"""Every check's decision, with the Windows probe faked. The live probes run in test_live.py on Windows."""

from datetime import UTC, datetime
from types import SimpleNamespace

import pytest

from inspera_exam_helper.core.checks import hardware, network, platform, probes, software


def raise_(exc):
    def _raise(*a, **k):
        raise exc

    return _raise


def test_os_support(monkeypatch):
    monkeypatch.setattr(
        probes, "os_info", lambda: {"Version": "10.0.22631", "Caption": "Windows 11 Pro", "OSArchitecture": "64-bit"}
    )
    monkeypatch.setattr(probes, "processor_architecture", lambda: "ARM64")
    monkeypatch.setattr(probes, "s_mode", lambda: True)
    check = platform.os_support()
    assert check.passed and check.level == "warn"
    assert len(check.warnings) == 2
    assert check.lines()[0].startswith("[WARN] ARM")
    monkeypatch.setattr(
        probes, "os_info", lambda: {"Version": "6.1", "Caption": "Windows 7", "OSArchitecture": "64-bit"}
    )
    assert not platform.os_support().passed
    monkeypatch.setattr(probes, "os_info", lambda: {"Version": "10.0", "Caption": "W10", "OSArchitecture": "32-bit"})
    assert "32-bit Windows is not supported" in platform.os_support().message
    monkeypatch.setattr(probes, "os_info", raise_(RuntimeError("no wmi")))
    check = platform.os_support()
    assert check.passed and "skipped" in check.message


def test_admin_rdp_vm(monkeypatch):
    monkeypatch.setattr(probes, "is_admin", lambda: False)
    check = platform.admin_rights()
    assert check.informational and check.lines() == [f"[INFO] Administrator rights: {check.message}"]
    monkeypatch.setattr(probes, "is_admin", raise_(OSError()))
    assert platform.admin_rights().message == "Administrator check skipped"
    monkeypatch.setattr(probes, "is_remote_session", lambda: True)
    assert not platform.rdp_session().passed
    monkeypatch.setattr(probes, "is_remote_session", raise_(OSError()))
    assert platform.rdp_session().passed
    monkeypatch.setattr(probes, "computer_system", lambda: {"Manufacturer": "innotek GmbH", "Model": "VirtualBox"})
    assert not platform.virtual_machine().passed
    monkeypatch.setattr(probes, "computer_system", lambda: {"Manufacturer": "Dell", "Model": "XPS"})
    assert platform.virtual_machine().passed
    monkeypatch.setattr(probes, "computer_system", raise_(OSError()))
    assert platform.virtual_machine().message == "Virtual machine check skipped"


def test_sse42(monkeypatch):
    monkeypatch.setattr(probes, "cpu_name", lambda: "Intel Core(TM) i7")
    monkeypatch.setattr(probes, "sse42", lambda: True)
    assert platform.sse42().passed
    monkeypatch.setattr(probes, "sse42", lambda: False)
    assert "does NOT support" in platform.sse42().message
    monkeypatch.setattr(probes, "sse42", raise_(AttributeError()))
    check = platform.sse42()
    assert check.passed and check.details["source"] == "cpu-name-heuristic"
    monkeypatch.setattr(probes, "cpu_name", lambda: "Mystery CPU")
    assert platform.sse42().informational
    monkeypatch.setattr(probes, "cpu_name", raise_(OSError()))
    assert platform.sse42().informational


def test_virtualization_features(monkeypatch):
    monkeypatch.setattr(
        probes,
        "enabled_virtualization_features",
        lambda: ["Microsoft-Hyper-V", "Microsoft-Hyper-V-All", "VirtualMachinePlatform"],
    )
    check = platform.virtualization_features()
    assert check.passed and check.level == "warn"
    assert check.details["enabled"] == ["Hyper-V", "Virtual Machine Platform"]
    monkeypatch.setattr(probes, "enabled_virtualization_features", lambda: [])
    assert platform.virtualization_features().level == "pass"
    monkeypatch.setattr(probes, "enabled_virtualization_features", raise_(OSError()))
    assert "skipped" in platform.virtualization_features().message


