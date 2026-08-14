#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd -P)
SCRIPT=$ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review.sh
PROD_ACCEPTED=$ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-revision-review-20260814-accepted.json
PASS=0
FAIL=0
ok(){ PASS=$((PASS+1)); printf 'ok %d - %s\n' "$PASS" "$1"; }
not_ok(){ FAIL=$((FAIL+1)); printf 'not ok - %s\n' "$1"; }
check(){ if "$@"; then ok "$DESC"; else not_ok "$DESC"; fi; }

TMP=$(mktemp -d /tmp/slack-update-survivor-auth.XXXXXX) || exit 1
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM
TROOT=$TMP/root
mkdir -p "$TROOT/var/lib/pkgtools/packages" "$TROOT/boot/efi/EFI/Slackware" "$TROOT/boot" \
 "$TROOT/lib/modules/5.15.209/misc" "$TROOT/lib/modules/5.15.19/misc"

for p in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 \
 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2; do
 printf 'PACKAGE NAME:  %s\nFILE LIST:\nboot/placeholder\n' "$p" > "$TROOT/var/lib/pkgtools/packages/$p"
done
printf config > "$TROOT/boot/efi/EFI/Slackware/elilo.conf"
printf active-kernel > "$TROOT/boot/vmlinuz-generic-5.15.209"
printf active-initrd > "$TROOT/boot/initrd-generic-5.15.209.gz"
printf rollback-kernel > "$TROOT/boot/vmlinuz-generic-5.15.19"
printf rollback-initrd > "$TROOT/boot/initrd.gz"
cp "$TROOT/boot/vmlinuz-generic-5.15.209" "$TROOT/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
cp "$TROOT/boot/initrd-generic-5.15.209.gz" "$TROOT/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
cp "$TROOT/boot/vmlinuz-generic-5.15.19" "$TROOT/boot/efi/EFI/Slackware/vmlinuz"
cp "$TROOT/boot/initrd.gz" "$TROOT/boot/efi/EFI/Slackware/initrd.gz"
for n in vboxguest vboxsf vboxvideo; do printf 'old-%s' "$n" > "$TROOT/lib/modules/5.15.19/misc/$n.ko"; printf 'active-%s' "$n" > "$TROOT/lib/modules/5.15.209/misc/$n.ko"; done

