"""One test per fixture, ported from LogParser.Tests.ps1. The fixture is the spec."""

from pathlib import Path

import pytest

from inspera_exam_helper.core.config import Config
from inspera_exam_helper.core.logs.parser import Failure, parse_log, select_primary

CONFIG = Config()


def parse(fixture_path, name):
    return parse_log(fixture_path(name), CONFIG)


def keys(log, key):
    return [f for f in log.failures if f.key == key]


def test_environment_failure_simple(fixture_path):
    log = parse(fixture_path, "environment-failure.log")
    assert log.found
    assert log.primary.key == "Environment - failure"
    assert "Discord.exe" in log.applications
    assert "obs64.exe" in log.applications


def test_electron_log_fortknox(fixture_path):
    log = parse(fixture_path, "electron-log-system-check.log")
    assert log.primary.key == "Environment - failure"
    assert log.failure_details
    assert len([e for e in log.system_checks if e.type == "pass"]) > 3


def test_structured_prefers_error_over_warn(fixture_path):
    assert parse(fixture_path, "structured-module-check.log").primary.key == "Process blocklist - failure"


def test_failed_to_close_json_array(fixture_path):
    log = parse(fixture_path, "failed-to-close-apps.log")
    assert log.primary.key == "failed to close"
    assert "desktopextension.exe" in log.applications
    assert "Discord.exe" in log.applications


def test_clock_failure_json(fixture_path):
    assert parse(fixture_path, "clock-failure.log").primary.key == "Clock accuracy - failure"


def test_multiple_hardware_failures(fixture_path):
    log = parse(fixture_path, "memory-screens-power.log")
    assert log.primary.key == "Memory Check - failure"
    assert keys(log, "Number of screens - failure")
    assert keys(log, "Power state - failure")


def test_proctoring_screen_capture_and_webcam(fixture_path):
    log = parse(fixture_path, "screen-capture-proctoring.log")
    assert log.primary.key == "Cannot upload files"
    assert keys(log, "Screen Capture")
    assert keys(log, "Webcam")
    assert "SnippingTool.exe" in log.applications


def test_check_failed_lifecycle_syntax(fixture_path):
    log = parse(fixture_path, "full-system-check-pass-then-fail.log")
    assert log.primary.key == "Environment - failure"
    assert len([e for e in log.system_checks if e.type == "pass"]) > 5


@pytest.mark.parametrize(
    ("fixture", "key"),
    [
        ("blocklist-failure.log", "Process blocklist - failure"),
        ("desktop-changed.log", "desktop changed"),
        ("already-running.log", "IIB already running"),
    ],
)
def test_primary_key(fixture_path, fixture, key):
    assert parse(fixture_path, fixture).primary.key == key


def test_config_download_denied(fixture_path):
    log = parse(fixture_path, "config-download-denied.log")
    assert log.primary.key == "Configuration download failed"
    assert log.metadata["version"] == "1.16.24"


def test_remote_session_maps_to_environment(fixture_path):
    log = parse(fixture_path, "remote-session.log")
    assert log.primary.key == "Environment - failure"
    assert len(keys(log, "Environment - failure")) >= 2


def test_utf16_log_parses_like_utf8(fixture_path, tmp_path):
    text = Path(fixture_path("clock-failure.log")).read_text(encoding="utf-8")

    log = tmp_path / "inspera-launcher-1.log"
    log.write_text(text, encoding="utf-16")
    assert parse_log(log, CONFIG).primary.key == "Clock accuracy - failure"


def test_unreadable_log_is_found_but_empty(tmp_path, monkeypatch):
    log = tmp_path / "inspera-launcher-1.log"
    log.write_text("x", encoding="utf-8")

    def locked(self):
        raise PermissionError("locked")

    monkeypatch.setattr(type(log), "read_bytes", locked)
    parsed = parse_log(log, CONFIG)
    assert parsed.found and parsed.primary is None and parsed.lines == []


def test_clock_offset_line(tmp_path):
    log = tmp_path / "inspera-launcher-1.log"
    log.write_text(
        "2026/06/09 22:47:09 clock offset to NTP server -45.123s\n2026/06/09 22:47:10 clock offset to NTP server -.s\n",
        encoding="utf-8",
    )
    parsed = parse_log(log, CONFIG)
    assert parsed.primary.key == "Clock accuracy - failure"
    assert parsed.metadata["clock_offset_seconds"] == -45.12


def test_missing_log():

    log = parse_log("C:\\nonexistent\\inspera-launcher-0.log", CONFIG)
    assert not log.found
    assert log.primary is None


def test_real_go_launcher_log(fixture_path):
    log = parse(fixture_path, "real-auckland-1781002029.log")
    assert log.found
    assert log.primary.key == "iceworm failure"
    assert log.metadata["version"] == "1.16.3"
    assert log.metadata["session_id"] == "1781002029"
    assert log.metadata["tenant"] == "auckland.inspera.com"
    assert keys(log, "UI runtime error")
    assert keys(log, "system check aborted")
    assert len([e for e in log.system_checks if e.check == "iceworm" and e.type == "fail"]) == 1


def test_select_primary_rules():
    def f(key, priority, line, level):
        return Failure(key, priority, line, "", "", level=level)

    assert select_primary([]) is None
    unknown = [f("unknown", 0, 1, "ERROR"), f("unknown", 0, 2, "WARN")]
    assert select_primary(unknown) is unknown[-1]
    assert select_primary([f("a", 20, 1, "WARN"), f("b", 10, 2, "error")]).key == "b"
    assert select_primary([f("a", 10, 1, None), f("b", 10, 2, None)]).key == "b"
    assert select_primary([f("a", 15, 1, None), f("b", 10, 2, None)]).key == "a"
