#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-apply-reboot-review-policy.json"
ACCEPTED_APPLY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-20260815-accepted.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_APPLY_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_RECOVERY_BACKUP_PATH=""
CONFIRM_REVIEW_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-post-apply-reboot-review.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-apply-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-recovery-backup-path ABSOLUTE_PATH \
    --confirm-review-scope-sha256 SHA256

This stage is read-only with respect to packages and boot state. A successful
review authorizes only a later manual reboot; it never executes that reboot.
USAGE
}

while (($#)); do
    case "$1" in
        --target)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            TARGET=$2
            shift 2
            ;;
        --confirm-hostname-fqdn)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CONFIRM_HOSTNAME_FQDN=$2
            shift 2
            ;;
        --confirm-apply-evidence-sha256)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CONFIRM_APPLY_EVIDENCE_SHA256=$2
            shift 2
            ;;
        --confirm-active-kernel)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CONFIRM_ACTIVE_KERNEL=$2
            shift 2
            ;;
        --confirm-rollback-kernel)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CONFIRM_ROLLBACK_KERNEL=$2
            shift 2
            ;;
        --confirm-recovery-backup-path)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CONFIRM_RECOVERY_BACKUP_PATH=$2
            shift 2
            ;;
        --confirm-review-scope-sha256)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CONFIRM_REVIEW_SCOPE_SHA256=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance review must run as root.\n' >&2
    exit 2
fi

for value in \
    "$TARGET" \
    "$CONFIRM_HOSTNAME_FQDN" \
    "$CONFIRM_APPLY_EVIDENCE_SHA256" \
    "$CONFIRM_ACTIVE_KERNEL" \
    "$CONFIRM_ROLLBACK_KERNEL" \
    "$CONFIRM_RECOVERY_BACKUP_PATH" \
    "$CONFIRM_REVIEW_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done

