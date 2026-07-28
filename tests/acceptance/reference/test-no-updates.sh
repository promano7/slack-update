#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
DEFAULT_CONFIG_TEMPLATE="$REPOSITORY_ROOT/data/config/slack-update.conf"

TARGET=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG_TEMPLATE
EXECUTE_APPLY=0
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/no-updates

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0|slackware-current --execute-apply [options]

Run the real-system acceptance scenario for a fully updated Slackware host with
no available package changes. The scenario executes the real Slackware package
workflow. Run it only on a disposable VM snapshot or an equivalently recoverable
test installation.

Required options:
      --target TARGET          Declare slackware-15.0 or slackware-current
      --execute-apply          Confirm that the real apply workflow may run

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
      --reference-script PATH  Select the reference script under test
      --config-template PATH   Select the schema-1 configuration template
  -h, --help                   Show this help and exit

The generated scenario configuration disables Flatpak, SBo, ELF, Cinnamon, and
boot preparation so this case isolates the Slackware no-package-change path.
The script first requires --check to report no updates, then runs --apply.
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
            --execute-apply)
                EXECUTE_APPLY=1
                shift
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
    [ "$EXECUTE_APPLY" -eq 1 ] || {
        error '--execute-apply is required because this scenario runs real package commands'
        return 1
    }

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
         section == "[elf]" || section == "[boot]" ||
         section == "[cinnamon]") && /^mode=/ {
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

validate_json_result() {
    local operation=$1
    local json_path=$2
    local config_path=$3

    python3 - "$operation" "$json_path" "$config_path" <<'PYTHON_EOF'
import json
import pathlib
import sys

operation, json_path, config_path = sys.argv[1:]
path = pathlib.Path(json_path)

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (OSError, UnicodeError, json.JSONDecodeError) as error:
    raise SystemExit(f"invalid JSON result: {error}")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


require(data.get("schema_version") == 0, "unexpected schema_version")
require(data.get("schema_status") == "provisional", "unexpected schema_status")
require(data.get("operation") == operation, "unexpected operation")
require(data.get("success") is True, "result is not successful")
require(data.get("partial") is False, "result is partial")
require(data.get("reboot") == "none", "unexpected reboot guidance")
require(data.get("boot_safe") is True, "result is not boot-safe")
require(data.get("exit_code") == 0, "unexpected stable exit code")
require(data.get("exit_code_stable") is True, "exit code is not marked stable")
require(data.get("config_path") == config_path, "unexpected config path")
require(data.get("warnings") == [], "unexpected warnings")
require(data.get("errors") == [], "unexpected errors")

modules = data.get("modules")
require(isinstance(modules, dict), "missing modules object")
slackware = modules.get("slackware")
require(isinstance(slackware, dict), "missing Slackware result")
require(slackware.get("state") == "success", "Slackware module did not succeed")

if operation == "check":
    require(slackware.get("check_exit_code") == 0, "check-updates did not return 0")
    require(slackware.get("updates_available") is False, "updates are available")
elif operation == "apply":
    for key in ("update_exit_code", "install_new_exit_code", "upgrade_all_exit_code"):
        require(slackware.get(key) == 0, f"{key} is not zero")
    require(slackware.get("snapshot_before_valid") is True, "baseline snapshot is invalid")
    require(slackware.get("snapshot_after_valid") is True, "final snapshot is invalid")
    before_count = slackware.get("snapshot_before_records")
    after_count = slackware.get("snapshot_after_records")
    require(isinstance(before_count, int) and before_count > 0, "invalid baseline record count")
    require(after_count == before_count, "package record count changed")
    require(slackware.get("secondary_modules_blocked") is False, "secondary modules were blocked")
    require(slackware.get("abi_changes") is False, "unexpected ABI changes")
    require(slackware.get("kernel_changes") is False, "unexpected kernel changes")
    require(slackware.get("critical_packages") == [], "unexpected critical-package changes")

    for module_name in ("flatpak", "sbo", "elf", "cinnamon", "boot"):
        module = modules.get(module_name)
        require(isinstance(module, dict), f"missing {module_name} result")
        require(module.get("mode") == "disabled", f"{module_name} mode is not disabled")
        require(module.get("activation_state") == "disabled", f"{module_name} was not disabled")
else:
    raise SystemExit(f"unsupported operation: {operation}")
PYTHON_EOF
}

run_reference_operation() {
    local operation=$1
    local json_output=$2
    local diagnostic_output=$3
    local status_output=$4
    local status

    SLACK_UPDATE_CONFIG=$SCENARIO_CONFIG \
        bash "$REFERENCE_SCRIPT" "--$operation" --json \
        > "$json_output" 2> "$diagnostic_output"
    status=$?
    printf '%d\n' "$status" > "$status_output"
    return "$status"
}

report_json_failure_details() {
    local json_path=$1

    python3 - "$json_path" <<'PYTHON_EOF'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (OSError, UnicodeError, json.JSONDecodeError) as error:
    print(f"[DETAIL] JSON result could not be inspected: {error}")
    raise SystemExit(0)

print(f"[DETAIL] stable exit code: {data.get('exit_code', 'missing')}")
modules = data.get("modules")
slackware = modules.get("slackware") if isinstance(modules, dict) else None
if isinstance(slackware, dict):
    for key in ("update_exit_code", "install_new_exit_code", "upgrade_all_exit_code"):
        print(f"[DETAIL] slackware.{key}: {slackware.get(key, 'missing')}")

errors = data.get("errors")
if isinstance(errors, list) and errors:
    for message in errors:
        print(f"[DETAIL] error: {message}")
else:
    print("[DETAIL] error list: empty or unavailable")
PYTHON_EOF
}

capture_host_metadata() {
    local output=$1

    {
        printf 'scenario=no-updates\n'
        printf 'target=%s\n' "$TARGET"
        printf 'captured_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
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
        printf 'scenario=no-updates\n'
        printf 'target=%s\n' "$TARGET"
        printf 'result=%s\n' "$result"
        printf 'passes=%d\n' "$PASS_COUNT"
        printf 'failures=%d\n' "$FAILURE_COUNT"
        printf 'check_exit_code=%s\n' "$(cat "$OUTPUT_DIR/check.exit" 2>/dev/null || printf 'not-run')"
        printf 'apply_exit_code=%s\n' "$(cat "$OUTPUT_DIR/apply.exit" 2>/dev/null || printf 'not-run')"
        printf 'evidence_directory=%s\n' "$OUTPUT_DIR"
    } > "$summary_path"
}

prepare_default_output_root() {
    local project_root=${DEFAULT_OUTPUT_ROOT%/no-updates}

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
    sha256sum -- "$archive" > "$archive.sha256" || return 1
    publish_evidence_archive "$archive" || return 1
    printf '%s\n' "$archive"
}

main() {
    local timestamp
    local check_status
    local apply_status
    local archive

    parse_arguments "$@" || {
        print_usage >&2
        return 2
    }

    [ "$(id -u)" -eq 0 ] || {
        error 'this real-system acceptance scenario requires root'
        return 2
    }

    for command_name in awk cmp date diff find grep mktemp python3 readlink sed sha256sum sort stat tar; do
        require_command "$command_name" || return 2
    done

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
        error '/etc/slackware-version is unavailable; this is not a supported Slackware host'
        return 2
    }
    [ -d /var/log/packages ] || {
        error '/var/log/packages is unavailable'
        return 2
    }
    require_command slackpkg || return 2

    SLACKWARE_VERSION=$(cat /etc/slackware-version)
    validate_slackware_target_version "$TARGET" "$SLACKWARE_VERSION" || {
        error "declared target $TARGET does not match '$SLACKWARE_VERSION'"
        return 2
    }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    if [ -z "$OUTPUT_DIR" ]; then
        prepare_default_output_root || {
            error "failed to prepare the default evidence root: $DEFAULT_OUTPUT_ROOT"
            return 2
        }
        OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
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
    capture_host_metadata "$OUTPUT_DIR/host.txt" || {
        error 'failed to capture host metadata'
        return 2
    }
    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.before.sha256" || {
        error 'failed to capture the baseline package database'
        return 2
    }
    capture_boot_state "$OUTPUT_DIR/boot.before.txt" || {
        error 'failed to capture the baseline boot state'
        return 2
    }

    printf 'Running no-updates precondition check on %s...\n' "$TARGET"
    run_reference_operation check \
        "$OUTPUT_DIR/check.json" \
        "$OUTPUT_DIR/check.stderr.log" \
        "$OUTPUT_DIR/check.exit"
    check_status=$?
    assert_equal 0 "$check_status" 'the real --check process exits with status 0'
    if validate_json_result check "$OUTPUT_DIR/check.json" "$SCENARIO_CONFIG" \
        > "$OUTPUT_DIR/check.validation.log" 2>&1; then
        record_pass 'the real --check JSON reports no available updates'
    else
        record_failure 'the real --check JSON does not satisfy the no-updates contract'
        report_json_failure_details "$OUTPUT_DIR/check.json" \
            | tee -a "$ASSERTION_LOG" >&2 || true
    fi

    if [ "$check_status" -ne 0 ] || [ "$FAILURE_COUNT" -ne 0 ]; then
        printf 'The no-updates precondition failed; --apply was not executed.\n' >&2
        write_summary "$OUTPUT_DIR/summary.txt"
        archive=$(create_evidence_archive) || archive=unavailable
        printf 'Evidence: %s\n' "$archive"
        return 1
    fi

    printf 'Running the isolated real --apply workflow...\n'
    run_reference_operation apply \
        "$OUTPUT_DIR/apply.json" \
        "$OUTPUT_DIR/apply.stderr.log" \
        "$OUTPUT_DIR/apply.exit"
    apply_status=$?
    assert_equal 0 "$apply_status" 'the real --apply process exits with status 0'
    if validate_json_result apply "$OUTPUT_DIR/apply.json" "$SCENARIO_CONFIG" \
        > "$OUTPUT_DIR/apply.validation.log" 2>&1; then
        record_pass 'the real --apply JSON satisfies the no-package-change contract'
    else
        record_failure 'the real --apply JSON does not satisfy the no-package-change contract'
        report_json_failure_details "$OUTPUT_DIR/apply.json" \
            | tee -a "$ASSERTION_LOG" >&2 || true
    fi

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.after.sha256" || {
        record_failure 'the final package database could not be captured'
        : > "$OUTPUT_DIR/packages.after.sha256"
    }
    capture_boot_state "$OUTPUT_DIR/boot.after.txt" || {
        record_failure 'the final boot state could not be captured'
        : > "$OUTPUT_DIR/boot.after.txt"
    }

    assert_files_equal \
        "$OUTPUT_DIR/packages.before.sha256" \
        "$OUTPUT_DIR/packages.after.sha256" \
        "$OUTPUT_DIR/packages.diff" \
        'the installed package database is byte-for-byte unchanged'
    assert_files_equal \
        "$OUTPUT_DIR/boot.before.txt" \
        "$OUTPUT_DIR/boot.after.txt" \
        "$OUTPUT_DIR/boot.diff" \
        'the observed initrd and GRUB configuration state is unchanged'

    write_summary "$OUTPUT_DIR/summary.txt"
    archive=$(create_evidence_archive) || {
        error 'failed to create the evidence archive'
        return 1
    }
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"

    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
