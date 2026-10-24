#!/usr/bin/env python3
"""Characterize replacement of preexisting SBo cleanup bookkeeping on exact526 source."""
import hashlib
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
SOURCE_SHA256 = 'b0f2bd8d4af6685ffad8f85f9b19ca0f83509532e3e76408fc2728a254bbe976'
spec = importlib.util.spec_from_file_location('workspace_audit_support', Path(__file__).with_name('test-sbo-workspace-count.py'))
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
PRIORS = ('empty', 'complete', 'path-only', 'canonical-only')


def scenario(reference, root, prior_kind, profile, fault, entry):
    personal = root / 'personal'
    workspace = root / 'workspace'
    prior = root / 'prior'
    prior.mkdir(mode=0o700)
    (prior / 'queue.sqf').write_bytes(b'prior unresolved queue\n')
    (root / 'sentinel').write_bytes(b'protected\n')
    if profile == 'full':
        (personal / 'nested').mkdir(parents=True)
        (personal / 'top.sqf').write_bytes(b'alpha\n')
        (personal / 'nested/private.sqf').write_bytes(b'beta\n')
        (personal / 'link.sqf').symlink_to('../sentinel')
    before = fixture.inventory(root)
    expected = before.copy()
    failed = profile == 'full' and fault == 'wc-43'
    copied = 2 if profile == 'full' and not failed else 0
    links = 1 if profile == 'full' and not failed else 0
    error = 'cannot count personal SBo queue symlinks: ' + str(personal) if failed else ''
    owned = '' if failed else str(workspace)
    state = ['0' if entry == 'sync' else '17',
             '1' if entry == 'sync' and failed else '0' if entry == 'sync' else '18',
             '0' if entry == 'sync' and failed else '1' if entry == 'sync' else '9',
             '' if entry == 'sync' and failed else str(root / 'old-source') if failed else str(workspace),
             str(copied), str(links), error, owned, owned,
             str(root / 'private.conf') if entry == 'sync' and not failed else 'old-conf']
    if not failed:
        expected['workspace'] = ('dir', 0o700)
        if profile == 'full':
            expected['workspace/nested'] = ('dir', 0o700)
            expected['workspace/top.sqf'] = ('file', b'alpha\n', 0o600)
            expected['workspace/nested/private.sqf'] = ('file', b'beta\n', 0o600)
    prior_path = str(prior) if prior_kind in ('complete', 'path-only') else ''
    prior_canonical = str(prior) if prior_kind in ('complete', 'canonical-only') else ''
    values = dict(PERSONAL=personal, WORKSPACE=workspace, FAULT=fault, CLEANUP='none',
                  symlink_count='outer-count-sentinel', SBOPKG_SYNC_STATUS=17, SQG_SYNC_STATUS=18,
                  SBO_QUEUE_GENERATION_READY=9, SBO_QUEUE_SOURCE_DIR=root / 'old-source',
                  SBO_PERSONAL_QUEUE_FILE_COUNT=8, SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,
                  SBO_TARGET_SELECTION_ERROR='old-error', SBO_GENERATED_QUEUE_OWNED_PATH=prior_path,
                  SBO_GENERATED_QUEUE_OWNED_CANONICAL=prior_canonical, SBO_PRIVATE_SBOPKG_CONFIG='old-conf',
                  SBO_GENERATED_QUEUE_DIR=workspace, SBOPKG_CONFIG=root / 'original.conf',
                  SBOPKG_CONF='outer-conf', QUEUEDIR='outer-queue')
    script = fixture.PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in fixture.GUARDS) + '\n'
    script += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    script += "\nIFS='|: '\nsaved_ifs=$IFS\n"
    script += ('synchronize_sbo_repository' if entry == 'sync' else 'prepare_private_sbo_queue_workspace "$PERSONAL" "$WORKSPACE"')
    script += '\nraw=$?\n[[ $symlink_count == outer-count-sentinel && $IFS == "$saved_ifs" && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in fixture.FIELDS)
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script,
                             'binding-replacement-audit', str(reference), str(root)], capture_output=True,
                            timeout=10, cwd=root, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root), BASH_ENV='/dev/null'))
    output = ''
    main = [('discover', 'sbopkg'), ('discover', 'sqg'), ('sbopkg', '-r'), ('resolve',)] if entry == 'sync' else []
    main += [('workspace', str(personal), str(workspace)), ('workspace-return', 1 if failed else 0)]
    if entry == 'sync':
        output = '[5] Sync SBo\n'
        if failed:
            output += '  [ERROR] ' + error + '\n'
        else:
            main += [('config', str(root / 'original.conf'), str(workspace)), ('sqg', '-a')]
            output += (f'  Personal queue directory preserved read-only: {personal}\n'
                       f'  Private sqg workspace: {workspace}\n  Personal queue files copied: {copied}\n')
            if links:
                output += '  [WARN] Personal queue symlinks ignored: 1\n'
    wanted = output.encode() + b'\0STATE\0' + (b'1' if failed and entry == 'direct' else b'0') + b'\0'
    wanted += b''.join(value.encode() + b'\0' for value in state)
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (prior_kind, profile, fault, entry, result.returncode, result.stdout, wanted, result.stderr)
    names = ('main', 'regular-find', 'link-find', 'count', 'removal', 'canonical', 'copy')
    logs = {name: (root / (name + '.events')).read_bytes() if (root / (name + '.events')).exists() else b'' for name in names}
    assert logs['main'] == fixture.encode(main)
    assert logs['regular-find'] == (fixture.encode([(str(personal), '-type', 'f', '-name', '*.sqf', '-print0')]) if profile == 'full' else b'')
    assert logs['link-find'] == (fixture.encode([(str(personal), '-type', 'l', '-name', '*.sqf', '-printf', '.')]) if profile == 'full' else b'')
    assert logs['count'] == (fixture.encode([('-c',)]) if profile == 'full' else b'')
    removal = [('listing', '-f')]
    if failed:
        removal.append(('owned-workspace', '-rf', '--', str(workspace)))
    assert logs['removal'] == (fixture.encode(removal) if profile == 'full' else b'')
    assert logs['canonical'] == (fixture.encode([('-m', '--', str(workspace))]) if failed else b'')
    copies = []
    if copied:
        for relative in ('nested/private.sqf', 'top.sqf'):
            copies += [('install', '-m', '0600', '/dev/null', str(workspace / relative)), ('cat', '--', str(personal / relative))]
    assert logs['copy'] == fixture.encode(copies)
    assert fixture.inventory(root) == expected
    assert all(fixture.inventory(root)[name] == row for name, row in before.items())
    displaced = bool(prior_path or prior_canonical)
    assert not displaced or (state[7], state[8]) != (prior_path, prior_canonical)
    return dict(prior=prior_kind, profile=profile, fault=fault, entry=entry,
                prior_binding_displaced=displaced, prior_resource_preserved=True,
                new_workspace_removed=failed, raw=1 if failed and entry == 'direct' else 0)


def main():
    if hashlib.sha256(REFERENCE.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise SystemExit('REFUSE: audit527 requires exact pre-repair526 runtime')
    rows = []
    with tempfile.TemporaryDirectory(prefix="sbo replacement's ") as directory:
        for number, case in enumerate(itertools.product(PRIORS, ('missing', 'full'), ('none', 'wc-43'), ('direct', 'sync'))):
            root = Path(directory).resolve() / str(number)
            root.mkdir()
            rows.append(scenario(REFERENCE, root, *case))
    assert len(rows) == 32 and sum(row['prior_binding_displaced'] for row in rows) == 24
    print('AUDIT527 OBSERVED: 24 preexisting binding replacements; prior resources preserved')
    print('PASS AUDIT527: 32 source-bound characterizations; 24 defect observations; not safety passes')


if __name__ == '__main__':
    main()
