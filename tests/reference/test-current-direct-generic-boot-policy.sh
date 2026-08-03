#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
ACCEPTED_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-accepted.json"

# Source the reference implementation without invoking main().
# shellcheck source=../../tools/reference/slack-update-reference.sh
source "$REFERENCE_SCRIPT"

TEST_COUNT=0
FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BOOT="$TMP/boot"
MODULES="$TMP/modules"
PKGDB_REAL="$TMP/pkgtools/packages"
PKGDB_COMPAT="$TMP/var-log-packages"
CMDLINE="$TMP/cmdline"
GRUB_CONFIG="$TMP/grub.cfg"
MKINITRD_CONFIG="$TMP/mkinitrd.conf"
INITRD_IMAGE="$BOOT/initrd.gz"
GENERIC_LINK="$BOOT/vmlinuz-generic"
AFTER_SNAPSHOT="$TMP/packages.after"
mkdir -p "$BOOT" "$MODULES/6.18.40" "$PKGDB_REAL"
ln -s pkgtools/packages "$PKGDB_COMPAT"
printf 'kernel-6.18.40\n' > "$BOOT/vmlinuz-6.18.40"
ln -s vmlinuz-6.18.40 "$GENERIC_LINK"
printf 'BOOT_IMAGE=/boot/vmlinuz-generic root=/dev/sda2 ro\n' > "$CMDLINE"
printf 'menuentry test {\n  linux /boot/vmlinuz-generic root=/dev/sda2 ro\n}\n' > "$GRUB_CONFIG"
cat > "$PKGDB_REAL/kernel-generic-6.18.40-x86_64-1" <<'EOF_RECORD'
boot/vmlinuz-6.18.40
boot/vmlinuz-generic
lib/modules/6.18.40/
lib/modules/6.18.40/kernel/test.ko
EOF_RECORD

INITRD_KERNEL_PACKAGE=kernel-generic
assert_success 'the accepted direct-generic evidence fixture should be valid JSON' python3 -m json.tool "$ACCEPTED_FIXTURE"
assert_contains '"accepted": true' "$ACCEPTED_FIXTURE" 'the corrected real-system preflight should be accepted'
assert_contains '"boot_mode": "direct-generic-no-initrd"' "$ACCEPTED_FIXTURE" 'the accepted fixture should preserve the boot mode'
assert_contains '"apply_ready": false' "$ACCEPTED_FIXTURE" 'discovery evidence must not authorize apply readiness'
assert_contains '"apply_authorized": false' "$ACCEPTED_FIXTURE" 'discovery evidence must deny apply'

assert_contains 'classify_direct_generic_boot_layout' "$REFERENCE_SCRIPT" 'the reference should expose direct-generic classification'
assert_contains 'validate_direct_generic_kernel_configuration' "$REFERENCE_SCRIPT" 'the reference should validate the post-update direct kernel'
assert_contains 'direct-generic-no-initrd' "$REFERENCE_SCRIPT" 'the direct boot mode should be explicit'
assert_contains 'generated GRUB configuration does not reference the validated direct-generic kernel' "$REFERENCE_SCRIPT" 'generated GRUB output should be tied to the validated kernel'
assert_not_contains 'mkinitrd -F >/dev/null' "$REFERENCE_SCRIPT" 'direct mode must not hide an unconditional initrd regeneration'

assert_success 'a coherent direct-generic layout should classify' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
assert_equal "$BOOT/vmlinuz-6.18.40" "$BOOT_DIRECT_GENERIC_KERNEL_PATH" 'the resolved kernel path should be preserved'
assert_equal 6.18.40 "$BOOT_DIRECT_GENERIC_KERNEL_VERSION" 'the installed kernel version should be preserved'
assert_equal kernel-generic-6.18.40-x86_64-1 "$BOOT_DIRECT_GENERIC_PACKAGE_RECORD" 'the exact package record should be preserved'
assert_equal /boot/vmlinuz-generic "$BOOT_DIRECT_GENERIC_BOOT_IMAGE" 'the boot image should be preserved'

printf 'initrd\n' > "$INITRD_IMAGE"
assert_failure 'an unexpected initrd should reject direct mode' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
rm -f "$INITRD_IMAGE"
printf 'KERNEL_VERSION=6.18.40\n' > "$MKINITRD_CONFIG"
assert_failure 'an unexpected mkinitrd configuration should reject direct mode' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
rm -f "$MKINITRD_CONFIG"

ln -sfn vmlinuz-6.18.39 "$GENERIC_LINK"
assert_failure 'a generic link for another kernel should fail closed' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
ln -sfn vmlinuz-6.18.40 "$GENERIC_LINK"

