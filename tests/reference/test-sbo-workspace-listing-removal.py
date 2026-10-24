#!/usr/bin/env python3
"""Check final private SBo listing removal before helper/sync publication."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT/'tools/reference/slack-update-reference.sh'
spec = importlib.util.spec_from_file_location('workspace_count_support',
    Path(__file__).with_name('test-sbo-workspace-count.py'))
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
FAULTS = ('none', 'quiet-1', 'quiet-43', 'stderr-127', 'removed-43')
REMOVAL = r'''
rm() {
    if [[ $# == 2 && $1 == -f && $2 == "$TEST_ROOT/"tmp.* ]]; then
        record removal listing -f
        case "$FINAL_FAULT" in
            quiet-1) return 1 ;;
            quiet-43) return 43 ;;
            stderr-127) builtin printf 'supplied final listing removal failure\n' >&2; return 127 ;;
            removed-43) builtin command rm "$@" || return; return 43 ;;
        esac
    elif [[ $# == 3 && $1 == -rf && $2 == -- && $3 == "$WORKSPACE" ]]; then
        record removal owned-workspace "$@"
        [[ $CLEANUP != owned-fail ]] || return 43
    else forbidden final-remove-vector; fi
    builtin command rm "$@"
}
'''


def scenario(reference, root, profile, fault, entry, cleanup='none'):
    personal = root/'personal'
    workspace = root/'workspace'
    (root/'sentinel').write_bytes(b'untouched\n')
    if profile != 'missing':
        personal.mkdir()
    if profile == 'full':
        (personal/'nested').mkdir()
        (personal/'top.sqf').write_bytes(b'alpha\n')
        (personal/'nested/private.sqf').write_bytes(b'beta\n')
        (personal/'note.txt').write_bytes(b'preserved\n')
        (personal/'link.sqf').symlink_to('../sentinel')
        (personal/'nested/link.sqf').symlink_to('../../sentinel')
    before = fixture.inventory(root)
    expected = before.copy()
    existing = profile != 'missing'
    failed = existing and fault != 'none'
    retained = failed and cleanup in ('owned-fail', 'canonical-fail', 'mismatch')
    listing_retained = failed and fault != 'removed-43'
    copied = 2 if profile == 'full' else 0
    links = 2 if profile == 'full' else 0
    error = 'cannot remove personal SBo queue listing' if failed else ''
    raw = 1 if failed and entry == 'direct' else 0
    owned = str(workspace) if not failed or retained else ''
    source = str(root/'old-source') if failed and entry == 'direct' else '' if failed else str(workspace)
    state = ['0' if entry == 'sync' else '17',
        '1' if entry == 'sync' and failed else '0' if entry == 'sync' else '18',
        '0' if entry == 'sync' and failed else '1' if entry == 'sync' else '9',
        source, str(copied), str(links), error, owned, owned,
        str(root/'private.conf') if entry == 'sync' and not failed else 'old-conf']
    values = dict(PERSONAL=personal, WORKSPACE=workspace, FAULT='none', CLEANUP=cleanup, FINAL_FAULT=fault,
        symlink_count='outer-count-sentinel', SBOPKG_SYNC_STATUS=17, SQG_SYNC_STATUS=18,
        SBO_QUEUE_GENERATION_READY=9, SBO_QUEUE_SOURCE_DIR=root/'old-source',
        SBO_PERSONAL_QUEUE_FILE_COUNT=8, SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,
        SBO_TARGET_SELECTION_ERROR='old-error', SBO_GENERATED_QUEUE_OWNED_PATH='',
        SBO_GENERATED_QUEUE_OWNED_CANONICAL='', SBO_PRIVATE_SBOPKG_CONFIG='old-conf',
        SBO_GENERATED_QUEUE_DIR=workspace, SBOPKG_CONFIG=root/'original.conf',
        SBOPKG_CONF='outer-conf', QUEUEDIR='outer-queue')
    script = fixture.PREFIX + REMOVAL
    script += '\n'+'\n'.join(n+'() { forbidden '+n+'; }' for n in fixture.GUARDS)+'\n'
    script += '\n'.join(n+'='+shlex.quote(str(v)) for n, v in values.items())
    script += "\nIFS='|: '\nsaved_ifs=$IFS\n"
    script += ('synchronize_sbo_repository' if entry == 'sync' else
               'prepare_private_sbo_queue_workspace "$PERSONAL" "$WORKSPACE"')+'\nraw=$?\n'
    script += '[[ $symlink_count == outer-count-sentinel && $IFS == "$saved_ifs" && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${'+n+'}"' for n in fixture.FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script, 'workspace-listing-removal',
        str(reference), str(root)], capture_output=True, cwd=root, timeout=10,
        env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    main = [('discover', 'sbopkg'), ('discover', 'sqg'), ('sbopkg', '-r'), ('resolve',)] if entry == 'sync' else []
    main += [('workspace', str(personal), str(workspace)), ('workspace-return', 1 if failed else 0)]
    output = ''
    if entry == 'sync':
        output = '[5] Sync SBo\n'
        if failed:
            output += '  [ERROR] '+error+'\n'
        else:
            main += [('config', str(root/'original.conf'), str(workspace)), ('sqg', '-a')]
            output += (f'  Personal queue directory preserved read-only: {personal}\n'
                f'  Private sqg workspace: {workspace}\n'
                f'  Personal queue files copied: {copied}\n')
            if links:
                output += f'  [WARN] Personal queue symlinks ignored: {links}\n'
    wanted = output.encode()+b'\0STATE\0'+str(raw).encode()+b'\0'+b''.join(v.encode()+b'\0' for v in state)
    stderr = b'supplied final listing removal failure\n' if existing and fault == 'stderr-127' else b''
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, stderr), (
        profile, fault, entry, cleanup, result.returncode, result.stdout, wanted, result.stderr)
    names = ('main', 'regular-find', 'link-find', 'count', 'removal', 'canonical', 'copy')
    logs = {n: (root/(n+'.events')).read_bytes() if (root/(n+'.events')).exists() else b'' for n in names}
    assert logs['main'] == fixture.encode(main), (profile, fault, entry, cleanup, 'main vectors')
    assert logs['regular-find'] == (fixture.encode([(str(personal), '-type', 'f', '-name', '*.sqf', '-print0')]) if existing else b'')
    assert logs['link-find'] == (fixture.encode([(str(personal), '-type', 'l', '-name', '*.sqf', '-printf', '.')]) if existing else b'')
    assert logs['count'] == (fixture.encode([('-c',)]) if existing else b'')
    removals = [('listing', '-f')] if existing else []
    if failed and cleanup not in ('canonical-fail', 'mismatch'):
        removals.append(('owned-workspace', '-rf', '--', str(workspace)))
    assert logs['removal'] == fixture.encode(removals), (profile, fault, entry, cleanup, 'removal vectors')
    assert logs['canonical'] == (fixture.encode([('-m', '--', str(workspace))]) if failed else b'')
    copies = []
    if not failed or retained:
        expected['workspace'] = ('dir', 0o700)
        if copied:
            expected['workspace/nested'] = ('dir', 0o700)
            expected['workspace/top.sqf'] = ('file', b'alpha\n', 0o600)
            expected['workspace/nested/private.sqf'] = ('file', b'beta\n', 0o600)
    if copied:
        for relative in ('nested/private.sqf', 'top.sqf'):
            copies += [('install', '-m', '0600', '/dev/null', str(workspace/relative)),
                       ('cat', '--', str(personal/relative))]
    assert logs['copy'] == fixture.encode(copies)
    listings = list(root.glob('tmp.*'))
    assert len(listings) == int(listing_retained), (profile, fault, entry, cleanup, 'listing inventory')
    listing_bytes = b''.join((str(personal/r)+'\0').encode() for r in ('nested/private.sqf', 'top.sqf')) if copied else b''
    if listings:
        expected[listings[0].name] = ('file', listing_bytes, 0o600)
    actual = fixture.inventory(root)
    assert actual == expected, (profile, fault, entry, cleanup, 'private inventory')
    assert all(actual[n] == row for n, row in before.items())
    return dict(profile=profile, fault=fault, entry=entry, cleanup=cleanup,
        rejected_final_removal_failure=failed, helper_status=1 if failed else 0, raw_status=raw,
        workspace_retained=retained, listing_retained=listing_retained, copied_files=copied,
        symlinks=links, source_published=not failed, sqg_entered=entry == 'sync' and not failed)


def cases():
    selected = list(itertools.product(('missing', 'empty', 'full'), FAULTS, ('direct', 'sync')))
    selected += [(*case, cleanup) for case in itertools.product(('empty', 'full'),
        ('quiet-43', 'removed-43'), ('direct', 'sync')) for cleanup in ('owned-fail', 'canonical-fail', 'mismatch')]
    return selected


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix='slack-update-workspace-listing-') as tmp:
        for number, case in enumerate(cases()):
            root = Path(tmp).resolve()/str(number)
            root.mkdir()
            rows.append(scenario(REFERENCE, root, *case))
    assert len(rows) == 54 and sum(r['rejected_final_removal_failure'] for r in rows) == 40
    assert sum(r['listing_retained'] for r in rows) == 24
    assert sum(r['workspace_retained'] for r in rows) == 24
    print('SBo workspace final listing removal: 54 scenarios, 0 failures')


if __name__ == '__main__':
    main()
