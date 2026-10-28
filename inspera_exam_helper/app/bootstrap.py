"""``main()``: the log file, the excepthook, the QApplication, style and theme, then the window."""

import logging
import logging.handlers
import sys

from PySide6.QtCore import QTimer
from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication, QIcon
from PySide6.QtWidgets import QApplication, QMessageBox, QStyleFactory

from inspera_exam_helper.app.settings import APPLICATION, LOG_FILE, ORGANISATION, TITLE, check_on_startup
from inspera_exam_helper.app.window import MainWindow
from inspera_exam_helper.ui.theme import apply_scheme, asset_path


def _excepthook(exc_type, exc, tb) -> None:
    logging.getLogger("inspera_exam_helper").critical("unhandled exception", exc_info=(exc_type, exc, tb))
    QMessageBox.critical(None, TITLE, f"{exc}\n\nDetails: {LOG_FILE}")


def main() -> None:
    handler = logging.handlers.RotatingFileHandler(LOG_FILE, maxBytes=1_000_000, backupCount=1, encoding="utf-8")
    logging.basicConfig(
        handlers=[handler], level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s"
    )
    sys.excepthook = _excepthook
    app = QApplication.instance() or QApplication(sys.argv)
    app.setOrganizationName(ORGANISATION)
    app.setApplicationName(APPLICATION)
    app.setWindowIcon(QIcon(str(asset_path("icon.ico"))))
    # The native Windows 11 style draws Fluent controls properly; Fusion is the fallback elsewhere.
    app.setStyle("windows11" if "windows11" in QStyleFactory.keys() else "Fusion")  # noqa: SIM118 - a class, not a dict
    if "Segoe UI Variable Text" in QFontDatabase.families():
        font = QFont("Segoe UI Variable Text")
        font.setPointSizeF(10.5)  # Windows 11 Body: 14px regular
        app.setFont(font)
    apply_scheme("System")  # also installs the stylesheet
    QGuiApplication.styleHints().colorSchemeChanged.connect(lambda _: apply_scheme("System"))
    window = MainWindow()
    window.show()
    if check_on_startup():
        QTimer.singleShot(1500, lambda: window.updates.check(manual=False))  # after the window has painted
    sys.exit(app.exec())
