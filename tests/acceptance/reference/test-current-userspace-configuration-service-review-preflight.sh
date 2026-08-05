#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_MAINTAINER_REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-maintainer-script-review-preflight.sh"
DEFAULT_MAINTAINER_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-20260805-accepted.json"
DEFAULT_REVIEW_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-configuration-service-review-policy.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-userspace-configuration-service-review-preflight

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
MAINTAINER_REVIEW_SCRIPT=$DEFAULT_MAINTAINER_REVIEW_SCRIPT
MAINTAINER_RECORD=$DEFAULT_MAINTAINER_RECORD
REVIEW_POLICY=$DEFAULT_REVIEW_POLICY
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
EXPECTED_CONFIGURATION_PATH_COUNT=0
EXPECTED_SERVICE_PATH_COUNT=0
CONFIGURATION_PATH_COUNT=0
CONFIGURATION_FILE_COUNT=0
SERVICE_PATH_COUNT=0
SERVICE_FILE_COUNT=0
REVIEWED_PACKAGE_COUNT=0
SYSTEMD_USER_SERVICE_COUNT=0
SYSTEMD_USER_PRESET_COUNT=0
SYSTEMD_SYSTEM_SERVICE_COUNT=0
RC_SCRIPT_COUNT=0
CONFIGURATION_SERVICE_REVIEW_COMPLETE=false
NEXT_STAGE=manual-review-required

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Review the exact configuration and service payloads from the accepted
Slackware-current userspace transaction without installing packages or
executing payload files. The preflight reruns the maintainer-script review,
verifies the exact 90-path boundary, reads only the reviewed regular members
from the exact cached package archives, and performs static format and scope
checks. It never starts or reloads a service.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --maintainer-review-script PATH
      --maintainer-record PATH
      --review-policy PATH
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
            --maintainer-review-script) [ "$#" -ge 2 ] || return 1; MAINTAINER_REVIEW_SCRIPT=$2; shift 2 ;;
            --maintainer-record) [ "$#" -ge 2 ] || return 1; MAINTAINER_RECORD=$2; shift 2 ;;
            --review-policy) [ "$#" -ge 2 ] || return 1; REVIEW_POLICY=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    local path
    for path in "$MAINTAINER_REVIEW_SCRIPT" "$MAINTAINER_RECORD" "$REVIEW_POLICY" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
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
    python3 - "$MAINTAINER_RECORD" "$REVIEW_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
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

