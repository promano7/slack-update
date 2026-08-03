#!/bin/bash
#
# slack-update-reference.sh — Unattended Slackware 15.0/current + SBo + Flatpak + Cinnamon update reference
#
# Installation:
#   install -Dm755 slack-update-reference.sh /usr/local/sbin/slack-update
#   install -Dm644 data/config/slack-update.conf /etc/slack-update/slack-update.conf
#
# Manual use:   slack-update
# Cron example: 0 3 * * 0 /usr/local/sbin/slack-update --check

set -uo pipefail
IFS=$'\n\t'

# Use a deterministic root execution environment for cron and other unattended
# launchers. Administrative Slackware commands may live in sbin directories
# that are commonly absent from a minimal cron PATH.
readonly SLACK_UPDATE_SYSTEM_PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

initialize_execution_environment() {
    PATH=$SLACK_UPDATE_SYSTEM_PATH
    HOME=/root
    USER=root
    LOGNAME=root
    SHELL=/bin/bash
    TMPDIR=/tmp
    LANG=C
    LC_ALL=C
    TERM=dumb
    GIT_TERMINAL_PROMPT=0
    GIT_ASKPASS=/bin/false
    SSH_ASKPASS=/bin/false

    export PATH HOME USER LOGNAME SHELL TMPDIR LANG LC_ALL TERM
    export GIT_TERMINAL_PROMPT GIT_ASKPASS SSH_ASKPASS
    unset CDPATH DISPLAY WAYLAND_DISPLAY XAUTHORITY
    unset DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR
    umask 077
}

# Stable process exit codes shared with the future C implementation.
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_FAILURE=1
readonly EXIT_PARTIAL=2
readonly EXIT_BOOT_UNSAFE=3
readonly EXIT_REBOOT_RECOMMENDED=4
readonly EXIT_REBOOT_REQUIRED=5
readonly EXIT_ALREADY_RUNNING=6
readonly EXIT_INVALID_INPUT=7
readonly EXIT_PRIVILEGE_UNAVAILABLE=8

# Command-line interface functions

print_usage() {
    cat <<EOF
Usage: ${0##*/} [--check | --apply | --dry-run] [--json | --events]
       ${0##*/} [--help]

Run the current Slack-Update reference workflow.

Options:
      --check    Check for Slackware repository updates without applying changes
      --apply    Run the existing update workflow and apply changes
      --dry-run  Produce a complete non-modifying execution plan
      --json     Write the final structured result to standard output
      --events   Stream provisional NDJSON progress events to standard output
  -h, --help     Show this help message and exit

Running without an operation preserves the current legacy apply workflow.
With --json or --events, human-readable progress is written to standard error
and the log. The two machine-readable output modes are mutually exclusive.
Configuration is loaded from /etc/slack-update/slack-update.conf. When the
script runs from the source tree, data/config/slack-update.conf is used as a
development fallback. SLACK_UPDATE_CONFIG may select another file for tests.
Optional modules use enabled, disabled, or auto activation modes in that file.
Process exit codes 0 through 8 are stable and documented in README.md.
EOF
}

parse_arguments() {
    SHOW_HELP=0
    JSON_OUTPUT=0
    EVENTS_OUTPUT=0
    OPERATION=apply
    OPERATION_EXPLICIT=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --check|--apply|--dry-run)
                if [ "$OPERATION_EXPLICIT" -eq 1 ]; then
                    echo "Error: only one operation may be specified" >&2
                    return 1
                fi
                OPERATION=${1#--}
                OPERATION_EXPLICIT=1
                ;;
            --json)
                if [ "$EVENTS_OUTPUT" -eq 1 ]; then
                    echo "Error: --json and --events are mutually exclusive" >&2
                    return 1
                fi
                JSON_OUTPUT=1
                ;;
            --events)
                if [ "$JSON_OUTPUT" -eq 1 ]; then
                    echo "Error: --json and --events are mutually exclusive" >&2
                    return 1
                fi
                EVENTS_OUTPUT=1
                ;;
            -h|--help)
                SHOW_HELP=1
                ;;
            --)
                shift
                if [ "$#" -gt 0 ]; then
                    echo "Error: unexpected argument: $1" >&2
                    return 1
                fi
                break
                ;;
            -*)
                echo "Error: unknown option: $1" >&2
                return 1
                ;;
            *)
                echo "Error: unexpected argument: $1" >&2
                return 1
                ;;
        esac
        shift
    done
}

# Configuration functions

config_error() {
    echo "Error: $*" >&2
    return 1
}

trim_whitespace() {
    local value=$1

    value=${value#"${value%%[![:space:]]*}"}
    value=${value%"${value##*[![:space:]]}"}
    printf '%s' "$value"
}

resolve_configuration_file() {
    local script_dir
    local source_config

    if [ -n "${SLACK_UPDATE_CONFIG:-}" ]; then
        CONFIG_FILE=$SLACK_UPDATE_CONFIG
        case "$CONFIG_FILE" in
            /*) ;;
            *)
                config_error "SLACK_UPDATE_CONFIG must be an absolute path"
                return 1
                ;;
        esac
    else
        CONFIG_FILE=/etc/slack-update/slack-update.conf

        if [ ! -f "$CONFIG_FILE" ]; then
            script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || return 1
            source_config="$script_dir/../../data/config/slack-update.conf"
            if [ -f "$source_config" ]; then
                CONFIG_FILE=$(CDPATH= cd -- "$(dirname -- "$source_config")" && pwd -P)/${source_config##*/}
            fi
        fi
    fi

    [ -f "$CONFIG_FILE" ] || {
        config_error "configuration file not found: $CONFIG_FILE"
        return 1
    }
    [ -r "$CONFIG_FILE" ] || {
        config_error "configuration file is not readable: $CONFIG_FILE"
        return 1
    }
}

initialize_configuration_state() {
    CONFIG_SCHEMA_VERSION=
    CONFIG_WORK_DIR=
    CONFIG_LOG_DIR=
    CONFIG_LOCK_FILE=
    CONFIG_LOG_RETENTION_DAYS=
    CONFIG_PACKAGE_DATABASE=
    CONFIG_SLACKWARE_INSTALL_NEW=
    CONFIG_SLACKWARE_UPGRADE_ALL=
    CONFIG_FLATPAK_MODE=auto
    CONFIG_SBO_MODE=auto
    CONFIG_SBOPKG_CONFIG=
    CONFIG_SBO_QUEUE_DIR_FALLBACK=
    CONFIG_SBO_PACKAGE_TAG=
    CONFIG_SBO_OPTIONS_FILE=/etc/slack-update/sbo-options.sqf
    CONFIG_ELF_MODE=auto
    CONFIG_ELF_SCAN_PATHS=
    CONFIG_ABI_PACKAGES=
    CONFIG_CINNAMON_ABI_PACKAGES=
    CONFIG_CRITICAL_PACKAGES=
    CONFIG_KERNEL_PACKAGES=
    CONFIG_KERNEL_BOOT_PACKAGES=
    CONFIG_KERNEL_HEADERS_PACKAGES=
    CONFIG_BOOT_MODE=auto
    CONFIG_MKINITRD_CONFIG=
    CONFIG_INITRD_DEFAULT_OUTPUT=
    CONFIG_INITRD_KERNEL_PACKAGE=kernel-generic
    CONFIG_KERNEL_MODULES_DIRECTORY=/lib/modules
    CONFIG_GRUB_DIRECTORY=
    CONFIG_GRUB_CONFIG=
    CONFIG_CINNAMON_MODE=auto
    CONFIG_CSB_REPOSITORY=
    CONFIG_CSB_REMOTE=
    CONFIG_CSB_BRANCH=
    CONFIG_CSB_BUILDER=
    SEEN_CONFIG_KEYS='|'
}

assign_configuration_value() {
    local section=$1
    local key=$2
    local value=$3
    local line_number=$4
    local full_key="$section.$key"

    case "$SEEN_CONFIG_KEYS" in
        *"|$full_key|"*)
            config_error "$CONFIG_FILE:$line_number: duplicate key: $full_key"
            return 1
            ;;
    esac
    SEEN_CONFIG_KEYS="${SEEN_CONFIG_KEYS}${full_key}|"

    case "$full_key" in
        core.schema_version) CONFIG_SCHEMA_VERSION=$value ;;
        core.work_dir) CONFIG_WORK_DIR=$value ;;
        core.log_dir) CONFIG_LOG_DIR=$value ;;
        core.lock_file) CONFIG_LOCK_FILE=$value ;;
        core.log_retention_days) CONFIG_LOG_RETENTION_DAYS=$value ;;
        core.package_database) CONFIG_PACKAGE_DATABASE=$value ;;
        slackware.install_new) CONFIG_SLACKWARE_INSTALL_NEW=$value ;;
        slackware.upgrade_all) CONFIG_SLACKWARE_UPGRADE_ALL=$value ;;
        flatpak.mode) CONFIG_FLATPAK_MODE=$value ;;
        sbo.mode) CONFIG_SBO_MODE=$value ;;
        sbo.sbopkg_config) CONFIG_SBOPKG_CONFIG=$value ;;
        sbo.queue_dir_fallback) CONFIG_SBO_QUEUE_DIR_FALLBACK=$value ;;
        sbo.package_tag) CONFIG_SBO_PACKAGE_TAG=$value ;;
        sbo.options_file) CONFIG_SBO_OPTIONS_FILE=$value ;;
        elf.mode) CONFIG_ELF_MODE=$value ;;
        elf.scan_paths) CONFIG_ELF_SCAN_PATHS=$value ;;
        packages.abi) CONFIG_ABI_PACKAGES=$value ;;
        packages.cinnamon_abi) CONFIG_CINNAMON_ABI_PACKAGES=$value ;;
        packages.critical) CONFIG_CRITICAL_PACKAGES=$value ;;
        packages.kernel) CONFIG_KERNEL_PACKAGES=$value ;;
        packages.kernel_boot) CONFIG_KERNEL_BOOT_PACKAGES=$value ;;
        packages.kernel_headers) CONFIG_KERNEL_HEADERS_PACKAGES=$value ;;
        boot.mode) CONFIG_BOOT_MODE=$value ;;
        boot.mkinitrd_config) CONFIG_MKINITRD_CONFIG=$value ;;
        boot.initrd_default_output) CONFIG_INITRD_DEFAULT_OUTPUT=$value ;;
        boot.kernel_package) CONFIG_INITRD_KERNEL_PACKAGE=$value ;;
        boot.modules_directory) CONFIG_KERNEL_MODULES_DIRECTORY=$value ;;
        boot.grub_directory) CONFIG_GRUB_DIRECTORY=$value ;;
        boot.grub_config) CONFIG_GRUB_CONFIG=$value ;;
        cinnamon.mode) CONFIG_CINNAMON_MODE=$value ;;
        cinnamon.repository) CONFIG_CSB_REPOSITORY=$value ;;
        cinnamon.remote) CONFIG_CSB_REMOTE=$value ;;
        cinnamon.branch) CONFIG_CSB_BRANCH=$value ;;
        cinnamon.builder) CONFIG_CSB_BUILDER=$value ;;
        *)
            config_error "$CONFIG_FILE:$line_number: unknown configuration key: $full_key"
            return 1
            ;;
    esac
}

parse_configuration_file() {
    local raw_line
    local line
    local section=
    local key
    local value
    local line_number=0

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        line_number=$((line_number + 1))
        line=${raw_line%$'\r'}
        line=$(trim_whitespace "$line")

        case "$line" in
            ''|'#'*|';'*)
                continue
                ;;
            '['*']')
                section=${line#'['}
                section=${section%']'}
                section=$(trim_whitespace "$section")
                case "$section" in
                    core|slackware|flatpak|sbo|elf|packages|boot|cinnamon) ;;
                    *)
                        config_error "$CONFIG_FILE:$line_number: unknown section: $section"
                        return 1
                        ;;
                esac
                ;;
            *=*)
                [ -n "$section" ] || {
                    config_error "$CONFIG_FILE:$line_number: key outside a section"
                    return 1
                }
                key=${line%%=*}
                value=${line#*=}
                key=$(trim_whitespace "$key")
                value=$(trim_whitespace "$value")
                case "$key" in
                    ''|*[!a-z0-9_]* )
                        config_error "$CONFIG_FILE:$line_number: invalid key: $key"
                        return 1
                        ;;
                esac
                assign_configuration_value "$section" "$key" "$value" "$line_number" || return 1
                ;;
            *)
                config_error "$CONFIG_FILE:$line_number: invalid configuration line"
                return 1
                ;;
        esac
    done < "$CONFIG_FILE"
}

require_configuration_value() {
    local key=$1
    local value=$2

    [ -n "$value" ] || {
        config_error "missing required configuration key: $key"
        return 1
    }
}

validate_boolean_configuration() {
    local key=$1
    local value=$2

    case "$value" in
        true|false) ;;
        *)
            config_error "$key must be true or false"
            return 1
            ;;
    esac
}

validate_module_mode_configuration() {
    local key=$1
    local value=$2

    case "$value" in
        enabled|disabled|auto) ;;
        *)
            config_error "$key must be enabled, disabled, or auto"
            return 1
            ;;
    esac
}

validate_absolute_path_configuration() {
    local key=$1
    local value=$2

    case "$value" in
        /*) ;;
        *)
            config_error "$key must be an absolute path"
            return 1
            ;;
    esac
}

validate_package_list_configuration() {
    local key=$1
    local value=$2
    local token
    local old_ifs=$IFS
    local tokens=()

    IFS=' ' read -r -a tokens <<< "$value"
    IFS=$old_ifs
    [ "${#tokens[@]}" -gt 0 ] || {
        config_error "$key must contain at least one package name"
        return 1
    }

    for token in "${tokens[@]}"; do
        case "$token" in
            ''|*[!A-Za-z0-9+_.-]* )
                config_error "$key contains an invalid package name: $token"
                return 1
                ;;
        esac
    done
}

validate_configuration() {
    local required_key
    local required_value
    local scan_path
    local old_ifs=$IFS

    while IFS='|' read -r required_key required_value; do
        require_configuration_value "$required_key" "$required_value" || return 1
    done <<EOF
core.schema_version|$CONFIG_SCHEMA_VERSION
core.work_dir|$CONFIG_WORK_DIR
core.log_dir|$CONFIG_LOG_DIR
core.lock_file|$CONFIG_LOCK_FILE
core.log_retention_days|$CONFIG_LOG_RETENTION_DAYS
core.package_database|$CONFIG_PACKAGE_DATABASE
slackware.install_new|$CONFIG_SLACKWARE_INSTALL_NEW
slackware.upgrade_all|$CONFIG_SLACKWARE_UPGRADE_ALL
sbo.sbopkg_config|$CONFIG_SBOPKG_CONFIG
sbo.queue_dir_fallback|$CONFIG_SBO_QUEUE_DIR_FALLBACK
sbo.package_tag|$CONFIG_SBO_PACKAGE_TAG
sbo.options_file|$CONFIG_SBO_OPTIONS_FILE
elf.scan_paths|$CONFIG_ELF_SCAN_PATHS
packages.abi|$CONFIG_ABI_PACKAGES
packages.cinnamon_abi|$CONFIG_CINNAMON_ABI_PACKAGES
packages.critical|$CONFIG_CRITICAL_PACKAGES
packages.kernel|$CONFIG_KERNEL_PACKAGES
packages.kernel_boot|$CONFIG_KERNEL_BOOT_PACKAGES
packages.kernel_headers|$CONFIG_KERNEL_HEADERS_PACKAGES
boot.mkinitrd_config|$CONFIG_MKINITRD_CONFIG
boot.initrd_default_output|$CONFIG_INITRD_DEFAULT_OUTPUT
boot.kernel_package|$CONFIG_INITRD_KERNEL_PACKAGE
boot.modules_directory|$CONFIG_KERNEL_MODULES_DIRECTORY
boot.grub_directory|$CONFIG_GRUB_DIRECTORY
boot.grub_config|$CONFIG_GRUB_CONFIG
cinnamon.repository|$CONFIG_CSB_REPOSITORY
cinnamon.remote|$CONFIG_CSB_REMOTE
cinnamon.branch|$CONFIG_CSB_BRANCH
cinnamon.builder|$CONFIG_CSB_BUILDER
EOF

    [ "$CONFIG_SCHEMA_VERSION" = 1 ] || {
        config_error "unsupported configuration schema version: $CONFIG_SCHEMA_VERSION"
        return 1
    }

    case "$CONFIG_LOG_RETENTION_DAYS" in
        ''|*[!0-9]*)
            config_error "core.log_retention_days must be a non-negative integer"
            return 1
            ;;
    esac

    validate_boolean_configuration slackware.install_new "$CONFIG_SLACKWARE_INSTALL_NEW" || return 1
    validate_boolean_configuration slackware.upgrade_all "$CONFIG_SLACKWARE_UPGRADE_ALL" || return 1
    validate_module_mode_configuration flatpak.mode "$CONFIG_FLATPAK_MODE" || return 1
    validate_module_mode_configuration sbo.mode "$CONFIG_SBO_MODE" || return 1
    validate_module_mode_configuration elf.mode "$CONFIG_ELF_MODE" || return 1
    validate_module_mode_configuration boot.mode "$CONFIG_BOOT_MODE" || return 1
    validate_module_mode_configuration cinnamon.mode "$CONFIG_CINNAMON_MODE" || return 1

    for required_value in \
        "$CONFIG_WORK_DIR" "$CONFIG_LOG_DIR" "$CONFIG_LOCK_FILE" \
        "$CONFIG_PACKAGE_DATABASE" "$CONFIG_SBOPKG_CONFIG" \
        "$CONFIG_SBO_QUEUE_DIR_FALLBACK" "$CONFIG_SBO_OPTIONS_FILE" \
        "$CONFIG_MKINITRD_CONFIG" \
        "$CONFIG_INITRD_DEFAULT_OUTPUT" "$CONFIG_KERNEL_MODULES_DIRECTORY" \
        "$CONFIG_GRUB_DIRECTORY" \
        "$CONFIG_GRUB_CONFIG" "$CONFIG_CSB_REPOSITORY"; do
        validate_absolute_path_configuration path "$required_value" || return 1
    done

    case "$CONFIG_SBO_PACKAGE_TAG" in
        *[!A-Za-z0-9_+.-]* )
            config_error "sbo.package_tag contains unsupported characters"
            return 1
            ;;
    esac

    case "$CONFIG_CSB_BRANCH" in
        -*|*[^A-Za-z0-9._/-]* )
            config_error "cinnamon.branch contains unsupported characters"
            return 1
            ;;
    esac

    case "$CONFIG_CSB_BUILDER" in
        ''|/*|..|../*|*/../*|*/..|*[!A-Za-z0-9._/-]* )
            config_error "cinnamon.builder must be a safe relative path"
            return 1
            ;;
    esac

    case "$CONFIG_CSB_REMOTE" in
        *[[:space:]]*|-* )
            config_error "cinnamon.remote contains unsupported characters"
            return 1
            ;;
        https://*) ;;
        *)
            config_error "cinnamon.remote must use an explicit https:// URL"
            return 1
            ;;
    esac

    validate_package_list_configuration packages.abi "$CONFIG_ABI_PACKAGES" || return 1
    validate_package_list_configuration packages.cinnamon_abi "$CONFIG_CINNAMON_ABI_PACKAGES" || return 1
    validate_package_list_configuration packages.critical "$CONFIG_CRITICAL_PACKAGES" || return 1
    validate_package_list_configuration packages.kernel "$CONFIG_KERNEL_PACKAGES" || return 1
    validate_package_list_configuration packages.kernel_boot "$CONFIG_KERNEL_BOOT_PACKAGES" || return 1
    validate_package_list_configuration packages.kernel_headers "$CONFIG_KERNEL_HEADERS_PACKAGES" || return 1
    validate_package_list_configuration boot.kernel_package "$CONFIG_INITRD_KERNEL_PACKAGE" || return 1
    case "$CONFIG_INITRD_KERNEL_PACKAGE" in
        *\ * )
            config_error "boot.kernel_package must contain exactly one package name"
            return 1
            ;;
    esac

    IFS=':' read -r -a ELF_SCAN_PATHS <<< "$CONFIG_ELF_SCAN_PATHS"
    IFS=$old_ifs
    [ "${#ELF_SCAN_PATHS[@]}" -gt 0 ] || {
        config_error "elf.scan_paths must contain at least one path"
        return 1
    }
    for scan_path in "${ELF_SCAN_PATHS[@]}"; do
        validate_absolute_path_configuration elf.scan_paths "$scan_path" || return 1
    done
}

apply_configuration() {
    local old_ifs=$IFS

    WORKDIR_CONFIG=$CONFIG_WORK_DIR
    LOGDIR_CONFIG=$CONFIG_LOG_DIR
    LOCKFILE=$CONFIG_LOCK_FILE
    LOG_RETENTION_DAYS=$CONFIG_LOG_RETENTION_DAYS
    PACKAGE_DATABASE=$CONFIG_PACKAGE_DATABASE
    SLACKWARE_INSTALL_NEW=$CONFIG_SLACKWARE_INSTALL_NEW
    SLACKWARE_UPGRADE_ALL=$CONFIG_SLACKWARE_UPGRADE_ALL
    FLATPAK_MODE=$CONFIG_FLATPAK_MODE
    SBO_MODE=$CONFIG_SBO_MODE
    SBOPKG_CONFIG=$CONFIG_SBOPKG_CONFIG
    SBO_QUEUE_DIR_FALLBACK=$CONFIG_SBO_QUEUE_DIR_FALLBACK
    SBO_PACKAGE_TAG=$CONFIG_SBO_PACKAGE_TAG
    SBO_OPTIONS_FILE=$CONFIG_SBO_OPTIONS_FILE
    ELF_MODE=$CONFIG_ELF_MODE
    BOOT_MODE=$CONFIG_BOOT_MODE
    MKINITRD_CONFIG=$CONFIG_MKINITRD_CONFIG
    INITRD_DEFAULT_OUTPUT=$CONFIG_INITRD_DEFAULT_OUTPUT
    INITRD_KERNEL_PACKAGE=$CONFIG_INITRD_KERNEL_PACKAGE
    KERNEL_MODULES_DIRECTORY=$CONFIG_KERNEL_MODULES_DIRECTORY
    GRUB_DIRECTORY=$CONFIG_GRUB_DIRECTORY
    GRUB_CONFIG=$CONFIG_GRUB_CONFIG
    CINNAMON_MODE=$CONFIG_CINNAMON_MODE
    CSB_DIR_CONFIG=$CONFIG_CSB_REPOSITORY
    CSB_REMOTE=$CONFIG_CSB_REMOTE
    CSB_BRANCH=$CONFIG_CSB_BRANCH
    CSB_BUILDER=$CONFIG_CSB_BUILDER

    IFS=' ' read -r -a ABI_PACKAGES <<< "$CONFIG_ABI_PACKAGES"
    IFS=' ' read -r -a CINNAMON_ABI <<< "$CONFIG_CINNAMON_ABI_PACKAGES"
    IFS=' ' read -r -a CRITICAL_PACKAGES <<< "$CONFIG_CRITICAL_PACKAGES"
    IFS=' ' read -r -a KERNEL_PACKAGES <<< "$CONFIG_KERNEL_PACKAGES"
    IFS=' ' read -r -a KERNEL_BOOT_PACKAGES <<< "$CONFIG_KERNEL_BOOT_PACKAGES"
    IFS=' ' read -r -a KERNEL_HEADERS_PACKAGES <<< "$CONFIG_KERNEL_HEADERS_PACKAGES"
    IFS=$old_ifs
}

load_configuration() {
    resolve_configuration_file || return 1
    initialize_configuration_state
    parse_configuration_file || return 1
    validate_configuration || return 1
    apply_configuration
}

array_contains() {
    local expected=$1
    shift
    local item

    for item in "$@"; do
        [ "$item" = "$expected" ] && return 0
    done
    return 1
}

# Slackware package record parsing

parse_slackware_package_record() {
    local input=$1
    local base
    local remainder

    SLACKWARE_PACKAGE_RECORD=
    SLACKWARE_PACKAGE_NAME=
    SLACKWARE_PACKAGE_VERSION=
    SLACKWARE_PACKAGE_ARCH=
    SLACKWARE_PACKAGE_BUILD=

    base=${input##*/}
    case "$base" in
        *.tgz|*.tbz|*.tlz|*.txz)
            base=${base%.*}
            ;;
    esac

    [ -n "$base" ] || return 1

    case "$base" in
        *[[:space:]]*) return 1 ;;
    esac

    remainder=${base%-*}
    [ "$remainder" != "$base" ] || return 1
    SLACKWARE_PACKAGE_BUILD=${base##*-}
    [ -n "$SLACKWARE_PACKAGE_BUILD" ] || return 1

    base=$remainder
    remainder=${base%-*}
    [ "$remainder" != "$base" ] || return 1
    SLACKWARE_PACKAGE_ARCH=${base##*-}
    [ -n "$SLACKWARE_PACKAGE_ARCH" ] || return 1

    base=$remainder
    remainder=${base%-*}
    [ "$remainder" != "$base" ] || return 1
    SLACKWARE_PACKAGE_VERSION=${base##*-}
    [ -n "$SLACKWARE_PACKAGE_VERSION" ] || return 1

    SLACKWARE_PACKAGE_NAME=$remainder
    [ -n "$SLACKWARE_PACKAGE_NAME" ] || return 1

    SLACKWARE_PACKAGE_RECORD="${SLACKWARE_PACKAGE_NAME}-${SLACKWARE_PACKAGE_VERSION}-${SLACKWARE_PACKAGE_ARCH}-${SLACKWARE_PACKAGE_BUILD}"
}

slackware_package_name() {
    parse_slackware_package_record "$1" || return 1
    printf '%s\n' "$SLACKWARE_PACKAGE_NAME"
}

slackware_package_record_has_build_suffix() {
    local record=$1
    local suffix=$2

    [ -n "$suffix" ] || return 1
    parse_slackware_package_record "$record" || return 1

    case "$SLACKWARE_PACKAGE_BUILD" in
        *"$suffix") return 0 ;;
        *) return 1 ;;
    esac
}

package_snapshot_records_for_name() {
    local snapshot=$1
    local expected_name=$2
    local record

    [ -f "$snapshot" ] || return 0

    while IFS= read -r record || [ -n "$record" ]; do
        parse_slackware_package_record "$record" || continue
        if [ "$SLACKWARE_PACKAGE_NAME" = "$expected_name" ]; then
            printf '%s\n' "$SLACKWARE_PACKAGE_RECORD"
        fi
    done < "$snapshot"
}

enumerate_package_database_records() {
    # Follow a command-line compatibility symlink such as /var/log/packages,
    # but do not follow symlinks stored inside the package database itself.
    find -H "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n'
}

validate_package_snapshot() {
    local snapshot=$1
    local record
    local count=0

    PACKAGE_SNAPSHOT_ERROR=
    PACKAGE_SNAPSHOT_RECORD_COUNT=0

    if [ ! -f "$snapshot" ]; then
        PACKAGE_SNAPSHOT_ERROR="snapshot does not exist: $snapshot"
        return 1
    fi

    if [ ! -r "$snapshot" ]; then
        PACKAGE_SNAPSHOT_ERROR="snapshot is not readable: $snapshot"
        return 1
    fi

    if [ ! -s "$snapshot" ]; then
        PACKAGE_SNAPSHOT_ERROR="snapshot is empty: $snapshot"
        return 1
    fi

    if ! LC_ALL=C sort -c -u "$snapshot" >/dev/null 2>&1; then
        PACKAGE_SNAPSHOT_ERROR="snapshot records are not strictly sorted and unique: $snapshot"
        return 1
    fi

    while IFS= read -r record || [ -n "$record" ]; do
        if ! parse_slackware_package_record "$record"; then
            PACKAGE_SNAPSHOT_ERROR="snapshot contains an invalid package record: $record"
            return 1
        fi

        if [ "$record" != "$SLACKWARE_PACKAGE_RECORD" ]; then
            PACKAGE_SNAPSHOT_ERROR="snapshot contains a non-canonical package record: $record"
            return 1
        fi

        count=$((count + 1))
    done < "$snapshot"

    if [ "$count" -eq 0 ]; then
        PACKAGE_SNAPSHOT_ERROR="snapshot contains no package records: $snapshot"
        return 1
    fi

    PACKAGE_SNAPSHOT_RECORD_COUNT=$count
}

