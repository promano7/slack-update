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
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-third-attempt-authorization-review.sh
POLICY=${ELILO_CLEANUP_THIRD_AUTH_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-third-attempt-authorization-review-policy.json}
ACCEPTED_REVISION=${ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_REVISION_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review-20260814-accepted.json}
ACCEPTED_PLAN=${ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_PLAN_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json}
ACCEPTED_SURVIVOR_AUTH=${ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_SURVIVOR_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review-20260814-accepted.json}
REVISED_APPLY=${ELILO_CLEANUP_THIRD_AUTH_REVISED_APPLY_PATH:-$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh}
INTEGRATION_CONTRACT=${ELILO_CLEANUP_THIRD_AUTH_INTEGRATION_CONTRACT_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-survivor-integrated-apply-revision-contract.json}
PREPARED_APPLY_POLICY=${ELILO_CLEANUP_THIRD_AUTH_PREPARED_APPLY_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-policy.json}
AUTH_CONTRACT=${ELILO_CLEANUP_THIRD_AUTH_CONTRACT_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-third-attempt-authorization-contract.json}

TARGET=
HOST=
REVISION_EVIDENCE_SHA=
ACTIVE=
ROLLBACK=
SCOPE=
OUTPUT_DIR=
PACKAGE_DATABASE=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
THIRD_ATTEMPT_AUTHORIZED=false
CLEANUP_AUTHORIZED=false
APPLY_AUTHORIZED=false
EXECUTION_AUTHORIZED=false
PAUSE_SAFE=false
NEXT_STAGE=elilo-oldkernel-cleanup-third-attempt-authorization-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-revision-review-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \\
  --confirm-third-attempt-authorization-sha256 SHA256

Authorize a third ELILO oldkernel cleanup attempt only against the exact accepted
step-103 survivor-integrated executor revision. This review is strictly
non-mutating. It binds the live recovered state, exact cached 5.15.209 archives,
exact three rollback VirtualBox survivors, and revised executor. Destructive
execution remains disabled until a later prepared apply boundary consumes this
accepted authorization.
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
   --confirm-revision-review-evidence-sha256) REVISION_EVIDENCE_SHA=${2,,}; shift 2;;
   --confirm-active-kernel) ACTIVE=$2; shift 2;;
   --confirm-rollback-kernel) ROLLBACK=$2; shift 2;;
   --confirm-third-attempt-authorization-sha256) SCOPE=${2,,}; shift 2;;
   --output-dir) OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] && [ -n "$HOST" ] && is_sha "$REVISION_EVIDENCE_SHA" \
  && safe_ver "$ACTIVE" && safe_ver "$ROLLBACK" && [ "$ACTIVE" != "$ROLLBACK" ] && is_sha "$SCOPE"
}

