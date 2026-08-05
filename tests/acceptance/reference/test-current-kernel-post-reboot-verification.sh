#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${POST_REBOOT_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-kernel-post-reboot-verification}
REBOOT_RECORD=${POST_REBOOT_REBOOT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-apply-reboot-review-20260805-accepted.json}
REVIEW_POLICY=${POST_REBOOT_REVIEW_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-apply-reboot-review-policy.json}
REVIEW_SCRIPT=${POST_REBOOT_REVIEW_SCRIPT:-$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-apply-reboot-review.sh}
RECOVERY_POLICY=${POST_REBOOT_RECOVERY_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-policy.json}
VERIFICATION_POLICY=${POST_REBOOT_VERIFICATION_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-reboot-verification-policy.json}
VERIFICATION_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-reboot-verification.sh

TARGET=
OUTPUT_DIR=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256=
CONFIRM_TARGET_KERNEL=
CONFIRM_VERIFICATION_SHA256=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
PACKAGE_DATABASE=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL=
ARCHITECTURE=
ROOT_UUID=
ROOT_SOURCE=
ROOT_PREFIX=
CMDLINE_FILE=
BOOT_ID_FILE=
OSRELEASE_FILE=
BOOT_ID=
BOOT_IMAGE=
ROLLBACK_STATE=unknown
BOOT_SELECTION=unverified
PAUSE_SAFE=false
REBOOT_VERIFIED=false
UPDATE_CLOSED=false
NEXT_STAGE=manual-recovery-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-reboot-review-evidence-sha256 SHA256 \\
                     --confirm-target-kernel VERSION \\
                     --confirm-verification-sha256 SHA256 [options]

Verify the first real boot after the accepted Slackware-current reboot review.
This command does not refresh repository metadata, install or remove packages,
generate an initrd, modify GRUB, or reboot the machine. It binds the immutable
reboot authorization, proves that 6.18.42 is the active kernel loaded through
the reviewed generic boot path, and confirms that the exact package and boot
state remains unchanged.

A successful result closes the reviewed update and leaves rollback
reconstruction as a separate optional stage.

Required options:
      --target slackware-current
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-reboot-review-evidence-sha256 SHA256
      --confirm-target-kernel VERSION
      --confirm-verification-sha256 SHA256

Optional arguments:
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
            --confirm-reboot-review-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --confirm-verification-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_VERIFICATION_SHA256=${2,,}; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || return 1
    is_sha256 "$CONFIRM_VERIFICATION_SHA256" || return 1
    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac
    fi
}

rooted() {
    printf '%s%s\n' "$ROOT_PREFIX" "$1"
}

require_regular_file() {
    [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]
}

file_sha256() {
    sha256sum -- "$1" | awk '{print $1}'
}

file_size() {
    stat -Lc '%s' -- "$1"
}

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
    python3 - "$REBOOT_RECORD" "$REVIEW_POLICY" "$REVIEW_SCRIPT" "$RECOVERY_POLICY" \
        "$VERIFICATION_POLICY" "$VERIFICATION_SCRIPT" "$CONFIRM_HOSTNAME" \
        "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256" \
        "$CONFIRM_TARGET_KERNEL" "$CONFIRM_VERIFICATION_SHA256" <<'PY'
import hashlib
import json
import pathlib
import sys

(record_path, review_policy_path, review_script_path, recovery_policy_path,
 verification_policy_path, verification_script_path, hostname_short,
 hostname_fqdn, review_archive_sha, target_kernel, verification_sha) = sys.argv[1:]


def load_regular(path):
    p = pathlib.Path(path)
    if not p.is_file() or p.is_symlink():
        raise SystemExit(1)
    return json.loads(p.read_text(encoding='utf-8'))


