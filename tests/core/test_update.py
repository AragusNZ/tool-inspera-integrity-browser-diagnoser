from inspera_exam_helper.core.update import is_newer, version_key


def test_version_compare():
    assert version_key("v1.16.3.0") == version_key("1.16.3") == (1, 16, 3)
    assert not is_newer("1.0", "1.0.0")
    assert not is_newer("1.0.0", "1.0")
    assert is_newer("1.0.10", "1.0.9")
    assert is_newer("1.15.4.1", "1.15.4")
