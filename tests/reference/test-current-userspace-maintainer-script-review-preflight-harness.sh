#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-maintainer-script-review-preflight.sh"
PAYLOAD_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-20260805-accepted.json"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-policy.json"
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
assert_not_contains() { local needle=$1 file=$2 message=$3; grep -Fq -- "$needle" "$file" && fail "$message" || pass "$message"; }
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
MAINTAINER_POLICY=$POLICY

assert_success 'the accepted payload record and maintainer policy should validate' validate_accepted_records
assert_equal 37 "$(validate_accepted_records | tail -n 1)" 'the accepted boundary should enumerate 37 scripts'

copy_json_mutation "$PAYLOAD_RECORD" "$TMP/bad-payload-accepted.json" 'd["accepted"]=False'
PAYLOAD_RECORD=$TMP/bad-payload-accepted.json
assert_failure 'an unaccepted payload record should fail closed' validate_accepted_records
PAYLOAD_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-20260805-accepted.json"
copy_json_mutation "$PAYLOAD_RECORD" "$TMP/bad-payload-count.json" 'd["doinst_script_count"]=36'
PAYLOAD_RECORD=$TMP/bad-payload-count.json
assert_failure 'a changed payload script count should fail closed' validate_accepted_records
PAYLOAD_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-20260805-accepted.json"
copy_json_mutation "$PAYLOAD_RECORD" "$TMP/bad-payload-stage.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
PAYLOAD_RECORD=$TMP/bad-payload-stage.json
assert_failure 'a payload record that skips script review should fail closed' validate_accepted_records
PAYLOAD_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-20260805-accepted.json"
copy_json_mutation "$POLICY" "$TMP/bad-policy-apply.json" 'd["apply_ready"]=True'
MAINTAINER_POLICY=$TMP/bad-policy-apply.json
assert_failure 'an apply-ready maintainer policy should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-signal.json" 'd["allowed_process_signal"]["process"]="plasmashell"'
MAINTAINER_POLICY=$TMP/bad-policy-signal.json
assert_failure 'a broadened process-signal target should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-total.json" 'd["expected_action_totals"]["process_signal"]=2'
MAINTAINER_POLICY=$TMP/bad-policy-total.json
assert_failure 'changed maintainer action totals should fail closed' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-hash.json" 'd["maintainer_scripts"][0]["script_sha256"]="0"*64'
MAINTAINER_POLICY=$TMP/bad-policy-hash.json
assert_failure 'a changed script hash should fail the manifest binding' validate_accepted_records
copy_json_mutation "$POLICY" "$TMP/bad-policy-stage.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
MAINTAINER_POLICY=$TMP/bad-policy-stage.json
assert_failure 'the policy must not route directly to apply authorization' validate_accepted_records
MAINTAINER_POLICY=$POLICY

make_fixture_policy() {
    local directory=$1 output=$2
    python3 - "$directory" "$output" <<'PY'
import collections, hashlib, json, pathlib, re, sys
root=pathlib.Path(sys.argv[1]); scripts=[]; totals=collections.Counter(); rows=[]
for path in sorted(root.glob('*.sh')):
    package=path.name[:-3]; content=path.read_bytes(); counts=collections.Counter()
    for raw in content.decode().splitlines():
        line=raw.strip()
        if re.fullmatch(r'\( cd [^;]+ ; rm -rf [^ )]+ \)', line): counts['relative_remove']+=1
        elif re.fullmatch(r'\( cd [^;]+ ; ln -sf [^ ]+ [^ )]+ \)', line): counts['relative_symlink']+=1
        elif line.startswith('config '): counts['config_install']+=1
        elif line in {'mkfontscale usr/share/fonts/TTF 2> /dev/null','mkfontdir usr/share/fonts/TTF 2> /dev/null','/usr/bin/fc-cache -f 2> /dev/null','/usr/bin/update-desktop-database /usr/share/applications >/dev/null 2>&1'}: counts['cache_refresh']+=1
        elif line=='killall -TERM kscreenlocker_greet 1>/dev/null 2>/dev/null': counts['process_signal']+=1
    digest=hashlib.sha256(content).hexdigest(); totals.update(counts); rows.append(f'{package}\t{digest}\n')
    scripts.append({'package':package,'script_sha256':digest,'line_count':len(content.decode().splitlines()),'actions':dict(sorted(counts.items()))})
policy={
'scenario':'fixture','maintainer_scripts':scripts,'expected_action_totals':dict(sorted(totals.items())),
'doinst_manifest_sha256':hashlib.sha256(''.join(rows).encode()).hexdigest(),
'allowed_config_installs':[{'package':'config-1.0-x86_64-1.txz','path':'etc/example.conf.new'}],
'allowed_cache_refreshes':[
 {'package':'fonts-1.0-noarch-1.txz','command':'mkfontscale usr/share/fonts/TTF 2> /dev/null'},
 {'package':'fonts-1.0-noarch-1.txz','command':'mkfontdir usr/share/fonts/TTF 2> /dev/null'},
 {'package':'fonts-1.0-noarch-1.txz','command':'/usr/bin/fc-cache -f 2> /dev/null'}],
'allowed_process_signal':{'package':'kscreenlocker-1.0-x86_64-1.txz','script_sha256':next(x['script_sha256'] for x in scripts if x['package'].startswith('kscreenlocker-')),'command':'killall -TERM kscreenlocker_greet 1>/dev/null 2>/dev/null','process':'kscreenlocker_greet','signal':'TERM'},
'allowed_absolute_symlink_targets':['/usr/bin/target'],'relative_write_prefixes':['usr/']}
pathlib.Path(sys.argv[2]).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n')
PY
}

