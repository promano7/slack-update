#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL
REPO=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); if "$@"; then :; else printf 'FAIL: %s\n' "$*" >&2; FAILS=$((FAILS+1)); fi; }
eq(){ COUNT=$((COUNT+1)); if [ "$1" = "$2" ]; then :; else printf 'FAIL: expected <%s> got <%s> -- %s\n' "$1" "$2" "$3" >&2; FAILS=$((FAILS+1)); fi; }
contains(){ COUNT=$((COUNT+1)); grep -Fq -- "$1" "$2" || { printf 'FAIL: missing <%s> in %s\n' "$1" "$2" >&2; FAILS=$((FAILS+1)); }; }

make_case(){
 local c=$1
 local root=$TMP/$c/root meta=$TMP/$c/meta
 rm -rf "$TMP/$c"; mkdir -p "$root/boot/efi/EFI/Slackware" "$root/lib/modules/5.15.209/kernel" "$root/lib/modules/5.15.19/kernel" "$root/var/lib/pkgtools/packages" "$root/var/lib/pkgtools/scripts" "$root/var/lib/pkgtools/removed_packages" "$root/var/lib/pkgtools/removed_scripts" "$root/var/cache/packages/linux" "$meta" "$TMP/$c/bin"
 printf active-kernel > "$root/boot/vmlinuz-generic-5.15.209"
 printf active-huge > "$root/boot/vmlinuz-huge-5.15.209"
 printf active-initrd > "$root/boot/initrd-generic-5.15.209.gz"
 printf rollback-kernel > "$root/boot/vmlinuz-generic-5.15.19"
 printf rollback-huge > "$root/boot/vmlinuz-huge-5.15.19"
 printf rollback-initrd > "$root/boot/initrd.gz"
 cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
 cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
 cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"
 cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
 cat > "$root/boot/efi/EFI/Slackware/elilo.conf" <<'EOC'
default=vmlinuz
image=vmlinuz-generic-5.15.209
  label=vmlinuz
  initrd=initrd-generic-5.15.209.gz
  root=/dev/sda2
  read-only
image=vmlinuz
  label=oldkernel
  initrd=initrd.gz
  root=/dev/sda2
  read-only
EOC
 printf module-active > "$root/lib/modules/5.15.209/kernel/a.ko"
 printf module-old > "$root/lib/modules/5.15.19/kernel/o.ko"
 local records=(kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2 kernel-headers-5.15.209-x86-1 kernel-source-5.15.209-noarch-1 kernel-firmware-20250912_f0f4634-noarch-1)
 local r; for r in "${records[@]}"; do : > "$root/var/lib/pkgtools/packages/$r"; done
 printf ag > "$root/var/cache/packages/linux/kernel-generic-5.15.209-x86_64-1.txz"
 printf ah > "$root/var/cache/packages/linux/kernel-huge-5.15.209-x86_64-1.txz"
 printf am > "$root/var/cache/packages/linux/kernel-modules-5.15.209-x86_64-1.txz"
 ROOT="$root" META="$meta" SCRIPT="$SCRIPT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META']); script=pathlib.Path(os.environ['SCRIPT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
names=''.join(x.name+'\n' for x in sorted((root/'var/lib/pkgtools/packages').iterdir()))
pkgsha=hashlib.sha256(names.encode()).hexdigest()
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths); bootsha=hashlib.sha256(rows.encode()).hexdigest()
archives=[]
for rec in ['kernel-generic-5.15.209-x86_64-1','kernel-huge-5.15.209-x86_64-1','kernel-modules-5.15.209-x86_64-1']:
 p='/var/cache/packages/linux/'+rec+'.txz'; archives.append({'record':rec,'path':p,'sha256':sh(root/p.lstrip('/'))})
