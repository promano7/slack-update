#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REVIEW_SCRIPT=$REPO/tests/acceptance/reference/test-current-rollback-return-verification-closure.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
PASS_COUNT=0
FAILURE_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" >&2; }
check(){ local name=$1; shift; if "$@"; then pass "$name"; else fail "$name"; fi; }
contains(){ grep -Fq -- "$2" "$1"; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }

prepare_case(){
  local name=$1 c root manifest pkg accepted policy script_sha accepted_sha scope fragment
  c=$TMP/$name
  root=$c/root
  mkdir -p "$root"/{boot/grub,etc/grub.d,var/lib/pkgtools/packages,lib/modules/6.18.40/kernel/drivers}
  printf 'active-kernel\n' > "$root/boot/vmlinuz-6.18.42"
  printf 'rollback-kernel\n' > "$root/boot/vmlinuz-6.18.40"
  printf 'active-initrd\n' | gzip -c > "$root/boot/initrd-6.18.42.img"
  printf 'rollback-initrd\n' | gzip -c > "$root/boot/initrd-6.18.40.img"
  ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
  ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
  printf 'module\n' > "$root/lib/modules/6.18.40/kernel/drivers/test.ko"
  printf 'kernel/drivers/test.ko:\n' > "$root/lib/modules/6.18.40/modules.dep"
  printf 'alias synthetic test\n' > "$root/lib/modules/6.18.40/modules.alias"
  printf 'synthetic package\n' > "$root/var/lib/pkgtools/packages/synthetic-1.0-x86_64-1"
  fragment=$root/etc/grub.d/41_slackware_rollback_6_18_40
  cat > "$fragment" <<'EOS'
#!/bin/sh
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id slackware-rollback-6.18.40 {
 linux /boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOS
  chmod 0755 "$fragment"
  cat > "$root/boot/grub/grub.cfg" <<'EOS'
menuentry 'Slackware GNU/Linux' {
 linux /boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-generic.img
}
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id slackware-rollback-6.18.40 {
 linux /boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOS
  : > "$root/boot/grub/grubenv"
  manifest=$c/manifest.txt
  python3 - "$root/lib/modules/6.18.40" "$manifest" <<'PY'
import hashlib,pathlib,stat,sys
r=pathlib.Path(sys.argv[1]); rows=[]
for p in sorted(r.rglob('*'),key=lambda x:x.relative_to(r).as_posix()):
 rel=p.relative_to(r).as_posix()
 if p.is_file() and rel.startswith('kernel/') and rel.endswith(('.ko','.ko.gz','.ko.xz','.ko.zst')):
  rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.stat().st_size}  {oct(stat.S_IMODE(p.stat().st_mode))}  {rel}\n')
pathlib.Path(sys.argv[2]).write_text(''.join(rows))
PY
  pkg=$c/packages.txt
  (cd "$root/var/lib/pkgtools/packages" && sha256sum synthetic-1.0-x86_64-1) > "$pkg"
  accepted=$c/accepted.json
  python3 - "$accepted" "$(sha "$pkg")" "$(sha "$root/boot/vmlinuz-6.18.42")" "$(sha "$root/boot/initrd-6.18.42.img")" "$(sha "$root/boot/vmlinuz-6.18.40")" "$(sha "$root/boot/initrd-6.18.40.img")" "$(sha "$manifest")" "$(sha "$fragment")" <<'PY'
import json,pathlib,sys
out,pkg,ak,ai,rk,ri,manifest,frag=sys.argv[1:]
data={'schema':1,'scenario':'current-rollback-boot-verification-and-return-review','target':'slackware-current','accepted':True,
'archive_sha256':'a'*64,'result':'PASS','passes':5,'failures':0,'skips':0,'hostname_short':'pcold-slack',
'hostname_fqdn':'pcold-slack.pcold-slack.org','active_kernel':'6.18.42','rollback_kernel':'6.18.40',
'boot_authorization_evidence_sha256':'b'*64,'return_review_scope_sha256':'c'*64,'rollback_boot_verified':True,
'return_authorized':True,'return_executed':False,'manual_selection_required':False,'package_database_manifest_sha256':pkg,
'active_kernel_sha256':ak,'active_initrd_sha256':ai,'rollback_kernel_sha256':rk,'rollback_initrd_sha256':ri,
'installed_module_object_manifest_sha256':manifest,'installed_module_object_count':1,'grub_fragment_sha256':frag,
'grub_entry_id':'slackware-rollback-6.18.40','grub_entry_title':'Slackware GNU/Linux (rollback 6.18.40)',
'active_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-generic.img'],
'rollback_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-6.18.40.img'],
'root_source':'/dev/sda2','root_uuid':'ba7632d7-7469-483e-830d-59c88d985866','package_database_mutated':False,
'grub_configuration_mutated':False,'grubenv_mutated':False,'repository_metadata_refreshed':False,'reboot_performed':False,
'next_stage':'current-rollback-return-manual-reboot'}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
  script_sha=$(sha "$REVIEW_SCRIPT"); accepted_sha=$(sha "$accepted")
  scope=$(python3 - "$script_sha" "$accepted_sha" <<'PY'
import hashlib,sys
script,accepted=sys.argv[1:]
s=('operation=current-rollback-return-verification-closure\n' 'target=slackware-current\n'
'hostname_short=pcold-slack\n' 'hostname_fqdn=pcold-slack.pcold-slack.org\n'
'accepted_return_review_archive_sha256='+'a'*64+'\n' 'active_kernel=6.18.42\n' 'rollback_kernel=6.18.40\n'
f'accepted_return_review_record_sha256={accepted}\n' f'closure_script_sha256={script}\n')
print(hashlib.sha256(s.encode()).hexdigest())
PY
)
  policy=$c/policy.json
  python3 - "$policy" "$script_sha" "$accepted_sha" "$scope" <<'PY'
