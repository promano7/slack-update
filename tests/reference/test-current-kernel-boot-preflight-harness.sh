#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-boot-preflight.sh"
ACCEPTED_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
DIAGNOSTIC_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-diagnostic.json"
ACCEPTED_BOOT_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-accepted.json"
RESTART_DIAGNOSTIC_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260804-diagnostic.json"
READINESS_DIAGNOSTIC_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-transaction-readiness-20260805-diagnostic.json"

# Source functions without running the real-system scenario.
# shellcheck source=../acceptance/reference/test-current-kernel-boot-preflight.sh
source "$ACCEPTANCE_SCRIPT"

TEST_COUNT=0
TEST_FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
DIGEST=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9

assert_contains 'never installs packages, runs mkinitrd' "$ACCEPTANCE_SCRIPT" 'usage should state the non-destructive boundary'
assert_contains 'apply-ready=false, apply-authorized=false' "$ACCEPTANCE_SCRIPT" 'the result must deny apply'
assert_contains 'monolithic kernel-generic' "$ACCEPTANCE_SCRIPT" 'the current package model should be explicit'
assert_contains 'direct-generic-no-initrd' "$ACCEPTANCE_SCRIPT" 'direct generic boot without initrd should remain an explicit mode'
assert_contains 'geninitrd-managed-versioned-initrd' "$ACCEPTANCE_SCRIPT" 'GenInitrd-managed versioned initrd boot should be an explicit mode'
assert_contains '/boot/initrd-generic.img' "$ACCEPTANCE_SCRIPT" 'the named GenInitrd symlink should be inspected'
assert_contains 'validate_grub_kernel_initrd_pair' "$ACCEPTANCE_SCRIPT" 'GRUB should pair the running kernel with the named initrd'
assert_contains 'BOOT_IMAGE' "$ACCEPTANCE_SCRIPT" 'the running boot image should be validated'
assert_contains 'grub-script-check /boot/grub/grub.cfg' "$ACCEPTANCE_SCRIPT" 'the active GRUB configuration should be syntax checked'
assert_contains 'repository_target_owns_path "boot/vmlinuz-$TARGET_KERNEL"' "$ACCEPTANCE_SCRIPT" 'available target image inventory should still be consumed'
assert_contains 'deferred-to-exact-package-preflight' "$ACCEPTANCE_SCRIPT" 'missing target file inventory should defer to the exact package stage'
assert_contains 'target_image_metadata_state=$TARGET_IMAGE_METADATA_STATE' "$ACCEPTANCE_SCRIPT" 'the evidence summary should expose the metadata decision'
assert_contains 'target versioned generic kernel image ownership is deferred to the exact package preflight' "$ACCEPTANCE_SCRIPT" 'the deferred ownership boundary should be explicit'
assert_contains 'package_record_owns_path "$record" "boot/$basename"' "$ACCEPTANCE_SCRIPT" 'the running kernel image should be owned by the installed package'
assert_not_contains "if [ -s /boot/initrd.gz ]; then record_pass" "$ACCEPTANCE_SCRIPT" 'initrd absence must not be rejected unconditionally'
assert_contains '/home/$owner' "$ACCEPTANCE_SCRIPT" 'evidence must be copied directly to the user home'
assert_contains 'sha256sum -c' "$ACCEPTANCE_SCRIPT" 'the destination verification command should be printed'
assert_contains '(cd "$parent" && sha256sum "${archive##*/}")' "$ACCEPTANCE_SCRIPT" 'sidecars should contain only the archive basename'
assert_contains 'hashlib.sha256()' "$ACCEPTANCE_SCRIPT" 'package immutability should cover package-record contents'
assert_contains 'the package database and boot state were captured before inspection' "$ACCEPTANCE_SCRIPT" 'the initial state must be captured before inspection'
assert_contains 'a complete capture pair is unavailable' "$ACCEPTANCE_SCRIPT" 'missing captures must block unchanged-state assertions'
assert_not_contains 'slackpkg upgrade-all' "$ACCEPTANCE_SCRIPT" 'preflight must not upgrade packages'
assert_not_contains 'mkinitrd -F' "$ACCEPTANCE_SCRIPT" 'preflight must not regenerate initrd'
assert_not_contains 'grub-mkconfig -o' "$ACCEPTANCE_SCRIPT" 'preflight must not regenerate GRUB'
assert_not_contains 'upgradepkg ' "$ACCEPTANCE_SCRIPT" 'preflight must not invoke upgradepkg'
assert_not_contains 'installpkg ' "$ACCEPTANCE_SCRIPT" 'preflight must not invoke installpkg'
assert_not_contains 'removepkg ' "$ACCEPTANCE_SCRIPT" 'preflight must not invoke removepkg'

TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_success 'valid current preflight arguments should parse' parse_arguments --target slackware-current --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel 6.18.42
assert_equal slackware-current "$TARGET" 'target should be preserved'
assert_equal 6.18.42 "$TARGET_KERNEL" 'target kernel should be preserved'
assert_equal "$DIGEST" "$CONFIRM_CANDIDATES_SHA256" 'candidate digest should be preserved'

TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'Slackware 15.0 should be rejected' parse_arguments --target slackware-15.0 --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel 6.18.42
TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'short candidate digests should be rejected' parse_arguments --target slackware-current --confirm-candidates-sha256 deadbeef --confirm-target-kernel 6.18.42
TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'unsafe target kernel versions should be rejected' parse_arguments --target slackware-current --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel ../6.18.42
TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'relative output paths should be rejected' parse_arguments --target slackware-current --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel 6.18.42 --output-dir relative

assert_success 'the accepted fixture should match the reviewed identity' validate_accepted_preflight
assert_equal 6.18.40 "$(package_record_version kernel-generic-6.18.40-x86_64-1)" 'kernel package version should be parsed'
assert_success 'safe kernel versions should pass' is_safe_kernel_version 6.18.42
assert_failure 'kernel versions with whitespace should fail' is_safe_kernel_version '6.18.42 bad'
assert_failure 'kernel versions with slash should fail' is_safe_kernel_version '6.18/41'
assert_success 'the reviewed fixture should be valid JSON' python3 -m json.tool "$ACCEPTED_FIXTURE"
assert_success 'the direct-generic diagnostic fixture should be valid JSON' python3 -m json.tool "$DIAGNOSTIC_FIXTURE"
assert_contains '"classification": "direct-generic-no-initrd"' "$DIAGNOSTIC_FIXTURE" 'the diagnostic should preserve the observed boot mode'
assert_contains '"apply_authorized": false' "$DIAGNOSTIC_FIXTURE" 'the diagnostic must deny apply'
assert_success 'the corrected direct-generic fixture should be valid JSON' python3 -m json.tool "$ACCEPTED_BOOT_FIXTURE"
assert_contains '"accepted": true' "$ACCEPTED_BOOT_FIXTURE" 'the corrected real-system run should be accepted'
assert_contains '"archive_sha256": "ed7462e70496cf38a52c211f3d5945438e5f1bad5b8d8eaa7b90079540381967"' "$ACCEPTED_BOOT_FIXTURE" 'the accepted archive digest should be preserved'
assert_contains '"assertions": {' "$ACCEPTED_BOOT_FIXTURE" 'the accepted assertion summary should be preserved'
assert_contains '"apply_ready": false' "$ACCEPTED_BOOT_FIXTURE" 'the accepted discovery must remain non-ready'
assert_success 'the rejected chain-restart diagnostic fixture should be valid JSON' python3 -m json.tool "$RESTART_DIAGNOSTIC_FIXTURE"
assert_contains '"archive_sha256": "ea7b0d7fa6ff5f9020f41ae06f5bea5c91a79d579dddf1bc25d258ca484605d1"' "$RESTART_DIAGNOSTIC_FIXTURE" 'the rejected outer archive digest should be preserved'
assert_contains '"repository_target_image_inventory_present": false' "$RESTART_DIAGNOSTIC_FIXTURE" 'the missing local file inventory should be preserved'
assert_contains '"apply_authorized": false' "$RESTART_DIAGNOSTIC_FIXTURE" 'the rejected restart must remain unauthorized'
assert_success 'the readiness baseline diagnostic fixture should be valid JSON' python3 -m json.tool "$READINESS_DIAGNOSTIC_FIXTURE"
assert_contains '"classification": "geninitrd-managed-versioned-initrd"' "$READINESS_DIAGNOSTIC_FIXTURE" 'the diagnostic should preserve the corrected boot classification'
assert_contains '"prior_boot_mode_revoked": "direct-generic-no-initrd"' "$READINESS_DIAGNOSTIC_FIXTURE" 'the previous classification should be explicitly revoked'
assert_contains '"apply_ready": false' "$READINESS_DIAGNOSTIC_FIXTURE" 'the diagnostic must keep apply blocked'

