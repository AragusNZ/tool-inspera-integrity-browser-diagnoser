import sys

import pytest
from PySide6.QtCore import QEvent
from PySide6.QtGui import QCloseEvent, QDesktopServices
from PySide6.QtWidgets import QApplication, QMessageBox

from inspera_exam_helper import __version__
from inspera_exam_helper.app import bootstrap, updates
from inspera_exam_helper.app import window as window_module
from inspera_exam_helper.app.settings import check_on_startup, settings
from inspera_exam_helper.app.window import MainWindow
from inspera_exam_helper.core.result import Result, Section

pytestmark = pytest.mark.usefixtures("qapp")


def wait_done(win: MainWindow, qapp) -> None:
    worker = win._worker
    assert worker is not None and worker.wait(10000)
    qapp.processEvents()


def canned(status="ok"):
    return Result(
        "T", status, "Summary line", [Section("Head", ["[PASS] a", "[FAIL] b", "[WARN] c", "plain", ""], "info")]
    )


def test_intro_and_buttons(qapp):
    win = MainWindow()
    assert "Recommended order:" in win.results.toPlainText()
    assert list(win.buttons) == ["prepare", "ready", "diagnose", "guided"]
    assert win.status.text() == "Ready"


def test_ready_runs_preflight_and_renders(qapp, monkeypatch):
    monkeypatch.setattr(window_module, "context", lambda: "ctx")
    monkeypatch.setattr(window_module.preflight, "run", lambda ctx: canned("issues"))
    win = MainWindow()
    win.buttons["ready"].click()
    assert not win.buttons["ready"].isEnabled()
    wait_done(win, qapp)
    assert win.buttons["ready"].isEnabled()
    text = win.results.toPlainText()
    assert text.startswith("Summary line") and "[FAIL] b" in text
    assert win.status.text() == "Summary line"
    assert win._worker is None
    win._start(canned)  # a second start while idle works
    wait_done(win, qapp)


def test_diagnose_failure_shows_message(qapp, monkeypatch):
    monkeypatch.setattr(window_module, "context", lambda: (_ for _ in ()).throw(RuntimeError("boom")))
    win = MainWindow()
    win.buttons["diagnose"].click()
    wait_done(win, qapp)
    assert "Something went wrong." in win.results.toPlainText()
    assert "boom" in win.results.toPlainText()
    assert win.status.text() == "Error"


def test_prepare_and_guided_ask_first(qapp, monkeypatch):
    monkeypatch.setattr(QMessageBox, "question", lambda *a: QMessageBox.StandardButton.No)
    win = MainWindow()
    win.buttons["prepare"].click()
    win.buttons["guided"].click()
    assert win._worker is None
    calls = []
    monkeypatch.setattr(QMessageBox, "question", lambda *a: QMessageBox.StandardButton.Yes)
    monkeypatch.setattr(window_module, "context", lambda: "ctx")
    monkeypatch.setattr(window_module.prepare, "run", lambda ctx, apply: calls.append(("prepare", apply)) or canned())
    monkeypatch.setattr(window_module.guided, "run", lambda ctx: calls.append("guided") or canned())
    win.buttons["prepare"].click()
    win._start(canned)  # ignored: one action at a time
    wait_done(win, qapp)
    win.buttons["guided"].click()
    wait_done(win, qapp)
    assert calls == [("prepare", True), "guided"]


def test_close_refused_while_running(qapp, monkeypatch):
    monkeypatch.setattr(window_module, "context", lambda: "ctx")
    monkeypatch.setattr(window_module.diagnose, "run", lambda ctx: canned())
    win = MainWindow()
    win.buttons["diagnose"].click()
    event = QCloseEvent()
    win.closeEvent(event)
    assert not event.isAccepted()
    wait_done(win, qapp)
    event = QCloseEvent()
    win.closeEvent(event)
    assert event.isAccepted()
    assert settings().value("geometry") is not None


def test_help_menu(qapp, monkeypatch):
    win = MainWindow()
    assert check_on_startup()
    win.startup_check.setChecked(False)
    assert not check_on_startup()
    opened = []
    monkeypatch.setattr(QDesktopServices, "openUrl", lambda url: opened.append(url.toString()))
    win.centralWidget().findChildren(type(win.status))[-1].linkActivated.emit("#open")
    assert opened and opened[0].startswith("file:")
    shown = []
    monkeypatch.setattr(QMessageBox, "about", lambda *a: shown.append(a[-1]))
    next(a for a in win.menuBar().actions()[0].menu().actions() if a.text() == "&About").trigger()
    assert __version__ in shown[0]


def stub_update(monkeypatch, latest):
    seen: dict = {"opened": [], "info": []}

    def fetch():
        if isinstance(latest, Exception):
            raise latest
        return latest

    monkeypatch.setattr(updates, "latest_version", fetch)
    monkeypatch.setattr(QMessageBox, "question", lambda *a: QMessageBox.StandardButton.Yes)
    monkeypatch.setattr(QMessageBox, "information", lambda *a: seen["info"].append(a[-1]))
    monkeypatch.setattr(QMessageBox, "warning", lambda *a: seen["info"].append(a[-1]))
    monkeypatch.setattr(QDesktopServices, "openUrl", lambda url: seen["opened"].append(url.toString()))
    return seen


def run_update(win, qapp, manual):
    win.updates.check(manual)
    win.updates.check(manual)  # second call while running is ignored
    win.updates.wait()
    qapp.processEvents()


def test_update_newer_opens_releases(qapp, monkeypatch):
    seen = stub_update(monkeypatch, "99.0.0")
    win = MainWindow()
    run_update(win, qapp, manual=False)
    assert seen["opened"] == [updates.RELEASES_URL]


def test_update_current_and_failed(qapp, monkeypatch):
    seen = stub_update(monkeypatch, __version__)
    win = MainWindow()
    run_update(win, qapp, manual=True)
    assert seen["info"] == [f"Inspera Exam Helper {__version__} is up to date."]
    run_update(win, qapp, manual=False)
    assert len(seen["info"]) == 1
    seen = stub_update(monkeypatch, OSError("offline"))
    run_update(win, qapp, manual=True)
    assert seen["info"] == ["Update check failed: offline"]
    run_update(win, qapp, manual=False)
    assert len(seen["info"]) == 1


def test_main_builds_app(qapp, monkeypatch, tmp_path):
    monkeypatch.setattr(bootstrap, "LOG_FILE", tmp_path / "x.log")
    monkeypatch.setattr(QApplication, "exec", lambda self: 0)
    monkeypatch.setattr(updates, "latest_version", lambda: __version__)
    with pytest.raises(SystemExit):
        bootstrap.main()
    assert sys.excepthook is bootstrap._excepthook
    monkeypatch.setattr(QMessageBox, "critical", lambda *a: None)
    bootstrap._excepthook(RuntimeError, RuntimeError("x"), None)
    qapp.sendEvent(qapp, QEvent(QEvent.Type.None_))
