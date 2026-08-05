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
DEFAULT_NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
DEFAULT_BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260804-accepted.json"
DEFAULT_CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260804-accepted.json"
DEFAULT_PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260804-accepted.json"
DEFAULT_POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260804-accepted.json"
DEFAULT_DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260804-accepted.json"
DEFAULT_COMMAND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260804-accepted.json"
DEFAULT_OWNERSHIP_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260804-accepted.json"
DEFAULT_POST_STATE_CONTRACT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-post-state-6.18.42-synthetic.json"
DEFAULT_REFERENCE_ENGINE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-kernel-transaction-readiness-preflight
DEFAULT_PACKAGE_CACHE_ROOT=/var/cache/packages

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
NORMAL_UPDATE_SCRIPT=$DEFAULT_NORMAL_UPDATE_SCRIPT
NORMAL_PREFLIGHT=$DEFAULT_NORMAL_PREFLIGHT
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
RUNNING_KERNEL=
TARGET_KERNEL=
CANDIDATE_SET_SHA256=
PACKAGE_FILENAME=
PACKAGE_SHA256=
ACTIVE_POLICY_SHA256=
GENERATOR_SHA256=
SETUP_SHA256=
REFERENCE_ENGINE_SHA256=
POST_STATE_CONTRACT_SHA256=
FRESH_CANDIDATE_SHA256=
READINESS_STATUS=blocked
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Perform the final non-installing Slackware-current kernel transaction readiness
review. The preflight binds every accepted evidence record, refreshes Slackpkg
metadata through the existing normal-update preflight, verifies that the exact
candidate set and cached kernel package remain unchanged, and rechecks the live
boot, GenInitrd, DKMS, and GRUB ownership boundary. It may report apply_ready=true
but never authorizes or executes package, initrd, DKMS, or GRUB changes.

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
        "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" \
        "$POLICY_PREFLIGHT" "$DKMS_PREFLIGHT" "$COMMAND_PREFLIGHT" "$OWNERSHIP_PREFLIGHT" \
        "$POST_STATE_CONTRACT" "$REFERENCE_ENGINE" \
        "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
(
    normal_path, boot_path, chain_path, package_path, policy_path, dkms_path,
    command_path, ownership_path, post_path, engine_path, confirmed_digest,
    confirmed_target,
) = sys.argv[1:]
try:
    normal = json.load(open(normal_path, encoding='utf-8'))
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

