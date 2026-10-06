#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast
import copy
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
passes=0
def check(label,condition):
    global passes
    if not condition:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,TypeError,KeyError,OSError,SyntaxError):return True
    return False
def mutated(value,path,new):
    x=copy.deepcopy(value);p=x
    for k in path[:-1]:p=p[k]
    p[path[-1]]=new;return x
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
check('exact334 failure-refinement tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='0fb916c66dd04a283173a59f119e2195b5a3dbb0ad7cb01a3920b154ddd98dbf')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step334_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');review=load('-refinement.json');history=ns['verify_history'](root,policy)
manifest=json.loads(history[ns['MANIFEST_PATH']]);legacy=json.loads(history[ns['LEGACY_PATH']]);phase=manifest['exact_phase_contract']
def validate(v):return ns['validate_failure_refinement'](v,history,manifest,legacy)
check('1584 accepted bytes and additive CHANGELOG only',len(history)==1584)
check('complete333 external receipt with1400 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step333-user-acceptance.json')))
check('exact source-bound failure-refinement obligations accepted as data only',validate(review))
check('31 macro events map by32 links to25 distinct candidate phases',len(review['legacy_to_candidate'])==31 and sum(len(r['candidate_phase_ids']) for r in review['legacy_to_candidate'])==32 and len({p for r in review['legacy_to_candidate'] for p in r['candidate_phase_ids']})==25)
check('two unmatched explicit candidate boundaries remain pending',[r['phase_id'] for r in review['unmatched_explicit_legacy_boundaries']]==['worker0-readonly-preflight','stop-forward-irreversibly'])
check('all81 macro cuts pending and all nine owned binding microsteps source-exact',len(review['candidate_boundary_cuts'])==81 and all(r['status']=='required-not-refined' and r['actual_instruction_or_syscall'] is None and not r['runtime_authorized'] for r in review['candidate_boundary_cuts']) and [r['source_step'] for r in review['stage7_owned_microstep_obligations']]==phase['stage7_owned_commit_sequence'])
check('exact2938 declared families never universal native schedules',review['legacy_model_coverage']==legacy['model_coverage'] and review['legacy_model_coverage']['total_case_count']==2938 and review['legacy_model_contract']==legacy['model_contract'] and not review['actual_native_refinement_complete'])
check('all23 hazards and eight forbidden actions retained',len(review['hazard_register'])==23 and [r['id'] for r in review['hazard_register']]==legacy['model_domains']['hazards'] and review['forbidden_actions']==legacy['model_domains']['forbidden'] and len(review['forbidden_actions'])==8)
check('all16 native gap obligations retain inherited binding and null proof',len(review['native_gap_register'])==16 and [r['inherited_gap'] for r in review['native_gap_register']]==manifest['actual_selection_gaps'] and all(r['actual_independent_evidence'] is None for r in review['native_gap_register']))
check('all46 proofs52 separate cases and exact phase contract preserved',review['qualified_proof_register']==manifest['qualified_proof_register'] and len(review['qualified_proof_register'])==46 and review['independent_platform_cases']==manifest['independent_platform_cases'] and len(review['independent_platform_cases'])==52 and review['exact_phase_contract']==phase)
for key in ['actual_native_refinement_complete','actual_fault_schedules_selected','actual_native_graph_complete','actual_operational_conformance','operational_readiness','runtime_authority','actual_global_host_closure_asserted','machine_action_required','controller_action_required','historical_v2_or_reference_main_sourced_run','user_step334_checkpoint_confirmed','strong_safe_pause']:
 check('refinement review cannot promote native proof authority '+key,rejected(validate,mutated(review,[key],True)))
for key,new in [('schema',True),('step',True),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),('manifest_binding',{}),('legacy_model_binding',{}),('unmatched_explicit_legacy_boundaries',[]),('legacy_model_coverage',{}),('exact_phase_contract',{}),('fault_disposition_contract',{})]:
 check('refinement source or blocker cannot be waived '+key,rejected(validate,mutated(review,[key],new)))
for i,row in enumerate(review['legacy_to_candidate']):
 for key,new in [('candidate_phase_ids',['unreviewed-phase']),('actual_native_events',['syscall-proven']),('status','refinement-complete')]:
  check('legacy split or merge never native equivalence '+row['legacy_event']+' '+key,rejected(validate,mutated(review,['legacy_to_candidate',i,key],new)))
for i,row in enumerate(review['candidate_boundary_cuts']):
 for key,new in [('status','proven'),('actual_fault_schedule',['crash-tested']),('runtime_authorized',True)]:
  check('macro cut retains native injection and proof gap '+row['id']+' '+key,rejected(validate,mutated(review,['candidate_boundary_cuts',i,key],new)))
for i,row in enumerate(review['stage7_owned_microstep_obligations']):
 check('stage7 microstep never inferred durable '+str(i),rejected(validate,mutated(review,['stage7_owned_microstep_obligations',i,'actual_durability_evidence'],{'PASS':True})))
for i,row in enumerate(review['native_gap_register']):
 check('native gap cannot close '+row['inherited_gap']['id'],rejected(validate,mutated(review,['native_gap_register',i,'status'],'closed')))
for i,row in enumerate(review['hazard_register']):
 check('hazard not actual injection evidence '+row['id'],rejected(validate,mutated(review,['hazard_register',i,'actual_evidence'],{'PASS':True})))
