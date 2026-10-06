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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact332 nominal interface tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='e7627b51972776921f5bbe5d2f5aceaaefed402d46bb7dcf3b0a6b20a86c618d')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step332_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');catalog=load('-interfaces.json');types=load('-types.json');history=ns['verify_history'](root,policy)
phase=json.loads(history[ns['PHASE_PATH']])
def validate(c):return ns['validate_interface_catalog'](c,history,phase)
check('1566 accepted bytes and additive CHANGELOG only',len(history)==1566)
check('complete331 receipt with399 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step331-user-acceptance.json')))
check('26 typed interfaces all30 domains and exact331 source closure',validate(catalog))
check('closed nominal type registry no native ABI',types['types']==catalog['type_definitions'] and types['actual_abi'] is None and not types['actual_authority'])
check('all27 original phase boundaries and13 stages copied exactly',catalog['inherited_phase_contract']==phase and len(phase['entry_trace'])==27 and len(phase['frozen_worker_stages'])==13)
all_rows=catalog['interfaces']+catalog['blocked_domains']
check('all46 qualified native proofs remain required',{p for r in all_rows for p in r['required_future_proofs']}=={p for r in phase['node_phase_map'] for p in r['required_future_proofs']} and len({p for r in all_rows for p in r['required_future_proofs']})==46)
check('all52 independent native cases remain unrun',catalog['inherited_counts']['actual_platform_cases_run']==0 and len(catalog['inherited_platform_cases'])==52)
check('all16 actual selection and refinement gaps retained',len(catalog['all_actual_selection_gaps'])==16 and catalog['all_actual_selection_gaps']==phase['all_actual_selection_gaps'])
check('four forbidden or unknown domains never gain interface',len(catalog['blocked_domains'])==4 and all(r['interface'] is None and r['dispatch_blocked'] for r in catalog['blocked_domains']))
for k in ['actual_native_primitives_selected','actual_native_interface_abi_selected','actual_graph_complete','actual_implementation_frozen','operational_conformance','operational_readiness','runtime_authority','machine_action_required','controller_action_required','historical_v2_or_reference_main_sourced_run','strong_safe_pause','user_step332_checkpoint_confirmed']:
 check('catalog cannot promote actual proof authority '+k,rejected(validate,mutated(catalog,[k],True)))
for k,new in [('schema',True),('step',True),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),('inherited_phase_contract',{}),('phase_map_binding',{}),('blocked_domains',[]),('all_actual_selection_gaps',[]),('inherited_platform_cases',[]),('type_definitions',[])]:
 check('catalog cannot waive source or blocker '+k,rejected(validate,mutated(catalog,[k],new)))
for i,row in enumerate(catalog['interfaces']):
 ident=row['id']
 for k,new in [('dispatch_blocked',False),('required_future_proofs',[]),('actual_component_path','/usr/bin/native'),('actual_lifetime','proved'),('actual_conformance_evidence',{'PASS':True})]:
  check('interface retains unresolved native obligations '+ident+' '+k,rejected(validate,mutated(catalog,['interfaces',i,k],new)))
 for pi,p in enumerate(row['allowed_phase_contexts']):
  for status in ['known-complete','known-failed','unknown','not-attempted']:
   q,r=ns['private_exchange'](row,pi,status);answer=ns['validate_private_exchange'](q,r,catalog)
   check('typed private exchange never native proof '+ident+' '+p['id']+' '+status,answer['model_shape_valid'] and answer['model_pending_native_obligations'] and not any(v for k,v in answer.items() if k.startswith('actual_')) and not answer['model_retry_or_automatic_recovery'] and answer['model_nominal_outputs_present']==(status=='known-complete'))
 q,r=ns['private_exchange'](row)
 for k,new in [('phase','unreviewed-phase'),('provider_role','new-provider'),('caller_actor','new-actor'),('rights_window','fresh-unused-grant'),('version',True),('origin','actual-host'),('scope','native-request'),('inputs',{})]:
  check('private request rejects context or capability crossing '+ident+' '+k,rejected(ns['validate_private_exchange'],dict(q,**{k:new}),r,catalog))
 for status in ['known-failed','unknown','not-attempted']:
  check('noncomplete result cannot carry success payload '+ident+' '+status,rejected(ns['validate_private_exchange'],q,dict(r,status=status),catalog))
 for k,new in [('actual_evidence',{'native':'PASS'}),('actual_authority',True),('schema',True),('status','retry-allowed'),('interface','unreviewed-interface'),('origin','actual-host'),('outputs',{})]:
  check('private result rejects proof or outcome promotion '+ident+' '+k,rejected(ns['validate_private_exchange'],q,dict(r,**{k:new}),catalog))
 for name in row['input_types']:
  bad=copy.deepcopy(q);bad['inputs'].pop(name)
  check('every declared input is required '+ident+' '+name,rejected(ns['validate_private_exchange'],bad,r,catalog))
for row in catalog['blocked_domains']:
 q,r=ns['private_exchange'](catalog['interfaces'][0]);q['interface']=row['id'];r['interface']=row['id']
 check('forbidden domain cannot become private interface '+row['id'],rejected(ns['validate_private_exchange'],q,r,catalog))
for t in types['types']:
 name=t['name'];v=ns['symbolic_value'](name)
 check('nominal value shape accepted without native authority '+name,ns['validate_symbolic_value'](v,name) and not v['authority'])
 for k,new in [('type','wrong-type'),('scope','native-handle'),('attempt','new-attempt-B'),('boot','new-boot-B'),('authority',True),('symbol','/proc/self/fd/3'),('symbol','x'*65),('symbol',3)]:
  check('nominal value rejects rebind path or authority '+name+' '+k+' '+str(new)[:15],rejected(ns['validate_symbolic_value'],dict(v,**{k:new}),name))
 bad=dict(v);bad['native_fd']=3
 check('nominal value rejects undeclared FD '+name,rejected(ns['validate_symbolic_value'],bad,name))
q,r=ns['private_exchange'](catalog['interfaces'][0]);q['inputs']['unexpected']=ns['symbolic_value']('issuer-policy-view')
check('extra input cannot add a capability',rejected(ns['validate_private_exchange'],q,r,catalog))
q,r=ns['private_exchange'](catalog['interfaces'][0]);r['outputs']['unexpected']=ns['symbolic_value']('authenticated-policy-view')
check('extra output cannot mint a capability',rejected(ns['validate_private_exchange'],q,r,catalog))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict332 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('332 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('332 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step332-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual332 entry reruns full399 predecessor and complete historical coverage',result.returncode==0 and 'exact_step331_acceptance\tPASS (399 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered399 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==399 and lines[-1]=='Result: PASS (399 passes, 0 failures)')
    for suffix in ['-policy.json','-interfaces.json','-types.json','-checkpoint-confirmation.json','-step331-user-acceptance.json','-interface-proof-map.tsv']:
        check('exact332 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('nominal interfaces grant no native ABI dispatch or proof','actual_native_ABI_or_dispatch_authorized\tno' in result.stdout and 'actual_native_proof_or_closure\tno' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+[ns['PHASE_PATH'],'tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed332 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1566 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
