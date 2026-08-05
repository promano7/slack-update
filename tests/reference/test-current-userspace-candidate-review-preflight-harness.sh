#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-candidate-review-preflight.sh"
BASELINE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
REFRESH="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-candidate-chain-refresh-20260805-accepted.json"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-expansion-20260805-reviewed.json"
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM
HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0

pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; if "$@"; then pass "$message"; else fail "$message"; fi; }
assert_failure() { local message=$1; shift; if "$@"; then fail "$message"; else pass "$message"; fi; }
assert_equal() { local expected=$1 actual=$2 message=$3; [ "$expected" = "$actual" ] && pass "$message" || { printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual" >&2; fail "$message"; }; }
assert_contains() { local needle=$1 file=$2 message=$3; grep -Fq -- "$needle" "$file" && pass "$message" || fail "$message"; }
json_value() { python3 - "$1" "$2" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
print(eval(sys.argv[2], {'d':d}))
PY
}
copy_json_mutation() { local src=$1 dst=$2 code=$3; python3 - "$src" "$dst" "$code" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
exec(sys.argv[3], {'d':d})
open(sys.argv[2], 'w', encoding='utf-8').write(json.dumps(d, indent=2, sort_keys=True)+'\n')
PY
}
make_fresh() {
    local dir=$1
    mkdir -p -- "$dir"
    python3 - "$REFRESH" "$dir" <<'PY'
import json, pathlib, sys
d=json.load(open(sys.argv[1], encoding='utf-8')); root=pathlib.Path(sys.argv[2])
for name,key in [('install-new.candidates.txt','install_new'),('upgrade-all.candidates.txt','upgrade_all'),('all.candidates.txt','all_candidates'),('critical.candidates.txt','critical_candidates')]:
    values=d[key]
    (root/name).write_text(''.join(f'{x}\n' for x in values), encoding='utf-8')
summary={
'scenario':'normal-update','mode':'preflight','target':'slackware-current','result':'PASS','failures':'0',
'install_new_candidates':str(len(d['install_new'])),'upgrade_candidates':str(len(d['upgrade_all'])),
'total_candidates':str(len(d['all_candidates'])),'critical_candidates':'0',
'candidate_set_sha256':d['fresh_candidate_set_sha256']}
(root/'summary.txt').write_text(''.join(f'{k}={v}\n' for k,v in summary.items()), encoding='utf-8')
PY
}

[ -r "$SCRIPT" ] || { printf 'missing script: %s\n' "$SCRIPT" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SCRIPT"

BASELINE_PREFLIGHT=$BASELINE
REFRESH_RECORD=$REFRESH
REVIEW_POLICY=$POLICY
CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
CONFIRM_TARGET_KERNEL=6.18.42
RUNNING_KERNEL=6.18.40

assert_success 'the accepted refresh and userspace policy should validate' validate_accepted_records
values=$(validate_accepted_records)
assert_equal "$CONFIRM_CANDIDATES_SHA256" "$(printf '%s\n' "$values" | sed -n '1p')" 'the accepted digest should be returned'
assert_equal 6.18.42 "$(printf '%s\n' "$values" | sed -n '2p')" 'the target kernel should be returned'
assert_equal 68 "$(printf '%s\n' "$values" | sed -n '3p')" 'the added candidate count should be returned'
assert_equal 61 "$(printf '%s\n' "$values" | sed -n '4p')" 'the Plasma category count should be returned'
assert_equal 6 "$(printf '%s\n' "$values" | sed -n '5p')" 'the supporting category count should be returned'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '6p')" 'the boot-adjacent category count should be returned'

copy_json_mutation "$REFRESH" "$TMP/bad-refresh-digest.json" 'd["fresh_candidate_set_sha256"]="0"*64'
REFRESH_RECORD=$TMP/bad-refresh-digest.json
assert_failure 'a stale refresh digest should fail closed' validate_accepted_records
REFRESH_RECORD=$REFRESH
copy_json_mutation "$REFRESH" "$TMP/bad-refresh-kernel.json" 'd["kernel_transaction_changed"]=True'
REFRESH_RECORD=$TMP/bad-refresh-kernel.json
assert_failure 'a changed kernel transaction should fail userspace review' validate_accepted_records
REFRESH_RECORD=$REFRESH
copy_json_mutation "$POLICY" "$TMP/bad-policy-apply.json" 'd["apply_ready"]=True'
REVIEW_POLICY=$TMP/bad-policy-apply.json
assert_failure 'an apply-ready review policy should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-payload.json" 'd["package_payloads_inspected"]=True'
REVIEW_POLICY=$TMP/bad-policy-payload.json
assert_failure 'a policy that misstates payload inspection should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-category.json" 'd["categories"]["boot_adjacent_theme"]=[]'
REVIEW_POLICY=$TMP/bad-policy-category.json
assert_failure 'an incomplete category union should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-next.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
REVIEW_POLICY=$TMP/bad-policy-next.json
assert_failure 'a review policy must not route directly to apply authorization' validate_accepted_records
REVIEW_POLICY=$POLICY

make_fresh "$TMP/fresh"
assert_success 'the exact 137-candidate userspace expansion should analyze safely' analyze_fresh_review "$TMP/fresh" "$TMP/analysis.json"
assert_equal current-userspace-candidate-review-preflight "$(json_value "$TMP/analysis.json" 'd["scenario"]')" 'the analysis scenario should be explicit'
assert_equal 137 "$(json_value "$TMP/analysis.json" 'd["fresh_candidate_count"]')" 'the full candidate count should be preserved'
assert_equal 68 "$(json_value "$TMP/analysis.json" 'd["added_candidate_count"]')" 'the added userspace count should be preserved'
assert_equal 0 "$(json_value "$TMP/analysis.json" 'd["removed_candidate_count"]')" 'no reviewed candidate should be removed'
assert_equal 61 "$(json_value "$TMP/analysis.json" 'd["category_counts"]["plasma_6_7_4"]')" 'the Plasma group should contain 61 packages'
assert_equal 6 "$(json_value "$TMP/analysis.json" 'd["category_counts"]["supporting_userspace"]')" 'the supporting group should contain six packages'
assert_equal 1 "$(json_value "$TMP/analysis.json" 'd["category_counts"]["boot_adjacent_theme"]')" 'the boot-adjacent group should contain one theme package'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["all_added_candidates_are_upgrade_all"]).lower()')" 'all added packages should remain upgrade-all candidates'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["critical_candidates_absent"]).lower()')" 'critical candidates should remain absent'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["kernel_transaction_changed"]).lower()')" 'the exact kernel transaction should remain unchanged'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["kernel_evidence_rebind_ready"]).lower()')" 'the kernel evidence should be eligible for explicit rebind'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["userspace_apply_review_complete"]).lower()')" 'candidate review must not claim full userspace apply review'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["apply_ready"]).lower()')" 'candidate review must not become apply-ready'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["apply_authorized"]).lower()')" 'candidate review must not authorize apply'
assert_equal current-kernel-evidence-rebind-preflight "$(json_value "$TMP/analysis.json" 'd["next_stage"]')" 'the next stage should be explicit rebind'

