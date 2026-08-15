#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-policy.json"
ACCEPTED_POST_REBOOT="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-reboot-verification-20260815-accepted.json"
FAILED_STEP108="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-20260815-failed-reviewed.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_POST_REBOOT_EVIDENCE_SHA256=""
CONFIRM_FAILED_RELEASE_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_RECOVERY_BACKUP_PATH=""
CONFIRM_RELEASE_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-post-reboot-evidence-sha256 SHA256 \
    --confirm-failed-release-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-recovery-backup-path ABSOLUTE_PATH \
    --confirm-release-scope-sha256 SHA256

This stage is read-only. It reviews the retained recovery snapshot after the
step-108 false negative. It uses the path representation accepted by step 107
and validates the complete ten-file private recovery snapshot. It never removes
recovery data.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-post-reboot-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_POST_REBOOT_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-failed-release-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_FAILED_RELEASE_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-active-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
        --confirm-rollback-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
        --confirm-recovery-backup-path) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_RECOVERY_BACKUP_PATH=$2; shift 2 ;;
        --confirm-release-scope-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_RELEASE_SCOPE_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance review must run as root.\n' >&2
    exit 2
fi

for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_POST_REBOOT_EVIDENCE_SHA256" "$CONFIRM_FAILED_RELEASE_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_RECOVERY_BACKUP_PATH" "$CONFIRM_RELEASE_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done

