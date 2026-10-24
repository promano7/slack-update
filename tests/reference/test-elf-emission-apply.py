#!/usr/bin/env python3
"""Compose ordered path-emission failures through real scan, ownership and stable apply results."""
from collections import Counter
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT/'tools/reference/slack-update-reference.sh'
spec = importlib.util.spec_from_file_location('owner_composition_fixture', ROOT/'tests/reference/test-elf-owner-composition.py')
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)
FIELDS = (*base.FIELDS, 'BROKEN_COUNT', 'ELF_LIBRARY_CACHE_RECORD_COUNT', 'SBOPKG_SYNC_STATUS',
          'SQG_SYNC_STATUS', 'TOTAL_CORE', 'SBO_OPTION_RECORD_COUNT')
HEADER = ' Class: ELF64\n Data: little-endian\n Machine: supplied-machine\n'
CACHE = b'libpresent.so\tELF64\tlittle-endian\tsupplied-machine\t/supplied/library\n'
PREFIX = base.PREFIX.replace('source "$1"\n', r'''
source "$1"
eval "$(declare -f detect_broken_elf_objects | sed '1s/detect_broken_elf_objects/real_initial_elf_scan/')"
eval "$(declare -f verify_broken_elf_objects_after_rebuild | sed '1s/verify_broken_elf_objects_after_rebuild/real_initial_elf_recheck/')"
''', 1)
start = PREFIX.index('detect_broken_elf_objects() {')
end = PREFIX.index('\ngrep() {', start)
PREFIX = PREFIX[:start]+r'''
detect_broken_elf_objects() { event scan; real_initial_elf_scan; }
'''+PREFIX[end:]
start = PREFIX.index('verify_broken_elf_objects_after_rebuild() {')
end = PREFIX.index('\nemit_module_started_event()', start)
PREFIX = PREFIX[:start]+r'''
verify_broken_elf_objects_after_rebuild() { event recheck; real_initial_elf_recheck; }
'''+PREFIX[end:]
PREFIX = PREFIX.replace('synchronize_sbo_repository() { SBOPKG_SYNC_STATUS=0; SQG_SYNC_STATUS=0; }',
                        'synchronize_sbo_repository() { SBOPKG_SYNC_STATUS=$SYNC_CODE; SQG_SYNC_STATUS=0; }')
PREFIX = PREFIX.replace('    return "$BUILD_CODE"\n}', '    REBUILT=1\n    return "$BUILD_CODE"\n}', 1)
PREFIX += r'''
inspect_event() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/inspection.events"; builtin printf '\n' >> "$TEST_ROOT/inspection.events"; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    inspect_event cache "$REBUILT"
    builtin printf '%s' "$CACHE_TEXT" > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
readelf() {
    [[ $# == 3 && $2 == -- && ( $3 == "$OBJECT_PATH" || $3 == "$COMPANION" ) && $LC_ALL == C ]] || forbidden reader-vector
    inspect_event readelf "$@" "$LC_ALL" "$REBUILT"
    local profile=$PROFILE
    [[ $3 != "$COMPANION" ]] || profile=compatible
    [[ $profile != missing || $REBUILT != 1 ]] || profile=compatible
    if [[ $1 == -h ]]; then
        if [[ $profile == incomplete-header ]]; then
            builtin printf ' Class: ELF64\n Data: little-endian\n'
        else
            builtin printf '%s' "$HEADER"
        fi
        if [[ $profile == header-error ]]; then
            builtin printf 'supplied header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d ]] || forbidden reader-mode
    [[ $profile != no-needed ]] || return 0
    if [[ $profile == missing ]]; then
        builtin printf ' (NEEDED) [libabsent.so]\n'
    else
        builtin printf ' (NEEDED) [libpresent.so]\n'
    fi
    if [[ $profile == dynamic-error ]]; then
        builtin printf 'supplied dynamic diagnostic\n' >&2
        return 43
    fi
    return 0
}
'''
PREFIX += r'''
find() {
    [[ $# == 9 && $1 == "$TEST_ROOT/objects" && $9 == -print0 ]] || forbidden ordered-find-vector
    inspect_event enumerate "$ORDER"
    builtin command find "$@" > "$TEST_ROOT/enumerated" || forbidden real-find
    local -a observed=()
    mapfile -d '' -t observed < "$TEST_ROOT/enumerated"
    [[ ${#observed[@]} == 2 ]] || forbidden enumeration-count
    [[ ( ${observed[0]} == "$OBJECT_PATH" && ${observed[1]} == "$COMPANION" ) || ( ${observed[1]} == "$OBJECT_PATH" && ${observed[0]} == "$COMPANION" ) ]] || forbidden enumeration-members
    if [[ $ORDER == first ]]; then builtin printf '%s\0' "$OBJECT_PATH" "$COMPANION"
    else builtin printf '%s\0' "$COMPANION" "$OBJECT_PATH"; fi
}
printf() {
    if [[ ${FUNCNAME[1]} == real_initial_elf_scan && $# == 2 && $1 == '%s\n' && $2 == "$OBJECT_PATH" ]]; then
        inspect_event emission "$EMISSION"
        [[ $EMISSION != quiet ]] || return 43
        builtin printf "$@"
        [[ $EMISSION != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
'''
GUARDS = tuple(name for name in base.GUARDS if name != 'readelf')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path in (root/'events', root/'inspection.events', root/'enumerated'):
            continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink(): value = ('link', mode, os.readlink(path))
        elif path.is_dir(): value = ('directory', mode)
        else: value = ('file', mode, path.read_bytes())
        result[path.relative_to(root).as_posix()] = value
    return result


