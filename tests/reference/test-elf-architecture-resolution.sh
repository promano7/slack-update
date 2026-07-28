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

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

BROKEN_ERRORS="$TEST_TMP/elf-errors.txt"
ELF_LIBRARY_CACHE="$TEST_TMP/elf-cache.txt"
BROKEN_NEW="$TEST_TMP/broken-new.txt"
BROKEN="$TEST_TMP/broken.txt"
STILL_BROKEN="$TEST_TMP/still-broken.txt"
: > "$BROKEN_ERRORS"
: > "$BROKEN_NEW"
: > "$BROKEN"
: > "$STILL_BROKEN"

X86_64_IDENTITY=$'ELF64\t2\x27s complement, little endian\tAdvanced Micro Devices X86-64'
X86_IDENTITY=$'ELF32\t2\x27s complement, little endian\tIntel 80386'
AARCH64_IDENTITY=$'ELF64\t2\x27s complement, little endian\tAArch64'
X86_64_BIG_IDENTITY=$'ELF64\t2\x27s complement, big endian\tAdvanced Micro Devices X86-64'

# Preserve the production parser before installing deterministic readelf output.
eval "$(declare -f extract_static_elf_identity | sed '1s/extract_static_elf_identity/original_extract_static_elf_identity/')"

READELF_ARGUMENTS="$TEST_TMP/readelf-arguments.txt"
READELF_HEADER_MODE=x86_64
readelf() {
    printf '%s\n' "$*" > "$READELF_ARGUMENTS"
    case "$READELF_HEADER_MODE" in
        x86_64)
            cat <<'EOF_HEADER'
ELF Header:
  Class:                             ELF64
  Data:                              2's complement, little endian
  Machine:                           Advanced Micro Devices X86-64
EOF_HEADER
            ;;
        x86)
            cat <<'EOF_HEADER'
ELF Header:
  Class:                             ELF32
  Data:                              2's complement, little endian
  Machine:                           Intel 80386
EOF_HEADER
            ;;
        aarch64)
            cat <<'EOF_HEADER'
ELF Header:
  Class:                             ELF64
  Data:                              2's complement, little endian
  Machine:                           AArch64
EOF_HEADER
            ;;
        missing-machine)
            cat <<'EOF_HEADER'
ELF Header:
  Class:                             ELF64
  Data:                              2's complement, little endian
EOF_HEADER
            ;;
        *)
            return 1
            ;;
    esac
}

READELF_HEADER_MODE=x86_64
assert_equal "$X86_64_IDENTITY" \
    "$(original_extract_static_elf_identity "$TEST_TMP/object")" \
    'ELF64 x86-64 identity should be normalized'
assert_equal "-h
--
$TEST_TMP/object" "$(cat "$READELF_ARGUMENTS")" \
    'identity extraction should pass the object after --'
READELF_HEADER_MODE=x86
assert_equal "$X86_IDENTITY" \
    "$(original_extract_static_elf_identity "$TEST_TMP/object")" \
    'ELF32 x86 identity should be normalized'
READELF_HEADER_MODE=aarch64
assert_equal "$AARCH64_IDENTITY" \
    "$(original_extract_static_elf_identity "$TEST_TMP/object")" \
    'ELF64 AArch64 identity should be normalized'
READELF_HEADER_MODE=missing-machine
assert_failure 'an incomplete ELF header should fail identity extraction' \
    original_extract_static_elf_identity "$TEST_TMP/object"

CACHE="$TEST_TMP/architecture-cache.txt"
printf '%s\t%s\t%s\t%s\t%s\n' \
    'libsame.so.1' 'ELF32' "2's complement, little endian" 'Intel 80386' '/lib/libsame.so.1' \
    'libsame.so.1' 'ELF64' "2's complement, little endian" 'AArch64' '/lib64/aarch64/libsame.so.1' \
    'libsame.so.1' 'ELF64' "2's complement, little endian" 'Advanced Micro Devices X86-64' '/lib64/libsame.so.1' \
    'libsame.so.1' 'ELF64' "2's complement, big endian" 'Advanced Micro Devices X86-64' '/lib64/be/libsame.so.1' \
    'libsecond.so.2' 'ELF64' "2's complement, little endian" 'Advanced Micro Devices X86-64' '/lib64/libsecond.so.2' \
    > "$CACHE"
