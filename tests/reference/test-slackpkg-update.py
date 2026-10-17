#!/usr/bin/env python3
"""Check supplied slackpkg sequencing and real relocated private pending-file scans."""

from pathlib import Path
import itertools
import os
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
SCANS = ("empty", "mixed", "no-new", "links", "root-link", "find-failure", "sort-failure", "blank", "unset", "directory", "missing-parent", "count-failure")
STATUS_PROFILES = ((0, 0, 0), (1, 0, 0), (0, 20, 0), (0, 0, 20), (42, 127, 255), (255, 1, 42))
PREFIX = r'''
source "$1"
WORK=$2
PRIVATE_ETC=$3
COMMAND_TRACE=$WORK/commands
FIND_TRACE=$WORK/find-trace
SORT_TRACE=$WORK/sort-trace
COUNT_TRACE=$WORK/count-trace
trace() { local destination=$1; shift; printf '%s\0' "$@" >> "$destination"; printf '\n' >> "$destination"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
slackpkg() {
    local action=${*: -1}
    trace "$COMMAND_TRACE" slackpkg "$@"
    if [[ $PAYLOAD == 1 ]]; then printf 'supplied %s stdout\n' "$action"; printf 'supplied %s stderr\n' "$action" >&2; fi
    case "$action" in update) return "$UPDATE_RAW" ;; install-new) return "$INSTALL_RAW" ;; upgrade-all) return "$UPGRADE_RAW" ;; *) forbidden slackpkg-action ;; esac
}
find() {
    [[ $# == 8 && $1 == -H && $2 == /etc && $3 == -xdev && $4 == -type && $5 == f && $6 == -name && $7 == '*.new' && $8 == -print ]] || forbidden find-arguments
    trace "$FIND_TRACE" find "$@"
    builtin command find -H "$PRIVATE_ETC" -xdev -type f -name '*.new' -print || return
    if [[ $SCAN == find-failure ]]; then printf 'supplied find failure\n' >&2; return 23; fi
}
sort() {
    [[ $# == 0 ]] || forbidden sort-arguments
    trace "$SORT_TRACE" sort "${LC_ALL-}"
    builtin command sort "$@" || return
    if [[ $SCAN == sort-failure ]]; then printf 'supplied sort failure\n' >&2; return 31; fi
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-arguments
    trace "$COUNT_TRACE" wc "$@"
    if [[ $SCAN == count-failure ]]; then printf 'supplied count failure\n' >&2; return 37; fi
    builtin command wc "$@"
}
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "capture_validated_package_snapshot",
             "stage_geninitrd_grub_policy_override", "regenerate_initrd", "update_grub_configuration", "emit_event", "print_json_result",
             "flatpak", "sbopkg", "sqg", "git", "curl", "wget", "mkinitrd", "geninitrd", "grub-mkconfig", "rm", "mv", "mktemp")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = ("SLACKPKG_UPDATE_STATUS", "SLACKPKG_INSTALL_NEW_STATUS", "SLACKPKG_UPGRADE_ALL_STATUS", "PENDING_NEW_CONFIG_FILES_VALID",
          "PENDING_NEW_CONFIG_FILES_COUNT", "PENDING_NEW_CONFIG_FILES_ERROR", "SLACKWARE_INSTALL_NEW", "SLACKWARE_UPGRADE_ALL")
TRACE_NAMES = ("commands", "find-trace", "sort-trace", "count-trace")


def cases():
    for scan in SCANS:
        yield dict(kind="capture", scan=scan, flags=("true", "true"), statuses=(0, 0, 0), seed=91, payload=0)
    for flags, statuses, scan, seed, payload in itertools.product(itertools.product(("true", "false"), repeat=2), STATUS_PROFILES,
            ("empty", "mixed", "find-failure", "sort-failure", "blank", "directory"), (-1, 91), (0, 1)):
        yield dict(kind="update", scan=scan, flags=flags, statuses=statuses, seed=seed, payload=payload)


def encode(rows):
    return b"".join(b"".join(str(value).encode() + b"\0" for value in row) + b"\n" for row in rows)


def inventory(work):
    return {str(path.relative_to(work)): ("link", str(path.readlink())) if path.is_symlink() else
            ("directory",) if path.is_dir() else ("file", path.read_bytes()) for path in work.rglob("*") if path.name not in TRACE_NAMES}


def run_case(work, case):
    scan = case["scan"]
    target = work / "etc contents"
    target.mkdir()
    private_etc = work / "etc alias" if scan == "root-link" else target
    if scan == "root-link": private_etc.symlink_to(target, target_is_directory=True)
    relatives = ("a space.new", "nested/b.new", "rc.d/z.new") if scan in ("mixed", "root-link", "find-failure", "sort-failure", "count-failure") else ("regular.new",) if scan == "links" else ()
    for relative in relatives:
        path = target / relative; path.parent.mkdir(parents=True, exist_ok=True); path.write_text("private configuration\n")
    (target / "ignored.new.old").write_text("ignored\n")
    (target / "directory.new").mkdir()
    if scan == "links":
        external = work / "external private tree"; external.mkdir(); (external / "outside.new").write_text("outside\n")
        (target / "linked.new").symlink_to(external / "outside.new")
        (target / "linked directory").symlink_to(external, target_is_directory=True)
        (target / "broken.new").symlink_to(work / "absent")
    pending = work / "pending list"
    pending.write_bytes(b"old pending list\n")
    destination = "" if scan in ("blank", "unset") else str(work / "directory destination") if scan == "directory" else str(work / "missing parent" / "list") if scan == "missing-parent" else str(pending)
    if scan == "directory": Path(destination).mkdir()
    for name in TRACE_NAMES: (work / name).write_bytes(b"")
    before = inventory(work)
    values = dict(SLACKPKG_UPDATE_STATUS=case["seed"], SLACKPKG_INSTALL_NEW_STATUS=case["seed"], SLACKPKG_UPGRADE_ALL_STATUS=case["seed"],
                  PENDING_NEW_CONFIG_FILES_VALID=7, PENDING_NEW_CONFIG_FILES_COUNT=99, PENDING_NEW_CONFIG_FILES_ERROR="stale-error",
                  PENDING_NEW_CONFIG_FILES=destination, SLACKWARE_INSTALL_NEW=case["flags"][0], SLACKWARE_UPGRADE_ALL=case["flags"][1],
                  UPDATE_RAW=case["statuses"][0], INSTALL_RAW=case["statuses"][1], UPGRADE_RAW=case["statuses"][2], SCAN=scan, PAYLOAD=case["payload"])
    reset = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in values.items())
    if scan == "unset": reset += "\nunset PENDING_NEW_CONFIG_FILES"
    function = "capture_pending_new_config_files" if case["kind"] == "capture" else "update_slackware_system"
    output = 'printf \'RESULT\\0%s\\0\' "$raw"; printf \'%s\\0\' ' + " ".join(f'"${{{name}}}"' for name in FIELDS) + ' "$IFS"\n'
    driver = PREFIX + GUARDS + "\nIFS='|: '\nfor repetition in 1 2; do\n" + reset + "\n" + function + '\nraw=$?\n' + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "slackpkg-update-test", str(REFERENCE), str(work), str(private_etc)],
                            capture_output=True, timeout=10, env=dict(os.environ, LC_ALL="C"))
    state = {name: str(values[name]) for name in FIELDS}
    error = "pending .new configuration-file path is not initialized" if scan in ("blank", "unset") else "cannot initialize pending .new configuration-file list" if scan in ("directory", "missing-parent") else "cannot enumerate pending .new configuration files under /etc" if scan in ("find-failure", "sort-failure") else ""
    count = "" if scan == "count-failure" else "0" if error else str(len(relatives))
    state.update(PENDING_NEW_CONFIG_FILES_VALID="0" if error else "1", PENDING_NEW_CONFIG_FILES_COUNT=count, PENDING_NEW_CONFIG_FILES_ERROR=error)
    stdout, stderr = b"", b""
    rows = {name: [] for name in TRACE_NAMES}
    initialized = scan not in ("blank", "unset", "directory", "missing-parent")
    if initialized:
        rows["find-trace"].append(("find", "-H", "/etc", "-xdev", "-type", "f", "-name", "*.new", "-print"))
        rows["sort-trace"].append(("sort", "C"))
        expected_file = "".join(str(private_etc / relative) + "\n" for relative in relatives).encode()
        before["pending list"] = ("file", expected_file)
        if not error: rows["count-trace"].append(("wc", "-l"))
    if scan in ("find-failure", "sort-failure", "count-failure"):
        stderr = ("supplied " + {"find-failure": "find", "sort-failure": "sort", "count-failure": "count"}[scan] + " failure\n").encode()
    if case["kind"] == "update":
        stdout = b"[1] Slackware update\n"
        scan_stderr, stderr = stderr, b""
        for index, action in enumerate(("update", "install-new", "upgrade-all")):
            if index and case["flags"][index - 1] != "true":
                stdout += ("  " + action + " disabled by configuration\n").encode()
                continue
            args = ("-batch=on", "-default_answer=y") + (() if index == 0 else ("-postinst=off",)) + (action,)
            rows["commands"].append(("slackpkg", *args))
            state[("SLACKPKG_UPDATE_STATUS", "SLACKPKG_INSTALL_NEW_STATUS", "SLACKPKG_UPGRADE_ALL_STATUS")[index]] = str(case["statuses"][index])
            if case["payload"]:
                stdout += ("supplied " + action + " stdout\n").encode(); stderr += ("supplied " + action + " stderr\n").encode()
        stderr += scan_stderr
        if error: stdout += ("  [WARN] Pending .new configuration files could not be enumerated: " + error + "\n").encode()
        elif count != "0": stdout += ("  [WARN] " + count + " pending .new configuration file(s) require manual review\n").encode()
    raw = int(bool(error)) if case["kind"] == "capture" else 0
    packet = stdout + b"RESULT\0" + str(raw).encode() + b"\0" + b"".join(str(value).encode() + b"\0" for value in (*[state[name] for name in FIELDS], "|: "))
    assert result.returncode == 0, (case, "driver", result.returncode, result.stderr)
    assert result.stdout == packet * 2, (case, "stdout", result.stdout, packet * 2)
    if scan in ("directory", "missing-parent"):
        diagnostic = "Is a directory" if scan == "directory" else "No such file or directory"
        expected_error = re.escape(str(REFERENCE)) + r": line [0-9]+: " + re.escape(destination) + ": " + diagnostic + r"\n"
        assert re.fullmatch((re.escape(stderr.decode()) + expected_error) * 2, result.stderr.decode()), (case, "stderr", result.stderr)
    else:
        assert result.stderr == stderr * 2, (case, "stderr", result.stderr, stderr * 2)
    for name in TRACE_NAMES: assert (work / name).read_bytes() == encode(rows[name]) * 2, (case, name, (work / name).read_bytes(), encode(rows[name]) * 2)
    assert inventory(work) == before, (case, "private files/inventory")


def main():
    counts = dict(capture=0, update=0)
    with tempfile.TemporaryDirectory(prefix="slack-update package wrapper ") as temporary:
        for number, case in enumerate(cases()):
            work = Path(temporary) / str(number); work.mkdir(); run_case(work, case); counts[case["kind"]] += 1
    total = sum(counts.values())
    print(f"Slackpkg update wrapper: {counts['capture']} capture scenarios, {counts['update']} update scenarios, {total * 2} entries, 0 failures")


if __name__ == "__main__":
    main()
