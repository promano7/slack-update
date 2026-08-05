#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
DEFAULT_CONFIG_TEMPLATE="$REPOSITORY_ROOT/data/config/slack-update.conf"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/normal-update
DEFAULT_CURRENT_KERNEL_BOOT_ACCEPTANCE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-accepted.json"
DEFAULT_CURRENT_KERNEL_TRANSACTION_READINESS_ACCEPTANCE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-transaction-readiness-20260805-accepted.json"

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG_TEMPLATE
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=
ALLOW_KERNEL_UPDATE=0
ALLOW_CRITICAL_UPDATE=0
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
SCENARIO_CONFIG=
SLACKWARE_VERSION=
HOSTNAME_VALUE=
INSTALL_NEW_CANDIDATE_COUNT=0
UPGRADE_CANDIDATE_COUNT=0
TOTAL_CANDIDATE_COUNT=0
KERNEL_CANDIDATE_COUNT=0
CRITICAL_CANDIDATE_COUNT=0
CANDIDATE_SET_SHA256=

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0|slackware-current --preflight [options]
       ${0##*/} --target slackware-15.0|slackware-current --execute-apply \\
                     --confirm-hostname HOSTNAME \\
                     --confirm-candidates-sha256 SHA256 [options]

Run the real-system acceptance scenario for a normal Slackware package update.
Always run --preflight first. Each mode refreshes Slackware package metadata,
then asks slackpkg to generate the actual install-new and upgrade-all candidate
lists with a negative default answer. Preflight proves that the installed
package database and observed boot files were not modified.

The apply mode performs real package changes. On physical hardware, review the
preflight evidence and have a tested recovery path before using it.

Required options:
      --target TARGET          Declare slackware-15.0 or slackware-current
      --preflight              Detect candidates without installing them
      --execute-apply          Run the real Slack-Update apply workflow
      --confirm-hostname NAME  Required with --execute-apply; must match hostname
      --confirm-candidates-sha256 SHA256
                              Require the exact reviewed candidate-set digest

Optional arguments:
      --allow-kernel-update    Permit kernel consideration after boot preflight review
      --confirm-kernel-boot-preflight-sha256 SHA256
                              Require an accepted apply-ready current-kernel boot or
                              final transaction-readiness record
      --allow-critical-update  Permit apply when preflight finds critical packages
      --output-dir PATH        Store evidence under an absolute, new directory
      --reference-script PATH  Select the reference script under test
      --config-template PATH   Select the schema-1 configuration template
  -h, --help                   Show this help and exit

The generated configuration disables Flatpak, SBo, ELF, and Cinnamon so this
scenario isolates official Slackware packages. Boot preparation remains in auto
mode so kernel changes fail closed unless initrd and GRUB handling is available.
EOF_USAGE
}

error() {
    printf 'ERROR: %s\n' "$*" >&2
}

record_pass() {
    local message=$1

    PASS_COUNT=$((PASS_COUNT + 1))
    printf '[PASS] %s\n' "$message" | tee -a "$ASSERTION_LOG"
}

record_failure() {
    local message=$1

    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf '[FAIL] %s\n' "$message" | tee -a "$ASSERTION_LOG" >&2
}

assert_equal() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" = "$expected" ]; then
        record_pass "$message"
    else
        record_failure "$message (expected '$expected', got '$actual')"
    fi
}

assert_nonempty_file() {
    local path=$1
    local message=$2

    if [ -s "$path" ]; then
        record_pass "$message"
    else
        record_failure "$message"
    fi
}

assert_files_equal() {
    local before=$1
    local after=$2
    local diff_path=$3
    local message=$4

    if cmp -s -- "$before" "$after"; then
        : > "$diff_path"
        record_pass "$message"
    else
        diff -u -- "$before" "$after" > "$diff_path" 2>&1 || true
        record_failure "$message"
    fi
}

assert_files_different() {
    local before=$1
    local after=$2
    local diff_path=$3
    local message=$4

    diff -u -- "$before" "$after" > "$diff_path" 2>&1 || true
    if cmp -s -- "$before" "$after"; then
        record_failure "$message"
    else
        record_pass "$message"
    fi
}

validate_target_name() {
    case "$1" in
        slackware-15.0|slackware-current) return 0 ;;
        *) return 1 ;;
    esac
}

