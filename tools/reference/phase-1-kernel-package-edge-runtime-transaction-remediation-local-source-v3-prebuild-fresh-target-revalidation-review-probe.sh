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
readonly EXPECTED_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
readonly EXPECTED_V2_TREE_MANIFEST_SHA256='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
readonly EXPECTED_BUILDER_SHA256='56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
readonly PACKAGE_DATABASE_COMPAT='/var/log/packages'
readonly PACKAGE_DATABASE='/var/lib/pkgtools/packages'
readonly SLACKPKG_STATE='/var/lib/slackpkg'
readonly SLACKPKG_CONF='/etc/slackpkg/slackpkg.conf'
readonly SLACKPKG_MIRRORS='/etc/slackpkg/mirrors'
readonly GENINITRD_POLICY='/etc/default/geninitrd'
readonly STAGED_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'
readonly LOCAL_SOURCE_V2_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'
readonly V2_TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256'
readonly V2_TREE_MANIFEST_SHA256_FILE='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256.sha256'
readonly FAILED_EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation'
readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz'
readonly PUBLISHED_SHA256="${PUBLISHED_ARCHIVE}.sha256"
readonly LOCAL_SOURCE_V3_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3'
readonly V3_TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256'
readonly V3_TREE_MANIFEST_SHA256_FILE='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256'
readonly V3_TEMP_PARENT='/var/tmp/slack-update-acceptance/kernel-package-edge'
readonly V3_TEMP_GLOB='.local-source-v3.build.*'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review-probe.sh --observe-prebuild-v3-fresh-target-revalidation
       phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review-probe.sh --help

Perform one read-only target observation immediately before any future local-source-v3
builder transport or execution. The probe revalidates the restored target baseline,
preserved local-source-v2 and failed remediation evidence, staged target bytes, and the
absence of all local-source-v3 final and temporary outputs. It performs no package,
Slackpkg, repository, network, boot, reboot, builder, or persistent configuration action.
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
    local file=$1 key=$2
    awk -F '\t' -v k="$key" '$1==k {print $2; exit}' "$file"
}

