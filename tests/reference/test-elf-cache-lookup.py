#!/usr/bin/env python3
"""Distinguish compatible, absent and failed private ELF-cache lookups."""
from pathlib import Path
import itertools
import os
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
IDENTITY = ('ELF64', "2's complement, little endian", 'Advanced Micro Devices X86-64')
QUERIES = (IDENTITY, ('ELF32', IDENTITY[1], 'Intel 80386'),
           (IDENTITY[0], IDENTITY[1], 'AArch64'),
           (IDENTITY[0], "2's complement, big endian", IDENTITY[2]), (), ('ELF64', 'incomplete'))
CACHES = ('matching', 'wrong-class', 'wrong-data', 'wrong-machine', 'prefix', 'empty', 'duplicate', 'missing', 'directory')
FAULTS = ('none', 'awk-1', 'awk-2', 'awk-partial', 'awk-127', 'awk-empty', 'awk-invalid', 'awk-directory-skipped')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
event() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
readelf() {
    [[ $# == 3 && $2 == -- && $3 == "$TEST_ROOT/scan/object" ]] || forbidden readelf-vector
    event readelf "$1"
    case "$1" in
        -h) builtin printf '%s' "$HEADER" ;;
        -d) builtin printf '%s' "$DYNAMIC" ;;
        *) forbidden readelf-mode ;;
    esac
}
awk() {
    local last=${!#}
    if [[ $last == "$CACHE" ]]; then
        [[ $# == 12 && $1 == -F && $3 == -v && $5 == -v && $7 == -v && $9 == -v ]] || forbidden lookup-vector
        event lookup
        case "$FAULT" in
            awk-1) return 1 ;;
            awk-2) return 2 ;;
            awk-partial) builtin printf 'compatible\n'; return 43 ;;
            awk-127) return 127 ;;
            awk-empty) return 0 ;;
            awk-invalid) builtin printf 'unexpected\n'; return 0 ;;
            awk-directory-skipped)
                if [[ -d $CACHE ]]; then
                    builtin printf 'awk: supplied warning: %s is a directory: skipped\n' "$CACHE" >&2
                    builtin printf 'absent\n'
                    return 0
                fi
                ;;
        esac
    fi
    builtin command awk "$@"
}
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$CACHE" ]] || forbidden refresh-vector
    event refresh
    ELF_LIBRARY_CACHE_RECORD_COUNT=6
    return 0
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow', 'ldd', 'ldconfig',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def encode(rows):
    return b''.join(b''.join(value.encode() + b'\0' for value in row) + b'\n' for row in rows)


