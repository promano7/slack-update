#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-authorized-apply-review.sh
SOURCE_PLAN_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-source-and-plan-preflight.sh
FIXTURE_PACKAGE=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/test-kernel-generic-6.18.40-x86_64-1.txz
FIXTURE_SIGNATURE=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/test-kernel-generic-6.18.40-x86_64-1.txz.asc
PRODUCTION_ACCEPTED=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-20260806-accepted.json
PRODUCTION_POLICY=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-authorized-apply-review-policy.json
PRODUCTION_SOURCE_POLICY=$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-policy.json

PASS_COUNT=0
FAIL_COUNT=0
WORK=

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_true() { if "$@"; then pass "$*"; else fail "$*"; fi; }
assert_contains() { if grep -Fq -- "$2" "$1"; then pass "$2"; else fail "$2"; fi; }
assert_not_contains() { if ! grep -Fq -- "$2" "$1"; then pass "not: $2"; else fail "not: $2"; fi; }

cleanup() {
    if [ "${KEEP_WORK:-0}" = 1 ]; then printf 'DEBUG_WORK=%s\n' "$WORK"; else [ -n "$WORK" ] && rm -rf -- "$WORK"; fi
}
trap cleanup EXIT HUP INT TERM
WORK=$(mktemp -d)

sha() { sha256sum -- "$1" | awk '{print $1}'; }

make_root() {
    local root=$1
    mkdir -p "$root/etc" "$root/var/lib/pkgtools/packages" "$root/lib/modules/6.18.40/misc" "$root/boot/grub" "$root/etc/grub.d" \
        "$root/etc/default" "$root/usr/sbin" "$root/usr/share/mkinitrd" "$root/var/lib/pkgtools/setup"
    printf 'Slackware 15.0+\n' > "$root/etc/slackware-version"
    printf 'PACKAGE NAME: test-package-1.0-x86_64-1\n' > "$root/var/lib/pkgtools/packages/test-package-1.0-x86_64-1"
    printf 'active grub\n' > "$root/boot/grub/grub.cfg"
    printf 'policy\n' > "$root/etc/default/geninitrd"
    printf '#!/bin/sh\n' > "$root/usr/sbin/geninitrd"
    printf '#!/bin/sh\n' > "$root/usr/share/mkinitrd/mkinitrd_command_generator.sh"
    printf '#!/bin/sh\n' > "$root/var/lib/pkgtools/setup/setup.01.mkinitrd"
    printf 'placeholder\n' > "$root/lib/modules/6.18.40/modules.dep"
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    printf 'kernel\n' > "$root/boot/vmlinuz-6.18.42"
    printf 'initrd\n' > "$root/boot/initrd-6.18.42.img"
}

