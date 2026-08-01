#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-generator-preflight.sh"

# Source helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-elilo-generator-preflight.sh
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

assert_contains 'never executes the proposed command' "$ACCEPTANCE_SCRIPT" \
    'usage should state that generated commands are not executed'
assert_contains 'bash "$GENERATOR" -k "$RUNNING_KERNEL"' "$ACCEPTANCE_SCRIPT" \
    'the generator should be probed for the running kernel'
assert_not_contains 'bash "$GENERATOR" -k "$RUNNING_KERNEL" | bash' "$ACCEPTANCE_SCRIPT" \
    'the generated command must never be piped to a shell'
assert_not_contains 'eval ' "$ACCEPTANCE_SCRIPT" \
    'the preflight must not evaluate generated shell text'
assert_not_contains 'mkinitrd -c' "$ACCEPTANCE_SCRIPT" \
    'the preflight must not invoke mkinitrd directly'
assert_not_contains 'eliloconfig' "$ACCEPTANCE_SCRIPT" \
    'the preflight must not invoke eliloconfig'
assert_not_contains 'slackpkg upgrade' "$ACCEPTANCE_SCRIPT" \
    'the preflight must not update packages'
assert_contains 'Copy evidence command:' "$ACCEPTANCE_SCRIPT" \
    'the script should print a one-line copy command'
assert_contains 'owner=${SUDO_USER:-promano}' "$ACCEPTANCE_SCRIPT" \
    'the copy command should default to promano'
assert_contains '/usr/share/mkinitrd/mkinitrd_command_generator.sh' "$ACCEPTANCE_SCRIPT" \
    'the official Slackware generator path should be fixed'
assert_contains 'ELILO_DIRECTORY=/boot/efi/EFI/Slackware' "$ACCEPTANCE_SCRIPT" \
    'the ELILO directory should be explicit'
assert_contains 'ELILO_CONFIG=$ELILO_DIRECTORY/elilo.conf' "$ACCEPTANCE_SCRIPT" \
    'the ELILO configuration should be resolved inside the fixed directory'
assert_contains 'findmnt -n -o SOURCE,FSTYPE,OPTIONS /boot/efi' "$ACCEPTANCE_SCRIPT" \
    'the EFI system partition should be recorded'
assert_contains 'find -H "$database"' "$ACCEPTANCE_SCRIPT" \
    'package enumeration should follow the compatibility symlink'

TARGET=
OUTPUT_DIR=
assert_success 'Slackware 15.0 arguments should parse' \
    parse_arguments --target slackware-15.0
assert_equal slackware-15.0 "$TARGET" 'the target should be preserved'

TARGET=
OUTPUT_DIR=
assert_failure 'Slackware-current should be rejected' \
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

ELILO_CONFIG="$TMP/elilo.conf"
cat > "$ELILO_CONFIG" <<'EOF_CONFIG'
image=vmlinuz
        label=vmlinuz
        initrd=initrd.gz
        append="root=/dev/sda2 vga=normal ro"
EOF_CONFIG
assert_equal vmlinuz "$(read_elilo_assignment image)" \
    'the image basename should be parsed'
assert_equal initrd.gz "$(read_elilo_assignment initrd)" \
    'the initrd basename should be parsed'

printf 'image=vmlinuz\nimage=second\ninitrd=initrd.gz\n' > "$ELILO_CONFIG"
assert_failure 'duplicate image directives should be rejected' \
    read_elilo_assignment image

printf 'image=../vmlinuz\ninitrd=initrd.gz\n' > "$ELILO_CONFIG"
assert_failure 'parent traversal should be rejected' \
    read_elilo_assignment image

printf 'image=/boot/vmlinuz\ninitrd=initrd.gz\n' > "$ELILO_CONFIG"
assert_failure 'absolute image paths should be rejected' \
    read_elilo_assignment image

printf 'image=subdir/vmlinuz\ninitrd=initrd.gz\n' > "$ELILO_CONFIG"
assert_failure 'nested image paths should be rejected' \
    read_elilo_assignment image

printf 'image=vmlinuz\n' > "$ELILO_CONFIG"
assert_failure 'missing initrd directives should be rejected' \
    read_elilo_assignment initrd

printf 'same\n' > "$TMP/first"
printf 'same\n' > "$TMP/second"
assert_success 'equal regular files should compare successfully' \
    compare_regular_files "$TMP/first" "$TMP/second"
printf 'different\n' > "$TMP/second"
assert_failure 'different regular files should not compare successfully' \
    compare_regular_files "$TMP/first" "$TMP/second"
ln -s "$TMP/first" "$TMP/link"
assert_failure 'symbolic-link inputs should be rejected for initrd comparison' \
    compare_regular_files "$TMP/link" "$TMP/first"
assert_success 'resolved kernel symlinks may be compared to the EFI copy' \
    compare_boot_symlink_copy "$TMP/link" "$TMP/first"

mkdir -p "$TMP/packages"
touch "$TMP/packages/kernel-generic-5.15.19-x86_64-2"
ln -s "$TMP/packages" "$TMP/packages-link"
assert_success 'package database capture should follow the top-level symlink' \
    capture_package_database "$TMP/packages-link" "$TMP/packages.sha256"
assert_success 'package database capture should produce a digest' \
    test -s "$TMP/packages.sha256"


FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-discovery-reviewed.json"
assert_success 'the reviewed ELILO discovery fixture should be valid JSON' \
    python -m json.tool "$FIXTURE"
assert_contains '"classification": "elilo"' "$FIXTURE" \
    'the reviewed fixture should preserve the ELILO classification'
assert_contains '"apply_authorized": false' "$FIXTURE" \
    'the reviewed discovery must not authorize a kernel apply'
assert_contains '"archive_sha256": "78f4d60738fe08a5ce599458e7da8917402bb029a90b0f9ac449c6129b6746ab"' "$FIXTURE" \
    'the reviewed fixture should preserve the evidence digest'

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'the acceptance script should pass bash -n'

printf 'ELILO generator preflight harness: %d checks, %d failures\n' \
    "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
