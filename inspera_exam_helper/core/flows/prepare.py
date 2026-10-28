"""Prepare my PC: close interfering apps (or list them on a dry run), audit the environment, run the readiness list."""

from inspera_exam_helper.core import processes
from inspera_exam_helper.core.flows import reminders
from inspera_exam_helper.core.flows.sections import environment_section, system_checks_section
from inspera_exam_helper.core.result import Result, Section

TITLE = "Prepare my PC"


def _apps_section(log_apps: list[str], apply: bool) -> tuple[Section, int, bool]:
    """(section, issue count, whether a kill failed)."""
    hits = processes.running_matches(log_apps)
    if not hits:
        return Section("Interfering apps", ["[PASS] No interfering apps running"], "pass"), 0, False
    if not apply:
        lines = [f"[INFO] {len(hits)} app(s) would be closed (dry-run)"]
        lines += [f"  - {h.name}" for h in hits]
        lines.append("Use 'Prepare my PC' in the toolkit to close them.")
        return Section("Interfering apps", lines, "warn"), len(hits), False
    lines = [f"  - {h.name} (found)" for h in hits]
    failed = 0
    for r in processes.cleanup(log_apps, apply=True):
        if r.success:
            lines.append(f"[PASS] {r.name}: closed")
        else:
            lines.append(f"[FAIL] {r.name}: {r.message}")
            failed += 1
    if failed:
        lines.append("Some apps need Administrator - ask exam support to run the toolkit as admin.")
    return Section("Interfering apps", lines, "fail" if failed else "pass"), failed, bool(failed)


def run(ctx, apply: bool) -> Result:
    apps, issues, kill_failed = _apps_section(ctx.log.applications, apply)
    env, env_issues = environment_section(apply)
    system, fails, total = system_checks_section(ctx.config, ctx.url, ctx.proctored, ctx.max_displays)
    issues += env_issues + fails
    sections = [apps, env, system, Section("Before you start Inspera", list(reminders.PREPARE), "info")]
    mode = "Prepare complete" if apply else "Dry-run (no apps closed)"
    summary = f"{mode} - {total - fails}/{total} system checks passed"
    if not apply and apps.level == "warn":
        summary += ". Click Prepare my PC to close interfering apps."
    status = "issues" if (fails or kill_failed or issues) else "ok"
    return Result(TITLE, status, summary, sections, 1 if fails else 0)
