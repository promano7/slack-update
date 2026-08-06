#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
APPLY_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-authorized-apply.sh
PASS_COUNT=0
FAILURE_COUNT=0
WORK_ROOT=

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
check() { local description=$1; shift; if "$@"; then pass "$description"; else fail "$description"; fi; }
contains() { grep -Fq -- "$2" "$1"; }
not_contains() { ! grep -Fq -- "$2" "$1"; }
not_match() { ! grep -Eq -- "$2" "$1"; }

cleanup() { [ "${KEEP_WORK:-0}" = 1 ] && { printf 'WORK_ROOT=%s\n' "$WORK_ROOT"; return; }; [ -n "$WORK_ROOT" ] && rm -rf -- "$WORK_ROOT"; }
trap cleanup EXIT HUP INT TERM
WORK_ROOT=$(mktemp -d) || exit 1

make_executable() { chmod 0755 "$@"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

write_mock_commands() {
    local case_dir=$1 bin=$case_dir/bin
    install -d -m 0700 "$bin"
    cat > "$bin/mock-auth-review" <<'MOCK'
#!/bin/bash
set -u
out=
pkg=
sig=
contract=${MOCK_APPLY_CONTRACT_SHA256:?}
while [ "$#" -gt 0 ]; do
 case "$1" in
  --output-dir) out=$2; shift 2 ;;
  --source-package) pkg=$2; shift 2 ;;
  --source-signature) sig=$2; shift 2 ;;
  *) shift ;;
 esac
done
[ "${MOCK_AUTH_FAIL:-0}" = 0 ] || exit 1
install -d -m 0700 "$out/nested-source-and-plan-preflight"
cp -- "$MOCK_SOURCE_MANIFEST" "$out/nested-source-and-plan-preflight/source-module-manifest.txt"
cp -- "$MOCK_GRUB_FRAGMENT" "$out/nested-source-and-plan-preflight/projected-41_slackware_rollback_6_18_40"
cat > "$out/summary.txt" <<EOF_SUMMARY
result=PASS
failures=0
apply_ready=true
apply_authorized=true
apply_executed=false
apply_contract_sha256=$contract
EOF_SUMMARY
python3 - "$out/apply-authorization.json" "$contract" "$pkg" "$sig" <<'PY'
import json,pathlib,sys
pathlib.Path(sys.argv[1]).write_text(json.dumps({
 'apply_ready':True,'apply_authorized':True,'apply_executed':False,
 'apply_contract_sha256':sys.argv[2],
 'source_package':{'path':sys.argv[3]},'source_signature':{'path':sys.argv[4]},
 'fresh_review':{'fresh_preflight_result':'PASS','system_state_mutated':False},
},sort_keys=True)+'\n')
PY
MOCK
    cat > "$bin/mock-depmod" <<'MOCK'
#!/bin/bash
set -u
[ "${MOCK_DEPMOD_FAIL:-0}" = 0 ] || exit 1
version=${@: -1}
root=${TEST_ROOT:?}/lib/modules/$version
printf 'kernel/drivers/test.ko:\n' > "$root/modules.dep"
printf 'alias test test\n' > "$root/modules.alias"
exit 0
MOCK
    cat > "$bin/mock-mkinitrd" <<'MOCK'
#!/bin/bash
set -u
out=
while [ "$#" -gt 0 ]; do
 if [ "$1" = -o ]; then out=$2; shift 2; else shift; fi
done
[ -n "$out" ] || exit 2
printf 'synthetic initrd\n' | gzip -c > "$out"
[ "${MOCK_MKINITRD_FAIL:-0}" = 0 ] || exit 1
MOCK
    cat > "$bin/mock-grub-mkconfig" <<'MOCK'
#!/bin/bash
set -u
out=
while [ "$#" -gt 0 ]; do
 if [ "$1" = -o ]; then out=$2; shift 2; else shift; fi
done
[ "${MOCK_GRUB_MKCONFIG_FAIL:-0}" = 0 ] || exit 1
if [ "${MOCK_GRUB_MODE:-valid}" = wrong ]; then rollback_initrd=/boot/initrd-generic.img; else rollback_initrd=/boot/initrd-6.18.40.img; fi
cat > "$out" <<EOF_GRUB
menuentry 'Slackware GNU/Linux' --id 'slackware-current' {
 linux /boot/vmlinuz-generic root=UUID=test ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-generic.img
}
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
 linux /boot/vmlinuz-6.18.40 root=UUID=test ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img $rollback_initrd
}
EOF_GRUB
MOCK
    cat > "$bin/mock-grub-script-check" <<'MOCK'
