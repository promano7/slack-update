#!/bin/bash
set -uo pipefail
IFS=$'\n\t'; LC_ALL=C; export LC_ALL
REPO=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply-revision-review.sh
APPLY=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh
CONTRACT=$REPO/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-contract.json
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
COUNT=0; FAILS=0
ok(){ COUNT=$((COUNT+1)); "$@" || { printf 'FAIL: %s\n' "$*" >&2; FAILS=$((FAILS+1)); }; }
contains(){ COUNT=$((COUNT+1)); grep -Fq -- "$1" "$2" || { printf 'FAIL: missing <%s> in %s\n' "$1" "$2" >&2; FAILS=$((FAILS+1)); }; }
root=$TMP/root; meta=$TMP/meta; out=$TMP/out; mkdir -p "$root/boot/efi/EFI/Slackware" "$root/lib/modules/5.15.209/kernel" "$root/lib/modules/5.15.19/kernel" "$root/var/lib/pkgtools/packages" "$root/var/cache/packages/linux" "$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test" "$meta"
printf active > "$root/boot/vmlinuz-generic-5.15.209"; printf initrd > "$root/boot/initrd-generic-5.15.209.gz"; printf old > "$root/boot/vmlinuz-generic-5.15.19"; printf oldinitrd > "$root/boot/initrd.gz"; cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"; cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"; cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"; cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
cat > "$root/boot/efi/EFI/Slackware/elilo.conf" <<'EOC'
default=vmlinuz
image=vmlinuz-generic-5.15.209
  label=vmlinuz
  initrd=initrd-generic-5.15.209.gz
image=vmlinuz
  label=oldkernel
  initrd=initrd.gz
EOC
printf ko > "$root/lib/modules/5.15.209/kernel/a.ko"; printf oldko > "$root/lib/modules/5.15.19/kernel/o.ko"
for f in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2; do : > "$root/var/lib/pkgtools/packages/$f"; done
for f in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1; do printf "$f" > "$root/var/cache/packages/linux/$f.txz"; done
backup=$root/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test; printf a > "$backup/boot.tar"; printf b > "$backup/modules.tar"; printf c > "$backup/pkgtools.tar"; (cd "$backup" && sha256sum boot.tar modules.tar pkgtools.tar) > "$backup/archive.sha256"
ROOT="$root" META="$meta" SCRIPT="$SCRIPT" APPLY="$APPLY" CONTRACT="$CONTRACT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META']); script=pathlib.Path(os.environ['SCRIPT']); apply=pathlib.Path(os.environ['APPLY']); contract=pathlib.Path(os.environ['CONTRACT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
packages=''.join(x.name+'\n' for x in sorted((root/'var/lib/pkgtools/packages').iterdir())); (meta/'packages').write_text(packages)
def mod(v):
 d=root/'lib/modules'/v; rows=''.join(f"{sh(p)}  ./{p.relative_to(d)}\n" for p in sorted(d.rglob('*')) if p.is_file()); return rows
for v,n in [('5.15.209','active'),('5.15.19','rollback')]: (meta/f'mod-{n}').write_text(mod(v))
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']; boot=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths); (meta/'boot').write_text(boot)
contract_data=json.loads(contract.read_text()); contract_data['base_apply_contract_sha256']='d'*64; (meta/'contract.json').write_text(json.dumps(contract_data,sort_keys=True))
plan={'accepted':True,'active_archives':[]}
for rec in ['kernel-generic-5.15.209-x86_64-1','kernel-huge-5.15.209-x86_64-1','kernel-modules-5.15.209-x86_64-1']:
 p='/var/cache/packages/linux/'+rec+'.txz'; plan['active_archives'].append({'path':p,'sha256':sh(root/p.lstrip('/'))})
