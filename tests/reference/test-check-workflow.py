#!/usr/bin/env python3
"""Check orchestration and command outcomes with supplied mirror/event callbacks."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
# name, command present, mirror return, mirror diagnostic, raw command status
CHECK_CASES = (
    ("missing-command", 0, 0, "unused mirror error", 0),
    ("mirror-message", 1, 1, "supplied mirror rejection", 0),
    ("mirror-empty", 1, 23, "", 0),
    ("mirror-unset", 1, 255, None, 0),
    *((f"raw-{status}", 1, 0, "stale mirror error", status)
      for status in (0, 100, 1, 2, 20, 42, 127, 255)),
)
START = [
    ("module-started", "slackware", "Slackware update check started"),
    ("action-started", "slackware", "check_updates", "Checking Slackware repository updates"),
]
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
command() {
    [[ $# == 2 && $1 == -v && $2 == slackpkg ]] || forbidden command-lookup
    trace lookup slackpkg
    (( COMMAND_PRESENT == 1 ))
}
probe_slackpkg_mirror_changelog() {
    [[ $# == 0 ]] || forbidden mirror-arguments
    trace mirror
    if [[ $MIRROR_UNSET == 1 ]]; then
        unset SLACKPKG_MIRROR_ERROR
    else
        SLACKPKG_MIRROR_ERROR=$MIRROR_ERROR
    fi
    return "$MIRROR_RETURN"
}
slackpkg() {
    [[ $# == 3 && $1 == -batch=on && $2 == -default_answer=n && $3 == check-updates ]] || forbidden slackpkg-arguments
    trace slackpkg "$@"
    printf 'supplied slackpkg output\n'
    return "$RAW_STATUS"
}
emit_module_started_event() { trace module-started "$@"; return "$EVENT_RETURN"; }
emit_action_started_event() { trace action-started "$@"; return "$EVENT_RETURN"; }
emit_action_completed_event() { trace action-completed "$@"; return "$EVENT_RETURN"; }
emit_module_completed_event() { trace module-completed "$@"; return "$EVENT_RETURN"; }
print_check_summary() {
    [[ $# == 0 ]] || forbidden summary-arguments
    trace summary "$CHECK_STATUS" "$CHECK_ERROR"
    return "$SUMMARY_RETURN"
}
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state",
             "load_configuration", "resolve_active_slackpkg_mirror", "wget", "curl", "date",
             "run_apply_workflow", "run_dry_run_workflow", "print_json_result", "emit_final_events")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def completed(result, raw, error):
    state = "success" if result == 0 else "failed"
    return [
        ("action-completed", "slackware", "check_updates", state,
         "Slackware repository update check completed", str(raw)),
        ("module-completed", "slackware", state, "Slackware update check completed", str(raw)),
        ("summary", str(raw), error),
    ]


def integrated_cases():
    for name, present, mirror_return, mirror_error, raw in CHECK_CASES:
        trace = START + [("lookup", "slackpkg")]
        output = "[CHECK] Slackware updates\n"
        if not present:
            result, status, error = 1, 127, "slackpkg is not available"
        else:
            trace += [("mirror",)]
            if mirror_return:
                result, status = 1, 69
                error = mirror_error or "Slackware repository mirror probe failed"
            else:
                trace += [("slackpkg", "-batch=on", "-default_answer=n", "check-updates")]
                output += "supplied slackpkg output\n"
                status = raw
                result = 0 if raw in (0, 100) else 1
                error = "" if result == 0 else f"slackpkg check-updates failed with exit code {raw}"
        if error:
            output += f"  [ERROR] {error}\n"
        values = dict(COMMAND_PRESENT=present, MIRROR_RETURN=mirror_return,
                      MIRROR_ERROR=mirror_error or "", MIRROR_UNSET=int(mirror_error is None), RAW_STATUS=raw)
        yield name, values, "", result, status, error, output, trace + completed(result, status, error)


def supplied_cases():
    # Supplied inconsistent pairs isolate orchestration; they do not assert reachability.
    for result, raw in itertools.product((0, 1, 23, 255), (0, 100, 42, 69, 127)):
        error = "supplied check diagnostic"
        callback = r'''
check_slackware_updates() {
    [[ $# == 0 ]] || forbidden check-arguments
    trace supplied-check
    CHECK_STATUS=$SUPPLIED_RAW
    CHECK_ERROR='supplied check diagnostic'
    return "$SUPPLIED_RETURN"
}
'''
        values = dict(SUPPLIED_RETURN=result, SUPPLIED_RAW=raw)
        trace = START + [("supplied-check",)] + completed(result, raw, error)
        yield f"supplied-{result}-{raw}", values, callback, result, raw, error, "", trace


def encoded_trace(rows):
    return b"".join(b"".join(str(value).encode() + b"\0" for value in row) + b"\n" for row in rows)


def run_case(work, case):
    name, values, callback, result, raw, error, output, rows = case
    trace = work / "callback trace"
    assignments = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in values.items())
    driver = PREFIX + GUARDS + "\n" + callback + "\n" + assignments + r'''
IFS='|: '
for repetition in 1 2; do
    CHECK_STATUS=222
    CHECK_ERROR='stale check error'
    SLACKPKG_MIRROR_ERROR='stale previous mirror error'
    EVENT_RETURN=0
    SUMMARY_RETURN=0
    if [[ $repetition == 2 ]]; then EVENT_RETURN=17; SUMMARY_RETURN=19; fi
    status=0
    run_check_workflow || status=$?
    printf '%s\0' "$status" "$CHECK_STATUS" "$CHECK_ERROR" "$IFS"
done
'''
    process = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "check-workflow-test",
                              str(REFERENCE), str(trace)], cwd=work, capture_output=True, timeout=10)
    assert process.returncode == 0 and process.stderr == b"", (name, process.returncode, process.stderr)
    packet = output.encode() + b"".join(str(value).encode() + b"\0" for value in (result, raw, error, "|: "))
    assert process.stdout == packet * 2, (name, process.stdout, packet * 2)
    assert trace.read_bytes() == encoded_trace(rows) * 2, (name, trace.read_bytes(), rows)
    assert sorted(p.name for p in work.iterdir()) == ["callback trace"], name


def main():
    cases = [*integrated_cases(), *supplied_cases()]
    with tempfile.TemporaryDirectory(prefix="slack-update-check-workflow-") as directory:
        for index, case in enumerate(cases):
            work = Path(directory) / str(index)
            work.mkdir()
            run_case(work, case)
    print(f"Check workflow: {len(cases)} scenarios, {2 * len(cases)} workflow calls, 0 failures")


if __name__ == "__main__":
    main()
