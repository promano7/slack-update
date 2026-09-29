#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-characterization-freeze-and-strong-safe-pause'
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-characterization-freeze-and-strong-safe-pause.sh --output-dir DIR

Reproduce the frozen step-269 failure characterization and strong safe pause.
This helper is repository-only and grants no machine or build authority.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
req() { local p=$1 e=$2 l=$3 a; [[ -f $p && ! -L $p ]] || fail "$l missing or unsafe"; a=$(sha "$p"); [[ $a == "$e" ]] || fail "$l SHA-256 mismatch: $a"; }
[[ ${1:-} == --help || ${1:-} == -h ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == --output-dir ]] || { usage >&2; exit 2; }
out=$2; [[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be symlink'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.sh" 'da49e1e5688dfc95291fa13a2078d12e7d8ba54220bd9a7d3854964440a764d9' 'accepted step-268 helper'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-probe.sh" '5bebb4e56e3d39d2346a004fe7b5055a208b02ce5673f65d023bb66c44d9ea63' 'accepted step-268 probe'
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.md" 'd836c961acb5b1ac77e7e09e565b0442c82d1c838f6a1719c684bef9b2d9c3b0' 'accepted step-268 document'
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-harness.sh" '91375e62de5bbd1d9c2559125b5b560857c68ab4337556ada1b51839a693b773' 'accepted step-268 harness'
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-policy.json" '78e9f5701fce6a2f876bfe4d245faddb42db10119869d3e5d13837eb76e96f19' 'accepted step-268 policy'
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.tsv" 'f36666492820f274802c03ff57784c844213d72616bc808b90b3abf9bdfd7be1' 'accepted step-268 record'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen v4 builder'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh" 'f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985' 'failed step-267 executor'
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json" "$out/${base}-policy.json"
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv" "$out/${base}.tsv"
printf 'v4_build_launch_failure_characterization_freeze_status\tPASS\n'
printf 'failure_class\tpermission-denied-on-direct-script-exec\n'
printf 'authorization_state\tconsumed-invalidated-no-reuse\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review\n'
