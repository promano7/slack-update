#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
OWNERSHIP_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260803-accepted.json"
POST_STATE_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-post-state-synthetic.json"

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

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BOOT="$TMP/boot"
MODULES="$TMP/modules"
PKGDB_REAL="$TMP/pkgtools/packages"
PKGDB_COMPAT="$TMP/var-log-packages"
AFTER_SNAPSHOT="$TMP/packages.after"
MKINITRD_CONFIG="$TMP/mkinitrd.conf"
LEGACY_INITRD="$BOOT/initrd.gz"
GENERIC_LINK="$BOOT/vmlinuz-generic"
NAMED_INITRD_LINK="$BOOT/initrd-generic.img"
TARGET_KERNEL=6.18.41
TARGET_KERNEL_PATH="$BOOT/vmlinuz-$TARGET_KERNEL"
TARGET_INITRD="$BOOT/initrd-$TARGET_KERNEL.img"
TARGET_MODULES="$MODULES/$TARGET_KERNEL"
TARGET_RECORD="kernel-generic-$TARGET_KERNEL-x86_64-1"
POLICY="$TMP/geninitrd"
GRUB_CONFIG="$TMP/grub.cfg"

mkdir -p "$BOOT" "$TARGET_MODULES/kernel" "$PKGDB_REAL"
ln -s pkgtools/packages "$PKGDB_COMPAT"
printf 'kernel\n' > "$TARGET_KERNEL_PATH"
ln -s "vmlinuz-$TARGET_KERNEL" "$GENERIC_LINK"
printf 'initrd\n' > "$TARGET_INITRD"
chmod 600 "$TARGET_INITRD"
ln -s "initrd-$TARGET_KERNEL.img" "$NAMED_INITRD_LINK"
printf 'module\n' > "$TARGET_MODULES/kernel/test.ko"
printf '%s\n' "$TARGET_RECORD" > "$AFTER_SNAPSHOT"
cat > "$PKGDB_REAL/$TARGET_RECORD" <<EOF_RECORD
boot/vmlinuz-$TARGET_KERNEL
boot/vmlinuz-generic
lib/modules/$TARGET_KERNEL/
lib/modules/$TARGET_KERNEL/kernel/test.ko
EOF_RECORD
cat > "$POLICY" <<'EOF_POLICY'
AUTOGENERATE_INITRD=true
AUTO_UPDATE_GRUB=true
EOF_POLICY
chmod 644 "$POLICY"
cat > "$GRUB_CONFIG" <<EOF_GRUB
menuentry target {
  linux /boot/vmlinuz-$TARGET_KERNEL root=/dev/sda2 ro
  initrd /boot/initrd-$TARGET_KERNEL.img
}
EOF_GRUB

PACKAGE_DATABASE=$PKGDB_COMPAT
AFTER_PKGS=$AFTER_SNAPSHOT
KERNEL_MODULES_DIRECTORY=$MODULES
GENERIC_KERNEL_LINK=$GENERIC_LINK
MKINITRD_CONFIG=$MKINITRD_CONFIG
INITRD_DEFAULT_OUTPUT=$LEGACY_INITRD
GENINITRD_NAMED_INITRD_LINK=$NAMED_INITRD_LINK
GENINITRD_VERSIONED_INITRD_DIRECTORY=$BOOT
GENINITRD_POLICY_PATH=$POLICY
INITRD_KERNEL_PACKAGE=kernel-generic
BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd
GENINITRD_TRANSITION_EXPECTED=1

assert_success 'the accepted GRUB ownership fixture should be valid JSON' python3 -m json.tool "$OWNERSHIP_FIXTURE"
assert_contains '"accepted": true' "$OWNERSHIP_FIXTURE" 'the ownership fixture should be accepted'
assert_contains '"strategy": "temporary-atomic-policy-override"' "$OWNERSHIP_FIXTURE" 'the accepted ownership strategy should be preserved'
assert_contains '"apply_authorized": false' "$OWNERSHIP_FIXTURE" 'the accepted ownership fixture must deny apply'
assert_success 'the synthetic post-state contract should be valid JSON' python3 -m json.tool "$POST_STATE_FIXTURE"
assert_contains '"synthetic": true' "$POST_STATE_FIXTURE" 'the post-state fixture must remain explicitly synthetic'
assert_contains '"state": "generated-initrd"' "$POST_STATE_FIXTURE" 'the synthetic fixture should describe the generated-initrd state'
assert_contains '"requires_target_initrd_reference": true' "$POST_STATE_FIXTURE" 'the GRUB contract should require the target initrd'
assert_contains '"apply_authorized": false' "$POST_STATE_FIXTURE" 'the synthetic post-state contract must deny apply'

