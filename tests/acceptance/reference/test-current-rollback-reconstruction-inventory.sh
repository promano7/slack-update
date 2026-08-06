#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${ROLLBACK_INVENTORY_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-rollback-reconstruction-inventory}
CLOSURE_RECORD=${ROLLBACK_INVENTORY_CLOSURE_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-reboot-verification-20260805-accepted.json}
CLOSURE_POLICY=${ROLLBACK_INVENTORY_CLOSURE_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-reboot-verification-policy.json}
CLOSURE_SCRIPT=${ROLLBACK_INVENTORY_CLOSURE_SCRIPT:-$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-reboot-verification.sh}
RECOVERY_POLICY=${ROLLBACK_INVENTORY_RECOVERY_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-policy.json}
INVENTORY_POLICY=${ROLLBACK_INVENTORY_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-inventory-policy.json}
INVENTORY_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-inventory.sh

TARGET=
OUTPUT_DIR=
SOURCE_ROOT=${ROLLBACK_INVENTORY_SOURCE_ROOT:-/var/cache/packages}
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_CLOSURE_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_INVENTORY_SHA256=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
PACKAGE_DATABASE=
ROOT_PREFIX=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL=
ARCHITECTURE=
ROOT_UUID=
ROOT_SOURCE=
CMDLINE_FILE=
OSRELEASE_FILE=
SOURCE_STATE=unchecked
SOURCE_PACKAGE=
SOURCE_PACKAGE_SHA256=
SOURCE_PACKAGE_SIZE=0
SOURCE_KERNEL_SHA256=
SOURCE_KERNEL_SIZE=0
SOURCE_MODULE_COUNT=0
ROLLBACK_MODULE_STATE=unknown
INSTALLED_MODULE_COUNT=0
BOOT_FREE_BYTES=0
BOOT_REQUIRED_BYTES=0
SPACE_STATE=unchecked
RECONSTRUCTION_VIABLE=false
NEXT_STAGE=current-rollback-reconstruction-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-closure-evidence-sha256 SHA256 \\
                     --confirm-active-kernel VERSION \\
                     --confirm-rollback-kernel VERSION \\
                     --confirm-inventory-sha256 SHA256 [options]

Inventory the feasibility of reconstructing an explicit Slackware-current
rollback kernel from preserved modules and an exact local package archive.
This command is read-only with respect to the installed system. It does not
refresh repository metadata, install or remove packages, create an initrd,
modify GRUB, or reboot the machine.

A missing exact package in the reviewed source root is reported as a successful
inventory with reconstruction_viable=false. Unsafe, ambiguous, corrupt, or
version-mismatched source material fails closed.

Required options:
      --target slackware-current
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-closure-evidence-sha256 SHA256
      --confirm-active-kernel VERSION
      --confirm-rollback-kernel VERSION
      --confirm-inventory-sha256 SHA256

