#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.tsv"
output_dir=''
usage() {
    cat <<'EOF'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-234 repository-only candidate-set binding
review and freeze that contract unchanged for the subsequent repository-only
runtime executor remediation design review. No live candidate set is created
and no machine, package, Slackpkg, network, boot, reboot, or rerun authority is
granted.
EOF
}
while (($#)); do
    case "$1" in
        --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2 ;;
        --help) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input is missing or unsafe: %s\n' "$f" >&2; exit 3; }
done
if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.tsv"
prior_helper_sha=$(sha256sum -- "$prior_helper" | awk '{print $1}')
prior_doc_sha=$(sha256sum -- "$prior_doc" | awk '{print $1}')
prior_harness_sha=$(sha256sum -- "$prior_harness" | awk '{print $1}')
prior_policy_sha=$(sha256sum -- "$prior_policy" | awk '{print $1}')
prior_record_sha=$(sha256sum -- "$prior_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
python3 - "$prior_policy" "$prior_record" "$policy" "$record" \
    "$prior_helper_sha" "$prior_doc_sha" "$prior_harness_sha" \
    "$prior_policy_sha" "$prior_record_sha" "$helper_sha" <<'PYFREEZE'
import csv, json, sys
from pathlib import Path
ppath,rpath,outp,outr=map(Path,sys.argv[1:5])
hsha,dsha,tsha,psha,rsha,helper_sha=sys.argv[5:11]
p=json.loads(ppath.read_text())
with rpath.open(newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review'
assert p['step']==234 and p['review_status']=='PASS'
assert p['candidate_binding_contract']['candidate_set_state_at_step_234']=='not-bound'
assert p['candidate_binding_contract']['global_pkglist_row_count_is_not_an_acceptance_guard'] is True
assert p['candidate_binding_contract']['candidate_guard_scope']=='target-specific'
assert p['authorization']['repository_only_candidate_binding_freeze_authorized'] is True
assert p['authorization']['runtime_candidate_binding_authorized'] is False
assert r['step']=='234' and r['review_status']=='PASS' and r['candidate_set_bound']=='no'
policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze',
  'step':235,
  'review_only':True,
  'freeze_status':'PASS',
  'accepted_step_234':{
    'helper_sha256':hsha,'document_sha256':dsha,'harness_sha256':tsha,'policy_sha256':psha,'record_sha256':rsha,
    'review_status':'PASS','semantics_consumed_without_change':True,'no_machine_authority_inherited':True
  },
  'frozen_runtime_identity':dict(p['frozen_runtime_identity'], state='contract-freeze-input-only'),
  'local_source_v2_binding':dict(p['local_source_v2_binding'], state='frozen-runtime-source-binding'),
  'candidate_binding_freeze_contract':{
    'state':'contract-frozen-live-binding-not-created',
    'accepted_step_234_semantics_must_not_change':True,
    'candidate_set_bound_at_freeze':False,
    'truthful_pre_staging_upgrade_candidate_count':0,
    'predecessor_record':'kernel-headers-6.18.44-x86-1',
    'target_record':'kernel-headers-6.18.45-x86-1',
    'binding_time':'after-exact-predecessor-staging-and-guarded-local-refresh-before-reference-apply',
    'binding_lifetime':'same-runtime-transaction-only',
    'binding_must_be_consumed_without_pause':True,
    'durable_pre_staging_binding_forbidden':True,
    'transaction_owned_new_empty_slackpkg_workdir_required':True,
    'pre_refresh_pkglist_must_be_absent_in_transaction_workdir':True,
    'post_refresh_pkglist_must_be_created_in_transaction_workdir':True,
    'preexisting_var_lib_slackpkg_pkglist_may_not_prove_refresh':True,
    'refresh_exit_status_must_be_zero':True,
    'refresh_output_must_not_contain_error_downloading_from_local_source':True,
    'global_pkglist_row_count_guard_retired':True,
    'candidate_guard_scope':'target-specific',
    'expected_target_candidate_row_count':1,
    'target_candidate_fullname':'kernel-headers-6.18.45-x86-1',
    'target_candidate_location':'./slackware64/d',
    'expected_install_new_candidate_count':0,
    'expected_non_header_upgrade_candidate_count':0,
    'expected_configured_boot_package_upgrade_candidate_count':0,
    'target_source_binding_to_frozen_sha256_and_v2_manifest_required':True,
    'source_tree_manifest_must_verify_immediately_before_refresh':True,
    'external_network_access_forbidden':True,
    'evidence_encoding':'real-tab-tsv',
    'binding_invalidated_by_any_relevant_state_change':True,
  },
  'executor_remediation_design_boundary':{
    'candidate_binding_contract_is_frozen_input':True,
    'repository_only_design_review_authorized':True,
    'design_must_conform_to_frozen_candidate_binding_contract':True,
    'design_review_may_not_authorize_implementation_or_execution':True,
    'executor_remediation_implementation_authorized':False,
    'runtime_rerun_authorized':False,
  },
  'future_transaction_order':p['future_transaction_order'],
  'preservation_contract':p['preservation_contract'],
  'authorization':{
    'repository_only_runtime_executor_remediation_design_review_authorized':True,
    'repository_only_candidate_binding_freeze_authorized':False,
    'target_observation_authorized':False,
    'runtime_candidate_binding_authorized':False,
    'runtime_executor_remediation_authorized':False,
    'runtime_executor_transport_authorized':False,
    'runtime_rerun_authorized':False,
    'package_action_authorized':False,
    'slackpkg_mutation_authorized':False,
    'repository_refresh_authorized':False,
    'network_access_authorized':False,
    'boot_action_authorized':False,
    'reboot_authorized':False,
    'evidence_cleanup_authorized':False,
    'persistent_configuration_change_authorized':False,
    'phase_2_start_authorized':False,
  },
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh',
  'helper_sha256':helper_sha,
  'machine_action_required':False,
  'controller_action_required':False,
  'future_work_requires_explicit_authorization':True,
  'pause_safe':False,
  'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review'
}
Path(outp).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n')
rows=[
 ('step','235'),('revision','runtime-candidate-set-binding-freeze'),('freeze_status','PASS'),
 ('accepted_step_234','yes'),('candidate_binding_contract_frozen','yes'),('candidate_set_bound','no'),
 ('truthful_pre_staging_upgrade_candidate_count','0'),('candidate_source_uri',p['local_source_v2_binding']['mirror_uri']),
 ('local_source_v2_tree_manifest_sha256',p['local_source_v2_binding']['tree_manifest_sha256']),
 ('predecessor_record','kernel-headers-6.18.44-x86-1'),('target_candidate_fullname','kernel-headers-6.18.45-x86-1'),
 ('binding_lifetime','same-runtime-transaction-only'),('workdir_strategy','transaction-owned-new-empty-workdir'),
 ('global_pkglist_row_count_guard','retired'),('candidate_guard_scope','target-specific'),
 ('refresh_exit_status_zero_required','yes'),('refresh_local_source_download_error_forbidden','yes'),
 ('expected_target_candidate_row_count','1'),('expected_install_new_candidate_count','0'),
 ('expected_non_header_upgrade_candidate_count','0'),('expected_configured_boot_package_upgrade_candidate_count','0'),
 ('evidence_encoding','real-tab-tsv'),('repository_only_runtime_executor_remediation_design_review_authorized','yes'),
 ('runtime_candidate_binding_authorized','no'),('runtime_executor_remediation_authorized','no'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('repository_refresh_authorized','no'),
 ('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),
 ('machine_action_required','no'),('controller_action_required','no'),('pause_safe','no'),('strong_safe_pause','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review')]
with Path(outr).open('w',newline='') as h:
    w=csv.writer(h,delimiter='\t',lineterminator='\n'); w.writerows(rows)
PYFREEZE
cat "$record"
