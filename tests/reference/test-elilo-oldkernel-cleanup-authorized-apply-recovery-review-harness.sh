#!/bin/bash
set -u
export LC_ALL=C
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply-recovery-review.sh
TMP=$(mktemp -d /tmp/elilo-cleanup-recovery-review.XXXXXX) || exit 1
trap 'rm -rf -- "$TMP"' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); if "$@"; then :; else echo "not ok $COUNT: $*"; FAILS=$((FAILS+1)); fi; }
contains(){ COUNT=$((COUNT+1)); if grep -Fq -- "$1" "$2"; then :; else echo "not ok $COUNT: missing $1"; FAILS=$((FAILS+1)); fi; }
make_case(){
 local c=$1
 local root=$TMP/$c/root meta=$TMP/$c/meta recovery
 mkdir -p "$root/boot/efi/EFI/Slackware" "$root/boot" "$root/lib/modules/5.15.209/kernel" "$root/lib/modules/5.15.19/kernel" "$root/var/lib/pkgtools/packages" "$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test" "$meta"
 cat > "$root/boot/efi/EFI/Slackware/elilo.conf" <<'EOF'
default=vmlinuz
image=vmlinuz-generic-5.15.209
  label=vmlinuz
  initrd=initrd-generic-5.15.209.gz
image=vmlinuz
  label=oldkernel
  initrd=initrd.gz
EOF
 printf active > "$root/boot/vmlinuz-generic-5.15.209"
 printf initrd > "$root/boot/initrd-generic-5.15.209.gz"
 printf old > "$root/boot/vmlinuz-generic-5.15.19"
 printf oldinitrd > "$root/boot/initrd.gz"
 cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
 cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
 cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"
 cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
 printf ko > "$root/lib/modules/5.15.209/kernel/a.ko"
 printf oldko > "$root/lib/modules/5.15.19/kernel/b.ko"
 for x in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2; do : > "$root/var/lib/pkgtools/packages/$x"; done
 recovery=$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test
 printf boot > "$recovery/boot.tar"; printf modules > "$recovery/modules.tar"; printf pkg > "$recovery/pkgtools.tar"
 (cd "$recovery" && sha256sum boot.tar modules.tar pkgtools.tar > archive.sha256)
 ROOT="$root" META="$meta" SCRIPT="$SCRIPT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META']); script=pathlib.Path(os.environ['SCRIPT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
names=''.join(p.name+'\n' for p in sorted((root/'var/lib/pkgtools/packages').iterdir()))
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths)
def manifest(ver):
 d=root/'lib/modules'/ver; ls=[]
 for p in sorted(x for x in d.rglob('*') if x.is_file()): ls.append(f"{sh(p)}  ./{p.relative_to(d)}\n")
 return ''.join(ls)
