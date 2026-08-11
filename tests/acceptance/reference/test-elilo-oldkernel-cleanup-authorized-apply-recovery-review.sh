#!/bin/bash
set -u
export LC_ALL=C
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-authorized-apply-recovery-review.sh
POLICY=${ELILO_CLEANUP_RECOVERY_REVIEW_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-recovery-review-policy.json}
ACCEPTED_AUTH=${ELILO_CLEANUP_RECOVERY_REVIEW_ACCEPTED_AUTH_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-20260811-accepted.json}
FAILED_DIAGNOSTIC=${ELILO_CLEANUP_RECOVERY_REVIEW_DIAGNOSTIC_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-20260811-recovered-diagnostic.json}
TARGET= HOST= FAILED_SHA= ACTIVE= ROLLBACK= SCOPE= OUTPUT_DIR=
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
PASS_COUNT=0; FAILURE_COUNT=0; SKIP_COUNT=0
PAUSE_SAFE=false; RECOVERY_VERIFIED=false; RETRY_DESIGN_REQUIRED=false
NEXT_STAGE=elilo-oldkernel-cleanup-authorized-apply-recovery-manual-review

usage(){ cat <<'EOF'
Usage: test-elilo-oldkernel-cleanup-authorized-apply-recovery-review.sh \
  --target slackware-15.0 --confirm-hostname-fqdn HOST \
  --confirm-failed-apply-evidence-sha256 SHA256 \
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
  --confirm-recovery-review-sha256 SHA256
EOF
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
   --confirm-failed-apply-evidence-sha256) FAILED_SHA=${2:-}; shift 2;;
   --confirm-active-kernel) ACTIVE=${2:-}; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=${2:-}; shift 2;;
   --confirm-recovery-review-sha256) SCOPE=${2:-}; shift 2;;
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
 if [ -z "$OUTPUT_DIR" ]; then base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorized-apply-recovery-review; install -d -m 0700 -- "$base" || return 1; OUTPUT_DIR=$base/slackware-15.0-$stamp; fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
 install -d -m 0700 -- "$OUTPUT_DIR" || return 1
 : > "$OUTPUT_DIR/assertions.log"
}
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_RECOVERY_REVIEW_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_RECOVERY_REVIEW_TEST_HOST:-$HOST}"; else hostname -f; fi; }
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
 python3 - "$POLICY" "$ACCEPTED_AUTH" "$FAILED_DIAGNOSTIC" "$SELF" "$TARGET" "$HOST" "$FAILED_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,auth,diag,script=map(pathlib.Path,sys.argv[1:5]); target,host,failed,active,rollback,scope=sys.argv[5:]
def fh(p): return hashlib.sha256(p.read_bytes()).hexdigest()
p=json.load(open(pol)); a=json.load(open(auth)); d=json.load(open(diag))
checks=[p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-authorized-apply-recovery-review',p.get('reviewed') is True,
 fh(script)==p.get('expected_script_sha256'),fh(auth)==p.get('accepted_authorization_record_sha256'),fh(diag)==p.get('failed_apply_diagnostic_sha256'),
 target=='slackware-15.0',host==d.get('hostname_fqdn')==a.get('hostname_fqdn'),failed==d.get('archive_sha256')==p.get('failed_apply_archive_sha256'),
 active==d.get('active_kernel')==a.get('active_kernel'),rollback==d.get('rollback_kernel')==a.get('rollback_kernel'),scope==p.get('confirmation_scope_sha256'),
 d.get('apply_executed') is True,d.get('apply_committed') is False,d.get('recovery_restored') is True,d.get('pause_safe') is True,
 d.get('false_negative',{}).get('classification')=='generated-depmod-index-byte-drift',d.get('false_negative',{}).get('changed_kernel_module_objects')==0]
