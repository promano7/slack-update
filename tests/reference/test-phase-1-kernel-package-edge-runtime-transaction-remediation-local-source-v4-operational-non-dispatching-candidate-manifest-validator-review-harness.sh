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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(base+'.sh')
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
check('exact333 non-dispatching manifest tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='c8801e5d6323dbdf9be78597fea9ac2a7e752d871c8fcd8ccf3bd7bcd7aeff25')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source);tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step333_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda s:json.loads((fixture/(base+s)).read_bytes())
policy=load('-policy.json');manifest=ns['parse_candidate_manifest']((fixture/(base+'-manifest.json')).read_bytes());history=ns['verify_history'](root,policy)
catalog=json.loads(history[ns['CATALOG_PATH']]);phase=catalog['inherited_phase_contract'];inventory=json.loads(history[phase['inherited_inventory_binding']['path']]);retained=json.loads(history[inventory['inherited_obligations_binding']['path']])
def validate(v):return ns['validate_candidate_manifest'](v,history,catalog,inventory,retained)
report=validate(manifest)
check('1575 accepted bytes and additive CHANGELOG only',len(history)==1575)
check('complete332 receipt with1429 ordered passes retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step332-user-acceptance.json')))
check('manifest accepted as declaration while every native completion remains false',report['candidate_declaration_valid'] and report['native_selection_or_evidence_complete'] is False and not any(v for k,v in report.items() if k.startswith('actual_')))
check('manifest report exactly matches bound result',report==load('-validation-report.json'))
check('30 domains 95 macro relations 27 phases 26 interfaces 35 types retained',[report[k] for k in ['component_domains','macro_design_relations','phase_boundaries','nominal_interfaces','nominal_types']]==[30,95,27,26,35])
check('all46 proofs 52 independent cases 16 gaps still pending',[report[k] for k in ['required_not_proven_proofs','required_not_run_cases','unresolved_native_gap_categories']]==[46,52,16])
check('all eight contract views and13 stage source statements unchanged',manifest['exact_phase_contract']==phase and len(phase['selected_source_views'])==8 and len(phase['frozen_worker_stages'])==13)
check('all13 inherited data bindings exact source bytes',len(manifest['artifact_bindings'])==13 and all(hashlib.sha256(history[r['path']]).hexdigest()==r['sha256'] for r in manifest['artifact_bindings']))
check('four blocked domains retain no interface',sum(r['interface_binding'] is None for r in manifest['components'])==4)
check('all85 nominal phase uses declare no authority',sum(len(r['nominal_interface_uses']) for r in manifest['phases'])==85 and all(not u['dispatch_authorized'] for r in manifest['phases'] for u in r['nominal_interface_uses']))
parse=ns['parse_candidate_manifest'];bad_json=[b'',b'[]',b'null',b'false',b'1',b'{',b'\xff',b'{"a":1,"a":2}',b'{"nested":{"a":1,"a":2}}',b'{"a":NaN}',b'{"a":Infinity}',b'{"a":1.0}',b'{"a":9223372036854775808}',b'{"a":-9223372036854775809}',b' '*1048577,json.dumps({'a':'x'*65537}).encode(),b'{"a":'+b'['*33+b'0'+b']'*33+b'}',json.dumps({'a':[0]*50001}).encode()]
for i,raw in enumerate(bad_json):check('bounded closed JSON rejects ambiguous or excessive fixture '+str(i),rejected(parse,raw))
check('parser requires bytes not implicit text',rejected(parse,'{}'))
check('parser accepts boundary integer values and Unicode data',parse('{"a":9223372036854775807,"b":-9223372036854775808,"c":"α"}'.encode())['c']=='α')
for key in ['actual_dynamic_graph_complete','actual_native_primitives_selected','actual_implementation_frozen','operational_conformance','operational_readiness','runtime_authority','actual_global_host_closure_asserted','historical_v2_or_reference_main_sourced_run','machine_action_required','controller_action_required','user_step333_checkpoint_confirmed','strong_safe_pause']:
 check('manifest cannot promote actual selection proof or authority '+key,rejected(validate,mutated(manifest,[key],True)))
for key,new in [('schema',True),('step',True),('actual_entry_path','/usr/bin/native'),('actual_dispatcher','execute'),('actual_live_bindings',{'boot':'old'}),('actual_host_state','absent'),('exact_phase_contract',{}),('authority_windows',[]),('seven_requirements_bindings',{}),('preserved_cross_obligations',[]),('actual_selection_gaps',[])]:
 check('manifest cannot omit source rights or native blocker '+key,rejected(validate,mutated(manifest,[key],new)))
bad=dict(manifest,new_runtime_flag=True);check('closed manifest rejects extra runtime instruction',rejected(validate,bad))
for i,row in enumerate(manifest['artifact_bindings']):
 for key,new in [('sha256','0'*64),('path','../outside'),('path','/etc/shadow')]:
  check('bound data never drifts or resolves outside source '+str(i)+' '+key+' '+str(new)[:15],rejected(validate,mutated(manifest,['artifact_bindings',i,key],new)))
