#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-scoped-integration-design-freeze-and-strong-safe-pause';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact328 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='37dff8e694a871bbd1049545ccb72e0c8615daab1560bf2aaa6e70f35853c8e2')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step328_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-freeze.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_freeze'](value,prior,frozen,history)
check('exact1530 predecessor bytes and original CHANGELOG suffix',len(history)==1530)
check('complete1361 original327 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step327-user-acceptance.json')))
check('finite failure and independent conformance contracts accepted',validate(design))
check('prepared327 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('recovery requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no real recovery proof from model '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for section in ['integration_contract','pause_contract','resume_boundary','crossclosure_counts']:
    for key in design[section]:check('scoped freeze and conditional pause retained '+section+'/'+key,rejected(validate,mutate(design,[section,key],'unreviewed')))
for key in ['scope','freeze_version','successor_contract_bindings','contract_view_fields','frozen_contract_views','original_resume_plan_binding','batch_acceptance_register','seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_batch_design_reviews','in_scope_unresolved_normative_design_dispositions','private_model_scope','future_proof_register','inherited_blocker_disposition']:
    check('source normative scope or separate proof retained '+key,rejected(validate,mutate(design,[key],['invented'])))

check('original319 route stops at328 within original scope',design['pause_contract']['scope']==design['scope'] and not design['remaining_batch_design_reviews'] and not design['in_scope_unresolved_normative_design_dispositions'])
check('all eight successor views source-bound',sorted(design['successor_contract_bindings'])==list(map(str,range(320,328))))
for step,binding in design['successor_contract_bindings'].items():
    original=json.loads(history[binding['path']])
    check('exact normative source view '+step,design['frozen_contract_views'][step]=={key:original[key] for key in design['contract_view_fields'][step]})
    for key in design['contract_view_fields'][step]:
        check('selected normative contract cannot be omitted '+step+'/'+key,rejected(validate,mutate(design,['frozen_contract_views',step,key],'unreviewed')))
    check('successor source SHA cannot drift '+step,rejected(validate,mutate(design,['successor_contract_bindings',step,'sha256'],'0'*64)))
for i,row in enumerate(design['batch_acceptance_register']):
    check('original accepted route checkpoint and328 pending '+str(row['step']),row['status']==('prepared-user-application-tests-commit-push-return-pending' if row['step']==328 else 'confirmed-complete-original-user-return') and row['runtime_authority'] is False and row['operational_conformance'] is False)
    check('historical or pending checkpoint cannot be promoted '+str(row['step']),rejected(validate,mutate(design,['batch_acceptance_register',i,'status'],'actual-runtime-conformance')))
check('328 real commit and acceptance unknown',all(design['batch_acceptance_register'][-1][k] is None for k in ['commit_prefix','commit_full','acceptance','source_confirmation_path','source_confirmation_sha256','evidence_sha256']))
for i,row in enumerate(design['future_proof_register']):
    original=json.loads(history[row['source_design_path']]);expected={r['id']:r for r in original['future_proof_obligations']}
    check('exact future proof statement source and status '+row['qualified_id'],row['source_proof']==expected[row['source_proof']['id']] and row['source_proof']['status']=='required-not-proven' and row['actual_evidence'] is None and not row['operational_proven'])
    for key,new in [('operational_proven',True),('actual_evidence','private-PASS')]:
        check('freeze never waives actual proof '+row['qualified_id']+'/'+key,rejected(validate,mutate(design,['future_proof_register',i,key],new)))
for i,row in enumerate(design['inherited_blocker_disposition']):
    check('immutable inherited blocker retained '+row['inherited_blocker'],row['inherited_blocker']==frozen['remaining_operational_blockers'][i] and row['operational_blocker_retained'] and row['actual_proof'] is None)
    check('normative resolution does not erase actual blocker '+row['inherited_blocker'],rejected(validate,mutate(design,['inherited_blocker_disposition',i,'operational_blocker_retained'],False)))
check('all30 effects seven capabilities ten obligations nine windows46 proofs52 cases retained',design['crossclosure_counts']==dict(effect_domains=30,seven_capabilities=7,cross_obligations=10,authority_windows=9,inherited320_327_future_proofs=46,independent_platform_cases=52,actual_platform_cases_run=0))
check('separate conformance has zero actual runs',prior['conformance_plan_binding']['actual_runs']==0 and prior['conformance_plan_binding']['case_count']==52)
check('frozen source327 windows remain actually unbound',len(prior['authority_windows'])==9 and all(not r['actual_authority_valid'] and r['actual_issuer'] is None for r in prior['authority_windows']))
evaluate=ns['evaluate_private_pause']
pause_fixture=lambda claim=ns['PAUSE_SCOPE']:dict(origin='synthetic-private-fixture',scope='conditional-repository-pause-contract-only',host_state='unobserved-not-claimed-absent',claim_scope=claim,conditions=dict.fromkeys(ns['PAUSE_GATES'],True),acceptance=dict.fromkeys(ns['ACCEPTANCE_KEYS'],True),effects=dict.fromkeys(ns['BATCH_EFFECT_KEYS'],True))
def closed(r):return all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['live_binding_reused'] and not r['optional329_330_authorized'] and not r['automatic_next_stage_authorized'] and not r['required_new_machine_action'] and not r['required_new_controller_action'] and r['last_confirmed_strong_safe_pause_step']==318
check('complete synthetic pause contract never confirms actual328 or host or runtime',evaluate(pause_fixture())['model_repository_pause_contract_eligible'] and closed(evaluate(pause_fixture())))
for domain,keys in [('conditions',ns['PAUSE_GATES']),('acceptance',ns['ACCEPTANCE_KEYS']),('effects',ns['BATCH_EFFECT_KEYS'])]:
    for key in keys:
        r=evaluate(mutate(pause_fixture(),[domain,key],False));check('every scoped pause gate required '+domain+'/'+key,not r['model_repository_pause_contract_eligible'] and closed(r))
        check('strict pause bool '+domain+'/'+key,rejected(evaluate,mutate(pause_fixture(),[domain,key],1)))
    current=pause_fixture();current[domain].pop(keys[0]);check('missing pause flag rejected '+domain,rejected(evaluate,current))
    current=pause_fixture();current[domain]['foreign']=True;check('extra pause flag rejected '+domain,rejected(evaluate,current))
    check('non-dict pause vector rejected '+domain,rejected(evaluate,mutate(pause_fixture(),[domain],[])))
for domain,keys in [('acceptance',ns['ACCEPTANCE_KEYS']),('effects',ns['BATCH_EFFECT_KEYS'])]:
    for mask in range(1<<len(keys)):
        current=pause_fixture();current[domain]={key:bool(mask&(1<<i)) for i,key in enumerate(keys)};r=evaluate(current)
        check('complete declared pause vector '+domain+'/'+str(mask),r['model_repository_pause_contract_eligible']==(mask==(1<<len(keys))-1) and closed(r))
for claim in ['actual-global-host-closure','actual-runtime-readiness']:
    r=evaluate(pause_fixture(claim));check('full private gates cannot claim '+claim,not r['model_repository_pause_contract_eligible'] and closed(r))
for host in ['absent','closed',None,False]:check('unobserved actual host never inferred absent '+repr(host),rejected(evaluate,dict(pause_fixture(),host_state=host)))
for field,new in [('origin','actual328-user-receipt'),('scope','actual-runtime'),('claim_scope','all-live-grants-closed')]:check('private pause context cannot promote '+field,rejected(evaluate,dict(pause_fixture(),**{field:new})))
resume=ns['evaluate_private_resume'];resume_fixture=lambda action='repository-resume-planning':dict(origin='synthetic-private-fixture',scope='post-pause-repository-planning-boundary-only',action=action,conditions=dict.fromkeys(ns['RESUME_GATES'],True))
for action in ns['RESUME_ACTIONS']:
    for mask in range(1<<len(ns['RESUME_GATES'])):
        current=resume_fixture(action);current['conditions']={key:bool(mask&(1<<i)) for i,key in enumerate(ns['RESUME_GATES'])};r=resume(current)
        check('post-pause request and action vector '+action+'/'+str(mask),r['model_repository_resume_planning_eligible']==(action=='repository-resume-planning' and mask==(1<<len(ns['RESUME_GATES']))-1) and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['optional329_330_authorized'] and not r['automatic_next_stage_authorized'])
for key in ns['RESUME_GATES']:check('strict future repository planning bool '+key,rejected(resume,mutate(resume_fixture(),['conditions',key],1)))
for field,new in [('origin','old-signed-grant'),('scope','operational-resume'),('action','next-step-without-new-request')]:check('resume scope or identity never reused '+field,rejected(resume,dict(resume_fixture(),**{field:new})))
current=resume_fixture();current['conditions'].pop(ns['RESUME_GATES'][0]);check('missing future request condition rejected',rejected(resume,current))
current=resume_fixture();current['conditions']['foreign']=True;check('foreign future request condition rejected',rejected(resume,current))
a=(fixture/(base+'-integration-freeze-closure.tsv')).read_bytes();b=(fixture/(base+'-future-proof-register.tsv')).read_bytes()
check('exact complete freeze and future proof tables',ns['validate_tables'](a,b))
check('no normative effect omitted',rejected(ns['validate_tables'],b'\n'.join(a.splitlines()[:-1])+b'\n',b))
check('no actual proof status promoted',rejected(ns['validate_tables'],a,b.replace(b'required-not-proven',b'PASS')))

for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict328 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step328-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real328 entry reruns full exact1361 predecessor acceptance',result.returncode==0 and 'exact_step327_acceptance\tPASS (1361 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered1361 predecessor capture',sum(x.startswith('PASS: ') for x in log)==1361 and log[-1]=='Result: PASS (1361 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published328 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no live forward recovery clock fence or restoration proof','actual_effects_obligations_rights_or_conformance_proven\tno' in result.stdout and 'actual_dispatch_or_publication_authorized\tno' in result.stdout and 'strong_safe_pause\tno-user328-acceptance-pending' in result.stdout and 'repository_strong_safe_pause_candidate\tconditional-complete328-user-return' in result.stdout and 'next_stage_authorized\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']+[x['path'] for x in design['successor_contract_bindings'].values()]+[design['original_resume_plan_binding']['path'],frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed recovery or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1530 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