validate_slackware_target_version() {
    local target=$1
    local version=$2

    case "$target" in
        slackware-15.0)
            [ "$version" = 'Slackware 15.0' ]
            ;;
        slackware-current)
            case "$version" in
                Slackware\ *+|Slackware\ current*) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                [ "$#" -ge 2 ] || {
                    error '--target requires a value'
                    return 1
                }
                TARGET=$2
                shift 2
                ;;
            --preflight)
                [ -z "$MODE" ] || {
                    error 'select exactly one of --preflight or --execute-apply'
                    return 1
                }
                MODE=preflight
                shift
                ;;
            --execute-apply)
                [ -z "$MODE" ] || {
                    error 'select exactly one of --preflight or --execute-apply'
                    return 1
                }
                MODE=apply
                shift
                ;;
            --confirm-hostname)
                [ "$#" -ge 2 ] || {
                    error '--confirm-hostname requires a value'
                    return 1
                }
                CONFIRM_HOSTNAME=$2
                shift 2
                ;;
            --confirm-candidates-sha256)
                [ "$#" -ge 2 ] || {
                    error '--confirm-candidates-sha256 requires a value'
                    return 1
                }
                CONFIRM_CANDIDATES_SHA256=$2
                shift 2
                ;;
            --allow-kernel-update)
                ALLOW_KERNEL_UPDATE=1
                shift
                ;;
            --confirm-kernel-boot-preflight-sha256)
                [ "$#" -ge 2 ] || {
                    error '--confirm-kernel-boot-preflight-sha256 requires a value'
                    return 1
                }
                CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=$2
                shift 2
                ;;
            --allow-critical-update)
                ALLOW_CRITICAL_UPDATE=1
                shift
                ;;
            --output-dir)
                [ "$#" -ge 2 ] || {
                    error '--output-dir requires a value'
                    return 1
                }
                OUTPUT_DIR=$2
                shift 2
                ;;
            --reference-script)
                [ "$#" -ge 2 ] || {
                    error '--reference-script requires a value'
                    return 1
                }
                REFERENCE_SCRIPT=$2
                shift 2
                ;;
            --config-template)
                [ "$#" -ge 2 ] || {
                    error '--config-template requires a value'
                    return 1
                }
                CONFIG_TEMPLATE=$2
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

    validate_target_name "$TARGET" || {
        error '--target must be slackware-15.0 or slackware-current'
        return 1
    }
    case "$MODE" in
        preflight) ;;
        apply)
            [ -n "$CONFIRM_HOSTNAME" ] || {
                error '--confirm-hostname is required with --execute-apply'
                return 1
            }
            [ -n "$CONFIRM_CANDIDATES_SHA256" ] || {
                error '--confirm-candidates-sha256 is required with --execute-apply'
                return 1
            }
            [ "${#CONFIRM_CANDIDATES_SHA256}" -eq 64 ] || {
                error '--confirm-candidates-sha256 must contain exactly 64 hexadecimal characters'
                return 1
            }
            case "$CONFIRM_CANDIDATES_SHA256" in
                *[!0-9A-Fa-f]*)
                    error '--confirm-candidates-sha256 must contain exactly 64 hexadecimal characters'
                    return 1
                    ;;
            esac
            CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
            if [ -n "$CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256" ]; then
                [ "${#CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256}" -eq 64 ] || {
                    error '--confirm-kernel-boot-preflight-sha256 must contain exactly 64 hexadecimal characters'
                    return 1
                }
                case "$CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256" in
                    *[!0-9A-Fa-f]*)
                        error '--confirm-kernel-boot-preflight-sha256 must contain exactly 64 hexadecimal characters'
                        return 1
                        ;;
                esac
                CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=${CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256,,}
            fi
            ;;
        *)
            error 'select exactly one of --preflight or --execute-apply'
            return 1
            ;;
    esac

    for path in "$REFERENCE_SCRIPT" "$CONFIG_TEMPLATE"; do
        case "$path" in
            /*) ;;
            *)
                error "path must be absolute: $path"
                return 1
                ;;
        esac
    done
    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in
            /*) ;;
            *)
                error '--output-dir must be absolute'
                return 1
                ;;
        esac
    fi
    case "$OUTPUT_DIR$REFERENCE_SCRIPT$CONFIG_TEMPLATE" in
        *[[:space:]]*)
            error 'acceptance paths must not contain whitespace'
            return 1
            ;;
    esac
}

validate_current_kernel_boot_acceptance() {
    [ -n "$CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256" ] || return 1
    python3 -         "$DEFAULT_CURRENT_KERNEL_BOOT_ACCEPTANCE"         "$DEFAULT_CURRENT_KERNEL_TRANSACTION_READINESS_ACCEPTANCE"         "$CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256"         "$CANDIDATE_SET_SHA256" <<'PY_VALIDATE_CURRENT_KERNEL'
import json
import pathlib
import sys

boot_path, readiness_path, evidence_sha256, candidate_sha256 = sys.argv[1:]


def load(path):
    candidate = pathlib.Path(path)
    if not candidate.is_file() or candidate.is_symlink():
        return None
    try:
        return json.loads(candidate.read_text(encoding='utf-8'))
    except Exception:
        return None


boot = load(boot_path)
if isinstance(boot, dict):
    checks = [
        boot.get('scenario') == 'current-kernel-boot-preflight',
        boot.get('target') == 'slackware-current',
        boot.get('accepted') is True,
        boot.get('archive_sha256') == evidence_sha256,
        boot.get('normal_update_candidate_set_sha256') == candidate_sha256,
        boot.get('apply_ready') is True,
        boot.get('apply_authorized') is False,
    ]
    if all(checks):
        raise SystemExit(0)

readiness = load(readiness_path)
if isinstance(readiness, dict):
    checks = [
        readiness.get('scenario') == 'current-kernel-transaction-readiness-preflight',
        readiness.get('target') == 'slackware-current',
        readiness.get('accepted') is True,
        readiness.get('archive_sha256') == evidence_sha256,
        readiness.get('candidate_set_sha256') == candidate_sha256,
        readiness.get('fresh_candidate_set_sha256') == candidate_sha256,
        readiness.get('readiness_status') == 'apply-ready',
        readiness.get('apply_ready') is True,
        readiness.get('apply_authorized') is False,
        readiness.get('pause_safe') is False,
        readiness.get('next_stage') == 'normal-update-apply-authorization-review',
    ]
    if all(checks):
        raise SystemExit(0)

raise SystemExit(1)
PY_VALIDATE_CURRENT_KERNEL
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        error "required command is unavailable: $1"
        return 1
    }
}

write_acceptance_config() {
    local template=$1
    local output=$2
    local runtime_root=$3

    awk \
        -v work_dir="$runtime_root/work" \
        -v log_dir="$runtime_root/log" \
        -v lock_file="$runtime_root/slack-update.lock" '
        /^\[/ {
            section = $0
        }
        section == "[core]" && /^work_dir=/ {
            print "work_dir=" work_dir
            next
        }
        section == "[core]" && /^log_dir=/ {
            print "log_dir=" log_dir
            next
        }
        section == "[core]" && /^lock_file=/ {
            print "lock_file=" lock_file
            next
        }
        (section == "[flatpak]" || section == "[sbo]" ||
         section == "[elf]" || section == "[cinnamon]") && /^mode=/ {
            print "mode=disabled"
            next
        }
        {
            print
        }
    ' "$template" > "$output"
}

capture_package_database() {
    local package_database=$1
    local output=$2

    [ -d "$package_database" ] || return 1
    (
        cd "$package_database" || exit 1
        find . -maxdepth 1 -type f -printf '%P\0' \
            | LC_ALL=C sort -z \
            | while IFS= read -r -d '' package_record; do
                sha256sum -- "$package_record"
            done
    ) > "$output"
}

capture_boot_state() {
    local output=$1
    local path
    local type
    local metadata
    local digest
    local link_target

    : > "$output"
    for path in /boot/initrd.gz /boot/grub/grub.cfg; do
        if [ -L "$path" ]; then
            type=symlink
            metadata=$(stat -c '%a|%u|%g|%s|%Y' -- "$path") || return 1
            link_target=$(readlink -- "$path") || return 1
            if [ -e "$path" ]; then
                digest=$(sha256sum -- "$path" | awk '{print $1}') || return 1
            else
                digest=broken
            fi
            printf '%s|%s|%s|%s|%s\n' "$path" "$type" "$metadata" "$digest" "$link_target" >> "$output"
        elif [ -f "$path" ]; then
            type=regular
            metadata=$(stat -c '%a|%u|%g|%s|%Y' -- "$path") || return 1
            digest=$(sha256sum -- "$path" | awk '{print $1}') || return 1
            printf '%s|%s|%s|%s|\n' "$path" "$type" "$metadata" "$digest" >> "$output"
        elif [ -e "$path" ]; then
            type=other
            metadata=$(stat -c '%a|%u|%g|%s|%Y' -- "$path") || return 1
            printf '%s|%s|%s|||\n' "$path" "$type" "$metadata" >> "$output"
        else
            printf '%s|missing||||\n' "$path" >> "$output"
        fi
    done
}

extract_slackpkg_candidates() {
    local input=$1
    local output=$2

    python3 - "$input" "$output" <<'PYTHON_EOF'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
text = source.read_text(encoding="utf-8", errors="replace")

pattern = re.compile(
    r"(?<![A-Za-z0-9+._-])"
    r"(?:[^\s\"']*/)?"
    r"([A-Za-z0-9][A-Za-z0-9+._-]*-"
    r"[^\s/\"']+-"
    r"(?:x86_64|x86|noarch|fw|i[3-6]86|aarch64|arm[^\s/\"'-]*)-"
    r"[^\s/\"']+\.t(?:xz|gz|bz|lz))"
)

