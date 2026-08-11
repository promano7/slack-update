#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
umask 077
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
REVIEW_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-boot-verification-and-return-review.sh
PASS_COUNT=0
FAILURE_COUNT=0
WORK_ROOT=
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" >&2; }
check(){ local d=$1; shift; if "$@"; then pass "$d"; else fail "$d"; fi; }
contains(){ grep -Fq -- "$2" "$1"; }
cleanup(){ [ -n "$WORK_ROOT" ] && rm -rf -- "$WORK_ROOT"; }
trap cleanup EXIT HUP INT TERM
WORK_ROOT=$(mktemp -d) || exit 1
sha(){ sha256sum -- "$1" | awk '{print $1}'; }

prepare_case(){
    local name=$1 case_dir root accepted policy fragment manifest package_manifest script_sha accepted_sha scope
    case_dir=$WORK_ROOT/$name
    root=$case_dir/root
    install -d -m 0700 "$root/boot/grub" "$root/etc/grub.d" "$root/lib/modules/6.18.40/kernel/drivers" "$root/var/lib/pkgtools/packages" "$case_dir/out-parent"
    printf 'active kernel\n' > "$root/boot/vmlinuz-6.18.42"
    printf 'active initrd\n' | gzip -c > "$root/boot/initrd-6.18.42.img"
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    printf 'rollback kernel\n' > "$root/boot/vmlinuz-6.18.40"
    printf 'rollback initrd\n' | gzip -c > "$root/boot/initrd-6.18.40.img"
    printf 'module\n' > "$root/lib/modules/6.18.40/kernel/drivers/test.ko"
    printf 'kernel/drivers/test.ko:\n' > "$root/lib/modules/6.18.40/modules.dep"
    printf 'alias test test\n' > "$root/lib/modules/6.18.40/modules.alias"
    printf 'PACKAGE NAME: synthetic-1.0-x86_64-1\n' > "$root/var/lib/pkgtools/packages/synthetic-1.0-x86_64-1"
    printf 'intel\n' > "$root/boot/intel-ucode.img"; printf 'amd\n' > "$root/boot/amd-ucode.img"
    fragment=$root/etc/grub.d/41_slackware_rollback_6_18_40
    cat > "$fragment" <<'EOF_FRAGMENT'
#!/bin/sh
cat <<'EOF_ENTRY'
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
 linux /boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOF_ENTRY
EOF_FRAGMENT
    chmod 0755 "$fragment"
    cat > "$root/boot/grub/grub.cfg" <<'EOF_GRUB'
menuentry 'Slackware GNU/Linux' --id 'slackware-current' {
 linux /boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-generic.img
}
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
 linux /boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOF_GRUB
    : > "$root/boot/grub/grubenv"
    manifest=$case_dir/manifest.txt
    python3 - "$root/lib/modules/6.18.40" "$manifest" <<'PY'
import hashlib,pathlib,stat,sys
r=pathlib.Path(sys.argv[1]); rows=[]
for p in sorted(r.rglob('*'),key=lambda x:x.relative_to(r).as_posix()):
 rel=p.relative_to(r).as_posix()
 if p.is_file() and rel.startswith('kernel/') and rel.endswith(('.ko','.ko.gz','.ko.xz','.ko.zst')):
  rows.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.stat().st_size}  {oct(stat.S_IMODE(p.stat().st_mode))}  {rel}\n')
pathlib.Path(sys.argv[2]).write_text(''.join(rows))
PY
    package_manifest=$case_dir/packages.txt
    (cd "$root/var/lib/pkgtools/packages" && sha256sum synthetic-1.0-x86_64-1) > "$package_manifest"
    accepted=$case_dir/accepted.json
    python3 - "$accepted" "$(sha "$package_manifest")" "$(sha "$root/boot/vmlinuz-6.18.42")" "$(sha "$root/boot/initrd-6.18.42.img")" "$(sha "$root/boot/vmlinuz-6.18.40")" "$(sha "$root/boot/initrd-6.18.40.img")" "$(sha "$manifest")" "$(sha "$fragment")" <<'PY'
