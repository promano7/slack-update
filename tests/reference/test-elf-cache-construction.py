#!/usr/bin/env python3
"""Check real private cache construction with supplied ldconfig/identity/fault results."""
from collections import Counter
from pathlib import Path
import itertools
import os
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
SHELL = r'''
source "$1"
TEST_ROOT=$2
FAULT=$3
record() { local IFS=' '; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
/sbin/ldconfig() {
    [[ $# == 1 && $1 == -p ]] || forbidden ldconfig-vector
    record ldconfig -p
    if [[ $FAULT == raw-quiet ]]; then
        builtin printf 'supplied ldconfig error\n' >&2
        return 43
    fi
    builtin printf '%s' "$RAW_BYTES"
    if [[ $FAULT == raw-late ]]; then
        builtin printf 'supplied ldconfig error\n' >&2
        return 43
    fi
    return 0
}
mktemp() {
    [[ $# == 1 && ( $1 == "$TEST_ROOT/cache.raw.XXXXXX" || $1 == "$TEST_ROOT/cache.XXXXXX" ) ]] || forbidden mktemp-vector
    local path
    path=$(builtin command mktemp "$@") || forbidden real-mktemp
    record mktemp "$1" "$path"
    builtin printf '%s\n' "$path"
}
sort() {
    [[ $# == 1 && $1 == -u ]] || forbidden sort-vector
    local stage
    IFS= read -r stage < "$TEST_ROOT/sort-stage" || forbidden stage-read
    stage=$((stage + 1))
    [[ $stage == 1 || $stage == 2 ]] || forbidden extra-sort
    builtin printf '%s\n' "$stage" > "$TEST_ROOT/sort-stage"
    record sort "$stage" "$@"
    if [[ $stage == 2 && $FAULT == final-quiet ]]; then
        local line
        while IFS= read -r line || [[ -n $line ]]; do :; done
        return 43
    fi
    builtin command sort "$@" || forbidden real-sort
    [[ $stage != 2 || $FAULT != final-late ]] || return 43
    return 0
}
extract_static_elf_identity() {
    [[ $# == 1 && $1 == "$TEST_ROOT/objects/"* ]] || forbidden identity-vector
    record identity "$@"
    [[ $1 != */badidentity ]] || return 43
    builtin printf 'ELF64\tlittle endian\tX86-64\n'
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
    [[ $FAULT != mv-quiet ]] || return 43
    if [[ $FAULT == mv-partial ]]; then
        builtin printf 'supplied partial publication\n' > "$4"
        return 43
    fi
    builtin command mv "$@" || forbidden real-mv
    [[ $FAULT != mv-late ]] || return 43
    return 0
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden wc-vector
    record wc "$@"
    [[ $FAULT != wc-quiet ]] || return 43
    if [[ $FAULT == wc-late ]]; then
        builtin printf '42\n'
        return 43
    fi
    builtin command wc "$@"
}
'''
FORBIDDEN = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
             'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
             'detect_broken_elf_objects', 'verify_broken_elf_objects_after_rebuild',
             'readelf', 'ldd', 'ldconfig', 'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'git', 'curl',
             'wget', 'find', 'regenerate_initrd', 'update_grub_configuration')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)
PROFILES = {'valid': [('liba.so', 'good')],
            'duplicates': [('libz.so', 'good'), ('liba.so', 'good'), ('libz.so', 'good')],
            'mixed': [('liba.so', 'good'), ('libbad.so', 'badtext'), ('libid.so', 'badidentity')],
            'empty': [], 'invalid': [('libbad.so', 'badtext'), ('libid.so', 'badidentity')]}


def inventory(root):
    return {str(p.relative_to(root)): p.read_bytes() for p in root.rglob('*') if p.is_file() and p.name != 'trace'}


