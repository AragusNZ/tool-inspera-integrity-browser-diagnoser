"""Find and close the apps IIB refuses to run beside: the shipped blocklist plus whatever the log named."""

import json
import os
import subprocess
from dataclasses import dataclass
from functools import cache

import psutil

from inspera_exam_helper.core.paths import DATA

# Never kill ourselves, the shell hosting us, or Windows itself.
PROTECTED_PREFIXES = ("python", "inspera", "csrss", "winlogon", "explorer", "powershell", "pwsh")


@dataclass(frozen=True)
class Entry:
    name: str
    category: str
    source: str  # default | log


@dataclass(frozen=True)
class Match:
    pid: int
    name: str
    category: str
    source: str  # default | log | pattern


@dataclass(frozen=True)
class StopResult:
    pid: int
    name: str
    action: str  # would-kill | stopped | taskkill | failed
    success: bool
    message: str


@cache
def default_blocklist() -> dict:
    return json.loads((DATA / "default-blocklist.json").read_text(encoding="utf-8"))


def blocklist_entries(log_apps: list[str] = ()) -> list[Entry]:
    """The shipped list, then any app the log named that is not already on it."""
    entries = [Entry(p["name"], p["category"], "default") for p in default_blocklist()["processes"]]
    known = {e.name.lower() for e in entries}
    for app in log_apps:
        name = app if app.lower().endswith((".exe", ".app")) else f"{app}.exe"
        if name.lower() not in known:
            entries.append(Entry(name, "from-log", "log"))
            known.add(name.lower())
    return entries


def _split_name(raw: str) -> tuple[str, str]:
    base = raw[:-4] if raw.lower().endswith(".exe") else raw
    return base, f"{base}.exe"


def running_matches(log_apps: list[str] = ()) -> list[Match]:
    entries = blocklist_entries(log_apps)
    patterns = default_blocklist()["processNamePatterns"]
    matches: list[Match] = []
    for proc in psutil.process_iter(["pid", "name"]):
        base, exe = _split_name(proc.info["name"] or "")
        if entry := next((e for e in entries if e.name.lower() in (exe.lower(), base.lower())), None):
            matches.append(Match(proc.info["pid"], base, entry.category, entry.source))
        elif pattern := next((p for p in patterns if p["pattern"].lower() in base.lower()), None):
            matches.append(Match(proc.info["pid"], base, pattern["category"], "pattern"))
    return matches


def stop_process(pid: int, name: str, apply: bool) -> StopResult:
    from inspera_exam_helper.core.checks import probes  # noqa: PLC0415 -- keeps the Windows calls in one place

    if not apply:
        return StopResult(pid, name, "would-kill", True, "Dry-run: would terminate")
    try:
        proc = psutil.Process(pid)
        proc.kill()
        # So the readiness list that runs next no longer sees it.
        proc.wait(timeout=3)
        return StopResult(pid, name, "stopped", True, "Closed")
    except psutil.TimeoutExpired:
        return StopResult(pid, name, "stopped", True, "Closed")
    except psutil.Error:
        pass
    try:
        code = probes.taskkill(pid)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return StopResult(pid, name, "failed", False, str(exc))
    if code == 0:
        return StopResult(pid, name, "taskkill", True, "Terminated via taskkill /T")
    return StopResult(pid, name, "failed", False, "Could not terminate - try running as Administrator")


def cleanup(log_apps: list[str], apply: bool) -> list[StopResult]:
    own_pid = os.getpid()
    return [
        stop_process(m.pid, m.name, apply)
        for m in running_matches(log_apps)
        if m.pid != own_pid and not m.name.lower().startswith(PROTECTED_PREFIXES)
    ]


def wsl_shutdown(apply: bool) -> tuple[bool, str]:
    """(ran, message). INSPERA_SKIP_WSL_SHUTDOWN=1 keeps a dev host's WSL alive under test."""
    from inspera_exam_helper.core.checks import probes  # noqa: PLC0415 -- keeps the Windows calls in one place

    if not probes.wsl_available():
        return False, "WSL not installed"
    if not apply:
        return False, "Dry-run: would run wsl --shutdown"
    if os.environ.get("INSPERA_SKIP_WSL_SHUTDOWN") == "1":
        return False, "Skipped WSL shutdown (test mode)"
    try:
        probes.wsl_shutdown()
        return True, "WSL shutdown completed"
    except (OSError, subprocess.TimeoutExpired) as exc:
        return False, f"WSL shutdown failed: {exc}"
