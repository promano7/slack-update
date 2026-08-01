#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/elilo-generator-preflight
TARGET=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_VALUE=
SLACKWARE_VERSION=
RUNNING_KERNEL=
GENERATOR=/usr/share/mkinitrd/mkinitrd_command_generator.sh
ELILO_DIRECTORY=/boot/efi/EFI/Slackware
ELILO_CONFIG=$ELILO_DIRECTORY/elilo.conf
ELILO_IMAGE=
ELILO_INITRD=
GENERATOR_STATUS=-1
GENERATOR_COMMAND_COUNT=0
ELILO_KERNEL_MATCH_COUNT=0
ELILO_KERNEL_SOURCE=
ELILO_KERNEL_FLAVOR=unknown
ELILO_KERNEL_VERSION_MATCH=no

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 [options]

Collect a non-destructive ELILO and mkinitrd-command-generator preflight for the
currently running Slackware 15.0 kernel. The scenario maps the ELILO kernel
copy to one unique versioned /boot source by content and records the generator's
proposed mkinitrd command. It never executes the proposed command and never
changes packages, the blacklist, initrd images, or EFI files.

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
        if [ -f "$path" ]; then
            printf 'sha256=%s\n' "$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')"
        fi
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

capture_state() {
    local output=$1
    local path

    : > "$output" || return 1
    while IFS= read -r -d '' path; do
        capture_path_record "$path" >> "$output"
    done < <(
        find /boot -maxdepth 1 \( -type f -o -type l \) -name 'vmlinuz*' -print0 2>/dev/null \
            | sort -z
    )
    for path in \
        /boot/initrd.gz \
        "$ELILO_CONFIG" \
        "$ELILO_DIRECTORY/vmlinuz" \
        "$ELILO_DIRECTORY/initrd.gz" \
        /etc/mkinitrd.conf \
        /etc/slackpkg/blacklist; do
        capture_path_record "$path" >> "$output"
    done
}

