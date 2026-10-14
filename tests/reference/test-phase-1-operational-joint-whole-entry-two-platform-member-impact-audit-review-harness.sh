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
root=Path(sys.argv[1]);step='phase-1-operational-joint-whole-entry-two-platform-member-impact-audit-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,audit,sources,policy=[load(s) for s in ['entry414','baseline','audit','sources','policy']]
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
check('whole authored415 fixtures bound',module['validate_fixtures']({'entry414':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual414 return74PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all133 whole inputs and41 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('all15 categories1286 WHOLE member impacts and full entry oracle context',module['validate_audit'](audit,inputs,sources,policy))
check('all2242 historical414 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
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
 ('one global rule waived',lambda a:a['whole_nine_global_semantic_rules'].pop('S406')),
 ('prior414 membership question omitted',lambda a:a['whole_accepted414_findings'].pop()),
 ('prior413 action identity question omitted',lambda a:a['whole_accepted413_findings'].pop()),
 ('inactive410 clarification activated',lambda a:a['whole_accepted410_clarifications'][0].update(normative_activation=True)),
 ('all1286 authored visits made independent acceptance',lambda a:a['interpretation_limit'].update(all1286_semantic_migration_independently_accepted=True)),
 ('paper reader selected as native oracle',lambda a:a['interpretation_limit'].update(paper_vector_reader_is_native_oracle=True)),
 ('private351 literals made native expectations',lambda a:a['interpretation_limit'].update(original_raw_expectations_replaced_by_private351_literals=True)),
 ('other-platform evidence transferred',lambda a:a['interpretation_limit'].update(cross_platform_evidence_transfer_allowed=True)),
 ('whole entry reduced to three calls',lambda a:a['interpretation_limit'].update(whole_entry_replaced_by_three_calls=True)),
 ('hash census made dynamic consumption proof',lambda a:a['interpretation_limit'].update(source_hash_or_census_proves_dynamic_consumption=True)),
 ('requested fault made effective native cut',lambda a:a['interpretation_limit'].update(requested_fault_proves_effective_cut=True)),
 ('role names made independence',lambda a:a['interpretation_limit'].update(distinct_people_or_role_names_prove_independence=True)),
 ('verifier forbidden from independent expectation authorship',lambda a:a['interpretation_limit'].update(verifier_may_author_independent_expectations=False)),
 ('member map resolves open findings',lambda a:a['interpretation_limit'].update(open_findings_resolved_by_mapping=True)),
 ('fresh explicit grant gate removed',lambda a:a['remaining_review_and_approval_order'].pop(2)),
 ('next step skips actual acceptance',lambda a:a.update(next_preparable_step_after_complete415_acceptance=417)),
 ('automatic419 permitted',lambda a:a.update(no_automatic419=False)),
 ('whole406 context shortened',lambda a:a['whole_entry_oracle406_context'].pop('all8_source_surface_reconciliations')),
 ('oracle own role omitted',lambda a:a['whole_entry_surface_role_fault_reviews']['all6_oracle_role_reconciliations'].pop())]
for label,mutate in mutations:
    bad=copy.deepcopy(audit);mutate(bad);check('reject '+label,rejects(module['validate_audit'],bad,inputs,sources,policy))
packet=json.loads(inputs['packet407']);original=packet['all15_category1286_whole_member_acceptance_matrix'];matrix=audit['all15_category1286_member_impact_reviews']
for source,category in zip(original,matrix):
    check('whole category '+category['category_id']+' '+str(len(category['member_reviews']))+' original members',category['ordered_member_ids']==source['ordered_member_ids'] and len(category['member_reviews'])==len(source['members']) and not category['semantic_migration_independently_accepted'])
needed={m['source_input_key'] for c in original for m in c['members']};documents={k:json.loads(inputs[k]) for k in needed}
member_mutations=[
 ('original nested member shortened',1,0,lambda r:r['whole_frozen407_member'].update(whole_original_member=[])),
 ('complete specific criterion shortened',3,0,lambda r:r.update(complete_specific_candidate_evidence_reviewed='short')),
 ('local focus waives global rules',3,0,lambda r:r.update(local_focus_does_not_waive_any_global_rule_or_other_open_finding=False)),
 ('member review made original equivalence',3,0,lambda r:r.update(unchanged_original_equivalence_established=True)),
 ('own case platform borrowed',4,0,lambda r:r['own_platform_obligations'][0].update(platform='Slackware-current')),
 ('actual native version invented',4,0,lambda r:r['own_platform_obligations'][0].update(actual_version='invented')),
 ('fresh authority invented',4,0,lambda r:r['own_platform_obligations'][0].update(actual_fresh_explicit_authority={})),
 ('raw group expectation replaced',5,0,lambda r:r.update(specific_member_assessment='private351 fixture is the native oracle')),
 ('relation proof side shortened',6,0,lambda r:r['proof_AND_case_review'].update(complete_proof_specific_criterion='short')),
 ('relation case side shortened',6,0,lambda r:r['proof_AND_case_review'].update(complete_case_specific_criterion='short')),
 ('relation whole proof pointer rebound',6,0,lambda r:r['proof_AND_case_review'].update(whole_proof_member_pointer='/all15_category1286_whole_member_acceptance_matrix/3/members/1')),
 ('relation whole case pointer rebound',6,0,lambda r:r['proof_AND_case_review'].update(whole_case_member_pointer='/all15_category1286_whole_member_acceptance_matrix/4/members/26')),
 ('proof AND case made either side',6,0,lambda r:r['proof_AND_case_review'].update(either_side_sufficient=True)),
 ('one-platform relation made native proof',6,0,lambda r:r['proof_AND_case_review'].update(native_proof=True))]
for label,i,j,mutate in member_mutations:
    row=copy.deepcopy(matrix[i]['member_reviews'][j]);mutate(row)
    check('reject '+label,rejects(module['validate_member_review'],row,original[i]['members'][j],original[i]['category_id'],packet,documents,policy['expected_member_review_sha256'][i][j]))
byid={r['case']['id']:r for r in audit['paper_raw_declaration_comparisons']}
def result(id_):return module['declared_vector_comparison'](byid[id_]['case'])
r=result('V01-matching-paper-declarations-not-native-proof');check('equal paper declarations never native conformance or grant',r['supplied_declarations_equal'] and not r['native_conformance_proven'] and not r['native_raw_artifacts_compared'] and not r['runtime_authority'])
r=result('V02-selector-order-changed');check('complete selector order retained',r['known_mismatch_paths']==['/vector/selector/0','/vector/selector/1'])
r=result('V03-selector-multiplicity-lost');check('duplicate selector multiplicity retained','/vector/selector/length' in r['known_mismatch_paths'])
for id_,label in [('V04-raw20-not0','raw20 distinct from0'),('V05-raw-minus1-not20','raw-minus1 distinct from20')]:check(label,'/vector/raw_status' in result(id_)['known_mismatch_paths'])
check('boolean status not integer0','/vector/raw_status/type' in result('V06-boolean-is-not-integer-status')['known_mismatch_paths'])
r=result('V07-null-is-not-empty-vector');check('null capture stays unknown not empty',r['unknown_paths']==['/vector/selector'] and not r['supplied_declarations_equal'])
r=result('V08-mismatch-and-missing-capture');check('known mismatch and missing capture pending coexist','/vector/raw_status' in r['known_mismatch_paths'] and '/vector/effects' in r['unknown_paths'] and r['pending_obligations_retained'])
r=result('V09-known-failure-with-matching-target');check('known original failure survives matching declarations',r['supplied_declarations_equal'] and r['original_forward_failed'] is True and not r['original_failure_erased'])
for id_,field in [('V10-other-platform-cannot-discharge-own-row','platform'),('V11-other-run-cannot-discharge-own-row','run')]:check('own '+field+' identity cannot be borrowed','/binding/'+field in result(id_)['known_mismatch_paths'])
check('unknown authority stays pending not grant','/binding/authority' in result('V12-unknown-authority-not-grant')['unknown_paths'])
check('logical rows never rebind exact raw bytes','/vector/raw_bytes_hex' in result('V13-logical-rows-do-not-rebind-raw-bytes')['known_mismatch_paths'])
check('qualified target match never completes unknown restore ACK','/vector/restore_ACK' in result('V14-unknown-restore-ACK-with-known-target')['unknown_paths'])
check('later unclassified effect retained','/vector/unclassified_later_effect/unexpected' in result('V15-future-undeclared-effect-visible')['known_mismatch_paths'])
check('empty selector differs from one target','/vector/selector/length' in result('V16-empty-is-not-one-target')['known_mismatch_paths'])
r=result('V17-unknown-failure-not-no-failure');check('unknown original failure stays null',r['original_forward_failed'] is None and '/original_forward_failed' in r['unknown_paths'])
check('later cleanup cannot remove earlier raw status','/vector/statuses/length' in result('V18-later-cleanup-does-not-erase-earlier-status')['known_mismatch_paths'])
bad=copy.deepcopy(byid['V01-matching-paper-declarations-not-native-proof']['case']);bad['original_forward_failed']=1
check('reject integer as original failure boolean',rejects(module['declared_vector_comparison'],bad))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual414 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['packet407']+=b' '
check('reject whole member source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['actual_native_oracle_selected']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('prepared full member result grants no native rights acceptance or pause',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure reader imports only hashlib json re without native dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
