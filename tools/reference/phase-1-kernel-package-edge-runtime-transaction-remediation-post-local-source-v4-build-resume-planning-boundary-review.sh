#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review'
usage() { printf 'Usage: %s --output-dir DIR\nRepository-only resume planning; no live observation or runtime authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
out_absolute=$(cd -- "$out" && pwd -L)
[[ $(readlink -f -- "$out_absolute") == "$out_absolute" ]] || fail 'output directory has a symlink ancestor'
out=$out_absolute
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze.md" "fc4697bd52f835002e2e340f3931b8e37ebf2047c61b1d85f7838675dba3dfa8"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause.md" "6b8566ce316c0c424a725556574f60682f11190eb37631b3b770b35356fa8055"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv" "f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze-authorization.tsv" "2844aab2cc35b5d8d2c87a70b5215a482936b31fafef35cd9039f2c4a1283842"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze-policy.json" "2c317d04d9d295f5ef012d9ccb42c8d9e022332f23bb3e298c86b8dfb67d33a7"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze.tsv" "33873839b1253bddaf292d49ea40dda548659aafefc1a9a9373393f496d09d63"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause-policy.json" "1f59e1773194259de7edb6fb1b11ab371047c7f92a2d9669344b9ccdf3beec22"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause-result.tsv" "db2fc3501a701ecd475fa5c824cd512140150770f7a9a456cb210eec6ba1485e"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause.tsv" "869c4eed4424c5c77bc4ada44553c74d250dfc1e868da2a22715449a6333170b"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review-observation.tsv" "e9be53e174808dfe9e9cdb6e35fcd4eccdbf7c220602cfc4f5cadf939c28a105"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze-harness.sh" "dce01943558a572debbbe43bd1be976e0e24d7358708c9b83d73304501e2fca0"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause-harness.sh" "6d704fe5cd8e456f4b712d888e9a895eef0b93b255084b6cdb3e27fee2c3da1b"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh" "3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze.sh" "083b9447c899b7f02293ee484713db4f46d525d096e3aaaf13cb6ea82380d843"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause.sh" "856c53ce04c8027f5c34d436fc647996fab1eff122e6e277ba0cccc4a9d86717"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh" "fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh" "deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review.md" "56754704d9a8cf2d773631766cbd57e81d6ba3319910de4b4b9771495a5f4b0e"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review-policy.json" "d32140a1f849d39bfec460690264e3d674104dc66ad809d03aa37081f658f312"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review.tsv" "64b4657057f0d55376aa06a0769a0f5c9b1c1a2b9622593bdcff93d7dfa587fe"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review-roadmap.tsv" "b053f9296c9e2c735da5f37b5fc95d719642aae49ec318c70462ffa5c1c91e80"
for suffix in -policy.json .tsv -roadmap.tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'planning output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted step288 repository acceptance failed'
fi
grep -Fxq 'Result: PASS (152 passes, 0 failures)' "$acceptance_log" || fail 'step288 acceptance result mismatch'
for suffix in -policy.json .tsv -roadmap.tsv; do
    cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base$suffix" "$out/$base$suffix"
done
printf 'step_289_resume_planning_boundary_review_status\tPASS\n'
printf 'accepted_step288_revalidated\tPASS (152 passes, 0 failures)\n'
printf 'all_prior_operational_authority_revoked\tyes\n'
printf 'live_target_observation_performed\tno\n'
printf 'production_builder_entered\tno\n'
printf 'runtime_attempt_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'pause_safe\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review\n'
