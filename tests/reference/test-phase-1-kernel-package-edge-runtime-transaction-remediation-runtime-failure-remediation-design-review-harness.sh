#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
pass=0
fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file() { local p=$1 d=$2; if [[ -f $p && ! -L $p ]]; then ok "$d is a regular non-symlink file"; else bad "$d is missing or unsafe"; fi; }
check_hash() { local p=$1 e=$2 d=$3 a; a=$(sha256sum -- "$p"|awk '{print $1}'); if [[ $a == "$e" ]]; then ok "$d hash is frozen"; else bad "$d hash drifted"; fi; }
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.tsv"
change="$repo_root/CHANGELOG.md"
check_file "$helper" 'step-243 helper'
check_file "$doc" 'step-243 document'
check_file "$policy" 'step-243 policy'
check_file "$record" 'step-243 record'
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.sh" "accepted step-242 helper"
check_file "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.md" "accepted step-242 doc"
check_file "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze-harness.sh" "accepted step-242 harness"
check_file "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze-policy.json" "accepted step-242 policy"
check_file "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.tsv" "accepted step-242 record"
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh" "historical local_source_v2_builder"
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh" "historical failed_executor_body"
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh" "historical failed_executor_builder"
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh" "historical failed_executor"
check_file "$change" CHANGELOG
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.sh" "042b3b925f0de7d583ded59240b54b0f66e5f116c51236ce44b3417f57a6a210" "accepted step-242 helper"
check_hash "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.md" "0f3c9b256d02201c46b7ea81d95d3deeab6423d635da2e9447afc64d378fee59" "accepted step-242 doc"
check_hash "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze-harness.sh" "31ea86e212b2a77c4e95daf557414c91bb4806dedf4a4d331cb04b6092ab3996" "accepted step-242 harness"
check_hash "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze-policy.json" "6b7ae8b27212bd3d5c3a5aeeae7bc2eab828bf14d51f59d8d368e72ee4fd869a" "accepted step-242 policy"
check_hash "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.tsv" "07d5bfa3a6e4fca347c51a83d25a7e7e60015a2b11dc377c9ddc96a5fd50257a" "accepted step-242 record"
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh" "8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d" "historical local_source_v2_builder"
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh" "ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b" "historical failed_executor_body"
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh" "a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379" "historical failed_executor_builder"
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh" "9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c" "historical failed_executor"
check_hash "$helper" "e4cc8a5c270c5e37873df0c7dc28516a3fb1eb861a570c9ab3d8688f82816e34" 'step-243 helper'
check_hash "$doc" "353766a4b1e2119257e672e3256f8b460ce8556cfd7f14e64ce9b12e502c4246" 'step-243 document'
check_hash "$policy" "8dc2bd4f4c82f1337a2dcd01ffbca2581aaf8ff22f389ccff8118f02923d5cac" 'step-243 policy'
check_hash "$record" "47fb0b06cfee9ec98f573b8a3fe2db0b59676607f2c668c3109e2c724efa7d2b" 'step-243 record'
if bash -n "$helper"; then ok 'step-243 helper passes bash syntax validation'; else bad 'step-243 helper bash syntax failed'; fi
if "$helper" --help >/dev/null; then ok 'step-243 helper exposes non-mutating help'; else bad 'step-243 helper help failed'; fi
if "$helper" --definitely-invalid >/dev/null 2>&1; then bad 'step-243 helper accepts unknown option'; else ok 'step-243 helper rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >/dev/null; then ok 'step-243 helper executes successfully'; else bad 'step-243 helper execution failed'; fi
if cmp -s "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-policy.json" "$policy"; then ok 'helper reproduces frozen policy exactly'; else bad 'helper policy output differs'; fi
if cmp -s "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.tsv" "$record"; then ok 'helper reproduces frozen record exactly'; else bad 'helper record output differs'; fi
if python3 - "$policy" "$record" <<'PYSEM'
import csv,json,sys
p=json.load(open(sys.argv[1]))
with open(sys.argv[2],newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['step']==243 and p['review_status']=='PASS'
assert p['confirmed_failure_input']['rollback_baseline_status']=='PASS'
assert p['confirmed_failure_input']['failure_mechanism']=='compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch'
assert p['historical_preservation']['local_source_v2_mutation_authorized'] is False
assert p['historical_preservation']['failed_executor_generation_mutation_authorized'] is False
d=p['remediation_design']
assert d['local_source_generation']=='local-source-v3'
assert d['compatibility_asc']['must_contain_literal_PGP_marker'] is True
assert d['compatibility_asc']['must_not_contain_BEGIN_PGP_SIGNATURE'] is True
assert d['compatibility_asc']['must_not_impersonate_upstream_signature'] is True
assert d['future_executor_generation']['new_generation_required'] is True
assert d['future_executor_generation']['source_generation_must_be_local_source_v3'] is True
assert d['refresh_error_guard']['slackpkg_exit_zero_is_sufficient'] is False
assert d['refresh_error_guard']['actual_human_spaced_error_prefix']=='Error downloading from '
assert d['refresh_error_guard']['hyphenated_literal_guard_retired'] is True
assert d['refresh_error_guard']['fresh_transaction_pkglist_required'] is True
assert d['retained_runtime_invariants']['external_network_forbidden'] is True
assert p['authorization']['repository_failure_remediation_design_freeze_authorized'] is True
assert p['authorization']['local_source_v3_build_authorized'] is False
assert p['authorization']['runtime_rerun_authorized'] is False
assert p['machine_action_required'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze'
assert r['review_status']=='PASS'
assert r['remediation_local_source_generation']=='local-source-v3'
assert r['compatibility_asc_literal_PGP_marker_required']=='yes'
assert r['refresh_error_guard_form']=='human-spaced-Error-downloading-from'
assert r['runtime_rerun_authorized']=='no'
PYSEM
then ok 'step-243 policy and record semantic assertions pass'; else bad 'step-243 semantic assertions failed'; fi
for text in   'local-source-v3'   'PGP compatibility marker for Slackpkg checkchangelog only.'   'MUST NOT contain `BEGIN PGP SIGNATURE`'   'Error downloading from '   'old hyphenated-literal guard is retired'   'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze'; do
  if grep -Fq -- "$text" "$doc"; then ok "reference document records: $text"; else bad "reference document missing: $text"; fi
done
if ! grep -n '[[:blank:]]$' "$doc" "$helper" >/dev/null; then ok 'step-243 document and helper have no trailing whitespace'; else bad 'step-243 files contain trailing whitespace'; fi
if grep -Fq '## Phase 1 step 243 ' "$change"; then ok 'CHANGELOG records step 243'; else bad 'CHANGELOG missing step 243'; fi
if grep -Eq '(^|[;&|])[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown)[[:space:]]' "$helper"; then bad 'step-243 helper contains executable machine/network mutation command'; else ok 'step-243 helper contains no executable machine/network mutation command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
