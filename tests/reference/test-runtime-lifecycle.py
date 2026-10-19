#!/usr/bin/env python3
"""Compose real state/runtime initialization, EXIT cleanup and private instance locking."""
from pathlib import Path
import itertools
import os
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('QUEUE_FINAL', 'BROKEN_NEW', 'STILL_BROKEN', 'BROKEN_ERRORS', 'ELF_LIBRARY_CACHE', 'RUNTIME_TMPDIR')
DRY_LEAVES = ('broken.txt', 'queue-core.sqf', 'queue-extra.sqf', 'sbo-options.normalized', 'broken-errors.txt', 'elf-library-cache.txt')
ORDINARY_FAULTS = ('none', 'start-date', 'mkdir', 'runtime-date', 'temp1', 'temp2', 'temp3', 'temp4', 'temp5')
DRY_FAULTS = ('none', 'start-date', 'mkdir', 'runtime-date', 'temp1', 'file1', 'file2', 'file3', 'file4', 'file5', 'file6')
SHELL = r'''
source "$1"
TEST_ROOT=$2
FAULT=$3
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/trace"; builtin printf '\n' >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
date() {
    record date "$@"
    if [[ $# == 2 && $1 == -u && $2 == +%Y-%m-%dT%H:%M:%SZ ]]; then
        [[ $FAULT != start-date ]] || return 43
        builtin printf '2030-02-03T04:05:06Z\n'
    elif [[ $# == 1 && $1 == +%F-%H%M%S ]]; then
        [[ $FAULT != runtime-date ]] || return 43
        builtin printf '2030-02-03-040506\n'
    else forbidden date-vector; fi
}
mkdir() {
    [[ $# -ge 2 && $1 == -p ]] || forbidden mkdir-vector
    record mkdir "$@"
    [[ $FAULT != mkdir ]] || return 43
    builtin command mkdir "$@"
}
mktemp() {
    local count path
    IFS= read -r count < "$TEST_ROOT/count"
    count=$((count + 1))
    builtin printf '%s\n' "$count" > "$TEST_ROOT/count"
    record mktemp "$@"
    [[ $FAULT != "temp$count" ]] || return 43
    if [[ $# == 0 ]]; then
        path=$TEST_ROOT/tmp/file-$count
        : > "$path" || forbidden create-file
    elif [[ $# == 2 && $1 == -d && $2 == /tmp/slack-update-dry-run.XXXXXX ]]; then
        path=$TEST_ROOT/tmp/dry
        builtin command mkdir -- "$path" || forbidden create-workspace
        case "$FAULT" in
            file1) builtin command mkdir -- "$path/broken.txt" ;;
            file2) builtin command mkdir -- "$path/queue-core.sqf" ;;
            file3) builtin command mkdir -- "$path/queue-extra.sqf" ;;
            file4) builtin command mkdir -- "$path/sbo-options.normalized" ;;
            file5) builtin command mkdir -- "$path/broken-errors.txt" ;;
            file6) builtin command mkdir -- "$path/elf-library-cache.txt" ;;
        esac
    else forbidden mktemp-vector; fi
    builtin printf '%s\n' "$path"
}
rm() {
    [[ $1 == -f || ( $1 == -rf && $2 == -- ) ]] || forbidden rm-vector
    local path
    for path in "${@:2}"; do
        [[ -z $path || $path == -- || $path == "$TEST_ROOT/"* ]] || forbidden rm-path
    done
    record rm "$@"
    builtin command rm "$@"
}
flock() {
    [[ $# == 2 && ( $1 == -n || $1 == -u ) && $2 == 9 ]] || forbidden flock-vector
    record flock "$@"
    builtin command flock "$@"
}
'''
FORBIDDEN = ('main', 'require_root', 'initialize_execution_environment', 'load_configuration',
             'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow', 'configure_logging',
             'rotate_logs', 'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget',
             'readelf', 'ldconfig', 'mkinitrd', 'grub-mkconfig', 'restore_geninitrd_grub_policy_override')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)


def snapshot(root):
    return {str(p.relative_to(root)): ('link', os.readlink(p)) if p.is_symlink() else ('dir',) if p.is_dir()
            else ('file', p.read_bytes()) for p in root.rglob('*') if p.name != 'trace'}


