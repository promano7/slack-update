#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${ROLLBACK_PLAN_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-rollback-source-and-plan-preflight}
DEFAULT_SOURCE_STAGING_ROOT=${ROLLBACK_PLAN_SOURCE_STAGING_ROOT:-/var/tmp/slack-update-rollback-source}
DIAGNOSTIC_RECORD=${ROLLBACK_PLAN_DIAGNOSTIC_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-inventory-20260806-corrected-diagnostic.json}
FAILED_PREFLIGHT_RECORD=${ROLLBACK_PLAN_FAILED_PREFLIGHT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-20260806-failed-diagnostic.json}
GENINITRD_RECORD=${ROLLBACK_PLAN_GENINITRD_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json}
SIGNING_KEY=${ROLLBACK_PLAN_SIGNING_KEY:-$REPOSITORY_ROOT/tests/fixtures/reference/keys/slackware-security.gpg.asc}
PLAN_POLICY=${ROLLBACK_PLAN_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-policy.json}
PLAN_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-source-and-plan-preflight.sh

TARGET=
OUTPUT_DIR=
SOURCE_STAGING_DIR=
SOURCE_PACKAGE=
SOURCE_SIGNATURE=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_INVENTORY_EVIDENCE_SHA256=
CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_SOURCE_PLAN_SHA256=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
ASSERTION_LOG=
ROOT_PREFIX=
PACKAGE_DATABASE=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL=
ARCHITECTURE=
ROOT_UUID=
ROOT_SOURCE=
SOURCE_ACQUISITION=unchecked
SOURCE_PACKAGE_SHA256=
SOURCE_SIGNATURE_SHA256=
SOURCE_PACKAGE_SIZE=0
SOURCE_SIGNATURE_SIZE=0
SIGNATURE_FINGERPRINT=
SIGNATURE_PRIMARY_FINGERPRINT=
KERNEL_MEMBER=
KERNEL_SHA256=
KERNEL_SIZE=0
MODULE_FILE_COUNT=0
MODULE_PAYLOAD_BYTES=0
MODULE_MANIFEST_SHA256=
SPACE_STATE=unchecked
SPACE_RESERVE_BYTES=0
ESTIMATED_INITRD_BYTES=0
SPACE_REQUIRED_BYTES=0
SPACE_AVAILABLE_BYTES=0
APPLY_READY=false
NEXT_STAGE=current-rollback-source-and-plan-manual-review
REVIEWED_BOUNDARY_VALID=false
LIVE_BOUNDARY_VALID=false
SOURCE_ACQUIRED=false
SOURCE_SIGNATURE_VALID=false
SOURCE_PACKAGE_VALID=false
SPACE_BUDGET_VALID=false
INITRD_PROJECTION_VALID=false
GRUB_PROJECTION_VALID=false
APPLY_PLAN_VALID=false
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-inventory-evidence-sha256 SHA256 \\
                     --confirm-failed-preflight-evidence-sha256 SHA256 \\
                     --confirm-active-kernel VERSION \\
                     --confirm-rollback-kernel VERSION \\
                     --confirm-source-plan-sha256 SHA256 [options]

Acquire or reuse the exact historical Slackware package and detached signature,
verify them with the reviewed Slackware signing key, inspect the package without
extracting it into the installed system, and project the complete rollback
reconstruction plan. This preflight does not install packages, restore files,
run depmod or mkinitrd, modify GRUB, change the default boot entry, or reboot.

Required options:
      --target slackware-current
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-inventory-evidence-sha256 SHA256
      --confirm-failed-preflight-evidence-sha256 SHA256
      --confirm-active-kernel VERSION
      --confirm-rollback-kernel VERSION
      --confirm-source-plan-sha256 SHA256

Optional arguments:
      --source-package PATH     Reuse one pre-staged exact package
      --source-signature PATH   Reuse its detached signature; requires package
      --source-staging-dir PATH Download/reuse source files under this directory
      --output-dir PATH         Store evidence under an absolute, new directory
  -h, --help                    Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }
