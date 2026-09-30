#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib, json, os, subprocess, sys, tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
policy_path=fixture/(base+'-policy.json')
record_path=fixture/(base+'.tsv')
helper=root/'tools/reference'/(base+'.sh')
expected_review_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review.md': 'a221c53ff739ae33a4a82506c066d5f9abf1e4a126d61aac4fe3833f166e60d7', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review.sh': '0dcd9b34c74b86dbe99b089d82658634d1a53bc5145a7bb6e93c52f6a74f1c25', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review-policy.json': 'c38108622806b5a05ce2ab692354a0f88eecd43ac2416f34965e7d8776b1d7d3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review.tsv': '796b11953d881c38c2a8d782183f472060742c5a270347c6fa973c6165cfd061'}
policy=json.loads(policy_path.read_text())
passes=0
def check(label, condition):
    global passes
    if not condition:
        raise SystemExit('FAIL: '+label)
    passes+=1
    print('PASS: '+label)
def run(args):
    return subprocess.run([str(x) for x in args], capture_output=True, text=True)
for rel, digest in expected_review_hashes.items():
    p=root/rel
    check('review binding: '+p.name, p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for path, digest in policy['accepted_checkpoint']['sha256_bindings'].items():
    p=root/path
    check('accepted binding: '+p.name, p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for path in [helper, root/'tests/reference'/('test-'+base+'-harness.sh')]:
    check('Bash syntax: '+path.name, run(['bash','-n',path]).returncode==0)
check('review step and state', policy['step']==270 and policy['review_status']=='PASS' and policy['remediation']['state']=='reviewed-not-frozen-not-implemented')
check('only repository freeze is open', [k for k,v in policy['authorization'].items() if v]==['repository_only_launch_remediation_freeze_authorized'])
check('no machine action or safe-pause claim', all(policy[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('fresh revalidation; historical boot is not authority', policy['remediation']['fresh_target_revalidation_before_new_authorization'] and policy['remediation']['old_boot_id_is_historical_only'])
check('no production evidence claim', policy['evidence_scope']=='repository-only-synthetic-surrogate-no-production-builder-entry' and policy['preservation']['no_new_machine_state_claim'])
check('immutable builder and failed executor', policy['remediation']['builder_content_immutable'] and policy['preservation']['failed_step267_executor_immutable'])
check('Bash invocation reviewed exactly', policy['remediation']['future_launch_command']=='bash -- "$builder" --build-local-source-v4')
check('non-mutating helper help', run(['bash','--',helper,'--help']).returncode==0)
check('unknown helper option rejected', run(['bash','--',helper,'--bogus']).returncode!=0)
with tempfile.TemporaryDirectory(prefix='step270-review-') as tmp:
    tmp=Path(tmp)
    out=tmp/'review output'; out.mkdir()
    check('review helper succeeds', run(['bash','--',helper,'--output-dir',out]).returncode==0)
    for suffix in ['-policy.json','.tsv']:
        check('exact review output '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('existing review outputs rejected',run(['bash','--',helper,'--output-dir',out]).returncode!=0)
    link=tmp/'output-link'; link.symlink_to(out, target_is_directory=True)
    check('symlink output directory rejected',run(['bash','--',helper,'--output-dir',link]).returncode!=0)
    model_repo=tmp/'repository'; model_repo.mkdir()
    for rel in list(policy['accepted_checkpoint']['sha256_bindings'])+list(expected_review_hashes):
        dst=model_repo/rel; dst.parent.mkdir(parents=True,exist_ok=True); dst.write_bytes((root/rel).read_bytes())
    tampered=next(iter(policy['accepted_checkpoint']['sha256_bindings']))
    with (model_repo/tampered).open('a') as stream: stream.write('# changed checkpoint\n')
    rejected=tmp/'rejected output'; rejected.mkdir()
    check('helper rejects changed accepted checkpoint',run(['bash','--',model_repo/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0)
    check('rejected checkpoint publishes nothing',not list(rejected.iterdir()))
    inert=tmp/'transported builder with spaces.sh'
    inert.write_text("#!/bin/bash\nprintf '%s\\n' \"$#\" \"$1\"\n")
    inert.chmod(0o644)
    digest=hashlib.sha256(inert.read_bytes()).hexdigest()
    check('surrogate mode is 0644',(inert.stat().st_mode & 0o777)==0o644)
    try:
        direct=run([inert,'--build-local-source-v4'])
        rejected_direct=direct.returncode!=0
    except PermissionError:
        rejected_direct=True
    check('direct launch rejects non-executable surrogate',rejected_direct)
    def reviewed_launch(path, expected):
        if path.is_symlink() or not path.is_file(): return None
        if hashlib.sha256(path.read_bytes()).hexdigest()!=expected: return None
        return run(['bash','--',path,'--build-local-source-v4'])
    launched=reviewed_launch(inert,digest)
    check('reviewed Bash launch succeeds at 0644',launched is not None and launched.returncode==0)
    check('one exact argument reaches surrogate',launched.stdout=='1\n--build-local-source-v4\n')
    check('Bash launch preserves file bytes and mode',hashlib.sha256(inert.read_bytes()).hexdigest()==digest and (inert.stat().st_mode & 0o777)==0o644)
    check('missing surrogate rejected',reviewed_launch(tmp/'missing.sh',digest) is None)
    symlink=tmp/'builder-link'; symlink.symlink_to(inert)
    check('symlink surrogate rejected',reviewed_launch(symlink,digest) is None)
    inert.write_text('#!/bin/bash\nprintf unexpected-entry\n')
    check('changed surrogate rejected before entry',reviewed_launch(inert,digest) is None)
    inert.write_text('#!/bin/bash\nexit 37\n')
    failure=reviewed_launch(inert,hashlib.sha256(inert.read_bytes()).hexdigest())
    check('surrogate exit status 37 propagates',failure is not None and failure.returncode==37)
record=dict(line.split('\t') for line in record_path.read_text().splitlines())
check('record aligns with reviewed state',record['step']=='270' and record['review_status']=='PASS' and record['next_stage']==policy['next_stage'])
for key,value in policy['authorization'].items():
    check('record authorization: '+key,record[key]==('yes' if value else 'no'))
for rel in ['tools/reference/'+base+'.sh','docs/reference/'+base+'.md','tests/reference/test-'+base+'-harness.sh','tests/fixtures/reference/acceptance/phase-1/'+base+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+base+'.tsv']:
    check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
check('CHANGELOG records review', '## Phase 1 step 270 — local-source-v4 build-launch remediation review' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
