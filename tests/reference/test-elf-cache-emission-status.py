#!/usr/bin/env python3
"""Require cache emission failure refusal while processing all selected private input."""
from collections import Counter
import itertools
import os
from pathlib import Path
import re
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
HEADER = ' Class: ELF64\n Data: little-endian\n Machine: supplied-machine\n'
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { local IFS=' '; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
/sbin/ldconfig() {
    [[ $# == 1 && $1 == -p && $LC_ALL == C ]] || forbidden ldconfig-vector
    record ldconfig -p
    builtin printf '%s' "$RAW_BYTES"
}
readelf() {
    [[ $# == 3 && $1 == -h && $2 == -- && $LC_ALL == C && ( $3 == "$PRIMARY" || $3 == "$COMPANION" ) ]] || forbidden reader-vector
    record identity "${3##*/}"
    builtin printf '%s' "$HEADER"
    if [[ $3 == "$COMPANION" && $PROFILE == identity ]]; then
        builtin printf 'supplied companion identity diagnostic\n' >&2
        return 43
    fi
    return 0
}
printf() {
    if [[ ${FUNCNAME[1]} == refresh_static_elf_library_cache && $# == 4 && $1 == '%s\t%s\t%s\n' ]]; then
        [[ ( $2 == liba.so || $2 == libz.so || $2 == libm.so ) && $3 == $'ELF64\tlittle-endian\tsupplied-machine' && ( $4 == "$PRIMARY" || $4 == "$COMPANION" ) ]] || forbidden emission-vector
        local fault=none
        [[ $4 != "$PRIMARY" ]] || fault=$EMISSION
        record emit "$2" "${4##*/}" "$fault"
        [[ $fault != quiet ]] || return 43
        builtin printf "$@"
        [[ $fault != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
mktemp() {
    [[ $# == 1 && ( $1 == "$TEST_ROOT/cache.raw.XXXXXX" || $1 == "$TEST_ROOT/cache.XXXXXX" ) ]] || forbidden mktemp-vector
    local path
    path=$(builtin command mktemp "$@") || forbidden real-mktemp
    record mktemp "$1" "$path"
    builtin printf '%s\n' "$path"
}
sort() {
    [[ $# == 1 && $1 == -u && $LC_ALL == C ]] || forbidden sort-vector
    record sort -u
    builtin command sort "$@"
}
rm() {
    [[ $# -ge 3 && $1 == -f && $2 == -- ]] || forbidden rm-vector
    local path
    for path in "${@:3}"; do
        [[ $path == "$TEST_ROOT/cache."* && $path != "$TEST_ROOT/cache" ]] || forbidden rm-path
    done
    record rm "${@:3}"
    builtin command rm "$@"
}
chmod() {
    [[ $# == 2 && $1 == 600 && $2 == "$TEST_ROOT/cache."* ]] || forbidden chmod-vector
    record chmod "$@"
    builtin command chmod "$@"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$TEST_ROOT/cache."* && $4 == "$TEST_ROOT/cache" ]] || forbidden mv-vector
    record mv "$@"
    builtin command mv "$@"
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden wc-vector
    record wc -l
    builtin command wc "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime',
          'load_configuration', 'run_apply_workflow', 'run_check_workflow',
          'run_dry_run_workflow', 'detect_broken_elf_objects',
          'verify_broken_elf_objects_after_rebuild', 'map_broken_objects_to_sbo_packages',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'ldd', 'ldconfig', 'git', 'curl',
          'wget', 'find', 'regenerate_initrd', 'update_grub_configuration')


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


def scenario(root, position, profile, emission, old_errors, newline):
    objects = root / 'objects'
    objects.mkdir(mode=0o700)
    primary, companion = objects / 'primary', objects / 'companion'
    primary.write_bytes(b'\x7fELFinert primary fixture\n')
    companion.write_bytes(b'text\n' if profile == 'resolver' else b'\x7fELFinert companion fixture\n')
    for path in (primary, companion):
        path.chmod(0o600)
    cache, errors = root / 'cache', root / 'errors'
    cache.write_bytes(b'prior architecture cache\n')
    errors.write_text(old_errors)
    cache.chmod(0o600)
    errors.chmod(0o600)
    expected = inventory(root)
    soname = 'liba.so' if position == 'first' else 'libz.so'
    rows = sorted([(soname, primary), ('libm.so', companion)])
    raw = 'supplied ldconfig header\n' + '\n'.join(f' {name} (supplied) => {path}' for name, path in rows) + ('\n' if newline else '')
    identity = 'ELF64\tlittle-endian\tsupplied-machine'
    records = []
    calls = [f'mktemp {cache}.raw.XXXXXX <RAW>', f'mktemp {cache}.XXXXXX <STAGE>', 'ldconfig -p']
    diagnostics = old_errors
    for name, path in rows:
        if path == companion and profile == 'resolver':
            diagnostics += f'cannot resolve cached ELF library {name} => {path}\n'
        else:
            calls.append('identity ' + path.name)
            if path == companion and profile == 'identity':
                diagnostics += f'supplied companion identity diagnostic\ncannot read cached ELF identity {name} => {path}\n'
            else:
                fault = emission if path == primary else 'none'
                calls.append(f'emit {name} {path.name} {fault}')
                if fault != 'quiet':
                    records.append(f'{name}\t{identity}\t{path}\n')
    # Any selected failed emission invalidates the complete cache producer.
    pipeline_rejected = emission != 'none'
    status, count = 1, 0
    if pipeline_rejected:
        calls.append('rm <RAW> <STAGE>')
    else:
        calls.append('rm <RAW>')
        if records:
            calls += ['chmod 600 <STAGE>', f'mv -f -- <STAGE> {cache}', 'wc -l']
            expected['cache'] = ('file', 0o600, ''.join(sorted(records)).encode())
            status, count = 0, len(records)
        else:
            diagnostics += 'ldconfig produced no usable architecture-tagged ELF records\n'
            calls.append('rm <STAGE>')
    expected['errors'] = ('file', 0o600, diagnostics.encode())
    settings = dict(PRIMARY=primary, COMPANION=companion, PROFILE=profile,
                    EMISSION=emission, RAW_BYTES=raw, HEADER=HEADER,
                    BROKEN_ERRORS=errors, ELF_LIBRARY_CACHE_RECORD_COUNT=9)
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(str(value)) for key, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nemission_failed=123\nrefresh_static_elf_library_cache \"$TEST_ROOT/cache\"\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0%s\\0" "$raw" "$ELF_LIBRARY_CACHE_RECORD_COUNT"\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell,
                             'cache-emission-status', str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=15)
    wanted = b'\0STATE\0' + str(status).encode() + b'\0' + str(count).encode() + b'\0'
    trace = (root / 'trace').read_text()
    trace = re.sub(re.escape(str(cache) + '.raw.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<RAW>', trace)
    trace = re.sub(re.escape(str(cache) + '.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<STAGE>', trace)
    actual = trace.splitlines()
    ordered = [line for line in actual if line != 'sort -u']
    label = (position, profile, emission, bool(old_errors), newline)
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (label, result, wanted)
    assert Counter(actual)['sort -u'] == 2 and ordered == calls, (label, actual, calls)
    assert inventory(root) == expected, (label, inventory(root), expected)
    return dict(position=position, companion=profile, emission=emission,
                old_errors=bool(old_errors), final_newline=newline,
                raw_status=status, cache_count=count, pipeline_rejected=pipeline_rejected,
                emission_failure_rejected=emission != 'none' and pipeline_rejected,
                prior_cache_preserved=cache.read_bytes() == b'prior architecture cache\n',
                stdout_hex=result.stdout.hex(), stderr=result.stderr.decode(),
                trace=[line.replace(str(root), '<ROOT>') for line in actual],
                cache=cache.read_text().replace(str(root), '<ROOT>'),
                diagnostics=errors.read_text().replace(str(root), '<ROOT>'))


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-cache-emission-status-') as temporary:
        for index, args in enumerate(itertools.product(('first', 'last'),
                                                      ('valid', 'resolver', 'identity'),
                                                      ('none', 'quiet', 'late'),
                                                      ('', 'prior diagnostic\n'), (False, True))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir(mode=0o700)
            rows.append(scenario(root, *args))
    rejected = sum(row['emission_failure_rejected'] for row in rows)
    assert len(rows) == 72 and rejected == 48
    assert all(row['prior_cache_preserved'] and row['cache_count'] == 0 and row['raw_status'] == 1
               for row in rows if row['emission'] != 'none')
    print('ELF cache emission status: 72 scenarios, 48 rejected emission failures, 24 normal controls, 0 failures')
    return rows


if __name__ == '__main__':
    run()
