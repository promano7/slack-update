#!/bin/bash
set -uo pipefail
IFS=$'\n\t'; umask 077; LC_ALL=C; export LC_ALL
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; export PATH
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-authorized-apply-revision-review.sh
POLICY=${ELILO_CLEANUP_REVISION_REVIEW_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-review-policy.json}
RECOVERY=${ELILO_CLEANUP_ACCEPTED_RECOVERY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-recovery-review-20260811-accepted.json}
PLAN=${ELILO_CLEANUP_ACCEPTED_PLAN_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json}
AUTH=${ELILO_CLEANUP_ACCEPTED_AUTH_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-20260811-accepted.json}
REVISION_CONTRACT=${ELILO_CLEANUP_REVISION_CONTRACT_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-contract.json}
REVISED_APPLY=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-authorized-apply.sh
TARGET=; CONFIRM_HOST=; CONFIRM_RECOVERY_EVIDENCE=; CONFIRM_ACTIVE=; CONFIRM_ROLLBACK=; CONFIRM_SCOPE=; OUTPUT_DIR=
PASS_COUNT=0; FAILURE_COUNT=0; SKIP_COUNT=0; PACKAGE_DATABASE=
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}; ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
usage(){ cat <<EOFU
Usage: ${0##*/} --target slackware-15.0 --confirm-hostname-fqdn HOST \\
 --confirm-recovery-evidence-sha256 SHA256 --confirm-active-kernel 5.15.209 \\
 --confirm-rollback-kernel 5.15.19 --confirm-revision-review-sha256 SHA256
EOFU
}
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
is_sha(){ [ "${#1}" -eq 64 ] && [[ $1 != *[!0-9A-Fa-f]* ]]; }
safe_ver(){ [ -n "$1" ] && [[ $1 != *[!0-9A-Za-z._+-]* ]]; }
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log" >&2; }
rooted(){ printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
json_get(){ python3 - "$1" "$2" <<'PY'
import json,sys
v=json.load(open(sys.argv[1]));
for p in sys.argv[2].split('.'): v=v[p]
if isinstance(v,bool): print(str(v).lower())
elif isinstance(v,(dict,list)): print(json.dumps(v,sort_keys=True,separators=(',',':')))
else: print(v)
PY
}
parse_args(){ while [ "$#" -gt 0 ]; do case "$1" in --target) TARGET=$2; shift 2;; --confirm-hostname-fqdn) CONFIRM_HOST=$2; shift 2;; --confirm-recovery-evidence-sha256) CONFIRM_RECOVERY_EVIDENCE=${2,,}; shift 2;; --confirm-active-kernel) CONFIRM_ACTIVE=$2; shift 2;; --confirm-rollback-kernel) CONFIRM_ROLLBACK=$2; shift 2;; --confirm-revision-review-sha256) CONFIRM_SCOPE=${2,,}; shift 2;; --output-dir) OUTPUT_DIR=$2; shift 2;; *) usage >&2; return 1;; esac; done; [ "$TARGET" = slackware-15.0 ] && [ -n "$CONFIRM_HOST" ] && is_sha "$CONFIRM_RECOVERY_EVIDENCE" && safe_ver "$CONFIRM_ACTIVE" && safe_ver "$CONFIRM_ROLLBACK" && [ "$CONFIRM_ACTIVE" != "$CONFIRM_ROLLBACK" ] && is_sha "$CONFIRM_SCOPE"; }
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE}"; else uname -r; fi; }
runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_TEST_HOSTNAME_FQDN:-$CONFIRM_HOST}"; else hostname -f; fi; }
resolve_pkgdb(){ local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages; if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a; elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b"); elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b; else return 1; fi; }
capture_names(){ find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"; }
module_manifest(){ local v=$1 o=$2 d; d=$(rooted "/lib/modules/$v"); [ -d "$d" ] && [ ! -L "$d" ] || return 1; (cd "$d" && find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' f; do sha256sum -- "$f"; done) > "$o"; }
capture_boot(){ python3 - "$ROOT_PREFIX" "$CONFIRM_ACTIVE" "$CONFIRM_ROLLBACK" "$1" <<'PY'
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
validate_static(){ python3 - "$POLICY" "$SELF" "$RECOVERY" "$PLAN" "$AUTH" "$REVISION_CONTRACT" "$REVISED_APPLY" "$CONFIRM_HOST" "$CONFIRM_RECOVERY_EVIDENCE" "$CONFIRM_ACTIVE" "$CONFIRM_ROLLBACK" "$CONFIRM_SCOPE" <<'PY'
import hashlib,json,pathlib,sys
pol,selfp,rec,plan,auth,contract,apply,host,evidence,active,rollback,scope=sys.argv[1:]
def reg(p):
 p=pathlib.Path(p)
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return p
def sh(p): return hashlib.sha256(reg(p).read_bytes()).hexdigest()
p=json.loads(reg(pol).read_text()); r=json.loads(reg(rec).read_text()); pl=json.loads(reg(plan).read_text()); a=json.loads(reg(auth).read_text()); c=json.loads(reg(contract).read_text())
raw=('operation=elilo-oldkernel-cleanup-authorized-apply-revision-review\n'+'target=slackware-15.0\n'+f'hostname_fqdn={host}\n'+f'recovery_evidence_sha256={evidence}\n'+f'active_kernel={active}\n'+f'rollback_kernel={rollback}\n'+f'accepted_recovery_record_sha256={sh(rec)}\n'+f'revision_contract_sha256={sh(contract)}\n'+f'revised_apply_script_sha256={sh(apply)}\n'+f'revision_review_script_sha256={sh(selfp)}\n').encode()
checks=[p.get('schema')==1,p.get('scenario')=='elilo-oldkernel-cleanup-authorized-apply-revision-review',p.get('reviewed') is True,p.get('expected_script_sha256')==sh(selfp),p.get('accepted_recovery_record_sha256')==sh(rec),p.get('revision_contract_sha256')==sh(contract),p.get('revised_apply_script_sha256')==sh(apply),p.get('confirmation_scope_sha256')==scope==hashlib.sha256(raw).hexdigest(),r.get('status')=='accepted-recovery-review',r.get('archive_sha256')==evidence,r.get('recovery_verified') is True,r.get('cleanup_authorized') is False,r.get('apply_authorized') is False,r.get('hostname_fqdn')==host,r.get('active_kernel')==active,r.get('rollback_kernel')==rollback,c.get('immutable_module_validation',{}).get('compare_all_kernel_module_objects_byte_for_byte') is True,c.get('immutable_module_validation',{}).get('additional_generated_paths_allowed') is False,c.get('base_apply_contract_sha256')==a.get('apply_contract_sha256'),pl.get('accepted') is True]
raise SystemExit(0 if all(checks) else 1)
PY
}
verify_live(){ local ok=true backup recsha; [ "$(runtime_fqdn)" = "$CONFIRM_HOST" ] || ok=false; [ "$(runtime_kernel)" = "$CONFIRM_ACTIVE" ] || ok=false; [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || ok=false; resolve_pkgdb || ok=false; capture_names "$OUTPUT_DIR/packages.before.txt" || ok=false; [ "$(sha "$OUTPUT_DIR/packages.before.txt" 2>/dev/null)" = "$(json_get "$RECOVERY" package_snapshot_sha256)" ] || ok=false; capture_boot "$OUTPUT_DIR/boot.before.sha256" || ok=false; [ "$(sha "$OUTPUT_DIR/boot.before.sha256" 2>/dev/null)" = "$(json_get "$RECOVERY" boot_manifest_sha256)" ] || ok=false; module_manifest "$CONFIRM_ACTIVE" "$OUTPUT_DIR/modules-active.before.sha256" || ok=false; [ "$(sha "$OUTPUT_DIR/modules-active.before.sha256" 2>/dev/null)" = "$(json_get "$RECOVERY" active_module_manifest_sha256)" ] || ok=false; module_manifest "$CONFIRM_ROLLBACK" "$OUTPUT_DIR/modules-rollback.before.sha256" || ok=false; [ "$(sha "$OUTPUT_DIR/modules-rollback.before.sha256" 2>/dev/null)" = "$(json_get "$RECOVERY" rollback_module_manifest_sha256)" ] || ok=false; backup=$(rooted "$(json_get "$RECOVERY" recovery_backup_path)"); [ -d "$backup" ] && [ ! -L "$backup" ] || ok=false; [ -f "$backup/archive.sha256" ] && [ "$(sha "$backup/archive.sha256" 2>/dev/null)" = "$(json_get "$RECOVERY" recovery_archive_manifest_sha256)" ] || ok=false; (cd "$backup" && sha256sum -c archive.sha256 > "$OUTPUT_DIR/recovery-backup-verify.log" 2>&1) || ok=false; while IFS=$'\t' read -r path digest; do [ -f "$(rooted "$path")" ] && [ "$(sha "$(rooted "$path")" 2>/dev/null)" = "$digest" ] || ok=false; done < <(python3 - "$PLAN" <<'PY'
import json,sys
for x in json.load(open(sys.argv[1]))['active_archives']: print(x['path']+'\t'+x['sha256'])
PY
); [ "$ok" = true ]; }
verify_revision_semantics(){ python3 - "$REVISION_CONTRACT" "$REVISED_APPLY" <<'PY'
import json,pathlib,sys
c=json.load(open(sys.argv[1])); s=pathlib.Path(sys.argv[2]).read_text(); expected=['./modules.alias','./modules.alias.bin','./modules.dep','./modules.dep.bin','./modules.symbols','./modules.symbols.bin']; v=c['immutable_module_validation']; checks=[v['generated_depmod_indexes_allowed_to_change']==expected,v['compare_all_kernel_module_objects_byte_for_byte'] is True,v['compare_all_non_generated_module_files_byte_for_byte'] is True,v['additional_generated_paths_allowed'] is False,v['require_read_only_depmod_validation'] is True,'module_stable_manifest' in s,'module_object_manifest' in s,'verify_generated_depmod_indexes' in s,'"$DEPMOD" -n "$version"' in s]; raise SystemExit(0 if all(checks) else 1)
PY
}
capture_after(){ capture_names "$OUTPUT_DIR/packages.after.txt" && capture_boot "$OUTPUT_DIR/boot.after.sha256" && module_manifest "$CONFIRM_ACTIVE" "$OUTPUT_DIR/modules-active.after.sha256" && module_manifest "$CONFIRM_ROLLBACK" "$OUTPUT_DIR/modules-rollback.after.sha256"; }
init_output(){ local base; if [ -z "$OUTPUT_DIR" ]; then base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorized-apply-revision-review; install -d -m 0700 "$base" || return 1; OUTPUT_DIR=$base/slackware-15.0-$(date -u +%Y%m%dT%H%M%SZ); fi; [ ! -e "$OUTPUT_DIR" ] || return 1; install -d -m 0700 "$OUTPUT_DIR"; : > "$OUTPUT_DIR/assertions.log"; }
publish(){ local base archive side owner group; base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-authorized-apply-revision-review; archive=$base/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-review-$(date -u +%Y%m%dT%H%M%SZ).tar.gz; side=$archive.sha256; install -d -m 0700 "$base"; tar -C "$(dirname "$OUTPUT_DIR")" -czf "$archive" "$(basename "$OUTPUT_DIR")"; chmod 0600 "$archive"; (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side"; chmod 0600 "$side"; printf 'Evidence archive: %s\nEvidence SHA-256: %s\n' "$archive" "$(awk '{print $1}' "$side")"; owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users); printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"; printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"; }
main(){ parse_args "$@" || return 2; [ "$(id -u)" -eq 0 ] || [ "$TEST_MODE" = 1 ] || return 2; init_output || return 2; if validate_static; then pass 'the accepted recovery, corrected validation contract, exact revised executor, and review scope are bound'; else fail 'the static revision-review boundary does not match'; fi; if [ "$FAILURE_COUNT" -eq 0 ] && verify_live; then pass 'the recovered 5.15.209/5.15.19 ELILO state and private recovery backup remain exact after the intervening reboot'; else fail 'the recovered live boundary or recovery backup drifted'; fi; if [ "$FAILURE_COUNT" -eq 0 ] && verify_revision_semantics; then pass 'the revised executor permits only the six reviewed depmod indexes to regenerate while keeping every module object and all other module files immutable'; else fail 'the revised module validation semantics are not exact'; fi; if [ "$FAILURE_COUNT" -eq 0 ] && capture_after && cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" && cmp -s "$OUTPUT_DIR/boot.before.sha256" "$OUTPUT_DIR/boot.after.sha256" && cmp -s "$OUTPUT_DIR/modules-active.before.sha256" "$OUTPUT_DIR/modules-active.after.sha256" && cmp -s "$OUTPUT_DIR/modules-rollback.before.sha256" "$OUTPUT_DIR/modules-rollback.after.sha256"; then pass 'the revision review did not modify packages, ELILO, boot artifacts, module trees, or the retained recovery state'; else fail 'the revision review changed protected state'; fi; local revised_hash contract_hash; revised_hash=$(sha "$REVISED_APPLY"); contract_hash=$(sha "$REVISION_CONTRACT"); cat > "$OUTPUT_DIR/summary.txt" <<EOFS
scenario=elilo-oldkernel-cleanup-authorized-apply-revision-review
target=$TARGET
hostname=$CONFIRM_HOST
active_kernel=$CONFIRM_ACTIVE
rollback_kernel=$CONFIRM_ROLLBACK
recovery_evidence_sha256=$CONFIRM_RECOVERY_EVIDENCE
revised_apply_script_sha256=$revised_hash
revision_contract_sha256=$contract_hash
revision_ready=$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)
retry_authorized=$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)
cleanup_authorized=$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)
apply_authorized=$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)
apply_executed=false
pause_safe=true
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
next_stage=$([ "$FAILURE_COUNT" -eq 0 ] && printf elilo-oldkernel-cleanup-authorized-apply-revision-1 || printf elilo-oldkernel-cleanup-authorized-apply-revision-manual-review)
EOFS
 publish || return 2; printf 'Result: %s (%d passes, %d failures, %d skips); revision_ready=%s; retry_authorized=%s; cleanup_authorized=%s; apply_authorized=%s; apply_executed=false; pause_safe=true; next_stage=%s\n' "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)" "$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)" "$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)" "$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)" "$([ "$FAILURE_COUNT" -eq 0 ] && printf elilo-oldkernel-cleanup-authorized-apply-revision-1 || printf elilo-oldkernel-cleanup-authorized-apply-revision-manual-review)"; [ "$FAILURE_COUNT" -eq 0 ]; }
main "$@"