candidates = sorted({match.group(1).rsplit("/", 1)[-1] for match in pattern.finditer(text)})
target.write_text("".join(f"{item}\n" for item in candidates), encoding="utf-8")
PYTHON_EOF
}

classify_candidates() {
    local combined=$1
    local names=$2
    local kernel=$3
    local critical=$4

    python3 - "$combined" "$names" "$kernel" "$critical" <<'PYTHON_EOF'
import pathlib
import sys

source, names_path, kernel_path, critical_path = map(pathlib.Path, sys.argv[1:])
kernel_names = {"kernel-generic", "kernel-huge", "kernel-modules", "kernel-headers"}
critical_names = {"glibc", "aaa_glibc-solibs", "openssl", "openssl-solibs", "dbus", "slackpkg", "pkgtools"}

names = []
for line in source.read_text(encoding="utf-8").splitlines():
    filename = line.strip()
    if not filename:
        continue
    stem = filename
    for suffix in (".txz", ".tgz", ".tbz", ".tlz"):
        if stem.endswith(suffix):
            stem = stem[: -len(suffix)]
            break
    fields = stem.rsplit("-", 3)
    if len(fields) != 4 or not fields[0]:
        raise SystemExit(f"cannot parse Slackware package filename: {filename}")
    names.append((fields[0], filename))

unique_names = sorted({name for name, _ in names})
kernel = sorted({filename for name, filename in names if name in kernel_names})
critical = sorted({filename for name, filename in names if name in critical_names})

names_path.write_text("".join(f"{name}\n" for name in unique_names), encoding="utf-8")
kernel_path.write_text("".join(f"{item}\n" for item in kernel), encoding="utf-8")
critical_path.write_text("".join(f"{item}\n" for item in critical), encoding="utf-8")
PYTHON_EOF
}

