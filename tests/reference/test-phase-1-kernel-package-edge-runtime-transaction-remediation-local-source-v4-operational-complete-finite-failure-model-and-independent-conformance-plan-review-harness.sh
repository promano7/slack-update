#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-complete-finite-failure-model-and-independent-conformance-plan-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
def check(label,condition):
    global passes
    if not condition:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,TypeError,KeyError,OSError):return True
    return False
def mutate(value,path,new):
    result=copy.deepcopy(value);cursor=result
    for key in path[:-1]:cursor=cursor[key]
    cursor[path[-1]]=new;return result
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
check('exact326 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='54eba76adc8cfd815beacf071de47339ae1157bd13fd381b69009841c637e281')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step326_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_design'](value,prior,frozen,history)
check('exact1512 predecessor bytes and original CHANGELOG suffix',len(history)==1512)
check('complete1004 original325 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step325-user-acceptance.json')))
check('finite failure and independent conformance contracts accepted',validate(design))
check('prepared325 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('recovery requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no real recovery proof from model '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for section in ['model_contract','independent_conformance_contract','model_coverage']:
    for key in design[section]:check('explicit split-rights contract retained '+section+'/'+key,rejected(validate,mutate(design,[section,key],'unreviewed')))
for key in ['selected_policy','previous_design_bindings','seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges','private_model_scope','reference_review_binding','model_domains','conformance_plan','conformance_platforms','conformance_case_ids','conformance_evidence_gates','whole_graph_binding','inherited_whole_graph_proof_obligations']:
    check('prior or separate obligation retained '+key,rejected(validate,mutate(design,[key],[])))
for i,row in enumerate(design['future_proof_obligations']):check('real future recovery proof retained '+row['id'],rejected(validate,mutate(design,['future_proof_obligations',i,'status'],'operational-PASS')))

simulate=ns['simulate_private_lifecycle']
event=lambda action,outcome='ok',status=0:dict(action=action,outcome=outcome,raw_status=status)
sequence=ns['FORWARD']+ns['RECOVERY']+ns['PUBLICATION']; golden=[event(x) for x in sequence]
fixture_run=lambda events,budget=8:dict(origin='synthetic-private-fixture',scope='finite-failure-contract-only-not-real-lifecycle',conditions=dict.fromkeys(ns['GATE_KEYS'],True),recovery_budget=budget,events=events)
cases=ns['enumerate_private_fault_cases']()
check('exact declared finite case family count',len(cases)==design['model_coverage']['total_case_count'] and len({label for label,value in cases})==len(cases))
for label,value in cases:
    r=simulate(value); traces=r['trace']; first=r['model_original_failure']
    forward_after_stop=False; stopped=False
    for trace in traces:
        if stopped and trace['action'] in ns['FORWARD'] and trace['attempted']:forward_after_stop=True
        stopped=stopped or trace['forward_latched']
    invariants=not forward_after_stop and r['model_launch_count']<=1 and r['model_claim_count']<=1
    invariants=invariants and r['model_recovery_budget_spent']<=value['recovery_budget'] and all(t['recovery_budget_remaining']>=0 for t in traces)
    released=False
    for t in traces:
        invariants=invariants and not(released and t['target_effect_attempted'])
        released=released or t['target_released'] is True or t['target_released'] is None
    invariants=invariants and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['replay_authorized'] and not r['new_grant_authorized'] and not r['republish_authorized']
    if r['model_scope_closed']:invariants=invariants and r['model_target_restored_verified'] and r['model_children_quiescent'] is True and r['model_target_released'] is True and r['model_receipt_durability'] is True and not r['model_obligations_pending']
    if first:invariants=invariants and all(t['original_failure']==first for t in traces[next(i for i,t in enumerate(traces) if t['original_failure'] is not None):])
    check('declared finite case invariant '+label,invariants)
r=simulate(fixture_run(golden));check('private golden lifecycle closes only modeled scope',r['model_scope_closed'] and r['model_forward_progress']==len(ns['FORWARD']) and r['model_recovery_budget_spent']==len(ns['RECOVERY']))
for index in range(len(golden)):
    r=simulate(fixture_run(golden[:index]));check('every incomplete lifecycle prefix retains obligations '+str(index),r['model_obligations_pending'])
for index,action in enumerate(ns['FORWARD']):
    for outcome in ['known-failure','unknown']:
        events=golden[:index]+[event(action,outcome,0 if outcome=='known-failure' else None)]+[event(x) for x in ns['RECOVERY']+ns['PUBLICATION']]
        r=simulate(fixture_run(events))
        check('original raw failure retained across finalization '+action+'/'+outcome,r['model_original_failure']==dict(action=action,outcome=outcome,raw_status=0 if outcome=='known-failure' else None))
for action in ['stage2-owned-work','stage3-verify-original-backups']:
    index=sequence.index(action);r=simulate(fixture_run(golden[:index]+[event(action,'unknown',None)]+[event(x) for x in ns['RECOVERY']+ns['PUBLICATION']]))
    check('unchanged target unknown owned file can independently verify without blind restore '+action,r['model_scope_closed'] and r['model_owned_outcome_unknown'] and not r['model_target_effect_attempted'] and not any(t['target_effect_attempted'] for t in r['trace'] if t['action'] in ns['RECOVERY']))
index=sequence.index('stage7-owned-binding');r=simulate(fixture_run(golden[:index]+[event('stage7-owned-binding','unknown',None)]+[event(x) for x in ns['RECOVERY']+ns['PUBLICATION']]))
check('unknown owned binding retains artifacts while known target restoration can close modeled scope',r['model_scope_closed'] and r['model_owned_outcome_unknown'] and r['model_artifacts_may_exist'] and r['model_target_restored_verified'])
for action in ns['TARGET_WRITES']:
    index=sequence.index(action);r=simulate(fixture_run(golden[:index]+[event(action,'unknown',None)]+[event(x) for x in ns['RECOVERY']+ns['PUBLICATION']]))
    check('unknown target mutation prevents blind original restoration '+action,r['model_obligations_pending'] and not r['model_target_state_known'] and not any(t['attempted'] for t in r['trace'] if t['action']=='restore-original-if-changed'))
for action in ['consume-original-grant','spend-launch-slot','launch-one-worker']:
    index=sequence.index(action);r=simulate(fixture_run(golden[:index]+[event(action,'unknown',None)]+[event(action)]+golden[index+1:]))
    field={'consume-original-grant':'model_consumed','spend-launch-slot':'model_launch_slot_spent','launch-one-worker':'model_worker_launched'}[action]
    check('unknown durable or spawn outcome stays null with no replay '+action,r[field] is None and r['model_obligations_pending'] and not r['trace'][index+1]['attempted'])
for action in sequence:
    index=sequence.index(action);r=simulate(fixture_run(golden[:index+1]+[event(action)]+golden[index+1:]));check('every same attempt action single use '+action,not r['trace'][index+1]['attempted'])
for action in ['nested-update-same-raw-pin','nested-install-new-empty','nested-upgrade-one-target']:
    index=sequence.index(action)
    for status in [-1,0,1,2,20]:
        events=list(golden);events[index]=event(action,'ok',status);r=simulate(fixture_run(events));expected=status==0 or action=='nested-install-new-empty' and status==20
        check('raw selector status policy retained '+action+'/'+str(status),r['model_original_failure'] is None if expected else r['model_original_failure']['raw_status']==status)
for action in ns['RECOVERY']:
    index=sequence.index(action);r=simulate(fixture_run(golden[:index]+[event(action,'unknown',None)]+[event(action)]+golden[index+1:]));check('unknown recovery action pre-spends budget and never retries '+action,r['model_obligations_pending'] and not r['trace'][index+1]['attempted'] and r['model_recovery_budget_spent']==ns['RECOVERY'].index(action)+1)
for action in ['write-record-no-replace','record-durability-confirmed','write-last-receipt-no-replace','last-receipt-durability-confirmed','handoff-complete']:
    index=sequence.index(action);r=simulate(fixture_run(golden[:index]+[event(action,'unknown',None)]+[event(action)]+golden[index+1:]+[event('target-refresh-after-release')]))
    check('unknown publication retains target closure without replay or fresh refresh '+action,r['model_obligations_pending'] and r['model_target_restored_verified'] and r['model_target_released'] is True and r['model_artifacts_may_exist'] and not r['trace'][index+1]['attempted'] and not r['trace'][-1]['target_effect_attempted'])
for key in ns['GATE_KEYS']:check('strict finite prerequisite type '+key,rejected(simulate,mutate(fixture_run(golden),['conditions',key],1)))
for value in [True,-1,9,'8',None]:check('strict finite budget type '+repr(value),rejected(simulate,dict(fixture_run(golden),recovery_budget=value)))
for value in [True,'0',99]:check('strict raw status type '+repr(value),rejected(simulate,fixture_run([event('service-own-failure-barrier','ok',value)])))
check('finite model rejects real origin',rejected(simulate,dict(fixture_run(golden),origin='live-operational-evidence')))
check('finite model rejects unbounded events',rejected(simulate,fixture_run(golden*4)))
check('finite model rejects unknown syscall',rejected(simulate,fixture_run([event('unreviewed-native-syscall')])) )
check('finite model rejects wrong outcome',rejected(simulate,fixture_run([event('service-own-failure-barrier','success')])) )
evaluate=ns['evaluate_private_conformance_index']
index_fixture=lambda platform:dict(origin='synthetic-private-fixture',scope='future-independent-evidence-index-only',platform=platform,case_ids=list(ns['CONFORMANCE_CASES']),conditions=dict.fromkeys(ns['CONFORMANCE_GATES'],True))
for platform in ns['PLATFORMS']:
    r=evaluate(index_fixture(platform));check('complete private evidence index cannot imply real conformance '+platform,r['model_evidence_index_complete'] and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['opposite_platform_inferred'] and not r['synthetic_or_self_oracle_is_conformance'])
    rows=[row for row in design['conformance_plan'] if row['platform']==platform];check('every independent platform case remains unbound required-not-run '+platform,len(rows)==26 and all(row['status']=='required-not-run' and row['result'] is None and row['implementation_path'] is None and row['boot_id'] is None and row['test_run_id'] is None for row in rows))
    for key in ns['CONFORMANCE_GATES']:
        r=evaluate(mutate(index_fixture(platform),['conditions',key],False));check('independent conformance evidence gate required '+platform+'/'+key,not r['model_evidence_index_complete'])
        check('strict independent evidence gate type '+platform+'/'+key,rejected(evaluate,mutate(index_fixture(platform),['conditions',key],1)))
    for case_id in ns['CONFORMANCE_CASES']:
        current=index_fixture(platform);current['case_ids'].remove(case_id);check('no independent platform test omitted '+platform+'/'+case_id,not evaluate(current)['model_evidence_index_complete'])
    current=index_fixture(platform);current['case_ids'][0]=current['case_ids'][1];check('duplicate independent evidence case rejected '+platform,rejected(evaluate,current))
    current=index_fixture(platform);current['case_ids'][0]='foreign-case';check('foreign independent evidence case rejected '+platform,rejected(evaluate,current))
    for i,row in enumerate(design['conformance_plan']):
        if row['platform']==platform:check('private test cannot mark conformance plan done '+platform+'/'+row['case_id'],rejected(validate,mutate(design,['conformance_plan',i,'status'],'PASS')))
check('unknown conformance platform rejected',rejected(evaluate,dict(index_fixture(ns['PLATFORMS'][0]),platform='one-platform-proves-all')))
check('actual self report not accepted by private evidence index',rejected(evaluate,dict(index_fixture(ns['PLATFORMS'][0]),origin='signed-live-self-report')))
a=(fixture/(base+'-finite-failure-contract.tsv')).read_bytes();b=(fixture/(base+'-independent-conformance-plan.tsv')).read_bytes()
check('exact complete finite failure and independent conformance tables',ns['validate_tables'](a,b))
check('no declared failure domain omitted',rejected(ns['validate_tables'],b'\n'.join(a.splitlines()[:-1])+b'\n',b))
check('no independent planned test promoted to conformance',rejected(ns['validate_tables'],a,b.replace(b'required-not-run',b'PASS')))

for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict326 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step326-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real326 entry reruns full exact1004 predecessor acceptance',result.returncode==0 and 'exact_step325_acceptance\tPASS (1004 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered1004 predecessor capture',sum(x.startswith('PASS: ') for x in log)==1004 and log[-1]=='Result: PASS (1004 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published326 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no live forward recovery clock fence or restoration proof','actual_runtime_lifecycle_or_conformance_proven\tno' in result.stdout and 'actual_dispatch_or_publication_authorized\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']+[x['path'] for x in design['previous_design_bindings'].values()]+[design['reference_review_binding']['path'],frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed recovery or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1512 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
