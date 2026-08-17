#!/usr/bin/env bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
CHECKPOINT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-scenario-closure-checkpoint.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-policy.json"
ACCEPTED_CLOSURE="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-destructive-boundary-closure-20260817-accepted.json"
STEP115_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-destructive-boundary-closure.sh"
STEP115_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-destructive-boundary-closure-policy.json"

EXPECTED_CHECKPOINT_SHA256=a46fffcc39efea85d0ffc6d407836cbd3b2a74ef45df9cdef3bbba1b065e5a06
EXPECTED_POLICY_SHA256=7d62ac199c74eb8fbe60bb88953f13eb9be1ae15a8d2308f10f95d5e0a2ca038
EXPECTED_ACCEPTED_RECORD_SHA256=7bb415bb71c47763b5a6b1db8eb9faf1c324b3d9711c8c9cf442a37663882601
EXPECTED_STEP115_SCRIPT_SHA256=8fb0061725acc8e867552d56869ac4114445ff90c681b113d37ff96a5b02dea2
EXPECTED_STEP115_POLICY_SHA256=e758081200e59e4e48cf5f133a538f49ec92f57d5700e21110b3bf8b23bcd813
EXPECTED_ARCHIVE_SHA256=439465cf4c48ec85c7257a0fefa12d561796212f3aa807215a06a9ac897000d4
EXPECTED_SCOPE_SHA256=dd194234a20b913993ade561987dd1857c16f4f58afc3d8fbc3096e7c8b7ff53
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
check_json_eq() {
    local file=$1 path=$2 expected=$3 description=$4 actual
    actual=$(json_value "$file" "$path" 2>/dev/null || true)
    [[ $actual == "$expected" ]] && pass "$description" || fail "$description"
}

for item in "$CHECKPOINT" "$POLICY" "$ACCEPTED_CLOSURE" "$STEP115_SCRIPT" "$STEP115_POLICY"; do
    [[ -f $item && ! -L $item ]] && pass "$(basename "$item") is a regular non-symlink file" || fail "unsafe or missing file: $item"
done

[[ $(sha_file "$CHECKPOINT") == "$EXPECTED_CHECKPOINT_SHA256" ]] && pass "scenario checkpoint has the exact prepared SHA-256" || fail "scenario checkpoint SHA-256 differs"
[[ $(sha_file "$POLICY") == "$EXPECTED_POLICY_SHA256" ]] && pass "scenario-checkpoint policy has the exact prepared SHA-256" || fail "checkpoint policy SHA-256 differs"
[[ $(sha_file "$ACCEPTED_CLOSURE") == "$EXPECTED_ACCEPTED_RECORD_SHA256" ]] && pass "accepted step-115 record has the exact reviewed SHA-256" || fail "accepted step-115 record SHA-256 differs"
[[ $(sha_file "$STEP115_SCRIPT") == "$EXPECTED_STEP115_SCRIPT_SHA256" ]] && pass "step-115 closure script remains byte-identical" || fail "step-115 script changed"
[[ $(sha_file "$STEP115_POLICY") == "$EXPECTED_STEP115_POLICY_SHA256" ]] && pass "step-115 closure policy remains byte-identical" || fail "step-115 policy changed"

bash -n "$CHECKPOINT" && pass "scenario checkpoint is shell-syntax valid" || fail "scenario checkpoint has shell syntax errors"
"$CHECKPOINT" --help >/dev/null 2>&1
[[ $? -eq 0 ]] && pass "scenario checkpoint exposes a non-mutating help boundary" || fail "checkpoint help boundary failed"
set +e
"$CHECKPOINT" --definitely-unknown >/dev/null 2>&1
unknown_rc=$?
set -e
[[ $unknown_rc -eq 2 ]] && pass "unknown options fail closed" || fail "unknown options do not fail closed with exit 2"

