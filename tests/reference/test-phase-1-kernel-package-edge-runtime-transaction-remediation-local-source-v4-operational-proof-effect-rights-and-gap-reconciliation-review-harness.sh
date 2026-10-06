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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact337 proof effect rights reconciliation tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='8454b5cc79f06f62e2ff1cd4fe3a0e42fb090b02a5f3f8485d2b82fa4e555bcb')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step337_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');review=load('-reconciliation.json');history=ns['verify_history'](root,policy)
validate=lambda value:ns['validate_reconciliation'](value,history)
check('1611 accepted bytes with only additive CHANGELOG',len(history)==1611)
check('complete336 external receipt1247 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step336-user-acceptance.json')))
check('all repository source joins reconcile without native proof waiver',validate(review) and review['repository_reconciliation_complete'] and review['repository_source_conflicts_found']==[])
s=ns['reconciliation_sources'](history)
check('source source contract closure checks pass independently',ns['reconcile_source_inputs'](history,s))
check('all72 artifacts329-336 separately source bound',len(review['repository_artifact_registry329_336'])==72 and all(sum(r['step']==step for r in review['repository_artifact_registry329_336'])==9 for step in range(329,337)))
check('every46 proof retained exactly and linked to domains and native case tuples',[r['inherited_proof'] for r in review['qualified_proof_reconciliation']]==s['retained']['future_proof_register'] and all(r['domain_ids'] and r['required_native_case_tuples'] for r in review['qualified_proof_reconciliation']))
check('all52 cases still26 each platform without actual results',[sum(c['platform']==p for c in review['all52_native_case_templates']) for p in ['Slackware-15.0','Slackware-current']]==[26,26] and all(c['status']=='required-not-run' and c['actual_result'] is None for c in review['all52_native_case_templates']))
check('all16 native gaps81 macro cuts9 microsteps remain exact',review['all16_native_gaps']==s['fault']['native_gap_register'] and review['all81_macro_cut_obligations']==s['fault']['candidate_boundary_cuts'] and review['all9_owned_microsteps']==s['fault']['stage7_owned_microstep_obligations'])
check('source service and forbidden windows not invented as new phases',[(r['window'],r['phase_ids']) for r in review['authority_window_reconciliation'] if r['no_standalone_candidate_phase']]==[('service',[]),('forbidden',[])])
check('private1166 checks and1247 receipt never native proof',review['private_negative_test_reconciliation']['private_cases']==1166 and review['private_negative_test_reconciliation']['positive_controls']==92 and review['private_negative_test_reconciliation']['native_proofs_added']==0 and review['private_negative_test_reconciliation']['native_cases_run']==0)
for key in ['actual_dynamic_graph_complete','actual_native_refinement_complete','actual_independent_oracle_selected','actual_operational_implementation_frozen','actual_operational_conformance','operational_readiness','runtime_authority','actual_global_host_closure_asserted','historical_v2_or_reference_main_sourced_run','machine_action_required','controller_action_required','user_step337_checkpoint_confirmed','strong_safe_pause','phase2_open','phase1_matrix_complete','kernel_package_edge_complete']:
    check('reconciliation cannot promote actual native closure '+key,rejected(validate,mutated(review,[key],True)))
for key,value in [('actual_native_cases_run',1),('actual_proofs_added',1),('actual_live_bindings',{'boot':'old'}),('actual_host_state','absent'),('production_entry_closed',False),('exact_contract_views',{}),('original329_pause_conditions',[])]:
    check('reconciliation cannot waive original scope '+key,rejected(validate,mutated(review,[key],value)))
for i,row in enumerate(review['qualified_proof_reconciliation']):
    check('proof remains required-not-proven '+row['qualified_id'],rejected(validate,mutated(review,['qualified_proof_reconciliation',i,'status'],'PASS')))
    check('private PASS never becomes native evidence '+row['qualified_id'],rejected(validate,mutated(review,['qualified_proof_reconciliation',i,'actual_evidence'],{'private_PASS':True})))
