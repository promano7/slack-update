#!/usr/bin/env python3
"""Check Cinnamon orchestration with supplied Git and real private inert builders."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
GIT_PROFILES = ((0, 0, 0), (23, 0, 0), (0, 42, 0), (0, 0, 127))
KINDS = ("executable", "plain", "missing", "link", "broken", "nested")
PREFIX = r'''
source "$1"
WORK=$2
TRACE=$WORK/trace
CSB_DIR=$WORK/'checkout with spaces'
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
function [ {
    if [[ $# == 3 && $1 == -d && $3 == ']' ]]; then
        [[ $2 == "$CSB_DIR/.git" ]] || forbidden directory-path
        trace directory "$2"
    elif [[ $# == 3 && $1 == -x && $3 == ']' ]]; then
        [[ $2 == "$CSB_DIR/$CSB_BUILDER" ]] || forbidden executable-path
        trace executable "$2"
    elif [[ ${1-} == -f || ${1-} == -r || ${1-} == -s || ${1-} == -L ]]; then
        forbidden unexpected-file-predicate
    fi
    builtin [ "$@"
}
git() {
    trace git "$@"
    if [[ $PAYLOAD == 1 ]]; then
        printf 'supplied Git stdout\n'
        printf 'supplied Git stderr\n' >&2
    fi
    case "${1-}:${3-}" in
        -C:fetch) return "$FETCH_STATUS" ;;
        -C:reset) return "$RESET_STATUS" ;;
        clone:*) return "$CLONE_STATUS" ;;
        *) forbidden git-arguments ;;
    esac
}
cd() {
    [[ $# == 1 && $1 == "$CSB_DIR" ]] || forbidden cd-path
    trace cd "$@"
    if [[ $CD_FAIL == 1 ]]; then printf 'supplied cd failure\n' >&2; return 1; fi
    builtin cd "$@"
}
'''
BUILDER = '''#!/bin/bash
printf '%s\\0' builder "$PWD" "$#" >> "$BUILDER_TRACE"
printf '\\n' >> "$BUILDER_TRACE"
if [[ $PAYLOAD == 1 ]]; then
    printf 'supplied builder stdout\\n'
    printf 'supplied builder stderr\\n' >&2
fi
exit "$BUILDER_STATUS"
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "probe_cinnamon_module", "probe_optional_modules",
             "emit_event", "print_json_result", "slackpkg", "flatpak", "sbopkg", "sqg", "curl", "wget", "mkinitrd", "geninitrd",
             "grub-mkconfig", "date", "find", "sort", "rm", "mv", "mktemp")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = ("CINNAMON_TRIGGER", "CINNAMON_OK", "RET", "CINNAMON_MODE", "CINNAMON_MODULE_RUN", "CINNAMON_MODULE_STATE", "CSB_BRANCH", "CSB_REMOTE", "CSB_BUILDER")


def cases():
    for repo, statuses, builder, raw, payload in itertools.product(("directory", "file", "missing"), GIT_PROFILES, KINDS, (0, 23), (0, 1)):
        yield dict(trigger=1, repo=repo, git=statuses, builder=builder, raw=raw, payload=payload, cd_fail=0)
    for trigger, repo, builder, payload in itertools.product((0, 2, 3, 9), ("directory", "file", "missing"), KINDS, (0, 1)):
        yield dict(trigger=trigger, repo=repo, git=(0, 0, 0), builder=builder, raw=23, payload=payload, cd_fail=0)
    for raw, payload in itertools.product((0, 23), (0, 1)):
        yield dict(trigger=1, repo="directory", git=(0, 0, 0), builder="executable", raw=raw, payload=payload, cd_fail=1)


def inventory(work):
    return {str(path.relative_to(work)): ("link", str(path.readlink())) if path.is_symlink() else
            ("directory", path.stat().st_mode & 0o777) if path.is_dir() else ("file", path.read_bytes(), path.stat().st_mode & 0o777)
            for path in work.rglob("*") if path.name != "trace"}


def expected(case, work, builder_name):
    checkout = str(work / "checkout with spaces")
    values = dict(CINNAMON_TRIGGER=case["trigger"], CINNAMON_OK=7, RET=91, CINNAMON_MODE="auto", CINNAMON_MODULE_RUN=1,
                  CINNAMON_MODULE_STATE="supplied-state", CSB_BRANCH="private-branch", CSB_REMOTE="https://example.invalid/private/csb.git", CSB_BUILDER=builder_name)
    stdout, stderr, rows = "", "", []
    if case["trigger"] != 1:
        return values, stdout.encode(), stderr.encode(), rows
    stdout = "[11] Rebuild Cinnamon\n"
    rows.append(("directory", checkout + "/.git"))

    def git(arguments, merged):
        nonlocal stdout, stderr
        rows.append(("git", *arguments))
        if case["payload"]:
            stdout += "supplied Git stdout\n"
            if merged: stdout += "supplied Git stderr\n"
            else: stderr += "supplied Git stderr\n"

    fetch, reset, clone = case["git"]
    if case["repo"] == "directory":
        stdout += "  Actualizando repositorio CSB\n"
        git(("-C", checkout, "fetch", "origin"), True)
        if not fetch:
            git(("-C", checkout, "reset", "--hard", "origin/private-branch"), True)
        stdout += "  [WARN] No se pudo actualizar CSB -- continuando con copia local\n" if fetch or reset else "  [OK] Repositorio CSB actualizado\n"
    else:
        stdout += "  Clonando repositorio CSB\n"
        git(("clone", "-b", "private-branch", "--", values["CSB_REMOTE"], checkout), False)
        stdout += "  [ERROR] git clone de CSB fallo -- Cinnamon NO sera reconstruido\n" if clone else "  [OK] Repositorio CSB clonado\n"
    values["CINNAMON_OK"] = 0
    rows.append(("executable", checkout + "/" + builder_name))
    if case["builder"] in ("executable", "link", "nested"):
        rows.append(("cd", checkout))
        if case["cd_fail"]:
            values["RET"] = 1
            stderr += "supplied cd failure\n"
        else:
            rows.append(("builder", checkout, "0"))
            values["RET"] = case["raw"]
            if case["payload"]:
                stdout += "supplied builder stdout\n"
                stderr += "supplied builder stderr\n"
        if values["RET"] == 0:
            values.update(CINNAMON_OK=1, CINNAMON_TRIGGER=2)
            stdout += "  [OK] Cinnamon reconstruido correctamente\n"
        else:
            values["CINNAMON_TRIGGER"] = 3
            stdout += "  [ERROR] Fallo en Cinnamon -- revisar log\n"
    else:
        values["CINNAMON_TRIGGER"] = 3
        stdout += "  [ERROR] " + builder_name + " no existe o no es ejecutable\n"
    return values, stdout.encode(), stderr.encode(), rows


def run_case(work, case):
    checkout = work / "checkout with spaces"
    checkout.mkdir()
    if case["repo"] == "directory": (checkout / ".git").mkdir()
    elif case["repo"] == "file": (checkout / ".git").write_text("private metadata\n")
    name = "scripts/private builder.sh" if case["builder"] == "nested" else "private builder.sh"
    builder = checkout / name
    builder.parent.mkdir(exist_ok=True)
    if case["builder"] in ("executable", "plain", "nested"):
        builder.write_text(BUILDER)
        builder.chmod(0o644 if case["builder"] == "plain" else 0o755)
    elif case["builder"] in ("link", "broken"):
        target = work / "private builder target"
        if case["builder"] == "link": target.write_text(BUILDER); target.chmod(0o755)
        builder.symlink_to(target)
    trace = work / "trace"
    trace.write_bytes(b"")
    before = inventory(work)
    values = dict(CINNAMON_TRIGGER=case["trigger"], CINNAMON_OK=7, RET=91, CINNAMON_MODE="auto", CINNAMON_MODULE_RUN=1,
                  CINNAMON_MODULE_STATE="supplied-state", CSB_BRANCH="private-branch", CSB_REMOTE="https://example.invalid/private/csb.git", CSB_BUILDER=name,
                  FETCH_STATUS=case["git"][0], RESET_STATUS=case["git"][1], CLONE_STATUS=case["git"][2],
                  BUILDER_STATUS=case["raw"], PAYLOAD=case["payload"], CD_FAIL=case["cd_fail"])
    setup = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in values.items())
    output = 'printf \'RESULT\\0%s\\0\' "$raw"; printf \'%s\\0\' ' + " ".join(f'"${{{name}}}"' for name in FIELDS) + ' "$PWD" "$IFS"\n'
    driver = PREFIX + GUARDS + "\n" + setup + "\nIFS='|: '\nexport BUILDER_TRACE=$TRACE BUILDER_STATUS PAYLOAD\nfor repetition in 1 2; do\nrebuild_cinnamon\nraw=$?\n" + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "cinnamon-rebuild-test", str(REFERENCE), str(work)],
                            cwd=work, capture_output=True, timeout=10)
    state, stdout, stderr, rows = expected(case, work, name)
    packet = b"RESULT\0" + b"0\0" + b"".join(str(value).encode() + b"\0" for value in (*[state[name] for name in FIELDS], str(work), "|: "))
    expected_trace = b"".join(b"".join(str(value).encode() + b"\0" for value in row) + b"\n" for row in rows)
    assert result.returncode == 0, (case, "driver", result.returncode, result.stderr)
    assert result.stdout == stdout + packet + packet, (case, "stdout", result.stdout, stdout + packet + packet)
    assert result.stderr == stderr, (case, "stderr", result.stderr, stderr)
    assert trace.read_bytes() == expected_trace, (case, "trace", trace.read_bytes(), expected_trace)
    assert inventory(work) == before, (case, "private fixture change")


def main():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update Cinnamon wrapper ") as temporary:
        for count, case in enumerate(cases(), 1):
            work = Path(temporary) / str(count)
            work.mkdir()
            run_case(work, case)
    print(f"Cinnamon rebuild wrapper: {count} scenarios, {count * 2} wrapper entries, 0 failures")


if __name__ == "__main__":
    main()
