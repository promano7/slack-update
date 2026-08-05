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
DEFAULT_BASELINE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
DEFAULT_USERSPACE_REVIEW="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-userspace-candidate-review-20260805-accepted.json"
DEFAULT_REBIND_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-evidence-rebind-20260805-accepted.json"
DEFAULT_PAYLOAD_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-policy.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-userspace-payload-review-preflight

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
NORMAL_UPDATE_SCRIPT=$DEFAULT_NORMAL_UPDATE_SCRIPT
BASELINE_PREFLIGHT=$DEFAULT_BASELINE_PREFLIGHT
USERSPACE_REVIEW=$DEFAULT_USERSPACE_REVIEW
REBIND_RECORD=$DEFAULT_REBIND_RECORD
PAYLOAD_POLICY=$DEFAULT_PAYLOAD_POLICY
OUTPUT_DIR=
PACKAGE_CACHE_ROOT=/var/cache/packages
SLACKPKG_PKGLIST=/var/lib/slackpkg/pkglist
SYSTEM_ROOT=/
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
EXPECTED_PACKAGE_COUNT=0
INSPECTED_PACKAGE_COUNT=0
DOINST_SCRIPT_COUNT=0
CONFIG_PATH_COUNT=0
SERVICE_PATH_COUNT=0
ELF_FILE_COUNT=0
BOOT_THEME_PATH_COUNT=0
NEXT_STAGE=manual-review-required
PAYLOAD_PATH_REVIEW_COMPLETE=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Download and inspect the exact 68 userspace package archives added to the
reviewed Slackware-current transaction. The preflight validates archive paths,
member types, link targets, package identity, and maintainer-script syntax. It
never installs packages or executes maintainer scripts, mkinitrd, GenInitrd,
DKMS, or GRUB.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-update-script PATH
      --baseline-preflight PATH
      --userspace-review PATH
      --rebind-record PATH
      --payload-policy PATH
      --package-cache-root PATH
      --slackpkg-pkglist PATH
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

root_path() {
    local path=$1
    if [ "$SYSTEM_ROOT" = / ]; then
        printf '%s\n' "$path"
    else
        printf '%s%s\n' "${SYSTEM_ROOT%/}" "$path"
    fi
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-candidates-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CANDIDATES_SHA256=$2; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --normal-update-script) [ "$#" -ge 2 ] || return 1; NORMAL_UPDATE_SCRIPT=$2; shift 2 ;;
            --baseline-preflight) [ "$#" -ge 2 ] || return 1; BASELINE_PREFLIGHT=$2; shift 2 ;;
            --userspace-review) [ "$#" -ge 2 ] || return 1; USERSPACE_REVIEW=$2; shift 2 ;;
            --rebind-record) [ "$#" -ge 2 ] || return 1; REBIND_RECORD=$2; shift 2 ;;
            --payload-policy) [ "$#" -ge 2 ] || return 1; PAYLOAD_POLICY=$2; shift 2 ;;
            --package-cache-root) [ "$#" -ge 2 ] || return 1; PACKAGE_CACHE_ROOT=$2; shift 2 ;;
            --slackpkg-pkglist) [ "$#" -ge 2 ] || return 1; SLACKPKG_PKGLIST=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    local path
    for path in "$NORMAL_UPDATE_SCRIPT" "$BASELINE_PREFLIGHT" "$USERSPACE_REVIEW" "$REBIND_RECORD" "$PAYLOAD_POLICY" "$PACKAGE_CACHE_ROOT" "$SLACKPKG_PKGLIST" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
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
    local path=$1 actual
    actual=$(root_path "$path")
    if [ -L "$actual" ]; then
        printf 'symlink|%s|%s' "$(readlink -- "$actual" 2>/dev/null || true)" "$(readlink -e -- "$actual" 2>/dev/null || true)"
    elif [ -f "$actual" ]; then
        printf 'regular|%s|%s' "$(stat -c '%a:%u:%g:%s:%Y' -- "$actual")" "$(sha256sum -- "$actual" | awk '{print $1}')"
    elif [ -d "$actual" ]; then
        printf 'directory|%s|' "$(stat -c '%a:%u:%g:%Y' -- "$actual")"
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
    local expected_output=$1
    python3 - "$BASELINE_PREFLIGHT" "$USERSPACE_REVIEW" "$REBIND_RECORD" "$PAYLOAD_POLICY" \
        "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" "$expected_output" <<'PY'
