"""The failure vocabulary. Keys are ErrorCatalog keys; tests check every key has an entry.

Priority breaks ties when one log has several failures: a runtime 'desktop changed' (20) outranks
the system-check failure (10) that it usually drags along.
"""

import re
from typing import NamedTuple


class FailurePattern(NamedTuple):
    key: str
    pattern: re.Pattern
    priority: int


def _p(key: str, pattern: str, priority: int = 10) -> FailurePattern:
    return FailurePattern(key, re.compile(pattern, re.I), priority)


FAILURE_PATTERNS: tuple[FailurePattern, ...] = (
    _p("Environment - failure", r"Environment\s*-\s*failure|Environment\s+check\s+failed|Environment\s+error"),
    _p("Process blocklist - failure", r"Process\s+blocklist\s*-\s*failure|Failed to retrieve process blocklist"),
    _p("Connection quality - failure", r"Connection quality\s*-\s*failure|Too poor connection quality"),
    _p("Clock accuracy - failure", r"Clock accuracy\s*-\s*failure|Clock accuracy error"),
    _p("Number of screens - failure", r"Number of screens\s*-\s*failure|Incorrect number of screens"),
    _p("Power state - failure", r"Power state\s*-\s*failure|No external power supply"),
    _p("Memory Check - failure", r"Memory Check\s*[-\u2013]\s*failure|Not enough free memory"),
    _p("CPU features - failure", r"CPU features\s*-\s*failure|Unsupported CPU"),
    _p("App version - failure", r"App version\s*-\s*failure|Obsolete app version"),
    _p("App location - failure", r"App location\s*[-\u2013]\s*failure|Wrong application location"),
    _p("After completion - failed", r"After completion\s*-\s*failed|Login configuration error"),
    _p("Device check failure", r"Device check failure"),
    _p("Incorrect keyboard language", r"Incorrect keyboard language"),
    _p("desktop changed", r"active desktop has changed|desktop has changed", 20),
    _p("failed to close", r"failed to close the following applications", 15),
    _p(
        "Screen Capture",
        r"detected the following applications that have access to Screen Capture|access to Screen Capture",
    ),
    _p("Failed to capture screen", r"Failed to capture screen|Failed to capture your screen"),
    _p("Cannot upload files", r"Cannot upload files|Failed to upload"),
    _p("Webcam", r"Webcam too dark|Webcam Capture\s*-\s*failure"),
    _p("Full disk access", r"Full disk access\s*-\s*failure|Failed to acquire full disk access"),
    _p("iceworm failure", r"iceworm exited: exit status [1-9]\d*", 18),
    _p("system check aborted", r"cancellation detected", 17),
    _p("UI runtime error", r"Fyne error:|GLFW poll event error", 12),
    _p(
        "Environment - failure",
        r"cannot run within a remote session|remote (?:desktop )?session (?:detected|active|is not supported)",
    ),
    _p("Configuration download failed", r"Failed to download configuration file", 16),
    _p(
        "IIB already running",
        r"Inspera Integrity Browser (?:is )?already running|another instance (?:is )?already running",
        16,
    ),
)

# IIB's own system-check names, as they appear in `Check "<name>" failed`, to the catalog key.
CHECK_KEYS = {
    "login configuration": "After completion - failed",
    "environment": "Environment - failure",
    "process blocklist": "Process blocklist - failure",
    "connection quality": "Connection quality - failure",
    "clock accuracy": "Clock accuracy - failure",
    "number of screens": "Number of screens - failure",
    "power state": "Power state - failure",
    "memory check": "Memory Check - failure",
    "cpu features": "CPU features - failure",
    "app version": "App version - failure",
    "app location": "App location - failure",
    "screen capture": "Screen Capture",
    "webcam capture": "Webcam",
    "file upload": "Cannot upload files",
    "available disk space": "Cannot upload files",
}

BENIGN = re.compile(r'no error|without error|0 error|errorCount.:0|errors.:0|"error":null|error.:false', re.I)


def check_key(name: str) -> str | None:
    return CHECK_KEYS.get(name.strip().strip("\"'").lower())


def is_benign(line: str) -> bool:
    return bool(BENIGN.search(line))


def is_generic_failure(haystack: str, message: str) -> bool:
    """A line that says failed/error without matching any known pattern: kept as 'unknown', lowest priority."""
    if is_benign(haystack) or re.match(r"^Fyne error:|^\s+At:", message, re.I):
        return False
    if re.search(r"\b(failure|failed)\b", haystack, re.I):
        return True
    return bool(re.search(r"\berror\b", haystack, re.I)) and not re.search("Fyne error", message, re.I)
