"""Why did Inspera fail? Read the last log, name the failure, and say what to try."""

from inspera_exam_helper.core import checks, processes
from inspera_exam_helper.core.catalog import catalog
from inspera_exam_helper.core.logs.discovery import search_directories
from inspera_exam_helper.core.processes import Match
from inspera_exam_helper.core.result import Result, Section, worst_level

TITLE = "Why did Inspera fail?"
BLOCKLIST_KEYS = {
    "Environment - failure",
    "failed to close",
    "Process blocklist - failure",
    "iceworm failure",
    "UI runtime error",
}
META_LABELS = (
    ("version", "IIB version"),
    ("session_id", "Session ID"),
    ("tenant", "Tenant"),
    ("last_session_status", "Last status"),
)


def diagnosis_sections(ctx, live_matches: list[Match]) -> list[Section]:
    log = ctx.log
    if not log.found:
        searched = [f"  - {d}" for d in search_directories(ctx.config)]
        return [
            Section(
                "No log found",
                [
                    "Inspera has not written a log file yet, or it is in a different folder.",
                    "Try running Inspera once, then click this button again.",
                    "Searched:",
                    *searched,
                ],
                "warn",
            )
        ]
    sections: list[Section] = []
    if meta := [f"{label}: {log.metadata[key]}" for key, label in META_LABELS if log.metadata.get(key)]:
        sections.append(Section("Last session", meta, "info"))
    if log.primary:
        sections += _failure_sections(ctx, live_matches)
    else:
        sections.append(
            Section(
                "No clear failure found",
                [
                    "The log does not match a known failure pattern.",
                    "If Inspera still fails, ask exam support to review the log file.",
                ],
                "warn",
            )
        )
    if log.applications:
        sections.append(Section("Apps mentioned in log", [f"- {a}" for a in log.applications], "info"))
    return sections


def _failure_sections(ctx, live_matches: list[Match]) -> list[Section]:
    log, key = ctx.log, ctx.log.primary.key
    if entry := catalog().get(key):
        fixes = [f"  {i}. {fix}" for i, fix in enumerate(entry["fixes"], 1)]
        lines = [entry["title"], "", "What this means:", f"  {entry['userMessage']}", "", "What to try:", *fixes]
    else:
        lines = [key, f"  {log.primary.message}"]
    sections = [Section("Why Inspera failed", lines, "fail")]
    if log.failure_details:
        sections.append(Section("Related details", list(log.failure_details), "info"))
    targeted = checks.targeted_checks(
        key, ctx.config, ctx.url, log.metadata.get("connection_check_url"), ctx.max_displays
    )
    if targeted:
        sections.append(Section("Live checks", [line for c in targeted for line in c.lines()], worst_level(targeted)))
    if key in BLOCKLIST_KEYS and live_matches:
        lines = [f"{m.name} (still running)" for m in live_matches] + ["Click 'Prepare my PC', then try Inspera again."]
        sections.append(Section("Apps still running", lines, "warn"))
    return sections


def run(ctx) -> Result:
    sections = diagnosis_sections(ctx, processes.running_matches(ctx.log.applications))
    if not ctx.log.found:
        return Result(TITLE, "error", "No Inspera log file found.", sections, 2)
    if ctx.log.primary:
        return Result(
            TITLE, "issues", "A problem was found in your last Inspera session. See fixes below.", sections, 1
        )
    return Result(TITLE, "ok", "No failure detected in the latest log.", sections, 0)
