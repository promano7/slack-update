#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_UNAME_MACHINE='x86_64'
readonly EXPECTED_UNAME_RELEASE='6.18.45'
readonly EXPECTED_SLACKWARE_VERSION='Slackware 15.0+'
readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'
readonly EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
readonly FROZEN_PREDECESSOR_ARTIFACT='kernel-headers-6.18.44-x86-1.txz'
readonly FROZEN_PREDECESSOR_SHA256='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
readonly FROZEN_TARGET_ARTIFACT='kernel-headers-6.18.45-x86-1.txz'
readonly FROZEN_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
readonly FROZEN_TREE_MANIFEST_SHA256='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
readonly PACKAGE_DATABASE='/var/log/packages'
readonly PACKAGE_DATABASE_CANONICAL='/var/lib/pkgtools/packages'
readonly ACCEPTANCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge'
readonly STAGED_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'
readonly LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
readonly LOCAL_SOURCE_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source/slackware64/d/kernel-headers-6.18.45-x86-1.txz'
readonly TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
readonly TREE_MANIFEST_SHA256_FILE='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh --observe-post-build-revalidation
       phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh --help

Perform the read-only Phase 1 post-local-source-build revalidation. The probe
observes the fresh target identity and verifies the preserved staged target,
local-source tree, external tree manifest, package state, and Slackpkg
configuration. It performs no repository refresh, network access, package
mutation, boot action, persistent configuration change, or reboot.
USAGE
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

regular_sha256() {
    local path=$1
    [[ -f $path && ! -L $path ]] || fail "required regular non-symlink file missing: $path"
    sha256sum -- "$path" | awk '{print $1}'
}

