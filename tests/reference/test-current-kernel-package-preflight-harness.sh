#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-package-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-kernel-package-preflight.sh
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

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
PKGROOT=$TMP/pkgroot
CACHE=$TMP/cache
mkdir -p "$PKGROOT/boot" "$PKGROOT/install" "$PKGROOT/lib/modules/6.18.42/kernel/drivers/test" "$CACHE/a"
printf 'kernel\n' > "$PKGROOT/boot/vmlinuz-6.18.42"
printf 'module\n' > "$PKGROOT/lib/modules/6.18.42/kernel/drivers/test/test.ko"
cat > "$PKGROOT/install/doinst.sh" <<'EOF_DOINST'
#!/bin/sh
if [ -r boot/vmlinuz-6.18.42 ]; then
  ( cd boot ; rm -rf vmlinuz-generic )
  ( cd boot ; ln -sf vmlinuz-6.18.42 vmlinuz-generic )
fi
if [ -r var/lib/pkgtools/setup/setup.01.mkinitrd ]; then
  if ! grep -wq vmlinuz-generic-smp var/lib/pkgtools/setup/setup.01.mkinitrd 2> /dev/null ; then
    if [ -z "$INSIDE_INSTALLER" ]; then
      if [ -x usr/sbin/geninitrd ]; then
        usr/sbin/geninitrd
      fi
    fi
  fi
fi
EOF_DOINST
PACKAGE=$CACHE/a/kernel-generic-6.18.42-x86_64-1.txz
( cd "$PKGROOT" && tar -cJf "$PACKAGE" . )

assert_success 'the acceptance script should have valid Bash syntax' bash -n "$SCRIPT"
assert_contains 'download kernel-generic' "$SCRIPT" 'the preflight should download one exact package name'
if grep -Eq '^[[:space:]]*(installpkg|upgradepkg|removepkg)[[:space:]]' "$SCRIPT"; then
    fail 'the preflight must not invoke package mutation commands'
else
    pass
fi
assert_not_contains 'sh "$doinst_file"' "$SCRIPT" 'the package script must never be executed'
assert_contains 'APPLY_READY=false' "$SCRIPT" 'apply readiness must remain false'
assert_contains 'APPLY_AUTHORIZED=false' "$SCRIPT" 'apply authorization must remain false'
assert_contains 'grub-mkconfig -o "$output"' "$SCRIPT" 'GRUB discovery must write only to the supplied evidence path'
assert_contains 'live Slackpkg metadata still exposes exactly the reviewed kernel-generic package' "$SCRIPT" 'live metadata must gate the download'
assert_contains 'return 1' "$SCRIPT" 'precondition failures must stop before download'
assert_contains 'sha256sum -c' "$SCRIPT" 'portable evidence verification should be printed'

is_safe_kernel_version 6.18.42 && pass || fail 'a normal kernel version should be safe'
is_safe_kernel_version '../6.18.42' && fail 'parent traversal should be rejected' || pass
is_sha256 "$(printf 'a%.0s' {1..64})" && pass || fail 'a valid SHA-256 should be accepted'
is_sha256 abc && fail 'a short SHA-256 should be rejected' || pass

NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260804-accepted.json"
CONFIRM_CANDIDATES_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
TARGET_KERNEL=6.18.42
CHAIN_RESTART="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260804-accepted.json"
assert_success 'the accepted candidate, boot, and restarted-chain records should match the exact transaction' validate_accepted_records
cp "$BOOT_PREFLIGHT" "$TMP/boot-mismatch.json"
sed -i 's/6.18.42/6.18.43/' "$TMP/boot-mismatch.json"
BOOT_PREFLIGHT="$TMP/boot-mismatch.json"
assert_failure 'a mismatched boot record should fail closed' validate_accepted_records
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260804-accepted.json"
cp "$CHAIN_RESTART" "$TMP/chain-mismatch.json"
sed -i 's/6.18.42/6.18.43/g' "$TMP/chain-mismatch.json"
CHAIN_RESTART="$TMP/chain-mismatch.json"
assert_failure 'a mismatched restarted-chain record should fail closed' validate_accepted_records
CHAIN_RESTART="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260804-accepted.json"

OUT=$TMP/out
mkdir "$OUT"
PKGLIST="$TMP/pkglist"
printf 'slackware64 kernel-generic 6.18.42 x86_64 1 kernel-generic-6.18.42-x86_64-1 ./slackware64/a
' > "$PKGLIST"
assert_success 'one exact live repository record should validate' validate_live_repository_target "$PKGLIST" 6.18.42 "$OUT/live-record"
printf 'slackware64 kernel-generic 6.18.42 x86_64 1 kernel-generic-6.18.42-x86_64-1 ./slackware64/a
' >> "$PKGLIST"
assert_failure 'duplicate live repository records should fail closed' validate_live_repository_target "$PKGLIST" 6.18.42 "$OUT/live-record"
printf 'slackware64 kernel-generic 6.18.43 x86_64 1 kernel-generic-6.18.43-x86_64-1 ./slackware64/a\n' > "$PKGLIST"
assert_failure 'a changed live target should fail closed' validate_live_repository_target "$PKGLIST" 6.18.42 "$OUT/live-record"

