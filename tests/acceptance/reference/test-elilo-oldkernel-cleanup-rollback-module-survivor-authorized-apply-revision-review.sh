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
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review.sh
POLICY=${ELILO_CLEANUP_SURVIVOR_INTEGRATION_REVIEW_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review-policy.json}
ACCEPTED_SURVIVOR_AUTH=${ELILO_CLEANUP_SURVIVOR_INTEGRATION_ACCEPTED_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review-20260814-accepted.json}
INTEGRATION_CONTRACT=${ELILO_CLEANUP_SURVIVOR_INTEGRATION_CONTRACT_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-survivor-integrated-apply-revision-contract.json}
APPLY_POLICY=${ELILO_CLEANUP_SURVIVOR_INTEGRATION_APPLY_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-policy.json}
REVISED_APPLY=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-authorized-apply.sh

TARGET=
HOST=
SURVIVOR_AUTH_EVIDENCE_SHA=
ACTIVE=
ROLLBACK=
SCOPE=
OUTPUT_DIR=
PACKAGE_DATABASE=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
REVISION_READY=false
SURVIVOR_INTEGRATION_READY=false
PAUSE_SAFE=false
NEXT_STAGE=elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 \
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
  --confirm-survivor-authorization-evidence-sha256 SHA256 \
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
  --confirm-apply-revision-review-sha256 SHA256

Review the revised transactional executor that integrates unlink of only the
three separately authorized package-unowned 5.15.19 VirtualBox module
survivors. This review is strictly non-mutating. A third cleanup attempt remains
unauthorized and the revised executor remains fail-closed until a separate
third-attempt authorization record is accepted.
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
   --confirm-survivor-authorization-evidence-sha256) SURVIVOR_AUTH_EVIDENCE_SHA=${2,,}; shift 2;;
   --confirm-active-kernel) ACTIVE=$2; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=$2; shift 2;;
   --confirm-apply-revision-review-sha256) SCOPE=${2,,}; shift 2;;
   --output-dir) OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ -n "$HOST" ] && is_sha "$SURVIVOR_AUTH_EVIDENCE_SHA" \
  && safe_ver "$ACTIVE" && safe_ver "$ROLLBACK" && [ "$ACTIVE" != "$ROLLBACK" ] && is_sha "$SCOPE"
}

init_output(){
 local stamp base
 if [ -z "$OUTPUT_DIR" ]; then
  stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
  base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review
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
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_SURVIVOR_INTEGRATION_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_SURVIVOR_INTEGRATION_TEST_HOST:-$HOST}"; else hostname -f; fi; }
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
 python3 - "$POLICY" "$SELF" "$ACCEPTED_SURVIVOR_AUTH" "$INTEGRATION_CONTRACT" "$APPLY_POLICY" "$REVISED_APPLY" "$HOST" "$SURVIVOR_AUTH_EVIDENCE_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,selfp,accepted,contract,apply_policy,apply,host,evidence,active,rollback,scope=sys.argv[1:]
def reg(p):
 p=pathlib.Path(p)
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return p
def sh(p): return hashlib.sha256(reg(p).read_bytes()).hexdigest()
p=json.loads(reg(pol).read_text()); a=json.loads(reg(accepted).read_text()); c=json.loads(reg(contract).read_text()); ap=json.loads(reg(apply_policy).read_text())
raw=(
 'operation=elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review\n'
 'target=slackware-15.0\n'
 f'hostname_fqdn={host}\n'
 f'survivor_authorization_evidence_sha256={evidence}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'accepted_survivor_authorization_record_sha256={sh(accepted)}\n'
 f'integration_contract_sha256={sh(contract)}\n'
 f'revised_apply_script_sha256={sh(apply)}\n'
 f'prepared_apply_policy_sha256={sh(apply_policy)}\n'
 f'revision_review_script_sha256={sh(selfp)}\n'
).encode()
checks=[
 p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review',
 p.get('reviewed') is True,p.get('expected_script_sha256')==sh(selfp),
 p.get('accepted_survivor_authorization_record_sha256')==sh(accepted),
 p.get('accepted_survivor_authorization_archive_sha256')==evidence,
 p.get('integration_contract_sha256')==sh(contract),p.get('revised_apply_script_sha256')==sh(apply),
 p.get('prepared_apply_policy_sha256')==sh(apply_policy),
 p.get('confirmation_scope_sha256')==scope==hashlib.sha256(raw).hexdigest(),
 a.get('accepted') is True,a.get('archive_sha256')==evidence,a.get('survivor_deletion_authorized') is True,
 a.get('recursive_module_tree_removal_authorized') is False,a.get('active_counterpart_removal_authorized') is False,
 a.get('third_attempt_authorized') is False,a.get('execution_authorized') is False,
 a.get('hostname_fqdn')==host,a.get('active_kernel')==active,a.get('rollback_kernel')==rollback,
 c.get('reviewed') is True,c.get('survivor_count')==3,c.get('third_attempt_authorized') is False,
 c.get('execution_authorized') is False,c.get('survivor_deletion_authorization_archive_sha256')==evidence,
 ap.get('schema')==3,ap.get('scenario')=='elilo-oldkernel-cleanup-authorized-apply-revision-2-prepared',
 ap.get('reviewed') is True,ap.get('execution_authorized') is False,ap.get('third_attempt_authorized') is False,
 ap.get('expected_script_sha256')==sh(apply),ap.get('accepted_survivor_authorization_record_sha256')==sh(accepted),
 ap.get('survivor_integrated_revision_contract_sha256')==sh(contract),
 ap.get('accepted_third_attempt_authorization_archive_sha256') is None,
 ap.get('accepted_third_attempt_authorization_record_sha256') is None,
 ap.get('confirmation_scope_sha256') is None
]
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
 expected=$(json_get "$ACCEPTED_SURVIVOR_AUTH" package_snapshot_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/packages.before.txt")" = "$expected" ] || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_SURVIVOR_AUTH" boot_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_SURVIVOR_AUTH" active_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-active.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_SURVIVOR_AUTH" rollback_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-rollback.before.sha256")" = "$expected" ] || return 1
 python3 - "$ACCEPTED_SURVIVOR_AUTH" "$ROOT_PREFIX" <<'PY'