run_metadata_refresh() {
    local output=$1
    local status_output=$2
    local status=0

    LC_ALL=C LANG=C TERM=dumb \
        slackpkg -dialog=off -batch=on -default_answer=y update \
        > "$output" 2>&1 || status=$?
    printf '%d\n' "$status" > "$status_output"
    return "$status"
}

run_candidate_probe() {
    local action=$1
    local output=$2
    local status_output=$3
    local status=0

    LC_ALL=C LANG=C TERM=dumb \
        slackpkg -dialog=off -batch=on -default_answer=n "$action" \
        > "$output" 2>&1 || status=$?
    printf '%d\n' "$status" > "$status_output"
    case "$status" in
        0|20) return 0 ;;
        *) return "$status" ;;
    esac
}

run_reference_apply() {
    local json_output=$1
    local diagnostic_output=$2
    local status_output=$3
    local status=0

    SLACK_UPDATE_CONFIG=$SCENARIO_CONFIG \
        bash "$REFERENCE_SCRIPT" --apply --json \
        > "$json_output" 2> "$diagnostic_output" || status=$?
    printf '%d\n' "$status" > "$status_output"
    return "$status"
}

validate_apply_json() {
    local json_path=$1
    local config_path=$2
    local process_status=$3

    python3 - "$json_path" "$config_path" "$process_status" <<'PYTHON_EOF'
import json
import pathlib
import sys

json_path, config_path, process_status = sys.argv[1:]
data = json.loads(pathlib.Path(json_path).read_text(encoding="utf-8"))
status = int(process_status)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


require(data.get("schema_version") == 0, "unexpected schema_version")
require(data.get("operation") == "apply", "unexpected operation")
require(data.get("success") is True, "result is not successful")
require(data.get("partial") is False, "result is partial")
require(data.get("boot_safe") is True, "result is not boot-safe")
require(data.get("exit_code") == status, "JSON exit code differs from process status")
require(status in (0, 4, 5), "unexpected successful stable exit code")
require(data.get("config_path") == config_path, "unexpected config path")
require(data.get("errors") == [], "unexpected errors")

expected_reboot = {0: "none", 4: "recommended", 5: "required"}[status]
require(data.get("reboot") == expected_reboot, "reboot guidance does not match exit code")

modules = data.get("modules")
require(isinstance(modules, dict), "missing modules object")
slackware = modules.get("slackware")
require(isinstance(slackware, dict), "missing Slackware result")
require(slackware.get("state") == "success", "Slackware module did not succeed")
require(slackware.get("update_exit_code") == 0, "slackpkg update did not succeed")
for key in ("install_new_exit_code", "upgrade_all_exit_code"):
    require(slackware.get(key) in (0, 20), f"unexpected {key}")
require(slackware.get("postinstall_policy") == "defer", "unexpected post-install policy")
require(slackware.get("postinstall_processing_enabled") is False, "interactive post-install processing is enabled")
require(slackware.get("pending_new_config_files_valid") is True, "pending .new file scan is invalid")
pending_count = slackware.get("pending_new_config_files_count")
pending_files = slackware.get("pending_new_config_files")
require(isinstance(pending_count, int) and pending_count >= 0, "invalid pending .new file count")
require(isinstance(pending_files, list), "missing pending .new file list")
require(len(pending_files) == pending_count, "pending .new file count does not match the list")
require(slackware.get("snapshot_before_valid") is True, "baseline snapshot is invalid")
require(slackware.get("snapshot_after_valid") is True, "final snapshot is invalid")
require(slackware.get("secondary_modules_blocked") is False, "secondary modules were blocked")

for module_name in ("flatpak", "sbo", "elf", "cinnamon"):
    module = modules.get(module_name)
    require(isinstance(module, dict), f"missing {module_name} result")
    require(module.get("mode") == "disabled", f"{module_name} mode is not disabled")

boot = modules.get("boot")
require(isinstance(boot, dict), "missing boot result")
require(boot.get("mode") == "auto", "boot mode is not auto")

critical_packages = slackware.get("critical_packages")
require(isinstance(critical_packages, list), "missing critical package list")

initrd_required = boot.get("initrd_required")
grub_required = boot.get("grub_required")
require(isinstance(initrd_required, bool), "invalid initrd-required state")
require(isinstance(grub_required, bool), "invalid GRUB-required state")
boot_preparation_required = initrd_required or grub_required

# kernel_changes is intentionally broader than boot-kernel replacement: it also
# covers kernel-firmware, kernel-source, and header updates. Only the explicit
# boot requirements determine whether stable code 5 and boot preparation are
# mandatory.
if boot_preparation_required:
    require(slackware.get("kernel_changes") is True, "boot preparation lacks a kernel-change trigger")
    require(status == 5, "boot-kernel changes did not require reboot")
    require(boot.get("state") == "success", "boot preparation did not succeed")
    if initrd_required:
        require(boot.get("initrd_state") == "success", "required initrd preparation did not succeed")
    if grub_required:
        require(boot.get("grub_state") == "success", "required GRUB preparation did not succeed")
else:
    require(status != 5, "reboot-required status lacks boot preparation")
    require(boot.get("state") in ("not-required", "success"), "unexpected boot state")

if critical_packages and not boot_preparation_required:
    require(status == 4, "critical package changes did not recommend reboot")
elif status == 4:
    require(bool(critical_packages), "reboot recommendation lacks critical package changes")
PYTHON_EOF
}

