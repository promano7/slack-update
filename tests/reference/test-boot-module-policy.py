#!/usr/bin/env python3
"""Check boot activation and in-memory policy with private paths and supplied capabilities."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
MK = ["lookup:mkinitrd", "file:config", "not-link:config"]
GRUB = ["lookup:grub-mkconfig", "lookup:grub-script-check", "directory:grub", "not-link:grub"]
# name, command availability, config kind, GRUB kind, expected capabilities, queries
CAPABILITIES = (
    ("none", (0, 0, 0), "file", "directory", (0, 0), ["lookup:mkinitrd", "lookup:grub-mkconfig"]),
    ("initrd-only", (1, 0, 1), "file", "directory", (1, 0), MK + ["lookup:grub-mkconfig"]),
    ("grub-only", (0, 1, 1), "missing", "directory", (0, 1), ["lookup:mkinitrd"] + GRUB),
    ("managed", (1, 1, 1), "file", "directory", (1, 1), MK + GRUB),
    ("config-missing", (1, 1, 1), "missing", "directory", (0, 1), ["lookup:mkinitrd", "file:config"] + GRUB),
    ("config-directory", (1, 1, 1), "directory", "directory", (0, 1), ["lookup:mkinitrd", "file:config"] + GRUB),
    ("config-link", (1, 1, 1), "link", "directory", (0, 1), MK + GRUB),
    ("config-broken", (1, 1, 1), "broken", "directory", (0, 1), ["lookup:mkinitrd", "file:config"] + GRUB),
    ("no-validator", (1, 1, 0), "file", "directory", (1, 0), MK + ["lookup:grub-mkconfig", "lookup:grub-script-check"]),
    ("grub-missing", (1, 1, 1), "file", "missing", (1, 0), MK + GRUB[:-1]),
    ("grub-file", (1, 1, 1), "file", "file", (1, 0), MK + GRUB[:-1]),
    ("grub-link", (1, 1, 1), "file", "link", (1, 0), MK + GRUB),
    ("grub-broken", (1, 1, 1), "file", "broken", (1, 0), MK + GRUB[:-1]),
)
PROBE_FIELDS = ("BOOT_MODULE_STATE", "BOOT_MODULE_RUN", "BOOT_MODULE_REASON",
                "BOOT_INITRD_AVAILABLE", "BOOT_GRUB_AVAILABLE", "BOOT_DIRECT_GENERIC_AVAILABLE",
                "BOOT_PREPARATION_LAYOUT", "BOOT_DIRECT_GENERIC_REASON")
PREFIX = r'''
source "$1"
TRACE=$2
MKINITRD_CONFIG=$3
GRUB_DIRECTORY=$4
trace() { printf '%s\n' "$1" >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
command() {
    [[ $# == 2 && $1 == -v ]] || forbidden command-arguments
    trace "lookup:$2"
    case "$2" in
        mkinitrd) (( HAS_MKINITRD == 1 )) ;;
        grub-mkconfig) (( HAS_GRUB == 1 )) ;;
        grub-script-check) (( HAS_VALIDATOR == 1 )) ;;
        *) forbidden "command:$2" ;;
    esac
}
function [ {
    if [[ $# == 3 && $1 == -f && $2 == "$MKINITRD_CONFIG" && $3 == ']' ]]; then
        trace file:config
    elif [[ $# == 3 && $1 == -d && $2 == "$GRUB_DIRECTORY" && $3 == ']' ]]; then
        trace directory:grub
    elif [[ $# == 4 && $1 == '!' && $2 == -L && $4 == ']' ]]; then
        case "$3" in
            "$MKINITRD_CONFIG") trace not-link:config ;;
            "$GRUB_DIRECTORY") trace not-link:grub ;;
            *) forbidden "link-path:$3" ;;
        esac
    elif [[ $# == 3 && ( $1 == -f || $1 == -d || $1 == -L || $1 == -r || $1 == -x ) ]]; then
        forbidden "path:$2"
    fi
    builtin [ "$@"
}
probe_direct_generic_boot_layout() {
    [[ $# == 0 ]] || forbidden direct-arguments
    trace direct-probe
    BOOT_DIRECT_GENERIC_AVAILABLE=$DIRECT_OK
    BOOT_DIRECT_GENERIC_REASON=$DIRECT_REASON
    (( DIRECT_OK == 1 ))
}
'''
FORBIDDEN = ("main", "load_configuration", "initialize_runtime", "initialize_runtime_state",
             "classify_direct_generic_boot_layout", "run_check_workflow", "run_apply_workflow",
             "run_dry_run_workflow", "mkinitrd", "grub-mkconfig", "grub-script-check")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
TRIGGERS = ((0, 0), (0, 1), (1, 0), (1, 1))
AUTO_ROWS = {
    (0, 0): ((0, 0), (0, 0), (0, 0), (0, 0)),
    (0, 1): ((0, 0), (0, 1), (0, 0), (0, 1)),
    (1, 0): ((0, 0), (0, 0), (1, 0), (1, 0)),
    (1, 1): TRIGGERS,
}


def probe_cases():
    for mode in ("disabled", "enabled", "auto"):
        for label, commands, config_kind, grub_kind, capabilities, queries in CAPABILITIES:
            for direct_ok, direct_reason in ((1, ""), (0, "supplied-direct-rejection"), (0, "")):
                initrd, grub = capabilities
                trace = list(queries)
                if mode == "disabled":
                    outcome = ("disabled", 0, "disabled by configuration", 0, 0, 0, "unknown", "")
                    trace = []
                elif capabilities == (1, 1):
                    outcome = ("available", 1, "", 1, 1, 0, "mkinitrd-managed", "")
                elif grub and direct_ok:
                    trace.append("direct-probe")
                    outcome = ("available", 1, "", 0, 1, 1, "direct-generic-no-initrd", "")
                else:
                    reason = "no supported initrd or GRUB preparation path was detected"
                    if grub:
                        trace.append("direct-probe")
                    if mode == "enabled":
                        if capabilities == (0, 0):
                            reason = "initrd and GRUB preparation requirements are missing"
                        elif not grub:
                            reason = "GRUB preparation requirements are missing"
                        elif direct_reason:
                            reason = "neither managed initrd nor safe direct-generic boot is available: " + direct_reason
                        else:
                            reason = "initrd preparation requirements are missing"
                    outcome = ("unavailable", 0, reason, initrd, grub, 0, "unknown", direct_reason if grub else "")
                values = dict(BOOT_MODE=mode, HAS_MKINITRD=commands[0], HAS_GRUB=commands[1],
                              HAS_VALIDATOR=commands[2], DIRECT_OK=direct_ok, DIRECT_REASON=direct_reason)
                yield label, values, config_kind, grub_kind, outcome, trace


def policy_cases():
    for mode, layout, availability, index in itertools.product(
            ("disabled", "enabled", "auto"), ("unknown", "mkinitrd-managed", "direct-generic-no-initrd"),
            TRIGGERS, range(4)):
        requested = TRIGGERS[index]
        direct = layout == "direct-generic-no-initrd"
        required = (0, requested[1]) if direct else requested
        row = ((0, 0),) * 4 if mode == "disabled" else TRIGGERS if mode == "enabled" else AUTO_ROWS[availability]
        selected_index = (0, 1, 0, 1)[index] if direct else index
        updates = row[selected_index]
        values = dict(BOOT_MODE=mode, BOOT_PREPARATION_LAYOUT=layout,
                      BOOT_INITRD_AVAILABLE=availability[0], BOOT_GRUB_AVAILABLE=availability[1],
                      INITRD_UPDATE=requested[0], GRUB_UPDATE=requested[1])
        yield values, (*required, *updates)


def fixture(path, kind, target):
    if kind == "file":
        path.write_bytes(b"private fixture\n")
    elif kind == "directory":
        path.mkdir()
    elif kind == "link":
        path.symlink_to(target)
    elif kind == "broken":
        path.symlink_to(path.parent / "absent-target")
    else:
        assert kind == "missing"


def run_case(work, values, function, fields, expected, trace_lines, config_kind="missing", grub_kind="missing"):
    config, grub, trace = work / "mkinitrd.conf", work / "grub directory", work / "trace"
    fixture(config, config_kind, work / "config-target")
    fixture(grub, grub_kind, work / "grub-target")
    trace.write_bytes(b"")
    assignments = "\n".join(f"{name}={shlex.quote(str(value))}" for name, value in values.items())
    poison = {name: "stale" for name in fields}
    poison.update(values)
    reset = "\n".join(f"{name}={shlex.quote(str(value))}" for name, value in poison.items())
    output = 'printf \'%s\\0\' "$status" ' + " ".join(f'"${{{name}}}"' for name in fields) + ' "$IFS"\n'
    driver = PREFIX + GUARDS + "\n" + assignments + "\nIFS='|: '\nfor repetition in 1 2; do\n" + reset + "\n" + function + '\nstatus=$?\n' + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "boot-policy-test",
                             str(REFERENCE), str(trace), str(config), str(grub)],
                            cwd=work, capture_output=True, timeout=10)
    assert result.returncode == 0 and result.stderr == b"", (values, result.returncode, result.stderr)
    packet = b"".join(str(value).encode() + b"\0" for value in (0, *expected, "|: "))
    assert result.stdout == packet * 2, (values, result.stdout, packet * 2)
    assert trace.read_bytes() == ("".join(line + "\n" for line in trace_lines) * 2).encode(), (values, trace.read_bytes(), trace_lines)
    if config_kind == "file":
        assert config.read_bytes() == b"private fixture\n"
    assert (work / "config-target").read_bytes() == b"private config target\n"
    assert (work / "grub-target").is_dir()


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-boot-policy-") as directory:
        parent = Path(directory)
        for _, values, config_kind, grub_kind, expected, trace in probe_cases():
            work = parent / str(count)
            work.mkdir()
            (work / "config-target").write_bytes(b"private config target\n")
            (work / "grub-target").mkdir()
            run_case(work, values, "probe_boot_module", PROBE_FIELDS, expected, trace, config_kind, grub_kind)
            count += 1
        for values, expected in policy_cases():
            work = parent / str(count)
            work.mkdir()
            (work / "config-target").write_bytes(b"private config target\n")
            (work / "grub-target").mkdir()
            fields = ("INITRD_REQUIRED", "GRUB_REQUIRED", "INITRD_UPDATE", "GRUB_UPDATE")
            run_case(work, values, "apply_boot_module_policy", fields, expected, [])
            count += 1
    return count


def main():
    count = run_cases()
    print(f"Boot module policy: {count} scenarios, {2 * count} entry calls, 0 failures")


if __name__ == "__main__":
    main()
