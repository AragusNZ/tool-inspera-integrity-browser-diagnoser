"""Am I ready? The last failure if there was one, the environment, the readiness list, and what is still running."""

from inspera_exam_helper.core import processes
from inspera_exam_helper.core.flows.diagnose import diagnosis_sections
from inspera_exam_helper.core.flows.sections import environment_section, system_checks_section
from inspera_exam_helper.core.result import Result, Section

TITLE = "Am I ready?"
KEPT_DIAGNOSIS = {"Why Inspera failed", "No log found", "No clear failure found"}


def run(ctx, skip_environment: bool = False, skip_system: bool = False, skip_diagnosis: bool = False) -> Result:
    """The skip flags exist for the guided flow, which has just run Prepare and need not repeat its sections."""
    sections: list[Section] = []
    issues = 0
    live = processes.running_matches(ctx.log.applications)
    if not skip_diagnosis:
        issues += ctx.log.primary is not None
        sections += [s for s in diagnosis_sections(ctx, live) if s.heading in KEPT_DIAGNOSIS]
    if not skip_environment:
        env, env_issues = environment_section(apply=False)
        sections.append(env)
        issues += env_issues
    if not skip_system:
        system, fails, _ = system_checks_section(ctx.config, ctx.url, ctx.proctored, ctx.max_displays)
        sections.append(system)
        issues += fails
    if live:
        lines = [f"[WARN] {m.name} (still running)" for m in live] + [
            "Click 'Prepare my PC' to close these before your exam."
        ]
        issues += len(live)
    else:
        lines = ["[PASS] No interfering apps running"]
    sections.append(Section("Interfering apps", lines, "warn" if live else "pass"))
    summary = "Your PC looks ready for Inspera." if not issues else f"{issues} issue(s) found - see details below."
    return Result(TITLE, "ok" if not issues else "issues", summary, sections, 1 if issues else 0)
