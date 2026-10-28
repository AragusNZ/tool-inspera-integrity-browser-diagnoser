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
        """A failure outranks its warnings: a missing IIB beside a leftover Exam Portal is still a fail."""
        if not self.passed and not self.informational:
            return "fail"
        if self.warnings:
            return "warn"
        return "info" if self.informational else "pass"

    def lines(self) -> list[str]:
        warnings = [f"[WARN] {w}" for w in self.warnings]
        if self.warnings and self.passed:
            return warnings
        return [f"[{self.level.upper()}] {self.name}: {self.message}", *warnings]


@dataclass
class Section:
    heading: str
    lines: list[str] = field(default_factory=list)
    level: str = "info"  # info | pass | warn | fail


# A Result's status as the level that colours it.
STATUS_LEVEL = {"ok": "pass", "issues": "warn", "error": "fail"}


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
