#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-reference-comment-language-remediation-closure-review.sh"
doc="$repo_root/docs/reference/phase-1-reference-comment-language-remediation-closure-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-closure-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-closure-review.tsv"
step168_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation-policy.json"
step168_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation.tsv"
target="$repo_root/tools/reference/slack-update-reference.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check_regular() { [[ -f $1 && ! -L $1 ]] && pass "$2" || fail "$2"; }
check_hash() {
    local file=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$file" 2>/dev/null | awk '{print $1}' || true)
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}

check_regular "$helper" 'step-169 closure helper is a regular non-symlink file'
check_regular "$doc" 'step-169 reference document is a regular non-symlink file'
check_regular "$policy" 'step-169 closure policy is a regular non-symlink file'
check_regular "$record" 'step-169 closure record is a regular non-symlink file'
check_regular "$step168_policy" 'accepted step-168 implementation policy is a regular non-symlink file'
check_regular "$step168_record" 'accepted step-168 implementation record is a regular non-symlink file'
check_regular "$target" 'closed reference shell is a regular non-symlink file'
check_hash "$helper" '8d7a8b25f8fe3395f3a1679ee2c08dce60db67e5226de15bbe721f26890d03cd' 'step-169 closure helper has the exact reviewed SHA-256'
check_hash "$doc" '0fba5f49e103a0b5ffbec6d3792633b1feac86a170c349fd78ff643191ab0e21' 'step-169 reference document has the exact reviewed SHA-256'

if bash -n -- "$helper"; then pass 'step-169 closure helper is shell-syntax valid'; else fail 'step-169 closure helper is shell-syntax valid'; fi
if bash -n -- "$target"; then pass 'closed reference shell is shell-syntax valid'; else fail 'closed reference shell is shell-syntax valid'; fi
if bash -- "$helper" --help >/dev/null; then pass 'step-169 helper exposes a non-mutating help boundary'; else fail 'step-169 helper exposes a non-mutating help boundary'; fi
if bash -- "$helper" --definitely-unknown >/dev/null 2>&1; then fail 'step-169 helper rejects unknown options'; else pass 'step-169 helper rejects unknown options'; fi
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-169 closure policy is valid JSON'; else fail 'step-169 closure policy is valid JSON'; fi

# Reproduce closure evidence independently and compare byte-for-byte.
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if bash -- "$helper" --output-dir "$tmp" >/dev/null; then
    pass 'step-169 closure review reproduces successfully'
else
    fail 'step-169 closure review reproduces successfully'
fi
if cmp -s -- "$tmp/phase-1-reference-comment-language-remediation-closure-review-policy.json" "$policy"; then
    pass 'accepted closure policy is deterministically reproducible'
else
    fail 'accepted closure policy is deterministically reproducible'
fi
if cmp -s -- "$tmp/phase-1-reference-comment-language-remediation-closure-review.tsv" "$record"; then
    pass 'accepted closure record is deterministically reproducible'
else
    fail 'accepted closure record is deterministically reproducible'
fi

if python3 - "$policy" "$record" "$step168_policy" "$step168_record" "$target" <<'PY_CHECK'
import csv, hashlib, json, sys
from pathlib import Path
policy_path, record_path, p168_path, r168_path, target_path = map(Path, sys.argv[1:])
p=json.loads(policy_path.read_text(encoding='utf-8'))
p168=json.loads(p168_path.read_text(encoding='utf-8'))
assert p['scenario'] == 'phase-1-reference-comment-language-remediation-closure-review'
assert p['review_only'] is True
assert p['accepted_implementation']['step'] == 168
assert p['accepted_implementation']['policy_sha256'] == hashlib.sha256(p168_path.read_bytes()).hexdigest()
assert p['accepted_implementation']['record_sha256'] == hashlib.sha256(r168_path.read_bytes()).hexdigest()
c=p['closure']
assert c['source_before_sha256'] == p168['implementation']['source_before_sha256']
assert c['source_after_sha256'] == hashlib.sha256(target_path.read_bytes()).hexdigest()
assert c['source_after_sha256'] == p168['implementation']['source_after_sha256']
assert c['authorized_translations'] == 17
assert c['reverse_reconstruction_matches_source_before'] is True
assert c['bash_n_pass'] is True
assert c['fresh_reaudit']['inventory_complete'] is True
assert c['fresh_reaudit']['language_defects'] == 0
assert c['fresh_reaudit']['conformance_pass'] is True
assert c['workstream_closed'] is True
assert c['source_remediation_closed'] is True
a=p['authorization']
assert all(a[k] is False for k in ('source_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'))
assert a['future_work_requires_explicit_authorization'] is True
assert a['future_work_requires_fresh_boundary'] is True
s=p['safe_pause']
assert s['pause_safe'] is True and s['strong_safe_pause'] is True
assert s['machine_action_required'] is False
assert s['slackware_current_publication_invalidates_closure'] is False
assert p['next_stage'] == 'phase-1-resume-planning-after-comment-language-closure'
with record_path.open(encoding='utf-8', newline='') as h:
    rows=list(csv.reader(h, delimiter='\t'))
assert rows[0] == ['check','value']
vals={k:v for k,v in rows[1:]}
assert len(vals) == 19
assert vals['authorized_translations'] == '17'
assert vals['reverse_reconstruction_matches_source_before'] == 'yes'
assert vals['reaudit_language_defects'] == '0'
assert vals['reaudit_conformance_pass'] == 'yes'
assert vals['workstream_closed'] == 'yes'
assert vals['pause_safe'] == 'yes'
assert vals['strong_safe_pause'] == 'yes'
assert vals['machine_action_required'] == 'no'
assert vals['future_work_requires_fresh_boundary'] == 'yes'
assert vals['next_stage'] == 'phase-1-resume-planning-after-comment-language-closure'
PY_CHECK
then
    pass 'closure policy and record bind step 168, zero-defect re-audit, and strong safe pause coherently'
else
    fail 'closure policy and record bind step 168, zero-defect re-audit, and strong safe pause coherently'
fi

if grep -Fq '## Phase 1 step 169 reference comment-language remediation closure review' "$repo_root/CHANGELOG.md"; then
    pass 'CHANGELOG records step 169'
else
    fail 'CHANGELOG records step 169'
fi

if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([;&|[:space:]]|$)' "$helper"; then
    fail 'step-169 helper contains no package, boot, reboot, or shutdown mutation command'
else
    pass 'step-169 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|git[[:space:]]+(fetch|pull|clone)|rsync[[:space:]].*::)([;&|[:space:]]|$)' "$helper"; then
    fail 'step-169 helper contains no network client command'
else
    pass 'step-169 helper contains no network client command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
