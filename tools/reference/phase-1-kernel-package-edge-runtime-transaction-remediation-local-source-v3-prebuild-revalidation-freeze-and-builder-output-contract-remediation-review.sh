#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-revalidation-freeze-and-builder-output-contract-remediation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"
new_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_probe="$repo_root/tools/reference/${prev}-probe.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-revalidation-freeze-and-builder-output-contract-remediation-review.sh --output-dir DIR

Consume and freeze the successful step-247 read-only observation and review a
separate r1 v3 builder whose only change corrects stale v2 evidence labels.
This helper grants no target, build, package, Slackpkg, network, boot, reboot,
or runtime-rerun authority.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
require_hash() { local path=$1 expected=$2 label=$3 actual; regular "$path" || fail "$label is missing or unsafe: $path"; actual=$(sha "$path"); [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"; }
[[ ${1:-} == '--help' || ${1:-} == '-h' ]] && { [[ $# -eq 1 ]] || { usage >&2; exit 2; }; usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'
require_hash "$prev_helper" '82f00abac2aafb0b79ca74e7d210bd96899cb91a93e6e735b1e3d3171de91941' 'accepted step-247 helper'
require_hash "$prev_probe" '7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949' 'accepted step-247 probe'
require_hash "$prev_doc" 'afd62ddaf9bbae7554a133997bd2b6ea0101ffdb2cfedf2bdcac98341251459e' 'accepted step-247 document'
require_hash "$prev_harness" '1543be40544074240e1080bab037555d0389d05380694f5c77eccf8622c1f746' 'accepted step-247 harness'
require_hash "$prev_policy" '08973f578b54e330e7c2219fe92d99192cf01379f2667627850515396f7f2fd9' 'accepted step-247 policy'
require_hash "$prev_record" '2535d7488cab5268a73e779e8fd6c4a110a8c0797ab87616bf0778321f4fb759' 'accepted step-247 record'
require_hash "$old_builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582' 'historical frozen v3 builder'
require_hash "$new_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' 'reviewed corrected v3 builder r1'
python3 - "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" <<'PY'
import json,sys
policy_path,record_path=sys.argv[1:]
policy={
  "schema":1,
  "step":248,
  "scenario":"phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-revalidation-freeze-and-builder-output-contract-remediation-review",
  "review_status":"PASS",
  "review_only":True,
  "strong_safe_pause":False,
  "prebuild_v3_observation":{
    "state":"consumed-and-frozen",
    "prebuild_v3_revalidation_status":"PASS",
    "prior_runtime_binding_reused":False,
    "fresh_boot_id":"fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9",
    "package_database_manifest_sha256":"726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
    "header_package_record":"kernel-headers-6.18.45-x86-1",
    "kernel_generic_record":"kernel-generic-6.18.45-x86_64-1",
    "staged_target_sha256":"c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "local_source_v2_tree_manifest_sha256":"e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945",
    "local_source_v2_tree_verified":True,
    "failed_remediation_evidence_preserved":True,
    "boot_artifacts_match_failed_remediation_preflight":True,
    "slackpkg_state_matches_failed_remediation_preflight":True,
    "geninitrd_policy_matches_failed_remediation_preflight":True,
    "local_source_v3_final_outputs_absent":True,
    "local_source_v3_temporary_build_roots_absent":True,
    "probe_authority_consumed":True
  },
  "builder_output_contract_remediation":{
    "defect_state":"confirmed-before-build-authorization",
    "historical_builder_path":"tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh",
    "historical_builder_sha256":"56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582",
    "historical_builder_execution_count":0,
    "historical_builder_must_remain_unchanged":True,
    "corrected_builder_path":"tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh",
    "corrected_builder_sha256":"80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30",
    "corrected_builder_state":"implemented-reviewed-not-frozen-not-executed",
    "allowed_change_count":2,
    "allowed_changes":[
      "local_source_v2_build_status->local_source_v3_build_status",
      "local_source_v2_root->local_source_v3_root"
    ],
    "build_semantics_unchanged":True,
    "synthetic_render_manifest_equivalence_required":True,
    "execution_acknowledgement":"--build-local-source-v3"
  },
  "future_executor_v2_state":"reviewed-frozen-not-implemented",
  "authorization":{
    "repository_corrected_builder_freeze_and_build_authorization_review_authorized":True,
    "target_observation_authorized":False,
    "probe_transport_copy_authorized":False,
    "local_source_v3_builder_transport_authorized":False,
    "local_source_v3_builder_execution_authorized":False,
    "local_source_v3_build_authorized":False,
    "runtime_executor_v2_implementation_authorized":False,
    "runtime_executor_v2_transport_authorized":False,
    "runtime_rerun_authorized":False,
    "package_action_authorized":False,
    "slackpkg_mutation_authorized":False,
    "repository_refresh_authorized":False,
    "network_access_authorized":False,
    "boot_action_authorized":False,
    "reboot_authorized":False,
    "evidence_cleanup_authorized":False,
    "phase_2_start_authorized":False
  },
  "machine_action_required":False,
  "controller_action_required":False,
  "future_work_requires_explicit_authorization":True,
  "pause_safe":False,
  "next_stage":"phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review"
}
with open(policy_path,'w',encoding='utf-8') as f: json.dump(policy,f,indent=2,sort_keys=True); f.write('\n')
rows=[
("step","248"),("review_status","PASS"),("prebuild_v3_observation_state","consumed-and-frozen"),("fresh_boot_id","fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9"),("package_database_manifest_sha256","726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6"),("staged_target_sha256","c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c"),("local_source_v2_tree_manifest_sha256","e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945"),("local_source_v3_final_outputs_absent_at_observation","yes"),("local_source_v3_temporary_build_roots_absent_at_observation","yes"),("historical_v3_builder_sha256","56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582"),("historical_v3_builder_execution_count","0"),("corrected_v3_builder_r1_sha256","80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30"),("corrected_v3_builder_r1_state","implemented-reviewed-not-frozen-not-executed"),("builder_output_label_remediation_only","yes"),("target_observation_authorized","no"),("probe_transport_copy_authorized","no"),("local_source_v3_builder_transport_authorized","no"),("local_source_v3_builder_execution_authorized","no"),("local_source_v3_build_authorized","no"),("runtime_executor_v2_implementation_authorized","no"),("runtime_rerun_authorized","no"),("machine_action_required","no"),("controller_action_required","no"),("pause_safe","no"),("next_stage","phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review")]
with open(record_path,'w',encoding='utf-8',newline='') as f:
    for k,v in rows: f.write(k+'\t'+v+'\n')
PY
