#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
SCRIPT=$ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorization-review.sh
PROD_ACCEPTED=$ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json
PASS=0
FAIL=0
ok(){ PASS=$((PASS+1)); printf 'ok %d - %s\n' "$PASS" "$1"; }
not_ok(){ FAIL=$((FAIL+1)); printf 'not ok - %s\n' "$1"; }
check(){ if "$@"; then ok "$DESC"; else not_ok "$DESC"; fi; }

TMP=$(mktemp -d /tmp/slack-update-elilo-auth-harness.XXXXXX) || exit 1
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM
TROOT=$TMP/root
mkdir -p "$TROOT/var/lib/pkgtools/packages" "$TROOT/boot/efi/EFI/Slackware" "$TROOT/boot" \
 "$TROOT/lib/modules/5.15.209/kernel" "$TROOT/lib/modules/5.15.19/kernel" \
 "$TROOT/var/cache/packages/patches/packages/linux-5.15.209"

for p in \
 kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 \
 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2 \
 kernel-firmware-20250912_f0f4634-noarch-1 kernel-headers-5.15.209-x86-1 kernel-source-5.15.209-noarch-1; do
 : > "$TROOT/var/lib/pkgtools/packages/$p"
done
printf active-module > "$TROOT/lib/modules/5.15.209/kernel/a.ko"
printf rollback-module > "$TROOT/lib/modules/5.15.19/kernel/b.ko"
printf config > "$TROOT/boot/efi/EFI/Slackware/elilo.conf"
printf active-kernel > "$TROOT/boot/vmlinuz-generic-5.15.209"
printf active-initrd > "$TROOT/boot/initrd-generic-5.15.209.gz"
printf rollback-kernel > "$TROOT/boot/vmlinuz-generic-5.15.19"
printf rollback-initrd > "$TROOT/boot/initrd.gz"
cp "$TROOT/boot/vmlinuz-generic-5.15.209" "$TROOT/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
cp "$TROOT/boot/initrd-generic-5.15.209.gz" "$TROOT/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
cp "$TROOT/boot/vmlinuz-generic-5.15.19" "$TROOT/boot/efi/EFI/Slackware/vmlinuz"
cp "$TROOT/boot/initrd.gz" "$TROOT/boot/efi/EFI/Slackware/initrd.gz"
for n in kernel-generic kernel-huge kernel-modules; do printf '%s\n' "$n archive" > "$TROOT/var/cache/packages/patches/packages/linux-5.15.209/${n}-5.15.209-x86_64-1.txz"; done

