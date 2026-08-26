#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.sh"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.tsv"
auth_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review-policy.json"
execution_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-policy.json"
execution_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution.tsv"
execution_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery.sh"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.md"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { passes=$((passes + 1)); printf 'PASS: %s\n' "$*"; }
fail() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$*"; }
check_file() { [[ -f "$1" && ! -L "$1" ]] && pass "$2 is a regular non-symlink file" || fail "$2 is missing or unsafe"; }
check_hash() { local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ "$actual" == "$2" ]] && pass "$3 SHA-256 is frozen" || fail "$3 SHA-256 mismatch: $actual"; }
check_output() { local key=$1 value=$2 label=$3; grep -Fqx "$key"$'\t'"$value" <<< "$output" && pass "$label" || fail "$label"; }

for spec in \
    "$helper|step-145 manual-review helper" \
    "$policy|step-145 manual-review policy" \
    "$record|step-145 manual-review record" \
    "$auth_policy|step-143 recovery authorization policy" \
    "$execution_policy|step-144 execution policy" \
    "$execution_record|step-144 execution record" \
    "$execution_harness|step-144 machine harness" \
    "$doc|step-145 reference document" \
    "$changelog|CHANGELOG"; do
    IFS='|' read -r path label <<< "$spec"
    check_file "$path" "$label"
done

if (( failures != 0 )); then
    printf 'Result: FAIL (%d passes, %d failures)\n' "$passes" "$failures"
    exit 1
fi

check_hash "$auth_policy" ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c "step-143 recovery authorization policy"
check_hash "$execution_policy" 4d056fcf9287ffbbdf83ec8b9fc5bb709b781989f59a719639aab77f58c93e6f "step-144 execution policy"
check_hash "$execution_record" 1d4f5a7b5ae5ae21130dec5da6771269cf043ba601094c2c7eae57bbfe8f3adf "step-144 execution record"
check_hash "$execution_harness" 300335ef07df2f091e9b0d8f849f8c65fcece5a134880301d684c36bb10bf12f "step-144 machine harness"
check_hash "$policy" f0976658c0c1a9ffbdb21bc3ec7a6f9157204f7642469488f515d136ff983e90 "step-145 manual-review policy"
check_hash "$record" 4dd611a3fdb2f35724ba5ad4da3305d6ac8c26889baa346ee838d51662bb1bc3 "step-145 manual-review record"
check_hash "$helper" fa677b6cdbee801bb4c6223ed08e464163ee436921877912be3350a3ff0c717d "step-145 manual-review helper"
check_hash "$doc" 26edb7fbf502bc441a6e6cb28761e7d6aabc9d88844a92428c6ef529604faa3d "step-145 reference document"

bash -n "$helper" && pass "the step-145 helper has valid Bash syntax" || fail "the step-145 helper has invalid Bash syntax"
bash -n "${BASH_SOURCE[0]}" && pass "the step-145 harness has valid Bash syntax" || fail "the step-145 harness has invalid Bash syntax"
python3 -m json.tool "$policy" >/dev/null && pass "the step-145 manual-review policy is valid JSON" || fail "the step-145 manual-review policy is invalid JSON"
"$helper" --help >/dev/null && pass "the step-145 helper exposes a non-mutating help boundary" || fail "the step-145 helper help boundary failed"
if "$helper" --invalid >/dev/null 2>&1; then fail "the step-145 helper accepted an unknown option"; else pass "the step-145 helper rejects unknown options"; fi