init_output(){
 local stamp base
 if [ -z "$OUTPUT_DIR" ]; then
  stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
  base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-third-attempt-authorization-review
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
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_THIRD_AUTH_TEST_KERNEL:-$ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_THIRD_AUTH_TEST_HOST:-$HOST}"; else hostname -f; fi; }
resolve_pkgdb(){
 local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages
 if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a
 elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b")
 elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b
 else return 1; fi
}
capture_names(){ find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"; }
capture_active_archives(){
 local out=$1 rec path digest actual
 : > "$out" || return 1
 while IFS=$'\t' read -r rec path digest; do
  [ -f "$(rooted "$path")" ] && [ ! -L "$(rooted "$path")" ] || return 1
  actual=$(sha "$(rooted "$path")") || return 1
  [ "$actual" = "$digest" ] || return 1
  printf '%s  %s\n' "$actual" "$path" >> "$out" || return 1
 done < <(python3 - "$ACCEPTED_PLAN" <<'PY2'
import json,sys
for x in json.load(open(sys.argv[1]))['active_archives']:
 print(x['record']+'\t'+x['path']+'\t'+x['sha256'])
PY2
)
}
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
 python3 - "$POLICY" "$ACCEPTED_REVISION" "$ACCEPTED_PLAN" "$ACCEPTED_SURVIVOR_AUTH" "$REVISED_APPLY" "$INTEGRATION_CONTRACT" "$PREPARED_APPLY_POLICY" "$AUTH_CONTRACT" "$SELF" "$HOST" "$REVISION_EVIDENCE_SHA" "$ACTIVE" "$ROLLBACK" "$SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,accepted,plan,survivor,apply,contract,apply_policy,auth_contract,selfp=map(pathlib.Path,sys.argv[1:10]); host,evidence,active,rollback,scope=sys.argv[10:]
def reg(p):
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return p
def sh(p): return hashlib.sha256(reg(p).read_bytes()).hexdigest()
p=json.load(open(reg(pol))); a=json.load(open(reg(accepted))); pl=json.load(open(reg(plan))); sa=json.load(open(reg(survivor))); c=json.load(open(reg(contract))); ap=json.load(open(reg(apply_policy))); ac=json.load(open(reg(auth_contract)))
raw=(
 'operation=elilo-oldkernel-cleanup-third-attempt-authorization-review\n'
 'target=slackware-15.0\n'+f'hostname_fqdn={host}\n'+f'revision_review_evidence_sha256={evidence}\n'
 +f'active_kernel={active}\nrollback_kernel={rollback}\n'+f'accepted_revision_review_record_sha256={sh(accepted)}\n'
 +f'accepted_source_plan_record_sha256={sh(plan)}\n'+f'accepted_survivor_authorization_record_sha256={sh(survivor)}\n'
 +f'revised_apply_script_sha256={sh(apply)}\n'+f'survivor_integrated_revision_contract_sha256={sh(contract)}\n'
 +f'prepared_apply_policy_sha256={sh(apply_policy)}\n'+f'third_attempt_authorization_contract_sha256={sh(auth_contract)}\n'
 +f'authorization_script_sha256={sh(selfp)}\n').encode()
checks=[
 p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-third-attempt-authorization-review',p.get('reviewed') is True,p.get('mutation_forbidden') is True,
 p.get('expected_script_sha256')==sh(selfp),p.get('accepted_revision_review_record_sha256')==sh(accepted),p.get('accepted_revision_review_archive_sha256')==evidence,
 p.get('accepted_source_plan_record_sha256')==sh(plan),p.get('accepted_survivor_authorization_record_sha256')==sh(survivor),
 p.get('revised_apply_script_sha256')==sh(apply),p.get('survivor_integrated_revision_contract_sha256')==sh(contract),p.get('prepared_apply_policy_sha256')==sh(apply_policy),
 p.get('third_attempt_authorization_contract_sha256')==sh(auth_contract),p.get('confirmation_scope_sha256')==scope==hashlib.sha256(raw).hexdigest(),
 p.get('hostname_fqdn')==host,p.get('active_kernel')==active,p.get('rollback_kernel')==rollback,p.get('execution_authorized') is False,
 a.get('accepted') is True,a.get('archive_sha256')==evidence,a.get('revision_ready') is True,a.get('survivor_integration_ready') is True,a.get('third_attempt_authorized') is False,
 a.get('cleanup_authorized') is False,a.get('apply_authorized') is False,a.get('apply_executed') is False,a.get('pause_safe') is True,
 a.get('hostname_fqdn')==host,a.get('active_kernel')==active,a.get('rollback_kernel')==rollback,a.get('revised_apply_script_sha256')==sh(apply),
 a.get('integration_contract_sha256')==sh(contract),a.get('prepared_apply_policy_sha256')==sh(apply_policy),
 pl.get('accepted') is True,pl.get('source_ready') is True,pl.get('plan_ready') is True,pl.get('cleanup_ready') is True,
 sa.get('accepted') is True,sa.get('survivor_deletion_authorized') is True,sa.get('recursive_module_tree_removal_authorized') is False,sa.get('active_counterpart_removal_authorized') is False,
 sa.get('third_attempt_authorized') is False,sa.get('execution_authorized') is False,sa.get('archive_sha256')==a.get('survivor_authorization_evidence_sha256'),
 c.get('reviewed') is True,c.get('survivor_count')==3,c.get('third_attempt_authorized') is False,c.get('execution_authorized') is False,
 ap.get('schema')==3,ap.get('scenario')=='elilo-oldkernel-cleanup-authorized-apply-revision-2-prepared',ap.get('reviewed') is True,
 ap.get('expected_script_sha256')==sh(apply),ap.get('execution_authorized') is False,ap.get('third_attempt_authorized') is False,
 ap.get('accepted_third_attempt_authorization_archive_sha256') is None,ap.get('accepted_third_attempt_authorization_record_sha256') is None,ap.get('confirmation_scope_sha256') is None,
 ac.get('schema')==1,ac.get('scenario')=='elilo-oldkernel-cleanup-third-attempt-authorization-contract',ac.get('accepted_revision_review_archive_sha256')==evidence,
 ac.get('accepted_revision_review_record_sha256')==sh(accepted),ac.get('revised_apply_script_sha256')==sh(apply),ac.get('survivor_integrated_revision_contract_sha256')==sh(contract),
 ac.get('survivor_deletion_authorization_archive_sha256')==sa.get('archive_sha256'),ac.get('active_kernel')==active,ac.get('rollback_kernel')==rollback,
 ac.get('third_attempt_authorized') is True,ac.get('cleanup_authorized') is True,ac.get('apply_authorized') is True,ac.get('execution_authorized') is False,ac.get('apply_executed') is False,
 ac.get('repository_refresh_authorized') is False,ac.get('network_access_authorized') is False,ac.get('reboot_execution_authorized') is False,
 ac.get('recursive_module_tree_removal_authorized') is False,ac.get('active_counterpart_removal_authorized') is False,
 ac.get('recovery_snapshot_required_before_mutation') is True,ac.get('exact_cached_active_archives_required') is True,ac.get('exact_survivor_unlink_required') is True
]
raise SystemExit(0 if all(checks) else 1)
PY
}

