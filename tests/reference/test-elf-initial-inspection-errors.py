#!/usr/bin/env python3
"""Reject incomplete initial ELF metadata inspection before result publication."""
from collections import Counter
import itertools
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
PROFILES = ('header-failure', 'incomplete-header', 'dynamic-failure',
            'compatible', 'missing', 'no-needed')
ERROR_PROFILES = frozenset(PROFILES[:3])
FIELDS = ('ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT',
          'ELF_LIBRARY_CACHE_RECORD_COUNT')
HEADER = '  Class: ELF64\n  Data: 2s complement, little endian\n  Machine: supplied-machine\n'
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record cache
    builtin printf 'libpresent.so\tELF64\t2s complement, little endian\tsupplied-machine\t/supplied/library\n' > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C && ( $3 == "$TEST_ROOT/scan/target" || $3 == "$TEST_ROOT/scan/companion" || $3 == "$TEST_ROOT/scan/healthy" ) ]] || forbidden reader-vector
    record "$1:${3##*/}"
    local profile=$PROFILE
    [[ $3 != */companion ]] || profile=missing
    [[ $3 != */healthy ]] || profile=compatible
    if [[ $1 == -h ]]; then
        if [[ $profile == incomplete-header ]]; then
            builtin printf '  Class: ELF64\n  Data: 2s complement, little endian\n'
        else
            builtin printf '%s' "$HEADER"
        fi
        if [[ $profile == header-failure ]]; then
            [[ $DIAGNOSTIC == silent ]] || builtin printf 'supplied header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d ]] || forbidden reader-mode
    case "$profile" in
        no-needed) return 0 ;;
        missing) builtin printf ' 0x1 (NEEDED) Shared library: [libabsent.so]\n' ;;
        *) builtin printf ' 0x1 (NEEDED) Shared library: [libpresent.so]\n' ;;
    esac
    if [[ $profile == dynamic-failure ]]; then
        [[ $DIAGNOSTIC == silent ]] || builtin printf 'supplied dynamic diagnostic\n' >&2
        return 43
    fi
    return 0
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'map_broken_objects_to_sbo_packages', 'slackpkg', 'sbopkg', 'sqg', 'flatpak',
          'ldd', 'ldconfig', 'curl', 'wget', 'git', 'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    """Observe private bytes, modes and link targets; exclude only the named trace."""
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
        result[str(path.relative_to(root))] = value
    return result


