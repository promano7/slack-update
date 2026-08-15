#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-reboot-verification-policy.json"
ACCEPTED_REBOOT_REVIEW="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-apply-reboot-review-20260815-accepted.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_RECOVERY_BACKUP_PATH=""
CONFIRM_VERIFICATION_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-post-reboot-verification.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-reboot-review-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-recovery-backup-path ABSOLUTE_PATH \
    --confirm-verification-scope-sha256 SHA256

This stage is read-only. It verifies that the accepted ELILO cleanup survived
an authorized manual reboot. It never removes the retained recovery backup.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-reboot-review-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-active-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
        --confirm-rollback-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
        --confirm-recovery-backup-path) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_RECOVERY_BACKUP_PATH=$2; shift 2 ;;
        --confirm-verification-scope-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_VERIFICATION_SCOPE_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance verification must run as root.\n' >&2
    exit 2
fi

for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_RECOVERY_BACKUP_PATH" "$CONFIRM_VERIFICATION_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done

[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid reboot-review evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_VERIFICATION_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid verification scope SHA-256.\n' >&2; exit 2; }
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

if [[ ! -f $0 || -L $0 || ! -f $POLICY || -L $POLICY || ! -f $ACCEPTED_REBOOT_REVIEW || -L $ACCEPTED_REBOOT_REVIEW ]]; then
    fail "the verification script, post-reboot policy, or accepted step-106 record is missing or unsafe"
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-post-reboot-verification
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
ACCEPTED_REBOOT_REVIEW_SHA256=$(sha_file "$ACCEPTED_REBOOT_REVIEW")
EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_RECORD_SHA256=$(json_value "$POLICY" accepted_reboot_review_record_sha256)
EXPECTED_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_reboot_review_archive_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" hostname_fqdn)
EXPECTED_ACTIVE_KERNEL=$(json_value "$POLICY" active_kernel)
EXPECTED_ROLLBACK_KERNEL=$(json_value "$POLICY" rollback_kernel)
EXPECTED_RECOVERY_BACKUP_PATH=$(json_value "$POLICY" recovery_backup_path)
EXPECTED_REVIEW_EPOCH=$(json_value "$POLICY" accepted_reboot_review_epoch)
EXPECTED_PACKAGE_SHA256=$(json_value "$POLICY" post_package_snapshot_sha256)
EXPECTED_ACTIVE_MODULES_SHA256=$(json_value "$POLICY" active_module_object_manifest_sha256)
EXPECTED_BOOT_STATE_SHA256=$(json_value "$POLICY" boot_state_sha256)
EXPECTED_ELILO_SHA256=$(json_value "$POLICY" elilo_conf_sha256)
EXPECTED_KERNEL_SHA256=$(json_value "$POLICY" active_kernel_sha256)
EXPECTED_INITRD_SHA256=$(json_value "$POLICY" active_initrd_sha256)

VERIFICATION_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-post-reboot-verification' \
        "accepted_reboot_review_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_reboot_review_record_sha256=$ACCEPTED_REBOOT_REVIEW_SHA256" \
        "verification_policy_sha256=$POLICY_SHA256" \
        "verification_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_REBOOT_REVIEW_SHA256 == "$EXPECTED_RECORD_SHA256" \
    && $(json_value "$ACCEPTED_REBOOT_REVIEW" accepted) == true \
    && $(json_value "$ACCEPTED_REBOOT_REVIEW" reboot_authorized) == true \
    && $(json_value "$ACCEPTED_REBOOT_REVIEW" reboot_executed) == false \
    && $(json_value "$ACCEPTED_REBOOT_REVIEW" archive_sha256) == "$EXPECTED_ARCHIVE_SHA256" \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" post_reboot_verification_authorized) == true \
    && $(json_value "$POLICY" recovery_backup_removal_authorized) == false ]]; then
    pass "the accepted step-106 reboot authorization, exact verification code, and post-reboot policy are bound"
else
    fail "the accepted reboot authorization or post-reboot verification boundary does not match"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256 == "$EXPECTED_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_RECOVERY_BACKUP_PATH == "$EXPECTED_RECOVERY_BACKUP_PATH" \
    && $CONFIRM_VERIFICATION_SCOPE_SHA256 == "$VERIFICATION_SCOPE_SHA256" ]]; then
    pass "the explicit host, evidence, kernel, recovery-backup, and verification-scope confirmations match"
else
    fail "one or more explicit confirmations do not match the reviewed post-reboot boundary"
fi

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
RUNNING_KERNEL=$(uname -r 2>/dev/null || true)
CMDLINE=$(cat /proc/cmdline 2>/dev/null || true)
BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)
BOOT_EPOCH=$(awk '$1 == "btime" {print $2; exit}' /proc/stat 2>/dev/null || true)
PKGDB=""
for candidate in /var/lib/pkgtools/packages /var/log/packages; do
    if [[ -d $candidate ]]; then
        resolved=$(readlink -f -- "$candidate" 2>/dev/null || true)
        if [[ -n $resolved && -d $resolved ]]; then PKGDB=$resolved; break; fi
    fi
