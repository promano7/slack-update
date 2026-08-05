#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${REBOOT_REVIEW_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-kernel-post-apply-reboot-review}
CHECKPOINT_RECORD=${REBOOT_REVIEW_CHECKPOINT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-20260805-accepted.json}
RECOVERY_POLICY=${REBOOT_REVIEW_RECOVERY_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-policy.json}
RECOVERY_SCRIPT=${REBOOT_REVIEW_RECOVERY_SCRIPT:-$REPOSITORY_ROOT/tests/acceptance/reference/test-current-post-package-boot-recovery-verification.sh}
REVIEW_POLICY=${REBOOT_REVIEW_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-apply-reboot-review-policy.json}
REVIEW_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-apply-reboot-review.sh

TARGET=
OUTPUT_DIR=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_RUNNING_KERNEL=
CONFIRM_SAFE_PAUSE_EVIDENCE_SHA256=
CONFIRM_TARGET_KERNEL=
CONFIRM_AUTHORIZATION_SHA256=
AUTHORIZE_REBOOT_REVIEW=0
ACKNOWLEDGE_DEGRADED_ROLLBACK=0
PASS_COUNT=0
FAILURE_COUNT=0
CHECKPOINT_FAILURE_COUNT=0
REBOOT_FAILURE_COUNT=0
ASSERTION_LOG=
PACKAGE_DATABASE=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL=
ROOT_PREFIX=
CMDLINE_FILE=
PAUSE_SAFE=false
REBOOT_READY=false
REBOOT_AUTHORIZED=false
ROLLBACK_STATE=unknown
BOOT_SELECTION=unverified
NEXT_STAGE=manual-review-required
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current --authorize-reboot-review \\
                     --acknowledge-degraded-rollback \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-running-kernel VERSION \\
                     --confirm-safe-pause-evidence-sha256 SHA256 \\
                     --confirm-target-kernel VERSION \\
                     --confirm-authorization-sha256 SHA256 [options]

Review and authorize the separate manual reboot boundary after the accepted
Slackware-current package transaction. This command does not refresh repository
metadata, install packages, execute maintainer scripts, generate an initrd,
modify GRUB, or reboot the machine.

The review binds the accepted safe-pause checkpoint, proves that the exact
installed package and boot state has not drifted, rejects a one-time GRUB
next_entry override, and requires the effective next boot selection to pair
/boot/vmlinuz-generic with /boot/initrd-generic.img. The user must explicitly
acknowledge that the 6.18.40 rollback is degraded because only its running
session and module tree remain.

