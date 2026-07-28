#!/bin/bash
#
# slack-update-reference.sh — Unattended Slackware 15.0/current + SBo + Flatpak + Cinnamon update reference
#
# Installation:
#   install -Dm755 slack-update-reference.sh /usr/local/sbin/slack-update
#   install -Dm644 data/config/slack-update.conf /etc/slack-update/slack-update.conf
#
# Manual use:   slack-update
# Cron example: 0 3 * * 0 /usr/local/sbin/slack-update

set -uo pipefail
IFS=$'\n\t'

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
elf.scan_paths|$CONFIG_ELF_SCAN_PATHS
packages.abi|$CONFIG_ABI_PACKAGES
packages.cinnamon_abi|$CONFIG_CINNAMON_ABI_PACKAGES
packages.critical|$CONFIG_CRITICAL_PACKAGES
packages.kernel|$CONFIG_KERNEL_PACKAGES
packages.kernel_boot|$CONFIG_KERNEL_BOOT_PACKAGES
packages.kernel_headers|$CONFIG_KERNEL_HEADERS_PACKAGES
boot.mkinitrd_config|$CONFIG_MKINITRD_CONFIG
boot.initrd_default_output|$CONFIG_INITRD_DEFAULT_OUTPUT
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
        "$CONFIG_SBO_QUEUE_DIR_FALLBACK" "$CONFIG_MKINITRD_CONFIG" \
        "$CONFIG_INITRD_DEFAULT_OUTPUT" "$CONFIG_GRUB_DIRECTORY" \
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
    ELF_MODE=$CONFIG_ELF_MODE
    BOOT_MODE=$CONFIG_BOOT_MODE
    MKINITRD_CONFIG=$CONFIG_MKINITRD_CONFIG
    INITRD_DEFAULT_OUTPUT=$CONFIG_INITRD_DEFAULT_OUTPUT
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

# Optional module activation functions

detect_cinnamon_installation() {
    if command -v cinnamon >/dev/null 2>&1; then
        return 0
    fi

    if [ -d "$PACKAGE_DATABASE" ] \
        && find "$PACKAGE_DATABASE" -maxdepth 1 -type f -name 'cinnamon-[0-9]*' \
            -print -quit 2>/dev/null | grep -q .; then
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

probe_boot_module() {
    BOOT_MODULE_RUN=0
    BOOT_MODULE_REASON=
    BOOT_INITRD_AVAILABLE=0
    BOOT_GRUB_AVAILABLE=0

    if [ "$BOOT_MODE" = disabled ]; then
        BOOT_MODULE_STATE=disabled
        BOOT_MODULE_REASON="disabled by configuration"
        return 0
    fi

    if command -v mkinitrd >/dev/null 2>&1 \
        && [ -f "$MKINITRD_CONFIG" ] \
        && grep -q '^ROOTDEV=' "$MKINITRD_CONFIG" 2>/dev/null; then
        BOOT_INITRD_AVAILABLE=1
    fi

    if command -v grub-mkconfig >/dev/null 2>&1 \
        && [ -d "$GRUB_DIRECTORY" ]; then
        BOOT_GRUB_AVAILABLE=1
    fi

    if [ "$BOOT_MODE" = enabled ]; then
        if [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] && [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then
            BOOT_MODULE_STATE=available
            BOOT_MODULE_RUN=1
        elif [ "$BOOT_INITRD_AVAILABLE" -eq 0 ] && [ "$BOOT_GRUB_AVAILABLE" -eq 0 ]; then
            BOOT_MODULE_STATE=unavailable
            BOOT_MODULE_REASON="initrd and GRUB preparation requirements are missing"
        elif [ "$BOOT_INITRD_AVAILABLE" -eq 0 ]; then
            BOOT_MODULE_STATE=unavailable
            BOOT_MODULE_REASON="initrd preparation requirements are missing"
        else
            BOOT_MODULE_STATE=unavailable
            BOOT_MODULE_REASON="GRUB preparation requirements are missing"
        fi
    elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then
        BOOT_MODULE_STATE=available
        BOOT_MODULE_RUN=1
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

    case "$BOOT_MODE" in
        disabled)
            INITRD_UPDATE=0
            GRUB_UPDATE=0
            ;;
        enabled)
            ;;
        auto)
            [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || INITRD_UPDATE=0
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
        echo "Otra instancia de slack-update ya esta ejecutandose" >&2
        return "$EXIT_ALREADY_RUNNING"
    fi
}

