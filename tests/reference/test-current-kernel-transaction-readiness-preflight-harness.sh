#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-transaction-readiness-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-kernel-transaction-readiness-preflight.sh
source "$SCRIPT"

HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0
pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_success 'the readiness preflight should have valid Bash syntax' bash -n "$SCRIPT"
assert_contains 'current-kernel-transaction-readiness-preflight' "$SCRIPT" 'the readiness scenario should be explicit'
assert_contains 'apply_ready=true' "$SCRIPT" 'a clean final review should be able to report readiness'
assert_contains 'apply_authorized=false' "$SCRIPT" 'readiness must never imply authorization'
assert_contains 'requires_explicit_apply_authorization' "$SCRIPT" 'separate apply authorization should remain mandatory'
assert_contains 'requires_apply_time_candidate_revalidation' "$SCRIPT" 'the apply workflow must revalidate candidates again'
assert_contains 'package_transaction_executed=false' "$SCRIPT" 'the readiness summary must deny package execution'
assert_contains 'mkinitrd_executed=false' "$SCRIPT" 'the readiness summary must deny mkinitrd execution'
assert_contains 'geninitrd_executed=false' "$SCRIPT" 'the readiness summary must deny geninitrd execution'
assert_contains 'dkms_build_executed=false' "$SCRIPT" 'the readiness summary must deny DKMS build execution'
assert_contains 'update_grub_executed=false' "$SCRIPT" 'the readiness summary must deny update-grub execution'
assert_contains 'grub_mkconfig_executed=false' "$SCRIPT" 'the readiness summary must deny grub-mkconfig execution'
assert_not_contains '--execute-apply' "$SCRIPT" 'the wrapper must not expose or invoke execute-apply'
if grep -E '^[[:space:]]*(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|geninitrd|update-grub|grub-mkconfig|dkms[[:space:]]+(build|install|autoinstall|remove))[[:space:]]' "$SCRIPT" | grep -vq '='; then
    fail 'the readiness preflight must not invoke mutation commands'
else
    pass
fi
assert_contains 'sha256sum -c' "$SCRIPT" 'portable evidence verification should be printed'
assert_contains '/home/$owner/' "$SCRIPT" 'evidence should be copied directly to the user home directory'
assert_contains 'geninitrd-managed-versioned-initrd' "$SCRIPT" 'readiness must bind the corrected versioned-initrd boot mode'
assert_contains 'versioned-to-versioned-initrd' "$SCRIPT" 'readiness must bind the corrected transition mode'
assert_contains 'validate_grub_kernel_initrd_pair' "$SCRIPT" 'readiness must revalidate the live GRUB kernel/initrd pair'
assert_contains '"$CURRENT_VERSIONED_INITRD"' "$SCRIPT" 'sensitive state capture must include the accepted versioned initrd'
assert_not_contains "boot.get('boot_mode') == 'direct-generic-no-initrd'" "$SCRIPT" 'the revoked direct-no-initrd baseline must not authorize readiness'

assert_success 'a valid SHA-256 should be accepted' is_sha256 "$(printf 'a%.0s' {1..64})"
assert_failure 'a short SHA-256 should be rejected' is_sha256 deadbeef
assert_success 'a normal kernel version should be accepted' is_safe_kernel_version 6.18.42
assert_failure 'a traversing kernel version should be rejected' is_safe_kernel_version ../6.18.42

TARGET=slackware-current
CONFIRM_CANDIDATES_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
CONFIRM_TARGET_KERNEL=6.18.42
assert_success 'all accepted records should bind the exact reviewed transaction' validate_accepted_records
assert_equal 6.18.40 "$RUNNING_KERNEL" 'the accepted chain should expose the running kernel'
assert_equal 6.18.42 "$TARGET_KERNEL" 'the accepted chain should expose the target kernel'
assert_equal kernel-generic-6.18.42-x86_64-1.txz "$PACKAGE_FILENAME" 'the accepted chain should expose the exact package filename'
assert_equal e9e7a1c5c71c945ee99595868aa8fee8a644b56601ece0c3e5696d643fe84878 "$PACKAGE_SHA256" 'the accepted chain should expose the exact package digest'
assert_equal geninitrd-managed-versioned-initrd "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["boot_mode"])' "$BOOT_PREFLIGHT")" 'the accepted boot record should use the corrected mode'
assert_equal /boot/initrd-6.18.40.img "$CURRENT_VERSIONED_INITRD" 'the chain should expose the current versioned initrd'
assert_equal 0da0e0289d93cdf2d3b78288bfa23db4c9437b576563f92889399b2c98294442 "$CURRENT_VERSIONED_INITRD_SHA256" 'the chain should expose the accepted initrd digest'
assert_equal 5fdff76d42ddec26b0c212668c4981a9ea2853a98b3260f33850c91ccf8ac247 "$ACTIVE_GRUB_SHA256" 'the chain should expose the accepted GRUB digest'

