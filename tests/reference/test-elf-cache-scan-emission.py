#!/usr/bin/env python3
"""Compose real cache emission refusal with private initial ELF scan and diagnostics."""
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
SUPPORT = ROOT / 'tests/reference/test-elf-cache-emission-status.py'
spec = importlib.util.spec_from_file_location('cache_direct_fixture', SUPPORT)
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
OVERRIDES = r'''
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C ]] || forbidden reader-vector
    if [[ $3 == "$PRIMARY" || $3 == "$COMPANION" ]]; then
        [[ $1 == -h ]] || forbidden library-reader-mode
        record identity "${3##*/}"
        builtin printf '%s' "$HEADER"
        return 0
    fi
    [[ $3 == "$OBJECT" ]] || forbidden reader-path
    record object-reader "$1"
    if [[ $1 == -h ]]; then
        builtin printf '%s' "$HEADER"
        if [[ $OBJECT_PROFILE == metadata ]]; then
            builtin printf 'supplied scan header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d && $OBJECT_PROFILE != metadata ]] || forbidden object-reader-mode
    if [[ $OBJECT_PROFILE == healthy ]]; then
        builtin printf ' (NEEDED) [%s]\n' "$PRIMARY_SONAME"
    else
        builtin printf ' (NEEDED) [libabsent.so]\n'
    fi
}
sort() {
    [[ $# == 1 && $1 == -u && $LC_ALL == C ]] || forbidden sort-vector
    case ${FUNCNAME[1]} in
        refresh_static_elf_library_cache) record cache-sort ;;
        detect_broken_elf_objects) record scan-sort ;;
        extract_static_elf_needed_libraries) record needed-sort ;;
        *) forbidden sort-caller ;;
    esac
    builtin command sort "$@"
}
find() {
    [[ ${FUNCNAME[1]} == detect_broken_elf_objects && $# == 9 && $1 == "$TEST_ROOT/scan" && $2 == '(' && $3 == -type && $4 == f && $5 == -o && $6 == -type && $7 == l && $8 == ')' && $9 == -print0 ]] || forbidden find-vector
    record find
    builtin command find "$@"
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden wc-vector
    case ${FUNCNAME[1]} in
        refresh_static_elf_library_cache) record cache-count ;;
        detect_broken_elf_objects) record scan-count ;;
        *) forbidden wc-caller ;;
    esac
    builtin command wc "$@"
}
cp() {
    [[ ${FUNCNAME[1]} == detect_broken_elf_objects && $# == 4 && $1 == -f && $2 == -- && $3 == "$BROKEN_NEW" && $4 == "$BROKEN" ]] || forbidden copy-vector
    record scan-copy
    builtin command cp "$@"
}
sed() {
    [[ ${FUNCNAME[1]} == report_static_elf_scan_errors && $# == 2 && $1 == 's/^/    /' && $2 == "$BROKEN_ERRORS" ]] || forbidden sed-vector
    record diagnostics
    builtin command sed "$@"
}
'''
LAYOUTS = ('two-valid', 'alias-duplicate', 'skip-text', 'empty')
FIELDS = ('ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT', 'ELF_LIBRARY_CACHE_RECORD_COUNT')