cp -a "$TMP/fresh" "$TMP/critical"
printf '%s\n' 'plasma-desktop-6.7.4-x86_64-1.txz' > "$TMP/critical/critical.candidates.txt"
sed -i 's/^critical_candidates=.*/critical_candidates=1/' "$TMP/critical/summary.txt"
assert_failure 'a critical candidate should fail the reviewed userspace boundary' analyze_fresh_review "$TMP/critical" "$TMP/critical.json"
cp -a "$TMP/fresh" "$TMP/missing"
sed -i '/SDL3-3.4.14-x86_64-1.txz/d' "$TMP/missing/upgrade-all.candidates.txt" "$TMP/missing/all.candidates.txt"
assert_failure 'a missing reviewed userspace package should fail closed' analyze_fresh_review "$TMP/missing" "$TMP/missing.json"
cp -a "$TMP/fresh" "$TMP/kernel-added"
printf '%s\n' 'kernel-modules-6.18.42-x86_64-1.txz' >> "$TMP/kernel-added/upgrade-all.candidates.txt"
printf '%s\n' 'kernel-modules-6.18.42-x86_64-1.txz' >> "$TMP/kernel-added/all.candidates.txt"
sort -u "$TMP/kernel-added/upgrade-all.candidates.txt" -o "$TMP/kernel-added/upgrade-all.candidates.txt"
sort -u "$TMP/kernel-added/all.candidates.txt" -o "$TMP/kernel-added/all.candidates.txt"
assert_failure 'an added kernel package should fail the userspace-only review' analyze_fresh_review "$TMP/kernel-added" "$TMP/kernel-added.json"
cp -a "$TMP/fresh" "$TMP/install-added"
grep -v '^SDL3-' "$TMP/install-added/upgrade-all.candidates.txt" > "$TMP/install-added/u" && mv "$TMP/install-added/u" "$TMP/install-added/upgrade-all.candidates.txt"
printf '%s\n' 'SDL3-3.4.14-x86_64-1.txz' >> "$TMP/install-added/install-new.candidates.txt"
sort -u "$TMP/install-added/install-new.candidates.txt" -o "$TMP/install-added/install-new.candidates.txt"
assert_failure 'an added userspace package moved to install-new should fail the exact review' analyze_fresh_review "$TMP/install-added" "$TMP/install-added.json"
cp -a "$TMP/fresh" "$TMP/unsorted"
{ tail -n 1 "$TMP/unsorted/all.candidates.txt"; head -n -1 "$TMP/unsorted/all.candidates.txt"; } > "$TMP/unsorted/all.tmp"
mv "$TMP/unsorted/all.tmp" "$TMP/unsorted/all.candidates.txt"
assert_failure 'an unsorted candidate list should fail closed' analyze_fresh_review "$TMP/unsorted" "$TMP/unsorted.json"

