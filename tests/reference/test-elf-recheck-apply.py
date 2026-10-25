#!/usr/bin/env python3
"""Compose real ELF recheck, apply mapping, messages and selected provisional JSON fields."""
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
spec = importlib.util.spec_from_file_location('initial_emission_fixture', ROOT / 'tests/reference/test-elf-emission-apply.py')
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
base = fixture.base
FIELDS = fixture.FIELDS
PREFIX = fixture.PREFIX + r'''
sbopkg() {
    [[ $# == 3 && $1 == -b && $2 == -B && $3 == "$QUEUE_FINAL" ]] || forbidden builder-vector
    [[ $(builtin command cat -- "$3") == $'core-b\ncore-a\nabi\nowner\nzeta' ]] || forbidden builder-input
    event builder "$@"
    REBUILT=1
    if [[ $POST_PROFILE == resolver ]]; then
        builtin printf 'post-build supplied non-ELF text\n' > "$OBJECT_PATH"
    fi
    return "$BUILD_CODE"
}
readelf() {
    [[ $# == 3 && $2 == -- && ( $3 == "$OBJECT_PATH" || $3 == "$COMPANION" ) && $LC_ALL == C ]] || forbidden reader-vector
    inspect_event readelf "$@" "$LC_ALL" "$REBUILT"
    local profile=missing
    if [[ $3 == "$COMPANION" ]]; then
        profile=compatible
    elif [[ $REBUILT == 1 ]]; then
        case $POST_PROFILE in
            resolved) profile=compatible ;;
            missing) profile=missing ;;
            metadata) profile=header-error ;;
            *) forbidden post-reader-profile ;;
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
    else builtin printf ' (NEEDED) [libpresent.so]\n'; fi
}
printf() {
    if [[ ${FUNCNAME[1]} == real_initial_elf_recheck && $# == 2 && $1 == '%s\n' && $2 == "$OBJECT_PATH" ]]; then
        inspect_event recheck-emission "$EMISSION"
        [[ $EMISSION != quiet ]] || return 43
        builtin printf "$@"
        [[ $EMISSION != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
'''
GUARDS = fixture.GUARDS


