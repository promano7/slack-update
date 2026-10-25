#!/usr/bin/env python3
"""Compose real cache-emission refusal with private post-build static ELF recheck."""
from collections import Counter
import importlib.util
import itertools
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
SUPPORT = ROOT / 'tests/reference/test-elf-cache-scan-emission.py'
spec = importlib.util.spec_from_file_location('cache_scan_fixture', SUPPORT)
SCAN = importlib.util.module_from_spec(spec)
spec.loader.exec_module(SCAN)
BASE = SCAN.BASE
LAYOUTS = SCAN.LAYOUTS
FIELDS = SCAN.FIELDS
OVERRIDES = SCAN.OVERRIDES.replace('detect_broken_elf_objects', 'verify_broken_elf_objects_after_rebuild').replace('scan-sort', 'recheck-sort').replace('scan-copy', 'recheck-copy').replace('$BROKEN_NEW', '$STILL_BROKEN').replace('supplied scan header diagnostic', 'supplied recheck header diagnostic')
OVERRIDES += r'''
find() { forbidden find; }
wc() {
    [[ ${FUNCNAME[1]} == refresh_static_elf_library_cache && $# == 1 && $1 == -l ]] || forbidden wc-vector
    record cache-count
    builtin command wc "$@"
}
sed() {
    [[ $# == 2 && $1 == 's/^/    /' ]] || forbidden sed-vector
    if [[ ${FUNCNAME[1]} == report_static_elf_scan_errors && $2 == "$BROKEN_ERRORS" ]]; then
        record diagnostics
    elif [[ ${FUNCNAME[1]} == verify_broken_elf_objects_after_rebuild && $2 == "$STILL_BROKEN" ]]; then
        record unresolved
    else
        forbidden sed-caller-path
    fi
    builtin command sed "$@"
}
'''


