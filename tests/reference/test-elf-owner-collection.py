#!/usr/bin/env python3
"""Exercise real private owner collection with authored command-failure projections."""
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
PROFILES = ('owned', 'first-unowned', 'last-unowned', 'unowned', 'missing-object', 'empty', 'missing-list')
FAULTS = ('none', 'allocation', 'grep-first', 'grep-first-partial', 'grep-last', 'grep-last-partial',
          'sort', 'sort-partial', 'filter', 'filter-partial', 'missing-database', 'broken-open')
WATCHED = {'events', 'grep-count', 'sort-count', 'allocation-seen'}
PREFIX = r'''
source "$1"
TEST_ROOT=$2
event() { builtin printf '%s\n' "$1" >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
eval "$(declare -f package_names_with_build_suffix_from_stream | sed '1s/package_names_with_build_suffix_from_stream/real_package_names_with_build_suffix_from_stream/')"
eval "$(declare -f merge_sbo_target_sets | sed '1s/merge_sbo_target_sets/real_merge_sbo_target_sets/')"
mktemp() {
    if [[ ! -e $TEST_ROOT/allocation-seen ]]; then
        [[ $# == 0 ]] || forbidden first-allocation-vector
        : > "$TEST_ROOT/allocation-seen"
        event allocate
        [[ $FAULT != allocation ]] || return 43
        if [[ $FAULT == broken-open ]]; then builtin command rm -- "$BROKEN"; fi
    fi
    builtin command mktemp "$@"
}
grep() {
    [[ $# == 7 && $1 == -rlFx && $2 == -e && $4 == -e && $6 == -- \
        && $7 == "$PACKAGE_DATABASE/" && $3 == "$TEST_ROOT/objects/"* ]] || forbidden grep-vector
    local count=$(< "$TEST_ROOT/grep-count")
    count=$((count + 1))
    builtin printf '%s\n' "$count" > "$TEST_ROOT/grep-count"
    event "grep:$count"
    if { [[ $count == 1 && $FAULT == grep-first* ]]; } \
        || { [[ $count == 2 && $FAULT == grep-last* ]]; }; then
        if [[ $FAULT == *-partial ]]; then
            builtin printf '%s\n' "$TEST_ROOT/packages/owner-a-1.0-x86_64-1_SBo"
        fi
        return 43
    fi
    builtin command grep "$@"
}
package_names_with_build_suffix_from_stream() {
    [[ $# == 1 && $1 == _SBo ]] || forbidden filter-vector
    local count=$(< "$TEST_ROOT/grep-count")
    event "filter:$count"
    if [[ $FAULT == filter || $FAULT == filter-partial ]]; then
        local line
        while IFS= read -r line || [[ -n $line ]]; do :; done
        if [[ $FAULT == filter-partial ]]; then builtin printf 'supplied-target\n'; fi
        return 43
    fi
    real_package_names_with_build_suffix_from_stream "$@"
}
sort() {
    local count=$(< "$TEST_ROOT/sort-count")
    count=$((count + 1))
    builtin printf '%s\n' "$count" > "$TEST_ROOT/sort-count"
    if [[ $count == 1 && ( $FAULT == sort || $FAULT == sort-partial ) ]]; then
        local line
        while IFS= read -r line || [[ -n $line ]]; do :; done
        if [[ $FAULT == sort-partial ]]; then builtin printf 'supplied-target\n'; fi
        return 43
    fi
    builtin command sort "$@"
}
merge_sbo_target_sets() {
    [[ $# == 3 && $1 == "$QUEUE_EXTRA.merged" && $2 == "$QUEUE_EXTRA" && $3 == "$TEST_ROOT/"* ]] || forbidden merge-vector
    event merge
    real_merge_sbo_target_sets "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'detect_broken_elf_objects', 'verify_broken_elf_objects_after_rebuild',
          'readelf', 'ldd', 'ldconfig', 'slackpkg', 'sbopkg', 'sqg', 'flatpak',
          'git', 'curl', 'wget', 'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name not in WATCHED}


def scenario(root, profile, fault, terminated):
    objects = root / 'objects'
    database = root / 'packages'
    objects.mkdir(); database.mkdir()
    paths = [objects / 'first', objects / 'last']
    if profile != 'missing-object':
        for path in paths: path.write_text('private text; no ELF execution\n')
    owners = {'owned': (True, True), 'first-unowned': (False, True),
              'last-unowned': (True, False)}.get(profile, (False, False))
    for name, path, owned in zip(('owner-a', 'owner-b'), paths, owners):
        (database / (name + '-1.0-x86_64-1_SBo')).write_text(str(path) + ('' if owned else '-suffix') + '\n')
    broken = root / 'broken'
    if profile != 'missing-list':
        broken.write_text('' if profile == 'empty' else '\n'.join(map(str, paths)) + ('\n' if terminated else ''))
    queue = root / 'queue-extra'; queue.write_text('zeta\nabi\nzeta\n')
    for name in ('grep-count', 'sort-count'): (root / name).write_text('0\n')
    expected = inventory(root); active = profile not in ('empty', 'missing-list')
    calls = []; lookups = 0; sorts = 0; failed = False; error = ''
    if active:
        calls.append('allocate')
        if fault == 'allocation':
            failed = True; error = 'cannot allocate broken-object SBo owner list'
        else:
            sorts = 1
            if fault == 'broken-open':
                del expected['broken']; failed = True
            elif profile != 'missing-object':
                for number, owned in enumerate(owners, 1):
                    lookups += 1; calls.append(f'grep:{number}')
                    if fault == 'missing-database' or (number == 1 and fault.startswith('grep-first')) \
                            or (number == 2 and fault.startswith('grep-last')):
                        failed = True; break
                    if owned:
                        calls.append(f'filter:{number}')
                        if fault in ('filter', 'filter-partial'):
                            failed = True; break
            if fault in ('sort', 'sort-partial'): failed = True
            if failed:
                error = 'cannot collect broken-object SBo owners'
            else:
                calls.append('merge'); sorts = 2
                targets = sorted({'abi', 'zeta'} | {name for name, owned in zip(('owner-a', 'owner-b'), owners) if owned})
                expected['queue-extra'] = ('file', ''.join(name + '\n' for name in targets).encode())
    status = 1 if failed else 0
    total = '9' if not active or failed else str(2 + sum(owners))
    output = '[9] Mapeando binarios rotos a paquetes SBo\n'
    output += ('  [ERROR] ' + error + '\n' if failed else '  Cola extra tras rotos: ' + total + ' paquetes\n'
               if active else '  Sin binarios rotos, nada que anadir\n')
    values = dict(BROKEN=str(broken), QUEUE_EXTRA=str(queue),
                  PACKAGE_DATABASE=str(root / 'missing-database') if fault == 'missing-database' else str(database),
                  SBO_PACKAGE_TAG='_SBo', SBO_TARGET_SELECTION_ERROR='', TOTAL_EXTRA='9', FAULT=fault,
                  ELF_SCAN_STATUS='8', ELF_VERIFICATION_STATUS='7')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(value) for key, value in values.items()) + '\n'
    shell += r'''
