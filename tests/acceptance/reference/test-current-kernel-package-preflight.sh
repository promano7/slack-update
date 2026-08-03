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
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-kernel-package-preflight

TARGET=
TARGET_KERNEL=
CONFIRM_CANDIDATES_SHA256=
NORMAL_PREFLIGHT=$DEFAULT_NORMAL_PREFLIGHT
BOOT_PREFLIGHT=$DEFAULT_BOOT_PREFLIGHT
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_VALUE=
RUNNING_KERNEL=
PACKAGE_FILENAME=
PACKAGE_PATH=
PACKAGE_SHA256=
DOINST_POLICY=unknown
GRUB_DISCOVERY_STATUS=not-run
APPLY_READY=false
APPLY_AUTHORIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Download and inspect the exact Slackware-current kernel-generic package without
installing it. The preflight validates the accepted candidate and boot-layout
records, the cached package archive, its path inventory and doinst.sh policy,
and a GRUB configuration generated only inside the evidence directory. It never
runs the package script, installs packages, changes /boot, or authorizes apply.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --normal-preflight PATH  Select the accepted normal-update record
      --boot-preflight PATH    Select the accepted boot-layout record
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
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error 'invalid candidate SHA-256'; return 1; }
    CONFIRM_CANDIDATES_SHA256=${CONFIRM_CANDIDATES_SHA256,,}
    is_safe_kernel_version "$TARGET_KERNEL" || { error 'unsafe target kernel version'; return 1; }
    for path in "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

