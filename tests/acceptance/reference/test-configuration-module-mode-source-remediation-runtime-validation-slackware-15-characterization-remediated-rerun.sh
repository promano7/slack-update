#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SOURCE_FILE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPOSITORY_ROOT/data/config/slack-update.conf"
IMPLEMENTATION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-policy.json"
STEP153_AUTHORIZATION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
TARGET_BINDING_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
ACCEPTED_ELILO_CLOSURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
CONSUMED_STEP150_HARNESS="$REPOSITORY_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
EXECUTION_AUTHORIZATION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"

TARGET=""
CONFIRM_HOSTNAME_FQDN=""
CONFIRM_EXECUTION_AUTHORIZATION_POLICY_SHA256=""

usage() {
    cat <<'USAGE'
Usage:
  test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh \
    --target slackware-15.0 \
    --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
    --confirm-execution-authorization-policy-sha256 SHA256

Run the separately authorized non-mutating Slackware 15.0 characterization-
remediated runtime validation. This harness is intentionally non-consumable
until a later execution-authorization policy exists and its SHA-256 is
explicitly confirmed. It never authorizes repository refresh, package changes,
boot changes, source/template changes, or reboot.
USAGE
}

while (($#)); do
    case "$1" in
        --target) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; TARGET=$2; shift 2 ;;
        --confirm-hostname-fqdn) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
        --confirm-execution-authorization-policy-sha256) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; CONFIRM_EXECUTION_AUTHORIZATION_POLICY_SHA256=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

for value in "$TARGET" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_EXECUTION_AUTHORIZATION_POLICY_SHA256"; do
    [[ -n $value ]] || { usage >&2; exit 2; }