make_nested() {
    local nested=$1 package=$2 signature=$3 manifest_sha package_sha signature_sha kernel_sha
    mkdir -p "$nested"
    package_sha=$(sha "$package")
    signature_sha=$(sha "$signature")
    printf 'module-manifest\n' > "$nested/source-module-manifest.txt"
    manifest_sha=$(sha "$nested/source-module-manifest.txt")
    kernel_sha=$(printf test-kernel | sha256sum | awk '{print $1}')
    cat > "$nested/summary.txt" <<EOF
result=PASS
passes=61
failures=0
skips=0
apply_ready=true
apply_authorized=false
EOF
    python3 - "$nested" "$package" "$signature" "$package_sha" "$signature_sha" "$manifest_sha" "$kernel_sha" <<'PY'
import json, pathlib, sys
n=pathlib.Path(sys.argv[1]); package, signature, package_sha, signature_sha, manifest_sha, kernel_sha=sys.argv[2:]
modules='xhci-pci:ohci-pci:ehci-pci:xhci-hcd:uhci-hcd:ehci-hcd:hid:usbhid:i2c-hid:hid_generic:hid-asus:hid-cherry:hid-logitech:hid-logitech-dj:hid-logitech-hidpp:hid-lenovo:hid-microsoft:hid_multitouch'
initrd=['mkinitrd','-c','-k','6.18.40','-f','ext4','-r','/dev/sda2','-m',modules,'-u','-o','/boot/initrd-6.18.40.img']
source_vec=['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-generic.img']
projected_vec=['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-6.18.40.img']
actions=['revalidate-boundary-and-source-hashes','create-owner-only-backup-and-extraction-directories','back-up-depmod-metadata-placeholder-and-active-grub-config','extract-only-reviewed-kernel-and-module-tree-to-private-staging','verify-staged-kernel-and-complete-module-manifest','install-versioned-rollback-kernel-and-module-tree','run-depmod-for-rollback-kernel','run-reviewed-versioned-mkinitrd-command','install-explicit-rollback-grub-fragment','generate-and-validate-temporary-grub-config','prove-default-remains-active-6.18.42-entry','atomically-replace-grub-config-and-verify-final-state']
limits=['do-not-change-generic-kernel-link','do-not-change-generic-initrd-link','do-not-change-grub-default','retain-source-package-signature-and-backups']
analysis={'apply_ready':True,'apply_authorized':False,'system_state_mutated':False,'source_package':{'path':package,'sha256':package_sha},'source_signature':{'path':signature,'sha256':signature_sha}}
plan={'source':{'package_sha256':package_sha,'signature_sha256':signature_sha},'payload':{'kernel_sha256':kernel_sha,'module_manifest_sha256':manifest_sha},'initrd':{'command_vector':initrd},'grub':{'default_must_remain':'0','fragment_destination':'/etc/grub.d/41_slackware_rollback_6_18_40'},'ordered_actions':[{'order':i+1,'id':v} for i,v in enumerate(actions)],'rollback_limits':limits}
mk={'command_vector':initrd,'executed':False}
gr={'source_initrd_vector':source_vec,'projected_initrd_vector':projected_vec,'active_initrd_retained':False}
space={'state':'sufficient','minimum_available_bytes':10000000000,'aggregate_required_bytes':1000000000}
live={'validated':True,'checks':[{'ok':True,'key':'test','detail':'test'}]}
pkg={'kernel':{'sha256':kernel_sha},'module_member_count':5504,'module_object_count':5490}
for name,obj in [('source-and-plan-analysis.json',analysis),('reconstruction-plan.json',plan),('projected-mkinitrd-command.json',mk),('projected-grub-entry.json',gr),('space-budget.json',space),('live-boundary.json',live),('source-package.json',pkg)]:
    (n/name).write_text(json.dumps(obj,indent=2,sort_keys=True)+'\n')
PY
    cat > "$nested/projected-grub-menuentry.cfg" <<'EOF'
menuentry 'Slackware GNU/Linux (rollback 6.18.40)' --id 'slackware-rollback-6.18.40' {
	linux /boot/vmlinuz-6.18.40 root=UUID=test ro
	initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img
}
EOF
    printf '#!/bin/sh\ncat <<EOF\nrollback\nEOF\n' > "$nested/projected-41_slackware_rollback_6_18_40"
    printf '# projected\n' > "$nested/projected-mkinitrd-command.sh"
    cat > "$nested/projected-apply-commands.txt" <<'EOF'
# Projected only.
BACKUP_ROOT='/var/lib/slack-update/rollback-backups/6.18.40'
STAGE_ROOT='/var/tmp/slack-update-rollback-apply/6.18.40'
cp -a -- /lib/modules/6.18.40 "$BACKUP_ROOT/modules.metadata-placeholder.before"
cp -a -- /boot/grub/grub.cfg "$BACKUP_ROOT/grub.cfg.before"
tar -xJf "$SOURCE_PACKAGE" -C "$STAGE_ROOT" -- "boot/vmlinuz-6.18.40" "lib/modules/6.18.40"
install -o root -g root -m 0644 "$STAGE_ROOT/boot/vmlinuz-6.18.40" /boot/vmlinuz-6.18.40
mv -- /lib/modules/6.18.40 "$BACKUP_ROOT/modules.metadata-placeholder.original"
mv -- "$STAGE_ROOT/lib/modules/6.18.40" /lib/modules/6.18.40
depmod -a 6.18.40
mkinitrd -c -k 6.18.40 -f ext4 -r /dev/sda2 -m modules -u -o /boot/initrd-6.18.40.img
install fragment /etc/grub.d/41_slackware_rollback_6_18_40
grub-mkconfig -o "$STAGE_ROOT/grub.cfg.new"
grub-script-check "$STAGE_ROOT/grub.cfg.new"
mv -f -- /boot/grub/grub.cfg.new /boot/grub/grub.cfg
EOF
    for name in packages package-names sensitive; do printf 'same\n' > "$nested/$name.before.txt"; cp "$nested/$name.before.txt" "$nested/$name.after.txt"; done
}

