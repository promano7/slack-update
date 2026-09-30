#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib, json, shutil, subprocess, sys, tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
freeze_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze.md': 'dc0f2864bde33fa842f35a0af145b9f6429cb4e2a64769cfc0e113bff6ce0df5', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze.sh': 'f9ec467c4c6af937daac3c12eec1c41ebe50d36e193327447bbdedcf38c72a66', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze-policy.json': '2b5b96f9a1d14e5f606666e86933910034e4cf72d565a140608a08d26451ad43', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze.tsv': '57d2a7fc50b38090c5a03180e198ac065905b6f696389d3359e84b429cad99cf'}
passes=0
def check(label,condition):
    global passes
    if not condition: raise SystemExit('FAIL: '+label)
    passes+=1
    print('PASS: '+label)
def run(args): return subprocess.run([str(x) for x in args],capture_output=True,text=True)
for rel,digest in freeze_hashes.items():
    p=root/rel
    check('freeze artifact binding: '+p.name,p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for rel,digest in policy['accepted_step_270']['sha256_bindings'].items():
    p=root/rel
    check('accepted artifact binding: '+p.name,p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:
    check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('freeze step and accepted commit',policy['step']==271 and policy['freeze_status']=='PASS' and policy['accepted_step_270']['commit']=='179245c')
check('only executor design review is open',[key for key,value in policy['authorization'].items() if value]==['repository_only_executor_design_review_authorized'])
check('freeze has no operational or pause claim',all(policy[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('launch contract is frozen and unimplemented',policy['launch_contract']['state']=='launch-remediation-frozen-not-implemented')
frozen={k:v for k,v in policy['launch_contract'].items() if k!='state'}
reviewed={k:v for k,v in previous['remediation'].items() if k!='state'}
check('frozen contract exactly equals accepted reviewed contract',frozen==reviewed)
check('preservation contract unchanged',policy['preservation']==previous['preservation'])
check('no production or live observation evidence',policy['evidence_scope']==previous['evidence_scope'])
check('non-mutating help',run(['bash','--',helper,'--help']).returncode==0)
check('unknown option rejected',run(['bash','--',helper,'--bogus']).returncode!=0)
with tempfile.TemporaryDirectory(prefix='step271-freeze-') as tmp:
    tmp=Path(tmp)
    out=tmp/'freeze output'; out.mkdir()
    result=run(['bash','--',helper,'--output-dir',out])
    check('freeze reruns complete accepted repository acceptance',result.returncode==0 and 'accepted_step_270_revalidated\tyes' in result.stdout)
    for suffix in ['-policy.json','.tsv']:
        check('exact freeze output '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('existing freeze outputs rejected',run(['bash','--',helper,'--output-dir',out]).returncode!=0)
    link=tmp/'output-link'; link.symlink_to(out,target_is_directory=True)
    check('symlink output directory rejected',run(['bash','--',helper,'--output-dir',link]).returncode!=0)
    replica=tmp/'replica'; shutil.copytree(root,replica)
    tampered=replica/'tools/reference'/(prior+'.sh')
    tampered.write_bytes(tampered.read_bytes()+b'\n# changed accepted review\n')
    rejected=tmp/'rejected'; rejected.mkdir()
    check('changed predecessor rejected before publication',run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0 and not list(rejected.iterdir()))
    # Restore the predecessor, then ensure the frozen policy itself is bound.
    tampered.write_bytes((root/'tools/reference'/(prior+'.sh')).read_bytes())
    altered=replica/'tests/fixtures/reference/acceptance/phase-1'/(base+'-policy.json')
    altered.write_bytes(altered.read_bytes()+b'\n')
    check('changed freeze policy rejected before publication',run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0 and not list(rejected.iterdir()))
record=dict(line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines())
check('record matches freeze and continuation',record['step']=='271' and record['freeze_status']=='PASS' and record['next_stage']==policy['next_stage'])
for key,value in policy['authorization'].items():
    check('record authority: '+key,record[key]==('yes' if value else 'no'))
for rel in list(freeze_hashes)+['tests/reference/test-'+base+'-harness.sh']:
    check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
check('CHANGELOG records freeze','## Phase 1 step 271 — local-source-v4 build-launch remediation freeze' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
