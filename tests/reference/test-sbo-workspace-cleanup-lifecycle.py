#!/usr/bin/env python3
"""Compose SBo cleanup bindings with real EXIT/signal cleanup and private locks."""
import itertools
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FAULTS = ('none', 'canonical-mismatch', 'symlink', 'canonical-fail', 'owned-rm-fail', 'owned-removed-43')
LAYOUTS = ('outside-runtime', 'inside-runtime', 'inside-runtime-rm-fail')
ENTRIES = ('direct', 'exit0', 'exit17', 'term')
SHELL = r'''
source "$1"
root=$2
workspace=$3
FAULT=$4
LAYOUT=$5
ENTRY=$6
record() { builtin printf '%s\0' "$@" >> "$root/trace"; builtin printf '\n' >> "$root/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
readlink() {
    [[ $# == 3 && $1 == -m && $2 == -- && $3 == "$workspace" ]] || forbidden readlink-vector
    record readlink "$@"
    case "$FAULT" in
        canonical-mismatch) builtin printf '%s\n' "$root/other" ;;
        canonical-fail) builtin printf 'supplied canonical failure\n' >&2; return 43 ;;
        *) builtin command readlink "$@" ;;
    esac
}
rm() {
    if [[ $# == 6 && $1 == -f && $2 == "$root/final" && $3 == "$root/broken-new" && \
            $4 == "$root/still-broken" && $5 == "$root/broken-errors" && $6 == "$root/cache" ]]; then
        record rm-files "$@"
    elif [[ $# == 3 && $1 == -rf && $2 == -- && $3 == "$workspace" ]]; then
        record rm-owned "$@"
        [[ $FAULT != owned-rm-fail ]] || return 43
        if [[ $FAULT == owned-removed-43 ]]; then
            builtin command rm "$@" || return
            return 43
        fi
    elif [[ $# == 3 && $1 == -rf && $2 == -- && $3 == "$root/runtime" ]]; then
        record rm-runtime "$@"
        [[ $LAYOUT != inside-runtime-rm-fail ]] || return 43
    else forbidden rm-vector; fi
    builtin command rm "$@"
}
flock() {
    [[ $# == 2 && ( $1 == -n || $1 == -u ) && $2 == 9 ]] || forbidden flock-vector
    record flock "$@"
    builtin command flock "$@"
}
remove_owned_geninitrd_policy_temporary() {
    [[ $# == 2 && -z $1 && $2 == 0 ]] || forbidden geninitrd-vector
    record geninitrd "$@"
}
discard_owned_grub_temporary_config() {
    [[ $# == 0 ]] || forbidden grub-vector
    record grub
}
definition=$(declare -f remove_owned_sbo_queue_workspace)
eval "${definition/remove_owned_sbo_queue_workspace/test_real_owned_cleanup}"
remove_owned_sbo_queue_workspace() {
    local result=0
    test_real_owned_cleanup || result=$?
    record owned-return "$result" "$SBO_GENERATED_QUEUE_OWNED_PATH" "$SBO_GENERATED_QUEUE_OWNED_CANONICAL"
    return "$result"
}
definition=$(declare -f cleanup)
eval "${definition/cleanup/test_real_cleanup}"
unset definition
cleanup() {
    local result=0
    local descriptor=closed
    test_real_cleanup || result=$?
    if { true >&9; } 2>/dev/null; then descriptor=open; fi
    record cleanup-return "$result" "$SBO_GENERATED_QUEUE_OWNED_PATH" \
        "$SBO_GENERATED_QUEUE_OWNED_CANONICAL" "$INSTANCE_LOCK_HELD" "$descriptor"
    return "$result"
}
QUEUE_FINAL=$root/final
BROKEN_NEW=$root/broken-new
STILL_BROKEN=$root/still-broken
BROKEN_ERRORS=$root/broken-errors
ELF_LIBRARY_CACHE=$root/cache
RUNTIME_TMPDIR=$root/runtime
GENINITRD_POLICY_OVERRIDE_ACTIVE=0
GENINITRD_POLICY_BACKUP_OWNED=0
SBO_GENERATED_QUEUE_OWNED_PATH=$workspace
SBO_GENERATED_QUEUE_OWNED_CANONICAL=$workspace
LOCKFILE=$root/lock
INSTANCE_LOCK_HELD=0
acquire_instance_lock || exit 98
record acquired "$INSTANCE_LOCK_HELD"
case "$ENTRY" in
    direct) cleanup; result=$?; builtin printf 'direct=%s\n' "$result"; exit 0 ;;
    exit0) install_runtime_traps; exit 0 ;;
    exit17) install_runtime_traps; exit 17 ;;
    term) install_runtime_traps; builtin kill -s TERM "$$"; exit 99 ;;
    *) forbidden entry ;;
esac
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime',
          'initialize_dry_run_runtime', 'initialize_runtime_state', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow', 'slackpkg',
          'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget', 'regenerate_initrd',
          'update_grub_configuration', 'restore_geninitrd_grub_policy_override',
          'prepare_private_sbo_queue_workspace')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path == root / 'trace':
            continue
        mode = path.lstat().st_mode & 0o777
        result[str(path.relative_to(root))] = (
            ('link', os.readlink(path), mode) if path.is_symlink()
            else ('dir', mode) if path.is_dir() else ('file', path.read_bytes(), mode))
    return result


def encode(rows):
    return b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in rows)


def scenario(reference, root, fault, layout, entry):
    (root / 'protected').mkdir(mode=0o700)
    (root / 'protected/sentinel').write_bytes(b'preserve target\n')
    (root / 'runtime').mkdir(mode=0o700)
    (root / 'runtime/other').write_bytes(b'other runtime state\n')
    workspace = root / ('workspace' if layout == 'outside-runtime' else 'runtime/queues')
    if fault == 'symlink':
        workspace.symlink_to(root / 'protected')
    else:
        workspace.mkdir(mode=0o700)
        (workspace / 'queue.sqf').write_bytes(b'private queue\n')
    for name in ('final', 'broken-new', 'still-broken', 'broken-errors', 'cache'):
        (root / name).write_bytes(b'temporary\n')
    (root / 'lock').touch()
    before = inventory(root)
    expected = before.copy()
    for name in ('final', 'broken-new', 'still-broken', 'broken-errors', 'cache'):
        del expected[name]
    remove_workspace = fault in ('none', 'owned-removed-43')
    remove_runtime = layout != 'inside-runtime-rm-fail'
    relative = str(workspace.relative_to(root))
    expected = {name: row for name, row in expected.items()
                if not (remove_workspace and (name == relative or name.startswith(relative + '/')))
                and not (remove_runtime and (name == 'runtime' or name.startswith('runtime/')))}
    binding = '' if fault == 'none' else str(workspace)
    helper = 0 if fault == 'none' else 1
    calls = [('flock', '-n', '9'), ('acquired', '1'), ('geninitrd', '', '0'),
             ('rm-files', '-f', *(str(root / name) for name in
                ('final', 'broken-new', 'still-broken', 'broken-errors', 'cache'))),
             ('grub',), ('readlink', '-m', '--', str(workspace))]
    if fault in ('none', 'owned-rm-fail', 'owned-removed-43'):
        calls.append(('rm-owned', '-rf', '--', str(workspace)))
    calls += [('owned-return', helper, binding, binding), ('rm-runtime', '-rf', '--', str(root / 'runtime')),
              ('flock', '-u', '9'), ('cleanup-return', 0, binding, binding, 0, 'closed')]
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    script = SHELL.replace('QUEUE_FINAL=$root/final', guards + 'QUEUE_FINAL=$root/final', 1)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script,
                             'cleanup-lifecycle-test', str(reference), str(root), str(workspace), fault, layout, entry],
                            capture_output=True, timeout=10, cwd=root,
                            env=dict(os.environ, LC_ALL='C', BASH_ENV='/dev/null'))
    status = {'direct': 0, 'exit0': 0, 'exit17': 17, 'term': 143}[entry]
    stdout = b'direct=0\n' if entry == 'direct' else b''
    stderr = b'Interrupted by SIGTERM; cleaning up and exiting with status 143\n' if entry == 'term' else b''
    assert (result.returncode, result.stdout, result.stderr) == (status, stdout, stderr), (
        fault, layout, entry, result.returncode, result.stdout, result.stderr)
    assert (root / 'trace').read_bytes() == encode(calls), (fault, layout, entry, (root / 'trace').read_bytes(), calls)
    assert inventory(root) == expected, (fault, layout, entry, inventory(root), expected)
    lock = subprocess.run(['flock', '-n', str(root / 'lock'), '-c', 'true'], capture_output=True, timeout=5)
    assert (lock.returncode, lock.stdout, lock.stderr) == (0, b'', b''), 'lock still held after cleanup'
    return dict(fault=fault, layout=layout, entry=entry, helper=helper, binding_retained=bool(binding),
                parent_removal_attempted=True, parent_removed=remove_runtime,
                workspace_present=workspace.exists() or workspace.is_symlink(), exit_status=status)


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix="sbo lifecycle's ") as directory:
        for number, case in enumerate(itertools.product(FAULTS, LAYOUTS, ENTRIES)):
            root = Path(directory).resolve() / str(number)
            root.mkdir()
            rows.append(scenario(REFERENCE, root, *case))
    assert len(rows) == 72 and sum(row['binding_retained'] for row in rows) == 60
    print('SBo workspace cleanup lifecycle: 72 scenarios, 0 failures')


if __name__ == '__main__':
    main()