Optional arguments:
      --source-root PATH       Search one absolute local directory tree
                               (default: /var/cache/packages)
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
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
    [ -n "$1" ] || return 1
    case "$1" in *[!0-9A-Za-z._+-]*) return 1 ;; esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-closure-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CLOSURE_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-active-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
            --confirm-rollback-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
            --confirm-inventory-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_INVENTORY_SHA256=${2,,}; shift 2 ;;
            --source-root) [ "$#" -ge 2 ] || return 1; SOURCE_ROOT=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_CLOSURE_EVIDENCE_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_ACTIVE_KERNEL" || return 1
    is_safe_kernel_version "$CONFIRM_ROLLBACK_KERNEL" || return 1
    [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
    is_sha256 "$CONFIRM_INVENTORY_SHA256" || return 1
    case "$SOURCE_ROOT" in /*) ;; *) return 1 ;; esac
    if [ -n "$OUTPUT_DIR" ]; then case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac; fi
}

rooted() { printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
require_regular_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
file_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
file_size() { stat -Lc '%s' -- "$1"; }

policy_value() {
    local file=$1 key=$2
    python3 - "$file" "$key" <<'PY'
import json, sys
value = json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value = value[part]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

validate_reviewed_boundary() {
    python3 - "$CLOSURE_RECORD" "$CLOSURE_POLICY" "$CLOSURE_SCRIPT" "$RECOVERY_POLICY" \
        "$INVENTORY_POLICY" "$INVENTORY_SCRIPT" "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" \
        "$CONFIRM_CLOSURE_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" \
        "$CONFIRM_INVENTORY_SHA256" <<'PY'
import hashlib
import json
import pathlib
import sys

(record_path, closure_policy_path, closure_script_path, recovery_policy_path,
 inventory_policy_path, inventory_script_path, hostname_short, hostname_fqdn,
 closure_archive_sha, active_kernel, rollback_kernel, inventory_scope_sha) = sys.argv[1:]


def load_regular(path):
    p = pathlib.Path(path)
    if not p.is_file() or p.is_symlink():
        raise SystemExit(1)
    return json.loads(p.read_text(encoding='utf-8'))


def digest(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

record = load_regular(record_path)
closure_policy = load_regular(closure_policy_path)
recovery_policy = load_regular(recovery_policy_path)
inventory_policy = load_regular(inventory_policy_path)
record_sha = digest(record_path)
closure_policy_sha = digest(closure_policy_path)
closure_script_sha = digest(closure_script_path)
recovery_policy_sha = digest(recovery_policy_path)
inventory_script_sha = digest(inventory_script_path)
required_root_uuid = inventory_policy.get('required_root_uuid', '')
scope = (
    'operation=current-rollback-reconstruction-inventory\n'
    'target=slackware-current\n'
    f'hostname_short={hostname_short}\n'
    f'hostname_fqdn={hostname_fqdn}\n'
    f'active_kernel={active_kernel}\n'
    f'rollback_kernel={rollback_kernel}\n'
    f'root_uuid={required_root_uuid}\n'
    f'closure_archive_sha256={closure_archive_sha}\n'
    f'closure_record_sha256={record_sha}\n'
    f'closure_policy_sha256={closure_policy_sha}\n'
    f'closure_script_sha256={closure_script_sha}\n'
    f'recovery_policy_sha256={recovery_policy_sha}\n'
    f'inventory_script_sha256={inventory_script_sha}\n'
).encode()
calculated_scope = hashlib.sha256(scope).hexdigest()

checks = [
    record.get('scenario') == 'current-kernel-post-reboot-verification',
    record.get('target') == 'slackware-current',
    record.get('accepted') is True,
    record.get('archive_sha256') == closure_archive_sha,
    record.get('hostname_short') == hostname_short,
    record.get('hostname_fqdn') == hostname_fqdn,
    record.get('running_kernel') == active_kernel,
    record.get('target_kernel') == active_kernel,
    record.get('rollback_state') == 'degraded-modules-only',
    record.get('pause_safe') is True,
    record.get('reboot_verified') is True,
    record.get('update_closed') is True,
    record.get('mandatory_work_remaining') is False,
    record.get('next_stage') == 'optional-rollback-reconstruction-review',
    record.get('post_reboot_verification_policy_sha256') == closure_policy_sha,
    record.get('post_reboot_verification_script_sha256') == closure_script_sha,
    closure_policy.get('scenario') == 'current-kernel-post-reboot-verification',
    closure_policy.get('target') == 'slackware-current',
    closure_policy.get('reviewed') is True,
    closure_policy.get('target_kernel') == active_kernel,
    closure_policy.get('rollback_state_after_reboot') == 'degraded-modules-only',
    closure_policy.get('expected_update_closed') is True,
    closure_policy.get('next_stage') == 'optional-rollback-reconstruction-review',
    recovery_policy.get('scenario') == 'current-post-package-boot-recovery-verification',
    recovery_policy.get('target') == 'slackware-current',
    recovery_policy.get('reviewed') is True,
    recovery_policy.get('target_kernel') == active_kernel,
    recovery_policy.get('rollback', {}).get('state') == 'degraded-running-session-and-modules-only',
    recovery_policy.get('rollback', {}).get('modules_path') == f'/lib/modules/{rollback_kernel}',
    inventory_policy.get('scenario') == 'current-rollback-reconstruction-inventory',
    inventory_policy.get('target') == 'slackware-current',
    inventory_policy.get('reviewed') is True,
    inventory_policy.get('required_hostname_short') == hostname_short,
    inventory_policy.get('required_hostname_fqdn') == hostname_fqdn,
    inventory_policy.get('active_kernel') == active_kernel,
    inventory_policy.get('rollback_kernel') == rollback_kernel,
    inventory_policy.get('accepted_closure_archive_sha256') == closure_archive_sha,
    inventory_policy.get('accepted_closure_record_sha256') == record_sha,
    inventory_policy.get('closure_policy_sha256') == closure_policy_sha,
    inventory_policy.get('closure_script_sha256') == closure_script_sha,
    inventory_policy.get('recovery_policy_sha256') == recovery_policy_sha,
    inventory_policy.get('inventory_script_sha256') == inventory_script_sha,
    inventory_policy.get('inventory_scope_sha256') == inventory_scope_sha == calculated_scope,
    inventory_policy.get('repository_refresh_allowed') is False,
    inventory_policy.get('package_mutation_allowed') is False,
    inventory_policy.get('initrd_mutation_allowed') is False,
    inventory_policy.get('grub_mutation_allowed') is False,
    inventory_policy.get('reboot_execution_allowed') is False,
]
raise SystemExit(0 if all(checks) else 1)
PY
}

capture_package_database() {
    local output=$1
    (
        cd "$PACKAGE_DATABASE" || exit 1
        find . -maxdepth 1 -type f -printf '%P\0' | LC_ALL=C sort -z |
            while IFS= read -r -d '' record; do sha256sum -- "$record"; done
    ) > "$output"
}

capture_package_names() {
    local output=$1
    (
        cd "$PACKAGE_DATABASE" || exit 1
        find . -maxdepth 1 -type f -printf '%P\n' | LC_ALL=C sort
    ) > "$output"
}

capture_path_state() {
    local path=$1 output=$2 type metadata digest target
    if [ -L "$path" ]; then
        target=$(readlink -- "$path") || return 1
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}') || digest=
        printf '%s|symlink|%s|%s|%s\n' "${path#$ROOT_PREFIX}" "$target" "$metadata" "$digest" >> "$output"
    elif [ -f "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(file_sha256 "$path") || return 1
        printf '%s|regular||%s|%s\n' "${path#$ROOT_PREFIX}" "$metadata" "$digest" >> "$output"
    elif [ -d "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|directory||%s|\n' "${path#$ROOT_PREFIX}" "$metadata" >> "$output"
    elif [ -e "$path" ]; then
        type=$(stat -c '%F' -- "$path" 2>/dev/null || printf unknown)
        printf '%s|unsafe-%s|||\n' "${path#$ROOT_PREFIX}" "$type" >> "$output"
    else
        printf '%s|missing|||\n' "${path#$ROOT_PREFIX}" >> "$output"
    fi
}

capture_sensitive_state() {
    local output=$1 path
    : > "$output"
    for path in \
        /proc/cmdline \
        /proc/sys/kernel/osrelease \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL" \
        "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL" \
        /boot/initrd-generic.img \
        "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img" \
        "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img" \
        /boot/grub/grub.cfg \
        /boot/grub/grubenv \
        /etc/default/geninitrd \
        /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        "/lib/modules/$CONFIRM_ACTIVE_KERNEL" \
        "/lib/modules/$CONFIRM_ROLLBACK_KERNEL"; do
        capture_path_state "$(rooted "$path")" "$output" || return 1
    done
}

validate_package_state() {
    local snapshot=$1 names=$2 expected_count expected_snapshot expected_names count
    expected_count=$(policy_value "$RECOVERY_POLICY" installed_package_count) || return 1
    expected_snapshot=$(policy_value "$RECOVERY_POLICY" installed_package_database_snapshot_sha256) || return 1
    expected_names=$(policy_value "$RECOVERY_POLICY" installed_package_name_snapshot_sha256) || return 1
    count=$(wc -l < "$names") || return 1
    [ "$count" -eq "$expected_count" ] || return 1
    [ "$(file_sha256 "$snapshot")" = "$expected_snapshot" ] || return 1
    [ "$(file_sha256 "$names")" = "$expected_names" ]
}

validate_package_records() {
    python3 - "$RECOVERY_POLICY" "$PACKAGE_DATABASE" <<'PY'
import hashlib, json, pathlib, sys
policy = json.load(open(sys.argv[1], encoding='utf-8'))
root = pathlib.Path(sys.argv[2])
for record in policy['required_package_records']:
    path = root / record['name']
    if not path.is_file() or path.is_symlink():
        raise SystemExit(1)
    if hashlib.sha256(path.read_bytes()).hexdigest() != record['record_sha256']:
        raise SystemExit(1)
for name in policy['forbidden_package_records']:
    path = root / name
    if path.exists() or path.is_symlink():
        raise SystemExit(1)
raise SystemExit(0)
PY
}

validate_exact_regular() {
    local path=$1 expected_sha=$2 expected_size=$3 mode uid gid metadata
    [ -f "$path" ] && [ ! -L "$path" ] || return 1
    metadata=$(stat -Lc '%a %u %g' -- "$path") || return 1
    IFS=' ' read -r mode uid gid <<< "$metadata"
    [ "$uid" -eq 0 ] && [ "$gid" -eq 0 ] || return 1
    case "$mode" in 600|644|700|755) ;; *) return 1 ;; esac
    [ "$(file_size "$path")" -eq "$expected_size" ] || return 1
    [ "$(file_sha256 "$path")" = "$expected_sha" ]
}

validate_live_identity() {
    local expected_uuid expected_image osrelease
    expected_uuid=$(policy_value "$INVENTORY_POLICY" required_root_uuid) || return 1
    expected_image=$(policy_value "$INVENTORY_POLICY" required_boot_image) || return 1
    osrelease=$(tr -d '\n' < "$OSRELEASE_FILE") || return 1
    [ "$HOSTNAME_SHORT" = "$CONFIRM_HOSTNAME" ] || return 1
    [ "$HOSTNAME_FQDN" = "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    [ "$RUNNING_KERNEL" = "$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ "$osrelease" = "$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ "$ARCHITECTURE" = x86_64 ] || return 1
    [ "$ROOT_UUID" = "$expected_uuid" ] || return 1
    python3 - "$CMDLINE_FILE" "$expected_image" "$expected_uuid" "$ROOT_SOURCE" "$OUTPUT_DIR/live-identity.json" <<'PY'
import json, pathlib, shlex, sys
cmdline_path, expected_image, expected_uuid, root_source, output = sys.argv[1:]
try:
    cmdline = pathlib.Path(cmdline_path).read_text(encoding='utf-8').strip()
    tokens = shlex.split(cmdline)
except Exception:
    raise SystemExit(1)
boot_images = [x.split('=', 1)[1] for x in tokens if x.startswith('BOOT_IMAGE=')]
roots = [x.split('=', 1)[1] for x in tokens if x.startswith('root=')]
if boot_images != [expected_image] or roots != [f'UUID={expected_uuid}'] or not root_source:
    raise SystemExit(1)
pathlib.Path(output).write_text(json.dumps({
    'boot_image': boot_images[0],
    'cmdline': cmdline,
    'root_argument': roots[0],
    'root_source': root_source,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

validate_active_artifacts() {
    local kernel initrd modules kernel_link initrd_link
    kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL")
    initrd=$(rooted "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img")
    modules=$(rooted "/lib/modules/$CONFIRM_ACTIVE_KERNEL")
    kernel_link=$(rooted /boot/vmlinuz-generic)
    initrd_link=$(rooted /boot/initrd-generic.img)
    validate_exact_regular "$kernel" "$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_sha256)" "$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_size)" || return 1
    validate_exact_regular "$initrd" "$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_sha256)" "$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_size)" || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    find "$modules" -mindepth 1 -print -quit | grep -q . || return 1
    [ -L "$kernel_link" ] && [ "$(readlink -- "$kernel_link")" = "vmlinuz-$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ -L "$initrd_link" ] && [ "$(readlink -- "$initrd_link")" = "initrd-$CONFIRM_ACTIVE_KERNEL.img" ]
}

classify_rollback_modules() {
    local modules output
    modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    output=$OUTPUT_DIR/rollback-modules.json
    [ ! -e "$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")" ] && [ ! -L "$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")" ] || return 1
    [ ! -e "$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")" ] && [ ! -L "$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")" ] || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    python3 - "$modules" "$CONFIRM_ROLLBACK_KERNEL" "$output" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
version = sys.argv[2]
out = pathlib.Path(sys.argv[3])
all_members = sorted(p.relative_to(root).as_posix() for p in root.rglob('*'))
required = ['modules.alias', 'modules.builtin', 'modules.dep']
missing = [name for name in required if not (root / name).is_file() or (root / name).is_symlink()]
module_files = sorted(
    p.relative_to(root).as_posix() for p in root.rglob('*')
    if p.is_file() and not p.is_symlink() and '/kernel/' in f'/{p.relative_to(root).as_posix()}'
    and any(p.name.endswith(ext) for ext in ('.ko', '.ko.gz', '.ko.xz', '.ko.zst'))
)
if not all_members:
    state = 'empty-directory-placeholder'
elif not missing and module_files:
    state = 'preserved-populated-module-tree'
else:
    raise SystemExit(1)
out.write_text(json.dumps({
    'kernel_version': version,
    'member_count': len(all_members),
    'module_file_count': len(module_files),
    'required_metadata': required,
    'required_metadata_missing': missing,
    'state': state,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
print(f'{state} {len(module_files)}')
PY
}
validate_geninitrd_boundary() {
    validate_exact_regular "$(rooted /etc/default/geninitrd)" "$(policy_value "$RECOVERY_POLICY" geninitrd.policy_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.policy_size)" || return 1
    validate_exact_regular "$(rooted /usr/sbin/geninitrd)" "$(policy_value "$RECOVERY_POLICY" geninitrd.geninitrd_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.geninitrd_size)" || return 1
    validate_exact_regular "$(rooted /usr/share/mkinitrd/mkinitrd_command_generator.sh)" "$(policy_value "$RECOVERY_POLICY" geninitrd.generator_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.generator_size)" || return 1
    validate_exact_regular "$(rooted /var/lib/pkgtools/setup/setup.01.mkinitrd)" "$(policy_value "$RECOVERY_POLICY" geninitrd.setup_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.setup_size)"
}

capture_grubenv() {
    local output=$1 grubenv
    grubenv=$(rooted /boot/grub/grubenv)
    if [ -e "$grubenv" ] || [ -L "$grubenv" ]; then
        [ -f "$grubenv" ] && [ ! -L "$grubenv" ] || return 1
        grub-editenv "$grubenv" list > "$output" 2>/dev/null || return 1
    else
        : > "$output"
    fi
}

validate_effective_grub_selection() {
    local grub=$1 env_list=$2 required_kernel=$3 required_initrd=$4 output=$5
    python3 - "$grub" "$env_list" "$required_kernel" "$required_initrd" "$output" <<'PY'
import json, pathlib, re, shlex, sys
grub_path, env_path, required_kernel, required_initrd, output = sys.argv[1:]
lines = pathlib.Path(grub_path).read_text(encoding='utf-8', errors='strict').splitlines()
env = {}
for raw in pathlib.Path(env_path).read_text(encoding='utf-8', errors='strict').splitlines():
    if not raw.strip(): continue
    if '=' not in raw: raise SystemExit(1)
    key, value = raw.split('=', 1)
    if key in env: raise SystemExit(1)
    env[key] = value
if env.get('next_entry', '').strip(): raise SystemExit(1)

def quoted_value(text):
    try: tokens = shlex.split(text, comments=False, posix=True)
    except ValueError: raise SystemExit(1)
    if not tokens: raise SystemExit(1)
    return tokens[0]

def entry_identity(text):
    match = re.search(r'(?:^|\s)--id(?:=|\s+)([^\s{]+)', text)
    return match.group(1).strip('"\'') if match else ''

roots=[]; stack=[]; conditions=[]; assignments=[]; function_depth=0

def condition_value(text):
    if re.search(r'\$\{?next_entry\}?', text): return bool(env.get('next_entry', '').strip())
    return None

def branch_state():
    unknown=False
    for item in conditions:
        value=item['value']
        if item['else']: value = None if value is None else not value
        if value is False: return False
        if value is None: unknown=True
    return None if unknown else True

for raw in lines:
    line=raw.strip()
    if not line or line.startswith('#'): continue
    if function_depth:
        if line == '}': function_depth -= 1
        elif re.match(r'^function\s+[^\s{]+\s*\{\s*$', line): function_depth += 1
        continue
    if not stack and re.match(r'^function\s+[^\s{]+\s*\{\s*$', line):
        function_depth=1; continue
    if not stack:
        if re.match(r'^if\b.*\bthen\s*$', line): conditions.append({'value':condition_value(line),'else':False}); continue
        if line == 'else':
            if not conditions or conditions[-1]['else']: raise SystemExit(1)
            conditions[-1]['else']=True; continue
        if line == 'fi':
            if not conditions: raise SystemExit(1)
            conditions.pop(); continue
        match=re.match(r'^set\s+default=(.*?)\s*$', line)
        if match:
            state=branch_state()
            if state is None: raise SystemExit(1)
            if state: assignments.append(match.group(1))
            continue
    opener=re.match(r'^(menuentry|submenu)\s+(.*)$', line)
    if opener:
        kind, rest=opener.groups()
        node={'kind':kind,'title':quoted_value(rest),'id':entry_identity(rest),'lines':[],'children':[]}
        (stack[-1]['children'] if stack else roots).append(node); stack.append(node); continue
    if line == '}' and stack: stack.pop(); continue
    if stack: stack[-1]['lines'].append(line)
if stack or conditions or not roots or len(assignments) != 1: raise SystemExit(1)
expr=assignments[0].strip()
if expr in ('${saved_entry}','"${saved_entry}"',"'${saved_entry}'",'$saved_entry','"$saved_entry"',"'$saved_entry'"):
    selector=env.get('saved_entry','')
else:
    match=re.fullmatch(r"(['\"])(.*?)\1", expr)
    if match: selector=match.group(2)
    elif re.fullmatch(r'[A-Za-z0-9_.+:-]+(?:>[A-Za-z0-9_.+:-]+)*', expr): selector=expr
    else: raise SystemExit(1)
selector=selector.strip() or '0'

def resolve(entries, segment):
    if segment.isdigit():
        index=int(segment); return entries[index] if 0 <= index < len(entries) else None
    matches=[entry for entry in entries if segment in (entry['id'],entry['title'])]
    return matches[0] if len(matches)==1 else None
entries=roots; selected=None
for pos, segment in enumerate(selector.split('>')):
    selected=resolve(entries, segment)
    if selected is None: raise SystemExit(1)
    if pos < len(selector.split('>')) - 1:
        if selected['kind'] != 'submenu': raise SystemExit(1)
        entries=selected['children']
if selected is None or selected['kind'] != 'menuentry': raise SystemExit(1)
linux=[line for line in selected['lines'] if re.match(r'^linux(?:efi)?\s+',line)]
initrd=[line for line in selected['lines'] if re.match(r'^initrd(?:efi)?\s+',line)]
if len(linux)!=1 or required_kernel not in linux[0].split(): raise SystemExit(1)
if len(initrd)!=1 or required_initrd not in initrd[0].split(): raise SystemExit(1)
pathlib.Path(output).write_text(json.dumps({
    'next_entry_present': False,
    'required_initrd': required_initrd,
    'required_kernel': required_kernel,
    'selected_entry_id': selected['id'],
    'selected_entry_title': selected['title'],
    'selector': selector,
    'selector_expression': expr,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

validate_active_grub() {
    local grub env_list
    grub=$(rooted /boot/grub/grub.cfg)
    env_list=$OUTPUT_DIR/grubenv.list
    validate_exact_regular "$grub" "$(policy_value "$RECOVERY_POLICY" active_grub.sha256)" "$(policy_value "$RECOVERY_POLICY" active_grub.size)" || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    capture_grubenv "$env_list" || return 1
    validate_effective_grub_selection "$grub" "$env_list" "/boot/vmlinuz-generic" "/boot/initrd-generic.img" "$OUTPUT_DIR/grub-selection.json"
}

resolve_source_package() {
    local search_root=$1 expected output matches candidate canonical_root canonical_candidate
    expected="kernel-generic-$CONFIRM_ROLLBACK_KERNEL-x86_64-1.txz"
    output=$OUTPUT_DIR/source-candidates.txt
    : > "$output"
    [ -d "$search_root" ] && [ ! -L "$search_root" ] || return 1
    while IFS= read -r -d '' candidate; do printf '%s\n' "$candidate" >> "$output"; done < <(find "$search_root" -name "$expected" -print0 2>/dev/null | LC_ALL=C sort -z)
    matches=$(wc -l < "$output") || return 1
    if [ "$matches" -eq 0 ]; then
        SOURCE_STATE=not-found-in-reviewed-root
        return 3
    fi
    [ "$matches" -eq 1 ] || return 1
    candidate=$(cat "$output") || return 1
    [ -f "$candidate" ] && [ ! -L "$candidate" ] || return 1
    canonical_root=$(readlink -f -- "$search_root") || return 1
    canonical_candidate=$(readlink -f -- "$candidate") || return 1
    case "$canonical_candidate" in "$canonical_root"/*) ;; *) return 1 ;; esac
    SOURCE_PACKAGE=$canonical_candidate
}

inspect_source_package() {
    local package=$1 summary=$2 package_modules=$3
    python3 - "$package" "$CONFIRM_ROLLBACK_KERNEL" "$summary" "$package_modules" <<'PY'
import hashlib, json, pathlib, posixpath, tarfile, sys
package = pathlib.Path(sys.argv[1])
version = sys.argv[2]
summary = pathlib.Path(sys.argv[3])
module_manifest = pathlib.Path(sys.argv[4])
expected_name = f'kernel-generic-{version}-x86_64-1.txz'
if package.name != expected_name or not package.is_file() or package.is_symlink():
    raise SystemExit(1)

def normalize(name):
    while name.startswith('./'): name = name[2:]
    if not name or name.startswith('/'):
        raise SystemExit(1)
    normalized = posixpath.normpath(name)
    if normalized in ('', '.', '..') or normalized.startswith('../'):
        raise SystemExit(1)
    return normalized

def safe_link(member_name, target):
    if not target or target.startswith('/'):
        return False
    resolved = posixpath.normpath(posixpath.join(posixpath.dirname(member_name), target))
    return resolved not in ('', '.', '..') and not resolved.startswith('../')

seen=set(); kernel=None; module_paths=[]; member_count=0
with tarfile.open(package, mode='r:*') as archive:
    for member in archive:
        member_count += 1
        name=normalize(member.name)
        if name in seen: raise SystemExit(1)
        seen.add(name)
        if member.issym() or member.islnk():
            if not safe_link(name, member.linkname): raise SystemExit(1)
        if name == f'boot/vmlinuz-{version}':
            if not member.isfile() or kernel is not None: raise SystemExit(1)
            extracted=archive.extractfile(member)
            if extracted is None: raise SystemExit(1)
            h=hashlib.sha256(); size=0
            while True:
                chunk=extracted.read(1024*1024)
                if not chunk: break
                size += len(chunk); h.update(chunk)
            if size <= 0: raise SystemExit(1)
            kernel={'path':'/'+name,'sha256':h.hexdigest(),'size':size}
        prefix=f'lib/modules/{version}/kernel/'
        if name.startswith(prefix) and member.isfile() and name.endswith(('.ko','.ko.gz','.ko.xz','.ko.zst')):
            module_paths.append(name[len(f'lib/modules/{version}/'):])
if kernel is None or not module_paths:
    raise SystemExit(1)
module_paths=sorted(module_paths)
module_manifest.write_text(''.join(path+'\n' for path in module_paths), encoding='utf-8')
package_hash=hashlib.sha256()
with package.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024*1024), b''): package_hash.update(chunk)
summary.write_text(json.dumps({
    'filename': package.name,
    'kernel': kernel,
    'member_count': member_count,
    'module_file_count': len(module_paths),
    'package_path': str(package),
    'package_sha256': package_hash.hexdigest(),
    'package_size': package.stat().st_size,
    'paths_safe': True,
    'source_state': 'exact-local-package',
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

capture_installed_module_manifest() {
    local output=$1 modules
    modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    python3 - "$modules" "$output" <<'PY'
import pathlib, sys
root=pathlib.Path(sys.argv[1]); out=pathlib.Path(sys.argv[2])
paths=sorted(
    p.relative_to(root).as_posix() for p in root.rglob('*')
    if p.is_file() and not p.is_symlink() and '/kernel/' in f'/{p.relative_to(root).as_posix()}'
    and p.name.endswith(('.ko','.ko.gz','.ko.xz','.ko.zst'))
)
if not paths: raise SystemExit(1)
out.write_text(''.join(path+'\n' for path in paths), encoding='utf-8')
PY
}

load_source_summary() {
    local summary=$1
    IFS=$'\t' read -r SOURCE_PACKAGE_SHA256 SOURCE_PACKAGE_SIZE SOURCE_KERNEL_SHA256 SOURCE_KERNEL_SIZE SOURCE_MODULE_COUNT < <(
        python3 - "$summary" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
print(d['package_sha256'], d['package_size'], d['kernel']['sha256'], d['kernel']['size'], d['module_file_count'], sep='\t')
PY
    )
}

validate_source_boundary_unchanged() {
    local expected matches
    expected="kernel-generic-$CONFIRM_ROLLBACK_KERNEL-x86_64-1.txz"
    case "$SOURCE_STATE" in
        exact-local-package)
            [ -f "$SOURCE_PACKAGE" ] && [ ! -L "$SOURCE_PACKAGE" ] || return 1
            [ "$(file_size "$SOURCE_PACKAGE")" -eq "$SOURCE_PACKAGE_SIZE" ] || return 1
            [ "$(file_sha256 "$SOURCE_PACKAGE")" = "$SOURCE_PACKAGE_SHA256" ] || return 1
            ;;
        not-found-in-reviewed-root)
            matches=$(find "$SOURCE_ROOT" -name "$expected" -print -quit 2>/dev/null) || return 1
            [ -z "$matches" ]
            ;;
        *)
            return 1
            ;;
    esac
}

measure_boot_space() {
    local boot_path free_k reserve baseline_kernel baseline_initrd grub_size
    boot_path=$(rooted /boot)
    if [ "$TEST_MODE" = 1 ] && [ -n "${SLACK_UPDATE_TEST_BOOT_FREE_BYTES:-}" ]; then
        BOOT_FREE_BYTES=$SLACK_UPDATE_TEST_BOOT_FREE_BYTES
    else
        free_k=$(df -Pk -- "$boot_path" | awk 'NR==2 {print $4}') || return 1
        case "$free_k" in ''|*[!0-9]*) return 1 ;; esac
        BOOT_FREE_BYTES=$((free_k * 1024))
    fi
    reserve=$(policy_value "$INVENTORY_POLICY" minimum_free_space_reserve_bytes) || return 1
    baseline_kernel=$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_size) || return 1
    baseline_initrd=$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_size) || return 1
    grub_size=$(policy_value "$RECOVERY_POLICY" active_grub.size) || return 1
    if [ "$SOURCE_KERNEL_SIZE" -gt 0 ]; then baseline_kernel=$SOURCE_KERNEL_SIZE; fi
    BOOT_REQUIRED_BYTES=$((baseline_kernel + baseline_initrd + (3 * grub_size) + reserve))
    if [ "$BOOT_FREE_BYTES" -ge "$BOOT_REQUIRED_BYTES" ]; then SPACE_STATE=sufficient
    else SPACE_STATE=insufficient
    fi
    python3 - "$OUTPUT_DIR/boot-space.json" "$BOOT_FREE_BYTES" "$BOOT_REQUIRED_BYTES" "$reserve" "$baseline_kernel" "$baseline_initrd" "$grub_size" "$SPACE_STATE" <<'PY'
import json, pathlib, sys
out, free, required, reserve, kernel, initrd, grub, state = sys.argv[1:]
pathlib.Path(out).write_text(json.dumps({
    'available_bytes': int(free),
    'estimated_kernel_bytes': int(kernel),
    'estimated_initrd_bytes': int(initrd),
    'grub_configuration_bytes': int(grub),
    'minimum_free_space_reserve_bytes': int(reserve),
    'required_bytes': int(required),
    'state': state,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_analysis() {
    python3 - "$OUTPUT_DIR/rollback-inventory-analysis.json" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" \
        "$RUNNING_KERNEL" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ROOT_UUID" "$ROOT_SOURCE" \
        "$SOURCE_ROOT" "$SOURCE_STATE" "$SOURCE_PACKAGE" "$SOURCE_PACKAGE_SHA256" "$SOURCE_PACKAGE_SIZE" \
        "$SOURCE_KERNEL_SHA256" "$SOURCE_KERNEL_SIZE" "$SOURCE_MODULE_COUNT" "$ROLLBACK_MODULE_STATE" "$INSTALLED_MODULE_COUNT" \
        "$BOOT_FREE_BYTES" "$BOOT_REQUIRED_BYTES" "$SPACE_STATE" "$RECONSTRUCTION_VIABLE" "$NEXT_STAGE" \
        "$PASS_COUNT" "$FAILURE_COUNT" "$CONFIRM_CLOSURE_EVIDENCE_SHA256" "$CONFIRM_INVENTORY_SHA256" <<'PY'
import json, pathlib, sys
(out, host, fqdn, running, active, rollback, root_uuid, root_source, source_root,
 source_state, package_path, package_sha, package_size, kernel_sha, kernel_size,
 source_modules, module_state, installed_modules, free_bytes, required_bytes, space_state,
 viable, next_stage, passes, failures, closure_sha, inventory_sha) = sys.argv[1:]
def number(value): return int(value or 0)
data={
 'scenario':'current-rollback-reconstruction-inventory','target':'slackware-current',
 'hostname_short':host,'hostname_fqdn':fqdn,'running_kernel':running,
 'active_kernel':active,'rollback_kernel':rollback,'root_uuid':root_uuid,'root_source':root_source,
 'accepted_closure_archive_sha256':closure_sha,'inventory_scope_sha256':inventory_sha,
 'source_search_root':source_root,'source_state':source_state,
 'source_package': None if not package_path else {'path':package_path,'sha256':package_sha,'size':number(package_size)},
 'source_kernel': None if not kernel_sha else {'sha256':kernel_sha,'size':number(kernel_size)},
 'source_module_file_count':number(source_modules),'rollback_module_state':module_state,'installed_module_file_count':number(installed_modules),
 'boot_space':{'available_bytes':number(free_bytes),'required_bytes':number(required_bytes),'state':space_state},
 'repository_metadata_refreshed':False,'package_mutation_performed':False,'initrd_generated':False,
 'grub_mutation_performed':False,'reboot_performed':False,'host_mutated':False,
 'reconstruction_viable': viable == 'true','next_stage':next_stage,
 'assertions':{'passes':int(passes),'failures':int(failures)},
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-rollback-reconstruction-inventory
target=$TARGET
hostname_short=$HOSTNAME_SHORT
hostname_fqdn=$HOSTNAME_FQDN
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
root_uuid=$ROOT_UUID
root_source=$ROOT_SOURCE
closure_evidence_sha256=$CONFIRM_CLOSURE_EVIDENCE_SHA256
inventory_scope_sha256=$CONFIRM_INVENTORY_SHA256
source_search_root=$SOURCE_ROOT
source_state=$SOURCE_STATE
source_package=$SOURCE_PACKAGE
source_package_sha256=$SOURCE_PACKAGE_SHA256
source_kernel_sha256=$SOURCE_KERNEL_SHA256
source_kernel_size=$SOURCE_KERNEL_SIZE
source_module_file_count=$SOURCE_MODULE_COUNT
rollback_module_state=$ROLLBACK_MODULE_STATE
installed_module_file_count=$INSTALLED_MODULE_COUNT
boot_free_bytes=$BOOT_FREE_BYTES
boot_required_bytes=$BOOT_REQUIRED_BYTES
space_state=$SPACE_STATE
repository_metadata_refreshed=false
package_mutation_performed=false
initrd_generated=false
grub_mutation_performed=false
reboot_performed=false
host_mutated=false
reconstruction_viable=$RECONSTRUCTION_VIABLE
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    if [ "$TEST_MODE" = 1 ]; then
        printf 'Evidence directory (test mode): %s\n' "$OUTPUT_DIR"
        return 0
    fi
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-current-rollback-reconstruction-inventory-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive"
    (cd "$(dirname -- "$archive")" && sha256sum -- "$(basename -- "$archive")" > "$(basename -- "$sidecar")") || return 1
    chmod 0600 -- "$sidecar"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    [ -n "$owner" ] && [ "$owner" != root ] || owner=promano
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
        "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${sidecar##*/}"
}