config = policy.get('configuration_paths', [])
service = policy.get('service_paths', [])
rows = [('configuration', item) for item in config] + [('service', item) for item in service]
manifest = ''.join(
    f"{kind}\t{item.get('package')}\t{item.get('path')}\t{item.get('kind')}\t{item.get('mode')}\t{item.get('size')}\n"
    for kind, item in sorted(rows, key=lambda value: (value[0], value[1].get('package',''), value[1].get('path','')))
).encode()
config_regular = {f"{item.get('package')}\t{item.get('path')}" for item in config if item.get('kind') == 'regular'}
service_regular = {f"{item.get('package')}\t{item.get('path')}" for item in service if item.get('kind') == 'regular'}
totals = policy.get('expected_totals', {})
reviewed_packages = policy.get('reviewed_packages', [])
package_manifest = ''.join(f"{item.get('package')}\t{item.get('sha256')}\t{item.get('size')}\n" for item in sorted(reviewed_packages, key=lambda item:item.get('package',''))).encode()
checks = [
    record.get('scenario') == 'current-userspace-maintainer-script-review-preflight',
    record.get('target') == 'slackware-current', record.get('accepted') is True, denied(record),
    digest(record.get('archive_sha256')), digest(record.get('nested_payload_archive_sha256')),
    record.get('candidate_set_sha256') == confirmed_digest,
    record.get('target_kernel') == confirmed_target,
    record.get('expected_package_count') == record.get('inspected_package_count') == 68,
    record.get('doinst_script_count') == 37,
    record.get('maintainer_scripts_review_complete') is True,
    record.get('configuration_service_review_complete') is False,
    record.get('userspace_apply_review_complete') is False,
    record.get('package_transaction_executed') is False,
    record.get('maintainer_script_executed') is False,
    record.get('package_database_unchanged') is True,
    record.get('maintainer_sensitive_state_unchanged') is True,
    record.get('assertions') == {'passes': 15, 'failures': 0},
    record.get('evidence', {}).get('copied_to') == '/home/promano',
    record.get('evidence', {}).get('destination_verification') == 'passed',
    record.get('next_stage') == 'current-userspace-configuration-service-review-preflight',
    policy.get('scenario') == 'current-userspace-configuration-service-review-policy',
    policy.get('target') == 'slackware-current', policy.get('reviewed') is True, denied(policy),
    policy.get('candidate_set_sha256') == confirmed_digest,
    policy.get('target_kernel') == confirmed_target,
    policy.get('accepted_maintainer_archive_sha256') == record.get('archive_sha256'),
    policy.get('accepted_nested_payload_archive_sha256') == record.get('nested_payload_archive_sha256'),
    policy.get('expected_package_count') == 68,
    policy.get('expected_doinst_script_count') == 37,
    policy.get('expected_reviewed_package_count') == len(reviewed_packages) == 19,
    len({item.get('package') for item in reviewed_packages}) == 19,
    all(digest(item.get('sha256')) and isinstance(item.get('size'), int) and item.get('size') > 0 for item in reviewed_packages),
    policy.get('reviewed_package_manifest_sha256') == hashlib.sha256(package_manifest).hexdigest(),
    len(config) == totals.get('configuration_paths') == 46,
    len(service) == totals.get('service_paths') == 44,
    len(config_regular) == totals.get('configuration_files') == 21,
    len(service_regular) == totals.get('service_files') == 27,
    len(config) - len(config_regular) == totals.get('configuration_directories') == 25,
    len(service) - len(service_regular) == totals.get('service_directories') == 17,
    len({(item.get('package'), item.get('path')) for item in config}) == 46,
    len({(item.get('package'), item.get('path')) for item in service}) == 44,
    set(policy.get('configuration_file_classes', {})) == config_regular,
    set(policy.get('service_file_classes', {})) == service_regular,
    policy.get('path_manifest_sha256') == hashlib.sha256(manifest).hexdigest(),
    policy.get('allowed_service_prefixes') == ['usr/lib/systemd/user/', 'usr/lib/systemd/user-preset/'],
    policy.get('forbidden_service_prefixes') == ['etc/rc.d/', 'lib/systemd/system/', 'usr/lib/systemd/system/', 'usr/lib64/systemd/system/'],
    totals.get('systemd_user_service') == 26,
    totals.get('systemd_user_preset') == 1,
    totals.get('systemd_system_service') == 0,
    totals.get('rc_script') == 0,
    policy.get('require_exact_path_manifest') is True,
    policy.get('require_exact_package_hashes') is True,
    policy.get('require_nonexecuting_review') is True,
    policy.get('require_complete_file_classification') is True,
    policy.get('require_user_service_scope_only') is True,
    policy.get('maintainer_scripts_review_complete') is True,
    policy.get('configuration_service_review_complete') is False,
    policy.get('userspace_apply_review_complete') is False,
    policy.get('next_stage') == 'current-userspace-elf-runtime-review-preflight',
]
if not all(checks):
    raise SystemExit(1)
print(len(config))
print(len(service))
PY
}

parse_summary_file() {
    python3 - "$1" <<'PY'
import sys
result={}
for raw in open(sys.argv[1], encoding='utf-8'):
    raw=raw.rstrip('\n')
    if '=' in raw:
        key,value=raw.split('=',1); result[key]=value
for key in sorted(result): print(f'{key}\t{result[key]}')
PY
}