capture_host_metadata() {
    local output=$1

    {
        printf 'scenario=normal-update\n'
        printf 'mode=%s\n' "$MODE"
        printf 'target=%s\n' "$TARGET"
        printf 'captured_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'hostname=%s\n' "$HOSTNAME_VALUE"
        printf 'slackware_version=%s\n' "$SLACKWARE_VERSION"
        printf 'uname=%s\n' "$(uname -a)"
        printf 'package_database=%s\n' /var/log/packages
        printf 'package_database_resolved=%s\n' "$(readlink -f -- /var/log/packages 2>/dev/null || printf unresolved)"
        printf 'reference_script=%s\n' "$REFERENCE_SCRIPT"
        printf 'reference_sha256=%s\n' "$(sha256sum -- "$REFERENCE_SCRIPT" | awk '{print $1}')"
        printf 'config_template=%s\n' "$CONFIG_TEMPLATE"
        printf 'config_template_sha256=%s\n' "$(sha256sum -- "$CONFIG_TEMPLATE" | awk '{print $1}')"
        printf 'active_mirrors_begin\n'
        if [ -r /etc/slackpkg/mirrors ]; then
            grep -Ev '^[[:space:]]*(#|$)' /etc/slackpkg/mirrors || true
        fi
        printf 'active_mirrors_end\n'
        printf 'slackpkg_package_records_begin\n'
        find -H /var/log/packages -maxdepth 1 -type f -name 'slackpkg-*' -printf '%f\n' 2>/dev/null \
            | LC_ALL=C sort
        printf 'slackpkg_package_records_end\n'
    } > "$output"
}

write_summary() {
    local result=PASS
    local summary_path=$1

    [ "$FAILURE_COUNT" -eq 0 ] || result=FAIL
    {
        printf 'scenario=normal-update\n'
        printf 'mode=%s\n' "$MODE"
        printf 'target=%s\n' "$TARGET"
        printf 'hostname=%s\n' "$HOSTNAME_VALUE"
        printf 'result=%s\n' "$result"
        printf 'passes=%d\n' "$PASS_COUNT"
        printf 'failures=%d\n' "$FAILURE_COUNT"
        printf 'install_new_candidates=%d\n' "$INSTALL_NEW_CANDIDATE_COUNT"
        printf 'upgrade_candidates=%d\n' "$UPGRADE_CANDIDATE_COUNT"
        printf 'total_candidates=%d\n' "$TOTAL_CANDIDATE_COUNT"
        printf 'candidate_set_sha256=%s\n' "${CANDIDATE_SET_SHA256:-not-calculated}"
        printf 'kernel_candidates=%d\n' "$KERNEL_CANDIDATE_COUNT"
        printf 'critical_candidates=%d\n' "$CRITICAL_CANDIDATE_COUNT"
        printf 'metadata_update_exit_code=%s\n' "$(cat "$OUTPUT_DIR/metadata.update.exit" 2>/dev/null || printf 'not-run')"
        printf 'apply_exit_code=%s\n' "$(cat "$OUTPUT_DIR/apply.exit" 2>/dev/null || printf 'not-run')"
        printf 'evidence_directory=%s\n' "$OUTPUT_DIR"
    } > "$summary_path"
}