capture_validated_package_snapshot() {
    local destination=$1
    local destination_directory
    local listing
    local normalized
    local candidate
    local record
    local duplicate
    local source_count=0

    PACKAGE_SNAPSHOT_ERROR=
    PACKAGE_SNAPSHOT_RECORD_COUNT=0

    if [ ! -d "$PACKAGE_DATABASE" ]; then
        PACKAGE_SNAPSHOT_ERROR="package database directory does not exist: $PACKAGE_DATABASE"
        return 1
    fi

    if [ ! -r "$PACKAGE_DATABASE" ] || [ ! -x "$PACKAGE_DATABASE" ]; then
        PACKAGE_SNAPSHOT_ERROR="package database directory is not readable: $PACKAGE_DATABASE"
        return 1
    fi

    destination_directory=$(dirname -- "$destination")

    listing=$(mktemp "$destination_directory/.package-records.XXXXXX") || {
        PACKAGE_SNAPSHOT_ERROR="cannot create a temporary package listing in: $destination_directory"
        return 1
    }
    normalized=$(mktemp "$destination_directory/.package-normalized.XXXXXX") || {
        rm -f "$listing"
        PACKAGE_SNAPSHOT_ERROR="cannot create a temporary normalized snapshot in: $destination_directory"
        return 1
    }
    candidate=$(mktemp "$destination_directory/.package-snapshot.XXXXXX") || {
        rm -f "$listing" "$normalized"
        PACKAGE_SNAPSHOT_ERROR="cannot create a temporary validated snapshot in: $destination_directory"
        return 1
    }

    if ! enumerate_package_database_records > "$listing"; then
        rm -f "$listing" "$normalized" "$candidate"
        PACKAGE_SNAPSHOT_ERROR="cannot enumerate package database records: $PACKAGE_DATABASE"
        return 1
    fi

    while IFS= read -r record || [ -n "$record" ]; do
        source_count=$((source_count + 1))
        if ! parse_slackware_package_record "$record"; then
            rm -f "$listing" "$normalized" "$candidate"
            PACKAGE_SNAPSHOT_ERROR="package database contains an invalid package record: $record"
            return 1
        fi
        printf '%s\n' "$SLACKWARE_PACKAGE_RECORD" >> "$normalized"
    done < "$listing"

    rm -f "$listing"

    if [ "$source_count" -eq 0 ]; then
        rm -f "$normalized" "$candidate"
        PACKAGE_SNAPSHOT_ERROR="package database contains no package records: $PACKAGE_DATABASE"
        return 1
    fi

    LC_ALL=C sort "$normalized" > "$candidate" || {
        rm -f "$normalized" "$candidate"
        PACKAGE_SNAPSHOT_ERROR="cannot sort package snapshot records"
        return 1
    }
    rm -f "$normalized"

    duplicate=$(LC_ALL=C uniq -d "$candidate" | head -n 1)
    if [ -n "$duplicate" ]; then
        rm -f "$candidate"
        PACKAGE_SNAPSHOT_ERROR="package database produces a duplicate normalized record: $duplicate"
        return 1
    fi

    if ! validate_package_snapshot "$candidate"; then
        rm -f "$candidate"
        return 1
    fi

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$candidate"
        PACKAGE_SNAPSHOT_ERROR="cannot install validated package snapshot: $destination"
        PACKAGE_SNAPSHOT_RECORD_COUNT=0
        return 1
    fi
}

package_names_with_build_suffix_from_stream() {
    local suffix=$1
    local record

    while IFS= read -r record || [ -n "$record" ]; do
        slackware_package_record_has_build_suffix "$record" "$suffix" || continue
        printf '%s\n' "$SLACKWARE_PACKAGE_NAME"
    done
}

is_safe_sbo_target_name() {
    local target=$1

    case "$target" in
        ''|.|..|-*|@*|*[!A-Za-z0-9_+.-]*) return 1 ;;
        *) return 0 ;;
    esac
}

normalize_sbo_build_options() {
    local options=$1
    local rest
    local name
    local value
    local quote
    local token
    local character
    local index
    local length
    local quoted_value_pattern='^[A-Za-z0-9_+.,:/@%=~ -]*$'
    local unquoted_value_pattern='^[A-Za-z0-9_+.,:/@%=~-]*$'

    SBO_NORMALIZED_BUILD_OPTIONS=
    options=$(trim_whitespace "$options")
    [ -n "$options" ] || return 1
    rest=$options

    while [ -n "$rest" ]; do
        rest=${rest#"${rest%%[![:space:]]*}"}
        [ -n "$rest" ] || break

        case "$rest" in
            *=*) ;;
            *) return 1 ;;
        esac

        name=${rest%%=*}
        case "$name" in
            ''|[!A-Za-z_]*|*[!A-Za-z0-9_]*) return 1 ;;
        esac
        rest=${rest#*=}

        case "${rest:0:1}" in
            "'"|'"')
                quote=${rest:0:1}
                rest=${rest:1}
                value=
                index=0
                length=${#rest}

                while [ "$index" -lt "$length" ]; do
                    character=${rest:index:1}
                    [ "$character" = "$quote" ] && break
                    value+=$character
                    index=$((index + 1))
                done

                [ "$index" -lt "$length" ] || return 1
                [[ "$value" =~ $quoted_value_pattern ]] || return 1
                token="$name=$quote$value$quote"
                rest=${rest:index+1}
                case "$rest" in
                    ''|[[:space:]]*) ;;
                    *) return 1 ;;
                esac
                ;;
            *)
                value=${rest%%[[:space:]]*}
                [[ "$value" =~ $unquoted_value_pattern ]] || return 1
                token="$name=$value"
                rest=${rest#"$value"}
                ;;
        esac

        if [ -n "$SBO_NORMALIZED_BUILD_OPTIONS" ]; then
            SBO_NORMALIZED_BUILD_OPTIONS+=" "
        fi
        SBO_NORMALIZED_BUILD_OPTIONS+=$token
    done

    [ -n "$SBO_NORMALIZED_BUILD_OPTIONS" ]
}

sbo_queue_record_from_line() {
    local line=$1
    local target
    local options=

    SBO_QUEUE_LINE_TARGET=
    SBO_QUEUE_LINE_OPTIONS=
    SBO_QUEUE_LINE_RECORD=
    line=${line%$'\r'}
    line=${line%%#*}
    line=$(trim_whitespace "$line")

    [ -n "$line" ] || return 1

    case "$line" in
        *'|'*'|'*) return 2 ;;
    esac

    target=${line%%|*}
    target=$(trim_whitespace "$target")
    case "$target" in
        *[[:space:]]*) return 2 ;;
    esac

    # Queue references and deselected entries are control records, not targets.
    case "$target" in
        @*|-*) return 1 ;;
    esac

    is_safe_sbo_target_name "$target" || return 2

    if [[ "$line" == *'|'* ]]; then
        options=${line#*|}
        normalize_sbo_build_options "$options" || return 2
        options=$SBO_NORMALIZED_BUILD_OPTIONS
    fi

    SBO_QUEUE_LINE_TARGET=$target
    SBO_QUEUE_LINE_OPTIONS=$options
    SBO_QUEUE_LINE_RECORD=$target
    if [ -n "$options" ]; then
        SBO_QUEUE_LINE_RECORD+=" | $options"
    fi
}

sbo_target_from_queue_line() {
    sbo_queue_record_from_line "$1"
}

sbo_option_records_from_queue_stream() {
    local line
    local status

    while IFS= read -r line || [ -n "$line" ]; do
        if sbo_queue_record_from_line "$line"; then
            if [ -n "$SBO_QUEUE_LINE_OPTIONS" ]; then
                printf '%s\t%s\n' "$SBO_QUEUE_LINE_TARGET" "$SBO_QUEUE_LINE_OPTIONS"
            fi
        else
            status=$?
            [ "$status" -eq 1 ] || return "$status"
        fi
    done
}

sbo_option_records_from_override_stream() {
    local line
    local normalized

    while IFS= read -r line || [ -n "$line" ]; do
        normalized=${line%$'\r'}
        normalized=${normalized%%#*}
        normalized=$(trim_whitespace "$normalized")
        [ -n "$normalized" ] || continue

        if ! sbo_queue_record_from_line "$line"; then
            return 2
        fi
        [ -n "$SBO_QUEUE_LINE_OPTIONS" ] || return 2
        printf '%s\t%s\n' "$SBO_QUEUE_LINE_TARGET" "$SBO_QUEUE_LINE_OPTIONS"
    done
}

normalize_sbo_option_records_from_stream() {
    local duplicate_policy=$1
    local record
    local target
    local options
    local extra
    local sorted_targets
    local -A selected_options=()

    SBO_OPTION_NORMALIZATION_ERROR=

    while IFS= read -r record || [ -n "$record" ]; do
        [ -n "$record" ] || continue
        IFS=$'\t' read -r target options extra <<< "$record"
        if [ -z "$target" ] || [ -z "$options" ] || [ -n "${extra:-}" ] \
            || ! is_safe_sbo_target_name "$target" \
            || ! normalize_sbo_build_options "$options"; then
            SBO_OPTION_NORMALIZATION_ERROR="invalid SBo build-option record"
            return 1
        fi
        options=$SBO_NORMALIZED_BUILD_OPTIONS

        if [ -n "${selected_options[$target]+present}" ]; then
            if [ "$duplicate_policy" = reject ]; then
                SBO_OPTION_NORMALIZATION_ERROR="duplicate SBo build-option record for target: $target"
                return 1
            fi
            if [ "${selected_options[$target]}" != "$options" ]; then
                SBO_OPTION_NORMALIZATION_ERROR="conflicting SBo build options for target: $target"
                return 1
            fi
        else
            selected_options[$target]=$options
        fi
    done

    [ "${#selected_options[@]}" -gt 0 ] || return 0
    sorted_targets=$(printf '%s\n' "${!selected_options[@]}" | LC_ALL=C sort) || return 1
    while IFS= read -r target; do
        printf '%s\t%s\n' "$target" "${selected_options[$target]}"
    done <<< "$sorted_targets"
}

collect_sbo_option_records_from_sources() {
    local queue_directory=$1
    local options_file=$2
    local destination=$3
    local queue_listing
    local queue_raw
    local queue_normalized
    local override_raw
    local override_normalized
    local candidate
    local destination_directory
    local queue_file
    local record
    local target
    local options
    local -A selected_options=()

    SBO_TARGET_SELECTION_ERROR=
    SBO_OPTION_RECORD_COUNT=0
    queue_listing=$(mktemp) || return 1
    queue_raw=$(mktemp) || {
        rm -f "$queue_listing"
        return 1
    }
    queue_normalized=$(mktemp) || {
        rm -f "$queue_listing" "$queue_raw"
        return 1
    }
    override_raw=$(mktemp) || {
        rm -f "$queue_listing" "$queue_raw" "$queue_normalized"
        return 1
    }
    override_normalized=$(mktemp) || {
        rm -f "$queue_listing" "$queue_raw" "$queue_normalized" "$override_raw"
        return 1
    }
    destination_directory=$(dirname -- "$destination")
    candidate=$(mktemp "$destination_directory/.sbo-options.XXXXXX") || {
        rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
            "$override_raw" "$override_normalized"
        SBO_TARGET_SELECTION_ERROR="cannot create a temporary SBo option map in: $destination_directory"
        return 1
    }

    if [ -d "$queue_directory" ]; then
        if ! find "$queue_directory" -type f -name '*.sqf' -print0 \
            | LC_ALL=C sort -z > "$queue_listing"; then
            rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
                "$override_raw" "$override_normalized" "$candidate"
            SBO_TARGET_SELECTION_ERROR="cannot enumerate SBo queue files: $queue_directory"
            return 1
        fi

        while IFS= read -r -d '' queue_file; do
            if ! sbo_option_records_from_queue_stream < "$queue_file" >> "$queue_raw"; then
                rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
                    "$override_raw" "$override_normalized" "$candidate"
                SBO_TARGET_SELECTION_ERROR="queue contains invalid SBo build options: $queue_file"
                return 1
            fi
        done < "$queue_listing"
    fi

    if ! normalize_sbo_option_records_from_stream merge \
        < "$queue_raw" > "$queue_normalized"; then
        rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
            "$override_raw" "$override_normalized" "$candidate"
        SBO_TARGET_SELECTION_ERROR=${SBO_OPTION_NORMALIZATION_ERROR:-cannot normalize SBo queue options}
        return 1
    fi

    if [ -e "$options_file" ] || [ -L "$options_file" ]; then
        if [ ! -f "$options_file" ] || [ ! -r "$options_file" ]; then
            rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
                "$override_raw" "$override_normalized" "$candidate"
            SBO_TARGET_SELECTION_ERROR="SBo options file is not a readable regular file: $options_file"
            return 1
        fi
        if ! sbo_option_records_from_override_stream \
            < "$options_file" > "$override_raw"; then
            rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
                "$override_raw" "$override_normalized" "$candidate"
            SBO_TARGET_SELECTION_ERROR="SBo options file contains an invalid record: $options_file"
            return 1
        fi
        if ! normalize_sbo_option_records_from_stream reject \
            < "$override_raw" > "$override_normalized"; then
            rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
                "$override_raw" "$override_normalized" "$candidate"
            SBO_TARGET_SELECTION_ERROR=${SBO_OPTION_NORMALIZATION_ERROR:-cannot normalize SBo option overrides}
            return 1
        fi
    fi

    while IFS= read -r record || [ -n "$record" ]; do
        [ -n "$record" ] || continue
        IFS=$'\t' read -r target options <<< "$record"
        selected_options[$target]=$options
    done < "$queue_normalized"
    while IFS= read -r record || [ -n "$record" ]; do
        [ -n "$record" ] || continue
        IFS=$'\t' read -r target options <<< "$record"
        selected_options[$target]=$options
    done < "$override_normalized"

    if [ "${#selected_options[@]}" -gt 0 ]; then
        printf '%s\n' "${!selected_options[@]}" | LC_ALL=C sort \
            | while IFS= read -r target; do
                printf '%s\t%s\n' "$target" "${selected_options[$target]}"
            done > "$candidate" || {
                rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
                    "$override_raw" "$override_normalized" "$candidate"
                SBO_TARGET_SELECTION_ERROR="cannot write normalized SBo option map"
                return 1
            }
    fi

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
            "$override_raw" "$override_normalized" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot install normalized SBo option map: $destination"
        return 1
    fi

    SBO_OPTION_RECORD_COUNT=$(wc -l < "$destination")
    rm -f "$queue_listing" "$queue_raw" "$queue_normalized" \
        "$override_raw" "$override_normalized"
}

normalize_sbo_target_names_from_stream() {
    local target
    local temporary
    local status

    temporary=$(mktemp) || return 1

    while IFS= read -r target || [ -n "$target" ]; do
        [ -n "$target" ] || continue
        if ! is_safe_sbo_target_name "$target"; then
            rm -f "$temporary"
            return 1
        fi
        printf '%s\n' "$target" >> "$temporary"
    done

    LC_ALL=C sort -u "$temporary"
    status=$?
    rm -f "$temporary"
    return "$status"
}

sbo_targets_from_queue_stream() {
    local line
    local status

    while IFS= read -r line || [ -n "$line" ]; do
        if sbo_target_from_queue_line "$line"; then
            printf '%s\n' "$SBO_QUEUE_LINE_TARGET"
        else
            status=$?
            [ "$status" -eq 1 ] || return "$status"
        fi
    done
}

append_sbo_queue_constraints_from_stream() {
    local graph_file=$1
    local line
    local previous=
    local status

    while IFS= read -r line || [ -n "$line" ]; do
        if sbo_target_from_queue_line "$line"; then
            printf 'N\t%s\n' "$SBO_QUEUE_LINE_TARGET" >> "$graph_file" || return 1
            if [ -n "$previous" ] && [ "$previous" != "$SBO_QUEUE_LINE_TARGET" ]; then
                printf 'E\t%s\t%s\n' "$previous" "$SBO_QUEUE_LINE_TARGET" \
                    >> "$graph_file" || return 1
            fi
            previous=$SBO_QUEUE_LINE_TARGET
        else
            status=$?
            [ "$status" -eq 1 ] || return "$status"
        fi
    done
}

order_sbo_queue_graph() {
    LC_ALL=C awk -F '\t' '
        function heap_push(value, parent, current, temporary) {
            heap_size++
            heap[heap_size] = value
            current = heap_size

            while (current > 1) {
                parent = int(current / 2)
                if (heap[parent] <= heap[current]) {
                    break
                }
                temporary = heap[parent]
                heap[parent] = heap[current]
                heap[current] = temporary
                current = parent
            }
        }

        function heap_pop(    result, current, left, right, smallest, temporary) {
            result = heap[1]
            heap[1] = heap[heap_size]
            delete heap[heap_size]
            heap_size--
            current = 1

            while (current <= heap_size) {
                left = current * 2
                right = left + 1
                smallest = current

                if (left <= heap_size && heap[left] < heap[smallest]) {
                    smallest = left
                }
                if (right <= heap_size && heap[right] < heap[smallest]) {
                    smallest = right
                }
                if (smallest == current) {
                    break
                }

                temporary = heap[current]
                heap[current] = heap[smallest]
                heap[smallest] = temporary
                current = smallest
            }

            return result
        }

        $1 == "N" && NF == 2 {
            nodes[$2] = 1
            next
        }
        $1 == "E" && NF == 3 {
            nodes[$2] = 1
            nodes[$3] = 1
            edge = $2 SUBSEP $3
            if (!(edge in edges)) {
                edges[edge] = 1
                successor_count[$2]++
                successors[$2, successor_count[$2]] = $3
                indegree[$3]++
            }
            next
        }
        {
            invalid = 1
        }
        END {
            if (invalid) {
                exit 1
            }

            for (node in nodes) {
                node_count++
                if (indegree[node] == 0) {
                    heap_push(node)
                }
            }

            while (heap_size > 0) {
                selected = heap_pop()
                print selected
                emitted_count++

                for (i = 1; i <= successor_count[selected]; i++) {
                    successor = successors[selected, i]
                    indegree[successor]--
                    if (indegree[successor] == 0) {
                        heap_push(successor)
                    }
                }
            }

            if (emitted_count != node_count) {
                exit 2
            }
        }
    '
}

collect_ordered_sbo_targets_from_queue_directory() {
    local queue_directory=$1
    local destination=$2
    local queue_listing
    local graph_file
    local candidate
    local destination_directory
    local queue_file
    local order_status

    SBO_TARGET_SELECTION_ERROR=
    queue_listing=$(mktemp) || return 1
    graph_file=$(mktemp) || {
        rm -f "$queue_listing"
        return 1
    }
    destination_directory=$(dirname -- "$destination")
    candidate=$(mktemp "$destination_directory/.sbo-ordered-queue.XXXXXX") || {
        rm -f "$queue_listing" "$graph_file"
        SBO_TARGET_SELECTION_ERROR="cannot create a temporary ordered SBo queue in: $destination_directory"
        return 1
    }

    if [ -d "$queue_directory" ]; then
        if ! find "$queue_directory" -type f -name '*.sqf' -print0 \
            | LC_ALL=C sort -z > "$queue_listing"; then
            rm -f "$queue_listing" "$graph_file" "$candidate"
            SBO_TARGET_SELECTION_ERROR="cannot enumerate SBo queue files: $queue_directory"
            return 1
        fi

        while IFS= read -r -d '' queue_file; do
            if ! append_sbo_queue_constraints_from_stream "$graph_file" < "$queue_file"; then
                rm -f "$queue_listing" "$graph_file" "$candidate"
                SBO_TARGET_SELECTION_ERROR="queue contains an invalid SBo target: $queue_file"
                return 1
            fi
        done < "$queue_listing"
    fi

    order_sbo_queue_graph < "$graph_file" > "$candidate"
    order_status=$?
    if [ "$order_status" -ne 0 ]; then
        rm -f "$queue_listing" "$graph_file" "$candidate"
        if [ "$order_status" -eq 2 ]; then
            SBO_TARGET_SELECTION_ERROR="SBo queue dependency order is cyclic or contradictory in: $queue_directory"
        else
            SBO_TARGET_SELECTION_ERROR="cannot resolve SBo queue dependency order from: $queue_directory"
        fi
        return 1
    fi

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$queue_listing" "$graph_file" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot install dependency-ordered SBo queue: $destination"
        return 1
    fi

    rm -f "$queue_listing" "$graph_file"
}

collect_sbo_targets_from_queue_directory() {
    local queue_directory=$1
    local destination=$2
    local queue_listing
    local raw_targets
    local candidate
    local destination_directory
    local queue_file

    SBO_TARGET_SELECTION_ERROR=
    queue_listing=$(mktemp) || return 1
    raw_targets=$(mktemp) || {
        rm -f "$queue_listing"
        return 1
    }
    destination_directory=$(dirname -- "$destination")
    candidate=$(mktemp "$destination_directory/.sbo-targets.XXXXXX") || {
        rm -f "$queue_listing" "$raw_targets"
        SBO_TARGET_SELECTION_ERROR="cannot create a temporary SBo target set in: $destination_directory"
        return 1
    }

    if [ -d "$queue_directory" ]; then
        if ! find "$queue_directory" -type f -name '*.sqf' -print0 \
            | LC_ALL=C sort -z > "$queue_listing"; then
            rm -f "$queue_listing" "$raw_targets" "$candidate"
            SBO_TARGET_SELECTION_ERROR="cannot enumerate SBo queue files: $queue_directory"
            return 1
        fi

        while IFS= read -r -d '' queue_file; do
            if ! sbo_targets_from_queue_stream < "$queue_file" >> "$raw_targets"; then
                rm -f "$queue_listing" "$raw_targets" "$candidate"
                SBO_TARGET_SELECTION_ERROR="queue contains an invalid SBo target: $queue_file"
                return 1
            fi
        done < "$queue_listing"
    fi

    if ! normalize_sbo_target_names_from_stream < "$raw_targets" > "$candidate"; then
        rm -f "$queue_listing" "$raw_targets" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot normalize SBo targets from: $queue_directory"
        return 1
    fi

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$queue_listing" "$raw_targets" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot install selected SBo targets: $destination"
        return 1
    fi

    rm -f "$queue_listing" "$raw_targets"
}

collect_installed_sbo_targets() {
    local destination=$1
    local package_records
    local candidate
    local destination_directory

    SBO_TARGET_SELECTION_ERROR=
    package_records=$(mktemp) || return 1
    destination_directory=$(dirname -- "$destination")
    candidate=$(mktemp "$destination_directory/.sbo-targets.XXXXXX") || {
        rm -f "$package_records"
        SBO_TARGET_SELECTION_ERROR="cannot create a temporary SBo target set in: $destination_directory"
        return 1
    }

    if ! enumerate_package_database_records > "$package_records"; then
        rm -f "$package_records" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot enumerate installed package records: $PACKAGE_DATABASE"
        return 1
    fi

    if ! package_names_with_build_suffix_from_stream "$SBO_PACKAGE_TAG" < "$package_records" \
        | normalize_sbo_target_names_from_stream > "$candidate"; then
        rm -f "$package_records" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot normalize installed SBo package targets"
        return 1
    fi

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$package_records" "$candidate"
        SBO_TARGET_SELECTION_ERROR="cannot install selected SBo targets: $destination"
        return 1
    fi

    rm -f "$package_records"
}

merge_sbo_target_sets() {
    local destination=$1
    local destination_directory
    local candidate

    shift
    destination_directory=$(dirname -- "$destination")
    candidate=$(mktemp "$destination_directory/.sbo-targets.XXXXXX") || return 1

    if ! cat "$@" 2>/dev/null | normalize_sbo_target_names_from_stream > "$candidate"; then
        rm -f "$candidate"
        return 1
    fi

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$candidate"
        return 1
    fi
}

merge_ordered_sbo_queue_with_target_sets() {
    local destination=$1
    local ordered_queue=$2
    local option_records=$3
    local destination_directory
    local normalized_extra
    local normalized_options
    local candidate
    local source
    local line
    local target
    local options
    local record
    local extra
    local status
    local -A seen_targets=()
    local -A selected_options=()

    shift 3
    destination_directory=$(dirname -- "$destination")
    normalized_extra=$(mktemp) || return 1
    normalized_options=$(mktemp) || {
        rm -f "$normalized_extra"
        return 1
    }
    candidate=$(mktemp "$destination_directory/.sbo-final-queue.XXXXXX") || {
        rm -f "$normalized_extra" "$normalized_options"
        return 1
    }

    if [ "$#" -gt 0 ]; then
        if ! cat "$@" 2>/dev/null             | normalize_sbo_target_names_from_stream > "$normalized_extra"; then
            rm -f "$normalized_extra" "$normalized_options" "$candidate"
            return 1
        fi
    else
        : > "$normalized_extra"
    fi

    if [ -f "$option_records" ]; then
        if ! normalize_sbo_option_records_from_stream merge \
            < "$option_records" > "$normalized_options"; then
            rm -f "$normalized_extra" "$normalized_options" "$candidate"
            return 1
        fi
        while IFS= read -r record || [ -n "$record" ]; do
            [ -n "$record" ] || continue
            IFS=$'\t' read -r target options extra <<< "$record"
            [ -z "${extra:-}" ] || {
                rm -f "$normalized_extra" "$normalized_options" "$candidate"
                return 1
            }
            selected_options[$target]=$options
        done < "$normalized_options"
    fi

    for source in "$ordered_queue" "$normalized_extra"; do
        [ -f "$source" ] || continue
        while IFS= read -r line || [ -n "$line" ]; do
            [ -n "$line" ] || continue
            if sbo_queue_record_from_line "$line"; then
                target=$SBO_QUEUE_LINE_TARGET
            else
                status=$?
                rm -f "$normalized_extra" "$normalized_options" "$candidate"
                [ "$status" -eq 1 ] && return 1
                return "$status"
            fi
            if [ -n "${seen_targets[$target]+selected}" ]; then
                continue
            fi

            options=${selected_options[$target]:-$SBO_QUEUE_LINE_OPTIONS}
            if [ -n "$options" ]; then
                printf '%s | %s\n' "$target" "$options" >> "$candidate" || {
                    rm -f "$normalized_extra" "$normalized_options" "$candidate"
                    return 1
                }
            else
                printf '%s\n' "$target" >> "$candidate" || {
                    rm -f "$normalized_extra" "$normalized_options" "$candidate"
                    return 1
                }
            fi
            seen_targets[$target]=1
        done < "$source"
    done

    if ! mv -f -- "$candidate" "$destination"; then
        rm -f "$normalized_extra" "$normalized_options" "$candidate"
        return 1
    fi

    rm -f "$normalized_extra" "$normalized_options"
}

package_database_contains_name() {
    local expected_name=$1
    local record

    [ -d "$PACKAGE_DATABASE" ] || return 1

    while IFS= read -r record; do
        parse_slackware_package_record "$record" || continue
        [ "$SLACKWARE_PACKAGE_NAME" = "$expected_name" ] && return 0
    done < <(enumerate_package_database_records 2>/dev/null)

    return 1
}

# Optional module activation functions

detect_cinnamon_installation() {
    if command -v cinnamon >/dev/null 2>&1; then
        return 0
    fi

    if package_database_contains_name cinnamon; then
        return 0
    fi

    [ -d "$CSB_DIR_CONFIG/.git" ]
}

probe_flatpak_module() {
    FLATPAK_MODULE_RUN=0
    FLATPAK_MODULE_REASON=

    case "$FLATPAK_MODE" in
        disabled)
            FLATPAK_MODULE_STATE=disabled
            FLATPAK_MODULE_REASON="disabled by configuration"
            ;;
        enabled|auto)
            if command -v flatpak >/dev/null 2>&1; then
                FLATPAK_MODULE_STATE=available
                FLATPAK_MODULE_RUN=1
            else
                FLATPAK_MODULE_STATE=unavailable
                FLATPAK_MODULE_REASON="flatpak is not installed"
            fi
            ;;
    esac
}

probe_sbo_module() {
    SBO_MODULE_RUN=0
    SBO_MODULE_REASON=
    SBO_SBOPKG_AVAILABLE=0
    SBO_SQG_AVAILABLE=0

    if [ "$SBO_MODE" = disabled ]; then
        SBO_MODULE_STATE=disabled
        SBO_MODULE_REASON="disabled by configuration"
        return 0
    fi

    command -v sbopkg >/dev/null 2>&1 && SBO_SBOPKG_AVAILABLE=1
    command -v sqg >/dev/null 2>&1 && SBO_SQG_AVAILABLE=1

    if [ "$SBO_SBOPKG_AVAILABLE" -eq 1 ] && [ "$SBO_SQG_AVAILABLE" -eq 1 ]; then
        SBO_MODULE_STATE=available
        SBO_MODULE_RUN=1
    elif [ "$SBO_SBOPKG_AVAILABLE" -eq 0 ] && [ "$SBO_SQG_AVAILABLE" -eq 0 ]; then
        SBO_MODULE_STATE=unavailable
        SBO_MODULE_REASON="sbopkg and sqg are not installed"
    elif [ "$SBO_SBOPKG_AVAILABLE" -eq 0 ]; then
        SBO_MODULE_STATE=unavailable
        SBO_MODULE_REASON="sbopkg is not installed"
    else
        SBO_MODULE_STATE=unavailable
        SBO_MODULE_REASON="sqg is not installed"
    fi
}

probe_elf_module() {
    ELF_MODULE_RUN=0
    ELF_MODULE_REASON=
    ELF_READELF_AVAILABLE=0
    ELF_LDCONFIG_AVAILABLE=0

    if [ "$ELF_MODE" = disabled ]; then
        ELF_MODULE_STATE=disabled
        ELF_MODULE_REASON="disabled by configuration"
        return 0
    fi

    command -v readelf >/dev/null 2>&1 && ELF_READELF_AVAILABLE=1
    [ -x /sbin/ldconfig ] && ELF_LDCONFIG_AVAILABLE=1

    if [ "$ELF_READELF_AVAILABLE" -eq 1 ] && [ "$ELF_LDCONFIG_AVAILABLE" -eq 1 ]; then
        ELF_MODULE_STATE=available
        ELF_MODULE_RUN=1
    elif [ "$ELF_READELF_AVAILABLE" -eq 0 ] && [ "$ELF_LDCONFIG_AVAILABLE" -eq 0 ]; then
        ELF_MODULE_STATE=unavailable
        ELF_MODULE_REASON="readelf and /sbin/ldconfig are unavailable"
    elif [ "$ELF_READELF_AVAILABLE" -eq 0 ]; then
        ELF_MODULE_STATE=unavailable
        ELF_MODULE_REASON="readelf is unavailable"
    else
        ELF_MODULE_STATE=unavailable
        ELF_MODULE_REASON="/sbin/ldconfig is unavailable"
    fi
}

