#!/usr/bin/env python3
"""Check core SBo queue count failures and the following ABI-stage gate."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('TOTAL_CORE', 'SBO_OPTION_RECORD_COUNT', 'TOTAL_EXTRA', 'SBO_BUILD_STATUS',
          'SBO_TARGET_SELECTION_ERROR', 'SBO_QUEUE_GENERATION_READY', 'TOTAL', 'TOTAL_EN_COLA')
FAULTS = ('none', 'count-1', 'count-43', 'count-127', 'count-partial',
          'missing', 'directory', 'core', 'options', 'resolve')
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
    builtin command rm "$@"
}
collect_ordered_sbo_targets_from_queue_directory() {
    [[ $# == 2 && $1 == "$TEST_ROOT/queues" && $2 == "$QUEUE_CORE" ]] || forbidden core-vector
    record core "$@"
    SBO_TARGET_SELECTION_ERROR=
    if [[ $FAULT == core ]]; then SBO_TARGET_SELECTION_ERROR=supplied-core-error; return 43; fi
    builtin printf '%s' "$CORE_BYTES" > "$2"
}
collect_sbo_option_records_from_sources() {
    [[ $# == 3 && $1 == "$TEST_ROOT/queues" && $2 == "$SBO_OPTIONS_FILE" \
        && $3 == "$SBO_OPTION_RECORDS" ]] || forbidden options-vector
    record options "$@"
    SBO_TARGET_SELECTION_ERROR=
    if [[ $FAULT == options ]]; then SBO_TARGET_SELECTION_ERROR=supplied-options-error; return 43; fi
    builtin printf '%s' "$OPTION_BYTES" > "$3"
    SBO_OPTION_RECORD_COUNT=$OPTION_COUNT
    if [[ $FAULT == missing || $FAULT == directory ]]; then
        [[ $QUEUE_CORE == "$TEST_ROOT/core" && -f $QUEUE_CORE && ! -L $QUEUE_CORE ]] || forbidden count-fixture
        builtin command rm -- "$QUEUE_CORE" || forbidden remove-core
        if [[ $FAULT == directory ]]; then builtin command mkdir -- "$QUEUE_CORE" || forbidden directory-core; fi
    fi
    return 0
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    record count "$@"
    case "$FAULT" in
        count-1) return 1 ;;
        count-43) return 43 ;;
        count-127) return 127 ;;
        count-partial) builtin printf '42\n'; return 43 ;;
    esac
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
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, gate, resolve, seed):
    core, options = {
        'empty': ('', ''),
        'one': ('alpha\n', 'alpha\tV=yes\n'),
        'many': ('zeta\nalpha\nbeta\n', 'alpha\tV=yes\nbeta\tN=2\n'),
    }[profile]
    (root / 'queues').mkdir()
    for name, data in {'core': 'old-core\n', 'extra': 'old-extra\n', 'options': 'old-options\n',
                       'overrides': 'old-overrides\n'}.items():
        (root / name).write_text(data)
    expected_files = inventory(root)
    old = ['6' if seed else '0', '5', '4', '3', 'old-error', '1', '11', '12']
    state = old.copy()
    calls = []
    status = 0
    output = '[6] Generando colas SBo\n'
    if resolve: calls.append(('resolve',))
    if fault == 'resolve' and resolve:
        state[4] = 'supplied-resolve-error'
        status = 1
        output += '  [ERROR] ' + state[4] + '\n'
    else:
        calls.append(('remove', '-f', str(root / 'core'), str(root / 'extra'), str(root / 'options')))
        for name in ('core', 'extra', 'options'): expected_files.pop(name)
        calls.append(('core', str(root / 'queues'), str(root / 'core')))
        state[4] = ''
        if fault == 'core':
            state[4] = 'supplied-core-error'
            status = 1
        else:
            expected_files['core'] = ('file', core.encode())
            calls.append(('options', str(root / 'queues'), str(root / 'overrides'), str(root / 'options')))
            if fault == 'options':
                state[4] = 'supplied-options-error'
                status = 1
            else:
                expected_files['options'] = ('file', options.encode())
                state[1] = str(options.count('\n'))
                if fault == 'missing': expected_files.pop('core')
                elif fault == 'directory': expected_files['core'] = ('dir',)
                if fault != 'missing': calls.append(('count', '-l'))
                if fault in ('count-1', 'count-43', 'count-127', 'count-partial', 'missing', 'directory'):
                    state[4] = 'cannot count the core SBo queue'
                    status = 1
                else:
                    state[0] = str(core.count('\n'))
                    output += '  Cola principal: ' + state[0] + ' paquetes\n'
                    output += '  Opciones de compilacion preservadas: ' + state[1] + '\n'
        if status: output += '  [ERROR] ' + state[4] + '\n'
        elif gate:
            calls.append(('abi',))
            state[2] = '9'
            expected_files['extra'] = ('file', b'supplied-abi-target\n')
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
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'sbo-core-count-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    if fault == 'missing':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(root / 'core')) + r': No such file or directory\n'
        stderr_ok = re.fullmatch(pattern, result.stderr.decode()) is not None
    elif fault == 'directory':
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n', result.stderr.decode()) is not None
    else:
        stderr_ok = result.stderr == b''
    label = (profile, fault, gate, resolve, seed)
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0, wanted)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root / 'events').read_bytes()
    wanted_events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    if actual != wanted_events: raise AssertionError(f'{label}: ordered command vectors differ')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-core-count-') as tmp:
        for values in itertools.product(('empty', 'one', 'many'), FAULTS, (0, 1), (0, 1), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'SBo core queue count tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
