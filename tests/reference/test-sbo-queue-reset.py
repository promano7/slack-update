#!/usr/bin/env python3
"""Check private queue removal failure before core collection and the ABI gate."""
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('TOTAL_CORE', 'SBO_OPTION_RECORD_COUNT', 'TOTAL_EXTRA', 'SBO_BUILD_STATUS',
          'SBO_TARGET_SELECTION_ERROR', 'SBO_QUEUE_GENERATION_READY', 'TOTAL', 'TOTAL_EN_COLA')
FAULTS = ('none', 'absent', 'symlink', 'dir-core', 'dir-extra', 'dir-options',
          'quiet-1', 'quiet-43', 'quiet-127', 'partial-43', 'removed-43', 'resolve')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
resolve_sbo_personal_queue_directory() {
    record resolve
    if [[ $FAULT == resolve ]]; then SBO_TARGET_SELECTION_ERROR=supplied-resolve-error; return 43; fi
    SBO_PERSONAL_QUEUE_DIR=$TEST_ROOT/queues
}
rm() {
    [[ $# == 4 && $1 == -f && $2 == "$QUEUE_CORE" && $3 == "$QUEUE_EXTRA" \
        && $4 == "$SBO_OPTION_RECORDS" ]] || forbidden remove-vector
    record remove "$@"
    case "$FAULT" in
        quiet-1) return 1 ;;
        quiet-43) return 43 ;;
        quiet-127) return 127 ;;
        partial-43)
            builtin command rm -f -- "$QUEUE_CORE" || forbidden partial-removal
            builtin printf 'supplied-remove-output\n'
            return 43 ;;
        removed-43)
            builtin command rm "$@" || forbidden completed-removal
            return 43 ;;
    esac
    builtin command rm "$@"
}
collect_ordered_sbo_targets_from_queue_directory() {
    [[ $# == 2 && $1 == "$TEST_ROOT/queues" && $2 == "$QUEUE_CORE" ]] || forbidden core-vector
    record core "$@"
    SBO_TARGET_SELECTION_ERROR=
    builtin printf '%s' "$CORE_BYTES" > "$2"
}
collect_sbo_option_records_from_sources() {
    [[ $# == 3 && $1 == "$TEST_ROOT/queues" && $2 == "$SBO_OPTIONS_FILE" \
        && $3 == "$SBO_OPTION_RECORDS" ]] || forbidden options-vector
    record options "$@"
    builtin printf '%s' "$OPTION_BYTES" > "$3"
    SBO_OPTION_RECORD_COUNT=$OPTION_COUNT
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    record count "$@"
    builtin command wc "$@"
}
add_abi_rebuild_targets() {
    record abi
    TOTAL_EXTRA=9
    builtin printf 'supplied-abi-target\n' > "$QUEUE_EXTRA"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'configure_logging', 'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'readelf', 'ldd', 'ldconfig', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration', 'detect_broken_elf_objects',
          'map_broken_objects_to_sbo_packages', 'collect_installed_sbo_targets',
          'build_and_apply_sbo_queue', 'verify_broken_elf_objects_after_rebuild')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path.name == 'events': continue
        name = path.relative_to(root).as_posix()
        if path.is_symlink(): result[name] = ('symlink', os.readlink(path))
        elif path.is_dir(): result[name] = ('dir',)
        else: result[name] = ('file', path.read_bytes())
    return result


def scenario(root, profile, fault, gate, resolve):
    core, options = {'empty': ('', ''), 'full': ('zeta\nalpha\nbeta\n', 'alpha\tV=yes\nbeta\tN=2\n')}[profile]
    (root / 'queues').mkdir()
    for name, data in {'core': 'old-core\n', 'extra': 'old-extra\n', 'options': 'old-options\n',
                       'overrides': 'old-overrides\n', 'sentinel': 'private-target-must-survive\n'}.items():
        (root / name).write_text(data)
    queue_names = ('core', 'extra', 'options')
    if fault == 'absent':
        for name in queue_names: (root / name).unlink()
    elif fault == 'symlink':
        (root / 'core').unlink()
        (root / 'core').symlink_to(root / 'sentinel')
    elif fault.startswith('dir-'):
        path = root / fault.removeprefix('dir-')
        path.unlink()
        path.mkdir()
        (path / 'child').write_text('directory child must survive\n')
    expected_files = inventory(root)
    old = ['6', '5', '4', '3', 'old-error', '1', '11', '12']
    state = old.copy()
    calls = [('resolve',)] if resolve else []
    output = '[6] Generando colas SBo\n'
    status = 0
    stderr = b''
    if fault == 'resolve' and resolve:
        state[4] = 'supplied-resolve-error'
        status = 1
    else:
        calls.append(('remove', '-f', str(root / 'core'), str(root / 'extra'), str(root / 'options')))
        if not fault.startswith('quiet-'):
            removed = ('core',) if fault == 'partial-43' else queue_names
            for name in removed:
                if expected_files.get(name) != ('dir',): expected_files.pop(name, None)
        failed = fault.startswith(('quiet-', 'dir-')) or fault in ('partial-43', 'removed-43')
        if fault == 'partial-43': output += 'supplied-remove-output\n'
        if failed:
            state[4] = 'cannot remove previous private SBo queue files'
            status = 1
            if fault.startswith('dir-'):
                target = root / fault.removeprefix('dir-')
                stderr = ("rm: cannot remove '" + str(target) + "': Is a directory\n").encode()
        else:
            calls.extend((('core', str(root / 'queues'), str(root / 'core')),
                          ('options', str(root / 'queues'), str(root / 'overrides'), str(root / 'options')),
                          ('count', '-l')))
            expected_files['core'] = ('file', core.encode())
            expected_files['options'] = ('file', options.encode())
            state[0], state[1], state[4] = str(core.count('\n')), str(options.count('\n')), ''
            output += '  Cola principal: ' + state[0] + ' paquetes\n'
            output += '  Opciones de compilacion preservadas: ' + state[1] + '\n'
            if gate:
                calls.append(('abi',))
                state[2] = '9'
                expected_files['extra'] = ('file', b'supplied-abi-target\n')
    if status: output += '  [ERROR] ' + state[4] + '\n'
    values = dict(zip(FIELDS, old)) | dict(
        QUEUE_CORE=str(root / 'core'), QUEUE_EXTRA=str(root / 'extra'), SBO_OPTION_RECORDS=str(root / 'options'),
        SBO_OPTIONS_FILE=str(root / 'overrides'), SBO_PERSONAL_QUEUE_DIR='' if resolve else str(root / 'queues'),
        SBO_QUEUE_SOURCE_DIR='', FAULT=fault, CORE_BYTES=core, OPTION_BYTES=options,
        OPTION_COUNT=options.count('\n'))
    assignments = '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    script = PREFIX + guards + '\n' + assignments + '\n'
    script += 'saved_ifs=$IFS\nouter=kept\ncore_count=outer-count\n'
    script += ('build_sbo_target_queues_after_synchronization' if gate else 'build_sbo_core_queue') + '\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $core_count == outer-count ]] || exit 96\n'
    script += '[[ $SBO_QUEUE_SOURCE_DIR == "$TEST_ROOT/queues" ]] || [[ $FAULT == resolve && -z $SBO_QUEUE_SOURCE_DIR ]] || exit 95\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'sbo-queue-reset-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    label = (profile, fault, gate, resolve)
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, stderr):
        raise AssertionError(f'{label}: wanted {(0, wanted, stderr)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    actual = (root / 'events').read_bytes()
    if actual != events: raise AssertionError(f'{label}: ordered command vectors differ')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-queue-reset-') as tmp:
        for values in itertools.product(('empty', 'full'), FAULTS, (0, 1), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'SBo queue reset tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
