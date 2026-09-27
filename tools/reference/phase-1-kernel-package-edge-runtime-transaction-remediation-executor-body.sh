readonly PUBLISHED_OWNER='promano:users'
readonly PUBLISHED_MODE='0600'
readonly GENINITRD_POLICY='/etc/default/geninitrd'
readonly SLACKPKG_CONF='/etc/slackpkg/slackpkg.conf'
readonly SLACKPKG_MIRRORS='/etc/slackpkg/mirrors'
readonly SLACKPKG_STATE='/var/lib/slackpkg'
readonly PACKAGE_DATABASE='/var/log/packages'
readonly PACKAGE_DATABASE_CANONICAL='/var/lib/pkgtools/packages'
readonly LOCAL_SOURCE_TARGET="$LOCAL_SOURCE_ROOT/slackware64/d/$TARGET_ARTIFACT"
readonly TREE_MANIFEST_SHA256_FILE="${TREE_MANIFEST}.sha256"

SELF=$(readlink -f -- "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")
RUN_DIR=
BACKUP_ROOT=
REFERENCE_FILE=
SOURCE_CONFIG=
DERIVED_CONFIG=
PRE_PACKAGE_NAMES=
BOOT_FINGERPRINT_BEFORE=
SLACKPKG_STATE_FINGERPRINT_BEFORE=
GENINITRD_FINGERPRINT_BEFORE=
SLACKPKG_WORKDIR=
SLACKPKG_CACHE=
BACKUP_READY=0
MUTATION_STARTED=0
RESTORATION_COMPLETE=0
CLEANUP_RUNNING=0

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh --execute-runtime-remediation-validation
       phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh --help

Run the remediated bounded Phase 1 kernel-package-edge runtime transaction.
The executor revalidates the exact frozen target and local-source-v2, temporarily
stages kernel-headers 6.18.44, creates transaction-owned Slackpkg WORKDIR/TEMP
state, binds exactly the frozen 6.18.45 target candidate, runs the frozen
reference apply without external network interfaces, and restores the accepted
baseline before publishing evidence. A Git repository is not required on the VM.
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

package_database_manifest_hash() {
    find "$PACKAGE_DATABASE_CANONICAL" -maxdepth 1 -type f -printf '%f\n' \
        | LC_ALL=C sort | sha256sum | awk '{print $1}'
}

