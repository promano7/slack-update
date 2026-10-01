#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only implementation freeze; no transport or observation authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
out_absolute=$(cd -- "$out" && pwd -L)
[[ $(readlink -f -- "$out_absolute") == "$out_absolute" ]] || fail 'output directory has a symlink ancestor'
out=$out_absolute
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.md" "c5a5a6c33ce361cbb1405911359d242be114e2e397936c727a072277dc01918f"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-policy.json" "babfb8e7acf5cd11f75e4dc566757fad69deda53f0aca2a51547c6b1fd1ae039"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.tsv" "7b902e4068e37d52b0014ca866308a4d9c0b7b10799ecd7d906151f561c7d76d"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-implementation.tsv" "d82f24218ebf448af92a23dab4fe68a2bcf830d3b457e140c43ac56115a66a48"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.sh" "70401fa4fbfb276971797837e47986367cecc9a9bfa45ea2450f517af84c5762"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-harness.sh" "84f126de71c5df56729c23d83c157d14ab920858cc889d27e7e0942c27afbf8a"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh" "fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh" "3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv" "f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.md" "6d9432e9b42ade09eadf2b19ddf1f2814679410002192eafff8262759daf4690"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-policy.json" "321bd93e1ab0ecb39f3a32296f4cea899cfd0d4207e9b318b5933377ce203a2c"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.tsv" "05e8b8aa9e28acef2aeff24c115f6ded9971cfbffffe6071b5a00fca7240cc00"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-freeze.tsv" "2bb3ff796d045b1e5cee34dddecd672417345899b16e44f63965f85ea8f71c2a"
for suffix in -policy.json .tsv -freeze.tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'freeze output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted step283 repository acceptance failed'
fi
grep -Fxq 'Result: PASS (150 passes, 0 failures)' "$acceptance_log" || fail 'step283 acceptance result mismatch'
for suffix in -policy.json .tsv -freeze.tsv; do
    cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base$suffix" "$out/$base$suffix"
done
printf 'step_284_revalidation_probe_implementation_freeze_status\tPASS\n'
printf 'accepted_step283_revalidated\tPASS (150 passes, 0 failures)\n'
printf 'implementation_frozen\tyes\n'
printf 'probe_already_present_from_accepted_step283\tyes\n'
printf 'probe_modified_by_this_step\tno\n'
printf 'live_target_observation_performed\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization\n'
