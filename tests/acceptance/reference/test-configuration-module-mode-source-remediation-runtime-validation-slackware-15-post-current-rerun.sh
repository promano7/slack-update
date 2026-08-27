#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SOURCE_FILE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPOSITORY_ROOT/data/config/slack-update.conf"
AUTHORIZATION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review-policy.json"
AUTHORIZATION_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization.tsv"
STEP148_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
STEP148_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
TARGET_BINDING_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
HISTORICAL_HARNESS="$REPOSITORY_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15.sh"
ACCEPTED_ELILO_CLOSURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_AUTHORIZATION_POLICY_SHA256=""
CONFIRM_STEP148_REVIEW_POLICY_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
    --confirm-authorization-policy-sha256 SHA256 \
    --confirm-step148-review-policy-sha256 SHA256

Run the single authorized non-mutating Slackware 15.0 runtime validation after
accepted Slackware-current source-remediation validation. The execution is
bound to the accepted remediated source and the step-149 authorization. It does
not authorize package changes, repository refresh, boot changes, or reboot.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-authorization-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_AUTHORIZATION_POLICY_SHA256=$2; shift 2 ;;
        --confirm-step148-review-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_STEP148_REVIEW_POLICY_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance validation must run as root.\n' >&2
    exit 2
fi
for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_AUTHORIZATION_POLICY_SHA256" "$CONFIRM_STEP148_REVIEW_POLICY_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done
[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_AUTHORIZATION_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid authorization-policy SHA-256.\n' >&2; exit 2; }
[[ $CONFIRM_STEP148_REVIEW_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid step-148 review-policy SHA-256.\n' >&2; exit 2; }

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
BOOT_PROFILE_MATCH=false
RUNTIME_PROBE_INVOKED=false
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

for required in "$0" "$SOURCE_FILE" "$TEMPLATE" "$AUTHORIZATION_POLICY" "$AUTHORIZATION_RECORD" "$STEP148_POLICY" "$STEP148_RECORD" "$TARGET_BINDING_POLICY" "$HISTORICAL_HARNESS" "$ACCEPTED_ELILO_CLOSURE"; do
    [[ -f $required && ! -L $required ]] || fail "a required runtime-validation file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/configuration-module-mode-source-remediation-runtime-validation
EVIDENCE_DIR="$EVIDENCE_PARENT/slackware-15-post-current-rerun-${TIMESTAMP}"
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
AUTHORIZATION_RECORD_SHA256=$(sha_file "$AUTHORIZATION_RECORD")
STEP148_POLICY_SHA256=$(sha_file "$STEP148_POLICY")
STEP148_RECORD_SHA256=$(sha_file "$STEP148_RECORD")
TARGET_BINDING_POLICY_SHA256=$(sha_file "$TARGET_BINDING_POLICY")
HISTORICAL_HARNESS_SHA256=$(sha_file "$HISTORICAL_HARNESS")
SOURCE_SHA256=$(sha_file "$SOURCE_FILE")
TEMPLATE_SHA256=$(sha_file "$TEMPLATE")
ACCEPTED_ELILO_CLOSURE_SHA256=$(sha_file "$ACCEPTED_ELILO_CLOSURE")

EXPECTED_SCRIPT_SHA256=$(json_value "$AUTHORIZATION_POLICY" execution.execution_harness_sha256)
EXPECTED_RECORD_SHA256=$(json_value "$AUTHORIZATION_POLICY" authorization_record_sha256)
EXPECTED_STEP148_POLICY_SHA256=$(json_value "$AUTHORIZATION_POLICY" step148_review_policy_sha256)
EXPECTED_STEP148_RECORD_SHA256=$(json_value "$AUTHORIZATION_POLICY" step148_review_record_sha256)
EXPECTED_BINDING_POLICY_SHA256=$(json_value "$AUTHORIZATION_POLICY" step132_target_binding_policy_sha256)
EXPECTED_HISTORICAL_HARNESS_SHA256=$(json_value "$AUTHORIZATION_POLICY" obsolete_step132_slackware15_harness_sha256)
EXPECTED_SOURCE_SHA256=$(json_value "$AUTHORIZATION_POLICY" accepted_source_sha256)
EXPECTED_TEMPLATE_SHA256=$(json_value "$AUTHORIZATION_POLICY" configuration_template_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$AUTHORIZATION_POLICY" target.hostname_fqdn)
EXPECTED_BOOT_PROFILE=$(json_value "$AUTHORIZATION_POLICY" target.required_boot_profile)
EXPECTED_KERNEL=$(json_value "$AUTHORIZATION_POLICY" target.accepted_kernel)
EXPECTED_BOOT_IMAGE_SUFFIX=$(json_value "$AUTHORIZATION_POLICY" target.required_boot_image_suffix)
EXPECTED_ELILO_SHA256=$(json_value "$AUTHORIZATION_POLICY" target.elilo_conf_sha256)
EXPECTED_ACCEPTED_ELILO_CLOSURE_SHA256=$(json_value "$AUTHORIZATION_POLICY" target.accepted_closure_record_sha256)

[[ $AUTHORIZATION_POLICY_SHA256 == "$CONFIRM_AUTHORIZATION_POLICY_SHA256" ]] \
    && pass "the execution is bound to the explicitly confirmed step-149 authorization policy" \
    || fail "the step-149 authorization policy SHA-256 does not match the explicit confirmation"
[[ $STEP148_POLICY_SHA256 == "$CONFIRM_STEP148_REVIEW_POLICY_SHA256" && $STEP148_POLICY_SHA256 == "$EXPECTED_STEP148_POLICY_SHA256" ]] \
    && pass "the execution is bound to the explicitly confirmed accepted step-148 review policy" \
    || fail "the step-148 review policy SHA-256 does not match the authorization boundary"
[[ $AUTHORIZATION_RECORD_SHA256 == "$EXPECTED_RECORD_SHA256" ]] \
    && pass "the step-149 authorization record matches the frozen policy" \
    || fail "the step-149 authorization record identity changed"
[[ $STEP148_RECORD_SHA256 == "$EXPECTED_STEP148_RECORD_SHA256" ]] \
    && pass "the accepted step-148 review record identity is preserved" \
    || fail "the accepted step-148 review record identity changed"
[[ $TARGET_BINDING_POLICY_SHA256 == "$EXPECTED_BINDING_POLICY_SHA256" ]] \
    && pass "the historical step-132 target identity remains frozen" \
    || fail "the step-132 target-binding policy identity changed"
[[ $HISTORICAL_HARNESS_SHA256 == "$EXPECTED_HISTORICAL_HARNESS_SHA256" ]] \
    && pass "the obsolete step-132 Slackware 15.0 harness remains identifiable and is not reused" \
    || fail "the obsolete step-132 Slackware 15.0 harness identity changed"
[[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" ]] \
    && pass "the Slackware 15.0 execution harness matches the fresh step-149 frozen SHA-256" \
    || fail "the Slackware 15.0 execution harness does not match the fresh step-149 SHA-256"
[[ $SOURCE_SHA256 == "$EXPECTED_SOURCE_SHA256" ]] \
    && pass "the target carries the accepted remediated reference implementation" \
    || fail "the target reference implementation SHA-256 is not the accepted remediated source"
[[ $TEMPLATE_SHA256 == "$EXPECTED_TEMPLATE_SHA256" ]] \
    && pass "the target carries the frozen configuration template" \
    || fail "the target configuration template SHA-256 is not the accepted input"
[[ $ACCEPTED_ELILO_CLOSURE_SHA256 == "$EXPECTED_ACCEPTED_ELILO_CLOSURE_SHA256" ]] \
    && pass "the established Slackware 15.0 target remains bound to its accepted ELILO closure record" \
    || fail "the accepted Slackware 15.0 ELILO closure record is not the frozen input"

if python3 - "$STEP148_POLICY" "$AUTHORIZATION_POLICY" <<'PY_RELEASE'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    review = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    authorization = json.load(handle)
assert review["schema"] == 1
assert review["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review"
assert review["source_remediation"]["exercised"] is True
assert review["source_remediation"]["accepted"] is True
assert review["slackware_current"]["runtime_validation_accepted"] is True
assert review["slackware_15"]["released_to_fresh_authorization_review"] is True
assert review["slackware_15"]["execution_authorized"] is False
assert review["slackware_15"]["step132_slackware15_execution_harness_reusable"] is False
assert review["accepted_source_sha256"] == authorization["accepted_source_sha256"]
assert review["configuration_template_sha256"] == authorization["configuration_template_sha256"]
assert review["slackware_15"]["step132_target_binding_policy_sha256"] == authorization["step132_target_binding_policy_sha256"]
assert review["slackware_15"]["step132_slackware15_execution_harness_sha256"] == authorization["obsolete_step132_slackware15_harness_sha256"]
assert authorization["authorization"]["execution_authorized"] is True
assert authorization["authorization"]["authorization_consumable"] is True
assert authorization["authorization"]["machine_execution_limit"] == 1
assert authorization["authorization"]["reboot_limit"] == 0
assert authorization["authorization"]["repository_refresh_authorized"] is False
assert authorization["authorization"]["package_mutation_authorized"] is False
assert authorization["authorization"]["boot_mutation_authorized"] is False
assert authorization["authorization"]["source_change_authorized"] is False
assert authorization["authorization"]["configuration_template_change_authorized"] is False
assert authorization["authorization"]["contract_change_authorized"] is False
PY_RELEASE
then
    pass "step 148 releases only this fresh single-use Slackware 15.0 authorization"
else
    fail "the accepted step-148 release and step-149 authorization do not form the required fresh boundary"
fi

if [[ $FAIL_COUNT -eq 0 ]]; then
    AUTHORIZATION_CONSUMED_BY_EXECUTION=true
    pass "the single-use step-149 authorization is consumed by this execution attempt"
else
    skip "machine characterization is withheld because repository authorization checks failed"
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
        printf 'elilo_conf_sha256=%s\n' "$(optional_hash /boot/efi/EFI/Slackware/elilo.conf)"
        printf 'mkinitrd_config_sha256=%s\n' "$(optional_hash /etc/mkinitrd.conf)"
        printf 'initrd_default_output_sha256=%s\n' "$(optional_hash /boot/initrd.gz)"
        printf 'grub_directory_kind='; if [[ -L /boot/grub ]]; then printf 'symlink\n'; elif [[ -d /boot/grub ]]; then printf 'directory\n'; else printf 'absent\n'; fi
    } > "$destination"
}

if [[ $AUTHORIZATION_CONSUMED_BY_EXECUTION == true ]]; then
    capture_packages "$EVIDENCE_DIR/packages.before.txt"
    capture_slackpkg_metadata "$EVIDENCE_DIR/slackpkg-metadata.before.txt"
    capture_boot_state "$EVIDENCE_DIR/boot-state.before.txt"
    sha_file "$SOURCE_FILE" > "$EVIDENCE_DIR/source.before.sha256"
    sha_file "$TEMPLATE" > "$EVIDENCE_DIR/template.before.sha256"

    HOSTNAME_FQDN=$(hostname -f 2>/dev/null || true)
    SLACKWARE_VERSION=$(cat /etc/slackware-version 2>/dev/null || true)
    RUNNING_KERNEL_ACTUAL=$(uname -r)
    CMDLINE=$(cat /proc/cmdline 2>/dev/null || true)
    ELILO_CONF=/boot/efi/EFI/Slackware/elilo.conf
    ELILO_SHA256=$(sha_file "$ELILO_CONF" 2>/dev/null || true)
    printf '%s\n' "$HOSTNAME_FQDN" > "$EVIDENCE_DIR/hostname-fqdn.txt"
    printf '%s\n' "$SLACKWARE_VERSION" > "$EVIDENCE_DIR/slackware-version.txt"
    printf '%s\n' "$RUNNING_KERNEL_ACTUAL" > "$EVIDENCE_DIR/uname-r.txt"
    printf '%s\n' "$CMDLINE" > "$EVIDENCE_DIR/proc-cmdline.txt"
    cp -p -- "$ELILO_CONF" "$EVIDENCE_DIR/elilo.conf.observed" 2>/dev/null || true

    [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" ]] \
        && pass "the live Slackware 15.0 FQDN matches the frozen target binding" \
        || fail "the live Slackware 15.0 FQDN does not match the frozen target binding"
    [[ $SLACKWARE_VERSION == 'Slackware 15.0' ]] \
        && pass "the target identifies as Slackware 15.0" \
        || fail "the target does not identify as the expected Slackware 15.0 installation"
    [[ -d /sys/firmware/efi ]] \
        && pass "the target is running under UEFI firmware" \
        || fail "the target is not running under the accepted UEFI profile"
    [[ $RUNNING_KERNEL_ACTUAL == "$EXPECTED_KERNEL" ]] \
        && pass "the running kernel matches the accepted Slackware 15.0 ELILO closure" \
        || fail "the running kernel no longer matches the accepted Slackware 15.0 ELILO closure"

    BOOT_IMAGE_COUNT=0
    BOOT_IMAGE_VALUE=""
    for token in $CMDLINE; do
        case "$token" in
            BOOT_IMAGE=*) BOOT_IMAGE_COUNT=$((BOOT_IMAGE_COUNT + 1)); BOOT_IMAGE_VALUE=${token#BOOT_IMAGE=} ;;
        esac
    done
    [[ $BOOT_IMAGE_COUNT -eq 1 && $BOOT_IMAGE_VALUE == *"$EXPECTED_BOOT_IMAGE_SUFFIX" ]] \
        && pass "the live kernel command line matches the accepted ELILO generic-kernel boot identity" \
        || fail "the live kernel command line does not match the accepted ELILO generic-kernel boot identity"
    [[ -f $ELILO_CONF && ! -L $ELILO_CONF && $ELILO_SHA256 == "$EXPECTED_ELILO_SHA256" ]] \
        && pass "the active ELILO configuration matches the accepted generic+initrd closure" \
        || fail "the active ELILO configuration no longer matches the accepted generic+initrd closure"
    [[ -f /etc/mkinitrd.conf && ! -L /etc/mkinitrd.conf ]] \
        && pass "the live target exposes the expected mkinitrd-managed capability input" \
        || fail "the accepted ELILO target no longer exposes its regular mkinitrd configuration"
    [[ ! -d /boot/grub && ! -L /boot/grub ]] \
        && pass "the active ELILO target has no GRUB directory that could create a false supported preparation path" \
        || fail "an incidental /boot/grub path exists and could make the ELILO target appear runnable"

    if [[ $FAIL_COUNT -eq 0 ]]; then
        BOOT_PROFILE_MATCH=true
        pass "the live target independently matches the frozen $EXPECTED_BOOT_PROFILE profile"
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
                && $BOOT_MODULE_STATE == unavailable \
                && $BOOT_MODULE_RUN -eq 0 \
                && $BOOT_PREPARATION_LAYOUT == unknown \
                && $BOOT_INITRD_AVAILABLE -eq 1 \
                && $BOOT_GRUB_AVAILABLE -eq 0 \
                && $BOOT_DIRECT_GENERIC_AVAILABLE -eq 0 \
                && $BOOT_MODULE_REASON == 'no supported initrd or GRUB preparation path was detected' ]]; then
                RUNTIME_PROBE_ACCEPTED=true
                pass "boot=auto fails closed on the real ELILO initrd-only capability set with the accepted remediated source"
            else
                fail "boot=auto did not fail closed on the frozen Slackware 15.0 ELILO target"
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
fi

if [[ $FAIL_COUNT -eq 0 && $BOOT_PROFILE_MATCH == true \
    && $RUNTIME_PROBE_INVOKED == true && $RUNTIME_PROBE_ACCEPTED == true \
    && $SYSTEM_STATE_PRESERVED == true && $AUTHORIZATION_CONSUMED_BY_EXECUTION == true ]]; then
    NEXT_STAGE=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-review
    pass "the single authorized Slackware 15.0 execution completed and is ready for evidence review"
else
    skip "evidence acceptance remains blocked because this execution did not satisfy every acceptance condition"
fi

HOSTNAME_FQDN=${HOSTNAME_FQDN:-$(hostname -f 2>/dev/null || true)}
SLACKWARE_VERSION=${SLACKWARE_VERSION:-$(cat /etc/slackware-version 2>/dev/null || true)}
RUNNING_KERNEL_ACTUAL=${RUNNING_KERNEL_ACTUAL:-$(uname -r)}
BOOT_IMAGE_VALUE=${BOOT_IMAGE_VALUE:-}
ELILO_SHA256=${ELILO_SHA256:-$(sha_file /boot/efi/EFI/Slackware/elilo.conf 2>/dev/null || true)}
cat > "$EVIDENCE_DIR/summary.txt" <<EOF_SUMMARY
schema=1
scenario=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun
target=$TARGET
hostname_fqdn=$HOSTNAME_FQDN
slackware_version=$SLACKWARE_VERSION
running_kernel=$RUNNING_KERNEL_ACTUAL
boot_image=$BOOT_IMAGE_VALUE
required_boot_profile=$EXPECTED_BOOT_PROFILE
authorization_policy_sha256=$AUTHORIZATION_POLICY_SHA256
authorization_record_sha256=$AUTHORIZATION_RECORD_SHA256
step148_review_policy_sha256=$STEP148_POLICY_SHA256
step148_review_record_sha256=$STEP148_RECORD_SHA256
target_binding_policy_sha256=$TARGET_BINDING_POLICY_SHA256
obsolete_step132_slackware15_harness_sha256=$HISTORICAL_HARNESS_SHA256
execution_harness_sha256=$SCRIPT_SHA256
source_sha256=$SOURCE_SHA256
template_sha256=$TEMPLATE_SHA256
accepted_elilo_closure_record_sha256=$ACCEPTED_ELILO_CLOSURE_SHA256
elilo_conf_sha256=$ELILO_SHA256
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

ARCHIVE="$EVIDENCE_PARENT/slackware-15-configuration-module-mode-source-remediation-runtime-validation-post-current-rerun-${TIMESTAMP}.tar.gz"
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