make_contracts() {
    local dir=$1 package=$2 signature=$3 nested=$4 script_sha source_script_sha source_policy_sha package_sha signature_sha manifest_sha kernel_sha scope_sha
    script_sha=$(sha "$SCRIPT")
    source_script_sha=$(sha "$SOURCE_PLAN_SCRIPT")
    package_sha=$(sha "$package")
    signature_sha=$(sha "$signature")
    manifest_sha=$(sha "$nested/source-module-manifest.txt")
    kernel_sha=$(python3 - "$nested/source-package.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['kernel']['sha256'])
PY
)
    cat > "$dir/source-policy.json" <<'JSON'
{
  "inventory_archive_sha256":"1111111111111111111111111111111111111111111111111111111111111111",
  "failed_preflight_archive_sha256":"2222222222222222222222222222222222222222222222222222222222222222",
  "revision_1_failed_preflight_archive_sha256":"3333333333333333333333333333333333333333333333333333333333333333",
  "revision_2_failed_preflight_archive_sha256":"4444444444444444444444444444444444444444444444444444444444444444",
  "revision_3_failed_preflight_archive_sha256":"5555555555555555555555555555555555555555555555555555555555555555",
  "revision_4_rejected_plan_archive_sha256":"6666666666666666666666666666666666666666666666666666666666666666",
  "revision_5_failed_preflight_archive_sha256":"7777777777777777777777777777777777777777777777777777777777777777",
  "source_plan_scope_sha256":"8888888888888888888888888888888888888888888888888888888888888888"
}
JSON
    source_policy_sha=$(sha "$dir/source-policy.json")
    scope_sha=$(python3 - "$dir" "$package" "$signature" "$package_sha" "$signature_sha" "$manifest_sha" "$kernel_sha" "$source_script_sha" "$source_policy_sha" "$script_sha" <<'PY'
import hashlib,json,pathlib,sys
p=pathlib.Path(sys.argv[1])
(package,signature,package_sha,signature_sha,manifest_sha,kernel_sha,
 source_script_sha,source_policy_sha,script_sha)=sys.argv[2:]
modules='xhci-pci:ohci-pci:ehci-pci:xhci-hcd:uhci-hcd:ehci-hcd:hid:usbhid:i2c-hid:hid_generic:hid-asus:hid-cherry:hid-logitech:hid-logitech-dj:hid-logitech-hidpp:hid-lenovo:hid-microsoft:hid_multitouch'
actions=['revalidate-boundary-and-source-hashes','create-owner-only-backup-and-extraction-directories','back-up-depmod-metadata-placeholder-and-active-grub-config','extract-only-reviewed-kernel-and-module-tree-to-private-staging','verify-staged-kernel-and-complete-module-manifest','install-versioned-rollback-kernel-and-module-tree','run-depmod-for-rollback-kernel','run-reviewed-versioned-mkinitrd-command','install-explicit-rollback-grub-fragment','generate-and-validate-temporary-grub-config','prove-default-remains-active-6.18.42-entry','atomically-replace-grub-config-and-verify-final-state']
limits=['do-not-change-generic-kernel-link','do-not-change-generic-initrd-link','do-not-change-grub-default','retain-source-package-signature-and-backups']
accepted={
 'accepted':True,
 'archive_sha256':'a'*64,
 'hostname_short':'pcold-slack',
 'hostname_fqdn':'pcold-slack.pcold-slack.org',
 'active_kernel':'6.18.42',
 'rollback_kernel':'6.18.40',
 'root_source':'/dev/sda2',
 'root_uuid':'ba7632d7-7469-483e-830d-59c88d985866',
 'source_plan_script_sha256':source_script_sha,
 'source_plan_policy_sha256':source_policy_sha,
 'source_plan_scope_sha256':'8'*64,
 'source':{
   'package_path':package,'signature_path':signature,
   'package_sha256':package_sha,'signature_sha256':signature_sha,
   'package_size':pathlib.Path(package).stat().st_size,
   'signature_size':pathlib.Path(signature).stat().st_size,
   'primary_fingerprint':'EC5649DA401E22ABFA6736EF6A4463C040102233'},
 'payload':{
   'kernel_member':'boot/vmlinuz-6.18.40','kernel_destination':'/boot/vmlinuz-6.18.40',
   'kernel_sha256':kernel_sha,'kernel_size':11,
   'module_destination':'/lib/modules/6.18.40','module_member_count':5504,
   'module_object_count':5490,'module_payload_bytes':431714444,
   'module_manifest_sha256':manifest_sha},
 'initrd':{'destination':'/boot/initrd-6.18.40.img','command_vector':['mkinitrd','-c','-k','6.18.40','-f','ext4','-r','/dev/sda2','-m',modules,'-u','-o','/boot/initrd-6.18.40.img']},
 'grub':{'fragment_destination':'/etc/grub.d/41_slackware_rollback_6_18_40','fragment_mode':'0755','entry_id':'slackware-rollback-6.18.40','default_must_remain':'0','source_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-generic.img'],'projected_initrd_vector':['/boot/intel-ucode.img','/boot/amd-ucode.img','/boot/initrd-6.18.40.img']},
 'ordered_actions':actions,
 'rollback_limits':limits,
}
accepted_path=p/'accepted.json'
accepted_path.write_text(json.dumps(accepted,indent=2,sort_keys=True)+'\n')
accepted_sha=hashlib.sha256(accepted_path.read_bytes()).hexdigest()
backup_root='/var/lib/slack-update/rollback-backups/6.18.40'
stage_root='/var/tmp/slack-update-rollback-apply/6.18.40'
contract={
 'operation':'current-rollback-reconstruction-authorized-apply',
 'target':'slackware-current',
 'hostname_short':accepted['hostname_short'],'hostname_fqdn':accepted['hostname_fqdn'],
 'active_kernel':accepted['active_kernel'],'rollback_kernel':accepted['rollback_kernel'],
 'root_source':accepted['root_source'],'root_uuid':accepted['root_uuid'],
 'source':accepted['source'],'payload':accepted['payload'],'initrd':accepted['initrd'],'grub':accepted['grub'],
 'backup_root':backup_root,'stage_root':stage_root,
 'ordered_actions':accepted['ordered_actions'],'rollback_limits':accepted['rollback_limits'],
}
contract_sha=hashlib.sha256((json.dumps(contract,separators=(',',':'),sort_keys=True)+'\n').encode()).hexdigest()
scope=(
 'operation=current-rollback-reconstruction-authorized-apply-review\n'
 'target=slackware-current\n'
 'hostname_short=pcold-slack\n'
 'hostname_fqdn=pcold-slack.pcold-slack.org\n'
 'active_kernel=6.18.42\n'
 'rollback_kernel=6.18.40\n'
 f'source_plan_evidence_sha256={"a"*64}\n'
 f'accepted_source_plan_record_sha256={accepted_sha}\n'
 f'source_plan_script_sha256={source_script_sha}\n'
 f'source_plan_policy_sha256={source_policy_sha}\n'
 f'review_script_sha256={script_sha}\n'
 f'source_package_sha256={package_sha}\n'
 f'source_signature_sha256={signature_sha}\n'
 f'kernel_sha256={kernel_sha}\n'
 f'module_manifest_sha256={manifest_sha}\n'
 f'source_plan_scope_sha256={"8"*64}\n'
 f'apply_contract_sha256={contract_sha}\n')
scope_sha=hashlib.sha256(scope.encode()).hexdigest()
policy={
 'schema':1,'scenario':'current-rollback-reconstruction-authorized-apply-review',
 'hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org',
 'active_kernel':'6.18.42','rollback_kernel':'6.18.40',
 'expected_review_script_sha256':script_sha,
 'accepted_source_plan_record_sha256':accepted_sha,
 'accepted_source_plan_archive_sha256':'a'*64,
 'source_plan_script_sha256':source_script_sha,
 'source_plan_policy_sha256':source_policy_sha,
 'backup_root':backup_root,'stage_root':stage_root,
 'apply_contract_sha256':contract_sha,
 'confirmation_scope_sha256':scope_sha,
 'required_projected_command_fragments':["BACKUP_ROOT='/var/lib/slack-update/rollback-backups/6.18.40'","STAGE_ROOT='/var/tmp/slack-update-rollback-apply/6.18.40'",'cp -a -- /lib/modules/6.18.40 "$BACKUP_ROOT/modules.metadata-placeholder.before"','cp -a -- /boot/grub/grub.cfg "$BACKUP_ROOT/grub.cfg.before"','tar -xJf "$SOURCE_PACKAGE" -C "$STAGE_ROOT" -- "boot/vmlinuz-6.18.40" "lib/modules/6.18.40"','install -o root -g root -m 0644 "$STAGE_ROOT/boot/vmlinuz-6.18.40" /boot/vmlinuz-6.18.40','mv -- /lib/modules/6.18.40 "$BACKUP_ROOT/modules.metadata-placeholder.original"','mv -- "$STAGE_ROOT/lib/modules/6.18.40" /lib/modules/6.18.40','depmod -a 6.18.40','mkinitrd -c -k 6.18.40','/etc/grub.d/41_slackware_rollback_6_18_40','grub-mkconfig -o "$STAGE_ROOT/grub.cfg.new"','grub-script-check "$STAGE_ROOT/grub.cfg.new"','mv -f -- /boot/grub/grub.cfg.new /boot/grub/grub.cfg'],
 'forbidden_projected_tokens':['slackpkg update','installpkg ','upgradepkg ','removepkg ','grub-reboot','reboot'],
 'authorization_constraints':['exact-only','no-reboot-is-authorized-by-this-review'],
}
(p/'review-policy.json').write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n')
print(scope_sha)
PY
)
    printf '%s\n' "$scope_sha"
}

