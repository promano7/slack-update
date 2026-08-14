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
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-rollback-module-survivor-revision-review.sh
POLICY=${ELILO_CLEANUP_SURVIVOR_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-revision-review-policy.json}
ACCEPTED_INSTRUMENTATION=${ELILO_CLEANUP_SURVIVOR_ACCEPTED_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-final-predicate-instrumentation-review-20260814-accepted.json}
FAILED_DIAGNOSTIC=${ELILO_CLEANUP_SURVIVOR_FAILED_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-1-20260811-recovered-diagnostic.json}

TARGET=
HOST=
INSTRUMENTATION_EVIDENCE_SHA=
ACTIVE=
ROLLBACK=
SCOPE=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
PACKAGE_DATABASE=
SURVIVOR_REVIEW_READY=false
SURVIVOR_REMOVAL_SCOPE_READY=false
THIRD_ATTEMPT_AUTHORIZED=false
PAUSE_SAFE=false
NEXT_STAGE=elilo-oldkernel-cleanup-rollback-module-survivor-revision-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
MODINFO=${ELILO_CLEANUP_SURVIVOR_MODINFO:-/sbin/modinfo}

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-instrumentation-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \\
  --confirm-survivor-review-sha256 SHA256

Read-only review of the three package-unowned VirtualBox module objects proven by
step 100. It verifies that no installed package owns the rollback paths, checks
their rollback vermagic, validates matching active-kernel counterparts, and
fingerprints the exact survivor-removal scope. It never removes a module and
never authorizes another cleanup attempt.
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
   --confirm-hostname-fqdn) HOST=$2; shift 2;;
   --confirm-instrumentation-evidence-sha256) INSTRUMENTATION_EVIDENCE_SHA=${2,,}; shift 2;;
   --confirm-active-kernel) ACTIVE=$2; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=$2; shift 2;;
   --confirm-survivor-review-sha256) SCOPE=${2,,}; shift 2;;
   --output-dir) OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ -n "$HOST" ] && is_sha "$INSTRUMENTATION_EVIDENCE_SHA" \
  && safe_ver "$ACTIVE" && safe_ver "$ROLLBACK" && [ "$ACTIVE" != "$ROLLBACK" ] && is_sha "$SCOPE"
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
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_SURVIVOR_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_SURVIVOR_TEST_HOST:-$HOST}"; else hostname -f; fi; }
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
 python3 - "$POLICY" "$ACCEPTED_INSTRUMENTATION" "$FAILED_DIAGNOSTIC" "$SELF" "$TARGET" "$HOST" "$INSTRUMENTATION_EVIDENCE_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,accepted,failed,script=map(pathlib.Path,sys.argv[1:5]); target,host,evidence,active,rollback,scope=sys.argv[5:]
def fh(p):
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return hashlib.sha256(p.read_bytes()).hexdigest()
p=json.load(open(pol)); a=json.load(open(accepted)); d=json.load(open(failed))
scope_bytes=(
 'operation=elilo-oldkernel-cleanup-rollback-module-survivor-revision-review\n'
 +'target=slackware-15.0\n'
 +f'hostname_fqdn={host}\n'
 +f'instrumentation_evidence_sha256={evidence}\n'
 +f'active_kernel={active}\nrollback_kernel={rollback}\n'
 +f'accepted_instrumentation_record_sha256={fh(accepted)}\n'
 +f'failed_revision_1_diagnostic_sha256={fh(failed)}\n'
 +f'survivor_review_script_sha256={fh(script)}\n'
).encode()
calc=hashlib.sha256(scope_bytes).hexdigest()
expected=['/lib/modules/5.15.19/misc/vboxguest.ko','/lib/modules/5.15.19/misc/vboxsf.ko','/lib/modules/5.15.19/misc/vboxvideo.ko']
checks=[
 p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-rollback-module-survivor-revision-review',p.get('reviewed') is True,
 fh(script)==p.get('expected_script_sha256'),fh(accepted)==p.get('accepted_instrumentation_record_sha256'),fh(failed)==p.get('failed_revision_1_diagnostic_sha256'),
 target=='slackware-15.0',host==p.get('hostname_fqdn')==a.get('hostname_fqdn')==d.get('hostname_fqdn'),
 evidence==p.get('accepted_instrumentation_archive_sha256')==a.get('archive_sha256'),active==p.get('active_kernel')==a.get('active_kernel')==d.get('active_kernel'),rollback==p.get('rollback_kernel')==a.get('rollback_kernel')==d.get('rollback_kernel'),
 scope==p.get('confirmation_scope_sha256')==calc,
 a.get('root_cause_confirmed') is True,a.get('root_cause_classification')=='rollback-package-unowned-module-object-survivors',a.get('unowned_rollback_module_object_paths')==expected,a.get('third_attempt_authorized') is False,a.get('pause_safe') is True,
 d.get('recovery_restored') is True,d.get('pause_safe') is True
]
raise SystemExit(0 if all(checks) else 1)
PY
}

