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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact331 inert phase-map tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='83bc003285e10d77d7437acea9f52c17378a12320279627ecd72587dc68b4a17')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step331_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');phase=load('-phase-map.json');history=ns['verify_history'](root,policy)
inventory=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-inventory.json']);retained=json.loads(history[inventory['inherited_obligations_binding']['path']]);frozen=json.loads(history[ns['FROZEN_WORKER']])
def validate(p):return ns['validate_phase_map'](p,history,inventory,retained,frozen)
check('1557 accepted bytes and additive CHANGELOG only',len(history)==1557)
check('complete330 external receipt with379 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step330-user-acceptance.json')))
check('27-boundary inert phase map agrees with exact source contracts',validate(phase))
check('all13 frozen stage descriptors remain exact',phase['frozen_worker_stages']==frozen['frozen_implementation_specification']['stages'])
check('historical readonly7 remains historical and successor owned commit explicit',phase['frozen_worker_stages'][7]['effect']=='read-only' and phase['selected_source_views']['322']['successor_stage7']['effect']=='owned-files')
ids=[r['id'] for r in phase['entry_trace']]
check('service burn and pre-spent launch precede readonly worker0',ids.index('service-original-durable-claim')<ids.index('service-durable-launch-spend')<ids.index('service-single-worker-spawn')<ids.index('worker0-bounded-auth-read'))
check('traps guard freshoriginal precede owned2 and backup3 precedes predecessor4',ids.index('worker1-arm-traps')<ids.index('interstage1-2-guard-freshoriginal')<ids.index('worker2-owned-workspace')<ids.index('worker3-original-backups')<ids.index('worker4-exact-predecessor'))
check('forward stop and child drain precede restore verification evidence release',ids.index('stop-forward-irreversibly')<ids.index('drain-known-owned-children')<ids.index('worker9-original-restoration')<ids.index('worker10-original-verification')<ids.index('worker11-close-target-evidence')<ids.index('release-target-control'))
check('publication record receipt handoff follows target release',ids.index('release-target-control')<ids.index('worker12-publication-controls')<ids.index('worker12-publication-record')<ids.index('worker12-last-receipt')<ids.index('worker12-durable-handoff'))
check('all source321 bounded bootstrap limits preserved',phase['bootstrap_limits']['maximum_raw_bytes']==65536 and phase['bootstrap_limits']['deadline_seconds']==10)
check('all46 qualified proofs retained in30 domain mappings',{p for n in phase['node_phase_map'] for p in n['required_future_proofs']}=={r['qualified_id'] for r in retained['future_proof_register']})
check('no forbidden boot optional GenInitrd or unknown domain added',all(not n['phase_ids'] and n['dispatch_blocked'] for n in phase['node_phase_map'] if n['forbidden_or_unknown']))
for key in ['actual_successor_entry_selected','actual_dynamic_graph_complete','actual_native_primitives_selected','actual_operational_implementation_frozen',
            'operational_conformance','operational_readiness','runtime_authority','historical_v2_or_reference_main_sourced_run','machine_action_required',
            'controller_action_required','user_step331_checkpoint_confirmed','strong_safe_pause']:
    check('phase map rejects actual authority or completion '+key,rejected(validate,mutated(phase,[key],True)))
for key,new in [('schema',True),('step',True),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),
                ('entry_trace',[]),('frozen_worker_stages',[]),('selected_source_views',{}),('continuous_controls',{}),
                ('stage7_owned_commit_sequence',[]),('raw_pkglist_rule',{}),('retained_recovery_contract',{}),('publication_contract',{}),
                ('all_actual_selection_gaps',[]),('inherited_platform_cases',[])]:
    check('phase provenance or blocker cannot be waived '+key,rejected(validate,mutated(phase,[key],new)))
for i,n in enumerate(phase['node_phase_map']):
    check('all domains remain blocked '+n['id'],rejected(validate,mutated(phase,['node_phase_map',i,'dispatch_blocked'],False)))