record_skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }

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
            --confirm-inventory-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_INVENTORY_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-failed-preflight-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-active-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
            --confirm-rollback-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
            --confirm-source-plan-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_SOURCE_PLAN_SHA256=${2,,}; shift 2 ;;
            --source-package) [ "$#" -ge 2 ] || return 1; SOURCE_PACKAGE=$2; shift 2 ;;
            --source-signature) [ "$#" -ge 2 ] || return 1; SOURCE_SIGNATURE=$2; shift 2 ;;
            --source-staging-dir) [ "$#" -ge 2 ] || return 1; SOURCE_STAGING_DIR=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_INVENTORY_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_SOURCE_PLAN_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_ACTIVE_KERNEL" || return 1
    is_safe_kernel_version "$CONFIRM_ROLLBACK_KERNEL" || return 1
    [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
    if [ -n "$SOURCE_PACKAGE" ] || [ -n "$SOURCE_SIGNATURE" ]; then
        [ -n "$SOURCE_PACKAGE" ] && [ -n "$SOURCE_SIGNATURE" ] || return 1
        case "$SOURCE_PACKAGE" in /*) ;; *) return 1 ;; esac
        case "$SOURCE_SIGNATURE" in /*) ;; *) return 1 ;; esac
    fi
    if [ -n "$SOURCE_STAGING_DIR" ]; then case "$SOURCE_STAGING_DIR" in /*) ;; *) return 1 ;; esac; fi
    if [ -n "$OUTPUT_DIR" ]; then case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac; fi
}

rooted() { printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
require_regular_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
file_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
file_size() { stat -Lc '%s' -- "$1"; }
policy_value() {
    python3 - "$PLAN_POLICY" "$1" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value=value[part]
if isinstance(value, bool): print(str(value).lower())
else: print(value)
PY
}

validate_reviewed_boundary() {
    python3 - "$PLAN_POLICY" "$PLAN_SCRIPT" "$DIAGNOSTIC_RECORD" "$FAILED_PREFLIGHT_RECORD" "$GENINITRD_RECORD" "$SIGNING_KEY" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_INVENTORY_EVIDENCE_SHA256" \
        "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" \
        "$CONFIRM_SOURCE_PLAN_SHA256" <<'PY'
import hashlib, json, pathlib, sys
(policy_path, script_path, diagnostic_path, failed_path, geninitrd_path, key_path, host, fqdn,
 inventory_archive, failed_archive, active, rollback, confirmed_scope) = sys.argv[1:]
def regular(path):
    p=pathlib.Path(path)
    if not p.is_file() or p.is_symlink(): raise SystemExit(1)
    return p
def sha(path): return hashlib.sha256(regular(path).read_bytes()).hexdigest()
policy=json.loads(regular(policy_path).read_text(encoding='utf-8'))
diagnostic=json.loads(regular(diagnostic_path).read_text(encoding='utf-8'))
failed=json.loads(regular(failed_path).read_text(encoding='utf-8'))
geninitrd=json.loads(regular(geninitrd_path).read_text(encoding='utf-8'))
script_sha=sha(script_path); diagnostic_sha=sha(diagnostic_path); failed_sha=sha(failed_path)
geninitrd_sha=sha(geninitrd_path); key_sha=sha(key_path)
scope=(
 'operation=current-rollback-source-and-plan-preflight-revision-1\n'
 'target=slackware-current\n'
 f'hostname_short={host}\n'
 f'hostname_fqdn={fqdn}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'root_uuid={policy.get("required_root_uuid", "")}\n'
 f'inventory_archive_sha256={inventory_archive}\n'
 f'failed_preflight_archive_sha256={failed_archive}\n'
 f'diagnostic_record_sha256={diagnostic_sha}\n'
 f'failed_preflight_record_sha256={failed_sha}\n'
 f'geninitrd_record_sha256={geninitrd_sha}\n'
 f'signing_key_sha256={key_sha}\n'
 f'plan_script_sha256={script_sha}\n'
).encode()
calculated=hashlib.sha256(scope).hexdigest()
vector=geninitrd.get('current_command_vector', [])
checks=[
 policy.get('scenario') == 'current-rollback-source-and-plan-preflight-revision-1',
 policy.get('target') == 'slackware-current', policy.get('reviewed') is True,
 policy.get('required_hostname_short') == host, policy.get('required_hostname_fqdn') == fqdn,
 policy.get('active_kernel') == active, policy.get('rollback_kernel') == rollback,
 policy.get('inventory_archive_sha256') == inventory_archive,
 policy.get('failed_preflight_archive_sha256') == failed_archive,
 policy.get('diagnostic_record_sha256') == diagnostic_sha,
 policy.get('failed_preflight_record_sha256') == failed_sha,
 policy.get('geninitrd_record_sha256') == geninitrd_sha,
 policy.get('signing_key_sha256') == key_sha,
 policy.get('plan_script_sha256') == script_sha,
 policy.get('source_plan_scope_sha256') == calculated == confirmed_scope,
 policy.get('repository_metadata_refresh_allowed') is False,
 policy.get('package_installation_allowed') is False,
 policy.get('initrd_generation_allowed') is False,
 policy.get('grub_mutation_allowed') is False,
 policy.get('reboot_execution_allowed') is False,
 diagnostic.get('archive_sha256') == inventory_archive,
 diagnostic.get('active_kernel') == active,
 diagnostic.get('rollback_kernel') == rollback,
 diagnostic.get('rollback_modules', {}).get('corrected_state') == 'depmod-metadata-only-placeholder',
 diagnostic.get('rollback_modules', {}).get('module_file_count') == 0,
 diagnostic.get('system_state_unchanged') is True,
 failed.get('archive_sha256') == failed_archive,
 failed.get('executed_script_sha256') == '37756428b0fbb9e106ce1853414f8032d803fdc6bb9ec9fef642ed82bd4c8a74',
 failed.get('system_state_mutated') is False,
 geninitrd.get('accepted') is True,
 geninitrd.get('current_command_vector') == vector,
 len(vector) >= 12 and vector[0] == 'mkinitrd' and '-k' in vector and vector[vector.index('-k')+1] == rollback,
]
if not all(checks): raise SystemExit(1)
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
    (cd "$PACKAGE_DATABASE" && find . -maxdepth 1 -type f -printf '%P\n' | LC_ALL=C sort) > "$output"
}

capture_path_state() {
    local path=$1 output=$2 metadata digest target type
    if [ -L "$path" ]; then
        target=$(readlink -- "$path") || return 1
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|symlink|%s|%s|\n' "${path#$ROOT_PREFIX}" "$target" "$metadata" >> "$output"
    elif [ -f "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(file_sha256 "$path") || return 1
        printf '%s|regular||%s|%s\n' "${path#$ROOT_PREFIX}" "$metadata" "$digest" >> "$output"
    elif [ -d "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|directory||%s|\n' "${path#$ROOT_PREFIX}" "$metadata" >> "$output"
        find "$path" -mindepth 1 -printf '%P|%y|%m|%u|%g|%s|%T@\n' | LC_ALL=C sort >> "$output" || return 1
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
        /proc/cmdline /proc/sys/kernel/osrelease \
        /boot/vmlinuz-generic "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL" "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL" \
        /boot/initrd-generic.img "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img" "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img" \
        /boot/grub/grub.cfg /boot/grub/grubenv \
        /etc/default/geninitrd /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh /var/lib/pkgtools/setup/setup.01.mkinitrd \
        "/lib/modules/$CONFIRM_ACTIVE_KERNEL" "/lib/modules/$CONFIRM_ROLLBACK_KERNEL" \
        "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}"; do
        capture_path_state "$(rooted "$path")" "$output" || return 1
    done
}

validate_live_boundary() {
    local grubenv_list=$OUTPUT_DIR/grubenv.list
    local grubenv_path
    grubenv_path=$(rooted /boot/grub/grubenv)
    if [ -e "$grubenv_path" ] || [ -L "$grubenv_path" ]; then
        [ -f "$grubenv_path" ] && [ ! -L "$grubenv_path" ] || return 1
        grub-editenv "$grubenv_path" list > "$grubenv_list" 2>/dev/null || return 1
    else
        : > "$grubenv_list"
    fi
    python3 - "$PLAN_POLICY" "$ROOT_PREFIX" "$PACKAGE_DATABASE" "$OUTPUT_DIR/packages.before.txt" \
        "$OUTPUT_DIR/package-names.before.txt" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" "$RUNNING_KERNEL" \
        "$ARCHITECTURE" "$ROOT_UUID" "$ROOT_SOURCE" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" \
        "$grubenv_list" "$OUTPUT_DIR/live-boundary.json" "$OUTPUT_DIR/live-boundary-checks.tsv" <<'PY'
import hashlib, json, pathlib, shlex, sys
(policy_path, prefix, package_db, package_snapshot, names_snapshot, host, fqdn, running,
 arch, root_uuid, root_source, active, rollback, grubenv_path, output, checks_output) = sys.argv[1:]
policy=json.load(open(policy_path, encoding='utf-8'))
root=pathlib.Path(prefix) if prefix else pathlib.Path('/')
def path(value): return root / value.lstrip('/')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def exact_regular(p, expected_sha, expected_size):
    return p.is_file() and not p.is_symlink() and p.stat().st_uid == 0 and p.stat().st_gid == 0 and p.stat().st_size == expected_size and sha(p) == expected_sha
checks=[]
def add(key, ok, detail): checks.append({'key':key,'ok':bool(ok),'detail':detail})
add('hostname-short', host == policy['required_hostname_short'], f'hostname short name is {host}')
add('hostname-fqdn', fqdn == policy['required_hostname_fqdn'], f'hostname FQDN is {fqdn}')
add('running-kernel', running == active == policy['active_kernel'], f'running kernel is {running}')
add('architecture', arch == 'x86_64', f'architecture is {arch}')
add('root-uuid', root_uuid == policy['required_root_uuid'], f'root UUID is {root_uuid}')
add('root-source', bool(root_source), f'root source is {root_source or "missing"}')
osrelease=path('/proc/sys/kernel/osrelease'); cmdline=path('/proc/cmdline')
add('osrelease', osrelease.is_file() and osrelease.read_text().strip() == active, 'kernel osrelease matches the active kernel')
add('cmdline-readable', cmdline.is_file(), 'kernel command line is readable')
try: tokens=shlex.split(cmdline.read_text().strip()) if cmdline.is_file() else []
except Exception: tokens=[]
add('cmdline-boot-image', 'BOOT_IMAGE=/boot/vmlinuz-generic' in tokens, 'BOOT_IMAGE uses /boot/vmlinuz-generic')
add('cmdline-root-uuid', f'root=UUID={root_uuid}' in tokens, 'kernel command line uses the reviewed root UUID')
active_art=policy['active_artifacts']
add('active-kernel-file', exact_regular(path(f'/boot/vmlinuz-{active}'), active_art['kernel_sha256'], active_art['kernel_size']), 'active versioned kernel matches reviewed size and SHA-256')
add('active-initrd-file', exact_regular(path(f'/boot/initrd-{active}.img'), active_art['initrd_sha256'], active_art['initrd_size']), 'active versioned initrd matches reviewed size and SHA-256')
add('generic-kernel-link', path('/boot/vmlinuz-generic').is_symlink() and path('/boot/vmlinuz-generic').readlink().as_posix() == f'vmlinuz-{active}', 'generic kernel link targets the active version')
add('generic-initrd-link', path('/boot/initrd-generic.img').is_symlink() and path('/boot/initrd-generic.img').readlink().as_posix() == f'initrd-{active}.img', 'generic initrd link targets the active version')
active_modules=path(f'/lib/modules/{active}')
add('active-modules', active_modules.is_dir() and not active_modules.is_symlink() and any(active_modules.rglob('*')), 'active module tree is populated')
add('rollback-kernel-absent', not path(f'/boot/vmlinuz-{rollback}').exists() and not path(f'/boot/vmlinuz-{rollback}').is_symlink(), 'rollback kernel is absent before reconstruction')
add('rollback-initrd-absent', not path(f'/boot/initrd-{rollback}.img').exists() and not path(f'/boot/initrd-{rollback}.img').is_symlink(), 'rollback initrd is absent before reconstruction')
rollback_modules=path(f'/lib/modules/{rollback}')
add('rollback-placeholder-directory', rollback_modules.is_dir() and not rollback_modules.is_symlink(), 'rollback placeholder is a real directory')
expected=policy['rollback_placeholder_entries']
observed={}
if rollback_modules.is_dir() and not rollback_modules.is_symlink():
    for item in rollback_modules.iterdir():
        if item.is_symlink(): kind='symlink'
        elif item.is_dir(): kind='directory'
        elif item.is_file(): kind='regular'
        else: kind='other'
        st=item.lstat()
        observed[item.name]={'kind':kind,'mode':st.st_mode & 0o777,'uid':st.st_uid,'gid':st.st_gid,'size':st.st_size}
add('rollback-placeholder-entry-set', set(observed) == set(expected), 'rollback placeholder contains only the reviewed depmod metadata names')
metadata_ok=set(observed) == set(expected)
if metadata_ok:
    for name, spec in expected.items():
        item=observed[name]
        metadata_ok = metadata_ok and item['kind'] == spec['kind'] and item['mode'] == int(spec['mode'],8) and item['uid'] == 0 and item['gid'] == 0
        if spec['kind'] == 'regular': metadata_ok = metadata_ok and item['size'] == spec['size']
add('rollback-placeholder-metadata', metadata_ok, 'rollback placeholder types, modes, owners, and regular-file sizes match the reviewed metadata-only state')
module_suffixes=('.ko','.ko.gz','.ko.xz','.ko.zst')
module_objects=[]
if rollback_modules.is_dir() and not rollback_modules.is_symlink():
    module_objects=[p for p in rollback_modules.rglob('*') if p.is_file() and p.name.endswith(module_suffixes)]
add('rollback-module-objects-absent', not module_objects, 'rollback placeholder contains no kernel module objects')
for policy_key, check_key, live in [
 ('geninitrd_policy','geninitrd-policy','/etc/default/geninitrd'), ('geninitrd','geninitrd','/usr/sbin/geninitrd'),
 ('generator','generator','/usr/share/mkinitrd/mkinitrd_command_generator.sh'),
 ('setup','setup','/var/lib/pkgtools/setup/setup.01.mkinitrd'), ('active_grub','active-grub','/boot/grub/grub.cfg')]:
    item=policy[policy_key]
    add(check_key, exact_regular(path(live), item['sha256'], item['size']), f'{live} matches reviewed size and SHA-256')
fragment=path(f'/etc/grub.d/41_slackware_rollback_{rollback.replace(".", "_")}')
add('rollback-grub-fragment-absent', not fragment.exists() and not fragment.is_symlink(), 'rollback GRUB fragment is absent before reconstruction')
package_snapshot_path=pathlib.Path(package_snapshot); names_snapshot_path=pathlib.Path(names_snapshot)
add('installed-package-count', len(names_snapshot_path.read_text().splitlines()) == policy['installed_package_count'], 'installed package count matches the reviewed boundary')
add('package-database-snapshot', sha(package_snapshot_path) == policy['package_database_snapshot_sha256'], 'package database snapshot SHA-256 matches')
add('package-name-snapshot', sha(names_snapshot_path) == policy['package_name_snapshot_sha256'], 'package-name snapshot SHA-256 matches')
for forbidden in policy['forbidden_package_records']:
    candidate=pathlib.Path(package_db)/forbidden
    add(f'forbidden-package-{forbidden}', not candidate.exists() and not candidate.is_symlink(), f'forbidden rollback package record {forbidden} is absent')
grubenv=pathlib.Path(grubenv_path).read_text(encoding='utf-8',errors='replace').splitlines()
add('grub-next-entry-clear', not any(line.startswith('next_entry=') and line != 'next_entry=' for line in grubenv), 'GRUB has no pending one-time next_entry')
all_ok=all(item['ok'] for item in checks)
data={
 'active_kernel':active,'rollback_kernel':rollback,'root_uuid':root_uuid,'root_source':root_source,
 'rollback_module_state':'depmod-metadata-only-placeholder','rollback_kernel_present':False,
 'rollback_initrd_present':False,'rollback_grub_fragment_present':False,
 'installed_package_count':policy['installed_package_count'],'validated':all_ok,'checks':checks,
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True)+'\n', encoding='utf-8')
with pathlib.Path(checks_output).open('w', encoding='utf-8') as stream:
    for item in checks:
        detail=item['detail'].replace('\t',' ').replace('\n',' ')
        stream.write(f"{item['key']}\t{'PASS' if item['ok'] else 'FAIL'}\t{detail}\n")
raise SystemExit(0 if all_ok else 1)
PY
}

record_live_boundary_results() {
    local status=0 key result detail
    validate_live_boundary || status=$?
    if [ ! -s "$OUTPUT_DIR/live-boundary-checks.tsv" ]; then
        record_failure 'the live-boundary validator failed before producing individual checks'
        return 1
    fi
    while IFS=$'\t' read -r key result detail; do
        if [ "$result" = PASS ]; then
            record_pass "live boundary [$key]: $detail"
        else
            record_failure "live boundary [$key]: $detail"
        fi
    done < "$OUTPUT_DIR/live-boundary-checks.tsv"
    return "$status"
}

acquire_source() {
    local expected expected_sig package_url signature_url tmp_package tmp_signature
    expected=$(policy_value expected_package_filename) || return 1
    expected_sig="$expected.asc"
    if [ -n "$SOURCE_PACKAGE" ]; then
        [ "${SOURCE_PACKAGE##*/}" = "$expected" ] && [ "${SOURCE_SIGNATURE##*/}" = "$expected_sig" ] || return 1
        require_regular_file "$SOURCE_PACKAGE" && require_regular_file "$SOURCE_SIGNATURE" || return 1
        SOURCE_ACQUISITION=pre-staged
        return 0
    fi
    [ -n "$SOURCE_STAGING_DIR" ] || SOURCE_STAGING_DIR="$DEFAULT_SOURCE_STAGING_ROOT/$CONFIRM_ROLLBACK_KERNEL"
    [ ! -L "$SOURCE_STAGING_DIR" ] || return 1
    mkdir -m 0700 -p -- "$SOURCE_STAGING_DIR" || return 1
    SOURCE_PACKAGE="$SOURCE_STAGING_DIR/$expected"
    SOURCE_SIGNATURE="$SOURCE_STAGING_DIR/$expected_sig"
    if [ -e "$SOURCE_PACKAGE" ] || [ -L "$SOURCE_PACKAGE" ] || [ -e "$SOURCE_SIGNATURE" ] || [ -L "$SOURCE_SIGNATURE" ]; then
        require_regular_file "$SOURCE_PACKAGE" && require_regular_file "$SOURCE_SIGNATURE" || return 1
        SOURCE_ACQUISITION=reused-staging
        return 0
    fi
    package_url=$(policy_value package_url) || return 1
    signature_url=$(policy_value signature_url) || return 1
    case "$package_url:$signature_url" in https://*:https://*) ;; *) return 1 ;; esac
    tmp_package="$SOURCE_PACKAGE.partial.$$"
    tmp_signature="$SOURCE_SIGNATURE.partial.$$"
    trap 'rm -f -- "$tmp_package" "$tmp_signature"' RETURN
    curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --show-error \
        --output "$tmp_package" "$package_url" || return 1
    curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --show-error \
        --output "$tmp_signature" "$signature_url" || return 1
    require_regular_file "$tmp_package" && require_regular_file "$tmp_signature" || return 1
    chmod 0600 "$tmp_package" "$tmp_signature" || return 1
    mv -- "$tmp_package" "$SOURCE_PACKAGE" || return 1
    mv -- "$tmp_signature" "$SOURCE_SIGNATURE" || return 1
    trap - RETURN
    SOURCE_ACQUISITION=downloaded-https
}

