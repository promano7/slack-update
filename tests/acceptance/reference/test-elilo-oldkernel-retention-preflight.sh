#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
ACCEPTED_TRANSACTION_RECORD=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-kernel-transaction-accepted.json
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/elilo-oldkernel-retention-preflight
TARGET=
OUTPUT_DIR=
EXPECTED_ACTIVE_KERNEL=
EXPECTED_OLD_KERNEL=
ACCEPTED_APPLY_AT=
ACCEPTED_REBOOT_REVIEWED_AT=
MINIMUM_RETENTION_DAYS=7
REQUIRED_SUCCESSFUL_BOOTS=2
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_VALUE=
SLACKWARE_VERSION=
RUNNING_KERNEL=
BOOT_ID=
BOOT_STARTED_AT_UTC=
RETENTION_REFERENCE_EPOCH=0
BOOT_START_EPOCH=0
CURRENT_EPOCH=0
RETENTION_AGE_SECONDS=0
RETENTION_REQUIRED_SECONDS=0
RETENTION_WINDOW_MET=false
ADDITIONAL_BOOT_OBSERVED=false
CLEANUP_ELIGIBLE=false
ELILO_DIRECTORY=/boot/efi/EFI/Slackware
ELILO_CONFIG=$ELILO_DIRECTORY/elilo.conf
PACKAGE_DATABASE=/var/log/packages
PACKAGE_DATABASE_RESOLVED=
BLACKLIST=/etc/slackpkg/blacklist
ACTIVE_EFI_KERNEL=
ACTIVE_EFI_INITRD=
ROLLBACK_EFI_KERNEL=
ROLLBACK_EFI_INITRD=

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 [options]

Collect a non-destructive retention and cleanup-eligibility preflight for the
accepted Slackware 15.0 ELILO kernel transaction. The preflight verifies the
active and rollback package sets, the two-entry ELILO configuration, active and
rollback boot artifacts, the minimum retention window, and a later successful
boot into the accepted kernel.

This command never invokes removepkg, upgradepkg, installpkg, mkinitrd,
eliloconfig, efibootmgr, or any file-removal command. It only records whether a
separately reviewed cleanup stage could be designed and authorized.

Required options:
      --target slackware-15.0

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
EOF_USAGE
}

error() {
    printf 'error: %s\n' "$*" >&2
}

record_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS: %s\n' "$*" | tee -a "$ASSERTION_LOG"
}

