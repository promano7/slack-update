#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-policy.json"
ACCEPTED_RELEASE="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-20260815-accepted.json"
STEP109_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1.sh"
STEP109_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-policy.json"

TARGET=""
EXECUTE_AUTHORIZED_REMOVAL=false
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_RELEASE_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_RECOVERY_BACKUP_PATH=""
CONFIRM_REMOVAL_TARGET_SHA256=""
CONFIRM_REMOVAL_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-recovery-backup-authorized-removal.sh \
    --target slackware-15.0 \
    --execute-authorized-removal \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-release-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-recovery-backup-path ABSOLUTE_PATH \
    --confirm-removal-target-sha256 SHA256 \
    --confirm-removal-scope-sha256 SHA256

This stage performs the separately authorized recovery-backup removal. It is
restricted to ten exact regular files under one exact reviewed directory. It
uses unlink for each reviewed file and rmdir for the reviewed directory. It
never uses recursive removal, globs, package mutation, boot mutation, network
access, repository refresh, or reboot execution.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --execute-authorized-removal) EXECUTE_AUTHORIZED_REMOVAL=true; shift ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-release-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_RELEASE_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-active-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
        --confirm-rollback-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
        --confirm-recovery-backup-path) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_RECOVERY_BACKUP_PATH=$2; shift 2 ;;
        --confirm-removal-target-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REMOVAL_TARGET_SHA256=$2; shift 2 ;;
        --confirm-removal-scope-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REMOVAL_SCOPE_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance removal must run as root.\n' >&2
    exit 2
fi

for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_RELEASE_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_RECOVERY_BACKUP_PATH" "$CONFIRM_REMOVAL_TARGET_SHA256" "$CONFIRM_REMOVAL_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done

