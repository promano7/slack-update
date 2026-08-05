#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
DEFAULT_BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
DEFAULT_CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
DEFAULT_PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
DEFAULT_POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"
DEFAULT_DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
DEFAULT_COMMAND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-geninitrd-grub-ownership-preflight

TARGET=
TARGET_KERNEL=
CONFIRM_CANDIDATES_SHA256=
NORMAL_PREFLIGHT=$DEFAULT_NORMAL_PREFLIGHT
BOOT_PREFLIGHT=$DEFAULT_BOOT_PREFLIGHT
CHAIN_PREFLIGHT=$DEFAULT_CHAIN_PREFLIGHT
PACKAGE_PREFLIGHT=$DEFAULT_PACKAGE_PREFLIGHT
POLICY_PREFLIGHT=$DEFAULT_POLICY_PREFLIGHT
DKMS_PREFLIGHT=$DEFAULT_DKMS_PREFLIGHT
COMMAND_PREFLIGHT=$DEFAULT_COMMAND_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
RUNNING_KERNEL=
GENINITRD_CONFIG=/etc/default/geninitrd
GENINITRD_SCRIPT=/usr/sbin/geninitrd
SETUP_SCRIPT=/var/lib/pkgtools/setup/setup.01.mkinitrd
STRATEGY=unresolved
ENVIRONMENT_OVERRIDE_SAFE=unknown
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Inspect which component owns GRUB regeneration during the reviewed
Slackware-current kernel transaction. The preflight validates all accepted
records, proves that the active GenInitrd policy would overwrite an
AUTO_UPDATE_GRUB environment value, creates only an evidence-local staged
configuration with AUTO_UPDATE_GRUB=false, and emits an ordered transaction
and recovery plan in which Slack-Update owns validated atomic GRUB replacement.
It never changes /etc/default/geninitrd, installs packages, generates an initrd,
or invokes update-grub or grub-mkconfig.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-preflight PATH
      --boot-preflight PATH
      --chain-preflight PATH
      --package-preflight PATH
      --policy-preflight PATH
      --dkms-preflight PATH
      --command-preflight PATH
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
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; TARGET_KERNEL=$2; shift 2 ;;
            --normal-preflight) [ "$#" -ge 2 ] || return 1; NORMAL_PREFLIGHT=$2; shift 2 ;;
            --boot-preflight) [ "$#" -ge 2 ] || return 1; BOOT_PREFLIGHT=$2; shift 2 ;;
            --chain-preflight) [ "$#" -ge 2 ] || return 1; CHAIN_PREFLIGHT=$2; shift 2 ;;
            --package-preflight) [ "$#" -ge 2 ] || return 1; PACKAGE_PREFLIGHT=$2; shift 2 ;;
            --policy-preflight) [ "$#" -ge 2 ] || return 1; POLICY_PREFLIGHT=$2; shift 2 ;;
            --dkms-preflight) [ "$#" -ge 2 ] || return 1; DKMS_PREFLIGHT=$2; shift 2 ;;
            --command-preflight) [ "$#" -ge 2 ] || return 1; COMMAND_PREFLIGHT=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error 'invalid candidate SHA-256'; return 1; }
    CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
    is_safe_kernel_version "$TARGET_KERNEL" || { error 'unsafe target kernel version'; return 1; }
    for path in "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" "$DKMS_PREFLIGHT" "$COMMAND_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_accepted_records() {
    python3 - "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" "$DKMS_PREFLIGHT" "$COMMAND_PREFLIGHT" "$CONFIRM_CANDIDATES_SHA256" "$TARGET_KERNEL" <<'PYCODE'