def scenario(root, kind, cache_profile, identity, needed, fault):
    (root / 'scan').mkdir(); obj = root / 'scan/object'; obj.write_bytes(b'\x7fELFprivate fixture\n')
    cache = root / 'cache'
    rows = []
    if cache_profile not in ('missing', 'directory', 'empty'):
        row = ('libsame.so.1', *IDENTITY, '/unmeasured/library')
        if cache_profile == 'wrong-class': row = (row[0], 'ELF32', *row[2:])
        elif cache_profile == 'wrong-data': row = (*row[:2], "2's complement, big endian", *row[3:])
        elif cache_profile == 'wrong-machine': row = (*row[:3], 'AArch64', row[4])
        elif cache_profile == 'prefix': row = ('libsame.so.10', *row[1:])
        rows = [row] * (2 if cache_profile == 'duplicate' else 1)
    if cache_profile == 'directory': cache.mkdir()
    elif cache_profile != 'missing': cache.write_text(''.join('\t'.join(row) + '\n' for row in rows))
    (root / 'errors').write_text('old diagnostics\n')
    (root / 'broken').write_text(str(obj) + '\n' if kind == 'verify' else 'old broken\n')
    for name in ('new', 'still'): (root / name).write_text('old staging\n')
    expected = inventory(root); trace = []; diagnostic = False
    valid_identity = len(identity) == 3 and all(identity)
    def lookup_status(soname):
        nonlocal diagnostic
        if not valid_identity: return 1
        trace.append(('lookup',))
        if fault == 'awk-directory-skipped' and cache_profile == 'directory':
            diagnostic = True; return 2
        if fault not in ('none', 'awk-directory-skipped'): return 2
        if cache_profile in ('missing', 'directory'): diagnostic = True; return 2
        return 0 if any(tuple(row[:4]) == (soname, *identity) for row in rows) else 1
    if kind == 'lookup':
        status = lookup_status('libsame.so.1'); stdout = b''
    else:
        if kind in ('scan', 'verify'): trace.append(('refresh',))
        trace += [('readelf', '-h'), ('readelf', '-d')]
        status = 1
        for soname in sorted(set(needed)):
            if not soname: continue
            found = lookup_status(soname)
            if found == 1: status = 0; break
            if found == 2: status = 2; break
        stdout = b''
        if kind in ('scan', 'verify'):
            issue = status == 2; broken = status == 0 or (kind == 'verify' and issue)
            value = (str(obj) + '\n') if broken else ''
            if kind == 'scan':
                text = '[8] Detecting broken ELF objects without executing inspected files\n'
                if issue: text += '  [WARN] Static ELF inspection diagnostics:\n    readelf could not inspect ' + str(obj) + '\n'
                text += '  Broken ELF objects detected: ' + str(int(broken)) + '\n'
                expected['new'] = ('file', value.encode()); expected['broken'] = ('file', value.encode())
                state = ['0', '8', str(int(broken)), '6']; status = 0
            else:
                text = '  Verifying rebuilt ELF objects with static inspection...\n'
                if issue: text += '  [WARN] Static ELF inspection diagnostics:\n    readelf could not re-inspect ' + str(obj) + '\n'
                if broken: text += '  [WARN] ELF objects that still have unresolved dependencies:\n    ' + str(obj) + '\n'
                else: text += '  [OK] All previously broken ELF objects passed static verification\n'
                expected['still'] = ('file', value.encode()); expected['broken'] = ('file', value.encode())
                state = ['9', str(int(broken)), '7', '6']; status = int(broken)
            expected['errors'] = ('file', b''); stdout = text.encode()
    assignments = dict(CACHE=str(cache), FAULT=fault, HEADER=''.join(key + ': ' + value + '\n' for key, value in zip(('Class', 'Data', 'Machine'), identity)),
                       DYNAMIC=''.join(' (NEEDED) [' + name + ']\n' for name in needed),
                       BROKEN_ERRORS=str(root / 'errors'), BROKEN=str(root / 'broken'), BROKEN_NEW=str(root / 'new'),
                       STILL_BROKEN=str(root / 'still'), ELF_LIBRARY_CACHE=str(cache))
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(value) for key, value in assignments.items()) + '\n'
    shell += "IFS='|: '; outer=kept; ELF_SCAN_STATUS=9; ELF_VERIFICATION_STATUS=8; BROKEN_COUNT=7; ELF_LIBRARY_CACHE_RECORD_COUNT=5\n"
    shell += 'ELF_SCAN_PATHS=("$TEST_ROOT/scan")\nraw=0\n'
    if kind == 'lookup': call = 'static_elf_cache_has_compatible_library "$CACHE" libsame.so.1 ' + shlex.quote('\t'.join(identity))
    elif kind == 'object': call = 'static_elf_object_has_missing_dependency "$TEST_ROOT/scan/object" "$CACHE"'
    elif kind == 'scan': call = 'detect_broken_elf_objects'
    else: call = 'verify_broken_elf_objects_after_rebuild'
    shell += call + ' || raw=$?\n'
    shell += '[[ $IFS == "|: " && $outer == kept ]] || exit 96\nbuiltin printf "\\0STATUS\\0%s" "$raw"\n'
    if kind in ('scan', 'verify'):
        shell += 'builtin printf "\\0%s" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS" "$BROKEN_COUNT" "$ELF_LIBRARY_CACHE_RECORD_COUNT"\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'cache-lookup-test', str(REFERENCE), str(root)],
                            cwd=root, capture_output=True, timeout=15, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = stdout + b'\0STATUS\0' + str(status).encode()
    if kind in ('scan', 'verify'): wanted += b''.join(b'\0' + value.encode() for value in state)
    # Native awk wording varies. mawk can report a directory read error without
    # naming the path; require its error category or the missing private path.
    if diagnostic:
        stderr_ok = bool(result.stderr) and (b'awk' in result.stderr.lower()) and (
            b'directory' in result.stderr.lower() if cache_profile == 'directory' else str(cache).encode() in result.stderr)
    else:
        stderr_ok = result.stderr == b''
    actual_trace = (root / 'events').read_bytes() if (root / 'events').exists() else b''
    if result.returncode or result.stdout != wanted or not stderr_ok or actual_trace != encode(trace) or inventory(root) != expected:
        raise AssertionError(dict(kind=kind, cache=cache_profile, identity=identity, needed=needed, fault=fault,
                                  process_status=result.returncode, stdout=result.stdout, expected_stdout=wanted,
                                  stderr=result.stderr, diagnostic_expected=diagnostic, trace=actual_trace,
                                  expected_trace=encode(trace), inventory_matches=inventory(root) == expected))


def main():
    cases = []
    for profile, identity, fault in itertools.product(CACHES, QUERIES, FAULTS):
        cases.append(('lookup', profile, identity, (), fault))
    needed_sets = ((), ('libsame.so.1',), ('libabsent.so.1',), ('libsame.so.1', 'libzmissing.so.1'))
    for profile, needed, fault in itertools.product(('matching', 'wrong-class', 'missing', 'directory'), needed_sets,
                                                    ('none', 'awk-1', 'awk-partial', 'awk-directory-skipped')):
        cases.append(('object', profile, IDENTITY, needed, fault))
    for kind, profile, needed, fault in itertools.product(('scan', 'verify'), ('matching', 'wrong-class', 'missing', 'directory'),
                                                        needed_sets[:3], ('none', 'awk-1', 'awk-partial', 'awk-directory-skipped')):
        cases.append((kind, profile, IDENTITY, needed, fault))
    failures = []
    for number, case in enumerate(cases, 1):
        with tempfile.TemporaryDirectory(prefix='elf-cache-lookup-') as temporary:
            try: scenario(Path(temporary), *case)
            except AssertionError as error: failures.append((number, str(error)))
    if failures:
        for number, error in failures: print(f'FAIL cache lookup {number}: {error}', file=sys.stderr)
        raise SystemExit(f'ELF cache lookup: {len(cases) - len(failures)} pass, {len(failures)} fail')
    print(f'ELF cache lookup: {len(cases)} scenarios PASS (432 lookup, 64 object, 48 scan, 48 verification)')


if __name__ == '__main__': main()
