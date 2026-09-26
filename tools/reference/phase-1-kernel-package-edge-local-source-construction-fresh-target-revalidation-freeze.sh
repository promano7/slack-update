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
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.tsv"
prior_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-r2-probe.sh"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"

[[ -f $prior_policy && ! -L $prior_policy ]] || exit 3
[[ -f $prior_record && ! -L $prior_record ]] || exit 3
[[ -f $prior_probe && ! -L $prior_probe ]] || exit 3
[[ ! -e $builder ]] || { printf 'ERROR: local-source builder must remain unimplemented at step 202\n' >&2; exit 4; }
[[ $(sha256sum "$prior_policy" | awk '{print $1}') == 0d0ce818ea6155e9ed75436baeb16b6a2a993574aa5648cd8dbf5de80dda97fa ]] || exit 5
[[ $(sha256sum "$prior_record" | awk '{print $1}') == d48edf0060acf59be5401f7ab95ffd6da1b2aa509319108533e4b5fe58f28324 ]] || exit 5
[[ $(sha256sum "$prior_probe" | awk '{print $1}') == 93d705080e6698841d613eeb90a2baeca80d000a14af7405f0e219d8d608f3ae ]] || exit 5

[[ -z $output_dir ]] && output_dir=$acceptance_dir
mkdir -p "$output_dir"
policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.tsv"
helper_sha=$(sha256sum "$helper" | awk '{print $1}')

python3 - "$policy" "$record" "$helper_sha" <<'PY'
import csv, json, sys
from pathlib import Path
policy_path=Path(sys.argv[1]); record_path=Path(sys.argv[2]); helper_sha=sys.argv[3]
policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze',
  'revision':'fresh-post-pause-target-binding-freeze',
  'review_only':True,
  'accepted_step_201_r2':{
    'policy_sha256':'0d0ce818ea6155e9ed75436baeb16b6a2a993574aa5648cd8dbf5de80dda97fa',
    'record_sha256':'d48edf0060acf59be5401f7ab95ffd6da1b2aa509319108533e4b5fe58f28324',
    'revalidation_probe_sha256':'93d705080e6698841d613eeb90a2baeca80d000a14af7405f0e219d8d608f3ae'
  },
  'accepted_revalidation_evidence':{
    'status':'PASS',
    'target_hostname':'vbox-slackcurrent.vbox-slackcurrent.org',
    'hostname_fqdn':'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_release':'6.18.45',
    'uname_machine':'x86_64',
    'slackware_version':'Slackware 15.0+',
    'boot_id':'d767c4ed-b21f-4c6f-9a1e-db7948c285cf',
    'reference_script_sha256':'1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
    'effective_config_sha256':'4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'characterized_drift_record':'pCloudDrive-2.3.0-x86_64-1_SBo',
    'recent_installed_record_count':1,
    'recent_removed_record_count':0,
    'header_package_record':'kernel-headers-6.18.45-x86-1',
    'kernel_generic_record':'kernel-generic-6.18.45-x86_64-1',
    'kernel_huge_absent':True,
    'kernel_modules_absent':True,
    'slackpkg_conf_sha256':'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256':'71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'prior_step_194_binding_reused':False,
    'step_201_r1_characterization_consumed':True,
    'network_access_performed':False,
    'repository_refresh_performed':False,
    'package_action_performed':False,
    'boot_action_performed':False,
    'persistent_configuration_change_performed':False,
    'reboot_performed':False
  },
  'artifact_byte_binding':{
    'predecessor_artifact':'kernel-headers-6.18.44-x86-1.txz',
    'predecessor_sha256':'3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
    'target_artifact':'kernel-headers-6.18.45-x86-1.txz',
    'target_sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'signing_key_fingerprint':'EC5649DA401E22ABFA6736EF6A4463C040102233',
    'evidence_root':'/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts',
    'evidence_root_must_remain_unchanged':True
  },
  'fresh_target_binding':{
    'state':'frozen',
    'binding_is_post_pause':True,
    'historical_step_194_binding_reused':False,
    'boot_id_must_match_until_next_machine_action':True,
    'package_manifest_must_match_until_next_machine_action':True,
    'characterized_third_party_record_is_part_of_frozen_environment':True,
    'fresh_candidate_set_bound':False,
    'target_copy_performed':False,
    'local_source_tree_built':False,
    'builder_path':'tools/reference/phase-1-kernel-package-edge-local-source-build.sh',
    'builder_implementation_state':'not-implemented'
  },
  'authorization':{
    'fresh_target_observation_authorized':False,
    'target_artifact_copy_authorized':False,
    'local_source_build_authorized':False,
    'runtime_scenario_execution_authorized':False,
    'repository_refresh_authorized':False,
    'network_refresh_authorized':False,
    'package_action_authorized':False,
    'boot_action_authorized':False,
    'reboot_authorized':False,
    'phase_2_start_authorized':False,
    'repository_only_builder_design_review_authorized':True
  },
  'machine_action_required':False,
  'pause_safe':False,
  'helper_path':'tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.sh',
  'helper_sha256':helper_sha,
  'next_stage':'phase-1-kernel-package-edge-local-source-construction-builder-design-review'
}
policy_path.write_text(json.dumps(policy,indent=2)+'\n',encoding='utf-8')
rows=[
 ('step','202'),('revision',policy['revision']),('revalidation_status','PASS'),
 ('target_hostname','vbox-slackcurrent.vbox-slackcurrent.org'),('uname_release','6.18.45'),('uname_machine','x86_64'),
 ('boot_id','d767c4ed-b21f-4c6f-9a1e-db7948c285cf'),('package_database_manifest_sha256',policy['accepted_revalidation_evidence']['package_database_manifest_sha256']),
 ('characterized_drift_record','pCloudDrive-2.3.0-x86_64-1_SBo'),('header_package_record','kernel-headers-6.18.45-x86-1'),
 ('kernel_generic_record','kernel-generic-6.18.45-x86_64-1'),('kernel_huge_absent','yes'),('kernel_modules_absent','yes'),
 ('slackpkg_conf_sha256',policy['accepted_revalidation_evidence']['slackpkg_conf_sha256']),('slackpkg_mirrors_sha256',policy['accepted_revalidation_evidence']['slackpkg_mirrors_sha256']),
 ('fresh_target_binding','frozen'),('historical_step_194_binding_reused','no'),('fresh_candidate_set_bound','no'),
 ('target_artifact_copy_authorized','no'),('local_source_build_authorized','no'),('runtime_scenario_execution_authorized','no'),
 ('repository_refresh_authorized','no'),('network_refresh_authorized','no'),('package_action_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('repository_only_builder_design_review_authorized','yes'),('machine_action_required','no'),('pause_safe','no'),('next_stage',policy['next_stage'])]
with record_path.open('w',encoding='utf-8',newline='') as f: csv.writer(f,delimiter='\t',lineterminator='\n').writerows(rows)
PY
printf 'policy\t%s\nrecord\t%s\nnext_stage\tphase-1-kernel-package-edge-local-source-construction-builder-design-review\n' "$policy" "$record"
