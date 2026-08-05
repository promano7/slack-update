#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-geninitrd-policy-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-geninitrd-policy-preflight.sh
source "$SCRIPT"

TEST_COUNT=0
FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }
json_value() { python3 -c 'import json,sys; value=json.load(open(sys.argv[1]));
for part in sys.argv[2].split("."): value=value[part]
print(str(value).lower() if isinstance(value,bool) else value)' "$1" "$2"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ROOT=$TMP/root
mkdir -p \
    "$ROOT/etc/default" \
    "$ROOT/etc/geninitrd.d/pre-install" \
    "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT/usr/sbin" \
    "$ROOT/usr/share/mkinitrd" \
    "$ROOT/var/lib/pkgtools/setup" \
    "$ROOT/sbin" \
    "$ROOT/usr/bin" \
    "$ROOT/boot/grub"

cat > "$ROOT/usr/sbin/geninitrd" <<'EOF_GENINITRD'
#!/bin/bash
if [ -r etc/default/geninitrd ]; then
  . etc/default/geninitrd
fi
for script in etc/geninitrd.d/pre-install/* ; do
  [ -x "$script" ] && chroot . "$script"
done
if [ ! -z "$GENINITRD_OVERRIDE_SCRIPT" ]; then
  RELATIVE_OVERRIDE_SCRIPT=$GENINITRD_OVERRIDE_SCRIPT
fi
if [ -x "$RELATIVE_OVERRIDE_SCRIPT" ]; then
  chroot . "$GENINITRD_OVERRIDE_SCRIPT"
else
  chroot . /var/lib/pkgtools/setup/setup.01.mkinitrd
fi
for script in etc/geninitrd.d/post-install/* ; do
  [ -x "$script" ] && chroot . "$script"
done
EOF_GENINITRD
chmod 0755 "$ROOT/usr/sbin/geninitrd"

cat > "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" <<'EOF_SETUP'
#!/bin/bash
AUTOGENERATE_INITRD=${AUTOGENERATE_INITRD:-true}
AUTO_UPDATE_GRUB=${AUTO_UPDATE_GRUB:-true}
if [ "$KERNEL_DOINST" = "true" -a "$AUTOGENERATE_INITRD" = "false" ]; then
  exit 0
fi
if [ "$GENERATOR" = "mkinitrd" -a ! -r etc/mkinitrd.conf ]; then
  GENERATOR=mkinitrd_command_generator.sh
fi
chroot . /usr/share/mkinitrd/mkinitrd_command_generator.sh -k "$KERNEL_VERSION" -a "-o /boot/initrd-${KERNEL_VERSION}.img" | chroot . bash
if [ "$AUTO_UPDATE_GRUB" = "true" ]; then
  chroot . /usr/sbin/update-grub
fi
EOF_SETUP
chmod 0755 "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd"
printf '#!/bin/sh\nexit 0\n' > "$ROOT/usr/share/mkinitrd/mkinitrd_command_generator.sh"
printf '#!/bin/sh\nexit 0\n' > "$ROOT/sbin/mkinitrd"
printf '#!/bin/sh\nexit 0\n' > "$ROOT/usr/bin/dracut"
chmod 0755 "$ROOT/usr/share/mkinitrd/mkinitrd_command_generator.sh" "$ROOT/sbin/mkinitrd" "$ROOT/usr/bin/dracut"

CONFIG=$ROOT/etc/default/geninitrd
OUT=$TMP/policy.json
cat > "$CONFIG" <<'EOF_CONFIG'
KERNEL=/boot/vmlinuz-generic
GENINITRD_NAMED_SYMLINK=true
GENINITRD_INITRD_GZ_SYMLINK=false
GENERATOR=mkinitrd
AUTOGENERATE_INITRD=true
AUTO_REMOVE_ORPHANED_INITRDS=true
AUTO_REMOVE_INITRD_TREE=true
AUTO_UPDATE_GRUB=true
GENINITRD_DIALOG=false
GENINITRD_COMMAND_OUTPUT=true
EOF_CONFIG

assert_success 'the acceptance script should have valid Bash syntax' bash -n "$SCRIPT"
assert_contains 'apply-ready=false' "$SCRIPT" 'apply readiness must remain false'
assert_contains 'apply-authorized=false' "$SCRIPT" 'apply authorization must remain false'
assert_not_contains 'usr/sbin/geninitrd"' "$SCRIPT" 'the acceptance script must not execute the installed geninitrd program'
if grep -Eq '^[[:space:]]*(slackpkg|installpkg|upgradepkg|removepkg|update-grub|grub-mkconfig)[[:space:]]' "$SCRIPT"; then
    fail 'the preflight must not invoke package or boot mutation commands'
else
    pass
fi
assert_contains 'sha256sum -c' "$SCRIPT" 'portable evidence verification should be printed'
assert_contains 'without sourcing it' "$SCRIPT" 'configuration must be parsed without shell evaluation'
assert_contains 'validate_live_geninitrd_baseline' "$SCRIPT" 'the corrected live GenInitrd baseline must gate policy inspection'
assert_contains 'versioned-to-versioned-initrd' "$SCRIPT" 'the policy model must describe the corrected versioned-initrd transition'
assert_not_contains 'DEFAULT_BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260804-accepted.json"' "$SCRIPT" 'the revoked boot fixture must not be the default'
assert_not_contains 'recognized-direct-generic-transition-with-conditional-geninitrd' "$SCRIPT" 'the rebuilt policy preflight must not accept the revoked package classification'

is_safe_kernel_version 6.18.42 && pass || fail 'a normal kernel version should be safe'
is_safe_kernel_version '../6.18.42' && fail 'parent traversal should be rejected' || pass
is_sha256 "$(printf 'a%.0s' {1..64})" && pass || fail 'a valid SHA-256 should be accepted'
is_sha256 abc && fail 'a short SHA-256 should be rejected' || pass

NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
CHAIN_RESTART="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
CONFIRM_CANDIDATES_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
TARGET_KERNEL=6.18.42
assert_success 'the four accepted records should match the policy transaction' validate_accepted_records
cp "$PACKAGE_PREFLIGHT" "$TMP/package-mismatch.json"
sed -i 's/6.18.42/6.18.43/' "$TMP/package-mismatch.json"
PACKAGE_PREFLIGHT=$TMP/package-mismatch.json
assert_failure 'a mismatched package record should fail closed' validate_accepted_records
PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
cp "$CHAIN_RESTART" "$TMP/chain-mismatch.json"
sed -i 's/6.18.42/6.18.43/' "$TMP/chain-mismatch.json"
CHAIN_RESTART=$TMP/chain-mismatch.json
assert_failure 'a mismatched restarted-chain record should fail closed' validate_accepted_records
CHAIN_RESTART="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
cp "$BOOT_PREFLIGHT" "$TMP/boot-mode-mismatch.json"
sed -i 's/geninitrd-managed-versioned-initrd/direct-generic-no-initrd/' "$TMP/boot-mode-mismatch.json"
BOOT_PREFLIGHT=$TMP/boot-mode-mismatch.json
assert_failure 'the revoked direct-generic baseline should fail closed' validate_accepted_records
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
cp "$PACKAGE_PREFLIGHT" "$TMP/package-initrd-mismatch.json"
sed -i 's/0da0e0289d93cdf2d3b78288bfa23db4c9437b576563f92889399b2c98294442/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/' "$TMP/package-initrd-mismatch.json"
PACKAGE_PREFLIGHT=$TMP/package-initrd-mismatch.json
assert_failure 'a package record bound to another current initrd should fail closed' validate_accepted_records
PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"

printf 'kernel baseline\n' > "$ROOT/boot/vmlinuz-6.18.40"
ln -s vmlinuz-6.18.40 "$ROOT/boot/vmlinuz-generic"
printf 'versioned initrd baseline\n' > "$ROOT/boot/initrd-6.18.40.img"
ln -s initrd-6.18.40.img "$ROOT/boot/initrd-generic.img"
cat > "$ROOT/boot/grub/grub.cfg" <<'EOF_GRUB'
menuentry 'Slackware generic' {
  linux /boot/vmlinuz-generic root=/dev/sda2 ro
  initrd /boot/intel-ucode.img /boot/initrd-generic.img
}
EOF_GRUB
chmod 0644 "$ROOT/boot/vmlinuz-6.18.40" "$ROOT/boot/initrd-6.18.40.img" "$ROOT/boot/grub/grub.cfg"
SYNTHETIC_BOOT=$TMP/synthetic-boot.json
python3 - "$BOOT_PREFLIGHT" "$ROOT" "$SYNTHETIC_BOOT" <<'PY_BASELINE'
import hashlib, json, pathlib, sys
source, root_text, output = sys.argv[1:]
root = pathlib.Path(root_text)
data = json.load(open(source, encoding='utf-8'))
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
data['generic_kernel_sha256'] = digest(root / 'boot/vmlinuz-6.18.40')
data['versioned_initrd_sha256'] = digest(root / 'boot/initrd-6.18.40.img')
data['versioned_initrd_size'] = (root / 'boot/initrd-6.18.40.img').stat().st_size
data['active_grub_sha256'] = digest(root / 'boot/grub/grub.cfg')
pathlib.Path(output).write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
PY_BASELINE
grub-script-check() { return 0; }
assert_success 'the corrected synthetic GenInitrd baseline should validate' validate_live_geninitrd_baseline "$SYNTHETIC_BOOT" "$ROOT" "$TMP/live-baseline.txt"
assert_contains 'boot_mode=geninitrd-managed-versioned-initrd' "$TMP/live-baseline.txt" 'the live baseline should preserve the corrected mode'
assert_contains 'named_initrd_target=initrd-6.18.40.img' "$TMP/live-baseline.txt" 'the live baseline should preserve the exact named link target'
assert_contains 'versioned_initrd_sha256=' "$TMP/live-baseline.txt" 'the live baseline should record the versioned initrd hash'
printf 'changed initrd\n' > "$ROOT/boot/initrd-6.18.40.img"
assert_failure 'a changed current versioned initrd should fail closed' validate_live_geninitrd_baseline "$SYNTHETIC_BOOT" "$ROOT" "$TMP/live-baseline.txt"
printf 'versioned initrd baseline\n' > "$ROOT/boot/initrd-6.18.40.img"
sed -i 's/GENINITRD_NAMED_SYMLINK=true/GENINITRD_NAMED_SYMLINK=false/' "$CONFIG"
assert_failure 'a changed named-link policy should fail closed' validate_live_geninitrd_baseline "$SYNTHETIC_BOOT" "$ROOT" "$TMP/live-baseline.txt"
sed -i 's/GENINITRD_NAMED_SYMLINK=false/GENINITRD_NAMED_SYMLINK=true/' "$CONFIG"

assert_failure 'the revoked direct boot mode should not be analyzed' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" direct-generic-no-initrd 6.18.42 "$OUT"

assert_success 'default enabled policy should be analyzed safely'  analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
assert_equal enabled "$(json_value "$OUT" policy_state)" 'autogeneration should be enabled'
assert_equal mkinitrd_command_generator.sh "$(json_value "$OUT" effective_generator)" 'missing mkinitrd.conf should select the command generator'
assert_equal versioned-to-versioned-initrd "$(json_value "$OUT" transition_mode)" 'enabled policy should replace the current versioned initrd safely'
assert_equal true "$(json_value "$OUT" auto_update_grub)" 'automatic GRUB update should be explicit'
assert_equal /boot/initrd-6.18.42.img "$(json_value "$OUT" expected_initrd)" 'the versioned initrd path should be predicted'
assert_equal false "$(json_value "$OUT" custom_review_required)" 'an empty hook layout should not require custom review'
assert_equal false "$(json_value "$OUT" apply_ready)" 'policy discovery must remain non-ready'

sed -i 's/AUTOGENERATE_INITRD=true/AUTOGENERATE_INITRD=false/' "$CONFIG"
assert_success 'disabled autogeneration should be recognized' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
assert_equal disabled-by-policy "$(json_value "$OUT" policy_state)" 'disabled policy should be explicit'
assert_equal versioned-initrd-stale-after-kernel-transition "$(json_value "$OUT" transition_mode)" 'disabled policy should expose the stale-initrd risk'
assert_equal disabled "$(json_value "$OUT" effective_generator)" 'disabled policy should not select a generator'
sed -i 's/AUTOGENERATE_INITRD=false/AUTOGENERATE_INITRD=true/' "$CONFIG"

printf 'AUTOGENERATE_INITRD=maybe\n' > "$CONFIG"
assert_failure 'invalid booleans should fail closed' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
printf 'AUTOGENERATE_INITRD=$(touch /tmp/unsafe)\n' > "$CONFIG"
assert_failure 'command substitution in configuration should fail closed' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
printf 'UNKNOWN_ACTIVE_OPTION=true\n' > "$CONFIG"
assert_failure 'unknown active configuration should fail closed' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
rm "$CONFIG"
assert_success 'a missing config should use reviewed setup defaults' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
assert_equal missing-defaults "$(json_value "$OUT" config_state)" 'missing config state should be explicit'
assert_equal true "$(json_value "$OUT" autogenerate_initrd)" 'setup defaults should enable autogeneration'

cat > "$CONFIG" <<'EOF_CONFIG'
GENERATOR=dracut
AUTOGENERATE_INITRD=true
AUTO_UPDATE_GRUB=false
EOF_CONFIG
assert_success 'a supported dracut policy should be recognized' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
assert_equal dracut "$(json_value "$OUT" effective_generator)" 'dracut should remain the effective generator'
assert_equal false "$(json_value "$OUT" auto_update_grub)" 'disabled automatic GRUB update should be preserved'

printf '#!/bin/sh\nexit 0\n' > "$ROOT/etc/geninitrd.d/pre-install/custom-hook"
chmod 0755 "$ROOT/etc/geninitrd.d/pre-install/custom-hook"
assert_success 'an executable regular custom hook should be inventoried' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
assert_equal true "$(json_value "$OUT" custom_review_required)" 'custom hooks should require review'
rm "$ROOT/etc/geninitrd.d/pre-install/custom-hook"
ln -s /bin/true "$ROOT/etc/geninitrd.d/pre-install/unsafe-hook"
assert_failure 'symlinked hooks should fail closed' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
rm "$ROOT/etc/geninitrd.d/pre-install/unsafe-hook"

cp "$ROOT/usr/sbin/geninitrd" "$TMP/geninitrd.bad"
sed -i '/GENINITRD_OVERRIDE_SCRIPT/d' "$TMP/geninitrd.bad"
chmod 0755 "$TMP/geninitrd.bad"
assert_failure 'an unrecognized installed geninitrd control flow should fail closed' analyze_geninitrd_policy \
    "$CONFIG" "$TMP/geninitrd.bad" "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
cp "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" "$TMP/setup.bad"
sed -i '/AUTO_UPDATE_GRUB/d' "$TMP/setup.bad"
chmod 0755 "$TMP/setup.bad"
assert_failure 'an unrecognized setup control flow should fail closed' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$TMP/setup.bad" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"

cp "$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd" "$TMP/setup.legacy"
printf '# legacy vmlinuz-generic-smp marker\n' >> "$TMP/setup.legacy"
chmod 0755 "$TMP/setup.legacy"
assert_success 'a legacy setup marker should be modeled as a doinst skip' analyze_geninitrd_policy \
    "$CONFIG" "$ROOT/usr/sbin/geninitrd" "$TMP/setup.legacy" \
    "$ROOT/etc/mkinitrd.conf" "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" \
    "$ROOT" geninitrd-managed-versioned-initrd 6.18.42 "$OUT"
assert_equal false "$(json_value "$OUT" doinst_will_invoke_geninitrd)" 'legacy setup should suppress the doinst hook'
assert_equal legacy-setup-skip "$(json_value "$OUT" policy_state)" 'legacy skip state should be explicit'

HOOKS=$TMP/hooks.txt
assert_success 'empty hook directories should inventory safely' inventory_hooks "$ROOT/etc/geninitrd.d/pre-install" "$ROOT/etc/geninitrd.d/post-install" "$HOOKS"
assert_contains "$ROOT/etc/geninitrd.d/pre-install" "$HOOKS" 'the pre-install directory should be represented'

assert_contains 'conditional_geninitrd_hook' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json" 'accepted package evidence should record the hook'
assert_contains 'recognized-generic-kernel-transition-with-conditional-geninitrd' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json" 'accepted package evidence should record the corrected generic transition'
assert_contains 'host_policy_preflight_required' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json" 'accepted package evidence should require this stage'

printf 'Slackware-current geninitrd policy preflight harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
