#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.tsv"
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh"
reference_file="$repo_root/tools/reference/slack-update-reference.sh"
config_file="$repo_root/data/config/slack-update.conf"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.sh [--output-dir DIR] [--help]

Review the repository-only implementation of the remediated Phase 1
kernel-package-edge runtime executor. The review freezes the new generation
body, builder, canonical payload, and repository acceptance result while
preserving the failed executor generation unchanged. It grants no build
transport, package, Slackpkg, network, boot, reboot, or runtime-rerun authority.
USAGE
}

while (($#)); do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" \
         "$old_body" "$old_builder" "$old_executor" "$body" "$builder" "$executor" \
         "$acceptance_harness" "$reference_file" "$config_file" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input is missing or unsafe: %s\n' "$f" >&2; exit 3; }
done

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$prior_helper" 'f76b7e618c879565cc9e8483a7db435eb16826d39d96506702ed0ab63c9e94cb'
check_hash "$prior_doc" '3ae3393f2ae2c991e1396fefa24e52ba50b887f4e6a93a3761d7898753816b4b'
check_hash "$prior_harness" 'b9b1afd118dc06f13ee50e9b713d0260e3504e2fb66284dfbdd61d29418bd7d5'
check_hash "$prior_policy" '0a861ac5ca77f427664ae521245d91cf209bfc92099a7cedb2f47cb250d7a559'
check_hash "$prior_record" '68fe35a6d3ae05325307033178d7cf0f151cf1f2d1d56058c46c71162dcb6269'
check_hash "$old_body" '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
check_hash "$old_builder" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
check_hash "$old_executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
check_hash "$body" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
check_hash "$builder" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
check_hash "$executor" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
check_hash "$acceptance_harness" '9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652'
check_hash "$reference_file" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
check_hash "$config_file" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

prior_policy_path, prior_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
prior = json.loads(prior_policy_path.read_text(encoding='utf-8'))
with prior_record_path.open(encoding='utf-8', newline='') as handle:
    prior_record = dict(csv.reader(handle, delimiter='\t'))

assert prior['step'] == 236
assert prior['review_status'] == 'PASS'
assert prior['remediated_executor_design']['state'] == 'design-reviewed-not-implemented'
assert prior['remediated_executor_design']['candidate_guard']['global_pkglist_row_count_guard_forbidden'] is True
assert prior['implementation_boundary']['repository_only_implementation_review_authorized'] is True
assert prior['implementation_boundary']['machine_runtime_authorization_requires_later_explicit_step'] is True
assert prior_record['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review',
    'step': 237,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_236': {
        'helper_sha256': 'f76b7e618c879565cc9e8483a7db435eb16826d39d96506702ed0ab63c9e94cb',
        'document_sha256': '3ae3393f2ae2c991e1396fefa24e52ba50b887f4e6a93a3761d7898753816b4b',
        'harness_sha256': 'b9b1afd118dc06f13ee50e9b713d0260e3504e2fb66284dfbdd61d29418bd7d5',
        'policy_sha256': '0a861ac5ca77f427664ae521245d91cf209bfc92099a7cedb2f47cb250d7a559',
        'record_sha256': '68fe35a6d3ae05325307033178d7cf0f151cf1f2d1d56058c46c71162dcb6269',
        'design_consumed_without_change': True,
        'no_machine_authority_inherited': True,
    },
    'historical_failed_executor': {
        'body_sha256': '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581',
        'builder_sha256': '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea',
        'executor_sha256': '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300',
        'preserved_unchanged': True,
        'runtime_authorization_reusable': False,
    },
    'remediated_executor_implementation': {
        'state': 'implemented-reviewed-awaiting-freeze',
        'body_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh',
        'body_sha256': 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b',
        'builder_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh',
        'builder_sha256': 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379',
        'executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
        'executor_sha256': '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c',
        'repository_acceptance_harness_path': 'tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh',
        'repository_acceptance_harness_sha256': '9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652',
        'repository_acceptance_result': 'PASS (118 passes, 0 failures)',
        'payload_reproducibility': 'builder-output-matches-canonical-executor-byte-for-byte',
        'runtime_acknowledgement': '--execute-runtime-remediation-validation',
        'boot_id': 'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9',
        'local_source_generation': 'local-source-v2',
        'local_source_v2_tree_manifest_sha256': 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
        'runtime_evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation',
        'published_archive_path': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz',
    },
    'reviewed_remediations': {
        'isolated_slackpkg_workdir': True,
        'isolated_slackpkg_temp': True,
        'fresh_workdir_pkglist_required': True,
        'canonical_var_lib_pkglist_non_authoritative': True,
        'refresh_exit_status_zero_required': True,
        'error_downloading_from_local_source_forbidden': True,
        'source_tree_revalidated_immediately_before_refresh': True,
        'candidate_guard_scope': 'target-specific-source-backed',
        'pkglist_fields_validated': ['tree', 'name', 'version', 'arch', 'build', 'fullname', 'path', 'extension'],
        'auxiliary_pkglist_rows_without_backing_v2_package_bytes_are_not_candidates': True,
        'exact_target_candidate_row_count': 1,
        'target_candidate_fullname': 'kernel-headers-6.18.45-x86-1',
        'target_candidate_location': './slackware64/d',
        'target_candidate_priority_tree': 'slackware64',
        'install_new_candidate_count': 0,
        'non_header_upgrade_candidate_count': 0,
        'configured_boot_package_upgrade_candidate_count': 0,
        'global_pkglist_row_count_guard_retired': True,
        'candidate_binding_lifetime': 'same-runtime-transaction-only',
        'evidence_encoding': 'real-tab-tsv',
        'historical_failed_evidence_preserved_before_and_after_transaction': True,
        'local_source_v1_preserved_before_and_after_transaction': True,
        'rollback_and_final_invariants_preserved': True,
    },
    'authorization': {
        'repository_only_runtime_executor_implementation_freeze_authorized': True,
        'runtime_executor_build_authorized': False,
        'runtime_executor_transport_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'reference_apply_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'repository_refresh_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
    },
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'future_work_requires_explicit_authorization': True,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze',
}
out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step','237'),
    ('revision','runtime-executor-remediation-implementation-review'),
    ('review_status','PASS'),
    ('accepted_step_236','yes'),
    ('historical_failed_executor_preserved','yes'),
    ('remediated_executor_state','implemented-reviewed-awaiting-freeze'),
    ('remediated_body_sha256','ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'),
    ('remediated_builder_sha256','a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'),
    ('remediated_executor_sha256','9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'),
    ('repository_acceptance_result','PASS (118 passes, 0 failures)'),
    ('runtime_acknowledgement','--execute-runtime-remediation-validation'),
    ('candidate_guard_scope','target-specific-source-backed'),
    ('global_pkglist_row_count_guard','retired'),
    ('auxiliary_pkglist_rows_without_backing_source_bytes','ignored-as-non-candidates'),
    ('target_candidate_row_count','1'),
    ('target_candidate_fullname','kernel-headers-6.18.45-x86-1'),
    ('evidence_encoding','real-tab-tsv'),
    ('runtime_executor_transport_authorized','no'),
    ('runtime_rerun_authorized','no'),
    ('package_action_authorized','no'),
    ('slackpkg_mutation_authorized','no'),
    ('network_access_authorized','no'),
    ('boot_action_authorized','no'),
    ('reboot_authorized','no'),
    ('machine_action_required','no'),
    ('controller_action_required','no'),
    ('pause_safe','no'),
    ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'implementation_review_status\tPASS\n'
printf 'historical_failed_executor_preserved\tyes\n'
printf 'remediated_executor_state\timplemented-reviewed-awaiting-freeze\n'
printf 'repository_acceptance_result\tPASS (118 passes, 0 failures)\n'
printf 'runtime_executor_transport_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze\n'
