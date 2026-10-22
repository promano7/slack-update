#!/usr/bin/env python3
"""Check dry-run candidate counts with real private installed-target selection."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('PLAN_ABI_SBO_COUNT', 'TOTAL_CORE', 'SBO_OPTION_RECORD_COUNT',
          'SBO_TARGET_SELECTION_ERROR', 'SBO_TARGET_SELECTION_STATUS',
          'PLAN_BROKEN_COUNT', 'PLAN_BROKEN_SBO_COUNT', 'SBO_QUEUE_GENERATION_READY')
FAULTS = ('none', 'count-1', 'count-43', 'count-127', 'count-partial',
          'count-zero', 'count-stderr', 'missing', 'directory', 'collect', 'enumerate', 'normalize')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
definition=$(declare -f collect_installed_sbo_targets)
eval "${definition/collect_installed_sbo_targets/real_collect_installed_sbo_targets}"
unset definition
collect_installed_sbo_targets() {
    [[ $# == 1 && $1 == "$ABI_CANDIDATES" ]] || forbidden collect-vector
    record collect "$@"
    if [[ $FAULT == collect ]]; then SBO_TARGET_SELECTION_ERROR=supplied-collect-error; return 43; fi
    real_collect_installed_sbo_targets "$@" || return $?
    if [[ $FAULT == missing || $FAULT == directory ]]; then
        [[ $ABI_CANDIDATES == "$TEST_ROOT/candidates" && -f $ABI_CANDIDATES && ! -L $ABI_CANDIDATES ]] || forbidden count-fixture
        builtin command rm -- "$ABI_CANDIDATES" || forbidden remove-candidates
        if [[ $FAULT == directory ]]; then builtin command mkdir -- "$ABI_CANDIDATES" || forbidden directory-candidates; fi
    fi
    return 0
}
find() {
    [[ $# == 8 && $1 == -H && $2 == "$PACKAGE_DATABASE" && $3 == -maxdepth && $4 == 1 \
        && $5 == -type && $6 == f && $7 == -printf && $8 == '%f\n' ]] || forbidden enumerate-vector
    record enumerate "$@"
    if [[ $FAULT == enumerate ]]; then builtin printf 'partial-1.0-x86_64-1_SBo\n'; return 43; fi
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
        count-zero) builtin printf '0\n'; return 43 ;;
        count-stderr) builtin printf 'supplied candidate count failure\n' >&2; return 43 ;;
    esac
    builtin command wc "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'initialize_dry_run_runtime', 'configure_logging', 'run_apply_workflow',
          'run_check_workflow', 'run_dry_run_workflow', 'slackpkg', 'sbopkg', 'sqg', 'flatpak',
          'readelf', 'ldd', 'ldconfig', 'git', 'curl', 'wget', 'date', 'regenerate_initrd',
          'update_grub_configuration', 'detect_broken_elf_objects', 'map_broken_objects_to_sbo_packages',
          'inspect_current_sbo_queues', 'build_sbo_core_queue', 'build_and_apply_sbo_queue',
          'verify_broken_elf_objects_after_rebuild', 'print_json_result', 'emit_final_events')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, conditional, seed):
    database = root / 'packages'
    database.mkdir()
    records, targets = {
        'empty': ([], []),
        'one': (['alpha-1.0-x86_64-1_SBo'], ['alpha']),
        'many': (['alpha-1.0-x86_64-1_SBo', 'alpha-2.0-x86_64-2_SBo',
                  'zeta-1.0-noarch-1_SBo', 'my-lib-3.0-x86_64-4_SBo'], ['alpha', 'my-lib', 'zeta']),
    }[profile]
    for name in records + ['native-1.0-x86_64-1', 'suffix-1.0-x86_64-1_SBo_extra', 'malformed']:
        (database / name).write_text('private manifest\n')
    (database / 'ignored-1.0-x86_64-1_SBo').mkdir()
    if fault == 'normalize':
        (database / '@unsafe-1.0-x86_64-1_SBo').write_text('private unsafe name fixture\n')
    for name, data in {'candidates': 'old-candidates\n', 'core': 'old-core\n',
                       'options': 'old-options\n', 'sentinel': 'untouched\n'}.items():
        (root / name).write_text(data)
    expected_files = inventory(root)
    old = ['4' if seed else '0', '6', '5', 'old-error', '7', '8', '9', '1']
    state = old.copy()
    calls = [('collect', str(root / 'candidates'))]
    status = 0
    if fault == 'collect':
        status = 1
        state[3] = 'supplied-collect-error'
    else:
        calls.append(('enumerate', '-H', str(database), '-maxdepth', '1', '-type', 'f', '-printf', r'%f\n'))
        state[3] = ''
        if fault == 'enumerate':
            status = 1
            state[3] = 'cannot enumerate installed package records: ' + str(database)
        elif fault == 'normalize':
            status = 1
            state[3] = 'cannot normalize installed SBo package targets'
        else:
            expected_files['candidates'] = ('file', ''.join(target + '\n' for target in targets).encode())
            if fault == 'missing': expected_files.pop('candidates')
            elif fault == 'directory': expected_files['candidates'] = ('dir',)
            if fault != 'missing': calls.append(('count', '-l'))
            if fault != 'none':
                state[3] = 'cannot count installed SBo candidates for dry-run'
                status = 1
            else:
                state[0] = str(len(targets))
    output = '  [ERROR] ' + state[3] + '\n' if status else ''
    if conditional: calls.append(('rejected' if status else 'accepted',))
    values = dict(zip(FIELDS, old)) | dict(ABI_CANDIDATES=str(root / 'candidates'),
        QUEUE_CORE=str(root / 'core'), SBO_OPTION_RECORDS=str(root / 'options'),
        PACKAGE_DATABASE=str(database), SBO_PACKAGE_TAG='_SBo', FAULT=fault)
    assignments = '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    script = PREFIX + guards + '\n' + assignments + '\n'
    script += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\ncandidate_count=outer-count\n"
    if conditional:
        script += 'if collect_installed_sbo_candidates; then raw=0; record accepted; else raw=$?; record rejected; fi\n'
    else:
        script += 'collect_installed_sbo_candidates\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $candidate_count == outer-count ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'dry-candidate-count-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    if fault == 'missing':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(root / 'candidates')) + r': No such file or directory\n'
        stderr_ok = re.fullmatch(pattern, result.stderr.decode()) is not None
    elif fault == 'directory':
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n', result.stderr.decode()) is not None
    elif fault == 'count-stderr':
        stderr_ok = result.stderr == b'supplied candidate count failure\n'
    else:
        stderr_ok = result.stderr == b''
    label = (profile, fault, conditional, seed)
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0, wanted)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root / 'events').read_bytes()
    wanted_events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    if actual != wanted_events: raise AssertionError(f'{label}: ordered command vectors differ')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-dry-candidate-count-') as tmp:
        for values in itertools.product(('empty', 'one', 'many'), FAULTS, (0, 1), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'Dry-run SBo candidate count tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
