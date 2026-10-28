"""Where things live: the folder the student sees, and the data bundled inside the package."""

import sys
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data"


def app_root() -> Path:
    """The folder beside the exe when frozen, the repo root when run from source."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parents[2]


def config_path() -> Path:
    """IT edits config.json beside the exe; the installer never overwrites it. Otherwise the bundled default."""
    beside = app_root() / "config.json"
    return beside if beside.is_file() else DATA / "config.json"
