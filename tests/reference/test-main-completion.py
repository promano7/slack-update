#!/usr/bin/env python3
"""Exercise main dispatch, completion and output selection with inert callbacks."""

from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
STAMP = "2026-02-03T04:05:06Z"
PREFIX = r'''
source "$1"
TRACE=$2
CHANNEL=$3
INHERITED=$4
inherited_mode=$5
WORKFLOW_STATUS=$6
CLOCK_STATUS=$7
SUPPLIED_STABLE=$8
shift 8
trace() { printf '%s\n' "$1" >> "$TRACE"; }
forbidden() {
    trace "forbidden:$1"
    printf 'ERROR: prohibited boundary: %s\n' "$1" >&2
    exit 97
}
initialize_execution_environment() { trace environment; }
load_configuration() { trace configuration; }
require_root() { trace privilege; }
acquire_instance_lock() { trace lock; }
install_runtime_traps() { trace traps; }
initialize_runtime() { trace runtime; }
initialize_dry_run_runtime() { trace dry-runtime; }
rotate_logs() { trace rotation; }
configure_logging() {
    trace logging
    if [[ $JSON_OUTPUT == 1 || $EVENTS_OUTPUT == 1 ]]; then
        exec 3>"$CHANNEL"
        exec 1>&2
    fi
}
print_start_banner() { trace banner; }
emit_operation_started_event() { trace operation-start; }
workflow() {
    [[ $# == 1 && $OPERATION == "$1" ]] || forbidden workflow-selection
    trace "workflow:$1"
    printf 'workflow:%s\n' "$1"
    return "$WORKFLOW_STATUS"
}
run_check_workflow() { workflow check; }
run_apply_workflow() { workflow apply; }
run_dry_run_workflow() { workflow dry-run; }
date() {
    [[ $# == 2 && $1 == -u && $2 == +%Y-%m-%dT%H:%M:%SZ ]] || forbidden date-arguments
    trace clock
    if [[ $CLOCK_STATUS == 0 ]]; then printf '2026-02-03T04:05:06Z\n'; fi
    return "$CLOCK_STATUS"
}
determine_stable_exit_code() {
    [[ $# == 1 ]] || forbidden mapper-arguments
    trace "mapper:$1:${FINISHED_AT-unset}"
    STABLE_EXIT_CODE=$SUPPLIED_STABLE
}
print_stable_exit_code_summary() {
    [[ $# == 1 ]] || forbidden summary-arguments
    trace "summary:$1"
    printf 'summary:%s\n' "$1"
}
print_json_result() {
    [[ $# == 1 ]] || forbidden json-arguments
    trace "json:$1"
    printf 'json-callback:%s\n' "$1"
}
emit_final_events() {
    [[ $# == 1 ]] || forbidden events-arguments
    trace "events:$1"
    printf 'events-callback:%s\n' "$1" >&3
}
if [[ $inherited_mode == open ]]; then exec 3>"$INHERITED"; else exec 3>&-; fi
FINISHED_AT=stale-value
STABLE_EXIT_CODE=stale-value
'''
FORBIDDEN = (
    "print_usage", "id", "flock", "initialize_runtime_state", "cleanup",
    "release_instance_lock", "update_slackware_system", "run_boot_preparation_module",
)
SUFFIX = r'''
main "$@"
result=$?
if { : >&3; } 2>/dev/null; then trace descriptor:open; else trace descriptor:closed; fi
exit "$result"
'''
DRIVER = PREFIX + "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN) + SUFFIX


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-main-completion-") as directory:
        work = Path(directory)
        trace, channel, inherited = (work / name for name in ("trace", "channel", "inherited"))
        for arguments, operation in (([], "apply"), (["--check"], "check"),
                                     (["--dry-run"], "dry-run"), (["--apply"], "apply")):
            initializer = "dry-runtime" if operation == "dry-run" else "runtime"
            for output, kind in (([], "human"), (["--json"], "json"), (["--events"], "events")):
                for workflow_status in (0, 1, 23):
                    for clock_status in (0, 41):
                        for stable in (0, 2, 5, 8):
                            for mode in ("closed", "open"):
                                for path in (trace, channel, inherited):
                                    path.unlink(missing_ok=True)
                                result = subprocess.run(
                                    ["bash", "--noprofile", "--norc", "-c", DRIVER, "main-completion-test",
                                     str(REFERENCE), str(trace), str(channel), str(inherited), mode,
                                     str(workflow_status), str(clock_status), str(stable), *arguments, *output],
                                    cwd=work, capture_output=True, timeout=10)
                                label = (arguments, output, workflow_status, clock_status, stable, mode)
                                assert result.returncode == stable, (label, result.returncode, result.stderr)
                                effective_raw = workflow_status if clock_status == 0 else 1
                                finished = STAMP if clock_status == 0 else ""
                                expected_trace = ["environment", "configuration", "privilege", "lock", "traps",
                                                  initializer, "rotation", "logging", "banner", "operation-start",
                                                  f"workflow:{operation}", "clock", f"mapper:{effective_raw}:{finished}",
                                                  f"summary:{stable}"]
                                if kind != "human":
                                    expected_trace.append(f"{kind}:{stable}")
                                descriptor = mode if kind == "human" else "closed"
                                expected_trace.append(f"descriptor:{descriptor}")
                                expected_bytes = ("\n".join(expected_trace) + "\n").encode()
                                assert trace.read_bytes() == expected_bytes, (label, trace.read_bytes(), expected_bytes)
                                progress = f"workflow:{operation}\n".encode()
                                error = b"Error: cannot record the runtime completion time\n" if clock_status else b""
                                summary = f"summary:{stable}\n".encode()
                                if kind == "human":
                                    assert result.stdout == progress + summary, (label, result.stdout)
                                    assert result.stderr == error, (label, result.stderr)
                                    assert not channel.exists(), label
                                else:
                                    assert result.stdout == b"", (label, result.stdout)
                                    assert result.stderr == progress + error + summary, (label, result.stderr)
                                    assert channel.read_bytes() == f"{kind}-callback:{stable}\n".encode(), label
                                if mode == "open":
                                    assert inherited.read_bytes() == b"", (label, inherited.read_bytes())
                                else:
                                    assert not inherited.exists(), label
                                count += 1
    return count


def main():
    count = run_cases()
    print(f"Main completion boundaries: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
