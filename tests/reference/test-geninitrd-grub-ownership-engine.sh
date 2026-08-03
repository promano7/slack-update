#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
ACCEPTED_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260803-accepted.json"

# shellcheck source=../../tools/reference/slack-update-reference.sh
source "$REFERENCE_SCRIPT"

TEST_COUNT=0
FAILURE_COUNT=0

pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_equal() {
    local expected=$1 actual=$2 message=$3
    [ "$expected" = "$actual" ] && pass || fail "$message (expected '$expected', got '$actual')"
}
assert_status() {
    local expected=$1 message=$2 status
    shift 2
    "$@" >/dev/null 2>&1
    status=$?
    assert_equal "$expected" "$status" "$message"
}
assert_file_contains() {
    grep -Fq -- "$1" "$2" && pass || fail "$3"
}
assert_file_not_contains() {
    grep -Fq -- "$1" "$2" && fail "$3" || pass
}
assert_file_missing() {
    [ ! -e "$1" ] && [ ! -L "$1" ] && pass || fail "$2"
}
assert_file_exists() {
    [ -f "$1" ] && [ ! -L "$1" ] && pass || fail "$2"
}
assert_files_equal() {
    cmp -s -- "$1" "$2" && pass || fail "$3"
}
assert_source_order() {
    local first=$1 second=$2 message=$3 a b
    a=$(grep -nF -- "$first" "$REFERENCE_SCRIPT" | head -n1 | cut -d: -f1)
    b=$(grep -nF -- "$second" "$REFERENCE_SCRIPT" | head -n1 | cut -d: -f1)
    [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] && pass || fail "$message"
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
POLICY_DIR="$TEST_TMP/etc/default"
mkdir -p "$POLICY_DIR"
GENINITRD_POLICY_PATH="$POLICY_DIR/geninitrd"

write_policy() {
    cat > "$GENINITRD_POLICY_PATH" <<'EOF_POLICY'
# Safe test policy
KERNEL=/boot/vmlinuz-generic
AUTOGENERATE_INITRD=true
AUTO_UPDATE_GRUB=true
GENINITRD_DIALOG=false
EOF_POLICY
    chmod 0640 "$GENINITRD_POLICY_PATH"
}

reset_state() {
    initialize_runtime_state
    GENINITRD_POLICY_PATH="$POLICY_DIR/geninitrd"
    BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd
    write_policy
    cp "$GENINITRD_POLICY_PATH" "$TEST_TMP/original.policy"
}

# Non-direct layouts must not touch the policy.
reset_state
BOOT_PREPARATION_LAYOUT=mkinitrd-managed
assert_status 0 'managed initrd layout should not require an override' prepare_geninitrd_grub_policy_override
assert_equal 0 "$GENINITRD_POLICY_OVERRIDE_REQUIRED" 'managed layout should report no override requirement'
assert_equal not-required "$GENINITRD_POLICY_OVERRIDE_STATUS" 'managed layout should retain not-required status'
assert_files_equal "$TEST_TMP/original.policy" "$GENINITRD_POLICY_PATH" 'managed layout must preserve the policy'

# The reviewed direct-generic layout must stage and atomically activate one exact change.
reset_state
assert_status 0 'reviewed direct-generic layout should activate the policy override' prepare_geninitrd_grub_policy_override
assert_equal 1 "$GENINITRD_POLICY_OVERRIDE_REQUIRED" 'direct layout should require GRUB ownership'
assert_equal 1 "$GENINITRD_POLICY_OVERRIDE_ACTIVE" 'successful staging should mark the override active'
assert_equal 1 "$GENINITRD_POLICY_OVERRIDE_APPLIED" 'successful staging should record application'
assert_equal 0 "$GENINITRD_POLICY_OVERRIDE_RESTORED" 'active override should not yet report restoration'
assert_equal active "$GENINITRD_POLICY_OVERRIDE_STATUS" 'successful staging should expose active status'
assert_file_contains 'AUTO_UPDATE_GRUB=false' "$GENINITRD_POLICY_PATH" 'active policy should disable automatic GRUB updates'
assert_file_not_contains 'AUTO_UPDATE_GRUB=true' "$GENINITRD_POLICY_PATH" 'active policy must not retain the true assignment'
assert_equal 1 "$(grep -Ec '^[[:space:]]*AUTO_UPDATE_GRUB[[:space:]]*=' "$GENINITRD_POLICY_PATH")" 'active policy should contain one assignment'
assert_equal 640 "$(stat -c '%a' "$GENINITRD_POLICY_PATH")" 'atomic override should preserve the policy mode'
assert_file_exists "$GENINITRD_POLICY_BACKUP" 'active override should retain a private original backup'
assert_files_equal "$TEST_TMP/original.policy" "$GENINITRD_POLICY_BACKUP" 'backup should be byte-identical to the original'
assert_file_missing "${GENINITRD_POLICY_STAGED:-$TEST_TMP/missing}" 'staged file should no longer exist after atomic replacement'
assert_status 0 'active override should restore atomically' restore_geninitrd_grub_policy_override
assert_equal 0 "$GENINITRD_POLICY_OVERRIDE_ACTIVE" 'restoration should clear active state'
assert_equal 1 "$GENINITRD_POLICY_OVERRIDE_RESTORED" 'restoration should be recorded'
assert_equal restored "$GENINITRD_POLICY_OVERRIDE_STATUS" 'restoration should expose stable status'
assert_files_equal "$TEST_TMP/original.policy" "$GENINITRD_POLICY_PATH" 'restored policy should be byte-identical to the original'
assert_file_missing "${GENINITRD_POLICY_BACKUP:-$TEST_TMP/missing}" 'successful restoration should consume its backup'

# Cleanup must restore an active override before removing runtime state.
reset_state
assert_status 0 'cleanup scenario should activate the override' prepare_geninitrd_grub_policy_override
cleanup >/dev/null 2>&1
assert_files_equal "$TEST_TMP/original.policy" "$GENINITRD_POLICY_PATH" 'cleanup should restore the original policy'
assert_equal 0 "$GENINITRD_POLICY_OVERRIDE_ACTIVE" 'cleanup restoration should clear active state'
assert_equal 1 "$GENINITRD_POLICY_OVERRIDE_RESTORED" 'cleanup restoration should be recorded'

# Unsafe policy forms fail before replacement.
reset_state
chmod 0660 "$GENINITRD_POLICY_PATH"
assert_status 1 'group-writable policy should fail closed' prepare_geninitrd_grub_policy_override
assert_equal failed "$GENINITRD_POLICY_OVERRIDE_STATUS" 'unsafe permissions should expose failed status'
assert_files_equal "$TEST_TMP/original.policy" "$GENINITRD_POLICY_PATH" 'unsafe permissions must not change content'
cleanup >/dev/null 2>&1

reset_state
printf 'AUTO_UPDATE_GRUB=true\n' >> "$GENINITRD_POLICY_PATH"
cp "$GENINITRD_POLICY_PATH" "$TEST_TMP/duplicate.policy"
assert_status 1 'duplicate active assignments should fail closed' prepare_geninitrd_grub_policy_override
assert_files_equal "$TEST_TMP/duplicate.policy" "$GENINITRD_POLICY_PATH" 'duplicate assignment failure must preserve content'
cleanup >/dev/null 2>&1

reset_state
sed -i 's/AUTO_UPDATE_GRUB=true/AUTO_UPDATE_GRUB=false/' "$GENINITRD_POLICY_PATH"
cp "$GENINITRD_POLICY_PATH" "$TEST_TMP/false.policy"
assert_status 0 'an already-false policy should preserve exclusive Slack-Update GRUB ownership without staging' prepare_geninitrd_grub_policy_override
assert_equal 0 "$GENINITRD_POLICY_OVERRIDE_REQUIRED" 'already-disabled policy should require no temporary override'
assert_equal already-disabled "$GENINITRD_POLICY_OVERRIDE_STATUS" 'already-disabled policy should expose stable no-op status'
assert_equal 0 "$GENINITRD_POLICY_OVERRIDE_ACTIVE" 'already-disabled policy should not become transaction-owned'
assert_files_equal "$TEST_TMP/false.policy" "$GENINITRD_POLICY_PATH" 'already-disabled policy must remain unchanged'
cleanup >/dev/null 2>&1

reset_state
mv "$GENINITRD_POLICY_PATH" "$GENINITRD_POLICY_PATH.real"
ln -s "$GENINITRD_POLICY_PATH.real" "$GENINITRD_POLICY_PATH"
assert_status 1 'a symbolic-link policy should fail closed' prepare_geninitrd_grub_policy_override
assert_equal failed "$GENINITRD_POLICY_OVERRIDE_STATUS" 'symbolic-link rejection should expose failed status'
rm -f "$GENINITRD_POLICY_PATH"
mv "$GENINITRD_POLICY_PATH.real" "$GENINITRD_POLICY_PATH"
cleanup >/dev/null 2>&1

# Concurrent changes after activation must refuse restoration and preserve the backup.
reset_state
assert_status 0 'concurrent-change scenario should activate the override' prepare_geninitrd_grub_policy_override
backup=$GENINITRD_POLICY_BACKUP
printf '# external change\n' >> "$GENINITRD_POLICY_PATH"
assert_status 1 'changed active policy should refuse restoration' restore_geninitrd_grub_policy_override
assert_equal restore-failed "$GENINITRD_POLICY_OVERRIDE_STATUS" 'concurrent change should expose restore-failed status'
assert_equal 1 "$GENINITRD_POLICY_OVERRIDE_ACTIVE" 'failed restoration should retain active recovery state'
assert_file_exists "$backup" 'failed restoration should retain the original backup'
command mv -fT -- "$backup" "$GENINITRD_POLICY_PATH"
GENINITRD_POLICY_BACKUP_OWNED=0
GENINITRD_POLICY_OVERRIDE_ACTIVE=0
assert_files_equal "$TEST_TMP/original.policy" "$GENINITRD_POLICY_PATH" 'manual recovery fixture should restore original bytes'

# Backup tampering must be detected before restoration.
reset_state
assert_status 0 'backup-tamper scenario should activate the override' prepare_geninitrd_grub_policy_override
backup=$GENINITRD_POLICY_BACKUP
printf '# tampered backup\n' >> "$backup"
assert_status 1 'tampered backup should block restoration' restore_geninitrd_grub_policy_override
assert_file_exists "$backup" 'tampered backup should remain available for investigation'
# Recover the isolated fixture without relying on the rejected backup.
cp "$TEST_TMP/original.policy" "$GENINITRD_POLICY_PATH"
chmod 0640 "$GENINITRD_POLICY_PATH"
rm -f "$backup"
GENINITRD_POLICY_BACKUP_OWNED=0
GENINITRD_POLICY_OVERRIDE_ACTIVE=0

# Source-level ordering and reporting guarantees.
assert_source_order 'prepare_geninitrd_grub_policy_override' 'update_slackware_system' 'override preparation should precede package operations'
prepare_line=$(grep -nF 'if ! prepare_geninitrd_grub_policy_override; then' "$REFERENCE_SCRIPT" | head -n1 | cut -d: -f1)
update_line=$(grep -nF '    update_slackware_system' "$REFERENCE_SCRIPT" | head -n1 | cut -d: -f1)
restore_line=$(grep -nF 'if restore_geninitrd_grub_policy_override; then' "$REFERENCE_SCRIPT" | tail -n1 | cut -d: -f1)
[ "$prepare_line" -lt "$update_line" ] && pass || fail 'apply workflow should prepare before package operations'
[ "$update_line" -lt "$restore_line" ] && pass || fail 'apply workflow should restore after package operations'
assert_file_contains 'restore_geninitrd_grub_policy_override 2>/dev/null' "$REFERENCE_SCRIPT" 'cleanup trap should attempt policy restoration'
assert_file_contains '"geninitrd_policy_override_required"' "$REFERENCE_SCRIPT" 'JSON should report override requirement'
assert_file_contains '"geninitrd_policy_override_applied"' "$REFERENCE_SCRIPT" 'JSON should report override application'
assert_file_contains '"geninitrd_policy_override_restored"' "$REFERENCE_SCRIPT" 'JSON should report override restoration'
assert_file_contains '"geninitrd_policy_override_active"' "$REFERENCE_SCRIPT" 'JSON should report residual active state'
assert_file_contains '"geninitrd_policy_override_error"' "$REFERENCE_SCRIPT" 'JSON should report restoration diagnostics'

# The accepted real-system record must remain immutable and non-authorizing.
python3 - "$ACCEPTED_RECORD" <<'PY' && pass || fail 'accepted ownership record is incomplete or authorizes apply'
import json,sys
p=sys.argv[1]
d=json.load(open(p, encoding='utf-8'))
checks=[
 d.get('scenario') == 'current-geninitrd-grub-ownership-preflight',
 d.get('accepted') is True,
 d.get('archive_sha256') == '246a54dd81c1db6ce2e7d04cb5d6e4739249e4a2f0483edcb9c7a5f1e0e93ad3',
 d.get('strategy') == 'temporary-atomic-policy-override',
 d.get('environment_override_safe') is False,
 d.get('transaction', {}).get('step_count') == 12,
 d.get('transaction', {}).get('recovery_boundary_count') == 5,
 d.get('commands_executed') == [],
 d.get('mutations_performed') == [],
 d.get('apply_ready') is False,
 d.get('apply_authorized') is False,
]
raise SystemExit(0 if all(checks) else 1)
PY

printf 'GenInitrd GRUB ownership engine tests: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
