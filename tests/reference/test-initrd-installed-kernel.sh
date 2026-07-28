#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "$TEST_DIR/../.." && pwd)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"

# Source the reference implementation without invoking main().
# shellcheck source=../../tools/reference/slack-update-reference.sh
source "$REFERENCE_SCRIPT"

TEST_COUNT=0
FAILURE_COUNT=0

pass() {
    TEST_COUNT=$((TEST_COUNT + 1))
}

fail() {
    local message=$1

    TEST_COUNT=$((TEST_COUNT + 1))
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$message" >&2
}

assert_equal() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" = "$expected" ]; then
        pass
    else
        fail "$message (expected '$expected', got '$actual')"
    fi
}

assert_success() {
    local message=$1
    shift

    if "$@"; then
        pass
    else
        fail "$message"
    fi
}

assert_failure() {
    local message=$1
    shift

    if "$@"; then
        fail "$message"
    else
        pass
    fi
}

assert_status() {
    local expected=$1
    local message=$2
    shift 2
    local status

    "$@" >/dev/null 2>&1
    status=$?
    assert_equal "$expected" "$status" "$message"
}

assert_file_exists() {
    local path=$1
    local message=$2

    if [ -e "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

assert_file_missing() {
    local path=$1
    local message=$2

    if [ ! -e "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

assert_file_contains() {
    local pattern=$1
    local path=$2
    local message=$3

    if grep -Fq -- "$pattern" "$path"; then
        pass
    else
        fail "$message"
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

MKINITRD_CONFIG="$TEST_TMP/mkinitrd.conf"
AFTER_PKGS="$TEST_TMP/packages.after"
KERNEL_MODULES_DIRECTORY="$TEST_TMP/modules"
INITRD_KERNEL_PACKAGE=kernel-generic
INITRD_DEFAULT_OUTPUT="$TEST_TMP/initrd-default.gz"
mkdir -p "$KERNEL_MODULES_DIRECTORY"

write_snapshot() {
    LC_ALL=C sort > "$AFTER_PKGS"
}

write_config() {
    cat > "$MKINITRD_CONFIG"
}

# Safe, non-evaluating mkinitrd.conf scalar parsing.
write_config <<'EOF_CONFIG'
# Commented assignments must be ignored.
# KERNEL_VERSION="0.0.0"
export KERNEL_VERSION = "6.12.21" # installed kernel
ROOTDEV='/dev/sda2'
OUTPUT_IMAGE="/boot/initrd-test.gz"
EOF_CONFIG
assert_success 'a quoted KERNEL_VERSION assignment should be parsed safely' \
    read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" KERNEL_VERSION
assert_equal '6.12.21' "$MKINITRD_ASSIGNMENT_VALUE" \
    'quoted KERNEL_VERSION should be normalized'
assert_success 'an exported ROOTDEV assignment should be parsed safely' \
    read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" ROOTDEV
assert_equal '/dev/sda2' "$MKINITRD_ASSIGNMENT_VALUE" \
    'quoted ROOTDEV should be normalized'
assert_success 'OUTPUT_IMAGE should be parsed safely' \
    read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" OUTPUT_IMAGE
assert_equal '/boot/initrd-test.gz' "$MKINITRD_ASSIGNMENT_VALUE" \
    'OUTPUT_IMAGE should preserve its absolute path'
assert_status 1 'a missing assignment should have a distinct status' \
    read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" MISSING_VALUE

write_config <<'EOF_CONFIG'
KERNEL_VERSION="6.12.21"
KERNEL_VERSION="6.12.22"
EOF_CONFIG
assert_status 2 'duplicate KERNEL_VERSION assignments should be rejected' \
    read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" KERNEL_VERSION
assert_equal "duplicate KERNEL_VERSION assignment in: $MKINITRD_CONFIG" \
    "$MKINITRD_ASSIGNMENT_ERROR" \
    'duplicate assignments should expose a stable diagnostic'

write_config <<'EOF_CONFIG'
KERNEL_VERSION="$(uname -r)"
EOF_CONFIG
assert_status 2 'command substitution must never be accepted from mkinitrd.conf' \
    read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" KERNEL_VERSION
assert_equal "unsafe KERNEL_VERSION assignment in: $MKINITRD_CONFIG" \
    "$MKINITRD_ASSIGNMENT_ERROR" \
    'unsafe assignments should expose a stable diagnostic'

# Installed-kernel resolution must use the validated post-update package snapshot.
printf '%s\n' \
    'bash-5.2.037-x86_64-1' \
    'kernel-generic-6.12.21-x86_64-1' \
    'kernel-modules-6.12.21-x86_64-1' \
    | write_snapshot
INITRD_VALIDATION_ERROR=
assert_success 'the installed generic kernel should be resolved from the post-update snapshot' \
    resolve_installed_initrd_kernel_version "$AFTER_PKGS" "$INITRD_KERNEL_PACKAGE"
assert_equal '6.12.21' "$INITRD_INSTALLED_KERNEL_VERSION" \
    'the installed kernel version should come from kernel-generic'
assert_equal 1 "$INITRD_INSTALLED_KERNEL_RECORD_COUNT" \
    'the installed kernel record count should be exposed'

printf '%s\n' \
    'bash-5.2.037-x86_64-1' \
    'kernel-modules-6.12.21-x86_64-1' \
    | write_snapshot
assert_failure 'a snapshot without kernel-generic should fail closed' \
    resolve_installed_initrd_kernel_version "$AFTER_PKGS" "$INITRD_KERNEL_PACKAGE"
assert_equal 'installed kernel package was not found in the post-update snapshot: kernel-generic' \
    "$INITRD_VALIDATION_ERROR" \
    'a missing installed kernel should expose a stable diagnostic'

printf '%s\n' \
    'kernel-generic-6.12.20-x86_64-1' \
    'kernel-generic-6.12.21-x86_64-1' \
    | write_snapshot
assert_failure 'multiple installed generic-kernel versions should be rejected as ambiguous' \
    resolve_installed_initrd_kernel_version "$AFTER_PKGS" "$INITRD_KERNEL_PACKAGE"
assert_equal 'installed kernel package has multiple versions in the post-update snapshot: kernel-generic' \
    "$INITRD_VALIDATION_ERROR" \
    'ambiguous installed kernels should expose a stable diagnostic'

# Complete validation: configured version, installed version, modules, root, and output.
printf '%s\n' \
    'bash-5.2.037-x86_64-1' \
    'kernel-generic-6.12.21-x86_64-1' \
    'kernel-modules-6.12.21-x86_64-1' \
    | write_snapshot
mkdir -p "$KERNEL_MODULES_DIRECTORY/6.12.21"
INITRD_OUTPUT="$TEST_TMP/initrd-custom.gz"
write_config <<EOF_CONFIG
KERNEL_VERSION="6.12.21"
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_success 'matching installed and configured kernels should validate' \
    validate_initrd_kernel_configuration
assert_equal 0 "$INITRD_VALIDATION_STATUS" \
    'successful validation should expose status zero'
assert_equal '6.12.21' "$INITRD_CONFIGURED_KERNEL_VERSION" \
    'the configured kernel version should be reported'
assert_equal '6.12.21' "$INITRD_INSTALLED_KERNEL_VERSION" \
    'the installed kernel version should be reported'
assert_equal "$KERNEL_MODULES_DIRECTORY/6.12.21" "$INITRD_MODULES_PATH" \
    'validation should target the installed kernel modules directory'
assert_equal "$INITRD_OUTPUT" "$INITRD_OUTPUT_PATH" \
    'validation should use OUTPUT_IMAGE when configured'

UNAME_MARKER="$TEST_TMP/uname-called"
uname() {
    : > "$UNAME_MARKER"
    printf '%s\n' '5.15.0-running'
}
assert_success 'validation should remain independent from the running kernel' \
    validate_initrd_kernel_configuration
assert_file_missing "$UNAME_MARKER" \
    'validation must not call uname or use the running kernel version'

write_config <<EOF_CONFIG
KERNEL_VERSION="5.15.0-running"
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_failure 'a stale running-kernel version should not match the installed package' \
    validate_initrd_kernel_configuration
assert_equal 1 "$INITRD_VALIDATION_STATUS" \
    'stale kernel validation should expose failure status'
assert_equal 'configured KERNEL_VERSION does not match the installed kernel-generic package: configured=5.15.0-running installed=6.12.21' \
    "$INITRD_VALIDATION_ERROR" \
    'stale KERNEL_VERSION should expose both configured and installed versions'
assert_file_missing "$UNAME_MARKER" \
    'stale validation must still avoid uname'

write_config <<EOF_CONFIG
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_failure 'missing KERNEL_VERSION should fail validation' \
    validate_initrd_kernel_configuration
assert_equal "KERNEL_VERSION assignment is missing from: $MKINITRD_CONFIG" \
    "$INITRD_VALIDATION_ERROR" \
    'missing KERNEL_VERSION should expose a stable diagnostic'

write_config <<EOF_CONFIG
KERNEL_VERSION="6.12.21"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_failure 'missing ROOTDEV should fail validation' \
    validate_initrd_kernel_configuration
assert_equal "ROOTDEV assignment is missing from: $MKINITRD_CONFIG" \
    "$INITRD_VALIDATION_ERROR" \
    'missing ROOTDEV should expose a stable diagnostic'

rmdir "$KERNEL_MODULES_DIRECTORY/6.12.21"
write_config <<EOF_CONFIG
KERNEL_VERSION="6.12.21"
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_failure 'missing modules for the installed kernel should fail validation' \
    validate_initrd_kernel_configuration
assert_equal "installed kernel modules directory is missing: $KERNEL_MODULES_DIRECTORY/6.12.21" \
    "$INITRD_VALIDATION_ERROR" \
    'missing modules should identify the installed version path'
mkdir -p "$KERNEL_MODULES_DIRECTORY/6.12.21"

LEGACY_OUTPUT="$TEST_TMP/initrd-legacy.gz"
write_config <<EOF_CONFIG
KERNEL_VERSION="6.12.21"
ROOTDEV="/dev/sda2"
OUTPUT="$LEGACY_OUTPUT"
EOF_CONFIG
assert_success 'legacy OUTPUT should remain supported' validate_initrd_kernel_configuration
assert_equal "$LEGACY_OUTPUT" "$INITRD_OUTPUT_PATH" \
    'legacy OUTPUT should be used when OUTPUT_IMAGE is absent'

write_config <<'EOF_CONFIG'
KERNEL_VERSION="6.12.21"
ROOTDEV="/dev/sda2"
EOF_CONFIG
assert_success 'the configured default output should be used when no output assignment exists' \
    validate_initrd_kernel_configuration
assert_equal "$INITRD_DEFAULT_OUTPUT" "$INITRD_OUTPUT_PATH" \
    'the default initrd output should be deterministic'

# Apply-time regeneration must not invoke mkinitrd until validation succeeds.
MKINITRD_CALLS="$TEST_TMP/mkinitrd-calls.txt"
mkinitrd() {
    printf '%s\n' "$*" >> "$MKINITRD_CALLS"
    : > "$INITRD_OUTPUT_PATH"
    printf 'initrd\n' > "$INITRD_OUTPUT_PATH"
    return 0
}
INITRD_UPDATE=1
INITRD_OK=0
write_config <<EOF_CONFIG
KERNEL_VERSION="6.12.21"
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_success 'valid installed-kernel state should permit mkinitrd' regenerate_initrd
assert_equal 1 "$INITRD_OK" 'successful regeneration should set INITRD_OK'
assert_file_contains '-F' "$MKINITRD_CALLS" 'mkinitrd should be invoked with the configured-file mode'
assert_file_exists "$INITRD_OUTPUT" 'successful regeneration should produce the validated output path'

: > "$MKINITRD_CALLS"
rm -f "$INITRD_OUTPUT"
INITRD_OK=0
write_config <<EOF_CONFIG
KERNEL_VERSION="5.15.0-running"
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_failure 'stale KERNEL_VERSION should block initrd regeneration' regenerate_initrd
assert_equal 0 "$INITRD_OK" 'blocked regeneration must leave INITRD_OK unset'
if [ ! -s "$MKINITRD_CALLS" ]; then
    pass
else
    fail 'mkinitrd must not run after installed-kernel validation fails'
fi
assert_file_missing "$INITRD_OUTPUT" 'blocked regeneration must not create the initrd output'

# A successful command without a non-empty image must remain a failure.
mkinitrd() {
    printf '%s\n' "$*" >> "$MKINITRD_CALLS"
    rm -f "$INITRD_OUTPUT_PATH"
    return 0
}
: > "$MKINITRD_CALLS"
INITRD_OK=0
write_config <<EOF_CONFIG
KERNEL_VERSION="6.12.21"
ROOTDEV="/dev/sda2"
OUTPUT_IMAGE="$INITRD_OUTPUT"
EOF_CONFIG
assert_failure 'mkinitrd success without an image should fail closed' regenerate_initrd
assert_equal 0 "$INITRD_OK" 'an absent output must not be reported as success'

# Boot probing should detect the path, while exact safety validation remains apply-time.
BOOT_MODE=auto
GRUB_DIRECTORY="$TEST_TMP/no-grub"
write_config <<'EOF_CONFIG'
KERNEL_VERSION="$(uname -r)"
ROOTDEV="/dev/sda2"
EOF_CONFIG
probe_boot_module
assert_equal 1 "$BOOT_INITRD_AVAILABLE" \
    'an installed mkinitrd command and configuration file should activate validation'
assert_equal available "$BOOT_MODULE_STATE" \
    'auto mode should run the boot module so invalid data fails closed later'

# Backward-compatible schema-1 defaults and explicit configuration keys.
initialize_configuration_state
assert_equal kernel-generic "$CONFIG_INITRD_KERNEL_PACKAGE" \
    'older schema-1 files should default to kernel-generic'
assert_equal /lib/modules "$CONFIG_KERNEL_MODULES_DIRECTORY" \
    'older schema-1 files should default to /lib/modules'

LEGACY_CONFIG="$TEST_TMP/legacy-slack-update.conf"
grep -v -E '^(kernel_package|modules_directory)=' \
    "$REPOSITORY_ROOT/data/config/slack-update.conf" > "$LEGACY_CONFIG"
SLACK_UPDATE_CONFIG="$LEGACY_CONFIG"
assert_success 'a schema-1 configuration without the new boot keys should remain valid' \
    load_configuration
assert_equal kernel-generic "$INITRD_KERNEL_PACKAGE" \
    'loaded legacy configuration should apply the default kernel package'
assert_equal /lib/modules "$KERNEL_MODULES_DIRECTORY" \
    'loaded legacy configuration should apply the default modules directory'

SLACK_UPDATE_CONFIG="$REPOSITORY_ROOT/data/config/slack-update.conf"
assert_success 'the repository configuration should load the explicit boot validation keys' \
    load_configuration
assert_equal kernel-generic "$INITRD_KERNEL_PACKAGE" \
    'repository configuration should select kernel-generic'
assert_equal /lib/modules "$KERNEL_MODULES_DIRECTORY" \
    'repository configuration should select /lib/modules'

# Provisional JSON must report the exact validation source and outcome.
initialize_runtime_state
PACKAGE_SNAPSHOT_BEFORE_VALID=1
PACKAGE_SNAPSHOT_AFTER_VALID=1
SLACKPKG_UPDATE_STATUS=0
SLACKPKG_INSTALL_NEW_STATUS=0
SLACKPKG_UPGRADE_ALL_STATUS=0
FLATPAK_MODE=auto
FLATPAK_MODULE_RUN=0
FLATPAK_MODULE_STATE=unavailable
SBO_MODE=auto
SBO_MODULE_RUN=0
SBO_MODULE_STATE=unavailable
ELF_MODE=auto
ELF_MODULE_RUN=0
ELF_MODULE_STATE=unavailable
CINNAMON_MODE=auto
CINNAMON_MODULE_RUN=0
CINNAMON_MODULE_STATE=unavailable
BOOT_MODE=auto
BOOT_MODULE_STATE=available
INITRD_REQUIRED=1
INITRD_UPDATE=1
INITRD_OK=0
INITRD_VALIDATION_STATUS=1
INITRD_VALIDATION_ERROR='configured KERNEL_VERSION does not match installed kernel'
INITRD_CONFIGURED_KERNEL_VERSION='5.15.0-running'
INITRD_INSTALLED_KERNEL_VERSION='6.12.21'
INITRD_INSTALLED_KERNEL_RECORD_COUNT=1
INITRD_MODULES_PATH="$KERNEL_MODULES_DIRECTORY/6.12.21"
INITRD_OUTPUT_PATH="$INITRD_OUTPUT"
INITRD_KERNEL_PACKAGE=kernel-generic
KERNEL_MODULES_DIRECTORY="$TEST_TMP/modules"
GRUB_REQUIRED=0
GRUB_UPDATE=0
BROKEN="$TEST_TMP/json-broken"
SBO_OPTION_RECORDS="$TEST_TMP/json-options"
: > "$BROKEN"
: > "$SBO_OPTION_RECORDS"
JSON_OUTPUT_FILE="$TEST_TMP/modules.json"
{
    printf '{"modules":{\n'
    print_apply_json_modules
    printf '}}\n'
} > "$JSON_OUTPUT_FILE"
if jq -e . "$JSON_OUTPUT_FILE" >/dev/null; then
    pass
else
    fail 'provisional initrd JSON should be valid'
fi
assert_file_contains '"kernel_version_source": "post-update-package-snapshot"' "$JSON_OUTPUT_FILE" \
    'JSON should identify the installed package snapshot as the kernel source'
assert_file_contains '"kernel_package": "kernel-generic"' "$JSON_OUTPUT_FILE" \
    'JSON should report the package used to resolve the installed kernel'
assert_file_contains '"configured_kernel_version": "5.15.0-running"' "$JSON_OUTPUT_FILE" \
    'JSON should report the configured kernel version'
assert_file_contains '"installed_kernel_version": "6.12.21"' "$JSON_OUTPUT_FILE" \
    'JSON should report the installed kernel version'
assert_file_contains '"initrd_validation_exit_code": 1' "$JSON_OUTPUT_FILE" \
    'JSON should expose validation failure status'
assert_file_contains '"initrd_validation_error": "configured KERNEL_VERSION does not match installed kernel"' "$JSON_OUTPUT_FILE" \
    'JSON should expose the validation diagnostic'

# Source audit: installed-kernel validation must not regress to the running kernel.
VALIDATION_SOURCE="$TEST_TMP/validation-source.txt"
{
    declare -f resolve_installed_initrd_kernel_version
    declare -f validate_initrd_kernel_configuration
    declare -f regenerate_initrd
} > "$VALIDATION_SOURCE"
if grep -Eq 'uname([[:space:]]|$)|/proc/sys/kernel/osrelease' "$VALIDATION_SOURCE"; then
    fail 'initrd validation source must not inspect the running kernel'
else
    pass
fi
assert_file_contains 'resolve_installed_initrd_kernel_version "$AFTER_PKGS"' "$VALIDATION_SOURCE" \
    'validation should explicitly consume the post-update package snapshot'

printf 'Installed-kernel initrd tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"

[ "$FAILURE_COUNT" -eq 0 ]
