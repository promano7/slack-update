#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.sh"
policy="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.md"
prior_policy="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }

for f in "$helper" "$policy" "$record" "$doc" "$prior_policy" "$prior_record" "$probe"; do
    assert "$(basename "$f") is a regular file" test -f "$f"
    assert "$(basename "$f") is not a symlink" test ! -L "$f"
done
assert_hash() {
    local label=$1 file=$2 expected=$3 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}
assert_hash 'accepted step-212 policy hash is frozen' "$prior_policy" 'ac920048e3b245ce032edc519521c9aee34f8254b1ccf530837cd4cd57d1028e'
assert_hash 'accepted step-212 record hash is frozen' "$prior_record" 'b1ce8d28abb4c72a548c6ac036f8a78b0c1915490c9930ebf646b9dee9fddff0'
assert_hash 'accepted step-212 probe hash is frozen' "$probe" '44a68d5e63b873c5df836cccb4ffa525852e45a15fda0b332a7ee6ef56899383'
assert 'step-213 helper passes bash syntax validation' bash -n "$helper"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-213 helper executes successfully'; else fail 'step-213 helper executes successfully'; fi
assert 'generated step-213 policy matches frozen fixture' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'generated step-213 record matches frozen fixture' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS freeze status' grep -Fqx $'revalidation_freeze_status\tPASS' "$tmp/helper.out"
assert 'helper freezes runtime identity' grep -Fqx $'fresh_runtime_identity\tfrozen' "$tmp/helper.out"
assert 'helper keeps candidate set unbound' grep -Fqx $'fresh_candidate_set_bound\tno' "$tmp/helper.out"
assert 'helper opens repository-only candidate review' grep -Fqx $'repository_only_candidate_binding_review_authorized\tyes' "$tmp/helper.out"

python3 - "$policy" "$record" <<'PY' >"$tmp/semantic.out"
import csv, json, sys
p=json.load(open(sys.argv[1]))
with open(sys.argv[2], newline='') as h: r=dict(csv.reader(h, delimiter='\t'))
a=p['accepted_revalidation_evidence']; f=p['fresh_runtime_identity']; s=p['preserved_local_source_binding']; c=p['candidate_binding_boundary']; z=p['authorization']
checks={
 'policy identifies step-213 scenario': p['scenario']=='phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze',
 'accepted revalidation status is PASS': a['status']=='PASS' and r['revalidation_status']=='PASS',
 'fresh boot ID is frozen': a['fresh_boot_id']=='91901677-1dc3-4a39-a4b1-3f87e6875234' and f['boot_id']==a['fresh_boot_id'] and r['fresh_boot_id']==a['fresh_boot_id'],
 'package database manifest is frozen': a['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
 'kernel package state is frozen': a['header_package_record']=='kernel-headers-6.18.45-x86-1' and a['kernel_generic_record']=='kernel-generic-6.18.45-x86_64-1' and a['kernel_huge_absent'] and a['kernel_modules_absent'],
 'slackpkg fingerprints are frozen': a['slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' and a['slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
 'staged target hash is frozen': a['staged_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
 'local source tree is revalidated': a['local_source_tree_verified'] and a['tree_manifest_sidecar_verified'] and s['state']=='revalidated-and-frozen',
 'tree manifest hash is frozen': s['tree_manifest_sha256']=='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
 'single candidate contract is preserved': a['single_candidate_contract_verified'] and s['expected_candidate_count']==1,
 'predecessor remains excluded from source': a['predecessor_excluded_from_local_source'] and s['predecessor_excluded'],
 'historical step-202 binding is not reused': f['historical_step_202_binding_reused'] is False and r['historical_step_202_binding_reused']=='no',
 'fresh runtime identity is frozen': f['state']=='frozen' and r['fresh_runtime_identity']=='frozen',
 'candidate set remains unbound': f['fresh_candidate_set_bound'] is False and c['candidate_set_state']=='not-yet-bound' and r['fresh_candidate_set_bound']=='no',
 'fresh candidate binding remains required': c['fresh_candidate_binding_required'] is True,
 'only repository candidate review is opened': z['repository_only_candidate_binding_review_authorized'] is True,
 'runtime candidate binding is still forbidden': z['runtime_candidate_binding_authorized'] is False,
 'predecessor staging is forbidden': z['predecessor_package_staging_authorized'] is False,
 'repository refresh is forbidden': z['repository_refresh_authorized'] is False and z['network_refresh_authorized'] is False,
 'runtime execution is forbidden': z['runtime_scenario_execution_authorized'] is False,
 'package action is forbidden': z['package_action_authorized'] is False and z['slackpkg_configuration_change_authorized'] is False,
 'boot and reboot are forbidden': z['boot_action_authorized'] is False and z['reboot_authorized'] is False,
 'builder and stager execution are forbidden': z['builder_execution_authorized'] is False and z['stager_execution_authorized'] is False,
 'no machine action is required': p['machine_action_required'] is False and r['machine_action_required']=='no',
 'step is not a safe pause': p['pause_safe'] is False and p['strong_safe_pause'] is False,
 'next stage is candidate binding review': p['next_stage']=='phase-1-kernel-package-edge-runtime-candidate-set-binding-review',
}
for label, ok in checks.items(): print(('PASS' if ok else 'FAIL')+'\t'+label)
PY
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

assert 'accepted evidence records no repository refresh' grep -Fq '"repository_refresh_performed": false' "$policy"
assert 'accepted evidence records no package action' grep -Fq '"package_action_performed": false' "$policy"
assert 'accepted evidence records no reboot' grep -Fq '"reboot_performed": false' "$policy"
assert 'reference document records current fresh boot ID' grep -Fq '91901677-1dc3-4a39-a4b1-3f87e6875234' "$doc"
assert 'reference document records candidate set remains unbound' grep -Fq 'fresh candidate set is still not bound' "$doc"
assert 'CHANGELOG records step 213' grep -Fq '## Phase 1 step 213 kernel-package-edge post-local-source-build revalidation freeze' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable network/package/boot/reboot command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
