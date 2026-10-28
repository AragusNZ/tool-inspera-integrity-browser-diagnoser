"""Checks about what is installed and configured: IIB itself, temp folder, keyboard language, WSL."""

import os
import re
import tempfile
import uuid
from pathlib import Path

from inspera_exam_helper.core.checks import probes
from inspera_exam_helper.core.result import Check
from inspera_exam_helper.core.update import version_key

IIB_EXE = re.compile(r"inspera|launcher|IIB", re.I)
NOT_FOUND = (
    "Inspera Integrity Browser not found  - install it from your institution's link "
    "(run the installer as administrator)"
)
WSL_IDLE = re.compile(r"no running distributions|no installed distributions", re.I)
IIB_FOLDERS = (
    "ProgramFiles\\Inspera Integrity Browser",
    "ProgramFiles(x86)\\Inspera Integrity Browser",
    "LocalAppData\\Programs\\Inspera Integrity Browser",
    "LocalAppData\\Inspera Integrity Browser",
)
LEGACY_FOLDERS = (
    "ProgramFiles\\Inspera Exam Portal",
    "ProgramFiles(x86)\\Inspera Exam Portal",
    "ProgramData\\Inspera Exam Portal",
)


def _env_paths(*templates: str) -> list[Path]:
    """Expand '{ProgramFiles}\\x'-style templates, dropping any whose variable is unset here."""
    out = []
    for template in templates:
        var, _, tail = template.partition("\\")
        if base := os.environ.get(var):
            out.append(Path(base) / tail)
    return out


def _installed(folders: list[Path]) -> tuple[Path | None, Path | None]:
    """(folder, exe): the first IIB folder that exists, and the launcher inside it when there is one."""
    for folder in (f for f in folders if f.is_dir()):
        exes = sorted(
            (p for p in folder.rglob("*.exe") if IIB_EXE.search(p.name)),
            key=lambda p: p.name.lower() != "inspera-launcher.exe",
        )
        return folder, (exes[0] if exes else None)
    return None, None


def iib_version(minimum_version: str) -> Check:
    check = Check("IIB installation", False, "")
    if old := next((p for p in _env_paths(*LEGACY_FOLDERS) if p.exists()), None):
        check.warnings.append(
            f"Old 'Inspera Exam Portal' still installed ({old})  - "
            "uninstall it before installing the current Inspera Integrity Browser"
        )
    try:
        folder, exe = _installed(_env_paths(*IIB_FOLDERS))

    except OSError as exc:
        check.passed = True
        check.message = f"IIB installation check skipped: {exc}"
        return check
    if folder is None:
        check.message = NOT_FOUND
        return check
    if exe is None:
        check.passed = True
        check.message = f"Found installation folder: {folder}"
        check.details = {"path": str(folder)}
        return check
    version = probes.file_version(exe)
    check.details = {"path": str(exe), "version": version, "minimum_version": minimum_version}
    if version and minimum_version and version_key(version) < version_key(minimum_version):
        check.message = (
            f"Installed v{version} is older than {minimum_version}  - uninstall it, "
            "then install the latest from your institution's Inspera link"
        )
        return check
    check.passed = True
    check.message = f"Found: {exe}" + (f" v{version}" if version else "")

    return check


def iib_running() -> Check:
    """A stuck inspera-launcher.exe produces 'Inspera Integrity Browser already running' on next launch."""
    check = Check("Inspera not already running", True, "Inspera is not running in the background")
    pids = probes.pids_named("inspera-launcher.exe")
    if pids:
        check.passed = False
        check.details = {"pids": pids}
        check.message = (
            "Inspera is already running in the background  - open Task Manager, end inspera-launcher.exe, "
            "then start Inspera again (or restart the PC)"
        )
    return check


def temp_writable() -> Check:
    check = Check("Temp folder writable", False, "")
    temp = tempfile.gettempdir()
    try:
        probe = Path(temp) / f"inspera-preflight-test-{uuid.uuid4()}.tmp"
        probe.write_text("test", encoding="utf-8")
        probe.unlink()
        check.passed = True
        check.message = f"Writable: {temp}"
        check.details = {"path": temp}
    except OSError as exc:
        check.message = f"Temp folder not writable: {exc}"
    return check


def keyboard_language(approved: tuple[str, ...]) -> Check:
    """'en' approves every en-* layout; 'en-NZ' approves only that tag. No list means informational."""
    check = Check("Keyboard language", True, "", informational=not approved)
    try:
        tags = probes.keyboard_languages()
        check.details = {"languages": tags, "approved": list(approved)}
        if not approved:
            check.message = f"Active: {', '.join(tags)}  - verify with your institution's approved list"
            return check
        matched = [
            t for t in tags if any(t.lower() == a.lower() or t.lower().startswith(a.lower() + "-") for a in approved)
        ]
        if matched:
            check.message = f"Approved layout active: {', '.join(matched)}"
        else:
            check.passed = False
            check.message = (
                f"Active: {', '.join(tags)}  - switch to an approved layout ({', '.join(approved)}) "
                "in Settings > Time & language"
            )
    except Exception as exc:
        check.informational = True
        check.message = f"Could not read keyboard layout: {exc}"
    return check


def wsl_running() -> Check:
    check = Check("WSL status", True, "WSL not detected or not running")
    if not probes.wsl_available():
        return check
    try:
        code, listing = probes.wsl_running()
        check.details = {"running": listing}
        if code == 0 and not WSL_IDLE.search(listing):
            check.passed = False
            check.message = "WSL distributions are running  - may trigger environment error"
            check.optional_fix = "wsl --shutdown"
    except Exception:
        check.message = "WSL check skipped"
    return check