verify_live_boundary(){
 local expected rec path digest
 [ "$(runtime_fqdn 2>/dev/null)" = "$HOST" ] || return 1
 [ "$(runtime_kernel 2>/dev/null)" = "$ACTIVE" ] || return 1
 [ -d "${ROOT_PREFIX}/sys/firmware/efi" ] || [ "$TEST_MODE" = 1 ] || return 1
 resolve_pkgdb || return 1
 capture_names "$OUTPUT_DIR/packages.before.txt" || return 1
 expected=$(json_get "$ACCEPTED_REVISION" package_snapshot_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/packages.before.txt")" = "$expected" ] || return 1
 capture_boot_selected "$OUTPUT_DIR/boot.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_REVISION" boot_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ACTIVE" "$OUTPUT_DIR/modules-active.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_REVISION" active_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-active.before.sha256")" = "$expected" ] || return 1
 module_manifest "$ROLLBACK" "$OUTPUT_DIR/modules-rollback.before.sha256" || return 1
 expected=$(json_get "$ACCEPTED_REVISION" rollback_module_manifest_sha256) || return 1
 [ "$(sha "$OUTPUT_DIR/modules-rollback.before.sha256")" = "$expected" ] || return 1
 capture_active_archives "$OUTPUT_DIR/active-archives.before.sha256" || return 1
 python3 - "$ACCEPTED_SURVIVOR_AUTH" "$ROOT_PREFIX" <<'PY'
import hashlib,json,pathlib,sys
a=json.load(open(sys.argv[1])); root=pathlib.Path(sys.argv[2] or '/')
if len(a.get('survivors',[]))!=3: raise SystemExit(1)
for x in a['survivors']:
 for path,key in ((x['rollback_path'],'rollback_sha256'),(x['active_counterpart_path'],'active_counterpart_sha256')):
  p=root/path.lstrip('/')
  if not p.is_file() or p.is_symlink(): raise SystemExit(1)
  if hashlib.sha256(p.read_bytes()).hexdigest()!=x[key]: raise SystemExit(1)
