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

assert_file_empty() {
    local path=$1
    local message=$2

    if [ ! -s "$path" ]; then
        pass
    else
        fail "$message"
        sed 's/^/  /' "$path" >&2
    fi
}

assert_file_absent() {
    local path=$1
    local message=$2

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

assert_file_contains() {
    local path=$1
    local expected=$2
    local message=$3

    if grep -Fqx -- "$expected" "$path"; then
        pass
    else
        fail "$message"
    fi
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

# Preserve production helpers before installing deterministic test doubles.
eval "$(declare -f extract_static_elf_needed_libraries | sed '1s/extract_static_elf_needed_libraries/original_extract_static_elf_needed_libraries/')"
eval "$(declare -f refresh_static_elf_library_cache | sed '1s/refresh_static_elf_library_cache/original_refresh_static_elf_library_cache/')"

printf '\177ELFpayload\n' > "$TEST_TMP/elf-magic"
printf '#!/bin/sh\n' > "$TEST_TMP/text-file"
if elf_file_has_static_magic "$TEST_TMP/elf-magic"; then
    pass
else
    fail 'the static magic probe should recognize an ELF header without executing the file'
fi
if elf_file_has_static_magic "$TEST_TMP/text-file"; then
    fail 'the static magic probe should reject non-ELF data'
else
    pass
fi

ACTUAL_CACHE="$TEST_TMP/actual-cache.txt"
if original_refresh_static_elf_library_cache "$ACTUAL_CACHE"; then
    pass
else
    fail 'the production cache reader should parse /sbin/ldconfig -p'
fi
if [ -s "$ACTUAL_CACHE" ]; then
    pass
else
    fail 'the production cache reader should create a non-empty soname list'
fi
assert_equal 600 "$(stat -c '%a' "$ACTUAL_CACHE")" \
    'the static library cache should be private'
if LC_ALL=C sort -cu "$ACTUAL_CACHE"; then
    pass
else
    fail 'the static library cache should be C-locale sorted and unique'
fi

REAL_SHELL=$(resolve_static_elf_object_path /bin/sh 2>/dev/null || true)
if [ -n "$REAL_SHELL" ]; then
    pass
else
    fail '/bin/sh should resolve as a regular ELF object through static inspection'
fi
REAL_SHELL_NEEDED=$(original_extract_static_elf_needed_libraries "$REAL_SHELL" 2>/dev/null || true)
if [ -n "$REAL_SHELL_NEEDED" ]; then
    pass
else
    fail 'the production static reader should extract dependencies from /bin/sh'
fi

READELF_ARGUMENTS="$TEST_TMP/readelf-arguments.txt"
readelf() {
    printf '%s\n' "$*" > "$READELF_ARGUMENTS"
    cat <<'EOF_READELF'
 0x0000000000000001 (NEEDED)             Shared library: [libz.so.1]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
 0x0000000000000001 (NEEDED)             Shared library: [libz.so.1]
EOF_READELF
}

EXTRACTED=$(original_extract_static_elf_needed_libraries "$TEST_TMP/elf-magic")
assert_equal $'libc.so.6\nlibz.so.1' "$EXTRACTED" \
    'the static reader should normalize and deduplicate DT_NEEDED entries'
assert_equal "-d
--
$TEST_TMP/elf-magic" "$(cat "$READELF_ARGUMENTS")" \
    'readelf should receive the inspected path as data after --'

SCAN_DIR="$TEST_TMP/scan"
OUTSIDE_DIR="$TEST_TMP/outside"
mkdir -p "$SCAN_DIR" "$OUTSIDE_DIR"
EXECUTION_MARKER="$TEST_TMP/inspected-object-executed"
LDD_MARKER="$TEST_TMP/dynamic-loader-tool-used"

create_guarded_object() {
    local path=$1

    cat > "$path" <<EOF_OBJECT
#!/bin/sh
printf '%s\\n' executed >> '$EXECUTION_MARKER'
EOF_OBJECT
    chmod 755 "$path"
}

create_guarded_object "$SCAN_DIR/healthy-object"
create_guarded_object "$SCAN_DIR/broken-object"
create_guarded_object "$SCAN_DIR/prefix-object"
create_guarded_object "$SCAN_DIR/unreadable-object"
create_guarded_object "$OUTSIDE_DIR/symlink-target"
ln -s "$OUTSIDE_DIR/symlink-target" "$SCAN_DIR/linked-object"
ln -s "$OUTSIDE_DIR/missing-target" "$SCAN_DIR/dangling-object"
printf '%s\n' 'ordinary text' > "$SCAN_DIR/not-elf"

# Test doubles classify guarded scripts as ELF objects and describe their
# dependencies without invoking those scripts.
elf_file_has_static_magic() {
    case "$1" in
        "$SCAN_DIR/"*|"$OUTSIDE_DIR/"*) return 0 ;;
        *) return 1 ;;
    esac
}

STATIC_CACHE_SOURCE="$TEST_TMP/cache-source.txt"
printf '%s\n' 'libc.so.6' > "$STATIC_CACHE_SOURCE"
CACHE_REFRESH_FAIL=0
refresh_static_elf_library_cache() {
    local destination=$1

    if [ "$CACHE_REFRESH_FAIL" -eq 1 ]; then
        printf '%s\n' 'simulated cache failure' >> "$BROKEN_ERRORS"
        return 1
    fi
    cp -f -- "$STATIC_CACHE_SOURCE" "$destination"
}

