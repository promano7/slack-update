#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
v2_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.sh [--output-dir DIR] [--help]

Freeze the repository-only root-cause review for the executor-v2 empty pkglist
failure. This helper performs no target observation, package action, Slackpkg
mutation, network access, boot action, reboot, evidence cleanup, or runtime rerun.
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

for path in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$v3_builder" "$v2_body" "$helper_path"; do
    [[ -f $path && ! -L $path ]] || { printf 'ERROR: required repository input is missing or unsafe: %s\n' "$path" >&2; exit 3; }
done

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$prior_helper" 'f112bc1131db22a21d5561a15fd05cb2c9094389e9b27512861df4b3c53396a2'
check_hash "$prior_doc" 'eafe9afb4da73466181bff7e00e58c8416ec9db24c0089cdc1c46d2a113654b1'
check_hash "$prior_harness" 'f2b597c5ffdcd34376a70ab50470316b349aa97e2432119266e36d2df103f323'
check_hash "$prior_policy" '0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc'
check_hash "$prior_record" '20023a8057f7eea1260c22caa8b8dc52e9025f1cc2ff79af94962ca7d4c95bc5'
check_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
check_hash "$v2_body" 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'

grep -Fq 'md5sum --tag -- "$rel"' "$v3_builder" || { printf 'ERROR: accepted v3 builder no longer uses the reviewed tagged checksum writer\n' >&2; exit 5; }
grep -Fq "grep -Fqi 'Error downloading from '" "$v2_body" || { printf 'ERROR: executor-v2 refresh guard drift\n' >&2; exit 5; }
grep -Fq 'fresh pkglist exposes $target_count exact target candidates instead of one' "$v2_body" || { printf 'ERROR: executor-v2 candidate guard drift\n' >&2; exit 5; }

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/source/slackware64/d"
target_rel='./slackware64/d/kernel-headers-6.18.45-x86-1.txz'
printf 'slack-update-step-259-synthetic-package\n' > "$work/source/${target_rel#./}"
(
    cd "$work/source"
    md5sum --tag -- "$target_rel"
) > "$work/tagged-checksum.txt"
(
    cd "$work/source"
    md5sum -- "$target_rel"
) > "$work/untagged-checksum.txt"

[[ $(wc -l < "$work/tagged-checksum.txt") -eq 1 ]] || { printf 'ERROR: synthetic tagged checksum generation failed\n' >&2; exit 6; }
[[ $(wc -l < "$work/untagged-checksum.txt") -eq 1 ]] || { printf 'ERROR: synthetic untagged checksum generation failed\n' >&2; exit 6; }
grep -Eq '^MD5 \(\./slackware64/d/kernel-headers-6\.18\.45-x86-1\.txz\) = [0-9a-f]{32}$' "$work/tagged-checksum.txt" || { printf 'ERROR: unexpected GNU tagged checksum shape\n' >&2; exit 6; }
if grep -Eq '\.t[blxg]z$' "$work/tagged-checksum.txt"; then
    printf 'ERROR: tagged package checksum unexpectedly passes Slackpkg package-line filter\n' >&2
    exit 6
fi
grep -Eq '^[0-9a-f]{32}  \./slackware64/d/kernel-headers-6\.18\.45-x86-1\.txz$' "$work/untagged-checksum.txt" || { printf 'ERROR: unexpected GNU untagged checksum shape\n' >&2; exit 6; }
grep -Eq '\.t[blxg]z$' "$work/untagged-checksum.txt" || { printf 'ERROR: untagged package checksum does not pass Slackpkg package-line filter\n' >&2; exit 6; }
[[ $(awk '{print $NF}' "$work/tagged-checksum.txt") != "$target_rel" ]] || { printf 'ERROR: tagged checksum unexpectedly exposes package path as final field\n' >&2; exit 6; }
[[ $(awk '{print $NF}' "$work/untagged-checksum.txt") == "$target_rel" ]] || { printf 'ERROR: untagged checksum does not expose package path as final field\n' >&2; exit 6; }

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 7; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
tagged_line=$(cat "$work/tagged-checksum.txt")
untagged_line=$(cat "$work/untagged-checksum.txt")

python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" "$tagged_line" "$untagged_line" <<'PY'
import csv
import json
import sys
from pathlib import Path

prior_path = Path(sys.argv[1])
prior_record_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
helper_sha = sys.argv[5]
tagged_line = sys.argv[6]
untagged_line = sys.argv[7]

prior = json.loads(prior_path.read_text(encoding='utf-8'))
with prior_record_path.open(encoding='utf-8', newline='') as handle:
    prior_record = dict(csv.reader(handle, delimiter='\t'))