capture_package_names() {
    local output=$1
    find "$PACKAGE_DATABASE_CANONICAL" -maxdepth 1 -type f -printf '%f\n' \
        | LC_ALL=C sort > "$output"
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

check_owner_mode() {
    local path=$1 expected_owner=$2 expected_mode=$3 actual_owner actual_mode
    actual_owner=$(stat -c '%U:%G' -- "$path")
    actual_mode=$(stat -c '%a' -- "$path")
    [[ $actual_owner == "$expected_owner" ]] || fail "owner drift for $path: expected $expected_owner, got $actual_owner"
    [[ $actual_mode == "$expected_mode" ]] || fail "mode drift for $path: expected $expected_mode, got $actual_mode"
}

verify_v2_manifest_coverage() {
    local actual_paths manifest_paths
    actual_paths=$(cd "$LOCAL_SOURCE_ROOT" && find . -type f -printf '%p\n' | LC_ALL=C sort)
    manifest_paths=$(awk '{print $2}' "$TREE_MANIFEST" | LC_ALL=C sort)
    [[ $actual_paths == "$manifest_paths" ]] || fail 'local-source-v2 regular-file set differs from frozen tree manifest'
}

verify_local_source_tree() {
    local actual_dirs expected_dirs candidate_count expected_count checksum_count rel md5 tree bad_dirs bad_files bad_symlink bad_other
    [[ -d $LOCAL_SOURCE_ROOT && ! -L $LOCAL_SOURCE_ROOT ]] || fail 'local-source-v2 root is missing or unsafe'
    [[ -f $TREE_MANIFEST && ! -L $TREE_MANIFEST ]] || fail 'local-source-v2 tree manifest is missing or unsafe'
    [[ -f $TREE_MANIFEST_SHA256_FILE && ! -L $TREE_MANIFEST_SHA256_FILE ]] || fail 'local-source-v2 manifest sidecar is missing or unsafe'
    [[ $(regular_sha256 "$TREE_MANIFEST") == "$EXPECTED_TREE_MANIFEST_SHA256" ]] || fail 'local-source-v2 tree-manifest SHA-256 drift'
    check_owner_mode "$TREE_MANIFEST" 'root:root' '444'
    check_owner_mode "$TREE_MANIFEST_SHA256_FILE" 'root:root' '444'
    (cd "${TREE_MANIFEST%/*}" && sha256sum -c -- "${TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'local-source-v2 manifest sidecar verification failed'
    (cd "$LOCAL_SOURCE_ROOT" && sha256sum -c -- "$TREE_MANIFEST" >/dev/null) || fail 'local-source-v2 tree verification failed'

    bad_symlink=$(find "$LOCAL_SOURCE_ROOT" -type l -print -quit)
    [[ -z $bad_symlink ]] || fail "local-source-v2 contains unexpected symlink: $bad_symlink"
    bad_other=$(find "$LOCAL_SOURCE_ROOT" -mindepth 1 ! -type d ! -type f -print -quit)
    [[ -z $bad_other ]] || fail "local-source-v2 contains unsupported filesystem object: $bad_other"
    actual_dirs=$(cd "$LOCAL_SOURCE_ROOT" && find . -type d -printf '%p\n' | LC_ALL=C sort)
    expected_dirs=$'.\n./extra\n./pasture\n./patches\n./slackware64\n./slackware64/d\n./testing'
    [[ $actual_dirs == "$expected_dirs" ]] || fail 'local-source-v2 directory set differs from frozen design'
    bad_dirs=$(find "$LOCAL_SOURCE_ROOT" -type d \( ! -user root -o ! -group root -o ! -perm 0555 \) -print -quit)
    [[ -z $bad_dirs ]] || fail "local-source-v2 directory ownership/mode drift: $bad_dirs"
    bad_files=$(find "$LOCAL_SOURCE_ROOT" -type f \( ! -user root -o ! -group root -o ! -perm 0444 \) -print -quit)
    [[ -z $bad_files ]] || fail "local-source-v2 file ownership/mode drift: $bad_files"

    verify_v2_manifest_coverage
    [[ $(regular_sha256 "$LOCAL_SOURCE_TARGET") == "$TARGET_SHA256" ]] || fail 'local-source-v2 target SHA-256 drift'
    candidate_count=$(find "$LOCAL_SOURCE_ROOT" -type f -name '*.txz' -print | wc -l | awk '{print $1}')
    [[ $candidate_count -eq 1 ]] || fail "local-source-v2 exposes $candidate_count package archives instead of exactly one"
    [[ ! -e "$LOCAL_SOURCE_ROOT/slackware64/d/$PREDECESSOR_ARTIFACT" && ! -L "$LOCAL_SOURCE_ROOT/slackware64/d/$PREDECESSOR_ARTIFACT" ]] || fail 'local-source-v2 unexpectedly contains predecessor package'

    for rel in ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5 CHECKSUMS.md5.asc; do
        [[ -f "$LOCAL_SOURCE_ROOT/$rel" && ! -L "$LOCAL_SOURCE_ROOT/$rel" && -s "$LOCAL_SOURCE_ROOT/$rel" ]] || fail "required local-source-v2 metadata missing, unsafe, or empty: $rel"
    done
    for tree in patches slackware64 extra pasture testing; do
        [[ -f "$LOCAL_SOURCE_ROOT/$tree/PACKAGES.TXT" && ! -L "$LOCAL_SOURCE_ROOT/$tree/PACKAGES.TXT" ]] || fail "priority PACKAGES.TXT missing or unsafe: $tree"
    done
    [[ $(grep -c '^PACKAGE NAME:  ' "$LOCAL_SOURCE_ROOT/PACKAGES.TXT") -eq 1 ]] || fail 'top-level PACKAGES.TXT does not contain exactly one package stanza'
    [[ $(grep -c '^PACKAGE NAME:  ' "$LOCAL_SOURCE_ROOT/slackware64/PACKAGES.TXT") -eq 1 ]] || fail 'slackware64/PACKAGES.TXT does not contain exactly one package stanza'
    grep -Fxq "PACKAGE NAME:  $TARGET_ARTIFACT" "$LOCAL_SOURCE_ROOT/PACKAGES.TXT" || fail 'top-level target package identity mismatch'
    grep -Fxq "PACKAGE NAME:  $TARGET_ARTIFACT" "$LOCAL_SOURCE_ROOT/slackware64/PACKAGES.TXT" || fail 'slackware64 target package identity mismatch'
    grep -Fxq "PACKAGE LOCATION:  $TARGET_LOCATION" "$LOCAL_SOURCE_ROOT/PACKAGES.TXT" || fail 'top-level target package location mismatch'
    grep -Fxq "PACKAGE LOCATION:  $TARGET_LOCATION" "$LOCAL_SOURCE_ROOT/slackware64/PACKAGES.TXT" || fail 'slackware64 target package location mismatch'
    cmp -s "$LOCAL_SOURCE_ROOT/PACKAGES.TXT" "$LOCAL_SOURCE_ROOT/slackware64/PACKAGES.TXT" || fail 'top-level and slackware64 package stanzas differ'
    for tree in patches extra pasture testing; do
        [[ $(grep -c '^PACKAGE NAME:  ' "$LOCAL_SOURCE_ROOT/$tree/PACKAGES.TXT" || true) -eq 0 ]] || fail "$tree/PACKAGES.TXT exposes an unexpected package stanza"
    done

    expected_count=$(find "$LOCAL_SOURCE_ROOT" -type f | wc -l | awk '{print $1}')
    [[ $expected_count -eq 11 ]] || fail "local-source-v2 contains $expected_count regular files instead of exactly 11"
    [[ $(wc -l < "$LOCAL_SOURCE_ROOT/FILELIST.TXT") -eq $expected_count ]] || fail 'FILELIST.TXT does not enumerate every regular file exactly once'
    while IFS= read -r -d '' rel; do
        grep -Fxq "$rel" "$LOCAL_SOURCE_ROOT/FILELIST.TXT" || fail "FILELIST.TXT missing generated file: $rel"
    done < <(cd "$LOCAL_SOURCE_ROOT" && find . -type f -print0 | LC_ALL=C sort -z)

    checksum_count=$(grep -c '^MD5 (' "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5" || true)
    [[ $checksum_count -eq 9 ]] || fail 'CHECKSUMS.md5 does not contain the expected nine bindings'
    while IFS= read -r -d '' rel; do
        case "$rel" in
            ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;;
        esac
        md5=$(cd "$LOCAL_SOURCE_ROOT" && md5sum -- "$rel" | awk '{print $1}')
        grep -Fxq "MD5 ($rel) = $md5" "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5" || fail "CHECKSUMS.md5 missing binding: $rel"
    done < <(cd "$LOCAL_SOURCE_ROOT" && find . -type f -print0 | LC_ALL=C sort -z)

    grep -Fq 'No cryptographic authenticity claim is made by this file.' "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc" || fail 'compatibility asc role statement is missing'
    ! grep -Fq 'BEGIN PGP SIGNATURE' "$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc" || fail 'compatibility asc unexpectedly impersonates an upstream signature'
}

verify_preserved_inputs() {
    [[ -d $LOCAL_SOURCE_V1_ROOT && ! -L $LOCAL_SOURCE_V1_ROOT ]] || fail 'preserved local-source v1 root is missing or unsafe'
    [[ -f $LOCAL_SOURCE_V1_MANIFEST && ! -L $LOCAL_SOURCE_V1_MANIFEST ]] || fail 'preserved local-source v1 manifest is missing or unsafe'
    [[ $(regular_sha256 "$LOCAL_SOURCE_V1_MANIFEST") == "$EXPECTED_LOCAL_SOURCE_V1_MANIFEST_SHA256" ]] || fail 'preserved local-source v1 manifest SHA-256 drift'
    [[ -d $FAILED_EVIDENCE_ROOT && ! -L $FAILED_EVIDENCE_ROOT ]] || fail 'historical failed runtime evidence root is missing or unsafe'
    [[ ! -e "$FAILED_EVIDENCE_ROOT/result.tsv" && ! -L "$FAILED_EVIDENCE_ROOT/result.tsv" ]] || fail 'historical failed runtime evidence unexpectedly contains success result'
    [[ ! -e $FAILED_PUBLISHED_ARCHIVE && ! -L $FAILED_PUBLISHED_ARCHIVE ]] || fail 'historical failed run unexpectedly published success archive'
    [[ ! -e $FAILED_PUBLISHED_SHA256 && ! -L $FAILED_PUBLISHED_SHA256 ]] || fail 'historical failed run unexpectedly published success checksum'
}

extract_payload() {
    local kind=$1 destination=$2 begin end
    case "$kind" in
        reference)
            begin='__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__'
            end='__SLACK_UPDATE_REFERENCE_PAYLOAD_END__'
            ;;
        config)
            begin='__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__'
            end='__SLACK_UPDATE_CONFIG_PAYLOAD_END__'
            ;;
        *) return 2 ;;
    esac
    awk -v begin="$begin" -v end="$end" '
        $0 == begin { inside=1; next }
        $0 == end { inside=0; exit }
        inside { print }
    ' "$SELF" | base64 -d > "$destination"
}