check('stage7 history cannot be retroactively reclassified',rejected(validate,mutated(phase,['frozen_worker_stages',7,'effect'],'owned-files')))
good=dict(origin='synthetic-private-fixture',scope='inert-order-and-attempt-context-only',events=[dict(id=r['id'],actor=r['actor'],rights_window=r['rights_window'],attempt='original-attempt-A',boot='original-boot-A',outcome='known-complete') for r in phase['entry_trace']])
result=ns['evaluate_private_trace'](good)
check('complete inert trace never authorizes native effects',result['model_declared_sequence_complete'] and not any(v for k,v in result.items() if k.startswith('actual_')))
for i,event in enumerate(good['events']):
    for outcome in ['known-failed','unknown','not-attempted']:
        trace=copy.deepcopy(good)
        for j in range(i,len(trace['events'])):trace['events'][j]['outcome']=outcome if j==i else 'not-attempted'
        result=ns['evaluate_private_trace'](trace)
        check('stop prefix no automatic restore or native closure '+event['id']+' '+outcome,not result['model_declared_sequence_complete'] and result['model_first_stop_boundary']==event['id'] and result['model_automatic_recovery'] is False and result['model_pending_prefix_obligations'] and not any(v for k,v in result.items() if k.startswith('actual_')))
    bad=copy.deepcopy(good);bad['events'].pop(i)
    check('cannot omit phase '+event['id'],rejected(ns['evaluate_private_trace'],bad))
    for key,new in [('attempt','new-attempt-B'),('boot','new-boot-B'),('actor','unreviewed-actor'),('rights_window','new-unused-grant')]:
        check('context or rights cannot rebind '+event['id']+' '+key,rejected(ns['evaluate_private_trace'],mutated(good,['events',i,key],new)))
for i in range(len(good['events'])-1):
    bad=copy.deepcopy(good);bad['events'][i],bad['events'][i+1]=bad['events'][i+1],bad['events'][i]
    check('adjacent phase reorder rejected '+str(i),rejected(ns['evaluate_private_trace'],bad))
bad=copy.deepcopy(good);bad['events'].insert(2,copy.deepcopy(bad['events'][1]));check('claim replay rejected',rejected(ns['evaluate_private_trace'],bad))
bad=copy.deepcopy(good);bad['events'][15]['outcome']='unknown';check('cannot continue8 after unknown binding commit',rejected(ns['evaluate_private_trace'],bad))
for key,new in [('origin','actual-host'),('scope','runtime'),('events',[])]:check('private trace schema scope rejects '+key,rejected(ns['evaluate_private_trace'],dict(good,**{key:new})))
conditions=dict.fromkeys(ns['RECOVERY_FLAGS'],True)
recovery=dict(origin='synthetic-private-fixture',scope='retained-original-recovery-contract-only',mode='restore-original-from-verified-backups',conditions=conditions)
for mode in ['restore-original-from-verified-backups','verify-independently-unchanged-without-target-write']:
    model=ns['evaluate_private_recovery'](dict(recovery,mode=mode))
    check('private original recovery mode no native authority '+mode,model['model_retained_recovery_branch_eligible'] and model['model_original_failure_preserved'] and all(v is False for k,v in model.items() if k.startswith('actual_')))
    for key in ns['RECOVERY_FLAGS']:
        bad=mutated(dict(recovery,mode=mode),['conditions',key],False)
        if mode=='restore-original-from-verified-backups' and key=='independently_unchanged_target':continue
        if mode=='verify-independently-unchanged-without-target-write' and key=='verified_original_backups':continue
        check('missing original recovery condition denies '+mode+' '+key,not ns['evaluate_private_recovery'](bad)['model_retained_recovery_branch_eligible'])
verification=mutated(dict(recovery,mode='verify-independently-unchanged-without-target-write'),['conditions','verified_original_backups'],False)
result=ns['evaluate_private_recovery'](verification)
check('known unchanged target verifies without never-created backups or target write',result['model_retained_recovery_branch_eligible'] and result['model_verification_only'] and result['model_target_restore_required'] is False)
restore=mutated(recovery,['conditions','independently_unchanged_target'],False)
result=ns['evaluate_private_recovery'](restore)
check('backed restore is separate from verification-only branch',result['model_retained_recovery_branch_eligible'] and result['model_target_restore_required'] and not result['model_verification_only'])
for key in ns['RECOVERY_FLAGS']:check('recovery flag requires bool '+key,rejected(ns['evaluate_private_recovery'],mutated(recovery,['conditions',key],1)))
for key,new in [('mode','replay-unknown'),('origin','actual-host'),('scope','new-grant'),('conditions',{})]:check('recovery schema cannot acquire rights '+key,rejected(ns['evaluate_private_recovery'],dict(recovery,**{key:new})))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict331 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('331 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('331 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step331-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual331 entry reruns full379 predecessor and complete historical coverage',result.returncode==0 and 'exact_step330_acceptance\tPASS (379 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered379 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==379 and lines[-1]=='Result: PASS (379 passes, 0 failures)')
    for suffix in ['-policy.json','-phase-map.json','-checkpoint-confirmation.json','-step330-user-acceptance.json','-entry-trace.tsv','-domain-phase-map.tsv']:
        check('exact331 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('inert ordering grants no native dispatch','actual_dispatch_or_publication_authorized\tno' in result.stdout and 'actual_successor_entry_or_native_effects_proven\tno' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+[ns['FROZEN_WORKER'],'tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed331 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1557 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
