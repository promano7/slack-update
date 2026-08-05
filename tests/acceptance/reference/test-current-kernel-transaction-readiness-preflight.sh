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
DEFAULT_BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
DEFAULT_CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
DEFAULT_PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
DEFAULT_POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"
DEFAULT_DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
DEFAULT_COMMAND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json"
DEFAULT_OWNERSHIP_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260805-accepted.json"
DEFAULT_POST_STATE_CONTRACT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-post-state-6.18.42-synthetic.json"
DEFAULT_REBIND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-evidence-rebind-20260805-accepted.json"
DEFAULT_APPLY_REVIEW="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-apply-review-20260805-accepted.json"
DEFAULT_APPLY_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-apply-review-policy.json"
DEFAULT_ELF_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-elf-runtime-review-policy.json"
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
REBIND_PREFLIGHT=$DEFAULT_REBIND_PREFLIGHT
APPLY_REVIEW=$DEFAULT_APPLY_REVIEW
APPLY_POLICY=$DEFAULT_APPLY_POLICY
ELF_POLICY=$DEFAULT_ELF_POLICY
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
SOURCE_CANDIDATE_SET_SHA256=
PACKAGE_FILENAME=
PACKAGE_SHA256=
ACTIVE_POLICY_SHA256=
GENINITRD_SHA256=
COMMAND_GENERATOR_SHA256=
SETUP_SHA256=
REFERENCE_ENGINE_SHA256=
POST_STATE_CONTRACT_SHA256=
GENERIC_KERNEL_SHA256=
CURRENT_NAMED_INITRD=
CURRENT_NAMED_INITRD_TARGET=
CURRENT_VERSIONED_INITRD=
CURRENT_VERSIONED_INITRD_SHA256=
CURRENT_VERSIONED_INITRD_SIZE=
ACTIVE_GRUB_SHA256=
HOOK_BCACHEFS_SHA256=
HOOK_NVIDIA_SHA256=
FRESH_CANDIDATE_SHA256=
REBIND_ARCHIVE_SHA256=
APPLY_REVIEW_ARCHIVE_SHA256=
REVIEWED_CACHE_PACKAGE_COUNT=0
READINESS_STATUS=blocked
NEXT_STAGE=current-candidate-chain-refresh-preflight
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Perform the final non-installing Slackware-current kernel transaction readiness
review. The preflight binds the immutable kernel chain, explicit candidate
rebind, and accepted userspace apply review; refreshes Slackpkg metadata through
the existing normal-update preflight; verifies all 137 candidates and 69 exact
cached package archives; and rechecks the live boot, GenInitrd, DKMS, and GRUB
ownership boundary. It may report apply_ready=true, but reports pause_safe=false
until apply-time candidate revalidation and the real package transaction finish.
It never authorizes or executes package, initrd, DKMS, or GRUB changes.

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
        "$POST_STATE_CONTRACT" "$REBIND_PREFLIGHT" "$APPLY_REVIEW" "$APPLY_POLICY" \
        "$ELF_POLICY" "$REFERENCE_ENGINE" \
        "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
