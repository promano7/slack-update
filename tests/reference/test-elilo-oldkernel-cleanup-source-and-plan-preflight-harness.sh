#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT=$ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-source-and-plan-preflight.sh
PLANNER=$ROOT/tools/reference/kernel-cleanup-plan-reference.sh
DRY=$ROOT/tools/reference/kernel-cleanup-dry-run-reference.sh
KEY=$ROOT/tests/fixtures/reference/keys/slackware-security.gpg.asc
COUNT=0 FAILS=0
pass(){ COUNT=$((COUNT+1)); }
fail(){ COUNT=$((COUNT+1)); FAILS=$((FAILS+1)); printf 'FAIL: %s\n' "$1" >&2; }
ok(){ local m=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$m"; }
bad(){ local m=$1; shift; "$@" >/dev/null 2>&1 && fail "$m" || pass; }
contains(){ grep -Fq -- "$1" "$2" && pass || fail "$3"; }
not_contains(){ grep -Fq -- "$1" "$2" && fail "$3" || pass; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ok 'production script should pass Bash syntax validation' bash -n "$SCRIPT"
ok 'harness should pass Bash syntax validation' bash -n "$0"
not_contains 'slackpkg update' "$SCRIPT" 'source preflight must not refresh Slackpkg metadata'
not_contains 'slackpkg download' "$SCRIPT" 'source preflight must not download packages'
not_contains 'removepkg ' "$SCRIPT" 'source preflight must not remove packages'
not_contains 'installpkg ' "$SCRIPT" 'source preflight must not install packages'
not_contains 'upgradepkg ' "$SCRIPT" 'source preflight must not upgrade packages'
not_contains 'eliloconfig' "$SCRIPT" 'source preflight must not run eliloconfig'
contains 'gpgv ' "$SCRIPT" 'production path must authenticate Slackpkg checksum metadata'
contains 'kernel-cleanup-plan-reference.sh' "$SCRIPT" 'preflight must use the canonical cleanup planner'
contains 'kernel-cleanup-dry-run-reference.sh' "$SCRIPT" 'preflight must use the canonical dry-run executor'
contains 'cleanup_authorized=false' "$SCRIPT" 'preflight must deny cleanup authorization'
contains 'apply_authorized=false' "$SCRIPT" 'preflight must deny apply authorization'

make_root(){
 local r=$1
 mkdir -p "$r"/{etc,var/lib/pkgtools/packages,var/lib/slackpkg,var/cache/packages/patches/packages,boot/efi/EFI/Slackware,boot,lib/modules/5.15.209,lib/modules/5.15.19,var/tmp}
 printf 'Slackware 15.0\n' > "$r/etc/slackware-version"
 ln -s ../lib/pkgtools/packages "$r/var/log" 2>/dev/null || true
 for n in kernel-generic-5.15.209-x86_64-1 kernel-huge-5.15.209-x86_64-1 kernel-modules-5.15.209-x86_64-1 \
          kernel-generic-5.15.19-x86_64-2 kernel-huge-5.15.19-x86_64-2 kernel-modules-5.15.19-x86_64-2 \
          kernel-headers-5.15.209-x86-1 kernel-source-5.15.209-noarch-1; do
  printf 'PACKAGE NAME: %s\nFILE LIST:\ninstall/slack-desc\n' "$n" > "$r/var/lib/pkgtools/packages/$n"
 done
 printf 'elilo-config\n' > "$r/boot/efi/EFI/Slackware/elilo.conf"
 printf 'active-kernel\n' > "$r/boot/vmlinuz-generic-5.15.209"
 printf 'active-initrd\n' > "$r/boot/initrd-generic-5.15.209.gz"
 printf 'rollback-kernel\n' > "$r/boot/vmlinuz-generic-5.15.19"
 printf 'rollback-initrd\n' > "$r/boot/initrd.gz"
 cp "$r/boot/vmlinuz-generic-5.15.209" "$r/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209"
 cp "$r/boot/initrd-generic-5.15.209.gz" "$r/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz"
 cp "$r/boot/vmlinuz-generic-5.15.19" "$r/boot/efi/EFI/Slackware/vmlinuz"
 cp "$r/boot/initrd.gz" "$r/boot/efi/EFI/Slackware/initrd.gz"
 printf 'active-module\n' > "$r/lib/modules/5.15.209/test.ko"
 printf 'rollback-module\n' > "$r/lib/modules/5.15.19/test.ko"
 python3 - "$r" <<'PY'
import io,tarfile,pathlib,sys
r=pathlib.Path(sys.argv[1])
spec={
"kernel-generic-5.15.209-x86_64-1.txz":["boot/vmlinuz-generic-5.15.209"],
"kernel-huge-5.15.209-x86_64-1.txz":["boot/vmlinuz-huge-5.15.209"],
"kernel-modules-5.15.209-x86_64-1.txz":["lib/modules/5.15.209/kernel/test.ko"],
}
for fn,members in spec.items():
 p=r/"var/cache/packages/patches/packages"/fn
 with tarfile.open(p,"w:xz") as t:
  root=tarfile.TarInfo("."); root.type=tarfile.DIRTYPE; root.mode=0o755; t.addfile(root)
  for name in members:
   dirs=pathlib.PurePosixPath(name).parents
   data=(name+"\n").encode()
   ti=tarfile.TarInfo(name); ti.size=len(data); ti.mode=0o644
   t.addfile(ti,io.BytesIO(data))
PY
 : > "$r/var/lib/slackpkg/CHECKSUMS.md5"
 for f in "$r"/var/cache/packages/patches/packages/*.txz; do
  printf '%s  ./patches/packages/%s\n' "$(md5sum "$f"|awk '{print $1}')" "${f##*/}" >> "$r/var/lib/slackpkg/CHECKSUMS.md5"
 done
 printf 'dummy-signature\n' > "$r/var/lib/slackpkg/CHECKSUMS.md5.asc"
}

make_contract(){
 local r=$1 a=$2 p=$3 scope=$4
 python3 - "$ROOT" "$SCRIPT" "$PLANNER" "$DRY" "$KEY" "$r" "$a" "$p" "$scope" <<'PY'
import hashlib,json,pathlib,sys
repo,script,planner,dry,key,r,aout,pout,sout=sys.argv[1:]
r=pathlib.Path(r)
def sh(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def fsha(rel): return sh(r/rel)
names=sorted(p.name for p in (r/"var/lib/pkgtools/packages").iterdir() if p.is_file())
pkgtext="".join(x+"\n" for x in names).encode()
pkgsha=hashlib.sha256(pkgtext).hexdigest()
accepted={
"scenario":"elilo-oldkernel-retention-preflight","target":"slackware-15.0","status":"accepted-mature-retention",
"evidence":{"archive_sha256":"dacf3bf5ecbe1464b9aacd42457f47dcf91d8e79eed61a29bed40173e89c81af"},
"platform":{"hostname":"vbox-slack15.vbox-slack15.org","package_database_configured":"/var/log/packages","package_database_resolved":"/var/lib/pkgtools/packages"},
"kernel":{"active":"5.15.209","rollback":"5.15.19","active_package_records":["kernel-generic-5.15.209-x86_64-1","kernel-huge-5.15.209-x86_64-1","kernel-modules-5.15.209-x86_64-1"],"rollback_package_records":["kernel-generic-5.15.19-x86_64-2","kernel-huge-5.15.19-x86_64-2","kernel-modules-5.15.19-x86_64-2"]},
"elilo":{"config":"/boot/efi/EFI/Slackware/elilo.conf","config_sha256":fsha("boot/efi/EFI/Slackware/elilo.conf"),"active_image":"vmlinuz-generic-5.15.209","active_initrd":"initrd-generic-5.15.209.gz","active_kernel_sha256":fsha("boot/vmlinuz-generic-5.15.209"),"active_initrd_sha256":fsha("boot/initrd-generic-5.15.209.gz"),"rollback_kernel_sha256":fsha("boot/vmlinuz-generic-5.15.19"),"rollback_initrd_sha256":fsha("boot/initrd.gz")},
"immutability":{"package_name_snapshot_sha256":pkgsha},"cleanup_eligible":True,"cleanup_authorized":False}
pathlib.Path(aout).write_text(json.dumps(accepted,sort_keys=True,indent=2)+"\n")
accsha=sh(aout)
scope=("operation=elilo-oldkernel-cleanup-source-and-plan-preflight\n"
"target=slackware-15.0\nhostname_fqdn=vbox-slack15.vbox-slack15.org\n"
"retention_evidence_sha256=dacf3bf5ecbe1464b9aacd42457f47dcf91d8e79eed61a29bed40173e89c81af\n"
"active_kernel=5.15.209\nrollback_kernel=5.15.19\n"
f"accepted_retention_record_sha256={accsha}\nplanner_sha256={sh(planner)}\n"
f"dry_runner_sha256={sh(dry)}\nsigning_key_sha256={sh(key)}\npreflight_script_sha256={sh(script)}\n")
scope_sha=hashlib.sha256(scope.encode()).hexdigest()
policy={"schema":1,"scenario":"elilo-oldkernel-cleanup-source-and-plan-policy","reviewed":True,"target":"slackware-15.0",
"expected_script_sha256":sh(script),"planner_sha256":sh(planner),"dry_runner_sha256":sh(dry),"signing_key_sha256":sh(key),
"accepted_retention_record_sha256":accsha,"confirmation_scope_sha256":scope_sha,
"metadata_primary_fingerprint":"EC5649DA401E22ABFA6736EF6A4463C040102233","cleanup_authorized":False,"apply_authorized":False}
pathlib.Path(pout).write_text(json.dumps(policy,sort_keys=True,indent=2)+"\n")
pathlib.Path(sout).write_text(scope_sha+"\n")
PY
}

R=$TMP/root
make_root "$R"
A=$TMP/accepted.json P=$TMP/policy.json S=$TMP/scope
make_contract "$R" "$A" "$P" "$S"
SCOPE=$(cat "$S")
run_valid(){
 local od=$1; shift
 env SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$R" \
 ELILO_CLEANUP_ACCEPTED_RETENTION_PATH="$A" ELILO_CLEANUP_SOURCE_POLICY_PATH="$P" \
 "$@" "$SCRIPT" --target slackware-15.0 \
 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-retention-evidence-sha256 dacf3bf5ecbe1464b9aacd42457f47dcf91d8e79eed61a29bed40173e89c81af \
 --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-cleanup-plan-review-sha256 "$SCOPE" --output-dir "$od"
}
OUT=$TMP/out-valid
ok 'valid mature ELILO source-and-plan preflight should pass' run_valid "$OUT" env
contains 'source_ready=true' "$OUT/summary.txt" 'valid run should mark source ready'
contains 'plan_ready=true' "$OUT/summary.txt" 'valid run should mark plan ready'
contains 'cleanup_ready=true' "$OUT/summary.txt" 'valid run should mark cleanup ready'
contains 'cleanup_authorized=false' "$OUT/summary.txt" 'valid run must keep cleanup unauthorized'
contains '"status": "simulation-complete"' "$OUT/cleanup-dry-run.json" 'valid run should simulate the cleanup plan'
contains '"commands_executed": []' "$OUT/cleanup-dry-run.json" 'dry run must execute no commands'
contains '"mutations_performed": []' "$OUT/cleanup-dry-run.json" 'dry run must perform no mutations'
ok 'package state should remain byte-identical' cmp -s "$OUT/packages.before.txt" "$OUT/packages.after.txt"
ok 'boot artifact state should remain byte-identical' cmp -s "$OUT/boot.before.sha256" "$OUT/boot.after.sha256"

OUT2=$TMP/out-badsig
bad 'invalid metadata signature should fail closed' run_valid "$OUT2" env ELILO_CLEANUP_TEST_METADATA_SIGNATURE_VALID=false

MISSING=$TMP/cache-missing
cp -a "$R/var/cache/packages" "$MISSING"
rm -f "$MISSING/patches/packages/kernel-huge-5.15.209-x86_64-1.txz"
OUT3=$TMP/out-missing
bad 'missing exact active archive should fail closed' run_valid "$OUT3" env ELILO_CLEANUP_CACHE_ROOT="$MISSING"

OUT4=$TMP/out-kernel
bad 'running-kernel drift should fail closed' run_valid "$OUT4" env ELILO_CLEANUP_TEST_RUNNING_KERNEL=5.15.19

bad 'wrong confirmation scope should fail' env SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$R" \
 ELILO_CLEANUP_ACCEPTED_RETENTION_PATH="$A" ELILO_CLEANUP_SOURCE_POLICY_PATH="$P" \
 "$SCRIPT" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \
 --confirm-retention-evidence-sha256 dacf3bf5ecbe1464b9aacd42457f47dcf91d8e79eed61a29bed40173e89c81af \
 --confirm-active-kernel 5.15.209 --confirm-rollback-kernel 5.15.19 \
 --confirm-cleanup-plan-review-sha256 0000000000000000000000000000000000000000000000000000000000000000 \
 --output-dir "$TMP/out-scope"

printf 'ELILO oldkernel cleanup source-and-plan preflight harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
