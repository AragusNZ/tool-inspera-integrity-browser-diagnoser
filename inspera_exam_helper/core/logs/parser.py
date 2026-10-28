"""Read one IIB launcher log and name the failure that stopped the exam."""

import re
from dataclasses import dataclass, field
from pathlib import Path

from inspera_exam_helper.core.config import Config
from inspera_exam_helper.core.logs import details
from inspera_exam_helper.core.logs.details import CheckEvent
from inspera_exam_helper.core.logs.discovery import find_log
from inspera_exam_helper.core.logs.lines import parse_line
from inspera_exam_helper.core.logs.patterns import FAILURE_PATTERNS, check_key, is_generic_failure

CHECK_FAILED = re.compile(r'^Check\s+"?([^"]+)"?\s+(?:failed|failure)', re.I)
INTEGRITY_MODULE = re.compile(
    r"\[(?:FortKnox|IceWorm|Integrity|SystemCheck)\].*"
    r"(?:compromised|blocked|detected|failed|failure|virtual|remote session)",
    re.I,
)
CLOCK_OFFSET = details.META_COMPILED["clock_offset_seconds"]
ERROR_LEVEL = re.compile(r"^(ERROR|ERR|FATAL)$", re.I)
MAX_CLOCK_SKEW_SECONDS = 30


@dataclass
class Failure:
    key: str
    priority: int
    line_number: int
    message: str
    raw: str
    timestamp: str | None = None
    level: str | None = None
    module: str | None = None


@dataclass
class ParsedLog:
    found: bool = False
    path: Path | None = None
    lines: list[str] = field(default_factory=list)
    primary: Failure | None = None
    failures: list[Failure] = field(default_factory=list)
    applications: list[str] = field(default_factory=list)
    system_checks: list[CheckEvent] = field(default_factory=list)
    failure_details: list[str] = field(default_factory=list)
    metadata: dict = field(default_factory=dict)


def read_lines(path: Path) -> list[str]:
    raw = path.read_bytes()
    encoding = "utf-16" if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else "utf-8-sig"
    return raw.decode(encoding, errors="replace").splitlines()


def parse_log(path: str | Path | None, config: Config) -> ParsedLog:
    """Parse once; every flow then reads the ParsedLog rather than the file again."""
    resolved = find_log(path, config)
    if not resolved:
        return ParsedLog()
    try:
        lines = read_lines(resolved)
    except OSError:  # locked or denied: the flow says "no clear failure" instead of crashing
        return ParsedLog(found=True, path=resolved)

    failures = [f for number, raw in enumerate(lines, 1) for f in _line_failures(number, raw)]
    primary = select_primary(failures)
    return ParsedLog(
        found=True,
        path=resolved,
        lines=lines,
        primary=primary,
        failures=failures,
        applications=details.applications(lines),
        system_checks=details.check_events(lines),
        failure_details=details.failure_details(lines, primary.line_number) if primary else [],
        metadata=details.metadata(lines),
    )


def _line_failures(number: int, raw: str) -> list[Failure]:
    parsed = parse_line(raw)
    haystack = f"{raw} {parsed.message}"

    def failure(key: str, priority: int, level: str | None = parsed.level) -> Failure:
        return Failure(key, priority, number, parsed.message, raw, parsed.timestamp, level, parsed.module)

    found = [failure(p.key, p.priority) for p in FAILURE_PATTERNS if p.pattern.search(haystack)]
    if (m := CHECK_FAILED.match(parsed.message)) and (key := check_key(m.group(1))):
        found.append(failure(key, 10))
    if not found and INTEGRITY_MODULE.search(haystack):
        found.append(failure("Environment - failure", 8))
    if not found and is_generic_failure(haystack, parsed.message):
        found.append(failure("unknown", 0))
    if (m := CLOCK_OFFSET.match(parsed.message)) and abs(float(m.group(1))) > MAX_CLOCK_SKEW_SECONDS:
        found.append(failure("Clock accuracy - failure", 10, "ERROR"))
    return found


def select_primary(failures: list[Failure]) -> Failure | None:
    """Known beats unknown, ERROR beats WARN, then highest priority, then the latest line."""
    if not failures:
        return None
    known = [f for f in failures if f.key != "unknown"]
    if not known:
        return failures[-1]
    errors = [f for f in known if f.level and ERROR_LEVEL.match(f.level)]
    return max(errors or known, key=lambda f: (f.priority, f.line_number))