probe_cinnamon_module() {
    CINNAMON_MODULE_RUN=0
    CINNAMON_MODULE_REASON=
    CINNAMON_INSTALLED=0
    CINNAMON_GIT_AVAILABLE=0

    if [ "$CINNAMON_MODE" = disabled ]; then
        CINNAMON_MODULE_STATE=disabled
        CINNAMON_MODULE_REASON="disabled by configuration"
        return 0
    fi

    detect_cinnamon_installation && CINNAMON_INSTALLED=1
    command -v git >/dev/null 2>&1 && CINNAMON_GIT_AVAILABLE=1

    if [ "$CINNAMON_MODE" = enabled ]; then
        if [ "$CINNAMON_GIT_AVAILABLE" -eq 1 ]; then
            CINNAMON_MODULE_STATE=available
            CINNAMON_MODULE_RUN=1
        else
            CINNAMON_MODULE_STATE=unavailable
            CINNAMON_MODULE_REASON="git is unavailable"
        fi
    elif [ "$CINNAMON_INSTALLED" -eq 0 ]; then
        CINNAMON_MODULE_STATE=unavailable
        CINNAMON_MODULE_REASON="no Cinnamon installation or managed CSB checkout was detected"
    elif [ "$CINNAMON_GIT_AVAILABLE" -eq 0 ]; then
        CINNAMON_MODULE_STATE=unavailable
        CINNAMON_MODULE_REASON="git is unavailable"
    else
        CINNAMON_MODULE_STATE=available
        CINNAMON_MODULE_RUN=1
    fi
}

read_boot_image_from_cmdline() {
    local cmdline_file=$1
    local token
    local count=0

    BOOT_IMAGE_ASSIGNMENT=
    [ -f "$cmdline_file" ] && [ ! -L "$cmdline_file" ] && [ -r "$cmdline_file" ] || return 1

    while IFS= read -r token; do
        case "$token" in
            BOOT_IMAGE=*)
                BOOT_IMAGE_ASSIGNMENT=${token#BOOT_IMAGE=}
                count=$((count + 1))
                ;;
        esac
    done < <(tr ' ' '\n' < "$cmdline_file")

    [ "$count" -eq 1 ] || return 1
    case "$BOOT_IMAGE_ASSIGNMENT" in
        /boot/vmlinuz-generic) return 0 ;;
        /boot/vmlinuz-*)
            is_safe_kernel_version "${BOOT_IMAGE_ASSIGNMENT#/boot/vmlinuz-}"
            return
            ;;
        *) return 1 ;;
    esac
}

grub_config_references_kernel_path() {
    local config=$1
    local path=$2
    local alternate=

    [ -f "$config" ] && [ ! -L "$config" ] && [ -r "$config" ] || return 1
    case "$path" in
        /boot/*) alternate=${path#/boot} ;;
    esac

    awk -v expected="$path" -v alternate="$alternate" '
        ($1 == "linux" || $1 == "linuxefi") && ($2 == expected || (alternate != "" && $2 == alternate)) {
            found = 1
        }
        END { exit !found }
    ' "$config"
}

classify_direct_generic_boot_layout() {
    local package_database=$1
    local cmdline_file=$2
    local grub_config=$3
    local generic_link=$4
    local mkinitrd_config=$5
    local initrd_image=$6
    local modules_directory=$7
    local running_kernel=$8
    local package_database_resolved
    local resolved_kernel
    local kernel_basename
    local record
    local record_path
    local record_count=0

    BOOT_DIRECT_GENERIC_REASON=
    BOOT_DIRECT_GENERIC_KERNEL_PATH=
    BOOT_DIRECT_GENERIC_KERNEL_VERSION=
    BOOT_DIRECT_GENERIC_PACKAGE_RECORD=
    BOOT_DIRECT_GENERIC_BOOT_IMAGE=
    GENERIC_KERNEL_LINK=/boot/vmlinuz-generic

    is_safe_kernel_version "$running_kernel" || {
        BOOT_DIRECT_GENERIC_REASON="running kernel version is unsafe: $running_kernel"
        return 1
    }

    if [ -e "$mkinitrd_config" ] || [ -L "$mkinitrd_config" ] \
        || [ -e "$initrd_image" ] || [ -L "$initrd_image" ]; then
        BOOT_DIRECT_GENERIC_REASON="mkinitrd configuration or initrd is present"
        return 1
    fi

    [ -L "$generic_link" ] || {
        BOOT_DIRECT_GENERIC_REASON="generic kernel path is not a symbolic link: $generic_link"
        return 1
    }
    resolved_kernel=$(readlink -e -- "$generic_link" 2>/dev/null) || {
        BOOT_DIRECT_GENERIC_REASON="generic kernel link cannot be resolved: $generic_link"
        return 1
    }
    [ -f "$resolved_kernel" ] && [ ! -L "$resolved_kernel" ] && [ -r "$resolved_kernel" ] || {
        BOOT_DIRECT_GENERIC_REASON="resolved generic kernel is not a readable regular file: $resolved_kernel"
        return 1
    }
    kernel_basename=${resolved_kernel##*/}
    [ "$kernel_basename" = "vmlinuz-$running_kernel" ] || {
        BOOT_DIRECT_GENERIC_REASON="generic kernel link does not select the running version: $kernel_basename"
        return 1
    }

    [ -d "$modules_directory/$running_kernel" ] && [ ! -L "$modules_directory/$running_kernel" ] || {
        BOOT_DIRECT_GENERIC_REASON="running kernel module tree is missing or unsafe: $modules_directory/$running_kernel"
        return 1
    }

    package_database_resolved=$(readlink -e -- "$package_database" 2>/dev/null) || {
        BOOT_DIRECT_GENERIC_REASON="package database cannot be resolved: $package_database"
        return 1
    }
    [ -d "$package_database_resolved" ] && [ ! -L "$package_database_resolved" ] \
        && [ -r "$package_database_resolved" ] && [ -x "$package_database_resolved" ] || {
        BOOT_DIRECT_GENERIC_REASON="package database is not a safe readable directory: $package_database_resolved"
        return 1
    }

    while IFS= read -r record || [ -n "$record" ]; do
        parse_slackware_package_record "$record" || continue
        [ "$SLACKWARE_PACKAGE_NAME" = "$INITRD_KERNEL_PACKAGE" ] || continue
        record_count=$((record_count + 1))
        BOOT_DIRECT_GENERIC_PACKAGE_RECORD=$record
        BOOT_DIRECT_GENERIC_KERNEL_VERSION=$SLACKWARE_PACKAGE_VERSION
    done < <(find -H "$package_database" -maxdepth 1 -type f -name "${INITRD_KERNEL_PACKAGE}-*" -printf '%f\n' 2>/dev/null | LC_ALL=C sort)

    [ "$record_count" -eq 1 ] || {
        BOOT_DIRECT_GENERIC_REASON="expected one installed $INITRD_KERNEL_PACKAGE record, found $record_count"
        return 1
    }
    [ "$BOOT_DIRECT_GENERIC_KERNEL_VERSION" = "$running_kernel" ] || {
        BOOT_DIRECT_GENERIC_REASON="installed generic kernel does not match the running version"
        return 1
    }

    record_path="$package_database_resolved/$BOOT_DIRECT_GENERIC_PACKAGE_RECORD"
    [ -f "$record_path" ] && [ ! -L "$record_path" ] && [ -r "$record_path" ] || {
        BOOT_DIRECT_GENERIC_REASON="installed generic kernel record is missing or unsafe"
        return 1
    }
    grep -Fxq -- "boot/$kernel_basename" "$record_path" || {
        BOOT_DIRECT_GENERIC_REASON="installed generic kernel record does not own boot/$kernel_basename"
        return 1
    }
    awk -v prefix="lib/modules/$running_kernel/" 'index($0, prefix) == 1 { found=1 } END { exit !found }'         "$record_path" || {
        BOOT_DIRECT_GENERIC_REASON="installed generic kernel record does not own the running module tree"
        return 1
    }

    [ -f "$grub_config" ] && [ ! -L "$grub_config" ] && [ -r "$grub_config" ] || {
        BOOT_DIRECT_GENERIC_REASON="active GRUB configuration is missing or unsafe: $grub_config"
        return 1
    }
    read_boot_image_from_cmdline "$cmdline_file" || {
        BOOT_DIRECT_GENERIC_REASON="BOOT_IMAGE is missing, ambiguous, or unsafe"
        return 1
    }
    case "$BOOT_IMAGE_ASSIGNMENT" in
        /boot/vmlinuz-generic|"/boot/$kernel_basename") ;;
        *)
            BOOT_DIRECT_GENERIC_REASON="BOOT_IMAGE does not select the generic kernel path"
            return 1
            ;;
    esac
    grub_config_references_kernel_path "$grub_config" "$BOOT_IMAGE_ASSIGNMENT" || {
        BOOT_DIRECT_GENERIC_REASON="active GRUB configuration does not reference $BOOT_IMAGE_ASSIGNMENT"
        return 1
    }

    BOOT_DIRECT_GENERIC_KERNEL_PATH=$resolved_kernel
    BOOT_DIRECT_GENERIC_BOOT_IMAGE=$BOOT_IMAGE_ASSIGNMENT
    return 0
}

probe_direct_generic_boot_layout() {
    BOOT_DIRECT_GENERIC_AVAILABLE=0
    BOOT_DIRECT_GENERIC_REASON=

    classify_direct_generic_boot_layout \
        "$PACKAGE_DATABASE" "$BOOT_CMDLINE_FILE" "$GRUB_CONFIG" "$GENERIC_KERNEL_LINK" \
        "$MKINITRD_CONFIG" "$INITRD_DEFAULT_OUTPUT" "$KERNEL_MODULES_DIRECTORY" "$RUNNING_KERNEL" \
        || return 1

    if ! command -v grub-script-check >/dev/null 2>&1; then
        BOOT_DIRECT_GENERIC_REASON="grub-script-check is unavailable"
        return 1
    fi
    if ! grub-script-check "$GRUB_CONFIG" >/dev/null 2>&1; then
        BOOT_DIRECT_GENERIC_REASON="active GRUB configuration failed syntax validation"
        return 1
    fi

    BOOT_DIRECT_GENERIC_AVAILABLE=1
    return 0
}

probe_boot_module() {
    BOOT_MODULE_RUN=0
    BOOT_MODULE_REASON=
    BOOT_INITRD_AVAILABLE=0
    BOOT_GRUB_AVAILABLE=0
    BOOT_DIRECT_GENERIC_AVAILABLE=0
    BOOT_PREPARATION_LAYOUT=unknown
    BOOT_DIRECT_GENERIC_REASON=

    if [ "$BOOT_MODE" = disabled ]; then
        BOOT_MODULE_STATE=disabled
        BOOT_MODULE_REASON="disabled by configuration"
        return 0
    fi

    if command -v mkinitrd >/dev/null 2>&1 \
        && [ -f "$MKINITRD_CONFIG" ] && [ ! -L "$MKINITRD_CONFIG" ]; then
        BOOT_INITRD_AVAILABLE=1
    fi

    if command -v grub-mkconfig >/dev/null 2>&1 \
        && command -v grub-script-check >/dev/null 2>&1 \
        && [ -d "$GRUB_DIRECTORY" ] && [ ! -L "$GRUB_DIRECTORY" ]; then
        BOOT_GRUB_AVAILABLE=1
    fi

    if [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] && [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then
        BOOT_PREPARATION_LAYOUT=mkinitrd-managed
    elif [ "$BOOT_GRUB_AVAILABLE" -eq 1 ] && probe_direct_generic_boot_layout; then
        BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd
    fi

    if [ "$BOOT_MODE" = enabled ]; then
        case "$BOOT_PREPARATION_LAYOUT" in
            mkinitrd-managed|direct-generic-no-initrd)
                BOOT_MODULE_STATE=available
                BOOT_MODULE_RUN=1
                ;;
            *)
                BOOT_MODULE_STATE=unavailable
                if [ "$BOOT_GRUB_AVAILABLE" -eq 0 ] && [ "$BOOT_INITRD_AVAILABLE" -eq 0 ]; then
                    BOOT_MODULE_REASON="initrd and GRUB preparation requirements are missing"
                elif [ "$BOOT_GRUB_AVAILABLE" -eq 0 ]; then
                    BOOT_MODULE_REASON="GRUB preparation requirements are missing"
                elif [ -n "$BOOT_DIRECT_GENERIC_REASON" ]; then
                    BOOT_MODULE_REASON="neither managed initrd nor safe direct-generic boot is available: $BOOT_DIRECT_GENERIC_REASON"
                else
                    BOOT_MODULE_REASON="initrd preparation requirements are missing"
                fi
                ;;
        esac
    elif [ "$BOOT_PREPARATION_LAYOUT" = mkinitrd-managed ] \
        || [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ]; then
        BOOT_MODULE_STATE=available
        BOOT_MODULE_RUN=1
    elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then
        BOOT_MODULE_STATE=available
        BOOT_MODULE_RUN=1
        BOOT_PREPARATION_LAYOUT=partial
        if [ -n "$BOOT_DIRECT_GENERIC_REASON" ]; then
            BOOT_MODULE_REASON="auto mode detected a partial boot preparation path: $BOOT_DIRECT_GENERIC_REASON"
        else
            BOOT_MODULE_REASON="auto mode detected a partial boot preparation path"
        fi
    else
        BOOT_MODULE_STATE=unavailable
        BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"
    fi
}

probe_optional_modules() {
    probe_flatpak_module
    probe_sbo_module
    probe_elf_module
    probe_cinnamon_module
    probe_boot_module
}

print_optional_module_activation() {
    local module
    local mode
    local state
    local reason

    echo "[MODULES] Optional module activation"

    for module in flatpak sbo elf cinnamon boot; do
        case "$module" in
            flatpak)
                mode=$FLATPAK_MODE
                state=$FLATPAK_MODULE_STATE
                reason=$FLATPAK_MODULE_REASON
                ;;
            sbo)
                mode=$SBO_MODE
                state=$SBO_MODULE_STATE
                reason=$SBO_MODULE_REASON
                ;;
            elf)
                mode=$ELF_MODE
                state=$ELF_MODULE_STATE
                reason=$ELF_MODULE_REASON
                ;;
            cinnamon)
                mode=$CINNAMON_MODE
                state=$CINNAMON_MODULE_STATE
                reason=$CINNAMON_MODULE_REASON
                ;;
            boot)
                mode=$BOOT_MODE
                state=$BOOT_MODULE_STATE
                reason=$BOOT_MODULE_REASON
                ;;
        esac

        if [ "$state" = unavailable ] && [ "$mode" = enabled ]; then
            echo "  [ERROR] $module: mode=$mode, state=$state ($reason)"
        elif [ -n "$reason" ]; then
            echo "  [INFO] $module: mode=$mode, state=$state ($reason)"
        else
            echo "  [OK] $module: mode=$mode, state=$state"
        fi
    done
}

apply_boot_module_policy() {
    INITRD_REQUIRED=$INITRD_UPDATE
    GRUB_REQUIRED=$GRUB_UPDATE

    if [ "$INITRD_REQUIRED" -eq 0 ] && [ "$GRUB_REQUIRED" -eq 0 ]; then
        return 0
    fi

    if [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ]; then
        INITRD_REQUIRED=0
        INITRD_UPDATE=0
    fi

    case "$BOOT_MODE" in
        disabled)
            INITRD_UPDATE=0
            GRUB_UPDATE=0
            ;;
        enabled)
            ;;
        auto)
            if [ "$BOOT_PREPARATION_LAYOUT" != direct-generic-no-initrd ]; then
                [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || INITRD_UPDATE=0
            fi
            [ "$BOOT_GRUB_AVAILABLE" -eq 1 ] || GRUB_UPDATE=0
            ;;
    esac
}

# Runtime setup functions

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Este script requiere root" >&2
        return "$EXIT_PRIVILEGE_UNAVAILABLE"
    fi
}

acquire_instance_lock() {
    if ! command -v flock >/dev/null 2>&1; then
        echo "Error: flock is required to acquire the instance lock" >&2
        return "$EXIT_GENERAL_FAILURE"
    fi

    if ! exec 9>"$LOCKFILE"; then
        echo "Error: cannot open instance lock: $LOCKFILE" >&2
        return "$EXIT_GENERAL_FAILURE"
    fi

    # Keep the lock file open for the complete process lifetime.
    if ! flock -n 9; then
        exec 9>&-
        echo "Otra instancia de slack-update ya esta ejecutandose" >&2
        return "$EXIT_ALREADY_RUNNING"
    fi

    INSTANCE_LOCK_HELD=1
}

release_instance_lock() {
    if [ "${INSTANCE_LOCK_HELD:-0}" -eq 1 ]; then
        flock -u 9 2>/dev/null || true
        INSTANCE_LOCK_HELD=0
    fi

    exec 9>&-
}

initialize_runtime_state() {
    KERNEL_TRIGGER=0
    INITRD_UPDATE=0
    GRUB_UPDATE=0
    ABI_TRIGGER=0
    CRITICAL_UPDATED=()
    CINNAMON_TRIGGER=0   # 0=none, 1=needed, 2=ok, 3=fail
    CINNAMON_OK=0
    INITRD_OK=0
    INITRD_VALIDATION_STATUS=-1
    INITRD_VALIDATION_ERROR=
    INITRD_CONFIGURED_KERNEL_VERSION=
    INITRD_INSTALLED_KERNEL_VERSION=
    INITRD_INSTALLED_KERNEL_RECORD_COUNT=0
    INITRD_MODULES_PATH=
    INITRD_OUTPUT_PATH=
    GRUB_OK=0
    GRUB_COMMAND_ATTEMPTED=0
    GRUB_BLOCKED_BY_INITRD=0
    GRUB_BLOCK_REASON=
    GRUB_GENERATION_STATUS=-1
    GRUB_VALIDATION_STATUS=-1
    GRUB_VALIDATION_ERROR=
    GRUB_INSTALL_STATUS=-1
    GRUB_REPLACEMENT_ATTEMPTED=0
    GRUB_CONFIG_REPLACED=0
    GRUB_ACTIVE_CONFIG_EXISTED=0
    GRUB_ACTIVE_CONFIG_FINGERPRINT=
    GRUB_TEMP_CONFIG=
    GRUB_TEMP_CONFIG_OWNED=0
    GRUB_TEMP_DIRECTORY_CANONICAL=
    INITRD_REQUIRED=0
    GRUB_REQUIRED=0
    FLATPAK_MODULE_STATE=idle
    FLATPAK_MODULE_REASON=
    FLATPAK_MODULE_RUN=0
    SBO_MODULE_STATE=idle
    SBO_MODULE_REASON=
    SBO_MODULE_RUN=0
    SBO_SBOPKG_AVAILABLE=0
    SBO_SQG_AVAILABLE=0
    ELF_MODULE_STATE=idle
    ELF_MODULE_REASON=
    ELF_MODULE_RUN=0
    ELF_READELF_AVAILABLE=0
    ELF_LDCONFIG_AVAILABLE=0
    ELF_SCAN_STATUS=-1
    ELF_VERIFICATION_STATUS=-1
    ELF_LIBRARY_CACHE_RECORD_COUNT=0
    CINNAMON_MODULE_STATE=idle
    CINNAMON_MODULE_REASON=
    CINNAMON_MODULE_RUN=0
    CINNAMON_INSTALLED=0
    CINNAMON_GIT_AVAILABLE=0
    BOOT_MODULE_STATE=idle
    BOOT_MODULE_REASON=
    BOOT_MODULE_RUN=0
    BOOT_INITRD_AVAILABLE=0
    BOOT_GRUB_AVAILABLE=0
    BOOT_DIRECT_GENERIC_AVAILABLE=0
    BOOT_PREPARATION_LAYOUT=unknown
    BOOT_DIRECT_GENERIC_REASON=
    BOOT_DIRECT_GENERIC_KERNEL_PATH=
    BOOT_DIRECT_GENERIC_KERNEL_VERSION=
    BOOT_DIRECT_GENERIC_PACKAGE_RECORD=
    BOOT_DIRECT_GENERIC_BOOT_IMAGE=
    DIRECT_GENERIC_VALIDATION_STATUS=-1
    DIRECT_GENERIC_VALIDATION_ERROR=
    DIRECT_GENERIC_INSTALLED_KERNEL_VERSION=
    DIRECT_GENERIC_INSTALLED_KERNEL_RECORD_COUNT=0
    DIRECT_GENERIC_PACKAGE_RECORD=
    DIRECT_GENERIC_KERNEL_PATH=
    DIRECT_GENERIC_MODULES_PATH=
    TOTAL_EN_COLA=0
    TOTAL_CORE=0
    TOTAL_EXTRA=0
    CHECK_STATUS=0
    SLACKPKG_UPDATE_STATUS=-1
    SLACKPKG_INSTALL_NEW_STATUS=-1
    SLACKPKG_UPGRADE_ALL_STATUS=-1
    SLACKPKG_POSTINST_POLICY=defer
    PENDING_NEW_CONFIG_FILES_VALID=0
    PENDING_NEW_CONFIG_FILES_COUNT=0
    PENDING_NEW_CONFIG_FILES_ERROR=
    PENDING_NEW_CONFIG_FILES=
    FLATPAK_STATUS=-1
    SBOPKG_SYNC_STATUS=-1
    SQG_SYNC_STATUS=-1
    SBO_BUILD_STATUS=-1
    SBO_TARGET_SELECTION_STATUS=-1
    SBO_TARGET_SELECTION_ERROR=
    SBO_OPTION_RECORD_COUNT=0
    SBO_PERSONAL_QUEUE_DIR=
    SBO_QUEUE_SOURCE_DIR=
    SBO_PERSONAL_QUEUE_FILE_COUNT=0
    SBO_PERSONAL_QUEUE_SYMLINK_COUNT=0
    SBO_QUEUE_GENERATION_READY=0
    SBO_PRIVATE_SBOPKG_CONFIG=
    SBO_PRIVATE_LOCAL_SBOPKG_CONFIG=
    SBO_GENERATED_QUEUE_OWNED_PATH=
    SBO_GENERATED_QUEUE_OWNED_CANONICAL=
    PACKAGE_SNAPSHOT_BEFORE_VALID=0
    PACKAGE_SNAPSHOT_AFTER_VALID=0
    PACKAGE_SNAPSHOT_BEFORE_COUNT=0
    PACKAGE_SNAPSHOT_AFTER_COUNT=0
    PACKAGE_SNAPSHOT_BEFORE_ERROR=
    PACKAGE_SNAPSHOT_AFTER_ERROR=
    PACKAGE_SNAPSHOT_ERROR=
    PACKAGE_SNAPSHOT_RECORD_COUNT=0
    SECONDARY_MODULES_BLOCKED=0
    SECONDARY_MODULES_BLOCK_REASON=
    if ! STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ); then
        echo "Error: cannot record the runtime start time" >&2
        return 1
    fi
    FINISHED_AT=
    RUNTIME_TMPDIR=
    EVENT_SEQUENCE=0
}

initialize_runtime() {
    if ! initialize_runtime_state; then
        return 1
    fi

    WORKDIR=$WORKDIR_CONFIG
    LOGDIR=$LOGDIR_CONFIG

    if ! mkdir -p "$WORKDIR" "$LOGDIR"; then
        echo "Error: cannot create runtime directories: $WORKDIR, $LOGDIR" >&2
        return 1
    fi

    if ! DATE=$(date +%F-%H%M%S); then
        echo "Error: cannot create the runtime timestamp" >&2
        return 1
    fi
    LOG="$LOGDIR/run-$DATE.log"

    BROKEN="$WORKDIR/broken.txt"
    QUEUE_CORE="$WORKDIR/queue-core.sqf"
    QUEUE_EXTRA="$WORKDIR/queue-extra.sqf"
    SBO_OPTION_RECORDS="$WORKDIR/sbo-options.normalized"
    SBO_GENERATED_QUEUE_DIR="$WORKDIR/.sbo-generated-$DATE-$$"

    BEFORE_PKGS="$WORKDIR/packages.before"
    AFTER_PKGS="$WORKDIR/packages.after"
    PENDING_NEW_CONFIG_FILES="$WORKDIR/slackware-new-config-files.txt"

    # Temporary files are created here so the trap covers them immediately.
    if ! QUEUE_FINAL=$(mktemp); then
        echo "Error: cannot create the final queue temporary file" >&2
        return 1
    fi
    if ! BROKEN_NEW=$(mktemp); then
        echo "Error: cannot create the broken-object scan temporary file" >&2
        return 1
    fi
    if ! STILL_BROKEN=$(mktemp); then
        echo "Error: cannot create the broken-object verification temporary file" >&2
        return 1
    fi
    if ! BROKEN_ERRORS=$(mktemp); then
        echo "Error: cannot create the broken-object diagnostics temporary file" >&2
        return 1
    fi
    if ! ELF_LIBRARY_CACHE=$(mktemp); then
        echo "Error: cannot create the ELF library-cache temporary file" >&2
        return 1
    fi

    CSB_DIR=$CSB_DIR_CONFIG
}

initialize_dry_run_runtime() {
    local runtime_file

    if ! initialize_runtime_state; then
        return 1
    fi

    LOGDIR=$LOGDIR_CONFIG
    if ! mkdir -p "$LOGDIR"; then
        echo "Error: cannot create the dry-run log directory: $LOGDIR" >&2
        return 1
    fi

    if ! DATE=$(date +%F-%H%M%S); then
        echo "Error: cannot create the dry-run timestamp" >&2
        return 1
    fi
    LOG="$LOGDIR/run-$DATE.log"

    if ! RUNTIME_TMPDIR=$(mktemp -d /tmp/slack-update-dry-run.XXXXXX); then
        echo "Error: cannot create the private dry-run workspace" >&2
        return 1
    fi
    WORKDIR="$RUNTIME_TMPDIR"

    BROKEN="$WORKDIR/broken.txt"
    QUEUE_CORE="$WORKDIR/queue-core.sqf"
    QUEUE_EXTRA="$WORKDIR/queue-extra.sqf"
    SBO_OPTION_RECORDS="$WORKDIR/sbo-options.normalized"
    SBO_GENERATED_QUEUE_DIR="$WORKDIR/sbo-generated-queues"
    QUEUE_FINAL="$WORKDIR/queue-final.sqf"
    BROKEN_NEW="$WORKDIR/broken-new.txt"
    STILL_BROKEN="$WORKDIR/still-broken.txt"
    BROKEN_ERRORS="$WORKDIR/broken-errors.txt"
    ELF_LIBRARY_CACHE="$WORKDIR/elf-library-cache.txt"
    BEFORE_PKGS="$WORKDIR/packages.before"
    AFTER_PKGS="$WORKDIR/packages.after"
    PENDING_NEW_CONFIG_FILES="$WORKDIR/slackware-new-config-files.txt"
    ABI_CANDIDATES="$WORKDIR/abi-rebuild-candidates.txt"

    RUNTIME_TMPDIR="$WORKDIR"
    CSB_DIR=$CSB_DIR_CONFIG

    for runtime_file in \
        "$BROKEN" \
        "$QUEUE_CORE" \
        "$QUEUE_EXTRA" \
        "$SBO_OPTION_RECORDS" \
        "$BROKEN_ERRORS" \
        "$ELF_LIBRARY_CACHE"
    do
        if ! : > "$runtime_file"; then
            echo "Error: cannot initialize dry-run state file: $runtime_file" >&2
            return 1
        fi
    done
}

remove_owned_sbo_queue_workspace() {
    local owned_path=${SBO_GENERATED_QUEUE_OWNED_PATH:-}
    local owned_canonical=${SBO_GENERATED_QUEUE_OWNED_CANONICAL:-}
    local current_canonical

    [ -n "$owned_path" ] || return 0

    current_canonical=$(readlink -m -- "$owned_path") || return 1
    if [ -L "$owned_path" ] || [ "$current_canonical" != "$owned_canonical" ]; then
        SBO_GENERATED_QUEUE_OWNED_PATH=
        SBO_GENERATED_QUEUE_OWNED_CANONICAL=
        return 1
    fi

    rm -rf -- "$owned_path" || return 1
    SBO_GENERATED_QUEUE_OWNED_PATH=
    SBO_GENERATED_QUEUE_OWNED_CANONICAL=
}

cleanup() {
    rm -f "${QUEUE_FINAL:-}" "${BROKEN_NEW:-}" "${STILL_BROKEN:-}" \
        "${BROKEN_ERRORS:-}" "${ELF_LIBRARY_CACHE:-}" 2>/dev/null || true

    discard_owned_grub_temporary_config 2>/dev/null || true
    remove_owned_sbo_queue_workspace 2>/dev/null || true

    if [ -n "${RUNTIME_TMPDIR:-}" ]; then
        rm -rf -- "$RUNTIME_TMPDIR" 2>/dev/null || true
    fi

    release_instance_lock
}

handle_interruption_signal() {
    local signal_name=$1
    local signal_number=$2
    local exit_code=$((128 + signal_number))

    # Prevent recursive or duplicate cleanup while terminating from a signal.
    trap - EXIT HUP INT TERM
    printf 'Interrupted by SIG%s; cleaning up and exiting with status %d\n' \
        "$signal_name" "$exit_code" >&2
    cleanup
    exit "$exit_code"
}

install_runtime_traps() {
    trap cleanup EXIT
    trap 'handle_interruption_signal HUP 1' HUP
    trap 'handle_interruption_signal INT 2' INT
    trap 'handle_interruption_signal TERM 15' TERM
}

rotate_logs() {
    # Rotacion de logs — conservar solo los ultimos 30 dias.
    # FIX #10: La rotacion se ejecuta ANTES de abrir el log de esta ejecucion,
    # por lo que nunca puede borrar el fichero run-$DATE.log actual.
    find "$LOGDIR" -name 'run-*.log' -mtime +"$LOG_RETENTION_DAYS" -delete 2>/dev/null || true
}

configure_logging() {
    local logging_command

    for logging_command in sed tee; do
        if ! command -v "$logging_command" >/dev/null 2>&1; then
            echo "Error: required logging command is unavailable: $logging_command" >&2
            return 1
        fi
    done

    if ! : >> "$LOG"; then
        echo "Error: cannot open the runtime log for writing: $LOG" >&2
        return 1
    fi

    # Redirigir log filtrando codigos ANSI
    # FIX #10: Se eliminan emojis del log para evitar problemas de encoding en cron.
    # La salida de consola (si se ejecuta interactivamente) los mostrara igualmente
    # porque el tee escribe a stdout antes del filtro de ANSI.
    if [ "$JSON_OUTPUT" -eq 1 ] || [ "$EVENTS_OUTPUT" -eq 1 ]; then
        # Keep stdout reserved for machine-readable output.
        if ! exec 3>&1; then
            echo "Error: cannot reserve the machine-readable output descriptor" >&2
            return 1
        fi
        exec > >(sed 's/\x1b\[[0-9;]*[mGKHJ]//g; s/\r//' | tee -a "$LOG" >&2) 2>&1
    else
        exec > >(sed 's/\x1b\[[0-9;]*[mGKHJ]//g; s/\r//' | tee -a "$LOG") 2>&1
    fi
}

