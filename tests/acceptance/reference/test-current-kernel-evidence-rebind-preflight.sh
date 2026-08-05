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
DEFAULT_USERSPACE_REVIEW="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-userspace-candidate-review-20260805-accepted.json"
DEFAULT_REBIND_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-evidence-rebind-20260805-reviewed.json"
DEFAULT_BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
DEFAULT_CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
DEFAULT_PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
DEFAULT_POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"
DEFAULT_DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
DEFAULT_COMMAND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json"
DEFAULT_OWNERSHIP_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260805-accepted.json"
DEFAULT_POST_STATE_CONTRACT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-post-state-6.18.42-synthetic.json"
DEFAULT_REFERENCE_ENGINE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-kernel-evidence-rebind-preflight
DEFAULT_PACKAGE_CACHE_ROOT=/var/cache/packages

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
NORMAL_UPDATE_SCRIPT=$DEFAULT_NORMAL_UPDATE_SCRIPT
BASELINE_PREFLIGHT=$DEFAULT_BASELINE_PREFLIGHT
REFRESH_RECORD=$DEFAULT_REFRESH_RECORD
USERSPACE_REVIEW=$DEFAULT_USERSPACE_REVIEW
REBIND_POLICY=$DEFAULT_REBIND_POLICY
BOOT_PREFLIGHT=$DEFAULT_BOOT_PREFLIGHT
CHAIN_PREFLIGHT=$DEFAULT_CHAIN_PREFLIGHT
PACKAGE_PREFLIGHT=$DEFAULT_PACKAGE_PREFLIGHT
POLICY_PREFLIGHT=$DEFAULT_POLICY_PREFLIGHT
DKMS_PREFLIGHT=$DEFAULT_DKMS_PREFLIGHT
COMMAND_PREFLIGHT=$DEFAULT_COMMAND_PREFLIGHT
OWNERSHIP_PREFLIGHT=$DEFAULT_OWNERSHIP_PREFLIGHT
POST_STATE_CONTRACT=$DEFAULT_POST_STATE_CONTRACT
REFERENCE_ENGINE=$DEFAULT_REFERENCE_ENGINE
PACKAGE_CACHE_ROOT=$DEFAULT_PACKAGE_CACHE_ROOT
SYSTEM_ROOT=/
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
SOURCE_CANDIDATE_SHA256=
REBIND_CANDIDATE_SHA256=
FRESH_CANDIDATE_SHA256=
RUNNING_KERNEL=
TARGET_KERNEL=
PACKAGE_FILENAME=
PACKAGE_SHA256=
ACTIVE_POLICY_SHA256=
GENINITRD_SHA256=
COMMAND_GENERATOR_SHA256=
SETUP_SHA256=
GENERIC_KERNEL_SHA256=
CURRENT_NAMED_INITRD=
CURRENT_NAMED_INITRD_TARGET=
CURRENT_VERSIONED_INITRD=
CURRENT_VERSIONED_INITRD_SHA256=
CURRENT_VERSIONED_INITRD_SIZE=
ACTIVE_GRUB_SHA256=
HOOK_BCACHEFS_SHA256=
HOOK_NVIDIA_SHA256=
KERNEL_EVIDENCE_REBOUND=false
NEXT_STAGE=manual-review-required

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Rebind the accepted Slackware-current kernel evidence chain from the reviewed
69-candidate digest to an exact 137-candidate userspace-only expansion. This
preflight refreshes metadata, proves that the kernel transaction and live
GenInitrd state remain unchanged, and emits a new candidate-binding record. It
never installs packages, runs maintainer scripts, generates an initrd, invokes
DKMS build actions, or changes GRUB.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-update-script PATH
      --output-dir PATH
      --package-cache-root PATH
      --system-root PATH
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