def scenario(root, layout, object_profile, emission, order, prior_newline):
    objects = root / 'objects'
    scan = root / 'scan'
    objects.mkdir(mode=0o700)
    scan.mkdir(mode=0o700)
    primary, companion, obj = objects / 'primary', objects / 'companion', scan / 'object'
    for path in (primary, companion, obj):
        path.write_bytes(b'text\n' if path == companion and layout == 'skip-text' else b'\x7fELFinert scan fixture\n')
        path.chmod(0o600)
    alias = objects / 'alias'
    if layout == 'alias-duplicate':
        alias.symlink_to('primary')
    paths = {name: root / name.lower() for name in ('BROKEN', 'BROKEN_NEW', 'STILL_BROKEN', 'BROKEN_ERRORS')}
    paths['ELF_LIBRARY_CACHE'] = root / 'cache'
    for path in paths.values():
        path.write_bytes(b'prior staging\n')
        path.chmod(0o600)
    prior = 'prior publication' + ('\n' if prior_newline else '')
    paths['BROKEN'].write_text(prior)
    paths['BROKEN_ERRORS'].write_text('prior diagnostic discarded by scan\n')
    paths['ELF_LIBRARY_CACHE'].write_text('prior architecture cache\n')
    expected = BASE.inventory(root)
    expected['broken_new'] = ('file', 0o600, b'')
    expected['broken_errors'] = ('file', 0o600, b'')
    soname = 'liba.so' if order == 'first' else 'libz.so'
    selected = [(soname, primary), ('libm.so', companion)]
    if layout == 'alias-duplicate':
        selected = [(soname, primary), (soname, alias)]
    elif layout == 'empty':
        selected = []
    raw = 'supplied raw-cache header\n' + ''.join(f' {name} (supplied) => {path}\n' for name, path in reversed(selected))
    calls = [f'mktemp {root}/cache.raw.XXXXXX <RAW>', f'mktemp {root}/cache.XXXXXX <STAGE>', 'ldconfig -p']
    diagnostics = ''
    records = []
    for name, candidate in sorted(selected):
        resolved = primary if candidate == alias else candidate
        if resolved == companion and layout == 'skip-text':
            diagnostics += f'cannot resolve cached ELF library {name} => {candidate}\n'
            continue
        calls += ['identity ' + resolved.name, f'emit {name} {resolved.name} ' + (emission if resolved == primary else 'none')]
        if resolved != primary or emission != 'quiet':
            records.append(f'{name}\tELF64\tlittle-endian\tsupplied-machine\t{resolved}\n')
    active = layout != 'empty' and emission != 'none'
    cache_refused = active or layout == 'empty'
    raw_status, scan_status, broken_count, cache_count = 1, 1, 7, 0
    output = '[8] Detecting broken ELF objects without executing inspected files\n'
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
        output += '  [ERROR] Cannot build the static ELF library cache\n'
    else:
        calls += ['find', 'object-reader -h']
        if object_profile == 'metadata':
            diagnostics += f'supplied scan header diagnostic\nreadelf could not inspect {obj}\n'
            output += '  [ERROR] Cannot enumerate, inspect or sort the static ELF scan results\n'
        else:
            calls.append('object-reader -d')
            unresolved = (str(obj) + '\n').encode() if object_profile == 'missing' else b''
            expected['broken_new'] = ('file', 0o600, unresolved)
            expected['broken'] = ('file', 0o600, unresolved)
            raw_status, scan_status, broken_count = 0, 0, int(object_profile == 'missing')
    if diagnostics:
        output += '  [WARN] Static ELF inspection diagnostics:\n' + ''.join('    ' + line + '\n' for line in diagnostics.splitlines())
        calls.append('diagnostics')
    if not cache_refused and object_profile != 'metadata':
        calls += ['scan-count', 'scan-copy']
        output += f'  Broken ELF objects detected: {broken_count}\n'
    settings = dict(paths, PRIMARY=primary, COMPANION=companion, OBJECT=obj,
                    OBJECT_PROFILE=object_profile, PRIMARY_SONAME=soname,
                    PROFILE='valid', EMISSION=emission, RAW_BYTES=raw, HEADER=BASE.HEADER,
                    ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6)
    shell = BASE.PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in BASE.GUARDS if name not in ('detect_broken_elf_objects', 'find')) + '\n' + OVERRIDES
    shell += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in settings.items()) + '\n'
    shell += "ELF_SCAN_PATHS=(\"$TEST_ROOT/scan\")\nIFS='|: '\nsaved_ifs=$IFS\nouter=kept\nemission_failed=123\ninspection_failed=124\ndetect_broken_elf_objects\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $emission_failed == 123 && $inspection_failed == 124 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n' + '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'cache-scan-emission', str(REFERENCE), str(root)],
                            cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), capture_output=True, timeout=15)
    state = (raw_status, scan_status, 8, broken_count, cache_count)
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in state)
    trace = (root / 'trace').read_text()
    trace = re.sub(re.escape(str(root) + '/cache.raw.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<RAW>', trace)
    trace = re.sub(re.escape(str(root) + '/cache.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<STAGE>', trace)
    actual = trace.splitlines()
    sorts = {'cache-sort', 'scan-sort', 'needed-sort'}
    ordered = [line for line in actual if line not in sorts]
    label = (layout, object_profile, emission, order, prior_newline)
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (label, result, wanted)
    assert Counter(actual)['cache-sort'] == 2, (label, actual, calls, result, wanted)
    assert Counter(actual)['scan-sort'] == int(not cache_refused), (label, actual, calls, result, wanted)
    assert Counter(actual)['needed-sort'] == int(not cache_refused and object_profile != 'metadata'), (label, actual, calls, result, wanted)
    assert ordered == calls, (label, actual, calls)
    assert BASE.inventory(root) == expected, (label, BASE.inventory(root), expected)
    return dict(layout=layout, object_profile=object_profile, emission=emission, order=order,
                prior_newline=prior_newline, active_emission_failure=active, cache_refused=cache_refused,
                raw_status=raw_status, scan_status=scan_status, broken_count=broken_count, cache_count=cache_count,
                object_processing_reached=not cache_refused, prior_list_preserved=paths['BROKEN'].read_text() == prior,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'), stderr=result.stderr.decode(),
                trace=[line.replace(str(root), '<ROOT>') for line in actual],
                cache=paths['ELF_LIBRARY_CACHE'].read_text().replace(str(root), '<ROOT>'))


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-cache-scan-') as temporary:
        for index, case in enumerate(itertools.product(LAYOUTS, ('healthy', 'missing', 'metadata'),
                                                      ('none', 'quiet', 'late'), ('first', 'last'), (False, True))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir(mode=0o700)
            rows.append(scenario(root, *case))
    assert len(rows) == 144
    assert sum(row['active_emission_failure'] for row in rows) == 72
    assert sum(row['cache_refused'] for row in rows) == 108
    assert sum(row['object_processing_reached'] for row in rows) == 36
    assert sum(row['raw_status'] == 0 for row in rows) == 24
    assert all(row['raw_status'] == row['scan_status'] == 1 and row['prior_list_preserved'] and row['broken_count'] == 7 and row['cache_count'] == 0 for row in rows if row['cache_refused'])
    print('ELF cache scan emission: 144 scenarios, 72 active emission refusals, 108 cache blocks, 36 object-processing controls, 0 failures')
    return rows


if __name__ == '__main__':
    run()