print_start_banner() {
    echo "================================================"
    echo "START: $(date)"
    echo "================================================"
}

# Check workflow functions

check_slackware_updates() {
    echo "[CHECK] Slackware updates"

    if ! command -v slackpkg >/dev/null 2>&1; then
        CHECK_STATUS=127
        echo "  [ERROR] slackpkg is not available"
        return 1
    fi

    slackpkg -batch=on -default_answer=n check-updates
    CHECK_STATUS=$?

    case "$CHECK_STATUS" in
        0|100)
            ;;
        *)
            echo "  [ERROR] slackpkg check-updates failed with exit code $CHECK_STATUS"
            return 1
            ;;
    esac
}

print_check_summary() {
    echo
    echo "=============================="
    echo "CHECK SUMMARY"
    echo "=============================="
    echo

    case "$CHECK_STATUS" in
        0)
            echo "[OK] No Slackware repository updates were reported."
            ;;
        100)
            echo "[UPDATES] Slackware repository updates are available."
            ;;
        *)
            echo "[ERROR] The Slackware update check did not complete successfully."
            ;;
    esac

    echo
    echo "[INFO] No packages or optional components were modified."
    echo "[CONFIG] Configuration: $CONFIG_FILE"
    echo "[LOG] Full log: $LOG"
    echo "[END] Finished: $(date)"
}

run_check_workflow() {
    local result=0
    local state=success

    emit_module_started_event slackware "Slackware update check started"
    emit_action_started_event slackware check_updates "Checking Slackware repository updates"

    check_slackware_updates || result=$?

    if [ "$result" -ne 0 ]; then
        state=failed
    fi

    emit_action_completed_event slackware check_updates "$state" \
        "Slackware repository update check completed" "$CHECK_STATUS"
    emit_module_completed_event slackware "$state" \
        "Slackware update check completed" "$CHECK_STATUS"

    print_check_summary

    return "$result"
}

# Dry-run workflow functions

inspect_dry_run_environment() {
    PLAN_FLATPAK_AVAILABLE=0
    PLAN_SBOPKG_AVAILABLE=0
    PLAN_SQG_AVAILABLE=0
    PLAN_READELF_AVAILABLE=0
    PLAN_MKINITRD_AVAILABLE=0
    PLAN_GRUB_AVAILABLE=0
    PLAN_GRUB_VALIDATOR_AVAILABLE=0
    PLAN_MKINITRD_CONFIGURED=0
    PLAN_GRUB_CONFIGURED=0
    PLAN_CINNAMON_REPOSITORY=0
    PLAN_CINNAMON_BUILDER=0

    if [ "$FLATPAK_MODE" != disabled ]; then
        command -v flatpak >/dev/null 2>&1 && PLAN_FLATPAK_AVAILABLE=1
    fi

    if [ "$SBO_MODE" != disabled ]; then
        command -v sbopkg >/dev/null 2>&1 && PLAN_SBOPKG_AVAILABLE=1
        command -v sqg >/dev/null 2>&1 && PLAN_SQG_AVAILABLE=1
    fi

    if [ "$ELF_MODE" != disabled ]; then
        command -v readelf >/dev/null 2>&1 && PLAN_READELF_AVAILABLE=1
    fi

    if [ "$BOOT_MODE" != disabled ]; then
        command -v mkinitrd >/dev/null 2>&1 && PLAN_MKINITRD_AVAILABLE=1
        command -v grub-mkconfig >/dev/null 2>&1 && PLAN_GRUB_AVAILABLE=1
        command -v grub-script-check >/dev/null 2>&1 && PLAN_GRUB_VALIDATOR_AVAILABLE=1

        if [ -f "$MKINITRD_CONFIG" ]; then
            PLAN_MKINITRD_CONFIGURED=1
        fi

        [ -d "$GRUB_DIRECTORY" ] && PLAN_GRUB_CONFIGURED=1
    fi

    if [ "$CINNAMON_MODE" != disabled ]; then
        [ -d "$CSB_DIR/.git" ] && PLAN_CINNAMON_REPOSITORY=1
        [ -x "$CSB_DIR/$CSB_BUILDER" ] && PLAN_CINNAMON_BUILDER=1
    fi
}

inspect_current_sbo_queues() {
    echo "[PLAN] Inspecting current SBo queues"

    if ! resolve_sbo_personal_queue_directory; then
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi
    SBO_QUEUE_SOURCE_DIR=$SBO_PERSONAL_QUEUE_DIR

    if ! collect_ordered_sbo_targets_from_queue_directory "$SBO_QUEUE_SOURCE_DIR" "$QUEUE_CORE"; then
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi
    if ! collect_sbo_option_records_from_sources \
        "$SBO_QUEUE_SOURCE_DIR" "$SBO_OPTIONS_FILE" "$SBO_OPTION_RECORDS"; then
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi

    TOTAL_CORE=$(wc -l < "$QUEUE_CORE")
    echo "  Current local queue targets: $TOTAL_CORE"
    echo "  Preserved build-option records: $SBO_OPTION_RECORD_COUNT"
}

collect_installed_sbo_candidates() {
    if ! collect_installed_sbo_targets "$ABI_CANDIDATES"; then
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi

    PLAN_ABI_SBO_COUNT=$(wc -l < "$ABI_CANDIDATES")
}

inspect_current_elf_state() {
    echo "[PLAN] Inspecting current ELF dependency state"

    if [ "$PLAN_READELF_AVAILABLE" -eq 0 ]; then
        : > "$BROKEN"
        : > "$QUEUE_EXTRA"
        PLAN_BROKEN_COUNT=0
        PLAN_BROKEN_SBO_COUNT=0
        echo "  readelf is unavailable; the current ELF state cannot be inspected"
        return 0
    fi

    if ! detect_broken_elf_objects; then
        : > "$BROKEN"
        : > "$QUEUE_EXTRA"
        PLAN_BROKEN_COUNT=0
        PLAN_BROKEN_SBO_COUNT=0
        return 1
    fi
    map_broken_objects_to_sbo_packages || return 1

    PLAN_BROKEN_COUNT=$(wc -l < "$BROKEN")
    PLAN_BROKEN_SBO_COUNT=$(wc -l < "$QUEUE_EXTRA")
}

print_plan_file() {
    local path=$1

    if [ -s "$path" ]; then
        sed 's/^/      - /' "$path"
    else
        echo "      (none)"
    fi
}

print_sbo_option_records() {
    local path=$1
    local target
    local options

    if [ -s "$path" ]; then
        while IFS=$'	' read -r target options; do
            printf '      - %s | %s
' "$target" "$options"
        done < "$path"
    else
        echo "      (none)"
    fi
}

print_dry_run_plan() {
    echo
    echo "=============================="
    echo "DRY-RUN PLAN"
    echo "=============================="
    echo

    echo "[1] Slackware"
    case "$CHECK_STATUS" in
        0)
            echo "  Repository status: no updates reported since the last slackpkg update."
            ;;
        100)
            echo "  Repository status: updates are available."
            ;;
        *)
            echo "  Repository status: unavailable because the check failed."
            ;;
    esac
    echo "  Planned commands:"
    echo "      slackpkg -batch=on -default_answer=y update"
    if [ "$SLACKWARE_INSTALL_NEW" = true ]; then
        echo "      slackpkg -batch=on -default_answer=y -postinst=off install-new"
    else
        echo "      (install-new disabled by configuration)"
    fi
    if [ "$SLACKWARE_UPGRADE_ALL" = true ]; then
        echo "      slackpkg -batch=on -default_answer=y -postinst=off upgrade-all"
    else
        echo "      (upgrade-all disabled by configuration)"
    fi
    echo "  Exact changed packages and all package-derived triggers remain conditional"
    echo "  until the package metadata is refreshed and the apply snapshots are compared."
    echo

    echo "[2] Flatpak"
    echo "  Mode: $FLATPAK_MODE"
    echo "  Activation state: $FLATPAK_MODULE_STATE"
    if [ "$FLATPAK_MODULE_RUN" -eq 1 ]; then
        echo "  Planned command: flatpak update -y --noninteractive"
    elif [ "$FLATPAK_MODULE_STATE" = disabled ]; then
        echo "  The module is disabled; no Flatpak command would run."
    elif [ "$FLATPAK_MODE" = enabled ]; then
        echo "  [ERROR] Enabled module requirements are missing: $FLATPAK_MODULE_REASON"
    else
        echo "  Auto mode found no applicable Flatpak installation: $FLATPAK_MODULE_REASON"
    fi
    echo

    echo "[3] ABI and kernel triggers"
    echo "  After the Slackware commands, the before/after package snapshots would be"
    echo "  compared for ABI-sensitive and kernel package changes."
    echo "  Installed SBo packages eligible for an ABI-triggered rebuild: $PLAN_ABI_SBO_COUNT"
    print_plan_file "$ABI_CANDIDATES"
    echo "  Kernel image or module changes would schedule boot preparation."
    echo "  Managed-initrd hosts regenerate initrd before GRUB; validated direct-generic hosts regenerate GRUB without initrd."
    echo "  A kernel-headers-only change would only emit the external-module warning."
    echo

    echo "[4] SBo"
    echo "  Mode: $SBO_MODE"
    echo "  Activation state: $SBO_MODULE_STATE"
    if [ "$SBO_MODULE_RUN" -eq 1 ]; then
        echo "  Planned repository commands: sbopkg -r, then sqg -a in a private queue workspace"
        echo "  Personal queue directory (read-only): $SBODIR"
        echo "  Current local queue targets: $TOTAL_CORE"
        print_plan_file "$QUEUE_CORE"
        echo "  Persistent build-options file: $SBO_OPTIONS_FILE"
        echo "  Preserved build-option records: $SBO_OPTION_RECORD_COUNT"
        print_sbo_option_records "$SBO_OPTION_RECORDS"
        echo "  Current broken-ELF SBo targets: $PLAN_BROKEN_SBO_COUNT"
        print_plan_file "$QUEUE_EXTRA"
        echo "  Apply would copy regular personal .sqf files into an isolated workspace,"
        echo "  run sqg only there, preserve dependency constraints from the resulting queues,"
        echo "  then append unique ABI-triggered and broken-ELF targets deterministically."
    elif [ "$SBO_MODULE_STATE" = disabled ]; then
        echo "  The module is disabled; repository synchronization and builds would not run."
    elif [ "$SBO_MODE" = enabled ]; then
        echo "  [ERROR] Enabled module requirements are missing: $SBO_MODULE_REASON"
    else
        echo "  Auto mode found no applicable SBo toolchain: $SBO_MODULE_REASON"
    fi
    echo

    echo "[5] ELF diagnostics"
    echo "  Mode: $ELF_MODE"
    echo "  Activation state: $ELF_MODULE_STATE"
    if [ "$ELF_MODULE_RUN" -eq 1 ]; then
        echo "  Current broken ELF objects detected statically: $PLAN_BROKEN_COUNT"
        print_plan_file "$BROKEN"
        echo "  The apply workflow would repeat this scan after Slackware changes."
    elif [ "$ELF_MODULE_STATE" = disabled ]; then
        echo "  The module is disabled; no ELF object would be inspected."
    elif [ "$ELF_MODE" = enabled ]; then
        echo "  [ERROR] Enabled module requirements are missing: $ELF_MODULE_REASON"
    else
        echo "  Auto mode found no applicable ELF diagnostics backend: $ELF_MODULE_REASON"
    fi
    echo

    echo "[6] Cinnamon"
    echo "  Mode: $CINNAMON_MODE"
    echo "  Activation state: $CINNAMON_MODULE_STATE"
    if [ "$CINNAMON_MODULE_RUN" -eq 1 ]; then
        echo "  This phase remains conditional on a graphical ABI trigger."
        if [ "$PLAN_CINNAMON_REPOSITORY" -eq 1 ]; then
            echo "  Existing CSB repository: $CSB_DIR"
            echo "  Planned repository action: git fetch followed by reset to origin/$CSB_BRANCH"
        else
            echo "  No existing CSB checkout was found; apply would attempt to clone it when triggered."
        fi
        if [ "$PLAN_CINNAMON_BUILDER" -eq 1 ]; then
            echo "  Cinnamon build command: $CSB_DIR/$CSB_BUILDER"
        else
            echo "  The Cinnamon build script is not currently executable or present."
        fi
    elif [ "$CINNAMON_MODULE_STATE" = disabled ]; then
        echo "  The module is disabled; graphical ABI changes would not trigger a rebuild."
    elif [ "$CINNAMON_MODE" = enabled ]; then
        echo "  [ERROR] Enabled module requirements are missing: $CINNAMON_MODULE_REASON"
    else
        echo "  Auto mode found no applicable Cinnamon installation: $CINNAMON_MODULE_REASON"
    fi
    echo

    echo "[7] Boot preparation"
    echo "  Mode: $BOOT_MODE"
    echo "  Activation state: $BOOT_MODULE_STATE"
    echo "  Preparation layout: $BOOT_PREPARATION_LAYOUT"
    if [ "$BOOT_MODULE_RUN" -eq 1 ]; then
        echo "  These actions remain conditional on kernel-generic, kernel-huge, or kernel-modules changes."
        if [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ]; then
            echo "  Direct generic policy: no initrd is required or generated."
            echo "  Before GRUB generation, apply must validate the new package-owned vmlinuz-VERSION symlink target and module tree."
        elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ]; then
            echo "  Planned initrd command: mkinitrd -F"
            echo "  Installed kernel source: validated post-update $INITRD_KERNEL_PACKAGE package record"
            echo "  Required modules path: $KERNEL_MODULES_DIRECTORY/<installed-version>"
            echo "  KERNEL_VERSION must match the installed package before mkinitrd can run."
        elif [ "$BOOT_MODE" = enabled ]; then
            echo "  [ERROR] initrd requirements are missing and would fail if triggered."
        else
            echo "  Auto mode would omit initrd preparation because it is not applicable."
        fi
        if [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then
            echo "  Planned GRUB generation: grub-mkconfig writes an owner-only temporary file beside $GRUB_CONFIG"
            echo "  Planned GRUB validation: grub-script-check <temporary-config>"
            echo "  Planned GRUB installation: atomic replacement of $GRUB_CONFIG after validation"
        elif [ "$BOOT_MODE" = enabled ]; then
            echo "  [ERROR] GRUB requirements are missing and would fail if triggered."
        else
            echo "  Auto mode would omit GRUB because no supported GRUB installation was detected."
        fi
    elif [ "$BOOT_MODULE_STATE" = disabled ]; then
        echo "  The module is disabled; kernel changes would not run initrd or GRUB actions."
    elif [ "$BOOT_MODE" = enabled ]; then
        echo "  [ERROR] Enabled module requirements are missing: $BOOT_MODULE_REASON"
    else
        echo "  Auto mode found no applicable boot preparation path: $BOOT_MODULE_REASON"
    fi
    echo

    echo "[DRY-RUN] No update, synchronization, build, installation, initrd, or bootloader"
    echo "          command was executed. Only state inspection and normal logging occurred."
    echo "[CONFIG] Configuration: $CONFIG_FILE"
    echo "[LOG] Full log: $LOG"
    echo "[END] Finished: $(date)"
}