[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $EXECUTE_AUTHORIZED_REMOVAL == true ]] || { printf 'ERROR: destructive removal requires --execute-authorized-removal.\n' >&2; exit 2; }
[[ $CONFIRM_RELEASE_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid release evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_REMOVAL_TARGET_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid removal target SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_REMOVAL_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid removal scope SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_RECOVERY_BACKUP_PATH == /* ]] || { printf 'ERROR: recovery backup confirmation must be absolute.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
REMOVAL_STARTED=false
REMOVAL_EXECUTED=false
RECOVERY_BACKUP_REMOVED=false
RECOVERY_BACKUP_RETAINED=true
SYSTEM_STATE_PRESERVED=false
PAUSE_SAFE=false
NEXT_STAGE=manual-review-required
REMOVED_COUNT=0

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
json_map_value() {
    local file=$1 object_name=$2 key=$3
    python3 - "$file" "$object_name" "$key" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)
print(data[sys.argv[2]][sys.argv[3]])
PY
}

for required in "$0" "$POLICY" "$ACCEPTED_RELEASE" "$STEP109_SCRIPT" "$STEP109_POLICY"; do
    if [[ ! -f $required || -L $required ]]; then
        fail "a required removal-boundary file is missing or unsafe: $required"
    fi
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-recovery-backup-authorized-removal
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
ACCEPTED_RELEASE_SHA256=$(sha_file "$ACCEPTED_RELEASE")
STEP109_SCRIPT_SHA256=$(sha_file "$STEP109_SCRIPT")
STEP109_POLICY_SHA256=$(sha_file "$STEP109_POLICY")

EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_ACCEPTED_RELEASE_RECORD_SHA256=$(json_value "$POLICY" accepted_release_record_sha256)
EXPECTED_ACCEPTED_RELEASE_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_release_archive_sha256)
EXPECTED_STEP109_SCRIPT_SHA256=$(json_value "$POLICY" accepted_release_review_script_sha256)
EXPECTED_STEP109_POLICY_SHA256=$(json_value "$POLICY" accepted_release_review_policy_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" hostname_fqdn)
EXPECTED_ACTIVE_KERNEL=$(json_value "$POLICY" active_kernel)
EXPECTED_ROLLBACK_KERNEL=$(json_value "$POLICY" rollback_kernel)
EXPECTED_BOOT_ID=$(json_value "$POLICY" accepted_boot_id)
EXPECTED_RECOVERY_BACKUP_PATH=$(json_value "$POLICY" recovery_backup_path)
EXPECTED_PACKAGE_SHA256=$(json_value "$POLICY" post_package_snapshot_sha256)
EXPECTED_ACTIVE_MODULES_SHA256=$(json_value "$POLICY" active_module_object_manifest_sha256)
EXPECTED_ROLLBACK_MODULES_SHA256=$(json_value "$POLICY" rollback_module_objects_manifest_sha256)
EXPECTED_BOOT_STATE_SHA256=$(json_value "$POLICY" boot_state_sha256)
EXPECTED_ELILO_SHA256=$(json_value "$POLICY" elilo_conf_sha256)
EXPECTED_RECOVERY_MANIFEST_SHA256=$(json_value "$POLICY" recovery_manifest_sha256)
EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256=$(json_value "$POLICY" recovery_directory_manifest_sha256)
EXPECTED_REMOVAL_TARGET_SHA256=$(json_value "$POLICY" removal_target_sha256)

EXPECTED_MEMBER_NAMES='archive.sha256,boot.before.sha256,boot.tar,modules-active-objects.before.sha256,modules-active-stable.before.sha256,modules-active.before.sha256,modules-rollback.before.sha256,modules.tar,packages.before.txt,pkgtools.tar'
EXPECTED_MEMBERS=$'archive.sha256\tf\nboot.before.sha256\tf\nboot.tar\tf\nmodules-active-objects.before.sha256\tf\nmodules-active-stable.before.sha256\tf\nmodules-active.before.sha256\tf\nmodules-rollback.before.sha256\tf\nmodules.tar\tf\npackages.before.txt\tf\npkgtools.tar\tf'
MEMBERS=(
    archive.sha256
    boot.before.sha256
    boot.tar
    modules-active-objects.before.sha256
    modules-active-stable.before.sha256
    modules-active.before.sha256
    modules-rollback.before.sha256
    modules.tar
    packages.before.txt
    pkgtools.tar
)

REMOVAL_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-recovery-backup-authorized-removal' \
        "accepted_release_archive_sha256=$EXPECTED_ACCEPTED_RELEASE_ARCHIVE_SHA256" \
        "accepted_release_record_sha256=$ACCEPTED_RELEASE_SHA256" \
        "accepted_release_review_script_sha256=$STEP109_SCRIPT_SHA256" \
        "accepted_release_review_policy_sha256=$STEP109_POLICY_SHA256" \
        "removal_policy_sha256=$POLICY_SHA256" \
        "removal_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "accepted_boot_id=$EXPECTED_BOOT_ID" \
        "recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH" \
        "recovery_directory_manifest_sha256=$EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256" \
        "removal_target_sha256=$EXPECTED_REMOVAL_TARGET_SHA256" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_RELEASE_SHA256 == "$EXPECTED_ACCEPTED_RELEASE_RECORD_SHA256" \
    && $STEP109_SCRIPT_SHA256 == "$EXPECTED_STEP109_SCRIPT_SHA256" \
    && $STEP109_POLICY_SHA256 == "$EXPECTED_STEP109_POLICY_SHA256" \
    && $(json_value "$ACCEPTED_RELEASE" accepted) == true \
    && $(json_value "$ACCEPTED_RELEASE" release_review_passed) == true \
    && $(json_value "$ACCEPTED_RELEASE" recovery_backup_retained) == true \
    && $(json_value "$ACCEPTED_RELEASE" recovery_backup_removal_authorized) == true \
    && $(json_value "$ACCEPTED_RELEASE" removal_executed) == false \
    && $(json_value "$ACCEPTED_RELEASE" archive_sha256) == "$EXPECTED_ACCEPTED_RELEASE_ARCHIVE_SHA256" \
    && $(json_value "$ACCEPTED_RELEASE" removal_target_sha256) == "$EXPECTED_REMOVAL_TARGET_SHA256" \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" removal_execution_authorized) == true \
    && $(json_value "$POLICY" recovery_backup_mutation_authorized) == true \
    && $(json_value "$POLICY" recursive_removal_authorized) == false \
    && $(json_value "$POLICY" glob_removal_authorized) == false ]]; then
    pass "the accepted step-109 release authorization, exact removal code, and exact reviewed target are immutably bound"
else
    fail "the destructive removal boundary does not match the accepted step-109 authorization"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_RELEASE_EVIDENCE_SHA256 == "$EXPECTED_ACCEPTED_RELEASE_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_RECOVERY_BACKUP_PATH == "$EXPECTED_RECOVERY_BACKUP_PATH" \
    && $CONFIRM_REMOVAL_TARGET_SHA256 == "$EXPECTED_REMOVAL_TARGET_SHA256" \
    && $CONFIRM_REMOVAL_SCOPE_SHA256 == "$REMOVAL_SCOPE_SHA256" ]]; then
    pass "the explicit host, evidence, kernels, recovery path, removal target, and removal scope confirmations match"
else
    fail "one or more explicit destructive-removal confirmations do not match"
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

if [[ $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $RUNNING_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CURRENT_BOOT_ID == "$EXPECTED_BOOT_ID" \
    && -n $PKGDB && -d $PKGDB && ! -L $PKGDB ]]; then
    pass "the same successfully verified 5.15.209 boot remains active before removal"
else
    fail "the host, running kernel, boot identity, or package database drifted before removal"
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

capture_system_state() {
    local phase=$1
    capture_packages "$WORKDIR/packages.$phase.txt" || true
    capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.$phase.sha256" || true
    capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.$phase.txt" || true
    capture_boot_state "$WORKDIR/boot-state.$phase.txt"
    cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.$phase" 2>/dev/null || true
}

capture_system_state before
capture_recovery_hashes "$WORKDIR/recovery.before.sha256" || true
capture_recovery_directory_members "$WORKDIR/recovery-directory-members.before.txt" || true
capture_recovery_directory_manifest "$WORKDIR/recovery-directory-manifest.before.sha256" || true

if [[ -s $WORKDIR/packages.before.txt \
    && -s $WORKDIR/modules-active-objects.before.sha256 \
    && -s $WORKDIR/boot-state.before.txt \
    && -s $WORKDIR/elilo.conf.before \
    && -s $WORKDIR/recovery.before.sha256 \
    && -s $WORKDIR/recovery-directory-members.before.txt \
    && -s $WORKDIR/recovery-directory-manifest.before.sha256 ]]; then
    pass "the complete system and ten-file recovery state was captured before destructive removal"
else
    fail "one or more required pre-removal state captures are incomplete"
fi

if [[ $(sha_file "$WORKDIR/packages.before.txt") == "$EXPECTED_PACKAGE_SHA256" \
    && $(sha_file "$WORKDIR/modules-active-objects.before.sha256") == "$EXPECTED_ACTIVE_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/modules-rollback-objects.before.txt") == "$EXPECTED_ROLLBACK_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/boot-state.before.txt") == "$EXPECTED_BOOT_STATE_SHA256" \
    && $(sha_file "$WORKDIR/elilo.conf.before") == "$EXPECTED_ELILO_SHA256" ]]; then
    pass "the accepted package, module, rollback-absence, ELILO, and boot baselines remain intact before removal"
else
    fail "system state differs from the accepted post-reboot baseline before removal"
fi

ACTUAL_MEMBERS=$(cat "$WORKDIR/recovery-directory-members.before.txt")
if [[ $ACTUAL_MEMBERS == "$EXPECTED_MEMBERS" ]]; then
    pass "the recovery directory still contains exactly the ten authorized regular files"
else
    fail "the recovery directory member set or file types differ from the authorized target"
fi

if [[ $(sha_file "$WORKDIR/recovery-directory-manifest.before.sha256") == "$EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256" \
    && $(sha_file "$WORKDIR/recovery.before.sha256") == "$EXPECTED_RECOVERY_MANIFEST_SHA256" ]] \
    && cmp -s -- "$EXPECTED_RECOVERY_BACKUP_PATH/archive.sha256" "$WORKDIR/recovery.before.sha256"; then
    pass "all ten recovery files and the three payload archive hashes match the accepted removal target"
else
    fail "the retained recovery data no longer matches the accepted removal target"
fi

expected_parent=/var/lib/slack-update/elilo-cleanup-backups
resolved_parent=$(readlink -f -- "$expected_parent" 2>/dev/null || true)
resolved_backup=$(readlink -f -- "$EXPECTED_RECOVERY_BACKUP_PATH" 2>/dev/null || true)
if [[ $resolved_parent == "$expected_parent" \
    && -d $expected_parent && ! -L $expected_parent \
    && $resolved_backup == "$EXPECTED_RECOVERY_BACKUP_PATH" \
    && -d $EXPECTED_RECOVERY_BACKUP_PATH && ! -L $EXPECTED_RECOVERY_BACKUP_PATH \
    && ${EXPECTED_RECOVERY_BACKUP_PATH%/*} == "$expected_parent" \
    && ${EXPECTED_RECOVERY_BACKUP_PATH##*/} == "5.15.19-20260815T160020Z" ]]; then
    pass "the destructive target is the exact non-symlink recovery directory under the protected parent"
