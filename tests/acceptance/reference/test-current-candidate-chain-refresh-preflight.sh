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
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-candidate-chain-refresh-preflight

TARGET=
NORMAL_UPDATE_SCRIPT=$DEFAULT_NORMAL_UPDATE_SCRIPT
BASELINE_PREFLIGHT=$DEFAULT_BASELINE_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
RUNNING_KERNEL=
BASELINE_CANDIDATE_SHA256=
FRESH_CANDIDATE_SHA256=
CHAIN_STATUS=unresolved
NEXT_STAGE=unresolved
TARGET_KERNEL=none
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current [options]

Refresh Slackware-current metadata through the existing normal-update preflight,
compare the exact candidate set with the last accepted transaction chain, and
classify whether the reviewed kernel evidence remains candidate-bound or must be
repeated. This wrapper permits only the non-installing --preflight mode. It never
runs --execute-apply, installs packages, generates an initrd, or changes GRUB.

Required options:
      --target slackware-current

Optional arguments:
      --normal-update-script PATH
      --baseline-preflight PATH
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
            --normal-update-script) [ "$#" -ge 2 ] || return 1; NORMAL_UPDATE_SCRIPT=$2; shift 2 ;;
            --baseline-preflight) [ "$#" -ge 2 ] || return 1; BASELINE_PREFLIGHT=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    for path in "$NORMAL_UPDATE_SCRIPT" "$BASELINE_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_baseline_record() {
    python3 - "$BASELINE_PREFLIGHT" <<'PY'
import json, re, sys
try:
    data = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    raise SystemExit(1)
c = data.get('candidates', {})
digest = c.get('candidate_set_sha256', '')
target = c.get('target_kernel_version', '')
checks = [
    data.get('scenario') == 'normal-update',
    data.get('mode') == 'preflight',
    data.get('target') == 'slackware-current',
    data.get('accepted') is True,
    data.get('apply_authorized') is False,
    isinstance(c.get('install_new'), list),
    isinstance(c.get('upgrade_all'), list),
    isinstance(c.get('total'), int),
    re.fullmatch(r'[0-9a-f]{64}', digest) is not None,
    re.fullmatch(r'[A-Za-z0-9._+-]+', target) is not None,
]
if not all(checks):
    raise SystemExit(1)
print(digest)
print(target)
PY
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
        /boot/initrd.gz \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/mkinitrd.conf; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

analyze_refresh() {
    local baseline=$1 fresh_dir=$2 output=$3
    python3 - "$baseline" "$fresh_dir" "$output" "$RUNNING_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
baseline_path, fresh_dir, output_path, running = sys.argv[1:]
fresh = pathlib.Path(fresh_dir)
try:
    baseline = json.load(open(baseline_path, encoding='utf-8'))
    summary = dict(
        line.rstrip('\n').split('=', 1)
        for line in open(fresh/'summary.txt', encoding='utf-8')
        if '=' in line
    )
except Exception:
    raise SystemExit(1)

def read_list(name):
    p = fresh/name
    if not p.is_file():
        raise SystemExit(1)
    values = [line.strip() for line in p.read_text(encoding='utf-8').splitlines() if line.strip()]
    if values != sorted(set(values)):
        raise SystemExit(1)
    for value in values:
        if '/' in value or value.startswith('.') or any(ord(ch) < 32 for ch in value):
            raise SystemExit(1)
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9+._-]*\.t(?:xz|gz|lz|bz)', value):
            raise SystemExit(1)
    return values

def package_parts(filename):
    stem = re.sub(r'\.t(?:xz|gz|lz|bz)$', '', filename)
    parts = stem.rsplit('-', 3)
    if len(parts) != 4:
        raise ValueError(filename)
    name, version, arch, build = parts
    if not name or not version or not arch or not build:
        raise ValueError(filename)
    return name, version, arch, build

def kernel_transaction(values):
    parsed = [(item, *package_parts(item)) for item in values]
    generic = [(item, version) for item, name, version, arch, build in parsed if name == 'kernel-generic']
    headers = [(item, version) for item, name, version, arch, build in parsed if name == 'kernel-headers']
    source = [(item, version) for item, name, version, arch, build in parsed if name == 'kernel-source']
    exact = sorted([item for item, *_ in generic + headers + source])
    target = generic[0][1] if len(generic) == 1 else None
    complete = (
        len(generic) == 1
        and len(headers) == 1
        and len(source) == 1
        and headers[0][1] == target
        and source[0][1] == target
    )
    empty = not generic and not headers and not source
    return {
        'generic': generic,
        'headers': headers,
        'source': source,
        'exact': exact,
        'target': target,
        'complete': complete,
        'empty': empty,
    }

install = read_list('install-new.candidates.txt')
upgrade = read_list('upgrade-all.candidates.txt')
all_candidates = read_list('all.candidates.txt')
critical = read_list('critical.candidates.txt')
if set(install) & set(upgrade):
    raise SystemExit(1)
if all_candidates != sorted(set(install + upgrade)):
    raise SystemExit(1)
if not set(critical).issubset(set(all_candidates)):
    raise SystemExit(1)
