#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
umask 022

ACCEPTANCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge'
STAGING_INPUT_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input'
TARGET_FILENAME='kernel-headers-6.18.45-x86-1.txz'
TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
TARGET_INPUT='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'
TARGET_RELATIVE_PATH='slackware64/d/kernel-headers-6.18.45-x86-1.txz'
PREDECESSOR_FILENAME='kernel-headers-6.18.44-x86-1.txz'
PACKAGE_LOCATION='./slackware64/d'
LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4'
TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256'
TREE_MANIFEST_SHA256='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256'
PRIORITY_TREES=(patches slackware64 extra pasture testing)

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh --build-local-source-v4

Build the deterministic remediated local Slackpkg source v4 for the frozen
Phase 1 kernel-package-edge target. Production execution requires root and
uses only the frozen /var/tmp paths and target package SHA-256.
USAGE
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    return 1
}

require_regular_nonsymlink() {
    local path=$1
    [[ -f $path && ! -L $path ]] || fail "required regular non-symlink file missing: $path"
}

validate_input_file() {
    local input=$1 expected_filename=$2 expected_sha=$3 actual
    require_regular_nonsymlink "$input" || return 1
    [[ ${input##*/} == "$expected_filename" ]] || fail "input filename mismatch: ${input##*/}" || return 1
    actual=$(sha256sum -- "$input" | awk '{print $1}')
    [[ $actual == "$expected_sha" ]] || fail 'input SHA-256 mismatch' || return 1
}

preflight_output_paths() {
    local source_root=$1 manifest=$2 manifest_sha=$3
    [[ ! -e $source_root && ! -L $source_root ]] || fail "final v4 source path already exists: $source_root" || return 1
    [[ ! -e $manifest && ! -L $manifest ]] || fail "v4 tree manifest already exists: $manifest" || return 1
    [[ ! -e $manifest_sha && ! -L $manifest_sha ]] || fail "v4 tree-manifest SHA-256 already exists: $manifest_sha" || return 1
}

kib_ceil() {
    local bytes=$1
    printf '%d\n' $(( (bytes + 1023) / 1024 ))
}

extract_description() {
    local input=$1 output=$2 raw=$3
    if tar -xOf "$input" install/slack-desc > "$raw" 2>/dev/null; then
        :
    elif tar -xOf "$input" ./install/slack-desc > "$raw" 2>/dev/null; then
        :
    else
        fail 'cannot extract install/slack-desc'
        return 1
    fi
    grep '^kernel-headers:' "$raw" > "$output" || fail 'install/slack-desc has no kernel-headers description lines' || return 1
    [[ -s $output ]] || fail 'package description is empty'
}

write_package_stanza() {
    local output=$1 compressed_kib=$2 uncompressed_kib=$3 desc=$4
    cat > "$output" <<EOF_STANZA
PACKAGE NAME:  $TARGET_FILENAME
PACKAGE LOCATION:  $PACKAGE_LOCATION
PACKAGE SIZE (compressed):  $compressed_kib K
PACKAGE SIZE (uncompressed):  $uncompressed_kib K
PACKAGE DESCRIPTION:
$(cat "$desc")

EOF_STANZA
}

write_filelist() {
    local source_root=$1 output=$2 rel
    : > "$output"
    while IFS= read -r -d '' rel; do
        printf '%s\n' "$rel" >> "$output"
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)
}

write_checksums_md5() {
    local source_root=$1 output=$2 rel
    : > "$output"
    while IFS= read -r -d '' rel; do
        case "$rel" in
            ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;;
        esac
        (cd "$source_root" && md5sum -- "$rel") >> "$output"
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)
}

render_source_tree() {
    local input=$1 source_root=$2 scratch_root=$3 expected_sha=$4
    local package_path="$source_root/$TARGET_RELATIVE_PATH"
    local desc="$scratch_root/package-description.txt"
    local raw_desc="$scratch_root/slack-desc.raw"
    local compressed_bytes compressed_kib uncompressed_bytes uncompressed_kib tree

    validate_input_file "$input" "$TARGET_FILENAME" "$expected_sha" || return 1
    mkdir -p -- "$source_root/${TARGET_RELATIVE_PATH%/*}" "$scratch_root"
    for tree in "${PRIORITY_TREES[@]}"; do
        mkdir -p -- "$source_root/$tree"
    done
    cp -- "$input" "$package_path"
    extract_description "$input" "$desc" "$raw_desc" || return 1

    compressed_bytes=$(stat -c '%s' -- "$input")
    compressed_kib=$(kib_ceil "$compressed_bytes")
    uncompressed_bytes=$(tar --numeric-owner -tvf "$input" | awk '{sum += $3} END {printf "%.0f\n", sum}')
    uncompressed_kib=$(kib_ceil "$uncompressed_bytes")

    cat > "$source_root/ChangeLog.txt" <<EOF_CHANGELOG
Phase 1 deterministic remediated local source v4 for kernel-package-edge acceptance.
Package: $TARGET_FILENAME
SHA256: $expected_sha
EOF_CHANGELOG

    write_package_stanza "$source_root/PACKAGES.TXT" "$compressed_kib" "$uncompressed_kib" "$desc"
    write_package_stanza "$source_root/slackware64/PACKAGES.TXT" "$compressed_kib" "$uncompressed_kib" "$desc"
    for tree in patches extra pasture testing; do
        : > "$source_root/$tree/PACKAGES.TXT"
    done

    cat > "$source_root/CHECKSUMS.md5.asc" <<'EOF_ASC'
slack-update local-source-v4 Slackpkg compatibility artifact
PGP compatibility marker for Slackpkg checkchangelog only.
No cryptographic authenticity claim is made by this file.
This file is not an OpenPGP signature and MUST NOT be treated as one.
Package authenticity is bound by the frozen SHA-256 and external v4 tree manifest.
EOF_ASC

    # Create the checksum path before enumerating the complete generated tree.
    : > "$source_root/CHECKSUMS.md5"
    write_filelist "$source_root" "$source_root/FILELIST.TXT"
    write_checksums_md5 "$source_root" "$source_root/CHECKSUMS.md5"

    # Normalize all generated mtimes so no wall-clock value is embedded.
    find "$source_root" -exec touch -h -d '@0' -- {} +
}

validate_source_tree() {
    local source_root=$1 expected_sha=$2
    local target="$source_root/$TARGET_RELATIVE_PATH" actual count tree rel expected_count checksum_count md5
    local metadata

    for metadata in ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5 CHECKSUMS.md5.asc; do
        [[ -f $source_root/$metadata && ! -L $source_root/$metadata ]] || fail "missing or unsafe top-level metadata file: $metadata" || return 1
    done
    for metadata in ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5 CHECKSUMS.md5.asc; do
        [[ -s $source_root/$metadata ]] || fail "top-level metadata file is empty: $metadata" || return 1
    done
    for tree in "${PRIORITY_TREES[@]}"; do
        [[ -f $source_root/$tree/PACKAGES.TXT && ! -L $source_root/$tree/PACKAGES.TXT ]] || fail "missing or unsafe priority PACKAGES.TXT: $tree" || return 1
    done

    require_regular_nonsymlink "$target" || return 1
    actual=$(sha256sum -- "$target" | awk '{print $1}')
    [[ $actual == "$expected_sha" ]] || fail 'generated target package SHA-256 mismatch' || return 1
    [[ ! -e $source_root/slackware64/d/$PREDECESSOR_FILENAME && ! -L $source_root/slackware64/d/$PREDECESSOR_FILENAME ]] || fail 'predecessor package must be absent from v4' || return 1

    count=$(find "$source_root" -type f -name '*.txz' -print | wc -l)
    [[ $count -eq 1 ]] || fail "generated v4 source exposes $count package archives" || return 1
    [[ $(grep -c '^PACKAGE NAME:  ' "$source_root/PACKAGES.TXT") -eq 1 ]] || fail 'top-level PACKAGES.TXT does not contain exactly one stanza' || return 1
    [[ $(grep -c '^PACKAGE NAME:  ' "$source_root/slackware64/PACKAGES.TXT") -eq 1 ]] || fail 'slackware64/PACKAGES.TXT does not contain exactly one stanza' || return 1
    grep -Fxq "PACKAGE NAME:  $TARGET_FILENAME" "$source_root/PACKAGES.TXT" || fail 'top-level package identity mismatch' || return 1
    grep -Fxq "PACKAGE NAME:  $TARGET_FILENAME" "$source_root/slackware64/PACKAGES.TXT" || fail 'slackware64 package identity mismatch' || return 1
    grep -Fxq "PACKAGE LOCATION:  $PACKAGE_LOCATION" "$source_root/PACKAGES.TXT" || fail 'top-level package location mismatch' || return 1
    grep -Fxq "PACKAGE LOCATION:  $PACKAGE_LOCATION" "$source_root/slackware64/PACKAGES.TXT" || fail 'slackware64 package location mismatch' || return 1
    cmp -s "$source_root/PACKAGES.TXT" "$source_root/slackware64/PACKAGES.TXT" || fail 'top-level and slackware64 target stanzas differ' || return 1
    for tree in patches extra pasture testing; do
        [[ $(grep -c '^PACKAGE NAME:  ' "$source_root/$tree/PACKAGES.TXT" || true) -eq 0 ]] || fail "$tree/PACKAGES.TXT exposes a package stanza" || return 1
    done

    expected_count=$(find "$source_root" -type f | wc -l)
    [[ $(wc -l < "$source_root/FILELIST.TXT") -eq $expected_count ]] || fail 'FILELIST.TXT does not enumerate every regular file exactly once' || return 1
    while IFS= read -r -d '' rel; do
        grep -Fxq "$rel" "$source_root/FILELIST.TXT" || fail "FILELIST.TXT missing generated file: $rel" || return 1
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)

    expected_count=$(( expected_count - 2 ))
    checksum_count=$(wc -l < "$source_root/CHECKSUMS.md5")
    [[ $checksum_count -eq $expected_count ]] || fail 'CHECKSUMS.md5 does not bind exactly the required generated regular files' || return 1
    [[ $(grep -c '^MD5 (' "$source_root/CHECKSUMS.md5" || true) -eq 0 ]] || fail 'CHECKSUMS.md5 contains forbidden tagged MD5 records' || return 1
    while IFS= read -r -d '' rel; do
        case "$rel" in
            ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;;
        esac
        md5=$(cd "$source_root" && md5sum -- "$rel" | awk '{print $1}')
        [[ $(grep -Fxc "$md5  $rel" "$source_root/CHECKSUMS.md5" || true) -eq 1 ]] || fail "CHECKSUMS.md5 missing, duplicate, or malformed binding: $rel" || return 1
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)

    grep -Fxq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$source_root/CHECKSUMS.md5.asc" || fail 'compatibility asc PGP marker is missing or altered' || return 1
    grep -Fq 'No cryptographic authenticity claim is made by this file.' "$source_root/CHECKSUMS.md5.asc" || fail 'compatibility asc role is not explicit' || return 1
    ! grep -Fq 'BEGIN PGP SIGNATURE' "$source_root/CHECKSUMS.md5.asc" || fail 'compatibility asc must not impersonate an upstream signature' || return 1
}