for i,row in enumerate(manifest['components']):
 ident=row['id']
 for key,new in [('dispatch_blocked',False),('actual_implementation_path','/usr/bin/native'),('actual_evidence',{'PASS':True}),('required_future_proofs',['missing/proof']),('phase_ids',['missing-phase'])]:
  check('component reference and native blocker retained '+ident+' '+key,rejected(validate,mutated(manifest,['components',i,key],new)))
 bad=copy.deepcopy(manifest);bad['components'].pop(i);check('no component omission '+ident,rejected(validate,bad))
 if row['interface_binding'] is not None:
  for key,new in [('id','unknown-interface'),('canonical_sha256','0'*64)]:check('component cannot cross or alter interface '+ident+' '+key,rejected(validate,mutated(manifest,['components',i,'interface_binding',key],new)))
 else:
  check('blocked domain cannot acquire interface '+ident,rejected(validate,mutated(manifest,['components',i,'interface_binding'],copy.deepcopy(manifest['components'][0]['interface_binding']))))
bad=copy.deepcopy(manifest);bad['components'].append(copy.deepcopy(bad['components'][0]));check('duplicate domain rejected',rejected(validate,bad))
for i,edge in enumerate(manifest['macro_design_relations']):
 for key,new in [('source','missing-domain'),('target','missing-domain'),('actual_edge_proven',True),('dispatch_authorized',True)]:
  check('macro design relation is resolved and inert '+str(i)+' '+key,rejected(validate,mutated(manifest,['macro_design_relations',i,key],new)))
for i,row in enumerate(manifest['phases']):
 bad=copy.deepcopy(manifest);bad['phases'].pop(i);check('no phase omission '+row['declared_boundary']['id'],rejected(validate,bad))
 for j,use in enumerate(row['nominal_interface_uses']):
  for key,new in [('interface_id','reference-boot-mutation'),('caller_actor','unreviewed-actor'),('rights_window','new-unused-grant'),('input_types',['missing-type']),('dispatch_authorized',True)]:
   check('phase interface preserves actor types and rights '+str(i)+'/'+str(j)+' '+key,rejected(validate,mutated(manifest,['phases',i,'nominal_interface_uses',j,key],new)))
for i in range(len(manifest['phases'])-1):
 bad=copy.deepcopy(manifest);bad['phases'][i],bad['phases'][i+1]=bad['phases'][i+1],bad['phases'][i]
 check('phase order never changed '+str(i),rejected(validate,bad))
for i,row in enumerate(manifest['qualified_proof_register']):
 check('proof evidence remains native-pending '+row['qualified_id'],rejected(validate,mutated(manifest,['qualified_proof_register',i,'actual_evidence'],{'PASS':True})))
 check('proof cannot be omitted '+row['qualified_id'],rejected(validate,mutated(manifest,['qualified_proof_register',i,'source_proof','status'],'proven')))
for i,row in enumerate(manifest['independent_platform_cases']):
 check('native case never inferred from private tests '+row['platform']+'/'+row['case_id'],rejected(validate,mutated(manifest,['independent_platform_cases',i,'status'],'PASS')))
for i,row in enumerate(manifest['type_bindings']):
 check('nominal type cannot gain native ABI '+row['name'],rejected(validate,mutated(manifest,['type_bindings',i,'actual_native_ABI'],'function-pointer')))
check('historical readonly7 not reclassified',rejected(validate,mutated(manifest,['exact_phase_contract','frozen_worker_stages',7,'effect'],'owned-files')))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:check('strict333 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('333 help repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('333 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step333-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir();result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual333 entry reruns full1429 predecessor and complete historical coverage',result.returncode==0 and 'exact_step332_acceptance\tPASS (1429 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines();check('full ordered1429 predecessor capture',sum(x.startswith('PASS: ') for x in lines)==1429 and lines[-1]=='Result: PASS (1429 passes, 0 failures)')
    for suffix in ['-policy.json','-manifest.json','-validation-report.json','-checkpoint-confirmation.json','-step332-user-acceptance.json','-artifact-bindings.tsv']:
        check('exact333 published artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('manifest validity grants no native dispatch or proof','actual_native_dispatch_or_proof_authorized\tno' in result.stdout and 'required_proofs_and_independent_cases\t46-unproven/52-unrun' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()};check('occupied output denied without change',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing';check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    link=area/'link';link.symlink_to(out,target_is_directory=True);check('symlink output denied',run(['bash',tool,'--output-dir',link]).returncode!=0)
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir();ct=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+[ns['CATALOG_PATH'],catalog['phase_map_binding']['path'],'tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n');check('changed333 source denied '+p.name,run(['bash',ct,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()));p.write_bytes(old)
check('all1575 history bytes intact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
