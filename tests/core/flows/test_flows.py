"""The four flows against fixtures, with every Windows probe stubbed and the process table faked."""

import pytest

from inspera_exam_helper.core import flows, processes
from inspera_exam_helper.core.checks import probes
from inspera_exam_helper.core.config import Config
from inspera_exam_helper.core.flows import diagnose, guided, preflight, prepare
from inspera_exam_helper.core.flows.diagnose import diagnosis_sections
from inspera_exam_helper.core.flows.sections import environment_section
from inspera_exam_helper.core.logs.parser import ParsedLog
from inspera_exam_helper.core.result import Result, Section

pytestmark = pytest.mark.usefixtures("healthy_probes", "fake_processes")
CONFIG = Config(log_directories=("%TEMP%",), fallback_to_user_temp=False)


def ctx(fixture_path, name="environment-failure.log", **kw):
    return flows.context(fixture_path(name), config=CONFIG, **kw)


def headings(result):
    return [s.heading for s in result.sections]


def section(result, heading):
    return next(s for s in result.sections if s.heading == heading)


def test_resolve_url(fixture_path):
    assert flows.resolve_url(ParsedLog(), CONFIG, "https://custom") == "https://custom"
    assert flows.resolve_url(ParsedLog(), CONFIG, flows.DEFAULT_URL) == "https://www.inspera.com"
    assert ctx(fixture_path, "real-auckland-1781002029.log").url == "https://auckland.inspera.com"
    assert flows.resolve_url(ParsedLog(metadata={"tenant": "http://t"}), CONFIG, None) == "http://t"
    assert flows.resolve_url(ParsedLog(), Config(inspera_url=""), None) == flows.DEFAULT_URL


def test_diagnosis_sections_with_catalog_entry(fixture_path):
    sections = diagnosis_sections(ctx(fixture_path, "electron-log-system-check.log"), [])
    why = [s for s in sections if s.heading == "Why Inspera failed"]
    assert len(why) == 1
    assert "Environment" in "\n".join(why[0].lines)
    assert "What to try:" in why[0].lines


def test_diagnose_missing_log(tmp_path):
    result = diagnose.run(flows.context(tmp_path / "no-such-inspera.log", config=CONFIG))
    assert (result.exit_code, result.status) == (2, "error")
    assert headings(result) == ["No log found"]
    assert any(line.startswith("  - ") for line in result.sections[0].lines)


def test_diagnose_primary_failure(fixture_path, fake_processes):
    fake_processes("Discord.exe")
    result = diagnose.run(ctx(fixture_path))
    assert result.exit_code == 1
    assert result.title == "Why did Inspera fail?"
    assert headings(result).count("Why Inspera failed") == 1
    assert "Live checks" in headings(result)
    assert section(result, "Apps still running").lines[0] == "Discord (still running)"
    assert "- Discord.exe" in section(result, "Apps mentioned in log").lines
    assert "Last session" not in headings(result)  # electron log: no Go-launcher metadata


def test_diagnose_metadata_and_unknown_key(fixture_path, monkeypatch):
    result = diagnose.run(ctx(fixture_path, "real-auckland-1781002029.log"))
    assert section(result, "Last session").lines[0] == "IIB version: 1.16.3"
    monkeypatch.setattr(diagnose, "catalog", lambda: {})
    why = section(diagnose.run(ctx(fixture_path)), "Why Inspera failed")
    assert why.lines[0] == "Environment - failure"


def test_diagnose_clean_log(tmp_path):
    log = tmp_path / "inspera-launcher-1.log"
    log.write_text("2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3\n", encoding="utf-8")
    result = diagnose.run(flows.context(log, config=CONFIG))
    assert (result.exit_code, result.status) == (0, "ok")
    assert "No clear failure found" in headings(result)


def test_prepare_dry_run(fixture_path, fake_processes):
    result = prepare.run(ctx(fixture_path), apply=False)
    assert headings(result) == ["Interfering apps", "Environment", "System readiness", "Before you start Inspera"]
    assert section(result, "Interfering apps").lines == ["[PASS] No interfering apps running"]
    fake_processes("Discord.exe", "obs64.exe")
    result = prepare.run(ctx(fixture_path), apply=False)
    apps = section(result, "Interfering apps")
    assert apps.level == "warn" and apps.lines[0] == "[INFO] 2 app(s) would be closed (dry-run)"
    assert result.status == "issues" and result.exit_code == 0
    assert result.summary.endswith("Click Prepare my PC to close interfering apps.")