run_case() {
    local name=$1 mode=${2:-valid} case_dir root nested package signature scope output rc
    case_dir=$WORK/$name; mkdir -p "$case_dir"
    root=$case_dir/root; make_root "$root"
    package=$case_dir/kernel-generic-6.18.40-x86_64-1.txz
    signature=$case_dir/kernel-generic-6.18.40-x86_64-1.txz.asc
    cp "$FIXTURE_PACKAGE" "$package"; cp "$FIXTURE_SIGNATURE" "$signature"; chmod 0600 "$package" "$signature"
    nested=$case_dir/nested; make_nested "$nested" "$package" "$signature"
    scope=$(make_contracts "$case_dir" "$package" "$signature" "$nested")
    case "$mode" in
      changed-source) printf x >> "$package" ;;
      missing-nested) rm -f "$nested/reconstruction-plan.json" ;;
      bad-grub) sed -i 's#/boot/initrd-6.18.40.img#/boot/initrd-generic.img#' "$nested/projected-grub-menuentry.cfg" ;;
      bad-scope) scope=$(printf '0%.0s' {1..64}) ;;
    esac
    output=$case_dir/output
    set +e
    SLACK_UPDATE_TEST_MODE=1 \
    SLACK_UPDATE_TEST_ROOT="$root" \
    SLACK_UPDATE_TEST_NESTED_SOURCE="$nested" \
    ROLLBACK_AUTH_ACCEPTED_SOURCE_PLAN="$case_dir/accepted.json" \
    ROLLBACK_AUTH_SOURCE_PLAN_POLICY="$case_dir/source-policy.json" \
    ROLLBACK_AUTH_REVIEW_POLICY="$case_dir/review-policy.json" \
    "$SCRIPT" --target slackware-current \
      --confirm-hostname pcold-slack \
      --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
      --confirm-source-plan-evidence-sha256 "$(printf 'a%.0s' {1..64})" \
      --confirm-active-kernel 6.18.42 \
      --confirm-rollback-kernel 6.18.40 \
      --confirm-authorization-review-sha256 "$scope" \
      --source-package "$package" \
      --source-signature "$signature" \
      --output-dir "$output" > "$case_dir/console.txt" 2>&1
    rc=$?
    set -e
    printf '%s|%s|%s\n' "$case_dir" "$rc" "$output"
}

