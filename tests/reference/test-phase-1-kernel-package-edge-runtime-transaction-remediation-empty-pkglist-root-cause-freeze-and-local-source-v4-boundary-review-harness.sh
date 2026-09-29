#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert() { local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }

assert 'step-260 helper exists as regular file' regular "$helper"
assert 'step-260 document exists as regular file' regular "$doc"
assert 'step-260 policy exists as regular file' regular "$policy"
assert 'step-260 record exists as regular file' regular "$record"
assert 'accepted step-259 helper exists as regular file' regular "$prior_helper"
assert 'accepted step-259 document exists as regular file' regular "$prior_doc"
assert 'accepted step-259 harness exists as regular file' regular "$prior_harness"
assert 'accepted step-259 policy exists as regular file' regular "$prior_policy"
assert 'accepted step-259 record exists as regular file' regular "$prior_record"
assert 'accepted v3 builder exists as regular file' regular "$v3_builder"
assert 'CHANGELOG exists as regular file' regular "$changelog"

assert 'accepted step-259 helper SHA-256 matches' sha_is "$prior_helper" '5fd8be4fcfae7ef061c3c038000ffccec54a85377717175f98befaadf6985ffc'
assert 'accepted step-259 document SHA-256 matches' sha_is "$prior_doc" 'd6de802c3ff0425bbb0a9dd0e83ea1f264f0a529a97c1051d41b9d3e2e2bb6a6'
assert 'accepted step-259 harness SHA-256 matches' sha_is "$prior_harness" 'd41be2ccd1c1a62844996064b4c27fd49a6ac547b88d7ec7322aaf075751b211'
assert 'accepted step-259 policy SHA-256 matches' sha_is "$prior_policy" '0d93cd3f3ea7ca79995fb1eea2d71d96159dea33a6308144311f63580ad51395'
assert 'accepted step-259 record SHA-256 matches' sha_is "$prior_record" '8fd908b7fedbc61ea5ded315fd11afa9946fe7a2214a86d78971ee408433a3e1'
assert 'accepted v3 builder SHA-256 remains frozen' sha_is "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'step-260 helper SHA-256 matches' sha_is "$helper" '7c8e4adf631352887d142a984d7433df3550741ad74671071ca875134275c09c'
assert 'step-260 document SHA-256 matches' sha_is "$doc" '336ef9f38fe3d7a4319b769a7ed375169a161d6c2f4302b913bacd12be980fe4'
assert 'step-260 policy SHA-256 matches' sha_is "$policy" '72012226ec638b0cf9da0ab0514b391a88223958cb2c5567ad4aeca356ec9872'
assert 'step-260 record SHA-256 matches' sha_is "$record" '266acba4c83d9a346e032433221776e14d67e7dde5bba49a5bb0da62b95aa780'

assert 'step-260 helper passes bash syntax validation' bash -n "$helper"
assert 'step-260 harness passes bash syntax validation' bash -n "${BASH_SOURCE[0]}"
assert 'step-260 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail 'step-260 helper rejects unknown option'; else pass 'step-260 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp/generated" > "$tmp/helper.out" 2> "$tmp/helper.err"; then pass 'step-260 helper executes successfully'; else cat "$tmp/helper.err" >&2; fail 'step-260 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/generated/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/generated/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review.tsv"
assert 'helper reports PASS v4 boundary review' grep -Fqx $'v4_boundary_review_status\tPASS' "$tmp/helper.out"
assert 'helper accepts frozen root cause' grep -Fqx $'root_cause_status\tFROZEN_ACCEPTED' "$tmp/helper.out"
assert 'helper narrows functional remediation scope' grep -Fqx $'functional_remediation_scope\tCHECKSUMS.md5-record-representation-only' "$tmp/helper.out"
assert 'helper requires untagged path-final checksum format' grep -Fqx $'required_checksum_format\tGNU-untagged-md5-path-final-field' "$tmp/helper.out"
assert 'helper keeps v4 implementation closed' grep -Fqx $'local_source_v4_builder_implementation_authorized\tno' "$tmp/helper.out"
assert 'helper keeps v4 build closed' grep -Fqx $'local_source_v4_build_authorized\tno' "$tmp/helper.out"
assert 'helper keeps runtime rerun closed' grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/helper.out"
assert 'helper requires no machine action' grep -Fqx $'machine_action_required\tno' "$tmp/helper.out"

