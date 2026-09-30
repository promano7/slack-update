#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review.md': '6506810d6c0af0a346a33a7febe26b22fe9c676a85263d829811aad14819d7cf', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-policy.json': '1d800d8c96b7bce11aa2658113437cf691a55338f4a0dea09e5f863d776818ff', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review.tsv': '68f7778a483f6a17130fb1a63ebc6809604dc72f9ad16e87849d612273a39c94', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh': '3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review.sh': '7a577c288250aa9cce5ac0339c6ab584b5711b17f7ccf9e27d42ecaa4be39f6f'}
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
check('step and accepted commit',policy['step']==276 and policy['review_status']=='PASS' and policy['accepted_checkpoint']['commit']=='a7480d3')
check('stage action and pause flags match the reviewed contract',policy['machine_action_required'] is True and policy['controller_action_required'] is True and policy['pause_safe'] is False and policy['strong_safe_pause'] is False)
check('only single read-only observation authorized',{k for k,v in policy['authorization'].items() if v}=={'target_observation_authorized','read_only_probe_transport_authorized','read_only_probe_execution_authorized'})
o=policy['observation']
check('live observation remains pending',o['state']=='authorized-pending-single-read-only-observation' and o['fresh_boot_id'] is None and not o['machine_result_observed'])
check('one invocation and no retry',o['invocation_limit']==1 and o['no_retry_after_failure'] and o['authority_consumed_on_invocation_even_on_failure'])
check('frozen implementation unchanged',policy['frozen_implementation']==previous['frozen_implementation'])
check('preservation contract unchanged',policy['preservation']==previous['preservation'])
check('no old binding or surrounding copies required',not o['runtime_identity_reused'] and not o['surrounding_builder_or_executor_copy_required'])
probe=root/o['probe_path'];source=(root/o['baseline_probe_path']).read_text();actual=probe.read_text()
check('probe SHA matches',hashlib.sha256(probe.read_bytes()).hexdigest()==o['probe_sha256'])
check('historical probe unchanged',hashlib.sha256(source.encode()).hexdigest()==o['baseline_probe_sha256'])
for rule in o['derivation_recipe']:
    check('bounded probe derivative: '+rule['before'].splitlines()[0][:70],source.count(rule['before'])==rule['occurrences'])
    source=source.replace(rule['before'],rule['after'])
check('exact bounded derivative',source==actual)
check('probe Bash syntax',run(['bash','-n',probe]).returncode==0)
check('probe help avoids host observation',run(['bash','--',probe,'--help']).returncode==0)
check('old observation switch rejected',run(['bash','--',probe,'--observe-v4-fresh-target-and-output-absence-revalidation']).returncode==2)
check('unknown switch rejected',run(['bash','--',probe,'--bogus']).returncode==2)
check('missing switch rejected',run(['bash','--',probe]).returncode==2)
check('no historical boot expectation','EXPECTED_BOOT_ID' not in actual)
check('fresh boot observed and canonical','boot_id=$(cat /proc/sys/kernel/random/boot_id)' in actual and 'fresh boot ID is not a canonical lowercase UUID' in actual)
check('PASS follows all output-absence guards',actual.index('    verify_v4_outputs_absent\n')<actual.index("    printf '"+o['required_status_field']))
for key in o['required_yes_fields']+o['required_no_fields']:
    check('probe evidence field: '+key,("printf '"+key+r'\t') in actual)
check('measured probe self SHA',"printf 'probe_sha256" in actual and 'probe_sha=$(sha256sum -- "$probe_path"' in actual)
check('no state-mutating command',not __import__('re').search(r'(?m)^\s*(?:sudo\s+)?(?:slackpkg|installpkg|upgradepkg|removepkg|wget|curl|reboot|shutdown|poweroff|mkdir|mktemp|rm|mv|cp|chmod|chown|touch)(?:\s|$)',actual))
check('no builder/executor entry','bash -- "$builder"' not in actual and '"$builder" --build-local-source-v4' not in actual)
check('build and cleanup closed',not policy['authorization']['local_source_v4_build_authorized'] and not policy['authorization']['builder_execution_authorized'] and not policy['authorization']['evidence_cleanup_authorized'])
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
check('CHANGELOG records stage','## Phase 1 step 276 ' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
