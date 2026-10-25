#!/usr/bin/env python3
"""Compose the real SBo queue coordinator and recheck with private supplied leaves."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
spec = importlib.util.spec_from_file_location('recheck_input_fixture', ROOT / 'tests/reference/test-elf-recheck-inputs.py')
inputs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inputs)
PREFIX = inputs.PREFIX.replace('verify_broken_elf_objects_after_rebuild', 'real_post_build_recheck') + r'''
eval "$(declare -f verify_broken_elf_objects_after_rebuild | builtin command sed '1s/verify_broken_elf_objects_after_rebuild/real_post_build_recheck/')"
verify_broken_elf_objects_after_rebuild() {
    local recheck_status=0
    real_post_build_recheck || recheck_status=$?
    RECHECK_RAW=$recheck_status
    record "recheck:$recheck_status"
    return "$recheck_status"
}
sort() {
    [[ $LC_ALL == C ]] || forbidden sort-locale
    case ${FUNCNAME[1]} in
        normalize_sbo_target_names_from_stream)
            [[ $# == 2 && $1 == -u && $2 == "$TEST_ROOT/"* && -f $2 && ! -L $2 ]] || forbidden merge-sort-path
            record merge-sort
            ;;
        real_post_build_recheck)
            [[ $# == 1 && $1 == -u ]] || forbidden recheck-sort-vector
            record final-sort
            ;;
        extract_static_elf_needed_libraries)
            [[ $# == 1 && $1 == -u ]] || forbidden needed-sort-vector
            record needed-sort
            ;;
        normalize_sbo_option_records_from_stream)
            [[ $# == 0 ]] || forbidden option-sort-vector
            record option-sort
            ;;
        *) forbidden sort-caller ;;
    esac
    builtin command sort "$@"
}
wc() {
    [[ $# == 1 && $1 == -l && ${FUNCNAME[1]} == build_and_apply_sbo_queue ]] || forbidden count-vector
    record count
    builtin command wc "$@"
}
sbopkg() {
    [[ $# == 3 && $1 == -b && $2 == -B && $3 == "$QUEUE_FINAL" ]] || forbidden builder-vector
    [[ $(builtin command cat -- "$3") == $'core-b\ncore-a | DEBUG=yes\nzeta' ]] || forbidden builder-input
    record "builder:$BUILD_CODE"
    return "$BUILD_CODE"
}
'''
GUARDS = tuple(name for name in inputs.GUARDS if name not in ('sbopkg', 'wc'))
FIELDS = ('SBO_BUILD_STATUS', 'TOTAL', 'TOTAL_EN_COLA', 'SBO_TARGET_SELECTION_ERROR',
          'ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT',
          'ELF_LIBRARY_CACHE_RECORD_COUNT', 'RECHECK_RAW')
PROFILES = ('healthy', 'missing', 'metadata', 'resolver', 'empty', 'absent-list',
            'gone', 'duplicates')


def scenario(root, profile, emission, build, queue):
    objects = root / 'objects'
    objects.mkdir()
    for name in ('healthy', 'broken', 'metadata', 'text'):
        path = objects / name
        path.write_bytes(b'non-ELF text\n' if name == 'text' else b'\x7fELFinert fixture\n')
        path.chmod(0o600)
    selected = {'healthy': ['healthy'], 'missing': ['broken'], 'metadata': ['metadata'],
                'resolver': ['text'], 'empty': [], 'absent-list': [], 'gone': ['absent'],
                'duplicates': ['broken', 'healthy', 'broken']}[profile]
    prior = ''.join(str(objects / name) + '\n' for name in selected)
    paths = {key: root / key.lower() for key in
             ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE',
              'QUEUE_CORE', 'QUEUE_EXTRA', 'QUEUE_FINAL', 'SBO_OPTION_RECORDS')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    paths['QUEUE_CORE'].write_text('core-b\ncore-a\n' if queue else '')
    paths['QUEUE_EXTRA'].write_text('zeta\ncore-a\n' if queue else '')
    paths['SBO_OPTION_RECORDS'].write_text('core-a\tDEBUG=yes\n')
    if profile == 'absent-list':
        paths['BROKEN'].unlink()
    else:
        paths['BROKEN'].write_text(prior)
    expected = inputs.inventory(root)

    def file(key, value):
        expected[paths[key].name] = ('file', 0o600, value.encode() if isinstance(value, str) else value)

    final = 'core-b\ncore-a | DEBUG=yes\nzeta\n' if queue else ''
    file('QUEUE_FINAL', final)
    calls = ['merge-sort', 'option-sort', 'count']
    output = '[10] Aplicando cola SBo\n  Total paquetes en cola: ' + ('3' if queue else '0') + '\n'
    recheck = bool(queue and selected)
    emissions = []
    diagnostic = []
    if queue:
        calls.append('builder:' + str(build))
        output += ('  [OK] Cola SBo procesada\n' if build == 0 else
                   '  [WARN] sbopkg termino con errores -- revisar log: ' + str(root / 'run.log') + '\n')
    else:
        output += '  Cola vacia, nada que hacer\n'
    if recheck:
        output += '  Verifying rebuilt ELF objects with static inspection...\n'
        calls.append('cache')
        for name in selected:
            if name == 'absent':
                continue
            if name != 'text':
                calls.append('readelf:-h:' + name)
                if name == 'metadata':
                    diagnostic.append('supplied metadata header diagnostic')
                else:
                    calls.extend(('readelf:-d:' + name, 'needed-sort'))
            if name == 'healthy':
                continue
            calls.append('emit:' + name + ':' + emission)
            path = str(objects / name)
            emissions.append(path)
            if name == 'metadata':
                diagnostic.append('readelf could not re-inspect ' + path)
            elif name == 'text':
                diagnostic.append('cannot statically re-inspect ' + path)
    rejected = bool(emissions) and emission != 'none'
    staged = sorted(set(emissions)) if emission != 'quiet' else []
    staged_text = ''.join(path + '\n' for path in staged)
    verify_raw = int(rejected or bool(staged)) if recheck else 99
    if rejected:
        output += '  [WARN] Cannot read, emit or sort the static ELF verification results\n'
    if diagnostic:
        calls.append('diagnostic-render')
        output += '  [WARN] Static ELF inspection diagnostics:\n'
        output += ''.join('    ' + line + '\n' for line in diagnostic)
    if recheck:
        file('ELF_LIBRARY_CACHE', inputs.CACHE)
        file('BROKEN_ERRORS', '')
        file('STILL_BROKEN', staged_text)
        if not rejected:
            file('BROKEN', staged_text)
            if staged:
                calls.extend(('unresolved-render', 'copy'))
                output += '  [WARN] ELF objects that still have unresolved dependencies:\n'
                output += ''.join('    ' + path + '\n' for path in staged)
            else:
                output += '  [OK] All previously broken ELF objects passed static verification\n'
        calls.append('recheck:' + str(verify_raw))
    state = [build if queue else 17, 3 if queue else 0, 3 if queue else 0, '', 9,
             verify_raw if recheck else 8, 7, 1 if recheck else 6, verify_raw]
    settings = dict(paths, HEADER=inputs.HEADER, CACHE_TEXT=inputs.CACHE.decode(),
                    EMISSION=emission, BUILD_CODE=build, LOG=root / 'run.log',
                    SBO_BUILD_STATUS=17, TOTAL=23, TOTAL_EN_COLA=29, SBO_TARGET_SELECTION_ERROR='',
                    ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6, RECHECK_RAW=99,
                    inspection_failed=123, emission_failed=456, queue_count=777, option_records='caller-option')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(str(value)) for key, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nbuild_and_apply_sbo_queue\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 && $emission_failed == 456 && $queue_count == 777 && $option_records == caller-option ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'elf-recheck-build',
                             str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=20)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in [0, *state])
    trace = (root / 'trace').read_text().splitlines()
    assert trace.count('final-sort') == int(recheck), trace
    assert trace.count('needed-sort') == calls.count('needed-sort'), trace
    ordered = [value for value in trace if value not in ('final-sort', 'needed-sort')]
    wanted_order = [value for value in calls if value != 'needed-sort']
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b'') or ordered != wanted_order:
        raise AssertionError(dict(case=(profile, emission, build, queue), status=result.returncode,
                                  stdout=result.stdout, expected_stdout=wanted, stderr=result.stderr,
                                  trace=trace, expected_ordered_trace=wanted_order))
    assert inputs.inventory(root) == expected, (profile, emission, build, queue, 'private inventory mismatch')
    return dict(profile=profile, emission=emission, build_code=build, queue=queue,
                raw_coordinator=0, raw_recheck=verify_raw, recheck_called=recheck, rejected=rejected,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'), stderr=result.stderr.decode(),
                trace=[value.replace(str(root), '<ROOT>') for value in trace])


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-recheck-build-') as temporary:
        for index, args in enumerate(itertools.product(PROFILES, ('none', 'quiet', 'late'), (0, 43), (False, True))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 96 and sum(row['rejected'] for row in rows) == 16
    assert sum(row['recheck_called'] for row in rows) == 36
    assert sum(row['queue'] for row in rows) == 48
    print('ELF recheck build: 96 scenarios, 16 emission refusals, 36 rechecks, 0 failures')
    return rows


if __name__ == '__main__':
    run()
