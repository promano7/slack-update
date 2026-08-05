#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_PAYLOAD_REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-payload-review-preflight.sh"
DEFAULT_PAYLOAD_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-20260805-accepted.json"
DEFAULT_MAINTAINER_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-policy.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-userspace-maintainer-script-review-preflight

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
PAYLOAD_REVIEW_SCRIPT=$DEFAULT_PAYLOAD_REVIEW_SCRIPT
PAYLOAD_RECORD=$DEFAULT_PAYLOAD_RECORD
MAINTAINER_POLICY=$DEFAULT_MAINTAINER_POLICY
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
EXPECTED_SCRIPT_COUNT=0
CLASSIFIED_SCRIPT_COUNT=0
RELATIVE_REMOVE_COUNT=0
RELATIVE_SYMLINK_COUNT=0
CONFIG_INSTALL_COUNT=0
CACHE_REFRESH_COUNT=0
PROCESS_SIGNAL_COUNT=0
MAINTAINER_SCRIPTS_REVIEW_COMPLETE=false
NEXT_STAGE=manual-review-required

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Review the exact captured Slackware-current install/doinst.sh scripts without
executing them. The preflight reruns the accepted payload inspection, verifies
all script identities, and classifies every command and path effect. It never
installs packages, runs a maintainer script, generates an initrd, invokes DKMS,
or changes GRUB.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --payload-review-script PATH
      --payload-record PATH
      --maintainer-policy PATH
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
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --payload-review-script) [ "$#" -ge 2 ] || return 1; PAYLOAD_REVIEW_SCRIPT=$2; shift 2 ;;
            --payload-record) [ "$#" -ge 2 ] || return 1; PAYLOAD_RECORD=$2; shift 2 ;;
            --maintainer-policy) [ "$#" -ge 2 ] || return 1; MAINTAINER_POLICY=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    local path
    for path in "$PAYLOAD_REVIEW_SCRIPT" "$PAYLOAD_RECORD" "$MAINTAINER_POLICY" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