verify_source_signature() {
    local home status=$OUTPUT_DIR/gpg-status.txt expected result=0
    if [ "$TEST_MODE" = 1 ] && [ -n "${SLACK_UPDATE_TEST_SIGNATURE_MODE:-}" ]; then
        [ "$SLACK_UPDATE_TEST_SIGNATURE_MODE" = valid ] || return 1
        expected=$(policy_value signing_key_fingerprint) || return 1
        SIGNATURE_FINGERPRINT=${SLACK_UPDATE_TEST_SIGNING_FINGERPRINT:-}
        SIGNATURE_PRIMARY_FINGERPRINT=${SLACK_UPDATE_TEST_PRIMARY_FINGERPRINT:-}
        [ -n "$SIGNATURE_FINGERPRINT" ] && [ "$SIGNATURE_PRIMARY_FINGERPRINT" = "$expected" ] || return 1
        SOURCE_PACKAGE_SHA256=$(file_sha256 "$SOURCE_PACKAGE") || return 1
        SOURCE_SIGNATURE_SHA256=$(file_sha256 "$SOURCE_SIGNATURE") || return 1
        SOURCE_PACKAGE_SIZE=$(file_size "$SOURCE_PACKAGE") || return 1
        SOURCE_SIGNATURE_SIZE=$(file_size "$SOURCE_SIGNATURE") || return 1
        [ "$SOURCE_PACKAGE_SIZE" -gt 0 ] && [ "$SOURCE_SIGNATURE_SIZE" -gt 0 ] || return 1
        [ "$SOURCE_PACKAGE_SHA256" = "$(policy_value expected_package_sha256)" ] || return 1
        [ "$SOURCE_SIGNATURE_SHA256" = "$(policy_value expected_signature_sha256)" ] || return 1
        printf 'test-mode signature verification bypass\n' > "$OUTPUT_DIR/gpg-import.log"
        printf '[GNUPG:] VALIDSIG %s 0 0 0 0 0 0 0 0 %s\n' \
            "$SIGNATURE_FINGERPRINT" "$SIGNATURE_PRIMARY_FINGERPRINT" > "$status"
        : > "$OUTPUT_DIR/gpg-verify.log"
        return 0
    fi
    home=$(mktemp -d /tmp/slack-update-gpg.XXXXXX) || return 1
    chmod 0700 "$home" || { rm -rf -- "$home"; return 1; }
    printf '%s\n' "$home" > "$OUTPUT_DIR/gpg-home-path.txt"
    gpg --batch --homedir "$home" --import "$SIGNING_KEY" > "$OUTPUT_DIR/gpg-import.log" 2>&1 || result=1
    if [ "$result" -eq 0 ]; then
        gpg --batch --homedir "$home" --status-fd 1 --verify "$SOURCE_SIGNATURE" "$SOURCE_PACKAGE" \
            > "$status" 2> "$OUTPUT_DIR/gpg-verify.log" || result=1
    fi
    if [ "$result" -eq 0 ]; then
        expected=$(policy_value signing_key_fingerprint) || result=1
    fi
    if [ "$result" -eq 0 ]; then
        local signature_identities identity_count
        signature_identities=$(awk '$1=="[GNUPG:]" && $2=="VALIDSIG" {primary=($12=="" ? $3 : $12); print $3 "\t" primary}' "$status" | LC_ALL=C sort -u)
        identity_count=$(printf '%s\n' "$signature_identities" | awk 'NF {count++} END {print count+0}')
        [ "$identity_count" -eq 1 ] || result=1
        if [ "$result" -eq 0 ]; then
            IFS=$'\t' read -r SIGNATURE_FINGERPRINT SIGNATURE_PRIMARY_FINGERPRINT <<< "$signature_identities"
            [ "$SIGNATURE_PRIMARY_FINGERPRINT" = "$expected" ] || result=1
        fi
    fi
    if [ "$result" -eq 0 ]; then
        SOURCE_PACKAGE_SHA256=$(file_sha256 "$SOURCE_PACKAGE") || result=1
        SOURCE_SIGNATURE_SHA256=$(file_sha256 "$SOURCE_SIGNATURE") || result=1
        SOURCE_PACKAGE_SIZE=$(file_size "$SOURCE_PACKAGE") || result=1
        SOURCE_SIGNATURE_SIZE=$(file_size "$SOURCE_SIGNATURE") || result=1
        [ "$SOURCE_PACKAGE_SIZE" -gt 0 ] && [ "$SOURCE_SIGNATURE_SIZE" -gt 0 ] || result=1
        [ "$SOURCE_PACKAGE_SHA256" = "$(policy_value expected_package_sha256)" ] || result=1
        [ "$SOURCE_SIGNATURE_SHA256" = "$(policy_value expected_signature_sha256)" ] || result=1
    fi
    gpgconf --homedir "$home" --kill gpg-agent >/dev/null 2>&1 || true
    rm -rf -- "$home"
    return "$result"
}