validate_nested_maintainer() {
    local directory=$1
    [ -f "$directory/summary.txt" ] || return 1
    [ -f "$directory/maintainer-script-summary.json" ] || return 1
    [ -f "$directory/maintainer-script-inventory.tsv" ] || return 1
    [ -f "$directory/nested/payload-review/package-payload-summary.json" ] || return 1
    [ -f "$directory/nested/payload-review/payload-inventory.tsv" ] || return 1
    [ -f "$directory/nested/payload-review/cached-packages.tsv" ] || return 1
    python3 - "$directory" "$MAINTAINER_RECORD" "$REVIEW_POLICY" <<'PY'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
record=json.load(open(sys.argv[2], encoding='utf-8'))
policy=json.load(open(sys.argv[3], encoding='utf-8'))
summary={}
for raw in (root/'summary.txt').read_text().splitlines():
    if '=' in raw:
        key,value=raw.split('=',1); summary[key]=value
maint=json.load(open(root/'maintainer-script-summary.json', encoding='utf-8'))
payload=json.load(open(root/'nested/payload-review/package-payload-summary.json', encoding='utf-8'))
checks=[
    summary.get('scenario') == 'current-userspace-maintainer-script-review-preflight',
    summary.get('result') == 'PASS', summary.get('target') == 'slackware-current',
    summary.get('candidate_set_sha256') == record.get('candidate_set_sha256'),
    summary.get('target_kernel') == record.get('target_kernel'),
    int(summary.get('classified_doinst_script_count','-1')) == 37,
    int(summary.get('relative_remove_count','-1')) == 1159,
    int(summary.get('relative_symlink_count','-1')) == 1159,
    int(summary.get('config_install_count','-1')) == 2,
    int(summary.get('cache_refresh_count','-1')) == 5,
    int(summary.get('process_signal_count','-1')) == 1,
    summary.get('maintainer_scripts_review_complete') == 'true',
    summary.get('userspace_apply_review_complete') == 'false',
    summary.get('package_transaction_executed') == 'false',
    summary.get('maintainer_script_executed') == 'false',
    summary.get('next_stage') == 'current-userspace-configuration-service-review-preflight',
    summary.get('apply_ready') == 'false', summary.get('apply_authorized') == 'false',
    int(summary.get('passes','-1')) == 15, int(summary.get('failures','-1')) == 0,
    maint.get('scenario') == 'current-userspace-maintainer-script-review-preflight',
    maint.get('script_count') == 37,
    maint.get('action_totals') == {'cache_refresh':5,'config_install':2,'process_signal':1,'relative_remove':1159,'relative_symlink':1159},
    maint.get('exact_script_hashes_verified') is True,
    maint.get('complete_command_classification') is True,
    maint.get('remove_symlink_pairing_verified') is True,
    maint.get('process_signal_confined_to_reviewed_exception') is True,
    maint.get('maintainer_scripts_executed') is False,
    maint.get('maintainer_scripts_review_complete') is True,
    maint.get('next_stage') == 'current-userspace-configuration-service-review-preflight',
    payload.get('scenario') == 'current-userspace-payload-review-preflight',
    payload.get('package_count') == 68,
    payload.get('totals',{}).get('config_paths') == policy.get('expected_totals',{}).get('configuration_paths'),
    payload.get('totals',{}).get('service_paths') == policy.get('expected_totals',{}).get('service_paths'),
    payload.get('payload_path_review_complete') is True,
]
if not all(checks): raise SystemExit(1)
PY
}

create_and_verify_nested_archive() {
    local nested_root=$1 directory=$2 archive sidecar
    archive=$nested_root/maintainer-review.tar.gz
    sidecar=$archive.sha256
    tar -C "$nested_root" -czf "$archive" "$(basename -- "$directory")" || return 1
    (cd "$nested_root" && sha256sum -- "${archive##*/}" > "${sidecar##*/}") || return 1
    (cd "$nested_root" && sha256sum -c "${sidecar##*/}" >/dev/null) || return 1
}