(
    normal_path, boot_path, chain_path, package_path, policy_path, dkms_path,
    command_path, ownership_path, post_path, rebind_path, apply_path,
    apply_policy_path, elf_policy_path, engine_path, confirmed_digest,
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
    rebind = json.load(open(rebind_path, encoding='utf-8'))
    apply = json.load(open(apply_path, encoding='utf-8'))
    apply_policy = json.load(open(apply_policy_path, encoding='utf-8'))
    elf_policy = json.load(open(elf_policy_path, encoding='utf-8'))
    engine_bytes = pathlib.Path(engine_path).read_bytes()
except Exception:
    raise SystemExit(1)

def digest(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None

def denied(record):
    return record.get('apply_ready') is False and record.get('apply_authorized') is False

def sorted_unique(values):
    return isinstance(values, list) and values == sorted(set(values))

candidate = normal.get('candidates', {})
package_data = package.get('package', {})
policy_data = policy.get('policy', {})
dkms_data = dkms.get('dkms', {})
command_package = command.get('package', {})
ownership_package = ownership.get('package', {})
ownership_transaction = ownership.get('transaction', {})
engine_sha = hashlib.sha256(engine_bytes).hexdigest()
source_digest = candidate.get('candidate_set_sha256', '')
archives = {
    'boot': boot.get('archive_sha256'),
    'chain': chain.get('archive_sha256'),
    'package': package.get('archive_sha256'),
    'policy': policy.get('archive_sha256'),
    'dkms': dkms.get('archive_sha256'),
    'command': command.get('archive_sha256'),
    'ownership': ownership.get('archive_sha256'),
}
running = normal.get('platform', {}).get('kernel_version', '')
package_filename = f'kernel-generic-{confirmed_target}-x86_64-1.txz'
headers_filename = f'kernel-headers-{confirmed_target}-x86-1.txz'
source_filename = f'kernel-source-{confirmed_target}-noarch-1.txz'
current_initrd = f'/boot/initrd-{running}.img'
baseline = apply_policy.get('baseline_candidates', [])
additions = apply_policy.get('reviewed_additions', [])
expected_all = sorted(baseline + additions)
expected_install = apply_policy.get('expected_install_new', [])
expected_upgrade = sorted(set(expected_all) - set(expected_install))
manifest = ''.join(f'{item}\n' for item in expected_all).encode()
reviewed_packages = elf_policy.get('reviewed_packages', [])
reviewed_names = [item.get('package') for item in reviewed_packages if isinstance(item, dict)]
reviewed_manifest = ''.join(
    f"{item.get('package')}\t{item.get('sha256')}\t{item.get('size')}\t{item.get('expected_elf_count')}\n"
    for item in sorted(reviewed_packages, key=lambda item: item.get('package', ''))
).encode()
elf_count_manifest = ''.join(
    f"{item.get('package')}\t{item.get('expected_elf_count')}\n"
    for item in sorted(reviewed_packages, key=lambda item: item.get('package', ''))
    if item.get('expected_elf_count')
).encode()
checks = [
    normal.get('scenario') == 'normal-update', normal.get('mode') == 'preflight',
    normal.get('target') == 'slackware-current', normal.get('accepted') is True, denied(normal),
    digest(source_digest), source_digest != confirmed_digest,
    candidate.get('target_kernel_version') == confirmed_target,
    candidate.get('total') == 69,
    package_filename in candidate.get('upgrade_all', []),
    headers_filename in candidate.get('upgrade_all', []),
    source_filename in candidate.get('upgrade_all', []),
    boot.get('scenario') == 'current-kernel-boot-preflight', boot.get('accepted') is True, denied(boot),
    boot.get('normal_update_candidate_set_sha256') == source_digest,
    boot.get('running_kernel') == running,
    boot.get('target_kernel') == confirmed_target,
    boot.get('boot_mode') == 'geninitrd-managed-versioned-initrd',
    boot.get('named_initrd_path') == '/boot/initrd-generic.img',
    boot.get('named_initrd_target') == f'initrd-{running}.img',
    boot.get('versioned_initrd_path') == current_initrd,
    digest(boot.get('versioned_initrd_sha256')),
    boot.get('versioned_initrd_size', 0) > 0,
    digest(boot.get('generic_kernel_sha256')), digest(boot.get('active_grub_sha256')),
    boot.get('geninitrd_transition_required') is True,
    chain.get('scenario') == 'current-kernel-chain-restart-preflight', chain.get('accepted') is True, denied(chain),
    chain.get('candidate_set_sha256') == source_digest,
    chain.get('running_kernel') == running,
    chain.get('target_kernel') == confirmed_target,
    chain.get('accepted_boot_archive_sha256') == archives['boot'],
    chain.get('nested_boot_mode') == boot.get('boot_mode'),
    chain.get('nested_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    chain.get('nested_geninitrd_transition_required') is True,
    package.get('scenario') == 'current-kernel-package-preflight', package.get('accepted') is True, denied(package),
    package.get('normal_update_candidate_set_sha256') == source_digest,
    package.get('boot_preflight_archive_sha256') == archives['boot'],
    package.get('chain_restart_archive_sha256') == archives['chain'],
    package.get('running_kernel') == running,
    package.get('target_kernel') == confirmed_target,
    package.get('boot_mode') == boot.get('boot_mode'),
    package.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    package.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    package_data.get('filename') == package_filename,
    digest(package_data.get('sha256')), package_data.get('paths_safe') is True,
    package_data.get('kernel_image') == f'/boot/vmlinuz-{confirmed_target}',
    package_data.get('embedded_initrd_count') == 0,
    policy.get('scenario') == 'current-geninitrd-policy-preflight', policy.get('accepted') is True, denied(policy),
    policy.get('boot_preflight_archive_sha256') == archives['boot'],
    policy.get('chain_restart_archive_sha256') == archives['chain'],
    policy.get('package_preflight_archive_sha256') == archives['package'],
    policy.get('running_kernel') == running,
    policy.get('target_kernel') == confirmed_target,
    policy.get('boot_mode') == boot.get('boot_mode'),
    policy.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    policy_data.get('transition_mode') == 'versioned-to-versioned-initrd',
    policy_data.get('expected_initrd') == f'/boot/initrd-{confirmed_target}.img',
    policy_data.get('autogenerate_initrd') is True,
    policy_data.get('named_symlink') is True,
    policy_data.get('initrd_gz_symlink') is False,
    policy_data.get('auto_update_grub') is True,
    dkms.get('scenario') == 'current-geninitrd-dkms-hook-preflight', dkms.get('accepted') is True, denied(dkms),
    dkms.get('policy_preflight_archive_sha256') == archives['policy'],
    dkms.get('running_kernel') == running,
    dkms.get('target_kernel') == confirmed_target,
    dkms.get('boot_mode') == boot.get('boot_mode'),
    dkms.get('transition_mode') == 'versioned-to-versioned-initrd',
    dkms.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    dkms_data.get('status_row_count') == 0, dkms_data.get('var_lib_dkms_state') == 'empty',
    dkms.get('review_status') == 'accepted-noop-hooks',
    command.get('scenario') == 'current-geninitrd-command-preflight', command.get('accepted') is True, denied(command),
    command.get('dkms_preflight_archive_sha256') == archives['dkms'],
    command.get('running_kernel') == running,
    command.get('target_kernel') == confirmed_target,
    command.get('boot_mode') == boot.get('boot_mode'),
    command.get('transition_mode') == 'versioned-to-versioned-initrd',
    command.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    command.get('projected_initrd') == f'/boot/initrd-{confirmed_target}.img',
    command_package.get('filename') == package_data.get('filename'),
    command_package.get('observed_sha256') == package_data.get('sha256'),
    command.get('module_count') == 18,
    ownership.get('scenario') == 'current-geninitrd-grub-ownership-preflight', ownership.get('accepted') is True, denied(ownership),
    ownership.get('normal_update_candidate_set_sha256') == source_digest,
    ownership.get('boot_preflight_archive_sha256') == archives['boot'],
    ownership.get('chain_restart_archive_sha256') == archives['chain'],
    ownership.get('package_preflight_archive_sha256') == archives['package'],
    ownership.get('policy_preflight_archive_sha256') == archives['policy'],
    ownership.get('dkms_preflight_archive_sha256') == archives['dkms'],
    ownership.get('command_preflight_archive_sha256') == archives['command'],
    ownership.get('running_kernel') == running,
    ownership.get('target_kernel') == confirmed_target,
    ownership.get('boot_mode') == boot.get('boot_mode'),
    ownership.get('transition_mode') == 'versioned-to-versioned-initrd',
    ownership.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    ownership.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    ownership.get('strategy') == 'temporary-atomic-policy-override',
    ownership.get('environment_override_safe') is False,
    ownership_package.get('filename') == package_data.get('filename'),
    ownership_package.get('sha256') == package_data.get('sha256'),
    ownership_transaction.get('step_count') == 12,
    ownership_transaction.get('recovery_boundary_count') == 5,
    ownership_transaction.get('requires_final_candidate_revalidation') is True,
    ownership_transaction.get('requires_separate_apply_authorization') is True,
    ownership.get('next_stage') == 'current-kernel-transaction-readiness-preflight',
    post.get('scenario') == 'current-geninitrd-post-state', post.get('synthetic') is True,
    post.get('accepted') is False, denied(post),
    post.get('normal_update_candidate_set_sha256') == source_digest,
    post.get('running_kernel') == running,
    post.get('target_kernel') == confirmed_target,
    post.get('pre_transaction_layout') == 'geninitrd-managed-versioned-initrd',
    post.get('transition_mode') == 'versioned-to-versioned-initrd',
    post.get('pre_transaction', {}).get('versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    post.get('post_transaction', {}).get('versioned_initrd') == f'/boot/initrd-{confirmed_target}.img',
    post.get('post_transaction', {}).get('named_initrd_target') == f'initrd-{confirmed_target}.img',
    post.get('reference_engine_sha256') == engine_sha,
    rebind.get('scenario') == 'current-kernel-evidence-rebind-preflight',
    rebind.get('target') == 'slackware-current', rebind.get('accepted') is True, denied(rebind),
    rebind.get('source_candidate_set_sha256') == source_digest,
    rebind.get('rebound_candidate_set_sha256') == confirmed_digest,
    rebind.get('fresh_candidate_set_sha256') == confirmed_digest,
    rebind.get('running_kernel') == running, rebind.get('target_kernel') == confirmed_target,
    rebind.get('accepted_kernel_evidence_count') == 7,
    rebind.get('boot_mode') == 'geninitrd-managed-versioned-initrd',
    rebind.get('transition_mode') == 'versioned-to-versioned-initrd',
    rebind.get('kernel_transaction_candidates') == [package_filename, headers_filename, source_filename],
    rebind.get('kernel_transaction_changed') is False,
    rebind.get('kernel_evidence_rebound') is True,
    rebind.get('candidate_binding_change_only') is True,
    rebind.get('userspace_apply_review_complete') is False,
    rebind.get('next_stage') == 'current-userspace-payload-review-preflight',
    apply.get('scenario') == 'current-userspace-apply-review-preflight',
    apply.get('target') == 'slackware-current', apply.get('accepted') is True, denied(apply),
    apply.get('candidate_set_sha256') == confirmed_digest,
    apply.get('target_kernel') == confirmed_target,
    apply.get('candidate_count') == 137,
    apply.get('baseline_candidate_count') == 69,
    apply.get('added_candidate_count') == 68,
    apply.get('install_new_count') == 1,
    apply.get('upgrade_all_count') == 136,
    apply.get('kernel_candidate_count') == 2,
    apply.get('kernel_transaction_count') == 3,
    apply.get('critical_candidate_count') == 0,
    apply.get('transaction_step_count') == 12,
    apply.get('recovery_boundary_count') == 5,
    apply.get('elf_runtime_review_complete') is True,
    apply.get('userspace_apply_review_complete') is True,
    apply.get('exact_candidate_union_verified') is True,
    apply.get('reference_apply_contract_verified') is True,
    apply.get('nested_elf_runtime_evidence_verified') is True,
    apply.get('nested_normal_update_evidence_verified') is True,
    apply.get('package_database_unchanged') is True,
    apply.get('apply_sensitive_state_unchanged') is True,
    apply.get('normal_update_apply_executed') is False,
    apply.get('package_transaction_executed') is False,
    apply.get('maintainer_script_executed') is False,
    apply.get('mkinitrd_executed') is False,
    apply.get('geninitrd_executed') is False,
    apply.get('dkms_action_executed') is False,
    apply.get('grub_update_executed') is False,
    apply.get('assertions') == {'passes': 15, 'failures': 0},
    apply.get('reference_sha256') == engine_sha,
    apply.get('next_stage') == 'current-kernel-transaction-readiness-preflight',
    apply_policy.get('scenario') == 'current-userspace-apply-review-policy',
    apply_policy.get('target') == 'slackware-current', apply_policy.get('reviewed') is True, denied(apply_policy),
    apply_policy.get('candidate_set_sha256') == confirmed_digest,
    apply_policy.get('baseline_candidate_set_sha256') == source_digest,
    apply_policy.get('target_kernel') == confirmed_target,
    apply_policy.get('expected_candidate_count') == 137,
    apply_policy.get('expected_baseline_candidate_count') == 69,
    apply_policy.get('expected_added_candidate_count') == 68,
    apply_policy.get('expected_install_new_count') == 1,
    apply_policy.get('expected_upgrade_all_count') == 136,
    apply_policy.get('expected_kernel_candidate_count') == 2,
    apply_policy.get('expected_kernel_transaction_count') == 3,
    apply_policy.get('expected_critical_candidate_count') == 0,
    sorted_unique(baseline), len(baseline) == 69,
    sorted_unique(additions), len(additions) == 68,
    set(baseline).isdisjoint(additions),
    len(expected_all) == 137,
    hashlib.sha256(manifest).hexdigest() == confirmed_digest,
    apply_policy.get('candidate_union_manifest_sha256') == confirmed_digest,
    expected_install == ['ristretto-0.14.0-x86_64-1.txz'],
    len(expected_upgrade) == 136,
    apply_policy.get('expected_kernel_transaction') == [package_filename, headers_filename, source_filename],
    apply_policy.get('kernel_transaction_candidates') == [package_filename, headers_filename, source_filename],
    apply_policy.get('elf_runtime_review_complete') is True,
    apply_policy.get('kernel_evidence_rebound') is True,
    apply_policy.get('reference_engine_sha256') == engine_sha,
    apply_policy.get('next_stage') == 'current-kernel-transaction-readiness-preflight',
    elf_policy.get('scenario') == 'current-userspace-elf-runtime-review-policy',
    elf_policy.get('target') == 'slackware-current', elf_policy.get('reviewed') is True, denied(elf_policy),
    elf_policy.get('candidate_set_sha256') == confirmed_digest,
    elf_policy.get('target_kernel') == confirmed_target,
    elf_policy.get('expected_package_count') == 68,
    len(reviewed_packages) == 68,
    reviewed_names == sorted(set(reviewed_names)),
    reviewed_names == additions,
    elf_policy.get('expected_elf_package_count') == sum(item.get('expected_elf_count', 0) > 0 for item in reviewed_packages) == 61,
    elf_policy.get('expected_elf_file_count') == sum(item.get('expected_elf_count', 0) for item in reviewed_packages) == 722,
    elf_policy.get('reviewed_package_elf_manifest_sha256') == hashlib.sha256(reviewed_manifest).hexdigest(),
    elf_policy.get('elf_count_manifest_sha256') == hashlib.sha256(elf_count_manifest).hexdigest(),
]
if not all(checks):
    raise SystemExit(1)
for value in list(archives.values()) + [rebind.get('archive_sha256'), apply.get('archive_sha256'),
        apply.get('nested_elf_runtime_archive_sha256'), apply.get('nested_normal_update_archive_sha256')]:
    if not digest(value):
        raise SystemExit(1)
for item in reviewed_packages:
    if not isinstance(item, dict) or not digest(item.get('sha256')) or not isinstance(item.get('size'), int) or item.get('size', 0) <= 0:
        raise SystemExit(1)
hooks = {item.get('path'): item.get('sha256') for item in dkms.get('hooks', [])}
for path in ('/etc/geninitrd.d/pre-install/dkms-bcachefs', '/etc/geninitrd.d/pre-install/dkms-nvidia'):
    if not digest(hooks.get(path)):
        raise SystemExit(1)
print(running)
print(confirmed_target)
print(confirmed_digest)
print(source_digest)
print(package_data.get('filename', ''))
print(package_data.get('sha256', ''))
print(ownership.get('active_policy', {}).get('sha256', ''))
print(policy.get('scripts', {}).get('geninitrd_sha256', ''))
print(command.get('generator', {}).get('sha256', ''))
print(policy.get('scripts', {}).get('setup_sha256', ''))
print(engine_sha)
print(hashlib.sha256(pathlib.Path(post_path).read_bytes()).hexdigest())
print(boot.get('generic_kernel_sha256', ''))
print(boot.get('named_initrd_path', ''))
print(boot.get('named_initrd_target', ''))
print(boot.get('versioned_initrd_path', ''))
print(boot.get('versioned_initrd_sha256', ''))
print(boot.get('versioned_initrd_size', ''))
print(boot.get('active_grub_sha256', ''))
print(hooks['/etc/geninitrd.d/pre-install/dkms-bcachefs'])
print(hooks['/etc/geninitrd.d/pre-install/dkms-nvidia'])
print(rebind.get('archive_sha256', ''))
print(apply.get('archive_sha256', ''))
print(len(reviewed_packages) + 1)
PY
) || return 1
    RUNNING_KERNEL=$(printf '%s\n' "$values" | sed -n '1p')
    TARGET_KERNEL=$(printf '%s\n' "$values" | sed -n '2p')
    CANDIDATE_SET_SHA256=$(printf '%s\n' "$values" | sed -n '3p')
    SOURCE_CANDIDATE_SET_SHA256=$(printf '%s\n' "$values" | sed -n '4p')
    PACKAGE_FILENAME=$(printf '%s\n' "$values" | sed -n '5p')
    PACKAGE_SHA256=$(printf '%s\n' "$values" | sed -n '6p')
    ACTIVE_POLICY_SHA256=$(printf '%s\n' "$values" | sed -n '7p')
    GENINITRD_SHA256=$(printf '%s\n' "$values" | sed -n '8p')
    COMMAND_GENERATOR_SHA256=$(printf '%s\n' "$values" | sed -n '9p')
    SETUP_SHA256=$(printf '%s\n' "$values" | sed -n '10p')
    REFERENCE_ENGINE_SHA256=$(printf '%s\n' "$values" | sed -n '11p')
    POST_STATE_CONTRACT_SHA256=$(printf '%s\n' "$values" | sed -n '12p')
    GENERIC_KERNEL_SHA256=$(printf '%s\n' "$values" | sed -n '13p')
    CURRENT_NAMED_INITRD=$(printf '%s\n' "$values" | sed -n '14p')
    CURRENT_NAMED_INITRD_TARGET=$(printf '%s\n' "$values" | sed -n '15p')
    CURRENT_VERSIONED_INITRD=$(printf '%s\n' "$values" | sed -n '16p')
    CURRENT_VERSIONED_INITRD_SHA256=$(printf '%s\n' "$values" | sed -n '17p')
    CURRENT_VERSIONED_INITRD_SIZE=$(printf '%s\n' "$values" | sed -n '18p')
    ACTIVE_GRUB_SHA256=$(printf '%s\n' "$values" | sed -n '19p')
    HOOK_BCACHEFS_SHA256=$(printf '%s\n' "$values" | sed -n '20p')
    HOOK_NVIDIA_SHA256=$(printf '%s\n' "$values" | sed -n '21p')
    REBIND_ARCHIVE_SHA256=$(printf '%s\n' "$values" | sed -n '22p')
    APPLY_REVIEW_ARCHIVE_SHA256=$(printf '%s\n' "$values" | sed -n '23p')
    REVIEWED_CACHE_PACKAGE_COUNT=$(printf '%s\n' "$values" | sed -n '24p')
    [ -n "$RUNNING_KERNEL" ] && [ -n "$PACKAGE_FILENAME" ] \
        && is_sha256 "$PACKAGE_SHA256" && is_sha256 "$CURRENT_VERSIONED_INITRD_SHA256" \
        && is_sha256 "$REBIND_ARCHIVE_SHA256" && is_sha256 "$APPLY_REVIEW_ARCHIVE_SHA256" \
        && [ "$REVIEWED_CACHE_PACKAGE_COUNT" -eq 69 ]
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

read_nested_candidate_digest() {
    local summary=$1 digest
    [ -f "$summary" ] && [ ! -L "$summary" ] || return 1
    digest=$(sed -n 's/^candidate_set_sha256=//p' "$summary")
    [ "$(printf '%s\n' "$digest" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1
    is_sha256 "$digest" || return 1
    printf '%s\n' "$digest"
}

validate_nested_normal_update() {
    local directory=$1
    python3 - "$APPLY_POLICY" "$directory" "$CANDIDATE_SET_SHA256" "$TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, sys
policy_path, directory, expected_digest, target = sys.argv[1:]
root = pathlib.Path(directory)
try:
    policy = json.load(open(policy_path, encoding='utf-8'))
    summary = dict(
        line.rstrip('\n').split('=', 1)
        for line in open(root/'summary.txt', encoding='utf-8')
        if '=' in line
    )
except Exception:
    raise SystemExit(1)

def lines(name):
    path = root/name
    if not path.is_file() or path.is_symlink():
        raise SystemExit(1)
    values = [x.strip() for x in path.read_text(encoding='utf-8').splitlines() if x.strip()]
    if values != sorted(set(values)):
        raise SystemExit(1)
    return values

install = lines('install-new.candidates.txt')
upgrade = lines('upgrade-all.candidates.txt')
all_candidates = lines('all.candidates.txt')
expected_install = policy.get('expected_install_new', [])
expected_all = sorted(policy.get('baseline_candidates', []) + policy.get('reviewed_additions', []))
expected_upgrade = sorted(set(expected_all) - set(expected_install))
raw = ''.join(f'{item}\n' for item in all_candidates).encode()
digest = hashlib.sha256(raw).hexdigest()
checks = [
    summary.get('scenario') == 'normal-update', summary.get('mode') == 'preflight',
    summary.get('target') == 'slackware-current', summary.get('result') == 'PASS',
    summary.get('failures') == '0', summary.get('candidate_set_sha256') == expected_digest,
    digest == expected_digest, all_candidates == expected_all,
    install == expected_install, upgrade == expected_upgrade,
    int(summary.get('install_new_candidates', '-1')) == len(install) == 1,
    int(summary.get('upgrade_candidates', '-1')) == len(upgrade) == 136,
    int(summary.get('total_candidates', '-1')) == len(all_candidates) == 137,
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

validate_reviewed_userspace_cache() {
    python3 - "$ELF_POLICY" "$PACKAGE_CACHE_ROOT" <<'PY'
import hashlib, json, os, pathlib, stat, sys
policy_path, cache_path = sys.argv[1:]
try:
    policy = json.load(open(policy_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
cache = pathlib.Path(cache_path)
try:
    cache_stat = cache.lstat()
except OSError:
    raise SystemExit(1)
if not stat.S_ISDIR(cache_stat.st_mode) or stat.S_ISLNK(cache_stat.st_mode):
    raise SystemExit(1)
records = policy.get('reviewed_packages', [])
if not isinstance(records, list) or len(records) != 68:
    raise SystemExit(1)
for record in records:
    if not isinstance(record, dict):
        raise SystemExit(1)
    name = record.get('package')
    expected_hash = record.get('sha256')
    expected_size = record.get('size')
    if not isinstance(name, str) or '/' in name or not isinstance(expected_hash, str) or len(expected_hash) != 64:
        raise SystemExit(1)
    matches = []
    for root, directories, files in os.walk(cache, followlinks=False):
        directories[:] = sorted(d for d in directories if not pathlib.Path(root, d).is_symlink())
        if name in files:
            matches.append(pathlib.Path(root, name))
    if len(matches) != 1:
        raise SystemExit(1)
    path = matches[0]
    try:
        entry = path.lstat()
    except OSError:
        raise SystemExit(1)
    if not stat.S_ISREG(entry.st_mode) or stat.S_ISLNK(entry.st_mode) or entry.st_size != expected_size:
        raise SystemExit(1)
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    if digest.hexdigest() != expected_hash:
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
    validate_reviewed_userspace_cache || return 1
    [ -d "$(root_path "/lib/modules/$RUNNING_KERNEL")" ] || return 1
    [ ! -e "$(root_path "/lib/modules/$TARGET_KERNEL")" ] || return 1
    [ -d "$(root_path /var/lib/dkms)" ] && [ ! -L "$(root_path /var/lib/dkms)" ] || return 1
    [ -z "$(find "$(root_path /var/lib/dkms)" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ] || return 1
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
  "source_candidate_set_sha256": "$SOURCE_CANDIDATE_SET_SHA256",
  "candidate_set_sha256": "$CANDIDATE_SET_SHA256",
  "fresh_candidate_set_sha256": "$FRESH_CANDIDATE_SHA256",
  "accepted_evidence_count": 10,
  "kernel_evidence_rebind_archive_sha256": "$REBIND_ARCHIVE_SHA256",
  "userspace_apply_review_archive_sha256": "$APPLY_REVIEW_ARCHIVE_SHA256",
  "candidate_count": 137,
  "baseline_candidate_count": 69,
  "added_candidate_count": 68,
  "boot_mode": "geninitrd-managed-versioned-initrd",
  "transition_mode": "versioned-to-versioned-initrd",
  "current_versioned_initrd": "$CURRENT_VERSIONED_INITRD",
  "current_versioned_initrd_sha256": "$CURRENT_VERSIONED_INITRD_SHA256",
  "expected_initrd": "/boot/initrd-$TARGET_KERNEL.img",
  "final_candidate_revalidation_completed": True,
  "final_candidate_revalidation_fresh": True,
  "exact_package_cache_verified": True,
  "reviewed_package_cache_count": $REVIEWED_CACHE_PACKAGE_COUNT,
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
  "next_stage": "$NEXT_STAGE",
  "requires_explicit_apply_authorization": True,
  "requires_apply_time_candidate_revalidation": True,
  "pause_safe": False,
  "pause_safety_reason": "apply-time-candidate-revalidation-and-package-transaction-pending",
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
source_candidate_set_sha256=$SOURCE_CANDIDATE_SET_SHA256
candidate_set_sha256=$CANDIDATE_SET_SHA256
fresh_candidate_set_sha256=$FRESH_CANDIDATE_SHA256
candidate_count=137
baseline_candidate_count=69
added_candidate_count=68
reviewed_package_cache_count=$REVIEWED_CACHE_PACKAGE_COUNT
boot_mode=geninitrd-managed-versioned-initrd
transition_mode=versioned-to-versioned-initrd
current_versioned_initrd=$CURRENT_VERSIONED_INITRD
expected_initrd=/boot/initrd-$TARGET_KERNEL.img
readiness_status=$READINESS_STATUS
final_candidate_revalidation_completed=true
package_transaction_executed=false
mkinitrd_executed=false
geninitrd_executed=false
dkms_build_executed=false
update_grub_executed=false
grub_mkconfig_executed=false
pause_safe=false
pause_safety_reason=apply-time-candidate-revalidation-and-package-transaction-pending
apply_ready=$APPLY_READY
apply_authorized=false
next_stage=$NEXT_STAGE
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
        record_pass "the accepted kernel chain, candidate rebind, and userspace apply review bind target $TARGET_KERNEL"
    else
        record_failure 'the accepted kernel, rebind, or userspace apply-review evidence is inconsistent, stale, or unsafe'
    fi
    if [ "$CANDIDATE_SET_SHA256" = "$CONFIRM_CANDIDATES_SHA256" ] && [ "$TARGET_KERNEL" = "$CONFIRM_TARGET_KERNEL" ]; then
        record_pass 'the explicit candidate and target confirmations match the rebound 137-package transaction'
    else
        record_failure 'the explicit candidate or target confirmation differs from the rebound transaction'
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
    if fresh_digest=$(read_nested_candidate_digest "$nested_dir/summary.txt"); then
        FRESH_CANDIDATE_SHA256=$fresh_digest
    fi
    if validate_nested_normal_update "$nested_dir"; then
        record_pass 'the fresh candidate set exactly matches all 137 reviewed candidates and kernel companions'
    else
        record_failure 'the fresh candidate set differs from the reviewed transaction or is malformed'
    fi
    if verify_nested_archive "$nested_root"; then
        record_pass 'the nested normal-update evidence archive and portable sidecar verify inside the readiness evidence'
    else
        record_failure 'the nested normal-update archive or portable sidecar is missing, ambiguous, or invalid'
    fi
    if validate_live_state; then
        record_pass 'the 69 exact reviewed package archives, versioned GenInitrd boot layout, no-op DKMS state, and GRUB ownership boundary remain reviewed'
    else
        record_failure 'the reviewed package cache, boot, GenInitrd, DKMS, or GRUB state no longer matches the accepted chain'
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
        NEXT_STAGE=normal-update-apply-authorization-review
        APPLY_READY=true
    else
        READINESS_STATUS=blocked
        NEXT_STAGE=current-candidate-chain-refresh-preflight
        APPLY_READY=false
    fi
    write_analysis "$OUTPUT_DIR/readiness-analysis.json"
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current kernel transaction readiness result: running=%s, target=%s, candidates=%s, packages=137, reviewed-cache=69, boot-mode=geninitrd-managed-versioned-initrd, transition=versioned-to-versioned-initrd, readiness=%s, pause-safe=false, apply-ready=%s, apply-authorized=false\n' \
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
