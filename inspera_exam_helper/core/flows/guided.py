"""Run recommended steps: Prepare with apply, a light readiness pass, then the launch checklist."""

from inspera_exam_helper.core.flows import preflight as preflight_flow
from inspera_exam_helper.core.flows import prepare as prepare_flow
from inspera_exam_helper.core.flows import reminders
from inspera_exam_helper.core.result import STATUS_LEVEL, Result, Section

TITLE = "Recommended steps"


def run(ctx) -> Result:
    first = prepare_flow.run(ctx, apply=True)
    sections = [Section("Step 1: Prepare my PC", [first.summary], STATUS_LEVEL[first.status]), *first.sections]
    second = preflight_flow.run(ctx, skip_environment=True, skip_system=True, skip_diagnosis=True)
    sections.append(Section("Step 2: Readiness check", [second.summary], STATUS_LEVEL[second.status]))

    sections += [s for s in second.sections if s.level != "pass"]
    sections.append(Section("Step 3: Before you launch Inspera", list(reminders.GUIDED), "info"))
    issues = (first.status != "ok") + second.exit_code
    summary = (
        "All recommended steps complete. You can launch Inspera now."
        if not issues
        else "Some issues remain. Review the sections below before launching Inspera."
    )
    return Result(TITLE, "ok" if not issues else "issues", summary, sections, 1 if issues else 0)
