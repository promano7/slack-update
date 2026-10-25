#!/usr/bin/env python3
"""Check private raw-cache record selection, aliases and active/inactive emission faults."""
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
spec = importlib.util.spec_from_file_location('cache_emission_fixture', SUPPORT)
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
PROFILES = ('primary-first', 'primary-last', 'duplicate-primary', 'alias-same-soname',
            'alias-two-sonames', 'skip-text-companion', 'skip-identity-companion',
            'dangling-candidate', 'missing-candidate', 'only-companion', 'empty', 'all-skipped')


def scenario(root, profile, emission, old_errors, newline):
    objects = root / 'objects'
    objects.mkdir(mode=0o700)
    primary, companion = objects / 'primary', objects / 'companion'
    primary.write_bytes(b'\x7fELFinert primary input fixture\n')
    leaf_profile = 'resolver' if profile in ('skip-text-companion', 'all-skipped') else 'identity' if profile == 'skip-identity-companion' else 'valid'
    companion.write_bytes(b'text\n' if leaf_profile == 'resolver' else b'\x7fELFinert companion input fixture\n')
    for path in (primary, companion):
        path.chmod(0o600)
    alias, missing = objects / 'alias', objects / 'missing'
    if profile in ('alias-same-soname', 'alias-two-sonames'):
        alias.symlink_to('primary')
    elif profile == 'dangling-candidate':
        alias.symlink_to('missing')
    selected = [('liba.so', primary), ('libm.so', companion)]
    if profile == 'primary-last':
        selected = [('libz.so', primary), ('libm.so', companion)]
    elif profile == 'duplicate-primary':
        selected += [('liba.so', primary)]
    elif profile == 'alias-same-soname':
        selected += [('liba.so', alias)]
    elif profile == 'alias-two-sonames':
        selected += [('libz.so', alias)]
    elif profile == 'dangling-candidate':
        selected = [('liba.so', alias), ('libm.so', companion)]
    elif profile == 'missing-candidate':
        selected = [('liba.so', missing), ('libm.so', companion)]
    elif profile in ('only-companion', 'all-skipped'):
        selected = [('libm.so', companion)]
    elif profile == 'empty':
        selected = []
    # Noise is independently selected to fail the raw awk indentation/separator gate.
    raw_lines = ['supplied raw-cache header', f'libignored.so => {objects / "ignored"}',
                 '   indented text without a separator', '', '\t']
    raw_lines += [f' {name} (supplied) => {path}' for name, path in reversed(selected)]
    raw = '\n'.join(raw_lines) + ('\n' if newline else '')
    cache, errors = root / 'cache', root / 'errors'
    cache.write_bytes(b'prior architecture cache\n')
    errors.write_text(old_errors)
    cache.chmod(0o600)
    errors.chmod(0o600)
    expected = BASE.inventory(root)
    identity = 'ELF64\tlittle-endian\tsupplied-machine'
    calls = [f'mktemp {cache}.raw.XXXXXX <RAW>', f'mktemp {cache}.XXXXXX <STAGE>', 'ldconfig -p']
    diagnostics = old_errors
    records = []
    active = False
    primary_emissions = 0
    # Expected raw-sort selection is authored from explicit fixture records, not runtime output.
    for name, candidate in sorted(set(selected)):
        if candidate in (alias, missing) and profile in ('dangling-candidate', 'missing-candidate'):
            diagnostics += f'cannot resolve cached ELF library {name} => {candidate}\n'
            continue
        resolved = primary if candidate == alias else candidate
        if resolved == companion and leaf_profile == 'resolver':
            diagnostics += f'cannot resolve cached ELF library {name} => {candidate}\n'
            continue
        calls.append('identity ' + resolved.name)
        if resolved == companion and leaf_profile == 'identity':
            diagnostics += f'supplied companion identity diagnostic\ncannot read cached ELF identity {name} => {resolved}\n'
            continue
        fault = emission if resolved == primary else 'none'
        if resolved == primary:
            primary_emissions += 1
            active = active or emission != 'none'
        calls.append(f'emit {name} {resolved.name} {fault}')
        if fault != 'quiet':
            records.append(f'{name}\t{identity}\t{resolved}\n')
    status, count = 1, 0
    if active:
        calls.append('rm <RAW> <STAGE>')
    else:
        calls.append('rm <RAW>')
        if records:
            normalized = ''.join(sorted(set(records))).encode()
            calls += ['chmod 600 <STAGE>', f'mv -f -- <STAGE> {cache}', 'wc -l']
            expected['cache'] = ('file', 0o600, normalized)
            status, count = 0, len(set(records))
        else:
            diagnostics += 'ldconfig produced no usable architecture-tagged ELF records\n'
            calls.append('rm <STAGE>')
    expected['errors'] = ('file', 0o600, diagnostics.encode())
    settings = dict(PRIMARY=primary, COMPANION=companion, PROFILE=leaf_profile,
                    EMISSION=emission, RAW_BYTES=raw, HEADER=BASE.HEADER,
                    BROKEN_ERRORS=errors, ELF_LIBRARY_CACHE_RECORD_COUNT=9)
    shell = BASE.PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in BASE.GUARDS) + '\n'
    shell += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nemission_failed=123\nrefresh_static_elf_library_cache \"$TEST_ROOT/cache\"\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0%s\\0" "$raw" "$ELF_LIBRARY_CACHE_RECORD_COUNT"\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'cache-inputs',
                             str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=15)
    wanted = b'\0STATE\0' + str(status).encode() + b'\0' + str(count).encode() + b'\0'
    trace = (root / 'trace').read_text()
    trace = re.sub(re.escape(str(cache) + '.raw.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<RAW>', trace)
    trace = re.sub(re.escape(str(cache) + '.') + r'(?!XXXXXX(?: |\n))[A-Za-z0-9]{6}(?= |\n)', '<STAGE>', trace)
    actual = trace.splitlines()
    ordered = [line for line in actual if line != 'sort -u']
    label = (profile, emission, bool(old_errors), newline)
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (label, result, wanted)
    assert Counter(actual)['sort -u'] == 2 and ordered == calls, (label, actual, calls)
    assert BASE.inventory(root) == expected, (label, BASE.inventory(root), expected)
    return dict(profile=profile, emission=emission, old_errors=bool(old_errors), final_newline=newline,
                active_emission_failure=active, primary_emission_attempts=primary_emissions,
                raw_status=status, cache_count=count, prior_cache_preserved=cache.read_bytes() == b'prior architecture cache\n',
                selected_raw_records=len(set(selected)), stdout_hex=result.stdout.hex(), stderr=result.stderr.decode(),
                raw_input=raw.replace(str(root), '<ROOT>'), cache=cache.read_text().replace(str(root), '<ROOT>'),
                diagnostics=errors.read_text().replace(str(root), '<ROOT>'),
                trace=[line.replace(str(root), '<ROOT>') for line in actual])


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-cache-inputs-') as temporary:
        for index, case in enumerate(itertools.product(PROFILES, ('none', 'quiet', 'late'),
                                                      ('', 'prior diagnostic\n'), (False, True))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir(mode=0o700)
            rows.append(scenario(root, *case))
    active = [row for row in rows if row['active_emission_failure']]
    empty = [row for row in rows if row['profile'] in ('empty', 'all-skipped')]
    successes = [row for row in rows if row['raw_status'] == 0]
    assert (len(rows), len(active), len(empty), len(successes)) == (144, 56, 24, 64)
    assert all(row['raw_status'] == 1 and row['cache_count'] == 0 and row['prior_cache_preserved'] for row in active + empty)
    print('ELF cache inputs: 144 scenarios, 56 active emission refusals, 24 empty-stage refusals, 64 successful controls, 0 failures')
    return rows


if __name__ == '__main__':
    run()
