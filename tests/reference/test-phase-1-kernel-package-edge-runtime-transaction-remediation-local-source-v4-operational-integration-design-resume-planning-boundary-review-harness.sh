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
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review'
fixture = root/'tests/fixtures/reference/acceptance/phase-1'
tool = root/'tools/reference'/(base+'.sh')
passes = 0
def check(label,condition):
    global passes
    if not condition: raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try: fn(*args)
    except (ValueError,TypeError,KeyError,OSError): return True
    return False
def mutate(value,path,new):
    result=copy.deepcopy(value);cursor=result
    for key in path[:-1]:cursor=cursor[key]
    cursor[path[-1]]=new;return result
def run(args):
    return subprocess.run([str(x) for x in args],capture_output=True,text=True)

check('exact319 planning tool SHA',hashlib.sha256(tool.read_bytes()).hexdigest()=='87aa6e10bb78656bd9ae785bd984c5563b2ef56b2ac2fb5b34b896f1b29f3d05')
source=tool.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
tree=ast.parse(source)
tree.body=[n for n in tree.body if not isinstance(n,ast.If)]
ns={'__name__':'step319_test_definitions'};exec(compile(tree,str(tool),'exec'),ns)
policy=json.loads((fixture/(base+'-policy.json')).read_bytes())
plan=json.loads((fixture/(base+'-plan.json')).read_bytes())
confirmed=json.loads((fixture/(base+'-checkpoint-confirmation.json')).read_bytes())
receipt=json.loads((fixture/(base+'-step318-user-acceptance.json')).read_bytes())
history=ns['verify_history'](root,policy)
frozen=json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-freeze.json'])
check('exact1449 accepted files and additive CHANGELOG suffix',len(history)==1449)
check('complete318 external confirmation with717 return and clean HEAD origin',ns['validate_confirmation'](confirmed,receipt))
check('new ten-step successor integration design plan accepted',ns['validate_plan'](plan,frozen))
check('historical318 prepared pause flags remain false and immutable',json.loads(history[ns['FIXTURE']+'/'+ns['PRIOR']+'-policy.json'])['strong_safe_pause'] is False and confirmed['strong_safe_pause'] is True)
for key in ['schema','step','last_confirmed_strong_safe_pause_step']:
    check('integer planning field rejects bool '+key,rejected(ns['validate_plan'],mutate(plan,[key],True),frozen))
for key,value in plan.items():
    if type(value) is bool or value is None:
        check('boundary overclaim rejects '+key,rejected(ns['validate_plan'],mutate(plan,[key],not value if type(value) is bool else 'invented-live-value'),frozen))
for key,value in dict(scope='live-runtime',preferred_step_range=[319,330],optional_step_range=[],runtime_rights='open',later_stage_rights='open',current_stage_rights=['runtime'],scope_selection='reuse-old319-reserve',pause_conditions=[],seven_requirements_bindings=[],remaining_operational_blockers=[],integration_obligations=[],decision_boundaries={},stop_rule='',successor_rule='',compatibility_scope=['Slackware-current'],compatibility_claim='both-hosts-PASS').items():
    check('invalid route or weakened proof rejects '+key,rejected(ns['validate_plan'],mutate(plan,[key],value),frozen))
check('extra planning authority field rejects',rejected(ns['validate_plan'],dict(plan,actual_grant=True),frozen))
for i,row in enumerate(plan['route']):
    for key,new in dict(step=318,stage='unreviewed',entry_requires_confirmed_step=0,scope='runtime',runtime_authorized=True,conditional_pause_candidate=not row['conditional_pause_candidate'],status='authorized',deliverable='').items():
        check('stage boundary rejects '+str(row['step'])+' '+key,rejected(ns['validate_plan'],mutate(plan,['route',i,key],new),frozen))
for i,row in enumerate(plan['integration_obligations']):
    for key,new in dict(required_evidence='',status='operational-PASS',operational_proof_complete=True,design_review_steps=[]).items():
        check('cross proof preserved '+row['id']+' '+key,rejected(ns['validate_plan'],mutate(plan,['integration_obligations',i,key],new),frozen))
for i,row in enumerate(plan['seven_requirements_bindings']):
    check('exact frozen requirement SHA preserved '+str(row['step']),rejected(ns['validate_plan'],mutate(plan,['seven_requirements_bindings',i,'review_sha256'],'0'*64),frozen))
for key,value in plan['decision_boundaries'].items():
    check('unselected design cannot become resolved '+key,rejected(ns['validate_plan'],mutate(plan,['decision_boundaries',key],'operational-PASS'),frozen))
roadmap=(fixture/(base+'-roadmap.tsv')).read_bytes();obligations=(fixture/(base+'-integration-obligations.tsv')).read_bytes()
check('exact closed roadmap and ten obligation coverage TSV',ns['validate_tables'](roadmap,obligations))
for a,b,label in [(roadmap+b'330\tunreviewed\n',obligations,'extra reserve'),(roadmap.replace(b'\tno\t',b'\tyes\t'),obligations,'runtime right'),(roadmap,obligations.replace(b'required-not-proven',b'operational-PASS'),'overclaim'),(roadmap,b'\n'.join(obligations.splitlines()[:-1])+b'\n','lost proof')]:
    check('strict TSV rejects '+label,rejected(ns['validate_tables'],a,b))
