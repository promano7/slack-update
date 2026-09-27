#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
pass=0
fail=0

ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file() {
  local path=$1 description=$2
  if [[ -f $path && ! -L $path ]]; then ok "$description is a regular non-symlink file"; else bad "$description is missing or unsafe"; fi
}
check_hash() {
  local path=$1 expected=$2 description=$3 actual
  actual=$(sha256sum -- "$path" | awk '{print $1}')
  if [[ $actual == "$expected" ]]; then ok "$description hash is frozen"; else bad "$description hash drifted"; fi
}

helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.tsv"
change="$repo_root/CHANGELOG.md"
step243_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-policy.json"

check_file "$helper" 'step-244 helper'
check_file "$doc" 'step-244 document'
check_file "$policy" 'step-244 policy'
check_file "$record" 'step-244 record'
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.sh" 'accepted step-243 helper'
check_file "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.md" 'accepted step-243 doc'
check_file "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-harness.sh" 'accepted step-243 harness'
check_file "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-policy.json" 'accepted step-243 policy'
check_file "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.tsv" 'accepted step-243 record'
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh" 'historical local_source_v2_builder'
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh" 'historical failed_executor_body'
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh" 'historical failed_executor_builder'
check_file "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh" 'historical failed_executor'
check_file "$change" 'CHANGELOG'
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.sh" 'e4cc8a5c270c5e37873df0c7dc28516a3fb1eb861a570c9ab3d8688f82816e34' 'accepted step-243 helper'
check_hash "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.md" '353766a4b1e2119257e672e3256f8b460ce8556cfd7f14e64ce9b12e502c4246' 'accepted step-243 doc'
check_hash "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-harness.sh" 'e672d76c567d33ff4da914f513ce8da78adb42a370d24b67a9a3fcd68cc78a9a' 'accepted step-243 harness'
check_hash "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-policy.json" '8dc2bd4f4c82f1337a2dcd01ffbca2581aaf8ff22f389ccff8118f02923d5cac' 'accepted step-243 policy'
check_hash "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.tsv" '47fb0b06cfee9ec98f573b8a3fe2db0b59676607f2c668c3109e2c724efa7d2b' 'accepted step-243 record'
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'historical local_source_v2_builder'
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b' 'historical failed_executor_body'
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379' 'historical failed_executor_builder'
check_hash "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' 'historical failed_executor'
check_hash "$helper" '1385b1cdedb54c3084095f366eecf238a68d305aad9419dab2c42fa7a92fe98d' 'step-244 helper'
check_hash "$doc" 'e58d9d00fcc0102b5841699c5db99a819660bef9505d772e319bf7e802e6a40c' 'step-244 document'
check_hash "$policy" '1b4e137ade321f081b16433b2f009a8667e6fc4417dc4fc685e8bfbcf29bc79d' 'step-244 policy'
check_hash "$record" 'e204082d58b7df1ccaa6cacb712b36b4873c14b6b26bf16c1c6050bd613b0047' 'step-244 record'

if bash -n "$helper"; then ok 'step-244 helper passes bash syntax validation'; else bad 'step-244 helper bash syntax failed'; fi
if "$helper" --help >/dev/null; then ok 'step-244 helper exposes non-mutating help'; else bad 'step-244 helper help failed'; fi
if "$helper" --definitely-invalid >/dev/null 2>&1; then bad 'step-244 helper accepts unknown option'; else ok 'step-244 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >/dev/null; then ok 'step-244 helper executes successfully'; else bad 'step-244 helper execution failed'; fi
if cmp -s "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze-policy.json" "$policy"; then ok 'helper reproduces frozen policy exactly'; else bad 'helper policy output differs'; fi
if cmp -s "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.tsv" "$record"; then ok 'helper reproduces frozen record exactly'; else bad 'helper record output differs'; fi

if python3 - "$step243_policy" "$policy" "$record" <<'PYSEM'
import csv
import json
import sys

review = json.load(open(sys.argv[1]))
freeze = json.load(open(sys.argv[2]))
with open(sys.argv[3], newline='') as handle:
    record = dict(csv.reader(handle, delimiter='\t'))