def scenario(root, dry, fault, populated):
    (root / 'protected/runtime').mkdir(parents=True)
    (root / 'tmp').mkdir()
    (root / 'count').write_text('0\n')
    prior = [root / 'protected' / name.lower() for name in FIELDS[:-1]]
    for path in prior:
        path.write_bytes(b'preserve prior file\n')
    (root / 'protected/runtime/keep').write_bytes(b'preserve prior directory\n')
    prior.append(root / 'protected/runtime')
    expected = snapshot(root)
    expected['lock'] = ('file', b'')
    bindings = [''] * 6
    calls = [('flock', '-n', '9'), ('date', '-u', '+%Y-%m-%dT%H:%M:%SZ')]
    status = 0 if fault == 'none' else 1
    stderr = b''
    stderr_pattern = None
    count = 0
    if fault == 'start-date':
        stderr = b'Error: cannot record the runtime start time\n'
    else:
        work, log = root / 'work', root / 'logs'
        calls.append(('mkdir', '-p', str(log)) if dry else ('mkdir', '-p', str(work), str(log)))
        if fault == 'mkdir':
            stderr = (f'Error: cannot create the dry-run log directory: {log}\n' if dry else f'Error: cannot create runtime directories: {work}, {log}\n').encode()
        else:
            expected['logs'] = ('dir',)
            if not dry:
                expected['work'] = ('dir',)
            calls.append(('date', '+%F-%H%M%S'))
            if fault == 'runtime-date':
                stderr = ('Error: cannot create the ' + ('dry-run' if dry else 'runtime') + ' timestamp\n').encode()
            elif dry:
                count = 1
                calls.append(('mktemp', '-d', '/tmp/slack-update-dry-run.XXXXXX'))
                if fault == 'temp1':
                    stderr = b'Error: cannot create the private dry-run workspace\n'
                else:
                    private = root / 'tmp/dry'
                    bindings = [str(private / leaf) for leaf in ('queue-final.sqf', 'broken-new.txt', 'still-broken.txt', 'broken-errors.txt', 'elf-library-cache.txt')] + [str(private)]
                    if fault.startswith('file'):
                        blocked = private / DRY_LEAVES[int(fault[4:]) - 1]
                        message = f'{blocked}: Is a directory\nError: cannot initialize dry-run state file: {blocked}\n'
                        stderr_pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(message)
            else:
                names = ('final queue', 'broken-object scan', 'broken-object verification', 'broken-object diagnostics', 'ELF library-cache')
                for number in range(1, 6):
                    count = number
                    calls.append(('mktemp',))
                    if fault == 'temp' + str(number):
                        stderr = f'Error: cannot create the {names[number - 1]} temporary file\n'.encode()
                        break
                    bindings[number - 1] = str(root / f'tmp/file-{number}')
    expected['count'] = ('file', (str(count) + '\n').encode())
    calls.append(('rm', '-f', *bindings[:-1]))
    if bindings[-1]:
        calls.append(('rm', '-rf', '--', bindings[-1]))
    calls.append(('flock', '-u', '9'))
    values = dict(zip(FIELDS, map(str, prior))) if populated else dict.fromkeys(FIELDS, '')
    values.update(WORKDIR_CONFIG=str(root / 'work'), LOGDIR_CONFIG=str(root / 'logs'), CSB_DIR_CONFIG=str(root / 'csb'), LOCKFILE=str(root / 'lock'), INSTANCE_LOCK_HELD='0')
    assignments = '\n'.join(name + '=' + shlex.quote(value) for name, value in values.items())
    function = 'initialize_dry_run_runtime' if dry else 'initialize_runtime'
    suffix = '\nacquire_instance_lock || exit 98\ninstall_runtime_traps\n' + function + '\nraw=$?\n'
    suffix += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n' + '\n'.join('builtin printf "%s\\0" "$' + name + '"' for name in FIELDS)
    suffix += '\nbuiltin printf "%s\\0" "$INSTANCE_LOCK_HELD"\nexit "$raw"\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', SHELL + GUARDS + '\n' + assignments + suffix,
                             'runtime-lifecycle-test', str(REFERENCE), str(root), fault], capture_output=True, cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root / 'tmp')), timeout=10)
    wanted = b'\0STATE\0' + str(status).encode() + b'\0' + b''.join(value.encode() + b'\0' for value in bindings) + b'1\0'
    raw_trace = (root / 'trace').read_bytes()
    actual_calls = [tuple(item.decode() for item in line.split(b'\0')[:-1]) for line in raw_trace.split(b'\n') if line]
    actual_snapshot = snapshot(root)
    stderr_ok = bool(re.fullmatch(stderr_pattern, result.stderr.decode())) if stderr_pattern else result.stderr == stderr
    observed = (result.returncode, result.stdout, actual_calls, actual_snapshot)
    expected_values = (status, wanted, calls, expected)
    if observed != expected_values or not stderr_ok:
        raise AssertionError(f'{dry}/{fault}/{populated}: expected {expected_values!r}, stderr={stderr_pattern or stderr!r}; got {observed!r}, stderr={result.stderr!r}')
    available = subprocess.run(['flock', '-n', str(root / 'lock'), '-c', 'true'], capture_output=True, timeout=5)
    if (available.returncode, available.stdout, available.stderr) != (0, b'', b''):
        raise AssertionError('private instance lock remains unavailable after process exit')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-runtime-lifecycle-') as temporary:
        for dry, faults in ((False, ORDINARY_FAULTS), (True, DRY_FAULTS)):
            for fault, populated in itertools.product(faults, (False, True)):
                root = Path(temporary).resolve() / str(count)
                root.mkdir()
                scenario(root, dry, fault, populated)
                count += 1
    print(f'Runtime lifecycle tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
