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

root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-candidate-refinement-resume-planning-boundary-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
tool=root/'tools/reference'/(base+'.sh')
passes=0
def check(label, condition):
    global passes
    if not condition:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,TypeError,KeyError,OSError):return True
    return False
def mutated(value,path,new):
    result=copy.deepcopy(value);cursor=result
    for k in path[:-1]:cursor=cursor[k]
    cursor[path[-1]]=new;return result
def run(args):
    return subprocess.run([str(x) for x in args],capture_output=True,text=True)
check('exact329 repository-only tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='a41b09d795058e484e7de646247dd522cf73acc18f6409ee1bb9c16cfb7da8ee')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source)
tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step329_private_definitions'};exec(compile(tree,str(tool),'exec'),ns)
load=lambda suffix:json.loads((fixture/(base+suffix)).read_bytes())
policy=load('-policy.json');plan=load('-plan.json');retained=load('-retained-obligations.json')
history=ns['verify_history'](root,policy)
freeze=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-freeze.json'])
cross=json.loads(history[freeze['crossclosure_binding']['path']])
failure=json.loads(history[freeze['successor_contract_bindings']['326']['path']])
def validate(p=plan,r=retained):return ns['validate_plan'](p,r,freeze,cross,failure)
check('accepted1539 bytes with additive CHANGELOG only',len(history)==1539)
check('complete confirmed328 return including failed first push retained',ns['validate_confirmation'](load('-checkpoint-confirmation.json'),load('-step328-user-acceptance.json')))
check('new candidate route with all original proof obligations',validate())
check('prepared328 historical pause flags are unchanged',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['strong_safe_pause'] is False)
check('confirmed328 external pause remains true',load('-checkpoint-confirmation.json')['strong_safe_pause'] is True)
# Independent changes attempt to turn private planning into live authority or waive history.
for key in ['runtime_authority','preflight_authorized','refresh_authorized','namespace_authorized','target_authorized',
            'operational_publication_authorized','historical_bindings_or_grants_reusable','historical_v2_sourced_or_run',
            'reference_main_sourced_or_run','actual_transitive_graph_complete','operational_implementation_frozen',
            'operational_conformance','operational_readiness','actual_global_host_closure_asserted',
            'machine_action_required','controller_action_required','phase2_open','phase1_matrix_complete',
            'kernel_package_edge_complete','user_step329_checkpoint_confirmed','strong_safe_pause']:
    check('denies invented authority or completion '+key,rejected(validate,mutated(plan,[key],True)))
for key,new in [('step',True),('schema',True),('last_confirmed_strong_safe_pause_step',True),
                ('production_entry_closed',False),('current_live_bindings',{'boot':'historical'}),
                ('actual_host_state','absent'),('preferred_step_range',[329,340]),
                ('historical_optional329_330_rights_reused',True),('actual_implementation_selection','native-PASS'),
                ('actual_independent_oracle','selfreport'),('pause_conditions',[]),('remaining_operational_blockers',[])]:
    check('rejects unsafe planning mutation '+key,rejected(validate,mutated(plan,[key],new)))
check('rejects extra runtime grant field',rejected(validate,dict(plan,actual_grant=True)))
for i,row in enumerate(plan['route']):
    for key,new in [('entry_requires_confirmed_step',328),('runtime_authorized',True),('status','machine-authorized'),('deliverable',''),('step',True)]:
        if key=='entry_requires_confirmed_step' and i==0:new=327
        check('future route denies invalid '+str(row['step'])+' '+key,rejected(validate,mutated(plan,['route',i,key],new)))
for key in ['future_proof_register','preserved_cross_obligations','seven_requirements_bindings','effect_domains','designed_edges',
            'authority_windows','independent_conformance_plan','frozen_contract_views','remaining_operational_blockers']:
    check('cannot omit inherited '+key,rejected(validate,plan,mutated(retained,[key],[])))
for i,row in enumerate(retained['future_proof_register']):
    check('cannot promote future proof '+row['qualified_id'],rejected(validate,plan,mutated(retained,['future_proof_register',i,'operational_proven'],True)))
for key,new in [('text','truncated'),('original_display_size_bytes',True),('original_display_sha256','0'*64)]:
    check('rejects changed original receipt '+key,rejected(ns['validate_confirmation'],load('-checkpoint-confirmation.json'),mutated(load('-step328-user-acceptance.json'),[key],new)))
check('rejects fabricated confirmed commit',rejected(ns['validate_confirmation'],mutated(load('-checkpoint-confirmation.json'),['commit_prefix'],'fffffff'),load('-step328-user-acceptance.json')))
keys=['applied','complete_acceptance','exact_commit','push_successful','worktree_clean','HEAD_matches_origin']
for stage in range(330,339):
    value=dict(origin='synthetic-private-fixture',scope='repository-preparation-only',requested_step=stage,returned_step=stage-1,checkpoint=dict.fromkeys(keys,True))
    result=ns['evaluate_private_gate'](value)
    check('private eligibility only after complete predecessor '+str(stage),result['model_repository_preparation_eligible'] and not any(v for k,v in result.items() if k.startswith('actual_')))
    for key in keys:
        result=ns['evaluate_private_gate'](mutated(value,['checkpoint',key],False))
        check('incomplete predecessor denies '+str(stage)+' '+key,result['model_repository_preparation_eligible'] is False)
    check('stale predecessor denies '+str(stage),ns['evaluate_private_gate'](dict(value,returned_step=stage-2))['model_repository_preparation_eligible'] is False)
for key,new in [('origin','real-host'),('scope','runtime'),('requested_step',True),('returned_step',True),('requested_step',329),('requested_step',339)]:
    check('private gate rejects authority/type '+key+' '+str(new),rejected(ns['evaluate_private_gate'],dict(value,**{key:new})))
for key in keys:
    check('typed checkpoint rejects int '+key,rejected(ns['evaluate_private_gate'],mutated(value,['checkpoint',key],1)))
check('private gate rejects extra grant',rejected(ns['evaluate_private_gate'],dict(value,grant='old')))
for rel in ['/absolute','../escape','a/../b','a//b','a/./b','a\\b','']:
    check('unsafe relative path rejected '+repr(rel),rejected(ns['safe_relative'],rel))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:
    check('strict329 CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('329 help names repository scope','Repository-only' in run(['bash',tool,'--help']).stdout)
check('329 tool Bash syntax',run(['bash','-n',tool]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step329-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir()
    result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual329 entry reruns full exact1320 predecessor acceptance',result.returncode==0 and 'exact_step328_acceptance\tPASS (1320 passes, 0 failures)' in result.stdout)
    lines=(out/(base+'-predecessor-test.log')).read_text().splitlines()
    check('full1320 ordered predecessor capture',sum(x.startswith('PASS: ') for x in lines)==1320 and lines[-1]=='Result: PASS (1320 passes, 0 failures)')
    for suffix in ['-policy.json','-plan.json','-checkpoint-confirmation.json','-step328-user-acceptance.json','-roadmap.tsv','-retained-obligations.json']:
        check('published exact planning artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry never emits runtime authority','actual_dispatch_or_publication_authorized\tno' in result.stdout and 'operational_readiness\tno' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()}
    check('occupied output rejected without changes',run(['bash',tool,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
    missing=area/'missing'
    check('missing output not created',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    linked=area/'linked';linked.symlink_to(out,target_is_directory=True)
    check('symlink output rejected',run(['bash',tool,'--output-dir',linked]).returncode!=0)
    empty=area/'empty';empty.mkdir();copied=area/'copy';shutil.copytree(root,copied)
    copied_tool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n')
        check('changed source or planning file rejects '+p.name,run(['bash',copied_tool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
        p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';saved=area/'saved';saved.write_bytes(p.read_bytes());p.unlink();p.symlink_to(saved)
    check('same-byte frozen reference symlink rejected',run(['bash',copied_tool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('accepted history exact after tests',all(hashlib.sha256(v).hexdigest()==policy['baseline_sha256_bindings'][k] for k,v in ns['verify_history'](root,policy).items()))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
