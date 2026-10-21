#!/usr/bin/env python3
"""Check ABI queue count failures with real private package-record selection."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('TOTAL_EXTRA', 'TOTAL_CORE', 'SBO_BUILD_STATUS', 'SBO_TARGET_SELECTION_ERROR',
          'SBO_QUEUE_GENERATION_READY', 'TOTAL', 'TOTAL_EN_COLA', 'SBO_OPTION_RECORD_COUNT')
FAULTS = ('none', 'count-1', 'count-43', 'count-127', 'count-partial', 'missing', 'directory', 'collect')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
definition=$(declare -f collect_installed_sbo_targets)
eval "${definition/collect_installed_sbo_targets/real_collect_installed_sbo_targets}"
unset definition
collect_installed_sbo_targets() {
    [[ $# == 1 && $1 == "$QUEUE_EXTRA" ]] || forbidden collect-vector
    record collect "$@"
    if [[ $FAULT == collect ]]; then SBO_TARGET_SELECTION_ERROR=supplied-collect-error; return 43; fi
    real_collect_installed_sbo_targets "$@" || return $?
    if [[ $FAULT == missing || $FAULT == directory ]]; then
        [[ $QUEUE_EXTRA == "$TEST_ROOT/extra" && -f $QUEUE_EXTRA && ! -L $QUEUE_EXTRA ]] || forbidden count-fixture
        builtin command rm -- "$QUEUE_EXTRA" || forbidden remove-extra
        if [[ $FAULT == directory ]]; then builtin command mkdir -- "$QUEUE_EXTRA" || forbidden directory-extra; fi
    fi
    return 0
}
find() {
    [[ $# == 8 && $1 == -H && $2 == "$PACKAGE_DATABASE" && $3 == -maxdepth && $4 == 1 \
        && $5 == -type && $6 == f && $7 == -printf && $8 == '%f\n' ]] || forbidden enumerate-vector
    record enumerate "$@"
    builtin command find "$@"
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
touch() {
    [[ $# == 1 && $1 == "$QUEUE_EXTRA" ]] || forbidden touch-vector
    record touch "$@"
    builtin command touch "$@"
}
build_sbo_core_queue() { record core; TOTAL_CORE=9; return 0; }
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'configure_logging', 'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'readelf', 'ldd', 'ldconfig', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration', 'detect_broken_elf_objects',
          'map_broken_objects_to_sbo_packages', 'build_and_apply_sbo_queue',
          'verify_broken_elf_objects_after_rebuild')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, trigger, gate, seed):
    database = root / 'packages'
    database.mkdir()
    records, targets = {
        'empty': ([], []),
        'one': (['alpha-1.0-x86_64-1_SBo'], ['alpha']),
        'many': (['alpha-1.0-x86_64-1_SBo', 'alpha-2.0-x86_64-2_SBo',
                  'zeta-1.0-noarch-1_SBo', 'my-lib-3.0-x86_64-4_SBo'], ['alpha', 'my-lib', 'zeta']),
    }[profile]
    for name in records + ['native-1.0-x86_64-1', 'suffix-1.0-x86_64-1_SBo_extra']:
        (database / name).write_text('private manifest\n')
    (root / 'extra').write_text('old-extra\n')
    (root / 'core').write_text('old-core\n')
    expected_files = inventory(root)
    old = ['4' if seed else '0', '6', '3', 'old-error', '1', '11', '12', '5']
    state = old.copy()
    calls = []
    status = 0
    output = ''
    if gate:
        calls.append(('core',))
        state[1] = '9'
    if trigger != 1:
        calls.append(('touch', str(root / 'extra')))
    else:
        output = '[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra\n'
        calls.append(('collect', str(root / 'extra')))
        if fault == 'collect':
            state[3] = 'supplied-collect-error'
            status = 1
        else:
            calls.append(('enumerate', '-H', str(database), '-maxdepth', '1', '-type', 'f', '-printf', r'%f\n'))
            state[3] = ''
            expected_files['extra'] = ('file', ''.join(target + '\n' for target in targets).encode())
            if fault == 'missing': expected_files.pop('extra')
            elif fault == 'directory': expected_files['extra'] = ('dir',)
            if fault != 'missing': calls.append(('count', '-l'))
            if fault != 'none':
                state[3] = 'cannot count the ABI SBo target queue'
                status = 1
            else:
                state[0] = str(len(targets))
                output += '  Cola ABI extra: ' + state[0] + ' paquetes\n'
        if status: output += '  [ERROR] ' + state[3] + '\n'
    values = dict(zip(FIELDS, old)) | dict(QUEUE_EXTRA=str(root / 'extra'), PACKAGE_DATABASE=str(database),
        SBO_PACKAGE_TAG='_SBo', ABI_TRIGGER=trigger, FAULT=fault)
    assignments = '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    script = PREFIX + guards + '\n' + assignments + '\n'
    script += 'saved_ifs=$IFS\nouter=kept\nabi_count=outer-count\n'
    script += ('build_sbo_target_queues_after_synchronization' if gate else 'add_abi_rebuild_targets') + '\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $abi_count == outer-count ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'sbo-abi-count-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    if trigger == 1 and fault == 'missing':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(root / 'extra')) + r': No such file or directory\n'
        stderr_ok = re.fullmatch(pattern, result.stderr.decode()) is not None
    elif trigger == 1 and fault == 'directory':
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n', result.stderr.decode()) is not None
    else:
        stderr_ok = result.stderr == b''
    label = (profile, fault, trigger, gate, seed)
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0, wanted)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root / 'events').read_bytes()
    wanted_events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    if actual != wanted_events: raise AssertionError(f'{label}: ordered command vectors differ: {actual!r} != {wanted_events!r}')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-abi-count-') as tmp:
        for values in itertools.product(('empty', 'one', 'many'), FAULTS, (0, 1, 2), (0, 1), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'SBo ABI queue count tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
