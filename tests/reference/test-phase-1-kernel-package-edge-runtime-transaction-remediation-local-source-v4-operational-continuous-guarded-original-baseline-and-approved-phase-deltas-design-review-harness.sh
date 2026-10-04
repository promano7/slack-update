#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact324 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='5b39225fe277fc6cba9601ae7ca3970b2e1ceb700515df8ede4174c5fe1cd7ff')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step324_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_design'](value,prior,frozen,history)
check('exact1494 predecessor bytes and original CHANGELOG suffix',len(history)==1494)
check('complete271 original323 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step323-user-acceptance.json')))
check('split issuer rights and bounded recovery contract accepted',validate(design))
check('prepared323 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('recovery requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no real recovery proof from model '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for section in ['interstage_contract','guard_contract','baseline_contract','pkglist_contract','recovery_contract']:
    for key in design[section]:check('explicit split-rights contract retained '+section+'/'+key,rejected(validate,mutate(design,[section,key],'unreviewed')))
for key in ['selected_policy','previous_design_bindings','seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges','private_model_scope','writer_resource_map_binding','resource_domains','successor_sequence','publication_contract']:
    check('prior or separate obligation retained '+key,rejected(validate,mutate(design,[key],[])))
for i,row in enumerate(design['future_proof_obligations']):check('real future recovery proof retained '+row['id'],rejected(validate,mutate(design,['future_proof_obligations',i,'status'],'operational-PASS')))

original=ns['FIXTURE_ORIGINAL'];phases=ns['FIXTURE_PHASES'];sequence=ns['PHASE_SEQUENCE'];recovery=ns['RECOVERY_SEQUENCE']
def event(action,before,after=None,**conditions):
    return dict(action=action,before=copy.deepcopy(before),after=copy.deepcopy(before if after is None else after),guard_continuous=conditions.get('guard_continuous',True),identity_safe=conditions.get('identity_safe',True),writers_excluded=conditions.get('writers_excluded',True),recovery_rights_valid=conditions.get('recovery_rights_valid',True))
def schedule():
    result=[];state=dict(original)
    transition={'stage-exact-predecessor':'predecessor','isolate-local-config':'isolated','refresh-new-pkglist':'refreshed','target-only-apply':'target','restore-original':'original'}
    for action in sequence:
        after=phases[transition[action]] if action in transition else state
        result.append(event(action,state,after));state=dict(after)
    return result
model=lambda events:dict(origin='synthetic-private-fixture',scope='continuous-guard-original-phase-contract-only',conditions=dict.fromkeys(ns['GATE_KEYS'],True),events=events)
simulate=ns['simulate_private_guarded_phases'];happy=schedule();r=simulate(model(happy))
check('complete approved phase route closes only modeled scoped target',r['model_scoped_target_closure'] and not r['model_controller_obligations_pending'] and r['model_denials']==0 and r['model_original_baseline']==original)
check('modeled route conveys no actual guard baseline restoration authority',all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['retry_authorized'] and not r['publication_authorized'])
check('original production pkglist restore preserves distinct immutable audit pin',r['model_raw_pin']==ns['FIXTURE_RAW_PIN'] and r['trace'][-1]['phase_state']['pkglist_raw']==original['pkglist_raw'])
check('original baseline immutable across every phase',all(t['original_baseline']==original for t in r['trace'] if t['baseline_captured']))
check('fresh guarded capture before all owned writes',all(t['baseline_captured'] and t['guard_held'] for t in r['trace'] if t['modeled_owned_write']))
r=simulate(model([event('early-preflight',dict(original,pkglist_raw='stale-memory'))]+happy))
check('early stale memory never substitutes guarded original capture',r['model_original_baseline']==original and r['model_scoped_target_closure'])
for index in range(len(happy)+1):
    r=simulate(model(happy[:index]));check('complete verification evidence release at prefix '+str(index),r['model_scoped_target_closure']==(index>=15) and r['model_controller_obligations_pending']==(index<16))
for key in ns['GATE_KEYS']:
    r=simulate(mutate(model(happy),['conditions',key],False));check('missing guard prerequisite prevents writes '+key,not r['model_scoped_target_closure'] and not any(t['modeled_target_write'] or t['modeled_owned_write'] for t in r['trace']))
    check('strict guard prerequisite bool '+key,rejected(simulate,mutate(model(happy),['conditions',key],1)))
for index in range(len(happy)):
    for key in original:
        for side in ['before','after']:
            changed=copy.deepcopy(happy);changed[index][side][key]='foreign-or-drift';r=simulate(model(changed))
            check('complete snapshot drift denied '+str(index)+'/'+side+'/'+key,not r['model_scoped_target_closure'] and r['model_unknown'] and r['model_original_baseline'] in [None,original] and r['model_controller_obligations_pending'])
    for safety in ['guard_continuous','identity_safe','writers_excluded']:
        changed=copy.deepcopy(happy);changed[index][safety]=False;r=simulate(model(changed))
        check('guard identity writer loss cannot reacquire '+str(index)+'/'+safety,not r['model_scoped_target_closure'] and r['model_unknown'] and not any(t['modeled_target_write'] or t['modeled_owned_write'] for t in r['trace'][index:]))
for index in range(5,12):
    prefix_events=happy[:index];state=prefix_events[-1]['after'];rest=[];current=state
    for action in recovery:
        after=original if action=='restore-original' else current;rest.append(event(action,current,after));current=after
    r=simulate(model(prefix_events+[event('fail-forward',state)]+rest))
    check('ordinary failure keeps safe same attempt recovery and original status '+str(index),r['model_scoped_target_closure'] and not r['model_controller_obligations_pending'] and r['model_original_status']=='original-forward-failure')
    changed=copy.deepcopy(rest);changed[0]['recovery_rights_valid']=False;r=simulate(model(prefix_events+[event('fail-forward',state)]+changed))
    check('recovery still requires exact323 retained rights '+str(index),not r['model_scoped_target_closure'] and r['model_controller_obligations_pending'])
    r=simulate(model(prefix_events+[event('supervisor-loss',state)]+rest))
    check('owner loss keeps unknown surviving child and machine obligations '+str(index),not r['model_scoped_target_closure'] and r['model_unknown'] and r['model_machine_obligations_pending'] and not any(t['modeled_target_write'] for t in r['trace'][index:]))
state=phases['refreshed'];r=simulate(model(happy[:10]+[event('nested-update',state)]+happy[10:]))
check('nested update preserves already bound raw pin in original phase',r['model_scoped_target_closure'] and r['model_denials']==0 and r['model_raw_pin']==ns['FIXTURE_RAW_PIN'])
r=simulate(model(happy[:10]+[event('nested-update',state,dict(state,pkglist_raw=state['pkglist_raw']+' '))]+happy[10:]))
check('logical row equality cannot repin raw drift',not r['model_scoped_target_closure'] and r['model_unknown'] and r['model_raw_pin']==ns['FIXTURE_RAW_PIN'])
for action in ['rebind-original','rebind-pkglist','force-unlock','reacquire','publication','target-write-after-release','nested-update']:
    r=simulate(model(happy+[event(action,original)]));check('release cannot authorize later target consumer or rebind '+action,r['model_denials']==1 and not r['trace'][-1]['modeled_target_write'] and not r['retry_authorized'] and not r['publication_authorized'])
for action in sequence[1:]:
    r=simulate(model([event(action,original)]));check('out of order guarded action denied '+action,r['model_denials']==1 and not any(t['modeled_target_write'] or t['modeled_owned_write'] for t in r['trace']))
for key,new in dict(origin='host',scope='real-lock',events='apply').items():check('typed model rejects '+key,rejected(simulate,dict(model([]),**{key:new})))
for key,new in dict(action='lock-real',guard_continuous=1,identity_safe=1,writers_excluded=1,recovery_rights_valid=1,before={},after='actual-state').items():check('typed event rejects '+key,rejected(simulate,model([dict(event('arm-traps',original),**{key:new})])))
check('bounded phase schedule',rejected(simulate,model([event('early-preflight',original)]*33)))
a=(fixture/(base+'-guard-resource-window-matrix.tsv')).read_bytes();b=(fixture/(base+'-original-phase-delta-matrix.tsv')).read_bytes()
check('exact resource window and original phase tables',ns['validate_tables'](a,b));check('resource domain cannot be omitted',rejected(ns['validate_tables'],b'\n'.join(a.splitlines()[:-1])+b'\n',b));check('original baseline cannot be rebound in table',rejected(ns['validate_tables'],a,b.replace(b'unchanged',b'rebound')))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict324 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step324-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real324 entry reruns full exact271 predecessor acceptance',result.returncode==0 and 'exact_step323_acceptance\tPASS (271 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered271 predecessor capture',sum(x.startswith('PASS: ') for x in log)==271 and log[-1]=='Result: PASS (271 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published324 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no live forward recovery clock fence or restoration proof','actual_guard_baseline_or_delta_proven\tno' in result.stdout and 'actual_forward_or_recovery_authorized\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']+[x['path'] for x in design['previous_design_bindings'].values()]+[design['writer_resource_map_binding']['path'],frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed recovery or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1494 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
