#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze.md': '8e619d1bf68e19810af1a44d58da17d7f8164e7d4479234ceb205bb3733925d8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze-policy.json': 'c186baed8313c0520fffef073b546086a805329f37f7c7d6a2955f559d4a8bd9', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze.tsv': 'fc76b15611b0cdbddd2dac1377bd6240a908d8d0770a88f529a569c0fe490842', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze.sh': 'a9a6f1e5bb67743e3f7be00d84a6bc4edfe63c7508ccbf5196fcae99998fa2b0'}
passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1
    print('PASS: '+label)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
for rel,digest in (own_hashes|policy['accepted_checkpoint']['sha256_bindings']).items():
    p=root/rel
    check('artifact binding: '+p.name,p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:
    check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('step and accepted commit',policy['step']==275 and policy['review_status']=='PASS' and policy['accepted_checkpoint']['commit']=='137889b')
check('no operational or pause claim',all(policy[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('freeze status PASS',policy['freeze_status']=='PASS')
check('only revalidation review is open',[k for k,v in policy['authorization'].items() if v]==['repository_only_fresh_target_revalidation_review_authorized'])
f=policy['frozen_implementation']
check('implementation frozen without production execution',f['state']=='implementation-frozen-not-production-executed' and not f['production_main_entered'] and not f['production_builder_entered'] and not f['live_target_observation_performed'])
check('exact accepted implementation apart from state',{k:v for k,v in f.items() if k!='state'}=={k:v for k,v in previous['implementation'].items() if k!='state'})
check('executor identity frozen',hashlib.sha256((root/f['executor_path']).read_bytes()).hexdigest()==f['executor_sha256'])
check('builder remains immutable',hashlib.sha256((root/f['builder_path']).read_bytes()).hexdigest()==f['builder_sha256'])
check('failed executor remains immutable',hashlib.sha256((root/f['baseline_path']).read_bytes()).hexdigest()==f['baseline_sha256'])
check('preservation contract unchanged',policy['preservation']==previous['preservation'])
check('fresh authorization still mandatory',f['frozen_design']['authorization_boot_id']['required'] and not f['frozen_design']['authorization_boot_id']['historical_default_allowed'])
check('single-attempt protocol retained',f['frozen_design']['single_use_enforcement']=='controller-one-attempt-authorization-protocol-no-automatic-or-manual-retry' and not f['frozen_design']['persistent_attempt_marker_added'])
check('probe transport and execution not authorized',not policy['authorization']['target_observation_authorized'] and not policy['authorization']['builder_transport_authorized'])
check('production build and reruns not authorized',not policy['authorization']['builder_execution_authorized'] and not policy['authorization']['local_source_v4_build_authorized'] and not policy['authorization']['step267_executor_rerun_authorized'] and not policy['authorization']['runtime_executor_rerun_authorized'])
check('non-mutating help',run(['bash','--',helper,'--help']).returncode==0)
check('unknown option rejected',run(['bash','--',helper,'--bogus']).returncode!=0)
with tempfile.TemporaryDirectory(prefix='repository-stage-') as tmp:
    tmp=Path(tmp);out=tmp/'review output';out.mkdir()
    result=run(['bash','--',helper,'--output-dir',out])
    check('complete accepted predecessor acceptance reruns',result.returncode==0 and 'accepted_predecessor_revalidated\tyes' in result.stdout)
    for suffix in ['-policy.json','.tsv']:
        check('exact review output '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('existing review outputs rejected',run(['bash','--',helper,'--output-dir',out]).returncode!=0)
    link=tmp/'output-link';link.symlink_to(out,target_is_directory=True)
    check('symlink output directory rejected',run(['bash','--',helper,'--output-dir',link]).returncode!=0)
    replica=tmp/'replica';shutil.copytree(root,replica)
    tampered=replica/'tools/reference'/(prior+'.sh')
    tampered.write_bytes(tampered.read_bytes()+b'\n# changed accepted predecessor\n')
    rejected=tmp/'rejected';rejected.mkdir()
    check('changed predecessor rejected before publication',run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0 and not list(rejected.iterdir()))
    tampered.write_bytes((root/'tools/reference'/(prior+'.sh')).read_bytes())
    altered=replica/'tests/fixtures/reference/acceptance/phase-1'/(base+'-policy.json')
    altered.write_bytes(altered.read_bytes()+b'\n')
    check('changed policy rejected before publication',run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0 and not list(rejected.iterdir()))
record=dict(line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines())
check('record matches review and continuation',record['step']==str(policy['step']) and record['review_status']=='PASS' and record['next_stage']==policy['next_stage'])
for key,value in policy['authorization'].items():check('record authority: '+key,record[key]==('yes' if value else 'no'))
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:
    check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
check('CHANGELOG records stage','## Phase 1 step 275 ' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
