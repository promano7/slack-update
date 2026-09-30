#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only failed-result review and authority closure; no machine action.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze.md" "89c0ba1418f3bc6df7c5b9a60b64634aacea34a2a036a38f77045de6fbfadb2c"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze.sh" "f2820a8897f70dc218d0248576d4dd0f970f8f2a77ba5a1c1afd3305fb5a4c09"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze-harness.sh" "f6f92fd46f1444fc5bac1a7feed9827c52f6df862bd22651c6c40e9f237d315c"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze-policy.json" "f986e83287281f80ebf160680e1673b3bd03c17f74db2a2c9a90adc135554b5d"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze.tsv" "224b0fbec5f2fe5023d47a35b21b46dc277533270d7c018e95b165920268ab3c"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh" "f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review.md" "7b797ef64b2115cc83d54344c6b2f2bc2abf5190aca8b9eb99680a298c02fd37"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-policy.json" "608b26984130bb05bb74cc98489ca000a85db62084d20d0f9c1464a96c2caa9f"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review.tsv" "26213a1611d9a96d9925dca04ce7be98706e07111f16138b55bd998e434d30d6"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv" "f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6"
for suffix in -policy.json .tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'result-review output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted predecessor repository acceptance failed'
fi
grep -Fxq 'Result: PASS (137 passes, 0 failures)' "$acceptance_log" || fail 'predecessor acceptance result differs from the accepted checkpoint'
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base-policy.json" "$out/$base-policy.json"
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base.tsv" "$out/$base.tsv"
printf 'step_279_failed_result_review_status\tPASS\n'
printf 'accepted_predecessor_revalidated\tyes\n'
printf 'build_attempt_result\tpreflight-rejected-before-builder-entry\n'
printf 'build_authority_consumed\tyes\n'
printf 'all_operational_authority_revoked\tyes\n'
printf 'repository_acceptance_production_builder_entered\tno\n'
printf 'current_target_preservation_independently_observed\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review\n'
