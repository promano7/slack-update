#!/bin/bash
set -u
export LC_ALL=C
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-final-contract-diagnostic.sh
TMP=$(mktemp -d /tmp/elilo-cleanup-final-diagnostic.XXXXXX) || exit 1
trap ':' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); if "$@"; then :; else echo "not ok $COUNT: $*"; FAILS=$((FAILS+1)); fi; }
contains(){ COUNT=$((COUNT+1)); if grep -Fq -- "$1" "$2"; then :; else echo "not ok $COUNT: missing $1"; FAILS=$((FAILS+1)); fi; }
make_case(){
 local c=$1 rc=$2
 local root=$TMP/$c/root meta=$TMP/$c/meta recovery
 mkdir -p "$root/boot/efi/EFI/Slackware" "$root/lib/modules/5.15.209/kernel" "$root/lib/modules/5.15.19/kernel" "$root/var/lib/pkgtools/packages" "$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test" "$meta"
 cat > "$root/boot/efi/EFI/Slackware/elilo.conf" <<'CONF'
default=vmlinuz
image=vmlinuz-generic-5.15.209
  label=vmlinuz
  initrd=initrd-generic-5.15.209.gz
image=vmlinuz
  label=oldkernel
  initrd=initrd.gz
CONF
 printf active > "$root/boot/vmlinuz-generic-5.15.209"; printf initrd > "$root/boot/initrd-generic-5.15.209.gz"; printf old > "$root/boot/vmlinuz-generic-5.15.19"; printf oldinitrd > "$root/boot/initrd.gz"
 cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"; cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"; cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"; cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
 printf ko > "$root/lib/modules/5.15.209/kernel/a.ko"; printf oldko > "$root/lib/modules/5.15.19/kernel/b.ko"
 for f in modules.alias modules.alias.bin modules.dep modules.dep.bin modules.symbols modules.symbols.bin; do printf generated > "$root/lib/modules/5.15.209/$f"; done
 for x in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2; do : > "$root/var/lib/pkgtools/packages/$x"; done
 recovery=$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test
 printf boot > "$recovery/boot.tar"; printf modules > "$recovery/modules.tar"; printf pkg > "$recovery/pkgtools.tar"; (cd "$recovery" && sha256sum boot.tar modules.tar pkgtools.tar > archive.sha256)
 cat > "$TMP/$c/depmod" <<DEP
#!/bin/sh
printf 'depmod output for %s\n' "\$2"
printf 'diagnostic rc=$rc\n' >&2
exit $rc
DEP
 chmod +x "$TMP/$c/depmod"
 ROOT="$root" META="$meta" SCRIPT="$SCRIPT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META']); script=pathlib.Path(os.environ['SCRIPT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
names=''.join(p.name+'\n' for p in sorted((root/'var/lib/pkgtools/packages').iterdir()))
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths)
def manifest(ver):
 d=root/'lib/modules'/ver; return ''.join(f"{sh(p)}  ./{p.relative_to(d)}\n" for p in sorted(x for x in d.rglob('*') if x.is_file()))
pkgsha=hashlib.sha256(names.encode()).hexdigest(); bootsha=hashlib.sha256(rows.encode()).hexdigest(); actsha=hashlib.sha256(manifest('5.15.209').encode()).hexdigest(); oldsha=hashlib.sha256(manifest('5.15.19').encode()).hexdigest()
recovery=root/'var/lib/slack-update/elilo-cleanup-backups/5.15.19-test'
diag={'schema':1,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','archive_sha256':'f'*64,'apply_executed':True,'apply_committed':False,'recovery_restored':True,'pause_safe':True,'recovery_backup_path':'/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test','recovery_archive_manifest_sha256':sh(recovery/'archive.sha256'),'preapply_package_snapshot_sha256':pkgsha,'preapply_boot_manifest_sha256':bootsha,'preapply_active_module_manifest_sha256':actsha,'preapply_rollback_module_manifest_sha256':oldsha,'narrowing':{'attempt_final_package_set_was_exactly_expected':True,'stable_module_payload_was_byte_identical':True,'kernel_module_objects_were_byte_identical':True,'changed_active_module_manifest_entries':6,'changed_paths':['./modules.alias','./modules.alias.bin','./modules.dep','./modules.dep.bin','./modules.symbols','./modules.symbols.bin'],'all_six_generated_indexes_existed':True,'remaining_final_predicate_was_not_logged_individually':True}}
(meta/'diag.json').write_text(json.dumps(diag,sort_keys=True)+'\n')
rec={'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19'}; (meta/'recovery.json').write_text(json.dumps(rec,sort_keys=True)+'\n')
rev={'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','retry_authorized':True,'apply_executed':False}; (meta/'revision.json').write_text(json.dumps(rev,sort_keys=True)+'\n')
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-final-contract-diagnostic','reviewed':True,'expected_script_sha256':fh(script),'failed_revision_1_diagnostic_sha256':fh(meta/'diag.json'),'accepted_recovery_record_sha256':fh(meta/'recovery.json'),'accepted_revision_record_sha256':fh(meta/'revision.json'),'failed_revision_1_archive_sha256':'f'*64,'confirmation_scope_sha256':'e'*64}; (meta/'policy.json').write_text(json.dumps(pol,sort_keys=True)+'\n')
PY
}
run_case(){ local c=$1; SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TMP/$c/root" ELILO_CLEANUP_FINAL_DIAGNOSTIC_TEST_HOST=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_FINAL_DIAGNOSTIC_TEST_KERNEL=5.15.209 ELILO_CLEANUP_FINAL_DIAGNOSTIC_DEPMOD="$TMP/$c/depmod" ELILO_CLEANUP_FINAL_DIAGNOSTIC_POLICY_PATH="$TMP/$c/meta/policy.json" ELILO_CLEANUP_FINAL_DIAGNOSTIC_FAILED_PATH="$TMP/$c/meta/diag.json" ELILO_CLEANUP_FINAL_DIAGNOSTIC_RECOVERY_PATH="$TMP/$c/meta/recovery.json" ELILO_CLEANUP_FINAL_DIAGNOSTIC_REVISION_PATH="$TMP/$c/meta/revision.json" bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-failed-revision-evidence-sha256 "$(printf 'f%.0s' {1..64})" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-final-diagnostic-sha256 "$(printf 'e%.0s' {1..64})" --output-dir "$TMP/$c/output" > "$TMP/$c/run.log" 2>&1; }
make_case rc1 1
ok run_case rc1
contains 'depmod_dry_run_rc=1' "$TMP/rc1/output/summary.txt"
contains 'root_cause_confirmed=true' "$TMP/rc1/output/summary.txt"
contains 'third_attempt_authorized=false' "$TMP/rc1/output/summary.txt"
contains 'next_stage=elilo-oldkernel-cleanup-depmod-validation-revision-review' "$TMP/rc1/output/summary.txt"
ok cmp -s "$TMP/rc1/output/modules-active.probe.before.sha256" "$TMP/rc1/output/modules-active.probe.after.sha256"
ok bash -n "$SCRIPT"
contains 'third_attempt_authorized=false' "$SCRIPT"
contains 'if [ "$DEPMOD_RC" -ne 0 ]; then ROOT_CAUSE_CONFIRMED=true' "$SCRIPT"
contains 'else ROOT_CAUSE_CONFIRMED=false; NEXT_STAGE=elilo-oldkernel-cleanup-final-predicate-instrumentation-review' "$SCRIPT"
printf 'ELILO oldkernel cleanup final-contract diagnostic harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
