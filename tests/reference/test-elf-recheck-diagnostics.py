#!/usr/bin/env python3
"""Compose sticky recheck emission refusal with diagnostic render/clear failures."""
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
spec = importlib.util.spec_from_file_location('recheck_input_fixture', ROOT / 'tests/reference/test-elf-recheck-inputs.py')
inputs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inputs)
PREFIX = inputs.PREFIX + r'''
sed() {
    [[ $# == 2 && $1 == 's/^/    /' ]] || forbidden sed-vector
    if [[ $2 == "$STILL_BROKEN" ]]; then
        record unresolved-render
        builtin command sed "$@"
        return $?
    fi
    [[ $2 == "$BROKEN_ERRORS" ]] || forbidden sed-path
    record "diagnostic-render:$DIAGNOSTIC_FAULT"
    [[ $DIAGNOSTIC_FAULT != render-quiet ]] || return 43
    builtin command sed "$@" || forbidden real-diagnostic-render
    [[ $DIAGNOSTIC_FAULT != render-late ]] || return 43
    if [[ $DIAGNOSTIC_FAULT == clear-directory || $DIAGNOSTIC_FAULT == clear-link-directory ]]; then
        [[ -f $BROKEN_ERRORS && ! -L $BROKEN_ERRORS && ! -e $TEST_ROOT/saved-diagnostics ]] || forbidden clear-fixture
        record "block-clear:$DIAGNOSTIC_FAULT"
        builtin command mv -- "$BROKEN_ERRORS" "$TEST_ROOT/saved-diagnostics" || forbidden preserve-diagnostics
        local target=$BROKEN_ERRORS
        [[ $DIAGNOSTIC_FAULT != clear-link-directory ]] || target=$TEST_ROOT/diagnostic-target
        builtin command mkdir -m 700 -- "$target" || forbidden make-clear-target
        builtin printf 'diagnostic child sentinel\n' > "$target/keep" || forbidden make-clear-child
        builtin command chmod 600 -- "$target/keep" || forbidden clear-child-mode
        if [[ $DIAGNOSTIC_FAULT == clear-link-directory ]]; then
            builtin command ln -s -- "$target" "$BROKEN_ERRORS" || forbidden link-clear-target
        fi
    fi
    return 0
}
'''
FAULTS = ('none', 'render-quiet', 'render-late', 'clear-directory', 'clear-link-directory')
FIELDS = inputs.FIELDS