cp "$PKGDB_REAL/kernel-generic-6.18.40-x86_64-1" "$TMP/record.good"
printf 'boot/vmlinuz-6.18.40\n' > "$PKGDB_REAL/kernel-generic-6.18.40-x86_64-1"
assert_failure 'a package record without the module tree should be rejected' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
cp "$TMP/record.good" "$PKGDB_REAL/kernel-generic-6.18.40-x86_64-1"
cp "$TMP/record.good" "$PKGDB_REAL/kernel-generic-6.18.39-x86_64-1"
assert_failure 'multiple installed generic kernel records should be rejected' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
rm -f "$PKGDB_REAL/kernel-generic-6.18.39-x86_64-1"

printf 'BOOT_IMAGE=/boot/vmlinuz-generic BOOT_IMAGE=/boot/vmlinuz-6.18.40 ro\n' > "$CMDLINE"
assert_failure 'duplicate BOOT_IMAGE assignments should be rejected' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
printf 'BOOT_IMAGE=/boot/vmlinuz-huge ro\n' > "$CMDLINE"
assert_failure 'an unrelated BOOT_IMAGE should be rejected' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
printf 'BOOT_IMAGE=/boot/vmlinuz-6.18.40/escape ro\n' > "$CMDLINE"
assert_failure 'a versioned BOOT_IMAGE containing a slash should be rejected' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
printf 'BOOT_IMAGE=/boot/vmlinuz-generic root=/dev/sda2 ro\n' > "$CMDLINE"
printf '# /boot/vmlinuz-generic\nmenuentry test {\n  linux /boot/vmlinuz-6.18.39 root=/dev/sda2 ro\n}\n' > "$GRUB_CONFIG"
assert_failure 'GRUB must reference the running BOOT_IMAGE' \
    classify_direct_generic_boot_layout "$PKGDB_COMPAT" "$CMDLINE" "$GRUB_CONFIG" "$GENERIC_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_IMAGE" "$MODULES" 6.18.40
printf 'menuentry test {\n  linux /boot/vmlinuz-generic root=/dev/sda2 ro\n}\n' > "$GRUB_CONFIG"

FAKE_BIN="$TMP/bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/grub-mkconfig" <<'EOF_GRUB_MKCONFIG'
#!/bin/sh
exit 0
EOF_GRUB_MKCONFIG
cat > "$FAKE_BIN/grub-script-check" <<'EOF_GRUB_CHECK'
#!/bin/sh
exit "${GRUB_CHECK_STATUS:-0}"
EOF_GRUB_CHECK
chmod +x "$FAKE_BIN/grub-mkconfig" "$FAKE_BIN/grub-script-check"
OLD_PATH=$PATH
PATH="$FAKE_BIN:$PATH"
PACKAGE_DATABASE=$PKGDB_COMPAT
BOOT_CMDLINE_FILE=$CMDLINE
GRUB_DIRECTORY=$TMP
GRUB_CONFIG=$GRUB_CONFIG
GENERIC_KERNEL_LINK=$GENERIC_LINK
MKINITRD_CONFIG=$MKINITRD_CONFIG
INITRD_DEFAULT_OUTPUT=$INITRD_IMAGE
KERNEL_MODULES_DIRECTORY=$MODULES
RUNNING_KERNEL=6.18.40
BOOT_MODE=auto
GRUB_CHECK_STATUS=0
export GRUB_CHECK_STATUS
probe_boot_module
assert_equal available "$BOOT_MODULE_STATE" 'auto mode should activate the coherent direct-generic path'
assert_equal 1 "$BOOT_MODULE_RUN" 'the direct-generic boot module should run'
assert_equal 1 "$BOOT_DIRECT_GENERIC_AVAILABLE" 'the direct-generic probe should be available'
assert_equal direct-generic-no-initrd "$BOOT_PREPARATION_LAYOUT" 'the direct-generic layout should be preserved'
GRUB_CHECK_STATUS=1
probe_boot_module
assert_equal available "$BOOT_MODULE_STATE" 'auto mode should preserve partial inspection when GRUB validation fails'
assert_equal partial "$BOOT_PREPARATION_LAYOUT" 'a failed direct probe should not claim the direct layout'
assert_equal 0 "$BOOT_DIRECT_GENERIC_AVAILABLE" 'a failed GRUB syntax check should reject direct availability'
PATH=$OLD_PATH
unset GRUB_CHECK_STATUS

BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd
BOOT_MODE=auto
BOOT_INITRD_AVAILABLE=0
BOOT_GRUB_AVAILABLE=1
INITRD_UPDATE=1
GRUB_UPDATE=1
apply_boot_module_policy
assert_equal 0 "$INITRD_REQUIRED" 'direct mode should not require initrd regeneration'
assert_equal 0 "$INITRD_UPDATE" 'direct mode should suppress initrd execution'
assert_equal 1 "$GRUB_REQUIRED" 'direct mode should still require GRUB regeneration'
assert_equal 1 "$GRUB_UPDATE" 'direct mode should keep GRUB execution enabled'

