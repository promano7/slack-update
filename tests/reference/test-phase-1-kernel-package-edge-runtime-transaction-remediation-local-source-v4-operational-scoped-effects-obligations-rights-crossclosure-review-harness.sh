#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-scoped-effects-obligations-rights-crossclosure-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact327 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='91cad540f8db5c55e5194602677c2e5dac6f73ac5e224ee34f67b31d525b844e')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step327_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_design'](value,prior,frozen,history)
check('exact1521 predecessor bytes and original CHANGELOG suffix',len(history)==1521)
check('complete3404 original326 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step326-user-acceptance.json')))
check('finite failure and independent conformance contracts accepted',validate(design))
check('prepared326 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('recovery requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no real recovery proof from model '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for section in ['crossclosure_contract']:
    for key in design[section]:check('explicit split-rights contract retained '+section+'/'+key,rejected(validate,mutate(design,[section,key],'unreviewed')))
for key in ['selected_policy','previous_design_bindings','seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges','private_model_scope','reference_review_binding','whole_graph_binding','catalogue_edges','crossclosure_matrix','authority_windows','future_proof_inventory','inherited_blocker_disposition','conformance_plan_binding','vector_ids']:
    check('prior or separate obligation retained '+key,rejected(validate,mutate(design,[key],[])))
for i,row in enumerate(design['future_proof_obligations']):check('real future recovery proof retained '+row['id'],rejected(validate,mutate(design,['future_proof_obligations',i,'status'],'operational-PASS')))


graph=json.loads(history[design['whole_graph_binding']['path']])
check('all30 effect nodes and every designed edge retained',len(design['crossclosure_matrix'])==30 and [r['effect_node'] for r in design['crossclosure_matrix']]==[r['id'] for r in graph['catalogue_nodes']] and design['catalogue_edges']==graph['catalogue_edges'])
capabilities={r['capability'] for r in frozen['seven_review_bindings']};obligations={r['id'] for r in frozen['proof_obligations']};proofids={r['qualified_id'] for r in design['future_proof_inventory']}
check('matrix covers every seven capability ten obligation and42 future proofs',{x for r in design['crossclosure_matrix'] for x in r['capabilities']}==capabilities and {x for r in design['crossclosure_matrix'] for x in r['cross_obligations']}==obligations and {x for r in design['crossclosure_matrix'] for x in r['future_proofs']}==proofids and len(proofids)==42)
for i,row in enumerate(design['crossclosure_matrix']):
    check('actual effect obligations rights unobserved not closed '+row['effect_node'],row['actual_effect_binding'] is None and row['actual_writers'] is None and row['actual_outcome'] is None and all(row[k] is False for k in ['actual_effect_closed','actual_obligations_closed','actual_rights_valid','actual_operational_conformance']))
    for key in ['capabilities','cross_obligations','future_proofs','source_design_bindings','conformance_case_ids']:
        check('effect linkage retained '+row['effect_node']+'/'+key,rejected(validate,mutate(design,['crossclosure_matrix',i,key],[])))
    check('actual effect closure cannot be promoted '+row['effect_node'],rejected(validate,mutate(design,['crossclosure_matrix',i,'actual_effect_closed'],True)))
for i,row in enumerate(design['future_proof_inventory']):
    original=json.loads(history[row['source_design_path']]);expected={r['id']:r for r in original['future_proof_obligations']}
    check('immutable proof statement status and source retained '+row['qualified_id'],row['source_proof']==expected[row['source_proof']['id']] and row['source_proof']['status']=='required-not-proven' and row['actual_evidence'] is None and not row['operational_proven'])
    check('future proof cannot be waived '+row['qualified_id'],rejected(validate,mutate(design,['future_proof_inventory',i,'operational_proven'],True)))
    check('future proof cannot be replaced by private receipt '+row['qualified_id'],rejected(validate,mutate(design,['future_proof_inventory',i,'actual_evidence'],'fixture-PASS')))
for i,row in enumerate(design['inherited_blocker_disposition']):
    check('inherited blocker retained with actual pending disposition '+row['inherited_blocker'],row['inherited_blocker']==frozen['remaining_operational_blockers'][i] and row['operational_blocker_retained'] and row['actual_proof'] is None)
    check('selected design cannot waive old operational blocker '+row['inherited_blocker'],rejected(validate,mutate(design,['inherited_blocker_disposition',i,'operational_blocker_retained'],False)))
for i,row in enumerate(design['authority_windows']):
    check('every actual actor authority binding remains null '+row['window'],row['actual_issuer'] is None and row['actual_scope'] is None and row['actual_deadline'] is None and row['actual_budget'] is None and row['actual_fence'] is None and not row['actual_authority_valid'])
    check('private model cannot bind actual authority '+row['window'],rejected(validate,mutate(design,['authority_windows',i,'actual_authority_valid'],True)))
window=ns['evaluate_private_rights_window']
window_fixture=lambda name,state='known-consumed':dict(origin='synthetic-private-fixture',scope='actor-specific-rights-window-contract-only',window=name,grant_state=state,conditions=dict.fromkeys(ns['RIGHT_GATE_KEYS'],True))
for name,keys in ns['WINDOW_GATES'].items():
    for state in ['known-unused','known-consumed','unknown']:
        for mask in range(16):
            current=window_fixture(name,state)
            for i,key in enumerate(['forward_rights_live','finite_retained_recovery_rights_live','independent_publication_rights_live','same_attempt_same_boot_phase']):current['conditions'][key]=bool(mask&(1<<i))
            expected=all(current['conditions'][k] for k in keys) and name!='forbidden'
            if name=='admission':expected=expected and state=='known-unused'
            elif name in ['launch','bootstrap','service','forward','recovery']:expected=expected and state=='known-consumed'
            r=window(current);check('actor rights and grant state combination '+name+'/'+state+'/'+str(mask),r['model_window_contract_eligible']==expected and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['new_target_grant_from_publication'] and not r['forward_renewal_from_recovery'])
    for key in keys:
        current=window_fixture(name,'known-unused' if name=='admission' else 'known-consumed');current['conditions'][key]=False;check('each actor window gate required '+name+'/'+key,not window(current)['model_window_contract_eligible'])
for key in ns['RIGHT_GATE_KEYS']:check('strict typed actor right gate '+key,rejected(window,mutate(window_fixture('forward'),['conditions',key],1)))
check('admission unused original grant distinct from nested consumed',window(window_fixture('admission','known-unused'))['model_window_contract_eligible'] and not window(window_fixture('admission'))['model_window_contract_eligible'] and window(window_fixture('forward'))['model_window_contract_eligible'] and not window(window_fixture('forward','known-unused'))['model_window_contract_eligible'])
current=window_fixture('recovery');current['conditions']['forward_rights_live']=False;check('finite original recovery does not renew forward',window(current)['model_window_contract_eligible'] and not window(current)['forward_renewal_from_recovery'])
current['conditions']['same_attempt_same_boot_phase']=False;check('wrong boot blocks original retained recovery',not window(current)['model_window_contract_eligible'])
current=window_fixture('publication','unknown');current['conditions']['forward_rights_live']=current['conditions']['finite_retained_recovery_rights_live']=False;check('separate closed captured publication is not fresh target grant',window(current)['model_window_contract_eligible'] and not window(current)['new_target_grant_from_publication'] and not window(current)['actual_target_effect_authorized'])
current['conditions']['captured_closed_target_data']=False;check('publication cannot replace pending target closure',not window(current)['model_window_contract_eligible'])
check('unknown actor window rejected',rejected(window,dict(window_fixture('forward'),window='unknown-namespace-helper')))
check('reused receipt not accepted as private context origin',rejected(window,dict(window_fixture('forward'),origin='historical-live-receipt')))
for state in [True,None,'spent-maybe']:check('typed actor grant state '+repr(state),rejected(window,dict(window_fixture('forward'),grant_state=state)))
evaluate=ns['evaluate_private_crossclosure']
index_fixture=lambda claim='repository-design-crossclosure':dict(origin='synthetic-private-fixture',scope='complete-scoped-evidence-index-contract-only',claim=claim,conditions=dict.fromkeys(ns['CLOSURE_GATES'],True),vectors={k:dict.fromkeys(ids,True) for k,ids in ns['VECTOR_IDS'].items()})
r=evaluate(index_fixture());check('complete private disposition index never actual effects obligations rights proof',r['model_repository_design_claim_eligible'] and r['model_scoped_index_complete'] and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['new_grant_authorized'] and not r['operational_proof_waived'] and not r['unobserved_state_is_absent'])
for domain,ids in ns['VECTOR_IDS'].items():
    for item in ids:
        current=index_fixture();current['vectors'][domain][item]=False;check('no crossclosure disposition omitted '+domain+'/'+item,not evaluate(current)['model_repository_design_claim_eligible'])
        check('strict crossclosure vector value '+domain+'/'+item,rejected(evaluate,mutate(index_fixture(),['vectors',domain,item],1)))
    current=index_fixture();current['vectors'][domain].pop(ids[0]);check('missing vector key rejected '+domain,rejected(evaluate,current))
    current=index_fixture();current['vectors'][domain]['unreviewed-extra']=True;check('foreign vector key rejected '+domain,rejected(evaluate,current))
for key in ns['CLOSURE_GATES']:
    current=index_fixture();current['conditions'][key]=False;check('each scoped crossclosure prerequisite required '+key,not evaluate(current)['model_repository_design_claim_eligible'])
    check('strict scoped crossclosure prerequisite '+key,rejected(evaluate,mutate(index_fixture(),['conditions',key],1)))
for claim in ['actual-runtime-readiness','global-host-absence','new-runtime-authorization']:
    r=evaluate(index_fixture(claim));check('complete private matrix cannot promote '+claim,r['model_scoped_index_complete'] and not r['model_repository_design_claim_eligible'] and all(v is False for k,v in r.items() if k.startswith('actual_')))
check('unknown closure claim rejected',rejected(evaluate,index_fixture('actual-all-grants-and-host-closed')))
check('actual self report cannot be private closure origin',rejected(evaluate,dict(index_fixture(),origin='signed-operational-self-report')))
check('all52 conformance case dispositions remain required-not-run',design['conformance_plan_binding']['case_count']==52 and design['conformance_plan_binding']['actual_runs']==0 and len(ns['VECTOR_IDS']['independent_case_dispositions'])==52)
a=(fixture/(base+'-effects-obligations-rights-crossclosure.tsv')).read_bytes();b=(fixture/(base+'-proofs-and-authority-windows.tsv')).read_bytes()
check('exact complete crossclosure proof and authority tables',ns['validate_tables'](a,b))
check('no designed effect omitted',rejected(ns['validate_tables'],b'\n'.join(a.splitlines()[:-1])+b'\n',b))
check('no pending operational proof promoted',rejected(ns['validate_tables'],a,b.replace(b'required-not-proven',b'PASS')))

for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict327 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step327-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real327 entry reruns full exact3404 predecessor acceptance',result.returncode==0 and 'exact_step326_acceptance\tPASS (3404 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered3404 predecessor capture',sum(x.startswith('PASS: ') for x in log)==3404 and log[-1]=='Result: PASS (3404 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published327 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no live forward recovery clock fence or restoration proof','actual_effects_obligations_rights_or_conformance_proven\tno' in result.stdout and 'actual_dispatch_or_publication_authorized\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']+[x['path'] for x in design['previous_design_bindings'].values()]+[design['reference_review_binding']['path'],frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed recovery or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1521 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