verify_preserved_local_source_v2() {
    local compat_asc="$LOCAL_SOURCE_V2_ROOT/CHECKSUMS.md5.asc"
    [[ -d $LOCAL_SOURCE_V2_ROOT && ! -L $LOCAL_SOURCE_V2_ROOT ]] || fail 'local-source-v2 root is missing or unsafe'
    [[ -f $V2_TREE_MANIFEST && ! -L $V2_TREE_MANIFEST ]] || fail 'local-source-v2 tree manifest is missing or unsafe'
    [[ -f $V2_TREE_MANIFEST_SHA256_FILE && ! -L $V2_TREE_MANIFEST_SHA256_FILE ]] || fail 'local-source-v2 manifest sidecar is missing or unsafe'
    [[ $(regular_sha256 "$V2_TREE_MANIFEST") == "$EXPECTED_V2_TREE_MANIFEST_SHA256" ]] || fail 'local-source-v2 tree manifest SHA-256 drift'
    (cd "${V2_TREE_MANIFEST%/*}" && sha256sum -c -- "${V2_TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'local-source-v2 manifest sidecar verification failed'
    (cd "$LOCAL_SOURCE_V2_ROOT" && sha256sum -c -- "$V2_TREE_MANIFEST" >/dev/null) || fail 'local-source-v2 tree verification failed'
    [[ -f $compat_asc && ! -L $compat_asc ]] || fail 'local-source-v2 compatibility asc is missing or unsafe'
    if grep -q 'PGP' "$compat_asc"; then
        fail 'historical local-source-v2 compatibility asc unexpectedly contains PGP marker'
    fi
    [[ $(regular_sha256 "$STAGED_TARGET") == "$EXPECTED_TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
}

verify_failed_remediation_preservation() {
    local preflight="$FAILED_EVIDENCE_ROOT/preflight.tsv"
    local cleanup="$FAILED_EVIDENCE_ROOT/cleanup.tsv"
    local update_exit="$FAILED_EVIDENCE_ROOT/slackpkg-update.exit-code"
    local update_stdout="$FAILED_EVIDENCE_ROOT/slackpkg-update.stdout"
    local update_stderr="$FAILED_EVIDENCE_ROOT/slackpkg-update.stderr"
    local workdir="$FAILED_EVIDENCE_ROOT/slackpkg-workdir"
    local boot_before slackpkg_before geninitrd_before update_rc

    [[ -d $FAILED_EVIDENCE_ROOT && ! -L $FAILED_EVIDENCE_ROOT ]] || fail 'failed remediation evidence root is missing or unsafe'
    [[ -d $workdir && ! -L $workdir ]] || fail 'failed remediation Slackpkg workdir is missing or unsafe'
    for path in "$preflight" "$cleanup" "$update_exit" "$update_stdout" "$update_stderr"; do
        [[ -f $path && ! -L $path ]] || fail "expected failed remediation evidence is missing or unsafe: $path"
    done
    [[ ! -e "$FAILED_EVIDENCE_ROOT/result.tsv" && ! -L "$FAILED_EVIDENCE_ROOT/result.tsv" ]] || fail 'failed remediation evidence unexpectedly contains result.tsv'
    [[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]] || fail 'failed remediation unexpectedly published success archive'
    [[ ! -e $PUBLISHED_SHA256 && ! -L $PUBLISHED_SHA256 ]] || fail 'failed remediation unexpectedly published success checksum'
    [[ ! -e "$workdir/pkglist" && ! -L "$workdir/pkglist" ]] || fail 'failed remediation workdir unexpectedly contains pkglist'

    [[ $(tsv_value "$preflight" preflight_status) == PASS ]] || fail 'failed remediation preflight status is not PASS'
    [[ $(tsv_value "$cleanup" cleanup_triggered) == yes ]] || fail 'failed remediation cleanup evidence does not record cleanup_triggered=yes'
    update_rc=$(tr -d '[:space:]' < "$update_exit")
    [[ $update_rc == 0 ]] || fail 'failed remediation Slackpkg update exit code changed'
    grep -Fqi 'Error downloading from ' "$update_stdout" "$update_stderr" || fail 'failed remediation output no longer contains human-spaced download error'

    boot_before=$(tsv_value "$preflight" boot_fingerprint)
    slackpkg_before=$(tsv_value "$preflight" slackpkg_state_fingerprint)
    geninitrd_before=$(tsv_value "$preflight" geninitrd_policy_fingerprint)
    [[ -n $boot_before && $(tree_fingerprint /boot) == "$boot_before" ]] || fail '/boot differs from failed remediation preflight fingerprint'
    [[ -n $slackpkg_before && $(tree_fingerprint "$SLACKPKG_STATE") == "$slackpkg_before" ]] || fail 'Slackpkg state differs from failed remediation preflight fingerprint'
    [[ -n $geninitrd_before && $(path_fingerprint "$GENINITRD_POLICY") == "$geninitrd_before" ]] || fail 'GenInitrd policy differs from failed remediation preflight fingerprint'
}

verify_v3_absent() {
    local candidate
    for candidate in "$LOCAL_SOURCE_V3_ROOT" "$V3_TREE_MANIFEST" "$V3_TREE_MANIFEST_SHA256_FILE"; do
        [[ ! -e $candidate && ! -L $candidate ]] || fail "prebuild local-source-v3 output already exists: $candidate"
    done
    shopt -s nullglob dotglob
    local temp_roots=("$V3_TEMP_PARENT"/$V3_TEMP_GLOB)
    shopt -u nullglob dotglob
    ((${#temp_roots[@]} == 0)) || fail 'prebuild local-source-v3 temporary build root already exists'
}

main() {
    if [[ ${1:-} == '--help' || ${1:-} == '-h' ]]; then
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        usage
        exit 0
    fi
    [[ $# -eq 1 && $1 == '--observe-prebuild-v3-fresh-target-revalidation' ]] || { usage >&2; exit 2; }
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

    verify_preserved_local_source_v2
    verify_failed_remediation_preservation
    verify_v3_absent
    staged_target_sha=$(regular_sha256 "$STAGED_TARGET")

    printf 'prebuild_v3_revalidation_status\tPASS\n'
    printf 'prior_runtime_binding_reused\tno\n'
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
    printf 'local_source_v2_tree_verified\tyes\n'
    printf 'local_source_v2_tree_manifest_sha256\t%s\n' "$EXPECTED_V2_TREE_MANIFEST_SHA256"
    printf 'local_source_v2_historical_compatibility_asc_without_PGP_preserved\tyes\n'
    printf 'failed_remediation_evidence_root_present\tyes\n'
    printf 'failed_remediation_success_result_absent\tyes\n'
    printf 'published_remediation_success_evidence_absent\tyes\n'
    printf 'failed_remediation_pkglist_absent\tyes\n'
    printf 'failed_remediation_human_error_preserved\tyes\n'
    printf 'boot_artifacts_match_failed_remediation_preflight\tyes\n'
    printf 'slackpkg_state_matches_failed_remediation_preflight\tyes\n'
    printf 'geninitrd_policy_matches_failed_remediation_preflight\tyes\n'
    printf 'local_source_v3_final_outputs_absent\tyes\n'
    printf 'local_source_v3_temporary_build_roots_absent\tyes\n'
    printf 'frozen_builder_sha256\t%s\n' "$EXPECTED_BUILDER_SHA256"
    printf 'builder_transport_performed\tno\n'
    printf 'builder_execution_performed\tno\n'
    printf 'local_source_v3_build_performed\tno\n'
    printf 'runtime_executor_v2_implementation_performed\tno\n'
    printf 'runtime_rerun_performed\tno\n'
    printf 'repository_refresh_performed\tno\n'
    printf 'network_access_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'slackpkg_mutation_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
    printf 'persistent_configuration_change_performed\tno\n'
}

main "$@"
