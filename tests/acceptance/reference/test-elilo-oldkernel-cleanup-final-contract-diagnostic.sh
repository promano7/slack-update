#!/bin/bash
set -u
export LC_ALL=C
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-final-contract-diagnostic.sh
POLICY=${ELILO_CLEANUP_FINAL_DIAGNOSTIC_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-final-contract-diagnostic-policy.json}
FAILED_DIAGNOSTIC=${ELILO_CLEANUP_FINAL_DIAGNOSTIC_FAILED_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-1-20260811-recovered-diagnostic.json}
RECOVERY_ACCEPTED=${ELILO_CLEANUP_FINAL_DIAGNOSTIC_RECOVERY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-recovery-review-20260811-accepted.json}
REVISION_ACCEPTED=${ELILO_CLEANUP_FINAL_DIAGNOSTIC_REVISION_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-review-20260811-accepted.json}
TARGET= HOST= FAILED_SHA= ACTIVE= ROLLBACK= SCOPE= OUTPUT_DIR=
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
DEPMOD=${ELILO_CLEANUP_FINAL_DIAGNOSTIC_DEPMOD:-/sbin/depmod}
PASS_COUNT=0; FAILURE_COUNT=0; SKIP_COUNT=0
PAUSE_SAFE=false; DIAGNOSTIC_COMPLETE=false; ROOT_CAUSE_CONFIRMED=false
DEPMOD_RC=not-run
NEXT_STAGE=elilo-oldkernel-cleanup-final-contract-diagnostic-manual-review

