#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

REPO=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review.sh
APPLY=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh
CONTRACT=$REPO/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-survivor-integrated-apply-revision-contract.json
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
COUNT=0
FAILS=0

ok(){ COUNT=$((COUNT+1)); "$@" || { printf 'FAIL: %s\n' "$*" >&2; FAILS=$((FAILS+1)); }; }
contains(){ COUNT=$((COUNT+1)); grep -Fq -- "$1" "$2" || { printf 'FAIL: missing <%s> in %s\n' "$1" "$2" >&2; FAILS=$((FAILS+1)); }; }

root=$TMP/root
meta=$TMP/meta
out=$TMP/out
mkdir -p "$root/boot/efi/EFI/Slackware" "$root/lib/modules/5.15.209/misc" "$root/lib/modules/5.15.19/misc" "$root/var/lib/pkgtools/packages" "$meta"

printf active > "$root/boot/vmlinuz-generic-5.15.209"
printf initrd > "$root/boot/initrd-generic-5.15.209.gz"
printf old > "$root/boot/vmlinuz-generic-5.15.19"
printf oldinitrd > "$root/boot/initrd.gz"
cp "$root/boot/vmlinuz-generic-5.15.209" "$root/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
cp "$root/boot/initrd-generic-5.15.209.gz" "$root/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
cp "$root/boot/vmlinuz-generic-5.15.19" "$root/boot/efi/EFI/Slackware/vmlinuz"
cp "$root/boot/initrd.gz" "$root/boot/efi/EFI/Slackware/initrd.gz"
cat > "$root/boot/efi/EFI/Slackware/elilo.conf" <<'EOF_CONF'
default=vmlinuz
image=vmlinuz-generic-5.15.209
  label=vmlinuz
  initrd=initrd-generic-5.15.209.gz
image=vmlinuz
  label=oldkernel
  initrd=initrd.gz
EOF_CONF

for m in vboxguest vboxsf vboxvideo; do
 printf "active-$m" > "$root/lib/modules/5.15.209/misc/$m.ko"
 printf "rollback-$m" > "$root/lib/modules/5.15.19/misc/$m.ko"
done
for f in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2; do : > "$root/var/lib/pkgtools/packages/$f"; done

ROOT="$root" META="$meta" SCRIPT="$SCRIPT" APPLY="$APPLY" CONTRACT="$CONTRACT" python3 <<'PY'
import hashlib,json,os,pathlib
root=pathlib.Path(os.environ['ROOT']); meta=pathlib.Path(os.environ['META'])
script=pathlib.Path(os.environ['SCRIPT']); apply=pathlib.Path(os.environ['APPLY']); contract=pathlib.Path(os.environ['CONTRACT'])
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
packages=''.join(p.name+'\n' for p in sorted((root/'var/lib/pkgtools/packages').iterdir()))
(meta/'packages.txt').write_text(packages)
def manifest(v):
 d=root/'lib/modules'/v
 return ''.join(f"{sh(p)}  ./{p.relative_to(d)}\n" for p in sorted(d.rglob('*')) if p.is_file())
(meta/'active.txt').write_text(manifest('5.15.209'))
(meta/'rollback.txt').write_text(manifest('5.15.19'))
paths=['/boot/efi/EFI/Slackware/elilo.conf','/boot/vmlinuz-generic-5.15.209','/boot/initrd-generic-5.15.209.gz','/boot/vmlinuz-generic-5.15.19','/boot/initrd.gz','/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209','/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz','/boot/efi/EFI/Slackware/vmlinuz','/boot/efi/EFI/Slackware/initrd.gz']
boot=''.join(f"{sh(root/p.lstrip('/'))}  {p}\n" for p in paths)
(meta/'boot.txt').write_text(boot)
survivors=[]
for m in ('vboxguest','vboxsf','vboxvideo'):
 old=f'/lib/modules/5.15.19/misc/{m}.ko'; active=f'/lib/modules/5.15.209/misc/{m}.ko'
 survivors.append({'module_name':m,'rollback_path':old,'rollback_sha256':sh(root/old.lstrip('/')),
 'rollback_vermagic':'5.15.19 SMP preempt mod_unload','installed_package_owners':[],
 'active_counterpart_path':active,'active_counterpart_sha256':sh(root/active.lstrip('/')),
 'active_counterpart_vermagic':'5.15.209 SMP preempt mod_unload'})
accepted={'accepted':True,'archive_sha256':'e'*64,'hostname_fqdn':'vbox-slack15.vbox-slack15.org',
 'active_kernel':'5.15.209','rollback_kernel':'5.15.19','survivor_deletion_authorized':True,
 'recursive_module_tree_removal_authorized':False,'active_counterpart_removal_authorized':False,
 'third_attempt_authorized':False,'execution_authorized':False,'package_snapshot_sha256':sh(meta/'packages.txt'),
 'boot_manifest_sha256':sh(meta/'boot.txt'),'active_module_manifest_sha256':sh(meta/'active.txt'),
 'rollback_module_manifest_sha256':sh(meta/'rollback.txt'),'survivors':survivors}
