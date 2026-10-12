#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast
import copy
import json
import runpy
import subprocess
import sys

root = Path(sys.argv[1])
step = 'phase-1-operational-joint-contract-proposal-resume-planning-review'
prefix = root / 'tests/fixtures/reference/acceptance/phase-1'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe repository input ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, plan, sources, policy = [load(s) for s in ['entry398', 'baseline', 'plan', 'sources', 'policy']]
module = runpy.run_path(str(root / 'tools/reference' / (step + '.py')))
passes = 0
def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)
def rejects(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, IndexError, TypeError):
        return True
    return False
inputs = {k: safe(v['path']) for k, v in sources['inputs'].items()}
inputs['receipt398_raw'] = entry['receipt']['text'].encode('utf-8')
rows = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
source_blobs = {row['path']: (safe(row['path'])[len(policy['prefixes']['README.md'].encode()):] if row['path'] == 'README.md' else safe(row['path'])) for row in rows}
check('whole authored399 fixtures independently bound', module['validate_fixtures']({'entry398': entry, 'baseline': baseline, 'plan': plan, 'sources': sources}, policy))
check('all70 whole original JSON inputs and25 source roots retained', module['validate_sources'](inputs, source_blobs, sources, policy))
check('complete accepted398 receipt and nine whole external conditions', module['validate_entry'](entry, inputs, policy))
check('finite joint plan retains whole original scope and closed approvals', module['validate_plan_shape'](plan, inputs, sources, policy))
check('all2114 accepted398 files unchanged except exact additive prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    actual = {x.decode() for x in raw.split(b'\0') if x}
else:
    actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG scope', actual == set(baseline) | set(policy['new_paths']))
mutations = [
    ('boolean schema', lambda p: p.update(schema=True)),
    ('selected options invented', lambda p: p.update(selected_options=['test'])),
    ('draft already chosen', lambda p: p.update(draft_candidate={})),
    ('joint approval invented', lambda p: p.update(approved_joint_specification={})),
    ('contract migration invented', lambda p: p.update(approved_contract_migration={})),
    ('native graph invented', lambda p: p.update(actual_joint_native_graph={})),
    ('full Git ID invented', lambda p: p.update(full_commit_id='0' * 40)),
    ('native authority opened', lambda p: p['boundaries'].update(runtime_authority=True)),
    ('native proof invented', lambda p: p['boundaries'].update(native_proofs_added=1)),
    ('unknown host made absent', lambda p: p['boundaries'].update(actual_host_state='absent')),
    ('global closure invented', lambda p: p['boundaries'].update(actual_global_host_closure=True)),
    ('original contract made inactive', lambda p: p.update(whole_original_requirements_remain_normative=False)),
    ('whole decision truncated', lambda p: p['whole_original_decisions'].pop()),
    ('joint dimension truncated', lambda p: p['whole_joint_review_dimensions'].pop()),
    ('original requirement shortened', lambda p: p['whole_original_decisions'][0]['whole_original_conflict'].update(unresolved_requirement='short')),
    ('source input removed', lambda p: p['whole_input_references'].pop('original320')),
    ('draft choice promoted to user selection', lambda p: p['joint_draft_rules'].update(author_draft_choice_is_user_selection=True)),
    ('migration impact promoted to approval', lambda p: p.update(independent_impact_review_accepted=True)),
    ('migration complete invented', lambda p: p.update(semantic_migration_complete=True)),
    ('runtime authorized by block request', lambda p: p['authorization_basis'].update(native_test_or_runtime_authorized=True)),
    ('successor skips acceptance', lambda p: p['roadmap'][1].update(complete_predecessor_acceptance_required=398)),
    ('roadmap shortened', lambda p: p['roadmap'].pop()),
    ('whole entry obligation replaced with three calls', lambda p: p['roadmap'][7].update(required_result='three calls suffice')),
    ('conditional pause asserted now', lambda p: p['boundaries'].update(current_step_strong_safe_pause=True)),
    ('pause condition removed', lambda p: p['pause_policy']['original_condition_ids'].pop()),
    ('automatic409 allowed', lambda p: p['pause_policy'].update(no_automatic409=False)),
    ('old bindings reused', lambda p: p['pause_policy'].update(historical_binding_or_authority_reuse_allowed=True))]
for label, mutate in mutations:
    altered = copy.deepcopy(plan)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(module['validate_plan_shape'], altered, inputs, sources, policy))
for label, mutate in [
    ('truncated receipt', lambda e: e['receipt'].update(text=e['receipt']['text'][:-1])),
    ('whole external condition truncated', lambda e: e['external_conditions']['conditions'][0]['whole_prepared398_condition'].pop('full_original_prepared_condition388')),
    ('external native evidence invented', lambda e: e['external_conditions']['conditions'][0].update(actual_native_evidence={})),
    ('external confirmation missing', lambda e: e['external_conditions']['conditions'].pop())]:
    altered = copy.deepcopy(entry)
    mutate(altered)
    check('reject ' + label, rejects(module['validate_entry'], altered, inputs, policy))
bad_inputs = dict(inputs)
bad_inputs['original324'] += b' '
check('reject original contract byte drift', rejects(module['validate_sources'], bad_inputs, source_blobs, sources, policy))
bad_policy = copy.deepcopy(policy)
bad_policy['expected_pause_policy']['no_automatic409'] = False
check('reject coordinated policy substitution', rejects(module['validate_policy'], bad_policy))
check('prepared result has no selection native rights or current pause', module['review'](entry, plan, sources, inputs, source_blobs, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('reviewer imports only supplied-data libraries', imports == {'hashlib', 'json', 're'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
