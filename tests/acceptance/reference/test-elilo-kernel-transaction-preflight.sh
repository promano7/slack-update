#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/elilo-kernel-transaction-preflight
TARGET=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_VALUE=
SLACKWARE_VERSION=
RUNNING_KERNEL=
CURRENT_KERNEL_VERSION=
TARGET_KERNEL_VERSION=
TARGET_KERNEL_BUILD=
TARGET_KERNEL_REPOSITORY=
CANDIDATE_SET_SHA256=
ELILO_DIRECTORY=/boot/efi/EFI/Slackware
ELILO_CONFIG=$ELILO_DIRECTORY/elilo.conf
ELILO_IMAGE=
ELILO_INITRD=
TARGET_EFI_KERNEL=
TARGET_EFI_INITRD=
PKGLIST=/var/lib/slackpkg/pkglist
GENERATOR=/usr/share/mkinitrd/mkinitrd_command_generator.sh
METADATA_STATUS=-1
EFI_REQUIRED_BYTES=0
EFI_AVAILABLE_BYTES=0
BOOT_REQUIRED_BYTES=0
BOOT_AVAILABLE_BYTES=0

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 [options]

Build a non-destructive transaction plan for the deferred Slackware 15.0 ELILO
kernel update. The preflight refreshes Slackpkg metadata, resolves one common
repository version for kernel-generic, kernel-huge, and kernel-modules, validates
the active generic ELILO mapping, and writes a versioned atomic configuration
plan. It never changes packages, the Slackpkg blacklist, initrd images, ELILO
files, or firmware variables.

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

is_safe_kernel_version() {
    local version=$1
    [ -n "$version" ] || return 1
    case "$version" in
        *[!A-Za-z0-9._+-]*) return 1 ;;
    esac
    case "$version" in
        .*|*..*) return 1 ;;
    esac
}

version_is_newer() {
    local current=$1
    local candidate=$2
    local first

    [ "$current" != "$candidate" ] || return 1
    first=$(printf '%s\n%s\n' "$current" "$candidate" | sort -V | head -n 1)
    [ "$first" = "$current" ]
}

capture_package_database() {
    local database=$1
    local output=$2

    [ -d "$database" ] || return 1
    find -H "$database" -maxdepth 1 -type f -printf '%f\0' 2>/dev/null \
        | sort -z \
        | xargs -0 -r -n 1 printf '%s\n' \
        > "$output"
    [ -s "$output" ]
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

capture_boot_state() {
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
        /etc/slackpkg/blacklist; do
        capture_path_record "$path" >> "$output"
    done
}

read_elilo_assignment_from() {
    local config=$1
    local name=$2
    local line value count=0 result=

    [ -f "$config" ] && [ ! -L "$config" ] && [ -r "$config" ] || return 1
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
    done < "$config"
    [ "$count" -eq 1 ] && [ -n "$result" ] || return 1
    case "$result" in
        /*|*..*|*/*) return 1 ;;
    esac
    printf '%s\n' "$result"
}

write_planned_elilo_config() {
    local source=$1
    local output=$2
    local image=$3
    local initrd=$4

    python3 - "$source" "$output" "$image" "$initrd" <<'PYTHON_EOF'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
image = sys.argv[3]
initrd = sys.argv[4]
text = source.read_text(encoding="utf-8")
lines = text.splitlines(keepends=True)
counts = {"image": 0, "initrd": 0}
result = []
for line in lines:
    match = re.match(r"^(\s*)(image|initrd)(\s*=\s*)([^#\r\n]*?)(\s*(?:#.*)?)(\r?\n)?$", line)
    if not match:
        result.append(line)
        continue
    key = match.group(2)
    counts[key] += 1
    value = image if key == "image" else initrd
    ending = match.group(6) or ""
    result.append(f"{match.group(1)}{key}{match.group(3)}{value}{match.group(5)}{ending}")
if counts != {"image": 1, "initrd": 1}:
    raise SystemExit(f"unsafe ELILO assignment counts: {counts}")
output.write_text("".join(result), encoding="utf-8")
PYTHON_EOF
}

