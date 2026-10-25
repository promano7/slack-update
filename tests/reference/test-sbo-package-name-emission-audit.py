#!/usr/bin/env python3
"""Characterize historical package-name emission status loss; not a safety test."""

import hashlib
import itertools
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
HISTORICAL_SHA256 = "52015a485e206993af40a543e0e938052c9e1efa7e5155c475954abf2378c323"
NAMES = ("alpha", "middle", "zeta")
PREFIX = r'''
source "$1"
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
printf() {
    if [[ ${FUNCNAME[1]} == package_names_with_build_suffix_from_stream ]]; then
        [[ $# == 2 && $1 == '%s\n' ]] || forbidden emission-vector
        [[ $2 == alpha || $2 == middle || $2 == zeta ]] || forbidden emission-name
        builtin printf 'EMIT %s\n' "$2" >&2
        if [[ $2 == "$SELECTED" && $FAULT != none ]]; then
            builtin printf 'FAULT %s %s\n' "$2" "$FAULT" >&2
            [[ $FAULT != quiet ]] || return 43
            builtin printf "$@"
            return 43
        fi
    fi
    builtin printf "$@"
}
'''
GUARDS = (
    "main", "load_configuration", "initialize_execution_environment",
    "initialize_runtime", "initialize_dry_run_runtime", "configure_logging",
    "run_apply_workflow", "run_check_workflow", "run_dry_run_workflow",
    "collect_installed_sbo_targets", "enumerate_package_database_records",
    "map_broken_objects_to_sbo_packages", "detect_broken_elf_objects",
    "verify_broken_elf_objects_after_rebuild", "slackpkg", "sbopkg", "sqg",
    "flatpak", "readelf", "ldd", "ldconfig", "git", "curl", "wget", "find",
    "regenerate_initrd", "update_grub_configuration",
)


def scenario(position, fault, trailer, newline, conditional):
    selected = NAMES[position]
    records = [name + "-1.0-x86_64-1_SBo" for name in NAMES]
    if trailer == "native":
        records.append("native-1.0-x86_64-1")
    elif trailer == "malformed":
        records.append("malformed")
    payload = "\n".join(records) + ("\n" if newline else "")
    shell = PREFIX + "\n".join(name + "() { forbidden " + name + "; }" for name in GUARDS)
    shell += "\nSELECTED=" + shlex.quote(selected) + "\nFAULT=" + shlex.quote(fault) + "\n"
    shell += "IFS='|: '\nsaved_ifs=$IFS\nrecord=outer-record\nsuffix=outer-suffix\n"
    if conditional:
        shell += 'if package_names_with_build_suffix_from_stream _SBo; then raw=0; else raw=$?; fi\n'
    else:
        shell += 'package_names_with_build_suffix_from_stream _SBo\nraw=$?\n'
    shell += '[[ $IFS == "$saved_ifs" && $record == outer-record && $suffix == outer-suffix ]] || exit 96\n'
    shell += 'builtin printf "\\0STATUS\\0%s\\0" "$raw"\n'
    result = subprocess.run(
        ["bash", "--noprofile", "--norc", "-c", shell, "package-name-emission-audit", str(REFERENCE)],
        input=payload.encode(), capture_output=True, cwd=ROOT,
        env=dict(os.environ, LC_ALL="C"), timeout=10,
    )
    # The historical loop returns the last completed iteration's status.
    expected_status = 43 if fault != "none" and position == 2 and trailer == "none" else 0
    expected_output = "".join(name + "\n" for name in NAMES if not (name == selected and fault == "quiet"))
    expected_trace = "".join(
        "EMIT " + name + "\n" + ("FAULT " + name + " " + fault + "\n" if name == selected and fault != "none" else "")
        for name in NAMES
    )
    expected = expected_output.encode() + b"\0STATUS\0" + str(expected_status).encode() + b"\0"
    label = (position, fault, trailer, newline, conditional)
    assert (result.returncode, result.stdout, result.stderr) == (0, expected, expected_trace.encode()), (
        label, result.returncode, result.stdout, result.stderr, expected, expected_trace,
    )
    return dict(position=position, selected=selected, fault=fault, trailer=trailer,
                final_newline=newline, conditional=conditional, raw_status=expected_status,
                stdout=result.stdout.decode(), stderr=result.stderr.decode(),
                fault_activated=fault != "none", masked_failure=fault != "none" and expected_status == 0)


def main():
    actual = hashlib.sha256(REFERENCE.read_bytes()).hexdigest()
    if actual != HISTORICAL_SHA256:
        print("REFUSE SBO PACKAGE-NAME EMISSION AUDIT: requires exact historical555 runtime " + HISTORICAL_SHA256, file=sys.stderr)
        return 1
    rows = [scenario(*cell) for cell in itertools.product(range(3), ("none", "quiet", "late"),
            ("none", "native", "malformed"), (False, True), (False, True))]
    assert len(rows) == 108
    assert sum(row["fault_activated"] for row in rows) == 72
    assert sum(row["masked_failure"] for row in rows) == 64
    assert sum(row["raw_status"] == 43 for row in rows) == 8
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(
            schema=1, historical_runtime_sha256=actual, safety_pass=False,
            scope="Direct package-name stream helper only; supplied printf failures; no installed database or native operation",
            rows=rows), indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-package-name-emission-audit.py [--report /path/report.json]"
    print("PASS SBO PACKAGE-NAME HISTORICAL CHARACTERIZATION: 108 exact observations; 72 active emission faults; 64 masked failures; 8 surfaced failures; 36 normal controls; NOT a safety pass")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
