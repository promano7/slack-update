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
step = 'phase-1-operational-joint-loss-drain-clock-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry402', 'baseline', 'review', 'sources', 'policy']]
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
check('whole authored403 entry baseline review sources independently bound', module['validate_fixtures']({'entry402': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual402 supplied receipt71PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all82 whole inputs and29 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('full original loss drain clock clauses and original finite rights requirements retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2146 accepted402 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
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
    ('selection invented',lambda c:c.update(selected_options=['test'])),
    ('approved migration invented',lambda c:c.update(approved_contract_migration={})),
    ('runtime opened',lambda c:c.update(runtime_authority=True)),
    ('native case invented',lambda c:c.update(native_cases_run=1)),
    ('normative original waived',lambda c:c.update(whole_original_requirements_remain_normative=False)),
    ('whole clock rule removed',lambda c:c['whole_original323_clock_recovery_forward_closure']['clock_contract'].pop('rule')),
    ('whole independent criterion omitted',lambda c:c['whole_original382_independent_resolution_criteria'].pop()),
    ('clock guarantee loss hidden',lambda c:c['whole392_clock_option']['guarantees_lost_or_changed'].pop()),
    ('clock clause approved',lambda c:c['exact_clock_clause_proposal'].update(replacement_approved=True)),
    ('clock fallback substituted',lambda c:c['exact_clock_clause_proposal'].update(proposed_complete_clause_text='Use another clock on loss.')),
    ('guardian immortal',lambda c:c.update(guardian_is_immortal=True)),
    ('signal treated as full drain',lambda c:c.update(parent_exit_or_signal_is_full_drain=True)),
    ('known drain renews rights',lambda c:c.update(known_drain_renews_expired_rights=True)),
    ('unknown time erases known facts',lambda c:c.update(unknown_time_erases_independent_captured_facts=True)),
    ('deadline budget refill allowed',lambda c:c.update(clock_fallback_or_deadline_budget_refill_allowed=True)),
    ('hidden rollback detection claimed',lambda c:c.update(hidden_trusted_clock_tampering_detection_proven=True)),
    ('one loss role omitted',lambda c:c['proposed_loss_roles'].pop()),
    ('one drain facet omitted',lambda c:c['seven_full_drain_requirements'].pop()),
    ('membership known from task count',lambda c:c['joint_proposed_statements'].update(membership_and_guardian='Task counts suffice.')),
    ('suspend time omitted',lambda c:c['joint_proposed_statements'].update(suspend_and_discontinuity='Suspend pauses all deadlines.')),
    ('guardian native component chosen',lambda c:c.update(actual_guardian_or_surviving_control={})),
    ('known native drain invented',lambda c:c.update(actual_full_membership_and_drain={})),
    ('actual clock mapping invented',lambda c:c.update(actual_clock_mapping_or_provider={})),
    ('other platform support borrowed',lambda c:c['whole_original_platform_assessments'][0].update(native_feasibility_proven=True)),
    ('paper case native evidence invented',lambda c:c['authored_hypothetical_cases'][0].update(actual_native_evidence={})),
    ('joint question dropped',lambda c:c['remaining_joint_reviews'].pop()),
    ('semantic migration complete',lambda c:c.update(semantic_migration_complete=True)),
    ('new pause claimed',lambda c:c['boundaries'].update(strong_safe_pause=True)),
    ('automatic409 opened',lambda c:c.update(no_automatic409=False))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual402 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_sections']['joint_proposed_statements']['clock_mapping'] = 'Renew deadlines.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
for case in proposal['authored_hypothetical_cases']:
    result=module['hypothetical_case'](case,policy)
    check('paper loss drain clock witness '+case['id'],result['drain_disposition']==case['expected_drain_disposition'] and result['recovery_eligibility_question']==case['expected_recovery_question'] and result['runtime_authority'] is False and result['native_proof'] is False and result['actual_native_drain_or_rights'] is None and result['actual_closed'] is False)
result=module['hypothetical_case'](proposal['authored_hypothetical_cases'][12],policy)
check('known full drain retained with expired recovery rights denied',result['drain_disposition']=='paper-full-drain-declaration' and result['recovery_eligibility_question']=='paper-deny-recovery-expired')
result=module['hypothetical_case'](proposal['authored_hypothetical_cases'][20],policy)
check('known mismatch preserved with incomplete drain pending',result['known_mismatch_preserved'] is True and result['drain_disposition']=='paper-drain-pending')
result=module['hypothetical_case'](proposal['authored_hypothetical_cases'][3],policy)
check('supervisor loss keeps forward closed and original failure retained',result['forward_admission_closed_in_paper'] is True and result['original_forward_failure_preserved'] is True)
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['original_spent']=True
check('reject boolean action spend masquerading as integer',rejects(module['hypothetical_case'],case,policy))
case['original_spent']=1;case['hypothetical_only']=False
check('reject paper evaluator used as actual recovery permission',rejects(module['hypothetical_case'],case,policy))
case['hypothetical_only']=True;case['original_spend_known']=None
check('unknown spend is denied rather than reset to zero',module['hypothetical_case'](case,policy)['recovery_eligibility_question']=='paper-deny-unknown-spend')
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['forward_deadline']=None
check('unknown original forward deadline closes further admission',module['hypothetical_case'](case,policy)['forward_admission_closed_in_paper'] is True)
case['forward_deadline']=20;case['membership_known']=None
check('unknown original membership closes further admission',module['hypothetical_case'](case,policy)['forward_admission_closed_in_paper'] is True)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
