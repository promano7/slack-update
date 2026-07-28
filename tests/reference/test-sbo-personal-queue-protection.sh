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

assert_path_absent() {
    local path=$1
    local message=$2

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

PERSONAL_QUEUE_DIR="$TEST_TMP/personal queues"
mkdir -p "$PERSONAL_QUEUE_DIR/nested"
cat > "$PERSONAL_QUEUE_DIR/custom.sqf" <<'EOF_PERSONAL_MAIN'
dependency
application | FEATURE=yes
EOF_PERSONAL_MAIN
cat > "$PERSONAL_QUEUE_DIR/nested/tool.sqf" <<'EOF_PERSONAL_NESTED'
library
tool
EOF_PERSONAL_NESTED
printf '%s\n' 'not a queue' > "$PERSONAL_QUEUE_DIR/notes.txt"
ln -s custom.sqf "$PERSONAL_QUEUE_DIR/link.sqf"

SBOPKG_CONFIG="$TEST_TMP/sbopkg user's.conf"
SBO_QUEUE_DIR_FALLBACK="$TEST_TMP/fallback-queues"
LOCAL_SBOPKG_CONF="$TEST_TMP/default-local-missing.conf"
printf 'QUEUEDIR="%s"\n' "$PERSONAL_QUEUE_DIR" > "$SBOPKG_CONFIG"
SBO_TARGET_SELECTION_ERROR=
SBO_PERSONAL_QUEUE_DIR=
SBODIR=

if resolve_sbo_personal_queue_directory; then
    pass
else
    fail "a quoted absolute QUEUEDIR should resolve: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal "$PERSONAL_QUEUE_DIR" "$SBO_PERSONAL_QUEUE_DIR" \
    'the configured queue directory should be classified as personal state'
assert_equal "$PERSONAL_QUEUE_DIR" "$SBODIR" \
    'the legacy SBODIR value should retain the personal queue path'

printf 'QUEUEDIR=${QUEUEDIR:-%s}\n' "$PERSONAL_QUEUE_DIR" > "$SBOPKG_CONFIG"
if resolve_sbo_personal_queue_directory; then
    pass
else
    fail "the official default-value QUEUEDIR syntax should resolve: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal "$PERSONAL_QUEUE_DIR" "$SBO_PERSONAL_QUEUE_DIR" \
    'the official parameter-expansion syntax should expose its absolute default path'

SYSTEM_QUEUE_DIR="$TEST_TMP/system-queues"
LOCAL_OVERRIDE_CONFIG="$TEST_TMP/resolution-local.conf"
printf 'QUEUEDIR="%s"\n' "$PERSONAL_QUEUE_DIR" > "$LOCAL_OVERRIDE_CONFIG"
printf 'QUEUEDIR=${QUEUEDIR:-%s}\nLOCAL_SBOPKG_CONF="%s"\n' \
    "$SYSTEM_QUEUE_DIR" "$LOCAL_OVERRIDE_CONFIG" > "$SBOPKG_CONFIG"
if resolve_sbo_personal_queue_directory; then
    pass
else
    fail "a local sbopkg QUEUEDIR override should resolve: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal "$PERSONAL_QUEUE_DIR" "$SBO_PERSONAL_QUEUE_DIR" \
    'the local sbopkg configuration should override the system queue path'

: > "$SBOPKG_CONFIG"
if resolve_sbo_personal_queue_directory; then
    pass
else
    fail "a missing QUEUEDIR should use the fallback: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal "$SBO_QUEUE_DIR_FALLBACK" "$SBO_PERSONAL_QUEUE_DIR" \
    'the fallback queue directory should remain personal state'

printf '%s\n' 'QUEUEDIR=relative/queues' > "$SBOPKG_CONFIG"
if resolve_sbo_personal_queue_directory; then
    fail 'a relative QUEUEDIR should be rejected'
else
    pass
fi
assert_equal 'resolved SBo queue directory is not absolute: relative/queues' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'a relative QUEUEDIR should expose a stable diagnostic'

printf 'QUEUEDIR="%s"\n' "$PERSONAL_QUEUE_DIR" > "$SBOPKG_CONFIG"
PERSONAL_SNAPSHOT="$TEST_TMP/personal.snapshot"
find "$PERSONAL_QUEUE_DIR" -type f -printf '%P\0' \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' relative; do
        printf '%s\t' "$relative"
        sha256sum "$PERSONAL_QUEUE_DIR/$relative" | awk '{print $1}'
    done > "$PERSONAL_SNAPSHOT"

PRIVATE_QUEUE_DIR="$TEST_TMP/private-queues"
if prepare_private_sbo_queue_workspace "$PERSONAL_QUEUE_DIR" "$PRIVATE_QUEUE_DIR"; then
    pass
else
    fail "personal queues should be copied into a private workspace: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal "$PRIVATE_QUEUE_DIR" "$SBO_QUEUE_SOURCE_DIR" \
    'subsequent queue parsing should use the private workspace'
assert_equal 2 "$SBO_PERSONAL_QUEUE_FILE_COUNT" \
    'only regular .sqf files should be copied'
assert_equal 1 "$SBO_PERSONAL_QUEUE_SYMLINK_COUNT" \
    'personal .sqf symlinks should be counted and ignored'
assert_file_equal "$PERSONAL_QUEUE_DIR/custom.sqf" "$PRIVATE_QUEUE_DIR/custom.sqf" \
    'a top-level personal queue should be copied byte-for-byte'
assert_file_equal "$PERSONAL_QUEUE_DIR/nested/tool.sqf" "$PRIVATE_QUEUE_DIR/nested/tool.sqf" \
    'a nested personal queue should be copied byte-for-byte'
assert_path_absent "$PRIVATE_QUEUE_DIR/link.sqf" \
    'a personal queue symlink must not be reproduced in the private workspace'
assert_path_absent "$PRIVATE_QUEUE_DIR/notes.txt" \
    'non-queue files must not be copied into the private workspace'
assert_equal 700 "$(stat -c '%a' "$PRIVATE_QUEUE_DIR")" \
    'the private queue workspace should be accessible only to its owner'
assert_equal 600 "$(stat -c '%a' "$PRIVATE_QUEUE_DIR/custom.sqf")" \
    'copied queue files should be private regular files'

CURRENT_PERSONAL_SNAPSHOT="$TEST_TMP/personal-current.snapshot"
find "$PERSONAL_QUEUE_DIR" -type f -printf '%P\0' \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' relative; do
        printf '%s\t' "$relative"
        sha256sum "$PERSONAL_QUEUE_DIR/$relative" | awk '{print $1}'
    done > "$CURRENT_PERSONAL_SNAPSHOT"
assert_file_equal "$PERSONAL_SNAPSHOT" "$CURRENT_PERSONAL_SNAPSHOT" \
    'preparing the workspace must not modify personal queue contents'

SAME_DESTINATION="$PERSONAL_QUEUE_DIR"
if prepare_private_sbo_queue_workspace "$PERSONAL_QUEUE_DIR" "$SAME_DESTINATION"; then
    fail 'the personal queue directory must never be accepted as the private workspace'
else
    pass
fi
assert_equal 'private SBo queue workspace must differ from the personal queue directory' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'same-directory protection should expose a stable diagnostic'

INSIDE_DESTINATION="$PERSONAL_QUEUE_DIR/private"
if prepare_private_sbo_queue_workspace "$PERSONAL_QUEUE_DIR" "$INSIDE_DESTINATION"; then
    fail 'a workspace inside the personal queue tree should be rejected'
else
    pass
fi
assert_equal 'private SBo queue workspace must not be inside the personal queue directory' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'inside-tree protection should expose a stable diagnostic'
assert_path_absent "$INSIDE_DESTINATION" \
    'inside-tree rejection must not create any directory in personal state'

ALIASED_PARENT="$TEST_TMP/aliased-personal-parent"
ln -s "$PERSONAL_QUEUE_DIR" "$ALIASED_PARENT"
ALIASED_DESTINATION="$ALIASED_PARENT/private-generated"
if prepare_private_sbo_queue_workspace "$PERSONAL_QUEUE_DIR" "$ALIASED_DESTINATION"; then
    fail 'a workspace reaching personal state through a symlinked parent should be rejected'
else
    pass
fi
assert_equal 'private SBo queue workspace must not be inside the personal queue directory' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'canonical path protection should detect a symlinked destination parent'
assert_path_absent "$PERSONAL_QUEUE_DIR/private-generated" \
    'canonical path rejection must not create state through a symlinked parent'

SOURCE_LINK="$TEST_TMP/personal-link"
ln -s "$PERSONAL_QUEUE_DIR" "$SOURCE_LINK"
LINK_DESTINATION="$TEST_TMP/link-destination"
if prepare_private_sbo_queue_workspace "$SOURCE_LINK" "$LINK_DESTINATION"; then
    fail 'a symlinked personal queue root should be rejected'
else
    pass
fi
assert_equal "personal SBo queue path is not a real directory: $SOURCE_LINK" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'a symlinked queue root should expose a stable diagnostic'
assert_path_absent "$LINK_DESTINATION" \
    'a rejected symlinked queue root must not leave a workspace behind'

MISSING_SOURCE="$TEST_TMP/missing-personal"
EMPTY_WORKSPACE="$TEST_TMP/empty-workspace"
if prepare_private_sbo_queue_workspace "$MISSING_SOURCE" "$EMPTY_WORKSPACE"; then
    pass
else
    fail "a missing optional personal queue directory should create an empty workspace: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal 0 "$SBO_PERSONAL_QUEUE_FILE_COUNT" \
    'a missing personal queue directory should copy zero files'
assert_equal 0 "$(find "$EMPTY_WORKSPACE" -mindepth 1 -print | wc -l)" \
    'a missing personal queue directory should produce an empty workspace'

# Dry-run inspection reads personal queues directly but does not create a generator workspace.
DRY_QUEUE_CORE="$TEST_TMP/dry-core.sqf"
DRY_OPTION_RECORDS="$TEST_TMP/dry-options.normalized"
DRY_OPTIONS_FILE="$TEST_TMP/dry-options.sqf"
DRY_GENERATED_QUEUE_DIR="$TEST_TMP/dry-generated-queues"
QUEUE_CORE=$DRY_QUEUE_CORE
SBO_OPTION_RECORDS=$DRY_OPTION_RECORDS
SBO_OPTIONS_FILE=$DRY_OPTIONS_FILE
SBO_GENERATED_QUEUE_DIR=$DRY_GENERATED_QUEUE_DIR
SBO_PERSONAL_QUEUE_DIR=
SBO_QUEUE_SOURCE_DIR=
SBODIR=
: > "$DRY_OPTIONS_FILE"
if inspect_current_sbo_queues >/dev/null; then
    pass
else
    fail "dry-run queue inspection should read personal queues safely: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal "$PERSONAL_QUEUE_DIR" "$SBO_QUEUE_SOURCE_DIR"     'dry-run inspection should use the personal queue directory as a read-only source'
assert_path_absent "$DRY_GENERATED_QUEUE_DIR"     'dry-run inspection must not create or invoke a generated queue workspace'
assert_equal 1 "$(grep -Fxc application "$DRY_QUEUE_CORE")"     'dry-run inspection should retain personal queue targets'

# Integration: sqg receives only the private workspace and cannot overwrite personal files.
rm -rf "$PRIVATE_QUEUE_DIR" "$EMPTY_WORKSPACE"
SBO_GENERATED_QUEUE_DIR="$TEST_TMP/generated-queues"
SBO_QUEUE_SOURCE_DIR=
SBO_PERSONAL_QUEUE_DIR=
SBODIR=
SBOPKG_SYNC_STATUS=-1
SQG_SYNC_STATUS=-1
SBOPKG_CALL="$TEST_TMP/sbopkg.call"
SQG_CALL="$TEST_TMP/sqg.call"
SQG_ENV="$TEST_TMP/sqg.env"
SQG_CONF="$TEST_TMP/sqg.conf"
ORIGINAL_LOCAL_SBOPKG_CONFIG="$TEST_TMP/local sbopkg.conf"
printf 'QUEUEDIR="%s"\n' "$PERSONAL_QUEUE_DIR" > "$ORIGINAL_LOCAL_SBOPKG_CONFIG"
printf 'QUEUEDIR="%s"\nLOCAL_SBOPKG_CONF="%s"\n' \
    "$SYSTEM_QUEUE_DIR" "$ORIGINAL_LOCAL_SBOPKG_CONFIG" > "$SBOPKG_CONFIG"

sbopkg() {
    printf '%s\n' "$*" > "$SBOPKG_CALL"
    return 0
}

sqg() {
    printf '%s\n' "$*" > "$SQG_CALL"
    printf '%s\n' "${SBOPKG_CONF:-}" > "$SQG_CONF"
    # Mirror sqg configuration loading: system config first, local config second.
    . "$SBOPKG_CONF"
    if [ -e "$LOCAL_SBOPKG_CONF" ]; then
        . "$LOCAL_SBOPKG_CONF"
    fi
    printf '%s\n' "${QUEUEDIR:-}" > "$SQG_ENV"
    printf '%s\n' generated-dependency 'generated-application | PRIVATE=yes' > "$QUEUEDIR/custom.sqf"
    printf '%s\n' generated-new > "$QUEUEDIR/generated-new.sqf"
    return 0
}

if synchronize_sbo_repository >/dev/null; then
    pass
else
    fail 'SBo synchronization should complete with the isolated queue workspace'
fi
assert_equal 0 "$SBOPKG_SYNC_STATUS" \
    'the mocked sbopkg repository synchronization should succeed'
assert_equal 0 "$SQG_SYNC_STATUS" \
    'the mocked sqg generation should succeed'
assert_equal 1 "$SBO_QUEUE_GENERATION_READY" \
    'successful private sqg generation should authorize queue construction'
assert_equal '-r' "$(cat "$SBOPKG_CALL")" \
    'sbopkg should still receive the repository refresh action'
assert_equal '-a' "$(cat "$SQG_CALL")" \
    'sqg should still receive the all-queues generation action'
assert_equal "$SBO_PRIVATE_SBOPKG_CONFIG" "$(cat "$SQG_CONF")" \
    'sqg should receive the private wrapper instead of the personal sbopkg configuration'
assert_equal 600 "$(stat -c '%a' "$SBO_PRIVATE_SBOPKG_CONFIG")" \
    'the private system configuration wrapper should be owner-readable only'
assert_equal 600 "$(stat -c '%a' "$SBO_PRIVATE_LOCAL_SBOPKG_CONFIG")" \
    'the private local configuration wrapper should be owner-readable only'
assert_equal "$SBO_GENERATED_QUEUE_DIR" "$(cat "$SQG_ENV")" \
    'sqg must receive only the private workspace through QUEUEDIR'
assert_equal "$SBO_GENERATED_QUEUE_DIR" "$SBO_QUEUE_SOURCE_DIR" \
    'generated queues should become the only apply-time queue source'
assert_equal "$PERSONAL_QUEUE_DIR" "$SBO_PERSONAL_QUEUE_DIR" \
    'the personal queue path should remain distinct from generated state'
assert_equal $'dependency\napplication | FEATURE=yes' \
    "$(cat "$PERSONAL_QUEUE_DIR/custom.sqf")" \
    'sqg generation must not alter a personal queue with the same filename'
assert_equal $'generated-dependency\ngenerated-application | PRIVATE=yes' \
    "$(cat "$SBO_GENERATED_QUEUE_DIR/custom.sqf")" \
    'sqg should be free to replace only the private copy'
assert_file_equal "$PERSONAL_SNAPSHOT" "$CURRENT_PERSONAL_SNAPSHOT" \
    'the baseline personal snapshot file should remain available for comparison'

POST_SYNC_PERSONAL_SNAPSHOT="$TEST_TMP/personal-post-sync.snapshot"
find "$PERSONAL_QUEUE_DIR" -type f -printf '%P\0' \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' relative; do
        printf '%s\t' "$relative"
        sha256sum "$PERSONAL_QUEUE_DIR/$relative" | awk '{print $1}'
    done > "$POST_SYNC_PERSONAL_SNAPSHOT"
assert_file_equal "$PERSONAL_SNAPSHOT" "$POST_SYNC_PERSONAL_SNAPSHOT" \
    'successful sqg generation must leave every personal regular file unchanged'

QUEUE_CORE="$TEST_TMP/core.sqf"
QUEUE_EXTRA="$TEST_TMP/extra.sqf"
SBO_OPTION_RECORDS="$TEST_TMP/options.normalized"
SBO_OPTIONS_FILE="$TEST_TMP/options.sqf"
: > "$SBO_OPTIONS_FILE"
if build_sbo_core_queue >/dev/null; then
    pass
else
    fail "core queue construction should use the generated workspace: $SBO_TARGET_SELECTION_ERROR"
fi
assert_equal 1 "$(grep -Fxc generated-application "$QUEUE_CORE")" \
    'the generated workspace should feed core queue construction'
assert_equal $'generated-application\tPRIVATE=yes' \
    "$(cat "$SBO_OPTION_RECORDS")" \
    'build options should also be collected from the private generated workspace'
assert_equal 0 "$(grep -Fxc application "$QUEUE_CORE" || true)" \
    'the overwritten private copy should not fall back to the personal original'
assert_equal "$PERSONAL_QUEUE_DIR" "$SBO_PERSONAL_QUEUE_DIR" \
    'queue parsing should retain the protected personal-directory metadata'
assert_equal "$SBO_GENERATED_QUEUE_DIR" "$SBO_QUEUE_SOURCE_DIR" \
    'option collection should retain the private apply-time queue source'
assert_equal 2 "$SBO_PERSONAL_QUEUE_FILE_COUNT" \
    'queue parsing should retain the copied personal-file count'
assert_equal 1 "$SBO_PERSONAL_QUEUE_SYMLINK_COUNT" \
    'queue parsing should retain the ignored-symlink count'

# A failing sqg command still operates only on a disposable private copy.
rm -rf "$SBO_GENERATED_QUEUE_DIR"
SBO_GENERATED_QUEUE_DIR="$TEST_TMP/generated-failure"
SBO_QUEUE_SOURCE_DIR=
SBO_PERSONAL_QUEUE_DIR=
SBODIR=
SBOPKG_SYNC_STATUS=-1
SQG_SYNC_STATUS=-1

sqg() {
    . "$SBOPKG_CONF"
    if [ -e "$LOCAL_SBOPKG_CONF" ]; then
        . "$LOCAL_SBOPKG_CONF"
    fi
    printf '%s\n' failed-private-content > "$QUEUEDIR/custom.sqf"
    return 17
}

if synchronize_sbo_repository >/dev/null; then
    pass
else
    fail 'the synchronization wrapper should report command statuses through state variables'
fi
assert_equal 17 "$SQG_SYNC_STATUS" \
    'a failing sqg command should preserve its raw exit status'
assert_equal 0 "$SBO_QUEUE_GENERATION_READY" \
    'failed private sqg generation must not authorize queue construction'
assert_equal 'sqg queue generation failed in the private workspace with exit code 17' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'failed private sqg generation should expose a stable blocking diagnostic'
assert_equal failed-private-content "$(cat "$SBO_GENERATED_QUEUE_DIR/custom.sqf")" \
    'a failed sqg command may only damage the disposable private copy'
POST_FAILURE_PERSONAL_SNAPSHOT="$TEST_TMP/personal-post-failure.snapshot"
find "$PERSONAL_QUEUE_DIR" -type f -printf '%P\0' \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' relative; do
        printf '%s\t' "$relative"
        sha256sum "$PERSONAL_QUEUE_DIR/$relative" | awk '{print $1}'
    done > "$POST_FAILURE_PERSONAL_SNAPSHOT"
assert_file_equal "$PERSONAL_SNAPSHOT" "$POST_FAILURE_PERSONAL_SNAPSHOT" \
    'failed sqg generation must also leave personal queues unchanged'

# A pre-existing workspace fails closed before sqg is called.
rm -rf "$SBO_GENERATED_QUEUE_DIR"
SBO_GENERATED_QUEUE_DIR="$TEST_TMP/existing-workspace"
mkdir "$SBO_GENERATED_QUEUE_DIR"
SBO_QUEUE_SOURCE_DIR=
SBO_PERSONAL_QUEUE_DIR=
SBODIR=
SBO_GENERATED_QUEUE_OWNED_PATH=
SBO_GENERATED_QUEUE_OWNED_CANONICAL=
SQG_SYNC_STATUS=-1
SQG_INVOCATIONS=0
sqg() {
    SQG_INVOCATIONS=$((SQG_INVOCATIONS + 1))
    return 0
}

if synchronize_sbo_repository >/dev/null; then
    pass
else
    fail 'workspace preparation failures should be represented by SQG_SYNC_STATUS'
fi
assert_equal 1 "$SQG_SYNC_STATUS" \
    'an unsafe pre-existing workspace should fail queue generation'
assert_equal 0 "$SBO_QUEUE_GENERATION_READY" \
    'workspace preparation failure must not authorize queue construction'
assert_equal 0 "$SQG_INVOCATIONS" \
    'sqg must not run when a private workspace cannot be prepared safely'
assert_equal "private SBo queue workspace already exists: $SBO_GENERATED_QUEUE_DIR" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'pre-existing workspace rejection should expose a stable diagnostic'

RUNTIME_TMPDIR=
QUEUE_FINAL=
BROKEN_NEW=
STILL_BROKEN=
BROKEN_ERRORS=
cleanup
if [ -d "$SBO_GENERATED_QUEUE_DIR" ]; then
    pass
else
    fail 'cleanup must not remove a pre-existing workspace that Slack-Update did not create'
fi
rm -rf "$SBO_GENERATED_QUEUE_DIR"

CLEANUP_WORKSPACE="$TEST_TMP/cleanup-workspace"
CLEANUP_SOURCE="$TEST_TMP/cleanup-source-missing"
if prepare_private_sbo_queue_workspace "$CLEANUP_SOURCE" "$CLEANUP_WORKSPACE"; then
    pass
else
    fail "a cleanup fixture workspace should be created safely: $SBO_TARGET_SELECTION_ERROR"
fi
SBO_GENERATED_QUEUE_DIR=$CLEANUP_WORKSPACE
cleanup
assert_path_absent "$CLEANUP_WORKSPACE" \
    'normal cleanup should remove a disposable workspace owned by Slack-Update'

SWAPPED_WORKSPACE="$TEST_TMP/swapped-workspace"
SWAPPED_TARGET="$TEST_TMP/swapped-target"
mkdir "$SWAPPED_TARGET"
printf '%s\n' protected > "$SWAPPED_TARGET/keep.txt"
if prepare_private_sbo_queue_workspace "$CLEANUP_SOURCE" "$SWAPPED_WORKSPACE"; then
    pass
else
    fail "a symlink-swap fixture workspace should be created safely: $SBO_TARGET_SELECTION_ERROR"
fi
rm -rf "$SWAPPED_WORKSPACE"
ln -s "$SWAPPED_TARGET" "$SWAPPED_WORKSPACE"
SBO_GENERATED_QUEUE_DIR=$SWAPPED_WORKSPACE
cleanup
assert_equal protected "$(cat "$SWAPPED_TARGET/keep.txt")" \
    'cleanup must not follow a replaced workspace symlink into unrelated state'
if [ -L "$SWAPPED_WORKSPACE" ]; then
    pass
else
    fail 'cleanup should leave an untrusted replacement symlink untouched'
fi
rm -f "$SWAPPED_WORKSPACE"

SBO_QUEUE_GENERATION_READY=0
SBO_TARGET_SELECTION_ERROR=
CORE_BUILD_INVOCATIONS=0
EXTRA_BUILD_INVOCATIONS=0
build_sbo_core_queue() {
    CORE_BUILD_INVOCATIONS=$((CORE_BUILD_INVOCATIONS + 1))
    return 0
}
add_abi_rebuild_targets() {
    EXTRA_BUILD_INVOCATIONS=$((EXTRA_BUILD_INVOCATIONS + 1))
    return 0
}
if build_sbo_target_queues_after_synchronization; then
    fail 'queue construction should be blocked when private generation is incomplete'
else
    pass
fi
assert_equal 0 "$CORE_BUILD_INVOCATIONS" \
    'blocked private generation must not invoke core queue construction'
assert_equal 0 "$EXTRA_BUILD_INVOCATIONS" \
    'blocked private generation must not invoke ABI queue construction'
assert_equal 'private SBo queue generation did not complete successfully' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'blocked queue construction should expose a stable diagnostic'

# Provisional apply JSON exposes the isolation boundary without leaking queue contents.
if command -v jq >/dev/null 2>&1; then
    initialize_runtime_state
    PACKAGE_SNAPSHOT_BEFORE_VALID=1
    PACKAGE_SNAPSHOT_AFTER_VALID=1
    SLACKPKG_UPDATE_STATUS=0
    SLACKPKG_INSTALL_NEW_STATUS=0
    SLACKPKG_UPGRADE_ALL_STATUS=0
    FLATPAK_MODE=auto
    FLATPAK_MODULE_RUN=0
    FLATPAK_MODULE_STATE=skipped
    FLATPAK_MODULE_REASON='not applicable'
    FLATPAK_STATUS=-1
    SBO_MODE=enabled
    SBO_MODULE_RUN=1
    SBO_MODULE_STATE=active
    SBO_MODULE_REASON='requirements available'
    SBOPKG_SYNC_STATUS=0
    SQG_SYNC_STATUS=0
    SBO_TARGET_SELECTION_STATUS=0
    SBO_BUILD_STATUS=0
    SBO_PERSONAL_QUEUE_DIR=$PERSONAL_QUEUE_DIR
    SBO_GENERATED_QUEUE_DIR=$TEST_TMP/json-private-workspace
    SBO_PERSONAL_QUEUE_FILE_COUNT=2
    SBO_PERSONAL_QUEUE_SYMLINK_COUNT=1
    SBO_QUEUE_GENERATION_READY=1
    SBO_OPTIONS_FILE=$TEST_TMP/options.sqf
    SBO_OPTION_RECORD_COUNT=0
    SBO_OPTION_RECORDS=$TEST_TMP/json-options
    : > "$SBO_OPTION_RECORDS"
    TOTAL_CORE=2
    TOTAL_EXTRA=0
    TOTAL_EN_COLA=2
    ELF_MODE=auto
    ELF_MODULE_RUN=0
    ELF_MODULE_STATE=skipped
    ELF_MODULE_REASON='not applicable'
    BROKEN=$TEST_TMP/json-broken
    : > "$BROKEN"
    CINNAMON_MODE=auto
    CINNAMON_MODULE_RUN=0
    CINNAMON_MODULE_STATE=skipped
    CINNAMON_MODULE_REASON='not applicable'
    CINNAMON_TRIGGER=0
    INITRD_REQUIRED=0
    GRUB_REQUIRED=0
    BOOT_MODE=auto
    BOOT_MODULE_STATE=skipped
    BOOT_MODULE_REASON='not applicable'
    SECONDARY_MODULES_BLOCKED=0
    SECONDARY_MODULES_BLOCK_REASON=
    ABI_TRIGGER=0
    KERNEL_TRIGGER=0
    CRITICAL_UPDATED=()

    APPLY_MODULES_JSON="$TEST_TMP/apply-modules.json"
    {
        printf '{\n'
        print_apply_json_modules
        printf '}\n'
    } > "$APPLY_MODULES_JSON"

    if jq -e . "$APPLY_MODULES_JSON" >/dev/null; then
        pass
    else
        fail 'the apply module output should remain valid JSON'
    fi
    assert_equal "$PERSONAL_QUEUE_DIR" \
        "$(jq -r '.sbo.personal_queue_directory' "$APPLY_MODULES_JSON")" \
        'apply JSON should identify the protected personal queue directory'
    assert_equal "$TEST_TMP/json-private-workspace" \
        "$(jq -r '.sbo.generated_queue_workspace' "$APPLY_MODULES_JSON")" \
        'apply JSON should identify the disposable generated queue workspace'
    assert_equal true \
        "$(jq -r '.sbo.queue_workspace_isolated' "$APPLY_MODULES_JSON")" \
        'apply JSON should explicitly report queue workspace isolation'
    assert_equal true \
        "$(jq -r '.sbo.private_queue_generation_ready' "$APPLY_MODULES_JSON")" \
        'apply JSON should report successful private queue generation'
    assert_equal 2 \
        "$(jq -r '.sbo.personal_queue_files_copied' "$APPLY_MODULES_JSON")" \
        'apply JSON should report copied regular personal queue files'
    assert_equal 1 \
        "$(jq -r '.sbo.personal_queue_symlinks_ignored' "$APPLY_MODULES_JSON")" \
        'apply JSON should report ignored personal queue symlinks'
fi

printf 'SBo personal-queue protection tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"

[ "$FAILURE_COUNT" -eq 0 ]
