#!/usr/bin/env python3
"""Compose initial inspection errors with reporting, staging and final producer status."""
from collections import Counter
import itertools
import os
from pathlib import Path
import re
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT', 'ELF_LIBRARY_CACHE_RECORD_COUNT')
HEADER = ' Class: ELF64\n Data: little-endian\n Machine: supplied-machine\n'
CACHE = b'libpresent.so\tELF64\tlittle-endian\tsupplied-machine\t/supplied/library\n'
PIPELINE_ERROR = '  [ERROR] Cannot enumerate, inspect or sort the static ELF scan results\n'
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { local IFS=' '; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record cache
    builtin printf '%s' "$CACHE_TEXT" > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C && ( $3 == "$TEST_ROOT/scan/target" || $3 == "$TEST_ROOT/scan/companion" ) ]] || forbidden reader-vector
    record "readelf:$1:${3##*/}"
    local profile=$PROFILE
    [[ $3 != */companion ]] || profile=missing
    if [[ $1 == -h ]]; then
        builtin printf '%s' "$HEADER"
        if [[ $profile == header-error ]]; then
            builtin printf 'supplied header diagnostic\n' >&2
            return 43
        fi
        [[ $profile != warning-only ]] || builtin printf 'supplied reader warning\n' >&2
        return 0
    fi
    [[ $1 == -d ]] || forbidden reader-mode
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
find() {
    [[ $# == 9 && $1 == "$TEST_ROOT/scan" && $2 == '(' && $3 == -type && $4 == f && $5 == -o && $6 == -type && $7 == l && $8 == ')' && $9 == -print0 ]] || forbidden find-vector
    record find
    builtin command find "$@"
}
sort() {
    [[ $# == 1 && $1 == -u && $LC_ALL == C ]] || forbidden sort-vector
    if [[ ${FUNCNAME[1]} == detect_broken_elf_objects ]]; then
        record final-sort
        builtin command sort "$@" || forbidden real-sort
        [[ $SORT_FAULT != late ]] || return 43
        return 0
    fi
    [[ ${FUNCNAME[1]} == extract_static_elf_needed_libraries ]] || forbidden sort-caller
    builtin command sort "$@"
}
printf() {
    if [[ ${FUNCNAME[1]} == detect_broken_elf_objects && $# == 2 && $1 == '%s\n' && $2 == "$TEST_ROOT/scan/target" ]]; then
        record "emit:$EMIT_FAULT"
        [[ $EMIT_FAULT != quiet ]] || return 43
        builtin printf "$@"
        [[ $EMIT_FAULT != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
sed() {
    [[ $# == 2 && $1 == 's/^/    /' && $2 == "$BROKEN_ERRORS" ]] || forbidden report-vector
    record render
    [[ $REPORT_FAULT != render-quiet ]] || return 43
    builtin command sed "$@" || forbidden real-sed
    [[ $REPORT_FAULT != render-late ]] || return 43
    if [[ $REPORT_FAULT == clear-directory || $REPORT_FAULT == clear-link-directory ]]; then
        [[ -f $BROKEN_ERRORS && ! -L $BROKEN_ERRORS ]] || forbidden errors-preimage
        record "$REPORT_FAULT"
        builtin command mv -- "$BROKEN_ERRORS" "$TEST_ROOT/saved-errors" || forbidden save-errors
        if [[ $REPORT_FAULT == clear-directory ]]; then
            builtin command mkdir -m 0700 -- "$BROKEN_ERRORS" || forbidden errors-directory
        else
            builtin command mkdir -m 0700 -- "$TEST_ROOT/diagnostic-target" || forbidden diagnostic-target
            builtin command ln -s -- "$TEST_ROOT/diagnostic-target" "$BROKEN_ERRORS" || forbidden diagnostic-link
        fi
    fi
    return 0
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    record count
    builtin command wc "$@"
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$BROKEN_NEW" && $4 == "$BROKEN" ]] || forbidden publish-vector
    record copy
    builtin command cp "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'verify_broken_elf_objects_after_rebuild', 'map_broken_objects_to_sbo_packages',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'ldd', 'ldconfig', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path == root/'trace':
            continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink(): value = ('link', mode, os.readlink(path))
        elif path.is_dir(): value = ('directory', mode)
        else: value = ('file', mode, path.read_bytes())
        result[str(path.relative_to(root))] = value
    return result


def scenario(root, profile, companion, report_fault, sort_fault, emit_fault, prior_empty):
    scan = root/'scan'
    scan.mkdir()
    target = scan/'target'
    target.write_bytes(b'\x7fELFinert metadata fixture\n')
    target.chmod(0o700)
    if companion:
        (scan/'companion').write_bytes(b'\x7fELFinert companion\n')
    paths = {key: root/key.lower() for key in ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    paths['BROKEN'].write_bytes(b'' if prior_empty else b'prior published list\n')
    expected = inventory(root)
    def expect_file(name, data): expected[name] = ('file', 0o600, data)
    expect_file('elf_library_cache', CACHE)
    staged = []
    if profile == 'missing' and emit_fault != 'quiet': staged.append(target)
    if companion: staged.append(scan/'companion')
    value = ''.join(str(p)+'\n' for p in sorted(staged)).encode()
    expect_file('broken_new', value)
    metadata_error = profile in ('header-error', 'dynamic-error')
    pipeline_failed = metadata_error or sort_fault == 'late' or emit_fault != 'none'
    diagnostics = []
    if profile == 'header-error': diagnostics.append('supplied header diagnostic')
    elif profile == 'dynamic-error': diagnostics.append('supplied dynamic diagnostic')
    elif profile == 'warning-only': diagnostics.append('supplied reader warning')
    if metadata_error: diagnostics.append('readelf could not inspect '+str(target))
    diagnostic_bytes = ''.join(line+'\n' for line in diagnostics).encode()
    output = '[8] Detecting broken ELF objects without executing inspected files\n'
    if pipeline_failed: output += PIPELINE_ERROR
    stderr_pattern = None
    calls = ['cache', 'find', 'final-sort', 'readelf:-h:target']
    if profile != 'header-error': calls.append('readelf:-d:target')
    if profile == 'missing': calls.append('emit:'+emit_fault)
    if companion: calls += ['readelf:-h:companion', 'readelf:-d:companion']
    report_failed = bool(diagnostics) and report_fault != 'none'
    expect_file('broken_errors', b'')
    if diagnostics:
        calls.append('render')
        output += '  [WARN] Static ELF inspection diagnostics:\n'
        if report_fault != 'render-quiet': output += ''.join('    '+line+'\n' for line in diagnostics)
        if report_fault in ('render-quiet', 'render-late'):
            output += '  [WARN] Cannot render the static ELF inspection diagnostics\n'
            expect_file('broken_errors', diagnostic_bytes)
        elif report_fault in ('clear-directory', 'clear-link-directory'):
            calls.append(report_fault)
            expect_file('saved-errors', diagnostic_bytes)
            if report_fault == 'clear-directory': expected['broken_errors'] = ('directory', 0o700)
            else:
                expected['diagnostic-target'] = ('directory', 0o700)
                expected['broken_errors'] = ('link', 0o777, str(root/'diagnostic-target'))
            output += '  [WARN] Cannot clear the static ELF inspection diagnostics\n'
            stderr_pattern = re.escape(str(REFERENCE))+r': line [1-9][0-9]*: '+re.escape(str(paths['BROKEN_ERRORS']))+r': Is a directory\n'
    raw = int(pipeline_failed or report_failed)
    count = '7'
    if not raw:
        calls += ['count', 'copy']
        expect_file('broken', value)
        count = str(len(staged))
        output += '  Broken ELF objects detected: '+count+'\n'
    state = (str(raw), '8', count, '1')
    values = dict(paths, PROFILE=profile, REPORT_FAULT=report_fault, SORT_FAULT=sort_fault,
                  EMIT_FAULT=emit_fault, HEADER=HEADER, CACHE_TEXT=CACHE.decode(),
                  ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                  ELF_LIBRARY_CACHE_RECORD_COUNT=6, inspection_failed=123)
    assignments = '\n'.join(key+'='+shlex.quote(str(value)) for key, value in values.items())
    guards = '\n'.join(name+'() { forbidden '+name+'; }' for name in GUARDS)
    suffix = '\nELF_SCAN_PATHS=("$TEST_ROOT/scan")\nIFS="|: "\nsaved_ifs=$IFS\nouter=kept\n'
    suffix += 'detect_broken_elf_objects\nraw=$?\n[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 ]] || exit 96\n'
    suffix += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    suffix += '\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)+'\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', PREFIX+guards+'\n'+assignments+suffix,
                             'elf-initial-diagnostics', str(REFERENCE), str(root)], cwd=root,
                            capture_output=True, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)), timeout=10)
    wanted = output.encode()+b'\0STATE\0'+str(raw).encode()+b'\0'+b''.join(v.encode()+b'\0' for v in state)
    label = (profile, companion, report_fault, sort_fault, emit_fault, prior_empty)
    stderr_ok = bool(re.fullmatch(stderr_pattern, result.stderr.decode())) if stderr_pattern else result.stderr == b''
    if (result.returncode, result.stdout) != (0, wanted) or not stderr_ok:
        raise AssertionError(f'{label}: expected {(0, wanted, stderr_pattern)!r}, got {(result.returncode, result.stdout, result.stderr)!r}')
    actual = (root/'trace').read_text().splitlines()
    if Counter(actual) != Counter(calls) or actual[0] != 'cache':
        raise AssertionError(f'{label}: callback vectors/multiplicity differ: {actual!r}')
    for name in ('target', 'companion'):
        readers = [line for line in actual if line.startswith('readelf:') and line.endswith(':'+name)]
        if readers != [line for line in calls if line.startswith('readelf:') and line.endswith(':'+name)]:
            raise AssertionError(f'{label}: per-object reader order differs')
    if 'render' in actual:
        assert all(actual.index('render') > i for i, line in enumerate(actual) if line.startswith('readelf:') or line == 'final-sort')
    if 'copy' in actual: assert actual.index('copy') > actual.index('count') > actual.index('final-sort')
    if inventory(root) != expected: raise AssertionError(f'{label}: private bytes/modes/links/inventory differ')
    return dict(profile=profile, companion=companion, report_fault=report_fault, sort_fault=sort_fault,
                emit_fault=emit_fault, prior_empty=prior_empty, raw_status=raw,
                prior_publication_preserved=bool(raw), staged_records=len(staged))


def run():
    cases = [(profile, companion, report, ordering, 'none', False)
             for profile, companion, report, ordering in itertools.product(
                 ('header-error', 'dynamic-error', 'warning-only'), (False, True),
                 ('none', 'render-quiet', 'render-late', 'clear-directory', 'clear-link-directory'), ('none', 'late'))]
    cases += [('missing', False, 'none', ordering, emission, empty)
              for ordering, emission, empty in itertools.product(('none', 'late'), ('none', 'quiet', 'late'), (False, True))]
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-initial-diagnostics-') as temporary:
        parent = Path(temporary).resolve()
        for index, args in enumerate(cases):
            root = parent/str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 72
    print('ELF initial inspection diagnostics: 72 scenarios, 60 reporting/staging entries, 12 final-producer entries, 0 failures')
    return rows


if __name__ == '__main__': run()
