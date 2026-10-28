from inspera_exam_helper.core.catalog import catalog
from inspera_exam_helper.core.logs.patterns import FAILURE_PATTERNS, check_key, is_generic_failure


def test_includes_major_check_names():
    keys = {p.key for p in FAILURE_PATTERNS}
    assert {
        "Environment - failure",
        "Clock accuracy - failure",
        "CPU features - failure",
        "failed to close",
        "Full disk access",
        "Configuration download failed",
        "IIB already running",
    } <= keys


def test_every_pattern_key_has_catalog_entry():
    entries = catalog()
    for key in {p.key for p in FAILURE_PATTERNS}:
        assert key in entries, key
        assert entries[key]["title"]
        assert entries[key]["userMessage"]
        assert entries[key]["fixes"]


def test_catalog_fixes_name_buttons_not_scripts():
    for entry in catalog().values():
        for fix in entry["fixes"]:
            assert ".ps1" not in fix, fix


def test_check_key():
    assert check_key('"Environment"') == "Environment - failure"
    assert check_key("memory check") == "Memory Check - failure"
    assert check_key("nope") is None


def test_generic_failure():
    assert is_generic_failure("something failed", "something failed")
    assert is_generic_failure("an error here", "an error here")
    assert not is_generic_failure("completed with no error", "completed with no error")
    assert not is_generic_failure("Fyne error: x", "Fyne error: x")
    assert not is_generic_failure("fine", "fine")