done
printf '%s\n' "$CMDLINE" > "$WORKDIR/proc-cmdline.txt"
printf '%s\n' "$BOOT_ID" > "$WORKDIR/boot-id.txt"
printf '%s\n' "$BOOT_EPOCH" > "$WORKDIR/boot-epoch.txt"

if [[ $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $RUNNING_KERNEL == "$EXPECTED_ACTIVE_KERNEL" && -n $PKGDB && -d $PKGDB && ! -L $PKGDB ]]; then
    pass "the rebooted host is running the exact active 5.15.209 kernel with the canonical package database available"
else
    fail "the hostname, running kernel, or package database is wrong after reboot"
fi

if [[ $BOOT_EPOCH =~ ^[0-9]+$ && $EXPECTED_REVIEW_EPOCH =~ ^[0-9]+$ && $BOOT_EPOCH -gt $EXPECTED_REVIEW_EPOCH && -n $BOOT_ID ]]; then
    pass "the current kernel boot started after the accepted step-106 reboot authorization"
else
    fail "the current boot cannot be proven to have started after step 106"
fi

if python3 - "$CMDLINE" "$EXPECTED_ACTIVE_KERNEL" "$EXPECTED_ROLLBACK_KERNEL" <<'PY'
import sys
cmdline, active, rollback = sys.argv[1:]
tokens = cmdline.split()
boot = [t.split("=", 1)[1] for t in tokens if t.startswith("BOOT_IMAGE=")]
if len(boot) != 1:
    raise SystemExit(1)
name = boot[0].replace("\\", "/").rstrip("/").split("/")[-1]
if name != f"vmlinuz-generic-{active}":
    raise SystemExit(1)
if rollback in cmdline or "oldkernel" in cmdline.lower():
    raise SystemExit(1)
PY
then
    pass "the running kernel was loaded from the exact active versioned ELILO kernel image"
else
    fail "the post-reboot kernel command line does not identify the reviewed active ELILO image"
fi

capture_packages() {
    local output=$1
    [[ -n $PKGDB && -d $PKGDB ]] || { : > "$output"; return 1; }
    find "$PKGDB" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | sort > "$output"
}
capture_module_objects() {
    local module_dir=$1 output=$2
    [[ -d $module_dir ]] || { : > "$output"; return 1; }
    (cd -- "$module_dir" && find . -type f -name '*.ko' -print0 | sort -z | xargs -0 -r sha256sum) > "$output"
}
capture_rollback_objects() {
    local module_dir=$1 output=$2
    [[ -d $module_dir ]] || { : > "$output"; return 0; }
    (cd -- "$module_dir" && find . -type f \( -name '*.ko' -o -name '*.ko.*' \) -print | sort) > "$output"
}
capture_boot_state() {
    local output=$1 path
    : > "$output"
    for path in \
        /boot/efi/EFI/Slackware/elilo.conf \
        /boot/vmlinuz-generic-5.15.209 \
        /boot/initrd-generic-5.15.209.gz \
        /boot/vmlinuz-generic-5.15.19 \
        /boot/initrd.gz \
        /boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209 \
        /boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz \
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

capture_packages "$WORKDIR/packages.before.txt" || true
capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.before.sha256" || true
capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.before.txt" || true
capture_boot_state "$WORKDIR/boot-state.before.txt"
capture_recovery_hashes "$WORKDIR/recovery.before.sha256" || true
cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.before" 2>/dev/null || true

if [[ -s $WORKDIR/packages.before.txt && -s $WORKDIR/modules-active-objects.before.sha256 && -s $WORKDIR/boot-state.before.txt && -s $WORKDIR/recovery.before.sha256 && -s $WORKDIR/elilo.conf.before ]]; then
    pass "the complete package, ELILO, boot, module, recovery, and running-boot state was captured after reboot"
else
    fail "one or more required post-reboot state captures are incomplete"
fi

if [[ $(sha_file "$WORKDIR/packages.before.txt") == "$EXPECTED_PACKAGE_SHA256" ]]; then
    pass "the exact committed post-cleanup package database survived the reboot"
else
    fail "the installed package database drifted across the reboot"
fi

boot_artifacts_ok=true
for pair in \
    "/boot/vmlinuz-generic-5.15.209:$EXPECTED_KERNEL_SHA256" \
    "/boot/initrd-generic-5.15.209.gz:$EXPECTED_INITRD_SHA256" \
    "/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209:$EXPECTED_KERNEL_SHA256" \
    "/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz:$EXPECTED_INITRD_SHA256"; do
    path=${pair%%:*}; expected=${pair#*:}
    [[ -f $path && ! -L $path && $(sha_file "$path" 2>/dev/null || true) == "$expected" ]] || boot_artifacts_ok=false
done
elilo_ok=false
if [[ -f /boot/efi/EFI/Slackware/elilo.conf && ! -L /boot/efi/EFI/Slackware/elilo.conf && $(sha_file /boot/efi/EFI/Slackware/elilo.conf) == "$EXPECTED_ELILO_SHA256" ]]; then
    if python3 - /boot/efi/EFI/Slackware/elilo.conf "$EXPECTED_ACTIVE_KERNEL" "$EXPECTED_ROLLBACK_KERNEL" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1]); active = sys.argv[2]; rollback = sys.argv[3]
