#!/bin/bash
set -u
export LC_ALL=C
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-final-predicate-instrumentation-review.sh
TMP=$(mktemp -d /tmp/elilo-cleanup-predicate-review.XXXXXX) || exit 1
trap 'rm -rf -- "$TMP"' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); if "$@"; then :; else echo "not ok $COUNT: $*"; FAILS=$((FAILS+1)); fi; }
contains(){ COUNT=$((COUNT+1)); if grep -Fq -- "$1" "$2"; then :; else echo "not ok $COUNT: missing $1"; FAILS=$((FAILS+1)); fi; }

make_case(){
 local c=$1 survivor=$2 root meta recovery
 root=$TMP/$c/root
 meta=$TMP/$c/meta
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
 cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
 cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
 cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"
 cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
 printf ko > "$root/lib/modules/5.15.209/kernel/a.ko"
 printf oldko > "$root/lib/modules/5.15.19/kernel/owned.ko"
 printf generated > "$root/lib/modules/5.15.19/modules.dep"
 if [ "$survivor" = yes ]; then printf external > "$root/lib/modules/5.15.19/kernel/external.ko"; fi
 write_pkg(){ local path=$1; shift; { printf 'PACKAGE NAME:  %s\n' "${path##*/}"; printf 'FILE LIST:\n'; printf '%s\n' "$@"; } > "$path"; }
 write_pkg "$root/var/lib/pkgtools/packages/kernel-generic-5.15.19-x86_64-2" boot/ boot/vmlinuz-generic-5.15.19
 write_pkg "$root/var/lib/pkgtools/packages/kernel-huge-5.15.19-x86_64-2" boot/ boot/vmlinuz-huge-5.15.19
 write_pkg "$root/var/lib/pkgtools/packages/kernel-modules-5.15.19-x86_64-2" lib/ lib/modules/ lib/modules/5.15.19/ lib/modules/5.15.19/kernel/ lib/modules/5.15.19/kernel/owned.ko
 for x in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-headers-5.15.209-x86-1 kernel-source-5.15.209-noarch-1 kernel-firmware-test-noarch-1; do write_pkg "$root/var/lib/pkgtools/packages/$x" install/slack-desc; done
 recovery=$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test
 printf boot > "$recovery/boot.tar"; printf modules > "$recovery/modules.tar"; printf pkg > "$recovery/pkgtools.tar"; (cd "$recovery" && sha256sum boot.tar modules.tar pkgtools.tar > archive.sha256)
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
failed={'schema':1,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','apply_executed':True,'apply_committed':False,'recovery_restored':True,'pause_safe':True,'recovery_backup_path':'/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test','preapply_package_snapshot_sha256':pkgsha,'preapply_boot_manifest_sha256':bootsha,'preapply_active_module_manifest_sha256':actsha,'preapply_rollback_module_manifest_sha256':oldsha,'narrowing':{'attempt_final_package_set_was_exactly_expected':True,'stable_module_payload_was_byte_identical':True,'kernel_module_objects_were_byte_identical':True,'all_six_generated_indexes_existed':True,'rollback_package_removal_log_deleted_versioned_generic_kernel':True}}
(meta/'failed.json').write_text(json.dumps(failed,sort_keys=True)+'\n')
final={'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','archive_sha256':'a'*64,'diagnostic_complete':True,'depmod_dry_run_rc':0,'root_cause_confirmed':False,'third_attempt_authorized':False,'pause_safe':True}
(meta/'final.json').write_text(json.dumps(final,sort_keys=True)+'\n')
plan={'accepted':True,'rollback_packages':['kernel-generic-5.15.19-x86_64-2','kernel-huge-5.15.19-x86_64-2','kernel-modules-5.15.19-x86_64-2']}
(meta/'plan.json').write_text(json.dumps(plan,sort_keys=True)+'\n')
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
scope=(
'operation=elilo-oldkernel-cleanup-final-predicate-instrumentation-review\n'
+'target=slackware-15.0\n'
+'hostname_fqdn=vbox-slack15.vbox-slack15.org\n'
+'final_diagnostic_evidence_sha256='+'a'*64+'\n'
+'active_kernel=5.15.209\nrollback_kernel=5.15.19\n'
+f'failed_revision_1_diagnostic_sha256={fh(meta/"failed.json")}\n'
+f'accepted_final_diagnostic_record_sha256={fh(meta/"final.json")}\n'
+f'accepted_source_plan_record_sha256={fh(meta/"plan.json")}\n'
+f'instrumentation_script_sha256={fh(script)}\n').encode()
pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-final-predicate-instrumentation-review','reviewed':True,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','expected_script_sha256':fh(script),'failed_revision_1_diagnostic_sha256':fh(meta/'failed.json'),'accepted_final_diagnostic_record_sha256':fh(meta/'final.json'),'accepted_final_diagnostic_archive_sha256':'a'*64,'accepted_source_plan_record_sha256':fh(meta/'plan.json'),'confirmation_scope_sha256':hashlib.sha256(scope).hexdigest()}
(meta/'policy.json').write_text(json.dumps(pol,sort_keys=True)+'\n')
PY
}
run_case(){
 local c=$1 scope
 scope=$(python3 - "$TMP/$c/meta/policy.json" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['confirmation_scope_sha256'])
PY
)
 SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TMP/$c/root" \
 ELILO_CLEANUP_PREDICATE_TEST_HOST=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_PREDICATE_TEST_KERNEL=5.15.209 \
 ELILO_CLEANUP_PREDICATE_POLICY_PATH="$TMP/$c/meta/policy.json" ELILO_CLEANUP_PREDICATE_FAILED_PATH="$TMP/$c/meta/failed.json" \
 ELILO_CLEANUP_PREDICATE_FINAL_DIAGNOSTIC_PATH="$TMP/$c/meta/final.json" ELILO_CLEANUP_PREDICATE_PLAN_PATH="$TMP/$c/meta/plan.json" \
 bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-final-diagnostic-evidence-sha256 "$(printf 'a%.0s' {1..64})" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-instrumentation-review-sha256 "$scope" --output-dir "$TMP/$c/output" > "$TMP/$c/run.log" 2>&1
}

