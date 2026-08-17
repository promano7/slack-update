#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
VERIFY_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-policy.json"
ACCEPTED_REMOVAL="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1-20260815-accepted.json"
STEP112_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1.sh"
STEP112_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1-policy.json"

EXPECTED_SCRIPT_SHA256=607b120020c6eafa9bf24a2b0e5808ef7a879493e6bb12e8f6bb5b95c3dc228a
EXPECTED_POLICY_SHA256=d0131d35bd7531e21d6ef4fe8a75f0e0ac88ac9ecc699ea064a4c3810df4bd90
EXPECTED_ACCEPTED_REMOVAL_SHA256=46506f20ec1bf42bf622519b0b09d9ebf269d5714137f2ffe48a59fff4fb4f89
EXPECTED_STEP112_SCRIPT_SHA256=bec15e0b3d6fdaa7f1afdd6cec3dbb4d572ec0174cbcb3d49508affcbc7b1a28
EXPECTED_STEP112_POLICY_SHA256=cd2adb82efc638e60d9c3b14f06550e0b838d5c9577cb9d251a6ed9ca7ebfcd5
EXPECTED_ARCHIVE_SHA256=b008a1d8d7e0aacca60d99039eeac39a1578ed7fde26036bbe064803cb7bd1b8
EXPECTED_SCOPE_SHA256=2efd9131e765ced343ce6326c6a5395bf2e080e4c8710212a0d1700ac9f2b5ac
EXPECTED_REMOVAL_TARGET_SHA256=a18c56ff099c424cea5e16b3ec559debd8e54d7fec4968c6c0154dd2216831a8
EXPECTED_RECOVERY_PATH=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z

PASS_COUNT=0
FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*"; }
sha_file() { sha256sum -- "$1" | awk '{print $1}'; }
json_value() {
    local file=$1 path=$2
    python3 - "$file" "$path" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    value = json.load(handle)
for part in sys.argv[2].split("."):
    value = value[part]
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
else:
    print(value)
PY
}

check_regular() {
    local file=$1 label=$2
    if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
}
check_hash() {
    local file=$1 expected=$2 label=$3
    if [[ $(sha_file "$file" 2>/dev/null || true) == "$expected" ]]; then pass "$label has the exact prepared SHA-256"; else fail "$label SHA-256 differs from the prepared boundary"; fi
}
check_json_eq() {
    local file=$1 path=$2 expected=$3 label=$4 actual
    actual=$(json_value "$file" "$path" 2>/dev/null || true)
    if [[ $actual == "$expected" ]]; then pass "$label"; else fail "$label (expected $expected, got $actual)"; fi
}

check_regular "$VERIFY_SCRIPT" "post-removal verification"
check_regular "$POLICY" "post-removal policy"
check_regular "$ACCEPTED_REMOVAL" "accepted step-112 record"
check_regular "$STEP112_SCRIPT" "step-112 removal script"
check_regular "$STEP112_POLICY" "step-112 removal policy"

if [[ $FAIL_COUNT -eq 0 ]]; then
    check_hash "$VERIFY_SCRIPT" "$EXPECTED_SCRIPT_SHA256" "post-removal verification"
    check_hash "$POLICY" "$EXPECTED_POLICY_SHA256" "post-removal policy"
    check_hash "$ACCEPTED_REMOVAL" "$EXPECTED_ACCEPTED_REMOVAL_SHA256" "accepted step-112 record"
    check_hash "$STEP112_SCRIPT" "$EXPECTED_STEP112_SCRIPT_SHA256" "step-112 removal script"
    check_hash "$STEP112_POLICY" "$EXPECTED_STEP112_POLICY_SHA256" "step-112 removal policy"
fi

if bash -n "$VERIFY_SCRIPT"; then pass "post-removal verification is shell-syntax valid"; else fail "post-removal verification has invalid shell syntax"; fi
if "$VERIFY_SCRIPT" --help >/dev/null 2>&1; then pass "post-removal verification exposes a non-mutating help boundary"; else fail "post-removal verification help boundary failed"; fi
set +e
"$VERIFY_SCRIPT" --definitely-unknown >/dev/null 2>&1
unknown_rc=$?
set -e
if [[ $unknown_rc -eq 2 ]]; then pass "unknown options fail closed"; else fail "unknown options do not fail closed with exit 2"; fi