def test_prepare_apply(fixture_path, fake_processes, monkeypatch):
    fake_processes("Discord.exe", "obs64.exe")
    monkeypatch.setattr(
        processes, "stop_process", lambda pid, name, apply: processes.StopResult(pid, name, "stopped", True, "")
    )
    result = prepare.run(ctx(fixture_path), apply=True)
    apps = section(result, "Interfering apps")
    assert apps.lines == ["  - Discord (found)", "  - obs64 (found)", "[PASS] Discord: closed", "[PASS] obs64: closed"]
    assert result.summary.startswith("Prepare complete")
    monkeypatch.setattr(
        processes, "stop_process", lambda pid, name, apply: processes.StopResult(pid, name, "failed", False, "no")
    )
    result = prepare.run(ctx(fixture_path), apply=True)
    apps = section(result, "Interfering apps")
    assert apps.level == "fail" and apps.lines[-1].startswith("Some apps need Administrator")
    assert result.status == "issues"


def test_environment_section_wsl_and_virtualization(monkeypatch):
    monkeypatch.setattr(probes, "wsl_available", lambda: True)
    monkeypatch.setattr(probes, "wsl_running", lambda: (0, "Ubuntu"))
    monkeypatch.setattr(probes, "enabled_virtualization_features", lambda: ["VirtualMachinePlatform"])
    sec, issues = environment_section(apply=False)
    assert issues == 1 and sec.level == "warn"
    assert sec.lines[-1] == "[INFO] WSL is running - will be shut down when you prepare with Apply"
    assert any(line.startswith("[WARN] Virtual Machine Platform enabled") for line in sec.lines)
    sec, _ = environment_section(apply=True)
    assert sec.lines[-1] == "[INFO] Skipped WSL shutdown (test mode)"
    monkeypatch.setattr(probes, "enabled_virtualization_features", lambda: [])
    assert "[PASS] No virtualization warnings" in environment_section(apply=False)[0].lines


def test_preflight(fixture_path, fake_processes):
    result = preflight.run(ctx(fixture_path))
    assert headings(result) == ["Why Inspera failed", "Environment", "System readiness", "Interfering apps"]
    assert result.exit_code == 1 and result.summary == "1 issue(s) found - see details below."
    fake_processes("Discord.exe")
    result = preflight.run(ctx(fixture_path), skip_environment=True, skip_system=True, skip_diagnosis=True)
    assert headings(result) == ["Interfering apps"]
    assert result.sections[0].lines[0] == "[WARN] Discord (still running)"


def test_preflight_ready(tmp_path):
    log = tmp_path / "inspera-launcher-1.log"
    log.write_text("2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3\n", encoding="utf-8")
    result = preflight.run(flows.context(log, config=CONFIG))
    assert result.summary == "Your PC looks ready for Inspera."
    assert result.exit_code == 0


def test_guided_calls_prepare_apply_then_light_preflight(fixture_path, monkeypatch):
    calls = []

    def fake_prepare(ctx, apply):
        calls.append(("prepare", apply))
        return Result("Prepare my PC", "ok", "Prepare complete", [Section("Interfering apps", ["[PASS] x"], "pass")])

    def fake_preflight(ctx, **flags):
        calls.append(("preflight", flags))
        return Result("Am I ready?", "ok", "Ready.", [Section("Interfering apps", ["[PASS] x"], "pass")])

    monkeypatch.setattr(guided.prepare_flow, "run", fake_prepare)
    monkeypatch.setattr(guided.preflight_flow, "run", fake_preflight)
    result = guided.run(ctx(fixture_path))
    assert calls == [
        ("prepare", True),
        ("preflight", {"skip_environment": True, "skip_system": True, "skip_diagnosis": True}),
    ]
    assert result.title == "Recommended steps" and result.exit_code == 0
    assert headings(result) == [
        "Step 1: Prepare my PC",
        "Interfering apps",
        "Step 2: Readiness check",
        "Step 3: Before you launch Inspera",
    ]


def test_guided_reports_issues(fixture_path, monkeypatch):
    def issues(*a, **k):
        return Result("P", "issues", "s", [Section("Interfering apps", [], "warn")], 1)

    monkeypatch.setattr(guided.prepare_flow, "run", issues)
    monkeypatch.setattr(guided.preflight_flow, "run", issues)
    result = guided.run(ctx(fixture_path))
    assert result.status == "issues" and result.exit_code == 1
    assert headings(result).count("Interfering apps") == 2