mutate_record() {
    local source=$1 output=$2 code=$3
    cp "$source" "$output"
    python3 - "$output" "$code" <<'PY'
import json, sys
path, code = sys.argv[1:]
data = json.load(open(path, encoding='utf-8'))
exec(code, {}, {'d': data})
with open(path, 'w', encoding='utf-8') as handle:
    json.dump(data, handle)
PY
}

original=$OWNERSHIP_PREFLIGHT
mutate_record "$original" "$TMP/ownership-ready.json" "d['apply_ready']=True"
OWNERSHIP_PREFLIGHT="$TMP/ownership-ready.json"
assert_failure 'an already apply-ready ownership record should fail the preflight boundary' validate_accepted_records
OWNERSHIP_PREFLIGHT=$original

mutate_record "$original" "$TMP/ownership-strategy.json" "d['strategy']='environment-only'"
OWNERSHIP_PREFLIGHT="$TMP/ownership-strategy.json"
assert_failure 'an unreviewed ownership strategy should fail closed' validate_accepted_records
OWNERSHIP_PREFLIGHT=$original

mutate_record "$original" "$TMP/ownership-transition.json" "d['transition_mode']='direct-to-generated-initrd'"
OWNERSHIP_PREFLIGHT="$TMP/ownership-transition.json"
assert_failure 'an ownership record using the revoked transition should fail closed' validate_accepted_records
OWNERSHIP_PREFLIGHT=$original

original=$BOOT_PREFLIGHT
mutate_record "$original" "$TMP/boot-mode.json" "d['boot_mode']='direct-generic-no-initrd'"
BOOT_PREFLIGHT="$TMP/boot-mode.json"
assert_failure 'the revoked direct-no-initrd boot baseline should fail readiness' validate_accepted_records
BOOT_PREFLIGHT=$original

original=$POST_STATE_CONTRACT
mutate_record "$original" "$TMP/post-layout.json" "d['pre_transaction_layout']='direct-generic-no-initrd'"
POST_STATE_CONTRACT="$TMP/post-layout.json"
assert_failure 'a post-state contract built on the revoked baseline should fail closed' validate_accepted_records
POST_STATE_CONTRACT=$original

original=$COMMAND_PREFLIGHT
mutate_record "$original" "$TMP/command-package.json" "d['package']['observed_sha256']='0'*64"
COMMAND_PREFLIGHT="$TMP/command-package.json"
assert_failure 'a command record detached from exact-package evidence should fail closed' validate_accepted_records
COMMAND_PREFLIGHT=$original

original=$POST_STATE_CONTRACT
mutate_record "$original" "$TMP/post-engine.json" "d['reference_engine_sha256']='0'*64"
POST_STATE_CONTRACT="$TMP/post-engine.json"
assert_failure 'a post-state contract detached from the current engine should fail closed' validate_accepted_records
POST_STATE_CONTRACT=$original

original=$DKMS_PREFLIGHT
mutate_record "$original" "$TMP/dkms-row.json" "d['dkms']['status_row_count']=1"
DKMS_PREFLIGHT="$TMP/dkms-row.json"
assert_failure 'a non-empty DKMS status should invalidate readiness' validate_accepted_records
DKMS_PREFLIGHT=$original

original=$POLICY_PREFLIGHT
mutate_record "$original" "$TMP/policy-target.json" "d['target_kernel']='6.18.41'"
POLICY_PREFLIGHT="$TMP/policy-target.json"
assert_failure 'a policy record for another kernel should fail closed' validate_accepted_records
POLICY_PREFLIGHT=$original

