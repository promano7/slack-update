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
readonly BUILDER_BASENAME='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh'
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
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh --execute-authorized-local-source-v4-build-v2 --authorization-boot-id UUID
       phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh --help

Perform one newly authorized build attempt after full preflight, using the exact
unchanged SHA-bound builder through Bash. UUID must be the fresh boot identity
from the new explicit authorization; no historical default or retry is allowed.
Transport and production execution require a later explicit authorization.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
regular_sha256() { local path=$1; [[ -f $path && ! -L $path ]] || fail "required regular non-symlink file missing: $path"; sha256sum -- "$path" | awk '{print $1}'; }
package_records() {
    local package_name=$1 candidate base
    local records=()
    shopt -s nullglob
    for candidate in "$PACKAGE_DATABASE/$package_name-"*; do
        [[ -f $candidate && ! -L $candidate ]] || continue
        base=${candidate##*/}; records+=("$base")
    done
    shopt -u nullglob
    if ((${#records[@]})); then printf '%s\n' "${records[@]}" | LC_ALL=C sort; fi
}
package_database_manifest_hash() { find "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'; }
path_fingerprint() {
    local path=$1 metadata digest target
    if [[ ! -e $path && ! -L $path ]]; then printf 'absent\n'; return 0; fi
    if [[ -L $path ]]; then metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path"); target=$(readlink -- "$path"); printf 'symlink|%s|%s\n' "$metadata" "$target" | sha256sum | awk '{print $1}'; return 0; fi
    if [[ -f $path ]]; then metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path"); digest=$(sha256sum -- "$path" | awk '{print $1}'); printf 'file|%s|%s\n' "$metadata" "$digest" | sha256sum | awk '{print $1}'; return 0; fi
    fail "unsupported fingerprint path type: $path"
}
tree_fingerprint() {
    local root=$1
    [[ -d $root && ! -L $root ]] || fail "tree fingerprint root missing or unsafe: $root"
    (
        cd "$root"
        find . -xdev -mindepth 1 -printf '%P\0' | LC_ALL=C sort -z |
        while IFS= read -r -d '' rel; do
            if [[ -L $rel ]]; then printf 'L\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(readlink -- "$rel")"
            elif [[ -f $rel ]]; then printf 'F\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(sha256sum -- "$rel" | awk '{print $1}')"
            elif [[ -d $rel ]]; then printf 'D\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")"
            else printf 'O\t%s\t%s\n' "$rel" "$(stat -c '%F:%a:%u:%g:%s:%Y' -- "$rel")"
            fi
        done
    ) | sha256sum | awk '{print $1}'
}
tsv_value() { local file=$1 key=$2; awk -F '\t' -v k="$key" '$1==k {print $2; exit}' "$file"; }
verify_local_source_v3() {
    [[ -d $LOCAL_SOURCE_V3_ROOT && ! -L $LOCAL_SOURCE_V3_ROOT ]] || fail 'accepted local-source-v3 root is missing or unsafe'
    [[ $(regular_sha256 "$V3_TREE_MANIFEST") == "$EXPECTED_V3_TREE_MANIFEST_SHA256" ]] || fail 'accepted local-source-v3 tree manifest SHA-256 drift'
    [[ -f $V3_TREE_MANIFEST_SHA256_FILE && ! -L $V3_TREE_MANIFEST_SHA256_FILE ]] || fail 'accepted local-source-v3 manifest sidecar is missing or unsafe'
    (cd "${V3_TREE_MANIFEST%/*}" && sha256sum -c -- "${V3_TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'accepted local-source-v3 sidecar verification failed'
    (cd "$LOCAL_SOURCE_V3_ROOT" && sha256sum -c -- "$V3_TREE_MANIFEST" >/dev/null) || fail 'accepted local-source-v3 tree verification failed'
}
verify_failed_v2_evidence() {
    local preflight="$FAILED_V2_EVIDENCE_ROOT/preflight.tsv" cleanup="$FAILED_V2_EVIDENCE_ROOT/cleanup.tsv" refresh="$FAILED_V2_EVIDENCE_ROOT/slackpkg-refresh.tsv" update_exit="$FAILED_V2_EVIDENCE_ROOT/slackpkg-update.exit-code" pkglist="$FAILED_V2_EVIDENCE_ROOT/slackpkg-workdir/pkglist"
    local boot_before slackpkg_before geninitrd_before path
    [[ -d $FAILED_V2_EVIDENCE_ROOT && ! -L $FAILED_V2_EVIDENCE_ROOT ]] || fail 'failed v2 evidence root is missing or unsafe'
    for path in "$preflight" "$cleanup" "$refresh" "$update_exit" "$FAILED_V2_EVIDENCE_ROOT/slackpkg-update.stdout" "$FAILED_V2_EVIDENCE_ROOT/slackpkg-update.stderr"; do [[ -f $path && ! -L $path ]] || fail "failed v2 evidence file missing or unsafe: $path"; done
    [[ -f $pkglist && ! -L $pkglist && ! -s $pkglist ]] || fail 'failed v2 pkglist is missing, unsafe, or no longer zero bytes'
    [[ $(regular_sha256 "$pkglist") == "$EXPECTED_EMPTY_SHA256" ]] || fail 'failed v2 pkglist SHA-256 drift'
    [[ ! -e "$FAILED_V2_EVIDENCE_ROOT/candidate-binding.tsv" && ! -L "$FAILED_V2_EVIDENCE_ROOT/candidate-binding.tsv" ]] || fail 'failed v2 candidate binding unexpectedly exists'
    [[ ! -e "$FAILED_V2_EVIDENCE_ROOT/result.tsv" && ! -L "$FAILED_V2_EVIDENCE_ROOT/result.tsv" ]] || fail 'failed v2 result unexpectedly exists'
    [[ $(tsv_value "$preflight" preflight_status) == PASS ]] || fail 'failed v2 preflight status drift'
    [[ $(tsv_value "$cleanup" cleanup_triggered) == yes ]] || fail 'failed v2 cleanup state drift'
    [[ $(tr -d '[:space:]' < "$update_exit") == 0 ]] || fail 'failed v2 Slackpkg update exit code drift'
    [[ $(tsv_value "$refresh" refresh_status) == PASS ]] || fail 'failed v2 refresh state drift'
    [[ $(tsv_value "$refresh" refreshed_pkglist_sha256) == "$EXPECTED_EMPTY_SHA256" ]] || fail 'failed v2 refresh pkglist SHA-256 drift'
    boot_before=$(tsv_value "$preflight" boot_fingerprint); slackpkg_before=$(tsv_value "$preflight" slackpkg_state_fingerprint); geninitrd_before=$(tsv_value "$preflight" geninitrd_policy_fingerprint)
    [[ -n $boot_before && $(tree_fingerprint /boot) == "$boot_before" ]] || fail '/boot differs from failed v2 preflight fingerprint'
    [[ -n $slackpkg_before && $(tree_fingerprint "$SLACKPKG_STATE") == "$slackpkg_before" ]] || fail 'Slackpkg state differs from failed v2 preflight fingerprint'
    [[ -n $geninitrd_before && $(path_fingerprint "$GENINITRD_POLICY") == "$geninitrd_before" ]] || fail 'GenInitrd policy differs from failed v2 preflight fingerprint'
}
verify_v4_outputs_absent() {
    local path roots=()
    for path in "$LOCAL_SOURCE_V4_ROOT" "$V4_TREE_MANIFEST" "$V4_TREE_MANIFEST_SHA256_FILE"; do [[ ! -e $path && ! -L $path ]] || fail "local-source-v4 output already exists: $path"; done
    shopt -s nullglob dotglob; roots=("$ACCEPTANCE_ROOT"/$V4_TEMP_GLOB); shopt -u nullglob dotglob
    ((${#roots[@]} == 0)) || fail 'local-source-v4 temporary build root already exists'
}

parse_authorization_boot_id() {
    [[ $# -eq 3 && $1 == '--execute-authorized-local-source-v4-build-v2' && $2 == '--authorization-boot-id' ]] || { usage >&2; return 2; }
    [[ $3 =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || { printf 'ERROR: authorization boot ID must be a canonical lowercase UUID\n' >&2; return 2; }
    printf '%s\n' "$3"
}

launch_verified_builder() {
    [[ $# -eq 2 ]] || fail 'launch requires a builder path and exact SHA-256'
    local builder=$1 expected_sha256=$2 builder_sha builder_status
    command -v bash >/dev/null 2>&1 || fail 'required command missing: bash'
    builder_sha=$(regular_sha256 "$builder")
    [[ $builder_sha == "$expected_sha256" ]] || fail "authorized builder SHA-256 mismatch at launch: $builder_sha"
    if bash -- "$builder" --build-local-source-v4; then
        builder_status=0
    else
        builder_status=$?
        return "$builder_status"
    fi
    printf 'v4_v2_authorized_build_executor_status\tPASS\n'
    printf 'authorization_consumed\tyes\n'
    printf 'second_execution_authorized\tno\n'
    printf 'slackpkg_refresh_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'network_access_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
}

main() {
    if [[ ${1:-} == '--help' || ${1:-} == '-h' ]]; then [[ $# -eq 1 ]] || { usage >&2; exit 2; }; usage; exit 0; fi
    local authorization_boot_id
    authorization_boot_id=$(parse_authorization_boot_id "$@") || return $?
    [[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'authorized build executor must run through sudo/root'
    local script_dir builder builder_sha boot_id fqdn machine release slackware_version package_manifest header_record generic_record compat_resolved conf_sha mirrors_sha staged_sha cmd
    for cmd in awk bash cat find grep hostname readlink sha256sum sort stat tr uname; do command -v "$cmd" >/dev/null 2>&1 || fail "required command missing: $cmd"; done
    script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    builder="$script_dir/$BUILDER_BASENAME"
    [[ -f $builder && ! -L $builder ]] || fail "authorized builder missing or unsafe: $builder"
    builder_sha=$(sha256sum -- "$builder" | awk '{print $1}')
    [[ $builder_sha == "$EXPECTED_V4_BUILDER_SHA256" ]] || fail "authorized builder SHA-256 mismatch: $builder_sha"
    [[ -d $PACKAGE_DATABASE && ! -L $PACKAGE_DATABASE ]] || fail 'canonical package database is missing or unsafe'
    [[ -L $PACKAGE_DATABASE_COMPAT ]] || fail 'compatibility package database path is not a symlink'
    compat_resolved=$(readlink -f -- "$PACKAGE_DATABASE_COMPAT" 2>/dev/null || true); [[ $compat_resolved == "$PACKAGE_DATABASE" ]] || fail 'compatibility package database symlink target drift'
    [[ -d $ACCEPTANCE_ROOT && ! -L $ACCEPTANCE_ROOT ]] || fail 'acceptance root is missing or unsafe'
    boot_id=$(cat /proc/sys/kernel/random/boot_id); fqdn=$(hostname -f); machine=$(uname -m); release=$(uname -r); slackware_version=$(cat /etc/slackware-version); package_manifest=$(package_database_manifest_hash); header_record=$(package_records kernel-headers); generic_record=$(package_records kernel-generic)
    [[ $boot_id == "$authorization_boot_id" ]] || fail "authorization boot ID mismatch: $boot_id"
    [[ $fqdn == "$EXPECTED_FQDN" ]] || fail "target FQDN drift: $fqdn"
    [[ $machine == "$EXPECTED_UNAME_MACHINE" ]] || fail "target architecture drift: $machine"
    [[ $release == "$EXPECTED_UNAME_RELEASE" ]] || fail "running kernel drift: $release"
    [[ $slackware_version == "$EXPECTED_SLACKWARE_VERSION" ]] || fail "Slackware release drift: $slackware_version"
    [[ $package_manifest == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail "package database manifest drift: $package_manifest"
    [[ $header_record == "$EXPECTED_HEADER_RECORD" ]] || fail "kernel-headers record drift: ${header_record:-<none>}"
    [[ $generic_record == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail "kernel-generic record drift: ${generic_record:-<none>}"
    [[ -z $(package_records kernel-huge) && -z $(package_records kernel-modules) ]] || fail 'unexpected kernel-huge or kernel-modules package record'
    conf_sha=$(regular_sha256 "$SLACKPKG_CONF"); mirrors_sha=$(regular_sha256 "$SLACKPKG_MIRRORS"); staged_sha=$(regular_sha256 "$STAGED_TARGET")
    [[ $conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf fingerprint drift'
    [[ $mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors fingerprint drift'
    [[ $staged_sha == "$EXPECTED_TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
    verify_local_source_v3
    verify_failed_v2_evidence
    verify_v4_outputs_absent
    printf 'v4_v2_authorized_build_preflight_status\tPASS\n'
    printf 'authorization_boot_id\t%s\n' "$boot_id"
    printf 'authorized_builder_sha256\t%s\n' "$builder_sha"
    printf 'authorization_use_count\t1\n'
    printf 'authorized_builder_execution_starting\tyes\n'
    launch_verified_builder "$builder" "$EXPECTED_V4_BUILDER_SHA256"
}
if [[ ${SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY:-0} == 1 ]]; then
    [[ ${BASH_SOURCE[0]} != "$0" ]] || { printf 'ERROR: library-only mode requires sourcing\n' >&2; exit 2; }
else
    main "$@"
fi
