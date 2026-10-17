#!/usr/bin/env python3
"""Exercise dry-run orchestration with supplied inspections and private files."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
CHECKS = ((0, 0), (0, 100), (1, 69), (23, 42), (255, 127))
SBO_CASES = ("disabled", "unavailable", "success", "queues-fail", "candidates-fail")
ELF_CASES = ("disabled", "unavailable", "clean", "broken", "scan-fail")
FILES = ("queue core", "queue extra", "option records", "abi candidates", "broken objects")
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
check_slackware_updates() {
    [[ $# == 0 ]] || forbidden check-arguments
    trace check
    CHECK_STATUS=$RAW_CHECK
    CHECK_ERROR='supplied check reason'
    return "$CHECK_RETURN"
}
inspect_dry_run_environment() { trace inspect "$@"; return "$AUX_RETURN"; }
probe_optional_modules() {
    trace probe "$@"
    SBO_MODULE_RUN=1
    SBO_MODULE_STATE=available
    ELF_MODULE_RUN=1
    ELF_MODULE_STATE=available
    case "$SBO_CASE" in disabled|unavailable) SBO_MODULE_RUN=0; SBO_MODULE_STATE=$SBO_CASE ;; esac
    case "$ELF_CASE" in disabled|unavailable) ELF_MODULE_RUN=0; ELF_MODULE_STATE=$ELF_CASE ;; esac
    SBO_MODULE_REASON='supplied SBo reason'
    ELF_MODULE_REASON='supplied ELF reason'
    return "$AUX_RETURN"
}
print_optional_module_activation() { trace activation "$@"; return "$AUX_RETURN"; }
inspect_current_sbo_queues() {
    [[ $# == 0 ]] || forbidden queue-arguments
    trace queues
    [[ $SBO_TARGET_SELECTION_STATUS == 0 ]] || forbidden selection-not-reset
    printf 'queue target\n' > "$QUEUE_CORE"
    [[ -z $SBO_OPTION_RECORDS ]] || printf 'target\tOPTION=yes\n' > "$SBO_OPTION_RECORDS"
    TOTAL_CORE=3
    SBO_OPTION_RECORD_COUNT=2
    SBO_TARGET_SELECTION_ERROR='supplied queue failure'
    [[ $SBO_CASE != queues-fail ]]
}
collect_installed_sbo_candidates() {
    [[ $# == 0 ]] || forbidden candidate-arguments
    trace candidates
    printf 'candidate\n' > "$ABI_CANDIDATES"
    PLAN_ABI_SBO_COUNT=4
    SBO_TARGET_SELECTION_ERROR='supplied candidate failure'
    [[ $SBO_CASE != candidates-fail ]]
}
inspect_current_elf_state() {
    [[ $# == 0 ]] || forbidden elf-arguments
    trace elf
    printf 'supplied ELF scan\n' > "$BROKEN"
    printf 'supplied ELF target\n' > "$QUEUE_EXTRA"
    PLAN_BROKEN_COUNT=0
    [[ $ELF_CASE != broken ]] || PLAN_BROKEN_COUNT=2
    PLAN_BROKEN_SBO_COUNT=6
    [[ $ELF_CASE != scan-fail ]]
}
print_dry_run_plan() { trace plan "$@"; return "$AUX_RETURN"; }
emit_module_started_event() { trace module-started "$@"; return "$AUX_RETURN"; }
emit_action_started_event() { trace action-started "$@"; return "$AUX_RETURN"; }
emit_action_completed_event() { trace action-completed "$@"; return "$AUX_RETURN"; }
emit_module_completed_event() { trace module-completed "$@"; return "$AUX_RETURN"; }
'''
FORBIDDEN = (
    "main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state",
    "initialize_dry_run_runtime", "load_configuration", "run_check_workflow", "run_apply_workflow",
    "resolve_sbo_personal_queue_directory", "collect_installed_sbo_targets",
    "detect_broken_elf_objects", "slackpkg", "sbopkg", "sqg", "flatpak", "readelf", "ldconfig",
    "mkinitrd", "grub-mkconfig", "git", "curl", "wget", "date", "print_json_result", "emit_final_events",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def expected(check, sbo, elf, options):
    result, raw = check
    state = "failed" if result else "success"
    rows = [
        ("module-started", "slackware", "Slackware planning probe started"),
        ("action-started", "slackware", "check_updates", "Checking Slackware repository updates"),
        ("check",),
        ("action-completed", "slackware", "check_updates", state, "Slackware repository probe completed", raw),
        ("module-completed", "slackware", state, "Slackware planning probe completed", raw),
        ("module-started", "core", "Local environment inspection started"),
        ("action-started", "core", "inspect_environment", "Inspecting optional tools and boot configuration"),
        ("inspect",), ("probe",), ("activation",),
        ("action-completed", "core", "inspect_environment", "success",
         "Optional tools, module modes, and boot configuration inspected", 0),
        ("module-completed", "core", "success", "Local environment inspection completed", 0),
        ("module-started", "sbo", "SBo planning inspection started"),
    ]
    files = {name: b"stale private data\n" for name in FILES}
    selection, total, records, abi, broken, broken_sbo = 91, 92, 93, 94, 95, 96
    directory = "stale queue directory"
    if sbo in ("disabled", "unavailable"):
        sbo_state = sbo
        total = records = abi = broken_sbo = 0
        directory = "private fallback"
        for name in ("queue core", "queue extra", "abi candidates"):
            files[name] = b""
        if options:
            files["option records"] = b""
        rows += [("action-completed", "sbo", "inspect_queues", sbo_state,
                  "SBo queue inspection was not applicable: supplied SBo reason", 0)]
    else:
        rows += [("action-started", "sbo", "inspect_queues", "Inspecting current SBo queues"), ("queues",)]
        selection = 0
        if sbo != "queues-fail":
            rows += [("candidates",)]
        if sbo == "success":
            sbo_state = "success"
            total, records, abi = 3, 2, 4
            files["queue core"] = b"queue target\n"
            files["abi candidates"] = b"candidate\n"
            if options:
                files["option records"] = b"target\tOPTION=yes\n"
            rows += [("action-completed", "sbo", "inspect_queues", "success",
                      "Current SBo queues and ABI candidates inspected", 0)]
        else:
            sbo_state, result, selection = "failed", 1, 1
            total = records = abi = 0
            files["queue core"] = files["abi candidates"] = b""
            if options:
                files["option records"] = b""
            reason = "queue" if sbo == "queues-fail" else "candidate"
            rows += [("action-completed", "sbo", "inspect_queues", "failed",
                      f"SBo target selection failed: supplied {reason} failure", 1)]
    rows += [("module-completed", "sbo", sbo_state, "SBo planning inspection completed", 0),
             ("module-started", "elf", "ELF dependency inspection started")]
    if elf in ("disabled", "unavailable"):
        elf_state = elf
        broken = 0
        files["broken objects"] = b""
        rows += [("action-completed", "elf", "scan_dependencies", elf_state,
                  "ELF dependency inspection was not applicable: supplied ELF reason", 0)]
    else:
        rows += [("action-started", "elf", "scan_dependencies", "Scanning current ELF dependencies"), ("elf",)]
        broken = 2 if elf == "broken" else 0
        broken_sbo = 6
        files["broken objects"] = b"supplied ELF scan\n"
        files["queue extra"] = b"supplied ELF target\n"
        if elf == "scan-fail":
            elf_state, result = "failed", 1
            message, code = "Static ELF dependency inspection failed", 1
        else:
            elf_state = "warning" if elf == "broken" else "success"
            message, code = "Current ELF dependency inspection completed", 0
        rows += [("action-completed", "elf", "scan_dependencies", elf_state, message, code)]
    rows += [
        ("module-completed", "elf", elf_state, "ELF dependency inspection completed", 0),
        ("action-started", "core", "render_plan", "Rendering dry-run plan"), ("plan",),
        ("action-completed", "core", "render_plan", "success", "Dry-run plan rendered", 0),
    ]
    # State projection is separate from event state and callback return codes.
    values = (result, raw, "supplied check reason", selection, total, records, abi,
              broken, broken_sbo, directory, "|: ")
    return rows, values, files


def encoded_rows(rows):
    return b"".join(b"".join(str(value).encode() + b"\0" for value in row) + b"\n" for row in rows)


def run_case(work, check, sbo, elf, options):
    rows, values, files = expected(check, sbo, elf, options)
    settings = dict(CHECK_RETURN=check[0], RAW_CHECK=check[1], SBO_CASE=sbo, ELF_CASE=elf,
                    QUEUE_CORE="queue core", QUEUE_EXTRA="queue extra", ABI_CANDIDATES="abi candidates",
                    BROKEN="broken objects", SBO_OPTION_RECORDS="option records" if options else "",
                    SBO_QUEUE_DIR_FALLBACK="private fallback")
    assignments = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in settings.items())
    driver = PREFIX + GUARDS + "\n" + assignments + r'''
IFS='|: '
for repetition in 1 2; do
    for file in 'queue core' 'queue extra' 'option records' 'abi candidates' 'broken objects'; do
        printf 'stale private data\n' > "$file"
    done
    SBO_MODULE_RUN=99; ELF_MODULE_RUN=99
    SBO_MODULE_STATE=poison; ELF_MODULE_STATE=poison
    SBO_TARGET_SELECTION_STATUS=91; TOTAL_CORE=92; SBO_OPTION_RECORD_COUNT=93
    PLAN_ABI_SBO_COUNT=94; PLAN_BROKEN_COUNT=95; PLAN_BROKEN_SBO_COUNT=96
    CHECK_STATUS=222; CHECK_ERROR=stale; SBODIR='stale queue directory'
    AUX_RETURN=0
    [[ $repetition == 1 ]] || AUX_RETURN=19
    status=0
    run_dry_run_workflow || status=$?
    printf '%s\0' "$status" "$CHECK_STATUS" "$CHECK_ERROR" "$SBO_TARGET_SELECTION_STATUS" \
        "$TOTAL_CORE" "$SBO_OPTION_RECORD_COUNT" "$PLAN_ABI_SBO_COUNT" "$PLAN_BROKEN_COUNT" \
        "$PLAN_BROKEN_SBO_COUNT" "$SBODIR" "$IFS"
    # Preserve each call's bytes before the next repetition reseeds the inputs.
    for file in 'queue core' 'queue extra' 'option records' 'abi candidates' 'broken objects'; do
        printf '%s\0' "$(< "$file")"
    done
done
'''
    trace = work / "callback trace"
    process = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "dry-run-workflow-test",
                              str(REFERENCE), str(trace)], cwd=work, capture_output=True, timeout=10)
    label = (check, sbo, elf, options)
    assert process.returncode == 0 and process.stderr == b"", (label, process.returncode, process.stderr)
    packet = b"".join(str(value).encode() + b"\0" for value in values)
    packet += b"".join(files[name].rstrip(b"\n") + b"\0" for name in FILES)
    assert process.stdout == packet * 2, (label, process.stdout, packet * 2)
    assert trace.read_bytes() == encoded_rows(rows) * 2, (label, trace.read_bytes(), rows)
    assert {p.name: p.read_bytes() for p in work.iterdir() if p != trace} == files, label
    assert sorted(p.name for p in work.iterdir()) == sorted((*FILES, "callback trace")), label


def main():
    cases = list(itertools.product(CHECKS, SBO_CASES, ELF_CASES, (False, True)))
    with tempfile.TemporaryDirectory(prefix="slack-update-dry-run-workflow-") as directory:
        for index, case in enumerate(cases):
            work = Path(directory) / str(index)
            work.mkdir()
            run_case(work, *case)
    print(f"Dry-run workflow: {len(cases)} scenarios, {2 * len(cases)} workflow calls, 0 failures")


if __name__ == "__main__":
    main()