candidate = normal.get('candidates', {})
package_data = package.get('package', {})
policy_data = policy.get('policy', {})
dkms_data = dkms.get('dkms', {})
command_package = command.get('package', {})
ownership_package = ownership.get('package', {})
engine_sha = hashlib.sha256(engine_bytes).hexdigest()
all_archive_links = {
    'boot': boot.get('archive_sha256'),
    'chain': chain.get('archive_sha256'),
    'package': package.get('archive_sha256'),
    'policy': policy.get('archive_sha256'),
    'dkms': dkms.get('archive_sha256'),
    'command': command.get('archive_sha256'),
    'ownership': ownership.get('archive_sha256'),
}
checks = [
    normal.get('scenario') == 'normal-update', normal.get('mode') == 'preflight',
    normal.get('target') == 'slackware-current', normal.get('accepted') is True, denied(normal),
    candidate.get('candidate_set_sha256') == confirmed_digest,
    candidate.get('target_kernel_version') == confirmed_target,
    candidate.get('total') == 69,
    'kernel-generic-6.18.42-x86_64-1.txz' in candidate.get('upgrade_all', []),
    'kernel-headers-6.18.42-x86-1.txz' in candidate.get('upgrade_all', []),
    'kernel-source-6.18.42-noarch-1.txz' in candidate.get('upgrade_all', []),
    boot.get('scenario') == 'current-kernel-boot-preflight', boot.get('accepted') is True, denied(boot),
    boot.get('normal_update_candidate_set_sha256') == confirmed_digest,
    boot.get('target_kernel') == confirmed_target,
    boot.get('boot_mode') == 'direct-generic-no-initrd',
    chain.get('scenario') == 'current-kernel-chain-restart-preflight', chain.get('accepted') is True, denied(chain),
    chain.get('candidate_set_sha256') == confirmed_digest,
    chain.get('target_kernel') == confirmed_target,
    chain.get('nested_boot_archive_sha256') == all_archive_links['boot'],
    package.get('scenario') == 'current-kernel-package-preflight', package.get('accepted') is True, denied(package),
    package.get('normal_update_candidate_set_sha256') == confirmed_digest,
    package.get('boot_preflight_archive_sha256') == all_archive_links['boot'],
    package.get('chain_restart_archive_sha256') == all_archive_links['chain'],
    package.get('target_kernel') == confirmed_target,
    package_data.get('filename') == 'kernel-generic-6.18.42-x86_64-1.txz',
    digest(package_data.get('sha256')), package_data.get('paths_safe') is True,
    package_data.get('kernel_image') == '/boot/vmlinuz-6.18.42', package_data.get('embedded_initrd_count') == 0,
    policy.get('scenario') == 'current-geninitrd-policy-preflight', policy.get('accepted') is True, denied(policy),
    policy.get('package_preflight_archive_sha256') == all_archive_links['package'],
    policy.get('target_kernel') == confirmed_target,
    policy_data.get('transition_mode') == 'direct-to-generated-initrd',
    policy_data.get('expected_initrd') == '/boot/initrd-6.18.42.img',
    policy_data.get('auto_update_grub') is True,
    dkms.get('scenario') == 'current-geninitrd-dkms-hook-preflight', dkms.get('accepted') is True, denied(dkms),
    dkms.get('policy_preflight_archive_sha256') == all_archive_links['policy'],
    dkms.get('target_kernel') == confirmed_target,
    dkms_data.get('status_row_count') == 0, dkms.get('review_status') == 'accepted-noop-hooks',
    command.get('scenario') == 'current-geninitrd-command-preflight', command.get('accepted') is True, denied(command),
    command.get('dkms_preflight_archive_sha256') == all_archive_links['dkms'],
    command.get('target_kernel') == confirmed_target,
    command.get('projected_initrd') == '/boot/initrd-6.18.42.img',
    command_package.get('observed_sha256') == package_data.get('sha256'),
    ownership.get('scenario') == 'current-geninitrd-grub-ownership-preflight', ownership.get('accepted') is True, denied(ownership),
    ownership.get('command_preflight_archive_sha256') == all_archive_links['command'],
    ownership.get('target_kernel') == confirmed_target,
    ownership.get('strategy') == 'temporary-atomic-policy-override',
    ownership.get('environment_override_safe') is False,
    ownership_package.get('filename') == package_data.get('filename'),
    ownership_package.get('sha256') == package_data.get('sha256'),
    ownership.get('next_stage') == 'current-kernel-transaction-readiness-preflight',
    post.get('scenario') == 'current-geninitrd-post-state', post.get('synthetic') is True,
    post.get('accepted') is False, denied(post),
    post.get('normal_update_candidate_set_sha256') == confirmed_digest,
    post.get('target_kernel') == confirmed_target,
    post.get('post_transaction', {}).get('versioned_initrd') == '/boot/initrd-6.18.42.img',
    post.get('reference_engine_sha256') == engine_sha,
]
if not all(checks):
    raise SystemExit(1)
for value in all_archive_links.values():
    if not digest(value):
        raise SystemExit(1)
print(normal.get('platform', {}).get('kernel_version', ''))
print(confirmed_target)
print(confirmed_digest)
print(package_data.get('filename', ''))
print(package_data.get('sha256', ''))
print(ownership.get('active_policy', {}).get('sha256', ''))
print(policy.get('scripts', {}).get('geninitrd_sha256', ''))
print(policy.get('scripts', {}).get('setup_sha256', ''))
print(engine_sha)
print(hashlib.sha256(pathlib.Path(post_path).read_bytes()).hexdigest())
PY
) || return 1
    RUNNING_KERNEL=$(printf '%s\n' "$values" | sed -n '1p')
    TARGET_KERNEL=$(printf '%s\n' "$values" | sed -n '2p')
    CANDIDATE_SET_SHA256=$(printf '%s\n' "$values" | sed -n '3p')
    PACKAGE_FILENAME=$(printf '%s\n' "$values" | sed -n '4p')
    PACKAGE_SHA256=$(printf '%s\n' "$values" | sed -n '5p')
    ACTIVE_POLICY_SHA256=$(printf '%s\n' "$values" | sed -n '6p')
    GENERATOR_SHA256=$(printf '%s\n' "$values" | sed -n '7p')
    SETUP_SHA256=$(printf '%s\n' "$values" | sed -n '8p')
    REFERENCE_ENGINE_SHA256=$(printf '%s\n' "$values" | sed -n '9p')
    POST_STATE_CONTRACT_SHA256=$(printf '%s\n' "$values" | sed -n '10p')
    [ -n "$RUNNING_KERNEL" ] && [ -n "$PACKAGE_FILENAME" ] && is_sha256 "$PACKAGE_SHA256"
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
        /boot/initrd-generic.img \
        /boot/initrd.gz \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/mkinitrd.conf \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia \
        /var/lib/dkms \
        "/lib/modules/$RUNNING_KERNEL"; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$(root_path "$path")" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

