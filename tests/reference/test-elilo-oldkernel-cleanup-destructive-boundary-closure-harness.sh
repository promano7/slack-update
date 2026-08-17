#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-destructive-boundary-closure.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-destructive-boundary-closure-policy.json"
ACCEPTED_FINAL_STATE="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-final-state-review-20260817-accepted.json"
STEP114_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-final-state-review.sh"
STEP114_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-final-state-review-policy.json"

EXPECTED_SCRIPT_SHA256="8fb0061725acc8e867552d56869ac4114445ff90c681b113d37ff96a5b02dea2"
EXPECTED_POLICY_SHA256="e758081200e59e4e48cf5f133a538f49ec92f57d5700e21110b3bf8b23bcd813"
EXPECTED_ACCEPTED_RECORD_SHA256="33c93ea836bfa81317b6252011a07c580fff6323d32679f673934b66a00d8186"
EXPECTED_STEP114_SCRIPT_SHA256="48c23a9d2173a6c369994e3b31a37809181d60bb0717fce18c6ed445c0b3d562"
EXPECTED_STEP114_POLICY_SHA256="3e1a0eb110c00238e9e75aa2854205a8c4604d349aca4eb0fe8d7c03543b4f7d"
EXPECTED_ARCHIVE_SHA256="cfd6ddac3ab880f09188790e775929961e54e22e28aec63960b346210bbff2e3"
EXPECTED_SCOPE_SHA256="30b0d03d7821a39ba2b0a68423defb1aafd221ff1a4506f8b15700fa27ee0961"
EXPECTED_RECOVERY_PATH="/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z"

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
check_json_eq() {
    local file=$1 path=$2 expected=$3 message=$4 actual
    actual=$(json_value "$file" "$path" 2>/dev/null || true)
    [[ $actual == "$expected" ]] && pass "$message" || fail "$message"
}

for item in \
    "$REVIEW_SCRIPT" \
    "$POLICY" \
    "$ACCEPTED_FINAL_STATE" \
    "$STEP114_SCRIPT" \
    "$STEP114_POLICY"; do
    [[ -f $item && ! -L $item ]] && pass "$(basename "$item") is a regular non-symlink file" || fail "$item is missing or unsafe"
done

[[ $(sha_file "$REVIEW_SCRIPT") == "$EXPECTED_SCRIPT_SHA256" ]] && pass "destructive-boundary closure has the exact prepared SHA-256" || fail "destructive-boundary closure SHA-256 differs"
[[ $(sha_file "$POLICY") == "$EXPECTED_POLICY_SHA256" ]] && pass "closure policy has the exact prepared SHA-256" || fail "closure policy SHA-256 differs"
[[ $(sha_file "$ACCEPTED_FINAL_STATE") == "$EXPECTED_ACCEPTED_RECORD_SHA256" ]] && pass "accepted step-114 record has the exact reviewed SHA-256" || fail "accepted step-114 record SHA-256 differs"
[[ $(sha_file "$STEP114_SCRIPT") == "$EXPECTED_STEP114_SCRIPT_SHA256" ]] && pass "step-114 final-state review script remains byte-identical" || fail "step-114 script changed"
[[ $(sha_file "$STEP114_POLICY") == "$EXPECTED_STEP114_POLICY_SHA256" ]] && pass "step-114 final-state review policy remains byte-identical" || fail "step-114 policy changed"

bash -n "$REVIEW_SCRIPT" && pass "destructive-boundary closure is shell-syntax valid" || fail "destructive-boundary closure has shell syntax errors"
"$REVIEW_SCRIPT" --help >/dev/null 2>&1
[[ $? -eq 0 ]] && pass "destructive-boundary closure exposes a non-mutating help boundary" || fail "help boundary failed"
set +e
"$REVIEW_SCRIPT" --definitely-unknown >/dev/null 2>&1
unknown_rc=$?
set -e
[[ $unknown_rc -eq 2 ]] && pass "unknown options fail closed" || fail "unknown options do not fail closed with exit 2"