assert prior['step'] == 258
assert prior['review_status'] == 'PASS'
assert prior['runtime_result'] == 'FAIL_CLOSED'
assert prior['strong_safe_pause'] is True
assert prior['pause_safe'] is True
assert prior['failure_characterization']['root_cause_not_yet_frozen'] is True
assert prior['failure_characterization']['candidate_count'] == 0
assert prior['observed_runtime_result']['slackpkg_refresh']['pkglist_size_bytes'] == 0
assert prior['observed_runtime_result']['slackpkg_refresh']['pkglist_sha256'] == 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
assert prior_record['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review',
    'step': 259,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_258': {
        'helper_sha256': 'f112bc1131db22a21d5561a15fd05cb2c9094389e9b27512861df4b3c53396a2',
        'document_sha256': 'eafe9afb4da73466181bff7e00e58c8416ec9db24c0089cdc1c46d2a113654b1',
        'harness_sha256': 'f2b597c5ffdcd34376a70ab50470316b349aa97e2432119266e36d2df103f323',
        'policy_sha256': '0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc',
        'record_sha256': '20023a8057f7eea1260c22caa8b8dc52e9025f1cc2ff79af94962ca7d4c95bc5',
        'strong_safe_pause_consumed_for_repository_review_only': True,
    },
    'frozen_inputs': {
        'local_source_v3_builder_sha256': '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30',
        'executor_v2_body_sha256': 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68',
        'accepted_local_source_v3_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
        'failed_v2_pkglist_sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    },
    'slackpkg_package_list_contract': {
        'reviewed_source': 'Slackware-current slackpkg core-functions.sh and pkglist.awk',
        'review_date': '2026-09-29',
        'package_list_source': 'CHECKSUMS.md5',
        'package_line_terminal_extension_filter': r'\.t[blxg]z$',
        'pkglist_parser_path_field': 'last whitespace-delimited field',
        'package_path_must_be_terminal_field': True,
    },
    'local_source_v3_checksum_behavior': {
        'writer': 'md5sum --tag -- "$rel"',
        'format': 'GNU tagged MD5',
        'synthetic_target_line': tagged_line,
        'line_ends_with_package_extension': False,
        'last_field_is_package_path': False,
        'last_field_is_digest': True,
        'passes_slackpkg_package_line_filter': False,
    },
    'root_cause': {
        'status': 'FROZEN',
        'class': 'slackpkg-incompatible-tagged-checksums-md5-package-line-format',
        'causal_chain': [
            'accepted local-source-v3 writes CHECKSUMS.md5 in GNU tagged format',
            'tagged package checksum lines end in the MD5 digest rather than the package filename',
            'Slackpkg package-list generation selects CHECKSUMS.md5 lines ending in a Slackware package extension',
            'the v3 target package checksum line is therefore excluded before pkglist.awk parsing',
            'no package row is generated for the only package in local-source-v3',
            'the fresh transaction-owned pkglist is therefore empty',
            'executor-v2 candidate binding correctly fails closed with zero exact target candidates',
        ],
        'observed_empty_pkglist_explained_exactly': True,
        'row_matching_logic_is_not_causal': True,
        'filelist_txt_is_not_the_package_row_source': True,
        'packages_txt_is_not_the_package_row_source': True,
        'slackpkg_exit_zero_is_compatible_with_empty_generated_pkglist': True,
    },
    'remediation_direction': {
        'accepted_local_source_v3_is_immutable_evidence': True,
        'accepted_v3_builder_bytes_must_not_be_modified_in_place': True,
        'failed_executor_v2_evidence_must_be_preserved_unchanged': True,
        'executor_v2_must_not_be_rerun': True,
        'new_local_source_revision_required': 'local-source-v4',
        'required_checksum_format': 'GNU untagged md5sum output with package path as final field',
        'synthetic_corrected_target_line': untagged_line,
        'corrected_line_ends_with_package_extension': True,
        'corrected_last_field_is_package_path': True,
        'corrected_line_passes_slackpkg_package_line_filter': True,
        'package_authenticity_remains_bound_by_frozen_sha256_and_external_tree_manifest': True,
        'compatibility_asc_remains_non-cryptographic': True,
        'future_runtime_requires_new_executor/review_or explicitly re-frozen compatible executor': True,
    },
    'authorization': {
        'repository_only_root_cause_review_authorized': False,
        'repository_only_root_cause_freeze_and_v4_boundary_review_authorized': True,
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'local_source_v4_builder_implementation_authorized': False,
        'local_source_v4_build_authorized': False,
        'runtime_executor_build_authorized': False,
        'runtime_executor_transport_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'repository_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'reference_apply_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'network_access_authorized': False,
        'persistent_configuration_change_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.sh',
    'helper_sha256': helper_sha,
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '259'),
    ('revision', 'empty-pkglist-root-cause-review'),
    ('review_status', 'PASS'),
    ('accepted_step_258', 'yes'),
    ('root_cause_status', 'FROZEN'),
    ('root_cause_class', policy['root_cause']['class']),
    ('v3_checksum_format', 'GNU-tagged-md5'),
    ('v3_package_line_ends_with_extension', 'no'),
    ('v3_package_line_last_field_is_path', 'no'),
    ('v3_package_line_passes_slackpkg_filter', 'no'),
    ('failed_v2_pkglist_size_bytes', '0'),
    ('failed_v2_pkglist_sha256', policy['frozen_inputs']['failed_v2_pkglist_sha256']),
    ('observed_empty_pkglist_explained_exactly', 'yes'),
    ('row_matching_logic_causal', 'no'),
    ('remediation_source_revision', 'local-source-v4'),
    ('required_checksum_format', 'GNU-untagged-md5-path-final-field'),
    ('corrected_package_line_ends_with_extension', 'yes'),
    ('corrected_package_line_last_field_is_path', 'yes'),
    ('corrected_package_line_passes_slackpkg_filter', 'yes'),
    ('runtime_rerun_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('strong_safe_pause', 'no'),
    ('next_stage', policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'root_cause_review_status\tPASS\n'
printf 'root_cause_status\tFROZEN\n'
printf 'root_cause_class\tslackpkg-incompatible-tagged-checksums-md5-package-line-format\n'
printf 'observed_empty_pkglist_explained_exactly\tyes\n'
printf 'remediation_source_revision\tlocal-source-v4\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review\n'