def scenario(root, profile, fault, old_errors):
    objects = root / 'objects'
    objects.mkdir()
    for name in ('good', 'badidentity', 'badtext'):
        (objects / name).write_bytes(b'text\n' if name == 'badtext' else b'\x7fELFprivate fixture\n')
    (root / 'cache').write_bytes(b'prior cache\n')
    (root / 'errors').write_text(old_errors)
    (root / 'sort-stage').write_text('0\n')
    expected = inventory(root)
    rows = PROFILES[profile]
    raw = 'supplied ldconfig header\n' + ''.join(f' {soname} (supplied) => {objects / name}\n' for soname, name in rows)
    errors = old_errors
    calls = ['mktemp ' + str(root / 'cache.raw.XXXXXX') + ' <RAW>',
             'mktemp ' + str(root / 'cache.XXXXXX') + ' <STAGE>', 'ldconfig -p', 'sort 1 -u']
    failed_raw = fault in ('raw-quiet', 'raw-late')
    failed_final = fault in ('final-quiet', 'final-late')
    status = 1
    count = 0
    expected['sort-stage'] = b'1\n' if failed_raw else b'2\n'
    if failed_raw:
        errors += 'supplied ldconfig error\n'
        calls.append('rm <RAW> <STAGE>')
    else:
        calls.append('sort 2 -u')
        records = []
        for soname, name in sorted(set(rows)):
            if name == 'badtext':
                errors += f'cannot resolve cached ELF library {soname} => {objects / name}\n'
            else:
                calls.append('identity ' + str(objects / name))
                if name == 'badidentity':
                    errors += f'cannot read cached ELF identity {soname} => {objects / name}\n'
                else:
                    records.append(f'{soname}\tELF64\tlittle endian\tX86-64\t{objects / name}\n')
        if failed_final:
            calls.append('rm <RAW> <STAGE>')
        else:
            calls.append('rm <RAW>')
            if records:
                normalized = ''.join(sorted(set(records))).encode()
                calls += ['chmod 600 <STAGE>', 'mv -f -- <STAGE> ' + str(root / 'cache')]
                if fault in ('mv-quiet', 'mv-partial', 'mv-late'):
                    calls.append('rm <STAGE>')
                    if fault == 'mv-partial':
                        expected['cache'] = b'supplied partial publication\n'
                    elif fault == 'mv-late':
                        expected['cache'] = normalized
                else:
                    calls.append('wc -l')
                    expected['cache'] = normalized
                    if fault not in ('wc-quiet', 'wc-late'):
                        status = 0
                        count = len(records)
            else:
                errors += 'ldconfig produced no usable architecture-tagged ELF records\n'
                calls.append('rm <STAGE>')
    expected['errors'] = errors.encode()
    assignments = '\n'.join(name + '=' + shlex.quote(value) for name, value in {
        'RAW_BYTES': raw, 'BROKEN_ERRORS': str(root / 'errors')}.items())
    suffix = r'''
ELF_LIBRARY_CACHE_RECORD_COUNT=9
saved_ifs=$IFS
outer=kept
refresh_static_elf_library_cache "$TEST_ROOT/cache"
raw=$?
[[ $IFS == "$saved_ifs" && $outer == kept ]] || exit 96
builtin printf '\0STATE\0%s\0%s\0' "$raw" "$ELF_LIBRARY_CACHE_RECORD_COUNT"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', SHELL + GUARDS + '\n' + assignments + suffix,
                             'elf-cache-test', str(REFERENCE), str(root), fault], capture_output=True, cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), timeout=10)
    wanted = b'\0STATE\0' + str(status).encode() + b'\0' + str(count).encode() + b'\0'
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b''):
        raise AssertionError(f'{profile}/{fault}: expected {(0, wanted, b"")!r}, got {(result.returncode, result.stdout, result.stderr)!r}')
    trace = (root / 'trace').read_text()
    trace = re.sub(re.escape(str(root / 'cache.raw.')) + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<RAW>', trace)
    trace = re.sub(re.escape(str(root / 'cache.')) + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<STAGE>', trace)
    actual = trace.splitlines()
    if Counter(actual) != Counter(calls):
        raise AssertionError(f'{profile}/{fault}: callback vectors/multiplicity differ: {actual!r} != {calls!r}')
    # Sort producers/consumers can interleave. Only serial phase relationships are asserted.
    if actual[:2] != calls[:2] or actual.index('sort 1 -u') > next((i for i, item in enumerate(actual) if item.startswith('identity ')), len(actual)):
        raise AssertionError(f'{profile}/{fault}: phase order differs')
    publication = 'mv -f -- <STAGE> ' + str(root / 'cache')
    if publication in actual:
        if not actual.index('sort 2 -u') < actual.index('chmod 600 <STAGE>') < actual.index(publication):
            raise AssertionError(f'{profile}/{fault}: publication phase order differs')
        if 'wc -l' in actual and actual.index('wc -l') < actual.index(publication):
            raise AssertionError(f'{profile}/{fault}: count precedes publication')
    if inventory(root) != expected:
        raise AssertionError(f'{profile}/{fault}: complete private file inventory differs: {inventory(root)!r} != {expected!r}')
    if {str(p.relative_to(root)) for p in root.rglob('*') if p.is_dir()} != {'objects'}:
        raise AssertionError(f'{profile}/{fault}: private directory inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-cache-') as temporary:
        faults = ('none', 'raw-quiet', 'raw-late', 'final-quiet', 'final-late',
                  'mv-quiet', 'mv-partial', 'mv-late', 'wc-quiet', 'wc-late')
        for profile, fault, old_errors in itertools.product(PROFILES, faults, ('', 'prior diagnostic\n')):
            root = Path(temporary).resolve() / str(count)
            root.mkdir()
            scenario(root, profile, fault, old_errors)
            count += 1
    print(f'ELF cache construction tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
