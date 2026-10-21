#!/usr/bin/env python3
"""Check option-map count errors through real private collection and core gates."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('SBO_OPTION_RECORD_COUNT', 'TOTAL_CORE', 'TOTAL_EXTRA', 'SBO_BUILD_STATUS',
          'SBO_TARGET_SELECTION_ERROR', 'TOTAL', 'TOTAL_EN_COLA')
FAULTS = ('none', 'count-1', 'count-43', 'count-127', 'count-partial', 'missing', 'directory')
PROFILES = {
    'empty': ('# empty\n', None, '', ''),
    'queue': ('alpha | V=yes\n', None, 'alpha\n', 'alpha\tV=yes\n'),
    'override': ('alpha | V=yes\n', 'alpha | V=no\n', 'alpha\n', 'alpha\tV=no\n'),
    'merged': ('zeta\nalpha | V=yes\nbeta | N=2\n', 'alpha | V=no\nnew | X=1\n',
               'zeta\nalpha\nbeta\n', 'alpha\tV=no\nbeta\tN=2\nnew\tX=1\n'),
}
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
definition=$(declare -f collect_sbo_option_records_from_sources)
eval "${definition/collect_sbo_option_records_from_sources/real_collect_sbo_option_records_from_sources}"
unset definition
collect_sbo_option_records_from_sources() {
    [[ $# == 3 && $1 == "$TEST_ROOT/queues" && $2 == "$TEST_ROOT/overrides" \
        && $3 == "$SBO_OPTION_RECORDS" ]] || forbidden options-vector
    record options-entry
    OPTION_ACTIVE=1
    local result=0
    real_collect_sbo_option_records_from_sources "$@" || result=$?
    OPTION_ACTIVE=0
    record options-exit "$result"
    return "$result"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$TEST_ROOT/"* \
        && $4 == "$TEST_ROOT/"* ]] || forbidden move-vector
    builtin command mv "$@" || return $?
    if [[ $4 == "$SBO_OPTION_RECORDS" ]]; then
        record options-publish
        if [[ $FAULT == missing || $FAULT == directory ]]; then
            [[ -f $4 && ! -L $4 ]] || forbidden count-fixture
            builtin command rm -- "$4" || forbidden remove-options
            if [[ $FAULT == directory ]]; then builtin command mkdir -- "$4" || forbidden directory-options; fi
        fi
    fi
    return 0
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    if [[ $OPTION_ACTIVE == 1 ]]; then
        record options-count "$@"
        case "$FAULT" in
            count-1) return 1 ;;
            count-43) return 43 ;;
            count-127) return 127 ;;
            count-partial) builtin printf '42\n'; return 43 ;;
        esac
    else
        record core-count "$@"
    fi
    builtin command wc "$@"
}
add_abi_rebuild_targets() { record abi; TOTAL_EXTRA=9; builtin printf 'supplied-abi\n' > "$QUEUE_EXTRA"; }
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


def missing_input_diagnostic_matches(stderr, reference, missing):
    # Bash may identify an eval-defined function by its launcher rather than source.
    prefixes = (str(reference), 'environment', 'sbo-option-count-test')
    prefix = '(?:' + '|'.join(re.escape(value) for value in prefixes) + ')'
    pattern = prefix + r': line [1-9][0-9]*: ' + re.escape(str(missing)) + r': No such file or directory\n'
    return re.fullmatch(pattern, stderr.decode()) is not None


def diagnostic_controls():
    reference = Path('/private/source/reference.sh')
    missing = Path('/private/case/options')
    tail = f': line 110: {missing}: No such file or directory\n'
    cases = [(str(reference) + tail, True), ('environment' + tail, True),
             ('sbo-option-count-test' + tail, True)]
    valid = 'sbo-option-count-test' + tail
    cases += [(valid.replace(str(missing), str(missing) + '-other'), False),
              ('other-launcher' + tail, False), (valid.replace('110', '0'), False),
              (valid.replace('110', '-1'), False), (valid.replace('110', 'abc'), False),
              (valid.replace('No such file or directory', 'Permission denied'), False),
              (valid.rstrip('\n'), False), (valid + valid, False), ('junk' + valid, False),
              (str(reference) + '-other' + tail, False)]
    for text, expected in cases:
        if missing_input_diagnostic_matches(text.encode(), reference, missing) != expected:
            raise AssertionError(f'diagnostic oracle control: {text!r}')
    return len(cases)


def scenario(root, profile, fault, kind, existing):
    queue, overrides, core, options = PROFILES[profile]
    (root / 'queues').mkdir()
    (root / 'queues/private.sqf').write_text(queue)
    if overrides is not None: (root / 'overrides').write_text(overrides)
    for name in ('core', 'extra'): (root / name).write_text('old-' + name + '\n')
    if existing: (root / 'options').write_text('old-options\n')
    expected_files = inventory(root)
    state = ['0', '6', '4', '3', '', '11', '12']
    if kind != 'options':
        expected_files['core'] = ('file', core.encode())
        expected_files.pop('extra')
    expected_files['options'] = ('file', options.encode())
    if fault == 'missing': expected_files.pop('options')
    elif fault == 'directory': expected_files['options'] = ('dir',)
    calls = [('options-entry',), ('options-publish',)]
    if fault != 'missing': calls.append(('options-count', '-l'))
    failed = fault != 'none'
    raw = 1 if failed else 0
    calls.append(('options-exit', str(raw)))
    output = '[6] Generando colas SBo\n' if kind != 'options' else ''
    if failed:
        state[4] = 'cannot count normalized SBo option map'
        if kind != 'options': output += '  [ERROR] ' + state[4] + '\n'
    else:
        state[0] = str(options.count('\n'))
        if kind != 'options':
            calls.append(('core-count', '-l'))
            state[1] = str(core.count('\n'))
            output += '  Cola principal: ' + state[1] + ' paquetes\n'
            output += '  Opciones de compilacion preservadas: ' + state[0] + '\n'
            if kind == 'gate':
                calls.append(('abi',))
                state[2] = '9'
                expected_files['extra'] = ('file', b'supplied-abi\n')
    initial = ['5', '6', '4', '3', 'old-error', '11', '12']
    values = dict(zip(FIELDS, initial)) | dict(QUEUE_CORE=str(root / 'core'), QUEUE_EXTRA=str(root / 'extra'),
        SBO_OPTION_RECORDS=str(root / 'options'), SBO_OPTIONS_FILE=str(root / 'overrides'),
        SBO_PERSONAL_QUEUE_DIR=str(root / 'queues'), SBO_QUEUE_SOURCE_DIR=str(root / 'queues'),
        SBO_QUEUE_GENERATION_READY=1, OPTION_ACTIVE=0, FAULT=fault)
    assignments = '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    entry = {'options': 'collect_sbo_option_records_from_sources "$TEST_ROOT/queues" "$TEST_ROOT/overrides" "$SBO_OPTION_RECORDS"',
             'core': 'build_sbo_core_queue', 'gate': 'build_sbo_target_queues_after_synchronization'}[kind]
    script = PREFIX + guards + '\n' + assignments + '\nsaved_ifs=$IFS\nouter=kept\noption_count=outer-count\n'
    script += entry + '\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $option_count == outer-count && $OPTION_ACTIVE == 0 ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'sbo-option-count-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(raw).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    if fault == 'missing':
        stderr_ok = missing_input_diagnostic_matches(result.stderr, REFERENCE, root / 'options')
    elif fault == 'directory':
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n', result.stderr.decode()) is not None
    else:
        stderr_ok = result.stderr == b''
    label = (profile, fault, kind, existing)
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0, wanted)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root / 'events').read_bytes()
    wanted_events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    if actual != wanted_events: raise AssertionError(f'{label}: ordered vectors differ: {actual!r} != {wanted_events!r}')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    controls = diagnostic_controls()
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-option-count-') as tmp:
        for values in itertools.product(PROFILES, FAULTS, ('options', 'core', 'gate'), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'SBo option map count tests: {count} scenarios, {controls} diagnostic controls, 0 failures')


if __name__ == '__main__':
    run()