initialize_runtime_state() {
    KERNEL_TRIGGER=0
    INITRD_UPDATE=0
    GRUB_UPDATE=0
    ABI_TRIGGER=0
    CINNAMON_TRIGGER=0   # 0=none, 1=needed, 2=ok, 3=fail
    CINNAMON_OK=0
    INITRD_OK=0
    GRUB_OK=0
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
    TOTAL_EN_COLA=0
    TOTAL_CORE=0
    TOTAL_EXTRA=0
    CHECK_STATUS=0
    SLACKPKG_UPDATE_STATUS=-1
    SLACKPKG_INSTALL_NEW_STATUS=-1
    SLACKPKG_UPGRADE_ALL_STATUS=-1
    FLATPAK_STATUS=-1
    SBOPKG_SYNC_STATUS=-1
    SQG_SYNC_STATUS=-1
    SBO_BUILD_STATUS=-1
    STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    FINISHED_AT=
    RUNTIME_TMPDIR=
    EVENT_SEQUENCE=0
}

initialize_runtime() {
    WORKDIR=$WORKDIR_CONFIG
    LOGDIR=$LOGDIR_CONFIG

    mkdir -p "$WORKDIR" "$LOGDIR"

    DATE=$(date +%F-%H%M%S)
    LOG="$LOGDIR/run-$DATE.log"

    BROKEN="$WORKDIR/broken.txt"
    QUEUE_CORE="$WORKDIR/queue-core.sqf"
    QUEUE_EXTRA="$WORKDIR/queue-extra.sqf"

    BEFORE_PKGS="$WORKDIR/packages.before"
    AFTER_PKGS="$WORKDIR/packages.after"

    # Temporary files are created here so the trap covers them immediately.
    QUEUE_FINAL=$(mktemp)
    BROKEN_NEW=$(mktemp)
    STILL_BROKEN=$(mktemp)
    BROKEN_ERRORS=$(mktemp)

    initialize_runtime_state
    CSB_DIR=$CSB_DIR_CONFIG
}

initialize_dry_run_runtime() {
    LOGDIR=$LOGDIR_CONFIG
    mkdir -p "$LOGDIR"

    DATE=$(date +%F-%H%M%S)
    LOG="$LOGDIR/run-$DATE.log"

    RUNTIME_TMPDIR=$(mktemp -d /tmp/slack-update-dry-run.XXXXXX)
    WORKDIR="$RUNTIME_TMPDIR"

    BROKEN="$WORKDIR/broken.txt"
    QUEUE_CORE="$WORKDIR/queue-core.sqf"
    QUEUE_EXTRA="$WORKDIR/queue-extra.sqf"
    QUEUE_FINAL="$WORKDIR/queue-final.sqf"
    BROKEN_NEW="$WORKDIR/broken-new.txt"
    STILL_BROKEN="$WORKDIR/still-broken.txt"
    BROKEN_ERRORS="$WORKDIR/broken-errors.txt"
    BEFORE_PKGS="$WORKDIR/packages.before"
    AFTER_PKGS="$WORKDIR/packages.after"
    ABI_CANDIDATES="$WORKDIR/abi-rebuild-candidates.txt"

    initialize_runtime_state
    RUNTIME_TMPDIR="$WORKDIR"
    CSB_DIR=$CSB_DIR_CONFIG

    : > "$BROKEN"
    : > "$QUEUE_CORE"
    : > "$QUEUE_EXTRA"
    : > "$BROKEN_ERRORS"
}

cleanup() {
    rm -f "${QUEUE_FINAL:-}" "${BROKEN_NEW:-}" "${STILL_BROKEN:-}" \
        "${BROKEN_ERRORS:-}" 2>/dev/null || true

    if [ -n "${RUNTIME_TMPDIR:-}" ]; then
        rm -rf -- "$RUNTIME_TMPDIR" 2>/dev/null || true
    fi

    flock -u 9 2>/dev/null || true
}