import json, re, sys
normal_path, boot_path, chain_path, package_path, policy_path, dkms_path, command_path, digest, target = sys.argv[1:]
try:
    normal = json.load(open(normal_path, encoding='utf-8'))
    boot = json.load(open(boot_path, encoding='utf-8'))
    chain = json.load(open(chain_path, encoding='utf-8'))
    package = json.load(open(package_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
    dkms = json.load(open(dkms_path, encoding='utf-8'))
    command = json.load(open(command_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
expected_package = f'kernel-generic-{target}-x86_64-1.txz'
expected_current_initrd = f'/boot/initrd-{boot.get("running_kernel")}.img'
expected_current_target = f'initrd-{boot.get("running_kernel")}.img'
expected_target_initrd = f'/boot/initrd-{target}.img'
def is_sha256(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None
def denied(record):
    return record.get('apply_ready') is False and record.get('apply_authorized') is False
package_sha = package.get('package', {}).get('sha256')
projected = command.get('projected_command_vector', [])
checks = [
    normal.get('scenario') == 'normal-update', normal.get('accepted') is True,
    normal.get('candidates', {}).get('candidate_set_sha256') == digest,
    normal.get('candidates', {}).get('target_kernel_version') == target,
    expected_package in normal.get('candidates', {}).get('upgrade_all', []),
    normal.get('apply_authorized') is False,

    boot.get('scenario') == 'current-kernel-boot-preflight', boot.get('accepted') is True,
    boot.get('normal_update_candidate_set_sha256') == digest,
    boot.get('target_kernel') == target,
    boot.get('boot_mode') == 'geninitrd-managed-versioned-initrd',
    boot.get('named_initrd_path') == '/boot/initrd-generic.img',
    boot.get('named_initrd_target') == expected_current_target,
    boot.get('versioned_initrd_path') == expected_current_initrd,
    is_sha256(boot.get('versioned_initrd_sha256')),
    isinstance(boot.get('versioned_initrd_size'), int) and boot.get('versioned_initrd_size') > 0,
    is_sha256(boot.get('active_grub_sha256')),
    boot.get('geninitrd_transition_required') is True,
    boot.get('target_image_metadata_state') in {'present', 'deferred-to-exact-package-preflight'},
    boot.get('next_stage') == 'current-kernel-chain-restart-preflight', denied(boot),

    chain.get('scenario') == 'current-kernel-chain-restart-preflight', chain.get('accepted') is True,
    chain.get('candidate_set_sha256') == digest,
    chain.get('accepted_boot_archive_sha256') == boot.get('archive_sha256'),
    chain.get('target_kernel') == target,
    chain.get('nested_boot_mode') == boot.get('boot_mode'),
    chain.get('nested_named_initrd_target') == boot.get('named_initrd_target'),
    chain.get('nested_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    chain.get('nested_geninitrd_transition_required') is True,
    chain.get('next_stage') == 'current-kernel-package-preflight', denied(chain),

    package.get('scenario') == 'current-kernel-package-preflight', package.get('accepted') is True,
    package.get('normal_update_candidate_set_sha256') == digest,
    package.get('boot_preflight_archive_sha256') == boot.get('archive_sha256'),
    package.get('chain_restart_archive_sha256') == chain.get('archive_sha256'),
    package.get('running_kernel') == boot.get('running_kernel'), package.get('target_kernel') == target,
    package.get('boot_mode') == boot.get('boot_mode'),
    package.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    package.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    package.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    package.get('package', {}).get('filename') == expected_package,
    is_sha256(package_sha),
    package.get('doinst', {}).get('conditional_geninitrd_hook') is True,
    package.get('next_stage') == 'current-geninitrd-policy-preflight', denied(package),

    policy.get('scenario') == 'current-geninitrd-policy-preflight', policy.get('accepted') is True,
    policy.get('normal_update_candidate_set_sha256') == digest,
    policy.get('boot_preflight_archive_sha256') == boot.get('archive_sha256'),
    policy.get('chain_restart_archive_sha256') == chain.get('archive_sha256'),
    policy.get('package_preflight_archive_sha256') == package.get('archive_sha256'),
    policy.get('running_kernel') == boot.get('running_kernel'), policy.get('target_kernel') == target,
    policy.get('boot_mode') == boot.get('boot_mode'),
    policy.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    policy.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    policy.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    policy.get('policy', {}).get('state') == 'enabled',
    policy.get('policy', {}).get('autogenerate_initrd') is True,
    policy.get('policy', {}).get('named_symlink') is True,
    policy.get('policy', {}).get('initrd_gz_symlink') is False,
    policy.get('policy', {}).get('auto_update_grub') is True,
    policy.get('policy', {}).get('transition_mode') == 'versioned-to-versioned-initrd',
    policy.get('policy', {}).get('expected_initrd') == expected_target_initrd,
    policy.get('next_stage') == 'current-geninitrd-dkms-hook-preflight', denied(policy),

    dkms.get('scenario') == 'current-geninitrd-dkms-hook-preflight', dkms.get('accepted') is True,
    dkms.get('normal_update_candidate_set_sha256') == digest,
    dkms.get('boot_preflight_archive_sha256') == boot.get('archive_sha256'),
    dkms.get('chain_restart_archive_sha256') == chain.get('archive_sha256'),
    dkms.get('package_preflight_archive_sha256') == package.get('archive_sha256'),
    dkms.get('policy_preflight_archive_sha256') == policy.get('archive_sha256'),
    dkms.get('running_kernel') == boot.get('running_kernel'), dkms.get('target_kernel') == target,
    dkms.get('boot_mode') == boot.get('boot_mode'),
    dkms.get('transition_mode') == 'versioned-to-versioned-initrd',
    dkms.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    dkms.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    dkms.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    dkms.get('dkms', {}).get('status_row_count') == 0,
    dkms.get('review_status') == 'accepted-noop-hooks',
    dkms.get('next_stage') == 'current-geninitrd-command-preflight', denied(dkms),

    command.get('scenario') == 'current-geninitrd-command-preflight', command.get('accepted') is True,
    command.get('normal_update_candidate_set_sha256') == digest,
    command.get('boot_preflight_archive_sha256') == boot.get('archive_sha256'),
    command.get('chain_restart_archive_sha256') == chain.get('archive_sha256'),
    command.get('package_preflight_archive_sha256') == package.get('archive_sha256'),
    command.get('policy_preflight_archive_sha256') == policy.get('archive_sha256'),
    command.get('dkms_preflight_archive_sha256') == dkms.get('archive_sha256'),
    command.get('running_kernel') == boot.get('running_kernel'), command.get('target_kernel') == target,
    command.get('boot_mode') == boot.get('boot_mode'),
    command.get('transition_mode') == 'versioned-to-versioned-initrd',
    command.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    command.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    command.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    command.get('package', {}).get('filename') == expected_package,
    command.get('package', {}).get('expected_sha256') == package_sha,
    command.get('package', {}).get('observed_sha256') == package_sha,
    command.get('command_status') == 'projected-safe',
    command.get('projected_initrd') == expected_target_initrd,
    '-k' in projected and target in projected,
    '-o' in projected and expected_target_initrd in projected,
    command.get('generated_command_executed') is False,
    command.get('mkinitrd_executed') is False,
    command.get('geninitrd_executed') is False,
    command.get('update_grub_executed') is False,
    command.get('next_stage') == 'current-geninitrd-grub-ownership-preflight', denied(command),
]
raise SystemExit(0 if all(checks) else 1)
PYCODE
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

capture_sensitive_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in \
        "$GENINITRD_CONFIG" \
        "$GENINITRD_SCRIPT" \
        "$SETUP_SCRIPT" \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$RUNNING_KERNEL" \
        "/boot/vmlinuz-$TARGET_KERNEL" \
        /boot/initrd.gz \
        /boot/initrd-generic.img \
        "/boot/initrd-$RUNNING_KERNEL.img" \
        "/boot/initrd-$TARGET_KERNEL.img" \
        /boot/grub/grub.cfg \
        /var/lib/dkms \
        "/lib/modules/$RUNNING_KERNEL" \
        "/lib/modules/$TARGET_KERNEL"; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

validate_live_geninitrd_baseline() {
    local record=$1 root=$2 output=$3 grub
    grub="$root/boot/grub/grub.cfg"
    [ -f "$grub" ] && [ ! -L "$grub" ] || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    python3 - "$record" "$root" "$output" <<'PY'
import hashlib, json, os, pathlib, re, stat, sys
record_path, root_text, output_path = sys.argv[1:]
root = pathlib.Path(root_text)
record = json.load(open(record_path, encoding='utf-8'))
if record.get('boot_mode') != 'geninitrd-managed-versioned-initrd':
    raise SystemExit('accepted record is not the corrected GenInitrd baseline')
def rooted(path): return root / path.lstrip('/')
def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''): h.update(block)
    return h.hexdigest()
def safe_regular(path, expected_hash=None, expected_size=None):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_size <= 0 or info.st_uid != 0 or info.st_gid != 0 or info.st_mode & 0o022:
        raise SystemExit(f'unsafe regular file: {path}')
    if expected_size is not None and info.st_size != expected_size: raise SystemExit(f'unexpected size: {path}')
    value = digest(path)
    if expected_hash and value != expected_hash: raise SystemExit(f'unexpected hash: {path}')
    return value
def exact_relative_link(path, target):
    info = path.lstat()
    if not stat.S_ISLNK(info.st_mode) or os.readlink(path) != target: raise SystemExit(f'unexpected link: {path}')
def scalar(path, name):
    values=[]; pattern=re.compile(rf'^\s*(?:export\s+)?{re.escape(name)}\s*=\s*(.*?)\s*$')
    for raw in path.read_text(encoding='utf-8', errors='strict').splitlines():
        match=pattern.match(raw.split('#',1)[0].rstrip())
        if match:
            value=match.group(1).strip()
            if len(value)>=2 and value[0]==value[-1] and value[0] in "'\"": value=value[1:-1]
            values.append(value)
    if len(values)!=1: raise SystemExit(f'ambiguous assignment: {name}')
    return values[0]
def grub_pair(path, kernel, initrd):
    blocks=[]; active=None; depth=0
    for line in path.read_text(encoding='utf-8', errors='strict').splitlines():
        stripped=line.strip()
        if active is None and stripped.startswith('menuentry '): active=[]; depth=0
        if active is not None:
            active.append(stripped); depth += stripped.count('{')-stripped.count('}')
            if depth<=0 and len(active)>1: blocks.append(active); active=None
    for block in blocks:
        linux_ok=any(re.match(r'^linux(?:efi)?\s+', line) and kernel in line.split() for line in block)
        initrd_ok=any(re.match(r'^initrd(?:efi)?\s+', line) and initrd in line.split() for line in block)
        if linux_ok and initrd_ok: return True
    return False
if rooted('/etc/mkinitrd.conf').exists() or rooted('/boot/initrd.gz').exists(): raise SystemExit('legacy initrd state is present')
exact_relative_link(rooted('/boot/vmlinuz-generic'), pathlib.PurePosixPath(record['generic_kernel_path']).name)
generic_hash=safe_regular(rooted(record['generic_kernel_path']), record.get('generic_kernel_sha256'))
exact_relative_link(rooted(record['named_initrd_path']), record['named_initrd_target'])
versioned_hash=safe_regular(rooted(record['versioned_initrd_path']), record.get('versioned_initrd_sha256'), record.get('versioned_initrd_size'))
policy=rooted('/etc/default/geninitrd'); safe_regular(policy)
if (scalar(policy,'AUTOGENERATE_INITRD'), scalar(policy,'GENINITRD_NAMED_SYMLINK'), scalar(policy,'GENINITRD_INITRD_GZ_SYMLINK')) != ('true','true','false'):
    raise SystemExit('GenInitrd policy no longer matches the accepted baseline')
grub=rooted('/boot/grub/grub.cfg'); grub_hash=safe_regular(grub, record.get('active_grub_sha256'))
if not grub_pair(grub, record['boot_image'], record['named_initrd_path']): raise SystemExit('GRUB pairing changed')
pathlib.Path(output_path).write_text(
    f"boot_mode={record['boot_mode']}\ntransition_mode=versioned-to-versioned-initrd\n"
    f"generic_kernel_sha256={generic_hash}\nnamed_initrd={record['named_initrd_path']}\n"
    f"named_initrd_target={record['named_initrd_target']}\nversioned_initrd={record['versioned_initrd_path']}\n"
    f"versioned_initrd_sha256={versioned_hash}\nactive_grub_sha256={grub_hash}\n", encoding='utf-8')
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

capture_sensitive_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$RUNNING_KERNEL" \
        "/boot/vmlinuz-$TARGET_KERNEL" \
        /boot/initrd.gz \
        /boot/initrd-generic.img \
        "/boot/initrd-$RUNNING_KERNEL.img" \
        "/boot/initrd-$TARGET_KERNEL.img" \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/mkinitrd.conf \
        "$GENINITRD_SCRIPT" \
        "$SETUP_SCRIPT" \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia \
        /var/lib/dkms \
        "/lib/modules/$RUNNING_KERNEL" \
        "/lib/modules/$TARGET_KERNEL"; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

analyze_grub_ownership() {
    local config=$1 geninitrd=$2 setup=$3 staged=$4 analysis=$5 target=$6
    for path in "$config" "$geninitrd" "$setup"; do
        [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ] || return 1
        [ "$(stat -c '%u' -- "$path")" -eq 0 ] || return 1
        [ $((8#$(stat -c '%a' -- "$path") & 8#022)) -eq 0 ] || return 1
    done
    [ -x "$geninitrd" ] && [ -x "$setup" ] || return 1
    bash -n "$geninitrd" && bash -n "$setup" || return 1
    python3 - "$config" "$geninitrd" "$setup" "$staged" "$analysis" "$target" <<'PY'
import difflib, hashlib, json, os, pathlib, re, shlex, sys
config_path, geninitrd_path, setup_path, staged_path, analysis_path, target = sys.argv[1:]
config = pathlib.Path(config_path)
geninitrd = pathlib.Path(geninitrd_path)
setup = pathlib.Path(setup_path)
staged = pathlib.Path(staged_path)
analysis = pathlib.Path(analysis_path)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def index_after(text, needle, after=-1):
    position = text.find(needle, after + 1)
    if position < 0:
        raise SystemExit(f'missing reviewed control-flow token: {needle}')
    return position

config_text = config.read_text(encoding='utf-8', errors='strict')
gen_text = geninitrd.read_text(encoding='utf-8', errors='strict')
setup_text = setup.read_text(encoding='utf-8', errors='strict')

# geninitrd must load the host policy before invoking the setup handler.
gen_source = index_after(gen_text, 'etc/default/geninitrd')
gen_setup = index_after(gen_text, '/var/lib/pkgtools/setup/setup.01.mkinitrd', gen_source)

# setup.01.mkinitrd must load the policy before applying shell defaults, and
# the guarded update-grub call must occur only after initrd generation.
setup_source = index_after(setup_text, 'etc/default/geninitrd')
setup_default = index_after(setup_text, 'AUTO_UPDATE_GRUB=${AUTO_UPDATE_GRUB:-true}', setup_source)
setup_generate = index_after(setup_text, 'initrd-${KERNEL_VERSION}.img', setup_default)
setup_guard = index_after(setup_text, 'if [ "$AUTO_UPDATE_GRUB" = "true" ]', setup_generate)
setup_update = index_after(setup_text, '/usr/sbin/update-grub', setup_guard)

active = []
for number, raw in enumerate(config_text.splitlines(), 1):
    line = raw.strip()
    if not line or line.startswith('#'):
        continue
    match = re.fullmatch(r'([A-Z][A-Z0-9_]*)=(.*)', line)
    if not match:
        raise SystemExit(f'unsupported active config line {number}')
    key, raw_value = match.groups()
    if any(token in raw_value for token in ('`', '$(', '${', ';', '&&', '||', '\r', '\n')):
        raise SystemExit(f'unsafe active config line {number}')
    try:
        values = shlex.split(raw_value, posix=True)
    except ValueError:
        raise SystemExit(f'invalid quoting at line {number}')
    if len(values) > 1:
        raise SystemExit(f'ambiguous value at line {number}')
    active.append((number, key, values[0] if values else ''))
assignments = [item for item in active if item[1] == 'AUTO_UPDATE_GRUB']
if len(assignments) != 1 or assignments[0][2] != 'true':
    raise SystemExit('AUTO_UPDATE_GRUB must have exactly one active true assignment')
line_number = assignments[0][0]

lines = config_text.splitlines(keepends=True)
original = lines[line_number - 1]
ending = '\n' if original.endswith('\n') else ''
lines[line_number - 1] = 'AUTO_UPDATE_GRUB=false' + ending
staged_text = ''.join(lines)
if staged_text == config_text:
    raise SystemExit('staged policy did not change')
staged.write_text(staged_text, encoding='utf-8')
os.chmod(staged, 0o600)

changed = [line for line in difflib.ndiff(config_text.splitlines(), staged_text.splitlines()) if line.startswith(('- ', '+ '))]
if changed != ['- AUTO_UPDATE_GRUB=true', '+ AUTO_UPDATE_GRUB=false']:
    raise SystemExit('staged policy changed more than AUTO_UPDATE_GRUB')

result = {
    'active_config': str(config),
    'active_config_sha256': digest(config),
    'staged_config': str(staged),
    'staged_config_sha256': digest(staged),
    'staged_diff': changed,
    'environment_override_safe': False,
    'environment_override_reason': 'active-config-assignment-overwrites-environment-before-shell-defaulting',
    'strategy': 'temporary-atomic-policy-override',
    'target_kernel': target,
    'expected_initrd': f'/boot/initrd-{target}.img',
    'update_grub_suppressed_during_package_transaction': True,
    'slack_update_owns_grub_regeneration': True,
    'restore_original_policy_required': True,
    'control_flow': {
        'geninitrd_sources_policy_before_setup': gen_source < gen_setup,
        'setup_sources_policy_before_defaulting': setup_source < setup_default,
        'update_grub_guarded_after_initrd_generation': setup_generate < setup_guard < setup_update,
    },
    'transaction_steps': [
        {'order': 1, 'id': 'final-candidate-revalidation', 'mutating': False},
        {'order': 2, 'id': 'capture-package-boot-policy-baseline', 'mutating': False},
        {'order': 3, 'id': 'stage-root-owned-geninitrd-policy', 'mutating': False},
        {'order': 4, 'id': 'atomically-disable-geninitrd-grub-update', 'mutating': True},
        {'order': 5, 'id': 'run-reviewed-slackpkg-package-transaction', 'mutating': True},
        {'order': 6, 'id': 'verify-target-kernel-modules-and-versioned-initrd', 'mutating': False},
        {'order': 7, 'id': 'atomically-restore-original-geninitrd-policy', 'mutating': True},
        {'order': 8, 'id': 'generate-grub-config-to-owned-temporary-file', 'mutating': True},
        {'order': 9, 'id': 'validate-temporary-grub-config', 'mutating': False},
        {'order': 10, 'id': 'atomically-replace-active-grub-config', 'mutating': True},
        {'order': 11, 'id': 'verify-final-package-boot-policy-state', 'mutating': False},
        {'order': 12, 'id': 'publish-portable-transaction-evidence', 'mutating': True},
    ],
    'recovery_boundaries': [
        {'after': 'atomically-disable-geninitrd-grub-update', 'required': ['restore-original-geninitrd-policy']},
        {'after': 'run-reviewed-slackpkg-package-transaction', 'required': ['restore-original-geninitrd-policy', 'preserve-active-grub-config', 'mark-reboot-unsafe-until-boot-validation']},
        {'after': 'verify-target-kernel-modules-and-versioned-initrd', 'required': ['restore-original-geninitrd-policy', 'preserve-active-grub-config']},
        {'after': 'atomically-restore-original-geninitrd-policy', 'required': ['preserve-active-grub-config-until-temporary-config-validates']},
        {'after': 'atomically-replace-active-grub-config', 'required': ['retain-transaction-evidence', 'require-reviewed-reboot']},
    ],
    'commands_executed': [],
    'mutations_performed': [],
    'apply_ready': False,
    'apply_authorized': False,
    'requires_final_candidate_revalidation': True,
    'requires_separate_apply_authorization': True,
}
analysis.write_text(json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-geninitrd-grub-ownership-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
boot_mode=geninitrd-managed-versioned-initrd
transition_mode=versioned-to-versioned-initrd
current_versioned_initrd=/boot/initrd-$RUNNING_KERNEL.img
expected_initrd=/boot/initrd-$TARGET_KERNEL.img
strategy=$STRATEGY
environment_override_safe=$ENVIRONMENT_OVERRIDE_SAFE
active_policy_changed=false
update_grub_executed=false
grub_mkconfig_executed=false
package_transaction_executed=false
mkinitrd_executed=false
geninitrd_executed=false
commands_executed=0
mutations_performed=0
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-geninitrd-grub-ownership-preflight-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive"
    (cd "$(dirname -- "$archive")" && sha256sum -- "$(basename -- "$archive")" > "$(basename -- "$sidecar")") || return 1
    chmod 0600 -- "$sidecar"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    if id "$owner" >/dev/null 2>&1; then
        group=$(id -gn "$owner")
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
            "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
        printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${sidecar##*/}"
    fi
}

main() {
    local timestamp analysis staged
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in python3 sha256sum tar find bash cmp grub-script-check; do
        command -v "$command" >/dev/null 2>&1 || { error "required command missing: $command"; return 2; }
    done
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"
    RUNNING_KERNEL=$(uname -r)

    validate_accepted_records \
        && record_pass 'the accepted candidate, boot, restarted-chain, package, GenInitrd, DKMS, and command records match this GRUB-ownership inspection' \
        || record_failure 'the accepted records do not match this GRUB-ownership inspection'
    [ "$RUNNING_KERNEL" != "$TARGET_KERNEL" ] && is_safe_kernel_version "$RUNNING_KERNEL" \
        && record_pass "the running kernel $RUNNING_KERNEL remains the reviewed predecessor of $TARGET_KERNEL" \
        || record_failure 'the running and target kernel relationship is unsafe'
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and GRUB-ownership-sensitive state were captured before inspection' \
        || record_failure 'the initial package or GRUB-ownership-sensitive state could not be captured'
    validate_live_geninitrd_baseline "$BOOT_PREFLIGHT" / "$OUTPUT_DIR/live-geninitrd-baseline.txt" \
        && record_pass 'the live generic kernel, versioned initrd, GenInitrd policy, and GRUB pairing match the corrected baseline' \
        || record_failure 'the live GenInitrd-managed boot baseline no longer matches the accepted chain'

    staged=$OUTPUT_DIR/geninitrd.override.staged
    analysis=$OUTPUT_DIR/grub-ownership-analysis.json
    if analyze_grub_ownership "$GENINITRD_CONFIG" "$GENINITRD_SCRIPT" "$SETUP_SCRIPT" "$staged" "$analysis" "$TARGET_KERNEL"; then
        STRATEGY=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["strategy"])' "$analysis")
        ENVIRONMENT_OVERRIDE_SAFE=$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["environment_override_safe"]).lower())' "$analysis")
        record_pass 'the installed GenInitrd scripts and active policy expose the reviewed guarded update-grub control flow'
        record_pass 'an evidence-local policy copy changes only AUTO_UPDATE_GRUB from true to false'
        record_pass 'an environment-only override was rejected and a temporary atomic policy override was selected'
        record_pass 'the ordered package, initrd, policy-restore, and atomic-GRUB transaction plan was generated without execution'
        python3 - "$analysis" <<'PY' \
            && record_pass 'the plan records zero executed commands, zero mutations, and immutable apply denial' \
            || record_failure 'the plan incorrectly records execution, mutation, or apply readiness'
import json,sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
checks=[
 d.get('commands_executed') == [],
 d.get('mutations_performed') == [],
 d.get('apply_ready') is False,
 d.get('apply_authorized') is False,
 d.get('requires_final_candidate_revalidation') is True,
 d.get('requires_separate_apply_authorization') is True,
 len(d.get('transaction_steps', [])) == 12,
 len(d.get('recovery_boundaries', [])) == 5,
]
raise SystemExit(0 if all(checks) else 1)
PY
    else
        record_failure 'the GenInitrd GRUB-ownership policy is unsafe, unsupported, or incomplete'
    fi

    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and GRUB-ownership-sensitive state were captured after inspection' \
        || record_failure 'the final package or GRUB-ownership-sensitive state could not be captured'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during the GRUB-ownership preflight' \
        || record_failure 'the installed package database changed during the GRUB-ownership preflight'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active boot, GenInitrd policy, and GRUB state remained unchanged during the preflight' \
        || record_failure 'the active boot, GenInitrd policy, or GRUB state changed during the preflight'

    APPLY_READY=false
    APPLY_AUTHORIZED=false
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current GenInitrd GRUB ownership result: running=%s, target=%s, transition=versioned-to-versioned-initrd, strategy=%s, environment-override-safe=%s, apply-ready=false, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$STRATEGY" "$ENVIRONMENT_OVERRIDE_SAFE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
