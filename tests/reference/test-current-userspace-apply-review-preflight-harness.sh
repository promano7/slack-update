#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-apply-review-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-userspace-apply-review-preflight.sh
source "$SCRIPT"

HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0
pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; if "$@"; then pass "$message"; else fail "$message"; fi; }
assert_failure() { local message=$1; shift; if "$@"; then fail "$message"; else pass "$message"; fi; }
assert_equal() { local expected=$1 actual=$2 message=$3; [ "$expected" = "$actual" ] && pass "$message" || { printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual" >&2; fail "$message"; }; }
assert_contains() { local needle=$1 file=$2 message=$3; grep -Fq -- "$needle" "$file" && pass "$message" || fail "$message"; }
assert_not_matches() { local pattern=$1 file=$2 message=$3; grep -Eq -- "$pattern" "$file" && fail "$message" || pass "$message"; }
copy_json_mutation() { local src=$1 dst=$2 code=$3; python3 - "$src" "$dst" "$code" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); exec(sys.argv[3]); open(sys.argv[2],'w').write(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
TARGET=slackware-current
CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
CONFIRM_TARGET_KERNEL=6.18.42
ELF_RECORD=$DEFAULT_ELF_RECORD
REVIEW_POLICY=$DEFAULT_REVIEW_POLICY
REFERENCE_ENGINE=$DEFAULT_REFERENCE_ENGINE

values=$(validate_accepted_boundary)
assert_equal 69 "$(printf '%s\n' "$values"|sed -n '1p')" 'the policy should retain 69 baseline candidates'
assert_equal 68 "$(printf '%s\n' "$values"|sed -n '2p')" 'the policy should retain 68 reviewed additions'
assert_equal 137 "$(printf '%s\n' "$values"|sed -n '3p')" 'the policy should bind the exact 137-package union'
assert_equal 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "$(printf '%s\n' "$values"|sed -n '4p')" 'the policy should bind the reviewed reference engine'

mkdir -p "$TMP/normal"
python3 - "$REVIEW_POLICY" "$TMP/normal" <<'PY'
import json,pathlib,sys
p=json.load(open(sys.argv[1])); out=pathlib.Path(sys.argv[2])
install=sorted(p['expected_install_new']); allc=sorted(p['baseline_candidates']+p['reviewed_additions']); upgrade=sorted(set(allc)-set(install))
kernel=sorted(x for x in allc if x.startswith(('kernel-generic-','kernel-headers-')))
for name,items in [('install-new.candidates.txt',install),('upgrade-all.candidates.txt',upgrade),('all.candidates.txt',allc),('kernel.candidates.txt',kernel),('critical.candidates.txt',[])]:
    (out/name).write_text(''.join(x+'\n' for x in items))
PY
values=$(validate_candidate_plan "$TMP/normal" "$TMP/plan.json" "$TMP/plan.tsv")
assert_equal 137 "$(printf '%s\n' "$values"|sed -n '1p')" 'the valid fixture should contain 137 candidates'
assert_equal 69 "$(printf '%s\n' "$values"|sed -n '2p')" 'the valid fixture should preserve the baseline count'
assert_equal 68 "$(printf '%s\n' "$values"|sed -n '3p')" 'the valid fixture should preserve the addition count'
assert_equal 1 "$(printf '%s\n' "$values"|sed -n '4p')" 'the valid fixture should contain one install-new candidate'
assert_equal 136 "$(printf '%s\n' "$values"|sed -n '5p')" 'the valid fixture should contain 136 upgrade-all candidates'
assert_equal 2 "$(printf '%s\n' "$values"|sed -n '6p')" 'the normal-update classifier should expose two kernel candidates'
assert_equal 3 "$(printf '%s\n' "$values"|sed -n '7p')" 'the transaction should retain three kernel package identities'
assert_equal 0 "$(printf '%s\n' "$values"|sed -n '8p')" 'the valid fixture should contain no critical candidates'
assert_contains $'ristretto-0.14.0-x86_64-1.txz\tbaseline\tinstall-new\tfalse' "$TMP/plan.tsv" 'the install-new action should be explicit in the plan'
assert_contains $'kernel-source-6.18.42-noarch-1.txz\tbaseline\tupgrade-all\ttrue' "$TMP/plan.tsv" 'kernel-source should remain in the reviewed kernel transaction'
assert_contains '"exact_union_verified": true' "$TMP/plan.json" 'the plan should publish exact-union verification'
assert_contains '"package_transaction_executed": false' "$TMP/plan.json" 'the plan should publish transaction non-execution'
assert_contains '"next_stage": "current-kernel-transaction-readiness-preflight"' "$TMP/plan.json" 'the plan should route only to readiness'

assert_success 'the checked-in reference contract should validate' validate_reference_contract "$TMP/contract.json"
assert_contains '"all_checks_passed": true' "$TMP/contract.json" 'the reference contract should report complete validation'
assert_contains '"temporary_policy_override_precedes_packages": true' "$TMP/contract.json" 'the policy override should precede package actions'
assert_contains '"policy_restore_follows_packages": true' "$TMP/contract.json" 'the original GenInitrd policy should be restored after package actions'
assert_contains '"package_failures_block_secondary_modules": true' "$TMP/contract.json" 'partial package failures should block secondary modules'
assert_contains '"generated_grub_is_validated": true' "$TMP/contract.json" 'temporary GRUB output should be validated'

mkdir -p "$TMP/elf"
cat > "$TMP/elf/summary.txt" <<EOF_SUMMARY
scenario=current-userspace-elf-runtime-review-preflight
result=PASS
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
target_kernel=$CONFIRM_TARGET_KERNEL
elf_file_count=722
elf_package_count=61
unresolved_edge_count=0
unsafe_runtime_object_count=0
elf_runtime_review_complete=true
userspace_apply_review_complete=false
package_transaction_executed=false
elf_payload_executed=false
dynamic_loader_tracing_executed=false
next_stage=current-userspace-apply-review-preflight
apply_ready=false
apply_authorized=false
passes=15
failures=0
EOF_SUMMARY
assert_success 'the accepted nested ELF summary should validate' validate_nested_elf_review "$TMP/elf"
cp "$TMP/elf/summary.txt" "$TMP/elf/summary.good"
for mutation in \
    'elf_file_count=721' \
    'elf_package_count=60' \
    'unresolved_edge_count=1' \
    'unsafe_runtime_object_count=1' \
    'package_transaction_executed=true' \
    'elf_payload_executed=true' \
    'apply_ready=true' \
    'failures=1'; do
    cp "$TMP/elf/summary.good" "$TMP/elf/summary.txt"
    key=${mutation%%=*}
    sed -i "s/^${key}=.*/${mutation}/" "$TMP/elf/summary.txt"
    assert_failure "nested ELF mutation $mutation should fail closed" validate_nested_elf_review "$TMP/elf"
done
cp "$TMP/elf/summary.good" "$TMP/elf/summary.txt"

cp -a "$TMP/normal" "$TMP/missing"
sed -i '/^breeze-grub-/d' "$TMP/missing/all.candidates.txt"
assert_failure 'a missing reviewed addition should fail the candidate union' validate_candidate_plan "$TMP/missing" "$TMP/x.json" "$TMP/x.tsv"
cp -a "$TMP/normal" "$TMP/extra"
printf 'unexpected-1.0-x86_64-1.txz\n' >> "$TMP/extra/all.candidates.txt"
sort -u -o "$TMP/extra/all.candidates.txt" "$TMP/extra/all.candidates.txt"
assert_failure 'an unreviewed extra candidate should fail the candidate union' validate_candidate_plan "$TMP/extra" "$TMP/x.json" "$TMP/x.tsv"
cp -a "$TMP/normal" "$TMP/wrong-action"
sed -i '/^ristretto-/d' "$TMP/wrong-action/install-new.candidates.txt"
printf 'ristretto-0.14.0-x86_64-1.txz\n' >> "$TMP/wrong-action/upgrade-all.candidates.txt"
sort -u -o "$TMP/wrong-action/upgrade-all.candidates.txt" "$TMP/wrong-action/upgrade-all.candidates.txt"
assert_failure 'moving install-new into upgrade-all should fail closed' validate_candidate_plan "$TMP/wrong-action" "$TMP/x.json" "$TMP/x.tsv"
cp -a "$TMP/normal" "$TMP/missing-kernel"
sed -i '/^kernel-headers-/d' "$TMP/missing-kernel/kernel.candidates.txt"
assert_failure 'a changed kernel classification should fail closed' validate_candidate_plan "$TMP/missing-kernel" "$TMP/x.json" "$TMP/x.tsv"
cp -a "$TMP/normal" "$TMP/critical"
printf 'aaa_glibc-solibs-2.42-x86_64-1.txz\n' > "$TMP/critical/critical.candidates.txt"
assert_failure 'a newly critical candidate should fail closed' validate_candidate_plan "$TMP/critical" "$TMP/x.json" "$TMP/x.tsv"

for spec in \
 'record-digest:d["candidate_set_sha256"]="0"*64' \
 'record-unsafe:d["unsafe_runtime_object_count"]=1' \
 'record-authorized:d["apply_authorized"]=True' \
 'record-stage:d["next_stage"]="wrong"'; do
    name=${spec%%:*}; code=${spec#*:}; copy_json_mutation "$DEFAULT_ELF_RECORD" "$TMP/$name.json" "$code"
    ELF_RECORD="$TMP/$name.json"
    assert_failure "$name should invalidate the accepted ELF boundary" validate_accepted_boundary
    ELF_RECORD=$DEFAULT_ELF_RECORD
done
for spec in \
 'policy-overlap:d["reviewed_additions"][0]=d["baseline_candidates"][0]' \
 'policy-step-count:d["transaction"]["step_count"]=11' \
 'policy-postinst:d["postinstall_processing_enabled"]=True' \
 'policy-authorized:d["apply_ready"]=True' \
 'policy-stage:d["next_stage"]="wrong"'; do
    name=${spec%%:*}; code=${spec#*:}; copy_json_mutation "$DEFAULT_REVIEW_POLICY" "$TMP/$name.json" "$code"
    REVIEW_POLICY="$TMP/$name.json"
    assert_failure "$name should invalidate the apply policy" validate_accepted_boundary
    REVIEW_POLICY=$DEFAULT_REVIEW_POLICY
done

USPACE_APPLY_REVIEW_COMPLETE=true
NEXT_STAGE=current-kernel-transaction-readiness-preflight
CANDIDATE_COUNT=137
BASELINE_CANDIDATE_COUNT=69
ADDED_CANDIDATE_COUNT=68
INSTALL_NEW_COUNT=1
UPGRADE_ALL_COUNT=136
KERNEL_CANDIDATE_COUNT=2
KERNEL_TRANSACTION_COUNT=3
CRITICAL_CANDIDATE_COUNT=0
PASS_COUNT=15
FAILURE_COUNT=0
write_summary "$TMP/summary.txt"
assert_contains 'result=PASS' "$TMP/summary.txt" 'a clean review summary should report PASS'
assert_contains 'candidate_count=137' "$TMP/summary.txt" 'the summary should retain the exact candidate count'
assert_contains 'baseline_candidate_count=69' "$TMP/summary.txt" 'the summary should retain the baseline count'
assert_contains 'added_candidate_count=68' "$TMP/summary.txt" 'the summary should retain the addition count'
assert_contains 'kernel_transaction_count=3' "$TMP/summary.txt" 'the summary should retain all kernel package identities'
assert_contains 'transaction_step_count=12' "$TMP/summary.txt" 'the summary should retain the reviewed transaction step count'
assert_contains 'recovery_boundary_count=5' "$TMP/summary.txt" 'the summary should retain the recovery boundary count'
assert_contains 'userspace_apply_review_complete=true' "$TMP/summary.txt" 'the summary should complete userspace application review'
assert_contains 'package_transaction_executed=false' "$TMP/summary.txt" 'the summary should preserve package non-execution'
assert_contains 'next_stage=current-kernel-transaction-readiness-preflight' "$TMP/summary.txt" 'the summary should route only to readiness'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should preserve readiness denial'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should preserve authorization denial'

assert_success 'the userspace apply-review preflight should have valid Bash syntax' bash -n "$SCRIPT"
assert_success 'the userspace apply-review preflight should be executable' test -x "$SCRIPT"
assert_not_matches '^[[:space:]]*(upgradepkg|installpkg|removepkg)([[:space:]]|$)' "$SCRIPT" 'the preflight must not invoke package installation tools'
assert_not_matches '^[[:space:]]*(mkinitrd|geninitrd|dkms|grub-mkconfig|update-grub)([[:space:]]|$)' "$SCRIPT" 'the preflight must not mutate boot state'
assert_contains '--preflight' "$SCRIPT" 'the nested normal-update invocation should remain preflight-only'
assert_contains 'package_transaction_executed=false' "$SCRIPT" 'the preflight should publish package non-execution explicitly'
assert_contains "printf 'userspace_apply_review_complete=%s\\n'" "$SCRIPT" 'the preflight should publish application-review completion explicitly'
assert_contains 'apply_ready=false' "$SCRIPT" 'the preflight should preserve readiness denial'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the preflight should preserve authorization denial'

printf 'Slackware-current userspace apply review harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
