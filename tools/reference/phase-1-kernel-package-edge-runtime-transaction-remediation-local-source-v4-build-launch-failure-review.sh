#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review'
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.sh --output-dir DIR

Reproduce the frozen repository-only review for the step-267 direct-launch failure.
This helper performs no target-machine action and grants no rerun authority.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
req() { local p=$1 e=$2 l=$3 a; [[ -f $p && ! -L $p ]] || fail "$l missing or unsafe"; a=$(sha "$p"); [[ $a == "$e" ]] || fail "$l SHA-256 mismatch: $a"; }
[[ ${1:-} == --help || ${1:-} == -h ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == --output-dir ]] || { usage >&2; exit 2; }
out=$2; [[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be symlink'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.sh" '19e18b03a3ede501479dd6feda45f9abba9ee5b4ac78a51a2f04f185de47e709' 'accepted step-267 helper'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh" 'f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985' 'accepted step-267 executor'
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.md" '52403327b577b910c13c47ce1a36631b92c70e6085ef59cf44847719d6cb6044' 'accepted step-267 document'
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-harness.sh" 'c235f3428b3e7893bc795893d380915a88900b6b229838395b5207bb1a29adb5' 'accepted step-267 harness'
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-policy.json" '8dd97f9e4593c6ecb2081f342c9f0a0af308650eac58abf375c92880a2e1f405' 'accepted step-267 policy'
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.tsv" '5cb4fa2687c238cf88d15539b337da771da06555d2eaba8ea889302132f7c2f1' 'accepted step-267 record'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen v4 builder'
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-probe.sh" '5bebb4e56e3d39d2346a004fe7b5055a208b02ce5673f65d023bb66c44d9ea63' 'step-268 characterization probe'
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-policy.json" "$out/${base}-policy.json"
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.tsv" "$out/${base}.tsv"
printf 'v4_build_launch_failure_review_status\tPASS\n'
printf 'failure_class\tpermission-denied-on-direct-script-exec\n'
printf 'authorization_state\tfailed-at-launch-invalidated\n'
printf 'rerun_authorized\tno\n'
printf 'remediation_candidate\tinvoke-frozen-builder-through-bash\n'
printf 'machine_action_required\tyes-read-only-probe-only\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-characterization-freeze-and-strong-safe-pause\n'
