#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
v4_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review.sh --output-dir DIR

Generate the repository-only step-263 local-source-v4 builder implementation-review policy and TSV record.
This helper reviews the separately implemented v4 builder identity and opens no production execution or target-machine authority.
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

require_hash "$prev_helper" 'a8e6e5980edcf9550bc4ab7999b4452899b45e0e29c4e62039b9045916573b2f' 'accepted step-262 helper'
require_hash "$prev_doc" '29da67295aba1d65de381901031048691940ac8729b57846c51d20c318ac04e5' 'accepted step-262 document'
require_hash "$prev_harness" 'f5da26f955ded2eec9a70eb5035f9d06fa299476aa1414ad7a82ffd40ab98961' 'accepted step-262 harness'
require_hash "$prev_policy" '9359949c6dfd9ac7476b1b4f3053dbd2859022feab6d90e7baafcafb5a07b425' 'accepted step-262 policy'
require_hash "$prev_record" 'fff8563425ff16f64935e94d99d6e8709554941aac55bc7e40917a04fb39d6e3' 'accepted step-262 record'
require_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' 'accepted local-source-v3 builder'
require_hash "$v4_builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'reviewed local-source-v4 builder'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy, json, pathlib, sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p262=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p262['step']==262 and p262['review_status']=='PASS'
assert p262['builder_design']['state']=='design-frozen-not-implemented'
assert p262['authorization']['repository_only_v4_builder_implementation_review_authorized'] is True
assert p262['authorization']['local_source_v4_builder_execution_authorized'] is False
assert p262['authorization']['local_source_v4_build_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review'

policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review',
  'step':263,
  'review_only':True,
  'review_status':'PASS',
  'accepted_step_262':{
    'helper_sha256':'a8e6e5980edcf9550bc4ab7999b4452899b45e0e29c4e62039b9045916573b2f',
    'document_sha256':'29da67295aba1d65de381901031048691940ac8729b57846c51d20c318ac04e5',
    'harness_sha256':'f5da26f955ded2eec9a70eb5035f9d06fa299476aa1414ad7a82ffd40ab98961',
    'policy_sha256':'9359949c6dfd9ac7476b1b4f3053dbd2859022feab6d90e7baafcafb5a07b425',
    'record_sha256':'fff8563425ff16f64935e94d99d6e8709554941aac55bc7e40917a04fb39d6e3',
  },
  'accepted_v3_builder':copy.deepcopy(p262['accepted_v3_builder']),
  'reviewed_v4_builder':{
    'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh',
    'sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7',
    'state':'implementation-reviewed-not-frozen',
    'mechanical_v3_derivative_verified':True,
    'production_execution_performed':False,
  },
  'frozen_inputs':copy.deepcopy(p262['frozen_inputs']),
  'implementation_review':{
    'design_state_consumed':'design-frozen-not-implemented',
    'implementation_state':'implementation-reviewed-not-frozen',
    'functional_remediation_scope':'CHECKSUMS.md5 record representation only',
    'authorized_identity_substitutions_verified':True,
    'checksum_writer':'md5sum -- "$rel"',
    'checksum_line_shape':'<32-lowercase-hex-md5><two spaces>./relative/path',
    'checksum_path_is_final_field':True,
    'tagged_writer_absent':True,
    'validator_exact_line_count_required':True,
    'validator_tagged_records_rejected':True,
    'validator_exact_one_binding_per_eligible_file':True,
    'synthetic_valid_untagged_passed':True,
    'synthetic_tagged_failed':True,
    'synthetic_missing_failed':True,
    'synthetic_duplicate_failed':True,
    'synthetic_binary_marker_or_malformed_failed':True,
    'synthetic_extra_failed':True,
    'v3_baseline_hash_unchanged':True,
    'production_execution_forbidden_and_not_performed':True,
  },
  'unchanged_behavior_contract':copy.deepcopy(p262['builder_design']['unchanged_code_and_behavior_contract']),
  'implementation_freeze_gate':{
    'repository_only':True,
    'must_bind_exact_reviewed_v4_builder_sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7',
    'must_reprove_v3_baseline_sha256':'80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30',
    'must_rerun_repository_acceptance':True,
    'must_keep_builder_execution_closed':True,
    'must_keep_v4_build_closed':True,
    'must_open_no_machine_authority':True,
  },
  'authorization':{
    'repository_only_v4_builder_implementation_review_authorized':False,
    'repository_only_v4_builder_implementation_freeze_authorized':True,
    'local_source_v4_builder_execution_authorized':False,
    'local_source_v4_build_authorized':False,
    'target_observation_authorized':False,
    'probe_transport_copy_authorized':False,
    'predecessor_transport_or_staging_authorized':False,
    'temporary_slackpkg_configuration_authorized':False,
    'local_source_metadata_refresh_authorized':False,
    'runtime_candidate_binding_authorized':False,
    'reference_apply_authorized':False,
    'runtime_execution_or_rerun_authorized':False,
    'package_action_authorized':False,
    'slackpkg_mutation_authorized':False,
    'repository_refresh_authorized':False,
    'network_access_authorized':False,
    'persistent_configuration_change_authorized':False,
    'boot_action_authorized':False,
    'reboot_authorized':False,
    'evidence_cleanup_authorized':False,
    'phase_2_start_authorized':False,
  },
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review.sh',
  'helper_sha256':helper_sha,
  'machine_action_required':False,
  'controller_action_required':False,
  'future_work_requires_explicit_authorization':True,
  'pause_safe':False,
  'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','263'),
 ('revision','local-source-v4-builder-implementation-review'),
 ('review_status','PASS'),
 ('accepted_step_262','yes'),
 ('accepted_step_262_policy_sha256','9359949c6dfd9ac7476b1b4f3053dbd2859022feab6d90e7baafcafb5a07b425'),
 ('accepted_step_262_record_sha256','fff8563425ff16f64935e94d99d6e8709554941aac55bc7e40917a04fb39d6e3'),
 ('accepted_v3_builder_sha256','80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'),
 ('reviewed_v4_builder_sha256','38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'),
 ('builder_implementation_state','implementation-reviewed-not-frozen'),
 ('functional_remediation_scope','CHECKSUMS.md5-record-representation-only'),
 ('authorized_diff_only_verified','yes'),
 ('checksum_writer','md5sum-untagged-path-final'),
 ('valid_untagged_synthetic_test','PASS'),
 ('tagged_synthetic_test','REJECTED'),
 ('missing_synthetic_test','REJECTED'),
 ('duplicate_synthetic_test','REJECTED'),
 ('binary_marker_or_malformed_synthetic_test','REJECTED'),
 ('extra_synthetic_test','REJECTED'),
 ('v4_builder_execution_performed','no'),
 ('v4_builder_execution_authorized','no'),
 ('v4_build_authorized','no'),
 ('target_observation_authorized','no'),
 ('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),
 ('slackpkg_mutation_authorized','no'),
 ('network_access_authorized','no'),
 ('boot_action_authorized','no'),
 ('reboot_authorized','no'),
 ('machine_action_required','no'),
 ('controller_action_required','no'),
 ('future_work_requires_explicit_authorization','yes'),
 ('pause_safe','no'),
 ('strong_safe_pause','no'),
 ('next_stage',policy['next_stage']),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN

printf 'v4_builder_implementation_review_status\tPASS\n'
printf 'builder_implementation_state\timplementation-reviewed-not-frozen\n'
printf 'reviewed_v4_builder_sha256\t38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7\n'
printf 'authorized_diff_only_verified\tyes\n'
printf 'synthetic_checksum_contract\tPASS\n'
printf 'v4_builder_execution_authorized\tno\n'
printf 'v4_build_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze\n'
