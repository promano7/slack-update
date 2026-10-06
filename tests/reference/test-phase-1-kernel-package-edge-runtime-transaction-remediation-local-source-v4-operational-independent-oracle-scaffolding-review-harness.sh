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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact335 oracle scaffolding tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='23ebbf76f5dd0bb520620dcd58308a2ee7607e117374a4d062e194b19d4d4e92')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step335_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');scaffold=load('-scaffold.json');history=ns['verify_history'](root,policy);refinement=json.loads(history[ns['REFINEMENT_PATH']]);legacy=json.loads(history[ns['LEGACY_PATH']])
def validate(v):return ns['validate_oracle_scaffold'](v,history,refinement,legacy)
evaluate=lambda q:ns['evaluate_private_oracle_packet'](q,scaffold)
check('1593 accepted bytes and additive CHANGELOG only',len(history)==1593)
check('complete334 external receipt with1242 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step334-user-acceptance.json')))
check('source-bound independent oracle scaffold valid as data only',validate(scaffold))
check('all52 native case templates copy source326 exactly',[r['inherited_case'] for r in scaffold['cases']]==legacy['conformance_plan'] and len(scaffold['cases'])==52 and all(r['status']=='required-not-run' and r['actual_result'] is None for r in scaffold['cases']))
check('26 separate native cases each15.0-current',[sum(r['platform']==p for r in scaffold['cases']) for p in ['Slackware-15.0','Slackware-current']]==[26,26])
check('all12 source evidence gates and12 raw observation groups retained',scaffold['inherited_source_evidence_gates']==legacy['conformance_evidence_gates'] and len(scaffold['evidence_groups'])==12)
check('46 proofs16 gaps81 cuts9 microsteps14 recovery controls preserved',scaffold['qualified_proof_register']==refinement['qualified_proof_register'] and len(scaffold['qualified_proof_register'])==46 and scaffold['inherited_native_gap_register']==refinement['native_gap_register'] and len(scaffold['inherited_macro_cut_obligations'])==81 and len(scaffold['inherited_owned_stage7_microsteps'])==9 and len(scaffold['inherited_phase_contract']['recovery_branch_gates'])==15 and len(refinement['fault_disposition_contract']['conditions'])==14)
check('all native observer verifier comparison authority and raw captures unselected',all(r[k] is None for r in scaffold['cases'] for k in ['actual_independent_collector','actual_independent_verifier','actual_expectation_author','actual_comparison_algorithm','actual_fresh_test_authority','actual_raw_capture_artifacts']))
for key in ['actual_independent_oracle_selected','actual_native_capture_present','actual_operational_conformance','operational_readiness','runtime_authority','actual_fresh_test_authority_granted','actual_global_host_closure_asserted','machine_action_required','controller_action_required','historical_v2_or_reference_main_sourced_run','user_step335_checkpoint_confirmed','strong_safe_pause']:
 check('oracle scaffold cannot promote native proof authority '+key,rejected(validate,mutated(scaffold,[key],True)))
for key,new in [('schema',True),('step',True),('actual_native_cases_run',1),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),('inherited_source_evidence_gates',[]),('independence_contract',{}),('inherited_native_gap_register',[]),('inherited_macro_cut_obligations',[])]:
 check('oracle source or blocker cannot be waived '+key,rejected(validate,mutated(scaffold,[key],new)))
for i,row in enumerate(scaffold['cases']):
 label=row['platform']+'/'+row['case_id']
 for key,new in [('status','PASS'),('actual_result','PASS'),('actual_fresh_test_authority','granted'),('actual_independent_verifier','same-candidate-verifier')]:
  check('case remains separately unrun unbound '+label+' '+key,rejected(validate,mutated(scaffold,['cases',i,key],new)))
 q=ns['private_oracle_packet'](row);answer=evaluate(q)
 check('complete private envelope never executes native case '+label,answer['model_declared_evidence_complete'] and answer['actual_platform_case_status']=='required-not-run' and not any(v for k,v in answer.items() if k.startswith('actual_') and type(v) is bool))
 check('subject claim does not decide oracle result '+label,evaluate(dict(q,subject_claimed_status='FAIL'))==answer and evaluate(dict(q,subject_claimed_status='unknown'))==answer)
 other='Slackware-current' if row['platform']=='Slackware-15.0' else 'Slackware-15.0'
 check('platform tuple cannot transplant private context '+label,rejected(evaluate,mutated(q,['case_ref','platform'],other)))
 next_case=next(r['case_id'] for r in scaffold['cases'] if r['platform']==row['platform'] and r['case_id']!=row['case_id'])
 check('case tuple cannot transplant original packet context '+label,rejected(evaluate,mutated(q,['case_ref','case_id'],next_case)))
for i,row in enumerate(scaffold['evidence_groups']):
 check('independent group has no fabricated raw capture '+row['id'],rejected(validate,mutated(scaffold,['evidence_groups',i,'actual_raw_capture'],{'PASS':True})))
