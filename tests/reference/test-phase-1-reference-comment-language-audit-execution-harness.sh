#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-reference-comment-language-audit-execution.sh"
DOC="$repo_root/docs/reference/phase-1-reference-comment-language-audit-execution.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution.tsv"
STEP165_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze-policy.json"
STEP165_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze.tsv"
TARGET="$repo_root/tools/reference/slack-update-reference.sh"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is missing or unsafe"; }
for spec in "$HELPER|step-166 audit helper" "$DOC|step-166 reference document" "$POLICY|step-166 audit policy" "$RECORD|step-166 audit record" "$STEP165_POLICY|accepted step-165 contract policy" "$STEP165_RECORD|accepted step-165 contract record" "$TARGET|reference shell audit target"; do check_regular "${spec%%|*}" "${spec#*|}"; done

hash_eq(){ local got; got=$(sha256sum -- "$1"|awk '{print $1}'); [[ $got == "$2" ]] && pass "$3 has the exact reviewed SHA-256" || fail "$3 SHA-256 mismatch"; }
hash_eq "$HELPER" 'ae80606727a703ace033a0fcb52116d46841df3c9ba09b94fc36daba358f69d1' 'step-166 audit helper'
hash_eq "$DOC" '2fe85a89e93963cdcce82509b67a866c33522218159568f13765601ba6fe3795' 'step-166 reference document'
hash_eq "$STEP165_POLICY" '3df64c07bf2169f78add075ff0febaf04f3c418d8f1cbdb7435ebe9498209d4d' 'accepted step-165 contract policy'
hash_eq "$STEP165_RECORD" '74c5cbda7c4fd609844352747af29f4ffe24e84dd9ef934cb6671dcb25523743' 'accepted step-165 contract record'

if bash -n "$HELPER"; then pass 'step-166 audit helper is shell-syntax valid'; else fail 'step-166 audit helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-166 helper exposes a non-mutating help boundary'; else fail 'step-166 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-166 helper accepts unknown options'; else pass 'step-166 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-166 audit policy is valid JSON'; else fail 'step-166 audit policy is invalid JSON'; fi

TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
if "$HELPER" --output-dir "$TMP" >/dev/null; then pass 'step-166 audit execution reproduces successfully'; else fail 'step-166 audit execution failed'; fi
TMP_POLICY="$TMP/phase-1-reference-comment-language-audit-execution-policy.json"
TMP_RECORD="$TMP/phase-1-reference-comment-language-audit-execution.tsv"
if cmp -s "$TMP_POLICY" "$POLICY"; then pass 'accepted audit policy is deterministically reproducible'; else fail 'accepted audit policy differs from regenerated result'; fi
if cmp -s "$TMP_RECORD" "$RECORD"; then pass 'accepted audit record is deterministically reproducible'; else fail 'accepted audit record differs from regenerated result'; fi

if python3 - "$POLICY" "$RECORD" "$TARGET" <<'PY_CHECK'
import csv, hashlib, json, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: rows=list(csv.DictReader(h,delimiter='\t'))
target_hash=hashlib.sha256(open(sys.argv[3],'rb').read()).hexdigest()
a=p['audit']
assert p['review_only'] is True
assert p['accepted_contract']['step'] == 165
assert p['accepted_contract']['policy_sha256'] == '3df64c07bf2169f78add075ff0febaf04f3c418d8f1cbdb7435ebe9498209d4d'
assert p['accepted_contract']['record_sha256'] == '74c5cbda7c4fd609844352747af29f4ffe24e84dd9ef934cb6671dcb25523743'
assert a['target_path'] == 'tools/reference/slack-update-reference.sh'
assert a['target_sha256'] == target_hash
assert a['inventory_complete'] is True
assert a['total_comments'] == len(rows)
counts={k:0 for k in ('english-prose','technical-directive','code-fragment','language-defect')}
for r in rows: counts[r['classification']]+=1
assert a['english_prose'] == counts['english-prose']
assert a['technical_directive'] == counts['technical-directive']
assert a['code_fragment'] == counts['code-fragment']
assert a['language_defects'] == counts['language-defect']
assert a['conformance_pass'] == (a['language_defects'] == 0)
assert a['source_modified'] is False
assert p['next_stage'] == ('phase-1-reference-comment-language-audit-closure-review' if a['language_defects']==0 else 'phase-1-reference-comment-language-remediation-design')
for k in ('source_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'):
    assert p['authorization'][k] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['slackware_current_publication_invalidates_audit'] is False
assert p['pause_safe'] is False
PY_CHECK
then pass 'audit policy is bound to the exact target and coherent with the complete comment inventory'; else fail 'step-166 audit semantic assertions failed'; fi

header=$(head -n1 "$RECORD")
[[ $header == $'line_number\tclassification\treason\tcomment_sha256\tcomment_text' ]] && pass 'audit record has the frozen five-column schema' || fail 'audit record schema mismatch'
if awk -F '\t' 'NR>1 && $2=="language-defect"{found=1} END{exit found?0:1}' "$RECORD"; then pass 'audit records at least one comment-language defect requiring remediation'; else pass 'audit records zero comment-language defects and may proceed to closure review'; fi
if grep -Fq 'Phase 1 step 166 reference comment-language audit execution' "$CHANGELOG"; then pass 'CHANGELOG records step 166'; else fail 'CHANGELOG does not record step 166'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-166 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-166 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-166 helper contains a network client command'; else pass 'step-166 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
