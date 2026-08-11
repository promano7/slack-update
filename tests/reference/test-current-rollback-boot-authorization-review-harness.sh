#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
umask 077
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
REVIEW_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-boot-authorization-review.sh
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
    cat > "$fragment" <<'EOF'
#!/bin/sh
cat <<'EOF_ENTRY'
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
 linux /boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOF_ENTRY
EOF
    chmod 0755 "$fragment"
    cat > "$root/boot/grub/grub.cfg" <<'EOF'
menuentry 'Slackware GNU/Linux' --id 'slackware-current' {
 linux /boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-generic.img
}
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
 linux /boot/vmlinuz-6.18.40 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOF
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
    python3 - "$accepted" "$(sha "$package_manifest")" "$(sha "$root/boot/vmlinuz-6.18.42")" "$(sha "$root/boot/initrd-6.18.42.img")" "$(sha "$root/boot/vmlinuz-6.18.40")" "$(sha "$manifest")" "$(sha "$fragment")" <<'PY'
import json,pathlib,sys
out,pkg,ak,ai,rk,manifest,frag=sys.argv[1:]
data={'schema':1,'scenario':'current-rollback-reconstruction-authorized-apply','target':'slackware-current','accepted':True,'archive_sha256':'a'*64,'result':'PASS','passes':13,'failures':0,'active_kernel':'6.18.42','rollback_kernel':'6.18.40','apply_contract_sha256':'b'*64,'apply_scope_sha256':'c'*64,'apply_executed':True,'apply_committed':True,'rollback_complete_on_disk':True,'pause_safe':True,'reboot_performed':False,'reboot_required':False,'package_database_manifest_sha256':pkg,'active_kernel_sha256':ak,'active_initrd_sha256':ai,'rollback_kernel_sha256':rk,'installed_module_object_manifest_sha256':manifest,'installed_module_object_count':1,'grub_fragment_sha256':frag,'grub_entry_id':'slackware-rollback-6.18.40','grub_entry_title':'Slackware GNU/Linux (rollback 6.18.40)','active_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-generic.img'],'rollback_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-6.18.40.img'],'root_uuid':'ba7632d7-7469-483e-830d-59c88d985866','root_source':'/dev/sda2','hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org','next_stage':'current-rollback-reconstruction-boot-test-optional'}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
    script_sha=$(sha "$REVIEW_SCRIPT"); accepted_sha=$(sha "$accepted")
    scope=$(python3 - "$script_sha" "$accepted_sha" <<'PY'
import hashlib,sys
script,accepted=sys.argv[1:]
s=('operation=current-rollback-boot-authorization-review\n' 'target=slackware-current\n' 'hostname_short=pcold-slack\n' 'hostname_fqdn=pcold-slack.pcold-slack.org\n' 'accepted_apply_archive_sha256='+'a'*64+'\n' 'active_kernel=6.18.42\n' 'rollback_kernel=6.18.40\n' f'accepted_apply_record_sha256={accepted}\n' f'boot_review_script_sha256={script}\n')
print(hashlib.sha256(s.encode()).hexdigest())
PY
)
    policy=$case_dir/policy.json
    python3 - "$policy" "$script_sha" "$accepted_sha" "$scope" <<'PY'
import json,pathlib,sys
out,script,accepted,scope=sys.argv[1:]
data={'schema':1,'scenario':'current-rollback-boot-authorization-review','target':'slackware-current','reviewed':True,'expected_review_script_sha256':script,'accepted_apply_record_sha256':accepted,'accepted_apply_archive_sha256':'a'*64,'confirmation_scope_sha256':scope,'hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org','active_kernel':'6.18.42','rollback_kernel':'6.18.40'}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
    printf '%s|%s|%s|%s|%s\n' "$case_dir" "$root" "$accepted" "$policy" "$scope"
}