import json,pathlib,sys
out,script,accepted,scope=sys.argv[1:]
data={'schema':1,'scenario':'current-rollback-return-verification-closure','target':'slackware-current','reviewed':True,
'expected_review_script_sha256':script,'accepted_return_review_record_sha256':accepted,
'accepted_return_review_archive_sha256':'a'*64,'confirmation_scope_sha256':scope,'hostname_short':'pcold-slack',
'hostname_fqdn':'pcold-slack.pcold-slack.org','active_kernel':'6.18.42','rollback_kernel':'6.18.40',
'repository_metadata_refresh_allowed':False,'package_database_mutation_allowed':False,'grub_configuration_mutation_allowed':False,
'grubenv_mutation_allowed':False,'reboot_execution_allowed':False,'success_pause_safe':True,'success_current_work_remaining':False,
'success_next_stage':'slackware-15.0-elilo-preflight-repeat-review'}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
  printf '%s|%s|%s|%s|%s|%s\n' "$c" "$root" "$accepted" "$policy" "$scope" "$manifest"
}

run_case(){
  local name=$1 mode=${2:-valid} prepared c root accepted policy scope manifest out log status cmdline running
  prepared=$(prepare_case "$name") || return 1
  IFS='|' read -r c root accepted policy scope manifest <<< "$prepared"
  out=$c/out/evidence
  cmdline='BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro'
  running=6.18.42
  case "$mode" in
    running-rollback) running=6.18.40 ;;
    rollback-boot-image) cmdline='BOOT_IMAGE=/boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro' ;;
    missing-boot-image) cmdline='root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro' ;;
    wrong-root) cmdline='BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=11111111-1111-1111-1111-111111111111 ro' ;;
    generic-link-drift) rm "$root/boot/vmlinuz-generic"; ln -s vmlinuz-6.18.40 "$root/boot/vmlinuz-generic" ;;
    package-change) printf 'changed\n' >> "$root/var/lib/pkgtools/packages/synthetic-1.0-x86_64-1" ;;
    rollback-missing) rm "$root/boot/vmlinuz-6.18.40" ;;
    next-entry) printf 'next_entry=slackware-rollback-6.18.40\n' > "$root/boot/grub/grubenv" ;;
  esac
  log=$c/run.log
  set +e
  SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$root" \
    ROLLBACK_RETURN_CLOSURE_POLICY_PATH="$policy" ROLLBACK_RETURN_CLOSURE_ACCEPTED_RETURN_PATH="$accepted" \
    ROLLBACK_RETURN_CLOSURE_TEST_RUNNING_KERNEL="$running" ROLLBACK_RETURN_CLOSURE_TEST_OSRELEASE="$running" \
    ROLLBACK_RETURN_CLOSURE_TEST_CMDLINE="$cmdline" ROLLBACK_RETURN_CLOSURE_TEST_MODULE_MANIFEST_SHA256="$(sha "$manifest")" \
    ROLLBACK_RETURN_CLOSURE_TEST_MODULE_COUNT=1 \
    bash "$REVIEW_SCRIPT" --target slackware-current --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
      --confirm-return-review-evidence-sha256 "$(printf 'a%.0s' {1..64})" --confirm-active-kernel 6.18.42 --confirm-rollback-kernel 6.18.40 \
      --confirm-closure-sha256 "$scope" --output-dir "$out" > "$log" 2>&1
  status=$?
  set -e
  printf '%s|%s|%s|%s\n' "$c" "$out" "$log" "$status"
}