check_json_eq "$POLICY" schema 1 "policy schema"
check_json_eq "$POLICY" scenario elilo-oldkernel-cleanup-destructive-boundary-closure "policy scenario"
check_json_eq "$POLICY" reviewed true "closure policy is reviewed"
check_json_eq "$POLICY" closure_review_only true "closure boundary is review-only"
check_json_eq "$POLICY" destructive_action_authorized false "destructive action remains unauthorized"
check_json_eq "$POLICY" pending_destructive_action false "no destructive action is pending"
check_json_eq "$POLICY" historical_authorizations_consumed true "historical destructive authorizations are marked consumed"
check_json_eq "$POLICY" recovery_path_mutation_authorized false "recovery-path mutation remains denied"
check_json_eq "$POLICY" package_mutation_authorized false "package mutation remains denied"
check_json_eq "$POLICY" boot_mutation_authorized false "boot mutation remains denied"
check_json_eq "$POLICY" module_mutation_authorized false "module mutation remains denied"
check_json_eq "$POLICY" repository_refresh_authorized false "repository refresh remains denied"
check_json_eq "$POLICY" network_access_authorized false "network access remains denied"
check_json_eq "$POLICY" reboot_authorized false "reboot execution remains denied"
check_json_eq "$POLICY" transient_boot_id_equality_required false "transient boot-ID equality remains released"
check_json_eq "$POLICY" stable_boot_identity_required true "stable boot identity remains required"
check_json_eq "$POLICY" expected_script_sha256 "$EXPECTED_SCRIPT_SHA256" "policy binds the exact closure script"
check_json_eq "$POLICY" accepted_final_state_record_sha256 "$EXPECTED_ACCEPTED_RECORD_SHA256" "policy binds the exact accepted step-114 record"
check_json_eq "$POLICY" accepted_final_state_archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "policy binds the exact step-114 evidence archive"
check_json_eq "$POLICY" accepted_final_state_script_sha256 "$EXPECTED_STEP114_SCRIPT_SHA256" "policy binds the exact step-114 review code"
check_json_eq "$POLICY" accepted_final_state_policy_sha256 "$EXPECTED_STEP114_POLICY_SHA256" "policy binds the exact step-114 policy"
check_json_eq "$POLICY" hostname_fqdn vbox-slack15.vbox-slack15.org "host binding"
check_json_eq "$POLICY" active_kernel 5.15.209 "active-kernel binding"
check_json_eq "$POLICY" rollback_kernel 5.15.19 "rollback-kernel binding"
check_json_eq "$POLICY" required_boot_image_suffix '\EFI\Slackware\vmlinuz-generic-5.15.209' "stable BOOT_IMAGE binding"
check_json_eq "$POLICY" removed_recovery_path "$EXPECTED_RECOVERY_PATH" "removed recovery-path binding"
check_json_eq "$POLICY" post_package_snapshot_sha256 ab69ead76bd994fd5198fa0351b9ecc66a6b2af986965751750e54aaa69e054f "package baseline binding"
check_json_eq "$POLICY" active_module_object_manifest_sha256 4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425 "active-module baseline binding"
check_json_eq "$POLICY" rollback_module_objects_manifest_sha256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 "rollback absence binding"
check_json_eq "$POLICY" boot_state_sha256 6600fc6131428963ec9726983a061990e3605ed724e19ca0f718337793a224b8 "boot-state baseline binding"
check_json_eq "$POLICY" elilo_conf_sha256 94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6 "ELILO baseline binding"

check_json_eq "$ACCEPTED_FINAL_STATE" accepted true "step-114 record is explicitly accepted"
check_json_eq "$ACCEPTED_FINAL_STATE" archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "step-114 record binds the accepted archive"
check_json_eq "$ACCEPTED_FINAL_STATE" final_state_review_passed true "step-114 final-state review passed"
check_json_eq "$ACCEPTED_FINAL_STATE" cleanup_final_state_accepted true "step-114 accepted the cleanup final state"
check_json_eq "$ACCEPTED_FINAL_STATE" rollback_state_absent true "step-114 confirms rollback state absence"
check_json_eq "$ACCEPTED_FINAL_STATE" recovery_backup_absent true "step-114 confirms recovery backup absence"
check_json_eq "$ACCEPTED_FINAL_STATE" destructive_action_authorized false "step-114 leaves destructive action unauthorized"
check_json_eq "$ACCEPTED_FINAL_STATE" system_state_preserved true "step-114 confirms persistent state preservation"
check_json_eq "$ACCEPTED_FINAL_STATE" pause_safe true "step-114 preserves a safe pause"
check_json_eq "$ACCEPTED_FINAL_STATE" next_stage elilo-oldkernel-cleanup-destructive-boundary-closure "step-114 advances only to destructive-boundary closure"

