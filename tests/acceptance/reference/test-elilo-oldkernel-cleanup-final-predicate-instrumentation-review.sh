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
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-final-predicate-instrumentation-review.sh
POLICY=${ELILO_CLEANUP_PREDICATE_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-final-predicate-instrumentation-review-policy.json}
FAILED_DIAGNOSTIC=${ELILO_CLEANUP_PREDICATE_FAILED_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-1-20260811-recovered-diagnostic.json}
FINAL_DIAGNOSTIC=${ELILO_CLEANUP_PREDICATE_FINAL_DIAGNOSTIC_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-final-contract-diagnostic-20260811-accepted.json}
ACCEPTED_PLAN=${ELILO_CLEANUP_PREDICATE_PLAN_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json}

TARGET=
HOST=
FINAL_EVIDENCE_SHA=
ACTIVE=
ROLLBACK=
SCOPE=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
PACKAGE_DATABASE=
DIAGNOSTIC_COMPLETE=false
ROOT_CAUSE_CONFIRMED=false
UNOWNED_ROLLBACK_FILES=0
UNOWNED_ROLLBACK_MODULE_OBJECTS=0
PAUSE_SAFE=false
NEXT_STAGE=elilo-oldkernel-cleanup-final-predicate-instrumentation-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-final-diagnostic-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \\
  --confirm-instrumentation-review-sha256 SHA256

Read-only review that decomposes the unresolved final cleanup boundary. It binds
step 99, verifies the recovered live state, inventories every rollback-tree file
against the exact FILE LIST records of the three 5.15.19 packages, and identifies
package-unowned module objects that would survive removepkg. It never authorizes
or executes another cleanup attempt.
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
   --confirm-final-diagnostic-evidence-sha256) FINAL_EVIDENCE_SHA=${2,,}; shift 2;;
   --confirm-active-kernel) ACTIVE=$2; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=$2; shift 2;;
   --confirm-instrumentation-review-sha256) SCOPE=${2,,}; shift 2;;
   --output-dir) OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ -n "$HOST" ] && is_sha "$FINAL_EVIDENCE_SHA" \
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

runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_PREDICATE_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_PREDICATE_TEST_HOST:-$HOST}"; else hostname -f; fi; }
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
 python3 - "$POLICY" "$FAILED_DIAGNOSTIC" "$FINAL_DIAGNOSTIC" "$ACCEPTED_PLAN" "$SELF" "$TARGET" "$HOST" "$FINAL_EVIDENCE_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,failed,final,plan,script=map(pathlib.Path,sys.argv[1:6]); target,host,evidence,active,rollback,scope=sys.argv[6:]
def fh(p):
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return hashlib.sha256(p.read_bytes()).hexdigest()
p=json.load(open(pol)); d=json.load(open(failed)); f=json.load(open(final)); a=json.load(open(plan))
scope_bytes=(
 'operation=elilo-oldkernel-cleanup-final-predicate-instrumentation-review\n'
 +'target=slackware-15.0\n'
 +f'hostname_fqdn={host}\n'
 +f'final_diagnostic_evidence_sha256={evidence}\n'
 +f'active_kernel={active}\nrollback_kernel={rollback}\n'
 +f'failed_revision_1_diagnostic_sha256={fh(failed)}\n'
 +f'accepted_final_diagnostic_record_sha256={fh(final)}\n'
 +f'accepted_source_plan_record_sha256={fh(plan)}\n'
 +f'instrumentation_script_sha256={fh(script)}\n'
).encode()
calc_scope=hashlib.sha256(scope_bytes).hexdigest()
checks=[
 p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-final-predicate-instrumentation-review',p.get('reviewed') is True,
 fh(script)==p.get('expected_script_sha256'),fh(failed)==p.get('failed_revision_1_diagnostic_sha256'),fh(final)==p.get('accepted_final_diagnostic_record_sha256'),fh(plan)==p.get('accepted_source_plan_record_sha256'),
 target=='slackware-15.0',host==p.get('hostname_fqdn')==d.get('hostname_fqdn')==f.get('hostname_fqdn'),
 evidence==p.get('accepted_final_diagnostic_archive_sha256')==f.get('archive_sha256'),active==p.get('active_kernel')==d.get('active_kernel')==f.get('active_kernel'),rollback==p.get('rollback_kernel')==d.get('rollback_kernel')==f.get('rollback_kernel'),scope==p.get('confirmation_scope_sha256')==calc_scope,
 f.get('diagnostic_complete') is True,f.get('depmod_dry_run_rc')==0,f.get('root_cause_confirmed') is False,f.get('third_attempt_authorized') is False,f.get('pause_safe') is True,
 d.get('apply_executed') is True,d.get('apply_committed') is False,d.get('recovery_restored') is True,d.get('pause_safe') is True,
 a.get('accepted') is True
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
}