Required options:
      --target slackware-current
      --authorize-reboot-review
      --acknowledge-degraded-rollback
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-running-kernel VERSION
      --confirm-safe-pause-evidence-sha256 SHA256
      --confirm-target-kernel VERSION
      --confirm-authorization-sha256 SHA256

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_checkpoint_failure() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    CHECKPOINT_FAILURE_COUNT=$((CHECKPOINT_FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2
}
record_reboot_failure() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    REBOOT_FAILURE_COUNT=$((REBOOT_FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2
}

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
            --authorize-reboot-review) AUTHORIZE_REBOOT_REVIEW=$((AUTHORIZE_REBOOT_REVIEW + 1)); shift ;;
            --acknowledge-degraded-rollback) ACKNOWLEDGE_DEGRADED_ROLLBACK=$((ACKNOWLEDGE_DEGRADED_ROLLBACK + 1)); shift ;;
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-running-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_RUNNING_KERNEL=$2; shift 2 ;;
            --confirm-safe-pause-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_SAFE_PAUSE_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --confirm-authorization-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_AUTHORIZATION_SHA256=${2,,}; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || return 1
    [ "$AUTHORIZE_REBOOT_REVIEW" -eq 1 ] || return 1
    [ "$ACKNOWLEDGE_DEGRADED_ROLLBACK" -eq 1 ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_safe_kernel_version "$CONFIRM_RUNNING_KERNEL" || return 1
    is_sha256 "$CONFIRM_SAFE_PAUSE_EVIDENCE_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || return 1
    is_sha256 "$CONFIRM_AUTHORIZATION_SHA256" || return 1
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

validate_reviewed_authorization() {
    python3 - "$CHECKPOINT_RECORD" "$RECOVERY_POLICY" "$RECOVERY_SCRIPT" "$REVIEW_POLICY" "$REVIEW_SCRIPT" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_RUNNING_KERNEL" \
        "$CONFIRM_SAFE_PAUSE_EVIDENCE_SHA256" "$CONFIRM_TARGET_KERNEL" "$CONFIRM_AUTHORIZATION_SHA256" <<'PY'
import hashlib
import json
import pathlib
import sys

(checkpoint_path, recovery_policy_path, recovery_script_path, review_policy_path,
 review_script_path, hostname_short, hostname_fqdn, running_kernel,
 safe_pause_sha, target_kernel, authorization_sha) = sys.argv[1:]


def load_regular(path):
    p = pathlib.Path(path)
    if not p.is_file() or p.is_symlink():
        raise SystemExit(1)
    return json.loads(p.read_text(encoding='utf-8'))


def digest(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

checkpoint = load_regular(checkpoint_path)
recovery_policy = load_regular(recovery_policy_path)
review_policy = load_regular(review_policy_path)
checkpoint_digest = digest(checkpoint_path)
recovery_policy_digest = digest(recovery_policy_path)
recovery_script_digest = digest(recovery_script_path)
review_script_digest = digest(review_script_path)
scope = (
    'operation=current-kernel-post-apply-reboot-review\n'
    'target=slackware-current\n'
    f'hostname_short={hostname_short}\n'
    f'hostname_fqdn={hostname_fqdn}\n'
    f'running_kernel={running_kernel}\n'
    f'target_kernel={target_kernel}\n'
    f'safe_pause_archive_sha256={safe_pause_sha}\n'
    'rollback_state=degraded-running-session-and-modules-only\n'
    f'checkpoint_record_sha256={checkpoint_digest}\n'
    f'recovery_policy_sha256={recovery_policy_digest}\n'
    f'recovery_verification_script_sha256={recovery_script_digest}\n'
    f'reboot_review_script_sha256={review_script_digest}\n'
).encode()
calculated_scope = hashlib.sha256(scope).hexdigest()

checks = [
    checkpoint.get('scenario') == 'current-post-package-boot-recovery-verification',
    checkpoint.get('target') == 'slackware-current',
    checkpoint.get('accepted') is True,
    checkpoint.get('archive_sha256') == safe_pause_sha,
    checkpoint.get('package_transaction_completed') is True,
    checkpoint.get('target_boot_pair_verified') is True,
    checkpoint.get('active_grub_mutated') is False,
    checkpoint.get('running_kernel') == running_kernel,
    checkpoint.get('target_kernel') == target_kernel,
    checkpoint.get('rollback_state') == 'degraded-running-session-and-modules-only',
    checkpoint.get('pause_safe') is True,
    checkpoint.get('reboot_ready') is True,
    checkpoint.get('reboot_authorized') is False,
    checkpoint.get('next_stage') == 'current-kernel-post-apply-reboot-review',
    checkpoint.get('policy_sha256') == recovery_policy_digest,
    checkpoint.get('verification_script_sha256') == recovery_script_digest,
    recovery_policy.get('scenario') == 'current-post-package-boot-recovery-verification',
    recovery_policy.get('target') == 'slackware-current',
    recovery_policy.get('reviewed') is True,
    recovery_policy.get('required_hostname_short') == hostname_short,
    recovery_policy.get('required_hostname_fqdn') == hostname_fqdn,
    recovery_policy.get('running_kernel') == running_kernel,
    recovery_policy.get('target_kernel') == target_kernel,
    recovery_policy.get('expected_pause_safe') is True,
    recovery_policy.get('reboot_authorized') is False,
    review_policy.get('scenario') == 'current-kernel-post-apply-reboot-review',
    review_policy.get('target') == 'slackware-current',
    review_policy.get('reviewed') is True,
    review_policy.get('authorization_reviewed') is True,
    review_policy.get('required_hostname_short') == hostname_short,
    review_policy.get('required_hostname_fqdn') == hostname_fqdn,
    review_policy.get('required_running_kernel') == running_kernel,
    review_policy.get('target_kernel') == target_kernel,
    review_policy.get('accepted_safe_pause_archive_sha256') == safe_pause_sha,
    review_policy.get('accepted_checkpoint_record_sha256') == checkpoint_digest,
    review_policy.get('recovery_policy_sha256') == recovery_policy_digest,
    review_policy.get('recovery_verification_script_sha256') == recovery_script_digest,
    review_policy.get('reboot_review_script_sha256') == review_script_digest,
    review_policy.get('authorization_scope_sha256') == authorization_sha == calculated_scope,
    review_policy.get('rollback_state') == 'degraded-running-session-and-modules-only',
    review_policy.get('required_current_boot_image') == '/boot/vmlinuz-generic',
    review_policy.get('required_next_kernel') == '/boot/vmlinuz-generic',
    review_policy.get('required_next_initrd') == '/boot/initrd-generic.img',
    review_policy.get('forbid_grub_next_entry') is True,
    review_policy.get('repository_refresh_allowed') is False,
    review_policy.get('package_mutation_allowed') is False,
    review_policy.get('initrd_mutation_allowed') is False,
    review_policy.get('grub_mutation_allowed') is False,
    review_policy.get('reboot_execution_allowed') is False,
    review_policy.get('reboot_authorized_only_after_exact_review') is True,
    review_policy.get('next_stage') == 'manual-reboot-to-reviewed-target',
    review_policy.get('post_reboot_stage') == 'current-kernel-post-reboot-verification',
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
import hashlib
import json
import pathlib
import sys

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
    local kernel initrd modules generic_link named_link
    kernel=$(rooted "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL")
    initrd=$(rooted "/boot/initrd-$CONFIRM_TARGET_KERNEL.img")
    modules=$(rooted "/lib/modules/$CONFIRM_TARGET_KERNEL")
    generic_link=$(rooted /boot/vmlinuz-generic)
    named_link=$(rooted /boot/initrd-generic.img)

    validate_exact_regular "$kernel" "$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_sha256)" "$(policy_value "$RECOVERY_POLICY" target_artifacts.kernel_size)" || return 1
    validate_exact_regular "$initrd" "$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_sha256)" "$(policy_value "$RECOVERY_POLICY" target_artifacts.initrd_size)" || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    find "$modules" -mindepth 1 -print -quit | grep -q . || return 1
    [ -L "$generic_link" ] && [ "$(readlink -- "$generic_link")" = "vmlinuz-$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -L "$named_link" ] && [ "$(readlink -- "$named_link")" = "initrd-$CONFIRM_TARGET_KERNEL.img" ]
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

validate_current_boot_image() {
    python3 - "$CMDLINE_FILE" "$(policy_value "$REVIEW_POLICY" required_current_boot_image)" <<'PY'
import pathlib, shlex, sys
path, required = sys.argv[1:]
try:
    tokens = shlex.split(pathlib.Path(path).read_text(encoding='utf-8', errors='strict').strip())
except Exception:
    raise SystemExit(1)
values = [token.split('=', 1)[1] for token in tokens if token.startswith('BOOT_IMAGE=') and '=' in token]
raise SystemExit(0 if values == [required] else 1)
PY
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
import json
import pathlib
import re
import sys

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
default_assignments = []
function_depth = 0

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
        assignment = re.match(r'^set\s+default=(.*?)\s*$', stripped)
        if assignment:
            default_assignments.append(assignment.group(1))

    opener = re.match(r'^(menuentry|submenu)\s+(.*)$', stripped)
    if opener:
        kind, remainder = opener.groups()
        node = {
            'kind': kind,
            'title': quoted_value(remainder),
            'id': entry_identity(remainder),
            'lines': [],
            'children': [],
        }
        if stack:
            if stack[-1]['kind'] != 'submenu':
                raise SystemExit(1)
            stack[-1]['children'].append(node)
        else:
            root_entries.append(node)
        stack.append(node)
        continue

    if stripped == '}':
        if not stack:
            raise SystemExit(1)
        stack.pop()
        continue

    if stack and stack[-1]['kind'] == 'menuentry':
        stack[-1]['lines'].append(stripped)

if stack or function_depth or not root_entries:
    raise SystemExit(1)

selector_expression = default_assignments[-1] if default_assignments else '0'
selector = selector_expression.strip()
if len(selector) >= 2 and selector[0] == selector[-1] and selector[0] in "'\"":
    selector = selector[1:-1]
selector = selector.replace('${saved_entry}', env.get('saved_entry', ''))
selector = selector.replace('$saved_entry', env.get('saved_entry', ''))
selector = selector.replace('${next_entry}', env.get('next_entry', ''))
selector = selector.replace('$next_entry', env.get('next_entry', ''))
if '$' in selector or '`' in selector or '$(' in selector:
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

selection = {
    'selector': selector,
    'selector_expression': selector_expression,
    'selected_entry_id': selected['id'],
    'selected_entry_title': selected['title'],
    'required_kernel': required_kernel,
    'required_initrd': required_initrd,
    'next_entry_present': False,
}
pathlib.Path(selection_path).write_text(
    json.dumps(selection, indent=2, sort_keys=True) + '\n', encoding='utf-8'
)
PY
}
validate_active_grub() {
    local grub grubenv_list
    grub=$(rooted /boot/grub/grub.cfg)
    grubenv_list=$OUTPUT_DIR/grubenv.list
    validate_exact_regular "$grub" "$(policy_value "$RECOVERY_POLICY" active_grub.sha256)" "$(policy_value "$RECOVERY_POLICY" active_grub.size)" || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    capture_grubenv "$grubenv_list" || return 1
    validate_effective_grub_selection "$grub" "$grubenv_list" \
        "$(policy_value "$REVIEW_POLICY" required_next_kernel)" \
        "$(policy_value "$REVIEW_POLICY" required_next_initrd)" \
        "$OUTPUT_DIR/grub-selection.json" || return 1
    BOOT_SELECTION=effective-default-generic-kernel-initrd-pair
}

validate_degraded_rollback() {
    [ ! -e "$(rooted /boot/vmlinuz-6.18.40)" ] && [ ! -L "$(rooted /boot/vmlinuz-6.18.40)" ] || return 1
    [ ! -e "$(rooted /boot/initrd-6.18.40.img)" ] && [ ! -L "$(rooted /boot/initrd-6.18.40.img)" ] || return 1
    [ -d "$(rooted /lib/modules/6.18.40)" ] && [ ! -L "$(rooted /lib/modules/6.18.40)" ] || return 1
    ROLLBACK_STATE=degraded-running-session-and-modules-only
}

write_analysis() {
    python3 - "$OUTPUT_DIR/reboot-review-analysis.json" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" \
        "$RUNNING_KERNEL" "$CONFIRM_TARGET_KERNEL" "$PASS_COUNT" "$FAILURE_COUNT" \
        "$CHECKPOINT_FAILURE_COUNT" "$REBOOT_FAILURE_COUNT" "$ROLLBACK_STATE" "$BOOT_SELECTION" \
        "$PAUSE_SAFE" "$REBOOT_READY" "$REBOOT_AUTHORIZED" "$NEXT_STAGE" <<'PY'
import json, pathlib, sys
(output, hostname_short, hostname_fqdn, running, target, passes, failures,
 checkpoint_failures, reboot_failures, rollback, boot_selection, pause_safe,
 reboot_ready, reboot_authorized, next_stage) = sys.argv[1:]
data = {
    'scenario': 'current-kernel-post-apply-reboot-review',
    'target': 'slackware-current',
    'hostname_short': hostname_short,
    'hostname_fqdn': hostname_fqdn,
    'running_kernel': running,
    'target_kernel': target,
    'package_transaction_completed': True,
    'repository_metadata_refreshed': False,
    'host_mutated': False,
    'rollback_state': rollback,
    'boot_selection': boot_selection,
    'pause_safe': pause_safe == 'true',
    'reboot_ready': reboot_ready == 'true',
    'reboot_authorized': reboot_authorized == 'true',
    'reboot_executed': False,
    'next_stage': next_stage,
    'assertions': {
        'passes': int(passes),
        'failures': int(failures),
        'checkpoint_failures': int(checkpoint_failures),
        'reboot_failures': int(reboot_failures),
    },
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-kernel-post-apply-reboot-review
target=$TARGET
hostname_short=$HOSTNAME_SHORT
hostname_fqdn=$HOSTNAME_FQDN
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
checkpoint_failures=$CHECKPOINT_FAILURE_COUNT
reboot_failures=$REBOOT_FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
target_kernel=$CONFIRM_TARGET_KERNEL
safe_pause_evidence_sha256=$CONFIRM_SAFE_PAUSE_EVIDENCE_SHA256
authorization_scope_sha256=$CONFIRM_AUTHORIZATION_SHA256
package_transaction_completed=true
repository_metadata_refreshed=false
host_mutated=false
rollback_state=$ROLLBACK_STATE
boot_selection=$BOOT_SELECTION
pause_safe=$PAUSE_SAFE
reboot_ready=$REBOOT_READY
reboot_authorized=$REBOOT_AUTHORIZED
reboot_executed=false
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
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-current-kernel-post-apply-reboot-review-${timestamp}.tar.gz"
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
    printf 'Slackware-current reboot review result: running=%s, target=%s, boot-selection=%s, rollback=%s, pause-safe=%s, reboot-ready=%s, reboot-authorized=%s, reboot-executed=false, next-stage=%s\n' \
        "$RUNNING_KERNEL" "$CONFIRM_TARGET_KERNEL" "$BOOT_SELECTION" "$ROLLBACK_STATE" "$PAUSE_SAFE" "$REBOOT_READY" "$REBOOT_AUTHORIZED" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

main() {
    local timestamp slackware_version package_record
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this reboot review must run as root'; return 2; }

    if [ "$TEST_MODE" = 1 ]; then
        ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
        [ -n "$ROOT_PREFIX" ] || { error 'test root is missing'; return 2; }
        PATH=${SLACK_UPDATE_TEST_PATH:-$PATH}
        HOSTNAME_SHORT=${SLACK_UPDATE_TEST_HOSTNAME_SHORT:-pcold-slack}
        HOSTNAME_FQDN=${SLACK_UPDATE_TEST_HOSTNAME_FQDN:-pcold-slack.pcold-slack.org}
        RUNNING_KERNEL=${SLACK_UPDATE_TEST_RUNNING_KERNEL:-6.18.40}
        CMDLINE_FILE=$(rooted /proc/cmdline)
    else
        ROOT_PREFIX=
        HOSTNAME_SHORT=$(hostname -s) || return 2
        HOSTNAME_FQDN=$(hostname -f) || return 2
        RUNNING_KERNEL=$(uname -r) || return 2
        CMDLINE_FILE=/proc/cmdline
    fi

    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk chmod cmp date find grep grub-editenv grub-script-check hostname install python3 readlink sha256sum sort stat tar uname; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command missing: $command_name"; return 2; }
    done
    for reviewed_file in "$CHECKPOINT_RECORD" "$RECOVERY_POLICY" "$RECOVERY_SCRIPT" "$REVIEW_POLICY" "$REVIEW_SCRIPT"; do
        require_regular_file "$reviewed_file" || { error "reviewed file is missing or unsafe: $reviewed_file"; return 2; }
    done
    bash -n "$RECOVERY_SCRIPT" || { error 'recovery verification script has invalid shell syntax'; return 2; }
    bash -n "$REVIEW_SCRIPT" || { error 'reboot review script has invalid shell syntax'; return 2; }

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

    validate_reviewed_authorization \
        && record_pass 'the accepted safe-pause checkpoint, exact review code, and explicit reboot authorization scope are bound' \
        || record_checkpoint_failure 'the accepted checkpoint, review code, or authorization scope is missing, changed, or mismatched'

    [ "$HOSTNAME_SHORT" = "$CONFIRM_HOSTNAME" ] \
        && [ "$HOSTNAME_FQDN" = "$CONFIRM_HOSTNAME_FQDN" ] \
        && [ "$RUNNING_KERNEL" = "$CONFIRM_RUNNING_KERNEL" ] \
        && [ "$CONFIRM_RUNNING_KERNEL" = "$(policy_value "$REVIEW_POLICY" required_running_kernel 2>/dev/null)" ] \
        && [ "$CONFIRM_TARGET_KERNEL" = "$(policy_value "$REVIEW_POLICY" target_kernel 2>/dev/null)" ] \
        && record_pass 'the explicit short hostname, FQDN, running kernel, and target kernel match the reviewed host boundary' \
        || record_checkpoint_failure 'the live host identity or explicit kernel confirmations do not match the reviewed boundary'

    capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && install -m 0600 -- "$CMDLINE_FILE" "$OUTPUT_DIR/proc-cmdline.txt" \
        && require_regular_file "$(rooted /boot/grub/grub.cfg)" \
        && install -m 0600 -- "$(rooted /boot/grub/grub.cfg)" "$OUTPUT_DIR/grub.cfg.observed" \
        && capture_grubenv "$OUTPUT_DIR/grubenv.before.list" \
        && record_pass 'the package database, command line, GRUB inputs, and reboot-sensitive state were captured before review' \
        || record_checkpoint_failure 'the initial package, command-line, GRUB, or reboot-sensitive state could not be captured'

    validate_package_state "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/package-names.before.txt" \
        && validate_package_records \
        && record_pass 'the installed package database and exact reviewed package records still match the completed 2040-record transaction' \
        || record_checkpoint_failure 'the installed package database or reviewed package records drifted after the accepted safe pause'

    validate_target_artifacts \
        && record_pass 'the exact 6.18.42 kernel, modules, initrd, and both generic links remain unchanged' \
        || record_checkpoint_failure 'the target kernel, initrd, modules, or generic links are incomplete or changed'

    validate_geninitrd_boundary \
        && record_pass 'the restored GenInitrd policy and installed control files retain their accepted identities' \
        || record_checkpoint_failure 'the GenInitrd policy or installed control files changed after the accepted safe pause'

    validate_current_boot_image \
        && record_pass 'the current 6.18.40 session was loaded through the same generic kernel path that the reviewed links now retarget' \
        || record_reboot_failure 'the current boot command line does not identify the reviewed generic kernel path'

    validate_active_grub \
        && install -m 0600 -- "$(rooted /boot/grub/grub.cfg)" "$OUTPUT_DIR/grub.cfg.verified" \
        && record_pass 'the unchanged syntax-valid GRUB configuration has no one-time override and its effective next selection uses the generic kernel/initrd pair' \
        || record_reboot_failure 'the active GRUB configuration, environment, or effective next boot selection is not the reviewed generic pair'

    validate_degraded_rollback \
        && [ "$ACKNOWLEDGE_DEGRADED_ROLLBACK" -eq 1 ] \
        && record_pass 'the user explicitly acknowledged the degraded 6.18.40 rollback state before reboot authorization' \
        || record_reboot_failure 'the degraded 6.18.40 rollback state is different or was not explicitly acknowledged'

    for package_record in \
        kernel-generic-6.18.42-x86_64-1 \
        kernel-headers-6.18.42-x86-1 \
        kernel-source-6.18.42-noarch-1 \
        grub-2.14-x86_64-3 \
        breeze-grub-6.7.4-x86_64-1; do
        if require_regular_file "$PACKAGE_DATABASE/$package_record"; then
            install -m 0600 -- "$PACKAGE_DATABASE/$package_record" "$OUTPUT_DIR/package-record.$package_record"
        fi
    done

    capture_package_database "$OUTPUT_DIR/packages.after.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and reboot-sensitive state were captured after review' \
        || record_checkpoint_failure 'the final package or reboot-sensitive state could not be captured'

    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/package-names.before.txt" "$OUTPUT_DIR/package-names.after.txt" \
        && record_pass 'the installed package database remained unchanged during reboot review' \
        || record_checkpoint_failure 'the installed package database changed during reboot review'

    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the command line, kernel, initrd, GenInitrd, module, GRUB, and GRUB environment state remained unchanged during review' \
        || record_checkpoint_failure 'the reboot-sensitive state changed during reboot review'

    if [ "$CHECKPOINT_FAILURE_COUNT" -eq 0 ]; then
        PAUSE_SAFE=true
    else
        PAUSE_SAFE=false
    fi

    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$AUTHORIZE_REBOOT_REVIEW" -eq 1 ]; then
        REBOOT_READY=true
        REBOOT_AUTHORIZED=true
        NEXT_STAGE=manual-reboot-to-reviewed-target
        record_pass 'the exact 6.18.42 boot selection is authorized for one manual reboot; this command did not execute it'
    elif [ "$PAUSE_SAFE" = true ]; then
        REBOOT_READY=false
        REBOOT_AUTHORIZED=false
        NEXT_STAGE=current-kernel-post-apply-reboot-review-correction
    else
        REBOOT_READY=false
        REBOOT_AUTHORIZED=false
        NEXT_STAGE=manual-recovery-review-required
    fi

    finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
