#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.sh"
policy="$acc/phase-1-kernel-package-edge-runtime-candidate-set-binding-review-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.md"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.sh"
prior_policy="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.tsv"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }

for f in "$helper" "$policy" "$record" "$doc" "$prior_helper" "$prior_policy" "$prior_record"; do
    assert "$(basename "$f") is a regular file" test -f "$f"
    assert "$(basename "$f") is not a symlink" test ! -L "$f"
done

assert_hash() {
    local label=$1 file=$2 expected=$3 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}
assert_hash 'accepted step-213-r1 helper hash is frozen' "$prior_helper" '7326d5b02b40a2df25ab5b2967fba59405de910075b6febb3422aaceda9b1aa6'
assert_hash 'accepted step-213-r1 policy hash is frozen' "$prior_policy" 'ae790c0b857f64961ed267c19b7db58f33f447c260e0f6659217ddeba32c18eb'
assert_hash 'accepted step-213-r1 record hash is frozen' "$prior_record" 'cad59ab48ed5ea697b130ed084c42c68e51b7ec71212806e24fd33b09ce8ab45'
assert 'step-214 helper passes bash syntax validation' bash -n "$helper"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-214 helper executes successfully'; else fail 'step-214 helper executes successfully'; fi
assert 'generated step-214 policy matches frozen fixture' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'generated step-214 record matches frozen fixture' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS candidate-binding review' grep -Fqx $'candidate_binding_review_status\tPASS' "$tmp/helper.out"
assert 'helper fixes binding time after predecessor staging' grep -Fqx $'candidate_binding_time\tafter-predecessor-staging-and-before-reference-apply' "$tmp/helper.out"
assert 'helper fixes same-transaction lifetime' grep -Fqx $'candidate_binding_lifetime\tsame-runtime-transaction-only' "$tmp/helper.out"
assert 'helper keeps runtime candidate binding unauthorized' grep -Fqx $'runtime_candidate_binding_authorized\tno' "$tmp/helper.out"

python3 - "$policy" "$record" <<'PY' >"$tmp/semantic.out"
import csv
import json
import sys

p = json.load(open(sys.argv[1], encoding='utf-8'))
with open(sys.argv[2], encoding='utf-8', newline='') as handle:
    r = dict(csv.reader(handle, delimiter='\t'))

c = p['candidate_binding_contract']
t = p['runtime_transaction_contract']
a = p['authorization']
f = p['frozen_runtime_identity']
checks = {
    'policy identifies step-214 scenario': p['scenario'] == 'phase-1-kernel-package-edge-runtime-candidate-set-binding-review',
    'step-213-r1 remediation is consumed': p['accepted_step_213_r1']['predecessor_record_remediation_consumed'] is True,
    'fresh boot ID is preserved': f['boot_id'] == '91901677-1dc3-4a39-a4b1-3f87e6875234' and r['fresh_boot_id'] == f['boot_id'],
    'pre-staging header is target version': f['pre_staging_header_record'] == 'kernel-headers-6.18.45-x86-1',
    'predecessor is corrected 6.18.44': f['predecessor_record'] == 'kernel-headers-6.18.44-x86-1' and r['predecessor_record'] == f['predecessor_record'],
    'target remains 6.18.45': f['target_record'] == 'kernel-headers-6.18.45-x86-1',
    'candidate binding occurs only after staging': c['binding_time'] == 'after-predecessor-staging-and-before-reference-apply',
    'candidate binding is same-transaction only': c['binding_lifetime'] == 'same-runtime-transaction-only' and t['candidate_binding_must_be_consumed_without_pause'] is True,
    'durable pre-staging binding is forbidden': c['durable_pre_staging_binding_forbidden'] is True,
    'one header upgrade is required': c['expected_upgrade_count'] == 1 and c['expected_upgrade_package'] == 'kernel-headers',
    'upgrade direction is 6.18.44 to 6.18.45': c['expected_upgrade_from'] == 'kernel-headers-6.18.44-x86-1' and c['expected_upgrade_to'] == 'kernel-headers-6.18.45-x86-1',
    'install-new candidates remain zero': c['expected_install_new_count'] == 0,
    'non-header upgrades remain zero': c['expected_non_header_upgrade_count'] == 0,
    'boot-package upgrades remain zero': c['expected_configured_boot_upgrade_count'] == 0,
    'candidate source is immutable local file source': c['candidate_source_uri'] == 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source' and c['runtime_network_access_allowed'] is False,
    'local source tree binding is preserved': c['local_source_tree_manifest_sha256'] == '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'transaction revalidates before staging': t['required_order'][0] == 'revalidate-frozen-runtime-identity' and 'stage-predecessor-header-only' in t['required_order'],
    'candidate binding precedes reference consumption': t['required_order'].index('bind-exact-candidate-set') < t['required_order'].index('consume-candidate-set-with-reference-apply-or-rollback'),
    'predecessor cannot be successful terminal state': t['predecessor_state_may_not_be_left_as_success_terminal_state'] is True,
    'failure requires target restore': t['failure_requires_target_header_restore'] is True,
    'candidate invalidates on state drift': t['candidate_binding_invalidated_by_any_package_change'] and t['candidate_binding_invalidated_by_boot_id_change'] and t['candidate_binding_invalidated_by_local_source_change'] and t['candidate_binding_invalidated_by_slackpkg_configuration_change'],
    'boot mutation remains forbidden': t['boot_package_mutation_allowed'] is False and t['boot_configuration_mutation_allowed'] is False and t['reboot_allowed'] is False,
    'only executor design review is opened': a['repository_only_runtime_transaction_executor_design_review_authorized'] is True,
    'predecessor staging remains unauthorized': a['predecessor_package_staging_authorized'] is False and a['predecessor_package_transport_authorized'] is False,
    'slackpkg mutation remains unauthorized': a['temporary_slackpkg_configuration_authorized'] is False and a['local_source_metadata_refresh_authorized'] is False,
    'runtime candidate binding remains unauthorized': a['runtime_candidate_binding_authorized'] is False,
    'runtime apply remains unauthorized': a['runtime_scenario_execution_authorized'] is False and a['reference_apply_authorized'] is False,
    'package network boot reboot remain unauthorized': a['package_action_authorized'] is False and a['network_access_authorized'] is False and a['boot_action_authorized'] is False and a['reboot_authorized'] is False,
    'no machine or controller action is required': p['machine_action_required'] is False and p['controller_action_required'] is False,
    'step is not a safe pause': p['pause_safe'] is False and p['strong_safe_pause'] is False,
    'next stage is executor design review': p['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-design-review',
}
for label, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + '\t' + label)
PY
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s ' ')
[[ $normalized_doc == *'truthful upgrade candidate count is therefore zero'* ]] && pass 'reference document explains zero pre-staging upgrade candidates' || fail 'reference document explains zero pre-staging upgrade candidates'
[[ $normalized_doc == *'carried across a pause'* ]] && pass 'reference document requires candidate consumption without pause' || fail 'reference document requires candidate consumption without pause'
[[ $normalized_doc == *'Leaving the predecessor installed is not an acceptable successful terminal state'* ]] && pass 'reference document requires predecessor rollback' || fail 'reference document requires predecessor rollback'
assert 'CHANGELOG records step 214' grep -Fq '## Phase 1 step 214 kernel-package-edge runtime candidate-set binding review' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable package/network/boot/reboot command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
