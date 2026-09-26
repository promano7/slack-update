#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
[[ $# -eq 2 && $1 == --output-dir ]] || { printf 'Usage: %s --output-dir DIR\n' "${0##*/}" >&2; exit 2; }
out=$2
mkdir -p -- "$out"
cat > "$out/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review-policy.json" <<'POLICY209'
{
  "accepted_artifact_binding": {
    "binding_step": 197,
    "evidence_root": "/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts",
    "evidence_root_must_remain_unchanged": true,
    "policy_sha256": "79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12",
    "predecessor_artifact": "kernel-headers-6.18.44-x86-1.txz",
    "predecessor_sha256": "3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d",
    "record_sha256": "abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449",
    "signing_key_fingerprint": "EC5649DA401E22ABFA6736EF6A4463C040102233",
    "target_artifact": "kernel-headers-6.18.45-x86-1.txz",
    "target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c"
  },
  "accepted_step_202": {
    "boot_id": "d767c4ed-b21f-4c6f-9a1e-db7948c285cf",
    "fresh_target_binding_state": "frozen",
    "helper_sha256": "5e6968c0af540fe993d229f7c86f906e6e2bcb2bbe82557603d24b01975e7a59",
    "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
    "policy_sha256": "196f29cc2bc171e8ce12f4ba6648dcceeb36a5ba49ca29956edba1f6c35521b0",
    "record_sha256": "611bb1de56fb14c04340333b02c2290640f325ba11daf68e944d13c252432e45"
  },
  "accepted_step_206": {
    "builder_sha256": "59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92",
    "document_sha256": "ffbf3fc7f062ce31106074a9eaf9c6bd96a9b43ba4fbfe9de1dd7fc2fca9a312",
    "harness_sha256": "b76315a4a1b53f26702cbdf2d01a805d86efdfb5e7e97a03fda943cf70badcf5",
    "helper_sha256": "93cd675d96e377a96c17d405fc75695fbaa12342bbf1cfc21a7f3e336e121572",
    "policy_sha256": "89ae426cb6f7a57163fde8c182078549ed94d239956108eb1803806e3030f3ac",
    "record_sha256": "9324e7df13b645a6445be0dd3b1f1010381a14eccfaa352cb2c610cfa3a4f005"
  },
  "accepted_step_207": {
    "document_sha256": "c32c2ce7c11ed1283b3b9cabd55316048a6c97d5572b348c2085cfa371602426",
    "harness_sha256": "a798ead36cbf6dcae11239c250b066759a9e2e47c8264cc62faf04d84405e0c3",
    "helper_sha256": "e7374f48ce3b553099799dacb6e878c75c25fe402c016943c7928e2edb92fdbe",
    "policy_sha256": "d31bfef0c279061d78c5a70192f2ab6892ca3f80c2461b586688257c94d4c00c",
    "record_sha256": "882f4c4b42e1e9acfb67cb5a66d554d45f261a679b0238cb512da865bccef543",
    "stager_sha256": "a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb"
  },
  "accepted_step_208": {
    "builder_sha256": "59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92",
    "document_sha256": "f411895a28f1477ff61dc9e0c9042889a61a810d3869c383a12c8a3a478077b8",
    "harness_sha256": "785cfe75873c758db777cb89eced217733fc29925b33c4b036fbcd3c6bf1b85a",
    "helper_sha256": "d3b72850a4844f010aa4d45ab45ca7d42b48daf25655d15d7e4c8585e96aeb34",
    "policy_sha256": "6e4cdc3f8e63ee7d88d30407a8e54838b12784915cd986e447eb3125f69f41a3",
    "record_sha256": "3c708a9e40b1b1756582d7550f1cd9b40a1fb7fc803361595848edebf7b6307c",
    "stager_sha256": "a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb"
  },
  "authorization": {
    "boot_action_authorized": false,
    "builder_execution_authorized": true,
    "controller_builder_transport_copy_authorized": true,
    "controller_transport_copy_authorized": false,
    "local_source_build_authorized": true,
    "local_source_build_result_review_required_after_execution": true,
    "network_refresh_authorized": false,
    "package_action_authorized": false,
    "phase_2_start_authorized": false,
    "reboot_authorized": false,
    "repository_refresh_authorized": false,
    "runtime_candidate_refresh_authorized": false,
    "runtime_scenario_execution_authorized": false,
    "stager_execution_authorized": false,
    "target_artifact_copy_authorized": false,
    "target_artifact_staging_result_review_required_after_execution": false
  },
  "builder_implementation": {
    "acceptance_root": "/var/tmp/slack-update-acceptance/kernel-package-edge",
    "accepted_builder_input_artifact": "kernel-headers-6.18.45-x86-1.txz",
    "accepted_builder_input_artifact_count": 1,
    "artifact_authenticity_source": "frozen-step-197-package-and-detached-signature-binding",
    "builder_implementation_state": "frozen",
    "builder_path": "tools/reference/phase-1-kernel-package-edge-local-source-build.sh",
    "builder_sha256": "59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92",
    "deterministic_generation": {
      "boot_id_embedded": false,
      "existing_final_tree_overwrite_allowed": false,
      "hostname_embedded": false,
      "locale": "C",
      "sorted_manifest_paths": true,
      "source_tree_promoted_only_after_validation": true,
      "umask": "022",
      "wall_clock_time_embedded": false
    },
    "exact_package_candidate": "kernel-headers-6.18.45-x86-1.txz",
    "exact_package_candidate_count": 1,
    "execution_acknowledgement": "--build-local-source",
    "execution_target": "slackware-current-target-vm",
    "failure_contract": {
      "fail_closed": true,
      "may_remove_only_builder_owned_temporary_tree": true,
      "must_not_delete_preexisting_final_tree": true,
      "must_not_modify_boot_state": true,
      "must_not_modify_package_database": true,
      "must_not_modify_slackpkg_configuration": true,
      "must_not_reboot": true,
      "must_preserve_staging_inputs": true
    },
    "finalization_contract": {
      "all_regular_files_sha256_manifest_required": true,
      "final_tree_directory_mode": "0555",
      "final_tree_owner": "root:root",
      "final_tree_regular_file_mode": "0444",
      "manifest_is_outside_source_tree": true,
      "manifest_sha256_required": true,
      "tree_must_be_read_only_before_runtime": true,
      "tree_must_verify_unchanged_after_finalization": true,
      "tree_must_verify_unchanged_after_reference_apply": true,
      "tree_must_verify_unchanged_before_reference_apply": true
    },
    "generated_metadata_is_upstream_signed": false,
    "implementation_freeze_step": 206,
    "implementation_review_policy_sha256": "1c8dcce9ac02594734e866bc6f5515900f6dfbdfbc8b630ef6e5c5ac8836fd1d",
    "implementation_review_record_sha256": "9ad8a0902cd5fe49152fefc4cc5ef6db3e7c979ed9d79441f350ab75693c5e6c",
    "implementation_review_step": 205,
    "input_guards": {
      "builder_may_access_network": false,
      "builder_may_modify_external_evidence_root": false,
      "output_root_must_not_preexist": true,
      "target_input_filename_must_match_frozen_binding": true,
      "target_input_must_be_regular_file": true,
      "target_input_sha256_must_match_frozen_binding": true,
      "target_input_symlink_allowed": false
    },
    "local_source_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source",
    "metadata_contract": {
      "changelog_txt_must_be_deterministic": true,
      "changelog_txt_must_be_nonempty": true,
      "checksums_md5_must_bind_target_package": true,
      "filelist_txt_must_enumerate_target_package_path": true,
      "filelist_txt_must_not_expose_second_package_archive": true,
      "metadata_signature_check_may_be_disabled_only_inside_bound_runtime_configuration": true,
      "packages_txt_description_source": "install/slack-desc-from-bound-target-package",
      "packages_txt_exact_stanza_count": 1,
      "packages_txt_package_location": "./slackware64/d",
      "packages_txt_package_name": "kernel-headers-6.18.45-x86-1.txz",
      "packages_txt_requires_compressed_size_kib": true,
      "packages_txt_requires_uncompressed_size_kib": true
    },
    "predecessor_input_path": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.44-x86-1.txz",
    "predecessor_is_builder_input": false,
    "predecessor_role": "later-staging-only-never-local-source-candidate",
    "privilege_boundary": "root-via-sudo",
    "repository_test_seam": {
      "environment_variable": "SLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY",
      "production_main_bypassed": true,
      "production_paths_overridable": false,
      "purpose": "repository-harness-only-function-testing",
      "value": "1"
    },
    "required_top_level_metadata": [
      "ChangeLog.txt",
      "FILELIST.TXT",
      "PACKAGES.TXT",
      "CHECKSUMS.md5"
    ],
    "runtime_mirror_uri": "file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source",
    "runtime_must_not_depend_on_generated_metadata_for_artifact_authenticity": true,
    "runtime_network_access_allowed": false,
    "staging_input_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input",
    "state": "frozen",
    "target_input_path": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz",
    "target_relative_path": "slackware64/d/kernel-headers-6.18.45-x86-1.txz",
    "temporary_build_root_pattern": "/var/tmp/slack-update-acceptance/kernel-package-edge/.local-source.build.XXXXXX",
    "tree_manifest_path": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256",
    "tree_manifest_sha256_path": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256"
  },
  "helper_path": "tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.sh",
  "local_source_build_authorization": {
    "authorization_consumed_when_local_source_root_created": true,
    "authorization_scope": "single-frozen-builder-execution",
    "builder_execution_authorized": true,
    "builder_repository_source": "/home/promano/GitHub/slack-update/tools/reference/phase-1-kernel-package-edge-local-source-build.sh",
    "builder_sha256": "59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92",
    "builder_transport_source": "/home/promano/Descargas/phase-1-kernel-package-edge-local-source-build.sh",
    "controller_transport_copy_authorized": true,
    "execution_acknowledgement": "--build-local-source",
    "execution_exact_command": "sudo bash phase-1-kernel-package-edge-local-source-build.sh --build-local-source",
    "execution_target": "slackware-current-target-vm",
    "expected_outputs": {
      "local_source_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source",
      "single_candidate": "kernel-headers-6.18.45-x86-1.txz",
      "single_candidate_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
      "tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256",
      "tree_manifest_sha256": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256"
    },
    "forbidden_effects": {
      "boot_action": true,
      "network_access": true,
      "package_action": true,
      "phase_2": true,
      "reboot": true,
      "repository_refresh": true,
      "runtime_scenario_execution": true,
      "slackpkg_configuration_change": true
    },
    "local_source_build_authorized": true,
    "manual_builder_transport_placement_to_fixed_vm_path_authorized": true,
    "post_execution_result_review_required": true,
    "preflight": {
      "acceptance_root_must_exist": true,
      "builder_transport_must_be_regular_nonsymlink": true,
      "builder_transport_sha256_must_match": true,
      "local_source_root_must_not_preexist": true,
      "staged_target_must_be_regular_nonsymlink": true,
      "staged_target_sha256_must_match": true,
      "staging_input_root_must_exist": true,
      "tree_manifest_must_not_preexist": true,
      "tree_manifest_sha256_must_not_preexist": true
    },
    "state": "authorized-awaiting-single-execution"
  },
  "machine_action_required": true,
  "next_stage": "phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause",
  "pause_safe": false,
  "review_only": false,
  "revision": "accepted-staging-result-and-single-local-source-build-authorization",
  "scenario": "phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review",
  "schema": 1,
  "stager_path": "tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh",
  "stager_sha256": "a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb",
  "target_artifact_staging": {
    "acceptance_parent": "/var/tmp/slack-update-acceptance",
    "acceptance_root": "/var/tmp/slack-update-acceptance/kernel-package-edge",
    "atomicity": {
      "failure_may_remove_only_stager_owned_temporary_root": true,
      "promote_only_after_staged_artifact_validation": true,
      "temporary_root_pattern": "/var/tmp/slack-update-acceptance/.kernel-package-edge.stage.XXXXXX",
      "unexpected_existing_acceptance_root_overwrite_allowed": false
    },
    "authorization_contract": {
      "authorization_consumed_when_acceptance_root_created": true,
      "authorization_expires_on_runtime_binding_drift": true,
      "authorization_expires_on_stager_byte_drift": true,
      "authorization_expires_on_transport_hash_or_type_drift": true,
      "authorization_scope": "single-target-artifact-staging-execution",
      "manual_transport_placement_must_not_modify_evidence_root": true,
      "manual_transport_placement_to_fixed_vm_path_authorized": true,
      "post_execution_result_review_required": true,
      "stager_execution_exact_command": "sudo bash phase-1-kernel-package-edge-target-artifact-stage.sh --stage-target-artifact"
    },
    "controller_transport_copy_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "controller_transport_source": "/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.45-x86-1.txz",
    "execution_acknowledgement": "--stage-target-artifact",
    "execution_target": "slackware-current-target-vm",
    "forbidden_effects": {
      "boot_action": true,
      "builder_execution": true,
      "local_source_build": true,
      "network_access": true,
      "package_action": true,
      "reboot": true,
      "repository_refresh": true,
      "slackpkg_configuration_change": true
    },
    "observed_result": {
      "boot_action_performed": false,
      "network_access_performed": false,
      "package_action_performed": false,
      "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
      "reboot_performed": false,
      "repository_refresh_performed": false,
      "slackpkg_configuration_change_performed": false,
      "staged_target": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz",
      "staged_target_mode": "0444",
      "staged_target_owner": "root:root",
      "staged_target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
      "target_artifact_staging_status": "PASS",
      "target_boot_id": "d767c4ed-b21f-4c6f-9a1e-db7948c285cf",
      "transport_source": "/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz",
      "transport_source_preserved": true
    },
    "preflight": {
      "acceptance_root_must_not_preexist": true,
      "runtime_binding_must_match_step_202": true,
      "transport_filename_must_match": true,
      "transport_sha256_must_match": true,
      "transport_source_must_be_regular_file": true,
      "transport_source_symlink_allowed": false
    },
    "privilege_boundary": "root-via-sudo",
    "repository_test_seam": {
      "environment_variable": "SLACK_UPDATE_TARGET_ARTIFACT_STAGER_LIBRARY_ONLY",
      "production_main_bypassed": true,
      "production_paths_overridable": false,
      "purpose": "repository-harness-only-function-testing",
      "value": "1"
    },
    "result_review": {
      "accepted": true,
      "runtime_binding_match_confirmed": true,
      "single_use_staging_authority_consumed": true,
      "staged_target_binding_match_confirmed": true,
      "stager_execution_authority_revoked": true,
      "target_artifact_copy_authority_revoked": true
    },
    "runtime_binding": {
      "boot_id": "d767c4ed-b21f-4c6f-9a1e-db7948c285cf",
      "fqdn": "vbox-slackcurrent.vbox-slackcurrent.org",
      "header_record": "kernel-headers-6.18.45-x86-1",
      "kernel_generic_record": "kernel-generic-6.18.45-x86_64-1",
      "kernel_huge_absent": true,
      "kernel_modules_absent": true,
      "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
      "slackpkg_conf_sha256": "f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4",
      "slackpkg_mirrors_sha256": "71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12",
      "slackware_version": "Slackware 15.0+",
      "uname_machine": "x86_64",
      "uname_release": "6.18.45"
    },
    "staged_target_mode": "0444",
    "staged_target_owner": "root:root",
    "staged_target_path": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz",
    "stager_path": "tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh",
    "stager_sha256": "a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb",
    "staging_input_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input",
    "state": "accepted-pass-authority-consumed",
    "target_artifact": "kernel-headers-6.18.45-x86-1.txz",
    "target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "transport_role": "untrusted-transport-copy-validated-against-frozen-step-197-binding",
    "transport_source": "/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz",
    "transport_source_preserved": true
  }
}
POLICY209
cat > "$out/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.tsv" <<'RECORD209'
step	209
revision	accepted-staging-result-and-single-local-source-build-authorization
fresh_target_binding_state	frozen
builder_implementation_state	frozen
target_artifact_staging_state	accepted-pass-authority-consumed
staging_result_status	PASS
staged_target_path	/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz
staged_target_sha256	c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c
staged_target_owner	root:root
staged_target_mode	0444
target_boot_id	d767c4ed-b21f-4c6f-9a1e-db7948c285cf
target_package_database_manifest_sha256	726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6
stager_execution_authorized	no
target_artifact_copy_authorized	no
builder_path	tools/reference/phase-1-kernel-package-edge-local-source-build.sh
builder_sha256	59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92
builder_transport_source	/home/promano/Descargas/phase-1-kernel-package-edge-local-source-build.sh
builder_execution_acknowledgement	--build-local-source
builder_execution_authorized	yes
local_source_build_authorized	yes
controller_builder_transport_copy_authorized	yes
local_source_root	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source
tree_manifest_path	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256
tree_manifest_sha256_path	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256
repository_refresh_authorized	no
package_action_authorized	no
slackpkg_configuration_change_authorized	no
runtime_scenario_execution_authorized	no
boot_action_authorized	no
reboot_authorized	no
machine_action_required	yes
pause_safe	no
next_stage	phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause
RECORD209
