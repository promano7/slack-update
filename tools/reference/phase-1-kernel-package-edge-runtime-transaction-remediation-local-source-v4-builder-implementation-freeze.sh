#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
v4_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.sh --output-dir DIR

Freeze the accepted step-263 local-source-v4 builder implementation identity and repository-only acceptance state.
No production builder execution or target-machine authority is opened.
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

require_hash "$prev_helper" '546cc2c6bcb50ea64dfcde09d9facdd997dc6f1c615e04c07d944596d2557445' 'accepted step-263 helper'
require_hash "$prev_doc" 'df86e5f3e7002dd6fbffd53951d15242c917ad0514c5122e38597b7f7dd9c72b' 'accepted step-263 document'
require_hash "$prev_harness" '09e8242d0ec4a457cce3df528e73a92419d4c6f663d2127d4ff25521a1cfc5b2' 'accepted step-263 harness'
require_hash "$prev_policy" '2d43ad83fbdd51dfcadcb9dc0b2f61403ab4ab883c18108c02b0e2595efe1dc7' 'accepted step-263 policy'
require_hash "$prev_record" '42289765f73553f2d8ffac31c1d04dbe3208045c5e2e8a3375260b227e0eee28' 'accepted step-263 record'
require_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' 'accepted local-source-v3 builder'
require_hash "$v4_builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'reviewed local-source-v4 builder'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy, json, pathlib, sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p263=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p263['step']==263 and p263['review_status']=='PASS'
assert p263['reviewed_v4_builder']['state']=='implementation-reviewed-not-frozen'
assert p263['reviewed_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert p263['implementation_review']['synthetic_valid_untagged_passed'] is True
for key in ('synthetic_tagged_failed','synthetic_missing_failed','synthetic_duplicate_failed','synthetic_binary_marker_or_malformed_failed','synthetic_extra_failed'):
    assert p263['implementation_review'][key] is True
assert p263['authorization']['repository_only_v4_builder_implementation_freeze_authorized'] is True
assert p263['authorization']['local_source_v4_builder_execution_authorized'] is False
assert p263['authorization']['local_source_v4_build_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze'

policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze',
  'step':264,
  'review_only':True,
  'review_status':'PASS',
  'accepted_step_263':{
    'helper_sha256':'546cc2c6bcb50ea64dfcde09d9facdd997dc6f1c615e04c07d944596d2557445',
    'document_sha256':'df86e5f3e7002dd6fbffd53951d15242c917ad0514c5122e38597b7f7dd9c72b',
    'harness_sha256':'09e8242d0ec4a457cce3df528e73a92419d4c6f663d2127d4ff25521a1cfc5b2',
    'policy_sha256':'2d43ad83fbdd51dfcadcb9dc0b2f61403ab4ab883c18108c02b0e2595efe1dc7',
    'record_sha256':'42289765f73553f2d8ffac31c1d04dbe3208045c5e2e8a3375260b227e0eee28',
  },
  'accepted_v3_builder':copy.deepcopy(p263['accepted_v3_builder']),
  'frozen_v4_builder':{
    'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh',
    'sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7',
    'state':'implementation-frozen-not-executed',
    'mechanical_v3_derivative_verified':True,
    'repository_acceptance_rerun_required':True,
    'production_execution_performed':False,
  },
  'frozen_inputs':copy.deepcopy(p263['frozen_inputs']),
  'implementation_freeze':{
    'functional_remediation_scope':'CHECKSUMS.md5 record representation only',
    'reviewed_builder_identity_frozen':True,
    'v3_baseline_identity_reproved':True,
    'checksum_writer':'md5sum -- "$rel"',
    'checksum_line_shape':'<32-lowercase-hex-md5><two spaces>./relative/path',
    'checksum_path_is_final_field':True,
    'tagged_writer_forbidden':True,
    'exact_binding_validator_required':True,
    'step_263_repository_acceptance_must_pass':True,
    'synthetic_gate_set_frozen':[
      'valid-untagged-pass',
      'tagged-reject',
      'missing-reject',
      'duplicate-reject',
      'binary-marker-or-malformed-reject',
      'extra-reject',
    ],
    'production_execution_forbidden_and_not_performed':True,
  },
  'unchanged_behavior_contract':copy.deepcopy(p263['unchanged_behavior_contract']),
  'fresh_revalidation_gate':{
    'repository_only':False,
    'target_machine_read_only_revalidation_required':True,
    'must_revalidate_target_filename':'kernel-headers-6.18.45-x86-1.txz',
    'must_revalidate_target_sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'must_revalidate_predecessor_absent':True,
    'must_prove_v4_output_paths_absent':True,
    'must_not_execute_v4_builder':True,
    'must_not_refresh_slackpkg':True,
    'must_not_mutate_packages_or_configuration':True,
    'must_open_no_build_authority':True,
  },
  'authorization':{
    'repository_only_v4_builder_implementation_freeze_authorized':False,
    'fresh_target_and_v4_output_absence_revalidation_authorized':True,
    'local_source_v4_builder_execution_authorized':False,
    'local_source_v4_build_authorized':False,
    'local_source_metadata_refresh_authorized':False,
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
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.sh',
  'helper_sha256':helper_sha,
  'machine_action_required':True,
  'machine_action_class':'read-only-target-and-output-absence-revalidation',
  'controller_action_required':False,
  'future_work_requires_explicit_authorization':True,
  'pause_safe':False,
  'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','264'),
 ('revision','local-source-v4-builder-implementation-freeze'),
 ('review_status','PASS'),
 ('accepted_step_263','yes'),
 ('accepted_step_263_policy_sha256','2d43ad83fbdd51dfcadcb9dc0b2f61403ab4ab883c18108c02b0e2595efe1dc7'),
 ('accepted_step_263_record_sha256','42289765f73553f2d8ffac31c1d04dbe3208045c5e2e8a3375260b227e0eee28'),
 ('accepted_v3_builder_sha256','80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'),
 ('frozen_v4_builder_sha256','38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'),
 ('builder_implementation_state','implementation-frozen-not-executed'),
 ('functional_remediation_scope','CHECKSUMS.md5-record-representation-only'),
 ('step_263_repository_acceptance_required','yes'),
 ('synthetic_gate_set_frozen','yes'),
 ('v4_builder_execution_performed','no'),
 ('v4_builder_execution_authorized','no'),
 ('v4_build_authorized','no'),
 ('fresh_target_and_v4_output_absence_revalidation_authorized','yes'),
 ('slackpkg_refresh_authorized','no'),
 ('package_action_authorized','no'),
 ('network_access_authorized','no'),
 ('boot_action_authorized','no'),
 ('reboot_authorized','no'),
 ('machine_action_required','yes'),
 ('machine_action_class','read-only-target-and-output-absence-revalidation'),
 ('controller_action_required','no'),
 ('future_work_requires_explicit_authorization','yes'),
 ('pause_safe','no'),
 ('strong_safe_pause','no'),
 ('next_stage',policy['next_stage']),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN

printf 'v4_builder_implementation_freeze_status\tPASS\n'
printf 'builder_implementation_state\timplementation-frozen-not-executed\n'
printf 'frozen_v4_builder_sha256\t38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7\n'
printf 'v4_builder_execution_authorized\tno\n'
printf 'v4_build_authorized\tno\n'
printf 'machine_action_required\tyes\n'
printf 'machine_action_class\tread-only-target-and-output-absence-revalidation\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation\n'
