#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
LC_ALL=C
export LC_ALL

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd -P)
REVIEW_SCRIPT=$SCRIPT_DIR/test-current-rollback-return-verification-closure.sh
DEFAULT_POLICY=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-return-verification-closure-policy.json
DEFAULT_ACCEPTED_RETURN=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-boot-verification-and-return-review-20260811-accepted.json
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
POLICY=${ROLLBACK_RETURN_CLOSURE_POLICY_PATH:-$DEFAULT_POLICY}
ACCEPTED_RETURN=${ROLLBACK_RETURN_CLOSURE_ACCEPTED_RETURN_PATH:-$DEFAULT_ACCEPTED_RETURN}

TARGET=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_RETURN_REVIEW_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_CLOSURE_SHA256=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
RETURN_VERIFIED=false
ROLLBACK_RETAINED=false
ROLLBACK_BOOT_DEMONSTRATION_CLOSED=false
PAUSE_SAFE=false
CURRENT_WORK_REMAINING=true
NEXT_STAGE=current-rollback-return-verification-manual-review
PACKAGE_DATABASE=
BEFORE_PACKAGES_SHA256=
BEFORE_SENSITIVE_SHA256=
ACCEPTED_PACKAGE_DB_SHA=
ACCEPTED_ACTIVE_KERNEL_SHA=
ACCEPTED_ACTIVE_INITRD_SHA=
ACCEPTED_ROLLBACK_KERNEL_SHA=
ACCEPTED_ROLLBACK_INITRD_SHA=
ACCEPTED_MODULE_MANIFEST_SHA=
ACCEPTED_MODULE_COUNT=
ACCEPTED_GRUB_FRAGMENT_SHA=
ACCEPTED_GRUB_ENTRY_ID=
ACCEPTED_GRUB_ENTRY_TITLE=
ACCEPTED_ROOT_SOURCE=
ACCEPTED_ROOT_UUID=

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
  --confirm-hostname SHORT_HOSTNAME \\
  --confirm-hostname-fqdn FQDN \\
  --confirm-return-review-evidence-sha256 SHA256 \\
  --confirm-active-kernel VERSION \\
  --confirm-rollback-kernel VERSION \\
  --confirm-closure-sha256 SHA256 [--output-dir PATH]

Verify the normal return to the unchanged active 6.18.42 default after the real
6.18.40 rollback boot test. This command is strictly non-mutating: it does not
refresh Slackware-current metadata, modify packages, GRUB or grubenv, or reboot.
A clean result closes the optional rollback boot demonstration while retaining
6.18.40 as an on-disk rollback.
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log" >&2; }
record_skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }

is_sha256() { [ "${#1}" -eq 64 ] && [[ $1 != *[!0-9A-Fa-f]* ]]; }
is_safe_kernel_version() { [ -n "$1" ] && [[ $1 != *[!0-9A-Za-z._+-]* ]]; }
file_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
require_regular_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
rooted() { printf '%s%s\n' "$ROOT_PREFIX" "$1"; }

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-return-review-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_RETURN_REVIEW_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-active-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
            --confirm-rollback-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
            --confirm-closure-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CLOSURE_SHA256=${2,,}; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    is_sha256 "$CONFIRM_RETURN_REVIEW_EVIDENCE_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_ACTIVE_KERNEL" || return 1
    is_safe_kernel_version "$CONFIRM_ROLLBACK_KERNEL" || return 1
    [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
    is_sha256 "$CONFIRM_CLOSURE_SHA256" || return 1
    if [ -n "$OUTPUT_DIR" ]; then case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac; fi
}