check_json_eq "$POLICY" schema 1 "policy schema"
check_json_eq "$POLICY" scenario elilo-oldkernel-cleanup-scenario-closure-checkpoint "policy scenario"
check_json_eq "$POLICY" reviewed true "scenario-checkpoint policy is reviewed"
check_json_eq "$POLICY" checkpoint_review_only true "scenario checkpoint is review-only"
check_json_eq "$POLICY" destructive_action_authorized false "destructive action remains unauthorized"
check_json_eq "$POLICY" pending_destructive_action false "no destructive action is pending"
check_json_eq "$POLICY" historical_authorizations_consumed true "historical destructive authorizations remain consumed"
check_json_eq "$POLICY" machine_action_required false "no machine action is required after successful checkpoint"
check_json_eq "$POLICY" future_work_requires_fresh_boundary true "future work requires a fresh review boundary"
check_json_eq "$POLICY" recovery_path_mutation_authorized false "recovery mutation remains denied"
check_json_eq "$POLICY" package_mutation_authorized false "package mutation remains denied"
check_json_eq "$POLICY" boot_mutation_authorized false "boot mutation remains denied"
check_json_eq "$POLICY" module_mutation_authorized false "module mutation remains denied"
check_json_eq "$POLICY" repository_refresh_authorized false "repository refresh remains denied"
check_json_eq "$POLICY" network_access_authorized false "network access remains denied"
check_json_eq "$POLICY" reboot_authorized false "reboot execution remains denied"
check_json_eq "$POLICY" transient_boot_id_equality_required false "transient boot-ID equality remains released"
check_json_eq "$POLICY" stable_boot_identity_required true "stable boot identity remains required"
check_json_eq "$POLICY" expected_script_sha256 "$EXPECTED_CHECKPOINT_SHA256" "policy binds the exact checkpoint script"
check_json_eq "$POLICY" accepted_closure_record_sha256 "$EXPECTED_ACCEPTED_RECORD_SHA256" "policy binds the exact accepted step-115 record"
check_json_eq "$POLICY" accepted_closure_archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "policy binds the exact step-115 evidence archive"
check_json_eq "$POLICY" accepted_closure_script_sha256 "$EXPECTED_STEP115_SCRIPT_SHA256" "policy binds the exact step-115 closure code"
check_json_eq "$POLICY" accepted_closure_policy_sha256 "$EXPECTED_STEP115_POLICY_SHA256" "policy binds the exact step-115 closure policy"
check_json_eq "$POLICY" hostname_fqdn vbox-slack15.vbox-slack15.org "host binding"
check_json_eq "$POLICY" active_kernel 5.15.209 "active-kernel binding"
check_json_eq "$POLICY" rollback_kernel 5.15.19 "rollback-kernel binding"
check_json_eq "$POLICY" required_boot_image_suffix '\EFI\Slackware\vmlinuz-generic-5.15.209' "stable BOOT_IMAGE binding"
check_json_eq "$POLICY" removed_recovery_path "$EXPECTED_RECOVERY_PATH" "retired recovery-path binding"
check_json_eq "$POLICY" post_package_snapshot_sha256 ab69ead76bd994fd5198fa0351b9ecc66a6b2af986965751750e54aaa69e054f "package baseline binding"
check_json_eq "$POLICY" active_module_object_manifest_sha256 4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425 "active-module baseline binding"
check_json_eq "$POLICY" rollback_module_objects_manifest_sha256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 "rollback-module absence binding"
check_json_eq "$POLICY" boot_state_sha256 6600fc6131428963ec9726983a061990e3605ed724e19ca0f718337793a224b8 "boot-state baseline binding"
check_json_eq "$POLICY" elilo_conf_sha256 94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6 "ELILO baseline binding"

check_json_eq "$ACCEPTED_CLOSURE" accepted true "step-115 record is explicitly accepted"
check_json_eq "$ACCEPTED_CLOSURE" archive_sha256 "$EXPECTED_ARCHIVE_SHA256" "step-115 record binds the accepted archive"
check_json_eq "$ACCEPTED_CLOSURE" destructive_boundary_closed true "step-115 record confirms destructive-boundary closure"
check_json_eq "$ACCEPTED_CLOSURE" historical_authorizations_consumed true "step-115 record confirms historical authorization exhaustion"
check_json_eq "$ACCEPTED_CLOSURE" pending_destructive_action false "step-115 record confirms no pending destructive action"
check_json_eq "$ACCEPTED_CLOSURE" rollback_targets_absent true "step-115 record confirms rollback targets are absent"
check_json_eq "$ACCEPTED_CLOSURE" recovery_target_absent true "step-115 record confirms the recovery target is absent"
check_json_eq "$ACCEPTED_CLOSURE" system_state_preserved true "step-115 record confirms persistent state preservation"
check_json_eq "$ACCEPTED_CLOSURE" pause_safe true "step-115 record preserves a safe pause"
check_json_eq "$ACCEPTED_CLOSURE" next_stage elilo-oldkernel-cleanup-scenario-closure-checkpoint "step-115 advances only to scenario closure"

check_json_eq "$POLICY" successful_result.scenario_closure_checkpoint true "successful checkpoint is explicitly recorded"
check_json_eq "$POLICY" successful_result.cleanup_scenario_closed true "successful checkpoint closes the cleanup scenario"
check_json_eq "$POLICY" successful_result.destructive_boundary_closed true "successful checkpoint preserves destructive-boundary closure"
check_json_eq "$POLICY" successful_result.historical_authorizations_consumed true "successful checkpoint preserves authorization exhaustion"
check_json_eq "$POLICY" successful_result.pending_destructive_action false "successful checkpoint leaves no pending destructive action"
check_json_eq "$POLICY" successful_result.machine_action_required false "successful checkpoint requires no machine action"
check_json_eq "$POLICY" successful_result.rollback_state_absent true "successful checkpoint preserves rollback absence"
check_json_eq "$POLICY" successful_result.recovery_backup_absent true "successful checkpoint preserves recovery absence"
check_json_eq "$POLICY" successful_result.system_state_preserved true "successful checkpoint preserves persistent system state"
check_json_eq "$POLICY" successful_result.future_work_requires_fresh_boundary true "successful checkpoint requires a fresh future boundary"
check_json_eq "$POLICY" successful_result.pause_safe true "successful checkpoint is a safe pause"
check_json_eq "$POLICY" successful_result.next_stage phase-1-resume-planning "successful checkpoint returns only to phase-1 planning"

