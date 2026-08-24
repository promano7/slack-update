#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SOURCE_FILE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPOSITORY_ROOT/data/config/slack-update.conf"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_BINDING_POLICY_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh \
    --target slackware-current \
    --confirm-hostname-fqdn vbox-slackcurrent.vbox-slackcurrent.org \
    --confirm-binding-policy-sha256 SHA256

Run the single authorized non-mutating Slackware-current runtime validation for
Phase 1 optional-module mode source remediation. The target must already be in
the frozen GRUB direct-generic/no-initrd profile. A profile mismatch is a hard
stop and does not authorize any guest repair or boot change.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-binding-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_BINDING_POLICY_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance validation must run as root.\n' >&2
    exit 2
fi
for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_BINDING_POLICY_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done
[[ $TARGET == slackware-current ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_BINDING_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid binding-policy SHA-256.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
BOOT_PROFILE_MATCH=false
RUNTIME_PROBE_ACCEPTED=false
SYSTEM_STATE_PRESERVED=false
AUTHORIZATION_CONSUMED_BY_EXECUTION=false
NEXT_STAGE=manual-review-required

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

for required in "$0" "$SOURCE_FILE" "$TEMPLATE" "$POLICY"; do
    [[ -f $required && ! -L $required ]] || fail "a required runtime-validation file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/configuration-module-mode-source-remediation-runtime-validation
EVIDENCE_DIR="$EVIDENCE_PARENT/${TARGET}-${TIMESTAMP}"
mkdir -p -- "$EVIDENCE_DIR"
chmod 0700 -- "$EVIDENCE_DIR"
ASSERTIONS_LOG="$EVIDENCE_DIR/assertions.log"
: > "$ASSERTIONS_LOG"
exec 3>&1
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }

SCRIPT_SHA256=$(sha_file "$0")
POLICY_SHA256=$(sha_file "$POLICY")
SOURCE_SHA256=$(sha_file "$SOURCE_FILE")
TEMPLATE_SHA256=$(sha_file "$TEMPLATE")
EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" slackware_current.execution_harness_sha256)
EXPECTED_SOURCE_SHA256=$(json_value "$POLICY" source_sha256)
EXPECTED_TEMPLATE_SHA256=$(json_value "$POLICY" template_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" slackware_current.hostname_fqdn)
EXPECTED_BOOT_PROFILE=$(json_value "$POLICY" slackware_current.required_boot_profile)
EXPECTED_KERNEL=$(json_value "$POLICY" slackware_current.accepted_kernel)
EXPECTED_GRUB_MENUENTRY=$(json_value "$POLICY" slackware_current.direct_generic_menuentry)
EXPECTED_ROOT_DEVICE=$(json_value "$POLICY" slackware_current.expected_root_device)

if [[ $POLICY_SHA256 == "$CONFIRM_BINDING_POLICY_SHA256" ]]; then
    pass "the execution is bound to the explicitly confirmed step-132 target-binding policy"
else
    fail "the step-132 target-binding policy SHA-256 does not match the explicit confirmation"
fi
if [[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" ]]; then
    pass "the Slackware-current execution harness matches the frozen step-132 SHA-256"
else
    fail "the Slackware-current execution harness does not match the frozen step-132 SHA-256"
fi
if [[ $SOURCE_SHA256 == "$EXPECTED_SOURCE_SHA256" ]]; then
    pass "the target carries the accepted remediated reference implementation"
else
    fail "the target reference implementation SHA-256 is not the accepted remediated source"
fi
if [[ $TEMPLATE_SHA256 == "$EXPECTED_TEMPLATE_SHA256" ]]; then
    pass "the target carries the frozen configuration template"
else
    fail "the target configuration template SHA-256 is not frozen step-132 input"
fi
if [[ $(json_value "$POLICY" machine_execution_authorized) == true \
    && $(json_value "$POLICY" authorization_consumable) == true \
    && $(json_value "$POLICY" target_binding_complete) == true \
    && $(json_value "$POLICY" slackware_current.execution_authorized) == true \
    && $(json_value "$POLICY" slackware_current.machine_execution_limit) == 1 \
    && $(json_value "$POLICY" reboot_limit) == 0 ]]; then
    pass "the target-binding policy authorizes exactly one current-VM execution and zero reboots"
else
    fail "the target-binding policy does not expose the frozen current-VM authorization envelope"
fi

capture_packages() {
    local destination=$1
    find -H /var/log/packages -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | LC_ALL=C sort > "$destination"
}

capture_boot_state() {
    local destination=$1
    {
        printf 'hostname_fqdn=%s\n' "$(hostname -f 2>/dev/null || true)"
        printf 'kernel=%s\n' "$(uname -r)"
        printf 'cmdline=%s\n' "$(cat /proc/cmdline 2>/dev/null || true)"
        printf 'root=%s\n' "$(findmnt -no SOURCE,FSTYPE,OPTIONS / 2>/dev/null || true)"
        printf 'vmlinuz_generic_target=%s\n' "$(readlink -e /boot/vmlinuz-generic 2>/dev/null || true)"
        printf 'mkinitrd_config_kind='; if [[ -L /etc/mkinitrd.conf ]]; then printf 'symlink\n'; elif [[ -e /etc/mkinitrd.conf ]]; then printf 'present\n'; else printf 'absent\n'; fi
        printf 'legacy_initrd_kind='; if [[ -L /boot/initrd.gz ]]; then printf 'symlink\n'; elif [[ -e /boot/initrd.gz ]]; then printf 'present\n'; else printf 'absent\n'; fi
        printf 'grub_cfg_sha256=%s\n' "$(sha_file /boot/grub/grub.cfg 2>/dev/null || true)"
        printf 'custom_grub_script_sha256=%s\n' "$(sha_file /etc/grub.d/41_slack-update-direct-generic 2>/dev/null || true)"
    } > "$destination"
}

capture_packages "$EVIDENCE_DIR/packages.before.txt"
capture_boot_state "$EVIDENCE_DIR/boot-state.before.txt"
sha_file "$SOURCE_FILE" > "$EVIDENCE_DIR/source.before.sha256"
sha_file "$TEMPLATE" > "$EVIDENCE_DIR/template.before.sha256"

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
SLACKWARE_VERSION=$(cat /etc/slackware-version 2>/dev/null || true)
RUNNING_KERNEL_ACTUAL=$(uname -r)
CMDLINE=$(cat /proc/cmdline 2>/dev/null || true)
ROOT_STATE=$(findmnt -no SOURCE,FSTYPE,OPTIONS / 2>/dev/null || true)
printf '%s\n' "$HOSTNAME_FQDN" > "$EVIDENCE_DIR/hostname-fqdn.txt"
printf '%s\n' "$SLACKWARE_VERSION" > "$EVIDENCE_DIR/slackware-version.txt"
printf '%s\n' "$RUNNING_KERNEL_ACTUAL" > "$EVIDENCE_DIR/uname-r.txt"
printf '%s\n' "$CMDLINE" > "$EVIDENCE_DIR/proc-cmdline.txt"
printf '%s\n' "$ROOT_STATE" > "$EVIDENCE_DIR/root-state.txt"

if [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" ]]; then
    pass "the live Slackware-current FQDN matches the frozen target binding"
else
    fail "the live Slackware-current FQDN does not match the frozen target binding"
fi
if [[ $SLACKWARE_VERSION == 'Slackware 15.0+'* ]]; then
    pass "the target identifies as Slackware-current"
else
    fail "the target does not identify as the expected Slackware-current installation"
fi
if [[ -d /sys/firmware/efi ]]; then
    pass "the target is running under UEFI firmware"
else
    fail "the target is not running under the expected UEFI firmware profile"
fi
if [[ $RUNNING_KERNEL_ACTUAL == "$EXPECTED_KERNEL" ]]; then
    pass "the running kernel matches the kernel characterized before target binding"
else
    fail "the running kernel changed after the pre-binding characterization"
fi

BOOT_IMAGE_COUNT=0
BOOT_IMAGE_VALUE=""
ROOT_TOKEN_COUNT=0
ROOT_TOKEN_VALUE=""
for token in $CMDLINE; do
    case "$token" in
        BOOT_IMAGE=*) BOOT_IMAGE_COUNT=$((BOOT_IMAGE_COUNT + 1)); BOOT_IMAGE_VALUE=${token#BOOT_IMAGE=} ;;
        root=*) ROOT_TOKEN_COUNT=$((ROOT_TOKEN_COUNT + 1)); ROOT_TOKEN_VALUE=${token#root=} ;;
    esac
done
if [[ $BOOT_IMAGE_COUNT -eq 1 && $BOOT_IMAGE_VALUE == /boot/vmlinuz-generic ]]; then
    pass "the running kernel was selected through /boot/vmlinuz-generic"
else
    fail "the running kernel command line does not uniquely select /boot/vmlinuz-generic"
fi
if [[ $ROOT_TOKEN_COUNT -eq 1 && $ROOT_TOKEN_VALUE == "$EXPECTED_ROOT_DEVICE" \
    && ${ROOT_STATE%% *} == "$EXPECTED_ROOT_DEVICE" ]]; then
    pass "the live root device matches the frozen direct-generic boot entry"
else
    fail "the live root device does not match the frozen direct-generic boot entry"
fi
RESOLVED_GENERIC=$(readlink -e /boot/vmlinuz-generic 2>/dev/null || true)
if [[ -L /boot/vmlinuz-generic && ${RESOLVED_GENERIC##*/} == "vmlinuz-$RUNNING_KERNEL_ACTUAL" ]]; then
    pass "the generic-kernel symlink resolves to the running kernel version"
else
    fail "the generic-kernel symlink does not resolve to the running kernel version"
fi
if [[ ! -e /etc/mkinitrd.conf && ! -L /etc/mkinitrd.conf \
    && ! -e /boot/initrd.gz && ! -L /boot/initrd.gz ]]; then
    pass "the source-level direct-generic preconditions contain neither mkinitrd.conf nor /boot/initrd.gz"
else
    fail "mkinitrd.conf or /boot/initrd.gz is present and the direct-generic source path is not valid"
fi
if [[ -f /boot/grub/grub.cfg && ! -L /boot/grub/grub.cfg \
    && -d /boot/grub && ! -L /boot/grub \
    && -x /usr/sbin/grub-mkconfig && -x /usr/bin/grub-script-check ]] \
    && /usr/bin/grub-script-check /boot/grub/grub.cfg >/dev/null 2>&1; then
    pass "the GRUB preparation and syntax-validation requirements are present"
else
    fail "the GRUB preparation or syntax-validation requirements are not satisfied"
fi

MENUENTRY_FILE="$EVIDENCE_DIR/direct-generic-menuentry.txt"
awk -v title="$EXPECTED_GRUB_MENUENTRY" '
    index($0, "menuentry \047" title "\047") == 1 { inside=1 }
    inside { print }
    inside && $0 ~ /^}/ { exit }
' /boot/grub/grub.cfg > "$MENUENTRY_FILE"
MENUENTRY_LINUX_COUNT=$(awk '$1 == "linux" || $1 == "linuxefi" { count++ } END { print count+0 }' "$MENUENTRY_FILE")
MENUENTRY_INITRD_COUNT=$(awk '$1 == "initrd" || $1 == "initrdefi" { count++ } END { print count+0 }' "$MENUENTRY_FILE")
MENUENTRY_EXPECTED_LINUX_COUNT=$(awk -v root="$EXPECTED_ROOT_DEVICE" '$1 == "linux" && $2 == "/boot/vmlinuz-generic" { for (i=3;i<=NF;i++) if ($i == "root=" root) ok=1; if (ok) count++ } END { print count+0 }' "$MENUENTRY_FILE")
if [[ -s $MENUENTRY_FILE && $MENUENTRY_LINUX_COUNT -eq 1 \
    && $MENUENTRY_EXPECTED_LINUX_COUNT -eq 1 && $MENUENTRY_INITRD_COUNT -eq 0 ]]; then
    pass "the frozen active direct-generic GRUB entry has one generic linux command and no initrd command"
else
    fail "the frozen direct-generic GRUB entry does not prove a no-initrd generic boot"
fi

if [[ $FAIL_COUNT -eq 0 ]]; then
    BOOT_PROFILE_MATCH=true
    pass "the live target independently matches the frozen $EXPECTED_BOOT_PROFILE profile"
else
    skip "runtime probing is withheld because target characterization failed"
fi

if [[ $BOOT_PROFILE_MATCH == true ]]; then
    # Source the accepted implementation as a library. The entry-point guard in
    # slack-update-reference.sh prevents the normal workflow from running here.
    # Only configuration loading and probe_boot_module are invoked.
    # shellcheck disable=SC1090
    source "$SOURCE_FILE"
    initialize_execution_environment
    export SLACK_UPDATE_CONFIG="$TEMPLATE"
    if load_configuration; then
        RUNNING_KERNEL="$RUNNING_KERNEL_ACTUAL"
        BOOT_CMDLINE_FILE=/proc/cmdline
        probe_boot_module
        {
            printf 'boot_mode=%s\n' "$BOOT_MODE"
            printf 'boot_module_state=%s\n' "$BOOT_MODULE_STATE"
            printf 'boot_module_run=%s\n' "$BOOT_MODULE_RUN"
            printf 'boot_preparation_layout=%s\n' "$BOOT_PREPARATION_LAYOUT"
            printf 'boot_initrd_available=%s\n' "$BOOT_INITRD_AVAILABLE"
            printf 'boot_grub_available=%s\n' "$BOOT_GRUB_AVAILABLE"
            printf 'boot_direct_generic_available=%s\n' "$BOOT_DIRECT_GENERIC_AVAILABLE"
            printf 'boot_module_reason=%s\n' "$BOOT_MODULE_REASON"
            printf 'boot_direct_generic_reason=%s\n' "$BOOT_DIRECT_GENERIC_REASON"
        } > "$EVIDENCE_DIR/runtime-probe.txt"
        if [[ $BOOT_MODE == auto \
            && $BOOT_MODULE_STATE == available \
            && $BOOT_MODULE_RUN -eq 1 \
            && $BOOT_PREPARATION_LAYOUT == direct-generic-no-initrd \
            && $BOOT_INITRD_AVAILABLE -eq 0 \
            && $BOOT_GRUB_AVAILABLE -eq 1 \
            && $BOOT_DIRECT_GENERIC_AVAILABLE -eq 1 \
            && -z $BOOT_MODULE_REASON \
            && -z $BOOT_DIRECT_GENERIC_REASON ]]; then
            RUNTIME_PROBE_ACCEPTED=true
            pass "boot=auto is available and runnable only through the validated direct-generic-no-initrd path"
        else
            fail "boot=auto did not produce the frozen direct-generic runtime verdict"
        fi
    else
        fail "the accepted configuration template could not be loaded by the accepted reference source"
    fi
fi

capture_packages "$EVIDENCE_DIR/packages.after.txt"
capture_boot_state "$EVIDENCE_DIR/boot-state.after.txt"
sha_file "$SOURCE_FILE" > "$EVIDENCE_DIR/source.after.sha256"
sha_file "$TEMPLATE" > "$EVIDENCE_DIR/template.after.sha256"

if cmp -s -- "$EVIDENCE_DIR/packages.before.txt" "$EVIDENCE_DIR/packages.after.txt" \
    && cmp -s -- "$EVIDENCE_DIR/boot-state.before.txt" "$EVIDENCE_DIR/boot-state.after.txt" \
    && cmp -s -- "$EVIDENCE_DIR/source.before.sha256" "$EVIDENCE_DIR/source.after.sha256" \
    && cmp -s -- "$EVIDENCE_DIR/template.before.sha256" "$EVIDENCE_DIR/template.after.sha256"; then
    SYSTEM_STATE_PRESERVED=true
    pass "runtime validation preserved package, boot, source, and template state"
else
    fail "runtime validation changed package, boot, source, or template state"
fi

if [[ $FAIL_COUNT -eq 0 && $BOOT_PROFILE_MATCH == true \
    && $RUNTIME_PROBE_ACCEPTED == true && $SYSTEM_STATE_PRESERVED == true ]]; then
    AUTHORIZATION_CONSUMED_BY_EXECUTION=true
    NEXT_STAGE=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-review
    pass "the single authorized Slackware-current execution completed and is ready for evidence review"
else
    skip "authorization review remains blocked because this execution did not satisfy every acceptance condition"
fi

cat > "$EVIDENCE_DIR/summary.txt" <<EOF_SUMMARY
schema=1
scenario=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current
target=$TARGET
hostname_fqdn=$HOSTNAME_FQDN
slackware_version=$SLACKWARE_VERSION
running_kernel=$RUNNING_KERNEL_ACTUAL
boot_image=$BOOT_IMAGE_VALUE
root_device=$ROOT_TOKEN_VALUE
required_boot_profile=$EXPECTED_BOOT_PROFILE
binding_policy_sha256=$POLICY_SHA256
execution_harness_sha256=$SCRIPT_SHA256
source_sha256=$SOURCE_SHA256
template_sha256=$TEMPLATE_SHA256
boot_profile_match=$BOOT_PROFILE_MATCH
runtime_probe_accepted=$RUNTIME_PROBE_ACCEPTED
system_state_preserved=$SYSTEM_STATE_PRESERVED
authorization_consumed_by_execution=$AUTHORIZATION_CONSUMED_BY_EXECUTION
repository_refresh_performed=false
package_mutation_performed=false
boot_mutation_performed=false
reboot_performed=false
passes=$PASS_COUNT
failures=$FAIL_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-configuration-module-mode-source-remediation-runtime-validation-${TIMESTAMP}.tar.gz"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$EVIDENCE_DIR")"
ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
    "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
printf 'Result: %s (%d passes, %d failures, %d skips); boot_profile_match=%s; runtime_probe_accepted=%s; system_state_preserved=%s; authorization_consumed_by_execution=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
    "$BOOT_PROFILE_MATCH" "$RUNTIME_PROBE_ACCEPTED" "$SYSTEM_STATE_PRESERVED" "$AUTHORIZATION_CONSUMED_BY_EXECUTION" "$NEXT_STAGE"

[[ $FAIL_COUNT -eq 0 ]]