FIXTURE=$TMP/scripts
mkdir -p "$FIXTURE"
cat > "$FIXTURE/libfoo-1.0-x86_64-1.txz.sh" <<'EOF_SCRIPT'
( cd usr/lib64 ; rm -rf libfoo.so )
( cd usr/lib64 ; ln -sf libfoo.so.1 libfoo.so )
( cd usr/bin ; rm -rf foo-tool )
( cd usr/bin ; ln -sf /usr/bin/target foo-tool )
EOF_SCRIPT
cat > "$FIXTURE/config-1.0-x86_64-1.txz.sh" <<'EOF_SCRIPT'
config() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then
    rm $NEW
  fi
}
config etc/example.conf.new
EOF_SCRIPT
cat > "$FIXTURE/fonts-1.0-noarch-1.txz.sh" <<'EOF_SCRIPT'
#!/bin/sh
if [ -x /usr/bin/mkfontdir -o -x /usr/X11R6/bin/mkfontdir ]; then
  mkfontscale usr/share/fonts/TTF 2> /dev/null
  mkfontdir usr/share/fonts/TTF 2> /dev/null
fi
if [ -x /usr/bin/fc-cache ]; then
  /usr/bin/fc-cache -f 2> /dev/null
fi
EOF_SCRIPT
cat > "$FIXTURE/kscreenlocker-1.0-x86_64-1.txz.sh" <<'EOF_SCRIPT'
killall -TERM kscreenlocker_greet 1>/dev/null 2>/dev/null
( cd usr/lib64 ; rm -rf libKScreenLocker.so )
( cd usr/lib64 ; ln -sf libKScreenLocker.so.1 libKScreenLocker.so )
EOF_SCRIPT
make_fixture_policy "$FIXTURE" "$TMP/fixture-policy.json"
MAINTAINER_POLICY=$TMP/fixture-policy.json
assert_success 'the synthetic maintainer scripts should have valid shell syntax' validate_script_syntax "$FIXTURE"
values=$(analyze_maintainer_scripts "$FIXTURE" "$TMP/inventory.tsv" "$TMP/analysis.json")
assert_equal 4 "$(printf '%s\n' "$values" | sed -n '1p')" 'four fixture scripts should be classified'
assert_equal 3 "$(printf '%s\n' "$values" | sed -n '2p')" 'three paired removes should be classified'
assert_equal 3 "$(printf '%s\n' "$values" | sed -n '3p')" 'three paired symlinks should be classified'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '4p')" 'one config promotion should be classified'
assert_equal 3 "$(printf '%s\n' "$values" | sed -n '5p')" 'three cache refreshes should be classified'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '6p')" 'one reviewed process signal should be classified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["exact_script_hashes_verified"]).lower()')" 'exact script hashes should be verified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["complete_command_classification"]).lower()')" 'all commands should be classified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["remove_symlink_pairing_verified"]).lower()')" 'remove and symlink pairing should be verified'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["process_signal_confined_to_reviewed_exception"]).lower()')" 'the signal should remain confined'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["maintainer_scripts_executed"]).lower()')" 'analysis must not execute scripts'
assert_equal true "$(json_value "$TMP/analysis.json" 'str(d["maintainer_scripts_review_complete"]).lower()')" 'static classification should complete the script review'
assert_equal false "$(json_value "$TMP/analysis.json" 'str(d["userspace_apply_review_complete"]).lower()')" 'full userspace apply review should remain pending'
assert_equal current-userspace-configuration-service-review-preflight "$(json_value "$TMP/analysis.json" 'd["next_stage"]')" 'the next stage should review configuration and service payloads'
assert_contains $'libfoo-1.0-x86_64-1.txz\t1\trelative_remove\tusr/lib64/libfoo.so' "$TMP/inventory.tsv" 'the relative remove path should be normalized'
assert_contains $'libfoo-1.0-x86_64-1.txz\t2\trelative_symlink\tusr/lib64/libfoo.so\tusr/lib64/libfoo.so.1' "$TMP/inventory.tsv" 'the relative symlink target should be normalized'
assert_contains $'config-1.0-x86_64-1.txz\t10\tconfig_install\tetc/example.conf.new' "$TMP/inventory.tsv" 'the exact config promotion should be inventoried'
assert_contains $'kscreenlocker-1.0-x86_64-1.txz\t1\tprocess_signal\tkscreenlocker_greet\tTERM' "$TMP/inventory.tsv" 'the exact process signal should be inventoried'

