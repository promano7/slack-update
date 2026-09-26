#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
output_dir=
while (($#)); do
    case "$1" in
        --output-dir) output_dir=${2:?}; shift 2 ;;
        --help|-h) printf 'Usage: %s [--output-dir DIR]\n' "${0##*/}"; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-review.sh"
[[ -f $prior_policy && ! -L $prior_policy ]] || { printf 'ERROR: accepted step-202 policy missing\n' >&2; exit 3; }
[[ -f $prior_record && ! -L $prior_record ]] || { printf 'ERROR: accepted step-202 record missing\n' >&2; exit 3; }
[[ -f $prior_helper && ! -L $prior_helper ]] || { printf 'ERROR: accepted step-202 helper missing\n' >&2; exit 3; }
[[ ! -e $builder ]] || { printf 'ERROR: local-source builder must remain unimplemented during design review\n' >&2; exit 4; }
[[ $(sha256sum "$prior_policy" | awk '{print $1}') == 196f29cc2bc171e8ce12f4ba6648dcceeb36a5ba49ca29956edba1f6c35521b0 ]] || { printf 'ERROR: accepted step-202 policy hash mismatch\n' >&2; exit 5; }
[[ $(sha256sum "$prior_record" | awk '{print $1}') == 611bb1de56fb14c04340333b02c2290640f325ba11daf68e944d13c252432e45 ]] || { printf 'ERROR: accepted step-202 record hash mismatch\n' >&2; exit 5; }
[[ $(sha256sum "$prior_helper" | awk '{print $1}') == 5e6968c0af540fe993d229f7c86f906e6e2bcb2bbe82557603d24b01975e7a59 ]] || { printf 'ERROR: accepted step-202 helper hash mismatch\n' >&2; exit 5; }
[[ -z $output_dir ]] && output_dir=$acceptance_dir
mkdir -p "$output_dir"
policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-builder-design-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-builder-design-review.tsv"
helper_sha=$(sha256sum "$helper" | awk '{print $1}')
python3 - "$policy" "$record" "$helper_sha" <<'PYDATA203'
import csv, json, sys
from pathlib import Path
policy_path=Path(sys.argv[1]); record_path=Path(sys.argv[2]); helper_sha=sys.argv[3]
policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-local-source-construction-builder-design-review',
  'revision':'deterministic-minimal-file-mirror-builder-design',
  'review_only':True,
  'accepted_step_202':{
    'policy_sha256':'196f29cc2bc171e8ce12f4ba6648dcceeb36a5ba49ca29956edba1f6c35521b0',
    'record_sha256':'611bb1de56fb14c04340333b02c2290640f325ba11daf68e944d13c252432e45',
    'helper_sha256':'5e6968c0af540fe993d229f7c86f906e6e2bcb2bbe82557603d24b01975e7a59',
    'fresh_target_binding_state':'frozen',
    'boot_id':'d767c4ed-b21f-4c6f-9a1e-db7948c285cf',
    'package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
  },
  'accepted_artifact_binding':{
    'binding_step':197,
    'policy_sha256':'79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12',
    'record_sha256':'abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449',
    'evidence_root':'/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts',
    'evidence_root_must_remain_unchanged':True,
    'predecessor_artifact':'kernel-headers-6.18.44-x86-1.txz',
    'predecessor_sha256':'3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
    'target_artifact':'kernel-headers-6.18.45-x86-1.txz',
    'target_sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'signing_key_fingerprint':'EC5649DA401E22ABFA6736EF6A4463C040102233'
  },
  'builder_design':{
    'state':'reviewed-awaiting-design-freeze',
    'builder_path':'tools/reference/phase-1-kernel-package-edge-local-source-build.sh',
    'builder_implementation_state':'not-implemented',
    'execution_target':'slackware-current-target-vm',
    'privilege_boundary':'root-via-sudo',
    'execution_acknowledgement':'--build-local-source',
    'acceptance_root':'/var/tmp/slack-update-acceptance/kernel-package-edge',
    'staging_input_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input',
    'target_input_path':'/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
    'predecessor_input_path':'/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.44-x86-1.txz',
    'accepted_builder_input_artifact_count':1,
    'accepted_builder_input_artifact':'kernel-headers-6.18.45-x86-1.txz',
    'predecessor_is_builder_input':False,
    'predecessor_role':'later-staging-only-never-local-source-candidate',
    'local_source_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'runtime_mirror_uri':'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'temporary_build_root_pattern':'/var/tmp/slack-update-acceptance/kernel-package-edge/.local-source.build.XXXXXX',
    'tree_manifest_path':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256',
    'tree_manifest_sha256_path':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256',
    'target_relative_path':'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
    'required_top_level_metadata':['ChangeLog.txt','FILELIST.TXT','PACKAGES.TXT','CHECKSUMS.md5'],
    'exact_package_candidate_count':1,
    'exact_package_candidate':'kernel-headers-6.18.45-x86-1.txz',
    'generated_metadata_is_upstream_signed':False,
    'artifact_authenticity_source':'frozen-step-197-package-and-detached-signature-binding',
    'runtime_must_not_depend_on_generated_metadata_for_artifact_authenticity':True,
    'runtime_network_access_allowed':False,
    'deterministic_generation':{
      'wall_clock_time_embedded':False,'hostname_embedded':False,'boot_id_embedded':False,
      'locale':'C','umask':'022','sorted_manifest_paths':True,
      'source_tree_promoted_only_after_validation':True,'existing_final_tree_overwrite_allowed':False
    },
    'input_guards':{
      'target_input_must_be_regular_file':True,'target_input_symlink_allowed':False,
      'target_input_sha256_must_match_frozen_binding':True,'target_input_filename_must_match_frozen_binding':True,
      'output_root_must_not_preexist':True,'builder_may_modify_external_evidence_root':False,'builder_may_access_network':False
    },
    'metadata_contract':{
      'packages_txt_exact_stanza_count':1,'packages_txt_package_name':'kernel-headers-6.18.45-x86-1.txz',
      'packages_txt_package_location':'./slackware64/d','packages_txt_requires_compressed_size_kib':True,
      'packages_txt_requires_uncompressed_size_kib':True,'packages_txt_description_source':'install/slack-desc-from-bound-target-package',
      'filelist_txt_must_enumerate_target_package_path':True,'filelist_txt_must_not_expose_second_package_archive':True,
      'checksums_md5_must_bind_target_package':True,'changelog_txt_must_be_nonempty':True,'changelog_txt_must_be_deterministic':True,
      'metadata_signature_check_may_be_disabled_only_inside_bound_runtime_configuration':True
    },
    'finalization_contract':{
      'all_regular_files_sha256_manifest_required':True,'manifest_is_outside_source_tree':True,'manifest_sha256_required':True,
      'final_tree_directory_mode':'0555','final_tree_regular_file_mode':'0444','final_tree_owner':'root:root',
      'tree_must_be_read_only_before_runtime':True,'tree_must_verify_unchanged_after_finalization':True,
      'tree_must_verify_unchanged_before_reference_apply':True,'tree_must_verify_unchanged_after_reference_apply':True
    },
    'failure_contract':{
      'fail_closed':True,'may_remove_only_builder_owned_temporary_tree':True,'must_not_delete_preexisting_final_tree':True,
      'must_preserve_staging_inputs':True,'must_not_modify_package_database':True,'must_not_modify_slackpkg_configuration':True,
      'must_not_modify_boot_state':True,'must_not_reboot':True
    }
  },
  'authorization':{
    'builder_design_freeze_authorized_for_next_stage':True,'builder_implementation_authorized':False,
    'target_artifact_copy_authorized':False,'local_source_build_authorized':False,'runtime_candidate_refresh_authorized':False,
    'runtime_scenario_execution_authorized':False,'repository_refresh_authorized':False,'network_refresh_authorized':False,
    'package_action_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,'phase_2_start_authorized':False
  },
  'machine_action_required':False,'pause_safe':False,
  'helper_path':'tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-review.sh',
  'helper_sha256':helper_sha,
  'next_stage':'phase-1-kernel-package-edge-local-source-construction-builder-design-freeze'
}
policy_path.write_text(json.dumps(policy,indent=2,sort_keys=True)+"\n",encoding='utf-8')
rows=[
('step','203'),('revision','deterministic-minimal-file-mirror-builder-design'),('builder_design_state','reviewed-awaiting-design-freeze'),
('fresh_target_binding_state','frozen'),('target_boot_id','d767c4ed-b21f-4c6f-9a1e-db7948c285cf'),
('target_package_database_manifest_sha256','726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'),
('builder_path','tools/reference/phase-1-kernel-package-edge-local-source-build.sh'),('builder_implementation_state','not-implemented'),
('execution_target','slackware-current-target-vm'),('execution_acknowledgement','--build-local-source'),
('acceptance_root','/var/tmp/slack-update-acceptance/kernel-package-edge'),('staging_input_root','/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input'),
('target_input_path','/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'),
('predecessor_input_path','/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.44-x86-1.txz'),
('accepted_builder_input_artifact_count','1'),('accepted_builder_input_artifact','kernel-headers-6.18.45-x86-1.txz'),
('predecessor_is_builder_input','no'),('predecessor_role','later-staging-only-never-local-source-candidate'),
('target_input_sha256','c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'),
('local_source_root','/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'),
('runtime_mirror_uri','file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source'),
('target_relative_path','slackware64/d/kernel-headers-6.18.45-x86-1.txz'),('required_top_level_metadata','ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5'),
('exact_package_candidate_count','1'),('exact_package_candidate','kernel-headers-6.18.45-x86-1.txz'),('packages_txt_package_location','./slackware64/d'),
('packages_txt_description_source','install/slack-desc-from-bound-target-package'),
('tree_manifest_path','/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'),
('tree_manifest_sha256_path','/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256'),
('final_tree_directory_mode','0555'),('final_tree_regular_file_mode','0444'),('final_tree_owner','root:root'),('generated_metadata_is_upstream_signed','no'),
('runtime_network_access_allowed','no'),('existing_final_tree_overwrite_allowed','no'),('builder_may_modify_external_evidence_root','no'),
('builder_may_modify_package_database','no'),('builder_may_modify_slackpkg_configuration','no'),('builder_may_modify_boot_state','no'),('builder_may_reboot','no'),
('builder_design_freeze_authorized_for_next_stage','yes'),('builder_implementation_authorized','no'),('target_artifact_copy_authorized','no'),
('local_source_build_authorized','no'),('runtime_candidate_refresh_authorized','no'),('runtime_scenario_execution_authorized','no'),
('package_action_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('machine_action_required','no'),('pause_safe','no'),
('next_stage','phase-1-kernel-package-edge-local-source-construction-builder-design-freeze')]
with record_path.open('w',encoding='utf-8',newline='') as f:
    csv.writer(f,delimiter='\t',lineterminator='\n').writerows(rows)
PYDATA203