assert_success 'vmlinuz-VERSION should be a supported running image' is_supported_running_kernel_image vmlinuz-6.18.40 6.18.40
assert_success 'vmlinuz-generic-VERSION should remain supported for managed layouts' is_supported_running_kernel_image vmlinuz-generic-6.18.40 6.18.40
assert_failure 'an unversioned image should not prove the running kernel' is_supported_running_kernel_image vmlinuz-generic 6.18.40
assert_failure 'a different versioned image should be rejected' is_supported_running_kernel_image vmlinuz-6.18.42 6.18.40
assert_equal direct-generic-no-initrd "$(classify_boot_mode_from_states absent absent absent absent vmlinuz-6.18.40 6.18.40)" 'matching absent initrd artifacts should classify as direct boot'
assert_equal geninitrd-managed-versioned-initrd "$(classify_boot_mode_from_states absent absent present present vmlinuz-6.18.40 6.18.40)" 'named and versioned initrd artifacts should classify as GenInitrd-managed boot'
assert_equal mkinitrd-managed "$(classify_boot_mode_from_states present present absent absent vmlinuz-6.18.40 6.18.40)" 'legacy initrd.gz with mkinitrd.conf should classify as mkinitrd-managed boot'
assert_equal mkinitrd-managed "$(classify_boot_mode_from_states present present absent absent vmlinuz-generic-6.18.40 6.18.40)" 'legacy versioned generic naming should remain valid with mkinitrd'
assert_failure 'a named initrd without its versioned target should be inconsistent' classify_boot_mode_from_states absent absent present absent vmlinuz-6.18.40 6.18.40
assert_failure 'a versioned initrd without its named link should be inconsistent' classify_boot_mode_from_states absent absent absent present vmlinuz-6.18.40 6.18.40
assert_failure 'mkinitrd.conf with a missing legacy initrd should be inconsistent' classify_boot_mode_from_states present absent absent absent vmlinuz-6.18.40 6.18.40
assert_failure 'initrd-less legacy generic naming should be rejected' classify_boot_mode_from_states absent absent absent absent vmlinuz-generic-6.18.40 6.18.40

GRUB_CFG="$TMP/grub.cfg"
cat > "$GRUB_CFG" <<'EOF_GRUB'
menuentry 'Slackware generic' {
    linux /boot/vmlinuz-generic root=/dev/sda2 ro
    initrd /boot/intel-ucode.img /boot/initrd-generic.img
}
EOF_GRUB
assert_success 'a GRUB menuentry pairing the generic kernel and named initrd should pass' validate_grub_kernel_initrd_pair "$GRUB_CFG" /boot/vmlinuz-generic /boot/initrd-generic.img
sed -i '/initrd /d' "$GRUB_CFG"
assert_failure 'a GRUB menuentry without the named initrd should fail' validate_grub_kernel_initrd_pair "$GRUB_CFG" /boot/vmlinuz-generic /boot/initrd-generic.img

PACKAGE_DATABASE_RESOLVED="$TMP/packages"
mkdir -p "$PACKAGE_DATABASE_RESOLVED"
printf 'boot/vmlinuz-6.18.40\nlib/modules/6.18.40/kernel/test.ko\n' > "$PACKAGE_DATABASE_RESOLVED/kernel-generic-6.18.40-x86_64-1"
assert_success 'exact package-owned kernel paths should pass' package_record_owns_path kernel-generic-6.18.40-x86_64-1 boot/vmlinuz-6.18.40
assert_failure 'prefix-only package paths should not pass' package_record_owns_path kernel-generic-6.18.40-x86_64-1 boot/vmlinuz-6.18
assert_failure 'missing package records should fail ownership checks' package_record_owns_path kernel-generic-missing boot/vmlinuz-6.18.40
TARGET_KERNEL=6.18.42
repository_target_owns_path() { return 0; }
assert_equal present "$(classify_target_image_metadata_state)" 'available target file inventory should be classified as present'
repository_target_owns_path() { return 1; }
assert_equal deferred-to-exact-package-preflight "$(classify_target_image_metadata_state)" 'missing target file inventory should defer to the exact package preflight'

cp "$ACCEPTED_FIXTURE" "$TMP/fixture.json"
python3 - "$TMP/fixture.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['apply_authorized']=True
open(p,'w').write(json.dumps(d))
PY
ACCEPTED_PREFLIGHT="$TMP/fixture.json"
assert_failure 'an apply-authorized fixture should be rejected' validate_accepted_preflight
ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE

CONF="$TMP/mkinitrd.conf"
cat > "$CONF" <<'EOF_CONF'
KERNEL_VERSION="6.18.40"
ROOTDEV='/dev/sda2'
OUTPUT_IMAGE=/boot/initrd.gz
EOF_CONF
assert_equal 6.18.40 "$(read_scalar_assignment "$CONF" KERNEL_VERSION)" 'quoted KERNEL_VERSION should parse'
assert_equal /dev/sda2 "$(read_scalar_assignment "$CONF" ROOTDEV)" 'single-quoted ROOTDEV should parse'
assert_equal /boot/initrd.gz "$(read_scalar_assignment "$CONF" OUTPUT_IMAGE)" 'plain output path should parse'
printf 'KERNEL_VERSION=one\nKERNEL_VERSION=two\n' > "$CONF"
assert_failure 'duplicate mkinitrd assignments should fail' read_scalar_assignment "$CONF" KERNEL_VERSION

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'acceptance script should pass bash -n'

printf 'Slackware-current kernel boot preflight harness: %d checks, %d failures\n' "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