original=$PACKAGE_PREFLIGHT
mutate_record "$original" "$TMP/package-image.json" "d['package']['kernel_image']='/boot/vmlinuz-6.18.41'"
PACKAGE_PREFLIGHT="$TMP/package-image.json"
assert_failure 'an exact-package record with another kernel image should fail closed' validate_accepted_records
PACKAGE_PREFLIGHT=$original

original=$CHAIN_PREFLIGHT
mutate_record "$original" "$TMP/chain-link.json" "d['accepted_boot_archive_sha256']='0'*64"
CHAIN_PREFLIGHT="$TMP/chain-link.json"
assert_failure 'a restarted chain detached from boot evidence should fail closed' validate_accepted_records
CHAIN_PREFLIGHT=$original

NESTED="$TMP/nested"
mkdir -p "$NESTED"
python3 - "$NORMAL_PREFLIGHT" "$NESTED" <<'PY'
import json, pathlib, sys
record = json.load(open(sys.argv[1], encoding='utf-8'))
root = pathlib.Path(sys.argv[2])
c = record['candidates']
(root/'install-new.candidates.txt').write_text(''.join(f'{x}\n' for x in c['install_new']), encoding='utf-8')
(root/'upgrade-all.candidates.txt').write_text(''.join(f'{x}\n' for x in c['upgrade_all']), encoding='utf-8')
all_candidates = sorted(c['install_new'] + c['upgrade_all'])
(root/'all.candidates.txt').write_text(''.join(f'{x}\n' for x in all_candidates), encoding='utf-8')
(root/'summary.txt').write_text(
    'scenario=normal-update\nmode=preflight\ntarget=slackware-current\nresult=PASS\npasses=6\nfailures=0\n'
    f"install_new_candidates={len(c['install_new'])}\nupgrade_candidates={len(c['upgrade_all'])}\n"
    f"total_candidates={len(all_candidates)}\ncandidate_set_sha256={c['candidate_set_sha256']}\n"
    'kernel_candidates=2\ncritical_candidates=0\n', encoding='utf-8')
PY
assert_success 'the exact fresh candidate set should pass final revalidation' validate_nested_normal_update "$NESTED"
assert_equal "$CANDIDATE_SET_SHA256" "$(read_nested_candidate_digest "$NESTED/summary.txt")" 'the reviewed digest should be readable independently of exact-set acceptance'
cp -a "$NESTED" "$TMP/nested-missing-source"
sed -i '/kernel-source-6.18.42-noarch-1.txz/d' "$TMP/nested-missing-source/upgrade-all.candidates.txt" "$TMP/nested-missing-source/all.candidates.txt"
assert_failure 'a fresh set missing kernel-source should fail closed' validate_nested_normal_update "$TMP/nested-missing-source"
cp -a "$NESTED" "$TMP/nested-critical"
sed -i 's/critical_candidates=0/critical_candidates=1/' "$TMP/nested-critical/summary.txt"
assert_failure 'a newly critical candidate classification should require another review' validate_nested_normal_update "$TMP/nested-critical"
cp -a "$NESTED" "$TMP/nested-digest"
sed -i 's/^candidate_set_sha256=.*/candidate_set_sha256=0000000000000000000000000000000000000000000000000000000000000000/' "$TMP/nested-digest/summary.txt"
assert_failure 'a mismatched fresh candidate digest should fail closed' validate_nested_normal_update "$TMP/nested-digest"
assert_equal 0000000000000000000000000000000000000000000000000000000000000000 "$(read_nested_candidate_digest "$TMP/nested-digest/summary.txt")" 'a valid changed digest should remain available for blocked diagnostics'
cp -a "$NESTED" "$TMP/nested-invalid-digest"
sed -i 's/^candidate_set_sha256=.*/candidate_set_sha256=invalid/' "$TMP/nested-invalid-digest/summary.txt"
assert_failure 'a malformed nested digest should not be exposed' read_nested_candidate_digest "$TMP/nested-invalid-digest/summary.txt"
cp -a "$NESTED" "$TMP/nested-extra"
printf '%s\n' 'unexpected-1.0-x86_64-1.txz' >> "$TMP/nested-extra/upgrade-all.candidates.txt"
printf '%s\n' 'unexpected-1.0-x86_64-1.txz' >> "$TMP/nested-extra/all.candidates.txt"
sort -o "$TMP/nested-extra/upgrade-all.candidates.txt" "$TMP/nested-extra/upgrade-all.candidates.txt"
sort -o "$TMP/nested-extra/all.candidates.txt" "$TMP/nested-extra/all.candidates.txt"
assert_failure 'an added userspace candidate should invalidate the reviewed digest' validate_nested_normal_update "$TMP/nested-extra"

