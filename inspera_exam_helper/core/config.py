"""config.json: log search paths and the few institution-specific knobs."""

import getpass
import json
import re
import tempfile
from dataclasses import dataclass
from pathlib import Path

from inspera_exam_helper.core.paths import config_path


@dataclass(frozen=True)
class Config:
    log_directories: tuple[str, ...] = ()
    fallback_to_user_temp: bool = True
    inspera_url: str = "https://www.inspera.com"
    minimum_iib_version: str = "1.15.4"
    approved_keyboard_languages: tuple[str, ...] = ()


def load_config(path: Path | None = None) -> Config:
    """A missing or broken file means defaults: the tool must still run on a PC IT never touched."""
    path = path or config_path()
    try:
        # utf-8-sig: PowerShell 5.1 and older Notepad save JSON with a BOM.
        raw = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError):
        return Config()
    if not isinstance(raw, dict):
        return Config()
    defaults = Config()
    return Config(
        log_directories=_strings(raw.get("logDirectories")),
        fallback_to_user_temp=bool(raw.get("fallbackToUserTemp", True)),
        inspera_url=raw.get("insperaUrl") or defaults.inspera_url,
        minimum_iib_version=str(raw.get("minimumIibVersion") or defaults.minimum_iib_version),
        approved_keyboard_languages=_strings(raw.get("approvedKeyboardLanguages")),
    )


def _strings(value) -> tuple[str, ...]:
    """A list field; a lone string is one item, not its characters."""
    items = [value] if isinstance(value, str) else value if isinstance(value, list) else []
    return tuple(str(x) for x in items if x)


def expand_path(entry: str) -> str | None:
    """Only %TEMP%, %USERNAME% and %USERPROFILE% expand - the three the config has ever needed."""
    if not entry or not entry.strip():
        return None
    out = re.sub("%USERNAME%", getpass.getuser(), entry.strip(), flags=re.I)
    out = re.sub("%USERPROFILE%", str(Path.home()).replace("\\", "\\\\"), out, flags=re.I)
    return re.sub("%TEMP%", tempfile.gettempdir().rstrip("\\").replace("\\", "\\\\"), out, flags=re.I)
