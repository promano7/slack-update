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
BACKUP_READY=0
MUTATION_STARTED=0
RESTORATION_COMPLETE=0
CLEANUP_RUNNING=0

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-executor.sh --execute-runtime-validation
       phase-1-kernel-package-edge-runtime-transaction-executor.sh --help

Run the bounded Phase 1 kernel-package-edge runtime transaction. The executor
revalidates the exact frozen target, temporarily stages kernel-headers 6.18.44,
binds the single local 6.18.45 candidate, runs the frozen reference apply in a
network namespace without external interfaces, and restores all temporary
Slackpkg state before publishing evidence. A Git repository is not required on
the target VM.
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

verify_local_source_tree() {
    local actual_manifest_sha candidate_count bad_dirs bad_files metadata
    [[ -d $LOCAL_SOURCE_ROOT && ! -L $LOCAL_SOURCE_ROOT ]] || fail "local-source root missing or unsafe: $LOCAL_SOURCE_ROOT"
    [[ -f $TREE_MANIFEST && ! -L $TREE_MANIFEST ]] || fail "tree manifest missing or unsafe: $TREE_MANIFEST"
    [[ -f $TREE_MANIFEST_SHA256_FILE && ! -L $TREE_MANIFEST_SHA256_FILE ]] || fail "tree-manifest sidecar missing or unsafe: $TREE_MANIFEST_SHA256_FILE"
    actual_manifest_sha=$(sha256sum -- "$TREE_MANIFEST" | awk '{print $1}')
    [[ $actual_manifest_sha == "$EXPECTED_TREE_MANIFEST_SHA256" ]] || fail 'tree-manifest SHA-256 drift'
    (cd "${TREE_MANIFEST%/*}" && sha256sum -c -- "${TREE_MANIFEST_SHA256_FILE##*/}" >/dev/null) || fail 'tree-manifest sidecar verification failed'
    (cd "$LOCAL_SOURCE_ROOT" && sha256sum -c -- "$TREE_MANIFEST" >/dev/null) || fail 'local-source tree does not match bound manifest'
    [[ $(regular_sha256 "$LOCAL_SOURCE_TARGET") == "$TARGET_SHA256" ]] || fail 'local-source target SHA-256 drift'
    candidate_count=$(find "$LOCAL_SOURCE_ROOT" -type f -name '*.txz' -print | wc -l | awk '{print $1}')
    [[ $candidate_count -eq 1 ]] || fail "local source exposes $candidate_count package archives instead of exactly one"
    [[ ! -e "$LOCAL_SOURCE_ROOT/slackware64/d/$PREDECESSOR_ARTIFACT" && ! -L "$LOCAL_SOURCE_ROOT/slackware64/d/$PREDECESSOR_ARTIFACT" ]] || fail 'predecessor unexpectedly present in local source'
    for metadata in ChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5; do
        [[ -f "$LOCAL_SOURCE_ROOT/$metadata" && ! -L "$LOCAL_SOURCE_ROOT/$metadata" && -s "$LOCAL_SOURCE_ROOT/$metadata" ]] || fail "required local-source metadata missing or unsafe: $metadata"
    done
    bad_dirs=$(find "$LOCAL_SOURCE_ROOT" -type d \( ! -user root -o ! -group root -o ! -perm 0555 \) -print -quit)
    [[ -z $bad_dirs ]] || fail "local-source directory ownership/mode drift: $bad_dirs"
    bad_files=$(find "$LOCAL_SOURCE_ROOT" -type f \( ! -user root -o ! -group root -o ! -perm 0444 \) -print -quit)
    [[ -z $bad_files ]] || fail "local-source file ownership/mode drift: $bad_files"
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
    awk '
        /^[[:space:]]*CHECKGPG[[:space:]]*=/ { print "CHECKGPG=off"; seen=1; next }
        { print }
        END { if (!seen) exit 42 }
    ' "$SLACKPKG_CONF" > "$tmp_conf" || fail 'cannot derive temporary slackpkg.conf'
    cat "$tmp_conf" > "$SLACKPKG_CONF"
    printf '%s\n' "$LOCAL_SOURCE_URI" > "$SLACKPKG_MIRRORS"
    rm -f -- "$tmp_conf"

    record_kv "$RUN_DIR/temporary-slackpkg.tsv" slackpkg_conf_sha256 "$(sha256sum "$SLACKPKG_CONF" | awk '{print $1}')"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" mirrors_sha256 "$(sha256sum "$SLACKPKG_MIRRORS" | awk '{print $1}')"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" mirror "$LOCAL_SOURCE_URI"
    record_kv "$RUN_DIR/temporary-slackpkg.tsv" checkgpg off
}