read_elilo_assignment() {
    local name=$1
    local line value count=0 result=

    [ -f "$ELILO_CONFIG" ] && [ ! -L "$ELILO_CONFIG" ] && [ -r "$ELILO_CONFIG" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line%%#*}
        case "$line" in
            *"$name"*=*)
                if printf '%s\n' "$line" | grep -Eq "^[[:space:]]*${name}[[:space:]]*="; then
                    value=${line#*=}
                    value=${value#"${value%%[![:space:]]*}"}
                    value=${value%"${value##*[![:space:]]}"}
                    value=${value#\"}
                    value=${value%\"}
                    value=${value#\'}
                    value=${value%\'}
                    count=$((count + 1))
                    result=$value
                fi
                ;;
        esac
    done < "$ELILO_CONFIG"
    [ "$count" -eq 1 ] && [ -n "$result" ] || return 1
    case "$result" in
        /*|*..*|*/*) return 1 ;;
    esac
    printf '%s\n' "$result"
}

capture_mounts() {
    local output=$1

    {
        printf '[root]\n'
        findmnt -n -o SOURCE,FSTYPE,OPTIONS / 2>&1 || true
        printf '\n[efi-system-partition]\n'
        findmnt -n -o SOURCE,FSTYPE,OPTIONS /boot/efi 2>&1 || true
    } > "$output"
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

run_generator_probe() {
    local stdout=$1
    local stderr=$2
    local commands=$3

    : > "$stdout" || return 1
    : > "$stderr" || return 1
    : > "$commands" || return 1

    bash "$GENERATOR" -k "$RUNNING_KERNEL" > "$stdout" 2> "$stderr"
    GENERATOR_STATUS=$?
    grep -E '^[[:space:]]*mkinitrd[[:space:]]' "$stdout" > "$commands" 2>/dev/null || true
    GENERATOR_COMMAND_COUNT=$(wc -l < "$commands" | tr -d '[:space:]')
}

compare_regular_files() {
    local first=$1
    local second=$2

    [ -f "$first" ] && [ ! -L "$first" ] \
        && [ -f "$second" ] && [ ! -L "$second" ] \
        && cmp -s -- "$first" "$second"
}

capture_elilo_kernel_sources() {
    local boot_directory=$1
    local efi_image=$2
    local running_kernel=$3
    local output=$4
    local matches_file="$output.matches"
    local path resolved type target hash matches version_matches
    local basename

    ELILO_KERNEL_MATCH_COUNT=0
    ELILO_KERNEL_SOURCE=
    ELILO_KERNEL_FLAVOR=unknown
    ELILO_KERNEL_VERSION_MATCH=no
    : > "$output" || return 1
    : > "$matches_file" || return 1

    [ -d "$boot_directory" ] || return 1
    [ -f "$efi_image" ] && [ ! -L "$efi_image" ] || return 1

    while IFS= read -r -d '' path; do
        [ -f "$path" ] || continue
        resolved=$(readlink -e -- "$path" 2>/dev/null || true)
        [ -n "$resolved" ] || continue
        if [ -L "$path" ]; then
            type=symlink
            target=$(readlink -- "$path" 2>/dev/null || true)
        else
            type=file
            target=
        fi
        hash=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')
        matches=no
        if cmp -s -- "$path" "$efi_image"; then
            matches=yes
            printf '%s\n' "$resolved" >> "$matches_file"
        fi
        basename=${resolved##*/}
        version_matches=no
        case "$basename" in
            "vmlinuz-generic-$running_kernel"|"vmlinuz-huge-$running_kernel")
                version_matches=yes
                ;;
        esac
        {
            printf 'path=%s\n' "$path"
            printf 'type=%s\n' "$type"
            printf 'target=%s\n' "$target"
            printf 'resolved=%s\n' "$resolved"
            printf 'sha256=%s\n' "$hash"
            printf 'matches_elilo=%s\n' "$matches"
            printf 'matches_running_kernel_name=%s\n' "$version_matches"
            printf '\n'
        } >> "$output"
    done < <(
        find "$boot_directory" -maxdepth 1 \( -type f -o -type l \) -name 'vmlinuz*' -print0 2>/dev/null \
            | sort -z
    )

    sort -u "$matches_file" -o "$matches_file"
    ELILO_KERNEL_MATCH_COUNT=$(wc -l < "$matches_file" | tr -d '[:space:]')
    if [ "$ELILO_KERNEL_MATCH_COUNT" -eq 1 ]; then
        ELILO_KERNEL_SOURCE=$(cat "$matches_file")
        basename=${ELILO_KERNEL_SOURCE##*/}
        case "$basename" in
            "vmlinuz-generic-$running_kernel")
                ELILO_KERNEL_FLAVOR=generic
                ELILO_KERNEL_VERSION_MATCH=yes
                ;;
            "vmlinuz-huge-$running_kernel")
                ELILO_KERNEL_FLAVOR=huge
                ELILO_KERNEL_VERSION_MATCH=yes
                ;;
            vmlinuz-generic-*)
                ELILO_KERNEL_FLAVOR=generic
                ;;
            vmlinuz-huge-*)
                ELILO_KERNEL_FLAVOR=huge
                ;;
        esac
    fi
    rm -f -- "$matches_file"
}

write_summary() {
    local output=$1

    cat > "$output" <<EOF_SUMMARY
scenario=elilo-generator-preflight
target=$TARGET
hostname=$HOSTNAME_VALUE
slackware_version=$SLACKWARE_VERSION
running_kernel=$RUNNING_KERNEL
elilo_image=$ELILO_IMAGE
elilo_initrd=$ELILO_INITRD
generator=$GENERATOR
generator_exit_code=$GENERATOR_STATUS
generator_command_count=$GENERATOR_COMMAND_COUNT
elilo_kernel_match_count=$ELILO_KERNEL_MATCH_COUNT
elilo_kernel_source=$ELILO_KERNEL_SOURCE
elilo_kernel_flavor=$ELILO_KERNEL_FLAVOR
elilo_kernel_version_match=$ELILO_KERNEL_VERSION_MATCH
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-elilo-generator-preflight-${timestamp}.tar.gz"
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
    RUNNING_KERNEL=$(uname -r)
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
    capture_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the ELILO and initrd state was captured before inspection' \
        || record_failure 'the ELILO and initrd state could not be captured'

    if [ -d /sys/firmware/efi ]; then
        record_pass 'the system is running in UEFI mode'
    else
        record_failure 'the system is not running in UEFI mode'
    fi
    if [ -f "$ELILO_CONFIG" ] && [ ! -L "$ELILO_CONFIG" ] && [ -r "$ELILO_CONFIG" ]; then
        record_pass 'elilo.conf is a readable regular file'
    else
        record_failure 'elilo.conf is missing, unreadable, or unsafe'
    fi

    if ELILO_IMAGE=$(read_elilo_assignment image); then
        record_pass "ELILO has one safe image directive: $ELILO_IMAGE"
    else
        record_failure 'ELILO image directive is missing, ambiguous, or unsafe'
    fi
    if ELILO_INITRD=$(read_elilo_assignment initrd); then
        record_pass "ELILO has one safe initrd directive: $ELILO_INITRD"
    else
        record_failure 'ELILO initrd directive is missing, ambiguous, or unsafe'
    fi

    capture_mounts "$OUTPUT_DIR/mounts.txt"
    if findmnt -n /boot/efi >/dev/null 2>&1; then
        record_pass 'the EFI system partition mount was identified'
    else
        record_failure 'the EFI system partition mount could not be identified'
    fi

    if [ -f "$GENERATOR" ] && [ ! -L "$GENERATOR" ] && [ -r "$GENERATOR" ]; then
        printf 'path=%s\nsha256=%s\n' "$GENERATOR" \
            "$(sha256sum -- "$GENERATOR" | awk '{print $1}')" > "$OUTPUT_DIR/generator.txt"
        record_pass 'the Slackware mkinitrd command generator is a readable regular file'
        run_generator_probe "$OUTPUT_DIR/generator.stdout" "$OUTPUT_DIR/generator.stderr" \
            "$OUTPUT_DIR/generator.commands"
        if [ "$GENERATOR_STATUS" -eq 0 ]; then
            record_pass 'the command generator completed without executing mkinitrd'
        else
            record_failure "the command generator exited with status $GENERATOR_STATUS"
        fi
        if [ "$GENERATOR_COMMAND_COUNT" -eq 1 ]; then
            record_pass 'the command generator proposed exactly one mkinitrd command'
        else
            record_failure "the command generator proposed $GENERATOR_COMMAND_COUNT mkinitrd commands"
        fi
        if grep -Eq -- "(^|[[:space:]])-k[[:space:]]+$RUNNING_KERNEL([[:space:]]|$)" \
            "$OUTPUT_DIR/generator.commands"; then
            record_pass 'the proposed command targets the running kernel version'
        else
            record_failure 'the proposed command does not target the running kernel version'
        fi
        if grep -Eq -- '(^|[[:space:]])-o[[:space:]]+/boot/initrd\.gz([[:space:]]|$)' \
            "$OUTPUT_DIR/generator.commands"; then
            record_pass 'the proposed command targets /boot/initrd.gz'
        else
            record_failure 'the proposed command does not target /boot/initrd.gz'
        fi
    else
        : > "$OUTPUT_DIR/generator.txt"
        : > "$OUTPUT_DIR/generator.stdout"
        : > "$OUTPUT_DIR/generator.stderr"
        : > "$OUTPUT_DIR/generator.commands"
        record_failure 'the Slackware mkinitrd command generator is missing or unsafe'
    fi

    if capture_elilo_kernel_sources /boot "$ELILO_DIRECTORY/$ELILO_IMAGE" \
        "$RUNNING_KERNEL" "$OUTPUT_DIR/kernel-sources.txt"; then
        if [ "$ELILO_KERNEL_MATCH_COUNT" -eq 1 ]; then
            record_pass "the ELILO kernel copy matches one unique /boot source: $ELILO_KERNEL_SOURCE"
        else
            record_failure "the ELILO kernel copy matches $ELILO_KERNEL_MATCH_COUNT unique /boot sources"
        fi
        if [ "$ELILO_KERNEL_VERSION_MATCH" = yes ]; then
            record_pass "the ELILO kernel source matches the running $ELILO_KERNEL_FLAVOR kernel version"
        else
            record_failure 'the ELILO kernel source does not identify the running kernel version'
        fi
    else
        : > "$OUTPUT_DIR/kernel-sources.txt"
        record_failure 'the ELILO kernel-source inventory could not be generated'
        record_failure 'the ELILO kernel source could not be classified'
    fi
    if compare_regular_files /boot/initrd.gz "$ELILO_DIRECTORY/$ELILO_INITRD"; then
        record_pass 'the active /boot initrd matches the ELILO initrd copy'
    else
        record_failure 'the active /boot initrd does not match the ELILO initrd copy'
    fi

    capture_blacklist_summary "$OUTPUT_DIR/blacklist.txt"
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
    capture_state "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the ELILO and initrd state was captured after inspection' \
        || record_failure 'the ELILO and initrd state could not be recaptured'

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
        record_pass 'the preflight did not modify ELILO or initrd state'
    else
        diff -u -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
            > "$OUTPUT_DIR/boot.diff" 2>&1 || true
        record_failure 'the preflight modified ELILO or initrd state'
    fi

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'ELILO generator summary: kernel=%s, image=%s, initrd=%s, source=%s, flavor=%s, commands=%s\n' \
        "$RUNNING_KERNEL" "${ELILO_IMAGE:-unknown}" "${ELILO_INITRD:-unknown}" \
        "${ELILO_KERNEL_SOURCE:-unknown}" "$ELILO_KERNEL_FLAVOR" "$GENERATOR_COMMAND_COUNT"
    printf 'Preflight only: the proposed mkinitrd command was recorded but never executed.\n'
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