[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_POST_REBOOT_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid post-reboot evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_FAILED_RELEASE_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid failed release evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_RELEASE_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid release scope SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_RECOVERY_BACKUP_PATH == /* ]] || { printf 'ERROR: recovery backup confirmation must be absolute.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*"; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$*"; }
sha_file() { sha256sum -- "$1" | awk '{print $1}'; }
json_value() {
    local file=$1 path=$2
    python3 - "$file" "$path" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    value = json.load(handle)
for part in sys.argv[2].split("."):
    value = value[part]
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
else:
    print(value)
PY
}

if [[ ! -f $0 || -L $0 || ! -f $POLICY || -L $POLICY || ! -f $ACCEPTED_POST_REBOOT || -L $ACCEPTED_POST_REBOOT || ! -f $FAILED_STEP108 || -L $FAILED_STEP108 ]]; then
    fail "the revision review, policy, accepted step-107 record, or reviewed step-108 diagnostic is missing or unsafe"
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1
WORKDIR="$EVIDENCE_PARENT/${TARGET}-${TIMESTAMP}"
mkdir -p -- "$WORKDIR"
chmod 0700 -- "$WORKDIR"
ASSERTIONS_LOG="$WORKDIR/assertions.log"
: > "$ASSERTIONS_LOG"
exec 3>&1
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }

SCRIPT_SHA256=$(sha_file "$0")
POLICY_SHA256=$(sha_file "$POLICY")
ACCEPTED_POST_REBOOT_SHA256=$(sha_file "$ACCEPTED_POST_REBOOT")
FAILED_STEP108_SHA256=$(sha_file "$FAILED_STEP108")

EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_RECORD_SHA256=$(json_value "$POLICY" accepted_post_reboot_record_sha256)
EXPECTED_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_post_reboot_archive_sha256)
EXPECTED_FAILED_RECORD_SHA256=$(json_value "$POLICY" failed_step108_record_sha256)
EXPECTED_FAILED_ARCHIVE_SHA256=$(json_value "$POLICY" failed_step108_archive_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" hostname_fqdn)
EXPECTED_ACTIVE_KERNEL=$(json_value "$POLICY" active_kernel)
EXPECTED_ROLLBACK_KERNEL=$(json_value "$POLICY" rollback_kernel)
EXPECTED_BOOT_ID=$(json_value "$POLICY" accepted_boot_id)
EXPECTED_RECOVERY_BACKUP_PATH=$(json_value "$POLICY" recovery_backup_path)
EXPECTED_PACKAGE_SHA256=$(json_value "$POLICY" post_package_snapshot_sha256)
EXPECTED_ACTIVE_MODULES_SHA256=$(json_value "$POLICY" active_module_object_manifest_sha256)
EXPECTED_BOOT_STATE_SHA256=$(json_value "$POLICY" boot_state_sha256)
EXPECTED_ELILO_SHA256=$(json_value "$POLICY" elilo_conf_sha256)
EXPECTED_RECOVERY_MANIFEST_SHA256=$(json_value "$POLICY" recovery_manifest_sha256)
EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256=$(json_value "$POLICY" recovery_directory_manifest_sha256)
EXPECTED_BOOT_TAR_SHA256=$(json_value "$POLICY" recovery_archives.boot_tar)
EXPECTED_MODULES_TAR_SHA256=$(json_value "$POLICY" recovery_archives.modules_tar)
EXPECTED_PKGTOOLS_TAR_SHA256=$(json_value "$POLICY" recovery_archives.pkgtools_tar)

EXPECTED_MEMBER_NAMES='archive.sha256,boot.before.sha256,boot.tar,modules-active-objects.before.sha256,modules-active-stable.before.sha256,modules-active.before.sha256,modules-rollback.before.sha256,modules.tar,packages.before.txt,pkgtools.tar'

RELEASE_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1' \
        "accepted_post_reboot_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_post_reboot_record_sha256=$ACCEPTED_POST_REBOOT_SHA256" \
        "failed_step108_archive_sha256=$EXPECTED_FAILED_ARCHIVE_SHA256" \
        "failed_step108_record_sha256=$FAILED_STEP108_SHA256" \
        "release_review_policy_sha256=$POLICY_SHA256" \
        "release_review_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "accepted_boot_id=$EXPECTED_BOOT_ID" \
        "recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH" \
        | sha256sum | awk '{print $1}'
)

REMOVAL_TARGET_SHA256=$(
    printf '%s\n' \
        "recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH" \
        "recovery_directory_manifest_sha256=$EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256" \
        "directory_members=$EXPECTED_MEMBER_NAMES" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_POST_REBOOT_SHA256 == "$EXPECTED_RECORD_SHA256" \
    && $FAILED_STEP108_SHA256 == "$EXPECTED_FAILED_RECORD_SHA256" \
    && $(json_value "$ACCEPTED_POST_REBOOT" accepted) == true \
    && $(json_value "$ACCEPTED_POST_REBOOT" post_reboot_verified) == true \
    && $(json_value "$ACCEPTED_POST_REBOOT" recovery_backup_release_ready) == true \
    && $(json_value "$ACCEPTED_POST_REBOOT" recovery_backup_removal_authorized) == false \
    && $(json_value "$ACCEPTED_POST_REBOOT" archive_sha256) == "$EXPECTED_ARCHIVE_SHA256" \
    && $(json_value "$FAILED_STEP108" diagnostic_accepted) == true \
    && $(json_value "$FAILED_STEP108" release_review_passed) == false \
    && $(json_value "$FAILED_STEP108" recovery_backup_removal_authorized) == false \
    && $(json_value "$FAILED_STEP108" archive_sha256) == "$EXPECTED_FAILED_ARCHIVE_SHA256" \
    && $(json_value "$FAILED_STEP108" diagnosis.machine_state_drift) == false \
    && $(json_value "$FAILED_STEP108" diagnosis.normalized_module_manifest_matches_step107) == true \
    && $(json_value "$FAILED_STEP108" diagnosis.actual_recovery_directory_member_count) == 10 \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" revision_review_authorized) == true \
    && $(json_value "$POLICY" removal_execution_authorized) == false ]]; then
    pass "the accepted step-107 state and reviewed step-108 false-negative diagnosis are immutably bound"
else
    fail "the revision review does not match the accepted post-reboot state and failed step-108 diagnosis"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_POST_REBOOT_EVIDENCE_SHA256 == "$EXPECTED_ARCHIVE_SHA256" \
    && $CONFIRM_FAILED_RELEASE_EVIDENCE_SHA256 == "$EXPECTED_FAILED_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_RECOVERY_BACKUP_PATH == "$EXPECTED_RECOVERY_BACKUP_PATH" \
    && $CONFIRM_RELEASE_SCOPE_SHA256 == "$RELEASE_SCOPE_SHA256" ]]; then
    pass "the explicit host, accepted evidence, failed evidence, kernels, recovery path, and revision scope confirmations match"
else
    fail "one or more explicit revision confirmations do not match"
fi

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
RUNNING_KERNEL=$(uname -r 2>/dev/null || true)
CURRENT_BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)
PKGDB=""
for candidate in /var/lib/pkgtools/packages /var/log/packages; do
    if [[ -d $candidate ]]; then
        resolved=$(readlink -f -- "$candidate" 2>/dev/null || true)
        if [[ -n $resolved && -d $resolved ]]; then
            PKGDB=$resolved
            break
        fi
    fi
done
printf '%s\n' "$CURRENT_BOOT_ID" > "$WORKDIR/boot-id.txt"

if [[ $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $RUNNING_KERNEL == "$EXPECTED_ACTIVE_KERNEL" && $CURRENT_BOOT_ID == "$EXPECTED_BOOT_ID" && -n $PKGDB && -d $PKGDB && ! -L $PKGDB ]]; then
    pass "the same successfully verified 5.15.209 boot remains active"
else
    fail "the host, running kernel, boot identity, or package database drifted after step 107"
fi

capture_packages() {
    local output=$1
    find "$PKGDB" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$output"
}

capture_module_objects() {
    local module_root=$1 output=$2
    : > "$output"
    [[ -d $module_root && ! -L $module_root ]] || return 1
    while IFS= read -r -d '' path; do
        rel=${path#"$module_root"/}
        # Step 107 accepted the canonical manifest with an explicit "./" prefix.
        printf '%s  ./%s\n' "$(sha_file "$path")" "$rel" >> "$output"
    done < <(find "$module_root" -type f \( -name '*.ko' -o -name '*.ko.*' \) -print0 | LC_ALL=C sort -z)
}

capture_rollback_objects() {
    local module_root=$1 output=$2
    : > "$output"
    [[ -d $module_root && ! -L $module_root ]] || return 0
    find "$module_root" -type f \( -name '*.ko' -o -name '*.ko.*' \) -printf '%P\n' | LC_ALL=C sort > "$output"
}

capture_boot_state() {
    local output=$1 path
    : > "$output"
    for path in \
        /boot/efi/EFI/Slackware/elilo.conf \
        "/boot/vmlinuz-generic-$EXPECTED_ACTIVE_KERNEL" \
        "/boot/initrd-generic-$EXPECTED_ACTIVE_KERNEL.gz" \
        "/boot/vmlinuz-generic-$EXPECTED_ROLLBACK_KERNEL" \
        /boot/initrd.gz \
        "/boot/efi/EFI/Slackware/vmlinuz-generic-$EXPECTED_ACTIVE_KERNEL" \
        "/boot/efi/EFI/Slackware/initrd-generic-$EXPECTED_ACTIVE_KERNEL.gz" \
        /boot/efi/EFI/Slackware/vmlinuz \
        /boot/efi/EFI/Slackware/initrd.gz; do
        if [[ -L $path ]]; then
            printf 'symlink\t%s\t%s\n' "$path" "$(readlink -- "$path")" >> "$output"
        elif [[ -f $path ]]; then
            printf 'file\t%s\t%s\n' "$path" "$(sha_file "$path")" >> "$output"
        elif [[ -d $path ]]; then
            printf 'directory\t%s\n' "$path" >> "$output"
        else
            printf 'absent\t%s\n' "$path" >> "$output"
        fi
    done
}

capture_recovery_hashes() {
    local output=$1 name
    : > "$output"
    [[ -d $EXPECTED_RECOVERY_BACKUP_PATH && ! -L $EXPECTED_RECOVERY_BACKUP_PATH ]] || return 1
    for name in boot.tar modules.tar pkgtools.tar; do
        [[ -f $EXPECTED_RECOVERY_BACKUP_PATH/$name && ! -L $EXPECTED_RECOVERY_BACKUP_PATH/$name ]] || return 1
        printf '%s  %s\n' "$(sha_file "$EXPECTED_RECOVERY_BACKUP_PATH/$name")" "$name" >> "$output"
    done
}

capture_recovery_directory_members() {
    local output=$1
    : > "$output"
    [[ -d $EXPECTED_RECOVERY_BACKUP_PATH && ! -L $EXPECTED_RECOVERY_BACKUP_PATH ]] || return 1
    find "$EXPECTED_RECOVERY_BACKUP_PATH" -mindepth 1 -maxdepth 1 -printf '%f\t%y\n' | LC_ALL=C sort > "$output"
}

capture_recovery_directory_manifest() {
    local output=$1 path name
    : > "$output"
    [[ -d $EXPECTED_RECOVERY_BACKUP_PATH && ! -L $EXPECTED_RECOVERY_BACKUP_PATH ]] || return 1
    while IFS= read -r -d '' path; do
        name=${path##*/}
        [[ -f $path && ! -L $path ]] || return 1
        printf '%s  %s\n' "$(sha_file "$path")" "$name" >> "$output"
    done < <(find "$EXPECTED_RECOVERY_BACKUP_PATH" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z)
}

