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
root=Path(sys.argv[1]);step='phase-1-operational-joint-baseline-storage-once-only-rights-audit-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,audit,sources,policy=[load(s) for s in ['entry412','baseline','audit','sources','policy']]
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
check('whole authored413 fixtures bound',module['validate_fixtures']({'entry412':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual412 return69PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all125 whole inputs and39 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('whole baseline storage context18 branches9 microsteps27 cuts and status cases',module['validate_audit'](audit,inputs,sources,policy))
check('all2226 historical412 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={p.decode() for p in raw.split(b'\0') if p}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda a:a.update(schema=True)),
 ('option selected',lambda a:a.update(selected_options=['JCP400-A'])),
 ('migration approved',lambda a:a.update(approved_contract_migration={})),
 ('same-author audit made independent acceptance',lambda a:a.update(independent_impact_review_accepted=True)),
 ('native authority opened',lambda a:a.update(runtime_authority=True)),
 ('current pause self-confirmed',lambda a:a.update(current_strong_safe_pause=True)),
 ('unknown host made absent',lambda a:a['boundaries'].update(actual_host_state='absent')),
 ('global closure invented',lambda a:a['boundaries'].update(actual_global_host_closure=True)),
 ('native case invented',lambda a:a['boundaries'].update(native_cases_run=1)),
 ('one global rule waived',lambda a:a['whole_nine_global_semantic_rules'].pop('D404')),
 ('one original baseline domain omitted',lambda a:a['whole_storage404_context']['whole_original7_baseline_domain_reviews'].pop()),
 ('one owned failure omitted',lambda a:a['whole_storage404_context']['whole_original8_owned_failure_reviews'].pop()),
 ('prior412 question omitted',lambda a:a['whole_accepted412_findings'].pop()),
 ('clock clarification activated',lambda a:a['whole_accepted410_clarifications'][0].update(substitution_authorized=True)),
 ('one original branch omitted',lambda a:a['branch_reviews'].pop()),
 ('current recovery branch shortened',lambda a:a['branch_reviews'][3]['whole_storage404_reconciliation']['whole_original_branch'].update(proposed_future_disposition='restore allowed')),
 ('branch turned executable selector',lambda a:a['branch_reviews'][0].update(is_executable_action_selector=True)),
 ('one microstep omitted',lambda a:a['owned_microstep_reviews'].pop()),
 ('within-cut review omitted',lambda a:a['owned_microstep_reviews'][6]['complete_paper_cut_reviews'].pop(1)),
 ('paper fault made actual',lambda a:a['owned_microstep_reviews'][6]['complete_paper_cut_reviews'][1].update(actual_effective_native_fault={})),
 ('one status case omitted',lambda a:a['paper_status_cases'].pop()),
 ('unknown restore completed from target match',lambda a:a['paper_status_cases'][3]['status_projection'].update(target_fact_completes_unknown_ACK=True)),
 ('unknown action may repeat',lambda a:a['paper_status_cases'][3]['status_projection'].update(unknown_action_may_repeat=True)),
 ('claim launch reopened',lambda a:a['paper_status_cases'][9]['status_projection'].update(claim_or_launch_may_reopen=True)),
 ('spend refunded',lambda a:a['paper_status_cases'][8]['status_projection'].update(spend_may_refund=True)),
 ('verification selected',lambda a:a['paper_status_cases'][7]['status_projection'].update(verification_selected=True)),
 ('original failure erased',lambda a:a['paper_status_cases'][16]['status_projection']['separate_original_status_components'].update(original_forward_failed=False)),
 ('restored production rebinds audit pin',lambda a:a['raw_binding_review'].update(audit_pin_rebound_to_restored_production=True)),
 ('logical rows rebind raw bytes',lambda a:a['raw_binding_review'].update(logical_rows_rebind_raw_bytes=True)),
 ('new question omitted',lambda a:a['new_findings'].pop()),
 ('status vector made recovery selector',lambda a:a['interpretation_limit'].update(reader_is_executable_recovery_selector=True)),
 ('fresh explicit grant gate removed',lambda a:a['remaining_review_and_approval_order'].pop(2)),
 ('next step skips actual acceptance',lambda a:a.update(next_preparable_step_after_complete413_acceptance=415)),
 ('automatic419 permitted',lambda a:a.update(no_automatic419=False))]
for label,mutate in mutations:
    bad=copy.deepcopy(audit);mutate(bad);check('reject '+label,rejects(module['validate_audit'],bad,inputs,sources,policy))
for row in audit['branch_reviews']:
    check('whole original recovery branch '+row['id'],row['whole_storage404_reconciliation']['whole_original_branch']['id']==row['id'] and not row['is_executable_action_selector'] and not row['current_recovery_authority'])
for row in audit['owned_microstep_reviews']:
    check('whole ordered microstep and all three paper cuts '+row['source_step'],[c['location'] for c in row['complete_paper_cut_reviews']]==['before','within','after'] and all(c['actual_effective_native_fault'] is None for c in row['complete_paper_cut_reviews']))
byid={r['case']['id']:r['case'] for r in audit['paper_status_cases']}
r=module['status_vector'](byid['S04-lost-restore-ACK-qualified-match']);v=r['separate_original_status_components']
check('qualified target match never completes unknown restore ACK',v['qualified_captured_target_fact']=='qualified-original-match-at-capture-cut' and v['restore_outcome']=='unknown' and 'restore_outcome' in r['pending_component_names'] and not r['target_fact_completes_unknown_ACK'] and not r['unknown_action_may_repeat'])
r=module['status_vector'](byid['S08-spent-right-no-new-verification'])
check('spent original action and exhausted verification right remain separate',r['separate_original_status_components']['original_action_spend']=='known-spent' and r['separate_original_status_components']['original_verification_right']=='known-exhausted' and not r['verification_selected'])
r=module['status_vector'](byid['S17-original-failure-pending'])
check('original failure captured match and owned controller pending survive together',r['separate_original_status_components']['original_forward_failed'] is True and 'owned_commit_outcome' in r['pending_component_names'] and 'controller_outcome' in r['pending_component_names'])
r=module['status_vector'](byid['S18-original-status-unknown'])
check('unknown original failure mismatch stays null not no-failure',r['separate_original_status_components']['original_forward_failed'] is None and r['separate_original_status_components']['original_mismatch'] is None)
bad=copy.deepcopy(byid['S17-original-failure-pending']);bad['original_forward_failed']=1
check('reject integer as original failure boolean',rejects(module['status_vector'],bad))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual412 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['storage404']+=b' '
check('reject storage source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['reader_is_executable_recovery_selector']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('prepared result preserves full branch microstep status scope without native rights',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure reader imports only hashlib json re without native dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