[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_APPLY_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid apply evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_REVIEW_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid review scope SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_RECOVERY_BACKUP_PATH == /* ]] || { printf 'ERROR: recovery backup confirmation must be absolute.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS: %s\n' "$*"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf 'FAIL: %s\n' "$*"
}

skip() {
    SKIP_COUNT=$((SKIP_COUNT + 1))
    printf 'SKIP: %s\n' "$*"
}

sha_file() {
    sha256sum -- "$1" | awk '{print $1}'
}

json_value() {
    local file=$1
    local path=$2
    python3 - "$file" "$path" <<'PY'
import json
import sys

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

if [[ ! -f $0 || -L $0 || ! -f $POLICY || -L $POLICY || ! -f $ACCEPTED_APPLY || -L $ACCEPTED_APPLY ]]; then
    fail "the review script, post-apply policy, or accepted step-105 record is missing or unsafe"
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-post-apply-reboot-review
WORKDIR="$EVIDENCE_PARENT/${TARGET}-${TIMESTAMP}"
mkdir -p -- "$WORKDIR"
chmod 0700 -- "$WORKDIR"
ASSERTIONS_LOG="$WORKDIR/assertions.log"
: > "$ASSERTIONS_LOG"

# Mirror all review assertions into the evidence log.
exec 3>&1
pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3
}
fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf 'FAIL: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3
}
skip() {
    SKIP_COUNT=$((SKIP_COUNT + 1))
    printf 'SKIP: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3
}

SCRIPT_SHA256=$(sha_file "$0")
POLICY_SHA256=$(sha_file "$POLICY")
ACCEPTED_APPLY_SHA256=$(sha_file "$ACCEPTED_APPLY")
EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_APPLY_RECORD_SHA256=$(json_value "$POLICY" accepted_apply_record_sha256)
EXPECTED_APPLY_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_apply_archive_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" hostname_fqdn)
EXPECTED_ACTIVE_KERNEL=$(json_value "$POLICY" active_kernel)
EXPECTED_ROLLBACK_KERNEL=$(json_value "$POLICY" rollback_kernel)
EXPECTED_RECOVERY_BACKUP_PATH=$(json_value "$POLICY" recovery_backup_path)
EXPECTED_PACKAGE_SNAPSHOT_SHA256=$(json_value "$POLICY" post_package_snapshot_sha256)
EXPECTED_ACTIVE_MODULE_OBJECTS_SHA256=$(json_value "$POLICY" active_module_object_manifest_sha256)

REVIEW_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-post-apply-reboot-review' \
        "accepted_apply_archive_sha256=$EXPECTED_APPLY_ARCHIVE_SHA256" \
        "accepted_apply_record_sha256=$ACCEPTED_APPLY_SHA256" \
        "review_policy_sha256=$POLICY_SHA256" \
        "review_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_APPLY_SHA256 == "$EXPECTED_APPLY_RECORD_SHA256" \
    && $(json_value "$ACCEPTED_APPLY" accepted) == true \
    && $(json_value "$ACCEPTED_APPLY" apply_committed) == true \
    && $(json_value "$ACCEPTED_APPLY" archive_sha256) == "$EXPECTED_APPLY_ARCHIVE_SHA256" \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" reboot_review_authorized) == true \
    && $(json_value "$POLICY" reboot_execution_authorized) == false ]]; then
    pass "the accepted committed step-105 cleanup, exact review code, and reboot-review policy are bound"
else
    fail "the accepted committed step-105 cleanup, review code, or reboot-review policy does not match"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_APPLY_EVIDENCE_SHA256 == "$EXPECTED_APPLY_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_RECOVERY_BACKUP_PATH == "$EXPECTED_RECOVERY_BACKUP_PATH" \
    && $CONFIRM_REVIEW_SCOPE_SHA256 == "$REVIEW_SCOPE_SHA256" ]]; then
    pass "the explicit host, evidence, kernel, recovery-backup, and review-scope confirmations match"
else
    fail "one or more explicit confirmations do not match the reviewed post-apply boundary"
fi

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
RUNNING_KERNEL=$(uname -r 2>/dev/null || true)

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

if [[ $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $RUNNING_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && -n $PKGDB && -d $PKGDB && ! -L $PKGDB ]]; then
    pass "the live host is still running 5.15.209 and the canonical package database is available"
else
    fail "the live hostname, running kernel, or canonical package database changed before reboot review"
fi

capture_packages() {
    local output=$1
    if [[ -z $PKGDB || ! -d $PKGDB ]]; then
        : > "$output"
        return 1
    fi
    find "$PKGDB" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | sort > "$output"
}

capture_module_objects() {
    local module_dir=$1
    local output=$2
    if [[ ! -d $module_dir ]]; then
        : > "$output"
        return 1
    fi
    (
        cd -- "$module_dir" || exit 1
        find . -type f -name '*.ko' -print0 \
            | sort -z \
            | xargs -0 -r sha256sum
    ) > "$output"
}

capture_rollback_objects() {
    local module_dir=$1
    local output=$2
    if [[ ! -d $module_dir ]]; then
        : > "$output"
        return 0
    fi
    (
        cd -- "$module_dir" || exit 1
        find . -type f \( -name '*.ko' -o -name '*.ko.*' \) -print | sort
    ) > "$output"
}

capture_boot_state() {
    local output=$1
    local path
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
    local output=$1
    local name
    : > "$output"
    if [[ ! -d $EXPECTED_RECOVERY_BACKUP_PATH || -L $EXPECTED_RECOVERY_BACKUP_PATH ]]; then
        return 1
    fi
    for name in boot.tar modules.tar pkgtools.tar; do
        if [[ ! -f $EXPECTED_RECOVERY_BACKUP_PATH/$name || -L $EXPECTED_RECOVERY_BACKUP_PATH/$name ]]; then
            return 1
        fi
        printf '%s  %s\n' "$(sha_file "$EXPECTED_RECOVERY_BACKUP_PATH/$name")" "$name" >> "$output"
    done
}

capture_packages "$WORKDIR/packages.before.txt" || true
capture_module_objects "/lib/modules/$EXPECTED_ACTIVE_KERNEL" "$WORKDIR/modules-active-objects.before.sha256" || true
capture_rollback_objects "/lib/modules/$EXPECTED_ROLLBACK_KERNEL" "$WORKDIR/modules-rollback-objects.before.txt" || true
capture_boot_state "$WORKDIR/boot-state.before.txt"
capture_recovery_hashes "$WORKDIR/recovery.before.sha256" || true
cp -p -- /boot/efi/EFI/Slackware/elilo.conf "$WORKDIR/elilo.conf.before" 2>/dev/null || true

if [[ -s $WORKDIR/packages.before.txt \
    && -s $WORKDIR/modules-active-objects.before.sha256 \
    && -s $WORKDIR/boot-state.before.txt \
    && -s $WORKDIR/recovery.before.sha256 \
    && -s $WORKDIR/elilo.conf.before ]]; then
    pass "the package, ELILO, boot, module, and retained recovery state were captured before reboot review"
else
    fail "one or more required pre-review state captures are incomplete"
fi

PACKAGE_SHA256=$(sha_file "$WORKDIR/packages.before.txt")
ACTIVE_MODULE_OBJECTS_SHA256=$(sha_file "$WORKDIR/modules-active-objects.before.sha256")

active_packages_ok=true
for package in \
    kernel-generic-5.15.209-x86_64-1 \
    kernel-huge-5.15.209-x86_64-1 \
    kernel-modules-5.15.209-x86_64-1; do
    grep -Fxq -- "$package" "$WORKDIR/packages.before.txt" || active_packages_ok=false
done
rollback_packages_absent=true
for package in \
    kernel-generic-5.15.19-x86_64-2 \
    kernel-huge-5.15.19-x86_64-2 \
    kernel-modules-5.15.19-x86_64-2; do
    if grep -Fxq -- "$package" "$WORKDIR/packages.before.txt"; then
        rollback_packages_absent=false
    fi
done

if [[ $PACKAGE_SHA256 == "$EXPECTED_PACKAGE_SNAPSHOT_SHA256" \
    && $active_packages_ok == true \
    && $rollback_packages_absent == true ]]; then
    pass "the exact post-cleanup package database is unchanged and contains only the active boot-kernel triple"
else
    fail "the installed package database drifted from the accepted committed cleanup"
fi

EXPECTED_KERNEL_SHA256=7a001bd59a0a86567e18798bfa4951dc5ef916004d92daed9a1e532eff04a2a9
EXPECTED_INITRD_SHA256=777c8d971342b15c9d5ece42d26e869b8d804ac37a17044113aae18aa51124df
boot_artifacts_ok=true
for pair in \
    "/boot/vmlinuz-generic-5.15.209:$EXPECTED_KERNEL_SHA256" \
    "/boot/initrd-generic-5.15.209.gz:$EXPECTED_INITRD_SHA256" \
    "/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209:$EXPECTED_KERNEL_SHA256" \
    "/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz:$EXPECTED_INITRD_SHA256"; do
    path=${pair%%:*}
    expected=${pair#*:}
    if [[ ! -f $path || -L $path || $(sha_file "$path" 2>/dev/null || true) != "$expected" ]]; then
        boot_artifacts_ok=false
    fi
done

elilo_ok=false
if [[ -f /boot/efi/EFI/Slackware/elilo.conf && ! -L /boot/efi/EFI/Slackware/elilo.conf ]]; then
    if python3 - /boot/efi/EFI/Slackware/elilo.conf "$EXPECTED_ACTIVE_KERNEL" "$EXPECTED_ROLLBACK_KERNEL" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
active = sys.argv[2]
rollback = sys.argv[3]
raw = path.read_text(encoding="utf-8", errors="strict")
lines = []
for original in raw.splitlines():
    line = original.split("#", 1)[0].strip()
    if line:
        lines.append(line)
joined = "\n".join(lines).lower()
if "oldkernel" in joined or rollback.lower() in joined:
    raise SystemExit(1)
def clean_value(value):
    value = value.strip().strip('"').strip("'")
    return value.replace("\\", "/")

def basename(value):
    return clean_value(value).rstrip("/").split("/")[-1]

def entries(key):
    prefix = key.lower() + "="
    return [line.split("=", 1)[1].strip() for line in lines if line.lower().startswith(prefix)]
images = entries("image")
initrds = entries("initrd")
labels = entries("label")
defaults = entries("default")
if len(images) != 1 or basename(images[0]) != f"vmlinuz-generic-{active}":
    raise SystemExit(1)
if len(initrds) != 1 or basename(initrds[0]) != f"initrd-generic-{active}.gz":
    raise SystemExit(1)
if len(labels) != 1 or len(defaults) != 1:
    raise SystemExit(1)
if clean_value(labels[0]) != clean_value(defaults[0]):
    raise SystemExit(1)
PY
    then
        elilo_ok=true
    fi
fi

if [[ $boot_artifacts_ok == true && $elilo_ok == true ]]; then
    pass "the active 5.15.209 ELILO configuration and all four reviewed boot artifacts are reboot-ready"
else
    fail "the active ELILO configuration or reviewed 5.15.209 boot artifacts are not reboot-ready"
fi

rollback_objects_absent=true
if [[ -s $WORKDIR/modules-rollback-objects.before.txt ]]; then
    rollback_objects_absent=false
fi
rollback_boot_absent=true
for path in \
    /boot/vmlinuz-generic-5.15.19 \
    /boot/efi/EFI/Slackware/vmlinuz \
    /boot/efi/EFI/Slackware/initrd.gz; do
    [[ ! -e $path && ! -L $path ]] || rollback_boot_absent=false
done
survivors_absent=true
for path in \
    /lib/modules/5.15.19/misc/vboxguest.ko \
    /lib/modules/5.15.19/misc/vboxsf.ko \
    /lib/modules/5.15.19/misc/vboxvideo.ko; do
    [[ ! -e $path && ! -L $path ]] || survivors_absent=false
done

if [[ $rollback_objects_absent == true \
    && $rollback_boot_absent == true \
    && $survivors_absent == true ]]; then
    pass "rollback package boot artifacts and all rollback module objects remain absent after committed cleanup"
else
    fail "rollback boot artifacts or rollback module objects reappeared before reboot review"
fi

if [[ $ACTIVE_MODULE_OBJECTS_SHA256 == "$EXPECTED_ACTIVE_MODULE_OBJECTS_SHA256" ]]; then
    pass "the complete active 5.15.209 kernel-module object manifest remains byte-identical to accepted step 105"
else
    fail "the active 5.15.209 kernel-module object manifest drifted after the committed cleanup"
fi

recovery_ok=true
if [[ ! -d $EXPECTED_RECOVERY_BACKUP_PATH || -L $EXPECTED_RECOVERY_BACKUP_PATH ]]; then
    recovery_ok=false
fi
while read -r expected name; do
    [[ -n ${expected:-} && -n ${name:-} ]] || continue
    path="$EXPECTED_RECOVERY_BACKUP_PATH/$name"
    if [[ ! -f $path || -L $path || $(sha_file "$path" 2>/dev/null || true) != "$expected" ]]; then
        recovery_ok=false
    fi
done <<'RECOVERY'
ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85 boot.tar
ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781 modules.tar
50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f pkgtools.tar
RECOVERY

if [[ $recovery_ok == true ]]; then
    pass "the exact private recovery snapshot is still retained and hash-valid before reboot"
else
    fail "the retained private recovery snapshot is missing, unsafe, or hash-invalid"
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
    pass "the reboot review did not modify packages, ELILO, boot artifacts, module objects, or recovery archives"
else
    fail "review-sensitive system state changed while the non-mutating reboot review was running"
fi

REBOOT_READY=false
REBOOT_AUTHORIZED=false
PAUSE_SAFE=false
NEXT_STAGE=manual-review-required
if [[ $FAIL_COUNT -eq 0 ]]; then
    REBOOT_READY=true
    REBOOT_AUTHORIZED=true
    PAUSE_SAFE=true
    NEXT_STAGE=elilo-oldkernel-cleanup-manual-reboot
    pass "one normal manual reboot is authorized while the retained recovery snapshot remains protected"
else
    skip "manual reboot authorization is withheld because the post-apply review has failures"
fi

cat > "$WORKDIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-post-apply-reboot-review
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_apply_archive_sha256=$EXPECTED_APPLY_ARCHIVE_SHA256
accepted_apply_record_sha256=$ACCEPTED_APPLY_SHA256
review_script_sha256=$SCRIPT_SHA256
review_policy_sha256=$POLICY_SHA256
review_scope_sha256=$REVIEW_SCOPE_SHA256
recovery_backup_path=$EXPECTED_RECOVERY_BACKUP_PATH
recovery_backup_retained=$recovery_ok
reboot_ready=$REBOOT_READY
reboot_authorized=$REBOOT_AUTHORIZED
reboot_executed=false
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-post-apply-reboot-review-${TIMESTAMP}.tar.gz"
SIDECAR="$ARCHIVE.sha256"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" -- "$(basename "$WORKDIR")"
printf '%s  %s\n' "$(sha_file "$ARCHIVE")" "$(basename "$ARCHIVE")" > "$SIDECAR"
chmod 0600 -- "$ARCHIVE" "$SIDECAR"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$(sha_file "$ARCHIVE")"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
    "$ARCHIVE" "$(basename "$ARCHIVE")" "$SIDECAR" "$(basename "$SIDECAR")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$SIDECAR")"
printf 'Result: %s (%d passes, %d failures, %d skips); reboot_ready=%s; reboot_authorized=%s; reboot_executed=false; recovery_backup_retained=%s; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" \
    "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
    "$REBOOT_READY" "$REBOOT_AUTHORIZED" "$recovery_ok" "$PAUSE_SAFE" "$NEXT_STAGE"

if [[ $FAIL_COUNT -eq 0 ]]; then
    printf 'Next action: do not modify packages, ELILO, boot files, or the retained recovery backup; perform only the separately reviewed manual reboot after this evidence is accepted.\n'
    exit 0
fi

printf 'Next action: do not reboot; review the failed post-apply boundary first.\n'
exit 1