assert_true test -x "$SCRIPT"
assert_true bash -n "$SCRIPT"
assert_true bash -n "$SOURCE_PLAN_SCRIPT"
assert_contains "$SCRIPT" 'apply_authorized=$APPLY_AUTHORIZED'
assert_contains "$SCRIPT" 'apply_executed=$APPLY_EXECUTED'
assert_contains "$SCRIPT" 'repository_metadata_refreshed=false'
assert_true bash -c "! grep -Eq '^[[:space:]]*(slackpkg|installpkg|upgradepkg|removepkg|depmod|mkinitrd|grub-mkconfig|grub-reboot|reboot)([[:space:]]|$)' '$SCRIPT'"
assert_not_contains "$SCRIPT" 'grub-mkconfig -o /boot/grub/grub.cfg'
assert_true python3 -m json.tool "$PRODUCTION_ACCEPTED"
assert_true python3 -m json.tool "$PRODUCTION_POLICY"
assert_true python3 - "$SCRIPT" "$SOURCE_PLAN_SCRIPT" "$PRODUCTION_SOURCE_POLICY" "$PRODUCTION_ACCEPTED" "$PRODUCTION_POLICY" <<'PY'
import hashlib,json,pathlib,sys
def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
script,source_script,source_policy_path,accepted_path,policy_path=sys.argv[1:]
accepted=json.load(open(accepted_path)); policy=json.load(open(policy_path))
contract={
 'operation':'current-rollback-reconstruction-authorized-apply',
 'target':'slackware-current',
 'hostname_short':accepted['hostname_short'],'hostname_fqdn':accepted['hostname_fqdn'],
 'active_kernel':accepted['active_kernel'],'rollback_kernel':accepted['rollback_kernel'],
 'root_source':accepted['root_source'],'root_uuid':accepted['root_uuid'],
 'source':accepted['source'],'payload':accepted['payload'],'initrd':accepted['initrd'],'grub':accepted['grub'],
 'backup_root':policy['backup_root'],'stage_root':policy['stage_root'],
 'ordered_actions':accepted['ordered_actions'],'rollback_limits':accepted['rollback_limits'],
}
contract_sha=hashlib.sha256((json.dumps(contract,separators=(',',':'),sort_keys=True)+'\n').encode()).hexdigest()
scope=(
 'operation=current-rollback-reconstruction-authorized-apply-review\n'
 'target=slackware-current\n'
 f'hostname_short={accepted["hostname_short"]}\n'
 f'hostname_fqdn={accepted["hostname_fqdn"]}\n'
 f'active_kernel={accepted["active_kernel"]}\n'
 f'rollback_kernel={accepted["rollback_kernel"]}\n'
 f'source_plan_evidence_sha256={accepted["archive_sha256"]}\n'
 f'accepted_source_plan_record_sha256={sha(accepted_path)}\n'
 f'source_plan_script_sha256={sha(source_script)}\n'
 f'source_plan_policy_sha256={sha(source_policy_path)}\n'
 f'review_script_sha256={sha(script)}\n'
 f'source_package_sha256={accepted["source"]["package_sha256"]}\n'
 f'source_signature_sha256={accepted["source"]["signature_sha256"]}\n'
 f'kernel_sha256={accepted["payload"]["kernel_sha256"]}\n'
 f'module_manifest_sha256={accepted["payload"]["module_manifest_sha256"]}\n'
 f'source_plan_scope_sha256={accepted["source_plan_scope_sha256"]}\n'
 f'apply_contract_sha256={contract_sha}\n')
