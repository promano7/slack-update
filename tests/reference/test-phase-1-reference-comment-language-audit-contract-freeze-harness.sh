#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-reference-comment-language-audit-contract-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-reference-comment-language-audit-contract-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze.tsv"
STEP164_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze-policy.json"
STEP164_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze.tsv"
TARGET="$repo_root/tools/reference/slack-update-reference.sh"
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
    "$HELPER|step-165 contract helper" \
    "$DOC|step-165 reference document" \
    "$POLICY|step-165 contract policy" \
    "$RECORD|step-165 contract record" \
    "$STEP164_POLICY|accepted step-164 selection policy" \
    "$STEP164_RECORD|accepted step-164 selection record" \
    "$TARGET|reference shell audit target"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '4caccfbc03f880ba4679126de5d2e10aa70ee22d9c2805694a9042da03680d1b' 'step-165 contract helper'
check_hash "$DOC" 'b6ed4dd397c92a2c0a79dbca0b72d29f2ad693e6d0bc44e99f407e8a3568ea92' 'step-165 reference document'
check_hash "$POLICY" '3df64c07bf2169f78add075ff0febaf04f3c418d8f1cbdb7435ebe9498209d4d' 'step-165 contract policy'
check_hash "$RECORD" '74c5cbda7c4fd609844352747af29f4ffe24e84dd9ef934cb6671dcb25523743' 'step-165 contract record'
check_hash "$STEP164_POLICY" 'd2dfa3d4e1fe716d841a416a15f2c162573bca029b7f5742c543d5d071373c11' 'accepted step-164 selection policy'
check_hash "$STEP164_RECORD" '9a00e18b56d4ce0a98b3c90db94fb1528e73e0501a6bc493769841cbacbcb79d' 'accepted step-164 selection record'

if bash -n "$HELPER"; then pass 'step-165 contract helper is shell-syntax valid'; else fail 'step-165 contract helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-165 helper exposes a non-mutating help boundary'; else fail 'step-165 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-165 helper accepts unknown options'; else pass 'step-165 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-165 contract policy is valid JSON'; else fail 'step-165 contract policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-165 comment-language audit contract freeze completed successfully'; else fail 'step-165 contract helper failed'; printf '%s\n' "$output"; fi

header=$(head -n 1 "$RECORD")
if [[ $header == $'contract_item\tscope\trequirement\tclassification\tdisposition' ]]; then pass 'contract record has the frozen five-column schema'; else fail 'contract record schema mismatch'; fi
rows=$(($(wc -l < "$RECORD") - 1))
if [[ $rows -eq 10 ]]; then pass 'contract record contains exactly ten audit rules'; else fail 'contract record row count is not ten'; fi

expect_record() {
    local pattern=$1 label=$2
    if grep -Eq "$pattern" "$RECORD"; then pass "$label"; else fail "$label"; fi
}
expect_record '^target[[:space:]]+tools/reference/slack-update-reference\.sh[[:space:]]+audit this file only[[:space:]]+mandatory[[:space:]]+' 'contract targets only the shell reference'
expect_record '^shell-comments[[:space:]]+syntactic shell comments[[:space:]]+English prose required[[:space:]]+mandatory[[:space:]]+' 'contract restricts scope to syntactic shell comments'
expect_record '^natural-language-comment[[:space:]]+comment prose[[:space:]]+English only[[:space:]]+conformance-critical[[:space:]]+' 'natural-language comment prose must be English'
expect_record '^audit-pass[[:space:]]+complete target inventory[[:space:]]+zero language-defect rows[[:space:]]+conformance-gate[[:space:]]+' 'audit PASS requires zero language defects'
expect_record '^remediation[[:space:]]+any discovered language defect[[:space:]]+separate explicit source-change authorization required[[:space:]]+blocked[[:space:]]+' 'source remediation remains unauthorized'

if python3 - "$POLICY" "$STEP164_POLICY" <<'PY2'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p164 = json.load(handle)
assert p164['next_stage'] == 'phase-1-reference-comment-language-audit-contract-freeze'
assert p164['selection']['selected_workstream'] == 'reference-comment-language-audit'
assert p['review_only'] is True
assert p['accepted_selection']['step'] == 164
c = p['contract']
assert c['workstream'] == 'reference-comment-language-audit'
assert c['target_path'] == 'tools/reference/slack-update-reference.sh'
assert c['target_hash_binding'] == 'execution-time-sha256'
assert c['shell_lexical_comments_only'] is True
assert c['shebang_excluded'] is True
assert c['heredoc_payload_excluded'] is True
assert c['quoted_or_syntactic_hash_excluded'] is True
assert c['technical_directives_allowed_as_non_prose'] is True
assert c['commented_code_allowed_as_non_prose'] is True
assert c['mixed_prose_and_code_is_prose'] is True
assert c['natural_language_required'] == 'English'
assert c['pass_requires_complete_inventory'] is True
assert c['pass_requires_zero_language_defects'] is True
assert c['audit_execution_required'] is True
assert c['source_remediation_authorized'] is False
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
assert p['next_stage'] == 'phase-1-reference-comment-language-audit-execution'
assert p['slackware_current_publication_invalidates_contract'] is False
assert p['pause_safe'] is False
PY2
then pass 'contract policy freezes lexical scope, English requirement, and zero-defect gate without operational authorization'; else fail 'step-165 contract semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'actual shell comments'* && $normalized_doc == *'zero `language-defect` classifications'* && $normalized_doc == *'does not authorize remediation'* && $normalized_doc == *'phase-1-reference-comment-language-audit-execution'* ]]; then
    pass 'reference document explains lexical scope, conformance gate, and next stage'
else
    fail 'step-165 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 165 reference comment-language audit contract freeze' "$CHANGELOG" && grep -Fq 'phase-1-reference-comment-language-audit-execution' "$CHANGELOG"; then pass 'CHANGELOG records step 165'; else fail 'CHANGELOG does not record step 165'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-165 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-165 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-165 helper contains a network client command'; else pass 'step-165 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
