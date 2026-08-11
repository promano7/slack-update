#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
umask 077
LC_ALL=C
export LC_ALL
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-authorized-apply.sh
POLICY=${ELILO_CLEANUP_APPLY_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-policy.json}
ACCEPTED_AUTH=${ELILO_CLEANUP_ACCEPTED_AUTH_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-20260811-accepted.json}
ACCEPTED_PLAN=${ELILO_CLEANUP_ACCEPTED_PLAN_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json}
ACCEPTED_REVISION=${ELILO_CLEANUP_ACCEPTED_REVISION_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-review-20260811-accepted.json}

TARGET=
EXECUTE=0
CONFIRM_HOSTNAME_FQDN=
CONFIRM_AUTH_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_CONTRACT_SHA256=
CONFIRM_SCOPE_SHA256=
CONFIRM_REVISION_EVIDENCE_SHA256=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
APPLY_EXECUTED=false
APPLY_COMMITTED=false
RECOVERY_ATTEMPTED=false
RECOVERY_RESTORED=false
PAUSE_SAFE=false
NEXT_STAGE=elilo-oldkernel-cleanup-authorized-apply-manual-review
PACKAGE_DATABASE=
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
REMOVEPKG=${ELILO_CLEANUP_REMOVEPKG:-/sbin/removepkg}
UPGRADEPKG=${ELILO_CLEANUP_UPGRADEPKG:-/sbin/upgradepkg}
DEPMOD=${ELILO_CLEANUP_DEPMOD:-/sbin/depmod}
FAIL_AT=${ELILO_CLEANUP_FAIL_AT:-}
TRANSACTION_STARTED=false
MUTATION_STARTED=false
RUN_STAMP=
RECOVERY_DIR=
RECOVERY_RETAINED=false

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 --execute-authorized-cleanup \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-authorization-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \\
  --confirm-apply-contract-sha256 SHA256 --confirm-revision-evidence-sha256 SHA256 \\
  --confirm-apply-scope-sha256 SHA256

Apply the exact authorized ELILO oldkernel cleanup. The transaction removes only
the three reviewed 5.15.19 boot-kernel package records, reinstalls the exact
verified 5.15.209 boot-kernel archives, atomically removes the oldkernel ELILO
stanza, deletes only the now-unreferenced legacy EFI rollback kernel/initrd, and
verifies the final active boot chain. A private recovery snapshot is captured
before mutation. Any failure after mutation triggers best-effort restoration and
pause_safe=true is reported only if that restoration is proven exact.
EOF_USAGE
}
err(){ printf 'ERROR: %s\n' "$*" >&2; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
is_sha(){ [ "${#1}" -eq 64 ] && [[ $1 != *[!0-9A-Fa-f]* ]]; }
safe_ver(){ [ -n "$1" ] && [[ $1 != *[!0-9A-Za-z._+-]* ]]; }
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log" >&2; }
skip(){ SKIP_COUNT=$((SKIP_COUNT+1)); printf 'SKIP: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
rooted(){ printf '%s%s\n' "$ROOT_PREFIX" "$1"; }

parse_args(){
 while [ "$#" -gt 0 ]; do
  case "$1" in
   --target) TARGET=$2; shift 2;;
   --execute-authorized-cleanup) EXECUTE=$((EXECUTE+1)); shift;;
   --confirm-hostname-fqdn) CONFIRM_HOSTNAME_FQDN=$2; shift 2;;
   --confirm-authorization-evidence-sha256) CONFIRM_AUTH_EVIDENCE_SHA256=${2,,}; shift 2;;
   --confirm-active-kernel) CONFIRM_ACTIVE_KERNEL=$2; shift 2;;
   --confirm-rollback-kernel) CONFIRM_ROLLBACK_KERNEL=$2; shift 2;;
   --confirm-apply-contract-sha256) CONFIRM_CONTRACT_SHA256=${2,,}; shift 2;;
   --confirm-revision-evidence-sha256) CONFIRM_REVISION_EVIDENCE_SHA256=${2,,}; shift 2;;
   --confirm-apply-scope-sha256) CONFIRM_SCOPE_SHA256=${2,,}; shift 2;;
   --output-dir) OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ "$EXECUTE" -eq 1 ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] \
  && is_sha "$CONFIRM_AUTH_EVIDENCE_SHA256" && safe_ver "$CONFIRM_ACTIVE_KERNEL" \
  && safe_ver "$CONFIRM_ROLLBACK_KERNEL" && [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] \
  && is_sha "$CONFIRM_CONTRACT_SHA256" && is_sha "$CONFIRM_REVISION_EVIDENCE_SHA256" && is_sha "$CONFIRM_SCOPE_SHA256"
}

