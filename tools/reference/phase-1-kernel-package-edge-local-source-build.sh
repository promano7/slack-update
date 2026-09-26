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
PACKAGE_LOCATION='./slackware64/d'
LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
TREE_MANIFEST_SHA256='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-build.sh --build-local-source

Build the deterministic single-candidate local Slackpkg source for the frozen
Phase 1 kernel-package-edge scenario. Production execution requires root and
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
    [[ $actual == "$expected_sha" ]] || fail "input SHA-256 mismatch" || return 1
}

preflight_output_paths() {
    local source_root=$1 manifest=$2 manifest_sha=$3
    [[ ! -e $source_root && ! -L $source_root ]] || fail "final source path already exists: $source_root" || return 1
    [[ ! -e $manifest && ! -L $manifest ]] || fail "tree manifest already exists: $manifest" || return 1
    [[ ! -e $manifest_sha && ! -L $manifest_sha ]] || fail "tree-manifest SHA-256 already exists: $manifest_sha" || return 1
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

render_source_tree() {
    local input=$1 source_root=$2 scratch_root=$3 expected_sha=$4
    local package_path="$source_root/$TARGET_RELATIVE_PATH"
    local desc="$scratch_root/package-description.txt"
    local raw_desc="$scratch_root/slack-desc.raw"
    local compressed_bytes compressed_kib uncompressed_bytes uncompressed_kib package_md5

    validate_input_file "$input" "$TARGET_FILENAME" "$expected_sha" || return 1
    mkdir -p -- "$source_root/${TARGET_RELATIVE_PATH%/*}" "$scratch_root"
    cp -p -- "$input" "$package_path"
    extract_description "$input" "$desc" "$raw_desc" || return 1

    compressed_bytes=$(stat -c '%s' -- "$input")
    compressed_kib=$(kib_ceil "$compressed_bytes")
    uncompressed_bytes=$(tar --numeric-owner -tvf "$input" | awk '{sum += $3} END {{printf "%.0f\n", sum}}')
    uncompressed_kib=$(kib_ceil "$uncompressed_bytes")
    package_md5=$(md5sum -- "$input" | awk '{print $1}')

    cat > "$source_root/ChangeLog.txt" <<EOF_CHANGELOG
Phase 1 deterministic local source for kernel-package-edge acceptance.
Package: $TARGET_FILENAME
SHA256: $expected_sha
EOF_CHANGELOG

    cat > "$source_root/FILELIST.TXT" <<EOF_FILELIST
./ChangeLog.txt
./FILELIST.TXT
./PACKAGES.TXT
./CHECKSUMS.md5
./$TARGET_RELATIVE_PATH
EOF_FILELIST

    cat > "$source_root/PACKAGES.TXT" <<EOF_PACKAGES
PACKAGE NAME:  $TARGET_FILENAME
PACKAGE LOCATION:  $PACKAGE_LOCATION
PACKAGE SIZE (compressed):  $compressed_kib K
PACKAGE SIZE (uncompressed):  $uncompressed_kib K
PACKAGE DESCRIPTION:
$(cat "$desc")

EOF_PACKAGES

    printf 'MD5 (./%s) = %s\n' "$TARGET_RELATIVE_PATH" "$package_md5" > "$source_root/CHECKSUMS.md5"

    # Normalize generated-tree mtimes so no wall-clock value is embedded.
    find "$source_root" -exec touch -h -d '@0' -- {} +
}

validate_source_tree() {
    local source_root=$1 expected_sha=$2
    local target="$source_root/$TARGET_RELATIVE_PATH" count actual md5
    local metadata

    for metadata in ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5; do
        [[ -f $source_root/$metadata && ! -L $source_root/$metadata && -s $source_root/$metadata ]] \
            || fail "missing or unsafe metadata file: $metadata" || return 1
    done
    require_regular_nonsymlink "$target" || return 1
    actual=$(sha256sum -- "$target" | awk '{print $1}')
    [[ $actual == "$expected_sha" ]] || fail 'generated target package SHA-256 mismatch' || return 1

    count=$(find "$source_root" -type f -name '*.txz' -print | wc -l)
    [[ $count -eq 1 ]] || fail "generated source exposes $count package archives" || return 1
    grep -Fxq "./$TARGET_RELATIVE_PATH" "$source_root/FILELIST.TXT" || fail 'FILELIST.TXT does not expose target package' || return 1
    [[ $(grep -c '^PACKAGE NAME:  ' "$source_root/PACKAGES.TXT") -eq 1 ]] || fail 'PACKAGES.TXT does not contain exactly one stanza' || return 1
    grep -Fxq "PACKAGE NAME:  $TARGET_FILENAME" "$source_root/PACKAGES.TXT" || fail 'PACKAGES.TXT package identity mismatch' || return 1
    grep -Fxq "PACKAGE LOCATION:  $PACKAGE_LOCATION" "$source_root/PACKAGES.TXT" || fail 'PACKAGES.TXT package location mismatch' || return 1
    md5=$(md5sum -- "$target" | awk '{print $1}')
    grep -Fxq "MD5 (./$TARGET_RELATIVE_PATH) = $md5" "$source_root/CHECKSUMS.md5" || fail 'CHECKSUMS.md5 does not bind target package' || return 1
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
    (cd "$source_root" && sha256sum -c -- "$manifest" >/dev/null) || fail 'tree manifest verification failed' || return 1
    (cd "${manifest%/*}" && sha256sum -c -- "${manifest_sha##*/}" >/dev/null) || fail 'tree-manifest SHA-256 verification failed' || return 1
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
    local tmp source scratch tmp_manifest tmp_manifest_sha
    [[ $# -eq 1 && $1 == '--build-local-source' ]] || { usage >&2; exit 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: production build requires root\n' >&2; exit 3; }

    local cmd
    for cmd in awk cat chmod chown cp find grep install md5sum mkdir mktemp mv rm sha256sum sort stat tar touch wc; do
        command -v "$cmd" >/dev/null 2>&1 || { printf 'ERROR: required command missing: %s\n' "$cmd" >&2; exit 4; }
    done

    [[ -d $ACCEPTANCE_ROOT && ! -L $ACCEPTANCE_ROOT ]] || { printf 'ERROR: acceptance root missing or unsafe\n' >&2; exit 5; }
    [[ -d $STAGING_INPUT_ROOT && ! -L $STAGING_INPUT_ROOT ]] || { printf 'ERROR: staging input root missing or unsafe\n' >&2; exit 6; }
    validate_input_file "$TARGET_INPUT" "$TARGET_FILENAME" "$TARGET_SHA256" || exit 7
    preflight_output_paths "$LOCAL_SOURCE_ROOT" "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256" || exit 8

    tmp=$(mktemp -d "$ACCEPTANCE_ROOT/.local-source.build.XXXXXX")
    BUILDER_TEMP_ROOT=$tmp
    trap cleanup_builder_temp EXIT HUP INT TERM
    source="$tmp/source"
    scratch="$tmp/scratch"
    tmp_manifest="$tmp/local-source.tree.sha256"
    tmp_manifest_sha="$tmp/local-source.tree.sha256.sha256"

    render_source_tree "$TARGET_INPUT" "$source" "$scratch" "$TARGET_SHA256" || exit 9
    validate_source_tree "$source" "$TARGET_SHA256" || exit 10
    finalize_source_tree "$source"
    write_tree_manifest "$source" "$tmp_manifest" "$tmp_manifest_sha"
    verify_tree_manifest "$source" "$tmp_manifest" "$tmp_manifest_sha" || exit 11

    mv -- "$source" "$LOCAL_SOURCE_ROOT"
    install -o root -g root -m 0444 -- "$tmp_manifest" "$TREE_MANIFEST"
    install -o root -g root -m 0444 -- "$tmp_manifest_sha" "$TREE_MANIFEST_SHA256"
    verify_tree_manifest "$LOCAL_SOURCE_ROOT" "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256" || exit 12

    printf 'local_source_build_status\tPASS\n'
    printf 'local_source_root\t%s\n' "$LOCAL_SOURCE_ROOT"
    printf 'target_package\t%s\n' "$TARGET_FILENAME"
    printf 'target_sha256\t%s\n' "$TARGET_SHA256"
    printf 'tree_manifest\t%s\n' "$TREE_MANIFEST"
    printf 'tree_manifest_sha256\t%s\n' "$(sha256sum -- "$TREE_MANIFEST" | awk '{print $1}')"
    printf 'network_access_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'slackpkg_configuration_change_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
}

# The repository harness sources functions through this non-production seam.
if [[ ${SLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY:-0} == 1 ]]; then
    return 0 2>/dev/null || exit 0
fi

main "$@"
