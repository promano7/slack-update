#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_ACCEPTED_REFRESH="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-candidate-chain-refresh-20260804-accepted.json"
DEFAULT_ACCEPTED_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-kernel-chain-restart-preflight
BOOT_PREFLIGHT_SCRIPT=${BOOT_PREFLIGHT_SCRIPT:-$TEST_DIR/test-current-kernel-boot-preflight.sh}

TARGET=
ACCEPTED_REFRESH=$DEFAULT_ACCEPTED_REFRESH
ACCEPTED_PREFLIGHT=$DEFAULT_ACCEPTED_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
CANDIDATE_SET_SHA256=
TARGET_KERNEL=
RUNNING_KERNEL=
NEXT_STAGE=current-kernel-package-preflight
NESTED_TARGET_IMAGE_METADATA_STATE=unknown

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current [options]

Restart the Slackware-current kernel evidence chain from the accepted fresh
candidate set. The wrapper validates the reviewed 2026-08-04 chain-refresh and
normal-update records, then invokes only the non-destructive kernel boot
preflight for the accepted target. It never installs packages, generates an
initrd, updates GRUB, or authorizes apply.

Required options:
      --target slackware-current

Optional arguments:
      --accepted-refresh PATH    Select the reviewed chain-refresh record
      --accepted-preflight PATH  Select the reviewed normal-update record
      --output-dir PATH          Store evidence under an absolute, new directory
  -h, --help                     Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"
}
record_failure() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                [ "$#" -ge 2 ] || { error '--target requires a value'; return 1; }
                TARGET=$2; shift 2 ;;
            --accepted-refresh)
                [ "$#" -ge 2 ] || { error '--accepted-refresh requires a value'; return 1; }
                ACCEPTED_REFRESH=$2; shift 2 ;;
            --accepted-preflight)
                [ "$#" -ge 2 ] || { error '--accepted-preflight requires a value'; return 1; }
                ACCEPTED_PREFLIGHT=$2; shift 2 ;;
            --output-dir)
                [ "$#" -ge 2 ] || { error '--output-dir requires a value'; return 1; }
                OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    for path in "$ACCEPTED_REFRESH" "$ACCEPTED_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

load_reviewed_chain() {
    local values
    values=$(python3 - "$ACCEPTED_REFRESH" "$ACCEPTED_PREFLIGHT" <<'PY'
import hashlib, json, re, sys
refresh_path, preflight_path = sys.argv[1:]
try:
    refresh = json.load(open(refresh_path, encoding='utf-8'))
    preflight = json.load(open(preflight_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)

def digest_for(items):
    return hashlib.sha256(('\n'.join(items) + '\n').encode()).hexdigest()

candidate = preflight.get('candidates', {})
install = candidate.get('install_new')
upgrade = candidate.get('upgrade_all')
if not isinstance(install, list) or not isinstance(upgrade, list):
    raise SystemExit(1)
all_candidates = sorted(install + upgrade)
if len(all_candidates) != len(set(all_candidates)):
    raise SystemExit(1)
if all_candidates != install + upgrade and set(install) & set(upgrade):
    raise SystemExit(1)
for name in all_candidates:
    if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._+~-]*\.txz', name):
        raise SystemExit(1)
digest = digest_for(all_candidates)
target = candidate.get('target_kernel_version')
expected_generic = f'kernel-generic-{target}-x86_64-1.txz'
expected_headers = f'kernel-headers-{target}-x86-1.txz'
expected_source = f'kernel-source-{target}-noarch-1.txz'
checks = [
    refresh.get('scenario') == 'current-candidate-chain-refresh-preflight',
    refresh.get('target') == 'slackware-current',
    refresh.get('accepted') is True,
    refresh.get('chain_status') == 'changed-kernel-set',
    refresh.get('next_stage') == 'repeat-current-kernel-evidence-chain',
    refresh.get('prior_candidate_bound_chain_reusable') is False,
    refresh.get('kernel_companion_set_complete') is True,
    refresh.get('apply_ready') is False,
    refresh.get('apply_authorized') is False,
    preflight.get('scenario') == 'normal-update',
    preflight.get('mode') == 'preflight',
    preflight.get('target') == 'slackware-current',
    preflight.get('accepted') is True,
    preflight.get('apply_ready') is False,
    preflight.get('apply_authorized') is False,
    candidate.get('total') == len(all_candidates),
    candidate.get('candidate_set_sha256') == digest,
    refresh.get('fresh_candidate_set_sha256') == digest,
    refresh.get('fresh_candidate_count') == len(all_candidates),
    refresh.get('target_kernel') == target,
    expected_generic in candidate.get('kernel', []),
    expected_headers in candidate.get('kernel', []),
    expected_source in upgrade,
]
if not all(checks):
    raise SystemExit(1)
print(digest)
print(target)
print(refresh.get('running_kernel', ''))
PY
) || return 1
    CANDIDATE_SET_SHA256=$(printf '%s\n' "$values" | sed -n '1p')
    TARGET_KERNEL=$(printf '%s\n' "$values" | sed -n '2p')
    RUNNING_KERNEL=$(printf '%s\n' "$values" | sed -n '3p')
    [ -n "$CANDIDATE_SET_SHA256" ] && [ -n "$TARGET_KERNEL" ] && [ -n "$RUNNING_KERNEL" ]
}

