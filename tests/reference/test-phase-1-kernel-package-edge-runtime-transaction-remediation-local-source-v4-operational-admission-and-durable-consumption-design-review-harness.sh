#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,itertools,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-and-durable-consumption-design-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact320 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='f4569f80ce2fa221f12711446fc46d66bc88f1fda97cf9bdbc63f086a78b3cc1')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step320_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes())
policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-plan.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
check('exact1458 predecessor bytes and additive CHANGELOG suffix',len(history)==1458)
check('complete547 original319 acceptance and commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step319-user-acceptance.json')))
check('selected external admission successor contract accepted',ns['validate_design'](design,prior,frozen))
check('prepared319 flags remain immutable and user confirmation external',prior['user_step319_checkpoint_confirmed'] is False and load('-checkpoint-confirmation.json')['user_commit_and_push_completed'] is True)
for key in design['requirements']:
    check('admission requirement cannot be weakened '+key,rejected(ns['validate_design'],mutate(design,['requirements',key],False),prior,frozen))
for key,value in design['proof_state'].items():
    check('design selection cannot promote actual proof '+key,rejected(ns['validate_design'],mutate(design,['proof_state',key],not value if type(value) is bool else 'invented'),prior,frozen))
for key in ['selected_protocol','invocation_boundary','compatibility_rule','service_scope','service_traps','grant_validation','burn_boundary','claim_contract','launch_contract','handoff_contract','unknown_rule','private_model_scope']:
    check('admission design boundary cannot disappear '+key,rejected(ns['validate_design'],mutate(design,[key],''),prior,frozen))
for key in ['actual_storage_engine','actual_service_endpoint','actual_issuer','actual_attempt_id','actual_grant','actual_worker_command']:
    check('no fabricated operational admission binding '+key,rejected(ns['validate_design'],mutate(design,[key],'fixture-as-live'),prior,frozen))
for i,row in enumerate(design['future_proof_obligations']):
    check('future service proof retained '+row['id'],rejected(ns['validate_design'],mutate(design,['future_proof_obligations',i,'status'],'operational-PASS'),prior,frozen))
for i,row in enumerate(design['stage_mapping']):
    check('successor stage effect cannot be silently rewritten '+row['stage'],rejected(ns['validate_design'],mutate(design,['stage_mapping',i,'effect'],'owned-ledger-in-worker-stage0'),prior,frozen))
for key in ['seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','unresolved_design_edges','remaining_design_reviews']:
    check('prior requirements or separate design edge cannot be dropped '+key,rejected(ns['validate_design'],mutate(design,[key],[]),prior,frozen))
for name,row in ns['MODEL_CASES'].items():
    value=dict(case=name,origin='synthetic-private-fixture',scope='external-admission-contract-only');r=ns['evaluate_private_admission_case'](value)
    check('typed finite admission loss case '+name,all(r[k]==v for k,v in row.items()) and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['retry_authorized'] and not r['recovery_authorized'])
check('failed worker preflight burns grant in model only',ns['evaluate_private_admission_case'](dict(value,case='worker-preflight-failed'))['modeled_grant_consumed'] is True)
check('unknown durable claim remains null quarantined pending',ns['evaluate_private_admission_case'](dict(value,case='claim-durability-unknown'))['modeled_grant_consumed'] is None and ns['evaluate_private_admission_case'](dict(value,case='claim-durability-unknown'))['modeled_controller_obligations_pending'])
for key,new in dict(case='replay-success',origin='actual-host',scope='runtime-grant').items():check('admission classifier rejects '+key,rejected(ns['evaluate_private_admission_case'],dict(value,**{key:new})))
check('admission classifier rejects extra actual grant field',rejected(ns['evaluate_private_admission_case'],dict(value,actual_grant=True)))
events=['claim-durable-CAS','spend-launch-slot-durable','invoke-worker-once','ack']
schedule=lambda rows:dict(origin='synthetic-private-fixture',scope='atomic-contract-interleaving-not-real-concurrency',events=rows)
for positions in itertools.combinations(range(8),4):
    counts=[0,0];rows=[]
    for index in range(8):
        actor=0 if index in positions else 1;rows.append(dict(actor=actor,event=events[counts[actor]]));counts[actor]+=1
    r=ns['simulate_private_schedule'](schedule(rows))
    check('two claimant interleaving has one consumed owner and one launch '+str(positions),r['modeled_owner']==rows[0]['actor'] and r['modeled_worker_invocations']==1 and r['modeled_launch_slot_spent'] and not r['actual_atomicity_or_durability_proven'])
    for index in range(9):
        crashed=rows[:index]+[dict(actor=0,event='crash')]+rows[index:]
        r=ns['simulate_private_schedule'](schedule(crashed));trace=r['trace'];first=trace[index]
        check('crash cannot replay or relaunch '+str(positions)+'/'+str(index),r['modeled_worker_invocations']<=1 and r['modeled_pending_controller'] and all(t['owner']==first['owner'] and t['spent']==first['spent'] and t['invocations']==first['invocations'] for t in trace[index:]) and not r['retry_authorized'])
for rows,label in [([dict(actor=0,event='invoke-worker-once')],'spawn-before-consume'),([dict(actor=0,event='claim-durable-CAS'),dict(actor=0,event='invoke-worker-once')],'spawn-before-durable-slot'),([dict(actor=0,event=e) for e in events]+[dict(actor=0,event='invoke-worker-once')],'duplicate-spawn'),([dict(actor=0,event='claim-durable-CAS'),dict(actor=1,event='spend-launch-slot-durable'),dict(actor=1,event='invoke-worker-once')],'foreign-owner')]:
    r=ns['simulate_private_schedule'](schedule(rows));check('out-of-order or replay events denied '+label,r['modeled_denials']>=1 and r['modeled_worker_invocations']<=1)
for row in [dict(actor=True,event='claim-durable-CAS'),dict(actor=2,event='ack'),dict(actor=0,event='host-exec'),dict(actor=0,event='ack',runtime=True)]:check('typed schedule rejects unsafe event '+repr(row),rejected(ns['simulate_private_schedule'],schedule([row])))
check('unbounded schedule rejected',rejected(ns['simulate_private_schedule'],schedule([dict(actor=0,event='ack')]*21)))
a=(fixture/(base+'-admission-states.tsv')).read_bytes();b=(fixture/(base+'-failure-cases.tsv')).read_bytes()
check('exact admission states and loss matrix accepted',ns['validate_tables'](a,b))
check('unknown consumption cannot become false in TSV',rejected(ns['validate_tables'],a,b.replace(b'\tnull\t',b'\tno\t')))
check('no reuse gate cannot disappear in TSV',rejected(ns['validate_tables'],a.replace(b'quarantined-no-replay',b'reusable'),b))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict320 review CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step320-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real320 entry reruns complete exact547 predecessor suite',result.returncode==0 and 'exact_step319_acceptance\tPASS (547 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered547 predecessor capture',sum(x.startswith('PASS: ') for x in log)==547 and log[-1]=='Result: PASS (547 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published320 review input '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no actual dispatch claim or pause','actual_dispatch_authorized\tno' in result.stdout and 'actual_grant_consumed\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n')
        check('all occupied outputs checked before first write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md',ns['FIXTURE']+'/'+ns['PRIOR']+'-plan.json']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed frozen or admission input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';old=p.read_bytes();saved=area/'saved';saved.write_bytes(old);p.unlink();p.symlink_to(saved)
    check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1458 historical artifacts exact after validation',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
