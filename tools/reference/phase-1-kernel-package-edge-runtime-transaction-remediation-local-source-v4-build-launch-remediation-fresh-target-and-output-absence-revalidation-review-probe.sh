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
readonly EXPECTED_V3_TREE_MANIFEST_SHA256='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
readonly EXPECTED_EMPTY_SHA256='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
readonly EXPECTED_V4_BUILDER_SHA256='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
readonly PACKAGE_DATABASE_COMPAT='/var/log/packages'
readonly PACKAGE_DATABASE='/var/lib/pkgtools/packages'
readonly SLACKPKG_STATE='/var/lib/slackpkg'
readonly SLACKPKG_CONF='/etc/slackpkg/slackpkg.conf'
readonly SLACKPKG_MIRRORS='/etc/slackpkg/mirrors'
readonly GENINITRD_POLICY='/etc/default/geninitrd'
readonly ACCEPTANCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge'
readonly STAGED_TARGET="$ACCEPTANCE_ROOT/staging-input/kernel-headers-6.18.45-x86-1.txz"
readonly LOCAL_SOURCE_V3_ROOT="$ACCEPTANCE_ROOT/local-source-v3"
readonly V3_TREE_MANIFEST="$ACCEPTANCE_ROOT/local-source-v3.tree.sha256"
readonly V3_TREE_MANIFEST_SHA256_FILE="$ACCEPTANCE_ROOT/local-source-v3.tree.sha256.sha256"
readonly FAILED_V2_EVIDENCE_ROOT="$ACCEPTANCE_ROOT/runtime-transaction-remediation-v2"
readonly LOCAL_SOURCE_V4_ROOT="$ACCEPTANCE_ROOT/local-source-v4"
readonly V4_TREE_MANIFEST="$ACCEPTANCE_ROOT/local-source-v4.tree.sha256"
readonly V4_TREE_MANIFEST_SHA256_FILE="$ACCEPTANCE_ROOT/local-source-v4.tree.sha256.sha256"
readonly V4_TEMP_GLOB='.local-source-v4.build.*'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh --observe-v4-launch-remediation-fresh-target-and-output-absence-revalidation
       phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-fresh-target-and-output-absence-revalidation-review-probe.sh --help

