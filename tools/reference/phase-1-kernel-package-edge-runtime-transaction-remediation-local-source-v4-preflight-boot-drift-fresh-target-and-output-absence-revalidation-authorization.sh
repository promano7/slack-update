#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization'
usage() { printf 'Usage: %s --output-dir DIR\nRepository authorization review; one read-only observation only after user repository acceptance.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
out_absolute=$(cd -- "$out" && pwd -L)
[[ $(readlink -f -- "$out_absolute") == "$out_absolute" ]] || fail 'output directory has a symlink ancestor'
out=$out_absolute
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.md" "6d9432e9b42ade09eadf2b19ddf1f2814679410002192eafff8262759daf4690"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-policy.json" "321bd93e1ab0ecb39f3a32296f4cea899cfd0d4207e9b318b5933377ce203a2c"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.tsv" "05e8b8aa9e28acef2aeff24c115f6ded9971cfbffffe6071b5a00fca7240cc00"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-freeze.tsv" "2bb3ff796d045b1e5cee34dddecd672417345899b16e44f63965f85ea8f71c2a"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.sh" "7e2ae2c4cff20ceaf9dbd125f0154ca84a55865795785000ff34da616f928bf7"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-harness.sh" "29e575c99df781a4fab76b0e26a912c7970132e4ecc3b1395d7ac6d9c112a8a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh" "fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh" "3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv" "f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.md" "71d6b948bca89191b62ec92fca718cd003df05b8833714522850404ead4e7953"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-policy.json" "469e3829e8164465d4b8c7083bb41e51b31476df02e937dcaec28d826aeadb41"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.tsv" "a0511fe1fafaff99d3e9de314dd2bcb0d8ee3f469f58fb596be1e318a88c5d5f"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-authorization.tsv" "f674702d144474695ff8afc13126556fc9da694b6495c09d177b7a4feb68f54d"
for suffix in -policy.json .tsv -authorization.tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'authorization output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted step284 repository acceptance failed'
fi
grep -Fxq 'Result: PASS (129 passes, 0 failures)' "$acceptance_log" || fail 'step284 acceptance result mismatch'
for suffix in -policy.json .tsv -authorization.tsv; do
    cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base$suffix" "$out/$base$suffix"
done
printf 'step_285_fresh_revalidation_authorization_review_status\tPASS\n'
printf 'accepted_step284_revalidated\tPASS (129 passes, 0 failures)\n'
printf 'probe_implementation_preserved\tyes\n'
printf 'observation_authority_effective_after_user_repository_acceptance\tyes\n'
printf 'observation_invocation_limit\t1\n'
printf 'live_target_observation_performed\tno\n'
printf 'machine_action_required\tyes\n'
printf 'controller_action_required\tyes\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review\n'
