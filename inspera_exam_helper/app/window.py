"""The one window: four buttons, a coloured results pane, a status line, and the Help menu."""

from collections.abc import Callable
from html import escape

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QAction, QCloseEvent, QDesktopServices, QFont, QGuiApplication
from PySide6.QtWidgets import (
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from inspera_exam_helper import __version__
from inspera_exam_helper.app.settings import TITLE, check_on_startup, settings
from inspera_exam_helper.app.updates import UpdateCheck
from inspera_exam_helper.core.flows import context, diagnose, guided, preflight, prepare
from inspera_exam_helper.core.flows.reminders import GUI_INTRO
from inspera_exam_helper.core.paths import app_root
from inspera_exam_helper.core.result import Result
from inspera_exam_helper.ui.worker import Worker

# The same five colours the WinForms build used, plus readable equivalents on a dark window.
COLOURS = {
    "light": {"pass": "#007800", "fail": "#B40000", "warn": "#B47800", "heading": "#005A8C", "info": "#3C3C3C"},
    "dark": {"pass": "#6CCB5F", "fail": "#FF99A4", "warn": "#F7C948", "heading": "#60CDFF", "info": "#CFCFCF"},
}
STATUS_LEVEL = {"ok": "pass", "issues": "warn", "error": "fail"}
PREPARE_CONFIRM = (
    "This will close apps like Discord, OBS, screen recorders, and other programs that can interfere "
    "with Inspera.\n\nContinue?"
)
GUIDED_CONFIRM = (
    "This will prepare your PC (close interfering apps), check readiness, and show a short checklist.\n\nContinue?"
)


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(TITLE)
        self.resize(720, 640)
        self.setMinimumSize(600, 500)
        self._worker: Worker | None = None
        self.updates = UpdateCheck(self)
        self._build()
        self._build_menu()
        if geometry := settings().value("geometry"):
            self.restoreGeometry(geometry)

    def _build(self) -> None:
        root = QWidget()
        layout = QVBoxLayout(root)
        title = QLabel(TITLE)
        title.setFont(QFont(title.font().family(), 14, QFont.Weight.Bold))
        subtitle = QLabel("Prepare your PC and understand Inspera failures")
        subtitle.setEnabled(False)
        layout.addWidget(title)
        layout.addWidget(subtitle)
        row = QHBoxLayout()
        self.buttons = {
            "prepare": QPushButton("Prepare my PC for the exam"),
            "ready": QPushButton("Am I ready?"),
            "diagnose": QPushButton("Why did Inspera fail?"),
            "guided": QPushButton("Run recommended steps"),
        }
        for button in self.buttons.values():
            row.addWidget(button)
        layout.addLayout(row)
        self.results = QTextEdit()
        self.results.setReadOnly(True)
        self.results.setPlainText("\n".join(GUI_INTRO))
        layout.addWidget(self.results, 1)
        footer = QHBoxLayout()
        self.status = QLabel("Ready")
        footer.addWidget(self.status, 1)
        folder = QLabel('<a href="#open">Advanced: open folder</a>')
        folder.linkActivated.connect(lambda _: QDesktopServices.openUrl(QUrl.fromLocalFile(str(app_root()))))
        footer.addWidget(folder)
        layout.addLayout(footer)
        self.setCentralWidget(root)
        self.buttons["prepare"].clicked.connect(self.on_prepare)
        self.buttons["ready"].clicked.connect(lambda: self._start(lambda: preflight.run(context())))
        self.buttons["diagnose"].clicked.connect(lambda: self._start(lambda: diagnose.run(context())))
        self.buttons["guided"].clicked.connect(self.on_guided)

    def _build_menu(self) -> None:
        menu = self.menuBar().addMenu("&Help")
        menu.addAction("Check for &Updates...", lambda: self.updates.check(manual=True))
        self.startup_check = QAction("Check on &Startup", self, checkable=True, checked=check_on_startup())
        self.startup_check.toggled.connect(lambda on: settings().setValue("check_updates", on))
        menu.addAction(self.startup_check)
        menu.addSeparator()
        menu.addAction("&About", lambda: QMessageBox.about(self, TITLE, f"{TITLE} {__version__}\n\nAragusNZ"))

    # --- actions ------------------------------------------------------------
    def _confirm(self, title: str, text: str) -> bool:
        return QMessageBox.question(self, title, text) == QMessageBox.StandardButton.Yes

    def on_prepare(self) -> None:
        if self._confirm("Prepare my PC", PREPARE_CONFIRM):
            self._start(lambda: prepare.run(context(), apply=True))

    def on_guided(self) -> None:
        if self._confirm("Run recommended steps", GUIDED_CONFIRM):
            self._start(lambda: guided.run(context()))

    def _start(self, action: Callable[[], Result]) -> None:
        if self._worker is not None:
            return
        self._set_busy(True)
        self.results.setPlainText("Please wait...")
        holder: dict = {}
        self._worker = Worker(lambda: holder.update(result=action()), parent=self)
        self._worker.failed.connect(self._failed)
        self._worker.finished.connect(lambda: self._done(holder.get("result")))
        self._worker.start()

    def _done(self, result: Result | None) -> None:
        self._worker.deleteLater()
        self._worker = None
        if result is not None:
            self.render(result)
        self._set_busy(False)

    def _failed(self, message: str) -> None:
        c = self._colours()
        self.results.setHtml(
            f'<p style="color:{c["fail"]}"><b>Something went wrong.</b><br>{escape(message)}</p>'
            f'<p style="color:{c["info"]}">Ask exam support for help, or try again.</p>'
        )
        self.status.setText("Error")
        self.status.setStyleSheet(f"color: {c['fail']}")

    def _set_busy(self, busy: bool) -> None:
        for button in self.buttons.values():
            button.setEnabled(not busy)
        if busy:
            self.status.setText("Working...")
            self.status.setStyleSheet("")
            self.setCursor(Qt.CursorShape.WaitCursor)
        else:
            self.unsetCursor()

    # --- rendering -----------------------------------------------------------
    @staticmethod
    def _colours() -> dict[str, str]:
        dark = QGuiApplication.styleHints().colorScheme() == Qt.ColorScheme.Dark
        return COLOURS["dark" if dark else "light"]

    def render(self, result: Result) -> None:
        c = self._colours()
        parts = []
        if result.summary:
            parts.append(
                f'<p style="color:{c[STATUS_LEVEL.get(result.status, "info")]}"><b>{escape(result.summary)}</b></p>'
            )
        for section in result.sections:
            lines = [f'<b style="color:{c["heading"]}">{escape(section.heading)}</b>'] if section.heading else []
            for line in section.lines:
                level = next(
                    (lv for lv in ("pass", "fail", "warn") if line.startswith(f"[{lv.upper()}]")), section.level
                )
                lines.append(f'<span style="color:{c.get(level, c["info"])}">{escape(line) or "&nbsp;"}</span>')
            parts.append('<p style="white-space:pre-wrap">' + "<br>".join(lines) + "</p>")
        self.results.setHtml("".join(parts))
        self.results.verticalScrollBar().setValue(0)
        self.status.setText(result.summary)
        self.status.setStyleSheet(f"color: {c[STATUS_LEVEL.get(result.status, 'info')]}")

    def closeEvent(self, event: QCloseEvent) -> None:
        # Destroying a running QThread aborts the process; refuse to close until the action is done.
        if self._worker is not None:
            event.ignore()
            return
        self.updates.wait()
        settings().setValue("geometry", self.saveGeometry())
        super().closeEvent(event)
