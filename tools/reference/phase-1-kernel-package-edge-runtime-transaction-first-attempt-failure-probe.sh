#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_KERNEL='6.18.45'
readonly EXPECTED_BOOT_ID='91901677-1dc3-4a39-a4b1-3f87e6875234'
readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'
readonly EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
readonly EXPECTED_TREE_MANIFEST_SHA256='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
readonly EXPECTED_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
readonly EXPECTED_PREDECESSOR_RECORD='kernel-headers-6.18.44-x86-1'
readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'
readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz'
readonly PUBLISHED_SHA256="${PUBLISHED_ARCHIVE}.sha256"
readonly PACKAGE_DATABASE='/var/lib/pkgtools/packages'
readonly SLACKPKG_STATE='/var/lib/slackpkg'
readonly SLACKPKG_CONF='/etc/slackpkg/slackpkg.conf'
readonly SLACKPKG_MIRRORS='/etc/slackpkg/mirrors'
readonly GENINITRD_POLICY='/etc/default/geninitrd'
readonly LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
readonly TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
readonly TREE_MANIFEST_SHA256_FILE='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256'
readonly STAGED_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-probe.sh --observe-failure-cleanup

Read only the failed first runtime transaction evidence and current target state.
No package, Slackpkg, repository, network, boot, configuration, or reboot action is performed.
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
    awk -F '\t' -v key="$key" '$1 == key {print substr($0, length($1)+2); exit}' "$file"
}

