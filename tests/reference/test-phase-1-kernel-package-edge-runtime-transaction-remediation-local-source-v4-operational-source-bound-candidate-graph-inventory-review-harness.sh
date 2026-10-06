#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast
import copy
import hashlib
import itertools
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact330 repository-only inventory tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='69ace6fb3c8ae5206fb7107cabcccf3ff0353251864f66cbc0e5051bf64cc057')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step330_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');value=load('-inventory.json');history=ns['verify_history'](root,policy)
retained=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-retained-obligations.json'])
graph=json.loads(history[retained['successor_contract_bindings']['325']['path']])
cross=json.loads(history[retained['successor_contract_bindings']['327']['path']])
def validate(v):return ns['validate_inventory'](v,history,retained,graph,cross)
check('all1548 accepted source bytes preserved',len(history)==1548)
check('confirmed329 original full271 return and push retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step329-user-acceptance.json')))
check('source-bound candidate inventory agrees with original design and text',validate(value))
check('reference full SHA agrees with frozen310 facts',value['reference_segments']['reference_sha256']=='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415')
check('all166 reference header spans preserved',value['reference_segments']['function_count']==166)
check('all30 macro domains and95 design relations preserved',len(value['candidate_nodes'])==30 and len(value['candidate_edges'])==95)
proofs={p for n in value['candidate_nodes'] for p in n['required_future_proofs']}
check('all46 qualified proofs cross-indexed without waiver',proofs=={r['qualified_id'] for r in retained['future_proof_register']})
check('both26 platform cases remain required-not-run',len(value['inherited_platform_cases'])==52 and all(r['status']=='required-not-run' and r['result'] is None for r in value['inherited_platform_cases']) and all(sum(r['platform']==p for r in value['inherited_platform_cases'])==26 for p in ['Slackware-15.0','Slackware-current']))
for key in ['actual_dynamic_graph_complete','actual_successor_entry_selected','actual_operational_implementation_frozen','operational_conformance',
            'operational_readiness','runtime_authority','historical_v2_or_reference_main_sourced_run','machine_action_required',
            'controller_action_required','user_step330_checkpoint_confirmed','strong_safe_pause']:
    check('rejects invented native proof or authority '+key,rejected(validate,mutated(value,[key],True)))
for key,new in [('schema',True),('step',True),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),
                ('source_roles',[]),('lexical_ambiguity_candidates',{}),('all_actual_selection_gaps',[]),('stop_rule',''),
                ('inherited_platform_cases',[]),('inherited_obligations_binding',{})]:
    check('rejects incomplete provenance or gap register '+key,rejected(validate,mutated(value,[key],new)))
check('rejects extra grant field',rejected(validate,dict(value,actual_grant='invented')))
for i,n in enumerate(value['candidate_nodes']):
    for key,new in [('dispatch_blocked',False),('actual_implementation_path','/usr/bin/slackpkg'),('actual_evidence','private-PASS'),('historical_source_anchors',[]),('required_future_proofs',[])]:
        check('unselected node cannot become runnable '+n['id']+' '+key,rejected(validate,mutated(value,['candidate_nodes',i,key],new)))
for i,e in enumerate(value['candidate_edges']):
    changed=copy.deepcopy(value);changed['candidate_edges'].pop(i)
    check('cannot omit designed edge '+e['source']+' -> '+e['target'],rejected(validate,changed))
check('macro relation cannot claim runtime edge proof',rejected(validate,mutated(value,['candidate_edges',0,'actual_edge_proven'],True)))
check('unknown invented edge cannot close graph',rejected(validate,dict(value,candidate_edges=value['candidate_edges']+[dict(value['candidate_edges'][0],target='unknown-helper')])))
for i,s in enumerate(value['source_roles']):
    check('historical source not operational implementation '+s['role'],rejected(validate,mutated(value,['source_roles',i,'selected_actual_implementation'],True)))
for i,g in enumerate(value['all_actual_selection_gaps']):
    check('required native selection gap retained '+g['id'],rejected(validate,mutated(value,['all_actual_selection_gaps',i,'status'],'operational-PASS')))
# Parser can inspect hostile top-level Python without executing it.
hostile=b'raise RuntimeError("MUST NOT EXECUTE")\nclass Probe:\n    def action(self):\n        return 7\n'
definitions=ns['python_definitions'](hostile)
check('Python source parsed without running top-level code',[r['name'] for r in definitions]==['Probe','Probe.action'])
check('malformed Python source rejected',rejected(ns['python_definitions'],b'def invalid(:\n'))
check('comment lexical hit does not become operational proof',ns['lexical_ambiguities'](b'# eval "$UNTRUSTED" > target\n')[0]['interpretation']=='lexical-hit-including-comments-strings-not-confirmed-effect-or-complete-hazard-list')
minimal=b'#!/bin/bash\nf() {\n  echo text\n}\nif [ "${BASH_SOURCE[0]}" = "$0" ]; then\n f\nfi\n'
check('static header segmentation leaves actual graph unproven',ns['reference_segments'](minimal)['actual_transitive_graph_complete'] is False)
check('ambiguous duplicate static header rejected',rejected(ns['reference_segments'],minimal.replace(b'if [',b'f() {\n}\nif [')))
check('missing entry-tail boundary rejected',rejected(ns['reference_segments'],b'f() {\n}\n'))
keys=['known_macro_node','actual_implementation_selected','actual_dependencies_closed','actual_native_proofs_complete','both_platforms_independently_proven']
for flags in itertools.product([False,True],repeat=5):
    result=ns['inventory_repository_status'](dict(origin='synthetic-private-fixture',**dict(zip(keys,flags))))
    check('private summary never operational dispatch '+str(flags),result['repository_inventory_row_eligible']==flags[0] and all(v is False for k,v in result.items() if k.startswith('actual_')))
example=dict(origin='synthetic-private-fixture',**dict.fromkeys(keys,True))
check('native-looking private row cannot use actual-host origin',rejected(ns['inventory_repository_status'],dict(example,origin='actual-host')))
for key in keys:check('private summary field requires bool '+key,rejected(ns['inventory_repository_status'],dict(example,**{key:1})))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:
    check('strict330 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('330 help names repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('330 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step330-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir()
    result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual330 entry reruns exact271 predecessor with full historical coverage',result.returncode==0 and 'exact_step329_acceptance\tPASS (271 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines()
    check('full ordered271 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==271 and lines[-1]=='Result: PASS (271 passes, 0 failures)')
    for suffix in ['-policy.json','-inventory.json','-checkpoint-confirmation.json','-step329-user-acceptance.json','-candidate-nodes.tsv','-candidate-edges.tsv']:
        check('published exact330 artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('static inventory leaves graph and authority blocked','actual_dynamic_graph_complete\tno' in result.stdout and 'actual_dispatch_or_publication_authorized\tno' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()}
    check('occupied output rejected without changes',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'linked';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',tool,'--output-dir',link]).returncode!=0)
    empty=area/'empty';empty.mkdir();copied=area/'copy';shutil.copytree(root,copied);copiedtool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+list(ns['SOURCE_ROLES'])+['CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n')
        check('changed330 or source input denied '+p.name,run(['bash',copiedtool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
        p.write_bytes(old)
    p=copied/ns['PRIVATE'];saved=area/'samebytes';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved)
    check('same-byte private source symlink rejected',run(['bash',copiedtool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('accepted1548 history unchanged after validation',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
