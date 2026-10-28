from inspera_exam_helper.core.logs.lines import parse_line


def test_electron_bracket_format():
    p = parse_line("[2026-03-15 09:12:34.123] [error] Environment - failure")
    assert p.level == "error"
    assert p.message == "Environment - failure"
    assert p.timestamp


def test_go_launcher_format():
    p = parse_line("2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3")
    assert p.timestamp == "2026/06/09 22:47:09"
    assert "launching Inspera" in p.message
    assert p.level is None


def test_go_launcher_levels():
    assert parse_line("2026/06/09 22:47:09 iceworm exited: exit status 1").level == "ERROR"
    assert parse_line("2026/06/09 22:47:09 iceworm: Info: hello").level == "INFO"
    p = parse_line("2026/06/09 22:47:09 iceworm: Error: bad")
    assert (p.level, p.module) == ("ERROR", "iceworm")


def test_structured_module_format():
    p = parse_line("2026-03-15 09:12:01.005 [01] - INFO: [SystemCheck] Running check")
    assert p.level == "INFO"
    assert p.module == "SystemCheck"
    assert p.message == "Running check"


def test_iso_and_generic_and_keyword():
    assert parse_line("2026-06-09T10:15:01.123Z [WARN] slow").level == "WARN"
    p = parse_line("2026-06-09 10:15:01 something failed with ERROR code")
    assert p.timestamp.startswith("2026-06-09 10:15:01")
    assert parse_line("something failed with ERROR code").level == "ERROR"
    assert parse_line("   ").message == ""


def test_json_line():
    p = parse_line('{"level":"error","msg":"Clock accuracy - failure","timestamp":"t","context":"check"}')
    assert (p.level, p.message, p.timestamp, p.module) == ("error", "Clock accuracy - failure", "t", "check")
    assert parse_line("{not json}").json is None
    assert parse_line("[1, 2]").json is None


def test_json_non_string_values_are_coerced():
    p = parse_line('{"level":50,"msg":123,"context":{"a":1}}')
    assert (p.level, p.message) == ("50", "123")
    assert isinstance(p.module, str)
