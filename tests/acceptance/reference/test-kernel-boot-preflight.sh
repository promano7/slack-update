#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/kernel-boot-preflight
TARGET=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_VALUE=
SLACKWARE_VERSION=
FIRMWARE_MODE=unknown
BOOTLOADER_CLASSIFICATION=unknown
BOOTLOADER_SUPPORT=unsupported
MKINITRD_CONFIG_STATE=missing

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 [options]

Collect a non-destructive boot-path preflight before the deferred Slackware 15.0
kernel packages are updated. The scenario identifies firmware mode, probable
boot loader, mkinitrd configuration, installed and repository kernel records,
and relevant boot artifacts. It never changes Slackpkg configuration, packages,
initrd images, or boot-loader files.

Required options:
      --target slackware-15.0  Declare the supported acceptance target

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
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

    [ "$TARGET" = slackware-15.0 ] || {
        error '--target must be slackware-15.0'
        return 1
    }

    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in
            /*) ;;
            *)
                error '--output-dir must be absolute'
                return 1
                ;;
        esac
    fi
}

capture_package_database() {
    local database=$1
    local output=$2

    [ -d "$database" ] || return 1
    find -H "$database" -maxdepth 1 -type f -printf '%f\0' 2>/dev/null \
        | sort -z \
        | xargs -0 -r -n 1 printf '%s\n' \
        | sha256sum \
        | awk '{print $1}' > "$output"
}

capture_path_record() {
    local path=$1

    printf 'path=%s\n' "$path"
    if [ -L "$path" ]; then
        printf 'type=symlink\n'
        printf 'target=%s\n' "$(readlink -- "$path" 2>/dev/null || true)"
        printf 'resolved=%s\n' "$(readlink -e -- "$path" 2>/dev/null || true)"
    elif [ -f "$path" ]; then
        printf 'type=file\n'
        printf 'size=%s\n' "$(stat -c '%s' -- "$path" 2>/dev/null || true)"
        printf 'mode=%s\n' "$(stat -c '%a' -- "$path" 2>/dev/null || true)"
        printf 'sha256=%s\n' "$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')"
    elif [ -d "$path" ]; then
        printf 'type=directory\n'
        printf 'mode=%s\n' "$(stat -c '%a' -- "$path" 2>/dev/null || true)"
    else
        printf 'type=missing\n'
    fi
    printf '\n'
}

capture_boot_artifacts() {
    local output=$1
    local path

    : > "$output" || return 1
    for path in \
        /boot/vmlinuz \
        /boot/vmlinuz-generic \
        /boot/vmlinuz-huge \
        /boot/initrd.gz \
        /boot/grub/grub.cfg \
        /etc/lilo.conf \
        /boot/efi/EFI/Slackware/elilo.conf \
        /boot/efi/EFI/Slackware/vmlinuz \
        /boot/efi/EFI/Slackware/initrd.gz \
        /etc/mkinitrd.conf \
        /etc/slackpkg/blacklist; do
        capture_path_record "$path" >> "$output"
    done
}

read_scalar_assignment() {
    local file=$1
    local name=$2
    local line value count=0 result=

    [ -f "$file" ] && [ ! -L "$file" ] && [ -r "$file" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "${name}"=*)
                value=${line#*=}
                value=${value%%#*}
                value=${value#\"}
                value=${value%\"}
                value=${value#\'}
                value=${value%\'}
                value=${value#"${value%%[![:space:]]*}"}
                value=${value%"${value##*[![:space:]]}"}
                count=$((count + 1))
                result=$value
                ;;
        esac
    done < "$file"
    [ "$count" -eq 1 ] || return 1
    printf '%s\n' "$result"
}

capture_mkinitrd_summary() {
    local output=$1
    local variable value

    : > "$output" || return 1
    if [ ! -e /etc/mkinitrd.conf ]; then
        MKINITRD_CONFIG_STATE=missing
        printf 'state=missing\n' > "$output"
        return 0
    fi
    if [ -L /etc/mkinitrd.conf ] || [ ! -f /etc/mkinitrd.conf ] || [ ! -r /etc/mkinitrd.conf ]; then
        MKINITRD_CONFIG_STATE=unsafe
        printf 'state=unsafe\n' > "$output"
        return 0
    fi

    MKINITRD_CONFIG_STATE=readable
    printf 'state=readable\n' > "$output"
    for variable in KERNEL_VERSION OUTPUT_IMAGE OUTPUT ROOTDEV ROOTFS MODULE_LIST LUKSDEV LVM RAID WAIT; do
        if value=$(read_scalar_assignment /etc/mkinitrd.conf "$variable" 2>/dev/null); then
            printf '%s=%s\n' "$variable" "$value" >> "$output"
        else
            printf '%s=<missing-or-ambiguous>\n' "$variable" >> "$output"
        fi
    done
}

capture_kernel_records() {
    local output=$1
    local package

    : > "$output" || return 1
    for package in kernel-generic kernel-huge kernel-modules kernel-headers kernel-source kernel-firmware; do
        printf '[installed:%s]\n' "$package" >> "$output"
        find -H /var/log/packages -maxdepth 1 -type f -name "${package}-*" -printf '%f\n' 2>/dev/null \
            | LC_ALL=C sort >> "$output"
        printf '[repository:%s]\n' "$package" >> "$output"
        if [ -r /var/lib/slackpkg/pkglist ]; then
            awk -v package="$package" '
                $0 ~ "(^|[[:space:]])" package "([[:space:]]|$)" { print }
            ' /var/lib/slackpkg/pkglist >> "$output"
        fi
        printf '\n' >> "$output"
    done
}

capture_blacklist_summary() {
    local output=$1
    local package

    : > "$output" || return 1
    if [ ! -r /etc/slackpkg/blacklist ]; then
        printf 'state=unreadable\n' > "$output"
        return 0
    fi
    printf 'state=readable\n' > "$output"
    for package in kernel-generic kernel-huge kernel-modules; do
        if grep -Eq "^[[:space:]]*${package}([[:space:]]*(#.*)?)?$" /etc/slackpkg/blacklist; then
            printf '%s=deferred\n' "$package" >> "$output"
        else
            printf '%s=not-deferred\n' "$package" >> "$output"
        fi
    done
}

detect_firmware_mode() {
    if [ -d /sys/firmware/efi ]; then
        FIRMWARE_MODE=uefi
    else
        FIRMWARE_MODE=bios
    fi
}

detect_bootloader() {
    local grub=0 lilo=0 elilo=0 count

    [ -f /boot/grub/grub.cfg ] && command -v grub-mkconfig >/dev/null 2>&1 && grub=1
    [ -f /etc/lilo.conf ] && command -v lilo >/dev/null 2>&1 && lilo=1
    if [ "$FIRMWARE_MODE" = uefi ]; then
        if [ -f /boot/efi/EFI/Slackware/elilo.conf ] || command -v eliloconfig >/dev/null 2>&1; then
            elilo=1
        fi
    fi

    count=$((grub + lilo + elilo))
    if [ "$count" -gt 1 ]; then
        BOOTLOADER_CLASSIFICATION=ambiguous
        BOOTLOADER_SUPPORT=blocked
    elif [ "$grub" -eq 1 ]; then
        BOOTLOADER_CLASSIFICATION=grub
        BOOTLOADER_SUPPORT=reference-supported
    elif [ "$lilo" -eq 1 ]; then
        BOOTLOADER_CLASSIFICATION=lilo
        BOOTLOADER_SUPPORT=reference-unsupported
    elif [ "$elilo" -eq 1 ]; then
        BOOTLOADER_CLASSIFICATION=elilo
        BOOTLOADER_SUPPORT=reference-unsupported
    else
        BOOTLOADER_CLASSIFICATION=unknown
        BOOTLOADER_SUPPORT=blocked
    fi
}

capture_bootloader_details() {
    local output=$1
    local command_name

    {
        printf 'firmware_mode=%s\n' "$FIRMWARE_MODE"
        printf 'classification=%s\n' "$BOOTLOADER_CLASSIFICATION"
        printf 'reference_support=%s\n' "$BOOTLOADER_SUPPORT"
        for command_name in lilo eliloconfig grub-mkconfig grub-script-check efibootmgr mkinitrd; do
            if command -v "$command_name" >/dev/null 2>&1; then
                printf 'command.%s=%s\n' "$command_name" "$(command -v "$command_name")"
            else
                printf 'command.%s=<missing>\n' "$command_name"
            fi
        done
        if [ "$FIRMWARE_MODE" = uefi ] && command -v efibootmgr >/dev/null 2>&1; then
            printf '\n[efibootmgr]\n'
            efibootmgr -v 2>&1 || true
        fi
        if [ -r /etc/lilo.conf ]; then
            printf '\n[lilo-directives]\n'
            grep -E '^[[:space:]]*(boot|image|initrd|root|label|other|append|read-only|read-write)[[:space:]]*=' \
                /etc/lilo.conf 2>/dev/null || true
        fi
        if [ -r /boot/efi/EFI/Slackware/elilo.conf ]; then
            printf '\n[elilo-directives]\n'
            grep -E '^[[:space:]]*(image|initrd|root|label|append|read-only|read-write)[[:space:]]*=' \
                /boot/efi/EFI/Slackware/elilo.conf 2>/dev/null || true
        fi
    } > "$output"
}

write_summary() {
    local output=$1

    cat > "$output" <<EOF_SUMMARY
scenario=kernel-boot-preflight
target=$TARGET
hostname=$HOSTNAME_VALUE
slackware_version=$SLACKWARE_VERSION
running_kernel=$(uname -r)
firmware_mode=$FIRMWARE_MODE
bootloader=$BOOTLOADER_CLASSIFICATION
reference_support=$BOOTLOADER_SUPPORT
mkinitrd_config_state=$MKINITRD_CONFIG_STATE
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-kernel-boot-preflight-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive" || return 1
    sha256sum -- "$archive" > "$sidecar" || return 1
    chmod 0600 -- "$sidecar" || return 1

    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    if id "$owner" >/dev/null 2>&1; then
        group=$(id -gn "$owner")
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
            "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
    fi
}

main() {
    local timestamp

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
    HOSTNAME_VALUE=$(hostname -f 2>/dev/null || hostname)
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    if [ -z "$OUTPUT_DIR" ]; then
        OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    fi
    [ ! -e "$OUTPUT_DIR" ] || {
        error "output directory already exists: $OUTPUT_DIR"
        return 2
    }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"
    : > "$ASSERTION_LOG"

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.before.sha256" \
        && record_pass 'the installed package database was captured before inspection' \
        || record_failure 'the installed package database could not be captured'
    capture_boot_artifacts "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the boot artifacts were captured before inspection' \
        || record_failure 'the boot artifacts could not be captured'

    detect_firmware_mode
    detect_bootloader
    capture_bootloader_details "$OUTPUT_DIR/bootloader.txt"
    capture_mkinitrd_summary "$OUTPUT_DIR/mkinitrd.txt"
    capture_kernel_records "$OUTPUT_DIR/kernel-records.txt"
    capture_blacklist_summary "$OUTPUT_DIR/blacklist.txt"

    record_pass "firmware mode was classified as $FIRMWARE_MODE"
    case "$BOOTLOADER_CLASSIFICATION" in
        grub|lilo|elilo) record_pass "one probable boot loader was classified: $BOOTLOADER_CLASSIFICATION" ;;
        ambiguous) record_failure 'multiple probable boot loaders were detected' ;;
        *) record_failure 'the active boot loader could not be classified' ;;
    esac
    if [ "$MKINITRD_CONFIG_STATE" = readable ]; then
        record_pass 'mkinitrd.conf is a readable regular file'
    else
        record_failure "mkinitrd.conf state is $MKINITRD_CONFIG_STATE"
    fi
    if grep -q '^kernel-generic=deferred$' "$OUTPUT_DIR/blacklist.txt" \
        && grep -q '^kernel-huge=deferred$' "$OUTPUT_DIR/blacklist.txt" \
        && grep -q '^kernel-modules=deferred$' "$OUTPUT_DIR/blacklist.txt"; then
        record_pass 'the three boot-kernel packages remain deferred in the Slackpkg blacklist'
    else
        record_failure 'the expected boot-kernel blacklist deferral is incomplete'
    fi

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.after.sha256" \
        && record_pass 'the installed package database was captured after inspection' \
        || record_failure 'the installed package database could not be recaptured'
    capture_boot_artifacts "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the boot artifacts were captured after inspection' \
        || record_failure 'the boot artifacts could not be recaptured'

    if cmp -s -- "$OUTPUT_DIR/packages.before.sha256" "$OUTPUT_DIR/packages.after.sha256"; then
        : > "$OUTPUT_DIR/packages.diff"
        record_pass 'the preflight did not modify the installed package database'
    else
        diff -u -- "$OUTPUT_DIR/packages.before.sha256" "$OUTPUT_DIR/packages.after.sha256" \
            > "$OUTPUT_DIR/packages.diff" 2>&1 || true
        record_failure 'the preflight modified the installed package database'
    fi
    if cmp -s -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt"; then
        : > "$OUTPUT_DIR/boot.diff"
        record_pass 'the preflight did not modify observed boot artifacts'
    else
        diff -u -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
            > "$OUTPUT_DIR/boot.diff" 2>&1 || true
        record_failure 'the preflight modified observed boot artifacts'
    fi

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Boot summary: firmware=%s, loader=%s, reference-support=%s, mkinitrd=%s\n' \
        "$FIRMWARE_MODE" "$BOOTLOADER_CLASSIFICATION" "$BOOTLOADER_SUPPORT" "$MKINITRD_CONFIG_STATE"
    printf 'Preflight only: no package, blacklist, initrd, or boot-loader change was authorized.\n'
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
