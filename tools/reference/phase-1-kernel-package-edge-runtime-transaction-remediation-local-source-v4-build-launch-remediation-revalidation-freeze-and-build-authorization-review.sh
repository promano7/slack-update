#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only review; no machine or production authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review.md" "6506810d6c0af0a346a33a7febe26b22fe9c676a85263d829811aad14819d7cf"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review.sh" "7a577c288250aa9cce5ac0339c6ab584b5711b17f7ccf9e27d42ecaa4be39f6f"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-harness.sh" "3e929e8258fe32b9123b6f8ac1840c0d5c4acd337b170046b6e61123b99699f3"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-policy.json" "1d800d8c96b7bce11aa2658113437cf691a55338f4a0dea09e5f863d776818ff"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review.tsv" "68f7778a483f6a17130fb1a63ebc6809604dc72f9ad16e87849d612273a39c94"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh" "3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh" "f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review.md" "415a69338e084c909e7aff98581e457cb39287bfa341952a58ca7ba656224379"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-policy.json" "0d942fe037278c778a0c72597b1ca4ecb9da07b166d4a95ffe4fe2e3f9d934ed"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review.tsv" "c92f42b7ff6557ec22d0555a32bb5d8d6d5f8444fb8ea27c6ab3c1559d4bc6c7"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
for suffix in -policy.json .tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'review output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted predecessor repository acceptance failed'
fi
grep -Fxq 'Result: PASS (102 passes, 0 failures)' "$acceptance_log" || fail 'predecessor acceptance result differs from the accepted checkpoint'
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base-policy.json" "$out/$base-policy.json"
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base.tsv" "$out/$base.tsv"
printf 'step_277_repository_review_status\tPASS\n'
printf 'accepted_predecessor_revalidated\tyes\n'
printf 'production_builder_entered\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze\n'