keys=['applied','complete_acceptance','commit_pushed','worktree_clean','HEAD_matches_origin']
for step in range(320,329):
    value=dict(origin='synthetic-private-fixture',scope='repository-stage-preparation-only',requested_step=step,returned_step=step-1,checkpoint=dict.fromkeys(keys,True))
    for flags in itertools.product([False,True],repeat=5):
        r=ns['evaluate_private_stage_gate'](dict(value,checkpoint=dict(zip(keys,flags))))
        check('complete predecessor return required '+str(step)+' '+str(flags),r['model_repository_preparation_eligible']==all(flags) and all(v is False for k,v in r.items() if k.startswith('actual_')))
    for old in [318,step,step+1]:
        if old != step-1:
            check('no stale or skipped predecessor '+str(step)+'/'+str(old),not ns['evaluate_private_stage_gate'](dict(value,returned_step=old))['model_repository_preparation_eligible'])
for key,new in dict(origin='actual-host',scope='operational-authorization',requested_step=True,returned_step=True,checkpoint={}).items():
    check('private stage gate rejects scope or type '+key,rejected(ns['evaluate_private_stage_gate'],dict(value,**{key:new})))
for step in [319,329,330]:
    check('private gate denies current or optional stage '+str(step),rejected(ns['evaluate_private_stage_gate'],dict(value,requested_step=step)))
for key in keys:
    check('checkpoint field requires bool '+key,rejected(ns['evaluate_private_stage_gate'],mutate(value,['checkpoint',key],1)))
check('gate rejects invented operational grant field',rejected(ns['evaluate_private_stage_gate'],dict(value,actual_grant=True)))
for argv in [[],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:
    check('strict planning CLI '+repr(argv),run(['bash',tool,*argv]).returncode==2)
check('planning help names repository scope', 'Repository-only' in run(['bash',tool,'--help']).stdout)
check('planning tool Bash syntax',run(['bash','-n',tool]).returncode==0)
check('planning harness Bash syntax',run(['bash','-n',root/'tests/reference'/('test-'+base+'-harness.sh')]).returncode==0)
with tempfile.TemporaryDirectory(prefix='step319-harness-') as directory:
    area=Path(directory);out=area/'out';out.mkdir()
    result=run(['bash',tool,'--output-dir',out])
    if result.returncode:sys.stderr.write(result.stdout+result.stderr)
    check('actual319 entry reruns complete exact717 predecessor suite',result.returncode==0 and 'exact_step318_acceptance\tPASS (717 passes, 0 failures)' in result.stdout)
    log=(out/(base+'-predecessor-test.log')).read_text().splitlines()
    check('full predecessor ordered717 capture',sum(x.startswith('PASS: ') for x in log)==717 and log[-1]=='Result: PASS (717 passes, 0 failures)')
    for suffix in ['-policy.json', '-plan.json', '-checkpoint-confirmation.json', '-step318-user-acceptance.json', '-roadmap.tsv', '-integration-obligations.tsv']:
        check('exact published planning artifact '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('entry cannot grant runtime or actual pause','actual_dispatch_authorized\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout)
    check('occupied planning output rejected',run(['bash',tool,'--output-dir',out]).returncode!=0)
    for suffix in ['-policy.json', '-plan.json', '-checkpoint-confirmation.json', '-step318-user-acceptance.json', '-roadmap.tsv', '-integration-obligations.tsv']+['-predecessor-test.log']:
        blocked=area/('blocked-'+str(passes));blocked.mkdir();p=blocked/(base+suffix);p.write_bytes(b'keep\n')
        check('no partial output before occupied check '+suffix,run(['bash',tool,'--output-dir',blocked]).returncode!=0 and list(blocked.iterdir())==[p] and p.read_bytes()==b'keep\n')
    missing=area/'missing'
    check('missing output rejected without create',run(['bash',tool,'--output-dir',missing]).returncode!=0 and not missing.exists())
    linked=area/'linked';linked.symlink_to(out,target_is_directory=True)
    check('symlink output rejected',run(['bash',tool,'--output-dir',linked]).returncode!=0)
    # Drift checks invoke the entry point and must fail before predecessor execution or output.
    import shutil
    copied=area/'copy';shutil.copytree(root,copied);empty=area/'empty';empty.mkdir()
    copied_tool=copied/'tools/reference'/(base+'.sh')
    for rel in list(ns['OWN_HASHES'])+['tools/reference/slack-update-reference.sh','CHANGELOG.md']:
        p=copied/rel;old=p.read_bytes();p.write_bytes(old+b'\n')
        check('changed accepted or planning bytes reject '+p.name,run(['bash',copied_tool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
        p.write_bytes(old)
    p=copied/'tools/reference/slack-update-reference.sh';old=p.read_bytes();saved=area/'same-bytes';saved.write_bytes(old);p.unlink();p.symlink_to(saved)
    check('same-byte reference symlink rejects',run(['bash',copied_tool,'--output-dir',empty]).returncode!=0 and not list(empty.iterdir()))
check('accepted1449 history remains exact after all tests',ns['verify_history'](root,policy)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
