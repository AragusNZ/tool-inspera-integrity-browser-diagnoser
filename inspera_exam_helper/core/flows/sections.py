"""The two sections Prepare and Am I ready share: the environment audit and the readiness list."""

from inspera_exam_helper.core import checks, processes
from inspera_exam_helper.core.result import Section


def environment_section(apply: bool) -> tuple[Section, int]:
    """(section, issue count). Virtualization is advisory: Hyper-V/VMP is common (WSL2, Docker) and only
    matters if IIB's own Environment check fails."""
    results = checks.environment_audit()
    lines: list[str] = []
    issues = 0
    for check in results:
        if check.name == "Virtualization features":
            lines += [f"[WARN] {w}" for w in check.warnings] or ["[PASS] No virtualization warnings"]
            continue
        lines += check.lines()
        issues += not check.passed
    wsl = next((c for c in results if c.name == "WSL status"), None)
    if wsl and not wsl.passed and wsl.optional_fix and apply:
        lines.append(f"[INFO] {processes.wsl_shutdown(apply=True)[1]}")
    elif wsl and not wsl.passed and not apply:
        lines.append("[INFO] WSL is running - will be shut down when you prepare with Apply")
    return Section("Environment", lines, "warn" if issues else "pass"), issues


def system_checks_section(config, url: str, proctored: bool, max_displays: int) -> tuple[Section, int, int]:
    """(section, fail count, total)."""
    results = checks.system_checks(config, url, proctored, max_displays)
    lines = [line for c in results for line in c.lines()]
    fails = sum(c.level == "fail" for c in results)
    return Section("System readiness", lines, "fail" if fails else "pass"), fails, len(results)
