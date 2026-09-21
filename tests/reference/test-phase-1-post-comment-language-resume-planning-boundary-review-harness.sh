#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-post-comment-language-resume-planning-boundary-review.sh"
DOC="$repo_root/docs/reference/phase-1-post-comment-language-resume-planning-boundary-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-resume-planning-boundary-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-resume-planning-boundary-review.tsv"
STEP169_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-closure-review-policy.json"
STEP169_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-closure-review.tsv"
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
    "$HELPER|step-170 boundary helper" \
    "$DOC|step-170 reference document" \
    "$POLICY|step-170 boundary policy" \
    "$RECORD|step-170 boundary record" \
    "$STEP169_POLICY|accepted step-169 closure policy" \
    "$STEP169_RECORD|accepted step-169 closure record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '89b887d296eb02ce599c7a9d84afd86e180b9f984466d092f4d62d3356a3a78f' 'step-170 boundary helper'
check_hash "$DOC" '4686f318eb12ea374b91460c733fb12c60964aff230a239c023cedcecd348da1' 'step-170 reference document'
check_hash "$POLICY" 'b5fb9bc7dc95a27a7d2c119eceb5142a8d7c851044b78d2484ae165f346cf7b8' 'step-170 boundary policy'
check_hash "$RECORD" '0063d67c00a3d441fd32d225b70b4da210c9b9fd301a5928dbf20116668fca05' 'step-170 boundary record'
check_hash "$STEP169_POLICY" 'd0cc3e26dd663e5f1117a327a088084b6c734a6ced608191f1ce174b5be4e11c' 'accepted step-169 closure policy'
check_hash "$STEP169_RECORD" 'c0cc272c7270945d289068d024ff7a14abe275c03292b310e058a829b0528f44' 'accepted step-169 closure record'

if bash -n "$HELPER"; then pass 'step-170 boundary helper is shell-syntax valid'; else fail 'step-170 boundary helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-170 helper exposes a non-mutating help boundary'; else fail 'step-170 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-170 helper accepts unknown options'; else pass 'step-170 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-170 boundary policy is valid JSON'; else fail 'step-170 boundary policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-170 resume-planning boundary review completed successfully'; else fail 'step-170 boundary helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_checkpoint_step\t169' 'boundary starts from accepted step 169'
expect_line $'comment_language_workstream_closed\ttrue' 'comment-language workstream remains closed'
expect_line $'source_remediation_closed\ttrue' 'comment-language source remediation remains closed'
expect_line $'comment_language_conformance_pass\ttrue' 'comment-language conformance remains accepted'
expect_line $'fresh_boundary\ttrue' 'step 170 opens a fresh boundary'
expect_line $'boundary_scope\tphase-1-resume-planning-after-comment-language-closure' 'fresh boundary has the required post-closure scope'
expect_line $'roadmap_reconciliation_status\tpending-repository-only-nonblocking' 'roadmap reconciliation remains repository-only and pending'
expect_line $'acceptance_matrix_remainder_status\tpending-future-machine-work' 'acceptance-matrix remainder remains future machine work'
expect_line $'source_change_authorized\tfalse' 'no source change is authorized'
expect_line $'repository_refresh_authorized\tfalse' 'no repository refresh is authorized'
expect_line $'network_refresh_authorized\tfalse' 'no network refresh is authorized'
expect_line $'machine_execution_authorized\tfalse' 'no machine execution is authorized'
expect_line $'package_action_authorized\tfalse' 'no package action is authorized'
expect_line $'boot_action_authorized\tfalse' 'no boot action is authorized'
expect_line $'phase_2_start_authorized\tfalse' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tfalse' 'step 170 requires no machine action'
expect_line $'future_work_requires_explicit_authorization\ttrue' 'future operational work requires explicit authorization'
expect_line $'slackware_current_publication_invalidates_boundary\tfalse' 'later Slackware-current publication does not invalidate this planning boundary'
expect_line $'next_stage\tphase-1-post-comment-language-next-workstream-selection-freeze' 'next stage is the post-closure workstream selection freeze'
expect_line $'pause_safe\tfalse' 'step 170 is not the requested end-of-session strong safe pause'

if python3 - "$POLICY" "$STEP169_POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p169 = json.load(handle)
assert p169['safe_pause']['strong_safe_pause'] is True
assert p169['authorization']['future_work_requires_fresh_boundary'] is True
assert p169['next_stage'] == 'phase-1-resume-planning-after-comment-language-closure'
assert p['review_only'] is True
assert p['accepted_checkpoint']['step'] == 169
assert p['accepted_checkpoint']['comment_language_workstream_closed'] is True
assert p['accepted_checkpoint']['comment_language_conformance_pass'] is True
assert p['fresh_boundary']['opened'] is True
assert p['fresh_boundary']['scope'] == 'phase-1-resume-planning-after-comment-language-closure'
assert p['fresh_boundary']['slackware_current_publication_invalidates_boundary'] is False
assert p['remaining_phase_1_work']['roadmap_reconciliation'] == 'pending-repository-only-nonblocking'
assert p['remaining_phase_1_work']['acceptance_matrix_remainder'] == 'pending-future-machine-work'
for key in (
    'source_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['machine_action_required'] is False
assert p['next_stage'] == 'phase-1-post-comment-language-next-workstream-selection-freeze'
assert p['pause_safe'] is False
PY
then pass 'boundary policy preserves the step-169 closure and grants no operational authorization'; else fail 'step-170 boundary semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'Step 170 opens the fresh repository-only planning boundary'* && $normalized_doc == *'grants no permission to mutate the reference source'* && $normalized_doc == *'phase-1-post-comment-language-next-workstream-selection-freeze'* ]]; then
    pass 'reference document records the fresh boundary and next stage'
else
    fail 'step-170 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 170 post-comment-language resume-planning fresh boundary review' "$CHANGELOG" && grep -Fq 'phase-1-post-comment-language-next-workstream-selection-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 170'; else fail 'CHANGELOG does not record step 170'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-170 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-170 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-170 helper contains a network client command'; else pass 'step-170 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