capture_package_database() {
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
        /boot/vmlinuz-generic "/boot/vmlinuz-$(uname -r)" \
        /boot/initrd-generic.img "/boot/initrd-$(uname -r).img" \
        /boot/initrd.gz /boot/grub/grub.cfg /etc/default/geninitrd \
        /etc/mkinitrd.conf /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia \
        /var/lib/dkms; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

validate_accepted_records() {
    python3 - "$PAYLOAD_RECORD" "$MAINTAINER_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, re, sys
record_path, policy_path, confirmed_digest, confirmed_target = sys.argv[1:]
try:
    record = json.load(open(record_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)

def digest(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None

def denied(value):
    return value.get('apply_ready') is False and value.get('apply_authorized') is False

scripts = policy.get('maintainer_scripts', [])
manifest = ''.join(f"{item.get('package')}\t{item.get('script_sha256')}\n" for item in sorted(scripts, key=lambda item: item.get('package', ''))).encode()
checks = [
    record.get('scenario') == 'current-userspace-payload-review-preflight',
    record.get('target') == 'slackware-current', record.get('accepted') is True, denied(record),
    digest(record.get('archive_sha256')), digest(record.get('nested_normal_update_archive_sha256')),
    record.get('candidate_set_sha256') == confirmed_digest,
    record.get('target_kernel') == confirmed_target,
    record.get('expected_package_count') == record.get('inspected_package_count') == 68,
    record.get('doinst_script_count') == 37,
    record.get('package_payloads_inspected') is True,
    record.get('payload_path_review_complete') is True,
    record.get('maintainer_scripts_review_complete') is False,
    record.get('userspace_apply_review_complete') is False,
    record.get('package_transaction_executed') is False,
    record.get('maintainer_script_executed') is False,
    record.get('package_database_unchanged') is True,
    record.get('payload_sensitive_state_unchanged') is True,
    record.get('assertions') == {'passes': 16, 'failures': 0},
    record.get('evidence', {}).get('copied_to') == '/home/promano',
    record.get('evidence', {}).get('destination_verification') == 'passed',
    record.get('next_stage') == 'current-userspace-maintainer-script-review-preflight',
    policy.get('scenario') == 'current-userspace-maintainer-script-review-policy',
    policy.get('target') == 'slackware-current', policy.get('reviewed') is True, denied(policy),
    policy.get('candidate_set_sha256') == confirmed_digest,
    policy.get('target_kernel') == confirmed_target,
    policy.get('accepted_payload_archive_sha256') == record.get('archive_sha256'),
    policy.get('expected_package_count') == 68,
    policy.get('expected_doinst_script_count') == len(scripts) == 37,
    policy.get('doinst_manifest_sha256') == record.get('doinst_manifest_sha256'),
    hashlib.sha256(manifest).hexdigest() == policy.get('doinst_manifest_sha256'),
    len({item.get('package') for item in scripts}) == 37,
    all(digest(item.get('script_sha256')) for item in scripts),
    policy.get('expected_action_totals') == {
        'cache_refresh': 5, 'config_install': 2, 'process_signal': 1,
        'relative_remove': 1159, 'relative_symlink': 1159,
    },
    policy.get('allowed_process_signal', {}).get('package') == 'kscreenlocker-6.7.4-x86_64-1.txz',
    policy.get('allowed_process_signal', {}).get('script_sha256') == 'c63222aa5084b2d550136c098bd71b12ced7612a59af3ac75c37c5eabbad9507',
    policy.get('allowed_process_signal', {}).get('command') == 'killall -TERM kscreenlocker_greet 1>/dev/null 2>/dev/null',
    policy.get('allowed_process_signal', {}).get('signal') == 'TERM',
    policy.get('allowed_process_signal', {}).get('process') == 'kscreenlocker_greet',
    policy.get('allowed_process_signal', {}).get('reviewed_effect') == 'restart the lock-screen greeter after kcheckpass replacement',
    policy.get('allowed_process_signal', {}).get('persistent_state_change') is False,
    policy.get('allowed_absolute_symlink_targets') == [
        '/usr/bin/plasma-apply-lookandfeel', '/usr/bin/systemsettings', '/usr/libexec/kf6/kdesu',
        '/usr/share/applications/org.kde.spectacle.desktop', '/usr/share/applications/systemsettings.desktop',
    ],
    policy.get('relative_write_prefixes') == ['usr/'],
    policy.get('require_exact_script_hashes') is True,
    policy.get('require_complete_command_classification') is True,
    policy.get('require_remove_symlink_pairing') is True,
    policy.get('require_nonexecuting_review') is True,
    policy.get('review_scope') == 'exact-doinst-static-command-and-effect-classification',
    policy.get('package_payloads_inspected') is True,
    policy.get('payload_path_review_complete') is True,
    policy.get('maintainer_scripts_review_complete') is False,
    policy.get('userspace_apply_review_complete') is False,
    policy.get('next_stage') == 'current-userspace-configuration-service-review-preflight',
]
if not all(checks):
    raise SystemExit(1)
print(len(scripts))
PY
}

validate_nested_payload() {
    local directory=$1
    python3 - "$directory" "$MAINTAINER_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, sys
root = pathlib.Path(sys.argv[1])
policy = json.load(open(sys.argv[2], encoding='utf-8'))
expected_digest, expected_target = sys.argv[3:]
try:
    summary = dict(line.rstrip('\n').split('=', 1) for line in open(root/'summary.txt', encoding='utf-8') if '=' in line)
    payload = json.load(open(root/'package-payload-summary.json', encoding='utf-8'))
except Exception:
    raise SystemExit(1)
expected = {item['package']: item for item in policy['maintainer_scripts']}
scripts = {}
for path in sorted((root/'doinst').glob('*.sh')):
    if not path.is_file() or path.is_symlink() or not path.name.endswith('.txz.sh'):
        raise SystemExit(1)
    package = path.name[:-3]
    scripts[package] = hashlib.sha256(path.read_bytes()).hexdigest()
checks = [
    summary.get('scenario') == 'current-userspace-payload-review-preflight',
    summary.get('result') == 'PASS', summary.get('target') == 'slackware-current',
    summary.get('candidate_set_sha256') == expected_digest,
    summary.get('target_kernel') == expected_target,
    int(summary.get('expected_package_count', '-1')) == 68,
    int(summary.get('inspected_package_count', '-1')) == 68,
    int(summary.get('doinst_script_count', '-1')) == 37,
    int(summary.get('config_path_count', '-1')) == 46,
    int(summary.get('service_path_count', '-1')) == 44,
    int(summary.get('elf_file_count', '-1')) == 722,
    int(summary.get('boot_theme_path_count', '-1')) == 24,
    summary.get('package_payloads_inspected') == 'true',
    summary.get('payload_path_review_complete') == 'true',
    summary.get('maintainer_scripts_review_complete') == 'false',
    summary.get('package_transaction_executed') == 'false',
    summary.get('maintainer_script_executed') == 'false',
    summary.get('next_stage') == 'current-userspace-maintainer-script-review-preflight',
    summary.get('apply_ready') == 'false', summary.get('apply_authorized') == 'false',
    int(summary.get('passes', '-1')) == 16, int(summary.get('failures', '-1')) == 0,
    payload.get('scenario') == 'current-userspace-payload-review-preflight',
    payload.get('package_count') == 68,
    payload.get('totals', {}).get('doinst') == 37,
    payload.get('payload_path_review_complete') is True,
    payload.get('maintainer_scripts_review_complete') is False,
    payload.get('next_stage') == 'current-userspace-maintainer-script-review-preflight',
    scripts == {name: item['script_sha256'] for name, item in expected.items()},
]
if not all(checks):
    raise SystemExit(1)
PY
}

create_and_verify_nested_archive() {
    local nested_root=$1 directory=$2 archive sidecar
    archive=$nested_root/payload-review.tar.gz
    sidecar=$archive.sha256
    tar -C "$nested_root" -czf "$archive" "$(basename -- "$directory")" || return 1
    (cd "$nested_root" && sha256sum -- "${archive##*/}" > "${sidecar##*/}") || return 1
    (cd "$nested_root" && sha256sum -c "${sidecar##*/}" >/dev/null) || return 1
}

validate_script_syntax() {
    local directory=$1 script
    [ -d "$directory" ] || return 1
    while IFS= read -r -d '' script; do
        sh -n "$script" || return 1
    done < <(find "$directory" -maxdepth 1 -type f -name '*.sh' -print0 | LC_ALL=C sort -z)
}

analyze_maintainer_scripts() {
    local directory=$1 inventory=$2 summary=$3
    python3 - "$directory" "$MAINTAINER_POLICY" "$inventory" "$summary" <<'PY'
import collections, hashlib, json, pathlib, posixpath, re, sys
script_dir = pathlib.Path(sys.argv[1])
policy = json.load(open(sys.argv[2], encoding='utf-8'))
inventory_path = pathlib.Path(sys.argv[3])
summary_path = pathlib.Path(sys.argv[4])

expected_list = policy.get('maintainer_scripts', [])
expected = {item['package']: item for item in expected_list}
if len(expected) != len(expected_list):
    raise SystemExit('duplicate package in maintainer policy')
actual_paths = sorted(script_dir.glob('*.sh'))
actual_packages = [path.name[:-3] for path in actual_paths if path.name.endswith('.txz.sh')]
if len(actual_paths) != len(actual_packages) or set(actual_packages) != set(expected):
    raise SystemExit('maintainer script set does not match policy')

allowed_configs = {(item['package'], item['path']) for item in policy.get('allowed_config_installs', [])}
allowed_caches = {(item['package'], item['command']) for item in policy.get('allowed_cache_refreshes', [])}
allowed_signal = policy.get('allowed_process_signal', {})
allowed_absolute_targets = set(policy.get('allowed_absolute_symlink_targets', []))
write_prefixes = tuple(policy.get('relative_write_prefixes', []))
if not write_prefixes:
    raise SystemExit('missing relative write prefixes')

rm_pattern = re.compile(r'^\( cd ([A-Za-z0-9_./+:-]+) ; rm -rf ([A-Za-z0-9_./+:-]+) \)$')
ln_pattern = re.compile(r'^\( cd ([A-Za-z0-9_./+:-]+) ; ln -sf ([A-Za-z0-9_./+:-]+) ([A-Za-z0-9_./+:-]+) \)$')
config_structural = {
    'config() {', 'NEW="$1"', 'OLD="$(dirname $NEW)/$(basename $NEW .new)"',
    'OLD="`dirname $NEW`/`basename $NEW .new`"', 'if [ ! -r $OLD ]; then',
    'mv $NEW $OLD', 'elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then',
    'elif [ "`cat $OLD | md5sum`" = "`cat $NEW | md5sum`" ]; then # toss the redundant copy',
    'rm $NEW', 'fi', '}',
}
guards = {
    'if [ -x /usr/bin/mkfontdir -o -x /usr/X11R6/bin/mkfontdir ]; then',
    'if [ -x /usr/bin/fc-cache ]; then',
    'if [ -x /usr/bin/update-desktop-database ]; then',
    'fi',
}

def safe_relative(value):
    if not value or value.startswith('/'):
        return None
    normalized = posixpath.normpath(value)
    if normalized in ('.', '..') or normalized.startswith('../'):
        return None
    return normalized

def write_allowed(value):
    return any(value.startswith(prefix) for prefix in write_prefixes)

rows = []
totals = collections.Counter()
script_results = []
manifest_rows = []
for path in actual_paths:
    if not path.is_file() or path.is_symlink():
        raise SystemExit(f'unsafe maintainer script file: {path.name}')
    content = path.read_bytes()
    if not content or len(content) > 262144 or b'\0' in content:
        raise SystemExit(f'unsafe maintainer script content: {path.name}')
    text = content.decode('utf-8')
    package = path.name[:-3]
    item = expected[package]
    digest = hashlib.sha256(content).hexdigest()
    if digest != item.get('script_sha256'):
        raise SystemExit(f'maintainer script digest changed: {package}')
    lines = text.splitlines()
    if len(lines) != item.get('line_count'):
        raise SystemExit(f'maintainer script line count changed: {package}')
    manifest_rows.append(f'{package}\t{digest}\n')
    counts = collections.Counter()
    pending_remove = None
    for number, raw in enumerate(lines, 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        match = rm_pattern.fullmatch(line)
        if match:
            if pending_remove is not None:
                raise SystemExit(f'unpaired remove before line {number} in {package}')
            directory, destination = match.groups()
            directory = safe_relative(directory)
            destination = safe_relative(destination)
            if directory is None or destination is None:
                raise SystemExit(f'unsafe relative remove at line {number} in {package}')
            write_path = safe_relative(posixpath.join(directory, destination))
            if write_path is None or not write_allowed(write_path):
                raise SystemExit(f'unreviewed remove path at line {number} in {package}: {write_path}')
            pending_remove = (directory, destination, write_path, number)
            counts['relative_remove'] += 1
            rows.append((package, number, 'relative_remove', write_path, destination))
            continue
        match = ln_pattern.fullmatch(line)
        if match:
            directory, target, destination = match.groups()
            directory = safe_relative(directory)
            destination = safe_relative(destination)
            if directory is None or destination is None:
                raise SystemExit(f'unsafe relative symlink at line {number} in {package}')
            write_path = safe_relative(posixpath.join(directory, destination))
            if write_path is None or not write_allowed(write_path):
                raise SystemExit(f'unreviewed symlink path at line {number} in {package}: {write_path}')
            if target.startswith('/'):
                if target not in allowed_absolute_targets:
                    raise SystemExit(f'unreviewed absolute symlink target at line {number} in {package}')
                resolved_target = target
            else:
                resolved_target = safe_relative(posixpath.join(directory, target))
                if resolved_target is None:
                    raise SystemExit(f'escaping symlink target at line {number} in {package}')
            if pending_remove is None or pending_remove[:2] != (directory, destination):
                raise SystemExit(f'symlink is not paired with its remove at line {number} in {package}')
            pending_remove = None
            counts['relative_symlink'] += 1
            rows.append((package, number, 'relative_symlink', write_path, resolved_target))
            continue
        if pending_remove is not None:
            raise SystemExit(f'remove is not immediately paired in {package}')
        if line.startswith('config '):
            config_path = line.split(None, 1)[1]
            if (package, config_path) not in allowed_configs or safe_relative(config_path) is None or not config_path.endswith('.new'):
                raise SystemExit(f'unreviewed config install at line {number} in {package}')
            counts['config_install'] += 1
            rows.append((package, number, 'config_install', config_path, 'preserve-existing-or-promote-new'))
            continue
        if line in config_structural:
            continue
        if (package, line) in allowed_caches:
            counts['cache_refresh'] += 1
            rows.append((package, number, 'cache_refresh', '-', line))
            continue
        if line in guards:
            continue
        if line == allowed_signal.get('command'):
            if package != allowed_signal.get('package') or digest != allowed_signal.get('script_sha256'):
                raise SystemExit(f'unreviewed process signal at line {number} in {package}')
            counts['process_signal'] += 1
            rows.append((package, number, 'process_signal', allowed_signal.get('process', '-'), allowed_signal.get('signal', '-')))
            continue
        raise SystemExit(f'unclassified command at line {number} in {package}: {line}')
    if pending_remove is not None:
        raise SystemExit(f'unpaired final remove in {package}')
    if dict(sorted(counts.items())) != item.get('actions', {}):
        raise SystemExit(f'action counts changed in {package}')
    totals.update(counts)
    script_results.append({'package': package, 'script_sha256': digest, 'line_count': len(lines), 'actions': dict(sorted(counts.items()))})

manifest = ''.join(sorted(manifest_rows)).encode()
if hashlib.sha256(manifest).hexdigest() != policy.get('doinst_manifest_sha256'):
    raise SystemExit('maintainer script manifest digest changed')
if dict(sorted(totals.items())) != policy.get('expected_action_totals'):
    raise SystemExit('maintainer action totals changed')
if totals.get('process_signal', 0) != 1:
    raise SystemExit('the exact reviewed process signal is not unique')

inventory_path.write_text('package\tline\taction\tpath_or_process\tdetail\n' + ''.join(
    f'{package}\t{line}\t{action}\t{path}\t{detail}\n'
    for package, line, action, path, detail in rows
), encoding='utf-8')
summary_path.write_text(json.dumps({
    'scenario': 'current-userspace-maintainer-script-review-preflight',
    'script_count': len(script_results),
    'scripts': script_results,
    'action_totals': dict(sorted(totals.items())),
    'exact_script_hashes_verified': True,
    'complete_command_classification': True,
    'remove_symlink_pairing_verified': True,
    'process_signal_confined_to_reviewed_exception': True,
    'maintainer_scripts_executed': False,
    'maintainer_scripts_review_complete': True,
    'userspace_apply_review_complete': False,
    'next_stage': 'current-userspace-configuration-service-review-preflight',
    'apply_ready': False,
    'apply_authorized': False,
}, indent=2, sort_keys=True) + '\n', encoding='utf-8')
print(len(script_results))
for key in ('relative_remove', 'relative_symlink', 'config_install', 'cache_refresh', 'process_signal'):
    print(totals.get(key, 0))
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-userspace-maintainer-script-review-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
target_kernel=$CONFIRM_TARGET_KERNEL
expected_doinst_script_count=$EXPECTED_SCRIPT_COUNT
classified_doinst_script_count=$CLASSIFIED_SCRIPT_COUNT
relative_remove_count=$RELATIVE_REMOVE_COUNT
relative_symlink_count=$RELATIVE_SYMLINK_COUNT
config_install_count=$CONFIG_INSTALL_COUNT
cache_refresh_count=$CACHE_REFRESH_COUNT
process_signal_count=$PROCESS_SIGNAL_COUNT
package_payloads_inspected=true
payload_path_review_complete=true
maintainer_scripts_review_complete=$MAINTAINER_SCRIPTS_REVIEW_COMPLETE
userspace_apply_review_complete=false
package_transaction_executed=false
maintainer_script_executed=false
mkinitrd_executed=false
geninitrd_executed=false
dkms_action_executed=false
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
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-userspace-maintainer-script-review-preflight-${timestamp}.tar.gz"
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
    local timestamp nested_root nested_dir nested_exit=0 values
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this acceptance preflight must run as root'; return 2; }
    local tool
    for tool in bash python3 sha256sum find sort tar stat sh cmp; do
        command -v "$tool" >/dev/null 2>&1 || { error "required command is missing: $tool"; return 2; }
    done
    bash -n "$PAYLOAD_REVIEW_SCRIPT" || { error 'payload-review script has invalid syntax'; return 2; }
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    mkdir -p "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if values=$(validate_accepted_records); then
        EXPECTED_SCRIPT_COUNT=$(printf '%s\n' "$values" | tail -n 1)
        record_pass 'the accepted payload review and maintainer policy bind the exact 37-script inspection'
    else
        record_failure 'the accepted payload review or maintainer policy is unsafe or inconsistent'
    fi
    [ "$CONFIRM_CANDIDATES_SHA256" = 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 ] \
        && [ "$CONFIRM_TARGET_KERNEL" = 6.18.42 ] \
        && record_pass 'the explicit candidate digest and target kernel match the reviewed maintainer-script boundary' \
        || record_failure 'the explicit candidate digest or target kernel does not match the reviewed maintainer-script boundary'
    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and maintainer-sensitive state were captured before static review'
    else
        record_failure 'the initial package or maintainer-sensitive state could not be captured safely'
    fi

    nested_root=$OUTPUT_DIR/nested
    nested_dir=$nested_root/payload-review
    mkdir -p "$nested_root"
    printf 'Running a fresh non-installing userspace payload review before maintainer-script classification...\n'
    bash "$PAYLOAD_REVIEW_SCRIPT" \
        --target slackware-current \
        --confirm-candidates-sha256 "$CONFIRM_CANDIDATES_SHA256" \
        --confirm-target-kernel "$CONFIRM_TARGET_KERNEL" \
        --output-dir "$nested_dir" \
        > "$OUTPUT_DIR/payload-review.stdout.log" 2> "$OUTPUT_DIR/payload-review.stderr.log" || nested_exit=$?
    printf '%s\n' "$nested_exit" > "$OUTPUT_DIR/payload-review.exit"
    cat "$OUTPUT_DIR/payload-review.stdout.log"
    [ -s "$OUTPUT_DIR/payload-review.stderr.log" ] && cat "$OUTPUT_DIR/payload-review.stderr.log" >&2 || true
    [ "$nested_exit" -eq 0 ] \
        && record_pass 'the embedded payload review completed without installing packages or executing maintainer scripts' \
        || record_failure "the embedded payload review failed with exit code $nested_exit"
    [ "$nested_exit" -eq 0 ] && validate_nested_payload "$nested_dir" \
        && record_pass 'the fresh payload evidence still contains the exact accepted 68 packages and 37 scripts' \
        || record_failure 'the payload or maintainer-script identities changed before static review'
    [ "$nested_exit" -eq 0 ] && create_and_verify_nested_archive "$nested_root" "$nested_dir" \
        && record_pass 'the nested payload-review archive and portable sidecar verify inside the maintainer evidence' \
        || record_failure 'the nested payload-review archive or portable sidecar is invalid'

    validate_script_syntax "$nested_dir/doinst" \
        && record_pass 'all 37 captured maintainer scripts remain syntax-valid and unexecuted' \
        || record_failure 'a captured maintainer script is missing, ambiguous, or syntax-invalid'
    if values=$(analyze_maintainer_scripts "$nested_dir/doinst" "$OUTPUT_DIR/maintainer-script-inventory.tsv" "$OUTPUT_DIR/maintainer-script-summary.json"); then
        CLASSIFIED_SCRIPT_COUNT=$(printf '%s\n' "$values" | sed -n '1p')
        RELATIVE_REMOVE_COUNT=$(printf '%s\n' "$values" | sed -n '2p')
        RELATIVE_SYMLINK_COUNT=$(printf '%s\n' "$values" | sed -n '3p')
        CONFIG_INSTALL_COUNT=$(printf '%s\n' "$values" | sed -n '4p')
        CACHE_REFRESH_COUNT=$(printf '%s\n' "$values" | sed -n '5p')
        PROCESS_SIGNAL_COUNT=$(printf '%s\n' "$values" | sed -n '6p')
        record_pass 'every command is classified under exact script hashes and safe relative write boundaries'
        record_pass 'all remove operations are paired with the reviewed symlink replacements'
        record_pass 'configuration promotion and cache refresh commands are confined to the reviewed package-path pairs'
        record_pass 'the sole process signal is confined to the exact kscreenlocker script and greeter restart command'
    else
        record_failure 'one or more maintainer scripts contain changed, unsafe, or unclassified effects'
    fi
    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$CLASSIFIED_SCRIPT_COUNT" -eq "$EXPECTED_SCRIPT_COUNT" ]; then
        MAINTAINER_SCRIPTS_REVIEW_COMPLETE=true
        NEXT_STAGE=current-userspace-configuration-service-review-preflight
        record_pass 'the maintainer-script review is complete while configuration, service, and userspace apply review remain pending'
    else
        MAINTAINER_SCRIPTS_REVIEW_COMPLETE=false
        NEXT_STAGE=manual-review-required
        record_failure 'the maintainer-script boundary could not be completed safely'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and maintainer-sensitive state were captured after static review' \
        || record_failure 'the final package or maintainer-sensitive state could not be captured safely'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during maintainer-script review' \
        || record_failure 'the installed package database changed during maintainer-script review'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged during maintainer-script review' \
        || record_failure 'the maintainer-sensitive system state changed during review'

    [ "$FAILURE_COUNT" -eq 0 ] || { MAINTAINER_SCRIPTS_REVIEW_COMPLETE=false; NEXT_STAGE=manual-review-required; }
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current maintainer-script review result: candidates=%s, scripts=%s, removes=%s, symlinks=%s, config-installs=%s, cache-refreshes=%s, process-signals=%s, maintainer-scripts-review-complete=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "$CONFIRM_CANDIDATES_SHA256" "$CLASSIFIED_SCRIPT_COUNT" "$RELATIVE_REMOVE_COUNT" "$RELATIVE_SYMLINK_COUNT" "$CONFIG_INSTALL_COUNT" "$CACHE_REFRESH_COUNT" "$PROCESS_SIGNAL_COUNT" "$MAINTAINER_SCRIPTS_REVIEW_COMPLETE" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
