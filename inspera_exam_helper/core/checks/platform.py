"""Checks about the machine itself: Windows build, admin, remote session, VM, CPU, virtualization."""

import re

from inspera_exam_helper.core.checks import probes
from inspera_exam_helper.core.result import Check

VM_FINGERPRINT = re.compile(r"VirtualBox|VMware|Virtual Machine|QEMU|KVM|Parallels|Xen|Bochs|innotek", re.I)
CPU_HEURISTIC = re.compile(r"Core\(TM\) i[3579]|Core\(TM\) Ultra|Ryzen|Xeon|EPYC|Core\(TM\) \d+", re.I)


def os_support() -> Check:
    check = Check("Windows version", False, "")
    try:
        info = probes.os_info()
        caption, version, arch = (
            info.get("Caption") or "",
            str(info.get("Version") or "0"),
            info.get("OSArchitecture") or "",
        )
        check.details = {"caption": caption, "version": version, "architecture": arch}
        if int(version.split(".", maxsplit=1)[0]) < 10:
            check.message = f"{caption} is not supported  - Inspera needs Windows 10 or 11 (64-bit)"
            return check
        if "64" not in arch:
            check.message = f"{arch} Windows is not supported  - Inspera needs 64-bit Windows"
            return check
        check.passed = True
        check.message = f"{caption} ({arch})"
        if probes.processor_architecture() == "ARM64":
            check.warnings.append("ARM-based PC  - Inspera needs IIB version 2.3.0 or newer on ARM")
        if probes.s_mode():
            check.warnings.append(
                "Windows S mode is on  - Inspera cannot be installed until you switch out of S mode "
                "(Settings > System > Activation)"
            )
    except Exception as exc:
        check.passed = True
        check.message = f"Windows version check skipped: {exc}"
    return check


def admin_rights() -> Check:
    check = Check("Administrator rights", True, "", informational=True)
    try:
        is_admin = probes.is_admin()
        check.details = {"is_admin": is_admin}
        check.message = (
            "Running as administrator"
            if is_admin
            else "Not running as administrator  - fine for most exams; "
            "needed to install Inspera and for Strict lockdown exams"
        )
    except Exception:
        check.message = "Administrator check skipped"
    return check


def rdp_session() -> Check:
    check = Check("Remote session", True, "Not a remote desktop session")
    try:
        if probes.is_remote_session():
            check.passed = False
            check.message = (
                "Remote desktop session active  - Inspera cannot run within a remote session, use the PC directly"
            )
    except Exception:
        check.message = "Remote session check skipped"
    return check


def virtual_machine() -> Check:
    check = Check("Virtual machine", True, "Running on physical hardware")
    try:
        info = probes.computer_system()
        fingerprint = f"{info.get('Manufacturer') or ''} {info.get('Model') or ''}"
        check.details = {"manufacturer": info.get("Manufacturer"), "model": info.get("Model")}
        if VM_FINGERPRINT.search(fingerprint):
            check.passed = False
            check.message = f"This is a virtual machine ({fingerprint})  - Inspera only runs on a physical PC"
    except Exception:
        check.message = "Virtual machine check skipped"
    return check


def sse42() -> Check:
    check = Check("CPU SSE4.2", False, "")
    cpu = ""
    try:
        cpu = probes.cpu_name()
        check.details["name"] = cpu
    except Exception:
        pass
    try:
        has_sse42 = probes.sse42()
        check.details["source"] = "IsProcessorFeaturePresent"
    except Exception:
        has_sse42 = bool(CPU_HEURISTIC.search(cpu))
        check.details["source"] = "cpu-name-heuristic"
        if not has_sse42:
            check.informational = True
            check.message = f"Could not verify SSE4.2 for '{cpu}'  - Inspera will check this itself"
            return check
    check.passed = has_sse42
    check.message = (
        "CPU supports SSE4.2"
        if has_sse42
        else "CPU does NOT support SSE4.2  - Inspera cannot run on this PC, use a different computer"
    )
    return check


def virtualization_features() -> Check:
    check = Check("Virtualization features", True, "Hyper-V and Virtual Machine Platform are off")
    try:
        names = probes.enabled_virtualization_features()
        labels = list(
            dict.fromkeys("Virtual Machine Platform" if n == "VirtualMachinePlatform" else "Hyper-V" for n in names)
        )
        check.details = {"enabled": labels}
        if labels:
            check.warnings.append(
                f"{' and '.join(labels)} enabled  - if Inspera shows an Environment error, "
                "turn these off in Windows Features and restart"
            )
            check.message = "; ".join(check.warnings)
    except Exception:
        check.message = "Virtualization feature check skipped"
    return check
