#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-whole-service-reference-helper-selector-source-backend-publication-effect-graph-design-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact325 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='d1aa52e85750084214b3b7b1ce16e73b4e1d9be74c72f0f46440a7a340e7555c')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step325_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
validate=lambda value:ns['validate_design'](value,prior,frozen,history)
check('exact1503 predecessor bytes and original CHANGELOG suffix',len(history)==1503)
check('complete797 original324 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step324-user-acceptance.json')))
check('split issuer rights and bounded recovery contract accepted',validate(design))
check('prepared324 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('recovery requirement retained '+key,rejected(validate,mutate(design,['requirements',key],False)))
for key,value in design['proof_state'].items():check('no real recovery proof from model '+key,rejected(validate,mutate(design,['proof_state',key],not value if type(value) is bool else 'invented')))
for section in ['graph_contract','selector_contract','publication_contract']:
    for key in design[section]:check('explicit split-rights contract retained '+section+'/'+key,rejected(validate,mutate(design,[section,key],'unreviewed')))
for key in ['selected_policy','previous_design_bindings','seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges','private_model_scope','reference_review_binding','reference_census','catalogue_nodes','catalogue_edges','nested_argv_contract']:
    check('prior or separate obligation retained '+key,rejected(validate,mutate(design,[key],[])))
for i,row in enumerate(design['future_proof_obligations']):check('real future recovery proof retained '+row['id'],rejected(validate,mutate(design,['future_proof_obligations',i,'status'],'operational-PASS')))


check('whole reference source census covers every exact header segment',ns['reference_census'](history[design['reference_path']])==design['reference_census'])
for row in design['reference_census']['functions']:
    check('static source segment stays bound '+row['name'],rejected(validate,mutate(design,['reference_census','functions',design['reference_census']['functions'].index(row),'sha256'],'invented')))
for i,node in enumerate(design['catalogue_nodes']):
    check('effect catalogue node retained '+node['id'],rejected(validate,mutate(design,['catalogue_nodes',i,'proof_status'],'operational-PASS')))
for i,edge in enumerate(design['catalogue_edges']):
    check('effect dependency edge retained '+str(i),rejected(validate,mutate(design,['catalogue_edges',i],['missing','missing'])))
graph_fixture=lambda node:dict(origin='synthetic-private-fixture',scope='transitive-effect-contract-only',node=node,conditions=dict.fromkeys(ns['GATE_KEYS'],True))
for node,keys in ns['NODE_GATES'].items():
    r=ns['evaluate_private_graph_node'](graph_fixture(node));check('modeled graph gate no real authority '+node,r['model_node_contract_eligible']==(node not in ns['FORBIDDEN_DISPATCH_NODES']) and all(v is False for k,v in r.items() if k.startswith('actual_')))
    for key in keys:
        r=ns['evaluate_private_graph_node'](mutate(graph_fixture(node),['conditions',key],False));check('missing transitive node obligation denies '+node+'/'+key,not r['model_node_contract_eligible'])
for key in ns['GATE_KEYS']:check('strict graph gate type '+key,rejected(ns['evaluate_private_graph_node'],mutate(graph_fixture('whole-reference-entry'),['conditions',key],1)))
check('unknown helper node denied',rejected(ns['evaluate_private_graph_node'],graph_fixture('unknown-unreviewed-helper')))
check('admission burn checks original authenticated unused grant without consumed worker precondition','known_authenticated_unused_grant' in ns['NODE_GATES']['durable-admission-claim'] and 'same_consumed_active_attempt' not in ns['NODE_GATES']['durable-admission-claim'])
check('worker and nested effects require same consumed active attempt','same_consumed_active_attempt' in ns['NODE_GATES']['nested-call-adapter'])
def call(action,status=0):
    return dict(action=action,argv=copy.deepcopy(ns['CALL_ARGV'].get(action,[])),raw_status=status,raw_pkglist_sha256=ns['FIXTURE_RAW_PIN'],inputs=copy.deepcopy(ns['SELECTOR_INPUTS']),selectors=copy.deepcopy(ns['SELECTOR_VECTORS']),effects=copy.deepcopy(ns['CALL_EFFECTS'].get(action,[])),stdout_error=False,stderr_error=False)
def nested(calls):return dict(origin='synthetic-private-fixture',scope='raw-selector-status-and-persistent-latch-contract-only',conditions=dict.fromkeys(ns['SELECTOR_GATES'],True),calls=calls)
simulate=ns['simulate_private_nested_calls'];calls=[call('update'),call('install-new',20),call('upgrade-all')];r=simulate(nested(calls))
check('raw empty install-new20 and exact upgrade0 qualify only private contract',r['model_satisfied_call_count']==3 and r['trace'][1]['raw_status']==20 and all(v is False for k,v in r.items() if k.startswith('actual_')))
for action in ['update','install-new','upgrade-all']:
    for status in [-1,0,1,2,20]:
        current=call(action,status);r=simulate(nested([current]));expected=status==0 or action=='install-new' and status==20
        check('raw status policy remains exact '+action+'/'+str(status),r['model_satisfied_call_count']==int(expected) and r['trace'][0]['raw_status']==status)
for key in ns['SELECTOR_GATES']:
    r=simulate(mutate(nested(calls),['conditions',key],False));check('missing independent selector effect gate denies all '+key,r['model_satisfied_call_count']==0 and all(t['forward_latched'] for t in r['trace']))
    check('strict selector effect gate type '+key,rejected(simulate,mutate(nested(calls),['conditions',key],1)))
for failure_index in range(3):
    changed=copy.deepcopy(calls);changed[failure_index]['raw_status']=1;r=simulate(nested(changed))
    check('reference caller continuation cannot escape sticky failure at call '+str(failure_index),all(t['forward_latched'] and not t['model_contract_satisfied'] for t in r['trace'][failure_index:]) and r['model_original_failure_raw_status']==1)
for action in ['update','install-new','upgrade-all']:
    for side in ['stdout_error','stderr_error']:
        current=call(action);current[side]=True;r=simulate(nested([current,call('upgrade-all')]))
        check('raw0 stream error latches later mutation '+action+'/'+side,r['model_satisfied_call_count']==0 and r['model_original_failure_raw_status']==0)
    for key in ns['SELECTOR_INPUTS']:
        current=call(action);current['inputs'][key]='foreign-or-drift';r=simulate(nested([current]));check('all original selector inputs immutable '+action+'/'+key,r['model_satisfied_call_count']==0)
    current=call(action);current['raw_pkglist_sha256']='rehash-as-new-pin';check('raw pkglist cannot repin '+action,simulate(nested([current]))['model_satisfied_call_count']==0)
    current=call(action);current['argv'].append('--foreign');check('exact caller argv only '+action,simulate(nested([current]))['model_satisfied_call_count']==0)
    current=call(action);current['effects']=['unrelated-config-or-boot-write'];check('candidate vector alone cannot cover extra effect '+action,simulate(nested([current]))['model_satisfied_call_count']==0)
for vector in ['install-new','upgrade-all']:
    current=call('upgrade-all');current['selectors'][vector]=[] if vector=='upgrade-all' else copy.deepcopy(ns['SELECTOR_VECTORS']['upgrade-all'])
    check('full vectors not merely one row or counts '+vector,simulate(nested([current]))['model_satisfied_call_count']==0)
for key in ns['SELECTOR_VECTORS']['upgrade-all'][0]:
    current=call('upgrade-all');current['selectors']['upgrade-all'][0][key]='wrong-role-arch-build-or-target';check('complete target vector field '+key,simulate(nested([current]))['model_satisfied_call_count']==0)
current=call('upgrade-all');current['selectors']['upgrade-all']*=2;check('duplicate actual candidates not equivalent',simulate(nested([current]))['model_satisfied_call_count']==0)
check('three argv grant no unreviewed reference side effect',simulate(nested(calls+[call('unreviewed-reference-effect')]))['model_satisfied_call_count']==3)
for value in [True,'0',None,99]:check('typed raw status rejected '+repr(value),rejected(simulate,nested([dict(call('upgrade-all'),raw_status=value)])))
check('bounded nested schedule',rejected(simulate,nested(calls*5)))
publication=lambda events:dict(origin='synthetic-private-fixture',scope='closed-captured-data-and-last-receipt-contract-only',conditions=dict.fromkeys(ns['PUBLICATION_GATES'],True),events=events)
simulatepub=ns['simulate_private_publication'];events=ns['PUBLICATION_EVENTS'];r=simulatepub(publication(events))
check('complete private record receipt handoff carries no actual proof or target refresh',r['model_publication_complete'] and not r['model_controller_obligations_pending'] and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['target_refresh_authorized'])
for key in ns['PUBLICATION_GATES']:
    r=simulatepub(mutate(publication(events),['conditions',key],False));check('independent publication gate required '+key,not r['model_publication_complete'] and r['model_controller_obligations_pending'])
    check('strict publication gate type '+key,rejected(simulatepub,mutate(publication(events),['conditions',key],1)))
for index in range(len(events)+1):
    r=simulatepub(publication(events[:index]));check('separate last receipt durability and handoff required '+str(index),r['model_publication_complete']==(index==len(events)))
    for failure in ns['PUBLICATION_FAILURES']:
        r=simulatepub(publication(events[:index]+[failure]+events[index:]));check('publication failure unknown cannot replay or close '+str(index)+'/'+failure,not r['model_publication_complete'] and r['model_controller_obligations_pending'] and not r['replay_authorized'] and r['model_artifacts_preserved']==(index>=4))
for index in range(1,len(events)):check('out of order receipt event cannot skip prerequisite '+events[index],not simulatepub(publication([events[index]]))['model_publication_complete'])
check('unknown receipt durability stays null',simulatepub(publication(events[:6]+['receipt-outcome-unknown']))['model_receipt_durability'] is None)
check('bounded publication schedule',rejected(simulatepub,publication(events*4)))
check('unknown publication operation rejected',rejected(simulatepub,publication(['refresh-target-after-release'])))
a=(fixture/(base+'-transitive-effect-contract.tsv')).read_bytes();b=(fixture/(base+'-reference-source-census.tsv')).read_bytes()
check('exact complete effect and static source tables',ns['validate_tables'](a,b));check('no graph node omitted',rejected(ns['validate_tables'],b'\n'.join(a.splitlines()[:-1])+b'\n',b));check('static source table cannot promote runtime graph',rejected(ns['validate_tables'],a,b.replace(b'not-proven',b'operational-PASS')))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict325 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step325-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real325 entry reruns full exact797 predecessor acceptance',result.returncode==0 and 'exact_step324_acceptance\tPASS (797 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered797 predecessor capture',sum(x.startswith('PASS: ') for x in log)==797 and log[-1]=='Result: PASS (797 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published325 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no live forward recovery clock fence or restoration proof','actual_transitive_graph_or_selector_proven\tno' in result.stdout and 'actual_dispatch_or_publication_authorized\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('occupied outputs checked before any write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']+[x['path'] for x in design['previous_design_bindings'].values()]+[design['reference_review_binding']['path'],frozen['freeze_path']]:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed recovery or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1503 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