BOOT_PREPARATION_LAYOUT=mkinitrd-managed
BOOT_MODE=auto
BOOT_INITRD_AVAILABLE=1
BOOT_GRUB_AVAILABLE=1
INITRD_UPDATE=1
GRUB_UPDATE=1
apply_boot_module_policy
assert_equal 1 "$INITRD_REQUIRED" 'managed mode should preserve the initrd requirement'
assert_equal 1 "$INITRD_UPDATE" 'managed mode should preserve initrd execution'
assert_equal 1 "$GRUB_REQUIRED" 'managed mode should require GRUB regeneration'
assert_equal 1 "$GRUB_UPDATE" 'managed mode should preserve GRUB execution'

# Validate the post-update direct kernel against isolated paths.
printf '%s\n' kernel-generic-6.18.41-x86_64-1 > "$AFTER_SNAPSHOT"
printf 'kernel-6.18.41\n' > "$BOOT/vmlinuz-6.18.41"
ln -sfn vmlinuz-6.18.41 "$GENERIC_LINK"
mkdir -p "$MODULES/6.18.41"
cat > "$PKGDB_REAL/kernel-generic-6.18.41-x86_64-1" <<'EOF_NEW_RECORD'
boot/vmlinuz-6.18.41
boot/vmlinuz-generic
lib/modules/6.18.41/
lib/modules/6.18.41/kernel/test.ko
EOF_NEW_RECORD
rm -f "$PKGDB_REAL/kernel-generic-6.18.40-x86_64-1"
PACKAGE_DATABASE=$PKGDB_COMPAT
AFTER_PKGS=$AFTER_SNAPSHOT
KERNEL_MODULES_DIRECTORY=$MODULES
GENERIC_KERNEL_LINK=$GENERIC_LINK
MKINITRD_CONFIG=$MKINITRD_CONFIG
INITRD_DEFAULT_OUTPUT=$INITRD_IMAGE
BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd
assert_success 'a coherent post-update direct kernel should validate' validate_direct_generic_kernel_configuration
assert_equal 0 "$DIRECT_GENERIC_VALIDATION_STATUS" 'successful direct validation should expose status zero'
assert_equal 6.18.41 "$DIRECT_GENERIC_INSTALLED_KERNEL_VERSION" 'the post-update version should come from the package snapshot'
assert_equal "$BOOT/vmlinuz-6.18.41" "$DIRECT_GENERIC_KERNEL_PATH" 'the post-update generic link target should be preserved'
assert_equal "$MODULES/6.18.41" "$DIRECT_GENERIC_MODULES_PATH" 'the post-update module path should be preserved'

printf 'menuentry target {\n  linux /boot/vmlinuz-6.18.41 root=/dev/sda2 ro\n}\n' > "$TMP/generated-grub.cfg"
assert_success 'generated GRUB should accept the validated target kernel' \
    validate_generated_direct_generic_grub_config "$TMP/generated-grub.cfg"
printf 'menuentry stale {\n  linux /boot/vmlinuz-6.18.40 root=/dev/sda2 ro\n}\n' > "$TMP/generated-grub.cfg"
assert_failure 'generated GRUB should reject a stale direct kernel' \
    validate_generated_direct_generic_grub_config "$TMP/generated-grub.cfg"

OPERATION=apply
RESULT_ERRORS=()
CRITICAL_UPDATED=()
INITRD_REQUIRED=0
INITRD_UPDATE=0
GRUB_REQUIRED=1
GRUB_UPDATE=1
GRUB_OK=1
calculate_result_state 0
assert_equal 1 "$RESULT_SUCCESS" 'a successful direct GRUB transaction should report success'
assert_equal 1 "$RESULT_BOOT_SAFE" 'a successful direct GRUB transaction should remain boot-safe'
assert_equal required "$RESULT_REBOOT" 'a direct kernel transition should require reboot'
GRUB_OK=0
calculate_result_state 0
assert_equal 0 "$RESULT_SUCCESS" 'a failed direct GRUB transaction should fail the result'
assert_equal 0 "$RESULT_BOOT_SAFE" 'a failed direct GRUB transaction should be boot-unsafe'
assert_equal unsafe "$RESULT_REBOOT" 'a failed direct GRUB transaction should require recovery before reboot'

rm -rf "$MODULES/6.18.41"
assert_failure 'a missing post-update module tree should block GRUB' validate_direct_generic_kernel_configuration
assert_equal 1 "$DIRECT_GENERIC_VALIDATION_STATUS" 'failed direct validation should expose status one'
mkdir -p "$MODULES/6.18.41"
printf 'initrd\n' > "$INITRD_IMAGE"
assert_failure 'an unexpected post-update initrd should block direct mode' validate_direct_generic_kernel_configuration
rm -f "$INITRD_IMAGE"

bash -n "$REFERENCE_SCRIPT" && pass || fail 'the reference script should pass bash -n'

printf 'Current direct-generic boot policy harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
