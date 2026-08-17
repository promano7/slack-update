#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-policy.json"
ACCEPTED_REMOVAL="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1-20260815-accepted.json"
STEP112_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1.sh"
STEP112_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1-policy.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_REMOVAL_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_REMOVED_RECOVERY_PATH=""
CONFIRM_VERIFICATION_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-removal-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-removed-recovery-path ABSOLUTE_PATH \
    --confirm-verification-scope-sha256 SHA256

This stage verifies the committed step-112 recovery-backup removal without
mutating packages, ELILO, boot files, kernel modules, recovery paths, or the
running boot. It accepts a stable versioned ELILO boot identity and does not
require equality to any transient Linux boot UUID.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-removal-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REMOVAL_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-active-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
        --confirm-rollback-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
        --confirm-removed-recovery-path) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REMOVED_RECOVERY_PATH=$2; shift 2 ;;
        --confirm-verification-scope-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_VERIFICATION_SCOPE_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance verification must run as root.\n' >&2
    exit 2
fi

for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_REMOVAL_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_REMOVED_RECOVERY_PATH" "$CONFIRM_VERIFICATION_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done

[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_REMOVAL_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid removal evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_VERIFICATION_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid verification scope SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_REMOVED_RECOVERY_PATH == /* ]] || { printf 'ERROR: removed recovery path confirmation must be absolute.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
POST_REMOVAL_VERIFIED=false
RECOVERY_BACKUP_ABSENT=false
REMOVAL_COMMIT_VERIFIED=false
SYSTEM_STATE_PRESERVED=false
STABLE_BOOT_IDENTITY_VERIFIED=false
PAUSE_SAFE=false
NEXT_STAGE=manual-review-required

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

for required in "$0" "$POLICY" "$ACCEPTED_REMOVAL" "$STEP112_SCRIPT" "$STEP112_POLICY"; do
    if [[ ! -f $required || -L $required ]]; then
        fail "a required post-removal verification file is missing or unsafe: $required"
    fi
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-recovery-backup-post-removal-verification
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
ACCEPTED_REMOVAL_SHA256=$(sha_file "$ACCEPTED_REMOVAL")
STEP112_SCRIPT_SHA256=$(sha_file "$STEP112_SCRIPT")
STEP112_POLICY_SHA256=$(sha_file "$STEP112_POLICY")

EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_ACCEPTED_REMOVAL_RECORD_SHA256=$(json_value "$POLICY" accepted_removal_record_sha256)
EXPECTED_ACCEPTED_REMOVAL_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_removal_archive_sha256)
EXPECTED_STEP112_SCRIPT_SHA256=$(json_value "$POLICY" accepted_removal_script_sha256)
EXPECTED_STEP112_POLICY_SHA256=$(json_value "$POLICY" accepted_removal_policy_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" hostname_fqdn)
EXPECTED_ACTIVE_KERNEL=$(json_value "$POLICY" active_kernel)
EXPECTED_ROLLBACK_KERNEL=$(json_value "$POLICY" rollback_kernel)
EXPECTED_BOOT_IMAGE_SUFFIX=$(json_value "$POLICY" required_boot_image_suffix)
EXPECTED_REMOVED_RECOVERY_PATH=$(json_value "$POLICY" removed_recovery_path)
EXPECTED_PACKAGE_SHA256=$(json_value "$POLICY" post_package_snapshot_sha256)
EXPECTED_ACTIVE_MODULES_SHA256=$(json_value "$POLICY" active_module_object_manifest_sha256)
EXPECTED_ROLLBACK_MODULES_SHA256=$(json_value "$POLICY" rollback_module_objects_manifest_sha256)
EXPECTED_BOOT_STATE_SHA256=$(json_value "$POLICY" boot_state_sha256)
EXPECTED_ELILO_SHA256=$(json_value "$POLICY" elilo_conf_sha256)
EXPECTED_REMOVAL_TARGET_SHA256=$(json_value "$POLICY" removal_target_sha256)

VERIFICATION_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-recovery-backup-post-removal-verification' \
        "accepted_removal_archive_sha256=$EXPECTED_ACCEPTED_REMOVAL_ARCHIVE_SHA256" \
        "accepted_removal_record_sha256=$ACCEPTED_REMOVAL_SHA256" \
        "accepted_removal_script_sha256=$STEP112_SCRIPT_SHA256" \
        "accepted_removal_policy_sha256=$STEP112_POLICY_SHA256" \
        "verification_policy_sha256=$POLICY_SHA256" \
        "verification_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "required_boot_image_suffix=$EXPECTED_BOOT_IMAGE_SUFFIX" \
        "removed_recovery_path=$EXPECTED_REMOVED_RECOVERY_PATH" \
        "removal_target_sha256=$EXPECTED_REMOVAL_TARGET_SHA256" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_REMOVAL_SHA256 == "$EXPECTED_ACCEPTED_REMOVAL_RECORD_SHA256" \
    && $STEP112_SCRIPT_SHA256 == "$EXPECTED_STEP112_SCRIPT_SHA256" \
    && $STEP112_POLICY_SHA256 == "$EXPECTED_STEP112_POLICY_SHA256" \
    && $(json_value "$ACCEPTED_REMOVAL" accepted) == true \
    && $(json_value "$ACCEPTED_REMOVAL" archive_sha256) == "$EXPECTED_ACCEPTED_REMOVAL_ARCHIVE_SHA256" \
    && $(json_value "$ACCEPTED_REMOVAL" removal_executed) == true \
    && $(json_value "$ACCEPTED_REMOVAL" recovery_backup_removed) == true \
    && $(json_value "$ACCEPTED_REMOVAL" recovery_backup_retained) == false \
    && $(json_value "$ACCEPTED_REMOVAL" system_state_preserved) == true \
    && $(json_value "$ACCEPTED_REMOVAL" pause_safe) == true \
    && $(json_value "$ACCEPTED_REMOVAL" next_stage) == elilo-oldkernel-cleanup-recovery-backup-post-removal-verification \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" verification_only) == true \
    && $(json_value "$POLICY" recovery_path_mutation_authorized) == false \
    && $(json_value "$POLICY" package_mutation_authorized) == false \
    && $(json_value "$POLICY" boot_mutation_authorized) == false \
    && $(json_value "$POLICY" module_mutation_authorized) == false ]]; then
    pass "the accepted step-112 committed removal, exact verification code, and post-removal policy are immutably bound"
else
    fail "the post-removal verification boundary does not match the accepted step-112 removal"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_REMOVAL_EVIDENCE_SHA256 == "$EXPECTED_ACCEPTED_REMOVAL_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_REMOVED_RECOVERY_PATH == "$EXPECTED_REMOVED_RECOVERY_PATH" \
    && $CONFIRM_VERIFICATION_SCOPE_SHA256 == "$VERIFICATION_SCOPE_SHA256" ]]; then
    pass "the explicit host, removal evidence, kernels, removed path, and verification-scope confirmations match"
else
    fail "one or more explicit post-removal verification confirmations do not match"
fi

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
RUNNING_KERNEL=$(uname -r 2>/dev/null || true)
CURRENT_BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)
CMDLINE=$(cat /proc/cmdline 2>/dev/null || true)
BOOT_IMAGE=$(printf '%s\n' "$CMDLINE" | awk '{for (i=1;i<=NF;i++) if ($i ~ /^BOOT_IMAGE=/) {sub(/^BOOT_IMAGE=/,"",$i); print $i; exit}}')
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
printf '%s\n' "$CMDLINE" > "$WORKDIR/proc-cmdline.txt"
printf '%s\n' "$BOOT_IMAGE" > "$WORKDIR/boot-image.txt"

if [[ $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $RUNNING_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CURRENT_BOOT_ID =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ \
    && $BOOT_IMAGE == *"$EXPECTED_BOOT_IMAGE_SUFFIX" \
    && -n $PKGDB && -d $PKGDB && ! -L $PKGDB ]]; then
    STABLE_BOOT_IDENTITY_VERIFIED=true
    pass "the current host has the exact stable 5.15.209 boot identity required for post-removal verification"
else
    fail "the host, running kernel, stable BOOT_IMAGE identity, or package database drifted after removal"
fi

capture_packages() {
    local output=$1
    find "$PKGDB" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$output"
}

capture_module_objects() {
    local module_root=$1 output=$2 path rel
    : > "$output"
    [[ -d $module_root && ! -L $module_root ]] || return 1
    while IFS= read -r -d '' path; do
        rel=${path#"$module_root"/}
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

capture_removed_path_state() {
    local output=$1
    if [[ -L $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
        printf 'symlink\t%s\n' "$(readlink -- "$EXPECTED_REMOVED_RECOVERY_PATH")" > "$output"
    elif [[ -e $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
        if [[ -d $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
            printf 'directory\n' > "$output"
        elif [[ -f $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
            printf 'file\n' > "$output"
        else
            printf 'other\n' > "$output"
        fi
    else
        printf 'absent\n' > "$output"
    fi
}

capture_system_state() {
    local phase=$1
    capture_packages "$WORKDIR/packages.$phase.txt" || true
    capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.$phase.sha256" || true
    capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.$phase.txt" || true
    capture_boot_state "$WORKDIR/boot-state.$phase.txt"
    cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.$phase" 2>/dev/null || true
    capture_removed_path_state "$WORKDIR/recovery-path.$phase.txt"
}

capture_system_state before

if [[ -s $WORKDIR/packages.before.txt \
    && -s $WORKDIR/modules-active-objects.before.sha256 \
    && -s $WORKDIR/boot-state.before.txt \
    && -s $WORKDIR/elilo.conf.before \
    && -s $WORKDIR/recovery-path.before.txt ]]; then
    pass "the package, ELILO, boot, module, rollback, and removed recovery-path state was captured after step 112"
else
    fail "one or more required post-removal state captures are incomplete"
fi

if [[ $(sha_file "$WORKDIR/packages.before.txt") == "$EXPECTED_PACKAGE_SHA256" \
    && $(sha_file "$WORKDIR/modules-active-objects.before.sha256") == "$EXPECTED_ACTIVE_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/modules-rollback-objects.before.txt") == "$EXPECTED_ROLLBACK_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/boot-state.before.txt") == "$EXPECTED_BOOT_STATE_SHA256" \
    && $(sha_file "$WORKDIR/elilo.conf.before") == "$EXPECTED_ELILO_SHA256" ]]; then
    pass "the accepted package, active-module, rollback-absence, ELILO, and boot baselines remain intact after removal"
else
    fail "persistent system state differs from the accepted step-112 post-removal baseline"
fi

if [[ $(cat "$WORKDIR/recovery-path.before.txt") == absent \
    && ! -e $EXPECTED_REMOVED_RECOVERY_PATH \
    && ! -L $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
    RECOVERY_BACKUP_ABSENT=true
    REMOVAL_COMMIT_VERIFIED=true
    pass "the exact recovery-backup path removed by step 112 remains absent"
else
    fail "the exact recovery-backup path reappeared after the committed removal"
fi

capture_system_state after

if cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt" \
    && cmp -s -- "$WORKDIR/modules-active-objects.before.sha256" "$WORKDIR/modules-active-objects.after.sha256" \
    && cmp -s -- "$WORKDIR/modules-rollback-objects.before.txt" "$WORKDIR/modules-rollback-objects.after.txt" \
    && cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt" \
    && cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after" \
    && cmp -s -- "$WORKDIR/recovery-path.before.txt" "$WORKDIR/recovery-path.after.txt"; then
    SYSTEM_STATE_PRESERVED=true
    pass "the post-removal verification did not modify packages, ELILO, boot artifacts, modules, or recovery paths"
else
    fail "state changed while executing the post-removal verification"
fi

if [[ $STABLE_BOOT_IDENTITY_VERIFIED == true \
    && $RECOVERY_BACKUP_ABSENT == true \
    && $REMOVAL_COMMIT_VERIFIED == true \
    && $SYSTEM_STATE_PRESERVED == true \
    && $FAIL_COUNT -eq 0 ]]; then
    POST_REMOVAL_VERIFIED=true
    PAUSE_SAFE=true
    NEXT_STAGE=elilo-oldkernel-cleanup-final-state-review
    pass "the committed recovery-backup removal is independently verified and the cleanup remains at a safe boundary"
else
    skip "final post-removal acceptance is withheld because one or more verification conditions failed"
fi

cat > "$WORKDIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-recovery-backup-post-removal-verification
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_removal_archive_sha256=$EXPECTED_ACCEPTED_REMOVAL_ARCHIVE_SHA256
accepted_removal_record_sha256=$ACCEPTED_REMOVAL_SHA256
accepted_removal_script_sha256=$STEP112_SCRIPT_SHA256
accepted_removal_policy_sha256=$STEP112_POLICY_SHA256
verification_script_sha256=$SCRIPT_SHA256
verification_policy_sha256=$POLICY_SHA256
verification_scope_sha256=$VERIFICATION_SCOPE_SHA256
removal_target_sha256=$EXPECTED_REMOVAL_TARGET_SHA256
transient_boot_id_equality_required=false
current_boot_id_evidence_only=$CURRENT_BOOT_ID
boot_image=$BOOT_IMAGE
required_boot_image_suffix=$EXPECTED_BOOT_IMAGE_SUFFIX
removed_recovery_path=$EXPECTED_REMOVED_RECOVERY_PATH
post_removal_verified=$POST_REMOVAL_VERIFIED
stable_boot_identity_verified=$STABLE_BOOT_IDENTITY_VERIFIED
recovery_backup_absent=$RECOVERY_BACKUP_ABSENT
removal_commit_verified=$REMOVAL_COMMIT_VERIFIED
system_state_preserved=$SYSTEM_STATE_PRESERVED
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-${TIMESTAMP}.tar.gz"
SIDECAR="$ARCHIVE.sha256"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" -- "$(basename "$WORKDIR")"
printf '%s  %s\n' "$(sha_file "$ARCHIVE")" "$(basename "$ARCHIVE")" > "$SIDECAR"
chmod 0600 -- "$ARCHIVE" "$SIDECAR"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$(sha_file "$ARCHIVE")"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' "$ARCHIVE" "$(basename "$ARCHIVE")" "$SIDECAR" "$(basename "$SIDECAR")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$SIDECAR")"
printf 'Result: %s (%d passes, %d failures, %d skips); post_removal_verified=%s; recovery_backup_absent=%s; removal_commit_verified=%s; system_state_preserved=%s; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" "$POST_REMOVAL_VERIFIED" "$RECOVERY_BACKUP_ABSENT" "$REMOVAL_COMMIT_VERIFIED" "$SYSTEM_STATE_PRESERVED" "$PAUSE_SAFE" "$NEXT_STAGE"
if [[ $FAIL_COUNT -eq 0 ]]; then
    printf 'Next action: preserve this evidence; continue only with the separately prepared final-state review.\n'
else
    printf 'Next action: do not mutate packages, ELILO, boot files, modules, or recovery paths; review this evidence before any further action.\n'
fi

[[ $FAIL_COUNT -eq 0 ]]