output=$("$helper" 2>&1) || {
    printf '%s\n' "$output"
    fail "the step-145 manual review did not execute successfully"
    output=''
}
check_output pre_reboot_evidence_sha256 7779072439d48eaace4b3a5b468647887fe89ca173eb78b1cdb0cb5876d9f60f "the pre-reboot evidence identity is authenticated"
check_output post_reboot_evidence_sha256 0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9 "the post-reboot evidence identity is authenticated"
check_output pre_reboot_marker_sha256 9d3a00371ef60a1bcd0a399feba31004a98ba807fbd6445de574bd94f9a48cd7 "the post-reboot review is bound to the accepted handoff marker"
check_output authorization_consumed_by_reboot true "the single recovery authorization is consumed"
check_output authorization_reusable false "the consumed recovery authorization is non-reusable"
check_output boot_selection_mismatch_resolved true "the frozen boot-selection mismatch is resolved"
check_output recovered_live_root_token /dev/sda2 "the recovered live root token matches the frozen entry"
check_output mounted_root_device /dev/sda2 "the recovered mounted root remains the frozen device"
check_output running_kernel 6.18.45 "the recovered kernel remains frozen"
check_output boot_image /boot/vmlinuz-generic "the recovered boot image remains frozen"
check_output system_state_preserved true "the recovery preserved package, Slackpkg, boot, source, and template state"
check_output runtime_probe_invoked false "the recovery did not invoke the runtime probe"
check_output source_remediation_exercised false "the source remediation remains unexercised"
check_output source_remediation_rejected false "the source remediation remains unrejected"
check_output fresh_slackware_current_rerun_authorization_review_required true "a fresh rerun authorization review is required"
check_output slackware_current_rerun_authorized false "step 145 grants no Slackware-current rerun"
check_output slackware_15_execution_authorized false "Slackware 15.0 remains unauthorized"
check_output repository_refresh_required false "manual review requires no Slackware repository refresh"
check_output machine_action_required false "step 145 requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review "manual review advances only to a fresh rerun authorization review"
check_output pause_safe true "the completed recovery review is pause-safe"

if grep -Fq '0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9' "$doc" \
    && grep -Fq '7779072439d48eaace4b3a5b468647887fe89ca173eb78b1cdb0cb5876d9f60f' "$doc" \
    && grep -Fq '9d3a00371ef60a1bcd0a399feba31004a98ba807fbd6445de574bd94f9a48cd7' "$doc"; then
    pass "the reference document binds the review to both authenticated archives and the handoff marker"
else
    fail "the reference document binds the review to both authenticated archives and the handoff marker"
fi
if grep -Fq 'root=UUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863' "$doc" \
    && grep -Fq 'root=/dev/sda2' "$doc" \
    && grep -Fq 'frozen-boot-selection-mismatch' "$doc"; then
    pass "the reference document records the exact root-token recovery"
else
    fail "the reference document records the exact root-token recovery"
fi
if python3 - "$doc" <<'PYDOC1'
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    normalized = " ".join(handle.read().split())
assert "neither exercised nor rejected" in normalized
assert "fresh Slackware-current rerun authorization" in normalized
PYDOC1
then
    pass "the reference document preserves the unexercised runtime-remediation boundary"
else
    fail "the reference document preserves the unexercised runtime-remediation boundary"
fi
if grep -Fq 'consumed step-139 rerun authorization' "$doc" \
    && grep -Fq 'consumed step-143 recovery authorization' "$doc"; then
    pass "the reference document forbids reuse of both consumed authorizations"
else
    fail "the reference document forbids reuse of both consumed authorizations"
fi
if python3 - "$doc" <<'PYDOC2'
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    normalized = " ".join(handle.read().split())
assert "Slackware 15.0 remains held and unauthorized" in normalized
assert "pause_safe=true" in normalized
assert "independent of later Slackware-current publications" in normalized
PYDOC2
then
    pass "the reference document records the held Slackware 15.0 boundary and publication-independent safe pause"
else
    fail "the reference document records the held Slackware 15.0 boundary and publication-independent safe pause"
fi
if grep -F '<!-- step-145-slackware-current-boot-selection-recovery-manual-review:start -->' "$changelog" >/dev/null \
    && grep -Fq '0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9' "$changelog"; then
    pass "CHANGELOG records the authenticated step-145 recovery review"
else
    fail "CHANGELOG records the authenticated step-145 recovery review"
fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "the step-145 helper contains a package, boot, reboot, or shutdown mutation command"
else
    pass "the step-145 helper contains no package, boot, reboot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "the step-145 helper contains a network client command"
else
    pass "the step-145 helper contains no network client command"
fi

if (( failures == 0 )); then
    printf 'Result: PASS (%d passes, %d failures)\n' "$passes" "$failures"
else
    printf 'Result: FAIL (%d passes, %d failures)\n' "$passes" "$failures"
    exit 1
fi