prepare_default_output_root() {
    local project_root=${DEFAULT_OUTPUT_ROOT%/normal-update}

    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    chmod 0755 -- "$project_root" "$DEFAULT_OUTPUT_ROOT" || return 1
}

publish_evidence_archive() {
    local archive=$1
    local owner_uid=${SUDO_UID:-}
    local owner_gid=${SUDO_GID:-}

    chmod 0600 -- "$archive" "$archive.sha256" || return 1
    if [ -n "$owner_uid" ] && [ -n "$owner_gid" ]; then
        case "$owner_uid$owner_gid" in
            *[!0-9]*) ;;
            *) chown -- "$owner_uid:$owner_gid" "$archive" "$archive.sha256" || return 1 ;;
        esac
    fi
}

create_evidence_archive() {
    local parent
    local base
    local archive

    parent=$(dirname -- "$OUTPUT_DIR")
    base=$(basename -- "$OUTPUT_DIR")
    archive="$OUTPUT_DIR.tar.gz"

    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum -- "${archive##*/}") > "$archive.sha256" || return 1
    publish_evidence_archive "$archive" || return 1
    printf '%s\n' "$archive"
}

print_evidence_verification_command() {
    local archive=$1
    local owner=${SUDO_USER:-promano}
    local owner_home

    [ -n "$owner" ] && [ "$owner" != root ] || owner=promano
    owner_home=$(awk -F: -v owner="$owner" '$1 == owner { print $6; exit }' /etc/passwd)
    [ -n "$owner_home" ] || owner_home="/home/$owner"

    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' \
        "$owner_home" "${archive##*/}.sha256"
}

print_evidence_copy_command() {
    local archive=$1
    local owner=${SUDO_USER:-promano}
    local owner_group
    local owner_home

    [ -n "$owner" ] && [ "$owner" != root ] || owner=promano
    owner_group=$(id -gn "$owner" 2>/dev/null) || return 0
    owner_home=$(awk -F: -v owner="$owner" '$1 == owner { print $6; exit }' /etc/passwd)
    [ -n "$owner_home" ] || owner_home="/home/$owner"

    printf 'Copy evidence command: '
    printf 'sudo install -o %q -g %q -m 0600 %q %q && ' \
        "$owner" "$owner_group" "$archive" "$owner_home/${archive##*/}"
    printf 'sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$owner_group" "$archive.sha256" "$owner_home/${archive##*/}.sha256"
}

finish_with_evidence() {
    local archive

    write_summary "$OUTPUT_DIR/summary.txt"
    archive=$(create_evidence_archive) || {
        error 'failed to create the evidence archive'
        return 1
    }
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"
    print_evidence_copy_command "$archive"
    print_evidence_verification_command "$archive"
    [ "$FAILURE_COUNT" -eq 0 ]
}

