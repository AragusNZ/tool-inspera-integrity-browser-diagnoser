"""Which checks run for which flow, with every probe stubbed so nothing reaches Windows."""

import pytest

from inspera_exam_helper.core import checks
from inspera_exam_helper.core.checks import hardware, network, platform, probes, software
from inspera_exam_helper.core.config import Config


@pytest.fixture(autouse=True)
def _stub_probes(monkeypatch):
    for name in dir(probes):
        if not name.startswith("_") and callable(getattr(probes, name)):
            monkeypatch.setattr(probes, name, lambda *a, **k: (_ for _ in ()).throw(OSError("stubbed")))
    # The two probes called outside a try: they never raise on a real PC either.
    monkeypatch.setattr(probes, "pids_named", lambda name: [])
    monkeypatch.setattr(probes, "wsl_available", lambda: False)


def test_system_checks_unique_names_and_webcam_only_when_proctored():
    plain = checks.system_checks(Config(), "https://x")
    names = [c.name for c in plain]
    assert len(names) == len(set(names)) == 14
    assert all(isinstance(c.message, str) for c in plain)
    assert "Webcam (proctored)" in [c.name for c in checks.system_checks(Config(), "https://x", proctored=True)]


def test_environment_audit_order():
    assert [c.name for c in checks.environment_audit()] == [
        "Remote session",
        "Virtual machine",
        "WSL status",
        "Virtualization features",
    ]


@pytest.mark.parametrize(
    ("key", "names"),
    [
        ("Environment - failure", ["Remote session", "Virtual machine", "WSL status", "Virtualization features"]),
        ("Clock accuracy - failure", ["Clock accuracy"]),
        ("Connection quality - failure", ["Network connectivity", "Connection quality"]),
        ("Process blocklist - failure", []),
        ("failed to close", []),
        ("UI runtime error", ["Graphics driver", "Display count"]),
        ("IIB already running", ["Inspera not already running"]),
        ("iceworm failure", ["Network connectivity", "Connection quality", "Graphics driver"]),
        ("Configuration download failed", ["Administrator rights", "Network connectivity"]),
        ("nope", []),
        (None, []),
    ],
)
def test_targeted_checks(key, names):
    assert [c.name for c in checks.targeted_checks(key, Config(), "https://x")] == names


def test_targeted_probes_connection_check_url(monkeypatch):
    seen = []
    monkeypatch.setattr(probes, "http_head", lambda url, timeout: seen.append(url) or (200, 1))
    result = checks.targeted_checks(
        "Connection quality - failure", Config(), "https://x", "https://cdn/connectionCheck.json"
    )
    assert [c.name for c in result] == ["Network connectivity", "Network connectivity", "Connection quality"]
    assert seen[:2] == ["https://x", "https://cdn/connectionCheck.json"]


def test_every_key_in_table_resolves(monkeypatch):
    for module, fn in (
        (hardware, "display_count"),
        (platform, "sse42"),
        (network, "clock_skew"),
        (software, "iib_running"),
    ):
        assert callable(getattr(module, fn))
    for key in (
        "Number of screens - failure",
        "Power state - failure",
        "Memory Check - failure",
        "CPU features - failure",
    ):
        assert len(checks.targeted_checks(key, Config(), "https://x")) == 1
    for key in ("App version - failure", "Incorrect keyboard language", "After completion - failed", "Screen Capture"):
        assert len(checks.targeted_checks(key, Config(), "https://x")) == 1
    for key in ("Failed to capture screen", "Cannot upload files", "desktop changed", "system check aborted", "Webcam"):
        assert len(checks.targeted_checks(key, Config(), "https://x")) == 1