def test_displays_power_memory_disk(monkeypatch):
    monkeypatch.setattr(probes, "display_count", lambda: 2)
    assert not hardware.display_count(1).passed
    assert hardware.display_count(2).passed
    monkeypatch.setattr(probes, "display_count", raise_(OSError("x")))
    assert "Could not enumerate" in hardware.display_count().message
    monkeypatch.setattr(probes, "battery", lambda: None)
    assert hardware.power_state().passed
    monkeypatch.setattr(probes, "battery", lambda: SimpleNamespace(power_plugged=False))
    assert not hardware.power_state().passed
    monkeypatch.setattr(probes, "battery", lambda: SimpleNamespace(power_plugged=True))
    assert hardware.power_state().message == "On AC power / charging"
    monkeypatch.setattr(probes, "battery", raise_(OSError("x")))
    assert hardware.power_state().passed
    mb = 1024 * 1024
    monkeypatch.setattr(probes, "memory", lambda: SimpleNamespace(available=4096 * mb, total=16384 * mb))
    assert hardware.free_memory().message == "4096 MB free of 16384 MB total"
    monkeypatch.setattr(probes, "memory", lambda: SimpleNamespace(available=100 * mb, total=16384 * mb))
    assert not hardware.free_memory().passed
    monkeypatch.setattr(probes, "memory", raise_(OSError("x")))
    assert not hardware.free_memory().passed
    monkeypatch.setattr(probes, "disk_free_mb", lambda drive: 2048)
    assert hardware.disk_space().message.startswith("2.0 GB free on")
    assert hardware.disk_space(proctored=True).name == "Disk space (proctored)"
    monkeypatch.setattr(probes, "disk_free_mb", lambda drive: 600)
    assert not hardware.disk_space(proctored=True).passed
    monkeypatch.setattr(probes, "disk_free_mb", raise_(OSError("x")))
    assert hardware.disk_space().passed


def test_graphics_and_webcam(monkeypatch):
    monkeypatch.setattr(
        probes,
        "video_controllers",
        lambda: [{"Name": "Microsoft Basic Display Adapter", "DriverVersion": "1", "Status": "OK"}],
    )
    assert "No real graphics driver" in hardware.graphics_driver().message
    monkeypatch.setattr(
        probes, "video_controllers", lambda: [{"Name": "NVIDIA", "DriverVersion": "1", "Status": "Error"}]
    )
    assert "status 'Error'" in hardware.graphics_driver().message
    monkeypatch.setattr(
        probes,
        "video_controllers",
        lambda: [{"Name": "Microsoft Basic Display Adapter", "Status": "OK"}, {"Name": "NVIDIA", "Status": "OK"}],
    )
    assert hardware.graphics_driver().message == "NVIDIA"
    monkeypatch.setattr(probes, "video_controllers", raise_(OSError("x")))
    assert hardware.graphics_driver().passed
    monkeypatch.setattr(probes, "cameras", lambda: [])
    assert not hardware.webcam().passed
    monkeypatch.setattr(probes, "cameras", lambda: ["Microsoft LifeCam HD-3000", "Integrated"])
    check = hardware.webcam()
    assert check.passed and len(check.warnings) == 2
    monkeypatch.setattr(probes, "cameras", raise_(OSError("x")))
    assert hardware.webcam().passed


def test_network_and_quality(monkeypatch):
    monkeypatch.setattr(probes, "http_head", lambda url, timeout: (200, 50))
    assert network.network("https://x").message == "Reachable (50 ms)  - https://x"
    monkeypatch.setattr(probes, "http_head", lambda url, timeout: (500, 50))
    assert "Unexpected status 500" in network.network("https://x").message
    monkeypatch.setattr(probes, "http_head", raise_(OSError("down")))
    assert network.network("https://x").message == "Cannot reach https://x  - down"
    assert "3/3 attempts failed" in network.connection_quality("https://x").message
    samples = iter([(200, 100), (503, 1), (200, 300)])
    monkeypatch.setattr(probes, "http_head", lambda url, timeout: next(samples))
    check = network.connection_quality("https://x")
    assert check.passed and check.message == "Avg latency 200ms, max 300ms (2/3 OK)"
    monkeypatch.setattr(probes, "http_head", lambda url, timeout: (200, 5000))
    assert "High latency" in network.connection_quality("https://x").message


