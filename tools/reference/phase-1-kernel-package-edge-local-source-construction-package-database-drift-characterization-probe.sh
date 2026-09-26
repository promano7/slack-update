#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_UNAME_RELEASE='6.18.45'
readonly EXPECTED_UNAME_MACHINE='x86_64'
readonly EXPECTED_SLACKWARE_VERSION='Slackware 15.0+'
readonly EXPECTED_BASELINE_MANIFEST_SHA256='3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
readonly EXPECTED_DRIFT_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
readonly BASELINE_OBSERVED_UTC='2026-09-24 16:18:07 UTC'
readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'
readonly EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
readonly PACKAGE_DATABASE='/var/log/packages'
readonly PACKAGE_DATABASE_CANONICAL='/var/lib/pkgtools/packages'
readonly REMOVED_DATABASE_CANONICAL='/var/lib/pkgtools/removed_packages'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-probe.sh --characterize-package-database-drift

Perform the read-only step-201-r1 characterization of the package-database
manifest drift observed by step 201. No network, package, boot, configuration,
or reboot action is performed.
USAGE
}

[[ ${1:-} == --characterize-package-database-drift && $# -eq 1 ]] || { usage >&2; exit 2; }
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: run through sudo/root\n' >&2; exit 3; }

manifest_hash() {
    find "$1" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'
}
regular_file_hash_or_absent() {
    if [[ -f $1 && ! -L $1 ]]; then sha256sum -- "$1" | awk '{print $1}'; else printf 'absent\n'; fi
}
package_records() {
    local package_name=$1 candidate
    shopt -s nullglob
    for candidate in "$PACKAGE_DATABASE_CANONICAL/$package_name-"*; do
        [[ -f $candidate && ! -L $candidate ]] && printf '%s\n' "${candidate##*/}"
    done | LC_ALL=C sort
    shopt -u nullglob
}
recent_records() {
    local directory=$1
    [[ -d $directory && ! -L $directory ]] || return 0
    find "$directory" -maxdepth 1 -type f -newermt "$BASELINE_OBSERVED_UTC" -printf '%f\n' | LC_ALL=C sort
}
count_lines() {
    awk 'NF { count++ } END { print count+0 }'
}

for path in /etc/slackware-version /proc/sys/kernel/random/boot_id; do
    [[ -f $path && ! -L $path ]] || { printf 'ERROR: required identity file missing or unsafe: %s\n' "$path" >&2; exit 4; }
done
[[ -d $PACKAGE_DATABASE_CANONICAL && ! -L $PACKAGE_DATABASE_CANONICAL ]] || { printf 'ERROR: canonical package database missing or unsafe\n' >&2; exit 4; }
[[ -L $PACKAGE_DATABASE ]] || { printf 'ERROR: package database compatibility path is not a symlink\n' >&2; exit 4; }
resolved=$(readlink -f -- "$PACKAGE_DATABASE" 2>/dev/null || true)
[[ $resolved == "$PACKAGE_DATABASE_CANONICAL" ]] || { printf 'ERROR: package database symlink target mismatch\n' >&2; exit 4; }

fqdn=$(hostname -f 2>/dev/null || true)
uname_release=$(uname -r)
uname_machine=$(uname -m)
slackware_version=$(cat /etc/slackware-version)
[[ $fqdn == "$EXPECTED_FQDN" ]] || { printf 'ERROR: target FQDN drift\n' >&2; exit 5; }
[[ $uname_release == "$EXPECTED_UNAME_RELEASE" ]] || { printf 'ERROR: running kernel drift\n' >&2; exit 5; }
[[ $uname_machine == "$EXPECTED_UNAME_MACHINE" ]] || { printf 'ERROR: architecture drift\n' >&2; exit 5; }
[[ $slackware_version == "$EXPECTED_SLACKWARE_VERSION" ]] || { printf 'ERROR: Slackware release drift\n' >&2; exit 5; }

actual_manifest=$(manifest_hash "$PACKAGE_DATABASE_CANONICAL")
[[ $actual_manifest == "$EXPECTED_DRIFT_MANIFEST_SHA256" ]] || {
    printf 'ERROR: package database changed again since the step-201 failure\nexpected-current: %s\nactual:           %s\n' "$EXPECTED_DRIFT_MANIFEST_SHA256" "$actual_manifest" >&2
    exit 6
}

header_records=$(package_records kernel-headers)
generic_records=$(package_records kernel-generic)
huge_records=$(package_records kernel-huge)
modules_records=$(package_records kernel-modules)
slackpkg_conf_sha=$(regular_file_hash_or_absent /etc/slackpkg/slackpkg.conf)
slackpkg_mirrors_sha=$(regular_file_hash_or_absent /etc/slackpkg/mirrors)
recent_installed=$(recent_records "$PACKAGE_DATABASE_CANONICAL")
recent_removed=$(recent_records "$REMOVED_DATABASE_CANONICAL")
recent_installed_count=$(printf '%s\n' "$recent_installed" | count_lines)
recent_removed_count=$(printf '%s\n' "$recent_removed" | count_lines)
probe_path=$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

header_match=no; [[ $header_records == "$EXPECTED_HEADER_RECORD" ]] && header_match=yes
generic_match=no; [[ $generic_records == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] && generic_match=yes
huge_absent=no; [[ -z $huge_records ]] && huge_absent=yes
modules_absent=no; [[ -z $modules_records ]] && modules_absent=yes
conf_match=no; [[ $slackpkg_conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] && conf_match=yes
mirrors_match=no; [[ $slackpkg_mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] && mirrors_match=yes

printf 'characterization_status\tPASS\n'
printf 'hostname_fqdn\t%s\n' "$fqdn"
printf 'uname_release\t%s\n' "$uname_release"
printf 'uname_machine\t%s\n' "$uname_machine"
printf 'slackware_version\t%s\n' "$slackware_version"
printf 'boot_id\t%s\n' "$(cat /proc/sys/kernel/random/boot_id)"
printf 'baseline_observed_utc\t%s\n' "$BASELINE_OBSERVED_UTC"
printf 'baseline_package_database_manifest_sha256\t%s\n' "$EXPECTED_BASELINE_MANIFEST_SHA256"
printf 'observed_drift_package_database_manifest_sha256\t%s\n' "$actual_manifest"
printf 'package_database_manifest_drift\tyes\n'
printf 'header_package_record\t%s\n' "${header_records:-<none>}"
printf 'header_package_record_baseline_match\t%s\n' "$header_match"
printf 'kernel_generic_record\t%s\n' "${generic_records:-<none>}"
printf 'kernel_generic_record_baseline_match\t%s\n' "$generic_match"
printf 'kernel_huge_absent\t%s\n' "$huge_absent"
printf 'kernel_modules_absent\t%s\n' "$modules_absent"
printf 'slackpkg_conf_sha256\t%s\n' "$slackpkg_conf_sha"
printf 'slackpkg_conf_baseline_match\t%s\n' "$conf_match"
printf 'slackpkg_mirrors_sha256\t%s\n' "$slackpkg_mirrors_sha"
printf 'slackpkg_mirrors_baseline_match\t%s\n' "$mirrors_match"
printf 'recent_installed_record_count\t%s\n' "$recent_installed_count"
while IFS= read -r line; do [[ -n $line ]] && printf 'recent_installed_record\t%s\n' "$line"; done <<< "$recent_installed"
printf 'recent_removed_record_count\t%s\n' "$recent_removed_count"
while IFS= read -r line; do [[ -n $line ]] && printf 'recent_removed_record\t%s\n' "$line"; done <<< "$recent_removed"
printf 'probe_sha256\t%s\n' "$probe_sha"
printf 'network_access_performed\tno\n'
printf 'repository_refresh_performed\tno\n'
printf 'package_action_performed\tno\n'
printf 'boot_action_performed\tno\n'
printf 'persistent_configuration_change_performed\tno\n'
printf 'reboot_performed\tno\n'
