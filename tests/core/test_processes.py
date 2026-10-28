import os
from types import SimpleNamespace

import psutil

from inspera_exam_helper.core import processes
from inspera_exam_helper.core.checks import probes
from inspera_exam_helper.core.config import Config
from inspera_exam_helper.core.logs.parser import parse_log


def fake_procs(monkeypatch, *names):
    procs = [SimpleNamespace(info={"pid": 100 + i, "name": n}) for i, n in enumerate(names)]
    monkeypatch.setattr(psutil, "process_iter", lambda attrs: procs)


def test_default_blocklist_entries():
    entries = processes.blocklist_entries()
    assert len(entries) > 10
    assert len([e for e in entries if e.name == "Discord.exe"]) == 1
    assert len([e for e in entries if e.name == "desktopextension.exe" and e.source == "default"]) == 1
    assert len([e for e in entries if e.name == "remoting_host.exe"]) == 1


def test_no_duplicate_blocklist_names():
    names = [p["name"].lower() for p in processes.default_blocklist()["processes"]]
    assert len(names) == len(set(names))


def test_log_apps_augment_blocklist(fixture_path):
    log = parse_log(fixture_path("failed-to-close-apps.log"), Config())
    entries = processes.blocklist_entries(log.applications)
    assert [e for e in entries if e.source == "log"]
    assert len([e for e in entries if e.name == "Overwolf.exe" and e.source == "log"]) == 1
    assert len([e for e in entries if e.name.lower() == "desktopextension.exe"]) == 1
    assert "Overwolf.exe" in [e.name for e in processes.blocklist_entries(["Overwolf"])]


def test_running_matches_by_name_and_pattern(monkeypatch):
    fake_procs(monkeypatch, "discord.exe", "obs-studio-helper.exe", "notepad.exe", None)
    matches = processes.running_matches()
    assert [(m.name, m.source) for m in matches] == [("discord", "default"), ("obs-studio-helper", "pattern")]


def test_dry_run_cleanup_never_kills(monkeypatch):
    fake_procs(monkeypatch, "Discord.exe", "inspera-launcher.exe", "TeamViewer.exe")
    monkeypatch.setattr(psutil.Process, "kill", lambda self: (_ for _ in ()).throw(AssertionError("killed")))
    results = processes.cleanup([], apply=False)
    assert [r.name for r in results] == ["Discord", "TeamViewer"]
    assert all(r.action == "would-kill" and r.success for r in results)


def test_cleanup_skips_own_pid(monkeypatch):
    fake_procs(monkeypatch, "Discord.exe")
    monkeypatch.setattr(os, "getpid", lambda: 100)
    assert processes.cleanup([], apply=False) == []


def test_stop_process_paths(monkeypatch):
    class Dead:
        def __init__(self, pid):
            raise psutil.NoSuchProcess(pid)

    monkeypatch.setattr(psutil, "Process", Dead)
    monkeypatch.setattr(processes.subprocess, "run", lambda *a, **k: SimpleNamespace(returncode=0))
    assert processes.stop_process(1, "x", apply=True).action == "taskkill"
    monkeypatch.setattr(processes.subprocess, "run", lambda *a, **k: SimpleNamespace(returncode=1))
    result = processes.stop_process(1, "x", apply=True)
    assert (result.action, result.success) == ("failed", False)

    def missing(*a, **k):
        raise FileNotFoundError("taskkill")

    monkeypatch.setattr(processes.subprocess, "run", missing)
    assert processes.stop_process(1, "x", apply=True).message == "taskkill"

    class Alive:
        def __init__(self, pid):
            pass

        def kill(self):
            pass

    monkeypatch.setattr(psutil, "Process", Alive)
    assert processes.stop_process(1, "x", apply=True).action == "stopped"


def test_wsl_shutdown(monkeypatch):
    monkeypatch.setattr(probes, "wsl_available", lambda: False)
    assert processes.wsl_shutdown(apply=True) == (False, "WSL not installed")
    monkeypatch.setattr(probes, "wsl_available", lambda: True)
    assert processes.wsl_shutdown(apply=False)[0] is False
    assert "test mode" in processes.wsl_shutdown(apply=True)[1]
    monkeypatch.delenv("INSPERA_SKIP_WSL_SHUTDOWN")
    ran = []
    monkeypatch.setattr(probes, "wsl_shutdown", lambda: ran.append(1))
    assert processes.wsl_shutdown(apply=True) == (True, "WSL shutdown completed")
    assert ran

    def boom():
        raise OSError("no wsl")

    monkeypatch.setattr(probes, "wsl_shutdown", boom)
    assert processes.wsl_shutdown(apply=True) == (False, "WSL shutdown failed: no wsl")