python3 - "$policy" "$record" > "$tmp/semantic.out" <<'PY'
import csv
import json
import sys

p = json.load(open(sys.argv[1], encoding='utf-8'))
with open(sys.argv[2], encoding='utf-8', newline='') as handle:
    r = dict(csv.reader(handle, delimiter='\t'))
root = p['frozen_root_cause']
b = p['local_source_v4_boundary']
checksum = b['checksum_contract']
ident = b['frozen_package_identity']
out = b['v4_output_identity']
inv = b['preserved_functional_invariants']
prereq = p['future_build_prerequisites']
auth = p['authorization']
checks = {
    'policy identifies step-260 scenario': p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review' and p['step'] == 260,
    'review and freeze status are PASS': p['review_status'] == 'PASS' and p['freeze_status'] == 'PASS' and r['review_status'] == 'PASS' and r['freeze_status'] == 'PASS',
    'step-259 is accepted input': r['accepted_step_259'] == 'yes' and p['accepted_step_259']['policy_sha256'] == '0d93cd3f3ea7ca79995fb1eea2d71d96159dea33a6308144311f63580ad51395',
    'root cause is accepted frozen': root['status'] == 'FROZEN_ACCEPTED' and r['root_cause_status'] == 'FROZEN_ACCEPTED',
    'root cause class remains exact': root['class'] == 'slackpkg-incompatible-tagged-checksums-md5-package-line-format',
    'empty pkglist identity remains frozen': root['failed_v2_pkglist_sha256'] == 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'candidate matching remains non-causal': root['candidate_matching_logic_is_not_causal'] is True,
    'executor-v2 rerun remains forbidden': root['executor_v2_rerun_forbidden'] is True and r['runtime_rerun_authorized'] == 'no',
    'v3 builder remains immutable historical evidence': p['historical_evidence']['accepted_v3_builder_must_remain_unchanged'] is True,
    'v3 source remains immutable historical evidence': p['historical_evidence']['accepted_local_source_v3_must_remain_unchanged'] is True,
    'failed executor-v2 evidence remains immutable': p['historical_evidence']['failed_executor_v2_evidence_must_remain_unchanged'] is True,
    'v4 revision is selected': b['revision'] == 'local-source-v4' and r['local_source_revision'] == 'local-source-v4',
    'functional remediation is checksum representation only': b['functional_remediation_scope'] == 'CHECKSUMS.md5 record representation only' and r['functional_remediation_scope'] == 'CHECKSUMS.md5-record-representation-only',
    'v4 writer requires ordinary md5sum': checksum['writer_requirement'] == 'md5sum -- "$rel"',
    'v4 format is untagged path-final MD5': checksum['format'] == 'GNU untagged MD5 with two-space separator and relative path as final field',
    'v4 checksum applies to every covered file': checksum['applies_to_every_checksum_covered_regular_file'] is True,
    'v4 tagged MD5 records are forbidden': checksum['tagged_md5_records_forbidden'] is True and r['tagged_md5_records_authorized'] == 'no',
    'v4 package path is terminal field': checksum['package_path_is_final_field'] is True,
    'v4 package checksum ends in extension': checksum['package_line_ends_with_package_extension'] is True,
    'v4 package checksum passes Slackpkg filter': checksum['package_line_passes_slackpkg_terminal_extension_filter'] is True,
    'v4 validator must bind all eligible files': checksum['validation_must_bind_every_eligible_regular_file'] is True,
    'v4 validator rejects malformed bindings': checksum['validation_must_reject_missing_duplicate_or_tagged_binding'] is True,
    'target filename remains 6.18.45 headers': ident['target_filename'] == 'kernel-headers-6.18.45-x86-1.txz',
    'target SHA-256 remains frozen': ident['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'target relative path remains frozen': ident['target_relative_path'] == 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
    'predecessor identity remains 6.18.44': ident['predecessor_filename'] == 'kernel-headers-6.18.44-x86-1.txz',
    'package location remains frozen': ident['package_location'] == './slackware64/d',
    'v4 source root is distinct': out['local_source_root'] == '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4',
    'v4 manifest path is distinct': out['tree_manifest'] == '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256',
    'v4 manifest checksum path is distinct': out['tree_manifest_sha256'] == '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256',
    'v4 build switch is distinct': out['build_switch'] == '--build-local-source-v4',
    'exactly one package archive remains required': inv['exactly_one_package_archive'] is True,
    'target package bytes remain unchanged': inv['target_package_bytes_and_sha256_unchanged'] is True and r['target_package_bytes_change_authorized'] == 'no',
    'predecessor remains absent': inv['predecessor_package_absent'] is True and r['predecessor_or_extra_package_authorized'] == 'no',
    'package stanzas remain equivalent': inv['top_level_and_slackware64_package_stanzas_remain_equivalent'] is True,
    'priority tree behavior remains unchanged': inv['priority_tree_package_exposure_unchanged'] is True,
    'FILELIST completeness remains required': inv['filelist_enumerates_generated_regular_files'] is True,
    'compatibility asc retains PGP marker': inv['compatibility_asc_retains_PGP_marker_for_slackpkg_gate'] is True,
    'compatibility asc remains non-cryptographic': inv['compatibility_asc_remains_explicitly_non_cryptographic'] is True,
    'package authenticity remains externally bound': inv['package_authenticity_remains_external_sha256_and_tree_manifest_bound'] is True,
    'generated mtimes remain deterministic': inv['generated_tree_mtimes_remain_deterministic'] is True,
    'v4 output paths must be absent before build': inv['output_paths_must_be_absent_before_build'] is True,
    'v4 remains local only': inv['local_only_no_network_behavior'] is True,
    'v4 performs no package Slackpkg boot or reboot action': inv['no_package_slackpkg_boot_or_reboot_action'] is True,
    'design review is prerequisite': prereq['v4_builder_design_review_required'] is True,
    'design freeze is prerequisite': prereq['v4_builder_design_freeze_required'] is True,
    'implementation review is prerequisite': prereq['v4_builder_implementation_review_required'] is True,
    'implementation freeze is prerequisite': prereq['v4_builder_implementation_freeze_required'] is True,
    'fresh target revalidation is prerequisite': prereq['fresh_target_revalidation_required_before_build_authorization'] is True,
    'fresh v4 output absence proof is prerequisite': prereq['fresh_absent_v4_output_path_proof_required_before_build_authorization'] is True,
    'single-use build authority remains required': prereq['single_use_build_authority_required'] is True,
    'returned build evidence review remains required': prereq['returned_build_evidence_review_required_before_runtime_work'] is True,
    'only v4 builder design review is open': auth['repository_only_v4_builder_design_review_authorized'] is True and auth['repository_only_v4_boundary_review_authorized'] is False,
    'target observation remains closed': auth['target_observation_authorized'] is False and auth['probe_transport_copy_authorized'] is False,
    'v4 implementation and build remain closed': auth['local_source_v4_builder_implementation_authorized'] is False and auth['local_source_v4_build_authorized'] is False,
    'runtime executor build and transport remain closed': auth['runtime_executor_build_authorized'] is False and auth['runtime_executor_transport_authorized'] is False,
    'predecessor transport and staging remain closed': auth['predecessor_package_transport_authorized'] is False and auth['predecessor_package_staging_authorized'] is False,
    'Slackpkg configuration and refresh remain closed': auth['temporary_slackpkg_configuration_authorized'] is False and auth['local_source_metadata_refresh_authorized'] is False and auth['repository_refresh_authorized'] is False,
    'candidate binding and reference apply remain closed': auth['runtime_candidate_binding_authorized'] is False and auth['reference_apply_authorized'] is False,
    'runtime execution remains closed': auth['runtime_scenario_execution_authorized'] is False and auth['runtime_rerun_authorized'] is False,
    'package and Slackpkg mutation remain closed': auth['package_action_authorized'] is False and auth['slackpkg_mutation_authorized'] is False,
    'network remains closed': auth['network_access_authorized'] is False,
    'persistent configuration remains closed': auth['persistent_configuration_change_authorized'] is False,
    'boot and reboot remain closed': auth['boot_action_authorized'] is False and auth['reboot_authorized'] is False,
    'cleanup and Phase 2 remain closed': auth['evidence_cleanup_authorized'] is False and auth['phase_2_start_authorized'] is False,
    'no machine action is required': p['machine_action_required'] is False and r['machine_action_required'] == 'no',
    'no controller action is required': p['controller_action_required'] is False and r['controller_action_required'] == 'no',
    'step 260 is not a strong safe pause': p['pause_safe'] is False and p['strong_safe_pause'] is False and r['pause_safe'] == 'no' and r['strong_safe_pause'] == 'no',
    'next stage is v4 builder design review': p['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review' and r['next_stage'] == p['next_stage'],
}
for label, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + '\t' + label)
PY
while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

# Independent reproduction of the checksum representation frozen for v4.
mkdir -p "$tmp/source/slackware64/d"
target='./slackware64/d/kernel-headers-6.18.45-x86-1.txz'
printf 'synthetic-step-260-package\n' > "$tmp/source/${target#./}"
(cd "$tmp/source" && md5sum -- "$target") > "$tmp/untagged"
assert 'untagged v4 checksum line has expected GNU shape' grep -Eq '^[0-9a-f]{32}  \./slackware64/d/kernel-headers-6\.18\.45-x86-1\.txz$' "$tmp/untagged"
assert 'untagged v4 checksum passes Slackpkg terminal-extension filter' grep -Eq '\.t[blxg]z$' "$tmp/untagged"
assert 'untagged v4 checksum final field is package path' bash -c '[[ $(awk "{print \$NF}" "$1") == "$2" ]]' _ "$tmp/untagged" "$target"
if grep -Eq '^MD5 \(' "$tmp/untagged"; then fail 'untagged v4 checksum contains no tagged MD5 record'; else pass 'untagged v4 checksum contains no tagged MD5 record'; fi

assert 'v3 builder still contains historical tagged writer' grep -Fq 'md5sum --tag -- "$rel"' "$v3_builder"
assert 'v3 builder target identity remains frozen' grep -Fq "TARGET_FILENAME='kernel-headers-6.18.45-x86-1.txz'" "$v3_builder"
assert 'step-260 document freezes checksum representation boundary' grep -Fq 'functional remediation is intentionally narrow' "$doc"
assert 'step-260 document requires path-final package checksum' grep -Fq 'path must be the final whitespace-delimited field' "$doc"
assert 'step-260 document preserves compatibility asc semantics' grep -Fq 'must retain the compatibility `PGP` marker' "$doc"
assert 'step-260 document keeps accepted v3 evidence immutable' grep -Fq 'Accepted v3 artifacts, the accepted v3 builder, and the failed executor-v2 evidence remain immutable historical evidence.' "$doc"
assert 'step-260 document keeps machine actions closed' grep -Fq 'grants no machine or controller action' "$doc"
assert 'CHANGELOG records step 260' grep -Fqx '## Phase 1 step 260 kernel-package-edge runtime-transaction remediation empty-pkglist root-cause freeze and local-source-v4 boundary review — 2026-09-29' "$changelog"

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") contains no trailing whitespace"; else pass "$(basename "$f") contains no trailing whitespace"; fi
done

if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then fail 'step-260 helper contains no executable network package boot reboot or shutdown command'; else pass 'step-260 helper contains no executable network package boot reboot or shutdown command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
