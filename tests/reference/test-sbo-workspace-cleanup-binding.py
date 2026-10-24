#!/usr/bin/env python3
"""Check retained unresolved SBo cleanup bindings and unchanged deletion refusal."""
import itertools
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
CASES = ('absent-empty', 'absent-unset', 'normal', 'missing', 'canonical-mismatch',
         'symlink', 'dangling-symlink', 'ancestor-symlink', 'readlink-1', 'readlink-43',
         'readlink-127', 'readlink-output-43', 'rm-1', 'rm-43', 'rm-127', 'rm-removed-43')
SHELL = r'''
source "$1"
root=$2
workspace=$3
kind=$4
entry=$5
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
record() { builtin printf '%s\0' "$@" >> "$root/trace"; }
readlink() {
    [[ $# == 3 && $1 == -m && $2 == -- && $3 == "$workspace" ]] || forbidden readlink-vector
    record readlink "$@"
    case "$kind" in
        readlink-1) return 1 ;;
        readlink-43) return 43 ;;
        readlink-127) return 127 ;;
        readlink-output-43) builtin command readlink "$@" || return; return 43 ;;
        canonical-mismatch) builtin printf '%s\n' "$root/other" ;;
        *) builtin command readlink "$@" ;;
    esac
}
rm() {
    [[ $# == 3 && $1 == -rf && $2 == -- && $3 == "$workspace" ]] || forbidden rm-vector
    record rm "$@"
    case "$kind" in
        rm-1) return 1 ;;
        rm-43) return 43 ;;
        rm-127) return 127 ;;
        rm-removed-43) builtin command rm "$@" || return; return 43 ;;
        *) builtin command rm "$@" ;;
    esac
}
SBO_GENERATED_QUEUE_OWNED_PATH=$workspace
SBO_GENERATED_QUEUE_OWNED_CANONICAL=$workspace
case "$kind" in
    absent-empty) SBO_GENERATED_QUEUE_OWNED_PATH= ;;
    absent-unset) unset SBO_GENERATED_QUEUE_OWNED_PATH SBO_GENERATED_QUEUE_OWNED_CANONICAL ;;
esac
owned_path=outer-path
owned_canonical=outer-canonical
current_canonical=outer-current
IFS='|: '
saved_ifs=$IFS
if [[ $entry == conditional ]]; then
    set -e
    first=0
    remove_owned_sbo_queue_workspace || first=$?
else
    remove_owned_sbo_queue_workspace
    first=$?
fi
builtin printf '%s\0' "$first" "${SBO_GENERATED_QUEUE_OWNED_PATH-<unset>}" \
    "${SBO_GENERATED_QUEUE_OWNED_CANONICAL-<unset>}"
if [[ $entry == conditional ]]; then
    second=0
    remove_owned_sbo_queue_workspace || second=$?
else
    remove_owned_sbo_queue_workspace
    second=$?
fi
builtin printf '%s\0' "$second" "${SBO_GENERATED_QUEUE_OWNED_PATH-<unset>}" \
    "${SBO_GENERATED_QUEUE_OWNED_CANONICAL-<unset>}"
[[ $owned_path == outer-path && $owned_canonical == outer-canonical && \
    $current_canonical == outer-current && $IFS == "$saved_ifs" ]] || forbidden caller-state
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'cleanup',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow', 'slackpkg',
          'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget', 'regenerate_initrd',
          'update_grub_configuration', 'prepare_private_sbo_queue_workspace')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path == root / 'trace':
            continue
        name = str(path.relative_to(root))
        mode = path.lstat().st_mode & 0o777
        result[name] = (('link', os.readlink(path), mode) if path.is_symlink()
                        else ('dir', mode) if path.is_dir() else ('file', path.read_bytes(), mode))
    return result


def encode(values):
    return b''.join(str(value).encode() + b'\0' for value in values)


def scenario(reference, root, kind, entry):
    real = root / 'real'
    real.mkdir(mode=0o700)
    (real / 'sentinel').write_bytes(b'protected target\n')
    workspace = root / 'workspace'
    if kind == 'ancestor-symlink':
        (root / 'real-parent').mkdir()
        workspace = root / 'alias/workspace'
        (root / 'alias').symlink_to(root / 'real-parent', target_is_directory=True)
        workspace.mkdir(mode=0o700)
        (workspace / 'personal.sqf').write_bytes(b'private queue\n')
    elif kind in ('symlink', 'dangling-symlink'):
        workspace.symlink_to(real if kind == 'symlink' else root / 'missing-target')
    elif kind != 'missing':
        workspace.mkdir(mode=0o700)
        (workspace / 'personal.sqf').write_bytes(b'private queue\n')
    before = inventory(root)
    success = kind in ('absent-empty', 'absent-unset', 'normal', 'missing')
    if kind == 'absent-empty':
        states = [0, '', str(workspace)] * 2
        calls = []
    elif kind == 'absent-unset':
        states = [0, '<unset>', '<unset>'] * 2
        calls = []
    elif success:
        states = [0, '', ''] * 2
        calls = ['readlink', '-m', '--', str(workspace), 'rm', '-rf', '--', str(workspace)]
    else:
        states = [1, str(workspace), str(workspace)] * 2
        calls = ['readlink', '-m', '--', str(workspace)]
        if kind.startswith('rm-'):
            calls += ['rm', '-rf', '--', str(workspace)]
        calls *= 2
    expected = before.copy()
    if kind in ('normal', 'rm-removed-43'):
        expected = {name: row for name, row in before.items()
                    if name != 'workspace' and not name.startswith('workspace/')}
    # Guards must be defined before entering the tested function.
    definitions = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    script = SHELL.replace('SBO_GENERATED_QUEUE_OWNED_PATH=$workspace',
                           definitions + 'SBO_GENERATED_QUEUE_OWNED_PATH=$workspace', 1)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script,
                             'cleanup-binding-test', str(reference), str(root), str(workspace), kind, entry],
                            capture_output=True, timeout=10, cwd=root,
                            env=dict(os.environ, LC_ALL='C', BASH_ENV='/dev/null'))
    assert (result.returncode, result.stdout, result.stderr) == (0, encode(states), b''), (
        kind, entry, result.returncode, result.stdout, states, result.stderr)
    actual_calls = (root / 'trace').read_bytes() if (root / 'trace').exists() else b''
    assert actual_calls == encode(calls), (kind, entry, actual_calls, calls)
    assert inventory(root) == expected, (kind, entry, inventory(root), expected)
    return dict(kind=kind, entry=entry, failed=not success)


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix="sbo cleanup's ") as directory:
        for number, (kind, entry) in enumerate(itertools.product(CASES, ('direct', 'conditional'))):
            root = Path(directory).resolve() / str(number)
            root.mkdir()
            rows.append(scenario(REFERENCE, root, kind, entry))
    assert len(rows) == 32 and sum(row['failed'] for row in rows) == 24
    print('SBo workspace cleanup binding: 32 scenarios, 0 failures')


if __name__ == '__main__':
    main()
