#!/usr/bin/env python3
"""Check configuration path selection using private files and modeled predicates."""

from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
SYSTEM = "/etc/slack-update/slack-update.conf"
DRIVER = r'''
source "$1"
PRIVATE_ROOT=$2
SYSTEM_EXISTS=$3
SYSTEM_READABLE=$4
DENIED_PATH=$5
presence=$6
override=$7
shift 7
CONFIG_FILE=stale
if [[ $presence == unset ]]; then
    unset SLACK_UPDATE_CONFIG
else
    SLACK_UPDATE_CONFIG=$override
fi
# Model only the installed path and requested unreadability. Other -f/-r
# predicates operate on real private fixtures. No installed config is statted.
function [ {
    if (( $# == 4 )) && [[ $1 == '!' && $2 == -f && $4 == ']' ]]; then
        if [[ $3 == /etc/slack-update/slack-update.conf ]]; then
            (( SYSTEM_EXISTS == 0 )); return
        fi
        [[ $3 == "$PRIVATE_ROOT"/* ]] || { printf 'unexpected path probe\n' >&2; exit 97; }
    elif (( $# == 3 )) && [[ $3 == ']' && ( $1 == -f || $1 == -r ) ]]; then
        if [[ $2 == /etc/slack-update/slack-update.conf ]]; then
            if [[ $1 == -f ]]; then (( SYSTEM_EXISTS == 1 )); else (( SYSTEM_READABLE == 1 )); fi
            return
        fi
        [[ $2 == "$PRIVATE_ROOT"/* ]] || { printf 'unexpected path probe\n' >&2; exit 97; }
        if [[ $1 == -r && $2 == "$DENIED_PATH" ]]; then return 1; fi
    fi
    builtin [ "$@"
}
resolve_configuration_file
status=$?
printf '%s\0' "$CONFIG_FILE"
exit "$status"
'''


def exercise(fallback_kind, installed, override_kind):
    with tempfile.TemporaryDirectory(prefix="slack-update-config-resolver-") as directory:
        work = Path(directory)
        project = work / "source with spaces"
        subject = project / "tools/reference/slack-update-reference.sh"
        subject.parent.mkdir(parents=True)
        # Exact source bytes, relocated only so BASH_SOURCE finds private data.
        shutil.copyfile(REFERENCE, subject)
        fallback = project / "data/config/slack-update.conf"
        fallback.parent.mkdir(parents=True)
        explicit = work / "explicit configuration ñ.conf"
        explicit.write_text("private explicit data, not parsed\n")
        missing = work / "missing.conf"
        link = work / "linked.conf"
        link.symlink_to(explicit)
        broken = work / "broken.conf"
        broken.symlink_to(missing)
        subdirectory = work / "directory"
        subdirectory.mkdir()
        if fallback_kind == "file":
            fallback.write_text("private fallback data, not parsed\n")
        elif fallback_kind == "symlink":
            fallback.symlink_to(explicit)
        elif fallback_kind == "broken":
            fallback.symlink_to(missing)
        elif fallback_kind == "directory":
            fallback.mkdir()
        else:
            assert fallback_kind == "missing"
        present = "set"
        denied = ""
        error = ""
        status = 0
        if override_kind in ("unset", "empty"):
            present = "unset" if override_kind == "unset" else "set"
            override = ""
            if installed[0]:
                wanted = SYSTEM
                if not installed[1]:
                    status, error = 1, "configuration file is not readable: " + SYSTEM
            elif fallback_kind in ("file", "symlink"):
                wanted = str(fallback)
            else:
                wanted = SYSTEM
                status, error = 1, "configuration file not found: " + SYSTEM
        else:
            choices = {
                "file": str(explicit), "symlink": str(link), "broken": str(broken),
                "missing": str(missing), "directory": str(subdirectory),
                "relative": "relative.conf", "tilde": "~/config.conf",
                "dotdot": str(subdirectory) + "/../" + explicit.name,
                "unreadable": str(explicit),
            }
            override = wanted = choices[override_kind]
            if override_kind in ("relative", "tilde"):
                status, error = 1, "SLACK_UPDATE_CONFIG must be an absolute path"
            elif override_kind in ("broken", "missing", "directory"):
                status, error = 1, "configuration file not found: " + wanted
            elif override_kind == "unreadable":
                denied = override
                status, error = 1, "configuration file is not readable: " + wanted
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", "-c", DRIVER, "config-resolver-test",
             str(subject), str(work), str(int(installed[0])), str(int(installed[1])),
             denied, present, override], cwd=work, capture_output=True, timeout=10)
        label = (fallback_kind, installed, override_kind)
        assert result.returncode == status, (label, result.returncode, result.stderr)
        assert result.stdout == wanted.encode("utf-8") + b"\0", (label, result.stdout, wanted)
        assert result.stderr == (("Error: " + error + "\n").encode() if error else b""), (label, result.stderr)
        assert subject.read_bytes() == REFERENCE.read_bytes(), "resolver changed source"
        assert explicit.read_text() == "private explicit data, not parsed\n", "resolver changed explicit input"
        if fallback_kind == "file":
            assert fallback.read_text() == "private fallback data, not parsed\n", "resolver changed fallback input"


def run_cases():
    count = 0
    for fallback in ("file", "missing", "directory", "symlink", "broken"):
        for installed in ((False, False), (True, True), (True, False)):
            for override in ("unset", "empty"):
                exercise(fallback, installed, override)
                count += 1
    for fallback in ("file", "missing"):
        for installed in ((False, False), (True, True), (True, False)):
            for override in ("file", "symlink", "broken", "missing", "directory",
                             "relative", "tilde", "dotdot", "unreadable"):
                exercise(fallback, installed, override)
                count += 1
    return count


def main():
    count = run_cases()
    print(f"Configuration resolver: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
