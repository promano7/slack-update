#!/bin/bash
set -u
export LC_ALL=C
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-rollback-module-survivor-revision-review.sh
TMP=$(mktemp -d /tmp/elilo-cleanup-survivor-review.XXXXXX) || exit 1
trap 'rm -rf -- "$TMP"' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); if "$@"; then :; else echo "not ok $COUNT: $*"; FAILS=$((FAILS+1)); fi; }
contains(){ COUNT=$((COUNT+1)); if grep -Fq -- "$1" "$2"; then :; else echo "not ok $COUNT: missing $1"; FAILS=$((FAILS+1)); fi; }

make_case(){
 local c=$1 owner_mode=$2 root meta recovery
 root=$TMP/$c/root; meta=$TMP/$c/meta
 mkdir -p "$root/boot/efi/EFI/Slackware" "$root/lib/modules/5.15.209/misc" "$root/lib/modules/5.15.19/misc" "$root/var/lib/pkgtools/packages" "$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test" "$meta"
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
 for n in vboxguest vboxsf vboxvideo; do printf "old-$n" > "$root/lib/modules/5.15.19/misc/$n.ko"; printf "active-$n" > "$root/lib/modules/5.15.209/misc/$n.ko"; done
 write_pkg(){ local path=$1; shift; { printf 'PACKAGE NAME:  %s\n' "${path##*/}"; printf 'FILE LIST:\n'; printf '%s\n' "$@"; } > "$path"; }
 write_pkg "$root/var/lib/pkgtools/packages/kernel-generic-5.15.19-x86_64-2" boot/vmlinuz-generic-5.15.19
 write_pkg "$root/var/lib/pkgtools/packages/kernel-huge-5.15.19-x86_64-2" boot/vmlinuz-huge-5.15.19
 write_pkg "$root/var/lib/pkgtools/packages/kernel-modules-5.15.19-x86_64-2" lib/modules/5.15.19/kernel/owned.ko
 for x in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1; do write_pkg "$root/var/lib/pkgtools/packages/$x" install/slack-desc; done
 if [ "$owner_mode" = owned ]; then write_pkg "$root/var/lib/pkgtools/packages/virtualbox-addons-test-x86_64-1" lib/modules/5.15.19/misc/vboxguest.ko; fi
 recovery=$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test
 printf boot > "$recovery/boot.tar"; printf modules > "$recovery/modules.tar"; printf pkg > "$recovery/pkgtools.tar"; (cd "$recovery" && sha256sum boot.tar modules.tar pkgtools.tar > archive.sha256)
 cat > "$meta/modinfo" <<'MI'
#!/bin/bash
if [ "$1" = -n ]; then printf '/lib/modules/5.15.209/misc/%s.ko\n' "$2"; exit 0; fi
[ "$1" = -F ] || exit 1
field=$2; path=$3
base=${path##*/}; name=${base%.ko}
case "$field" in
 name) printf '%s\n' "$name";;
 vermagic) case "$path" in */5.15.19/*) printf '5.15.19 SMP mod_unload\n';; */5.15.209/*) printf '5.15.209 SMP mod_unload\n';; *) exit 1;; esac;;
 *) exit 1;;
esac
MI
 chmod +x "$meta/modinfo"
 ROOT="$root" META="$meta" SCRIPT="$SCRIPT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META']); script=pathlib.Path(os.environ['SCRIPT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
names=''.join(p.name+'\n' for p in sorted((root/'var/lib/pkgtools/packages').iterdir()))
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
rows=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths)
def manifest(ver):
 d=root/'lib/modules'/ver
 return ''.join(f"{sh(p)}  ./{p.relative_to(d)}\n" for p in sorted(x for x in d.rglob('*') if x.is_file()))
pkgsha=hashlib.sha256(names.encode()).hexdigest(); bootsha=hashlib.sha256(rows.encode()).hexdigest(); actsha=hashlib.sha256(manifest('5.15.209').encode()).hexdigest(); oldsha=hashlib.sha256(manifest('5.15.19').encode()).hexdigest()
paths_old=['/lib/modules/5.15.19/misc/vboxguest.ko','/lib/modules/5.15.19/misc/vboxsf.ko','/lib/modules/5.15.19/misc/vboxvideo.ko']
accepted={'schema':1,'scenario':'elilo-oldkernel-cleanup-final-predicate-instrumentation-review','accepted':True,'archive_sha256':'a'*64,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','diagnostic_complete':True,'root_cause_confirmed':True,'root_cause_classification':'rollback-package-unowned-module-object-survivors','unowned_rollback_files':3,'unowned_rollback_module_objects':3,'unowned_rollback_module_object_paths':paths_old,'package_snapshot_sha256':pkgsha,'boot_manifest_sha256':bootsha,'active_module_manifest_sha256':actsha,'rollback_module_manifest_sha256':oldsha,'third_attempt_authorized':False,'pause_safe':True}
(meta/'accepted.json').write_text(json.dumps(accepted,sort_keys=True)+'\n')
failed={'schema':1,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','recovery_restored':True,'pause_safe':True,'recovery_backup_path':'/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test'}
(meta/'failed.json').write_text(json.dumps(failed,sort_keys=True)+'\n')
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
scope=(
'operation=elilo-oldkernel-cleanup-rollback-module-survivor-revision-review\n'
+'target=slackware-15.0\n'
+'hostname_fqdn=vbox-slack15.vbox-slack15.org\n'
+'instrumentation_evidence_sha256='+'a'*64+'\n'
+'active_kernel=5.15.209\nrollback_kernel=5.15.19\n'
+f'accepted_instrumentation_record_sha256={fh(meta/"accepted.json")}\n'
+f'failed_revision_1_diagnostic_sha256={fh(meta/"failed.json")}\n'
+f'survivor_review_script_sha256={fh(script)}\n').encode()
pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-revision-review','reviewed':True,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','expected_script_sha256':fh(script),'accepted_instrumentation_record_sha256':fh(meta/'accepted.json'),'failed_revision_1_diagnostic_sha256':fh(meta/'failed.json'),'accepted_instrumentation_archive_sha256':'a'*64,'confirmation_scope_sha256':hashlib.sha256(scope).hexdigest()}
(meta/'policy.json').write_text(json.dumps(pol,sort_keys=True)+'\n')
PY
}
run_case(){
 local c=$1 scope
 scope=$(python3 - "$TMP/$c/meta/policy.json" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['confirmation_scope_sha256'])
PY
)
 SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$TMP/$c/root" ELILO_CLEANUP_SURVIVOR_TEST_HOST=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_SURVIVOR_TEST_KERNEL=5.15.209 \
 ELILO_CLEANUP_SURVIVOR_POLICY_PATH="$TMP/$c/meta/policy.json" ELILO_CLEANUP_SURVIVOR_ACCEPTED_PATH="$TMP/$c/meta/accepted.json" ELILO_CLEANUP_SURVIVOR_FAILED_PATH="$TMP/$c/meta/failed.json" ELILO_CLEANUP_SURVIVOR_MODINFO="$TMP/$c/meta/modinfo" \
 bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-instrumentation-evidence-sha256 "$(printf 'a%.0s' {1..64})" --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-survivor-review-sha256 "$scope" --output-dir "$TMP/$c/output" > "$TMP/$c/run.log" 2>&1
}

make_case valid unowned
ok run_case valid
contains 'survivor_review_ready=true' "$TMP/valid/output/summary.txt"
contains 'survivor_removal_scope_ready=true' "$TMP/valid/output/summary.txt"
contains 'third_attempt_authorized=false' "$TMP/valid/output/summary.txt"
contains '/lib/modules/5.15.19/misc/vboxguest.ko' "$TMP/valid/output/survivor-review.tsv"
contains '5.15.19 SMP mod_unload' "$TMP/valid/output/survivor-review.tsv"
contains '/lib/modules/5.15.209/misc/vboxvideo.ko' "$TMP/valid/output/survivor-review.tsv"
contains '"deletion_authorized": false' "$TMP/valid/output/survivor-removal-contract.json"
contains '"recursive_module_tree_removal_authorized": false' "$TMP/valid/output/survivor-removal-contract.json"
contains 'pause_safe=true' "$TMP/valid/output/summary.txt"

make_case owned owned
COUNT=$((COUNT+1)); if run_case owned; then echo "not ok $COUNT: package-owned survivor was accepted"; FAILS=$((FAILS+1)); fi
contains 'survivor_review_ready=false' "$TMP/owned/output/summary.txt"

ok bash -n "$SCRIPT"
contains 'third_attempt_authorized=false' "$SCRIPT"
contains 'recursive_module_tree_removal_authorized' "$SCRIPT"
contains 'package_owners' "$SCRIPT"
contains "modinfo,'-F'" "$SCRIPT"
printf 'ELILO oldkernel cleanup rollback-module survivor revision harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