try:
    summary_counts = (
        int(summary.get('install_new_candidates', '-1')),
        int(summary.get('upgrade_candidates', '-1')),
        int(summary.get('total_candidates', '-1')),
        int(summary.get('critical_candidates', '-1')),
    )
except ValueError:
    raise SystemExit(1)
if summary_counts != (len(install), len(upgrade), len(all_candidates), len(critical)):
    raise SystemExit(1)
raw = ''.join(f'{item}\n' for item in all_candidates).encode()
fresh_digest = hashlib.sha256(raw).hexdigest()
if fresh_digest != summary.get('candidate_set_sha256'):
    raise SystemExit(1)
if summary.get('result') != 'PASS' or summary.get('failures') != '0':
    raise SystemExit(1)

base_candidates = baseline.get('candidates', {})
base_install = base_candidates.get('install_new', [])
base_upgrade = base_candidates.get('upgrade_all', [])
if not isinstance(base_install, list) or not isinstance(base_upgrade, list):
    raise SystemExit(1)
base_all = sorted(set(base_install + base_upgrade))
base_digest = base_candidates.get('candidate_set_sha256')
if hashlib.sha256(''.join(f'{item}\n' for item in base_all).encode()).hexdigest() != base_digest:
    raise SystemExit(1)
for value in base_all:
    package_parts(value)

added = sorted(set(all_candidates) - set(base_all))
removed = sorted(set(base_all) - set(all_candidates))
base_kernel = kernel_transaction(base_all)
fresh_kernel = kernel_transaction(all_candidates)
kernel_changed = fresh_kernel['exact'] != base_kernel['exact']
strict_superset = bool(added) and not removed and set(base_all).issubset(set(all_candidates))
userspace_only_change = fresh_digest != base_digest and not kernel_changed

status = 'unsupported'
next_stage = 'manual-review-required'
target = fresh_kernel['target'] or base_kernel['target']
companions = fresh_kernel['complete']
prior_chain_reusable = False
kernel_evidence_rebind_possible = False

if not all_candidates:
    status = 'no-updates'
    next_stage = 'no-updates-acceptance'
elif critical:
    status = 'critical-candidates-present'
    next_stage = 'manual-review-required'
elif len(fresh_kernel['generic']) > 1:
    status = 'ambiguous-kernel-target'
elif not fresh_kernel['complete'] and not fresh_kernel['empty']:
    status = 'incomplete-kernel-companion-set'
elif kernel_changed:
    status = 'changed-kernel-set'
    next_stage = 'repeat-current-kernel-evidence-chain'
elif fresh_digest == base_digest:
    if fresh_kernel['complete']:
        status = 'unchanged-reviewed-kernel-set'
        next_stage = 'current-transaction-readiness-dry-run'
    else:
        status = 'unchanged-reviewed-userspace-set'
        next_stage = 'current-userspace-readiness-review'
    prior_chain_reusable = True
else:
    status = 'changed-userspace-set'
    next_stage = 'review-fresh-userspace-candidates'
    kernel_evidence_rebind_possible = fresh_kernel['complete'] and base_kernel['complete']

result = {
    'scenario': 'current-candidate-chain-refresh-preflight',
    'target': 'slackware-current',
    'running_kernel': running,
    'baseline_candidate_set_sha256': base_digest,
    'fresh_candidate_set_sha256': fresh_digest,
    'candidate_set_changed': fresh_digest != base_digest,
    'baseline_candidate_count': len(base_all),
    'fresh_candidate_count': len(all_candidates),
    'install_new_count': len(install),
    'upgrade_all_count': len(upgrade),
    'critical_candidate_count': len(critical),
    'critical_candidates': critical,
    'added_candidate_count': len(added),
    'removed_candidate_count': len(removed),
    'added_candidates': added,
    'removed_candidates': removed,
    'strict_candidate_superset': strict_superset,
    'userspace_only_candidate_change': userspace_only_change,
    'baseline_kernel_candidates': base_kernel['exact'],
    'fresh_kernel_candidates': fresh_kernel['exact'],
    'kernel_transaction_changed': kernel_changed,
    'kernel_generic_candidates': [x[0] for x in fresh_kernel['generic']],
    'kernel_headers_candidates': [x[0] for x in fresh_kernel['headers']],
    'kernel_source_candidates': [x[0] for x in fresh_kernel['source']],
    'target_kernel': target,
    'kernel_companion_set_complete': companions,
    'chain_status': status,
    'prior_candidate_bound_chain_reusable': prior_chain_reusable,
    'kernel_evidence_rebind_possible_after_userspace_review': kernel_evidence_rebind_possible,
    'next_stage': next_stage,
    'normal_update_preflight_passed': True,
    'normal_update_apply_executed': False,
    'package_transaction_executed': False,
    'initrd_generation_executed': False,
    'grub_update_executed': False,
    'apply_ready': False,
    'apply_authorized': False,
}
pathlib.Path(output_path).write_text(json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-candidate-chain-refresh-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
baseline_candidate_set_sha256=$BASELINE_CANDIDATE_SHA256
fresh_candidate_set_sha256=$FRESH_CANDIDATE_SHA256
chain_status=$CHAIN_STATUS
target_kernel=$TARGET_KERNEL
next_stage=$NEXT_STAGE
normal_update_apply_executed=false
package_transaction_executed=false
initrd_generation_executed=false
grub_update_executed=false
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group home
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-candidate-chain-refresh-preflight-${timestamp}.tar.gz"
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
        home=$(awk -F: -v owner="$owner" '$1 == owner {print $6; exit}' /etc/passwd)
        [ -n "$home" ] || home="/home/$owner"
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "$home/${archive##*/}" \
            "$owner" "$group" "$sidecar" "$home/${sidecar##*/}"
        printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "$home" "${sidecar##*/}"
    fi
}