inventory_rollback_survivors(){
 local record
 python3 - "$PACKAGE_DATABASE" "$ACCEPTED_PLAN" "$(rooted "/lib/modules/$ROLLBACK")" "$OUTPUT_DIR/rollback-package-owned-paths.txt" "$OUTPUT_DIR/rollback-unowned-files.txt" "$OUTPUT_DIR/rollback-unowned-module-objects.txt" <<'PY'
import json,pathlib,sys
pkgdb=pathlib.Path(sys.argv[1]); plan=json.load(open(sys.argv[2])); tree=pathlib.Path(sys.argv[3]); owned_out=pathlib.Path(sys.argv[4]); unowned_out=pathlib.Path(sys.argv[5]); ko_out=pathlib.Path(sys.argv[6])
if not tree.is_dir() or tree.is_symlink(): raise SystemExit(1)
owned=set()
for rec in plan['rollback_packages']:
 p=pkgdb/rec
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 lines=p.read_text(encoding='utf-8',errors='strict').splitlines()
 try: start=lines.index('FILE LIST:')+1
 except ValueError: raise SystemExit(1)
 for raw in lines[start:]:
  value=raw.strip()
  if not value or value.endswith('/') or value=='install/doinst.sh': continue
  q=pathlib.PurePosixPath(value)
  if q.is_absolute() or '..' in q.parts: raise SystemExit(1)
  owned.add(value)
prefix=f'lib/modules/{tree.name}/'
owned_module=sorted(x for x in owned if x.startswith(prefix))
owned_out.write_text(''.join(x+'\n' for x in owned_module),encoding='utf-8')
unowned=[]; kos=[]
for p in sorted(x for x in tree.rglob('*') if x.is_file() and not x.is_symlink()):
 rel=prefix+p.relative_to(tree).as_posix()
 if rel not in owned:
  logical='/'+rel
  unowned.append(logical)
  name=p.name
  if '.ko' in name and (name.endswith('.ko') or '.ko.' in name): kos.append(logical)
unowned_out.write_text(''.join(x+'\n' for x in unowned),encoding='utf-8')
ko_out.write_text(''.join(x+'\n' for x in kos),encoding='utf-8')
PY
 UNOWNED_ROLLBACK_FILES=$(wc -l < "$OUTPUT_DIR/rollback-unowned-files.txt" | tr -d ' ')
 UNOWNED_ROLLBACK_MODULE_OBJECTS=$(wc -l < "$OUTPUT_DIR/rollback-unowned-module-objects.txt" | tr -d ' ')
 if [ "$UNOWNED_ROLLBACK_MODULE_OBJECTS" -gt 0 ]; then
  ROOT_CAUSE_CONFIRMED=true
  NEXT_STAGE=elilo-oldkernel-cleanup-rollback-module-survivor-revision-review
 else
  ROOT_CAUSE_CONFIRMED=false
  NEXT_STAGE=elilo-oldkernel-cleanup-instrumented-third-attempt-review
 fi
}

