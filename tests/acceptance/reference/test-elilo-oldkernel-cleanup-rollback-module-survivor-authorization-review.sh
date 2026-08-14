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
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review.sh
POLICY=${ELILO_CLEANUP_SURVIVOR_AUTH_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review-policy.json}
ACCEPTED_REVIEW=${ELILO_CLEANUP_SURVIVOR_AUTH_ACCEPTED_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-revision-review-20260814-accepted.json}

TARGET=
HOST=
REVIEW_EVIDENCE_SHA=
ACTIVE=
ROLLBACK=
SCOPE=
OUTPUT_DIR=
PACKAGE_DATABASE=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
SURVIVOR_DELETION_AUTHORIZED=false
RECURSIVE_REMOVAL_AUTHORIZED=false
ACTIVE_COUNTERPART_REMOVAL_AUTHORIZED=false
THIRD_ATTEMPT_AUTHORIZED=false
PAUSE_SAFE=false
NEXT_STAGE=elilo-oldkernel-cleanup-rollback-module-survivor-authorization-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
MODINFO=${ELILO_CLEANUP_SURVIVOR_AUTH_MODINFO:-/sbin/modinfo}

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-survivor-review-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \\
  --confirm-survivor-authorization-sha256 SHA256

Authorize only deletion of the exact three reviewed package-unowned rollback
VirtualBox module objects during a later revised cleanup transaction. This
review is strictly non-mutating. Recursive rollback-tree removal, active-module
removal, and a third cleanup attempt remain unauthorized.
EOF_USAGE
}
err(){ printf 'ERROR: %s\n' "$*" >&2; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
is_sha(){ [ "${#1}" -eq 64 ] && [[ $1 != *[!0-9A-Fa-f]* ]]; }
safe_ver(){ [ -n "$1" ] && [[ $1 != *[!0-9A-Za-z._+-]* ]]; }
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log" >&2; }
rooted(){ printf '%s%s\n' "$ROOT_PREFIX" "$1"; }

parse_args(){
 while [ "$#" -gt 0 ]; do
  case "$1" in
   --target) TARGET=$2; shift 2;;
   --confirm-hostname-fqdn) HOST=$2; shift 2;;
   --confirm-survivor-review-evidence-sha256) REVIEW_EVIDENCE_SHA=${2,,}; shift 2;;
   --confirm-active-kernel) ACTIVE=$2; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=$2; shift 2;;
   --confirm-survivor-authorization-sha256) SCOPE=${2,,}; shift 2;;
   --output-dir) OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ -n "$HOST" ] && is_sha "$REVIEW_EVIDENCE_SHA" \
  && safe_ver "$ACTIVE" && safe_ver "$ROLLBACK" && [ "$ACTIVE" != "$ROLLBACK" ] && is_sha "$SCOPE"
}