LC_ALL=C sort -o "$CACHE" "$CACHE"

assert_success 'the ELF64 x86-64 candidate should satisfy the matching identity' \
    static_elf_cache_has_compatible_library "$CACHE" 'libsame.so.1' "$X86_64_IDENTITY"
assert_success 'the ELF32 x86 candidate should satisfy the matching identity' \
    static_elf_cache_has_compatible_library "$CACHE" 'libsame.so.1' "$X86_IDENTITY"
assert_success 'the AArch64 candidate should satisfy the matching identity' \
    static_elf_cache_has_compatible_library "$CACHE" 'libsame.so.1' "$AARCH64_IDENTITY"
assert_success 'the big-endian candidate should satisfy only its exact identity' \
    static_elf_cache_has_compatible_library "$CACHE" 'libsame.so.1' "$X86_64_BIG_IDENTITY"
assert_failure 'an absent soname must not match a similarly structured cache' \
    static_elf_cache_has_compatible_library "$CACHE" 'libmissing.so.1' "$X86_64_IDENTITY"
assert_failure 'a soname prefix must not count as an exact match' \
    static_elf_cache_has_compatible_library "$CACHE" 'libsame.so' "$X86_64_IDENTITY"
assert_failure 'a malformed identity must be rejected' \
    static_elf_cache_has_compatible_library "$CACHE" 'libsame.so.1' $'ELF64\tbroken'

X86_ONLY_CACHE="$TEST_TMP/x86-only-cache.txt"
grep $'libsame.so.1\tELF32\t' "$CACHE" > "$X86_ONLY_CACHE"
assert_failure 'an ELF32 library must not satisfy an ELF64 object' \
    static_elf_cache_has_compatible_library "$X86_ONLY_CACHE" 'libsame.so.1' "$X86_64_IDENTITY"

AARCH64_ONLY_CACHE="$TEST_TMP/aarch64-only-cache.txt"
grep $'libsame.so.1\tELF64\t2\x27s complement, little endian\tAArch64\t' \
    "$CACHE" > "$AARCH64_ONLY_CACHE"
assert_failure 'an AArch64 library must not satisfy an x86-64 object' \
    static_elf_cache_has_compatible_library "$AARCH64_ONLY_CACHE" 'libsame.so.1' "$X86_64_IDENTITY"

BIG_ENDIAN_ONLY_CACHE="$TEST_TMP/big-endian-only-cache.txt"
grep $'libsame.so.1\tELF64\t2\x27s complement, big endian\t' \
    "$CACHE" > "$BIG_ENDIAN_ONLY_CACHE"
assert_failure 'a big-endian library must not satisfy a little-endian object' \
    static_elf_cache_has_compatible_library "$BIG_ENDIAN_ONLY_CACHE" 'libsame.so.1' "$X86_64_IDENTITY"

# Deterministic object metadata and dependency fixtures.
extract_static_elf_identity() {
    case "$1" in
        */x86_64-*) printf '%s\n' "$X86_64_IDENTITY" ;;
        */x86-*) printf '%s\n' "$X86_IDENTITY" ;;
        */aarch64-*) printf '%s\n' "$AARCH64_IDENTITY" ;;
        */big-*) printf '%s\n' "$X86_64_BIG_IDENTITY" ;;
        */identity-error) return 1 ;;
        *) return 1 ;;
    esac
}

extract_static_elf_needed_libraries() {
    case "$1" in
        */*-healthy) printf '%s\n' 'libsame.so.1' ;;
        */*-multiple) printf '%s\n' 'libsame.so.1' 'libsecond.so.2' ;;
        */*-missing) printf '%s\n' 'libmissing.so.1' ;;
        */*-none) : ;;
        */needed-error) return 1 ;;
        *) return 1 ;;
    esac
}

