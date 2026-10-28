import os
from types import SimpleNamespace

import psutil
import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
# Tests must never shut down the operator's WSL.
os.environ["INSPERA_SKIP_WSL_SHUTDOWN"] = "1"

FIXTURES = os.path.join(os.path.dirname(__file__), "fixtures")


@pytest.fixture
def fixture_path():
    return lambda name: os.path.join(FIXTURES, name)


@pytest.fixture
def stub_probes(monkeypatch):
    """Every Windows probe raises, so each check takes its 'skipped' branch and nothing touches the machine."""
    from inspera_exam_helper.core.checks import probes

    for name in dir(probes):
        if not name.startswith("_") and callable(getattr(probes, name)):
            monkeypatch.setattr(probes, name, lambda *a, **k: (_ for _ in ()).throw(OSError("stubbed")))
    # The two probes called outside a try: they never raise on a real PC either.
    monkeypatch.setattr(probes, "pids_named", lambda name: [])
    monkeypatch.setattr(probes, "wsl_available", lambda: False)
    return probes


@pytest.fixture
def healthy_probes(stub_probes, monkeypatch, tmp_path):
    """A fake PC that passes every check, so a flow's own logic is what a test sees."""
    from datetime import UTC, datetime
    from types import SimpleNamespace

    from inspera_exam_helper.core.checks.network import NTP_EPOCH

    gb = 1024**3
    values = {
        "os_info": {"Version": "10.0.22631", "Caption": "Windows 11 Pro", "OSArchitecture": "64-bit"},
        "processor_architecture": "AMD64",
        "s_mode": False,
        "file_version": "1.16.3.0",
        "display_count": 1,
        "is_remote_session": False,
        "battery": None,
        "memory": SimpleNamespace(available=8 * gb, total=16 * gb),
        "disk_free_mb": 100_000,
        "cpu_name": "Intel Core(TM) i7",
        "sse42": True,
        "video_controllers": [{"Name": "NVIDIA", "DriverVersion": "1", "Status": "OK"}],
        "http_head": (200, 10),
        "is_admin": False,
        "keyboard_languages": ["en-NZ"],
        "computer_system": {"Manufacturer": "Dell", "Model": "XPS"},
        "enabled_virtualization_features": [],
        "cameras": ["Integrated Camera"],
    }
    for name, value in values.items():
        monkeypatch.setattr(stub_probes, name, lambda *a, _v=value, **k: _v)

    def ntp(server, timeout):
        secs = int((datetime.now(UTC) - NTP_EPOCH).total_seconds())
        return bytes(40) + secs.to_bytes(4, "big") + bytes(4)

    monkeypatch.setattr(stub_probes, "ntp_response", ntp)
    monkeypatch.setenv("ProgramFiles", str(tmp_path))
    (tmp_path / "Inspera Integrity Browser").mkdir()
    return stub_probes


@pytest.fixture
def fake_processes(monkeypatch):
    """Replace the process table: fake_processes('Discord.exe', 'obs64.exe') -> pids 100, 101."""

    def install(*names):
        procs = [SimpleNamespace(info={"pid": 100 + i, "name": n}) for i, n in enumerate(names)]
        monkeypatch.setattr(psutil, "process_iter", lambda attrs: procs)

    install()
    return install


@pytest.fixture(autouse=True, scope="session")
def _settings_in_tmp(tmp_path_factory):
    """QSettings land in a temp folder, not the operator's real registry / ~/.config store."""
    from PySide6.QtCore import QCoreApplication, QSettings

    QCoreApplication.setOrganizationName("inspera-exam-helper-test")
    QCoreApplication.setApplicationName("inspera-exam-helper-test")
    QSettings.setDefaultFormat(QSettings.Format.IniFormat)
    QSettings.setPath(QSettings.Format.IniFormat, QSettings.Scope.UserScope, str(tmp_path_factory.mktemp("settings")))


@pytest.fixture(autouse=True)
def _fresh_settings(_settings_in_tmp):
    """Every test starts from empty settings, and leaves none behind for the next."""
    from PySide6.QtCore import QSettings

    QSettings().clear()


@pytest.fixture(scope="session")
def qapp():
    from PySide6.QtWidgets import QApplication

    return QApplication.instance() or QApplication([])
