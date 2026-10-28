"""Which checks run when. The flows call these three; nothing else reaches the check modules directly."""

from inspera_exam_helper.core.checks import hardware, network, platform, software
from inspera_exam_helper.core.config import Config
from inspera_exam_helper.core.result import Check


def system_checks(config: Config, inspera_url: str, proctored: bool = False, max_displays: int = 1) -> list[Check]:
    """The readiness list. Remote session, VM, WSL and Hyper-V live in environment_audit instead."""
    checks = [
        platform.os_support(),
        software.iib_version(config.minimum_iib_version),
        software.iib_running(),
        network.clock_skew(),
        hardware.display_count(max_displays),
        hardware.power_state(),
        hardware.free_memory(),
        hardware.disk_space(proctored),
        platform.sse42(),
        hardware.graphics_driver(),
        network.network(inspera_url),
        software.temp_writable(),
        software.keyboard_language(config.approved_keyboard_languages),
        platform.admin_rights(),
    ]
    if proctored:
        checks.append(hardware.webcam())
    return checks


def environment_audit() -> list[Check]:
    return [
        platform.rdp_session(),
        platform.virtual_machine(),
        software.wsl_running(),
        platform.virtualization_features(),
    ]


def targeted_checks(
    failure_key: str | None,
    config: Config,
    inspera_url: str,
    connection_check_url: str | None = None,
    max_displays: int = 1,
) -> list[Check]:
    """The live checks worth re-running for one failure key. Blocklist keys are handled by the process scan."""
    if not failure_key:
        return []

    def reach() -> list[Check]:
        urls = [inspera_url] + ([connection_check_url] if connection_check_url else [])
        return [network.network(u) for u in urls] + [network.connection_quality(inspera_url)]

    table: dict[str, list] = {
        "Environment - failure": [environment_audit],
        "Connection quality - failure": [reach],
        "Clock accuracy - failure": [network.clock_skew],
        "Number of screens - failure": [lambda: [hardware.display_count(max_displays)]],
        "Power state - failure": [hardware.power_state],
        "Memory Check - failure": [hardware.free_memory],
        "CPU features - failure": [platform.sse42],
        "App version - failure": [lambda: [software.iib_version(config.minimum_iib_version)]],
        "Incorrect keyboard language": [lambda: [software.keyboard_language(config.approved_keyboard_languages)]],
        "After completion - failed": [lambda: [network.network(inspera_url)]],
        "Screen Capture": [lambda: [hardware.display_count(max_displays)]],
        "Failed to capture screen": [lambda: [hardware.display_count(max_displays)]],
        "Cannot upload files": [lambda: [network.connection_quality(inspera_url)]],
        "desktop changed": [lambda: [hardware.display_count(max_displays)]],
        "iceworm failure": [reach, hardware.graphics_driver],
        "system check aborted": [lambda: [network.network(inspera_url)]],
        "UI runtime error": [hardware.graphics_driver, lambda: [hardware.display_count(max_displays)]],
        "Webcam": [hardware.webcam],
        "Configuration download failed": [platform.admin_rights, lambda: [network.network(inspera_url)]],
        "IIB already running": [software.iib_running],
    }
    out: list[Check] = []
    for step in table.get(failure_key, []):
        result = step()
        out.extend(result if isinstance(result, list) else [result])
    return out
