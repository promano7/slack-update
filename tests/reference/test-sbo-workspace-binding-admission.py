#!/usr/bin/env python3
"""Reject new SBo workspace preparation while either cleanup binding is unresolved."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
ERROR = 'cannot replace unresolved private SBo queue workspace binding'
PRIORS = ('empty', 'unset', 'complete', 'path-only', 'canonical-only', 'different-canonical')
PROFILES = ('missing', 'full', 'relative-source', 'relative-destination')
spec = importlib.util.spec_from_file_location('admission_support', Path(__file__).with_name('test-sbo-workspace-count.py'))
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
CANONICAL = r'''
definition=$(declare -f readlink)
eval "${definition/readlink/admission_base_readlink}"
unset definition
readlink() {
    record canonical-all "$@"
    admission_base_readlink "$@"
}
'''


def scenario(reference, root, prior_kind, profile, fault, entry):
    personal = root / 'personal'
    workspace = root / 'workspace'
    prior = root / 'prior'
    prior.mkdir(mode=0o700)
    (prior / 'keep.sqf').write_bytes(b'prior unresolved queue\n')
    (root / 'sentinel').write_bytes(b'protected\n')
    if profile != 'missing':
        (personal / 'nested').mkdir(parents=True)
        (personal / 'top.sqf').write_bytes(b'alpha\n')
        (personal / 'nested/private.sqf').write_bytes(b'beta\n')
        (personal / 'link.sqf').symlink_to('../sentinel')
    source_arg = 'relative-personal' if profile == 'relative-source' else str(personal)
    destination_arg = 'relative-workspace' if profile == 'relative-destination' else str(workspace)
    prior_path = str(prior) if prior_kind in ('complete', 'path-only', 'different-canonical') else ''
    prior_canonical = (str(root / 'different-canonical') if prior_kind == 'different-canonical'
                       else str(prior) if prior_kind in ('complete', 'canonical-only') else '')
    guarded = prior_kind not in ('empty', 'unset')
    invalid = profile in ('relative-source', 'relative-destination')
    count_failed = not guarded and profile == 'full' and fault == 'wc-43'
    failed = guarded or invalid or count_failed
    copied = 2 if not failed and profile == 'full' else 0
    links = 1 if copied else 0
    error = (ERROR if guarded else 'personal SBo queue directory is not absolute: ' + source_arg
             if profile == 'relative-source' else 'private SBo queue workspace is not absolute: ' + destination_arg
             if profile == 'relative-destination' else 'cannot count personal SBo queue symlinks: ' + str(personal)
             if count_failed else '')
    if guarded:
        owned = prior_path
        canonical = prior_canonical
    elif invalid:
        owned = canonical = '<unset>' if prior_kind == 'unset' else ''
    else:
        owned = canonical = '' if count_failed else str(workspace)
    counters = (8, 7) if guarded else (copied, links)
    state = ['0' if entry == 'sync' else '17',
             '1' if entry == 'sync' and failed else '0' if entry == 'sync' else '18',
             '0' if entry == 'sync' and failed else '1' if entry == 'sync' else '9',
             '' if entry == 'sync' and failed else str(root / 'old-source') if failed else str(workspace),
             str(counters[0]), str(counters[1]), error, owned, canonical,
             str(root / 'private.conf') if entry == 'sync' and not failed else 'old-conf']
    before = fixture.inventory(root)
    expected = before.copy()
    if not failed:
        expected['workspace'] = ('dir', 0o700)
        if copied:
            expected['workspace/nested'] = ('dir', 0o700)
            expected['workspace/top.sqf'] = ('file', b'alpha\n', 0o600)
            expected['workspace/nested/private.sqf'] = ('file', b'beta\n', 0o600)
    values = dict(PERSONAL=source_arg, WORKSPACE=destination_arg, FAULT=fault, CLEANUP='none',
                  symlink_count='outer-count-sentinel', SBOPKG_SYNC_STATUS=17, SQG_SYNC_STATUS=18,
                  SBO_QUEUE_GENERATION_READY=9, SBO_QUEUE_SOURCE_DIR=root / 'old-source',
                  SBO_PERSONAL_QUEUE_FILE_COUNT=8, SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,
                  SBO_TARGET_SELECTION_ERROR='old-error', SBO_GENERATED_QUEUE_OWNED_PATH=prior_path,
                  SBO_GENERATED_QUEUE_OWNED_CANONICAL=prior_canonical, SBO_PRIVATE_SBOPKG_CONFIG='old-conf',
                  SBO_GENERATED_QUEUE_DIR=destination_arg, SBOPKG_CONFIG=root / 'original.conf',
                  SBOPKG_CONF='outer-conf', QUEUEDIR='outer-queue')
    script = fixture.PREFIX + CANONICAL + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in fixture.GUARDS) + '\n'
    script += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    if prior_kind == 'unset':
        script += '\nunset SBO_GENERATED_QUEUE_OWNED_PATH SBO_GENERATED_QUEUE_OWNED_CANONICAL\n'
    script += "\nIFS='|: '\nsaved_ifs=$IFS\n"
    script += ('synchronize_sbo_repository' if entry == 'sync' else 'prepare_private_sbo_queue_workspace "$PERSONAL" "$WORKSPACE"')
    script += '\nraw=$?\n[[ $symlink_count == outer-count-sentinel && $IFS == "$saved_ifs" && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '-<unset>}"' for name in fixture.FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script,
                             'binding-admission-test', str(reference), str(root)], capture_output=True,
                            timeout=10, cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root), BASH_ENV='/dev/null'))
    output = ''
    main = [('discover', 'sbopkg'), ('discover', 'sqg'), ('sbopkg', '-r'), ('resolve',)] if entry == 'sync' else []
    main += [('workspace', source_arg, destination_arg), ('workspace-return', 1 if failed else 0)]
    if entry == 'sync':
        output = '[5] Sync SBo\n'
        if failed:
            output += '  [ERROR] ' + error + '\n'
        else:
            main += [('config', str(root / 'original.conf'), destination_arg), ('sqg', '-a')]
            output += (f'  Personal queue directory preserved read-only: {source_arg}\n'
                       f'  Private sqg workspace: {destination_arg}\n  Personal queue files copied: {copied}\n')
            if links:
                output += '  [WARN] Personal queue symlinks ignored: 1\n'
    wanted = output.encode() + b'\0STATE\0' + (b'1' if failed and entry == 'direct' else b'0') + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (prior_kind, profile, fault, entry, result.returncode, result.stdout, wanted, result.stderr)
    names = ('main', 'regular-find', 'link-find', 'count', 'removal', 'canonical', 'copy', 'canonical-all')
    logs = {name: (root / (name + '.events')).read_bytes() if (root / (name + '.events')).exists() else b'' for name in names}
    assert logs['main'] == fixture.encode(main)
    active = not guarded and profile == 'full'
    assert logs['regular-find'] == (fixture.encode([(source_arg, '-type', 'f', '-name', '*.sqf', '-print0')]) if active else b'')
    assert logs['link-find'] == (fixture.encode([(source_arg, '-type', 'l', '-name', '*.sqf', '-printf', '.')]) if active else b'')
    assert logs['count'] == (fixture.encode([('-c',)]) if active else b'')
    removal = [('listing', '-f')]
    if count_failed:
        removal.append(('owned-workspace', '-rf', '--', destination_arg))
    assert logs['removal'] == (fixture.encode(removal) if active else b'')
    assert logs['canonical'] == (fixture.encode([('-m', '--', destination_arg)]) if count_failed else b'')
    canonical_calls = [] if guarded or invalid else [('-m', '--', source_arg), ('-m', '--', destination_arg)]
    if count_failed:
        canonical_calls.append(('-m', '--', destination_arg))
    assert logs['canonical-all'] == fixture.encode(canonical_calls)
    copies = []
    if copied:
        for relative in ('nested/private.sqf', 'top.sqf'):
            copies += [('install', '-m', '0600', '/dev/null', str(workspace / relative)), ('cat', '--', str(personal / relative))]
    assert logs['copy'] == fixture.encode(copies)
    assert fixture.inventory(root) == expected
    assert all(fixture.inventory(root)[name] == row for name, row in before.items())
    return dict(prior=prior_kind, profile=profile, fault=fault, entry=entry, admission_rejected=guarded,
                earlier_counters_preserved=guarded, count_failed=count_failed, invalid_path=invalid and not guarded)


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix="sbo admission's ") as directory:
        for number, case in enumerate(itertools.product(PRIORS, PROFILES, ('none', 'wc-43'), ('direct', 'sync'))):
            root = Path(directory).resolve() / str(number)
            root.mkdir()
            rows.append(scenario(REFERENCE, root, *case))
    assert len(rows) == 96 and sum(row['admission_rejected'] for row in rows) == 64
    print('SBo workspace binding admission: 96 scenarios, 0 failures')


if __name__ == '__main__':
    main()