inspect_source_package() {
    python3 - "$SOURCE_PACKAGE" "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/source-package.json" \
        "$OUTPUT_DIR/source-module-manifest.txt" <<'PY'
import hashlib, json, pathlib, posixpath, stat, tarfile, sys
package=pathlib.Path(sys.argv[1]); version=sys.argv[2]; summary=pathlib.Path(sys.argv[3]); modules_out=pathlib.Path(sys.argv[4])
expected=f'kernel-generic-{version}-x86_64-1.txz'
if package.name != expected or not package.is_file() or package.is_symlink(): raise SystemExit(1)
def normalize(name):
    while name.startswith('./'): name=name[2:]
    if not name or name.startswith('/'): raise SystemExit(1)
    value=posixpath.normpath(name)
    if value in ('','.','..') or value.startswith('../'): raise SystemExit(1)
    return value
def safe_link(name,target):
    if not target or target.startswith('/'): return False
    value=posixpath.normpath(posixpath.join(posixpath.dirname(name),target))
    return value not in ('','.','..') and not value.startswith('../')
def stream_hash(archive, member):
    stream=archive.extractfile(member)
    if stream is None: raise SystemExit(1)
    h=hashlib.sha256(); size=0
    for chunk in iter(lambda: stream.read(1024*1024), b''): h.update(chunk); size += len(chunk)
    if size <= 0: raise SystemExit(1)
    return h.hexdigest(), size
seen=set(); kernels=[]; modules=[]; module_bytes=0; member_count=0; doinst=None
with tarfile.open(package, 'r:*') as archive:
    for member in archive:
        member_count += 1
        name=normalize(member.name)
        if name in seen: raise SystemExit(1)
        seen.add(name)
        if member.ischr() or member.isblk() or member.isfifo(): raise SystemExit(1)
        if member.issym() or member.islnk():
            if not safe_link(name, member.linkname): raise SystemExit(1)
            continue
        if not (member.isfile() or member.isdir()): raise SystemExit(1)
        if member.isfile() and (member.mode & (stat.S_ISUID | stat.S_ISGID | stat.S_IWOTH)): raise SystemExit(1)
        if member.isfile() and (member.uid != 0 or member.gid != 0): raise SystemExit(1)
        if member.isfile() and name in (f'boot/vmlinuz-{version}', f'boot/vmlinuz-generic-{version}'):
            digest,size=stream_hash(archive,member); kernels.append({'member':name,'sha256':digest,'size':size,'mode':oct(member.mode & 0o777)})
        prefix=f'lib/modules/{version}/'
        if member.isfile() and name.startswith(prefix):
            digest,size=stream_hash(archive,member)
            rel=name[len(prefix):]
            modules.append({'path':rel,'sha256':digest,'size':size,'mode':oct(member.mode & 0o777)})
            module_bytes += size
        if member.isfile() and name == 'install/doinst.sh':
            digest,size=stream_hash(archive,member); doinst={'sha256':digest,'size':size,'mode':oct(member.mode & 0o777)}
if len(kernels) != 1 or not modules: raise SystemExit(1)
module_objects=[m for m in modules if m['path'].startswith('kernel/') and m['path'].endswith(('.ko','.ko.gz','.ko.xz','.ko.zst'))]
if not module_objects: raise SystemExit(1)
modules=sorted(modules,key=lambda x:x['path'])
modules_out.write_text(''.join(f"{m['sha256']}  {m['size']}  {m['mode']}  {m['path']}\n" for m in modules),encoding='utf-8')
package_hash=hashlib.sha256()
with package.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024*1024),b''): package_hash.update(chunk)
data={
 'filename':package.name,'package_sha256':package_hash.hexdigest(),'package_size':package.stat().st_size,
 'member_count':member_count,'kernel':kernels[0],'module_member_count':len(modules),
 'module_object_count':len(module_objects),'module_payload_bytes':module_bytes,'doinst':doinst,
 'paths_safe':True,'ownership_safe':True,'modes_safe':True,
}
summary.write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
    IFS=$'\t' read -r KERNEL_MEMBER KERNEL_SHA256 KERNEL_SIZE MODULE_FILE_COUNT MODULE_PAYLOAD_BYTES < <(
        python3 - "$OUTPUT_DIR/source-package.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
print(d['kernel']['member'],d['kernel']['sha256'],d['kernel']['size'],d['module_member_count'],d['module_payload_bytes'],sep='\t')
PY
    )
    MODULE_MANIFEST_SHA256=$(file_sha256 "$OUTPUT_DIR/source-module-manifest.txt") || return 1
    [ -n "$KERNEL_MEMBER" ] && [ "$KERNEL_SIZE" -gt 0 ] && [ "$MODULE_FILE_COUNT" -gt 0 ] \
        && is_sha256 "$MODULE_MANIFEST_SHA256"
}

