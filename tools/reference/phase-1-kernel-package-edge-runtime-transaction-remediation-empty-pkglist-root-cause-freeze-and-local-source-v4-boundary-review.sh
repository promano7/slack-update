#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.sh [--output-dir DIR] [--help]

Freeze the accepted empty-pkglist root cause and define the repository-only
local-source-v4 remediation boundary. This helper grants no target observation,
builder implementation/build, package, Slackpkg, network, boot, reboot, cleanup,
or runtime-rerun authority.
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

for path in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$v3_builder" "$helper_path"; do
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

check_hash "$prior_helper" '5fd8be4fcfae7ef061c3c038000ffccec54a85377717175f98befaadf6985ffc'
check_hash "$prior_doc" 'd6de802c3ff0425bbb0a9dd0e83ea1f264f0a529a97c1051d41b9d3e2e2bb6a6'
check_hash "$prior_harness" 'd41be2ccd1c1a62844996064b4c27fd49a6ac547b88d7ec7322aaf075751b211'
check_hash "$prior_policy" '0d93cd3f3ea7ca79995fb1eea2d71d96159dea33a6308144311f63580ad51395'
check_hash "$prior_record" '8fd908b7fedbc61ea5ded315fd11afa9946fe7a2214a86d78971ee408433a3e1'
check_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'

grep -Fq 'md5sum --tag -- "$rel"' "$v3_builder" || { printf 'ERROR: accepted v3 checksum writer drift\n' >&2; exit 5; }
grep -Fq "TARGET_FILENAME='kernel-headers-6.18.45-x86-1.txz'" "$v3_builder" || { printf 'ERROR: accepted v3 target filename drift\n' >&2; exit 5; }
grep -Fq "TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'" "$v3_builder" || { printf 'ERROR: accepted v3 target SHA-256 drift\n' >&2; exit 5; }
grep -Fq "PREDECESSOR_FILENAME='kernel-headers-6.18.44-x86-1.txz'" "$v3_builder" || { printf 'ERROR: accepted v3 predecessor filename drift\n' >&2; exit 5; }
grep -Fq "PACKAGE_LOCATION='./slackware64/d'" "$v3_builder" || { printf 'ERROR: accepted v3 package location drift\n' >&2; exit 5; }

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/source/slackware64/d"
target_rel='./slackware64/d/kernel-headers-6.18.45-x86-1.txz'
printf 'slack-update-step-260-v4-boundary\n' > "$work/source/${target_rel#./}"
(
    cd "$work/source"
    md5sum -- "$target_rel"
) > "$work/untagged-checksum.txt"

[[ $(wc -l < "$work/untagged-checksum.txt") -eq 1 ]] || { printf 'ERROR: synthetic untagged checksum generation failed\n' >&2; exit 6; }
grep -Eq '^[0-9a-f]{32}  \./slackware64/d/kernel-headers-6\.18\.45-x86-1\.txz$' "$work/untagged-checksum.txt" || { printf 'ERROR: unexpected GNU untagged checksum shape\n' >&2; exit 6; }
grep -Eq '\.t[blxg]z$' "$work/untagged-checksum.txt" || { printf 'ERROR: required v4 package checksum does not pass Slackpkg package-line filter\n' >&2; exit 6; }
[[ $(awk '{print $NF}' "$work/untagged-checksum.txt") == "$target_rel" ]] || { printf 'ERROR: required v4 checksum does not expose package path as final field\n' >&2; exit 6; }
if grep -Eq '^MD5 \(' "$work/untagged-checksum.txt"; then
    printf 'ERROR: required v4 checksum unexpectedly uses GNU tagged form\n' >&2
    exit 6
fi

python3 - "$prior_policy" "$prior_record" <<'PY'
import csv
import json
import sys
from pathlib import Path

policy = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
with Path(sys.argv[2]).open(encoding='utf-8', newline='') as handle:
    record = dict(csv.reader(handle, delimiter='\t'))

