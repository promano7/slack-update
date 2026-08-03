#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_ACCEPTED_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-accepted.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-kernel-boot-preflight

TARGET=
TARGET_KERNEL=
CONFIRM_CANDIDATES_SHA256=
ACCEPTED_PREFLIGHT=$DEFAULT_ACCEPTED_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_VALUE=
SLACKWARE_VERSION=
RUNNING_KERNEL=
PACKAGE_DATABASE_CONFIGURED=/var/log/packages
PACKAGE_DATABASE_RESOLVED=
INSTALLED_KERNEL_VERSION=
MKINITRD_KERNEL_VERSION=
MKINITRD_TRANSITION_REQUIRED=false
MKINITRD_STATE=unknown
INITRD_STATE=unknown
BOOT_MODE=unknown
BOOT_IMAGE=
GENERIC_KERNEL_PATH=
GENERIC_KERNEL_BASENAME=
GENERIC_SYMLINK_TRANSITION_REQUIRED=false
PACKAGE_LAYOUT=unknown
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Collect a non-destructive Slackware-current boot preflight for the monolithic
kernel-generic package model. The script validates the accepted normal-update
record, installed and repository kernel records, initrd-managed or direct-generic
boot artifacts, module trees, and GRUB prerequisites. It never installs packages, runs mkinitrd,
regenerates GRUB, or authorizes apply.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --accepted-preflight PATH  Select the reviewed normal-update record
      --output-dir PATH          Store evidence under an absolute, new directory
  -h, --help                     Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"
}
record_failure() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2
}

is_sha256() {
    [ "${#1}" -eq 64 ] || return 1
    case "$1" in *[!0-9A-Fa-f]*) return 1 ;; esac
}

is_safe_kernel_version() {
    case "$1" in
        ''|.|..|*/*|*[[:space:]]*|*[!A-Za-z0-9._+-]*) return 1 ;;
        *) return 0 ;;
    esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                [ "$#" -ge 2 ] || { error '--target requires a value'; return 1; }
                TARGET=$2; shift 2 ;;
            --confirm-candidates-sha256)
                [ "$#" -ge 2 ] || { error '--confirm-candidates-sha256 requires a value'; return 1; }
                CONFIRM_CANDIDATES_SHA256=$2; shift 2 ;;
            --confirm-target-kernel)
                [ "$#" -ge 2 ] || { error '--confirm-target-kernel requires a value'; return 1; }
                TARGET_KERNEL=$2; shift 2 ;;
            --accepted-preflight)
                [ "$#" -ge 2 ] || { error '--accepted-preflight requires a value'; return 1; }
                ACCEPTED_PREFLIGHT=$2; shift 2 ;;
            --output-dir)
                [ "$#" -ge 2 ] || { error '--output-dir requires a value'; return 1; }
                OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || {
        error '--confirm-candidates-sha256 must contain exactly 64 hexadecimal characters'
        return 1
    }
    CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
    is_safe_kernel_version "$TARGET_KERNEL" || { error 'unsafe target kernel version'; return 1; }
    for path in "$ACCEPTED_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

package_record_version() {
    local record=$1
    record=${record##*/}
    printf '%s\n' "$record" | rev | cut -d- -f3 | rev
}