plan={'accepted':True,'archive_sha256':'b'*64,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','cleanup_plan_sha256':'c'*64,'package_name_snapshot_sha256':pkgsha,'boot_state_snapshot_sha256':bootsha,
'active_archives':archives,'rollback_packages':['kernel-generic-5.15.19-x86_64-2','kernel-huge-5.15.19-x86_64-2','kernel-modules-5.15.19-x86_64-2'],'active_packages':['kernel-generic-5.15.209-x86_64-1','kernel-huge-5.15.209-x86_64-1','kernel-modules-5.15.209-x86_64-1'],'other_kernel_packages_preserved':['kernel-firmware-20250912_f0f4634-noarch-1','kernel-headers-5.15.209-x86-1','kernel-source-5.15.209-noarch-1'],
'elilo':{'active_kernel_sha256':sh(root/'boot/vmlinuz-generic-5.15.209'),'active_initrd_sha256':sh(root/'boot/initrd-generic-5.15.209.gz')}}
(meta/'plan.json').write_text(json.dumps(plan,sort_keys=True,indent=2)+'\n')
contract='d'*64; evidence='e'*64
auth={'status':'accepted-authorization-review','archive_sha256':evidence,'cleanup_authorized':True,'apply_authorized':True,'apply_executed':False,'hostname_fqdn':plan['hostname_fqdn'],'active_kernel':plan['active_kernel'],'rollback_kernel':plan['rollback_kernel'],'apply_contract_sha256':contract,'cleanup_plan_sha256':plan['cleanup_plan_sha256']}
(meta/'auth.json').write_text(json.dumps(auth,sort_keys=True,indent=2)+'\n')
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
scope=('operation=elilo-oldkernel-cleanup-authorized-apply\n'+'target=slackware-15.0\n'+f"hostname_fqdn={plan['hostname_fqdn']}\n"+f'authorization_evidence_sha256={evidence}\n'+f"active_kernel={plan['active_kernel']}\n"+f"rollback_kernel={plan['rollback_kernel']}\n"+f'apply_contract_sha256={contract}\n'+f"accepted_authorization_record_sha256={fh(meta/'auth.json')}\n"+f"authorized_apply_script_sha256={fh(script)}\n").encode()
pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-authorized-apply','reviewed':True,'expected_script_sha256':fh(script),'accepted_authorization_record_sha256':fh(meta/'auth.json'),'accepted_source_plan_record_sha256':fh(meta/'plan.json'),'accepted_authorization_archive_sha256':evidence,'apply_contract_sha256':contract,'confirmation_scope_sha256':hashlib.sha256(scope).hexdigest()}
(meta/'policy.json').write_text(json.dumps(pol,sort_keys=True,indent=2)+'\n')
(meta/'args').write_text(evidence+'\n'+contract+'\n'+pol['confirmation_scope_sha256']+'\n')
PY
 cat > "$TMP/$c/bin/removepkg" <<'EOS'
#!/bin/bash
set -eu
rec=$1; root=${SLACK_UPDATE_TEST_ROOT:?}; rm -f "$root/var/lib/pkgtools/packages/$rec"
case "$rec" in kernel-generic-5.15.19-*) rm -f "$root/boot/vmlinuz-generic-5.15.19";; kernel-huge-5.15.19-*) rm -f "$root/boot/vmlinuz-huge-5.15.19";; kernel-modules-5.15.19-*) rm -rf "$root/lib/modules/5.15.19";; esac
EOS
 cat > "$TMP/$c/bin/upgradepkg" <<'EOS'
#!/bin/bash
set -eu
[ "$1" = --reinstall ]; root=${SLACK_UPDATE_TEST_ROOT:?}; base=${2##*/}; rec=${base%.txz}; : > "$root/var/lib/pkgtools/packages/$rec"
EOS
 chmod +x "$TMP/$c/bin/removepkg" "$TMP/$c/bin/upgradepkg"
}

run_case(){
 local c=$1 failat=${2:-}
 local root=$TMP/$c/root meta=$TMP/$c/meta out=$TMP/$c/output evidence contract scope
 readarray -t vals < "$meta/args"; evidence=${vals[0]}; contract=${vals[1]}; scope=${vals[2]}
 SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$root" ELILO_CLEANUP_TEST_HOSTNAME_FQDN=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_TEST_RUNNING_KERNEL=5.15.209 \
 ELILO_CLEANUP_REMOVEPKG="$TMP/$c/bin/removepkg" ELILO_CLEANUP_UPGRADEPKG="$TMP/$c/bin/upgradepkg" ELILO_CLEANUP_FAIL_AT="$failat" \
 ELILO_CLEANUP_APPLY_POLICY_PATH="$meta/policy.json" ELILO_CLEANUP_ACCEPTED_AUTH_PATH="$meta/auth.json" ELILO_CLEANUP_ACCEPTED_PLAN_PATH="$meta/plan.json" \
 bash "$SCRIPT" --target slackware-15.0 --execute-authorized-cleanup --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-authorization-evidence-sha256 "$evidence" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-apply-contract-sha256 "$contract" --confirm-apply-scope-sha256 "$scope" --output-dir "$out" > "$TMP/$c/run.log" 2>&1
}

