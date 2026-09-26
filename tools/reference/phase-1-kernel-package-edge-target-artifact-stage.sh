#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
umask 022

EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
EXPECTED_UNAME_RELEASE='6.18.45'
EXPECTED_UNAME_MACHINE='x86_64'
EXPECTED_SLACKWARE_VERSION='Slackware 15.0+'
EXPECTED_BOOT_ID='d767c4ed-b21f-4c6f-9a1e-db7948c285cf'
EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'
EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
TARGET_FILENAME='kernel-headers-6.18.45-x86-1.txz'
TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
TRANSPORT_SOURCE='/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz'
PACKAGE_DATABASE='/var/lib/pkgtools/packages'
ACCEPTANCE_PARENT='/var/tmp/slack-update-acceptance'
ACCEPTANCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge'
STAGING_INPUT_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input'
STAGED_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-target-artifact-stage.sh --stage-target-artifact

Stage the frozen 6.18.45 kernel-headers artifact from the fixed transport path
into the Phase 1 kernel-package-edge staging root. This operation is local-only,
verifies the frozen target/runtime binding, preserves the transport copy, and
performs no package mutation, repository-configuration mutation, boot-state mutation, network access, or system restart.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; return 1; }
require_regular_nonsymlink() { [[ -f $1 && ! -L $1 ]] || fail "required regular non-symlink file missing: $1"; }
file_sha() { sha256sum -- "$1" | awk '{print $1}'; }
manifest_hash() { find "$1" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'; }
regular_file_hash_or_absent() { if [[ -f $1 && ! -L $1 ]]; then file_sha "$1"; else printf 'absent\n'; fi; }
package_records() {
    local package_name=$1 candidate base records=()
    shopt -s nullglob
    for candidate in "$PACKAGE_DATABASE/$package_name-"*; do
        [[ -f $candidate && ! -L $candidate ]] || continue
        base=${candidate##*/}; records+=("$base")
    done
    shopt -u nullglob
    ((${#records[@]})) && printf '%s\n' "${records[@]}" | LC_ALL=C sort || true
}
validate_transport_artifact() {
    local path=$1 expected_filename=$2 expected_sha=$3 actual
    require_regular_nonsymlink "$path" || return 1
    [[ ${path##*/} == "$expected_filename" ]] || fail "transport filename mismatch: ${path##*/}" || return 1
    actual=$(file_sha "$path")
    [[ $actual == "$expected_sha" ]] || fail 'transport artifact SHA-256 mismatch' || return 1
}
validate_runtime_binding() {
    local fqdn release machine version boot package_manifest conf_hash mirrors_hash headers generic huge modules
    fqdn=$(hostname -f 2>/dev/null || true); release=$(uname -r); machine=$(uname -m)
    version=$(cat /etc/slackware-version); boot=$(cat /proc/sys/kernel/random/boot_id)
    package_manifest=$(manifest_hash "$PACKAGE_DATABASE")
    conf_hash=$(regular_file_hash_or_absent /etc/slackpkg/slackpkg.conf)
    mirrors_hash=$(regular_file_hash_or_absent /etc/slackpkg/mirrors)
    headers=$(package_records kernel-headers); generic=$(package_records kernel-generic)
    huge=$(package_records kernel-huge); modules=$(package_records kernel-modules)
    [[ $fqdn == "$EXPECTED_FQDN" ]] || fail 'target FQDN drift' || return 1
    [[ $release == "$EXPECTED_UNAME_RELEASE" && $machine == "$EXPECTED_UNAME_MACHINE" ]] || fail 'kernel or architecture drift' || return 1
    [[ $version == "$EXPECTED_SLACKWARE_VERSION" && $boot == "$EXPECTED_BOOT_ID" ]] || fail 'release or boot identity drift' || return 1
    [[ $package_manifest == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail 'package database manifest drift' || return 1
    [[ $conf_hash == "$EXPECTED_SLACKPKG_CONF_SHA256" && $mirrors_hash == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg configuration drift' || return 1
    [[ $headers == "$EXPECTED_HEADER_RECORD" ]] || fail 'kernel-headers record drift' || return 1
    [[ $generic == "$EXPECTED_KERNEL_GENERIC_RECORD" && -z $huge && -z $modules ]] || fail 'boot package record drift' || return 1
}
preflight_destination() {
    [[ ! -e $ACCEPTANCE_ROOT && ! -L $ACCEPTANCE_ROOT ]] || fail "acceptance root already exists: $ACCEPTANCE_ROOT"
}
verify_staged_target() {
    local path=$1 expected_sha=$2 actual mode owner
    require_regular_nonsymlink "$path" || return 1
    actual=$(file_sha "$path"); [[ $actual == "$expected_sha" ]] || fail 'staged artifact SHA-256 mismatch' || return 1
    mode=$(stat -c '%a' -- "$path"); owner=$(stat -c '%U:%G' -- "$path")
    [[ $mode == 444 ]] || fail "staged artifact mode mismatch: $mode" || return 1
    [[ $owner == root:root ]] || fail "staged artifact owner mismatch: $owner" || return 1
}

STAGER_TEMP_ROOT=''; STAGER_PARENT_CREATED=0
cleanup_stager_temp() {
    [[ -n ${STAGER_TEMP_ROOT:-} ]] && rm -rf -- "$STAGER_TEMP_ROOT"
    if [[ ${STAGER_PARENT_CREATED:-0} -eq 1 && -d $ACCEPTANCE_PARENT ]]; then rmdir --ignore-fail-on-non-empty "$ACCEPTANCE_PARENT" 2>/dev/null || true; fi
}

main() {
    local cmd tmp staged_in_tmp before_sha after_sha
    [[ $# -eq 1 && $1 == '--stage-target-artifact' ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: staging requires root\n' >&2; exit 3; }
    for cmd in awk cat chmod find hostname id install mkdir mktemp mv readlink rm rmdir sha256sum sort stat uname; do
        command -v "$cmd" >/dev/null 2>&1 || { printf 'ERROR: required command missing: %s\n' "$cmd" >&2; exit 4; }
    done
    [[ -f /etc/slackware-version && ! -L /etc/slackware-version ]] || { printf 'ERROR: unsafe Slackware version file\n' >&2; exit 5; }
    [[ -f /proc/sys/kernel/random/boot_id && ! -L /proc/sys/kernel/random/boot_id ]] || { printf 'ERROR: unsafe boot-id file\n' >&2; exit 5; }
    [[ -d $PACKAGE_DATABASE && ! -L $PACKAGE_DATABASE ]] || { printf 'ERROR: unsafe package database\n' >&2; exit 5; }
    validate_runtime_binding || exit 6
    validate_transport_artifact "$TRANSPORT_SOURCE" "$TARGET_FILENAME" "$TARGET_SHA256" || exit 7
    preflight_destination || exit 8
    before_sha=$(file_sha "$TRANSPORT_SOURCE")
    if [[ ! -e $ACCEPTANCE_PARENT && ! -L $ACCEPTANCE_PARENT ]]; then mkdir -m 0755 -- "$ACCEPTANCE_PARENT"; STAGER_PARENT_CREATED=1; fi
    [[ -d $ACCEPTANCE_PARENT && ! -L $ACCEPTANCE_PARENT ]] || { printf 'ERROR: unsafe acceptance parent\n' >&2; exit 9; }
    tmp=$(mktemp -d "$ACCEPTANCE_PARENT/.kernel-package-edge.stage.XXXXXX")
    STAGER_TEMP_ROOT=$tmp; trap cleanup_stager_temp EXIT HUP INT TERM
    mkdir -m 0755 -- "$tmp/staging-input"
    staged_in_tmp="$tmp/staging-input/$TARGET_FILENAME"
    install -o root -g root -m 0444 -- "$TRANSPORT_SOURCE" "$staged_in_tmp"
    verify_staged_target "$staged_in_tmp" "$TARGET_SHA256" || exit 10
    mv -- "$tmp" "$ACCEPTANCE_ROOT"; STAGER_TEMP_ROOT=''
    verify_staged_target "$STAGED_TARGET" "$TARGET_SHA256" || exit 11
    after_sha=$(file_sha "$TRANSPORT_SOURCE")
    [[ $before_sha == "$after_sha" && $after_sha == "$TARGET_SHA256" ]] || { printf 'ERROR: transport source changed during staging\n' >&2; exit 12; }
    printf 'target_artifact_staging_status\tPASS\n'
    printf 'transport_source\t%s\n' "$TRANSPORT_SOURCE"
    printf 'transport_source_preserved\tyes\n'
    printf 'staged_target\t%s\n' "$STAGED_TARGET"
    printf 'staged_target_sha256\t%s\n' "$TARGET_SHA256"
    printf 'staged_target_owner\troot:root\n'
    printf 'staged_target_mode\t0444\n'
    printf 'target_boot_id\t%s\n' "$EXPECTED_BOOT_ID"
    printf 'package_database_manifest_sha256\t%s\n' "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256"
    printf 'network_access_performed\tno\n'
    printf 'repository_refresh_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'slackpkg_configuration_change_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
}

if [[ ${SLACK_UPDATE_TARGET_ARTIFACT_STAGER_LIBRARY_ONLY:-0} == 1 ]]; then
    return 0 2>/dev/null || exit 0
fi
main "$@"