assert_status 1 'a compatible x86-64 dependency set should be complete' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86_64-healthy" "$CACHE"
assert_status 1 'a compatible x86 dependency set should be complete' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86-healthy" "$CACHE"
assert_status 1 'a compatible AArch64 dependency set should be complete' \
    static_elf_object_has_missing_dependency "$TEST_TMP/aarch64-healthy" "$CACHE"
assert_status 1 'an object with no DT_NEEDED entries should be complete' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86_64-none" "$CACHE"
assert_status 1 'multiple compatible x86-64 dependencies should be complete' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86_64-multiple" "$CACHE"
assert_status 0 'an absent dependency should mark the object as broken' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86_64-missing" "$CACHE"
assert_status 0 'an ELF32 object should remain broken with only an ELF64 candidate' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86-healthy" \
    <(grep $'libsame.so.1\tELF64\t2\x27s complement, little endian\tAdvanced Micro Devices X86-64\t' "$CACHE")
assert_status 0 'an x86-64 object should remain broken with only an AArch64 candidate' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86_64-healthy" "$AARCH64_ONLY_CACHE"
assert_status 0 'a little-endian object should remain broken with only a big-endian candidate' \
    static_elf_object_has_missing_dependency "$TEST_TMP/x86_64-healthy" "$BIG_ENDIAN_ONLY_CACHE"
assert_status 2 'an unreadable ELF identity should produce an inspection error' \
    static_elf_object_has_missing_dependency "$TEST_TMP/identity-error" "$CACHE"
assert_status 2 'an unreadable dynamic section should produce an inspection error' \
    static_elf_object_has_missing_dependency "$TEST_TMP/needed-error" "$CACHE"

# End-to-end scan: the same soname exists, but only the compatible architecture counts.
SCAN_DIR="$TEST_TMP/scan"
mkdir -p "$SCAN_DIR"
printf '\177ELFfixture\n' > "$SCAN_DIR/x86_64-healthy"
printf '\177ELFfixture\n' > "$SCAN_DIR/x86-healthy"
printf '\177ELFfixture\n' > "$SCAN_DIR/aarch64-healthy"
ELF_SCAN_PATHS=("$SCAN_DIR")
SCAN_CACHE_SOURCE="$TEST_TMP/scan-cache.txt"
grep $'libsame.so.1\tELF64\t2\x27s complement, little endian\tAdvanced Micro Devices X86-64\t' \
    "$CACHE" > "$SCAN_CACHE_SOURCE"
refresh_static_elf_library_cache() {
    local destination=$1
    cp -f -- "$SCAN_CACHE_SOURCE" "$destination"
    ELF_LIBRARY_CACHE_RECORD_COUNT=$(wc -l < "$destination")
}

if detect_broken_elf_objects >/dev/null; then
    pass
else
    fail 'the architecture-aware scan should complete with a valid cache'
fi
EXPECTED_BROKEN=$(printf '%s\n' "$SCAN_DIR/aarch64-healthy" "$SCAN_DIR/x86-healthy")
assert_equal "$EXPECTED_BROKEN" "$(cat "$BROKEN")" \
    'only objects without a same-architecture candidate should be reported'
assert_equal 1 "$ELF_LIBRARY_CACHE_RECORD_COUNT" \
    'the architecture-aware cache should report its normalized record count'

cp -f -- "$CACHE" "$SCAN_CACHE_SOURCE"
if detect_broken_elf_objects >/dev/null; then
    pass
else
    fail 'the scan should complete when all architecture variants are available'
fi
assert_equal '' "$(cat "$BROKEN")" \
    'all objects should resolve when exact architecture variants exist'
assert_equal 5 "$ELF_LIBRARY_CACHE_RECORD_COUNT" \
    'the record count should include each architecture-tagged candidate'