load_accepted_values() {
    local -a values=()
    mapfile -t values < <(python3 - "$ACCEPTED_RETURN" <<'PY'
import json,sys
a=json.load(open(sys.argv[1],encoding='utf-8'))
for key in ('package_database_manifest_sha256','active_kernel_sha256','active_initrd_sha256',
            'rollback_kernel_sha256','rollback_initrd_sha256','installed_module_object_manifest_sha256',
            'installed_module_object_count','grub_fragment_sha256','grub_entry_id','grub_entry_title',
            'root_source','root_uuid'):
    print(a[key])
PY
) || return 1
    [ "${#values[@]}" -eq 12 ] || return 1
    ACCEPTED_PACKAGE_DB_SHA=${values[0]}
    ACCEPTED_ACTIVE_KERNEL_SHA=${values[1]}
    ACCEPTED_ACTIVE_INITRD_SHA=${values[2]}
    ACCEPTED_ROLLBACK_KERNEL_SHA=${values[3]}
    ACCEPTED_ROLLBACK_INITRD_SHA=${values[4]}
    ACCEPTED_MODULE_MANIFEST_SHA=${values[5]}
    ACCEPTED_MODULE_COUNT=${values[6]}
    ACCEPTED_GRUB_FRAGMENT_SHA=${values[7]}
    ACCEPTED_GRUB_ENTRY_ID=${values[8]}
    ACCEPTED_GRUB_ENTRY_TITLE=${values[9]}
    ACCEPTED_ROOT_SOURCE=${values[10]}
    ACCEPTED_ROOT_UUID=${values[11]}
}

validate_static_boundary() {
    python3 - "$POLICY" "$REVIEW_SCRIPT" "$ACCEPTED_RETURN" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_RETURN_REVIEW_EVIDENCE_SHA256" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_CLOSURE_SHA256" <<'PY'
import hashlib,json,pathlib,sys
policy_path,script_path,accepted_path,host,fqdn,evidence,active,rollback,confirmed_scope=sys.argv[1:]
def regular(p):
    p=pathlib.Path(p)
    if not p.is_file() or p.is_symlink(): raise SystemExit(1)
    return p
def sha(p): return hashlib.sha256(regular(p).read_bytes()).hexdigest()
policy=json.loads(regular(policy_path).read_text(encoding='utf-8'))
accepted=json.loads(regular(accepted_path).read_text(encoding='utf-8'))
script_sha=sha(script_path); accepted_sha=sha(accepted_path)
scope=(
 'operation=current-rollback-return-verification-closure\n'
 'target=slackware-current\n'
 f'hostname_short={host}\n'
 f'hostname_fqdn={fqdn}\n'
 f'accepted_return_review_archive_sha256={evidence}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'accepted_return_review_record_sha256={accepted_sha}\n'
 f'closure_script_sha256={script_sha}\n'
).encode()
calculated=hashlib.sha256(scope).hexdigest()
checks=[
 policy.get('schema')==1,
 policy.get('scenario')=='current-rollback-return-verification-closure',
 policy.get('reviewed') is True,
 policy.get('target')=='slackware-current',
 policy.get('expected_review_script_sha256')==script_sha,
 policy.get('accepted_return_review_record_sha256')==accepted_sha,
 policy.get('accepted_return_review_archive_sha256')==evidence,
 policy.get('confirmation_scope_sha256')==confirmed_scope==calculated,
 policy.get('hostname_short')==host==accepted.get('hostname_short'),
 policy.get('hostname_fqdn')==fqdn==accepted.get('hostname_fqdn'),
 policy.get('active_kernel')==active==accepted.get('active_kernel'),
 policy.get('rollback_kernel')==rollback==accepted.get('rollback_kernel'),
 accepted.get('accepted') is True,
 accepted.get('result')=='PASS',
 accepted.get('failures')==0,
 accepted.get('rollback_boot_verified') is True,
 accepted.get('return_authorized') is True,
 accepted.get('return_executed') is False,
 accepted.get('manual_selection_required') is False,
 accepted.get('archive_sha256')==evidence,
]
if not all(checks): raise SystemExit(1)
PY
}

