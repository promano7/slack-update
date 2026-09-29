#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

readonly EXPECTED_BOOT_ID='d34855ae-e039-4005-a842-1bef51082195'
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
readonly EXPECTED_EXECUTOR_SHA256='f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985'
readonly BUILDER_BASENAME='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh'
readonly EXECUTOR_BASENAME='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh'
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
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-probe.sh --observe-v4-launch-failure-state
       phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-probe.sh --help

Read-only characterization after the step-267 executor passed preflight but failed at
its direct builder launch with Permission denied. This probe does not execute the
builder and does not authorize any rerun.
USAGE
}
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
regular_sha256(){ local p=$1; [[ -f $p && ! -L $p ]] || fail "required regular non-symlink file missing: $p"; sha256sum -- "$p" | awk '{print $1}'; }
package_records(){ local n=$1 c b; local a=(); shopt -s nullglob; for c in "$PACKAGE_DATABASE/$n-"*; do [[ -f $c && ! -L $c ]] || continue; b=${c##*/}; a+=("$b"); done; shopt -u nullglob; ((${#a[@]})) && printf '%s\n' "${a[@]}" | LC_ALL=C sort || true; }
package_database_manifest_hash(){ find "$PACKAGE_DATABASE" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'; }
path_fingerprint(){ local p=$1 m d t; if [[ ! -e $p && ! -L $p ]]; then printf 'absent\n'; return; fi; if [[ -L $p ]]; then m=$(stat -c '%a:%u:%g:%s:%Y' -- "$p"); t=$(readlink -- "$p"); printf 'symlink|%s|%s\n' "$m" "$t" | sha256sum | awk '{print $1}'; elif [[ -f $p ]]; then m=$(stat -c '%a:%u:%g:%s:%Y' -- "$p"); d=$(sha256sum -- "$p"|awk '{print $1}'); printf 'file|%s|%s\n' "$m" "$d"|sha256sum|awk '{print $1}'; else fail "unsupported fingerprint path: $p"; fi; }
tree_fingerprint(){ local root=$1; [[ -d $root && ! -L $root ]] || fail "tree root missing or unsafe: $root"; (cd "$root"; find . -xdev -mindepth 1 -printf '%P\0' | LC_ALL=C sort -z | while IFS= read -r -d '' rel; do if [[ -L $rel ]]; then printf 'L\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(readlink -- "$rel")"; elif [[ -f $rel ]]; then printf 'F\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(sha256sum -- "$rel"|awk '{print $1}')"; elif [[ -d $rel ]]; then printf 'D\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")"; else printf 'O\t%s\t%s\n' "$rel" "$(stat -c '%F:%a:%u:%g:%s:%Y' -- "$rel")"; fi; done) | sha256sum | awk '{print $1}'; }
tsv_value(){ awk -F '\t' -v k="$2" '$1==k {print $2; exit}' "$1"; }
verify_v3(){ [[ -d $LOCAL_SOURCE_V3_ROOT && ! -L $LOCAL_SOURCE_V3_ROOT ]] || fail 'local-source-v3 missing or unsafe'; [[ $(regular_sha256 "$V3_TREE_MANIFEST") == "$EXPECTED_V3_TREE_MANIFEST_SHA256" ]] || fail 'v3 manifest drift'; (cd "${V3_TREE_MANIFEST%/*}" && sha256sum -c -- "${V3_TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'v3 sidecar check failed'; (cd "$LOCAL_SOURCE_V3_ROOT" && sha256sum -c -- "$V3_TREE_MANIFEST" >/dev/null) || fail 'v3 tree check failed'; }
verify_failed_v2(){ local pre="$FAILED_V2_EVIDENCE_ROOT/preflight.tsv" pkg="$FAILED_V2_EVIDENCE_ROOT/slackpkg-workdir/pkglist"; [[ -d $FAILED_V2_EVIDENCE_ROOT && ! -L $FAILED_V2_EVIDENCE_ROOT ]] || fail 'failed-v2 evidence missing'; [[ -f $pkg && ! -L $pkg && ! -s $pkg ]] || fail 'failed-v2 pkglist no longer empty'; [[ $(regular_sha256 "$pkg") == "$EXPECTED_EMPTY_SHA256" ]] || fail 'failed-v2 pkglist drift'; [[ ! -e "$FAILED_V2_EVIDENCE_ROOT/candidate-binding.tsv" && ! -e "$FAILED_V2_EVIDENCE_ROOT/result.tsv" ]] || fail 'failed-v2 later evidence unexpectedly exists'; [[ $(tsv_value "$pre" preflight_status) == PASS ]] || fail 'failed-v2 preflight drift'; [[ $(tree_fingerprint /boot) == "$(tsv_value "$pre" boot_fingerprint)" ]] || fail '/boot drift'; [[ $(tree_fingerprint "$SLACKPKG_STATE") == "$(tsv_value "$pre" slackpkg_state_fingerprint)" ]] || fail 'Slackpkg state drift'; [[ $(path_fingerprint "$GENINITRD_POLICY") == "$(tsv_value "$pre" geninitrd_policy_fingerprint)" ]] || fail 'GenInitrd policy drift'; }
verify_v4_absent(){ local p roots=(); for p in "$LOCAL_SOURCE_V4_ROOT" "$V4_TREE_MANIFEST" "$V4_TREE_MANIFEST_SHA256_FILE"; do [[ ! -e $p && ! -L $p ]] || fail "v4 output exists: $p"; done; shopt -s nullglob dotglob; roots=("$ACCEPTANCE_ROOT"/$V4_TEMP_GLOB); shopt -u nullglob dotglob; ((${#roots[@]}==0)) || fail 'v4 temporary build root exists'; }

main(){
    if [[ ${1:-} == --help || ${1:-} == -h ]]; then [[ $# -eq 1 ]] || { usage >&2; exit 2; }; usage; exit 0; fi
    [[ $# -eq 1 && $1 == --observe-v4-launch-failure-state ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'probe must run through sudo/root'
    local dir builder executor builder_sha executor_sha boot fqdn machine release sv pm hr gr conf mir staged compat builder_mode builder_exec executor_mode
    dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    builder="$dir/$BUILDER_BASENAME"; executor="$dir/$EXECUTOR_BASENAME"
    builder_sha=$(regular_sha256 "$builder"); executor_sha=$(regular_sha256 "$executor")
    [[ $builder_sha == "$EXPECTED_V4_BUILDER_SHA256" ]] || fail 'transported builder SHA-256 mismatch'
    [[ $executor_sha == "$EXPECTED_EXECUTOR_SHA256" ]] || fail 'transported executor SHA-256 mismatch'
    [[ -d $PACKAGE_DATABASE && ! -L $PACKAGE_DATABASE ]] || fail 'package database missing or unsafe'
    [[ -L $PACKAGE_DATABASE_COMPAT ]] || fail 'compatibility package database path is not symlink'
    compat=$(readlink -f -- "$PACKAGE_DATABASE_COMPAT" 2>/dev/null || true); [[ $compat == "$PACKAGE_DATABASE" ]] || fail 'package database compatibility symlink drift'
    boot=$(cat /proc/sys/kernel/random/boot_id); fqdn=$(hostname -f); machine=$(uname -m); release=$(uname -r); sv=$(cat /etc/slackware-version); pm=$(package_database_manifest_hash); hr=$(package_records kernel-headers); gr=$(package_records kernel-generic)
    [[ $boot == "$EXPECTED_BOOT_ID" ]] || fail "boot ID drift: $boot"
    [[ $fqdn == "$EXPECTED_FQDN" && $machine == "$EXPECTED_UNAME_MACHINE" && $release == "$EXPECTED_UNAME_RELEASE" && $sv == "$EXPECTED_SLACKWARE_VERSION" ]] || fail 'target identity drift'
    [[ $pm == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" && $hr == "$EXPECTED_HEADER_RECORD" && $gr == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail 'package baseline drift'
    [[ -z $(package_records kernel-huge) && -z $(package_records kernel-modules) ]] || fail 'unexpected kernel package record'
    conf=$(regular_sha256 "$SLACKPKG_CONF"); mir=$(regular_sha256 "$SLACKPKG_MIRRORS"); staged=$(regular_sha256 "$STAGED_TARGET")
    [[ $conf == "$EXPECTED_SLACKPKG_CONF_SHA256" && $mir == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" && $staged == "$EXPECTED_TARGET_SHA256" ]] || fail 'Slackpkg/staged target drift'
    verify_v3; verify_failed_v2; verify_v4_absent
    builder_mode=$(stat -c '%a' -- "$builder"); executor_mode=$(stat -c '%a' -- "$executor"); if [[ -x $builder ]]; then builder_exec=yes; else builder_exec=no; fi
    printf 'v4_build_launch_failure_characterization_status\tPASS\n'
    printf 'failure_stage\tdirect-builder-launch-before-builder-entry\n'
    printf 'failure_class\tpermission-denied-on-direct-script-exec\n'
    printf 'authorization_boot_id\t%s\n' "$boot"
    printf 'transported_builder_sha256\t%s\n' "$builder_sha"
    printf 'transported_builder_mode\t%s\n' "$builder_mode"
    printf 'transported_builder_executable_bit_visible\t%s\n' "$builder_exec"
    printf 'transported_executor_sha256\t%s\n' "$executor_sha"
    printf 'transported_executor_mode\t%s\n' "$executor_mode"
    printf 'local_source_v4_root_absent\tyes\n'
    printf 'local_source_v4_tree_manifest_absent\tyes\n'
    printf 'local_source_v4_tree_manifest_sidecar_absent\tyes\n'
    printf 'local_source_v4_temporary_build_roots_absent\tyes\n'
    printf 'local_source_v3_tree_verified\tyes\n'
    printf 'failed_v2_evidence_preserved\tyes\n'
    printf 'boot_slackpkg_geninitrd_state_preserved\tyes\n'
    printf 'builder_execution_completed\tno\n'
    printf 'local_source_v4_build_performed\tno\n'
    printf 'authorization_reuse_authorized\tno\n'
    printf 'remediation_candidate\tinvoke-frozen-builder-through-bash-after-new-review-and-authorization\n'
    printf 'probe_side_effects\tnone-read-only\n'
}
main "$@"
