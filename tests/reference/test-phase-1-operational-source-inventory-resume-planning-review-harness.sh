#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy
import hashlib
import json
import runpy
import sys

root = Path(sys.argv[1])
name = 'phase-1-operational-source-inventory-resume-planning-review'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
module = runpy.run_path(str(root / 'tools/reference' / (name + '.py')))
passes = 0
def check(label, result):
    global passes
    if not result:
        raise AssertionError(label)
    passes += 1
    print('PASS: ' + label, flush=True)
def rejected(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, TypeError):
        return True
    return False
def load(tail):
    return json.loads((fixture / (name + '-' + tail + '.json')).read_bytes())
policy = load('policy')
plan = load('plan')
confirmation = load('confirmed358')
receipt = load('step358-user-acceptance')
baseline = policy['baseline_sha256']
check('all1809 accepted source bindings retained', len(baseline) == policy['accepted_source_count'] == 1809)
history = {}
for rel, digest in baseline.items():
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe accepted source: ' + rel)
    raw = p.read_bytes()
    if rel == 'CHANGELOG.md':
        raw = raw[-policy['accepted_changelog_size_bytes']:]
    if hashlib.sha256(raw).hexdigest() != digest:
        raise ValueError('accepted source drift: ' + rel)
    history[rel] = raw
check('all accepted source bytes preserved with additive CHANGELOG only', len(history) == 1809)
check('confirmation document matches carried external acceptance bytes',
      hashlib.sha256((fixture / (name + '-confirmed358.json')).read_bytes()).hexdigest() == policy['expected_confirmation_sha256'])
check('complete original358 receipt and reported scoped pause', module['validate_return'](confirmation, receipt, policy))
check('finite359-368 plan and final README requirement', module['validate_plan'](plan))
sources = {r['path']: history[r['path']] for r in policy['source_roots']}
check('four review roots exact and historical artifact roles distinct', module['validate_source_roots'](policy['source_roots'], sources))
gaps = json.loads(history[plan['requirements_retained_by_exact_binding'][0]])
check('all native gaps retained without selection or proof', module['validate_retained_gaps'](gaps, policy))
check('README left exact pending reconciliation367', hashlib.sha256((root / 'README.md').read_bytes()).hexdigest() == policy['readme_at_entry_sha256'])
check('last numbered README checkpoint120 distinguished from reconciliation173', policy['last_numbered_readme_checkpoint'] == 120 and policy['last_documentation_reconciliation_step'] == 173)
for field, value in [
    ('strong_safe_pause', False), ('actual_global_host_closure', True),
    ('commit_full', 'invented'), ('actual_live_bindings', {}),
    ('runtime_authority', True), ('native_cases_run', 52),
    ('user_worktree_clean', False), ('user_head_matches_origin', False),
    ('phase1_matrix_complete', True), ('phase2_open', True)]:
    changed = copy.deepcopy(confirmation); changed[field] = value
    check('reject changed confirmed358 ' + field, rejected(module['validate_return'], changed, receipt, policy))
for label, replacement in [
    ('truncated original receipt', receipt['text'][:-10]),
    ('same-length original receipt edit', receipt['text'].replace('292 passes', '291 passes', 1)),
    ('injected status output', receipt['text'].replace('64b63ed (HEAD', ' M README.md\n64b63ed (HEAD', 1)),
    ('reordered PASS labels', receipt['text'].replace(policy['expected_ordered358_labels'][0], policy['expected_ordered358_labels'][1], 1))]:
    changed = copy.deepcopy(receipt); changed['text'] = replacement
    check('reject ' + label, rejected(module['validate_return'], confirmation, changed, policy))
for label, mutate in [
    ('README reconciliation omitted', lambda p: p.update(readme_reconciliation_step=None)),
    ('premature pause confirmation', lambda p: p['boundaries'].update(current_step_strong_safe_pause=True)),
    ('machine authority', lambda p: p['boundaries'].update(runtime_authority=True)),
    ('native successor selection', lambda p: p['boundaries'].update(native_successor_selected=True)),
    ('historical authority reuse', lambda p: p['boundaries'].update(historical_authority_reuse_allowed=True)),
    ('unknown host claimed absent', lambda p: p['boundaries'].update(actual_host_state='absent')),
    ('skipped predecessor acceptance', lambda p: p['roadmap'][1].update(entry_requires_confirmed_step=358)),
    ('runtime stage', lambda p: p['roadmap'][2].update(runtime_authorized=True)),
    ('extra stage beyond368', lambda p: p['roadmap'].append(copy.deepcopy(p['roadmap'][-1]))),
    ('deleted retained contract', lambda p: p['requirements_retained_by_exact_binding'].pop()),
    ('unknown roadmap authority field', lambda p: p['roadmap'][0].update(native_runner='bash')),
    ('bool masquerading as integer', lambda p: p.update(schema=True))]:
    changed = copy.deepcopy(plan); mutate(changed)
    check('reject ' + label, rejected(module['validate_plan'], changed))
for label, mutate in [
    ('traversal source', lambda rs: rs[0].update(path='../slack-update-reference.sh')),
    ('duplicate source root', lambda rs: rs.__setitem__(1, copy.deepcopy(rs[0]))),
    ('historical executable made runnable', lambda rs: rs[3].update(execution_authorized=True)),
    ('generated artifact counted as independent worker', lambda rs: rs[3].update(role=rs[1]['role'])),
    ('false native binding', lambda rs: rs[0].update(actual_native_binding={'host': 'claimed'})),
    ('source hash substitution', lambda rs: rs[0].update(sha256='0'*64))]:
    changed = copy.deepcopy(policy['source_roots']); mutate(changed)
    check('reject ' + label, rejected(module['validate_source_roots'], changed, sources))
changed_sources = dict(sources); changed_sources[next(iter(sources))] += b'\n'
check('reject drift in source bytes', rejected(module['validate_source_roots'], policy['source_roots'], changed_sources))
changed = copy.deepcopy(gaps); changed['full_original_native_gap_rows348'][0]['native_status_promoted'] = True
check('reject lexical review promoted to native proof', rejected(module['validate_retained_gaps'], changed, policy))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