validate_nested_normal_update() {
    local directory=$1
    python3 - "$NORMAL_PREFLIGHT" "$directory" "$CANDIDATE_SET_SHA256" "$TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, sys
accepted_path, directory, expected_digest, target = sys.argv[1:]
root = pathlib.Path(directory)
try:
    accepted = json.load(open(accepted_path, encoding='utf-8'))
    summary = dict(
        line.rstrip('\n').split('=', 1)
        for line in open(root/'summary.txt', encoding='utf-8')
        if '=' in line
    )
except Exception:
    raise SystemExit(1)

def lines(name):
    path = root/name
    if not path.is_file():
        raise SystemExit(1)
    values = [x.strip() for x in path.read_text(encoding='utf-8').splitlines() if x.strip()]
    if values != sorted(set(values)):
        raise SystemExit(1)
    return values
install = lines('install-new.candidates.txt')
upgrade = lines('upgrade-all.candidates.txt')
all_candidates = lines('all.candidates.txt')
expected = accepted.get('candidates', {})
expected_all = sorted(expected.get('install_new', []) + expected.get('upgrade_all', []))
raw = ''.join(f'{item}\n' for item in all_candidates).encode()
digest = hashlib.sha256(raw).hexdigest()
checks = [
    summary.get('scenario') == 'normal-update', summary.get('mode') == 'preflight',
    summary.get('target') == 'slackware-current', summary.get('result') == 'PASS',
    summary.get('failures') == '0', summary.get('candidate_set_sha256') == expected_digest,
    digest == expected_digest, all_candidates == expected_all,
    install == expected.get('install_new'), upgrade == expected.get('upgrade_all'),
    int(summary.get('total_candidates', '-1')) == len(all_candidates) == 69,
    int(summary.get('kernel_candidates', '-1')) == 2,
    int(summary.get('critical_candidates', '-1')) == 0,
    f'kernel-generic-{target}-x86_64-1.txz' in upgrade,
    f'kernel-headers-{target}-x86-1.txz' in upgrade,
    f'kernel-source-{target}-noarch-1.txz' in upgrade,
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

validate_live_state() {
    local generic target policy generator setup grub package matches observed hook path
    generic=$(root_path /boot/vmlinuz-generic)
    target=$(root_path "/boot/vmlinuz-$RUNNING_KERNEL")
    policy=$(root_path /etc/default/geninitrd)
    generator=$(root_path /usr/share/mkinitrd/mkinitrd_command_generator.sh)
    setup=$(root_path /var/lib/pkgtools/setup/setup.01.mkinitrd)
    grub=$(root_path /boot/grub/grub.cfg)
    [ "$(uname -r)" = "$RUNNING_KERNEL" ] || return 1
    [ -L "$generic" ] && [ "$(readlink -e -- "$generic")" = "$target" ] || return 1
    [ -f "$target" ] && [ ! -L "$target" ] || return 1
    [ -f "$policy" ] && [ ! -L "$policy" ] && [ "$(sha256sum -- "$policy" | awk '{print $1}')" = "$ACTIVE_POLICY_SHA256" ] || return 1
    [ -f "$generator" ] && [ ! -L "$generator" ] && [ "$(sha256sum -- "$generator" | awk '{print $1}')" = "$GENERATOR_SHA256" ] || return 1
    [ -f "$setup" ] && [ ! -L "$setup" ] && [ "$(sha256sum -- "$setup" | awk '{print $1}')" = "$SETUP_SHA256" ] || return 1
    [ -f "$grub" ] && [ ! -L "$grub" ] || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    for path in /etc/geninitrd.d/pre-install/dkms-bcachefs /etc/geninitrd.d/pre-install/dkms-nvidia; do
        hook=$(root_path "$path")
        [ -f "$hook" ] && [ ! -L "$hook" ] && [ -x "$hook" ] || return 1
    done
    matches=$(find "$PACKAGE_CACHE_ROOT" -type f -name "$PACKAGE_FILENAME" -print 2>/dev/null | LC_ALL=C sort)
    [ "$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1
    package=$matches
    [ ! -L "$package" ] || return 1
    observed=$(sha256sum -- "$package" | awk '{print $1}')
    [ "$observed" = "$PACKAGE_SHA256" ] || return 1
    [ -d "$(root_path "/lib/modules/$RUNNING_KERNEL")" ] || return 1
    [ ! -e "$(root_path "/lib/modules/$TARGET_KERNEL")" ] || return 1
    [ ! -e "$(root_path /boot/initrd-generic.img)" ] || return 1
    [ ! -e "$(root_path /boot/initrd.gz)" ] || return 1
    [ ! -e "$(root_path /etc/mkinitrd.conf)" ] || return 1
    if command -v dkms >/dev/null 2>&1; then
        [ "$(dkms status 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l)" -eq 0 ] || return 1
    fi
}

write_analysis() {
    python3 - "$1" <<PY
import json
result = {
  "scenario": "current-kernel-transaction-readiness-preflight",
  "target": "$TARGET",
  "running_kernel": "$RUNNING_KERNEL",
  "target_kernel": "$TARGET_KERNEL",
  "candidate_set_sha256": "$CANDIDATE_SET_SHA256",
  "fresh_candidate_set_sha256": "$FRESH_CANDIDATE_SHA256",
  "accepted_evidence_count": 8,
  "final_candidate_revalidation_completed": True,
  "final_candidate_revalidation_fresh": True,
  "exact_package_cache_verified": True,
  "live_boot_layout_verified": True,
  "geninitrd_policy_verified": True,
  "dkms_noop_state_verified": True,
  "grub_ownership_strategy": "temporary-atomic-policy-override",
  "post_state_contract_sha256": "$POST_STATE_CONTRACT_SHA256",
  "reference_engine_sha256": "$REFERENCE_ENGINE_SHA256",
  "metadata_refresh_executed": True,
  "candidate_probe_executed": True,
  "package_transaction_executed": False,
  "mkinitrd_executed": False,
  "geninitrd_executed": False,
  "dkms_build_executed": False,
  "update_grub_executed": False,
  "grub_mkconfig_executed": False,
  "readiness_status": "$READINESS_STATUS",
  "requires_explicit_apply_authorization": True,
  "requires_apply_time_candidate_revalidation": True,
  "apply_ready": $([ "$APPLY_READY" = true ] && printf True || printf False),
  "apply_authorized": False
}
with open("$1", "w", encoding="utf-8") as handle:
    json.dump(result, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-kernel-transaction-readiness-preflight
target=$TARGET
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CANDIDATE_SET_SHA256
fresh_candidate_set_sha256=$FRESH_CANDIDATE_SHA256
readiness_status=$READINESS_STATUS
final_candidate_revalidation_completed=true
package_transaction_executed=false
mkinitrd_executed=false
geninitrd_executed=false
dkms_build_executed=false
update_grub_executed=false
grub_mkconfig_executed=false
apply_ready=$APPLY_READY
apply_authorized=false
next_stage=normal-update-apply-authorization-review
EOF_SUMMARY
}

create_evidence_archive() {
    local parent base archive
    parent=$(dirname -- "$OUTPUT_DIR")
    base=${OUTPUT_DIR##*/}
    archive="$parent/${TARGET}-current-kernel-transaction-readiness-preflight-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum "${archive##*/}") > "$archive.sha256" || return 1
    printf '%s\n' "$archive"
}

print_evidence_commands() {
    local archive=$1 owner=${SUDO_USER:-promano} group
    [ -n "$owner" ] && [ "$owner" != root ] || owner=promano
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
        "$owner" "$group" "$archive.sha256" "/home/$owner/${archive##*/}.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${archive##*/}.sha256"
}

main() {
    local timestamp nested_root nested_dir nested_exit archive
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this real-system preflight requires root'; return 2; }
    for command_name in bash cmp date dkms find grub-script-check hostname id python3 readlink sed sha256sum stat tar uname wc; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command unavailable: $command_name"; return 2; }
    done
    [ -x "$NORMAL_UPDATE_SCRIPT" ] || { error "normal-update preflight is unavailable: $NORMAL_UPDATE_SCRIPT"; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] || { error "output directory already exists: $OUTPUT_DIR"; return 2; }
    mkdir -p -- "$OUTPUT_DIR" || return 2
    chmod 0700 -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"
    : > "$ASSERTION_LOG"

    if validate_accepted_records; then
        record_pass "the complete accepted Slackware-current kernel evidence chain binds target $TARGET_KERNEL"
    else
        record_failure 'the accepted Slackware-current kernel evidence chain is inconsistent, stale, or unsafe'
    fi
    if [ "$CANDIDATE_SET_SHA256" = "$CONFIRM_CANDIDATES_SHA256" ] && [ "$TARGET_KERNEL" = "$CONFIRM_TARGET_KERNEL" ]; then
        record_pass 'the explicit candidate and target confirmations match the accepted chain'
    else
        record_failure 'the explicit candidate or target confirmation differs from the accepted chain'
    fi
    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and transaction-sensitive state were captured before final revalidation'
    else
        record_failure 'the initial package or transaction-sensitive state could not be captured safely'
    fi

    nested_root="$OUTPUT_DIR/nested"
    nested_dir="$nested_root/normal-update"
    mkdir -p -- "$nested_root" || return 2
    printf 'Running a fresh non-installing normal-update preflight for final candidate revalidation...\n'
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
    if validate_nested_normal_update "$nested_dir"; then
        FRESH_CANDIDATE_SHA256=$(sed -n 's/^candidate_set_sha256=//p' "$nested_dir/summary.txt")
        record_pass 'the fresh candidate set exactly matches all 69 reviewed candidates and kernel companions'
    else
        record_failure 'the fresh candidate set differs from the reviewed transaction or is malformed'
    fi
    if verify_nested_archive "$nested_root"; then
        record_pass 'the nested normal-update evidence archive and portable sidecar verify inside the readiness evidence'
    else
        record_failure 'the nested normal-update archive or portable sidecar is missing, ambiguous, or invalid'
    fi
    if validate_live_state; then
        record_pass 'the exact package cache, direct boot layout, GenInitrd policy, no-op DKMS state, and GRUB configuration remain reviewed'
    else
        record_failure 'the live package, boot, GenInitrd, DKMS, or GRUB state no longer matches the accepted chain'
    fi
    if capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt"; then
        record_pass 'the package database and transaction-sensitive state were captured after final revalidation'
    else
        record_failure 'the final package or transaction-sensitive state could not be captured safely'
    fi
    if cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt"; then
        record_pass 'the installed package database remained unchanged during readiness review'
    else
        record_failure 'the installed package database changed during readiness review'
    fi
    if cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt"; then
        record_pass 'the active boot, policy, hook, generator, and DKMS state remained unchanged during readiness review'
    else
        record_failure 'transaction-sensitive state changed during readiness review'
    fi

    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$FRESH_CANDIDATE_SHA256" = "$CANDIDATE_SET_SHA256" ]; then
        READINESS_STATUS=apply-ready
        APPLY_READY=true
    else
        READINESS_STATUS=blocked
        APPLY_READY=false
    fi
    write_analysis "$OUTPUT_DIR/readiness-analysis.json"
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current kernel transaction readiness result: running=%s, target=%s, candidates=%s, readiness=%s, apply-ready=%s, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$FRESH_CANDIDATE_SHA256" "$READINESS_STATUS" "$APPLY_READY"
    archive=$(create_evidence_archive) || { error 'failed to create readiness evidence archive'; return 1; }
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"
    print_evidence_commands "$archive"
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
