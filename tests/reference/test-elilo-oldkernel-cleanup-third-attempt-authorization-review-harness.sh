#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-third-attempt-authorization-review.sh
APPLY=$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
TROOT=$TMP/root
FIX=$TMP/fixtures
PASS=0
FAIL=0
DESC=

ok(){ PASS=$((PASS+1)); printf 'ok - %s\n' "$1"; }
not_ok(){ FAIL=$((FAIL+1)); printf 'not ok - %s\n' "$1" >&2; }
check(){ if "$@"; then ok "$DESC"; else not_ok "$DESC"; fi; }

mkdir -p "$TROOT/sys/firmware/efi" "$TROOT/var/lib/pkgtools/packages" \
 "$TROOT/boot/efi/EFI/Slackware" "$TROOT/lib/modules/5.15.209/misc" "$TROOT/lib/modules/5.15.19/misc" \
 "$TROOT/var/cache/packages/patches/packages/linux-5.15.209" "$FIX"

for rec in \
 kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 \
 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2 \
 kernel-firmware-20250912_f0f4634-noarch-1 kernel-headers-5.15.209-x86-1 kernel-source-5.15.209-noarch-1; do
 printf 'PACKAGE NAME: %s\n' "$rec" > "$TROOT/var/lib/pkgtools/packages/$rec"
done

printf 'elilo-config\n' > "$TROOT/boot/efi/EFI/Slackware/elilo.conf"
printf 'active-kernel\n' > "$TROOT/boot/vmlinuz-generic-5.15.209"
printf 'active-initrd\n' > "$TROOT/boot/initrd-generic-5.15.209.gz"
printf 'rollback-kernel\n' > "$TROOT/boot/vmlinuz-generic-5.15.19"
printf 'rollback-initrd\n' > "$TROOT/boot/initrd.gz"
printf 'active-kernel\n' > "$TROOT/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
printf 'active-initrd\n' > "$TROOT/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
printf 'rollback-kernel\n' > "$TROOT/boot/efi/EFI/Slackware/vmlinuz"
printf 'rollback-initrd\n' > "$TROOT/boot/efi/EFI/Slackware/initrd.gz"

for m in vboxguest vboxsf vboxvideo; do
 printf 'active-%s\n' "$m" > "$TROOT/lib/modules/5.15.209/misc/$m.ko"
 printf 'rollback-%s\n' "$m" > "$TROOT/lib/modules/5.15.19/misc/$m.ko"
done
printf 'active-core\n' > "$TROOT/lib/modules/5.15.209/kernel-core.ko"
printf 'rollback-core\n' > "$TROOT/lib/modules/5.15.19/kernel-core.ko"
for v in 5.15.209 5.15.19; do
 for f in modules.alias modules.alias.bin modules.dep modules.dep.bin modules.symbols modules.symbols.bin; do printf '%s-%s\n' "$v" "$f" > "$TROOT/lib/modules/$v/$f"; done
done

printf 'generic-archive\n' > "$TROOT/var/cache/packages/patches/packages/linux-5.15.209/kernel-generic-5.15.209-x86_64-1.txz"
printf 'huge-archive\n' > "$TROOT/var/cache/packages/patches/packages/linux-5.15.209/kernel-huge-5.15.209-x86_64-1.txz"
printf 'modules-archive\n' > "$TROOT/var/cache/packages/patches/packages/linux-5.15.209/kernel-modules-5.15.209-x86_64-1.txz"

python3 - "$TROOT" "$FIX" "$SCRIPT" "$APPLY" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1]); fx=pathlib.Path(sys.argv[2]); script=pathlib.Path(sys.argv[3]); apply=pathlib.Path(sys.argv[4])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def write(name,obj):
 p=fx/name; p.write_text(json.dumps(obj,indent=2,sort_keys=True)+'\n'); return p
def manifest(d):
 d=pathlib.Path(d); rows=[]
 for p in sorted(x for x in d.rglob('*') if x.is_file()):
  rel='./'+p.relative_to(d).as_posix(); rows.append(f'{sh(p)}  {rel}\n')
 return hashlib.sha256(''.join(rows).encode()).hexdigest()
