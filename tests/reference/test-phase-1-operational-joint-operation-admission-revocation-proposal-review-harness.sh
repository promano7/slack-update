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
step = 'phase-1-operational-joint-operation-admission-revocation-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry401', 'baseline', 'review', 'sources', 'policy']]
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
roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
source_blobs = {r['path']: (safe(r['path'])[len(policy['prefixes']['README.md'].encode()):] if r['path'] == 'README.md' else safe(r['path'])) for r in roots}
check('whole authored402 entry baseline review sources independently bound', module['validate_fixtures']({'entry401': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual401 supplied receipt60PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all79 whole inputs and28 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('full original scoped admission revocation clauses and finite envelope requirements retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2138 accepted401 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    inventory = {p.decode() for p in raw.split(b'\0') if p}
else:
    inventory = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG scope', inventory == set(baseline) | set(policy['new_paths']))
def shape(c):
    return module['validate_review_shape'](c, inputs, sources, policy)
mutations = [
    ('boolean schema',lambda c:c.update(schema=True)),
    ('selected options invented',lambda c:c.update(selected_options=['test'])),
    ('approved contract invented',lambda c:c.update(approved_contract_migration={})),
    ('runtime opened',lambda c:c.update(runtime_authority=True)),
    ('native case invented',lambda c:c.update(native_cases_run=1)),
    ('normative original waived',lambda c:c.update(whole_original_requirements_remain_normative=False)),
    ('whole fence shortened',lambda c:c['whole_original323_contracts']['fence_contract'].pop('rule')),
    ('offline FD denial removed',lambda c:c['whole_original321_bootstrap_authentication_fd_loss']['fd_policy']['denied'].pop()),
    ('worker service channel introduced',lambda c:c['complete_operation_envelope_requirements'].update(worker_channel_exception=True)),
    ('recovery additional loss hidden',lambda c:c['additional_joint_guarantee_losses'].pop(1)),
    ('recovery validity replacement omitted',lambda c:c['exact_inactive_clause_replacements'].pop(5)),
    ('original clause rebound',lambda c:c['exact_inactive_clause_replacements'][0].update(whole_current_clause='short')),
    ('replacement approved',lambda c:c['exact_inactive_clause_replacements'][0].update(replacement_approved=True)),
    ('deadline extended',lambda c:c['scope_revocation_policy'][1].update(fixed_bounds_may_extend=True)),
    ('scope borrowed from forward',lambda c:c['scope_revocation_policy'][1].update(applicable_request_values=['forward'])),
    ('evidence new right minted',lambda c:c.update(evidence_has_its_own_new_grant=True)),
    ('service first-effects barrier weakened',lambda c:c.update(policy_admission_launch_bootstrap_service_windows_amended=True)),
    ('one node omitted',lambda c:c['whole_original30_node_questions'].pop()),
    ('one ordered edge omitted',lambda c:c['whole_original95_edges'].pop()),
    ('one authority window omitted',lambda c:c['whole_original9_authority_windows'].pop()),
    ('operation partition claimed actual',lambda c:c.update(actual_operation_partition={})),
    ('enforcer selected',lambda c:c.update(actual_native_enforcer_or_transport={})),
    ('backend exit made known drain',lambda c:c.update(safe_stop_known_from_request_or_backend_exit=True)),
    ('no-channel compatibility proved',lambda c:c.update(native_no_channel_enforcement_resolved=True)),
    ('forward failure erased on restore',lambda c:c.update(original_forward_failure_survives_recovery_and_publication=False)),
    ('all23 papercases shortened',lambda c:c['authored_hypothetical_cases'].pop()),
    ('native paper evidence invented',lambda c:c['authored_hypothetical_cases'][0].update(actual_native_evidence={})),
    ('joint question deleted',lambda c:c['remaining_joint_reviews'].pop()),
    ('semantic migration declared complete',lambda c:c.update(semantic_migration_complete=True)),
    ('new pause claimed',lambda c:c['boundaries'].update(strong_safe_pause=True)),
    ('automatic409 opened',lambda c:c.update(no_automatic409=False))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual401 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_sections']['complete_operation_envelope_requirements']['worker_channel_exception'] = True
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
for case in proposal['authored_hypothetical_cases']:
    result=module['hypothetical_case'](case,policy)
    check('paper scoped revocation witness '+case['id'],result['proposed_disposition']==case['expected_proposed_disposition'] and result['original_revocation_disposition']==case['expected_original_revocation_disposition'] and result['runtime_authority'] is False and result['native_proof'] is False and result['actual_native_admission_or_drain'] is None and result['actual_closed'] is False)
case=copy.deepcopy(proposal['authored_hypothetical_cases'][13]);result=module['hypothetical_case'](case,policy)
check('known mismatch retained alongside pending unknown request',result['pending_inputs_present'] is True and 'known-original-mismatch' in result['known_failures_preserved'])
case=copy.deepcopy(proposal['authored_hypothetical_cases'][4]);result=module['hypothetical_case'](case,policy)
check('original forward failure retained during recovery proposal', 'original-forward-failure' in result['known_failures_preserved'])
case['deadline_tick']=True
check('reject boolean deadline masquerading as finite integer',rejects(module['hypothetical_case'],case,policy))
case['deadline_tick']=20;case['hypothetical_only']=False
check('reject paper evaluator used as actual permission policy',rejects(module['hypothetical_case'],case,policy))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