check_json_eq "$POLICY" schema 1 "policy schema"
check_json_eq "$POLICY" scenario elilo-oldkernel-cleanup-recovery-backup-post-removal-verification "policy scenario"
check_json_eq "$POLICY" reviewed true "post-removal policy is reviewed"
check_json_eq "$POLICY" verification_only true "post-removal boundary is verification-only"
check_json_eq "$POLICY" recovery_path_mutation_authorized false "recovery-path mutation remains denied"
check_json_eq "$POLICY" package_mutation_authorized false "package mutation remains denied"
check_json_eq "$POLICY" boot_mutation_authorized false "boot mutation remains denied"
check_json_eq "$POLICY" module_mutation_authorized false "module mutation remains denied"
check_json_eq "$POLICY" repository_refresh_authorized false "repository refresh remains denied"
check_json_eq "$POLICY" network_access_authorized false "network access remains denied"
check_json_eq "$POLICY" reboot_authorized false "reboot execution remains denied"
check_json_eq "$POLICY" transient_boot_id_equality_required false "transient boot-ID equality remains released"
check_json_eq "$POLICY" stable_boot_identity_required true "stable boot identity remains required"
check_json_eq "$POLICY" accepted_removal_archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "policy binds the exact step-112 evidence archive"
check_json_eq "$POLICY" accepted_removal_record_sha256 "$EXPECTED_ACCEPTED_REMOVAL_SHA256" "policy binds the exact accepted step-112 record"
check_json_eq "$POLICY" accepted_removal_script_sha256 "$EXPECTED_STEP112_SCRIPT_SHA256" "policy binds the exact step-112 removal code"
check_json_eq "$POLICY" accepted_removal_policy_sha256 "$EXPECTED_STEP112_POLICY_SHA256" "policy binds the exact step-112 removal policy"
check_json_eq "$POLICY" removed_recovery_path "$EXPECTED_RECOVERY_PATH" "policy binds the exact removed recovery path"
check_json_eq "$POLICY" removal_target_sha256 "$EXPECTED_REMOVAL_TARGET_SHA256" "policy preserves the exact reviewed removal target"

check_json_eq "$ACCEPTED_REMOVAL" accepted true "step-112 record is explicitly accepted"
check_json_eq "$ACCEPTED_REMOVAL" archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "step-112 record binds the accepted archive"
check_json_eq "$ACCEPTED_REMOVAL" removal_started true "step-112 record confirms destructive removal started"
check_json_eq "$ACCEPTED_REMOVAL" removed_file_count 10 "step-112 record confirms all ten reviewed files were removed"
check_json_eq "$ACCEPTED_REMOVAL" removal_executed true "step-112 record confirms removal execution"
check_json_eq "$ACCEPTED_REMOVAL" recovery_backup_removed true "step-112 record confirms the recovery backup was removed"
check_json_eq "$ACCEPTED_REMOVAL" recovery_backup_retained false "step-112 record confirms the recovery backup is no longer retained"
check_json_eq "$ACCEPTED_REMOVAL" system_state_preserved true "step-112 record confirms persistent system state was preserved"
check_json_eq "$ACCEPTED_REMOVAL" pause_safe true "step-112 record preserves the safe post-removal boundary"
check_json_eq "$ACCEPTED_REMOVAL" next_stage elilo-oldkernel-cleanup-recovery-backup-post-removal-verification "step-112 record advances only to post-removal verification"
check_json_eq "$ACCEPTED_REMOVAL" post_package_snapshot_sha256 ab69ead76bd994fd5198fa0351b9ecc66a6b2af986965751750e54aaa69e054f "accepted package baseline is bound"
check_json_eq "$ACCEPTED_REMOVAL" active_module_object_manifest_sha256 4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425 "accepted active-module baseline is bound"
check_json_eq "$ACCEPTED_REMOVAL" rollback_module_objects_manifest_sha256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 "accepted rollback-module absence baseline is bound"
check_json_eq "$ACCEPTED_REMOVAL" boot_state_sha256 6600fc6131428963ec9726983a061990e3605ed724e19ca0f718337793a224b8 "accepted boot-state baseline is bound"
check_json_eq "$ACCEPTED_REMOVAL" elilo_conf_sha256 94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6 "accepted ELILO baseline is bound"

