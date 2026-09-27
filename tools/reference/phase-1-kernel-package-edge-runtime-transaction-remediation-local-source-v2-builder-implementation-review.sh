#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review.sh --output-dir DIR

Generate the repository-only step-226 v2 builder implementation-review policy and TSV record.
This helper does not execute the builder or perform any target-machine action.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
require_hash() {
    local path=$1 expected=$2 label=$3 actual
    regular "$path" || fail "$label is missing or unsafe: $path"
    actual=$(sha "$path")
    [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"
}

[[ ${1:-} == '--help' ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'

require_hash "$prev_helper" 'e7c3c682b0078f4db070328cecf26e2df89f40caa12e8bea68e2f5aacedcf2e4' 'accepted step-225 helper'
require_hash "$prev_doc" 'f2e2f343b83b03a963c10fe094a39bdad2623d447807cc88c2021effebb42808' 'accepted step-225 document'
require_hash "$prev_harness" '6ac7be3dc98936c43585e6e0ffec158597035abbd88d166052f5d25a3cf76f59' 'accepted step-225 harness'
require_hash "$prev_policy" '6f439cc4803cefb8d1c8d62a3e9ccc07a4dae9523c4e16592d4527e01696ab64' 'accepted step-225 policy'
require_hash "$prev_record" 'd43544d6dbe41e5c17372921b93fd200afddaea7dcbf147c89814c625c5e5811' 'accepted step-225 record'
require_hash "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'reviewed v2 builder'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p225=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if not line: continue
    k,v=line.split('\t',1); record[k]=v
assert p225['step']==225 and p225['review_status']=='PASS'
assert p225['local_source_v2_design']['state']=='design-frozen-not-implemented'
assert p225['authorization']['repository_only_local_source_v2_builder_implementation_review_authorized'] is True
assert p225['authorization']['local_source_v2_builder_execution_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'

design=copy.deepcopy(p225['local_source_v2_design'])
refresh=copy.deepcopy(p225['future_refresh_acceptance_contract'])
refresh.pop('not_authorized_by_step_225',None)
refresh['not_authorized_by_step_226']=True
implementation={
  'state':'implemented-reviewed-awaiting-freeze',
  'builder_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh',
  'builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d',
  'execution_acknowledgement':'--build-local-source-v2',
  'repository_test_seam':'SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1',
  'production_paths_overridable':False,
  'local_source_v2_root':design['root'],
  'tree_manifest':design['tree_manifest'],
  'tree_manifest_sha256_sidecar':design['tree_manifest_sha256_sidecar'],
  'temporary_build_root_pattern':'/var/tmp/slack-update-acceptance/kernel-package-edge/.local-source-v2.build.XXXXXX',
  'target_input':design['target_input'],
  'target_filename':design['target_filename'],
  'target_sha256':design['target_sha256'],
  'target_relative_path':design['target_relative_path'],
  'priority_trees':copy.deepcopy(design['priority_tree_contract']['effective_x86_64_priority_trees']),
  'compatibility_asc_required':True,
  'compatibility_asc_is_not_authenticity_evidence':True,
  'deterministic_generation':{
    'locale':'C','umask':'022','generated_mtime_epoch':0,'sorted_file_enumeration':True,
    'wall_clock_time_embedded':False,'hostname_embedded':False,'boot_id_embedded':False,
  },
  'publication_contract':{
    'temporary_sibling_build_required':True,'validate_before_publish':True,'final_paths_must_not_preexist':True,
    'final_tree_directory_mode':'0555','final_tree_regular_file_mode':'0444','final_tree_owner':'root:root',
    'external_tree_manifest_required':True,'tree_manifest_sidecar_required':True,
  },
  'failure_contract':{
    'fail_closed':True,'builder_may_remove_only_builder_owned_temporary_tree':True,
    'must_preserve_local_source_v1':True,'must_preserve_failed_runtime_evidence':True,'must_preserve_staged_target':True,
    'must_not_modify_package_database':True,'must_not_modify_slackpkg_configuration':True,
    'must_not_access_network':True,'must_not_modify_boot_state':True,'must_not_reboot':True,
  },
}
policy={
  'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review','step':226,'review_only':True,'review_status':'PASS',
  'accepted_step_225':{
    'helper_sha256':'e7c3c682b0078f4db070328cecf26e2df89f40caa12e8bea68e2f5aacedcf2e4','document_sha256':'f2e2f343b83b03a963c10fe094a39bdad2623d447807cc88c2021effebb42808','harness_sha256':'6ac7be3dc98936c43585e6e0ffec158597035abbd88d166052f5d25a3cf76f59',
    'policy_sha256':'6f439cc4803cefb8d1c8d62a3e9ccc07a4dae9523c4e16592d4527e01696ab64','record_sha256':'d43544d6dbe41e5c17372921b93fd200afddaea7dcbf147c89814c625c5e5811',
  },
  'frozen_runtime_identity':copy.deepcopy(p225['frozen_runtime_identity']),
  'preservation_contract':copy.deepcopy(p225['preservation_contract']),
  'local_source_v2_design':design,
  'future_refresh_acceptance_contract':refresh,
  'builder_implementation':implementation,
  'authorization':{
    'repository_only_local_source_v2_builder_implementation_review_authorized':False,
    'repository_only_local_source_v2_builder_implementation_freeze_authorized':True,
    'local_source_v2_builder_execution_authorized':False,'local_source_v2_build_authorized':False,
    'target_observation_authorized':False,'runtime_candidate_binding_authorized':False,
    'runtime_executor_remediation_authorized':False,'runtime_rerun_authorized':False,
    'package_action_authorized':False,'slackpkg_mutation_authorized':False,'repository_refresh_authorized':False,
    'network_access_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,
    'persistent_configuration_change_authorized':False,'evidence_cleanup_authorized':False,'phase_2_start_authorized':False,
  },
  'implementation_review_contract':{
    'builder_conforms_to_frozen_step_225_design':True,
    'repository_harness_exercises_builder_functions_without_production_main':True,
    'builder_execution_requires_later_fresh_target_revalidation_and_explicit_authorization':True,
    'v2_build_result_must_be_frozen_before_runtime_executor_remediation':True,
  },
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review.sh','helper_sha256':helper_sha,
  'machine_action_required':False,'controller_action_required':False,'future_work_requires_explicit_authorization':True,
  'pause_safe':False,'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','226'),('review_status','PASS'),('accepted_step_225_policy_sha256','6f439cc4803cefb8d1c8d62a3e9ccc07a4dae9523c4e16592d4527e01696ab64'),
 ('frozen_boot_id',policy['frozen_runtime_identity']['boot_id']),
 ('local_source_v1_must_be_preserved_unchanged','yes'),('failed_runtime_evidence_root_must_be_preserved_unchanged','yes'),
 ('local_source_v2_design_state',design['state']),('builder_implementation_state',implementation['state']),
 ('builder_path',implementation['builder_path']),('builder_sha256',implementation['builder_sha256']),
 ('execution_acknowledgement',implementation['execution_acknowledgement']),('repository_test_seam',implementation['repository_test_seam']),
 ('production_paths_overridable','no'),('local_source_v2_root',implementation['local_source_v2_root']),
 ('target_filename',implementation['target_filename']),('target_sha256',implementation['target_sha256']),
 ('target_relative_path',implementation['target_relative_path']),('priority_trees',','.join(implementation['priority_trees'])),
 ('CHECKSUMS_md5_asc_required','yes'),('CHECKSUMS_md5_asc_authenticity_claim','no'),
 ('generated_mtime_epoch','0'),('temporary_sibling_build_required','yes'),('final_paths_must_not_preexist','yes'),
 ('tree_manifest_required','yes'),('tree_manifest_sidecar_required','yes'),
 ('refresh_workdir_strategy',refresh['workdir_strategy']),('candidate_guard_scope',refresh['candidate_guard_scope']),
 ('repository_only_local_source_v2_builder_implementation_freeze_authorized','yes'),
 ('local_source_v2_builder_execution_authorized','no'),('local_source_v2_build_authorized','no'),
 ('target_observation_authorized','no'),('runtime_executor_remediation_authorized','no'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('repository_refresh_authorized','no'),
 ('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('evidence_cleanup_authorized','no'),('phase_2_start_authorized','no'),('machine_action_required','no'),('controller_action_required','no'),
 ('future_work_requires_explicit_authorization','yes'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