rotate_logs() {
    # Rotacion de logs — conservar solo los ultimos 30 dias.
    # FIX #10: La rotacion se ejecuta ANTES de abrir el log de esta ejecucion,
    # por lo que nunca puede borrar el fichero run-$DATE.log actual.
    find "$LOGDIR" -name 'run-*.log' -mtime +"$LOG_RETENTION_DAYS" -delete 2>/dev/null || true
}

configure_logging() {
    # Redirigir log filtrando codigos ANSI
    # FIX #10: Se eliminan emojis del log para evitar problemas de encoding en cron.
    # La salida de consola (si se ejecuta interactivamente) los mostrara igualmente
    # porque el tee escribe a stdout antes del filtro de ANSI.
    if [ "$JSON_OUTPUT" -eq 1 ] || [ "$EVENTS_OUTPUT" -eq 1 ]; then
        # Keep stdout reserved for machine-readable output.
        exec 3>&1
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

        if [ -f "$MKINITRD_CONFIG" ] && grep -q '^ROOTDEV=' "$MKINITRD_CONFIG" 2>/dev/null; then
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

    SBODIR=$(grep -E '^QUEUEDIR=' "$SBOPKG_CONFIG" 2>/dev/null \
        | head -1 | cut -d= -f2- | tr -d "\"'" \
        | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' || true)

    if [ -z "$SBODIR" ]; then
        SBODIR=$SBO_QUEUE_DIR_FALLBACK
    fi

    if [ -d "$SBODIR" ]; then
        find "$SBODIR" -name '*.sqf' -exec cat {} + 2>/dev/null \
            | awk '{print $1}' | sort -u > "$QUEUE_CORE"
    else
        : > "$QUEUE_CORE"
    fi

    TOTAL_CORE=$(wc -l < "$QUEUE_CORE")
    echo "  Current local queue targets: $TOTAL_CORE"
}

collect_installed_sbo_candidates() {
    find "$PACKAGE_DATABASE" -maxdepth 1 -name "*${SBO_PACKAGE_TAG}" -printf '%f\n' 2>/dev/null \
        | rev | cut -d- -f4- | rev | sort -u > "$ABI_CANDIDATES" || true

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

    detect_broken_elf_objects
    map_broken_objects_to_sbo_packages

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
        echo "      slackpkg -batch=on -default_answer=y install-new"
    else
        echo "      (install-new disabled by configuration)"
    fi
    if [ "$SLACKWARE_UPGRADE_ALL" = true ]; then
        echo "      slackpkg -batch=on -default_answer=y upgrade-all"
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
    echo "  Kernel image or module changes would schedule initrd and GRUB processing."
    echo "  A kernel-headers-only change would only emit the external-module warning."
    echo

    echo "[4] SBo"
    echo "  Mode: $SBO_MODE"
    echo "  Activation state: $SBO_MODULE_STATE"
    if [ "$SBO_MODULE_RUN" -eq 1 ]; then
        echo "  Planned repository commands: sbopkg -r, then sqg -a"
        echo "  Current local queue directory: $SBODIR"
        echo "  Current local queue targets: $TOTAL_CORE"
        print_plan_file "$QUEUE_CORE"
        echo "  Current broken-ELF SBo targets: $PLAN_BROKEN_SBO_COUNT"
        print_plan_file "$QUEUE_EXTRA"
        echo "  The final apply queue would be the sorted union of the current queue,"
        echo "  ABI-triggered candidates, and broken-ELF package owners determined after update."
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
    if [ "$BOOT_MODULE_RUN" -eq 1 ]; then
        echo "  These actions remain conditional on kernel-generic, kernel-huge, or kernel-modules changes."
        if [ "$BOOT_INITRD_AVAILABLE" -eq 1 ]; then
            echo "  Planned initrd command: mkinitrd -F"
        elif [ "$BOOT_MODE" = enabled ]; then
            echo "  [ERROR] initrd requirements are missing and would fail if triggered."
        else
            echo "  Auto mode would omit initrd preparation because it is not applicable."
        fi
        if [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then
            echo "  Planned GRUB command: grub-mkconfig -o $GRUB_CONFIG"
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
        inspect_current_sbo_queues
        collect_installed_sbo_candidates
        emit_action_completed_event sbo inspect_queues success \
            "Current SBo queues and ABI candidates inspected" 0
        sbo_state=success
    else
        sbo_state=$SBO_MODULE_STATE
        action_exit=0
        SBODIR=$SBO_QUEUE_DIR_FALLBACK
        : > "$QUEUE_CORE"
        : > "$QUEUE_EXTRA"
        : > "$ABI_CANDIDATES"
        TOTAL_CORE=0
        PLAN_ABI_SBO_COUNT=0
        PLAN_BROKEN_SBO_COUNT=0
        emit_action_completed_event sbo inspect_queues "$sbo_state" \
            "SBo queue inspection was not applicable: $SBO_MODULE_REASON" 0
    fi
    emit_module_completed_event sbo "$sbo_state" "SBo planning inspection completed" 0

    emit_module_started_event elf "ELF dependency inspection started"
    if [ "$ELF_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event elf scan_dependencies "Scanning current ELF dependencies"
        inspect_current_elf_state
        if [ "$PLAN_BROKEN_COUNT" -gt 0 ]; then
            elf_state=warning
        fi
        emit_action_completed_event elf scan_dependencies "$elf_state" \
            "Current ELF dependency inspection completed" 0
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
    # ---------------------------
    # SNAPSHOT BEFORE
    # ---------------------------

    rm -f "$BEFORE_PKGS" "$AFTER_PKGS"

    find "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n' \
        | sort > "$BEFORE_PKGS" || true
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
        slackpkg -batch=on -default_answer=y install-new || SLACKPKG_INSTALL_NEW_STATUS=$?
    else
        echo "  install-new disabled by configuration"
    fi

    if [ "$SLACKWARE_UPGRADE_ALL" = true ]; then
        SLACKPKG_UPGRADE_ALL_STATUS=0
        slackpkg -batch=on -default_answer=y upgrade-all || SLACKPKG_UPGRADE_ALL_STATUS=$?
    else
        echo "  upgrade-all disabled by configuration"
    fi
}

capture_package_snapshot_after() {
    # ---------------------------
    # SNAPSHOT AFTER
    # ---------------------------

    find "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n' \
        | sort > "$AFTER_PKGS" || true
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

        BEFORE=$(grep "^${p}-" "$BEFORE_PKGS" || true)
        AFTER=$(grep  "^${p}-" "$AFTER_PKGS"  || true)

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

        BEFORE=$(grep "^${p}-" "$BEFORE_PKGS" || true)
        AFTER=$(grep  "^${p}-" "$AFTER_PKGS"  || true)

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
            sqg -a || SQG_SYNC_STATUS=$?
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

    # FIX #6: Parseo mas robusto de sbopkg.conf — cubre valores con comillas dobles,
    # comillas simples o sin comillas.
    SBODIR=$(grep -E '^QUEUEDIR=' "$SBOPKG_CONFIG" 2>/dev/null \
        | head -1 | cut -d= -f2- | tr -d \"\' | xargs 2>/dev/null || true)
    if [ -z "$SBODIR" ]; then
        SBODIR=$SBO_QUEUE_DIR_FALLBACK
        echo "  [WARN] No se pudo leer QUEUEDIR de sbopkg.conf — usando valor por defecto: $SBODIR"
    fi

    rm -f "$QUEUE_CORE" "$QUEUE_EXTRA"

    if [ -d "$SBODIR" ]; then
        find "$SBODIR" -name '*.sqf' -exec cat {} + 2>/dev/null \
            | awk '{print $1}' | sort -u > "$QUEUE_CORE"
        TOTAL_CORE=$(wc -l < "$QUEUE_CORE")
        echo "  Cola principal: $TOTAL_CORE paquetes"
    else
        echo "  [WARN] Directorio de queues no encontrado: $SBODIR"
        touch "$QUEUE_CORE"
    fi
}

add_abi_rebuild_targets() {
    # ---------------------------
    # [7] ABI FORCES SBo REBUILD
    # ---------------------------

    if [ "$ABI_TRIGGER" -eq 1 ]; then

        echo "[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra"

        find "$PACKAGE_DATABASE" -maxdepth 1 -name "*${SBO_PACKAGE_TAG}" \
            -printf '%f\n' 2>/dev/null \
            | rev | cut -d- -f4- | rev \
            | sort -u > "$QUEUE_EXTRA" || true

        TOTAL_EXTRA=$(wc -l < "$QUEUE_EXTRA")
        echo "  Cola ABI extra: $TOTAL_EXTRA paquetes"

    else
        touch "$QUEUE_EXTRA"
    fi
}

detect_broken_elf_objects() {
    # ---------------------------
    # [8] BROKEN LIBS DETECTION
    # ---------------------------

    echo "[8] Detectando binarios rotos"

    # FIX #2: El subshell del pipe hacia 'while | sort' perdía la salida del log.
    # Se redirige la salida de errores del bucle explícitamente al log mediante
    # un fichero temporal de errores, y se procesa después del bucle.
    find "${ELF_SCAN_PATHS[@]}" \( -type f -o -type l \) -print0 |
    while IFS= read -r -d '' f; do
        # FIX #5: Sustituido 'file | ldd' por 'readelf -d' para deteccion segura.
        # ldd puede ejecutar el binario (riesgo con binarios de terceros) y genera
        # falsos positivos con binarios PIE o con RPATH $ORIGIN. readelf -d es
        # estrictamente estatico. Se comprueba cada libreria NEEDED contra la cache
        # de ldconfig; si no aparece, el binario se marca como roto.
        _real=$(readlink -f "$f" 2>/dev/null || echo "$f")
        _needed=$(readelf -d "$_real" 2>>"$BROKEN_ERRORS" \
            | awk '/\(NEEDED\)/{match($0,/\[([^]]+)\]/,a); print a[1]}') || continue
        [ -z "$_needed" ] && continue
        while IFS= read -r _lib; do
            [ -z "$_lib" ] && continue
            /sbin/ldconfig -p 2>/dev/null | grep -qF "$_lib" || { echo "$f"; break; }
        done <<< "$_needed"
    done | sort -u > "$BROKEN_NEW"

    # Volcar los errores del bucle al log principal
    if [ -s "$BROKEN_ERRORS" ]; then
        echo "  [WARN] Errores durante deteccion de binarios rotos:"
        sed 's/^/    /' "$BROKEN_ERRORS"
        > "$BROKEN_ERRORS"
    fi

    # broken.txt refleja el estado actual — no acumulado
    cp "$BROKEN_NEW" "$BROKEN"

    BROKEN_COUNT=$(wc -l < "$BROKEN" 2>/dev/null || echo 0)
    echo "  Binarios rotos detectados: $BROKEN_COUNT"
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
                | sed 's|.*/||' \
                | grep -F "$SBO_PACKAGE_TAG" \
                | rev | cut -d- -f4- | rev
        done < "$BROKEN" | sort -u > "$_BROKEN_PKGS"

        # Merge: contenido previo de QUEUE_EXTRA (si lo hay) + rotos nuevos, deduplicado
        sort -u "$QUEUE_EXTRA" "$_BROKEN_PKGS" -o "$QUEUE_EXTRA" 2>/dev/null || true
        rm -f "$_BROKEN_PKGS"

        TOTAL_EXTRA=$(wc -l < "$QUEUE_EXTRA")
        echo "  Cola extra tras rotos: $TOTAL_EXTRA paquetes"
    else
        echo "  Sin binarios rotos, nada que anadir"
    fi
}

build_and_apply_sbo_queue() {
    # ---------------------------
    # [10] BUILD FINAL QUEUE + APPLY
    # ---------------------------

    echo "[10] Aplicando cola SBo"

    cat "$QUEUE_CORE" "$QUEUE_EXTRA" 2>/dev/null | sort -u > "$QUEUE_FINAL"

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

        # Verificar si los binarios que estaban rotos antes de sbopkg siguen rotos
        if [ -s "$BROKEN" ]; then
            echo "  Verificando si los binarios rotos fueron reparados..."
            > "$STILL_BROKEN"
            while read -r bin; do
                [ -e "$bin" ] || continue
                ldd "$bin" 2>/dev/null | grep -q "not found" && echo "$bin"
            done < "$BROKEN" | sort > "$STILL_BROKEN"

            if [ -s "$STILL_BROKEN" ]; then
                echo "  [WARN] Binarios que siguen rotos tras la recompilacion:"
                sed 's/^/    /' "$STILL_BROKEN"
                cp "$STILL_BROKEN" "$BROKEN"
            else
                echo "  [OK] Todos los binarios rotos fueron reparados"
                > "$BROKEN"
            fi
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

regenerate_initrd() {
    # ---------------------------
    # [12] INITRD
    # ---------------------------

    if [ "$INITRD_UPDATE" -eq 1 ]; then

        echo "[12] Regenerando initrd"

        if command -v mkinitrd >/dev/null 2>&1; then
            if [ -f "$MKINITRD_CONFIG" ]; then
                if grep -q '^ROOTDEV=' "$MKINITRD_CONFIG" 2>/dev/null; then
                    mkinitrd -F \
                        && {
                            # FIX #8: Verificar que el initrd existe y no esta vacio
                            _initrd=$(grep -E '^OUTPUT=' "$MKINITRD_CONFIG" 2>/dev/null \
                                | cut -d= -f2- | tr -d \"\' | xargs 2>/dev/null)
                            _initrd=${_initrd:-$INITRD_DEFAULT_OUTPUT}
                            if [ -s "$_initrd" ]; then
                                INITRD_OK=1
                                echo "  [OK] initrd regenerado ($_initrd)"
                            else
                                echo "  [ERROR] mkinitrd termino sin errores pero $_initrd esta vacio o no existe"
                            fi
                        } \
                        || echo "  [ERROR] mkinitrd -F fallo"
                else
                    echo "  [ERROR] $MKINITRD_CONFIG existe pero no contiene ROOTDEV -- initrd NO regenerado"
                    echo "          Revisa $MKINITRD_CONFIG antes de continuar"
                fi
            else
                echo "  [ERROR] $MKINITRD_CONFIG no existe -- initrd NO regenerado"
            fi
        else
            echo "  [ERROR] mkinitrd no encontrado"
        fi

    fi
}

update_grub_configuration() {
    # ---------------------------
    # [13] GRUB
    # ---------------------------

    if [ "$GRUB_UPDATE" -eq 1 ]; then

        echo "[13] Actualizando GRUB"

        if command -v grub-mkconfig >/dev/null 2>&1 && [ -d "$GRUB_DIRECTORY" ]; then
            grub-mkconfig -o "$GRUB_CONFIG" \
                && {
                    GRUB_OK=1
                    echo "  [OK] GRUB actualizado"
                } \
                || echo "  [ERROR] grub-mkconfig fallo"

        else
            echo "  [ERROR] GRUB no encontrado o $GRUB_DIRECTORY no existe"
        fi

    fi
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
            fi
        fi

        if [ "$GRUB_REQUIRED" -eq 1 ]; then
            if [ "$GRUB_UPDATE" -eq 0 ]; then
                echo "  -> GRUB omitido por el modo del modulo boot ($BOOT_MODE)."
            elif [ "$GRUB_OK" -eq 1 ]; then
                echo "  -> GRUB actualizado correctamente."
            else
                echo "  -> GRUB requeria actualizacion pero fallo."
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
    echo "- Cola extra (ABI + binarios rotos):  $TOTAL_EXTRA paquetes"
    echo "- Total en cola (enviados a sbopkg):  $TOTAL_EN_COLA paquetes"

    echo

    echo "[SYS] Diagnostico del sistema:"
    echo

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
            RESULT_WARNINGS+=("Exact Slackware package changes remain unresolved until package metadata is refreshed during apply")
            ;;
        apply)
            append_enabled_module_requirement_errors
            [ "$SLACKPKG_UPDATE_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("slackpkg update failed with exit code $SLACKPKG_UPDATE_STATUS")
            [ "$SLACKPKG_INSTALL_NEW_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("slackpkg install-new failed with exit code $SLACKPKG_INSTALL_NEW_STATUS")
            [ "$SLACKPKG_UPGRADE_ALL_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("slackpkg upgrade-all failed with exit code $SLACKPKG_UPGRADE_ALL_STATUS")
            [ "$FLATPAK_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("flatpak update failed with exit code $FLATPAK_STATUS")
            [ "$SBOPKG_SYNC_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("sbopkg repository synchronization failed with exit code $SBOPKG_SYNC_STATUS")
            [ "$SQG_SYNC_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("sqg queue generation failed with exit code $SQG_SYNC_STATUS")
            [ "$SBO_BUILD_STATUS" -gt 0 ] \
                && RESULT_ERRORS+=("sbopkg queue processing failed with exit code $SBO_BUILD_STATUS")
            [ "$CINNAMON_TRIGGER" -eq 3 ] \
                && RESULT_ERRORS+=("Cinnamon required rebuilding but the rebuild failed")
            if [ "$INITRD_UPDATE" -eq 1 ] && [ "$INITRD_OK" -ne 1 ]; then
                RESULT_ERRORS+=("initrd preparation was required but did not complete successfully")
            fi
            if [ "$GRUB_UPDATE" -eq 1 ] && [ "$GRUB_OK" -ne 1 ]; then
                RESULT_ERRORS+=("GRUB configuration generation was required but did not complete successfully")
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
        printf ', '; json_string 'slackpkg -batch=on -default_answer=y install-new'
    fi
    if [ "$SLACKWARE_UPGRADE_ALL" = true ]; then
        printf ', '; json_string 'slackpkg -batch=on -default_answer=y upgrade-all'
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
    printf '      "current_queue_targets": '; json_string_array_from_file "$QUEUE_CORE"; printf ',\n'
    printf '      "abi_rebuild_candidates": '; json_string_array_from_file "$ABI_CANDIDATES"; printf ',\n'
    printf '      "broken_elf_targets": '; json_string_array_from_file "$QUEUE_EXTRA"; printf '\n'
    printf '    },\n'

    printf '    "elf": {\n'
    printf '      "mode": '; json_string "$ELF_MODE"; printf ',\n'
    printf '      "activation_state": '; json_string "$ELF_MODULE_STATE"; printf ',\n'
    printf '      "reason": '; json_string "$ELF_MODULE_REASON"; printf ',\n'
    printf '      "readelf_available": '; json_boolean "$PLAN_READELF_AVAILABLE"; printf ',\n'
    printf '      "ldconfig_available": '; json_boolean "$ELF_LDCONFIG_AVAILABLE"; printf ',\n'
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
    printf '      "grub_available": '; json_boolean "$PLAN_GRUB_AVAILABLE"; printf ',\n'
    printf '      "grub_configured": '; json_boolean "$PLAN_GRUB_CONFIGURED"; printf '\n'
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

    if [ "$SLACKPKG_UPDATE_STATUS" -gt 0 ] \
        || [ "$SLACKPKG_INSTALL_NEW_STATUS" -gt 0 ] \
        || [ "$SLACKPKG_UPGRADE_ALL_STATUS" -gt 0 ]; then
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
        || [ "$SBO_BUILD_STATUS" -gt 0 ]; then
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
        elif [ "$GRUB_OK" -eq 1 ]; then
            grub_state=success
        else
            grub_state=failed
        fi
    fi

    if [ "$INITRD_REQUIRED" -eq 0 ] && [ "$GRUB_REQUIRED" -eq 0 ]; then
        boot_state=not-required
    elif [ "$initrd_state" = failed ] || [ "$grub_state" = failed ]; then
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
    printf '      "initrd_required": '; json_boolean "$INITRD_REQUIRED"; printf ',\n'
    printf '      "initrd_state": '; json_string "$initrd_state"; printf ',\n'
    printf '      "grub_required": '; json_boolean "$GRUB_REQUIRED"; printf ',\n'
    printf '      "grub_state": '; json_string "$grub_state"; printf '\n'
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

run_apply_workflow() {
    local slackware_state=success
    local flatpak_state=success
    local sbo_state=success
    local elf_state=success
    local cinnamon_state=skipped
    local boot_state=skipped
    local action_exit=0

    emit_module_started_event slackware "Slackware update module started"
    emit_action_started_event slackware snapshot_before "Capturing package snapshot before update"
    capture_package_snapshot_before
    emit_action_completed_event slackware snapshot_before success \
        "Package snapshot before update captured" 0

    emit_action_started_event slackware update_packages "Applying Slackware package operations"
    update_slackware_system
    action_exit=0
    if [ "$SLACKPKG_UPDATE_STATUS" -gt 0 ]; then
        action_exit=$SLACKPKG_UPDATE_STATUS
    elif [ "$SLACKPKG_INSTALL_NEW_STATUS" -gt 0 ]; then
        action_exit=$SLACKPKG_INSTALL_NEW_STATUS
    elif [ "$SLACKPKG_UPGRADE_ALL_STATUS" -gt 0 ]; then
        action_exit=$SLACKPKG_UPGRADE_ALL_STATUS
    fi
    if [ "$action_exit" -gt 0 ]; then
        slackware_state=failed
    fi
    emit_action_completed_event slackware update_packages "$slackware_state" \
        "Slackware package operations completed" "$action_exit"

    emit_action_started_event slackware snapshot_after "Capturing package snapshot after update"
    capture_package_snapshot_after
    emit_action_completed_event slackware snapshot_after success \
        "Package snapshot after update captured" 0
    emit_module_completed_event slackware "$slackware_state" \
        "Slackware package operations completed" "$action_exit"

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
        build_sbo_core_queue
        add_abi_rebuild_targets
        emit_action_completed_event sbo build_queues success "SBo target queues built" 0
    else
        sbo_state=$SBO_MODULE_STATE
        action_exit=0
        SBODIR=$SBO_QUEUE_DIR_FALLBACK
        : > "$QUEUE_CORE"
        : > "$QUEUE_EXTRA"
        TOTAL_CORE=0
        TOTAL_EXTRA=0
        emit_action_completed_event sbo synchronize "$sbo_state" \
            "SBo repository synchronization was not applicable: $SBO_MODULE_REASON" 0
        emit_action_completed_event sbo build_queues "$sbo_state" \
            "SBo queue generation was not applicable: $SBO_MODULE_REASON" 0
    fi

    emit_module_started_event elf "ELF dependency module started"
    if [ "$ELF_MODULE_RUN" -eq 1 ]; then
        emit_action_started_event elf scan_dependencies "Scanning ELF dependencies statically"
        detect_broken_elf_objects
        map_broken_objects_to_sbo_packages
        if [ -s "$BROKEN" ]; then
            elf_state=warning
        else
            elf_state=success
        fi
        emit_action_completed_event elf scan_dependencies "$elf_state" \
            "ELF dependency scan completed" 0
    else
        elf_state=$ELF_MODULE_STATE
        : > "$BROKEN"
        emit_action_completed_event elf scan_dependencies "$elf_state" \
            "ELF dependency scan was not applicable: $ELF_MODULE_REASON" 0
    fi
    emit_module_completed_event elf "$elf_state" "ELF dependency module completed" 0

    if [ "$SBO_MODULE_RUN" -eq 1 ]; then
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

    emit_action_started_event boot update_grub "Updating GRUB configuration when required"
    update_grub_configuration
    if [ "$GRUB_REQUIRED" -eq 0 ]; then
        emit_action_completed_event boot update_grub skipped \
            "GRUB configuration update was not required" 0
    elif [ "$GRUB_UPDATE" -eq 0 ]; then
        emit_action_completed_event boot update_grub "$boot_state" \
            "GRUB configuration update was not applicable: mode=$BOOT_MODE, $BOOT_MODULE_REASON" 0
    elif [ "$GRUB_OK" -eq 1 ]; then
        [ "$boot_state" != failed ] && boot_state=success
        emit_action_completed_event boot update_grub success \
            "GRUB configuration update completed" 0
    else
        boot_state=failed
        emit_action_completed_event boot update_grub failed \
            "GRUB configuration update failed" 1
    fi

    action_exit=0
    [ "$boot_state" = failed ] && action_exit=1
    emit_module_completed_event boot "$boot_state" \
        "Boot preparation module completed" "$action_exit"

    print_summary
}

# Entry point

main() {
    local workflow_result=0
    local result

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

    if [ "$OPERATION" = "dry-run" ]; then
        initialize_dry_run_runtime
    else
        initialize_runtime
    fi

    trap cleanup EXIT INT TERM HUP
    rotate_logs
    configure_logging
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

    FINISHED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
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

main "$@"
