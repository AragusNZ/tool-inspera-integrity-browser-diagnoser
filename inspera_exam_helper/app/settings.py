"""State the student never edits by hand: window geometry and the update preference."""

import tempfile
from pathlib import Path

from PySide6.QtCore import QSettings

TITLE = "Inspera Exam Helper"
ORGANISATION, APPLICATION = "inspera-exam-helper", "InsperaExamHelper"
LOG_FILE = Path(tempfile.gettempdir()) / "InsperaExamHelper.log"


def settings() -> QSettings:
    """The application-wide store. The names are set once on the QApplication by ``main``.

    Not ``QSettings(org, app)``: that constructor always uses the registry on Windows, so the test
    suite's redirect to a temp folder (``setDefaultFormat``) would not reach it.
    """
    return QSettings()


def check_on_startup() -> bool:
    return settings().value("check_updates", True, type=bool)