run_dry_run_workflow() {
    local result=0
    local slackware_state=success
    local sbo_state=success
    local elf_state=success

    emit_module_started_event slackware "Slackware planning probe started"
    emit_action_started_event slackware check_updates "Checking Slackware repository updates"
    check_slackware_updates || result=$?
    if [ "$result" -ne 0 ]; then
        slackware_state=failed
    fi
    emit_action_completed_event slackware check_updates "$slackware_state" \
        "Slackware repository probe completed" "$CHECK_STATUS"
    emit_module_completed_event slackware "$slackware_state" \
        "Slackware planning probe completed" "$CHECK_STATUS"

    emit_module_started_event core "Local environment inspection started"
    emit_action_started_event core inspect_environment "Inspecting optional tools and boot configuration"
    inspect_dry_run_environment
    probe_optional_modules
    print_optional_module_activation
    emit_action_completed_event core inspect_environment success \
        "Optional tools, module modes, and boot configuration inspected" 0
    emit_module_completed_event core success "Local environment inspection completed" 0

    emit_module_started_event sbo "SBo planning inspection started"
    if [ "$SBO_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event sbo inspect_queues "Inspecting current SBo queues"
        SBO_TARGET_SELECTION_STATUS=0
        if inspect_current_sbo_queues && collect_installed_sbo_candidates; then
            emit_action_completed_event sbo inspect_queues success \
                "Current SBo queues and ABI candidates inspected" 0
            sbo_state=success
        else
            SBO_TARGET_SELECTION_STATUS=1
            sbo_state=failed
            result=1
            : > "$QUEUE_CORE"
            [ -n "${SBO_OPTION_RECORDS:-}" ] && : > "$SBO_OPTION_RECORDS"
            : > "$ABI_CANDIDATES"
            TOTAL_CORE=0
            SBO_OPTION_RECORD_COUNT=0
            PLAN_ABI_SBO_COUNT=0
            emit_action_completed_event sbo inspect_queues failed \
                "SBo target selection failed: $SBO_TARGET_SELECTION_ERROR" 1
        fi
    else
        sbo_state=$SBO_MODULE_STATE
        action_exit=0
        SBODIR=$SBO_QUEUE_DIR_FALLBACK
        : > "$QUEUE_CORE"
        : > "$QUEUE_EXTRA"
        [ -n "${SBO_OPTION_RECORDS:-}" ] && : > "$SBO_OPTION_RECORDS"
        : > "$ABI_CANDIDATES"
        TOTAL_CORE=0
        SBO_OPTION_RECORD_COUNT=0
        PLAN_ABI_SBO_COUNT=0
        PLAN_BROKEN_SBO_COUNT=0
        emit_action_completed_event sbo inspect_queues "$sbo_state" \
            "SBo queue inspection was not applicable: $SBO_MODULE_REASON" 0
    fi
    emit_module_completed_event sbo "$sbo_state" "SBo planning inspection completed" 0

    emit_module_started_event elf "ELF dependency inspection started"
    if [ "$ELF_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event elf scan_dependencies "Scanning current ELF dependencies"
        if inspect_current_elf_state; then
            if [ "$PLAN_BROKEN_COUNT" -gt 0 ]; then
                elf_state=warning
            fi
            emit_action_completed_event elf scan_dependencies "$elf_state" \
                "Current ELF dependency inspection completed" 0
        else
            elf_state=failed
            result=1
            emit_action_completed_event elf scan_dependencies failed \
                "Static ELF dependency inspection failed" 1
        fi
    else
        elf_state=$ELF_MODULE_STATE
        : > "$BROKEN"
        PLAN_BROKEN_COUNT=0
        emit_action_completed_event elf scan_dependencies "$elf_state" \
            "ELF dependency inspection was not applicable: $ELF_MODULE_REASON" 0
    fi
    emit_module_completed_event elf "$elf_state" "ELF dependency inspection completed" 0

    emit_action_started_event core render_plan "Rendering dry-run plan"
    print_dry_run_plan
    emit_action_completed_event core render_plan success "Dry-run plan rendered" 0

    return "$result"
}

# Update workflow functions

capture_package_snapshot_before() {
    # Capture a validated baseline and remove any stale post-update snapshot.
    PACKAGE_SNAPSHOT_BEFORE_VALID=0
    PACKAGE_SNAPSHOT_BEFORE_COUNT=0
    PACKAGE_SNAPSHOT_BEFORE_ERROR=

    if ! rm -f "$BEFORE_PKGS" "$AFTER_PKGS"; then
        PACKAGE_SNAPSHOT_BEFORE_ERROR="cannot remove stale package snapshots"
        return 1
    fi

    if ! capture_validated_package_snapshot "$BEFORE_PKGS"; then
        PACKAGE_SNAPSHOT_BEFORE_ERROR=$PACKAGE_SNAPSHOT_ERROR
        return 1
    fi

    PACKAGE_SNAPSHOT_BEFORE_VALID=1
    PACKAGE_SNAPSHOT_BEFORE_COUNT=$PACKAGE_SNAPSHOT_RECORD_COUNT
}

slackpkg_apply_action_failed() {
    local action=$1
    local status=$2

    # slackpkg 15.0 uses status 20 when install-new or upgrade-all has no
    # matching packages. Preserve that raw status for reporting, but treat the
    # no-op as a successful package action.
    case "$action:$status" in
        update:0|install-new:0|install-new:20|upgrade-all:0|upgrade-all:20)
            return 1
            ;;
        *:-1)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

capture_pending_new_config_files() {
    PENDING_NEW_CONFIG_FILES_VALID=0
    PENDING_NEW_CONFIG_FILES_COUNT=0
    PENDING_NEW_CONFIG_FILES_ERROR=

    if [ -z "${PENDING_NEW_CONFIG_FILES:-}" ]; then
        PENDING_NEW_CONFIG_FILES_ERROR="pending .new configuration-file path is not initialized"
        return 1
    fi
    if ! : > "$PENDING_NEW_CONFIG_FILES"; then
        PENDING_NEW_CONFIG_FILES_ERROR="cannot initialize pending .new configuration-file list"
        return 1
    fi
    if ! find -H /etc -xdev -type f -name '*.new' -print \
        | LC_ALL=C sort > "$PENDING_NEW_CONFIG_FILES"; then
        PENDING_NEW_CONFIG_FILES_ERROR="cannot enumerate pending .new configuration files under /etc"
        return 1
    fi

    PENDING_NEW_CONFIG_FILES_COUNT=$(wc -l < "$PENDING_NEW_CONFIG_FILES")
    PENDING_NEW_CONFIG_FILES_VALID=1
}

update_slackware_system() {
    # ---------------------------
    # [1] UPDATE SYSTEM
    # ---------------------------

    echo "[1] Slackware update"

    SLACKPKG_UPDATE_STATUS=0
    slackpkg -batch=on -default_answer=y update || SLACKPKG_UPDATE_STATUS=$?

    if [ "$SLACKWARE_INSTALL_NEW" = true ]; then
        SLACKPKG_INSTALL_NEW_STATUS=0
        slackpkg -batch=on -default_answer=y -postinst=off install-new || SLACKPKG_INSTALL_NEW_STATUS=$?
    else
        echo "  install-new disabled by configuration"
    fi

    if [ "$SLACKWARE_UPGRADE_ALL" = true ]; then
        SLACKPKG_UPGRADE_ALL_STATUS=0
        slackpkg -batch=on -default_answer=y -postinst=off upgrade-all || SLACKPKG_UPGRADE_ALL_STATUS=$?
    else
        echo "  upgrade-all disabled by configuration"
    fi

    if ! capture_pending_new_config_files; then
        echo "  [WARN] Pending .new configuration files could not be enumerated: $PENDING_NEW_CONFIG_FILES_ERROR"
    elif [ "$PENDING_NEW_CONFIG_FILES_COUNT" -gt 0 ]; then
        echo "  [WARN] $PENDING_NEW_CONFIG_FILES_COUNT pending .new configuration file(s) require manual review"
    fi
}

capture_package_snapshot_after() {
    # Capture and validate the package state produced by Slackware operations.
    PACKAGE_SNAPSHOT_AFTER_VALID=0
    PACKAGE_SNAPSHOT_AFTER_COUNT=0
    PACKAGE_SNAPSHOT_AFTER_ERROR=

    if ! rm -f "$AFTER_PKGS"; then
        PACKAGE_SNAPSHOT_AFTER_ERROR="cannot remove stale post-update package snapshot"
        return 1
    fi

    if ! capture_validated_package_snapshot "$AFTER_PKGS"; then
        PACKAGE_SNAPSHOT_AFTER_ERROR=$PACKAGE_SNAPSHOT_ERROR
        return 1
    fi

    PACKAGE_SNAPSHOT_AFTER_VALID=1
    PACKAGE_SNAPSHOT_AFTER_COUNT=$PACKAGE_SNAPSHOT_RECORD_COUNT
}

block_secondary_modules_after_partial_slackware_update() {
    SECONDARY_MODULES_BLOCKED=1
    SECONDARY_MODULES_BLOCK_REASON='Slackware package operations did not complete successfully'

    FLATPAK_MODULE_STATE=blocked
    FLATPAK_MODULE_REASON=$SECONDARY_MODULES_BLOCK_REASON
    FLATPAK_MODULE_RUN=0
    SBO_MODULE_STATE=blocked
    SBO_MODULE_REASON=$SECONDARY_MODULES_BLOCK_REASON
    SBO_MODULE_RUN=0
    ELF_MODULE_STATE=blocked
    ELF_MODULE_REASON=$SECONDARY_MODULES_BLOCK_REASON
    ELF_MODULE_RUN=0
    CINNAMON_MODULE_STATE=blocked
    CINNAMON_MODULE_REASON=$SECONDARY_MODULES_BLOCK_REASON
    CINNAMON_MODULE_RUN=0
    BOOT_MODULE_STATE=blocked
    BOOT_MODULE_REASON=$SECONDARY_MODULES_BLOCK_REASON
    BOOT_MODULE_RUN=0
}

update_flatpak() {
    # ---------------------------
    # [2] FLATPAK
    # ---------------------------

    echo "[2] Flatpak update"

    if command -v flatpak >/dev/null 2>&1; then
        FLATPAK_STATUS=0
        flatpak update -y --noninteractive || FLATPAK_STATUS=$?
    else
        echo "  Flatpak no instalado, omitiendo"
    fi
}

detect_abi_changes() {
    # ---------------------------
    # [3] ABI + CINNAMON DETECTION
    # ---------------------------

    echo "[3] Detectando cambios ABI"

    CRITICAL_UPDATED=()

    for p in "${ABI_PACKAGES[@]}"; do

        BEFORE=$(package_snapshot_records_for_name "$BEFORE_PKGS" "$p")
        AFTER=$(package_snapshot_records_for_name "$AFTER_PKGS" "$p")

        if [ "$BEFORE" != "$AFTER" ]; then

            echo "  ABI change: $p"
            ABI_TRIGGER=1

            # Critical package changes require a restart to become fully effective.
            if array_contains "$p" "${CRITICAL_PACKAGES[@]}"; then
                CRITICAL_UPDATED+=("$p")
            fi

            if array_contains "$p" "${CINNAMON_ABI[@]}"; then
                if [ "$CINNAMON_MODULE_RUN" -eq 1 ]; then
                    CINNAMON_TRIGGER=1
                    echo "   -> Cinnamon rebuild required"
                else
                    echo "   -> Cinnamon trigger ignored: mode=$CINNAMON_MODE, state=$CINNAMON_MODULE_STATE"
                fi
            fi

        fi

    done

    [ "$ABI_TRIGGER"      -eq 0 ] && echo "  Sin cambios ABI relevantes"
    [ "$CINNAMON_TRIGGER" -eq 0 ] && echo "  Sin cambios en pila grafica de Cinnamon"

    if [ "${#CRITICAL_UPDATED[@]}" -gt 0 ]; then
        echo "  [WARN] Paquetes criticos actualizados que requieren reinicio: ${CRITICAL_UPDATED[*]}"
    fi
}

detect_kernel_changes() {
    # ---------------------------
    # [4] KERNEL DETECTION
    # ---------------------------

    echo "[4] Detectando cambios en kernel"

    # Kernel package groups are loaded from the validated configuration.

    for p in "${KERNEL_PACKAGES[@]}"; do

        BEFORE=$(package_snapshot_records_for_name "$BEFORE_PKGS" "$p")
        AFTER=$(package_snapshot_records_for_name "$AFTER_PKGS" "$p")

        if [ "$BEFORE" != "$AFTER" ]; then
            echo "  Kernel actualizado: $p"
            KERNEL_TRIGGER=1
            # Only kernel image or module changes schedule boot preparation.
            if array_contains "$p" "${KERNEL_BOOT_PACKAGES[@]}"; then
                INITRD_UPDATE=1
                GRUB_UPDATE=1
            elif array_contains "$p" "${KERNEL_HEADERS_PACKAGES[@]}"; then
                echo "  [INFO] $p actualizado: puede requerir recompilacion de modulos externos"
            fi
        fi

    done

    [ "$KERNEL_TRIGGER" -eq 0 ] && echo "  Sin cambios de kernel"

    apply_boot_module_policy

    if [ "$KERNEL_TRIGGER" -eq 1 ] && [ "$BOOT_MODE" = disabled ]; then
        echo "  [INFO] Boot preparation disabled by configuration"
    elif [ "$KERNEL_TRIGGER" -eq 1 ] && [ "$BOOT_MODE" = auto ]; then
        if [ "$INITRD_REQUIRED" -eq 1 ] && [ "$INITRD_UPDATE" -eq 0 ]; then
            echo "  [INFO] initrd preparation not applicable in auto mode"
        fi
        if [ "$GRUB_REQUIRED" -eq 1 ] && [ "$GRUB_UPDATE" -eq 0 ]; then
            echo "  [INFO] GRUB preparation not applicable in auto mode"
        fi
    fi
}

read_simple_shell_path_assignment() {
    local config_file=$1
    local variable_name=$2
    local line
    local value
    local parameter_prefix="\${$variable_name:-"

    [ -f "$config_file" ] || return 1

    line=$(grep -E "^[[:space:]]*(export[[:space:]]+)?${variable_name}=" \
        "$config_file" 2>/dev/null | tail -1) || return 1
    line=$(trim_whitespace "$line")
    line=${line#export }
    value=${line#*=}
    value=$(trim_whitespace "$value")

    if [ "${value#\"}" != "$value" ] && [ "${value%\"}" != "$value" ]; then
        value=${value#\"}
        value=${value%\"}
    elif [ "${value#\'}" != "$value" ] && [ "${value%\'}" != "$value" ]; then
        value=${value#\'}
        value=${value%\'}
    fi

    if [[ $value == "$parameter_prefix"*'}' ]]; then
        value=${value#"$parameter_prefix"}
        value=${value%\}}
    fi

    [ -n "$value" ] || return 1
    printf '%s\n' "$value"
}

resolve_sbo_personal_queue_directory() {
    local configured_queue_dir
    local local_config_file=${LOCAL_SBOPKG_CONF:-/root/.sbopkg.conf}
    local configured_local_file
    local local_queue_dir

    configured_queue_dir=$(read_simple_shell_path_assignment \
        "$SBOPKG_CONFIG" QUEUEDIR 2>/dev/null || true)
    configured_local_file=$(read_simple_shell_path_assignment \
        "$SBOPKG_CONFIG" LOCAL_SBOPKG_CONF 2>/dev/null || true)
    if [ -n "$configured_local_file" ]; then
        local_config_file=$configured_local_file
    fi
    local_queue_dir=$(read_simple_shell_path_assignment \
        "$local_config_file" QUEUEDIR 2>/dev/null || true)
    if [ -n "$local_queue_dir" ]; then
        configured_queue_dir=$local_queue_dir
    fi
    if [ -z "$configured_queue_dir" ]; then
        configured_queue_dir=$SBO_QUEUE_DIR_FALLBACK
    fi

    case "$configured_queue_dir" in
        /*) ;;
        *)
            SBO_TARGET_SELECTION_ERROR="resolved SBo queue directory is not absolute: $configured_queue_dir"
            return 1
            ;;
    esac

    SBO_PERSONAL_QUEUE_DIR=$configured_queue_dir
    SBODIR=$configured_queue_dir
}

prepare_private_sbo_queue_workspace() {
    local source_directory=$1
    local destination_directory=$2
    local source_listing
    local source_file
    local relative_path
    local destination_file
    local destination_parent
    local canonical_source
    local canonical_destination

    SBO_TARGET_SELECTION_ERROR=
    SBO_PERSONAL_QUEUE_FILE_COUNT=0
    SBO_PERSONAL_QUEUE_SYMLINK_COUNT=0

    case "$source_directory" in
        /*) ;;
        *)
            SBO_TARGET_SELECTION_ERROR="personal SBo queue directory is not absolute: $source_directory"
            return 1
            ;;
    esac
    case "$destination_directory" in
        /*) ;;
        *)
            SBO_TARGET_SELECTION_ERROR="private SBo queue workspace is not absolute: $destination_directory"
            return 1
            ;;
    esac

    canonical_source=$(readlink -m -- "$source_directory") || {
        SBO_TARGET_SELECTION_ERROR="cannot canonicalize personal SBo queue directory: $source_directory"
        return 1
    }
    canonical_destination=$(readlink -m -- "$destination_directory") || {
        SBO_TARGET_SELECTION_ERROR="cannot canonicalize private SBo queue workspace: $destination_directory"
        return 1
    }

    if [ "$canonical_source" = "$canonical_destination" ]; then
        SBO_TARGET_SELECTION_ERROR="private SBo queue workspace must differ from the personal queue directory"
        return 1
    fi
    case "$canonical_destination/" in
        "$canonical_source/"*)
            SBO_TARGET_SELECTION_ERROR="private SBo queue workspace must not be inside the personal queue directory"
            return 1
            ;;
    esac

    if [ -e "$destination_directory" ] || [ -L "$destination_directory" ]; then
        SBO_TARGET_SELECTION_ERROR="private SBo queue workspace already exists: $destination_directory"
        return 1
    fi

    if [ -e "$source_directory" ] || [ -L "$source_directory" ]; then
        if [ ! -d "$source_directory" ] || [ -L "$source_directory" ]; then
            SBO_TARGET_SELECTION_ERROR="personal SBo queue path is not a real directory: $source_directory"
            return 1
        fi
        if [ ! -r "$source_directory" ] || [ ! -x "$source_directory" ]; then
            SBO_TARGET_SELECTION_ERROR="personal SBo queue directory is not readable: $source_directory"
            return 1
        fi
    fi

    if ! mkdir -m 0700 -- "$destination_directory"; then
        SBO_TARGET_SELECTION_ERROR="cannot create private SBo queue workspace: $destination_directory"
        return 1
    fi
    SBO_GENERATED_QUEUE_OWNED_PATH=$destination_directory
    SBO_GENERATED_QUEUE_OWNED_CANONICAL=$canonical_destination

    if [ ! -d "$source_directory" ]; then
        SBO_QUEUE_SOURCE_DIR=$destination_directory
        return 0
    fi

    source_listing=$(mktemp) || {
        remove_owned_sbo_queue_workspace
        SBO_TARGET_SELECTION_ERROR="cannot create personal SBo queue listing"
        return 1
    }

    if ! find "$source_directory" -type f -name '*.sqf' -print0 \
        | LC_ALL=C sort -z > "$source_listing"; then
        rm -f "$source_listing"
        remove_owned_sbo_queue_workspace
        SBO_TARGET_SELECTION_ERROR="cannot enumerate personal SBo queue files: $source_directory"
        return 1
    fi

    SBO_PERSONAL_QUEUE_SYMLINK_COUNT=$(find "$source_directory" -type l -name '*.sqf' \
        -printf '.' 2>/dev/null | wc -c)

    while IFS= read -r -d '' source_file; do
        relative_path=${source_file#"$source_directory"/}
        if [ "$relative_path" = "$source_file" ] || [ -z "$relative_path" ]; then
            rm -f "$source_listing"
            remove_owned_sbo_queue_workspace
            SBO_TARGET_SELECTION_ERROR="cannot derive a relative personal queue path: $source_file"
            return 1
        fi

        destination_file="$destination_directory/$relative_path"
        destination_parent=$(dirname -- "$destination_file")
        if ! mkdir -p -m 0700 -- "$destination_parent" \
            || ! install -m 0600 /dev/null "$destination_file" \
            || ! cat -- "$source_file" > "$destination_file"; then
            rm -f "$source_listing"
            remove_owned_sbo_queue_workspace
            SBO_TARGET_SELECTION_ERROR="cannot copy personal SBo queue into private workspace: $source_file"
            return 1
        fi
        SBO_PERSONAL_QUEUE_FILE_COUNT=$((SBO_PERSONAL_QUEUE_FILE_COUNT + 1))
    done < "$source_listing"

    rm -f "$source_listing"
    SBO_QUEUE_SOURCE_DIR=$destination_directory
}

shell_single_quote() {
    local value=$1

    printf "'%s'" "${value//\'/\'\\\'\'}"
}

prepare_private_sqg_configuration() {
    local original_config=$1
    local private_queue_directory=$2
    local wrapper_directory="$private_queue_directory/.slack-update"
    local original_config_quoted
    local private_queue_directory_quoted
    local private_local_config_quoted

    SBO_PRIVATE_SBOPKG_CONFIG=
    SBO_PRIVATE_LOCAL_SBOPKG_CONFIG=

    if [ ! -f "$original_config" ] || [ ! -r "$original_config" ]; then
        SBO_TARGET_SELECTION_ERROR="sbopkg configuration is not a readable regular file: $original_config"
        return 1
    fi
    if [ ! -d "$private_queue_directory" ] || [ -L "$private_queue_directory" ]; then
        SBO_TARGET_SELECTION_ERROR="private SBo queue workspace is not a real directory: $private_queue_directory"
        return 1
    fi
    if [ -e "$wrapper_directory" ] || [ -L "$wrapper_directory" ]; then
        SBO_TARGET_SELECTION_ERROR="private sqg configuration directory already exists: $wrapper_directory"
        return 1
    fi
    if ! mkdir -m 0700 -- "$wrapper_directory"; then
        SBO_TARGET_SELECTION_ERROR="cannot create private sqg configuration directory: $wrapper_directory"
        return 1
    fi

    SBO_PRIVATE_SBOPKG_CONFIG="$wrapper_directory/sbopkg.conf"
    SBO_PRIVATE_LOCAL_SBOPKG_CONFIG="$wrapper_directory/local.conf"
    if ! install -m 0600 /dev/null "$SBO_PRIVATE_SBOPKG_CONFIG" \
        || ! install -m 0600 /dev/null "$SBO_PRIVATE_LOCAL_SBOPKG_CONFIG"; then
        rm -rf -- "$wrapper_directory"
        SBO_PRIVATE_SBOPKG_CONFIG=
        SBO_PRIVATE_LOCAL_SBOPKG_CONFIG=
        SBO_TARGET_SELECTION_ERROR="cannot create private sqg configuration files"
        return 1
    fi

    original_config_quoted=$(shell_single_quote "$original_config")
    private_queue_directory_quoted=$(shell_single_quote "$private_queue_directory")
    private_local_config_quoted=$(shell_single_quote "$SBO_PRIVATE_LOCAL_SBOPKG_CONFIG")

    if ! {
        printf '. %s\n' "$original_config_quoted"
        printf 'SLACK_UPDATE_ORIGINAL_LOCAL_SBOPKG_CONF=${LOCAL_SBOPKG_CONF:-}\n'
        printf 'LOCAL_SBOPKG_CONF=%s\n' "$private_local_config_quoted"
        printf 'QUEUEDIR=%s\n' "$private_queue_directory_quoted"
    } > "$SBO_PRIVATE_SBOPKG_CONFIG"; then
        rm -rf -- "$wrapper_directory"
        SBO_PRIVATE_SBOPKG_CONFIG=
        SBO_PRIVATE_LOCAL_SBOPKG_CONFIG=
        SBO_TARGET_SELECTION_ERROR="cannot write private sqg system configuration"
        return 1
    fi

    if ! {
        printf '%s\n' 'if [ -n "${SLACK_UPDATE_ORIGINAL_LOCAL_SBOPKG_CONF:-}" ] && [ -e "$SLACK_UPDATE_ORIGINAL_LOCAL_SBOPKG_CONF" ]; then'
        printf '%s\n' '    . "$SLACK_UPDATE_ORIGINAL_LOCAL_SBOPKG_CONF"'
        printf '%s\n' 'fi'
        printf 'QUEUEDIR=%s\n' "$private_queue_directory_quoted"
    } > "$SBO_PRIVATE_LOCAL_SBOPKG_CONFIG"; then
        rm -rf -- "$wrapper_directory"
        SBO_PRIVATE_SBOPKG_CONFIG=
        SBO_PRIVATE_LOCAL_SBOPKG_CONFIG=
        SBO_TARGET_SELECTION_ERROR="cannot write private sqg local configuration"
        return 1
    fi
}

synchronize_sbo_repository() {
    # ---------------------------
    # [5] SBo SYNC
    # ---------------------------

    echo "[5] Sync SBo"

    if command -v sbopkg >/dev/null 2>&1; then
        if command -v sqg >/dev/null 2>&1; then
            SBOPKG_SYNC_STATUS=0
            sbopkg -r || SBOPKG_SYNC_STATUS=$?

            SQG_SYNC_STATUS=0
            SBO_QUEUE_GENERATION_READY=0
            SBO_QUEUE_SOURCE_DIR=
            if ! resolve_sbo_personal_queue_directory; then
                SQG_SYNC_STATUS=1
                echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
            elif ! prepare_private_sbo_queue_workspace \
                "$SBO_PERSONAL_QUEUE_DIR" "$SBO_GENERATED_QUEUE_DIR"; then
                SQG_SYNC_STATUS=1
                echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
            elif ! prepare_private_sqg_configuration \
                "$SBOPKG_CONFIG" "$SBO_GENERATED_QUEUE_DIR"; then
                SQG_SYNC_STATUS=1
                echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
            else
                echo "  Personal queue directory preserved read-only: $SBO_PERSONAL_QUEUE_DIR"
                echo "  Private sqg workspace: $SBO_GENERATED_QUEUE_DIR"
                echo "  Personal queue files copied: $SBO_PERSONAL_QUEUE_FILE_COUNT"
                if [ "$SBO_PERSONAL_QUEUE_SYMLINK_COUNT" -gt 0 ]; then
                    echo "  [WARN] Personal queue symlinks ignored: $SBO_PERSONAL_QUEUE_SYMLINK_COUNT"
                fi
                if SBOPKG_CONF="$SBO_PRIVATE_SBOPKG_CONFIG" \
                    QUEUEDIR="$SBO_GENERATED_QUEUE_DIR" sqg -a; then
                    SBO_QUEUE_GENERATION_READY=1
                else
                    SQG_SYNC_STATUS=$?
                    SBO_TARGET_SELECTION_ERROR="sqg queue generation failed in the private workspace with exit code $SQG_SYNC_STATUS"
                fi
            fi
        else
            echo "  sqg no encontrado -- omitiendo sync SBo"
        fi
    else
        echo "  sbopkg no instalado, omitiendo"
    fi
}

build_sbo_core_queue() {
    # ---------------------------
    # [6] BUILD QUEUES
    # ---------------------------

    echo "[6] Generando colas SBo"

    if [ -z "${SBO_PERSONAL_QUEUE_DIR:-}" ]; then
        if ! resolve_sbo_personal_queue_directory; then
            echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
            return 1
        fi
    fi
    if [ -z "${SBO_QUEUE_SOURCE_DIR:-}" ]; then
        SBO_QUEUE_SOURCE_DIR=$SBO_PERSONAL_QUEUE_DIR
    fi

    rm -f "$QUEUE_CORE" "$QUEUE_EXTRA" "$SBO_OPTION_RECORDS"

    if [ ! -d "$SBO_QUEUE_SOURCE_DIR" ]; then
        echo "  [WARN] SBo queue source directory not found: $SBO_QUEUE_SOURCE_DIR"
    fi

    if ! collect_ordered_sbo_targets_from_queue_directory "$SBO_QUEUE_SOURCE_DIR" "$QUEUE_CORE"; then
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi
    if ! collect_sbo_option_records_from_sources \
        "$SBO_QUEUE_SOURCE_DIR" "$SBO_OPTIONS_FILE" "$SBO_OPTION_RECORDS"; then
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi

    TOTAL_CORE=$(wc -l < "$QUEUE_CORE")
    echo "  Cola principal: $TOTAL_CORE paquetes"
    echo "  Opciones de compilacion preservadas: $SBO_OPTION_RECORD_COUNT"
}

add_abi_rebuild_targets() {
    # ---------------------------
    # [7] ABI FORCES SBo REBUILD
    # ---------------------------

    if [ "$ABI_TRIGGER" -eq 1 ]; then

        echo "[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra"

        if ! collect_installed_sbo_targets "$QUEUE_EXTRA"; then
            echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
            return 1
        fi

        TOTAL_EXTRA=$(wc -l < "$QUEUE_EXTRA")
        echo "  Cola ABI extra: $TOTAL_EXTRA paquetes"

    else
        touch "$QUEUE_EXTRA"
    fi
}

elf_file_has_static_magic() {
    local path=$1
    local magic

    [ -f "$path" ] || return 1

    magic=$(LC_ALL=C od -An -tx1 -N4 -- "$path" 2>/dev/null | tr -d '[:space:]') || return 1
    [ "$magic" = 7f454c46 ]
}

resolve_static_elf_object_path() {
    local path=$1
    local resolved

    resolved=$(readlink -f -- "$path" 2>/dev/null) || return 1
    elf_file_has_static_magic "$resolved" || return 1
    printf '%s\n' "$resolved"
}

extract_static_elf_needed_libraries() {
    local object=$1

    LC_ALL=C readelf -d -- "$object" 2>>"$BROKEN_ERRORS" \
        | awk '/\(NEEDED\)/ { value=$0; sub(/^.*\[/, "", value); sub(/\].*$/, "", value); print value }' \
        | LC_ALL=C sort -u
}

extract_static_elf_identity() {
    local object=$1

    LC_ALL=C readelf -h -- "$object" 2>>"$BROKEN_ERRORS" \
        | awk -F ':' '
            function trim(value) {
                sub(/^[[:space:]]+/, "", value)
                sub(/[[:space:]]+$/, "", value)
                return value
            }
            /^[[:space:]]*Class:/ { elf_class=trim($2) }
            /^[[:space:]]*Data:/ { elf_data=trim(substr($0, index($0, ":") + 1)) }
            /^[[:space:]]*Machine:/ { elf_machine=trim(substr($0, index($0, ":") + 1)) }
            END {
                if (elf_class == "" || elf_data == "" || elf_machine == "") {
                    exit 1
                }
                printf "%s\t%s\t%s\n", elf_class, elf_data, elf_machine
            }
        '
}

refresh_static_elf_library_cache() {
    local destination=$1
    local raw_cache
    local temporary
    local soname
    local candidate
    local resolved
    local identity

    ELF_LIBRARY_CACHE_RECORD_COUNT=0
    raw_cache=$(mktemp "${destination}.raw.XXXXXX") || return 1
    temporary=$(mktemp "${destination}.XXXXXX") || {
        rm -f -- "$raw_cache"
        return 1
    }

    if ! LC_ALL=C /sbin/ldconfig -p 2>>"$BROKEN_ERRORS" \
        | awk '$0 ~ /^[[:space:]]/ && index($0, "=>") { print $1 "\t" $NF }' \
        | LC_ALL=C sort -u > "$raw_cache"; then
        rm -f -- "$raw_cache" "$temporary"
        return 1
    fi

    while IFS=$'\t' read -r soname candidate; do
        [ -n "$soname" ] && [ -n "$candidate" ] || continue

        if ! resolved=$(resolve_static_elf_object_path "$candidate"); then
            printf 'cannot resolve cached ELF library %s => %s\n' \
                "$soname" "$candidate" >> "$BROKEN_ERRORS"
            continue
        fi
        if ! identity=$(extract_static_elf_identity "$resolved"); then
            printf 'cannot read cached ELF identity %s => %s\n' \
                "$soname" "$resolved" >> "$BROKEN_ERRORS"
            continue
        fi

        printf '%s\t%s\t%s\n' "$soname" "$identity" "$resolved"
    done < "$raw_cache" | LC_ALL=C sort -u > "$temporary"

    rm -f -- "$raw_cache"

    if [ ! -s "$temporary" ]; then
        printf '%s\n' 'ldconfig produced no usable architecture-tagged ELF records' \
            >> "$BROKEN_ERRORS"
        rm -f -- "$temporary"
        return 1
    fi

    chmod 600 "$temporary" 2>/dev/null || true
    mv -f -- "$temporary" "$destination"
    ELF_LIBRARY_CACHE_RECORD_COUNT=$(wc -l < "$destination")
}

static_elf_cache_has_compatible_library() {
    local library_cache=$1
    local soname=$2
    local identity=$3
    local elf_class
    local elf_data
    local elf_machine

    IFS=$'\t' read -r elf_class elf_data elf_machine <<< "$identity"
    [ -n "$elf_class" ] && [ -n "$elf_data" ] && [ -n "$elf_machine" ] || return 1

    awk -F '\t' \
        -v soname="$soname" \
        -v elf_class="$elf_class" \
        -v elf_data="$elf_data" \
        -v elf_machine="$elf_machine" '
            $1 == soname && $2 == elf_class && $3 == elf_data && $4 == elf_machine {
                found=1
                exit
            }
            END { exit(found ? 0 : 1) }
        ' "$library_cache"
}

static_elf_object_has_missing_dependency() {
    local object=$1
    local library_cache=$2
    local identity
    local needed_libraries
    local library

    if ! identity=$(extract_static_elf_identity "$object"); then
        return 2
    fi
    if ! needed_libraries=$(extract_static_elf_needed_libraries "$object"); then
        return 2
    fi

    while IFS= read -r library; do
        [ -n "$library" ] || continue
        if ! static_elf_cache_has_compatible_library \
            "$library_cache" "$library" "$identity"; then
            return 0
        fi
    done <<< "$needed_libraries"

    return 1
}

report_static_elf_scan_errors() {
    if [ -s "$BROKEN_ERRORS" ]; then
        echo "  [WARN] Static ELF inspection diagnostics:"
        sed 's/^/    /' "$BROKEN_ERRORS"
        : > "$BROKEN_ERRORS"
    fi
}

detect_broken_elf_objects() {
    local path
    local object
    local inspection_status

    # ---------------------------
    # [8] BROKEN LIBS DETECTION
    # ---------------------------

    echo "[8] Detecting broken ELF objects without executing inspected files"

    ELF_SCAN_STATUS=0
    : > "$BROKEN_ERRORS"
    : > "$BROKEN_NEW"

    if ! refresh_static_elf_library_cache "$ELF_LIBRARY_CACHE"; then
        ELF_SCAN_STATUS=1
        echo "  [ERROR] Cannot build the static ELF library cache"
        report_static_elf_scan_errors
        return 1
    fi

    find "${ELF_SCAN_PATHS[@]}" \( -type f -o -type l \) -print0 |
    while IFS= read -r -d '' path; do
        object=$(resolve_static_elf_object_path "$path") || continue

        if static_elf_object_has_missing_dependency "$object" "$ELF_LIBRARY_CACHE"; then
            printf '%s\n' "$path"
        else
            inspection_status=$?
            if [ "$inspection_status" -eq 2 ]; then
                printf 'readelf could not inspect %s\n' "$path" >> "$BROKEN_ERRORS"
            fi
        fi
    done | LC_ALL=C sort -u > "$BROKEN_NEW"

    report_static_elf_scan_errors

    # broken.txt represents only the current static inspection result.
    cp -f -- "$BROKEN_NEW" "$BROKEN"

    BROKEN_COUNT=$(wc -l < "$BROKEN" 2>/dev/null || echo 0)
    echo "  Broken ELF objects detected: $BROKEN_COUNT"
}

verify_broken_elf_objects_after_rebuild() {
    local path
    local object
    local inspection_status

    if [ ! -s "$BROKEN" ]; then
        ELF_VERIFICATION_STATUS=0
        return 0
    fi

    ELF_VERIFICATION_STATUS=0
    echo "  Verifying rebuilt ELF objects with static inspection..."
    : > "$BROKEN_ERRORS"
    : > "$STILL_BROKEN"

    if ! refresh_static_elf_library_cache "$ELF_LIBRARY_CACHE"; then
        ELF_VERIFICATION_STATUS=1
        echo "  [WARN] Cannot refresh the static ELF library cache after the rebuild"
        report_static_elf_scan_errors
        return 1
    fi

    while IFS= read -r path; do
        [ -n "$path" ] || continue
        if ! object=$(resolve_static_elf_object_path "$path"); then
            if [ -e "$path" ] || [ -L "$path" ]; then
                printf '%s\n' "$path"
                printf 'cannot statically re-inspect %s\n' "$path" >> "$BROKEN_ERRORS"
            fi
            continue
        fi

        if static_elf_object_has_missing_dependency "$object" "$ELF_LIBRARY_CACHE"; then
            printf '%s\n' "$path"
        else
            inspection_status=$?
            if [ "$inspection_status" -eq 2 ]; then
                printf '%s\n' "$path"
                printf 'readelf could not re-inspect %s\n' "$path" >> "$BROKEN_ERRORS"
            fi
        fi
    done < "$BROKEN" | LC_ALL=C sort -u > "$STILL_BROKEN"

    report_static_elf_scan_errors

    if [ -s "$STILL_BROKEN" ]; then
        echo "  [WARN] ELF objects that still have unresolved dependencies:"
        sed 's/^/    /' "$STILL_BROKEN"
        cp -f -- "$STILL_BROKEN" "$BROKEN"
        ELF_VERIFICATION_STATUS=1
        return 1
    fi

    echo "  [OK] All previously broken ELF objects passed static verification"
    : > "$BROKEN"
}

map_broken_objects_to_sbo_packages() {
    # ---------------------------
    # [9] MAP BROKEN TO SBo PKGS
    # ---------------------------

    echo "[9] Mapeando binarios rotos a paquetes SBo"

    if [ -s "$BROKEN" ]; then
        # FIX #3: Acumular en temporal y hacer merge para no contaminar QUEUE_EXTRA
        # con datos de ejecuciones anteriores cuando ABI no disparo (bloque [7]).
        _BROKEN_PKGS=$(mktemp)
        while read -r bin; do
            [ -e "$bin" ] || continue
            # FIX #4: Anclar con grep -P para cubrir rutas con y sin barra inicial
            # en los manifiestos de /var/log/packages (algunos omiten el '/' inicial).
            grep -rlP "^/?${bin#/}$" "$PACKAGE_DATABASE"/ 2>/dev/null \
                | package_names_with_build_suffix_from_stream "$SBO_PACKAGE_TAG"
        done < "$BROKEN" | LC_ALL=C sort -u > "$_BROKEN_PKGS"

        # Merge the existing ABI targets and broken-object owners deterministically.
        if ! merge_sbo_target_sets "$QUEUE_EXTRA.merged" "$QUEUE_EXTRA" "$_BROKEN_PKGS"; then
            rm -f "$_BROKEN_PKGS" "$QUEUE_EXTRA.merged"
            SBO_TARGET_SELECTION_ERROR="cannot merge broken-object SBo targets"
            echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
            return 1
        fi
        mv -f -- "$QUEUE_EXTRA.merged" "$QUEUE_EXTRA"
        rm -f "$_BROKEN_PKGS"

        TOTAL_EXTRA=$(wc -l < "$QUEUE_EXTRA")
        echo "  Cola extra tras rotos: $TOTAL_EXTRA paquetes"
    else
        echo "  Sin binarios rotos, nada que anadir"
    fi
}

build_sbo_target_queues_after_synchronization() {
    if [ "${SBO_QUEUE_GENERATION_READY:-0}" -ne 1 ]; then
        if [ -z "${SBO_TARGET_SELECTION_ERROR:-}" ]; then
            SBO_TARGET_SELECTION_ERROR="private SBo queue generation did not complete successfully"
        fi
        return 1
    fi

    build_sbo_core_queue && add_abi_rebuild_targets
}

build_and_apply_sbo_queue() {
    local option_records=${SBO_OPTION_RECORDS:-/dev/null}

    # ---------------------------
    # [10] BUILD FINAL QUEUE + APPLY
    # ---------------------------

    echo "[10] Aplicando cola SBo"

    if ! merge_ordered_sbo_queue_with_target_sets \
        "$QUEUE_FINAL" "$QUEUE_CORE" "$option_records" "$QUEUE_EXTRA"; then
        SBO_TARGET_SELECTION_ERROR="cannot build the final dependency-ordered SBo queue"
        SBO_BUILD_STATUS=1
        echo "  [ERROR] $SBO_TARGET_SELECTION_ERROR"
        return 1
    fi

    TOTAL=$(wc -l < "$QUEUE_FINAL")
    TOTAL_EN_COLA=$TOTAL
    echo "  Total paquetes en cola: $TOTAL"

    if [ "$TOTAL" -gt 0 ]; then
        # FIX #5: Sustituido 'sbopkg -b -i "string largo"' por 'sbopkg -b -B fichero'.
        # Pasar todos los paquetes como un unico string con -i puede superar ARG_MAX
        # cuando la cola es grande. Usar -B con el fichero .sqf es mas robusto y es
        # la forma recomendada por sbopkg para listas de paquetes.
        SBO_BUILD_STATUS=0
        if sbopkg -b -B "$QUEUE_FINAL"; then
            echo "  [OK] Cola SBo procesada"
        else
            SBO_BUILD_STATUS=$?
            echo "  [WARN] sbopkg termino con errores -- revisar log: $LOG"
        fi

        # Reuse the static reader for post-build verification. Inspected objects
        # are never invoked as commands and no dynamic-loader trace mode is used.
        if [ -s "$BROKEN" ]; then
            verify_broken_elf_objects_after_rebuild || true
        fi
    else
        echo "  Cola vacia, nada que hacer"
    fi
}

rebuild_cinnamon() {
    # ---------------------------
    # [11] CINNAMON BUILD
    # ---------------------------

    if [ "$CINNAMON_TRIGGER" -eq 1 ]; then

        echo "[11] Rebuild Cinnamon"

        if [ -d "$CSB_DIR/.git" ]; then

            echo "  Actualizando repositorio CSB"

            git -C "$CSB_DIR" fetch origin 2>&1 \
                && git -C "$CSB_DIR" reset --hard "origin/$CSB_BRANCH" 2>&1 \
                && echo "  [OK] Repositorio CSB actualizado" \
                || echo "  [WARN] No se pudo actualizar CSB -- continuando con copia local"

        else

            echo "  Clonando repositorio CSB"

            git clone -b "$CSB_BRANCH" -- "$CSB_REMOTE" "$CSB_DIR" \
                && echo "  [OK] Repositorio CSB clonado" \
                || echo "  [ERROR] git clone de CSB fallo -- Cinnamon NO sera reconstruido"
        fi

        CINNAMON_OK=0

        if [ -x "$CSB_DIR/$CSB_BUILDER" ]; then

            (
                cd "$CSB_DIR" || exit 1
                "./$CSB_BUILDER"
            )
            RET=$?

            if [ "$RET" -eq 0 ]; then
                CINNAMON_OK=1
                CINNAMON_TRIGGER=2
                echo "  [OK] Cinnamon reconstruido correctamente"
            else
                CINNAMON_TRIGGER=3
                echo "  [ERROR] Fallo en Cinnamon -- revisar log"
            fi

        else
            CINNAMON_TRIGGER=3
            echo "  [ERROR] $CSB_BUILDER no existe o no es ejecutable"
        fi

    fi
}


is_safe_kernel_version() {
    local version=$1

    case "$version" in
        ''|.|..|*/*|*[[:space:]]*|*[!A-Za-z0-9._+-]*) return 1 ;;
        *) return 0 ;;
    esac
}

read_mkinitrd_scalar_assignment() {
    local config_file=$1
    local variable_name=$2
    local raw_line
    local line
    local assignment_name
    local value
    local quote
    local match_count=0

    MKINITRD_ASSIGNMENT_VALUE=
    MKINITRD_ASSIGNMENT_ERROR=

    if [ ! -f "$config_file" ]; then
        MKINITRD_ASSIGNMENT_ERROR="mkinitrd configuration is not a regular file: $config_file"
        return 2
    fi
    if [ ! -r "$config_file" ]; then
        MKINITRD_ASSIGNMENT_ERROR="mkinitrd configuration is not readable: $config_file"
        return 2
    fi

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        line=${raw_line%$'\r'}
        line=$(trim_whitespace "$line")
        case "$line" in
            ''|'#'*) continue ;;
        esac
        case "$line" in
            *=*) ;;
            *) continue ;;
        esac

        assignment_name=${line%%=*}
        assignment_name=$(trim_whitespace "$assignment_name")
        case "$assignment_name" in
            export[[:space:]]*)
                assignment_name=${assignment_name#export}
                assignment_name=$(trim_whitespace "$assignment_name")
                ;;
        esac
        [ "$assignment_name" = "$variable_name" ] || continue

        match_count=$((match_count + 1))
        if [ "$match_count" -gt 1 ]; then
            MKINITRD_ASSIGNMENT_ERROR="duplicate $variable_name assignment in: $config_file"
            return 2
        fi

        value=${line#*=}
        value=${value%%#*}
        value=$(trim_whitespace "$value")
        [ -n "$value" ] || {
            MKINITRD_ASSIGNMENT_ERROR="empty $variable_name assignment in: $config_file"
            return 2
        }

        quote=${value:0:1}
        case "$quote" in
            "'"|'"')
                if [ "${value: -1}" != "$quote" ] || [ "${#value}" -lt 2 ]; then
                    MKINITRD_ASSIGNMENT_ERROR="unterminated $variable_name assignment in: $config_file"
                    return 2
                fi
                value=${value:1:${#value}-2}
                ;;
            *)
                case "$value" in
                    *"'"*|*'"'*)
                        MKINITRD_ASSIGNMENT_ERROR="invalid quoting in $variable_name assignment: $config_file"
                        return 2
                        ;;
                esac
                ;;
        esac

        case "$value" in
            ''|*[!A-Za-z0-9_+.,:/=@%-]*)
                MKINITRD_ASSIGNMENT_ERROR="unsafe $variable_name assignment in: $config_file"
                return 2
                ;;
        esac
        MKINITRD_ASSIGNMENT_VALUE=$value
    done < "$config_file"

    if [ "$match_count" -eq 0 ]; then
        MKINITRD_ASSIGNMENT_ERROR="$variable_name assignment is missing from: $config_file"
        return 1
    fi
}

resolve_installed_initrd_kernel_version() {
    local snapshot=$1
    local package_name=$2
    local record
    local version
    local -A versions=()

    INITRD_INSTALLED_KERNEL_VERSION=
    INITRD_INSTALLED_KERNEL_RECORD_COUNT=0

    if [ ! -f "$snapshot" ] || [ ! -r "$snapshot" ]; then
        INITRD_VALIDATION_ERROR="installed package snapshot is unavailable: $snapshot"
        return 1
    fi

    while IFS= read -r record || [ -n "$record" ]; do
        parse_slackware_package_record "$record" || continue
        [ "$SLACKWARE_PACKAGE_NAME" = "$package_name" ] || continue
        version=$SLACKWARE_PACKAGE_VERSION
        if ! is_safe_kernel_version "$version"; then
            INITRD_VALIDATION_ERROR="installed kernel package has an unsafe version: $record"
            return 1
        fi
        versions[$version]=1
        INITRD_INSTALLED_KERNEL_RECORD_COUNT=$((INITRD_INSTALLED_KERNEL_RECORD_COUNT + 1))
    done < "$snapshot"

    if [ "$INITRD_INSTALLED_KERNEL_RECORD_COUNT" -eq 0 ]; then
        INITRD_VALIDATION_ERROR="installed kernel package was not found in the post-update snapshot: $package_name"
        return 1
    fi
    if [ "${#versions[@]}" -ne 1 ]; then
        INITRD_VALIDATION_ERROR="installed kernel package has multiple versions in the post-update snapshot: $package_name"
        return 1
    fi

    for version in "${!versions[@]}"; do
        INITRD_INSTALLED_KERNEL_VERSION=$version
    done
}

resolve_configured_initrd_output_path() {
    local status

    INITRD_OUTPUT_PATH=

    if read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" OUTPUT_IMAGE; then
        INITRD_OUTPUT_PATH=$MKINITRD_ASSIGNMENT_VALUE
    else
        status=$?
        if [ "$status" -eq 2 ]; then
            INITRD_VALIDATION_ERROR=$MKINITRD_ASSIGNMENT_ERROR
            return 1
        fi

        if read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" OUTPUT; then
            INITRD_OUTPUT_PATH=$MKINITRD_ASSIGNMENT_VALUE
        else
            status=$?
            if [ "$status" -eq 2 ]; then
                INITRD_VALIDATION_ERROR=$MKINITRD_ASSIGNMENT_ERROR
                return 1
            fi
            INITRD_OUTPUT_PATH=$INITRD_DEFAULT_OUTPUT
        fi
    fi

    case "$INITRD_OUTPUT_PATH" in
        /*) ;;
        *)
            INITRD_VALIDATION_ERROR="resolved initrd output path is not absolute: $INITRD_OUTPUT_PATH"
            return 1
            ;;
    esac
}

validate_initrd_kernel_configuration() {
    INITRD_VALIDATION_STATUS=1
    INITRD_VALIDATION_ERROR=
    INITRD_CONFIGURED_KERNEL_VERSION=
    INITRD_INSTALLED_KERNEL_VERSION=
    INITRD_INSTALLED_KERNEL_RECORD_COUNT=0
    INITRD_MODULES_PATH=
    INITRD_OUTPUT_PATH=

    if ! resolve_installed_initrd_kernel_version "$AFTER_PKGS" "$INITRD_KERNEL_PACKAGE"; then
        return 1
    fi

    if read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" KERNEL_VERSION; then
        INITRD_CONFIGURED_KERNEL_VERSION=$MKINITRD_ASSIGNMENT_VALUE
    else
        INITRD_VALIDATION_ERROR=$MKINITRD_ASSIGNMENT_ERROR
        return 1
    fi

    if ! is_safe_kernel_version "$INITRD_CONFIGURED_KERNEL_VERSION"; then
        INITRD_VALIDATION_ERROR="configured KERNEL_VERSION is unsafe: $INITRD_CONFIGURED_KERNEL_VERSION"
        return 1
    fi

    if [ "$INITRD_CONFIGURED_KERNEL_VERSION" != "$INITRD_INSTALLED_KERNEL_VERSION" ]; then
        INITRD_VALIDATION_ERROR="configured KERNEL_VERSION does not match the installed $INITRD_KERNEL_PACKAGE package: configured=$INITRD_CONFIGURED_KERNEL_VERSION installed=$INITRD_INSTALLED_KERNEL_VERSION"
        return 1
    fi

    if ! read_mkinitrd_scalar_assignment "$MKINITRD_CONFIG" ROOTDEV; then
        INITRD_VALIDATION_ERROR=$MKINITRD_ASSIGNMENT_ERROR
        return 1
    fi

    INITRD_MODULES_PATH="$KERNEL_MODULES_DIRECTORY/$INITRD_INSTALLED_KERNEL_VERSION"
    if [ ! -d "$INITRD_MODULES_PATH" ]; then
        INITRD_VALIDATION_ERROR="installed kernel modules directory is missing: $INITRD_MODULES_PATH"
        return 1
    fi

    resolve_configured_initrd_output_path || return 1

    INITRD_VALIDATION_STATUS=0
}

regenerate_initrd() {
    # ---------------------------
    # [12] INITRD
    # ---------------------------

    if [ "$INITRD_UPDATE" -eq 1 ]; then
        echo "[12] Regenerando initrd"

        INITRD_OK=0
        if ! command -v mkinitrd >/dev/null 2>&1; then
            INITRD_VALIDATION_STATUS=1
            INITRD_VALIDATION_ERROR="mkinitrd is unavailable"
            echo "  [ERROR] mkinitrd no encontrado"
            return 1
        fi

        if ! validate_initrd_kernel_configuration; then
            echo "  [ERROR] Validacion de initrd fallida: $INITRD_VALIDATION_ERROR"
            return 1
        fi

        echo "  [OK] Kernel instalado validado: $INITRD_INSTALLED_KERNEL_VERSION"
        echo "  [OK] Modulos instalados validados: $INITRD_MODULES_PATH"

        if mkinitrd -F; then
            if [ -s "$INITRD_OUTPUT_PATH" ]; then
                INITRD_OK=1
                echo "  [OK] initrd regenerado ($INITRD_OUTPUT_PATH)"
                return 0
            fi
            echo "  [ERROR] mkinitrd termino sin errores pero $INITRD_OUTPUT_PATH esta vacio o no existe"
        else
            echo "  [ERROR] mkinitrd -F fallo"
        fi

        return 1
    fi
}

validate_direct_generic_kernel_configuration() {
    local record
    local record_path
    local record_count=0
    local installed_version=
    local resolved_kernel
    local kernel_basename
    local package_database_resolved

    DIRECT_GENERIC_VALIDATION_STATUS=1
    DIRECT_GENERIC_VALIDATION_ERROR=
    DIRECT_GENERIC_INSTALLED_KERNEL_VERSION=
    DIRECT_GENERIC_INSTALLED_KERNEL_RECORD_COUNT=0
    DIRECT_GENERIC_KERNEL_PATH=
    DIRECT_GENERIC_MODULES_PATH=

    [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="boot preparation layout is not direct-generic-no-initrd"
        return 1
    }
    [ -f "$AFTER_PKGS" ] && [ -r "$AFTER_PKGS" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update package snapshot is unavailable"
        return 1
    }

    while IFS= read -r record || [ -n "$record" ]; do
        parse_slackware_package_record "$record" || continue
        [ "$SLACKWARE_PACKAGE_NAME" = "$INITRD_KERNEL_PACKAGE" ] || continue
        record_count=$((record_count + 1))
        installed_version=$SLACKWARE_PACKAGE_VERSION
        DIRECT_GENERIC_PACKAGE_RECORD=$SLACKWARE_PACKAGE_RECORD
    done < <(package_snapshot_records_for_name "$AFTER_PKGS" "$INITRD_KERNEL_PACKAGE")

    DIRECT_GENERIC_INSTALLED_KERNEL_RECORD_COUNT=$record_count
    [ "$record_count" -eq 1 ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="installed kernel package has an ambiguous post-update record count: $record_count"
        return 1
    }
    is_safe_kernel_version "$installed_version" || {
        DIRECT_GENERIC_VALIDATION_ERROR="installed direct-generic kernel version is unsafe: $installed_version"
        return 1
    }

    if [ -e "$MKINITRD_CONFIG" ] || [ -L "$MKINITRD_CONFIG" ] \
        || [ -e "$INITRD_DEFAULT_OUTPUT" ] || [ -L "$INITRD_DEFAULT_OUTPUT" ]; then
        DIRECT_GENERIC_VALIDATION_ERROR="direct-generic boot became inconsistent because mkinitrd configuration or initrd appeared"
        return 1
    fi

    [ -L "$GENERIC_KERNEL_LINK" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel path is not a symbolic link"
        return 1
    }
    resolved_kernel=$(readlink -e -- "$GENERIC_KERNEL_LINK" 2>/dev/null) || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel link cannot be resolved"
        return 1
    }
    [ -f "$resolved_kernel" ] && [ ! -L "$resolved_kernel" ] && [ -r "$resolved_kernel" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel target is not a readable regular file"
        return 1
    }
    kernel_basename=${resolved_kernel##*/}
    [ "$kernel_basename" = "vmlinuz-$installed_version" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel link does not select vmlinuz-$installed_version"
        return 1
    }

    DIRECT_GENERIC_MODULES_PATH="$KERNEL_MODULES_DIRECTORY/$installed_version"
    [ -d "$DIRECT_GENERIC_MODULES_PATH" ] && [ ! -L "$DIRECT_GENERIC_MODULES_PATH" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update direct-generic module tree is missing or unsafe: $DIRECT_GENERIC_MODULES_PATH"
        return 1
    }

    package_database_resolved=$(readlink -e -- "$PACKAGE_DATABASE" 2>/dev/null) || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update package database cannot be resolved"
        return 1
    }
    [ -d "$package_database_resolved" ] && [ ! -L "$package_database_resolved" ]         && [ -r "$package_database_resolved" ] && [ -x "$package_database_resolved" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update package database is not a safe readable directory"
        return 1
    }
    record_path="$package_database_resolved/$DIRECT_GENERIC_PACKAGE_RECORD"
    [ -f "$record_path" ] && [ ! -L "$record_path" ] && [ -r "$record_path" ] || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel package record is missing or unsafe"
        return 1
    }
    grep -Fxq -- "boot/$kernel_basename" "$record_path" || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel package does not own boot/$kernel_basename"
        return 1
    }
    awk -v prefix="lib/modules/$installed_version/" 'index($0, prefix) == 1 { found=1 } END { exit !found }'         "$record_path" || {
        DIRECT_GENERIC_VALIDATION_ERROR="post-update generic kernel package does not own its module tree"
        return 1
    }

    DIRECT_GENERIC_INSTALLED_KERNEL_VERSION=$installed_version
    DIRECT_GENERIC_KERNEL_PATH=$resolved_kernel
    DIRECT_GENERIC_VALIDATION_STATUS=0
    return 0
}

