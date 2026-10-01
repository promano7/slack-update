#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only probe implementation review; no live observation authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
out_absolute=$(cd -- "$out" && pwd -L)
[[ $(readlink -f -- "$out_absolute") == "$out_absolute" ]] || fail 'output directory has a symlink ancestor'
out=$out_absolute
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze.md" "d45a4177811285201c1396b3d9efc5cfc82f1ac81e08462ba95bb2428faa7dd0"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze-policy.json" "2ec01bc01e3d55e35001fdbc170331f3978d02baddc4f4f86f9c0c1f3cf82de5"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze.tsv" "596dd44d0b0d2d98525e58c9abb8ebeb71f435c77e58228f30645d99f6ac9795"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze-freeze.tsv" "515dcecd3bf8b27672085aa4380943599ffe033256be906ac48c9e0bdb19211e"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze.sh" "c0483260b9609542259b2bcb64ebd1c9f38afd8f4955c3b6164508e30314b3d2"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze-harness.sh" "48f8ef34bd20b1bf0c626ef11cdb9ac46b6a3b66e5e5b315e57abe5bcf426c51"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh" "3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv" "f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.md" "c5a5a6c33ce361cbb1405911359d242be114e2e397936c727a072277dc01918f"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-policy.json" "babfb8e7acf5cd11f75e4dc566757fad69deda53f0aca2a51547c6b1fd1ae039"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.tsv" "7b902e4068e37d52b0014ca866308a4d9c0b7b10799ecd7d906151f561c7d76d"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-implementation.tsv" "d82f24218ebf448af92a23dab4fe68a2bcf830d3b457e140c43ac56115a66a48"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh" "fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b"
for suffix in -policy.json .tsv -implementation.tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'implementation-review output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted step282 repository acceptance failed'
fi
grep -Fxq 'Result: PASS (110 passes, 0 failures)' "$acceptance_log" || fail 'step282 acceptance result mismatch'
for suffix in -policy.json .tsv -implementation.tsv; do
    cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base$suffix" "$out/$base$suffix"
done
printf 'step_283_probe_implementation_review_status\tPASS\n'
printf 'accepted_step282_revalidated\tPASS (110 passes, 0 failures)\n'
printf 'implemented_probe_sha256\tfe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b\n'
printf 'production_main_entered\tno\n'
printf 'live_target_observation_performed\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze\n'
