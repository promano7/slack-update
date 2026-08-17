#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-policy.json"
ACCEPTED_CLOSURE="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-destructive-boundary-closure-20260817-accepted.json"
STEP115_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-destructive-boundary-closure.sh"
STEP115_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-destructive-boundary-closure-policy.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_CLOSURE_EVIDENCE_SHA256=""
CONFIRM_ACTIVE_KERNEL=""
CONFIRM_ROLLBACK_KERNEL=""
CONFIRM_REMOVED_RECOVERY_PATH=""
CONFIRM_CHECKPOINT_SCOPE_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-elilo-oldkernel-cleanup-scenario-closure-checkpoint.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn HOSTNAME_FQDN \
    --confirm-closure-evidence-sha256 SHA256 \
    --confirm-active-kernel VERSION \
    --confirm-rollback-kernel VERSION \
    --confirm-removed-recovery-path ABSOLUTE_PATH \
    --confirm-checkpoint-scope-sha256 SHA256

This stage performs the final non-mutating scenario-closure checkpoint for the
Slackware 15.0 ELILO oldkernel cleanup. It proves that the destructive boundary
is closed, all historical destructive authorizations are consumed, the final
persistent state remains intact, no machine action is pending, and any future
work must start from a fresh review boundary.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-closure-evidence-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_CLOSURE_EVIDENCE_SHA256=$2; shift 2 ;;
        --confirm-active-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
        --confirm-rollback-kernel) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
        --confirm-removed-recovery-path) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_REMOVED_RECOVERY_PATH=$2; shift 2 ;;
        --confirm-checkpoint-scope-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_CHECKPOINT_SCOPE_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance checkpoint must run as root.\n' >&2
    exit 2