grub_initrd_prerequisite_is_satisfied() {
    GRUB_BLOCKED_BY_INITRD=0
    GRUB_BLOCK_REASON=

    if [ "${GRUB_REQUIRED:-0}" -ne 1 ] || [ "${GRUB_UPDATE:-0}" -ne 1 ]; then
        return 0
    fi

    if [ "${BOOT_PREPARATION_LAYOUT:-unknown}" = direct-generic-no-initrd ]; then
        if validate_direct_generic_kernel_configuration; then
            return 0
        fi
        GRUB_BLOCKED_BY_INITRD=1
        GRUB_BLOCK_REASON="direct-generic kernel transition failed validation: $DIRECT_GENERIC_VALIDATION_ERROR"
        return 1
    fi

    if [ "${INITRD_REQUIRED:-0}" -ne 1 ]; then
        return 0
    fi

    if [ "${INITRD_UPDATE:-0}" -ne 1 ]; then
        GRUB_BLOCKED_BY_INITRD=1
        GRUB_BLOCK_REASON="required initrd preparation was not applicable: mode=${BOOT_MODE:-unknown}, ${BOOT_MODULE_REASON:-requirements unavailable}"
        return 1
    fi

    if [ "${INITRD_OK:-0}" -ne 1 ]; then
        GRUB_BLOCKED_BY_INITRD=1
        if [ -n "${INITRD_VALIDATION_ERROR:-}" ]; then
            GRUB_BLOCK_REASON="required initrd preparation failed validation: $INITRD_VALIDATION_ERROR"
        else
            GRUB_BLOCK_REASON="required initrd regeneration did not complete successfully"
        fi
        return 1
    fi

    return 0
}

grub_config_fingerprint() {
    local path=$1
    local metadata
    local checksum

    if [ -L "$path" ]; then
        return 2
    fi

    if [ ! -e "$path" ]; then
        printf '%s' absent
        return 0
    fi

    [ -f "$path" ] || return 2
    metadata=$(stat -c '%d:%i:%f:%u:%g:%s:%y' -- "$path") || return 1
    checksum=$(cksum -- "$path") || return 1
    printf '%s|%s' "$metadata" "$checksum"
}

discard_owned_grub_temporary_config() {
    local current_parent

    [ "${GRUB_TEMP_CONFIG_OWNED:-0}" -eq 1 ] || return 0
    [ -n "${GRUB_TEMP_CONFIG:-}" ] || return 0
    [ -n "${GRUB_TEMP_DIRECTORY_CANONICAL:-}" ] || return 0

    current_parent=$(readlink -e -- "$(dirname -- "$GRUB_TEMP_CONFIG")" 2>/dev/null) || return 0
    [ "$current_parent" = "$GRUB_TEMP_DIRECTORY_CANONICAL" ] || return 0
    [ ! -L "$GRUB_TEMP_CONFIG" ] || return 0

    if [ -f "$GRUB_TEMP_CONFIG" ]; then
        rm -f -- "$GRUB_TEMP_CONFIG" || return 1
    fi

    GRUB_TEMP_CONFIG_OWNED=0
}

prepare_grub_transaction() {
    local configured_directory
    local config_parent
    local canonical_directory
    local canonical_parent
    local config_name

    GRUB_VALIDATION_ERROR=
    GRUB_ACTIVE_CONFIG_EXISTED=0
    GRUB_ACTIVE_CONFIG_FINGERPRINT=
    GRUB_TEMP_CONFIG=
    GRUB_TEMP_CONFIG_OWNED=0
    GRUB_TEMP_DIRECTORY_CANONICAL=

    configured_directory=$GRUB_DIRECTORY
    config_parent=$(dirname -- "$GRUB_CONFIG")
    config_name=${GRUB_CONFIG##*/}

    if [ ! -d "$configured_directory" ] || [ -L "$configured_directory" ]; then
        GRUB_VALIDATION_ERROR="configured GRUB directory is missing or is a symbolic link: $configured_directory"
        return 1
    fi
    if [ ! -d "$config_parent" ] || [ -L "$config_parent" ]; then
        GRUB_VALIDATION_ERROR="GRUB configuration parent is missing or is a symbolic link: $config_parent"
        return 1
    fi

    canonical_directory=$(readlink -e -- "$configured_directory") || {
        GRUB_VALIDATION_ERROR="cannot resolve configured GRUB directory: $configured_directory"
        return 1
    }
    canonical_parent=$(readlink -e -- "$config_parent") || {
        GRUB_VALIDATION_ERROR="cannot resolve GRUB configuration parent: $config_parent"
        return 1
    }

    if [ "$canonical_parent" != "$canonical_directory" ]; then
        GRUB_VALIDATION_ERROR="GRUB configuration is outside the configured GRUB directory: $GRUB_CONFIG"
        return 1
    fi

    if [ -L "$GRUB_CONFIG" ]; then
        GRUB_VALIDATION_ERROR="active GRUB configuration must not be a symbolic link: $GRUB_CONFIG"
        return 1
    fi
    if [ -e "$GRUB_CONFIG" ] && [ ! -f "$GRUB_CONFIG" ]; then
        GRUB_VALIDATION_ERROR="active GRUB configuration is not a regular file: $GRUB_CONFIG"
        return 1
    fi

    if [ -e "$GRUB_CONFIG" ]; then
        GRUB_ACTIVE_CONFIG_EXISTED=1
    fi
    GRUB_ACTIVE_CONFIG_FINGERPRINT=$(grub_config_fingerprint "$GRUB_CONFIG") || {
        GRUB_VALIDATION_ERROR="cannot fingerprint active GRUB configuration: $GRUB_CONFIG"
        return 1
    }

    GRUB_TEMP_CONFIG=$(mktemp -- "$canonical_parent/.${config_name}.slack-update.XXXXXX") || {
        GRUB_VALIDATION_ERROR="cannot create temporary GRUB configuration in: $canonical_parent"
        return 1
    }
    chmod 0600 -- "$GRUB_TEMP_CONFIG" || {
        GRUB_VALIDATION_ERROR="cannot secure temporary GRUB configuration: $GRUB_TEMP_CONFIG"
        rm -f -- "$GRUB_TEMP_CONFIG" 2>/dev/null || true
        GRUB_TEMP_CONFIG=
        return 1
    }

    GRUB_TEMP_CONFIG_OWNED=1
    GRUB_TEMP_DIRECTORY_CANONICAL=$canonical_parent
}

validate_generated_direct_generic_grub_config() {
    local config=$1
    local version=${DIRECT_GENERIC_INSTALLED_KERNEL_VERSION:-}

    [ "${BOOT_PREPARATION_LAYOUT:-unknown}" = direct-generic-no-initrd ] || return 0
    is_safe_kernel_version "$version" || return 1
    [ -f "$config" ] && [ ! -L "$config" ] && [ -r "$config" ] || return 1

    grub_config_references_kernel_path "$config" /boot/vmlinuz-generic         || grub_config_references_kernel_path "$config" "/boot/vmlinuz-$version"
}

validate_generated_grub_config() {
    local validator_status

    GRUB_VALIDATION_STATUS=1

    if [ -z "$GRUB_TEMP_CONFIG" ] || [ -L "$GRUB_TEMP_CONFIG" ] \
        || [ ! -f "$GRUB_TEMP_CONFIG" ] || [ ! -r "$GRUB_TEMP_CONFIG" ]; then
        GRUB_VALIDATION_ERROR="generated GRUB configuration is not a readable regular file"
        return 1
    fi
    if [ ! -s "$GRUB_TEMP_CONFIG" ]; then
        GRUB_VALIDATION_ERROR="generated GRUB configuration is empty"
        return 1
    fi
    if ! chmod 0600 -- "$GRUB_TEMP_CONFIG"; then
        GRUB_VALIDATION_ERROR="cannot secure generated GRUB configuration"
        return 1
    fi
    if ! command -v grub-script-check >/dev/null 2>&1; then
        GRUB_VALIDATION_ERROR="grub-script-check is unavailable"
        return 1
    fi

    grub-script-check "$GRUB_TEMP_CONFIG"
    validator_status=$?
    if [ "$validator_status" -ne 0 ]; then
        GRUB_VALIDATION_STATUS=$validator_status
        GRUB_VALIDATION_ERROR="grub-script-check rejected the generated configuration"
        return "$validator_status"
    fi

    if ! validate_generated_direct_generic_grub_config "$GRUB_TEMP_CONFIG"; then
        GRUB_VALIDATION_STATUS=1
        GRUB_VALIDATION_ERROR="generated GRUB configuration does not reference the validated direct-generic kernel"
        return 1
    fi

    GRUB_VALIDATION_STATUS=0
    GRUB_VALIDATION_ERROR=
    return 0
}

install_validated_grub_config() {
    local current_fingerprint
    local install_status

    GRUB_INSTALL_STATUS=1

    current_fingerprint=$(grub_config_fingerprint "$GRUB_CONFIG") || {
        GRUB_VALIDATION_ERROR="cannot recheck active GRUB configuration before replacement"
        return 1
    }
    if [ "$current_fingerprint" != "$GRUB_ACTIVE_CONFIG_FINGERPRINT" ]; then
        GRUB_VALIDATION_ERROR="active GRUB configuration changed during generation; replacement refused"
        return 1
    fi

    if [ "$GRUB_ACTIVE_CONFIG_EXISTED" -eq 1 ]; then
        chown --reference="$GRUB_CONFIG" -- "$GRUB_TEMP_CONFIG" || {
            GRUB_VALIDATION_ERROR="cannot preserve active GRUB configuration ownership"
            return 1
        }
        chmod --reference="$GRUB_CONFIG" -- "$GRUB_TEMP_CONFIG" || {
            GRUB_VALIDATION_ERROR="cannot preserve active GRUB configuration permissions"
            return 1
        }
    else
        chmod 0600 -- "$GRUB_TEMP_CONFIG" || {
            GRUB_VALIDATION_ERROR="cannot apply secure permissions to new GRUB configuration"
            return 1
        }
    fi

    current_fingerprint=$(grub_config_fingerprint "$GRUB_CONFIG") || {
        GRUB_VALIDATION_ERROR="cannot perform the final active GRUB configuration check"
        return 1
    }
    if [ "$current_fingerprint" != "$GRUB_ACTIVE_CONFIG_FINGERPRINT" ]; then
        GRUB_VALIDATION_ERROR="active GRUB configuration changed before atomic replacement; replacement refused"
        return 1
    fi

    GRUB_REPLACEMENT_ATTEMPTED=1
    mv -fT -- "$GRUB_TEMP_CONFIG" "$GRUB_CONFIG"
    install_status=$?
    if [ "$install_status" -eq 0 ]; then
        GRUB_TEMP_CONFIG_OWNED=0
        GRUB_CONFIG_REPLACED=1
        GRUB_INSTALL_STATUS=0
        return 0
    fi

    GRUB_INSTALL_STATUS=$install_status
    GRUB_VALIDATION_ERROR="atomic GRUB configuration replacement failed"
    return "$install_status"
}

update_grub_configuration() {
    local grub_status

    # ---------------------------
    # [13] GRUB
    # ---------------------------

    GRUB_OK=0
    GRUB_COMMAND_ATTEMPTED=0
    GRUB_BLOCKED_BY_INITRD=0
    GRUB_BLOCK_REASON=
    GRUB_GENERATION_STATUS=-1
    GRUB_VALIDATION_STATUS=-1
    GRUB_VALIDATION_ERROR=
    GRUB_INSTALL_STATUS=-1
    GRUB_REPLACEMENT_ATTEMPTED=0
    GRUB_CONFIG_REPLACED=0
    GRUB_ACTIVE_CONFIG_EXISTED=0
    discard_owned_grub_temporary_config 2>/dev/null || true
    GRUB_TEMP_CONFIG=
    GRUB_TEMP_CONFIG_OWNED=0
    GRUB_TEMP_DIRECTORY_CANONICAL=

    if [ "$GRUB_UPDATE" -eq 1 ]; then
        if ! grub_initrd_prerequisite_is_satisfied; then
            echo "[13] GRUB blocked"
            echo "  [BLOCKED] $GRUB_BLOCK_REASON"
            return 2
        fi

        echo "[13] Actualizando GRUB"

        if ! command -v grub-mkconfig >/dev/null 2>&1; then
            GRUB_VALIDATION_ERROR="grub-mkconfig is unavailable"
            echo "  [ERROR] grub-mkconfig no encontrado"
            return 1
        fi
        if ! command -v grub-script-check >/dev/null 2>&1; then
            GRUB_VALIDATION_ERROR="grub-script-check is unavailable"
            echo "  [ERROR] grub-script-check no encontrado"
            return 1
        fi
        if ! prepare_grub_transaction; then
            echo "  [ERROR] Preparacion segura de GRUB fallida: $GRUB_VALIDATION_ERROR"
            return 1
        fi

        GRUB_COMMAND_ATTEMPTED=1
        if grub-mkconfig -o "$GRUB_TEMP_CONFIG"; then
            GRUB_GENERATION_STATUS=0
        else
            grub_status=$?
            [ "$grub_status" -gt 0 ] || grub_status=1
            GRUB_GENERATION_STATUS=$grub_status
            GRUB_VALIDATION_ERROR="grub-mkconfig failed while generating the temporary configuration"
            echo "  [ERROR] grub-mkconfig fallo"
            discard_owned_grub_temporary_config 2>/dev/null || true
            return "$grub_status"
        fi

        validate_generated_grub_config
        grub_status=$?
        if [ "$grub_status" -ne 0 ]; then
            echo "  [ERROR] Validacion de GRUB fallida: $GRUB_VALIDATION_ERROR"
            discard_owned_grub_temporary_config 2>/dev/null || true
            return "$grub_status"
        fi

        install_validated_grub_config
        grub_status=$?
        if [ "$grub_status" -ne 0 ]; then
            echo "  [ERROR] Instalacion atomica de GRUB fallida: $GRUB_VALIDATION_ERROR"
            discard_owned_grub_temporary_config 2>/dev/null || true
            return "$grub_status"
        fi

        GRUB_OK=1
        echo "  [OK] GRUB generado, validado e instalado atomicamente"
        return 0
    fi

    return 0
}

print_summary() {
    # ---------------------------
    # RESUMEN
    # FIX #10: Eliminados emojis para evitar problemas de encoding en entornos
    # cron sin locale UTF-8. Se sustituyen por marcadores de texto plano.
    # ---------------------------

    echo
    echo "=============================="
    echo "RESUMEN"
    echo "=============================="
    echo

    echo "[PKG] Estado de actualizacion del sistema:"
    echo

    if [ "$PACKAGE_SNAPSHOT_BEFORE_VALID" -eq 1 ]; then
        echo "- Instantanea previa: valida ($PACKAGE_SNAPSHOT_BEFORE_COUNT paquetes)"
    else
        echo "- [ERROR] Instantanea previa: no valida${PACKAGE_SNAPSHOT_BEFORE_ERROR:+ ($PACKAGE_SNAPSHOT_BEFORE_ERROR)}"
    fi

    if [ "$PACKAGE_SNAPSHOT_AFTER_VALID" -eq 1 ]; then
        echo "- Instantanea posterior: valida ($PACKAGE_SNAPSHOT_AFTER_COUNT paquetes)"
    elif [ "$PACKAGE_SNAPSHOT_BEFORE_VALID" -eq 1 ]; then
        echo "- [ERROR] Instantanea posterior: no valida${PACKAGE_SNAPSHOT_AFTER_ERROR:+ ($PACKAGE_SNAPSHOT_AFTER_ERROR)}"
    else
        echo "- Instantanea posterior: no capturada"
    fi

    echo

    echo "- Politica de configuracion post-instalacion: conservar archivos actuales"
    echo "  -> El procesamiento interactivo de slackpkg esta desactivado durante install-new y upgrade-all."
    if [ "$PENDING_NEW_CONFIG_FILES_VALID" -eq 1 ]; then
        echo "  -> Archivos .new pendientes de revision manual: $PENDING_NEW_CONFIG_FILES_COUNT"
        if [ "$PENDING_NEW_CONFIG_FILES_COUNT" -gt 0 ]; then
            while IFS= read -r pending_config || [ -n "$pending_config" ]; do
                echo "    * $pending_config"
            done < "$PENDING_NEW_CONFIG_FILES"
        fi
    else
        echo "  -> [WARN] No se pudo enumerar los archivos .new pendientes${PENDING_NEW_CONFIG_FILES_ERROR:+: $PENDING_NEW_CONFIG_FILES_ERROR}"
    fi

    echo

    if [ "$SECONDARY_MODULES_BLOCKED" -eq 1 ]; then
        echo "- [ERROR] Modulos secundarios bloqueados: $SECONDARY_MODULES_BLOCK_REASON"
        echo "  -> Flatpak, analisis de paquetes, SBo, ELF, Cinnamon y boot no se iniciaron."
        echo
        echo "[MODULES] Modos y estado de activacion:"
        echo
        echo "- Flatpak: mode=$FLATPAK_MODE, state=$FLATPAK_MODULE_STATE"
        echo "- SBo: mode=$SBO_MODE, state=$SBO_MODULE_STATE"
        echo "- ELF: mode=$ELF_MODE, state=$ELF_MODULE_STATE"
        echo "- Cinnamon: mode=$CINNAMON_MODE, state=$CINNAMON_MODULE_STATE"
        echo "- Boot: mode=$BOOT_MODE, state=$BOOT_MODULE_STATE"
        echo
        echo "[CONFIG] Configuracion: $CONFIG_FILE"
        echo "[LOG] Log completo: $LOG"
        echo "[FIN] Finalizacion: $(date)"
        return
    fi

    echo "- Cambios ABI detectados: $ABI_TRIGGER"
    if [ "$ABI_TRIGGER" -eq 1 ]; then
        echo "  -> Se detectaron actualizaciones en librerias criticas del sistema."
        echo "  -> Los paquetes SBo afectados han sido anadidos a la cola de recompilacion."
    else
        echo "  -> No se detectaron cambios en librerias ABI relevantes."
    fi

    echo

    echo "- Recompilacion de Cinnamon: $CINNAMON_TRIGGER"

    if [ "$CINNAMON_TRIGGER" -ne 0 ]; then

        if [ "$CINNAMON_TRIGGER" -eq 2 ]; then
            echo "  -> Cinnamon fue reconstruido correctamente."
        elif [ "$CINNAMON_TRIGGER" -eq 3 ]; then
            echo "  -> Cinnamon requeria reconstruccion pero fallo."
        else
            echo "  -> Cinnamon fue marcado pero no ejecutado correctamente."
        fi

    else
        echo "  -> Cinnamon no requirio recompilacion."
    fi

    echo

    echo "- Cambios de kernel: $KERNEL_TRIGGER"

    if [ "$KERNEL_TRIGGER" -eq 1 ]; then

        echo "  -> Se detecto actualizacion del kernel."

        if [ "$INITRD_REQUIRED" -eq 1 ]; then
            if [ "$INITRD_UPDATE" -eq 0 ]; then
                echo "  -> initrd omitido por el modo del modulo boot ($BOOT_MODE)."
            elif [ "$INITRD_OK" -eq 1 ]; then
                echo "  -> initrd regenerado correctamente."
            else
                echo "  -> initrd requeria regeneracion pero fallo."
                if [ -n "$INITRD_VALIDATION_ERROR" ]; then
                    echo "  -> Validacion: $INITRD_VALIDATION_ERROR"
                fi
            fi
        elif [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ]; then
            echo "  -> Direct generic boot does not require initrd."
            if [ "$DIRECT_GENERIC_VALIDATION_STATUS" -eq 0 ]; then
                echo "  -> Direct kernel and modules validated: $DIRECT_GENERIC_INSTALLED_KERNEL_VERSION."
            elif [ -n "$DIRECT_GENERIC_VALIDATION_ERROR" ]; then
                echo "  -> Direct validation: $DIRECT_GENERIC_VALIDATION_ERROR"
            fi
        fi

        if [ "$GRUB_REQUIRED" -eq 1 ]; then
            if [ "$GRUB_UPDATE" -eq 0 ]; then
                echo "  -> GRUB omitido por el modo del modulo boot ($BOOT_MODE)."
            elif [ "$GRUB_BLOCKED_BY_INITRD" -eq 1 ]; then
                echo "  -> GRUB bloqueado para proteger el arranque: $GRUB_BLOCK_REASON"
            elif [ "$GRUB_OK" -eq 1 ]; then
                echo "  -> GRUB generado en temporal, validado e instalado atomicamente."
            else
                echo "  -> GRUB requeria actualizacion pero fallo."
                if [ -n "${GRUB_VALIDATION_ERROR:-}" ]; then
                    echo "  -> Transaccion GRUB: $GRUB_VALIDATION_ERROR"
                fi
            fi
        fi

        echo "  -> Reinicia el sistema para aplicar el nuevo kernel."

    else
        echo "  -> No hubo cambios en el kernel."
    fi

    if [ "${#CRITICAL_UPDATED[@]}" -gt 0 ]; then
        echo
        echo "- [WARN] Paquetes criticos actualizados que requieren reinicio:"
        for pkg in "${CRITICAL_UPDATED[@]}"; do
            echo "    * $pkg"
        done
        echo "  -> Se recomienda reiniciar el sistema para que los cambios sean efectivos."
    fi

    echo

    echo "[PKG] Estado de colas SBo:"
    echo

    echo "- Cola principal (repositorios SBo):  $TOTAL_CORE paquetes"
    echo "- Opciones SBo preservadas:            $SBO_OPTION_RECORD_COUNT registros"
    echo "- Cola extra (ABI + binarios rotos):  $TOTAL_EXTRA paquetes"
    echo "- Total en cola (enviados a sbopkg):  $TOTAL_EN_COLA paquetes"
    if [ -n "${SBO_PERSONAL_QUEUE_DIR:-}" ]; then
        echo "- Directorio de colas personales:     $SBO_PERSONAL_QUEUE_DIR (solo lectura)"
        echo "- Colas personales copiadas:          $SBO_PERSONAL_QUEUE_FILE_COUNT"
        echo "- Enlaces de cola ignorados:          $SBO_PERSONAL_QUEUE_SYMLINK_COUNT"
    fi
    if [ "${SBO_QUEUE_GENERATION_READY:-0}" -eq 1 ]; then
        echo "- Workspace privado de sqg:           $SBO_GENERATED_QUEUE_DIR (validado)"
    elif [ -n "${SBO_GENERATED_QUEUE_DIR:-}" ]; then
        echo "- Workspace privado de sqg:           no validado"
    fi

    echo

    echo "[SYS] Diagnostico del sistema:"
    echo
    echo "- Resolucion ELF por arquitectura: clase + datos + maquina"
    echo "- Registros ELF compatibles en cache: ${ELF_LIBRARY_CACHE_RECORD_COUNT:-0}"

    if [ -s "$BROKEN" ]; then
        echo "- [WARN] Binarios con librerias rotas tras recompilacion: $(wc -l < "$BROKEN")"
        echo "  -> Estos binarios siguen rotos y requieren atencion manual:"
        sed 's/^/      /' "$BROKEN"
    else
        echo "- [OK] No se detectaron binarios con librerias rotas (o todos fueron reparados)."
    fi

    echo

    echo "[MODULES] Modos y estado de activacion:"
    echo
    echo "- Flatpak: mode=$FLATPAK_MODE, state=$FLATPAK_MODULE_STATE"
    echo "- SBo: mode=$SBO_MODE, state=$SBO_MODULE_STATE"
    echo "- ELF: mode=$ELF_MODE, state=$ELF_MODULE_STATE"
    echo "- Cinnamon: mode=$CINNAMON_MODE, state=$CINNAMON_MODULE_STATE"
    echo "- Boot: mode=$BOOT_MODE, state=$BOOT_MODULE_STATE"

    echo

    echo "[CONFIG] Configuracion: $CONFIG_FILE"
    echo "[LOG] Log completo: $LOG"
    echo "[FIN] Finalizacion: $(date)"
}

# Structured result functions

json_escape() {
    local value=${1-}

    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\b'/\\b}
    value=${value//$'\f'/\\f}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}

    printf '%s' "$value"
}

json_string() {
    printf '"%s"' "$(json_escape "${1-}")"
}

json_boolean() {
    if [ "$1" -eq 1 ]; then
        printf 'true'
    else
        printf 'false'
    fi
}

json_nullable_status() {
    if [ "$1" -lt 0 ]; then
        printf 'null'
    else
        printf '%d' "$1"
    fi
}

json_status_state() {
    case "$1" in
        -1)
            printf 'skipped'
            ;;
        0)
            printf 'success'
            ;;
        *)
            printf 'failed'
            ;;
    esac
}

