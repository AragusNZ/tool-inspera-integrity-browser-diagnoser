"""The real probes against the real machine. Windows only; the ubuntu leg skips this file."""

import sys

import pytest

from inspera_exam_helper.core import checks
from inspera_exam_helper.core.checks import platform, probes
from inspera_exam_helper.core.config import Config

pytestmark = pytest.mark.skipif(sys.platform != "win32", reason="live Windows probes")


def test_system_checks_run_on_real_windows():
    results = checks.system_checks(Config(), "https://www.inspera.com")
    assert [c.name for c in results if "skipped" in c.message] == []
    assert results[0].passed  # Windows version: CI runners are Windows 10/11 x64
    assert platform.sse42().details["source"] == "IsProcessorFeaturePresent"


def test_environment_audit_runs():
    audit = checks.environment_audit()
    assert audit[1].details["manufacturer"]
    assert isinstance(probes.is_remote_session(), bool)
    assert isinstance(probes.display_count(), int)
    assert isinstance(probes.keyboard_languages(), list)
