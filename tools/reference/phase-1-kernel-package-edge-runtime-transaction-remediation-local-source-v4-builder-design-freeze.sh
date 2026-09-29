#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze.sh --output-dir DIR

Generate the repository-only step-262 local-source-v4 builder design-freeze policy and TSV record.
This helper performs no target-machine, builder execution, package, Slackpkg, network, boot, reboot, or persistent-configuration action.
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

require_hash "$prev_helper" '6768757c0eb8524a7b5e75ff71281f1614f2d3a04103825d3f662c5a44c50393' 'accepted step-261 helper'
require_hash "$prev_doc" 'd90684734c2de428d84ae0bf01c34c62c78ba234cb59598cb47ceeb910516da7' 'accepted step-261 document'
require_hash "$prev_harness" '161a00c3552bcc2cec52446a239490140df80989885ce53984c4211355b57874' 'accepted step-261 harness'
require_hash "$prev_policy" 'db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef' 'accepted step-261 policy'
require_hash "$prev_record" 'b733228aeca5be7055cb84dff306744fb41f49f13c7cc8c1d57bed7401c94981' 'accepted step-261 record'
require_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' 'accepted local-source-v3 builder'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy, json, pathlib, sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p261=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p261['step']==261 and p261['review_status']=='PASS'
assert p261['builder_design']['state']=='design-reviewed-not-implemented'
assert p261['authorization']['repository_only_v4_builder_design_freeze_authorized'] is True
assert p261['authorization']['repository_only_v4_builder_implementation_authorized'] is False
assert p261['authorization']['local_source_v4_build_authorized'] is False
assert p261['machine_action_required'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze'

design=copy.deepcopy(p261['builder_design'])
design['state']='design-frozen-not-implemented'
policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze',
  'step':262,
  'review_only':True,
  'review_status':'PASS',
  'accepted_step_261':{
    'helper_sha256':'6768757c0eb8524a7b5e75ff71281f1614f2d3a04103825d3f662c5a44c50393',
    'document_sha256':'d90684734c2de428d84ae0bf01c34c62c78ba234cb59598cb47ceeb910516da7',
    'harness_sha256':'161a00c3552bcc2cec52446a239490140df80989885ce53984c4211355b57874',
    'policy_sha256':'db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef',
    'record_sha256':'b733228aeca5be7055cb84dff306744fb41f49f13c7cc8c1d57bed7401c94981',
  },
  'accepted_v3_builder':copy.deepcopy(p261['accepted_v3_builder']),
  'frozen_inputs':copy.deepcopy(p261['frozen_inputs']),
  'builder_design':design,
  'design_freeze_contract':{
    'accepted_step_261_design_semantics_must_not_change':True,
    'functional_remediation_scope_remains_CHECKSUMS_md5_record_representation_only':True,
    'implementation_must_be_mechanical_v3_r1_derivative':True,
    'implementation_diff_must_be_limited_to_frozen_identity_and_checksum_changes':True,
    'accepted_v3_builder_hash_must_remain_exact':True,
    'untagged_writer_and_exact_binding_validator_are_mandatory':True,
    'tagged_MD5_records_are_forbidden':True,
    'synthetic_negative_tests_are_mandatory':True,
    'implementation_review_may_create_repository_artifacts_but_may_not_execute_builder':True,
    'v4_build_requires_later_fresh_target_revalidation_and_explicit_single_use_authorization':True,
    'runtime_rerun_requires_later_accepted_v4_build_and_separate_authorization':True,
  },
  'implementation_review_boundary':{
    'repository_only':True,
    'production_builder_path':design['production_builder_path'],
    'production_switch':design['production_switch'],
    'library_only_seam':design['library_only_seam'],
    'must_prove_exact_v3_baseline_hash':True,
    'must_prove_authorized_diff_only':True,
    'must_source_library_only_seam_for_synthetic_tests':True,
    'must_prove_valid_untagged_bindings_pass':True,
    'must_prove_tagged_bindings_fail':True,
    'must_prove_missing_bindings_fail':True,
    'must_prove_duplicate_bindings_fail':True,
    'must_prove_malformed_or_binary_marker_bindings_fail':True,
    'must_prove_extra_bindings_fail':True,
    'production_execution_forbidden':True,
    'target_machine_action_forbidden':True,
  },
  'authorization':{
    'repository_only_v4_builder_design_freeze_authorized':False,
    'repository_only_v4_builder_implementation_review_authorized':True,
    'repository_only_v4_builder_implementation_freeze_authorized':False,
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
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze.sh',
  'helper_sha256':helper_sha,
  'machine_action_required':False,
  'controller_action_required':False,
  'future_work_requires_explicit_authorization':True,
  'pause_safe':False,
  'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','262'),
 ('revision','local-source-v4-builder-design-freeze'),
 ('review_status','PASS'),
 ('accepted_step_261','yes'),
 ('accepted_step_261_policy_sha256','db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef'),
 ('accepted_step_261_record_sha256','b733228aeca5be7055cb84dff306744fb41f49f13c7cc8c1d57bed7401c94981'),
 ('accepted_v3_builder_sha256','80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'),
 ('builder_design_state','design-frozen-not-implemented'),
 ('functional_remediation_scope','CHECKSUMS.md5-record-representation-only'),
 ('checksum_writer','md5sum-untagged-path-final'),
 ('tagged_checksum_records_authorized','no'),
 ('validator_requires_exact_one_binding_per_eligible_file','yes'),
 ('synthetic_negative_tests_required','yes'),
 ('authorized_diff_only_required','yes'),
 ('v3_builder_mutation_authorized','no'),
 ('repository_only_v4_builder_implementation_review_authorized','yes'),
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
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review'),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
