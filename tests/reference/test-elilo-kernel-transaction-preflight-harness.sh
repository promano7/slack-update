#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-kernel-transaction-preflight.sh"

# Source helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-elilo-kernel-transaction-preflight.sh
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

assert_contains 'never changes packages' "$ACCEPTANCE_SCRIPT" \
    'usage should state that the transaction preflight is non-destructive'
assert_contains 'slackpkg -dialog=off -batch=on -default_answer=y update' "$ACCEPTANCE_SCRIPT" \
    'metadata refresh should be explicit and non-interactive'
assert_not_contains 'slackpkg -dialog=off -batch=on -default_answer=y upgrade' "$ACCEPTANCE_SCRIPT" \
    'the transaction preflight must not upgrade packages'
assert_not_contains 'mkinitrd -c' "$ACCEPTANCE_SCRIPT" \
    'the transaction preflight must not invoke mkinitrd'
assert_not_contains 'eliloconfig ' "$ACCEPTANCE_SCRIPT" \
    'the transaction preflight must not invoke eliloconfig'
assert_not_contains 'efibootmgr -' "$ACCEPTANCE_SCRIPT" \
    'the transaction preflight must not modify firmware variables'
assert_not_contains 'eval ' "$ACCEPTANCE_SCRIPT" \
    'the transaction preflight must not evaluate generated commands'
assert_contains 'activation_boundary=atomic-elilo.conf-replacement-after-new-files-verify' "$ACCEPTANCE_SCRIPT" \
    'the plan should activate through an atomic ELILO configuration switch'
assert_contains 'rollback_boundary=retain-current-vmlinuz-initrd-and-original-elilo.conf' "$ACCEPTANCE_SCRIPT" \
    'the plan should preserve the current boot artifacts for rollback'
assert_contains 'eliloconfig_policy=not-used-existing-efi-entry-and-loader-remain-unchanged' "$ACCEPTANCE_SCRIPT" \
    'the plan should preserve the existing ELILO binary and firmware entry'
assert_contains 'owner=${SUDO_USER:-promano}' "$ACCEPTANCE_SCRIPT" \
    'the copy command should default to promano'
assert_contains 'Copy evidence command:' "$ACCEPTANCE_SCRIPT" \
    'the preflight should print the one-line evidence copy command'
assert_contains 'find -H "$database"' "$ACCEPTANCE_SCRIPT" \
    'package enumeration should follow the Slackware compatibility symlink'
assert_contains 'PKGLIST=/var/lib/slackpkg/pkglist' "$ACCEPTANCE_SCRIPT" \
    'the repository candidate source should be explicit'
assert_contains 'kernel-generic,kernel-huge,kernel-modules' "$ACCEPTANCE_SCRIPT" \
    'the transaction plan should be limited to the three deferred packages'
assert_contains 'apply_authorized=false' "$ACCEPTANCE_SCRIPT" \
    'the generated plan must not authorize apply'

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

assert_success 'a normal kernel release should be accepted' \
    is_safe_kernel_version 5.15.209
assert_success 'a release with a local suffix should be accepted' \
    is_safe_kernel_version 5.15.209-custom+1
assert_failure 'an empty release should be rejected' \
    is_safe_kernel_version ''
assert_failure 'a release containing a slash should be rejected' \
    is_safe_kernel_version ../5.15.209
assert_failure 'a hidden release should be rejected' \
    is_safe_kernel_version .5.15.209
assert_success '5.15.209 should be newer than 5.15.19' \
    version_is_newer 5.15.19 5.15.209
assert_failure 'equal releases should not be newer' \
    version_is_newer 5.15.209 5.15.209
assert_failure 'an older release should not be newer' \
    version_is_newer 5.15.209 5.15.19

ELILO_FIXTURE="$TMP/elilo.conf"
cat > "$ELILO_FIXTURE" <<'EOF_CONFIG'
prompt
chooser=simple
message=message.txt
image=vmlinuz
        label=vmlinuz
        initrd=initrd.gz
        append="root=/dev/sda2 vga=normal ro"
EOF_CONFIG
assert_equal vmlinuz "$(read_elilo_assignment_from "$ELILO_FIXTURE" image)" \
    'the active image basename should be parsed'
assert_equal initrd.gz "$(read_elilo_assignment_from "$ELILO_FIXTURE" initrd)" \
    'the active initrd basename should be parsed'
assert_success 'the planned ELILO configuration should be generated' \
    write_planned_elilo_config "$ELILO_FIXTURE" "$TMP/elilo.conf.planned" \
        vmlinuz-generic-5.15.209 initrd-generic-5.15.209.gz
assert_equal vmlinuz-generic-5.15.209 \
    "$(read_elilo_assignment_from "$TMP/elilo.conf.planned" image)" \
    'the planned image should be versioned'
assert_equal initrd-generic-5.15.209.gz \
    "$(read_elilo_assignment_from "$TMP/elilo.conf.planned" initrd)" \
    'the planned initrd should be versioned'
assert_contains 'append="root=/dev/sda2 vga=normal ro"' "$TMP/elilo.conf.planned" \
    'unrelated ELILO settings should be preserved'
assert_contains 'message=message.txt' "$TMP/elilo.conf.planned" \
    'top-level ELILO settings should be preserved'