json_get(){ python3 - "$1" "$2" <<'PY'
import json,sys
v=json.load(open(sys.argv[1],encoding='utf-8'))
for p in sys.argv[2].split('.'): v=v[p]
if isinstance(v,bool): print(str(v).lower())
elif isinstance(v,(dict,list)): print(json.dumps(v,sort_keys=True,separators=(',',':')))
else: print(v)
PY
}

validate_static(){
 python3 - "$POLICY" "$SELF" "$ACCEPTED_AUTH" "$ACCEPTED_PLAN" "$ACCEPTED_REVISION" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_AUTH_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_CONTRACT_SHA256" "$CONFIRM_REVISION_EVIDENCE_SHA256" "$CONFIRM_SCOPE_SHA256" <<'PY'
import hashlib,json,pathlib,sys
pol,script,auth,plan,revision,host,evidence,active,rollback,contract,revision_evidence,scope_confirm=sys.argv[1:]
def reg(p):
 p=pathlib.Path(p)
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return p
def sh(p): return hashlib.sha256(reg(p).read_bytes()).hexdigest()
p=json.loads(reg(pol).read_text()); a=json.loads(reg(auth).read_text()); pl=json.loads(reg(plan).read_text()); r=json.loads(reg(revision).read_text())
scope=(
'operation=elilo-oldkernel-cleanup-authorized-apply-revision-1\n'
'target=slackware-15.0\n'
f'hostname_fqdn={host}\n'+f'authorization_evidence_sha256={evidence}\n'+f'revision_evidence_sha256={revision_evidence}\n'+f'active_kernel={active}\n'+f'rollback_kernel={rollback}\n'+f'apply_contract_sha256={contract}\n'+f'accepted_authorization_record_sha256={sh(auth)}\n'+f'accepted_revision_record_sha256={sh(revision)}\n'+f'authorized_apply_script_sha256={sh(script)}\n').encode()
calc=hashlib.sha256(scope).hexdigest()
checks=[p.get('schema')==2,p.get('scenario')=='elilo-oldkernel-cleanup-authorized-apply-revision-1',p.get('reviewed') is True,
 p.get('expected_script_sha256')==sh(script),p.get('accepted_authorization_record_sha256')==sh(auth),
 p.get('accepted_source_plan_record_sha256')==sh(plan),p.get('accepted_revision_record_sha256')==sh(revision),
 p.get('accepted_authorization_archive_sha256')==evidence,p.get('accepted_revision_archive_sha256')==revision_evidence,
 p.get('apply_contract_sha256')==contract,p.get('confirmation_scope_sha256')==scope_confirm==calc,
 a.get('status')=='accepted-authorization-review',a.get('archive_sha256')==evidence,a.get('cleanup_authorized') is True,
 a.get('apply_authorized') is True,a.get('apply_executed') is False,a.get('hostname_fqdn')==host,
 a.get('active_kernel')==active,a.get('rollback_kernel')==rollback,a.get('apply_contract_sha256')==contract,
 r.get('status')=='accepted-apply-revision-review',r.get('archive_sha256')==revision_evidence,
 r.get('retry_authorized') is True,r.get('apply_executed') is False,r.get('hostname_fqdn')==host,
 r.get('active_kernel')==active,r.get('rollback_kernel')==rollback,r.get('base_apply_contract_sha256')==contract,
 r.get('revised_apply_script_sha256')==sh(script),
 pl.get('accepted') is True,pl.get('cleanup_plan_sha256')==a.get('cleanup_plan_sha256')]
raise SystemExit(0 if all(checks) else 1)
PY
}
init_output(){
 local base recovery_base
 RUN_STAMP=$(date -u +%Y%m%dT%H%M%SZ) || return 1
 if [ -z "$OUTPUT_DIR" ]; then base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorized-apply; install -d -m 0700 -- "$base" || return 1; OUTPUT_DIR=$base/slackware-15.0-$RUN_STAMP; fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
 install -d -m 0700 -- "$OUTPUT_DIR" || return 1
 recovery_base=$(rooted /var/lib/slack-update/elilo-cleanup-backups)
 RECOVERY_DIR=$recovery_base/$CONFIRM_ROLLBACK_KERNEL-$RUN_STAMP
 [ ! -e "$RECOVERY_DIR" ] && [ ! -L "$RECOVERY_DIR" ] || return 1
 printf '%s\n' "$RECOVERY_DIR" > "$OUTPUT_DIR/recovery-location.txt"
 : > "$OUTPUT_DIR/assertions.log"
}