checks=[
 policy['expected_review_script_sha256']==sha(script),
 policy['accepted_source_plan_record_sha256']==sha(accepted_path),
 policy['source_plan_script_sha256']==sha(source_script),
 policy['source_plan_policy_sha256']==sha(source_policy_path),
 accepted['archive_sha256']=='ce45977bbcacb237163d821a43d5a79f5246bfca54bc3fb4ca6edfc30243fbfb',
 policy['accepted_source_plan_archive_sha256']==accepted['archive_sha256'],
 policy['apply_contract_sha256']==contract_sha,
 policy['confirmation_scope_sha256']==hashlib.sha256(scope.encode()).hexdigest(),
]
raise SystemExit(0 if all(checks) else 1)
PY

set +e
"$SCRIPT" --help > "$WORK/help.txt" 2>&1; help_rc=$?
"$SCRIPT" > "$WORK/noargs.txt" 2>&1; noargs_rc=$?
set -e
assert_true test "$help_rc" -eq 0
assert_contains "$WORK/help.txt" 'non-mutating authorization review'
assert_true test "$noargs_rc" -eq 2
assert_contains "$WORK/noargs.txt" 'Usage:'

IFS='|' read -r valid_dir valid_rc valid_output <<< "$(run_case valid valid)"
assert_true test "$valid_rc" -eq 0
assert_contains "$valid_dir/console.txt" 'Result: PASS'
assert_contains "$valid_dir/console.txt" 'apply_ready=true'
assert_contains "$valid_dir/console.txt" 'apply_authorized=true'
assert_contains "$valid_dir/console.txt" 'apply_executed=false'
assert_contains "$valid_dir/console.txt" 'next_stage=current-rollback-reconstruction-authorized-apply'
assert_true test -f "$valid_output/apply-authorization.json"
assert_true test -f "$valid_output/reviewed-plan.json"
assert_true test -f "$valid_output/summary.txt"
assert_true test -f "$valid_output.tar.gz"
assert_true test -f "$valid_output.tar.gz.sha256"
assert_true cmp -s "$valid_output/packages.before.txt" "$valid_output/packages.after.txt"
assert_true cmp -s "$valid_output/sensitive.before.txt" "$valid_output/sensitive.after.txt"
assert_contains "$valid_output/summary.txt" 'apply_authorized=true'
assert_contains "$valid_output/apply-authorization.json" '"apply_executed": false'
assert_contains "$valid_output/apply-authorization.json" '"no-reboot-is-authorized-by-this-review"'
assert_true python3 - "$valid_output/apply-authorization.json" "$valid_dir/review-policy.json" <<'PY'
import json,sys
a=json.load(open(sys.argv[1])); p=json.load(open(sys.argv[2]))
raise SystemExit(0 if a['apply_contract_sha256']==p['apply_contract_sha256'] else 1)
PY
assert_contains "$valid_dir/console.txt" 'Copy evidence pair command:'
assert_contains "$valid_dir/console.txt" 'Source package retained:'

