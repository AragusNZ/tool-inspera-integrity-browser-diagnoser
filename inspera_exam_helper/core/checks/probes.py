"""The thin Windows calls behind every check. Each returns plain values and nothing else.

Coverage-omitted and never imported by tests directly: the decision functions beside this module
are what get tested, with these monkeypatched. Anything with `ctypes.windll`, `winreg` or
`win32com` only works on Windows and is imported inside the function for that reason.
"""

import ctypes
import os
import shutil
import socket
import subprocess
import time
import urllib.request
from pathlib import Path

import psutil

SM_CMONITORS = 80
SM_REMOTESESSION = 0x1000
PF_SSE4_2_INSTRUCTIONS_AVAILABLE = 38


def wmi(class_name: str, where: str | None = None) -> list[dict]:
    import win32com.client  # noqa: PLC0415 -- pywin32 is a Windows-only dependency

    query = f"SELECT * FROM {class_name}" + (f" WHERE {where}" if where else "")
    service = win32com.client.GetObject("winmgmts:")
    return [{p.Name: p.Value for p in item.Properties_} for item in service.ExecQuery(query)]


def os_info() -> dict:
    return wmi("Win32_OperatingSystem")[0]


def processor_architecture() -> str:
    return os.environ.get("PROCESSOR_ARCHITECTURE", "")


def s_mode() -> bool:
    import winreg  # noqa: PLC0415

    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\CI\Policy") as key:
            return winreg.QueryValueEx(key, "SkuPolicyRequired")[0] == 1
    except OSError:
        return False


def file_version(path: Path) -> str | None:
    import win32api  # noqa: PLC0415

    try:
        info = win32api.GetFileVersionInfo(str(path), "\\")
    except Exception:
        return None
    ms, ls = info["FileVersionMS"], info["FileVersionLS"]
    return f"{ms >> 16}.{ms & 0xFFFF}.{ls >> 16}.{ls & 0xFFFF}"


def pids_named(name: str) -> list[int]:
    name = name.lower()
    return [p.info["pid"] for p in psutil.process_iter(["pid", "name"]) if (p.info["name"] or "").lower() == name]


def ntp_response(server: str, timeout: float) -> bytes:
    """One SNTP request; raises socket.timeout when UDP 123 is blocked."""
    packet = bytearray(48)
    packet[0] = 0x1B
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(timeout)
        sock.sendto(packet, (server, 123))
        return sock.recv(48)


def display_count() -> int:
    return ctypes.windll.user32.GetSystemMetrics(SM_CMONITORS)


def is_remote_session() -> bool:
    return bool(ctypes.windll.user32.GetSystemMetrics(SM_REMOTESESSION))


def battery():
    return psutil.sensors_battery()


def memory():
    return psutil.virtual_memory()


def disk_free_mb(drive: str) -> int:
    return shutil.disk_usage(drive).free // (1024 * 1024)


def cpu_name() -> str:
    return wmi("Win32_Processor")[0].get("Name") or ""


def sse42() -> bool:
    return bool(ctypes.windll.kernel32.IsProcessorFeaturePresent(PF_SSE4_2_INSTRUCTIONS_AVAILABLE))


def video_controllers() -> list[dict]:
    return wmi("Win32_VideoController")


def http_head(url: str, timeout: float) -> tuple[int, int]:
    """(status, milliseconds). Raises on any network error."""
    request = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "inspera-exam-helper"})
    started = time.perf_counter()
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.status, int((time.perf_counter() - started) * 1000)


def is_admin() -> bool:
    return bool(ctypes.windll.shell32.IsUserAnAdmin())


def keyboard_languages() -> list[str]:
    """The user's language list, as Settings shows it - the same source Get-WinUserLanguageList reads."""
    import winreg  # noqa: PLC0415

    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Control Panel\International\User Profile") as key:
        return list(winreg.QueryValueEx(key, "Languages")[0])


def computer_system() -> dict:
    return wmi("Win32_ComputerSystem")[0]


def enabled_virtualization_features() -> list[str]:
    where = "Name='Microsoft-Hyper-V-All' OR Name='Microsoft-Hyper-V' OR Name='VirtualMachinePlatform'"
    return [f["Name"] for f in wmi("Win32_OptionalFeature", where) if f.get("InstallState") == 1]


def cameras() -> list[str]:
    return [
        c["Name"] for c in wmi("Win32_PnPEntity", "PNPClass='Camera' OR PNPClass='Image'") if c.get("Status") == "OK"
    ]


def wsl_available() -> bool:
    return shutil.which("wsl") is not None


def wsl_running() -> tuple[int, str]:
    """wsl.exe writes UTF-16; decoding as such is what strips the embedded nulls."""
    completed = subprocess.run(["wsl", "-l", "--running"], capture_output=True, check=False)
    return completed.returncode, (completed.stdout + completed.stderr).decode("utf-16", errors="replace")


def wsl_shutdown() -> None:
    subprocess.run(["wsl", "--shutdown"], capture_output=True, check=False)
