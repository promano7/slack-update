#!/usr/bin/env python3
"""Characterize earlier path-emission status loss on exact535 source; not a safety pass."""
from collections import Counter
import hashlib
import itertools
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT/'tools/reference/slack-update-reference.sh'
EXPECTED_SOURCE = '162f956c2ac3e01d27934972c53c9073e13024bd93637aa5b20a0a4071de5b65'
HEADER = ' Class: ELF64\n Data: little-endian\n Machine: supplied-machine\n'
CACHE = b'libpresent.so\tELF64\tlittle-endian\tsupplied-machine\t/supplied/library\n'
FIELDS = ('ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT', 'ELF_LIBRARY_CACHE_RECORD_COUNT')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { local IFS=' '; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record cache
    builtin printf '%s' "$CACHE_TEXT" > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
find() {
    [[ $# == 9 && $1 == "$TEST_ROOT/scan" && $2 == '(' && $3 == -type && $4 == f && $5 == -o && $6 == -type && $7 == l && $8 == ')' && $9 == -print0 ]] || forbidden find-vector
    record "find:$ORDER"
    builtin command find "$@" > "$TEST_ROOT/enumerated" || forbidden real-find
    local -a observed=()
    mapfile -d '' -t observed < "$TEST_ROOT/enumerated"
    [[ ${#observed[@]} == 2 ]] || forbidden enumeration-count
    [[ ( ${observed[0]} == "$PRIMARY" && ${observed[1]} == "$COMPANION" ) || ( ${observed[1]} == "$PRIMARY" && ${observed[0]} == "$COMPANION" ) ]] || forbidden enumeration-paths
    if [[ $ORDER == first ]]; then builtin printf '%s\0' "$PRIMARY" "$COMPANION"
    else builtin printf '%s\0' "$COMPANION" "$PRIMARY"; fi
}
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C && ( $3 == "$PRIMARY" || $3 == "$COMPANION" ) ]] || forbidden reader-vector
    record "readelf:$1:${3##*/}"
    local profile=missing
    [[ $3 != "$COMPANION" ]] || profile=$COMPANION_PROFILE
    if [[ $1 == -h ]]; then
        builtin printf '%s' "$HEADER"
        if [[ $profile == error ]]; then
            builtin printf 'supplied companion header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d ]] || forbidden reader-mode
    if [[ $profile == healthy ]]; then builtin printf ' (NEEDED) [libpresent.so]\n'
    else builtin printf ' (NEEDED) [libabsent.so]\n'; fi
}
printf() {
    if [[ ${FUNCNAME[1]} == detect_broken_elf_objects && $# == 2 && $1 == '%s\n' && ( $2 == "$PRIMARY" || $2 == "$COMPANION" ) ]]; then
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
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    record count
    builtin command wc "$@"
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$BROKEN_NEW" && $4 == "$BROKEN" ]] || forbidden copy-vector
    record copy
    builtin command cp "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'verify_broken_elf_objects_after_rebuild', 'map_broken_objects_to_sbo_packages',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'ldd', 'ldconfig', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path in (root/'trace', root/'enumerated'): continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink(): value = ('link', mode, os.readlink(path))
        elif path.is_dir(): value = ('directory', mode)
        else: value = ('file', mode, path.read_bytes())
        result[path.relative_to(root).as_posix()] = value
    return result


def scenario(root, order, companion, emission, prior_empty):
    scan = root/'scan'
    scan.mkdir()
    primary, secondary = scan/'primary', scan/'companion'
    for path in (primary, secondary):
        path.write_bytes(b'\x7fELFinert fixture; never executed\n')
        path.chmod(0o700)
    paths = {key: root/key.lower() for key in ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    paths['BROKEN'].write_bytes(b'' if prior_empty else b'prior published list\n')
    expected = inventory(root)
    def file(name, value):
        if isinstance(value, str): value = value.encode()
        expected[name] = ('file', 0o600, value)
    file('elf_library_cache', CACHE)
    file('broken_errors', '')
    staged = []
    if emission != 'quiet': staged.append(primary)
    if companion == 'missing': staged.append(secondary)
    value = ''.join(str(path)+'\n' for path in sorted(staged))
    file('broken_new', value)
    metadata_error = companion == 'error'
    last_emission_error = order == 'last' and emission != 'none'
    raw = int(metadata_error or last_emission_error)
    masked = order == 'first' and emission != 'none' and not metadata_error
    count = '7' if raw else str(len(staged))
    output = '[8] Detecting broken ELF objects without executing inspected files\n'
    if raw: output += '  [ERROR] Cannot enumerate, inspect or sort the static ELF scan results\n'
    if metadata_error:
        output += '  [WARN] Static ELF inspection diagnostics:\n    supplied companion header diagnostic\n    readelf could not inspect '+str(secondary)+'\n'
    if not raw:
        file('broken', value)
        output += '  Broken ELF objects detected: '+count+'\n'
    calls = ['cache', 'find:'+order]
    primary_calls = ['readelf:-h:primary', 'readelf:-d:primary', 'emit:primary:'+emission]
    secondary_calls = ['readelf:-h:companion']
    if not metadata_error: secondary_calls.append('readelf:-d:companion')
    if companion == 'missing': secondary_calls.append('emit:companion:none')
    calls += primary_calls+secondary_calls if order == 'first' else secondary_calls+primary_calls
    if not raw: calls += ['count', 'copy']
    state = (str(raw), '8', count, '1')
    settings = dict(paths, PRIMARY=str(primary), COMPANION=str(secondary), ORDER=order,
                    COMPANION_PROFILE=companion, EMISSION=emission, HEADER=HEADER,
                    CACHE_TEXT=CACHE.decode(), ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8,
                    BROKEN_COUNT=7, ELF_LIBRARY_CACHE_RECORD_COUNT=6, inspection_failed=123)
    shell = PREFIX+'\n'+'\n'.join(name+'() { forbidden '+name+'; }' for name in GUARDS)+'\n'
    shell += '\n'.join(key+'='+shlex.quote(str(value)) for key, value in settings.items())+'\n'
    shell += "ELF_SCAN_PATHS=(\"$TEST_ROOT/scan\")\nIFS='|: '\nsaved_ifs=$IFS\nouter=kept\ndetect_broken_elf_objects\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 ]] || exit 96\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)+'\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'elf-emission-audit', str(REFERENCE), str(root)],
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), capture_output=True, timeout=15)
    wanted = output.encode()+b'\0STATE\0'+str(raw).encode()+b'\0'+b''.join(v.encode()+b'\0' for v in state)
    label = (order, companion, emission, prior_empty)
    trace = (root/'trace').read_text().splitlines()
    enumerated = (root/'enumerated').read_bytes().split(b'\0')
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b'') or trace != calls:
        raise AssertionError(dict(case=label, status=result.returncode, stdout=result.stdout,
                                  expected_stdout=wanted, stderr=result.stderr, trace=trace, expected_trace=calls))
    if not enumerated or enumerated[-1] != b'' or Counter(enumerated[:-1]) != Counter((str(primary).encode(), str(secondary).encode())):
        raise AssertionError(f'{label}: full real enumeration bytes differ')
    if inventory(root) != expected: raise AssertionError(f'{label}: private bytes/modes/links/inventory differ')
    return dict(order=order, companion=companion, emission=emission, prior_empty=prior_empty,
                raw_status=raw, staged_records=len(staged), earlier_failure_masked=masked)


def run():
    if hashlib.sha256(REFERENCE.read_bytes()).hexdigest() != EXPECTED_SOURCE:
        raise SystemExit('REFUSE ELF EMISSION AUDIT: requires exact historical535 runtime '+EXPECTED_SOURCE)
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-emission-audit-') as temporary:
        parent = Path(temporary).resolve()
        for index, args in enumerate(itertools.product(('first', 'last'), ('healthy', 'missing', 'error'), ('none', 'quiet', 'late'), (False, True))):
            root = parent/str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 36 and sum(row['earlier_failure_masked'] for row in rows) == 8
    print('ELF emission status audit: 36 exact-source observations, 8 masked earlier emission failures, 0 assertion failures; NOT a safety pass')
    return rows


if __name__ == '__main__': run()
