#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-accepted.json"
DEFAULT_BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-accepted.json"
DEFAULT_PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260803-accepted.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-geninitrd-policy-preflight

TARGET=
TARGET_KERNEL=
CONFIRM_CANDIDATES_SHA256=
NORMAL_PREFLIGHT=$DEFAULT_NORMAL_PREFLIGHT
BOOT_PREFLIGHT=$DEFAULT_BOOT_PREFLIGHT
PACKAGE_PREFLIGHT=$DEFAULT_PACKAGE_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
RUNNING_KERNEL=
POLICY_STATE=unknown
DOINST_WILL_INVOKE=unknown
AUTOGENERATE_INITRD=unknown
EFFECTIVE_GENERATOR=unknown
AUTO_UPDATE_GRUB=unknown
TRANSITION_MODE=unknown
CUSTOM_REVIEW_REQUIRED=unknown
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Inspect the installed Slackware-current geninitrd policy that the reviewed
kernel-generic doinst.sh would invoke. The preflight statically validates the
installed scripts, parses /etc/default/geninitrd without sourcing it, inventories
custom hooks, predicts initrd and GRUB side effects, and proves that packages and
active boot state remain unchanged. It never executes geninitrd, a generator,
update-grub, package installation, or any boot mutation.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-preflight PATH   Select the accepted normal-update record
      --boot-preflight PATH     Select the accepted boot-layout record
      --package-preflight PATH  Select the accepted package-inspection record
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
            --package-preflight) [ "$#" -ge 2 ] || return 1; PACKAGE_PREFLIGHT=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error 'invalid candidate SHA-256'; return 1; }
    CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
    is_safe_kernel_version "$TARGET_KERNEL" || { error 'unsafe target kernel version'; return 1; }
    for path in "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$PACKAGE_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_accepted_records() {
    python3 - "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$PACKAGE_PREFLIGHT" "$CONFIRM_CANDIDATES_SHA256" "$TARGET_KERNEL" <<'PY'