assert freeze['step'] == 244
assert freeze['freeze_status'] == 'PASS'
assert freeze['accepted_step_243']['review_status'] == 'PASS'
assert freeze['confirmed_failure_input'] == review['confirmed_failure_input']
assert freeze['historical_preservation'] == review['historical_preservation']
expected_design = dict(review['remediation_design'])
expected_design['state'] = 'frozen-not-implemented'
assert freeze['frozen_remediation_design'] == expected_design
assert freeze['implementation_sequence'] == review['implementation_sequence']
assert freeze['frozen_remediation_design']['local_source_generation'] == 'local-source-v3'
assert freeze['frozen_remediation_design']['compatibility_asc']['must_contain_literal_PGP_marker'] is True
assert freeze['frozen_remediation_design']['compatibility_asc']['required_marker_text'] == 'PGP compatibility marker for Slackpkg checkchangelog only.'
assert freeze['frozen_remediation_design']['compatibility_asc']['must_not_contain_BEGIN_PGP_SIGNATURE'] is True
assert freeze['frozen_remediation_design']['future_executor_generation']['new_generation_required'] is True
assert freeze['frozen_remediation_design']['future_executor_generation']['source_generation_must_be_local_source_v3'] is True
assert freeze['frozen_remediation_design']['refresh_error_guard']['actual_human_spaced_error_prefix'] == 'Error downloading from '
assert freeze['frozen_remediation_design']['refresh_error_guard']['hyphenated_literal_guard_retired'] is True
assert freeze['frozen_remediation_design']['refresh_error_guard']['fresh_transaction_pkglist_required'] is True
assert freeze['authorization']['repository_failure_remediation_implementation_contract_review_authorized'] is True
for key in (
    'local_source_v3_builder_implementation_authorized',
    'local_source_v3_build_authorized',
    'runtime_executor_v2_implementation_authorized',
    'runtime_executor_transport_authorized',
    'runtime_scenario_execution_authorized',
    'runtime_rerun_authorized',
    'package_action_authorized',
    'slackpkg_mutation_authorized',
    'repository_refresh_authorized',
    'network_access_authorized',
    'boot_action_authorized',
    'reboot_authorized',
    'evidence_cleanup_authorized',
    'phase_2_start_authorized',
):
    assert freeze['authorization'][key] is False
assert freeze['machine_action_required'] is False
assert freeze['controller_action_required'] is False
assert freeze['pause_safe'] is False
assert freeze['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review'
assert record['freeze_status'] == 'PASS'
assert record['remediation_design_state'] == 'frozen-not-implemented'
assert record['remediation_local_source_generation'] == 'local-source-v3'
assert record['refresh_error_guard_form'] == 'human-spaced-Error-downloading-from'
assert record['repository_implementation_contract_review_authorized'] == 'yes'
assert record['local_source_v3_build_authorized'] == 'no'
assert record['runtime_rerun_authorized'] == 'no'
PYSEM
then ok 'step-244 policy and record semantic assertions pass'; else bad 'step-244 semantic assertions failed'; fi

for text in \
  'local-source-v3' \
  'PGP compatibility marker for Slackpkg checkchangelog only.' \
  'MUST NOT contain `BEGIN PGP SIGNATURE`' \
  'Error downloading from ' \
  'old hyphenated-literal guard is retired' \
  'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review'; do
  if grep -Fq -- "$text" "$doc"; then ok "reference document records: $text"; else bad "reference document missing: $text"; fi
done

if ! grep -n '[[:blank:]]$' "$doc" "$helper" >/dev/null; then ok 'step-244 document and helper have no trailing whitespace'; else bad 'step-244 files contain trailing whitespace'; fi
if grep -Fq '## Phase 1 step 244 ' "$change"; then ok 'CHANGELOG records step 244'; else bad 'CHANGELOG missing step 244'; fi
if grep -Eq '(^|[;&|])[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown)[[:space:]]' "$helper"; then
  bad 'step-244 helper contains executable machine/network mutation command'
else
  ok 'step-244 helper contains no executable machine/network mutation command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