def digest(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

record = load_regular(record_path)
review_policy = load_regular(review_policy_path)
recovery_policy = load_regular(recovery_policy_path)
verification_policy = load_regular(verification_policy_path)
record_sha = digest(record_path)
review_policy_sha = digest(review_policy_path)
review_script_sha = digest(review_script_path)
recovery_policy_sha = digest(recovery_policy_path)
verification_script_sha = digest(verification_script_path)
root_uuid = verification_policy.get('required_root_uuid', '')
scope = (
    'operation=current-kernel-post-reboot-verification\n'
    'target=slackware-current\n'
    f'hostname_short={hostname_short}\n'
    f'hostname_fqdn={hostname_fqdn}\n'
    f'target_kernel={target_kernel}\n'
    f'root_uuid={root_uuid}\n'
    f'reboot_review_archive_sha256={review_archive_sha}\n'
    f'reboot_review_record_sha256={record_sha}\n'
    f'reboot_review_policy_sha256={review_policy_sha}\n'
    f'reboot_review_script_sha256={review_script_sha}\n'
    f'recovery_policy_sha256={recovery_policy_sha}\n'
    f'post_reboot_verification_script_sha256={verification_script_sha}\n'
).encode()
calculated_scope = hashlib.sha256(scope).hexdigest()

checks = [
    record.get('scenario') == 'current-kernel-post-apply-reboot-review',
    record.get('target') == 'slackware-current',
    record.get('accepted') is True,
    record.get('archive_sha256') == review_archive_sha,
    record.get('hostname_short') == hostname_short,
    record.get('hostname_fqdn') == hostname_fqdn,
    record.get('running_kernel') == '6.18.40',
    record.get('target_kernel') == target_kernel,
    record.get('package_transaction_completed') is True,
    record.get('package_database_unchanged') is True,
    record.get('boot_sensitive_state_unchanged') is True,
    record.get('target_artifacts_verified') is True,
    record.get('geninitrd_controls_verified') is True,
    record.get('current_boot_image') == '/boot/vmlinuz-generic',
    record.get('required_kernel') == '/boot/vmlinuz-generic',
    record.get('required_initrd') == '/boot/initrd-generic.img',
    record.get('next_entry_present') is False,
    record.get('pause_safe') is True,
    record.get('reboot_ready') is True,
    record.get('reboot_authorized') is True,
    record.get('reboot_executed') is False,
    record.get('next_stage') == 'manual-reboot-to-reviewed-target',
    record.get('review_policy_sha256') == review_policy_sha,
    record.get('review_script_sha256') == review_script_sha,
    review_policy.get('scenario') == 'current-kernel-post-apply-reboot-review',
    review_policy.get('target') == 'slackware-current',
    review_policy.get('reviewed') is True,
    review_policy.get('target_kernel') == target_kernel,
    review_policy.get('post_reboot_stage') == 'current-kernel-post-reboot-verification',
    review_policy.get('reboot_execution_allowed') is False,
    recovery_policy.get('scenario') == 'current-post-package-boot-recovery-verification',
    recovery_policy.get('target') == 'slackware-current',
    recovery_policy.get('reviewed') is True,
    recovery_policy.get('target_kernel') == target_kernel,
    verification_policy.get('scenario') == 'current-kernel-post-reboot-verification',
    verification_policy.get('target') == 'slackware-current',
    verification_policy.get('reviewed') is True,
    verification_policy.get('required_hostname_short') == hostname_short,
    verification_policy.get('required_hostname_fqdn') == hostname_fqdn,
    verification_policy.get('previous_running_kernel') == '6.18.40',
    verification_policy.get('target_kernel') == target_kernel,
    verification_policy.get('accepted_reboot_review_archive_sha256') == review_archive_sha,
    verification_policy.get('accepted_reboot_review_record_sha256') == record_sha,
    verification_policy.get('reboot_review_policy_sha256') == review_policy_sha,
    verification_policy.get('reboot_review_script_sha256') == review_script_sha,
    verification_policy.get('recovery_policy_sha256') == recovery_policy_sha,
    verification_policy.get('post_reboot_verification_script_sha256') == verification_script_sha,
    verification_policy.get('verification_scope_sha256') == verification_sha == calculated_scope,
    verification_policy.get('required_boot_image') == '/boot/vmlinuz-generic',
    verification_policy.get('required_root_uuid') == root_uuid and bool(root_uuid),
    verification_policy.get('expected_architecture') == 'x86_64',
    verification_policy.get('repository_refresh_allowed') is False,
    verification_policy.get('package_mutation_allowed') is False,
    verification_policy.get('initrd_mutation_allowed') is False,
    verification_policy.get('grub_mutation_allowed') is False,
    verification_policy.get('reboot_execution_allowed') is False,
    verification_policy.get('expected_pause_safe') is True,
    verification_policy.get('expected_reboot_verified') is True,
    verification_policy.get('expected_update_closed') is True,
    verification_policy.get('next_stage') == 'optional-rollback-reconstruction-review',
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
        /proc/sys/kernel/random/boot_id \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" \
        /boot/vmlinuz-6.18.40 \
        /boot/initrd-generic.img \
        "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" \
        /boot/initrd-6.18.40.img \
        /boot/grub/grub.cfg \
        /boot/grub/grubenv \
        /etc/default/geninitrd \
        "/lib/modules/$CONFIRM_TARGET_KERNEL" \
        /lib/modules/6.18.40; do
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
policy_path, package_database = sys.argv[1:]
d = json.load(open(policy_path, encoding='utf-8'))
root = pathlib.Path(package_database)
for record in d['required_package_records']:
    path = root / record['name']
    if not path.is_file() or path.is_symlink():
        raise SystemExit(1)
    if hashlib.sha256(path.read_bytes()).hexdigest() != record['record_sha256']:
        raise SystemExit(1)
for name in d['forbidden_package_records']:
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

validate_target_artifacts() {
    local kernel initrd modules generic_link initrd_link
    kernel=$(rooted "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL")
    initrd=$(rooted "/boot/initrd-$CONFIRM_TARGET_KERNEL.img")
    modules=$(rooted "/lib/modules/$CONFIRM_TARGET_KERNEL")
    generic_link=$(rooted /boot/vmlinuz-generic)
    initrd_link=$(rooted /boot/initrd-generic.img)

    validate_exact_regular "$kernel" "$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_sha256)" "$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_size)" || return 1
    validate_exact_regular "$initrd" "$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_sha256)" "$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_size)" || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    find "$modules" -mindepth 1 -print -quit | grep -q . || return 1
    [ -L "$generic_link" ] && [ "$(readlink -- "$generic_link")" = "vmlinuz-$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -L "$initrd_link" ] && [ "$(readlink -- "$initrd_link")" = "initrd-$CONFIRM_TARGET_KERNEL.img" ]
}

validate_geninitrd_boundary() {
    local policy_path geninitrd generator setup
    policy_path=$(rooted /etc/default/geninitrd)
    geninitrd=$(rooted /usr/sbin/geninitrd)
    generator=$(rooted /usr/share/mkinitrd/mkinitrd_command_generator.sh)
    setup=$(rooted /var/lib/pkgtools/setup/setup.01.mkinitrd)
    validate_exact_regular "$policy_path" "$(policy_value "$RECOVERY_POLICY" geninitrd.policy_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.policy_size)" || return 1
    validate_exact_regular "$geninitrd" "$(policy_value "$RECOVERY_POLICY" geninitrd.geninitrd_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.geninitrd_size)" || return 1
    validate_exact_regular "$generator" "$(policy_value "$RECOVERY_POLICY" geninitrd.generator_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.generator_size)" || return 1
    validate_exact_regular "$setup" "$(policy_value "$RECOVERY_POLICY" geninitrd.setup_sha256)" "$(policy_value "$RECOVERY_POLICY" geninitrd.setup_size)"
}

validate_live_boot_identity() {
    local expected_arch expected_uuid expected_image osrelease
    expected_arch=$(policy_value "$VERIFICATION_POLICY" expected_architecture) || return 1
    expected_uuid=$(policy_value "$VERIFICATION_POLICY" required_root_uuid) || return 1
    expected_image=$(policy_value "$VERIFICATION_POLICY" required_boot_image) || return 1
    osrelease=$(tr -d '\n' < "$OSRELEASE_FILE") || return 1
    BOOT_ID=$(tr -d '\n' < "$BOOT_ID_FILE") || return 1

    [ "$RUNNING_KERNEL" = "$CONFIRM_TARGET_KERNEL" ] || return 1
    [ "$osrelease" = "$CONFIRM_TARGET_KERNEL" ] || return 1
    [ "$ARCHITECTURE" = "$expected_arch" ] || return 1
    [ "$ROOT_UUID" = "$expected_uuid" ] || return 1
    python3 - "$CMDLINE_FILE" "$expected_image" "$expected_uuid" "$BOOT_ID" "$ROOT_SOURCE" "$OUTPUT_DIR/boot-identity.json" <<'PY'
import json, pathlib, re, shlex, sys
cmdline_path, expected_image, expected_uuid, boot_id, root_source, output = sys.argv[1:]
try:
    cmdline = pathlib.Path(cmdline_path).read_text(encoding='utf-8', errors='strict').strip()
    tokens = shlex.split(cmdline)
except Exception:
    raise SystemExit(1)
boot_images = [t.split('=', 1)[1] for t in tokens if t.startswith('BOOT_IMAGE=')]
roots = [t.split('=', 1)[1] for t in tokens if t.startswith('root=')]
valid_boot_id = re.fullmatch(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', boot_id)
checks = [
    boot_images == [expected_image],
    roots == [f'UUID={expected_uuid}'],
    tokens.count('ro') == 1,
    'rw' not in tokens,
    valid_boot_id is not None,
    boot_id.lower() != '00000000-0000-0000-0000-000000000000',
    bool(root_source),
]
if not all(checks):
    raise SystemExit(1)
pathlib.Path(output).write_text(json.dumps({
    'boot_id': boot_id,
    'boot_image': boot_images[0],
    'cmdline': cmdline,
    'root_argument': roots[0],
    'root_source': root_source,
    'root_uuid': expected_uuid,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
    [ "$?" -eq 0 ] || return 1
    BOOT_IMAGE=$expected_image
}

capture_grubenv() {
    local output=$1 grubenv
    grubenv=$(rooted /boot/grub/grubenv)
    : > "$output"
    if [ -e "$grubenv" ] || [ -L "$grubenv" ]; then
        [ -f "$grubenv" ] && [ ! -L "$grubenv" ] || return 1
        grub-editenv "$grubenv" list > "$output"
    fi
}

validate_effective_grub_selection() {
    local grub=$1 grubenv_list=$2 kernel=$3 initrd=$4 selection_output=$5
    python3 - "$grub" "$grubenv_list" "$kernel" "$initrd" "$selection_output" <<'PY'
import json, pathlib, re, sys
(grub_path, env_path, required_kernel, required_initrd, selection_path) = sys.argv[1:]
try:
    lines = pathlib.Path(grub_path).read_text(encoding='utf-8', errors='strict').splitlines()
    env_lines = pathlib.Path(env_path).read_text(encoding='utf-8', errors='strict').splitlines()
except Exception:
    raise SystemExit(1)
env = {}
for line in env_lines:
    if '=' in line:
        key, value = line.split('=', 1)
        env[key.strip()] = value.strip()
if env.get('next_entry'):
    raise SystemExit(1)

def quoted_value(text):
    match = re.match(r"^(['\"])(.*?)\1", text.lstrip())
    return match.group(2) if match else ''

def entry_identity(text):
    explicit = re.search(r"--id(?:=|\s+)(?:(['\"])(.*?)\1|([^\s{]+))", text)
    if explicit:
        return explicit.group(2) or explicit.group(3).strip("'\"")
    generated = re.search(r"\$menuentry_id_option\s+(['\"])(.*?)\1", text)
    return generated.group(2) if generated else ''

root_entries = []
stack = []
active_default_assignments = []
condition_stack = []
function_depth = 0


def simple_condition_value(text):
    match = re.fullmatch(
        r"if\s+\[\s*(?:(-n|-z)\s+)?['\"]?\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?['\"]?\s*\]\s*;\s*then",
        text,
    )
    if not match:
        return None
    operator, variable = match.groups()
    if variable not in ('next_entry', 'saved_entry'):
        return None
    value = bool(env.get(variable, ''))
    if operator == '-z':
        value = not value
    return value


def branch_state():
    unknown = False
    for frame in condition_stack:
        value = frame['value']
        if value is not None and frame['else_branch']:
            value = not value
        if value is False:
            return False
        if value is None:
            unknown = True
    return None if unknown else True


for original in lines:
    stripped = original.strip()
    if not stripped or stripped.startswith('#'):
        continue
    if function_depth:
        if stripped == '}':
            function_depth -= 1
        elif re.match(r'^function\s+[^\s{]+\s*\{\s*$', stripped):
            function_depth += 1
        continue
    if not stack and re.match(r'^function\s+[^\s{]+\s*\{\s*$', stripped):
        function_depth = 1
        continue
    if not stack:
        if re.match(r'^if\b.*\bthen\s*$', stripped):
            condition_stack.append({'value': simple_condition_value(stripped), 'else_branch': False})
            continue
        if stripped == 'else':
            if not condition_stack or condition_stack[-1]['else_branch']:
                raise SystemExit(1)
            condition_stack[-1]['else_branch'] = True
            continue
        if stripped == 'fi':
            if not condition_stack:
                raise SystemExit(1)
            condition_stack.pop()
            continue
        assignment = re.match(r'^set\s+default=(.*?)\s*$', stripped)
        if assignment:
            state = branch_state()
            if state is None:
                raise SystemExit(1)
            if state:
                active_default_assignments.append(assignment.group(1))
            continue
    opener = re.match(r'^(menuentry|submenu)\s+(.*)$', stripped)
    if opener:
        kind, remainder = opener.groups()
        node = {'kind': kind, 'title': quoted_value(remainder), 'id': entry_identity(remainder), 'lines': [], 'children': []}
        if stack:
            stack[-1]['children'].append(node)
        else:
            root_entries.append(node)
        stack.append(node)
        continue
    if stripped == '}' and stack:
        stack.pop()
        continue
    if stack:
        stack[-1]['lines'].append(stripped)
if stack or condition_stack or not root_entries or len(active_default_assignments) != 1:
    raise SystemExit(1)
selector_expression = active_default_assignments[0].strip()
if selector_expression in ('${saved_entry}', '"${saved_entry}"', "'${saved_entry}'", '$saved_entry', '"$saved_entry"', "'$saved_entry'"):
    selector = env.get('saved_entry', '')
else:
    match = re.fullmatch(r"(['\"])(.*?)\1", selector_expression)
    if match:
        selector = match.group(2)
    elif re.fullmatch(r'[A-Za-z0-9_.+:-]+(?:>[A-Za-z0-9_.+:-]+)*', selector_expression):
        selector = selector_expression
    else:
        raise SystemExit(1)
selector = selector.strip() or '0'

def resolve_segment(entries, segment):
    if segment.isdigit():
        index = int(segment)
        return entries[index] if 0 <= index < len(entries) else None
    matches = [entry for entry in entries if segment in (entry['id'], entry['title'])]
    return matches[0] if len(matches) == 1 else None

segments = selector.split('>')
entries = root_entries
selected = None
for position, segment in enumerate(segments):
    if not segment:
        raise SystemExit(1)
    selected = resolve_segment(entries, segment)
    if selected is None:
        raise SystemExit(1)
    if position < len(segments) - 1:
        if selected['kind'] != 'submenu':
            raise SystemExit(1)
        entries = selected['children']
if selected is None or selected['kind'] != 'menuentry':
    raise SystemExit(1)
linux_lines = [line for line in selected['lines'] if re.match(r'^linux(?:efi)?\s+', line)]
initrd_lines = [line for line in selected['lines'] if re.match(r'^initrd(?:efi)?\s+', line)]
linux_ok = len(linux_lines) == 1 and required_kernel in linux_lines[0].split()
initrd_ok = len(initrd_lines) == 1 and required_initrd in initrd_lines[0].split()
if not linux_ok or not initrd_ok:
    raise SystemExit(1)
pathlib.Path(selection_path).write_text(json.dumps({
    'next_entry_present': False,
    'required_initrd': required_initrd,
    'required_kernel': required_kernel,
    'selected_entry_id': selected['id'],
    'selected_entry_title': selected['title'],
    'selector': selector,
    'selector_expression': selector_expression,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

validate_active_grub() {
    local grub grubenv_list
    grub=$(rooted /boot/grub/grub.cfg)
    grubenv_list=$OUTPUT_DIR/grubenv.list
    validate_exact_regular "$grub" "$(policy_value "$RECOVERY_POLICY" active_grub.sha256)" "$(policy_value "$RECOVERY_POLICY" active_grub.size)" || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    capture_grubenv "$grubenv_list" || return 1
    cp -- "$grub" "$OUTPUT_DIR/grub.cfg.verified" || return 1
    validate_effective_grub_selection "$grub" "$grubenv_list" \
        "$(policy_value "$VERIFICATION_POLICY" required_boot_image)" \
        "$(policy_value "$VERIFICATION_POLICY" required_initrd)" \
        "$OUTPUT_DIR/grub-selection.json" || return 1
    BOOT_SELECTION=effective-default-generic-kernel-initrd-pair
}

validate_active_modules() {
    local modules
    modules=$(rooted "/lib/modules/$RUNNING_KERNEL")
    [ "$RUNNING_KERNEL" = "$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    find "$modules" -mindepth 1 -print -quit | grep -q .
}

validate_degraded_rollback() {
    [ ! -e "$(rooted /boot/vmlinuz-6.18.40)" ] && [ ! -L "$(rooted /boot/vmlinuz-6.18.40)" ] || return 1
    [ ! -e "$(rooted /boot/initrd-6.18.40.img)" ] && [ ! -L "$(rooted /boot/initrd-6.18.40.img)" ] || return 1
    [ -d "$(rooted /lib/modules/6.18.40)" ] && [ ! -L "$(rooted /lib/modules/6.18.40)" ] || return 1
    [ "$RUNNING_KERNEL" != 6.18.40 ] || return 1
    ROLLBACK_STATE=degraded-modules-only
}

write_analysis() {
    python3 - "$OUTPUT_DIR/post-reboot-analysis.json" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" \
        "$RUNNING_KERNEL" "$CONFIRM_TARGET_KERNEL" "$ARCHITECTURE" "$ROOT_UUID" "$ROOT_SOURCE" \
        "$BOOT_ID" "$BOOT_IMAGE" "$PASS_COUNT" "$FAILURE_COUNT" "$ROLLBACK_STATE" \
        "$BOOT_SELECTION" "$PAUSE_SAFE" "$REBOOT_VERIFIED" "$UPDATE_CLOSED" "$NEXT_STAGE" <<'PY'
import json, pathlib, sys
(output, hostname_short, hostname_fqdn, running, target, architecture, root_uuid,
 root_source, boot_id, boot_image, passes, failures, rollback, boot_selection,
 pause_safe, reboot_verified, update_closed, next_stage) = sys.argv[1:]
data = {
    'scenario': 'current-kernel-post-reboot-verification',
    'target': 'slackware-current',
    'hostname_short': hostname_short,
    'hostname_fqdn': hostname_fqdn,
    'running_kernel': running,
    'target_kernel': target,
    'architecture': architecture,
    'root_uuid': root_uuid,
    'root_source': root_source,
    'boot_id': boot_id,
    'boot_image': boot_image,
    'package_transaction_completed': True,
    'repository_metadata_refreshed': False,
    'host_mutated': False,
    'rollback_state': rollback,
    'boot_selection': boot_selection,
    'pause_safe': pause_safe == 'true',
    'reboot_verified': reboot_verified == 'true',
    'update_closed': update_closed == 'true',
    'next_stage': next_stage,
    'assertions': {'passes': int(passes), 'failures': int(failures)},
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-kernel-post-reboot-verification
target=$TARGET
hostname_short=$HOSTNAME_SHORT
hostname_fqdn=$HOSTNAME_FQDN
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
target_kernel=$CONFIRM_TARGET_KERNEL
architecture=$ARCHITECTURE
root_uuid=$ROOT_UUID
root_source=$ROOT_SOURCE
boot_id=$BOOT_ID
boot_image=$BOOT_IMAGE
reboot_review_evidence_sha256=$CONFIRM_REBOOT_REVIEW_EVIDENCE_SHA256
verification_scope_sha256=$CONFIRM_VERIFICATION_SHA256
package_transaction_completed=true
repository_metadata_refreshed=false
host_mutated=false
rollback_state=$ROLLBACK_STATE
boot_selection=$BOOT_SELECTION
pause_safe=$PAUSE_SAFE
reboot_verified=$REBOOT_VERIFIED
update_closed=$UPDATE_CLOSED
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
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-current-kernel-post-reboot-verification-${timestamp}.tar.gz"
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
    printf 'Slackware-current post-reboot result: running=%s, target=%s, boot-image=%s, boot-selection=%s, rollback=%s, pause-safe=%s, reboot-verified=%s, update-closed=%s, next-stage=%s\n' \
        "$RUNNING_KERNEL" "$CONFIRM_TARGET_KERNEL" "$BOOT_IMAGE" "$BOOT_SELECTION" "$ROLLBACK_STATE" "$PAUSE_SAFE" "$REBOOT_VERIFIED" "$UPDATE_CLOSED" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

main() {
    local timestamp slackware_version
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this post-reboot verification must run as root'; return 2; }

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
    BOOT_ID_FILE=$(rooted /proc/sys/kernel/random/boot_id)
    OSRELEASE_FILE=$(rooted /proc/sys/kernel/osrelease)

    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk chmod cmp cp date find findmnt grep grub-editenv grub-script-check hostname install python3 readlink sha256sum sort stat tar tr uname; do
        if [ "$TEST_MODE" = 1 ] && [ "$command_name" = findmnt ]; then
            continue
        fi
        command -v "$command_name" >/dev/null 2>&1 || { error "required command missing: $command_name"; return 2; }
    done
    for reviewed_file in "$REBOOT_RECORD" "$REVIEW_POLICY" "$REVIEW_SCRIPT" "$RECOVERY_POLICY" "$VERIFICATION_POLICY" "$VERIFICATION_SCRIPT"; do
        require_regular_file "$reviewed_file" || { error "reviewed file is missing or unsafe: $reviewed_file"; return 2; }
    done
    bash -n "$REVIEW_SCRIPT" || { error 'reboot review script has invalid shell syntax'; return 2; }
    bash -n "$VERIFICATION_SCRIPT" || { error 'post-reboot verification script has invalid shell syntax'; return 2; }
    for live_file in "$CMDLINE_FILE" "$BOOT_ID_FILE" "$OSRELEASE_FILE"; do
        require_regular_file "$live_file" || { error "live boot identity file is missing or unsafe: $live_file"; return 2; }
    done

    if [ -d "$(rooted /var/lib/pkgtools/packages)" ] && [ ! -L "$(rooted /var/lib/pkgtools/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/lib/pkgtools/packages)
    elif [ -d "$(rooted /var/log/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/log/packages)
    else
        error 'installed package database is unavailable'
        return 2
    fi

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    validate_reviewed_boundary \
        && record_pass 'the accepted reboot authorization, exact reviewed code, and post-reboot verification scope are bound' \
        || record_failure 'the accepted reboot boundary, reviewed code, or verification scope is missing, changed, or mismatched'

    [ "$HOSTNAME_SHORT" = "$CONFIRM_HOSTNAME" ] \
        && [ "$HOSTNAME_FQDN" = "$CONFIRM_HOSTNAME_FQDN" ] \
        && [ "$CONFIRM_TARGET_KERNEL" = "$(policy_value "$VERIFICATION_POLICY" target_kernel)" ] \
        && record_pass 'the explicit host identity and target kernel match the reviewed post-reboot boundary' \
        || record_failure 'the host identity or target kernel does not match the reviewed post-reboot boundary'

    capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and reboot-sensitive state were captured before verification' \
        || record_failure 'the package database or reboot-sensitive state could not be captured before verification'

    validate_live_boot_identity \
        && record_pass 'the live x86_64 kernel, osrelease, boot ID, root UUID, and generic BOOT_IMAGE prove the reviewed 6.18.42 boot' \
        || record_failure 'the live kernel identity, boot ID, root filesystem, or reviewed command line does not prove a 6.18.42 boot'

    validate_package_state "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/package-names.before.txt" \
        && validate_package_records \
        && record_pass 'the exact reviewed 2040-record package transaction remains installed after reboot' \
        || record_failure 'the installed package database or exact reviewed package records changed before post-reboot verification'

    validate_target_artifacts \
        && record_pass 'the exact 6.18.42 kernel, initrd, modules, and generic links remain installed' \
        || record_failure 'the reviewed 6.18.42 kernel, initrd, modules, or generic links are missing or changed'

    validate_active_modules \
        && record_pass 'the active kernel release resolves to the populated 6.18.42 module tree' \
        || record_failure 'the active kernel does not resolve to the reviewed 6.18.42 module tree'

    validate_geninitrd_boundary \
        && record_pass 'the restored GenInitrd policy and control files retain their accepted identities after reboot' \
        || record_failure 'the GenInitrd policy or installed control files changed after reboot'

    validate_active_grub \
        && record_pass 'the unchanged syntax-valid GRUB configuration still selects the reviewed generic kernel and initrd pair without next_entry' \
        || record_failure 'the active GRUB configuration, environment, or effective generic boot selection changed after reboot'

    validate_degraded_rollback \
        && record_pass 'the former 6.18.40 rollback is now correctly classified as modules-only' \
        || record_failure 'the former 6.18.40 rollback state differs from the reviewed modules-only boundary'

    capture_package_database "$OUTPUT_DIR/packages.after.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and reboot-sensitive state were captured after verification' \
        || record_failure 'the package database or reboot-sensitive state could not be captured after verification'

    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/package-names.before.txt" "$OUTPUT_DIR/package-names.after.txt" \
        && record_pass 'the installed package database remained unchanged during post-reboot verification' \
        || record_failure 'the installed package database changed during post-reboot verification'

    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the live identity, kernel, initrd, module, GenInitrd, GRUB, and rollback state remained unchanged during verification' \
        || record_failure 'reboot-sensitive state changed during post-reboot verification'

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        PAUSE_SAFE=true
        REBOOT_VERIFIED=true
        UPDATE_CLOSED=true
        NEXT_STAGE=optional-rollback-reconstruction-review
        record_pass 'the 6.18.42 reboot is verified and the reviewed Slackware-current update is closed without further mandatory work'
    else
        PAUSE_SAFE=false
        REBOOT_VERIFIED=false
        UPDATE_CLOSED=false
        NEXT_STAGE=manual-recovery-review
        record_failure 'the update cannot close because one or more post-reboot invariants failed'
    fi

    finish
}

main "$@"