fi
for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_CLOSURE_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_REMOVED_RECOVERY_PATH" "$CONFIRM_CHECKPOINT_SCOPE_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done
[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_CLOSURE_EVIDENCE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid closure evidence SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_CHECKPOINT_SCOPE_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid checkpoint scope SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_REMOVED_RECOVERY_PATH == /* ]] || { printf 'ERROR: removed recovery path must be absolute.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
SCENARIO_CLOSURE_CHECKPOINT=false
CLEANUP_SCENARIO_CLOSED=false
DESTRUCTIVE_BOUNDARY_CLOSED=false
HISTORICAL_AUTHORIZATIONS_CONSUMED=false
PENDING_DESTRUCTIVE_ACTION=false
MACHINE_ACTION_REQUIRED=false
ROLLBACK_STATE_ABSENT=false
RECOVERY_BACKUP_ABSENT=false
SYSTEM_STATE_PRESERVED=false
STABLE_BOOT_IDENTITY_VERIFIED=false
FUTURE_WORK_REQUIRES_FRESH_BOUNDARY=false
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

for required in "$0" "$POLICY" "$ACCEPTED_CLOSURE" "$STEP115_SCRIPT" "$STEP115_POLICY"; do
    [[ -f $required && ! -L $required ]] || fail "a required scenario-closure checkpoint file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-scenario-closure-checkpoint
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
ACCEPTED_CLOSURE_SHA256=$(sha_file "$ACCEPTED_CLOSURE")
STEP115_SCRIPT_SHA256=$(sha_file "$STEP115_SCRIPT")
STEP115_POLICY_SHA256=$(sha_file "$STEP115_POLICY")

EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" expected_script_sha256)
EXPECTED_ACCEPTED_RECORD_SHA256=$(json_value "$POLICY" accepted_closure_record_sha256)
EXPECTED_ARCHIVE_SHA256=$(json_value "$POLICY" accepted_closure_archive_sha256)
EXPECTED_STEP115_SCRIPT_SHA256=$(json_value "$POLICY" accepted_closure_script_sha256)
EXPECTED_STEP115_POLICY_SHA256=$(json_value "$POLICY" accepted_closure_policy_sha256)
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

CHECKPOINT_SCOPE_SHA256=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-scenario-closure-checkpoint' \
        "accepted_closure_archive_sha256=$EXPECTED_ARCHIVE_SHA256" \
        "accepted_closure_record_sha256=$ACCEPTED_CLOSURE_SHA256" \
        "accepted_closure_script_sha256=$STEP115_SCRIPT_SHA256" \
        "accepted_closure_policy_sha256=$STEP115_POLICY_SHA256" \
        "checkpoint_policy_sha256=$POLICY_SHA256" \
        "checkpoint_script_sha256=$SCRIPT_SHA256" \
        "hostname_fqdn=$EXPECTED_HOSTNAME_FQDN" \
        "active_kernel=$EXPECTED_ACTIVE_KERNEL" \
        "rollback_kernel=$EXPECTED_ROLLBACK_KERNEL" \
        "required_boot_image_suffix=$EXPECTED_BOOT_IMAGE_SUFFIX" \
        "removed_recovery_path=$EXPECTED_REMOVED_RECOVERY_PATH" \
        | sha256sum | awk '{print $1}'
)

if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" \
    && $ACCEPTED_CLOSURE_SHA256 == "$EXPECTED_ACCEPTED_RECORD_SHA256" \
    && $STEP115_SCRIPT_SHA256 == "$EXPECTED_STEP115_SCRIPT_SHA256" \
    && $STEP115_POLICY_SHA256 == "$EXPECTED_STEP115_POLICY_SHA256" \
    && $(json_value "$ACCEPTED_CLOSURE" accepted) == true \
    && $(json_value "$ACCEPTED_CLOSURE" archive_sha256) == "$EXPECTED_ARCHIVE_SHA256" \
    && $(json_value "$ACCEPTED_CLOSURE" destructive_boundary_closed) == true \
    && $(json_value "$ACCEPTED_CLOSURE" historical_authorizations_consumed) == true \
    && $(json_value "$ACCEPTED_CLOSURE" pending_destructive_action) == false \
    && $(json_value "$ACCEPTED_CLOSURE" rollback_targets_absent) == true \
    && $(json_value "$ACCEPTED_CLOSURE" recovery_target_absent) == true \
    && $(json_value "$ACCEPTED_CLOSURE" system_state_preserved) == true \
    && $(json_value "$ACCEPTED_CLOSURE" pause_safe) == true \
    && $(json_value "$POLICY" reviewed) == true \
    && $(json_value "$POLICY" checkpoint_review_only) == true \
    && $(json_value "$POLICY" destructive_action_authorized) == false ]]; then
    pass "the accepted step-115 destructive-boundary closure and exact scenario checkpoint are immutably bound"
else
    fail "the scenario checkpoint does not match the accepted step-115 closure"
fi

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" \
    && $CONFIRM_CLOSURE_EVIDENCE_SHA256 == "$EXPECTED_ARCHIVE_SHA256" \
    && $CONFIRM_ACTIVE_KERNEL == "$EXPECTED_ACTIVE_KERNEL" \
    && $CONFIRM_ROLLBACK_KERNEL == "$EXPECTED_ROLLBACK_KERNEL" \
    && $CONFIRM_REMOVED_RECOVERY_PATH == "$EXPECTED_REMOVED_RECOVERY_PATH" \
    && $CONFIRM_CHECKPOINT_SCOPE_SHA256 == "$CHECKPOINT_SCOPE_SHA256" ]]; then
    pass "the explicit host, closure evidence, kernels, removed path, and checkpoint scope confirmations match"
else
    fail "one or more explicit scenario-closure checkpoint confirmations do not match"
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
    pass "the current host retains the stable 5.15.209 boot identity required for scenario closure"
else
    fail "the current host is outside the stable scenario-closure boot boundary"
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
    pass "the complete persistent scenario-closure checkpoint baseline was captured"
else
    fail "one or more scenario-closure checkpoint captures are incomplete"
fi

if [[ $(sha_file "$WORKDIR/packages.before.txt") == "$EXPECTED_PACKAGE_SHA256" \
    && $(sha_file "$WORKDIR/modules-active-objects.before.sha256") == "$EXPECTED_ACTIVE_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/modules-rollback-objects.before.txt") == "$EXPECTED_ROLLBACK_MODULES_SHA256" \
    && $(sha_file "$WORKDIR/boot-state.before.txt") == "$EXPECTED_BOOT_STATE_SHA256" \
    && $(sha_file "$WORKDIR/elilo.conf.before") == "$EXPECTED_ELILO_SHA256" ]]; then
    pass "the accepted package, module, rollback-absence, boot, and ELILO baselines remain intact at scenario closure"
else
    fail "persistent state drifted after the accepted destructive-boundary closure"
fi

ELILO=/boot/efi/EFI/Slackware/elilo.conf
OLDKERNEL_EXECUTABLE_REFS=$(sed 's/[[:space:]]*#.*$//' "$ELILO" | grep -Eic "oldkernel|$EXPECTED_ROLLBACK_KERNEL" || true)
ROLLBACK_PACKAGE_COUNT=$(
    find "$PKGDB" -mindepth 1 -maxdepth 1 -type f \
        \( -name "kernel-generic-$EXPECTED_ROLLBACK_KERNEL-*" \
           -o -name "kernel-huge-$EXPECTED_ROLLBACK_KERNEL-*" \
           -o -name "kernel-modules-$EXPECTED_ROLLBACK_KERNEL-*" \) \
        -printf '.' | wc -c
)
if [[ $ROLLBACK_PACKAGE_COUNT -eq 0 \
    && $OLDKERNEL_EXECUTABLE_REFS -eq 0 \
    && ! -s $WORKDIR/modules-rollback-objects.before.txt ]]; then
    ROLLBACK_STATE_ABSENT=true
    pass "rollback packages, module objects, and executable ELILO references remain absent"
else
    fail "rollback state reappeared before scenario closure"
fi

if [[ ! -e $EXPECTED_REMOVED_RECOVERY_PATH && ! -L $EXPECTED_REMOVED_RECOVERY_PATH ]]; then
    RECOVERY_BACKUP_ABSENT=true
    pass "the retired recovery backup remains absent at scenario closure"
else
    fail "the retired recovery backup path reappeared before scenario closure"
fi

if [[ $(json_value "$ACCEPTED_CLOSURE" destructive_boundary_closed) == true \
    && $(json_value "$ACCEPTED_CLOSURE" historical_authorizations_consumed) == true \
    && $(json_value "$ACCEPTED_CLOSURE" pending_destructive_action) == false \
    && $(json_value "$POLICY" destructive_action_authorized) == false \
    && $(json_value "$POLICY" pending_destructive_action) == false \
    && $(json_value "$POLICY" historical_authorizations_consumed) == true ]]; then
    DESTRUCTIVE_BOUNDARY_CLOSED=true
    HISTORICAL_AUTHORIZATIONS_CONSUMED=true
    PENDING_DESTRUCTIVE_ACTION=false
    MACHINE_ACTION_REQUIRED=false
    FUTURE_WORK_REQUIRES_FRESH_BOUNDARY=true
    pass "the destructive boundary remains closed and future work requires a fresh review boundary"
else
    fail "destructive authorization exhaustion is not preserved at scenario closure"
fi

capture_state after
if cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt" \
    && cmp -s -- "$WORKDIR/modules-active-objects.before.sha256" "$WORKDIR/modules-active-objects.after.sha256" \
    && cmp -s -- "$WORKDIR/modules-rollback-objects.before.txt" "$WORKDIR/modules-rollback-objects.after.txt" \
    && cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt" \
    && cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after" \
    && cmp -s -- "$WORKDIR/recovery-path.before.txt" "$WORKDIR/recovery-path.after.txt"; then
    SYSTEM_STATE_PRESERVED=true
    pass "the scenario-closure checkpoint did not modify persistent system state"
else
    fail "the scenario-closure checkpoint changed persistent system state"
fi

if [[ $FAIL_COUNT -eq 0 \
    && $STABLE_BOOT_IDENTITY_VERIFIED == true \
    && $DESTRUCTIVE_BOUNDARY_CLOSED == true \
    && $HISTORICAL_AUTHORIZATIONS_CONSUMED == true \
    && $PENDING_DESTRUCTIVE_ACTION == false \
    && $MACHINE_ACTION_REQUIRED == false \
    && $ROLLBACK_STATE_ABSENT == true \
    && $RECOVERY_BACKUP_ABSENT == true \
    && $SYSTEM_STATE_PRESERVED == true \
    && $FUTURE_WORK_REQUIRES_FRESH_BOUNDARY == true ]]; then
    SCENARIO_CLOSURE_CHECKPOINT=true
    CLEANUP_SCENARIO_CLOSED=true
    PAUSE_SAFE=true
    NEXT_STAGE=phase-1-resume-planning
    pass "the ELILO oldkernel cleanup scenario is closed at a safe no-action checkpoint"
else
    skip "scenario closure is withheld because one or more checkpoint conditions failed"
fi

cat > "$WORKDIR/summary.txt" <<EOF
scenario=elilo-oldkernel-cleanup-scenario-closure-checkpoint
target=$TARGET
hostname=$HOSTNAME_FQDN
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_ROLLBACK_KERNEL
accepted_closure_archive_sha256=$EXPECTED_ARCHIVE_SHA256
accepted_closure_record_sha256=$ACCEPTED_CLOSURE_SHA256
accepted_closure_script_sha256=$STEP115_SCRIPT_SHA256
accepted_closure_policy_sha256=$STEP115_POLICY_SHA256
checkpoint_script_sha256=$SCRIPT_SHA256
checkpoint_policy_sha256=$POLICY_SHA256
checkpoint_scope_sha256=$CHECKPOINT_SCOPE_SHA256
transient_boot_id_equality_required=false
current_boot_id_evidence_only=$CURRENT_BOOT_ID
boot_image=$BOOT_IMAGE
required_boot_image_suffix=$EXPECTED_BOOT_IMAGE_SUFFIX
removed_recovery_path=$EXPECTED_REMOVED_RECOVERY_PATH
scenario_closure_checkpoint=$SCENARIO_CLOSURE_CHECKPOINT
cleanup_scenario_closed=$CLEANUP_SCENARIO_CLOSED
destructive_boundary_closed=$DESTRUCTIVE_BOUNDARY_CLOSED
historical_authorizations_consumed=$HISTORICAL_AUTHORIZATIONS_CONSUMED
pending_destructive_action=$PENDING_DESTRUCTIVE_ACTION
machine_action_required=$MACHINE_ACTION_REQUIRED
rollback_state_absent=$ROLLBACK_STATE_ABSENT
recovery_backup_absent=$RECOVERY_BACKUP_ABSENT
system_state_preserved=$SYSTEM_STATE_PRESERVED
stable_boot_identity_verified=$STABLE_BOOT_IDENTITY_VERIFIED
future_work_requires_fresh_boundary=$FUTURE_WORK_REQUIRES_FRESH_BOUNDARY
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-elilo-oldkernel-cleanup-scenario-closure-checkpoint-${TIMESTAMP}.tar.gz"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$WORKDIR")"
ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
    "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
printf 'Result: %s (%d passes, %d failures, %d skips); scenario_closure_checkpoint=%s; cleanup_scenario_closed=%s; destructive_boundary_closed=%s; historical_authorizations_consumed=%s; pending_destructive_action=%s; machine_action_required=%s; rollback_state_absent=%s; recovery_backup_absent=%s; system_state_preserved=%s; future_work_requires_fresh_boundary=%s; pause_safe=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
    "$SCENARIO_CLOSURE_CHECKPOINT" "$CLEANUP_SCENARIO_CLOSED" "$DESTRUCTIVE_BOUNDARY_CLOSED" "$HISTORICAL_AUTHORIZATIONS_CONSUMED" "$PENDING_DESTRUCTIVE_ACTION" "$MACHINE_ACTION_REQUIRED" "$ROLLBACK_STATE_ABSENT" "$RECOVERY_BACKUP_ABSENT" "$SYSTEM_STATE_PRESERVED" "$FUTURE_WORK_REQUIRES_FRESH_BOUNDARY" "$PAUSE_SAFE" "$NEXT_STAGE"

[[ $FAIL_COUNT -eq 0 ]]
