#!/usr/bin/env python3
"""Reject every selected path-emission failure before recheck list publication."""
import itertools
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
HEADER = ' Class: ELF64\n Data: little-endian\n Machine: supplied-machine\n'
CACHE = b'libpresent.so\tELF64\tlittle-endian\tsupplied-machine\t/supplied/library\n'
FIELDS = ('ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT',
          'ELF_LIBRARY_CACHE_RECORD_COUNT')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\n' "$1" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record cache
    builtin printf '%s' "$CACHE_TEXT" > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C && ( $3 == "$PRIMARY" || $3 == "$COMPANION" ) ]] || forbidden reader-vector
    record "readelf:$1:${3##*/}"
    local profile=$PRIMARY_PROFILE
    [[ $3 != "$COMPANION" ]] || profile=$COMPANION_PROFILE
    if [[ $1 == -h ]]; then
        builtin printf '%s' "$HEADER"
        if [[ $profile == metadata ]]; then
            builtin printf 'supplied primary header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d ]] || forbidden reader-mode
    if [[ $profile == healthy ]]; then builtin printf ' (NEEDED) [libpresent.so]\n'
    else builtin printf ' (NEEDED) [libabsent.so]\n'; fi
}
printf() {
    if [[ ${FUNCNAME[1]} == verify_broken_elf_objects_after_rebuild && $# == 2 && $1 == '%s\n' && ( $2 == "$PRIMARY" || $2 == "$COMPANION" ) ]]; then
        local fault=none
        [[ $2 != "$PRIMARY" ]] || fault=$EMISSION
        record "emit:${2##*/}:$fault"
        [[ $fault != quiet ]] || return 43
        builtin printf "$@"
        [[ $fault != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
sort() {
    [[ $# == 1 && $1 == -u && $LC_ALL == C ]] || forbidden sort-vector
    case ${FUNCNAME[1]} in
        verify_broken_elf_objects_after_rebuild) record sort ;;
        extract_static_elf_needed_libraries) record needed-sort ;;
        *) forbidden sort-caller ;;
    esac
    builtin command sort "$@"
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$STILL_BROKEN" && $4 == "$BROKEN" ]] || forbidden copy-vector
    record copy
    builtin command cp "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime',
          'load_configuration', 'run_apply_workflow', 'run_check_workflow',
          'run_dry_run_workflow', 'detect_broken_elf_objects',
          'map_broken_objects_to_sbo_packages', 'slackpkg', 'sbopkg', 'sqg',
          'flatpak', 'ldd', 'ldconfig', 'git', 'curl', 'wget', 'find', 'wc',
          'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path == root / 'trace':
            continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink():
            value = ('link', mode, os.readlink(path))
        elif path.is_dir():
            value = ('directory', mode)
        else:
            value = ('file', mode, path.read_bytes())
        result[path.relative_to(root).as_posix()] = value
    return result


def scenario(root, primary_profile, order, companion_profile, emission, newline):
    scan = root / 'scan'
    scan.mkdir()
    primary, companion = scan / 'primary', scan / 'companion'
    primary.write_bytes(b'not ELF\n' if primary_profile == 'resolver' else b'\x7fELFinert fixture\n')
    primary.chmod(0o600)
    if companion_profile != 'absent':
        companion.write_bytes(b'\x7fELFinert fixture\n')
        companion.chmod(0o600)
    paths = {key: root / key.lower() for key in
             ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    ordered = [primary, companion] if order == 'first' else [companion, primary]
    prior = '\n'.join(map(str, ordered)) + ('\n' if newline else '')
    paths['BROKEN'].write_text(prior)
    expected = inventory(root)

    def file(key, value):
        expected[paths[key].name] = ('file', 0o600, value.encode() if isinstance(value, str) else value)

    staged = ([] if emission == 'quiet' else [primary])
    if companion_profile == 'missing':
        staged.append(companion)
    staged_text = ''.join(str(path) + '\n' for path in sorted(staged))
    pipeline_rejected = emission != 'none'
    raw = int(pipeline_rejected or bool(staged))
    output = '  Verifying rebuilt ELF objects with static inspection...\n'
    if pipeline_rejected:
        output += '  [WARN] Cannot read, emit or sort the static ELF verification results\n'
    if primary_profile != 'missing':
        output += '  [WARN] Static ELF inspection diagnostics:\n'
        if primary_profile == 'metadata':
            output += '    supplied primary header diagnostic\n    readelf could not re-inspect '
        else:
            output += '    cannot statically re-inspect '
        output += str(primary) + '\n'
    if not pipeline_rejected:
        file('BROKEN', staged_text)
        if staged:
            output += '  [WARN] ELF objects that still have unresolved dependencies:\n'
            output += ''.join('    ' + str(path) + '\n' for path in sorted(staged))
        else:
            output += '  [OK] All previously broken ELF objects passed static verification\n'
    file('ELF_LIBRARY_CACHE', CACHE)
    file('BROKEN_ERRORS', '')
    file('STILL_BROKEN', staged_text)
    primary_calls = [] if primary_profile == 'resolver' else ['readelf:-h:primary']
    if primary_profile == 'missing':
        primary_calls.extend(('readelf:-d:primary', 'needed-sort'))
    primary_calls.append('emit:primary:' + emission)
    companion_calls = [] if companion_profile == 'absent' else ['readelf:-h:companion', 'readelf:-d:companion', 'needed-sort']
    if companion_profile == 'missing':
        companion_calls.append('emit:companion:none')
    calls = ['cache'] + (primary_calls + companion_calls if order == 'first' else companion_calls + primary_calls)
    if not pipeline_rejected and staged:
        calls.append('copy')
    settings = dict(paths, PRIMARY=primary, COMPANION=companion,
                    PRIMARY_PROFILE=primary_profile, COMPANION_PROFILE=companion_profile,
                    EMISSION=emission, HEADER=HEADER, CACHE_TEXT=CACHE.decode(),
                    ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6, inspection_failed=123, emission_failed=456)
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(str(value)) for key, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nverify_broken_elf_objects_after_rebuild\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 && $emission_failed == 456 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'recheck-emission-status',
                             str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=15)
    state = (str(raw), '9', str(raw), '7', '1')
    wanted = output.encode() + b'\0STATE\0' + b''.join(value.encode() + b'\0' for value in state)
    trace = (root / 'trace').read_text().splitlines()
    # Pipeline children run concurrently: sort can be logged before its producer.
    assert trace.count('sort') == 1, trace
    ordered_trace = [value for value in trace if value not in ('sort', 'needed-sort')]
    assert trace.count('needed-sort') == calls.count('needed-sort'), trace
    calls = [value for value in calls if value != 'needed-sort']
    label = (primary_profile, order, companion_profile, emission, newline)
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b'') or ordered_trace != calls:
        raise AssertionError(dict(case=label, status=result.returncode, stdout=result.stdout,
                                  expected_stdout=wanted, stderr=result.stderr, trace=trace,
                                  expected_ordered_trace=calls))
    if inventory(root) != expected:
        raise AssertionError(f'{label}: private bytes/modes/links/inventory differ')
    return dict(primary_profile=primary_profile, order=order, companion_profile=companion_profile,
                emission=emission, final_newline=newline, raw_status=raw,
                pipeline_rejected=pipeline_rejected,
                emission_failure_rejected=pipeline_rejected,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'),
                stderr=result.stderr.decode(), trace=[s.replace(str(root), '<ROOT>') for s in trace])


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-recheck-emission-status-') as temporary:
        parent = Path(temporary).resolve()
        for index, args in enumerate(itertools.product(('missing', 'metadata', 'resolver'),
                                                      ('first', 'last'), ('healthy', 'missing', 'absent'),
                                                      ('none', 'quiet', 'late'), (False, True))):
            root = parent / str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 108
    rejected = sum(row['emission_failure_rejected'] for row in rows)
    assert rejected == 72
    print('ELF recheck emission status: 108 scenarios, 72 rejected emission failures, 36 normal controls, 0 failures')
    return rows


if __name__ == '__main__':
    run()