finish() {
    write_analysis || return 2
    write_summary
    printf 'Slackware-current rollback inventory: active=%s, rollback=%s, source=%s, module-state=%s, modules=%s, space=%s, viable=%s, next-stage=%s\n' \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$SOURCE_STATE" "$ROLLBACK_MODULE_STATE" "$INSTALLED_MODULE_COUNT" "$SPACE_STATE" "$RECONSTRUCTION_VIABLE" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

main() {
    local timestamp slackware_version source_result
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this rollback inventory must run as root'; return 2; }

    if [ "$TEST_MODE" = 1 ]; then
        ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
        [ -n "$ROOT_PREFIX" ] || { error 'test root is missing'; return 2; }
        PATH=${SLACK_UPDATE_TEST_PATH:-$PATH}
        HOSTNAME_SHORT=${SLACK_UPDATE_TEST_HOSTNAME_SHORT:-pcold-slack}
        HOSTNAME_FQDN=${SLACK_UPDATE_TEST_HOSTNAME_FQDN:-pcold-slack.pcold-slack.org}
        RUNNING_KERNEL=${SLACK_UPDATE_TEST_RUNNING_KERNEL:-6.18.42}
        ARCHITECTURE=${SLACK_UPDATE_TEST_ARCHITECTURE:-x86_64}
        ROOT_UUID=${SLACK_UPDATE_TEST_ROOT_UUID:-ba7632d7-7469-483e-830d-59c88d985866}
        ROOT_SOURCE=${SLACK_UPDATE_TEST_ROOT_SOURCE:-/dev/test-root}
    else
        ROOT_PREFIX=
        HOSTNAME_SHORT=$(hostname -s) || return 2
        HOSTNAME_FQDN=$(hostname -f) || return 2
        RUNNING_KERNEL=$(uname -r) || return 2
        ARCHITECTURE=$(uname -m) || return 2
        ROOT_UUID=$(findmnt -n -o UUID /) || return 2
        ROOT_SOURCE=$(findmnt -n -o SOURCE /) || return 2
    fi
    CMDLINE_FILE=$(rooted /proc/cmdline)
    OSRELEASE_FILE=$(rooted /proc/sys/kernel/osrelease)

    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk bash chmod cmp date df find findmnt grep grub-editenv grub-script-check hostname id mkdir python3 readlink sha256sum sort stat tar tee tr uname wc; do
        if [ "$TEST_MODE" = 1 ] && { [ "$command_name" = findmnt ] || [ "$command_name" = hostname ] || [ "$command_name" = uname ]; }; then continue; fi
        command -v "$command_name" >/dev/null 2>&1 || { error "required command missing: $command_name"; return 2; }
    done
    for reviewed_file in "$CLOSURE_RECORD" "$CLOSURE_POLICY" "$CLOSURE_SCRIPT" "$RECOVERY_POLICY" "$INVENTORY_POLICY" "$INVENTORY_SCRIPT"; do
        require_regular_file "$reviewed_file" || { error "reviewed file is missing or unsafe: $reviewed_file"; return 2; }
    done
    bash -n "$CLOSURE_SCRIPT" || { error 'closure verification script has invalid shell syntax'; return 2; }
    bash -n "$INVENTORY_SCRIPT" || { error 'rollback inventory script has invalid shell syntax'; return 2; }
    for live_file in "$CMDLINE_FILE" "$OSRELEASE_FILE"; do require_regular_file "$live_file" || { error "live boot identity file is missing or unsafe: $live_file"; return 2; }; done

    if [ -d "$(rooted /var/lib/pkgtools/packages)" ] && [ ! -L "$(rooted /var/lib/pkgtools/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/lib/pkgtools/packages)
    elif [ -d "$(rooted /var/log/packages)" ] && [ ! -L "$(rooted /var/log/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/log/packages)
    else
        error 'installed package database is unavailable'; return 2
    fi

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    validate_reviewed_boundary \
        && record_pass 'the accepted closed update, exact reviewed code, and rollback inventory scope are bound' \
        || record_failure 'the accepted closure, reviewed code, or rollback inventory scope is missing, changed, or mismatched'

    capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and rollback-sensitive state were captured before inventory' \
        || record_failure 'the package database or rollback-sensitive state could not be captured before inventory'

    validate_live_identity \
        && record_pass 'the explicit host identity proves the reviewed 6.18.42 generic boot on the accepted root filesystem' \
        || record_failure 'the host identity, running kernel, root filesystem, or generic boot image changed after closure'

    validate_package_state "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/package-names.before.txt" \
        && validate_package_records \
        && record_pass 'the exact closed 2040-record package state remains installed without a 6.18.40 package record' \
        || record_failure 'the installed package database differs from the accepted closed update state'

    validate_active_artifacts \
        && record_pass 'the active 6.18.42 kernel, initrd, modules, and generic links retain their accepted identities' \
        || record_failure 'the accepted active kernel, initrd, modules, or generic links changed after closure'

    module_result=
    if module_result=$(classify_rollback_modules); then
        ROLLBACK_MODULE_STATE=${module_result% *}
        INSTALLED_MODULE_COUNT=${module_result##* }
        if [ "$ROLLBACK_MODULE_STATE" = preserved-populated-module-tree ]; then
            record_pass 'the 6.18.40 rollback has a populated module tree with required depmod metadata'
        else
            record_pass 'the 6.18.40 path is an empty directory placeholder; the exact source package must restore all modules'
        fi
    else
        ROLLBACK_MODULE_STATE=invalid
        INSTALLED_MODULE_COUNT=0
        record_failure 'the 6.18.40 module path is missing, unsafe, or partially populated without a complete module boundary'
    fi

    validate_geninitrd_boundary \
        && record_pass 'the exact accepted GenInitrd policy, generator, implementation, and setup control remain available' \
        || record_failure 'the GenInitrd reconstruction controls differ from the accepted closure boundary'

    validate_active_grub \
        && record_pass 'the unchanged syntax-valid GRUB configuration still defaults to the 6.18.42 generic kernel and initrd pair' \
        || record_failure 'the active GRUB configuration, environment, or effective default changed after closure'

    source_result=0
    resolve_source_package "$SOURCE_ROOT" || source_result=$?
    if [ "$source_result" -eq 0 ]; then
        source_payload_valid=false
        if inspect_source_package "$SOURCE_PACKAGE" "$OUTPUT_DIR/source-package.json" "$OUTPUT_DIR/source-package-modules.txt"; then
            if [ "$ROLLBACK_MODULE_STATE" = preserved-populated-module-tree ]; then
                capture_installed_module_manifest "$OUTPUT_DIR/installed-rollback-modules.txt" \
                    && cmp -s "$OUTPUT_DIR/source-package-modules.txt" "$OUTPUT_DIR/installed-rollback-modules.txt" \
                    && source_payload_valid=true
            else
                : > "$OUTPUT_DIR/installed-rollback-modules.txt"
                [ -s "$OUTPUT_DIR/source-package-modules.txt" ] && source_payload_valid=true
            fi
        fi
        if [ "$source_payload_valid" = true ] && load_source_summary "$OUTPUT_DIR/source-package.json"; then
            SOURCE_STATE=exact-local-package
            record_pass 'one exact safe local 6.18.40 package supplies the missing kernel image and complete module payload'
        else
            SOURCE_STATE=invalid-or-module-mismatched-package
            record_failure 'the local 6.18.40 package is corrupt, unsafe, incomplete, or incompatible with the observed module state'
        fi
    elif [ "$source_result" -eq 3 ]; then
        SOURCE_STATE=not-found-in-reviewed-root
        : > "$OUTPUT_DIR/source-package.json"
        : > "$OUTPUT_DIR/source-package-modules.txt"
        : > "$OUTPUT_DIR/installed-rollback-modules.txt"
        record_pass 'no exact 6.18.40 package was found in the reviewed local source root; external source review is required'
    else
        SOURCE_STATE=ambiguous-or-unsafe-local-source
        record_failure 'the reviewed source root is missing, unsafe, or contains ambiguous 6.18.40 package candidates'
    fi

    measure_boot_space \
        && record_pass "the boot filesystem inventory completed with space classified as $SPACE_STATE" \
        || record_failure 'the available boot filesystem space or conservative reconstruction requirement could not be measured'

    capture_package_database "$OUTPUT_DIR/packages.after.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and rollback-sensitive state were captured after inventory' \
        || record_failure 'the final package database or rollback-sensitive state could not be captured'

    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/package-names.before.txt" "$OUTPUT_DIR/package-names.after.txt" \
        && record_pass 'the installed package database remained unchanged during rollback inventory' \
        || record_failure 'the installed package database changed during rollback inventory'

    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the kernel, initrd, module, GenInitrd, and GRUB state remained unchanged during inventory' \
        || record_failure 'rollback-sensitive system state changed during inventory'

    validate_source_boundary_unchanged \
        && record_pass 'the exact local source boundary remained unchanged throughout inventory' \
        || record_failure 'the local rollback source boundary changed or remained unsafe during inventory'

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        if [ "$SOURCE_STATE" = exact-local-package ] && [ "$SPACE_STATE" = sufficient ]; then
            RECONSTRUCTION_VIABLE=true
            NEXT_STAGE=current-rollback-reconstruction-preflight
            record_pass 'the rollback is viable for an exact non-executing reconstruction preflight; apply remains unauthorized'
        elif [ "$SOURCE_STATE" = not-found-in-reviewed-root ]; then
            RECONSTRUCTION_VIABLE=false
            NEXT_STAGE=current-rollback-source-acquisition-review
            record_pass 'the inventory is accepted but reconstruction waits for an exact externally verified 6.18.40 source package'
        else
            RECONSTRUCTION_VIABLE=false
            NEXT_STAGE=current-rollback-space-remediation-review
            record_pass 'the inventory is accepted but reconstruction waits for additional boot filesystem space'
        fi
    else
        RECONSTRUCTION_VIABLE=false
        NEXT_STAGE=current-rollback-reconstruction-manual-review
        record_failure 'the rollback reconstruction cannot advance because one or more inventory invariants failed'
    fi

    finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
