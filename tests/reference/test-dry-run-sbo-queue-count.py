#!/usr/bin/env python3
"""Check current SBo queue count failures and the dry-run candidate-stage gate."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('TOTAL_CORE', 'SBO_OPTION_RECORD_COUNT', 'PLAN_ABI_SBO_COUNT',
          'SBO_TARGET_SELECTION_ERROR', 'SBO_TARGET_SELECTION_STATUS',
          'TOTAL_EXTRA', 'TOTAL', 'SBO_QUEUE_GENERATION_READY')
FAULTS = ('none', 'count-1', 'count-43', 'count-127', 'count-partial',
          'count-zero', 'count-stderr', 'missing', 'directory', 'core', 'options', 'resolve')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
resolve_sbo_personal_queue_directory() {
    [[ $# == 0 ]] || forbidden resolve-vector
    record resolve
    if [[ $FAULT == resolve ]]; then SBO_TARGET_SELECTION_ERROR=supplied-resolve-error; return 43; fi
    SBO_PERSONAL_QUEUE_DIR=$TEST_ROOT/queues
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
        count-zero) builtin printf '0\n'; return 43 ;;
        count-stderr) builtin printf 'supplied count failure\n' >&2; return 43 ;;
    esac
    builtin command wc "$@"
}
collect_installed_sbo_candidates() {
    [[ $# == 0 ]] || forbidden candidate-vector
    record candidates
    PLAN_ABI_SBO_COUNT=9
    builtin printf 'supplied-candidate\n' > "$ABI_CANDIDATES"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'initialize_dry_run_runtime', 'configure_logging', 'run_apply_workflow',
          'run_check_workflow', 'run_dry_run_workflow', 'slackpkg', 'sbopkg', 'sqg', 'flatpak',
          'readelf', 'ldd', 'ldconfig', 'git', 'curl', 'wget', 'date', 'regenerate_initrd',
          'update_grub_configuration', 'detect_broken_elf_objects', 'map_broken_objects_to_sbo_packages',
          'collect_installed_sbo_targets', 'build_sbo_core_queue', 'build_and_apply_sbo_queue',
          'verify_broken_elf_objects_after_rebuild', 'print_json_result', 'emit_final_events')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, gate, seed):
    core, options = {
        'empty': ('', ''),
        'one': ('alpha\n', 'alpha\tV=yes\n'),
        'many': ('zeta\nalpha\nbeta\n', 'alpha\tV=yes\nbeta\tN=2\n'),
    }[profile]
    (root / 'queues').mkdir()
    for name, data in {'core': 'old-core\n', 'extra': 'old-extra\n', 'options': 'old-options\n',
                       'overrides': 'old-overrides\n', 'candidates': 'old-candidates\n',
                       'sentinel': 'untouched\n'}.items():
        (root / name).write_text(data)
    expected_files = inventory(root)
    state = ['6' if seed else '0', '5', '4', 'old-error', '7', '8', '11', '1']
    old = state.copy()
    calls = [('resolve',)]
    status = 0
    output = '[PLAN] Inspecting current SBo queues\n'
    if fault == 'resolve':
        state[3] = 'supplied-resolve-error'
        status = 1
    else:
        calls.append(('core', str(root / 'queues'), str(root / 'core')))
        state[3] = ''
        if fault == 'core':
            state[3] = 'supplied-core-error'
            status = 1
        else:
            expected_files['core'] = ('file', core.encode())
            calls.append(('options', str(root / 'queues'), str(root / 'overrides'), str(root / 'options')))
            if fault == 'options':
                state[3] = 'supplied-options-error'
                status = 1
            else:
                expected_files['options'] = ('file', options.encode())
                state[1] = str(options.count('\n'))
                if fault == 'missing': expected_files.pop('core')
                elif fault == 'directory': expected_files['core'] = ('dir',)
                if fault != 'missing': calls.append(('count', '-l'))
                if fault.startswith('count-') or fault in ('missing', 'directory'):
                    state[3] = 'cannot count the current local SBo queue'
                    status = 1
                else:
                    state[0] = str(core.count('\n'))
                    output += '  Current local queue targets: ' + state[0] + '\n'
                    output += '  Preserved build-option records: ' + state[1] + '\n'
    if status:
        output += '  [ERROR] ' + state[3] + '\n'
    elif gate:
        calls.append(('candidates',))
        state[2] = '9'
        expected_files['candidates'] = ('file', b'supplied-candidate\n')
    values = dict(zip(FIELDS, old)) | dict(
        QUEUE_CORE=str(root / 'core'), QUEUE_EXTRA=str(root / 'extra'), SBO_OPTION_RECORDS=str(root / 'options'),
        SBO_OPTIONS_FILE=str(root / 'overrides'), ABI_CANDIDATES=str(root / 'candidates'),
        SBO_PERSONAL_QUEUE_DIR='', SBO_QUEUE_SOURCE_DIR='old-source', FAULT=fault,
        CORE_BYTES=core, OPTION_BYTES=options, OPTION_COUNT=options.count('\n'))
    assignments = '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    script = PREFIX + guards + '\n' + assignments + '\n'
    script += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\ncore_count=outer-count\n"
    script += ('inspect_current_sbo_queues && collect_installed_sbo_candidates' if gate else 'inspect_current_sbo_queues') + '\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $core_count == outer-count ]] || exit 96\n'
    script += '[[ $SBO_QUEUE_SOURCE_DIR == "$TEST_ROOT/queues" ]] || [[ $FAULT == resolve && $SBO_QUEUE_SOURCE_DIR == old-source ]] || exit 95\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'dry-sbo-count-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    if fault == 'missing':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(root / 'core')) + r': No such file or directory\n'
        stderr_ok = re.fullmatch(pattern, result.stderr.decode()) is not None
    elif fault == 'directory':
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n', result.stderr.decode()) is not None
    elif fault == 'count-stderr':
        stderr_ok = result.stderr == b'supplied count failure\n'
    else:
        stderr_ok = result.stderr == b''
    label = (profile, fault, gate, seed)
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0, wanted)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root / 'events').read_bytes()
    wanted_events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    if actual != wanted_events: raise AssertionError(f'{label}: ordered command vectors differ')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-dry-sbo-count-') as tmp:
        for values in itertools.product(('empty', 'one', 'many'), FAULTS, (0, 1), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'Dry-run SBo queue count tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