json_string_array() {
    local first=1
    local item

    printf '['
    for item in "$@"; do
        if [ "$first" -eq 0 ]; then
            printf ', '
        fi
        json_string "$item"
        first=0
    done
    printf ']'
}

json_string_array_from_file() {
    local path=$1
    local first=1
    local item

    printf '['
    if [ -f "$path" ]; then
        while IFS= read -r item || [ -n "$item" ]; do
            if [ "$first" -eq 0 ]; then
                printf ', '
            fi
            json_string "$item"
            first=0
        done < "$path"
    fi
    printf ']'
}

json_sbo_option_records_from_file() {
    local path=$1
    local first=1
    local target
    local options

    printf '['
    if [ -f "$path" ]; then
        while IFS=$'	' read -r target options; do
            [ -n "$target" ] || continue
            if [ "$first" -eq 0 ]; then
                printf ', '
            fi
            printf '{"target":'
            json_string "$target"
            printf ',"options":'
            json_string "$options"
            printf '}'
            first=0
        done < "$path"
    fi
    printf ']'
}

# Machine-readable progress event functions

emit_event() {
    local type=$1
    local module=${2-}
    local action=${3-}
    local state=${4-}
    local message=${5-}
    local exit_code=${6-}

    [ "$EVENTS_OUTPUT" -eq 1 ] || return 0

    EVENT_SEQUENCE=$((EVENT_SEQUENCE + 1))

    printf '{' >&3
    printf '"schema_version":0,' >&3
    printf '"schema_status":"provisional",' >&3
    printf '"sequence":%d,' "$EVENT_SEQUENCE" >&3
    printf '"timestamp":' >&3; json_string "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >&3; printf ',' >&3
    printf '"operation":' >&3; json_string "$OPERATION" >&3; printf ',' >&3
    printf '"type":' >&3; json_string "$type" >&3; printf ',' >&3

    printf '"module":' >&3
    if [ -n "$module" ]; then
        json_string "$module" >&3
    else
        printf 'null' >&3
    fi
    printf ',' >&3

    printf '"action":' >&3
    if [ -n "$action" ]; then
        json_string "$action" >&3
    else
        printf 'null' >&3
    fi
    printf ',' >&3

    printf '"state":' >&3
    if [ -n "$state" ]; then
        json_string "$state" >&3
    else
        printf 'null' >&3
    fi
    printf ',' >&3

    printf '"message":' >&3; json_string "$message" >&3; printf ',' >&3
    printf '"exit_code":' >&3
    if [ -n "$exit_code" ]; then
        printf '%d' "$exit_code" >&3
    else
        printf 'null' >&3
    fi
    printf '}\n' >&3
}

emit_operation_started_event() {
    emit_event operation_started '' '' running "Operation started" ''
}

emit_module_started_event() {
    emit_event module_started "$1" '' running "$2" ''
}

emit_module_completed_event() {
    emit_event module_completed "$1" '' "$2" "$3" "${4-}"
}

emit_action_started_event() {
    emit_event action_started "$1" "$2" running "$3" ''
}

emit_action_completed_event() {
    emit_event action_completed "$1" "$2" "$3" "$4" "${5-}"
}

emit_final_events() {
    local stable_exit_code=$1
    local warning
    local error
    local final_state=failed

    for warning in "${RESULT_WARNINGS[@]}"; do
        emit_event warning '' '' warning "$warning" ''
    done

    for error in "${RESULT_ERRORS[@]}"; do
        emit_event error '' '' failed "$error" ''
    done

    if [ "$RESULT_SUCCESS" -eq 1 ]; then
        final_state=success
    elif [ "$RESULT_BOOT_SAFE" -eq 1 ] && [ "$RESULT_PARTIAL" -eq 1 ]; then
        final_state=warning
    fi

    emit_event operation_completed '' '' "$final_state" \
        "Operation completed: $(stable_exit_code_description "$stable_exit_code")" \
        "$stable_exit_code"
}

append_enabled_module_requirement_errors() {
    if [ "$FLATPAK_MODE" = enabled ] && [ "$FLATPAK_MODULE_STATE" = unavailable ]; then
        RESULT_ERRORS+=("Flatpak module is enabled but unavailable: $FLATPAK_MODULE_REASON")
    fi
    if [ "$SBO_MODE" = enabled ] && [ "$SBO_MODULE_STATE" = unavailable ]; then
        RESULT_ERRORS+=("SBo module is enabled but unavailable: $SBO_MODULE_REASON")
    fi
    if [ "$ELF_MODE" = enabled ] && [ "$ELF_MODULE_STATE" = unavailable ]; then
        RESULT_ERRORS+=("ELF module is enabled but unavailable: $ELF_MODULE_REASON")
    fi
    if [ "$CINNAMON_MODE" = enabled ] && [ "$CINNAMON_MODULE_STATE" = unavailable ]; then
        RESULT_ERRORS+=("Cinnamon module is enabled but unavailable: $CINNAMON_MODULE_REASON")
    fi
    if [ "$BOOT_MODE" = enabled ] && [ "$BOOT_MODULE_STATE" = unavailable ]; then
        RESULT_ERRORS+=("Boot module is enabled but unavailable: $BOOT_MODULE_REASON")
    fi
}

prepare_json_messages() {
    RESULT_WARNINGS=()
    RESULT_ERRORS=()

    case "$OPERATION" in
        check)
            if [ "$CHECK_STATUS" -ne 0 ] && [ "$CHECK_STATUS" -ne 100 ]; then
                RESULT_ERRORS+=("slackpkg check-updates failed with exit code $CHECK_STATUS")
            fi
            ;;
        dry-run)
            if [ "$CHECK_STATUS" -ne 0 ] && [ "$CHECK_STATUS" -ne 100 ]; then
                RESULT_ERRORS+=("slackpkg check-updates failed with exit code $CHECK_STATUS")
            fi
            append_enabled_module_requirement_errors
            [ "$SBO_TARGET_SELECTION_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("SBo target selection failed: ${SBO_TARGET_SELECTION_ERROR:-unknown selection failure}")
            RESULT_WARNINGS+=("Exact Slackware package changes remain unresolved until package metadata is refreshed during apply")
            ;;
        apply)
            append_enabled_module_requirement_errors
            if [ "$PACKAGE_SNAPSHOT_BEFORE_VALID" -ne 1 ]; then
                RESULT_ERRORS+=("Package snapshot before update is invalid: ${PACKAGE_SNAPSHOT_BEFORE_ERROR:-unknown validation failure}")
            elif [ "$PACKAGE_SNAPSHOT_AFTER_VALID" -ne 1 ]; then
                RESULT_ERRORS+=("Package snapshot after update is invalid: ${PACKAGE_SNAPSHOT_AFTER_ERROR:-unknown validation failure}")
            fi
            slackpkg_apply_action_failed update "$SLACKPKG_UPDATE_STATUS" \
                && RESULT_ERRORS+=("slackpkg update failed with exit code $SLACKPKG_UPDATE_STATUS")
            slackpkg_apply_action_failed install-new "$SLACKPKG_INSTALL_NEW_STATUS" \
                && RESULT_ERRORS+=("slackpkg install-new failed with exit code $SLACKPKG_INSTALL_NEW_STATUS")
            slackpkg_apply_action_failed upgrade-all "$SLACKPKG_UPGRADE_ALL_STATUS" \
                && RESULT_ERRORS+=("slackpkg upgrade-all failed with exit code $SLACKPKG_UPGRADE_ALL_STATUS")
            if [ "$PENDING_NEW_CONFIG_FILES_VALID" -ne 1 ]; then
                RESULT_WARNINGS+=("Pending Slackware .new configuration files could not be enumerated: ${PENDING_NEW_CONFIG_FILES_ERROR:-unknown scan failure}")
            elif [ "$PENDING_NEW_CONFIG_FILES_COUNT" -gt 0 ]; then
                RESULT_WARNINGS+=("$PENDING_NEW_CONFIG_FILES_COUNT pending Slackware .new configuration file(s) require manual review")
            fi
            [ "$FLATPAK_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("flatpak update failed with exit code $FLATPAK_STATUS")
            [ "$SBOPKG_SYNC_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("sbopkg repository synchronization failed with exit code $SBOPKG_SYNC_STATUS")
            [ "$SQG_SYNC_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("sqg queue generation failed with exit code $SQG_SYNC_STATUS")
            [ "$SBO_TARGET_SELECTION_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("SBo target selection failed: ${SBO_TARGET_SELECTION_ERROR:-unknown selection failure}")
            [ "$SBO_BUILD_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("sbopkg queue processing failed with exit code $SBO_BUILD_STATUS")
            [ "$CINNAMON_TRIGGER" -eq 3 ] \
                && RESULT_ERRORS+=("Cinnamon required rebuilding but the rebuild failed")
            if [ "$INITRD_UPDATE" -eq 1 ] && [ "$INITRD_OK" -ne 1 ]; then
                if [ -n "$INITRD_VALIDATION_ERROR" ]; then
                    RESULT_ERRORS+=("initrd preparation failed validation: $INITRD_VALIDATION_ERROR")
                else
                    RESULT_ERRORS+=("initrd preparation was required but did not complete successfully")
                fi
            fi
            if [ "$GRUB_BLOCKED_BY_INITRD" -eq 1 ]; then
                RESULT_ERRORS+=("GRUB configuration generation was blocked to protect boot safety: $GRUB_BLOCK_REASON")
            elif [ "$GRUB_UPDATE" -eq 1 ] && [ "$GRUB_OK" -ne 1 ]; then
                if [ -n "${GRUB_VALIDATION_ERROR:-}" ]; then
                    RESULT_ERRORS+=("GRUB configuration transaction failed: $GRUB_VALIDATION_ERROR")
                else
                    RESULT_ERRORS+=("GRUB configuration generation was required but did not complete successfully")
                fi
            fi
            if [ "$ELF_MODULE_RUN" -eq 1 ] && [ -s "$BROKEN" ]; then
                RESULT_ERRORS+=("ELF dependency verification still reports broken objects")
            fi
            if [ "${#CRITICAL_UPDATED[@]}" -gt 0 ]; then
                RESULT_WARNINGS+=("Critical system packages were updated; a reboot is recommended")
            fi
            ;;
    esac
}

calculate_result_state() {
    local workflow_result=$1

    RESULT_SUCCESS=1
    RESULT_PARTIAL=0
    RESULT_BOOT_SAFE=1
    RESULT_REBOOT=none

    if [ "$workflow_result" -ne 0 ] || [ "${#RESULT_ERRORS[@]}" -gt 0 ]; then
        RESULT_SUCCESS=0
    fi

    if [ "$OPERATION" = apply ]; then
        if [ "$workflow_result" -ne 0 ] || [ "${#RESULT_ERRORS[@]}" -gt 0 ]; then
            RESULT_PARTIAL=1
        fi

        if { [ "$INITRD_UPDATE" -eq 1 ] && [ "$INITRD_OK" -ne 1 ]; } \
            || { [ "$GRUB_UPDATE" -eq 1 ] && [ "$GRUB_OK" -ne 1 ]; }; then
            RESULT_SUCCESS=0
            RESULT_PARTIAL=1
            RESULT_BOOT_SAFE=0
            RESULT_REBOOT=unsafe
        elif [ "$INITRD_REQUIRED" -eq 1 ] || [ "$GRUB_REQUIRED" -eq 1 ]; then
            RESULT_REBOOT=required
        elif [ "${#CRITICAL_UPDATED[@]}" -gt 0 ]; then
            RESULT_REBOOT=recommended
        fi
    fi
}

determine_stable_exit_code() {
    local workflow_result=$1

    prepare_json_messages
    calculate_result_state "$workflow_result"

    case "$OPERATION" in
        check|dry-run)
            if [ "$RESULT_SUCCESS" -eq 1 ]; then
                STABLE_EXIT_CODE=$EXIT_SUCCESS
            else
                STABLE_EXIT_CODE=$EXIT_GENERAL_FAILURE
            fi
            ;;
        apply)
            if [ "$RESULT_BOOT_SAFE" -eq 0 ]; then
                STABLE_EXIT_CODE=$EXIT_BOOT_UNSAFE
            elif [ "$RESULT_SUCCESS" -eq 0 ]; then
                STABLE_EXIT_CODE=$EXIT_PARTIAL
            elif [ "$RESULT_REBOOT" = required ]; then
                STABLE_EXIT_CODE=$EXIT_REBOOT_REQUIRED
            elif [ "$RESULT_REBOOT" = recommended ]; then
                STABLE_EXIT_CODE=$EXIT_REBOOT_RECOMMENDED
            else
                STABLE_EXIT_CODE=$EXIT_SUCCESS
            fi
            ;;
    esac
}

stable_exit_code_description() {
    case "$1" in
        0) printf '%s' 'success; no reboot required' ;;
        1) printf '%s' 'general failure' ;;
        2) printf '%s' 'partial update or verification failure' ;;
        3) printf '%s' 'critical boot preparation failure; do not reboot' ;;
        4) printf '%s' 'success; reboot recommended' ;;
        5) printf '%s' 'success; reboot required' ;;
        6) printf '%s' 'another instance is already running' ;;
        7) printf '%s' 'invalid configuration or command-line arguments' ;;
        8) printf '%s' 'required privilege was denied or unavailable' ;;
        *) printf '%s' 'unknown exit status' ;;
    esac
}

print_stable_exit_code_summary() {
    local stable_exit_code=$1

    echo
    echo "[EXIT] Stable exit code: $stable_exit_code ($(stable_exit_code_description "$stable_exit_code"))"
}

print_check_json_module() {
    local state=failed
    local updates_available=null

    if [ "$CHECK_STATUS" -eq 0 ]; then
        state=success
        updates_available=false
    elif [ "$CHECK_STATUS" -eq 100 ]; then
        state=success
        updates_available=true
    fi

    printf '    "slackware": {\n'
    printf '      "state": '; json_string "$state"; printf ',\n'
    printf '      "check_exit_code": %d,\n' "$CHECK_STATUS"
    printf '      "updates_available": %s\n' "$updates_available"
    printf '    }\n'
}

print_dry_run_json_modules() {
    local slackware_state=failed
    local updates_available=null

    if [ "$CHECK_STATUS" -eq 0 ]; then
        slackware_state=success
        updates_available=false
    elif [ "$CHECK_STATUS" -eq 100 ]; then
        slackware_state=success
        updates_available=true
    fi

    printf '    "slackware": {\n'
    printf '      "state": '; json_string "$slackware_state"; printf ',\n'
    printf '      "check_exit_code": %d,\n' "$CHECK_STATUS"
    printf '      "updates_available": %s,\n' "$updates_available"
    printf '      "planned_commands": ['
    json_string 'slackpkg -batch=on -default_answer=y update'
    if [ "$SLACKWARE_INSTALL_NEW" = true ]; then
        printf ', '; json_string 'slackpkg -batch=on -default_answer=y -postinst=off install-new'
    fi
    if [ "$SLACKWARE_UPGRADE_ALL" = true ]; then
        printf ', '; json_string 'slackpkg -batch=on -default_answer=y -postinst=off upgrade-all'
    fi
    printf ']\n'
    printf '    },\n'

    printf '    "flatpak": {\n'
    printf '      "mode": '; json_string "$FLATPAK_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$FLATPAK_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$FLATPAK_MODULE_REASON"; printf ',\n'
    printf '      "available": '; json_boolean "$PLAN_FLATPAK_AVAILABLE"; printf ',\n'
    printf '      "would_update": '; json_boolean "$FLATPAK_MODULE_RUN"; printf '\n'
    printf '    },\n'

    printf '    "sbo": {\n'
    printf '      "mode": '; json_string "$SBO_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$SBO_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$SBO_MODULE_REASON"; printf ',\n'
    printf '      "sbopkg_available": '; json_boolean "$PLAN_SBOPKG_AVAILABLE"; printf ',\n'
    printf '      "sqg_available": '; json_boolean "$PLAN_SQG_AVAILABLE"; printf ',\n'
    printf '      "queue_directory": '; json_string "$SBODIR"; printf ',\n'
    printf '      "personal_queue_directory": '; json_string "${SBO_PERSONAL_QUEUE_DIR:-$SBODIR}"; printf ',\n'
    printf '      "queue_workspace_isolated": true,\n'
    printf '      "options_file": '; json_string "${SBO_OPTIONS_FILE:-}"; printf ',\n'
    printf '      "build_option_record_count": %d,\n' "${SBO_OPTION_RECORD_COUNT:-0}"
    printf '      "build_options": '; json_sbo_option_records_from_file "${SBO_OPTION_RECORDS:-}"; printf ',\n'
    printf '      "target_selection_exit_code": '; json_nullable_status "$SBO_TARGET_SELECTION_STATUS"; printf ',\n'
    printf '      "target_selection_error": '; json_string "$SBO_TARGET_SELECTION_ERROR"; printf ',\n'
    printf '      "current_queue_targets": '; json_string_array_from_file "$QUEUE_CORE"; printf ',\n'
    printf '      "abi_rebuild_candidates": '; json_string_array_from_file "$ABI_CANDIDATES"; printf ',\n'
    printf '      "broken_elf_targets": '; json_string_array_from_file "$QUEUE_EXTRA"; printf '\n'
    printf '    },\n'

    printf '    "elf": {\n'
    printf '      "mode": '; json_string "$ELF_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$ELF_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$ELF_MODULE_REASON"; printf ',\n'
    printf '      "inspection_method": '; json_string 'readelf+ldconfig-cache'; printf ',\n'
    printf '      "executes_inspected_objects": false,\n'
    printf '      "architecture_specific_resolution": true,\n'
    printf '      "architecture_match_fields": ["class", "data", "machine"],\n'
    printf '      "library_cache_records": %d,\n' "${ELF_LIBRARY_CACHE_RECORD_COUNT:-0}"
    printf '      "readelf_available": '; json_boolean "$PLAN_READELF_AVAILABLE"; printf ',\n'
    printf '      "ldconfig_available": '; json_boolean "$ELF_LDCONFIG_AVAILABLE"; printf ',\n'
    printf '      "scan_exit_code": '; json_nullable_status "$ELF_SCAN_STATUS"; printf ',\n'
    printf '      "broken_objects": '; json_string_array_from_file "$BROKEN"; printf '\n'
    printf '    },\n'

    printf '    "cinnamon": {\n'
    printf '      "mode": '; json_string "$CINNAMON_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$CINNAMON_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$CINNAMON_MODULE_REASON"; printf ',\n'
    printf '      "installation_detected": '; json_boolean "$CINNAMON_INSTALLED"; printf ',\n'
    printf '      "repository_available": '; json_boolean "$PLAN_CINNAMON_REPOSITORY"; printf ',\n'
    printf '      "builder_available": '; json_boolean "$PLAN_CINNAMON_BUILDER"; printf '\n'
    printf '    },\n'

    printf '    "boot": {\n'
    printf '      "mode": '; json_string "$BOOT_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$BOOT_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$BOOT_MODULE_REASON"; printf ',\n'
    printf '      "mkinitrd_available": '; json_boolean "$PLAN_MKINITRD_AVAILABLE"; printf ',\n'
    printf '      "mkinitrd_configured": '; json_boolean "$PLAN_MKINITRD_CONFIGURED"; printf ',\n'
    printf '      "kernel_version_source": '; json_string 'post-update-package-snapshot'; printf ',\n'
    printf '      "kernel_package": '; json_string "${INITRD_KERNEL_PACKAGE:-}"; printf ',\n'
    printf '      "modules_directory": '; json_string "${KERNEL_MODULES_DIRECTORY:-}"; printf ',\n'
    printf '      "kernel_validation_deferred_until_apply": true,\n'
    printf '      "grub_generator_available": '; json_boolean "$PLAN_GRUB_AVAILABLE"; printf ',\n'
    printf '      "grub_validator_available": '; json_boolean "$PLAN_GRUB_VALIDATOR_AVAILABLE"; printf ',\n'
    printf '      "grub_configured": '; json_boolean "$PLAN_GRUB_CONFIGURED"; printf ',\n'
    printf '      "grub_active_config": '; json_string "${GRUB_CONFIG:-}"; printf ',\n'
    printf '      "grub_temporary_generation": true,\n'
    printf '      "grub_validator": '; json_string 'grub-script-check'; printf ',\n'
    printf '      "grub_atomic_replacement": true\n'
    printf '    }\n'
}

