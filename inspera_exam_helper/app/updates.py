"""Help > Check for Updates, and the silent check at startup."""

from PySide6.QtCore import QObject, QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QMainWindow, QMessageBox

from inspera_exam_helper import __version__
from inspera_exam_helper.app.settings import TITLE
from inspera_exam_helper.core.update import RELEASES_URL, is_newer, latest_version
from inspera_exam_helper.ui.worker import Worker


class UpdateCheck(QObject):
    """Ask GitHub off the UI thread; a startup check (manual=False) stays silent unless there is news."""

    def __init__(self, window: QMainWindow):
        super().__init__(window)
        self._window = window
        self._worker: Worker | None = None

    def check(self, manual: bool) -> None:
        if self._worker is not None:
            return
        result: dict = {}
        self._worker = Worker(lambda: result.update(latest=latest_version()), parent=self)
        if manual:
            self._worker.failed.connect(lambda m: QMessageBox.warning(self._window, TITLE, f"Update check failed: {m}"))
        self._worker.finished.connect(lambda: self._done(result.get("latest"), manual))
        self._worker.start()

    def wait(self) -> None:
        if self._worker is not None:
            self._worker.wait()  # bounded by the request timeout

    def _done(self, latest: str | None, manual: bool) -> None:
        self._worker.deleteLater()
        self._worker = None
        if latest is None:
            return  # failed: already said so if manual
        if is_newer(latest, __version__):
            text = f"{TITLE} {latest} is available (you have {__version__}).\n\nOpen the download page?"
            if QMessageBox.question(self._window, TITLE, text) == QMessageBox.StandardButton.Yes:
                QDesktopServices.openUrl(QUrl(RELEASES_URL))
        elif manual:
            QMessageBox.information(self._window, TITLE, f"{TITLE} {__version__} is up to date.")
