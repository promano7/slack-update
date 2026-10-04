#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact323 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='1169c61e4d382e96fc466552a15c0332efd350b4ddbef98c8d408bf61b081f7b')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step323_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_design'](value,prior,frozen,history)
check('exact1485 predecessor bytes and original CHANGELOG suffix',len(history)==1485)
check('complete456 original322 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step322-user-acceptance.json')))
check('split issuer rights and bounded recovery contract accepted',validate(design))
check('prepared322 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('recovery requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no real recovery proof from model '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for section in ['forward_contract','recovery_contract','clock_contract','fence_contract','closure_contract']:
    for key in design[section]:check('explicit split-rights contract retained '+section+'/'+key,rejected(validate,mutate(design,[section,key],'unreviewed')))
for key in ['selected_policy','previous_design_bindings','seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges','private_model_scope']:
    check('prior or separate obligation retained '+key,rejected(validate,mutate(design,[key],[])))
for i,row in enumerate(design['future_proof_obligations']):check('real future recovery proof retained '+row['id'],rejected(validate,mutate(design,['future_proof_obligations',i,'status'],'operational-PASS')))
event=lambda action,tick=1,revocation='none',identity_safe=True:dict(action=action,tick=tick,revocation=revocation,identity_safe=identity_safe)
model=lambda events,phase='predecessor',budget=5:dict(origin='synthetic-private-fixture',scope='split-rights-policy-only',conditions=dict.fromkeys(ns['GATE_KEYS'],True),events=events,phase=phase,recovery_budget=budget)
simulate=ns['simulate_private_rights'];recovery=['drain','restore-original','verify-original','capture-evidence','release-control']
safe=[event('fail-forward',1)]+[event(a,101+i) for i,a in enumerate(recovery)]
r=simulate(model(safe));check('ordinary failure safely restores within explicitly retained rights after forward expiry',r['model_scoped_target_obligations_closed'] and not r['model_controller_obligations_pending'] and r['model_original_status']=='original-forward-failure' and r['model_restore_writes']==1)
check('private qualified recovery conveys no real authorization or closure',all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['renewal_authorized'] and not r['retry_authorized'] and not r['publication_authorized'])
for phase in ['baseline','predecessor','target','unknown']:
    r=simulate(model(safe,phase));check('original phase and unknown restoration preserved '+phase,r['model_scoped_target_obligations_closed']==(phase!='unknown') and r['model_phase_unknown']==(phase=='unknown') and r['model_restore_writes']==(1 if phase in ['predecessor','target'] else 0))
for key in ns['GATE_KEYS']:
    value=mutate(model(safe),['conditions',key],False);r=simulate(value)
    check('missing recovery safety proof blocks writes '+key,not r['model_scoped_target_obligations_closed'] and not any(t['modeled_write'] for t in r['trace']))
    check('strict prerequisite bool '+key,rejected(simulate,mutate(model(safe),['conditions',key],1)))
for revocation in ns['REVOCATIONS']:
    for tick in [99,100,139,140]:
        r=simulate(model([event('forward',tick,revocation)]))
        check('forward deadline and scoped revocation '+revocation+'/'+str(tick),r['model_forward_effects']==(1 if tick<100 and revocation in ['none','recovery'] else 0))
        r=simulate(model([event('fail-forward',1),event('drain',tick,revocation),event('restore-original',tick)]))
        check('retained recovery deadline and absorbing revocation '+revocation+'/'+str(tick),r['model_restore_writes']==(1 if tick<140 and revocation in ['none','forward'] else 0))
for prefix in range(len(safe)+1):
    for failure in ['all','recovery','unknown']:
        changed=safe[:prefix]+[event('restore-original',110,failure)]+[event(a,111+i) for i,a in enumerate(recovery)]+[event('forward',120)]
        r=simulate(model(changed));trace=r['trace'];after=trace[prefix:]
        check('revocation and unknown stop later effects at recovery boundary '+str(prefix)+'/'+failure,not any(t['modeled_write'] for t in after) and all(t['recovery_closed'] for t in after) and r['model_forward_effects']==0)
for action in ns['MODEL_ACTIONS']:
    r=simulate(model([event('fail-forward',1),event(action,2,identity_safe=False)]+[event(a,3+i) for i,a in enumerate(recovery)]))
    check('wrong boot identity never restores for action '+action,not any(t['modeled_write'] for t in r['trace']) and r['model_machine_obligations_pending'] and r['model_controller_obligations_pending'])
for action in recovery:
    r=simulate(model([event('fail-forward',20),event(action,19)]+[event(a,21+i) for i,a in enumerate(recovery)]))
    check('clock rollback is absorbing for '+action,not any(t['modeled_write'] for t in r['trace']) and r['model_phase_unknown'])
for budget in range(9):
    r=simulate(model(safe,budget=budget));check('finite recovery budget before actions '+str(budget),r['model_scoped_target_obligations_closed']==(budget>=4) and (not r['model_controller_obligations_pending'])==(budget>=5) and r['model_recovery_budget_remaining']==max(0,budget-5))
for bad in [-1,9,True,'5',None]:check('invalid finite budget rejected '+repr(bad),rejected(simulate,dict(model([]),recovery_budget=bad)))
for action in recovery[1:]:
    r=simulate(model([event('fail-forward'),event(action,2)]));check('out of order recovery denied '+action,r['model_denials']==1 and not any(t['modeled_write'] for t in r['trace']))
r=simulate(model([event('forward',1),event('forward',2),event('finish-forward',3)]+[event(a,4+i) for i,a in enumerate(recovery)]))
check('one forward package effect then only recovery with original failure preserved',r['model_forward_effects']==1 and r['model_original_status']=='original-forward-denial' and r['model_scoped_target_obligations_closed'])
r=simulate(model([event('fail-forward',1),event('drain',2),event('restore-original',3),event('restore-original',4),event('verify-original',5)],budget=5))
check('known already restored action is modeled no-op not another package write',r['model_restore_writes']==1 and not r['trace'][3]['modeled_write'])
r=simulate(model([event('fail-forward',1),event('drain',2),event('restore-original',3,revocation='unknown'),event('restore-original',4)]))
check('unknown action outcome or authority never replayed',r['model_restore_writes']==0 and r['model_phase_unknown'] and r['model_machine_obligations_pending'])
r=simulate(model([event('fail-forward',1),event('drain',2),event('restore-original',3),event('lose-action-outcome',4),event('restore-original',5),event('verify-original',6)]))
check('lost result after possible restore never retries or claims known closure budget',r['model_restore_writes']==1 and r['model_phase_unknown'] and r['model_machine_obligations_pending'] and r['model_recovery_budget_remaining'] is None and not r['trace'][-1]['allowed'])
for action in ['retry','rebind','publication']:
    r=simulate(model(safe+[event(action,120)]));check('recovery cannot issue retry rebind or publication authority '+action,r['model_denials']==1 and not r['retry_authorized'] and not r['publication_authorized'])
for key,new in dict(origin='host',scope='real-restore',phase='foreign',events='restore',recovery_budget=100).items():check('typed model field rejects '+key,rejected(simulate,dict(model([]),**{key:new})))
for key,new in dict(action='renew',tick=True,revocation='guess-none',identity_safe=1).items():check('typed event rejects '+key,rejected(simulate,model([dict(event('drain'),**{key:new})])))
check('bounded event count',rejected(simulate,model([event('drain')]*25)))
a=(fixture/(base+'-revocation-scope-matrix.tsv')).read_bytes();b=(fixture/(base+'-bounded-recovery-action-matrix.tsv')).read_bytes()
check('exact revocation and bounded recovery tables',ns['validate_tables'](a,b));check('all revocation cannot allow recovery',rejected(ns['validate_tables'],a.replace(b'all\tstopped\tstopped',b'all\tstopped\tconditional'),b));check('no renewal action table',rejected(ns['validate_tables'],a,b+b'renew\trecovery\tnew-grant\tPASS\n'))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict323 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step323-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real323 entry reruns full exact456 predecessor acceptance',result.returncode==0 and 'exact_step322_acceptance\tPASS (456 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered456 predecessor capture',sum(x.startswith('PASS: ') for x in log)==456 and log[-1]=='Result: PASS (456 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published323 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no live forward recovery clock fence or restoration proof','actual_forward_or_recovery_authorized\tno' in result.stdout and 'actual_clock_fence_budget_or_restoration_proven\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']+[x['path'] for x in design['previous_design_bindings'].values()]+[frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed recovery or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1485 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