init_output(){
 local stamp base
 if [ -z "$OUTPUT_DIR" ]; then
  stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
  base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review
  install -d -m 0700 -- "$base" || return 1
  OUTPUT_DIR=$base/slackware-15.0-$stamp
 fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
 install -d -m 0700 -- "$OUTPUT_DIR" || return 1
 : > "$OUTPUT_DIR/assertions.log"
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
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_SURVIVOR_AUTH_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_SURVIVOR_AUTH_TEST_HOST:-$HOST}"; else hostname -f; fi; }
resolve_pkgdb(){
 local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages
 if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a
 elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b")
 elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b
 else return 1; fi
}
capture_names(){ find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"; }
module_manifest(){
 local version=$1 out=$2 dir; dir=$(rooted "/lib/modules/$version")
 [ -d "$dir" ] && [ ! -L "$dir" ] || return 1
 (cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do sha256sum -- "$f"; done) > "$out"
}
capture_boot_selected(){
 python3 - "$ROOT_PREFIX" "$ACTIVE" "$ROLLBACK" "$1" <<'PY'
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

validate_static(){
 python3 - "$POLICY" "$ACCEPTED_REVIEW" "$SELF" "$HOST" "$REVIEW_EVIDENCE_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,accepted,script=map(pathlib.Path,sys.argv[1:4]); host,evidence,active,rollback,scope=sys.argv[4:]
def fh(p):
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return hashlib.sha256(p.read_bytes()).hexdigest()
p=json.load(open(pol)); a=json.load(open(accepted))
base=a['survivor_removal_contract']
auth={
 'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-deletion-authorization-contract',
 'reviewed_survivor_contract_sha256':a['survivor_removal_contract_sha256'],
 'active_kernel':active,'rollback_kernel':rollback,'survivor_count':base['survivor_count'],'survivors':base['survivors'],
 'removal_method':base['removal_method'],'survivor_deletion_authorized':True,'recursive_module_tree_removal_authorized':False,
 'active_counterpart_removal_authorized':False,'third_attempt_authorized':False,'execution_authorized':False}
auth_sha=hashlib.sha256((json.dumps(auth,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest()
scope_bytes=(
 'operation=elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review\n'
 +'target=slackware-15.0\n'+f'hostname_fqdn={host}\n'+f'survivor_review_evidence_sha256={evidence}\n'
 +f'active_kernel={active}\nrollback_kernel={rollback}\n'+f'accepted_survivor_review_record_sha256={fh(accepted)}\n'
 +f'authorization_script_sha256={fh(script)}\n'+f'survivor_deletion_authorization_contract_sha256={auth_sha}\n').encode()
calc=hashlib.sha256(scope_bytes).hexdigest()
checks=[p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review',p.get('reviewed') is True,
 fh(script)==p.get('expected_script_sha256'),fh(accepted)==p.get('accepted_survivor_review_record_sha256'),
 evidence==p.get('accepted_survivor_review_archive_sha256')==a.get('archive_sha256'),host==p.get('hostname_fqdn')==a.get('hostname_fqdn'),
 active==p.get('active_kernel')==a.get('active_kernel'),rollback==p.get('rollback_kernel')==a.get('rollback_kernel'),
 a.get('accepted') is True,a.get('survivor_review_ready') is True,a.get('survivor_removal_scope_ready') is True,
 a.get('third_attempt_authorized') is False,a.get('cleanup_authorized') is False,a.get('apply_authorized') is False,a.get('pause_safe') is True,
 p.get('survivor_deletion_authorization_contract_sha256')==auth_sha,p.get('confirmation_scope_sha256')==scope==calc]
raise SystemExit(0 if all(checks) else 1)
PY
}

verify_live_boundary(){
 local expected
 [ "$(runtime_fqdn 2>/dev/null)" = "$HOST" ] || return 1
 [ "$(runtime_kernel 2>/dev/null)" = "$ACTIVE" ] || return 1
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || return 1
 resolve_pkgdb || return 1
 capture_names "$OUTPUT_DIR/packages.before.txt" || return 1
 expected=$(json_get "$ACCEPTED_REVIEW" package_snapshot_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/packages.before.txt")" = "$expected" ] || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_REVIEW" boot_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_REVIEW" active_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-active.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_REVIEW" rollback_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-rollback.before.sha256")" = "$expected" ] || return 1
}

verify_exact_survivors(){
 python3 - "$ACCEPTED_REVIEW" "$PACKAGE_DATABASE" "$ROOT_PREFIX" "$MODINFO" "$OUTPUT_DIR/live-survivor-check.tsv" <<'PY'
import hashlib,json,pathlib,stat,subprocess,sys
a=json.load(open(sys.argv[1])); pkgdb=pathlib.Path(sys.argv[2]); root=pathlib.Path(sys.argv[3] or '/'); modinfo=sys.argv[4]; out=pathlib.Path(sys.argv[5])
items=a['survivor_removal_contract']['survivors']
def owners(logical):
 needle=logical.lstrip('/'); found=[]
 for rec in sorted(p for p in pkgdb.iterdir() if p.is_file() and not p.is_symlink()):
  lines=rec.read_text(encoding='utf-8',errors='strict').splitlines()
  try: start=lines.index('FILE LIST:')+1
  except ValueError: continue
  listed={x.strip().removeprefix('./') for x in lines[start:] if x.strip()}
  if needle in listed: found.append(rec.name)
 return found
def field(path,name):
 cp=subprocess.run([modinfo,'-F',name,str(path)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,check=False)
 if cp.returncode!=0: raise SystemExit(1)
 return cp.stdout.strip()
def resolve(name):
 cp=subprocess.run([modinfo,'-n',name],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,check=False)
 if cp.returncode!=0: raise SystemExit(1)
 return cp.stdout.strip()
rows=[]
for x in items:
 old=root/x['rollback_path'].lstrip('/'); active=root/x['active_counterpart_path'].lstrip('/')
 for p in (old,active):
  if not p.is_file() or p.is_symlink(): raise SystemExit(1)
  st=p.stat()
  if st.st_uid!=0 or st.st_gid!=0 or stat.S_IMODE(st.st_mode)&0o022: raise SystemExit(1)
 if hashlib.sha256(old.read_bytes()).hexdigest()!=x['rollback_sha256']: raise SystemExit(1)
 if hashlib.sha256(active.read_bytes()).hexdigest()!=x['active_counterpart_sha256']: raise SystemExit(1)
 if owners(x['rollback_path']): raise SystemExit(1)
 if field(old,'name')!=x['module_name'] or field(old,'vermagic')!=x['rollback_vermagic']: raise SystemExit(1)
 if field(active,'name')!=x['module_name'] or field(active,'vermagic')!=x['active_counterpart_vermagic']: raise SystemExit(1)
 if pathlib.PurePosixPath(resolve(x['module_name']))!=pathlib.PurePosixPath(x['active_counterpart_path']): raise SystemExit(1)
 rows.append((x['rollback_path'],x['rollback_sha256'],x['active_counterpart_path'],x['active_counterpart_sha256']))
out.write_text('rollback_path\trollback_sha256\tactive_counterpart\tactive_sha256\n'+''.join('\t'.join(r)+'\n' for r in rows))
PY
}

emit_authorization(){
 python3 - "$ACCEPTED_REVIEW" "$OUTPUT_DIR/survivor-deletion-authorization.json" <<'PY'
import hashlib,json,pathlib,sys
a=json.load(open(sys.argv[1])); base=a['survivor_removal_contract']
obj={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-deletion-authorization-contract',
 'reviewed_survivor_contract_sha256':a['survivor_removal_contract_sha256'],'active_kernel':a['active_kernel'],'rollback_kernel':a['rollback_kernel'],
 'survivor_count':base['survivor_count'],'survivors':base['survivors'],'removal_method':base['removal_method'],
 'survivor_deletion_authorized':True,'recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,
 'third_attempt_authorized':False,'execution_authorized':False}
out=pathlib.Path(sys.argv[2]); out.write_text(json.dumps(obj,indent=2,sort_keys=True)+'\n')
print(hashlib.sha256((json.dumps(obj,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest())
PY
}

verify_no_mutation(){
 capture_names "$OUTPUT_DIR/packages.after.txt" || return 1
 cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/boot.before.sha256" "$OUTPUT_DIR/boot.after.sha256" || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/modules-active.before.sha256" "$OUTPUT_DIR/modules-active.after.sha256" || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/modules-rollback.before.sha256" "$OUTPUT_DIR/modules-rollback.after.sha256" || return 1
}

write_summary(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
survivor_review_evidence_sha256=$REVIEW_EVIDENCE_SHA
survivor_deletion_authorized=$SURVIVOR_DELETION_AUTHORIZED
recursive_module_tree_removal_authorized=$RECURSIVE_REMOVAL_AUTHORIZED
active_counterpart_removal_authorized=$ACTIVE_COUNTERPART_REMOVAL_AUTHORIZED
third_attempt_authorized=$THIRD_ATTEMPT_AUTHORIZED
cleanup_authorized=false
apply_authorized=false
apply_executed=false
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

archive_evidence(){
 local base archive sidecar
 base=${OUTPUT_DIR%/*}; archive=$base/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
 tar -C "$base" -czf "$archive" "${OUTPUT_DIR##*/}" || return 1
 sidecar=$archive.sha256
 (cd "${archive%/*}" && sha256sum "${archive##*/}") > "$sidecar" || return 1
 chmod 0600 "$archive" "$sidecar"
 printf 'Evidence archive: %s\n' "$archive"
 printf 'Evidence SHA-256: %s\n' "$(sha "$archive")"
 printf 'Copy evidence command: sudo install -o promano -g users -m 0600 %q /home/promano/%q && sudo install -o promano -g users -m 0600 %q /home/promano/%q\n' "$archive" "${archive##*/}" "$sidecar" "${sidecar##*/}"
 printf 'Verify copied evidence command: cd /home/promano && sha256sum -c %q\n' "${sidecar##*/}"
}

main(){
 parse_args "$@" || { usage >&2; exit 2; }
 init_output || { err 'unable to initialize evidence output'; exit 1; }
 if validate_static; then pass 'the accepted step-101 survivor review, exact authorization code, and deletion-bound scope are fixed'; else fail 'the static survivor-authorization boundary is invalid'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_live_boundary; then pass 'the recovered package, ELILO, active-module, and rollback-module state still matches step 101 exactly'; else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the live survivor-authorization boundary changed'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_exact_survivors; then pass 'the exact three rollback VirtualBox survivors and their active counterparts still match the reviewed hashes, vermagic, and package-ownership boundary'; else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the exact reviewed survivor set no longer matches'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then
  local auth_sha expected
  auth_sha=$(emit_authorization) || fail 'the exact survivor-deletion authorization contract could not be emitted'
  expected=$(json_get "$POLICY" survivor_deletion_authorization_contract_sha256 2>/dev/null || true)
  if [ "$FAILURE_COUNT" -eq 0 ] && [ "$auth_sha" = "$expected" ]; then
   SURVIVOR_DELETION_AUTHORIZED=true; NEXT_STAGE=elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review
   pass 'only unlink of the exact three reviewed rollback module paths is authorized for a later revised transaction; recursive and active-module removal remain denied'
  else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the emitted survivor-deletion authorization contract does not match the reviewed scope'; fi
 fi
 if verify_no_mutation; then PAUSE_SAFE=true; pass 'the authorization review did not modify packages, ELILO, boot artifacts, active modules, or rollback modules'; else fail 'the authorization review changed protected state'; fi
 write_summary
 archive_evidence || err 'failed to archive evidence'
 if [ "$FAILURE_COUNT" -eq 0 ]; then
  printf 'Result: PASS (%d passes, %d failures, %d skips); survivor_deletion_authorized=%s; recursive_module_tree_removal_authorized=%s; active_counterpart_removal_authorized=%s; third_attempt_authorized=%s; cleanup_authorized=false; apply_authorized=false; apply_executed=false; pause_safe=%s; next_stage=%s\n' "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$SURVIVOR_DELETION_AUTHORIZED" "$RECURSIVE_REMOVAL_AUTHORIZED" "$ACTIVE_COUNTERPART_REMOVAL_AUTHORIZED" "$THIRD_ATTEMPT_AUTHORIZED" "$PAUSE_SAFE" "$NEXT_STAGE"
  exit 0
 fi
 printf 'Result: FAIL (%d passes, %d failures, %d skips); survivor_deletion_authorized=%s; third_attempt_authorized=false; pause_safe=%s; next_stage=elilo-oldkernel-cleanup-rollback-module-survivor-authorization-manual-review\n' "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$SURVIVOR_DELETION_AUTHORIZED" "$PAUSE_SAFE"
 exit 1
}
main "$@"
