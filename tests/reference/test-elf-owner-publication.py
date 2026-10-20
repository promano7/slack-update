#!/usr/bin/env python3
"""Check private owner staging, count-before-publication and selected failure effects."""
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
PROFILES = ('owned', 'unowned', 'duplicates', 'empty-abi', 'empty', 'missing')
FAULTS = ('none', 'merge', 'merge-partial', 'count', 'count-partial',
          'publish', 'publish-partial', 'stage-missing')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
event() { builtin printf '%s\n' "$1" >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
eval "$(declare -f merge_sbo_target_sets | sed '1s/merge_sbo_target_sets/real_merge_sbo_target_sets/')"
merge_sbo_target_sets() {
    [[ $# == 3 && $1 == "$QUEUE_EXTRA.merged" && $2 == "$QUEUE_EXTRA" && $3 == "$TEST_ROOT/"* ]] || forbidden merge-vector
    event merge
    if [[ $FAULT == merge || $FAULT == merge-partial ]]; then
        if [[ $FAULT == merge-partial ]]; then builtin printf 'supplied-target\n' > "$1"; fi
        return 43
    fi
    real_merge_sbo_target_sets "$@" || return $?
    if [[ $FAULT == stage-missing ]]; then builtin command rm -- "$1"; fi
    return 0
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    event count
    if [[ $FAULT == count || $FAULT == count-partial ]]; then
        if [[ $FAULT == count-partial ]]; then builtin printf '42\n'; fi
        return 43
    fi
    builtin command wc "$@"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$TEST_ROOT/"* ]] || forbidden move-vector
    if [[ $4 == "$QUEUE_EXTRA.merged" ]]; then
        builtin command mv "$@"
        return $?
    fi
    [[ $3 == "$QUEUE_EXTRA.merged" && $4 == "$QUEUE_EXTRA" ]] || forbidden publication-vector
    event publish
    if [[ $FAULT == publish || $FAULT == publish-partial ]]; then
        if [[ $FAULT == publish-partial ]]; then builtin printf 'supplied partial move\n' > "$QUEUE_EXTRA"; fi
        return 43
    fi
    builtin command mv "$@"
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'detect_broken_elf_objects', 'verify_broken_elf_objects_after_rebuild',
          'readelf', 'ldd', 'ldconfig', 'slackpkg', 'sbopkg', 'sqg', 'flatpak',
          'git', 'curl', 'wget', 'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def scenario(root, profile, fault, terminated):
    (root / 'objects').mkdir(); (root / 'packages').mkdir()
    paths = [root / 'objects/first', root / 'objects/last']
    for name, path in zip(('owner-a', 'owner-b'), paths):
        path.write_text('private text object; no ELF execution\n')
        body = str(path) + ('-suffix' if profile in ('unowned', 'empty-abi') else '')
        (root / 'packages' / (name + '-1.0-x86_64-1_SBo')).write_text(body + '\n')
    broken = root / 'broken'; queue = root / 'queue-extra'
    if profile != 'missing':
        lines = [] if profile == 'empty' else [str(paths[0]), str(paths[0])] if profile == 'duplicates' else list(map(str, paths))
        broken.write_text('\n'.join(lines) + ('\n' if lines and terminated else ''))
    queue.write_text('' if profile == 'empty-abi' else 'zeta\nabi\nzeta\n')
    expected = inventory(root); calls = []; active = profile not in ('empty', 'missing')
    error = ''; status = 0; total = '9'
    if active:
        calls.append('merge')
        targets = [] if profile == 'empty-abi' else ['abi', 'zeta'] if profile == 'unowned' else ['abi', 'owner-a', 'zeta'] if profile == 'duplicates' else ['abi', 'owner-a', 'owner-b', 'zeta']
        if fault in ('merge', 'merge-partial'):
            error = 'cannot merge broken-object SBo targets'
        elif fault == 'stage-missing':
            error = 'cannot count merged broken-object SBo targets'
        else:
            calls.append('count')
            if fault in ('count', 'count-partial'):
                error = 'cannot count merged broken-object SBo targets'
            else:
                calls.append('publish')
                if fault in ('publish', 'publish-partial'):
                    error = 'cannot publish broken-object SBo targets'
                    if fault == 'publish-partial': expected['queue-extra'] = ('file', b'supplied partial move\n')
                else:
                    expected['queue-extra'] = ('file', ''.join(name + '\n' for name in targets).encode())
                    total = str(len(targets))
        if error: status = 1
    output = '[9] Mapeando binarios rotos a paquetes SBo\n'
    output += ('  [ERROR] ' + error + '\n' if error else '  Cola extra tras rotos: ' + total + ' paquetes\n'
               if active else '  Sin binarios rotos, nada que anadir\n')
    values = dict(BROKEN=str(broken), QUEUE_EXTRA=str(queue), PACKAGE_DATABASE=str(root / 'packages'),
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
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'owner-publication', str(REFERENCE), str(root)],
                            cwd=root, capture_output=True, timeout=15,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + str(status).encode() + b'\0' + total.encode() + b'\0' + error.encode() + b'\0' + b'8\0' + b'7\0'
    stderr_ok = not result.stderr
    if active and fault == 'stage-missing':
        pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(str(queue) + '.merged') + r': No such file or directory\n'
        stderr_ok = bool(re.fullmatch(pattern, result.stderr.decode()))
    events = (root / 'events').read_text().splitlines() if (root / 'events').exists() else []
    if result.returncode or result.stdout != wanted or not stderr_ok or events != calls or inventory(root) != expected:
        raise AssertionError(dict(profile=profile, fault=fault, terminated=terminated, returncode=result.returncode,
                                  stdout=result.stdout, expected_stdout=wanted, stderr=result.stderr,
                                  events=events, expected_events=calls, inventory_matches=inventory(root) == expected))


def main():
    failures = []; count = 0
    for profile in PROFILES:
        for fault in FAULTS:
            for terminated in (True, False):
                count += 1
                with tempfile.TemporaryDirectory(prefix='owner-publication-test-') as temporary:
                    try: scenario(Path(temporary), profile, fault, terminated)
                    except AssertionError as error: failures.append((count, str(error)))
    if failures:
        for number, error in failures: print(f'FAIL owner publication {number}: {error}', file=sys.stderr)
        raise SystemExit(f'ELF owner publication: {count - len(failures)} pass, {len(failures)} fail')
    print(f'ELF owner publication: {count} scenarios PASS')


if __name__ == '__main__': main()