lines=[]
for original in path.read_text(encoding="utf-8", errors="strict").splitlines():
    line=original.split("#",1)[0].strip()
    if line: lines.append(line)
joined="\n".join(lines).lower()
if "oldkernel" in joined or rollback.lower() in joined: raise SystemExit(1)
def clean(v): return v.strip().strip('"').strip("'").replace("\\","/")
def base(v): return clean(v).rstrip('/').split('/')[-1]
def entries(k):
    p=k.lower()+"="
    return [line.split("=",1)[1].strip() for line in lines if line.lower().startswith(p)]
images=entries("image"); initrds=entries("initrd"); labels=entries("label"); defaults=entries("default")
if len(images)!=1 or base(images[0])!=f"vmlinuz-generic-{active}": raise SystemExit(1)
if len(initrds)!=1 or base(initrds[0])!=f"initrd-generic-{active}.gz": raise SystemExit(1)
if len(labels)!=1 or len(defaults)!=1 or clean(labels[0])!=clean(defaults[0]): raise SystemExit(1)
PY
    then elilo_ok=true; fi
fi
if [[ $boot_artifacts_ok == true && $elilo_ok == true && $(sha_file "$WORKDIR/boot-state.before.txt") == "$EXPECTED_BOOT_STATE_SHA256" ]]; then
    pass "the exact active ELILO configuration and boot artifacts survived the reboot unchanged"
else
    fail "ELILO or an accepted active boot artifact drifted across the reboot"
fi

if [[ ! -s $WORKDIR/modules-rollback-objects.before.txt \
    && ! -e /boot/vmlinuz-generic-5.15.19 && ! -L /boot/vmlinuz-generic-5.15.19 \
    && ! -e /boot/efi/EFI/Slackware/vmlinuz && ! -L /boot/efi/EFI/Slackware/vmlinuz \
    && ! -e /boot/efi/EFI/Slackware/initrd.gz && ! -L /boot/efi/EFI/Slackware/initrd.gz ]]; then
    pass "rollback package boot artifacts and all rollback module objects remain absent after reboot"
else
    fail "rollback boot artifacts or rollback module objects reappeared after reboot"
fi

if [[ $(sha_file "$WORKDIR/modules-active-objects.before.sha256") == "$EXPECTED_ACTIVE_MODULES_SHA256" ]]; then
    pass "the complete active 5.15.209 kernel-module object manifest survived the reboot byte-identically"
else
    fail "the active kernel-module object manifest drifted across the reboot"
fi

recovery_ok=true
while read -r expected name; do
    [[ -n ${expected:-} && -n ${name:-} ]] || continue
    path="$EXPECTED_RECOVERY_BACKUP_PATH/$name"
    [[ -f $path && ! -L $path && $(sha_file "$path" 2>/dev/null || true) == "$expected" ]] || recovery_ok=false
