#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only review; no machine or production authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze.md" "d52239d80788396a4e59c1481c3827448d200178bffbeb491d5dd28566c9582d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze.sh" "7ec4d490e2e1d92e178dbc99629b110d5b0d67749da1ab6723a3b073753a92a0"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze-harness.sh" "b6415339cada25956c894d585cd6d797a974fdc131c61b51e020853c4cd6dd20"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze-policy.json" "c535148954c549fc3b85542d5b3996e1ceb63d163f18e1ab91a85fb5f67db459"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze.tsv" "3202f397ec0763359de17aff706548a3114586b63c7420b082d13fe5059e7492"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh" "f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review.md" "353aa3c7c2f2217646e3aeb141ea83bf310107674806d65c0c867681b65685b3"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review-policy.json" "a0a6fb6c7fd7de0172d0b6a0e5ef698e7d00ec38088d182b581a4f85d9abc8ce"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review.tsv" "6a9addada4d287e848ba5b9328ed642454c488c2bac489225aa2145e77fdba59"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
for suffix in -policy.json .tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'review output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted predecessor repository acceptance failed'
fi
grep -Fxq 'Result: PASS (59 passes, 0 failures)' "$acceptance_log" || fail 'predecessor acceptance result differs from the accepted checkpoint'
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base-policy.json" "$out/$base-policy.json"
cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base.tsv" "$out/$base.tsv"
printf 'step_274_repository_review_status\tPASS\n'
printf 'accepted_predecessor_revalidated\tyes\n'
printf 'production_builder_entered\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze\n'