make_case success
ok run_case success
contains 'apply_committed=true' "$TMP/success/output/summary.txt"
contains 'pause_safe=true' "$TMP/success/output/summary.txt"
contains 'recovery_backup_retained=true' "$TMP/success/output/summary.txt"
contains 'reboot_required=true' "$TMP/success/output/summary.txt"
ok bash -c 'd=$(sed -n "s/^recovery_backup_path=//p" "$1"); cd "$d" && sha256sum -c archive.sha256 >/dev/null' bash "$TMP/success/output/summary.txt"
ok test ! -e "$TMP/success/root/var/lib/pkgtools/packages/kernel-generic-5.15.19-x86_64-2"
ok test -f "$TMP/success/root/var/lib/pkgtools/packages/kernel-generic-5.15.209-x86_64-1"
ok test ! -e "$TMP/success/root/boot/efi/EFI/Slackware/vmlinuz"
ok test ! -e "$TMP/success/root/boot/efi/EFI/Slackware/initrd.gz"
ok test -f "$TMP/success/root/boot/initrd.gz"
ok grep -q '^  label=vmlinuz$' "$TMP/success/root/boot/efi/EFI/Slackware/elilo.conf"
ok bash -c '! grep -q oldkernel "$1"' bash "$TMP/success/root/boot/efi/EFI/Slackware/elilo.conf"


make_case recover_remove
if run_case recover_remove remove_exact_rollback_package_records; then FAILS=$((FAILS+1)); fi; COUNT=$((COUNT+1))
contains 'recovery_restored=true' "$TMP/recover_remove/output/summary.txt"
contains 'pause_safe=true' "$TMP/recover_remove/output/summary.txt"
ok test -f "$TMP/recover_remove/root/var/lib/pkgtools/packages/kernel-generic-5.15.19-x86_64-2"
ok grep -q oldkernel "$TMP/recover_remove/root/boot/efi/EFI/Slackware/elilo.conf"

make_case recover_config
if run_case recover_config atomically_activate_elilo_config; then FAILS=$((FAILS+1)); fi; COUNT=$((COUNT+1))
contains 'recovery_restored=true' "$TMP/recover_config/output/summary.txt"
contains 'pause_safe=true' "$TMP/recover_config/output/summary.txt"
ok test -f "$TMP/recover_config/root/var/lib/pkgtools/packages/kernel-generic-5.15.19-x86_64-2"
ok test -f "$TMP/recover_config/root/boot/efi/EFI/Slackware/vmlinuz"
ok grep -q oldkernel "$TMP/recover_config/root/boot/efi/EFI/Slackware/elilo.conf"
ok test -f "$TMP/recover_config/root/lib/modules/5.15.19/kernel/o.ko"

make_case recover_after_delete
if run_case recover_after_delete capture_and_compare_final_state; then FAILS=$((FAILS+1)); fi; COUNT=$((COUNT+1))
contains 'recovery_restored=true' "$TMP/recover_after_delete/output/summary.txt"
contains 'pause_safe=true' "$TMP/recover_after_delete/output/summary.txt"
ok test -f "$TMP/recover_after_delete/root/boot/efi/EFI/Slackware/vmlinuz"
ok test -f "$TMP/recover_after_delete/root/boot/efi/EFI/Slackware/initrd.gz"
ok grep -q oldkernel "$TMP/recover_after_delete/root/boot/efi/EFI/Slackware/elilo.conf"

ok bash -n "$SCRIPT"
contains '/sbin/removepkg' "$SCRIPT"
contains '/sbin/upgradepkg' "$SCRIPT"
printf 'ELILO oldkernel cleanup authorized apply harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
