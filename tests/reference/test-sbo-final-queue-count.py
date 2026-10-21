#!/usr/bin/env python3
"""Check final SBo queue count failures before an inert builder can run."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('TOTAL', 'TOTAL_EN_COLA', 'SBO_BUILD_STATUS', 'SBO_TARGET_SELECTION_ERROR',
          'ELF_VERIFICATION_STATUS', 'TOTAL_CORE', 'TOTAL_EXTRA', 'SBO_OPTION_RECORD_COUNT')
FAULTS = ('none', 'count-1', 'count-43', 'count-127', 'count-partial',
          'merge', 'missing', 'directory')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
definition=$(declare -f merge_ordered_sbo_queue_with_target_sets)
eval "${definition/merge_ordered_sbo_queue_with_target_sets/real_merge_ordered_sbo_queue_with_target_sets}"
unset definition
merge_ordered_sbo_queue_with_target_sets() {
    [[ $# == 4 && $1 == "$QUEUE_FINAL" && $2 == "$QUEUE_CORE" && $4 == "$QUEUE_EXTRA" \
        && ( $3 == "$TEST_ROOT/options" || $3 == /dev/null ) ]] || forbidden merge-vector
    record merge "$@"
    [[ $FAULT != merge ]] || return 43
    real_merge_ordered_sbo_queue_with_target_sets "$@" || return $?
    if [[ $FAULT == missing || $FAULT == directory ]]; then
        [[ $QUEUE_FINAL == "$TEST_ROOT/final" && -f $QUEUE_FINAL && ! -L $QUEUE_FINAL ]] || forbidden count-fixture
        builtin command rm -- "$QUEUE_FINAL" || forbidden remove-final
        if [[ $FAULT == directory ]]; then builtin command mkdir -- "$QUEUE_FINAL" || forbidden directory-final; fi
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
sbopkg() {
    [[ $# == 3 && $1 == -b && $2 == -B && $3 == "$QUEUE_FINAL" ]] || forbidden builder-vector
    record builder "$@"
    return "$BUILD_CODE"
}
verify_broken_elf_objects_after_rebuild() { record verify; return 19; }
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'configure_logging', 'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'slackpkg', 'sqg', 'flatpak', 'readelf', 'ldd', 'ldconfig', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration', 'detect_broken_elf_objects',
          'map_broken_objects_to_sbo_packages', 'collect_installed_sbo_targets')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, broken, build_code, options):
    core, extra, final = {
        'empty': ('', '', ''),
        'one': ('alpha\n', '', 'alpha' + (' | V=yes' if options else '') + '\n'),
        'many': ('zeta\nalpha\nzeta\n', 'beta\nalpha\n',
                 'zeta\nalpha' + (' | V=yes' if options else '') + '\nbeta\n'),
    }[profile]
    for name, data in {'core': core, 'extra': extra, 'options': 'alpha\tV=yes\n',
                       'final': 'old-final\n', 'broken': 'old-broken\n' if broken else '',
                       'log': 'old-log\n'}.items():
        (root / name).write_text(data)
    expected_files = inventory(root)
    old = ['11', '12', '3', 'old-error', '8', '6', '4', '5']
    state = old.copy()
    calls = [('merge', str(root / 'final'), str(root / 'core'),
              str(root / 'options') if options else '/dev/null', str(root / 'extra'))]
    output = '[10] Aplicando cola SBo\n'
    status = 0
    if fault == 'merge':
        state[2:4] = ['1', 'cannot build the final dependency-ordered SBo queue']
        output += '  [ERROR] ' + state[3] + '\n'
        status = 1
    else:
        expected_files['final'] = ('file', final.encode())
        if fault == 'missing': expected_files.pop('final')
        elif fault == 'directory': expected_files['final'] = ('dir',)
        # Failed input redirection prevents the count function from being entered.
        if fault != 'missing': calls.append(('count', '-l'))
        if fault != 'none':
            state[2:4] = ['1', 'cannot count the final dependency-ordered SBo queue']
            output += '  [ERROR] ' + state[3] + '\n'
            status = 1
        else:
            count = str(final.count('\n'))
            state[0:2] = [count, count]
            output += '  Total paquetes en cola: ' + count + '\n'
            if not final:
                output += '  Cola vacia, nada que hacer\n'
            else:
                state[2] = str(build_code)
                calls.append(('builder', '-b', '-B', str(root / 'final')))
                output += ('  [OK] Cola SBo procesada\n' if not build_code else
                           '  [WARN] sbopkg termino con errores -- revisar log: ' + str(root / 'log') + '\n')
                if broken: calls.append(('verify',))
    values = dict(zip(FIELDS, old)) | dict(
        QUEUE_CORE=str(root / 'core'), QUEUE_EXTRA=str(root / 'extra'), QUEUE_FINAL=str(root / 'final'),
        SBO_OPTION_RECORDS=str(root / 'options'), BROKEN=str(root / 'broken'), LOG=str(root / 'log'),
        FAULT=fault, BUILD_CODE=build_code)
    assignments = '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    guards = '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    script = PREFIX + guards + '\n' + assignments + '\n'
    if not options: script += 'unset SBO_OPTION_RECORDS\n'
    script += 'saved_ifs=$IFS\nouter=kept\nqueue_count=outer-count\n'
    script += 'build_and_apply_sbo_queue\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $queue_count == outer-count ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script,
                             'sbo-final-count-test', str(REFERENCE), str(root)],
                            capture_output=True, cwd=root, timeout=10,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    if fault == 'missing':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(root / 'final')) + r': No such file or directory\n'
        stderr_ok = re.fullmatch(pattern, result.stderr.decode()) is not None
    elif fault == 'directory':
        # GNU wc consumes stdin and reports the directory as its input descriptor.
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n', result.stderr.decode()) is not None
    else:
        stderr_ok = result.stderr == b''
    label = (profile, fault, broken, build_code, options)
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0, wanted)!r}; got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root / 'events').read_bytes()
    wanted_events = b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in calls)
    if actual != wanted_events:
        raise AssertionError(f'{label}: ordered command vectors differ: {actual!r} != {wanted_events!r}')
    if inventory(root) != expected_files:
        raise AssertionError(f'{label}: complete private file inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-final-count-') as tmp:
        for values in itertools.product(('empty', 'one', 'many'), FAULTS, (0, 1), (0, 7, 20), (0, 1)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'SBo final queue count tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