def scenario(root, workflow, profile, mixed, diagnostic, healthy):
    scan = root / 'scan'
    scan.mkdir()
    target = scan / 'target'
    target.write_bytes(b'\x7fELFinert authored fixture\n')
    target.chmod(0o700)
    objects = [target]
    if mixed:
        companion = scan / 'companion'
        companion.write_bytes(b'\x7fELFinert companion\n')
        objects.append(companion)
    if healthy:
        tail = scan / 'healthy'
        tail.write_bytes(b'\x7fELFinert healthy fixture\n')
        objects.append(tail)
    paths = {key: root / key.lower() for key in
             ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    prior_list = b'prior published list\n' if workflow == 'scan' else ''.join(str(p)+'\n' for p in objects).encode()
    paths['BROKEN'].write_bytes(prior_list)
    expected_inventory = inventory(root)

    def expect_file(key, data):
        name = str(paths[key].relative_to(root))
        expected_inventory[name] = ('file', 0o600, data)

    cache = b'libpresent.so\tELF64\t2s complement, little endian\tsupplied-machine\t/supplied/library\n'
    expect_file('ELF_LIBRARY_CACHE', cache)
    expect_file('BROKEN_ERRORS', b'')
    failed = profile in ERROR_PROFILES
    retained = []
    if profile == 'missing' or (workflow == 'verify' and failed):
        retained.append(target)
    if mixed:
        retained.append(scan / 'companion')
    value = ''.join(str(p)+'\n' for p in sorted(retained)).encode()
    expect_file('BROKEN_NEW' if workflow == 'scan' else 'STILL_BROKEN', value)
    if not (workflow == 'scan' and failed):
        expect_file('BROKEN', value)
    diagnostics = []
    if failed:
        if diagnostic == 'message' and profile != 'incomplete-header':
            diagnostics.append('supplied '+('header' if profile == 'header-failure' else 'dynamic')+' diagnostic')
        diagnostics.append(('readelf could not inspect ' if workflow == 'scan' else 'readelf could not re-inspect ')+str(target))
    output = ('[8] Detecting broken ELF objects without executing inspected files\n' if workflow == 'scan'
              else '  Verifying rebuilt ELF objects with static inspection...\n')
    if workflow == 'scan' and failed:
        output += '  [ERROR] Cannot enumerate, inspect or sort the static ELF scan results\n'
    if diagnostics:
        output += '  [WARN] Static ELF inspection diagnostics:\n'+''.join('    '+line+'\n' for line in diagnostics)
    raw = int(failed) if workflow == 'scan' else int(bool(retained))
    if workflow == 'scan':
        if failed:
            state = ('1', '8', '7', '1')
        else:
            output += f'  Broken ELF objects detected: {len(retained)}\n'
            state = ('0', '8', str(len(retained)), '1')
    else:
        if retained:
            output += '  [WARN] ELF objects that still have unresolved dependencies:\n'+''.join('    '+str(p)+'\n' for p in sorted(retained))
        else:
            output += '  [OK] All previously broken ELF objects passed static verification\n'
        state = ('9', str(raw), '7', '1')
    values = {**paths, 'PROFILE': profile, 'DIAGNOSTIC': diagnostic, 'HEADER': HEADER,
              'ELF_SCAN_STATUS': 9, 'ELF_VERIFICATION_STATUS': 8, 'BROKEN_COUNT': 7,
              'ELF_LIBRARY_CACHE_RECORD_COUNT': 6, 'inspection_failed': 123}
    assignments = '\n'.join(key+'='+shlex.quote(str(value)) for key, value in values.items())
    guards = '\n'.join(name+'() { forbidden '+name+'; }' for name in GUARDS)
    entry = 'detect_broken_elf_objects' if workflow == 'scan' else 'verify_broken_elf_objects_after_rebuild'
    suffix = '\nELF_SCAN_PATHS=("$TEST_ROOT/scan")\nsaved_ifs=$IFS\nouter=kept\n'+entry+'\nraw=$?\n'
    suffix += '[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 ]] || exit 96\n'
    suffix += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    suffix += '\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)+'\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', PREFIX+guards+'\n'+assignments+suffix,
                             'elf-initial-audit', str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), capture_output=True, timeout=10)
    wanted = output.encode()+b'\0STATE\0'+str(raw).encode()+b'\0'+b''.join(v.encode()+b'\0' for v in state)
    label = (workflow, profile, mixed, diagnostic, healthy)
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b''):
        raise AssertionError(f'{label}: expected {(0, wanted, b"")!r}, got {(result.returncode, result.stdout, result.stderr)!r}')
    calls = ['cache', '-h:target']
    if profile not in ('header-failure', 'incomplete-header'):
        calls.append('-d:target')
    if mixed:
        calls += ['-h:companion', '-d:companion']
    if healthy:
        calls += ['-h:healthy', '-d:healthy']
    actual = (root / 'trace').read_text().splitlines()
    if Counter(actual) != Counter(calls) or actual[0] != 'cache':
        raise AssertionError(f'{label}: callback multiplicity differs: {actual!r}')
    for name in ('target', 'companion', 'healthy'):
        modes = [row for row in actual if row.endswith(':'+name)]
        if modes != [row for row in calls if row.endswith(':'+name)]:
            raise AssertionError(f'{label}: per-object reader order differs')
    if workflow == 'verify' and actual != calls:
        raise AssertionError(f'{label}: ordered verification calls differ')
    if inventory(root) != expected_inventory:
        raise AssertionError(f'{label}: private bytes/modes/links/inventory differ')
    return dict(workflow=workflow, profile=profile, companion=mixed, diagnostic=diagnostic,
                raw_status=raw, scan_status=state[0], verification_status=state[1],
                staged_records=len(retained), prior_publication_preserved=workflow == 'scan' and failed, initial_metadata_error_rejected=workflow == 'scan' and failed, healthy_companion=healthy)


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-initial-errors-') as temporary:
        parent = Path(temporary).resolve()
        for index, args in enumerate(itertools.product(('scan', 'verify'), PROFILES, (False, True), ('silent', 'message'), (False, True))):
            root = parent / str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 96 and sum(row['initial_metadata_error_rejected'] for row in rows) == 24
    print('ELF initial inspection errors: 96 scenarios, 24 rejected initial errors, 24 retained recheck errors, 0 failures')
    return rows


if __name__ == '__main__':
    run()