space_sample() {
    local path=$1 available device
    if [ "$TEST_MODE" = 1 ]; then
        available=${SLACK_UPDATE_TEST_SPACE_AVAILABLE_BYTES:-10737418240}
        device=${SLACK_UPDATE_TEST_SPACE_DEVICE:-test-root}
    else
        [ -d "$path" ] && [ ! -L "$path" ] || return 1
        device=$(stat -c '%d' -- "$path") || return 1
        available=$(df -PB1 --output=avail -- "$path" | awk 'NR == 2 { print $1 }') || return 1
    fi
    case "$available" in ''|*[!0-9]*) return 1 ;; esac
    printf '%s\t%s\n' "$device" "$available"
}

evaluate_space_budget() {
    local boot_device boot_available modules_device modules_available staging_device staging_available
    local backup_device backup_available grub_size boot_component modules_component staging_component backup_component
    SPACE_RESERVE_BYTES=$(policy_value minimum_free_space_reserve_bytes) || return 1
    ESTIMATED_INITRD_BYTES=$(policy_value estimated_initrd_bytes) || return 1
    grub_size=$(policy_value active_grub.size) || return 1
    case "$SPACE_RESERVE_BYTES:$ESTIMATED_INITRD_BYTES:$grub_size" in *[!0-9:]*) return 1 ;; esac
    IFS=$'\t' read -r boot_device boot_available < <(space_sample "$(rooted /boot)") || return 1
    IFS=$'\t' read -r modules_device modules_available < <(space_sample "$(rooted /lib/modules)") || return 1
    IFS=$'\t' read -r staging_device staging_available < <(space_sample "$(rooted /var/tmp)") || return 1
    IFS=$'\t' read -r backup_device backup_available < <(space_sample "$(rooted /var/lib)") || return 1
    boot_component=$((KERNEL_SIZE + ESTIMATED_INITRD_BYTES + (grub_size * 2)))
    modules_component=$MODULE_PAYLOAD_BYTES
    staging_component=$((KERNEL_SIZE + MODULE_PAYLOAD_BYTES + (grub_size * 2)))
    backup_component=$((grub_size + 4096))
    python3 - "$OUTPUT_DIR/space-budget.json" "$SPACE_RESERVE_BYTES" \
        "$boot_device" "$boot_available" "$boot_component" \
        "$modules_device" "$modules_available" "$modules_component" \
        "$staging_device" "$staging_available" "$staging_component" \
        "$backup_device" "$backup_available" "$backup_component" <<'PY'
import json, pathlib, sys
out=pathlib.Path(sys.argv[1]); reserve=int(sys.argv[2]); values=sys.argv[3:]
labels=('boot-final-artifacts','module-destination','private-apply-staging','rollback-backup')
groups={}
for label, offset in zip(labels, range(0, len(values), 3)):
    device, available, component = values[offset:offset+3]
    item=groups.setdefault(device, {'available_bytes':int(available),'component_bytes':0,'components':[]})
    item['available_bytes']=min(item['available_bytes'], int(available))
    item['component_bytes'] += int(component)
    item['components'].append({'name':label,'bytes':int(component)})
for item in groups.values():
    item['required_bytes']=item['component_bytes'] + reserve
    item['sufficient']=item['available_bytes'] >= item['required_bytes']
state='sufficient' if all(item['sufficient'] for item in groups.values()) else 'insufficient'
data={
    'state':state,'reserve_bytes_per_filesystem':reserve,
    'aggregate_required_bytes':sum(item['required_bytes'] for item in groups.values()),
    'minimum_available_bytes':min(item['available_bytes'] for item in groups.values()),
    'filesystems':groups,
}
out.write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
print(state, data['aggregate_required_bytes'], data['minimum_available_bytes'], sep='\t')
PY
    IFS=$'\t' read -r SPACE_STATE SPACE_REQUIRED_BYTES SPACE_AVAILABLE_BYTES < <(
        python3 - "$OUTPUT_DIR/space-budget.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
print(d['state'],d['aggregate_required_bytes'],d['minimum_available_bytes'],sep='\t')
PY
    )
    [ "$SPACE_STATE" = sufficient ]
}

project_initrd_command() {
    python3 - "$GENINITRD_RECORD" "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/projected-mkinitrd-command.json" \
        "$OUTPUT_DIR/projected-mkinitrd-command.sh" <<'PY'
import json, pathlib, shlex, sys
record=json.load(open(sys.argv[1],encoding='utf-8')); version=sys.argv[2]
vector=list(record['current_command_vector'])
if vector[0] != 'mkinitrd' or '-k' not in vector or vector[vector.index('-k')+1] != version or '-o' not in vector: raise SystemExit(1)
vector[vector.index('-o')+1]=f'/boot/initrd-{version}.img'
pathlib.Path(sys.argv[3]).write_text(json.dumps({'command_vector':vector,'executed':False,'output':f'/boot/initrd-{version}.img'},indent=2,sort_keys=True)+'\n',encoding='utf-8')
pathlib.Path(sys.argv[4]).write_text('# Projected only; do not execute before explicit authorization.\n'+shlex.join(vector)+'\n',encoding='utf-8')
PY
}