read_scalar_assignment() {
    local file=$1 name=$2 line value count=0 result=
    [ -f "$file" ] && [ ! -L "$file" ] && [ -r "$file" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line%$'\r'}
        case "$line" in
            "${name}"=*)
                value=${line#*=}
                value=${value%%#*}
                value=${value#\"}; value=${value%\"}
                value=${value#\'}; value=${value%\'}
                value=${value#"${value%%[![:space:]]*}"}
                value=${value%"${value##*[![:space:]]}"}
                count=$((count + 1)); result=$value
                ;;
        esac
    done < "$file"
    [ "$count" -eq 1 ] || return 1
    printf '%s\n' "$result"
}

validate_accepted_preflight() {
    python3 - "$ACCEPTED_PREFLIGHT" "$CONFIRM_CANDIDATES_SHA256" "$TARGET_KERNEL" <<'PY'
import json, sys
path, digest, target = sys.argv[1:]
try:
    data = json.load(open(path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
checks = [
    data.get('scenario') == 'normal-update',
    data.get('mode') == 'preflight',
    data.get('target') == 'slackware-current',
    data.get('accepted') is True,
    data.get('apply_authorized') is False,
    data.get('candidates', {}).get('candidate_set_sha256') == digest,
    data.get('candidates', {}).get('target_kernel_version') == target,
    f'kernel-generic-{target}-x86_64-1.txz' in data.get('candidates', {}).get('kernel', []),
    f'kernel-headers-{target}-x86-1.txz' in data.get('candidates', {}).get('kernel', []),
]
raise SystemExit(0 if all(checks) else 1)
PY
}

resolve_package_database() {
    [ -e "$PACKAGE_DATABASE_CONFIGURED" ] || return 1
    PACKAGE_DATABASE_RESOLVED=$(readlink -e -- "$PACKAGE_DATABASE_CONFIGURED") || return 1
    [ "$PACKAGE_DATABASE_RESOLVED" = /var/lib/pkgtools/packages ] || return 1
    [ -d "$PACKAGE_DATABASE_RESOLVED" ] && [ ! -L "$PACKAGE_DATABASE_RESOLVED" ] \
        && [ -r "$PACKAGE_DATABASE_RESOLVED" ] || return 1
    [ -z "$(find "$PACKAGE_DATABASE_RESOLVED" -maxdepth 1 -type l -print -quit 2>/dev/null)" ]
}

find_exact_records() {
    local package=$1
    find -H "$PACKAGE_DATABASE_CONFIGURED" -maxdepth 1 -type f -name "${package}-*" -printf '%f\n' 2>/dev/null \
        | LC_ALL=C sort
}

capture_package_state() {
    local output=$1 package
    : > "$output" || return 1
    for package in kernel-generic kernel-huge kernel-modules kernel-headers kernel-source kernel-firmware; do
        printf '[installed:%s]\n' "$package" >> "$output"
        find_exact_records "$package" >> "$output"
        printf '[repository:%s]\n' "$package" >> "$output"
        if [ -r /var/lib/slackpkg/pkglist ]; then
            awk -v package="$package" '$0 ~ "(^|[[:space:]])" package "([[:space:]]|$)" { print }' \
                /var/lib/slackpkg/pkglist >> "$output"
        fi
        printf '\n' >> "$output"
    done
}

capture_boot_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in /etc/mkinitrd.conf /boot/initrd.gz /boot/vmlinuz-generic \
        "/boot/vmlinuz-$RUNNING_KERNEL" "/boot/vmlinuz-generic-$RUNNING_KERNEL" \
        /boot/grub/grub.cfg "/lib/modules/$RUNNING_KERNEL"; do
        printf '%s|' "$path" >> "$output"
        if [ -L "$path" ]; then
            printf 'symlink|%s|%s\n' "$(readlink -- "$path" 2>/dev/null || true)" \
                "$(readlink -e -- "$path" 2>/dev/null || true)" >> "$output"
        elif [ -f "$path" ]; then
            printf 'regular|%s|%s|%s\n' "$(stat -c '%a:%u:%g:%s' -- "$path")" \
                "$(sha256sum -- "$path" | awk '{print $1}')" "$(stat -c '%Y' -- "$path")" >> "$output"
        elif [ -d "$path" ]; then
            printf 'directory|%s|%s\n' "$(stat -c '%a:%u:%g' -- "$path")" \
                "$(find "$path" -xdev -type f 2>/dev/null | wc -l)" >> "$output"
        else
            printf 'missing||\n' >> "$output"
        fi
    done
}

capture_mkinitrd_summary() {
    local output=$1 variable value
    : > "$output" || return 1
    if [ ! -f /etc/mkinitrd.conf ] || [ -L /etc/mkinitrd.conf ] || [ ! -r /etc/mkinitrd.conf ]; then
        printf 'state=missing-or-unsafe\n' > "$output"
        return 1
    fi
    printf 'state=readable\n' > "$output"
    for variable in KERNEL_VERSION ROOTDEV ROOTFS MODULE_LIST OUTPUT_IMAGE OUTPUT LUKSDEV LVM RAID WAIT; do
        if value=$(read_scalar_assignment /etc/mkinitrd.conf "$variable" 2>/dev/null); then
            printf '%s=%s\n' "$variable" "$value" >> "$output"
        else
            printf '%s=<missing-or-ambiguous>\n' "$variable" >> "$output"
        fi
    done
    MKINITRD_KERNEL_VERSION=$(read_scalar_assignment /etc/mkinitrd.conf KERNEL_VERSION 2>/dev/null || true)
    [ -n "$MKINITRD_KERNEL_VERSION" ]
}

repository_target_count() {
    local package=$1 architecture=$2
    [ -r /var/lib/slackpkg/pkglist ] || { printf '0\n'; return; }
    grep -E "(^|[[:space:]])${package}([[:space:]]|$).*${TARGET_KERNEL}.*${architecture}" \
        /var/lib/slackpkg/pkglist 2>/dev/null | wc -l
}

capture_repository_module_evidence() {
    local output=$1
    : > "$output" || return 1
    if [ -r /var/lib/slackpkg/filelist ]; then
        grep -F "lib/modules/$TARGET_KERNEL/" /var/lib/slackpkg/filelist 2>/dev/null \
            | sed -n '1,200p' > "$output" || true
    fi
    if [ ! -s "$output" ] && [ -r /var/lib/slackpkg/slackware64-filelist.gz ]; then
        gzip -cd /var/lib/slackpkg/slackware64-filelist.gz 2>/dev/null \
            | grep -F "lib/modules/$TARGET_KERNEL/" | sed -n '1,200p' > "$output" || true
    fi
}


is_supported_running_kernel_image() {
    local basename=$1 version=$2
    case "$basename" in
        "vmlinuz-$version"|"vmlinuz-generic-$version") return 0 ;;
        *) return 1 ;;
    esac
}

classify_boot_mode_from_states() {
    local mkinitrd_state=$1 initrd_state=$2 basename=$3 version=$4
    if [ "$mkinitrd_state" = absent ] && [ "$initrd_state" = absent ] \
        && [ "$basename" = "vmlinuz-$version" ]; then
        printf '%s\n' direct-generic-no-initrd
        return 0
    fi
    if [ "$mkinitrd_state" = present ] && [ "$initrd_state" = present ] \
        && is_supported_running_kernel_image "$basename" "$version"; then
        printf '%s\n' mkinitrd-managed
        return 0
    fi
    return 1
}

package_record_owns_path() {
    local record=$1 relative_path=$2
    [ -n "$record" ] || return 1
    [ -f "$PACKAGE_DATABASE_RESOLVED/$record" ] || return 1
    grep -Fxq -- "$relative_path" "$PACKAGE_DATABASE_RESOLVED/$record"
}

repository_target_owns_path() {
    local relative_path=$1
    if [ -r /var/lib/slackpkg/filelist ] \
        && grep -Fq -- " $relative_path" /var/lib/slackpkg/filelist; then
        return 0
    fi
    if [ -r /var/lib/slackpkg/slackware64-filelist.gz ] \
        && gzip -cd /var/lib/slackpkg/slackware64-filelist.gz 2>/dev/null \
            | awk -v needle=" $relative_path" 'index($0, needle) { found=1 } END { exit !found }'; then
        return 0
    fi
    return 1
}

validate_generic_kernel_link() {
    local record=$1 resolved basename
    [ -L /boot/vmlinuz-generic ] || return 1
    resolved=$(readlink -e -- /boot/vmlinuz-generic 2>/dev/null) || return 1
    [ -f "$resolved" ] && [ ! -L "$resolved" ] && [ -r "$resolved" ] || return 1
    basename=${resolved##*/}
    is_supported_running_kernel_image "$basename" "$RUNNING_KERNEL" || return 1
    package_record_owns_path "$record" "boot/$basename" || return 1
    GENERIC_KERNEL_PATH=$resolved
    GENERIC_KERNEL_BASENAME=$basename
}

capture_boot_image() {
    local token count=0
    [ -r /proc/cmdline ] || return 1
    BOOT_IMAGE=
    for token in $(tr ' ' '\n' < /proc/cmdline); do
        case "$token" in
            BOOT_IMAGE=*)
                BOOT_IMAGE=${token#BOOT_IMAGE=}
                count=$((count + 1))
                ;;
        esac
    done
    [ "$count" -eq 1 ] || return 1
    case "$BOOT_IMAGE" in
        /boot/vmlinuz-generic|"/boot/$GENERIC_KERNEL_BASENAME") ;;
        *) return 1 ;;
    esac
    grep -Fq -- "$BOOT_IMAGE" /boot/grub/grub.cfg
}

capture_package_database_digest() {
    python3 - "$PACKAGE_DATABASE_RESOLVED" <<'PY_PACKAGE_DIGEST'
import hashlib
import os
import sys

root = os.fsencode(sys.argv[1])
digest = hashlib.sha256()
try:
    names = sorted(os.listdir(root))
    for name in names:
        path = os.path.join(root, name)
        stat_result = os.lstat(path)
        if not os.path.isfile(path) or os.path.islink(path):
            continue
        digest.update(name)
        digest.update(b'\0')
        with open(path, 'rb') as handle:
            for block in iter(lambda: handle.read(1024 * 1024), b''):
                digest.update(block)
        digest.update(b'\0')
except Exception:
    raise SystemExit(1)
print(digest.hexdigest())
PY_PACKAGE_DIGEST
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-kernel-boot-preflight
target=$TARGET
hostname=$HOSTNAME_VALUE
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
installed_kernel=$INSTALLED_KERNEL_VERSION
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
package_layout=$PACKAGE_LAYOUT
boot_mode=$BOOT_MODE
boot_image=$BOOT_IMAGE
generic_kernel_path=$GENERIC_KERNEL_PATH
generic_symlink_transition_required=$GENERIC_SYMLINK_TRANSITION_REQUIRED
mkinitrd_state=$MKINITRD_STATE
initrd_state=$INITRD_STATE
mkinitrd_kernel_version=$MKINITRD_KERNEL_VERSION
mkinitrd_transition_required=$MKINITRD_TRANSITION_REQUIRED
apply_ready=$APPLY_READY
apply_authorized=$APPLY_AUTHORIZED
EOF_SUMMARY
}

create_evidence_archive() {
    local parent base archive
    parent=$(dirname -- "$OUTPUT_DIR")
    base=${OUTPUT_DIR##*/}
    archive="$parent/${TARGET}-current-kernel-boot-preflight-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum "${archive##*/}") > "$archive.sha256" || return 1
    printf '%s\n' "$archive"
}

print_evidence_commands() {
    local archive=$1 owner=${SUDO_USER:-promano} group
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
        "$owner" "$group" "$archive.sha256" "/home/$owner/${archive##*/}.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' \
        "/home/$owner" "${archive##*/}.sha256"
}

main() {
    local timestamp archive before_digest= after_digest=
    local initial_state_captured=false final_state_captured=false
    local generic_records headers_records source_records huge_records modules_records
    local generic_count headers_count source_count huge_count modules_count

    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this real-system preflight requires root'; return 2; }
    for command_name in awk cmp cut date find grep gzip hostname id python3 readlink sed sha256sum sort stat tar tr wc; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command unavailable: $command_name"; return 2; }
    done
    [ -r /etc/slackware-version ] || { error '/etc/slackware-version is unavailable'; return 2; }
    SLACKWARE_VERSION=$(cat /etc/slackware-version)
    case "$SLACKWARE_VERSION" in Slackware\ *+|Slackware\ current*) ;; *) error "unexpected Slackware-current version marker: $SLACKWARE_VERSION"; return 2 ;; esac

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] || { error "output directory already exists: $OUTPUT_DIR"; return 2; }
    mkdir -p -- "$OUTPUT_DIR" || return 2
    chmod 0700 -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"
    : > "$ASSERTION_LOG"

    HOSTNAME_VALUE=$(hostname)
    RUNNING_KERNEL=$(uname -r)
    printf 'hostname=%s\nslackware_version=%s\nrunning_kernel=%s\ncmdline=%s\n' \
        "$HOSTNAME_VALUE" "$SLACKWARE_VERSION" "$RUNNING_KERNEL" \
        "$(cat /proc/cmdline 2>/dev/null || true)" > "$OUTPUT_DIR/host.txt"

    if validate_accepted_preflight; then record_pass 'the accepted 57-candidate normal-update record matches the requested kernel transition'; else record_failure 'the accepted normal-update record does not match the requested candidate set and target kernel'; fi
    if resolve_package_database; then
        record_pass "the Slackware package database resolved safely to $PACKAGE_DATABASE_RESOLVED"
        before_digest=$(capture_package_database_digest 2>/dev/null || true)
        if [ -n "$before_digest" ] && capture_boot_state "$OUTPUT_DIR/boot.before.txt"; then
            initial_state_captured=true
            record_pass 'the package database and boot state were captured before inspection'
        else
            record_failure 'the initial package database or boot state could not be captured'
        fi
    else
        record_failure 'the Slackware package database could not be resolved safely'
    fi

    capture_package_state "$OUTPUT_DIR/kernel-records.txt" || record_failure 'kernel package records could not be captured'
    generic_records=$(find_exact_records kernel-generic); generic_count=$(printf '%s\n' "$generic_records" | sed '/^$/d' | wc -l)
    headers_records=$(find_exact_records kernel-headers); headers_count=$(printf '%s\n' "$headers_records" | sed '/^$/d' | wc -l)
    source_records=$(find_exact_records kernel-source); source_count=$(printf '%s\n' "$source_records" | sed '/^$/d' | wc -l)
    huge_records=$(find_exact_records kernel-huge); huge_count=$(printf '%s\n' "$huge_records" | sed '/^$/d' | wc -l)
    modules_records=$(find_exact_records kernel-modules); modules_count=$(printf '%s\n' "$modules_records" | sed '/^$/d' | wc -l)

    if [ "$generic_count" -eq 1 ]; then
        INSTALLED_KERNEL_VERSION=$(package_record_version "$generic_records")
        record_pass "exactly one installed kernel-generic record was found: $INSTALLED_KERNEL_VERSION"
    else
        record_failure "expected one installed kernel-generic record, found $generic_count"
    fi
    if [ "$headers_count" -eq 1 ] && [ "$source_count" -eq 1 ]; then record_pass 'exactly one installed kernel-headers and kernel-source record were found'; else record_failure 'installed kernel-headers or kernel-source records are incomplete or ambiguous'; fi
    if [ "$huge_count" -eq 0 ] && [ "$modules_count" -eq 0 ]; then PACKAGE_LAYOUT=monolithic-generic; record_pass 'the installed Slackware-current kernel layout is monolithic kernel-generic'; else record_failure 'legacy kernel-huge or kernel-modules records coexist with the expected monolithic layout'; fi
    if [ "$RUNNING_KERNEL" = "$INSTALLED_KERNEL_VERSION" ]; then record_pass 'the running kernel matches the installed kernel-generic record'; else record_failure 'the running kernel does not match the installed kernel-generic record'; fi
    if [ -d "/lib/modules/$RUNNING_KERNEL" ]; then record_pass 'the running kernel module tree is present'; else record_failure 'the running kernel module tree is missing'; fi
    if [ -n "$generic_records" ] && grep -Fq "lib/modules/$RUNNING_KERNEL/" "$PACKAGE_DATABASE_RESOLVED/$generic_records"; then record_pass 'the installed kernel-generic record owns the running module tree'; else record_failure 'the installed kernel-generic record does not prove ownership of the running module tree'; fi

    if [ "$(repository_target_count kernel-generic x86_64)" -eq 1 ] && [ "$(repository_target_count kernel-headers x86)" -eq 1 ] && [ "$(repository_target_count kernel-source noarch)" -eq 1 ]; then record_pass 'the repository exposes one matching generic, headers, and source target record'; else record_failure 'the repository target kernel records are incomplete or ambiguous'; fi
    if [ "$(repository_target_count kernel-huge x86_64)" -eq 0 ] && [ "$(repository_target_count kernel-modules x86_64)" -eq 0 ]; then record_pass 'the repository target uses the monolithic kernel-generic layout'; else record_failure 'the repository unexpectedly exposes split target boot-kernel packages'; fi
    capture_repository_module_evidence "$OUTPUT_DIR/repository-module-evidence.txt"
    if [ -s "$OUTPUT_DIR/repository-module-evidence.txt" ]; then record_pass 'Slackpkg metadata exposes target kernel module paths for inspection'; else record_pass 'target module ownership will be revalidated from the installed kernel-generic record after package application'; fi

    if [ -f /boot/grub/grub.cfg ] && [ ! -L /boot/grub/grub.cfg ] \
        && command -v grub-mkconfig >/dev/null 2>&1 \
        && command -v grub-script-check >/dev/null 2>&1 \
        && grub-script-check /boot/grub/grub.cfg >/dev/null 2>&1; then
        record_pass 'GRUB has a regular syntax-valid active configuration and both required commands'
    else
        record_failure 'GRUB prerequisites or active configuration validation are incomplete or unsafe'
    fi

    if validate_generic_kernel_link "$generic_records"; then
        record_pass "the generic kernel symlink resolves to the package-owned running image $GENERIC_KERNEL_BASENAME"
    else
        record_failure 'the generic kernel symlink does not resolve to a package-owned running image'
    fi

    if [ -n "$GENERIC_KERNEL_BASENAME" ] \
        && repository_target_owns_path "boot/vmlinuz-$TARGET_KERNEL"; then
        GENERIC_SYMLINK_TRANSITION_REQUIRED=true
        record_pass 'Slackpkg metadata exposes the target versioned generic kernel image'
    else
        record_failure 'Slackpkg metadata does not expose the target versioned generic kernel image'
    fi

    if [ -n "$GENERIC_KERNEL_BASENAME" ] && capture_boot_image; then
        record_pass "the running GRUB command line and configuration reference $BOOT_IMAGE"
    else
        record_failure 'the running BOOT_IMAGE is missing, ambiguous, or absent from GRUB configuration'
    fi

    if [ ! -e /etc/mkinitrd.conf ]; then MKINITRD_STATE=absent; else MKINITRD_STATE=present; fi
    if [ ! -e /boot/initrd.gz ]; then INITRD_STATE=absent; else INITRD_STATE=present; fi
    if BOOT_MODE=$(classify_boot_mode_from_states "$MKINITRD_STATE" "$INITRD_STATE" \
        "$GENERIC_KERNEL_BASENAME" "$RUNNING_KERNEL" 2>/dev/null); then
        if [ "$BOOT_MODE" = direct-generic-no-initrd ]; then
            printf 'state=not-required\nboot_mode=%s\n' "$BOOT_MODE" > "$OUTPUT_DIR/mkinitrd-summary.txt"
            record_pass 'the host uses a coherent direct generic-kernel GRUB boot without mkinitrd.conf or initrd'
        elif [ -f /etc/mkinitrd.conf ] && [ ! -L /etc/mkinitrd.conf ] \
            && [ -r /etc/mkinitrd.conf ] && [ -s /boot/initrd.gz ] \
            && [ ! -L /boot/initrd.gz ]; then
            MKINITRD_STATE=managed
            INITRD_STATE=present
            if capture_mkinitrd_summary "$OUTPUT_DIR/mkinitrd-summary.txt"; then
                if [ "$MKINITRD_KERNEL_VERSION" = "$RUNNING_KERNEL" ]; then record_pass 'mkinitrd.conf currently matches the running kernel'; else record_failure 'mkinitrd.conf does not match the running kernel'; fi
                if [ "$MKINITRD_KERNEL_VERSION" != "$TARGET_KERNEL" ]; then MKINITRD_TRANSITION_REQUIRED=true; record_pass 'mkinitrd.conf requires an explicit reviewed transition to the target kernel'; else record_failure 'mkinitrd.conf already names the uninstalled target kernel'; fi
                record_pass 'the active initrd is present and managed by a readable mkinitrd.conf'
            else
                record_failure 'mkinitrd.conf is unsafe, unreadable, or lacks one KERNEL_VERSION assignment'
            fi
        else
            record_failure 'the managed initrd layout contains unsafe file types or an empty initrd'
        fi
    else
        record_failure 'mkinitrd.conf and initrd presence form an inconsistent boot layout'
    fi

    if [ "$initial_state_captured" = true ]; then
        after_digest=$(capture_package_database_digest 2>/dev/null || true)
        if [ -n "$after_digest" ] && capture_boot_state "$OUTPUT_DIR/boot.after.txt"; then
            final_state_captured=true
            record_pass 'the package database and boot state were captured after inspection'
        else
            record_failure 'the final package database or boot state could not be captured'
        fi
    fi
    if [ "$initial_state_captured" = true ] && [ "$final_state_captured" = true ]; then
        if [ "$before_digest" = "$after_digest" ]; then record_pass 'the installed package database remained unchanged during the preflight'; else record_failure 'the installed package database changed during the preflight'; fi
        if cmp -s "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt"; then record_pass 'the boot state remained unchanged during the preflight'; else diff -u "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" > "$OUTPUT_DIR/boot.diff" || true; record_failure 'the boot state changed during the preflight'; fi
    else
        record_failure 'state immutability could not be evaluated because a complete capture pair is unavailable'
    fi

    APPLY_READY=false
    APPLY_AUTHORIZED=false
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current kernel boot result: layout=%s, boot-mode=%s, running=%s, target=%s, mkinitrd-transition=%s, apply-ready=false, apply-authorized=false\n' \
        "$PACKAGE_LAYOUT" "$BOOT_MODE" "$RUNNING_KERNEL" "$TARGET_KERNEL" "$MKINITRD_TRANSITION_REQUIRED"
    archive=$(create_evidence_archive) || { error 'failed to create evidence archive'; return 1; }
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"
    print_evidence_commands "$archive"
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