IFS='|' read -r scope_dir scope_rc scope_output <<< "$(run_case bad-scope bad-scope)"
assert_true test "$scope_rc" -eq 1
assert_contains "$scope_dir/console.txt" 'explicit authorization scope is missing, changed, or mismatched'
assert_not_contains "$scope_dir/console.txt" 'apply_authorized=true'

IFS='|' read -r source_dir source_rc source_output <<< "$(run_case changed-source changed-source)"
assert_true test "$source_rc" -eq 1
assert_contains "$source_dir/console.txt" 'pre-staged package or detached signature is missing, unsafe, or changed'
assert_not_contains "$source_dir/console.txt" 'apply_authorized=true'

IFS='|' read -r missing_dir missing_rc missing_output <<< "$(run_case missing-nested missing-nested)"
assert_true test "$missing_rc" -eq 1
assert_contains "$missing_dir/console.txt" 'fresh source-and-plan output is incomplete, changed, unsafe'
assert_not_contains "$missing_dir/console.txt" 'apply_authorized=true'

IFS='|' read -r grub_dir grub_rc grub_output <<< "$(run_case bad-grub bad-grub)"
assert_true test "$grub_rc" -eq 1
assert_contains "$grub_dir/console.txt" 'fresh source-and-plan output is incomplete, changed, unsafe'
assert_not_contains "$grub_dir/console.txt" 'apply_authorized=true'

printf 'Result: %d passes, %d failures\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