done
[[ $TARGET == slackware-15.0 ]] || { printf 'ERROR: unsupported target: %s\n' "$TARGET" >&2; exit 2; }
[[ $CONFIRM_EXECUTION_AUTHORIZATION_POLICY_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: invalid execution-authorization-policy SHA-256.\n' >&2; exit 2; }

# The successor harness must remain impossible to consume until a later
# repository-only execution authorization creates this exact policy file.
if [[ ! -f $EXECUTION_AUTHORIZATION_POLICY || -L $EXECUTION_AUTHORIZATION_POLICY ]]; then
    printf 'ERROR: Slackware 15.0 execution is not authorized; missing safe execution-authorization policy.\n' >&2
    exit 3
fi

if [[ $EUID -ne 0 ]]; then
    printf 'ERROR: this acceptance validation must run as root.\n' >&2
    exit 2
fi

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
CORE_IDENTITY_MATCH=false
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

for required in \
    "$0" \
    "$SOURCE_FILE" \
    "$TEMPLATE" \
    "$IMPLEMENTATION_POLICY" \
    "$STEP153_AUTHORIZATION_POLICY" \
    "$TARGET_BINDING_POLICY" \
    "$ACCEPTED_ELILO_CLOSURE" \
    "$CONSUMED_STEP150_HARNESS" \
    "$EXECUTION_AUTHORIZATION_POLICY"; do
    [[ -f $required && ! -L $required ]] || fail "a required runtime-validation file is missing or unsafe: $required"
done
if [[ $FAIL_COUNT -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures, %d skips)\n' "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

SCRIPT_SHA256=$(sha_file "$0")
EXECUTION_AUTHORIZATION_POLICY_SHA256=$(sha_file "$EXECUTION_AUTHORIZATION_POLICY")
IMPLEMENTATION_POLICY_SHA256=$(sha_file "$IMPLEMENTATION_POLICY")
STEP153_AUTHORIZATION_POLICY_SHA256=$(sha_file "$STEP153_AUTHORIZATION_POLICY")
TARGET_BINDING_POLICY_SHA256=$(sha_file "$TARGET_BINDING_POLICY")
ACCEPTED_ELILO_CLOSURE_SHA256=$(sha_file "$ACCEPTED_ELILO_CLOSURE")
CONSUMED_STEP150_HARNESS_SHA256=$(sha_file "$CONSUMED_STEP150_HARNESS")
SOURCE_SHA256=$(sha_file "$SOURCE_FILE")
TEMPLATE_SHA256=$(sha_file "$TEMPLATE")

EXPECTED_SCRIPT_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" execution.execution_harness_sha256)
EXPECTED_IMPLEMENTATION_POLICY_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" implementation_policy_sha256)
EXPECTED_STEP153_POLICY_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" step153_authorization_policy_sha256)
EXPECTED_BINDING_POLICY_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" step132_target_binding_policy_sha256)
EXPECTED_CLOSURE_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" accepted_elilo_closure_record_sha256)
EXPECTED_STEP150_HARNESS_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" consumed_step150_harness_sha256)
EXPECTED_SOURCE_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" accepted_source_sha256)
EXPECTED_TEMPLATE_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" configuration_template_sha256)
EXPECTED_HOSTNAME_FQDN=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" target.hostname_fqdn)
EXPECTED_KERNEL=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" target.running_kernel)
EXPECTED_BOOT_IMAGE_SUFFIX=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" target.required_boot_image_suffix)
EXPECTED_ELILO_SHA256=$(json_value "$EXECUTION_AUTHORIZATION_POLICY" target.elilo_conf_sha256)

[[ $EXECUTION_AUTHORIZATION_POLICY_SHA256 == "$CONFIRM_EXECUTION_AUTHORIZATION_POLICY_SHA256" ]] \
    && pass "the execution is bound to the explicitly confirmed fresh authorization policy" \
    || fail "the fresh execution authorization policy SHA-256 does not match explicit confirmation"
[[ $SCRIPT_SHA256 == "$EXPECTED_SCRIPT_SHA256" ]] \
    && pass "the successor execution harness matches the fresh authorization boundary" \
    || fail "the successor execution harness identity changed"
[[ $IMPLEMENTATION_POLICY_SHA256 == "$EXPECTED_IMPLEMENTATION_POLICY_SHA256" ]] \
    && pass "the reviewed step-154 implementation policy remains frozen" \
    || fail "the step-154 implementation policy identity changed"
[[ $STEP153_AUTHORIZATION_POLICY_SHA256 == "$EXPECTED_STEP153_POLICY_SHA256" ]] \
    && pass "the consumed repository implementation authorization remains frozen" \
    || fail "the step-153 implementation authorization identity changed"
[[ $TARGET_BINDING_POLICY_SHA256 == "$EXPECTED_BINDING_POLICY_SHA256" ]] \
    && pass "the historical step-132 target binding remains frozen" \
    || fail "the historical target-binding identity changed"
[[ $ACCEPTED_ELILO_CLOSURE_SHA256 == "$EXPECTED_CLOSURE_SHA256" ]] \
    && pass "the accepted Slackware 15.0 ELILO closure remains frozen" \
    || fail "the accepted ELILO closure identity changed"
[[ $CONSUMED_STEP150_HARNESS_SHA256 == "$EXPECTED_STEP150_HARNESS_SHA256" ]] \
    && pass "the consumed step-150 harness remains immutable" \
    || fail "the consumed step-150 harness identity changed"
[[ $SOURCE_SHA256 == "$EXPECTED_SOURCE_SHA256" ]] \
    && pass "the target carries the accepted remediated reference implementation" \
    || fail "the target reference implementation is not the accepted source"
[[ $TEMPLATE_SHA256 == "$EXPECTED_TEMPLATE_SHA256" ]] \
    && pass "the target carries the frozen configuration template" \
    || fail "the target configuration template is not the accepted input"

if python3 - "$EXECUTION_AUTHORIZATION_POLICY" <<'PY_AUTH'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    policy = json.load(handle)
auth = policy["authorization"]
assert auth["execution_authorized"] is True
assert auth["authorization_consumable"] is True
assert auth["machine_execution_limit"] == 1
assert auth["reboot_limit"] == 0
assert auth["repository_refresh_authorized"] is False
assert auth["package_mutation_authorized"] is False
assert auth["boot_mutation_authorized"] is False
assert auth["source_change_authorized"] is False
assert auth["configuration_template_change_authorized"] is False
assert auth["contract_change_authorized"] is False
PY_AUTH
then
    pass "the fresh policy grants only one non-mutating zero-reboot execution"
else
    fail "the fresh execution policy does not satisfy the narrow authorization contract"
fi

if [[ $FAIL_COUNT -eq 0 ]]; then
    AUTHORIZATION_CONSUMED_BY_EXECUTION=true
    pass "the fresh single-use authorization is consumed by this execution attempt"
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
        printf 'grub_directory_kind='; if [[ -L /boot/grub ]]; then printf 'symlink\n'; elif [[ -d /boot/grub ]]; then printf 'directory\n'; elif [[ -e /boot/grub ]]; then printf 'other\n'; else printf 'absent\n'; fi
    } > "$destination"
}

if [[ $AUTHORIZATION_CONSUMED_BY_EXECUTION == true ]]; then
    TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
    EVIDENCE_PARENT=/var/tmp/slack-update-acceptance/configuration-module-mode-source-remediation-runtime-validation
    EVIDENCE_DIR="$EVIDENCE_PARENT/slackware-15-characterization-remediated-rerun-${TIMESTAMP}"
    mkdir -p -- "$EVIDENCE_DIR"
    chmod 0700 -- "$EVIDENCE_DIR"
    ASSERTIONS_LOG="$EVIDENCE_DIR/assertions.log"
    : > "$ASSERTIONS_LOG"
    exec 3>&1
    pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
    fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }
    skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$*" | tee -a "$ASSERTIONS_LOG" >&3; }

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

    # BEGIN CORE IDENTITY GATE
    [[ $CONFIRM_HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" && $HOSTNAME_FQDN == "$EXPECTED_HOSTNAME_FQDN" ]] \
        && pass "the live Slackware 15.0 FQDN matches the frozen target identity" \
        || fail "the live Slackware 15.0 FQDN does not match the frozen target identity"
    [[ $SLACKWARE_VERSION == 'Slackware 15.0' ]] \
        && pass "the target identifies as Slackware 15.0" \
        || fail "the target does not identify as Slackware 15.0"
    [[ -d /sys/firmware/efi ]] \
        && pass "the target is running under UEFI firmware" \
        || fail "the target is not running under the accepted UEFI identity"
    [[ $RUNNING_KERNEL_ACTUAL == "$EXPECTED_KERNEL" ]] \
        && pass "the running kernel matches the accepted Slackware 15.0 ELILO closure" \
        || fail "the running kernel no longer matches the accepted ELILO closure"

    BOOT_IMAGE_COUNT=0
    BOOT_IMAGE_VALUE=""
    for token in $CMDLINE; do
        case "$token" in
            BOOT_IMAGE=*) BOOT_IMAGE_COUNT=$((BOOT_IMAGE_COUNT + 1)); BOOT_IMAGE_VALUE=${token#BOOT_IMAGE=} ;;
        esac
    done
    [[ $BOOT_IMAGE_COUNT -eq 1 && $BOOT_IMAGE_VALUE == *"$EXPECTED_BOOT_IMAGE_SUFFIX" ]] \
        && pass "the live kernel command line matches the accepted ELILO generic-kernel boot identity" \
        || fail "the live kernel command line does not match the accepted ELILO boot identity"
    [[ -f $ELILO_CONF && ! -L $ELILO_CONF && $ELILO_SHA256 == "$EXPECTED_ELILO_SHA256" ]] \
        && pass "the active ELILO configuration matches the accepted closure" \
        || fail "the active ELILO configuration no longer matches the accepted closure"
    # END CORE IDENTITY GATE

    if [[ $FAIL_COUNT -eq 0 ]]; then
        CORE_IDENTITY_MATCH=true
        pass "the live target matches only the frozen ELILO core identity gate"
    else
        skip "runtime probing is withheld because the frozen ELILO core identity gate failed"
    fi

    if [[ $CORE_IDENTITY_MATCH == true ]]; then
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

            # BEGIN RUNTIME ACCEPTANCE
            if [[ $BOOT_MODE == auto \
                && $BOOT_MODULE_STATE == unavailable \
                && $BOOT_MODULE_RUN -eq 0 \
                && $BOOT_PREPARATION_LAYOUT == unknown \
                && $BOOT_DIRECT_GENERIC_AVAILABLE -eq 0 \
                && $BOOT_MODULE_REASON == 'no supported initrd or GRUB preparation path was detected' ]]; then
                RUNTIME_PROBE_ACCEPTED=true
                pass "boot=auto fails closed on the live incomplete preparation layout without predeclaring capability bits"
            else
                fail "boot=auto did not satisfy the characterization-remediated fail-closed semantics"
            fi
            # END RUNTIME ACCEPTANCE
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

    if [[ $FAIL_COUNT -eq 0 && $CORE_IDENTITY_MATCH == true \
        && $RUNTIME_PROBE_INVOKED == true && $RUNTIME_PROBE_ACCEPTED == true \
        && $SYSTEM_STATE_PRESERVED == true && $AUTHORIZATION_CONSUMED_BY_EXECUTION == true ]]; then
        NEXT_STAGE=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review
        pass "the single authorized characterization-remediated Slackware 15.0 execution is ready for evidence review"
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
scenario=phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun
target=$TARGET
hostname_fqdn=$HOSTNAME_FQDN
slackware_version=$SLACKWARE_VERSION
running_kernel=$RUNNING_KERNEL_ACTUAL
boot_image=$BOOT_IMAGE_VALUE
execution_authorization_policy_sha256=$EXECUTION_AUTHORIZATION_POLICY_SHA256
implementation_policy_sha256=$IMPLEMENTATION_POLICY_SHA256
step153_authorization_policy_sha256=$STEP153_AUTHORIZATION_POLICY_SHA256
target_binding_policy_sha256=$TARGET_BINDING_POLICY_SHA256
accepted_elilo_closure_record_sha256=$ACCEPTED_ELILO_CLOSURE_SHA256
consumed_step150_harness_sha256=$CONSUMED_STEP150_HARNESS_SHA256
execution_harness_sha256=$SCRIPT_SHA256
source_sha256=$SOURCE_SHA256
template_sha256=$TEMPLATE_SHA256
elilo_conf_sha256=$ELILO_SHA256
core_identity_match=$CORE_IDENTITY_MATCH
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

    ARCHIVE="$EVIDENCE_PARENT/slackware-15-configuration-module-mode-source-remediation-runtime-validation-characterization-remediated-rerun-${TIMESTAMP}.tar.gz"
    tar -C "$EVIDENCE_PARENT" -czf "$ARCHIVE" "$(basename "$EVIDENCE_DIR")"
    ARCHIVE_SHA256=$(sha_file "$ARCHIVE")
    printf '%s  %s\n' "$ARCHIVE_SHA256" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"

    printf 'Evidence archive: %s\n' "$ARCHIVE"
    printf 'Evidence SHA-256: %s\n' "$ARCHIVE_SHA256"
    printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' \
        "$ARCHIVE" "$(basename "$ARCHIVE")" "$ARCHIVE.sha256" "$(basename "$ARCHIVE.sha256")"
    printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "$(basename "$ARCHIVE.sha256")"
    printf 'Result: %s (%d passes, %d failures, %d skips); core_identity_match=%s; runtime_probe_invoked=%s; runtime_probe_accepted=%s; system_state_preserved=%s; authorization_consumed_by_execution=%s; next_stage=%s\n' \
        "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT" \
        "$CORE_IDENTITY_MATCH" "$RUNTIME_PROBE_INVOKED" "$RUNTIME_PROBE_ACCEPTED" "$SYSTEM_STATE_PRESERVED" "$AUTHORIZATION_CONSUMED_BY_EXECUTION" "$NEXT_STAGE"
fi

[[ $FAIL_COUNT -eq 0 ]]