#!/bin/bash
[ "${MOCK_GRUB_CHECK_FAIL:-0}" = 0 ]
MOCK
    make_executable "$bin"/*
}

prepare_case() {
    local name=$1 case_dir root source_dir pkgroot
    case_dir=$WORK_ROOT/$name
    root=$case_dir/root
    source_dir=$case_dir/source
    pkgroot=$case_dir/pkgroot
    install -d -m 0700 "$root/boot/grub" "$root/etc/grub.d" "$root/lib/modules/6.18.40/misc" \
        "$root/var/lib/pkgtools/packages" "$root/boot/initrd-tree/etc" "$source_dir" "$pkgroot/boot" "$pkgroot/lib/modules/6.18.40/kernel/drivers"
    printf 'active kernel\n' > "$root/boot/vmlinuz-6.18.42"
    printf 'preserved initrd tree\n' > "$root/boot/initrd-tree/etc/preserved"
    printf 'active initrd\n' | gzip -c > "$root/boot/initrd-6.18.42.img"
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    printf '' > "$root/lib/modules/6.18.40/modules.dep"
    printf '' > "$root/lib/modules/6.18.40/modules.alias"
    cat > "$root/boot/grub/grub.cfg" <<'EOF_GRUB'
menuentry 'Slackware GNU/Linux' --id 'slackware-current' {
 linux /boot/vmlinuz-generic root=UUID=test ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-generic.img
}
EOF_GRUB
    printf 'PACKAGE NAME: synthetic-1.0-x86_64-1\n' > "$root/var/lib/pkgtools/packages/synthetic-1.0-x86_64-1"
    printf 'rollback kernel\n' > "$pkgroot/boot/vmlinuz-6.18.40"
    printf 'module object\n' > "$pkgroot/lib/modules/6.18.40/kernel/drivers/test.ko"
    printf 'builtin metadata\n' > "$pkgroot/lib/modules/6.18.40/modules.builtin"
    tar --owner=0 --group=0 -cJf "$source_dir/kernel-generic-6.18.40-x86_64-1.txz" -C "$pkgroot" boot lib
    printf 'synthetic detached signature\n' > "$source_dir/kernel-generic-6.18.40-x86_64-1.txz.asc"
    python3 - "$pkgroot/lib/modules/6.18.40" "$case_dir/source-module-manifest.txt" <<'PY'
import hashlib,pathlib,stat,sys
root=pathlib.Path(sys.argv[1]); rows=[]
for p in sorted(root.rglob('*'),key=lambda x:x.relative_to(root).as_posix()):
 if p.is_file() and not p.is_symlink():
  data=p.read_bytes(); st=p.stat(); rows.append(f'{hashlib.sha256(data).hexdigest()}  {st.st_size}  {oct(stat.S_IMODE(st.st_mode))}  {p.relative_to(root).as_posix()}\n')
pathlib.Path(sys.argv[2]).write_text(''.join(rows))
PY
    cat > "$case_dir/grub-fragment" <<'EOF_FRAGMENT'
#!/bin/sh
cat <<'EOF_ENTRY'
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
 linux /boot/vmlinuz-6.18.40 root=UUID=test ro
 initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOF_ENTRY
EOF_FRAGMENT
    chmod 0755 "$case_dir/grub-fragment"
    write_mock_commands "$case_dir"
    printf '{}\n' > "$case_dir/review-policy.json"
    local package signature
    package=$source_dir/kernel-generic-6.18.40-x86_64-1.txz
    signature=$package.asc
    local package_sha signature_sha kernel_sha kernel_size manifest_sha fragment_sha active_kernel_sha active_initrd_sha review_script_sha review_policy_sha apply_script_sha
    package_sha=$(sha "$package"); signature_sha=$(sha "$signature"); kernel_sha=$(sha "$pkgroot/boot/vmlinuz-6.18.40")
    kernel_size=$(stat -c %s "$pkgroot/boot/vmlinuz-6.18.40"); manifest_sha=$(sha "$case_dir/source-module-manifest.txt")
    fragment_sha=$(sha "$case_dir/grub-fragment"); active_kernel_sha=$(sha "$root/boot/vmlinuz-6.18.42"); active_initrd_sha=$(sha "$root/boot/initrd-6.18.42.img")
    review_script_sha=$(sha "$case_dir/bin/mock-auth-review"); review_policy_sha=$(sha "$case_dir/review-policy.json"); apply_script_sha=$(sha "$APPLY_SCRIPT")
    python3 - "$case_dir/accepted.json" "$package" "$signature" "$package_sha" "$signature_sha" "$kernel_sha" "$kernel_size" "$manifest_sha" "$fragment_sha" <<'PY'
import json,pathlib,sys
out,pkg,sig,pkgsha,sigsha,ksha,ksize,msha,fsha=sys.argv[1:]
data={
 'schema':1,'scenario':'current-rollback-reconstruction-authorized-apply-review','target':'slackware-current','accepted':True,
 'archive_sha256':'a'*64,'hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org',
 'active_kernel':'6.18.42','rollback_kernel':'6.18.40','source_plan_evidence_sha256':'b'*64,
 'authorization_review_scope_sha256':'c'*64,'apply_contract_sha256':'d'*64,
 'source':{'package_path':pkg,'package_sha256':pkgsha,'signature_path':sig,'signature_sha256':sigsha},
 'payload':{'kernel_member':'boot/vmlinuz-6.18.40','kernel_destination':'/boot/vmlinuz-6.18.40','kernel_sha256':ksha,'kernel_size':int(ksize),
            'module_destination':'/lib/modules/6.18.40','module_member_count':2,'module_object_count':1,'module_payload_bytes':30,'module_manifest_sha256':msha},
 'initrd':{'destination':'/boot/initrd-6.18.40.img','command_vector':['mkinitrd','-c','-k','6.18.40','-f','ext4','-r','/dev/test','-m','test','-u','-o','/boot/initrd-6.18.40.img']},
 'grub':{'fragment_destination':'/etc/grub.d/41_slackware_rollback_6_18_40','fragment_mode':'0755','fragment_sha256':fsha,
         'entry_id':'slackware-rollback-6.18.40','default_must_remain':'0',
         'source_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-generic.img'],
         'projected_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-6.18.40.img']},
 'backup_root':'/var/lib/slack-update/rollback-backups/6.18.40','stage_root':'/var/tmp/slack-update-rollback-apply/6.18.40',
 'apply_ready':True,'apply_authorized':True,'apply_executed':False,'next_stage':'current-rollback-reconstruction-authorized-apply'
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
    local accepted_sha scope
    accepted_sha=$(sha "$case_dir/accepted.json")
    scope=$(python3 - "$apply_script_sha" "$accepted_sha" "$package" "$signature" <<'PY'
import hashlib,sys
script,accepted,pkg,sig=sys.argv[1:]
s=(
'operation=current-rollback-reconstruction-authorized-apply\n'
' target=slackware-current\n'
).replace(' target','target')
s+=('hostname_short=pcold-slack\n'
'hostname_fqdn=pcold-slack.pcold-slack.org\n'
'authorization_evidence_sha256='+'a'*64+'\n'
'active_kernel=6.18.42\nrollback_kernel=6.18.40\n'
'apply_contract_sha256='+'d'*64+'\n'
f'accepted_authorization_record_sha256={accepted}\n'
f'authorized_apply_script_sha256={script}\n'
f'source_package={pkg}\nsource_signature={sig}\n')
print(hashlib.sha256(s.encode()).hexdigest())
PY
    )
    python3 - "$case_dir/policy.json" "$accepted_sha" "$review_script_sha" "$review_policy_sha" "$apply_script_sha" "$scope" "$active_kernel_sha" "$active_initrd_sha" <<'PY'
import json,pathlib,sys
out,accepted,review_script,review_policy,apply_script,scope,active_kernel,active_initrd=sys.argv[1:]
data={
 'schema':1,'scenario':'current-rollback-reconstruction-authorized-apply','target':'slackware-current','reviewed':True,
 'hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org','active_kernel':'6.18.42','rollback_kernel':'6.18.40',
 'accepted_authorization_archive_sha256':'a'*64,'accepted_authorization_record_sha256':accepted,
 'authorization_review_script_sha256':review_script,'authorization_review_policy_sha256':review_policy,
 'source_plan_evidence_sha256':'b'*64,'authorization_review_scope_sha256':'c'*64,'apply_contract_sha256':'d'*64,
 'expected_apply_script_sha256':apply_script,'confirmation_scope_sha256':scope,
 'active_kernel_sha256':active_kernel,'active_initrd_sha256':active_initrd,
 'backup_root':'/var/lib/slack-update/rollback-backups/6.18.40','stage_root':'/var/tmp/slack-update-rollback-apply/6.18.40',
 'repository_metadata_refresh_allowed':False,'package_installation_allowed':False,'package_database_mutation_allowed':False,'reboot_execution_allowed':False,
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
    printf '%s\n' "$case_dir"
}

run_case() {
    local name=$1 mode=${2:-valid} case_dir root package signature output status=0
    case_dir=$(prepare_case "$name") || return 1
    root=$case_dir/root
    package=$case_dir/source/kernel-generic-6.18.40-x86_64-1.txz
    signature=$package.asc
    output=$case_dir/output.txt
    if [ "$mode" = source-altered ]; then printf "altered\n" >> "$package"; fi
    TEST_ROOT=$root \
    MOCK_SOURCE_MANIFEST=$case_dir/source-module-manifest.txt \
    MOCK_GRUB_FRAGMENT=$case_dir/grub-fragment \
    MOCK_APPLY_CONTRACT_SHA256=$(printf 'd%.0s' {1..64}) \
    MOCK_AUTH_FAIL=$([ "$mode" = auth-fail ] && echo 1 || echo 0) \
    MOCK_DEPMOD_FAIL=$([ "$mode" = depmod-fail ] && echo 1 || echo 0) \
    MOCK_MKINITRD_FAIL=$([ "$mode" = mkinitrd-fail ] && echo 1 || echo 0) \
    MOCK_GRUB_MKCONFIG_FAIL=$([ "$mode" = grub-generate-fail ] && echo 1 || echo 0) \
    MOCK_GRUB_MODE=$([ "$mode" = grub-wrong ] && echo wrong || echo valid) \
    SLACK_UPDATE_TEST_MODE=1 \
    ROLLBACK_APPLY_ROOT_PREFIX=$root \
    ROLLBACK_APPLY_OUTPUT_ROOT=$case_dir/evidence-root \
    ROLLBACK_APPLY_POLICY=$case_dir/policy.json \
    ROLLBACK_APPLY_ACCEPTED_AUTH_REVIEW=$case_dir/accepted.json \
    ROLLBACK_APPLY_AUTH_REVIEW_SCRIPT=$case_dir/bin/mock-auth-review \
    ROLLBACK_APPLY_AUTH_REVIEW_POLICY=$case_dir/review-policy.json \
    ROLLBACK_APPLY_DEPMOD_COMMAND=$case_dir/bin/mock-depmod \
    ROLLBACK_APPLY_MKINITRD_COMMAND=$case_dir/bin/mock-mkinitrd \
    ROLLBACK_APPLY_GRUB_MKCONFIG_COMMAND=$case_dir/bin/mock-grub-mkconfig \
    ROLLBACK_APPLY_GRUB_SCRIPT_CHECK_COMMAND=$case_dir/bin/mock-grub-script-check \
    ROLLBACK_APPLY_TEST_RUNNING_KERNEL=6.18.42 \
    bash "$APPLY_SCRIPT" \
      --target slackware-current --execute-authorized-apply \
      --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
      --confirm-authorization-evidence-sha256 "$(printf 'a%.0s' {1..64})" \
      --confirm-active-kernel 6.18.42 --confirm-rollback-kernel 6.18.40 \
      --confirm-apply-contract-sha256 "$(printf 'd%.0s' {1..64})" \
      --confirm-apply-scope-sha256 "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["confirmation_scope_sha256"])' "$case_dir/policy.json")" \
      --source-package "$package" --source-signature "$signature" > "$output" 2>&1 || status=$?
    printf '%s\t%s\t%s\n' "$case_dir" "$status" "$output"
}

check "bash syntax" bash -n "$APPLY_SCRIPT"
check "help describes pause safety" bash -c '"$1" --help | grep -q "pause_safe=true"' _ "$APPLY_SCRIPT"
check "explicit execution flag is mandatory" bash -c '! "$1" --target slackware-current >/dev/null 2>&1' _ "$APPLY_SCRIPT"
check "no Slackware metadata refresh command" not_contains "$APPLY_SCRIPT" "slackpkg update"
check "no historical package installation command" not_contains "$APPLY_SCRIPT" "installpkg "
check "no reboot command" not_match "$APPLY_SCRIPT" "^[[:space:]]*(reboot|shutdown|poweroff|systemctl[[:space:]]+reboot)([[:space:]]|$)"
check "generic kernel link is never replaced" not_contains "$APPLY_SCRIPT" "ln -sf"
check "signal traps are installed" contains "$APPLY_SCRIPT" "handle_signal"
check "failed transactions invoke rollback" contains "$APPLY_SCRIPT" "rollback_transaction"
check "successful commit requires pause safety" contains "$APPLY_SCRIPT" "rollback-complete-on-disk-and-6.18.42-remains-running-and-default"

IFS=$'\t' read -r positive_dir positive_status positive_output < <(run_case positive valid)
check "positive case exits zero" test "$positive_status" -eq 0
check "positive case reports PASS" contains "$positive_output" "Result: PASS"
check "positive case reports pause_safe=true" contains "$positive_output" "pause_safe=true"
check "positive case commits the apply" contains "$positive_output" "apply_committed=true"
check "rollback kernel exists" test -f "$positive_dir/root/boot/vmlinuz-6.18.40"
check "rollback initrd exists" test -f "$positive_dir/root/boot/initrd-6.18.40.img"
check "rollback fragment exists" test -x "$positive_dir/root/etc/grub.d/41_slackware_rollback_6_18_40"
check "rollback module object exists" test -f "$positive_dir/root/lib/modules/6.18.40/kernel/drivers/test.ko"
check "active generic kernel link is unchanged" test "$(readlink "$positive_dir/root/boot/vmlinuz-generic")" = vmlinuz-6.18.42
check "active generic initrd link is unchanged" test "$(readlink "$positive_dir/root/boot/initrd-generic.img")" = initrd-6.18.42.img
check "GRUB keeps the active entry first" bash -c 'grep -n "menuentry" "$1" | head -n1 | grep -q "Slackware GNU/Linux"' _ "$positive_dir/root/boot/grub/grub.cfg"
check "GRUB contains one rollback identifier" bash -c 'test "$(grep -c "slackware-rollback-6.18.40" "$1")" -eq 1' _ "$positive_dir/root/boot/grub/grub.cfg"
check "owner-only backup remains" test "$(stat -c %a "$positive_dir/root/var/lib/slack-update/rollback-backups/6.18.40")" = 700
check "positive case restores the original initrd tree" bash -c 'test "$(cat "$1")" = "preserved initrd tree"' _ "$positive_dir/root/boot/initrd-tree/etc/preserved"

for mode in depmod-fail mkinitrd-fail grub-generate-fail grub-wrong; do
    IFS=$'\t' read -r case_dir status output < <(run_case "$mode" "$mode")
    check "$mode exits nonzero" test "$status" -ne 0
    check "$mode reports pause_safe=true after rollback" contains "$output" "pause_safe=true"
    check "$mode reports rollback restoration" contains "$output" "rolled back to the exact captured 6.18.42 baseline"
    check "$mode removes rollback kernel" test ! -e "$case_dir/root/boot/vmlinuz-6.18.40"
    check "$mode removes rollback initrd" test ! -e "$case_dir/root/boot/initrd-6.18.40.img"
    check "$mode removes rollback fragment" test ! -e "$case_dir/root/etc/grub.d/41_slackware_rollback_6_18_40"
    check "$mode restores metadata placeholder" test -f "$case_dir/root/lib/modules/6.18.40/modules.dep"
    check "$mode preserves active generic kernel link" test "$(readlink "$case_dir/root/boot/vmlinuz-generic")" = vmlinuz-6.18.42
    check "$mode restores the original initrd tree" bash -c 'test "$(cat "$1")" = "preserved initrd tree"' _ "$case_dir/root/boot/initrd-tree/etc/preserved"
done

for mode in auth-fail source-altered; do
    IFS=$'\t' read -r case_dir status output < <(run_case "$mode" "$mode")
    check "$mode exits nonzero" test "$status" -ne 0
    check "$mode reports pause_safe=true without mutation" contains "$output" "pause_safe=true"
    check "$mode reports the unchanged pre-apply baseline" contains "$output" "rejected pre-apply attempt left the exact 6.18.42 baseline unchanged"
    check "$mode does not create rollback kernel" test ! -e "$case_dir/root/boot/vmlinuz-6.18.40"
    check "$mode does not create the transaction backup" test ! -e "$case_dir/root/var/lib/slack-update/rollback-backups/6.18.40"
done

printf 'Result: %s (%d passes, %d failures)\n' "$([ "$FAILURE_COUNT" -eq 0 ] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
