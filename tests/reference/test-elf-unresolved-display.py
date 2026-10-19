#!/usr/bin/env python3
"""Check unresolved-list display failure before publication on private ELF fixtures."""
from pathlib import Path
import itertools
import os
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
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/trace"; builtin printf '\n' >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record refresh "$@"
    builtin printf 'supplied cache\n' > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
static_elf_object_has_missing_dependency() {
    [[ $# == 2 && $1 == "$TEST_ROOT/objects/"* && $2 == "$ELF_LIBRARY_CACHE" ]] || forbidden reader-vector
    record dependency "$@"
    case "$1" in
        */healthy) return 1 ;;
        */broken) return 0 ;;
        */error) return 2 ;;
        *) forbidden reader-object ;;
    esac
}
sed() {
    [[ $# == 2 && $1 == 's/^/    /' ]] || forbidden sed-vector
    if [[ $2 == "$BROKEN_ERRORS" ]]; then
        record diagnostic "$@"
        builtin command sed "$@"
        return $?
    fi
    [[ $2 == "$STILL_BROKEN" ]] || forbidden sed-path
    record unresolved "$@"
    [[ $FAULT != quiet ]] || return 43
    builtin command sed "$@" || forbidden real-sed
    [[ $FAULT != late ]] || return 43
    return 0
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$STILL_BROKEN" && $4 == "$BROKEN" ]] || forbidden cp-vector
    record publish "$@"
    builtin command cp "$@"
}
'''
FORBIDDEN = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
             'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow', 'detect_broken_elf_objects',
             'extract_static_elf_identity', 'extract_static_elf_needed_libraries', 'readelf', 'ldd', 'ldconfig',
             'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget', 'find', 'mktemp', 'mv', 'rm',
             'regenerate_initrd', 'update_grub_configuration', 'map_broken_objects_to_sbo_packages')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)


def inventory(root):
    return {str(p.relative_to(root)): p.read_bytes() for p in root.rglob('*') if p.is_file() and p.name != 'trace'}


def scenario(root, profile, fault, old_errors):
    objects = root / 'objects'
    objects.mkdir()
    for name in ('healthy', 'broken', 'error'):
        (objects / name).write_bytes(b'\x7fELFprivate fixture\n')
    paths = {name: root / name.lower() for name in ('BROKEN', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_text('prior staging\n')
    paths['BROKEN_ERRORS'].write_text(old_errors)
    selected = {'broken': ['broken'], 'mixed': ['healthy', 'broken', 'error'],
                'duplicates': ['broken', 'error', 'error', 'broken'], 'no-newline': ['broken'],
                'healthy': ['healthy'], 'empty': [], 'missing-list': []}[profile]
    original = ''.join(str(objects / name) + '\n' for name in selected)
    if profile == 'no-newline':
        original = original.rstrip('\n')
    if profile == 'missing-list':
        paths['BROKEN'].unlink()
    else:
        paths['BROKEN'].write_text(original)
    expected = inventory(root)
    calls = []
    output = ''
    state = [0, 9, 0, 7, 6]  # Raw return, scan status, verification status, prior count, cache count.
    early = profile in ('empty', 'missing-list')
    if not early:
        output = '  Verifying rebuilt ELF objects with static inspection...\n'
        calls.append(('refresh', str(paths['ELF_LIBRARY_CACHE'])))
        expected['elf_library_cache'] = b'supplied cache\n'
        state[4] = 1
        for name in selected:
            calls.append(('dependency', str(objects / name), str(paths['ELF_LIBRARY_CACHE'])))
        errors = ''.join('readelf could not re-inspect ' + str(objects / name) + '\n'
                         for name in selected if name == 'error')
        if errors:
            output += '  [WARN] Static ELF inspection diagnostics:\n'
            output += ''.join('    ' + line for line in errors.splitlines(keepends=True))
            calls.append(('diagnostic', 's/^/    /', str(paths['BROKEN_ERRORS'])))
        expected['broken_errors'] = b''
        unresolved = ''.join(str(objects / name) + '\n' for name in sorted(set(selected) - {'healthy'}))
        expected['still_broken'] = unresolved.encode()
        if unresolved:
            state[0] = state[2] = 1
            output += '  [WARN] ELF objects that still have unresolved dependencies:\n'
            calls.append(('unresolved', 's/^/    /', str(paths['STILL_BROKEN'])))
            if fault != 'quiet':
                output += ''.join('    ' + line for line in unresolved.splitlines(keepends=True))
            if fault == 'none':
                calls.append(('publish', '-f', '--', str(paths['STILL_BROKEN']), str(paths['BROKEN'])))
                expected['broken'] = unresolved.encode()
            else:
                output += '  [WARN] Cannot render the unresolved ELF verification results\n'
        else:
            expected['broken'] = b''
            output += '  [OK] All previously broken ELF objects passed static verification\n'
    assignments = '\n'.join(name + '=' + shlex.quote(str(path)) for name, path in paths.items())
    suffix = r'''
ELF_SCAN_STATUS=9
ELF_VERIFICATION_STATUS=8
BROKEN_COUNT=7
ELF_LIBRARY_CACHE_RECORD_COUNT=6
saved_ifs=$IFS
outer=kept
verify_broken_elf_objects_after_rebuild
raw=$?
[[ $IFS == "$saved_ifs" && $outer == kept ]] || exit 96
builtin printf '\0STATE\0%s\0%s\0%s\0%s\0%s\0' "$raw" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS" "$BROKEN_COUNT" "$ELF_LIBRARY_CACHE_RECORD_COUNT"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', SHELL + GUARDS + '\n' + assignments + suffix,
                             'elf-unresolved-test', str(REFERENCE), str(root), profile, fault],
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=10)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in state)
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b''):
        raise AssertionError(f'{profile}/{fault}: expected {(0, wanted, b"")!r}, got {(result.returncode, result.stdout, result.stderr)!r}')
    trace = (root / 'trace').read_bytes() if (root / 'trace').exists() else b''
    actual = [tuple(value.decode().split('\0')[:-1]) for value in trace.split(b'\n') if value]
    if actual != calls:
        raise AssertionError(f'{profile}/{fault}: callback order/vectors differ: {actual!r} != {calls!r}')
    if inventory(root) != expected:
        raise AssertionError(f'{profile}/{fault}: private file inventory differs')
    if {str(p.relative_to(root)) for p in root.rglob('*') if p.is_dir()} != {'objects'}:
        raise AssertionError(f'{profile}/{fault}: unexpected private directories')


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-unresolved-') as temporary:
        parent = Path(temporary).resolve()
        cases = list(itertools.product(('broken', 'mixed', 'duplicates', 'no-newline'),
                                       ('none', 'quiet', 'late'), ('', 'prior diagnostic\n')))
        cases += list(itertools.product(('healthy', 'empty', 'missing-list'), ('none', 'quiet', 'late'), ('prior diagnostic\n',)))
        for profile, fault, old_errors in cases:
            root = parent / str(count)
            root.mkdir()
            scenario(root, profile, fault, old_errors)
            count += 1
    print(f'ELF unresolved display tests: {count} scenarios, 0 failures')


if __name__ == '__main__':
    run()
