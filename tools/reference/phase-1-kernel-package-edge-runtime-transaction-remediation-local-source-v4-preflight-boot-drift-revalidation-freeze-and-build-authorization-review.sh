#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review'
usage() { printf 'Usage: %s --output-dir DIR\nRepository observation freeze and build review; no probe rerun or build authority.\n' "${0##*/}"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
req() { local path=$1 expected=$2 actual; [[ -f $path && ! -L $path ]] || fail "missing or unsafe: $path"; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] || fail "SHA-256 mismatch: $path"; }
if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { usage >&2; exit 2; }
out=$2
[[ -d $out && ! -L $out ]] || fail 'output directory must exist and not be a symlink'
out_absolute=$(cd -- "$out" && pwd -L)
[[ $(readlink -f -- "$out_absolute") == "$out_absolute" ]] || fail 'output directory has a symlink ancestor'
out=$out_absolute

req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.md" "71d6b948bca89191b62ec92fca718cd003df05b8833714522850404ead4e7953"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-policy.json" "469e3829e8164465d4b8c7083bb41e51b31476df02e937dcaec28d826aeadb41"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.tsv" "a0511fe1fafaff99d3e9de314dd2bcb0d8ee3f469f58fb596be1e318a88c5d5f"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-authorization.tsv" "f674702d144474695ff8afc13126556fc9da694b6495c09d177b7a4feb68f54d"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.sh" "0623c6f09a8c6dd8eba9e4cdeaac164e628aeb0a93b47e4b09d85e6b9241ba39"
req "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-harness.sh" "857de91f94b5184c6119ab5f72bc67e5260ac24ff3d87b4c3cbf3f8c50060583"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh" "fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh" "3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh" "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7"
req "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh" "43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review-observation.tsv" "2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv" "f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6"
req "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review.md" "39ddf0974017337727ab404cf94a31596081b379e5858c4430bc35aa70c35f1b"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review-policy.json" "51e4b047cefd22871feab2b3df3525b5f400a970c47ae02a014c0f3d2868e3e1"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review.tsv" "7addffd57e960eb657cd096fb3dae49c89bd19f04869803bb248114787aefc10"
req "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review-observation.tsv" "e9be53e174808dfe9e9cdb6e35fcd4eccdbf7c220602cfc4f5cadf939c28a105"
for suffix in -policy.json .tsv -observation.tsv; do
    [[ ! -e "$out/$base$suffix" && ! -L "$out/$base$suffix" ]] || fail 'observation-freeze output already exists'
done
acceptance_log=$(mktemp)
trap 'rm -f -- "$acceptance_log"' EXIT
if ! bash -- "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-harness.sh" > "$acceptance_log" 2>&1; then
    cat -- "$acceptance_log" >&2
    fail 'accepted step285 repository acceptance failed'
fi
grep -Fxq 'Result: PASS (132 passes, 0 failures)' "$acceptance_log" || fail 'step285 acceptance result mismatch'
for suffix in -policy.json .tsv -observation.tsv; do
    cp -- "$repo_root/tests/fixtures/reference/acceptance/phase-1/$base$suffix" "$out/$base$suffix"
done
printf 'step_286_fresh_revalidation_freeze_build_review_status\tPASS\n'
printf 'accepted_step285_revalidated\tPASS (132 passes, 0 failures)\n'
printf 'accepted_observation_frozen\tyes\n'
printf 'accepted_fresh_boot_id\tbcfac4fa-4e6e-450a-aa95-bd591a979b4e\n'
printf 'probe_authority_consumed\tyes\n'
printf 'future_build_authority_granted\tno\n'
printf 'live_target_observation_performed_by_this_helper\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'strong_safe_pause\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze\n'