done <<'RECOVERY'
ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85 boot.tar
ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781 modules.tar
50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f pkgtools.tar
RECOVERY
if [[ $recovery_ok == true && $(sha_file "$WORKDIR/recovery.before.sha256") == $(json_value "$POLICY" recovery_manifest_sha256) ]]; then
    pass "the exact private recovery snapshot remains retained and hash-valid after the successful reboot"
else
    fail "the retained recovery snapshot is missing, unsafe, or hash-invalid after reboot"
fi

capture_packages "$WORKDIR/packages.after.txt" || true
capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.after.sha256" || true
capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.after.txt" || true
capture_boot_state "$WORKDIR/boot-state.after.txt"
capture_recovery_hashes "$WORKDIR/recovery.after.sha256" || true
cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.after" 2>/dev/null || true

if cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt" \
    && cmp -s -- "$WORKDIR/modules-active-objects.before.sha256" "$WORKDIR/modules-active-objects.after.sha256" \
    && cmp -s -- "$WORKDIR/modules-rollback-objects.before.txt" "$WORKDIR/modules-rollback-objects.after.txt" \
    && cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt" \
    && cmp -s -- "$WORKDIR/recovery.before.sha256" "$WORKDIR/recovery.after.sha256" \
    && cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after"; then
    pass "the post-reboot verification did not modify packages, ELILO, boot artifacts, module objects, or recovery archives"
else
    fail "verification-sensitive system state changed while the read-only post-reboot verification was running"
fi

POST_REBOOT_VERIFIED=false
RECOVERY_BACKUP_RELEASE_READY=false
PAUSE_SAFE=false
NEXT_STAGE=manual-review-required
if [[ $FAIL_COUNT -eq 0 ]]; then
    POST_REBOOT_VERIFIED=true
    RECOVERY_BACKUP_RELEASE_READY=true
    PAUSE_SAFE=true
    NEXT_STAGE=elilo-oldkernel-cleanup-recovery-backup-release-review
    pass "the cleanup survived the authorized reboot and the retained recovery backup is eligible only for a later release review"
else
    skip "recovery-backup release review is withheld because post-reboot verification has failures"
fi

cat > "$WORKDIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-post-reboot-verification
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_reboot_review_archive_sha256=$EXPECTED_ARCHIVE_SHA256
accepted_reboot_review_record_sha256=$ACCEPTED_REBOOT_REVIEW_SHA256
verification_script_sha256=$SCRIPT_SHA256
verification_policy_sha256=$POLICY_SHA256
verification_scope_sha256=$VERIFICATION_SCOPE_SHA256
accepted_reboot_review_epoch=$EXPECTED_REVIEW_EPOCH
current_boot_epoch=$BOOT_EPOCH
current_boot_id=$BOOT_ID
recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH
post_reboot_verified=$POST_REBOOT_VERIFIED
recovery_backup_retained=$recovery_ok
recovery_backup_release_ready=$RECOVERY_BACKUP_RELEASE_READY
recovery_backup_removal_authorized=false
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-post-reboot-verification-${TIMESTAMP}.tar.gz"
SIDECAR="$ARCHIVE.sha256"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" -- "$(basename "$WORKDIR")"
printf '%s  %s\n' "$(sha_file "$ARCHIVE")" "$(basename "$ARCHIVE")" > "$SIDECAR"
chmod 0600 -- "$ARCHIVE" "$SIDECAR"
printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$(sha_file "$ARCHIVE")"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' "$ARCHIVE" "$(basename "$ARCHIVE")" "$SIDECAR" "$(basename "$SIDECAR")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$SIDECAR")"
printf 'Result: %s (%d passes, %d failures, %d skips); post_reboot_verified=%s; recovery_backup_retained=%s; recovery_backup_release_ready=%s; recovery_backup_removal_authorized=false; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" "$POST_REBOOT_VERIFIED" "$recovery_ok" "$RECOVERY_BACKUP_RELEASE_READY" "$PAUSE_SAFE" "$NEXT_STAGE"
if [[ $FAIL_COUNT -eq 0 ]]; then
    printf 'Next action: preserve the recovery backup and review this evidence before any backup removal.\n'
    exit 0
fi
printf 'Next action: preserve the recovery backup and review the failed post-reboot boundary.\n'
exit 1