def scenario(root, profile, order, emission, diagnostic_fault, newline):
    objects = root / 'objects'
    objects.mkdir()
    primary = objects / ('metadata' if profile == 'metadata' else 'text')
    healthy = objects / 'healthy'
    primary.write_bytes(b'\x7fELFinert fixture\n' if profile == 'metadata' else b'non-ELF text\n')
    healthy.write_bytes(b'\x7fELFinert fixture\n')
    primary.chmod(0o600)
    healthy.chmod(0o600)
    selected = [primary, healthy] if order == 'first' else [healthy, primary]
    prior = '\n'.join(map(str, selected)) + ('\n' if newline else '')
    paths = {key: root / key.lower() for key in
             ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    paths['BROKEN'].write_text(prior)
    expected = inputs.inventory(root)

    def file(key, value):
        expected[paths[key].name] = ('file', 0o600, value.encode() if isinstance(value, str) else value)

    diagnostic = (['supplied metadata header diagnostic', 'readelf could not re-inspect ' + str(primary)]
                  if profile == 'metadata' else ['cannot statically re-inspect ' + str(primary)])
    diagnostic_text = ''.join(line + '\n' for line in diagnostic)
    file('ELF_LIBRARY_CACHE', inputs.CACHE)
    staged = '' if emission == 'quiet' else str(primary) + '\n'
    file('STILL_BROKEN', staged)
    file('BROKEN_ERRORS', '' if diagnostic_fault == 'none' else diagnostic_text)
    rejected_emission = emission != 'none'
    rejected_diagnostic = diagnostic_fault != 'none'
    publication_blocked = rejected_emission or rejected_diagnostic
    output = '  Verifying rebuilt ELF objects with static inspection...\n'
    if rejected_emission:
        output += '  [WARN] Cannot read, emit or sort the static ELF verification results\n'
    output += '  [WARN] Static ELF inspection diagnostics:\n'
    if diagnostic_fault != 'render-quiet':
        output += ''.join('    ' + line + '\n' for line in diagnostic)
    stderr_pattern = None
    if diagnostic_fault.startswith('render-'):
        output += '  [WARN] Cannot render the static ELF inspection diagnostics\n'
    elif diagnostic_fault.startswith('clear-'):
        output += '  [WARN] Cannot clear the static ELF inspection diagnostics\n'
        expected['saved-diagnostics'] = ('file', 0o600, diagnostic_text.encode())
        if diagnostic_fault == 'clear-directory':
            expected['broken_errors'] = ('directory', 0o700)
            expected['broken_errors/keep'] = ('file', 0o600, b'diagnostic child sentinel\n')
        else:
            expected['broken_errors'] = ('link', 0o777, str(root / 'diagnostic-target'))
            expected['diagnostic-target'] = ('directory', 0o700)
            expected['diagnostic-target/keep'] = ('file', 0o600, b'diagnostic child sentinel\n')
        stderr_pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(paths['BROKEN_ERRORS'])) + r': Is a directory\n'
    if not publication_blocked:
        file('BROKEN', staged)
        output += '  [WARN] ELF objects that still have unresolved dependencies:\n    ' + str(primary) + '\n'
    primary_calls = ([] if profile == 'resolver' else ['readelf:-h:metadata'])
    primary_calls.append('emit:' + primary.name + ':' + emission)
    healthy_calls = ['readelf:-h:healthy', 'readelf:-d:healthy', 'needed-sort']
    calls = ['cache'] + (primary_calls + healthy_calls if order == 'first' else healthy_calls + primary_calls)
    calls.append('diagnostic-render:' + diagnostic_fault)
    if diagnostic_fault.startswith('clear-'):
        calls.append('block-clear:' + diagnostic_fault)
    if not publication_blocked:
        calls.extend(('unresolved-render', 'copy'))
    settings = dict(paths, HEADER=inputs.HEADER, CACHE_TEXT=inputs.CACHE.decode(),
                    EMISSION=emission, DIAGNOSTIC_FAULT=diagnostic_fault,
                    ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6, inspection_failed=123, emission_failed=456)
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in inputs.GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(str(value)) for key, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nverify_broken_elf_objects_after_rebuild\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 && $emission_failed == 456 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'elf-recheck-diagnostics',
                             str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=15)
    wanted = output.encode() + b'\0STATE\0' + b''.join(value.encode() + b'\0' for value in ('1', '9', '1', '7', '1'))
    trace = (root / 'trace').read_text().splitlines()
    assert trace.count('final-sort') == 1 and trace.count('needed-sort') == 1, trace
    ordered = [value for value in trace if value not in ('final-sort', 'needed-sort')]
    wanted_order = [value for value in calls if value != 'needed-sort']
    stderr_matches = bool(re.fullmatch(stderr_pattern, result.stderr.decode())) if stderr_pattern else result.stderr == b''
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_matches or ordered != wanted_order:
        raise AssertionError(dict(case=(profile, order, emission, diagnostic_fault, newline),
                                  status=result.returncode, stdout=result.stdout, expected_stdout=wanted,
                                  stderr=result.stderr, expected_stderr_pattern=stderr_pattern,
                                  trace=trace, expected_ordered_trace=wanted_order))
    assert inputs.inventory(root) == expected, (profile, order, emission, diagnostic_fault, newline, 'private inventory mismatch')
    return dict(profile=profile, order=order, emission=emission, diagnostic_fault=diagnostic_fault,
                final_newline=newline, raw_recheck=1, emission_refused=rejected_emission,
                diagnostic_refused=rejected_diagnostic, publication_blocked=publication_blocked,
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'),
                stderr=result.stderr.decode().replace(str(root), '<ROOT>'),
                trace=[value.replace(str(root), '<ROOT>') for value in trace])


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-recheck-diagnostics-') as temporary:
        for index, args in enumerate(itertools.product(('metadata', 'resolver'), ('first', 'last'),
                                                      ('none', 'quiet', 'late'), FAULTS, (False, True))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 120
    assert sum(row['emission_refused'] for row in rows) == 80
    assert sum(row['diagnostic_refused'] for row in rows) == 96
    assert sum(row['publication_blocked'] for row in rows) == 112
    print('ELF recheck diagnostics: 120 scenarios, 112 blocked publications, 8 normal unresolved controls, 0 failures')
    return rows


if __name__ == '__main__':
    run()
