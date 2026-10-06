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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independently-authored-candidate-negative-tests-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact336 independent negative tests tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='5c92c621f5cf134458d3b8e49c81d4bfa891dd82a119b1efbfa5b0f018896c5f')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step336_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');review=load('-review.json');suite=load('-negative-cases.json');history=ns['verify_history'](root,policy)
validate=lambda value:ns['validate_negative_review'](value,history,suite)
check('1602 accepted bytes with only additive CHANGELOG',len(history)==1602)
check('complete335 external receipt622 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step335-user-acceptance.json')))
check('source-bound negative contract review valid only as data',validate(review))
check('all seven pure private target families have positive controls',set(c['target'] for c in suite['cases'] if c['baseline_positive_control'])=={'trace','recovery','exchange','manifest','parse','fault','oracle'})
check('no native case run or native independence claimed',suite['actual_native_cases_run']==0 and suite['actual_native_independence_proven'] is False)
scaffold=json.loads(history[ns['SCAFFOLD_PATH']])
check('all46 proofs52 cases16 gaps81 cuts9 microsteps retained',review['qualified_proof_register']==scaffold['qualified_proof_register'] and len(review['qualified_proof_register'])==46 and review['native_case_templates']==scaffold['cases'] and len(review['native_case_templates'])==52 and review['native_gap_register']==scaffold['inherited_native_gap_register'] and len(review['native_gap_register'])==16 and len(review['macro_cut_obligations'])==81 and len(review['owned_stage7_microsteps'])==9)
check('all native platform cases remain required-not-run',all(c['status']=='required-not-run' and c['actual_result'] is None for c in review['native_case_templates']))
for key in ['actual_native_independence_proven','actual_independent_oracle_selected','actual_fault_schedules_selected','actual_operational_conformance','operational_readiness','runtime_authority','actual_global_host_closure_asserted','historical_v2_or_reference_main_sourced_run','machine_action_required','controller_action_required','user_step336_checkpoint_confirmed','strong_safe_pause']:
    check('private tests cannot promote native authority '+key,rejected(validate,mutated(review,[key],True)))
for key,value in [('actual_native_cases_run',1),('actual_live_bindings',{'boot':'old'}),('actual_host_state','absent'),('qualified_proof_register',[]),('native_gap_register',[]),('native_case_templates',[]),('macro_cut_obligations',[]),('owned_stage7_microsteps',[])]:
    check('private test review cannot waive original blockers '+key,rejected(validate,mutated(review,[key],value)))
answer=ns['run_negative_suite'](suite,history)
check('all independently authored contract assertions pass',answer['private_cases_passed']==len(suite['cases'])==review['private_case_count'])
check('positive baseline controls count exact',answer['baseline_positive_controls']==review['positive_control_count'])
for case,result in zip(suite['cases'],answer['results']):
    check('independent private expectation '+case['id']+' '+case['requirement'],result['id']==case['id'] and result['private_contract_assertion']=='PASS' and result['actual_native_evidence'] is None and result['candidate_declaration_rejected']==(case['expectation']['kind']=='reject'))
for key,value in answer['assertion_sensitivity_controls'].items():check('assertion sensitivity '+key,value is True)
check('matching all private cases creates no native evidence or authority',answer['actual_native_cases_run']==0 and not any(v for k,v in answer.items() if k.startswith('actual_') and type(v) is bool))
first=copy.deepcopy(suite);first['cases']=first['cases'][:1];first['cases'][0]['expectation']['fields']['model_declared_sequence_complete']=False
check('expectation authored differently cannot be auto-rebased to candidate',rejected(ns['run_negative_suite'],first,history))
original=ns['invoke_private_candidate']
ns['invoke_private_candidate']=lambda target,value,environment:{}
check('accept-all stub fails positive expected field',rejected(ns['run_negative_suite'],suite,history))
ns['invoke_private_candidate']=original
check('independent equality rejects bool integer coercion',not ns['expectation_holds']({'kind':'return','fields':{'count':1}},False,{'count':True}))
check('extra native authority result rejected',not ns['expectation_holds']({'kind':'return','fields':{}},False,{'actual_dispatch_authorized':True}))
check('reject requires actual declaration rejection',not ns['expectation_holds']({'kind':'reject','fields':{}},False,{}))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict336 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('336 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('336 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step336-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual336 entry reruns full622 predecessor and complete historical coverage',result.returncode==0 and 'exact_step335_acceptance\tPASS (622 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered622 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==622 and lines[-1]=='Result: PASS (622 passes, 0 failures)')
    for suffix in ['-policy.json','-review.json','-negative-cases.json','-checkpoint-confirmation.json','-step335-user-acceptance.json','-coverage.tsv']:
        check('exact336 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('negative contract tests grant no native independence or authority','actual_native_independence_or_test_authority_proven\tno' in result.stdout and 'actual_native_cases_run\t0' in result.stdout)
    published=json.loads((out/(base+'-private-results.json')).read_bytes());check('complete actual entry private results identical to separate run',published==answer)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+list(ns['CANDIDATE_TOOL_PATHS'].values())+[ns['PHASE_PATH'],ns['CATALOG_PATH'],ns['MANIFEST_PATH'],ns['REFINEMENT_PATH'],ns['SCAFFOLD_PATH'],'tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed336 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1602 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