q=ns['private_oracle_packet'](scaffold['cases'][0])
for ident in q['groups']:
 bad=copy.deepcopy(q);bad['groups'][ident]['observed_vector'][0]['value']=0;answer=evaluate(bad)
 check('claimed PASS cannot override independent vector mismatch '+ident,not answer['model_declared_evidence_complete'] and answer['model_mismatch_groups']==[ident] and not answer['model_subject_claim_used_for_acceptance'])
 for status in ['declared-unknown','declared-missing']:
  bad=copy.deepcopy(q);bad['groups'][ident].update(status=status,observed_vector=None);answer=evaluate(bad)
  check('unknown missing observation stays pending not absence '+ident+' '+status,not answer['model_declared_evidence_complete'] and answer['model_pending_groups']==[ident] and not answer['model_mismatch_groups'])
  check('unknown missing cannot masquerade as empty no-effect '+ident+' '+status,rejected(evaluate,mutated(bad,['groups',ident,'observed_vector'],[])))
 bad=copy.deepcopy(q);bad['groups'].pop(ident);check('no evidence group omitted '+ident,rejected(evaluate,bad))
 check('wrong observed bool cannot coerce to integer '+ident,rejected(evaluate,mutated(q,['groups',ident,'observed_vector',0,'value'],True)))
for control in ['positive','negative']:
 for status in ['declared-ineffective','declared-unknown','declared-missing']:
  answer=evaluate(mutated(q,['fault_controls',control],status))
  check('both independent fault controls required effective '+control+' '+status,not answer['model_declared_evidence_complete'] and (control in answer['model_ineffective_fault_controls'] or control in answer['model_pending_fault_controls']))
 bad=copy.deepcopy(q);bad['fault_controls'].pop(control);check('fault control cannot be omitted '+control,rejected(evaluate,bad))
for key in q['reuse']:check('candidate logic or selfreport cannot become oracle '+key,rejected(evaluate,mutated(q,['reuse',key],True)))
for key,new in [('collector','fixture-subject-A'),('verifier','fixture-subject-A'),('expectation_author','fixture-subject-A'),('verifier','fixture-collector-B'),('collector','native-capture-identity')]:
 check('private provenance roles cannot collapse '+key+' '+new,rejected(evaluate,mutated(q,['identities',key],new)))
for key,new in [('origin','native-capture'),('scope','native-conformance'),('actual_native_bindings',{'boot':'old'}),('actual_authority',True),('case_ref',{'platform':'*','case_id':'all'}),('context',{}),('subject_claimed_status','verified-signature')]:
 check('private envelope cannot claim actual native evidence '+key,rejected(evaluate,dict(q,**{key:new})))
check('extra actual grant field rejected',rejected(evaluate,dict(q,new_grant=True)))
first,second=list(q['groups'])[:2];bad=copy.deepcopy(q);bad['groups'][first]['observed_vector'][0]['value']=0;bad['groups'][second].update(status='declared-unknown',observed_vector=None);answer=evaluate(bad)
check('pending group never hides another group mismatch',answer['model_mismatch_groups']==[first] and answer['model_pending_groups']==[second] and not answer['model_declared_evidence_complete'])
for kind,good,bad_values in [('boolean',True,[1,0,'true',None]),('integer',1,[True,1.0,2**63,None]),('tag','fixture-tag-A',['/proc/self/fd/3','x'*65,1,None])]:
 v=[dict(item_id='fixture-item-A',value_type=kind,value=good)];check('typed private vector accepted '+kind,ns['validate_vector'](v))
 for bad_value in bad_values:check('private vector rejects coercion or native handle '+kind+' '+str(bad_value)[:15],rejected(ns['validate_vector'],mutated(v,[0,'value'],bad_value)))
v=[dict(item_id='fixture-item-A',value_type='integer',value=1)]
for bad in [[],v*65,v*2,[dict(v[0],native_fd=3)],[dict(v[0],value_type='native-handle')]]:check('closed bounded vector rejects malformed declaration '+str(len(bad)),rejected(ns['validate_vector'],bad))
for example in load('-private-packets.json')['examples']:
 check('exact private oracle example never native evidence '+example['id'],evaluate(example['input'])==example['result'] and example['actual_evidence'] is None and example['result']['actual_platform_case_status']=='required-not-run')
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict335 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('335 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('335 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step335-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual335 entry reruns full1242 predecessor and complete historical coverage',result.returncode==0 and 'exact_step334_acceptance\tPASS (1242 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered1242 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==1242 and lines[-1]=='Result: PASS (1242 passes, 0 failures)')
    for suffix in ['-policy.json','-scaffold.json','-private-packets.json','-checkpoint-confirmation.json','-step334-user-acceptance.json','-case-proof-map.tsv']:
        check('exact335 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('oracle scaffold grants no native oracle or test authority','actual_independent_oracle_or_test_authority_selected\tno' in result.stdout and 'actual_native_cases_run\t0' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+[ns['REFINEMENT_PATH'],ns['LEGACY_PATH'],'tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed335 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1593 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