def test_ntp_decode():
    packet = bytearray(48)
    packet[40:44] = bytes.fromhex("E87A9E00")  # 3900349952 s since 1900 -> mid 2023
    packet[44] = 0x80  # +0.5 s
    dt = network.decode_ntp(bytes(packet))
    assert (dt.year, dt.microsecond, dt.tzinfo) == (2023, 500000, UTC)
    with pytest.raises(ValueError, match="shorter"):
        network.decode_ntp(b"\0" * 10)


def test_clock_skew(monkeypatch):
    def reply(skew):
        secs = int((datetime.now(UTC) - network.NTP_EPOCH).total_seconds()) + skew
        return bytes(40) + secs.to_bytes(4, "big") + bytes(4)

    monkeypatch.setattr(probes, "ntp_response", lambda server, timeout: reply(0))
    assert network.clock_skew().passed
    monkeypatch.setattr(probes, "ntp_response", lambda server, timeout: reply(120))
    assert "exceeds 30s" in network.clock_skew().message
    monkeypatch.setattr(probes, "ntp_response", raise_(TimeoutError()))
    assert "timed out" in network.clock_skew().message
    monkeypatch.setattr(probes, "ntp_response", raise_(OSError("dns")))
    assert network.clock_skew().message == "Could not verify clock: dns"


def test_iib_version(monkeypatch, tmp_path):
    monkeypatch.setattr(probes, "file_version", lambda p: "1.16.3.0")
    for var in ("ProgramFiles", "ProgramFiles(x86)", "LocalAppData", "ProgramData"):
        monkeypatch.delenv(var, raising=False)
    assert "not found" in software.iib_version("1.15.4").message
    monkeypatch.setenv("ProgramFiles", str(tmp_path))
    folder = tmp_path / "Inspera Integrity Browser"
    folder.mkdir()
    assert software.iib_version("1.15.4").message == f"Found installation folder: {folder}"
    (folder / "other.exe").write_bytes(b"")
    (folder / "sub").mkdir()
    (folder / "sub" / "inspera-launcher.exe").write_bytes(b"")
    check = software.iib_version("1.15.4")
    assert check.passed and check.details["path"].endswith("inspera-launcher.exe")
    assert not software.iib_version("2.0.0").passed
    (tmp_path / "Inspera Exam Portal").mkdir()
    assert software.iib_version("1.15.4").level == "warn"


def test_iib_running_and_temp(monkeypatch):
    monkeypatch.setattr(probes, "pids_named", lambda name: [42])
    check = software.iib_running()
    assert not check.passed and check.level == "warn"
    monkeypatch.setattr(probes, "pids_named", lambda name: [])
    assert software.iib_running().passed
    assert software.temp_writable().passed
    monkeypatch.setattr(software.tempfile, "gettempdir", lambda: "/nonexistent/dir")
    assert not software.temp_writable().passed


def test_keyboard_language(monkeypatch):
    monkeypatch.setattr(probes, "keyboard_languages", lambda: ["en-NZ", "mi"])
    check = software.keyboard_language(())
    assert check.informational and check.message.startswith("Active: en-NZ, mi")
    assert software.keyboard_language(("en",)).message == "Approved layout active: en-NZ"
    assert software.keyboard_language(("EN-nz",)).passed
    assert not software.keyboard_language(("de",)).passed
    monkeypatch.setattr(probes, "keyboard_languages", raise_(OSError("reg")))
    assert software.keyboard_language(("en",)).informational


def test_wsl_running(monkeypatch):
    monkeypatch.setattr(probes, "wsl_available", lambda: False)
    assert software.wsl_running().passed
    monkeypatch.setattr(probes, "wsl_available", lambda: True)
    monkeypatch.setattr(probes, "wsl_running", lambda: (0, "Ubuntu (Default)"))
    check = software.wsl_running()
    assert not check.passed and check.optional_fix == "wsl --shutdown"
    monkeypatch.setattr(probes, "wsl_running", lambda: (0, "There are no running distributions."))
    assert software.wsl_running().passed
    monkeypatch.setattr(probes, "wsl_running", raise_(OSError()))
    assert software.wsl_running().message == "WSL check skipped"