derive_runtime_config() {
    local source=$1 destination=$2
    awk -v work_dir="$RUN_DIR/work" -v log_dir="$RUN_DIR/log" -v lock_file="$RUN_DIR/slack-update.lock" '
        /^\[[^]]+\]$/ {
            section=$0
            gsub(/^\[|\]$/, "", section)
            print
            next
        }
        section == "core" && /^work_dir=/ { print "work_dir=" work_dir; seen_work=1; next }
        section == "core" && /^log_dir=/ { print "log_dir=" log_dir; seen_log=1; next }
        section == "core" && /^lock_file=/ { print "lock_file=" lock_file; seen_lock=1; next }
        section == "flatpak" && /^mode=/ { print "mode=disabled"; seen_flatpak=1; next }
        section == "sbo" && /^mode=/ { print "mode=disabled"; seen_sbo=1; next }
        section == "elf" && /^mode=/ { print "mode=disabled"; seen_elf=1; next }
        section == "cinnamon" && /^mode=/ { print "mode=disabled"; seen_cinnamon=1; next }
        { print }
        END {
            if (!(seen_work && seen_log && seen_lock && seen_flatpak && seen_sbo && seen_elf && seen_cinnamon)) exit 42
        }
    ' "$source" > "$destination" || fail 'cannot derive bounded runtime configuration'
    chmod 0600 -- "$destination"
}

record_kv() {
    local file=$1 key=$2 value=$3
    printf '%s\t%s\n' "$key" "$value" >> "$file"
}

