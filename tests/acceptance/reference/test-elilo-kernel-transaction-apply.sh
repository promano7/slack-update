#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# Source the reviewed planning helpers without running its main function.
# shellcheck source=test-elilo-kernel-transaction-preflight.sh
source "$TEST_DIR/test-elilo-kernel-transaction-preflight.sh"

DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/elilo-kernel-transaction-apply
TARGET=
OUTPUT_DIR=
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATE_SHA256=
CONFIRM_TARGET_KERNEL=
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
PACKAGE_DATABASE=/var/log/packages
BLACKLIST=/etc/slackpkg/blacklist
BLACKLIST_BACKUP=
BLACKLIST_MODIFIED=0
ELILO_CONFIG_BACKUP=
ELILO_ACTIVATED=0
ELILO_COMMITTED=0
STAGED_BOOT_INITRD=
STAGED_EFI_KERNEL=
STAGED_EFI_INITRD=
STAGED_ELILO_CONFIG=
TRANSACTION_STATUS=not-started
SLACKPKG_DOWNLOAD_STATUS=-1
INSTALLPKG_STATUS=-1
MKINITRD_STATUS=-1

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 --execute-apply \\
                     --confirm-hostname HOSTNAME \\
                     --confirm-candidate-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Apply the reviewed Slackware 15.0 ELILO boot-kernel transaction. The command
refreshes Slackpkg metadata, requires the exact reviewed candidate digest,
temporarily removes only the three exact kernel deferrals, downloads exactly
kernel-generic, kernel-huge, and kernel-modules, restores the blacklist, installs
the new packages alongside the working kernel with installpkg, and then builds
an initrd under a versioned name, stages versioned files in the EFI partition,
and atomically activates them through elilo.conf.

The current ELILO kernel, initrd, and configuration remain present as rollback
artifacts. Package installation itself cannot be rolled back automatically.
Run only on a snapshotted disposable VM with a tested recovery path.

Required options:
      --target slackware-15.0
      --execute-apply
      --confirm-hostname HOSTNAME
      --confirm-candidate-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
EOF_USAGE
}

parse_apply_arguments() {
    local execute=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                [ "$#" -ge 2 ] || return 1
                TARGET=$2
                shift 2
                ;;
            --execute-apply)
                execute=$((execute + 1))
                shift
                ;;
            --confirm-hostname)
                [ "$#" -ge 2 ] || return 1
                CONFIRM_HOSTNAME=$2
                shift 2
                ;;
            --confirm-candidate-sha256)
                [ "$#" -ge 2 ] || return 1
                CONFIRM_CANDIDATE_SHA256=$2
                shift 2
                ;;
            --confirm-target-kernel)
                [ "$#" -ge 2 ] || return 1
                CONFIRM_TARGET_KERNEL=$2
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
    [ "$execute" -eq 1 ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] || return 1
    [ -n "$CONFIRM_TARGET_KERNEL" ] && is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || return 1
    case "$CONFIRM_CANDIDATE_SHA256" in
        *[!0-9A-Fa-f]*|'') return 1 ;;
    esac
    [ "${#CONFIRM_CANDIDATE_SHA256}" -eq 64 ] || return 1
    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac
    fi
}

require_regular_file() {
    [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]
}

write_blacklist_without_deferrals() {
    local source=$1 output=$2

    python3 - "$source" "$output" <<'PYTHON_EOF'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
required = {"kernel-generic", "kernel-huge", "kernel-modules"}
counts = {name: 0 for name in required}
result = []
for line in source.read_text(encoding="utf-8").splitlines(keepends=True):
    content = line.split("#", 1)[0].strip()
    if content in required:
        counts[content] += 1
        continue
    result.append(line)
if counts != {name: 1 for name in required}:
    raise SystemExit(f"expected one exact active deferral per package, found {counts}")
output.write_text("".join(result), encoding="utf-8")
PYTHON_EOF
}

atomic_replace_preserving_metadata() {
    local source=$1 destination=$2 temporary

    temporary="$(dirname -- "$destination")/.slack-update-${destination##*/}.$$"
    [ ! -e "$temporary" ] && [ ! -L "$temporary" ] || return 1
    install -o "$(stat -c '%u' -- "$destination")" \
        -g "$(stat -c '%g' -- "$destination")" \
        -m "$(stat -c '%a' -- "$destination")" \
        -- "$source" "$temporary" || return 1
    mv -fT -- "$temporary" "$destination"
}

restore_blacklist() {
    [ "$BLACKLIST_MODIFIED" -eq 1 ] || return 0
    [ -n "$BLACKLIST_BACKUP" ] && require_regular_file "$BLACKLIST_BACKUP" || return 1
    atomic_replace_preserving_metadata "$BLACKLIST_BACKUP" "$BLACKLIST" || return 1
    BLACKLIST_MODIFIED=0
}