names=''.join(x.name+'\n' for x in sorted((root/'var/lib/pkgtools/packages').iterdir()) if x.is_file())
pkg_hash=hashlib.sha256(names.encode()).hexdigest()
logical=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
boot=''.join(f'{sh(root/p.lstrip("/"))}  {p}\n' for p in logical)
boot_hash=hashlib.sha256(boot.encode()).hexdigest()
survivors=[]
for m in ('vboxguest','vboxsf','vboxvideo'):
 old=f'/lib/modules/5.15.19/misc/{m}.ko'; active=f'/lib/modules/5.15.209/misc/{m}.ko'
 survivors.append({'module_name':m,'rollback_path':old,'rollback_sha256':sh(root/old.lstrip('/')),'active_counterpart_path':active,'active_counterpart_sha256':sh(root/active.lstrip('/'))})
survivor=write('survivor.json',{
 'accepted':True,'archive_sha256':'b'*64,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19',
 'survivor_deletion_authorized':True,'recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,'third_attempt_authorized':False,'execution_authorized':False,
 'survivors':survivors})
archives=[]
for rec in ('kernel-generic-5.15.209-x86_64-1','kernel-huge-5.15.209-x86_64-1','kernel-modules-5.15.209-x86_64-1'):
 p=f'/var/cache/packages/patches/packages/linux-5.15.209/{rec}.txz'; archives.append({'record':rec,'path':p,'sha256':sh(root/p.lstrip('/'))})
plan=write('plan.json',{'accepted':True,'source_ready':True,'plan_ready':True,'cleanup_ready':True,'active_archives':archives})
integration=write('integration.json',{'schema':1,'scenario':'elilo-oldkernel-cleanup-survivor-integrated-apply-revision-contract','reviewed':True,'survivor_count':3,'third_attempt_authorized':False,'execution_authorized':False})
apply_policy=write('apply-policy.json',{'schema':3,'scenario':'elilo-oldkernel-cleanup-authorized-apply-revision-2-prepared','reviewed':True,'expected_script_sha256':sh(apply),'execution_authorized':False,'third_attempt_authorized':False,'accepted_third_attempt_authorization_archive_sha256':None,'accepted_third_attempt_authorization_record_sha256':None,'confirmation_scope_sha256':None})
accepted=write('accepted.json',{
 'accepted':True,'archive_sha256':'a'*64,'revision_ready':True,'survivor_integration_ready':True,'third_attempt_authorized':False,'cleanup_authorized':False,'apply_authorized':False,'apply_executed':False,'pause_safe':True,
 'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','revised_apply_script_sha256':sh(apply),'integration_contract_sha256':sh(integration),'prepared_apply_policy_sha256':sh(apply_policy),
 'survivor_authorization_evidence_sha256':'b'*64,'package_snapshot_sha256':pkg_hash,'boot_manifest_sha256':boot_hash,'active_module_manifest_sha256':manifest(root/'lib/modules/5.15.209'),'rollback_module_manifest_sha256':manifest(root/'lib/modules/5.15.19')})
