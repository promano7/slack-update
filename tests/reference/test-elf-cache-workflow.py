#!/usr/bin/env python3
"""Compose real cache/reader/scan/recheck helpers on private supplied ELF metadata."""
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
PROFILE=$3
FAULT=$4
record() { local IFS=' '; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
/sbin/ldconfig() {
    [[ $# == 1 && $1 == -p ]] || forbidden ldconfig-vector
    record ldconfig -p
    if [[ $FAULT == raw ]]; then
        builtin printf 'supplied cache producer error\n' >&2
        return 43
    fi
    builtin printf ' libok.so (supplied) => %s/libraries/library\n' "$TEST_ROOT"
}
extract_static_elf_identity() {
    [[ $# == 1 && ( $1 == "$TEST_ROOT/libraries/library" || $1 == "$TEST_ROOT/scan/object" ) ]] || forbidden identity-vector
    record identity "$@"
    [[ $1 != "$TEST_ROOT/scan/object" || $PROFILE != error ]] || return 43
    builtin printf 'ELF64\tlittle endian\tX86-64\n'
}
extract_static_elf_needed_libraries() {
    [[ $# == 1 && $1 == "$TEST_ROOT/scan/object" && $PROFILE != error ]] || forbidden needed-vector
    record needed "$@"
    if [[ $PROFILE == healthy ]]; then builtin printf 'libok.so\n'; else builtin printf 'missing.so\n'; fi
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
    [[ $stage -ge 1 && $stage -le 3 ]] || forbidden extra-sort
    builtin printf '%s\n' "$stage" > "$TEST_ROOT/sort-stage"
    record sort "$stage" -u
    builtin command sort "$@" || forbidden real-sort
    [[ $stage != 2 || $FAULT != sort ]] || return 43
}
find() {
    [[ $# == 9 && $1 == "$TEST_ROOT/scan" && $9 == -print0 ]] || forbidden find-vector
    record find "$@"
    builtin command find "$@"
}
rm() {
    [[ $# -ge 3 && $1 == -f && $2 == -- ]] || forbidden rm-vector
    local path
    for path in "${@:3}"; do
        [[ $path == "$TEST_ROOT/cache."* ]] || forbidden rm-path
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
    [[ $FAULT != move ]] || return 43
    builtin command mv "$@"
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden wc-vector
    record wc -l
    if [[ $FAULT == count ]]; then builtin printf '42\n'; return 43; fi
    builtin command wc "$@"
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && ( $3 == "$BROKEN_NEW" || $3 == "$STILL_BROKEN" ) && $4 == "$BROKEN" ]] || forbidden cp-vector
    record cp "$@"
    builtin command cp "$@"
}
'''
FORBIDDEN = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
             'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow', 'readelf', 'ldd',
             'ldconfig', 'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget',
             'regenerate_initrd', 'update_grub_configuration', 'map_broken_objects_to_sbo_packages')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)


def inventory(root):
    return {str(p.relative_to(root)): p.read_bytes() for p in root.rglob('*') if p.is_file() and p.name != 'trace'}


def diagnostic(text):
    return '  [WARN] Static ELF inspection diagnostics:\n    ' + text + '\n'


def scenario(root, entry, profile, fault, old_errors):
    for directory in ('scan', 'libraries'):
        (root / directory).mkdir()
    obj = root / 'scan/object'
    library = root / 'libraries/library'
    for path in (obj, library):
        path.write_bytes(b'\x7fELFprivate fixture\n')
    paths = {name: root / name.lower() for name in ('BROKEN', 'BROKEN_NEW', 'STILL_BROKEN', 'BROKEN_ERRORS')}
    paths['ELF_LIBRARY_CACHE'] = root / 'cache'
    for path in paths.values():
        path.write_text('prior staging\n')
    paths['BROKEN'].write_text(str(obj) + '\n' if entry == 'verify' else 'prior publication\n')
    paths['BROKEN_ERRORS'].write_text(old_errors)
    (root / 'sort-stage').write_text('0\n')
    expected = inventory(root)
    state = [0, 9, 8, 7, 0]  # Raw return, scan status, verification status, count, cache count.
    selected_status = 1 if entry == 'scan' else 2
    state[selected_status] = 0
    result_key = 'broken_new' if entry == 'scan' else 'still_broken'
    expected[result_key] = b''
    expected['broken_errors'] = b''
    output = '[8] Detecting broken ELF objects without executing inspected files\n' if entry == 'scan' else '  Verifying rebuilt ELF objects with static inspection...\n'
    calls = ['mktemp ' + str(root / 'cache.raw.XXXXXX') + ' <RAW>',
             'mktemp ' + str(root / 'cache.XXXXXX') + ' <STAGE>', 'ldconfig -p', 'sort 1 -u']
    cache_bytes = f'libok.so\tELF64\tlittle endian\tX86-64\t{library}\n'.encode()
    if fault == 'raw':
        calls.append('rm <RAW> <STAGE>')
        expected['sort-stage'] = b'1\n'
    else:
        calls += ['sort 2 -u', 'identity ' + str(library)]
        expected['sort-stage'] = b'2\n'
        if fault == 'sort':
            calls.append('rm <RAW> <STAGE>')
        else:
            calls += ['rm <RAW>', 'chmod 600 <STAGE>', 'mv -f -- <STAGE> ' + str(root / 'cache')]
            if fault == 'move':
                calls.append('rm <STAGE>')
            else:
                calls.append('wc -l')
                expected['cache'] = cache_bytes
    if fault != 'none':
        state[0] = state[selected_status] = 1
        output += '  [ERROR] Cannot build the static ELF library cache\n' if entry == 'scan' else '  [WARN] Cannot refresh the static ELF library cache after the rebuild\n'
        if fault == 'raw':
            output += diagnostic('supplied cache producer error')
    else:
        state[4] = 1
        expected['sort-stage'] = b'3\n'
        if entry == 'scan':
            calls.append('find ' + str(root / 'scan') + ' ( -type f -o -type l ) -print0')
        calls += ['sort 3 -u', 'identity ' + str(obj)]
        if profile != 'error':
            calls.append('needed ' + str(obj))
        if profile == 'error':
            output += diagnostic(('readelf could not inspect ' if entry == 'scan' else 'readelf could not re-inspect ') + str(obj))
        unresolved = (str(obj) + '\n').encode() if profile == 'broken' or (profile == 'error' and entry == 'verify') else b''
        expected[result_key] = unresolved
        if entry == 'scan':
            state[3] = int(bool(unresolved))
            calls += ['wc -l', 'cp -f -- ' + str(paths['BROKEN_NEW']) + ' ' + str(paths['BROKEN'])]
            expected['broken'] = unresolved
            output += f'  Broken ELF objects detected: {state[3]}\n'
        elif unresolved:
            state[0] = state[2] = 1
            calls.append('cp -f -- ' + str(paths['STILL_BROKEN']) + ' ' + str(paths['BROKEN']))
            expected['broken'] = unresolved
            output += '  [WARN] ELF objects that still have unresolved dependencies:\n    ' + str(obj) + '\n'
        else:
            expected['broken'] = b''
            output += '  [OK] All previously broken ELF objects passed static verification\n'
    assignments = '\n'.join(name + '=' + shlex.quote(str(path)) for name, path in paths.items())
    function = 'detect_broken_elf_objects' if entry == 'scan' else 'verify_broken_elf_objects_after_rebuild'
    suffix = r'''
ELF_SCAN_PATHS=("$TEST_ROOT/scan")
ELF_SCAN_STATUS=9
ELF_VERIFICATION_STATUS=8
BROKEN_COUNT=7
ELF_LIBRARY_CACHE_RECORD_COUNT=6
saved_ifs=$IFS
outer=kept
''' + function + r'''
raw=$?
[[ $IFS == "$saved_ifs" && $outer == kept ]] || exit 96
builtin printf '\0STATE\0%s\0%s\0%s\0%s\0%s\0' "$raw" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS" "$BROKEN_COUNT" "$ELF_LIBRARY_CACHE_RECORD_COUNT"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', SHELL + GUARDS + '\n' + assignments + suffix,
                             'elf-cache-workflow-test', str(REFERENCE), str(root), profile, fault], capture_output=True,
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), timeout=10)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in state)
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b''):
        raise AssertionError(f'{entry}/{profile}/{fault}: expected {(0, wanted, b"")!r}, got {(result.returncode, result.stdout, result.stderr)!r}')
    trace = (root / 'trace').read_text()
    trace = re.sub(re.escape(str(root / 'cache.raw.')) + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<RAW>', trace)
    trace = re.sub(re.escape(str(root / 'cache.')) + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<STAGE>', trace)
    actual = trace.splitlines()
    if Counter(actual) != Counter(calls) or actual[:2] != calls[:2]:
        raise AssertionError(f'{entry}/{profile}/{fault}: callback vectors/multiplicity differ: {actual!r} != {calls!r}')
    if fault == 'none':
        if not actual.index('identity ' + str(library)) < actual.index('wc -l') < actual.index('identity ' + str(obj)):
            raise AssertionError(f'{entry}/{profile}/{fault}: cache-before-object phase order differs')
    if inventory(root) != expected:
        raise AssertionError(f'{entry}/{profile}/{fault}: complete private file bytes differ: {inventory(root)!r} != {expected!r}')
    if {str(p.relative_to(root)) for p in root.rglob('*') if p.is_dir()} != {'scan', 'libraries'}:
        raise AssertionError(f'{entry}/{profile}/{fault}: private directory inventory differs')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-cache-workflow-') as temporary:
        for entry, profile, fault, seed in itertools.product(('scan', 'verify'), ('healthy', 'broken', 'error'),
                                                           ('none', 'raw', 'sort', 'move', 'count'), ('', 'prior diagnostic\n')):
            root = Path(temporary).resolve() / str(count)
            root.mkdir()
            scenario(root, entry, profile, fault, seed)
            count += 1
    print(f'ELF cache workflow tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