project_grub_entry() {
    local grub fragment_name
    grub=$(rooted /boot/grub/grub.cfg)
    fragment_name="41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}"
    python3 - "$grub" "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/projected-grub-menuentry.cfg" \
        "$OUTPUT_DIR/projected-$fragment_name" <<'PY'
import pathlib,re,shlex,sys
source=pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').splitlines(); version=sys.argv[2]
start=None; depth=0; entry=[]
for i,raw in enumerate(source):
    stripped=raw.strip()
    if start is None and stripped.startswith('menuentry '): start=i
    if start is not None:
        entry.append(raw); depth += raw.count('{') - raw.count('}')
        if depth == 0 and len(entry)>1: break
if not entry or depth != 0: raise SystemExit(1)
header=entry[0]
try: title=shlex.split(header[len(header)-len(header.lstrip()):].strip())[1]
except Exception: title='Slackware generic'
indent=header[:len(header)-len(header.lstrip())]
entry[0]=f"{indent}menuentry 'Slackware GNU/Linux (rollback {version})' --id 'slackware-rollback-{version}' {{"
linux_count=initrd_count=0
for i,line in enumerate(entry):
    stripped=line.strip()
    if re.match(r'^linux(?:efi)?\s+',stripped):
        parts=shlex.split(stripped); parts[1]=f'/boot/vmlinuz-{version}'; entry[i]=line[:len(line)-len(line.lstrip())]+shlex.join(parts); linux_count+=1
    elif re.match(r'^initrd(?:efi)?\s+',stripped):
        parts=shlex.split(stripped); parts[1]=f'/boot/initrd-{version}.img'; entry[i]=line[:len(line)-len(line.lstrip())]+shlex.join(parts); initrd_count+=1
if linux_count != 1 or initrd_count != 1: raise SystemExit(1)
body='\n'.join(entry)+'\n'
if f'/boot/vmlinuz-{version}' not in body or f'/boot/initrd-{version}.img' not in body: raise SystemExit(1)
pathlib.Path(sys.argv[3]).write_text(body,encoding='utf-8')
fragment='#!/bin/sh\n\ncat <<\'EOF_SLACK_UPDATE_ROLLBACK\'\n'+body+'EOF_SLACK_UPDATE_ROLLBACK\n'
pathlib.Path(sys.argv[4]).write_text(fragment,encoding='utf-8')
PY
    chmod 0755 "$OUTPUT_DIR/projected-$fragment_name" || return 1
    bash -n "$OUTPUT_DIR/projected-$fragment_name" || return 1
    grub-script-check "$OUTPUT_DIR/projected-grub-menuentry.cfg" >/dev/null 2>&1 || return 1
}