def scenario(root, layout, object_profile, emission, order, prior_newline, input_state='nonempty'):
    objects, scan = root / 'objects', root / 'scan'
    objects.mkdir(mode=0o700)
    scan.mkdir(mode=0o700)
    primary, companion, obj = objects / 'primary', objects / 'companion', scan / 'object'
    for path in (primary, companion, obj):
        path.write_bytes(b'text\n' if path == companion and layout == 'skip-text' else b'\x7fELFinert recheck fixture\n')
        path.chmod(0o600)
    alias = objects / 'alias'
    if layout == 'alias-duplicate':
        alias.symlink_to('primary')
    paths = {name: root / name.lower() for name in ('BROKEN', 'BROKEN_NEW', 'STILL_BROKEN', 'BROKEN_ERRORS')}
    paths['ELF_LIBRARY_CACHE'] = root / 'cache'
    for path in paths.values():
        path.write_bytes(b'prior staging\n')
        path.chmod(0o600)
    prior = str(obj) + ('\n' if prior_newline else '')
    paths['BROKEN'].write_text(prior if input_state == 'nonempty' else '')
    if input_state == 'missing':
        paths['BROKEN'].unlink()
    paths['BROKEN_ERRORS'].write_text('prior diagnostic\n')
    paths['ELF_LIBRARY_CACHE'].write_text('prior architecture cache\n')
    (root / 'trace').write_bytes(b'')
    expected = BASE.inventory(root)
    prior_bytes = paths['BROKEN'].read_bytes() if paths['BROKEN'].exists() else None
    soname = 'liba.so' if order == 'first' else 'libz.so'
    selected = [(soname, primary), ('libm.so', companion)]
    if layout == 'alias-duplicate':
        selected = [(soname, primary), (soname, alias)]
    elif layout == 'empty':
        selected = []
    raw_input = 'supplied raw-cache header\n' + ''.join(f' {name} (supplied) => {path}\n' for name, path in reversed(selected))
    calls, diagnostics, records = [], '', []
    early = input_state != 'nonempty'
    active = not early and layout != 'empty' and emission != 'none'
    cache_refused = not early and (active or layout == 'empty')
    raw_status, verify_status, cache_count = 0, 0, 6
    output = ''
    if not early:
        raw_status, verify_status, cache_count = 1, 1, 0
        output = '  Verifying rebuilt ELF objects with static inspection...\n'
        expected['still_broken'] = ('file', 0o600, b'')
        expected['broken_errors'] = ('file', 0o600, b'')
        calls = [f'mktemp {root}/cache.raw.XXXXXX <RAW>', f'mktemp {root}/cache.XXXXXX <STAGE>', 'ldconfig -p']
        for name, candidate in sorted(selected):
            resolved = primary if candidate == alias else candidate
            if resolved == companion and layout == 'skip-text':
                diagnostics += f'cannot resolve cached ELF library {name} => {candidate}\n'
                continue
            calls += ['identity ' + resolved.name, f'emit {name} {resolved.name} ' + (emission if resolved == primary else 'none')]
            if resolved != primary or emission != 'quiet':
                records.append(f'{name}\tELF64\tlittle-endian\tsupplied-machine\t{resolved}\n')
        if active:
            calls.append('rm <RAW> <STAGE>')
        else:
            calls.append('rm <RAW>')
            if layout == 'empty':
                diagnostics += 'ldconfig produced no usable architecture-tagged ELF records\n'
                calls.append('rm <STAGE>')
            else:
                normalized = ''.join(sorted(set(records))).encode()
                expected['cache'] = ('file', 0o600, normalized)
                cache_count = len(set(records))
                calls += ['chmod 600 <STAGE>', f'mv -f -- <STAGE> {root}/cache', 'cache-count']
        if cache_refused:
            output += '  [WARN] Cannot refresh the static ELF library cache after the rebuild\n'
        else:
            calls.append('object-reader -h')
            if object_profile == 'metadata':
                diagnostics += f'supplied recheck header diagnostic\nreadelf could not re-inspect {obj}\n'
            else:
                calls.append('object-reader -d')
            unresolved = (str(obj) + '\n').encode() if object_profile != 'healthy' else b''
            expected['still_broken'] = ('file', 0o600, unresolved)
            expected['broken'] = ('file', 0o600, unresolved)
            if object_profile == 'healthy':
                raw_status, verify_status = 0, 0
        if diagnostics:
            output += '  [WARN] Static ELF inspection diagnostics:\n' + ''.join('    ' + line + '\n' for line in diagnostics.splitlines())
            calls.append('diagnostics')
        if not cache_refused:
            if object_profile == 'healthy':
                output += '  [OK] All previously broken ELF objects passed static verification\n'
            else:
                output += '  [WARN] ELF objects that still have unresolved dependencies:\n    ' + str(obj) + '\n'
                calls += ['unresolved', 'recheck-copy']
    settings = dict(paths, PRIMARY=primary, COMPANION=companion, OBJECT=obj,
                    OBJECT_PROFILE=object_profile, PRIMARY_SONAME=soname, PROFILE='valid',
                    EMISSION=emission, RAW_BYTES=raw_input, HEADER=BASE.HEADER,
                    ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6)
    shell = BASE.PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in BASE.GUARDS if name != 'verify_broken_elf_objects_after_rebuild') + '\n' + OVERRIDES
    shell += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nemission_failed=123\nverify_broken_elf_objects_after_rebuild\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n' + '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'cache-recheck-emission', str(REFERENCE), str(root)],
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), capture_output=True, timeout=15)
    state = (raw_status, 9, verify_status, 7, cache_count)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in state)
    trace = (root / 'trace').read_text()
    trace = re.sub(re.escape(str(root) + '/cache.raw.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<RAW>', trace)
    trace = re.sub(re.escape(str(root) + '/cache.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<STAGE>', trace)
    actual = trace.splitlines()
    label = (layout, object_profile, emission, order, prior_newline, input_state)
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (label, result, wanted)
    assert Counter(actual)['cache-sort'] == (0 if early else 2), (label, actual, calls, result, wanted)
    assert Counter(actual)['recheck-sort'] == int(not early and not cache_refused), (label, actual, calls, result, wanted)
    assert Counter(actual)['needed-sort'] == int(not early and not cache_refused and object_profile != 'metadata'), (label, actual, calls, result, wanted)
    ordered = [line for line in actual if line not in {'cache-sort', 'recheck-sort', 'needed-sort'}]
    assert ordered == calls, (label, actual, calls)
    assert BASE.inventory(root) == expected, (label, BASE.inventory(root), expected)
    current_bytes = paths['BROKEN'].read_bytes() if paths['BROKEN'].exists() else None
    return dict(layout=layout, object_profile=object_profile, emission=emission, order=order,
                prior_newline=prior_newline, input_state=input_state, early_return=early,
                active_emission_failure=active, cache_refused=cache_refused,
                raw_status=raw_status, scan_status=9, verification_status=verify_status,
                broken_count=7, cache_count=cache_count, object_processing_reached=not early and not cache_refused,
                prior_list_preserved=current_bytes == prior_bytes,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'), stderr=result.stderr.decode(),
                trace=[line.replace(str(root), '<ROOT>') for line in actual],
                cache=paths['ELF_LIBRARY_CACHE'].read_text().replace(str(root), '<ROOT>'))


def cases():
    core = [(*case, 'nonempty') for case in itertools.product(LAYOUTS, ('healthy', 'missing', 'metadata'),
                                                            ('none', 'quiet', 'late'), ('first', 'last'), (False, True))]
    early = [('two-valid', 'healthy', emission, 'first', newline, state)
             for state, emission, newline in itertools.product(('empty', 'missing'), ('none', 'quiet', 'late'), (False, True))]
    return core + early


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-cache-recheck-') as temporary:
        for index, case in enumerate(cases()):
            root = Path(temporary).resolve() / str(index)
            root.mkdir(mode=0o700)
            rows.append(scenario(root, *case))
    assert len(rows) == 156
    assert sum(row['active_emission_failure'] for row in rows) == 72
    assert sum(row['cache_refused'] for row in rows) == 108
    assert sum(row['early_return'] for row in rows) == 12
    assert sum(row['object_processing_reached'] for row in rows) == 36
    assert sum(row['raw_status'] == 0 for row in rows) == 24
    assert all(row['raw_status'] == row['verification_status'] == 1 and row['prior_list_preserved'] and row['cache_count'] == 0 for row in rows if row['cache_refused'])
    print('ELF cache recheck emission: 156 scenarios, 72 active emission refusals, 108 cache blocks, 12 early returns, 0 failures')
    return rows


if __name__ == '__main__':
    run()