import hashlib,json,pathlib,sys
a=json.load(open(sys.argv[1])); root=pathlib.Path(sys.argv[2] or '/')
for x in a['survivors']:
 for path,key in ((x['rollback_path'],'rollback_sha256'),(x['active_counterpart_path'],'active_counterpart_sha256')):
  p=root/path.lstrip('/')
  if not p.is_file() or p.is_symlink(): raise SystemExit(1)
  if hashlib.sha256(p.read_bytes()).hexdigest()!=x[key]: raise SystemExit(1)
PY
}

verify_executor_semantics(){
 python3 - "$REVISED_APPLY" "$INTEGRATION_CONTRACT" "$ACCEPTED_SURVIVOR_AUTH" <<'PY'
import json,pathlib,re,sys
script=pathlib.Path(sys.argv[1]).read_text(); c=json.load(open(sys.argv[2])); a=json.load(open(sys.argv[3]))
survivors=a['survivors']
checks=[
 'ACCEPTED_SURVIVOR_AUTH=' in script,
 'ACCEPTED_THIRD_AUTH=' in script,
 '--confirm-survivor-authorization-evidence-sha256' in script,
 '--confirm-third-attempt-authorization-evidence-sha256' in script,
 'UNLINK=${ELILO_CLEANUP_UNLINK:-/usr/bin/unlink}' in script,
 'unlink_exact_authorized_survivors' in script,
 'verify_authorized_survivors_live' in script,
 'verify_authorized_survivors_absent' in script,
 'verify_authorized_survivors_active_counterparts' in script,
 'maybe_fail unlink_exact_reviewed_rollback_survivors' in script,
 'p.get(\'execution_authorized\') is True' in script,
 'ta.get(\'third_attempt_authorized\') is True' in script,
 c['integration']['unlink_tool']=='/usr/bin/unlink',
 c['integration']['ordering'].index('verify_active_after_packages') < c['integration']['ordering'].index('unlink_exact_reviewed_rollback_survivors') < c['integration']['ordering'].index('stage_elilo_config_without_oldkernel'),
 c['prohibitions']['recursive_rollback_module_tree_removal'] is True,
 c['prohibitions']['active_counterpart_removal'] is True,
 c['recovery']['survivors_covered_by_pre_mutation_full_rollback_module_tree_snapshot'] is True,
 len(survivors)==3
]
for x in survivors:
 checks.extend([x['rollback_path'] in script or 'rollback_path' in script,x['active_counterpart_path'].startswith('/lib/modules/5.15.209/misc/')])
raise SystemExit(0 if all(checks) else 1)
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
scenario=elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
survivor_authorization_evidence_sha256=$SURVIVOR_AUTH_EVIDENCE_SHA
revision_ready=$REVISION_READY
survivor_integration_ready=$SURVIVOR_INTEGRATION_READY
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

archive_evidence(){
 local base archive sidecar
 base=${OUTPUT_DIR%/*}
 archive=$base/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
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
 if validate_static; then pass 'the accepted step-102 survivor deletion authorization, exact revised executor, integration contract, prepared policy, and review scope are bound'; else fail 'the static survivor-integrated apply revision boundary is invalid'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_live_boundary; then pass 'the recovered package, ELILO, active-module, rollback-module, and exact survivor state still matches step 102'; else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the live survivor-integrated revision boundary changed'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_executor_semantics; then
  REVISION_READY=true; SURVIVOR_INTEGRATION_READY=true
  pass 'the revised executor integrates only exact reviewed survivor unlink with active-counterpart checks and recovery coverage'
 else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the revised executor does not match the reviewed survivor integration contract'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && [ ! -e "$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-third-attempt-authorization-review-20260814-accepted.json" ]; then
  pass 'the revised executor remains fail-closed because no accepted third-attempt authorization record exists'
 else [ "$FAILURE_COUNT" -gt 0 ] || fail 'a third-attempt authorization record exists before its separate review'; fi
 if verify_no_mutation; then
  PAUSE_SAFE=true
  pass 'the executor revision review did not modify packages, ELILO, boot artifacts, active modules, or rollback modules'
 else fail 'the executor revision review changed protected state'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then NEXT_STAGE=elilo-oldkernel-cleanup-third-attempt-authorization-review; fi
 write_summary
 archive_evidence || err 'failed to archive evidence'
 if [ "$FAILURE_COUNT" -eq 0 ]; then
  printf 'Result: PASS (%d passes, %d failures, %d skips); revision_ready=%s; survivor_integration_ready=%s; third_attempt_authorized=false; cleanup_authorized=false; apply_authorized=false; apply_executed=false; pause_safe=%s; next_stage=%s\n' "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$REVISION_READY" "$SURVIVOR_INTEGRATION_READY" "$PAUSE_SAFE" "$NEXT_STAGE"
  exit 0
 fi
 printf 'Result: FAIL (%d passes, %d failures, %d skips); revision_ready=%s; survivor_integration_ready=%s; third_attempt_authorized=false; pause_safe=%s; next_stage=elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-manual-review\n' "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$REVISION_READY" "$SURVIVOR_INTEGRATION_READY" "$PAUSE_SAFE"
 exit 1
}
main "$@"