initialize_output() {
    local stamp base
    if [ -z "$OUTPUT_DIR" ]; then
        stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
        base=$(rooted /var/tmp/slack-update-acceptance/current-rollback-return-verification-closure)
        install -d -m 0700 -- "$base" || return 1
        OUTPUT_DIR=$base/slackware-current-$stamp
    fi
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
    install -d -m 0700 -- "$OUTPUT_DIR" || return 1
    : > "$OUTPUT_DIR/assertions.log"
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
items=['/boot/vmlinuz-generic',f'/boot/vmlinuz-{active}',f'/boot/vmlinuz-{rollback}',
       '/boot/initrd-generic.img',f'/boot/initrd-{active}.img',f'/boot/initrd-{rollback}.img',
       '/boot/grub/grub.cfg','/boot/grub/grubenv',f'/etc/grub.d/41_slackware_rollback_{rollback.replace(".","_")}',
       f'/lib/modules/{rollback}']
def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for c in iter(lambda:f.read(1024*1024),b''): h.update(c)
    return h.hexdigest()
rows=[]
for logical in items:
    p=root/logical.lstrip('/')
    try: st=p.lstat()
    except FileNotFoundError:
        rows.append((logical,'missing','','','','','')); continue
    mode=f'{stat.S_IMODE(st.st_mode):04o}'
    if stat.S_ISLNK(st.st_mode): rows.append((logical,'symlink',mode,str(st.st_uid),str(st.st_gid),str(st.st_size),os.readlink(p)))
    elif stat.S_ISREG(st.st_mode): rows.append((logical,'file',mode,str(st.st_uid),str(st.st_gid),str(st.st_size),digest(p)))
    elif stat.S_ISDIR(st.st_mode): rows.append((logical,'directory',mode,str(st.st_uid),str(st.st_gid),'',''))
    else: rows.append((logical,'other',mode,str(st.st_uid),str(st.st_gid),str(st.st_size),''))
pathlib.Path(sys.argv[4]).write_text(''.join('\t'.join(r)+'\n' for r in rows),encoding='utf-8')
PY
}

runtime_hostname_short() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_HOSTNAME_SHORT:-pcold-slack}"; else hostname -s; fi; }
runtime_hostname_fqdn() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_HOSTNAME_FQDN:-pcold-slack.pcold-slack.org}"; else hostname -f; fi; }
runtime_kernel() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE_KERNEL}"; else uname -r; fi; }
runtime_arch() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_ARCH:-x86_64}"; else uname -m; fi; }
runtime_osrelease() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_OSRELEASE:-$CONFIRM_ACTIVE_KERNEL}"; else cat /proc/sys/kernel/osrelease; fi; }
runtime_cmdline() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_CMDLINE:-BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=$ACCEPTED_ROOT_UUID ro}"; else cat /proc/cmdline; fi; }
runtime_root_source() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_ROOT_SOURCE:-/dev/sda2}"; else findmnt -n -o SOURCE /; fi; }
runtime_root_uuid() { if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ROLLBACK_RETURN_CLOSURE_TEST_ROOT_UUID:-ba7632d7-7469-483e-830d-59c88d985866}"; else blkid -s UUID -o value "$(findmnt -n -o SOURCE /)"; fi; }

build_module_manifest() {
    local root output
    root=$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")
    output=$1
    python3 - "$root" "$output" <<'PY'
import hashlib,pathlib,stat,sys
root=pathlib.Path(sys.argv[1]); out=pathlib.Path(sys.argv[2]); rows=[]
if not root.is_dir() or root.is_symlink(): raise SystemExit(1)
for p in sorted(root.rglob('*'),key=lambda x:x.relative_to(root).as_posix()):
    rel=p.relative_to(root).as_posix()
    if p.is_file() and not p.is_symlink() and rel.startswith('kernel/') and rel.endswith(('.ko','.ko.gz','.ko.xz','.ko.zst')):
        h=hashlib.sha256()
        with p.open('rb') as f:
            for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
        st=p.stat(); rows.append(f'{h.hexdigest()}  {st.st_size}  {oct(stat.S_IMODE(st.st_mode))}  {rel}\n')
out.write_text(''.join(rows),encoding='utf-8')
if not rows: raise SystemExit(1)
PY
}