Perform one read-only prebuild local-source-v4 revalidation. The probe verifies the
current target baseline, staged target, accepted local-source-v3 tree, preserved failed
runtime-transaction-remediation-v2 evidence, and absence of every local-source-v4 final
or temporary output. It performs no builder execution, Slackpkg refresh, package action,
network access, boot action, reboot, cleanup, or persistent configuration change.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

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
    if ((${#records[@]})); then printf '%s\n' "${records[@]}" | LC_ALL=C sort; fi
}

package_database_manifest_hash() {
    find "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'
}

path_fingerprint() {
    local path=$1 metadata digest target
    if [[ ! -e $path && ! -L $path ]]; then printf 'absent\n'; return 0; fi
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
        find . -xdev -mindepth 1 -printf '%P\0' | LC_ALL=C sort -z |
        while IFS= read -r -d '' rel; do
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

tsv_value() { local file=$1 key=$2; awk -F '\t' -v k="$key" '$1==k {print $2; exit}' "$file"; }

verify_local_source_v3() {
    [[ -d $LOCAL_SOURCE_V3_ROOT && ! -L $LOCAL_SOURCE_V3_ROOT ]] || fail 'accepted local-source-v3 root is missing or unsafe'
    [[ -f $V3_TREE_MANIFEST && ! -L $V3_TREE_MANIFEST ]] || fail 'accepted local-source-v3 tree manifest is missing or unsafe'
    [[ -f $V3_TREE_MANIFEST_SHA256_FILE && ! -L $V3_TREE_MANIFEST_SHA256_FILE ]] || fail 'accepted local-source-v3 manifest sidecar is missing or unsafe'
    [[ $(regular_sha256 "$V3_TREE_MANIFEST") == "$EXPECTED_V3_TREE_MANIFEST_SHA256" ]] || fail 'accepted local-source-v3 tree manifest SHA-256 drift'
    (cd "${V3_TREE_MANIFEST%/*}" && sha256sum -c -- "${V3_TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'accepted local-source-v3 sidecar verification failed'
    (cd "$LOCAL_SOURCE_V3_ROOT" && sha256sum -c -- "$V3_TREE_MANIFEST" >/dev/null) || fail 'accepted local-source-v3 tree verification failed'
}

verify_failed_v2_evidence() {
    local preflight="$FAILED_V2_EVIDENCE_ROOT/preflight.tsv"
    local cleanup="$FAILED_V2_EVIDENCE_ROOT/cleanup.tsv"
    local refresh="$FAILED_V2_EVIDENCE_ROOT/slackpkg-refresh.tsv"
    local update_exit="$FAILED_V2_EVIDENCE_ROOT/slackpkg-update.exit-code"
    local pkglist="$FAILED_V2_EVIDENCE_ROOT/slackpkg-workdir/pkglist"
    local boot_before slackpkg_before geninitrd_before

    [[ -d $FAILED_V2_EVIDENCE_ROOT && ! -L $FAILED_V2_EVIDENCE_ROOT ]] || fail 'failed v2 evidence root is missing or unsafe'
    for path in "$preflight" "$cleanup" "$refresh" "$update_exit" "$FAILED_V2_EVIDENCE_ROOT/slackpkg-update.stdout" "$FAILED_V2_EVIDENCE_ROOT/slackpkg-update.stderr"; do
        [[ -f $path && ! -L $path ]] || fail "failed v2 evidence file missing or unsafe: $path"
    done
    [[ -f $pkglist && ! -L $pkglist ]] || fail 'failed v2 pkglist is missing or unsafe'
    [[ ! -s $pkglist ]] || fail 'failed v2 pkglist is no longer zero bytes'
    [[ $(regular_sha256 "$pkglist") == "$EXPECTED_EMPTY_SHA256" ]] || fail 'failed v2 pkglist SHA-256 drift'
    [[ ! -e "$FAILED_V2_EVIDENCE_ROOT/candidate-binding.tsv" && ! -L "$FAILED_V2_EVIDENCE_ROOT/candidate-binding.tsv" ]] || fail 'failed v2 evidence unexpectedly contains candidate-binding.tsv'
    [[ ! -e "$FAILED_V2_EVIDENCE_ROOT/result.tsv" && ! -L "$FAILED_V2_EVIDENCE_ROOT/result.tsv" ]] || fail 'failed v2 evidence unexpectedly contains result.tsv'
    [[ $(tsv_value "$preflight" preflight_status) == PASS ]] || fail 'failed v2 preflight status drift'
    [[ $(tsv_value "$cleanup" cleanup_triggered) == yes ]] || fail 'failed v2 cleanup status drift'
    [[ $(tsv_value "$cleanup" rollback_header_from) == kernel-headers-6.18.44-x86-1 ]] || fail 'failed v2 rollback source record drift'
    [[ $(tr -d '[:space:]' < "$update_exit") == 0 ]] || fail 'failed v2 Slackpkg update exit code drift'
    [[ $(tsv_value "$refresh" refresh_status) == PASS ]] || fail 'failed v2 refresh status drift'
    [[ $(tsv_value "$refresh" pre_refresh_pkglist_state) == absent ]] || fail 'failed v2 pre-refresh pkglist state drift'
    [[ $(tsv_value "$refresh" post_refresh_pkglist_state) == present-regular ]] || fail 'failed v2 post-refresh pkglist state drift'
    [[ $(tsv_value "$refresh" refreshed_pkglist_sha256) == "$EXPECTED_EMPTY_SHA256" ]] || fail 'failed v2 refresh pkglist SHA-256 drift'
    [[ $(tsv_value "$refresh" human_spaced_error_signal) == absent ]] || fail 'failed v2 human-spaced error signal drift'

    boot_before=$(tsv_value "$preflight" boot_fingerprint)
    slackpkg_before=$(tsv_value "$preflight" slackpkg_state_fingerprint)
    geninitrd_before=$(tsv_value "$preflight" geninitrd_policy_fingerprint)
    [[ -n $boot_before && $(tree_fingerprint /boot) == "$boot_before" ]] || fail '/boot differs from failed v2 preflight fingerprint'
    [[ -n $slackpkg_before && $(tree_fingerprint "$SLACKPKG_STATE") == "$slackpkg_before" ]] || fail 'Slackpkg state differs from failed v2 preflight fingerprint'
    [[ -n $geninitrd_before && $(path_fingerprint "$GENINITRD_POLICY") == "$geninitrd_before" ]] || fail 'GenInitrd policy differs from failed v2 preflight fingerprint'
}

verify_v4_outputs_absent() {
    local roots=()
    for path in "$LOCAL_SOURCE_V4_ROOT" "$V4_TREE_MANIFEST" "$V4_TREE_MANIFEST_SHA256_FILE"; do
        [[ ! -e $path && ! -L $path ]] || fail "local-source-v4 output already exists: $path"
    done
    shopt -s nullglob dotglob
    roots=("$ACCEPTANCE_ROOT"/$V4_TEMP_GLOB)
    shopt -u nullglob dotglob
    ((${#roots[@]} == 0)) || fail 'local-source-v4 temporary build root already exists'
}

main() {
    if [[ ${1:-} == '--help' || ${1:-} == '-h' ]]; then [[ $# -eq 1 ]] || { usage >&2; exit 2; }; usage; exit 0; fi
    [[ $# -eq 1 && $1 == '--observe-v4-launch-remediation-fresh-target-and-output-absence-revalidation' ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'run this read-only probe through sudo/root'

    local cmd boot_id fqdn machine release slackware_version package_manifest header_record generic_record compat_resolved
    local slackpkg_conf_sha slackpkg_mirrors_sha staged_target_sha probe_path probe_sha
    for cmd in awk cat find grep hostname readlink sha256sum sort stat tr uname; do command -v "$cmd" >/dev/null 2>&1 || fail "required command missing: $cmd"; done
    [[ -d $PACKAGE_DATABASE && ! -L $PACKAGE_DATABASE ]] || fail 'canonical package database is missing or unsafe'
    [[ -L $PACKAGE_DATABASE_COMPAT ]] || fail 'compatibility package database path is not a symlink'
    compat_resolved=$(readlink -f -- "$PACKAGE_DATABASE_COMPAT" 2>/dev/null || true)
    [[ $compat_resolved == "$PACKAGE_DATABASE" ]] || fail 'compatibility package database symlink target drift'
    [[ -d $ACCEPTANCE_ROOT && ! -L $ACCEPTANCE_ROOT ]] || fail 'acceptance root is missing or unsafe'

    fqdn=$(hostname -f); machine=$(uname -m); release=$(uname -r); slackware_version=$(cat /etc/slackware-version); boot_id=$(cat /proc/sys/kernel/random/boot_id)
    package_manifest=$(package_database_manifest_hash); header_record=$(package_records kernel-headers); generic_record=$(package_records kernel-generic)
    slackpkg_conf_sha=$(regular_sha256 "$SLACKPKG_CONF"); slackpkg_mirrors_sha=$(regular_sha256 "$SLACKPKG_MIRRORS")

    [[ $fqdn == "$EXPECTED_FQDN" ]] || fail "target FQDN drift: $fqdn"
    [[ $machine == "$EXPECTED_UNAME_MACHINE" ]] || fail "target architecture drift: $machine"
    [[ $release == "$EXPECTED_UNAME_RELEASE" ]] || fail "running kernel drift: $release"
    [[ $slackware_version == "$EXPECTED_SLACKWARE_VERSION" ]] || fail "Slackware release drift: $slackware_version"
    [[ $boot_id =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || fail 'fresh boot ID is not a canonical lowercase UUID'
    [[ $package_manifest == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail "package database manifest drift: $package_manifest"
    [[ $header_record == "$EXPECTED_HEADER_RECORD" ]] || fail "kernel-headers record drift: ${header_record:-<none>}"
    [[ $generic_record == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail "kernel-generic record drift: ${generic_record:-<none>}"
    [[ -z $(package_records kernel-huge) ]] || fail 'kernel-huge unexpectedly installed'
    [[ -z $(package_records kernel-modules) ]] || fail 'kernel-modules unexpectedly installed'
    [[ $slackpkg_conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf fingerprint drift'
    [[ $slackpkg_mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors fingerprint drift'

    staged_target_sha=$(regular_sha256 "$STAGED_TARGET")
    [[ $staged_target_sha == "$EXPECTED_TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
    verify_local_source_v3
    verify_failed_v2_evidence
    verify_v4_outputs_absent

    probe_path=$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")
    probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

    printf 'v4_launch_remediation_fresh_target_and_output_absence_revalidation_status\tPASS\n'
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
    printf 'predecessor_installed_record_absent\tyes\n'
    printf 'slackpkg_conf_sha256\t%s\n' "$slackpkg_conf_sha"
    printf 'slackpkg_mirrors_sha256\t%s\n' "$slackpkg_mirrors_sha"
    printf 'staged_target_sha256\t%s\n' "$staged_target_sha"
    printf 'local_source_v3_tree_verified\tyes\n'
    printf 'local_source_v3_tree_manifest_sha256\t%s\n' "$EXPECTED_V3_TREE_MANIFEST_SHA256"
    printf 'failed_v2_evidence_preserved\tyes\n'
    printf 'failed_v2_pkglist_size_bytes\t0\n'
    printf 'failed_v2_pkglist_sha256\t%s\n' "$EXPECTED_EMPTY_SHA256"
    printf 'failed_v2_candidate_binding_absent\tyes\n'
    printf 'failed_v2_result_absent\tyes\n'
    printf 'boot_artifacts_match_failed_v2_preflight\tyes\n'
    printf 'slackpkg_state_matches_failed_v2_preflight\tyes\n'
    printf 'geninitrd_policy_matches_failed_v2_preflight\tyes\n'
    printf 'local_source_v4_root_absent\tyes\n'
    printf 'local_source_v4_tree_manifest_absent\tyes\n'
    printf 'local_source_v4_tree_manifest_sidecar_absent\tyes\n'
    printf 'local_source_v4_temporary_build_roots_absent\tyes\n'
    printf 'frozen_v4_builder_sha256\t%s\n' "$EXPECTED_V4_BUILDER_SHA256"
    printf 'probe_sha256\t%s\n' "$probe_sha"
    printf 'builder_execution_performed\tno\n'
    printf 'local_source_v4_build_performed\tno\n'
    printf 'slackpkg_refresh_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'network_access_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
    printf 'persistent_configuration_change_performed\tno\n'
    printf 'evidence_cleanup_performed\tno\n'
}

main "$@"