resolve_pkgdb(){ local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages; if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a; elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b"); elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b; else return 1; fi; }
capture_names(){ find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"; }
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE_KERNEL}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_TEST_HOSTNAME_FQDN:-$CONFIRM_HOSTNAME_FQDN}"; else hostname -f; fi; }

capture_boot_selected(){
 python3 - "$ROOT_PREFIX" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$1" <<'PY'
import hashlib,pathlib,sys
root=pathlib.Path(sys.argv[1] or '/'); active,old=sys.argv[2:4]; out=pathlib.Path(sys.argv[4])
paths=['/boot/efi/EFI/Slackware/elilo.conf',f'/boot/vmlinuz-generic-{active}',f'/boot/initrd-generic-{active}.gz',f'/boot/vmlinuz-generic-{old}','/boot/initrd.gz',f'/boot/efi/EFI/Slackware/vmlinuz-generic-{active}',f'/boot/efi/EFI/Slackware/initrd-generic-{active}.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=[]
for logical in paths:
 p=root/logical.lstrip('/')
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {logical}\n")
out.write_text(''.join(rows))
PY
}

module_manifest(){
 local version=$1 out=$2 dir; dir=$(rooted "/lib/modules/$version")
 [ -d "$dir" ] && [ ! -L "$dir" ] || return 1
 (cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do sha256sum -- "$f"; done) > "$out"
}
is_generated_depmod_index(){
 case "$1" in
  ./modules.alias|./modules.alias.bin|./modules.dep|./modules.dep.bin|./modules.symbols|./modules.symbols.bin) return 0;;
  *) return 1;;
 esac
}
module_stable_manifest(){
 local version=$1 out=$2 dir; dir=$(rooted "/lib/modules/$version")
 [ -d "$dir" ] && [ ! -L "$dir" ] || return 1
 (
  cd "$dir" || exit 1
  find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do
   is_generated_depmod_index "$f" || sha256sum -- "$f"
  done
 ) > "$out"
}
module_object_manifest(){
 local version=$1 out=$2 dir; dir=$(rooted "/lib/modules/$version")
 [ -d "$dir" ] && [ ! -L "$dir" ] || return 1
 (cd "$dir" && find . -type f -name '*.ko*' -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do sha256sum -- "$f"; done) > "$out"
}
verify_generated_depmod_indexes(){
 local version=$1 dir f; dir=$(rooted "/lib/modules/$version")
 for f in modules.alias modules.alias.bin modules.dep modules.dep.bin modules.symbols modules.symbols.bin; do
  [ -f "$dir/$f" ] && [ ! -L "$dir/$f" ] || return 1
 done
 "$DEPMOD" -n "$version" >/dev/null 2>&1
}

