#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${ROLLBACK_APPLY_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-rollback-reconstruction-authorized-apply}
APPLY_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-authorized-apply.sh
AUTH_REVIEW_SCRIPT=${ROLLBACK_APPLY_AUTH_REVIEW_SCRIPT:-$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-authorized-apply-review.sh}
AUTH_REVIEW_POLICY=${ROLLBACK_APPLY_AUTH_REVIEW_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-authorized-apply-review-policy.json}
ACCEPTED_AUTH_REVIEW=${ROLLBACK_APPLY_ACCEPTED_AUTH_REVIEW:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-authorized-apply-review-20260806-accepted.json}
APPLY_POLICY=${ROLLBACK_APPLY_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-authorized-apply-policy.json}
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${ROLLBACK_APPLY_ROOT_PREFIX:-}

TARGET=
EXECUTE_AUTHORIZED_APPLY=0
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_AUTHORIZATION_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_APPLY_CONTRACT_SHA256=
CONFIRM_APPLY_SCOPE_SHA256=
SOURCE_PACKAGE=
SOURCE_SIGNATURE=
OUTPUT_DIR=
ASSERTION_LOG=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
PACKAGE_DATABASE=
NESTED_OUTPUT_DIR=
BACKUP_ROOT=
STAGE_ROOT=
TRANSACTION_STARTED=false
APPLY_EXECUTED=false
APPLY_COMMITTED=false
ROLLBACK_ATTEMPTED=false
ROLLBACK_RESTORED=false
ROLLBACK_COMPLETE_ON_DISK=false
PAUSE_SAFE=false
PAUSE_SAFETY_REASON=not-evaluated
NEXT_STAGE=current-rollback-reconstruction-authorized-apply-manual-review
KERNEL_INSTALLED=false
PLACEHOLDER_MOVED=false
MODULES_INSTALLED=false
INITRD_CREATED=false
FRAGMENT_INSTALLED=false
GRUB_REPLACED=false
BEFORE_GRUB_SHA256=
BEFORE_SENSITIVE_SHA256=
BEFORE_PACKAGES_SHA256=
BASELINE_CAPTURED=false
LIVE_BOUNDARY_VALID=false
SIGNAL_STATUS=0
FINALIZED=false

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current --execute-authorized-apply \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-authorization-evidence-sha256 SHA256 \\
                     --confirm-active-kernel VERSION \\
                     --confirm-rollback-kernel VERSION \\
                     --confirm-apply-contract-sha256 SHA256 \\
                     --confirm-apply-scope-sha256 SHA256 \\
                     --source-package PATH \\
                     --source-signature PATH [options]

Apply the exact authorized optional rollback reconstruction and immediately
verify the complete on-disk result. The transaction restores only the reviewed
versioned 6.18.40 kernel and module tree, generates its versioned initrd, adds
one explicit GRUB rollback entry, proves that 6.18.42 remains the running and
default selection, and does not reboot or refresh Slackware-current metadata.

A successful result reports pause_safe=true and may be followed by a normal
poweroff. Any failure triggers a best-effort rollback to the captured 6.18.42
baseline; poweroff is safe only when the final output also reports
pause_safe=true.

