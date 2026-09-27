#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
step222_base='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'
step222_helper="$repo_root/tools/reference/${step222_base}.sh"
step222_probe="$repo_root/tools/reference/${step222_base}-probe.sh"
step222_doc="$repo_root/docs/reference/${step222_base}.md"
step222_harness="$repo_root/tests/reference/test-${step222_base}-harness.sh"
step222_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${step222_base}-policy.json"
step222_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${step222_base}.tsv"
step220_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-policy.json"

passes=0
failures=0
assert() {
    local label=$1
    shift
    if "$@"; then
        printf 'PASS: %s\n' "$label"
        passes=$((passes + 1))
    else
        printf 'FAIL: %s\n' "$label"
        failures=$((failures + 1))
    fi
}
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }

for item in "$helper" "$doc" "$policy" "$record"; do
    assert "step-223 ${item##*/} is a regular non-symlink file" regular "$item"
done
for item in "$step222_helper" "$step222_probe" "$step222_doc" "$step222_harness" "$step222_policy" "$step222_record" "$step220_policy"; do
    assert "accepted prerequisite ${item##*/} is a regular non-symlink file" regular "$item"
done

assert 'accepted step-222 helper hash is frozen' hash_is "$step222_helper" '19a9775ca30f5949f7e7e6d63991ae532dbad88a61088d8b6f71bb119573da10'
assert 'accepted step-222 probe hash is frozen' hash_is "$step222_probe" 'e4b90b4379405e08fd05234c24736fc3ac498ddc5d37c57f9a573c15b8cc0c4a'
assert 'accepted step-222 document hash is frozen' hash_is "$step222_doc" 'a95de84218ee31beb9c4a024a462a5dea48d79900200c538b66eab853c3a7f72'
assert 'accepted step-222 harness hash is frozen' hash_is "$step222_harness" '75931da0c8b80c2322791a733194b76073a7c6c93af860bdf0ec9ff66ec94b2a'
assert 'accepted step-222 policy hash is frozen' hash_is "$step222_policy" '13d81956392eaab84c73af1700d6382712fcb7b93e28fcfa8cf59be8b03ecd85'
assert 'accepted step-222 record hash is frozen' hash_is "$step222_record" 'e537a55ede741f2689e85bb4207f6bae5390f8ce6e6a675524c764d8f9830891'
assert 'accepted step-220 remediation policy hash is frozen' hash_is "$step220_policy" 'f52b276f8c93d4e939b7093be95236ba719039dbb5d8d2fae850f3ac810a49a4'
assert 'step-223 helper hash matches generated policy' hash_is "$helper" '31dd91d1319fcd8c0a56a8580ae0665f2844dc02a5a3da39c80fb438681f20ae'
assert 'step-223 frozen policy hash matches overlay' hash_is "$policy" '7f8d68bce758482b9e96b42e9465d5574d37a0d6c0527508dfe66d44d18a75a3'
assert 'step-223 frozen record hash matches overlay' hash_is "$record" '6394ab2be2e303d2e26851065034fc199840a4d701ba87d6b21eb891adc8fac5'
assert 'step-223 helper passes bash syntax validation' bash -n "$helper"
assert 'step-223 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-223 helper rejects unknown option' bash -c '! "$1" --definitely-invalid >/dev/null 2>&1' _ "$helper"

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
assert 'step-223 helper executes successfully' "$helper" --output-dir "$tmp"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/${base}.tsv"

assert 'step-223 policy semantic assertions pass' python3 - "$policy" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema'] == 1
assert p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'
assert p['step'] == 223
assert p['review_status'] == 'PASS'
assert p['accepted_step_222']['returned_probe_result_consumed'] is True
assert p['accepted_step_222']['single_use_observation_authority_consumed'] is True
assert p['accepted_fresh_target_evidence']['revalidation_status'] == 'PASS'
assert p['accepted_fresh_target_evidence']['fresh_boot_id'] == 'cd975bdc-a133-47d1-9e92-e9b51bef9d99'
assert p['accepted_fresh_target_evidence']['package_database_manifest_sha256'] == '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert p['accepted_fresh_target_evidence']['local_source_v1_tree_verified'] is True
assert p['accepted_fresh_target_evidence']['failed_evidence_root_present'] is True
assert p['accepted_fresh_target_evidence']['candidate_set_bound'] is False
assert p['fresh_runtime_identity']['state'] == 'frozen-for-remediation-design'
assert p['fresh_runtime_identity']['historical_step_213_boot_binding_reused'] is False
assert p['fresh_runtime_identity']['historical_step_217_runtime_authorization_reused'] is False
assert p['preservation_contract']['local_source_v1_must_be_preserved_unchanged'] is True
assert p['preservation_contract']['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
assert p['local_source_v2_design_boundary']['state'] == 'repository-only-design-review-authorized'
assert p['local_source_v2_design_boundary']['CHECKSUMS_md5_asc_compatibility_artifact_required'] is True
assert p['local_source_v2_design_boundary']['candidate_guard_scope'] == 'target-specific-not-global-pkglist-row-count'
assert p['authorization']['target_observation_authorized'] is False
assert p['authorization']['repository_only_local_source_v2_design_review_authorized'] is True
for key in ('local_source_v2_builder_implementation_authorized','local_source_v2_build_authorized','runtime_candidate_binding_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized'):
    assert p['authorization'][key] is False, key
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'
PY

while IFS= read -r key; do
    [[ -n $key ]] || continue
    value=$(awk -F '\t' -v k="$key" '$1==k {print $2}' "$record")
    assert "record contains $key" test -n "$value"
done <<'KEYS'
step
review_status
fresh_boot_id
package_database_manifest_sha256
local_source_v1_tree_manifest_sha256
failed_evidence_root_present
repository_only_local_source_v2_design_review_authorized
local_source_v2_build_authorized
runtime_rerun_authorized
package_action_authorized
machine_action_required
pause_safe
next_stage
KEYS

assert 'record freezes step 223' record_is step 223
assert 'record freezes returned observation as consumed' record_is returned_probe_result_consumed yes
assert 'record freezes fresh boot id' record_is fresh_boot_id cd975bdc-a133-47d1-9e92-e9b51bef9d99
assert 'record freezes fresh runtime identity' record_is fresh_runtime_identity frozen-for-remediation-design
assert 'record preserves local-source v1' record_is local_source_v1_must_be_preserved_unchanged yes
assert 'record preserves failed evidence' record_is failed_runtime_evidence_root_must_be_preserved_unchanged yes
assert 'record authorizes repository-only v2 design review' record_is repository_only_local_source_v2_design_review_authorized yes
assert 'record keeps v2 build closed' record_is local_source_v2_build_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record keeps package action closed' record_is package_action_authorized no
assert 'record requires no machine action' record_is machine_action_required no
assert 'record names next stage' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review
assert 'reference document freezes the fresh boot id' grep -Fq 'cd975bdc-a133-47d1-9e92-e9b51bef9d99' "$doc"
assert 'reference document consumes step-222 observation authority' grep -Fq 'single-use step-222 observation authority is consumed and revoked' "$doc"
assert 'reference document keeps design repository-only' grep -Fq 'repository-only design review' "$doc"
assert 'CHANGELOG records step 223' grep -Fq '## Phase 1 step 223 kernel-package-edge runtime-transaction remediation fresh-target revalidation freeze' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable network, package, boot, reboot, or shutdown command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