package_records() {
    local package_name=$1 candidate base
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

check_owner_mode() {
    local path=$1 expected_owner=$2 expected_mode=$3 actual_owner actual_mode
    actual_owner=$(stat -c '%U:%G' -- "$path")
    actual_mode=$(stat -c '%a' -- "$path")
    [[ $actual_owner == "$expected_owner" ]] || fail "owner drift for $path: expected $expected_owner, got $actual_owner"
    [[ $actual_mode == "$expected_mode" ]] || fail "mode drift for $path: expected $expected_mode, got $actual_mode"
}

verify_local_source_tree() {
    local root=$1 manifest=$2 expected_manifest_sha=$3 target=$4 expected_target_sha=$5
    local actual_manifest_sha candidate_count bad_dirs bad_files
    [[ -d $root && ! -L $root ]] || fail "local-source root missing or unsafe: $root"
    [[ -f $manifest && ! -L $manifest ]] || fail "tree manifest missing or unsafe: $manifest"
    actual_manifest_sha=$(sha256sum -- "$manifest" | awk '{print $1}')
    [[ $actual_manifest_sha == "$expected_manifest_sha" ]] || fail "tree-manifest SHA-256 drift"
    (cd "$root" && sha256sum -c -- "$manifest" >/dev/null) || fail "local-source tree does not match bound manifest"
    [[ $(regular_sha256 "$target") == "$expected_target_sha" ]] || fail "local-source target SHA-256 drift"
    candidate_count=$(find "$root" -type f -name '*.txz' -print | wc -l | awk '{print $1}')
    [[ $candidate_count -eq 1 ]] || fail "local source exposes $candidate_count package archives instead of exactly one"
    [[ ! -e "$root/slackware64/d/$FROZEN_PREDECESSOR_ARTIFACT" && ! -L "$root/slackware64/d/$FROZEN_PREDECESSOR_ARTIFACT" ]] || fail 'predecessor unexpectedly present in local source'
    for metadata in ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5; do
        [[ -f "$root/$metadata" && ! -L "$root/$metadata" && -s "$root/$metadata" ]] || fail "required local-source metadata missing or unsafe: $metadata"
    done
    bad_dirs=$(find "$root" -type d \( ! -user root -o ! -group root -o ! -perm 0555 \) -print -quit)
    [[ -z $bad_dirs ]] || fail "local-source directory ownership/mode drift: $bad_dirs"
    bad_files=$(find "$root" -type f \( ! -user root -o ! -group root -o ! -perm 0444 \) -print -quit)
    [[ -z $bad_files ]] || fail "local-source file ownership/mode drift: $bad_files"
}

observe=0
while (($#)); do
    case "$1" in
        --observe-post-build-revalidation)
            [[ $observe -eq 0 ]] || fail 'duplicate --observe-post-build-revalidation'
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

for command_name in awk cat find grep hostname id readlink sha256sum sort stat uname wc; do
    command -v "$command_name" >/dev/null 2>&1 || fail "required command missing: $command_name"
done
for path in /etc/slackware-version /proc/sys/kernel/random/boot_id; do
    [[ -f $path && ! -L $path ]] || fail "required target identity file missing or unsafe: $path"
done
[[ -d $PACKAGE_DATABASE_CANONICAL && ! -L $PACKAGE_DATABASE_CANONICAL ]] || fail "canonical package database missing or unsafe: $PACKAGE_DATABASE_CANONICAL"
[[ -L $PACKAGE_DATABASE ]] || fail "compatibility package database is not the expected symlink: $PACKAGE_DATABASE"
[[ $(readlink -f -- "$PACKAGE_DATABASE" 2>/dev/null || true) == "$PACKAGE_DATABASE_CANONICAL" ]] || fail 'package database symlink target mismatch'
[[ -d $ACCEPTANCE_ROOT && ! -L $ACCEPTANCE_ROOT ]] || fail "acceptance root missing or unsafe: $ACCEPTANCE_ROOT"

fqdn=$(hostname -f 2>/dev/null || true)
hostname_short=$(hostname)
uname_release=$(uname -r)
uname_machine=$(uname -m)
slackware_version=$(cat /etc/slackware-version)
boot_id=$(cat /proc/sys/kernel/random/boot_id)
package_db_manifest_sha=$(manifest_hash "$PACKAGE_DATABASE_CANONICAL")
slackpkg_conf_sha=$(regular_sha256 /etc/slackpkg/slackpkg.conf)
slackpkg_mirrors_sha=$(regular_sha256 /etc/slackpkg/mirrors)

[[ $fqdn == "$EXPECTED_FQDN" ]] || fail "target FQDN drift: $fqdn"
[[ $uname_machine == "$EXPECTED_UNAME_MACHINE" ]] || fail "target architecture drift: $uname_machine"
[[ $uname_release == "$EXPECTED_UNAME_RELEASE" ]] || fail "running kernel drift: $uname_release"
[[ $slackware_version == "$EXPECTED_SLACKWARE_VERSION" ]] || fail "Slackware release drift: $slackware_version"
[[ $package_db_manifest_sha == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail "package database manifest drift: $package_db_manifest_sha"
[[ $slackpkg_conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail "slackpkg.conf fingerprint drift: $slackpkg_conf_sha"
[[ $slackpkg_mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail "slackpkg mirrors fingerprint drift: $slackpkg_mirrors_sha"

header_records=$(package_records kernel-headers)
[[ $header_records == "$EXPECTED_HEADER_RECORD" ]] || fail "kernel-headers record drift: ${header_records:-<none>}"
generic_records=$(package_records kernel-generic)
huge_records=$(package_records kernel-huge)
modules_records=$(package_records kernel-modules)
[[ $generic_records == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail "kernel-generic record drift: ${generic_records:-<none>}"
[[ -z $huge_records ]] || fail "kernel-huge unexpectedly installed: $huge_records"
[[ -z $modules_records ]] || fail "kernel-modules unexpectedly installed: $modules_records"

[[ $(regular_sha256 "$STAGED_TARGET") == "$FROZEN_TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
check_owner_mode "$STAGED_TARGET" 'root:root' '444'
check_owner_mode "$TREE_MANIFEST" 'root:root' '444'
check_owner_mode "$TREE_MANIFEST_SHA256_FILE" 'root:root' '444'
[[ $(regular_sha256 "$TREE_MANIFEST") == "$FROZEN_TREE_MANIFEST_SHA256" ]] || fail 'bound tree-manifest SHA-256 drift'
(cd "${TREE_MANIFEST%/*}" && sha256sum -c -- "${TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'tree-manifest sidecar verification failed'
verify_local_source_tree "$LOCAL_SOURCE_ROOT" "$TREE_MANIFEST" "$FROZEN_TREE_MANIFEST_SHA256" "$LOCAL_SOURCE_TARGET" "$FROZEN_TARGET_SHA256"

probe_path=$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

printf 'revalidation_status\tPASS\n'
printf 'target_hostname\t%s\n' "$hostname_short"
printf 'hostname_fqdn\t%s\n' "$fqdn"
printf 'uname_release\t%s\n' "$uname_release"
printf 'uname_machine\t%s\n' "$uname_machine"
printf 'slackware_version\t%s\n' "$slackware_version"
printf 'fresh_boot_id\t%s\n' "$boot_id"
printf 'package_database_manifest_sha256\t%s\n' "$package_db_manifest_sha"
printf 'header_package_record\t%s\n' "$header_records"
printf 'kernel_generic_record\t%s\n' "$generic_records"
printf 'kernel_huge_absent\tyes\n'
printf 'kernel_modules_absent\tyes\n'
printf 'slackpkg_conf_sha256\t%s\n' "$slackpkg_conf_sha"
printf 'slackpkg_mirrors_sha256\t%s\n' "$slackpkg_mirrors_sha"
printf 'staged_target\t%s\n' "$STAGED_TARGET"
printf 'staged_target_sha256\t%s\n' "$FROZEN_TARGET_SHA256"
printf 'local_source_root\t%s\n' "$LOCAL_SOURCE_ROOT"
printf 'local_source_target_sha256\t%s\n' "$FROZEN_TARGET_SHA256"
printf 'tree_manifest\t%s\n' "$TREE_MANIFEST"
printf 'tree_manifest_sha256\t%s\n' "$FROZEN_TREE_MANIFEST_SHA256"
printf 'tree_manifest_sidecar_verified\tyes\n'
printf 'local_source_tree_verified\tyes\n'
printf 'single_candidate_contract_verified\tyes\n'
printf 'predecessor_excluded_from_local_source\tyes\n'
printf 'frozen_predecessor_artifact\t%s\n' "$FROZEN_PREDECESSOR_ARTIFACT"
printf 'frozen_predecessor_sha256\t%s\n' "$FROZEN_PREDECESSOR_SHA256"
printf 'frozen_target_artifact\t%s\n' "$FROZEN_TARGET_ARTIFACT"
printf 'frozen_target_sha256\t%s\n' "$FROZEN_TARGET_SHA256"
printf 'probe_sha256\t%s\n' "$probe_sha"
printf 'prior_target_binding_reused\tno\n'
printf 'candidate_set_bound\tno\n'
printf 'repository_refresh_performed\tno\n'
printf 'network_access_performed\tno\n'
printf 'package_action_performed\tno\n'
printf 'slackpkg_configuration_change_performed\tno\n'
printf 'boot_action_performed\tno\n'
printf 'persistent_configuration_change_performed\tno\n'
printf 'reboot_performed\tno\n'
