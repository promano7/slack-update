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
step = 'phase-1-operational-joint-manuscript-audit-resume-planning-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe repository input ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, plan, sources, policy = [load(s) for s in ['entry408', 'baseline', 'plan', 'sources', 'policy']]
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
rows = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
source_blobs = {r['path']: (safe(r['path'])[len(policy['prefixes']['README.md'].encode()):] if r['path'] == 'README.md' else safe(r['path'])) for r in rows}
check('whole authored409 fixtures bound', module['validate_fixtures']({'entry408': entry, 'baseline': baseline, 'plan': plan, 'sources': sources}, policy))
check('complete actual408 receipt and all nine WHOLE external conditions', module['validate_entry'](entry, inputs, policy))
check('all109 whole JSON inputs and35 pure or inert source roots', module['validate_sources'](inputs, source_blobs, sources, policy))
check('frozen manuscript direct original14 clauses and1286 member bindings', module['validate_packet_bindings'](json.loads(inputs['packet407']), inputs))
check('finite409-418 internal audit plan and separate approval boundaries', module['validate_plan'](plan, entry, inputs, sources, policy))
check('all2194 historical408 paths unchanged except exact additive prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    actual = {p.decode() for p in raw.split(b'\0') if p}
else:
    actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG', actual == set(baseline) | set(policy['new_paths']))
mutations = [
    ('boolean schema', lambda p: p.update(schema=True)),
    ('wrong step', lambda p: p.update(step=410)),
    ('audit already completed', lambda p: p.update(state='audit-complete')),
    ('historical user full Git ID invented', lambda p: p.update(full_commit_id='0' * 40)),
    ('block request chooses option', lambda p: p.update(selected_options=['JCP400-A'])),
    ('joint specification approved', lambda p: p.update(approved_joint_specification={})),
    ('contract migration approved', lambda p: p.update(approved_contract_migration={})),
    ('implementation selected', lambda p: p.update(actual_selected_implementation={})),
    ('native graph invented', lambda p: p.update(actual_joint_native_graph={})),
    ('native evidence invented', lambda p: p.update(actual_native_evidence={})),
    ('author audit made independent impact acceptance', lambda p: p.update(independent_impact_review_accepted=True)),
    ('normative migration complete', lambda p: p.update(semantic_migration_complete=True)),
    ('original norms waived', lambda p: p.update(whole_original_requirements_remain_normative=False)),
    ('current409 pause self-confirmed', lambda p: p.update(current_strong_safe_pause=True)),
    ('block request opens native tests', lambda p: p['authorization_basis'].update(native_test_or_runtime_authorized=True)),
    ('source binding removed', lambda p: p['whole_input_references'].pop('original323')),
    ('inert native root removed', lambda p: p['whole_source_root_references'].pop(0)),
    ('whole joint dimension shortened', lambda p: p['whole_nine_joint_dimensions'][0].update(required_joint_review='short')),
    ('amendment omitted', lambda p: p['amendment_review_order'].pop()),
    ('member category omitted', lambda p: p['member_category_review_order'].pop()),
    ('roadmap shortened', lambda p: p['roadmap'].pop()),
    ('successor skips actual predecessor acceptance', lambda p: p['roadmap'][1].update(complete_predecessor_acceptance_required=408)),
    ('roadmap silently authorizes native effects', lambda p: p['roadmap'][2].update(native_execution_authorized=True)),
    ('no independent review falsely promoted', lambda p: p['roadmap'][2].update(independent_acceptance_claimed=True)),
    ('revocation review omits recovery scope', lambda p: p['roadmap'][2]['minimum_paper_challenges'].pop()),
    ('terminal receipt review replaced by producer exit', lambda p: p['roadmap'][5].update(required_result='producer exit proves final receipt')),
    ('findings may be erased', lambda p: p['audit_rules'].update(known_findings_preserved_until_explicit_disposition=False)),
    ('paper counterexample made native observation', lambda p: p['audit_rules'].update(paper_trace_is_native_observation=True)),
    ('author repair activates current contract', lambda p: p['audit_rules'].update(repair_proposal_activates_norms=True)),
    ('user approval gate omitted', lambda p: p['approval_order'].pop(0)),
    ('native grant before actual safety review', lambda p: p['approval_order'].reverse()),
    ('last confirmed pause moved to current block', lambda p: p['boundaries'].update(last_confirmed_strong_safe_pause_step=409)),
    ('unknown host declared absent', lambda p: p['boundaries'].update(actual_host_state='absent')),
    ('global host closure invented', lambda p: p['boundaries'].update(actual_global_host_closure=True)),
    ('native proof invented', lambda p: p['boundaries'].update(native_proofs_added=1)),
    ('batch cleanup demanded', lambda p: p['boundaries'].update(machine_action_required=True)),
    ('pause condition omitted', lambda p: p['pause_policy']['condition_ids'].pop()),
    ('whole nested pause reference rebound', lambda p: p['pause_policy']['condition_references'][0].update(entry_json_pointer='/confirmation')),
    ('external final confirmation omitted', lambda p: p['pause_policy'].update(external_all_nine_confirmation_required=False)),
    ('old binding revived', lambda p: p['pause_policy'].update(historical_binding_or_authority_reuse_allowed=True)),
    ('automatic419 permitted', lambda p: p['pause_policy'].update(no_automatic419=False)),
    ('future repository batch not stopped', lambda p: p['pause_policy'].update(stop_after_confirmed418=False)),
]
for label, mutate in mutations:
    altered = copy.deepcopy(plan)
    mutate(altered)
    check('reject ' + label, rejects(module['validate_plan'], altered, entry, inputs, sources, policy))
for label, mutate in [
    ('complete408 receipt truncated', lambda e: e['receipt'].update(text=e['receipt']['text'][:-1])),
    ('external whole condition truncated', lambda e: e['external_conditions']['conditions'][0]['whole_prepared408_condition'].pop('whole_original_prepared398_condition')),
    ('external historical scope expanded', lambda e: e['external_conditions'].update(scope='repository409-418')),
    ('unknown native evidence fabricated', lambda e: e['external_conditions']['conditions'][0].update(actual_native_evidence={})),
    ('external condition missing', lambda e: e['external_conditions']['conditions'].pop()),
]:
    altered = copy.deepcopy(entry)
    mutate(altered)
    check('reject ' + label, rejects(module['validate_entry'], altered, inputs, policy))
bad = dict(inputs)
bad['original323'] += b' '
check('reject original contract byte drift', rejects(module['validate_sources'], bad, source_blobs, sources, policy))
bad = dict(source_blobs)
bad[sources['inert_roots'][0]['path']] += b'\n'
check('reject inert native source drift without running it', rejects(module['validate_sources'], inputs, bad, sources, policy))
bad = copy.deepcopy(policy)
bad['expected_pause_policy']['no_automatic419'] = False
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], bad))
check('prepared result grants no native rights or independent acceptance', module['review'](entry, plan, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
forbidden = {'open', 'exec', 'eval', 'input', 'compile', '__import__'}
check('pure reviewer has only supplied-data imports and no dynamic dispatch', imports == {'hashlib', 'json', 're'} and not any(isinstance(n, ast.ImportFrom) or (isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for rel, digest in policy['artifact_sha256'].items():
    check('exact authored artifact ' + rel, module['sha'](safe(rel)) == digest)
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
