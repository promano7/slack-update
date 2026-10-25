#!/usr/bin/env python3
"""Check authored package-record layouts, literal suffixes and repeated writer failures."""
import itertools
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
PROFILES = {
    "empty": ([], [], []),
    "single": (["alpha-1.0-x86_64-1_SBo"], ["alpha"], []),
    "mixed": (["native-1.0-x86_64-1", "alpha-1.0-x86_64-1_SBo", "",
               "dir/complex-lib-2.0-x86_64-4_SBo.txz", "malformed",
               "literal-tag-1.0-noarch-2.SBo+", "near-1.0-noarch-2XSBo+",
               "extra-1.0-noarch-1_SBo_extra"], ["alpha", "complex-lib"], ["literal-tag"]),
    "duplicates": (["dup-1.0-x86_64-1_SBo", "dup-2.0-i586-2_SBo",
                    "dup-3.0-noarch-4.SBo+"], ["dup", "dup"], ["dup"]),
    "archives": (["dir/lib+name-2.0-x86_64-1_SBo.txz", "/absolute/other.name-1.0-noarch-1_SBo.tgz",
                  "dir/short-2-i586-3.SBo+.tbz", "dir/four-1.0-noarch-7.SBo+.tlz"],
                 ["lib+name", "other.name"], ["short", "four"]),
    "filtered": (["native-1.0-x86_64-1", "extra-1.0-noarch-1_SBo_extra", "malformed",
                  "two-fields", "  ", "spaced name-1.0-x86_64-1_SBo", "cr-1.0-x86_64-1_SBo\r",
                  "near-1.0-noarch-2XSBo+"], [], []),
    "literal-names": (["@unsafe-1.0-x86_64-1_SBo", "literal[abc]-1.0-noarch-2_SBo",
                       "name+dot.-1-x-4.SBo+"], ["@unsafe", "literal[abc]"], ["name+dot."]),
    "skip-tail": (["alpha-1.0-x86_64-1_SBo", "beta-1.0-noarch-2_SBo", "",
                   "native-1.0-x86_64-1", "malformed"], ["alpha", "beta"], []),
}
GUARDS = (
    "main", "initialize_execution_environment", "load_configuration", "initialize_runtime",
    "initialize_dry_run_runtime", "configure_logging", "run_apply_workflow", "run_check_workflow",
    "run_dry_run_workflow", "collect_installed_sbo_targets", "enumerate_package_database_records",
    "normalize_sbo_target_names_from_stream", "map_broken_objects_to_sbo_packages",
    "detect_broken_elf_objects", "verify_broken_elf_objects_after_rebuild", "find", "readelf",
    "ldd", "ldconfig", "slackpkg", "sbopkg", "sqg", "flatpak", "git", "curl", "wget",
    "regenerate_initrd", "update_grub_configuration",
)
SETUP = r'''
source "$1"
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
printf() {
    if [[ ${FUNCNAME[1]} == package_names_with_build_suffix_from_stream ]]; then
        [[ $# == 2 && $1 == '%s\n' ]] || forbidden writer-vector
        case "$2" in
            alpha|beta|dup|complex-lib|literal-tag|lib+name|other.name|short|four|@unsafe|'literal[abc]'|name+dot.) ;;
            *) forbidden writer-value ;;
        esac
        WRITES=$((WRITES + 1))
        builtin printf 'write:%s:%s\n' "$WRITES" "$2" >&2
        if [[ $WRITER != normal && ( $WRITER == all-* || $WRITES == 1 ) ]]; then
            builtin printf 'fault:%s:%s:%s\n' "$WRITES" "$WRITER" "$WRITER_STATUS" >&2
            if [[ $WRITER == *-late ]]; then builtin printf "$@"; fi
            return "$WRITER_STATUS"
        fi
    fi
    builtin printf "$@"
}
'''


def scenario(profile, suffix, writer, terminated, conditional):
    records, standard, literal = PROFILES[profile]
    selected = {"_SBo": standard, ".SBo+": literal, "": []}[suffix]
    payload = "\n".join(records) + ("\n" if records and terminated else "")
    writer_status = {"normal": 0, "first-quiet": 43, "first-late": 127, "all-quiet": 1, "all-late": 43}[writer]
    shell = SETUP + "\n" + "\n".join(name + "() { forbidden " + name + "; }" for name in GUARDS)
    settings = dict(SUFFIX=suffix, WRITER=writer, WRITER_STATUS=writer_status, WRITES=0)
    shell += "\n" + "\n".join(name + "=" + shlex.quote(str(value)) for name, value in settings.items()) + "\n"
    shell += "IFS='|: '\nsaved_ifs=$IFS\nrecord=outer-record\nsuffix=outer-suffix\nemission_failed=123\n"
    if conditional:
        shell += 'if package_names_with_build_suffix_from_stream "$SUFFIX"; then result=0; else result=$?; fi\n'
    else:
        shell += 'package_names_with_build_suffix_from_stream "$SUFFIX"\nresult=$?\n'
    shell += '[[ $IFS == "$saved_ifs" && $record == outer-record && $suffix == outer-suffix && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0%s\\0" "$result" "$WRITES"\n'
    completed = subprocess.run(["bash", "--noprofile", "--norc", "-c", shell, "package-inputs", str(REFERENCE)],
        input=payload.encode(), capture_output=True, cwd=ROOT, env=dict(os.environ, LC_ALL="C"), timeout=10)
    output, trace, failed = "", "", []
    for index, name in enumerate(selected, 1):
        active = writer != "normal" and (writer.startswith("all-") or index == 1)
        trace += f"write:{index}:{name}\n"
        if active:
            failed.append(index)
            trace += f"fault:{index}:{writer}:{writer_status}\n"
        if not active or writer.endswith("-late"):
            output += name + "\n"
    status = 1 if failed else 0
    expected = output.encode() + b"\0STATE\0" + str(status).encode() + b"\0" + str(len(selected)).encode() + b"\0"
    label = dict(profile=profile, suffix=suffix, writer=writer, final_newline=terminated, conditional=conditional)
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, expected, trace.encode()), dict(
        cell=label, shell_status=completed.returncode, stdout=completed.stdout, stderr=completed.stderr,
        expected_stdout=expected, expected_stderr=trace.encode())
    return label | dict(raw_status=status, selected_names=selected, attempted_emissions=len(selected),
        failed_emissions=failed, writer_status=writer_status, active_fault=bool(failed),
        inactive_fault=writer != "normal" and not failed, stdout=completed.stdout.decode(), stderr=completed.stderr.decode())


def main():
    cells = itertools.product(PROFILES, ("_SBo", ".SBo+", ""),
        ("normal", "first-quiet", "first-late", "all-quiet", "all-late"), (False, True), (False, True))
    rows = [scenario(*cell) for cell in cells]
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["inactive_fault"] for r in rows), normal=sum(r["writer"] == "normal" for r in rows),
        failed_emissions=sum(len(r["failed_emissions"]) for r in rows),
        multiple_fault_cases=sum(len(r["failed_emissions"]) > 1 for r in rows))
    assert totals == dict(cases=480, active=160, inactive=224, normal=96, failed_emissions=208, multiple_fault_cases=48), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            scope="Direct stream/parser only; authored expected names; supplied writer failures; no installed database or target normalization"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-package-name-inputs.py [--report /absolute/report.json]"
    print("SBo package-name inputs: 480 scenarios PASS; 160 active fault refusals; 224 inactive fault controls; 96 normal controls; 48 multiple-fault cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
