#!/usr/bin/env python3
"""Require every selected package-name writer failure to invalidate the stream."""

import itertools
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
NAMES = ("alpha", "middle", "zeta")
GUARDS = (
    "main", "initialize_execution_environment", "load_configuration",
    "initialize_runtime", "initialize_dry_run_runtime", "configure_logging",
    "run_apply_workflow", "run_check_workflow", "run_dry_run_workflow",
    "collect_installed_sbo_targets", "enumerate_package_database_records",
    "map_broken_objects_to_sbo_packages", "detect_broken_elf_objects",
    "verify_broken_elf_objects_after_rebuild", "find", "readelf", "ldd",
    "ldconfig", "slackpkg", "sbopkg", "sqg", "flatpak", "git", "curl", "wget",
    "regenerate_initrd", "update_grub_configuration",
)
SETUP = r'''
source "$1"
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
printf() {
    if [[ ${FUNCNAME[1]} == package_names_with_build_suffix_from_stream ]]; then
        [[ $# == 2 && $1 == '%s\n' ]] || forbidden printf-vector
        case "$2" in alpha|middle|zeta) ;; *) forbidden printf-value ;; esac
        builtin printf 'selected:%s\n' "$2" >&2
        if [[ $2 == "$FAILING_NAME" && $WRITER != normal ]]; then
            builtin printf 'failed:%s:%s\n' "$2" "$WRITER" >&2
            if [[ $WRITER == bytes-then-fail ]]; then builtin printf "$@"; fi
            return 43
        fi
    fi
    builtin printf "$@"
}
'''


def run_case(position, writer, trailer, terminated, conditional):
    records = [name + "-1.0-x86_64-1_SBo" for name in NAMES]
    records.extend({"none": [], "native": ["native-1.0-x86_64-1"], "malformed": ["malformed"]}[trailer])
    data = "\n".join(records) + ("\n" if terminated else "")
    selected = NAMES[position]
    shell = SETUP + "\n" + "\n".join(name + "() { forbidden " + name + "; }" for name in GUARDS)
    shell += "\nFAILING_NAME=" + shlex.quote(selected) + "\nWRITER=" + shlex.quote(writer) + "\n"
    shell += "IFS='|: '\nsaved_ifs=$IFS\nrecord=outer-record\nsuffix=outer-suffix\nemission_failed=123\n"
    if conditional:
        shell += "if package_names_with_build_suffix_from_stream _SBo; then result=0; else result=$?; fi\n"
    else:
        shell += "package_names_with_build_suffix_from_stream _SBo\nresult=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $record == outer-record && $suffix == outer-suffix && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0RESULT\\0%s\\0" "$result"\n'
    completed = subprocess.run(
        ["bash", "--noprofile", "--norc", "-c", shell, "package-name-status", str(REFERENCE)],
        input=data.encode(), capture_output=True, cwd=ROOT,
        env=dict(os.environ, LC_ALL="C"), timeout=10,
    )
    # Any supplied writer failure invalidates the stream, irrespective of later input.
    status = 0 if writer == "normal" else 1
    stdout = "".join(name + "\n" for name in NAMES if writer != "quiet-fail" or name != selected)
    stderr = "".join("selected:" + name + "\n" + (
        "failed:" + name + ":" + writer + "\n" if name == selected and writer != "normal" else "") for name in NAMES)
    expected = stdout.encode() + b"\0RESULT\0" + str(status).encode() + b"\0"
    cell = dict(position=position, writer=writer, trailer=trailer, final_newline=terminated, conditional=conditional)
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, expected, stderr.encode()), dict(
        cell=cell, shell_status=completed.returncode, stdout=completed.stdout, stderr=completed.stderr,
        expected_stdout=expected, expected_stderr=stderr.encode())
    return cell | dict(raw_status=status, stdout=completed.stdout.decode(), stderr=completed.stderr.decode(),
                       active_fault=writer != "normal", selected_emissions=3)


def main():
    cells = itertools.product(range(3), ("normal", "quiet-fail", "bytes-then-fail"),
                              ("none", "native", "malformed"), (False, True), (False, True))
    rows = [run_case(*cell) for cell in cells]
    assert len(rows) == 108 and sum(row["active_fault"] for row in rows) == 72
    assert sum(row["raw_status"] == 1 for row in rows) == 72
    assert sum(row["raw_status"] == 0 for row in rows) == 36
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, rows=rows,
            scope="Direct real stream/parser helper; supplied writer failures; no installed database/native conformance"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-package-name-emission-status.py [--report /absolute/report.json]"
    print("SBo package-name emission status: 108 scenarios PASS; 72 writer failures refused after all selected emissions; 36 normal controls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