extract_static_elf_needed_libraries() {
    case "$1" in
        "$SCAN_DIR/healthy-object")
            printf '%s\n' 'libc.so.6'
            ;;
        "$SCAN_DIR/broken-object")
            if [ "${REPAIR_STATE:-initial}" = repaired ]; then
                printf '%s\n' 'libc.so.6'
            else
                printf '%s\n' 'libmissing.so.1'
            fi
            ;;
        "$SCAN_DIR/prefix-object")
            printf '%s\n' 'libc.so'
            ;;
        "$SCAN_DIR/unreadable-object")
            printf '%s\n' 'simulated readelf failure' >> "$BROKEN_ERRORS"
            return 1
            ;;
        "$OUTSIDE_DIR/symlink-target")
            if [ "${REPAIR_STATE:-initial}" = repaired ]; then
                printf '%s\n' 'libc.so.6'
            else
                printf '%s\n' 'libmissing-linked.so.1'
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

ldd() {
    : > "$LDD_MARKER"
    return 99
}

ELF_SCAN_PATHS=("$SCAN_DIR")
SCAN_OUTPUT="$TEST_TMP/scan-output.txt"
if detect_broken_elf_objects > "$SCAN_OUTPUT"; then
    pass
else
    fail 'static ELF detection should complete with the deterministic test cache'
fi
assert_equal 0 "$ELF_SCAN_STATUS" \
    'a successful static scan should record status zero'
EXPECTED_SCAN=$(printf '%s\n' \
    "$SCAN_DIR/broken-object" "$SCAN_DIR/linked-object" "$SCAN_DIR/prefix-object")
assert_equal "$EXPECTED_SCAN" \
    "$(cat "$BROKEN")" \
    'static inspection should report only objects with exact unresolved sonames'
assert_file_empty "$EXECUTION_MARKER" \
    'the initial ELF scan must never execute an inspected object'
assert_file_absent "$LDD_MARKER" \
    'the initial ELF scan must not invoke a dynamic-loader tracing utility'
if grep -Fq 'readelf could not inspect' "$SCAN_OUTPUT"; then
    pass
else
    fail 'static reader failures should be reported as diagnostics'
fi
assert_file_empty "$BROKEN_ERRORS" \
    'reported static inspection diagnostics should be cleared after the scan'

printf '%s\n' "$SCAN_DIR/broken-object" "$SCAN_DIR/dangling-object" \
    "$SCAN_DIR/linked-object" "$SCAN_DIR/unreadable-object" > "$BROKEN"
REPAIR_STATE=initial
VERIFY_OUTPUT="$TEST_TMP/verify-output.txt"
if verify_broken_elf_objects_after_rebuild > "$VERIFY_OUTPUT"; then
    fail 'post-build verification should fail while dependencies remain unresolved'
else
    pass
fi
assert_equal 1 "$ELF_VERIFICATION_STATUS" \
    'unresolved or unreadable objects should record a failed verification status'
EXPECTED_VERIFY=$(printf '%s\n' \
    "$SCAN_DIR/broken-object" "$SCAN_DIR/dangling-object" \
    "$SCAN_DIR/linked-object" "$SCAN_DIR/unreadable-object")
assert_equal "$EXPECTED_VERIFY" \
    "$(cat "$BROKEN")" \
    'post-build verification should retain unresolved and uninspectable objects'
assert_file_empty "$EXECUTION_MARKER" \
    'post-build verification must never execute an inspected object'
assert_file_absent "$LDD_MARKER" \
    'post-build verification must not invoke a dynamic-loader tracing utility'

REPAIR_STATE=repaired
printf '%s\n' "$SCAN_DIR/broken-object" "$SCAN_DIR/linked-object" > "$BROKEN"
if verify_broken_elf_objects_after_rebuild >/dev/null; then
    pass
else
    fail 'post-build static verification should pass after all sonames resolve'
fi
assert_equal 0 "$ELF_VERIFICATION_STATUS" \
    'successful post-build verification should record status zero'
assert_file_empty "$BROKEN" \
    'successful post-build verification should clear the broken-object set'
assert_file_empty "$EXECUTION_MARKER" \
    'successful verification must still avoid executing inspected objects'

printf '%s\n' "$SCAN_DIR/broken-object" > "$BROKEN"
CACHE_REFRESH_FAIL=1
if verify_broken_elf_objects_after_rebuild >/dev/null; then
    fail 'post-build verification should fail closed when the library cache cannot refresh'
else
    pass
fi
assert_equal "$SCAN_DIR/broken-object" "$(cat "$BROKEN")" \
    'a cache failure should preserve the previous broken-object state'
assert_equal 1 "$ELF_VERIFICATION_STATUS" \
    'a cache refresh failure should record failed verification'
CACHE_REFRESH_FAIL=0

SOURCE_TEXT=$(cat "$REFERENCE_SCRIPT")
case "$SOURCE_TEXT" in
    *'LD_TRACE_LOADED_OBJECTS'*)
        fail 'the reference implementation must not use loader trace execution mode'
        ;;
    *)
        pass
        ;;
esac
if grep -Eq '(^|[[:space:];|&])ldd([[:space:]]|$)' "$REFERENCE_SCRIPT"; then
    fail 'the reference implementation must not invoke ldd on inspected objects'
else
    pass
fi

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
    fail 'provisional module JSON with static ELF metadata should be valid'
fi
assert_equal 'readelf+ldconfig-cache' \
    "$(jq -r '.modules.elf.inspection_method' "$JSON_MODULES")" \
    'provisional JSON should expose the static inspection method'
assert_equal false \
    "$(jq -r '.modules.elf.executes_inspected_objects' "$JSON_MODULES")" \
    'provisional JSON should state that inspected objects are never executed'
assert_equal 0 "$(jq -r '.modules.elf.scan_exit_code' "$JSON_MODULES")" \
    'provisional JSON should expose the static scan status'
assert_equal 0 "$(jq -r '.modules.elf.verification_exit_code' "$JSON_MODULES")" \
    'provisional JSON should expose the post-build verification status'

printf 'Static ELF inspection tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
