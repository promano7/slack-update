#!/usr/bin/env python3
"""Check real main setup ordering using supplied failures and inert callbacks."""

from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
FORBIDDEN = (
    "emit_operation_started_event", "run_check_workflow", "run_apply_workflow",
    "run_dry_run_workflow", "date", "determine_stable_exit_code",
    "print_stable_exit_code_summary", "print_json_result", "emit_final_events",
    "print_usage", "id", "flock",
)
PREFIX = r'''
source "$1"
TRACE=$2
CHANNEL=$3
channel_mode=$4
FAIL_STAGE=$5
FAIL_STATUS=$6
shift 6
trace() { printf '%s\n' "$1" >> "$TRACE"; }
forbidden() {
    trace "forbidden:$1"
    printf 'ERROR: prohibited boundary: %s\n' "$1" >&2
    exit 97
}
stage() {
    trace "$1"
    if [[ $FAIL_STAGE == "$1" ]]; then
        printf 'Callback failure: %s (%s)\n' "$1" "$FAIL_STATUS" >&2
        return "$FAIL_STATUS"
    fi
    return 0
}
initialize_execution_environment() { stage environment; }
load_configuration() { stage configuration; }
require_root() { stage privilege; }
acquire_instance_lock() { stage lock; }
install_runtime_traps() { stage traps; }
initialize_runtime() { stage runtime; }
initialize_dry_run_runtime() { stage dry-runtime; }
rotate_logs() { stage rotation; }
configure_logging() { stage logging; }
print_start_banner() {
    trace banner-control
    exit 96
}
if [[ $channel_mode == open ]]; then exec 3>"$CHANNEL"; else exec 3>&-; fi
'''
DRIVER = PREFIX + "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN) + '\nmain "$@"\n'


def run_cases():
    count = 0
    failures = (
        ("privilege", 1), ("privilege", 8), ("lock", 1), ("lock", 6),
        ("initialization", 1), ("initialization", 23),
        ("logging", 1), ("logging", 23), ("none", 0),
    )
    with tempfile.TemporaryDirectory(prefix="slack-update-main-setup-") as directory:
        work = Path(directory)
        trace, channel = work / "trace", work / "channel"
        for operation in ([], ["--check"], ["--dry-run"], ["--apply"]):
            initializer = "dry-runtime" if operation == ["--dry-run"] else "runtime"
            ordered = ["environment", "configuration", "privilege", "lock", "traps",
                       initializer, "rotation", "logging", "banner-control"]
            for stage, raw_status in failures:
                selected = initializer if stage == "initialization" else stage
                if stage == "none":
                    expected_status = 96
                    expected_trace = ordered
                    expected_error = b""
                else:
                    expected_status = raw_status if stage in ("privilege", "lock") else 1
                    expected_trace = ordered[:ordered.index(selected) + 1]
                    expected_error = f"Callback failure: {selected} ({raw_status})\n".encode()
                for output in ([], ["--json"], ["--events"]):
                    for mode in ("closed", "open"):
                        trace.unlink(missing_ok=True)
                        channel.unlink(missing_ok=True)
                        arguments = [*operation, *output]
                        result = subprocess.run(
                            ["bash", "--noprofile", "--norc", "-c", DRIVER, "main-setup-test",
                             str(REFERENCE), str(trace), str(channel), mode, selected,
                             str(raw_status), *arguments],
                            cwd=work, capture_output=True, timeout=10)
                        label = (stage, raw_status, arguments, mode)
                        assert result.returncode == expected_status, (label, result.returncode, result.stderr)
                        assert result.stdout == b"", (label, result.stdout)
                        assert result.stderr == expected_error, (label, result.stderr, expected_error)
                        assert trace.is_file(), (label, "missing trace")
                        expected_bytes = ("\n".join(expected_trace) + "\n").encode()
                        assert trace.read_bytes() == expected_bytes, (label, trace.read_bytes(), expected_bytes)
                        if mode == "open":
                            assert channel.read_bytes() == b"", (label, channel.read_bytes())
                        else:
                            assert not channel.exists(), label
                        count += 1
    return count


def main():
    count = run_cases()
    print(f"Main setup boundaries: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