for i,row in enumerate(review['effect_domain_reconciliation']):check('each domain stays dispatch blocked '+row['id'],rejected(validate,mutated(review,['effect_domain_reconciliation',i,'dispatch_blocked'],False)))
for i,row in enumerate(review['all95_macro_design_relations']):check('every macro edge still design only '+str(i),rejected(validate,mutated(review,['all95_macro_design_relations',i,'actual_edge_proven'],True)))
for i,row in enumerate(review['all52_native_case_templates']):check('every native platform case stays unrun '+row['platform']+'/'+row['case_id'],rejected(validate,mutated(review,['all52_native_case_templates',i,'status'],'PASS')))
for group in ['authority_window_reconciliation','seven_capability_reconciliation','ten_cross_obligation_reconciliation']:
    for i,row in enumerate(review[group]):
        ident=row.get('window',row.get('id'))
        check('all rights capabilities obligations stay native pending '+group+'/'+ident,rejected(validate,mutated(review,[group,i,'status'],'PASS')))
        if group=='authority_window_reconciliation':check('original window grants no actual authority '+ident,rejected(validate,mutated(review,[group,i,'inherited_window','actual_authority_valid'],True)))
for i,row in enumerate(review['all16_native_gaps']):check('native gap remains independent blocker '+row['inherited_gap']['id'],rejected(validate,mutated(review,['all16_native_gaps',i,'status'],'closed')))
for group in ['all81_macro_cut_obligations','all9_owned_microsteps']:
    check('macro or microstep obligations cannot be omitted '+group,rejected(validate,mutated(review,[group],review[group][:-1])))
for role,path in ns['SOURCE_PATHS'].items():
    drift=dict(history);drift[path]=history[path]+b'\n';check('bound source role byte drift denied '+role,rejected(ns['validate_reconciliation'],review,drift))
q=dict(origin='synthetic-private-fixture',scope='repository-candidate-refinement-workstream329-338-only',test_authority=False,live_binding=None,actual_host_state='unobserved-not-claimed-absent',conditions={k:True for k in review['original329_pause_conditions']})
evaluate=lambda value:ns['evaluate_private_pause_boundary'](value,review)
answer=evaluate(q)
check('private all-conditions reviewability never confirms pause or authority',answer['model_repository_candidate_freeze_reviewable'] and answer['model_actual_proofs_still_required']==46 and answer['model_actual_native_cases_still_unrun']==52 and not any(v for k,v in answer.items() if k.startswith('actual_')))
for key in q['conditions']:
    value=mutated(q,['conditions',key],False);answer=evaluate(value)
    check('each original329 pause condition stays pending '+key,not answer['model_repository_candidate_freeze_reviewable'] and answer['model_pending_conditions']==[key])
    check('pause condition exact bool no coercion '+key,rejected(evaluate,mutated(q,['conditions',key],1)))
    value=copy.deepcopy(q);del value['conditions'][key];check('pause condition never omitted '+key,rejected(evaluate,value))
for key,value in [('scope','global-host-closure'),('scope','operational-implementation-freeze'),('test_authority',True),('live_binding',{'boot':'old'}),('actual_host_state','absent'),('origin','native-observation')]:check('scoped private review cannot claim global runtime facts '+key+'/'+str(value),rejected(evaluate,dict(q,**{key:value})))
check('extra native grant denied',rejected(evaluate,dict(q,native_grant=True)))
for example in load('-private-boundaries.json')['examples']:check('private boundary fixture exact no actual evidence '+example['id'],evaluate(example['input'])==example['result'] and example['actual_evidence'] is None)
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict337 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('337 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('337 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step337-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual337 entry reruns full1247 predecessor and complete historical coverage',result.returncode==0 and 'exact_step336_acceptance\tPASS (1247 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered1247 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==1247 and lines[-1]=='Result: PASS (1247 passes, 0 failures)')
    for suffix in ['-policy.json','-reconciliation.json','-private-boundaries.json','-checkpoint-confirmation.json','-step336-user-acceptance.json','-proof-effect-rights-map.tsv']:
        check('exact337 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('reconciliation grants no actual authority or native closure','actual_runtime_authority_or_native_closure\tno' in result.stdout and 'actual_native_cases_run\t0' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+list(ns['SOURCE_PATHS'].values())+['tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed337 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1611 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
