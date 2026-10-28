"""What every flow hands the window: sections of lines, each with a level that picks its colour."""

from dataclasses import dataclass, field


@dataclass
class Check:
    name: str
    passed: bool
    message: str
    details: dict = field(default_factory=dict)
    warnings: list[str] = field(default_factory=list)
    informational: bool = False
    optional_fix: str | None = None

    @property
    def level(self) -> str:
        if self.warnings:
            return "warn"
        if self.informational:
            return "info"
        return "pass" if self.passed else "fail"

    def lines(self) -> list[str]:
        if self.warnings:
            return [f"[WARN] {w}" for w in self.warnings]
        return [f"[{self.level.upper()}] {self.name}: {self.message}"]


@dataclass
class Section:
    heading: str
    lines: list[str] = field(default_factory=list)
    level: str = "info"  # info | pass | warn | fail


@dataclass
class Result:
    title: str
    status: str = "ok"  # ok | issues | error
    summary: str = ""
    sections: list[Section] = field(default_factory=list)
    exit_code: int = 0


def worst_level(checks: list[Check]) -> str:
    levels = {c.level for c in checks}
    for level in ("fail", "warn", "pass"):
        if level in levels:
            return level
    return "info"