PY
}

write_authorization(){
 cp -- "$AUTH_CONTRACT" "$OUTPUT_DIR/third-attempt-authorization.json" || return 1
 [ "$(sha "$OUTPUT_DIR/third-attempt-authorization.json")" = "$(sha "$AUTH_CONTRACT")" ] || return 1
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
 capture_active_archives "$OUTPUT_DIR/active-archives.after.sha256" || return 1
 cmp -s "$OUTPUT_DIR/active-archives.before.sha256" "$OUTPUT_DIR/active-archives.after.sha256" || return 1
}

write_summary(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-third-attempt-authorization-review
target=$TARGET
hostname=$HOST
active_kernel=$ACTIVE
rollback_kernel=$ROLLBACK
revision_review_evidence_sha256=$REVISION_EVIDENCE_SHA
third_attempt_authorized=$THIRD_ATTEMPT_AUTHORIZED
cleanup_authorized=$CLEANUP_AUTHORIZED
apply_authorized=$APPLY_AUTHORIZED
execution_authorized=$EXECUTION_AUTHORIZED
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
 archive=$base/slackware-15.0-elilo-oldkernel-cleanup-third-attempt-authorization-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
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
 if validate_static; then pass 'the accepted step-103 revision, exact survivor-integrated executor, authorization contract, and review scope are bound'; else fail 'the static third-attempt authorization boundary is invalid'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_live_boundary; then pass 'the recovered 5.15.209/5.15.19 state, exact three survivors, and cached active kernel archives still match the accepted boundary'; else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the live third-attempt authorization boundary changed'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && write_authorization; then THIRD_ATTEMPT_AUTHORIZED=true; CLEANUP_AUTHORIZED=true; APPLY_AUTHORIZED=true; pass 'a third attempt is authorized only for the exact reviewed survivor-integrated transaction while execution remains separately disabled'; else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the exact third-attempt authorization contract could not be fixed'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && [ "$(json_get "$PREPARED_APPLY_POLICY" execution_authorized)" = false ] && [ "$(json_get "$PREPARED_APPLY_POLICY" third_attempt_authorized)" = false ]; then pass 'the prepared destructive executor remains fail-closed until this authorization is accepted by a later apply boundary'; else [ "$FAILURE_COUNT" -gt 0 ] || fail 'the destructive executor is executable before the separate apply boundary'; fi
 if verify_no_mutation; then PAUSE_SAFE=true; pass 'the third-attempt authorization review did not modify packages, ELILO, boot artifacts, active modules, rollback modules, or cached archives'; else fail 'the authorization review changed protected state'; fi
 if [ "$FAILURE_COUNT" -eq 0 ]; then NEXT_STAGE=elilo-oldkernel-cleanup-authorized-apply-revision-2; fi
 write_summary
 archive_evidence || err 'failed to archive evidence'
 if [ "$FAILURE_COUNT" -eq 0 ]; then
  printf 'Result: PASS (%d passes, %d failures, %d skips); third_attempt_authorized=%s; cleanup_authorized=%s; apply_authorized=%s; execution_authorized=%s; apply_executed=false; pause_safe=%s; next_stage=%s\n' "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$THIRD_ATTEMPT_AUTHORIZED" "$CLEANUP_AUTHORIZED" "$APPLY_AUTHORIZED" "$EXECUTION_AUTHORIZED" "$PAUSE_SAFE" "$NEXT_STAGE"
  exit 0
 fi
 printf 'Result: FAIL (%d passes, %d failures, %d skips); third_attempt_authorized=%s; execution_authorized=false; apply_executed=false; pause_safe=%s; next_stage=elilo-oldkernel-cleanup-third-attempt-authorization-manual-review\n' "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$THIRD_ATTEMPT_AUTHORIZED" "$PAUSE_SAFE"
 exit 1
}
main "$@"