import json,pathlib,sys
out,pkg,ak,ai,rk,ri,manifest,frag=sys.argv[1:]
data={'schema':1,'scenario':'current-rollback-boot-authorization-review','target':'slackware-current','accepted':True,
'archive_sha256':'a'*64,'result':'PASS','passes':5,'failures':0,'skips':0,'hostname_short':'pcold-slack',
'hostname_fqdn':'pcold-slack.pcold-slack.org','active_kernel':'6.18.42','rollback_kernel':'6.18.40',
'boot_review_scope_sha256':'b'*64,'boot_authorized':True,'boot_executed':False,'manual_selection_required':True,
'package_database_manifest_sha256':pkg,'active_kernel_sha256':ak,'active_initrd_sha256':ai,'rollback_kernel_sha256':rk,
'rollback_initrd_sha256':ri,'installed_module_object_manifest_sha256':manifest,'installed_module_object_count':1,
'grub_fragment_sha256':frag,'grub_entry_id':'slackware-rollback-6.18.40','grub_entry_title':'Slackware GNU/Linux (rollback 6.18.40)',
'active_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-generic.img'],
'rollback_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-6.18.40.img'],
'root_source':'/dev/sda2','root_uuid':'ba7632d7-7469-483e-830d-59c88d985866','package_database_mutated':False,
'grub_configuration_mutated':False,'grubenv_mutated':False,'repository_metadata_refreshed':False,'reboot_performed':False,
'next_stage':'current-rollback-boot-test-manual-reboot'}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
    script_sha=$(sha "$REVIEW_SCRIPT"); accepted_sha=$(sha "$accepted")
    scope=$(python3 - "$script_sha" "$accepted_sha" <<'PY'
import hashlib,sys
script,accepted=sys.argv[1:]
s=('operation=current-rollback-boot-verification-and-return-review\n' 'target=slackware-current\n' 'hostname_short=pcold-slack\n' 'hostname_fqdn=pcold-slack.pcold-slack.org\n' 'accepted_boot_authorization_archive_sha256='+'a'*64+'\n' 'active_kernel=6.18.42\n' 'rollback_kernel=6.18.40\n' f'accepted_boot_authorization_record_sha256={accepted}\n' f'return_review_script_sha256={script}\n')
print(hashlib.sha256(s.encode()).hexdigest())
PY
)
    policy=$case_dir/policy.json
    python3 - "$policy" "$script_sha" "$accepted_sha" "$scope" <<'PY'
import json,pathlib,sys
out,script,accepted,scope=sys.argv[1:]
data={'schema':1,'scenario':'current-rollback-boot-verification-and-return-review','target':'slackware-current','reviewed':True,
'expected_review_script_sha256':script,'accepted_boot_authorization_record_sha256':accepted,
'accepted_boot_authorization_archive_sha256':'a'*64,'confirmation_scope_sha256':scope,'hostname_short':'pcold-slack',
'hostname_fqdn':'pcold-slack.pcold-slack.org','active_kernel':'6.18.42','rollback_kernel':'6.18.40'}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
    printf '%s|%s|%s|%s|%s|%s\n' "$case_dir" "$root" "$accepted" "$policy" "$scope" "$manifest"
}

run_case(){
    trap - EXIT HUP INT TERM
    local name=$1 mode=${2:-valid} prepared case_dir root accepted policy scope manifest output log status cmdline running
    prepared=$(prepare_case "$name") || return 1
    IFS='|' read -r case_dir root accepted policy scope manifest <<< "$prepared"
    output=$case_dir/out-parent/evidence
    cmdline='BOOT_IMAGE=/boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro'
    running=6.18.40
    case "$mode" in
      running-active) running=6.18.42 ;;
      wrong-boot-image) cmdline='BOOT_IMAGE=/boot/vmlinuz-6.18.42 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro' ;;
      missing-boot-image) cmdline='root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro' ;;
      wrong-root) cmdline='BOOT_IMAGE=/boot/vmlinuz-6.18.40 root=UUID=11111111-1111-1111-1111-111111111111 ro' ;;
      corrupt-kernel) printf 'corrupt\n' >> "$root/boot/vmlinuz-6.18.40" ;;
      generic-link-drift) rm "$root/boot/vmlinuz-generic"; ln -s vmlinuz-6.18.40 "$root/boot/vmlinuz-generic" ;;
      package-change) printf 'changed\n' >> "$root/var/lib/pkgtools/packages/synthetic-1.0-x86_64-1" ;;
      next-entry) printf 'next_entry=slackware-rollback-6.18.40\n' > "$root/boot/grub/grubenv" ;;
      rollback-first)
        python3 - "$root/boot/grub/grub.cfg" <<'PY'
