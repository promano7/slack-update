#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly FROZEN_REFERENCE_SCRIPT_SHA256='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
readonly FROZEN_EFFECTIVE_CONFIG_SHA256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
readonly FROZEN_KERNEL_HEADERS='kernel-headers'
readonly FROZEN_KERNEL_BOOT='kernel-generic kernel-huge kernel-modules'
readonly PACKAGE_DATABASE='/var/log/packages'
readonly PACKAGE_DATABASE_CANONICAL='/var/lib/pkgtools/packages'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-target-binding-probe.sh --observe-target-binding
       phase-1-kernel-package-edge-runtime-target-binding-probe.sh --help

Perform the read-only Phase 1 step-193 target observation for the selected
kernel-package-edge scenario. The probe reads target identity, package database
records, Slackware identity, selected slackpkg configuration fingerprints, and
required command availability. It performs no repository refresh, network
access, package action, boot action, persistent configuration change, or reboot.
USAGE
}

observe=0
while (($#)); do
    case "$1" in
        --observe-target-binding)
            [[ $observe -eq 0 ]] || { printf 'ERROR: duplicate --observe-target-binding\n' >&2; exit 2; }
            observe=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done
[[ $observe -eq 1 ]] || { usage >&2; exit 2; }
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: run this read-only probe through sudo/root\n' >&2; exit 3; }

for path in /etc/slackware-version /proc/sys/kernel/random/boot_id; do
    [[ -f $path && ! -L $path ]] || { printf 'ERROR: required target identity file missing or unsafe: %s\n' "$path" >&2; exit 4; }
done
[[ -d $PACKAGE_DATABASE_CANONICAL && ! -L $PACKAGE_DATABASE_CANONICAL ]] || {
    printf 'ERROR: canonical package database missing or unsafe: %s\n' "$PACKAGE_DATABASE_CANONICAL" >&2
    exit 4
}
[[ -L $PACKAGE_DATABASE ]] || {
    printf 'ERROR: compatibility package database is not the expected symlink: %s\n' "$PACKAGE_DATABASE" >&2
    exit 4
}
package_database_resolved=$(readlink -f -- "$PACKAGE_DATABASE" 2>/dev/null || true)
[[ $package_database_resolved == "$PACKAGE_DATABASE_CANONICAL" ]] || {
    printf 'ERROR: package database symlink target mismatch\nexpected: %s\nactual:   %s\n' \
        "$PACKAGE_DATABASE_CANONICAL" "${package_database_resolved:-<unresolved>}" >&2
    exit 4
}

fqdn=$(hostname -f 2>/dev/null || true)
[[ $fqdn == "$EXPECTED_FQDN" ]] || {
    printf 'ERROR: target FQDN mismatch\nexpected: %s\nactual:   %s\n' "$EXPECTED_FQDN" "${fqdn:-<empty>}" >&2
    exit 5
}

required_commands=(bash python3 sha256sum tar flock slackpkg upgradepkg find sort hostname uname awk cat id readlink)
missing=()
for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        missing+=("$command_name")
    fi
done
if ((${#missing[@]})); then
    printf 'ERROR: required capability missing: %s\n' "${missing[*]}" >&2
    exit 6
fi

package_records() {
    local package_name=$1
    local candidate base
    local records=()
    shopt -s nullglob
    for candidate in "$PACKAGE_DATABASE_CANONICAL/$package_name-"*; do
        [[ -f $candidate && ! -L $candidate ]] || continue
        base=${candidate##*/}
        records+=("$base")
    done
    shopt -u nullglob
    if ((${#records[@]})); then
        printf '%s\n' "${records[@]}" | LC_ALL=C sort
    fi
}

manifest_hash() {
    local directory=$1
    find "$directory" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'
}

regular_file_hash_or_absent() {
    local path=$1
    if [[ -f $path && ! -L $path ]]; then
        sha256sum -- "$path" | awk '{print $1}'
    else
        printf 'absent\n'
    fi
}

header_records=$(package_records "$FROZEN_KERNEL_HEADERS")
header_count=0
if [[ -n $header_records ]]; then
    header_count=$(printf '%s\n' "$header_records" | awk 'NF { count++ } END { print count+0 }')
fi
[[ $header_count -eq 1 ]] || {
    printf 'ERROR: expected exactly one installed record for %s, found %d\n' "$FROZEN_KERNEL_HEADERS" "$header_count" >&2
    exit 7
}

boot_records_unambiguous=yes
installed_boot_package_count=0
boot_record_lines=()
IFS=' ' read -r -a kernel_boot_packages <<< "$FROZEN_KERNEL_BOOT"
for package_name in "${kernel_boot_packages[@]}"; do
    records=$(package_records "$package_name")
    count=0
    status=absent
    if [[ -n $records ]]; then
        count=$(printf '%s\n' "$records" | awk 'NF { count++ } END { print count+0 }')
    fi
    if [[ $count -gt 1 ]]; then
        boot_records_unambiguous=no
    elif [[ $count -eq 1 ]]; then
        status=installed
        installed_boot_package_count=$((installed_boot_package_count + 1))
        while IFS= read -r record; do
            [[ -n $record ]] && boot_record_lines+=("$package_name|$record")
        done <<< "$records"
    fi
    printf -v "boot_count_${package_name//-/_}" '%s' "$count"
    printf -v "boot_status_${package_name//-/_}" '%s' "$status"
done
[[ $boot_records_unambiguous == yes ]] || {
    printf 'ERROR: configured kernel boot package records are ambiguous\n' >&2
    exit 8
}
[[ $installed_boot_package_count -ge 1 ]] || {
    printf 'ERROR: no configured kernel boot package is installed\n' >&2
    exit 8
}

probe_path=$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')
slackware_version=$(cat /etc/slackware-version)
boot_id=$(cat /proc/sys/kernel/random/boot_id)
hostname_short=$(hostname)
uname_release=$(uname -r)
uname_machine=$(uname -m)
package_db_manifest_sha=$(manifest_hash "$PACKAGE_DATABASE_CANONICAL")
slackpkg_conf_sha=$(regular_file_hash_or_absent /etc/slackpkg/slackpkg.conf)
slackpkg_mirrors_sha=$(regular_file_hash_or_absent /etc/slackpkg/mirrors)

printf 'binding_status\tPASS\n'
printf 'target_hostname\t%s\n' "$hostname_short"
printf 'hostname_fqdn\t%s\n' "$fqdn"
printf 'uname_release\t%s\n' "$uname_release"
printf 'uname_machine\t%s\n' "$uname_machine"
printf 'slackware_version\t%s\n' "$slackware_version"
printf 'boot_id\t%s\n' "$boot_id"
printf 'reference_script_sha256\t%s\n' "$FROZEN_REFERENCE_SCRIPT_SHA256"
printf 'effective_config_sha256\t%s\n' "$FROZEN_EFFECTIVE_CONFIG_SHA256"
printf 'configured_kernel_headers\t%s\n' "$FROZEN_KERNEL_HEADERS"
printf 'configured_kernel_boot\t%s\n' "$FROZEN_KERNEL_BOOT"
printf 'package_database\t%s\n' "$PACKAGE_DATABASE"
printf 'package_database_canonical\t%s\n' "$PACKAGE_DATABASE_CANONICAL"
printf 'package_database_resolved\t%s\n' "$package_database_resolved"
printf 'package_database_manifest_sha256\t%s\n' "$package_db_manifest_sha"
printf 'header_package_record_count\t%s\n' "$header_count"
printf 'header_package_record\t%s\n' "$header_records"
printf 'boot_package_records_unambiguous\t%s\n' "$boot_records_unambiguous"
printf 'installed_boot_package_count\t%s\n' "$installed_boot_package_count"
for package_name in "${kernel_boot_packages[@]}"; do
    count_variable="boot_count_${package_name//-/_}"
    status_variable="boot_status_${package_name//-/_}"
    printf 'boot_package_record_count_%s\t%s\n' "$package_name" "${!count_variable}"
    printf 'boot_package_record_status_%s\t%s\n' "$package_name" "${!status_variable}"
done
for item in "${boot_record_lines[@]}"; do
    printf 'boot_package_record\t%s\n' "$item"
done
printf 'slackpkg_conf_sha256\t%s\n' "$slackpkg_conf_sha"
printf 'slackpkg_mirrors_sha256\t%s\n' "$slackpkg_mirrors_sha"
printf 'probe_sha256\t%s\n' "$probe_sha"
printf 'source_identity_origin\tcontroller-repo-frozen-at-step-193\n'
printf 'target_repository_required\tno\n'
printf 'repository_refresh_performed\tno\n'
printf 'network_access_performed\tno\n'
printf 'package_action_performed\tno\n'
printf 'boot_action_performed\tno\n'
printf 'persistent_configuration_change_performed\tno\n'
printf 'reboot_performed\tno\n'
