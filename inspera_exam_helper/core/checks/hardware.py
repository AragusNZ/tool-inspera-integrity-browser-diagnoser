"""Checks about what is plugged in and switched on: displays, power, memory, disk, graphics, webcam."""

import os
import re

from inspera_exam_helper.core.checks import probes
from inspera_exam_helper.core.result import Check

BASIC_ADAPTER = re.compile(r"Microsoft Basic Display|Standard VGA", re.I)
MIN_FREE_MEMORY_MB = 2048
MIN_DISK_MB = 500
MIN_DISK_MB_PROCTORED = 1024  # proctored exams record locally, ~75 MB per hour


def display_count(max_displays: int = 1) -> Check:
    check = Check("Display count", False, "")
    try:
        count = probes.display_count()
        check.details = {"count": count}
        check.passed = count <= max_displays
        check.message = (
            f"{count} display(s) detected"
            if check.passed
            else f"{count} displays detected  - disconnect secondary monitor for IIB checks"
        )
    except Exception as exc:
        check.passed = True
        check.message = f"Display count check skipped: {exc}"
    return check


def power_state() -> Check:
    check = Check("Power state", False, "")
    try:
        battery = probes.battery()
        if battery is None:
            check.passed = True
            check.message = "No battery detected (desktop PC or always plugged in)"
        elif battery.power_plugged:
            check.passed = True
            check.message = "On AC power / charging"
        else:
            check.message = "Running on battery  - plug in charger before exam"
        check.details = {"plugged": None if battery is None else battery.power_plugged}
    except Exception as exc:
        check.passed = True
        check.message = f"Power state check skipped: {exc}"
    return check


def free_memory(min_free_mb: int = MIN_FREE_MEMORY_MB) -> Check:
    check = Check("Free memory", False, "")
    try:
        mem = probes.memory()
        free_mb, total_mb = round(mem.available / 1024 / 1024), round(mem.total / 1024 / 1024)
        check.details = {"free_mb": free_mb, "total_mb": total_mb}
        check.passed = free_mb >= min_free_mb
        check.message = (
            f"{free_mb} MB free of {total_mb} MB total"
            if check.passed
            else f"Only {free_mb} MB free (need {min_free_mb} MB)  - close applications"
        )
    except Exception as exc:
        check.passed = True
        check.message = f"Free memory check skipped: {exc}"
    return check


def disk_space(proctored: bool = False) -> Check:
    min_mb = MIN_DISK_MB_PROCTORED if proctored else MIN_DISK_MB
    check = Check("Disk space (proctored)" if proctored else "Disk space", False, "")
    drive = os.environ.get("SYSTEMDRIVE", "C:") + "\\"
    try:
        free_mb = probes.disk_free_mb(drive)
        check.details = {"free_mb": free_mb, "min_mb": min_mb}
        check.passed = free_mb >= min_mb
        check.message = (
            f"{round(free_mb / 1024, 1)} GB free on {drive[:2]}"
            if check.passed
            else f"Only {free_mb} MB free on {drive[:2]}  - need {min_mb} MB, delete or move files"
        )
    except Exception as exc:
        check.passed = True
        check.message = f"Disk space check skipped: {exc}"
    return check


def graphics_driver() -> Check:
    """IIB's UI (Fyne/GLFW) needs an OpenGL 2.0 capable driver; the basic adapter has none."""
    check = Check("Graphics driver", False, "")
    try:
        controllers = probes.video_controllers()
        check.details = {"adapters": [f"{c.get('Name')} ({c.get('DriverVersion')})" for c in controllers]}
        basic = [c for c in controllers if BASIC_ADAPTER.search(c.get("Name") or "")]
        faulty = [c for c in controllers if c.get("Status") and c["Status"] != "OK"]
        if not controllers or len(basic) == len(controllers):
            check.message = (
                "No real graphics driver installed (Microsoft Basic Display Adapter)  - "
                "update graphics drivers or Inspera may crash"
            )
        elif faulty:
            check.message = (
                f"Graphics adapter reports status '{faulty[0]['Status']}'  - update or reinstall graphics drivers"
            )
        else:
            check.passed = True
            check.message = next(c["Name"] for c in controllers if c not in basic)
    except Exception as exc:
        check.passed = True
        check.message = f"Graphics driver check skipped: {exc}"
    return check


def webcam() -> Check:
    check = Check("Webcam (proctored)", False, "")
    try:
        names = probes.cameras()
        check.details = {"cameras": names}
        if not names:
            check.message = (
                "No webcam detected  - proctored exams need a working camera (check privacy shutter and Device Manager)"
            )
            return check
        check.passed = True
        check.message = f"{len(names)} camera(s): {', '.join(names)}"
        if any(re.search("LifeCam HD-3000", n, re.I) for n in names):
            check.warnings.append(
                "Microsoft LifeCam HD-3000 detected  - known to fail Inspera's camera check, use a different webcam"
            )
        if len(names) > 1:
            check.warnings.append(
                f"{len(names)} cameras detected  - if Inspera picks the wrong one, select it manually in Inspera "
                "or disable the other in Device Manager"
            )
    except Exception as exc:
        check.passed = True
        check.message = f"Webcam check skipped: {exc}"
    return check
