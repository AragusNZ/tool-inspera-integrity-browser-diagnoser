"""Size and boundary caps for this repo -- the `module-size` and `qt-boundary` rules, enforced.

Copied from the python-core plugin template. The two tuples below are the only edits.
"""

from __future__ import annotations

import ast
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = next(p for p in sorted(ROOT.iterdir()) if (p / "__init__.py").is_file() and p.name not in ("tests", "tools"))

QT_DIRS: tuple[str, ...] = ("ui", "app")  # under PACKAGE, may import Qt; "." means the whole package
DATA_MODULES: tuple[str, ...] = ()  # repo-relative, exempt from the line cap

MODULE_LINES = 300
FUNCTION_LINES = 40
QT = ("PySide6", "PyQt6", "PyQt5", "shiboken6")


def _py(*roots: Path) -> list[Path]:
    return sorted(p for r in roots for p in r.rglob("*.py") if "__pycache__" not in p.parts)


def _rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()


def _tree(p: Path) -> ast.Module:
    return ast.parse(p.read_text(encoding="utf-8"))


def _imports(tree: ast.AST):
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            yield from (a.name for a in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module:
            yield node.module


def test_modules_stay_short():
    over = {
        _rel(p): n
        for p in _py(PACKAGE, ROOT / "tests")
        if (n := len(p.read_text(encoding="utf-8").splitlines())) > MODULE_LINES and _rel(p) not in DATA_MODULES
    }
    assert not over, f"over {MODULE_LINES} lines, split by domain (package-layout): {over}"


def test_functions_stay_short():
    over = {}
    for p in _py(PACKAGE):
        for node in ast.walk(_tree(p)):
            if isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
                body = node.end_lineno - node.body[0].lineno + 1
                if body > FUNCTION_LINES:
                    over[f"{_rel(p)}:{node.name}"] = body
    assert not over, f"over {FUNCTION_LINES} body lines, extract the stages (module-size): {over}"


def test_qt_stays_in_the_ui_layers():
    allowed = {(PACKAGE / d).resolve() for d in QT_DIRS} | {PACKAGE / "app.py", PACKAGE / "__main__.py"}
    leaks = [
        _rel(p)
        for p in _py(PACKAGE)
        if not any(p == a or a in p.parents for a in allowed) and any(m.split(".")[0] in QT for m in _imports(_tree(p)))
    ]
    assert not leaks, f"Qt imported outside {QT_DIRS} (qt-boundary): {leaks}"


def test_core_imports_only_core():
    core = PACKAGE / "core"
    leaks = {
        _rel(p): m
        for p in (_py(core) if core.is_dir() else [])
        for m in _imports(_tree(p))
        if m.startswith(f"{PACKAGE.name}.") and not m.startswith(f"{PACKAGE.name}.core")
    }
    assert not leaks, f"core/ reaching outward (qt-boundary): {leaks}"
