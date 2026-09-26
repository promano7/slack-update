#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh"
expected_policy="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-review-policy.json"
expected_record="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert() { local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }

for f in "$helper" "$probe" "$expected_policy" "$expected_record" "$doc"; do
    assert "$(basename "$f") is a regular file" test -f "$f"
    assert "$(basename "$f") is not a symlink" test ! -L "$f"
done
assert 'step-212 helper passes bash syntax validation' bash -n "$helper"
assert 'step-212 probe passes bash syntax validation' bash -n "$probe"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-212 helper executes successfully'; else fail 'step-212 helper executes successfully'; fi
assert 'generated step-212 policy matches frozen fixture' cmp -s "$tmp/phase-1-kernel-package-edge-post-local-source-build-revalidation-review-policy.json" "$expected_policy"
assert 'generated step-212 record matches frozen fixture' cmp -s "$tmp/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.tsv" "$expected_record"
assert 'helper reports PASS review status' grep -Fqx $'revalidation_review_status\tPASS' "$tmp/helper.out"
assert 'helper authorizes fresh target observation' grep -Fqx $'fresh_target_observation_authorized\tyes' "$tmp/helper.out"
assert 'helper authorizes local-source verification' grep -Fqx $'local_source_tree_revalidation_authorized\tyes' "$tmp/helper.out"
assert 'helper does not bind candidate set' grep -Fqx $'candidate_set_binding_authorized\tno' "$tmp/helper.out"

python3 - "$expected_policy" "$expected_record" "$probe" <<'PY' >"$tmp/semantic.out"
import csv, hashlib, json, pathlib, sys
policy=json.load(open(sys.argv[1]))
with open(sys.argv[2], newline='') as h: record=dict(csv.reader(h, delimiter='\t'))
probe=pathlib.Path(sys.argv[3]).read_bytes()
probe_sha=hashlib.sha256(probe).hexdigest()
checks={
 'policy identifies step-212 scenario': policy['scenario']=='phase-1-kernel-package-edge-post-local-source-build-revalidation-review',
 'probe hash is frozen correctly': policy['probe']['sha256']==probe_sha==record['probe_sha256'],
 'probe is read only': policy['probe']['read_only'] is True,
 'fresh target observation is authorized': policy['authorization']['fresh_target_observation_authorized'] is True,
 'local-source revalidation is authorized': policy['authorization']['local_source_tree_revalidation_authorized'] is True,
 'staged-target revalidation is authorized': policy['authorization']['staged_target_revalidation_authorized'] is True,
 'prior target binding remains expired': policy['expected_target_baseline']['historical_boot_id_reusable'] is False,
 'fresh boot ID is required': policy['expected_target_baseline']['fresh_boot_id_must_be_observed'] is True,
 'bound tree manifest is preserved': policy['local_source_revalidation']['tree_manifest_sha256']=='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
 'single candidate remains required': policy['local_source_revalidation']['expected_candidate_count']==1,
 'builder rerun is forbidden': policy['authorization']['builder_execution_authorized'] is False,
 'candidate binding is forbidden': policy['authorization']['runtime_candidate_binding_authorized'] is False,
 'predecessor staging is forbidden': policy['authorization']['predecessor_package_staging_authorized'] is False,
 'repository refresh is forbidden': policy['authorization']['repository_refresh_authorized'] is False,
 'runtime execution is forbidden': policy['authorization']['runtime_scenario_execution_authorized'] is False,
 'package action is forbidden': policy['authorization']['package_action_authorized'] is False,
 'boot action is forbidden': policy['authorization']['boot_action_authorized'] is False,
 'reboot is forbidden': policy['authorization']['reboot_authorized'] is False,
 'machine action is required': policy['machine_action_required'] is True,
 'step is not safe pause': policy['pause_safe'] is False and policy['strong_safe_pause'] is False,
 'next stage is freeze': policy['next_stage']=='phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze',
}
for label, ok in checks.items(): print(('PASS' if ok else 'FAIL')+'\t'+label)
PY
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

assert 'probe contains no slackpkg execution' bash -c '! grep -Eq "(^|[[:space:]])slackpkg([[:space:]]|$)" "$1"' _ "$probe"
assert 'probe contains no upgradepkg execution' bash -c '! grep -Eq "(^|[[:space:]])upgradepkg([[:space:]]|$)" "$1"' _ "$probe"
assert 'probe contains no reboot command' bash -c '! grep -Eq "(^|[[:space:]])reboot([[:space:]]|$)" "$1"' _ "$probe"
assert 'probe binds expected target SHA-256' grep -Fq 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c' "$probe"
assert 'probe binds expected tree-manifest SHA-256' grep -Fq '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e' "$probe"
assert 'probe verifies tree manifest with sha256sum -c' grep -Fq 'sha256sum -c -- "$manifest"' "$probe"
assert 'probe verifies sidecar with sha256sum -c' grep -Fq 'TREE_MANIFEST_SHA256_FILE' "$probe"
assert 'reference document records read-only gate' grep -Fq 'standalone, read-only revalidation' "$doc"
assert 'CHANGELOG records step 212' grep -Fq '## Phase 1 step 212 kernel-package-edge post-local-source-build revalidation review' "$repo_root/CHANGELOG.md"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