if grep -Fq 'ROLLBACK_PACKAGE_COUNT=' "$REVIEW_SCRIPT" && grep -Fq 'OLDKERNEL_EXECUTABLE_REFS=' "$REVIEW_SCRIPT"; then pass "closure explicitly checks historical rollback destructive targets"; else fail "rollback-target closure checks are missing"; fi
if grep -Fq 'HISTORICAL_AUTHORIZATIONS_CONSUMED=true' "$REVIEW_SCRIPT" && grep -Fq 'PENDING_DESTRUCTIVE_ACTION=false' "$REVIEW_SCRIPT"; then pass "closure explicitly exhausts historical destructive authorization"; else fail "authorization exhaustion is missing"; fi
if grep -Fq 'DESTRUCTIVE_BOUNDARY_CLOSED=true' "$REVIEW_SCRIPT"; then pass "successful review closes the destructive boundary"; else fail "destructive-boundary closure result is missing"; fi
if grep -Fq 'NEXT_STAGE=elilo-oldkernel-cleanup-scenario-closure-checkpoint' "$REVIEW_SCRIPT"; then pass "successful closure advances only to scenario checkpoint"; else fail "closure next-stage boundary is incorrect"; fi
if grep -Fq 'PAUSE_SAFE=true' "$REVIEW_SCRIPT"; then pass "successful closure establishes a safe pause"; else fail "safe-pause result is missing"; fi
if grep -Fq '! -e $EXPECTED_REMOVED_RECOVERY_PATH' "$REVIEW_SCRIPT" && grep -Fq '! -L $EXPECTED_REMOVED_RECOVERY_PATH' "$REVIEW_SCRIPT"; then pass "closure requires the historical recovery target to remain absent"; else fail "recovery-target absence check is incomplete"; fi

if ! grep -Eq '^[[:space:]]*(rm|unlink|rmdir)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "closure source contains no removal command"; else fail "closure source contains a removal command"; fi
if ! grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "closure source contains no package-manager mutation command"; else fail "closure source contains package-manager mutation"; fi
if ! grep -Eq '^[[:space:]]*(eliloconfig|elilo)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "closure source contains no ELILO mutation command"; else fail "closure source contains ELILO mutation"; fi
if ! grep -Eq '^[[:space:]]*(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "closure source contains no reboot or shutdown execution"; else fail "closure source contains reboot/shutdown execution"; fi
if ! grep -Eq '^[[:space:]]*(curl|wget|ftp|git (fetch|pull|clone))([[:space:]]|$)' "$REVIEW_SCRIPT"; then pass "closure source contains no network client command"; else fail "closure source contains a network command"; fi

scope=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-destructive-boundary-closure' \
        "accepted_final_state_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_final_state_record_sha256=$(sha_file "$ACCEPTED_FINAL_STATE")" \
        "accepted_final_state_script_sha256=$(sha_file "$STEP114_SCRIPT")" \
        "accepted_final_state_policy_sha256=$(sha_file "$STEP114_POLICY")" \
        "closure_policy_sha256=$(sha_file "$POLICY")" \
        "closure_script_sha256=$(sha_file "$REVIEW_SCRIPT")" \
        'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
        'active_kernel=5.15.209' \
        'rollback_kernel=5.15.19' \
        'required_boot_image_suffix=\EFI\Slackware\vmlinuz-generic-5.15.209' \
        "removed_recovery_path=$EXPECTED_RECOVERY_PATH" \
        | sha256sum | awk '{print $1}'
)
[[ $scope == "$EXPECTED_SCOPE_SHA256" ]] && pass "calculated closure confirmation scope matches the prepared immutable boundary" || fail "calculated closure confirmation scope differs: $scope"
if grep -Fq "printf '%s  %s\\n' \"\$ARCHIVE_SHA256\" \"\$(basename \"\$ARCHIVE\")\"" "$REVIEW_SCRIPT"; then pass "evidence sidecar records only the portable archive basename"; else fail "evidence sidecar portability contract is missing"; fi
if grep -Fq 'sudo install -o promano -g users -m 0600' "$REVIEW_SCRIPT" && grep -Fq '/home/promano/' "$REVIEW_SCRIPT"; then pass "closure prints direct /home/promano evidence-copy commands with required ownership"; else fail "required evidence-copy command is missing"; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