raise SystemExit(0 if all(checks) else 1)
PY
}
verify_live_recovery(){
 local expected recovery
 [ "$(runtime_fqdn 2>/dev/null)" = "$HOST" ] || return 1
 [ "$(runtime_kernel 2>/dev/null)" = "$ACTIVE" ] || return 1
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || return 1
 resolve_pkgdb || return 1
 capture_names "$OUTPUT_DIR/packages.live.txt" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_package_snapshot_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/packages.live.txt")" = "$expected" ] || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.live.sha256" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_boot_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/boot.live.sha256")" = "$expected" ] || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.live.sha256" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_active_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-active.live.sha256")" = "$expected" ] || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.live.sha256" || return 1
 expected=$(json_get "$FAILED_DIAGNOSTIC" preapply_rollback_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-rollback.live.sha256")" = "$expected" ] || return 1
 recovery=$(rooted "$(json_get "$FAILED_DIAGNOSTIC" recovery_backup_path)") || return 1
 [ -d "$recovery" ] && [ ! -L "$recovery" ] || return 1
 (cd "$recovery" && sha256sum -c archive.sha256) > "$OUTPUT_DIR/recovery-backup-verify.log" 2>&1 || return 1
 [ "$(sha "$recovery/archive.sha256")" = "$(json_get "$FAILED_DIAGNOSTIC" recovery_archive_manifest_sha256)" ] || return 1
 printf '%s\n' "$recovery" > "$OUTPUT_DIR/recovery-backup-path.txt"
}
verify_diagnostic_scope(){
 python3 - "$FAILED_DIAGNOSTIC" "$OUTPUT_DIR/diagnostic.txt" <<'PY'
import json,pathlib,sys
d=json.load(open(sys.argv[1])); f=d['false_negative']; paths=f['changed_paths']
allowed={'./modules.alias','./modules.alias.bin','./modules.dep','./modules.dep.bin','./modules.symbols','./modules.symbols.bin'}
if set(paths)!=allowed or f['changed_active_module_manifest_entries']!=6 or f['changed_kernel_module_objects']!=0 or not f['attempt_final_package_set_was_exactly_expected'] or not f['transaction_reached_expected_cleanup_before_final_assertion']:
 raise SystemExit(1)
pathlib.Path(sys.argv[2]).write_text('classification='+f['classification']+'\nchanged_paths='+' '.join(paths)+'\nmodule_object_changes=0\n')
PY
}
write_result(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF
scenario=elilo-oldkernel-cleanup-authorized-apply-recovery-review
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
failed_apply_evidence_sha256=$FAILED_SHA
recovery_verified=$RECOVERY_VERIFIED
false_negative_classification=generated-depmod-index-byte-drift
retry_design_required=$RETRY_DESIGN_REQUIRED
cleanup_authorized=false
apply_authorized=false
apply_executed=false
pause_safe=$PAUSE_SAFE
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF
}
publish(){ local base archive side owner group; base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorized-apply-recovery-review; archive=$base/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-recovery-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz; side=$archive.sha256; install -d -m 0700 -- "$base" || return 1; tar -C "$(dirname "$OUTPUT_DIR")" -czf "$archive" "$(basename "$OUTPUT_DIR")" || return 1; chmod 0600 "$archive"; (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side" || return 1; chmod 0600 "$side"; printf 'Evidence archive: %s\n' "$archive"; printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$side")"; owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users); printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"; printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"; }
main(){
 parse_args "$@" || { usage >&2; return 2; }
 [ "$(id -u)" -eq 0 ] || { err 'must run as root'; return 2; }
 init_output || return 2
 if validate_static; then pass 'the failed step-95 apply, accepted authorization, exact recovery-review code, and scope are bound'; else fail 'the static recovery-review boundary does not match'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_diagnostic_scope; then pass 'the failed apply is classified as generated depmod index byte drift with zero kernel-module-object changes'; else fail 'the failed apply diagnostic is not narrow enough for safe review'; fi; else skip 'diagnostic classification requires a valid static boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_live_recovery; then RECOVERY_VERIFIED=true; PAUSE_SAFE=true; RETRY_DESIGN_REQUIRED=true; NEXT_STAGE=elilo-oldkernel-cleanup-authorized-apply-revision-review; pass 'the exact pre-apply package, boot, active-module, rollback-module, and private recovery state remains restored'; else fail 'the live system no longer matches the exact recovered pre-apply boundary'; fi; else skip 'live recovery verification requires accepted diagnostic classification'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then pass 'cleanup remains unauthorized until a revised executor distinguishes immutable module payload from regenerated depmod indexes'; fi
 write_result
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); recovery_verified=%s; retry_design_required=%s; cleanup_authorized=false; apply_authorized=false; pause_safe=%s; next_stage=%s\n' "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$RECOVERY_VERIFIED" "$RETRY_DESIGN_REQUIRED" "$PAUSE_SAFE" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
