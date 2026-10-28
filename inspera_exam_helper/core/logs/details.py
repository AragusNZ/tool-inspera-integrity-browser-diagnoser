"""Secondary reads of a parsed log: apps it names, lines around the failure, session metadata, check events."""

import re
from dataclasses import dataclass

from inspera_exam_helper.core.logs.lines import parse_line

APP_PATTERNS = [
    re.compile(p, re.I)
    for p in (
        r"failed to close(?:\s+the following applications)?[:\s]+(.+)$",
        r"Inspera failed to close the following applications[:\s.]+(.+)$",
        r"detected the following applications(?: that have access to Screen Capture)?[^:]*:\s*(.+)$",
        r"prohibited[^:]*:\s*(.+)$",
        r"blocklist[^:]*:\s*(.+)$",
        r"running processes?[:\s]+(.+)$",
        r"could not terminate[:\s]+(.+)$",
        r"blocked processes?[:\s]+(.+)$",
    )
]
APP_NAME = re.compile(r"\.(exe|app)$|^[A-Za-z][\w\s.-]{2,}$", re.I)
JSON_APP_KEYS = re.compile(r'"(?:process(?:Name)?|application|executable)"\s*:\s*"([^"]+)"', re.I)
JSON_ARRAY = re.compile(r'\[(?:\s*"[^"]+"\s*,?)+\]', re.I)
JSON_EXE = re.compile(r'"([^"]+\.(?:exe|app))"', re.I)
DETAIL_WORDS = re.compile(
    r"reason|because|detected|virtual|remote|VM|RDP|Hyper-V|offset|latency|memory|display|monitor|process|blocked|"
    r"permission|SSE4|version|battery|power|plugged|iceworm|Fyne|GLFW|cancellation|connectionCheck|session status|"
    r"clock offset|active displays",
    re.I,
)


def applications(lines: list[str]) -> list[str]:
    """Process names the log mentions, first-seen spelling, deduped without case."""
    apps: dict[str, str] = {}

    def add(name: str) -> None:
        apps.setdefault(name.lower(), name)

    for line in lines:
        for pattern in APP_PATTERNS:
            if m := pattern.search(line):
                for part in re.split(r'[,;|\[\]"]+', m.group(1)):
                    if (part := part.strip()) and APP_NAME.search(part):
                        add(part)
        for m in JSON_APP_KEYS.finditer(line):
            add(m.group(1))
        if JSON_ARRAY.search(line):
            for m in JSON_EXE.finditer(line):
                add(m.group(1))
    return list(apps.values())


def failure_details(lines: list[str], failure_line: int) -> list[str]:
    """The lines within -3/+4 of the failure that look like they explain it."""
    out: list[str] = []
    for i in range(max(0, failure_line - 3), min(len(lines) - 1, failure_line + 4) + 1):
        if i + 1 == failure_line:
            continue
        text = lines[i].strip()
        if DETAIL_WORDS.search(lines[i]) and text not in out:
            out.append(text)
    return out


META_PATTERNS = {
    "version": r"^launching Inspera Integrity Browser v([\d.]+)",
    "session_id": r"^session ID (\d+)",
    "tenant": r"^tenant domain (.+)",
    "platform": r"^host platform: (.+)",
    "machine": r"^machine name (.+?), vendor",
    "cpu": r"^CPU model (.+?), vendor",
    "keyboard_layouts": r"^keyboard layouts \[(.+)\]",
    "displays": r"^active displays \[(.+)\]",
    "clock_offset_seconds": r"^clock offset to NTP server ([-\d.]+)s",
    "last_session_status": r"^session status (.+)",
    "connection_check_url": r"requested frame URL (.+connectionCheck\.json)",
}
META_COMPILED = {k: re.compile(v, re.I) for k, v in META_PATTERNS.items()}


def metadata(lines: list[str]) -> dict[str, str | float]:
    """What the Go launcher logs about the session before any check runs. Last mention wins."""
    meta: dict[str, str | float] = {}
    for line in lines:
        msg = parse_line(line).message
        for key, pattern in META_COMPILED.items():
            if m := pattern.search(msg):
                meta[key] = round(float(m.group(1)), 2) if key == "clock_offset_seconds" else m.group(1).strip()
    return meta


@dataclass
class CheckEvent:
    type: str  # start | pass | fail | info
    check: str
    line_number: int
    raw: str


EVENT_RULES: tuple[tuple[str, str, str | None], ...] = (
    ("start", r'^(?:Running|Starting)\s+(?:system\s+)?check:?\s*"?([^"]+)"?$', None),
    ("start", r'^Check\s+"?([^"]+)"?\s+(?:started|running)', None),
    ("pass", r"^([A-Za-z][\w\s]+)\s*-\s*(?:success|passed)", None),
    ("fail", r"^([A-Za-z][\w\s]+)\s*-\s*(?:failure|failed)", None),
    ("info", r"^launching Inspera Integrity Browser v", "Launcher start"),
    ("start", r"^entering sys setup page", "System check"),
    ("info", r"^session status (.+)", "Session: {}"),
    ("info", r"^VM check", "VM check"),
    ("info", r"^clock offset to NTP server", "Clock NTP"),
    ("info", r"^active displays", "Displays"),
    ("fail", r"^iceworm exited:", "iceworm"),
    ("fail", r"^cancellation detected", "Check cancelled"),
)
EVENT_COMPILED = [(t, re.compile(p, re.I), label) for t, p, label in EVENT_RULES]


def check_events(lines: list[str]) -> list[CheckEvent]:
    """The system-check lifecycle as IIB logged it: which checks ran, passed and failed."""
    events: list[CheckEvent] = []
    for number, raw in enumerate(lines, 1):
        text = parse_line(raw).message
        for kind, pattern, label in EVENT_COMPILED:
            if m := pattern.search(text):
                name = m.group(1).strip() if label is None else label.format(*m.groups())
                events.append(CheckEvent(kind, name, number, raw))
                break
    return events
