#!/usr/bin/env python3
"""Compose real cache/scan/recheck/apply/results with private supplied update leaves."""
from collections import Counter
import importlib.util
import itertools
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
SUPPORT = ROOT / 'tests/reference/test-elf-recheck-apply.py'
spec = importlib.util.spec_from_file_location('apply_fixture', SUPPORT)
APPLY = importlib.util.module_from_spec(spec)
spec.loader.exec_module(APPLY)
FIXTURE = APPLY.fixture
BASE = APPLY.base
FIELDS = APPLY.FIELDS
PREFIX = APPLY.PREFIX
start = PREFIX.index('refresh_static_elf_library_cache() {')
end = PREFIX.index('\nreadelf() {', start)
# Remove only the old supplied cache override; the sourced real cache helper remains.
PREFIX = PREFIX[:start] + PREFIX[end:]
PREFIX += r'''
/sbin/ldconfig() {
    [[ $# == 1 && $1 == -p && $LC_ALL == C ]] || forbidden cache-vector
    inspect_event cache "$REBUILT"
    builtin printf ' libz.so (supplied) => %s\n liba.so (supplied) => %s\n' "$CACHE_COMPANION" "$CACHE_PRIMARY"
}
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C ]] || forbidden reader-vector
    if [[ $3 == "$CACHE_PRIMARY" || $3 == "$CACHE_COMPANION" ]]; then
        [[ $1 == -h ]] || forbidden cache-reader-mode
        inspect_event cache-header "$REBUILT" "${3##*/}"
        builtin printf '%s' "$HEADER"
        return 0
    fi
    [[ $3 == "$OBJECT_PATH" || $3 == "$COMPANION" ]] || forbidden reader-path
    inspect_event readelf "$@" "$LC_ALL" "$REBUILT"
    local profile=missing
    if [[ $3 == "$COMPANION" ]]; then
        profile=compatible
    elif [[ $REBUILT == 1 ]]; then
        case $POST_PROFILE in
            resolved) profile=compatible ;;
            missing) profile=missing ;;
            metadata) profile=header-error ;;
            *) forbidden object-profile ;;
        esac
    fi
    if [[ $1 == -h ]]; then
        builtin printf '%s' "$HEADER"
        if [[ $profile == header-error ]]; then
            builtin printf 'supplied post-build header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d && $profile != header-error ]] || forbidden reader-mode
    if [[ $profile == missing ]]; then builtin printf ' (NEEDED) [libabsent.so]\n'
    else builtin printf ' (NEEDED) [liba.so]\n'; fi
}
printf() {
    if [[ ${FUNCNAME[1]} == refresh_static_elf_library_cache && $# == 4 && $1 == '%s\t%s\t%s\n' ]]; then
        [[ $3 == $'ELF64\tlittle-endian\tsupplied-machine' && ( ( $2 == liba.so && $4 == "$CACHE_PRIMARY" ) || ( $2 == libz.so && $4 == "$CACHE_COMPANION" ) ) ]] || forbidden cache-emission-vector
        local fault=none
        if [[ $4 == "$CACHE_PRIMARY" && ( ( $CACHE_FAULT_PHASE == scan && $REBUILT == 0 ) || ( $CACHE_FAULT_PHASE == recheck && $REBUILT == 1 ) ) ]]; then
            fault=$EMISSION
        fi
        inspect_event cache-emission "$REBUILT" "$2" "$fault"
        [[ $fault != quiet ]] || return 43
        builtin printf "$@"
        [[ $fault != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
'''
GUARDS = APPLY.GUARDS


