"""One log line into (timestamp, level, module, message). IIB has shipped five log formats; all still turn up."""

import json
import re
from dataclasses import dataclass

GO_LAUNCHER = re.compile(r"^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) (.+)$", re.I)
GO_ERROR = re.compile(
    r"^Fyne error:|^GLFW poll event error|iceworm exited: exit status [1-9]|^cancellation detected", re.I
)
ELECTRON = re.compile(r"^\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\]\s+\[(\w+)\]\s+(.*)$", re.I)
STRUCTURED = re.compile(
    r"^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\s+\[(\d+)\]\s+-\s+(\w+):\s+(?:\[([^\]]+)\]\s+)?(.*)$", re.I
)
ISO = re.compile(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?)\s+\[(\w+)\]\s+(.*)$", re.I)
GENERIC_TS = re.compile(r"^\[?(\d{4}[-/]\d{2}[-/]\d{2}[T\s]\d{2}:\d{2}:\d{2}[^\]]*)\]?\s*(.*)$", re.I)
JSON_LINE = re.compile(r"^\s*\{.*\}\s*$", re.I)
LEVEL_WORD = re.compile(r"\b(ERROR|ERR|WARN|WARNING|INFO|DEBUG|FATAL)\b", re.I)


@dataclass
class ParsedLine:
    raw: str
    message: str
    timestamp: str | None = None
    level: str | None = None
    module: str | None = None
    json: dict | None = None


def parse_line(line: str) -> ParsedLine:
    out = ParsedLine(raw=line, message=line.strip())
    if not out.message or _known_format(out, line):
        return out
    if m := GENERIC_TS.match(line):
        out.timestamp, out.message = m.groups()
    if JSON_LINE.match(line):
        _apply_json(out, line)
    if not out.level and (m := LEVEL_WORD.search(out.message)):
        out.level = m.group(1)
    return out


def _known_format(out: ParsedLine, line: str) -> bool:
    """The four formats with a fixed shape; each fills the fields and ends the parse."""
    if m := GO_LAUNCHER.match(line):
        out.timestamp, out.message = m.groups()
        _go_level(out)
    elif m := ELECTRON.match(line):
        out.timestamp, out.level, out.message = m.groups()
    elif m := STRUCTURED.match(line):
        out.timestamp, _, out.level, out.module, out.message = m.groups()
    elif m := ISO.match(line):
        out.timestamp, out.level, out.message = m.groups()
    return m is not None


def _go_level(out: ParsedLine) -> None:
    """The Go launcher logs no level; a few message shapes are errors by content."""
    if GO_ERROR.search(out.message):
        out.level = "ERROR"
    elif re.match("^iceworm:", out.message, re.I):
        out.module = "iceworm"
        if re.search("Info:", out.message, re.I):
            out.level = "INFO"
        if re.search("Error:|Warn:", out.message, re.I):
            out.level = "ERROR"


def _apply_json(out: ParsedLine, line: str) -> None:
    try:
        data = json.loads(line)
    except ValueError:
        return
    if not isinstance(data, dict):
        return
    out.json = data
    out.level = data.get("level") or out.level
    out.message = data.get("msg") or data.get("message") or out.message
    out.timestamp = data.get("timestamp") or out.timestamp
    out.module = data.get("context") or data.get("module") or out.module