restore_elilo_config() {
    [ "$ELILO_ACTIVATED" -eq 1 ] && [ "$ELILO_COMMITTED" -eq 0 ] || return 0
    [ -n "$ELILO_CONFIG_BACKUP" ] && require_regular_file "$ELILO_CONFIG_BACKUP" || return 1
    atomic_replace_preserving_metadata "$ELILO_CONFIG_BACKUP" "$ELILO_CONFIG" || return 1
    ELILO_ACTIVATED=0
}

cleanup_transaction() {
    local status=$?

    restore_blacklist || true
    restore_elilo_config || true
    for path in "$STAGED_BOOT_INITRD" "$STAGED_EFI_KERNEL" "$STAGED_EFI_INITRD" "$STAGED_ELILO_CONFIG"; do
        [ -n "$path" ] || continue
        [ -L "$path" ] && continue
        rm -f -- "$path" 2>/dev/null || true
    done
    return "$status"
}

handle_transaction_signal() {
    local signal=$1 status
    case "$signal" in
        HUP) status=129 ;;
        INT) status=130 ;;
        TERM) status=143 ;;
        *) status=1 ;;
    esac
    trap - EXIT HUP INT TERM
    cleanup_transaction || true
    exit "$status"
}

run_kernel_package_download() {
    local output=$1 status=0

    LC_ALL=C LANG=C TERM=dumb \
        slackpkg -dialog=off -batch=on -default_answer=y \
        download '^kernel-(generic|huge|modules)$' \
        > "$output" 2>&1 || status=$?
    SLACKPKG_DOWNLOAD_STATUS=$status
    printf '%d\n' "$status" > "$OUTPUT_DIR/slackpkg-download.exit"
    return "$status"
}

resolve_downloaded_kernel_packages() {
    local selected_records=$1 cache_root=$2 output=$3

    python3 - "$selected_records" "$cache_root" "$output" <<'PYTHON_EOF'
import pathlib
import sys

selected = pathlib.Path(sys.argv[1])
cache = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
required = ("kernel-generic", "kernel-huge", "kernel-modules")
records = {}
for line in selected.read_text(encoding="utf-8").splitlines():
    repository, name, version, arch, build, filename, package_path, number = line.split("\t")
    if name not in required or name in records:
        raise SystemExit("unexpected or duplicate selected package record")
    package_path = package_path.removeprefix("./")
    base = filename
    if base.endswith((".txz", ".tgz", ".tbz", ".tlz")):
        base = base.rsplit(".", 1)[0]
    directory = cache / package_path
    matches = [directory / f"{base}{suffix}" for suffix in (".txz", ".tgz", ".tbz", ".tlz")]
    matches = [path for path in matches if path.is_file() and not path.is_symlink()]
    if len(matches) != 1:
        raise SystemExit(f"expected one cached package for {name}, found {len(matches)}")
    records[name] = matches[0]
if set(records) != set(required):
    raise SystemExit("the cached package set is incomplete")
output.write_text("".join(str(records[name]) + "\n" for name in required), encoding="utf-8")
PYTHON_EOF
}

install_downloaded_kernel_packages() {
    local package_list=$1 output=$2 status=0
    local -a packages=()

    mapfile -t packages < "$package_list"
    [ "${#packages[@]}" -eq 3 ] || return 1
    installpkg "${packages[@]}" > "$output" 2>&1 || status=$?
    INSTALLPKG_STATUS=$status
    printf '%d\n' "$status" > "$OUTPUT_DIR/installpkg.exit"
    return "$status"
}

validate_installed_target_kernel() {
    local database=$1 current=$2 target=$3 output=$4

    python3 - "$database" "$current" "$target" "$output" <<'PYTHON_EOF'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
current = sys.argv[2]
target = sys.argv[3]
output = pathlib.Path(sys.argv[4])
required = ("kernel-generic", "kernel-huge", "kernel-modules")
records = []
for name in required:
    matches = []
    for item in root.iterdir():
        if not item.is_file() or item.is_symlink():
            continue
        fields = item.name.rsplit("-", 3)
        if len(fields) == 4 and fields[0] == name:
            matches.append((name, fields[1], fields[2], fields[3], item.name))
    versions = sorted(record[1] for record in matches)
    if versions != sorted((current, target)):
        raise SystemExit(f"unexpected installed versions for {name}: {versions}")
    records.extend(sorted(matches, key=lambda record: record[1]))
output.write_text("".join("\t".join(record) + "\n" for record in records), encoding="utf-8")
PYTHON_EOF
}