verify_local_source_tree() {
    [[ -d $LOCAL_SOURCE_ROOT && ! -L $LOCAL_SOURCE_ROOT ]] || fail 'local source root missing or unsafe'
    [[ -f $TREE_MANIFEST && ! -L $TREE_MANIFEST ]] || fail 'tree manifest missing or unsafe'
    [[ -f $TREE_MANIFEST_SHA256_FILE && ! -L $TREE_MANIFEST_SHA256_FILE ]] || fail 'tree manifest sidecar missing or unsafe'
    [[ $(regular_sha256 "$TREE_MANIFEST") == "$EXPECTED_TREE_MANIFEST_SHA256" ]] || fail 'tree manifest SHA-256 drift'
    (cd "${TREE_MANIFEST%/*}" && sha256sum -c -- "${TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'tree manifest sidecar verification failed'
    (cd "$LOCAL_SOURCE_ROOT" && sha256sum -c -- "$TREE_MANIFEST" >/dev/null) || fail 'local source tree verification failed'
    [[ $(regular_sha256 "$STAGED_TARGET") == "$EXPECTED_TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
}

main() {
    [[ $# -eq 1 && $1 == '--observe-failure-cleanup' ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'run this read-only probe through sudo/root'

    local preflight="$EVIDENCE_ROOT/preflight.tsv"
    local cleanup="$EVIDENCE_ROOT/cleanup.tsv"
    local update_exit="$EVIDENCE_ROOT/slackpkg-update.exit-code"
    local update_stdout="$EVIDENCE_ROOT/slackpkg-update.stdout"
    local update_stderr="$EVIDENCE_ROOT/slackpkg-update.stderr"
    local pkglist="$SLACKPKG_STATE/pkglist"
    local boot_before slackpkg_before geninitrd_before pkglist_rows target_rows update_rc update_error_signal

    [[ -d $EVIDENCE_ROOT && ! -L $EVIDENCE_ROOT ]] || fail 'failed runtime evidence root is missing'
    for path in "$preflight" "$cleanup" "$update_exit" "$update_stdout" "$update_stderr"; do
        [[ -f $path && ! -L $path ]] || fail "expected failed-run evidence is missing or unsafe: $path"
    done
    [[ ! -e $EVIDENCE_ROOT/result.tsv && ! -L $EVIDENCE_ROOT/result.tsv ]] || fail 'failed run unexpectedly contains PASS result.tsv'
    [[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]] || fail 'failed run unexpectedly published success archive'
    [[ ! -e $PUBLISHED_SHA256 && ! -L $PUBLISHED_SHA256 ]] || fail 'failed run unexpectedly published success checksum'

    [[ $(hostname -f) == "$EXPECTED_FQDN" ]] || fail 'target hostname drift after failed transaction'
    [[ $(uname -r) == "$EXPECTED_KERNEL" ]] || fail 'running kernel drift after failed transaction'
    [[ $(cat /proc/sys/kernel/random/boot_id) == "$EXPECTED_BOOT_ID" ]] || fail 'boot ID drift after failed transaction'
    [[ $(package_database_manifest_hash) == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail 'package database was not restored after failed transaction'
    [[ $(package_records kernel-headers) == "$EXPECTED_HEADER_RECORD" ]] || fail 'kernel-headers target was not restored after failed transaction'
    [[ $(package_records kernel-generic) == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail 'kernel-generic record drift after failed transaction'
    [[ -z $(package_records kernel-huge) ]] || fail 'kernel-huge unexpectedly installed after failed transaction'
    [[ -z $(package_records kernel-modules) ]] || fail 'kernel-modules unexpectedly installed after failed transaction'
    [[ $(regular_sha256 "$SLACKPKG_CONF") == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf was not restored exactly'
    [[ $(regular_sha256 "$SLACKPKG_MIRRORS") == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors were not restored exactly'
    verify_local_source_tree

    [[ $(tsv_value "$preflight" preflight_status) == PASS ]] || fail 'failed run did not reach accepted preflight'
    boot_before=$(tsv_value "$preflight" boot_fingerprint)
    slackpkg_before=$(tsv_value "$preflight" slackpkg_state_fingerprint)
    geninitrd_before=$(tsv_value "$preflight" geninitrd_policy_fingerprint)
    [[ -n $boot_before && $(tree_fingerprint /boot) == "$boot_before" ]] || fail '/boot differs from failed-run preflight fingerprint'
    [[ -n $slackpkg_before && $(tree_fingerprint "$SLACKPKG_STATE") == "$slackpkg_before" ]] || fail 'Slackpkg state differs from failed-run preflight fingerprint'
    [[ -n $geninitrd_before && $(path_fingerprint "$GENINITRD_POLICY") == "$geninitrd_before" ]] || fail 'GenInitrd policy differs from failed-run preflight fingerprint'

    grep -Fxq $'cleanup_triggered\tyes' "$cleanup" || fail 'cleanup trap was not recorded as triggered'
    grep -Fxq $'rollback_header_from\t'"$EXPECTED_PREDECESSOR_RECORD" "$cleanup" || fail 'cleanup evidence does not record predecessor-to-target rollback'

    update_rc=$(tr -d '[:space:]' < "$update_exit")
    [[ $update_rc == 0 ]] || fail "unexpected slackpkg update exit code in failed run: $update_rc"
    if grep -Fq 'Error downloading from' "$update_stdout" "$update_stderr"; then
        update_error_signal='error-downloading-from-local-source'
    else
        update_error_signal='not-recorded'
    fi

    [[ -f $pkglist && ! -L $pkglist ]] || fail 'restored Slackpkg pkglist is missing or unsafe'
    pkglist_rows=$(awk 'NF {count++} END {print count+0}' "$pkglist")
    target_rows=$(grep -F -c -- "$EXPECTED_HEADER_RECORD" "$pkglist" || true)
    [[ $pkglist_rows -gt 1 ]] || fail 'restored Slackpkg pkglist does not demonstrate the stale/global-list condition'
    [[ ! -e "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc" && ! -L "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc" ]] || fail 'local source unexpectedly contains CHECKSUMS.md5.asc'

    printf 'failure_characterization_status\tPASS\n'
    printf 'cleanup_triggered\tyes\n'
    printf 'header_restored\tyes\n'
    printf 'package_database_restored\tyes\n'
    printf 'slackpkg_configuration_restored\tyes\n'
    printf 'slackpkg_state_restored\tyes\n'
    printf 'geninitrd_policy_restored\tyes\n'
    printf 'boot_artifacts_unchanged\tyes\n'
    printf 'published_success_evidence_absent\tyes\n'
    printf 'failed_run_slackpkg_update_exit_code\t%s\n' "$update_rc"
    printf 'failed_run_slackpkg_update_error_signal\t%s\n' "$update_error_signal"
    printf 'restored_pkglist_rows\t%s\n' "$pkglist_rows"
    printf 'restored_pkglist_target_rows\t%s\n' "$target_rows"
    printf 'local_source_CHECKSUMS_md5_asc_absent\tyes\n'
    printf 'runtime_rerun_authorized\tno\n'
    printf 'package_action_authorized\tno\n'
    printf 'boot_action_authorized\tno\n'
    printf 'reboot_authorized\tno\n'
}

main "$@"
