#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SOURCE_FILE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE_FILE="$REPOSITORY_ROOT/data/config/slack-update.conf"
AUTHORIZATION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review-policy.json"
EXECUTION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-policy.json"

TARGET=""
STAGE=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_AUTHORIZATION_POLICY_SHA256=""
CONFIRM_EXECUTION_POLICY_SHA256=""
CONFIRM_PRE_REBOOT_MARKER_SHA256=""
CONFIRM_INTERACTIVE_MENUENTRY=""
CONFIRM_SINGLE_AUTHORIZED_REBOOT=false

EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/configuration-module-mode-source-remediation-runtime-validation-boot-selection-recovery
STATE_DIR="$EVIDENCE_PARENT/state"
PENDING_MARKER="$STATE_DIR/step143-recovery.pending.tsv"
CONSUMED_MARKER="$STATE_DIR/step143-recovery.consumed.tsv"

usage() {
    cat <<'USAGE'
Usage, pre-reboot gate:
  test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery.sh \
    --stage pre-reboot \
    --target slackware-current \
    --confirm-hostname-fqdn vbox-slackcurrent.vbox-slackcurrent.org \
    --confirm-recovery-authorization-policy-sha256 SHA256 \
    --confirm-execution-policy-sha256 SHA256

Usage, post-reboot characterization:
  test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery.sh \
    --stage post-reboot \
    --target slackware-current \
    --confirm-hostname-fqdn vbox-slackcurrent.vbox-slackcurrent.org \
    --confirm-recovery-authorization-policy-sha256 SHA256 \
    --confirm-execution-policy-sha256 SHA256 \
    --confirm-pre-reboot-marker-sha256 SHA256 \
    --confirm-interactive-menuentry 'Slackware-current slack-update direct generic (no initrd)' \
    --confirm-single-authorized-reboot

The pre-reboot stage is non-mutating except for private acceptance evidence and
an authorization handoff marker below /var/tmp. It never reboots and never
changes GRUB. After a separately reviewed successful pre-reboot result, the
operator may execute exactly one reboot and manually select only the frozen
menuentry printed by the harness.

The post-reboot stage consumes the step-143 authorization as soon as it proves
that a reboot occurred after the pre-reboot gate. It then characterizes the
live boot and preserves the runtime probe as unauthorized.
USAGE
}

while (($#)); do
    case "$1" in
        --stage) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; STAGE=$2; shift 2 ;;
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-recovery-authorization-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_AUTHORIZATION_POLICY_SHA256=$2; shift 2 ;;
        --confirm-execution-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_EXECUTION_POLICY_SHA256=$2; shift 2 ;;
        --confirm-pre-reboot-marker-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_PRE_REBOOT_MARKER_SHA256=$2; shift 2 ;;
        --confirm-interactive-menuentry) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_INTERACTIVE_MENUENTRY=$2; shift 2 ;;
        --confirm-single-authorized-reboot) CONFIRM_SINGLE_AUTHORIZED_REBOOT=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance validation must run as root.\n' >&2
    exit 2
fi

for value in "$STAGE" "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_AUTHORIZATION_POLICY_SHA256" "$CONFIRM_EXECUTION_POLICY_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done