verify_live_recovery(){
 local expected recovery
 [ "$(runtime_fqdn 2>/dev/null)" = "$HOST" ] || return 1
 [ "$(runtime_kernel 2>/dev/null)" = "$ACTIVE" ] || return 1
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || return 1
 resolve_pkgdb || return 1
 capture_names "$OUTPUT_DIR/packages.before.txt" || return 1
 expected=$(json_get "$ACCEPTED_INSTRUMENTATION" package_snapshot_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/packages.before.txt")" = "$expected" ] || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_INSTRUMENTATION" boot_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_INSTRUMENTATION" active_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-active.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_INSTRUMENTATION" rollback_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-rollback.before.sha256")" = "$expected" ] || return 1
 recovery=$(rooted "$(json_get "$FAILED_DIAGNOSTIC" recovery_backup_path)") || return 1
 [ -d "$recovery" ] && [ ! -L "$recovery" ] || return 1
 (cd "$recovery" && sha256sum -c archive.sha256) > "$OUTPUT_DIR/recovery-backup-verify.log" 2>&1 || return 1
}

review_survivors(){
 python3 - "$PACKAGE_DATABASE" "$ACCEPTED_INSTRUMENTATION" "$ROOT_PREFIX" "$ACTIVE" "$ROLLBACK" "$MODINFO" "$OUTPUT_DIR/survivor-review.tsv" "$OUTPUT_DIR/survivor-removal-contract.json" <<'PY'
import hashlib,json,os,pathlib,stat,subprocess,sys
pkgdb=pathlib.Path(sys.argv[1]); accepted=json.load(open(sys.argv[2])); root=pathlib.Path(sys.argv[3] or '/'); active,rollback=sys.argv[4:6]; modinfo=sys.argv[6]; review=pathlib.Path(sys.argv[7]); contract=pathlib.Path(sys.argv[8])
paths=accepted['unowned_rollback_module_object_paths']
expected_names={'vboxguest.ko':'vboxguest','vboxsf.ko':'vboxsf','vboxvideo.ko':'vboxvideo'}
if paths != [f'/lib/modules/{rollback}/misc/vboxguest.ko',f'/lib/modules/{rollback}/misc/vboxsf.ko',f'/lib/modules/{rollback}/misc/vboxvideo.ko']:
 raise SystemExit(1)

def package_owners(logical):
 needle=logical.lstrip('/'); owners=[]
 for rec in sorted(p for p in pkgdb.iterdir() if p.is_file() and not p.is_symlink()):
  lines=rec.read_text(encoding='utf-8',errors='strict').splitlines()
  try: start=lines.index('FILE LIST:')+1
  except ValueError: continue
  listed=set()
  for raw in lines[start:]:
   value=raw.strip()
   if value.startswith('./'): value=value[2:]
   if value: listed.add(value)
  if needle in listed:
   owners.append(rec.name)
 return owners

def field(path,name):
 cp=subprocess.run([modinfo,'-F',name,str(path)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,check=False)
 if cp.returncode!=0: raise SystemExit(1)
 return cp.stdout.strip()
def resolve_name(name):
 cp=subprocess.run([modinfo,'-n',name],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,check=False)
 if cp.returncode!=0: raise SystemExit(1)
 return cp.stdout.strip()
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
rows=[]; items=[]
for logical in paths:
 old=root/logical.lstrip('/')
 if not old.is_file() or old.is_symlink(): raise SystemExit(1)
 st=old.stat()
 if st.st_uid!=0 or st.st_gid!=0 or stat.S_IMODE(st.st_mode) & 0o022: raise SystemExit(1)
 owners=package_owners(logical)
 if owners: raise SystemExit(1)
 expected=expected_names.get(old.name)
 if not expected: raise SystemExit(1)
 old_name=field(old,'name'); old_vermagic=field(old,'vermagic')
 if old_name!=expected or not old_vermagic.startswith(rollback+' '): raise SystemExit(1)
 active_logical=f'/lib/modules/{active}/misc/{old.name}'
 current=root/active_logical.lstrip('/')
 if not current.is_file() or current.is_symlink(): raise SystemExit(1)
 cst=current.stat()
 if cst.st_uid!=0 or cst.st_gid!=0 or stat.S_IMODE(cst.st_mode) & 0o022: raise SystemExit(1)
 current_name=field(current,'name'); current_vermagic=field(current,'vermagic'); resolved=resolve_name(expected)
 expected_resolved='/' + active_logical.lstrip('/')
 if current_name!=expected or not current_vermagic.startswith(active+' ') or pathlib.PurePosixPath(resolved)!=pathlib.PurePosixPath(expected_resolved): raise SystemExit(1)
 old_sha=digest(old); active_sha=digest(current)
 rows.append((logical,expected,old_sha,old_vermagic,active_logical,active_sha,current_vermagic,'0'))
 items.append({'rollback_path':logical,'module_name':expected,'rollback_sha256':old_sha,'rollback_vermagic':old_vermagic,'installed_package_owners':[],'active_counterpart_path':active_logical,'active_counterpart_sha256':active_sha,'active_counterpart_vermagic':current_vermagic})
review.write_text('rollback_path\tmodule_name\trollback_sha256\trollback_vermagic\tactive_counterpart\tactive_sha256\tactive_vermagic\tinstalled_package_owner_count\n'+''.join('\t'.join(r)+'\n' for r in rows),encoding='utf-8')
obj={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-removal-contract','reviewed':True,'active_kernel':active,'rollback_kernel':rollback,'survivor_count':len(items),'survivors':items,'removal_method':'unlink-exact-reviewed-paths-after-rollback-package-removal-before-final-verification','recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,'deletion_authorized':False,'third_attempt_authorized':False}
contract.write_text(json.dumps(obj,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

verify_no_mutation(){
 local expected
 capture_names "$OUTPUT_DIR/packages.after.txt" || return 1
 cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/boot.before.sha256" "$OUTPUT_DIR/boot.after.sha256" || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/modules-active.before.sha256" "$OUTPUT_DIR/modules-active.after.sha256" || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/modules-rollback.before.sha256" "$OUTPUT_DIR/modules-rollback.after.sha256" || return 1
}

write_result(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-rollback-module-survivor-revision-review
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
instrumentation_evidence_sha256=$INSTRUMENTATION_EVIDENCE_SHA
survivor_review_ready=$SURVIVOR_REVIEW_READY
survivor_removal_scope_ready=$SURVIVOR_REMOVAL_SCOPE_READY
reviewed_survivor_count=3
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

publish(){
 local base archive side owner group
 base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-rollback-module-survivor-revision-review
 archive=$base/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-revision-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
 side=$archive.sha256
 install -d -m 0700 -- "$base" || return 1
 tar -C "$(dirname "$OUTPUT_DIR")" -czf "$archive" "$(basename "$OUTPUT_DIR")" || return 1
 chmod 0600 "$archive"
 (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side" || return 1
 chmod 0600 "$side"
 printf 'Evidence archive: %s\n' "$archive"
 printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$side")"
 owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users)
 printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"
 printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"
}

main(){
 parse_args "$@" || { usage >&2; return 2; }
 [ "$(id -u)" -eq 0 ] || { err 'must run as root'; return 2; }
 if [ "$TEST_MODE" != 1 ]; then
  [ -z "$ROOT_PREFIX" ] || { err 'test root override is forbidden in production mode'; return 2; }
  [ "$MODINFO" = /sbin/modinfo ] || { err 'modinfo override is forbidden in production mode'; return 2; }
 fi
 if [ -z "$OUTPUT_DIR" ]; then OUTPUT_DIR=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-rollback-module-survivor-revision-review/work-$(date -u +%Y%m%dT%H%M%SZ); fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 2
 install -d -m 0700 -- "$OUTPUT_DIR" || return 2
 : > "$OUTPUT_DIR/assertions.log"
 if validate_static; then pass 'the accepted step-100 instrumentation, exact review code, recovered failure, and survivor-review scope are bound'; else fail 'the static rollback-module survivor review boundary does not match'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_live_recovery; then pass 'the recovered 5.15.209/5.15.19 package, boot, module, and private recovery state still matches exactly'; else fail 'the recovered live state no longer matches the accepted step-100 boundary'; fi; else skip 'live recovery verification requires a valid static boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if review_survivors; then SURVIVOR_REVIEW_READY=true; SURVIVOR_REMOVAL_SCOPE_READY=true; pass 'the exact three rollback VirtualBox module survivors are package-unowned, rollback-versioned, and have valid active-kernel counterparts'; else fail 'the rollback VirtualBox survivor ownership, identity, or active-counterpart review failed'; fi; else skip 'survivor review requires the exact recovered live state'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_no_mutation; then PAUSE_SAFE=true; NEXT_STAGE=elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review; pass 'the survivor review did not modify packages, ELILO, boot artifacts, active modules, rollback modules, or recovery state'; else fail 'the survivor review changed protected live state'; fi; else skip 'non-mutation proof requires a completed survivor review'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then pass 'the exact survivor-removal scope is ready for a separate authorization review while a third cleanup attempt remains denied'; fi
 write_result
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); survivor_review_ready=%s; survivor_removal_scope_ready=%s; third_attempt_authorized=false; cleanup_authorized=false; apply_authorized=false; pause_safe=%s; next_stage=%s\n' "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$SURVIVOR_REVIEW_READY" "$SURVIVOR_REMOVAL_SCOPE_READY" "$PAUSE_SAFE" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