(meta/'accepted.json').write_text(json.dumps(accepted,sort_keys=True))
c=json.loads(contract.read_text()); c['survivor_deletion_authorization_archive_sha256']='e'*64; c['survivors']=survivors
(meta/'contract.json').write_text(json.dumps(c,sort_keys=True))
def fh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
ap={'schema':3,'scenario':'elilo-oldkernel-cleanup-authorized-apply-revision-2-prepared','reviewed':True,
 'execution_authorized':False,'third_attempt_authorized':False,'expected_script_sha256':fh(apply),
 'accepted_survivor_authorization_record_sha256':fh(meta/'accepted.json'),
 'survivor_integrated_revision_contract_sha256':fh(meta/'contract.json'),
 'accepted_third_attempt_authorization_archive_sha256':None,'accepted_third_attempt_authorization_record_sha256':None,
 'confirmation_scope_sha256':None}
(meta/'apply-policy.json').write_text(json.dumps(ap,sort_keys=True))
raw=('operation=elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review\n'
'target=slackware-15.0\nhostname_fqdn=vbox-slack15.vbox-slack15.org\nsurvivor_authorization_evidence_sha256='+'e'*64+'\n'
'active_kernel=5.15.209\nrollback_kernel=5.15.19\n'
f"accepted_survivor_authorization_record_sha256={fh(meta/'accepted.json')}\n"
f"integration_contract_sha256={fh(meta/'contract.json')}\n"
f'revised_apply_script_sha256={fh(apply)}\n'
f"prepared_apply_policy_sha256={fh(meta/'apply-policy.json')}\n"
f'revision_review_script_sha256={fh(script)}\n').encode()
scope=hashlib.sha256(raw).hexdigest()
pol={'schema':1,'scenario':'elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review',
 'reviewed':True,'expected_script_sha256':fh(script),'accepted_survivor_authorization_record_sha256':fh(meta/'accepted.json'),
 'accepted_survivor_authorization_archive_sha256':'e'*64,'integration_contract_sha256':fh(meta/'contract.json'),
 'revised_apply_script_sha256':fh(apply),'prepared_apply_policy_sha256':fh(meta/'apply-policy.json'),
 'confirmation_scope_sha256':scope}
(meta/'policy.json').write_text(json.dumps(pol,sort_keys=True))
(meta/'scope.txt').write_text(scope+'\n')
PY

scope=$(cat "$meta/scope.txt")
SLACK_UPDATE_TEST_MODE=1 \
SLACK_UPDATE_TEST_ROOT="$root" \
ELILO_CLEANUP_SURVIVOR_INTEGRATION_TEST_KERNEL=5.15.209 \
ELILO_CLEANUP_SURVIVOR_INTEGRATION_TEST_HOST=vbox-slack15.vbox-slack15.org \
ELILO_CLEANUP_SURVIVOR_INTEGRATION_REVIEW_POLICY_PATH="$meta/policy.json" \
ELILO_CLEANUP_SURVIVOR_INTEGRATION_ACCEPTED_PATH="$meta/accepted.json" \
ELILO_CLEANUP_SURVIVOR_INTEGRATION_CONTRACT_PATH="$meta/contract.json" \
ELILO_CLEANUP_SURVIVOR_INTEGRATION_APPLY_POLICY_PATH="$meta/apply-policy.json" \
bash "$SCRIPT" --target slackware-15.0 \
 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-survivor-authorization-evidence-sha256 "$(printf 'e%.0s' {1..64})" \
 --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-apply-revision-review-sha256 "$scope" --output-dir "$out" > "$TMP/run.log" 2>&1
ok test $? -eq 0
contains 'revision_ready=true' "$out/summary.txt"
contains 'survivor_integration_ready=true' "$out/summary.txt"
contains 'third_attempt_authorized=false' "$out/summary.txt"
contains 'apply_authorized=false' "$out/summary.txt"
contains 'apply_executed=false' "$out/summary.txt"
contains 'pause_safe=true' "$out/summary.txt"
ok cmp -s "$out/packages.before.txt" "$out/packages.after.txt"
ok cmp -s "$out/boot.before.sha256" "$out/boot.after.sha256"
ok cmp -s "$out/modules-active.before.sha256" "$out/modules-active.after.sha256"
ok cmp -s "$out/modules-rollback.before.sha256" "$out/modules-rollback.after.sha256"
ok bash -n "$SCRIPT"
ok bash -n "$APPLY"
contains 'unlink_exact_authorized_survivors' "$APPLY"
contains 'unlink_exact_reviewed_rollback_survivors' "$APPLY"
contains 'ACCEPTED_THIRD_AUTH=' "$APPLY"
contains 'execution_authorized' "$meta/apply-policy.json"

printf 'ELILO survivor-integrated apply revision review harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
