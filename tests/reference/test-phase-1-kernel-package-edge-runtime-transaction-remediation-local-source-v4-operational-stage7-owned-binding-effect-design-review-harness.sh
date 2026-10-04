#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact322 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='cb977907987f51fc5267562ea1f77412927b4e15b84d03a9d312bf8086a798cb')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step322_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_design'](value,prior,frozen,history)
check('exact1476 predecessor bytes and original CHANGELOG suffix',len(history)==1476)
check('complete2251 original321 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step321-user-acceptance.json')))
check('successor owned stage7 contract accepted',validate(design))
check('old stage7 readonly and private persistence retained as immutable facts',ns['extract_stage_facts'](history,frozen)==design['immutable_stage_facts'] and design['immutable_stage_facts']['frozen_stage7']['effect']=='read-only' and design['immutable_stage_facts']['private_binding_persists_owned_file'])
check('prepared321 still pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('owned binding requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no model promotion to actual binding proof '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for key in ['selected_effect','compatibility_rule','private_model_scope']:check('binding boundary retained '+key,rejected(validate,mutate(design,[key],'')))
for key in ['seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges']:check('previous requirements or separate design edge retained '+key,rejected(validate,mutate(design,[key],[])))
for key in ['actual_commit_primitive','actual_durability_backend','actual_binding_bytes']:check('no invented real binding implementation '+key,rejected(validate,mutate(design,[key],'fixture-as-live')))
for key in ['actual_root','actual_owner','actual_parent','actual_staging_path','actual_final_path']:check('no actual owned path or owner binding '+key,rejected(validate,mutate(design,['owned_paths',key],'fixture-path')))
for key in design['successor_stage7']:check('successor stage field cannot drift '+key,rejected(validate,mutate(design,['successor_stage7',key],'unreviewed')))
for i,row in enumerate(design['future_proof_obligations']):check('future real stage7 proof retained '+row['id'],rejected(validate,mutate(design,['future_proof_obligations',i,'status'],'operational-PASS')))
gate=dict(origin='synthetic-private-fixture',scope='owned-binding-preparation-only',conditions=dict.fromkeys(ns['GATE_KEYS'],True))
r=ns['evaluate_private_binding_gate'](gate);check('all modeled owned write prerequisites eligible without real authority',r['model_owned_binding_preparation_eligible'] and not r['actual_binding_write_authorized'])
for key in ns['GATE_KEYS']:
    check('missing owned-write condition stops '+key,not ns['evaluate_private_binding_gate'](mutate(gate,['conditions',key],False))['model_owned_binding_preparation_eligible'])
    check('typed owned-write condition required '+key,rejected(ns['evaluate_private_binding_gate'],mutate(gate,['conditions',key],1)))
check('extra real binding grant field rejected',rejected(ns['evaluate_private_binding_gate'],dict(gate,actual_write=True)))
binding=dict(origin='synthetic-private-fixture',scope='candidate-observations-not-authority',raw_pkglist=ns['FIXTURE_RAW_ROW'].encode(),expected_pkglist_sha256=ns['FIXTURE_RAW_SHA'],binding_bytes=ns['canonical'](ns['FIXTURE_BINDING']))
r=ns['evaluate_private_binding_bytes'](binding);check('canonical synthetic pinned binding has no selector or dispatch proof',r['model_original_binding_bytes_eligible'] and all(v is False for k,v in r.items() if k.startswith('actual_')))
for key in ns['FIXTURE_BINDING']:
    changed=mutate(ns['FIXTURE_BINDING'],[key],True if key in ['actual_selector_effect_proven','operational_readiness'] else 'foreign-or-drift')
    check('original binding cannot self-rebind '+key,not ns['evaluate_private_binding_bytes'](dict(binding,binding_bytes=ns['canonical'](changed)))['model_original_binding_bytes_eligible'])
raw=ns['FIXTURE_RAW_ROW'].replace(' ','  ').encode()
check('logical same row different raw bytes denied',not ns['evaluate_private_binding_bytes'](dict(binding,raw_pkglist=raw))['model_original_binding_bytes_eligible'])
check('rehash new raw cannot replace original pin',not ns['evaluate_private_binding_bytes'](dict(binding,raw_pkglist=raw,expected_pkglist_sha256=hashlib.sha256(raw).hexdigest()))['model_original_binding_bytes_eligible'])
for raw in [b'{}',b'{"scope":"x","scope":"x"}',binding['binding_bytes']+b' ',binding['binding_bytes'][:-1],b'\xff']:
    check('malformed or noncanonical binding denied '+str(len(raw)),not ns['evaluate_private_binding_bytes'](dict(binding,binding_bytes=raw))['model_original_binding_bytes_eligible'])
check('oversize binding rejected',rejected(ns['evaluate_private_binding_bytes'],dict(binding,binding_bytes=b'x'*65537)))
model=lambda events,phase:dict(origin='synthetic-private-fixture',scope='stage7-owned-effect-contract-only',events=events,prior_target_phase=phase)
events=ns['COMMIT_EVENTS']
for phase in ['baseline','predecessor','unknown']:
    r=ns['simulate_private_binding_events'](model(events,phase));check('stage7 qualification never closes prior phase '+phase,r['model_stage7_qualified'] and r['modeled_possible_machine_obligations']==(phase!='baseline') and not r['actual_host_obligations_closed'])
    for index in range(len(events)+1):
        prefix=events[:index];r=ns['simulate_private_binding_events'](model(prefix,phase))
        check('complete known commit and evidence required '+phase+'/'+str(index),r['model_stage7_qualified']==(index==len(events)) and r['modeled_controller_obligations_pending']==(index!=len(events)))
        for failure in ns['FAILURE_EVENTS']:
            schedule=prefix+[failure]+events[index:];r=ns['simulate_private_binding_events'](model(schedule,phase));trace=r['trace'];at=trace[index]
            check('partial commit loss latches and preserves prior effects '+phase+'/'+str(index)+'/'+failure,not r['model_stage7_qualified'] and r['modeled_controller_obligations_pending'] and r['modeled_possible_machine_obligations']==(phase!='baseline') and all(t['progress']==at['progress'] and t['forward_latched'] for t in trace[index:]) and not r['retry_authorized'])
for i in range(1,len(events)):
    r=ns['simulate_private_binding_events'](model([events[i]],'predecessor'));check('out-of-order owned action cannot run '+events[i],not r['model_stage7_qualified'] and r['modeled_denials']==1 and not r['modeled_owned_artifacts_preserved'])
for key,new in dict(origin='actual-host',scope='real-write',prior_target_phase='restored-by-stage7',events=['force-rename']).items():check('typed binding schedule rejects '+key,rejected(ns['simulate_private_binding_events'],dict(model([], 'baseline'),**{key:new})))
check('bounded binding event count required',rejected(ns['simulate_private_binding_events'],model(events*3,'baseline')))
a=(fixture/(base+'-stage-effect-map.tsv')).read_bytes();b=(fixture/(base+'-binding-commit-matrix.tsv')).read_bytes()
check('exact compatibility and binding commit tables',ns['validate_tables'](a,b));check('owned binding cannot stay readonly in successor map',rejected(ns['validate_tables'],a.replace(b'7\tread-only\towned-files',b'7\tread-only\tread-only'),b));check('durability stage cannot be skipped',rejected(ns['validate_tables'],a,b.replace(b'directory-durability-confirmed',b'optional-directory-flush')))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict322 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step322-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real322 entry reruns full exact2251 predecessor acceptance',result.returncode==0 and 'exact_step321_acceptance\tPASS (2251 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered2251 predecessor capture',sum(x.startswith('PASS: ') for x in log)==2251 and log[-1]=='Result: PASS (2251 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published322 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no binding write dispatch or durability proof','actual_binding_write_or_dispatch_authorized\tno' in result.stdout and 'actual_no_replace_and_durability_proven\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md',ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json',ns['PRIVATE_MODEL_PATH'],frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed stage7 or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';old=p.read_bytes();saved=area/'saved';saved.write_bytes(old);p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1476 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
