#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-final-state-review.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-final-state-review-policy.json"
ACCEPTED_POST_REMOVAL="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-20260817-accepted.json"
STEP113_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification.sh"
STEP113_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-policy.json"

EXPECTED_SCRIPT_SHA256=48c23a9d2173a6c369994e3b31a37809181d60bb0717fce18c6ed445c0b3d562
EXPECTED_POLICY_SHA256=3e1a0eb110c00238e9e75aa2854205a8c4604d349aca4eb0fe8d7c03543b4f7d
EXPECTED_ACCEPTED_RECORD_SHA256=95455f3a25e2c42f2a0be88deaae7fe28eae406e08aa2bed33413a19ab45702d
EXPECTED_STEP113_SCRIPT_SHA256=607b120020c6eafa9bf24a2b0e5808ef7a879493e6bb12e8f6bb5b95c3dc228a
EXPECTED_STEP113_POLICY_SHA256=d0131d35bd7531e21d6ef4fe8a75f0e0ac88ac9ecc699ea064a4c3810df4bd90
EXPECTED_ARCHIVE_SHA256=a1da521cb8daacbd88e8dbfc70a34910d20d80089b115a2d04f9f28293d58d58
EXPECTED_SCOPE_SHA256=3045b936d168cf39b35f53872d793d0fa3a800532bbb240241be11084d11b236
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
check_regular() { local file=$1 label=$2; [[ -f $file && ! -L $file ]] && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"; }
check_hash() { local file=$1 expected=$2 label=$3; [[ $(sha_file "$file" 2>/dev/null || true) == "$expected" ]] && pass "$label has the exact prepared SHA-256" || fail "$label SHA-256 differs from the prepared boundary"; }
check_json_eq() { local file=$1 path=$2 expected=$3 label=$4 actual; actual=$(json_value "$file" "$path" 2>/dev/null || true); [[ $actual == "$expected" ]] && pass "$label" || fail "$label (expected $expected, got $actual)"; }

check_regular "$REVIEW_SCRIPT" "final-state review"
check_regular "$POLICY" "final-state policy"
check_regular "$ACCEPTED_POST_REMOVAL" "accepted step-113 record"
check_regular "$STEP113_SCRIPT" "step-113 verification script"
check_regular "$STEP113_POLICY" "step-113 verification policy"
if [[ $FAIL_COUNT -eq 0 ]]; then
    check_hash "$REVIEW_SCRIPT" "$EXPECTED_SCRIPT_SHA256" "final-state review"
    check_hash "$POLICY" "$EXPECTED_POLICY_SHA256" "final-state policy"
    check_hash "$ACCEPTED_POST_REMOVAL" "$EXPECTED_ACCEPTED_RECORD_SHA256" "accepted step-113 record"
    check_hash "$STEP113_SCRIPT" "$EXPECTED_STEP113_SCRIPT_SHA256" "step-113 verification script"
    check_hash "$STEP113_POLICY" "$EXPECTED_STEP113_POLICY_SHA256" "step-113 verification policy"
fi

bash -n "$REVIEW_SCRIPT" && pass "final-state review is shell-syntax valid" || fail "final-state review has invalid shell syntax"
"$REVIEW_SCRIPT" --help >/dev/null 2>&1 && pass "final-state review exposes a non-mutating help boundary" || fail "final-state review help boundary failed"
set +e
"$REVIEW_SCRIPT" --definitely-unknown >/dev/null 2>&1
unknown_rc=$?
set -e
[[ $unknown_rc -eq 2 ]] && pass "unknown options fail closed" || fail "unknown options do not fail closed with exit 2"

check_json_eq "$POLICY" schema 1 "policy schema"
check_json_eq "$POLICY" scenario elilo-oldkernel-cleanup-final-state-review "policy scenario"
check_json_eq "$POLICY" reviewed true "final-state policy is reviewed"
check_json_eq "$POLICY" final_state_review_only true "final-state boundary is review-only"
check_json_eq "$POLICY" destructive_action_authorized false "destructive action remains unauthorized"
check_json_eq "$POLICY" recovery_path_mutation_authorized false "recovery-path mutation remains denied"
check_json_eq "$POLICY" package_mutation_authorized false "package mutation remains denied"
check_json_eq "$POLICY" boot_mutation_authorized false "boot mutation remains denied"
check_json_eq "$POLICY" module_mutation_authorized false "module mutation remains denied"
check_json_eq "$POLICY" repository_refresh_authorized false "repository refresh remains denied"
check_json_eq "$POLICY" network_access_authorized false "network access remains denied"
check_json_eq "$POLICY" reboot_authorized false "reboot execution remains denied"
check_json_eq "$POLICY" transient_boot_id_equality_required false "transient boot-ID equality remains released"
check_json_eq "$POLICY" stable_boot_identity_required true "stable boot identity remains required"
check_json_eq "$POLICY" accepted_post_removal_archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "policy binds the exact step-113 evidence archive"
check_json_eq "$POLICY" accepted_post_removal_record_sha256 "$EXPECTED_ACCEPTED_RECORD_SHA256" "policy binds the exact accepted step-113 record"
check_json_eq "$POLICY" accepted_post_removal_script_sha256 "$EXPECTED_STEP113_SCRIPT_SHA256" "policy binds the exact step-113 verification code"
check_json_eq "$POLICY" accepted_post_removal_policy_sha256 "$EXPECTED_STEP113_POLICY_SHA256" "policy binds the exact step-113 policy"
check_json_eq "$POLICY" hostname_fqdn vbox-slack15.vbox-slack15.org "host binding"
check_json_eq "$POLICY" active_kernel 5.15.209 "active-kernel binding"
check_json_eq "$POLICY" rollback_kernel 5.15.19 "rollback-kernel binding"
check_json_eq "$POLICY" required_boot_image_suffix '\EFI\Slackware\vmlinuz-generic-5.15.209' "stable BOOT_IMAGE binding"
check_json_eq "$POLICY" removed_recovery_path "$EXPECTED_RECOVERY_PATH" "removed recovery-path binding"
check_json_eq "$POLICY" post_package_snapshot_sha256 ab69ead76bd994fd5198fa0351b9ecc66a6b2af986965751750e54aaa69e054f "package baseline binding"
check_json_eq "$POLICY" active_module_object_manifest_sha256 4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425 "active-module baseline binding"
check_json_eq "$POLICY" rollback_module_objects_manifest_sha256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 "rollback-absence baseline binding"
check_json_eq "$POLICY" boot_state_sha256 6600fc6131428963ec9726983a061990e3605ed724e19ca0f718337793a224b8 "boot-state baseline binding"
check_json_eq "$POLICY" elilo_conf_sha256 94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6 "ELILO baseline binding"

check_json_eq "$ACCEPTED_POST_REMOVAL" accepted true "step-113 record is explicitly accepted"
check_json_eq "$ACCEPTED_POST_REMOVAL" archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "step-113 record binds the accepted archive"
check_json_eq "$ACCEPTED_POST_REMOVAL" post_removal_verified true "step-113 independently verified post-removal state"
check_json_eq "$ACCEPTED_POST_REMOVAL" recovery_backup_absent true "step-113 confirms recovery backup absence"
check_json_eq "$ACCEPTED_POST_REMOVAL" removal_commit_verified true "step-113 confirms committed removal"
check_json_eq "$ACCEPTED_POST_REMOVAL" system_state_preserved true "step-113 confirms persistent state preservation"
check_json_eq "$ACCEPTED_POST_REMOVAL" pause_safe true "step-113 preserves a safe boundary"
check_json_eq "$ACCEPTED_POST_REMOVAL" next_stage elilo-oldkernel-cleanup-final-state-review "step-113 advances only to final-state review"
check_json_eq "$ACCEPTED_POST_REMOVAL" transient_boot_id_equality_required false "step-113 keeps transient boot-ID equality released"
check_json_eq "$ACCEPTED_POST_REMOVAL" stable_boot_identity_verified true "step-113 verified stable boot identity"

check_json_eq "$ACCEPTED_POST_REMOVAL" lineage.cleanup_apply_archive_sha256 d3f68ec2a2947c75fddadbdae57246db7b535c926fc83952ef2d9960aa8ac0fa "lineage binds the committed cleanup apply"
check_json_eq "$ACCEPTED_POST_REMOVAL" lineage.pre_reboot_review_archive_sha256 8c8cbdf911a860ed2b0681a3888812e4d3af59869ac93b3ec337e996ea1fc244 "lineage binds the pre-reboot review"
check_json_eq "$ACCEPTED_POST_REMOVAL" lineage.post_reboot_verification_archive_sha256 71b23d0175203eb6dc3ea5d8a93353c5eb68bb2bf49d83f7ae92f9a141fa4a1c "lineage binds post-reboot verification"
check_json_eq "$ACCEPTED_POST_REMOVAL" lineage.release_review_revision_1_archive_sha256 7c18beea914406dfe0354169b683839c14a03479e3a29dc869d1c2119facb624 "lineage binds recovery release authorization"
check_json_eq "$ACCEPTED_POST_REMOVAL" lineage.boot_rebind_review_archive_sha256 42c1d186e910da412d61e8896fdfbf96335aa70ee4ef8a4755e8c45a96fb2521 "lineage binds stable boot reauthorization"
check_json_eq "$ACCEPTED_POST_REMOVAL" lineage.removal_revision_1_archive_sha256 b008a1d8d7e0aacca60d99039eeac39a1578ed7fde26036bbe064803cb7bd1b8 "lineage binds committed recovery removal"

if grep -Fq 'ACTIVE_IMAGE_COUNT=' "$REVIEW_SCRIPT" && grep -Fq 'OLDKERNEL_EXECUTABLE_REFS=' "$REVIEW_SCRIPT"; then pass "final-state review performs semantic ELILO checks"; else fail "semantic ELILO checks are missing"; fi
if grep -Fq 'ACTIVE_IMAGE_COUNT -eq 1' "$REVIEW_SCRIPT" && grep -Fq 'ACTIVE_INITRD_COUNT -eq 1' "$REVIEW_SCRIPT" && grep -Fq 'OLDKERNEL_EXECUTABLE_REFS -eq 0' "$REVIEW_SCRIPT"; then pass "ELILO semantics require one active image/initrd and zero executable rollback references"; else fail "ELILO final-state cardinality checks are incomplete"; fi
if grep -Fq '! -e $EXPECTED_REMOVED_RECOVERY_PATH' "$REVIEW_SCRIPT" && grep -Fq '! -L $EXPECTED_REMOVED_RECOVERY_PATH' "$REVIEW_SCRIPT"; then pass "final-state review requires persistent recovery absence"; else fail "recovery absence requirement is incomplete"; fi
if grep -Fq '! -s $WORKDIR/modules-rollback-objects.before.txt' "$REVIEW_SCRIPT"; then pass "final-state review requires zero rollback module objects"; else fail "rollback module absence check is missing"; fi
if grep -Fq 'DESTRUCTIVE_ACTION_AUTHORIZED=false' "$REVIEW_SCRIPT"; then pass "final-state review explicitly denies destructive authorization"; else fail "destructive authorization denial is missing"; fi
if grep -Fq 'NEXT_STAGE=elilo-oldkernel-cleanup-destructive-boundary-closure' "$REVIEW_SCRIPT"; then pass "successful final-state review advances only to destructive-boundary closure"; else fail "final-state next-stage boundary is incorrect"; fi
if grep -Fq 'PAUSE_SAFE=true' "$REVIEW_SCRIPT"; then pass "successful final-state review establishes a safe pause"; else fail "safe-pause result is missing"; fi

if ! grep -Eq '^[[:space:]]*(rm|unlink|rmdir)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "final-state review source contains no removal command"; else fail "final-state review contains a removal command"; fi
if ! grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "final-state review source contains no package-manager mutation command"; else fail "final-state review contains a package-manager mutation command"; fi
if ! grep -Eq '^[[:space:]]*(eliloconfig|elilo)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "final-state review source contains no ELILO mutation command"; else fail "final-state review contains an ELILO mutation command"; fi
if ! grep -Eq '^[[:space:]]*(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "final-state review source contains no reboot or shutdown execution"; else fail "final-state review contains reboot/shutdown execution"; fi
if ! grep -Eq '^[[:space:]]*(curl|wget|ftp|git (fetch|pull|clone))([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "final-state review source contains no network client command"; else fail "final-state review contains a network command"; fi

scope=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-final-state-review' \
        "accepted_post_removal_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_post_removal_record_sha256=$(sha_file "$ACCEPTED_POST_REMOVAL")" \
        "accepted_post_removal_script_sha256=$(sha_file "$STEP113_SCRIPT")" \
        "accepted_post_removal_policy_sha256=$(sha_file "$STEP113_POLICY")" \
        "final_state_policy_sha256=$(sha_file "$POLICY")" \
        "final_state_script_sha256=$(sha_file "$REVIEW_SCRIPT")" \
        'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
        'active_kernel=5.15.209' \
        'rollback_kernel=5.15.19' \
        'required_boot_image_suffix=\EFI\Slackware\vmlinuz-generic-5.15.209' \
        "removed_recovery_path=$EXPECTED_RECOVERY_PATH" \
        | sha256sum | awk '{print $1}'
)
[[ $scope == "$EXPECTED_SCOPE_SHA256" ]] && pass "calculated final-state confirmation scope matches the prepared immutable boundary" || fail "calculated final-state confirmation scope differs: $scope"
if grep -Fq "printf '%s  %s\\n' \"\$ARCHIVE_SHA256\" \"\$(basename \"\$ARCHIVE\")\"" "$REVIEW_SCRIPT"; then pass "evidence sidecar records only the portable archive basename"; else fail "evidence sidecar portability contract is missing"; fi
if grep -Fq 'sudo install -o promano -g users -m 0600' "$REVIEW_SCRIPT" && grep -Fq '/home/promano/' "$REVIEW_SCRIPT"; then pass "final-state review prints direct /home/promano evidence-copy commands with required ownership"; else fail "required evidence-copy command is missing"; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
