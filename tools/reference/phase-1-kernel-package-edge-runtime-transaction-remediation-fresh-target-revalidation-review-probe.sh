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
readonly EXPECTED_TREE_MANIFEST_SHA256='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
readonly EXPECTED_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
readonly PACKAGE_DATABASE_COMPAT='/var/log/packages'
readonly PACKAGE_DATABASE='/var/lib/pkgtools/packages'
readonly SLACKPKG_STATE='/var/lib/slackpkg'
readonly SLACKPKG_CONF='/etc/slackpkg/slackpkg.conf'
readonly SLACKPKG_MIRRORS='/etc/slackpkg/mirrors'
readonly GENINITRD_POLICY='/etc/default/geninitrd'
readonly LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
readonly TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
readonly TREE_MANIFEST_SHA256_FILE='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256'
readonly STAGED_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'
readonly FAILED_EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'
readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz'
readonly PUBLISHED_SHA256="${PUBLISHED_ARCHIVE}.sha256"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-probe.sh --observe-fresh-target-revalidation
       phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-probe.sh --help

Perform one read-only fresh target observation for the Phase 1 kernel-package-edge
runtime-transaction remediation continuation. The probe validates the restored
post-failure target baseline, preserved local-source v1 and staged target, and
presence of the failed-run evidence. It performs no package, Slackpkg, network,
repository, boot, reboot, or persistent configuration mutation.
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
    for candidate in "$PACKAGE_DATABASE/$package_name-"*; do
        [[ -f $candidate && ! -L $candidate ]] || continue
        base=${candidate##*/}
        records+=("$base")
    done
    shopt -u nullglob
    if ((${#records[@]})); then
        printf '%s\n' "${records[@]}" | LC_ALL=C sort
    fi
}

package_database_manifest_hash() {
    find "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n' \
        | LC_ALL=C sort | sha256sum | awk '{print $1}'
}

path_fingerprint() {
    local path=$1 metadata digest target
    if [[ ! -e $path && ! -L $path ]]; then
        printf 'absent\n'
        return 0
    fi
    if [[ -L $path ]]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path")
        target=$(readlink -- "$path")
        printf 'symlink|%s|%s\n' "$metadata" "$target" | sha256sum | awk '{print $1}'
        return 0
    fi
    if [[ -f $path ]]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path")
        digest=$(sha256sum -- "$path" | awk '{print $1}')
        printf 'file|%s|%s\n' "$metadata" "$digest" | sha256sum | awk '{print $1}'
        return 0
    fi
    fail "unsupported fingerprint path type: $path"
}

tree_fingerprint() {
    local root=$1
    [[ -d $root && ! -L $root ]] || fail "tree fingerprint root missing or unsafe: $root"
    (
        cd "$root"
        find . -xdev -mindepth 1 -printf '%P\0' | LC_ALL=C sort -z \
            | while IFS= read -r -d '' rel; do
                if [[ -L $rel ]]; then
                    printf 'L\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(readlink -- "$rel")"
                elif [[ -f $rel ]]; then
                    printf 'F\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(sha256sum -- "$rel" | awk '{print $1}')"
                elif [[ -d $rel ]]; then
                    printf 'D\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")"
                else
                    printf 'O\t%s\t%s\n' "$rel" "$(stat -c '%F:%a:%u:%g:%s:%Y' -- "$rel")"
                fi
            done
    ) | sha256sum | awk '{print $1}'
}

tsv_value() {
    local file=$1 key=$2 line
    while IFS= read -r line; do
        if [[ $line == "$key"$'\t'* ]]; then
            printf '%s\n' "${line#*$'\t'}"
            return 0
        fi
        if [[ $line == "$key\\t"* ]]; then
            printf '%s\n' "${line#"$key\\t"}"
            return 0
        fi
    done < "$file"
    return 1
}

verify_preserved_local_source_v1() {
    [[ -d $LOCAL_SOURCE_ROOT && ! -L $LOCAL_SOURCE_ROOT ]] || fail 'local-source v1 root is missing or unsafe'
    [[ -f $TREE_MANIFEST && ! -L $TREE_MANIFEST ]] || fail 'local-source v1 tree manifest is missing or unsafe'
    [[ -f $TREE_MANIFEST_SHA256_FILE && ! -L $TREE_MANIFEST_SHA256_FILE ]] || fail 'local-source v1 manifest sidecar is missing or unsafe'
    [[ $(regular_sha256 "$TREE_MANIFEST") == "$EXPECTED_TREE_MANIFEST_SHA256" ]] || fail 'local-source v1 tree manifest SHA-256 drift'
    (cd "${TREE_MANIFEST%/*}" && sha256sum -c -- "${TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'local-source v1 manifest sidecar verification failed'
    (cd "$LOCAL_SOURCE_ROOT" && sha256sum -c -- "$TREE_MANIFEST" >/dev/null) || fail 'local-source v1 tree verification failed'
    [[ ! -e "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc" && ! -L "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc" ]] || fail 'local-source v1 unexpectedly contains CHECKSUMS.md5.asc'
    [[ $(regular_sha256 "$STAGED_TARGET") == "$EXPECTED_TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
}

verify_failed_run_preservation() {
    local preflight="$FAILED_EVIDENCE_ROOT/preflight.tsv"
    local cleanup="$FAILED_EVIDENCE_ROOT/cleanup.tsv"
    local update_exit="$FAILED_EVIDENCE_ROOT/slackpkg-update.exit-code"
    local update_stdout="$FAILED_EVIDENCE_ROOT/slackpkg-update.stdout"
    local update_stderr="$FAILED_EVIDENCE_ROOT/slackpkg-update.stderr"
    local boot_before slackpkg_before geninitrd_before

    [[ -d $FAILED_EVIDENCE_ROOT && ! -L $FAILED_EVIDENCE_ROOT ]] || fail 'failed runtime evidence root is missing or unsafe'
    for path in "$preflight" "$cleanup" "$update_exit" "$update_stdout" "$update_stderr"; do
        [[ -f $path && ! -L $path ]] || fail "expected failed-run evidence is missing or unsafe: $path"
    done
    [[ ! -e "$FAILED_EVIDENCE_ROOT/result.tsv" && ! -L "$FAILED_EVIDENCE_ROOT/result.tsv" ]] || fail 'failed runtime evidence unexpectedly contains result.tsv'
    [[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]] || fail 'failed runtime unexpectedly published success archive'
    [[ ! -e $PUBLISHED_SHA256 && ! -L $PUBLISHED_SHA256 ]] || fail 'failed runtime unexpectedly published success checksum'

    [[ $(tsv_value "$preflight" preflight_status) == PASS ]] || fail 'failed-run preflight status is not PASS'
    boot_before=$(tsv_value "$preflight" boot_fingerprint)
    slackpkg_before=$(tsv_value "$preflight" slackpkg_state_fingerprint)
    geninitrd_before=$(tsv_value "$preflight" geninitrd_policy_fingerprint)
    [[ -n $boot_before && $(tree_fingerprint /boot) == "$boot_before" ]] || fail '/boot differs from the failed-run accepted preflight fingerprint'
    [[ -n $slackpkg_before && $(tree_fingerprint "$SLACKPKG_STATE") == "$slackpkg_before" ]] || fail 'Slackpkg state differs from the failed-run accepted preflight fingerprint'
    [[ -n $geninitrd_before && $(path_fingerprint "$GENINITRD_POLICY") == "$geninitrd_before" ]] || fail 'GenInitrd policy differs from the failed-run accepted preflight fingerprint'
    grep -Fxq $'cleanup_triggered\tyes' "$cleanup" || fail 'failed-run cleanup evidence does not record cleanup_triggered=yes'
}

main() {
    if [[ ${1:-} == '--help' || ${1:-} == '-h' ]]; then
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        usage
        exit 0
    fi
    [[ $# -eq 1 && $1 == '--observe-fresh-target-revalidation' ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'run this read-only probe through sudo/root'

    local boot_id fqdn machine release slackware_version package_manifest header_record generic_record
    local compat_resolved slackpkg_conf_sha slackpkg_mirrors_sha staged_target_sha

    for path in /etc/slackware-version /proc/sys/kernel/random/boot_id; do
        [[ -f $path && ! -L $path ]] || fail "required target identity file missing or unsafe: $path"
    done
    [[ -d $PACKAGE_DATABASE && ! -L $PACKAGE_DATABASE ]] || fail 'canonical package database is missing or unsafe'
    [[ -L $PACKAGE_DATABASE_COMPAT ]] || fail 'compatibility package database path is not a symlink'
    compat_resolved=$(readlink -f -- "$PACKAGE_DATABASE_COMPAT" 2>/dev/null || true)
    [[ $compat_resolved == "$PACKAGE_DATABASE" ]] || fail 'compatibility package database symlink target drift'

    fqdn=$(hostname -f)
    machine=$(uname -m)
    release=$(uname -r)
    slackware_version=$(cat /etc/slackware-version)
    boot_id=$(cat /proc/sys/kernel/random/boot_id)
    package_manifest=$(package_database_manifest_hash)
    header_record=$(package_records kernel-headers)
    generic_record=$(package_records kernel-generic)
    slackpkg_conf_sha=$(regular_sha256 "$SLACKPKG_CONF")
    slackpkg_mirrors_sha=$(regular_sha256 "$SLACKPKG_MIRRORS")

    [[ $fqdn == "$EXPECTED_FQDN" ]] || fail 'target hostname drift'
    [[ $machine == "$EXPECTED_UNAME_MACHINE" ]] || fail 'target architecture drift'
    [[ $release == "$EXPECTED_UNAME_RELEASE" ]] || fail 'running kernel drift'
    [[ $slackware_version == "$EXPECTED_SLACKWARE_VERSION" ]] || fail 'Slackware release drift'
    [[ -n $boot_id ]] || fail 'fresh boot ID observation is empty'
    [[ $package_manifest == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail 'package database manifest drift'
    [[ $header_record == "$EXPECTED_HEADER_RECORD" ]] || fail 'kernel-headers record drift'
    [[ $generic_record == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail 'kernel-generic record drift'
    [[ -z $(package_records kernel-huge) ]] || fail 'kernel-huge unexpectedly installed'
    [[ -z $(package_records kernel-modules) ]] || fail 'kernel-modules unexpectedly installed'
    [[ $slackpkg_conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf fingerprint drift'
    [[ $slackpkg_mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors fingerprint drift'

    verify_preserved_local_source_v1
    verify_failed_run_preservation
    staged_target_sha=$(regular_sha256 "$STAGED_TARGET")

    printf 'revalidation_status\tPASS\n'
    printf 'prior_target_binding_reused\tno\n'
    printf 'fresh_boot_id\t%s\n' "$boot_id"
    printf 'hostname_fqdn\t%s\n' "$fqdn"
    printf 'uname_machine\t%s\n' "$machine"
    printf 'uname_release\t%s\n' "$release"
    printf 'slackware_version\t%s\n' "$slackware_version"
    printf 'package_database_manifest_sha256\t%s\n' "$package_manifest"
    printf 'header_package_record\t%s\n' "$header_record"
    printf 'kernel_generic_record\t%s\n' "$generic_record"
    printf 'kernel_huge_absent\tyes\n'
    printf 'kernel_modules_absent\tyes\n'
    printf 'slackpkg_conf_sha256\t%s\n' "$slackpkg_conf_sha"
    printf 'slackpkg_mirrors_sha256\t%s\n' "$slackpkg_mirrors_sha"
    printf 'staged_target_sha256\t%s\n' "$staged_target_sha"
    printf 'local_source_v1_tree_verified\tyes\n'
    printf 'local_source_v1_tree_manifest_sha256\t%s\n' "$EXPECTED_TREE_MANIFEST_SHA256"
    printf 'local_source_v1_CHECKSUMS_md5_asc_absent\tyes\n'
    printf 'failed_evidence_root_present\tyes\n'
    printf 'failed_success_result_absent\tyes\n'
    printf 'published_success_evidence_absent\tyes\n'
    printf 'boot_artifacts_match_failed_preflight\tyes\n'
    printf 'slackpkg_state_matches_failed_preflight\tyes\n'
    printf 'geninitrd_policy_matches_failed_preflight\tyes\n'
    printf 'repository_refresh_performed\tno\n'
    printf 'network_access_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'slackpkg_mutation_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
    printf 'persistent_configuration_change_performed\tno\n'
    printf 'candidate_set_bound\tno\n'
}

main "$@"