TARGET=slackware-current
RUNNING_KERNEL=6.18.40
TARGET_KERNEL=6.18.42
CANDIDATE_SET_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
FRESH_CANDIDATE_SHA256=$CANDIDATE_SET_SHA256
REFERENCE_ENGINE_SHA256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
POST_STATE_CONTRACT_SHA256=$(sha256sum "$POST_STATE_CONTRACT" | awk '{print $1}')
READINESS_STATUS=apply-ready
NEXT_STAGE=normal-update-apply-authorization-review
APPLY_READY=true
APPLY_AUTHORIZED=false
write_analysis "$TMP/readiness.json"
assert_equal apply-ready "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["readiness_status"])' "$TMP/readiness.json")" 'analysis should record apply-ready status'
assert_equal normal-update-apply-authorization-review "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["next_stage"])' "$TMP/readiness.json")" 'analysis should preserve the separate authorization boundary'
assert_equal true "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_ready"]).lower())' "$TMP/readiness.json")" 'analysis should record readiness as true'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_authorized"]).lower())' "$TMP/readiness.json")" 'analysis should keep authorization false'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["package_transaction_executed"]).lower())' "$TMP/readiness.json")" 'analysis should deny package execution'
assert_equal 8 "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["accepted_evidence_count"])' "$TMP/readiness.json")" 'analysis should bind eight accepted evidence records'
assert_equal geninitrd-managed-versioned-initrd "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["boot_mode"])' "$TMP/readiness.json")" 'analysis should record the corrected boot mode'
assert_equal versioned-to-versioned-initrd "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["transition_mode"])' "$TMP/readiness.json")" 'analysis should record the corrected transition mode'

PASS_COUNT=9
FAILURE_COUNT=0
write_summary "$TMP/summary.txt"
assert_contains 'readiness_status=apply-ready' "$TMP/summary.txt" 'summary should expose readiness'
assert_contains 'apply_ready=true' "$TMP/summary.txt" 'summary should expose positive readiness'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'summary should retain authorization denial'
assert_contains 'next_stage=normal-update-apply-authorization-review' "$TMP/summary.txt" 'summary should require a separate authorization review'
assert_contains 'boot_mode=geninitrd-managed-versioned-initrd' "$TMP/summary.txt" 'summary should expose the corrected boot mode'
assert_contains 'transition_mode=versioned-to-versioned-initrd' "$TMP/summary.txt" 'summary should expose the corrected transition mode'

OUTPUT_DIR="$TMP/evidence"
mkdir -p "$OUTPUT_DIR"
printf '%s\n' test > "$OUTPUT_DIR/summary.txt"
archive=$(create_evidence_archive)
assert_success 'the readiness archive should have a portable valid sidecar' bash -c 'cd "$1" && sha256sum -c "$2" >/dev/null' _ "$(dirname "$archive")" "${archive##*/}.sha256"


READINESS_STATUS=blocked
NEXT_STAGE=current-candidate-chain-refresh-preflight
APPLY_READY=false
write_summary "$TMP/blocked-summary.txt"
assert_contains 'readiness_status=blocked' "$TMP/blocked-summary.txt" 'blocked summary should expose blocked readiness'
assert_contains 'next_stage=current-candidate-chain-refresh-preflight' "$TMP/blocked-summary.txt" 'candidate drift should return to candidate-chain refresh'
assert_contains 'apply_ready=false' "$TMP/blocked-summary.txt" 'blocked summary must deny readiness'
printf 'Slackware-current kernel transaction readiness harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
