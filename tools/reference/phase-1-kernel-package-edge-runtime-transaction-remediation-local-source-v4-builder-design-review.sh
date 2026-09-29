#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review.sh --output-dir DIR

Generate the repository-only step-261 local-source-v4 builder design-review policy and TSV record.
This helper performs no target-machine, package, Slackpkg, network, boot, reboot, builder implementation, or builder execution action.
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

require_hash "$prev_helper" '7c8e4adf631352887d142a984d7433df3550741ad74671071ca875134275c09c' 'accepted step-260 helper'
require_hash "$prev_doc" '336ef9f38fe3d7a4319b769a7ed375169a161d6c2f4302b913bacd12be980fe4' 'accepted step-260 document'
require_hash "$prev_harness" 'd0fa4a58c3848bd26a512ef9a560120a7c8f30e9482a27c0c6837ed3a29cc58d' 'accepted step-260 harness'
require_hash "$prev_policy" '72012226ec638b0cf9da0ab0514b391a88223958cb2c5567ad4aeca356ec9872' 'accepted step-260 policy'
require_hash "$prev_record" '266acba4c83d9a346e032433221776e14d67e7dde5bba49a5bb0da62b95aa780' 'accepted step-260 record'
require_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' 'accepted local-source-v3 builder'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import json, pathlib, sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p260=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p260['step']==260
assert p260['review_status']=='PASS' and p260['freeze_status']=='PASS'
assert p260['frozen_root_cause']['status']=='FROZEN_ACCEPTED'
assert p260['local_source_v4_boundary']['functional_remediation_scope']=='CHECKSUMS.md5 record representation only'
assert p260['authorization']['repository_only_v4_builder_design_review_authorized'] is True
assert p260['authorization']['local_source_v4_builder_implementation_authorized'] is False
assert p260['authorization']['local_source_v4_build_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review'

policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review',
  'step':261,
  'review_only':True,
  'review_status':'PASS',
  'accepted_step_260':{
    'helper_sha256':'7c8e4adf631352887d142a984d7433df3550741ad74671071ca875134275c09c',
    'document_sha256':'336ef9f38fe3d7a4319b769a7ed375169a161d6c2f4302b913bacd12be980fe4',
    'harness_sha256':'d0fa4a58c3848bd26a512ef9a560120a7c8f30e9482a27c0c6837ed3a29cc58d',
    'policy_sha256':'72012226ec638b0cf9da0ab0514b391a88223958cb2c5567ad4aeca356ec9872',
    'record_sha256':'266acba4c83d9a346e032433221776e14d67e7dde5bba49a5bb0da62b95aa780',
  },
  'accepted_v3_builder':{
    'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh',
    'sha256':'80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30',
    'role':'immutable design baseline and historical evidence',
    'must_remain_unchanged':True,
  },
  'frozen_inputs':{
    'root_cause_class':p260['frozen_root_cause']['class'],
    'failed_v2_pkglist_sha256':p260['frozen_root_cause']['failed_v2_pkglist_sha256'],
    'functional_remediation_scope':p260['local_source_v4_boundary']['functional_remediation_scope'],
    'target_filename':p260['local_source_v4_boundary']['frozen_package_identity']['target_filename'],
    'target_sha256':p260['local_source_v4_boundary']['frozen_package_identity']['target_sha256'],
    'target_relative_path':p260['local_source_v4_boundary']['frozen_package_identity']['target_relative_path'],
    'predecessor_filename':p260['local_source_v4_boundary']['frozen_package_identity']['predecessor_filename'],
    'package_location':p260['local_source_v4_boundary']['frozen_package_identity']['package_location'],
  },
  'builder_design':{
    'state':'design-reviewed-not-implemented',
    'derivation':'mechanical v3-r1 derivative under step-260 narrow boundary',
    'production_builder_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh',
    'production_switch':'--build-local-source-v4',
    'library_only_seam':'SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY',
    'output_identity':p260['local_source_v4_boundary']['v4_output_identity'],
    'required_identity_substitutions':[      'LOCAL_SOURCE_ROOT local-source-v3 -> local-source-v4',      'TREE_MANIFEST local-source-v3.tree.sha256 -> local-source-v4.tree.sha256',      'TREE_MANIFEST_SHA256 local-source-v3.tree.sha256.sha256 -> local-source-v4.tree.sha256.sha256',      'production switch --build-local-source-v3 -> --build-local-source-v4',      'temporary build prefix .local-source-v3.build -> .local-source-v4.build',      'revision labels and emitted status keys v3 -> v4',      'library-only seam V3 -> V4',    ],
    'checksum_writer_design':{
      'function':'write_checksums_md5',
      'enumeration':'sorted generated regular files',
      'excluded_paths':['./CHECKSUMS.md5','./CHECKSUMS.md5.asc'],
      'writer_command':'md5sum -- "$rel"',
      'tagged_writer_forbidden':True,
      'required_line_shape':'<32-lowercase-hex-md5><two spaces>./relative/path',
      'path_is_final_whitespace_delimited_field':True,
      'target_line_must_end_with_target_filename':True,
    },
    'checksum_validator_design':{
      'expected_binding_count':'generated regular file count minus CHECKSUMS.md5 and CHECKSUMS.md5.asc',
      'actual_binding_count':'wc -l of CHECKSUMS.md5',
      'tagged_record_count_must_equal':0,
      'for_each_eligible_file':'compute md5sum and require exactly one exact `<md5>  <rel>` line',
      'missing_binding_rejected':True,
      'duplicate_binding_rejected':True,
      'malformed_binding_rejected':True,
      'extra_binding_rejected_by_count_plus_exact_per_file_proof':True,
      'binary_marker_binding_not_accepted':True,
    },
    'unchanged_code_and_behavior_contract':{
      'input_validation_and_target_sha256_binding':True,
      'output_path_absence_preflight':True,
      'package_description_extraction':True,
      'package_stanza_generation':True,
      'priority_tree_set':['patches','slackware64','extra','pasture','testing'],
      'exactly_one_target_package_archive':True,
      'predecessor_absent':True,
      'filelist_generation':True,
      'compatibility_asc_semantics':True,
      'deterministic_mtime_normalization':True,
      'root_ownership_and_0555_0444_finalization':True,
      'external_sha256_tree_manifest_and_sidecar':True,
      'temporary_sibling_build_then_publish':True,
      'post_publish_manifest_verification':True,
      'root_required_for_production':True,
      'local_only_no_network':True,
      'no_package_slackpkg_boot_reboot_or_persistent_config_action':True,
    },
    'implementation_review_requirements':{
      'exact_v3_baseline_hash_must_still_match':True,
      'diff_must_be_limited_to_authorized_identity_and_checksum_changes':True,
      'repository_harness_must_source_library_only_seam':True,
      'synthetic_tree_tests_must_prove_valid_untagged_bindings_pass':True,
      'synthetic_tree_tests_must_prove_tagged_binding_fails':True,
      'synthetic_tree_tests_must_prove_missing_binding_fails':True,
      'synthetic_tree_tests_must_prove_duplicate_binding_fails':True,
      'synthetic_tree_tests_must_prove_malformed_or_extra_binding_fails':True,
      'production_execution_forbidden_during_implementation_review':True,
    },
    'forbidden_design_expansion':[      'changing target package bytes, filename, relative path, or SHA-256',      'adding predecessor or another package archive',      'changing priority-tree or package-stanza behavior',      'changing compatibility asc semantics',      'weakening output absence, tree safety, permission, or manifest checks',      'adding network, package, Slackpkg, boot, reboot, or persistent configuration actions',      'modifying accepted v3 builder or accepted/failed historical evidence in place',    ],
  },
  'authorization':{
    'repository_only_v4_builder_design_freeze_authorized':True,
    'repository_only_v4_builder_implementation_authorized':False,
    'local_source_v4_build_authorized':False,
    'target_observation_authorized':False,
    'probe_transport_copy_authorized':False,
    'runtime_executor_build_authorized':False,
    'runtime_executor_transport_authorized':False,
    'predecessor_transport_or_staging_authorized':False,
    'temporary_slackpkg_configuration_authorized':False,
    'local_source_metadata_refresh_authorized':False,
    'repository_refresh_authorized':False,
    'runtime_candidate_binding_authorized':False,
    'reference_apply_authorized':False,
    'runtime_execution_or_rerun_authorized':False,
    'package_action_authorized':False,
    'slackpkg_mutation_authorized':False,
    'network_access_authorized':False,
    'persistent_configuration_change_authorized':False,
    'boot_action_authorized':False,
    'reboot_authorized':False,
    'evidence_cleanup_authorized':False,
    'phase_2_start_authorized':False,
  },
  'machine_action_required':False,
  'controller_action_required':False,
  'pause_safe':False,
  'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze',
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review.sh',
  'helper_sha256':helper_sha,
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','261'),
 ('revision','local-source-v4-builder-design-review'),
 ('review_status','PASS'),
 ('accepted_step_260','yes'),
 ('accepted_v3_builder_sha256','80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'),
 ('builder_design_state','design-reviewed-not-implemented'),
 ('functional_remediation_scope','CHECKSUMS.md5-record-representation-only'),
 ('checksum_writer','md5sum-untagged-path-final'),
 ('tagged_checksum_records_authorized','no'),
 ('validator_requires_exact_one_binding_per_eligible_file','yes'),
 ('validator_rejects_missing_duplicate_malformed_extra','yes'),
 ('target_package_identity_change_authorized','no'),
 ('v3_builder_mutation_authorized','no'),
 ('v4_builder_implementation_authorized','no'),
 ('v4_build_authorized','no'),
 ('runtime_rerun_authorized','no'),
 ('machine_action_required','no'),
 ('controller_action_required','no'),
 ('pause_safe','no'),
 ('strong_safe_pause','no'),
 ('next_stage',policy['next_stage']),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN

printf 'v4_builder_design_review_status\tPASS\n'
printf 'builder_design_state\tdesign-reviewed-not-implemented\n'
printf 'functional_remediation_scope\tCHECKSUMS.md5-record-representation-only\n'
printf 'checksum_writer\tmd5sum-untagged-path-final\n'
printf 'v4_builder_implementation_authorized\tno\n'
printf 'v4_build_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze\n'
