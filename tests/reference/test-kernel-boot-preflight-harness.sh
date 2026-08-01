#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-kernel-boot-preflight.sh"

# Source helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-kernel-boot-preflight.sh
source "$ACCEPTANCE_SCRIPT"

TEST_COUNT=0
TEST_FAILURE_COUNT=0

pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() {
    TEST_COUNT=$((TEST_COUNT + 1))
    TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" >&2
}
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() {
    local expected=$1 actual=$2 message=$3
    [ "$expected" = "$actual" ] && pass || fail "$message (expected '$expected', got '$actual')"
}
assert_contains() {
    local pattern=$1 path=$2 message=$3
    grep -Fq -- "$pattern" "$path" && pass || fail "$message"
}
assert_not_contains() {
    local pattern=$1 path=$2 message=$3
    grep -Fq -- "$pattern" "$path" && fail "$message" || pass
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_contains 'never changes Slackpkg configuration, packages' "$ACCEPTANCE_SCRIPT" \
    'usage should state the non-destructive boundary'
assert_contains 'Boot summary:' "$ACCEPTANCE_SCRIPT" \
    'the scenario should print a concise boot summary'
assert_contains 'Copy evidence command:' "$ACCEPTANCE_SCRIPT" \
    'the scenario should print a one-line evidence copy command'
assert_contains 'owner=${SUDO_USER:-promano}' "$ACCEPTANCE_SCRIPT" \
    'the copy command should default to the promano account'
assert_contains '/etc/lilo.conf' "$ACCEPTANCE_SCRIPT" \
    'the scenario should inspect LILO configuration'
assert_contains '/boot/efi/EFI/Slackware/elilo.conf' "$ACCEPTANCE_SCRIPT" \
    'the scenario should inspect ELILO configuration'
assert_contains '/boot/grub/grub.cfg' "$ACCEPTANCE_SCRIPT" \
    'the scenario should inspect GRUB configuration'
assert_contains 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' "$ACCEPTANCE_SCRIPT" \
    'the preflight should use a deterministic administrative command path'
assert_contains '/sys/firmware/efi' "$ACCEPTANCE_SCRIPT" \
    'the scenario should classify BIOS versus UEFI firmware'
assert_contains 'reference-unsupported' "$ACCEPTANCE_SCRIPT" \
    'LILO and ELILO should remain explicitly unsupported by the reference'
assert_contains 'find -H /var/log/packages' "$ACCEPTANCE_SCRIPT" \
    'package records should follow the Slackware compatibility symlink'
assert_not_contains 'lilo -v' "$ACCEPTANCE_SCRIPT" \
    'preflight must not run LILO installation commands'
assert_not_contains 'grub-mkconfig -o' "$ACCEPTANCE_SCRIPT" \
    'preflight must not regenerate GRUB configuration'
assert_not_contains 'mkinitrd -F' "$ACCEPTANCE_SCRIPT" \
    'preflight must not regenerate initrd'
assert_not_contains 'slackpkg upgrade' "$ACCEPTANCE_SCRIPT" \
    'preflight must not update packages'

TARGET=
OUTPUT_DIR=
assert_success 'Slackware 15.0 arguments should parse' \
    parse_arguments --target slackware-15.0
assert_equal slackware-15.0 "$TARGET" 'the target should be preserved'

TARGET=
OUTPUT_DIR=
assert_failure 'Slackware-current should be rejected for this dedicated scenario' \
    parse_arguments --target slackware-current

TARGET=
OUTPUT_DIR=
assert_failure 'relative output directories should be rejected' \
    parse_arguments --target slackware-15.0 --output-dir relative/path

TARGET=
OUTPUT_DIR=
assert_success 'absolute output directories should parse' \
    parse_arguments --target slackware-15.0 --output-dir "$TMP/output"
assert_equal "$TMP/output" "$OUTPUT_DIR" 'the absolute output path should be preserved'

CONFIG="$TMP/mkinitrd.conf"
cat > "$CONFIG" <<'EOF_CONFIG'
KERNEL_VERSION="5.15.209"
ROOTDEV='/dev/sda2'
OUTPUT_IMAGE=/boot/initrd.gz
EOF_CONFIG
assert_equal 5.15.209 "$(read_scalar_assignment "$CONFIG" KERNEL_VERSION)" \
    'quoted KERNEL_VERSION should be parsed'
assert_equal /dev/sda2 "$(read_scalar_assignment "$CONFIG" ROOTDEV)" \
    'single-quoted ROOTDEV should be parsed'
assert_equal /boot/initrd.gz "$(read_scalar_assignment "$CONFIG" OUTPUT_IMAGE)" \
    'plain OUTPUT_IMAGE should be parsed'
assert_failure 'missing assignments should be rejected' \
    read_scalar_assignment "$CONFIG" MODULE_LIST
printf 'KERNEL_VERSION=one\nKERNEL_VERSION=two\n' > "$CONFIG"
assert_failure 'duplicate assignments should be rejected' \
    read_scalar_assignment "$CONFIG" KERNEL_VERSION

FAKE_ROOT="$TMP/fake"
mkdir -p "$FAKE_ROOT/var/log/packages"
touch "$FAKE_ROOT/var/log/packages/kernel-generic-5.15.19-x86_64-2"
touch "$FAKE_ROOT/var/log/packages/kernel-modules-5.15.19-x86_64-2"
ln -s "$FAKE_ROOT/var/log/packages" "$TMP/packages-link"
capture_package_database "$TMP/packages-link" "$TMP/packages.sha256"
assert_success 'package database capture should produce a digest' test -s "$TMP/packages.sha256"

printf 'kernel-generic\nkernel-huge\nkernel-modules\n' > "$TMP/blacklist"
for package in kernel-generic kernel-huge kernel-modules; do
    grep -Eq "^[[:space:]]*${package}([[:space:]]*(#.*)?)?$" "$TMP/blacklist" \
        && pass || fail "the blacklist matcher should recognize $package"
done

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'the acceptance script should pass bash -n'

printf 'Kernel boot preflight harness: %d checks, %d failures\n' \
    "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