validate_runtime_cmdline() {
    local cmdline=$1
    python3 - "$cmdline" "$ACCEPTED_ROOT_UUID" "$OUTPUT_DIR/runtime-cmdline.json" <<'PY'
import json,pathlib,sys
cmdline,root_uuid,out=sys.argv[1:]
tokens=cmdline.split()
roots=[t for t in tokens if t.startswith('root=')]
if roots != [f'root=UUID={root_uuid}']: raise SystemExit(1)
if 'ro' not in tokens: raise SystemExit(1)
boot=[t.split('=',1)[1] for t in tokens if t.startswith('BOOT_IMAGE=')]
if boot != ['/boot/vmlinuz-generic']: raise SystemExit(1)
pathlib.Path(out).write_text(json.dumps({'cmdline':cmdline,'boot_image':boot[0],
 'root':roots[0],'read_only_root_requested':True,'normal_default_path_observed':True},indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

validate_grub_semantics() {
    local grub fragment
    grub=$(rooted /boot/grub/grub.cfg)
    fragment=$(rooted "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}")
    python3 - "$grub" "$fragment" "$ACCEPTED_RETURN" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/grub-closure-review.json" <<'PY'
import json,pathlib,re,shlex,sys
cfg,fragment,accepted_path,active,rollback,out=sys.argv[1:]
a=json.load(open(accepted_path,encoding='utf-8'))
cp=pathlib.Path(cfg); fp=pathlib.Path(fragment)
if not cp.is_file() or cp.is_symlink() or cp.stat().st_size<=0: raise SystemExit(1)
if not fp.is_file() or fp.is_symlink(): raise SystemExit(1)
lines=cp.read_text(encoding='utf-8').splitlines()
def entries(lines):
    result=[]; cur=[]; depth=0
    for line in lines:
        s=line.strip()
        if not cur and s.startswith('menuentry '): cur=[line]; depth=line.count('{')-line.count('}'); continue
        if cur:
            cur.append(line); depth+=line.count('{')-line.count('}')
            if depth==0: result.append(cur); cur=[]
    return result
items=entries(lines)
if not items: raise SystemExit(1)
def vectors(entry):
    linux=[]; initrd=[]
    for line in entry:
        s=line.strip()
        if re.match(r'^linux(?:efi)?\s+',s): linux.append(shlex.split(s)[1:])
        if re.match(r'^initrd(?:efi)?\s+',s): initrd.append(shlex.split(s)[1:])
    return linux,initrd
first_linux,first_initrd=vectors(items[0])
if len(first_linux)!=1 or first_linux[0][0]!='/boot/vmlinuz-generic': raise SystemExit(1)
if len(first_initrd)!=1 or first_initrd[0]!=a['active_initrd_vector']: raise SystemExit(1)
entry_id=a['grub_entry_id']; title=a['grub_entry_title']
matched=[e for e in items if entry_id in e[0]]
if len(matched)!=1: raise SystemExit(1)
linux,initrd=vectors(matched[0])
if len(linux)!=1 or linux[0][0]!=f'/boot/vmlinuz-{rollback}': raise SystemExit(1)
if len(initrd)!=1 or initrd[0]!=a['rollback_initrd_vector']: raise SystemExit(1)
if any(f'/boot/initrd-{active}.img' in line or '/boot/initrd-generic.img' in line for line in matched[0]): raise SystemExit(1)
if title not in matched[0][0]: raise SystemExit(1)
pathlib.Path(out).write_text(json.dumps({'active_entry_first':True,'normal_default_kernel':'/boot/vmlinuz-generic',
 'active_initrd_vector':first_initrd[0],'rollback_entry_id':entry_id,'rollback_entry_title':title,
 'rollback_entry_count':1,'rollback_linux_vector':linux[0],'rollback_initrd_vector':initrd[0],
 'rollback_retained':True},indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

validate_live_return() {
    local active_kernel active_initrd generic_kernel generic_initrd rollback_kernel rollback_initrd fragment grub grubenv cmdline manifest_sha count
    [ "$(runtime_hostname_short)" = "$CONFIRM_HOSTNAME" ] || return 1
    [ "$(runtime_hostname_fqdn)" = "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    [ "$(runtime_arch)" = x86_64 ] || return 1
    [ "$(runtime_kernel)" = "$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ "$(runtime_osrelease)" = "$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ "$(runtime_root_source)" = "$ACCEPTED_ROOT_SOURCE" ] || return 1
    [ "$(runtime_root_uuid)" = "$ACCEPTED_ROOT_UUID" ] || return 1
    cmdline=$(runtime_cmdline) || return 1
    printf '%s\n' "$cmdline" > "$OUTPUT_DIR/proc-cmdline.txt"
    validate_runtime_cmdline "$cmdline" || return 1

    active_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL")
    active_initrd=$(rooted "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img")
    generic_kernel=$(rooted /boot/vmlinuz-generic)
    generic_initrd=$(rooted /boot/initrd-generic.img)
    rollback_kernel=$(rooted "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL")
    rollback_initrd=$(rooted "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img")
    fragment=$(rooted "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}")
    grub=$(rooted /boot/grub/grub.cfg)

    require_regular_file "$active_kernel" && [ "$(file_sha256 "$active_kernel")" = "$ACCEPTED_ACTIVE_KERNEL_SHA" ] || return 1
    require_regular_file "$active_initrd" && [ "$(file_sha256 "$active_initrd")" = "$ACCEPTED_ACTIVE_INITRD_SHA" ] || return 1
    [ -L "$generic_kernel" ] && [ "$(readlink -- "$generic_kernel")" = "vmlinuz-$CONFIRM_ACTIVE_KERNEL" ] || return 1
    [ -L "$generic_initrd" ] && [ "$(readlink -- "$generic_initrd")" = "initrd-$CONFIRM_ACTIVE_KERNEL.img" ] || return 1
    require_regular_file "$rollback_kernel" && [ "$(file_sha256 "$rollback_kernel")" = "$ACCEPTED_ROLLBACK_KERNEL_SHA" ] || return 1
    require_regular_file "$rollback_initrd" && [ "$(file_sha256 "$rollback_initrd")" = "$ACCEPTED_ROLLBACK_INITRD_SHA" ] || return 1
    gzip -t -- "$rollback_initrd" > "$OUTPUT_DIR/rollback-initrd-gzip-test.log" 2>&1 || return 1
    require_regular_file "$fragment" && [ "$(file_sha256 "$fragment")" = "$ACCEPTED_GRUB_FRAGMENT_SHA" ] || return 1

    build_module_manifest "$OUTPUT_DIR/installed-module-object-manifest.txt" || return 1
    manifest_sha=$(file_sha256 "$OUTPUT_DIR/installed-module-object-manifest.txt")
    count=$(wc -l < "$OUTPUT_DIR/installed-module-object-manifest.txt")
    if [ "$TEST_MODE" = 1 ] && [ -n "${ROLLBACK_RETURN_CLOSURE_TEST_MODULE_MANIFEST_SHA256:-}" ]; then
        [ "$manifest_sha" = "$ROLLBACK_RETURN_CLOSURE_TEST_MODULE_MANIFEST_SHA256" ] || return 1
        [ "$count" -eq "${ROLLBACK_RETURN_CLOSURE_TEST_MODULE_COUNT:-1}" ] || return 1
    else
        [ "$manifest_sha" = "$ACCEPTED_MODULE_MANIFEST_SHA" ] || return 1
        [ "$count" -eq "$ACCEPTED_MODULE_COUNT" ] || return 1
    fi
    require_regular_file "$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL/modules.dep")" || return 1
    require_regular_file "$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL/modules.alias")" || return 1

    validate_grub_semantics || return 1
    if [ "$TEST_MODE" != 1 ]; then
        command -v grub-script-check >/dev/null 2>&1 || return 1
        grub-script-check "$grub" > "$OUTPUT_DIR/grub-script-check.log" 2>&1 || return 1
    else
        printf 'synthetic grub-script-check PASS\n' > "$OUTPUT_DIR/grub-script-check.log"
    fi
    grubenv=$(rooted /boot/grub/grubenv)
    if [ -f "$grubenv" ] && [ ! -L "$grubenv" ]; then
        if [ "$TEST_MODE" = 1 ]; then cat "$grubenv" > "$OUTPUT_DIR/grubenv.list"; else grub-editenv "$grubenv" list > "$OUTPUT_DIR/grubenv.list" 2>&1 || return 1; fi
        ! grep -q '^next_entry=' "$OUTPUT_DIR/grubenv.list" || return 1
        ! grep -Fq "saved_entry=$ACCEPTED_GRUB_ENTRY_ID" "$OUTPUT_DIR/grubenv.list" || return 1
    else
        : > "$OUTPUT_DIR/grubenv.list"
    fi
}

write_closure_record() {
    python3 - "$OUTPUT_DIR/closure.json" "$CONFIRM_RETURN_REVIEW_EVIDENCE_SHA256" "$CONFIRM_CLOSURE_SHA256" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ACCEPTED_RETURN" <<'PY'
import json,pathlib,sys
out,evidence,scope,active,rollback,accepted_path=sys.argv[1:]
a=json.load(open(accepted_path,encoding='utf-8'))
data={
 'schema':1,'scenario':'current-rollback-return-verification-closure','target':'slackware-current','result':'PASS',
 'accepted_return_review_archive_sha256':evidence,'closure_scope_sha256':scope,
 'active_kernel':active,'rollback_kernel':rollback,'running_kernel':active,'normal_return_verified':True,
 'rollback_boot_verified':True,'rollback_retained':True,'rollback_boot_demonstration_closed':True,
 'pause_safe':True,'current_work_remaining':False,'mandatory_work_remaining':False,
 'active_kernel_sha256':a['active_kernel_sha256'],'active_initrd_sha256':a['active_initrd_sha256'],
 'rollback_kernel_sha256':a['rollback_kernel_sha256'],'rollback_initrd_sha256':a['rollback_initrd_sha256'],
 'installed_module_object_manifest_sha256':a['installed_module_object_manifest_sha256'],
 'installed_module_object_count':a['installed_module_object_count'],'grub_fragment_sha256':a['grub_fragment_sha256'],
 'grub_entry_id':a['grub_entry_id'],'grub_entry_title':a['grub_entry_title'],
 'package_database_mutated':False,'grub_configuration_mutated':False,'grubenv_mutated':False,
 'repository_metadata_refreshed':False,'reboot_performed':False,
 'next_stage':'slackware-15.0-elilo-preflight-repeat-review'
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

write_result_files() {
    local result=$1
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-rollback-return-verification-closure
target=slackware-current
result=$result
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
running_kernel=$(runtime_kernel 2>/dev/null || printf unknown)
return_review_evidence_sha256=$CONFIRM_RETURN_REVIEW_EVIDENCE_SHA256
closure_scope_sha256=$CONFIRM_CLOSURE_SHA256
normal_return_verified=$RETURN_VERIFIED
rollback_retained=$ROLLBACK_RETAINED
rollback_boot_demonstration_closed=$ROLLBACK_BOOT_DEMONSTRATION_CLOSED
pause_safe=$PAUSE_SAFE
current_work_remaining=$CURRENT_WORK_REMAINING
mandatory_work_remaining=false
repository_metadata_refreshed=false
package_database_mutated=false
grub_configuration_mutated=false
grubenv_mutated=false
reboot_performed=false
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

archive_evidence() {
    local parent base archive sidecar owner group
    parent=$(dirname -- "$OUTPUT_DIR"); base=$(basename -- "$OUTPUT_DIR")
    archive=$parent/$base.tar.gz; sidecar=$archive.sha256
    [ ! -e "$archive" ] && [ ! -L "$archive" ] && [ ! -e "$sidecar" ] && [ ! -L "$sidecar" ] || return 1
    tar -czf "$archive" -C "$parent" "$base" || return 1
    sha256sum "$archive" > "$sidecar" || return 1
    owner=${SUDO_USER:-${USER:-root}}; group=$(id -gn "$owner" 2>/dev/null || printf users)
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(file_sha256 "$archive")"
    printf 'Copy evidence pair command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "/home/$owner/${base}.tar.gz" "$owner" "$group" "$sidecar" "/home/$owner/${base}.tar.gz.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${base}.tar.gz.sha256"
}

main() {
    local result=FAIL
    parse_arguments "$@" || { print_usage >&2; return 2; }
    require_regular_file "$POLICY" && require_regular_file "$ACCEPTED_RETURN" || { error 'policy or accepted step-91 record is unavailable'; return 1; }
    validate_static_boundary || { error 'the accepted step-91 return review, exact closure code, or confirmation scope does not match'; return 1; }
    initialize_output || { error 'could not initialize the evidence directory'; return 1; }
    load_accepted_values || { record_failure 'the accepted step-91 values could not be loaded'; write_result_files FAIL; archive_evidence || true; return 1; }
    record_pass "the accepted step-91 rollback verification, exact code, and closure scope are bound"

    if resolve_package_database && capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        BEFORE_PACKAGES_SHA256=$(file_sha256 "$OUTPUT_DIR/packages.before.txt")
        BEFORE_SENSITIVE_SHA256=$(file_sha256 "$OUTPUT_DIR/sensitive.before.txt")
        record_pass "the package database and rollback-sensitive state were captured before final return verification"
    else
        record_failure "the pre-verification package or rollback-sensitive state could not be captured"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        record_skip "final return verification requires the captured baseline"
    elif [ "$BEFORE_PACKAGES_SHA256" = "$ACCEPTED_PACKAGE_DB_SHA" ] && validate_live_return; then
        RETURN_VERIFIED=true
        ROLLBACK_RETAINED=true
        record_pass "the normal GRUB default returned to 6.18.42 and the tested 6.18.40 rollback remains complete on disk"
    else
        record_failure "the active return runtime, retained rollback, package database, or persistent GRUB boundary does not match step 91"
    fi

    if [ "$FAILURE_COUNT" -ne 0 ] || [ "$RETURN_VERIFIED" != true ]; then
        record_skip "closure requires a verified normal return and retained rollback"
    elif write_closure_record; then
        ROLLBACK_BOOT_DEMONSTRATION_CLOSED=true
        PAUSE_SAFE=true
        CURRENT_WORK_REMAINING=false
        NEXT_STAGE=slackware-15.0-elilo-preflight-repeat-review
        record_pass "the optional Slackware-current rollback boot demonstration is closed and the host is safe to pause"
    else
        record_failure "the final closure record could not be emitted"
    fi

    if capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && [ "$(file_sha256 "$OUTPUT_DIR/packages.after.txt")" = "$BEFORE_PACKAGES_SHA256" ] \
        && [ "$(file_sha256 "$OUTPUT_DIR/sensitive.after.txt")" = "$BEFORE_SENSITIVE_SHA256" ]; then
        record_pass "the final return verification did not modify packages, boot artifacts, GRUB, or grubenv"
    else
        record_failure "the final return verification changed or could not re-capture the protected state"
        RETURN_VERIFIED=false
        ROLLBACK_BOOT_DEMONSTRATION_CLOSED=false
        PAUSE_SAFE=false
        CURRENT_WORK_REMAINING=true
        NEXT_STAGE=current-rollback-return-verification-manual-review
        rm -f -- "$OUTPUT_DIR/closure.json"
    fi

    [ "$FAILURE_COUNT" -eq 0 ] && result=PASS
    write_result_files "$result"
    archive_evidence || return 1
    printf 'Result: %s (%d passes, %d failures, %d skips); normal_return_verified=%s; rollback_retained=%s; rollback_boot_demonstration_closed=%s; pause_safe=%s; current_work_remaining=%s; next_stage=%s\n' \
        "$result" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$RETURN_VERIFIED" "$ROLLBACK_RETAINED" "$ROLLBACK_BOOT_DEMONSTRATION_CLOSED" "$PAUSE_SAFE" "$CURRENT_WORK_REMAINING" "$NEXT_STAGE"
    if [ "$result" = PASS ]; then
        printf 'Verified normal-return kernel: %s\n' "$CONFIRM_ACTIVE_KERNEL"
        printf 'Retained tested rollback kernel: %s\n' "$CONFIRM_ROLLBACK_KERNEL"
    fi
    [ "$FAILURE_COUNT" -eq 0 ]
}

main "$@"