for i,row in enumerate(review['qualified_proof_register']):check('proof cannot be inferred from macro mapping '+row['qualified_id'],rejected(validate,mutated(review,['qualified_proof_register',i,'operational_proven'],True)))
for i,row in enumerate(review['independent_platform_cases']):check('independent native case stays unrun '+row['platform']+'/'+row['case_id'],rejected(validate,mutated(review,['independent_platform_cases',i,'status'],'PASS')))
evaluate=lambda q:ns['evaluate_private_fault_disposition'](q,phase)
for p in phase['entry_trace']:
 for scope in ['owned-only','target','control','publication']:
  for outcome in ['known-complete','known-failed','unknown','not-attempted']:
   q=ns['private_fault_record'](p,scope,outcome);answer=evaluate(q)
   check('private fault disposition no native closure or replay '+p['id']+' '+scope+' '+outcome,not any(v for k,v in answer.items() if k.startswith('actual_')) and not answer['model_automatic_recovery'] and not answer['model_unknown_action_replay_allowed'] and not answer['model_target_refresh_after_release_allowed'] and not answer['model_no_additional_effect_inferred'] and answer['model_unknown_scope_pending']==(outcome=='unknown'))
   if outcome=='unknown' and scope in ['target','control']:
    check('unknown target or control denies both recovery review branches '+p['id']+' '+scope,not answer['model_separate_original_verification_reviewable'] and not answer['model_separate_backed_restoration_reviewable'])
   if scope=='publication' or p['rights_window']=='publication':
    check('publication fault never allows target recovery '+p['id']+' '+scope+' '+outcome,not answer['model_separate_original_verification_reviewable'] and not answer['model_separate_backed_restoration_reviewable'])
q=ns['private_fault_record'](phase['entry_trace'][15]);q['conditions']['verified_original_backups']=False;answer=evaluate(q)
check('unknown owned-only binding may leave separate known-safe unchanged verification without backups',answer['model_retained_owned_artifacts_required'] and answer['model_separate_original_verification_reviewable'] and not answer['model_separate_backed_restoration_reviewable'] and not answer['model_never_created_backups_required_for_verification'])
q=ns['private_fault_record'](phase['entry_trace'][16],'target','known-failed');q['conditions']['independently_unchanged_target']=False;answer=evaluate(q)
check('known target failure with original exact verified backups has only inert backed restoration review',answer['model_separate_backed_restoration_reviewable'] and not answer['model_separate_original_verification_reviewable'] and not answer['actual_target_restored'])
for k in ns['FAULT_GATES']:
 check('every independent condition is bool '+k,rejected(evaluate,mutated(q,['conditions',k],1)))
 if k not in ['verified_original_backups','independently_unchanged_target']:
  answer=evaluate(mutated(q,['conditions',k],False));check('missing original known condition denies review '+k,not answer['model_separate_original_verification_reviewable'] and not answer['model_separate_backed_restoration_reviewable'])
answer=evaluate(mutated(q,['conditions','verified_original_backups'],False));check('no unchanged proof and no verified backups denies both branches',not answer['model_separate_original_verification_reviewable'] and not answer['model_separate_backed_restoration_reviewable'])
for raw in [-1,0,1,2,20,128,137,143]:
 answer=evaluate(dict(q,raw_fixture_status=raw));check('original private raw status retained without no-effect inference '+str(raw),answer['model_original_raw_fixture_status']==raw and not answer['model_no_additional_effect_inferred'])
for key,new in [('origin','actual-host'),('scope','execute-recovery'),('phase_id','new-phase'),('caller_actor','new-actor'),('rights_window','new-unused-grant'),('effect_scope','global-host'),('outcome','retry-allowed'),('raw_fixture_status',True),('raw_fixture_status',999),('conditions',{})]:
 check('private schema cannot promote authority or context '+key,rejected(evaluate,dict(q,**{key:new})))
check('extra grant field rejected',rejected(evaluate,dict(q,new_grant=True)))
check('known complete with failed raw status rejected',rejected(evaluate,dict(q,outcome='known-complete',raw_fixture_status=20)))
for example in load('-private-dispositions.json')['examples']:
 check('exact private disposition example and no native evidence '+example['id'],evaluate(example['input'])==example['result'] and example['actual_evidence'] is None)
check('historical stage7 readonly descriptor never altered',rejected(validate,mutated(review,['exact_phase_contract','frozen_worker_stages',7,'effect'],'owned-files')))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict334 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('334 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('334 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step334-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual334 entry reruns full1400 predecessor and complete historical coverage',result.returncode==0 and 'exact_step333_acceptance\tPASS (1400 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered1400 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==1400 and lines[-1]=='Result: PASS (1400 passes, 0 failures)')
    for suffix in ['-policy.json','-refinement.json','-private-dispositions.json','-checkpoint-confirmation.json','-step333-user-acceptance.json','-native-gap-register.tsv']:
        check('exact334 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('fault mapping grants no native refinement or recovery','actual_native_refinement_or_recovery_authorized\tno' in result.stdout and 'required_proofs_and_independent_cases\t46-unproven/52-unrun' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+[ns['MANIFEST_PATH'],ns['LEGACY_PATH'],'tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed334 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1584 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