PASS_COUNT=11
FAILURE_COUNT=0
TARGET=slackware-current
RUNNING_KERNEL=6.18.40
FRESH_CANDIDATE_SHA256=$CONFIRM_CANDIDATES_SHA256
TARGET_KERNEL=6.18.42
ADDED_CANDIDATE_COUNT=68
PLASMA_CANDIDATE_COUNT=61
SUPPORTING_CANDIDATE_COUNT=6
BOOT_ADJACENT_CANDIDATE_COUNT=1
KERNEL_EVIDENCE_REBIND_READY=true
NEXT_STAGE=current-kernel-evidence-rebind-preflight
write_summary "$TMP/summary-output.txt"
assert_contains 'review_scope=candidate-identity-for-kernel-evidence-rebind' "$TMP/summary-output.txt" 'the summary should state the limited review scope'
assert_contains 'userspace_apply_review_complete=false' "$TMP/summary-output.txt" 'the summary should deny full userspace apply review'
assert_contains 'kernel_evidence_rebind_ready=true' "$TMP/summary-output.txt" 'the summary should expose rebind eligibility'
assert_contains 'next_stage=current-kernel-evidence-rebind-preflight' "$TMP/summary-output.txt" 'the summary should route only to explicit rebind'
assert_contains 'apply_ready=false' "$TMP/summary-output.txt" 'the summary should keep readiness false'
assert_contains 'apply_authorized=false' "$TMP/summary-output.txt" 'the summary should keep authorization false'
assert_contains 'package_transaction_executed=false' "$TMP/summary-output.txt" 'the summary should deny package execution'
assert_contains 'dkms_action_executed=false' "$TMP/summary-output.txt" 'the summary should deny DKMS actions'
assert_contains 'grub_update_executed=false' "$TMP/summary-output.txt" 'the summary should deny GRUB updates'

assert_success 'the acceptance script should have valid Bash syntax' bash -n "$SCRIPT"
assert_failure 'the script must not contain an execute-apply invocation' grep -Eq 'test-normal-update\.sh[^\n]*--execute-apply|NORMAL_UPDATE_SCRIPT[^\n]*--execute-apply' "$SCRIPT"
assert_contains "'package_payloads_inspected': False" "$SCRIPT" 'the generated analysis should deny payload inspection'

printf 'Slackware-current userspace candidate review harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
