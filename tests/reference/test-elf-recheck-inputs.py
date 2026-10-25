#!/usr/bin/env python3
"""Check private post-build ELF input shapes and sticky emission refusal."""
import itertools
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
HEADER = ' Class: ELF64\n Data: little-endian\n Machine: supplied-machine\n'
CACHE = b'libpresent.so\tELF64\tlittle-endian\tsupplied-machine\t/supplied/library\n'
PROFILES = ('broken', 'healthy', 'absent-object', 'text', 'dangling', 'alias',
            'duplicates', 'blanks', 'mixed', 'metadata', 'empty', 'missing-list')
FIELDS = ('ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS', 'BROKEN_COUNT',
          'ELF_LIBRARY_CACHE_RECORD_COUNT')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\n' "$1" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record cache
    builtin printf '%s' "$CACHE_TEXT" > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
readelf() {
    [[ $# == 3 && $2 == -- && $LC_ALL == C ]] || forbidden reader-vector
    case $3 in
        "$TEST_ROOT/objects/broken"|"$TEST_ROOT/objects/healthy"|"$TEST_ROOT/objects/metadata") ;;
        *) forbidden reader-path ;;
    esac
    record "readelf:$1:${3##*/}"
    if [[ $1 == -h ]]; then
        builtin printf '%s' "$HEADER"
        if [[ $3 == "$TEST_ROOT/objects/metadata" ]]; then
            builtin printf 'supplied metadata header diagnostic\n' >&2
            return 43
        fi
        return 0
    fi
    [[ $1 == -d && $3 != "$TEST_ROOT/objects/metadata" ]] || forbidden reader-mode
    if [[ $3 == "$TEST_ROOT/objects/healthy" ]]; then
        builtin printf ' (NEEDED) [libpresent.so]\n'
    else
        builtin printf ' (NEEDED) [libabsent.so]\n'
    fi
}
printf() {
    if [[ ${FUNCNAME[1]} == verify_broken_elf_objects_after_rebuild && $# == 2 && $1 == '%s\n' ]]; then
        case $2 in
            "$TEST_ROOT/objects/broken"|"$TEST_ROOT/objects/alias"|"$TEST_ROOT/objects/text"|"$TEST_ROOT/objects/dangling"|"$TEST_ROOT/objects/metadata") ;;
            *) forbidden emission-path ;;
        esac
        record "emit:${2##*/}:$EMISSION"
        [[ $EMISSION != quiet ]] || return 43
        builtin printf "$@"
        [[ $EMISSION != late ]] || return 43
        return 0
    fi
    builtin printf "$@"
}
sort() {
    [[ $# == 1 && $1 == -u && $LC_ALL == C ]] || forbidden sort-vector
    case ${FUNCNAME[1]} in
        verify_broken_elf_objects_after_rebuild) record final-sort ;;
        extract_static_elf_needed_libraries) record needed-sort ;;
        *) forbidden sort-caller ;;
    esac
    builtin command sort "$@"
}
sed() {
    [[ $# == 2 && $1 == 's/^/    /' ]] || forbidden sed-vector
    case $2 in
        "$BROKEN_ERRORS") record diagnostic-render ;;
        "$STILL_BROKEN") record unresolved-render ;;
        *) forbidden sed-path ;;
    esac
    builtin command sed "$@"
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$STILL_BROKEN" && $4 == "$BROKEN" ]] || forbidden copy-vector
    record copy
    builtin command cp "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime',
          'load_configuration', 'run_apply_workflow', 'run_check_workflow',
          'run_dry_run_workflow', 'detect_broken_elf_objects',
          'map_broken_objects_to_sbo_packages', 'slackpkg', 'sbopkg', 'sqg',
          'flatpak', 'ldd', 'ldconfig', 'git', 'curl', 'wget', 'find', 'wc',
          'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    result = {}
    for path in root.rglob('*'):
        if path == root / 'trace':
            continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink():
            value = ('link', mode, os.readlink(path))
        elif path.is_dir():
            value = ('directory', mode)
        else:
            value = ('file', mode, path.read_bytes())
        result[path.relative_to(root).as_posix()] = value
    return result