if grep -Fq 'MACHINE_ACTION_REQUIRED=false' "$CHECKPOINT" && grep -Fq 'FUTURE_WORK_REQUIRES_FRESH_BOUNDARY=true' "$CHECKPOINT"; then pass "checkpoint explicitly leaves no machine action and requires a fresh future boundary"; else fail "checkpoint no-action/fresh-boundary contract is incomplete"; fi
if grep -Fq 'CLEANUP_SCENARIO_CLOSED=true' "$CHECKPOINT" && grep -Fq 'NEXT_STAGE=phase-1-resume-planning' "$CHECKPOINT"; then pass "successful checkpoint closes the scenario and returns to planning"; else fail "scenario-closure result is incomplete"; fi
if grep -Fq 'PAUSE_SAFE=true' "$CHECKPOINT"; then pass "successful checkpoint establishes a safe pause"; else fail "safe-pause result is missing"; fi
if grep -Fq '! -e $EXPECTED_REMOVED_RECOVERY_PATH' "$CHECKPOINT" && grep -Fq '! -L $EXPECTED_REMOVED_RECOVERY_PATH' "$CHECKPOINT"; then pass "checkpoint requires the retired recovery target to remain absent"; else fail "recovery absence check is incomplete"; fi
if grep -Fq 'OLDKERNEL_EXECUTABLE_REFS=' "$CHECKPOINT" && grep -Fq 'ROLLBACK_PACKAGE_COUNT=' "$CHECKPOINT"; then pass "checkpoint independently rechecks rollback package and ELILO absence"; else fail "rollback absence checks are incomplete"; fi

if ! grep -Eq '^[[:space:]]*(rm|unlink|rmdir)([[:space:]]|$)' "$CHECKPOINT"; then pass "checkpoint source contains no removal command"; else fail "checkpoint source contains a removal command"; fi
if ! grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg)([[:space:]]|$)' "$CHECKPOINT"; then pass "checkpoint source contains no package-manager mutation command"; else fail "checkpoint source contains package-manager mutation"; fi
if ! grep -Eq '^[[:space:]]*(eliloconfig|elilo)([[:space:]]|$)' "$CHECKPOINT"; then pass "checkpoint source contains no ELILO mutation command"; else fail "checkpoint source contains ELILO mutation"; fi
if ! grep -Eq '^[[:space:]]*(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$CHECKPOINT"; then pass "checkpoint source contains no reboot or shutdown execution"; else fail "checkpoint source contains reboot/shutdown execution"; fi
if ! grep -Eq '^[[:space:]]*(curl|wget|ftp|git (fetch|pull|clone))([[:space:]]|$)' "$CHECKPOINT"; then pass "checkpoint source contains no network client command"; else fail "checkpoint source contains a network command"; fi

scope=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-scenario-closure-checkpoint' \
        "accepted_closure_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_closure_record_sha256=$(sha_file "$ACCEPTED_CLOSURE")" \
        "accepted_closure_script_sha256=$(sha_file "$STEP115_SCRIPT")" \
        "accepted_closure_policy_sha256=$(sha_file "$STEP115_POLICY")" \
        "checkpoint_policy_sha256=$(sha_file "$POLICY")" \
        "checkpoint_script_sha256=$(sha_file "$CHECKPOINT")" \
        'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
        'active_kernel=5.15.209' \
        'rollback_kernel=5.15.19' \
        'required_boot_image_suffix=\EFI\Slackware\vmlinuz-generic-5.15.209' \
        "removed_recovery_path=$EXPECTED_RECOVERY_PATH" \
        | sha256sum | awk '{print $1}'
)
[[ $scope == "$EXPECTED_SCOPE_SHA256" ]] && pass "calculated checkpoint confirmation scope matches the prepared immutable boundary" || fail "calculated checkpoint scope differs: $scope"
if grep -Fq "printf '%s  %s\\n' \"\$ARCHIVE_SHA256\" \"\$(basename \"\$ARCHIVE\")\"" "$CHECKPOINT"; then pass "evidence sidecar records only the portable archive basename"; else fail "evidence sidecar portability contract is missing"; fi
if grep -Fq 'sudo install -o promano -g users -m 0600' "$CHECKPOINT" && grep -Fq '/home/promano/' "$CHECKPOINT"; then pass "checkpoint prints direct /home/promano evidence-copy commands with required ownership"; else fail "required evidence-copy command is missing"; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