saved_ifs=$IFS
outer=preserved
map_broken_objects_to_sbo_packages
raw=$?
[[ $IFS == "$saved_ifs" && $outer == preserved ]] || exit 96
builtin printf '\0STATE\0%s\0%s\0%s\0%s\0%s\0' \
    "$raw" "$TOTAL_EXTRA" "$SBO_TARGET_SELECTION_ERROR" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'owner-collection', str(REFERENCE), str(root)],
                            cwd=root, capture_output=True, timeout=15,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0' + total.encode() + b'\0' + error.encode() + b'\0' + b'8\0' + b'7\0'
    stderr_ok = not result.stderr
    if active and fault == 'broken-open':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(broken)) + r': No such file or directory\n'
        stderr_ok = bool(re.fullmatch(pattern, result.stderr.decode()))
    events = (root / 'events').read_text().splitlines() if (root / 'events').exists() else []
    observed = (int((root / 'grep-count').read_text()), int((root / 'sort-count').read_text()))
    if result.returncode or result.stdout != wanted or not stderr_ok or events != calls \
            or observed != (lookups, sorts) or inventory(root) != expected:
        raise AssertionError(dict(profile=profile, fault=fault, terminated=terminated,
                                  returncode=result.returncode, stdout=result.stdout, expected_stdout=wanted,
                                  stderr=result.stderr, events=events, expected_events=calls,
                                  counts=observed, expected_counts=(lookups, sorts),
                                  inventory_matches=inventory(root) == expected))


def main():
    failures = []; count = 0
    for profile in PROFILES:
        for fault in FAULTS:
            for terminated in (True, False):
                count += 1
                with tempfile.TemporaryDirectory(prefix='owner-collection-test-') as temporary:
                    try: scenario(Path(temporary), profile, fault, terminated)
                    except AssertionError as error: failures.append((count, str(error)))
    if failures:
        for number, error in failures: print(f'FAIL owner collection {number}: {error}', file=sys.stderr)
        raise SystemExit(f'ELF owner collection: {count - len(failures)} pass, {len(failures)} fail')
    print(f'ELF owner collection: {count} scenarios PASS')


if __name__ == '__main__': main()
