#!/bin/bash
set -uo pipefail
IFS=$'\n\t'; LC_ALL=C; export LC_ALL
REPO=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); "$@" || { printf 'FAIL: %s\n' "$*" >&2; FAILS=$((FAILS+1)); }; }
contains(){ COUNT=$((COUNT+1)); grep -Fq -- "$1" "$2" || { printf 'FAIL: missing <%s> in %s\n' "$1" "$2" >&2; FAILS=$((FAILS+1)); }; }
make_case(){
 local c=$1 root=$TMP/$1/root meta=$TMP/$1/meta f
 mkdir -p "$root/boot/efi/EFI/Slackware" "$root/lib/modules/5.15.209/kernel" "$root/lib/modules/5.15.19/kernel" "$root/var/lib/pkgtools/packages" "$root/var/cache/packages/linux" "$meta" "$TMP/$c/bin"
 printf active-kernel > "$root/boot/vmlinuz-generic-5.15.209"; printf active-initrd > "$root/boot/initrd-generic-5.15.209.gz"; printf old-kernel > "$root/boot/vmlinuz-generic-5.15.19"; printf old-initrd > "$root/boot/initrd.gz"
 cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"; cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"; cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"; cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
 cat > "$root/boot/efi/EFI/Slackware/elilo.conf" <<'EOC'
default=vmlinuz
image=vmlinuz-generic-5.15.209
  label=vmlinuz
  initrd=initrd-generic-5.15.209.gz
image=vmlinuz
  label=oldkernel
  initrd=initrd.gz
EOC
 printf module-active > "$root/lib/modules/5.15.209/kernel/a.ko"; printf module-old > "$root/lib/modules/5.15.19/kernel/o.ko"
 for f in modules.alias modules.alias.bin modules.dep modules.dep.bin modules.symbols modules.symbols.bin; do printf 'before-%s' "$f" > "$root/lib/modules/5.15.209/$f"; done
 for f in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2 kernel-headers-5.15.209-x86-1 kernel-source-5.15.209-noarch-1 kernel-firmware-20250912_f0f4634-noarch-1; do : > "$root/var/lib/pkgtools/packages/$f"; done
 for f in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1; do printf "$f" > "$root/var/cache/packages/linux/$f.txz"; done
 ROOT="$root" META="$meta" SCRIPT="$SCRIPT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META']); script=pathlib.Path(os.environ['SCRIPT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
names=''.join(x.name+'\n' for x in sorted((root/'var/lib/pkgtools/packages').iterdir())); pkgsha=hashlib.sha256(names.encode()).hexdigest()
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths); bootsha=hashlib.sha256(rows.encode()).hexdigest()
archives=[]
for rec in ['kernel-generic-5.15.209-x86_64-1','kernel-huge-5.15.209-x86_64-1','kernel-modules-5.15.209-x86_64-1']:
 p='/var/cache/packages/linux/'+rec+'.txz'; archives.append({'record':rec,'path':p,'sha256':sh(root/p.lstrip('/'))})
plan={'accepted':True,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','cleanup_plan_sha256':'c'*64,'package_name_snapshot_sha256':pkgsha,'boot_state_snapshot_sha256':bootsha,'active_archives':archives,'rollback_packages':['kernel-generic-5.15.19-x86_64-2','kernel-huge-5.15.19-x86_64-2','kernel-modules-5.15.19-x86_64-2'],'active_packages':['kernel-generic-5.15.209-x86_64-1','kernel-huge-5.15.209-x86_64-1','kernel-modules-5.15.209-x86_64-1'],'other_kernel_packages_preserved':['kernel-firmware-20250912_f0f4634-noarch-1','kernel-headers-5.15.209-x86-1','kernel-source-5.15.209-noarch-1'],'elilo':{'active_kernel_sha256':sh(root/'boot/vmlinuz-generic-5.15.209'),'active_initrd_sha256':sh(root/'boot/initrd-generic-5.15.209.gz')}}
(meta/'plan.json').write_text(json.dumps(plan,sort_keys=True))
contract='d'*64; evidence='e'*64; rev_evidence='f'*64
auth={'status':'accepted-authorization-review','archive_sha256':evidence,'cleanup_authorized':True,'apply_authorized':True,'apply_executed':False,'hostname_fqdn':plan['hostname_fqdn'],'active_kernel':'5.15.209','rollback_kernel':'5.15.19','apply_contract_sha256':contract,'cleanup_plan_sha256':plan['cleanup_plan_sha256']}; (meta/'auth.json').write_text(json.dumps(auth,sort_keys=True))
rev={'status':'accepted-apply-revision-review','archive_sha256':rev_evidence,'retry_authorized':True,'apply_executed':False,'hostname_fqdn':plan['hostname_fqdn'],'active_kernel':'5.15.209','rollback_kernel':'5.15.19','base_apply_contract_sha256':contract,'revised_apply_script_sha256':sh(script)}; (meta/'revision.json').write_text(json.dumps(rev,sort_keys=True))
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
scope=('operation=elilo-oldkernel-cleanup-authorized-apply-revision-1\n'+'target=slackware-15.0\n'+f"hostname_fqdn={plan['hostname_fqdn']}\n"+f'authorization_evidence_sha256={evidence}\n'+f'revision_evidence_sha256={rev_evidence}\n'+'active_kernel=5.15.209\nrollback_kernel=5.15.19\n'+f'apply_contract_sha256={contract}\n'+f"accepted_authorization_record_sha256={fh(meta/'auth.json')}\n"+f"accepted_revision_record_sha256={fh(meta/'revision.json')}\n"+f'authorized_apply_script_sha256={fh(script)}\n').encode()
pol={'schema':2,'scenario':'elilo-oldkernel-cleanup-authorized-apply-revision-1','reviewed':True,'expected_script_sha256':fh(script),'accepted_authorization_record_sha256':fh(meta/'auth.json'),'accepted_source_plan_record_sha256':fh(meta/'plan.json'),'accepted_revision_record_sha256':fh(meta/'revision.json'),'accepted_authorization_archive_sha256':evidence,'accepted_revision_archive_sha256':rev_evidence,'apply_contract_sha256':contract,'confirmation_scope_sha256':hashlib.sha256(scope).hexdigest()}; (meta/'policy.json').write_text(json.dumps(pol,sort_keys=True)); (meta/'args').write_text('\n'.join([evidence,rev_evidence,contract,pol['confirmation_scope_sha256']])+'\n')
PY
 cat > "$TMP/$c/bin/removepkg" <<'EOS'
#!/bin/bash
set -eu; root=${SLACK_UPDATE_TEST_ROOT:?}; rec=$1; rm -f "$root/var/lib/pkgtools/packages/$rec"; case "$rec" in kernel-generic-5.15.19-*) rm -f "$root/boot/vmlinuz-generic-5.15.19";; kernel-modules-5.15.19-*) rm -rf "$root/lib/modules/5.15.19";; esac
EOS
 cat > "$TMP/$c/bin/upgradepkg" <<'EOS'