usage(){ cat <<'USAGE'
Usage: test-elilo-oldkernel-cleanup-final-contract-diagnostic.sh \
  --target slackware-15.0 --confirm-hostname-fqdn HOST \
  --confirm-failed-revision-evidence-sha256 SHA256 \
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
  --confirm-final-diagnostic-sha256 SHA256
USAGE
}
err(){ printf 'ERROR: %s\n' "$*" >&2; }
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
skip(){ SKIP_COUNT=$((SKIP_COUNT+1)); printf 'SKIP: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
rooted(){ printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
json_get(){ python3 - "$1" "$2" <<'PY'
import json,sys
v=json.load(open(sys.argv[1]))
for p in sys.argv[2].split('.'):
    v=v[p]
if isinstance(v,bool): print(str(v).lower())
elif isinstance(v,(dict,list)): print(json.dumps(v,sort_keys=True,separators=(',',':')))
else: print(v)
PY
}
parse_args(){
 while [ $# -gt 0 ]; do
  case "$1" in
   --target) TARGET=${2:-}; shift 2;;
   --confirm-hostname-fqdn) HOST=${2:-}; shift 2;;
   --confirm-failed-revision-evidence-sha256) FAILED_SHA=${2:-}; shift 2;;
   --confirm-active-kernel) ACTIVE=${2:-}; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=${2:-}; shift 2;;
   --confirm-final-diagnostic-sha256) SCOPE=${2:-}; shift 2;;
   --output-dir) OUTPUT_DIR=${2:-}; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ -n "$HOST" ] && [ -n "$FAILED_SHA" ] && [ -n "$ACTIVE" ] && [ -n "$ROLLBACK" ] && [ -n "$SCOPE" ]
}
init_output(){
 local base stamp
 stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
 if [ -z "$OUTPUT_DIR" ]; then
  base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-final-contract-diagnostic
  install -d -m 0700 -- "$base" || return 1
  OUTPUT_DIR=$base/slackware-15.0-$stamp
 fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
 install -d -m 0700 -- "$OUTPUT_DIR" || return 1
 : > "$OUTPUT_DIR/assertions.log"
}
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_FINAL_DIAGNOSTIC_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_FINAL_DIAGNOSTIC_TEST_HOST:-$HOST}"; else hostname -f; fi; }
resolve_pkgdb(){ local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages; if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a; elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b"); elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b; else return 1; fi; }
capture_names(){ find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"; }
capture_boot_selected(){ python3 - "$ROOT_PREFIX" "$ACTIVE" "$ROLLBACK" "$1" <<'PY'
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
module_manifest(){ local ver=$1 out=$2 dir; dir=$(rooted "/lib/modules/$ver"); [ -d "$dir" ] && [ ! -L "$dir" ] || return 1; (cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do sha256sum -- "$f"; done) > "$out"; }
validate_static(){
 python3 - "$POLICY" "$FAILED_DIAGNOSTIC" "$RECOVERY_ACCEPTED" "$REVISION_ACCEPTED" "$SELF" "$TARGET" "$HOST" "$FAILED_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,diag,recovery,revision,script=map(pathlib.Path,sys.argv[1:6]); target,host,failed,active,rollback,scope=sys.argv[6:]
def fh(p): return hashlib.sha256(p.read_bytes()).hexdigest()
p=json.load(open(pol)); d=json.load(open(diag)); r=json.load(open(recovery)); v=json.load(open(revision))
checks=[
 p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-final-contract-diagnostic',p.get('reviewed') is True,
 fh(script)==p.get('expected_script_sha256'),fh(diag)==p.get('failed_revision_1_diagnostic_sha256'),fh(recovery)==p.get('accepted_recovery_record_sha256'),fh(revision)==p.get('accepted_revision_record_sha256'),
 target=='slackware-15.0',host==d.get('hostname_fqdn')==r.get('hostname_fqdn')==v.get('hostname_fqdn'),
 failed==d.get('archive_sha256')==p.get('failed_revision_1_archive_sha256'),active==d.get('active_kernel')==r.get('active_kernel')==v.get('active_kernel'),rollback==d.get('rollback_kernel')==r.get('rollback_kernel')==v.get('rollback_kernel'),scope==p.get('confirmation_scope_sha256'),
 d.get('apply_executed') is True,d.get('apply_committed') is False,d.get('recovery_restored') is True,d.get('pause_safe') is True,
 v.get('retry_authorized') is True,v.get('apply_executed') is False
]
raise SystemExit(0 if all(checks) else 1)
PY
}
verify_narrowing(){
 python3 - "$FAILED_DIAGNOSTIC" "$OUTPUT_DIR/failed-attempt-narrowing.txt" <<'PY'
import json,pathlib,sys
d=json.load(open(sys.argv[1])); n=d['narrowing']
allowed={'./modules.alias','./modules.alias.bin','./modules.dep','./modules.dep.bin','./modules.symbols','./modules.symbols.bin'}
checks=[n.get('attempt_final_package_set_was_exactly_expected') is True,n.get('stable_module_payload_was_byte_identical') is True,n.get('kernel_module_objects_were_byte_identical') is True,n.get('changed_active_module_manifest_entries')==6,set(n.get('changed_paths',[]))==allowed,n.get('all_six_generated_indexes_existed') is True,n.get('remaining_final_predicate_was_not_logged_individually') is True]
if not all(checks): raise SystemExit(1)
pathlib.Path(sys.argv[2]).write_text('package_set=exact\nstable_payload=identical\nmodule_objects=identical\ngenerated_indexes_present=true\nunresolved_final_predicate=true\n')
PY
}
verify_live_recovery(){
 local expected recovery
 [ "$(runtime_fqdn 2>/dev/null)" = "$HOST" ] || return 1
 [ "$(runtime_kernel 2>/dev/null)" = "$ACTIVE" ] || return 1
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || return 1
 resolve_pkgdb || return 1
 capture_names "$OUTPUT_DIR/packages.before.txt" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_package_snapshot_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/packages.before.txt")" = "$expected" ] || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.before.sha256" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_boot_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.before.sha256" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_active_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-active.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.before.sha256" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_rollback_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-rollback.before.sha256")" = "$expected" ] || return 1
 recovery=$(rooted "$(json_get "$FAILED_DIAGNOSTIC" recovery_backup_path)") || return 1
 [ -d "$recovery" ] && [ ! -L "$recovery" ] || return 1
 (cd "$recovery" && sha256sum -c archive.sha256) > "$OUTPUT_DIR/recovery-backup-verify.log" 2>&1 || return 1
 [ "$(sha "$recovery/archive.sha256")" = "$(json_get "$FAILED_DIAGNOSTIC" recovery_archive_manifest_sha256)" ] || return 1
 printf '%s\n' "$recovery" > "$OUTPUT_DIR/recovery-backup-path.txt"
}
probe_depmod(){
 local dir f rc
 dir=$(rooted "/lib/modules/$ACTIVE")
 for f in modules.alias modules.alias.bin modules.dep modules.dep.bin modules.symbols modules.symbols.bin; do [ -f "$dir/$f" ] && [ ! -L "$dir/$f" ] || return 1; done
 capture_names "$OUTPUT_DIR/packages.probe.before.txt" || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.probe.before.sha256" || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.probe.before.sha256" || return 1
 "$DEPMOD" -n "$ACTIVE" > "$OUTPUT_DIR/depmod-show.out" 2> "$OUTPUT_DIR/depmod-show.err"
 rc=$?
 DEPMOD_RC=$rc
 capture_names "$OUTPUT_DIR/packages.probe.after.txt" || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.probe.after.sha256" || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.probe.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/packages.probe.before.txt" "$OUTPUT_DIR/packages.probe.after.txt" || return 1
 cmp -s "$OUTPUT_DIR/boot.probe.before.sha256" "$OUTPUT_DIR/boot.probe.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/modules-active.probe.before.sha256" "$OUTPUT_DIR/modules-active.probe.after.sha256" || return 1
 python3 - "$OUTPUT_DIR/depmod-show.out" "$OUTPUT_DIR/depmod-show.err" "$DEPMOD_RC" "$OUTPUT_DIR/depmod-probe.json" <<'PY'
import hashlib,json,pathlib,sys
out,err=map(pathlib.Path,sys.argv[1:3]); rc=int(sys.argv[3]); dst=pathlib.Path(sys.argv[4])
def rec(p):
 b=p.read_bytes(); return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
dst.write_text(json.dumps({'depmod_dry_run_rc':rc,'stdout':rec(out),'stderr':rec(err)},indent=2,sort_keys=True)+'\n')
PY
 if [ "$DEPMOD_RC" -ne 0 ]; then ROOT_CAUSE_CONFIRMED=true; NEXT_STAGE=elilo-oldkernel-cleanup-depmod-validation-revision-review; else ROOT_CAUSE_CONFIRMED=false; NEXT_STAGE=elilo-oldkernel-cleanup-final-predicate-instrumentation-review; fi
 DIAGNOSTIC_COMPLETE=true; PAUSE_SAFE=true
}
write_result(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-final-contract-diagnostic
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
failed_revision_evidence_sha256=$FAILED_SHA
diagnostic_complete=$DIAGNOSTIC_COMPLETE
depmod_dry_run_rc=$DEPMOD_RC
root_cause_confirmed=$ROOT_CAUSE_CONFIRMED
third_attempt_authorized=false
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
publish(){ local base archive side owner group; base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-final-contract-diagnostic; archive=$base/slackware-15.0-elilo-oldkernel-cleanup-final-contract-diagnostic-$(date -u +%Y%m%dT%H%M%SZ).tar.gz; side=$archive.sha256; install -d -m 0700 -- "$base" || return 1; tar -C "$(dirname "$OUTPUT_DIR")" -czf "$archive" "$(basename "$OUTPUT_DIR")" || return 1; chmod 0600 "$archive"; (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side" || return 1; chmod 0600 "$side"; printf 'Evidence archive: %s\n' "$archive"; printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$side")"; owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users); printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"; printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"; }
main(){
 parse_args "$@" || { usage >&2; return 2; }
 [ "$(id -u)" -eq 0 ] || { err 'must run as root'; return 2; }
 if [ "$TEST_MODE" != 1 ]; then [ -z "$ROOT_PREFIX" ] && [ "$DEPMOD" = /sbin/depmod ] || { err 'test-only overrides are forbidden in production mode'; return 2; }; fi
 init_output || return 2
 if validate_static; then pass 'the recovered revision-1 failure, accepted recovery, accepted revision, exact code, and diagnostic scope are bound'; else fail 'the static final-contract diagnostic boundary does not match'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_narrowing; then pass 'the second failed attempt is narrowed to a post-payload final predicate with exact packages and immutable module payload already proven'; else fail 'the failed-attempt evidence cannot be narrowed safely'; fi; else skip 'failed-attempt narrowing requires a valid static boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_live_recovery; then pass 'the exact recovered pre-apply package, boot, module, and private recovery state still matches'; else fail 'the live system no longer matches the recovered pre-apply boundary'; fi; else skip 'live recovery verification requires accepted narrowing'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if probe_depmod; then pass 'the no-write depmod probe completed and its exit status was captured without changing packages, boot state, or modules'; else fail 'the depmod diagnostic probe could not be completed without mutation'; fi; else skip 'depmod probing requires the exact recovered live boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then pass 'a third destructive cleanup attempt remains denied until the individually observed final predicate is reviewed'; fi
 write_result
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); diagnostic_complete=%s; depmod_dry_run_rc=%s; root_cause_confirmed=%s; third_attempt_authorized=false; pause_safe=%s; next_stage=%s\n' "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$DIAGNOSTIC_COMPLETE" "$DEPMOD_RC" "$ROOT_CAUSE_CONFIRMED" "$PAUSE_SAFE" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