def scenario(root, profile, order, emission, newline):
    objects = root / 'objects'
    objects.mkdir()
    for name in ('broken', 'healthy', 'metadata', 'text'):
        p = objects / name
        p.write_bytes(b'non-ELF text\n' if name == 'text' else b'\x7fELFinert fixture\n')
        p.chmod(0o600)
    (objects / 'alias').symlink_to(objects / 'broken')
    (objects / 'dangling').symlink_to(objects / 'absent')
    selected = {
        'broken': ['broken'], 'healthy': ['healthy'], 'absent-object': ['absent'],
        'text': ['text'], 'dangling': ['dangling'], 'alias': ['alias'],
        'duplicates': ['broken', 'broken', 'alias', 'alias'],
        'blanks': ['', 'broken', '', 'healthy', ''],
        'mixed': ['healthy', 'alias', 'absent', 'text', 'dangling', 'metadata',
                  'broken', 'alias', '', 'healthy'],
        'metadata': ['metadata'], 'empty': [], 'missing-list': [],
    }[profile]
    if order == 'reverse':
        selected = list(reversed(selected))
    lines = [str(objects / name) if name else '' for name in selected]
    prior = '\n'.join(lines) + ('\n' if lines and newline else '')
    paths = {key: root / key.lower() for key in
             ('BROKEN', 'BROKEN_NEW', 'BROKEN_ERRORS', 'STILL_BROKEN', 'ELF_LIBRARY_CACHE')}
    for path in paths.values():
        path.write_bytes(b'prior bytes\n')
        path.chmod(0o600)
    if profile == 'missing-list':
        paths['BROKEN'].unlink()
    else:
        paths['BROKEN'].write_text(prior)
    expected = inventory(root)

    def file(key, value):
        expected[paths[key].name] = ('file', 0o600, value.encode() if isinstance(value, str) else value)

    early = profile in ('empty', 'missing-list')
    calls = [] if early else ['cache']
    emitted = []
    diagnostic = []
    if not early:
        for name, path in zip(selected, lines):
            if not name or name == 'absent':
                continue
            canonical = 'broken' if name == 'alias' else name
            if canonical not in ('text', 'dangling'):
                calls.append('readelf:-h:' + canonical)
                if canonical == 'metadata':
                    diagnostic.append('supplied metadata header diagnostic')
                else:
                    calls.extend(('readelf:-d:' + canonical, 'needed-sort'))
            if name == 'healthy':
                continue
            calls.append('emit:' + name + ':' + emission)
            emitted.append(path)
            if canonical == 'metadata':
                diagnostic.append('readelf could not re-inspect ' + path)
            elif canonical in ('text', 'dangling'):
                diagnostic.append('cannot statically re-inspect ' + path)
    rejected = bool(emitted) and emission != 'none'
    staged = sorted(set(emitted)) if emission != 'quiet' else []
    staged_text = ''.join(path + '\n' for path in staged)
    raw = int(rejected or bool(staged))
    output = '' if early else '  Verifying rebuilt ELF objects with static inspection...\n'
    if rejected:
        output += '  [WARN] Cannot read, emit or sort the static ELF verification results\n'
    if diagnostic:
        calls.append('diagnostic-render')
        output += '  [WARN] Static ELF inspection diagnostics:\n'
        output += ''.join('    ' + line + '\n' for line in diagnostic)
    if not early:
        file('ELF_LIBRARY_CACHE', CACHE)
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
    settings = dict(paths, EMISSION=emission, HEADER=HEADER, CACHE_TEXT=CACHE.decode(),
                    ELF_SCAN_STATUS=9, ELF_VERIFICATION_STATUS=8, BROKEN_COUNT=7,
                    ELF_LIBRARY_CACHE_RECORD_COUNT=6, inspection_failed=123, emission_failed=456)
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(str(value)) for key, value in settings.items()) + '\n'
    shell += "IFS='|: '\nsaved_ifs=$IFS\nouter=kept\nverify_broken_elf_objects_after_rebuild\nraw=$?\n"
    shell += '[[ $IFS == "$saved_ifs" && $outer == kept && $inspection_failed == 123 && $emission_failed == 456 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'elf-recheck-inputs',
                             str(REFERENCE), str(root)], cwd=root,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)),
                            capture_output=True, timeout=15)
    state = (str(raw), '9', str(raw), '7', '6' if early else '1')
    wanted = output.encode() + b'\0STATE\0' + b''.join(value.encode() + b'\0' for value in state)
    trace = (root / 'trace').read_text().splitlines() if (root / 'trace').exists() else []
    # Only sort records are concurrent with producers; preserve and count all of them.
    assert trace.count('final-sort') == int(not early), trace
    assert trace.count('needed-sort') == calls.count('needed-sort'), trace
    ordered_trace = [s for s in trace if s not in ('final-sort', 'needed-sort')]
    wanted_trace = [s for s in calls if s != 'needed-sort']
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, b'') or ordered_trace != wanted_trace:
        raise AssertionError(dict(case=(profile, order, emission, newline), status=result.returncode,
                                  stdout=result.stdout, expected_stdout=wanted, stderr=result.stderr,
                                  trace=trace, expected_ordered_trace=wanted_trace))
    assert inventory(root) == expected, (profile, order, emission, newline, 'private inventory mismatch')
    return dict(profile=profile, order=order, emission=emission, final_newline=newline,
                raw_status=raw, early=early, emission_attempts=len(emitted), rejected=rejected,
                normal_unresolved=emission == 'none' and bool(staged),
                stdout=result.stdout.decode().replace(str(root), '<ROOT>'), stderr=result.stderr.decode(),
                trace=[s.replace(str(root), '<ROOT>') for s in trace])


def run():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-recheck-inputs-') as temporary:
        for index, args in enumerate(itertools.product(PROFILES, ('forward', 'reverse'),
                                                      ('none', 'quiet', 'late'), (False, True))):
            root = Path(temporary).resolve() / str(index)
            root.mkdir()
            rows.append(scenario(root, *args))
    assert len(rows) == 144 and sum(row['rejected'] for row in rows) == 64
    assert sum(row['early'] for row in rows) == 24
    assert sum(row['normal_unresolved'] for row in rows) == 32
    print('ELF recheck inputs: 144 scenarios, 64 rejected emission failures, 24 early returns, 0 failures')
    return rows


if __name__ == '__main__':
    run()
