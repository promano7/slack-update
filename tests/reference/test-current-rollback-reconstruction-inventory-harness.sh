#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-inventory.sh"
REAL_CLOSURE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-reboot-verification.sh"

TEST_COUNT=0
FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
json_value() { python3 - "$1" "$2" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value=value[part]
if isinstance(value,bool): print(str(value).lower())
elif value is None: print('null')
else: print(value)
PY
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BIN="$TMP/bin"
mkdir -p "$BIN"

cat > "$BIN/grub-script-check" <<'EOF_STUB'
#!/bin/bash
[ "${GRUB_CHECK_FAIL:-0}" != 1 ] || exit 1
[ -f "$1" ] && grep -q '^menuentry ' "$1"
EOF_STUB
cat > "$BIN/grub-editenv" <<'EOF_STUB'
#!/bin/bash
[ "$#" -eq 2 ] && [ "$2" = list ] || exit 1
[ -f "$1" ] || exit 1
grep -E '^(next_entry|saved_entry)=' "$1" || true
EOF_STUB
chmod 755 "$BIN/grub-script-check" "$BIN/grub-editenv"

create_source_package() {
    local package=$1 version=${2:-6.18.40} module_name=${3:-test.ko}
    mkdir -p "$(dirname -- "$package")"
    python3 - "$package" "$version" "$module_name" <<'PY'
import io, pathlib, sys, tarfile
out=pathlib.Path(sys.argv[1]); version=sys.argv[2]; module=sys.argv[3]
with tarfile.open(out, mode='w:xz') as archive:
    for name, data, mode in [
        (f'boot/vmlinuz-{version}', f'kernel-{version}\n'.encode(), 0o644),
        (f'lib/modules/{version}/kernel/{module}', f'module-{version}\n'.encode(), 0o644),
        ('install/doinst.sh', b'#!/bin/sh\nexit 0\n', 0o755),
    ]:
        info=tarfile.TarInfo(name); info.size=len(data); info.mode=mode; info.uid=0; info.gid=0
        archive.addfile(info, io.BytesIO(data))
PY
}

write_root_file() {
    local path=$1 content=$2 mode=${3:-644}
    mkdir -p "$(dirname -- "$path")"
    printf '%b' "$content" > "$path"
    chmod "$mode" "$path"
}

create_root() {
    local root=$1
    rm -rf "$root"
    mkdir -p \
        "$root/proc/sys/kernel" \
        "$root/etc/default" \
        "$root/boot/grub" \
        "$root/lib/modules/6.18.42/kernel" \
        "$root/lib/modules/6.18.40/kernel" \
        "$root/usr/sbin" \
        "$root/usr/share/mkinitrd" \
        "$root/var/lib/pkgtools/setup" \
        "$root/var/lib/pkgtools/packages"
    write_root_file "$root/etc/slackware-version" 'Slackware 15.0+\n'
    write_root_file "$root/proc/cmdline" 'BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro\n' 444
    write_root_file "$root/proc/sys/kernel/osrelease" '6.18.42\n' 444
    write_root_file "$root/boot/vmlinuz-6.18.42" 'kernel-6.18.42\n'
    write_root_file "$root/boot/initrd-6.18.42.img" 'initrd-6.18.42\n'
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    write_root_file "$root/lib/modules/6.18.42/kernel/test.ko" 'target-module\n'
    write_root_file "$root/lib/modules/6.18.40/kernel/test.ko" 'module-6.18.40\n'
    write_root_file "$root/lib/modules/6.18.40/modules.alias" '# alias\n'
    write_root_file "$root/lib/modules/6.18.40/modules.builtin" '# builtin\n'
    write_root_file "$root/lib/modules/6.18.40/modules.dep" 'kernel/test.ko:\n'
    write_root_file "$root/etc/default/geninitrd" 'AUTOGENERATE_INITRD=true\nAUTO_UPDATE_GRUB=true\n'
    write_root_file "$root/usr/sbin/geninitrd" '#!/bin/bash\nexit 0\n' 755
    write_root_file "$root/usr/share/mkinitrd/mkinitrd_command_generator.sh" '#!/bin/bash\necho mkinitrd\n' 755
    write_root_file "$root/var/lib/pkgtools/setup/setup.01.mkinitrd" '#!/bin/bash\nexit 0\n' 755
    cat > "$root/boot/grub/grub.cfg" <<'EOF_GRUB'
if [ -s $prefix/grubenv ]; then
  load_env
fi
if [ "${next_entry}" ] ; then
  set default="${next_entry}"
  set next_entry=
  save_env next_entry
else
  set default="0"
fi
menuentry 'Slackware generic' --id slackware-generic {
  linux /boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
  initrd /boot/initrd-generic.img
}
menuentry 'Diagnostic shell' --id diagnostic-shell {
  linux /boot/vmlinuz-diagnostic root=/dev/sda2 ro
}
EOF_GRUB
    : > "$root/boot/grub/grubenv"
    chmod 600 "$root/boot/grub/grub.cfg"
    chmod 644 "$root/boot/grub/grubenv"
    write_root_file "$root/var/lib/pkgtools/packages/kernel-generic-6.18.42-x86_64-1" 'boot/vmlinuz-6.18.42\n'
    write_root_file "$root/var/lib/pkgtools/packages/kernel-headers-6.18.42-x86-1" 'usr/include/linux/\n'
    write_root_file "$root/var/lib/pkgtools/packages/kernel-source-6.18.42-noarch-1" 'usr/src/linux-6.18.42/\n'
    write_root_file "$root/var/lib/pkgtools/packages/grub-2.14-x86_64-3" 'usr/sbin/grub-mkconfig\n'
    write_root_file "$root/var/lib/pkgtools/packages/breeze-grub-6.7.4-x86_64-1" 'boot/grub/themes/breeze/\n'
    write_root_file "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1" 'usr/bin/dummy\n'
}

write_policies() {
    local root=$1 closure_policy=$2 recovery_policy=$3 closure_record=$4 inventory_policy=$5 closure_archive=$6
    python3 - "$root" "$closure_policy" "$recovery_policy" "$closure_record" "$inventory_policy" \
        "$REAL_CLOSURE_SCRIPT" "$SCRIPT" "$closure_archive" <<'PY'
import hashlib, json, pathlib, sys
root=pathlib.Path(sys.argv[1])
closure_policy_path=pathlib.Path(sys.argv[2])
recovery_policy_path=pathlib.Path(sys.argv[3])
closure_record_path=pathlib.Path(sys.argv[4])
inventory_policy_path=pathlib.Path(sys.argv[5])
closure_script_path=pathlib.Path(sys.argv[6])
inventory_script_path=pathlib.Path(sys.argv[7])
closure_archive=sys.argv[8]

def sha(path): return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()
def size(path): return pathlib.Path(path).stat().st_size

def write(path, data): path.write_text(json.dumps(data, indent=2, sort_keys=True)+'\n', encoding='utf-8')

pkg=root/'var/lib/pkgtools/packages'
names=sorted(p.name for p in pkg.iterdir() if p.is_file() and not p.is_symlink())
snapshot=''.join(f'{sha(pkg/name)}  {name}\n' for name in names).encode()
name_snapshot=''.join(name+'\n' for name in names).encode()
required_names=[
 'kernel-generic-6.18.42-x86_64-1','kernel-headers-6.18.42-x86-1',
 'kernel-source-6.18.42-noarch-1','grub-2.14-x86_64-3','breeze-grub-6.7.4-x86_64-1'
]
closure_policy={
 'scenario':'current-kernel-post-reboot-verification','target':'slackware-current','reviewed':True,
 'target_kernel':'6.18.42','rollback_state_after_reboot':'degraded-modules-only',
 'expected_update_closed':True,'next_stage':'optional-rollback-reconstruction-review',
}
write(closure_policy_path, closure_policy)
recovery_policy={
 'scenario':'current-post-package-boot-recovery-verification','target':'slackware-current','reviewed':True,
 'target_kernel':'6.18.42','installed_package_count':len(names),
 'installed_package_database_snapshot_sha256':hashlib.sha256(snapshot).hexdigest(),
 'installed_package_name_snapshot_sha256':hashlib.sha256(name_snapshot).hexdigest(),
 'required_package_records':[{'name':name,'record_sha256':sha(pkg/name)} for name in required_names],
 'forbidden_package_records':['kernel-generic-6.18.40-x86_64-1','kernel-headers-6.18.40-x86-1','kernel-source-6.18.40-noarch-1'],
 'rollback':{'state':'degraded-running-session-and-modules-only','modules_path':'/lib/modules/6.18.40'},
 'target_artifacts':{
   'kernel_sha256':sha(root/'boot/vmlinuz-6.18.42'),'kernel_size':size(root/'boot/vmlinuz-6.18.42'),
   'initrd_sha256':sha(root/'boot/initrd-6.18.42.img'),'initrd_size':size(root/'boot/initrd-6.18.42.img')},
 'geninitrd':{
   'policy_sha256':sha(root/'etc/default/geninitrd'),'policy_size':size(root/'etc/default/geninitrd'),
   'geninitrd_sha256':sha(root/'usr/sbin/geninitrd'),'geninitrd_size':size(root/'usr/sbin/geninitrd'),
   'generator_sha256':sha(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),'generator_size':size(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),
   'setup_sha256':sha(root/'var/lib/pkgtools/setup/setup.01.mkinitrd'),'setup_size':size(root/'var/lib/pkgtools/setup/setup.01.mkinitrd')},
 'active_grub':{'sha256':sha(root/'boot/grub/grub.cfg'),'size':size(root/'boot/grub/grub.cfg')},
}
write(recovery_policy_path, recovery_policy)
closure_record={
 'scenario':'current-kernel-post-reboot-verification','target':'slackware-current','accepted':True,
 'archive_sha256':closure_archive,'hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org',
 'running_kernel':'6.18.42','target_kernel':'6.18.42','rollback_state':'degraded-modules-only',
 'pause_safe':True,'reboot_verified':True,'update_closed':True,'mandatory_work_remaining':False,
 'next_stage':'optional-rollback-reconstruction-review',
 'post_reboot_verification_policy_sha256':sha(closure_policy_path),
 'post_reboot_verification_script_sha256':sha(closure_script_path),
}
write(closure_record_path, closure_record)
host='pcold-slack'; fqdn='pcold-slack.pcold-slack.org'; active='6.18.42'; rollback='6.18.40'; uuid='ba7632d7-7469-483e-830d-59c88d985866'
scope=(
 'operation=current-rollback-reconstruction-inventory\n'
 'target=slackware-current\n'
 f'hostname_short={host}\n'
 f'hostname_fqdn={fqdn}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'root_uuid={uuid}\n'
 f'closure_archive_sha256={closure_archive}\n'
 f'closure_record_sha256={sha(closure_record_path)}\n'
 f'closure_policy_sha256={sha(closure_policy_path)}\n'
 f'closure_script_sha256={sha(closure_script_path)}\n'
 f'recovery_policy_sha256={sha(recovery_policy_path)}\n'
 f'inventory_script_sha256={sha(inventory_script_path)}\n'
).encode()
inventory_policy={
 'scenario':'current-rollback-reconstruction-inventory','target':'slackware-current','reviewed':True,
 'required_hostname_short':host,'required_hostname_fqdn':fqdn,'active_kernel':active,'rollback_kernel':rollback,
 'required_root_uuid':uuid,'required_boot_image':'/boot/vmlinuz-generic',
 'accepted_closure_archive_sha256':closure_archive,'accepted_closure_record_sha256':sha(closure_record_path),
 'closure_policy_sha256':sha(closure_policy_path),'closure_script_sha256':sha(closure_script_path),
 'recovery_policy_sha256':sha(recovery_policy_path),'inventory_script_sha256':sha(inventory_script_path),
 'inventory_scope_sha256':hashlib.sha256(scope).hexdigest(),'minimum_free_space_reserve_bytes':1024,
 'repository_refresh_allowed':False,'package_mutation_allowed':False,'initrd_mutation_allowed':False,
 'grub_mutation_allowed':False,'reboot_execution_allowed':False,
}
write(inventory_policy_path, inventory_policy)
PY
}

prepare_case() {
    local name=$1
    CASE_ROOT="$TMP/$name-root"
    CASE_SOURCE="$TMP/$name-source"
    CASE_OUTPUT="$TMP/$name-output"
    CASE_CLOSURE_POLICY="$TMP/$name-closure-policy.json"
    CASE_RECOVERY_POLICY="$TMP/$name-recovery-policy.json"
    CASE_CLOSURE_RECORD="$TMP/$name-closure-record.json"
    CASE_INVENTORY_POLICY="$TMP/$name-inventory-policy.json"
    CASE_CLOSURE_ARCHIVE=$(printf 'c%.0s' {1..64})
    create_root "$CASE_ROOT"
    create_source_package "$CASE_SOURCE/slackware64/a/kernel-generic-6.18.40-x86_64-1.txz"
    write_policies "$CASE_ROOT" "$CASE_CLOSURE_POLICY" "$CASE_RECOVERY_POLICY" "$CASE_CLOSURE_RECORD" "$CASE_INVENTORY_POLICY" "$CASE_CLOSURE_ARCHIVE"
}

run_case() {
    local scope
    scope=$(json_value "$CASE_INVENTORY_POLICY" inventory_scope_sha256)
    env \
        SLACK_UPDATE_TEST_MODE=1 \
        SLACK_UPDATE_TEST_ROOT="$CASE_ROOT" \
        SLACK_UPDATE_TEST_PATH="$BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        SLACK_UPDATE_TEST_HOSTNAME_SHORT=pcold-slack \
        SLACK_UPDATE_TEST_HOSTNAME_FQDN=pcold-slack.pcold-slack.org \
        SLACK_UPDATE_TEST_RUNNING_KERNEL=6.18.42 \
        SLACK_UPDATE_TEST_ARCHITECTURE=x86_64 \
        SLACK_UPDATE_TEST_ROOT_UUID=ba7632d7-7469-483e-830d-59c88d985866 \
        SLACK_UPDATE_TEST_ROOT_SOURCE=/dev/test-root \
        SLACK_UPDATE_TEST_BOOT_FREE_BYTES="${CASE_FREE_BYTES:-104857600}" \
        ROLLBACK_INVENTORY_CLOSURE_RECORD="$CASE_CLOSURE_RECORD" \
        ROLLBACK_INVENTORY_CLOSURE_POLICY="$CASE_CLOSURE_POLICY" \
        ROLLBACK_INVENTORY_CLOSURE_SCRIPT="$REAL_CLOSURE_SCRIPT" \
        ROLLBACK_INVENTORY_RECOVERY_POLICY="$CASE_RECOVERY_POLICY" \
        ROLLBACK_INVENTORY_POLICY="$CASE_INVENTORY_POLICY" \
        bash "$SCRIPT" \
            --target slackware-current \
            --confirm-hostname pcold-slack \
            --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
            --confirm-closure-evidence-sha256 "$CASE_CLOSURE_ARCHIVE" \
            --confirm-active-kernel 6.18.42 \
            --confirm-rollback-kernel 6.18.40 \
            --confirm-inventory-sha256 "${CASE_SCOPE_OVERRIDE:-$scope}" \
            --source-root "$CASE_SOURCE" \
            --output-dir "$CASE_OUTPUT"
}

assert_success 'the inventory script should have valid shell syntax' bash -n "$SCRIPT"
assert_contains 'This command is read-only' <(bash "$SCRIPT" --help) 'help should state the read-only boundary'
assert_contains 'A missing exact package' <(bash "$SCRIPT" --help) 'help should explain source-missing semantics'

prepare_case baseline
CASE_FREE_BYTES=104857600
assert_success 'a complete exact local rollback source should pass inventory' run_case
ANALYSIS="$CASE_OUTPUT/rollback-inventory-analysis.json"
assert_equal true "$(json_value "$ANALYSIS" reconstruction_viable)" 'a complete local source should be viable'
assert_equal exact-local-package "$(json_value "$ANALYSIS" source_state)" 'the exact local package should be identified'
assert_equal current-rollback-reconstruction-preflight "$(json_value "$ANALYSIS" next_stage)" 'a viable inventory should advance to preflight'
assert_equal 1 "$(json_value "$ANALYSIS" source_module_file_count)" 'the package module manifest should be counted'
assert_equal 1 "$(json_value "$ANALYSIS" installed_module_file_count)" 'the installed rollback modules should be counted'
assert_equal false "$(json_value "$ANALYSIS" repository_metadata_refreshed)" 'metadata refresh should remain false'
assert_equal false "$(json_value "$ANALYSIS" package_mutation_performed)" 'package mutation should remain false'
assert_equal false "$(json_value "$ANALYSIS" initrd_generated)" 'initrd generation should remain false'
assert_equal false "$(json_value "$ANALYSIS" grub_mutation_performed)" 'GRUB mutation should remain false'
assert_equal false "$(json_value "$ANALYSIS" host_mutated)" 'host mutation should remain false'
assert_contains 'source_state=exact-local-package' "$CASE_OUTPUT/summary.txt" 'summary should expose the exact source state'
assert_contains 'reconstruction_viable=true' "$CASE_OUTPUT/summary.txt" 'summary should expose viability'
assert_contains 'the kernel, initrd, module, GenInitrd, and GRUB state remained unchanged' "$CASE_OUTPUT/assertions.log" 'before/after invariants should pass'

prepare_case empty-module-placeholder
rm -rf "$CASE_ROOT/lib/modules/6.18.40"/*
assert_success 'an empty rollback module directory should be accepted as a corrected placeholder state' run_case
ANALYSIS="$CASE_OUTPUT/rollback-inventory-analysis.json"
assert_equal empty-directory-placeholder "$(json_value "$ANALYSIS" rollback_module_state)" 'the empty module directory should be classified exactly'
assert_equal 0 "$(json_value "$ANALYSIS" installed_module_file_count)" 'the empty placeholder should report zero installed modules'
assert_equal true "$(json_value "$ANALYSIS" reconstruction_viable)" 'a complete package should make the empty placeholder reconstructible'
assert_contains 'rollback_module_state=empty-directory-placeholder' "$CASE_OUTPUT/summary.txt" 'summary should expose the corrected empty state'

prepare_case missing-source
rm -f "$CASE_SOURCE/slackware64/a/kernel-generic-6.18.40-x86_64-1.txz"
assert_success 'a missing local source should still complete the inventory safely' run_case
ANALYSIS="$CASE_OUTPUT/rollback-inventory-analysis.json"
assert_equal false "$(json_value "$ANALYSIS" reconstruction_viable)" 'missing source should not be viable'
assert_equal not-found-in-reviewed-root "$(json_value "$ANALYSIS" source_state)" 'missing source should be classified exactly'
assert_equal current-rollback-source-acquisition-review "$(json_value "$ANALYSIS" next_stage)" 'missing source should require acquisition review'

prepare_case low-space
CASE_FREE_BYTES=1
assert_success 'insufficient space should be an accepted inventory classification' run_case
ANALYSIS="$CASE_OUTPUT/rollback-inventory-analysis.json"
assert_equal insufficient "$(json_value "$ANALYSIS" boot_space.state)" 'insufficient space should be recorded'
assert_equal false "$(json_value "$ANALYSIS" reconstruction_viable)" 'insufficient space should block viability'
assert_equal current-rollback-space-remediation-review "$(json_value "$ANALYSIS" next_stage)" 'insufficient space should require remediation'
unset CASE_FREE_BYTES

prepare_case duplicate
mkdir -p "$CASE_SOURCE/duplicate"
cp "$CASE_SOURCE/slackware64/a/kernel-generic-6.18.40-x86_64-1.txz" "$CASE_SOURCE/duplicate/"
assert_failure 'duplicate exact source archives should fail closed' run_case

prepare_case missing-module-metadata
rm "$CASE_ROOT/lib/modules/6.18.40/modules.dep"
assert_failure 'missing rollback depmod metadata should fail closed' run_case

prepare_case scope-change
CASE_SCOPE_OVERRIDE=$(printf 'd%.0s' {1..64})
assert_failure 'a mismatched explicit inventory scope should fail closed' run_case
unset CASE_SCOPE_OVERRIDE

UNIT="$TMP/unit"
mkdir -p "$UNIT/out" "$UNIT/source"
create_source_package "$UNIT/source/kernel-generic-6.18.40-x86_64-1.txz"
printf 'not a package\n' > "$UNIT/source/corrupt.txz"
assert_failure 'a corrupt source archive should fail package inspection' bash -c '
    source "$1"
    CONFIRM_ROLLBACK_KERNEL=6.18.40
    inspect_source_package "$2" "$3" "$4"
' _ "$SCRIPT" "$UNIT/source/corrupt.txz" "$UNIT/out/corrupt.json" "$UNIT/out/corrupt.modules"

create_source_package "$UNIT/source/kernel-generic-6.18.40-x86_64-1.txz" 6.18.40 other.ko
prepare_case unit-module-mismatch
assert_success 'a safe package with a different module payload should still inspect structurally' bash -c '
    source "$1"
    CONFIRM_ROLLBACK_KERNEL=6.18.40
    inspect_source_package "$2" "$3" "$4"
' _ "$SCRIPT" "$UNIT/source/kernel-generic-6.18.40-x86_64-1.txz" "$UNIT/out/mismatch.json" "$UNIT/out/mismatch.modules"
assert_success 'the preserved module manifest should be capturable' bash -c '
    source "$1"
    ROOT_PREFIX="$2"
    CONFIRM_ROLLBACK_KERNEL=6.18.40
    capture_installed_module_manifest "$3"
' _ "$SCRIPT" "$CASE_ROOT" "$UNIT/out/installed.modules"
assert_failure 'a package module manifest mismatch should fail comparison' cmp -s "$UNIT/out/mismatch.modules" "$UNIT/out/installed.modules"

mkdir -p "$UNIT/symlink-root"
ln -s "$UNIT/source/kernel-generic-6.18.40-x86_64-1.txz" "$UNIT/symlink-root/kernel-generic-6.18.40-x86_64-1.txz"
assert_failure 'a symlinked exact source candidate should fail source resolution' bash -c '
    source "$1"
    CONFIRM_ROLLBACK_KERNEL=6.18.40
    OUTPUT_DIR="$2"
    mkdir -p "$OUTPUT_DIR"
    resolve_source_package "$3"
' _ "$SCRIPT" "$UNIT/out/symlink" "$UNIT/symlink-root"

assert_not_contains 'slackpkg update' "$SCRIPT" 'source must not refresh Slackpkg metadata'
assert_not_contains 'slackpkg download' "$SCRIPT" 'source must not download packages'
assert_not_contains 'installpkg ' "$SCRIPT" 'source must not install packages'
assert_not_contains 'upgradepkg ' "$SCRIPT" 'source must not upgrade packages'
assert_not_contains 'removepkg ' "$SCRIPT" 'source must not remove packages'
assert_not_contains 'grub-mkconfig ' "$SCRIPT" 'source must not regenerate GRUB'
assert_not_contains 'mkinitrd -' "$SCRIPT" 'source must not execute mkinitrd'
assert_contains 'Copy evidence command:' "$SCRIPT" 'real execution should print the portable evidence copy command'
assert_contains '/home/$owner/' "$SCRIPT" 'evidence should be copied directly to the user home'

printf 'Current rollback reconstruction inventory harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