assert_contains 'validate_generated_initrd_transition_state' "$REFERENCE_SCRIPT" 'the engine should expose generated-initrd post-state validation'
assert_contains 'geninitrd_post_state' "$REFERENCE_SCRIPT" 'structured output should expose the generated-initrd post state'
assert_contains 'grub_config_references_initrd_path' "$REFERENCE_SCRIPT" 'the engine should inspect generated GRUB initrd lines'
assert_contains 'GENINITRD_TRANSITION_EXPECTED' "$REFERENCE_SCRIPT" 'the transaction should record whether GenInitrd output is mandatory'

assert_success 'a single true AUTOGENERATE_INITRD assignment should parse safely' \
    read_geninitrd_policy_boolean "$POLICY" AUTOGENERATE_INITRD
assert_equal true "$GENINITRD_POLICY_BOOLEAN_VALUE" 'the parsed policy boolean should be true'
sed -i 's/AUTOGENERATE_INITRD=true/AUTOGENERATE_INITRD=false/' "$POLICY"
assert_success 'a single false AUTOGENERATE_INITRD assignment should parse safely' \
    read_geninitrd_policy_boolean "$POLICY" AUTOGENERATE_INITRD
assert_equal false "$GENINITRD_POLICY_BOOLEAN_VALUE" 'the parsed policy boolean should be false'
printf 'AUTOGENERATE_INITRD=true\n' >> "$POLICY"
assert_failure 'duplicate AUTOGENERATE_INITRD assignments should fail closed' \
    read_geninitrd_policy_boolean "$POLICY" AUTOGENERATE_INITRD
cat > "$POLICY" <<'EOF_POLICY'
# AUTOGENERATE_INITRD=false
AUTOGENERATE_INITRD=true
AUTO_UPDATE_GRUB=true
EOF_POLICY
assert_success 'commented assignments should not affect the active policy value' \
    read_geninitrd_policy_boolean "$POLICY" AUTOGENERATE_INITRD

assert_success 'a coherent generated-initrd post state should validate' validate_generated_initrd_transition_state
assert_equal generated-initrd "$GENINITRD_POST_STATE" 'the post state should be classified as generated-initrd'
assert_equal 0 "$GENINITRD_POST_VALIDATION_STATUS" 'successful validation should expose status zero'
assert_equal "$TARGET_KERNEL" "$GENINITRD_POST_KERNEL_VERSION" 'the target version should come from the package snapshot'
assert_equal "$TARGET_KERNEL_PATH" "$GENINITRD_POST_KERNEL_PATH" 'the validated target kernel path should be preserved'
assert_equal "$TARGET_MODULES" "$GENINITRD_POST_MODULES_PATH" 'the validated module tree should be preserved'
assert_equal "$TARGET_INITRD" "$GENINITRD_POST_INITRD_PATH" 'the validated versioned initrd should be preserved'
assert_equal "$NAMED_INITRD_LINK" "$GENINITRD_POST_NAMED_LINK" 'the named initrd link should be preserved'
assert_equal 1 "$INITRD_OK" 'a validated GenInitrd result should satisfy the initrd prerequisite'

GRUB_REQUIRED=1
GRUB_UPDATE=1
GRUB_BLOCKED_BY_INITRD=0
assert_success 'an expected generated-initrd transition should satisfy the GRUB prerequisite' \
    grub_initrd_prerequisite_is_satisfied
assert_equal 0 "$GRUB_BLOCKED_BY_INITRD" 'the valid generated state should not block GRUB'
assert_success 'GRUB should accept the target kernel and versioned initrd' \
    validate_generated_direct_generic_grub_config "$GRUB_CONFIG"
sed -i "s|/boot/initrd-$TARGET_KERNEL.img|/boot/initrd-generic.img|" "$GRUB_CONFIG"
assert_success 'GRUB should also accept the validated named initrd link' \
    validate_generated_direct_generic_grub_config "$GRUB_CONFIG"
sed -i '/initrd /d' "$GRUB_CONFIG"
assert_failure 'GRUB must reject a generated-initrd transition without an initrd line' \
    validate_generated_direct_generic_grub_config "$GRUB_CONFIG"