main() {
    local timestamp
    local metadata_update_status
    local install_probe_status
    local upgrade_probe_status
    local apply_status

    parse_arguments "$@" || {
        print_usage >&2
        return 2
    }
    [ "$(id -u)" -eq 0 ] || {
        error 'this real-system acceptance scenario requires root'
        return 2
    }

    for command_name in awk cmp date diff find grep hostname python3 readlink sed sha256sum sort stat tar; do
        require_command "$command_name" || return 2
    done
    require_command slackpkg || return 2
    [ -r "$REFERENCE_SCRIPT" ] || {
        error "reference script is not readable: $REFERENCE_SCRIPT"
        return 2
    }
    bash -n "$REFERENCE_SCRIPT" || {
        error "reference script does not pass bash syntax validation: $REFERENCE_SCRIPT"
        return 2
    }
    [ -r "$CONFIG_TEMPLATE" ] || {
        error "configuration template is not readable: $CONFIG_TEMPLATE"
        return 2
    }
    [ -r /etc/slackware-version ] || {
        error '/etc/slackware-version is unavailable'
        return 2
    }
    [ -d /var/log/packages ] || {
        error '/var/log/packages is unavailable'
        return 2
    }

    SLACKWARE_VERSION=$(cat /etc/slackware-version)
    validate_slackware_target_version "$TARGET" "$SLACKWARE_VERSION" || {
        error "declared target $TARGET does not match '$SLACKWARE_VERSION'"
        return 2
    }
    HOSTNAME_VALUE=$(hostname)
    if [ "$MODE" = apply ] && [ "$CONFIRM_HOSTNAME" != "$HOSTNAME_VALUE" ]; then
        error "--confirm-hostname must exactly match '$HOSTNAME_VALUE'"
        return 2
    fi

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    if [ -z "$OUTPUT_DIR" ]; then
        prepare_default_output_root || {
            error "failed to prepare the default evidence root: $DEFAULT_OUTPUT_ROOT"
            return 2
        }
        OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${MODE}-${timestamp}"
    fi
    [ ! -e "$OUTPUT_DIR" ] || {
        error "output directory already exists: $OUTPUT_DIR"
        return 2
    }

    mkdir -p -- "$OUTPUT_DIR/runtime" || return 2
    chmod 0700 -- "$OUTPUT_DIR" "$OUTPUT_DIR/runtime" || return 2
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"
    : > "$ASSERTION_LOG"
    SCENARIO_CONFIG="$OUTPUT_DIR/slack-update.conf"

    write_acceptance_config "$CONFIG_TEMPLATE" "$SCENARIO_CONFIG" "$OUTPUT_DIR/runtime" || {
        error 'failed to generate the isolated scenario configuration'
        return 2
    }
    capture_host_metadata "$OUTPUT_DIR/host.txt" || return 2
    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.before.sha256" || return 2
    capture_boot_state "$OUTPUT_DIR/boot.before.txt" || return 2

    printf 'Refreshing Slackware package metadata before candidate classification...\n'
    run_metadata_refresh "$OUTPUT_DIR/metadata.update.log" "$OUTPUT_DIR/metadata.update.exit"
    metadata_update_status=$?
    case "$metadata_update_status" in
        0) record_pass 'Slackware package metadata was refreshed before candidate classification' ;;
        *) record_failure "Slackware package metadata refresh failed with status $metadata_update_status" ;;
    esac

    printf 'Detecting real install-new candidates without installing them...\n'
    run_candidate_probe install-new "$OUTPUT_DIR/install-new.probe.log" "$OUTPUT_DIR/install-new.probe.exit"
    install_probe_status=$?
    case "$install_probe_status" in
        0) record_pass 'the install-new candidate probe completed safely' ;;
        *) record_failure "the install-new candidate probe failed with status $install_probe_status" ;;
    esac

    printf 'Detecting real upgrade-all candidates without installing them...\n'
    run_candidate_probe upgrade-all "$OUTPUT_DIR/upgrade-all.probe.log" "$OUTPUT_DIR/upgrade-all.probe.exit"
    upgrade_probe_status=$?
    case "$upgrade_probe_status" in
        0) record_pass 'the upgrade-all candidate probe completed safely' ;;
        *) record_failure "the upgrade-all candidate probe failed with status $upgrade_probe_status" ;;
    esac

    extract_slackpkg_candidates "$OUTPUT_DIR/install-new.probe.log" "$OUTPUT_DIR/install-new.candidates.txt" || \
        record_failure 'install-new candidate output could not be parsed'
    extract_slackpkg_candidates "$OUTPUT_DIR/upgrade-all.probe.log" "$OUTPUT_DIR/upgrade-all.candidates.txt" || \
        record_failure 'upgrade-all candidate output could not be parsed'
    cat "$OUTPUT_DIR/install-new.candidates.txt" "$OUTPUT_DIR/upgrade-all.candidates.txt" \
        | LC_ALL=C sort -u > "$OUTPUT_DIR/all.candidates.txt"

    classify_candidates \
        "$OUTPUT_DIR/all.candidates.txt" \
        "$OUTPUT_DIR/candidate-package-names.txt" \
        "$OUTPUT_DIR/kernel.candidates.txt" \
        "$OUTPUT_DIR/critical.candidates.txt" || \
        record_failure 'candidate package filenames could not be classified'

    INSTALL_NEW_CANDIDATE_COUNT=$(wc -l < "$OUTPUT_DIR/install-new.candidates.txt")
    UPGRADE_CANDIDATE_COUNT=$(wc -l < "$OUTPUT_DIR/upgrade-all.candidates.txt")
    TOTAL_CANDIDATE_COUNT=$(wc -l < "$OUTPUT_DIR/all.candidates.txt")
    KERNEL_CANDIDATE_COUNT=$(wc -l < "$OUTPUT_DIR/kernel.candidates.txt")
    CRITICAL_CANDIDATE_COUNT=$(wc -l < "$OUTPUT_DIR/critical.candidates.txt")
    CANDIDATE_SET_SHA256=$(sha256sum -- "$OUTPUT_DIR/all.candidates.txt" | awk '{print $1}')

    if [ "$TOTAL_CANDIDATE_COUNT" -gt 0 ]; then
        record_pass "slackpkg reports $TOTAL_CANDIDATE_COUNT real package candidate(s)"
    else
        record_failure 'slackpkg did not expose any parseable package candidates'
    fi

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.after-preflight.sha256" || \
        record_failure 'the package database could not be captured after candidate probing'
    capture_boot_state "$OUTPUT_DIR/boot.after-preflight.txt" || \
        record_failure 'the boot state could not be captured after candidate probing'
    assert_files_equal \
        "$OUTPUT_DIR/packages.before.sha256" \
        "$OUTPUT_DIR/packages.after-preflight.sha256" \
        "$OUTPUT_DIR/packages.preflight.diff" \
        'candidate probing did not modify the installed package database'
    assert_files_equal \
        "$OUTPUT_DIR/boot.before.txt" \
        "$OUTPUT_DIR/boot.after-preflight.txt" \
        "$OUTPUT_DIR/boot.preflight.diff" \
        'candidate probing did not modify initrd or GRUB state'

    printf 'Candidate summary: install-new=%d, upgrade-all=%d, total=%d, kernel=%d, critical=%d\n' \
        "$INSTALL_NEW_CANDIDATE_COUNT" "$UPGRADE_CANDIDATE_COUNT" "$TOTAL_CANDIDATE_COUNT" \
        "$KERNEL_CANDIDATE_COUNT" "$CRITICAL_CANDIDATE_COUNT"
    printf 'Candidate set SHA-256: %s\n' "$CANDIDATE_SET_SHA256"

    if [ "$MODE" = preflight ]; then
        printf 'Preflight only: no package installation was authorized.\n'
        finish_with_evidence
        return $?
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        error 'preflight validation failed; real apply was not executed'
        finish_with_evidence
        return 1
    fi
    if [ "$CANDIDATE_SET_SHA256" != "$CONFIRM_CANDIDATES_SHA256" ]; then
        record_failure 'the refreshed candidate set does not match the explicitly reviewed SHA-256'
        error 'real apply was not executed because the package candidate set changed'
        finish_with_evidence
        return 1
    fi
    if [ "$KERNEL_CANDIDATE_COUNT" -gt 0 ] && [ "$ALLOW_KERNEL_UPDATE" -ne 1 ]; then
        record_failure 'kernel candidates require the explicit --allow-kernel-update option'
        error 'real apply was not executed because kernel packages are candidates'
        finish_with_evidence
        return 1
    fi
    if [ "$TARGET" = slackware-current ] && [ "$KERNEL_CANDIDATE_COUNT" -gt 0 ]; then
        if ! validate_current_kernel_boot_acceptance; then
            record_failure 'Slackware-current kernel candidates require a matching accepted apply-ready boot or transaction-readiness record'
            error 'real apply was not executed because the current-kernel boot/readiness record is missing, mismatched, or not apply-ready'
            finish_with_evidence
            return 1
        fi
        record_pass 'the accepted Slackware-current kernel boot/readiness record matches the refreshed candidate set'
    fi
    if [ "$CRITICAL_CANDIDATE_COUNT" -gt 0 ] && [ "$ALLOW_CRITICAL_UPDATE" -ne 1 ]; then
        record_failure 'critical candidates require the explicit --allow-critical-update option'
        error 'real apply was not executed because critical packages are candidates'
        finish_with_evidence
        return 1
    fi

    printf 'Running the isolated real Slack-Update apply workflow on %s...\n' "$HOSTNAME_VALUE"
    run_reference_apply "$OUTPUT_DIR/apply.json" "$OUTPUT_DIR/apply.stderr.log" "$OUTPUT_DIR/apply.exit"
    apply_status=$?
    case "$apply_status" in
        0|4|5) record_pass "the real --apply process completed with successful stable code $apply_status" ;;
        *) record_failure "the real --apply process failed with stable code $apply_status" ;;
    esac
    if validate_apply_json "$OUTPUT_DIR/apply.json" "$SCENARIO_CONFIG" "$apply_status" \
        > "$OUTPUT_DIR/apply.validation.log" 2>&1; then
        record_pass 'the real --apply JSON satisfies the normal-update contract'
    else
        record_failure 'the real --apply JSON does not satisfy the normal-update contract'
    fi

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.after.sha256" || \
        record_failure 'the final package database could not be captured'
    capture_boot_state "$OUTPUT_DIR/boot.after.txt" || \
        record_failure 'the final boot state could not be captured'
    assert_files_different \
        "$OUTPUT_DIR/packages.before.sha256" \
        "$OUTPUT_DIR/packages.after.sha256" \
        "$OUTPUT_DIR/packages.apply.diff" \
        'the real update changed the installed package database'
    diff -u -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
        > "$OUTPUT_DIR/boot.apply.diff" 2>&1 || true

    finish_with_evidence
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