pkgsha=hashlib.sha256(names.encode()).hexdigest(); bootsha=hashlib.sha256(rows.encode()).hexdigest(); actsha=hashlib.sha256(manifest('5.15.209').encode()).hexdigest(); oldsha=hashlib.sha256(manifest('5.15.19').encode()).hexdigest()
auth={'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19'}; (meta/'auth.json').write_text(json.dumps(auth)+'\n')
diag={'schema':1,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','archive_sha256':'f'*64,'apply_executed':True,'apply_committed':False,'recovery_restored':True,'pause_safe':True,'recovery_backup_path':'/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test','recovery_archive_manifest_sha256':sh(root/'var/lib/slack-update/elilo-cleanup-backups/5.15.19-test/archive.sha256'),'preapply_package_snapshot_sha256':pkgsha,'preapply_boot_manifest_sha256':bootsha,'preapply_active_module_manifest_sha256':actsha,'preapply_rollback_module_manifest_sha256':oldsha,'false_negative':{'classification':'generated-depmod-index-byte-drift','changed_active_module_manifest_entries':6,'changed_kernel_module_objects':0,'changed_paths':['./modules.alias','./modules.alias.bin','./modules.dep','./modules.dep.bin','./modules.symbols','./modules.symbols.bin'],'attempt_final_package_set_was_exactly_expected':True,'transaction_reached_expected_cleanup_before_final_assertion':True}}
(meta/'diag.json').write_text(json.dumps(diag,sort_keys=True)+'\n')
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-authorized-apply-recovery-review','reviewed':True,'expected_script_sha256':fh(script),'accepted_authorization_record_sha256':fh(meta/'auth.json'),'failed_apply_diagnostic_sha256':fh(meta/'diag.json'),'failed_apply_archive_sha256':'f'*64,'confirmation_scope_sha256':'e'*64}; (meta/'policy.json').write_text(json.dumps(pol,sort_keys=True)+'\n')
PY
}
run_case(){ local c=$1; SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TMP/$c/root" ELILO_CLEANUP_RECOVERY_REVIEW_TEST_HOST=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_RECOVERY_REVIEW_TEST_KERNEL=5.15.209 ELILO_CLEANUP_RECOVERY_REVIEW_POLICY_PATH="$TMP/$c/meta/policy.json" ELILO_CLEANUP_RECOVERY_REVIEW_ACCEPTED_AUTH_PATH="$TMP/$c/meta/auth.json" ELILO_CLEANUP_RECOVERY_REVIEW_DIAGNOSTIC_PATH="$TMP/$c/meta/diag.json" bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-failed-apply-evidence-sha256 "$(printf 'f%.0s' {1..64})" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-recovery-review-sha256 "$(printf 'e%.0s' {1..64})" --output-dir "$TMP/$c/output" > "$TMP/$c/run.log" 2>&1; }
make_case valid
ok run_case valid
contains 'recovery_verified=true' "$TMP/valid/output/summary.txt"
contains 'retry_design_required=true' "$TMP/valid/output/summary.txt"
contains 'cleanup_authorized=false' "$TMP/valid/output/summary.txt"
contains 'apply_authorized=false' "$TMP/valid/output/summary.txt"
contains 'pause_safe=true' "$TMP/valid/output/summary.txt"
contains 'generated-depmod-index-byte-drift' "$TMP/valid/output/diagnostic.txt"
ok grep -q ': OK$' "$TMP/valid/output/recovery-backup-verify.log"

make_case drift
printf drift >> "$TMP/drift/root/boot/vmlinuz-generic-5.15.209"
if run_case drift; then FAILS=$((FAILS+1)); fi; COUNT=$((COUNT+1))
contains 'recovery_verified=false' "$TMP/drift/output/summary.txt"
contains 'pause_safe=false' "$TMP/drift/output/summary.txt"

make_case broad
python3 - "$TMP/broad/meta/diag.json" "$TMP/broad/meta/policy.json" "$SCRIPT" "$TMP/broad/meta/auth.json" <<'PY'
import hashlib,json,pathlib,sys
dp,pp,sp,ap=map(pathlib.Path,sys.argv[1:]); d=json.load(open(dp)); d['false_negative']['changed_kernel_module_objects']=1; dp.write_text(json.dumps(d,sort_keys=True)+'\n'); p=json.load(open(pp)); p['failed_apply_diagnostic_sha256']=hashlib.sha256(dp.read_bytes()).hexdigest(); pp.write_text(json.dumps(p,sort_keys=True)+'\n')
PY
if run_case broad; then FAILS=$((FAILS+1)); fi; COUNT=$((COUNT+1))
contains 'retry_design_required=false' "$TMP/broad/output/summary.txt"

ok bash -n "$SCRIPT"
contains 'cleanup_authorized=false' "$SCRIPT"
contains 'apply_authorized=false' "$SCRIPT"
contains 'sha256sum -c archive.sha256' "$SCRIPT"
printf 'ELILO oldkernel cleanup recovery review harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