main() {
    local timestamp normal_dir normal_status baseline_info
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in bash python3 sha256sum tar find cmp stat readlink awk; do
        command -v "$command" >/dev/null 2>&1 || { error "required command missing: $command"; return 2; }
    done
    [ -f "$NORMAL_UPDATE_SCRIPT" ] && [ ! -L "$NORMAL_UPDATE_SCRIPT" ] && [ -r "$NORMAL_UPDATE_SCRIPT" ] || { error 'normal-update script is unsafe or unreadable'; return 2; }
    bash -n "$NORMAL_UPDATE_SCRIPT" || { error 'normal-update script has invalid syntax'; return 2; }
    [ -f "$BASELINE_PREFLIGHT" ] && [ ! -L "$BASELINE_PREFLIGHT" ] && [ -r "$BASELINE_PREFLIGHT" ] || { error 'baseline preflight is unsafe or unreadable'; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"
    RUNNING_KERNEL=$(uname -r)

    if baseline_info=$(validate_baseline_record); then
        BASELINE_CANDIDATE_SHA256=$(printf '%s\n' "$baseline_info" | sed -n '1p')
        record_pass 'the accepted Slackware-current candidate baseline is safe and explicitly unauthorized'
    else
        record_failure 'the accepted Slackware-current candidate baseline is invalid or unsafe'
    fi
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the package database and boot state were captured before metadata refresh' \
        || record_failure 'the initial package or boot state could not be captured'

    normal_dir=$OUTPUT_DIR/normal-update
    printf 'Running a fresh non-installing normal-update preflight...\n'
    bash "$NORMAL_UPDATE_SCRIPT" --target slackware-current --preflight --output-dir "$normal_dir" \
        2> >(tee "$OUTPUT_DIR/normal-update.stderr.log" >&2) \
        | tee "$OUTPUT_DIR/normal-update.stdout.log" \
        | sed -e '/^Evidence archive:/d' \
              -e '/^Evidence SHA-256:/d' \
              -e '/^Copy evidence command:/d' \
              -e '/^Verify evidence command:/d'
    normal_status=${PIPESTATUS[0]}
    printf '%s\n' "$normal_status" > "$OUTPUT_DIR/normal-update.exit"
    if [ "$normal_status" -eq 0 ]; then
        record_pass 'the embedded normal-update preflight completed without authorizing package installation'
    else
        record_failure "the embedded normal-update preflight failed with status $normal_status"
    fi

    if [ "$normal_status" -eq 0 ] && analyze_refresh "$BASELINE_PREFLIGHT" "$normal_dir" "$OUTPUT_DIR/chain-analysis.json"; then
        FRESH_CANDIDATE_SHA256=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["fresh_candidate_set_sha256"])' "$OUTPUT_DIR/chain-analysis.json")
        CHAIN_STATUS=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chain_status"])' "$OUTPUT_DIR/chain-analysis.json")
        NEXT_STAGE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["next_stage"])' "$OUTPUT_DIR/chain-analysis.json")
        TARGET_KERNEL=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("target_kernel") or "none")' "$OUTPUT_DIR/chain-analysis.json")
        record_pass 'the fresh candidate set was parsed, hashed, and compared with the accepted chain'
        case "$CHAIN_STATUS" in
            unchanged-reviewed-kernel-set|unchanged-reviewed-userspace-set|changed-kernel-set|changed-userspace-set|no-updates)
                record_pass "the refreshed candidate chain was classified safely as $CHAIN_STATUS"
                ;;
            *)
                record_failure "the refreshed candidate chain requires manual review: $CHAIN_STATUS"
                ;;
        esac
    else
        record_failure 'the refreshed candidate chain could not be analyzed safely'
    fi

    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the package database and boot state were captured after metadata refresh' \
        || record_failure 'the final package or boot state could not be captured'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during chain refresh' \
        || record_failure 'the installed package database changed during chain refresh'
    cmp -s "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the active boot state remained unchanged during chain refresh' \
        || record_failure 'the active boot state changed during chain refresh'

    APPLY_READY=false
    APPLY_AUTHORIZED=false
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current candidate chain result: baseline=%s, fresh=%s, status=%s, target-kernel=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "${BASELINE_CANDIDATE_SHA256:-unavailable}" "${FRESH_CANDIDATE_SHA256:-unavailable}" "$CHAIN_STATUS" "$TARGET_KERNEL" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
