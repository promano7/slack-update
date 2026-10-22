#!/usr/bin/env python3
"""Check both dry-run ELF counts and preserve their prior pair on failure."""
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('PLAN_BROKEN_COUNT', 'PLAN_BROKEN_SBO_COUNT', 'ELF_SCAN_STATUS', 'BROKEN_COUNT',
          'TOTAL_EXTRA', 'SBO_TARGET_SELECTION_ERROR', 'SBO_TARGET_SELECTION_STATUS', 'ELF_VERIFICATION_STATUS')
SUFFIXES = ('1', '43', '127', 'partial', 'zero', 'stderr', 'missing', 'directory')
FAULTS = ('none', 'detect', 'map') + tuple(stage + '-' + suffix for stage in ('objects', 'targets') for suffix in SUFFIXES)
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
detect_broken_elf_objects() {
    [[ $# == 0 ]] || forbidden scan-vector
    record detect
    builtin printf '%s' "$OBJECT_BYTES" > "$BROKEN"
    ELF_SCAN_STATUS=0
    BROKEN_COUNT=$OBJECT_COUNT
    if [[ $FAULT == detect ]]; then ELF_SCAN_STATUS=1; return 43; fi
    return 0
}
map_broken_objects_to_sbo_packages() {
    [[ $# == 0 ]] || forbidden mapper-vector
    record map
    builtin printf '%s' "$TARGET_BYTES" > "$QUEUE_EXTRA"
    TOTAL_EXTRA=$TARGET_COUNT
    [[ $FAULT != map ]] || return 43
    local path
    case "$FAULT" in
        objects-missing|objects-directory) path=$BROKEN ;;
        targets-missing|targets-directory) path=$QUEUE_EXTRA ;;
        *) return 0 ;;
    esac
    [[ ( $path == "$TEST_ROOT/objects" || $path == "$TEST_ROOT/targets" ) && -f $path && ! -L $path ]] || forbidden count-fixture
    builtin command rm -- "$path" || forbidden remove-count-input
    if [[ $FAULT == *-directory ]]; then builtin command mkdir -- "$path" || forbidden count-input-directory; fi
    return 0
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    local index
    IFS= read -r index < "$TEST_ROOT/count-stage" || forbidden read-count-stage
    index=$((index + 1))
    [[ $index -le 2 ]] || forbidden extra-count
    builtin printf '%s\n' "$index" > "$TEST_ROOT/count-stage"
    record count "$index" "$@"
    if [[ ( $index == 1 && $FAULT == objects-* ) || ( $index == 2 && $FAULT == targets-* ) ]]; then
        case "$FAULT" in
            *-1) return 1 ;;
            *-43) return 43 ;;
            *-127) return 127 ;;
            *-partial) builtin printf '42\n'; return 43 ;;
            *-zero) builtin printf '0\n'; return 43 ;;
            *-stderr) builtin printf 'supplied ELF count failure\n' >&2; return 43 ;;
        esac
    fi
    builtin command wc "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'initialize_dry_run_runtime', 'configure_logging', 'run_apply_workflow',
          'run_check_workflow', 'run_dry_run_workflow', 'slackpkg', 'sbopkg', 'sqg', 'flatpak',
          'readelf', 'ldd', 'ldconfig', 'git', 'curl', 'wget', 'date', 'regenerate_initrd',
          'update_grub_configuration', 'inspect_current_sbo_queues', 'collect_installed_sbo_targets',
          'collect_installed_sbo_candidates', 'build_sbo_core_queue', 'build_and_apply_sbo_queue',
          'verify_broken_elf_objects_after_rebuild', 'print_json_result', 'emit_final_events')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, available, conditional, seed):
    objects, targets = {
        'empty': ('', ''),
        'objects-only': ('/private/object-one\n/private/object-two\n', ''),
        'mapped': ('/private/object-one\n/private/object-two\n', 'alpha\n'),
    }[profile]
    for name, data in {'objects': 'old-objects\n', 'targets': 'old-targets\n',
                       'sentinel': 'untouched\n', 'count-stage': '0\n'}.items():
        (root / name).write_text(data)
    expected_files = inventory(root)
    old = ['6' if seed else '0', '4' if seed else '0', '9', '8', '7', 'old-error', '5', '3']
    state = old.copy()
    calls = []
    status = 0
    output = '[PLAN] Inspecting current ELF dependency state\n'
    stage = 0
    if not available:
        expected_files['objects'] = expected_files['targets'] = ('file', b'')
        state[:2] = ['0', '0']
        output += '  readelf is unavailable; the current ELF state cannot be inspected\n'
    else:
        calls.append(('detect',))
        state[2:4] = ['0', str(objects.count('\n'))]
        expected_files['objects'] = ('file', objects.encode())
        if fault == 'detect':
            state[2] = '1'
            state[:2] = ['0', '0']
            expected_files['objects'] = expected_files['targets'] = ('file', b'')
            status = 1
        else:
            calls.append(('map',))
            expected_files['targets'] = ('file', targets.encode())
            state[4] = str(targets.count('\n'))
            if fault == 'map':
                status = 1
            else:
                for prefix, name in (('objects', 'objects'), ('targets', 'targets')):
                    if fault == prefix + '-missing': expected_files.pop(name)
                    elif fault == prefix + '-directory': expected_files[name] = ('dir',)
                if fault != 'objects-missing':
                    stage += 1; calls.append(('count', stage, '-l'))
                if fault.startswith('objects-'):
                    status = 1
                    output += '  [ERROR] Cannot count the current broken ELF objects for dry-run\n'
                else:
                    if fault != 'targets-missing':
                        stage += 1; calls.append(('count', stage, '-l'))
                    if fault.startswith('targets-'):
                        status = 1
                        output += '  [ERROR] Cannot count the current broken-ELF SBo targets for dry-run\n'
                    else:
                        state[:2] = [str(objects.count('\n')), str(targets.count('\n'))]
    expected_files['count-stage'] = ('file', (str(stage)+'\n').encode())
    if conditional: calls.append(('rejected' if status else 'accepted',))
    values = dict(zip(FIELDS, old)) | dict(BROKEN=str(root/'objects'), QUEUE_EXTRA=str(root/'targets'),
        PLAN_READELF_AVAILABLE=available, FAULT=fault, OBJECT_BYTES=objects, TARGET_BYTES=targets,
        OBJECT_COUNT=objects.count('\n'), TARGET_COUNT=targets.count('\n'))
    assignments = '\n'.join(name+'='+shlex.quote(str(value)) for name,value in values.items())
    guards = '\n'.join(name+'() { forbidden '+name+'; }' for name in GUARDS)
    script = PREFIX+guards+'\n'+assignments+'\n'
    script += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nbroken_count=outer-objects\nbroken_sbo_count=outer-targets\n"
    if conditional:
        script += 'if inspect_current_elf_state; then raw=0; record accepted; else raw=$?; record rejected; fi\n'
    else:
        script += 'inspect_current_elf_state\nraw=$?\n'
    script += '[[ $saved_ifs == "$IFS" && $outer == kept && $broken_count == outer-objects && $broken_sbo_count == outer-targets ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)
    result = subprocess.run(['bash','--noprofile','--norc','-c',script,'dry-elf-counts-test',str(REFERENCE),str(root)],
                            capture_output=True,cwd=root,timeout=10,
                            env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)))
    wanted = output.encode()+b'\0STATE\0'+str(status).encode()+b'\0'
    wanted += b''.join(value.encode()+b'\0' for value in state)
    if available and fault.endswith('-missing'):
        name = fault.split('-')[0]
        pattern = re.escape(str(REFERENCE))+r': line [1-9][0-9]*: '+re.escape(str(root/name))+r': No such file or directory\n'
        stderr_ok = re.fullmatch(pattern,result.stderr.decode()) is not None
    elif available and fault.endswith('-directory'):
        stderr_ok = re.fullmatch(r'wc: [^\n]*: Is a directory\n',result.stderr.decode()) is not None
    elif available and fault.endswith('-stderr'):
        stderr_ok = result.stderr == b'supplied ELF count failure\n'
    else:
        stderr_ok = result.stderr == b''
    label = (profile,fault,available,conditional,seed)
    if (result.returncode,result.stdout)!=(0,wanted) or not stderr_ok:
        raise AssertionError(f'{label}: wanted {(0,wanted)!r}; got {(result.returncode,result.stdout,result.stderr)!r}')
    actual = (root/'events').read_bytes() if (root/'events').exists() else b''
    wanted_events = b''.join(b''.join(str(value).encode()+b'\0' for value in row)+b'\n' for row in calls)
    if actual != wanted_events: raise AssertionError(f'{label}: ordered command vectors differ')
    if inventory(root) != expected_files: raise AssertionError(f'{label}: complete private inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-dry-elf-counts-') as tmp:
        for values in itertools.product(('empty','objects-only','mapped'),FAULTS,(0,1),(0,1),(0,1)):
            root = Path(tmp)/str(count);root.mkdir()
            scenario(root,*values);count += 1
    print(f'Dry-run ELF planning count tests: {count} scenarios, 0 failures')


if __name__ == '__main__': run()