capture_installed_kernel_records() {
    local database=$1
    local output=$2

    python3 - "$database" "$output" <<'PYTHON_EOF'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
required = ("kernel-generic", "kernel-huge", "kernel-modules")
records = []
for name in required:
    matches = []
    for item in root.iterdir():
        if not item.is_file() or item.is_symlink():
            continue
        stem = item.name
        fields = stem.rsplit("-", 3)
        if len(fields) == 4 and fields[0] == name:
            matches.append((name, fields[1], fields[2], fields[3], item.name))
    if len(matches) != 1:
        raise SystemExit(f"expected one installed record for {name}, found {len(matches)}")
    records.extend(matches)
versions = {record[1] for record in records}
if len(versions) != 1:
    raise SystemExit(f"installed boot-kernel versions differ: {sorted(versions)}")
out.write_text("".join("\t".join(record) + "\n" for record in records), encoding="utf-8")
PYTHON_EOF
}

resolve_repository_kernel_candidate() {
    local pkglist=$1
    local installed_records=$2
    local all_output=$3
    local selected_output=$4
    local summary_output=$5

    python3 - "$pkglist" "$installed_records" "$all_output" "$selected_output" "$summary_output" <<'PYTHON_EOF'
import collections
import pathlib
import sys

pkglist_path, installed_path, all_path, selected_path, summary_path = map(pathlib.Path, sys.argv[1:])
required = ("kernel-generic", "kernel-huge", "kernel-modules")
installed = {}
for line in installed_path.read_text(encoding="utf-8").splitlines():
    name, version, arch, build, filename = line.split("\t")
    installed[name] = (version, arch, build, filename)

records = []
for number, raw in enumerate(pkglist_path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
    fields = raw.split()
    if len(fields) < 5 or fields[1] not in required:
        continue
    repository, name, version, arch, build = fields[:5]
    filename = fields[5] if len(fields) >= 6 else f"{name}-{version}-{arch}-{build}.txz"
    path = fields[6] if len(fields) >= 7 else ""
    records.append((repository, name, version, arch, build, filename, path, str(number)))
if not records:
    raise SystemExit("no boot-kernel records found in Slackpkg pkglist")
all_path.write_text("".join("\t".join(item) + "\n" for item in records), encoding="utf-8")

by_key = collections.defaultdict(dict)
for record in records:
    repository, name, version, arch, build, filename, path, number = record
    if arch != "x86_64":
        continue
    by_key[(repository, version, build)][name] = record

candidates = []
for key, grouped in by_key.items():
    if set(grouped) != set(required):
        continue
    version = key[1]
    if all(installed[name][0] != version for name in required):
        candidates.append((key, grouped))

patches = [item for item in candidates if item[0][0] == "patches"]
selected_pool = patches if patches else candidates
if len(selected_pool) != 1:
    descriptions = ["/".join(item[0]) for item in selected_pool]
    raise SystemExit(f"expected one common repository candidate, found {descriptions}")
(key, grouped) = selected_pool[0]
repository, version, build = key
selected = [grouped[name] for name in required]
selected_path.write_text("".join("\t".join(item) + "\n" for item in selected), encoding="utf-8")
summary_path.write_text(
    f"repository={repository}\nversion={version}\nbuild={build}\ncount={len(selected)}\n",
    encoding="utf-8",
)
PYTHON_EOF
}

read_summary_value() {
    local key=$1
    local file=$2
    sed -n "s/^${key}=//p" "$file" | head -n 1
}

run_metadata_refresh() {
    local output=$1
    local status_output=$2
    local status=0

    LC_ALL=C LANG=C TERM=dumb \
        slackpkg -dialog=off -batch=on -default_answer=y update \
        > "$output" 2>&1 || status=$?
    printf '%d\n' "$status" > "$status_output"
    METADATA_STATUS=$status
    return "$status"
}

blacklist_has_exact_deferrals() {
    local package
    [ -r /etc/slackpkg/blacklist ] || return 1
    for package in kernel-generic kernel-huge kernel-modules; do
        grep -Eq "^[[:space:]]*${package}([[:space:]]*(#.*)?)?$" /etc/slackpkg/blacklist \
            || return 1
    done
}

calculate_space_plan() {
    local current_kernel=$1
    local current_initrd=$2
    local efi_mount=$3
    local boot_mount=$4
    local safety=$((16 * 1024 * 1024))
    local kernel_size initrd_size

    kernel_size=$(stat -c '%s' -- "$current_kernel") || return 1
    initrd_size=$(stat -c '%s' -- "$current_initrd") || return 1
    EFI_REQUIRED_BYTES=$((kernel_size + initrd_size + safety))
    BOOT_REQUIRED_BYTES=$((initrd_size + safety))
    EFI_AVAILABLE_BYTES=$(df -PB1 --output=avail "$efi_mount" | tail -n 1 | tr -d '[:space:]')
    BOOT_AVAILABLE_BYTES=$(df -PB1 --output=avail "$boot_mount" | tail -n 1 | tr -d '[:space:]')
    [ "$EFI_AVAILABLE_BYTES" -ge "$EFI_REQUIRED_BYTES" ] \
        && [ "$BOOT_AVAILABLE_BYTES" -ge "$BOOT_REQUIRED_BYTES" ]
}

write_transaction_plan() {
    local output=$1

    cat > "$output" <<EOF_PLAN
transaction=elilo-versioned-kernel-switch
current_kernel=$CURRENT_KERNEL_VERSION
target_kernel=$TARGET_KERNEL_VERSION
candidate_set_sha256=$CANDIDATE_SET_SHA256
packages=kernel-generic,kernel-huge,kernel-modules
blacklist_policy=remove-exact-three-during-transaction-and-restore-before-exit
new_boot_kernel=/boot/vmlinuz-generic-$TARGET_KERNEL_VERSION
new_boot_initrd=/boot/initrd-generic-$TARGET_KERNEL_VERSION.gz
new_efi_kernel=$ELILO_DIRECTORY/$TARGET_EFI_KERNEL
new_efi_initrd=$ELILO_DIRECTORY/$TARGET_EFI_INITRD
planned_elilo_config=$OUTPUT_DIR/elilo.conf.planned
activation_boundary=atomic-elilo.conf-replacement-after-new-files-verify
rollback_boundary=retain-current-vmlinuz-initrd-and-original-elilo.conf
mkinitrd_policy=generate-command-after-kernel-modules-install-validate-strict-grammar-never-eval
eliloconfig_policy=not-used-existing-efi-entry-and-loader-remain-unchanged
apply_authorized=false
EOF_PLAN
}

write_summary() {
    local output=$1

    cat > "$output" <<EOF_SUMMARY
scenario=elilo-kernel-transaction-preflight
target=$TARGET
hostname=$HOSTNAME_VALUE
slackware_version=$SLACKWARE_VERSION
running_kernel=$RUNNING_KERNEL
current_kernel=$CURRENT_KERNEL_VERSION
target_kernel=$TARGET_KERNEL_VERSION
target_build=$TARGET_KERNEL_BUILD
target_repository=$TARGET_KERNEL_REPOSITORY
candidate_set_sha256=$CANDIDATE_SET_SHA256
elilo_image=$ELILO_IMAGE
elilo_initrd=$ELILO_INITRD
planned_efi_kernel=$TARGET_EFI_KERNEL
planned_efi_initrd=$TARGET_EFI_INITRD
efi_required_bytes=$EFI_REQUIRED_BYTES
efi_available_bytes=$EFI_AVAILABLE_BYTES
boot_required_bytes=$BOOT_REQUIRED_BYTES
boot_available_bytes=$BOOT_AVAILABLE_BYTES
passes=$PASS_COUNT
failures=$FAILURE_COUNT
apply_authorized=false
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-elilo-kernel-transaction-preflight-${timestamp}.tar.gz"
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
    local timestamp installed_versions

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

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.before.txt" \
        && record_pass 'the installed package database was captured before planning' \
        || record_failure 'the installed package database could not be captured'
    capture_boot_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the ELILO boot state was captured before planning' \
        || record_failure 'the ELILO boot state could not be captured'

    [ -d /sys/firmware/efi ] \
        && record_pass 'the system is running in UEFI mode' \
        || record_failure 'the system is not running in UEFI mode'
    [ -f "$ELILO_CONFIG" ] && [ ! -L "$ELILO_CONFIG" ] && [ -r "$ELILO_CONFIG" ] \
        && record_pass 'elilo.conf is a readable regular file' \
        || record_failure 'elilo.conf is missing, unreadable, or unsafe'

    if ELILO_IMAGE=$(read_elilo_assignment_from "$ELILO_CONFIG" image); then
        record_pass "ELILO has one safe image directive: $ELILO_IMAGE"
    else
        record_failure 'ELILO image directive is missing, ambiguous, or unsafe'
    fi
    if ELILO_INITRD=$(read_elilo_assignment_from "$ELILO_CONFIG" initrd); then
        record_pass "ELILO has one safe initrd directive: $ELILO_INITRD"
    else
        record_failure 'ELILO initrd directive is missing, ambiguous, or unsafe'
    fi

    if capture_installed_kernel_records /var/log/packages "$OUTPUT_DIR/installed-kernel-records.tsv"; then
        CURRENT_KERNEL_VERSION=$(awk -F '\t' 'NR == 1 {print $2}' "$OUTPUT_DIR/installed-kernel-records.tsv")
        installed_versions=$(awk -F '\t' '{print $2}' "$OUTPUT_DIR/installed-kernel-records.tsv" | sort -u | wc -l)
        [ "$installed_versions" -eq 1 ] \
            && record_pass "the three installed boot-kernel packages share version $CURRENT_KERNEL_VERSION" \
            || record_failure 'the installed boot-kernel package versions differ'
    else
        : > "$OUTPUT_DIR/installed-kernel-records.tsv"
        record_failure 'the installed boot-kernel records could not be resolved exactly'
    fi

    [ "$RUNNING_KERNEL" = "$CURRENT_KERNEL_VERSION" ] \
        && record_pass 'the running kernel matches the installed boot-kernel package version' \
        || record_failure "the running kernel $RUNNING_KERNEL differs from installed version $CURRENT_KERNEL_VERSION"
    [ -f "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" ] \
        && cmp -s -- "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" "$ELILO_DIRECTORY/$ELILO_IMAGE" \
        && record_pass 'the active ELILO kernel matches the versioned generic kernel source' \
        || record_failure 'the active ELILO kernel does not match the expected versioned generic source'
    [ -f /boot/initrd.gz ] && cmp -s -- /boot/initrd.gz "$ELILO_DIRECTORY/$ELILO_INITRD" \
        && record_pass 'the active ELILO initrd matches /boot/initrd.gz' \
        || record_failure 'the active ELILO initrd does not match /boot/initrd.gz'

    blacklist_has_exact_deferrals \
        && record_pass 'the three boot-kernel packages remain deferred in the Slackpkg blacklist' \
        || record_failure 'the expected boot-kernel blacklist deferral is incomplete'

    printf 'Refreshing Slackware package metadata before transaction planning...\n'
    run_metadata_refresh "$OUTPUT_DIR/slackpkg-update.log" "$OUTPUT_DIR/slackpkg-update.exit"
    case "$METADATA_STATUS" in
        0) record_pass 'Slackware package metadata was refreshed before transaction planning' ;;
        *) record_failure "Slackware package metadata refresh failed with status $METADATA_STATUS" ;;
    esac

    if [ -f "$PKGLIST" ] && [ ! -L "$PKGLIST" ] && [ -r "$PKGLIST" ]; then
        record_pass 'the Slackpkg package list is a readable regular file'
    else
        record_failure 'the Slackpkg package list is missing, unreadable, or unsafe'
    fi

    if resolve_repository_kernel_candidate "$PKGLIST" "$OUTPUT_DIR/installed-kernel-records.tsv" \
        "$OUTPUT_DIR/repository-kernel-records.tsv" "$OUTPUT_DIR/selected-kernel-records.tsv" \
        "$OUTPUT_DIR/candidate-summary.txt"; then
        TARGET_KERNEL_REPOSITORY=$(read_summary_value repository "$OUTPUT_DIR/candidate-summary.txt")
        TARGET_KERNEL_VERSION=$(read_summary_value version "$OUTPUT_DIR/candidate-summary.txt")
        TARGET_KERNEL_BUILD=$(read_summary_value build "$OUTPUT_DIR/candidate-summary.txt")
        CANDIDATE_SET_SHA256=$(sha256sum -- "$OUTPUT_DIR/selected-kernel-records.tsv" | awk '{print $1}')
        record_pass "one common repository candidate was resolved: $TARGET_KERNEL_VERSION-$TARGET_KERNEL_BUILD from $TARGET_KERNEL_REPOSITORY"
    else
        : > "$OUTPUT_DIR/repository-kernel-records.tsv"
        : > "$OUTPUT_DIR/selected-kernel-records.tsv"
        : > "$OUTPUT_DIR/candidate-summary.txt"
        record_failure 'one common repository candidate could not be resolved safely'
    fi

    if is_safe_kernel_version "$TARGET_KERNEL_VERSION"; then
        record_pass 'the target kernel version uses a safe filename grammar'
    else
        record_failure 'the target kernel version is empty or unsafe'
    fi
    if version_is_newer "$CURRENT_KERNEL_VERSION" "$TARGET_KERNEL_VERSION"; then
        record_pass 'the repository kernel version is newer than the installed version'
    else
        record_failure 'the repository kernel version is not newer than the installed version'
    fi
    [ ! -e "/lib/modules/$TARGET_KERNEL_VERSION" ] \
        && record_pass 'the target kernel modules directory is not already installed' \
        || record_failure 'the target kernel modules directory already exists'

    TARGET_EFI_KERNEL="vmlinuz-generic-$TARGET_KERNEL_VERSION"
    TARGET_EFI_INITRD="initrd-generic-$TARGET_KERNEL_VERSION.gz"
    case "$TARGET_EFI_KERNEL$TARGET_EFI_INITRD" in
        *[!A-Za-z0-9._+-]*) record_failure 'the planned EFI basenames are unsafe' ;;
        *) record_pass 'the planned EFI kernel and initrd basenames are safe' ;;
    esac
    if [ ! -e "$ELILO_DIRECTORY/$TARGET_EFI_KERNEL" ] \
        && [ ! -e "$ELILO_DIRECTORY/$TARGET_EFI_INITRD" ]; then
        record_pass 'the planned versioned EFI files do not collide with existing paths'
    else
        record_failure 'one or more planned versioned EFI paths already exist'
    fi

    if write_planned_elilo_config "$ELILO_CONFIG" "$OUTPUT_DIR/elilo.conf.planned" \
        "$TARGET_EFI_KERNEL" "$TARGET_EFI_INITRD"; then
        record_pass 'a planned ELILO configuration was generated without modifying the active file'
    else
        : > "$OUTPUT_DIR/elilo.conf.planned"
        record_failure 'the planned ELILO configuration could not be generated safely'
    fi
    [ "$(read_elilo_assignment_from "$OUTPUT_DIR/elilo.conf.planned" image 2>/dev/null || true)" = "$TARGET_EFI_KERNEL" ] \
        && [ "$(read_elilo_assignment_from "$OUTPUT_DIR/elilo.conf.planned" initrd 2>/dev/null || true)" = "$TARGET_EFI_INITRD" ] \
        && record_pass 'the planned ELILO configuration selects the versioned target files' \
        || record_failure 'the planned ELILO configuration does not select the expected target files'

    if calculate_space_plan "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" /boot/initrd.gz /boot/efi /boot; then
        record_pass 'the EFI and /boot filesystems have conservative free space for staged versioned files'
    else
        record_failure 'the EFI or /boot filesystem lacks conservative staging space'
    fi

    [ -f "$GENERATOR" ] && [ ! -L "$GENERATOR" ] && [ -r "$GENERATOR" ] \
        && record_pass 'the official mkinitrd command generator remains available' \
        || record_failure 'the official mkinitrd command generator is missing or unsafe'

    write_transaction_plan "$OUTPUT_DIR/transaction-plan.txt"

    capture_package_database /var/log/packages "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database was captured after planning' \
        || record_failure 'the installed package database could not be recaptured'
    capture_boot_state "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the ELILO boot state was captured after planning' \
        || record_failure 'the ELILO boot state could not be recaptured'

    if cmp -s -- "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt"; then
        : > "$OUTPUT_DIR/packages.diff"
        record_pass 'the transaction preflight did not modify the installed package database'
    else
        diff -u -- "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
            > "$OUTPUT_DIR/packages.diff" 2>&1 || true
        record_failure 'the transaction preflight modified the installed package database'
    fi
    if cmp -s -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt"; then
        : > "$OUTPUT_DIR/boot.diff"
        record_pass 'the transaction preflight did not modify ELILO, initrd, or blacklist state'
    else
        diff -u -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
            > "$OUTPUT_DIR/boot.diff" 2>&1 || true
        record_failure 'the transaction preflight modified ELILO, initrd, or blacklist state'
    fi

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'ELILO kernel transaction summary: current=%s, target=%s, repository=%s, candidate-sha256=%s\n' \
        "${CURRENT_KERNEL_VERSION:-unknown}" "${TARGET_KERNEL_VERSION:-unknown}" \
        "${TARGET_KERNEL_REPOSITORY:-unknown}" "${CANDIDATE_SET_SHA256:-unknown}"
    printf 'Preflight only: no package, blacklist, initrd, ELILO, or firmware change was authorized.\n'
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
