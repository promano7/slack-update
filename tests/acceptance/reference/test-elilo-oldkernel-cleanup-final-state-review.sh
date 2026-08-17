#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-final-state-review-policy.json"
ACCEPTED_POST_REMOVAL="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-20260817-accepted.json"
STEP113_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification.sh"
STEP113_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-post-removal-verification-policy.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_POST_REMOVAL_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_REMOVED_RECOVERY_PATH=""
CONFIRM_FINAL_STATE_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-final-state-review.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-post-removal-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-removed-recovery-path ABSOLUTE_PATH \
    --confirm-final-state-scope-sha256 SHA256

This stage performs a non-mutating final-state review of the completed ELILO
oldkernel cleanup. It validates stable boot identity, package/module/boot
baselines, ELILO semantics, rollback absence, and persistent recovery-backup
absence. It never authorizes or executes mutation.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-post-removal-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_POST_REMOVAL_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-active-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
        --confirm-rollback-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
        --confirm-removed-recovery-path) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REMOVED_RECOVERY_PATH=$2; shift 2 ;;
        --confirm-final-state-scope-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_FINAL_STATE_SCOPE_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance review must run as root.\n' >&2
    exit 2
fi
for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_POST_REMOVAL_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_REMOVED_RECOVERY_PATH" "$CONFIRM_FINAL_STATE_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done
[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_POST_REMOVAL_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid post-removal evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_FINAL_STATE_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid final-state scope SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_REMOVED_RECOVERY_PATH == /* ]] || { printf 'ERROR: removed recovery path must be absolute.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FINAL_STATE_REVIEW_PASSED=false
CLEANUP_FINAL_STATE_ACCEPTED=false
ROLLBACK_STATE_ABSENT=false
RECOVERY_BACKUP_ABSENT=false
SYSTEM_STATE_PRESERVED=false
STABLE_BOOT_IDENTITY_VERIFIED=false
DESTRUCTIVE_ACTION_AUTHORIZED=false
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

for required in "$0" "$POLICY" "$ACCEPTED_POST_REMOVAL" "$STEP113_SCRIPT" "$STEP113_POLICY"; do
    [[ -f $required && ! -L $required ]] || fail "a required final-state review file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-final-state-review
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
ACCEPTED_POST_REMOVAL_SHA256=$(sha_file "$ACCEPTED_POST_REMOVAL")
STEP113_SCRIPT_SHA256=$(sha_file "$STEP113_SCRIPT")
STEP113_POLICY_SHA256=$(sha_file "$STEP113_POLICY")

EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_ACCEPTED_RECORD_SHA256=$(json_value "$POLICY" accepted_post_removal_record_sha256)
EXPECTED_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_post_removal_archive_sha256)
EXPECTED_STEP113_SCRIPT_SHA256=$(json_value "$POLICY" accepted_post_removal_script_sha256)
EXPECTED_STEP113_POLICY_SHA256=$(json_value "$POLICY" accepted_post_removal_policy_sha256)
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

FINAL_STATE_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-final-state-review' \
        "accepted_post_removal_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_post_removal_record_sha256=$ACCEPTED_POST_REMOVAL_SHA256" \
        "accepted_post_removal_script_sha256=$STEP113_SCRIPT_SHA256" \
        "accepted_post_removal_policy_sha256=$STEP113_POLICY_SHA256" \
        "final_state_policy_sha256=$POLICY_SHA256" \
        "final_state_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "required_boot_image_suffix=$EXPECTED_BOOT_IMAGE_SUFFIX" \
        "removed_recovery_path=$EXPECTED_REMOVED_RECOVERY_PATH" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_POST_REMOVAL_SHA256 == "$EXPECTED_ACCEPTED_RECORD_SHA256" \
    && $STEP113_SCRIPT_SHA256 == "$EXPECTED_STEP113_SCRIPT_SHA256" \
    && $STEP113_POLICY_SHA256 == "$EXPECTED_STEP113_POLICY_SHA256" \
    && $(json_value "$ACCEPTED_POST_REMOVAL" accepted) == true \
    && $(json_value "$ACCEPTED_POST_REMOVAL" archive_sha256) == "$EXPECTED_ARCHIVE_SHA256" \
    && $(json_value "$ACCEPTED_POST_REMOVAL" post_removal_verified) == true \
    && $(json_value "$ACCEPTED_POST_REMOVAL" recovery_backup_absent) == true \
    && $(json_value "$ACCEPTED_POST_REMOVAL" removal_commit_verified) == true \
    && $(json_value "$ACCEPTED_POST_REMOVAL" system_state_preserved) == true \
    && $(json_value "$ACCEPTED_POST_REMOVAL" pause_safe) == true \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" final_state_review_only) == true \
    && $(json_value "$POLICY" destructive_action_authorized) == false ]]; then
    pass "the accepted step-113 post-removal verification and exact final-state review boundary are immutably bound"
else
    fail "the final-state review does not match the accepted step-113 boundary"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_POST_REMOVAL_EVIDENCE_SHA256 == "$EXPECTED_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_REMOVED_RECOVERY_PATH == "$EXPECTED_REMOVED_RECOVERY_PATH" \
    && $CONFIRM_FINAL_STATE_SCOPE_SHA256 == "$FINAL_STATE_SCOPE_SHA256" ]]; then
    pass "the explicit host, evidence, kernels, removed path, and final-state scope confirmations match"
else
    fail "one or more explicit final-state confirmations do not match"
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
        if [[ -n $resolved && -d $resolved ]]; then PKGDB=$resolved; break; fi
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
    pass "the current host has the exact stable 5.15.209 boot identity required for final-state review"
else
    fail "the host, running kernel, stable BOOT_IMAGE identity, or package database is outside the final-state boundary"
fi

capture_packages() {
    find "$PKGDB" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"
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
    if [[ -L $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
        printf 'symlink\t%s\n' "$(readlink -- "$EXPECTED_REMOVED_RECOVERY_PATH")" > "$1"
    elif [[ -e $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
        printf 'present\n' > "$1"
    else
        printf 'absent\n' > "$1"
    fi
}
capture_state() {
    local phase=$1
    capture_packages "$WORKDIR/packages.$phase.txt" || true
    capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.$phase.sha256" || true
    capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.$phase.txt" || true
    capture_boot_state "$WORKDIR/boot-state.$phase.txt"
    cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.$phase" 2>/dev/null || true
    capture_removed_path_state "$WORKDIR/recovery-path.$phase.txt"
}

capture_state before
if [[ -s $WORKDIR/packages.before.txt \
    && -s $WORKDIR/modules-active-objects.before.sha256 \
    && -s $WORKDIR/boot-state.before.txt \
    && -s $WORKDIR/elilo.conf.before \
    && -s $WORKDIR/recovery-path.before.txt ]]; then
    pass "the complete persistent final-state baseline was captured"
else
    fail "one or more final-state captures are incomplete"
fi

if [[ $(sha_file "$WORKDIR/packages.before.txt") == "$EXPECTED_PACKAGE_SHA256" \
    && $(sha_file "$WORKDIR/modules-active-objects.before.sha256") == "$EXPECTED_ACTIVE_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/modules-rollback-objects.before.txt") == "$EXPECTED_ROLLBACK_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/boot-state.before.txt") == "$EXPECTED_BOOT_STATE_SHA256" \
    && $(sha_file "$WORKDIR/elilo.conf.before") == "$EXPECTED_ELILO_SHA256" ]]; then
    pass "the accepted package, module, rollback-absence, boot, and ELILO hashes match the final baseline"
else
    fail "persistent final-state hashes drifted after step 113"
fi

ELILO=/boot/efi/EFI/Slackware/elilo.conf
ACTIVE_IMAGE_COUNT=$(sed 's/[[:space:]]*#.*$//' "$ELILO" | grep -Ec "^[[:space:]]*image=vmlinuz-generic-$EXPECTED_ACTIVE_KERNEL[[:space:]]*$" || true)
ACTIVE_INITRD_COUNT=$(sed 's/[[:space:]]*#.*$//' "$ELILO" | grep -Ec "^[[:space:]]*initrd=initrd-generic-$EXPECTED_ACTIVE_KERNEL\\.gz[[:space:]]*$" || true)
OLDKERNEL_EXECUTABLE_REFS=$(sed 's/[[:space:]]*#.*$//' "$ELILO" | grep -Eic "oldkernel|$EXPECTED_ROLLBACK_KERNEL" || true)
DEFAULT_LABEL=$(sed 's/[[:space:]]*#.*$//' "$ELILO" | awk -F= '/^[[:space:]]*default=/{gsub(/[[:space:]]/,"",$2); print $2; exit}')
ACTIVE_LABEL_COUNT=$(sed 's/[[:space:]]*#.*$//' "$ELILO" | grep -Ec '^[[:space:]]*label=vmlinuz[[:space:]]*$' || true)
if [[ $ACTIVE_IMAGE_COUNT -eq 1 && $ACTIVE_INITRD_COUNT -eq 1 && $OLDKERNEL_EXECUTABLE_REFS -eq 0 && $DEFAULT_LABEL == vmlinuz && $ACTIVE_LABEL_COUNT -eq 1 ]]; then
    pass "ELILO semantics contain one active 5.15.209 boot entry and no executable rollback reference"
else
    fail "ELILO final-state semantics are not the exact active-only boundary"
fi

if [[ ! -e $EXPECTED_REMOVED_RECOVERY_PATH && ! -L $EXPECTED_REMOVED_RECOVERY_PATH \
    && ! -s $WORKDIR/modules-rollback-objects.before.txt ]]; then
    RECOVERY_BACKUP_ABSENT=true
    ROLLBACK_STATE_ABSENT=true
    pass "rollback module objects and the retired recovery backup remain absent"
else
    fail "rollback or recovery state reappeared after the completed cleanup"
fi

capture_state after
if cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt" \
    && cmp -s -- "$WORKDIR/modules-active-objects.before.sha256" "$WORKDIR/modules-active-objects.after.sha256" \
    && cmp -s -- "$WORKDIR/modules-rollback-objects.before.txt" "$WORKDIR/modules-rollback-objects.after.txt" \
    && cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt" \
    && cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after" \
    && cmp -s -- "$WORKDIR/recovery-path.before.txt" "$WORKDIR/recovery-path.after.txt"; then
    SYSTEM_STATE_PRESERVED=true
    pass "the final-state review did not modify packages, ELILO, boot artifacts, modules, or recovery paths"
else
    fail "the final-state review changed persistent state"
fi

if [[ $FAIL_COUNT -eq 0 \
    && $STABLE_BOOT_IDENTITY_VERIFIED == true \
    && $ROLLBACK_STATE_ABSENT == true \
    && $RECOVERY_BACKUP_ABSENT == true \
    && $SYSTEM_STATE_PRESERVED == true ]]; then
    FINAL_STATE_REVIEW_PASSED=true
    CLEANUP_FINAL_STATE_ACCEPTED=true
    DESTRUCTIVE_ACTION_AUTHORIZED=false
    PAUSE_SAFE=true
    NEXT_STAGE=elilo-oldkernel-cleanup-destructive-boundary-closure
    pass "the functional final state of the ELILO oldkernel cleanup is accepted with no destructive action authorized"
else
    skip "final-state acceptance is withheld because one or more review conditions failed"
fi

cat > "$WORKDIR/summary.txt" <<EOF
scenario=elilo-oldkernel-cleanup-final-state-review
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_post_removal_archive_sha256=$EXPECTED_ARCHIVE_SHA256
accepted_post_removal_record_sha256=$ACCEPTED_POST_REMOVAL_SHA256
accepted_post_removal_script_sha256=$STEP113_SCRIPT_SHA256
accepted_post_removal_policy_sha256=$STEP113_POLICY_SHA256
final_state_script_sha256=$SCRIPT_SHA256
final_state_policy_sha256=$POLICY_SHA256
final_state_scope_sha256=$FINAL_STATE_SCOPE_SHA256
transient_boot_id_equality_required=false
current_boot_id_evidence_only=$CURRENT_BOOT_ID
boot_image=$BOOT_IMAGE
required_boot_image_suffix=$EXPECTED_BOOT_IMAGE_SUFFIX
removed_recovery_path=$EXPECTED_REMOVED_RECOVERY_PATH
final_state_review_passed=$FINAL_STATE_REVIEW_PASSED
cleanup_final_state_accepted=$CLEANUP_FINAL_STATE_ACCEPTED
rollback_state_absent=$ROLLBACK_STATE_ABSENT
recovery_backup_absent=$RECOVERY_BACKUP_ABSENT
system_state_preserved=$SYSTEM_STATE_PRESERVED
stable_boot_identity_verified=$STABLE_BOOT_IDENTITY_VERIFIED
destructive_action_authorized=$DESTRUCTIVE_ACTION_AUTHORIZED
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-final-state-review-${TIMESTAMP}.tar.gz"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$WORKDIR")"
ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
    "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
printf 'Result: %s (%d passes, %d failures, %d skips); final_state_review_passed=%s; cleanup_final_state_accepted=%s; rollback_state_absent=%s; recovery_backup_absent=%s; destructive_action_authorized=%s; system_state_preserved=%s; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
    "$FINAL_STATE_REVIEW_PASSED" "$CLEANUP_FINAL_STATE_ACCEPTED" "$ROLLBACK_STATE_ABSENT" "$RECOVERY_BACKUP_ABSENT" "$DESTRUCTIVE_ACTION_AUTHORIZED" "$SYSTEM_STATE_PRESERVED" "$PAUSE_SAFE" "$NEXT_STAGE"

[[ $FAIL_COUNT -eq 0 ]]
