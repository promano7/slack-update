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
cleanup() { rm -rf "$TMP"; }
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

TEST_KEY_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/keys/slackware-test-signing-key.asc"
TEST_PACKAGE_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/test-kernel-generic-6.18.40-x86_64-1.txz"
TEST_SIGNATURE_FIXTURE="$TEST_PACKAGE_FIXTURE.asc"
cp -- "$TEST_KEY_FIXTURE" "$TMP/signing-key.asc"
SIGNING_FINGERPRINT=$(gpg --batch --show-keys --with-colons "$TMP/signing-key.asc" |
    awk -F: '$1=="fpr" {print $10; exit}')
SIGNING_SUBKEY_FINGERPRINT=$(gpg --batch --show-keys --with-colons "$TMP/signing-key.asc" |
    awk -F: '$1=="sub" {subkey=1; next} subkey && $1=="fpr" {print $10; exit}')

write_root_file() {
    local path=$1 content=$2 mode=${3:-644}
    mkdir -p "$(dirname -- "$path")"
    printf '%b' "$content" > "$path"
    chmod "$mode" "$path"
}

write_sized_root_file() {
    local path=$1 size=$2 mode=${3:-644}
    mkdir -p "$(dirname -- "$path")"
    : > "$path"
    truncate -s "$size" "$path"
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
directory('.')
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
if variant == 'unsafe-root-owner':
    entries=[(kind,name,data,mode,(1000 if name=='.' else uid),gid,target)
             for kind,name,data,mode,uid,gid,target in entries]
with tarfile.open(out, mode='w:xz') as archive:
    for kind,name,data,mode,uid,gid,target in entries:
        info=tarfile.TarInfo(name); info.mode=mode; info.uid=uid; info.gid=gid
        if kind=='file': info.size=len(data); archive.addfile(info,io.BytesIO(data))
        elif kind=='dir': info.type=tarfile.DIRTYPE; archive.addfile(info)
        else: info.type=tarfile.SYMTYPE; info.linkname=target; archive.addfile(info)
PY
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
    write_root_file "$root/lib/modules/6.18.42/kernel/test.ko.xz" 'active-module
'
    mkdir -p "$root/lib/modules/6.18.40/misc"
    chmod 755 "$root/lib/modules/6.18.40/misc"
    write_sized_root_file "$root/lib/modules/6.18.40/modules.alias.bin" 12
    write_sized_root_file "$root/lib/modules/6.18.40/modules.alias" 45
    write_sized_root_file "$root/lib/modules/6.18.40/modules.builtin.alias.bin" 0
    write_sized_root_file "$root/lib/modules/6.18.40/modules.builtin.bin" 0
    write_sized_root_file "$root/lib/modules/6.18.40/modules.dep.bin" 12
    write_sized_root_file "$root/lib/modules/6.18.40/modules.dep" 0
    write_sized_root_file "$root/lib/modules/6.18.40/modules.devname" 0
    write_sized_root_file "$root/lib/modules/6.18.40/modules.softdep" 55
    write_sized_root_file "$root/lib/modules/6.18.40/modules.symbols.bin" 12
    write_sized_root_file "$root/lib/modules/6.18.40/modules.symbols" 49
    write_sized_root_file "$root/lib/modules/6.18.40/modules.weakdep" 55
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
    local root=$1 diagnostic=$2 failed=$3 revision1_failed=$4 revision2_failed=$5 geninitrd=$6 policy=$7 inventory_archive=$8
    local failed_archive=$9 revision1_failed_archive=${10} revision2_failed_archive=${11} package=${12} signature=${13}
    python3 - "$root" "$diagnostic" "$failed" "$revision1_failed" "$revision2_failed" "$geninitrd" "$policy" "$TMP/signing-key.asc" \
        "$SCRIPT" "$inventory_archive" "$failed_archive" "$revision1_failed_archive" "$revision2_failed_archive" "$SIGNING_FINGERPRINT" "$package" "$signature" <<'PY'
import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1]); diagnostic=pathlib.Path(sys.argv[2]); failed=pathlib.Path(sys.argv[3])
revision1_failed=pathlib.Path(sys.argv[4]); revision2_failed=pathlib.Path(sys.argv[5]); geninitrd=pathlib.Path(sys.argv[6])
policy_path=pathlib.Path(sys.argv[7]); key=pathlib.Path(sys.argv[8]); script=pathlib.Path(sys.argv[9])
inventory=sys.argv[10]; failed_archive=sys.argv[11]; revision1_failed_archive=sys.argv[12]
revision2_failed_archive=sys.argv[13]; fingerprint=sys.argv[14]
package=pathlib.Path(sys.argv[15]); signature=pathlib.Path(sys.argv[16])
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
 'rollback_modules':{'corrected_state':'depmod-metadata-only-placeholder','member_count':12,'module_file_count':0},
 'system_state_unchanged':True,
})
write(failed,{
 'scenario':'current-rollback-source-and-plan-preflight-failed-diagnostic','target':'slackware-current','accepted':False,
 'archive_sha256':failed_archive,'executed_script_sha256':'37756428b0fbb9e106ce1853414f8032d803fdc6bb9ec9fef642ed82bd4c8a74',
 'system_state_mutated':False,
})
write(revision1_failed,{
 'scenario':'current-rollback-source-and-plan-preflight-revision-1-failed-diagnostic','target':'slackware-current','accepted':False,
 'archive_sha256':revision1_failed_archive,'executed_script_sha256':'8dc3eceb45c6c531aaf8e3f74e907cf4eb2b45a3aa113f43876b57405def47bd',
 'assertions':{'passes':41,'failures':1,'skips':5},'source_acquisition':'unchecked','system_state_mutated':False,
})
write(revision2_failed,{
 'scenario':'current-rollback-source-and-plan-preflight-revision-2-failed-diagnostic','target':'slackware-current','accepted':False,
 'archive_sha256':revision2_failed_archive,'executed_script_sha256':'516397c136ab9dd75d90eba7a5e1f969ef36c30e1725e05a2e3fbf3060b09c93',
 'assertions':{'passes':57,'failures':1,'skips':3},'source_acquisition':'pre-staged',
 'source_signature_valid':True,'failure_cause':'safe-root-directory-entry-rejected','system_state_mutated':False,
})
vector=['mkinitrd','-c','-k','6.18.40','-f','ext4','-r','/dev/sda2','-m','xhci-pci:usbhid','-u','-o','/boot/initrd.gz']
write(geninitrd,{'scenario':'current-geninitrd-command-preflight','target':'slackware-current','accepted':True,'current_command_vector':vector})
placeholder={
 'misc':{'kind':'directory','mode':'0755'},
 'modules.alias.bin':{'kind':'regular','mode':'0644','size':12},
 'modules.alias':{'kind':'regular','mode':'0644','size':45},
 'modules.builtin.alias.bin':{'kind':'regular','mode':'0644','size':0},
 'modules.builtin.bin':{'kind':'regular','mode':'0644','size':0},
 'modules.dep.bin':{'kind':'regular','mode':'0644','size':12},
 'modules.dep':{'kind':'regular','mode':'0644','size':0},
 'modules.devname':{'kind':'regular','mode':'0644','size':0},
 'modules.softdep':{'kind':'regular','mode':'0644','size':55},
 'modules.symbols.bin':{'kind':'regular','mode':'0644','size':12},
 'modules.symbols':{'kind':'regular','mode':'0644','size':49},
 'modules.weakdep':{'kind':'regular','mode':'0644','size':55},
}
base={
 'scenario':'current-rollback-source-and-plan-preflight-revision-3','target':'slackware-current','reviewed':True,
 'required_hostname_short':'pcold-slack','required_hostname_fqdn':'pcold-slack.pcold-slack.org',
 'required_root_uuid':'ba7632d7-7469-483e-830d-59c88d985866','active_kernel':'6.18.42','rollback_kernel':'6.18.40',
 'inventory_archive_sha256':inventory,'failed_preflight_archive_sha256':failed_archive,
 'revision_1_failed_preflight_archive_sha256':revision1_failed_archive,
 'revision_2_failed_preflight_archive_sha256':revision2_failed_archive,
 'diagnostic_record_sha256':sha(diagnostic),'failed_preflight_record_sha256':sha(failed),
 'revision_1_failed_preflight_record_sha256':sha(revision1_failed),
 'revision_2_failed_preflight_record_sha256':sha(revision2_failed),'geninitrd_record_sha256':sha(geninitrd),
 'signing_key_sha256':sha(key),'signing_key_fingerprint':fingerprint,'plan_script_sha256':sha(script),
 'repository_metadata_refresh_allowed':False,'package_installation_allowed':False,'initrd_generation_allowed':False,
 'grub_mutation_allowed':False,'reboot_execution_allowed':False,'package_database_mutation_allowed':False,
 'source_staging_mutation_allowed':True,'depmod_execution_allowed':False,'apply_authorized':False,
 'expected_package_filename':'kernel-generic-6.18.40-x86_64-1.txz',
 'expected_package_sha256':sha(package),'expected_signature_sha256':sha(signature),
 'package_url':'https://example.invalid/kernel-generic-6.18.40-x86_64-1.txz',
 'signature_url':'https://example.invalid/kernel-generic-6.18.40-x86_64-1.txz.asc',
 'required_rollback_module_state':'depmod-metadata-only-placeholder','rollback_placeholder_entries':placeholder,
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
 'operation=current-rollback-source-and-plan-preflight-revision-3\n' 'target=slackware-current\n'
 'hostname_short=pcold-slack\n' 'hostname_fqdn=pcold-slack.pcold-slack.org\n'
 'active_kernel=6.18.42\n' 'rollback_kernel=6.18.40\n'
 f'root_uuid={base["required_root_uuid"]}\n' f'inventory_archive_sha256={inventory}\n'
 f'failed_preflight_archive_sha256={failed_archive}\n'
 f'revision_1_failed_preflight_archive_sha256={revision1_failed_archive}\n'
 f'revision_2_failed_preflight_archive_sha256={revision2_failed_archive}\n'
 f'diagnostic_record_sha256={base["diagnostic_record_sha256"]}\n'
 f'failed_preflight_record_sha256={base["failed_preflight_record_sha256"]}\n'
 f'revision_1_failed_preflight_record_sha256={base["revision_1_failed_preflight_record_sha256"]}\n'
 f'revision_2_failed_preflight_record_sha256={base["revision_2_failed_preflight_record_sha256"]}\n'
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
cp -- "$TEST_PACKAGE_FIXTURE" "$CANONICAL_PACKAGE"
cp -- "$TEST_SIGNATURE_FIXTURE" "$CANONICAL_SIGNATURE"
CANONICAL_ROOT="$TMP/canonical-root"
create_root "$CANONICAL_ROOT"

prepare_case() {
    local name=$1 variant=${2:-valid}
    CASE_ROOT="$TMP/$name-root"
    CASE_OUTPUT="$TMP/$name-output"
    CASE_SOURCE="$TMP/$name-source"
    CASE_DIAGNOSTIC="$TMP/$name-diagnostic.json"
    CASE_FAILED="$TMP/$name-failed-preflight.json"
    CASE_REVISION1_FAILED="$TMP/$name-revision-1-failed-preflight.json"
    CASE_REVISION2_FAILED="$TMP/$name-revision-2-failed-preflight.json"
    CASE_GENINITRD="$TMP/$name-geninitrd.json"
    CASE_POLICY="$TMP/$name-policy.json"
    CASE_INVENTORY_ARCHIVE=$(printf 'a%.0s' {1..64})
    CASE_FAILED_ARCHIVE=$(printf 'c%.0s' {1..64})
    CASE_REVISION1_FAILED_ARCHIVE=$(printf 'd%.0s' {1..64})
    CASE_REVISION2_FAILED_ARCHIVE=$(printf 'e%.0s' {1..64})
    CASE_MARKER="$TMP/$name-prohibited"
    rm -rf "$CASE_ROOT"
    cp -a -- "$CANONICAL_ROOT" "$CASE_ROOT"
    mkdir -p "$CASE_SOURCE"
    CASE_PACKAGE="$CASE_SOURCE/kernel-generic-6.18.40-x86_64-1.txz"
    CASE_SIGNATURE="$CASE_PACKAGE.asc"
    if [ "$variant" = valid ]; then
        cp -- "$CANONICAL_PACKAGE" "$CASE_PACKAGE"
        cp -- "$CANONICAL_SIGNATURE" "$CASE_SIGNATURE"
    else
        create_package "$CASE_PACKAGE" "$variant"
        cp -- "$CANONICAL_SIGNATURE" "$CASE_SIGNATURE"
    fi
    write_records_and_policy "$CASE_ROOT" "$CASE_DIAGNOSTIC" "$CASE_FAILED" "$CASE_REVISION1_FAILED" "$CASE_REVISION2_FAILED" "$CASE_GENINITRD" "$CASE_POLICY" \
        "$CASE_INVENTORY_ARCHIVE" "$CASE_FAILED_ARCHIVE" "$CASE_REVISION1_FAILED_ARCHIVE" "$CASE_REVISION2_FAILED_ARCHIVE" "$CASE_PACKAGE" "$CASE_SIGNATURE"
}

run_case() {
    local scope source_mode=${CASE_SOURCE_MODE:-pre-staged} signature_mode=${CASE_SIGNATURE_MODE:-valid}
    [ "${CASE_REAL_GPG:-0}" = 1 ] && signature_mode=
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
        SLACK_UPDATE_TEST_SIGNATURE_MODE="$signature_mode" \
        SLACK_UPDATE_TEST_SIGNING_FINGERPRINT="$SIGNING_SUBKEY_FINGERPRINT" \
        SLACK_UPDATE_TEST_PRIMARY_FINGERPRINT="$SIGNING_FINGERPRINT" \
        ROLLBACK_PLAN_DIAGNOSTIC_RECORD="$CASE_DIAGNOSTIC" \
        ROLLBACK_PLAN_FAILED_PREFLIGHT_RECORD="$CASE_FAILED" \
        ROLLBACK_PLAN_REVISION_1_FAILED_PREFLIGHT_RECORD="$CASE_REVISION1_FAILED" \
        ROLLBACK_PLAN_REVISION_2_FAILED_PREFLIGHT_RECORD="$CASE_REVISION2_FAILED" \
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
            --confirm-failed-preflight-evidence-sha256 "$CASE_FAILED_ARCHIVE" \
            --confirm-revision-1-failed-preflight-evidence-sha256 "$CASE_REVISION1_FAILED_ARCHIVE" \
            --confirm-revision-2-failed-preflight-evidence-sha256 "$CASE_REVISION2_FAILED_ARCHIVE" \
            --confirm-active-kernel 6.18.42 \
            --confirm-rollback-kernel 6.18.40 \
            --confirm-source-plan-sha256 "${CASE_SCOPE_OVERRIDE:-$scope}" \
            "${source_args[@]}" \
            --output-dir "$CASE_OUTPUT"
}

assert_success 'the source and plan preflight should have valid shell syntax' bash -n "$SCRIPT"
assert_contains 'does not install packages' <(bash "$SCRIPT" --help) 'help should state that package installation is forbidden'
assert_contains 'Acquire or reuse the exact historical Slackware package' <(bash "$SCRIPT" --help) 'help should describe the planning boundary'

prepare_case missing-pair
rm "$CASE_SIGNATURE"
assert_failure 'an incomplete pre-staged package/signature pair should fail safely' run_case
assert_contains $'source-signature-lstat\tFAIL' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'a missing signature should identify the exact failed lstat check'
assert_contains $'source-signature-open-nofollow\tSKIP' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'dependent signature-open diagnostics should be skipped after missing lstat'

prepare_case symlink-package
rm "$CASE_PACKAGE"
ln -s "$CANONICAL_PACKAGE" "$CASE_PACKAGE"
assert_failure 'a symbolic-link pre-staged package should be rejected safely' run_case
assert_contains $'source-package-no-symbolic-link\tFAIL' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'a symbolic-link package should identify the exact no-link failure'
assert_contains $'source-package-open-nofollow\tSKIP' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'safe opening should be skipped for a rejected symbolic link'

prepare_case mode-0600
chmod 0600 "$CASE_PACKAGE" "$CASE_SIGNATURE"
assert_success 'owner-only regular pre-staged source files should pass acquisition and verification' run_case
assert_contains $'source-package-open-nofollow\tPASS' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'a mode-0600 package should open safely under the root preflight'

prepare_case safe-archive-root safe-root
assert_success 'one safe root-directory archive member should be accepted and excluded from payload paths' run_case
assert_equal 1 "$(json_value "$CASE_OUTPUT/source-package.json" archive_root_directory_count)" 'the safe archive root directory should be recorded exactly once'
assert_contains 'package inspection completed successfully' "$CASE_OUTPUT/source-package-inspection.log" 'successful package inspection should publish a deterministic diagnostic log'
assert_not_contains 'Traceback' "$CASE_OUTPUT/source-package-inspection.log" 'successful package inspection must not emit a Python traceback'

prepare_case unsafe-archive-root-owner unsafe-root-owner
assert_failure 'a non-root-owned archive root directory should fail package inspection' run_case
assert_contains 'archive root directory is not root-owned' "$CASE_OUTPUT/source-package-inspection.log" 'the unsafe root-directory owner should be diagnosed exactly'
assert_failure 'failed inspection must not publish a partial package summary' test -e "$CASE_OUTPUT/source-package.json"
assert_failure 'failed inspection must not publish a partial module manifest' test -e "$CASE_OUTPUT/source-module-manifest.txt"

prepare_case baseline
CASE_REAL_GPG=1
assert_success 'a signed exact package and unchanged closed system should pass the preflight with real GnuPG verification' run_case
unset CASE_REAL_GPG
ANALYSIS="$CASE_OUTPUT/source-and-plan-analysis.json"
PLAN="$CASE_OUTPUT/reconstruction-plan.json"
assert_equal true "$(json_value "$ANALYSIS" apply_ready)" 'a complete verified source and plan should be apply-ready'
assert_equal false "$(json_value "$ANALYSIS" apply_authorized)" 'the preflight must not authorize apply'
assert_equal depmod-metadata-only-placeholder "$(json_value "$ANALYSIS" rollback_module_state)" 'the observed rollback directory should be classified as metadata-only'
assert_equal 0 "$(json_value "$ANALYSIS" assertions.skips)" 'a successful baseline should not skip any stage'
assert_equal pre-staged "$(json_value "$ANALYSIS" source_acquisition)" 'the explicit source pair should be classified as pre-staged'
assert_equal "$(sha256sum "$CASE_PACKAGE" | awk '{print $1}')" "$(json_value "$ANALYSIS" source_package.sha256)" 'the safely opened package digest should be recorded before signature verification'
assert_equal "$(sha256sum "$CASE_SIGNATURE" | awk '{print $1}')" "$(json_value "$ANALYSIS" source_signature.sha256)" 'the safely opened signature digest should be recorded before signature verification'
assert_contains $'source-package-open-nofollow\tPASS' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'the package should be opened without following symbolic links'
assert_contains $'source-signature-open-nofollow\tPASS' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'the signature should be opened without following symbolic links'
assert_contains $'source-package-sha256\tPASS' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'the package digest should match during acquisition'
assert_contains $'source-signature-sha256\tPASS' "$CASE_OUTPUT/source-acquisition-checks.tsv" 'the signature digest should match during acquisition'
assert_file_exists "$CASE_OUTPUT/source-acquisition.json" 'source acquisition metadata should be emitted'
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
assert_contains 'modules.metadata-placeholder.original' "$CASE_OUTPUT/projected-apply-commands.txt" 'the apply projection should move the metadata placeholder into the backup'
assert_not_contains 'rmdir -- /lib/modules/6.18.40' "$CASE_OUTPUT/projected-apply-commands.txt" 'the apply projection must not assume an empty rollback directory'
assert_contains 'apply_authorized=false' "$CASE_OUTPUT/summary.txt" 'the summary should keep apply unauthorized'
assert_contains 'the active kernel, rollback placeholder, initrd, GenInitrd, and GRUB state remained unchanged' "$CASE_OUTPUT/assertions.log" 'the non-mutation proof should pass'
assert_file_exists "$CASE_OUTPUT/source-module-manifest.txt" 'the source module manifest should be emitted'
assert_file_exists "$CASE_OUTPUT/space-budget.json" 'the space budget should be emitted'
assert_file_exists "$CASE_OUTPUT.tar.gz" 'the evidence archive should be published'
assert_file_exists "$CASE_OUTPUT.tar.gz.sha256" 'the evidence sidecar should be published'
assert_failure 'no prohibited command should have executed during the baseline preflight' test -e "$CASE_MARKER"

prepare_case long-output-path
CASE_OUTPUT="$TMP/$(printf 'evidence-path-segment-%.0s' {1..5})/slackware-current-long-output"
CASE_REAL_GPG=1
assert_success 'a long evidence path should not affect isolated gpgv verification' run_case
unset CASE_REAL_GPG
assert_contains '/tmp/slack-update-gpgv.' "$CASE_OUTPUT/gpg-keyring-directory.txt" 'gpgv should use a short isolated keyring directory outside the evidence tree'
GPG_KEYRING_DIR_USED=$(cat "$CASE_OUTPUT/gpg-keyring-directory.txt")
assert_failure 'the temporary gpgv keyring directory should be removed after verification' test -e "$GPG_KEYRING_DIR_USED"

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
assert_equal 1 "$(json_value "$CASE_OUTPUT/source-and-plan-analysis.json" assertions.failures)" 'a bad signature should produce one root failure rather than dependent false failures'
assert_equal 5 "$(json_value "$CASE_OUTPUT/source-and-plan-analysis.json" assertions.skips)" 'signature, package, space, plan, and readiness stages should be skipped after acquisition detects a digest mismatch'
assert_contains 'source acquisition [source-package-sha256]' "$CASE_OUTPUT/assertions.log" 'the exact package digest mismatch should be identified during acquisition'

prepare_case low-space
CASE_SPACE_AVAILABLE=1
assert_failure 'an insufficient aggregate filesystem budget should fail closed' run_case
assert_equal insufficient "$(json_value "$CASE_OUTPUT/space-budget.json" state)" 'low space should be classified explicitly'
unset CASE_SPACE_AVAILABLE

prepare_case nonempty-placeholder
write_root_file "$CASE_ROOT/lib/modules/6.18.40/foreign.ko" 'foreign\n'
assert_failure 'an unexpected rollback module object should fail the live boundary' run_case
assert_contains 'live boundary [rollback-module-objects-absent]' "$CASE_OUTPUT/assertions.log" 'the exact rollback-module boundary failure should be identified'

prepare_case metadata-placeholder-drift
truncate -s 46 "$CASE_ROOT/lib/modules/6.18.40/modules.alias"
assert_failure 'changed depmod placeholder metadata should fail the live boundary' run_case
assert_contains 'live boundary [rollback-placeholder-metadata]' "$CASE_OUTPUT/assertions.log" 'the exact placeholder metadata failure should be identified'

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

assert_not_contains 'slackpkg update' "$SCRIPT" 'the preflight source must not refresh Slackpkg metadata'
assert_not_contains 'installpkg "' "$SCRIPT" 'the preflight source must not install a package'
assert_not_contains 'upgradepkg "' "$SCRIPT" 'the preflight source must not upgrade a package'
assert_not_contains 'removepkg "' "$SCRIPT" 'the preflight source must not remove a package'
assert_contains 'mktemp -d /tmp/slack-update-gpgv.' "$SCRIPT" 'the preflight should use a short isolated gpgv keyring directory'
assert_not_contains 'local home=$OUTPUT_DIR/gnupg' "$SCRIPT" 'the preflight must not nest GNUPGHOME below the evidence path'
assert_contains "if name in ('','.'): return None" "$SCRIPT" 'the package inspector should recognize a normalized archive root entry'
assert_contains "archive root directory is not root-owned" "$SCRIPT" 'the package inspector should constrain root-entry ownership'
assert_contains 'source-package-inspection.log' "$SCRIPT" 'package inspection failures should produce a deterministic diagnostic log'
assert_contains '[ -f "$summary" ]' "$SCRIPT" 'the package inspector should require both outputs before parsing them'
assert_contains 'record_skip' "$SCRIPT" 'dependent stages should be represented as skips'
assert_contains '[ "$TEST_MODE" = 1 ]' "$SCRIPT" 'the signature bypass must remain restricted to test mode'
assert_contains 'Copy evidence command:' "$SCRIPT" 'real execution should print the evidence copy command'
assert_contains 'Copy package command:' "$SCRIPT" 'real execution should print the verified package copy command'
assert_contains '/home/%s/' "$SCRIPT" 'copy commands should target the user home directly'

printf 'Current rollback source and plan preflight harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