printf 'image=vmlinuz\nimage=other\ninitrd=initrd.gz\n' > "$TMP/elilo.duplicate"
assert_failure 'duplicate image assignments should block planned config generation' \
    write_planned_elilo_config "$TMP/elilo.duplicate" "$TMP/elilo.invalid" new-kernel new-initrd

PACKAGES="$TMP/packages"
mkdir -p "$PACKAGES"
touch "$PACKAGES/kernel-generic-5.15.19-x86_64-2"
touch "$PACKAGES/kernel-huge-5.15.19-x86_64-2"
touch "$PACKAGES/kernel-modules-5.15.19-x86_64-2"
assert_success 'installed kernel records should resolve exactly' \
    capture_installed_kernel_records "$PACKAGES" "$TMP/installed.tsv"
assert_equal 3 "$(wc -l < "$TMP/installed.tsv" | tr -d '[:space:]')" \
    'three installed boot-kernel records should be emitted'
assert_contains $'kernel-generic\t5.15.19\tx86_64\t2' "$TMP/installed.tsv" \
    'the generic installed record should be parsed right-to-left'
touch "$PACKAGES/kernel-generic-5.15.18-x86_64-1"
assert_failure 'duplicate installed generic records should be rejected' \
    capture_installed_kernel_records "$PACKAGES" "$TMP/installed-duplicate.tsv"
rm -f "$PACKAGES/kernel-generic-5.15.18-x86_64-1"

PKGLIST_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/pkglist-kernel-candidates.tsv"
assert_success 'the common patches kernel candidate should resolve' \
    resolve_repository_kernel_candidate "$PKGLIST_FIXTURE" "$TMP/installed.tsv" \
        "$TMP/all.tsv" "$TMP/selected.tsv" "$TMP/candidate-summary.txt"
assert_equal patches "$(read_summary_value repository "$TMP/candidate-summary.txt")" \
    'the patches repository should take precedence'
assert_equal 5.15.209 "$(read_summary_value version "$TMP/candidate-summary.txt")" \
    'the common target version should be selected'
assert_equal 1 "$(read_summary_value build "$TMP/candidate-summary.txt")" \
    'the common target build should be selected'
assert_equal 3 "$(wc -l < "$TMP/selected.tsv" | tr -d '[:space:]')" \
    'exactly three selected package records should be emitted'
assert_contains $'patches\tkernel-generic\t5.15.209\tx86_64\t1' "$TMP/selected.tsv" \
    'the selected set should include kernel-generic'
assert_contains $'patches\tkernel-huge\t5.15.209\tx86_64\t1' "$TMP/selected.tsv" \
    'the selected set should include kernel-huge'
assert_contains $'patches\tkernel-modules\t5.15.209\tx86_64\t1' "$TMP/selected.tsv" \
    'the selected set should include kernel-modules'

awk '$2 != "kernel-modules" || $3 != "5.15.209"' "$PKGLIST_FIXTURE" > "$TMP/pkglist-missing"
assert_failure 'a missing member of the common candidate should be rejected' \
    resolve_repository_kernel_candidate "$TMP/pkglist-missing" "$TMP/installed.tsv" \
        "$TMP/all-missing.tsv" "$TMP/selected-missing.tsv" "$TMP/summary-missing.txt"
cat "$PKGLIST_FIXTURE" > "$TMP/pkglist-ambiguous"
printf '%s\n' \
    'patches kernel-generic 5.15.210 x86_64 1 kernel-generic-5.15.210-x86_64-1 ./patches/packages' \
    'patches kernel-huge 5.15.210 x86_64 1 kernel-huge-5.15.210-x86_64-1 ./patches/packages' \
    'patches kernel-modules 5.15.210 x86_64 1 kernel-modules-5.15.210-x86_64-1 ./patches/packages' \
    >> "$TMP/pkglist-ambiguous"
assert_failure 'multiple complete patches candidates should be rejected' \
    resolve_repository_kernel_candidate "$TMP/pkglist-ambiguous" "$TMP/installed.tsv" \
        "$TMP/all-ambiguous.tsv" "$TMP/selected-ambiguous.tsv" "$TMP/summary-ambiguous.txt"

SOURCE_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-source-accepted.json"
assert_success 'the accepted ELILO source fixture should be valid JSON' \
    python3 -m json.tool "$SOURCE_FIXTURE"
assert_contains '"archive_sha256": "0eb55c3bda5a4167f4ef9fc19aede6e2029985d5dd325416e78e00ba85d57480"' \
    "$SOURCE_FIXTURE" 'the accepted source fixture should preserve the evidence digest'
assert_contains '"kernel_source": "/boot/vmlinuz-generic-5.15.19"' "$SOURCE_FIXTURE" \
    'the accepted source fixture should preserve the unique versioned source'
assert_contains '"passes": 20' "$SOURCE_FIXTURE" \
    'the accepted source fixture should preserve all real-system passes'
assert_contains '"failures": 0' "$SOURCE_FIXTURE" \
    'the accepted source fixture should preserve the zero-failure result'
assert_contains '"apply_authorized": false' "$SOURCE_FIXTURE" \
    'the accepted source fixture should retain the no-apply boundary'

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'the acceptance script should pass bash -n'

printf 'ELILO kernel transaction preflight harness: %d checks, %d failures\n' \
    "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
