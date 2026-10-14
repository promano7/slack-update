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
root=Path(sys.argv[1]);step='phase-1-operational-joint-unselected-a-r-d-decision-brief-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,brief,sources,policy=[load(s) for s in ['entry416','baseline','brief','sources','policy']]
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
check('whole authored417 fixtures bound',module['validate_fixtures']({'entry416':entry,'baseline':baseline,'brief':brief,'sources':sources},policy))
check('complete actual416 return84PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all141 whole inputs and43 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('three unselected alternatives whole findings losses dependencies and seven boundaries',module['validate_brief'](brief,inputs,sources,policy))
check('all2258 historical416 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={p.decode() for p in raw.split(b'\0') if p}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda b:b.update(schema=True)),
 ('option A selected by brief',lambda b:b.update(selected_candidate='JCP400-A')),
 ('native closure inferred as option D',lambda b:b.update(selected_options=['JCP400-D'])),
 ('author recommendation made current user recommendation',lambda b:b.update(recommended_option_for_user='JCP400-A')),
 ('premature option decision requested',lambda b:b.update(decision_requested_now=True)),
 ('premature approval requested',lambda b:b.update(approval_requested_by_this_brief=True)),
 ('same-author brief made independent acceptance',lambda b:b.update(independent_impact_review_accepted=True)),
 ('migration approved',lambda b:b.update(approved_contract_migration={})),
 ('native grant invented',lambda b:b.update(fresh_native_test_grant={})),
 ('native authority opened',lambda b:b.update(runtime_authority=True)),
 ('current pause self-confirmed',lambda b:b.update(current_strong_safe_pause=True)),
 ('unknown host made absent',lambda b:b['boundaries'].update(actual_host_state='absent')),
 ('global closure invented',lambda b:b['boundaries'].update(actual_global_host_closure=True)),
 ('native proof invented',lambda b:b['boundaries'].update(native_proofs_added=1)),
 ('original norm waived',lambda b:b.update(whole_original_requirements_remain_normative=False)),
 ('one global rule waived',lambda b:b['whole_nine_global_semantic_rules'].pop('E405')),
 ('whole prior finding omitted',lambda b:b['whole_accepted414_findings'].pop()),
 ('whole integrated finding shortened',lambda b:b['whole_integrated416_finding_reviews'][0]['whole_original_authored_finding'].pop('issue')),
 ('guarantee change reclassified as retained',lambda b:b['classification_counts'].update({'explicit-guarantee-change':0})),
 ('additional recovery guarantee loss omitted',lambda b:b['whole_loss_and_incompatibility_register']['whole402_additional_forward_recovery_publication_losses'].pop()),
 ('inactive repair activated',lambda b:b['whole_four_inactive_repair_reviews'][0].update(normative_activation=True)),
 ('repository commit inferred as option decision',lambda b:b['interpretation_limit'].update(repository_continue_PASS_commit_push_is_option_choice=True)),
 ('unselected native closure inferred as choice D',lambda b:b['interpretation_limit'].update(unselected_native_entry_closed_is_implicit_choice_D=True)),
 ('retention made feasibility proof',lambda b:b['interpretation_limit'].update(retention_proves_feasible_original_composition=True)),
 ('deferral waives original requirements',lambda b:b['interpretation_limit'].update(deferral_waives_original_requirements=True)),
 ('A made original unchanged equivalence',lambda b:b['interpretation_limit'].update(candidate_A_is_original_equivalence=True)),
 ('summary replaces whole source meaning',lambda b:b['interpretation_limit'].update(summary_replaces_whole_findings_losses_or_dependencies=True)),
 ('another platform evidence borrowed',lambda b:b['interpretation_limit'].update(platform_evidence_can_be_borrowed=True)),
 ('one alternative omitted',lambda b:b['unselected_alternatives'].pop()),
 ('conditional pause whole policy shortened',lambda b:b['whole_conditional_pause_policy'].pop(next(iter(b['whole_conditional_pause_policy'])))),
 ('freeze skips all pause conditions',lambda b:b.update(freeze_with_options_unselected_permitted_only_after_all_pause_conditions=False)),
 ('next step skips actual acceptance',lambda b:b.update(next_preparable_step_after_complete417_acceptance=419)),
 ('automatic419 permitted',lambda b:b.update(no_automatic419=False))]
for label,mutate in mutations:
    bad=copy.deepcopy(brief);mutate(bad);check('reject '+label,rejects(module['validate_brief'],bad,inputs,sources,policy))
for i,id_ in enumerate(['JCP400-A','JCP400-R','JCP400-D']):
    row=brief['unselected_alternatives'][i]
    check('whole unselected alternative '+id_,row['candidate_id']==id_ and not row['selected'] and row['actual_joint_compatibility'] is None and row['whole_original_option_and_integrated_review_references'])
    for label,mutate in [
        ('selected',lambda b,i=i:b['unselected_alternatives'][i].update(selected=True)),
        ('consequences hidden',lambda b,i=i:b['unselected_alternatives'][i].update(consequences=[])),
        ('blockers omitted',lambda b,i=i:b['unselected_alternatives'][i].update(remaining_blockers=[])),
        ('whole option source reference omitted',lambda b,i=i:b['unselected_alternatives'][i]['whole_original_option_and_integrated_review_references'].pop())]:
        bad=copy.deepcopy(brief);mutate(bad);check('reject '+id_+' '+label,rejects(module['validate_brief'],bad,inputs,sources,policy))
gates=brief['seven_separate_decision_and_evidence_boundaries']
check('all seven separate boundaries preserve safe review before fresh native grant',module['validate_separate_boundaries'](gates,policy))
for label,mutate in [
 ('grant before independent actual safety review',lambda g:g.__setitem__(slice(4,6),[g[5],g[4]])),
 ('conditional migration made automatic',lambda g:g[2].update(applies_when='always-approved')),
 ('option choice fulfills independent review',lambda g:g[1].update(current_acceptance_or_authority_present=True)),
 ('commit fulfills native grant',lambda g:g[5].update(fulfilled_by_step417=True)),
 ('actual composition decision invented',lambda g:g[3].update(actual_evidence_or_decision={}))]:
    bad=copy.deepcopy(gates);mutate(bad);check('reject '+label,rejects(module['validate_separate_boundaries'],bad,policy))
check('all whole source attachments directly dereference complete values',module['validate_whole_attachments'](brief,inputs,sources,policy))
for label,mutate in [
 ('whole member attachment omitted',lambda b:b['whole_source_attachments'].pop(8)),
 ('whole source pointer rebound to summary',lambda b:b['whole_source_attachments'][0].update(json_pointer='/classification_counts')),
 ('concise summary replaces whole pair questions',lambda b:b['whole_source_attachments'][3].update(summary_replaces_whole_source=True))]:
    bad=copy.deepcopy(brief);mutate(bad);check('reject '+label,rejects(module['validate_whole_attachments'],bad,inputs,sources,policy))
for row in brief['non_authorizing_event_examples']:
    check('event grants no current choice migration native rights or pause '+row['id'],row['actual_current_user_option_choice'] is None and row['native_test_grant'] is None and not row['migration_approval'] and not row['current_pause_confirmation'])
bad=copy.deepcopy(brief);bad['non_authorizing_event_examples'][2]['native_test_grant']={}
check('reject repository commit example authorizes native tests',rejects(module['validate_brief'],bad,inputs,sources,policy))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual416 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=copy.deepcopy(entry);bad['confirmation']['commit_full']='invented-full-Git-ID'
check('reject invented full user Git ID',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['audit416']+=b' '
check('reject whole integrated source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['unselected_native_entry_closed_is_implicit_choice_D']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('prepared brief makes no selection approval native grant or pause',module['review'](entry,brief,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure reader imports only hashlib json re without native dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
