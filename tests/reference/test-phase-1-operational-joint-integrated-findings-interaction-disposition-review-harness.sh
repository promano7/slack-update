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
root=Path(sys.argv[1]);step='phase-1-operational-joint-integrated-findings-interaction-disposition-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,audit,sources,policy=[load(s) for s in ['entry415','baseline','audit','sources','policy']]
module=runpy.run_path(str(root/'tools/reference'/(step+'.py')));passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label)
def rejects(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,IndexError,TypeError):return True
    return False
inputs={k:safe(v['path']) for k,v in sources['inputs'].items()}
rows=sources['inert_roots']+sources['reviewer_roots']+[sources['readme']]
blobs={r['path']:(safe(r['path'])[len(policy['prefixes']['README.md'].encode()):] if r['path']=='README.md' else safe(r['path'])) for r in rows}
check('whole authored416 fixtures bound',module['validate_fixtures']({'entry415':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual415 return89PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all137 whole inputs and42 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('all13 findings9 dimensions325 original36 candidate pairs1286 dependencies',module['validate_audit'](audit,inputs,sources,policy))
check('all2250 historical415 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={p.decode() for p in raw.split(b'\0') if p}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda a:a.update(schema=True)),
 ('option selected',lambda a:a.update(selected_options=['JCP400-A'])),
 ('migration approved',lambda a:a.update(approved_contract_migration={})),
 ('same-author integration made independent acceptance',lambda a:a.update(independent_impact_review_accepted=True)),
 ('native authority opened',lambda a:a.update(runtime_authority=True)),
 ('current pause self-confirmed',lambda a:a.update(current_strong_safe_pause=True)),
 ('unknown host made absent',lambda a:a['boundaries'].update(actual_host_state='absent')),
 ('global closure invented',lambda a:a['boundaries'].update(actual_global_host_closure=True)),
 ('native case invented',lambda a:a['boundaries'].update(native_cases_run=1)),
 ('one global rule waived',lambda a:a['whole_nine_global_semantic_rules'].pop('R402')),
 ('whole prior414 membership question omitted',lambda a:a['whole_accepted414_findings'].pop()),
 ('inactive410 clarification substituted',lambda a:a['whole_accepted410_clarifications'][0].update(normative_activation=True)),
 ('local positive declarations prove joint compatibility',lambda a:a['interpretation_limit'].update(all_local_paper_positives_prove_joint_compatibility=True)),
 ('pair coverage counts made compatibility proof',lambda a:a['interpretation_limit'].update(pair_coverage_counts_prove_compatibility=True)),
 ('empty counterexample sample made proof',lambda a:a['interpretation_limit'].update(empty_counterexample_sample_proves_compatibility=True)),
 ('same-brief historical label made universal exclusion',lambda a:a['interpretation_limit'].update(historical_same_brief_label_proves_mutual_exclusion=True)),
 ('repair erases original finding',lambda a:a['interpretation_limit'].update(inactive_repair_activates_norms_or_erases_findings=True)),
 ('fresh explicit native grant gate omitted',lambda a:a['remaining_review_and_approval_order'].pop(2)),
 ('next step skips actual acceptance',lambda a:a.update(next_preparable_step_after_complete416_acceptance=418)),
 ('automatic419 permitted',lambda a:a.update(no_automatic419=False)),
 ('guarantee changes reclassified as retained',lambda a:a['classification_counts'].update({'explicit-guarantee-change':0})),
 ('whole original finding shortened',lambda a:a['integrated_finding_reviews'][0]['whole_original_authored_finding'].pop('issue')),
 ('finding status silently resolved',lambda a:a['integrated_finding_reviews'][0].update(status='resolved')),
 ('one joint dimension omitted',lambda a:a['all9_joint_dimension_reviews'].pop()),
 ('whole original option omitted',lambda a:a['all26_whole_option_reviews'].pop()),
 ('original pair sampled away',lambda a:a['all325_original_pair_reviews'].pop()),
 ('candidate pair sampled away',lambda a:a['all36_inactive_candidate_pair_reviews'].pop()),
 ('whole conflict decision omitted',lambda a:a['all8_whole_decision_reviews'].pop()),
 ('repair original history erased',lambda a:a['inactive_repair_dependency_reviews'][0].update(old_findings_resolved_or_erased=True)),
 ('member dependency omitted',lambda a:a['all1286_member_dependency_dispositions'].pop())]
for label,mutate in mutations:
    bad=copy.deepcopy(audit);mutate(bad);check('reject '+label,rejects(module['validate_audit'],bad,inputs,sources,policy))
packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit415']);options=audit['all26_whole_option_reviews'];dimensions=audit['all9_joint_dimension_reviews'];dimension_ids=[r['dimension_id'] for r in dimensions]
for row in dimensions:check('whole joint dimension '+row['dimension_id'],row['actual_joint_resolution'] is None and row['all_other_global_dependencies_still_required'] and row['whole_original_and_inactive407_answer']['whole_original397_dimension']['id']==row['dimension_id'])
check('all13 whole findings retain3 changes6 conditions4 hypotheses',audit['classification_counts']=={'explicit-guarantee-change':3,'underspecified-condition':6,'unproved-native-hypothesis':4} and len(audit['integrated_finding_reviews'])==13)
check('all325 original pair positions and36 inactive candidate positions retained',[r['ordered_option_ids'] for r in audit['all325_original_pair_reviews']]==[r['option_ids'] for r in packet['whole_original397_all325_pair_questions']] and [r['ordered_option_ids'] for r in audit['all36_inactive_candidate_pair_reviews']]==[r['whole_original397_pair_question']['option_ids'] for r in packet['all36_author_candidate_pair_questions']])
for field in ['all325_original_pair_reviews','all36_inactive_candidate_pair_reviews']:
    source=packet['whole_original397_all325_pair_questions'][0] if field=='all325_original_pair_reviews' else packet['all36_author_candidate_pair_questions'][0]['whole_original397_pair_question']
    candidate=None if field=='all325_original_pair_reviews' else packet['all36_author_candidate_pair_questions'][0]
    for label,mutate in [
        ('one full option assessment omitted',lambda r:r['both_complete_option_scope_assessments'].pop()),
        ('pair whole option pointer rebound',lambda r:r['whole_option_register_pointers'].__setitem__(0,'/option_register/25')),
        ('joint compatibility invented',lambda r:r.update(actual_joint_compatibility=True)),
        ('same-brief label promoted to exclusion proof',lambda r:r.update(historical_same_brief_label_is_mutual_exclusion_proof=True)),
        ('pair local focus waives global dependencies',lambda r:r.update(all_other_global_dependencies_still_required=False))]:
        row=copy.deepcopy(audit[field][0]);mutate(row);check('reject '+field+' '+label,rejects(module['validate_pair_review'],row,source,candidate,options,policy['expected_review_row_sha256'][field][0]))
repairs=audit['inactive_repair_dependency_reviews']
for row in repairs:check('whole inactive repair and cross-impact '+row['repair_id'],not row['normative_activation'] and not row['old_findings_resolved_or_erased'] and row['whole_inactive_proposal_and_context'] and row['open_finding_ids_to_revisit'])
for label,mutate in [
 ('dependency member source pointer rebound',lambda r:r['whole_415_member_review_reference'].update(json_pointer='/all15_category1286_member_impact_reviews/3/member_reviews/0')),
 ('dependency repair impacts omitted',lambda r:r.update(inactive_repair_ids_requiring_impact_revisit=[])),
 ('dependency original finding history erased',lambda r:r.update(original_finding_history_erased=True)),
 ('dependency independent migration invented',lambda r:r.update(semantic_migration_independently_accepted=True))]:
    row=copy.deepcopy(audit['all1286_member_dependency_dispositions'][0]);mutate(row)
    check('reject '+label,rejects(module['validate_member_dependency'],row,previous,'/all15_category1286_member_impact_reviews/0/member_reviews/0',repairs,policy['expected_review_row_sha256']['all1286_member_dependency_dispositions'][0]))
byid={r['case']['id']:r['case'] for r in audit['paper_joint_interaction_cases']}
def status(id_):return module['joint_paper_status'](byid[id_],dimension_ids)
r=status('J01-target-admission-does-not-cover-custody-expiry')
check('local target admission cannot cover own publication expiry or custody pending','durable-rights-vs-loss-deadlines' in r['known_failed_local_dimensions'] and 'observer-controls-vs-finite-custody' in r['unknown_local_dimensions'] and r['qualified_paper_facts']==['qualified-paper-target-at-original-cut'] and r['original_forward_failed'] is True and r['actual_joint_compatibility'] is None and not r['runtime_authority'])
r=status('J02-clock-clarification-leaves-async-impact-open')
check('clock clarification retains async impacts and all original finding history',r['inactive_repairs_considered']==['CL410-CLOCK'] and 'guardian-drain-vs-forward-failure' in r['unknown_local_dimensions'] and r['retained_finding_ids']==module['FINDING_IDS'] and not r['repair_closes_original_findings'] and not r['normative_activation'])
r=status('J03-publication-clarification-leaves-membership-open')
check('publication clarification retains collector own membership and custody unknown',r['qualified_paper_facts']==['qualified-paper-subject-trace-fact'] and 'terminal-cut-vs-whole-stage-oracle' in r['unknown_local_dimensions'] and not r['native_proof'])
r=status('J04-known-target-plus-unknown-restore-ACK')
check('qualified target original failure and unknown action coexist',r['original_forward_failed'] is True and r['qualified_paper_facts']==['qualified-paper-target-match'] and r['pending_obligations']==['original-restore-ACK-and-action-spend'] and not r['original_failure_erased'])
r=status('J05-namespace-repair-does-not-select-publication-policy')
check('namespace repair leaves original publication policy and applicability pending',r['pending_obligations']==['original-request-applicability-and-publication-policy'] and r['actual_joint_compatibility'] is None)
r=status('J06-all-local-paper-positives-not-joint-native-acceptance')
check('all local paper positives still no native compatibility independent acceptance or grant',r['all_local_paper_declarations_positive'] and r['actual_joint_compatibility'] is None and not r['native_proof'] and not r['independent_impact_acceptance'] and not r['runtime_authority'])
for label,mutate in [
 ('paper repair erases old finding',lambda c:c['retained_finding_ids'].pop()),
 ('paper repair activates wording',lambda c:c.update(normative_activation=True)),
 ('integer as local boolean status',lambda c:c['local_dimension_status'].update({'offline-bootstrap-vs-live-channel':1})),
 ('integer as original failure boolean',lambda c:c.update(original_forward_failed=1)),
 ('paper local dimension omitted',lambda c:c['local_dimension_status'].pop('observer-controls-vs-finite-custody'))]:
    c=copy.deepcopy(byid['J06-all-local-paper-positives-not-joint-native-acceptance']);mutate(c);check('reject '+label,rejects(module['joint_paper_status'],c,dimension_ids))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual415 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=copy.deepcopy(entry);bad['confirmation']['commit_full']='invented-full-Git-ID'
check('reject invented full user Git ID',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['audit415']+=b' '
check('reject whole accepted member source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['all_local_paper_positives_prove_joint_compatibility']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('prepared integrated result retains all dependencies without native rights or pause',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure reader imports only hashlib json re without native dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
