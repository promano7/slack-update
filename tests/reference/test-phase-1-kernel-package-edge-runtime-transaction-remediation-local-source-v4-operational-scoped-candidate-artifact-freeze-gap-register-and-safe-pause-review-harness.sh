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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-scoped-candidate-artifact-freeze-gap-register-and-safe-pause-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact338 scoped candidate freeze tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='7c3f231ce3f05b5a2818ec0cf9087851c4ed6d810fde4b3e3a40b1b36304b0d7')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step338_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes())
policy=load('-policy.json');freeze=load('-freeze.json');gaps=load('-gap-register.json');history=ns['verify_history'](root,policy)
validate=lambda value:ns['validate_candidate_freeze'](value,gaps,history)
validate_gaps=lambda value:ns['validate_candidate_freeze'](freeze,value,history)
check('1620 accepted bytes with only additive CHANGELOG',len(history)==1620)
check('complete337 original450 PASS receipt retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step337-user-acceptance.json')))
check('scoped repository input freeze and native gap register valid',validate(freeze))
check('81 accepted inputs329-337 frozen individually by source SHA',len(freeze['frozen_input_artifact_registry329_337'])==81 and all(sum(r['step']==step for r in freeze['frozen_input_artifact_registry329_337'])==9 for step in range(329,338)) and all(hashlib.sha256(history[r['path']]).hexdigest()==r['sha256'] for r in freeze['frozen_input_artifact_registry329_337']))
check('all nine accepted predecessor returns present',len(freeze['accepted_batch329_337'])==9 and [r['step'] for r in freeze['accepted_batch329_337']]==list(range(329,338)) and all(r['complete_user_acceptance'] and r['commit_full'] is None for r in freeze['accepted_batch329_337']))
check('current338 closure bookkeeping separately pending',freeze['current338_closure_artifacts']['count']==9 and freeze['current338_closure_artifacts']['user_current_acceptance_pending'] and freeze['user_step338_checkpoint_confirmed'] is False and freeze['strong_safe_pause'] is False)
check('all nine original conditional pause requirements retain current338 pending gate',len(freeze['conditional_pause_requirements'])==9 and freeze['conditional_pause_requirements'][0]['status']=='required-current338-complete-user-return-not-yet-confirmed' and all(r['actual338_user_confirmation'] is None for r in freeze['conditional_pause_requirements']))
check('stop after338 acceptance no339 or runtime work authorized',freeze['stop_after_complete338_acceptance'] and freeze['next_authorized_stage'] is None and freeze['new_runtime_work_authorized'] is False)
check('all native proofs46 cases52 gaps16 cuts81 microsteps9 unchanged',len(gaps['qualified_proofs'])==46 and len(gaps['native_case_templates'])==52 and len(gaps['native_gap_register'])==16 and len(gaps['macro_cut_obligations'])==81 and len(gaps['owned_stage7_microsteps'])==9)
check('both native platform sets remain separately26 unrun',[sum(c['platform']==p for c in gaps['native_case_templates']) for p in ['Slackware-15.0','Slackware-current']]==[26,26] and all(c['status']=='required-not-run' and c['actual_result'] is None for c in gaps['native_case_templates']))
check('all frozen native windows unbound',all(r['inherited_window']['actual_authority_valid'] is False and all(r['inherited_window'][k] is None for k in ['actual_issuer','actual_scope','actual_fence','actual_budget','actual_deadline']) for r in freeze['authority_window_reconciliation']))
for key in ['actual_operational_implementation_frozen','actual_dynamic_graph_complete','actual_native_refinement_complete','actual_independent_oracle_selected','actual_operational_conformance','operational_readiness','runtime_authority','actual_global_host_closure_asserted','historical_v2_or_reference_main_sourced_run','machine_action_required','controller_action_required','user_step338_checkpoint_confirmed','strong_safe_pause','phase2_open','phase1_matrix_complete','kernel_package_edge_complete','new_runtime_work_authorized']:
    check('candidate artifact freeze cannot promote native or premature user closure '+key,rejected(validate,mutated(freeze,[key],True)))
