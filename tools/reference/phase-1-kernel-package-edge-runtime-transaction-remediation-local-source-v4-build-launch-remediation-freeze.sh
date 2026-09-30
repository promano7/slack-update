#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only freeze; no production or machine authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review.md" "a221c53ff739ae33a4a82506c066d5f9abf1e4a126d61aac4fe3833f166e60d7"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review.sh" "0dcd9b34c74b86dbe99b089d82658634d1a53bc5145a7bb6e93c52f6a74f1c25"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review-harness.sh" "aacfaa181929f88bc5d5358b03ac4c8b55d79040e4f98c16246a503dbe8bbea3"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review-policy.json" "c38108622806b5a05ce2ab692354a0f88eecd43ac2416f34965e7d8776b1d7d3"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review.tsv" "796b11953d881c38c2a8d782183f472060742c5a270347c6fa973c6165cfd061"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh" "f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze.md" "dc0f2864bde33fa842f35a0af145b9f6429cb4e2a64769cfc0e113bff6ce0df5"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze-policy.json" "2b5b96f9a1d14e5f606666e86933910034e4cf72d565a140608a08d26451ad43"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze.tsv" "57d2a7fc50b38090c5a03180e198ac065905b6f696389d3359e84b429cad99cf"
for suffix in -policy.json .tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'freeze output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted step-270 repository acceptance failed'
fi
grep -Fxq 'Result: PASS (62 passes, 0 failures)' "$acceptance_log" || fail 'step-270 acceptance result differs from the accepted checkpoint'
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base-policy.json" "$out/$base-policy.json"
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base.tsv" "$out/$base.tsv"
printf 'v4_build_launch_remediation_freeze_status\tPASS\n'
printf 'accepted_step_270_revalidated\tyes\n'
printf 'production_builder_entered\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-review\n'