cat > "$GRUB_CONFIG" <<EOF_GRUB
menuentry stale {
  linux /boot/vmlinuz-6.18.40 root=/dev/sda2 ro
  initrd /boot/initrd-$TARGET_KERNEL.img
}
EOF_GRUB
assert_failure 'GRUB must reject a stale kernel even when the initrd is current' \
    validate_generated_direct_generic_grub_config "$GRUB_CONFIG"

# Restore a valid GRUB fixture and exercise fail-closed post-state mutations.
cat > "$GRUB_CONFIG" <<EOF_GRUB
menuentry target {
  linux /boot/vmlinuz-$TARGET_KERNEL root=/dev/sda2 ro
  initrd /boot/initrd-$TARGET_KERNEL.img
}
EOF_GRUB
mv "$TARGET_INITRD" "$TARGET_INITRD.saved"
assert_failure 'a missing versioned initrd should fail closed' validate_generated_initrd_transition_state
mv "$TARGET_INITRD.saved" "$TARGET_INITRD"
: > "$TARGET_INITRD"
assert_failure 'an empty versioned initrd should fail closed' validate_generated_initrd_transition_state
printf 'initrd\n' > "$TARGET_INITRD"
chmod 622 "$TARGET_INITRD"
assert_failure 'a group-writable versioned initrd should fail closed' validate_generated_initrd_transition_state
chmod 600 "$TARGET_INITRD"
rm -f "$NAMED_INITRD_LINK"
ln -s initrd-6.18.40.img "$NAMED_INITRD_LINK"
assert_failure 'a stale named initrd link should fail closed' validate_generated_initrd_transition_state
ln -sfn "initrd-$TARGET_KERNEL.img" "$NAMED_INITRD_LINK"
printf 'legacy\n' > "$LEGACY_INITRD"
assert_failure 'an unexpected legacy initrd.gz should fail closed' validate_generated_initrd_transition_state
rm -f "$LEGACY_INITRD"
printf 'KERNEL_VERSION=%s\n' "$TARGET_KERNEL" > "$MKINITRD_CONFIG"
assert_failure 'an unexpected mkinitrd.conf should fail closed' validate_generated_initrd_transition_state
rm -f "$MKINITRD_CONFIG"
rm -rf "$TARGET_MODULES"
assert_failure 'a missing target module tree should fail closed' validate_generated_initrd_transition_state
mkdir -p "$TARGET_MODULES/kernel"
printf 'module\n' > "$TARGET_MODULES/kernel/test.ko"
cp "$PKGDB_REAL/$TARGET_RECORD" "$TMP/record.good"
printf 'boot/vmlinuz-%s\n' "$TARGET_KERNEL" > "$PKGDB_REAL/$TARGET_RECORD"
assert_failure 'a package record without target modules should fail closed' validate_generated_initrd_transition_state
cp "$TMP/record.good" "$PKGDB_REAL/$TARGET_RECORD"
printf '%s\n%s\n' "$TARGET_RECORD" "kernel-generic-6.18.40-x86_64-1" > "$AFTER_SNAPSHOT"
assert_failure 'multiple post-update generic package records should fail closed' validate_generated_initrd_transition_state
printf '%s\n' "$TARGET_RECORD" > "$AFTER_SNAPSHOT"
ln -sfn vmlinuz-6.18.40 "$GENERIC_LINK"
assert_failure 'a generic kernel link to another version should fail closed' validate_generated_initrd_transition_state
ln -sfn "vmlinuz-$TARGET_KERNEL" "$GENERIC_LINK"

# When autogeneration is not expected, the existing direct path remains valid.
rm -f "$TARGET_INITRD" "$NAMED_INITRD_LINK"
GENINITRD_TRANSITION_EXPECTED=0
DIRECT_GENERIC_INSTALLED_KERNEL_VERSION=$TARGET_KERNEL
GENINITRD_POST_STATE=not-generated
cat > "$GRUB_CONFIG" <<EOF_GRUB
menuentry target {
  linux /boot/vmlinuz-$TARGET_KERNEL root=/dev/sda2 ro
}
EOF_GRUB
assert_success 'direct GRUB remains valid when no generated transition is expected' \
    validate_generated_direct_generic_grub_config "$GRUB_CONFIG"

bash -n "$REFERENCE_SCRIPT" && pass || fail 'the reference script should pass bash -n'

printf 'Slackware-current GenInitrd post-state tests: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
