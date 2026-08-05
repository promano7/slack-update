#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_NORMAL_UPDATE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-normal-update.sh"
DEFAULT_BASELINE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
DEFAULT_REFRESH_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-candidate-chain-refresh-20260805-accepted.json"
DEFAULT_REVIEW_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-expansion-20260805-reviewed.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-userspace-candidate-review-preflight

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
NORMAL_UPDATE_SCRIPT=$DEFAULT_NORMAL_UPDATE_SCRIPT
BASELINE_PREFLIGHT=$DEFAULT_BASELINE_PREFLIGHT
REFRESH_RECORD=$DEFAULT_REFRESH_RECORD
REVIEW_POLICY=$DEFAULT_REVIEW_POLICY
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
RUNNING_KERNEL=
FRESH_CANDIDATE_SHA256=
TARGET_KERNEL=
ADDED_CANDIDATE_COUNT=0
PLASMA_CANDIDATE_COUNT=0
SUPPORTING_CANDIDATE_COUNT=0
BOOT_ADJACENT_CANDIDATE_COUNT=0
KERNEL_EVIDENCE_REBIND_READY=false
NEXT_STAGE=manual-review-required

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Review an exact Slackware-current userspace-only candidate expansion before any
kernel evidence is rebound to the new candidate digest. The review validates
candidate identity and category boundaries only. It never installs packages,
executes maintainer scripts, generates an initrd, runs DKMS, or changes GRUB.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-update-script PATH
      --baseline-preflight PATH
      --refresh-record PATH
      --review-policy PATH
      --output-dir PATH
  -h, --help
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }

is_sha256() {
    [ "${#1}" -eq 64 ] || return 1
    case "$1" in *[!0-9A-Fa-f]*) return 1 ;; esac
}

is_safe_kernel_version() {
    case "$1" in ''|.|..|*/*|*[[:space:]]*|*[!A-Za-z0-9._+-]*) return 1 ;; *) return 0 ;; esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-candidates-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CANDIDATES_SHA256=$2; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --normal-update-script) [ "$#" -ge 2 ] || return 1; NORMAL_UPDATE_SCRIPT=$2; shift 2 ;;
            --baseline-preflight) [ "$#" -ge 2 ] || return 1; BASELINE_PREFLIGHT=$2; shift 2 ;;
            --refresh-record) [ "$#" -ge 2 ] || return 1; REFRESH_RECORD=$2; shift 2 ;;
            --review-policy) [ "$#" -ge 2 ] || return 1; REVIEW_POLICY=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    for path in "$NORMAL_UPDATE_SCRIPT" "$BASELINE_PREFLIGHT" "$REFRESH_RECORD" "$REVIEW_POLICY" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

capture_package_state() {
    local output=$1 root=/var/lib/pkgtools/packages item
    [ -d "$root" ] && [ ! -L "$root" ] || return 1
    : > "$output" || return 1
    while IFS= read -r -d '' item; do
        [ ! -L "$item" ] || return 1
        printf '%s\t%s\n' "${item##*/}" "$(sha256sum -- "$item" | awk '{print $1}')" >> "$output" || return 1
    done < <(find "$root" -maxdepth 1 -type f -print0 | LC_ALL=C sort -z)
    [ -s "$output" ]
}

capture_path_state() {
    local path=$1
    if [ -L "$path" ]; then
        printf 'symlink|%s|%s' "$(readlink -- "$path" 2>/dev/null || true)" "$(readlink -e -- "$path" 2>/dev/null || true)"
    elif [ -f "$path" ]; then
        printf 'regular|%s|%s' "$(stat -c '%a:%u:%g:%s:%Y' -- "$path")" "$(sha256sum -- "$path" | awk '{print $1}')"
    elif [ -d "$path" ]; then
        printf 'directory|%s|' "$(stat -c '%a:%u:%g:%Y' -- "$path")"
    else
        printf 'missing||'
    fi
}

capture_boot_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$RUNNING_KERNEL" \
        /boot/initrd-generic.img \
        "/boot/initrd-$RUNNING_KERNEL.img" \
        /boot/initrd.gz \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/mkinitrd.conf; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