if grep -Fq 'BOOT_IMAGE == *"$EXPECTED_BOOT_IMAGE_SUFFIX"' "$VERIFY_SCRIPT"; then pass "runtime verification requires the stable versioned ELILO BOOT_IMAGE suffix"; else fail "runtime stable BOOT_IMAGE check is missing"; fi
if grep -Fq 'CURRENT_BOOT_ID =~ ^[0-9a-f]{8}' "$VERIFY_SCRIPT"; then pass "current boot ID is validated only as an evidence identifier"; else fail "current boot ID evidence validation is missing"; fi
if ! grep -Eq 'CURRENT_BOOT_ID[[:space:]]*==|==[[:space:]]*\$CURRENT_BOOT_ID|boot[_-]id.*equality.*true' "$VERIFY_SCRIPT"; then pass "verification does not require equality to a transient boot ID"; else fail "verification reintroduced transient boot-ID equality"; fi
if grep -Fq '! -e $EXPECTED_REMOVED_RECOVERY_PATH' "$VERIFY_SCRIPT" && grep -Fq '! -L $EXPECTED_REMOVED_RECOVERY_PATH' "$VERIFY_SCRIPT"; then pass "verification requires the exact removed recovery path to remain absent and non-symlink"; else fail "removed recovery-path absence check is incomplete"; fi
if grep -Fq 'capture_module_objects' "$VERIFY_SCRIPT" && grep -Fq 'capture_rollback_objects' "$VERIFY_SCRIPT"; then pass "verification recaptures active modules and rollback-object absence"; else fail "module verification capture is incomplete"; fi
if grep -Fq 'capture_boot_state' "$VERIFY_SCRIPT" && grep -Fq 'elilo.conf.before' "$VERIFY_SCRIPT"; then pass "verification recaptures boot and ELILO state"; else fail "boot or ELILO verification capture is incomplete"; fi
if grep -Fq 'cmp -s -- "$WORKDIR/recovery-path.before.txt" "$WORKDIR/recovery-path.after.txt"' "$VERIFY_SCRIPT"; then pass "verification proves removed-path state is unchanged during execution"; else fail "removed-path before/after proof is missing"; fi
if grep -Fq 'POST_REMOVAL_VERIFIED=true' "$VERIFY_SCRIPT" && grep -Fq 'NEXT_STAGE=elilo-oldkernel-cleanup-final-state-review' "$VERIFY_SCRIPT"; then pass "successful verification advances only to final-state review"; else fail "successful next-stage boundary is incorrect"; fi
if grep -Fq 'PAUSE_SAFE=true' "$VERIFY_SCRIPT"; then pass "successful verification establishes a safe pause"; else fail "safe-pause result is missing"; fi

if ! grep -Eq '^[[:space:]]*(rm|unlink|rmdir)([[:space:]]|$)' "$VERIFY_SCRIPT"; then pass "verification source contains no recovery removal command"; else fail "verification source contains a removal command"; fi
if ! grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg)([[:space:]]|$)' "$VERIFY_SCRIPT"; then pass "verification source contains no package-manager mutation command"; else fail "verification source contains a package-manager mutation command"; fi
if ! grep -Eq '^[[:space:]]*(eliloconfig|elilo|cp .*EFI/Slackware|mv .*EFI/Slackware)([[:space:]]|$)' "$VERIFY_SCRIPT"; then pass "verification source contains no ELILO mutation command"; else fail "verification source contains an ELILO mutation command"; fi
if ! grep -Eq '^[[:space:]]*(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$VERIFY_SCRIPT"; then pass "verification source contains no reboot or shutdown execution"; else fail "verification source contains a reboot or shutdown command"; fi
if ! grep -Eq '^[[:space:]]*(curl|wget|ftp|rsync .*::|git (fetch|pull|clone))([[:space:]]|$)' "$VERIFY_SCRIPT"; then pass "verification source contains no network client command"; else fail "verification source contains a network command"; fi

scope=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-recovery-backup-post-removal-verification' \
        "accepted_removal_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_removal_record_sha256=$(sha_file "$ACCEPTED_REMOVAL")" \
        "accepted_removal_script_sha256=$(sha_file "$STEP112_SCRIPT")" \
        "accepted_removal_policy_sha256=$(sha_file "$STEP112_POLICY")" \
        "verification_policy_sha256=$(sha_file "$POLICY")" \
        "verification_script_sha256=$(sha_file "$VERIFY_SCRIPT")" \
        'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
        'active_kernel=5.15.209' \
        'rollback_kernel=5.15.19' \
        'required_boot_image_suffix=\EFI\Slackware\vmlinuz-generic-5.15.209' \
        "removed_recovery_path=$EXPECTED_RECOVERY_PATH" \
        "removal_target_sha256=$EXPECTED_REMOVAL_TARGET_SHA256" \
        | sha256sum | awk '{print $1}'
)
if [[ $scope == "$EXPECTED_SCOPE_SHA256" ]]; then pass "calculated post-removal confirmation scope matches the prepared immutable boundary"; else fail "calculated post-removal confirmation scope differs: $scope"; fi

if grep -Fq "printf '%s  %s\\n' \"\$(sha_file \"\$ARCHIVE\")\" \"\$(basename \"\$ARCHIVE\")\"" "$VERIFY_SCRIPT"; then pass "evidence sidecar records only the portable archive basename"; else fail "evidence sidecar portability contract is missing"; fi
if grep -Fq 'sudo install -o promano -g users -m 0600' "$VERIFY_SCRIPT" && grep -Fq '/home/promano/' "$VERIFY_SCRIPT"; then pass "verification prints direct /home/promano evidence-copy commands with required ownership"; else fail "required evidence-copy command is missing"; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