capture_all_state() {
    local phase=$1
    capture_packages "$WORKDIR/packages.$phase.txt" || true
    capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.$phase.sha256" || true
    capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.$phase.txt" || true
    capture_boot_state "$WORKDIR/boot-state.$phase.txt"
    capture_recovery_hashes "$WORKDIR/recovery.$phase.sha256" || true
    capture_recovery_directory_members "$WORKDIR/recovery-directory-members.$phase.txt" || true
    capture_recovery_directory_manifest "$WORKDIR/recovery-directory-manifest.$phase.sha256" || true
    cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.$phase" 2>/dev/null || true
}

capture_all_state before

if [[ -s $WORKDIR/packages.before.txt \
    && -s $WORKDIR/modules-active-objects.before.sha256 \
    && -s $WORKDIR/boot-state.before.txt \
    && -s $WORKDIR/recovery.before.sha256 \
    && -s $WORKDIR/recovery-directory-members.before.txt \
    && -s $WORKDIR/recovery-directory-manifest.before.sha256 \
    && -s $WORKDIR/elilo.conf.before ]]; then
    pass "the package, ELILO, boot, module, and complete recovery-directory state was captured"
else
    fail "one or more required revision-review state captures are incomplete"
fi

if [[ $(sha_file "$WORKDIR/packages.before.txt") == "$EXPECTED_PACKAGE_SHA256" \
    && $(sha_file "$WORKDIR/modules-active-objects.before.sha256") == "$EXPECTED_ACTIVE_MODULES_SHA256" \
    && ! -s $WORKDIR/modules-rollback-objects.before.txt \
    && $(sha_file "$WORKDIR/boot-state.before.txt") == "$EXPECTED_BOOT_STATE_SHA256" \
    && $(sha_file "$WORKDIR/elilo.conf.before") == "$EXPECTED_ELILO_SHA256" ]]; then
    pass "the accepted step-107 package, module, rollback-absence, ELILO, and boot state remains intact"