capture_generator_command() {
    local version=$1 output=$2 status_output=$3 status=0

    "$GENERATOR" -k "$version" > "$output" 2>&1 || status=$?
    printf '%d\n' "$status" > "$status_output"
    return "$status"
}

build_mkinitrd_argv() {
    local generator_output=$1 expected_version=$2 destination=$3 nul_output=$4

    python3 - "$generator_output" "$expected_version" "$destination" "$nul_output" <<'PYTHON_EOF'
import pathlib
import shlex
import sys

source, expected, destination, output = sys.argv[1:]
lines = []
for raw in pathlib.Path(source).read_text(encoding="utf-8", errors="replace").splitlines():
    stripped = raw.strip()
    if stripped.startswith("mkinitrd "):
        lines.append(stripped)
if len(lines) != 1:
    raise SystemExit(f"expected one mkinitrd command, found {len(lines)}")
args = shlex.split(lines[0], posix=True)
if not args or args[0] != "mkinitrd":
    raise SystemExit("unexpected command")
allowed_switches = {"-c", "-u"}
allowed_values = {"-k", "-f", "-r", "-m", "-o"}
parsed = ["mkinitrd"]
seen = {}
i = 1
while i < len(args):
    token = args[i]
    if token in allowed_switches:
        if token in seen:
            raise SystemExit(f"duplicate option: {token}")
        seen[token] = True
        parsed.append(token)
        i += 1
        continue
    if token in allowed_values:
        if token in seen or i + 1 >= len(args):
            raise SystemExit(f"invalid option: {token}")
        value = args[i + 1]
        seen[token] = value
        parsed.extend((token, value))
        i += 2
        continue
    raise SystemExit(f"unsupported token: {token}")
if seen.get("-k") != expected:
    raise SystemExit("generator targets an unexpected kernel")
for required in ("-c", "-k", "-f", "-r", "-m", "-u", "-o"):
    if required not in seen:
        raise SystemExit(f"missing required option: {required}")
if not seen["-r"].startswith("/") or any(ch.isspace() for ch in seen["-r"]):
    raise SystemExit("unsafe root argument")
for key in ("-f", "-m"):
    value = seen[key]
    if not value or any(ch.isspace() for ch in value) or any(ch in value for ch in ";|&`$<>"):
        raise SystemExit(f"unsafe value for {key}")
index = parsed.index("-o") + 1
parsed[index] = destination
pathlib.Path(output).write_bytes(b"".join(item.encode() + b"\0" for item in parsed))
PYTHON_EOF
}

run_versioned_mkinitrd() {
    local generator_output=$1 destination=$2 argv_file=$3
    local -a argv=()
    local status=0

    build_mkinitrd_argv "$generator_output" "$TARGET_KERNEL_VERSION" "$destination" "$argv_file" || return 1
    while IFS= read -r -d '' item; do argv+=("$item"); done < "$argv_file"
    [ "${#argv[@]}" -gt 1 ] && [ "${argv[0]}" = mkinitrd ] || return 1
    "${argv[@]}" > "$OUTPUT_DIR/mkinitrd.log" 2>&1 || status=$?
    MKINITRD_STATUS=$status
    printf '%d\n' "$status" > "$OUTPUT_DIR/mkinitrd.exit"
    [ "$status" -eq 0 ] || return "$status"
    [ -s "$destination" ] && [ -f "$destination" ] && [ ! -L "$destination" ]
}

stage_verified_copy() {
    local source=$1 staged=$2 final=$3 mode=$4
    local source_hash staged_hash

    [ -f "$source" ] && [ ! -L "$source" ] && [ ! -e "$final" ] && [ ! -L "$final" ] || return 1
    [ ! -e "$staged" ] && [ ! -L "$staged" ] || return 1
    install -o 0 -g 0 -m "$mode" -- "$source" "$staged" || return 1
    source_hash=$(sha256sum -- "$source" | awk '{print $1}') || return 1
    staged_hash=$(sha256sum -- "$staged" | awk '{print $1}') || return 1
    [ "$source_hash" = "$staged_hash" ] || return 1
    mv -T -- "$staged" "$final"
}

