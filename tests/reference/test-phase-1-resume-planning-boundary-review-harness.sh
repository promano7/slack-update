#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-resume-planning-boundary-review.sh"
DOC="$repo_root/docs/reference/phase-1-resume-planning-boundary-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review.tsv"
STEP161_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint-policy.json"
STEP161_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() {
    local file=$1 label=$2
    if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
}
check_hash() {
    local file=$1 expected=$2 label=$3 actual
    if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi
}

for spec in \
    "$HELPER|step-162 boundary helper" \
    "$DOC|step-162 reference document" \
    "$POLICY|step-162 boundary policy" \
    "$RECORD|step-162 boundary record" \
    "$STEP161_POLICY|accepted step-161 closure policy" \
    "$STEP161_RECORD|accepted step-161 closure record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" 'a5f2b1009346621f77d9b3b79f4ad3c49fa6b7772e24af0bc81e164fee0a53f6' 'step-162 boundary helper'
check_hash "$DOC" '63330aa85f257a9e57aeeb052520ad610e419050dbcaf4185063c08a8d3f3cdf' 'step-162 reference document'
check_hash "$POLICY" '47210ad2f1ce84946452c862be172a7e3b803c29772ecf8aae1e693dce4e3ae9' 'step-162 boundary policy'
check_hash "$RECORD" '338ca5c43dd79a02b7362c2a4cd661b4333139351902689c7af4d479a4bdf521' 'step-162 boundary record'
check_hash "$STEP161_POLICY" '0b06a01e33b33da1eba3e6e4566c1b1ea929d801b8c5d1357d93b3e55cbc6fb9' 'accepted step-161 closure policy'
check_hash "$STEP161_RECORD" '3705921dab84bc1dbb47766743d4623d9b575179b4c449d99a4adf460f5d15e8' 'accepted step-161 closure record'

if bash -n "$HELPER"; then pass 'step-162 boundary helper is shell-syntax valid'; else fail 'step-162 boundary helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-162 helper exposes a non-mutating help boundary'; else fail 'step-162 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-162 helper accepts unknown options'; else pass 'step-162 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-162 boundary policy is valid JSON'; else fail 'step-162 boundary policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-162 resume-planning boundary review completed successfully'; else fail 'step-162 boundary helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_checkpoint_step\t161' 'boundary starts from accepted step 161'
expect_line $'module_mode_workstream_closed\ttrue' 'optional-module mode workstream remains closed'
expect_line $'source_remediation_closed\ttrue' 'source-remediation chain remains closed'
expect_line $'runtime_validation_closed\ttrue' 'runtime-validation chain remains closed'
expect_line $'mandatory_targets_accepted\ttrue' 'both mandatory Slackware targets remain accepted'
expect_line $'fresh_boundary\ttrue' 'step 162 opens a fresh boundary'
expect_line $'boundary_scope\tphase-1-resume-planning' 'fresh boundary is limited to Phase 1 resume planning'
expect_line $'source_change_authorized\tfalse' 'no source change is authorized'
expect_line $'repository_refresh_authorized\tfalse' 'no repository refresh is authorized'
expect_line $'network_refresh_authorized\tfalse' 'no network refresh is authorized'
expect_line $'machine_execution_authorized\tfalse' 'no machine execution is authorized'
expect_line $'package_action_authorized\tfalse' 'no package action is authorized'
expect_line $'boot_action_authorized\tfalse' 'no boot action is authorized'
expect_line $'future_work_requires_explicit_authorization\ttrue' 'future privileged work requires explicit authorization'
expect_line $'slackware_current_publication_invalidates_boundary\tfalse' 'later Slackware-current publication does not invalidate this planning boundary'
expect_line $'next_stage\tphase-1-remaining-work-inventory' 'next stage is the Phase 1 remaining-work inventory'
expect_line $'pause_safe\tfalse' 'step 162 is not the requested end-of-session safe pause'

if python3 - "$POLICY" "$STEP161_POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p161 = json.load(handle)
assert p161['closure']['module_mode_workstream_closed'] is True
assert p161['closure']['source_remediation_closed'] is True
assert p161['closure']['runtime_validation_closed'] is True
assert p161['closure']['mandatory_targets_accepted'] is True
assert p161['next_stage'] == 'phase-1-resume-planning'
assert p161['pause_safe'] is True
assert p['review_only'] is True
assert p['fresh_boundary']['opened'] is True
assert p['fresh_boundary']['scope'] == 'phase-1-resume-planning'
assert p['fresh_boundary']['slackware_current_publication_invalidates_boundary'] is False
for key in (
    'source_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['next_stage'] == 'phase-1-remaining-work-inventory'
assert p['pause_safe'] is False
PY
then pass 'boundary policy preserves step-161 closure and grants no operational authorization'; else fail 'step-162 boundary semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'Step 162 opens a fresh repository-only planning boundary'* && $normalized_doc == *'No source change, repository refresh, network refresh, machine execution'* && $normalized_doc == *'phase-1-remaining-work-inventory'* ]]; then
    pass 'reference document records the fresh boundary and next stage'
else
    fail 'step-162 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 162 resume-planning fresh boundary review' "$CHANGELOG" && grep -Fq 'phase-1-remaining-work-inventory' "$CHANGELOG"; then pass 'CHANGELOG records step 162'; else fail 'CHANGELOG does not record step 162'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-162 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-162 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-162 helper contains a network client command'; else pass 'step-162 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
