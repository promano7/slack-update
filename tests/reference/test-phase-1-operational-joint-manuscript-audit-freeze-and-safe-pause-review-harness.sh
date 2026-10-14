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
root=Path(sys.argv[1]);step='phase-1-operational-joint-manuscript-audit-freeze-and-safe-pause-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,freeze,sources,policy=[load(s) for s in ['entry417','baseline','freeze','sources','policy']]
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
check('whole authored418 fixtures bound',module['validate_fixtures']({'entry417':entry,'baseline':baseline,'freeze':freeze,'sources':sources},policy))
check('complete actual417 return79PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all145 whole inputs and44 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('WHOLE freeze findings dispositions actual409-417 chain and all9 nested conditions',module['validate_freeze'](freeze,entry,inputs,sources,policy))
check('all2266 historical417 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={p.decode() for p in raw.split(b'\0') if p}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda f:f.update(schema=True)),
 ('option selected by freeze',lambda f:f.update(selected_options=['JCP400-A'])),
 ('migration approved',lambda f:f.update(approved_contract_migration={})),
 ('same-author audit made independent acceptance',lambda f:f.update(independent_impact_review_accepted=True)),
 ('native graph invented',lambda f:f.update(actual_joint_native_graph={})),
 ('actual native evidence invented',lambda f:f.update(actual_native_evidence={})),
 ('native authority opened',lambda f:f.update(runtime_authority=True)),
 ('current418 pause self-confirmed',lambda f:f.update(actual_strong_safe_pause_confirmed=True)),
 ('current418 all9 self-confirmed',lambda f:f.update(all_nine_current418_conditions_externally_confirmed=True)),
 ('private eligibility made actual confirmation',lambda f:f.update(private_eligibility_is_actual_confirmation=True)),
 ('actual final418 receipt invented',lambda f:f.update(current418_actual_final_user_receipt={})),
 ('actual final418 commit invented',lambda f:f.update(current418_user_commit_prefix='invented')),
 ('final clean worktree invented',lambda f:f.update(current418_user_worktree_clean=True)),
 ('unknown host made absent',lambda f:f.update(actual_host_state='absent')),
 ('global host closure invented',lambda f:f.update(actual_global_host_closure=True)),
 ('native proof invented',lambda f:f.update(native_proofs_added=1)),
 ('current live binding revived',lambda f:f.update(actual_live_bindings={})),
 ('machine cleanup demanded from pure block',lambda f:f.update(machine_action_required=True)),
 ('controller cleanup demanded from pure block',lambda f:f.update(controller_action_required=True)),
 ('historical408 confirmation expanded to new block',lambda f:f.update(historical408_confirmation_expands_to_new_scope=True)),
 ('historical authority reuse permitted',lambda f:f.update(historical_binding_or_authority_reuse_allowed=True)),
 ('later-current refresh invalidates repository pause',lambda f:f.update(later_current_refresh_invalidates_repository_only_pause=True)),
 ('original norm waived',lambda f:f.update(whole_original_requirements_remain_normative=False)),
 ('complete input binding omitted',lambda f:f['frozen_inputs'].pop('audit415')),
 ('inert source root omitted',lambda f:f['frozen_source_roots'].pop(0)),
 ('whole unselected417 brief shortened',lambda f:f['whole_accepted417_decision_brief']['whole_integrated416_finding_reviews'].pop()),
 ('one open finding erased',lambda f:f['whole_integrated416_audit_results']['integrated_finding_reviews'].pop()),
 ('whole original pair question omitted',lambda f:f['whole_integrated416_audit_results']['all325_original_pair_reviews'].pop()),
 ('whole candidate pair question omitted',lambda f:f['whole_integrated416_audit_results']['all36_inactive_candidate_pair_reviews'].pop()),
 ('whole member criteria reference rebound',lambda f:f['whole415_complete_member_criteria_reference'].update(canonical_sha256='wrong')),
 ('complete historical408 receipt truncated',lambda f:f['whole_historical_confirmed408_entry']['receipt'].update(text='short')),
 ('all-nine final requirement omitted',lambda f:f.update(final_pause_requires_all_nine_whole_original_conditions=False)),
 ('complete final actual return not required',lambda f:f.update(final_pause_requires_complete_actual_user_receipt=False)),
 ('separate external final confirmation omitted',lambda f:f.update(final_pause_requires_separate_external_all_nine_confirmation=False)),
 ('last confirmed pause moved to current418',lambda f:f.update(last_confirmed_strong_safe_pause_step=418)),
 ('automatic419 allowed',lambda f:f.update(no_automatic419=False)),
 ('next stage419 opened',lambda f:f.update(next_authorized_stage_after418=419)),
 ('future new request gate omitted',lambda f:f['after_final_acceptance'].update(future_batch_requires_new_user_request=False)),
 ('fresh native grant before actual safe review',lambda f:f['remaining_review_and_approval_order'].pop(2))]
for label,mutate in mutations:
    bad=copy.deepcopy(freeze);mutate(bad);check('reject '+label,rejects(module['validate_freeze'],bad,entry,inputs,sources,policy))
check('all9 WHOLE nested conditions retained with exact current bases',module['validate_current_conditions'](freeze,inputs,policy))
for i,row in enumerate(freeze['conditions']):
    check('whole current condition '+str(i+1)+' '+row['id'],row['position']==i and row['current418_actual_user_confirmation'] is None and row['current418_external_condition_confirmation'] is None and not row['actual_global_host_closure'])
for label,i,mutate in [
 ('one whole condition omitted',None,lambda f:f['conditions'].pop()),
 ('nested historical condition truncated',1,lambda f:f['conditions'][1]['whole_original_externally_confirmed408_condition']['whole_prepared408_condition'].pop('whole_original_prepared398_condition')),
 ('current review basis replaced by count',1,lambda f:f['conditions'][1].update(repository_review_basis_for409_418='all counts pass')),
 ('current condition confirmation self-invented',0,lambda f:f['conditions'][0].update(current418_actual_user_confirmation=True)),
 ('external current confirmation self-invented',8,lambda f:f['conditions'][8].update(current418_external_condition_confirmation=True)),
 ('old condition native proof invented',3,lambda f:f['conditions'][3]['whole_original_externally_confirmed408_condition'].update(actual_native_evidence={})),
 ('old condition historical scope rebound',6,lambda f:f['conditions'][6]['whole_original_externally_confirmed408_condition']['whole_prepared408_condition'].update(current_scope='409-418')),
 ('unknown actual host condition globally closed',7,lambda f:f['conditions'][7].update(actual_global_host_closure=True))]:
    bad={'conditions':copy.deepcopy(freeze['conditions'])};mutate(bad);check('reject '+label,rejects(module['validate_current_conditions'],bad,inputs,policy))
check('complete actual409-417 checkpoint receipts verified',module['validate_checkpoint_chain'](freeze,entry,inputs,policy))
for row in freeze['complete_accepted_checkpoint_chain409_417']:check('complete actual checkpoint '+str(row['step'])+' '+row['commit_prefix']+' '+str(row['ordered_pass_count'])+'PASS',row['whole_actual_user_entry']['confirmation']['commit_prefix']==row['commit_prefix'] and row['intermediate_checkpoint_not_strong_pause'])
for label,mutate in [
 ('one actual predecessor entry omitted',lambda f:f['complete_accepted_checkpoint_chain409_417'].pop()),
 ('actual409 return shortened',lambda f:f['complete_accepted_checkpoint_chain409_417'][0]['whole_actual_user_entry']['receipt'].update(text='short')),
 ('actual417 final tail shortened',lambda f:f['complete_accepted_checkpoint_chain409_417'][8]['whole_actual_user_entry']['receipt'].update(reported_final_tail='short')),
 ('intermediate actual416 made strong pause',lambda f:f['complete_accepted_checkpoint_chain409_417'][7].update(intermediate_checkpoint_not_strong_pause=False)),
 ('full historical user Git ID invented',lambda f:f['complete_accepted_checkpoint_chain409_417'][2].update(commit_full='invented'))]:
    bad={'complete_accepted_checkpoint_chain409_417':copy.deepcopy(freeze['complete_accepted_checkpoint_chain409_417'])};mutate(bad);check('reject '+label,rejects(module['validate_checkpoint_chain'],bad,entry,inputs,policy))
# Inspect,never execute,the full current block's pure supplied-data reviewers.
reviewer_paths=[r['path'] for r in sources['reviewer_roots'][-9:]]+['tools/reference/'+step+'.py']
forbidden={'open','exec','eval','input','compile','__import__','getattr','setattr','globals','locals','vars'}
for path in reviewer_paths:
    tree=ast.parse(safe(path));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
    check('pure current-block reviewer '+path,imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual417 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['brief417']+=b' '
check('reject whole accepted417 source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_after_final_acceptance']['no_automatic419']=False
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
r=module['review'](entry,freeze,inputs,blobs,sources,policy)
check('prepared review matches exact conditional result',r==policy['expected_review_result'])
check('all local validation still no actual418 receipt or confirmed pause',r['repository_review_eligible_for_conditional_pause'] and not r['actual_strong_safe_pause_confirmed'] and not r['all_nine_current418_conditions_externally_confirmed'] and r['last_confirmed_strong_safe_pause_step']==408)
check('closed repository scope independent of later-current refresh never reopens rights',not freeze['later_current_refresh_invalidates_repository_only_pause'] and not freeze['historical_binding_or_authority_reuse_allowed'] and r['next_authorized_stage_after418'] is None and not r['runtime_authority'])
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