ACCEPTED=$TMP/accepted.json
POLICY=$TMP/policy.json
python3 - "$PROD_ACCEPTED" "$ACCEPTED" "$POLICY" "$SCRIPT" "$TROOT" <<'PY'
import hashlib,json,pathlib,sys
prod,accp,polp,script,root=sys.argv[1:]
a=json.load(open(prod)); root=pathlib.Path(root)
def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
# Package snapshot.
names=sorted(p.name for p in (root/'var/lib/pkgtools/packages').iterdir() if p.is_file())
pkg_text=''.join(x+'\n' for x in names); a['package_name_snapshot_sha256']=hashlib.sha256(pkg_text.encode()).hexdigest()
# Boot snapshot in production order.
active=a['active_kernel']; old=a['rollback_kernel']
paths=['/boot/efi/EFI/Slackware/elilo.conf',f'/boot/vmlinuz-generic-{active}',f'/boot/initrd-generic-{active}.gz',f'/boot/vmlinuz-generic-{old}','/boot/initrd.gz',f'/boot/efi/EFI/Slackware/vmlinuz-generic-{active}',f'/boot/efi/EFI/Slackware/initrd-generic-{active}.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=''.join(f"{sha(root/p.lstrip('/'))}  {p}\n" for p in paths)
a['boot_state_snapshot_sha256']=hashlib.sha256(rows.encode()).hexdigest()
for x in a['active_archives']:
 x['sha256']=sha(root/x['path'].lstrip('/'))
a['archive_sha256']='11'*32
a['cleanup_plan_sha256']='22'*32
pathlib.Path(accp).write_text(json.dumps(a,sort_keys=True,indent=2)+'\n')
acc_sha=sha(accp); script_sha=sha(script)
contract={k:a[k] for k in ['target','hostname_fqdn','active_kernel','rollback_kernel','cleanup_plan_sha256','active_archives','rollback_packages','active_packages','other_kernel_packages_preserved','elilo','ordered_actions','safety_invariants']}; contract['operation']='elilo-oldkernel-cleanup-authorized-apply'
contract_sha=hashlib.sha256((json.dumps(contract,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest()
scope=('operation=elilo-oldkernel-cleanup-authorization-review\n'+'target=slackware-15.0\n'+f"hostname_fqdn={a['hostname_fqdn']}\n"+f"source_plan_evidence_sha256={a['archive_sha256']}\n"+f"active_kernel={active}\nrollback_kernel={old}\n"+f"accepted_source_plan_record_sha256={acc_sha}\n"+f"authorization_script_sha256={script_sha}\n"+f"apply_contract_sha256={contract_sha}\n").encode()
p={'schema':1,'scenario':'elilo-oldkernel-cleanup-authorization-review','reviewed':True,'target':'slackware-15.0','hostname_fqdn':a['hostname_fqdn'],'active_kernel':active,'rollback_kernel':old,'accepted_source_plan_archive_sha256':a['archive_sha256'],'accepted_source_plan_record_sha256':acc_sha,'expected_script_sha256':script_sha,'apply_contract_sha256':contract_sha,'confirmation_scope_sha256':hashlib.sha256(scope).hexdigest()}
pathlib.Path(polp).write_text(json.dumps(p,sort_keys=True,indent=2)+'\n')
print(p['confirmation_scope_sha256'])
PY
SCOPE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["confirmation_scope_sha256"])' "$POLICY")
EVIDENCE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["archive_sha256"])' "$ACCEPTED")

run_case(){
 local name=$1; shift
 local out=$TMP/$name
 SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TROOT" \
 ELILO_CLEANUP_AUTH_POLICY_PATH="$POLICY" ELILO_CLEANUP_AUTH_ACCEPTED_PLAN_PATH="$ACCEPTED" \
 "$@" bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-source-plan-evidence-sha256 "$EVIDENCE" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-authorization-review-sha256 "$SCOPE" --output-dir "$out" >"$TMP/$name.log" 2>&1
}

if run_case valid env; then ok 'valid unchanged boundary is authorized'; else not_ok 'valid unchanged boundary is authorized'; fi
DESC='valid review emits cleanup_authorized=true'; check grep -q '^cleanup_authorized=true$' "$TMP/valid/summary.txt"
DESC='valid review emits apply_authorized=true'; check grep -q '^apply_authorized=true$' "$TMP/valid/summary.txt"
DESC='valid review keeps apply_executed=false'; check grep -q '^apply_executed=false$' "$TMP/valid/summary.txt"
DESC='valid authorization is exact-plan-only'; check grep -q '"authorization_scope": "exact-plan-only"' "$TMP/valid/authorization.json"
DESC='valid review preserves package snapshot'; check cmp -s "$TMP/valid/packages.before.txt" "$TMP/valid/packages.after.txt"
DESC='valid review preserves boot snapshot'; check cmp -s "$TMP/valid/boot.before.sha256" "$TMP/valid/boot.after.sha256"

if run_case wrongkernel env ELILO_CLEANUP_AUTH_TEST_RUNNING_KERNEL=5.15.19; then not_ok 'wrong running kernel is rejected'; else ok 'wrong running kernel is rejected'; fi
mv "$TROOT/var/cache/packages/patches/packages/linux-5.15.209/kernel-generic-5.15.209-x86_64-1.txz" "$TMP/missing.txz"
if run_case missing env; then not_ok 'missing active archive is rejected'; else ok 'missing active archive is rejected'; fi
mv "$TMP/missing.txz" "$TROOT/var/cache/packages/patches/packages/linux-5.15.209/kernel-generic-5.15.209-x86_64-1.txz"
printf drift >> "$TROOT/boot/efi/EFI/Slackware/elilo.conf"
if run_case drift env; then not_ok 'ELILO drift is rejected'; else ok 'ELILO drift is rejected'; fi
printf config > "$TROOT/boot/efi/EFI/Slackware/elilo.conf"

if SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TROOT" ELILO_CLEANUP_AUTH_POLICY_PATH="$POLICY" ELILO_CLEANUP_AUTH_ACCEPTED_PLAN_PATH="$ACCEPTED" \
 bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-source-plan-evidence-sha256 "$EVIDENCE" \
 --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-authorization-review-sha256 "$(printf '00%.0s' {1..32})" --output-dir "$TMP/badscope" >/dev/null 2>&1; then
 not_ok 'incorrect confirmation scope is rejected'
else ok 'incorrect confirmation scope is rejected'; fi

DESC='production script contains no removepkg execution'; check bash -c '! grep -E "^[[:space:]]*(/sbin/)?removepkg[[:space:]]" "$1"' _ "$SCRIPT"
DESC='production script contains no upgradepkg execution'; check bash -c '! grep -E "^[[:space:]]*(/sbin/)?upgradepkg[[:space:]]" "$1"' _ "$SCRIPT"
DESC='production script contains no slackpkg refresh'; check bash -c '! grep -E "^[[:space:]]*slackpkg[[:space:]]+update" "$1"' _ "$SCRIPT"
DESC='production script contains no reboot execution'; check bash -c '! grep -E "^[[:space:]]*(reboot|shutdown|poweroff)([[:space:]]|$)" "$1"' _ "$SCRIPT"

total=$((PASS+FAIL)); printf 'Result: %d checks, %d failures\n' "$total" "$FAIL"
[ "$FAIL" -eq 0 ]
