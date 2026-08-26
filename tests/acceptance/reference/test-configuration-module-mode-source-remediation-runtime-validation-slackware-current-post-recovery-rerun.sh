#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SOURCE_FILE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPOSITORY_ROOT/data/config/slack-update.conf"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review-policy.json"
STEP145_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review-policy.json"
STEP145_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.tsv"
BINDING_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_RERUN_AUTHORIZATION_POLICY_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun.sh \
    --target slackware-current \
    --confirm-hostname-fqdn vbox-slackcurrent.vbox-slackcurrent.org \
    --confirm-rerun-authorization-policy-sha256 SHA256

Run the single authorized non-mutating Slackware-current runtime validation
rerun after the accepted boot-selection recovery. The live session must still
use the frozen direct-generic/no-initrd entry with root=/dev/sda2. Any target,
boot-profile, source, policy, or preservation mismatch is a hard stop before
the runtime probe is invoked.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-rerun-authorization-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_RERUN_AUTHORIZATION_POLICY_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance validation must run as root.\n' >&2
    exit 2
fi
for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_RERUN_AUTHORIZATION_POLICY_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done
[[ $TARGET == slackware-current ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_RERUN_AUTHORIZATION_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid rerun-authorization-policy SHA-256.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
BOOT_PROFILE_MATCH=false
RUNTIME_PROBE_INVOKED=false
RUNTIME_PROBE_ACCEPTED=false
SYSTEM_STATE_PRESERVED=false
AUTHORIZATION_CONSUMED_BY_EXECUTION=false
NEXT_STAGE=post-recovery-rerun-manual-review-required

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

for required in "$0" "$SOURCE_FILE" "$TEMPLATE" "$POLICY" "$STEP145_POLICY" "$STEP145_RECORD" "$BINDING_POLICY"; do
    [[ -f $required && ! -L $required ]] || fail "a required runtime-validation file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/configuration-module-mode-source-remediation-runtime-validation
EVIDENCE_DIR="$EVIDENCE_PARENT/${TARGET}-post-recovery-rerun-${TIMESTAMP}"
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
STEP145_POLICY_SHA256=$(sha_file "$STEP145_POLICY")
STEP145_RECORD_SHA256=$(sha_file "$STEP145_RECORD")
BINDING_POLICY_SHA256=$(sha_file "$BINDING_POLICY")
SOURCE_SHA256=$(sha_file "$SOURCE_FILE")
TEMPLATE_SHA256=$(sha_file "$TEMPLATE")
EXPECTED_SCRIPT_SHA256=$(json_value "$POLICY" slackware_current.execution_harness_sha256)
EXPECTED_STEP145_POLICY_SHA256=$(json_value "$POLICY" step145_manual_review_policy_sha256)
EXPECTED_STEP145_RECORD_SHA256=$(json_value "$POLICY" step145_manual_review_record_sha256)
EXPECTED_BINDING_POLICY_SHA256=$(json_value "$POLICY" step132_target_binding_policy_sha256)
EXPECTED_SOURCE_SHA256=$(json_value "$POLICY" accepted_source_sha256)
EXPECTED_TEMPLATE_SHA256=$(json_value "$POLICY" configuration_template_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$POLICY" slackware_current.hostname_fqdn)
EXPECTED_BOOT_PROFILE=$(json_value "$POLICY" slackware_current.required_boot_profile)
EXPECTED_KERNEL=$(json_value "$POLICY" slackware_current.accepted_kernel)
EXPECTED_BOOT_IMAGE=$(json_value "$POLICY" slackware_current.expected_boot_image)
EXPECTED_GRUB_MENUENTRY=$(json_value "$POLICY" slackware_current.direct_generic_menuentry)
EXPECTED_ROOT_DEVICE=$(json_value "$POLICY" slackware_current.expected_root_device)
EXPECTED_ROOT_TOKEN=$(json_value "$POLICY" slackware_current.expected_live_root_token)

[[ $POLICY_SHA256 == "$CONFIRM_RERUN_AUTHORIZATION_POLICY_SHA256" ]] \
    && pass "the rerun is bound to the explicitly confirmed step-146 authorization policy" \
    || fail "the step-146 rerun-authorization policy SHA-256 does not match the explicit confirmation"
[[ $STEP145_POLICY_SHA256 == "$EXPECTED_STEP145_POLICY_SHA256" ]] \
    && pass "the rerun preserves the exact accepted step-145 recovery-review policy" \
    || fail "the accepted step-145 recovery-review policy identity changed"
[[ $STEP145_RECORD_SHA256 == "$EXPECTED_STEP145_RECORD_SHA256" ]] \
    && pass "the rerun preserves the exact accepted step-145 recovery-review record" \
    || fail "the accepted step-145 recovery-review record identity changed"
[[ $BINDING_POLICY_SHA256 == "$EXPECTED_BINDING_POLICY_SHA256" ]] \
    && pass "the rerun preserves the exact accepted step-132 target binding" \
    || fail "the accepted step-132 target-binding policy identity changed"
[[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" ]] \
    && pass "the Slackware-current rerun harness matches the frozen step-146 SHA-256" \
    || fail "the Slackware-current rerun harness does not match the frozen step-146 SHA-256"
[[ $SOURCE_SHA256 == "$EXPECTED_SOURCE_SHA256" ]] \
    && pass "the target carries the accepted remediated reference implementation" \
    || fail "the target reference implementation SHA-256 is not the accepted remediated source"
[[ $TEMPLATE_SHA256 == "$EXPECTED_TEMPLATE_SHA256" ]] \
    && pass "the target carries the frozen configuration template" \
    || fail "the target configuration template SHA-256 is not the frozen accepted input"

if [[ $(json_value "$POLICY" authorization.machine_execution_authorized) == true \
    && $(json_value "$POLICY" authorization.authorization_consumable) == true \
    && $(json_value "$POLICY" authorization.machine_execution_limit_total) == 1 \
    && $(json_value "$POLICY" authorization.reboot_limit) == 0 \
    && $(json_value "$POLICY" prior_authorizations.step139_rerun_authorization_reusable) == false \
    && $(json_value "$POLICY" prior_authorizations.step143_recovery_authorization_reusable) == false ]]; then
    pass "the step-146 policy grants exactly one fresh current-VM rerun and reuses no consumed authorization"
else
    fail "the step-146 policy does not expose the frozen fresh single-use rerun envelope"
fi

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
        printf 'grub_cfg_sha256=%s\n' "$(optional_hash /boot/grub/grub.cfg)"
        printf 'custom_grub_script_sha256=%s\n' "$(optional_hash /etc/grub.d/41_slack-update-direct-generic)"
        printf 'grubenv_sha256=%s\n' "$(optional_hash /boot/grub/grubenv)"
        printf 'default_grub_sha256=%s\n' "$(optional_hash /etc/default/grub)"
    } > "$destination"
}

capture_packages "$EVIDENCE_DIR/packages.before.txt"
capture_slackpkg_metadata "$EVIDENCE_DIR/slackpkg-metadata.before.txt"
capture_boot_state "$EVIDENCE_DIR/boot-state.before.txt"
sha_file "$SOURCE_FILE" > "$EVIDENCE_DIR/source.before.sha256"
sha_file "$TEMPLATE" > "$EVIDENCE_DIR/template.before.sha256"

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
SLACKWARE_VERSION=$(cat /etc/slackware-version 2>/dev/null || true)
RUNNING_KERNEL_ACTUAL=$(uname -r)
CMDLINE=$(cat /proc/cmdline 2>/dev/null || true)
ROOT_STATE=$(findmnt -no SOURCE,FSTYPE,OPTIONS / 2>/dev/null || true)
MOUNTED_ROOT=${ROOT_STATE%% *}
printf '%s\n' "$HOSTNAME_FQDN" > "$EVIDENCE_DIR/hostname-fqdn.txt"
printf '%s\n' "$SLACKWARE_VERSION" > "$EVIDENCE_DIR/slackware-version.txt"
printf '%s\n' "$RUNNING_KERNEL_ACTUAL" > "$EVIDENCE_DIR/uname-r.txt"
printf '%s\n' "$CMDLINE" > "$EVIDENCE_DIR/proc-cmdline.txt"
printf '%s\n' "$ROOT_STATE" > "$EVIDENCE_DIR/root-state.txt"

[[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" ]] \
    && pass "the live Slackware-current FQDN matches the frozen target binding" \
    || fail "the live Slackware-current FQDN does not match the frozen target binding"
[[ $SLACKWARE_VERSION == 'Slackware 15.0+'* ]] \
    && pass "the target identifies as Slackware-current" \
    || fail "the target does not identify as the expected Slackware-current installation"
[[ -d /sys/firmware/efi ]] \
    && pass "the target is running under UEFI firmware" \
    || fail "the target is not running under the expected UEFI firmware profile"
[[ $RUNNING_KERNEL_ACTUAL == "$EXPECTED_KERNEL" ]] \
    && pass "the running kernel remains the frozen 6.18.45 target" \
    || fail "the running kernel changed after the accepted recovery review"

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
[[ $BOOT_IMAGE_COUNT -eq 1 && $BOOT_IMAGE_VALUE == "$EXPECTED_BOOT_IMAGE" ]] \
    && pass "the recovered session still uses the frozen generic boot image" \
    || fail "the recovered session does not uniquely select the frozen generic boot image"
[[ $ROOT_TOKEN_COUNT -eq 1 && $ROOT_TOKEN_VALUE == "$EXPECTED_ROOT_TOKEN" && $MOUNTED_ROOT == "$EXPECTED_ROOT_DEVICE" ]] \
    && pass "the recovered live root token and mounted root remain exactly /dev/sda2" \
    || fail "the live session no longer proves the accepted recovered root selection"

RESOLVED_GENERIC=$(readlink -e /boot/vmlinuz-generic 2>/dev/null || true)
[[ -L /boot/vmlinuz-generic && ${RESOLVED_GENERIC##*/} == "vmlinuz-$RUNNING_KERNEL_ACTUAL" ]] \
    && pass "the generic-kernel symlink resolves to the running kernel version" \
    || fail "the generic-kernel symlink does not resolve to the running kernel version"
[[ ! -e /etc/mkinitrd.conf && ! -L /etc/mkinitrd.conf && ! -e /boot/initrd.gz && ! -L /boot/initrd.gz ]] \
    && pass "the direct-generic source preconditions still contain neither mkinitrd.conf nor /boot/initrd.gz" \
    || fail "mkinitrd.conf or /boot/initrd.gz is present and the direct-generic source path is not valid"

if [[ -f /boot/grub/grub.cfg && ! -L /boot/grub/grub.cfg \
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
MENUENTRY_EXPECTED_LINUX_COUNT=$(awk -v root="$EXPECTED_ROOT_DEVICE" '$1 == "linux" && $2 == "/boot/vmlinuz-generic" { ok=0; for (i=3;i<=NF;i++) if ($i == "root=" root) ok=1; if (ok) count++ } END { print count+0 }' "$MENUENTRY_FILE")
if [[ -s $MENUENTRY_FILE && $MENUENTRY_LINUX_COUNT -eq 1 && $MENUENTRY_EXPECTED_LINUX_COUNT -eq 1 && $MENUENTRY_INITRD_COUNT -eq 0 ]]; then
    pass "the frozen direct-generic GRUB entry still has one generic linux command and no initrd command"
else
    fail "the frozen direct-generic GRUB entry no longer proves the recovered no-initrd generic boot"
fi

if [[ $FAIL_COUNT -eq 0 ]]; then
    BOOT_PROFILE_MATCH=true
    pass "the live target independently matches the recovered $EXPECTED_BOOT_PROFILE profile"
else
    skip "runtime probing is withheld because fail-closed target characterization failed"
fi

if [[ $BOOT_PROFILE_MATCH == true ]]; then
    # Source the accepted implementation as a library. The entry-point guard
    # prevents the normal update workflow from running in this acceptance test.
    # Only environment initialization, configuration loading, and the boot
    # module runtime probe are invoked.
    # shellcheck disable=SC1090
    source "$SOURCE_FILE"
    initialize_execution_environment
    export SLACK_UPDATE_CONFIG="$TEMPLATE"
    if load_configuration; then
        RUNNING_KERNEL="$RUNNING_KERNEL_ACTUAL"
        BOOT_CMDLINE_FILE=/proc/cmdline
        RUNTIME_PROBE_INVOKED=true
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
            pass "boot=auto is available and runnable through the recovered direct-generic-no-initrd path"
        else
            fail "boot=auto did not produce the frozen direct-generic runtime verdict"
        fi
    else
        fail "the accepted configuration template could not be loaded by the accepted reference source"
    fi
fi

capture_packages "$EVIDENCE_DIR/packages.after.txt"
capture_slackpkg_metadata "$EVIDENCE_DIR/slackpkg-metadata.after.txt"
capture_boot_state "$EVIDENCE_DIR/boot-state.after.txt"
sha_file "$SOURCE_FILE" > "$EVIDENCE_DIR/source.after.sha256"
sha_file "$TEMPLATE" > "$EVIDENCE_DIR/template.after.sha256"

if cmp -s -- "$EVIDENCE_DIR/packages.before.txt" "$EVIDENCE_DIR/packages.after.txt" \
    && cmp -s -- "$EVIDENCE_DIR/slackpkg-metadata.before.txt" "$EVIDENCE_DIR/slackpkg-metadata.after.txt" \
    && cmp -s -- "$EVIDENCE_DIR/boot-state.before.txt" "$EVIDENCE_DIR/boot-state.after.txt" \
    && cmp -s -- "$EVIDENCE_DIR/source.before.sha256" "$EVIDENCE_DIR/source.after.sha256" \
    && cmp -s -- "$EVIDENCE_DIR/template.before.sha256" "$EVIDENCE_DIR/template.after.sha256"; then
    SYSTEM_STATE_PRESERVED=true
    pass "runtime validation preserved package, Slackpkg metadata, boot, source, and template state"
else
    fail "runtime validation changed package, Slackpkg metadata, boot, source, or template state"
fi

if [[ $FAIL_COUNT -eq 0 && $BOOT_PROFILE_MATCH == true && $RUNTIME_PROBE_INVOKED == true \
    && $RUNTIME_PROBE_ACCEPTED == true && $SYSTEM_STATE_PRESERVED == true ]]; then
    AUTHORIZATION_CONSUMED_BY_EXECUTION=true
    NEXT_STAGE=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review
    pass "the fresh single-use Slackware-current rerun completed and is ready for evidence review"
else
    skip "the authorization is not accepted as a successful rerun because every acceptance condition was not satisfied"
fi

cat > "$EVIDENCE_DIR/summary.txt" <<EOF_SUMMARY
schema=1
scenario=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun
target=$TARGET
hostname_fqdn=$HOSTNAME_FQDN
slackware_version=$SLACKWARE_VERSION
running_kernel=$RUNNING_KERNEL_ACTUAL
boot_image=$BOOT_IMAGE_VALUE
root_device=$ROOT_TOKEN_VALUE
mounted_root=$MOUNTED_ROOT
required_boot_profile=$EXPECTED_BOOT_PROFILE
rerun_authorization_policy_sha256=$POLICY_SHA256
step145_manual_review_policy_sha256=$STEP145_POLICY_SHA256
step145_manual_review_record_sha256=$STEP145_RECORD_SHA256
accepted_target_binding_policy_sha256=$BINDING_POLICY_SHA256
execution_harness_sha256=$SCRIPT_SHA256
source_sha256=$SOURCE_SHA256
template_sha256=$TEMPLATE_SHA256
boot_profile_match=$BOOT_PROFILE_MATCH
runtime_probe_invoked=$RUNTIME_PROBE_INVOKED
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

ARCHIVE="$EVIDENCE_PARENT/${TARGET}-configuration-module-mode-source-remediation-runtime-validation-post-recovery-rerun-${TIMESTAMP}.tar.gz"
tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$EVIDENCE_DIR")"
ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"

printf 'Evidence archive: %s\n' "$ARCHIVE"
printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
    "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
printf 'Result: %s (%d passes, %d failures, %d skips); boot_profile_match=%s; runtime_probe_invoked=%s; runtime_probe_accepted=%s; system_state_preserved=%s; authorization_consumed_by_execution=%s; next_stage=%s\n' \
    "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
    "$BOOT_PROFILE_MATCH" "$RUNTIME_PROBE_INVOKED" "$RUNTIME_PROBE_ACCEPTED" "$SYSTEM_STATE_PRESERVED" "$AUTHORIZATION_CONSUMED_BY_EXECUTION" "$NEXT_STAGE"

[[ $FAIL_COUNT -eq 0 ]]
