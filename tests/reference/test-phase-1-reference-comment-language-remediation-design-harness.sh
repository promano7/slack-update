#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-reference-comment-language-remediation-design.sh"
DOC="$repo_root/docs/reference/phase-1-reference-comment-language-remediation-design.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design.tsv"
STEP166_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution-policy.json"
STEP166_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution.tsv"
TARGET="$repo_root/tools/reference/slack-update-reference.sh"
CHANGELOG="$repo_root/CHANGELOG.md"
check_regular(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is missing or unsafe"; }
for spec in "$HELPER|step-167 design helper" "$DOC|step-167 reference document" "$POLICY|step-167 design policy" "$RECORD|step-167 design record" "$STEP166_POLICY|accepted step-166 audit policy" "$STEP166_RECORD|accepted step-166 audit record" "$TARGET|reference shell target"; do check_regular "${spec%%|*}" "${spec#*|}"; done
hash_eq(){ local got; got=$(sha256sum -- "$1"|awk '{print $1}'); [[ $got == "$2" ]] && pass "$3 has the exact reviewed SHA-256" || fail "$3 SHA-256 mismatch"; }
hash_eq "$HELPER" '2a562711de0d463c4cd77e91d2171efb6b272e38aa4d6bd9967bce5de8d7ee1e' 'step-167 design helper'
hash_eq "$DOC" '80a05e274cc772575ac13e0ad7de1293cd960a5b90f35de8d4d1544ddb22aa60' 'step-167 reference document'
if bash -n "$HELPER"; then pass 'step-167 design helper is shell-syntax valid'; else fail 'step-167 design helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-167 helper exposes a non-mutating help boundary'; else fail 'step-167 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-167 helper accepts unknown options'; else pass 'step-167 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-167 design policy is valid JSON'; else fail 'step-167 design policy is invalid JSON'; fi
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
if "$HELPER" --output-dir "$TMP" >/dev/null; then pass 'step-167 remediation design reproduces successfully'; else fail 'step-167 remediation design failed'; fi
if cmp -s "$TMP/phase-1-reference-comment-language-remediation-design-policy.json" "$POLICY"; then pass 'accepted design policy is deterministically reproducible'; else fail 'accepted design policy differs from regenerated result'; fi
if cmp -s "$TMP/phase-1-reference-comment-language-remediation-design.tsv" "$RECORD"; then pass 'accepted design record is deterministically reproducible'; else fail 'accepted design record differs from regenerated result'; fi
if python3 - "$POLICY" "$RECORD" "$STEP166_POLICY" "$STEP166_RECORD" "$TARGET" <<'PY_CHECK'
import csv,hashlib,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: design=list(csv.DictReader(h,delimiter='\t'))
s166=json.load(open(sys.argv[3],encoding='utf-8'))
with open(sys.argv[4],encoding='utf-8',newline='') as h: audit=list(csv.DictReader(h,delimiter='\t'))
defects=[r for r in audit if r['classification']=='language-defect']
sha=lambda f:hashlib.sha256(open(f,'rb').read()).hexdigest()
assert p['scenario']=='phase-1-reference-comment-language-remediation-design'
assert p['review_only'] is True
assert p['accepted_audit']['step']==166
assert p['accepted_audit']['policy_sha256']==sha(sys.argv[3])
assert p['accepted_audit']['record_sha256']==sha(sys.argv[4])
assert p['accepted_audit']['target_sha256']==sha(sys.argv[5])==s166['audit']['target_sha256']
assert p['accepted_audit']['language_defects']==len(defects)==len(design)>0
assert [r['line_number'] for r in design]==[r['line_number'] for r in defects]
assert [r['comment_sha256'] for r in design]==[r['comment_sha256'] for r in defects]
assert all(r['authorized_change']=='translate-comment-payload-to-English' for r in design)
assert all(r['preserve_code_prefix']=='yes' and r['preserve_line_count']=='yes' for r in design)
r=p['remediation_design']
assert r['authorized_rows']==len(defects)
assert r['preserve_code_prefix_through_hash'] is True
assert r['preserve_line_count'] is True
assert r['preserve_nondefect_comments'] is True
assert r['runtime_strings_out_of_scope'] is True
assert r['heredoc_payload_out_of_scope'] is True
assert r['technical_directives_out_of_scope'] is True
assert r['code_changes_forbidden'] is True
assert r['implementation_must_run_bash_n'] is True
assert r['implementation_must_rerun_language_audit'] is True
assert r['implementation_zero_defect_gate'] is True
assert p['authorization']['source_change_authorized'] is True
for k in ('repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'):
    assert p['authorization'][k] is False
assert p['next_stage']=='phase-1-reference-comment-language-remediation-implementation'
assert p['slackware_current_publication_invalidates_design'] is False
assert p['pause_safe'] is False
PY_CHECK
then pass 'design is bound to the exact accepted audit and authorizes only frozen defect rows'; else fail 'step-167 semantic assertions failed'; fi
header=$(head -n1 "$RECORD")
[[ $header == $'defect_id\tline_number\tcomment_sha256\tcomment_text\tauthorized_change\tpreserve_code_prefix\tpreserve_line_count\tdisposition' ]] && pass 'design record has the frozen eight-column schema' || fail 'design record schema mismatch'
if grep -Fq 'Phase 1 step 167 reference comment-language remediation design' "$CHANGELOG"; then pass 'CHANGELOG records step 167'; else fail 'CHANGELOG does not record step 167'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-167 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-167 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-167 helper contains a network client command'; else pass 'step-167 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
