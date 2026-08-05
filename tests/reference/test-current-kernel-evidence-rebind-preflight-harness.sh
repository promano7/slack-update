#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-evidence-rebind-preflight.sh"
BASELINE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
REFRESH="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-candidate-chain-refresh-20260805-accepted.json"
REVIEW="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-userspace-candidate-review-20260805-accepted.json"
REBIND="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-evidence-rebind-20260805-reviewed.json"
BOOT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
CHAIN="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
PACKAGE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"
DKMS="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
COMMAND="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json"
OWNERSHIP="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260805-accepted.json"
POST="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-post-state-6.18.42-synthetic.json"
ENGINE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
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
assert_not_contains() { local needle=$1 file=$2 message=$3; grep -Fq -- "$needle" "$file" && fail "$message" || pass "$message"; }
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
    (root/name).write_text(''.join(f'{x}\n' for x in d[key]), encoding='utf-8')
summary={
'scenario':'normal-update','mode':'preflight','target':'slackware-current','result':'PASS','failures':'0',
'install_new_candidates':str(len(d['install_new'])),'upgrade_candidates':str(len(d['upgrade_all'])),
'total_candidates':str(len(d['all_candidates'])),'kernel_candidates':'2','critical_candidates':'0',
'candidate_set_sha256':d['fresh_candidate_set_sha256']}
(root/'summary.txt').write_text(''.join(f'{k}={v}\n' for k,v in summary.items()), encoding='utf-8')
PY
}
write_file() { mkdir -p -- "$(dirname -- "$1")"; printf '%s' "$2" > "$1"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

[ -r "$SCRIPT" ] || { printf 'missing script: %s\n' "$SCRIPT" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SCRIPT"

BASELINE_PREFLIGHT=$BASELINE
REFRESH_RECORD=$REFRESH
USERSPACE_REVIEW=$REVIEW
REBIND_POLICY=$REBIND
BOOT_PREFLIGHT=$BOOT
CHAIN_PREFLIGHT=$CHAIN
PACKAGE_PREFLIGHT=$PACKAGE
POLICY_PREFLIGHT=$POLICY
DKMS_PREFLIGHT=$DKMS
COMMAND_PREFLIGHT=$COMMAND
OWNERSHIP_PREFLIGHT=$OWNERSHIP
POST_STATE_CONTRACT=$POST
REFERENCE_ENGINE=$ENGINE
CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
CONFIRM_TARGET_KERNEL=6.18.42

assert_success 'the complete accepted rebind chain should validate' validate_accepted_records
assert_equal 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 "$SOURCE_CANDIDATE_SHA256" 'the source candidate digest should be the accepted 69-package set'
assert_equal "$CONFIRM_CANDIDATES_SHA256" "$REBIND_CANDIDATE_SHA256" 'the rebound candidate digest should be the reviewed 137-package set'
assert_equal 6.18.40 "$RUNNING_KERNEL" 'the accepted running kernel should be returned'
assert_equal 6.18.42 "$TARGET_KERNEL" 'the accepted target kernel should be returned'
assert_equal kernel-generic-6.18.42-x86_64-1.txz "$PACKAGE_FILENAME" 'the exact target package should be returned'
assert_equal /boot/initrd-generic.img "$CURRENT_NAMED_INITRD" 'the named initrd path should be returned'
assert_equal initrd-6.18.40.img "$CURRENT_NAMED_INITRD_TARGET" 'the named initrd target should be returned'
assert_equal /boot/initrd-6.18.40.img "$CURRENT_VERSIONED_INITRD" 'the current versioned initrd path should be returned'
assert_success 'the accepted package digest should be valid' is_sha256 "$PACKAGE_SHA256"
assert_success 'the accepted initrd digest should be valid' is_sha256 "$CURRENT_VERSIONED_INITRD_SHA256"

copy_json_mutation "$REVIEW" "$TMP/bad-review-archive.json" 'd["archive_sha256"]="0"*64'
USERSPACE_REVIEW=$TMP/bad-review-archive.json
assert_failure 'a modified accepted userspace review archive should fail closed' validate_accepted_records
USERSPACE_REVIEW=$REVIEW
copy_json_mutation "$REVIEW" "$TMP/bad-review-payload.json" 'd["package_payloads_inspected"]=True'
USERSPACE_REVIEW=$TMP/bad-review-payload.json
assert_failure 'a userspace review that overstates payload inspection should fail closed' validate_accepted_records
USERSPACE_REVIEW=$REVIEW
copy_json_mutation "$REBIND" "$TMP/bad-rebind-next.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
REBIND_POLICY=$TMP/bad-rebind-next.json
assert_failure 'a rebind policy must not route directly to apply authorization' validate_accepted_records
copy_json_mutation "$REBIND" "$TMP/bad-rebind-apply.json" 'd["apply_ready"]=True'
REBIND_POLICY=$TMP/bad-rebind-apply.json
assert_failure 'an apply-ready rebind policy should fail closed' validate_accepted_records
copy_json_mutation "$REBIND" "$TMP/bad-rebind-archive.json" 'd["accepted_evidence_archive_sha256"]["boot_preflight"]="0"*64'
REBIND_POLICY=$TMP/bad-rebind-archive.json
assert_failure 'a rebind policy with a stale evidence digest should fail closed' validate_accepted_records
REBIND_POLICY=$REBIND
copy_json_mutation "$BOOT" "$TMP/bad-boot-digest.json" 'd["normal_update_candidate_set_sha256"]="0"*64'
BOOT_PREFLIGHT=$TMP/bad-boot-digest.json
assert_failure 'kernel evidence detached from the source digest should fail closed' validate_accepted_records
BOOT_PREFLIGHT=$BOOT
copy_json_mutation "$PACKAGE" "$TMP/bad-package-target.json" 'd["target_kernel"]="6.18.43"'
PACKAGE_PREFLIGHT=$TMP/bad-package-target.json
assert_failure 'a changed target package record should fail rebind' validate_accepted_records
PACKAGE_PREFLIGHT=$PACKAGE
copy_json_mutation "$OWNERSHIP" "$TMP/bad-ownership-apply.json" 'd["apply_authorized"]=True'
OWNERSHIP_PREFLIGHT=$TMP/bad-ownership-apply.json
assert_failure 'an authorized ownership record should fail closed' validate_accepted_records
OWNERSHIP_PREFLIGHT=$OWNERSHIP

make_fresh "$TMP/fresh"
assert_success 'the exact 137-candidate transaction should validate for rebind' validate_nested_normal_update "$TMP/fresh"
cp -a "$TMP/fresh" "$TMP/critical"
printf '%s\n' 'breeze-grub-6.7.4-x86_64-1.txz' > "$TMP/critical/critical.candidates.txt"
sed -i 's/^critical_candidates=.*/critical_candidates=1/' "$TMP/critical/summary.txt"
assert_failure 'a fresh critical candidate should block rebind' validate_nested_normal_update "$TMP/critical"
cp -a "$TMP/fresh" "$TMP/kernel-change"
sed -i 's/kernel-generic-6\.18\.42-x86_64-1/kernel-generic-6.18.43-x86_64-1/' "$TMP/kernel-change/upgrade-all.candidates.txt" "$TMP/kernel-change/all.candidates.txt"
assert_failure 'a changed kernel package identity should block rebind' validate_nested_normal_update "$TMP/kernel-change"
cp -a "$TMP/fresh" "$TMP/missing-userspace"
sed -i '/SDL3-3.4.14-x86_64-1.txz/d' "$TMP/missing-userspace/upgrade-all.candidates.txt" "$TMP/missing-userspace/all.candidates.txt"
assert_failure 'a missing reviewed userspace candidate should block rebind' validate_nested_normal_update "$TMP/missing-userspace"
cp -a "$TMP/fresh" "$TMP/unsorted"
{ tail -n 1 "$TMP/unsorted/all.candidates.txt"; head -n -1 "$TMP/unsorted/all.candidates.txt"; } > "$TMP/unsorted/all.tmp"
mv "$TMP/unsorted/all.tmp" "$TMP/unsorted/all.candidates.txt"
assert_failure 'an unsorted fresh candidate list should fail closed' validate_nested_normal_update "$TMP/unsorted"

SYSTEM_ROOT=$TMP/system
PACKAGE_CACHE_ROOT=$TMP/cache
mkdir -p "$SYSTEM_ROOT/boot/grub" "$SYSTEM_ROOT/etc/default" "$SYSTEM_ROOT/etc/geninitrd.d/pre-install" \
    "$SYSTEM_ROOT/usr/sbin" "$SYSTEM_ROOT/usr/share/mkinitrd" "$SYSTEM_ROOT/var/lib/pkgtools/setup" \
    "$SYSTEM_ROOT/var/lib/pkgtools/packages" "$SYSTEM_ROOT/var/lib/dkms" \
    "$SYSTEM_ROOT/lib/modules/6.18.40" "$PACKAGE_CACHE_ROOT/slackware64/a" "$TMP/bin"
write_file "$SYSTEM_ROOT/var/lib/pkgtools/packages/sample-1.0-x86_64-1" 'package record'
write_file "$SYSTEM_ROOT/boot/vmlinuz-6.18.40" 'fixture current kernel'
ln -s vmlinuz-6.18.40 "$SYSTEM_ROOT/boot/vmlinuz-generic"
write_file "$SYSTEM_ROOT/boot/initrd-6.18.40.img" 'fixture versioned initrd'
ln -s initrd-6.18.40.img "$SYSTEM_ROOT/boot/initrd-generic.img"
write_file "$SYSTEM_ROOT/etc/default/geninitrd" $'AUTOGENERATE_INITRD=true\nGENINITRD_NAMED_SYMLINK=true\nGENINITRD_INITRD_GZ_SYMLINK=false\nAUTO_UPDATE_GRUB=true\n'
write_file "$SYSTEM_ROOT/usr/sbin/geninitrd" '#!/bin/bash\nexit 0\n'
write_file "$SYSTEM_ROOT/usr/share/mkinitrd/mkinitrd_command_generator.sh" '#!/bin/bash\nexit 0\n'
write_file "$SYSTEM_ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" '#!/bin/bash\nexit 0\n'
write_file "$SYSTEM_ROOT/etc/geninitrd.d/pre-install/dkms-bcachefs" '#!/bin/bash\nexit 0\n'
write_file "$SYSTEM_ROOT/etc/geninitrd.d/pre-install/dkms-nvidia" '#!/bin/bash\nexit 0\n'
chmod 0755 "$SYSTEM_ROOT/usr/sbin/geninitrd" "$SYSTEM_ROOT/usr/share/mkinitrd/mkinitrd_command_generator.sh" \
    "$SYSTEM_ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$SYSTEM_ROOT/etc/geninitrd.d/pre-install/dkms-bcachefs" "$SYSTEM_ROOT/etc/geninitrd.d/pre-install/dkms-nvidia"
write_file "$SYSTEM_ROOT/boot/grub/grub.cfg" $'menuentry "fixture" {\n linux /boot/vmlinuz-generic root=/dev/sda2 ro\n initrd /boot/initrd-generic.img\n}\n'
write_file "$PACKAGE_CACHE_ROOT/slackware64/a/kernel-generic-6.18.42-x86_64-1.txz" 'fixture target package'
write_file "$TMP/bin/uname" $'#!/bin/bash\nprintf \'%s\\n\' \'6.18.40\'\n'
write_file "$TMP/bin/grub-script-check" $'#!/bin/bash\nexit 0\n'
write_file "$TMP/bin/dkms" $'#!/bin/bash\ncase \"${1:-}\" in status) exit 0 ;; *) exit 0 ;; esac\n'
chmod 0755 "$TMP/bin/uname" "$TMP/bin/grub-script-check" "$TMP/bin/dkms"
PATH="$TMP/bin:/usr/bin:/bin"
GENERIC_KERNEL_SHA256=$(sha "$SYSTEM_ROOT/boot/vmlinuz-6.18.40")
CURRENT_VERSIONED_INITRD_SHA256=$(sha "$SYSTEM_ROOT/boot/initrd-6.18.40.img")
CURRENT_VERSIONED_INITRD_SIZE=$(stat -c '%s' "$SYSTEM_ROOT/boot/initrd-6.18.40.img")
ACTIVE_POLICY_SHA256=$(sha "$SYSTEM_ROOT/etc/default/geninitrd")
GENINITRD_SHA256=$(sha "$SYSTEM_ROOT/usr/sbin/geninitrd")
COMMAND_GENERATOR_SHA256=$(sha "$SYSTEM_ROOT/usr/share/mkinitrd/mkinitrd_command_generator.sh")
SETUP_SHA256=$(sha "$SYSTEM_ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd")
ACTIVE_GRUB_SHA256=$(sha "$SYSTEM_ROOT/boot/grub/grub.cfg")
HOOK_BCACHEFS_SHA256=$(sha "$SYSTEM_ROOT/etc/geninitrd.d/pre-install/dkms-bcachefs")
HOOK_NVIDIA_SHA256=$(sha "$SYSTEM_ROOT/etc/geninitrd.d/pre-install/dkms-nvidia")
PACKAGE_SHA256=$(sha "$PACKAGE_CACHE_ROOT/slackware64/a/kernel-generic-6.18.42-x86_64-1.txz")
RUNNING_KERNEL=6.18.40
TARGET_KERNEL=6.18.42
PACKAGE_FILENAME=kernel-generic-6.18.42-x86_64-1.txz
CURRENT_NAMED_INITRD=/boot/initrd-generic.img
CURRENT_NAMED_INITRD_TARGET=initrd-6.18.40.img
CURRENT_VERSIONED_INITRD=/boot/initrd-6.18.40.img
assert_success 'the fixture live GenInitrd evidence state should validate' validate_live_state
touch "$SYSTEM_ROOT/boot/initrd-6.18.42.img"
assert_failure 'an existing target initrd should block evidence rebind' validate_live_state
rm -f "$SYSTEM_ROOT/boot/initrd-6.18.42.img"
printf 'changed' >> "$PACKAGE_CACHE_ROOT/slackware64/a/kernel-generic-6.18.42-x86_64-1.txz"
assert_failure 'a changed cached target package should block evidence rebind' validate_live_state
write_file "$PACKAGE_CACHE_ROOT/slackware64/a/kernel-generic-6.18.42-x86_64-1.txz" 'fixture target package'
PACKAGE_SHA256=$(sha "$PACKAGE_CACHE_ROOT/slackware64/a/kernel-generic-6.18.42-x86_64-1.txz")
touch "$SYSTEM_ROOT/var/lib/dkms/unexpected"
assert_failure 'nonempty DKMS state should block evidence rebind' validate_live_state
rm -f "$SYSTEM_ROOT/var/lib/dkms/unexpected"
write_file "$SYSTEM_ROOT/boot/grub/grub.cfg" $'menuentry "fixture" {\n linux /boot/vmlinuz-generic root=/dev/sda2 ro\n}\n'
ACTIVE_GRUB_SHA256=$(sha "$SYSTEM_ROOT/boot/grub/grub.cfg")
assert_failure 'a GRUB entry without the named initrd should block evidence rebind' validate_live_state

SOURCE_CANDIDATE_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
REBIND_CANDIDATE_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
FRESH_CANDIDATE_SHA256=$REBIND_CANDIDATE_SHA256
assert_success 'the evidence-local rebind map should be generated' write_rebind_analysis "$TMP/rebind-analysis.json"
assert_equal current-kernel-evidence-rebind-preflight "$(json_value "$TMP/rebind-analysis.json" 'd["scenario"]')" 'the rebind scenario should be explicit'
assert_equal "$SOURCE_CANDIDATE_SHA256" "$(json_value "$TMP/rebind-analysis.json" 'd["source_candidate_set_sha256"]')" 'the source digest should remain recorded'
assert_equal "$REBIND_CANDIDATE_SHA256" "$(json_value "$TMP/rebind-analysis.json" 'd["rebound_candidate_set_sha256"]')" 'the rebound digest should be recorded'
assert_equal 7 "$(json_value "$TMP/rebind-analysis.json" 'd["accepted_kernel_evidence_count"]')" 'all seven kernel evidence records should be represented'
assert_equal true "$(json_value "$TMP/rebind-analysis.json" 'str(d["candidate_binding_change_only"]).lower()')" 'only the candidate binding may change'
assert_equal true "$(json_value "$TMP/rebind-analysis.json" 'str(d["kernel_evidence_rebound"]).lower()')" 'the evidence map should state that rebind completed'
assert_equal false "$(json_value "$TMP/rebind-analysis.json" 'str(d["package_payloads_inspected"]).lower()')" 'rebind must not claim payload inspection'
assert_equal false "$(json_value "$TMP/rebind-analysis.json" 'str(d["userspace_apply_review_complete"]).lower()')" 'rebind must not claim userspace apply completion'
assert_equal true "$(json_value "$TMP/rebind-analysis.json" 'str(d["userspace_payload_review_required"]).lower()')" 'userspace payload review should remain required'
assert_equal current-userspace-payload-review-preflight "$(json_value "$TMP/rebind-analysis.json" 'd["next_stage"]')" 'the next stage should be userspace payload review'
assert_equal false "$(json_value "$TMP/rebind-analysis.json" 'str(d["apply_ready"]).lower()')" 'rebind must not become apply-ready'
assert_equal false "$(json_value "$TMP/rebind-analysis.json" 'str(d["apply_authorized"]).lower()')" 'rebind must not authorize apply'

PASS_COUNT=12
FAILURE_COUNT=0
TARGET=slackware-current
KERNEL_EVIDENCE_REBOUND=true
NEXT_STAGE=current-userspace-payload-review-preflight
write_summary "$TMP/summary.txt"
assert_contains 'source_candidate_set_sha256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9' "$TMP/summary.txt" 'the summary should retain the source digest'
assert_contains 'rebound_candidate_set_sha256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926' "$TMP/summary.txt" 'the summary should expose the rebound digest'
assert_contains 'kernel_evidence_rebound=true' "$TMP/summary.txt" 'the summary should expose successful rebind'
assert_contains 'userspace_payload_review_required=true' "$TMP/summary.txt" 'the summary should retain the userspace payload boundary'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should deny readiness'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should deny authorization'
assert_contains 'next_stage=current-userspace-payload-review-preflight' "$TMP/summary.txt" 'the summary should route to payload review'

assert_success 'the rebind script should have valid Bash syntax' bash -n "$SCRIPT"
assert_success 'the rebind script should be executable' test -x "$SCRIPT"
assert_not_contains '--execute-apply' "$SCRIPT" 'the rebind script must never expose execute-apply'
assert_not_contains 'dkms build' "$SCRIPT" 'the rebind script must not invoke DKMS build'
assert_not_contains 'dkms install' "$SCRIPT" 'the rebind script must not invoke DKMS install'
assert_not_contains 'grub-mkconfig -o' "$SCRIPT" 'the rebind script must not replace GRUB configuration'
assert_not_contains 'update-grub' "$SCRIPT" 'the rebind script must not invoke update-grub'
assert_not_contains 'eval ' "$SCRIPT" 'the rebind script must not evaluate generated shell code'
assert_not_contains 'bash -c' "$SCRIPT" 'the rebind script must not execute shell command strings'
assert_contains 'package_payloads_inspected=false' "$SCRIPT" 'the rebind script should preserve the uninspected payload boundary'
assert_contains 'userspace_apply_review_complete=false' "$SCRIPT" 'the rebind script should preserve incomplete userspace review'
assert_contains 'apply_ready=false' "$SCRIPT" 'the rebind script should preserve apply denial'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the rebind script should preserve authorization denial'

printf 'Slackware-current kernel evidence rebind harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
