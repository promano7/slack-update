#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-configuration-service-review-preflight.sh"
MAINTAINER_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-20260805-accepted.json"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-configuration-service-review-policy.json"
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM
HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0

pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; if "$@"; then pass "$message"; else fail "$message"; fi; }
assert_failure() { local message=$1; shift; if "$@"; then fail "$message"; else pass "$message"; fi; }
assert_equal() { local expected=$1 actual=$2 message=$3; [ "$expected" = "$actual" ] && pass "$message" || { printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual" >&2; fail "$message"; }; }
assert_contains() { local needle=$1 file=$2 message=$3; grep -Fq -- "$needle" "$file" && pass "$message" || fail "$message"; }
assert_not_matches() { local pattern=$1 file=$2 message=$3; grep -Eq -- "$pattern" "$file" && fail "$message" || pass "$message"; }
copy_json_mutation() { local src=$1 dst=$2 code=$3; python3 - "$src" "$dst" "$code" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
exec(sys.argv[3], {'d':d})
open(sys.argv[2], 'w', encoding='utf-8').write(json.dumps(d, indent=2, sort_keys=True)+'\n')
PY
}
json_value() { python3 - "$1" "$2" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
print(eval(sys.argv[2], {'d':d}))
PY
}

[ -r "$SCRIPT" ] || { printf 'missing script: %s\n' "$SCRIPT" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SCRIPT"

CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
CONFIRM_TARGET_KERNEL=6.18.42
REVIEW_POLICY=$POLICY

values=$(validate_accepted_records)
assert_equal 46 "$(printf '%s\n' "$values" | sed -n '1p')" 'the accepted boundary should enumerate 46 configuration paths'
assert_equal 44 "$(printf '%s\n' "$values" | sed -n '2p')" 'the accepted boundary should enumerate 44 service paths'

copy_json_mutation "$MAINTAINER_RECORD" "$TMP/bad-record-accepted.json" 'd["accepted"]=False'
MAINTAINER_RECORD=$TMP/bad-record-accepted.json
assert_failure 'an unaccepted maintainer record should fail closed' validate_accepted_records
MAINTAINER_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-20260805-accepted.json"
copy_json_mutation "$MAINTAINER_RECORD" "$TMP/bad-record-stage.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
MAINTAINER_RECORD=$TMP/bad-record-stage.json
assert_failure 'a maintainer record that skips configuration review should fail closed' validate_accepted_records
MAINTAINER_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-20260805-accepted.json"
copy_json_mutation "$POLICY" "$TMP/bad-policy-apply.json" 'd["apply_ready"]=True'
REVIEW_POLICY=$TMP/bad-policy-apply.json
assert_failure 'an apply-ready configuration policy should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-manifest.json" 'd["path_manifest_sha256"]="0"*64'
REVIEW_POLICY=$TMP/bad-policy-manifest.json
assert_failure 'a changed sensitive-path manifest should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-package.json" 'd["reviewed_packages"][0]["sha256"]="0"*64'
REVIEW_POLICY=$TMP/bad-policy-package.json
assert_failure 'a changed reviewed package digest should fail the accepted boundary' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-class.json" 'd["configuration_file_classes"].pop(next(iter(d["configuration_file_classes"])))'
REVIEW_POLICY=$TMP/bad-policy-class.json
assert_failure 'an unclassified regular configuration path should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-scope.json" 'd["allowed_service_prefixes"].append("usr/lib/systemd/system/")'
REVIEW_POLICY=$TMP/bad-policy-scope.json
assert_failure 'a broadened system-service scope should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-stage.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
REVIEW_POLICY=$TMP/bad-policy-stage.json
assert_failure 'the policy must not route directly to apply authorization' validate_accepted_records
REVIEW_POLICY=$POLICY

make_fixture() {
    local directory=$1 mutation=${2:-none}
    rm -rf "$directory"
    mkdir -p "$directory"
    python3 - "$directory" "$mutation" <<'PY'
import hashlib, io, json, pathlib, tarfile, sys
root=pathlib.Path(sys.argv[1]); mutation=sys.argv[2]
package='fixture-1.0-x86_64-1.txz'
files={
'etc/xdg/autostart/fixture.desktop':(0o644,b'[Desktop Entry]\nType=Application\nName=Fixture\nExec=/usr/bin/fixture --start\n','xdg-autostart-desktop'),
'etc/chromium/native-messaging-hosts/org.example.fixture.json':(0o644,b'{"name":"org.example.fixture","description":"Fixture","path":"/usr/bin/fixture-host","type":"stdio","allowed_origins":["chrome-extension://abc/"]}\n','native-messaging-json'),
'etc/xdg/logo.png':(0o644,b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR'+b'\x00'*13+b'\x00\x00\x00\x00IEND\xaeB`\x82','png-asset'),
'etc/X11/xinit/xinitrc.fixture':(0o755,b'#!/bin/sh\nprintf "%s\\n" fixture\n','shell-helper'),
'etc/pam.d/fixture.new':(0o644,b'auth include system-auth\naccount include system-auth\nsession include system-auth\n','pam-new'),
'etc/xdg/menus/fixture.menu':(0o644,b'<Menu><Name>Applications</Name></Menu>\n','xdg-menu-xml'),
'etc/xdg/fixturerc':(0o644,b'[General]\nEnabled=true\n','ini-style-config'),
'etc/stunnel/openssl.cnf.new':(0o644,b'[req]\ndistinguished_name=req_distinguished_name\n','openssl-config-new'),
'etc/stunnel/stunnel.conf-sample':(0o644,b'foreground = no\n','stunnel-sample'),
'usr/lib/systemd/user/fixture.service':(0o644,b'[Unit]\nDescription=Fixture\n[Service]\nType=simple\nExecStart=/usr/bin/fixture-service\n','systemd-user-service'),
'usr/lib/systemd/user-preset/00-fixture.preset':(0o644,b'disable fixture.service\n','systemd-user-preset'),
}
if mutation=='desktop-shell': files['etc/xdg/autostart/fixture.desktop']=(0o644,b'[Desktop Entry]\nType=Application\nName=Fixture\nExec=/usr/bin/fixture; /bin/sh\n','xdg-autostart-desktop')
elif mutation=='json-invalid': files['etc/chromium/native-messaging-hosts/org.example.fixture.json']=(0o644,b'{broken\n','native-messaging-json')
elif mutation=='png-invalid': files['etc/xdg/logo.png']=(0o644,b'not-a-png','png-asset')
elif mutation=='shell-invalid': files['etc/X11/xinit/xinitrc.fixture']=(0o755,b'#!/bin/sh\nif then\n','shell-helper')
elif mutation=='pam-invalid': files['etc/pam.d/fixture.new']=(0o644,b'execute /bin/sh\n','pam-new')
elif mutation=='xml-invalid': files['etc/xdg/menus/fixture.menu']=(0o644,b'<Menu>\n','xdg-menu-xml')
elif mutation=='unit-privileged': files['usr/lib/systemd/user/fixture.service']=(0o644,b'[Unit]\nDescription=Fixture\n[Service]\nUser=root\nExecStart=/usr/bin/fixture-service\n','systemd-user-service')
elif mutation=='unit-shell': files['usr/lib/systemd/user/fixture.service']=(0o644,b'[Unit]\nDescription=Fixture\n[Service]\nExecStart=/bin/sh -c true\n','systemd-user-service')
elif mutation=='preset-wildcard': files['usr/lib/systemd/user-preset/00-fixture.preset']=(0o644,b'enable *.service\n','systemd-user-preset')
elif mutation=='system-service':
    mode,content,cls=files.pop('usr/lib/systemd/user/fixture.service')
    files['usr/lib/systemd/system/fixture.service']=(mode,content,cls)
elif mutation=='extra-file': files['etc/xdg/unclassified.conf']=(0o644,b'value=true\n',None)

directories=set()
for path in files:
    parent=pathlib.PurePosixPath(path).parent
    while str(parent)!='.': directories.add(str(parent)); parent=parent.parent
archive=root/package
with tarfile.open(archive,'w:xz') as tar:
    for path in sorted(directories):
        info=tarfile.TarInfo(path); info.type=tarfile.DIRTYPE; info.mode=0o755; info.size=0; tar.addfile(info)
    for path,(mode,content,classification) in sorted(files.items()):
        info=tarfile.TarInfo(path); info.mode=mode; info.size=len(content); tar.addfile(info,io.BytesIO(content))
sha=hashlib.sha256(archive.read_bytes()).hexdigest(); size=archive.stat().st_size
config=[]; service=[]; config_classes={}; service_classes={}; inventory=[]
for path in sorted(directories):
    item={'package':package,'path':path,'kind':'directory','mode':'755','size':0}
    if path.startswith('etc/'):
        config.append(item); inventory.append(item)
    if path.startswith(('etc/rc.d/','usr/lib/systemd/','lib/systemd/','usr/lib64/systemd/')):
        service.append(item); inventory.append(item)
for path,(mode,content,classification) in sorted(files.items()):
    item={'package':package,'path':path,'kind':'regular','mode':format(mode,'o'),'size':len(content)}
    if path.startswith('etc/'):
        config.append(item); inventory.append(item)
        if classification is not None: config_classes[f'{package}\t{path}']=classification
    if path.startswith(('etc/rc.d/','usr/lib/systemd/','lib/systemd/','usr/lib64/systemd/')):
        service.append(item); inventory.append(item)
        if classification is not None: service_classes[f'{package}\t{path}']=classification
rows=[('configuration',x) for x in config]+[('service',x) for x in service]
manifest=''.join(f"{kind}\t{x['package']}\t{x['path']}\t{x['kind']}\t{x['mode']}\t{x['size']}\n" for kind,x in sorted(rows,key=lambda y:(y[0],y[1]['package'],y[1]['path']))).encode()
class_counts={}
for value in list(config_classes.values())+list(service_classes.values()): class_counts[value]=class_counts.get(value,0)+1
mapping={'xdg-autostart-desktop':'xdg_autostart_desktop','native-messaging-json':'native_messaging_json','shell-helper':'shell_helper','pam-new':'pam_new','xdg-menu-xml':'xdg_menu_xml','png-asset':'png_asset','ini-style-config':'ini_style_config','openssl-config-new':'openssl_config_new','stunnel-sample':'stunnel_sample','systemd-user-service':'systemd_user_service','systemd-user-preset':'systemd_user_preset'}
totals={name:class_counts.get(cls,0) for cls,name in mapping.items()}
totals.update({'configuration_paths':len(config),'configuration_directories':sum(x['kind']=='directory' for x in config),'configuration_files':sum(x['kind']=='regular' for x in config),'service_paths':len(service),'service_directories':sum(x['kind']=='directory' for x in service),'service_files':sum(x['kind']=='regular' for x in service),'systemd_system_service':0,'rc_script':0})
package_manifest=f'{package}\t{sha}\t{size}\n'.encode()
policy={'configuration_paths':config,'service_paths':service,'configuration_file_classes':config_classes,'service_file_classes':service_classes,'expected_totals':totals,'path_manifest_sha256':hashlib.sha256(manifest).hexdigest(),'reviewed_packages':[{'package':package,'sha256':sha,'size':size}],'reviewed_package_manifest_sha256':hashlib.sha256(package_manifest).hexdigest(),'expected_reviewed_package_count':1,'forbidden_service_prefixes':['etc/rc.d/','lib/systemd/system/','usr/lib/systemd/system/','usr/lib64/systemd/system/']}
(root/'policy.json').write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n')
(root/'payload-inventory.tsv').write_text(''.join(f"{x['package']}\t{x['path']}\t{x['kind']}\t{x['mode']}\t{x['size']}\t\n" for x in inventory))
(root/'cached-packages.tsv').write_text(f'{package}\t{archive}\t{sha}\t{size}\n')
PY
}

FIXTURE=$TMP/fixture
make_fixture "$FIXTURE"
REVIEW_POLICY=$FIXTURE/policy.json
values=$(analyze_configuration_service_payload "$FIXTURE" "$TMP/inventory.tsv" "$TMP/analysis.json" "$TMP/reviewed")
assert_equal 18 "$(printf '%s\n' "$values" | sed -n '1p')" 'the fixture should expose 18 configuration paths'
assert_equal 9 "$(printf '%s\n' "$values" | sed -n '2p')" 'the fixture should classify nine configuration files'
assert_equal 4 "$(printf '%s\n' "$values" | sed -n '3p')" 'the fixture should expose four service paths'
assert_equal 2 "$(printf '%s\n' "$values" | sed -n '4p')" 'the fixture should classify two service files'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '5p')" 'one exact archive should provide the fixture payload'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '6p')" 'one systemd user service should be classified'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '7p')" 'one systemd user preset should be classified'
assert_equal 0 "$(printf '%s\n' "$values" | sed -n '8p')" 'no systemd system service should be classified'
assert_equal 0 "$(printf '%s\n' "$values" | sed -n '9p')" 'no rc script should be classified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["exact_path_manifest_verified"]).lower()')" 'the exact path manifest should be verified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["exact_package_hashes_verified"]).lower()')" 'the exact package hash should be verified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["complete_file_classification"]).lower()')" 'all regular files should be classified'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["configuration_files_executed"]).lower()')" 'configuration files must remain unexecuted'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["service_files_executed"]).lower()')" 'service files must remain unexecuted'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["service_control_executed"]).lower()')" 'service control must remain unexecuted'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["configuration_service_review_complete"]).lower()')" 'the fixture should complete configuration/service review'
assert_equal current-userspace-elf-runtime-review-preflight "$(json_value "$TMP/analysis.json" 'd["next_stage"]')" 'the next stage should be ELF runtime review'
assert_contains $'configuration\tfixture-1.0-x86_64-1.txz\tetc/xdg/autostart/fixture.desktop' "$TMP/inventory.tsv" 'the desktop entry should be inventoried'
assert_contains $'service\tfixture-1.0-x86_64-1.txz\tusr/lib/systemd/user/fixture.service' "$TMP/inventory.tsv" 'the systemd user service should be inventoried'
assert_success 'reviewed files should be copied with owner-only mode' test "$(stat -c '%a' "$TMP/reviewed/fixture-1.0-x86_64-1.txz/etc/xdg/autostart/fixture.desktop")" = 600

for case in desktop-shell json-invalid png-invalid shell-invalid pam-invalid xml-invalid unit-privileged unit-shell preset-wildcard system-service extra-file; do
    make_fixture "$TMP/$case" "$case"
    REVIEW_POLICY=$TMP/$case/policy.json
    assert_failure "the $case payload mutation should fail closed" analyze_configuration_service_payload "$TMP/$case" "$TMP/$case.tsv" "$TMP/$case.json" "$TMP/$case-reviewed"
done

make_fixture "$TMP/hash-drift"
printf '0' >> "$TMP/hash-drift/fixture-1.0-x86_64-1.txz"
REVIEW_POLICY=$TMP/hash-drift/policy.json
assert_failure 'archive content drift should fail the exact package hash check' analyze_configuration_service_payload "$TMP/hash-drift" "$TMP/hash.tsv" "$TMP/hash.json" "$TMP/hash-reviewed"

make_fixture "$TMP/manifest-drift"
copy_json_mutation "$TMP/manifest-drift/policy.json" "$TMP/manifest-drift/bad-policy.json" 'd["path_manifest_sha256"]="0"*64'
REVIEW_POLICY=$TMP/manifest-drift/bad-policy.json
assert_failure 'path manifest drift should fail closed' analyze_configuration_service_payload "$TMP/manifest-drift" "$TMP/manifest.tsv" "$TMP/manifest.json" "$TMP/manifest-reviewed"

TARGET=slackware-current
EXPECTED_CONFIGURATION_PATH_COUNT=46
EXPECTED_SERVICE_PATH_COUNT=44
CONFIGURATION_PATH_COUNT=46
CONFIGURATION_FILE_COUNT=21
SERVICE_PATH_COUNT=44
SERVICE_FILE_COUNT=27
REVIEWED_PACKAGE_COUNT=19
SYSTEMD_USER_SERVICE_COUNT=26
SYSTEMD_USER_PRESET_COUNT=1
SYSTEMD_SYSTEM_SERVICE_COUNT=0
RC_SCRIPT_COUNT=0
CONFIGURATION_SERVICE_REVIEW_COMPLETE=true
NEXT_STAGE=current-userspace-elf-runtime-review-preflight
PASS_COUNT=15
FAILURE_COUNT=0
write_summary "$TMP/summary.txt"
assert_contains 'result=PASS' "$TMP/summary.txt" 'a clean summary should report PASS'
assert_contains 'configuration_path_count=46' "$TMP/summary.txt" 'the summary should preserve configuration path count'
assert_contains 'service_path_count=44' "$TMP/summary.txt" 'the summary should preserve service path count'
assert_contains 'systemd_user_service_count=26' "$TMP/summary.txt" 'the summary should expose user service count'
assert_contains 'systemd_system_service_count=0' "$TMP/summary.txt" 'the summary should deny system service payloads'
assert_contains 'configuration_service_review_complete=true' "$TMP/summary.txt" 'the summary should complete the configuration/service boundary'
assert_contains 'elf_runtime_review_complete=false' "$TMP/summary.txt" 'the summary should preserve pending ELF review'
assert_contains 'userspace_apply_review_complete=false' "$TMP/summary.txt" 'the summary should preserve incomplete userspace review'
assert_contains 'next_stage=current-userspace-elf-runtime-review-preflight' "$TMP/summary.txt" 'the summary should route to ELF runtime review'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should preserve readiness denial'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should preserve authorization denial'

assert_success 'the configuration/service preflight should have valid Bash syntax' bash -n "$SCRIPT"
assert_success 'the configuration/service preflight should be executable' test -x "$SCRIPT"
assert_not_matches '^[[:space:]]*(upgradepkg|installpkg|removepkg|slackpkg[[:space:]].*(install|upgrade|remove))([[:space:]]|$)' "$SCRIPT" 'the preflight must not change installed packages'
assert_not_matches '^[[:space:]]*(systemctl|rc-service|start-stop-daemon)[[:space:]]' "$SCRIPT" 'the preflight must not invoke a service manager'
assert_not_matches '^[[:space:]]*service[[:space:]]+[A-Za-z0-9_.@-]+[[:space:]]+(start|stop|restart|reload)([[:space:]]|$)' "$SCRIPT" 'the preflight must not use the service command'
assert_not_matches '^[[:space:]]*(source|\.|sh|bash)[[:space:]].*reviewed-files' "$SCRIPT" 'the preflight must not execute reviewed payload files'
assert_not_matches '^[[:space:]]*(mkinitrd|geninitrd|dkms|grub-mkconfig|update-grub)([[:space:]]|$)' "$SCRIPT" 'the preflight must not change boot state'
assert_contains 'configuration_file_executed=false' "$SCRIPT" 'the preflight should publish configuration non-execution explicitly'
assert_contains 'service_file_executed=false' "$SCRIPT" 'the preflight should publish service-file non-execution explicitly'
assert_contains 'service_control_executed=false' "$SCRIPT" 'the preflight should publish service-control non-execution explicitly'
assert_contains 'configuration_service_review_complete=$CONFIGURATION_SERVICE_REVIEW_COMPLETE' "$SCRIPT" 'the preflight should publish the review state'
assert_contains 'elf_runtime_review_complete=false' "$SCRIPT" 'the preflight should preserve the next review boundary'
assert_contains 'apply_ready=false' "$SCRIPT" 'the preflight should preserve readiness denial'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the preflight should preserve authorization denial'

printf 'Slackware-current configuration/service review harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