else
    fail "system state differs from the accepted step-107 post-reboot boundary"
fi

EXPECTED_MEMBERS=$'archive.sha256\tf\nboot.before.sha256\tf\nboot.tar\tf\nmodules-active-objects.before.sha256\tf\nmodules-active-stable.before.sha256\tf\nmodules-active.before.sha256\tf\nmodules-rollback.before.sha256\tf\nmodules.tar\tf\npackages.before.txt\tf\npkgtools.tar\tf'
ACTUAL_MEMBERS=$(cat "$WORKDIR/recovery-directory-members.before.txt")
if [[ $ACTUAL_MEMBERS == "$EXPECTED_MEMBERS" ]]; then
    pass "the recovery directory contains exactly the ten private snapshot files established by step 105"
else
    fail "the recovery directory member set or file types differ from the reviewed ten-file snapshot"
fi

if [[ $(sha_file "$WORKDIR/recovery-directory-manifest.before.sha256") == "$EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256" ]]; then
    pass "all ten recovery snapshot files match the exact reviewed hashes"
else
    fail "one or more recovery snapshot files differ from the reviewed step-105 snapshot"
fi

if [[ $(sha_file "$WORKDIR/recovery.before.sha256") == "$EXPECTED_RECOVERY_MANIFEST_SHA256" \
    && $(awk '$2=="boot.tar" {print $1}' "$WORKDIR/recovery.before.sha256") == "$EXPECTED_BOOT_TAR_SHA256" \
    && $(awk '$2=="modules.tar" {print $1}' "$WORKDIR/recovery.before.sha256") == "$EXPECTED_MODULES_TAR_SHA256" \
    && $(awk '$2=="pkgtools.tar" {print $1}' "$WORKDIR/recovery.before.sha256") == "$EXPECTED_PKGTOOLS_TAR_SHA256" ]]; then
    pass "the three recovery payload archives retain the exact accepted hashes"
else
    fail "one or more recovery payload archives differ from the accepted snapshot"
fi

if cmp -s -- "$EXPECTED_RECOVERY_BACKUP_PATH/archive.sha256" "$WORKDIR/recovery.before.sha256"; then
    pass "the retained archive.sha256 metadata still describes the exact three recovery payloads"
else
    fail "the retained recovery archive manifest no longer matches the three payload archives"
fi

resolved_backup=$(readlink -f -- "$EXPECTED_RECOVERY_BACKUP_PATH" 2>/dev/null || true)
expected_parent=/var/lib/slack-update/elilo-cleanup-backups
if [[ $resolved_backup == "$EXPECTED_RECOVERY_BACKUP_PATH" \
    && ${EXPECTED_RECOVERY_BACKUP_PATH%/*} == "$expected_parent" \
    && ${EXPECTED_RECOVERY_BACKUP_PATH##*/} == "5.15.19-20260815T160020Z" ]]; then
    pass "the reviewed removal target is the exact non-symlink recovery directory under the protected parent"