make_bad_case() {
    local name=$1 code=$2
    rm -rf "$TMP/$name"
    cp -a "$FIXTURE" "$TMP/$name"
    eval "$code"
    make_fixture_policy "$TMP/$name" "$TMP/$name-policy.json"
}

make_bad_case unknown-command 'printf "touch usr/lib64/unsafe\\n" >> "$TMP/$name/libfoo-1.0-x86_64-1.txz.sh"'
MAINTAINER_POLICY=$TMP/unknown-command-policy.json
assert_failure 'an unclassified command should fail closed' analyze_maintainer_scripts "$TMP/unknown-command" "$TMP/u.tsv" "$TMP/u.json"
make_bad_case unpaired-remove 'sed -i "/ln -sf libfoo.so.1/d" "$TMP/$name/libfoo-1.0-x86_64-1.txz.sh"'
MAINTAINER_POLICY=$TMP/unpaired-remove-policy.json
assert_failure 'an unpaired recursive remove should fail closed' analyze_maintainer_scripts "$TMP/unpaired-remove" "$TMP/r.tsv" "$TMP/r.json"
make_bad_case escaping-target 'sed -i "s#ln -sf libfoo.so.1#ln -sf ../../../etc/shadow#" "$TMP/$name/libfoo-1.0-x86_64-1.txz.sh"'
MAINTAINER_POLICY=$TMP/escaping-target-policy.json
assert_failure 'an escaping symlink target should fail closed' analyze_maintainer_scripts "$TMP/escaping-target" "$TMP/e.tsv" "$TMP/e.json"
make_bad_case absolute-target 'sed -i "s#/usr/bin/target#/bin/sh#" "$TMP/$name/libfoo-1.0-x86_64-1.txz.sh"'
MAINTAINER_POLICY=$TMP/absolute-target-policy.json
assert_failure 'an unreviewed absolute symlink target should fail closed' analyze_maintainer_scripts "$TMP/absolute-target" "$TMP/a.tsv" "$TMP/a.json"
make_bad_case wrong-signal 'sed -i "s/kscreenlocker_greet/plasmashell/" "$TMP/$name/kscreenlocker-1.0-x86_64-1.txz.sh"'
MAINTAINER_POLICY=$TMP/wrong-signal-policy.json
assert_failure 'a changed process target should fail closed' analyze_maintainer_scripts "$TMP/wrong-signal" "$TMP/s.tsv" "$TMP/s.json"
make_bad_case wrong-config 'sed -i "s#etc/example.conf.new#etc/shadow.new#" "$TMP/$name/config-1.0-x86_64-1.txz.sh"'
MAINTAINER_POLICY=$TMP/wrong-config-policy.json
assert_failure 'an unreviewed config path should fail closed' analyze_maintainer_scripts "$TMP/wrong-config" "$TMP/c.tsv" "$TMP/c.json"
make_bad_case wrong-cache 'sed -i "s#usr/share/fonts/TTF#usr/share/fonts/OTF#" "$TMP/$name/fonts-1.0-noarch-1.txz.sh"'
MAINTAINER_POLICY=$TMP/wrong-cache-policy.json
assert_failure 'an unreviewed cache-refresh path should fail closed' analyze_maintainer_scripts "$TMP/wrong-cache" "$TMP/f.tsv" "$TMP/f.json"

