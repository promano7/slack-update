#!/usr/bin/env python3
"""Compose unresolved SBo binding admission through real apply/result coordination."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


workflow = load('binding_apply_scaffold', 'test-sbo-workspace-apply-composition.py')
admission = load('binding_admission_support', 'test-sbo-workspace-binding-admission.py')
fixture = workflow.fixture
PREFIX = workflow.PREFIX + admission.CANONICAL
FIELDS = workflow.FIELDS
GUARDS = workflow.GUARDS


def scenario(reference, root, prior_kind, profile, sbo, sync_code):
    personal, workspace, prior = root / 'personal', root / 'workspace', root / 'prior'
    prior.mkdir(mode=0o700)
    (prior / 'keep.sqf').write_bytes(b'prior unresolved queue\n')
    (root / 'sentinel').write_bytes(b'protected\n')
    if profile != 'missing':
        personal.mkdir()
    if profile == 'full':
        (personal / 'nested').mkdir()
        (personal / 'top.sqf').write_bytes(b'alpha\n')
        (personal / 'nested/private.sqf').write_bytes(b'beta\n')
        (personal / 'link.sqf').symlink_to('../sentinel')
    for name in ('core', 'extra', 'options', 'final', 'broken'):
        (root / name).write_text('old-' + name + '\n')
    prior_path = str(prior) if prior_kind in ('complete', 'path-only', 'different-canonical') else ''
    prior_canonical = (str(root / 'different-canonical') if prior_kind == 'different-canonical'
                       else str(prior) if prior_kind in ('complete', 'canonical-only') else '')
    initial_path = '<unset>' if prior_kind == 'unset' else prior_path
    initial_canonical = '<unset>' if prior_kind == 'unset' else prior_canonical
    early = bool(sbo and prior_kind not in ('empty', 'unset'))
    admitted = bool(sbo and not early)
    error = admission.ERROR if early else ''
    copied = 2 if admitted and profile == 'full' else 0 if admitted else 8
    links = 1 if admitted and profile == 'full' else 0 if admitted else 7
    state = 'disabled' if not sbo else 'failed' if early or sync_code else 'success'
    before = fixture.inventory(root)
    expected = before.copy()
    for name in ('core', 'extra', 'options', 'broken'):
        expected[name] = ('file', b'', before[name][2])
    total = 2 if admitted and profile == 'full' else 0
    if admitted:
        content = b'core-a\ncore-b\n' if total else b''
        expected['core'] = ('file', content, before['core'][2])
        expected['final'] = ('file', content, before['final'][2])
        expected['workspace'] = ('dir', 0o700)
        if profile == 'full':
            expected['workspace/nested'] = ('dir', 0o700)
            expected['workspace/nested/private.sqf'] = ('file', b'beta\n', 0o600)
            expected['workspace/top.sqf'] = ('file', b'alpha\n', 0o600)
    rows, errors, output = [], [], ''
    if sbo:
        rows += [('sync',), ('discover', 'sbopkg'), ('discover', 'sqg'), ('sbopkg', '-r'), ('resolve',),
                 ('workspace', str(personal), str(workspace)), ('workspace-return', 1 if early else 0)]
        output = '[5] Sync SBo\n'
        if early:
            output += '  [ERROR] ' + error + '\n'
        else:
            rows += [('config', str(root / 'original.conf'), str(workspace)), ('sqg', '-a')]
            output += (f'  Personal queue directory preserved read-only: {personal}\n'
                       f'  Private sqg workspace: {workspace}\n  Personal queue files copied: {copied}\n')
            if links:
                output += '  [WARN] Personal queue symlinks ignored: 1\n'
        rows += [('sync-return', 0), ('action', 'sbo', 'synchronize', 'failed' if early or sync_code else 'success',
                  'SBo repository synchronization completed', sync_code if sync_code else 1 if early else 0), ('gate',)]
        if not early:
            rows += [('core',), ('abi',)]
        rows += [('gate-return', 1 if early else 0),
                 ('action', 'sbo', 'build_queues', 'failed' if early else 'success',
                  'SBo target selection failed: ' + error if early else 'Deterministic SBo target sets built', 1 if early else 0)]
        if sync_code:
            errors.append('sbopkg repository synchronization failed with exit code ' + str(sync_code))
        if early:
            errors += ['sqg queue generation failed with exit code 1', 'SBo target selection failed: ' + error]
    else:
        rows += [('action', 'sbo', 'synchronize', 'disabled', 'SBo repository synchronization was not applicable: supplied-off', 0),
                 ('action', 'sbo', 'build_queues', 'disabled', 'SBo queue generation was not applicable: supplied-off', 0)]
    if admitted:
        rows += [('process',), ('action', 'sbo', 'process_queue', state, 'Final SBo queue processing completed', 0)]
    elif sbo:
        rows.append(('action', 'sbo', 'process_queue', 'failed', 'SBo queue processing was blocked because target selection failed', 1))
    else:
        rows.append(('action', 'sbo', 'process_queue', 'disabled', 'SBo queue processing was not applicable: supplied-off', 0))
    rows += [('module', 'sbo', state, 'SBo update module completed', 1 if early else 0), ('boot-callback',),
             ('summary', 'success', 'disabled', state, 'disabled', 'disabled', 0)]
    path = str(workspace) if admitted else initial_path
    canonical = str(workspace) if admitted else initial_canonical
    fields = [2 if errors else 0, 0 if errors else 1, 1 if errors else 0, 1, 'none',
              sync_code if sbo else -1, 1 if early else 0 if sbo else -1, 1 if admitted else 0,
              1 if early else 0 if sbo else -1, 0 if admitted else -1, copied, links,
              total, 0, 0, total, total, error,
              str(workspace) if admitted else '' if sbo else str(root / 'old-source'),
              path, canonical, str(root / 'private.conf') if admitted else 'old-conf']
    values = dict(PERSONAL=personal, WORKSPACE=workspace, FAULT='none', CLEANUP='none', PROFILE=profile,
                  SBO_RUN=sbo, SYNC_CODE=sync_code, symlink_count='outer-count-sentinel',
                  SBO_PERSONAL_QUEUE_FILE_COUNT=8, SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,
                  SBO_QUEUE_SOURCE_DIR=root / 'old-source', SBO_PRIVATE_SBOPKG_CONFIG='old-conf',
                  SBO_GENERATED_QUEUE_OWNED_PATH=prior_path, SBO_GENERATED_QUEUE_OWNED_CANONICAL=prior_canonical,
                  SBO_GENERATED_QUEUE_DIR=workspace, SBOPKG_CONFIG=root / 'original.conf',
                  SBOPKG_CONF='outer-conf', QUEUEDIR='outer-queue', QUEUE_CORE=root / 'core',
                  QUEUE_EXTRA=root / 'extra', QUEUE_FINAL=root / 'final', SBO_OPTION_RECORDS=root / 'options',
                  SBO_OPTIONS_FILE=root / 'overrides', BROKEN=root / 'broken', TOTAL=0, TOTAL_CORE=6,
                  SBO_OPTION_RECORD_COUNT=5, TOTAL_EXTRA=4, OPERATION='apply', FLATPAK_MODE='disabled',
                  SBO_MODE='auto', ELF_MODE='disabled', CINNAMON_MODE='disabled', BOOT_MODE='disabled',
                  SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS)
    shell += '\ninitialize_runtime_state || exit 96\n'
    shell += '\n'.join(name + '=' + shlex.quote(str(value)) for name, value in values.items())
    if prior_kind == 'unset':
        shell += '\nunset SBO_GENERATED_QUEUE_OWNED_PATH SBO_GENERATED_QUEUE_OWNED_CANONICAL\n'
    shell += "\nIFS='|: '\naction_exit=77;sbo_state=outer-sbo\nraw=0\nrun_apply_workflow || raw=$?\ndetermine_stable_exit_code \"$raw\"\n"
    shell += '[[ $symlink_count == outer-count-sentinel && $IFS == "|: " && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue && $action_exit == 77 && $sbo_state == outer-sbo ]] || exit 95\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '-<unset>}"' for name in FIELDS)
    shell += r'''
builtin printf 'ERRORS\0';builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0';builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell,
                             'binding-apply-test', str(reference), str(root)], cwd=root, capture_output=True,
                            timeout=15, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root), BASH_ENV='/dev/null'))
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in [0, *fields])
    wanted += b'ERRORS\0' + b''.join(item.encode() + b'\0' for item in (errors or [''])) + b'WARNINGS\0\0'
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b''), (
        prior_kind, profile, sbo, sync_code, result.returncode, result.stdout, wanted, result.stderr)
    names = ('main', 'regular-find', 'link-find', 'count', 'removal', 'canonical', 'copy', 'canonical-all')
    logs = {name: (root / (name + '.events')).read_bytes() if (root / (name + '.events')).exists() else b'' for name in names}
    assert logs['main'] == fixture.encode(rows), (prior_kind, profile, sbo, sync_code, logs['main'], rows)
    active = admitted and profile != 'missing'
    assert logs['regular-find'] == (fixture.encode([(str(personal), '-type', 'f', '-name', '*.sqf', '-print0')]) if active else b'')
    assert logs['link-find'] == (fixture.encode([(str(personal), '-type', 'l', '-name', '*.sqf', '-printf', '.')]) if active else b'')
    assert logs['count'] == (fixture.encode([('-c',)]) if active else b'')
    assert logs['removal'] == (fixture.encode([('listing', '-f')]) if active else b'')
    assert logs['canonical'] == b''
    assert logs['canonical-all'] == (fixture.encode([('-m', '--', str(personal)), ('-m', '--', str(workspace))]) if admitted else b'')
    copies = []
    if admitted and profile == 'full':
        for relative in ('nested/private.sqf', 'top.sqf'):
            copies += [('install', '-m', '0600', '/dev/null', str(workspace / relative)), ('cat', '--', str(personal / relative))]
    assert logs['copy'] == fixture.encode(copies)
    assert fixture.inventory(root) == expected
    assert all(fixture.inventory(root)[name] == row for name, row in before.items()
               if name not in ('core', 'extra', 'options', 'final', 'broken'))
    return dict(prior=prior_kind, profile=profile, sbo=sbo, sync_code=sync_code,
                admission_rejected=early, raw_status=0, stable_status=2 if errors else 0,
                prior_sync_policy_reaches_supplied_build=bool(admitted and sync_code))


def main():
    rows = []
    with tempfile.TemporaryDirectory(prefix="sbo binding apply's ") as directory:
        for number, case in enumerate(itertools.product(admission.PRIORS, ('missing', 'empty', 'full'), (0, 1), (0, 43))):
            root = Path(directory).resolve() / str(number)
            root.mkdir()
            rows.append(scenario(REFERENCE, root, *case))
    assert len(rows) == 72 and sum(row['admission_rejected'] for row in rows) == 24
    assert sum(row['prior_sync_policy_reaches_supplied_build'] for row in rows) == 6
    print('SBo workspace binding apply composition: 72 scenarios, 0 failures')


if __name__ == '__main__':
    main()
