#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-source-and-plan-preflight.sh"

TEST_COUNT=0
FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_file_exists() { [ -f "$1" ] && [ ! -L "$1" ] && pass || fail "$2"; }
json_value() { python3 - "$1" "$2" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    if part.isdigit() and isinstance(value, list): value=value[int(part)]
    else: value=value[part]
if isinstance(value,bool): print(str(value).lower())
elif value is None: print('null')
else: print(value)
PY
}

TMP=$(mktemp -d)
cleanup() {
    if [ -n "${SIGNING_HOME:-}" ]; then
        gpgconf --homedir "$SIGNING_HOME" --kill gpg-agent >/dev/null 2>&1 || true
    fi
    rm -rf "$TMP"
}
trap cleanup EXIT
BIN="$TMP/bin"
mkdir -p "$BIN"

cat > "$BIN/grub-script-check" <<'EOF_STUB'
#!/bin/bash
[ "${GRUB_CHECK_FAIL:-0}" != 1 ] || exit 1
[ "$#" -eq 1 ] && [ -f "$1" ] && grep -q '^menuentry ' "$1"
EOF_STUB
cat > "$BIN/grub-editenv" <<'EOF_STUB'
#!/bin/bash
[ "$#" -eq 2 ] && [ "$2" = list ] && [ -f "$1" ] || exit 1
grep -E '^(next_entry|saved_entry)=' "$1" || true
EOF_STUB
cat > "$BIN/curl" <<'EOF_STUB'
#!/bin/bash
output=
url=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --output) output=$2; shift 2 ;;
        --*) shift ;;
        *) url=$1; shift ;;
    esac
done
[ -n "$output" ] && [ -n "$url" ] || exit 1
case "$url" in
    *.txz.asc) cp -- "$TEST_DOWNLOAD_SIGNATURE" "$output" ;;
    *.txz) cp -- "$TEST_DOWNLOAD_PACKAGE" "$output" ;;
    *) exit 1 ;;
esac
EOF_STUB
for command_name in mkinitrd depmod grub-mkconfig installpkg upgradepkg removepkg; do
    cat > "$BIN/$command_name" <<'EOF_STUB'
#!/bin/bash
: > "${PROHIBITED_MARKER:?}"
exit 99
EOF_STUB
    chmod 755 "$BIN/$command_name"
done
chmod 755 "$BIN/grub-script-check" "$BIN/grub-editenv" "$BIN/curl"

SIGNING_HOME="$TMP/signing-home"
mkdir -m 0700 "$SIGNING_HOME"
gpg --batch --homedir "$SIGNING_HOME" --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'Slackware Test Signing Key <test@example.invalid>' rsa2048 cert 0 >/dev/null 2>&1
SIGNING_FINGERPRINT=$(gpg --batch --homedir "$SIGNING_HOME" --with-colons --list-keys |
    awk -F: '$1=="fpr" {print $10; exit}')
gpg --batch --homedir "$SIGNING_HOME" --pinentry-mode loopback --passphrase '' \
    --quick-add-key "$SIGNING_FINGERPRINT" rsa2048 sign 0 >/dev/null 2>&1
SIGNING_SUBKEY_FINGERPRINT=$(gpg --batch --homedir "$SIGNING_HOME" --with-colons --list-keys |
    awk -F: '$1=="sub" {subkey=1; next} subkey && $1=="fpr" {print $10; exit}')
gpg --batch --homedir "$SIGNING_HOME" --armor --export "$SIGNING_FINGERPRINT" > "$TMP/signing-key.asc"

write_root_file() {
    local path=$1 content=$2 mode=${3:-644}
    mkdir -p "$(dirname -- "$path")"
    printf '%b' "$content" > "$path"
    chmod "$mode" "$path"
}