record_failure() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$*" | tee -a "$ASSERTION_LOG" >&2
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                [ "$#" -ge 2 ] || return 1
                TARGET=$2
                shift 2
                ;;
            --output-dir)
                [ "$#" -ge 2 ] || return 1
                OUTPUT_DIR=$2
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                error "unknown argument: $1"
                return 1
                ;;
        esac
    done

    [ "$TARGET" = slackware-15.0 ] || return 1
    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in
            /*) ;;
            *) return 1 ;;
        esac
    fi
}

is_safe_kernel_version() {
    case "${1:-}" in
        ''|*[!0-9A-Za-z._+-]*|.*|*..*) return 1 ;;
        *) return 0 ;;
    esac
}

require_regular_file() {
    [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]
}

resolve_package_database() {
    local configured=$1 resolved

    [ -d "$configured" ] || return 1
    resolved=$(readlink -e -- "$configured" 2>/dev/null) || return 1
    case "$resolved" in
        /*) ;;
        *) return 1 ;;
    esac
    [ -d "$resolved" ] && [ ! -L "$resolved" ] \
        && [ -r "$resolved" ] && [ -x "$resolved" ] || return 1
    printf '%s\n' "$resolved"
}

load_accepted_transaction_record() {
    local record=$1 output=$2

    python3 - "$record" "$output" <<'PYTHON_EOF'
import json
import pathlib
import re
import sys

record_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
data = json.loads(record_path.read_text(encoding="utf-8"))

if data.get("scenario") != "elilo-kernel-transaction":
    raise SystemExit("unexpected scenario")
if data.get("target") != "slackware-15.0" or data.get("status") != "accepted":
    raise SystemExit("transaction is not accepted")
if data.get("cleanup_authorized") is not False:
    raise SystemExit("accepted record must keep cleanup unauthorized")

previous = data.get("kernel", {}).get("previous", "")
active = data.get("kernel", {}).get("active", "")
apply_at = data.get("apply_evidence", {}).get("captured_at_utc", "")
reviewed_at = data.get("post_reboot_validation", {}).get("reviewed_at_local", "")
rollback_retained = data.get("elilo", {}).get("rollback_retained")
version_re = re.compile(r"^[0-9A-Za-z._+-]+$")
if not version_re.fullmatch(previous) or not version_re.fullmatch(active):
    raise SystemExit("unsafe kernel version in accepted record")
if rollback_retained is not True:
    raise SystemExit("accepted record does not retain rollback")
if not apply_at or not reviewed_at:
    raise SystemExit("accepted timestamps are incomplete")

output_path.write_text(
    "\n".join(
        [
            f"previous_kernel={previous}",
            f"active_kernel={active}",
            f"apply_captured_at={apply_at}",
            f"reboot_reviewed_at={reviewed_at}",
        ]
    )
    + "\n",
    encoding="utf-8",
)
PYTHON_EOF
}

read_key_value() {
    local key=$1 file=$2
    awk -F '=' -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$file"
}

iso8601_to_epoch() {
    python3 - "$1" <<'PYTHON_EOF'
import datetime
import sys

value = sys.argv[1]
if value.endswith("Z"):
    value = value[:-1] + "+00:00"
parsed = datetime.datetime.fromisoformat(value)
if parsed.tzinfo is None:
    raise SystemExit("timestamp must include a timezone")
print(int(parsed.timestamp()))
PYTHON_EOF
}

read_boot_start_epoch() {
    awk '$1 == "btime" && $2 ~ /^[0-9]+$/ { print $2; found=1; exit } END { if (!found) exit 1 }' /proc/stat
}

format_epoch_utc() {
    python3 - "$1" <<'PYTHON_EOF'
import datetime
import sys

value = int(sys.argv[1])
print(datetime.datetime.fromtimestamp(value, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
PYTHON_EOF
}

evaluate_retention_window() {
    local current_epoch=$1 reference_epoch=$2 boot_start_epoch=$3 minimum_days=$4

    case "$current_epoch:$reference_epoch:$boot_start_epoch:$minimum_days" in
        *[!0-9:]*) return 1 ;;
    esac
    [ "$current_epoch" -ge "$reference_epoch" ] || return 1
    [ "$current_epoch" -ge "$boot_start_epoch" ] || return 1
    [ "$minimum_days" -ge 1 ] || return 1

    RETENTION_REQUIRED_SECONDS=$((minimum_days * 86400))
    RETENTION_AGE_SECONDS=$((current_epoch - reference_epoch))
    if [ "$RETENTION_AGE_SECONDS" -ge "$RETENTION_REQUIRED_SECONDS" ]; then
        RETENTION_WINDOW_MET=true
    else
        RETENTION_WINDOW_MET=false
    fi
    if [ "$boot_start_epoch" -gt "$reference_epoch" ]; then
        ADDITIONAL_BOOT_OBSERVED=true
    else
        ADDITIONAL_BOOT_OBSERVED=false
    fi
}

capture_package_database() {
    local package_database output=$2

    package_database=$(resolve_package_database "$1") || return 1
    find "$package_database" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' \
        | LC_ALL=C sort > "$output"
    [ -s "$output" ]
}

compare_captured_file() {
    require_regular_file "$1" && require_regular_file "$2" && cmp -s -- "$1" "$2"
}

evaluate_cleanup_eligibility() {
    CLEANUP_ELIGIBLE=false
    if [ "$FAILURE_COUNT" -eq 0 ] \
        && [ "$RETENTION_WINDOW_MET" = true ] \
        && [ "$ADDITIONAL_BOOT_OBSERVED" = true ]; then
        CLEANUP_ELIGIBLE=true
    fi
}

capture_kernel_package_records() {
    local package_database active_version=$2 old_version=$3 output=$4

    package_database=$(resolve_package_database "$1") || return 1

    python3 - "$package_database" "$active_version" "$old_version" "$output" <<'PYTHON_EOF'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
active = sys.argv[2]
old = sys.argv[3]
output = pathlib.Path(sys.argv[4])
required = ("kernel-generic", "kernel-huge", "kernel-modules")
name_re = re.compile(r"^(kernel-(?:generic|huge|modules))-(.+)-(x86_64)-([^-]+)$")
rows = []
counts = {(name, version): 0 for name in required for version in (old, active)}

if not root.is_dir() or root.is_symlink():
    raise SystemExit("unsafe package database")
for path in sorted(root.iterdir(), key=lambda item: item.name):
    if not path.is_file() or path.is_symlink():
        continue
    match = name_re.fullmatch(path.name)
    if not match:
        continue
    package, version, architecture, build = match.groups()
    if version not in (old, active):
        continue
    counts[(package, version)] += 1
    rows.append(("active" if version == active else "rollback", package, version, architecture, build, path.name))

if any(count != 1 for count in counts.values()):
    raise SystemExit(f"expected one record per package and retained version, found {counts}")
if len(rows) != 6:
    raise SystemExit("unexpected retained kernel record count")

output.write_text(
    "".join("\t".join(row) + "\n" for row in sorted(rows)),
    encoding="utf-8",
)
PYTHON_EOF
}

extract_package_path_overlap() {
    local package_database records=$2 output=$3

    package_database=$(resolve_package_database "$1") || return 1

    python3 - "$package_database" "$records" "$output" <<'PYTHON_EOF'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
records_path = pathlib.Path(sys.argv[2])
output_path = pathlib.Path(sys.argv[3])
records = []
for raw in records_path.read_text(encoding="utf-8").splitlines():
    fields = raw.split("\t")
    if len(fields) != 6:
        raise SystemExit("invalid kernel record row")
    records.append(fields)

def package_paths(package_log: pathlib.Path) -> set[str]:
    if not package_log.is_file() or package_log.is_symlink():
        raise SystemExit(f"unsafe package record {package_log.name}")
    lines = package_log.read_text(encoding="utf-8", errors="strict").splitlines()
    try:
        start = lines.index("FILE LIST:") + 1
    except ValueError as exc:
        raise SystemExit(f"missing FILE LIST marker in {package_log.name}") from exc
    result = set()
    for value in lines[start:]:
        value = value.strip()
        if not value or value.endswith("/") or value == "install/doinst.sh":
            continue
        path = pathlib.PurePosixPath(value)
        if path.is_absolute() or ".." in path.parts:
            raise SystemExit(f"unsafe package path {value!r}")
        result.add(value)
    return result

rows = []
for package in ("kernel-generic", "kernel-huge", "kernel-modules"):
    active_records = [row for row in records if row[0] == "active" and row[1] == package]
    rollback_records = [row for row in records if row[0] == "rollback" and row[1] == package]
    if len(active_records) != 1 or len(rollback_records) != 1:
        raise SystemExit("incomplete active/rollback package pair")
    active_record = active_records[0][5]
    rollback_record = rollback_records[0][5]
    active_paths = package_paths(root / active_record)
    rollback_paths = package_paths(root / rollback_record)
    for value in sorted(active_paths & rollback_paths):
        rows.append((package, rollback_record, active_record, value))

output_path.write_text(
    "".join("\t".join(row) + "\n" for row in rows),
    encoding="utf-8",
)
PYTHON_EOF
}

parse_elilo_retention_config() {
    local config=$1 output=$2

    python3 - "$config" "$output" <<'PYTHON_EOF'
import pathlib
import re
import shlex
import sys

config = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
if not config.is_file() or config.is_symlink():
    raise SystemExit("unsafe ELILO configuration")

safe_basename = re.compile(r"^[A-Za-z0-9._+-]+$")
def parse_value(raw: str) -> str:
    parts = shlex.split(raw, comments=True, posix=True)
    if len(parts) != 1:
        raise SystemExit("ELILO assignment is ambiguous")
    return parts[0]

settings = {}
stanzas = []
current = None
for original in config.read_text(encoding="utf-8").splitlines():
    stripped = original.strip()
    if not stripped or stripped.startswith("#") or "=" not in stripped:
        continue
    key, raw_value = stripped.split("=", 1)
    key = key.strip().lower()
    value = parse_value(raw_value.strip())
    if key == "image":
        current = {"image": value}
        stanzas.append(current)
    elif key in ("label", "initrd"):
        if current is None or key in current:
            raise SystemExit("ELILO stanza is malformed")
        current[key] = value
    elif current is None:
        if key in settings:
            raise SystemExit("duplicate global ELILO directive")
        settings[key] = value

if settings.get("default") != "vmlinuz":
    raise SystemExit("unexpected ELILO default")
if len(stanzas) != 2:
    raise SystemExit("exactly two ELILO stanzas are required during retention")
for stanza in stanzas:
    if set(stanza) != {"image", "label", "initrd"}:
        raise SystemExit("ELILO stanza is incomplete")
    if not all(safe_basename.fullmatch(stanza[key]) for key in stanza):
        raise SystemExit("unsafe ELILO basename")
labels = {stanza["label"] for stanza in stanzas}
if labels != {"vmlinuz", "oldkernel"}:
    raise SystemExit("required active and rollback labels are missing")

rows = [("default", settings["default"], "")]
for stanza in stanzas:
    rows.append((stanza["label"], stanza["image"], stanza["initrd"]))
output.write_text("".join("\t".join(row) + "\n" for row in rows), encoding="utf-8")
PYTHON_EOF
}

read_elilo_field() {
    local label=$1 field=$2 file=$3 column
    case "$field" in
        image) column=2 ;;
        initrd) column=3 ;;
        *) return 1 ;;
    esac
    awk -F '\t' -v label="$label" -v column="$column" '$1 == label { print $column; exit }' "$file"
}

blacklist_has_exact_deferrals() {
    local blacklist=$1

    python3 - "$blacklist" <<'PYTHON_EOF'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
if not path.is_file() or path.is_symlink():
    raise SystemExit(1)
required = {"kernel-generic", "kernel-huge", "kernel-modules"}
counts = {name: 0 for name in required}
for line in path.read_text(encoding="utf-8").splitlines():
    content = line.split("#", 1)[0].strip()
    if content in counts:
        counts[content] += 1
if counts != {name: 1 for name in required}:
    raise SystemExit(1)
PYTHON_EOF
}

capture_boot_state() {
    local output=$1

    {
        printf '[uname]\n'
        uname -a
        printf '\n[cmdline]\n'
        cat /proc/cmdline
        printf '\n[boot-id]\n'
        cat /proc/sys/kernel/random/boot_id
        printf '\n[elilo-sha256]\n'
        sha256sum -- "$ELILO_CONFIG"
        printf '\n[efi-files]\n'
        find "$ELILO_DIRECTORY" -mindepth 1 -maxdepth 1 -type f -printf '%f\t%s\n' | LC_ALL=C sort
    } > "$output"
}

write_cleanup_plan() {
    local output=$1 active=$2 old=$3

    cat > "$output" <<EOF_PLAN
plan=elilo-oldkernel-cleanup
active_kernel=$active
rollback_kernel=$old
minimum_retention_days=$MINIMUM_RETENTION_DAYS
required_successful_boots=$REQUIRED_SUCCESSFUL_BOOTS
retention_window_met=$RETENTION_WINDOW_MET
additional_boot_after_acceptance_observed=$ADDITIONAL_BOOT_OBSERVED
cleanup_eligible=$CLEANUP_ELIGIBLE
stage_1=review-this-preflight-and-authorize-a-separate-gated-apply
stage_2=download-and-revalidate-the-exact-active-kernel-package-archives
stage_3=archive-elilo.conf-and-all-rollback-artifacts-before-package-changes
stage_4=remove-only-the-three-exact-rollback-package-records
stage_5=reinstall-the-exact-active-package-set-to-repair-shared-package-paths
stage_6=verify-running-kernel-active-modules-versioned-boot-files-and-efi-copies
stage_7=atomically-replace-elilo.conf-with-the-single-verified-active-entry
stage_8=remove-unreferenced-legacy-vmlinuz-initrd.gz-and-old-versioned-initrd-artifacts
stage_9=sync-and-capture-final-package-and-boot-state-for-reboot-validation
failure_policy=stop-before-next-boundary-and-preserve-or-restore-elilo-rollback-configuration
cleanup_authorized=false
EOF_PLAN
}

write_summary() {
    local output=$1

    cat > "$output" <<EOF_SUMMARY
scenario=elilo-oldkernel-retention-preflight
target=$TARGET
hostname=$HOSTNAME_VALUE
slackware_version=$SLACKWARE_VERSION
accepted_apply_at=$ACCEPTED_APPLY_AT
accepted_reboot_reviewed_at=$ACCEPTED_REBOOT_REVIEWED_AT
running_kernel=$RUNNING_KERNEL
active_kernel=$EXPECTED_ACTIVE_KERNEL
rollback_kernel=$EXPECTED_OLD_KERNEL
package_database_configured=$PACKAGE_DATABASE
package_database_resolved=$PACKAGE_DATABASE_RESOLVED
boot_id=$BOOT_ID
boot_started_at_utc=$BOOT_STARTED_AT_UTC
minimum_retention_days=$MINIMUM_RETENTION_DAYS
retention_age_seconds=$RETENTION_AGE_SECONDS
retention_required_seconds=$RETENTION_REQUIRED_SECONDS
retention_window_met=$RETENTION_WINDOW_MET
required_successful_boots=$REQUIRED_SUCCESSFUL_BOOTS
accepted_successful_boots=1
additional_boot_after_acceptance_observed=$ADDITIONAL_BOOT_OBSERVED
cleanup_eligible=$CLEANUP_ELIGIBLE
passes=$PASS_COUNT
failures=$FAILURE_COUNT
cleanup_authorized=false
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-elilo-oldkernel-retention-preflight-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive" || return 1
    (cd -- "$(dirname -- "$archive")" && sha256sum -- "$(basename -- "$archive")") > "$sidecar" || return 1
    chmod 0600 -- "$sidecar" || return 1

    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    if id "$owner" >/dev/null 2>&1; then
        group=$(id -gn "$owner")
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
            "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
        printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' \
            "/home/$owner" "${sidecar##*/}"
    fi
}

