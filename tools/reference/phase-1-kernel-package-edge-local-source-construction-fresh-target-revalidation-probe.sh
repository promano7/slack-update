#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_UNAME_MACHINE='x86_64'
readonly EXPECTED_UNAME_RELEASE='6.18.45'
readonly EXPECTED_SLACKWARE_VERSION='Slackware 15.0+'
readonly FROZEN_REFERENCE_SCRIPT_SHA256='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
readonly FROZEN_EFFECTIVE_CONFIG_SHA256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'
readonly EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
readonly FROZEN_PREDECESSOR_ARTIFACT='kernel-headers-6.18.44-x86-1.txz'
readonly FROZEN_PREDECESSOR_SHA256='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
readonly FROZEN_TARGET_ARTIFACT='kernel-headers-6.18.45-x86-1.txz'
readonly FROZEN_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
readonly FROZEN_KERNEL_HEADERS='kernel-headers'
readonly FROZEN_KERNEL_BOOT='kernel-generic kernel-huge kernel-modules'
readonly PACKAGE_DATABASE='/var/log/packages'
readonly PACKAGE_DATABASE_CANONICAL='/var/lib/pkgtools/packages'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-probe.sh --observe-fresh-target-revalidation
       phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-probe.sh --help

Perform the read-only Phase 1 step-201 fresh target revalidation for the
kernel-package-edge continuation. The probe validates that the designated VM
still matches the frozen pre-staging package/configuration baseline while
accepting a fresh boot ID. It performs no repository refresh, network access,
package action, boot action, persistent configuration change, or reboot.
USAGE
}

observe=0
while (($#)); do
    case "$1" in
        --observe-fresh-target-revalidation)
            [[ $observe -eq 0 ]] || { printf 'ERROR: duplicate --observe-fresh-target-revalidation\n' >&2; exit 2; }
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

hostname_short=$(hostname)
uname_release=$(uname -r)
uname_machine=$(uname -m)
slackware_version=$(cat /etc/slackware-version)
boot_id=$(cat /proc/sys/kernel/random/boot_id)
package_db_manifest_sha=$(manifest_hash "$PACKAGE_DATABASE_CANONICAL")
slackpkg_conf_sha=$(regular_file_hash_or_absent /etc/slackpkg/slackpkg.conf)
slackpkg_mirrors_sha=$(regular_file_hash_or_absent /etc/slackpkg/mirrors)

[[ $uname_machine == "$EXPECTED_UNAME_MACHINE" ]] || {
    printf 'ERROR: target architecture drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_UNAME_MACHINE" "$uname_machine" >&2
    exit 7
}
[[ $uname_release == "$EXPECTED_UNAME_RELEASE" ]] || {
    printf 'ERROR: running kernel drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_UNAME_RELEASE" "$uname_release" >&2
    exit 7
}
[[ $slackware_version == "$EXPECTED_SLACKWARE_VERSION" ]] || {
    printf 'ERROR: Slackware release string drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_SLACKWARE_VERSION" "$slackware_version" >&2
    exit 7
}
[[ $package_db_manifest_sha == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || {
    printf 'ERROR: package database manifest drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" "$package_db_manifest_sha" >&2
    exit 8
}
[[ $slackpkg_conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || {
    printf 'ERROR: slackpkg.conf fingerprint drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_SLACKPKG_CONF_SHA256" "$slackpkg_conf_sha" >&2
    exit 8
}
[[ $slackpkg_mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || {
    printf 'ERROR: slackpkg mirrors fingerprint drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_SLACKPKG_MIRRORS_SHA256" "$slackpkg_mirrors_sha" >&2
    exit 8
}

header_records=$(package_records "$FROZEN_KERNEL_HEADERS")
header_count=0
if [[ -n $header_records ]]; then
    header_count=$(printf '%s\n' "$header_records" | awk 'NF { count++ } END { print count+0 }')
fi
[[ $header_count -eq 1 && $header_records == "$EXPECTED_HEADER_RECORD" ]] || {
    printf 'ERROR: kernel-headers record drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_HEADER_RECORD" "${header_records:-<none>}" >&2
    exit 9
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
    printf -v "boot_records_${package_name//-/_}" '%s' "$records"
done
[[ $boot_records_unambiguous == yes ]] || {
    printf 'ERROR: configured kernel boot package records are ambiguous\n' >&2
    exit 10
}
[[ $installed_boot_package_count -eq 1 ]] || {
    printf 'ERROR: expected exactly one installed configured boot package, found %d\n' "$installed_boot_package_count" >&2
    exit 10
}
[[ ${boot_count_kernel_generic} -eq 1 && ${boot_status_kernel_generic} == installed && ${boot_records_kernel_generic} == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || {
    printf 'ERROR: kernel-generic record drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_KERNEL_GENERIC_RECORD" "${boot_records_kernel_generic:-<none>}" >&2
    exit 10
}
[[ ${boot_count_kernel_huge} -eq 0 && ${boot_status_kernel_huge} == absent ]] || {
    printf 'ERROR: kernel-huge observation drift\n' >&2
    exit 10
}
[[ ${boot_count_kernel_modules} -eq 0 && ${boot_status_kernel_modules} == absent ]] || {
    printf 'ERROR: kernel-modules observation drift\n' >&2
    exit 10
}

probe_path=$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

printf 'revalidation_status\tPASS\n'
printf 'target_hostname\t%s\n' "$hostname_short"
printf 'hostname_fqdn\t%s\n' "$fqdn"
printf 'uname_release\t%s\n' "$uname_release"
printf 'uname_machine\t%s\n' "$uname_machine"
printf 'slackware_version\t%s\n' "$slackware_version"
printf 'boot_id\t%s\n' "$boot_id"
printf 'reference_script_sha256\t%s\n' "$FROZEN_REFERENCE_SCRIPT_SHA256"
printf 'effective_config_sha256\t%s\n' "$FROZEN_EFFECTIVE_CONFIG_SHA256"
printf 'frozen_predecessor_artifact\t%s\n' "$FROZEN_PREDECESSOR_ARTIFACT"
printf 'frozen_predecessor_sha256\t%s\n' "$FROZEN_PREDECESSOR_SHA256"
printf 'frozen_target_artifact\t%s\n' "$FROZEN_TARGET_ARTIFACT"
printf 'frozen_target_sha256\t%s\n' "$FROZEN_TARGET_SHA256"
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
printf 'prior_target_binding_reused\tno\n'
printf 'fresh_boot_id_observed\tyes\n'
printf 'source_identity_origin\tcontroller-repo-frozen-at-step-201\n'
printf 'target_repository_required\tno\n'
printf 'repository_refresh_performed\tno\n'
printf 'network_access_performed\tno\n'
printf 'package_action_performed\tno\n'
printf 'boot_action_performed\tno\n'
printf 'persistent_configuration_change_performed\tno\n'
printf 'reboot_performed\tno\n'
