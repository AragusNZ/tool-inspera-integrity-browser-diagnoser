"""The four things a button can do. Each takes a Context: config, the log parsed once, and the URL to probe."""

import re
from dataclasses import dataclass

from inspera_exam_helper.core.config import Config, load_config
from inspera_exam_helper.core.logs.parser import ParsedLog, parse_log

DEFAULT_URL = "https://www.inspera.com"


@dataclass
class Context:
    config: Config
    log: ParsedLog
    url: str
    proctored: bool = False
    max_displays: int = 1


def resolve_url(log: ParsedLog, config: Config, inspera_url: str | None) -> str:
    """An explicit non-default URL wins; then the tenant the log named; then config."""
    if inspera_url and inspera_url != DEFAULT_URL:
        return inspera_url
    if tenant := str(log.metadata.get("tenant") or "").strip():
        return tenant if re.match("^https?://", tenant, re.I) else f"https://{tenant}"
    return config.inspera_url or DEFAULT_URL


def context(
    log_path=None,
    inspera_url: str | None = None,
    proctored: bool = False,
    max_displays: int = 1,
    config: Config | None = None,
) -> Context:
    config = config or load_config()
    log = parse_log(log_path, config)
    return Context(config, log, resolve_url(log, config, inspera_url), proctored, max_displays)