else
    fail "the recovery backup path is not the exact reviewed target"
fi

capture_all_state after

if cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt" \
    && cmp -s -- "$WORKDIR/modules-active-objects.before.sha256" "$WORKDIR/modules-active-objects.after.sha256" \
    && cmp -s -- "$WORKDIR/modules-rollback-objects.before.txt" "$WORKDIR/modules-rollback-objects.after.txt" \
    && cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt" \
    && cmp -s -- "$WORKDIR/recovery.before.sha256" "$WORKDIR/recovery.after.sha256" \
    && cmp -s -- "$WORKDIR/recovery-directory-members.before.txt" "$WORKDIR/recovery-directory-members.after.txt" \
    && cmp -s -- "$WORKDIR/recovery-directory-manifest.before.sha256" "$WORKDIR/recovery-directory-manifest.after.sha256" \
    && cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after"; then
    pass "the revision review did not modify packages, ELILO, boot artifacts, module objects, or recovery data"
else
    fail "revision-review-sensitive state changed while the read-only review was running"
fi

RELEASE_REVIEW_PASSED=false
RECOVERY_BACKUP_REMOVAL_AUTHORIZED=false
PAUSE_SAFE=false
NEXT_STAGE=manual-review-required
if [[ $FAIL_COUNT -eq 0 ]]; then
    RELEASE_REVIEW_PASSED=true
    RECOVERY_BACKUP_REMOVAL_AUTHORIZED=true
    PAUSE_SAFE=true
    NEXT_STAGE=elilo-oldkernel-cleanup-recovery-backup-authorized-removal
    pass "the exact ten-file retained recovery snapshot is authorized only for a later separately gated removal"
else
    skip "recovery-backup removal authorization is withheld because the revision review has failures"
fi

cat > "$WORKDIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_post_reboot_archive_sha256=$EXPECTED_ARCHIVE_SHA256
accepted_post_reboot_record_sha256=$ACCEPTED_POST_REBOOT_SHA256
failed_step108_archive_sha256=$EXPECTED_FAILED_ARCHIVE_SHA256
failed_step108_record_sha256=$FAILED_STEP108_SHA256
release_review_script_sha256=$SCRIPT_SHA256
release_review_policy_sha256=$POLICY_SHA256
release_scope_sha256=$RELEASE_SCOPE_SHA256
removal_target_sha256=$REMOVAL_TARGET_SHA256
accepted_boot_id=$EXPECTED_BOOT_ID
current_boot_id=$CURRENT_BOOT_ID
recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH
recovery_directory_manifest_sha256=$EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256
release_review_passed=$RELEASE_REVIEW_PASSED
recovery_backup_retained=true
recovery_backup_removal_authorized=$RECOVERY_BACKUP_REMOVAL_AUTHORIZED
removal_executed=false
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-${TIMESTAMP}.tar.gz"
SIDECAR="$ARCHIVE.sha256"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" -- "$(basename "$WORKDIR")"
printf '%s  %s\n' "$(sha_file "$ARCHIVE")" "$(basename "$ARCHIVE")" > "$SIDECAR"
chmod 0600 -- "$ARCHIVE" "$SIDECAR"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$(sha_file "$ARCHIVE")"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' "$ARCHIVE" "$(basename "$ARCHIVE")" "$SIDECAR" "$(basename "$SIDECAR")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$SIDECAR")"
printf 'Result: %s (%d passes, %d failures, %d skips); release_review_passed=%s; recovery_backup_retained=true; recovery_backup_removal_authorized=%s; removal_executed=false; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" "$RELEASE_REVIEW_PASSED" "$RECOVERY_BACKUP_REMOVAL_AUTHORIZED" "$PAUSE_SAFE" "$NEXT_STAGE"
if [[ $FAIL_COUNT -eq 0 ]]; then
    printf 'Removal target SHA-256: %s\n' "$REMOVAL_TARGET_SHA256"
    printf 'Next action: preserve the recovery backup until this evidence is accepted and a separate exact-file removal boundary is prepared.\n'
else
    printf 'Next action: preserve the recovery backup and review the failed revision boundary.\n'
fi

[[ $FAIL_COUNT -eq 0 ]]