MAINTAINER_POLICY=$TMP/fixture-policy.json
cp -a "$FIXTURE" "$TMP/missing-script"
rm "$TMP/missing-script/fonts-1.0-noarch-1.txz.sh"
assert_failure 'a missing reviewed script should fail closed' analyze_maintainer_scripts "$TMP/missing-script" "$TMP/m.tsv" "$TMP/m.json"
cp -a "$FIXTURE" "$TMP/extra-script"
printf 'true\n' > "$TMP/extra-script/extra-1.0-noarch-1.txz.sh"
assert_failure 'an extra maintainer script should fail closed' analyze_maintainer_scripts "$TMP/extra-script" "$TMP/x.tsv" "$TMP/x.json"
cp -a "$FIXTURE" "$TMP/hash-drift"
printf '# changed\n' >> "$TMP/hash-drift/libfoo-1.0-x86_64-1.txz.sh"
assert_failure 'script content drift should fail exact hash validation' analyze_maintainer_scripts "$TMP/hash-drift" "$TMP/h.tsv" "$TMP/h.json"

TARGET=slackware-current
EXPECTED_SCRIPT_COUNT=37
CLASSIFIED_SCRIPT_COUNT=37
RELATIVE_REMOVE_COUNT=1159
RELATIVE_SYMLINK_COUNT=1159
CONFIG_INSTALL_COUNT=2
CACHE_REFRESH_COUNT=5
PROCESS_SIGNAL_COUNT=1
MAINTAINER_SCRIPTS_REVIEW_COMPLETE=true
NEXT_STAGE=current-userspace-configuration-service-review-preflight
PASS_COUNT=15
FAILURE_COUNT=0
write_summary "$TMP/summary.txt"
assert_contains 'result=PASS' "$TMP/summary.txt" 'a clean summary should report PASS'
assert_contains 'classified_doinst_script_count=37' "$TMP/summary.txt" 'the summary should preserve the script count'
assert_contains 'process_signal_count=1' "$TMP/summary.txt" 'the summary should expose the reviewed process signal'
assert_contains 'maintainer_scripts_review_complete=true' "$TMP/summary.txt" 'the summary should complete the script boundary'
assert_contains 'userspace_apply_review_complete=false' "$TMP/summary.txt" 'the summary should preserve incomplete userspace review'
assert_contains 'next_stage=current-userspace-configuration-service-review-preflight' "$TMP/summary.txt" 'the summary should route to configuration and service review'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should preserve readiness denial'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should preserve authorization denial'

assert_success 'the maintainer-script preflight should have valid Bash syntax' bash -n "$SCRIPT"
assert_success 'the maintainer-script preflight should be executable' test -x "$SCRIPT"
assert_not_contains '--execute-apply' "$SCRIPT" 'the preflight must never expose execute-apply'
assert_not_contains 'upgradepkg' "$SCRIPT" 'the preflight must not install package upgrades'
assert_not_contains 'installpkg' "$SCRIPT" 'the preflight must not install package archives'
assert_not_contains 'removepkg' "$SCRIPT" 'the preflight must not remove packages'
assert_not_contains 'source "$nested_dir/doinst' "$SCRIPT" 'the preflight must not source captured scripts'
assert_not_contains 'sh "$nested_dir/doinst' "$SCRIPT" 'the preflight must not execute captured scripts through sh'
assert_not_contains 'bash "$nested_dir/doinst' "$SCRIPT" 'the preflight must not execute captured scripts through bash'
assert_not_contains 'dkms build' "$SCRIPT" 'the preflight must not build DKMS modules'
assert_not_contains 'grub-mkconfig -o' "$SCRIPT" 'the preflight must not replace GRUB configuration'
assert_not_contains 'update-grub' "$SCRIPT" 'the preflight must not invoke update-grub'
assert_contains 'maintainer_script_executed=false' "$SCRIPT" 'the preflight should publish non-execution explicitly'
assert_contains 'maintainer_scripts_review_complete=$MAINTAINER_SCRIPTS_REVIEW_COMPLETE' "$SCRIPT" 'the preflight should publish the review state'
assert_contains 'userspace_apply_review_complete=false' "$SCRIPT" 'the preflight should preserve the remaining userspace boundary'
assert_contains 'apply_ready=false' "$SCRIPT" 'the preflight should preserve readiness denial'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the preflight should preserve authorization denial'

printf 'Slackware-current maintainer-script review harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
