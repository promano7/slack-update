#!/usr/bin/env python3
"""Check the Flatpak operation wrapper using supplied discovery and command results."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
# label, (discovered, raw command status) sequence, authored stored-status sequence
PROFILES = (
    ("missing", ((0, 0),), ("seed",)),
    *((f"raw-{raw}", ((1, raw),), (raw,)) for raw in (0, 1, 2, 20, 42, 69, 127, 255)),
    ("success-missing", ((1, 0), (0, 0)), (0, 0)),
    ("failure-missing", ((1, 42), (0, 0)), (42, 42)),
    ("missing-success", ((0, 0), (1, 0)), ("seed", 0)),
    ("missing-failure", ((0, 0), (1, 20)), ("seed", 20)),
    ("failure-success", ((1, 255), (1, 0)), (255, 0)),
    ("success-failure", ((1, 0), (1, 69)), (0, 69)),
)
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
command() {
    [[ $# == 2 && $1 == -v && $2 == flatpak ]] || forbidden command-arguments
    trace lookup "$@"
    printf 'supplied discovery stdout\n'
    printf 'supplied discovery stderr\n' >&2
    (( PRESENT == 1 ))
}
flatpak() {
    trace flatpak "$@"
    if [[ $PAYLOAD == 1 ]]; then
        printf 'supplied Flatpak stdout\n'
        printf 'supplied Flatpak stderr\n' >&2
    fi
    return "$COMMAND_STATUS"
}
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "probe_flatpak_module", "probe_optional_modules",
             "emit_event", "print_json_result", "slackpkg", "sbopkg", "sqg", "git", "curl", "wget", "mkinitrd", "geninitrd",
             "grub-mkconfig", "date", "find", "sort", "rm", "mv", "mktemp")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = ("FLATPAK_STATUS", "FLATPAK_MODE", "FLATPAK_MODULE_RUN", "FLATPAK_MODULE_STATE", "FLATPAK_MODULE_REASON", "ABI_TRIGGER", "SBO_BUILD_STATUS")


def cases():
    return itertools.product(PROFILES, (-1, 0, 42, 255), (0, 1))


def run_case(work, profile, seed, payload):
    trace = work / "callback trace"
    trace.write_bytes(b"")
    initial = dict(FLATPAK_STATUS=seed, FLATPAK_MODE="auto", FLATPAK_MODULE_RUN=1, FLATPAK_MODULE_STATE="supplied-state",
                   FLATPAK_MODULE_REASON="supplied reason with spaces", ABI_TRIGGER=7, SBO_BUILD_STATUS=8, PAYLOAD=payload)
    reset = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in initial.items())
    output = 'printf \'RESULT\\0%s\\0\' "$raw"; printf \'%s\\0\' ' + " ".join(f'"${{{name}}}"' for name in FIELDS) + ' "$IFS"\n'
    operations = ""
    for present, raw in profile[1]:
        operations += f"PRESENT={present}\nCOMMAND_STATUS={raw}\nupdate_flatpak\nraw=$?\n" + output
    script = PREFIX + GUARDS + "\nIFS='|: '\nfor repetition in 1 2; do\n" + reset + "\n" + operations + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "flatpak-update-test", str(REFERENCE), str(trace)],
                            capture_output=True, timeout=10)
    stdout, stderr, rows = b"", b"", []
    assert len(profile[1]) == len(profile[2])
    for (present, _), stored in zip(profile[1], profile[2]):
        rows.append(("lookup", "-v", "flatpak"))
        stdout += b"[2] Flatpak update\n"
        if present:
            rows.append(("flatpak", "update", "-y", "--noninteractive"))
            if payload:
                stdout += b"supplied Flatpak stdout\n"
                stderr += b"supplied Flatpak stderr\n"
        else:
            stdout += b"  Flatpak no instalado, omitiendo\n"
        state = dict(initial, FLATPAK_STATUS=seed if stored == "seed" else stored)
        stdout += b"RESULT\0" + b"0\0" + b"".join(str(value).encode() + b"\0" for value in (*[state[name] for name in FIELDS], "|: "))
    expected_trace = b"".join(b"".join(str(value).encode() + b"\0" for value in row) + b"\n" for row in rows) * 2
    identity = profile[0], seed, payload
    assert result.returncode == 0, (identity, "driver", result.returncode, result.stderr)
    assert result.stdout == stdout * 2, (identity, "stdout", result.stdout, stdout * 2)
    assert result.stderr == stderr * 2, (identity, "stderr", result.stderr, stderr * 2)
    assert trace.read_bytes() == expected_trace, (identity, "trace", trace.read_bytes(), expected_trace)
    assert sorted(path.name for path in work.iterdir()) == ["callback trace"], (identity, "private inventory")


def main():
    count = entries = 0
    with tempfile.TemporaryDirectory(prefix="slack-update Flatpak wrapper ") as temporary:
        for profile, seed, payload in cases():
            run_case(Path(temporary), profile, seed, payload)
            count += 1
            entries += len(profile[1]) * 2
    print(f"Flatpak update wrapper: {count} scenarios, {entries} wrapper entries, 0 failures")


if __name__ == "__main__":
    main()