create_package() {
    local package=$1 variant=${2:-valid}
    mkdir -p "$(dirname -- "$package")"
    python3 - "$package" "$variant" <<'PY'
import io, pathlib, sys, tarfile
out=pathlib.Path(sys.argv[1]); variant=sys.argv[2]; version='6.18.40'
entries=[]
def regular(name, data, mode=0o644, uid=0, gid=0):
    entries.append(('file',name,data.encode(),mode,uid,gid,''))
def directory(name, mode=0o755, uid=0, gid=0):
    entries.append(('dir',name,b'',mode,uid,gid,''))
def symlink(name, target, uid=0, gid=0):
    entries.append(('symlink',name,b'',0o777,uid,gid,target))
regular(f'boot/vmlinuz-{version}', f'kernel-{version}\n')
directory(f'lib/modules/{version}')
directory(f'lib/modules/{version}/kernel')
directory(f'lib/modules/{version}/kernel/drivers')
if variant != 'missing-modules':
    regular(f'lib/modules/{version}/kernel/drivers/test.ko.xz', 'compressed-module\n')
    regular(f'lib/modules/{version}/modules.alias', '# aliases\n')
    regular(f'lib/modules/{version}/modules.builtin', '# builtins\n')
    regular(f'lib/modules/{version}/modules.dep', 'kernel/drivers/test.ko.xz:\n')
    symlink(f'lib/modules/{version}/build', f'../../../usr/src/linux-{version}')
regular('install/doinst.sh', '#!/bin/sh\nexit 0\n', 0o755)
if variant == 'unsafe-path': regular('../../escape', 'unsafe\n')
if variant == 'duplicate-kernel': regular(f'./boot/vmlinuz-{version}', 'duplicate\n')
if variant == 'wrong-owner':
    entries=[(kind,name,data,mode,(1000 if kind=='file' and name.startswith('lib/modules/') else uid),gid,target)
             for kind,name,data,mode,uid,gid,target in entries]
with tarfile.open(out, mode='w:xz') as archive:
    for kind,name,data,mode,uid,gid,target in entries:
        info=tarfile.TarInfo(name); info.mode=mode; info.uid=uid; info.gid=gid
        if kind=='file': info.size=len(data); archive.addfile(info,io.BytesIO(data))
        elif kind=='dir': info.type=tarfile.DIRTYPE; archive.addfile(info)
        else: info.type=tarfile.SYMTYPE; info.linkname=target; archive.addfile(info)
PY
}

sign_package() {
    local package=$1 signature=$2
    rm -f -- "$signature"
    gpg --batch --homedir "$SIGNING_HOME" --pinentry-mode loopback --passphrase '' \
        --local-user "$SIGNING_SUBKEY_FINGERPRINT!" --armor --detach-sign --output "$signature" "$package" >/dev/null 2>&1
}

create_root() {
    local root=$1
    rm -rf "$root"
    mkdir -p \
        "$root/proc/sys/kernel" "$root/etc/default" "$root/etc/grub.d" \
        "$root/boot/grub" "$root/lib/modules/6.18.42/kernel" "$root/lib/modules/6.18.40" \
        "$root/usr/sbin" "$root/usr/share/mkinitrd" "$root/var/lib/pkgtools/setup" \
        "$root/var/lib/pkgtools/packages" "$root/var/tmp"
    write_root_file "$root/etc/slackware-version" 'Slackware 15.0+\n'
    write_root_file "$root/proc/cmdline" 'BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro\n' 444
    write_root_file "$root/proc/sys/kernel/osrelease" '6.18.42\n' 444
    write_root_file "$root/boot/vmlinuz-6.18.42" 'kernel-6.18.42\n'
    write_root_file "$root/boot/initrd-6.18.42.img" 'initrd-6.18.42\n'
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    write_root_file "$root/lib/modules/6.18.42/kernel/test.ko.xz" 'active-module\n'
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
menuentry 'Slackware-15.0+, with Linux generic' --id slackware-generic {
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
    write_root_file "$root/var/lib/pkgtools/packages/kernel-generic-6.18.42-x86_64-1" 'boot/vmlinuz-6.18.42\nlib/modules/6.18.42/kernel/test.ko.xz\n'
    write_root_file "$root/var/lib/pkgtools/packages/kernel-headers-6.18.42-x86-1" 'usr/include/linux/\n'
    write_root_file "$root/var/lib/pkgtools/packages/kernel-source-6.18.42-noarch-1" 'usr/src/linux-6.18.42/\n'
    write_root_file "$root/var/lib/pkgtools/packages/grub-2.14-x86_64-3" 'usr/sbin/grub-mkconfig\n'
    write_root_file "$root/var/lib/pkgtools/packages/breeze-grub-6.7.4-x86_64-1" 'boot/grub/themes/breeze/\n'
    write_root_file "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1" 'usr/bin/dummy\n'
}

write_records_and_policy() {
    local root=$1 diagnostic=$2 geninitrd=$3 policy=$4 inventory_archive=$5
    python3 - "$root" "$diagnostic" "$geninitrd" "$policy" "$TMP/signing-key.asc" \
        "$SCRIPT" "$inventory_archive" "$SIGNING_FINGERPRINT" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1]); diagnostic=pathlib.Path(sys.argv[2]); geninitrd=pathlib.Path(sys.argv[3]); policy_path=pathlib.Path(sys.argv[4])