run_case(){
    trap - EXIT HUP INT TERM
    local name=$1 mode=${2:-valid} prepared case_dir root accepted policy scope output log status
    prepared=$(prepare_case "$name") || return 1
    IFS='|' read -r case_dir root accepted policy scope <<< "$prepared"
    output=$case_dir/out-parent/evidence
    case "$mode" in
      corrupt-kernel) printf 'corrupt\n' >> "$root/boot/vmlinuz-6.18.40" ;;
      duplicate-entry) cat "$root/boot/grub/grub.cfg" >> "$root/boot/grub/grub.cfg.tmp"; cat "$root/boot/grub/grub.cfg.tmp" >> "$root/boot/grub/grub.cfg" ;;
      next-entry) printf 'next_entry=slackware-rollback-6.18.40\n' > "$root/boot/grub/grubenv" ;;
      package-change) printf 'changed\n' >> "$root/var/lib/pkgtools/packages/synthetic-1.0-x86_64-1" ;;
    esac
    log=$case_dir/run.log
    set +e
    SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$root" \
      ROLLBACK_BOOT_POLICY_PATH="$policy" ROLLBACK_BOOT_ACCEPTED_APPLY_PATH="$accepted" \
      ROLLBACK_BOOT_TEST_MODULE_MANIFEST_SHA256="$(sha "$case_dir/manifest.txt")" ROLLBACK_BOOT_TEST_MODULE_COUNT=1 \
      bash "$REVIEW_SCRIPT" --target slackware-current --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
      --confirm-apply-evidence-sha256 "$(printf 'a%.0s' {1..64})" --confirm-active-kernel 6.18.42 --confirm-rollback-kernel 6.18.40 \
      --confirm-boot-review-sha256 "$scope" --output-dir "$output" > "$log" 2>&1
    status=$?
    set -e
    printf '%s|%s|%s|%s\n' "$case_dir" "$output" "$log" "$status"
}

set -e
r=$(run_case valid valid); IFS='|' read -r c o l s <<< "$r"
check 'valid boot review exits zero' test "$s" -eq 0
check 'valid boot review reports PASS' contains "$l" 'Result: PASS'
check 'valid boot review authorizes boot' contains "$l" 'boot_authorized=true'
check 'valid boot review does not execute boot' contains "$l" 'boot_executed=false'
check 'valid authorization record exists' test -f "$o/boot-authorization.json"
check 'authorization requires manual selection' grep -Fq '"manual_selection_required": true' "$o/boot-authorization.json"
check 'authorization records exact rollback entry id' grep -Fq 'slackware-rollback-6.18.40' "$o/boot-authorization.json"
check 'before and after sensitive state are identical' cmp -s "$o/sensitive.before.txt" "$o/sensitive.after.txt"
check 'before and after package state are identical' cmp -s "$o/packages.before.txt" "$o/packages.after.txt"

check 'production code rejects a pending GRUB next_entry' grep -Fq "! grep -q '^next_entry='" "$REVIEW_SCRIPT"
check 'production code rejects a saved rollback entry' grep -Fq 'saved_entry=$ACCEPTED_GRUB_ENTRY_ID' "$REVIEW_SCRIPT"
check 'production code requires one unique rollback menuentry' grep -Fq 'if len(matched)!=1: raise SystemExit(1)' "$REVIEW_SCRIPT"
check 'production code binds the package database to step 89' grep -Fq 'BEFORE_PACKAGES_SHA256" = "$ACCEPTED_PACKAGE_DB_SHA' "$REVIEW_SCRIPT"
check 'production code never invokes slackpkg' bash -c '! grep -Eq "(^|[^A-Za-z0-9_-])slackpkg([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"
check 'production code never invokes a reboot command' bash -c '! grep -Eq "^[[:space:]]*(reboot|shutdown|poweroff)([[:space:]]|$)" "$1"' _ "$REVIEW_SCRIPT"

printf 'Result: %s (%d passes, %d failures)\n' "$([ "$FAILURE_COUNT" -eq 0 ] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
