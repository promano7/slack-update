#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast,copy,itertools,json,hashlib,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh');passes=0
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
check('exact321 design tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='2f1ba83e017f4d0e36b3d4bb2053058933d379acdf47f588716af76c363e0cbf')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0];tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step321_private_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes());policy=load('-policy.json');design=load('-design.json');history=ns['verify_history'](root,policy)
prior=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']);frozen=json.loads(history[ns['FIXTURE']+'/'+ns['REQUIREMENTS_BASE']+'-freeze.json'])
check('exact1467 predecessor bytes and original CHANGELOG suffix',len(history)==1467)
check('complete843 original320 acceptance commit push clean HEAD origin',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step320-user-acceptance.json')))
check('selected bounded handoff and descriptor contract accepted',ns['validate_design'](design,prior,frozen))
check('prepared320 remains pending in immutable source',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['user_application_commit_push_pending'] is True)
for key in design['requirements']:check('handoff requirement retained '+key,rejected(ns['validate_design'],mutate(design,['requirements',key],False),prior,frozen))
for key,value in design['proof_state'].items():check('no model promotion to actual handoff proof '+key,rejected(ns['validate_design'],mutate(design,['proof_state',key],not value if type(value) is bool else 'invented'),prior,frozen))
for key in ['receipt_binding_rule','private_model_scope','selected_handoff']:check('handoff boundary retained '+key,rejected(ns['validate_design'],mutate(design,[key],''),prior,frozen))
for key in ['seven_requirements_bindings','preserved_cross_obligations','remaining_operational_blockers','remaining_design_reviews','unresolved_design_edges']:check('unchanged requirements and separate design edge retained '+key,rejected(ns['validate_design'],mutate(design,[key],[]),prior,frozen))
for key in ['actual_pipe','actual_signature_algorithm','actual_verifier','actual_trust_root','actual_namespace','actual_FD_inventory','actual_worker_command']:check('no fabricated actual handoff binding '+key,rejected(ns['validate_design'],mutate(design,[key],'fixture-as-live'),prior,frozen))
for i,row in enumerate(design['future_proof_obligations']):check('future real handoff proof retained '+row['id'],rejected(ns['validate_design'],mutate(design,['future_proof_obligations',i,'status'],'operational-PASS'),prior,frozen))
context=dict(origin='synthetic-private-fixture',scope='offline-context-contract-not-real-cryptography',raw=ns['canonical'](ns['FIXTURE_ENVELOPE']),elapsed_seconds=1,stream_EOF=True,signature_ok=True,independent_launch_origin=True)
r=ns['evaluate_private_context'](context);check('canonical synthetic original context eligible without actual proof',r['model_original_context_eligible'] and all(v is False for k,v in r.items() if k.startswith('actual_')))
for key,new in dict(stream_EOF=False,signature_ok=False,independent_launch_origin=False,elapsed_seconds=10,raw=b'bad-json').items():check('loss or invalid original context stops '+key,not ns['evaluate_private_context'](dict(context,**{key:new}))['model_original_context_eligible'])
for bodykey in ns['FIXTURE_ENVELOPE']['body']:
    changed=mutate(ns['FIXTURE_ENVELOPE'],['body',bodykey],'fixture-foreign-binding')
    check('every authenticated original context field independently bound '+bodykey,not ns['evaluate_private_context'](dict(context,raw=ns['canonical'](changed)))['model_original_context_eligible'])
for key in ns['FIXTURE_ENVELOPE']['body']['scope_bindings']:
    changed=mutate(ns['FIXTURE_ENVELOPE'],['body','scope_bindings',key],'fixture-drift')
    check('no receipt self-rebind for '+key,not ns['evaluate_private_context'](dict(context,raw=ns['canonical'](changed)))['model_original_context_eligible'])
badbytes=[context['raw']+b' ',b'\xff',b'x'*65537,b'{"body":{},"body":{}}',b'{}',context['raw']+context['raw'],context['raw'][:-1]]
for i,raw in enumerate(badbytes):check('bounded canonical parser rejects malformed or duplicate input '+str(i),not ns['evaluate_private_context'](dict(context,raw=raw))['model_original_context_eligible'])
for key,new in dict(origin='actual-host',scope='actual-crypto',signature_ok=1,stream_EOF=None,independent_launch_origin='yes',elapsed_seconds=float('nan'),raw='text-not-bytes').items():check('typed context model rejects '+key,rejected(ns['evaluate_private_context'],dict(context,**{key:new})))
check('context cannot add real dispatch permission',rejected(ns['evaluate_private_context'],dict(context,actual_dispatch=True)))
inventory=dict(origin='synthetic-private-fixture',scope='typed-FD-contract-not-real-objects',descriptors=ns['FIXTURE_STREAMS'])
check('controlled012 roles eligible without real object proof',ns['evaluate_private_descriptors'](inventory)['model_child_FD_set_eligible'])
check('retained checked-code role conditionally preserved without blanket012 rule',ns['evaluate_private_descriptors'](dict(inventory,descriptors=inventory['descriptors']+[ns['FIXTURE_RETAINED_CODE']]))['model_child_FD_set_eligible'])
for i,row in enumerate(inventory['descriptors']):
    for key,new in dict(kind='socket',origin='host',reviewed=False,service_reachable=True,alias_known=False,lifetime='unbounded').items():check('standard FD number cannot hide wrong capability '+str(i)+' '+key,not ns['evaluate_private_descriptors'](mutate(inventory,['descriptors',i,key],new))['model_child_FD_set_eligible'])
for role in ['bootstrap-input','admission-rpc','service-ledger','trust-key','host-directory','pid-handle','namespace-handle','unknown']:
    row=dict(ns['FIXTURE_RETAINED_CODE'],role=role);check('child cannot inherit '+role,not ns['evaluate_private_descriptors'](dict(inventory,descriptors=inventory['descriptors']+[row]))['model_child_FD_set_eligible'])
for key,new in dict(kind='writable-file',origin='host',lifetime='inherited-by-any-helper',service_reachable=True,reviewed=False,alias_known=False).items():
    row=dict(ns['FIXTURE_RETAINED_CODE'],**{key:new});check('retained FD alone not safe '+key,not ns['evaluate_private_descriptors'](dict(inventory,descriptors=inventory['descriptors']+[row]))['model_child_FD_set_eligible'])
check('missing standard stream role denied',not ns['evaluate_private_descriptors'](dict(inventory,descriptors=inventory['descriptors'][:-1]))['model_child_FD_set_eligible'])
check('duplicate descriptor denied',not ns['evaluate_private_descriptors'](dict(inventory,descriptors=inventory['descriptors']+[inventory['descriptors'][0]]))['model_child_FD_set_eligible'])
for key,new in dict(fd=True,reviewed=1,alias_known=None,service_reachable='no').items():check('typed descriptor facts required '+key,rejected(ns['evaluate_private_descriptors'],mutate(inventory,['descriptors',0,key],new)))
check('unbounded descriptor inventory rejected',rejected(ns['evaluate_private_descriptors'],dict(inventory,descriptors=inventory['descriptors']*11)))
keys=ns['GATE_KEYS'];gate=dict(origin='synthetic-private-fixture',scope='handoff-and-command-contract-only',conditions=dict.fromkeys(keys,True))
for flags in itertools.product([False,True],repeat=len(keys)):
    r=ns['evaluate_private_command_gate'](dict(gate,conditions=dict(zip(keys,flags))))
    check('all independent command gates jointly required '+''.join('1' if x else '0' for x in flags),r['model_command_preparation_eligible']==all(flags) and all(v is False for k,v in r.items() if k.startswith('actual_')) and not r['retry_authorized'] and not r['recovery_authorized'])
for key in keys:check('typed gate condition required '+key,rejected(ns['evaluate_private_command_gate'],mutate(gate,['conditions',key],1)))
check('no extra gate authority field',rejected(ns['evaluate_private_command_gate'],dict(gate,actual_grant=True)))
a=(fixture/(base+'-descriptor-policy.tsv')).read_bytes();b=(fixture/(base+'-handoff-gates.tsv')).read_bytes()
check('exact descriptor and independent gate tables accepted',ns['validate_tables'](a,b));check('service reachability cannot become allowed',rejected(ns['validate_tables'],a.replace(b'denied',b'allowed'),b));check('lost gate cannot be skipped',rejected(ns['validate_tables'],a,b.replace(b'required-before-command',b'optional')))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict321 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('help states repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
for p in [tool,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax '+p.name,run(['bash','-n',p]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step321-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('real321 entry reruns full exact843 predecessor acceptance',result.returncode==0 and 'exact_step320_acceptance\tPASS (843 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('ordered full843 predecessor capture',sum(x.startswith('PASS: ') for x in log)==843 and log[-1]=='Result: PASS (843 passes, 0 failures)')
    for suffix in ns['SUFFIXES']:check('exact published321 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry grants no actual dispatch or isolation proof','actual_dispatch_authorized\tno' in result.stdout and 'actual_authentication_or_FD_containment_proven\tno' in result.stdout)
    check('occupied output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ns['SUFFIXES']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n');check('all occupied outputs checked before first write '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ctool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md',ns['FIXTURE']+'/'+ns['PRIOR']+'-design.json']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed handoff or frozen input rejects '+p.name,run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';old=p.read_bytes();saved=area/'saved';saved.write_bytes(old);p.unlink();p.symlink_to(saved);check('same-byte reference symlink rejected',run(['bash',ctool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('all1467 predecessor artifacts remain exact',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