r=$(run_case valid valid); IFS='|' read -r c o l s <<< "$r"
check 'valid final return verification exits zero' test "$s" -eq 0
check 'valid final return verification reports PASS' contains "$l" 'Result: PASS'
check 'valid final return verifies 6.18.42' contains "$l" 'normal_return_verified=true'
check 'valid final return retains the rollback' contains "$l" 'rollback_retained=true'
check 'valid final return closes the rollback demonstration' contains "$l" 'rollback_boot_demonstration_closed=true'
check 'valid final return is pause-safe' contains "$l" 'pause_safe=true'
check 'valid final return reports no current work remaining' contains "$l" 'current_work_remaining=false'
check 'valid closure routes to Slackware 15 ELILO work' contains "$l" 'next_stage=slackware-15.0-elilo-preflight-repeat-review'
check 'valid closure record exists' test -f "$o/closure.json"
check 'valid closure record marks normal return verified' grep -Fq '"normal_return_verified": true' "$o/closure.json"
check 'valid closure records retained tested rollback' grep -Fq '"rollback_retained": true' "$o/closure.json"
check 'valid runtime command line proves the generic default path' grep -Fq '"normal_default_path_observed": true' "$o/runtime-cmdline.json"
check 'valid before and after sensitive state are identical' cmp -s "$o/sensitive.before.txt" "$o/sensitive.after.txt"
check 'valid before and after package state are identical' cmp -s "$o/packages.before.txt" "$o/packages.after.txt"

check 'production runtime helper defaults to the active kernel' grep -Fq 'ROLLBACK_RETURN_CLOSURE_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE_KERNEL' "$REVIEW_SCRIPT"
check 'production command-line validator rejects missing or non-generic BOOT_IMAGE' grep -Fq "if boot != ['/boot/vmlinuz-generic']" "$REVIEW_SCRIPT"
check 'production command-line validator requires the reviewed root UUID' grep -Fq "if roots != [f'root=UUID={root_uuid}']" "$REVIEW_SCRIPT"
check 'production closure requires the accepted package database hash' grep -Fq '[ "$BEFORE_PACKAGES_SHA256" = "$ACCEPTED_PACKAGE_DB_SHA" ]' "$REVIEW_SCRIPT"
check 'production closure requires the retained rollback kernel file' grep -Fq 'ACCEPTED_ROLLBACK_KERNEL_SHA' "$REVIEW_SCRIPT"
check 'production closure requires the retained rollback initrd file' grep -Fq 'ACCEPTED_ROLLBACK_INITRD_SHA' "$REVIEW_SCRIPT"
check 'production closure requires one unique rollback entry' grep -Fq 'if len(matched)!=1: raise SystemExit(1)' "$REVIEW_SCRIPT"
check 'production closure removes no boot or module artifacts' bash -c '! grep -Eq "^[[:space:]]*(rm|rmdir|unlink)[^#]*(/boot|/lib/modules)" "$1"' _ "$REVIEW_SCRIPT"

check 'production code requires 6.18.42 to be running' grep -Fq '[ "$(runtime_kernel)" = "$CONFIRM_ACTIVE_KERNEL" ]' "$REVIEW_SCRIPT"
check 'production code requires active osrelease' grep -Fq '[ "$(runtime_osrelease)" = "$CONFIRM_ACTIVE_KERNEL" ]' "$REVIEW_SCRIPT"
check 'production code requires the generic BOOT_IMAGE' grep -Fq "if boot != ['/boot/vmlinuz-generic']" "$REVIEW_SCRIPT"
check 'production code verifies retained rollback module manifest' grep -Fq 'ACCEPTED_MODULE_MANIFEST_SHA' "$REVIEW_SCRIPT"
check 'production code preserves generic links on 6.18.42' grep -Fq 'vmlinuz-$CONFIRM_ACTIVE_KERNEL' "$REVIEW_SCRIPT"
check 'production code requires the active entry first' grep -Fq "first_linux[0][0]!='/boot/vmlinuz-generic'" "$REVIEW_SCRIPT"
check 'production code rejects pending next_entry' grep -Fq "! grep -q '^next_entry='" "$REVIEW_SCRIPT"
check 'production code never invokes slackpkg' bash -c '! grep -Eq "(^|[^A-Za-z0-9_-])slackpkg([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code never invokes grub-mkconfig' bash -c '! grep -Eq "^[[:space:]]*grub-mkconfig([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code never invokes a reboot command' bash -c '! grep -Eq "^[[:space:]]*(reboot|shutdown|poweroff)([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code does not set grubenv variables' bash -c '! grep -Eq "grub-editenv[^\n]*(set|unset|create)" "$1"' _ "$REVIEW_SCRIPT"

printf 'Result: %s (%d passes, %d failures)\n' "$([ "$FAILURE_COUNT" -eq 0 ] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