def scenario(root, post, emission, sbo, build, sync):
    (root / 'objects').mkdir()
    (root / 'packages').mkdir()
    obj = root / 'objects/lib[7]+.so'
    companion = root / 'objects/healthy.so'
    for path in (obj, companion):
        path.write_bytes(b'\x7fELFinert fixture; never executed\n')
        path.chmod(0o600)
    for name, value in {'owner-1.0-x86_64-1_SBo': str(obj) + '\n',
                        'decoy-1.0-x86_64-1_SBo': str(obj) + '-tail\n',
                        'native-1.0-x86_64-1': str(obj) + '\n'}.items():
        (root / 'packages' / name).write_text(value)
    files = {'core': b'stale-core\n', 'extra': b'stale-extra\n', 'options': b'',
             'broken': b'prior unrelated list\n', 'final': b'old-final\n',
             'broken_new': b'prior staging\n', 'still_broken': b'prior verification\n',
             'errors': b'prior diagnostic\n', 'cache': b'prior cache\n'}
    for name, value in files.items():
        (root / name).write_bytes(value)
        (root / name).chmod(0o600)
    expected = fixture.inventory(root)

    def file(name, value):
        expected[name] = ('file', 0o600, value.encode() if isinstance(value, str) else value)

    events = [('queues',)] if sbo else []
    file('core', 'core-b\ncore-a\n' if sbo else '')
    file('extra', 'abi\nowner\nzeta\n' if sbo else 'owner\n')
    file('options', '')
    file('broken_new', str(obj) + '\n')
    file('broken', str(obj) + '\n')
    file('errors', '')
    file('cache', fixture.CACHE)
    events.extend((('scan',), ('map',)))
    output = '[8] Detecting broken ELF objects without executing inspected files\n'
    output += '  Broken ELF objects detected: 1\n[9] Mapeando binarios rotos a paquetes SBo\n'
    output += '  Cola extra tras rotos: ' + ('3' if sbo else '1') + ' paquetes\n'
    inspected = [('cache', 0), ('enumerate', 'first'),
                 ('readelf', '-h', '--', str(obj), 'C', 0),
                 ('readelf', '-d', '--', str(obj), 'C', 0),
                 ('readelf', '-h', '--', str(companion), 'C', 0),
                 ('readelf', '-d', '--', str(companion), 'C', 0)]
    events.extend((('action', 'elf', 'scan_dependencies', 'warning', 'ELF dependency scan completed', 0),
                   ('module', 'elf', 'warning', 'ELF dependency module completed', 0)))
    recheck_failed = bool(sbo and post != 'resolved')
    emission_refused = bool(recheck_failed and emission != 'none')
    broken = not sbo or post != 'resolved'
    if sbo:
        file('final', 'core-b\ncore-a\nabi\nowner\nzeta\n')
        events.append(('builder', '-b', '-B', str(root / 'final')))
        output += '[10] Aplicando cola SBo\n  Total paquetes en cola: 5\n'
        output += ('  [OK] Cola SBo procesada\n' if build == 0 else
                   '  [WARN] sbopkg termino con errores -- revisar log: ' + str(root / 'run.log') + '\n')
        events.append(('recheck',))
        inspected.append(('cache', 1))
        output += '  Verifying rebuilt ELF objects with static inspection...\n'
        if post != 'resolver':
            inspected.append(('readelf', '-h', '--', str(obj), 'C', 1))
            if post != 'metadata':
                inspected.append(('readelf', '-d', '--', str(obj), 'C', 1))
        else:
            file('objects/lib[7]+.so', 'post-build supplied non-ELF text\n')
        if post != 'resolved':
            inspected.append(('recheck-emission', emission))
        staged = str(obj) + '\n' if post != 'resolved' and emission != 'quiet' else ''
        file('still_broken', staged)
        if emission_refused:
            output += '  [WARN] Cannot read, emit or sort the static ELF verification results\n'
        if post in ('metadata', 'resolver'):
            output += '  [WARN] Static ELF inspection diagnostics:\n'
            if post == 'metadata':
                output += '    supplied post-build header diagnostic\n    readelf could not re-inspect ' + str(obj) + '\n'
            else:
                output += '    cannot statically re-inspect ' + str(obj) + '\n'
        if not emission_refused:
            if broken:
                output += '  [WARN] ELF objects that still have unresolved dependencies:\n    ' + str(obj) + '\n'
            else:
                output += '  [OK] All previously broken ELF objects passed static verification\n'
                file('broken', '')
    sbo_state = 'failed' if sbo and (build or sync) else 'success' if sbo else 'disabled'
    events.append(('action', 'sbo', 'process_queue', sbo_state,
                   'Final SBo queue processing completed' if sbo else
                   'SBo queue processing was not applicable: supplied-off', build if sbo else 0))
    events.append(('module', 'sbo', sbo_state, 'SBo update module completed', build if sbo else 0))
    events.extend((('boot-callback',), ('summary', 'success', 'disabled', sbo_state, 'warning', 'disabled', 0)))
    errors = []
    if sbo and sync:
        errors.append('sbopkg repository synchronization failed with exit code ' + str(sync))
    if sbo and build:
        errors.append('sbopkg queue processing failed with exit code ' + str(build))
    if broken:
        errors.append('ELF dependency verification still reports broken objects')
    stable = 2 if errors else 0
    fields = [stable, 0 if errors else 1, 1 if errors else 0, 1, 'none',
              0 if sbo else -1, '', build if sbo else -1, 3 if sbo else 1,
              5 if sbo else 0, 0, int(recheck_failed) if sbo else -1,
              1, 1, sync if sbo else -1, 0 if sbo else -1, 2 if sbo else 0, 0]
    settings = dict(ORDER='first', EMISSION=emission, POST_PROFILE=post,
                    COMPANION=companion, PROFILE='missing', FAULT='none',
                    SBO_RUN=sbo, ELF_RUN=1, BUILD_CODE=build, SYNC_CODE=sync, REBUILT=0,
                    OBJECT_PATH=obj, OWNER_ACTIVE=0, PACKAGE_DATABASE=root / 'packages', SBO_PACKAGE_TAG='_SBo',
                    QUEUE_CORE=root / 'core', QUEUE_EXTRA=root / 'extra', QUEUE_FINAL=root / 'final',
                    SBO_OPTION_RECORDS=root / 'options', BROKEN=root / 'broken', BROKEN_NEW=root / 'broken_new',
                    STILL_BROKEN=root / 'still_broken', BROKEN_ERRORS=root / 'errors', ELF_LIBRARY_CACHE=root / 'cache',
                    BROKEN_COUNT=7, ELF_LIBRARY_CACHE_RECORD_COUNT=6, HEADER=fixture.HEADER, CACHE_TEXT=fixture.CACHE.decode(),
                    LOG=root / 'run.log', CONFIG_FILE=root / 'config', PENDING_NEW_CONFIG_FILES=root / 'pending-config',
                    STARTED_AT='2000-01-01T00:00:00Z', FINISHED_AT='2000-01-01T00:00:00Z',
                    OPERATION='apply', FLATPAK_MODE='disabled', SBO_MODE='auto', ELF_MODE='auto',
                    CINNAMON_MODE='disabled', BOOT_MODE='disabled', SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += 'initialize_runtime_state || exit 96\n'
    shell += '\n'.join(key + '=' + shlex.quote(str(value)) for key, value in settings.items()) + '\n'
    shell += "ELF_SCAN_PATHS=(\"$TEST_ROOT/objects\")\nIFS='|: '\naction_exit=77; sbo_state=outer-sbo; elf_state=outer-elf\nraw=0\n"
    shell += 'run_apply_workflow || raw=$?\ndetermine_stable_exit_code "$raw"\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    shell += r'''
builtin printf '%s\0' "$IFS" "$action_exit" "$sbo_state" "$elf_state"
builtin printf 'ERRORS\0'; builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0'; builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
builtin printf 'JSON\0'
print_json_result "$STABLE_EXIT_CODE"
[[ $IFS == '|: ' && $action_exit == 77 && $sbo_state == outer-sbo && $elf_state == outer-elf ]] || exit 96
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'elf-recheck-apply',
                             str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=25)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in
             [0, *fields, '|: ', 77, 'outer-sbo', 'outer-elf'])
    wanted += b'ERRORS\0' + b''.join(value.encode() + b'\0' for value in (errors or [''])) + b'WARNINGS\0\0JSON\0'
    prefix, separator, json_bytes = result.stdout.partition(b'JSON\0')
    trace = (root / 'events').read_bytes()
    inspection = (root / 'inspection.events').read_bytes()
    if result.returncode or result.stderr or prefix + separator != wanted or trace != base.encode(events) or inspection != base.encode(inspected):
        raise AssertionError(dict(case=(post, emission, sbo, build, sync), status=result.returncode,
                                  stdout=result.stdout, expected_prefix=wanted, stderr=result.stderr,
                                  trace=trace, expected_trace=base.encode(events), inspection=inspection,
                                  expected_inspection=base.encode(inspected)))
    data = json.loads(json_bytes)
    expected_root = dict(schema_version=0, schema_status='provisional', operation='apply',
                         success=not errors, partial=bool(errors), reboot='none', boot_safe=True,
                         exit_code=stable, exit_code_stable=True, errors=errors, warnings=[])
    assert {key: data[key] for key in expected_root} == expected_root, (post, emission, sbo, build, sync, data)
    elf_json = data['modules']['elf']
    elf_expected = dict(state='warning' if broken else 'success', scan_exit_code=0,
                        verification_exit_code=int(recheck_failed) if sbo else None,
                        broken_objects=[str(obj)] if broken else [], library_cache_records=1,
                        executes_inspected_objects=False)
    assert {key: elf_json[key] for key in elf_expected} == elf_expected
    sbo_json = data['modules']['sbo']
    sbo_expected = dict(state=sbo_state, sync_exit_code=sync if sbo else None,
                        build_exit_code=build if sbo else None, target_selection_exit_code=0 if sbo else None,
                        extra_queue_count=3 if sbo else 1, submitted_queue_count=5 if sbo else 0)
    assert {key: sbo_json[key] for key in sbo_expected} == sbo_expected
    assert fixture.inventory(root) == expected, (post, emission, sbo, build, sync, 'private inventory mismatch')
    enumerated = (root / 'enumerated').read_bytes().split(b'\0')
    assert enumerated[-1] == b'' and Counter(enumerated[:-1]) == Counter((str(obj).encode(), str(companion).encode()))
    return dict(post=post, emission=emission, sbo=sbo, build=build, sync=sync,
                emission_refused=emission_refused, raw_apply=0, stable=stable,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'), stderr=result.stderr.decode(),
                events=trace.decode().replace(str(root), '<ROOT>'),
                inspection=inspection.decode().replace(str(root), '<ROOT>'))


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-recheck-apply-') as temporary:
        for index, args in enumerate(itertools.product(('resolved', 'missing', 'metadata', 'resolver'),
                                                      ('none', 'quiet', 'late'), (0, 1), (0, 43), (0, 43))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 96 and sum(row['emission_refused'] for row in rows) == 24
    assert sum(row['stable'] == 0 for row in rows) == 3
    assert sum(row['stable'] == 2 for row in rows) == 93
    print('ELF recheck apply: 96 scenarios, 24 emission refusals, 3 success/93 partial results, 0 failures')
    return rows


if __name__ == '__main__':
    run()