validate_accepted_records() {
    python3 - "$NORMAL_PREFLIGHT" "$BOOT_PREFLIGHT" "$CONFIRM_CANDIDATES_SHA256" "$TARGET_KERNEL" <<'PY'
import json, sys
normal_path, boot_path, digest, target = sys.argv[1:]
try:
    normal = json.load(open(normal_path, encoding='utf-8'))
    boot = json.load(open(boot_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)
expected = f'kernel-generic-{target}-x86_64-1.txz'
checks = [
    normal.get('scenario') == 'normal-update',
    normal.get('target') == 'slackware-current',
    normal.get('accepted') is True,
    normal.get('apply_authorized') is False,
    normal.get('candidates', {}).get('candidate_set_sha256') == digest,
    expected in normal.get('candidates', {}).get('upgrade_all', []),
    boot.get('scenario') == 'current-kernel-boot-preflight',
    boot.get('target') == 'slackware-current',
    boot.get('accepted') is True,
    boot.get('normal_update_candidate_set_sha256') == digest,
    boot.get('target_kernel') == target,
    boot.get('package_layout') == 'monolithic-generic',
    boot.get('boot_mode') == 'direct-generic-no-initrd',
    boot.get('apply_ready') is False,
    boot.get('apply_authorized') is False,
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

capture_boot_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in /boot/vmlinuz-generic "/boot/vmlinuz-$RUNNING_KERNEL" /boot/initrd.gz /etc/mkinitrd.conf /boot/grub/grub.cfg; do
        printf '%s|' "$path" >> "$output"
        if [ -L "$path" ]; then
            printf 'symlink|%s|%s\n' "$(readlink -- "$path" 2>/dev/null || true)" "$(readlink -e -- "$path" 2>/dev/null || true)" >> "$output"
        elif [ -f "$path" ]; then
            printf 'regular|%s|%s\n' "$(stat -c '%a:%u:%g:%s' -- "$path")" "$(sha256sum -- "$path" | awk '{print $1}')" >> "$output"
        else
            printf 'missing||\n' >> "$output"
        fi
    done
}

validate_live_repository_target() {
    local pkglist=$1 target=$2 output=$3
    [ -f "$pkglist" ] && [ ! -L "$pkglist" ] && [ -r "$pkglist" ] || return 1
    python3 - "$pkglist" "$target" "$output" <<'PY_REPOSITORY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
target = sys.argv[2]
out = pathlib.Path(sys.argv[3])
expected_stem = f'kernel-generic-{target}-x86_64-1'
matches = []
for number, raw in enumerate(path.read_text(encoding='utf-8', errors='replace').splitlines(), 1):
    fields = raw.split()
    if len(fields) < 5:
        continue
    repository, name, version, arch, build = fields[:5]
    if (name, version, arch, build) != ('kernel-generic', target, 'x86_64', '1'):
        continue
    filename = fields[5] if len(fields) >= 6 else expected_stem
    if filename not in (expected_stem, expected_stem + '.txz'):
        raise SystemExit('repository filename does not match the reviewed package')
    matches.append((number, raw))
if len(matches) != 1:
    raise SystemExit(f'expected one reviewed repository record, found {len(matches)}')
out.write_text(f'{matches[0][0]}\t{matches[0][1]}\n', encoding='utf-8')
PY_REPOSITORY
}

run_exact_download() {
    local output=$1 status=0
    LC_ALL=C LANG=C TERM=dumb slackpkg -dialog=off -batch=on -default_answer=y \
        download kernel-generic > "$output" 2>&1 || status=$?
    printf '%d\n' "$status" > "$OUTPUT_DIR/slackpkg-download.exit"
    return "$status"
}

resolve_exact_cached_package() {
    local cache_root=$1 target=$2 output=$3
    python3 - "$cache_root" "$target" "$output" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
target = sys.argv[2]
out = pathlib.Path(sys.argv[3])
expected = f'kernel-generic-{target}-x86_64-1.txz'
matches = []
for path in root.rglob(expected):
    try:
        if path.is_file() and not path.is_symlink():
            matches.append(path.resolve(strict=True))
    except OSError:
        pass
matches = sorted(set(matches))
if len(matches) != 1:
    raise SystemExit(f'expected one cached {expected}, found {len(matches)}')
if root.resolve(strict=True) not in matches[0].parents:
    raise SystemExit('cached package escaped the cache root')
out.write_text(str(matches[0]) + '\n', encoding='utf-8')
PY
}

inspect_package_archive() {
    local package=$1 target=$2 inventory=$3 doinst=$4 summary=$5
    python3 - "$package" "$target" "$inventory" "$doinst" "$summary" <<'PY'
import hashlib, pathlib, posixpath, sys, tarfile
package = pathlib.Path(sys.argv[1])
target = sys.argv[2]
inventory = pathlib.Path(sys.argv[3])
doinst_out = pathlib.Path(sys.argv[4])
summary = pathlib.Path(sys.argv[5])
if not package.is_file() or package.is_symlink():
    raise SystemExit('unsafe package path')
expected_name = f'kernel-generic-{target}-x86_64-1.txz'
if package.name != expected_name:
    raise SystemExit('unexpected package filename')
with tarfile.open(package, mode='r:*') as archive:
    members = archive.getmembers()
    names = []
    for member in members:
        name = member.name.removeprefix('./')
        normalized = posixpath.normpath(name)
        if normalized == '.' and member.isdir():
            continue
        if not name or name.startswith('/') or normalized in ('.', '..') or normalized.startswith('../'):
            raise SystemExit(f'unsafe archive member: {member.name!r}')
        if member.isdev() or member.isfifo():
            raise SystemExit(f'unsupported archive member type: {member.name!r}')
        if member.issym() or member.islnk():
            link = member.linkname
            normalized_link = posixpath.normpath(posixpath.join(posixpath.dirname(normalized), link))
            if link.startswith('/') or normalized_link == '..' or normalized_link.startswith('../'):
                raise SystemExit(f'unsafe archive link: {member.name!r}')
        names.append(normalized)
    if len(names) != len(set(names)):
        raise SystemExit('duplicate archive members')
    required = {f'boot/vmlinuz-{target}', 'install/doinst.sh'}
    if not required.issubset(names):
        raise SystemExit('required kernel package members are missing')
    module_prefix = f'lib/modules/{target}/'
    modules = [name for name in names if name.startswith(module_prefix) and name.endswith('.ko')]
    if not modules:
        raise SystemExit('target module files are missing')
    foreign_modules = sorted({name.split('/')[2] for name in names if name.startswith('lib/modules/') and len(name.split('/')) > 2 and name.split('/')[2] != target})
    if foreign_modules:
        raise SystemExit('foreign module versions are present')
    if any(name.startswith('boot/initrd') for name in names):
        raise SystemExit('kernel package unexpectedly contains an initrd')
    doinst_members = [member for member in members if member.name.removeprefix('./') == 'install/doinst.sh']
    if len(doinst_members) != 1 or not doinst_members[0].isfile():
        raise SystemExit('doinst.sh is not one regular archive member')
    stream = archive.extractfile(doinst_members[0])
    if stream is None:
        raise SystemExit('doinst.sh could not be read')
    doinst = stream.read()
    if not doinst or len(doinst) > 131072 or b'\0' in doinst:
        raise SystemExit('unsafe doinst.sh content')
    doinst.decode('utf-8')
    doinst_out.write_bytes(doinst)
inventory.write_text(''.join(name + '\n' for name in names), encoding='utf-8')
hasher = hashlib.sha256()
with package.open('rb') as handle:
    for block in iter(lambda: handle.read(1024 * 1024), b''):
        hasher.update(block)
digest = hasher.hexdigest()
summary.write_text(
    f'package={package}\nsha256={digest}\nmember_count={len(names)}\nmodule_count={len(modules)}\n'
    f'kernel_image=boot/vmlinuz-{target}\ndoinst=install/doinst.sh\ninitrd_members=0\n',
    encoding='utf-8')
PY
}

validate_doinst_policy() {
    local script=$1 target=$2 summary=$3
    sh -n "$script" || return 1
    python3 - "$script" "$target" "$summary" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
target = sys.argv[2]
out = pathlib.Path(sys.argv[3])
text = path.read_text(encoding='utf-8')
forbidden = {'mkinitrd', 'grub-mkconfig', 'grub-install', 'lilo', 'eliloconfig', 'efibootmgr', 'slackpkg', 'installpkg', 'upgradepkg', 'removepkg', 'reboot', 'shutdown'}
executed_tokens = []
for raw_line in text.splitlines():
    line = raw_line.strip()
    if not line or line.startswith('#'):
        continue
    # Split the simple Slackware doinst command form at shell control separators.
    for segment in re.split(r'(?:&&|\|\||;|[()])', line):
        segment = segment.strip()
        if not segment or segment.startswith('#'):
            continue
        match = re.match(r'(?:if\s+|then\s+|else\s+|elif\s+)?(?:/[^\s]+/)?([A-Za-z0-9_.+-]+)', segment)
        if match:
            executed_tokens.append(match.group(1))
if forbidden.intersection(executed_tokens):
    raise SystemExit('doinst.sh contains a forbidden transaction command')
versioned = f'vmlinuz-{target}'
if versioned not in text or 'vmlinuz-generic' not in text:
    raise SystemExit('generic kernel symlink transition is not represented')
ln_lines = [line.strip() for line in text.splitlines() if re.search(r'(^|[;&()\s])ln\s', line)]
transition = [line for line in ln_lines if versioned in line and 'vmlinuz-generic' in line and re.search(r'\bln\s+-[^\n]*s', line)]
if len(transition) != 1:
    raise SystemExit(f'expected one generic symlink transition, found {len(transition)}')
unsafe_rm = []
for line in text.splitlines():
    stripped = line.strip()
    if re.search(r'(^|[;&()\s])rm\s', stripped) and re.search(r'(^|\s)/(?:\s|$|\*)', stripped):
        unsafe_rm.append(stripped)
if unsafe_rm:
    raise SystemExit('doinst.sh contains an unsafe absolute removal')
required_geninitrd_guards = [
    'var/lib/pkgtools/setup/setup.01.mkinitrd',
    'vmlinuz-generic-smp',
    'INSIDE_INSTALLER',
    'usr/sbin/geninitrd',
]
if not all(token in text for token in required_geninitrd_guards):
    raise SystemExit('conditional geninitrd hook is absent or not recognized')
invocations = []
for raw_line in text.splitlines():
    line = raw_line.strip()
    if not line or line.startswith('#') or line.startswith('if '):
        continue
    if re.fullmatch(r'(?:/)?usr/sbin/geninitrd(?:\s*)', line):
        invocations.append(line)
if len(invocations) != 1:
    raise SystemExit(f'expected one conditional geninitrd invocation, found {len(invocations)}')
out.write_text(
    'syntax=valid\npolicy=recognized-direct-generic-transition-with-conditional-geninitrd\n'
    f'target={target}\ntransition={transition[0]}\n'
    f'geninitrd_invocation={invocations[0]}\npostinstall_hook=conditional-geninitrd\n'
    'host_policy_preflight_required=true\nforbidden_commands=absent\nexecuted=false\n',
    encoding='utf-8')
PY
}

run_grub_discovery() {
    local output=$1 log=$2 status=0
    grub-mkconfig -o "$output" > "$log" 2>&1 || status=$?
    printf '%d\n' "$status" > "$OUTPUT_DIR/grub-mkconfig.exit"
    [ "$status" -eq 0 ] || return "$status"
    [ -s "$output" ] && [ ! -L "$output" ] || return 1
    grub-script-check "$output" >> "$log" 2>&1 || return 1
    grep -Fq '/boot/vmlinuz-generic' "$output" || grep -Fq "/boot/vmlinuz-$RUNNING_KERNEL" "$output"
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-kernel-package-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
hostname=$HOSTNAME_VALUE
running_kernel=$RUNNING_KERNEL
target_kernel=$TARGET_KERNEL
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
package_filename=$PACKAGE_FILENAME
package_path=$PACKAGE_PATH
package_sha256=$PACKAGE_SHA256
doinst_policy=$DOINST_POLICY
grub_discovery_status=$GRUB_DISCOVERY_STATUS
apply_ready=$APPLY_READY
apply_authorized=$APPLY_AUTHORIZED
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-kernel-package-preflight-${timestamp}.tar.gz"
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
    local timestamp package_list doinst_file
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    [ "$(cat /etc/slackware-version 2>/dev/null || true)" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in slackpkg python3 tar sha256sum grub-mkconfig grub-script-check find; do
        command -v "$command" >/dev/null 2>&1 || { error "required command missing: $command"; return 2; }
    done
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"
    HOSTNAME_VALUE=$(hostname -f 2>/dev/null || hostname)
    RUNNING_KERNEL=$(uname -r)
    PACKAGE_FILENAME="kernel-generic-$TARGET_KERNEL-x86_64-1.txz"

    validate_accepted_records \
        && record_pass 'the accepted normal-update and direct-generic boot records match this transaction' \
        || record_failure 'the accepted records do not match this transaction'
    [ "$RUNNING_KERNEL" != "$TARGET_KERNEL" ] && is_safe_kernel_version "$RUNNING_KERNEL" \
        && record_pass "the running kernel $RUNNING_KERNEL is a safe predecessor of $TARGET_KERNEL" \
        || record_failure 'the running and target kernel relationship is unsafe'
    capture_package_state "$OUTPUT_DIR/packages.before.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.before.txt" \
        && record_pass 'the package database and boot state were captured before download inspection' \
        || record_failure 'the initial package or boot state could not be captured'

    validate_live_repository_target /var/lib/slackpkg/pkglist "$TARGET_KERNEL" "$OUTPUT_DIR/live-repository-record.txt" \
        && record_pass 'the live Slackpkg metadata still exposes exactly the reviewed kernel-generic package' \
        || record_failure 'the live Slackpkg metadata no longer matches the reviewed kernel-generic package'
    if [ "$FAILURE_COUNT" -ne 0 ]; then
        capture_package_state "$OUTPUT_DIR/packages.after.txt" || true
        capture_boot_state "$OUTPUT_DIR/boot.after.txt" || true
        write_summary "$OUTPUT_DIR/summary.txt"
        publish_evidence || return 2
        return 1
    fi

    printf 'Downloading the exact kernel-generic package without installing it...\n'
    run_exact_download "$OUTPUT_DIR/slackpkg-download.log" \
        && record_pass 'slackpkg downloaded or confirmed the exact kernel-generic package safely' \
        || record_failure 'the exact kernel-generic package download failed'
    resolve_exact_cached_package /var/cache/packages "$TARGET_KERNEL" "$OUTPUT_DIR/cached-package.txt" \
        && record_pass 'exactly one reviewed kernel-generic package resolved inside the Slackpkg cache' \
        || record_failure 'the reviewed kernel-generic package is missing or ambiguous in the cache'

    PACKAGE_PATH=$(sed -n '1p' "$OUTPUT_DIR/cached-package.txt" 2>/dev/null || true)
    package_list=$OUTPUT_DIR/package-members.txt
    doinst_file=$OUTPUT_DIR/doinst.sh
    if [ -n "$PACKAGE_PATH" ] && inspect_package_archive "$PACKAGE_PATH" "$TARGET_KERNEL" "$package_list" "$doinst_file" "$OUTPUT_DIR/package-summary.txt"; then
        PACKAGE_SHA256=$(awk -F= '$1 == "sha256" { print $2 }' "$OUTPUT_DIR/package-summary.txt")
        record_pass 'the package archive has safe paths, the target kernel image, and target module files'
    else
        record_failure 'the package archive structure is unsafe or incomplete'
    fi
    if [ -s "$doinst_file" ] && validate_doinst_policy "$doinst_file" "$TARGET_KERNEL" "$OUTPUT_DIR/doinst-policy.txt"; then
        DOINST_POLICY=recognized-direct-generic-transition-with-conditional-geninitrd
        record_pass 'doinst.sh has valid syntax, one generic-kernel symlink transition, and one non-executed conditional geninitrd hook'
    else
        record_failure 'doinst.sh policy is unsafe or not recognized'
    fi
    if run_grub_discovery "$OUTPUT_DIR/grub-current.generated.cfg" "$OUTPUT_DIR/grub-mkconfig.log"; then
        GRUB_DISCOVERY_STATUS=valid-current-baseline
        record_pass 'GRUB generated and validated a current-system baseline only inside the evidence directory'
    else
        record_failure 'the GRUB discovery baseline could not be generated and validated safely'
    fi

    capture_package_state "$OUTPUT_DIR/packages.after.txt" \
        && capture_boot_state "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the package database and boot state were captured after inspection' \
        || record_failure 'the final package or boot state could not be captured'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during the preflight' \
        || record_failure 'the installed package database changed during the preflight'
    cmp -s "$OUTPUT_DIR/boot.before.txt" "$OUTPUT_DIR/boot.after.txt" \
        && record_pass 'the active boot state remained unchanged during the preflight' \
        || record_failure 'the active boot state changed during the preflight'

    APPLY_READY=false
    APPLY_AUTHORIZED=false
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current kernel package result: running=%s, target=%s, doinst=%s, apply-ready=false, apply-authorized=false\n' \
        "$RUNNING_KERNEL" "$TARGET_KERNEL" "$DOINST_POLICY"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
