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
root=Path(sys.argv[1]);step='phase-1-operational-joint-stage12-receipt-custody-terminal-audit-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,audit,sources,policy=[load(s) for s in ['entry413','baseline','audit','sources','policy']]
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
check('whole authored414 fixtures bound',module['validate_fixtures']({'entry413':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual413 return79PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all129 whole inputs and40 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('whole stage12 receipt custody context10 events6 roles28 paper cases',module['validate_audit'](audit,inputs,sources,policy))
check('all2234 historical413 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
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
 ('one global rule waived',lambda a:a['whole_nine_global_semantic_rules'].pop('E405')),
 ('whole405 causal context shortened',lambda a:a['whole_publication405_context'].pop('whole_original384_causal_and_event_review')),
 ('original whole stage12 shortened',lambda a:a['whole_current316_stage12'].update(operation='producer only suffices')),
 ('one exact inactive stage replacement omitted',lambda a:a['whole_frozen_inactive_stage_and_terminal_replacements'].pop()),
 ('prior413 question omitted',lambda a:a['whole_accepted413_findings'].pop()),
 ('one event omitted',lambda a:a['event_reviews'].pop()),
 ('one own actor omitted',lambda a:a['role_reviews'].pop()),
 ('observer exempted',lambda a:a['role_reviews'][3].update(is_exempt_observer=True)),
 ('whole subject event changed',lambda a:a['event_reviews'][3]['whole_publication405_event']['whole_original394_event'].update(proposed_subject_stage12_member=False)),
 ('one declared edge omitted',lambda a:a['whole_declared_comparison_graph']['edges'].pop()),
 ('one paper case omitted',lambda a:a['paper_publication_cases'].pop()),
 ('payload proves own future completion',lambda a:a['paper_publication_cases'][2]['publication_projection'].update(payload_proves_own_future_completion=True)),
 ('paper DAG made native closure proof',lambda a:a['paper_publication_cases'][27]['publication_projection'].update(native_closure_proven=True)),
 ('declared events made effect grant',lambda a:a['paper_publication_cases'][27]['publication_projection'].update(runtime_authority=True)),
 ('pending writer outcome erased',lambda a:a['paper_publication_cases'][4]['publication_projection'].update(pending_obligations_retained=False)),
 ('duplicate declarations made observed native replay',lambda a:a['paper_publication_cases'][24]['publication_projection'].update(duplicate_label_proves_observed_native_replay=True)),
 ('new membership question omitted',lambda a:a['new_findings'].pop()),
 ('actual graph implementation selected',lambda a:a['interpretation_limit'].update(actual_native_graph_selected=True)),
 ('own actor controls waived',lambda a:a['interpretation_limit'].update(all_own_actor_global_controls_still_required=False)),
 ('fresh explicit grant gate removed',lambda a:a['remaining_review_and_approval_order'].pop(2)),
 ('next step skips actual acceptance',lambda a:a.update(next_preparable_step_after_complete414_acceptance=416)),
 ('automatic419 permitted',lambda a:a.update(no_automatic419=False))]
for label,mutate in mutations:
    bad=copy.deepcopy(audit);mutate(bad);check('reject '+label,rejects(module['validate_audit'],bad,inputs,sources,policy))
for row in audit['event_reviews']:check('whole source event '+row['event_id'],row['whole_publication405_event']['whole_original394_event']['event_id']==row['event_id'] and not row['runtime_authority'])
for row in audit['role_reviews']:check('whole own actor controls '+row['role_question'],not row['is_exempt_observer'] and row['whole_publication405_role']['complete_own_descendant_FD_stream_storage_origin_required'] and not row['runtime_authority'])
graph=audit['whole_declared_comparison_graph'];byid={r['case']['id']:r['case'] for r in audit['paper_publication_cases']}
r=module['publication_vector'](byid['P02-payload-before-subject-closure'],graph)
check('paper payload before subject closure violates declared causal edge',['subject-trace-closed','receipt-payload-bound'] in r['declared_edge_order_violations'])
r=module['publication_vector'](byid['P22-final-observer-custody-order-independent'],graph)
check('observer and custody may exchange paper order without invented edge',r['declared_graph_order_satisfied'] and not r['native_closure_proven'] and not r['runtime_authority'])
r=module['publication_vector'](byid['P23-custody-before-receipt'],graph)
check('custody declaration before receipt violates existing dependency',['receipt-commit-known','custody-handoff-known'] in r['declared_edge_order_violations'])
r=module['publication_vector'](byid['P25-duplicate-label-identities-unknown'],graph)
check('duplicate event positions retained without native replay inference',r['duplicate_label_positions']==[{'label':'receipt-commit-known','positions':[5,6]}] and r['unresolved_declared_edges'] and not r['duplicate_label_proves_observed_native_replay'])
r=module['publication_vector'](byid['P07-target-object-facts-plus-writer-unknown'],graph)
check('qualified target object facts survive sticky failure and writer pending',r['qualified_target_fact']=='hypothetical-qualified-target-at-capture-cut' and r['qualified_object_fact']=='hypothetical-qualified-final-object-at-capture-cut' and r['original_forward_failed'] is True and 'positive_flags/receipt_writer_trace_closed' in r['unknown_premises'] and r['pending_obligations_retained'])
r=module['publication_vector'](byid['P12-later-unclassified-effect'],graph)
check('later unclassified effect not erased by declared terminal cut','negative_flags/later_unclassified_effect' in r['known_failed_premises'] and r['unclassified_declared_events'] and not r['native_closure_proven'])
for role in module['ROLE_IDS']:
    case=copy.deepcopy(byid['P28-all-paper-premises-not-native-proof']);case['own_role_controls'][role]=None;r=module['publication_vector'](case,graph)
    check('each own role retains independent controls '+role,'own_role_controls/'+role in r['unknown_premises'] and r['pending_obligations_retained'] and not r['runtime_authority'])
r=module['publication_vector'](byid['P28-all-paper-premises-not-native-proof'],graph)
check('all paper premises and order never prove actual native closure',r['declared_graph_order_satisfied'] and not r['known_failed_premises'] and not r['unknown_premises'] and not r['native_closure_proven'] and not r['new_publication_or_target_right'])
bad=copy.deepcopy(byid['P28-all-paper-premises-not-native-proof']);bad['positive_flags']['receipt_commit_known']=1
check('reject integer as known commit boolean',rejects(module['publication_vector'],bad,graph))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual413 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['publication405']+=b' '
check('reject whole publication source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['actual_native_graph_selected']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('prepared result retains whole event role case scope without native rights',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure reader imports only hashlib json re without native dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