contract=write('auth-contract.json',{
 'schema':1,'scenario':'elilo-oldkernel-cleanup-third-attempt-authorization-contract','accepted_revision_review_archive_sha256':'a'*64,'accepted_revision_review_record_sha256':sh(accepted),
 'survivor_deletion_authorization_archive_sha256':'b'*64,'survivor_deletion_authorization_record_sha256':sh(survivor),'base_apply_contract_sha256':'e5b587aacb911a05428706a09c3d7a85dc35a9802e46ccf8131cb3569dd6806f',
 'survivor_integrated_revision_contract_sha256':sh(integration),'revised_apply_script_sha256':sh(apply),'active_kernel':'5.15.209','rollback_kernel':'5.15.19','third_attempt_authorized':True,'cleanup_authorized':True,'apply_authorized':True,'execution_authorized':False,'apply_executed':False,
 'repository_refresh_authorized':False,'network_access_authorized':False,'reboot_execution_authorized':False,'recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,'recovery_snapshot_required_before_mutation':True,'exact_cached_active_archives_required':True,'exact_survivor_unlink_required':True,'next_stage':'elilo-oldkernel-cleanup-authorized-apply-revision-2'})
raw=(
 'operation=elilo-oldkernel-cleanup-third-attempt-authorization-review\n''target=slackware-15.0\n''hostname_fqdn=vbox-slack15.vbox-slack15.org\n'+'revision_review_evidence_sha256='+'a'*64+'\n'
 +'active_kernel=5.15.209\nrollback_kernel=5.15.19\n'+f'accepted_revision_review_record_sha256={sh(accepted)}\n'+f'accepted_source_plan_record_sha256={sh(plan)}\n'+f'accepted_survivor_authorization_record_sha256={sh(survivor)}\n'
 +f'revised_apply_script_sha256={sh(apply)}\n'+f'survivor_integrated_revision_contract_sha256={sh(integration)}\n'+f'prepared_apply_policy_sha256={sh(apply_policy)}\n'+f'third_attempt_authorization_contract_sha256={sh(contract)}\n'+f'authorization_script_sha256={sh(script)}\n').encode()
scope=hashlib.sha256(raw).hexdigest()
policy=write('policy.json',{
 'schema':1,'scenario':'elilo-oldkernel-cleanup-third-attempt-authorization-review','reviewed':True,'mutation_forbidden':True,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19',
 'accepted_revision_review_archive_sha256':'a'*64,'accepted_revision_review_record_sha256':sh(accepted),'accepted_source_plan_record_sha256':sh(plan),'accepted_survivor_authorization_record_sha256':sh(survivor),
 'revised_apply_script_sha256':sh(apply),'survivor_integrated_revision_contract_sha256':sh(integration),'prepared_apply_policy_sha256':sh(apply_policy),'third_attempt_authorization_contract_sha256':sh(contract),'expected_script_sha256':sh(script),'confirmation_scope_sha256':scope,
 'third_attempt_authorized':True,'cleanup_authorized':True,'apply_authorized':True,'execution_authorized':False,'apply_executed':False,'next_stage':'elilo-oldkernel-cleanup-authorized-apply-revision-2'})
(fx/'scope.txt').write_text(scope+'\n')
PY

POLICY=$FIX/policy.json
ACCEPTED=$FIX/accepted.json
PLAN=$FIX/plan.json
SURVIVOR=$FIX/survivor.json
INTEGRATION=$FIX/integration.json
APPLY_POLICY=$FIX/apply-policy.json
AUTH_CONTRACT=$FIX/auth-contract.json
EVIDENCE=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["archive_sha256"])' "$ACCEPTED")
SCOPE=$(cat "$FIX/scope.txt")

run_case(){
 local name=$1; shift
 local out=$TMP/$name
 SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TROOT" \
 ELILO_CLEANUP_THIRD_AUTH_POLICY_PATH="$POLICY" ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_REVISION_PATH="$ACCEPTED" \
 ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_PLAN_PATH="$PLAN" ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_SURVIVOR_PATH="$SURVIVOR" \
 ELILO_CLEANUP_THIRD_AUTH_REVISED_APPLY_PATH="$APPLY" ELILO_CLEANUP_THIRD_AUTH_INTEGRATION_CONTRACT_PATH="$INTEGRATION" \
 ELILO_CLEANUP_THIRD_AUTH_PREPARED_APPLY_POLICY_PATH="$APPLY_POLICY" ELILO_CLEANUP_THIRD_AUTH_CONTRACT_PATH="$AUTH_CONTRACT" \
 "$@" bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-revision-review-evidence-sha256 "$EVIDENCE" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-third-attempt-authorization-sha256 "$SCOPE" --output-dir "$out" >"$TMP/$name.log" 2>&1
}

if run_case valid env; then ok 'valid recovered boundary authorizes the third attempt'; else not_ok 'valid recovered boundary authorizes the third attempt'; fi
DESC='valid review authorizes cleanup'; check grep -q '^cleanup_authorized=true$' "$TMP/valid/summary.txt"
DESC='valid review authorizes apply'; check grep -q '^apply_authorized=true$' "$TMP/valid/summary.txt"
DESC='valid review keeps execution disabled'; check grep -q '^execution_authorized=false$' "$TMP/valid/summary.txt"
DESC='valid review keeps apply unexecuted'; check grep -q '^apply_executed=false$' "$TMP/valid/summary.txt"
DESC='valid review remains pause safe'; check grep -q '^pause_safe=true$' "$TMP/valid/summary.txt"
DESC='authorization artifact is byte-identical to reviewed contract'; check cmp -s "$TMP/valid/third-attempt-authorization.json" "$AUTH_CONTRACT"
DESC='authorization contract denies repository refresh'; check grep -q '"repository_refresh_authorized": false' "$TMP/valid/third-attempt-authorization.json"
DESC='authorization contract requires recovery snapshot'; check grep -q '"recovery_snapshot_required_before_mutation": true' "$TMP/valid/third-attempt-authorization.json"
DESC='prepared executor policy remains execution-disabled'; check grep -q '"execution_authorized": false' "$APPLY_POLICY"

if run_case wrongkernel env ELILO_CLEANUP_THIRD_AUTH_TEST_KERNEL=5.15.19; then not_ok 'wrong running kernel is rejected'; else ok 'wrong running kernel is rejected'; fi
archive=$TROOT/var/cache/packages/patches/packages/linux-5.15.209/kernel-generic-5.15.209-x86_64-1.txz
printf drift >> "$archive"
if run_case archivedrift env; then not_ok 'cached active archive drift is rejected'; else ok 'cached active archive drift is rejected'; fi
printf 'generic-archive\n' > "$archive"
old=$TROOT/lib/modules/5.15.19/misc/vboxsf.ko
printf drift >> "$old"
if run_case survivordrift env; then not_ok 'rollback survivor drift is rejected'; else ok 'rollback survivor drift is rejected'; fi
printf 'rollback-vboxsf\n' > "$old"

if SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TROOT" \
 ELILO_CLEANUP_THIRD_AUTH_POLICY_PATH="$POLICY" ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_REVISION_PATH="$ACCEPTED" \
 ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_PLAN_PATH="$PLAN" ELILO_CLEANUP_THIRD_AUTH_ACCEPTED_SURVIVOR_PATH="$SURVIVOR" \
 ELILO_CLEANUP_THIRD_AUTH_REVISED_APPLY_PATH="$APPLY" ELILO_CLEANUP_THIRD_AUTH_INTEGRATION_CONTRACT_PATH="$INTEGRATION" \
 ELILO_CLEANUP_THIRD_AUTH_PREPARED_APPLY_POLICY_PATH="$APPLY_POLICY" ELILO_CLEANUP_THIRD_AUTH_CONTRACT_PATH="$AUTH_CONTRACT" \
 bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-revision-review-evidence-sha256 "$EVIDENCE" \
 --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-third-attempt-authorization-sha256 "$(printf '00%.0s' {1..32})" --output-dir "$TMP/badscope" >/dev/null 2>&1; then
 not_ok 'incorrect authorization scope is rejected'
else ok 'incorrect authorization scope is rejected'; fi

DESC='production review contains no removepkg execution'; check bash -c '! grep -E "^[[:space:]]*(/sbin/)?removepkg([[:space:]]|$)" "$1"' _ "$SCRIPT"
DESC='production review contains no upgradepkg execution'; check bash -c '! grep -E "^[[:space:]]*(/sbin/)?upgradepkg([[:space:]]|$)" "$1"' _ "$SCRIPT"
DESC='production review contains no unlink execution'; check bash -c '! grep -E "^[[:space:]]*(/usr/bin/)?unlink([[:space:]]|$)" "$1"' _ "$SCRIPT"
DESC='production review contains no reboot/poweroff execution'; check bash -c '! grep -E "^[[:space:]]*(reboot|shutdown|poweroff)([[:space:]]|$)" "$1"' _ "$SCRIPT"

total=$((PASS+FAIL)); printf 'Result: %d checks, %d failures\n' "$total" "$FAIL"
[ "$FAIL" -eq 0 ]
