"""Checks that leave the PC: HTTP reachability, latency samples, and the NTP clock comparison."""

from datetime import UTC, datetime, timedelta

from inspera_exam_helper.core.checks import probes
from inspera_exam_helper.core.result import Check

NTP_EPOCH = datetime(1900, 1, 1, tzinfo=UTC)
MAX_SKEW_SECONDS = 30
MAX_LATENCY_MS = 2000


def network(url: str, timeout: float = 10) -> Check:
    check = Check("Network connectivity", False, "")
    try:
        status, ms = probes.http_head(url, timeout)
        check.details = {"status": status, "latency_ms": ms, "url": url}
        if 200 <= status < 400:
            check.passed = True
            check.message = f"Reachable ({ms} ms)  - {url}"
        else:
            check.message = f"Unexpected status {status} from {url}"
    except Exception as exc:
        check.message = f"Cannot reach {url}  - {exc}"
    return check


def connection_quality(url: str, samples: int = 3, max_latency_ms: int = MAX_LATENCY_MS) -> Check:
    check = Check("Connection quality", False, "")
    latencies: list[int] = []
    for _ in range(samples):
        try:
            status, ms = probes.http_head(url, 10)
            if 200 <= status < 400:
                latencies.append(ms)
        except Exception:
            pass
    if not latencies:
        check.message = f"Could not reach {url} ({samples - len(latencies)}/{samples} attempts failed)"
        return check
    avg, worst = int(sum(latencies) / len(latencies)), max(latencies)
    check.details = {"average_ms": avg, "max_ms": worst, "samples": len(latencies), "url": url}
    check.passed = avg <= max_latency_ms
    check.message = (
        f"Avg latency {avg}ms, max {worst}ms ({len(latencies)}/{samples} OK)"
        if check.passed
        else f"High latency (avg {avg}ms)  - try ethernet or a different network"
    )
    return check


def decode_ntp(response: bytes) -> datetime:
    """The transmit timestamp (bytes 40-47) of an SNTP reply, big-endian seconds.fraction since 1900."""
    if len(response) < 48:
        raise ValueError("NTP response shorter than 48 bytes")
    seconds = int.from_bytes(response[40:44], "big") + int.from_bytes(response[44:48], "big") / 2**32
    return NTP_EPOCH + timedelta(seconds=seconds)


def clock_skew(max_skew_seconds: int = MAX_SKEW_SECONDS, server: str = "time.google.com") -> Check:
    check = Check("Clock accuracy", False, "")
    try:
        response = probes.ntp_response(server, 3)
        local = datetime.now(UTC)
        ntp = decode_ntp(response)
        skew = round(abs((local - ntp).total_seconds()), 2)
        check.details = {"local_utc": local.isoformat(), "ntp_utc": ntp.isoformat(), "skew_seconds": skew}
        check.passed = skew <= max_skew_seconds
        check.message = (
            f"Clock skew {skew}s (within {max_skew_seconds}s limit)"
            if check.passed
            else f"Clock skew {skew}s exceeds {max_skew_seconds}s  - "
            "Settings > Time & language > Date & time > Sync now"
        )
    except (TimeoutError, ConnectionResetError):  # Windows reports ICMP port-unreachable as WinError 10054
        check.message = f"NTP request to {server} timed out (firewall may block UDP port 123)"
    except Exception as exc:
        check.message = f"Could not verify clock: {exc}"
    return check