activate_elilo_config() {
    local planned=$1

    STAGED_ELILO_CONFIG="$ELILO_DIRECTORY/.slack-update-elilo.conf.$$"
    [ ! -e "$STAGED_ELILO_CONFIG" ] && [ ! -L "$STAGED_ELILO_CONFIG" ] || return 1
    install -o "$(stat -c '%u' -- "$ELILO_CONFIG")" \
        -g "$(stat -c '%g' -- "$ELILO_CONFIG")" \
        -m "$(stat -c '%a' -- "$ELILO_CONFIG")" \
        -- "$planned" "$STAGED_ELILO_CONFIG" || return 1
    cmp -s -- "$planned" "$STAGED_ELILO_CONFIG" || return 1
    sync
    mv -fT -- "$STAGED_ELILO_CONFIG" "$ELILO_CONFIG" || return 1
    STAGED_ELILO_CONFIG=
    ELILO_ACTIVATED=1
    cmp -s -- "$planned" "$ELILO_CONFIG" || return 1
    validate_transaction_elilo_config "$ELILO_CONFIG" "$TARGET_EFI_KERNEL" "$TARGET_EFI_INITRD" || return 1
    ELILO_COMMITTED=1
}

write_transaction_elilo_config() {
    local source=$1 output=$2 new_image=$3 new_initrd=$4

    python3 - "$source" "$output" "$new_image" "$new_initrd" <<'PYTHON_EOF'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
new_image = sys.argv[3]
new_initrd = sys.argv[4]
lines = source.read_text(encoding="utf-8").splitlines(keepends=True)
image_indexes = [i for i, line in enumerate(lines) if re.match(r"^\s*image\s*=", line)]
if len(image_indexes) != 1:
    raise SystemExit(f"expected one image stanza, found {len(image_indexes)}")
start = image_indexes[0]
global_lines = lines[:start]
stanza = lines[start:]
default_indexes = [i for i, line in enumerate(global_lines) if re.match(r"^\s*default\s*=", line)]
if len(default_indexes) > 1:
    raise SystemExit(f"expected at most one default directive, found {len(default_indexes)}")
if default_indexes:
    index = default_indexes[0]
    ending = "\n" if global_lines[index].endswith("\n") else ""
    global_lines[index] = f"default=vmlinuz{ending}"
else:
    if global_lines and not global_lines[-1].endswith("\n"):
        global_lines[-1] += "\n"
    global_lines.append("default=vmlinuz\n")
counts = {key: 0 for key in ("image", "initrd", "label")}
for line in stanza:
    for key in counts:
        if re.match(rf"^\s*{key}\s*=", line):
            counts[key] += 1
if counts != {"image": 1, "initrd": 1, "label": 1}:
    raise SystemExit(f"unsafe ELILO stanza counts: {counts}")

def rewrite(items, replacements):
    result = []
    for line in items:
        replaced = False
        for key, value in replacements.items():
            match = re.match(rf"^(\s*){key}(\s*=\s*)([^#\r\n]*?)(\s*(?:#.*)?)(\r?\n)?$", line)
            if match:
                ending = match.group(5) or ""
                result.append(f"{match.group(1)}{key}{match.group(2)}{value}{match.group(4)}{ending}")
                replaced = True
                break
        if not replaced:
            result.append(line)
    return result

new_stanza = rewrite(stanza, {"image": new_image, "initrd": new_initrd})
old_stanza = rewrite(stanza, {"label": "oldkernel"})
text = "".join(global_lines + new_stanza)
if not text.endswith("\n"):
    text += "\n"
text += "\n# Slack-Update rollback entry: retained working kernel and initrd\n"
text += "".join(old_stanza)
output.write_text(text, encoding="utf-8")
PYTHON_EOF
}

validate_transaction_elilo_config() {
    local config=$1 new_image=$2 new_initrd=$3

    python3 - "$config" "$new_image" "$new_initrd" <<'PYTHON_EOF'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
new_image = sys.argv[2]
new_initrd = sys.argv[3]
images = []
defaults = []
current = None
for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.split("#", 1)[0].strip()
    match = re.match(r"^default\s*=\s*(\S+)$", line)
    if match:
        defaults.append(match.group(1))
        continue
    match = re.match(r"^image\s*=\s*(\S+)$", line)
    if match:
        current = {"image": match.group(1)}
        images.append(current)
        continue
    if current is None:
        continue
    for key in ("initrd", "label"):
        match = re.match(rf"^{key}\s*=\s*(\S+)$", line)
        if match:
            if key in current:
                raise SystemExit(f"duplicate {key}")
            current[key] = match.group(1)
if defaults != ["vmlinuz"]:
    raise SystemExit(f"unexpected default directives: {defaults}")
if len(images) != 2:
    raise SystemExit(f"expected two image stanzas, found {len(images)}")
new, old = images
if new != {"image": new_image, "initrd": new_initrd, "label": "vmlinuz"}:
    raise SystemExit(f"unexpected new stanza: {new}")
if old != {"image": "vmlinuz", "initrd": "initrd.gz", "label": "oldkernel"}:
    raise SystemExit(f"unexpected rollback stanza: {old}")
PYTHON_EOF
}