analyze_configuration_service_payload() {
    local payload_dir=$1 inventory=$2 summary=$3 reviewed_root=$4
    python3 - "$payload_dir" "$REVIEW_POLICY" "$inventory" "$summary" "$reviewed_root" <<'PY'
import configparser, hashlib, io, json, os, pathlib, posixpath, re, shlex, stat, subprocess, sys, tarfile
import xml.etree.ElementTree as ET
payload_dir=pathlib.Path(sys.argv[1])
policy=json.load(open(sys.argv[2], encoding='utf-8'))
inventory_out=pathlib.Path(sys.argv[3]); summary_out=pathlib.Path(sys.argv[4]); reviewed_root=pathlib.Path(sys.argv[5])
reviewed_root.mkdir(parents=True, exist_ok=True)

def key(item): return (item['package'], item['path'])
def exact_tuple(item): return (item['package'], item['path'], item['kind'], str(item['mode']), int(item['size']))
expected_config={key(x):x for x in policy['configuration_paths']}
expected_service={key(x):x for x in policy['service_paths']}
expected_totals=policy['expected_totals']
if len(expected_config)!=expected_totals['configuration_paths'] or len(expected_service)!=expected_totals['service_paths']: raise SystemExit('policy path count changed')

actual_config={}; actual_service={}
for raw in (payload_dir/'payload-inventory.tsv').read_text(encoding='utf-8').splitlines():
    fields=raw.split('\t')
    if len(fields)!=6: raise SystemExit('malformed payload inventory')
    package,path,kind,mode,size,link=fields
    item={'package':package,'path':path,'kind':kind,'mode':mode,'size':int(size)}
    if path.startswith('etc/'):
        actual_config[key(item)]=item
    if path.startswith(('etc/rc.d/','usr/lib/systemd/','lib/systemd/','usr/lib64/systemd/')):
        actual_service[key(item)]=item
if set(actual_config)!=set(expected_config) or set(actual_service)!=set(expected_service):
    raise SystemExit('configuration or service path set changed')
for k,item in actual_config.items():
    if exact_tuple(item)!=exact_tuple(expected_config[k]): raise SystemExit(f'configuration path metadata changed: {k}')
for k,item in actual_service.items():
    if exact_tuple(item)!=exact_tuple(expected_service[k]): raise SystemExit(f'service path metadata changed: {k}')
rows=[('configuration',x) for x in actual_config.values()]+[('service',x) for x in actual_service.values()]
manifest=''.join(f"{kind}\t{x['package']}\t{x['path']}\t{x['kind']}\t{x['mode']}\t{x['size']}\n" for kind,x in sorted(rows,key=lambda y:(y[0],y[1]['package'],y[1]['path']))).encode()
if hashlib.sha256(manifest).hexdigest()!=policy['path_manifest_sha256']:
    raise SystemExit('configuration/service path manifest changed')
for item in list(actual_config.values())+list(actual_service.values()):
    if item['kind']=='directory' and (item['mode']!='755' or item['size']!=0):
        raise SystemExit(f'unsafe directory metadata: {item["path"]}')

cache={}
for raw in (payload_dir/'cached-packages.tsv').read_text(encoding='utf-8').splitlines():
    fields=raw.split('\t')
    if len(fields)!=4: raise SystemExit('malformed cached package manifest')
    filename,path,digest,size=fields
    cache[filename]=(pathlib.Path(path),digest,int(size))
packages=sorted({x['package'] for x in list(actual_config.values())+list(actual_service.values())})
reviewed_packages=policy.get('reviewed_packages',[])
package_manifest=''.join(f"{item['package']}\t{item['sha256']}\t{item['size']}\n" for item in sorted(reviewed_packages,key=lambda item:item['package'])).encode()
if hashlib.sha256(package_manifest).hexdigest()!=policy.get('reviewed_package_manifest_sha256'): raise SystemExit('reviewed package manifest changed')
expected_packages={item['package']:(item['sha256'],int(item['size'])) for item in reviewed_packages}
if len(expected_packages)!=policy.get('expected_reviewed_package_count') or set(packages)!=set(expected_packages): raise SystemExit('reviewed package identity set changed')
if any(package not in cache for package in packages): raise SystemExit('review package is missing from cache manifest')
for package in packages:
    path,digest,size=cache[package]
    if (digest,size)!=expected_packages[package]: raise SystemExit(f'reviewed package identity changed: {package}')
    if path.name!=package or not path.is_file() or path.is_symlink(): raise SystemExit(f'unsafe cached package path: {package}')
    h=hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda:handle.read(1024*1024),b''): h.update(block)
    if h.hexdigest()!=digest or path.stat().st_size!=size: raise SystemExit(f'cached package changed: {package}')

