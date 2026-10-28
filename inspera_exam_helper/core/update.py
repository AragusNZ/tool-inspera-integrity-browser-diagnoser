"""Ask GitHub for the newest release. Stdlib only; nothing about the student's PC is sent."""

import json
import re
from urllib.request import Request, urlopen

from inspera_exam_helper import __version__

RELEASES_API = "https://api.github.com/repos/AragusNZ/tool-inspera-integrity-browser-diagnoser/releases/latest"
RELEASES_URL = "https://github.com/AragusNZ/tool-inspera-integrity-browser-diagnoser/releases/latest"


def latest_version(timeout: float = 5.0) -> str:
    """Tag of the latest release, without the leading ``v``. Raises on any network or API error."""
    # GitHub rejects requests without a User-Agent.
    req = Request(
        RELEASES_API,
        headers={"User-Agent": f"inspera-exam-helper/{__version__}", "Accept": "application/vnd.github+json"},
    )
    with urlopen(req, timeout=timeout) as response:
        return json.load(response)["tag_name"].lstrip("v")


def version_key(version: str) -> tuple[int, ...]:
    """Every numeric part, trailing zeros dropped: 1.0 == 1.0.0, and 1.16.3.0 == 1.16.3."""
    key = [int(part) for part in re.findall(r"\d+", version)]
    while key and key[-1] == 0:
        key.pop()
    return tuple(key)


def is_newer(latest: str, current: str) -> bool:
    return version_key(latest) > version_key(current)