write_apply_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=elilo-kernel-transaction-apply
target=$TARGET
hostname=$HOSTNAME_VALUE
slackware_version=$SLACKWARE_VERSION
running_kernel_before=$RUNNING_KERNEL
current_kernel_before=$CURRENT_KERNEL_VERSION
target_kernel=$TARGET_KERNEL_VERSION
target_build=$TARGET_KERNEL_BUILD
target_repository=$TARGET_KERNEL_REPOSITORY
candidate_set_sha256=$CANDIDATE_SET_SHA256
slackpkg_download_exit=$SLACKPKG_DOWNLOAD_STATUS
installpkg_exit=$INSTALLPKG_STATUS
mkinitrd_exit=$MKINITRD_STATUS
new_boot_kernel=/boot/vmlinuz-generic-$TARGET_KERNEL_VERSION
new_boot_initrd=/boot/initrd-generic-$TARGET_KERNEL_VERSION.gz
new_efi_kernel=$ELILO_DIRECTORY/$TARGET_EFI_KERNEL
new_efi_initrd=$ELILO_DIRECTORY/$TARGET_EFI_INITRD
elilo_activated=$ELILO_ACTIVATED
elilo_committed=$ELILO_COMMITTED
blacklist_restored=$((BLACKLIST_MODIFIED == 0))
rollback_label=oldkernel
reboot_required=true
transaction_status=$TRANSACTION_STATUS
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_apply_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-elilo-kernel-transaction-apply-${timestamp}.tar.gz"
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
    local timestamp installed_versions planned_config new_boot_kernel new_boot_initrd

    parse_apply_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this transaction must run as root'; return 2; }
    SLACKWARE_VERSION=$(cat /etc/slackware-version 2>/dev/null || true)
    [ "$SLACKWARE_VERSION" = 'Slackware 15.0' ] || { error "target mismatch: $SLACKWARE_VERSION"; return 2; }
    HOSTNAME_VALUE=$(hostname -f 2>/dev/null || hostname)
    [ "$HOSTNAME_VALUE" = "$CONFIRM_HOSTNAME" ] || { error "hostname confirmation mismatch: $HOSTNAME_VALUE"; return 2; }
    [ -d /sys/firmware/efi ] || { error 'UEFI mode is required'; return 2; }
    for command in slackpkg installpkg python3 sha256sum mkinitrd sort find install mv cmp stat sync; do
        command -v "$command" >/dev/null 2>&1 || { error "required command missing: $command"; return 2; }
    done
    require_regular_file "$ELILO_CONFIG" || { error 'unsafe or unreadable elilo.conf'; return 2; }
    require_regular_file "$GENERATOR" || { error 'mkinitrd command generator unavailable'; return 2; }
    require_regular_file "$BLACKLIST" || { error 'Slackpkg blacklist unavailable'; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    if [ -z "$OUTPUT_DIR" ]; then OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"; fi
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"
    trap cleanup_transaction EXIT
    trap 'handle_transaction_signal HUP' HUP
    trap 'handle_transaction_signal INT' INT
    trap 'handle_transaction_signal TERM' TERM

    capture_package_database "$PACKAGE_DATABASE" "$OUTPUT_DIR/packages.before.txt" \
        && record_pass 'the installed package database was captured before the transaction' \
        || record_failure 'the installed package database could not be captured before the transaction'
    capture_boot_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the ELILO boot state was captured before the transaction' \
        || record_failure 'the ELILO boot state could not be captured before the transaction'

    ELILO_IMAGE=$(read_elilo_assignment_from "$ELILO_CONFIG" image || true)
    ELILO_INITRD=$(read_elilo_assignment_from "$ELILO_CONFIG" initrd || true)
    [ "$ELILO_IMAGE" = vmlinuz ] && [ "$ELILO_INITRD" = initrd.gz ] \
        && record_pass 'the active ELILO configuration matches the reviewed legacy names' \
        || record_failure 'the active ELILO configuration changed after review'

    capture_installed_kernel_records "$PACKAGE_DATABASE" "$OUTPUT_DIR/installed-kernel-records.before.tsv" \
        && record_pass 'the installed boot-kernel package set was captured' \
        || record_failure 'the installed boot-kernel package set is unsafe'
    CURRENT_KERNEL_VERSION=$(awk -F '\t' 'NR == 1 { print $2 }' "$OUTPUT_DIR/installed-kernel-records.before.tsv")
    RUNNING_KERNEL=$(uname -r)
    installed_versions=$(cut -f2 "$OUTPUT_DIR/installed-kernel-records.before.tsv" | sort -u | wc -l)
    [ "$installed_versions" -eq 1 ] && [ "$RUNNING_KERNEL" = "$CURRENT_KERNEL_VERSION" ] \
        && record_pass "the running and installed boot-kernel version is $CURRENT_KERNEL_VERSION" \
        || record_failure 'the running and installed boot-kernel versions differ'
    if [ -f "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" ] \
        && [ ! -L "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" ] \
        && cmp -s -- "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" "$ELILO_DIRECTORY/vmlinuz"; then
        record_pass 'the working generic kernel still matches the active ELILO copy'
    else
        record_failure 'the working generic kernel no longer matches the active ELILO copy'
    fi
    if [ -f /boot/initrd.gz ] && [ ! -L /boot/initrd.gz ] \
        && cmp -s -- /boot/initrd.gz "$ELILO_DIRECTORY/initrd.gz"; then
        record_pass 'the working initrd still matches the active ELILO copy'
    else
        record_failure 'the working initrd no longer matches the active ELILO copy'
    fi
    blacklist_has_exact_deferrals \
        && record_pass 'the three exact kernel deferrals are still active' \
        || record_failure 'the reviewed kernel deferrals are not active'

    printf 'Refreshing Slackware package metadata before the authorized transaction...\n'
    if run_metadata_refresh "$OUTPUT_DIR/slackpkg-update.log" "$OUTPUT_DIR/slackpkg-update.exit"; then
        record_pass 'Slackware package metadata was refreshed before installation'
    else
        record_failure 'Slackware package metadata refresh failed'
    fi
    capture_installed_kernel_records "$PACKAGE_DATABASE" "$OUTPUT_DIR/installed-kernel-records.plan.tsv" || true
    resolve_repository_kernel_candidate "$PKGLIST" "$OUTPUT_DIR/installed-kernel-records.plan.tsv" \
        "$OUTPUT_DIR/repository-kernel-records.tsv" "$OUTPUT_DIR/selected-kernel-records.tsv" \
        "$OUTPUT_DIR/candidate-summary.txt" \
        && record_pass 'one newest complete kernel candidate was resolved after metadata refresh' \
        || record_failure 'the kernel candidate could not be resolved safely'
    TARGET_KERNEL_VERSION=$(read_summary_value version "$OUTPUT_DIR/candidate-summary.txt")
    TARGET_KERNEL_BUILD=$(read_summary_value build "$OUTPUT_DIR/candidate-summary.txt")
    TARGET_KERNEL_REPOSITORY=$(read_summary_value repository "$OUTPUT_DIR/candidate-summary.txt")
    CANDIDATE_SET_SHA256=$(sha256sum "$OUTPUT_DIR/selected-kernel-records.tsv" | awk '{print $1}')
    [ "$TARGET_KERNEL_VERSION" = "$CONFIRM_TARGET_KERNEL" ] \
        && record_pass "the target kernel remains $TARGET_KERNEL_VERSION" \
        || record_failure 'the target kernel changed after review'
    [ "$CANDIDATE_SET_SHA256" = "${CONFIRM_CANDIDATE_SHA256,,}" ] \
        && record_pass 'the candidate-set digest matches the reviewed evidence' \
        || record_failure 'the candidate-set digest changed after review'
    [ "$FAILURE_COUNT" -eq 0 ] || { TRANSACTION_STATUS=precondition-failed; write_apply_summary "$OUTPUT_DIR/summary.txt"; publish_apply_evidence; return 1; }

    TARGET_EFI_KERNEL="vmlinuz-generic-$TARGET_KERNEL_VERSION"
    TARGET_EFI_INITRD="initrd-generic-$TARGET_KERNEL_VERSION.gz"
    new_boot_kernel="/boot/vmlinuz-generic-$TARGET_KERNEL_VERSION"
    new_boot_initrd="/boot/initrd-generic-$TARGET_KERNEL_VERSION.gz"
    planned_config="$OUTPUT_DIR/elilo.conf.planned"
    write_transaction_elilo_config "$ELILO_CONFIG" "$planned_config" "$TARGET_EFI_KERNEL" "$TARGET_EFI_INITRD" \
        && validate_transaction_elilo_config "$planned_config" "$TARGET_EFI_KERNEL" "$TARGET_EFI_INITRD" \
        && record_pass 'the versioned ELILO configuration and old-kernel fallback were generated' \
        || record_failure 'the versioned ELILO configuration could not be generated safely'
    calculate_space_plan "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" /boot/initrd.gz /boot/efi /boot \
        && record_pass 'the EFI and /boot filesystems retain conservative staging space' \
        || record_failure 'insufficient conservative staging space'
    [ ! -e "$new_boot_initrd" ] && [ ! -e "$ELILO_DIRECTORY/$TARGET_EFI_KERNEL" ] \
        && [ ! -e "$ELILO_DIRECTORY/$TARGET_EFI_INITRD" ] \
        && record_pass 'the versioned target paths do not collide' \
        || record_failure 'a versioned target path already exists'
    [ "$FAILURE_COUNT" -eq 0 ] || { TRANSACTION_STATUS=planning-failed; write_apply_summary "$OUTPUT_DIR/summary.txt"; publish_apply_evidence; return 1; }

    BLACKLIST_BACKUP="$OUTPUT_DIR/blacklist.original"
    ELILO_CONFIG_BACKUP="$OUTPUT_DIR/elilo.conf.original"
    cp -a -- "$BLACKLIST" "$BLACKLIST_BACKUP" || return 1
    cp -a -- "$ELILO_CONFIG" "$ELILO_CONFIG_BACKUP" || return 1
    write_blacklist_without_deferrals "$BLACKLIST_BACKUP" "$OUTPUT_DIR/blacklist.transaction" \
        || { record_failure 'the exact kernel deferrals could not be isolated'; return 1; }
    atomic_replace_preserving_metadata "$OUTPUT_DIR/blacklist.transaction" "$BLACKLIST" || return 1
    BLACKLIST_MODIFIED=1
    record_pass 'only the three exact kernel deferrals were removed temporarily'

    TRANSACTION_STATUS=packages-downloading
    printf 'Downloading the three reviewed kernel packages without replacing the working kernel...\n'
    if run_kernel_package_download "$OUTPUT_DIR/slackpkg-download.log"; then
        record_pass 'Slackpkg downloaded the reviewed kernel package set'
    else
        record_failure "Slackpkg kernel download failed with status $SLACKPKG_DOWNLOAD_STATUS"
    fi
    if restore_blacklist && cmp -s -- "$BLACKLIST_BACKUP" "$BLACKLIST"; then
        record_pass 'the original Slackpkg blacklist was restored byte-for-byte after download'
    else
        record_failure 'the original Slackpkg blacklist could not be restored'
    fi
    resolve_downloaded_kernel_packages "$OUTPUT_DIR/selected-kernel-records.tsv" /var/cache/packages \
        "$OUTPUT_DIR/downloaded-kernel-packages.txt" \
        && record_pass 'the three exact downloaded package files were resolved from the cache' \
        || record_failure 'the downloaded kernel package set is incomplete or ambiguous'
    [ "$FAILURE_COUNT" -eq 0 ] || { TRANSACTION_STATUS=download-stage-failed; write_apply_summary "$OUTPUT_DIR/summary.txt"; publish_apply_evidence; return 1; }

    TRANSACTION_STATUS=packages-installing
    printf 'Installing the reviewed kernel packages alongside the working kernel...\n'
    if install_downloaded_kernel_packages "$OUTPUT_DIR/downloaded-kernel-packages.txt" "$OUTPUT_DIR/installpkg.log"; then
        record_pass 'installpkg installed the reviewed kernel packages without removing the working version'
    else
        record_failure "installpkg failed with status $INSTALLPKG_STATUS"
    fi
    validate_installed_target_kernel "$PACKAGE_DATABASE" "$CURRENT_KERNEL_VERSION" "$TARGET_KERNEL_VERSION" \
        "$OUTPUT_DIR/installed-kernel-records.after.tsv" \
        && record_pass 'the old and new boot-kernel package versions coexist for rollback' \
        || record_failure 'the installed boot-kernel package set does not preserve both versions'
    [ -s "$new_boot_kernel" ] && [ -d "/lib/modules/$TARGET_KERNEL_VERSION" ] \
        && record_pass 'the target generic kernel and module tree are installed' \
        || record_failure 'the target generic kernel or module tree is missing'
    [ "$FAILURE_COUNT" -eq 0 ] || { TRANSACTION_STATUS=package-stage-failed; write_apply_summary "$OUTPUT_DIR/summary.txt"; publish_apply_evidence; return 1; }

    TRANSACTION_STATUS=initrd-building
    capture_generator_command "$TARGET_KERNEL_VERSION" "$OUTPUT_DIR/mkinitrd-generator.log" "$OUTPUT_DIR/mkinitrd-generator.exit" \
        && record_pass 'the official generator proposed the target initrd command' \
        || record_failure 'the official generator failed for the target kernel'
    STAGED_BOOT_INITRD="/boot/.slack-update-initrd-generic-$TARGET_KERNEL_VERSION.gz.$$"
    run_versioned_mkinitrd "$OUTPUT_DIR/mkinitrd-generator.log" "$STAGED_BOOT_INITRD" "$OUTPUT_DIR/mkinitrd.argv.nul" \
        && record_pass 'the target initrd was built from a strictly parsed command' \
        || record_failure 'the target initrd could not be built safely'
    if [ "$FAILURE_COUNT" -eq 0 ]; then
        mv -T -- "$STAGED_BOOT_INITRD" "$new_boot_initrd" || record_failure 'the versioned /boot initrd could not be committed'
        STAGED_BOOT_INITRD=
    fi
    [ -s "$new_boot_initrd" ] && [ ! -L "$new_boot_initrd" ] \
        && record_pass 'the versioned /boot initrd is a non-empty regular file' \
        || record_failure 'the versioned /boot initrd is invalid'
    [ "$FAILURE_COUNT" -eq 0 ] || { TRANSACTION_STATUS=initrd-stage-failed; write_apply_summary "$OUTPUT_DIR/summary.txt"; publish_apply_evidence; return 1; }

    TRANSACTION_STATUS=efi-staging
    STAGED_EFI_KERNEL="$ELILO_DIRECTORY/.slack-update-$TARGET_EFI_KERNEL.$$"
    STAGED_EFI_INITRD="$ELILO_DIRECTORY/.slack-update-$TARGET_EFI_INITRD.$$"
    stage_verified_copy "$new_boot_kernel" "$STAGED_EFI_KERNEL" "$ELILO_DIRECTORY/$TARGET_EFI_KERNEL" 0755 \
        && { STAGED_EFI_KERNEL=; record_pass 'the versioned generic kernel was verified in the EFI partition'; } \
        || record_failure 'the versioned generic kernel could not be staged in the EFI partition'
    stage_verified_copy "$new_boot_initrd" "$STAGED_EFI_INITRD" "$ELILO_DIRECTORY/$TARGET_EFI_INITRD" 0755 \
        && { STAGED_EFI_INITRD=; record_pass 'the versioned initrd was verified in the EFI partition'; } \
        || record_failure 'the versioned initrd could not be staged in the EFI partition'
    [ "$FAILURE_COUNT" -eq 0 ] || { TRANSACTION_STATUS=efi-stage-failed; write_apply_summary "$OUTPUT_DIR/summary.txt"; publish_apply_evidence; return 1; }

    TRANSACTION_STATUS=activating
    if activate_elilo_config "$planned_config"; then
        record_pass 'elilo.conf atomically activated the verified versioned kernel and initrd'
    else
        restore_elilo_config || true
        record_failure 'elilo.conf activation failed and the original configuration was restored'
    fi
    sync
    if cmp -s -- "$ELILO_CONFIG_BACKUP" "$ELILO_CONFIG"; then
        record_failure 'the active ELILO configuration did not switch to the target entry'
    else
        record_pass 'the active ELILO configuration changed only at the final activation boundary'
    fi
    if cmp -s -- "/boot/vmlinuz-generic-$CURRENT_KERNEL_VERSION" "$ELILO_DIRECTORY/vmlinuz" \
        && cmp -s -- /boot/initrd.gz "$ELILO_DIRECTORY/initrd.gz"; then
        record_pass 'the old ELILO kernel and initrd remain byte-identical rollback artifacts'
    else
        record_failure 'the old ELILO rollback kernel or initrd changed unexpectedly'
    fi
    sha256sum -- "$new_boot_kernel" "$new_boot_initrd" \
        "$ELILO_DIRECTORY/$TARGET_EFI_KERNEL" "$ELILO_DIRECTORY/$TARGET_EFI_INITRD" \
        "$ELILO_CONFIG" > "$OUTPUT_DIR/new-artifacts.sha256" \
        || record_failure 'the committed boot artifacts could not be hashed'
    capture_boot_state "$OUTPUT_DIR/boot.after.txt" || record_failure 'the final boot state could not be captured'
    capture_package_database "$PACKAGE_DATABASE" "$OUTPUT_DIR/packages.after.txt" || record_failure 'the final package database could not be captured'
    diff -u -- "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" > "$OUTPUT_DIR/packages.diff" 2>&1 || true
    diff -u -- "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" > "$OUTPUT_DIR/boot.diff" 2>&1 || true
    if [ "$ELILO_COMMITTED" -eq 1 ] && [ "$FAILURE_COUNT" -eq 0 ]; then
        TRANSACTION_STATUS=committed-reboot-required
        record_pass 'the ELILO kernel transaction committed successfully and requires reboot validation'
    else
        TRANSACTION_STATUS=activation-failed
    fi
    write_apply_summary "$OUTPUT_DIR/summary.txt"
    printf 'ELILO kernel transaction result: target=%s, status=%s, reboot-required=true\n' \
        "$TARGET_KERNEL_VERSION" "$TRANSACTION_STATUS"
    publish_apply_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
