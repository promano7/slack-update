#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-retention-preflight.sh"

# Source helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-elilo-oldkernel-retention-preflight.sh
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
assert_not_matches() {
    local pattern=$1 path=$2 message=$3
    grep -Eq -- "$pattern" "$path" && fail "$message" || pass
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_contains 'non-destructive retention and cleanup-eligibility preflight' "$ACCEPTANCE_SCRIPT" \
    'usage should describe the retention stage as non-destructive'
assert_contains 'cleanup_authorized=false' "$ACCEPTANCE_SCRIPT" \
    'every generated policy result should keep cleanup unauthorized'
assert_contains 'MINIMUM_RETENTION_DAYS=7' "$ACCEPTANCE_SCRIPT" \
    'the rollback should be retained for at least seven days'
assert_contains 'REQUIRED_SUCCESSFUL_BOOTS=2' "$ACCEPTANCE_SCRIPT" \
    'the policy should require two successful target-kernel boots'
assert_contains 'boot_start_epoch" -gt "$reference_epoch' "$ACCEPTANCE_SCRIPT" \
    'the later boot must start after the accepted reboot review'
assert_contains 'stage_5=reinstall-the-exact-active-package-set-to-repair-shared-package-paths' "$ACCEPTANCE_SCRIPT" \
    'the future cleanup plan should repair shared package paths'
assert_contains 'stage_7=atomically-replace-elilo.conf-with-the-single-verified-active-entry' "$ACCEPTANCE_SCRIPT" \
    'the oldkernel stanza should be removed only at an atomic configuration boundary'
assert_contains 'owner=${SUDO_USER:-promano}' "$ACCEPTANCE_SCRIPT" \
    'evidence publication should default to promano ownership'
assert_contains '"/home/$owner/${archive##*/}"' "$ACCEPTANCE_SCRIPT" \
    'the evidence archive should be copied directly to the user home'
assert_not_contains '/home/$owner/Downloads' "$ACCEPTANCE_SCRIPT" \
    'the evidence copy command must not use a Downloads subdirectory'
assert_not_contains '/home/$owner/Descargas' "$ACCEPTANCE_SCRIPT" \
    'the evidence copy command must not use a Descargas subdirectory'
assert_not_matches '^[[:space:]]*(command[[:space:]]+)?removepkg([[:space:]]|$)' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not invoke removepkg'
assert_not_matches '^[[:space:]]*(command[[:space:]]+)?upgradepkg([[:space:]]|$)' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not invoke upgradepkg'
assert_not_matches '^[[:space:]]*(command[[:space:]]+)?installpkg([[:space:]]|$)' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not invoke installpkg'
assert_not_matches '^[[:space:]]*(command[[:space:]]+)?mkinitrd([[:space:]]|$)' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not invoke mkinitrd'
assert_not_matches '^[[:space:]]*(command[[:space:]]+)?rm([[:space:]]|$)' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not remove files'
assert_not_contains 'eliloconfig ' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not run eliloconfig'
assert_not_contains 'efibootmgr ' "$ACCEPTANCE_SCRIPT" \
    'the retention preflight must not change firmware variables'
assert_contains 'readlink -e -- "$configured"' "$ACCEPTANCE_SCRIPT" \
    'the package database compatibility path should be resolved canonically'
assert_contains 'package_database_resolved=$PACKAGE_DATABASE_RESOLVED' "$ACCEPTANCE_SCRIPT" \
    'the evidence summary should record the resolved package database path'
assert_contains 'compare_captured_file "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt"' \
    "$ACCEPTANCE_SCRIPT" 'package-state comparison should require captured files'
assert_not_contains 'sha256sum -- "$OUTPUT_DIR/packages.before.txt"' "$ACCEPTANCE_SCRIPT" \
    'missing package captures must not be hashed unconditionally'
assert_success 'cleanup eligibility should be evaluated after final state comparison' \
    python3 - "$ACCEPTANCE_SCRIPT" <<'PYTHON_EOF'
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
comparison = text.index('package and boot immutability could not be compared')
eligibility = text.index('    evaluate_cleanup_eligibility\n', comparison)
plan = text.index('    write_cleanup_plan ', eligibility)
if not comparison < eligibility < plan:
    raise SystemExit(1)
PYTHON_EOF

TARGET=
OUTPUT_DIR=
assert_success 'Slackware 15.0 arguments should parse' parse_arguments --target slackware-15.0
assert_equal slackware-15.0 "$TARGET" 'the target should be preserved'
TARGET=
OUTPUT_DIR=
assert_failure 'Slackware-current should be rejected' parse_arguments --target slackware-current
TARGET=
OUTPUT_DIR=
assert_failure 'relative output directories should be rejected' \
    parse_arguments --target slackware-15.0 --output-dir relative/path
TARGET=
OUTPUT_DIR=
assert_success 'an absolute output directory should parse' \
    parse_arguments --target slackware-15.0 --output-dir "$TMP/output"
assert_equal "$TMP/output" "$OUTPUT_DIR" 'the absolute output path should be preserved'

assert_success 'a normal kernel release should be accepted' is_safe_kernel_version 5.15.209
assert_success 'a release with a local suffix should be accepted' is_safe_kernel_version 5.15.209-custom+1
assert_failure 'an empty release should be rejected' is_safe_kernel_version ''
assert_failure 'a release containing traversal should be rejected' is_safe_kernel_version ../5.15.209
assert_failure 'a hidden release should be rejected' is_safe_kernel_version .5.15.209

assert_success 'the accepted transaction fixture should load' \
    load_accepted_transaction_record "$ACCEPTED_TRANSACTION_RECORD" "$TMP/accepted.txt"
assert_equal 5.15.19 "$(read_key_value previous_kernel "$TMP/accepted.txt")" \
    'the accepted rollback release should be preserved'
assert_equal 5.15.209 "$(read_key_value active_kernel "$TMP/accepted.txt")" \
    'the accepted active release should be preserved'
assert_equal 2026-08-01T17:38:17Z "$(read_key_value apply_captured_at "$TMP/accepted.txt")" \
    'the accepted apply timestamp should be preserved'
assert_equal 2026-08-01T19:51:00+02:00 "$(read_key_value reboot_reviewed_at "$TMP/accepted.txt")" \
    'the accepted reboot-review timestamp should be preserved'

RETENTION_WINDOW_MET=false
ADDITIONAL_BOOT_OBSERVED=false
RETENTION_AGE_SECONDS=0
RETENTION_REQUIRED_SECONDS=0
assert_success 'a retention evaluation before seven days should parse' \
    evaluate_retention_window 1600500000 1600000000 1599999900 7
assert_equal false "$RETENTION_WINDOW_MET" 'the seven-day window should remain unmet before 604800 seconds'
assert_equal false "$ADDITIONAL_BOOT_OBSERVED" 'a boot before the review should not count as the later boot'
assert_equal 500000 "$RETENTION_AGE_SECONDS" 'the retention age should be recorded exactly'
assert_equal 604800 "$RETENTION_REQUIRED_SECONDS" 'seven days should convert to 604800 seconds'
RETENTION_WINDOW_MET=false
ADDITIONAL_BOOT_OBSERVED=false
assert_success 'a mature retention window and later boot should parse' \
    evaluate_retention_window 1600700000 1600000000 1600600000 7
assert_equal true "$RETENTION_WINDOW_MET" 'the retention window should be met after seven days'
assert_equal true "$ADDITIONAL_BOOT_OBSERVED" 'a boot after the accepted review should count as the later boot'
assert_failure 'a current time before the retention reference should fail closed' \
    evaluate_retention_window 1599999999 1600000000 1599999900 7
assert_failure 'a zero-day retention policy should fail closed' \
    evaluate_retention_window 1600700000 1600000000 1600600000 0

FAILURE_COUNT=0
RETENTION_WINDOW_MET=true
ADDITIONAL_BOOT_OBSERVED=true
evaluate_cleanup_eligibility
assert_equal true "$CLEANUP_ELIGIBLE" \
    'eligibility should be true only after all checks and both retention gates pass'
FAILURE_COUNT=1
evaluate_cleanup_eligibility
assert_equal false "$CLEANUP_ELIGIBLE" \
    'any recorded failure should force cleanup eligibility false'
FAILURE_COUNT=0
RETENTION_WINDOW_MET=false
evaluate_cleanup_eligibility
assert_equal false "$CLEANUP_ELIGIBLE" \
    'an unmet retention window should force cleanup eligibility false'
RETENTION_WINDOW_MET=true
ADDITIONAL_BOOT_OBSERVED=false
evaluate_cleanup_eligibility
assert_equal false "$CLEANUP_ELIGIBLE" \
    'a missing later boot should force cleanup eligibility false'
FAILURE_COUNT=0
RETENTION_WINDOW_MET=true
ADDITIONAL_BOOT_OBSERVED=true

cat > "$TMP/elilo.conf" <<'EOF_ELILO'
chooser=simple
delay=1
timeout=1
default=vmlinuz
#
image=vmlinuz-generic-5.15.209
        label=vmlinuz
        initrd=initrd-generic-5.15.209.gz
        read-only
        append="root=/dev/sda2 vga=normal ro"
#
image=vmlinuz
        label=oldkernel
        initrd=initrd.gz
        read-only
        append="root=/dev/sda2 vga=normal ro"
EOF_ELILO
assert_success 'the accepted two-entry ELILO state should parse' \
    parse_elilo_retention_config "$TMP/elilo.conf" "$TMP/elilo.tsv"
assert_equal vmlinuz-generic-5.15.209 "$(read_elilo_field vmlinuz image "$TMP/elilo.tsv")" \
    'the active ELILO image should be versioned'
assert_equal initrd-generic-5.15.209.gz "$(read_elilo_field vmlinuz initrd "$TMP/elilo.tsv")" \
    'the active ELILO initrd should be versioned'
assert_equal vmlinuz "$(read_elilo_field oldkernel image "$TMP/elilo.tsv")" \
    'the rollback ELILO image should retain the legacy basename'
assert_equal initrd.gz "$(read_elilo_field oldkernel initrd "$TMP/elilo.tsv")" \
    'the rollback ELILO initrd should retain the legacy basename'
sed 's/default=vmlinuz/default=oldkernel/' "$TMP/elilo.conf" > "$TMP/elilo.wrong-default"
assert_failure 'oldkernel must never become the default during retention' \
    parse_elilo_retention_config "$TMP/elilo.wrong-default" "$TMP/elilo.bad"
sed '/label=oldkernel/,+3d' "$TMP/elilo.conf" > "$TMP/elilo.no-rollback"
assert_failure 'a missing rollback stanza should fail closed' \
    parse_elilo_retention_config "$TMP/elilo.no-rollback" "$TMP/elilo.bad"
printf '\nimage=extra\n label=extra\n initrd=extra.gz\n' >> "$TMP/elilo.conf"
assert_failure 'an extra ELILO stanza should fail closed' \
    parse_elilo_retention_config "$TMP/elilo.conf" "$TMP/elilo.bad"

PACKAGE_DB="$TMP/packages"
mkdir -p "$PACKAGE_DB"
write_package_log() {
    local path=$1
    shift
    {
        printf 'PACKAGE NAME:  %s\n' "${path##*/}"
        printf 'PACKAGE DESCRIPTION:\n'
        printf 'FILE LIST:\n'
        printf '%s\n' "$@"
    } > "$path"
}
write_package_log "$PACKAGE_DB/kernel-generic-5.15.19-x86_64-2" \
    boot/ boot/vmlinuz-generic-5.15.19 boot/vmlinuz-generic install/ install/doinst.sh
write_package_log "$PACKAGE_DB/kernel-generic-5.15.209-x86_64-1" \
    boot/ boot/vmlinuz-generic-5.15.209 boot/vmlinuz-generic install/ install/doinst.sh
write_package_log "$PACKAGE_DB/kernel-huge-5.15.19-x86_64-2" \
    boot/ boot/vmlinuz-huge-5.15.19 boot/vmlinuz install/ install/doinst.sh
write_package_log "$PACKAGE_DB/kernel-huge-5.15.209-x86_64-1" \
    boot/ boot/vmlinuz-huge-5.15.209 boot/vmlinuz install/ install/doinst.sh
write_package_log "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2" \
    lib/ lib/modules/ lib/modules/5.15.19/ lib/modules/5.15.19/kernel/object-old.ko
write_package_log "$PACKAGE_DB/kernel-modules-5.15.209-x86_64-1" \
    lib/ lib/modules/ lib/modules/5.15.209/ lib/modules/5.15.209/kernel/object-new.ko
PACKAGE_DB_LINK="$TMP/packages-link"
ln -s "$PACKAGE_DB" "$PACKAGE_DB_LINK"
assert_equal "$(readlink -e -- "$PACKAGE_DB")" "$(resolve_package_database "$PACKAGE_DB_LINK")" \
    'the Slackware package database compatibility symlink should resolve safely'
assert_success 'the package database snapshot should follow the compatibility symlink' \
    capture_package_database "$PACKAGE_DB_LINK" "$TMP/packages.snapshot"
assert_equal 6 "$(wc -l < "$TMP/packages.snapshot")" \
    'the package database snapshot should contain all six regular package records'
ln -s "$PACKAGE_DB/missing" "$TMP/broken-packages-link"
assert_failure 'a broken package database compatibility symlink should fail closed' \
    resolve_package_database "$TMP/broken-packages-link"
printf 'not a directory\n' > "$TMP/package-database-file"
ln -s "$TMP/package-database-file" "$TMP/package-database-file-link"
assert_failure 'a package database symlink to a regular file should fail closed' \
    resolve_package_database "$TMP/package-database-file-link"
assert_success 'the exact active and rollback package set should resolve' \
    capture_kernel_package_records "$PACKAGE_DB_LINK" 5.15.209 5.15.19 "$TMP/records.tsv"
assert_equal 6 "$(wc -l < "$TMP/records.tsv")" \
    'exactly six retained kernel package records should be emitted'
assert_equal 3 "$(awk -F '\t' '$1 == "active" {count++} END {print count+0}' "$TMP/records.tsv")" \
    'three active package records should be present'
assert_equal 3 "$(awk -F '\t' '$1 == "rollback" {count++} END {print count+0}' "$TMP/records.tsv")" \
    'three rollback package records should be present'
assert_success 'shared package paths should be inventoried' \
    extract_package_path_overlap "$PACKAGE_DB_LINK" "$TMP/records.tsv" "$TMP/overlap.tsv"
assert_contains $'kernel-generic\tkernel-generic-5.15.19-x86_64-2\tkernel-generic-5.15.209-x86_64-1\tboot/vmlinuz-generic' \
    "$TMP/overlap.tsv" 'the shared generic-kernel path should be recorded'
assert_contains $'kernel-huge\tkernel-huge-5.15.19-x86_64-2\tkernel-huge-5.15.209-x86_64-1\tboot/vmlinuz' \
    "$TMP/overlap.tsv" 'the shared huge-kernel path should be recorded'
assert_equal 2 "$(wc -l < "$TMP/overlap.tsv")" \
    'only the two representative shared paths should be emitted'
cp "$PACKAGE_DB/kernel-generic-5.15.19-x86_64-2" "$PACKAGE_DB/kernel-generic-5.15.19-x86_64-3"
assert_failure 'duplicate rollback package records should fail closed' \
    capture_kernel_package_records "$PACKAGE_DB" 5.15.209 5.15.19 "$TMP/records.bad"
rm -f "$PACKAGE_DB/kernel-generic-5.15.19-x86_64-3"
printf '../unsafe\n' >> "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2"
assert_failure 'unsafe package-log paths should fail closed' \
    extract_package_path_overlap "$PACKAGE_DB" "$TMP/records.tsv" "$TMP/overlap.bad"
sed -i '$d' "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2"
mv "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2" "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2.real"
ln -s kernel-modules-5.15.19-x86_64-2.real "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2"
assert_failure 'a package-record symlink introduced after inventory should fail closed' \
    extract_package_path_overlap "$PACKAGE_DB_LINK" "$TMP/records.tsv" "$TMP/overlap.symlink"
rm -f "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2"
mv "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2.real" "$PACKAGE_DB/kernel-modules-5.15.19-x86_64-2"

printf 'same\n' > "$TMP/state.before"
printf 'same\n' > "$TMP/state.after"
assert_success 'two captured regular files with identical content should compare equal' \
    compare_captured_file "$TMP/state.before" "$TMP/state.after"
printf 'changed\n' > "$TMP/state.after"
assert_failure 'different captured state should not compare equal' \
    compare_captured_file "$TMP/state.before" "$TMP/state.after"
assert_failure 'a missing initial capture should never compare equal' \
    compare_captured_file "$TMP/state.missing" "$TMP/state.after"
ln -s "$TMP/state.before" "$TMP/state.link"
assert_failure 'a symlinked state capture should fail closed' \
    compare_captured_file "$TMP/state.link" "$TMP/state.before"

MINIMUM_RETENTION_DAYS=7
REQUIRED_SUCCESSFUL_BOOTS=2
RETENTION_WINDOW_MET=true
ADDITIONAL_BOOT_OBSERVED=true
CLEANUP_ELIGIBLE=true
assert_success 'an eligible cleanup plan should be rendered without authorization' \
    write_cleanup_plan "$TMP/cleanup-plan.txt" 5.15.209 5.15.19
assert_contains 'cleanup_eligible=true' "$TMP/cleanup-plan.txt" \
    'the plan may report eligibility after all policy gates pass'
assert_contains 'cleanup_authorized=false' "$TMP/cleanup-plan.txt" \
    'eligibility must not authorize cleanup'
assert_contains 'stage_4=remove-only-the-three-exact-rollback-package-records' "$TMP/cleanup-plan.txt" \
    'the future apply should target only the exact rollback records'
assert_contains 'stage_8=remove-unreferenced-legacy-vmlinuz-initrd.gz-and-old-versioned-initrd-artifacts' "$TMP/cleanup-plan.txt" \
    'legacy files should be removed only after ELILO stops referencing them'

POLICY_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-retention-policy.json"
assert_success 'the retention policy fixture should be valid JSON' python3 -m json.tool "$POLICY_FIXTURE"
assert_contains '"minimum_days_after_accepted_reboot_review": 7' "$POLICY_FIXTURE" \
    'the fixture should preserve the seven-day retention window'
assert_contains '"required_successful_boots": 2' "$POLICY_FIXTURE" \
    'the fixture should preserve the two-boot requirement'
assert_contains '"one_later_boot_after_review_required": true' "$POLICY_FIXTURE" \
    'the fixture should require a distinct later boot'
assert_contains '"cleanup_authorized": false' "$POLICY_FIXTURE" \
    'the fixture must keep cleanup unauthorized'

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'the acceptance script should pass bash -n'

printf 'ELILO oldkernel retention preflight harness: %d checks, %d failures\n' \
    "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