import pathlib,sys
p=pathlib.Path(sys.argv[1]); s=p.read_text(); parts=s.split("menuentry 'Slackware GNU/Linux (rollback 6.18.40)'",1)
active=parts[0]; rest="menuentry 'Slackware GNU/Linux (rollback 6.18.40)'"+parts[1]
p.write_text(rest+'\n'+active)
PY
        ;;
    esac
    log=$case_dir/run.log
    set +e
    SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$root" \
      ROLLBACK_BOOT_VERIFY_POLICY_PATH="$policy" ROLLBACK_BOOT_VERIFY_ACCEPTED_AUTH_PATH="$accepted" \
      ROLLBACK_BOOT_VERIFY_TEST_RUNNING_KERNEL="$running" ROLLBACK_BOOT_VERIFY_TEST_OSRELEASE="$running" \
      ROLLBACK_BOOT_VERIFY_TEST_CMDLINE="$cmdline" ROLLBACK_BOOT_VERIFY_TEST_MODULE_MANIFEST_SHA256="$(sha "$manifest")" \
      ROLLBACK_BOOT_VERIFY_TEST_MODULE_COUNT=1 ROLLBACK_BOOT_VERIFY_TEST_VERMAGIC='6.18.40 SMP preempt mod_unload' \
      bash "$REVIEW_SCRIPT" --target slackware-current --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
      --confirm-boot-authorization-evidence-sha256 "$(printf 'a%.0s' {1..64})" --confirm-active-kernel 6.18.42 --confirm-rollback-kernel 6.18.40 \
      --confirm-return-review-sha256 "$scope" --output-dir "$output" > "$log" 2>&1
    status=$?
    set -e
    printf '%s|%s|%s|%s\n' "$case_dir" "$output" "$log" "$status"
}

set -e
r=$(run_case valid valid); IFS='|' read -r c o l s <<< "$r"
check 'valid rollback verification exits zero' test "$s" -eq 0
check 'valid rollback verification reports PASS' contains "$l" 'Result: PASS'
check 'valid rollback verification proves the real rollback boot' contains "$l" 'rollback_boot_verified=true'
check 'valid rollback verification authorizes the normal return' contains "$l" 'return_authorized=true'
check 'valid rollback verification does not execute the return' contains "$l" 'return_executed=false'
check 'valid rollback verification requires no manual selection for return' contains "$l" 'manual_selection_required=false'
check 'valid return authorization record exists' test -f "$o/return-authorization.json"
check 'valid return authorization expects 6.18.42' grep -Fq '"expected_return_kernel": "6.18.42"' "$o/return-authorization.json"
check 'valid runtime command line was recorded' test -f "$o/runtime-cmdline.json"
check 'valid module vermagic was recorded' grep -Fq '6.18.40' "$o/module-vermagic.txt"
check 'before and after sensitive state are identical' cmp -s "$o/sensitive.before.txt" "$o/sensitive.after.txt"
check 'before and after package state are identical' cmp -s "$o/packages.before.txt" "$o/packages.after.txt"

check 'production command-line validation accepts an absent BOOT_IMAGE but rejects a conflicting one' grep -Fq "if boot and not boot[0].endswith(f'/vmlinuz-{rollback}')" "$REVIEW_SCRIPT"
check 'production command-line validation requires the reviewed root UUID' grep -Fq "if roots != [f'root=UUID={root_uuid}']" "$REVIEW_SCRIPT"
check 'production code verifies the exact rollback kernel hash' grep -Fq 'ACCEPTED_ROLLBACK_KERNEL_SHA' "$REVIEW_SCRIPT"
check 'production code preserves generic links on the active kernel' grep -Fq 'vmlinuz-$CONFIRM_ACTIVE_KERNEL' "$REVIEW_SCRIPT"
check 'production code requires the active entry to remain first' grep -Fq "first_linux[0][0]!='/boot/vmlinuz-generic'" "$REVIEW_SCRIPT"
check 'production code requires one unique rollback entry' grep -Fq 'if len(matched)!=1: raise SystemExit(1)' "$REVIEW_SCRIPT"
check 'production code binds the package database to the accepted authorization' grep -Fq 'BEFORE_PACKAGES_SHA256" = "$ACCEPTED_PACKAGE_DB_SHA' "$REVIEW_SCRIPT"

check 'production code requires the rollback kernel to be running' grep -Fq '[ "$(runtime_kernel)" = "$CONFIRM_ROLLBACK_KERNEL" ]' "$REVIEW_SCRIPT"
check 'production code verifies kernel osrelease' grep -Fq '[ "$(runtime_osrelease)" = "$CONFIRM_ROLLBACK_KERNEL" ]' "$REVIEW_SCRIPT"
check 'production code verifies module vermagic' grep -Fq 'validate_module_vermagic' "$REVIEW_SCRIPT"
check 'production code rejects a pending GRUB next_entry' grep -Fq "! grep -q '^next_entry='" "$REVIEW_SCRIPT"
check 'production code never invokes slackpkg' bash -c '! grep -Eq "(^|[^A-Za-z0-9_-])slackpkg([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code never invokes grub-mkconfig' bash -c '! grep -Eq "^[[:space:]]*grub-mkconfig([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code never invokes a reboot command' bash -c '! grep -Eq "^[[:space:]]*(reboot|shutdown|poweroff)([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code does not set grubenv variables' bash -c '! grep -Eq "grub-editenv[^\n]*(set|unset|create)" "$1"' _ "$REVIEW_SCRIPT"

printf 'Result: %s (%d passes, %d failures)\n' "$([ "$FAILURE_COUNT" -eq 0 ] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