validate_nested_summary() {
    local summary=$1
    python3 - "$summary" "$CANDIDATE_SET_SHA256" "$TARGET_KERNEL" "$RUNNING_KERNEL" <<'PY'
import sys
path, digest, target, running = sys.argv[1:]
data = {}
try:
    for raw in open(path, encoding='utf-8'):
        raw = raw.rstrip('\n')
        if '=' in raw:
            key, value = raw.split('=', 1)
            data[key] = value
except Exception:
    raise SystemExit(1)
checks = [
    data.get('scenario') == 'current-kernel-boot-preflight',
    data.get('target') == 'slackware-current',
    data.get('result') == 'PASS',
    data.get('running_kernel') == running,
    data.get('installed_kernel') == running,
    data.get('target_kernel') == target,
    data.get('candidate_set_sha256') == digest,
    data.get('package_layout') == 'monolithic-generic',
    data.get('boot_mode') in {'direct-generic-no-initrd', 'mkinitrd-managed'},
    data.get('target_image_metadata_state') in {'present', 'deferred-to-exact-package-preflight'},
    data.get('apply_ready') == 'false',
    data.get('apply_authorized') == 'false',
    data.get('failures') == '0',
]
raise SystemExit(0 if all(checks) else 1)
PY
}

verify_nested_archive() {
    local nested_root=$1 archives sidecars archive
    archives=$(find "$nested_root" -maxdepth 1 -type f -name 'slackware-current-current-kernel-boot-preflight-*.tar.gz' -print)
    sidecars=$(find "$nested_root" -maxdepth 1 -type f -name 'slackware-current-current-kernel-boot-preflight-*.tar.gz.sha256' -print)
    [ "$(printf '%s\n' "$archives" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1
    [ "$(printf '%s\n' "$sidecars" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1
    archive=$archives
    (cd "$nested_root" && sha256sum -c "${archive##*/}.sha256" >/dev/null 2>&1)
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-kernel-chain-restart-preflight
target=$TARGET
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CANDIDATE_SET_SHA256
nested_target_image_metadata_state=$NESTED_TARGET_IMAGE_METADATA_STATE
nested_boot_preflight_passed=$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)
next_stage=$NEXT_STAGE
normal_update_apply_executed=false
package_transaction_executed=false
initrd_generation_executed=false
grub_update_executed=false
apply_ready=false
apply_authorized=false
EOF_SUMMARY
}

create_evidence_archive() {
    local parent base archive
    parent=$(dirname -- "$OUTPUT_DIR")
    base=${OUTPUT_DIR##*/}
    archive="$parent/${TARGET}-current-kernel-chain-restart-preflight-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum "${archive##*/}") > "$archive.sha256" || return 1
    printf '%s\n' "$archive"
}

print_evidence_commands() {
    local archive=$1 owner=${SUDO_USER:-promano} group
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
        "$owner" "$group" "$archive.sha256" "/home/$owner/${archive##*/}.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' \
        "/home/$owner" "${archive##*/}.sha256"
}

main() {
    local timestamp nested_root nested_dir nested_exit archive

    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this real-system preflight requires root'; return 2; }
    for command_name in bash date find hostname id python3 sed sha256sum tar uname wc; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command unavailable: $command_name"; return 2; }
    done
    [ -x "$BOOT_PREFLIGHT_SCRIPT" ] || { error "boot preflight is unavailable: $BOOT_PREFLIGHT_SCRIPT"; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] || { error "output directory already exists: $OUTPUT_DIR"; return 2; }
    mkdir -p -- "$OUTPUT_DIR" || return 2
    chmod 0700 -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"
    : > "$ASSERTION_LOG"

    if load_reviewed_chain; then
        record_pass "the accepted 69-candidate refresh and normal-update records bind target kernel $TARGET_KERNEL"
    else
        record_failure 'the accepted refresh and normal-update records are inconsistent or unsafe'
    fi

    printf 'hostname=%s\nrunning_kernel=%s\ntarget_kernel=%s\ncandidate_set_sha256=%s\n' \
        "$(hostname)" "$(uname -r)" "$TARGET_KERNEL" "$CANDIDATE_SET_SHA256" > "$OUTPUT_DIR/host.txt"

    nested_root="$OUTPUT_DIR/nested"
    nested_dir="$nested_root/boot-preflight"
    mkdir -p -- "$nested_root" || return 2
    printf 'Running the non-destructive Slackware-current kernel boot preflight for %s...\n' "$TARGET_KERNEL"
    bash "$BOOT_PREFLIGHT_SCRIPT" \
        --target slackware-current \
        --confirm-candidates-sha256 "$CANDIDATE_SET_SHA256" \
        --confirm-target-kernel "$TARGET_KERNEL" \
        --accepted-preflight "$ACCEPTED_PREFLIGHT" \
        --output-dir "$nested_dir" \
        > "$OUTPUT_DIR/boot-preflight.stdout.log" \
        2> "$OUTPUT_DIR/boot-preflight.stderr.log"
    nested_exit=$?
    printf '%s\n' "$nested_exit" > "$OUTPUT_DIR/boot-preflight.exit"
    cat "$OUTPUT_DIR/boot-preflight.stdout.log"
    [ -s "$OUTPUT_DIR/boot-preflight.stderr.log" ] && cat "$OUTPUT_DIR/boot-preflight.stderr.log" >&2 || true

    if [ "$nested_exit" -eq 0 ]; then
        record_pass 'the target-specific kernel boot preflight completed without authorizing package installation'
    else
        record_failure "the target-specific kernel boot preflight failed with exit code $nested_exit"
    fi
    if validate_nested_summary "$nested_dir/summary.txt"; then
        NESTED_TARGET_IMAGE_METADATA_STATE=$(sed -n 's/^target_image_metadata_state=//p' "$nested_dir/summary.txt")
        record_pass 'the nested boot result matches the accepted candidate digest, running kernel, and new target'
    else
        record_failure 'the nested boot result does not match the accepted restarted chain'
    fi
    if verify_nested_archive "$nested_root"; then
        record_pass 'the nested boot evidence archive and portable sidecar verify inside the outer evidence'
    else
        record_failure 'the nested boot evidence archive or sidecar is missing, ambiguous, or invalid'
    fi
    if [ -f "$nested_dir/boot.before.txt" ] && [ -f "$nested_dir/boot.after.txt" ] \
        && cmp -s "$nested_dir/boot.before.txt" "$nested_dir/boot.after.txt"; then
        record_pass 'the active boot state remained unchanged during the restarted boot preflight'
    else
        record_failure 'the restarted boot preflight did not prove an unchanged active boot state'
    fi
    if grep -Fxq 'PASS: the installed package database remained unchanged during the preflight' "$nested_dir/assertions.log"; then
        record_pass 'the installed package database remained unchanged during the restarted boot preflight'
    else
        record_failure 'the restarted boot preflight did not prove an unchanged package database'
    fi

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current kernel chain restart result: running=%s, target=%s, candidates=%s, target-image-metadata=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$CANDIDATE_SET_SHA256" "$NESTED_TARGET_IMAGE_METADATA_STATE" "$NEXT_STAGE"
    archive=$(create_evidence_archive) || { error 'failed to create evidence archive'; return 1; }
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"
    print_evidence_commands "$archive"
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
