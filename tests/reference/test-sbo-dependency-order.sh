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

assert_file_equal() {
    local expected=$1
    local actual=$2
    local message=$3

    if cmp -s "$expected" "$actual"; then
        pass
    else
        fail "$message"
        diff -u "$expected" "$actual" >&2 || true
    fi
}

assert_file_empty() {
    local path=$1
    local message=$2

    if [ -f "$path" ] && [ ! -s "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

CONSTRAINTS="$TEST_TMP/constraints"
: > "$CONSTRAINTS"
if append_sbo_queue_constraints_from_stream "$CONSTRAINTS" <<'EOF_QUEUE'; then
z-dependency
# comment
@recursive
-disabled
a-application | FEATURE=yes
EOF_QUEUE
    pass
else
    fail 'valid queue records should produce dependency constraints'
fi
assert_equal $'N\tz-dependency\nN\ta-application\nE\tz-dependency\ta-application' \
    "$(cat "$CONSTRAINTS")" \
    'queue constraints should preserve active record order while skipping controls'

ORDERED_FROM_GRAPH="$TEST_TMP/ordered-from-graph"
if order_sbo_queue_graph < "$CONSTRAINTS" > "$ORDERED_FROM_GRAPH"; then
    pass
else
    fail 'an acyclic queue graph should be ordered successfully'
fi
assert_equal $'z-dependency\na-application' "$(cat "$ORDERED_FROM_GRAPH")" \
    'dependency order must override alphabetical target order'

QUEUE_DIR_A="$TEST_TMP/queues-a"
QUEUE_DIR_B="$TEST_TMP/queues-b"
mkdir -p "$QUEUE_DIR_A/nested" "$QUEUE_DIR_B/other"

cat > "$QUEUE_DIR_A/z-application.sqf" <<'EOF_QUEUE_A1'
z-dependency
m-library | TESTS=no
a-application
EOF_QUEUE_A1
cat > "$QUEUE_DIR_A/nested/a-tool.sqf" <<'EOF_QUEUE_A2'
# generated queue
z-dependency
b-library
@ignored-reference
-disabled-target
y-tool
EOF_QUEUE_A2

cat > "$QUEUE_DIR_B/other/first.sqf" <<'EOF_QUEUE_B1'
z-dependency
b-library
@ignored-reference
-disabled-target
y-tool
EOF_QUEUE_B1
cat > "$QUEUE_DIR_B/second.sqf" <<'EOF_QUEUE_B2'
z-dependency
m-library | TESTS=no
a-application
EOF_QUEUE_B2

EXPECTED_ORDER="$TEST_TMP/expected-order"
cat > "$EXPECTED_ORDER" <<'EOF_EXPECTED'
z-dependency
b-library
m-library
a-application
y-tool
EOF_EXPECTED

ORDERED_A="$TEST_TMP/ordered-a"
ORDERED_B="$TEST_TMP/ordered-b"
if collect_ordered_sbo_targets_from_queue_directory "$QUEUE_DIR_A" "$ORDERED_A"; then
    pass
else
    fail "first dependency-ordered queue failed: $SBO_TARGET_SELECTION_ERROR"
fi
if collect_ordered_sbo_targets_from_queue_directory "$QUEUE_DIR_B" "$ORDERED_B"; then
    pass
else
    fail "second dependency-ordered queue failed: $SBO_TARGET_SELECTION_ERROR"
fi
assert_file_equal "$EXPECTED_ORDER" "$ORDERED_A" \
    'the combined queue should satisfy every generated dependency constraint'
assert_file_equal "$ORDERED_A" "$ORDERED_B" \
    'dependency ordering must not depend on queue file names or creation order'
assert_equal 1 "$(grep -Fxc z-dependency "$ORDERED_A")" \
    'a dependency shared by multiple queues should appear once'
assert_equal 1 "$(grep -Fxc a-application "$ORDERED_A")" \
    'each selected application should appear once'
assert_equal 0 "$(grep -Evc '^[A-Za-z0-9_+.-]+$' "$ORDERED_A")" \
    'the ordered queue should contain only canonical target names'

MISSING_ORDER="$TEST_TMP/missing-order"
if collect_ordered_sbo_targets_from_queue_directory \
    "$TEST_TMP/no-such-directory" "$MISSING_ORDER"; then
    pass
else
    fail 'a missing optional queue directory should produce an empty ordered queue'
fi
assert_file_empty "$MISSING_ORDER" \
    'a missing optional queue directory should install an empty ordered queue'

CYCLE_DIR="$TEST_TMP/cycle"
mkdir -p "$CYCLE_DIR"
printf '%s\n' alpha beta > "$CYCLE_DIR/alpha.sqf"
printf '%s\n' beta alpha > "$CYCLE_DIR/beta.sqf"
ATOMIC_ORDER="$TEST_TMP/atomic-order"
printf '%s\n' preserved > "$ATOMIC_ORDER"
if collect_ordered_sbo_targets_from_queue_directory "$CYCLE_DIR" "$ATOMIC_ORDER"; then
    fail 'cyclic dependency constraints should be rejected'
else
    pass
fi
assert_equal preserved "$(cat "$ATOMIC_ORDER")" \
    'a cyclic dependency failure must preserve the previous ordered queue'
assert_equal "SBo queue dependency order is cyclic or contradictory in: $CYCLE_DIR" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'a cyclic dependency failure should expose a stable diagnostic'

INVALID_DIR="$TEST_TMP/invalid"
mkdir -p "$INVALID_DIR"
printf '%s\n' '../escape' > "$INVALID_DIR/invalid.sqf"
printf '%s\n' preserved > "$ATOMIC_ORDER"
if collect_ordered_sbo_targets_from_queue_directory "$INVALID_DIR" "$ATOMIC_ORDER"; then
    fail 'an unsafe target should reject dependency ordering'
else
    pass
fi
assert_equal preserved "$(cat "$ATOMIC_ORDER")" \
    'an invalid target must not replace the previous ordered queue'
assert_equal "queue contains an invalid SBo target: $INVALID_DIR/invalid.sqf" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'an invalid ordered queue should expose its source file'

CORE_QUEUE="$TEST_TMP/core-queue"
EXTRA_A="$TEST_TMP/extra-a"
EXTRA_B="$TEST_TMP/extra-b"
FINAL_QUEUE="$TEST_TMP/final-queue"
OPTION_RECORDS="$TEST_TMP/option-records"
: > "$OPTION_RECORDS"
printf '%s\n' z-dependency b-library m-library a-application y-tool > "$CORE_QUEUE"
printf '%s\n' z-extra a-application alpha-extra > "$EXTRA_A"
printf '%s\n' beta-extra alpha-extra > "$EXTRA_B"
if merge_ordered_sbo_queue_with_target_sets \
    "$FINAL_QUEUE" "$CORE_QUEUE" "$OPTION_RECORDS" "$EXTRA_A" "$EXTRA_B"; then
    pass
else
    fail 'ordered core and deterministic extra targets should merge successfully'
fi
assert_equal $'z-dependency\nb-library\nm-library\na-application\ny-tool\nalpha-extra\nbeta-extra\nz-extra' \
    "$(cat "$FINAL_QUEUE")" \
    'final queue merging should preserve core order and append sorted unique extras'
assert_equal 1 "$(grep -Fxc a-application "$FINAL_QUEUE")" \
    'an extra target already present in the ordered core should not be duplicated'

printf '%s\n' '../escape' > "$CORE_QUEUE"
printf '%s\n' preserved > "$FINAL_QUEUE"
if merge_ordered_sbo_queue_with_target_sets \
    "$FINAL_QUEUE" "$CORE_QUEUE" "$OPTION_RECORDS" "$EXTRA_A"; then
    fail 'an unsafe ordered core should block final queue construction'
else
    pass
fi
assert_equal preserved "$(cat "$FINAL_QUEUE")" \
    'failed final queue construction must preserve the previous queue'

SBOPKG_CONFIG="$TEST_TMP/sbopkg.conf"
SBO_QUEUE_DIR_FALLBACK="$TEST_TMP/fallback"
printf 'QUEUEDIR="%s"\n' "$QUEUE_DIR_A" > "$SBOPKG_CONFIG"
QUEUE_CORE="$TEST_TMP/integration-core"
QUEUE_EXTRA="$TEST_TMP/integration-extra"
QUEUE_FINAL="$TEST_TMP/integration-final"
SBO_OPTION_RECORDS="$TEST_TMP/integration-options-normalized"
SBO_OPTIONS_FILE="$TEST_TMP/integration-options.sqf"
: > "$SBO_OPTIONS_FILE"
BROKEN="$TEST_TMP/integration-broken"
STILL_BROKEN="$TEST_TMP/integration-still-broken"
LOG="$TEST_TMP/integration.log"
: > "$QUEUE_EXTRA"
: > "$BROKEN"
TOTAL_CORE=0
TOTAL_EN_COLA=0
SBO_BUILD_STATUS=-1
SBO_CALL="$TEST_TMP/sbopkg-call"

sbopkg() {
    printf '%s\n' "$*" > "$SBO_CALL"
    return 0
}

if build_sbo_core_queue >/dev/null; then
    pass
else
    fail "the apply workflow should build an ordered core queue: $SBO_TARGET_SELECTION_ERROR"
fi
assert_file_equal "$EXPECTED_ORDER" "$QUEUE_CORE" \
    'the apply core queue should use dependency ordering rather than alphabetical sorting'
assert_equal 5 "$TOTAL_CORE" \
    'the apply workflow should report the dependency-ordered core count'

printf '%s\n' extra-target b-library > "$QUEUE_EXTRA"
if build_and_apply_sbo_queue >/dev/null; then
    pass
else
    fail "the final dependency-ordered queue should be submitted: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal $'z-dependency\nb-library\nm-library | TESTS=no\na-application\ny-tool\nextra-target' \
    "$(cat "$QUEUE_FINAL")" \
    'the submitted queue should retain dependency order and append unique extras'
assert_equal 6 "$TOTAL_EN_COLA" \
    'the submitted queue count should match the ordered final queue'
assert_equal "-b
-B
$QUEUE_FINAL" "$(cat "$SBO_CALL")" \
    'sbopkg should receive the dependency-ordered queue through -B'
assert_equal 0 "$SBO_BUILD_STATUS" \
    'successful ordered queue submission should record status zero'

printf 'SBo dependency-order tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