[[ $STAGE == pre-reboot || $STAGE == post-reboot ]] || { printf 'ERROR: unsupported stage: %s\n' "$STAGE" >&2; exit 2; }
[[ $TARGET == slackware-current ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_AUTHORIZATION_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid recovery-authorization-policy SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_EXECUTION_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid execution-policy SHA-256.\n' >&2; exit 2; }
if [[ $STAGE == post-reboot ]]; then
    [[ $CONFIRM_PRE_REBOOT_MARKER_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid pre-reboot marker SHA-256.\n' >&2; exit 2; }
    [[ -n $CONFIRM_INTERACTIVE_MENUENTRY ]] || { printf 'ERROR: post-reboot requires explicit menuentry confirmation.\n' >&2; exit 2; }
    [[ $CONFIRM_SINGLE_AUTHORIZED_REBOOT == true ]] || { printf 'ERROR: post-reboot requires --confirm-single-authorized-reboot.\n' >&2; exit 2; }
fi

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
AUTHORIZATION_ARMED=false
AUTHORIZATION_CONSUMED_BY_REBOOT=false
LIVE_RECOVERY_ACCEPTED=false
SYSTEM_STATE_PRESERVED=false
NEXT_STAGE=boot-selection-recovery-manual-review-required

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*"; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$*"; }
sha_file() { sha256sum -- "$1" | awk '{print $1}'; }

json_value() {
    local file=$1 path=$2
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

marker_value() {
    local key=$1 file=$2
    awk -F '\t' -v key="$key" '$1 == key { print substr($0, index($0, "\t") + 1); exit }' "$file"
}

capture_packages() {
    local destination=$1
    find -H /var/log/packages -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | LC_ALL=C sort > "$destination"
}

capture_slackpkg_metadata() {
    local destination=$1
    if [[ -d /var/lib/slackpkg && ! -L /var/lib/slackpkg ]]; then
        find /var/lib/slackpkg -type f -print0 2>/dev/null \
            | LC_ALL=C sort -z \
            | xargs -0 -r sha256sum -- > "$destination"
    else
        printf 'absent\n' > "$destination"
    fi
}

optional_hash() {
    local path=$1
    if [[ -f $path && ! -L $path ]]; then
        sha_file "$path"
    elif [[ ! -e $path && ! -L $path ]]; then
        printf 'absent\n'
    else
        printf 'unsafe\n'
    fi
}

capture_boot_guard() {
    local destination=$1
    {
        printf 'grub_cfg_sha256=%s\n' "$(optional_hash /boot/grub/grub.cfg)"
        printf 'custom_grub_script_sha256=%s\n' "$(optional_hash /etc/grub.d/41_slack-update-direct-generic)"
        printf 'grubenv_sha256=%s\n' "$(optional_hash /boot/grub/grubenv)"
        printf 'default_grub_sha256=%s\n' "$(optional_hash /etc/default/grub)"
        printf 'source_sha256=%s\n' "$(sha_file "$SOURCE_FILE" 2>/dev/null || true)"
        printf 'template_sha256=%s\n' "$(sha_file "$TEMPLATE_FILE" 2>/dev/null || true)"
    } > "$destination"
}

extract_menuentry() {
    local title=$1 destination=$2
    awk -v title="$title" '
        index($0, "menuentry \047" title "\047") == 1 { inside=1 }
        inside { print }
        inside && $0 ~ /^}/ { exit }
    ' /boot/grub/grub.cfg > "$destination"
}

cmdline_token_value() {
    local prefix=$1 token value="" count=0
    for token in $(cat /proc/cmdline 2>/dev/null || true); do
        case "$token" in
            "$prefix"*) count=$((count + 1)); value=${token#"$prefix"} ;;
        esac
    done
    printf '%s\t%s\n' "$count" "$value"
}

for required in "$0" "$SOURCE_FILE" "$TEMPLATE_FILE" "$AUTHORIZATION_POLICY" "$EXECUTION_POLICY"; do
    [[ -f $required && ! -L $required ]] || fail "a required recovery-boundary file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

mkdir -p -- "$EVIDENCE_PARENT" "$STATE_DIR"
chmod 0700 -- "$EVIDENCE_PARENT" "$STATE_DIR"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_DIR="$EVIDENCE_PARENT/${STAGE}-${TIMESTAMP}"
mkdir -p -- "$EVIDENCE_DIR"
chmod 0700 -- "$EVIDENCE_DIR"
ASSERTIONS_LOG="$EVIDENCE_DIR/assertions.log"
: > "$ASSERTIONS_LOG"
exec 3>&1
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }

SCRIPT_SHA256=$(sha_file "$0")
AUTHORIZATION_POLICY_SHA256=$(sha_file "$AUTHORIZATION_POLICY")
EXECUTION_POLICY_SHA256=$(sha_file "$EXECUTION_POLICY")
EXPECTED_SCRIPT_SHA256=$(json_value "$EXECUTION_POLICY" execution_harness_sha256)
EXPECTED_AUTHORIZATION_POLICY_SHA256=$(json_value "$EXECUTION_POLICY" step143_authorization_policy_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$EXECUTION_POLICY" target.hostname_fqdn)
EXPECTED_KERNEL=$(json_value "$EXECUTION_POLICY" target.accepted_kernel)
EXPECTED_BOOT_IMAGE=$(json_value "$EXECUTION_POLICY" target.boot_image)
EXPECTED_GENERIC_TARGET=$(json_value "$EXECUTION_POLICY" target.generic_kernel_target)
EXPECTED_ROOT_DEVICE=$(json_value "$EXECUTION_POLICY" target.mounted_root_device)
EXPECTED_POST_ROOT_TOKEN=$(json_value "$EXECUTION_POLICY" target.post_reboot_root_token)
EXPECTED_MENUENTRY=$(json_value "$EXECUTION_POLICY" target.dedicated_menuentry)
EXPECTED_LINUX_COMMAND=$(json_value "$EXECUTION_POLICY" target.dedicated_linux_command)
EXPECTED_GRUB_CFG_SHA256=$(json_value "$EXECUTION_POLICY" target.grub_cfg_sha256)
EXPECTED_CUSTOM_GRUB_SHA256=$(json_value "$EXECUTION_POLICY" target.custom_grub_script_sha256)

[[ $AUTHORIZATION_POLICY_SHA256 == "$CONFIRM_AUTHORIZATION_POLICY_SHA256" ]] \
    && pass "the execution is bound to the explicitly confirmed step-143 recovery authorization" \
    || fail "the step-143 recovery-authorization policy SHA-256 does not match the explicit confirmation"
[[ $AUTHORIZATION_POLICY_SHA256 == "$EXPECTED_AUTHORIZATION_POLICY_SHA256" ]] \
    && pass "the step-144 execution policy preserves the exact step-143 authorization identity" \
    || fail "the step-144 execution policy is not bound to the accepted step-143 authorization"
[[ $EXECUTION_POLICY_SHA256 == "$CONFIRM_EXECUTION_POLICY_SHA256" ]] \
    && pass "the execution is bound to the explicitly confirmed step-144 execution policy" \
    || fail "the step-144 execution-policy SHA-256 does not match the explicit confirmation"
[[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" ]] \
    && pass "the machine harness matches the frozen step-144 execution-harness SHA-256" \
    || fail "the machine harness does not match the frozen step-144 execution-harness SHA-256"

python3 - "$AUTHORIZATION_POLICY" "$EXECUTION_POLICY" > "$EVIDENCE_DIR/policy-semantic-check.txt" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    auth = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    execution = json.load(handle)
assert auth["authorization"]["authorization_id"] == execution["authorization_id"]
assert auth["authorization"]["authorization_consumable"] is True
assert auth["authorization"]["machine_sequence_limit"] == 1
assert auth["authorization"]["reboot_limit"] == 1
assert auth["authorization"]["interactive_boot_selection_authorized"] is True
assert auth["authorization"]["interactive_boot_selection_limit"] == 1
assert auth["authorization"]["manual_menu_selection_required"] is True
assert auth["authorization"]["authorized_menuentry"] == execution["target"]["dedicated_menuentry"]
for key in (
    "persistent_boot_selection_mutation_authorized",
    "boot_configuration_mutation_authorized",
    "grub_environment_mutation_authorized",
    "grub_cfg_regeneration_authorized",
    "package_mutation_authorized",
    "repository_refresh_authorized",
    "source_change_authorized",
    "configuration_template_change_authorized",
    "contract_change_authorized",
    "runtime_probe_authorized",
    "slackware_current_rerun_authorized",
    "slackware_15_execution_authorized",
):
    assert auth["authorization"][key] is False
assert auth["pre_reboot_gate"]["failure_stops_before_reboot"] is True
assert auth["post_reboot_characterization"]["runtime_probe_permitted"] is False
assert execution["machine_harness_performs_reboot"] is False
assert execution["runtime_probe_permitted"] is False
assert execution["repository_refresh_permitted"] is False
assert execution["package_mutation_permitted"] is False
assert execution["boot_configuration_mutation_permitted"] is False
print("policy_semantics=accepted")
PY
if [[ $? -eq 0 ]]; then
    pass "the step-143 authorization and step-144 execution policies expose the frozen single-reboot envelope"
else
    fail "the recovery authorization or execution policy semantics are not accepted"
fi

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
SLACKWARE_VERSION=$(cat /etc/slackware-version 2>/dev/null || true)
RUNNING_KERNEL=$(uname -r)
MOUNTED_ROOT=$(findmnt -no SOURCE / 2>/dev/null || true)
GENERIC_TARGET=$(readlink -e /boot/vmlinuz-generic 2>/dev/null || true)
BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)
BOOT_TIME_EPOCH=$(awk '$1 == "btime" { print $2; exit }' /proc/stat 2>/dev/null || true)
read -r BOOT_IMAGE_COUNT BOOT_IMAGE_VALUE < <(cmdline_token_value 'BOOT_IMAGE=')
read -r ROOT_TOKEN_COUNT ROOT_TOKEN_VALUE < <(cmdline_token_value 'root=')

printf '%s\n' "$HOSTNAME_FQDN" > "$EVIDENCE_DIR/hostname-fqdn.txt"
printf '%s\n' "$SLACKWARE_VERSION" > "$EVIDENCE_DIR/slackware-version.txt"
printf '%s\n' "$RUNNING_KERNEL" > "$EVIDENCE_DIR/uname-r.txt"
cat /proc/cmdline > "$EVIDENCE_DIR/proc-cmdline.txt" 2>/dev/null || :
printf '%s\n' "$MOUNTED_ROOT" > "$EVIDENCE_DIR/mounted-root.txt"
printf '%s\n' "$GENERIC_TARGET" > "$EVIDENCE_DIR/vmlinuz-generic-target.txt"
printf '%s\n' "$BOOT_ID" > "$EVIDENCE_DIR/boot-id.txt"
printf '%s\n' "$BOOT_TIME_EPOCH" > "$EVIDENCE_DIR/boot-time-epoch.txt"

[[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" ]] \
    && pass "the live Slackware-current FQDN matches the frozen target" \
    || fail "the live Slackware-current FQDN does not match the frozen target"
[[ $SLACKWARE_VERSION == 'Slackware 15.0+'* ]] \
    && pass "the target identifies as Slackware-current" \
    || fail "the target does not identify as Slackware-current"
[[ -d /sys/firmware/efi ]] \
    && pass "the target is running under UEFI firmware" \
    || fail "the target is not running under the required UEFI firmware"
[[ $RUNNING_KERNEL == "$EXPECTED_KERNEL" ]] \
    && pass "the running kernel remains the frozen 6.18.45 target" \
    || fail "the running kernel changed from the frozen target"
[[ $MOUNTED_ROOT == "$EXPECTED_ROOT_DEVICE" ]] \
    && pass "the mounted root remains the frozen /dev/sda2 device" \
    || fail "the mounted root device does not match the frozen target"
[[ -L /boot/vmlinuz-generic && $GENERIC_TARGET == "$EXPECTED_GENERIC_TARGET" ]] \
    && pass "the generic-kernel symlink resolves to the frozen versioned kernel" \
    || fail "the generic-kernel symlink target changed"
[[ $(optional_hash /boot/grub/grub.cfg) == "$EXPECTED_GRUB_CFG_SHA256" ]] \
    && pass "grub.cfg matches the frozen pre-recovery SHA-256" \
    || fail "grub.cfg does not match the frozen pre-recovery SHA-256"
[[ $(optional_hash /etc/grub.d/41_slack-update-direct-generic) == "$EXPECTED_CUSTOM_GRUB_SHA256" ]] \
    && pass "the dedicated GRUB script matches the frozen pre-recovery SHA-256" \
    || fail "the dedicated GRUB script does not match the frozen pre-recovery SHA-256"

MENUENTRY_FILE="$EVIDENCE_DIR/direct-generic-menuentry.txt"
extract_menuentry "$EXPECTED_MENUENTRY" "$MENUENTRY_FILE"
MENUENTRY_LINUX_COUNT=$(awk '$1 == "linux" || $1 == "linuxefi" { count++ } END { print count+0 }' "$MENUENTRY_FILE")
MENUENTRY_INITRD_COUNT=$(awk '$1 == "initrd" || $1 == "initrdefi" { count++ } END { print count+0 }' "$MENUENTRY_FILE")
NORMALIZED_LINUX=$(awk '$1 == "linux" { $1=$1; print; exit }' "$MENUENTRY_FILE")
if [[ -s $MENUENTRY_FILE && $MENUENTRY_LINUX_COUNT -eq 1 && $MENUENTRY_INITRD_COUNT -eq 0 \
    && $NORMALIZED_LINUX == "$EXPECTED_LINUX_COMMAND" ]]; then
    pass "the dedicated GRUB entry retains exactly the frozen linux command and no initrd command"
else
    fail "the dedicated GRUB entry no longer matches the frozen no-initrd recovery target"
fi

capture_packages "$EVIDENCE_DIR/packages.txt"
capture_slackpkg_metadata "$EVIDENCE_DIR/slackpkg-metadata.txt"
capture_boot_guard "$EVIDENCE_DIR/boot-guard.txt"

if [[ $STAGE == pre-reboot ]]; then
    if [[ -e $PENDING_MARKER || -L $PENDING_MARKER || -e $CONSUMED_MARKER || -L $CONSUMED_MARKER ]]; then
        fail "a prior step-143 recovery handoff marker already exists; this single-use authorization cannot be re-armed"
    else
        pass "no prior recovery handoff marker exists"
    fi

    if [[ $BOOT_IMAGE_COUNT -eq 1 && $BOOT_IMAGE_VALUE == "$EXPECTED_BOOT_IMAGE" ]]; then
        pass "the current session still uses the frozen generic boot image"
    else
        fail "the current session does not uniquely expose the frozen generic boot image"
    fi

    if [[ $FAIL_COUNT -eq 0 ]]; then
        PRE_EPOCH=$(date -u +%s)
        MARKER_TMP="$STATE_DIR/.step143-recovery.pending.$$"
        {
            printf 'schema\t1\n'
            printf 'authorization_id\t%s\n' "$(json_value "$EXECUTION_POLICY" authorization_id)"
            printf 'pre_timestamp_utc\t%s\n' "$TIMESTAMP"
            printf 'pre_epoch\t%s\n' "$PRE_EPOCH"
            printf 'pre_boot_id\t%s\n' "$BOOT_ID"
            printf 'pre_boot_time_epoch\t%s\n' "$BOOT_TIME_EPOCH"
            printf 'authorization_policy_sha256\t%s\n' "$AUTHORIZATION_POLICY_SHA256"
            printf 'execution_policy_sha256\t%s\n' "$EXECUTION_POLICY_SHA256"
            printf 'execution_harness_sha256\t%s\n' "$SCRIPT_SHA256"
            printf 'hostname_fqdn\t%s\n' "$HOSTNAME_FQDN"
            printf 'kernel\t%s\n' "$RUNNING_KERNEL"
            printf 'mounted_root\t%s\n' "$MOUNTED_ROOT"
            printf 'boot_image\t%s\n' "$BOOT_IMAGE_VALUE"
            printf 'live_root_token_before_recovery\t%s\n' "$ROOT_TOKEN_VALUE"
            printf 'generic_kernel_target\t%s\n' "$GENERIC_TARGET"
            printf 'menuentry\t%s\n' "$EXPECTED_MENUENTRY"
            printf 'grub_cfg_sha256\t%s\n' "$(optional_hash /boot/grub/grub.cfg)"
            printf 'custom_grub_script_sha256\t%s\n' "$(optional_hash /etc/grub.d/41_slack-update-direct-generic)"
            printf 'grubenv_sha256\t%s\n' "$(optional_hash /boot/grub/grubenv)"
            printf 'default_grub_sha256\t%s\n' "$(optional_hash /etc/default/grub)"
            printf 'source_sha256\t%s\n' "$(sha_file "$SOURCE_FILE")"
            printf 'template_sha256\t%s\n' "$(sha_file "$TEMPLATE_FILE")"
            printf 'packages_manifest_sha256\t%s\n' "$(sha_file "$EVIDENCE_DIR/packages.txt")"
            printf 'slackpkg_metadata_manifest_sha256\t%s\n' "$(sha_file "$EVIDENCE_DIR/slackpkg-metadata.txt")"
            printf 'runtime_probe_invoked\tfalse\n'
            printf 'repository_refresh_performed\tfalse\n'
            printf 'package_mutation_performed\tfalse\n'
            printf 'boot_configuration_mutation_performed\tfalse\n'
            printf 'reboot_performed_by_harness\tfalse\n'
        } > "$MARKER_TMP"
        chmod 0600 -- "$MARKER_TMP"
        mv -- "$MARKER_TMP" "$PENDING_MARKER"
        MARKER_SHA256=$(sha_file "$PENDING_MARKER")
        cp -- "$PENDING_MARKER" "$EVIDENCE_DIR/pre-reboot-marker.tsv"
        AUTHORIZATION_ARMED=true
        NEXT_STAGE=manual-interactive-reboot-selection
        pass "the fail-closed pre-reboot gate passed and armed the single-use recovery handoff"
    else
        skip "the recovery handoff remains unarmed because the pre-reboot gate failed"
        MARKER_SHA256=""
    fi

    cat > "$EVIDENCE_DIR/summary.txt" <<EOF_SUMMARY
schema=1
scenario=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery
stage=pre-reboot
target=$TARGET
hostname_fqdn=$HOSTNAME_FQDN
running_kernel=$RUNNING_KERNEL
boot_image=$BOOT_IMAGE_VALUE
live_root_token=$ROOT_TOKEN_VALUE
mounted_root=$MOUNTED_ROOT
authorization_policy_sha256=$AUTHORIZATION_POLICY_SHA256
execution_policy_sha256=$EXECUTION_POLICY_SHA256
execution_harness_sha256=$SCRIPT_SHA256
authorization_armed=$AUTHORIZATION_ARMED
authorization_consumed_by_reboot=false
runtime_probe_invoked=false
repository_refresh_performed=false
package_mutation_performed=false
boot_configuration_mutation_performed=false
reboot_performed_by_harness=false
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

    ARCHIVE="$EVIDENCE_PARENT/slackware-current-configuration-module-mode-source-remediation-runtime-validation-boot-selection-recovery-pre-${TIMESTAMP}.tar.gz"
    tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$EVIDENCE_DIR")"
    ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
    printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"
    printf 'Evidence archive: %s\n' "$ARCHIVE"
    printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
    if [[ -n $MARKER_SHA256 ]]; then
        printf 'Pre-reboot marker SHA-256: %s\n' "$MARKER_SHA256"
    fi
    printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
        "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
    printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
    if [[ $AUTHORIZATION_ARMED == true && $FAIL_COUNT -eq 0 ]]; then
        printf 'Manual reboot authorized: true\n'
        printf 'Authorized reboot command: sudo /sbin/reboot\n'
        printf 'Authorized GRUB menuentry: %s\n' "$EXPECTED_MENUENTRY"
        printf 'Runtime probe authorized: false\n'
    fi
    printf 'Result: %s (%d passes, %d failures, %d skips); authorization_armed=%s; next_stage=%s\n' \
        "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" "$AUTHORIZATION_ARMED" "$NEXT_STAGE"
    [[ $FAIL_COUNT -eq 0 ]]
    exit
fi

MARKER_FILE=""
if [[ -f $PENDING_MARKER && ! -L $PENDING_MARKER && ! -e $CONSUMED_MARKER && ! -L $CONSUMED_MARKER ]]; then
    MARKER_FILE=$PENDING_MARKER
elif [[ -f $CONSUMED_MARKER && ! -L $CONSUMED_MARKER && ! -e $PENDING_MARKER && ! -L $PENDING_MARKER ]]; then
    MARKER_FILE=$CONSUMED_MARKER
else
    fail "exactly one safe pre-reboot handoff marker must exist for post-reboot characterization"
fi

if [[ -n $MARKER_FILE ]]; then
    ACTUAL_MARKER_SHA256=$(sha_file "$MARKER_FILE")
    [[ $ACTUAL_MARKER_SHA256 == "$CONFIRM_PRE_REBOOT_MARKER_SHA256" ]] \
        && pass "the post-reboot stage is bound to the explicitly confirmed pre-reboot handoff marker" \
        || fail "the pre-reboot handoff marker SHA-256 does not match the explicit confirmation"
    cp -- "$MARKER_FILE" "$EVIDENCE_DIR/pre-reboot-marker.tsv"
fi

if [[ -n $MARKER_FILE && $FAIL_COUNT -eq 0 ]]; then
    PRE_BOOT_ID=$(marker_value pre_boot_id "$MARKER_FILE")
    PRE_EPOCH=$(marker_value pre_epoch "$MARKER_FILE")
    PRE_AUTH_POLICY_SHA256=$(marker_value authorization_policy_sha256 "$MARKER_FILE")
    PRE_EXEC_POLICY_SHA256=$(marker_value execution_policy_sha256 "$MARKER_FILE")
    PRE_HARNESS_SHA256=$(marker_value execution_harness_sha256 "$MARKER_FILE")
    PRE_PACKAGES_SHA256=$(marker_value packages_manifest_sha256 "$MARKER_FILE")
    PRE_SLACKPKG_METADATA_SHA256=$(marker_value slackpkg_metadata_manifest_sha256 "$MARKER_FILE")
    PRE_GRUBENV_SHA256=$(marker_value grubenv_sha256 "$MARKER_FILE")
    PRE_DEFAULT_GRUB_SHA256=$(marker_value default_grub_sha256 "$MARKER_FILE")
    PRE_SOURCE_SHA256=$(marker_value source_sha256 "$MARKER_FILE")
    PRE_TEMPLATE_SHA256=$(marker_value template_sha256 "$MARKER_FILE")

    [[ $PRE_AUTH_POLICY_SHA256 == "$AUTHORIZATION_POLICY_SHA256" \
        && $PRE_EXEC_POLICY_SHA256 == "$EXECUTION_POLICY_SHA256" \
        && $PRE_HARNESS_SHA256 == "$SCRIPT_SHA256" ]] \
        && pass "the post-reboot stage preserves the exact pre-reboot policy and harness identities" \
        || fail "the recovery policy or harness identity changed across the reboot"

    if [[ $BOOT_ID != "$PRE_BOOT_ID" && $BOOT_TIME_EPOCH =~ ^[0-9]+$ && $PRE_EPOCH =~ ^[0-9]+$ \
        && $BOOT_TIME_EPOCH -ge $PRE_EPOCH ]]; then
        pass "the current boot started after the accepted pre-reboot gate"
        AUTHORIZATION_CONSUMED_BY_REBOOT=true
    else
        fail "the post-reboot stage cannot prove a reboot occurred after the accepted pre-reboot gate"
    fi

    [[ $CONFIRM_SINGLE_AUTHORIZED_REBOOT == true ]] \
        && pass "the operator explicitly confirms that exactly one authorized reboot occurred" \
        || fail "the single authorized reboot was not explicitly confirmed"
    [[ $CONFIRM_INTERACTIVE_MENUENTRY == "$EXPECTED_MENUENTRY" ]] \
        && pass "the operator explicitly confirms the only authorized interactive GRUB menuentry" \
        || fail "the confirmed interactive GRUB menuentry is not the authorized entry"

    if [[ $AUTHORIZATION_CONSUMED_BY_REBOOT == true && $MARKER_FILE == "$PENDING_MARKER" ]]; then
        mv -- "$PENDING_MARKER" "$CONSUMED_MARKER"
        MARKER_FILE=$CONSUMED_MARKER
        pass "the step-143 recovery authorization is now consumed and cannot authorize another reboot"
    elif [[ $AUTHORIZATION_CONSUMED_BY_REBOOT == true && $MARKER_FILE == "$CONSUMED_MARKER" ]]; then
        pass "the step-143 recovery authorization was already marked consumed by the proven reboot"
    fi

    if [[ $BOOT_IMAGE_COUNT -eq 1 && $BOOT_IMAGE_VALUE == "$EXPECTED_BOOT_IMAGE" ]]; then
        pass "the recovered session uses the frozen generic boot image"
    else
        fail "the recovered session does not uniquely expose the frozen generic boot image"
    fi
    if [[ $ROOT_TOKEN_COUNT -eq 1 && $ROOT_TOKEN_VALUE == "$EXPECTED_POST_ROOT_TOKEN" \
        && $MOUNTED_ROOT == "$EXPECTED_ROOT_DEVICE" ]]; then
        pass "the recovered live root token and mounted root are exactly /dev/sda2"
    else
        fail "the recovered live root token or mounted root does not prove the frozen direct-generic selection"
    fi

    CURRENT_PACKAGES_SHA256=$(sha_file "$EVIDENCE_DIR/packages.txt")
    CURRENT_SLACKPKG_METADATA_SHA256=$(sha_file "$EVIDENCE_DIR/slackpkg-metadata.txt")
    CURRENT_GRUBENV_SHA256=$(optional_hash /boot/grub/grubenv)
    CURRENT_DEFAULT_GRUB_SHA256=$(optional_hash /etc/default/grub)
    CURRENT_SOURCE_SHA256=$(sha_file "$SOURCE_FILE")
    CURRENT_TEMPLATE_SHA256=$(sha_file "$TEMPLATE_FILE")

    if [[ $CURRENT_PACKAGES_SHA256 == "$PRE_PACKAGES_SHA256" \
        && $CURRENT_SLACKPKG_METADATA_SHA256 == "$PRE_SLACKPKG_METADATA_SHA256" \
        && $CURRENT_GRUBENV_SHA256 == "$PRE_GRUBENV_SHA256" \
        && $CURRENT_DEFAULT_GRUB_SHA256 == "$PRE_DEFAULT_GRUB_SHA256" \
        && $CURRENT_SOURCE_SHA256 == "$PRE_SOURCE_SHA256" \
        && $CURRENT_TEMPLATE_SHA256 == "$PRE_TEMPLATE_SHA256" ]]; then
        SYSTEM_STATE_PRESERVED=true
        pass "package, Slackpkg metadata, GRUB environment/defaults, source, and template state were preserved"
    else
        fail "package, repository metadata, GRUB environment/defaults, source, or template state changed across recovery"
    fi
fi

if [[ $FAIL_COUNT -eq 0 && $AUTHORIZATION_CONSUMED_BY_REBOOT == true && $SYSTEM_STATE_PRESERVED == true \
    && $ROOT_TOKEN_COUNT -eq 1 && $ROOT_TOKEN_VALUE == "$EXPECTED_POST_ROOT_TOKEN" ]]; then
    LIVE_RECOVERY_ACCEPTED=true
    NEXT_STAGE=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review
    pass "the recovered live boot satisfies the frozen selection-only characterization boundary"
else
    skip "recovery acceptance remains blocked pending manual evidence review"
fi

cat > "$EVIDENCE_DIR/summary.txt" <<EOF_SUMMARY
schema=1
scenario=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery
stage=post-reboot
target=$TARGET
hostname_fqdn=$HOSTNAME_FQDN
running_kernel=$RUNNING_KERNEL
boot_image=$BOOT_IMAGE_VALUE
live_root_token=$ROOT_TOKEN_VALUE
mounted_root=$MOUNTED_ROOT
authorization_policy_sha256=$AUTHORIZATION_POLICY_SHA256
execution_policy_sha256=$EXECUTION_POLICY_SHA256
execution_harness_sha256=$SCRIPT_SHA256
authorization_armed=false
authorization_consumed_by_reboot=$AUTHORIZATION_CONSUMED_BY_REBOOT
live_recovery_accepted=$LIVE_RECOVERY_ACCEPTED
system_state_preserved=$SYSTEM_STATE_PRESERVED
runtime_probe_invoked=false
repository_refresh_performed=false
package_mutation_performed=false
boot_configuration_mutation_performed=false
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/slackware-current-configuration-module-mode-source-remediation-runtime-validation-boot-selection-recovery-post-${TIMESTAMP}.tar.gz"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$EVIDENCE_DIR")"
ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"
printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
    "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
printf 'Result: %s (%d passes, %d failures, %d skips); authorization_consumed_by_reboot=%s; live_recovery_accepted=%s; system_state_preserved=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
    "$AUTHORIZATION_CONSUMED_BY_REBOOT" "$LIVE_RECOVERY_ACCEPTED" "$SYSTEM_STATE_PRESERVED" "$NEXT_STAGE"
[[ $FAIL_COUNT -eq 0 ]]