#!/bin/bash
set -eu; root=${SLACK_UPDATE_TEST_ROOT:?}; rec=${2##*/}; rec=${rec%.txz}; : > "$root/var/lib/pkgtools/packages/$rec"; if [[ $rec == kernel-modules-* ]]; then for f in modules.alias modules.alias.bin modules.dep modules.dep.bin modules.symbols modules.symbols.bin; do printf 'regenerated-%s' "$f" > "$root/lib/modules/5.15.209/$f"; done; if [ "${MUTATE_KO:-0}" = 1 ]; then printf changed > "$root/lib/modules/5.15.209/kernel/a.ko"; fi; fi
EOS
 cat > "$TMP/$c/bin/depmod" <<'EOS'
#!/bin/bash
exit 0
EOS
 chmod +x "$TMP/$c/bin/"*
}
run_case(){ local c=$1 mutate=${2:-0} root=$TMP/$1/root meta=$TMP/$1/meta out=$TMP/$1/out; readarray -t v < "$meta/args"; SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$root" ELILO_CLEANUP_TEST_HOSTNAME_FQDN=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_TEST_RUNNING_KERNEL=5.15.209 MUTATE_KO=$mutate ELILO_CLEANUP_REMOVEPKG="$TMP/$c/bin/removepkg" ELILO_CLEANUP_UPGRADEPKG="$TMP/$c/bin/upgradepkg" ELILO_CLEANUP_DEPMOD="$TMP/$c/bin/depmod" ELILO_CLEANUP_APPLY_POLICY_PATH="$meta/policy.json" ELILO_CLEANUP_ACCEPTED_AUTH_PATH="$meta/auth.json" ELILO_CLEANUP_ACCEPTED_PLAN_PATH="$meta/plan.json" ELILO_CLEANUP_ACCEPTED_REVISION_PATH="$meta/revision.json" bash "$SCRIPT" --target slackware-15.0 --execute-authorized-cleanup --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-authorization-evidence-sha256 "${v[0]}" --confirm-revision-evidence-sha256 "${v[1]}" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-apply-contract-sha256 "${v[2]}" --confirm-apply-scope-sha256 "${v[3]}" --output-dir "$out" > "$TMP/$c/run.log" 2>&1; }
make_case success; ok run_case success 0; contains 'apply_committed=true' "$TMP/success/out/summary.txt"; contains 'recovery_attempted=false' "$TMP/success/out/summary.txt"; ok cmp -s "$TMP/success/out/modules-active-objects.before.sha256" "$TMP/success/out/modules-active-objects.after.sha256"; ok cmp -s "$TMP/success/out/modules-active-stable.before.sha256" "$TMP/success/out/modules-active-stable.after.sha256"; ok bash -c '! cmp -s "$1" "$2"' bash "$TMP/success/out/modules-active.before.sha256" "$TMP/success/out/modules-active.after.sha256"
make_case mutate; if run_case mutate 1; then FAILS=$((FAILS+1)); fi; COUNT=$((COUNT+1)); contains 'recovery_restored=true' "$TMP/mutate/out/summary.txt"; contains 'pause_safe=true' "$TMP/mutate/out/summary.txt"; ok test -f "$TMP/mutate/root/lib/modules/5.15.19/kernel/o.ko"
ok bash -n "$SCRIPT"; contains 'modules.alias.bin' "$SCRIPT"; contains 'module_stable_manifest' "$SCRIPT"; contains 'module_object_manifest' "$SCRIPT"; contains '"$DEPMOD" -n' "$SCRIPT"
printf 'ELILO oldkernel cleanup revised authorized apply harness: %d checks, %d failures\n' "$COUNT" "$FAILS"; [ "$FAILS" -eq 0 ]
