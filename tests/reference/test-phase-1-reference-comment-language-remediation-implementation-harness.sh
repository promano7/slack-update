#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-reference-comment-language-remediation-implementation.sh"
DOC="$repo_root/docs/reference/phase-1-reference-comment-language-remediation-implementation.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation.tsv"
STEP167_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design-policy.json"
STEP167_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design.tsv"
AUDIT_HELPER="$repo_root/tools/reference/phase-1-reference-comment-language-audit-execution.sh"
TARGET="$repo_root/tools/reference/slack-update-reference.sh"
CHANGELOG="$repo_root/CHANGELOG.md"
check_regular(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is missing or unsafe"; }
for spec in "$HELPER|step-168 implementation helper" "$DOC|step-168 reference document" "$POLICY|step-168 implementation policy" "$RECORD|step-168 implementation record" "$STEP167_POLICY|accepted step-167 design policy" "$STEP167_RECORD|accepted step-167 design record" "$AUDIT_HELPER|accepted audit helper" "$TARGET|remediated reference shell"; do check_regular "${spec%%|*}" "${spec#*|}"; done
hash_eq(){ local got; got=$(sha256sum -- "$1"|awk '{print $1}'); [[ $got == "$2" ]] && pass "$3 has the exact reviewed SHA-256" || fail "$3 SHA-256 mismatch"; }
hash_eq "$HELPER" '42cbf30b1665584cbd09970939bbedc8f29633a3f1774073c97d3a8d3917e38a' 'step-168 implementation helper'
hash_eq "$DOC" '6d6439797d35e63c59f6d090bd5d7ca82cfc8e8150e132212842a57cdcb8b285' 'step-168 reference document'
if bash -n "$HELPER"; then pass 'step-168 implementation helper is shell-syntax valid'; else fail 'step-168 implementation helper has invalid shell syntax'; fi
if bash -n "$TARGET"; then pass 'remediated reference shell is shell-syntax valid'; else fail 'remediated reference shell has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-168 helper exposes a non-mutating help boundary'; else fail 'step-168 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-168 helper accepts unknown options'; else pass 'step-168 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-168 implementation policy is valid JSON'; else fail 'step-168 implementation policy is invalid JSON'; fi
if "$HELPER" --verify >/dev/null; then pass 'step-168 implementation verifies by exact reverse reconstruction'; else fail 'step-168 implementation verification failed'; fi
if python3 - "$POLICY" "$RECORD" "$STEP167_POLICY" "$STEP167_RECORD" "$TARGET" <<'PY_CHECK'
import csv,hashlib,json,sys
sha=lambda f:hashlib.sha256(open(f,'rb').read()).hexdigest()
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: rows=list(csv.DictReader(h,delimiter='\t'))
d=json.load(open(sys.argv[3],encoding='utf-8'))
with open(sys.argv[4],encoding='utf-8',newline='') as h: design=list(csv.DictReader(h,delimiter='\t'))
assert p['scenario']=='phase-1-reference-comment-language-remediation-implementation'
assert p['accepted_design']['step']==167
assert p['accepted_design']['policy_sha256']==sha(sys.argv[3])
assert p['accepted_design']['record_sha256']==sha(sys.argv[4])
i=p['implementation']
assert i['source_before_sha256']==d['accepted_audit']['target_sha256']
assert i['source_after_sha256']==sha(sys.argv[5])
assert i['authorized_translations']==i['changed_lines']==len(rows)==len(design)==17
assert i['line_count_preserved'] is True
assert i['code_prefix_preserved'] is True
assert i['nonauthorized_change_detected'] is False
assert i['reverse_reconstruction_matches_source_before'] is True
assert i['bash_n_pass'] is True
assert i['source_modified'] is True
assert [r['defect_id'] for r in rows]==[r['defect_id'] for r in design]
assert all(r['before_sha256']==drow['comment_sha256'] for r,drow in zip(rows,design))
assert all(r['code_prefix_preserved']=='yes' and r['line_count_preserved']=='yes' for r in rows)
assert p['reaudit']['inventory_complete'] is True
assert p['reaudit']['language_defects']==0
assert p['reaudit']['conformance_pass'] is True
for k in ('source_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'):
    assert p['authorization'][k] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['next_stage']=='phase-1-reference-comment-language-remediation-closure-review'
assert p['slackware_current_publication_invalidates_implementation'] is False
assert p['pause_safe'] is False
PY_CHECK
then pass 'implementation policy binds the exact authorized transformation and closes the zero-defect gate'; else fail 'step-168 implementation semantic assertions failed'; fi
header=$(head -n1 "$RECORD")
[[ $header == $'defect_id\tline_number\tbefore_sha256\tafter_sha256\tbefore_text\tafter_text\tcode_prefix_preserved\tline_count_preserved' ]] && pass 'implementation record has the frozen eight-column schema' || fail 'implementation record schema mismatch'
[[ $(awk 'END{print NR-1}' "$RECORD") -eq 17 ]] && pass 'implementation record contains exactly seventeen authorized translations' || fail 'implementation record row count mismatch'
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
if "$AUDIT_HELPER" --output-dir "$TMP" >/dev/null; then pass 'post-remediation language audit reruns successfully'; else fail 'post-remediation language audit rerun failed'; fi
if python3 - "$TMP/phase-1-reference-comment-language-audit-execution-policy.json" <<'PY_AUDIT'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['audit']['language_defects']==0
assert p['audit']['conformance_pass'] is True
assert p['next_stage']=='phase-1-reference-comment-language-audit-closure-review'
PY_AUDIT
then pass 'post-remediation audit reports zero language defects'; else fail 'post-remediation audit still reports language defects'; fi
if grep -Fq 'Phase 1 step 168 reference comment-language remediation implementation' "$CHANGELOG"; then pass 'CHANGELOG records step 168'; else fail 'CHANGELOG does not record step 168'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-168 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-168 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-168 helper contains a network client command'; else pass 'step-168 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