root_path() {
    local path=$1
    if [ "$SYSTEM_ROOT" = / ]; then
        printf '%s' "$path"
    else
        printf '%s%s' "${SYSTEM_ROOT%/}" "$path"
    fi
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-candidates-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CANDIDATES_SHA256=$2; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --normal-update-script) [ "$#" -ge 2 ] || return 1; NORMAL_UPDATE_SCRIPT=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            --package-cache-root) [ "$#" -ge 2 ] || return 1; PACKAGE_CACHE_ROOT=$2; shift 2 ;;
            --system-root) [ "$#" -ge 2 ] || return 1; SYSTEM_ROOT=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    for path in "$NORMAL_UPDATE_SCRIPT" "$PACKAGE_CACHE_ROOT" "$SYSTEM_ROOT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_accepted_records() {
    local values
    values=$(python3 - \
        "$BASELINE_PREFLIGHT" "$REFRESH_RECORD" "$USERSPACE_REVIEW" "$REBIND_POLICY" \
        "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" \
        "$DKMS_PREFLIGHT" "$COMMAND_PREFLIGHT" "$OWNERSHIP_PREFLIGHT" \
        "$POST_STATE_CONTRACT" "$REFERENCE_ENGINE" \
        "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
(
    baseline_path, refresh_path, review_path, rebind_path, boot_path, chain_path,
    package_path, policy_path, dkms_path, command_path, ownership_path,
    post_path, engine_path, confirmed_digest, confirmed_target,
) = sys.argv[1:]
try:
    baseline = json.load(open(baseline_path, encoding='utf-8'))
    refresh = json.load(open(refresh_path, encoding='utf-8'))
    review = json.load(open(review_path, encoding='utf-8'))
    rebind = json.load(open(rebind_path, encoding='utf-8'))
    boot = json.load(open(boot_path, encoding='utf-8'))
    chain = json.load(open(chain_path, encoding='utf-8'))
    package = json.load(open(package_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
    dkms = json.load(open(dkms_path, encoding='utf-8'))
    command = json.load(open(command_path, encoding='utf-8'))
    ownership = json.load(open(ownership_path, encoding='utf-8'))
    post = json.load(open(post_path, encoding='utf-8'))
    engine_bytes = pathlib.Path(engine_path).read_bytes()
except Exception:
    raise SystemExit(1)

def digest(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None

def denied(record):
    return record.get('apply_ready') is False and record.get('apply_authorized') is False

old_digest = baseline.get('candidates', {}).get('candidate_set_sha256')
new_digest = refresh.get('fresh_candidate_set_sha256')
running = boot.get('running_kernel')
target = boot.get('target_kernel')
archives = {
    'boot_preflight': boot.get('archive_sha256'),
    'chain_restart': chain.get('archive_sha256'),
    'package_preflight': package.get('archive_sha256'),
    'policy_preflight': policy.get('archive_sha256'),
    'dkms_preflight': dkms.get('archive_sha256'),
    'command_preflight': command.get('archive_sha256'),
    'grub_ownership_preflight': ownership.get('archive_sha256'),
}
expected_kernel = [
    f'kernel-generic-{target}-x86_64-1.txz',
    f'kernel-headers-{target}-x86-1.txz',
    f'kernel-source-{target}-noarch-1.txz',
]
package_data = package.get('package', {})
policy_data = policy.get('policy', {})
dkms_data = dkms.get('dkms', {})
constraints = rebind.get('rebind_constraints', {})
checks = [
    baseline.get('scenario') == 'normal-update', baseline.get('accepted') is True, denied(baseline),
    digest(old_digest), baseline.get('candidates', {}).get('total') == 69,
    refresh.get('scenario') == 'current-candidate-chain-refresh-preflight', refresh.get('accepted') is True, denied(refresh),
    digest(new_digest), new_digest == confirmed_digest,
    refresh.get('baseline_candidate_set_sha256') == old_digest,
    refresh.get('fresh_candidate_count') == 137,
    refresh.get('chain_status') == 'changed-userspace-set',
    refresh.get('kernel_transaction_changed') is False,
    refresh.get('strict_candidate_superset') is True,
    refresh.get('fresh_kernel_candidates') == expected_kernel,
    review.get('scenario') == 'current-userspace-candidate-review-preflight', review.get('accepted') is True, denied(review),
    review.get('baseline_candidate_set_sha256') == old_digest,
    review.get('fresh_candidate_set_sha256') == new_digest,
    review.get('target_kernel') == confirmed_target,
    review.get('running_kernel') == running,
    review.get('fresh_candidate_count') == 137,
    review.get('added_candidate_count') == 68,
    review.get('removed_candidate_count') == 0,
    review.get('kernel_transaction_candidates') == expected_kernel,
    review.get('kernel_transaction_changed') is False,
    review.get('kernel_evidence_rebind_ready') is True,
    review.get('package_payloads_inspected') is False,
    review.get('userspace_apply_review_complete') is False,
    review.get('assertions') == {'passes': 11, 'failures': 0},
    review.get('evidence', {}).get('copied_to') == '/home/promano',
    review.get('evidence', {}).get('destination_verification') == 'passed',
    digest(review.get('archive_sha256')), digest(review.get('nested_normal_update_archive_sha256')),
    rebind.get('scenario') == 'current-kernel-evidence-rebind-policy', rebind.get('reviewed') is True, denied(rebind),
    rebind.get('source_candidate_set_sha256') == old_digest,
    rebind.get('rebound_candidate_set_sha256') == new_digest,
    rebind.get('accepted_userspace_review_archive_sha256') == review.get('archive_sha256'),
    rebind.get('accepted_userspace_review_nested_archive_sha256') == review.get('nested_normal_update_archive_sha256'),
    rebind.get('running_kernel') == running,
    rebind.get('target_kernel') == confirmed_target == target,
    rebind.get('boot_mode') == 'geninitrd-managed-versioned-initrd',
    rebind.get('transition_mode') == 'versioned-to-versioned-initrd',
    rebind.get('kernel_transaction_candidates') == expected_kernel,
    rebind.get('accepted_evidence_archive_sha256') == archives,
    all(constraints.get(name) is True for name in (
        'accepted_userspace_review_required', 'exact_kernel_transaction_unchanged',
        'live_kernel_and_initrd_state_unchanged', 'exact_cached_kernel_package_required',
        'dkms_noop_state_required', 'same_grub_kernel_initrd_pair_required',
        'only_candidate_binding_may_change')),
    rebind.get('package_payloads_inspected') is False,
    rebind.get('userspace_apply_review_complete') is False,
    rebind.get('kernel_evidence_rebind_review_complete') is True,
    rebind.get('kernel_evidence_rebind_allowed') is True,
    rebind.get('kernel_evidence_rebound') is False,
    rebind.get('next_stage') == 'current-userspace-payload-review-preflight',
    boot.get('scenario') == 'current-kernel-boot-preflight', boot.get('accepted') is True, denied(boot),
    boot.get('normal_update_candidate_set_sha256') == old_digest,
    boot.get('boot_mode') == 'geninitrd-managed-versioned-initrd',
    boot.get('target_kernel') == target,
    boot.get('geninitrd_transition_required') is True,
    chain.get('scenario') == 'current-kernel-chain-restart-preflight', chain.get('accepted') is True, denied(chain),
    chain.get('candidate_set_sha256') == old_digest,
    chain.get('accepted_boot_archive_sha256') == archives['boot_preflight'],
    chain.get('nested_boot_mode') == boot.get('boot_mode'),
    chain.get('nested_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    package.get('scenario') == 'current-kernel-package-preflight', package.get('accepted') is True, denied(package),
    package.get('normal_update_candidate_set_sha256') == old_digest,
    package.get('boot_preflight_archive_sha256') == archives['boot_preflight'],
    package.get('chain_restart_archive_sha256') == archives['chain_restart'],
    package.get('target_kernel') == target,
    package_data.get('filename') == expected_kernel[0], digest(package_data.get('sha256')),
    package_data.get('paths_safe') is True, package_data.get('embedded_initrd_count') == 0,
    policy.get('scenario') == 'current-geninitrd-policy-preflight', policy.get('accepted') is True, denied(policy),
    policy.get('normal_update_candidate_set_sha256') == old_digest,
    policy.get('package_preflight_archive_sha256') == archives['package_preflight'],
    policy_data.get('transition_mode') == 'versioned-to-versioned-initrd',
    policy_data.get('autogenerate_initrd') is True, policy_data.get('named_symlink') is True,
    policy_data.get('initrd_gz_symlink') is False, policy_data.get('auto_update_grub') is True,
    dkms.get('scenario') == 'current-geninitrd-dkms-hook-preflight', dkms.get('accepted') is True, denied(dkms),
    dkms.get('normal_update_candidate_set_sha256') == old_digest,
    dkms.get('policy_preflight_archive_sha256') == archives['policy_preflight'],
    dkms.get('transition_mode') == 'versioned-to-versioned-initrd',
    dkms_data.get('status_row_count') == 0, dkms_data.get('var_lib_dkms_state') == 'empty',
    dkms.get('review_status') == 'accepted-noop-hooks',
    command.get('scenario') == 'current-geninitrd-command-preflight', command.get('accepted') is True, denied(command),
    command.get('normal_update_candidate_set_sha256') == old_digest,
    command.get('dkms_preflight_archive_sha256') == archives['dkms_preflight'],
    command.get('transition_mode') == 'versioned-to-versioned-initrd',
    command.get('projected_initrd') == f'/boot/initrd-{target}.img',
    command.get('package', {}).get('observed_sha256') == package_data.get('sha256'),
    command.get('module_count') == 18,
    ownership.get('scenario') == 'current-geninitrd-grub-ownership-preflight', ownership.get('accepted') is True, denied(ownership),
    ownership.get('normal_update_candidate_set_sha256') == old_digest,
    ownership.get('command_preflight_archive_sha256') == archives['command_preflight'],
    ownership.get('transition_mode') == 'versioned-to-versioned-initrd',
    ownership.get('strategy') == 'temporary-atomic-policy-override',
    ownership.get('environment_override_safe') is False,
    ownership.get('transaction', {}).get('step_count') == 12,
    ownership.get('transaction', {}).get('recovery_boundary_count') == 5,
    post.get('scenario') == 'current-geninitrd-post-state', post.get('synthetic') is True,
    post.get('accepted') is False, denied(post),
    post.get('normal_update_candidate_set_sha256') == old_digest,
    post.get('target_kernel') == target,
    post.get('pre_transaction_layout') == 'geninitrd-managed-versioned-initrd',
    post.get('transition_mode') == 'versioned-to-versioned-initrd',
    post.get('reference_engine_sha256') == hashlib.sha256(engine_bytes).hexdigest(),
]
if not all(checks):
    raise SystemExit(1)
for value in archives.values():
    if not digest(value):
        raise SystemExit(1)
hooks = {item.get('path'): item.get('sha256') for item in dkms.get('hooks', [])}
for path in ('/etc/geninitrd.d/pre-install/dkms-bcachefs', '/etc/geninitrd.d/pre-install/dkms-nvidia'):
    if not digest(hooks.get(path)):
        raise SystemExit(1)
print(old_digest)
print(new_digest)
print(running)
print(target)
print(package_data.get('filename', ''))
print(package_data.get('sha256', ''))
print(ownership.get('active_policy', {}).get('sha256', ''))
print(policy.get('scripts', {}).get('geninitrd_sha256', ''))
print(command.get('generator', {}).get('sha256', ''))
print(policy.get('scripts', {}).get('setup_sha256', ''))
print(boot.get('generic_kernel_sha256', ''))
print(boot.get('named_initrd_path', ''))
print(boot.get('named_initrd_target', ''))
print(boot.get('versioned_initrd_path', ''))
print(boot.get('versioned_initrd_sha256', ''))
print(boot.get('versioned_initrd_size', 0))
print(boot.get('active_grub_sha256', ''))
print(hooks['/etc/geninitrd.d/pre-install/dkms-bcachefs'])
print(hooks['/etc/geninitrd.d/pre-install/dkms-nvidia'])
PY
) || return 1
    SOURCE_CANDIDATE_SHA256=$(printf '%s\n' "$values" | sed -n '1p')
    REBIND_CANDIDATE_SHA256=$(printf '%s\n' "$values" | sed -n '2p')
    RUNNING_KERNEL=$(printf '%s\n' "$values" | sed -n '3p')
    TARGET_KERNEL=$(printf '%s\n' "$values" | sed -n '4p')
    PACKAGE_FILENAME=$(printf '%s\n' "$values" | sed -n '5p')
    PACKAGE_SHA256=$(printf '%s\n' "$values" | sed -n '6p')
    ACTIVE_POLICY_SHA256=$(printf '%s\n' "$values" | sed -n '7p')
    GENINITRD_SHA256=$(printf '%s\n' "$values" | sed -n '8p')
    COMMAND_GENERATOR_SHA256=$(printf '%s\n' "$values" | sed -n '9p')
    SETUP_SHA256=$(printf '%s\n' "$values" | sed -n '10p')
    GENERIC_KERNEL_SHA256=$(printf '%s\n' "$values" | sed -n '11p')
    CURRENT_NAMED_INITRD=$(printf '%s\n' "$values" | sed -n '12p')
    CURRENT_NAMED_INITRD_TARGET=$(printf '%s\n' "$values" | sed -n '13p')
    CURRENT_VERSIONED_INITRD=$(printf '%s\n' "$values" | sed -n '14p')
    CURRENT_VERSIONED_INITRD_SHA256=$(printf '%s\n' "$values" | sed -n '15p')
    CURRENT_VERSIONED_INITRD_SIZE=$(printf '%s\n' "$values" | sed -n '16p')
    ACTIVE_GRUB_SHA256=$(printf '%s\n' "$values" | sed -n '17p')
    HOOK_BCACHEFS_SHA256=$(printf '%s\n' "$values" | sed -n '18p')
    HOOK_NVIDIA_SHA256=$(printf '%s\n' "$values" | sed -n '19p')
    is_sha256 "$SOURCE_CANDIDATE_SHA256" && is_sha256 "$REBIND_CANDIDATE_SHA256" \
        && is_sha256 "$PACKAGE_SHA256" && is_sha256 "$CURRENT_VERSIONED_INITRD_SHA256"
}

capture_package_database() {
    local output=$1 root item
    root=$(root_path /var/lib/pkgtools/packages)
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

capture_sensitive_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$RUNNING_KERNEL" \
        "/boot/vmlinuz-$TARGET_KERNEL" \
        /boot/initrd-generic.img \
        "$CURRENT_VERSIONED_INITRD" \
        "/boot/initrd-$TARGET_KERNEL.img" \
        /boot/initrd.gz \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/mkinitrd.conf \
        /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia \
        /var/lib/dkms \
        "/lib/modules/$RUNNING_KERNEL" \
        "/lib/modules/$TARGET_KERNEL"; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$(root_path "$path")" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

read_scalar_assignment() {
    local file=$1 variable=$2
    python3 - "$file" "$variable" <<'PY'
import re, sys
path, variable = sys.argv[1:]
values=[]
try:
    lines=open(path, encoding='utf-8').read().splitlines()
except Exception:
    raise SystemExit(1)
pattern=re.compile(r'^\s*'+re.escape(variable)+r'\s*=\s*(.*?)\s*$')
for line in lines:
    if line.lstrip().startswith('#'):
        continue
    match=pattern.match(line)
    if match:
        value=match.group(1)
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value=value[1:-1]
        values.append(value)
if len(values) != 1:
    raise SystemExit(1)
print(values[0])
PY
}

validate_grub_kernel_initrd_pair() {
    local grub=$1 kernel=$2 initrd=$3
    python3 - "$grub" "$kernel" "$initrd" <<'PY'
import pathlib, re, sys
path, kernel, initrd = sys.argv[1:]
try:
    lines = pathlib.Path(path).read_text(encoding='utf-8', errors='strict').splitlines()
except Exception:
    raise SystemExit(1)
blocks=[]
active=None
depth=0
for line in lines:
    stripped=line.strip()
    if active is None and stripped.startswith('menuentry '):
        active=[]
        depth=0
    if active is not None:
        active.append(stripped)
        depth += stripped.count('{') - stripped.count('}')
        if depth <= 0 and len(active) > 1:
            blocks.append(active)
            active=None
for block in blocks:
    linux_ok=any(re.match(r'^linux(?:efi)?\s+', line) and kernel in line.split() for line in block)
    initrd_ok=any(re.match(r'^initrd(?:efi)?\s+', line) and initrd in line.split() for line in block)
    if linux_ok and initrd_ok:
        raise SystemExit(0)
raise SystemExit(1)
PY
}

validate_live_state() {
    local generic current_kernel target_kernel named_initrd current_initrd target_initrd
    local policy geninitrd generator setup grub package matches observed hook path expected_hook
    generic=$(root_path /boot/vmlinuz-generic)
    current_kernel=$(root_path "/boot/vmlinuz-$RUNNING_KERNEL")
    target_kernel=$(root_path "/boot/vmlinuz-$TARGET_KERNEL")
    named_initrd=$(root_path "$CURRENT_NAMED_INITRD")
    current_initrd=$(root_path "$CURRENT_VERSIONED_INITRD")
    target_initrd=$(root_path "/boot/initrd-$TARGET_KERNEL.img")
    policy=$(root_path /etc/default/geninitrd)
    geninitrd=$(root_path /usr/sbin/geninitrd)
    generator=$(root_path /usr/share/mkinitrd/mkinitrd_command_generator.sh)
    setup=$(root_path /var/lib/pkgtools/setup/setup.01.mkinitrd)
    grub=$(root_path /boot/grub/grub.cfg)
    [ "$(uname -r)" = "$RUNNING_KERNEL" ] || return 1
    [ -L "$generic" ] && [ "$(readlink -e -- "$generic")" = "$current_kernel" ] || return 1
    [ -f "$current_kernel" ] && [ ! -L "$current_kernel" ] \
        && [ "$(sha256sum -- "$current_kernel" | awk '{print $1}')" = "$GENERIC_KERNEL_SHA256" ] || return 1
    [ ! -e "$target_kernel" ] || return 1
    [ -L "$named_initrd" ] && [ "$(readlink -- "$named_initrd")" = "$CURRENT_NAMED_INITRD_TARGET" ] \
        && [ "$(readlink -e -- "$named_initrd")" = "$current_initrd" ] || return 1
    [ -f "$current_initrd" ] && [ ! -L "$current_initrd" ] \
        && [ "$(stat -c '%s' -- "$current_initrd")" = "$CURRENT_VERSIONED_INITRD_SIZE" ] \
        && [ "$(sha256sum -- "$current_initrd" | awk '{print $1}')" = "$CURRENT_VERSIONED_INITRD_SHA256" ] || return 1
    [ ! -e "$target_initrd" ] || return 1
    [ ! -e "$(root_path /boot/initrd.gz)" ] || return 1
    [ ! -e "$(root_path /etc/mkinitrd.conf)" ] || return 1
    [ -f "$policy" ] && [ ! -L "$policy" ] \
        && [ "$(sha256sum -- "$policy" | awk '{print $1}')" = "$ACTIVE_POLICY_SHA256" ] || return 1
    [ "$(read_scalar_assignment "$policy" AUTOGENERATE_INITRD)" = true ] || return 1
    [ "$(read_scalar_assignment "$policy" GENINITRD_NAMED_SYMLINK)" = true ] || return 1
    [ "$(read_scalar_assignment "$policy" GENINITRD_INITRD_GZ_SYMLINK)" = false ] || return 1
    [ "$(read_scalar_assignment "$policy" AUTO_UPDATE_GRUB)" = true ] || return 1
    [ -f "$geninitrd" ] && [ ! -L "$geninitrd" ] \
        && [ "$(sha256sum -- "$geninitrd" | awk '{print $1}')" = "$GENINITRD_SHA256" ] || return 1
    [ -f "$generator" ] && [ ! -L "$generator" ] \
        && [ "$(sha256sum -- "$generator" | awk '{print $1}')" = "$COMMAND_GENERATOR_SHA256" ] || return 1
    [ -f "$setup" ] && [ ! -L "$setup" ] \
        && [ "$(sha256sum -- "$setup" | awk '{print $1}')" = "$SETUP_SHA256" ] || return 1
    [ -f "$grub" ] && [ ! -L "$grub" ] \
        && [ "$(sha256sum -- "$grub" | awk '{print $1}')" = "$ACTIVE_GRUB_SHA256" ] || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    validate_grub_kernel_initrd_pair "$grub" /boot/vmlinuz-generic /boot/initrd-generic.img || return 1
    for path in /etc/geninitrd.d/pre-install/dkms-bcachefs /etc/geninitrd.d/pre-install/dkms-nvidia; do
        hook=$(root_path "$path")
        case "$path" in
            *dkms-bcachefs) expected_hook=$HOOK_BCACHEFS_SHA256 ;;
            *dkms-nvidia) expected_hook=$HOOK_NVIDIA_SHA256 ;;
        esac
        [ -f "$hook" ] && [ ! -L "$hook" ] && [ -x "$hook" ] \
            && [ "$(sha256sum -- "$hook" | awk '{print $1}')" = "$expected_hook" ] || return 1
    done
    matches=$(find "$PACKAGE_CACHE_ROOT" -type f -name "$PACKAGE_FILENAME" -print 2>/dev/null | LC_ALL=C sort)
    [ "$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1
    package=$matches
    [ ! -L "$package" ] || return 1
    observed=$(sha256sum -- "$package" | awk '{print $1}')
    [ "$observed" = "$PACKAGE_SHA256" ] || return 1
    [ -d "$(root_path "/lib/modules/$RUNNING_KERNEL")" ] || return 1
    [ ! -e "$(root_path "/lib/modules/$TARGET_KERNEL")" ] || return 1
    [ -d "$(root_path /var/lib/dkms)" ] && [ ! -L "$(root_path /var/lib/dkms)" ] || return 1
    [ -z "$(find "$(root_path /var/lib/dkms)" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ] || return 1
    [ "$(dkms status 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l)" -eq 0 ] || return 1
}

validate_nested_normal_update() {
    local directory=$1
    python3 - "$REFRESH_RECORD" "$USERSPACE_REVIEW" "$directory" "$REBIND_CANDIDATE_SHA256" "$TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
refresh_path, review_path, directory, expected_digest, target = sys.argv[1:]
root = pathlib.Path(directory)
try:
    refresh = json.load(open(refresh_path, encoding='utf-8'))
    review = json.load(open(review_path, encoding='utf-8'))
    summary = dict(line.rstrip('\n').split('=', 1) for line in open(root/'summary.txt', encoding='utf-8') if '=' in line)
except Exception:
    raise SystemExit(1)

def values(name):
    path=root/name
    if not path.is_file():
        raise SystemExit(1)
    rows=[x.strip() for x in path.read_text(encoding='utf-8').splitlines() if x.strip()]
    if rows != sorted(set(rows)):
        raise SystemExit(1)
    if any(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9+._-]*\.t(?:xz|gz|lz|bz)', row) is None for row in rows):
        raise SystemExit(1)
    return rows
install=values('install-new.candidates.txt')
upgrade=values('upgrade-all.candidates.txt')
all_candidates=values('all.candidates.txt')
critical=values('critical.candidates.txt')
raw=''.join(f'{item}\n' for item in all_candidates).encode()
digest=hashlib.sha256(raw).hexdigest()
checks=[
    summary.get('scenario') == 'normal-update', summary.get('mode') == 'preflight',
    summary.get('target') == 'slackware-current', summary.get('result') == 'PASS',
    summary.get('failures') == '0', summary.get('candidate_set_sha256') == expected_digest,
    digest == expected_digest == refresh.get('fresh_candidate_set_sha256') == review.get('fresh_candidate_set_sha256'),
    install == refresh.get('install_new'), upgrade == refresh.get('upgrade_all'),
    all_candidates == refresh.get('all_candidates'), critical == [],
    int(summary.get('total_candidates', '-1')) == len(all_candidates) == 137,
    int(summary.get('kernel_candidates', '-1')) == 2,
    int(summary.get('critical_candidates', '-1')) == 0,
    review.get('kernel_transaction_candidates') == [
        f'kernel-generic-{target}-x86_64-1.txz',
        f'kernel-headers-{target}-x86-1.txz',
        f'kernel-source-{target}-noarch-1.txz'],
    all(item in upgrade for item in review.get('kernel_transaction_candidates', [])),
]
raise SystemExit(0 if all(checks) else 1)
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

read_nested_candidate_digest() {
    local summary=$1 digest
    [ -f "$summary" ] && [ ! -L "$summary" ] || return 1
    digest=$(sed -n 's/^candidate_set_sha256=//p' "$summary")
    [ "$(printf '%s\n' "$digest" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1
    is_sha256 "$digest" || return 1
    printf '%s\n' "$digest"
}

write_rebind_analysis() {
    python3 - "$REBIND_POLICY" "$1" <<PY
import json, sys
policy=json.load(open(sys.argv[1], encoding='utf-8'))
result={
  'scenario':'current-kernel-evidence-rebind-preflight',
  'target':'$TARGET',
  'source_candidate_set_sha256':'$SOURCE_CANDIDATE_SHA256',
  'rebound_candidate_set_sha256':'$REBIND_CANDIDATE_SHA256',
  'fresh_candidate_set_sha256':'$FRESH_CANDIDATE_SHA256',
  'running_kernel':'$RUNNING_KERNEL',
  'target_kernel':'$TARGET_KERNEL',
  'kernel_transaction_candidates':policy['kernel_transaction_candidates'],
  'accepted_evidence_archive_sha256':policy['accepted_evidence_archive_sha256'],
  'accepted_kernel_evidence_count':7,
  'boot_mode':'geninitrd-managed-versioned-initrd',
  'transition_mode':'versioned-to-versioned-initrd',
  'current_named_initrd':'$CURRENT_NAMED_INITRD',
  'current_named_initrd_target':'$CURRENT_NAMED_INITRD_TARGET',
  'current_versioned_initrd':'$CURRENT_VERSIONED_INITRD',
  'current_versioned_initrd_sha256':'$CURRENT_VERSIONED_INITRD_SHA256',
  'exact_cached_package':{'filename':'$PACKAGE_FILENAME','sha256':'$PACKAGE_SHA256'},
  'candidate_binding_change_only':True,
  'kernel_transaction_changed':False,
  'live_kernel_evidence_state_verified':True,
  'kernel_evidence_rebound':True,
  'package_payloads_inspected':False,
  'userspace_apply_review_complete':False,
  'userspace_payload_review_required':True,
  'package_transaction_executed':False,
  'maintainer_script_executed':False,
  'mkinitrd_executed':False,
  'geninitrd_executed':False,
  'dkms_build_executed':False,
  'grub_update_executed':False,
  'next_stage':'current-userspace-payload-review-preflight',
  'apply_ready':False,
  'apply_authorized':False,
}
with open(sys.argv[2], 'w', encoding='utf-8') as handle:
    json.dump(result, handle, indent=2, sort_keys=True)
    handle.write('\n')
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-kernel-evidence-rebind-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
source_candidate_set_sha256=$SOURCE_CANDIDATE_SHA256
rebound_candidate_set_sha256=$REBIND_CANDIDATE_SHA256
fresh_candidate_set_sha256=$FRESH_CANDIDATE_SHA256
accepted_kernel_evidence_count=7
boot_mode=geninitrd-managed-versioned-initrd
transition_mode=versioned-to-versioned-initrd
kernel_evidence_rebound=$KERNEL_EVIDENCE_REBOUND
candidate_binding_change_only=true
package_payloads_inspected=false
userspace_apply_review_complete=false
userspace_payload_review_required=true
package_transaction_executed=false
maintainer_script_executed=false
mkinitrd_executed=false
geninitrd_executed=false
dkms_build_executed=false
grub_update_executed=false
next_stage=$NEXT_STAGE
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-kernel-evidence-rebind-preflight-${timestamp}.tar.gz"
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
    local timestamp nested_root nested_dir nested_exit fresh_digest archive path
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk bash cat cmp date dkms find grub-script-check id python3 readlink sed sha256sum stat tar uname wc; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command unavailable: $command_name"; return 2; }
    done
    for path in \
        "$NORMAL_UPDATE_SCRIPT" "$BASELINE_PREFLIGHT" "$REFRESH_RECORD" "$USERSPACE_REVIEW" \
        "$REBIND_POLICY" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" \
        "$POLICY_PREFLIGHT" "$DKMS_PREFLIGHT" "$COMMAND_PREFLIGHT" "$OWNERSHIP_PREFLIGHT" \
        "$POST_STATE_CONTRACT" "$REFERENCE_ENGINE"; do
        [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ] || { error "unsafe or unreadable input: $path"; return 2; }
    done
    bash -n "$NORMAL_UPDATE_SCRIPT" || { error 'normal-update script has invalid syntax'; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if validate_accepted_records; then
        record_pass 'the accepted userspace review and all seven kernel evidence records permit an explicit candidate rebind'
    else
        record_failure 'the accepted userspace review, rebind policy, or kernel evidence chain is inconsistent or unsafe'
    fi
    if [ "$REBIND_CANDIDATE_SHA256" = "$CONFIRM_CANDIDATES_SHA256" ] && [ "$TARGET_KERNEL" = "$CONFIRM_TARGET_KERNEL" ]; then
        record_pass 'the explicit candidate digest and target kernel match the reviewed rebind boundary'
    else
        record_failure 'the explicit candidate digest or target kernel differs from the reviewed rebind boundary'
    fi
    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and kernel-evidence-sensitive state were captured before rebind'
    else
        record_failure 'the initial package or kernel-evidence-sensitive state could not be captured safely'
    fi

    nested_root=$OUTPUT_DIR/nested
    nested_dir=$nested_root/normal-update
    mkdir -p -- "$nested_root" || return 2
    printf 'Running a fresh non-installing normal-update preflight for kernel evidence rebind...\n'
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
    if fresh_digest=$(read_nested_candidate_digest "$nested_dir/summary.txt"); then
        FRESH_CANDIDATE_SHA256=$fresh_digest
    fi
    if [ "$nested_exit" -eq 0 ] && validate_nested_normal_update "$nested_dir"; then
        record_pass 'the fresh 137-candidate set and exact kernel transaction still match the accepted userspace review'
    else
        record_failure 'the fresh candidate set, kernel transaction, or userspace review binding has changed'
    fi
    if verify_nested_archive "$nested_root"; then
        record_pass 'the nested normal-update evidence archive and portable sidecar verify inside the rebind evidence'
    else
        record_failure 'the nested normal-update archive or portable sidecar is missing, ambiguous, or invalid'
    fi
    if validate_live_state; then
        record_pass 'the exact cached kernel package and live GenInitrd, DKMS, and GRUB evidence state remain unchanged'
    else
        record_failure 'the cached package or live kernel evidence state differs from the accepted chain'
    fi
    if [ "$FAILURE_COUNT" -eq 0 ] \
        && [ "$FRESH_CANDIDATE_SHA256" = "$REBIND_CANDIDATE_SHA256" ] \
        && write_rebind_analysis "$OUTPUT_DIR/kernel-evidence-rebind.json"; then
        record_pass 'an evidence-local rebind map changes only the accepted candidate digest and preserves apply denial'
    else
        record_failure 'the candidate digest could not be rebound safely to the accepted kernel evidence'
    fi
    if capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt"; then
        record_pass 'the package database and kernel-evidence-sensitive state were captured after rebind'
    else
        record_failure 'the final package or kernel-evidence-sensitive state could not be captured safely'
    fi
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during evidence rebind' \
        || record_failure 'the installed package database changed during evidence rebind'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged during evidence rebind' \
        || record_failure 'the active kernel evidence state changed during evidence rebind'

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        KERNEL_EVIDENCE_REBOUND=true
        NEXT_STAGE=current-userspace-payload-review-preflight
        record_pass 'the seven kernel evidence records are rebound to the 137-candidate digest while userspace payload review remains required'
    else
        KERNEL_EVIDENCE_REBOUND=false
        NEXT_STAGE=manual-review-required
        record_failure 'the kernel evidence could not be rebound to the fresh candidate digest'
    fi
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current kernel evidence rebind result: source=%s, rebound=%s, running=%s, target=%s, evidence=%s, kernel-evidence-rebound=%s, userspace-payload-review-required=true, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "${SOURCE_CANDIDATE_SHA256:-unavailable}" "${REBIND_CANDIDATE_SHA256:-unavailable}" \
        "${RUNNING_KERNEL:-unavailable}" "${TARGET_KERNEL:-unavailable}" 7 \
        "$KERNEL_EVIDENCE_REBOUND" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
