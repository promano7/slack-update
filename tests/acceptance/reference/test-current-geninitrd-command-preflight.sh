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
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-geninitrd-command-preflight

TARGET=
TARGET_KERNEL=
CONFIRM_CANDIDATES_SHA256=
NORMAL_PREFLIGHT=$DEFAULT_NORMAL_PREFLIGHT
BOOT_PREFLIGHT=$DEFAULT_BOOT_PREFLIGHT
CHAIN_PREFLIGHT=$DEFAULT_CHAIN_PREFLIGHT
PACKAGE_PREFLIGHT=$DEFAULT_PACKAGE_PREFLIGHT
POLICY_PREFLIGHT=$DEFAULT_POLICY_PREFLIGHT
DKMS_PREFLIGHT=$DEFAULT_DKMS_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
RUNNING_KERNEL=
GENERATOR_SCRIPT=/usr/share/mkinitrd/mkinitrd_command_generator.sh
SETUP_SCRIPT=/var/lib/pkgtools/setup/setup.01.mkinitrd
EXPECTED_INITRD=
GENERATOR_SHA256=
COMMAND_STATUS=not-run
CURRENT_COMMAND=
PROJECTED_COMMAND=
APPLY_READY=false
APPLY_AUTHORIZED=false
REVIEWED_PACKAGE_FILENAME=
REVIEWED_PACKAGE_SHA256=

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Inspect the installed mkinitrd command generator in command-output mode only.
The preflight validates all accepted Slackware-current records, invokes the
reviewed generator only for the currently installed kernel without --run,
parses exactly one inert mkinitrd command vector, projects that vector to the
reviewed target kernel and versioned initrd path, revalidates the corrected GenInitrd-managed versioned-initrd baseline,
confirms the exact cached kernel package, and proves that packages and
boot-sensitive state remain unchanged. It never executes mkinitrd, geninitrd, update-grub, package tools,
or the generated command.

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
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error 'invalid candidate SHA-256'; return 1; }
    CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
    is_safe_kernel_version "$TARGET_KERNEL" || { error 'unsafe target kernel version'; return 1; }
    for path in "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" "$DKMS_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_accepted_records() {
    local identity
    REVIEWED_PACKAGE_FILENAME=
    REVIEWED_PACKAGE_SHA256=
    identity=$(python3 - "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" "$DKMS_PREFLIGHT" "$CONFIRM_CANDIDATES_SHA256" "$TARGET_KERNEL" <<'PY'
import json, re, sys
normal_path, boot_path, chain_path, package_path, policy_path, dkms_path, digest, target = sys.argv[1:]
try:
    normal = json.load(open(normal_path, encoding='utf-8'))
    boot = json.load(open(boot_path, encoding='utf-8'))
    chain = json.load(open(chain_path, encoding='utf-8'))
    package = json.load(open(package_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
    dkms = json.load(open(dkms_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
expected = f'kernel-generic-{target}-x86_64-1.txz'
expected_current_initrd = f'/boot/initrd-{boot.get("running_kernel")}.img'
expected_current_target = f'initrd-{boot.get("running_kernel")}.img'
expected_target_initrd = f'/boot/initrd-{target}.img'
package_filename = package.get('package', {}).get('filename')
package_sha256 = package.get('package', {}).get('sha256')
if isinstance(package_sha256, str):
    package_sha256 = package_sha256.lower()
def is_sha256(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None
def denied(record):
    return record.get('apply_ready') is False and record.get('apply_authorized') is False
checks = [
    normal.get('scenario') == 'normal-update', normal.get('accepted') is True,
    normal.get('candidates', {}).get('candidate_set_sha256') == digest,
    normal.get('candidates', {}).get('target_kernel_version') == target,
    expected in normal.get('candidates', {}).get('upgrade_all', []),
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
    is_sha256(chain.get('nested_boot_archive_sha256')),
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
    package.get('chain_nested_boot_archive_sha256') == chain.get('nested_boot_archive_sha256'),
    package.get('running_kernel') == boot.get('running_kernel'), package.get('target_kernel') == target,
    package.get('boot_mode') == boot.get('boot_mode'),
    package.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    package.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    package.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    package_filename == expected, is_sha256(package_sha256),
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
    policy.get('policy', {}).get('effective_generator') == 'mkinitrd_command_generator.sh',
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
    dkms.get('dkms', {}).get('var_lib_dkms_state') == 'empty',
    dkms.get('dkms', {}).get('running_updates_dkms_state') == 'missing',
    dkms.get('dkms', {}).get('target_module_tree_state') == 'missing',
    dkms.get('review_status') == 'accepted-noop-hooks',
    len(dkms.get('hooks', [])) == 2,
    all(item.get('predicted_action') == 'no-op-no-registered-module' for item in dkms.get('hooks', [])),
    dkms.get('hooks_executed') is False, dkms.get('dkms_build_executed') is False,
    dkms.get('next_stage') == 'current-geninitrd-command-preflight', denied(dkms),
]
if not all(checks):
    raise SystemExit(1)
print(f'{package_filename}\t{package_sha256}')
PY
) || return 1
    local IFS=$'\t'
    read -r REVIEWED_PACKAGE_FILENAME REVIEWED_PACKAGE_SHA256 <<< "$identity"
    [ "$REVIEWED_PACKAGE_FILENAME" = "kernel-generic-${TARGET_KERNEL}-x86_64-1.txz" ] \
        && is_sha256 "$REVIEWED_PACKAGE_SHA256"
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
        "$GENERATOR_SCRIPT" \
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

validate_generator_scripts() {
    local output=$1
    for path in "$GENERATOR_SCRIPT" "$SETUP_SCRIPT"; do
        [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ] && [ -x "$path" ] || return 1
        [ "$(stat -c '%u' -- "$path")" -eq 0 ] || return 1
        [ $((8#$(stat -c '%a' -- "$path") & 8#022)) -eq 0 ] || return 1
        bash -n "$path" || return 1
    done
    grep -Fq 'mkinitrd_command_generator.sh' "$SETUP_SCRIPT" || return 1
    grep -Fq 'initrd-${KERNEL_VERSION}.img' "$SETUP_SCRIPT" || return 1
    grep -Fq 'KERNEL_DOINST' "$SETUP_SCRIPT" || return 1
    GENERATOR_SHA256=$(sha256sum -- "$GENERATOR_SCRIPT" | awk '{print $1}')
    {
        printf 'generator=%s\n' "$GENERATOR_SCRIPT"
        printf 'generator_sha256=%s\n' "$GENERATOR_SHA256"
        printf 'setup=%s\n' "$SETUP_SCRIPT"
        printf 'setup_sha256=%s\n' "$(sha256sum -- "$SETUP_SCRIPT" | awk '{print $1}')"
    } > "$output"
}

locate_reviewed_package() {
    local output=$1 path count=0 digest
    [ -n "$REVIEWED_PACKAGE_FILENAME" ] && is_sha256 "$REVIEWED_PACKAGE_SHA256" || return 1
    : > "$output" || return 1
    while IFS= read -r -d '' path; do
        [ -f "$path" ] && [ ! -L "$path" ] || return 1
        count=$((count + 1))
        printf '%s\n' "$path" >> "$output"
    done < <(find /var/cache/packages -type f -name "$REVIEWED_PACKAGE_FILENAME" -print0 2>/dev/null | LC_ALL=C sort -z)
    [ "$count" -eq 1 ] || return 1
    path=$(head -n 1 -- "$output")
    digest=$(sha256sum -- "$path" | awk '{print $1}')
    {
        printf 'expected_filename=%s\n' "$REVIEWED_PACKAGE_FILENAME"
        printf 'expected_sha256=%s\n' "$REVIEWED_PACKAGE_SHA256"
        printf 'observed_sha256=%s\n' "$digest"
    } >> "$output"
    [ "$digest" = "$REVIEWED_PACKAGE_SHA256" ]
}

parse_generator_output() {
    local stdout_file=$1 analysis_file=$2
    python3 - "$stdout_file" "$analysis_file" "$RUNNING_KERNEL" "$TARGET_KERNEL" "$EXPECTED_INITRD" <<'PY'
import json, pathlib, re, shlex, sys
stdout_path, analysis_path, running, target, expected_initrd = sys.argv[1:]
text = pathlib.Path(stdout_path).read_text(encoding='utf-8', errors='strict')
if '\x00' in text or '\r' in text or '$(' in text or '`' in text:
    raise SystemExit(1)
logical = []
buffer = ''
for raw in text.splitlines():
    line = raw.strip()
    if not line:
        continue
    if buffer:
        buffer += ' ' + line
    else:
        buffer = line
    if buffer.endswith('\\'):
        buffer = buffer[:-1].rstrip()
        continue
    logical.append(buffer)
    buffer = ''
if buffer:
    logical.append(buffer)
commands = []
for line in logical:
    try:
        tokens = shlex.split(line, posix=True)
    except ValueError:
        continue
    if tokens and pathlib.PurePosixPath(tokens[0]).name == 'mkinitrd':
        commands.append((line, tokens))
if len(commands) != 1:
    raise SystemExit(1)
raw, tokens = commands[0]
if any(ch in raw for ch in ';|&<>'):
    raise SystemExit(1)
if any(any(ord(ch) < 32 for ch in token) for token in tokens):
    raise SystemExit(1)
if '-k' not in tokens:
    raise SystemExit(1)
kidx = tokens.index('-k')
if kidx + 1 >= len(tokens) or tokens[kidx + 1] != running:
    raise SystemExit(1)
if '-c' not in tokens:
    raise SystemExit(1)
projected = list(tokens)
projected[kidx + 1] = target
if '-o' in projected:
    oidx = projected.index('-o')
    if oidx + 1 >= len(projected):
        raise SystemExit(1)
    current_output = projected[oidx + 1]
    if not current_output.startswith('/boot/') or '..' in pathlib.PurePosixPath(current_output).parts:
        raise SystemExit(1)
    projected[oidx + 1] = expected_initrd
else:
    current_output = None
    projected.extend(['-o', expected_initrd])
for token in projected:
    if '\n' in token or '\r' in token or '\x00' in token:
        raise SystemExit(1)
    if token.startswith('/') and '..' in pathlib.PurePosixPath(token).parts:
        raise SystemExit(1)
module_list = []
if '-m' in projected:
    midx = projected.index('-m')
    if midx + 1 >= len(projected):
        raise SystemExit(1)
    module_list = [item for item in projected[midx + 1].split(':') if item]
    if any(not re.fullmatch(r'[A-Za-z0-9_.+-]+', item) for item in module_list):
        raise SystemExit(1)
result = {
    'generator_mode': 'command-output-only',
    'generator_executed_for_kernel': running,
    'generated_command_executed': False,
    'current_command_raw': raw,
    'current_command_vector': tokens,
    'current_output': current_output,
    'projected_target_kernel': target,
    'projected_initrd': expected_initrd,
    'projected_command_vector': projected,
    'module_count': len(module_list),
    'modules': module_list,
    'requires_post-install_confirmation': True,
    'apply_ready': False,
    'apply_authorized': False,
}
pathlib.Path(analysis_path).write_text(json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

run_generator_command_only() {
    local stdout_file=$1 stderr_file=$2 analysis_file=$3
    timeout 30 "$GENERATOR_SCRIPT" -k "$RUNNING_KERNEL" > "$stdout_file" 2> "$stderr_file" || return 1
    parse_generator_output "$stdout_file" "$analysis_file" || return 1
    COMMAND_STATUS=projected-safe
    CURRENT_COMMAND=$(python3 -c 'import json,sys,shlex; print(shlex.join(json.load(open(sys.argv[1]))["current_command_vector"]))' "$analysis_file")
    PROJECTED_COMMAND=$(python3 -c 'import json,sys,shlex; print(shlex.join(json.load(open(sys.argv[1]))["projected_command_vector"]))' "$analysis_file")
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-geninitrd-command-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
boot_mode=geninitrd-managed-versioned-initrd
transition_mode=versioned-to-versioned-initrd
current_versioned_initrd=/boot/initrd-$RUNNING_KERNEL.img
expected_initrd=$EXPECTED_INITRD
generator_sha256=$GENERATOR_SHA256
command_status=$COMMAND_STATUS
generator_run_mode=command-output-only
generated_command_executed=false
mkinitrd_executed=false
geninitrd_executed=false
update_grub_executed=false
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-geninitrd-command-preflight-${timestamp}.tar.gz"
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
    local timestamp
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in python3 sha256sum tar find bash stat timeout grub-script-check; do
        command -v "$command" >/dev/null 2>&1 || { error "required command missing: $command"; return 2; }
    done
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"
    RUNNING_KERNEL=$(uname -r)
    EXPECTED_INITRD="/boot/initrd-${TARGET_KERNEL}.img"

    validate_accepted_records \
        && record_pass 'the accepted candidate, corrected boot, restarted-chain, exact-package, versioned GenInitrd policy, and no-op DKMS records match this generator inspection' \
        || record_failure 'the accepted records do not match this generator inspection'
    [ "$RUNNING_KERNEL" != "$TARGET_KERNEL" ] && is_safe_kernel_version "$RUNNING_KERNEL" \
        && record_pass "the running kernel $RUNNING_KERNEL remains the reviewed predecessor of $TARGET_KERNEL" \
        || record_failure 'the running and target kernel relationship is unsafe'
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and generator-sensitive boot state were captured before inspection' \
        || record_failure 'the initial package or generator-sensitive state could not be captured'

    validate_live_geninitrd_baseline "$BOOT_PREFLIGHT" / "$OUTPUT_DIR/live-geninitrd-baseline.txt" \
        && record_pass 'the live generic kernel, versioned initrd, GenInitrd policy, and GRUB pairing match the corrected baseline' \
        || record_failure 'the live GenInitrd-managed versioned-initrd baseline no longer matches the accepted chain'
    validate_generator_scripts "$OUTPUT_DIR/scripts.txt" \
        && record_pass 'the installed generator and setup scripts are safe, syntax-valid, and expose the reviewed versioned-initrd flow' \
        || record_failure 'the installed generator or setup script is unsafe or no longer matches the reviewed flow'
    locate_reviewed_package "$OUTPUT_DIR/package-cache.txt" \
        && record_pass 'the exact reviewed kernel-generic package remains uniquely cached with its accepted SHA-256' \
        || record_failure 'the reviewed kernel-generic package is missing, ambiguous, unsafe, or changed'
    if run_generator_command_only "$OUTPUT_DIR/generator.stdout.txt" "$OUTPUT_DIR/generator.stderr.txt" "$OUTPUT_DIR/generator-analysis.json"; then
        record_pass 'the mkinitrd command generator completed in command-output mode without --run'
        record_pass 'exactly one inert mkinitrd command for the running kernel was parsed as a safe argument vector'
        record_pass 'the command vector was projected safely to the reviewed target kernel and versioned initrd path'
    else
        record_failure 'the mkinitrd command generator did not complete safely in command-output mode'
        record_failure 'the generated output did not contain exactly one safe inert mkinitrd command'
        record_failure 'a safe target-kernel versioned-initrd command could not be projected'
    fi

    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and generator-sensitive boot state were captured after inspection' \
        || record_failure 'the final package or generator-sensitive state could not be captured'
    if [ -f "$OUTPUT_DIR/packages.before.txt" ] && [ -f "$OUTPUT_DIR/packages.after.txt" ] \
        && cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt"; then
        record_pass 'the installed package database remained unchanged during the generator preflight'
    else
        record_failure 'the installed package database changed or could not be compared'
    fi
    if [ -f "$OUTPUT_DIR/sensitive.before.txt" ] && [ -f "$OUTPUT_DIR/sensitive.after.txt" ] \
        && cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt"; then
        record_pass 'the active boot, GenInitrd, DKMS, and generator state remained unchanged during the preflight'
    else
        record_failure 'the active boot, GenInitrd, DKMS, or generator state changed or could not be compared'
    fi

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current GenInitrd command result: running=%s, target=%s, transition=versioned-to-versioned-initrd, initrd=%s, command=%s, apply-ready=false, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$EXPECTED_INITRD" "$COMMAND_STATUS"
    publish_evidence || { error 'failed to publish evidence'; return 2; }
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