key=pathlib.Path(sys.argv[5]); script=pathlib.Path(sys.argv[6]); inventory=sys.argv[7]; fingerprint=sys.argv[8]
def sha(path): return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()
def size(path): return pathlib.Path(path).stat().st_size
def write(path,data): path.write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
pkgdb=root/'var/lib/pkgtools/packages'
names=sorted(p.name for p in pkgdb.iterdir() if p.is_file() and not p.is_symlink())
snapshot=''.join(f'{sha(pkgdb/name)}  {name}\n' for name in names).encode()
name_snapshot=''.join(name+'\n' for name in names).encode()
write(diagnostic,{
 'scenario':'current-rollback-reconstruction-inventory','target':'slackware-current','diagnostic':True,'accepted':False,
 'archive_sha256':inventory,'active_kernel':'6.18.42','rollback_kernel':'6.18.40',
 'rollback_modules':{'corrected_state':'empty-directory-placeholder'},'system_state_unchanged':True,
})
vector=['mkinitrd','-c','-k','6.18.40','-f','ext4','-r','/dev/sda2','-m','xhci-pci:usbhid','-u','-o','/boot/initrd.gz']
write(geninitrd,{'scenario':'current-geninitrd-command-preflight','target':'slackware-current','accepted':True,'current_command_vector':vector})
base={
 'scenario':'current-rollback-source-and-plan-preflight','target':'slackware-current','reviewed':True,
 'required_hostname_short':'pcold-slack','required_hostname_fqdn':'pcold-slack.pcold-slack.org',
 'required_root_uuid':'ba7632d7-7469-483e-830d-59c88d985866','active_kernel':'6.18.42','rollback_kernel':'6.18.40',
 'inventory_archive_sha256':inventory,'diagnostic_record_sha256':sha(diagnostic),'geninitrd_record_sha256':sha(geninitrd),
 'signing_key_sha256':sha(key),'signing_key_fingerprint':fingerprint,'plan_script_sha256':sha(script),
 'repository_metadata_refresh_allowed':False,'package_installation_allowed':False,'initrd_generation_allowed':False,
 'grub_mutation_allowed':False,'reboot_execution_allowed':False,'package_database_mutation_allowed':False,
 'source_staging_mutation_allowed':True,'depmod_execution_allowed':False,'apply_authorized':False,
 'expected_package_filename':'kernel-generic-6.18.40-x86_64-1.txz',
 'package_url':'https://example.invalid/kernel-generic-6.18.40-x86_64-1.txz',
 'signature_url':'https://example.invalid/kernel-generic-6.18.40-x86_64-1.txz.asc',
 'installed_package_count':len(names),'package_database_snapshot_sha256':hashlib.sha256(snapshot).hexdigest(),
 'package_name_snapshot_sha256':hashlib.sha256(name_snapshot).hexdigest(),
 'forbidden_package_records':['kernel-generic-6.18.40-x86_64-1','kernel-headers-6.18.40-x86-1','kernel-source-6.18.40-noarch-1'],
 'active_artifacts':{
   'kernel_sha256':sha(root/'boot/vmlinuz-6.18.42'),'kernel_size':size(root/'boot/vmlinuz-6.18.42'),
   'initrd_sha256':sha(root/'boot/initrd-6.18.42.img'),'initrd_size':size(root/'boot/initrd-6.18.42.img')},
 'geninitrd_policy':{'sha256':sha(root/'etc/default/geninitrd'),'size':size(root/'etc/default/geninitrd')},
 'geninitrd':{'sha256':sha(root/'usr/sbin/geninitrd'),'size':size(root/'usr/sbin/geninitrd')},
 'generator':{'sha256':sha(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),'size':size(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh')},
 'setup':{'sha256':sha(root/'var/lib/pkgtools/setup/setup.01.mkinitrd'),'size':size(root/'var/lib/pkgtools/setup/setup.01.mkinitrd')},
 'active_grub':{'sha256':sha(root/'boot/grub/grub.cfg'),'size':size(root/'boot/grub/grub.cfg')},
 'minimum_free_space_reserve_bytes':1024,'estimated_initrd_bytes':4096,
}
scope=(
 'operation=current-rollback-source-and-plan-preflight\n' 'target=slackware-current\n'
 'hostname_short=pcold-slack\n' 'hostname_fqdn=pcold-slack.pcold-slack.org\n'
 'active_kernel=6.18.42\n' 'rollback_kernel=6.18.40\n'
 f'root_uuid={base["required_root_uuid"]}\n' f'inventory_archive_sha256={inventory}\n'
 f'diagnostic_record_sha256={base["diagnostic_record_sha256"]}\n'
 f'geninitrd_record_sha256={base["geninitrd_record_sha256"]}\n'
 f'signing_key_sha256={base["signing_key_sha256"]}\n' f'plan_script_sha256={base["plan_script_sha256"]}\n'
).encode()
base['source_plan_scope_sha256']=hashlib.sha256(scope).hexdigest()
write(policy_path,base)
PY
}

CANONICAL_SOURCE="$TMP/canonical-source"
mkdir -p "$CANONICAL_SOURCE"
CANONICAL_PACKAGE="$CANONICAL_SOURCE/kernel-generic-6.18.40-x86_64-1.txz"
CANONICAL_SIGNATURE="$CANONICAL_PACKAGE.asc"
create_package "$CANONICAL_PACKAGE" valid
sign_package "$CANONICAL_PACKAGE" "$CANONICAL_SIGNATURE"

prepare_case() {
    local name=$1 variant=${2:-valid}
    CASE_ROOT="$TMP/$name-root"
    CASE_OUTPUT="$TMP/$name-output"
    CASE_SOURCE="$TMP/$name-source"
    CASE_DIAGNOSTIC="$TMP/$name-diagnostic.json"
    CASE_GENINITRD="$TMP/$name-geninitrd.json"
    CASE_POLICY="$TMP/$name-policy.json"
    CASE_INVENTORY_ARCHIVE=$(printf 'a%.0s' {1..64})
    CASE_MARKER="$TMP/$name-prohibited"
    create_root "$CASE_ROOT"
    mkdir -p "$CASE_SOURCE"
    CASE_PACKAGE="$CASE_SOURCE/kernel-generic-6.18.40-x86_64-1.txz"
    CASE_SIGNATURE="$CASE_PACKAGE.asc"
    if [ "$variant" = valid ]; then
        cp -- "$CANONICAL_PACKAGE" "$CASE_PACKAGE"
        cp -- "$CANONICAL_SIGNATURE" "$CASE_SIGNATURE"
    else
        create_package "$CASE_PACKAGE" "$variant"
        sign_package "$CASE_PACKAGE" "$CASE_SIGNATURE"
    fi
    write_records_and_policy "$CASE_ROOT" "$CASE_DIAGNOSTIC" "$CASE_GENINITRD" "$CASE_POLICY" "$CASE_INVENTORY_ARCHIVE"
}

run_case() {
    local scope source_mode=${CASE_SOURCE_MODE:-pre-staged}
    scope=$(json_value "$CASE_POLICY" source_plan_scope_sha256)
    local -a source_args
    if [ "$source_mode" = download ]; then
        source_args=(--source-staging-dir "$CASE_SOURCE/staging")
    else
        source_args=(--source-package "$CASE_PACKAGE" --source-signature "$CASE_SIGNATURE")
    fi
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
        SLACK_UPDATE_TEST_SPACE_AVAILABLE_BYTES="${CASE_SPACE_AVAILABLE:-10737418240}" \
        ROLLBACK_PLAN_DIAGNOSTIC_RECORD="$CASE_DIAGNOSTIC" \
        ROLLBACK_PLAN_GENINITRD_RECORD="$CASE_GENINITRD" \
        ROLLBACK_PLAN_SIGNING_KEY="$TMP/signing-key.asc" \
        ROLLBACK_PLAN_POLICY="$CASE_POLICY" \
        TEST_DOWNLOAD_PACKAGE="$CASE_PACKAGE" \
        TEST_DOWNLOAD_SIGNATURE="$CASE_SIGNATURE" \
        PROHIBITED_MARKER="$CASE_MARKER" \
        bash "$SCRIPT" \
            --target slackware-current \
            --confirm-hostname pcold-slack \
            --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
            --confirm-inventory-evidence-sha256 "$CASE_INVENTORY_ARCHIVE" \
            --confirm-active-kernel 6.18.42 \
            --confirm-rollback-kernel 6.18.40 \
            --confirm-source-plan-sha256 "${CASE_SCOPE_OVERRIDE:-$scope}" \
            "${source_args[@]}" \
            --output-dir "$CASE_OUTPUT"
}

assert_success 'the source and plan preflight should have valid shell syntax' bash -n "$SCRIPT"
assert_contains 'does not install packages' <(bash "$SCRIPT" --help) 'help should state that package installation is forbidden'
assert_contains 'Acquire or reuse the exact historical Slackware package' <(bash "$SCRIPT" --help) 'help should describe the planning boundary'

prepare_case baseline
assert_success 'a signed exact package and unchanged closed system should pass the preflight' run_case
ANALYSIS="$CASE_OUTPUT/source-and-plan-analysis.json"
PLAN="$CASE_OUTPUT/reconstruction-plan.json"
assert_equal true "$(json_value "$ANALYSIS" apply_ready)" 'a complete verified source and plan should be apply-ready'
assert_equal false "$(json_value "$ANALYSIS" apply_authorized)" 'the preflight must not authorize apply'
assert_equal pre-staged "$(json_value "$ANALYSIS" source_acquisition)" 'the explicit source pair should be classified as pre-staged'
assert_equal "$SIGNING_FINGERPRINT" "$(json_value "$ANALYSIS" source_signature.valid_fingerprint)" 'the exact primary signing-key fingerprint should be recorded'
assert_equal "$SIGNING_SUBKEY_FINGERPRINT" "$(json_value "$ANALYSIS" source_signature.signing_fingerprint)" 'the actual signing-subkey fingerprint should be recorded'
assert_equal boot/vmlinuz-6.18.40 "$(json_value "$ANALYSIS" payload.kernel_member)" 'the exact versioned kernel member should be selected'
assert_equal 4 "$(json_value "$ANALYSIS" payload.module_member_count)" 'all regular module-tree payload members should be counted'
assert_equal sufficient "$(json_value "$ANALYSIS" space_budget.state)" 'the conservative space budget should pass'
assert_equal current-rollback-reconstruction-authorized-apply-review "$(json_value "$ANALYSIS" next_stage)" 'the result should advance only to apply review'
assert_equal /boot/initrd-6.18.40.img "$(json_value "$PLAN" initrd.destination)" 'the projected initrd should be versioned'
assert_equal slackware-rollback-6.18.40 "$(json_value "$PLAN" grub.entry_id)" 'the explicit rollback GRUB id should be fixed'
assert_equal 12 "$(json_value "$PLAN" ordered_actions.11.order)" 'the plan should contain all twelve ordered actions'
assert_contains '/boot/vmlinuz-6.18.40' "$CASE_OUTPUT/projected-grub-menuentry.cfg" 'the projected GRUB entry should use the rollback kernel'
assert_contains '/boot/initrd-6.18.40.img' "$CASE_OUTPUT/projected-grub-menuentry.cfg" 'the projected GRUB entry should use the rollback initrd'
assert_contains "mkinitrd -c -k 6.18.40" "$CASE_OUTPUT/projected-mkinitrd-command.sh" 'the projected mkinitrd command should preserve the accepted vector'
assert_contains 'EXPECTED_MODULE_MANIFEST_SHA256=' "$CASE_OUTPUT/projected-apply-commands.txt" 'the apply projection should bind the module manifest'
assert_contains 'apply_authorized=false' "$CASE_OUTPUT/summary.txt" 'the summary should keep apply unauthorized'
assert_contains 'the active kernel, rollback placeholder, initrd, GenInitrd, and GRUB state remained unchanged' "$CASE_OUTPUT/assertions.log" 'the non-mutation proof should pass'
assert_file_exists "$CASE_OUTPUT/source-module-manifest.txt" 'the source module manifest should be emitted'
assert_file_exists "$CASE_OUTPUT/space-budget.json" 'the space budget should be emitted'
assert_file_exists "$CASE_OUTPUT.tar.gz" 'the evidence archive should be published'
assert_file_exists "$CASE_OUTPUT.tar.gz.sha256" 'the evidence sidecar should be published'
assert_failure 'no prohibited command should have executed during the baseline preflight' test -e "$CASE_MARKER"

prepare_case download
CASE_SOURCE_MODE=download
assert_success 'the exact package and signature should be safely acquired into private staging' run_case
assert_equal downloaded-https "$(json_value "$CASE_OUTPUT/source-and-plan-analysis.json" source_acquisition)" 'downloaded sources should be classified exactly'
assert_file_exists "$CASE_SOURCE/staging/kernel-generic-6.18.40-x86_64-1.txz" 'the downloaded package should be staged as a regular file'
assert_file_exists "$CASE_SOURCE/staging/kernel-generic-6.18.40-x86_64-1.txz.asc" 'the downloaded signature should be staged as a regular file'
unset CASE_SOURCE_MODE

prepare_case bad-signature
printf 'tamper\n' >> "$CASE_PACKAGE"
assert_failure 'a package changed after signing should fail closed' run_case

prepare_case low-space
CASE_SPACE_AVAILABLE=1
assert_failure 'an insufficient aggregate filesystem budget should fail closed' run_case
assert_equal insufficient "$(json_value "$CASE_OUTPUT/space-budget.json" state)" 'low space should be classified explicitly'
unset CASE_SPACE_AVAILABLE

prepare_case nonempty-placeholder
write_root_file "$CASE_ROOT/lib/modules/6.18.40/foreign.ko" 'foreign\n'
assert_failure 'a nonempty rollback placeholder should fail the live boundary' run_case

prepare_case existing-kernel
write_root_file "$CASE_ROOT/boot/vmlinuz-6.18.40" 'unexpected\n'
assert_failure 'an unexpected rollback kernel should fail the live boundary' run_case

prepare_case package-drift
write_root_file "$CASE_ROOT/var/lib/pkgtools/packages/unexpected-1.0-x86_64-1" 'usr/bin/unexpected\n'
assert_failure 'installed package database drift should fail closed' run_case

prepare_case next-entry
printf 'next_entry=diagnostic-shell\n' > "$CASE_ROOT/boot/grub/grubenv"
assert_failure 'a pending one-time GRUB entry should fail closed' run_case

prepare_case unsafe-path unsafe-path
assert_failure 'a signed archive containing path traversal should fail package inspection' run_case

prepare_case missing-modules missing-modules
assert_failure 'a signed package without a module object payload should fail inspection' run_case

prepare_case wrong-owner wrong-owner
assert_failure 'a signed package with non-root-owned module files should fail inspection' run_case

prepare_case scope-mismatch
CASE_SCOPE_OVERRIDE=$(printf 'b%.0s' {1..64})
assert_failure 'a mismatched explicit source-plan scope should fail closed' run_case
unset CASE_SCOPE_OVERRIDE

prepare_case wrong-fingerprint
python3 - "$CASE_POLICY" <<'PY'
import json, pathlib, sys
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text()); d['signing_key_fingerprint']='0'*40
p.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
assert_failure 'a signing-key fingerprint mismatch should fail closed' run_case

prepare_case missing-pair
rm "$CASE_SIGNATURE"
assert_failure 'an incomplete pre-staged package/signature pair should fail safely' run_case

assert_not_contains 'slackpkg update' "$SCRIPT" 'the preflight source must not refresh Slackpkg metadata'
assert_not_contains 'installpkg "' "$SCRIPT" 'the preflight source must not install a package'
assert_not_contains 'upgradepkg "' "$SCRIPT" 'the preflight source must not upgrade a package'
assert_not_contains 'removepkg "' "$SCRIPT" 'the preflight source must not remove a package'
assert_contains 'Copy evidence command:' "$SCRIPT" 'real execution should print the evidence copy command'
assert_contains 'Copy package command:' "$SCRIPT" 'real execution should print the verified package copy command'
assert_contains '/home/%s/' "$SCRIPT" 'copy commands should target the user home directly'

printf 'Current rollback source and plan preflight harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