make_case survivor yes
ok run_case survivor
contains 'root_cause_confirmed=true' "$TMP/survivor/output/summary.txt"
contains 'unowned_rollback_module_objects=1' "$TMP/survivor/output/summary.txt"
contains '/lib/modules/5.15.19/kernel/external.ko' "$TMP/survivor/output/rollback-unowned-module-objects.txt"
contains 'verify.rollback_module_objects_absent' "$TMP/survivor/output/final-predicate-instrumentation.tsv"
contains 'fail-projected' "$TMP/survivor/output/final-predicate-instrumentation.tsv"
contains 'third_attempt_authorized=false' "$TMP/survivor/output/summary.txt"
contains 'next_stage=elilo-oldkernel-cleanup-rollback-module-survivor-revision-review' "$TMP/survivor/output/summary.txt"

make_case clean no
ok run_case clean
contains 'root_cause_confirmed=false' "$TMP/clean/output/summary.txt"
contains 'unowned_rollback_module_objects=0' "$TMP/clean/output/summary.txt"
contains 'next_stage=elilo-oldkernel-cleanup-instrumented-third-attempt-review' "$TMP/clean/output/summary.txt"
ok test ! -s "$TMP/clean/output/rollback-unowned-module-objects.txt"

ok bash -n "$SCRIPT"
contains 'third_attempt_authorized=false' "$SCRIPT"
contains 'FILE LIST:' "$SCRIPT"
contains 'rollback-package-unowned-module-object-survivors' "$SCRIPT"
printf 'ELILO oldkernel cleanup final-predicate instrumentation harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