import json, sys
normal_path, boot_path, package_path, digest, target = sys.argv[1:]
try:
    normal = json.load(open(normal_path, encoding='utf-8'))
    boot = json.load(open(boot_path, encoding='utf-8'))
    package = json.load(open(package_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
expected = f'kernel-generic-{target}-x86_64-1.txz'
checks = [
    normal.get('scenario') == 'normal-update',
    normal.get('target') == 'slackware-current',
    normal.get('accepted') is True,
    normal.get('candidates', {}).get('candidate_set_sha256') == digest,
    expected in normal.get('candidates', {}).get('upgrade_all', []),
    normal.get('apply_authorized') is False,
    boot.get('scenario') == 'current-kernel-boot-preflight',
    boot.get('accepted') is True,
    boot.get('normal_update_candidate_set_sha256') == digest,
    boot.get('target_kernel') == target,
    boot.get('boot_mode') == 'direct-generic-no-initrd',
    boot.get('apply_ready') is False,
    package.get('scenario') == 'current-kernel-package-preflight',
    package.get('accepted') is True,
    package.get('normal_update_candidate_set_sha256') == digest,
    package.get('target_kernel') == target,
    package.get('package', {}).get('filename') == expected,
    package.get('doinst', {}).get('conditional_geninitrd_hook') is True,
    package.get('doinst', {}).get('host_policy_preflight_required') is True,
    package.get('apply_ready') is False,
    package.get('apply_authorized') is False,
]
raise SystemExit(0 if all(checks) else 1)
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
        printf 'regular|%s|%s' "$(stat -c '%a:%u:%g:%s' -- "$path")" "$(sha256sum -- "$path" | awk '{print $1}')"
    elif [ -d "$path" ]; then
        printf 'directory|%s|' "$(stat -c '%a:%u:%g' -- "$path")"
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
        "/boot/vmlinuz-$TARGET_KERNEL" \
        /boot/initrd.gz \
        /boot/initrd-generic.img \
        "/boot/initrd-$TARGET_KERNEL.img" \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        /etc/mkinitrd.conf \
        /usr/sbin/geninitrd \
        /var/lib/pkgtools/setup/setup.01.mkinitrd; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

inventory_hooks() {
    local pre_dir=$1 post_dir=$2 output=$3 dir path
    : > "$output" || return 1
    for dir in "$pre_dir" "$post_dir"; do
        if [ -L "$dir" ]; then
            return 1
        elif [ ! -e "$dir" ]; then
            printf '%s\tmissing\n' "$dir" >> "$output"
            continue
        elif [ ! -d "$dir" ]; then
            return 1
        fi
        printf '%s\tdirectory\n' "$dir" >> "$output"
        while IFS= read -r -d '' path; do
            if [ -L "$path" ]; then
                printf '%s\tsymlink\t%s\n' "$path" "$(readlink -- "$path" 2>/dev/null || true)" >> "$output"
            elif [ -f "$path" ]; then
                printf '%s\tregular\t%s\t%s\n' "$path" "$(test -x "$path" && printf executable || printf inactive)" "$(sha256sum -- "$path" | awk '{print $1}')" >> "$output"
            else
                printf '%s\tunsupported\n' "$path" >> "$output"
            fi
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z)
    done
}

analyze_geninitrd_policy() {
    local config=$1 geninitrd=$2 setup=$3 mkinitrd_conf=$4 pre_dir=$5 post_dir=$6 root=$7 target=$8 output=$9
    [ -f "$geninitrd" ] && [ ! -L "$geninitrd" ] && [ -r "$geninitrd" ] && [ -x "$geninitrd" ] || return 1
    [ -f "$setup" ] && [ ! -L "$setup" ] && [ -r "$setup" ] && [ -x "$setup" ] || return 1
    bash -n "$geninitrd" && bash -n "$setup" || return 1
    python3 - "$config" "$geninitrd" "$setup" "$mkinitrd_conf" "$pre_dir" "$post_dir" "$root" "$target" "$output" <<'PY'
import hashlib, json, os, pathlib, re, shlex, sys
config_path, geninitrd_path, setup_path, mkinitrd_conf_path, pre_dir, post_dir, root_path, target, output_path = sys.argv[1:]
root = pathlib.Path(root_path)
out = pathlib.Path(output_path)
geninitrd = pathlib.Path(geninitrd_path)
setup = pathlib.Path(setup_path)
config = pathlib.Path(config_path)
mkinitrd_conf = pathlib.Path(mkinitrd_conf_path)

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def rooted(path):
    p = pathlib.PurePosixPath(path)
    if p.is_absolute():
        p = pathlib.PurePosixPath(*p.parts[1:])
    if '..' in p.parts:
        raise ValueError(f'unsafe configured path: {path}')
    return root.joinpath(*p.parts)

def safe_script(path_value):
    if not path_value:
        return None
    path = rooted(path_value)
    if path.is_symlink() or not path.is_file() or not os.access(path, os.X_OK):
        raise ValueError(f'configured script is not a safe executable regular file: {path_value}')
    return {'configured': path_value, 'resolved': str(path.resolve(strict=True)), 'sha256': digest(path)}

gen_text = geninitrd.read_text(encoding='utf-8', errors='strict')
setup_text = setup.read_text(encoding='utf-8', errors='strict')
required_gen = [
    'etc/default/geninitrd',
    'GENINITRD_OVERRIDE_SCRIPT',
    '/var/lib/pkgtools/setup/setup.01.mkinitrd',
    'etc/geninitrd.d/pre-install',
    'etc/geninitrd.d/post-install',
]
required_setup = [
    'AUTOGENERATE_INITRD=${AUTOGENERATE_INITRD:-true}',
    'AUTO_UPDATE_GRUB=${AUTO_UPDATE_GRUB:-true}',
    'KERNEL_DOINST',
    'AUTOGENERATE_INITRD" = "false',
    'initrd-${KERNEL_VERSION}.img',
    'mkinitrd_command_generator.sh',
    '/usr/sbin/update-grub',
]
if not all(token in gen_text for token in required_gen):
    raise SystemExit('installed geninitrd script does not match the reviewed control flow')
if not all(token in setup_text for token in required_setup):
    raise SystemExit('installed setup.01.mkinitrd does not match the reviewed control flow')

values = {
    'KERNEL': '',
    'GENINITRD_NAMED_SYMLINK': 'true',
    'GENINITRD_INITRD_GZ_SYMLINK': 'true',
    'GENERATOR': 'mkinitrd',
    'AUTOGENERATE_INITRD': 'true',
    'AUTO_REMOVE_ORPHANED_INITRDS': 'true',
    'AUTO_REMOVE_INITRD_TREE': 'true',
    'AUTO_UPDATE_GRUB': 'true',
    'GENINITRD_OVERRIDE_SCRIPT': '',
    'POST_INSTALL_SCRIPT': '',
}
allowed = set(values) | {'DRACUT_OPTS', 'GENINITRD_DIALOG', 'GENINITRD_COMMAND_OUTPUT'}
config_state = 'missing-defaults'
if config.exists() or config.is_symlink():
    if config.is_symlink() or not config.is_file():
        raise SystemExit('unsafe /etc/default/geninitrd')
    config_state = 'regular'
    for number, raw in enumerate(config.read_text(encoding='utf-8', errors='strict').splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        match = re.fullmatch(r'([A-Z][A-Z0-9_]*)=(.*)', line)
        if not match or match.group(1) not in allowed:
            raise SystemExit(f'unsupported active geninitrd configuration at line {number}')
        key, raw_value = match.groups()
        if any(token in raw_value for token in ('`', '$(', '${', ';', '&&', '||', '\n', '\r')):
            raise SystemExit(f'unsafe active geninitrd configuration at line {number}')
        try:
            parts = shlex.split(raw_value, posix=True)
        except ValueError:
            raise SystemExit(f'invalid quoting at line {number}')
        if len(parts) > 1:
            value = ' '.join(parts)
        elif parts:
            value = parts[0]
        else:
            value = ''
        if key in values:
            values[key] = value

for key in ('GENINITRD_NAMED_SYMLINK', 'GENINITRD_INITRD_GZ_SYMLINK', 'AUTOGENERATE_INITRD', 'AUTO_REMOVE_ORPHANED_INITRDS', 'AUTO_REMOVE_INITRD_TREE', 'AUTO_UPDATE_GRUB'):
    if values[key] not in ('true', 'false'):
        raise SystemExit(f'{key} must be exactly true or false')
if values['GENERATOR'] not in ('mkinitrd', 'mkinitrd_command_generator.sh', 'dracut'):
    raise SystemExit('unsupported GENERATOR value')

legacy_skip = re.search(r'(?<![A-Za-z0-9_.-])vmlinuz-generic-smp(?![A-Za-z0-9_.-])', setup_text) is not None
doinst_will_invoke = not legacy_skip
custom_scripts = []
for label, configured in (('override', values['GENINITRD_OVERRIDE_SCRIPT']), ('post_install', values['POST_INSTALL_SCRIPT'])):
    item = safe_script(configured)
    if item:
        item['kind'] = label
        custom_scripts.append(item)

hook_items = []
for kind, directory in (('pre', pathlib.Path(pre_dir)), ('post', pathlib.Path(post_dir))):
    if directory.is_symlink():
        raise SystemExit(f'unsafe {kind}-install hook directory')
    if not directory.exists():
        continue
    if not directory.is_dir():
        raise SystemExit(f'unsupported {kind}-install hook path')
    for path in sorted(directory.iterdir(), key=lambda item: item.name):
        if path.is_symlink():
            raise SystemExit(f'symlinked {kind}-install hook is not accepted: {path}')
        if not path.is_file():
            raise SystemExit(f'unsupported {kind}-install hook: {path}')
        if os.access(path, os.X_OK):
            hook_items.append({'kind': kind, 'path': str(path), 'sha256': digest(path), 'dkms': path.name.startswith('dkms-')})

if not doinst_will_invoke:
    state = 'legacy-setup-skip'
    transition = 'preserve-direct-no-initrd'
    effective_generator = 'not-invoked'
elif values['AUTOGENERATE_INITRD'] == 'false':
    state = 'disabled-by-policy'
    transition = 'preserve-direct-no-initrd'
    effective_generator = 'disabled'
else:
    state = 'enabled'
    transition = 'direct-to-generated-initrd'
    effective_generator = values['GENERATOR']
    if effective_generator == 'mkinitrd' and not mkinitrd_conf.exists():
        effective_generator = 'mkinitrd_command_generator.sh'
    generator_paths = {
        'mkinitrd': '/sbin/mkinitrd',
        'mkinitrd_command_generator.sh': '/usr/share/mkinitrd/mkinitrd_command_generator.sh',
        'dracut': '/usr/bin/dracut',
    }
    generator_path = rooted(generator_paths[effective_generator])
    if generator_path.is_symlink() or not generator_path.is_file() or not os.access(generator_path, os.X_OK):
        raise SystemExit(f'effective generator is unavailable or unsafe: {generator_paths[effective_generator]}')

result = {
    'config_state': config_state,
    'geninitrd_sha256': digest(geninitrd),
    'setup_sha256': digest(setup),
    'doinst_will_invoke_geninitrd': doinst_will_invoke,
    'policy_state': state,
    'autogenerate_initrd': values['AUTOGENERATE_INITRD'],
    'configured_generator': values['GENERATOR'],
    'effective_generator': effective_generator,
    'auto_update_grub': values['AUTO_UPDATE_GRUB'],
    'auto_remove_orphaned_initrds': values['AUTO_REMOVE_ORPHANED_INITRDS'],
    'auto_remove_initrd_tree': values['AUTO_REMOVE_INITRD_TREE'],
    'named_symlink': values['GENINITRD_NAMED_SYMLINK'],
    'initrd_gz_symlink': values['GENINITRD_INITRD_GZ_SYMLINK'],
    'expected_initrd': f'/boot/initrd-{target}.img' if state == 'enabled' else '',
    'transition_mode': transition,
    'custom_scripts': custom_scripts,
    'executable_hooks': hook_items,
    'custom_review_required': bool(custom_scripts or hook_items),
    'apply_ready': False,
    'apply_authorized': False,
}
out.write_text(json.dumps(result, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-geninitrd-policy-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
doinst_will_invoke_geninitrd=$DOINST_WILL_INVOKE
policy_state=$POLICY_STATE
autogenerate_initrd=$AUTOGENERATE_INITRD
effective_generator=$EFFECTIVE_GENERATOR
auto_update_grub=$AUTO_UPDATE_GRUB
transition_mode=$TRANSITION_MODE
custom_review_required=$CUSTOM_REVIEW_REQUIRED
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-geninitrd-policy-preflight-${timestamp}.tar.gz"
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
    local timestamp policy_json
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in python3 sha256sum tar find bash; do
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
        && record_pass 'the accepted candidate, boot-layout, and exact-package records match this policy inspection' \
        || record_failure 'the accepted records do not match this policy inspection'
    [ "$RUNNING_KERNEL" != "$TARGET_KERNEL" ] && is_safe_kernel_version "$RUNNING_KERNEL" \
        && record_pass "the running kernel $RUNNING_KERNEL remains the reviewed predecessor of $TARGET_KERNEL" \
        || record_failure 'the running and target kernel relationship is unsafe'
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the package database and boot-sensitive policy state were captured before inspection' \
        || record_failure 'the initial package or boot-sensitive state could not be captured'
    inventory_hooks /etc/geninitrd.d/pre-install /etc/geninitrd.d/post-install "$OUTPUT_DIR/hooks.txt" \
        && record_pass 'geninitrd pre-install and post-install hooks were inventoried without following links' \
        || record_failure 'geninitrd hook inventory contains an unsafe path'

    policy_json=$OUTPUT_DIR/geninitrd-policy.json
    if analyze_geninitrd_policy \
        /etc/default/geninitrd \
        /usr/sbin/geninitrd \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        /etc/mkinitrd.conf \
        /etc/geninitrd.d/pre-install \
        /etc/geninitrd.d/post-install \
        / \
        "$TARGET_KERNEL" \
        "$policy_json"; then
        DOINST_WILL_INVOKE=$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["doinst_will_invoke_geninitrd"]).lower())' "$policy_json")
        POLICY_STATE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["policy_state"])' "$policy_json")
        AUTOGENERATE_INITRD=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["autogenerate_initrd"])' "$policy_json")
        EFFECTIVE_GENERATOR=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["effective_generator"])' "$policy_json")
        AUTO_UPDATE_GRUB=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["auto_update_grub"])' "$policy_json")
        TRANSITION_MODE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["transition_mode"])' "$policy_json")
        CUSTOM_REVIEW_REQUIRED=$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["custom_review_required"]).lower())' "$policy_json")
        record_pass 'the installed geninitrd and setup scripts match the reviewed conditional control flow'
        record_pass "the effective host policy was parsed safely as $POLICY_STATE with generator $EFFECTIVE_GENERATOR"
        record_pass "the predicted boot transition is $TRANSITION_MODE and automatic GRUB update is $AUTO_UPDATE_GRUB"
    else
        record_failure 'the installed geninitrd policy is unsafe, unsupported, or incomplete'
    fi

    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the package database and boot-sensitive policy state were captured after inspection' \
        || record_failure 'the final package or boot-sensitive state could not be captured'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during the policy preflight' \
        || record_failure 'the installed package database changed during the policy preflight'
    cmp -s "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the active boot and geninitrd policy state remained unchanged during the preflight' \
        || record_failure 'the active boot or geninitrd policy state changed during the preflight'

    APPLY_READY=false
    APPLY_AUTHORIZED=false
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current geninitrd policy result: running=%s, target=%s, policy=%s, generator=%s, transition=%s, auto-update-grub=%s, apply-ready=false, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$POLICY_STATE" "$EFFECTIVE_GENERATOR" "$TRANSITION_MODE" "$AUTO_UPDATE_GRUB"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
