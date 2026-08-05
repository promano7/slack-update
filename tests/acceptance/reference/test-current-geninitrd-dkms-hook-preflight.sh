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
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-geninitrd-dkms-hook-preflight

TARGET=
TARGET_KERNEL=
CONFIRM_CANDIDATES_SHA256=
NORMAL_PREFLIGHT=$DEFAULT_NORMAL_PREFLIGHT
BOOT_PREFLIGHT=$DEFAULT_BOOT_PREFLIGHT
CHAIN_PREFLIGHT=$DEFAULT_CHAIN_PREFLIGHT
PACKAGE_PREFLIGHT=$DEFAULT_PACKAGE_PREFLIGHT
POLICY_PREFLIGHT=$DEFAULT_POLICY_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
RUNNING_KERNEL=
HOOK_COUNT=0
DKMS_STATUS_ROWS=0
REVIEW_STATUS=unknown
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Inspect the executable DKMS hooks discovered by the accepted Slackware-current
GenInitrd policy preflight. The script copies the hook bodies into private
evidence, validates their metadata and syntax, captures their static command
surface, records read-only DKMS status and source/build inventories, and proves
that packages, boot files, hooks, and DKMS state remain unchanged. It never
executes a hook and never runs dkms build, install, remove, autoinstall, or any
package or boot mutation.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-preflight PATH   Select the accepted normal-update record
      --boot-preflight PATH     Select the accepted boot-layout record
      --chain-preflight PATH    Select the accepted corrected chain-restart record
      --package-preflight PATH  Select the accepted package-inspection record
      --policy-preflight PATH   Select the accepted GenInitrd policy record
      --output-dir PATH         Store evidence under an absolute, new directory
  -h, --help                    Show this help and exit
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
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error 'invalid candidate SHA-256'; return 1; }
    CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
    is_safe_kernel_version "$TARGET_KERNEL" || { error 'unsafe target kernel version'; return 1; }
    for path in "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_accepted_records() {
    python3 - "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CHAIN_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$POLICY_PREFLIGHT" "$CONFIRM_CANDIDATES_SHA256" "$TARGET_KERNEL" <<'PY'
