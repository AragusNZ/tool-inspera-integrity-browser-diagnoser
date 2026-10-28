import getpass
import tempfile
from pathlib import Path

from inspera_exam_helper.core import paths
from inspera_exam_helper.core.config import Config, expand_path, load_config
from inspera_exam_helper.core.logs.discovery import find_log, search_directories


def test_committed_config_uses_placeholders_not_usernames():
    raw = (paths.DATA / "config.json").read_text(encoding="utf-8")
    assert "\\Users\\" not in raw
    config = load_config()
    assert config.log_directories
    assert config.fallback_to_user_temp
    assert config.minimum_iib_version == "1.15.4"
    assert config.approved_keyboard_languages == ()


def test_missing_or_broken_config_means_defaults(tmp_path):
    assert load_config(tmp_path / "nope.json") == Config()
    broken = tmp_path / "config.json"
    broken.write_text("{nope", encoding="utf-8")
    assert load_config(broken) == Config()


def test_bom_non_object_and_string_lists(tmp_path):
    p = tmp_path / "config.json"
    p.write_text('{"approvedKeyboardLanguages": "en-NZ", "logDirectories": "C:\\\\logs"}', encoding="utf-8-sig")
    c = load_config(p)
    assert c.approved_keyboard_languages == ("en-NZ",)
    assert c.log_directories == ("C:\\logs",)
    for raw in ("[1, 2]", "null", '"x"'):
        p.write_text(raw, encoding="utf-8")
        assert load_config(p) == Config()


def test_partial_config_fills_defaults(tmp_path):

    p = tmp_path / "config.json"
    p.write_text('{"logDirectories": ["%TEMP%", ""], "insperaUrl": "", "fallbackToUserTemp": false}', encoding="utf-8")
    c = load_config(p)
    assert c.log_directories == ("%TEMP%",)
    assert c.inspera_url == "https://www.inspera.com"
    assert c.fallback_to_user_temp is False


def test_config_beside_exe_wins(tmp_path, monkeypatch):
    monkeypatch.setattr(paths, "app_root", lambda: tmp_path)
    assert paths.config_path() == paths.DATA / "config.json"
    (tmp_path / "config.json").write_text("{}", encoding="utf-8")
    assert paths.config_path() == tmp_path / "config.json"


def test_expand_path():
    assert expand_path("C:\\Users\\%username%\\x") == f"C:\\Users\\{getpass.getuser()}\\x"
    assert expand_path("%TEMP%") == tempfile.gettempdir().rstrip("\\")
    assert expand_path("%USERPROFILE%\\a") == f"{Path.home()}\\a"
    assert expand_path("  ") is None


def test_search_directories_configured_then_fallback(tmp_path):
    dirs = search_directories(Config(log_directories=(str(tmp_path), str(tmp_path).upper())))
    assert dirs == [str(tmp_path), tempfile.gettempdir()]
    assert search_directories(Config(fallback_to_user_temp=False)) == [tempfile.gettempdir()]


def test_find_log_picks_highest_session_number(tmp_path):
    (tmp_path / "inspera-launcher-100.log").write_text("old")
    (tmp_path / "inspera-launcher-999.log").write_text("new")
    (tmp_path / "inspera-launcher-x.log").write_text("odd")
    config = Config(log_directories=(str(tmp_path),), fallback_to_user_temp=False)
    assert find_log(None, config).name == "inspera-launcher-999.log"
    assert find_log(tmp_path / "inspera-launcher-100.log", config).name == "inspera-launcher-100.log"
    assert find_log(tmp_path / "missing.log", config) is None
    assert find_log(None, Config(log_directories=(str(tmp_path / "empty"),), fallback_to_user_temp=False)) is None