def scenario(root, phase, emission, post, build, sync):
    for directory in ('objects', 'packages', 'libraries'):
        (root / directory).mkdir()
    obj, companion = root / 'objects/lib[7]+.so', root / 'objects/healthy.so'
    library, cache_companion = root / 'libraries/primary', root / 'libraries/companion'
    for path in (obj, companion, library, cache_companion):
        path.write_bytes(b'\x7fELFinert apply fixture; never executed\n')
        path.chmod(0o600)
    for name, value in {'owner-1.0-x86_64-1_SBo': str(obj) + '\n',
                        'decoy-1.0-x86_64-1_SBo': str(obj) + '-tail\n',
                        'native-1.0-x86_64-1': str(obj) + '\n'}.items():
        (root / 'packages' / name).write_text(value)
    files = {'core': b'stale-core\n', 'extra': b'stale-extra\n', 'options': b'',
             'broken': (str(obj) + '\n').encode(), 'final': b'old-final\n',
             'broken_new': b'prior staging\n', 'still_broken': b'prior verification\n',
             'errors': b'prior diagnostic\n', 'cache': b'prior architecture cache\n'}
    for name, value in files.items():
        (root / name).write_bytes(value)
        (root / name).chmod(0o600)
    expected = FIXTURE.inventory(root)
    def file(name, value):
        expected[name] = ('file', 0o600, value.encode() if isinstance(value, str) else value)
    scan_failed = phase == 'scan' and emission != 'none'
    post_failed = phase == 'recheck' and emission != 'none'
    active = emission != 'none'
    builder = not scan_failed
    broken = scan_failed or post_failed or post != 'resolved'
    verification = -1 if scan_failed else int(post_failed or post != 'resolved')
    sbo_state = 'failed' if scan_failed or build or sync else 'success'
    event_elf = 'failed' if scan_failed else 'warning'
    events = [('queues',), ('scan',)]
    inspected = []
    def cache_calls(number):
        fault = emission if (phase == 'scan' and number == 0) or (phase == 'recheck' and number == 1) else 'none'
        inspected.extend((('cache', number), ('cache-header', number, 'primary'),
                          ('cache-emission', number, 'liba.so', fault),
                          ('cache-header', number, 'companion'), ('cache-emission', number, 'libz.so', 'none')))
    cache_calls(0)
    cache_bytes = f'liba.so\tELF64\tlittle-endian\tsupplied-machine\t{library}\nlibz.so\tELF64\tlittle-endian\tsupplied-machine\t{cache_companion}\n'
    file('core', 'core-b\ncore-a\n')
    file('extra', 'zeta\nabi\n' if scan_failed else 'abi\nowner\nzeta\n')
    file('options', '')
    file('broken_new', '' if scan_failed else str(obj) + '\n')
    file('broken', str(obj) + '\n' if broken else '')
    file('errors', '')
    if not scan_failed:
        file('cache', cache_bytes)
    output = '[8] Detecting broken ELF objects without executing inspected files\n'
    if scan_failed:
        output += '  [ERROR] Cannot build the static ELF library cache\n'
    else:
        inspected.extend((('enumerate', 'first'), ('readelf', '-h', '--', str(obj), 'C', 0),
                          ('readelf', '-d', '--', str(obj), 'C', 0),
                          ('readelf', '-h', '--', str(companion), 'C', 0),
                          ('readelf', '-d', '--', str(companion), 'C', 0)))
        output += '  Broken ELF objects detected: 1\n[9] Mapeando binarios rotos a paquetes SBo\n  Cola extra tras rotos: 3 paquetes\n'
        events.append(('map',))
    events.extend((('action', 'elf', 'scan_dependencies', event_elf,
                   'Static ELF inspection or ownership mapping failed' if scan_failed else 'ELF dependency scan completed', int(scan_failed)),
                   ('module', 'elf', event_elf, 'ELF dependency module completed', 0)))
    if builder:
        file('final', 'core-b\ncore-a\nabi\nowner\nzeta\n')
        file('still_broken', str(obj) + '\n' if not post_failed and post != 'resolved' else '')
        events.append(('builder', '-b', '-B', str(root / 'final')))
        output += '[10] Aplicando cola SBo\n  Total paquetes en cola: 5\n'
        output += ('  [OK] Cola SBo procesada\n' if build == 0 else '  [WARN] sbopkg termino con errores -- revisar log: ' + str(root / 'run.log') + '\n')
        events.append(('recheck',))
        cache_calls(1)
        output += '  Verifying rebuilt ELF objects with static inspection...\n'
        if post_failed:
            output += '  [WARN] Cannot refresh the static ELF library cache after the rebuild\n'
        else:
            inspected.append(('readelf', '-h', '--', str(obj), 'C', 1))
            if post != 'metadata':
                inspected.append(('readelf', '-d', '--', str(obj), 'C', 1))
            else:
                output += '  [WARN] Static ELF inspection diagnostics:\n    supplied post-build header diagnostic\n    readelf could not re-inspect ' + str(obj) + '\n'
            if post == 'resolved':
                output += '  [OK] All previously broken ELF objects passed static verification\n'
            else:
                output += '  [WARN] ELF objects that still have unresolved dependencies:\n    ' + str(obj) + '\n'
    events.extend((('action', 'sbo', 'process_queue', sbo_state,
                    'Final SBo queue processing completed' if builder else 'SBo queue processing was blocked because target selection failed', build if builder else 1),
                   ('module', 'sbo', sbo_state, 'SBo update module completed', build if builder else 1),
                   ('boot-callback',), ('summary', 'success', 'disabled', sbo_state, event_elf, 'disabled', 0)))
    errors = []
    if sync:
        errors.append('sbopkg repository synchronization failed with exit code ' + str(sync))
    if scan_failed:
        errors.append('SBo target selection failed: unknown selection failure')
    if builder and build:
        errors.append('sbopkg queue processing failed with exit code ' + str(build))
    if broken:
        errors.append('ELF dependency verification still reports broken objects')
    stable = 2 if errors else 0
    fields = [stable, int(not errors), int(bool(errors)), 1, 'none', int(scan_failed), '',
              build if builder else -1, 3 if builder else 2, 5 if builder else 0,
              int(scan_failed), verification, 1 if builder else 7, 0 if active else 2, sync, 0, 2, 0]
    settings = dict(ORDER='first', EMISSION=emission, CACHE_FAULT_PHASE=phase, POST_PROFILE=post,
                    CACHE_PRIMARY=library, CACHE_COMPANION=cache_companion, COMPANION=companion,
                    PROFILE='missing', FAULT='none', SBO_RUN=1, ELF_RUN=1, BUILD_CODE=build,
                    SYNC_CODE=sync, REBUILT=0, OBJECT_PATH=obj, OWNER_ACTIVE=0,
                    PACKAGE_DATABASE=root / 'packages', SBO_PACKAGE_TAG='_SBo', QUEUE_CORE=root / 'core',
                    QUEUE_EXTRA=root / 'extra', QUEUE_FINAL=root / 'final', SBO_OPTION_RECORDS=root / 'options',
                    BROKEN=root / 'broken', BROKEN_NEW=root / 'broken_new', STILL_BROKEN=root / 'still_broken',
                    BROKEN_ERRORS=root / 'errors', ELF_LIBRARY_CACHE=root / 'cache', BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6, HEADER=FIXTURE.HEADER, LOG=root / 'run.log',
                    CONFIG_FILE=root / 'config', PENDING_NEW_CONFIG_FILES=root / 'pending-config',
                    STARTED_AT='2000-01-01T00:00:00Z', FINISHED_AT='2000-01-01T00:00:00Z', OPERATION='apply',
                    FLATPAK_MODE='disabled', SBO_MODE='auto', ELF_MODE='auto', CINNAMON_MODE='disabled',
                    BOOT_MODE='disabled', SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\ninitialize_runtime_state || exit 96\n'
    shell += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in settings.items()) + '\n'
    shell += "ELF_SCAN_PATHS=(\"$TEST_ROOT/objects\")\nIFS='|: '\naction_exit=77; sbo_state=outer-sbo; elf_state=outer-elf\nraw=0\n"
    shell += 'run_apply_workflow || raw=$?\ndetermine_stable_exit_code "$raw"\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    shell += r'''
