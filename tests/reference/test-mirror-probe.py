#!/usr/bin/env python3
"""Check mirror resolution/probing and check-helper integration without network access."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
HTTPS = "https://mirror.invalid/slackware64/"
# label, mirrors text, expected active value, expected ChangeLog target, local kind, mirrors kind, error category
PROFILES = (
    ("empty", "", "", "", "missing", "file", "none"),
    ("comments", " \t\n# comment\n \t# second\r\n", "", "", "missing", "file", "none"),
    ("https", HTTPS + "\n", HTTPS, "https://mirror.invalid/slackware64/ChangeLog.txt", "missing", "file", ""),
    ("http", "http://mirror.invalid/tree\n", "http://mirror.invalid/tree", "http://mirror.invalid/tree/ChangeLog.txt", "missing", "file", ""),
    ("ftp", "ftp://mirror.invalid/tree/\n", "ftp://mirror.invalid/tree/", "ftp://mirror.invalid/tree/ChangeLog.txt", "missing", "file", ""),
    ("whitespace-crlf", " \t" + HTTPS + " \t\r\n", HTTPS, "https://mirror.invalid/slackware64/ChangeLog.txt", "missing", "file", ""),
    ("unterminated", HTTPS, HTTPS, "https://mirror.invalid/slackware64/ChangeLog.txt", "missing", "file", ""),
    ("double-slash", HTTPS + "/\n", HTTPS + "/", "https://mirror.invalid/slackware64//ChangeLog.txt", "missing", "file", ""),
    ("multiple", HTTPS + "\nhttp://other.invalid/\n", "", "", "missing", "file", "multiple"),
    ("duplicate", HTTPS + "\n" + HTTPS + "\n", "", "", "missing", "file", "multiple"),
    ("with-comment", "# first\n" + HTTPS + "\n  # second\n", HTTPS, "https://mirror.invalid/slackware64/ChangeLog.txt", "missing", "file", ""),
    ("inline", HTTPS + " # literal\n", HTTPS + " # literal", HTTPS + " # literal/ChangeLog.txt", "missing", "file", ""),
    ("unsupported", "rsync://mirror.invalid/tree\n", "rsync://mirror.invalid/tree", "rsync://mirror.invalid/tree/ChangeLog.txt", "missing", "file", ""),
    ("uppercase", "HTTPS://mirror.invalid/tree\n", "HTTPS://mirror.invalid/tree", "HTTPS://mirror.invalid/tree/ChangeLog.txt", "missing", "file", ""),
    ("relative", "relative/tree\n", "relative/tree", "relative/tree/ChangeLog.txt", "missing", "file", ""),
    ("local", "{local}/\n", "{local}/", "{local}/ChangeLog.txt", "file", "file", ""),
    ("file-local", "file://{local}\n", "file://{local}", "file://{local}/ChangeLog.txt", "file", "file", ""),
    ("local-empty", "{local}\n", "{local}", "{local}/ChangeLog.txt", "empty", "file", ""),
    ("local-directory", "{local}\n", "{local}", "{local}/ChangeLog.txt", "directory", "file", ""),
    ("local-link", "file://{local}/\n", "file://{local}/", "file://{local}/ChangeLog.txt", "link", "file", ""),
    ("local-broken", "{local}\n", "{local}", "{local}/ChangeLog.txt", "broken", "file", ""),
    ("local-missing", "file://{local}\n", "file://{local}", "file://{local}/ChangeLog.txt", "missing", "file", ""),
    ("local-denied", "{local}\n", "{local}", "{local}/ChangeLog.txt", "deny", "file", ""),
    ("missing-mirrors", "", "", "", "missing", "missing", "unreadable"),
    ("denied-mirrors", HTTPS + "\n", "", "", "missing", "deny", "unreadable"),
    ("linked-mirrors", HTTPS + "\n", HTTPS, "https://mirror.invalid/slackware64/ChangeLog.txt", "missing", "link", ""),
    ("broken-mirrors", "", "", "", "missing", "broken", "unreadable"),
    ("literal-shell", "https://mirror.invalid/$(forbidden)/;literal\n", "https://mirror.invalid/$(forbidden)/;literal", "https://mirror.invalid/$(forbidden)/;literal/ChangeLog.txt", "missing", "file", ""),
)
PREFIX = r'''
source "$1"
TRACE=$2
SLACKPKG_MIRRORS_FILE=$3
LOCAL_CHANGELOG=$4
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
function [ {
    local path= negate=0
    if [[ $# == 4 && $1 == '!' && $2 == -r && $4 == ']' ]]; then path=$3; negate=1
    elif [[ $# == 3 && $1 == -r && $3 == ']' ]]; then path=$2
    elif [[ ${1-} == -r || ${1-} == -f || ${1-} == -d || ${1-} == -x || ${1-} == -s || ${1-} == -L ]]; then
        forbidden unexpected-path-predicate
    fi
    if [[ -n $path ]]; then
        [[ $path == "$SLACKPKG_MIRRORS_FILE" || $path == "$LOCAL_CHANGELOG" ]] || forbidden unexpected-path
        trace readable "$path"
        if [[ $path == "$DENY_PATH" ]]; then (( negate == 1 )); return; fi
    fi
    builtin [ "$@"
}
command() {
    [[ $# == 2 && $1 == -v ]] || forbidden command-arguments
    trace lookup "$2"
    case "$2" in
        wget) (( HAS_WGET == 1 )) ;;
        slackpkg) (( HAS_SLACKPKG == 1 )) ;;
        *) forbidden command-name ;;
    esac
}
wget() { trace wget "$@"; return "$WGET_STATUS"; }
slackpkg() { trace slackpkg "$@"; printf 'supplied check output\n'; return "$RAW_STATUS"; }
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "load_configuration", "run_check_workflow",
             "run_dry_run_workflow", "run_apply_workflow", "probe_optional_modules", "probe_boot_module", "print_check_summary",
             "print_json_result", "emit_event", "curl", "git", "flatpak", "sbopkg", "sqg", "mkinitrd", "geninitrd",
             "grub-mkconfig", "find", "sort", "rm", "mv", "mktemp", "date")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = ("SLACKPKG_ACTIVE_MIRROR", "SLACKPKG_MIRROR_ERROR", "CHECK_STATUS", "CHECK_ERROR", "SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS",
          "raw_line", "line", "active_mirror", "active_count", "target", "local_path", "value")


def cases():
    defaults = dict(HAS_WGET=1, WGET_STATUS=0, HAS_SLACKPKG=1, RAW_STATUS=0, SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS=15)
    for profile in PROFILES:
        yield "resolve", profile, defaults
        if profile[2].startswith(("https://", "http://", "ftp://")) and not profile[6]:
            for present, raw, timeout in itertools.product((0, 1), (0, 4, 255), (1, 15, 90)):
                yield "probe", profile, defaults | dict(HAS_WGET=present, WGET_STATUS=raw, SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS=timeout)
        else:
            yield "probe", profile, defaults
    for label, present, raw, transport in itertools.product(
            ("https", "file-local", "unsupported", "multiple", "local-missing", "denied-mirrors", "inline", "literal-shell"),
            (0, 1), (0, 100, 1, 20, 255), ((1, 0), (0, 0), (1, 8))):
        profile = next(row for row in PROFILES if row[0] == label)
        yield "check", profile, defaults | dict(HAS_SLACKPKG=present, RAW_STATUS=raw, HAS_WGET=transport[0], WGET_STATUS=transport[1])


def expected(kind, profile, options, mirrors):
    _, _, active, target, local_kind, _, rejection = profile
    trace = []
    values = dict(SLACKPKG_ACTIVE_MIRROR="stale-active", SLACKPKG_MIRROR_ERROR="stale-mirror-error", CHECK_STATUS="91", CHECK_ERROR="stale-check-error",
                  SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS=str(options["SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS"]),
                  **{name: "outer-" + name for name in FIELDS[5:]})
    stdout = ""
    if kind == "check":
        trace.append(("lookup", "slackpkg"))
        stdout = "[CHECK] Slackware updates\n"
        values["CHECK_ERROR"] = ""
        if not options["HAS_SLACKPKG"]:
            values.update(CHECK_STATUS="127", CHECK_ERROR="slackpkg is not available")
            return 1, values, trace, (stdout + "  [ERROR] slackpkg is not available\n").encode()
    trace.append(("readable", str(mirrors)))
    error = {"unreadable": "slackpkg mirrors file is not readable: " + str(mirrors),
             "none": "slackpkg mirrors file has no active mirror", "multiple": "slackpkg mirrors file has multiple active mirrors", "": ""}[rejection]
    values.update(SLACKPKG_ACTIVE_MIRROR=active, SLACKPKG_MIRROR_ERROR=error)
    if kind != "resolve" and not error:
        if active.startswith(("https://", "http://", "ftp://")):
            trace.append(("lookup", "wget"))
            if not options["HAS_WGET"]:
                error = "wget is required to probe the configured slackpkg mirror"
            else:
                trace.append(("wget", "--spider", "--quiet", "--timeout=" + str(options["SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS"]), "--tries=1", "--", target))
                if options["WGET_STATUS"]:
                    error = "configured Slackware mirror ChangeLog is unreachable: " + target
        elif active.startswith(("/", "file://")):
            local = target.removeprefix("file://")
            trace.append(("readable", local))
            if local_kind in ("missing", "broken", "deny"):
                error = "configured local Slackware mirror ChangeLog is unreadable: " + local
        else:
            error = "configured slackpkg mirror uses an unsupported location: " + active
        values["SLACKPKG_MIRROR_ERROR"] = error
    if kind == "check":
        if error:
            values.update(CHECK_STATUS="69", CHECK_ERROR=error)
        else:
            trace.append(("slackpkg", "-batch=on", "-default_answer=n", "check-updates"))
            stdout += "supplied check output\n"
            values["CHECK_STATUS"] = str(options["RAW_STATUS"])
            if options["RAW_STATUS"] not in (0, 100):
                values["CHECK_ERROR"] = "slackpkg check-updates failed with exit code " + str(options["RAW_STATUS"])
        if values["CHECK_ERROR"]:
            stdout += "  [ERROR] " + values["CHECK_ERROR"] + "\n"
        raw = int(bool(values["CHECK_ERROR"]))
    else:
        raw = int(bool(error))
    return raw, values, trace, stdout.encode()


def inventory(work):
    return {str(p.relative_to(work)): ("link", str(p.readlink())) if p.is_symlink() else ("directory",) if p.is_dir() else ("file", p.read_bytes())
            for p in work.rglob("*") if p.name != "trace"}


def run_case(work, kind, raw_profile, options):
    local = work / "local mirror"
    local.mkdir()
    changelog = local / "ChangeLog.txt"
    mirror_text = raw_profile[1].replace("{local}", str(local))
    profile = (raw_profile[0], mirror_text, *(part.replace("{local}", str(local)) for part in raw_profile[2:4]), *raw_profile[4:])
    mirrors, trace = work / "mirrors file", work / "trace"
    trace.write_bytes(b"")
    for path, kind_name, data in ((mirrors, profile[5], mirror_text), (changelog, profile[4], "private ChangeLog\n")):
        if kind_name == "directory": path.mkdir()
        elif kind_name in ("file", "deny", "empty"): path.write_text("" if kind_name == "empty" else data)
        elif kind_name == "link":
            target_path = work / (path.name + " target")
            target_path.write_text(data)
            path.symlink_to(target_path)
        elif kind_name == "broken": path.symlink_to(work / "absent target")
        else: assert kind_name == "missing"
    before = inventory(work)
    denied = str(mirrors) if profile[5] == "deny" else str(changelog) if profile[4] == "deny" else ""
    values = dict(options, DENY_PATH=denied, SLACKPKG_ACTIVE_MIRROR="stale-active", SLACKPKG_MIRROR_ERROR="stale-mirror-error",
                  CHECK_STATUS=91, CHECK_ERROR="stale-check-error", **{name: "outer-" + name for name in FIELDS[5:]})
    reset = "\n".join(f"{name}={shlex.quote(str(value))}" for name, value in values.items())
    function = dict(resolve="resolve_active_slackpkg_mirror", probe="probe_slackpkg_mirror_changelog", check="check_slackware_updates")[kind]
    output = 'printf \'RESULT\\0%s\\0\' "$status"; printf \'%s\\0\' ' + " ".join(f'"${{{name}}}"' for name in FIELDS) + ' "$IFS"\n'
    driver = PREFIX + GUARDS + "\nIFS='|: '\nfor repetition in 1 2; do\n" + reset + "\n" + function + '\nstatus=$?\n' + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "mirror-probe-test", str(REFERENCE), str(trace), str(mirrors), str(changelog)],
                            capture_output=True, timeout=10)
    raw, state, rows, stdout = expected(kind, profile, options, mirrors)
    packet = stdout + b"RESULT\0" + str(raw).encode() + b"\0" + b"".join(str(value).encode() + b"\0" for value in (*[state[name] for name in FIELDS], "|: "))
    expected_trace = b"".join(b"".join(str(value).encode() + b"\0" for value in row) + b"\n" for row in rows) * 2
    identity = kind, profile[0], options
    assert result.returncode == 0, (identity, "driver", result.returncode, result.stderr)
    assert result.stderr == b"", (identity, "stderr", result.stderr)
    assert result.stdout == packet * 2, (identity, "stdout", result.stdout, packet * 2)
    assert trace.read_bytes() == expected_trace, (identity, "trace", trace.read_bytes(), expected_trace)
    assert inventory(work) == before, (identity, "private files changed")


def main():
    counts = dict(resolve=0, probe=0, check=0)
    with tempfile.TemporaryDirectory(prefix="slack-update mirror probe ") as temporary:
        for number, (kind, profile, options) in enumerate(cases()):
            work = Path(temporary) / str(number)
            work.mkdir()
            run_case(work, kind, profile, options)
            counts[kind] += 1
    total = sum(counts.values())
    print(f"Mirror probe tests: {counts['resolve']} resolver scenarios, {counts['probe']} probe scenarios, {counts['check']} check scenarios, {total * 2} entries, 0 failures")


if __name__ == "__main__":
    main()