verify_live_boundary(){
 local ok=true expected rec path digest
 [ "$(runtime_fqdn 2>/dev/null)" = "$CONFIRM_HOSTNAME_FQDN" ] || ok=false
 [ "$(runtime_kernel 2>/dev/null)" = "$CONFIRM_ACTIVE_KERNEL" ] || ok=false
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || ok=false
 resolve_pkgdb || ok=false
 capture_names "$OUTPUT_DIR/packages.before.txt" || ok=false
 expected=$(json_get "$ACCEPTED_PLAN" package_name_snapshot_sha256) || ok=false
 [ "$(sha "$OUTPUT_DIR/packages.before.txt" 2>/dev/null)" = "$expected" ] || ok=false
 capture_boot_selected "$OUTPUT_DIR/boot.before.sha256" || ok=false
 expected=$(json_get "$ACCEPTED_PLAN" boot_state_snapshot_sha256) || ok=false
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256" 2>/dev/null)" = "$expected" ] || ok=false
 module_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/modules-active.before.sha256" || ok=false
 module_manifest "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/modules-rollback.before.sha256" || ok=false
 module_stable_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/modules-active-stable.before.sha256" || ok=false
 module_object_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/modules-active-objects.before.sha256" || ok=false
 while IFS=$'\t' read -r rec path digest; do
   [ -f "$(rooted "$path")" ] && [ ! -L "$(rooted "$path")" ] && [ "$(sha "$(rooted "$path")" 2>/dev/null)" = "$digest" ] || ok=false
 done < <(python3 - "$ACCEPTED_PLAN" <<'PY'
import json,sys
for x in json.load(open(sys.argv[1]))['active_archives']: print(x['record']+'\t'+x['path']+'\t'+x['sha256'])
PY
)
 for rec in $(python3 - "$ACCEPTED_PLAN" <<'PY'
import json,sys
for x in json.load(open(sys.argv[1]))['rollback_packages']: print(x)
PY
); do [ -f "$PACKAGE_DATABASE/$rec" ] || ok=false; done
 [ "$ok" = true ]
}