assert policy['step'] == 259
assert policy['review_status'] == 'PASS'
assert policy['root_cause']['status'] == 'FROZEN'
assert policy['root_cause']['class'] == 'slackpkg-incompatible-tagged-checksums-md5-package-line-format'
assert policy['root_cause']['observed_empty_pkglist_explained_exactly'] is True
assert policy['remediation_direction']['new_local_source_revision_required'] == 'local-source-v4'
assert policy['remediation_direction']['corrected_line_passes_slackpkg_package_line_filter'] is True
assert policy['authorization']['repository_only_root_cause_freeze_and_v4_boundary_review_authorized'] is True
assert policy['authorization']['local_source_v4_builder_implementation_authorized'] is False
assert policy['authorization']['local_source_v4_build_authorized'] is False
assert policy['authorization']['runtime_rerun_authorized'] is False
assert record['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review'
PY

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 7; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
synthetic_line=$(cat "$work/untagged-checksum.txt")

python3 - "$policy" "$record" "$helper_sha" "$synthetic_line" <<'PY'
import csv
import json
import sys
from pathlib import Path

out_policy = Path(sys.argv[1])
out_record = Path(sys.argv[2])
helper_sha = sys.argv[3]
synthetic_line = sys.argv[4]

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review',
    'step': 260,
    'review_only': True,
    'review_status': 'PASS',
    'freeze_status': 'PASS',
    'accepted_step_259': {
        'helper_sha256': '5fd8be4fcfae7ef061c3c038000ffccec54a85377717175f98befaadf6985ffc',
        'document_sha256': 'd6de802c3ff0425bbb0a9dd0e83ea1f264f0a529a97c1051d41b9d3e2e2bb6a6',
        'harness_sha256': 'd41be2ccd1c1a62844996064b4c27fd49a6ac547b88d7ec7322aaf075751b211',
        'policy_sha256': '0d93cd3f3ea7ca79995fb1eea2d71d96159dea33a6308144311f63580ad51395',
        'record_sha256': '8fd908b7fedbc61ea5ded315fd11afa9946fe7a2214a86d78971ee408433a3e1',
    },
    'frozen_root_cause': {
        'status': 'FROZEN_ACCEPTED',
        'class': 'slackpkg-incompatible-tagged-checksums-md5-package-line-format',
        'observed_empty_pkglist_explained_exactly': True,
        'failed_v2_pkglist_sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'candidate_matching_logic_is_not_causal': True,
        'executor_v2_rerun_forbidden': True,
    },
    'historical_evidence': {
        'accepted_local_source_v3_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
        'local_source_v3_builder_sha256': '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30',
        'accepted_local_source_v3_must_remain_unchanged': True,
        'accepted_v3_builder_must_remain_unchanged': True,
        'failed_executor_v2_evidence_must_remain_unchanged': True,
    },
    'local_source_v4_boundary': {
        'revision': 'local-source-v4',
        'derivation_base': 'accepted local-source-v3 builder behavior and invariants',
        'functional_remediation_scope': 'CHECKSUMS.md5 record representation only',
        'checksum_contract': {
            'writer_requirement': 'md5sum -- "$rel"',
            'format': 'GNU untagged MD5 with two-space separator and relative path as final field',
            'applies_to_every_checksum_covered_regular_file': True,
            'tagged_md5_records_forbidden': True,
            'package_path_is_final_field': True,
            'package_line_ends_with_package_extension': True,
            'package_line_passes_slackpkg_terminal_extension_filter': True,
            'synthetic_target_line': synthetic_line,
            'validation_must_bind_every_eligible_regular_file': True,
            'validation_must_reject_missing_duplicate_or_tagged_binding': True,
        },
        'frozen_package_identity': {
            'target_filename': 'kernel-headers-6.18.45-x86-1.txz',
            'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
            'target_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
            'predecessor_filename': 'kernel-headers-6.18.44-x86-1.txz',
            'package_location': './slackware64/d',
        },
        'v4_output_identity': {
            'local_source_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4',
            'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256',
            'tree_manifest_sha256': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256',
            'build_switch': '--build-local-source-v4',
        },
        'preserved_functional_invariants': {
            'exactly_one_package_archive': True,
            'target_package_bytes_and_sha256_unchanged': True,
            'predecessor_package_absent': True,
            'top_level_and_slackware64_package_stanzas_remain_equivalent': True,
            'priority_tree_package_exposure_unchanged': True,
            'filelist_enumerates_generated_regular_files': True,
            'compatibility_asc_retains_PGP_marker_for_slackpkg_gate': True,
            'compatibility_asc_remains_explicitly_non_cryptographic': True,
            'package_authenticity_remains_external_sha256_and_tree_manifest_bound': True,
            'generated_tree_mtimes_remain_deterministic': True,
            'output_paths_must_be_absent_before_build': True,
            'local_only_no_network_behavior': True,
            'no_package_slackpkg_boot_or_reboot_action': True,
        },
        'permitted_revision_identity_changes': [
            'v3-to-v4 builder filename and usage text',
            'v3-to-v4 local-source and external-manifest output paths',
            'v3-to-v4 revision labels in generated descriptive metadata',
            'validation logic required to enforce the untagged checksum contract',
        ],
        'forbidden_scope_expansion': [
            'changing target package bytes or SHA-256',
            'adding predecessor or additional package archives',
            'changing package selection or package location',
            'weakening source-tree or output-path safety checks',
            'adding external network access',
            'adding package, Slackpkg, boot, reboot, or persistent configuration mutation',
            'editing accepted v3 artifacts or failed executor-v2 evidence in place',
        ],
    },
    'future_build_prerequisites': {
        'v4_builder_design_review_required': True,
        'v4_builder_design_freeze_required': True,
        'v4_builder_implementation_review_required': True,
        'v4_builder_implementation_freeze_required': True,
        'fresh_target_revalidation_required_before_build_authorization': True,
        'fresh_absent_v4_output_path_proof_required_before_build_authorization': True,
        'single_use_build_authority_required': True,
        'returned_build_evidence_review_required_before_runtime_work': True,
    },
    'authorization': {
        'repository_only_v4_boundary_review_authorized': False,
        'repository_only_v4_builder_design_review_authorized': True,
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
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.sh',
    'helper_sha256': helper_sha,
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '260'),
    ('revision', 'empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review'),
    ('review_status', 'PASS'),
    ('freeze_status', 'PASS'),
    ('accepted_step_259', 'yes'),
    ('root_cause_status', 'FROZEN_ACCEPTED'),
    ('root_cause_class', policy['frozen_root_cause']['class']),
    ('local_source_revision', 'local-source-v4'),
    ('functional_remediation_scope', 'CHECKSUMS.md5-record-representation-only'),
    ('required_checksum_format', 'GNU-untagged-md5-path-final-field'),
    ('tagged_md5_records_authorized', 'no'),
    ('target_package_bytes_change_authorized', 'no'),
    ('predecessor_or_extra_package_authorized', 'no'),
    ('v4_output_root', policy['local_source_v4_boundary']['v4_output_identity']['local_source_root']),
    ('v4_builder_implementation_authorized', 'no'),
    ('v4_build_authorized', 'no'),
    ('runtime_rerun_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('strong_safe_pause', 'no'),
    ('next_stage', policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'v4_boundary_review_status\tPASS\n'
printf 'root_cause_status\tFROZEN_ACCEPTED\n'
printf 'functional_remediation_scope\tCHECKSUMS.md5-record-representation-only\n'
printf 'required_checksum_format\tGNU-untagged-md5-path-final-field\n'
printf 'local_source_v4_builder_implementation_authorized\tno\n'
printf 'local_source_v4_build_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review\n'