Required options:
      --target slackware-current
      --execute-authorized-apply
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-authorization-evidence-sha256 SHA256
      --confirm-active-kernel VERSION
      --confirm-rollback-kernel VERSION
      --confirm-apply-contract-sha256 SHA256
      --confirm-apply-scope-sha256 SHA256
      --source-package PATH
      --source-signature PATH

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
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
            --execute-authorized-apply) EXECUTE_AUTHORIZED_APPLY=$((EXECUTE_AUTHORIZED_APPLY + 1)); shift ;;
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-authorization-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_AUTHORIZATION_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-active-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
            --confirm-rollback-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
            --confirm-apply-contract-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_APPLY_CONTRACT_SHA256=${2,,}; shift 2 ;;
            --confirm-apply-scope-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_APPLY_SCOPE_SHA256=${2,,}; shift 2 ;;
            --source-package) [ "$#" -ge 2 ] || return 1; SOURCE_PACKAGE=$2; shift 2 ;;
            --source-signature) [ "$#" -ge 2 ] || return 1; SOURCE_SIGNATURE=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || return 1
    [ "$EXECUTE_AUTHORIZED_APPLY" -eq 1 ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_AUTHORIZATION_EVIDENCE_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_ACTIVE_KERNEL" || return 1
    is_safe_kernel_version "$CONFIRM_ROLLBACK_KERNEL" || return 1
    [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
    is_sha256 "$CONFIRM_APPLY_CONTRACT_SHA256" || return 1
    is_sha256 "$CONFIRM_APPLY_SCOPE_SHA256" || return 1
    case "$SOURCE_PACKAGE" in /*) ;; *) return 1 ;; esac
    case "$SOURCE_SIGNATURE" in /*) ;; *) return 1 ;; esac
    if [ -n "$OUTPUT_DIR" ]; then case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac; fi
}

rooted() { printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
require_regular_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
file_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
file_size() { stat -Lc '%s' -- "$1"; }

json_value() {
    python3 - "$1" "$2" <<'PY'
import json,sys
value=json.load(open(sys.argv[1],encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value=value[part]
if isinstance(value,bool): print(str(value).lower())
elif isinstance(value,(dict,list)): print(json.dumps(value,separators=(',',':'),sort_keys=True))
else: print(value)
PY
}

policy_value() { json_value "$APPLY_POLICY" "$1"; }
accepted_value() { json_value "$ACCEPTED_AUTH_REVIEW" "$1"; }

validate_authorized_boundary() {
    python3 - "$APPLY_POLICY" "$APPLY_SCRIPT" "$ACCEPTED_AUTH_REVIEW" "$AUTH_REVIEW_SCRIPT" "$AUTH_REVIEW_POLICY" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_AUTHORIZATION_EVIDENCE_SHA256" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_APPLY_CONTRACT_SHA256" \
        "$CONFIRM_APPLY_SCOPE_SHA256" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" <<'PY'
import hashlib,json,pathlib,sys
(policy_path,script_path,accepted_path,review_script_path,review_policy_path,host,fqdn,evidence_sha,
 active,rollback,contract_sha,confirmed_scope,source_package,source_signature)=sys.argv[1:]
def regular(path):
    p=pathlib.Path(path)
    if not p.is_file() or p.is_symlink(): raise SystemExit(1)
    return p
def sha(path): return hashlib.sha256(regular(path).read_bytes()).hexdigest()
policy=json.loads(regular(policy_path).read_text(encoding='utf-8'))
accepted=json.loads(regular(accepted_path).read_text(encoding='utf-8'))
script_sha=sha(script_path)
accepted_sha=sha(accepted_path)
review_script_sha=sha(review_script_path)
review_policy_sha=sha(review_policy_path)
scope=(
 'operation=current-rollback-reconstruction-authorized-apply\n'
 'target=slackware-current\n'
 f'hostname_short={host}\n'
 f'hostname_fqdn={fqdn}\n'
 f'authorization_evidence_sha256={evidence_sha}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'apply_contract_sha256={contract_sha}\n'
 f'accepted_authorization_record_sha256={accepted_sha}\n'
 f'authorized_apply_script_sha256={script_sha}\n'
 f'source_package={source_package}\n'
 f'source_signature={source_signature}\n'
).encode()
calculated_scope=hashlib.sha256(scope).hexdigest()
checks=[
 policy.get('schema')==1,
 policy.get('scenario')=='current-rollback-reconstruction-authorized-apply',
 policy.get('reviewed') is True,
 policy.get('expected_apply_script_sha256')==script_sha,
 policy.get('accepted_authorization_record_sha256')==accepted_sha,
 policy.get('accepted_authorization_archive_sha256')==evidence_sha,
 policy.get('apply_contract_sha256')==contract_sha,
 policy.get('confirmation_scope_sha256')==confirmed_scope==calculated_scope,
 policy.get('authorization_review_script_sha256')==review_script_sha,
 policy.get('authorization_review_policy_sha256')==review_policy_sha,
 accepted.get('accepted') is True,
 accepted.get('archive_sha256')==evidence_sha,
 accepted.get('target')=='slackware-current',
 accepted.get('hostname_short')==host==policy.get('hostname_short'),
 accepted.get('hostname_fqdn')==fqdn==policy.get('hostname_fqdn'),
 accepted.get('active_kernel')==active==policy.get('active_kernel'),
 accepted.get('rollback_kernel')==rollback==policy.get('rollback_kernel'),
 accepted.get('apply_contract_sha256')==contract_sha,
 accepted.get('apply_ready') is True,
 accepted.get('apply_authorized') is True,
 accepted.get('apply_executed') is False,
 accepted.get('source',{}).get('package_path')==source_package,
 accepted.get('source',{}).get('signature_path')==source_signature,
 policy.get('repository_metadata_refresh_allowed') is False,
 policy.get('package_installation_allowed') is False,
 policy.get('package_database_mutation_allowed') is False,
 policy.get('reboot_execution_allowed') is False,
]
raise SystemExit(0 if all(checks) else 1)
PY
}

initialize_output() {
    local stamp
    if [ -z "$OUTPUT_DIR" ]; then
        stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
        OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/slackware-current-$stamp"
    fi
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
    install -d -m 0700 -- "$OUTPUT_DIR" || return 1
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG" || return 1
    NESTED_OUTPUT_DIR=$OUTPUT_DIR/nested-authorization-review
    BACKUP_ROOT=$(rooted "$(policy_value backup_root)") || return 1
    STAGE_ROOT=$(rooted "$(policy_value stage_root)") || return 1
}

resolve_package_database() {
    local first second
    first=$(rooted /var/lib/pkgtools/packages)
    second=$(rooted /var/log/packages)
    if [ -d "$first" ] && [ ! -L "$first" ]; then PACKAGE_DATABASE=$first
    elif [ -d "$second" ] && [ ! -L "$second" ]; then PACKAGE_DATABASE=$second
    elif [ -L "$second" ] && [ -d "$second" ]; then PACKAGE_DATABASE=$(readlink -f -- "$second")
    else return 1
    fi
    case "$PACKAGE_DATABASE" in "$ROOT_PREFIX"/*|/*) ;; *) return 1 ;; esac
}

capture_package_database() {
    local output=$1
    (
        cd "$PACKAGE_DATABASE" || exit 1
        find . -maxdepth 1 -type f -printf '%P\0' | LC_ALL=C sort -z |
            while IFS= read -r -d '' record; do sha256sum -- "$record"; done
    ) > "$output"
}

capture_sensitive_state() {
    local output=$1
    python3 - "$ROOT_PREFIX" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$output" <<'PY'
import hashlib,os,pathlib,stat,sys
root=pathlib.Path(sys.argv[1] or '/')
active,rollback=sys.argv[2],sys.argv[3]
out=pathlib.Path(sys.argv[4])
logical=[
 '/boot/vmlinuz-generic',f'/boot/vmlinuz-{active}',f'/boot/vmlinuz-{rollback}',
 '/boot/initrd-generic.img',f'/boot/initrd-{active}.img',f'/boot/initrd-{rollback}.img',
 '/boot/grub/grub.cfg',f'/etc/grub.d/41_slackware_rollback_{rollback.replace(".","_")}',
 f'/lib/modules/{rollback}', '/boot/initrd-tree',
]
def physical(item): return root / item.lstrip('/')
def digest(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
 return h.hexdigest()
def emit(logical_name,path):
 try: st=path.lstat()
 except FileNotFoundError:
  rows.append((logical_name,'missing','','','','',''))
  return
 mode=f'{stat.S_IMODE(st.st_mode):04o}'
 if stat.S_ISLNK(st.st_mode): rows.append((logical_name,'symlink',mode,str(st.st_uid),str(st.st_gid),str(st.st_size),os.readlink(path)))
 elif stat.S_ISREG(st.st_mode): rows.append((logical_name,'file',mode,str(st.st_uid),str(st.st_gid),str(st.st_size),digest(path)))
 elif stat.S_ISDIR(st.st_mode): rows.append((logical_name,'directory',mode,str(st.st_uid),str(st.st_gid),'',''))
 else: rows.append((logical_name,'other',mode,str(st.st_uid),str(st.st_gid),str(st.st_size),''))
rows=[]
for item in logical:
 p=physical(item); emit(item,p)
 if item in (f'/lib/modules/{rollback}','/boot/initrd-tree') and p.is_dir() and not p.is_symlink():
  for child in sorted(p.rglob('*'),key=lambda x:x.as_posix()):
   emit(item+'/'+child.relative_to(p).as_posix(),child)
out.write_text(''.join('\t'.join(row)+'\n' for row in rows),encoding='utf-8')
PY
}

run_fresh_authorization_review() {
    local source_plan_sha auth_scope
    source_plan_sha=$(policy_value source_plan_evidence_sha256) || return 1
    auth_scope=$(policy_value authorization_review_scope_sha256) || return 1
    bash "$AUTH_REVIEW_SCRIPT" \
        --target slackware-current \
        --confirm-hostname "$CONFIRM_HOSTNAME" \
        --confirm-hostname-fqdn "$CONFIRM_HOSTNAME_FQDN" \
        --confirm-source-plan-evidence-sha256 "$source_plan_sha" \
        --confirm-active-kernel "$CONFIRM_ACTIVE_KERNEL" \
        --confirm-rollback-kernel "$CONFIRM_ROLLBACK_KERNEL" \
        --confirm-authorization-review-sha256 "$auth_scope" \
        --source-package "$SOURCE_PACKAGE" \
        --source-signature "$SOURCE_SIGNATURE" \
        --output-dir "$NESTED_OUTPUT_DIR" \
        > "$OUTPUT_DIR/nested-authorization-review.log" 2>&1
}

validate_fresh_authorization_review() {
    python3 - "$NESTED_OUTPUT_DIR/summary.txt" "$NESTED_OUTPUT_DIR/apply-authorization.json" \
        "$CONFIRM_APPLY_CONTRACT_SHA256" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" <<'PY'
import json,pathlib,sys
summary_path,auth_path,contract,pkg,sig=sys.argv[1:]
summary=pathlib.Path(summary_path)
auth_file=pathlib.Path(auth_path)
if not summary.is_file() or summary.is_symlink() or not auth_file.is_file() or auth_file.is_symlink(): raise SystemExit(1)
values={}
for line in summary.read_text(encoding='utf-8').splitlines():
 if '=' in line:
  key,value=line.split('=',1); values[key]=value
auth=json.loads(auth_file.read_text(encoding='utf-8'))
checks=[
 values.get('result')=='PASS',values.get('failures')=='0',values.get('apply_ready')=='true',
 values.get('apply_authorized')=='true',values.get('apply_executed')=='false',
 values.get('apply_contract_sha256')==contract,
 auth.get('apply_ready') is True,auth.get('apply_authorized') is True,auth.get('apply_executed') is False,
 auth.get('apply_contract_sha256')==contract,
 auth.get('source_package',{}).get('path')==pkg,
 auth.get('source_signature',{}).get('path')==sig,
 auth.get('fresh_review',{}).get('fresh_preflight_result')=='PASS',
 auth.get('fresh_review',{}).get('system_state_mutated') is False,
]
raise SystemExit(0 if all(checks) else 1)
PY
}

validate_source_files() {
    require_regular_file "$SOURCE_PACKAGE" && require_regular_file "$SOURCE_SIGNATURE" || return 1
    [ "$(file_sha256 "$SOURCE_PACKAGE")" = "$(accepted_value source.package_sha256)" ] || return 1
    [ "$(file_sha256 "$SOURCE_SIGNATURE")" = "$(accepted_value source.signature_sha256)" ] || return 1
}

validate_pre_mutation_baseline() {
    local kernel rollback_kernel rollback_initrd fragment modules active_initrd active_kernel generic_kernel generic_initrd
    active_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL")
    active_initrd=$(rooted "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img")
    generic_kernel=$(rooted /boot/vmlinuz-generic)
    generic_initrd=$(rooted /boot/initrd-generic.img)
    rollback_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")
    rollback_initrd=$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")
    fragment=$(rooted "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}")
    modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    require_regular_file "$active_kernel" && require_regular_file "$active_initrd" || return 1
    [ -L "$generic_kernel" ] && [ "$(readlink -- "$generic_kernel")" = "vmlinuz-$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ -L "$generic_initrd" ] && [ "$(readlink -- "$generic_initrd")" = "initrd-$CONFIRM_ACTIVE_KERNEL.img" ] || return 1
    [ ! -e "$rollback_kernel" ] && [ ! -L "$rollback_kernel" ] || return 1
    [ ! -e "$rollback_initrd" ] && [ ! -L "$rollback_initrd" ] || return 1
    [ ! -e "$fragment" ] && [ ! -L "$fragment" ] || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    local initrd_tree
    initrd_tree=$(rooted /boot/initrd-tree)
    if [ -e "$initrd_tree" ] || [ -L "$initrd_tree" ]; then [ -d "$initrd_tree" ] && [ ! -L "$initrd_tree" ] || return 1; fi
    python3 - "$modules" <<'PY'
import pathlib,sys
root=pathlib.Path(sys.argv[1])
allowed={'misc','modules.alias','modules.alias.bin','modules.builtin.alias.bin','modules.builtin.bin','modules.builtin.modinfo','modules.dep','modules.dep.bin','modules.devname','modules.softdep','modules.symbols','modules.symbols.bin','modules.weakdep'}
entries={p.name for p in root.iterdir()}
if not entries.issubset(allowed): raise SystemExit(1)
if any(p.is_file() and p.name.startswith('kernel') for p in root.rglob('*')): raise SystemExit(1)
if any(p.suffix in {'.ko','.gz','.xz','.zst'} and '.ko' in p.name for p in root.rglob('*')): raise SystemExit(1)
PY
    kernel=$(uname -r 2>/dev/null || true)
    if [ "$TEST_MODE" = 1 ]; then kernel=${ROLLBACK_APPLY_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE_KERNEL}; fi
    [ "$kernel" = "$CONFIRM_ACTIVE_KERNEL" ]
}

create_transaction_directories() {
    [ ! -e "$BACKUP_ROOT" ] && [ ! -L "$BACKUP_ROOT" ] || return 1
    [ ! -e "$STAGE_ROOT" ] && [ ! -L "$STAGE_ROOT" ] || return 1
    install -d -o root -g root -m 0700 -- "$BACKUP_ROOT" "$STAGE_ROOT"
}

backup_initial_state() {
    local modules grub
    modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    grub=$(rooted /boot/grub/grub.cfg)
    cp -a -- "$modules" "$BACKUP_ROOT/modules.metadata-placeholder.before" || return 1
    cp -a -- "$grub" "$BACKUP_ROOT/grub.cfg.before" || return 1
    local initrd_tree
    initrd_tree=$(rooted /boot/initrd-tree)
    if [ -d "$initrd_tree" ] && [ ! -L "$initrd_tree" ]; then
        cp -a -- "$initrd_tree" "$BACKUP_ROOT/initrd-tree.before" || return 1
        printf 'present\n' > "$BACKUP_ROOT/initrd-tree.state" || return 1
    elif [ ! -e "$initrd_tree" ] && [ ! -L "$initrd_tree" ]; then
        printf 'absent\n' > "$BACKUP_ROOT/initrd-tree.state" || return 1
    else
        return 1
    fi
    file_sha256 "$BACKUP_ROOT/grub.cfg.before" > "$BACKUP_ROOT/grub.cfg.before.sha256" || return 1
}

extract_reviewed_payload() {
    tar -xJf "$SOURCE_PACKAGE" -C "$STAGE_ROOT" -- \
        "boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL" "lib/modules/$CONFIRM_ROLLBACK_KERNEL" \
        > "$OUTPUT_DIR/package-extraction.log" 2>&1
}

write_installed_module_manifest() {
    local root=$1 output=$2
    python3 - "$root" "$output" <<'PY'
import hashlib,os,pathlib,stat,sys
root=pathlib.Path(sys.argv[1]); out=pathlib.Path(sys.argv[2])
if not root.is_dir() or root.is_symlink(): raise SystemExit(1)
rows=[]
for p in sorted(root.rglob('*'),key=lambda x:x.relative_to(root).as_posix()):
 st=p.lstat(); rel=p.relative_to(root).as_posix()
 if stat.S_ISREG(st.st_mode):
  h=hashlib.sha256()
  with p.open('rb') as f:
   for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
  rows.append(f'{h.hexdigest()}  {st.st_size}  {oct(stat.S_IMODE(st.st_mode))}  {rel}\n')
 elif stat.S_ISLNK(st.st_mode):
  target=os.readlink(p)
  if target.startswith('/') or '..' in pathlib.PurePosixPath(rel).parent.joinpath(target).parts: raise SystemExit(1)
 elif not stat.S_ISDIR(st.st_mode): raise SystemExit(1)
out.write_text(''.join(rows),encoding='utf-8')
PY
}

verify_staged_payload() {
    local kernel modules expected_manifest staged_manifest
    kernel=$STAGE_ROOT/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL
    modules=$STAGE_ROOT/lib/modules/$CONFIRM_ROLLBACK_KERNEL
    expected_manifest=$NESTED_OUTPUT_DIR/nested-source-and-plan-preflight/source-module-manifest.txt
    staged_manifest=$OUTPUT_DIR/staged-module-manifest.txt
    require_regular_file "$kernel" && [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    [ "$(file_sha256 "$kernel")" = "$(accepted_value payload.kernel_sha256)" ] || return 1
    [ "$(file_size "$kernel")" = "$(accepted_value payload.kernel_size)" ] || return 1
    require_regular_file "$expected_manifest" || return 1
    [ "$(file_sha256 "$expected_manifest")" = "$(accepted_value payload.module_manifest_sha256)" ] || return 1
    write_installed_module_manifest "$modules" "$staged_manifest" || return 1
    [ "$(file_sha256 "$staged_manifest")" = "$(accepted_value payload.module_manifest_sha256)" ]
}

install_versioned_payload() {
    local staged_kernel staged_modules destination_kernel destination_modules
    staged_kernel=$STAGE_ROOT/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL
    staged_modules=$STAGE_ROOT/lib/modules/$CONFIRM_ROLLBACK_KERNEL
    destination_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")
    destination_modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    install -o root -g root -m 0644 -- "$staged_kernel" "$destination_kernel" || return 1
    KERNEL_INSTALLED=true
    mv -- "$destination_modules" "$BACKUP_ROOT/modules.metadata-placeholder.original" || return 1
    PLACEHOLDER_MOVED=true
    mv -- "$staged_modules" "$destination_modules" || return 1
    MODULES_INSTALLED=true
    chown -hR root:root -- "$destination_modules" || return 1
}

run_depmod() {
    local command=depmod
    if [ "$TEST_MODE" = 1 ]; then command=${ROLLBACK_APPLY_DEPMOD_COMMAND:-depmod}; fi
    "$command" -a "$CONFIRM_ROLLBACK_KERNEL" > "$OUTPUT_DIR/depmod.log" 2>&1
}

verify_module_objects_unchanged() {
    local expected source output modules
    source=$NESTED_OUTPUT_DIR/nested-source-and-plan-preflight/source-module-manifest.txt
    output=$OUTPUT_DIR/installed-module-object-manifest.txt
    modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    python3 - "$source" "$modules" "$output" <<'PY'
import hashlib,pathlib,sys
source=pathlib.Path(sys.argv[1]); root=pathlib.Path(sys.argv[2]); out=pathlib.Path(sys.argv[3])
expected=[]
for line in source.read_text(encoding='utf-8').splitlines():
 digest,size,mode,path=line.split('  ',3)
 if path.startswith('kernel/') and path.endswith(('.ko','.ko.gz','.ko.xz','.ko.zst')):
  expected.append((digest,size,mode,path))
rows=[]
for digest,size,mode,path in expected:
 p=root/path
 if not p.is_file() or p.is_symlink() or p.stat().st_size!=int(size): raise SystemExit(1)
 h=hashlib.sha256()
 with p.open('rb') as f:
  for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
 if h.hexdigest()!=digest: raise SystemExit(1)
 rows.append(f'{digest}  {size}  {mode}  {path}\n')
out.write_text(''.join(rows),encoding='utf-8')
if not rows: raise SystemExit(1)
PY
    expected=$(accepted_value payload.module_object_count) || return 1
    [ "$(wc -l < "$output")" -eq "$expected" ] || return 1
    require_regular_file "$modules/modules.dep" && require_regular_file "$modules/modules.alias"
}

run_reviewed_mkinitrd() {
    local -a vector=()
    mapfile -t vector < <(python3 - "$ACCEPTED_AUTH_REVIEW" <<'PY'
import json,sys
for item in json.load(open(sys.argv[1],encoding='utf-8'))['initrd']['command_vector']: print(item)
PY
    )
    [ "${#vector[@]}" -ge 3 ] && [ "${vector[0]}" = mkinitrd ] || return 1
    if [ "$TEST_MODE" = 1 ]; then vector[0]=${ROLLBACK_APPLY_MKINITRD_COMMAND:-mkinitrd}; fi
    local i
    for ((i=0;i<${#vector[@]};i++)); do
        if [ "${vector[$i]}" = -o ] && [ $((i+1)) -lt ${#vector[@]} ]; then
            vector[$((i+1))]=$(rooted "${vector[$((i+1))]}")
        fi
    done
    local output_path
    output_path=$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")
    [ ! -e "$output_path" ] && [ ! -L "$output_path" ] || return 1
    if ! "${vector[@]}" > "$OUTPUT_DIR/mkinitrd.log" 2>&1; then
        if [ -e "$output_path" ] || [ -L "$output_path" ]; then INITRD_CREATED=true; fi
        return 1
    fi
    INITRD_CREATED=true
}

restore_initrd_tree() {
    local tree state
    tree=$(rooted /boot/initrd-tree)
    require_regular_file "$BACKUP_ROOT/initrd-tree.state" || return 1
    state=$(cat "$BACKUP_ROOT/initrd-tree.state") || return 1
    case "$state" in
        present)
            [ -d "$BACKUP_ROOT/initrd-tree.before" ] && [ ! -L "$BACKUP_ROOT/initrd-tree.before" ] || return 1
            rm -rf -- "$tree" || return 1
            cp -a -- "$BACKUP_ROOT/initrd-tree.before" "$tree" || return 1
            ;;
        absent)
            rm -rf -- "$tree" || return 1
            ;;
        *) return 1 ;;
    esac
}

verify_generated_initrd() {
    local initrd
    initrd=$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")
    require_regular_file "$initrd" && [ "$(file_size "$initrd")" -gt 0 ] || return 1
    gzip -t -- "$initrd" > "$OUTPUT_DIR/initrd-gzip-test.log" 2>&1
}

install_grub_fragment() {
    local source destination
    source=$NESTED_OUTPUT_DIR/nested-source-and-plan-preflight/projected-41_slackware_rollback_6_18_40
    destination=$(rooted "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}")
    require_regular_file "$source" || return 1
    [ "$(file_sha256 "$source")" = "$(accepted_value grub.fragment_sha256)" ] || return 1
    install -o root -g root -m 0755 -- "$source" "$destination" || return 1
    FRAGMENT_INSTALLED=true
    bash -n "$destination" || return 1
}

validate_generated_grub_config() {
    local config=$1
    python3 - "$config" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ACCEPTED_AUTH_REVIEW" <<'PY'
import json,pathlib,re,shlex,sys
path=pathlib.Path(sys.argv[1]); active=sys.argv[2]; rollback=sys.argv[3]
accepted=json.load(open(sys.argv[4],encoding='utf-8'))
if not path.is_file() or path.is_symlink() or path.stat().st_size<=0: raise SystemExit(1)
lines=path.read_text(encoding='utf-8').splitlines()
def entries(lines):
 result=[]; current=[]; depth=0
 for line in lines:
  stripped=line.strip()
  if not current and stripped.startswith('menuentry '): current=[line]; depth=line.count('{')-line.count('}'); continue
  if current:
   current.append(line); depth+=line.count('{')-line.count('}')
   if depth==0: result.append(current); current=[]
 return result
items=entries(lines)
if not items: raise SystemExit(1)
def vectors(entry):
 linux=[]; initrd=[]
 for line in entry:
  stripped=line.strip()
  if re.match(r'^linux(?:efi)?\s+',stripped): linux.append(shlex.split(stripped)[1:])
  if re.match(r'^initrd(?:efi)?\s+',stripped): initrd.append(shlex.split(stripped)[1:])
 return linux,initrd
first_linux,first_initrd=vectors(items[0])
if len(first_linux)!=1 or first_linux[0][0]!='/boot/vmlinuz-generic': raise SystemExit(1)
if len(first_initrd)!=1 or first_initrd[0]!=accepted['grub']['source_initrd_vector']: raise SystemExit(1)
rollback_entries=[]
for entry in items:
 if f"--id 'slackware-rollback-{rollback}'" in entry[0] or f'--id slackware-rollback-{rollback}' in entry[0]: rollback_entries.append(entry)
if len(rollback_entries)!=1: raise SystemExit(1)
linux,initrd=vectors(rollback_entries[0])
if len(linux)!=1 or linux[0][0]!=f'/boot/vmlinuz-{rollback}': raise SystemExit(1)
if len(initrd)!=1 or initrd[0]!=accepted['grub']['projected_initrd_vector']: raise SystemExit(1)
if any(f'/boot/initrd-{active}.img' in line or '/boot/initrd-generic.img' in line for line in rollback_entries[0]): raise SystemExit(1)
PY
}

generate_and_validate_grub() {
    local mkconfig=grub-mkconfig check=grub-script-check config
    if [ "$TEST_MODE" = 1 ]; then
        mkconfig=${ROLLBACK_APPLY_GRUB_MKCONFIG_COMMAND:-grub-mkconfig}
        check=${ROLLBACK_APPLY_GRUB_SCRIPT_CHECK_COMMAND:-grub-script-check}
    fi
    config=$STAGE_ROOT/grub.cfg.new
    "$mkconfig" -o "$config" > "$OUTPUT_DIR/grub-mkconfig.log" 2>&1 || return 1
    require_regular_file "$config" && [ "$(file_size "$config")" -gt 0 ] || return 1
    "$check" "$config" > "$OUTPUT_DIR/grub-script-check.log" 2>&1 || return 1
    validate_generated_grub_config "$config"
}

atomic_replace_grub() {
    local active staged temporary uid gid mode
    active=$(rooted /boot/grub/grub.cfg)
    staged=$STAGE_ROOT/grub.cfg.new
    require_regular_file "$active" && require_regular_file "$staged" || return 1
    [ "$(file_sha256 "$active")" = "$BEFORE_GRUB_SHA256" ] || return 1
    uid=$(stat -c '%u' -- "$active") || return 1
    gid=$(stat -c '%g' -- "$active") || return 1
    mode=$(stat -c '%a' -- "$active") || return 1
    temporary=$(dirname -- "$active")/.slack-update-grub.cfg.$$
    [ ! -e "$temporary" ] && [ ! -L "$temporary" ] || return 1
    install -o "$uid" -g "$gid" -m "$mode" -- "$staged" "$temporary" || return 1
    mv -fT -- "$temporary" "$active" || return 1
    GRUB_REPLACED=true
}

verify_successful_post_state() {
    local active_kernel active_initrd generic_kernel generic_initrd rollback_kernel rollback_initrd fragment grub
    active_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL")
    active_initrd=$(rooted "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img")
    generic_kernel=$(rooted /boot/vmlinuz-generic)
    generic_initrd=$(rooted /boot/initrd-generic.img)
    rollback_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")
    rollback_initrd=$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")
    fragment=$(rooted "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}")
    grub=$(rooted /boot/grub/grub.cfg)
    [ "$(file_sha256 "$active_kernel")" = "$(policy_value active_kernel_sha256)" ] || return 1
    [ "$(file_sha256 "$active_initrd")" = "$(policy_value active_initrd_sha256)" ] || return 1
    [ -L "$generic_kernel" ] && [ "$(readlink -- "$generic_kernel")" = "vmlinuz-$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ -L "$generic_initrd" ] && [ "$(readlink -- "$generic_initrd")" = "initrd-$CONFIRM_ACTIVE_KERNEL.img" ] || return 1
    require_regular_file "$rollback_kernel" && [ "$(file_sha256 "$rollback_kernel")" = "$(accepted_value payload.kernel_sha256)" ] || return 1
    require_regular_file "$rollback_initrd" && gzip -t -- "$rollback_initrd" || return 1
    require_regular_file "$fragment" && [ "$(file_sha256 "$fragment")" = "$(accepted_value grub.fragment_sha256)" ] || return 1
    validate_generated_grub_config "$grub" || return 1
    verify_module_objects_unchanged || return 1
    [ "$(uname -r 2>/dev/null || printf '%s' "${ROLLBACK_APPLY_TEST_RUNNING_KERNEL:-}")" = "$CONFIRM_ACTIVE_KERNEL" ] || [ "$TEST_MODE" = 1 ] || return 1
    if [ -f "$(rooted /boot/grub/grubenv)" ]; then
        command -v grub-editenv >/dev/null 2>&1 || return 1
        grub-editenv "$(rooted /boot/grub/grubenv)" list > "$OUTPUT_DIR/grubenv.after.txt" 2>&1 || return 1
        ! grep -q '^next_entry=' "$OUTPUT_DIR/grubenv.after.txt" || return 1
    fi
}

restore_grub_from_backup() {
    local active backup temporary uid gid mode
    active=$(rooted /boot/grub/grub.cfg)
    backup=$BACKUP_ROOT/grub.cfg.before
    require_regular_file "$backup" || return 1
    uid=$(stat -c '%u' -- "$backup") || return 1
    gid=$(stat -c '%g' -- "$backup") || return 1
    mode=$(stat -c '%a' -- "$backup") || return 1
    temporary=$(dirname -- "$active")/.slack-update-grub-restore.$$
    install -o "$uid" -g "$gid" -m "$mode" -- "$backup" "$temporary" || return 1
    mv -fT -- "$temporary" "$active"
}

rollback_transaction() {
    local status=0 modules kernel initrd fragment
    ROLLBACK_ATTEMPTED=true
    modules=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")
    initrd=$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")
    fragment=$(rooted "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}")
    if require_regular_file "$BACKUP_ROOT/grub.cfg.before"; then
        if ! require_regular_file "$(rooted /boot/grub/grub.cfg)" \
            || [ "$(file_sha256 "$(rooted /boot/grub/grub.cfg)" 2>/dev/null || true)" != "$BEFORE_GRUB_SHA256" ]; then
            restore_grub_from_backup || status=1
        fi
    fi
    if [ -e "$fragment" ] || [ -L "$fragment" ]; then rm -f -- "$fragment" || status=1; fi
    if [ -e "$initrd" ] || [ -L "$initrd" ]; then rm -f -- "$initrd" || status=1; fi
    if [ -f "$BACKUP_ROOT/initrd-tree.state" ]; then restore_initrd_tree || status=1; fi
    if [ -d "$BACKUP_ROOT/modules.metadata-placeholder.original" ] \
        && [ ! -L "$BACKUP_ROOT/modules.metadata-placeholder.original" ]; then
        [ ! -e "$modules" ] && [ ! -L "$modules" ] || rm -rf -- "$modules" || status=1
        cp -a -- "$BACKUP_ROOT/modules.metadata-placeholder.original" "$modules" || status=1
    fi
    if [ -e "$kernel" ] || [ -L "$kernel" ]; then rm -f -- "$kernel" || status=1; fi
    rm -rf -- "$STAGE_ROOT" 2>/dev/null || status=1
    return "$status"
}

verify_baseline_restored() {
    local after_sensitive=$OUTPUT_DIR/sensitive.rollback-restored.txt after_packages=$OUTPUT_DIR/packages.rollback-restored.txt
    capture_sensitive_state "$after_sensitive" || return 1
    capture_package_database "$after_packages" || return 1
    [ "$(file_sha256 "$after_sensitive")" = "$BEFORE_SENSITIVE_SHA256" ] || return 1
    [ "$(file_sha256 "$after_packages")" = "$BEFORE_PACKAGES_SHA256" ] || return 1
    ROLLBACK_RESTORED=true
    PAUSE_SAFE=true
    PAUSE_SAFETY_REASON=failed-apply-rolled-back-to-verified-6.18.42-baseline
}

cleanup_stage_after_success() {
    rm -rf -- "$STAGE_ROOT"
}

write_result_files() {
    local result=$1
    python3 - "$OUTPUT_DIR/result.json" "$result" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_AUTHORIZATION_EVIDENCE_SHA256" \
        "$CONFIRM_APPLY_CONTRACT_SHA256" "$CONFIRM_APPLY_SCOPE_SHA256" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" \
        "$TRANSACTION_STARTED" "$APPLY_EXECUTED" "$APPLY_COMMITTED" "$ROLLBACK_ATTEMPTED" "$ROLLBACK_RESTORED" \
        "$ROLLBACK_COMPLETE_ON_DISK" "$PAUSE_SAFE" "$PAUSE_SAFETY_REASON" "$NEXT_STAGE" <<'PY'
import json,pathlib,sys
(out,result,passes,failures,skips,active,rollback,evidence,contract,scope,pkg,sig,started,executed,committed,
 rollback_attempted,rollback_restored,complete,pause_safe,pause_reason,next_stage)=sys.argv[1:]
b=lambda x:x=='true'
data={
 'schema':1,'scenario':'current-rollback-reconstruction-authorized-apply','target':'slackware-current',
 'result':result,'passes':int(passes),'failures':int(failures),'skips':int(skips),
 'active_kernel':active,'rollback_kernel':rollback,'authorization_evidence_sha256':evidence,
 'apply_contract_sha256':contract,'apply_scope_sha256':scope,
 'source_package':pkg,'source_signature':sig,
 'repository_metadata_refreshed':False,'package_installation_performed':False,'package_database_mutated':False,
 'transaction_started':b(started),'apply_executed':b(executed),'apply_committed':b(committed),
 'rollback_attempted':b(rollback_attempted),'rollback_restored':b(rollback_restored),
 'rollback_complete_on_disk':b(complete),'pause_safe':b(pause_safe),'pause_safety_reason':pause_reason,
 'running_kernel_unchanged':True if b(pause_safe) else None,'reboot_performed':False,'reboot_required':False,
 'next_stage':next_stage,
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-rollback-reconstruction-authorized-apply
target=slackware-current
result=$result
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
authorization_evidence_sha256=$CONFIRM_AUTHORIZATION_EVIDENCE_SHA256
apply_contract_sha256=$CONFIRM_APPLY_CONTRACT_SHA256
apply_scope_sha256=$CONFIRM_APPLY_SCOPE_SHA256
repository_metadata_refreshed=false
package_installation_performed=false
package_database_mutated=false
transaction_started=$TRANSACTION_STARTED
apply_executed=$APPLY_EXECUTED
apply_committed=$APPLY_COMMITTED
rollback_attempted=$ROLLBACK_ATTEMPTED
rollback_restored=$ROLLBACK_RESTORED
rollback_complete_on_disk=$ROLLBACK_COMPLETE_ON_DISK
pause_safe=$PAUSE_SAFE
pause_safety_reason=$PAUSE_SAFETY_REASON
reboot_performed=false
reboot_required=false
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

archive_evidence() {
    local parent base archive sidecar owner group
    parent=$(dirname -- "$OUTPUT_DIR")
    base=$(basename -- "$OUTPUT_DIR")
    archive=$parent/$base.tar.gz
    sidecar=$archive.sha256
    [ ! -e "$archive" ] && [ ! -L "$archive" ] && [ ! -e "$sidecar" ] && [ ! -L "$sidecar" ] || return 1
    tar -czf "$archive" -C "$parent" "$base" || return 1
    (cd "$parent" && sha256sum "${base}.tar.gz" > "${base}.tar.gz.sha256") || return 1
    owner=${SUDO_USER:-$(id -un)}
    group=$(id -gn "$owner" 2>/dev/null || id -gn)
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(file_sha256 "$archive")"
    printf 'Copy evidence pair command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "/home/$owner/${base}.tar.gz" \
        "$owner" "$group" "$sidecar" "/home/$owner/${base}.tar.gz.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${base}.tar.gz.sha256"
}

finalize_if_needed() {
    local status=$?
    [ "$FINALIZED" = true ] && return "$status"
    if [ "$TRANSACTION_STARTED" = true ] && [ "$APPLY_COMMITTED" = false ]; then
        rollback_transaction || true
        verify_baseline_restored || true
    fi
    return "$status"
}

handle_signal() {
    local signal=$1
    case "$signal" in HUP) SIGNAL_STATUS=129 ;; INT) SIGNAL_STATUS=130 ;; TERM) SIGNAL_STATUS=143 ;; *) SIGNAL_STATUS=1 ;; esac
    trap - EXIT HUP INT TERM
    if [ "$TRANSACTION_STARTED" = true ] && [ "$APPLY_COMMITTED" = false ]; then
        rollback_transaction || true
        verify_baseline_restored || true
    fi
    record_failure "the authorized rollback reconstruction was interrupted by SIG$signal"
    NEXT_STAGE=current-rollback-reconstruction-interrupted-manual-review
    write_result_files FAIL || true
    archive_evidence || true
    FINALIZED=true
    exit "$SIGNAL_STATUS"
}

main() {
    local result=FAIL status=1 active_grub
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$TEST_MODE" = 1 ] || [ "$(id -u)" -eq 0 ] || { error 'root privileges are required'; return 1; }
    validate_authorized_boundary || { error 'the accepted authorization, exact code, apply contract, or confirmation scope does not match'; return 1; }
    initialize_output || { error 'cannot create the private evidence directory'; return 1; }
    trap finalize_if_needed EXIT
    trap 'handle_signal HUP' HUP
    trap 'handle_signal INT' INT
    trap 'handle_signal TERM' TERM

    record_pass "the accepted authorization, canonical contract, exact code, and apply scope are bound"

    if validate_source_files; then
        record_pass "the locally preserved historical package and detached signature match the authorized hashes"
    else
        record_failure "the locally preserved historical package or signature no longer matches the authorization"
    fi

    if resolve_package_database && capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        BEFORE_PACKAGES_SHA256=$(file_sha256 "$OUTPUT_DIR/packages.before.txt")
        BEFORE_SENSITIVE_SHA256=$(file_sha256 "$OUTPUT_DIR/sensitive.before.txt")
        active_grub=$(rooted /boot/grub/grub.cfg)
        BEFORE_GRUB_SHA256=$(file_sha256 "$active_grub")
        BASELINE_CAPTURED=true
        record_pass "the package database and rollback-sensitive baseline were captured before mutation"
    else
        record_failure "the pre-apply package or rollback-sensitive baseline could not be captured"
    fi

    if [ "$BASELINE_CAPTURED" != true ]; then
        record_skip "live-boundary validation requires a captured pre-apply baseline"
    elif validate_pre_mutation_baseline; then
        LIVE_BOUNDARY_VALID=true
        record_pass "the live 6.18.42 boundary and metadata-only 6.18.40 placeholder match the authorized baseline"
    else
        record_failure "the live boundary no longer matches the authorized rollback reconstruction baseline"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "fresh authorization requires the exact live boundary and source"
    elif run_fresh_authorization_review && validate_fresh_authorization_review; then
        record_pass "a fresh non-mutating authorization review reproduced the exact canonical apply contract"
    else
        record_failure "the fresh authorization review did not reproduce the exact authorized contract"
    fi

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        TRANSACTION_STARTED=true
        APPLY_EXECUTED=true
        if create_transaction_directories && backup_initial_state; then
            record_pass "owner-only staging and rollback backups were created before any installed artifact changed"
        else
            record_failure "the private staging or rollback backup boundary could not be created safely"
        fi
    else
        record_skip "transaction setup requires a valid fresh authorization and unchanged live boundary"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "payload staging requires a successfully initialized transaction"
    elif extract_reviewed_payload && verify_staged_payload; then
        record_pass "only the reviewed kernel and complete module tree were staged and matched their authorized hashes"
    else
        record_failure "the reviewed kernel and module payload could not be staged and verified exactly"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "versioned payload installation requires a verified staged payload"
    elif install_versioned_payload; then
        record_pass "the versioned 6.18.40 kernel and module tree were installed without changing generic boot links"
    else
        record_failure "the versioned rollback kernel and module tree could not be installed safely"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "depmod requires the installed rollback module tree"
    elif run_depmod && verify_module_objects_unchanged; then
        record_pass "depmod completed for 6.18.40 while all reviewed module objects remained byte-identical"
    else
        record_failure "depmod or post-depmod module-object verification failed"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "initrd generation requires the verified rollback module tree"
    elif run_reviewed_mkinitrd && verify_generated_initrd && restore_initrd_tree; then
        record_pass "the exact reviewed mkinitrd vector created a valid versioned 6.18.40 initrd"
    else
        record_failure "the reviewed versioned initrd could not be generated and validated"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "GRUB staging requires the complete versioned rollback kernel and initrd"
    elif install_grub_fragment && generate_and_validate_grub; then
        record_pass "the explicit rollback fragment generated a syntax-valid GRUB configuration with 6.18.42 still first"
    else
        record_failure "the explicit rollback GRUB fragment or generated configuration failed validation"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "final commit requires every authorized reconstruction stage to pass"
    elif atomic_replace_grub && verify_successful_post_state; then
        APPLY_COMMITTED=true
        ROLLBACK_COMPLETE_ON_DISK=true
        PAUSE_SAFE=true
        PAUSE_SAFETY_REASON=rollback-complete-on-disk-and-6.18.42-remains-running-and-default
        NEXT_STAGE=current-rollback-reconstruction-boot-test-optional
        cleanup_stage_after_success || true
        record_pass "the rollback is complete on disk, 6.18.42 remains running and default, and the machine is safe to power off"
    else
        record_failure "the atomic GRUB replacement or final complete on-disk verification failed"
    fi

    if [ "$APPLY_COMMITTED" = false ] && [ "$TRANSACTION_STARTED" = true ]; then
        if rollback_transaction && verify_baseline_restored; then
            record_pass "the failed transaction was rolled back to the exact captured 6.18.42 baseline"
            NEXT_STAGE=current-rollback-reconstruction-authorized-apply-retry-review
        else
            record_failure "the failed transaction could not be proven restored to the captured baseline"
            PAUSE_SAFE=false
            PAUSE_SAFETY_REASON=rollback-restoration-not-proven
            NEXT_STAGE=current-rollback-reconstruction-emergency-manual-review
        fi
    elif [ "$APPLY_COMMITTED" = true ]; then
        if capture_package_database "$OUTPUT_DIR/packages.after.txt" \
            && [ "$(file_sha256 "$OUTPUT_DIR/packages.after.txt")" = "$BEFORE_PACKAGES_SHA256" ]; then
            record_pass "the installed package database remained unchanged throughout the reconstruction"
        else
            record_failure "the installed package database changed unexpectedly"
            PAUSE_SAFE=false
            PAUSE_SAFETY_REASON=package-database-change-detected-after-commit
            NEXT_STAGE=current-rollback-reconstruction-emergency-manual-review
        fi
    fi

    if [ "$TRANSACTION_STARTED" = false ] && [ "$BASELINE_CAPTURED" = true ] && [ "$LIVE_BOUNDARY_VALID" = true ]; then
        if capture_sensitive_state "$OUTPUT_DIR/sensitive.not-started-after.txt" \
            && capture_package_database "$OUTPUT_DIR/packages.not-started-after.txt" \
            && [ "$(file_sha256 "$OUTPUT_DIR/sensitive.not-started-after.txt")" = "$BEFORE_SENSITIVE_SHA256" ] \
            && [ "$(file_sha256 "$OUTPUT_DIR/packages.not-started-after.txt")" = "$BEFORE_PACKAGES_SHA256" ]; then
            PAUSE_SAFE=true
            PAUSE_SAFETY_REASON=apply-not-started-and-verified-6.18.42-baseline-unchanged
            NEXT_STAGE=current-rollback-reconstruction-authorized-apply-retry-review
            record_pass "the rejected pre-apply attempt left the exact 6.18.42 baseline unchanged and safe to power off"
        else
            PAUSE_SAFE=false
            PAUSE_SAFETY_REASON=pre-apply-baseline-preservation-not-proven
            NEXT_STAGE=current-rollback-reconstruction-emergency-manual-review
            record_failure "the pre-apply rejection could not prove preservation of the captured baseline"
        fi
    fi

    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$APPLY_COMMITTED" = true ] && [ "$PAUSE_SAFE" = true ]; then
        result=PASS
        status=0
    else
        result=FAIL
        status=1
    fi
    write_result_files "$result" || return 1
    archive_evidence || return 1
    printf 'Result: %s (%d passes, %d failures, %d skips); apply_executed=%s; apply_committed=%s; rollback_complete_on_disk=%s; pause_safe=%s; next_stage=%s\n' \
        "$result" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$APPLY_EXECUTED" "$APPLY_COMMITTED" \
        "$ROLLBACK_COMPLETE_ON_DISK" "$PAUSE_SAFE" "$NEXT_STAGE"
    FINALIZED=true
    trap - EXIT HUP INT TERM
    return "$status"
}

main "$@"