check_space_and_backup(){
 local recovery=$RECOVERY_DIR need avail rootbase recovery_base
 rootbase=${ROOT_PREFIX:-/}
 recovery_base=${recovery%/*}
 install -d -m 0700 -- "$recovery_base" || return 1
 install -d -m 0700 -- "$recovery" || return 1
 need=$(du -sb -- "$(rooted /boot)" "$(rooted "/lib/modules/$CONFIRM_ACTIVE_KERNEL")" "$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")" "$(rooted /var/lib/pkgtools)" 2>/dev/null | awk '{s+=$1} END{print s+134217728}') || return 1
 avail=$(df -B1 --output=avail "$recovery" | tail -n1 | tr -d ' ') || return 1
 [ "$avail" -ge "$need" ] || return 1
 tar -C "$rootbase" -cpf "$recovery/boot.tar" boot || return 1
 tar -C "$rootbase" -cpf "$recovery/modules.tar" "lib/modules/$CONFIRM_ACTIVE_KERNEL" "lib/modules/$CONFIRM_ROLLBACK_KERNEL" || return 1
 tar -C "$rootbase" -cpf "$recovery/pkgtools.tar" var/lib/pkgtools || return 1
 cp -a -- "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/boot.before.sha256" "$OUTPUT_DIR/modules-active.before.sha256" "$OUTPUT_DIR/modules-rollback.before.sha256" "$OUTPUT_DIR/modules-active-stable.before.sha256" "$OUTPUT_DIR/modules-active-objects.before.sha256" "$recovery/" || return 1
 (cd "$recovery" && sha256sum boot.tar modules.tar pkgtools.tar) > "$recovery/archive.sha256" || return 1
 cp -a -- "$recovery/archive.sha256" "$OUTPUT_DIR/recovery-archive.sha256" || return 1
 RECOVERY_RETAINED=true
}

maybe_fail(){ [ "$FAIL_AT" != "$1" ]; }

run_remove(){ local rec; while IFS= read -r rec; do "$REMOVEPKG" "$rec" >> "$OUTPUT_DIR/removepkg.log" 2>&1 || return 1; done < <(python3 - "$ACCEPTED_PLAN" <<'PY'
import json,sys
for x in json.load(open(sys.argv[1]))['rollback_packages']: print(x)
PY
); }
run_reinstall(){ local path; while IFS= read -r path; do "$UPGRADEPKG" --reinstall "$(rooted "$path")" >> "$OUTPUT_DIR/upgradepkg.log" 2>&1 || return 1; done < <(python3 - "$ACCEPTED_PLAN" <<'PY'
import json,sys
for x in json.load(open(sys.argv[1]))['active_archives']: print(x['path'])
PY
); }

verify_active_after_packages(){
 local rec
 [ "$(runtime_kernel)" = "$CONFIRM_ACTIVE_KERNEL" ] || return 1
 python3 - "$PACKAGE_DATABASE" "$ACCEPTED_PLAN" <<'PY'
import json,pathlib,sys
p=pathlib.Path(sys.argv[1]); a=json.load(open(sys.argv[2]))
for rec in a['active_packages']+a['other_kernel_packages_preserved']:
 if not (p/rec).is_file(): raise SystemExit(1)
for rec in a['rollback_packages']:
 if (p/rec).exists(): raise SystemExit(1)
PY
 [ -n "$(find "$(rooted "/lib/modules/$CONFIRM_ACTIVE_KERNEL")" -type f -print -quit 2>/dev/null)" ] || return 1
}

stage_elilo(){
 local conf staged; conf=$(rooted /boot/efi/EFI/Slackware/elilo.conf); staged=$(rooted /boot/efi/EFI/Slackware/.elilo.conf.slack-update.new)
 [ ! -e "$staged" ] && [ ! -L "$staged" ] || return 1
 python3 - "$conf" "$staged" "$CONFIRM_ACTIVE_KERNEL" <<'PY'
import pathlib,re,sys
src=pathlib.Path(sys.argv[1]); dst=pathlib.Path(sys.argv[2]); active=sys.argv[3]
lines=src.read_text(encoding='utf-8').splitlines(True)
starts=[i for i,l in enumerate(lines) if re.match(r'^\s*image\s*=',l,re.I)]
starts.append(len(lines)); blocks=[]
for a,b in zip(starts,starts[1:]):
 block=lines[a:b]; vals={}
 for l in block:
  m=re.match(r'^\s*([A-Za-z0-9_-]+)\s*=\s*(\S+)\s*$',l.strip())
  if m: vals[m.group(1).lower()]=m.group(2)
 blocks.append((a,b,vals))
old=[x for x in blocks if x[2].get('label')=='oldkernel']
act=[x for x in blocks if x[2].get('label')=='vmlinuz']
if len(old)!=1 or len(act)!=1: raise SystemExit(1)
if act[0][2].get('image')!=f'vmlinuz-generic-{active}' or act[0][2].get('initrd')!=f'initrd-generic-{active}.gz': raise SystemExit(1)
if sum(1 for l in lines if re.match(r'^\s*default\s*=\s*vmlinuz\s*$',l,re.I))!=1: raise SystemExit(1)
a,b,_=old[0]; out=lines[:a]+lines[b:]
dst.write_text(''.join(out),encoding='utf-8')
PY
 chmod 0600 "$staged" 2>/dev/null || true
}
validate_staged_elilo(){
 python3 - "$(rooted /boot/efi/EFI/Slackware/.elilo.conf.slack-update.new)" "$CONFIRM_ACTIVE_KERNEL" <<'PY'
import pathlib,re,sys
p=pathlib.Path(sys.argv[1]); active=sys.argv[2]; lines=p.read_text().splitlines(); text='\n'.join(lines)
if re.search(r'^\s*label\s*=\s*oldkernel\s*$',text,re.M|re.I): raise SystemExit(1)
if len(re.findall(r'^\s*label\s*=\s*vmlinuz\s*$',text,re.M|re.I))!=1: raise SystemExit(1)
if len(re.findall(r'^\s*image\s*=\s*vmlinuz-generic-'+re.escape(active)+r'\s*$',text,re.M|re.I))!=1: raise SystemExit(1)
if len(re.findall(r'^\s*initrd\s*=\s*initrd-generic-'+re.escape(active)+r'\.gz\s*$',text,re.M|re.I))!=1: raise SystemExit(1)
if len(re.findall(r'^\s*default\s*=\s*vmlinuz\s*$',text,re.M|re.I))!=1: raise SystemExit(1)
PY
}
activate_elilo(){ mv -- "$(rooted /boot/efi/EFI/Slackware/.elilo.conf.slack-update.new)" "$(rooted /boot/efi/EFI/Slackware/elilo.conf)" && sync; }
prove_unreferenced(){ ! grep -Eq '^[[:space:]]*label[[:space:]]*=[[:space:]]*oldkernel[[:space:]]*$' "$(rooted /boot/efi/EFI/Slackware/elilo.conf)"; }
verify_active_boot(){
 local p h kernel_hash initrd_hash
 kernel_hash=$(json_get "$ACCEPTED_PLAN" elilo.active_kernel_sha256) || return 1
 initrd_hash=$(json_get "$ACCEPTED_PLAN" elilo.active_initrd_sha256) || return 1
 for spec in "/boot/vmlinuz-generic-$CONFIRM_ACTIVE_KERNEL:$kernel_hash" "/boot/initrd-generic-$CONFIRM_ACTIVE_KERNEL.gz:$initrd_hash" "/boot/efi/EFI/Slackware/vmlinuz-generic-$CONFIRM_ACTIVE_KERNEL:$kernel_hash" "/boot/efi/EFI/Slackware/initrd-generic-$CONFIRM_ACTIVE_KERNEL.gz:$initrd_hash"; do p=${spec%%:*}; h=${spec#*:}; [ "$(sha "$(rooted "$p")" 2>/dev/null)" = "$h" ] || return 1; done
 prove_unreferenced
}
delete_efi_rollback(){ rm -- "$(rooted /boot/efi/EFI/Slackware/vmlinuz)" "$(rooted /boot/efi/EFI/Slackware/initrd.gz)"; }

capture_final(){
 capture_names "$OUTPUT_DIR/packages.after.txt" || return 1
 module_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/modules-active.after.sha256" || return 1
 module_stable_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/modules-active-stable.after.sha256" || return 1
 module_object_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/modules-active-objects.after.sha256" || return 1
}
verify_final(){
 python3 - "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" "$ACCEPTED_PLAN" <<'PY'
import json,sys
before=set(open(sys.argv[1]).read().splitlines()); after=set(open(sys.argv[2]).read().splitlines()); a=json.load(open(sys.argv[3]))
if after != before-set(a['rollback_packages']): raise SystemExit(1)
PY
 cmp -s "$OUTPUT_DIR/modules-active-stable.before.sha256" "$OUTPUT_DIR/modules-active-stable.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/modules-active-objects.before.sha256" "$OUTPUT_DIR/modules-active-objects.after.sha256" || return 1
 verify_generated_depmod_indexes "$CONFIRM_ACTIVE_KERNEL" || return 1
 [ ! -e "$(rooted /boot/efi/EFI/Slackware/vmlinuz)" ] && [ ! -e "$(rooted /boot/efi/EFI/Slackware/initrd.gz)" ] || return 1
 [ ! -e "$(rooted "/boot/vmlinuz-generic-$CONFIRM_ROLLBACK_KERNEL")" ] || return 1
 if [ -d "$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")" ]; then [ -z "$(find "$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")" -type f -name '*.ko*' -print -quit 2>/dev/null)" ] || return 1; fi
 verify_active_boot
}
recover(){
 local recovery=$RECOVERY_DIR rootbase=${ROOT_PREFIX:-/}
 RECOVERY_ATTEMPTED=true
 (cd "$recovery" && sha256sum -c archive.sha256) > "$OUTPUT_DIR/recovery-archive-verify.log" 2>&1 || return 1
 rm -f -- "$(rooted /boot/efi/EFI/Slackware/.elilo.conf.slack-update.new)" 2>/dev/null || true
 tar -C "$rootbase" -xpf "$recovery/boot.tar" >/dev/null 2>&1 || return 1
 rm -rf -- "$(rooted "/lib/modules/$CONFIRM_ACTIVE_KERNEL")" "$(rooted "/lib/modules/$CONFIRM_ROLLBACK_KERNEL")" || return 1
 tar -C "$rootbase" -xpf "$recovery/modules.tar" >/dev/null 2>&1 || return 1
 rm -rf -- "$(rooted /var/lib/pkgtools)" || return 1
 tar -C "$rootbase" -xpf "$recovery/pkgtools.tar" >/dev/null 2>&1 || return 1
 resolve_pkgdb || return 1
 install -d -m 0700 -- "$OUTPUT_DIR/recovery-restored" || return 1
 capture_names "$OUTPUT_DIR/recovery-restored/packages.restored.txt" || return 1
 capture_boot_selected "$OUTPUT_DIR/recovery-restored/boot.restored.sha256" || return 1
 module_manifest "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/recovery-restored/modules-active.restored.sha256" || return 1
 module_manifest "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/recovery-restored/modules-rollback.restored.sha256" || return 1
 cmp -s "$recovery/packages.before.txt" "$OUTPUT_DIR/recovery-restored/packages.restored.txt" \
  && cmp -s "$recovery/boot.before.sha256" "$OUTPUT_DIR/recovery-restored/boot.restored.sha256" \
  && cmp -s "$recovery/modules-active.before.sha256" "$OUTPUT_DIR/recovery-restored/modules-active.restored.sha256" \
  && cmp -s "$recovery/modules-rollback.before.sha256" "$OUTPUT_DIR/recovery-restored/modules-rollback.restored.sha256" || return 1
 RECOVERY_RESTORED=true; PAUSE_SAFE=true; NEXT_STAGE=elilo-oldkernel-cleanup-authorized-apply-recovery-review
}

write_result(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-authorized-apply
target=$TARGET
hostname=$CONFIRM_HOSTNAME_FQDN
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
authorization_evidence_sha256=$CONFIRM_AUTH_EVIDENCE_SHA256
revision_evidence_sha256=$CONFIRM_REVISION_EVIDENCE_SHA256
apply_contract_sha256=$CONFIRM_CONTRACT_SHA256
apply_executed=$APPLY_EXECUTED
apply_committed=$APPLY_COMMITTED
recovery_attempted=$RECOVERY_ATTEMPTED
recovery_restored=$RECOVERY_RESTORED
recovery_backup_retained=$RECOVERY_RETAINED
recovery_backup_path=$RECOVERY_DIR
pause_safe=$PAUSE_SAFE
reboot_required=$APPLY_COMMITTED
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY
}
publish(){ local base archive side owner group; base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorized-apply; archive=$base/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-$(date -u +%Y%m%dT%H%M%SZ).tar.gz; side=$archive.sha256; install -d -m 0700 -- "$base" || return 1; tar -C "$(dirname "$OUTPUT_DIR")" -czf "$archive" "$(basename "$OUTPUT_DIR")" || return 1; chmod 0600 "$archive"; (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side" || return 1; chmod 0600 "$side"; printf 'Evidence archive: %s\n' "$archive"; printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$side")"; owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users); printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"; printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"; }

main(){
 parse_args "$@" || { usage >&2; return 2; }
 [ "$(id -u)" -eq 0 ] || { err 'must run as root'; return 2; }
 if [ "$TEST_MODE" != 1 ]; then
  [ -z "$ROOT_PREFIX" ] && [ "$REMOVEPKG" = /sbin/removepkg ] && [ "$UPGRADEPKG" = /sbin/upgradepkg ] && [ "$DEPMOD" = /sbin/depmod ] && [ -z "$FAIL_AT" ] || { err 'test-only overrides are forbidden in production mode'; return 2; }
 fi
 init_output || return 2
 if validate_static; then pass 'the accepted step-94 authorization, accepted revision review, exact revised code, apply contract, and execution scope are bound'; else fail 'the static authorized cleanup boundary does not match'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_live_boundary; then pass 'the live 5.15.209 ELILO state, exact package set, module trees, boot artifacts, and cached active archives still match the authorization boundary'; else if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the live cleanup boundary drifted before execution'; else skip 'live validation requires a valid static boundary'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && check_space_and_backup; then pass 'a private recovery snapshot and sufficient recovery space were secured before mutation'; else if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the recovery snapshot could not be secured safely'; else skip 'recovery capture requires a valid live boundary'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then
  TRANSACTION_STARTED=true
  MUTATION_STARTED=true
  APPLY_EXECUTED=true
  if maybe_fail remove_exact_rollback_package_records && run_remove; then pass 'the exact three rollback package records were removed'; else fail 'rollback package removal failed or was intentionally interrupted'; fi
 fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if maybe_fail reinstall_exact_active_package_set && run_reinstall; then pass 'the exact three verified active 5.15.209 packages were reinstalled'; else fail 'active package reinstallation failed or was intentionally interrupted'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_active_after_packages; then pass 'the active package records and module tree are intact and the rollback records are absent'; else fail 'package or module state is unsafe after the package transaction'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if maybe_fail stage_elilo_config_without_oldkernel && stage_elilo && validate_staged_elilo; then pass 'a validated ELILO configuration without oldkernel was staged without in-place editing'; else fail 'the staged ELILO configuration could not be produced safely'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if maybe_fail atomically_activate_elilo_config && activate_elilo && prove_unreferenced; then pass 'the oldkernel-free ELILO configuration was atomically activated and no longer references rollback'; else fail 'ELILO activation or oldkernel dereference proof failed'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_active_boot; then pass 'the active 5.15.209 boot chain remains byte-identical across /boot and EFI'; else fail 'the active boot chain changed unexpectedly'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if maybe_fail delete_only_unreferenced_rollback_artifacts && delete_efi_rollback; then pass 'only the two unreferenced legacy EFI rollback artifacts were deleted'; else fail 'rollback artifact deletion failed or was intentionally interrupted'; fi; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if maybe_fail capture_and_compare_final_state && capture_final && verify_final; then APPLY_COMMITTED=true; PAUSE_SAFE=true; NEXT_STAGE=elilo-oldkernel-cleanup-post-apply-reboot-review; pass 'the cleanup transaction is committed and the final active boot/package state is coherent'; else fail 'the final cleanup state did not satisfy the reviewed contract'; fi; fi
 if [ "$FAILURE_COUNT" -gt 0 ] && [ "$MUTATION_STARTED" = true ]; then if recover; then pass 'the failed transaction was restored exactly to its pre-apply package, boot, and module state'; else PAUSE_SAFE=false; NEXT_STAGE=elilo-oldkernel-cleanup-emergency-recovery; fail 'automatic recovery could not prove exact restoration'; fi; fi
 write_result
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); apply_executed=%s; apply_committed=%s; recovery_attempted=%s; recovery_restored=%s; recovery_backup_retained=%s; pause_safe=%s; reboot_required=%s; next_stage=%s\n' "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$APPLY_EXECUTED" "$APPLY_COMMITTED" "$RECOVERY_ATTEMPTED" "$RECOVERY_RESTORED" "$RECOVERY_RETAINED" "$PAUSE_SAFE" "$APPLY_COMMITTED" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