else
    fail "the recovery path or protected parent is not the exact reviewed destructive target"
fi

if [[ $FAIL_COUNT -eq 0 ]]; then
    REMOVAL_STARTED=true
    printf '%s\n' "${MEMBERS[@]}" > "$WORKDIR/removal-order.txt"
    for name in "${MEMBERS[@]}"; do
        path="$EXPECTED_RECOVERY_BACKUP_PATH/$name"
        if [[ -f $path && ! -L $path ]]; then
            expected_member_sha256=$(json_map_value "$POLICY" recovery_member_hashes "$name")
            if [[ $(sha_file "$path") != "$expected_member_sha256" ]]; then
                fail "reviewed recovery member hash changed immediately before unlink: $name"
                break
            fi
            if unlink -- "$path"; then
                REMOVED_COUNT=$((REMOVED_COUNT + 1))
            else
                fail "unlink failed for reviewed recovery member: $name"
                break
            fi
        else
            fail "reviewed recovery member changed immediately before unlink: $name"
            break
        fi
    done

    if [[ $FAIL_COUNT -eq 0 && $REMOVED_COUNT -eq ${#MEMBERS[@]} ]]; then
        if rmdir -- "$EXPECTED_RECOVERY_BACKUP_PATH"; then
            REMOVAL_EXECUTED=true
            RECOVERY_BACKUP_REMOVED=true
            RECOVERY_BACKUP_RETAINED=false
            pass "the ten exact recovery files and only their now-empty reviewed directory were removed"
        else
            fail "all ten reviewed files were unlinked but the exact recovery directory could not be removed"
        fi
    else
        skip "recovery directory removal was not attempted because exact-file unlinking did not complete"
    fi
else
    skip "destructive recovery removal was withheld because the pre-removal boundary has failures"
fi

capture_system_state after
if [[ -e $EXPECTED_RECOVERY_BACKUP_PATH || -L $EXPECTED_RECOVERY_BACKUP_PATH ]]; then
    printf 'present\n' > "$WORKDIR/recovery-path.after.txt"
else
    printf 'absent\n' > "$WORKDIR/recovery-path.after.txt"
fi

if cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt" \
    && cmp -s -- "$WORKDIR/modules-active-objects.before.sha256" "$WORKDIR/modules-active-objects.after.sha256" \
    && cmp -s -- "$WORKDIR/modules-rollback-objects.before.txt" "$WORKDIR/modules-rollback-objects.after.txt" \
    && cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt" \
    && cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after"; then
    SYSTEM_STATE_PRESERVED=true
    pass "package, ELILO, boot, active modules, and rollback-absence state remained unchanged across recovery removal"
else
    fail "system state changed while removing the recovery backup"
fi

if [[ $REMOVAL_EXECUTED == true \
    && $RECOVERY_BACKUP_REMOVED == true \
    && $RECOVERY_BACKUP_RETAINED == false \
    && $SYSTEM_STATE_PRESERVED == true \
    && ! -e $EXPECTED_RECOVERY_BACKUP_PATH \
    && ! -L $EXPECTED_RECOVERY_BACKUP_PATH \
    && $REMOVED_COUNT -eq 10 \
    && $FAIL_COUNT -eq 0 ]]; then
    PAUSE_SAFE=true
    NEXT_STAGE=elilo-oldkernel-cleanup-recovery-backup-post-removal-verification
    pass "the authorized recovery-backup removal is committed and the machine is at a safe post-removal boundary"
else
    PAUSE_SAFE=false
    NEXT_STAGE=manual-review-required
    if [[ $REMOVAL_STARTED == true ]]; then
        fail "the destructive removal did not reach the complete reviewed post-removal boundary"
    else
        skip "no recovery data was removed because the destructive boundary was not entered"
    fi
fi

cat > "$WORKDIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-recovery-backup-authorized-removal
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_release_archive_sha256=$EXPECTED_ACCEPTED_RELEASE_ARCHIVE_SHA256
accepted_release_record_sha256=$ACCEPTED_RELEASE_SHA256
accepted_release_review_script_sha256=$STEP109_SCRIPT_SHA256
accepted_release_review_policy_sha256=$STEP109_POLICY_SHA256
removal_script_sha256=$SCRIPT_SHA256
removal_policy_sha256=$POLICY_SHA256
removal_scope_sha256=$REMOVAL_SCOPE_SHA256
removal_target_sha256=$EXPECTED_REMOVAL_TARGET_SHA256
accepted_boot_id=$EXPECTED_BOOT_ID
current_boot_id=$CURRENT_BOOT_ID
recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH
recovery_directory_manifest_sha256=$EXPECTED_RECOVERY_DIRECTORY_MANIFEST_SHA256
removal_started=$REMOVAL_STARTED
removed_file_count=$REMOVED_COUNT
removal_executed=$REMOVAL_EXECUTED
recovery_backup_removed=$RECOVERY_BACKUP_REMOVED
recovery_backup_retained=$RECOVERY_BACKUP_RETAINED
system_state_preserved=$SYSTEM_STATE_PRESERVED
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-${TIMESTAMP}.tar.gz"
SIDECAR="$ARCHIVE.sha256"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" -- "$(basename "$WORKDIR")"
printf '%s  %s\n' "$(sha_file "$ARCHIVE")" "$(basename "$ARCHIVE")" > "$SIDECAR"
chmod 0600 -- "$ARCHIVE" "$SIDECAR"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$(sha_file "$ARCHIVE")"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' "$ARCHIVE" "$(basename "$ARCHIVE")" "$SIDECAR" "$(basename "$SIDECAR")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$SIDECAR")"
printf 'Result: %s (%d passes, %d failures, %d skips); removal_executed=%s; recovery_backup_removed=%s; recovery_backup_retained=%s; system_state_preserved=%s; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" "$REMOVAL_EXECUTED" "$RECOVERY_BACKUP_REMOVED" "$RECOVERY_BACKUP_RETAINED" "$SYSTEM_STATE_PRESERVED" "$PAUSE_SAFE" "$NEXT_STAGE"
if [[ $FAIL_COUNT -eq 0 ]]; then
    printf 'Next action: preserve this evidence; no immediate follow-up is required before a safe pause.\n'
else
    printf 'Next action: do not mutate packages, ELILO, boot files, or recovery paths; review this evidence before any further action.\n'
fi

[[ $FAIL_COUNT -eq 0 ]]