# Post-rebuild verification must apply the same architecture rules.
printf '%s\n' "$SCAN_DIR/x86-healthy" > "$BROKEN"
grep $'libsame.so.1\tELF64\t2\x27s complement, little endian\tAdvanced Micro Devices X86-64\t' \
    "$CACHE" > "$SCAN_CACHE_SOURCE"
VERIFY_OUTPUT="$TEST_TMP/verify-output.txt"
if verify_broken_elf_objects_after_rebuild > "$VERIFY_OUTPUT"; then
    fail 'verification should fail when only a wrong-architecture library exists'
else
    pass
fi
assert_equal "$SCAN_DIR/x86-healthy" "$(cat "$BROKEN")" \
    'wrong-architecture verification should preserve the broken object'
grep $'libsame.so.1\tELF32\t' "$CACHE" > "$SCAN_CACHE_SOURCE"
if verify_broken_elf_objects_after_rebuild > "$VERIFY_OUTPUT"; then
    pass
else
    fail 'verification should pass after the compatible architecture appears'
fi
assert_equal '' "$(cat "$BROKEN")" \
    'successful architecture-aware verification should clear the object'

# Structured output advertises the exact compatibility boundary.
initialize_runtime_state
FLATPAK_MODE=auto
SBO_MODE=auto
ELF_MODE=auto
CINNAMON_MODE=auto
BOOT_MODE=auto
FLATPAK_MODULE_STATE=disabled
SBO_MODULE_STATE=disabled
ELF_MODULE_STATE=available
CINNAMON_MODULE_STATE=disabled
BOOT_MODULE_STATE=disabled
FLATPAK_MODULE_REASON='disabled for test'
SBO_MODULE_REASON='disabled for test'
ELF_MODULE_REASON=
CINNAMON_MODULE_REASON='disabled for test'
BOOT_MODULE_REASON='disabled for test'
PACKAGE_SNAPSHOT_BEFORE_VALID=1
PACKAGE_SNAPSHOT_AFTER_VALID=1
PACKAGE_SNAPSHOT_BEFORE_COUNT=1
PACKAGE_SNAPSHOT_AFTER_COUNT=1
SLACKPKG_UPDATE_STATUS=0
SLACKPKG_INSTALL_NEW_STATUS=0
SLACKPKG_UPGRADE_ALL_STATUS=0
ELF_SCAN_STATUS=0
ELF_VERIFICATION_STATUS=0
ELF_LIBRARY_CACHE_RECORD_COUNT=4
BROKEN="$TEST_TMP/json-broken.txt"
: > "$BROKEN"
JSON_MODULES="$TEST_TMP/elf-modules.json"
{
    printf '{"modules":{\n'
    print_apply_json_modules
    printf '}}\n'
} > "$JSON_MODULES"
if jq -e . "$JSON_MODULES" >/dev/null; then
    pass
else
    fail 'architecture-aware provisional module JSON should be valid'
fi
assert_equal true \
    "$(jq -r '.modules.elf.architecture_specific_resolution' "$JSON_MODULES")" \
    'JSON should state that resolution is architecture-specific'
assert_equal 'class,data,machine' \
    "$(jq -r '.modules.elf.architecture_match_fields | join(",")' "$JSON_MODULES")" \
    'JSON should expose every exact identity field'
assert_equal 4 "$(jq -r '.modules.elf.library_cache_records' "$JSON_MODULES")" \
    'JSON should expose the architecture-tagged cache record count'

if grep -Fq 'static_elf_cache_has_compatible_library' "$REFERENCE_SCRIPT"; then
    pass
else
    fail 'the reference implementation should use an explicit compatibility helper'
fi
if grep -Fq '$2 ~ /^\(/ { print $1 }' "$REFERENCE_SCRIPT"; then
    fail 'the reference implementation must not reduce the loader cache to sonames only'
else
    pass
fi
if grep -Fq 'architecture_specific_resolution": true' "$REFERENCE_SCRIPT"; then
    pass
else
    fail 'the reference implementation should advertise architecture-specific resolution'
fi

printf 'ELF architecture-resolution tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