verify_target_identity() {
    local fqdn uname_release boot_id package_manifest header_records generic_records huge_records modules_records
    fqdn=$(hostname -f 2>/dev/null || true)
    uname_release=$(uname -r)
    boot_id=$(cat /proc/sys/kernel/random/boot_id)
    package_manifest=$(package_database_manifest_hash)
    header_records=$(package_records kernel-headers)
    generic_records=$(package_records kernel-generic)
    huge_records=$(package_records kernel-huge)
    modules_records=$(package_records kernel-modules)

    [[ $fqdn == "$EXPECTED_FQDN" ]] || fail "target FQDN drift: $fqdn"
    [[ $uname_release == "$EXPECTED_KERNEL" ]] || fail "running kernel drift: $uname_release"
    [[ $boot_id == "$EXPECTED_BOOT_ID" ]] || fail "boot ID drift: $boot_id"
    [[ $package_manifest == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail "package database manifest drift: $package_manifest"
    [[ $header_records == "$TARGET_RECORD" ]] || fail "kernel-headers record drift: ${header_records:-<none>}"
    [[ $generic_records == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail "kernel-generic record drift: ${generic_records:-<none>}"
    [[ -z $huge_records ]] || fail "kernel-huge unexpectedly installed: $huge_records"
    [[ -z $modules_records ]] || fail "kernel-modules unexpectedly installed: $modules_records"
    [[ $(regular_sha256 "$SLACKPKG_CONF") == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf fingerprint drift'
    [[ $(regular_sha256 "$SLACKPKG_MIRRORS") == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors fingerprint drift'
    [[ $(regular_sha256 "$STAGED_TARGET") == "$TARGET_SHA256" ]] || fail 'staged target SHA-256 drift'
    check_owner_mode "$STAGED_TARGET" 'root:root' '444'
    check_owner_mode "$TREE_MANIFEST" 'root:root' '444'
    check_owner_mode "$TREE_MANIFEST_SHA256_FILE" 'root:root' '444'
    verify_local_source_tree
}

backup_mutable_state() {
    BACKUP_ROOT="$RUN_DIR/backup"
    mkdir -m 0700 -- "$BACKUP_ROOT"
    cp -a -- "$SLACKPKG_CONF" "$BACKUP_ROOT/slackpkg.conf"
    cp -a -- "$SLACKPKG_MIRRORS" "$BACKUP_ROOT/mirrors"
    cp -a -- "$SLACKPKG_STATE" "$BACKUP_ROOT/slackpkg-state"
    if [[ -e $GENINITRD_POLICY || -L $GENINITRD_POLICY ]]; then
        [[ -f $GENINITRD_POLICY && ! -L $GENINITRD_POLICY ]] || fail "unsafe GenInitrd policy path: $GENINITRD_POLICY"
        cp -a -- "$GENINITRD_POLICY" "$BACKUP_ROOT/geninitrd"
        printf 'present\n' > "$BACKUP_ROOT/geninitrd.state"
    else
        printf 'absent\n' > "$BACKUP_ROOT/geninitrd.state"
    fi
    BACKUP_READY=1
}

restore_target_header() {
    local current
    current=$(package_records kernel-headers)
    if [[ $current == "$TARGET_RECORD" ]]; then
        return 0
    fi
    printf 'rollback_header_from\t%s\n' "${current:-<none>}" >> "$RUN_DIR/cleanup.tsv"
    upgradepkg --install-new "$STAGED_TARGET" >> "$RUN_DIR/cleanup.stdout" 2>> "$RUN_DIR/cleanup.stderr" || return 1
    current=$(package_records kernel-headers)
    [[ $current == "$TARGET_RECORD" ]]
}

restore_slackpkg_state() {
    [[ $BACKUP_READY -eq 1 ]] || return 1
    rm -f -- "$SLACKPKG_CONF" "$SLACKPKG_MIRRORS"
    cp -a -- "$BACKUP_ROOT/slackpkg.conf" "$SLACKPKG_CONF"
    cp -a -- "$BACKUP_ROOT/mirrors" "$SLACKPKG_MIRRORS"
    rm -rf -- "$SLACKPKG_STATE"
    cp -a -- "$BACKUP_ROOT/slackpkg-state" "$SLACKPKG_STATE"
}

restore_geninitrd_policy() {
    [[ $BACKUP_READY -eq 1 ]] || return 1
    case "$(cat "$BACKUP_ROOT/geninitrd.state")" in
        present)
            rm -f -- "$GENINITRD_POLICY"
            cp -a -- "$BACKUP_ROOT/geninitrd" "$GENINITRD_POLICY"
            ;;
        absent)
            rm -f -- "$GENINITRD_POLICY"
            ;;
        *) return 1 ;;
    esac
}

restore_transaction_state() {
    local rc=0
    [[ $BACKUP_READY -eq 1 ]] || return 1
    restore_target_header || rc=1
    restore_slackpkg_state || rc=1
    restore_geninitrd_policy || rc=1
    return "$rc"
}

cleanup_on_exit() {
    local rc=$?
    local cleanup_rc=0
    if [[ $CLEANUP_RUNNING -eq 1 ]]; then
        exit "$rc"
    fi
    CLEANUP_RUNNING=1
    trap - EXIT HUP INT TERM
    if [[ $MUTATION_STARTED -eq 1 && $RESTORATION_COMPLETE -eq 0 ]]; then
        printf 'cleanup_triggered\tyes\n' >> "${RUN_DIR:-/tmp}/cleanup.tsv" 2>/dev/null || true
        restore_transaction_state || cleanup_rc=1
    fi
    if [[ $cleanup_rc -ne 0 ]]; then
        printf 'ERROR: rollback cleanup did not complete successfully\n' >&2
        rc=1
    fi
    exit "$rc"
}

handle_signal() {
    local name=$1 code=$2
    printf 'ERROR: received %s during runtime transaction\n' "$name" >&2
    exit "$code"
}

configure_temporary_slackpkg() {
    local tmp_conf="$RUN_DIR/slackpkg.conf.tmp"
    SLACKPKG_WORKDIR="$RUN_DIR/slackpkg-workdir"
    SLACKPKG_CACHE="$RUN_DIR/slackpkg-cache"
    install -d -m 0700 -o root -g root -- "$SLACKPKG_WORKDIR" "$SLACKPKG_CACHE"
    [[ -z $(find "$SLACKPKG_WORKDIR" -mindepth 1 -print -quit) ]] || fail 'transaction Slackpkg WORKDIR did not start empty'
    [[ ! -e "$SLACKPKG_WORKDIR/pkglist" && ! -L "$SLACKPKG_WORKDIR/pkglist" ]] || fail 'transaction pkglist exists before refresh'

    awk -v workdir="$SLACKPKG_WORKDIR" -v temp="$SLACKPKG_CACHE" '
        /^[[:space:]]*CHECKGPG[[:space:]]*=/ { print "CHECKGPG=off"; seen_gpg=1; next }
        /^[[:space:]]*WORKDIR[[:space:]]*=/ { print "WORKDIR=" workdir; seen_workdir=1; next }
        /^[[:space:]]*TEMP[[:space:]]*=/ { print "TEMP=" temp; seen_temp=1; next }
        { print }
        END { if (!(seen_gpg && seen_workdir && seen_temp)) exit 42 }
    ' "$SLACKPKG_CONF" > "$tmp_conf" || fail 'cannot derive isolated temporary slackpkg.conf'
    cat "$tmp_conf" > "$SLACKPKG_CONF"
    printf '%s\n' "$LOCAL_SOURCE_URI" > "$SLACKPKG_MIRRORS"
    rm -f -- "$tmp_conf"

    : > "$RUN_DIR/temporary-slackpkg.tsv"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" slackpkg_conf_sha256 "$(sha256sum "$SLACKPKG_CONF" | awk '{print $1}')"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" mirrors_sha256 "$(sha256sum "$SLACKPKG_MIRRORS" | awk '{print $1}')"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" mirror "$LOCAL_SOURCE_URI"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" checkgpg off
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" workdir "$SLACKPKG_WORKDIR"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" temp "$SLACKPKG_CACHE"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" pre_refresh_pkglist_state absent
}

verify_header_only_staging_delta() {
    local after="$RUN_DIR/package-names-after-staging.txt"
    capture_package_names "$after"
    python3 - "$PRE_PACKAGE_NAMES" "$after" "$TARGET_RECORD" "$PREDECESSOR_RECORD" <<'PYEMBED'
import sys
before=set(open(sys.argv[1],encoding='utf-8').read().splitlines())
after=set(open(sys.argv[2],encoding='utf-8').read().splitlines())
target=sys.argv[3]
predecessor=sys.argv[4]
removed=before-after
added=after-before
if removed != {target} or added != {predecessor}:
    raise SystemExit(f'unexpected package delta: removed={sorted(removed)!r} added={sorted(added)!r}')
PYEMBED
    [[ $(uname -r) == "$EXPECTED_KERNEL" ]] || fail 'running kernel changed during header staging'
    [[ $(cat /proc/sys/kernel/random/boot_id) == "$EXPECTED_BOOT_ID" ]] || fail 'boot ID changed during header staging'
    [[ $(package_records kernel-generic) == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail 'kernel-generic record changed during header staging'
    [[ -z $(package_records kernel-huge) ]] || fail 'kernel-huge appeared during header staging'
    [[ -z $(package_records kernel-modules) ]] || fail 'kernel-modules appeared during header staging'
    [[ $(tree_fingerprint /boot) == "$BOOT_FINGERPRINT_BEFORE" ]] || fail 'boot artifacts changed during header staging'
}

run_local_metadata_refresh() {
    local rc=0 pkglist="$SLACKPKG_WORKDIR/pkglist"
    verify_local_source_tree
    [[ ! -e $pkglist && ! -L $pkglist ]] || fail 'transaction pkglist exists before local refresh'
    unshare -n -- cat /proc/net/dev > "$RUN_DIR/network-namespace.txt"
    unshare -n -- slackpkg -batch=on -default_answer=y update \
        > "$RUN_DIR/slackpkg-update.stdout" 2> "$RUN_DIR/slackpkg-update.stderr" || rc=$?
    printf '%s\n' "$rc" > "$RUN_DIR/slackpkg-update.exit-code"
    [[ $rc -eq 0 ]] || fail "local slackpkg metadata refresh failed with exit code $rc"
    if grep -Fqi 'error-downloading-from-local-source' "$RUN_DIR/slackpkg-update.stdout" "$RUN_DIR/slackpkg-update.stderr"; then
        fail 'local Slackpkg metadata refresh emitted error-downloading-from-local-source'
    fi
    [[ -f $pkglist && ! -L $pkglist ]] || fail 'fresh transaction-owned Slackpkg pkglist is missing or unsafe'
    : > "$RUN_DIR/slackpkg-refresh.tsv"
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" refresh_status PASS
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" exit_code "$rc"
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" local_source_error_signal absent
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" workdir "$SLACKPKG_WORKDIR"
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" cache "$SLACKPKG_CACHE"
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" pre_refresh_pkglist_state absent
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" post_refresh_pkglist_state present-regular
    record_kv "$RUN_DIR/slackpkg-refresh.tsv" refreshed_pkglist_sha256 "$(sha256sum "$pkglist" | awk '{print $1}')"
}

bind_candidate_set() {
    local pkglist="$SLACKPKG_WORKDIR/pkglist"
    local target_count=0 install_new_count=0 non_header_upgrade_count=0 configured_boot_upgrade_count=0 unexpected_header_count=0
    local dir name version arch release fullname path ext extra installed source_package
    [[ -f $pkglist && ! -L $pkglist ]] || fail 'fresh transaction-owned Slackpkg pkglist is missing or unsafe'
    [[ $(package_records kernel-headers) == "$PREDECESSOR_RECORD" ]] || fail 'candidate binding did not start from frozen predecessor record'
    verify_local_source_tree

    while IFS=' ' read -r dir name version arch release fullname path ext extra; do
        [[ -n ${dir:-} ]] || continue
        [[ -z ${extra:-} ]] || fail 'fresh pkglist row contains unexpected extra fields'
        if [[ $dir == "$TARGET_PRIORITY_TREE" && $name == "$TARGET_NAME" && $version == "$TARGET_VERSION" && $arch == "$TARGET_ARCH" && $release == "$TARGET_BUILD" && $fullname == "$TARGET_RECORD" && $path == "$TARGET_LOCATION" && $ext == txz ]]; then
            target_count=$((target_count+1))
            continue
        fi

        source_package="$LOCAL_SOURCE_ROOT/${path#./}/$fullname.$ext"
        [[ -f $source_package && ! -L $source_package ]] || continue
        if [[ $name == "$TARGET_NAME" ]]; then
            unexpected_header_count=$((unexpected_header_count+1))
            continue
        fi
        installed=$(package_records "$name")
        if [[ -z $installed ]]; then
            install_new_count=$((install_new_count+1))
        elif [[ $name == kernel-generic || $name == kernel-huge || $name == kernel-modules ]]; then
            configured_boot_upgrade_count=$((configured_boot_upgrade_count+1))
        else
            non_header_upgrade_count=$((non_header_upgrade_count+1))
        fi
    done < "$pkglist"

    [[ $target_count -eq 1 ]] || fail "fresh pkglist exposes $target_count exact target candidates instead of one"
    [[ $unexpected_header_count -eq 0 ]] || fail "fresh pkglist exposes $unexpected_header_count unexpected kernel-headers candidates"
    [[ $install_new_count -eq 0 ]] || fail "fresh pkglist exposes $install_new_count install-new candidates"
    [[ $non_header_upgrade_count -eq 0 ]] || fail "fresh pkglist exposes $non_header_upgrade_count non-header upgrade candidates"
    [[ $configured_boot_upgrade_count -eq 0 ]] || fail "fresh pkglist exposes $configured_boot_upgrade_count configured boot-package upgrade candidates"
    [[ $(regular_sha256 "$LOCAL_SOURCE_TARGET") == "$TARGET_SHA256" ]] || fail 'candidate source target bytes drifted before binding'

    : > "$RUN_DIR/candidate-binding.tsv"
    record_kv "$RUN_DIR/candidate-binding.tsv" binding_status PASS
    record_kv "$RUN_DIR/candidate-binding.tsv" binding_lifetime same-runtime-transaction-only
    record_kv "$RUN_DIR/candidate-binding.tsv" candidate_guard_scope target-specific
    record_kv "$RUN_DIR/candidate-binding.tsv" target_candidate_count "$target_count"
    record_kv "$RUN_DIR/candidate-binding.tsv" target_candidate_fullname "$TARGET_RECORD"
    record_kv "$RUN_DIR/candidate-binding.tsv" target_candidate_location "$TARGET_LOCATION"
    record_kv "$RUN_DIR/candidate-binding.tsv" target_candidate_priority_tree "$TARGET_PRIORITY_TREE"
    record_kv "$RUN_DIR/candidate-binding.tsv" install_new_count "$install_new_count"
    record_kv "$RUN_DIR/candidate-binding.tsv" non_header_upgrade_count "$non_header_upgrade_count"
    record_kv "$RUN_DIR/candidate-binding.tsv" configured_boot_upgrade_count "$configured_boot_upgrade_count"
    record_kv "$RUN_DIR/candidate-binding.tsv" refreshed_pkglist_sha256 "$(sha256sum "$pkglist" | awk '{print $1}')"
    record_kv "$RUN_DIR/candidate-binding.tsv" target_sha256 "$TARGET_SHA256"
    record_kv "$RUN_DIR/candidate-binding.tsv" local_source_v2_tree_manifest_sha256 "$EXPECTED_TREE_MANIFEST_SHA256"
}

validate_reference_result() {
    local json=$1 stderr_file=$2
    python3 - "$json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['operation']=='apply'
assert p['success'] is True
assert p['partial'] is False
assert p['exit_code']==0
assert p['modules']['slackware']['kernel_changes'] is True
for module in ('flatpak','sbo','elf','cinnamon'):
    assert p['modules'][module]['mode']=='disabled'
boot=p['modules']['boot']
assert boot['grub_command_attempted'] is False
assert boot['grub_config_replaced'] is False
assert boot['initrd_state'] not in ('success','failed','blocked')
assert boot['grub_state'] not in ('success','failed','blocked')
PY
    grep -Fq 'puede requerir recompilacion de modulos externos' "$stderr_file" || fail 'reference output did not contain the required external-module header warning'
}

run_reference_apply() {
    local rc=0
    unshare -n -- env SLACK_UPDATE_CONFIG="$DERIVED_CONFIG" bash "$REFERENCE_FILE" --apply --json \
        > "$RUN_DIR/reference-result.json" 2> "$RUN_DIR/reference.stderr" || rc=$?
    printf '%s\n' "$rc" > "$RUN_DIR/reference.exit-code"
    [[ $rc -eq 0 ]] || fail "reference apply failed with exit code $rc"
    validate_reference_result "$RUN_DIR/reference-result.json" "$RUN_DIR/reference.stderr"
}

verify_final_invariants() {
    [[ $(package_records kernel-headers) == "$TARGET_RECORD" ]] || fail 'final kernel-headers record is not the frozen target'
    [[ $(package_database_manifest_hash) == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail 'final package database manifest differs from frozen baseline'
    [[ $(uname -r) == "$EXPECTED_KERNEL" ]] || fail 'final running kernel drift'
    [[ $(cat /proc/sys/kernel/random/boot_id) == "$EXPECTED_BOOT_ID" ]] || fail 'final boot ID drift'
    [[ $(package_records kernel-generic) == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail 'final kernel-generic record drift'
    [[ -z $(package_records kernel-huge) ]] || fail 'kernel-huge unexpectedly installed at final gate'
    [[ -z $(package_records kernel-modules) ]] || fail 'kernel-modules unexpectedly installed at final gate'
    [[ $(tree_fingerprint /boot) == "$BOOT_FINGERPRINT_BEFORE" ]] || fail 'final boot artifact fingerprint differs from baseline'
    [[ $(regular_sha256 "$SLACKPKG_CONF") == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf was not restored exactly'
    [[ $(regular_sha256 "$SLACKPKG_MIRRORS") == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors were not restored exactly'
    [[ $(tree_fingerprint "$SLACKPKG_STATE") == "$SLACKPKG_STATE_FINGERPRINT_BEFORE" ]] || fail 'Slackpkg state tree was not restored exactly'
    [[ $(path_fingerprint "$GENINITRD_POLICY") == "$GENINITRD_FINGERPRINT_BEFORE" ]] || fail 'GenInitrd policy was not restored exactly'
    [[ $(regular_sha256 "$STAGED_TARGET") == "$TARGET_SHA256" ]] || fail 'staged target bytes changed during transaction'
    verify_local_source_tree
    verify_preserved_inputs
}

publish_evidence() {
    local tmp_archive="${PUBLISHED_ARCHIVE}.tmp.$$"
    local archive_sha
    rm -rf -- "$BACKUP_ROOT"
    BACKUP_ROOT=
    : > "$RUN_DIR/result.tsv"
    record_kv "$RUN_DIR/result.tsv" runtime_remediation_validation_status PASS
    record_kv "$RUN_DIR/result.tsv" final_header_record "$TARGET_RECORD"
    record_kv "$RUN_DIR/result.tsv" package_database_manifest_sha256 "$(package_database_manifest_hash)"
    record_kv "$RUN_DIR/result.tsv" boot_id "$(cat /proc/sys/kernel/random/boot_id)"
    record_kv "$RUN_DIR/result.tsv" local_source_tree_manifest_sha256 "$EXPECTED_TREE_MANIFEST_SHA256"
    record_kv "$RUN_DIR/result.tsv" external_network_access_performed no
    record_kv "$RUN_DIR/result.tsv" boot_action_performed no
    record_kv "$RUN_DIR/result.tsv" reboot_performed no

    tar -C "$RUN_DIR" -czf "$tmp_archive" .
    chmod "$PUBLISHED_MODE" -- "$tmp_archive"
    chown "$PUBLISHED_OWNER" -- "$tmp_archive"
    mv -f -- "$tmp_archive" "$PUBLISHED_ARCHIVE"
    archive_sha=$(sha256sum -- "$PUBLISHED_ARCHIVE" | awk '{print $1}')
    printf '%s  %s\n' "$archive_sha" "${PUBLISHED_ARCHIVE##*/}" > "$PUBLISHED_SHA256"
    chmod "$PUBLISHED_MODE" -- "$PUBLISHED_SHA256"
    chown "$PUBLISHED_OWNER" -- "$PUBLISHED_SHA256"

    printf 'runtime_remediation_validation_status\tPASS\n'
    printf 'evidence_archive\t%s\n' "$PUBLISHED_ARCHIVE"
    printf 'evidence_archive_sha256\t%s\n' "$archive_sha"
    printf 'final_header_record\t%s\n' "$TARGET_RECORD"
    printf 'package_database_manifest_sha256\t%s\n' "$(package_database_manifest_hash)"
    printf 'boot_id\t%s\n' "$(cat /proc/sys/kernel/random/boot_id)"
    printf 'candidate_upgrade_count\t1\n'
    printf 'reference_apply_exit_code\t0\n'
    printf 'slackpkg_state_restored\tyes\n'
    printf 'geninitrd_policy_restored\tyes\n'
    printf 'boot_artifacts_unchanged\tyes\n'
    printf 'reboot_performed\tno\n'
}

main() {
    local ack=0 derived_sha
    while (($#)); do
        case "$1" in
            --execute-runtime-remediation-validation)
                [[ $ack -eq 0 ]] || fail 'duplicate --execute-runtime-remediation-validation'
                ack=1
                shift
                ;;
            --help|-h)
                usage
                return 0
                ;;
            *)
                printf 'ERROR: unknown option: %s\n' "$1" >&2
                return 2
                ;;
        esac
    done
    [[ $ack -eq 1 ]] || { usage >&2; return 2; }
    [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: run this executor through sudo/root\n' >&2; return 3; }

    for command_name in awk base64 cat chown cmp cp find grep hostname id install md5sum mkdir mv python3 readlink rm sha256sum sort stat tar uname unshare upgradepkg wc slackpkg; do
        command -v "$command_name" >/dev/null 2>&1 || fail "required command missing: $command_name"
    done
    [[ -f /proc/sys/kernel/random/boot_id && ! -L /proc/sys/kernel/random/boot_id ]] || fail 'boot ID source missing or unsafe'
    [[ -d $PACKAGE_DATABASE_CANONICAL && ! -L $PACKAGE_DATABASE_CANONICAL ]] || fail 'canonical package database missing or unsafe'
    [[ -L $PACKAGE_DATABASE ]] || fail 'compatibility package database is not the expected symlink'
    [[ $(readlink -f -- "$PACKAGE_DATABASE" 2>/dev/null || true) == "$PACKAGE_DATABASE_CANONICAL" ]] || fail 'package database symlink target mismatch'
    [[ -d $SLACKPKG_STATE && ! -L $SLACKPKG_STATE ]] || fail 'Slackpkg state root missing or unsafe'
    [[ ! -e $EVIDENCE_ROOT && ! -L $EVIDENCE_ROOT ]] || fail "runtime evidence root already exists: $EVIDENCE_ROOT"
    [[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]] || fail "published evidence archive already exists: $PUBLISHED_ARCHIVE"
    [[ ! -e $PUBLISHED_SHA256 && ! -L $PUBLISHED_SHA256 ]] || fail "published evidence checksum already exists: $PUBLISHED_SHA256"
    [[ -f $PREDECESSOR_TRANSPORT && ! -L $PREDECESSOR_TRANSPORT ]] || fail "predecessor transport file missing or unsafe: $PREDECESSOR_TRANSPORT"
    [[ $(sha256sum -- "$PREDECESSOR_TRANSPORT" | awk '{print $1}') == "$PREDECESSOR_SHA256" ]] || fail 'predecessor transport SHA-256 drift'

    verify_preserved_inputs
    verify_target_identity

    install -d -m 0700 -o root -g root -- "$EVIDENCE_ROOT"
    RUN_DIR=$EVIDENCE_ROOT
    REFERENCE_FILE="$RUN_DIR/slack-update-reference.sh"
    SOURCE_CONFIG="$RUN_DIR/source.conf"
    DERIVED_CONFIG="$RUN_DIR/derived.conf"
    PRE_PACKAGE_NAMES="$RUN_DIR/package-names-before.txt"
    extract_payload reference "$REFERENCE_FILE"
    extract_payload config "$SOURCE_CONFIG"
    chmod 0700 -- "$REFERENCE_FILE"
    chmod 0600 -- "$SOURCE_CONFIG"
    [[ $(sha256sum -- "$REFERENCE_FILE" | awk '{print $1}') == "$EMBEDDED_REFERENCE_SHA256" ]] || fail 'embedded reference script SHA-256 mismatch'
    [[ $(sha256sum -- "$SOURCE_CONFIG" | awk '{print $1}') == "$EMBEDDED_CONFIG_SHA256" ]] || fail 'embedded source configuration SHA-256 mismatch'
    derive_runtime_config "$SOURCE_CONFIG" "$DERIVED_CONFIG"
    derived_sha=$(sha256sum -- "$DERIVED_CONFIG" | awk '{print $1}')

    capture_package_names "$PRE_PACKAGE_NAMES"
    BOOT_FINGERPRINT_BEFORE=$(tree_fingerprint /boot)
    SLACKPKG_STATE_FINGERPRINT_BEFORE=$(tree_fingerprint "$SLACKPKG_STATE")
    GENINITRD_FINGERPRINT_BEFORE=$(path_fingerprint "$GENINITRD_POLICY")

    : > "$RUN_DIR/preflight.tsv"
    record_kv "$RUN_DIR/preflight.tsv" preflight_status PASS
    record_kv "$RUN_DIR/preflight.tsv" hostname_fqdn "$(hostname -f)"
    record_kv "$RUN_DIR/preflight.tsv" running_kernel "$(uname -r)"
    record_kv "$RUN_DIR/preflight.tsv" boot_id "$(cat /proc/sys/kernel/random/boot_id)"
    record_kv "$RUN_DIR/preflight.tsv" package_database_manifest_sha256 "$(package_database_manifest_hash)"
    record_kv "$RUN_DIR/preflight.tsv" header_record "$(package_records kernel-headers)"
    record_kv "$RUN_DIR/preflight.tsv" reference_script_sha256 "$EMBEDDED_REFERENCE_SHA256"
    record_kv "$RUN_DIR/preflight.tsv" source_config_sha256 "$EMBEDDED_CONFIG_SHA256"
    record_kv "$RUN_DIR/preflight.tsv" derived_config_sha256 "$derived_sha"
    record_kv "$RUN_DIR/preflight.tsv" predecessor_sha256 "$PREDECESSOR_SHA256"
    record_kv "$RUN_DIR/preflight.tsv" target_sha256 "$TARGET_SHA256"
    record_kv "$RUN_DIR/preflight.tsv" local_source_v2_tree_manifest_sha256 "$EXPECTED_TREE_MANIFEST_SHA256"
    record_kv "$RUN_DIR/preflight.tsv" boot_fingerprint "$BOOT_FINGERPRINT_BEFORE"
    record_kv "$RUN_DIR/preflight.tsv" slackpkg_state_fingerprint "$SLACKPKG_STATE_FINGERPRINT_BEFORE"
    record_kv "$RUN_DIR/preflight.tsv" geninitrd_policy_fingerprint "$GENINITRD_FINGERPRINT_BEFORE"
    record_kv "$RUN_DIR/preflight.tsv" external_network_access_authorized no

    backup_mutable_state
    trap cleanup_on_exit EXIT
    trap 'handle_signal HUP 129' HUP
    trap 'handle_signal INT 130' INT
    trap 'handle_signal TERM 143' TERM

    MUTATION_STARTED=1
    upgradepkg "$PREDECESSOR_TRANSPORT" > "$RUN_DIR/predecessor-staging.stdout" 2> "$RUN_DIR/predecessor-staging.stderr" || fail 'predecessor header staging failed'
    [[ $(package_records kernel-headers) == "$PREDECESSOR_RECORD" ]] || fail 'predecessor header record was not installed after staging'
    verify_header_only_staging_delta

    configure_temporary_slackpkg
    run_local_metadata_refresh
    bind_candidate_set
    run_reference_apply

    [[ $(package_records kernel-headers) == "$TARGET_RECORD" ]] || fail 'reference apply did not restore the target header record'
    [[ $(package_database_manifest_hash) == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail 'reference apply did not restore the frozen package database manifest'
    [[ $(tree_fingerprint /boot) == "$BOOT_FINGERPRINT_BEFORE" ]] || fail 'reference apply changed boot artifacts'
    [[ $(path_fingerprint "$GENINITRD_POLICY") == "$GENINITRD_FINGERPRINT_BEFORE" ]] || fail 'reference apply did not restore GenInitrd policy before executor cleanup'
    verify_local_source_tree
    [[ $(regular_sha256 "$STAGED_TARGET") == "$TARGET_SHA256" ]] || fail 'staged target changed during reference apply'

    restore_transaction_state || fail 'executor cleanup restoration failed'
    verify_final_invariants
    RESTORATION_COMPLETE=1
    MUTATION_STARTED=0
    publish_evidence
    trap - EXIT HUP INT TERM
    return 0
}

main "$@"
exit $?

__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__