write_apply_plan() {
    local fragment_name="41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}"
    python3 - "$OUTPUT_DIR/reconstruction-plan.json" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" \
        "$SOURCE_PACKAGE_SHA256" "$SOURCE_SIGNATURE_SHA256" "$SIGNATURE_FINGERPRINT" "$SIGNATURE_PRIMARY_FINGERPRINT" "$KERNEL_MEMBER" \
        "$KERNEL_SHA256" "$KERNEL_SIZE" "$MODULE_FILE_COUNT" "$MODULE_PAYLOAD_BYTES" "$MODULE_MANIFEST_SHA256" \
        "$SPACE_STATE" "$SPACE_RESERVE_BYTES" "$ESTIMATED_INITRD_BYTES" "$SPACE_REQUIRED_BYTES" "$SPACE_AVAILABLE_BYTES" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ROOT_UUID" "$ROOT_SOURCE" \
        "$OUTPUT_DIR/projected-mkinitrd-command.json" "$OUTPUT_DIR/projected-$fragment_name" \
        "$CONFIRM_INVENTORY_EVIDENCE_SHA256" "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" \
        "$CONFIRM_SOURCE_PLAN_SHA256" <<'PY'
import json,pathlib,sys
(out,pkg,sig,pkgsha,sigsha,signing_fingerprint,primary_fingerprint,kernel_member,kernel_sha,kernel_size,module_count,module_bytes,module_manifest_sha,
 space_state,space_reserve,estimated_initrd,space_required,space_available,active,rollback,root_uuid,root_source,mkinitrd_path,fragment_path,inventory_sha,failed_sha,scope_sha)=sys.argv[1:]
mkinitrd=json.load(open(mkinitrd_path,encoding='utf-8'))['command_vector']
fragment_name=f'41_slackware_rollback_{rollback.replace(".","_")}'
data={
 'scenario':'current-rollback-source-and-plan-preflight-revision-1','target':'slackware-current',
 'active_kernel':active,'rollback_kernel':rollback,'root_uuid':root_uuid,'root_source':root_source,
 'inventory_archive_sha256':inventory_sha,'failed_preflight_archive_sha256':failed_sha,'source_plan_scope_sha256':scope_sha,
 'source':{'package_path':pkg,'signature_path':sig,'package_sha256':pkgsha,'signature_sha256':sigsha,'signing_fingerprint':signing_fingerprint,'valid_primary_fingerprint':primary_fingerprint},
 'payload':{'kernel_member':kernel_member,'kernel_destination':f'/boot/vmlinuz-{rollback}','kernel_sha256':kernel_sha,'kernel_size':int(kernel_size),'module_destination':f'/lib/modules/{rollback}','module_member_count':int(module_count),'module_payload_bytes':int(module_bytes),'module_manifest_sha256':module_manifest_sha},
 'space_budget':{'state':space_state,'reserve_bytes_per_filesystem':int(space_reserve),'estimated_initrd_bytes':int(estimated_initrd),'aggregate_required_bytes':int(space_required),'minimum_available_bytes':int(space_available)},
 'initrd':{'destination':f'/boot/initrd-{rollback}.img','command_vector':mkinitrd},
 'grub':{'fragment_destination':f'/etc/grub.d/{fragment_name}','fragment_mode':'0755','entry_id':f'slackware-rollback-{rollback}','default_must_remain':'0','active_default_kernel':'/boot/vmlinuz-generic'},
 'ordered_actions':[
  {'order':1,'id':'revalidate-boundary-and-source-hashes'},
  {'order':2,'id':'create-owner-only-backup-and-extraction-directories'},
  {'order':3,'id':'back-up-depmod-metadata-placeholder-and-active-grub-config'},
  {'order':4,'id':'extract-only-reviewed-kernel-and-module-tree-to-private-staging'},
  {'order':5,'id':'verify-staged-kernel-and-complete-module-manifest'},
  {'order':6,'id':'install-versioned-rollback-kernel-and-module-tree'},
  {'order':7,'id':'run-depmod-for-rollback-kernel'},
  {'order':8,'id':'run-reviewed-versioned-mkinitrd-command'},
  {'order':9,'id':'install-explicit-rollback-grub-fragment'},
  {'order':10,'id':'generate-and-validate-temporary-grub-config'},
  {'order':11,'id':'prove-default-remains-active-6.18.42-entry'},
  {'order':12,'id':'atomically-replace-grub-config-and-verify-final-state'},
 ],
 'rollback_limits':['do-not-change-generic-kernel-link','do-not-change-generic-initrd-link','do-not-change-grub-default','retain-source-package-signature-and-backups'],
 'repository_metadata_refreshed':False,'package_installation_performed':False,'package_database_mutated':False,
 'depmod_executed':False,'initrd_generated':False,'grub_mutated':False,'reboot_performed':False,
 'apply_ready':True,'apply_authorized':False,'next_stage':'current-rollback-reconstruction-authorized-apply-review',
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
    cat > "$OUTPUT_DIR/projected-apply-commands.txt" <<EOF_COMMANDS
# Projected only. These commands are not authorized by this preflight.
# The authorized apply wrapper must revalidate every hash and state invariant.
ROLLBACK_VERSION='$CONFIRM_ROLLBACK_KERNEL'
SOURCE_PACKAGE='$SOURCE_PACKAGE'
SOURCE_SIGNATURE='$SOURCE_SIGNATURE'
EXPECTED_PACKAGE_SHA256='$SOURCE_PACKAGE_SHA256'
EXPECTED_SIGNATURE_SHA256='$SOURCE_SIGNATURE_SHA256'
EXPECTED_KERNEL_SHA256='$KERNEL_SHA256'
EXPECTED_MODULE_MANIFEST_SHA256='$MODULE_MANIFEST_SHA256'
KERNEL_MEMBER='$KERNEL_MEMBER'
BACKUP_ROOT='/var/lib/slack-update/rollback-backups/$CONFIRM_ROLLBACK_KERNEL'
STAGE_ROOT='/var/tmp/slack-update-rollback-apply/$CONFIRM_ROLLBACK_KERNEL'
sha256sum -- "\$SOURCE_PACKAGE" "\$SOURCE_SIGNATURE"
install -d -o root -g root -m 0700 "\$BACKUP_ROOT" "\$STAGE_ROOT"
cp -a -- /lib/modules/$CONFIRM_ROLLBACK_KERNEL "\$BACKUP_ROOT/modules.metadata-placeholder.before"
cp -a -- /boot/grub/grub.cfg "\$BACKUP_ROOT/grub.cfg.before"
tar -xJf "\$SOURCE_PACKAGE" -C "\$STAGE_ROOT" -- "$KERNEL_MEMBER" "lib/modules/$CONFIRM_ROLLBACK_KERNEL"
sha256sum -- "\$STAGE_ROOT/$KERNEL_MEMBER"
install -o root -g root -m 0644 "\$STAGE_ROOT/$KERNEL_MEMBER" /boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL
mv -- /lib/modules/$CONFIRM_ROLLBACK_KERNEL "\$BACKUP_ROOT/modules.metadata-placeholder.original"
mv -- "\$STAGE_ROOT/lib/modules/$CONFIRM_ROLLBACK_KERNEL" /lib/modules/$CONFIRM_ROLLBACK_KERNEL
chown -R root:root /lib/modules/$CONFIRM_ROLLBACK_KERNEL
depmod -a $CONFIRM_ROLLBACK_KERNEL
$(tail -n 1 "$OUTPUT_DIR/projected-mkinitrd-command.sh")
install -o root -g root -m 0755 '$OUTPUT_DIR/projected-$fragment_name' /etc/grub.d/$fragment_name
grub-mkconfig -o "\$STAGE_ROOT/grub.cfg.new"
grub-script-check "\$STAGE_ROOT/grub.cfg.new"
# Verify that selector 0 still resolves to /boot/vmlinuz-generic and /boot/initrd-generic.img.
install -o root -g root -m 0600 "\$STAGE_ROOT/grub.cfg.new" /boot/grub/grub.cfg.new
mv -f -- /boot/grub/grub.cfg.new /boot/grub/grub.cfg
EOF_COMMANDS
}

write_analysis() {
    python3 - "$OUTPUT_DIR/source-and-plan-analysis.json" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" "$RUNNING_KERNEL" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ROOT_UUID" "$ROOT_SOURCE" "$SOURCE_ACQUISITION" \
        "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" "$SOURCE_PACKAGE_SHA256" "$SOURCE_SIGNATURE_SHA256" \
        "$SOURCE_PACKAGE_SIZE" "$SOURCE_SIGNATURE_SIZE" "$SIGNATURE_FINGERPRINT" "$SIGNATURE_PRIMARY_FINGERPRINT" "$KERNEL_MEMBER" \
        "$KERNEL_SHA256" "$KERNEL_SIZE" "$MODULE_FILE_COUNT" "$MODULE_PAYLOAD_BYTES" "$MODULE_MANIFEST_SHA256" \
        "$SPACE_STATE" "$SPACE_RESERVE_BYTES" "$ESTIMATED_INITRD_BYTES" "$SPACE_REQUIRED_BYTES" "$SPACE_AVAILABLE_BYTES" "$APPLY_READY" \
        "$NEXT_STAGE" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$CONFIRM_INVENTORY_EVIDENCE_SHA256" \
        "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_SOURCE_PLAN_SHA256" <<'PY'
import json,pathlib,sys
(out,host,fqdn,running,active,rollback,root_uuid,root_source,acquisition,pkg,sig,pkgsha,sigsha,
 pkgsize,sigsize,signing_fingerprint,primary_fingerprint,kernel_member,kernel_sha,kernel_size,module_count,module_bytes,module_manifest_sha,
 space_state,space_reserve,estimated_initrd,space_required,space_available,ready,next_stage,
 passes,failures,skips,inventory_sha,failed_sha,scope_sha)=sys.argv[1:]
data={
 'scenario':'current-rollback-source-and-plan-preflight-revision-1','target':'slackware-current','hostname_short':host,
 'hostname_fqdn':fqdn,'running_kernel':running,'active_kernel':active,'rollback_kernel':rollback,
 'root_uuid':root_uuid,'root_source':root_source,'inventory_archive_sha256':inventory_sha,
 'failed_preflight_archive_sha256':failed_sha,
 'source_plan_scope_sha256':scope_sha,'rollback_module_state':'depmod-metadata-only-placeholder',
 'source_acquisition':acquisition,'source_package':{'path':pkg,'sha256':pkgsha,'size':int(pkgsize or 0)},
 'source_signature':{'path':sig,'sha256':sigsha,'size':int(sigsize or 0),'signing_fingerprint':signing_fingerprint,'valid_fingerprint':primary_fingerprint},
 'payload':{'kernel_member':kernel_member,'kernel_sha256':kernel_sha,'kernel_size':int(kernel_size or 0),'module_member_count':int(module_count or 0),'module_payload_bytes':int(module_bytes or 0),'module_manifest_sha256':module_manifest_sha},
 'space_budget':{'state':space_state,'reserve_bytes_per_filesystem':int(space_reserve or 0),'estimated_initrd_bytes':int(estimated_initrd or 0),'aggregate_required_bytes':int(space_required or 0),'minimum_available_bytes':int(space_available or 0)},
 'repository_metadata_refreshed':False,'package_installation_performed':False,'package_database_mutated':False,
 'depmod_executed':False,'initrd_generated':False,'grub_mutated':False,'reboot_performed':False,
 'system_state_mutated':False,'source_staging_created':acquisition in ('downloaded-https','reused-staging'),
 'apply_ready':ready=='true','apply_authorized':False,'next_stage':next_stage,
 'assertions':{'passes':int(passes),'failures':int(failures),'skips':int(skips)},
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-rollback-source-and-plan-preflight-revision-1
target=$TARGET
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
hostname_short=$HOSTNAME_SHORT
hostname_fqdn=$HOSTNAME_FQDN
running_kernel=$RUNNING_KERNEL
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
rollback_module_state=depmod-metadata-only-placeholder
inventory_evidence_sha256=$CONFIRM_INVENTORY_EVIDENCE_SHA256
failed_preflight_evidence_sha256=$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256
source_plan_scope_sha256=$CONFIRM_SOURCE_PLAN_SHA256
source_acquisition=$SOURCE_ACQUISITION
source_package=$SOURCE_PACKAGE
source_package_sha256=$SOURCE_PACKAGE_SHA256
source_package_size=$SOURCE_PACKAGE_SIZE
source_signature=$SOURCE_SIGNATURE
source_signature_sha256=$SOURCE_SIGNATURE_SHA256
signature_fingerprint=$SIGNATURE_FINGERPRINT
signature_primary_fingerprint=$SIGNATURE_PRIMARY_FINGERPRINT
kernel_member=$KERNEL_MEMBER
kernel_sha256=$KERNEL_SHA256
kernel_size=$KERNEL_SIZE
module_member_count=$MODULE_FILE_COUNT
module_payload_bytes=$MODULE_PAYLOAD_BYTES
module_manifest_sha256=$MODULE_MANIFEST_SHA256
space_state=$SPACE_STATE
space_reserve_bytes=$SPACE_RESERVE_BYTES
estimated_initrd_bytes=$ESTIMATED_INITRD_BYTES
space_required_bytes=$SPACE_REQUIRED_BYTES
space_available_bytes=$SPACE_AVAILABLE_BYTES
repository_metadata_refreshed=false
package_installation_performed=false
package_database_mutated=false
depmod_executed=false
initrd_generated=false
grub_mutated=false
reboot_performed=false
apply_ready=$APPLY_READY
apply_authorized=false
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

publish_evidence() {
    local parent base archive owner group
    parent=$(dirname -- "$OUTPUT_DIR")
    base=$(basename -- "$OUTPUT_DIR")
    archive="$parent/$base.tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum -- "$base.tar.gz" > "$base.tar.gz.sha256") || return 1
    owner=${SUDO_USER:-}
    if [ -z "$owner" ] || [ "$owner" = root ]; then owner=${ROLLBACK_PLAN_EVIDENCE_OWNER:-promano}; fi
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    chmod 0600 "$archive" "$archive.sha256" || return 1
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(file_sha256 "$archive")"
    printf 'Copy evidence command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$archive" "$owner" "$(basename -- "$archive")"
    printf 'Copy sidecar command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$archive.sha256" "$owner" "$(basename -- "$archive.sha256")"
    printf 'Copy package command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$SOURCE_PACKAGE" "$owner" "$(basename -- "$SOURCE_PACKAGE")"
    printf 'Copy signature command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$SOURCE_SIGNATURE" "$owner" "$(basename -- "$SOURCE_SIGNATURE")"
    printf 'Verify evidence command: cd /home/%s && sha256sum -c %q\n' "$owner" "$(basename -- "$archive.sha256")"
}

main() {
    local timestamp slackware_version
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    if [ "$TEST_MODE" = 1 ]; then
        ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
        PATH=${SLACK_UPDATE_TEST_PATH:-$PATH}; export PATH
        HOSTNAME_SHORT=${SLACK_UPDATE_TEST_HOSTNAME_SHORT:-}
        HOSTNAME_FQDN=${SLACK_UPDATE_TEST_HOSTNAME_FQDN:-}
        RUNNING_KERNEL=${SLACK_UPDATE_TEST_RUNNING_KERNEL:-}
        ARCHITECTURE=${SLACK_UPDATE_TEST_ARCHITECTURE:-}
        ROOT_UUID=${SLACK_UPDATE_TEST_ROOT_UUID:-}
        ROOT_SOURCE=${SLACK_UPDATE_TEST_ROOT_SOURCE:-}
    else
        ROOT_PREFIX=
        HOSTNAME_SHORT=$(hostname -s) || return 2
        HOSTNAME_FQDN=$(hostname -f) || return 2
        RUNNING_KERNEL=$(uname -r) || return 2
        ARCHITECTURE=$(uname -m) || return 2
        ROOT_UUID=$(findmnt -n -o UUID /) || return 2
        ROOT_SOURCE=$(findmnt -n -o SOURCE /) || return 2
    fi
    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk bash chmod cmp curl date df find findmnt gpg gpgconf grep grub-editenv grub-script-check hostname id mkdir mktemp mv python3 readlink rm sha256sum sort stat tar tee uname wc; do
        if [ "$TEST_MODE" = 1 ] && { [ "$command_name" = findmnt ] || [ "$command_name" = hostname ] || [ "$command_name" = uname ]; }; then continue; fi
        command -v "$command_name" >/dev/null 2>&1 || { error "required command missing: $command_name"; return 2; }
    done
    for reviewed_file in "$DIAGNOSTIC_RECORD" "$FAILED_PREFLIGHT_RECORD" "$GENINITRD_RECORD" "$SIGNING_KEY" "$PLAN_POLICY" "$PLAN_SCRIPT"; do
        require_regular_file "$reviewed_file" || { error "reviewed file is missing or unsafe: $reviewed_file"; return 2; }
    done
    bash -n "$PLAN_SCRIPT" || { error 'source and plan preflight has invalid shell syntax'; return 2; }
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

    if validate_reviewed_boundary; then
        REVIEWED_BOUNDARY_VALID=true
        record_pass 'the corrected inventory, failed step-87 evidence, reviewed signing key, historical initrd command, exact code, and revision scope are bound'
    else
        record_failure 'the corrected diagnostic boundary, failed step-87 evidence, or explicit revision scope is missing, changed, or mismatched'
    fi

    capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and rollback-sensitive state were captured before source verification' \
        || record_failure 'the package database or rollback-sensitive state could not be captured before source verification'

    if record_live_boundary_results; then
        LIVE_BOUNDARY_VALID=true
    fi

    if acquire_source; then
        SOURCE_ACQUIRED=true
        record_pass "the exact historical package and detached signature are available through $SOURCE_ACQUISITION"
    else
        record_failure 'the exact historical package and signature could not be acquired or reused safely'
    fi

    if [ "$SOURCE_ACQUIRED" = true ]; then
        if require_regular_file "$SOURCE_PACKAGE" && require_regular_file "$SOURCE_SIGNATURE" && verify_source_signature; then
            SOURCE_SIGNATURE_VALID=true
            record_pass 'the detached signature is valid under the exact reviewed Slackware primary-key fingerprint'
        else
            record_failure 'the historical package signature is invalid, untrusted, missing, or ambiguous'
        fi
    else
        record_skip 'signature verification requires a safely acquired package and detached signature'
    fi

    if [ "$SOURCE_SIGNATURE_VALID" = true ]; then
        if inspect_source_package; then
            SOURCE_PACKAGE_VALID=true
            record_pass 'the signed package safely supplies one versioned kernel image and a complete non-empty 6.18.40 module payload'
        else
            record_failure 'the signed package layout, kernel identity, module payload, ownership, modes, or archive paths are unsafe'
        fi
    else
        record_skip 'package payload inspection requires a valid detached signature'
    fi

    if [ "$SOURCE_PACKAGE_VALID" = true ]; then
        if evaluate_space_budget; then
            SPACE_BUDGET_VALID=true
            record_pass 'the conservative per-filesystem reconstruction space budget is sufficient'
        else
            record_failure 'the kernel, module, initrd, staging, backup, and reserve space budget is insufficient or unavailable'
        fi
    else
        record_skip 'space-budget evaluation requires the inspected kernel and module payload sizes'
    fi

    if [ "$REVIEWED_BOUNDARY_VALID" = true ]; then
        if project_initrd_command; then
            INITRD_PROJECTION_VALID=true
            record_pass 'the accepted 6.18.40 mkinitrd vector was projected to the versioned rollback initrd without execution'
        else
            record_failure 'the historical accepted initrd command cannot be projected exactly for the rollback'
        fi
    else
        record_skip 'initrd projection requires the reviewed revision boundary'
    fi

    if [ "$LIVE_BOUNDARY_VALID" = true ]; then
        if project_grub_entry; then
            GRUB_PROJECTION_VALID=true
            record_pass 'a syntax-valid explicit rollback GRUB entry was projected without changing the active default'
        else
            record_failure 'the explicit rollback GRUB entry cannot be projected safely from the accepted active entry'
        fi
    else
        record_skip 'GRUB projection requires a fully valid live boot boundary'
    fi

    if [ "$REVIEWED_BOUNDARY_VALID" = true ] && [ "$LIVE_BOUNDARY_VALID" = true ] \
        && [ "$SOURCE_PACKAGE_VALID" = true ] && [ "$SPACE_BUDGET_VALID" = true ] \
        && [ "$INITRD_PROJECTION_VALID" = true ] && [ "$GRUB_PROJECTION_VALID" = true ]; then
        if write_apply_plan; then
            APPLY_PLAN_VALID=true
            record_pass 'the exact ordered reconstruction, verification, placeholder backup, and recovery plan was recorded without execution'
        else
            record_failure 'the reconstruction plan could not be recorded completely'
        fi
    else
        record_skip 'the complete reconstruction plan requires all independent source, live-boundary, space, initrd, and GRUB prerequisites'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and rollback-sensitive state were captured after planning' \
        || record_failure 'the final package database or rollback-sensitive state could not be captured'

    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/package-names.before.txt" "$OUTPUT_DIR/package-names.after.txt" \
        && record_pass 'the installed package database remained unchanged throughout source verification and planning' \
        || record_failure 'the installed package database changed during the non-installing preflight'

    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, rollback placeholder, initrd, GenInitrd, and GRUB state remained unchanged' \
        || record_failure 'rollback-sensitive installed-system state changed during the non-mutating preflight'

    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$APPLY_PLAN_VALID" = true ]; then
        APPLY_READY=true
        NEXT_STAGE=current-rollback-reconstruction-authorized-apply-review
        record_pass 'the signed source and exact reconstruction plan are ready for separate explicit apply authorization'
    else
        APPLY_READY=false
        NEXT_STAGE=current-rollback-source-and-plan-manual-review
        record_skip 'apply readiness is unavailable because one or more independent prerequisites failed'
    fi

    write_analysis || return 2
    write_summary || return 2
    chmod -R go-rwx "$OUTPUT_DIR" || return 2
    publish_evidence || return 2
    printf 'Result: %s (%d passes, %d failures, %d skips); apply_ready=%s; apply_authorized=false; next_stage=%s\n' \
        "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$APPLY_READY" "$NEXT_STAGE"
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