config_classes=policy['configuration_file_classes']; service_classes=policy['service_file_classes']
expected_regular={**{k:('configuration',v) for k,v in config_classes.items()},**{k:('service',v) for k,v in service_classes.items()}}
result_rows=[]; class_counts={}; preset_enable=0; preset_disable=0; unit_exec=0
for package in packages:
    archive_path,package_sha,package_size=cache[package]
    wanted={p:item for (pkg,p),item in {**actual_config,**actual_service}.items() if pkg==package and item['kind']=='regular'}
    if not wanted: continue
    with tarfile.open(archive_path,mode='r:*') as archive:
        members={posixpath.normpath(member.name.removeprefix('./')):member for member in archive.getmembers()}
        for path,item in sorted(wanted.items()):
            member=members.get(path)
            if member is None or not member.isfile() or member.issym() or member.islnk(): raise SystemExit(f'missing regular member: {package}:{path}')
            if format(member.mode,'o')!=item['mode'] or member.size!=item['size']: raise SystemExit(f'regular metadata changed: {package}:{path}')
            stream=archive.extractfile(member)
            if stream is None: raise SystemExit(f'unreadable regular member: {package}:{path}')
            content=stream.read(item['size']+1); stream.close()
            if len(content)!=item['size']: raise SystemExit(f'regular size changed while reading: {package}:{path}')
            compound=f'{package}\t{path}'
            scope,classification=expected_regular.get(compound,(None,None))
            if scope is None: raise SystemExit(f'unclassified regular file: {package}:{path}')
            out=reviewed_root/package/path
            out.parent.mkdir(parents=True,exist_ok=True)
            out.write_bytes(content); os.chmod(out,0o600)
            digest=hashlib.sha256(content).hexdigest()
            details='static-format-valid'
            if classification=='png-asset':
                if not content.startswith(b'\x89PNG\r\n\x1a\n') or b'IHDR' not in content[:64] or b'IEND' not in content[-32:]: raise SystemExit('invalid PNG asset')
                details='png-signature-and-terminal-chunk-valid'
            else:
                if b'\0' in content: raise SystemExit(f'NUL byte in reviewed text file: {path}')
                try: text=content.decode('utf-8')
                except UnicodeDecodeError: raise SystemExit(f'non-UTF-8 reviewed text file: {path}')
                if any(len(line)>16384 for line in text.splitlines()): raise SystemExit(f'oversized text line: {path}')
                if classification=='xdg-autostart-desktop':
                    if '[Desktop Entry]' not in text: raise SystemExit(f'missing Desktop Entry group: {path}')
                    values={}
                    for raw in text.splitlines():
                        if '=' in raw and not raw.lstrip().startswith('#'):
                            k,v=raw.split('=',1); values.setdefault(k.strip(),v.strip())
                    if values.get('Type')!='Application' or not values.get('Exec'): raise SystemExit(f'unsafe desktop entry: {path}')
                    if re.search(r'[;&|<>`]|\$\(',values['Exec']): raise SystemExit(f'shell control syntax in desktop Exec: {path}')
                    details='desktop-entry-application-exec-static'
                elif classification=='native-messaging-json':
                    try:
                        data=json.loads(text)
                    except Exception as exc:
                        raise SystemExit(f'invalid native messaging JSON: {path}: {exc}')
                    if not isinstance(data,dict) or not isinstance(data.get('name'),str) or not isinstance(data.get('path'),str): raise SystemExit(f'invalid native messaging manifest: {path}')
                    host=data['path']
                    if not host.startswith('/usr/') or re.search(r'[;&|<>`]|\$\(',host): raise SystemExit(f'unsafe native host path: {path}')
                    details=f'native-host={host}'
                elif classification=='shell-helper':
                    completed=subprocess.run(['sh','-n',str(out)],stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                    if completed.returncode!=0: raise SystemExit(f'shell syntax error: {path}')
                    forbidden=re.compile(r'(^|[^A-Za-z0-9_-])(slackpkg|installpkg|upgradepkg|removepkg|systemctl|service|mkinitrd|geninitrd|dkms|grub-mkconfig|update-grub)([^A-Za-z0-9_-]|$)')
                    if any(forbidden.search(raw) for raw in text.splitlines() if not raw.lstrip().startswith('#')): raise SystemExit(f'forbidden control command in shell helper: {path}')
                    details='shell-syntax-valid-not-executed'
                elif classification=='pam-new':
                    valid=('auth','account','password','session','-auth','-account','-password','-session')
                    for raw in text.splitlines():
                        line=raw.strip()
                        if not line or line.startswith('#'): continue
                        if line.split()[0] not in valid: raise SystemExit(f'unclassified PAM directive: {path}')
                    details='pam-directives-static'
                elif classification=='xdg-menu-xml':
                    try:
                        ET.fromstring(text)
                    except ET.ParseError as exc:
                        raise SystemExit(f'invalid XDG menu XML: {path}: {exc}')
                    details='xml-well-formed'
                elif classification in ('ini-style-config','openssl-config-new','stunnel-sample'):
                    if re.search(r'(^|\n)\s*(slackpkg|installpkg|upgradepkg|removepkg|systemctl|mkinitrd|geninitrd|dkms|grub-mkconfig)\b',text): raise SystemExit(f'control command in configuration text: {path}')
                    details='bounded-utf8-configuration-text'
                elif classification in ('systemd-user-service','systemd-user-preset'):
                    pass
                else:
                    raise SystemExit(f'unknown configuration classification: {classification}')
            if classification=='systemd-user-service':
                if not path.startswith('usr/lib/systemd/user/') or not path.endswith('.service'): raise SystemExit(f'unit escaped user scope: {path}')
                sections=set(); directives=[]
                for raw in text.splitlines():
                    line=raw.strip()
                    if not line or line.startswith(('#',';')): continue
                    if line.startswith('[') and line.endswith(']'): sections.add(line[1:-1]); continue
                    if '=' not in line: raise SystemExit(f'malformed systemd unit line: {path}')
                    k,v=line.split('=',1); directives.append((k.strip(),v.strip()))
                if 'Unit' not in sections or 'Service' not in sections: raise SystemExit(f'incomplete systemd user service: {path}')
                forbidden_keys={'User','Group','SupplementaryGroups','AmbientCapabilities','CapabilityBoundingSet','DeviceAllow','RootDirectory','RootImage','BindPaths','BindReadOnlyPaths','MountImages','NetworkNamespacePath','PIDFile'}
                if any(k in forbidden_keys for k,v in directives): raise SystemExit(f'privileged systemd directive in user unit: {path}')
                for k,v in directives:
                    if k.startswith('Exec'):
                        unit_exec+=1
                        command=v.lstrip('-+!:@')
                        if re.search(r'[;&|<>`]|\$\(',command): raise SystemExit(f'shell control syntax in systemd Exec directive: {path}')
                        try: argv=shlex.split(command,posix=True)
                        except ValueError: raise SystemExit(f'invalid systemd Exec syntax: {path}')
                        if not argv: raise SystemExit(f'empty systemd Exec directive: {path}')
                        if pathlib.PurePosixPath(argv[0]).name in {'sh','bash','dash','zsh','ksh'}: raise SystemExit(f'shell interpreter in systemd Exec directive: {path}')
                details='systemd-user-service-static-no-privileged-directives'
            elif classification=='systemd-user-preset':
                if not path.startswith('usr/lib/systemd/user-preset/') or not path.endswith('.preset'): raise SystemExit(f'preset escaped user scope: {path}')
                for raw in text.splitlines():
                    line=raw.strip()
                    if not line or line.startswith('#'): continue
                    fields=line.split()
                    if len(fields)!=2 or fields[0] not in ('enable','disable') or not fields[1].endswith('.service') or any(c in fields[1] for c in '*?[]/\\'):
                        raise SystemExit(f'unsafe systemd user preset: {path}')
                    if fields[0]=='enable': preset_enable+=1
                    else: preset_disable+=1
                details='systemd-user-preset-static'
            class_counts[classification]=class_counts.get(classification,0)+1
            result_rows.append((scope,package,path,item['mode'],item['size'],digest,classification,details))

checks={
 'xdg-autostart-desktop':'xdg_autostart_desktop','native-messaging-json':'native_messaging_json','shell-helper':'shell_helper',
 'pam-new':'pam_new','xdg-menu-xml':'xdg_menu_xml','png-asset':'png_asset','ini-style-config':'ini_style_config',
 'openssl-config-new':'openssl_config_new','stunnel-sample':'stunnel_sample','systemd-user-service':'systemd_user_service',
 'systemd-user-preset':'systemd_user_preset',
}
for class_name,total_name in checks.items():
    if class_counts.get(class_name,0)!=expected_totals.get(total_name): raise SystemExit(f'classification count changed: {class_name}')
if any(path.startswith(tuple(policy['forbidden_service_prefixes'])) for package,path in actual_service): raise SystemExit('forbidden system service or rc path present')
if len(result_rows)!=expected_totals['configuration_files']+expected_totals['service_files']: raise SystemExit('reviewed regular file count changed')
inventory_out.write_text('scope\tpackage\tpath\tmode\tsize\tsha256\tclassification\tdetail\n'+''.join(
    '\t'.join(map(str,row))+'\n' for row in sorted(result_rows)
),encoding='utf-8')
summary={
 'scenario':'current-userspace-configuration-service-review-preflight',
 'configuration_path_count':len(actual_config),'configuration_file_count':sum(x['kind']=='regular' for x in actual_config.values()),
 'service_path_count':len(actual_service),'service_file_count':sum(x['kind']=='regular' for x in actual_service.values()),
 'reviewed_package_count':len(packages),'systemd_user_service_count':class_counts.get('systemd-user-service',0),
 'systemd_user_preset_count':class_counts.get('systemd-user-preset',0),'systemd_system_service_count':0,'rc_script_count':0,
 'systemd_exec_directive_count':unit_exec,'preset_enable_count':preset_enable,'preset_disable_count':preset_disable,
 'exact_path_manifest_verified':True,'exact_package_hashes_verified':True,'complete_file_classification':True,
 'configuration_files_executed':False,'service_files_executed':False,'service_control_executed':False,
 'user_service_scope_only':True,'maintainer_scripts_review_complete':True,'configuration_service_review_complete':True,
 'elf_runtime_review_complete':False,'userspace_apply_review_complete':False,
 'next_stage':'current-userspace-elf-runtime-review-preflight','apply_ready':False,'apply_authorized':False,
 'class_counts':dict(sorted(class_counts.items())),
}
summary_out.write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n',encoding='utf-8')
for value in (len(actual_config),sum(x['kind']=='regular' for x in actual_config.values()),len(actual_service),sum(x['kind']=='regular' for x in actual_service.values()),len(packages),class_counts.get('systemd-user-service',0),class_counts.get('systemd-user-preset',0),0,0): print(value)
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-userspace-configuration-service-review-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
target_kernel=$CONFIRM_TARGET_KERNEL
expected_configuration_path_count=$EXPECTED_CONFIGURATION_PATH_COUNT
configuration_path_count=$CONFIGURATION_PATH_COUNT
configuration_file_count=$CONFIGURATION_FILE_COUNT
expected_service_path_count=$EXPECTED_SERVICE_PATH_COUNT
service_path_count=$SERVICE_PATH_COUNT
service_file_count=$SERVICE_FILE_COUNT
reviewed_package_count=$REVIEWED_PACKAGE_COUNT
systemd_user_service_count=$SYSTEMD_USER_SERVICE_COUNT
systemd_user_preset_count=$SYSTEMD_USER_PRESET_COUNT
systemd_system_service_count=$SYSTEMD_SYSTEM_SERVICE_COUNT
rc_script_count=$RC_SCRIPT_COUNT
package_payloads_inspected=true
payload_path_review_complete=true
maintainer_scripts_review_complete=true
configuration_service_review_complete=$CONFIGURATION_SERVICE_REVIEW_COMPLETE
elf_runtime_review_complete=false
userspace_apply_review_complete=false
package_transaction_executed=false
maintainer_script_executed=false
configuration_file_executed=false
service_file_executed=false
service_control_executed=false
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
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-userspace-configuration-service-review-preflight-${timestamp}.tar.gz"
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
    bash -n "$MAINTAINER_REVIEW_SCRIPT" || { error 'maintainer-review script has invalid syntax'; return 2; }
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    mkdir -p "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if values=$(validate_accepted_records); then
        EXPECTED_CONFIGURATION_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '1p')
        EXPECTED_SERVICE_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '2p')
        record_pass 'the accepted maintainer review and configuration/service policy bind the exact 90-path inspection'
    else
        record_failure 'the accepted maintainer review or configuration/service policy is unsafe or inconsistent'
    fi
    [ "$CONFIRM_CANDIDATES_SHA256" = 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 ] \
        && [ "$CONFIRM_TARGET_KERNEL" = 6.18.42 ] \
        && record_pass 'the explicit candidate digest and target kernel match the reviewed configuration/service boundary' \
        || record_failure 'the explicit candidate digest or target kernel does not match the reviewed configuration/service boundary'
    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and service-sensitive state were captured before static review'
    else
        record_failure 'the initial package or service-sensitive state could not be captured safely'
    fi

    nested_root=$OUTPUT_DIR/nested
    nested_dir=$nested_root/maintainer-review
    mkdir -p "$nested_root"
    printf 'Running a fresh non-installing maintainer-script review before configuration and service classification...\n'
    bash "$MAINTAINER_REVIEW_SCRIPT" \
        --target slackware-current \
        --confirm-candidates-sha256 "$CONFIRM_CANDIDATES_SHA256" \
        --confirm-target-kernel "$CONFIRM_TARGET_KERNEL" \
        --output-dir "$nested_dir" \
        > "$OUTPUT_DIR/maintainer-review.stdout.log" 2> "$OUTPUT_DIR/maintainer-review.stderr.log" || nested_exit=$?
    printf '%s\n' "$nested_exit" > "$OUTPUT_DIR/maintainer-review.exit"
    cat "$OUTPUT_DIR/maintainer-review.stdout.log"
    [ -s "$OUTPUT_DIR/maintainer-review.stderr.log" ] && cat "$OUTPUT_DIR/maintainer-review.stderr.log" >&2 || true
    [ "$nested_exit" -eq 0 ] \
        && record_pass 'the embedded maintainer review completed without installing packages or executing payload files' \
        || record_failure "the embedded maintainer review failed with exit code $nested_exit"
    [ "$nested_exit" -eq 0 ] && validate_nested_maintainer "$nested_dir" \
        && record_pass 'the fresh maintainer evidence still contains the exact accepted 68 packages, 37 scripts, and 90 sensitive paths' \
        || record_failure 'the maintainer, package, or sensitive-path identities changed before static review'
    [ "$nested_exit" -eq 0 ] && create_and_verify_nested_archive "$nested_root" "$nested_dir" \
        && record_pass 'the nested maintainer-review archive and portable sidecar verify inside the configuration/service evidence' \
        || record_failure 'the nested maintainer-review archive or portable sidecar is invalid'

    if values=$(analyze_configuration_service_payload "$nested_dir/nested/payload-review" "$OUTPUT_DIR/configuration-service-inventory.tsv" "$OUTPUT_DIR/configuration-service-summary.json" "$OUTPUT_DIR/reviewed-files"); then
        CONFIGURATION_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '1p')
        CONFIGURATION_FILE_COUNT=$(printf '%s\n' "$values" | sed -n '2p')
        SERVICE_PATH_COUNT=$(printf '%s\n' "$values" | sed -n '3p')
        SERVICE_FILE_COUNT=$(printf '%s\n' "$values" | sed -n '4p')
        REVIEWED_PACKAGE_COUNT=$(printf '%s\n' "$values" | sed -n '5p')
        SYSTEMD_USER_SERVICE_COUNT=$(printf '%s\n' "$values" | sed -n '6p')
        SYSTEMD_USER_PRESET_COUNT=$(printf '%s\n' "$values" | sed -n '7p')
        SYSTEMD_SYSTEM_SERVICE_COUNT=$(printf '%s\n' "$values" | sed -n '8p')
        RC_SCRIPT_COUNT=$(printf '%s\n' "$values" | sed -n '9p')
        record_pass 'the exact 46 configuration and 44 service path records match the reviewed package boundary'
        record_pass 'all 19 contributing cached archives retain their exact package identities'
        record_pass 'all 21 regular configuration files are completely classified and statically valid'
        record_pass 'all 27 regular service files are completely classified and statically valid'
        record_pass 'all 26 units and the single preset remain confined to systemd user scope with no system or rc service payload'
    else
        record_failure 'one or more configuration or service payloads contain changed, unsafe, or unclassified content'
    fi
    if [ "$FAILURE_COUNT" -eq 0 ] \
        && [ "$CONFIGURATION_PATH_COUNT" -eq "$EXPECTED_CONFIGURATION_PATH_COUNT" ] \
        && [ "$SERVICE_PATH_COUNT" -eq "$EXPECTED_SERVICE_PATH_COUNT" ] \
        && [ "$SYSTEMD_SYSTEM_SERVICE_COUNT" -eq 0 ] \
        && [ "$RC_SCRIPT_COUNT" -eq 0 ]; then
        CONFIGURATION_SERVICE_REVIEW_COMPLETE=true
        NEXT_STAGE=current-userspace-elf-runtime-review-preflight
        record_pass 'the configuration/service review is complete while ELF runtime and userspace apply review remain pending'
    else
        CONFIGURATION_SERVICE_REVIEW_COMPLETE=false
        NEXT_STAGE=manual-review-required
        record_failure 'the configuration/service boundary could not be completed safely'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and service-sensitive state were captured after static review' \
        || record_failure 'the final package or service-sensitive state could not be captured safely'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during configuration/service review' \
        || record_failure 'the installed package database changed during configuration/service review'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged during configuration/service review' \
        || record_failure 'the service-sensitive system state changed during review'

    [ "$FAILURE_COUNT" -eq 0 ] || { CONFIGURATION_SERVICE_REVIEW_COMPLETE=false; NEXT_STAGE=manual-review-required; }
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current configuration/service review result: candidates=%s, config-paths=%s, config-files=%s, service-paths=%s, service-files=%s, user-units=%s, user-presets=%s, system-units=%s, rc-scripts=%s, configuration-service-review-complete=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "$CONFIRM_CANDIDATES_SHA256" "$CONFIGURATION_PATH_COUNT" "$CONFIGURATION_FILE_COUNT" "$SERVICE_PATH_COUNT" "$SERVICE_FILE_COUNT" "$SYSTEMD_USER_SERVICE_COUNT" "$SYSTEMD_USER_PRESET_COUNT" "$SYSTEMD_SYSTEM_SERVICE_COUNT" "$RC_SCRIPT_COUNT" "$CONFIGURATION_SERVICE_REVIEW_COMPLETE" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