verify_header_only_staging_delta() {
    local after="$RUN_DIR/package-names-after-staging.txt"
    capture_package_names "$after"
    python3 - "$PRE_PACKAGE_NAMES" "$after" "$TARGET_RECORD" "$PREDECESSOR_RECORD" <<'PY'
import sys
before=set(open(sys.argv[1],encoding='utf-8').read().splitlines())
after=set(open(sys.argv[2],encoding='utf-8').read().splitlines())
target=sys.argv[3]
predecessor=sys.argv[4]
removed=before-after
added=after-before
if removed != {target} or added != {predecessor}:
    raise SystemExit(f'unexpected package delta: removed={sorted(removed)!r} added={sorted(added)!r}')
PY
    [[ $(uname -r) == "$EXPECTED_KERNEL" ]] || fail 'running kernel changed during header staging'
    [[ $(cat /proc/sys/kernel/random/boot_id) == "$EXPECTED_BOOT_ID" ]] || fail 'boot ID changed during header staging'
    [[ $(package_records kernel-generic) == "$EXPECTED_KERNEL_GENERIC_RECORD" ]] || fail 'kernel-generic record changed during header staging'
    [[ -z $(package_records kernel-huge) ]] || fail 'kernel-huge appeared during header staging'
    [[ -z $(package_records kernel-modules) ]] || fail 'kernel-modules appeared during header staging'
    [[ $(tree_fingerprint /boot) == "$BOOT_FINGERPRINT_BEFORE" ]] || fail 'boot artifacts changed during header staging'
}

run_local_metadata_refresh() {
    unshare -n -- cat /proc/net/dev > "$RUN_DIR/network-namespace.txt"
    local rc=0
    unshare -n -- slackpkg -batch=on -default_answer=y update \
        > "$RUN_DIR/slackpkg-update.stdout" 2> "$RUN_DIR/slackpkg-update.stderr" || rc=$?
    printf '%s\n' "$rc" > "$RUN_DIR/slackpkg-update.exit-code"
    [[ $rc -eq 0 ]] || fail "local slackpkg metadata refresh failed with exit code $rc"
}

bind_candidate_set() {
    local pkglist="$SLACKPKG_STATE/pkglist"
    local line_count target_count
    [[ -f $pkglist && ! -L $pkglist ]] || fail "refreshed Slackpkg pkglist is missing or unsafe: $pkglist"
    line_count=$(awk 'NF {count++} END {print count+0}' "$pkglist")
    target_count=$(grep -F -c -- "$TARGET_RECORD" "$pkglist" || true)
    [[ $line_count -eq 1 ]] || fail "refreshed local pkglist contains $line_count package rows instead of exactly one"
    [[ $target_count -eq 1 ]] || fail 'refreshed local pkglist does not bind exactly one frozen target record'
    [[ $(package_records kernel-headers) == "$PREDECESSOR_RECORD" ]] || fail 'candidate binding did not start from frozen predecessor record'
    verify_local_source_tree

    cat > "$RUN_DIR/candidate-binding.tsv" <<EOF_CANDIDATES
binding_status\tPASS
binding_lifetime\tsame-runtime-transaction-only
upgrade_count\t1
upgrade_package\tkernel-headers
upgrade_from\t$PREDECESSOR_RECORD
upgrade_to\t$TARGET_RECORD
install_new_count\t0
non_header_upgrade_count\t0
configured_boot_upgrade_count\t0
refreshed_pkglist_sha256\t$(sha256sum "$pkglist" | awk '{print $1}')
local_source_tree_manifest_sha256\t$EXPECTED_TREE_MANIFEST_SHA256
EOF_CANDIDATES
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
}

publish_evidence() {
    local tmp_archive="${PUBLISHED_ARCHIVE}.tmp.$$"
    local archive_sha
    rm -rf -- "$BACKUP_ROOT"
    BACKUP_ROOT=
    printf 'runtime_validation_status\tPASS\n' > "$RUN_DIR/result.tsv"
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

    printf 'runtime_validation_status\tPASS\n'
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
            --execute-runtime-validation)
                [[ $ack -eq 0 ]] || fail 'duplicate --execute-runtime-validation'
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

    for command_name in awk base64 cat chown cp find grep hostname id install mkdir mv python3 readlink rm sha256sum sort stat tar uname unshare upgradepkg wc slackpkg; do
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

    cat > "$RUN_DIR/preflight.tsv" <<EOF_PREFLIGHT
preflight_status\tPASS
hostname_fqdn\t$(hostname -f)
running_kernel\t$(uname -r)
boot_id\t$(cat /proc/sys/kernel/random/boot_id)
package_database_manifest_sha256\t$(package_database_manifest_hash)
header_record\t$(package_records kernel-headers)
reference_script_sha256\t$EMBEDDED_REFERENCE_SHA256
source_config_sha256\t$EMBEDDED_CONFIG_SHA256
derived_config_sha256\t$derived_sha
predecessor_sha256\t$PREDECESSOR_SHA256
target_sha256\t$TARGET_SHA256
local_source_tree_manifest_sha256\t$EXPECTED_TREE_MANIFEST_SHA256
boot_fingerprint\t$BOOT_FINGERPRINT_BEFORE
slackpkg_state_fingerprint\t$SLACKPKG_STATE_FINGERPRINT_BEFORE
geninitrd_policy_fingerprint\t$GENINITRD_FINGERPRINT_BEFORE
external_network_access_authorized\tno
EOF_PREFLIGHT

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