for key,value in [('scope','global-host-closure'),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),('actual_native_cases_run',1),('actual_proofs_added',1),('next_authorized_stage','339'),('production_entry_closed',False),('stop_after_complete338_acceptance',False),('conditional_pause_requirements',[])]:check('freeze boundary cannot waive scoped stop rule '+key,rejected(validate,mutated(freeze,[key],value)))
for i,row in enumerate(freeze['frozen_input_artifact_registry329_337']):check('each frozen input cannot drift '+str(row['step'])+'/'+row['path'],rejected(validate,mutated(freeze,['frozen_input_artifact_registry329_337',i,'sha256'],'0'*64)))
for i,row in enumerate(freeze['accepted_batch329_337']):check('each complete predecessor receipt remains required '+str(row['step']),rejected(validate,mutated(freeze,['accepted_batch329_337',i,'complete_user_acceptance'],False)))
for i,row in enumerate(gaps['qualified_proofs']):
    check('each qualified native proof remains pending '+row['qualified_id'],rejected(validate_gaps,mutated(gaps,['qualified_proofs',i,'status'],'PASS')))
    check('private PASS cannot become native proof evidence '+row['qualified_id'],rejected(validate_gaps,mutated(gaps,['qualified_proofs',i,'actual_evidence'],{'private_PASS':True})))
for i,row in enumerate(gaps['native_case_templates']):check('each native case remains unrun '+row['platform']+'/'+row['case_id'],rejected(validate_gaps,mutated(gaps,['native_case_templates',i,'status'],'PASS')))
for i,row in enumerate(gaps['native_gap_register']):check('each native selection gap remains blocker '+row['inherited_gap']['id'],rejected(validate_gaps,mutated(gaps,['native_gap_register',i,'status'],'closed')))
for key in ['actual_independent_oracle_selected','actual_runtime_authority','actual_implementation_frozen','actual_operational_conformance','actual_operational_readiness','actual_global_host_closure']:check('gap register cannot create actual native closure '+key,rejected(validate_gaps,mutated(gaps,[key],True)))
for key in ['macro_cut_obligations','owned_stage7_microsteps','qualified_proofs','native_case_templates','native_gap_register']:check('no proof case gap or cut waiver '+key,rejected(validate_gaps,mutated(gaps,[key],[])))
q=dict(origin='synthetic-private-fixture',step=338,scope='repository-candidate-refinement-workstream329-338-only',runtime_authority=False,live_binding=None,actual_host_state='unobserved-not-claimed-absent',checks={k:True for k in ['complete_ordered_tests','exact_commit_scope','successful_push','clean_worktree','HEAD_matches_origin','exact_repository_snapshot']})
evaluate=ns['evaluate_private_closure_return'];answer=evaluate(q)
check('synthetic complete return only reviewable never actually confirmed',answer['model_scoped_pause_confirmation_eligible'] and not any(v for k,v in answer.items() if k.startswith('actual_')))
for key in q['checks']:
    answer=evaluate(mutated(q,['checks',key],False));check('each incomplete current338 return check prevents confirmation '+key,not answer['model_scoped_pause_confirmation_eligible'] and answer['model_pending_return_checks']==[key])
    check('current338 return check exact bool '+key,rejected(evaluate,mutated(q,['checks',key],1)))
    value=copy.deepcopy(q);del value['checks'][key];check('current338 return check never omitted '+key,rejected(evaluate,value))
for key,value in [('origin','actual-host-observation'),('step',339),('step',True),('scope','global-host-closure'),('scope','operational-implementation-freeze'),('runtime_authority',True),('live_binding',{'boot':'old'}),('actual_host_state','absent')]:check('private closure cannot claim native or global facts '+key+'/'+str(value),rejected(evaluate,dict(q,**{key:value})))
check('extra new grant rejected at pause handoff',rejected(evaluate,dict(q,new_grant=True)))
for example in gaps['private_confirmation_examples']:check('private closure fixture no actual evidence '+example['id'],evaluate(example['input'])==example['result'] and example['actual_evidence'] is None)
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict338 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('338 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('338 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step338-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual338 entry reruns full450 predecessor and complete historical coverage',result.returncode==0 and 'exact_step337_acceptance\tPASS (450 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered450 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==450 and lines[-1]=='Result: PASS (450 passes, 0 failures)')
    for suffix in ['-policy.json','-freeze.json','-gap-register.json','-checkpoint-confirmation.json','-step337-user-acceptance.json','-frozen-artifact-map.tsv']:
        check('exact338 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('reconciliation grants no actual authority or native closure','actual_runtime_authority_or_native_closure\tno' in result.stdout and 'actual_native_cases_run\t0' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+[ns['RECONCILIATION_PATH']]+['tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed338 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1620 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
