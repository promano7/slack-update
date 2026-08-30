#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.sh"
DOC="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.tsv"
STEP156_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"
STEP156_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization.tsv"
EXECUTION="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
CURRENT_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
CURRENT_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
SOURCE="$repo_root/tools/reference/slack-update-reference.sh"
TEMPLATE="$repo_root/data/config/slack-update.conf"
CHANGELOG="$repo_root/CHANGELOG.md"

check_file() {
    local path=$1 label=$2
    if [[ -f $path && ! -L $path ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
}
check_hash() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')
    if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi
}

check_file "$HELPER" 'step-158 review helper'
check_file "$DOC" 'step-158 reference document'
check_file "$POLICY" 'step-158 review policy'
check_file "$RECORD" 'step-158 review record'
check_file "$STEP156_POLICY" 'step-156 authorization policy'
check_file "$STEP156_RECORD" 'step-156 authorization record'
check_file "$EXECUTION" 'step-157 execution harness'
check_file "$CURRENT_POLICY" 'accepted Slackware-current review policy'
check_file "$CURRENT_RECORD" 'accepted Slackware-current review record'
check_file "$SOURCE" 'accepted remediated reference source'
check_file "$TEMPLATE" 'configuration template'

check_hash "$HELPER" e58e23f2bc3e7911cfb5126b5e0061da1b3fe18c845587610815cc0df3aae46c 'step-158 review helper'
check_hash "$DOC" a9ed56fae62312c887ad00c365ec1bb33cf4126a91a95fd01a86857d4e85c060 'step-158 reference document'
check_hash "$POLICY" 2ead4c6e4b144b7bc6c3f927eaeea8c46160cc8ebdf1054684046767444bd46a 'step-158 review policy'
check_hash "$RECORD" dbeded2f525a52dd4155c41963d8e154b6a4e90917c994c4b4a993d81a1e0ba4 'step-158 review record'
check_hash "$STEP156_POLICY" a01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375 'step-156 authorization policy'
check_hash "$STEP156_RECORD" 6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017 'step-156 authorization record'
check_hash "$EXECUTION" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 'step-157 execution harness'
check_hash "$CURRENT_POLICY" de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b 'accepted Slackware-current review policy'
check_hash "$CURRENT_RECORD" 9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361 'accepted Slackware-current review record'
check_hash "$SOURCE" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 'accepted remediated reference source'
check_hash "$TEMPLATE" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba 'configuration template'

if bash -n "$HELPER"; then pass 'step-158 review helper is shell-syntax valid'; else fail 'step-158 review helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-158 helper exposes a non-mutating help boundary'; else fail 'step-158 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-158 helper accepts unknown options'; else pass 'step-158 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-158 review policy is valid JSON'; else fail 'step-158 review policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-158 Slackware 15.0 rerun review completed successfully'; else fail 'step-158 review helper failed'; printf '%s\n' "$output"; fi

expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'evidence_archive_sha256\t8a740eb47558c13fb418cb460c581ed45a7d2d3ad73f1e7b6f0b62560741ef4d' 'review authenticates the uploaded evidence archive'
expect_line $'runtime_probe_invoked\ttrue' 'review records that the runtime probe ran'
expect_line $'runtime_probe_accepted\ttrue' 'review accepts the runtime probe result'
expect_line $'boot_module_state\tunavailable' 'review preserves the live fail-closed module state'
expect_line $'boot_module_run\t0' 'review preserves the non-runnable fail-closed verdict'
expect_line $'system_state_preserved\ttrue' 'review accepts non-mutation evidence'
expect_line $'authorization_consumed\ttrue' 'review records the single-use authorization as consumed'
expect_line $'authorization_reusable\tfalse' 'review forbids authorization reuse'
expect_line $'characterization_remediation_accepted\ttrue' 'review accepts the corrected characterization boundary'
expect_line $'slackware_15_runtime_validation_accepted\ttrue' 'Slackware 15.0 runtime validation is accepted'
expect_line $'slackware_current_runtime_validation_accepted\ttrue' 'Slackware-current runtime validation remains accepted'
expect_line $'mandatory_targets_accepted\ttrue' 'both mandatory Slackware targets are accepted'
expect_line $'machine_execution_authorized\tfalse' 'review grants no further machine execution'
expect_line $'repository_refresh_required\tfalse' 'review requires no repository refresh'
expect_line $'machine_action_required\tfalse' 'review requires no machine action'
expect_line $'future_work_requires_fresh_boundary\ttrue' 'future work requires a fresh boundary'
expect_line $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-closure-review' 'review advances only to global runtime-validation closure review'
expect_line $'pause_safe\ttrue' 'step-158 checkpoint is pause-safe'

if python3 - "$POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
assert p['evidence']['archive_sha256'] == '8a740eb47558c13fb418cb460c581ed45a7d2d3ad73f1e7b6f0b62560741ef4d'
assert p['evidence']['summary_sha256'] == '76a682f804a2a9564887fda61734a73ff16b479c2de825df5bf7b7fdee9e15c9'
assert p['evidence']['runtime_probe_sha256'] == 'dc5dce686e24ba5c61c91a50055e9502ad44ccd36d5f962a37ae6efc2e34d806'
assert p['evidence']['packages_before_sha256'] == p['evidence']['packages_after_sha256']
assert p['evidence']['slackpkg_metadata_before_sha256'] == p['evidence']['slackpkg_metadata_after_sha256']
assert p['evidence']['boot_state_before_sha256'] == p['evidence']['boot_state_after_sha256']
assert p['evidence']['source_before_record_sha256'] == p['evidence']['source_after_record_sha256']
assert p['evidence']['template_before_record_sha256'] == p['evidence']['template_after_record_sha256']
assert p['slackware_15']['expected_runtime_verdict']['boot_grub_available'] == 1
assert p['characterization_remediation']['historical_exact_capability_vector_required'] is False
assert p['cross_target_runtime_validation']['mandatory_targets_accepted'] is True
assert p['pause_safe'] is True
PY
then pass 'review policy freezes authenticated evidence, non-mutation, corrected semantics, and cross-target acceptance'; else fail 'review policy semantic assertions failed'; fi

if grep -Fq 'Step 158' "$DOC"     && grep -Fq '8a740eb47558c13fb418cb460c581ed45a7d2d3ad73f1e7b6f0b62560741ef4d' "$DOC"     && grep -Fq 'both mandatory targets' "$DOC"     && grep -Fq '`pause_safe=true`' "$DOC"     && grep -Fq 'strong safe pause' "$DOC"; then
    pass 'reference document records the accepted evidence and strong safe pause'
else
    fail 'step-158 reference document is incomplete'
fi

if grep -Fq 'Phase 1 step 158' "$CHANGELOG" && grep -Fq 'characterization-remediated rerun review' "$CHANGELOG"; then pass 'CHANGELOG records step 158'; else fail 'CHANGELOG does not record step 158'; fi

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-158 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-158 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-158 helper contains a network client command'; else pass 'step-158 helper contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