validate_accepted_records() {
    python3 - "$BASELINE_PREFLIGHT" "$REFRESH_RECORD" "$REVIEW_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, re, sys
baseline_path, refresh_path, policy_path, confirmed_digest, confirmed_target = sys.argv[1:]
try:
    baseline = json.load(open(baseline_path, encoding='utf-8'))
    refresh = json.load(open(refresh_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)

def digest(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None

def denied(record):
    return record.get('apply_ready') is False and record.get('apply_authorized') is False

base = baseline.get('candidates', {})
base_all = sorted(base.get('install_new', []) + base.get('upgrade_all', []))
fresh_all = refresh.get('all_candidates', [])
added = refresh.get('added_candidates', [])
categories = policy.get('categories', {})
category_values = categories.get('plasma_6_7_4', []) + categories.get('supporting_userspace', []) + categories.get('boot_adjacent_theme', [])
raw = ''.join(f'{item}\n' for item in fresh_all).encode()
checks = [
    baseline.get('scenario') == 'normal-update', baseline.get('accepted') is True, denied(baseline),
    base.get('candidate_set_sha256') == refresh.get('baseline_candidate_set_sha256'),
    refresh.get('scenario') == 'current-candidate-chain-refresh-preflight', refresh.get('accepted') is True, denied(refresh),
    digest(refresh.get('archive_sha256')), digest(refresh.get('nested_normal_update_archive_sha256')),
    refresh.get('evidence', {}).get('copied_to') == '/home/promano',
    refresh.get('evidence', {}).get('destination_verification') == 'passed',
    refresh.get('assertions') == {'passes': 8, 'failures': 0},
    refresh.get('fresh_candidate_set_sha256') == confirmed_digest, digest(confirmed_digest),
    hashlib.sha256(raw).hexdigest() == confirmed_digest,
    refresh.get('target_kernel') == confirmed_target,
    refresh.get('chain_status') == 'changed-userspace-set',
    refresh.get('fresh_candidate_count') == len(fresh_all) == 137,
    refresh.get('added_candidate_count') == len(added) == 68,
    refresh.get('removed_candidate_count') == 0 and refresh.get('removed_candidates') == [],
    refresh.get('strict_candidate_superset') is True,
    refresh.get('userspace_only_candidate_change') is True,
    refresh.get('kernel_transaction_changed') is False,
    refresh.get('kernel_evidence_rebind_possible_after_userspace_review') is True,
    set(base_all).issubset(set(fresh_all)), sorted(set(fresh_all) - set(base_all)) == added,
    policy.get('scenario') == 'current-userspace-candidate-review-policy', policy.get('reviewed') is True, denied(policy),
    policy.get('review_scope') == 'candidate-identity-for-kernel-evidence-rebind',
    policy.get('fresh_candidate_set_sha256') == confirmed_digest,
    policy.get('target_kernel') == confirmed_target,
    policy.get('added_candidate_count') == 68, policy.get('removed_candidate_count') == 0,
    sorted(category_values) == added and len(category_values) == len(set(category_values)),
    policy.get('category_counts') == {'boot_adjacent_theme': 1, 'plasma_6_7_4': 61, 'supporting_userspace': 6},
    categories.get('boot_adjacent_theme') == ['breeze-grub-6.7.4-x86_64-1.txz'],
    policy.get('kernel_or_boot_transaction_packages') == [],
    policy.get('package_payloads_inspected') is False,
    policy.get('kernel_evidence_rebind_review_complete') is True,
    policy.get('userspace_apply_review_complete') is False,
    policy.get('kernel_evidence_rebind_ready') is True,
    policy.get('next_stage') == 'current-kernel-evidence-rebind-preflight',
]
if not all(checks):
    raise SystemExit(1)
print(confirmed_digest)
print(confirmed_target)
print(len(added))
print(len(categories['plasma_6_7_4']))
print(len(categories['supporting_userspace']))
print(len(categories['boot_adjacent_theme']))
PY
}

analyze_fresh_review() {
    local fresh_dir=$1 output=$2
    python3 - "$BASELINE_PREFLIGHT" "$REFRESH_RECORD" "$REVIEW_POLICY" "$fresh_dir" "$output" "$RUNNING_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
baseline_path, refresh_path, policy_path, fresh_dir, output_path, running = sys.argv[1:]
root = pathlib.Path(fresh_dir)
try:
    baseline = json.load(open(baseline_path, encoding='utf-8'))
    refresh = json.load(open(refresh_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
    summary = dict(line.rstrip('\n').split('=', 1) for line in open(root/'summary.txt', encoding='utf-8') if '=' in line)
except Exception:
    raise SystemExit(1)

def read_list(name):
    path = root/name
    if not path.is_file():
        raise SystemExit(1)
    values = [x.strip() for x in path.read_text(encoding='utf-8').splitlines() if x.strip()]
    if values != sorted(set(values)):
        raise SystemExit(1)
    for value in values:
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9+._-]*\.t(?:xz|gz|lz|bz)', value):
            raise SystemExit(1)
    return values

def package_name(filename):
    stem = re.sub(r'\.t(?:xz|gz|lz|bz)$', '', filename)
    parts = stem.rsplit('-', 3)
    if len(parts) != 4 or not all(parts):
        raise SystemExit(1)
    return parts[0]

install = read_list('install-new.candidates.txt')
upgrade = read_list('upgrade-all.candidates.txt')
all_candidates = read_list('all.candidates.txt')
critical = read_list('critical.candidates.txt')
if set(install) & set(upgrade) or all_candidates != sorted(install + upgrade):
    raise SystemExit(1)
raw = ''.join(f'{item}\n' for item in all_candidates).encode()
digest = hashlib.sha256(raw).hexdigest()
base = baseline['candidates']
base_all = sorted(base['install_new'] + base['upgrade_all'])
added = sorted(set(all_candidates) - set(base_all))
removed = sorted(set(base_all) - set(all_candidates))
expected_added = refresh['added_candidates']
categories = policy['categories']
category_values = categories['plasma_6_7_4'] + categories['supporting_userspace'] + categories['boot_adjacent_theme']
kernel_names = {'kernel-generic', 'kernel-headers', 'kernel-source'}
fresh_kernel = sorted(x for x in all_candidates if package_name(x) in kernel_names)
prohibited_exact = {'grub', 'elilo', 'lilo', 'mkinitrd', 'geninitrd', 'dracut', 'os-prober', 'slackpkg', 'pkgtools'}
prohibited_added = sorted(x for x in added if package_name(x).startswith('kernel-') or package_name(x) in prohibited_exact)
checks = [
    summary.get('scenario') == 'normal-update', summary.get('mode') == 'preflight', summary.get('target') == 'slackware-current',
    summary.get('result') == 'PASS', summary.get('failures') == '0', summary.get('candidate_set_sha256') == digest,
    digest == refresh['fresh_candidate_set_sha256'], all_candidates == refresh['all_candidates'],
    install == refresh['install_new'], upgrade == refresh['upgrade_all'], critical == [],
    int(summary.get('total_candidates', '-1')) == len(all_candidates) == 137,
    int(summary.get('critical_candidates', '-1')) == 0,
    added == expected_added, removed == [], len(added) == 68,
    not (set(added) & set(install)), sorted(category_values) == added,
    fresh_kernel == refresh['fresh_kernel_candidates'], prohibited_added == [],
    categories['boot_adjacent_theme'] == ['breeze-grub-6.7.4-x86_64-1.txz'],
]
if not all(checks):
    raise SystemExit(1)
result = {
    'scenario': 'current-userspace-candidate-review-preflight',
    'target': 'slackware-current',
    'running_kernel': running,
    'baseline_candidate_set_sha256': refresh['baseline_candidate_set_sha256'],
    'fresh_candidate_set_sha256': digest,
    'target_kernel': refresh['target_kernel'],
    'fresh_candidate_count': len(all_candidates),
    'added_candidate_count': len(added),
    'removed_candidate_count': len(removed),
    'added_candidates': added,
    'removed_candidates': removed,
    'categories': categories,
    'category_counts': policy['category_counts'],
    'all_added_candidates_are_upgrade_all': True,
    'critical_candidates_absent': True,
    'kernel_transaction_candidates': fresh_kernel,
    'kernel_transaction_changed': False,
    'strict_candidate_superset': True,
    'review_scope': policy['review_scope'],
    'package_payloads_inspected': False,
    'userspace_apply_review_complete': False,
    'kernel_evidence_rebind_ready': True,
    'next_stage': 'current-kernel-evidence-rebind-preflight',
    'normal_update_apply_executed': False,
    'package_transaction_executed': False,
    'initrd_generation_executed': False,
    'dkms_action_executed': False,
    'grub_update_executed': False,
    'apply_ready': False,
    'apply_authorized': False,
}
pathlib.Path(output_path).write_text(json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

verify_nested_archive() {
    local nested_root=$1 archive sidecar
    archive=$(find "$nested_root" -maxdepth 1 -type f -name 'normal-update.tar.gz' -print)
    sidecar=$(find "$nested_root" -maxdepth 1 -type f -name 'normal-update.tar.gz.sha256' -print)
    [ -n "$archive" ] && [ -n "$sidecar" ] || return 1
    [ "$(printf '%s\n' "$archive" | wc -l)" -eq 1 ] || return 1
    [ "$(printf '%s\n' "$sidecar" | wc -l)" -eq 1 ] || return 1
    (cd "$nested_root" && sha256sum -c "${archive##*/}.sha256" >/dev/null 2>&1)
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-userspace-candidate-review-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
fresh_candidate_set_sha256=$FRESH_CANDIDATE_SHA256
target_kernel=$TARGET_KERNEL
fresh_candidate_count=137
added_candidate_count=$ADDED_CANDIDATE_COUNT
removed_candidate_count=0
plasma_candidate_count=$PLASMA_CANDIDATE_COUNT
supporting_candidate_count=$SUPPORTING_CANDIDATE_COUNT
boot_adjacent_candidate_count=$BOOT_ADJACENT_CANDIDATE_COUNT
review_scope=candidate-identity-for-kernel-evidence-rebind
userspace_apply_review_complete=false
kernel_evidence_rebind_ready=$KERNEL_EVIDENCE_REBIND_READY
next_stage=$NEXT_STAGE
normal_update_apply_executed=false
package_transaction_executed=false
initrd_generation_executed=false
dkms_action_executed=false
grub_update_executed=false
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-userspace-candidate-review-preflight-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive"
    (cd "$(dirname -- "$archive")" && sha256sum -- "$(basename -- "$archive")" > "$(basename -- "$sidecar")") || return 1
    chmod 0600 -- "$sidecar"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    [ "$owner" != root ] || owner=promano
    if id "$owner" >/dev/null 2>&1; then
        group=$(id -gn "$owner")
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
            "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
        printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${sidecar##*/}"
    fi
}

main() {
    local timestamp nested_root nested_dir nested_exit values archive
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk bash cmp date find id python3 readlink sed sha256sum stat tar uname wc; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command unavailable: $command_name"; return 2; }
    done
    for path in "$NORMAL_UPDATE_SCRIPT" "$BASELINE_PREFLIGHT" "$REFRESH_RECORD" "$REVIEW_POLICY"; do
        [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ] || { error "unsafe or unreadable input: $path"; return 2; }
    done
    bash -n "$NORMAL_UPDATE_SCRIPT" || { error 'normal-update script has invalid syntax'; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"
    RUNNING_KERNEL=$(uname -r)

    if values=$(validate_accepted_records); then
        FRESH_CANDIDATE_SHA256=$(printf '%s\n' "$values" | sed -n '1p')
        TARGET_KERNEL=$(printf '%s\n' "$values" | sed -n '2p')
        ADDED_CANDIDATE_COUNT=$(printf '%s\n' "$values" | sed -n '3p')
        PLASMA_CANDIDATE_COUNT=$(printf '%s\n' "$values" | sed -n '4p')
        SUPPORTING_CANDIDATE_COUNT=$(printf '%s\n' "$values" | sed -n '5p')
        BOOT_ADJACENT_CANDIDATE_COUNT=$(printf '%s\n' "$values" | sed -n '6p')
        record_pass 'the accepted candidate refresh and explicit userspace review policy bind the 137-candidate transaction'
    else
        record_failure 'the accepted candidate refresh or userspace review policy is inconsistent, stale, or unsafe'
    fi
    if [ "$FRESH_CANDIDATE_SHA256" = "$CONFIRM_CANDIDATES_SHA256" ] && [ "$TARGET_KERNEL" = "$CONFIRM_TARGET_KERNEL" ]; then
        record_pass 'the explicit candidate digest and target kernel match the reviewed userspace expansion'
    else
        record_failure 'the explicit candidate digest or target kernel differs from the reviewed userspace expansion'
    fi
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the package database and boot state were captured before userspace review' \
        || record_failure 'the initial package or boot state could not be captured safely'

    nested_root=$OUTPUT_DIR/nested
    nested_dir=$nested_root/normal-update
    mkdir -p -- "$nested_root" || return 2
    printf 'Running a fresh non-installing normal-update preflight for userspace candidate review...\n'
    bash "$NORMAL_UPDATE_SCRIPT" --target slackware-current --preflight --output-dir "$nested_dir" \
        > "$OUTPUT_DIR/normal-update.stdout.log" 2> "$OUTPUT_DIR/normal-update.stderr.log"
    nested_exit=$?
    printf '%s\n' "$nested_exit" > "$OUTPUT_DIR/normal-update.exit"
    cat "$OUTPUT_DIR/normal-update.stdout.log"
    [ -s "$OUTPUT_DIR/normal-update.stderr.log" ] && cat "$OUTPUT_DIR/normal-update.stderr.log" >&2 || true
    if [ "$nested_exit" -eq 0 ]; then
        record_pass 'the embedded normal-update preflight completed without authorizing package installation'
    else
        record_failure "the embedded normal-update preflight failed with exit code $nested_exit"
    fi
    if [ "$nested_exit" -eq 0 ] && analyze_fresh_review "$nested_dir" "$OUTPUT_DIR/userspace-review-analysis.json"; then
        record_pass 'the fresh 137-candidate set exactly matches the reviewed 68-package userspace expansion'
        record_pass 'the reviewed categories contain 61 Plasma packages, six supporting packages, and one GRUB theme package'
        KERNEL_EVIDENCE_REBIND_READY=true
        NEXT_STAGE=current-kernel-evidence-rebind-preflight
        record_pass 'the exact kernel transaction remains unchanged and is eligible for explicit evidence rebind'
    else
        record_failure 'the fresh candidate set or userspace category boundary could not be reviewed safely'
    fi
    if verify_nested_archive "$nested_root"; then
        record_pass 'the nested normal-update evidence archive and portable sidecar verify inside the review evidence'
    else
        record_failure 'the nested normal-update archive or portable sidecar is missing, ambiguous, or invalid'
    fi
    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the package database and boot state were captured after userspace review' \
        || record_failure 'the final package or boot state could not be captured safely'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during userspace review' \
        || record_failure 'the installed package database changed during userspace review'
    cmp -s "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the active boot state remained unchanged during userspace review' \
        || record_failure 'the active boot state changed during userspace review'

    [ "$FAILURE_COUNT" -eq 0 ] || { KERNEL_EVIDENCE_REBIND_READY=false; NEXT_STAGE=manual-review-required; }
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current userspace candidate review result: candidates=%s, added=%s, plasma=%s, supporting=%s, boot-adjacent=%s, target-kernel=%s, kernel-evidence-rebind-ready=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "${FRESH_CANDIDATE_SHA256:-unavailable}" "$ADDED_CANDIDATE_COUNT" "$PLASMA_CANDIDATE_COUNT" "$SUPPORTING_CANDIDATE_COUNT" "$BOOT_ADJACENT_CANDIDATE_COUNT" "${TARGET_KERNEL:-unavailable}" "$KERNEL_EVIDENCE_REBIND_READY" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
