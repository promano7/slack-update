#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-review'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-review.md': '2013acdd90d389d9456a60f88b5e96418df9425707c1e62a9dc400a24310bfe3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-review-policy.json': 'de60e477125d883754e6b4aba1d1c6698a7a3c9b0e4255495737db0addd1e499', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-review.tsv': 'c313e3fb16c7c9e4d9807e0c1abdf2ffde3b8041ff33bb59c0a97481bd5175aa', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-review.sh': '669121d485c92b6f536511eba57742f781c069b484d02dad0f440296af912ffc'}
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
check('step and accepted commit',policy['step']==272 and policy['review_status']=='PASS' and policy['accepted_checkpoint']['commit']=='cd73456')
check('no operational or pause claim',all(policy[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('only design freeze is open',[k for k,v in policy['authorization'].items() if v]==['repository_only_executor_design_freeze_authorized'])
d=policy['design']
check('design remains unimplemented',d['state']=='design-reviewed-not-frozen-not-implemented' and not d['executor_implemented'] and not d['production_builder_entered'] and not d['target_observation_performed'])
check('frozen launch contract preserved exactly',d['frozen_launch_contract']==previous['launch_contract'])
check('separate executor identity',d['future_executor_basename']!=d['guard_implementation_baseline'])
check('review helper does not implement reserved executor',not d['executor_implemented'] and d['future_executor_basename'] not in helper.read_text())
check('new strict execution switch',d['future_execution_argv'][0]=='--execute-authorized-local-source-v4-build-v2' and d['future_execution_argv'][1]=='--authorization-boot-id')
boot=d['authorization_boot_id']
check('fresh boot binding without historical default',boot['required'] and not boot['historical_default_allowed'] and boot['equals_current_boot_id_before_launch'])
check('boot identity treated as strict data',boot['strict_lowercase_uuid_format'] and boot['argument_count']==3 and boot['data_only_no_eval_or_source'] and boot['unknown_duplicate_missing_extra_arguments_rejected'])
check('preflight and exactly one launch',d['preflight_before_launch'] and d['launch_count_per_invocation']==1 and d['production_builder_arguments']==['--build-local-source-v4'])
check('success only after zero and failure status retained',d['success_publication_after_zero_builder_exit_only'] and d['builder_nonzero_exit_propagates'])
check('single-attempt mechanism described accurately',d['single_use_enforcement']=='controller-one-attempt-authorization-protocol-no-automatic-or-manual-retry' and not d['persistent_attempt_marker_added'])
check('library seam has no production entry or constant mutation',all(d['library_only_seam'].values()))
old=(root/'tools/reference'/d['guard_implementation_baseline']).read_text()
for name in d['guard_functions_preserved_exactly']:
    check('baseline verification function exists: '+name,name+'() {' in old)
check('old baseline has direct launch to replace','"$builder" --build-local-source-v4' in old)
check('old baseline launch follows output absence guard',old.index('    verify_v4_outputs_absent\n')<old.index('    "$builder" --build-local-source-v4'))
check('guard inventory covers full boundary',len(d['preflight_guard_inventory'])==17 and len(set(d['preflight_guard_inventory']))==17)
check('acceptance includes guarded rejection and nonzero publication boundary','guard-rejection-prevents-surrogate-entry' in d['implementation_acceptance_required'] and 'nonzero-exit-no-success-publication' in d['implementation_acceptance_required'])
check('preservation contract unchanged',policy['preservation']==previous['preservation'])
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
check('CHANGELOG records stage','## Phase 1 step 272 ' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
