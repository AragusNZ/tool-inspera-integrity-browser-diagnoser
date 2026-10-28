"""Find the newest inspera-launcher-*.log in the configured folders."""

import re
import tempfile
from pathlib import Path

from inspera_exam_helper.core.config import Config, expand_path

SUFFIX = re.compile(r"inspera-launcher-(\d+)$", re.I)


def search_directories(config: Config) -> list[str]:
    """Configured folders (missing ones included, so the 'no log' message can name them), then %TEMP%."""
    dirs: list[str] = []
    for entry in config.log_directories:
        resolved = expand_path(entry)
        if resolved and resolved.lower() not in (d.lower() for d in dirs):
            dirs.append(resolved)
    temp = tempfile.gettempdir().rstrip("\\")
    if (config.fallback_to_user_temp or not dirs) and temp.lower() not in (d.lower() for d in dirs):
        dirs.append(temp)
    return dirs


def log_files(directories: list[str]) -> list[Path]:
    return [p for d in directories if Path(d).is_dir() for p in Path(d).glob("inspera-launcher-*.log")]


def find_log(path: str | Path | None, config: Config) -> Path | None:
    """An explicit path wins; otherwise the highest session number, newest write time as the tiebreak."""
    if path:
        return Path(path).resolve() if Path(path).is_file() else None
    logs = log_files(search_directories(config))
    if not logs:
        return None

    def rank(p: Path) -> tuple[int, float]:
        m = SUFFIX.search(p.stem)
        return (int(m.group(1)) if m else -1, p.stat().st_mtime)

    return max(logs, key=rank).resolve()