assert_success 'one exact cached package should resolve' resolve_exact_cached_package "$CACHE" 6.18.42 "$OUT/cached.txt"
assert_equal "$PACKAGE" "$(cat "$OUT/cached.txt")" 'the exact cached package path should be emitted'
cp "$PACKAGE" "$CACHE/kernel-generic-6.18.42-x86_64-1.txz"
assert_failure 'duplicate exact cached packages should fail closed' resolve_exact_cached_package "$CACHE" 6.18.42 "$OUT/duplicate.txt"
rm "$CACHE/kernel-generic-6.18.42-x86_64-1.txz"

assert_success 'a safe synthetic package should inspect' inspect_package_archive "$PACKAGE" 6.18.42 "$OUT/members" "$OUT/doinst" "$OUT/package-summary"
assert_contains 'boot/vmlinuz-6.18.42' "$OUT/members" 'the versioned kernel should be inventoried'
assert_contains 'lib/modules/6.18.42/kernel/drivers/test/test.ko' "$OUT/members" 'target modules should be inventoried'
assert_contains 'initrd_members=0' "$OUT/package-summary" 'the package should not contain an initrd'
assert_contains 'sha256=' "$OUT/package-summary" 'the package hash should be recorded'
assert_success 'the recognized doinst policy should validate' validate_doinst_policy "$OUT/doinst" 6.18.42 "$OUT/doinst-policy"
assert_contains 'policy=recognized-direct-generic-transition-with-conditional-geninitrd' "$OUT/doinst-policy" 'the direct transition and conditional hook should be explicit'
assert_contains 'postinstall_hook=conditional-geninitrd' "$OUT/doinst-policy" 'the conditional geninitrd hook should be recorded'
assert_contains 'host_policy_preflight_required=true' "$OUT/doinst-policy" 'host policy review should be mandatory'
assert_contains 'executed=false' "$OUT/doinst-policy" 'the package script should be recorded as unexecuted'

BADROOT=$TMP/badroot
cp -a "$PKGROOT" "$BADROOT"
rm -rf "$BADROOT/lib/modules/6.18.42"
BADPKG=$TMP/kernel-generic-6.18.42-x86_64-1.txz
( cd "$BADROOT" && tar -cJf "$BADPKG" . )
assert_failure 'a package without modules should fail closed' inspect_package_archive "$BADPKG" 6.18.42 "$OUT/bad-members" "$OUT/bad-doinst" "$OUT/bad-summary"

cp -a "$PKGROOT" "$BADROOT.modules"
mkdir -p "$BADROOT.modules/lib/modules/6.18.40/kernel"
printf x > "$BADROOT.modules/lib/modules/6.18.40/kernel/foreign.ko"
( cd "$BADROOT.modules" && tar -cJf "$BADPKG" . )
assert_failure 'foreign module versions should fail closed' inspect_package_archive "$BADPKG" 6.18.42 "$OUT/bad-members" "$OUT/bad-doinst" "$OUT/bad-summary"

cp -a "$PKGROOT" "$BADROOT.initrd"
printf initrd > "$BADROOT.initrd/boot/initrd.gz"
( cd "$BADROOT.initrd" && tar -cJf "$BADPKG" . )
assert_failure 'an embedded initrd should fail closed' inspect_package_archive "$BADPKG" 6.18.42 "$OUT/bad-members" "$OUT/bad-doinst" "$OUT/bad-summary"

MALICIOUS_DIR="$TMP/malicious"
mkdir -p "$MALICIOUS_DIR"
python3 - "$MALICIOUS_DIR/kernel-generic-6.18.42-x86_64-1.txz" <<'PY_TAR'
import io, tarfile, sys
with tarfile.open(sys.argv[1], 'w:xz') as archive:
    member = tarfile.TarInfo('../escape')
    payload = b'escape\n'
    member.size = len(payload)
    archive.addfile(member, io.BytesIO(payload))
PY_TAR
assert_failure 'archive parent traversal should fail closed' inspect_package_archive "$MALICIOUS_DIR/kernel-generic-6.18.42-x86_64-1.txz" 6.18.42 "$OUT/bad-members" "$OUT/bad-doinst" "$OUT/bad-summary"
python3 - "$MALICIOUS_DIR/kernel-generic-6.18.42-x86_64-1.txz" <<'PY_TAR'
import tarfile, sys
with tarfile.open(sys.argv[1], 'w:xz') as archive:
    member = tarfile.TarInfo('lib/modules/6.18.42/escape')
    member.type = tarfile.SYMTYPE
    member.linkname = '../../../../etc/passwd'
    archive.addfile(member)
PY_TAR
assert_failure 'archive links escaping the package root should fail closed' inspect_package_archive "$MALICIOUS_DIR/kernel-generic-6.18.42-x86_64-1.txz" 6.18.42 "$OUT/bad-members" "$OUT/bad-doinst" "$OUT/bad-summary"

