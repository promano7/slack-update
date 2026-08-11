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
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-authorization-review.sh
POLICY=${ELILO_CLEANUP_AUTH_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-policy.json}
ACCEPTED_PLAN=${ELILO_CLEANUP_AUTH_ACCEPTED_PLAN_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json}

TARGET=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_AUTHORIZATION_REVIEW_SHA256=
OUTPUT_DIR=
PACKAGE_DATABASE=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
CLEANUP_READY=false
CLEANUP_AUTHORIZED=false
APPLY_AUTHORIZED=false
APPLY_EXECUTED=false
NEXT_STAGE=elilo-oldkernel-cleanup-authorization-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}

usage(){ cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-15.0 \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-source-plan-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 \\
  --confirm-rollback-kernel 5.15.19 \\
  --confirm-authorization-review-sha256 SHA256 [--output-dir PATH]

Revalidate the accepted mature ELILO cleanup plan and issue a plan-bound
authorization for a later apply stage. This review is non-mutating: it does not
run removepkg or upgradepkg, modify ELILO, delete oldkernel artifacts, refresh
repositories, or reboot.
EOF_USAGE
}
err(){ printf 'ERROR: %s\n' "$*" >&2; }
is_sha(){ [ "${#1}" -eq 64 ] && [[ $1 != *[!0-9A-Fa-f]* ]]; }
safe_ver(){ [ -n "$1" ] && [[ $1 != *[!0-9A-Za-z._+-]* ]]; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log" >&2; }
skip(){ SKIP_COUNT=$((SKIP_COUNT+1)); printf 'SKIP: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }

parse_args(){
 while [ "$#" -gt 0 ]; do
  case "$1" in
   --target) [ "$#" -ge 2 ]||return 1; TARGET=$2; shift 2;;
   --confirm-hostname-fqdn) [ "$#" -ge 2 ]||return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2;;
   --confirm-source-plan-evidence-sha256) [ "$#" -ge 2 ]||return 1; CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256=${2,,}; shift 2;;
   --confirm-active-kernel) [ "$#" -ge 2 ]||return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2;;
   --confirm-rollback-kernel) [ "$#" -ge 2 ]||return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2;;
   --confirm-authorization-review-sha256) [ "$#" -ge 2 ]||return 1; CONFIRM_AUTHORIZATION_REVIEW_SHA256=${2,,}; shift 2;;
   --output-dir) [ "$#" -ge 2 ]||return 1; OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] || return 1
 [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
 is_sha "$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256" || return 1
 is_sha "$CONFIRM_AUTHORIZATION_REVIEW_SHA256" || return 1
 safe_ver "$CONFIRM_ACTIVE_KERNEL" && safe_ver "$CONFIRM_ROLLBACK_KERNEL" || return 1
 [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
 [ -z "$OUTPUT_DIR" ] || [[ $OUTPUT_DIR = /* ]]
}

init_output(){
 local stamp base
 if [ -z "$OUTPUT_DIR" ]; then
  stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
  base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorization-review
  install -d -m 0700 -- "$base" || return 1
  OUTPUT_DIR=$base/slackware-15.0-$stamp
 fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
 install -d -m 0700 -- "$OUTPUT_DIR" || return 1
 : > "$OUTPUT_DIR/assertions.log"
}

rooted(){ printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_AUTH_TEST_HOSTNAME_FQDN:-$CONFIRM_HOSTNAME_FQDN}"; else hostname -f; fi; }
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_AUTH_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE_KERNEL}"; else uname -r; fi; }

resolve_pkgdb(){
 local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages
 if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a
 elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b")
 elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b
 else return 1; fi
}
capture_names(){ find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"; }

capture_boot(){
 python3 - "$ROOT_PREFIX" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$1" <<'PY'
import hashlib,pathlib,sys
root=pathlib.Path(sys.argv[1] or '/'); active,old=sys.argv[2:4]; out=pathlib.Path(sys.argv[4])
paths=['/boot/efi/EFI/Slackware/elilo.conf',f'/boot/vmlinuz-generic-{active}',f'/boot/initrd-generic-{active}.gz',
       f'/boot/vmlinuz-generic-{old}','/boot/initrd.gz',f'/boot/efi/EFI/Slackware/vmlinuz-generic-{active}',
       f'/boot/efi/EFI/Slackware/initrd-generic-{active}.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=[]
for logical in paths:
 p=root/logical.lstrip('/')
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {logical}\n")
out.write_text(''.join(rows))
PY
}

validate_static(){
 python3 - "$POLICY" "$SELF" "$ACCEPTED_PLAN" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256" \
  "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_AUTHORIZATION_REVIEW_SHA256" <<'PY'
import hashlib,json,pathlib,sys
pol,script,accepted,host,evidence,active,rollback,confirmed=sys.argv[1:]
def regular(p):
 p=pathlib.Path(p)
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return p
def sh(p): return hashlib.sha256(regular(p).read_bytes()).hexdigest()
p=json.loads(regular(pol).read_text()); a=json.loads(regular(accepted).read_text())
contract={k:a[k] for k in ['target','hostname_fqdn','active_kernel','rollback_kernel','cleanup_plan_sha256','active_archives','rollback_packages','active_packages','other_kernel_packages_preserved','elilo','ordered_actions','safety_invariants']}
contract['operation']='elilo-oldkernel-cleanup-authorized-apply'
contract_sha=hashlib.sha256((json.dumps(contract,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest()
scope=(
 'operation=elilo-oldkernel-cleanup-authorization-review\n'
 'target=slackware-15.0\n'
 f'hostname_fqdn={host}\n'
 f'source_plan_evidence_sha256={evidence}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'accepted_source_plan_record_sha256={sh(accepted)}\n'
 f'authorization_script_sha256={sh(script)}\n'
 f'apply_contract_sha256={contract_sha}\n').encode()
calc=hashlib.sha256(scope).hexdigest()
checks=[p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-authorization-review',p.get('reviewed') is True,
 p.get('expected_script_sha256')==sh(script),p.get('accepted_source_plan_record_sha256')==sh(accepted),
 p.get('accepted_source_plan_archive_sha256')==evidence==a.get('archive_sha256'),p.get('apply_contract_sha256')==contract_sha,
 p.get('confirmation_scope_sha256')==confirmed==calc,a.get('accepted') is True,a.get('source_ready') is True,
 a.get('plan_ready') is True,a.get('cleanup_ready') is True,a.get('cleanup_authorized') is False,a.get('apply_authorized') is False,
 a.get('hostname_fqdn')==host==p.get('hostname_fqdn'),a.get('active_kernel')==active==p.get('active_kernel'),
 a.get('rollback_kernel')==rollback==p.get('rollback_kernel'),len(a.get('active_archives',[]))==3,
 len(a.get('rollback_packages',[]))==3,len(a.get('ordered_actions',[]))==14]
if not all(checks): raise SystemExit(1)
PY
}

validate_live(){
 local ok=true archive path expected
 [ "$(runtime_fqdn 2>/dev/null)" = "$CONFIRM_HOSTNAME_FQDN" ] || ok=false
 [ "$(runtime_kernel 2>/dev/null)" = "$CONFIRM_ACTIVE_KERNEL" ] || ok=false
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || ok=false
 resolve_pkgdb || ok=false
 capture_names "$OUTPUT_DIR/packages.before.txt" || ok=false
 expected=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["package_name_snapshot_sha256"])' "$ACCEPTED_PLAN") || ok=false
 [ "$(sha "$OUTPUT_DIR/packages.before.txt" 2>/dev/null)" = "$expected" ] || ok=false
 capture_boot "$OUTPUT_DIR/boot.before.sha256" || ok=false
 expected=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["boot_state_snapshot_sha256"])' "$ACCEPTED_PLAN") || ok=false
 [ "$(sha "$OUTPUT_DIR/boot.before.sha256" 2>/dev/null)" = "$expected" ] || ok=false
 for version in "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL"; do
  path=$(rooted "/lib/modules/$version")
  [ -d "$path" ] && [ ! -L "$path" ] && [ -n "$(find "$path" -type f -print -quit 2>/dev/null)" ] || ok=false
 done
 while IFS=$'\t' read -r archive expected; do
  path=$(rooted "$archive")
  [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ] || { ok=false; continue; }
  [ "$(sha "$path" 2>/dev/null)" = "$expected" ] || ok=false
 done < <(python3 - "$ACCEPTED_PLAN" <<'PY'
import json,sys
a=json.load(open(sys.argv[1]))
for x in a['active_archives']: print(x['path']+'\t'+x['sha256'])
PY
)
 [ "$ok" = true ]
}

review_contract(){
 python3 - "$ACCEPTED_PLAN" "$POLICY" "$OUTPUT_DIR/authorization.json" <<'PY'
import hashlib,json,pathlib,sys
a=json.load(open(sys.argv[1])); p=json.load(open(sys.argv[2]))
contract={k:a[k] for k in ['target','hostname_fqdn','active_kernel','rollback_kernel','cleanup_plan_sha256','active_archives','rollback_packages','active_packages','other_kernel_packages_preserved','elilo','ordered_actions','safety_invariants']}
contract['operation']='elilo-oldkernel-cleanup-authorized-apply'
contract_sha=hashlib.sha256((json.dumps(contract,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest()
if contract_sha!=p['apply_contract_sha256']: raise SystemExit(1)
if a['ordered_actions'] != [
'revalidate_inventory_and_running_kernel','verify_exact_active_package_archives','archive_package_and_boot_state',
'remove_exact_rollback_package_records','reinstall_exact_active_package_set','verify_active_package_records_and_module_tree',
'stage_elilo_config_without_oldkernel','validate_active_elilo_entry_and_staged_config','atomically_activate_elilo_config',
'prove_oldkernel_is_no_longer_referenced','verify_active_boot_chain','delete_only_unreferenced_rollback_artifacts',
'capture_and_compare_final_state','publish_private_evidence_and_portable_sha256']:
 raise SystemExit(1)
out={'schema':1,'scenario':'elilo-oldkernel-cleanup-authorization','target':'slackware-15.0',
 'hostname_fqdn':a['hostname_fqdn'],'active_kernel':a['active_kernel'],'rollback_kernel':a['rollback_kernel'],
 'source_plan_archive_sha256':a['archive_sha256'],'cleanup_plan_sha256':a['cleanup_plan_sha256'],
 'apply_contract_sha256':contract_sha,'cleanup_authorized':True,'apply_authorized':True,'apply_executed':False,
 'authorization_scope':'exact-plan-only','ordered_actions':a['ordered_actions'],'safety_invariants':a['safety_invariants']}
pathlib.Path(sys.argv[3]).write_text(json.dumps(out,sort_keys=True,indent=2)+'\n')
PY
}

capture_after(){ capture_names "$OUTPUT_DIR/packages.after.txt" && capture_boot "$OUTPUT_DIR/boot.after.sha256"; }
write_summary(){ cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=elilo-oldkernel-cleanup-authorization-review
target=$TARGET
hostname=$CONFIRM_HOSTNAME_FQDN
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
source_plan_evidence_sha256=$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256
cleanup_ready=$CLEANUP_READY
cleanup_authorized=$CLEANUP_AUTHORIZED
apply_authorized=$APPLY_AUTHORIZED
apply_executed=$APPLY_EXECUTED
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

publish(){
 local base archive side owner group
 base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorization-review
 archive=$base/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
 side=$archive.sha256
 install -d -m 0700 -- "$base" || return 1
 tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
 chmod 0600 "$archive"
 (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side" || return 1
 chmod 0600 "$side"
 printf 'Evidence archive: %s\n' "$archive"
 printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$side")"
 owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users)
 printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
  "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"
 printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"
}

main(){
 parse_args "$@" || { usage >&2; return 2; }
 [ "$(id -u)" -eq 0 ] || { err 'must run as root'; return 2; }
 init_output || return 2
 if validate_static; then pass 'the accepted step-93 source-and-plan evidence, exact authorization code, and plan-bound scope are fixed'
 else fail 'the static cleanup authorization boundary does not match the reviewed contract'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && validate_live; then pass 'the running 5.15.209 system, ELILO state, package database, module trees, and exact cached active archives still match step 93'
 else
  if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the live cleanup boundary or exact active package sources drifted from step 93'; else skip 'live revalidation requires a valid static authorization boundary'; fi
 fi
 if [ "$FAILURE_COUNT" -eq 0 ] && review_contract; then
  CLEANUP_READY=true; CLEANUP_AUTHORIZED=true; APPLY_AUTHORIZED=true; NEXT_STAGE=elilo-oldkernel-cleanup-authorized-apply
  pass 'the exact fourteen-action cleanup contract is authorized for a separate apply stage without executing it'
 else
  if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the accepted plan could not be converted into the exact reviewed cleanup authorization'; else skip 'cleanup authorization requires an unchanged live boundary and source set'; fi
 fi
 if capture_after && [ -f "$OUTPUT_DIR/packages.before.txt" ] && [ -f "$OUTPUT_DIR/boot.before.sha256" ] \
    && cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
    && cmp -s "$OUTPUT_DIR/boot.before.sha256" "$OUTPUT_DIR/boot.after.sha256"; then
  pass 'the authorization review did not modify packages, ELILO, kernel artifacts, or rollback files'
 else fail 'the package database or ELILO boot state changed during authorization review'; fi
 write_summary
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); cleanup_ready=%s; cleanup_authorized=%s; apply_authorized=%s; apply_executed=%s; next_stage=%s\n' \
  "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" \
  "$CLEANUP_READY" "$CLEANUP_AUTHORIZED" "$APPLY_AUTHORIZED" "$APPLY_EXECUTED" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