import hashlib, json, pathlib, re, sys
baseline_path, review_path, rebind_path, policy_path, confirmed_digest, confirmed_target, output_path = sys.argv[1:]
try:
    baseline = json.load(open(baseline_path, encoding='utf-8'))
    review = json.load(open(review_path, encoding='utf-8'))
    rebind = json.load(open(rebind_path, encoding='utf-8'))
    policy = json.load(open(policy_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)

def digest(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None

def denied(record):
    return record.get('apply_ready') is False and record.get('apply_authorized') is False

categories = review.get('categories', {})
packages = sorted(categories.get('plasma_6_7_4', []) + categories.get('supporting_userspace', []) + categories.get('boot_adjacent_theme', []))
checks = [
    baseline.get('scenario') == 'normal-update', baseline.get('accepted') is True, denied(baseline),
    review.get('scenario') == 'current-userspace-candidate-review-preflight', review.get('accepted') is True, denied(review),
    digest(review.get('archive_sha256')), digest(review.get('nested_normal_update_archive_sha256')),
    review.get('evidence', {}).get('copied_to') == '/home/promano', review.get('evidence', {}).get('destination_verification') == 'passed',
    review.get('fresh_candidate_set_sha256') == confirmed_digest, review.get('target_kernel') == confirmed_target,
    review.get('added_candidate_count') == len(packages) == 68, len(packages) == len(set(packages)),
    rebind.get('scenario') == 'current-kernel-evidence-rebind-preflight', rebind.get('accepted') is True, denied(rebind),
    digest(rebind.get('archive_sha256')), digest(rebind.get('nested_normal_update_archive_sha256')),
    rebind.get('rebound_candidate_set_sha256') == confirmed_digest, rebind.get('fresh_candidate_set_sha256') == confirmed_digest,
    rebind.get('target_kernel') == confirmed_target, rebind.get('kernel_evidence_rebound') is True,
    rebind.get('candidate_binding_change_only') is True, rebind.get('userspace_payload_review_required') is True,
    rebind.get('package_payloads_inspected') is False, rebind.get('userspace_apply_review_complete') is False,
    rebind.get('next_stage') == 'current-userspace-payload-review-preflight',
    rebind.get('evidence', {}).get('copied_to') == '/home/promano', rebind.get('evidence', {}).get('destination_verification') == 'passed',
    policy.get('scenario') == 'current-userspace-payload-review-policy', policy.get('reviewed') is True, denied(policy),
    policy.get('candidate_set_sha256') == confirmed_digest, policy.get('target_kernel') == confirmed_target,
    policy.get('expected_package_count') == 68, policy.get('review_scope') == 'archive-path-and-metadata-safety',
    policy.get('boot_adjacent_package') == 'breeze-grub-6.7.4-x86_64-1.txz',
    policy.get('boot_adjacent_package_sha256') == '66209816c42b2363f7a2ca7d1a739dc393c101c752709e7291f1f97b6466008a',
    policy.get('boot_adjacent_package_size') == 1448432,
    policy.get('allowed_boot_adjacent_prefix') == 'boot/grub/themes/breeze/',
    policy.get('next_stage') == 'current-userspace-maintainer-script-review-preflight',
]
if not all(checks):
    raise SystemExit(1)
pattern = re.compile(r'[A-Za-z0-9][A-Za-z0-9+._-]*\.t(?:xz|gz|lz|bz)$')
if any(pattern.fullmatch(item) is None for item in packages):
    raise SystemExit(1)
pathlib.Path(output_path).write_text(''.join(item + '\n' for item in packages), encoding='utf-8')
print(len(packages))
PY
}

validate_nested_candidates() {
    local directory=$1
    python3 - "$BASELINE_PREFLIGHT" "$USERSPACE_REVIEW" "$directory" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, pathlib, re, sys
baseline_path, review_path, directory, expected_digest, target = sys.argv[1:]
root = pathlib.Path(directory)
try:
    baseline = json.load(open(baseline_path, encoding='utf-8'))
    review = json.load(open(review_path, encoding='utf-8'))
    summary = dict(line.rstrip('\n').split('=', 1) for line in open(root/'summary.txt', encoding='utf-8') if '=' in line)
except Exception:
    raise SystemExit(1)

def rows(name):
    path = root/name
    if not path.is_file() or path.is_symlink():
        raise SystemExit(1)
    values = [line.strip() for line in path.read_text(encoding='utf-8').splitlines() if line.strip()]
    if values != sorted(set(values)):
        raise SystemExit(1)
    return values
base = baseline.get('candidates', {})
expected = sorted(base.get('install_new', []) + base.get('upgrade_all', []) + review.get('categories', {}).get('plasma_6_7_4', []) + review.get('categories', {}).get('supporting_userspace', []) + review.get('categories', {}).get('boot_adjacent_theme', []))
all_candidates = rows('all.candidates.txt')
install = rows('install-new.candidates.txt')
upgrade = rows('upgrade-all.candidates.txt')
critical = rows('critical.candidates.txt')
raw = ''.join(f'{item}\n' for item in all_candidates).encode()
checks = [
    summary.get('scenario') == 'normal-update', summary.get('mode') == 'preflight', summary.get('result') == 'PASS',
    summary.get('candidate_set_sha256') == expected_digest, hashlib.sha256(raw).hexdigest() == expected_digest,
    all_candidates == expected, len(all_candidates) == 137, install == base.get('install_new', []),
    set(review.get('categories', {}).get('plasma_6_7_4', []) + review.get('categories', {}).get('supporting_userspace', []) + review.get('categories', {}).get('boot_adjacent_theme', [])).issubset(set(upgrade)),
    critical == [], int(summary.get('critical_candidates', '-1')) == 0,
    [f'kernel-generic-{target}-x86_64-1.txz', f'kernel-headers-{target}-x86-1.txz', f'kernel-source-{target}-noarch-1.txz'] == review.get('kernel_transaction_candidates'),
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

resolve_repository_records() {
    local expected=$1 output=$2
    [ -f "$SLACKPKG_PKGLIST" ] && [ ! -L "$SLACKPKG_PKGLIST" ] && [ -r "$SLACKPKG_PKGLIST" ] || return 1
    python3 - "$SLACKPKG_PKGLIST" "$expected" "$output" <<'PY'
import pathlib, sys
pkglist = pathlib.Path(sys.argv[1])
expected = [x.strip() for x in pathlib.Path(sys.argv[2]).read_text(encoding='utf-8').splitlines() if x.strip()]
output = pathlib.Path(sys.argv[3])
records = {name: [] for name in expected}
for number, raw in enumerate(pkglist.read_text(encoding='utf-8', errors='replace').splitlines(), 1):
    fields = raw.split()
    if len(fields) < 5:
        continue
    repository, name, version, arch, build = fields[:5]
    stem = f'{name}-{version}-{arch}-{build}'
    filename = fields[5] if len(fields) >= 6 else stem
    if not filename.endswith('.txz'):
        filename += '.txz'
    if filename in records:
        records[filename].append((number, repository, name, stem, raw))
rows = []
for filename in expected:
    matches = records[filename]
    if len(matches) != 1:
        raise SystemExit(f'expected one repository record for {filename}, found {len(matches)}')
    number, repository, name, stem, raw = matches[0]
    rows.append(f'{filename}\t{name}\t{stem}\t{repository}\t{number}\n')
output.write_text(''.join(rows), encoding='utf-8')
PY
}

find_cached_exact() {
    local filename=$1
    python3 - "$PACKAGE_CACHE_ROOT" "$filename" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
filename = sys.argv[2]
try:
    resolved_root = root.resolve(strict=True)
except OSError:
    raise SystemExit(1)
matches=[]
for path in root.rglob(filename):
    try:
        if path.is_file() and not path.is_symlink():
            value=path.resolve(strict=True)
            if resolved_root in value.parents:
                matches.append(value)
    except OSError:
        pass
matches=sorted(set(matches))
if len(matches) != 1:
    raise SystemExit(1)
print(matches[0])
PY
}

download_reviewed_packages() {
    local records=$1 log_dir=$2 filename name stem repository number status path
    mkdir -p "$log_dir" || return 1
    while IFS=$'\t' read -r filename name stem repository number; do
        [ -n "$filename" ] || continue
        if path=$(find_cached_exact "$filename" 2>/dev/null); then
            printf 'cached\t%s\t%s\n' "$filename" "$path" >> "$log_dir/status.tsv"
            continue
        fi
        status=0
        LC_ALL=C LANG=C TERM=dumb slackpkg -dialog=off -batch=on -default_answer=y \
            download "$stem" > "$log_dir/$filename.log" 2>&1 || status=$?
        printf '%s\n' "$status" > "$log_dir/$filename.exit"
        [ "$status" -eq 0 ] || return 1
        path=$(find_cached_exact "$filename" 2>/dev/null) || return 1
        printf 'downloaded\t%s\t%s\n' "$filename" "$path" >> "$log_dir/status.tsv"
    done < "$records"
}

resolve_cached_manifest() {
    local expected=$1 output=$2 filename path
    : > "$output" || return 1
    while IFS= read -r filename; do
        [ -n "$filename" ] || continue
        path=$(find_cached_exact "$filename") || return 1
        printf '%s\t%s\t%s\t%s\n' "$filename" "$path" \
            "$(sha256sum -- "$path" | awk '{print $1}')" "$(stat -c '%s' -- "$path")" >> "$output" || return 1
    done < "$expected"
}

inspect_payload_archives() {
    local manifest=$1 output_root=$2
    python3 - "$manifest" "$PAYLOAD_POLICY" "$output_root" <<'PY'
import hashlib, json, pathlib, posixpath, stat, sys, tarfile
manifest_path, policy_path, output_root = map(pathlib.Path, sys.argv[1:])
policy = json.load(open(policy_path, encoding='utf-8'))
rows=[]
for raw in manifest_path.read_text(encoding='utf-8').splitlines():
    if raw.strip():
        fields=raw.split('\t')
        if len(fields) != 4:
            raise SystemExit('malformed cache manifest')
        rows.append(fields)
if len(rows) != policy['expected_package_count']:
    raise SystemExit('unexpected package count')
forbidden=tuple(policy['forbidden_payload_prefixes'])
boot_package=policy['boot_adjacent_package']
boot_package_sha=policy['boot_adjacent_package_sha256']
boot_package_size=policy['boot_adjacent_package_size']
boot_prefix=policy['allowed_boot_adjacent_prefix']
boot_root=boot_prefix.rstrip('/')
if not boot_prefix.endswith('/') or not boot_root or boot_root.startswith('/') or posixpath.normpath(boot_root) != boot_root:
    raise SystemExit('unsafe reviewed boot theme prefix')
boot_ancestors=set()
parent=posixpath.dirname(boot_root)
while parent and parent != '.':
    boot_ancestors.add(parent)
    parent=posixpath.dirname(parent)
inventory=[]
package_results=[]
doinst_dir=output_root/'doinst'
doinst_dir.mkdir(parents=True, exist_ok=True)
totals={'members':0,'regular':0,'directories':0,'symlinks':0,'hardlinks':0,'executables':0,'elf':0,'doinst':0,'config_paths':0,'service_paths':0,'boot_theme_paths':0}
for filename, raw_path, expected_sha, expected_size in rows:
    package=pathlib.Path(raw_path)
    if package.name != filename or not package.is_file() or package.is_symlink():
        raise SystemExit(f'unsafe package path: {filename}')
    hasher=hashlib.sha256()
    with package.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            hasher.update(block)
    actual_sha=hasher.hexdigest()
    actual_size=package.stat().st_size
    if actual_sha != expected_sha or actual_size != int(expected_size):
        raise SystemExit(f'package changed during inspection: {filename}')
    if filename == boot_package and (actual_sha != boot_package_sha or actual_size != boot_package_size):
        raise SystemExit('reviewed breeze-grub archive identity changed')
    counts={key:0 for key in totals}
    names=[]
    has_theme=False
    doinst_seen=0
    with tarfile.open(package, mode='r|*') as archive:
        for member in archive:
            name=member.name.removeprefix('./')
            normalized=posixpath.normpath(name)
            if normalized == '.' and member.isdir():
                continue
            if not name or name.startswith('/') or normalized in ('.','..') or normalized.startswith('../'):
                raise SystemExit(f'unsafe archive member in {filename}: {member.name!r}')
            if member.isdev() or member.isfifo():
                raise SystemExit(f'device or fifo member in {filename}: {normalized}')
            if member.issym() or member.islnk():
                link=member.linkname
                resolved=posixpath.normpath(posixpath.join(posixpath.dirname(normalized), link))
                if link.startswith('/') or resolved == '..' or resolved.startswith('../'):
                    raise SystemExit(f'escaping archive link in {filename}: {normalized}')
            if member.mode & (stat.S_ISUID | stat.S_ISGID):
                raise SystemExit(f'setuid or setgid payload in {filename}: {normalized}')
            names.append(normalized)
            kind='other'
            if member.isfile(): kind='regular'; counts['regular']+=1
            elif member.isdir(): kind='directory'; counts['directories']+=1
            elif member.issym(): kind='symlink'; counts['symlinks']+=1
            elif member.islnk(): kind='hardlink'; counts['hardlinks']+=1
            else: raise SystemExit(f'unsupported archive member in {filename}: {normalized}')
            if member.isfile() and member.mode & 0o111:
                counts['executables']+=1
            if member.isfile():
                stream=archive.extractfile(member)
                if stream is None:
                    raise SystemExit(f'unreadable archive member in {filename}: {normalized}')
                if normalized == 'install/doinst.sh':
                    doinst_seen += 1
                    content=stream.read(262145)
                    if doinst_seen > 1 or not content or len(content) > 262144 or b'\0' in content:
                        raise SystemExit(f'unsafe or ambiguous doinst.sh in {filename}')
                    content.decode('utf-8')
                    (doinst_dir/(filename+'.sh')).write_bytes(content)
                    counts['doinst']=1
                    magic=content[:4]
                else:
                    magic=stream.read(4)
                stream.close()
                if magic == b'\x7fELF': counts['elf']+=1
            if normalized.startswith('etc/'):
                counts['config_paths']+=1
            if normalized.startswith(('etc/rc.d/','usr/lib/systemd/','lib/systemd/','usr/lib64/systemd/')):
                counts['service_paths']+=1
            theme_member = normalized == boot_root or normalized.startswith(boot_prefix)
            theme_ancestor = normalized in boot_ancestors
            allowed_boot_adjacent_path = filename == boot_package and (theme_member or theme_ancestor)
            if normalized == 'usr/share/grub' or normalized.startswith('usr/share/grub/') \
                    or normalized == 'boot/grub' or normalized.startswith('boot/grub/'):
                if not allowed_boot_adjacent_path:
                    raise SystemExit(f'unreviewed GRUB payload in {filename}: {normalized}')
            if theme_member and filename == boot_package:
                counts['boot_theme_paths']+=1
                has_theme=True
            for prefix in forbidden:
                if normalized == prefix.rstrip('/') or normalized.startswith(prefix):
                    if allowed_boot_adjacent_path:
                        continue
                    raise SystemExit(f'forbidden payload path in {filename}: {normalized}')
            inventory.append(f'{filename}\t{normalized}\t{kind}\t{member.mode:o}\t{member.size}\t{member.linkname}\n')
        if len(names) != len(set(names)):
            raise SystemExit(f'duplicate archive members in {filename}')
    if filename == boot_package and not has_theme:
        raise SystemExit('breeze-grub does not contain the reviewed theme prefix')
    counts['members']=len(names)
    for key in totals: totals[key]+=counts[key]
    package_results.append({'filename':filename,'sha256':actual_sha,'size':int(expected_size),**counts})
(output_root/'payload-inventory.tsv').write_text(''.join(inventory), encoding='utf-8')
(output_root/'package-payload-summary.json').write_text(json.dumps({
    'scenario':'current-userspace-payload-review-preflight',
    'package_count':len(package_results),
    'packages':package_results,
    'totals':totals,
    'package_payloads_inspected':True,
    'payload_path_review_complete':True,
    'maintainer_scripts_review_complete':False,
    'userspace_apply_review_complete':False,
    'next_stage':'current-userspace-maintainer-script-review-preflight',
    'apply_ready':False,
    'apply_authorized':False,
}, indent=2, sort_keys=True)+'\n', encoding='utf-8')
print(len(package_results))
print(totals['doinst'])
print(totals['config_paths'])
print(totals['service_paths'])
print(totals['elf'])
print(totals['boot_theme_paths'])
PY
}

validate_doinst_syntax() {
    local directory=$1 script
    [ -d "$directory" ] || return 1
    while IFS= read -r -d '' script; do
        sh -n "$script" || return 1
    done < <(find "$directory" -maxdepth 1 -type f -name '*.sh' -print0 | LC_ALL=C sort -z)
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-userspace-payload-review-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
target_kernel=$CONFIRM_TARGET_KERNEL
expected_package_count=$EXPECTED_PACKAGE_COUNT
inspected_package_count=$INSPECTED_PACKAGE_COUNT
doinst_script_count=$DOINST_SCRIPT_COUNT
config_path_count=$CONFIG_PATH_COUNT
service_path_count=$SERVICE_PATH_COUNT
elf_file_count=$ELF_FILE_COUNT
boot_theme_path_count=$BOOT_THEME_PATH_COUNT
package_payloads_inspected=$PAYLOAD_PATH_REVIEW_COMPLETE
payload_path_review_complete=$PAYLOAD_PATH_REVIEW_COMPLETE
maintainer_scripts_review_complete=false
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
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-userspace-payload-review-preflight-${timestamp}.tar.gz"
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
    for tool in bash python3 sha256sum find sort tar stat slackpkg sh; do
        command -v "$tool" >/dev/null 2>&1 || { error "required command is missing: $tool"; return 2; }
    done
    bash -n "$NORMAL_UPDATE_SCRIPT" || { error 'normal-update script has invalid syntax'; return 2; }
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    mkdir -p "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if values=$(validate_accepted_records "$OUTPUT_DIR/expected-packages.txt"); then
        EXPECTED_PACKAGE_COUNT=$(printf '%s\n' "$values" | tail -n 1)
        record_pass 'the accepted userspace review, kernel rebind, and payload policy bind the exact 68-package inspection'
    else
        record_failure 'the accepted userspace review, kernel rebind, or payload policy is unsafe or inconsistent'
    fi
    [ "$CONFIRM_CANDIDATES_SHA256" = 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 ] \
        && [ "$CONFIRM_TARGET_KERNEL" = 6.18.42 ] \
        && record_pass 'the explicit candidate digest and target kernel match the reviewed payload boundary' \
        || record_failure 'the explicit candidate digest or target kernel does not match the reviewed payload boundary'
    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and payload-sensitive state were captured before archive review'
    else
        record_failure 'the initial package or payload-sensitive state could not be captured safely'
    fi

    nested_root=$OUTPUT_DIR/nested
    nested_dir=$nested_root/normal-update
    mkdir -p "$nested_root"
    printf 'Running a fresh non-installing normal-update preflight before payload download...\n'
    bash "$NORMAL_UPDATE_SCRIPT" --target slackware-current --preflight --output-dir "$nested_dir" \
        > "$OUTPUT_DIR/normal-update.stdout.log" 2> "$OUTPUT_DIR/normal-update.stderr.log" || nested_exit=$?
    printf '%s\n' "$nested_exit" > "$OUTPUT_DIR/normal-update.exit"
    cat "$OUTPUT_DIR/normal-update.stdout.log"
    [ -s "$OUTPUT_DIR/normal-update.stderr.log" ] && cat "$OUTPUT_DIR/normal-update.stderr.log" >&2 || true
    [ "$nested_exit" -eq 0 ] \
        && record_pass 'the embedded normal-update preflight completed without authorizing package installation' \
        || record_failure "the embedded normal-update preflight failed with exit code $nested_exit"
    [ "$nested_exit" -eq 0 ] && validate_nested_candidates "$nested_dir" \
        && record_pass 'the fresh candidate set still matches the reviewed 137-package transaction' \
        || record_failure 'the fresh candidate set changed before payload inspection'
    verify_nested_archive "$nested_root" \
        && record_pass 'the nested normal-update archive and portable sidecar verify inside the payload evidence' \
        || record_failure 'the nested normal-update archive or portable sidecar is invalid'

    resolve_repository_records "$OUTPUT_DIR/expected-packages.txt" "$OUTPUT_DIR/repository-packages.tsv" \
        && record_pass 'the repository exposes exactly one record for each of the 68 reviewed packages' \
        || record_failure 'the repository package identities are missing, ambiguous, or changed'
    printf 'Downloading missing reviewed userspace packages without installing them...\n'
    download_reviewed_packages "$OUTPUT_DIR/repository-packages.tsv" "$OUTPUT_DIR/download-logs" \
        && record_pass 'all missing reviewed userspace packages were downloaded without installation' \
        || record_failure 'one or more reviewed userspace packages could not be downloaded exactly'
    resolve_cached_manifest "$OUTPUT_DIR/expected-packages.txt" "$OUTPUT_DIR/cached-packages.tsv" \
        && record_pass 'exactly one regular cached archive resolved for every reviewed package' \
        || record_failure 'the reviewed package cache is missing, ambiguous, or unsafe'

    if values=$(inspect_payload_archives "$OUTPUT_DIR/cached-packages.tsv" "$OUTPUT_DIR"); then
        INSPECTED_PACKAGE_COUNT=$(printf '%s\n' "$values" | sed -n '1p')
        DOINST_SCRIPT_COUNT=$(printf '%s\n' "$values" | sed -n '2p')
        CONFIG_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '3p')
        SERVICE_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '4p')
        ELF_FILE_COUNT=$(printf '%s\n' "$values" | sed -n '5p')
        BOOT_THEME_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '6p')
        record_pass 'all 68 archives have safe paths, member types, links, permissions, and unique identities'
        record_pass 'the only GRUB payload is confined to the reviewed breeze theme prefix'
    else
        record_failure 'one or more userspace archives contain unsafe or unreviewed payload members'
    fi
    validate_doinst_syntax "$OUTPUT_DIR/doinst" \
        && record_pass 'all captured doinst.sh files are syntax-valid and remain unexecuted' \
        || record_failure 'a captured maintainer script is missing, ambiguous, or syntax-invalid'
    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$INSPECTED_PACKAGE_COUNT" -eq "$EXPECTED_PACKAGE_COUNT" ]; then
        PAYLOAD_PATH_REVIEW_COMPLETE=true
        NEXT_STAGE=current-userspace-maintainer-script-review-preflight
        record_pass 'the payload path review is complete while maintainer-script and userspace apply review remain pending'
    else
        PAYLOAD_PATH_REVIEW_COMPLETE=false
        NEXT_STAGE=manual-review-required
        record_failure 'the userspace payload boundary could not be completed safely'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and payload-sensitive state were captured after archive review' \
        || record_failure 'the final package or payload-sensitive state could not be captured safely'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during payload review' \
        || record_failure 'the installed package database changed during payload review'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged during payload review' \
        || record_failure 'the payload-sensitive system state changed during review'

    [ "$FAILURE_COUNT" -eq 0 ] || { PAYLOAD_PATH_REVIEW_COMPLETE=false; NEXT_STAGE=manual-review-required; }
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current userspace payload review result: candidates=%s, packages=%s, doinst=%s, config-paths=%s, service-paths=%s, elf=%s, boot-theme-paths=%s, payload-path-review-complete=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "$CONFIRM_CANDIDATES_SHA256" "$INSPECTED_PACKAGE_COUNT" "$DOINST_SCRIPT_COUNT" "$CONFIG_PATH_COUNT" "$SERVICE_PATH_COUNT" "$ELF_FILE_COUNT" "$BOOT_THEME_PATH_COUNT" "$PAYLOAD_PATH_REVIEW_COMPLETE" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