cat > "$OUT/doinst.bad" <<'EOF_BAD'
#!/bin/sh
mkinitrd -F
ln -sf vmlinuz-6.18.42 vmlinuz-generic
EOF_BAD
assert_failure 'doinst must not invoke mkinitrd' validate_doinst_policy "$OUT/doinst.bad" 6.18.42 "$OUT/bad-policy"
cat > "$OUT/doinst.bootloader" <<'EOF_BOOTLOADER'
#!/bin/sh
lilo
ln -sf vmlinuz-6.18.42 vmlinuz-generic
EOF_BOOTLOADER
assert_failure 'doinst must not invoke another boot loader' validate_doinst_policy "$OUT/doinst.bootloader" 6.18.42 "$OUT/bad-policy"
printf '%s\n' '#!/bin/sh' 'if then' 'ln -sf vmlinuz-6.18.42 vmlinuz-generic' > "$OUT/doinst.syntax"
assert_failure 'invalid doinst shell syntax should fail closed' validate_doinst_policy "$OUT/doinst.syntax" 6.18.42 "$OUT/bad-policy"
cat > "$OUT/doinst.comment" <<'EOF_COMMENT'
#!/bin/sh
# Run mkinitrd manually only if this host uses an initrd.
echo "reboot after reviewing the boot loader"
ln -sf vmlinuz-6.18.42 vmlinuz-generic
if [ -r var/lib/pkgtools/setup/setup.01.mkinitrd ]; then
  if ! grep -wq vmlinuz-generic-smp var/lib/pkgtools/setup/setup.01.mkinitrd ; then
    if [ -z "$INSIDE_INSTALLER" ]; then
      if [ -x usr/sbin/geninitrd ]; then
        usr/sbin/geninitrd
      fi
    fi
  fi
fi
EOF_COMMENT
assert_success 'comments and informational text should not be treated as executed commands' validate_doinst_policy "$OUT/doinst.comment" 6.18.42 "$OUT/comment-policy"
cat > "$OUT/doinst.bad" <<'EOF_BAD'
#!/bin/sh
ln -sf vmlinuz-6.18.42 vmlinuz-generic
ln -sf vmlinuz-6.18.42 vmlinuz-generic
EOF_BAD
assert_failure 'duplicate generic transitions should fail closed' validate_doinst_policy "$OUT/doinst.bad" 6.18.42 "$OUT/bad-policy"
cat > "$OUT/doinst.bad" <<'EOF_BAD'
#!/bin/sh
ln -sf vmlinuz-6.18.40 vmlinuz-generic
EOF_BAD
assert_failure 'a transition to the wrong version should fail closed' validate_doinst_policy "$OUT/doinst.bad" 6.18.42 "$OUT/bad-policy"
cat > "$OUT/doinst.bad" <<'EOF_BAD'
#!/bin/sh
rm -rf /
ln -sf vmlinuz-6.18.42 vmlinuz-generic
EOF_BAD
assert_failure 'absolute destructive removal should fail closed' validate_doinst_policy "$OUT/doinst.bad" 6.18.42 "$OUT/bad-policy"

cat > "$OUT/doinst.nohook" <<'EOF_NOHOOK'
#!/bin/sh
ln -sf vmlinuz-6.18.42 vmlinuz-generic
EOF_NOHOOK
assert_failure 'a package without the conditional geninitrd hook should fail closed' validate_doinst_policy "$OUT/doinst.nohook" 6.18.42 "$OUT/bad-policy"
cat > "$OUT/doinst.doublehook" <<'EOF_DOUBLEHOOK'
#!/bin/sh
ln -sf vmlinuz-6.18.42 vmlinuz-generic
if [ -r var/lib/pkgtools/setup/setup.01.mkinitrd ]; then
  if ! grep -wq vmlinuz-generic-smp var/lib/pkgtools/setup/setup.01.mkinitrd ; then
    if [ -z "$INSIDE_INSTALLER" ]; then
      if [ -x usr/sbin/geninitrd ]; then
        usr/sbin/geninitrd
        usr/sbin/geninitrd
      fi
    fi
  fi
fi
EOF_DOUBLEHOOK
assert_failure 'duplicate geninitrd invocations should fail closed' validate_doinst_policy "$OUT/doinst.doublehook" 6.18.42 "$OUT/bad-policy"

assert_contains '"apply_ready": false' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260804-accepted.json" 'boot discovery evidence should remain non-ready'
assert_contains 'exact_package_preflight_required' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260804-accepted.json" 'boot discovery should require this exact-package preflight'
assert_contains '"accepted": true' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260804-accepted.json" 'the restarted-chain evidence should be accepted'
assert_contains '"nested_target_image_metadata_state": "deferred-to-exact-package-preflight"' "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260804-accepted.json" 'the restarted chain should preserve the deferred ownership boundary'

printf 'Slackware-current kernel package preflight harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
