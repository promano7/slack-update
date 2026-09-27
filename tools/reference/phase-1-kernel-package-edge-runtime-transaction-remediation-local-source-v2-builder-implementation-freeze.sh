#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze.sh --output-dir DIR

Generate the repository-only step-227 implementation-freeze policy and TSV record.
This helper performs no target observation, builder execution, package, Slackpkg, network, boot, or reboot action.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
require_hash() { local path=$1 expected=$2 label=$3 actual; regular "$path" || fail "$label is missing or unsafe: $path"; actual=$(sha "$path"); [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"; }
[[ ${1:-} == '--help' ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'
require_hash "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'reviewed v2 builder'
require_hash "$prev_helper" 'fc8ffed9c7fa9eb69a59b03b4d47bad3dfda4182cea20409f3dec0517f7f9d12' 'accepted step-226 helper'
require_hash "$prev_doc" 'f69b4c905d2b328f48f4c6f722015aa94794e095f4f1ed6cd1d16cee012fc806' 'accepted step-226 document'
require_hash "$prev_harness" '7ff6d776b683a5ddc7bc74a581e602f3479704bf37b78afb8ee3de8b4b9b3f8f' 'accepted step-226 harness'
require_hash "$prev_policy" '950fa9b91c59fc0562011ff716ca0108bb7ff78d5140cf96c4c9547806cd5826' 'accepted step-226 policy'
require_hash "$prev_record" '4da734369f4e4311f027d613732d0c8eaf2d873d74ec804272873c5ba265b412' 'accepted step-226 record'
helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p226=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p226['step']==226 and p226['review_status']=='PASS'
assert p226['builder_implementation']['state']=='implemented-reviewed-awaiting-freeze'
assert p226['builder_implementation']['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert p226['authorization']['repository_only_local_source_v2_builder_implementation_freeze_authorized'] is True
assert p226['authorization']['local_source_v2_builder_execution_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'
impl=copy.deepcopy(p226['builder_implementation']); impl['state']='implemented-frozen-not-executed'
design=copy.deepcopy(p226['local_source_v2_design']); design['state']='design-frozen-implementation-frozen-not-built'
refresh=copy.deepcopy(p226['future_refresh_acceptance_contract']); refresh.pop('not_authorized_by_step_226',None); refresh['not_authorized_by_step_227']=True
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze','step':227,'review_only':True,'review_status':'PASS',
 'accepted_step_226':{'builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d','helper_sha256':'fc8ffed9c7fa9eb69a59b03b4d47bad3dfda4182cea20409f3dec0517f7f9d12','document_sha256':'f69b4c905d2b328f48f4c6f722015aa94794e095f4f1ed6cd1d16cee012fc806','harness_sha256':'7ff6d776b683a5ddc7bc74a581e602f3479704bf37b78afb8ee3de8b4b9b3f8f','policy_sha256':'950fa9b91c59fc0562011ff716ca0108bb7ff78d5140cf96c4c9547806cd5826','record_sha256':'4da734369f4e4311f027d613732d0c8eaf2d873d74ec804272873c5ba265b412'},
 'frozen_runtime_identity':copy.deepcopy(p226['frozen_runtime_identity']),
 'preservation_contract':copy.deepcopy(p226['preservation_contract']),
 'local_source_v2_design':design,
 'builder_implementation':impl,
 'future_refresh_acceptance_contract':refresh,
 'implementation_freeze_contract':{
   'accepted_step_226_builder_bytes_are_immutable':True,
   'builder_sha256_is_execution_identity':True,
   'repository_test_seam_is_not_production_authority':True,
   'fresh_target_revalidation_required_before_builder_transport_or_execution':True,
   'builder_execution_requires_later_single_use_explicit_authorization':True,
   'v2_build_result_must_be_reviewed_and_frozen_before_executor_remediation':True,
 },
 'authorization':{
   'repository_only_local_source_v2_builder_implementation_freeze_authorized':False,
   'repository_only_prebuild_fresh_target_revalidation_review_authorized':True,
   'target_observation_authorized':False,
   'probe_transport_copy_authorized':False,
   'local_source_v2_builder_transport_authorized':False,
   'local_source_v2_builder_execution_authorized':False,
   'local_source_v2_build_authorized':False,
   'runtime_candidate_binding_authorized':False,
   'runtime_executor_remediation_authorized':False,
   'runtime_rerun_authorized':False,
   'package_action_authorized':False,
   'slackpkg_mutation_authorized':False,
   'repository_refresh_authorized':False,
   'network_access_authorized':False,
   'boot_action_authorized':False,
   'reboot_authorized':False,
   'persistent_configuration_change_authorized':False,
   'evidence_cleanup_authorized':False,
   'phase_2_start_authorized':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze.sh','helper_sha256':helper_sha,
 'machine_action_required':False,'controller_action_required':False,
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','227'),('review_status','PASS'),('accepted_step_226_builder_sha256','8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'),
 ('frozen_boot_id',policy['frozen_runtime_identity']['boot_id']),('builder_implementation_state',impl['state']),('builder_path',impl['builder_path']),('builder_sha256',impl['builder_sha256']),
 ('local_source_v2_design_state',design['state']),('local_source_v2_root',design['root']),('priority_trees',','.join(design['priority_tree_contract']['effective_x86_64_priority_trees'])),
 ('CHECKSUMS_md5_asc_required','yes'),('refresh_workdir_strategy',refresh['workdir_strategy']),('candidate_guard_scope',refresh['candidate_guard_scope']),
 ('local_source_v1_must_be_preserved_unchanged','yes'),('failed_runtime_evidence_root_must_be_preserved_unchanged','yes'),('staged_target_must_be_preserved_unchanged','yes'),
 ('repository_only_prebuild_fresh_target_revalidation_review_authorized','yes'),('target_observation_authorized','no'),('probe_transport_copy_authorized','no'),
 ('local_source_v2_builder_transport_authorized','no'),('local_source_v2_builder_execution_authorized','no'),('local_source_v2_build_authorized','no'),
 ('runtime_executor_remediation_authorized','no'),('runtime_rerun_authorized','no'),('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('repository_refresh_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),('phase_2_start_authorized','no'),
 ('machine_action_required','no'),('controller_action_required','no'),('future_work_requires_explicit_authorization','yes'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review')]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