MODINFO=$TMP/modinfo
cat > "$MODINFO" <<'EOF_MODINFO'
#!/bin/bash
set -eu
if [ "$1" = -n ]; then printf '/lib/modules/5.15.209/misc/%s.ko\n' "$2"; exit 0; fi
[ "$1" = -F ] || exit 1
field=$2; path=$3; base=${path##*/}; name=${base%.ko}
case "$field" in
 name) printf '%s\n' "$name";;
 vermagic) case "$path" in */5.15.19/*) printf '5.15.19 SMP preempt mod_unload\n';; */5.15.209/*) printf '5.15.209 SMP preempt mod_unload\n';; *) exit 1;; esac;;
 *) exit 1;;
esac
EOF_MODINFO
chmod +x "$MODINFO"

ACCEPTED=$TMP/accepted.json
POLICY=$TMP/policy.json
python3 - "$PROD_ACCEPTED" "$ACCEPTED" "$POLICY" "$SCRIPT" "$TROOT" <<'PY'
import hashlib,json,pathlib,sys
prod,accp,polp,script,root=sys.argv[1:]; root=pathlib.Path(root); a=json.load(open(prod))
def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def manifest(version):
 d=root/f'lib/modules/{version}'; rows=[]
 for p in sorted(x for x in d.rglob('*') if x.is_file()): rows.append(f"{sha(p)}  ./{p.relative_to(d)}\n")
 return ''.join(rows)
active='5.15.209'; old='5.15.19'
paths=['/boot/efi/EFI/Slackware/elilo.conf',f'/boot/vmlinuz-generic-{active}',f'/boot/initrd-generic-{active}.gz',f'/boot/vmlinuz-generic-{old}','/boot/initrd.gz',f'/boot/efi/EFI/Slackware/vmlinuz-generic-{active}',f'/boot/efi/EFI/Slackware/initrd-generic-{active}.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
boot=''.join(f"{sha(root/p.lstrip('/'))}  {p}\n" for p in paths)
names=''.join(x.name+'\n' for x in sorted((root/'var/lib/pkgtools/packages').iterdir()))
items=[]
for n in ['vboxguest','vboxsf','vboxvideo']:
 oldp=f'/lib/modules/{old}/misc/{n}.ko'; actp=f'/lib/modules/{active}/misc/{n}.ko'
 items.append({'rollback_path':oldp,'module_name':n,'rollback_sha256':sha(root/oldp.lstrip('/')),'rollback_vermagic':f'{old} SMP preempt mod_unload','installed_package_owners':[],'active_counterpart_path':actp,'active_counterpart_sha256':sha(root/actp.lstrip('/')),'active_counterpart_vermagic':f'{active} SMP preempt mod_unload'})
base={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-removal-contract','reviewed':True,'active_kernel':active,'rollback_kernel':old,'survivor_count':3,'survivors':items,'removal_method':'unlink-exact-reviewed-paths-after-rollback-package-removal-before-final-verification','recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,'deletion_authorized':False,'third_attempt_authorized':False}
a.update({'archive_sha256':'11'*32,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':active,'rollback_kernel':old,'survivor_removal_contract':base,'survivor_removal_contract_sha256':hashlib.sha256((json.dumps(base,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest(),'package_snapshot_sha256':hashlib.sha256(names.encode()).hexdigest(),'boot_manifest_sha256':hashlib.sha256(boot.encode()).hexdigest(),'active_module_manifest_sha256':hashlib.sha256(manifest(active).encode()).hexdigest(),'rollback_module_manifest_sha256':hashlib.sha256(manifest(old).encode()).hexdigest()})
pathlib.Path(accp).write_text(json.dumps(a,sort_keys=True,indent=2)+'\n')
acc_sha=sha(accp); script_sha=sha(script)
auth={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-deletion-authorization-contract','reviewed_survivor_contract_sha256':a['survivor_removal_contract_sha256'],'active_kernel':active,'rollback_kernel':old,'survivor_count':3,'survivors':items,'removal_method':base['removal_method'],'survivor_deletion_authorized':True,'recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,'third_attempt_authorized':False,'execution_authorized':False}
auth_sha=hashlib.sha256((json.dumps(auth,sort_keys=True,separators=(',',':'))+'\n').encode()).hexdigest()
scope=('operation=elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review\n'+'target=slackware-15.0\n'+f"hostname_fqdn={a['hostname_fqdn']}\n"+f"survivor_review_evidence_sha256={a['archive_sha256']}\n"+f'active_kernel={active}\nrollback_kernel={old}\n'+f'accepted_survivor_review_record_sha256={acc_sha}\n'+f'authorization_script_sha256={script_sha}\n'+f'survivor_deletion_authorization_contract_sha256={auth_sha}\n').encode()
p={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review','reviewed':True,'target':'slackware-15.0','hostname_fqdn':a['hostname_fqdn'],'active_kernel':active,'rollback_kernel':old,'accepted_survivor_review_archive_sha256':a['archive_sha256'],'accepted_survivor_review_record_sha256':acc_sha,'expected_script_sha256':script_sha,'survivor_deletion_authorization_contract_sha256':auth_sha,'confirmation_scope_sha256':hashlib.sha256(scope).hexdigest()}
pathlib.Path(polp).write_text(json.dumps(p,sort_keys=True,indent=2)+'\n')
PY
SCOPE=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["confirmation_scope_sha256"])' "$POLICY")
EVIDENCE=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["archive_sha256"])' "$ACCEPTED")

run_case(){
 local name=$1; shift
 local out=$TMP/$name
 SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TROOT" ELILO_CLEANUP_SURVIVOR_AUTH_MODINFO="$MODINFO" \
 ELILO_CLEANUP_SURVIVOR_AUTH_POLICY_PATH="$POLICY" ELILO_CLEANUP_SURVIVOR_AUTH_ACCEPTED_PATH="$ACCEPTED" \
 "$@" bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-survivor-review-evidence-sha256 "$EVIDENCE" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-survivor-authorization-sha256 "$SCOPE" --output-dir "$out" >"$TMP/$name.log" 2>&1
}

if run_case valid env; then ok 'valid exact survivor scope is authorized'; else not_ok 'valid exact survivor scope is authorized'; fi
DESC='valid review authorizes survivor deletion'; check grep -q '^survivor_deletion_authorized=true$' "$TMP/valid/summary.txt"
DESC='valid review denies recursive removal'; check grep -q '^recursive_module_tree_removal_authorized=false$' "$TMP/valid/summary.txt"
DESC='valid review denies active counterpart removal'; check grep -q '^active_counterpart_removal_authorized=false$' "$TMP/valid/summary.txt"
DESC='valid review denies third cleanup attempt'; check grep -q '^third_attempt_authorized=false$' "$TMP/valid/summary.txt"
DESC='valid review keeps cleanup unauthorized'; check grep -q '^cleanup_authorized=false$' "$TMP/valid/summary.txt"
DESC='valid review keeps apply unauthorized'; check grep -q '^apply_authorized=false$' "$TMP/valid/summary.txt"
DESC='valid review keeps apply unexecuted'; check grep -q '^apply_executed=false$' "$TMP/valid/summary.txt"
DESC='valid review remains pause safe'; check grep -q '^pause_safe=true$' "$TMP/valid/summary.txt"
DESC='authorization contract denies execution'; check grep -q '"execution_authorized": false' "$TMP/valid/survivor-deletion-authorization.json"
DESC='authorization contract contains exactly three survivors'; check bash -c '[ "$(python3 -c '\''import json,sys;print(json.load(open(sys.argv[1]))["survivor_count"])'\'' "$1")" = 3 ]' _ "$TMP/valid/survivor-deletion-authorization.json"

if run_case wrongkernel env ELILO_CLEANUP_SURVIVOR_AUTH_TEST_KERNEL=5.15.19; then not_ok 'wrong running kernel is rejected'; else ok 'wrong running kernel is rejected'; fi
printf drift >> "$TROOT/lib/modules/5.15.19/misc/vboxsf.ko"
if run_case rollbackdrift env; then not_ok 'rollback survivor hash drift is rejected'; else ok 'rollback survivor hash drift is rejected'; fi
printf 'old-vboxsf' > "$TROOT/lib/modules/5.15.19/misc/vboxsf.ko"
printf 'PACKAGE NAME: owner\nFILE LIST:\nlib/modules/5.15.19/misc/vboxguest.ko\n' > "$TROOT/var/lib/pkgtools/packages/owner-1-x86_64-1"
if run_case owner env; then not_ok 'new package ownership claim is rejected'; else ok 'new package ownership claim is rejected'; fi
rm -f "$TROOT/var/lib/pkgtools/packages/owner-1-x86_64-1"

if SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TROOT" ELILO_CLEANUP_SURVIVOR_AUTH_MODINFO="$MODINFO" ELILO_CLEANUP_SURVIVOR_AUTH_POLICY_PATH="$POLICY" ELILO_CLEANUP_SURVIVOR_AUTH_ACCEPTED_PATH="$ACCEPTED" \
 bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-survivor-review-evidence-sha256 "$EVIDENCE" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-survivor-authorization-sha256 "$(printf '00%.0s' {1..32})" --output-dir "$TMP/badscope" >/dev/null 2>&1; then
 not_ok 'incorrect authorization scope is rejected'
else ok 'incorrect authorization scope is rejected'; fi

DESC='production review contains no rm execution'; check bash -c '! grep -E "^[[:space:]]*rm([[:space:]]|$)" "$1"' _ "$SCRIPT"
DESC='production review contains no removepkg execution'; check bash -c '! grep -E "^[[:space:]]*(/sbin/)?removepkg([[:space:]]|$)" "$1"' _ "$SCRIPT"
DESC='production review contains no upgradepkg execution'; check bash -c '! grep -E "^[[:space:]]*(/sbin/)?upgradepkg([[:space:]]|$)" "$1"' _ "$SCRIPT"
DESC='production review contains no reboot execution'; check bash -c '! grep -E "^[[:space:]]*(reboot|shutdown|poweroff)([[:space:]]|$)" "$1"' _ "$SCRIPT"

total=$((PASS+FAIL)); printf 'Result: %d checks, %d failures\n' "$total" "$FAIL"
[ "$FAIL" -eq 0 ]