def scenario(root, order, emission, sbo, prior_nonempty, sync):
    profile, elf = 'missing', 1
    (root/'objects').mkdir()
    (root/'packages').mkdir()
    obj = root/'objects/lib[7]+.so'
    obj.write_bytes(b'\x7fELFinert fixture; never executed\n')
    obj.chmod(0o700)
    companion = root/'objects/healthy.so'
    companion.write_bytes(b'\x7fELFinert healthy fixture\n')
    companion.chmod(0o700)
    for name, value in {'owner-1.0-x86_64-1_SBo': str(obj)+'\n',
                        'decoy-1.0-x86_64-1_SBo': str(obj)+'-tail\n',
                        'native-1.0-x86_64-1': str(obj)+'\n'}.items():
        (root/'packages'/name).write_text(value)
    files = {'core': b'stale-core\n', 'extra': b'stale-extra\n', 'options': b'',
             'broken': b'prior unrelated list\n' if prior_nonempty else b'', 'final': b'old-final\n',
             'broken_new': b'prior staging\n', 'still_broken': b'prior verification\n',
             'errors': b'prior diagnostic\n', 'cache': b'prior cache\n'}
    for name, value in files.items():
        (root/name).write_bytes(value)
        (root/name).chmod(0o600)
    expected = inventory(root)
    def file(name, value):
        if isinstance(value, str): value = value.encode()
        expected[name] = ('file', 0o600, value)
    rows = []
    if sbo:
        rows.append(('queues',))
        file('core', 'core-b\ncore-a\n')
        file('extra', 'zeta\nabi\n')
    else:
        file('core', '')
        file('extra', '')
    file('options', '')
    failed = emission != 'none'
    initial_missing = not failed
    builder = bool(sbo and not failed)
    recheck = bool(builder and initial_missing)
    selected_sync = sync if sbo else -1
    errors = []
    if selected_sync > 0: errors.append('sbopkg repository synchronization failed with exit code '+str(sync))
    selection = 1 if failed else 0 if sbo else -1
    extra_count = 2 if sbo else 0
    output = ''
    inspection = []
    broken = 'prior unrelated list\n' if failed and prior_nonempty else str(obj)+'\n' if initial_missing else ''
    scan_status = 1 if failed else 0 if elf else -1
    cache_count = 1 if elf else 6
    broken_count = 7 if failed or not elf else 1 if initial_missing else 0
    if elf:
        rows.append(('scan',))
        output += '[8] Detecting broken ELF objects without executing inspected files\n'
        file('errors', '')
        file('cache', CACHE)
        staged = str(obj)+'\n' if emission != 'quiet' else ''
        file('broken_new', staged)
        primary_calls = [('readelf', '-h', '--', str(obj), 'C', 0), ('readelf', '-d', '--', str(obj), 'C', 0), ('emission', emission)]
        companion_calls = [('readelf', '-h', '--', str(companion), 'C', 0), ('readelf', '-d', '--', str(companion), 'C', 0)]
        inspection += [('cache', 0), ('enumerate', order)]
        inspection += primary_calls+companion_calls if order == 'first' else companion_calls+primary_calls
        if failed:
            output += '  [ERROR] Cannot enumerate, inspect or sort the static ELF scan results\n'
            errors.append('SBo target selection failed: unknown selection failure')
        else:
            file('broken', broken)
            output += '  Broken ELF objects detected: '+str(broken_count)+'\n'
            rows.append(('map',))
            output += '[9] Mapeando binarios rotos a paquetes SBo\n'
            if initial_missing:
                extra_count += 1
                targets = ['abi', 'owner', 'zeta'] if sbo else ['owner']
                file('extra', ''.join(name+'\n' for name in targets))
                output += '  Cola extra tras rotos: '+str(extra_count)+' paquetes\n'
            else: output += '  Sin binarios rotos, nada que anadir\n'
    else: file('broken', '')
    elf_state = 'disabled' if not elf else 'failed' if failed else 'warning' if initial_missing else 'success'
    rows.append(('action', 'elf', 'scan_dependencies', elf_state,
                 'ELF dependency scan was not applicable: supplied-off' if not elf else
                 'Static ELF inspection or ownership mapping failed' if failed else 'ELF dependency scan completed',
                 1 if failed else 0))
    rows.append(('module', 'elf', elf_state, 'ELF dependency module completed', 0))
    total = 0
    if builder:
        extra_names = ['abi', 'owner', 'zeta'] if initial_missing else ['abi', 'zeta']
        final = ['core-b', 'core-a', *extra_names]
        total = len(final)
        file('final', ''.join(name+'\n' for name in final))
        rows.append(('builder', '-b', '-B', str(root/'final')))
        output += '[10] Aplicando cola SBo\n  Total paquetes en cola: '+str(total)+'\n  [OK] Cola SBo procesada\n'
        if recheck:
            rows.append(('recheck',))
            inspection += [('cache', 1), ('readelf', '-h', '--', str(obj), 'C', 1), ('readelf', '-d', '--', str(obj), 'C', 1)]
            output += '  Verifying rebuilt ELF objects with static inspection...\n  [OK] All previously broken ELF objects passed static verification\n'
            file('still_broken', '')
            broken = ''
            file('broken', '')
    sbo_state = 'failed' if failed or (sbo and sync) else 'success' if sbo else 'disabled'
    raw_sbo = 1 if failed else 0
    rows.append(('action', 'sbo', 'process_queue', sbo_state,
                 'Final SBo queue processing completed' if builder else
                 'SBo queue processing was blocked because target selection failed' if sbo else
                 'SBo queue processing was not applicable: supplied-off', raw_sbo if sbo else 0))
    rows.append(('module', 'sbo', sbo_state, 'SBo update module completed', raw_sbo))
    rows += [('boot-callback',), ('summary', 'success', 'disabled', sbo_state, elf_state, 'disabled', 0)]
    if elf and broken: errors.append('ELF dependency verification still reports broken objects')
    fields = [2 if errors else 0, 0 if errors else 1, 1 if errors else 0, 1, 'none',
              selection, '', 0 if builder else -1, extra_count, total, scan_status, 0 if recheck else -1,
              broken_count, cache_count, selected_sync, 0 if sbo else -1, 2 if sbo else 0, 0]
    settings = dict(ORDER=order, EMISSION=emission, COMPANION=str(companion), PROFILE=profile, FAULT='none', SBO_RUN=sbo, ELF_RUN=elf, BUILD_CODE=0, SYNC_CODE=sync,
                    REBUILT=0, OBJECT_PATH=str(obj), OWNER_ACTIVE=0, PACKAGE_DATABASE=str(root/'packages'),
                    SBO_PACKAGE_TAG='_SBo', QUEUE_CORE=str(root/'core'), QUEUE_EXTRA=str(root/'extra'),
                    QUEUE_FINAL=str(root/'final'), SBO_OPTION_RECORDS=str(root/'options'), BROKEN=str(root/'broken'),
                    BROKEN_NEW=str(root/'broken_new'), STILL_BROKEN=str(root/'still_broken'),
                    BROKEN_ERRORS=str(root/'errors'), ELF_LIBRARY_CACHE=str(root/'cache'),
                    BROKEN_COUNT=7, ELF_LIBRARY_CACHE_RECORD_COUNT=6, HEADER=HEADER, CACHE_TEXT=CACHE.decode(),
                    LOG=str(root/'run.log'), OPERATION='apply', FLATPAK_MODE='disabled', SBO_MODE='auto',
                    ELF_MODE='auto', CINNAMON_MODE='disabled', BOOT_MODE='disabled', SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell = PREFIX+'\n'+'\n'.join(name+'() { forbidden '+name+'; }' for name in GUARDS)+'\n'
    shell += 'initialize_runtime_state || exit 96\n'
    shell += '\n'.join(key+'='+shlex.quote(str(value)) for key, value in settings.items())+'\n'
    shell += "ELF_SCAN_PATHS=(\"$TEST_ROOT/objects\")\nIFS='|: '\naction_exit=77; sbo_state=outer-sbo; elf_state=outer-elf\nraw=0\n"
    shell += 'run_apply_workflow || raw=$?\ndetermine_stable_exit_code "$raw"\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)+'\n'
    shell += r'''
builtin printf '%s\0' "$IFS" "$action_exit" "$sbo_state" "$elf_state"
builtin printf 'ERRORS\0'; builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0'; builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'elf-initial-apply', str(REFERENCE), str(root)],
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), capture_output=True, timeout=20)
    wanted = output.encode()+b'\0STATE\0'+b''.join(str(v).encode()+b'\0' for v in [0, *fields, '|: ', 77, 'outer-sbo', 'outer-elf'])
    wanted += b'ERRORS\0'+b''.join(e.encode()+b'\0' for e in (errors or ['']))+b'WARNINGS\0\0'
    trace = (root/'events').read_bytes() if (root/'events').exists() else b''
    inspected = (root/'inspection.events').read_bytes() if (root/'inspection.events').exists() else b''
    if result.returncode or result.stderr or result.stdout != wanted or trace != base.encode(rows) or inspected != base.encode(inspection) or inventory(root) != expected:
        raise AssertionError(dict(profile=profile, sbo=sbo, elf=elf, prior_nonempty=prior_nonempty, sync=sync,
                                  order=order, emission=emission, status=result.returncode, stdout=result.stdout, expected_stdout=wanted,
                                  stderr=result.stderr, trace=trace, expected_trace=base.encode(rows),
                                  inspection=inspected, expected_inspection=base.encode(inspection),
                                  inventory_matches=inventory(root) == expected))

    enumerated = (root/'enumerated').read_bytes().split(b'\0')
    assert enumerated[-1] == b'' and Counter(enumerated[:-1]) == Counter((str(obj).encode(), str(companion).encode()))


def run():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-emission-apply-') as temporary:
        parent = Path(temporary).resolve()
        for args in itertools.product(('first', 'last'), ('none', 'quiet', 'late'), (0, 1), (False, True), (0, 43)):
            root = parent/str(count)
            root.mkdir()
            scenario(root, *args)
            count += 1
    assert count == 48
    print('ELF emission apply: 48 scenarios, 32 rejected emission failures, 16 normal controls, 0 failures')


if __name__ == '__main__': run()