builtin printf '%s\0' "$IFS" "$action_exit" "$sbo_state" "$elf_state"
builtin printf 'ERRORS\0'; builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0'; builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
builtin printf 'JSON\0'; print_json_result "$STABLE_EXIT_CODE"
[[ $IFS == '|: ' && $action_exit == 77 && $sbo_state == outer-sbo && $elf_state == outer-elf ]] || exit 96
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'cache-apply-emission', str(REFERENCE), str(root)],
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), capture_output=True, timeout=25)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in [0, *fields, '|: ', 77, 'outer-sbo', 'outer-elf'])
    wanted += b'ERRORS\0' + b''.join(value.encode() + b'\0' for value in (errors or [''])) + b'WARNINGS\0\0JSON\0'
    prefix, separator, json_bytes = result.stdout.partition(b'JSON\0')
    trace = (root / 'events').read_bytes()
    inspection = (root / 'inspection.events').read_bytes()
    label = (phase, emission, post, build, sync)
    assert (result.returncode, result.stderr, prefix + separator) == (0, b'', wanted), (label, result, wanted)
    assert trace == BASE.encode(events), (label, trace, BASE.encode(events))
    assert inspection == BASE.encode(inspected), (label, inspection, BASE.encode(inspected))
    data = json.loads(json_bytes)
    root_expected = dict(schema_version=0, schema_status='provisional', operation='apply', success=not errors,
                         partial=bool(errors), reboot='none', boot_safe=True, exit_code=stable,
                         exit_code_stable=True, errors=errors, warnings=[])
    assert {key: data[key] for key in root_expected} == root_expected, (label, data, root_expected)
    elf_expected = dict(state='warning' if broken else 'success', scan_exit_code=int(scan_failed),
                        verification_exit_code=verification if builder else None, broken_objects=[str(obj)] if broken else [],
                        library_cache_records=0 if active else 2, executes_inspected_objects=False)
    assert {key: data['modules']['elf'][key] for key in elf_expected} == elf_expected, (label, data)
    sbo_expected = dict(state=sbo_state, sync_exit_code=sync, build_exit_code=build if builder else None,
                        target_selection_exit_code=int(scan_failed), extra_queue_count=3 if builder else 2,
                        submitted_queue_count=5 if builder else 0)
    assert {key: data['modules']['sbo'][key] for key in sbo_expected} == sbo_expected, (label, data)
    assert FIXTURE.inventory(root) == expected, (label, FIXTURE.inventory(root), expected)
    if builder:
        enumerated = (root / 'enumerated').read_bytes().split(b'\0')
        assert enumerated[-1] == b'' and Counter(enumerated[:-1]) == Counter((str(obj).encode(), str(companion).encode()))
    else:
        assert not (root / 'enumerated').exists()
    return dict(phase=phase, emission=emission, post=post, build=build, sync=sync,
                active_cache_refusal=active, initial_cache_block=scan_failed, post_cache_block=post_failed,
                builder_reached=builder, raw_apply=0, stable=stable, errors=errors,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'), stderr=result.stderr.decode(),
                events=trace.decode().replace(str(root), '<ROOT>'), inspection=inspection.decode().replace(str(root), '<ROOT>'))


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-cache-apply-') as temporary:
        for index, case in enumerate(itertools.product(('scan', 'recheck'), ('none', 'quiet', 'late'),
                                                      ('resolved', 'missing', 'metadata'), (0, 43), (0, 43))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir()
            rows.append(scenario(root, *case))
    assert len(rows) == 72 and sum(row['active_cache_refusal'] for row in rows) == 48
    assert sum(row['initial_cache_block'] for row in rows) == sum(row['post_cache_block'] for row in rows) == 24
    assert sum(row['stable'] == 0 for row in rows) == 2 and sum(row['stable'] == 2 for row in rows) == 70
    print('ELF cache apply emission: 72 scenarios, 48 cache refusals, 2 success/70 partial results, 0 failures')
    return rows


if __name__ == '__main__':
    run()
