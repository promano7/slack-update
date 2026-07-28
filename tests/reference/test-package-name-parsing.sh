#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "$TEST_DIR/../.." && pwd)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/slackware-package-records.tsv"

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

assert_parse_success() {
    local input=$1
    local expected_name=$2
    local expected_version=$3
    local expected_arch=$4
    local expected_build=$5

    if ! parse_slackware_package_record "$input"; then
        fail "valid package record was rejected: $input"
        return
    fi

    assert_equal "$expected_name" "$SLACKWARE_PACKAGE_NAME" "package name mismatch for $input"
    assert_equal "$expected_version" "$SLACKWARE_PACKAGE_VERSION" "version mismatch for $input"
    assert_equal "$expected_arch" "$SLACKWARE_PACKAGE_ARCH" "architecture mismatch for $input"
    assert_equal "$expected_build" "$SLACKWARE_PACKAGE_BUILD" "build mismatch for $input"
    assert_equal \
        "${expected_name}-${expected_version}-${expected_arch}-${expected_build}" \
        "$SLACKWARE_PACKAGE_RECORD" \
        "normalized record mismatch for $input"
}

assert_parse_failure() {
    local input=$1

    if parse_slackware_package_record "$input"; then
        fail "invalid package record was accepted: $input"
    else
        pass
    fi
}

while IFS=$'\t' read -r input expected_name expected_version expected_arch expected_build; do
    case "$input" in
        ''|'#'*) continue ;;
    esac
    assert_parse_success "$input" "$expected_name" "$expected_version" "$expected_arch" "$expected_build"
done < "$FIXTURE"

for invalid_record in \
    '' \
    'package' \
    'package-1.0' \
    'package-1.0-x86_64' \
    '-1.0-x86_64-1' \
    'package--x86_64-1' \
    'package-1.0--1' \
    'package-1.0-x86_64-' \
    'package name-1.0-x86_64-1'
do
    assert_parse_failure "$invalid_record"
done

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
snapshot=$TEST_TMP/snapshot
cat > "$snapshot" <<'EOF_SNAPSHOT'
gtk+3-3.24.49-x86_64-1
openssl-3.5.1-x86_64-1
openssl-3.5.2-x86_64-1
openssl-solibs-3.5.2-x86_64-1
openssl11-1.1.1w-x86_64-1
EOF_SNAPSHOT

actual=$(package_snapshot_records_for_name "$snapshot" openssl)
expected=$'openssl-3.5.1-x86_64-1\nopenssl-3.5.2-x86_64-1'
assert_equal "$expected" "$actual" "snapshot matching must not include similarly prefixed names"

actual=$(package_snapshot_records_for_name "$snapshot" 'gtk+3')
assert_equal 'gtk+3-3.24.49-x86_64-1' "$actual" "snapshot matching must treat package names literally"

sbo_records=$'normal-package-1.0-x86_64-1\n/var/lib/pkgtools/packages/real-sbo-package-2.0-x86_64-3_SBo\nname_SBo-2.0-x86_64-3\nversion-tag-2.0_SBo-x86_64-3\nwrong-suffix-2.0-x86_64-3_SBo_debug'
actual=$(printf '%s\n' "$sbo_records" | package_names_with_build_suffix_from_stream '_SBo')
assert_equal 'real-sbo-package' "$actual" "SBo detection must inspect only the build suffix"

if slackware_package_record_has_build_suffix 'real-sbo-package-2.0-x86_64-3_SBo' '_SBo'; then
    pass
else
    fail "valid SBo build suffix was not detected"
fi

if slackware_package_record_has_build_suffix 'name_SBo-2.0-x86_64-3' '_SBo'; then
    fail "package-name text was mistaken for an SBo build suffix"
else
    pass
fi

PACKAGE_DATABASE=$TEST_TMP/packages
mkdir -p "$PACKAGE_DATABASE"
: > "$PACKAGE_DATABASE/cinnamon-control-center-6.4.0-x86_64-1"
: > "$PACKAGE_DATABASE/cinnamon-menus-6.4.0-x86_64-1"
if package_database_contains_name cinnamon; then
    fail "similarly prefixed Cinnamon packages were mistaken for the cinnamon package"
else
    pass
fi

: > "$PACKAGE_DATABASE/cinnamon-6.4.0-x86_64-1"
if package_database_contains_name cinnamon; then
    pass
else
    fail "the exact cinnamon package name was not detected"
fi

printf 'Package parsing tests: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