write_tree_manifest() {
    local source_root=$1 manifest=$2 manifest_sha=$3 rel
    : > "$manifest"
    while IFS= read -r -d '' rel; do
        (cd "$source_root" && sha256sum -- "$rel") >> "$manifest"
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)
    (cd "${manifest%/*}" && sha256sum -- "${manifest##*/}") > "$manifest_sha"
}

verify_tree_manifest() {
    local source_root=$1 manifest=$2 manifest_sha=$3
    (cd "$source_root" && sha256sum -c -- "$manifest" >/dev/null) || fail 'v4 tree manifest verification failed' || return 1
    (cd "${manifest%/*}" && sha256sum -c -- "${manifest_sha##*/}" >/dev/null) || fail 'v4 tree-manifest SHA-256 verification failed' || return 1
}

finalize_source_tree() {
    local source_root=$1
    chown -R root:root -- "$source_root"
    find "$source_root" -type d -exec chmod 0555 -- {} +
    find "$source_root" -type f -exec chmod 0444 -- {} +
}

BUILDER_TEMP_ROOT=''
cleanup_builder_temp() {
    if [[ -n ${BUILDER_TEMP_ROOT:-} ]]; then
        rm -rf -- "$BUILDER_TEMP_ROOT"
    fi
}

main() {
    local tmp source scratch tmp_manifest tmp_manifest_sha cmd
    [[ $# -eq 1 && $1 == '--build-local-source-v4' ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: production v4 build requires root\n' >&2; exit 3; }

    for cmd in awk cat chmod chown cmp cp find grep md5sum mkdir mktemp mv rm sha256sum sort stat tar touch wc; do
        command -v "$cmd" >/dev/null 2>&1 || { printf 'ERROR: required command missing: %s\n' "$cmd" >&2; exit 4; }
    done

    [[ -d $ACCEPTANCE_ROOT && ! -L $ACCEPTANCE_ROOT ]] || { printf 'ERROR: acceptance root missing or unsafe\n' >&2; exit 5; }
    [[ -d $STAGING_INPUT_ROOT && ! -L $STAGING_INPUT_ROOT ]] || { printf 'ERROR: staging input root missing or unsafe\n' >&2; exit 6; }
    validate_input_file "$TARGET_INPUT" "$TARGET_FILENAME" "$TARGET_SHA256" || exit 7
    preflight_output_paths "$LOCAL_SOURCE_ROOT" "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256" || exit 8

    tmp=$(mktemp -d "$ACCEPTANCE_ROOT/.local-source-v4.build.XXXXXX")
    BUILDER_TEMP_ROOT=$tmp
    trap cleanup_builder_temp EXIT HUP INT TERM
    source="$tmp/source"
    scratch="$tmp/scratch"
    tmp_manifest="$tmp/local-source-v4.tree.sha256"
    tmp_manifest_sha="$tmp/local-source-v4.tree.sha256.sha256"

    render_source_tree "$TARGET_INPUT" "$source" "$scratch" "$TARGET_SHA256" || exit 9
    validate_source_tree "$source" "$TARGET_SHA256" || exit 10
    finalize_source_tree "$source"
    write_tree_manifest "$source" "$tmp_manifest" "$tmp_manifest_sha"
    verify_tree_manifest "$source" "$tmp_manifest" "$tmp_manifest_sha" || exit 11

    mv -- "$source" "$LOCAL_SOURCE_ROOT"
    cp -- "$tmp_manifest" "$TREE_MANIFEST"
    cp -- "$tmp_manifest_sha" "$TREE_MANIFEST_SHA256"
    chown root:root -- "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256"
    chmod 0444 -- "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256"
    touch -h -d '@0' -- "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256"
    verify_tree_manifest "$LOCAL_SOURCE_ROOT" "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256" || exit 12

    printf 'local_source_v4_build_status\tPASS\n'
    printf 'local_source_v4_root\t%s\n' "$LOCAL_SOURCE_ROOT"
    printf 'target_package\t%s\n' "$TARGET_FILENAME"
    printf 'target_sha256\t%s\n' "$TARGET_SHA256"
    printf 'priority_trees\tpatches,slackware64,extra,pasture,testing\n'
    printf 'compatibility_asc_present\tyes\n'
    printf 'compatibility_asc_PGP_marker_present\tyes\n'
    printf 'tree_manifest\t%s\n' "$TREE_MANIFEST"
    printf 'tree_manifest_sha256\t%s\n' "$(sha256sum -- "$TREE_MANIFEST" | awk '{print $1}')"
    printf 'network_access_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'slackpkg_configuration_change_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
}

# The repository harness sources functions through this non-production seam.
if [[ ${SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY:-0} == 1 ]]; then
    return 0 2>/dev/null || exit 0
fi

[[ ${1:-} == '--help' || ${1:-} == '-h' ]] && { usage; exit 0; }
main "$@"