main() {
    local timestamp metadata_file elilo_records active_boot_kernel active_boot_initrd
    local rollback_boot_kernel rollback_boot_initrd cmdline
    local initial_state_captured=false final_state_captured=false

    parse_arguments "$@" || {
        print_usage >&2
        return 2
    }
    [ "$(id -u)" -eq 0 ] || {
        error 'this real-system preflight must run as root'
        return 2
    }
    [ -r /etc/slackware-version ] || {
        error '/etc/slackware-version is unavailable'
        return 2
    }
    SLACKWARE_VERSION=$(cat /etc/slackware-version)
    [ "$SLACKWARE_VERSION" = 'Slackware 15.0' ] || {
        error "target mismatch: found '$SLACKWARE_VERSION'"
        return 2
    }
    for command in python3 sha256sum tar stat find cmp awk sort date readlink; do
        command -v "$command" >/dev/null 2>&1 || {
            error "required command missing: $command"
            return 2
        }
    done
    require_regular_file "$ACCEPTED_TRANSACTION_RECORD" || {
        error 'the accepted ELILO transaction record is unavailable or unsafe'
        return 2
    }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    if [ -z "$OUTPUT_DIR" ]; then
        OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    fi
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || {
        error "output directory already exists: $OUTPUT_DIR"
        return 2
    }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    metadata_file=$OUTPUT_DIR/accepted-transaction-metadata.txt
    if load_accepted_transaction_record "$ACCEPTED_TRANSACTION_RECORD" "$metadata_file"; then
        EXPECTED_OLD_KERNEL=$(read_key_value previous_kernel "$metadata_file")
        EXPECTED_ACTIVE_KERNEL=$(read_key_value active_kernel "$metadata_file")
        ACCEPTED_APPLY_AT=$(read_key_value apply_captured_at "$metadata_file")
        ACCEPTED_REBOOT_REVIEWED_AT=$(read_key_value reboot_reviewed_at "$metadata_file")
        record_pass 'the accepted ELILO transaction record was loaded with cleanup still unauthorized'
    else
        record_failure 'the accepted ELILO transaction record could not be validated'
    fi
    is_safe_kernel_version "$EXPECTED_ACTIVE_KERNEL" && is_safe_kernel_version "$EXPECTED_OLD_KERNEL" \
        && [ "$EXPECTED_ACTIVE_KERNEL" != "$EXPECTED_OLD_KERNEL" ] \
        && record_pass "the accepted active and rollback kernels are safe and distinct: $EXPECTED_ACTIVE_KERNEL and $EXPECTED_OLD_KERNEL" \
        || record_failure 'the accepted kernel versions are empty, unsafe, or identical'

    HOSTNAME_VALUE=$(hostname -f 2>/dev/null || hostname)
    RUNNING_KERNEL=$(uname -r)
    BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)
    BOOT_START_EPOCH=$(read_boot_start_epoch 2>/dev/null || printf '0')
    CURRENT_EPOCH=$(date +%s)
    RETENTION_REFERENCE_EPOCH=$(iso8601_to_epoch "$ACCEPTED_REBOOT_REVIEWED_AT" 2>/dev/null || printf '0')
    BOOT_STARTED_AT_UTC=$(format_epoch_utc "$BOOT_START_EPOCH" 2>/dev/null || printf 'unknown')
    if evaluate_retention_window "$CURRENT_EPOCH" "$RETENTION_REFERENCE_EPOCH" "$BOOT_START_EPOCH" "$MINIMUM_RETENTION_DAYS"; then
        record_pass 'the retention timestamps and current boot start were parsed safely'
    else
        record_failure 'the retention timestamps or current boot start are invalid'
    fi

    [ -d /sys/firmware/efi ] \
        && record_pass 'the system is running in UEFI mode' \
        || record_failure 'the system is not running in UEFI mode'
    require_regular_file "$ELILO_CONFIG" \
        && record_pass 'elilo.conf is a readable regular file' \
        || record_failure 'elilo.conf is missing, unreadable, or unsafe'
    [ "$RUNNING_KERNEL" = "$EXPECTED_ACTIVE_KERNEL" ] \
        && record_pass "the accepted kernel $EXPECTED_ACTIVE_KERNEL is currently running" \
        || record_failure "the running kernel $RUNNING_KERNEL is not the accepted active kernel $EXPECTED_ACTIVE_KERNEL"
    case "$BOOT_ID" in
        ????????-????-????-????-????????????) record_pass 'the current Linux boot ID was captured' ;;
        *) record_failure 'the current Linux boot ID is missing or malformed' ;;
    esac
    if PACKAGE_DATABASE_RESOLVED=$(resolve_package_database "$PACKAGE_DATABASE"); then
        record_pass "the package database compatibility path resolved safely to $PACKAGE_DATABASE_RESOLVED"
    else
        PACKAGE_DATABASE_RESOLVED=
        record_failure 'the package database compatibility path could not be resolved safely'
    fi

    elilo_records=$OUTPUT_DIR/elilo-retention-state.tsv
    if parse_elilo_retention_config "$ELILO_CONFIG" "$elilo_records"; then
        record_pass 'ELILO retains exactly one active entry and one oldkernel rollback entry'
    else
        : > "$elilo_records"
        record_failure 'ELILO does not match the required two-entry retention state'
    fi
    ACTIVE_EFI_KERNEL=$(read_elilo_field vmlinuz image "$elilo_records")
    ACTIVE_EFI_INITRD=$(read_elilo_field vmlinuz initrd "$elilo_records")
    ROLLBACK_EFI_KERNEL=$(read_elilo_field oldkernel image "$elilo_records")
    ROLLBACK_EFI_INITRD=$(read_elilo_field oldkernel initrd "$elilo_records")
    [ "$ACTIVE_EFI_KERNEL" = "vmlinuz-generic-$EXPECTED_ACTIVE_KERNEL" ] \
        && [ "$ACTIVE_EFI_INITRD" = "initrd-generic-$EXPECTED_ACTIVE_KERNEL.gz" ] \
        && record_pass 'the active ELILO entry uses the accepted versioned kernel and initrd' \
        || record_failure 'the active ELILO entry does not use the accepted versioned artifacts'
    [ "$ROLLBACK_EFI_KERNEL" = vmlinuz ] && [ "$ROLLBACK_EFI_INITRD" = initrd.gz ] \
        && record_pass 'oldkernel still uses the preserved legacy EFI kernel and initrd' \
        || record_failure 'the oldkernel rollback entry changed unexpectedly'

    cmdline=$(cat /proc/cmdline 2>/dev/null || true)
    case "$cmdline" in
        *"\\EFI\\Slackware\\vmlinuz-generic-$EXPECTED_ACTIVE_KERNEL"*)
            record_pass 'the current kernel command line names the accepted versioned EFI image'
            ;;
        *)
            record_failure 'the current kernel command line does not identify the accepted EFI image'
            ;;
    esac

    if capture_kernel_package_records "$PACKAGE_DATABASE" "$EXPECTED_ACTIVE_KERNEL" "$EXPECTED_OLD_KERNEL" \
        "$OUTPUT_DIR/retained-kernel-records.tsv"; then
        record_pass 'exactly three active and three rollback kernel package records coexist'
    else
        : > "$OUTPUT_DIR/retained-kernel-records.tsv"
        record_failure 'the active and rollback kernel package records are incomplete or ambiguous'
    fi
    if extract_package_path_overlap "$PACKAGE_DATABASE" "$OUTPUT_DIR/retained-kernel-records.tsv" \
        "$OUTPUT_DIR/kernel-package-path-overlap.tsv"; then
        record_pass 'shared old/new package paths were inventoried for mandatory active-package reinstallation'
    else
        : > "$OUTPUT_DIR/kernel-package-path-overlap.tsv"
        record_failure 'the old/new kernel package path overlap could not be inspected safely'
    fi
    [ -d "/lib/modules/$EXPECTED_ACTIVE_KERNEL" ] && [ ! -L "/lib/modules/$EXPECTED_ACTIVE_KERNEL" ] \
        && record_pass 'the active kernel module tree is present' \
        || record_failure 'the active kernel module tree is missing or unsafe'
    [ -d "/lib/modules/$EXPECTED_OLD_KERNEL" ] && [ ! -L "/lib/modules/$EXPECTED_OLD_KERNEL" ] \
        && record_pass 'the rollback kernel module tree remains present' \
        || record_failure 'the rollback kernel module tree is missing or unsafe'

    active_boot_kernel="/boot/vmlinuz-generic-$EXPECTED_ACTIVE_KERNEL"
    active_boot_initrd="/boot/initrd-generic-$EXPECTED_ACTIVE_KERNEL.gz"
    rollback_boot_kernel="/boot/vmlinuz-generic-$EXPECTED_OLD_KERNEL"
    rollback_boot_initrd=/boot/initrd.gz
    require_regular_file "$active_boot_kernel" \
        && require_regular_file "$active_boot_initrd" \
        && cmp -s -- "$active_boot_kernel" "$ELILO_DIRECTORY/$ACTIVE_EFI_KERNEL" \
        && cmp -s -- "$active_boot_initrd" "$ELILO_DIRECTORY/$ACTIVE_EFI_INITRD" \
        && record_pass 'the active /boot and EFI kernel/initrd copies match byte-for-byte' \
        || record_failure 'the active /boot and EFI kernel/initrd copies do not match'
    require_regular_file "$rollback_boot_kernel" \
        && require_regular_file "$rollback_boot_initrd" \
        && cmp -s -- "$rollback_boot_kernel" "$ELILO_DIRECTORY/$ROLLBACK_EFI_KERNEL" \
        && cmp -s -- "$rollback_boot_initrd" "$ELILO_DIRECTORY/$ROLLBACK_EFI_INITRD" \
        && record_pass 'the rollback /boot and EFI kernel/initrd copies remain byte-identical' \
        || record_failure 'the rollback /boot and EFI kernel/initrd copies are missing or changed'

    blacklist_has_exact_deferrals "$BLACKLIST" \
        && record_pass 'the three boot-kernel package names remain deferred in Slackpkg' \
        || record_failure 'the expected boot-kernel Slackpkg deferrals are incomplete'

    if [ "$RETENTION_WINDOW_MET" = true ]; then
        record_pass "the minimum $MINIMUM_RETENTION_DAYS-day rollback retention window has elapsed"
    else
        record_pass "the rollback remains retained because the $MINIMUM_RETENTION_DAYS-day window has not elapsed"
    fi
    if [ "$ADDITIONAL_BOOT_OBSERVED" = true ]; then
        record_pass 'a later boot after the accepted reboot review was observed with the target kernel active'
    else
        record_pass 'the required later boot has not yet been observed; cleanup remains ineligible'
    fi

    if capture_package_database "$PACKAGE_DATABASE" "$OUTPUT_DIR/packages.before.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.before.txt"; then
        initial_state_captured=true
        record_pass 'the package and boot state were captured before final non-destructive verification'
    else
        record_failure 'the initial package or boot state could not be captured'
    fi

    if capture_package_database "$PACKAGE_DATABASE" "$OUTPUT_DIR/packages.after.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.after.txt"; then
        final_state_captured=true
    else
        record_failure 'the final package or boot state could not be captured'
    fi
    if [ "$initial_state_captured" = true ] && [ "$final_state_captured" = true ]; then
        compare_captured_file "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
            && record_pass 'the installed package database remained unchanged during the preflight' \
            || record_failure 'the installed package database changed during the preflight'
        compare_captured_file "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
            && record_pass 'the ELILO boot state remained unchanged during the preflight' \
            || record_failure 'the ELILO boot state changed during the preflight'
    else
        record_failure 'package and boot immutability could not be compared because a state capture was incomplete'
    fi
    evaluate_cleanup_eligibility
    write_cleanup_plan "$OUTPUT_DIR/cleanup-plan.txt" "$EXPECTED_ACTIVE_KERNEL" "$EXPECTED_OLD_KERNEL"

    sha256sum -- "$ELILO_CONFIG" "$active_boot_kernel" "$active_boot_initrd" \
        "$rollback_boot_kernel" "$rollback_boot_initrd" \
        "$ELILO_DIRECTORY/$ACTIVE_EFI_KERNEL" "$ELILO_DIRECTORY/$ACTIVE_EFI_INITRD" \
        "$ELILO_DIRECTORY/$ROLLBACK_EFI_KERNEL" "$ELILO_DIRECTORY/$ROLLBACK_EFI_INITRD" \
        > "$OUTPUT_DIR/retained-artifacts.sha256" \
        || record_failure 'the retained boot artifacts could not be hashed'

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'ELILO oldkernel retention result: active=%s, rollback=%s, eligible=%s, cleanup-authorized=false\n' \
        "$EXPECTED_ACTIVE_KERNEL" "$EXPECTED_OLD_KERNEL" "$CLEANUP_ELIGIBLE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