(meta/'plan.json').write_text(json.dumps(plan))
auth={'apply_contract_sha256':'d'*64}; (meta/'auth.json').write_text(json.dumps(auth))
rec={'status':'accepted-recovery-review','archive_sha256':'e'*64,'recovery_verified':True,'cleanup_authorized':False,'apply_authorized':False,'hostname_fqdn':'vbox-slack15.vbox-slack15.org','active_kernel':'5.15.209','rollback_kernel':'5.15.19','package_snapshot_sha256':sh(meta/'packages'),'boot_manifest_sha256':sh(meta/'boot'),'active_module_manifest_sha256':sh(meta/'mod-active'),'rollback_module_manifest_sha256':sh(meta/'mod-rollback'),'recovery_backup_path':'/var/lib/slack-update/elilo-cleanup-backups/5.15.19-test','recovery_archive_manifest_sha256':sh(root/'var/lib/slack-update/elilo-cleanup-backups/5.15.19-test/archive.sha256')}; (meta/'recovery.json').write_text(json.dumps(rec,sort_keys=True))
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
raw=('operation=elilo-oldkernel-cleanup-authorized-apply-revision-review\n'+'target=slackware-15.0\n'+'hostname_fqdn=vbox-slack15.vbox-slack15.org\n'+'recovery_evidence_sha256='+'e'*64+'\n'+'active_kernel=5.15.209\nrollback_kernel=5.15.19\n'+f"accepted_recovery_record_sha256={fh(meta/'recovery.json')}\n"+f"revision_contract_sha256={fh(meta/'contract.json')}\n"+f'revised_apply_script_sha256={fh(apply)}\n'+f'revision_review_script_sha256={fh(script)}\n').encode(); scope=hashlib.sha256(raw).hexdigest(); pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-authorized-apply-revision-review','reviewed':True,'expected_script_sha256':fh(script),'accepted_recovery_record_sha256':fh(meta/'recovery.json'),'revision_contract_sha256':fh(meta/'contract.json'),'revised_apply_script_sha256':fh(apply),'confirmation_scope_sha256':scope}; (meta/'policy.json').write_text(json.dumps(pol)); (meta/'args').write_text(scope+'\n')
PY
scope=$(cat "$meta/args")
SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$root" ELILO_CLEANUP_TEST_HOSTNAME_FQDN=vbox-slack15.vbox-slack15.org ELILO_CLEANUP_TEST_RUNNING_KERNEL=5.15.209 ELILO_CLEANUP_REVISION_REVIEW_POLICY_PATH="$meta/policy.json" ELILO_CLEANUP_ACCEPTED_RECOVERY_PATH="$meta/recovery.json" ELILO_CLEANUP_ACCEPTED_PLAN_PATH="$meta/plan.json" ELILO_CLEANUP_ACCEPTED_AUTH_PATH="$meta/auth.json" ELILO_CLEANUP_REVISION_CONTRACT_PATH="$meta/contract.json" bash "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-recovery-evidence-sha256 $(printf 'e%.0s' {1..64}) --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 --confirm-revision-review-sha256 "$scope" --output-dir "$out" > "$TMP/run.log" 2>&1
ok test $? -eq 0; contains 'retry_authorized=true' "$out/summary.txt"; contains 'apply_executed=false' "$out/summary.txt"; contains 'pause_safe=true' "$out/summary.txt"; ok cmp -s "$out/packages.before.txt" "$out/packages.after.txt"; ok cmp -s "$out/boot.before.sha256" "$out/boot.after.sha256"; ok cmp -s "$out/modules-active.before.sha256" "$out/modules-active.after.sha256"; ok cmp -s "$out/modules-rollback.before.sha256" "$out/modules-rollback.after.sha256"; ok bash -n "$SCRIPT"; contains 'additional_generated_paths_allowed' "$CONTRACT"; contains 'module_object_manifest' "$APPLY"; contains 'verify_generated_depmod_indexes' "$APPLY"
printf 'ELILO oldkernel cleanup apply revision review harness: %d checks, %d failures\n' "$COUNT" "$FAILS"; [ "$FAILS" -eq 0 ]
