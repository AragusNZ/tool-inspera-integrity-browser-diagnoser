"""The error catalog: one plain-language entry per failure key the log parser can produce."""

import json
from functools import cache

from inspera_exam_helper.core.paths import DATA


@cache
def catalog() -> dict[str, dict]:
    return json.loads((DATA / "error_catalog.json").read_text(encoding="utf-8-sig"))