print_apply_json_modules() {
    local slackware_state=success
    local flatpak_state
    local sbo_state=success
    local elf_state=success
    local cinnamon_state=not-required
    local boot_state=not-required
    local initrd_state=not-required
    local grub_state=not-required

    if [ "$PACKAGE_SNAPSHOT_BEFORE_VALID" -ne 1 ] \
        || [ "$PACKAGE_SNAPSHOT_AFTER_VALID" -ne 1 ] \
        || slackpkg_apply_action_failed update "$SLACKPKG_UPDATE_STATUS" \
        || slackpkg_apply_action_failed install-new "$SLACKPKG_INSTALL_NEW_STATUS" \
        || slackpkg_apply_action_failed upgrade-all "$SLACKPKG_UPGRADE_ALL_STATUS"; then
        slackware_state=failed
    fi

    if [ "$FLATPAK_MODULE_RUN" -eq 1 ]; then
        flatpak_state=$(json_status_state "$FLATPAK_STATUS")
    else
        flatpak_state=$FLATPAK_MODULE_STATE
    fi

    if [ "$SBO_MODULE_RUN" -eq 0 ]; then
        sbo_state=$SBO_MODULE_STATE
    elif [ "$SBOPKG_SYNC_STATUS" -gt 0 ] || [ "$SQG_SYNC_STATUS" -gt 0 ] \
        || [ "$SBO_TARGET_SELECTION_STATUS" -gt 0 ] || [ "$SBO_BUILD_STATUS" -gt 0 ]; then
        sbo_state=failed
    fi

    if [ "$ELF_MODULE_RUN" -eq 0 ]; then
        elf_state=$ELF_MODULE_STATE
    elif [ -s "$BROKEN" ]; then
        elf_state=warning
    fi

    if [ "$CINNAMON_MODULE_RUN" -eq 0 ]; then
        cinnamon_state=$CINNAMON_MODULE_STATE
    else
        case "$CINNAMON_TRIGGER" in
            0) cinnamon_state=not-required ;;
            1) cinnamon_state=incomplete ;;
            2) cinnamon_state=success ;;
            3) cinnamon_state=failed ;;
        esac
    fi

    if [ "$INITRD_REQUIRED" -eq 1 ]; then
        if [ "$INITRD_UPDATE" -eq 0 ]; then
            if [ "$BOOT_MODE" = disabled ]; then
                initrd_state=disabled
            else
                initrd_state=unavailable
            fi
        elif [ "$INITRD_OK" -eq 1 ]; then
            initrd_state=success
        else
            initrd_state=failed
        fi
    fi

    if [ "$GRUB_REQUIRED" -eq 1 ]; then
        if [ "$GRUB_UPDATE" -eq 0 ]; then
            if [ "$BOOT_MODE" = disabled ]; then
                grub_state=disabled
            else
                grub_state=unavailable
            fi
        elif [ "$GRUB_BLOCKED_BY_INITRD" -eq 1 ]; then
            grub_state=blocked
        elif [ "$GRUB_OK" -eq 1 ]; then
            grub_state=success
        else
            grub_state=failed
        fi
    fi

    if [ "$SECONDARY_MODULES_BLOCKED" -eq 1 ]; then
        boot_state=blocked
        initrd_state=blocked
        grub_state=blocked
    elif [ "$INITRD_REQUIRED" -eq 0 ] && [ "$GRUB_REQUIRED" -eq 0 ]; then
        boot_state=not-required
    elif [ "$initrd_state" = failed ] || [ "$grub_state" = failed ] \
        || [ "$grub_state" = blocked ]; then
        boot_state=failed
    elif [ "$initrd_state" = success ] || [ "$grub_state" = success ]; then
        boot_state=success
    else
        boot_state=$BOOT_MODULE_STATE
    fi

    printf '    "slackware": {\n'
    printf '      "state": '; json_string "$slackware_state"; printf ',\n'
    printf '      "update_exit_code": '; json_nullable_status "$SLACKPKG_UPDATE_STATUS"; printf ',\n'
    printf '      "install_new_exit_code": '; json_nullable_status "$SLACKPKG_INSTALL_NEW_STATUS"; printf ',\n'
    printf '      "upgrade_all_exit_code": '; json_nullable_status "$SLACKPKG_UPGRADE_ALL_STATUS"; printf ',\n'
    printf '      "postinstall_policy": '; json_string "$SLACKPKG_POSTINST_POLICY"; printf ',\n'
    printf '      "postinstall_processing_enabled": false,\n'
    printf '      "pending_new_config_files_valid": '; json_boolean "$PENDING_NEW_CONFIG_FILES_VALID"; printf ',\n'
    printf '      "pending_new_config_files_count": %d,\n' "$PENDING_NEW_CONFIG_FILES_COUNT"
    printf '      "pending_new_config_files_error": '; json_string "$PENDING_NEW_CONFIG_FILES_ERROR"; printf ',\n'
    printf '      "pending_new_config_files": '; json_string_array_from_file "${PENDING_NEW_CONFIG_FILES:-}"; printf ',\n'
    printf '      "snapshot_before_valid": '; json_boolean "$PACKAGE_SNAPSHOT_BEFORE_VALID"; printf ',\n'
    printf '      "snapshot_before_records": %d,\n' "$PACKAGE_SNAPSHOT_BEFORE_COUNT"
    printf '      "snapshot_before_error": '; json_string "$PACKAGE_SNAPSHOT_BEFORE_ERROR"; printf ',\n'
    printf '      "snapshot_after_valid": '; json_boolean "$PACKAGE_SNAPSHOT_AFTER_VALID"; printf ',\n'
    printf '      "snapshot_after_records": %d,\n' "$PACKAGE_SNAPSHOT_AFTER_COUNT"
    printf '      "snapshot_after_error": '; json_string "$PACKAGE_SNAPSHOT_AFTER_ERROR"; printf ',\n'
    printf '      "secondary_modules_blocked": '; json_boolean "$SECONDARY_MODULES_BLOCKED"; printf ',\n'
    printf '      "secondary_modules_block_reason": '; json_string "$SECONDARY_MODULES_BLOCK_REASON"; printf ',\n'
    printf '      "abi_changes": '; json_boolean "$ABI_TRIGGER"; printf ',\n'
    printf '      "kernel_changes": '; json_boolean "$KERNEL_TRIGGER"; printf ',\n'
    printf '      "critical_packages": '; json_string_array "${CRITICAL_UPDATED[@]}"; printf '\n'
    printf '    },\n'

    printf '    "flatpak": {\n'
    printf '      "mode": '; json_string "$FLATPAK_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$FLATPAK_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$FLATPAK_MODULE_REASON"; printf ',\n'
    printf '      "state": '; json_string "$flatpak_state"; printf ',\n'
    printf '      "exit_code": '; json_nullable_status "$FLATPAK_STATUS"; printf '\n'
    printf '    },\n'

    printf '    "sbo": {\n'
    printf '      "mode": '; json_string "$SBO_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$SBO_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$SBO_MODULE_REASON"; printf ',\n'
    printf '      "state": '; json_string "$sbo_state"; printf ',\n'
    printf '      "sync_exit_code": '; json_nullable_status "$SBOPKG_SYNC_STATUS"; printf ',\n'
    printf '      "queue_generation_exit_code": '; json_nullable_status "$SQG_SYNC_STATUS"; printf ',\n'
    printf '      "personal_queue_directory": '; json_string "${SBO_PERSONAL_QUEUE_DIR:-}"; printf ',\n'
    printf '      "generated_queue_workspace": '; json_string "${SBO_GENERATED_QUEUE_DIR:-}"; printf ',\n'
    printf '      "queue_workspace_isolated": true,\n'
    printf '      "private_queue_generation_ready": '; json_boolean "${SBO_QUEUE_GENERATION_READY:-0}"; printf ',\n'
    printf '      "personal_queue_files_copied": %d,\n' "${SBO_PERSONAL_QUEUE_FILE_COUNT:-0}"
    printf '      "personal_queue_symlinks_ignored": %d,\n' "${SBO_PERSONAL_QUEUE_SYMLINK_COUNT:-0}"
    printf '      "options_file": '; json_string "${SBO_OPTIONS_FILE:-}"; printf ',\n'
    printf '      "build_option_record_count": %d,\n' "${SBO_OPTION_RECORD_COUNT:-0}"
    printf '      "build_options": '; json_sbo_option_records_from_file "${SBO_OPTION_RECORDS:-}"; printf ',\n'
    printf '      "target_selection_exit_code": '; json_nullable_status "$SBO_TARGET_SELECTION_STATUS"; printf ',\n'
    printf '      "target_selection_error": '; json_string "$SBO_TARGET_SELECTION_ERROR"; printf ',\n'
    printf '      "build_exit_code": '; json_nullable_status "$SBO_BUILD_STATUS"; printf ',\n'
    printf '      "core_queue_count": %d,\n' "$TOTAL_CORE"
    printf '      "extra_queue_count": %d,\n' "$TOTAL_EXTRA"
    printf '      "submitted_queue_count": %d\n' "$TOTAL_EN_COLA"
    printf '    },\n'

    printf '    "elf": {\n'
    printf '      "mode": '; json_string "$ELF_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$ELF_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$ELF_MODULE_REASON"; printf ',\n'
    printf '      "state": '; json_string "$elf_state"; printf ',\n'
    printf '      "inspection_method": '; json_string 'readelf+ldconfig-cache'; printf ',\n'
    printf '      "executes_inspected_objects": false,\n'
    printf '      "architecture_specific_resolution": true,\n'
    printf '      "architecture_match_fields": ["class", "data", "machine"],\n'
    printf '      "library_cache_records": %d,\n' "${ELF_LIBRARY_CACHE_RECORD_COUNT:-0}"
    printf '      "scan_exit_code": '; json_nullable_status "$ELF_SCAN_STATUS"; printf ',\n'
    printf '      "verification_exit_code": '; json_nullable_status "$ELF_VERIFICATION_STATUS"; printf ',\n'
    printf '      "broken_objects": '; json_string_array_from_file "$BROKEN"; printf '\n'
    printf '    },\n'

    printf '    "cinnamon": {\n'
    printf '      "mode": '; json_string "$CINNAMON_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$CINNAMON_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$CINNAMON_MODULE_REASON"; printf ',\n'
    printf '      "state": '; json_string "$cinnamon_state"; printf '\n'
    printf '    },\n'

    printf '    "boot": {\n'
    printf '      "mode": '; json_string "$BOOT_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$BOOT_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$BOOT_MODULE_REASON"; printf ',\n'
    printf '      "state": '; json_string "$boot_state"; printf ',\n'
    printf '      "preparation_layout": '; json_string "${BOOT_PREPARATION_LAYOUT:-unknown}"; printf ',\n'
    printf '      "direct_generic_available": '; json_boolean "${BOOT_DIRECT_GENERIC_AVAILABLE:-0}"; printf ',\n'
    printf '      "direct_generic_reason": '; json_string "${BOOT_DIRECT_GENERIC_REASON:-}"; printf ',\n'
    printf '      "direct_generic_boot_image": '; json_string "${BOOT_DIRECT_GENERIC_BOOT_IMAGE:-}"; printf ',\n'
    printf '      "direct_generic_running_kernel_path": '; json_string "${BOOT_DIRECT_GENERIC_KERNEL_PATH:-}"; printf ',\n'
    printf '      "direct_generic_validation_exit_code": '; json_nullable_status "${DIRECT_GENERIC_VALIDATION_STATUS:--1}"; printf ',\n'
    printf '      "direct_generic_validation_error": '; json_string "${DIRECT_GENERIC_VALIDATION_ERROR:-}"; printf ',\n'
    printf '      "direct_generic_installed_kernel_version": '; json_string "${DIRECT_GENERIC_INSTALLED_KERNEL_VERSION:-}"; printf ',\n'
    printf '      "direct_generic_installed_kernel_records": %d,\n' "${DIRECT_GENERIC_INSTALLED_KERNEL_RECORD_COUNT:-0}"
    printf '      "direct_generic_kernel_path": '; json_string "${DIRECT_GENERIC_KERNEL_PATH:-}"; printf ',\n'
    printf '      "direct_generic_modules_path": '; json_string "${DIRECT_GENERIC_MODULES_PATH:-}"; printf ',\n'
    printf '      "initrd_required": '; json_boolean "$INITRD_REQUIRED"; printf ',\n'
    printf '      "initrd_state": '; json_string "$initrd_state"; printf ',\n'
    printf '      "kernel_version_source": '; json_string 'post-update-package-snapshot'; printf ',\n'
    printf '      "kernel_package": '; json_string "${INITRD_KERNEL_PACKAGE:-}"; printf ',\n'
    printf '      "configured_kernel_version": '; json_string "${INITRD_CONFIGURED_KERNEL_VERSION:-}"; printf ',\n'
    printf '      "installed_kernel_version": '; json_string "${INITRD_INSTALLED_KERNEL_VERSION:-}"; printf ',\n'
    printf '      "installed_kernel_records": %d,\n' "${INITRD_INSTALLED_KERNEL_RECORD_COUNT:-0}"
    printf '      "modules_directory": '; json_string "${KERNEL_MODULES_DIRECTORY:-}"; printf ',\n'
    printf '      "installed_modules_path": '; json_string "${INITRD_MODULES_PATH:-}"; printf ',\n'
    printf '      "initrd_output": '; json_string "${INITRD_OUTPUT_PATH:-}"; printf ',\n'
    printf '      "initrd_validation_exit_code": '; json_nullable_status "${INITRD_VALIDATION_STATUS:--1}"; printf ',\n'
    printf '      "initrd_validation_error": '; json_string "${INITRD_VALIDATION_ERROR:-}"; printf ',\n'
    printf '      "grub_required": '; json_boolean "$GRUB_REQUIRED"; printf ',\n'
    printf '      "grub_state": '; json_string "$grub_state"; printf ',\n'
    printf '      "grub_command_attempted": '; json_boolean "${GRUB_COMMAND_ATTEMPTED:-0}"; printf ',\n'
    printf '      "grub_active_config": '; json_string "${GRUB_CONFIG:-}"; printf ',\n'
    printf '      "grub_temporary_config": '; json_string "${GRUB_TEMP_CONFIG:-}"; printf ',\n'
    printf '      "grub_generation_exit_code": '; json_nullable_status "${GRUB_GENERATION_STATUS:--1}"; printf ',\n'
    printf '      "grub_validation_exit_code": '; json_nullable_status "${GRUB_VALIDATION_STATUS:--1}"; printf ',\n'
    printf '      "grub_validation_error": '; json_string "${GRUB_VALIDATION_ERROR:-}"; printf ',\n'
    printf '      "grub_install_exit_code": '; json_nullable_status "${GRUB_INSTALL_STATUS:--1}"; printf ',\n'
    printf '      "grub_replacement_attempted": '; json_boolean "${GRUB_REPLACEMENT_ATTEMPTED:-0}"; printf ',\n'
    printf '      "grub_config_replaced": '; json_boolean "${GRUB_CONFIG_REPLACED:-0}"; printf ',\n'
    printf '      "grub_validator": '; json_string 'grub-script-check'; printf ',\n'
    printf '      "grub_atomic_replacement": true,\n'
    printf '      "grub_blocked_by_initrd": '; json_boolean "${GRUB_BLOCKED_BY_INITRD:-0}"; printf ',\n'
    printf '      "grub_block_reason": '; json_string "${GRUB_BLOCK_REASON:-}"; printf '\n'
    printf '    }\n'
}

print_json_result() {
    local stable_exit_code=$1

    printf '{\n'
    printf '  "schema_version": 0,\n'
    printf '  "schema_status": "provisional",\n'
    printf '  "operation": '; json_string "$OPERATION"; printf ',\n'
    printf '  "success": '; json_boolean "$RESULT_SUCCESS"; printf ',\n'
    printf '  "partial": '; json_boolean "$RESULT_PARTIAL"; printf ',\n'
    printf '  "reboot": '; json_string "$RESULT_REBOOT"; printf ',\n'
    printf '  "boot_safe": '; json_boolean "$RESULT_BOOT_SAFE"; printf ',\n'
    printf '  "exit_code": %d,\n' "$stable_exit_code"
    printf '  "exit_code_meaning": '; json_string "$(stable_exit_code_description "$stable_exit_code")"; printf ',\n'
    printf '  "exit_code_stable": true,\n'
    printf '  "started_at": '; json_string "$STARTED_AT"; printf ',\n'
    printf '  "finished_at": '; json_string "$FINISHED_AT"; printf ',\n'
    printf '  "log_path": '; json_string "$LOG"; printf ',\n'
    printf '  "config_path": '; json_string "$CONFIG_FILE"; printf ',\n'
    printf '  "modules": {\n'

    case "$OPERATION" in
        check)
            print_check_json_module
            ;;
        dry-run)
            print_dry_run_json_modules
            ;;
        apply)
            print_apply_json_modules
            ;;
    esac

    printf '  },\n'
    printf '  "warnings": '; json_string_array "${RESULT_WARNINGS[@]}"; printf ',\n'
    printf '  "errors": '; json_string_array "${RESULT_ERRORS[@]}"; printf '\n'
    printf '}\n'
}

# Workflow coordinators

run_boot_preparation_module() {
    local boot_state=skipped
    local action_exit=0

    GRUB_COMMAND_ATTEMPTED=0
    GRUB_BLOCKED_BY_INITRD=0
    GRUB_BLOCK_REASON=

    emit_module_started_event boot "Boot preparation module started"

    if [ "$INITRD_REQUIRED" -eq 0 ] && [ "$GRUB_REQUIRED" -eq 0 ]; then
        boot_state=skipped
    elif [ "$BOOT_MODE" = disabled ]; then
        boot_state=disabled
    elif [ "$BOOT_MODULE_RUN" -eq 0 ]; then
        boot_state=$BOOT_MODULE_STATE
    fi

    emit_action_started_event boot regenerate_initrd "Regenerating initrd when required"
    regenerate_initrd
    if [ "$INITRD_REQUIRED" -eq 0 ]; then
        emit_action_completed_event boot regenerate_initrd skipped \
            "initrd regeneration was not required" 0
    elif [ "$INITRD_UPDATE" -eq 0 ]; then
        emit_action_completed_event boot regenerate_initrd "$boot_state" \
            "initrd regeneration was not applicable: mode=$BOOT_MODE, $BOOT_MODULE_REASON" 0
    elif [ "$INITRD_OK" -eq 1 ]; then
        boot_state=success
        emit_action_completed_event boot regenerate_initrd success \
            "initrd regeneration completed" 0
    else
        boot_state=failed
        emit_action_completed_event boot regenerate_initrd failed \
            "initrd regeneration failed" 1
    fi

    if [ "$GRUB_REQUIRED" -eq 0 ]; then
        emit_action_completed_event boot update_grub skipped \
            "GRUB configuration update was not required" 0
    elif [ "$GRUB_UPDATE" -eq 0 ]; then
        emit_action_completed_event boot update_grub "$boot_state" \
            "GRUB configuration update was not applicable: mode=$BOOT_MODE, $BOOT_MODULE_REASON" 0
    elif ! grub_initrd_prerequisite_is_satisfied; then
        boot_state=failed
        emit_action_completed_event boot update_grub blocked \
            "GRUB configuration update was blocked: $GRUB_BLOCK_REASON" 1
    else
        emit_action_started_event boot update_grub "Updating GRUB configuration when required"
        update_grub_configuration
        if [ "$GRUB_OK" -eq 1 ]; then
            [ "$boot_state" != failed ] && boot_state=success
            emit_action_completed_event boot update_grub success \
                "GRUB configuration update completed" 0
        else
            boot_state=failed
            emit_action_completed_event boot update_grub failed \
                "GRUB configuration update failed" 1
        fi
    fi

    action_exit=0
    [ "$boot_state" = failed ] && action_exit=1
    emit_module_completed_event boot "$boot_state" \
        "Boot preparation module completed" "$action_exit"

    [ "$action_exit" -eq 0 ]
}

run_apply_workflow() {
    local slackware_state=success
    local flatpak_state=success
    local sbo_state=success
    local elf_state=success
    local cinnamon_state=skipped
    local action_exit=0

    emit_module_started_event slackware "Slackware update module started"
    emit_action_started_event slackware snapshot_before "Capturing package snapshot before update"
    if ! capture_package_snapshot_before; then
        slackware_state=failed
        echo "[ERROR] Cannot capture package snapshot before update: $PACKAGE_SNAPSHOT_BEFORE_ERROR"
        emit_action_completed_event slackware snapshot_before failed \
            "Package snapshot before update failed validation: $PACKAGE_SNAPSHOT_BEFORE_ERROR" 1
        emit_module_completed_event slackware failed \
            "Slackware update stopped before package operations because the baseline snapshot is invalid" 1
        print_summary
        return 1
    fi
    emit_action_completed_event slackware snapshot_before success \
        "Package snapshot before update captured and validated ($PACKAGE_SNAPSHOT_BEFORE_COUNT records)" 0

    emit_action_started_event slackware update_packages "Applying Slackware package operations"
    update_slackware_system
    action_exit=0
    if slackpkg_apply_action_failed update "$SLACKPKG_UPDATE_STATUS"; then
        action_exit=$SLACKPKG_UPDATE_STATUS
    elif slackpkg_apply_action_failed install-new "$SLACKPKG_INSTALL_NEW_STATUS"; then
        action_exit=$SLACKPKG_INSTALL_NEW_STATUS
    elif slackpkg_apply_action_failed upgrade-all "$SLACKPKG_UPGRADE_ALL_STATUS"; then
        action_exit=$SLACKPKG_UPGRADE_ALL_STATUS
    fi
    if [ "$action_exit" -gt 0 ]; then
        slackware_state=failed
    fi
    emit_action_completed_event slackware update_packages "$slackware_state" \
        "Slackware package operations completed" "$action_exit"

    emit_action_started_event slackware snapshot_after "Capturing package snapshot after update"
    if ! capture_package_snapshot_after; then
        slackware_state=failed
        action_exit=1
        echo "[ERROR] Cannot capture package snapshot after update: $PACKAGE_SNAPSHOT_AFTER_ERROR"
        emit_action_completed_event slackware snapshot_after failed \
            "Package snapshot after update failed validation: $PACKAGE_SNAPSHOT_AFTER_ERROR" 1
        emit_module_completed_event slackware failed \
            "Slackware package operations completed but post-update package state could not be validated" 1
        print_summary
        return 1
    fi
    emit_action_completed_event slackware snapshot_after success \
        "Package snapshot after update captured and validated ($PACKAGE_SNAPSHOT_AFTER_COUNT records)" 0
    emit_module_completed_event slackware "$slackware_state" \
        "Slackware package operations completed" "$action_exit"

    if [ "$action_exit" -gt 0 ]; then
        block_secondary_modules_after_partial_slackware_update
        echo "[ERROR] $SECONDARY_MODULES_BLOCK_REASON; secondary modules were not started"
        print_summary
        return 1
    fi

    probe_optional_modules
    print_optional_module_activation

    emit_module_started_event flatpak "Flatpak update module started"
    if [ "$FLATPAK_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event flatpak update "Updating Flatpak installations"
        update_flatpak
        if [ "$FLATPAK_STATUS" -gt 0 ]; then
            flatpak_state=failed
            action_exit=$FLATPAK_STATUS
        else
            flatpak_state=success
            action_exit=0
        fi
        emit_action_completed_event flatpak update "$flatpak_state" \
            "Flatpak update action completed" "$action_exit"
    else
        flatpak_state=$FLATPAK_MODULE_STATE
        action_exit=0
        emit_action_completed_event flatpak update "$flatpak_state" \
            "Flatpak update was not applicable: $FLATPAK_MODULE_REASON" 0
    fi
    emit_module_completed_event flatpak "$flatpak_state" \
        "Flatpak update module completed" "${action_exit:-0}"

    emit_module_started_event core "Package change analysis started"
    emit_action_started_event core detect_triggers "Detecting ABI and kernel changes"
    detect_abi_changes
    detect_kernel_changes
    emit_action_completed_event core detect_triggers success \
        "ABI and kernel change detection completed" 0
    emit_module_completed_event core success "Package change analysis completed" 0

    emit_module_started_event sbo "SBo update module started"
    if [ "$SBO_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event sbo synchronize "Synchronizing the configured SBo repository"
        synchronize_sbo_repository
        action_exit=0
        if [ "$SBOPKG_SYNC_STATUS" -gt 0 ]; then
            action_exit=$SBOPKG_SYNC_STATUS
        elif [ "$SQG_SYNC_STATUS" -gt 0 ]; then
            action_exit=$SQG_SYNC_STATUS
        fi
        if [ "$action_exit" -gt 0 ]; then
            sbo_state=failed
        else
            sbo_state=success
        fi
        emit_action_completed_event sbo synchronize "$sbo_state" \
            "SBo repository synchronization completed" "$action_exit"

        emit_action_started_event sbo build_queues "Building SBo target queues"
        SBO_TARGET_SELECTION_STATUS=0
        if build_sbo_target_queues_after_synchronization; then
            emit_action_completed_event sbo build_queues success \
                "Deterministic SBo target sets built" 0
        else
            SBO_TARGET_SELECTION_STATUS=1
            sbo_state=failed
            action_exit=1
            : > "$QUEUE_CORE"
            : > "$QUEUE_EXTRA"
            [ -n "${SBO_OPTION_RECORDS:-}" ] && : > "$SBO_OPTION_RECORDS"
            TOTAL_CORE=0
            SBO_OPTION_RECORD_COUNT=0
            TOTAL_EXTRA=0
            emit_action_completed_event sbo build_queues failed \
                "SBo target selection failed: $SBO_TARGET_SELECTION_ERROR" 1
        fi
    else
        sbo_state=$SBO_MODULE_STATE
        action_exit=0
        SBODIR=$SBO_QUEUE_DIR_FALLBACK
        : > "$QUEUE_CORE"
        : > "$QUEUE_EXTRA"
        [ -n "${SBO_OPTION_RECORDS:-}" ] && : > "$SBO_OPTION_RECORDS"
        TOTAL_CORE=0
        SBO_OPTION_RECORD_COUNT=0
        TOTAL_EXTRA=0
        emit_action_completed_event sbo synchronize "$sbo_state" \
            "SBo repository synchronization was not applicable: $SBO_MODULE_REASON" 0
        emit_action_completed_event sbo build_queues "$sbo_state" \
            "SBo queue generation was not applicable: $SBO_MODULE_REASON" 0
    fi

    emit_module_started_event elf "ELF dependency module started"
    if [ "$ELF_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event elf scan_dependencies "Scanning ELF dependencies statically"
        if detect_broken_elf_objects && map_broken_objects_to_sbo_packages; then
            if [ -s "$BROKEN" ]; then
                elf_state=warning
            else
                elf_state=success
            fi
            emit_action_completed_event elf scan_dependencies "$elf_state" \
                "ELF dependency scan completed" 0
        else
            elf_state=failed
            sbo_state=failed
            SBO_TARGET_SELECTION_STATUS=1
            action_exit=1
            emit_action_completed_event elf scan_dependencies failed \
                "Static ELF inspection or ownership mapping failed" 1
        fi
    else
        elf_state=$ELF_MODULE_STATE
        : > "$BROKEN"
        emit_action_completed_event elf scan_dependencies "$elf_state" \
            "ELF dependency scan was not applicable: $ELF_MODULE_REASON" 0
    fi
    emit_module_completed_event elf "$elf_state" "ELF dependency module completed" 0

    if [ "$SBO_MODULE_RUN" -eq 1 ] && [ "$SBO_TARGET_SELECTION_STATUS" -eq 0 ]; then
        emit_action_started_event sbo process_queue "Processing the final SBo queue"
        build_and_apply_sbo_queue
        if [ "$SBO_BUILD_STATUS" -gt 0 ]; then
            sbo_state=failed
            action_exit=$SBO_BUILD_STATUS
        else
            action_exit=0
        fi
        emit_action_completed_event sbo process_queue "$sbo_state" \
            "Final SBo queue processing completed" "$action_exit"
    elif [ "$SBO_MODULE_RUN" -eq 1 ]; then
        sbo_state=failed
        action_exit=1
        emit_action_completed_event sbo process_queue failed \
            "SBo queue processing was blocked because target selection failed" 1
    else
        emit_action_completed_event sbo process_queue "$sbo_state" \
            "SBo queue processing was not applicable: $SBO_MODULE_REASON" 0
    fi
    emit_module_completed_event sbo "$sbo_state" "SBo update module completed" "${action_exit:-0}"

    emit_module_started_event cinnamon "Cinnamon rebuild module started"
    if [ "$CINNAMON_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event cinnamon rebuild "Evaluating and rebuilding Cinnamon when required"
        rebuild_cinnamon
        action_exit=0
        case "$CINNAMON_TRIGGER" in
            0) cinnamon_state=skipped ;;
            2) cinnamon_state=success ;;
            1|3)
                cinnamon_state=failed
                action_exit=1
                ;;
        esac
        emit_action_completed_event cinnamon rebuild "$cinnamon_state" \
            "Cinnamon rebuild action completed" "$action_exit"
    else
        cinnamon_state=$CINNAMON_MODULE_STATE
        action_exit=0
        emit_action_completed_event cinnamon rebuild "$cinnamon_state" \
            "Cinnamon rebuild was not applicable: $CINNAMON_MODULE_REASON" 0
    fi
    emit_module_completed_event cinnamon "$cinnamon_state" \
        "Cinnamon rebuild module completed" "${action_exit:-0}"

    run_boot_preparation_module || true

    print_summary
}

# Entry point

main() {
    local workflow_result=0
    local result

    initialize_execution_environment

    parse_arguments "$@" || {
        print_usage >&2
        return "$EXIT_INVALID_INPUT"
    }

    if [ "$SHOW_HELP" -eq 1 ]; then
        print_usage
        return "$EXIT_SUCCESS"
    fi

    load_configuration || return "$EXIT_INVALID_INPUT"

    require_root || {
        result=$?
        return "$result"
    }

    acquire_instance_lock || {
        result=$?
        return "$result"
    }

    # Install cleanup coverage immediately after the process owns the lock.
    install_runtime_traps

    if [ "$OPERATION" = "dry-run" ]; then
        if ! initialize_dry_run_runtime; then
            return "$EXIT_GENERAL_FAILURE"
        fi
    elif ! initialize_runtime; then
        return "$EXIT_GENERAL_FAILURE"
    fi

    rotate_logs
    if ! configure_logging; then
        return "$EXIT_GENERAL_FAILURE"
    fi
    print_start_banner
    emit_operation_started_event

    case "$OPERATION" in
        check)
            run_check_workflow || workflow_result=$?
            ;;
        apply)
            run_apply_workflow || workflow_result=$?
            ;;
        dry-run)
            run_dry_run_workflow || workflow_result=$?
            ;;
    esac

    if ! FINISHED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ); then
        echo "Error: cannot record the runtime completion time" >&2
        workflow_result=$EXIT_GENERAL_FAILURE
    fi
    determine_stable_exit_code "$workflow_result"
    result=$STABLE_EXIT_CODE
    print_stable_exit_code_summary "$result"

    if [ "$JSON_OUTPUT" -eq 1 ]; then
        print_json_result "$result" >&3
        exec 3>&-
    elif [ "$EVENTS_OUTPUT" -eq 1 ]; then
        emit_final_events "$result"
        exec 3>&-
    fi

    return "$result"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
