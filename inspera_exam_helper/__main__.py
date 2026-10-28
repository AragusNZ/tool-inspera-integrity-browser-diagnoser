import sys

from inspera_exam_helper import __version__
from inspera_exam_helper.app import main
from inspera_exam_helper.core.catalog import catalog
from inspera_exam_helper.core.paths import DATA
from inspera_exam_helper.core.processes import default_blocklist
from inspera_exam_helper.ui.theme import asset_path


def self_check() -> int:
    """build.ps1 runs the frozen exe with --check: the bundled data, icon and VERSION all made it in.

    Exit code only, never an exception: a windowed exe would show a dialog and hang the build.
    """
    try:
        catalog()
        default_blocklist()
        ok = __version__ != "0.0.0" and asset_path("icon.ico").is_file() and (DATA / "config.json").is_file()
    except Exception:
        return 1
    return 0 if ok else 1


if "--check" in sys.argv:
    sys.exit(self_check())
main()