import json, re, sys
normal_path, boot_path, chain_path, package_path, policy_path, digest, target = sys.argv[1:]
try:
    normal = json.load(open(normal_path, encoding='utf-8'))
    boot = json.load(open(boot_path, encoding='utf-8'))
    chain = json.load(open(chain_path, encoding='utf-8'))
    package = json.load(open(package_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
expected_generic = f'kernel-generic-{target}-x86_64-1.txz'
expected_headers = f'kernel-headers-{target}-x86-1.txz'
expected_source = f'kernel-source-{target}-noarch-1.txz'
expected_initrd = f'/boot/initrd-{target}.img'
expected_current_initrd = f'/boot/initrd-{boot.get("running_kernel")}.img'
expected_current_target = f'initrd-{boot.get("running_kernel")}.img'
upgrade = normal.get('candidates', {}).get('upgrade_all', [])
hooks = policy.get('executable_hooks', [])
expected_hooks = {
    ('pre', '/etc/geninitrd.d/pre-install/dkms-bcachefs', 'bef7093aea411c39e971e825ad8651274757c5fd1d6da405028a118ebaec23a9'),
    ('pre', '/etc/geninitrd.d/pre-install/dkms-nvidia', '1430daca29079c8939f714ddff3628156dc990dc8b50e625fa8949367c362efa'),
}
actual_hooks = {
    (item.get('kind'), item.get('path'), item.get('sha256'))
    for item in hooks if item.get('dkms') is True
}
checks = [
    normal.get('scenario') == 'normal-update',
    normal.get('target') == 'slackware-current',
    normal.get('accepted') is True,
    normal.get('candidates', {}).get('candidate_set_sha256') == digest,
    expected_generic in upgrade,
    expected_headers in upgrade,
    expected_source in upgrade,
    normal.get('apply_authorized') is False,
    boot.get('scenario') == 'current-kernel-boot-preflight',
    boot.get('accepted') is True,
    boot.get('normal_update_candidate_set_sha256') == digest,
    boot.get('target_kernel') == target,
    boot.get('boot_mode') == 'geninitrd-managed-versioned-initrd',
    boot.get('named_initrd_path') == '/boot/initrd-generic.img',
    boot.get('named_initrd_target') == expected_current_target,
    boot.get('versioned_initrd_path') == expected_current_initrd,
    re.fullmatch(r'[0-9a-f]{64}', boot.get('versioned_initrd_sha256', '')) is not None,
    boot.get('versioned_initrd_size', 0) > 0,
    boot.get('geninitrd_transition_required') is True,
    boot.get('apply_ready') is False,
    chain.get('scenario') == 'current-kernel-chain-restart-preflight',
    chain.get('accepted') is True,
    chain.get('candidate_set_sha256') == digest,
    chain.get('accepted_boot_archive_sha256') == boot.get('archive_sha256'),
    chain.get('running_kernel') == boot.get('running_kernel'),
    chain.get('target_kernel') == target,
    chain.get('nested_boot_mode') == boot.get('boot_mode'),
    chain.get('nested_named_initrd_target') == boot.get('named_initrd_target'),
    chain.get('nested_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    chain.get('nested_geninitrd_transition_required') is True,
    chain.get('apply_ready') is False,
    package.get('scenario') == 'current-kernel-package-preflight',
    package.get('accepted') is True,
    package.get('normal_update_candidate_set_sha256') == digest,
    package.get('boot_preflight_archive_sha256') == boot.get('archive_sha256'),
    package.get('chain_restart_archive_sha256') == chain.get('archive_sha256'),
    package.get('running_kernel') == boot.get('running_kernel'),
    package.get('target_kernel') == target,
    package.get('boot_mode') == boot.get('boot_mode'),
    package.get('current_named_initrd') == boot.get('named_initrd_path'),
    package.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    package.get('current_versioned_initrd') == boot.get('versioned_initrd_path'),
    package.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    package.get('doinst', {}).get('conditional_geninitrd_hook') is True,
    package.get('apply_ready') is False,
    policy.get('scenario') == 'current-geninitrd-policy-preflight',
    policy.get('accepted') is True,
    policy.get('normal_update_candidate_set_sha256') == digest,
    policy.get('boot_preflight_archive_sha256') == boot.get('archive_sha256'),
    policy.get('chain_restart_archive_sha256') == chain.get('archive_sha256'),
    policy.get('package_preflight_archive_sha256') == package.get('archive_sha256'),
    policy.get('running_kernel') == boot.get('running_kernel'),
    policy.get('target_kernel') == target,
    policy.get('boot_mode') == boot.get('boot_mode'),
    policy.get('current_named_initrd') == boot.get('named_initrd_path'),
    policy.get('current_named_initrd_target') == boot.get('named_initrd_target'),
    policy.get('current_versioned_initrd') == boot.get('versioned_initrd_path'),
    policy.get('current_versioned_initrd_sha256') == boot.get('versioned_initrd_sha256'),
    policy.get('active_grub_sha256') == boot.get('active_grub_sha256'),
    policy.get('policy', {}).get('state') == 'enabled',
    policy.get('policy', {}).get('autogenerate_initrd') is True,
    policy.get('policy', {}).get('named_symlink') is True,
    policy.get('policy', {}).get('initrd_gz_symlink') is False,
    policy.get('policy', {}).get('effective_generator') == 'mkinitrd_command_generator.sh',
    policy.get('policy', {}).get('transition_mode') == 'versioned-to-versioned-initrd',
    policy.get('policy', {}).get('expected_initrd') == expected_initrd,
    policy.get('policy', {}).get('auto_update_grub') is True,
    policy.get('policy', {}).get('custom_review_required') is True,
    actual_hooks == expected_hooks,
    policy.get('next_stage') == 'current-geninitrd-dkms-hook-preflight',
    policy.get('apply_ready') is False,
    policy.get('apply_authorized') is False,
]
raise SystemExit(0 if all(checks) else 1)
PY
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

def rooted(path):
    return root / path.lstrip('/')

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def safe_regular(path, expected_hash=None, expected_size=None):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_size <= 0:
        raise SystemExit(f'unsafe regular file: {path}')
    if info.st_uid != 0 or info.st_gid != 0 or info.st_mode & 0o022:
        raise SystemExit(f'unsafe ownership or mode: {path}')
    if expected_size is not None and info.st_size != expected_size:
        raise SystemExit(f'unexpected size: {path}')
    value = digest(path)
    if expected_hash and value != expected_hash:
        raise SystemExit(f'unexpected hash: {path}')
    return value

def exact_relative_link(path, target):
    info = path.lstat()
    if not stat.S_ISLNK(info.st_mode) or os.readlink(path) != target:
        raise SystemExit(f'unexpected link: {path}')

def scalar(path, name):
    values = []
    pattern = re.compile(rf'^\s*(?:export\s+)?{re.escape(name)}\s*=\s*(.*?)\s*$')
    for raw in path.read_text(encoding='utf-8', errors='strict').splitlines():
        line = raw.split('#', 1)[0].rstrip()
        match = pattern.match(line)
        if match:
            value = match.group(1).strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
                value = value[1:-1]
            values.append(value)
    if len(values) != 1:
        raise SystemExit(f'ambiguous assignment: {name}')
    return values[0]

def grub_pair(path, kernel, initrd):
    blocks, active, depth = [], None, 0
    for line in path.read_text(encoding='utf-8', errors='strict').splitlines():
        stripped = line.strip()
        if active is None and stripped.startswith('menuentry '):
            active, depth = [], 0
        if active is not None:
            active.append(stripped)
            depth += stripped.count('{') - stripped.count('}')
            if depth <= 0 and len(active) > 1:
                blocks.append(active)
                active = None
    for block in blocks:
        linux_ok = any(re.match(r'^linux(?:efi)?\s+', line) and kernel in line.split() for line in block)
        initrd_ok = any(re.match(r'^initrd(?:efi)?\s+', line) and initrd in line.split() for line in block)
        if linux_ok and initrd_ok:
            return True
    return False

if rooted('/etc/mkinitrd.conf').exists() or rooted('/boot/initrd.gz').exists():
    raise SystemExit('legacy initrd state is present')
exact_relative_link(rooted('/boot/vmlinuz-generic'), pathlib.PurePosixPath(record['generic_kernel_path']).name)
generic_hash = safe_regular(rooted(record['generic_kernel_path']), record.get('generic_kernel_sha256'))
exact_relative_link(rooted(record['named_initrd_path']), record['named_initrd_target'])
versioned_hash = safe_regular(rooted(record['versioned_initrd_path']), record.get('versioned_initrd_sha256'), record.get('versioned_initrd_size'))
policy = rooted('/etc/default/geninitrd')
safe_regular(policy)
if (scalar(policy, 'AUTOGENERATE_INITRD'), scalar(policy, 'GENINITRD_NAMED_SYMLINK'), scalar(policy, 'GENINITRD_INITRD_GZ_SYMLINK')) != ('true', 'true', 'false'):
    raise SystemExit('GenInitrd policy no longer matches the accepted baseline')
grub = rooted('/boot/grub/grub.cfg')
grub_hash = safe_regular(grub, record.get('active_grub_sha256'))
if not grub_pair(grub, record['boot_image'], record['named_initrd_path']):
    raise SystemExit('GRUB no longer pairs the accepted kernel and named initrd')
pathlib.Path(output_path).write_text(
    f"boot_mode={record['boot_mode']}\n"
    f"generic_kernel_sha256={generic_hash}\n"
    f"named_initrd={record['named_initrd_path']}\n"
    f"named_initrd_target={record['named_initrd_target']}\n"
    f"versioned_initrd={record['versioned_initrd_path']}\n"
    f"versioned_initrd_sha256={versioned_hash}\n"
    f"active_grub_sha256={grub_hash}\n",
    encoding='utf-8')
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

capture_tree_inventory() {
    local root=$1 depth=$2 output=$3
    python3 - "$root" "$depth" "$output" <<'PY'
import hashlib, os, pathlib, stat, sys
root = pathlib.Path(sys.argv[1])
max_depth = int(sys.argv[2])
out = pathlib.Path(sys.argv[3])
rows = []
if root.is_symlink():
    raise SystemExit(1)
if not root.exists():
    out.write_text(f'{root}|missing\n', encoding='utf-8')
    raise SystemExit(0)
if not root.is_dir():
    raise SystemExit(1)
base_parts = len(root.parts)
for current, dirs, files in os.walk(root, topdown=True, followlinks=False):
    current_path = pathlib.Path(current)
    depth = len(current_path.parts) - base_parts
    dirs[:] = sorted(dirs)
    files = sorted(files)
    if depth >= max_depth:
        dirs[:] = []
    for name in dirs + files:
        path = current_path / name
        rel = path.relative_to(root)
        st = os.lstat(path)
        mode = stat.S_IMODE(st.st_mode)
        if stat.S_ISLNK(st.st_mode):
            kind = 'symlink'
            extra = os.readlink(path)
        elif stat.S_ISDIR(st.st_mode):
            kind = 'directory'
            extra = ''
        elif stat.S_ISREG(st.st_mode):
            kind = 'regular'
            extra = ''
        else:
            kind = 'other'
            extra = ''
        rows.append(f'{rel}|{kind}|{mode:o}:{st.st_uid}:{st.st_gid}:{st.st_size}:{st.st_mtime_ns}|{extra}')
out.write_text('\n'.join(rows) + ('\n' if rows else ''), encoding='utf-8')
PY
}

capture_sensitive_state() {
    local output=$1 path tmp
    : > "$output" || return 1
    for path in \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$RUNNING_KERNEL" \
        "/boot/vmlinuz-$TARGET_KERNEL" \
        /boot/initrd-generic.img \
        "/boot/initrd-$RUNNING_KERNEL.img" \
        "/boot/initrd-$TARGET_KERNEL.img" \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia \
        /usr/sbin/dkms \
        /etc/dkms/framework.conf; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
    while IFS='|' read -r path depth; do
        tmp=$(mktemp)
        capture_tree_inventory "$path" "$depth" "$tmp" || { rm -f -- "$tmp"; return 1; }
        printf 'TREE:%s\n' "$path" >> "$output"
        cat -- "$tmp" >> "$output" || { rm -f -- "$tmp"; return 1; }
        rm -f -- "$tmp"
    done <<EOF_TREES
/etc/geninitrd.d|3
/var/lib/dkms|5
/usr/src|1
/lib/modules/$RUNNING_KERNEL/updates/dkms|5
/lib/modules/$TARGET_KERNEL|3
EOF_TREES
}

analyze_reviewed_hooks() {
    local policy=$1 pre_dir=$2 post_dir=$3 output_dir=$4
    python3 - "$policy" "$pre_dir" "$post_dir" "$output_dir" <<'PY'
import hashlib, json, os, pathlib, re, shutil, stat, subprocess, sys
policy_path, pre_path, post_path, output_path = sys.argv[1:]
policy = json.load(open(policy_path, encoding='utf-8'))
pre = pathlib.Path(pre_path)
post = pathlib.Path(post_path)
out = pathlib.Path(output_path)
out.mkdir(mode=0o700, parents=True, exist_ok=False)
expected = {item['path']: item for item in policy['executable_hooks']}
observed = {}
for kind, directory in (('pre', pre), ('post', post)):
    if directory.is_symlink() or not directory.is_dir():
        raise SystemExit(1)
    for path in sorted(directory.iterdir(), key=lambda item: item.name):
        if path.is_symlink() or not path.is_file():
            raise SystemExit(1)
        if not os.access(path, os.X_OK):
            continue
        observed[str(path)] = (kind, path)
if set(observed) != set(expected):
    raise SystemExit(1)
results = []
keywords = {'if','then','else','elif','fi','for','while','until','do','done','case','esac','function','select','in','time','coproc','{','}','!'}
for configured, (kind, path) in observed.items():
    st = path.stat()
    if st.st_uid != 0 or stat.S_IMODE(st.st_mode) & 0o022:
        raise SystemExit(1)
    data = path.read_bytes()
    if b'\0' in data or b'\r' in data:
        raise SystemExit(1)
    digest = hashlib.sha256(data).hexdigest()
    if digest != expected[configured]['sha256'] or kind != expected[configured]['kind']:
        raise SystemExit(1)
    subprocess.run(['/bin/bash', '-n', str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    text = data.decode('utf-8', errors='strict')
    if not text.startswith('#!'):
        raise SystemExit(1)
    copy = out / path.name
    copy.write_bytes(data)
    copy.chmod(0o600)
    commands = []
    absolute_paths = set()
    features = set()
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        if '$(' in stripped:
            features.add('command-substitution')
        if '`' in stripped:
            features.add('backticks')
        if 'eval ' in f' {stripped} ':
            features.add('eval')
        if 'source ' in f' {stripped} ' or re.search(r'(^|[;&|()\s])\.\s', stripped):
            features.add('source')
        absolute_paths.update(re.findall(r'(?<![A-Za-z0-9_.-])(/[A-Za-z0-9_./+:-]+)', stripped))
        cleaned = re.sub(r'^[(){};\s]+', '', stripped)
        token = re.split(r'[\s;|&(){}]+', cleaned, maxsplit=1)[0] if cleaned else ''
        if token and token not in keywords and re.fullmatch(r'[A-Za-z0-9_./+:-]+', token):
            commands.append(token)
    results.append({
        'kind': kind,
        'path': configured,
        'sha256': digest,
        'mode': f'{stat.S_IMODE(st.st_mode):04o}',
        'owner_uid': st.st_uid,
        'syntax_valid': True,
        'copied_as': str(copy),
        'commands': sorted(set(commands)),
        'absolute_paths': sorted(absolute_paths),
        'shell_features': sorted(features),
        'requires_manual_content_review': True,
        'executed': False,
    })
(out / 'analysis.json').write_text(json.dumps({'hooks': results, 'hook_count': len(results), 'review_status': 'custom-review-required', 'apply_ready': False, 'apply_authorized': False}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

capture_dkms_discovery() {
    local output_dir=$1 dkms_path version_status
    dkms_path=$(command -v dkms 2>/dev/null || true)
    [ -n "$dkms_path" ] || return 1
    dkms_path=$(readlink -e -- "$dkms_path" 2>/dev/null || true)
    [ -n "$dkms_path" ] && [ -f "$dkms_path" ] && [ -x "$dkms_path" ] || return 1
    printf '%s\n' "$dkms_path" > "$output_dir/dkms-command.txt"
    dkms --version > "$output_dir/dkms-version.txt" 2>&1 || return 1
    dkms status > "$output_dir/dkms-status.txt" 2>&1 || return 1
    capture_tree_inventory /var/lib/dkms 5 "$output_dir/var-lib-dkms.txt" || return 1
    capture_tree_inventory /usr/src 1 "$output_dir/usr-src.txt" || return 1
    capture_tree_inventory "/lib/modules/$RUNNING_KERNEL/updates/dkms" 5 "$output_dir/running-modules-dkms.txt" || return 1
    capture_tree_inventory "/lib/modules/$TARGET_KERNEL" 5 "$output_dir/target-modules.txt" || return 1
    python3 - "$output_dir/dkms-status.txt" "$output_dir/dkms-discovery.json" "$RUNNING_KERNEL" "$TARGET_KERNEL" <<'PY'
import json, pathlib, sys
status_path, output_path, running, target = sys.argv[1:]
rows = [line.strip() for line in pathlib.Path(status_path).read_text(encoding='utf-8', errors='replace').splitlines() if line.strip()]
result = {
    'status_rows': rows,
    'status_row_count': len(rows),
    'running_kernel': running,
    'target_kernel': target,
    'target_build_executed': False,
    'commands_executed': ['dkms --version', 'dkms status'],
    'forbidden_commands_executed': [],
    'review_status': 'custom-review-required',
    'apply_ready': False,
    'apply_authorized': False,
}
pathlib.Path(output_path).write_text(json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-geninitrd-dkms-hook-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
boot_mode=geninitrd-managed-versioned-initrd
transition_mode=versioned-to-versioned-initrd
reviewed_hook_count=$HOOK_COUNT
dkms_status_rows=$DKMS_STATUS_ROWS
review_status=$REVIEW_STATUS
hooks_executed=false
dkms_build_executed=false
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-geninitrd-dkms-hook-preflight-${timestamp}.tar.gz"
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
    local timestamp hook_json dkms_json
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in python3 sha256sum tar find bash stat dkms grub-script-check; do
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
        && record_pass 'the accepted candidate, corrected boot, restarted-chain, exact-package, and versioned GenInitrd policy records match this DKMS-hook inspection' \
        || record_failure 'the accepted records do not match this DKMS-hook inspection'
    [ "$RUNNING_KERNEL" != "$TARGET_KERNEL" ] && is_safe_kernel_version "$RUNNING_KERNEL" \
        && record_pass "the running kernel $RUNNING_KERNEL remains the reviewed predecessor of $TARGET_KERNEL" \
        || record_failure 'the running and target kernel relationship is unsafe'
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and DKMS-sensitive boot state were captured before inspection' \
        || record_failure 'the initial package or DKMS-sensitive state could not be captured'

    validate_live_geninitrd_baseline "$BOOT_PREFLIGHT" / "$OUTPUT_DIR/live-geninitrd-baseline.txt" \
        && record_pass 'the live generic kernel, versioned initrd, GenInitrd policy, and GRUB pairing match the corrected baseline' \
        || record_failure 'the live GenInitrd-managed baseline no longer matches the accepted chain'

    if analyze_reviewed_hooks "$POLICY_PREFLIGHT" /etc/geninitrd.d/pre-install /etc/geninitrd.d/post-install "$OUTPUT_DIR/hooks"; then
        hook_json=$OUTPUT_DIR/hooks/analysis.json
        HOOK_COUNT=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hook_count"])' "$hook_json")
        REVIEW_STATUS=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["review_status"])' "$hook_json")
        record_pass 'the exact reviewed DKMS hooks are root-owned, immutable to non-root users, syntax-valid, and copied without execution'
        record_pass 'the hook command surfaces were captured for manual review without evaluating shell code'
    else
        record_failure 'the reviewed DKMS hook set, metadata, hashes, or syntax are unsafe'
        record_failure 'the DKMS hook command surfaces could not be captured safely'
    fi

    if capture_dkms_discovery "$OUTPUT_DIR"; then
        dkms_json=$OUTPUT_DIR/dkms-discovery.json
        DKMS_STATUS_ROWS=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status_row_count"])' "$dkms_json")
        record_pass 'read-only DKMS version and status completed without invoking any build or install action'
        record_pass 'DKMS sources, build state, running modules, and target-kernel paths were inventoried without mutation'
    else
        record_failure 'read-only DKMS status could not be captured safely'
        record_failure 'DKMS source, build, or module inventories could not be captured safely'
    fi

    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and DKMS-sensitive boot state were captured after inspection' \
        || record_failure 'the final package or DKMS-sensitive state could not be captured'
    if [ -f "$OUTPUT_DIR/packages.before.txt" ] && [ -f "$OUTPUT_DIR/packages.after.txt" ] \
        && cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt"; then
        record_pass 'the installed package database remained unchanged during the DKMS-hook preflight'
    else
        record_failure 'the installed package database changed or could not be compared'
    fi
    if [ -f "$OUTPUT_DIR/sensitive.before.txt" ] && [ -f "$OUTPUT_DIR/sensitive.after.txt" ] \
        && cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt"; then
        record_pass 'the active boot, GenInitrd hooks, and DKMS state remained unchanged during the preflight'
    else
        record_failure 'the active boot, GenInitrd hooks, or DKMS state changed or could not be compared'
    fi

    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current DKMS hook result: running=%s, target=%s, hooks=%s, dkms-status-rows=%s, review=%s, apply-ready=false, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$HOOK_COUNT" "$DKMS_STATUS_ROWS" "$REVIEW_STATUS"
    publish_evidence || { error 'failed to publish evidence'; return 2; }
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
