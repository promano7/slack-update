#!/usr/bin/env python3
"""Characterize cleanup binding loss on the exact pre-repair step-523 source."""
import hashlib
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tools/reference/slack-update-reference.sh'
EXPECTED = '524f6910daab586bc4fed4682e31f365a3e988a11c254add904f0ce4a31f56ae'
CASES = ('absent', 'normal', 'readlink-failure', 'rm-failure', 'canonical-mismatch', 'symlink')
SHELL = r'''
source "$1"
root=$2
kind=$3
workspace="$root/workspace"
real="$root/real"
mkdir -- "$real"
printf 'sentinel\n' > "$real/sentinel"
if [[ $kind == symlink ]]; then
    ln -s -- "$real" "$workspace"
else
    mkdir -- "$workspace"
    printf 'queue\n' > "$workspace/personal.sqf"
fi
SBO_GENERATED_QUEUE_OWNED_PATH=$workspace
SBO_GENERATED_QUEUE_OWNED_CANONICAL=$workspace
[[ $kind != absent ]] || SBO_GENERATED_QUEUE_OWNED_PATH=
readlink() {
    [[ $# == 3 && $1 == -m && $2 == -- && $3 == "$workspace" ]] || exit 91
    printf 'readlink\n' >> "$root/events"
    case "$kind" in
        readlink-failure) return 43 ;;
        canonical-mismatch) printf '%s\n' "$real" ;;
        *) command readlink "$@" ;;
    esac
}
rm() {
    [[ $# == 3 && $1 == -rf && $2 == -- && $3 == "$workspace" ]] || exit 92
    printf 'rm\n' >> "$root/events"
    [[ $kind != rm-failure ]] || return 43
    command rm "$@"
}
remove_owned_sbo_queue_workspace
first=$?
first_path=$SBO_GENERATED_QUEUE_OWNED_PATH
first_canonical=$SBO_GENERATED_QUEUE_OWNED_CANONICAL
remove_owned_sbo_queue_workspace
second=$?
printf '%s\0' "$first" "$second" "$first_path" "$first_canonical" \
    "$SBO_GENERATED_QUEUE_OWNED_PATH" "$SBO_GENERATED_QUEUE_OWNED_CANONICAL"
'''


def main():
    if hashlib.sha256(SOURCE.read_bytes()).hexdigest() != EXPECTED:
        raise SystemExit('REFUSE: source-bound defect audit requires exact step-523 source')
    observed = 0
    for kind in CASES:
        with tempfile.TemporaryDirectory(prefix='cleanup-binding-audit-') as directory:
            root = Path(directory)
            result = subprocess.run(['bash', '--noprofile', '--norc', '-c', SHELL,
                                     'cleanup-audit', str(SOURCE), str(root), kind],
                                    capture_output=True, timeout=10,
                                    env=dict(os.environ, LC_ALL='C', BASH_ENV='/dev/null'))
            assert result.returncode == 0 and not result.stderr, (kind, result)
            workspace = root / 'workspace'
            retained_binding = kind in ('readlink-failure', 'rm-failure')
            lost = kind in ('canonical-mismatch', 'symlink')
            first = '1' if retained_binding or lost else '0'
            second = '1' if retained_binding else '0'
            path = str(workspace) if retained_binding else ''
            canonical = str(workspace) if retained_binding or kind == 'absent' else ''
            expected = [first, second, path, canonical, path, canonical]
            assert result.stdout == ('\0'.join(expected) + '\0').encode(), (kind, result.stdout, expected)
            events = (root / 'events').read_text().splitlines() if (root / 'events').exists() else []
            expected_events = ([] if kind == 'absent' else ['readlink', 'rm'] if kind == 'normal'
                               else ['readlink', 'rm', 'readlink', 'rm'] if kind == 'rm-failure'
                               else ['readlink', 'readlink'] if kind == 'readlink-failure' else ['readlink'])
            assert events == expected_events, (kind, events)
            assert workspace.exists() == (kind != 'normal'), kind
            assert workspace.is_symlink() == (kind == 'symlink'), kind
            assert (root / 'real/sentinel').read_bytes() == b'sentinel\n', kind
            if kind not in ('normal', 'symlink'):
                assert (workspace / 'personal.sqf').read_bytes() == b'queue\n', kind
            observed += lost
            print('OBSERVED ' + kind + ': first=' + first + ' second=' + second
                  + ' binding=' + ('retained' if retained_binding else 'empty')
                  + ' resource=' + ('removed' if kind == 'normal' else 'retained'))
    assert observed == 2
    print('PASS AUDIT524: 6 characterizations; 2 binding-loss defects observed; not safety passes')


if __name__ == '__main__':
    main()