write_predicates(){
 python3 - "$FAILED_DIAGNOSTIC" "$FINAL_DIAGNOSTIC" "$UNOWNED_ROLLBACK_MODULE_OBJECTS" "$OUTPUT_DIR/final-predicate-instrumentation.tsv" <<'PY'
import json,pathlib,sys
d=json.load(open(sys.argv[1])); f=json.load(open(sys.argv[2])); survivors=int(sys.argv[3]); out=pathlib.Path(sys.argv[4]); n=d['narrowing']
rows=[
('capture.package_snapshot','proven','step-98 evidence contains the final package snapshot'),
('capture.active_module_manifest','proven','step-98 evidence contains the final active module manifest'),
('capture.stable_module_manifest','proven','step-98 evidence contains the final stable-payload manifest'),
('capture.module_object_manifest','proven','step-98 evidence contains the final module-object manifest'),
('verify.package_set','pass',str(n.get('attempt_final_package_set_was_exactly_expected')).lower()),
('verify.stable_module_payload','pass',str(n.get('stable_module_payload_was_byte_identical')).lower()),
('verify.active_module_objects','pass',str(n.get('kernel_module_objects_were_byte_identical')).lower()),
('verify.generated_depmod_indexes_present','pass',str(n.get('all_six_generated_indexes_existed')).lower()),
('verify.depmod_no_write_probe','pass',f"step-99 rc={f.get('depmod_dry_run_rc')}"),
('verify.efi_rollback_artifacts_absent','action-pass-not-postcaptured','delete action returned success before final verification'),
('verify.versioned_rollback_kernel_absent','action-log-pass',str(n.get('rollback_package_removal_log_deleted_versioned_generic_kernel')).lower()),
('verify.rollback_module_objects_absent','fail-projected' if survivors else 'pass-projected',f'package-unowned rollback module objects={survivors}'),
('verify.active_boot_chain','pre-delete-pass','active boot verification passed immediately before rollback EFI deletion'),
]
out.write_text('predicate\tstatus\tbasis\n'+''.join('\t'.join(r)+'\n' for r in rows),encoding='utf-8')
PY
}

write_result(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-final-predicate-instrumentation-review
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
final_diagnostic_evidence_sha256=$FINAL_EVIDENCE_SHA
diagnostic_complete=$DIAGNOSTIC_COMPLETE
root_cause_confirmed=$ROOT_CAUSE_CONFIRMED
root_cause_classification=$([ "$ROOT_CAUSE_CONFIRMED" = true ] && printf rollback-package-unowned-module-object-survivors || printf unresolved-after-ownership-projection)
unowned_rollback_files=$UNOWNED_ROLLBACK_FILES
unowned_rollback_module_objects=$UNOWNED_ROLLBACK_MODULE_OBJECTS
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

publish(){
 local base archive side owner group
 base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-final-predicate-instrumentation-review
 archive=$base/slackware-15.0-elilo-oldkernel-cleanup-final-predicate-instrumentation-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
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
 if [ "$TEST_MODE" != 1 ]; then [ -z "$ROOT_PREFIX" ] || { err 'test root override is forbidden in production mode'; return 2; }; fi
 if [ -z "$OUTPUT_DIR" ]; then OUTPUT_DIR=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-final-predicate-instrumentation-review/work-$(date -u +%Y%m%dT%H%M%SZ); fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 2
 install -d -m 0700 -- "$OUTPUT_DIR" || return 2
 : > "$OUTPUT_DIR/assertions.log"
 if validate_static; then pass 'the accepted step-99 diagnostic, failed revision-1 evidence, exact code, source plan, and instrumentation scope are bound'; else fail 'the static final-predicate instrumentation boundary does not match'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if verify_live_recovery; then pass 'the recovered 5.15.209/5.15.19 package, boot, module, and private recovery state still matches exactly'; else fail 'the live recovered state no longer matches the accepted boundary'; fi; else skip 'live recovery verification requires a valid static boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if inventory_rollback_survivors; then pass 'the rollback module tree was compared against all three exact 5.15.19 package FILE LIST records without mutation'; else fail 'rollback package ownership could not be projected safely'; fi; else skip 'rollback ownership instrumentation requires the exact recovered live boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then if write_predicates; then pass 'capture_final and each final verification predicate were decomposed with their evidence basis and rollback-survivor projection'; else fail 'the final predicate instrumentation report could not be produced'; fi; else skip 'predicate decomposition requires a complete ownership projection'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then
  DIAGNOSTIC_COMPLETE=true; PAUSE_SAFE=true
  if [ "$ROOT_CAUSE_CONFIRMED" = true ]; then pass 'package-unowned rollback module objects would survive removepkg and explain the failed final rollback-module predicate'; else pass 'no package-unowned rollback module object was found; a third attempt remains denied pending explicit runtime predicate instrumentation'; fi
 fi
 write_result
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); diagnostic_complete=%s; root_cause_confirmed=%s; unowned_rollback_module_objects=%s; third_attempt_authorized=false; pause_safe=%s; next_stage=%s\n' "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$DIAGNOSTIC_COMPLETE" "$ROOT_CAUSE_CONFIRMED" "$UNOWNED_ROLLBACK_MODULE_OBJECTS" "$PAUSE_SAFE" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
