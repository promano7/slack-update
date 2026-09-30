#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review.md': '415a69338e084c909e7aff98581e457cb39287bfa341952a58ca7ba656224379', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-policy.json': '0d942fe037278c778a0c72597b1ca4ecb9da07b166d4a95ffe4fe2e3f9d934ed', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review.tsv': 'c92f42b7ff6557ec22d0555a32bb5d8d6d5f8444fb8ea27c6ab3c1559d4bc6c7', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv': '2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review.sh': 'e75cd76c1dc0865541e4b8d2653afae154e3c1d6edcc150652cb335dc6e92749'}
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
check('step and accepted commit',policy['step']==277 and policy['review_status']=='PASS' and policy['accepted_checkpoint']['commit']=='904d44a')
check('stage action and pause flags match the reviewed contract',policy['machine_action_required'] is False and policy['controller_action_required'] is False and policy['pause_safe'] is False and policy['strong_safe_pause'] is False)
check('only authorization freeze is open',[k for k,v in policy['authorization'].items() if v]==['repository_only_build_authorization_freeze_authorized'])
o=policy['accepted_observation'];f=policy['future_authorization']
check('probe authority consumed and rerun closed',o['state']=='fresh-read-only-observation-accepted-frozen-authority-consumed' and o['probe_authority_consumed'] and not o['probe_rerun_authorized'])
check('frozen implementation unchanged',policy['frozen_implementation']==previous['frozen_implementation'])
check('preservation contract unchanged',policy['preservation']==previous['preservation'])
path=root/o['observation_path']
check('normalized observation SHA matches',hashlib.sha256(path.read_bytes()).hexdigest()==o['normalized_observation_sha256'])
rows=[line.split('\t') for line in path.read_text().splitlines()]
check('strict two-column nonempty TSV',all(len(row)==2 and all(row) for row in rows))
observed=dict(rows)
check('observation has unique fields',len(rows)==len(observed)==o['field_count'])
check('frozen values match normalized observation',observed==o['values'])
import re
probe=(root/previous['observation']['probe_path']).read_text()
emitted=set(re.findall(r"(?m)^\s*printf '([A-Za-z_0-9]+)\\t",probe[probe.index("\nmain() {"):]))
check('all emitted observation fields are present exactly',set(observed)==emitted)
check('probe status PASS',observed[previous['observation']['required_status_field']]=='PASS')
check('probe self SHA is authorized identity',observed['probe_sha256']==previous['observation']['probe_sha256'])
check('fresh boot is canonical and bound',re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',observed['fresh_boot_id']) is not None and f['authorization_boot_id']==observed['fresh_boot_id']=='79a19518-0d0a-4c57-ac1f-679a39edefbd')
mapping={'hostname_fqdn':'EXPECTED_FQDN','uname_machine':'EXPECTED_UNAME_MACHINE','uname_release':'EXPECTED_UNAME_RELEASE','slackware_version':'EXPECTED_SLACKWARE_VERSION','package_database_manifest_sha256':'EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256','header_package_record':'EXPECTED_HEADER_RECORD','kernel_generic_record':'EXPECTED_KERNEL_GENERIC_RECORD','slackpkg_conf_sha256':'EXPECTED_SLACKPKG_CONF_SHA256','slackpkg_mirrors_sha256':'EXPECTED_SLACKPKG_MIRRORS_SHA256','staged_target_sha256':'EXPECTED_TARGET_SHA256','local_source_v3_tree_manifest_sha256':'EXPECTED_V3_TREE_MANIFEST_SHA256','failed_v2_pkglist_sha256':'EXPECTED_EMPTY_SHA256','frozen_v4_builder_sha256':'EXPECTED_V4_BUILDER_SHA256'}
for key,constant in mapping.items():
    expected=re.search(r"(?m)^readonly "+constant+r"='([^']+)'$",probe).group(1)
    check('observed frozen baseline: '+key,observed[key]==expected)
for key in previous['observation']['required_yes_fields']:check('verified observed boundary: '+key,observed[key]=='yes')
for key in previous['observation']['required_no_fields']:check('no performed action: '+key,observed[key]=='no')
check('failed-v2 pkglist remains zero bytes',observed['failed_v2_pkglist_size_bytes']=='0')
check('transcription provenance is explicit','no-original-output-byte-identity-claim' in o['normalization'] and o['frozen_builder_sha_is_repository_context_not_observed_transport'])
check('future contract reviewed without authority',f['state']=='single-build-contract-reviewed-not-authorized' and not f['new_authority_granted'])
check('future exact executor and builder hashes',f['executor_sha256']==policy['frozen_implementation']['executor_sha256'] and f['builder_sha256']==policy['frozen_implementation']['builder_sha256'])
check('exact new execution arguments bound to fresh observation',f['execution_argv']==['--execute-authorized-local-source-v4-build-v2','--authorization-boot-id',observed['fresh_boot_id']])
check('one attempt with immediate preflight and no retry',f['attempt_limit']==1 and f['full_preflight_immediately_before_launch'] and f['reject_drift_before_launch'] and f['authority_consumed_on_attempt_even_on_failure'] and f['no_retry_after_failure'])
check('transport limited to new executor and immutable builder',f['transport_artifact_paths']==[f['executor_path'],f['builder_path']])
check('no historical reuse manual builder or chmod',not f['old_executor_or_authorization_reuse_allowed'] and f['no_manual_builder_execution'] and not f['chmod_remediation_allowed'])
check('probe and build actions currently closed',not policy['authorization']['read_only_probe_execution_authorized'] and not policy['authorization']['read_only_probe_transport_authorized'] and not policy['authorization']['target_observation_authorized'] and not policy['authorization']['builder_transport_authorized'] and not policy['authorization']['local_source_v4_build_authorized'])
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
check('CHANGELOG records stage','## Phase 1 step 277 ' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
