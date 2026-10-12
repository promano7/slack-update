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
step = 'phase-1-operational-joint-stage12-receipt-final-observation-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry404', 'baseline', 'review', 'sources', 'policy']]
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
check('whole authored405 entry baseline review sources independently bound', module['validate_fixtures']({'entry404': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual404 supplied receipt74PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all88 whole inputs and31 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('whole original stage12 causal receipt and terminal custody requirements retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2162 accepted404 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
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
    ('whole original stage12 shortened',lambda c:c['whole_original316_stage12'].pop('guard')),
    ('original stage renamed subset',lambda c:c['whole_original316_stage12'].update(stage='prepare-reviewed-publication')),
    ('original causal criterion omitted',lambda c:c['whole_original384_causal_and_event_review']['independent_resolution_criteria'].pop()),
    ('original failure cut omitted',lambda c:c['whole_original384_causal_and_event_review']['original374_publication_failure_cut_review'].pop()),
    ('one terminal event omitted',lambda c:c['all10_event_joint_reconciliations'].pop()),
    ('event whole membership rebound',lambda c:c['all10_event_joint_reconciliations'][4]['whole_original394_event'].update(proposed_subject_stage12_member=True)),
    ('external role omitted',lambda c:c['all6_external_role_obligation_questions'].pop()),
    ('observer role exempted',lambda c:c['all6_external_role_obligation_questions'][3].update(is_exempt_observer=True)),
    ('role label proves independence',lambda c:c['all6_external_role_obligation_questions'][3].update(role_label_proves_independence=True)),
    ('original publication replacement shortened',lambda c:c['exact_inactive_clause_replacements'][1]['whole_current_value'].pop('unknown')),
    ('replacement promoted to approval',lambda c:c['exact_inactive_clause_replacements'][0].update(approved=True)),
    ('producer guard weakened',lambda c:c['exact_inactive_clause_replacements'][0]['whole_proposed_value'].update(guard='Producer exit proves success.')),
    ('external clock rights omitted',lambda c:c['joint_proposed_statements'].update(joint_controls_every_actor='Use worker rights.')),
    ('terminal later effect ignored',lambda c:c['joint_proposed_statements'].update(finite_terminal_cut='Ignore later effects.')),
    ('receipt payload contains future completion',lambda c:c.update(receipt_payload_contains_future_completion=True)),
    ('producer exit proves final eligibility',lambda c:c.update(producer_exit_proves_final_eligibility=True)),
    ('producer subset is original stage12',lambda c:c.update(producer_subset_is_original_stage12=True)),
    ('archive sidecar pair atomic',lambda c:c.update(archive_sidecar_pair_atomic=True)),
    ('observer exempt from own effects',lambda c:c.update(observer_exempt_from_own_effects=True)),
    ('DAG proves native protocol',lambda c:c.update(DAG_proves_native_protocol=True)),
    ('unbounded self receipt chain required',lambda c:c.update(unbounded_self_receipt_chain_required=True)),
    ('unknown commit ACK permits republication',lambda c:c.update(unknown_commit_ACK_permits_republication=True)),
    ('post release target source read allowed',lambda c:c.update(post_release_target_source_read_allowed=True)),
    ('terminal cut establishes actual closure',lambda c:c.update(terminal_cut_establishes_actual_closure=True)),
    ('actual native graph invented',lambda c:c.update(actual_native_graph={})),
    ('actual receipt writer invented',lambda c:c.update(actual_receipt_writer={})),
    ('other platform support borrowed',lambda c:c['whole394_selected_for_drafting_option']['platform_rows'][0].update(support='supported')),
    ('paper native observation invented',lambda c:c['authored_hypothetical_cases'][0].update(actual_native_evidence={})),
    ('joint question omitted',lambda c:c['remaining_joint_reviews'].pop()),
    ('semantic migration complete',lambda c:c.update(semantic_migration_complete=True)),
    ('new pause claimed',lambda c:c['boundaries'].update(strong_safe_pause=True)),
    ('automatic409 opened',lambda c:c.update(no_automatic409=False))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual404 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_statements']['payload_causality'] = 'Receipt proves own future completion.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
for case in proposal['authored_hypothetical_cases']:
    result=module['hypothetical_case'](case,policy)
    check('paper receipt custody witness '+case['id'],result['finite_cut_review_question']==case['expected_question'] and result['runtime_authority'] is False and result['native_proof'] is False and result['republish_permission'] is False and result['actual_native_fact_or_action'] is None and result['actual_closed'] is False)
case=proposal['authored_hypothetical_cases'][17];result=module['hypothetical_case'](case,policy)
check('qualified captured object and target facts retained with unknown custody',result['qualified_captured_object_fact_retained'] and result['qualified_captured_target_fact_retained'] and result['finite_cut_review_question']=='paper-pending-external-outcomes')
case=proposal['authored_hypothetical_cases'][5];result=module['hypothetical_case'](case,policy)
check('unknown commit ACK denies republish despite new request',result['finite_cut_review_question']=='paper-quarantine-uncertain-commit-no-replay' and result['republish_permission'] is False)
case=proposal['authored_hypothetical_cases'][18];result=module['hypothetical_case'](case,policy)
check('known mismatch and original failure survive pending custody',result['known_mismatch_preserved'] and result['original_failure_preserved'] and result['finite_cut_review_question']=='paper-deny-known-mismatch')
case=proposal['authored_hypothetical_cases'][16];result=module['hypothetical_case'](case,policy)
check('spent complete facts do not require renewed action rights',result['finite_cut_review_question']=='paper-declared-finite-cut-review-question' and result['runtime_authority'] is False)
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['original_spent']=True
check('reject boolean original spend masquerading as integer',rejects(module['hypothetical_case'],case,policy))
case['original_spent']=1;case['hypothetical_only']=False
check('reject paper question used as actual publication permission',rejects(module['hypothetical_case'],case,policy))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
