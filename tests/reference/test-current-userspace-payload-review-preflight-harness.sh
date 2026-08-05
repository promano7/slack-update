#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-payload-review-preflight.sh"
BASELINE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
REVIEW="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-userspace-candidate-review-20260805-accepted.json"
REBIND="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-evidence-rebind-20260805-accepted.json"
POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-policy.json"
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

BASELINE_PREFLIGHT=$BASELINE
USERSPACE_REVIEW=$REVIEW
REBIND_RECORD=$REBIND
PAYLOAD_POLICY=$POLICY
CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
CONFIRM_TARGET_KERNEL=6.18.42

assert_success 'the accepted payload-review boundary should validate' validate_accepted_records "$TMP/expected.txt"
assert_equal 68 "$(wc -l < "$TMP/expected.txt")" 'the accepted review should enumerate 68 packages'
assert_contains 'breeze-grub-6.7.4-x86_64-1.txz' "$TMP/expected.txt" 'the exact GRUB theme package should be included'
assert_contains 'stunnel-5.80-x86_64-1.txz' "$TMP/expected.txt" 'the supporting service package should be included'
assert_equal 68 "$(sort -u "$TMP/expected.txt" | wc -l)" 'every reviewed package should be unique'

copy_json_mutation "$REBIND" "$TMP/bad-rebind.json" 'd["kernel_evidence_rebound"]=False'
REBIND_RECORD=$TMP/bad-rebind.json
assert_failure 'an uncompleted kernel rebind should block payload review' validate_accepted_records "$TMP/bad-expected.txt"
REBIND_RECORD=$REBIND
copy_json_mutation "$REBIND" "$TMP/bad-rebind-stage.json" 'd["next_stage"]="normal-update-apply-authorization-review"'
REBIND_RECORD=$TMP/bad-rebind-stage.json
assert_failure 'a rebind record that skips payload review should fail closed' validate_accepted_records "$TMP/bad-stage.txt"
REBIND_RECORD=$REBIND
copy_json_mutation "$POLICY" "$TMP/bad-policy-apply.json" 'd["apply_ready"]=True'
PAYLOAD_POLICY=$TMP/bad-policy-apply.json
assert_failure 'an apply-ready payload policy should fail closed' validate_accepted_records "$TMP/bad-policy.txt"
PAYLOAD_POLICY=$POLICY
copy_json_mutation "$POLICY" "$TMP/bad-policy-count.json" 'd["expected_package_count"]=67'
PAYLOAD_POLICY=$TMP/bad-policy-count.json
assert_failure 'a payload policy with the wrong package count should fail closed' validate_accepted_records "$TMP/bad-count.txt"
PAYLOAD_POLICY=$POLICY
CONFIRM_CANDIDATES_SHA256=0
assert_failure 'a malformed candidate confirmation should not validate accepted records' validate_accepted_records "$TMP/bad-digest.txt"
CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926

python3 - "$BASELINE" "$REVIEW" "$TMP/fresh" <<'PY'
import json, pathlib, sys
base=json.load(open(sys.argv[1], encoding='utf-8'))['candidates']
review=json.load(open(sys.argv[2], encoding='utf-8'))
root=pathlib.Path(sys.argv[3]); root.mkdir(parents=True)
added=sum(review['categories'].values(), [])
install=sorted(base['install_new'])
upgrade=sorted(base['upgrade_all']+added)
allc=sorted(install+upgrade)
for name, values in [('install-new.candidates.txt',install),('upgrade-all.candidates.txt',upgrade),('all.candidates.txt',allc),('critical.candidates.txt',[])]:
    (root/name).write_text(''.join(x+'\n' for x in values), encoding='utf-8')
summary={'scenario':'normal-update','mode':'preflight','target':'slackware-current','result':'PASS','candidate_set_sha256':review['fresh_candidate_set_sha256'],'critical_candidates':'0'}
(root/'summary.txt').write_text(''.join(f'{k}={v}\n' for k,v in summary.items()), encoding='utf-8')
PY
assert_success 'the exact fresh 137-candidate set should validate before downloads' validate_nested_candidates "$TMP/fresh"
cp -a "$TMP/fresh" "$TMP/fresh-missing"
sed -i '/stunnel-5.80-x86_64-1.txz/d' "$TMP/fresh-missing/all.candidates.txt" "$TMP/fresh-missing/upgrade-all.candidates.txt"
assert_failure 'a missing reviewed package should block payload inspection' validate_nested_candidates "$TMP/fresh-missing"
cp -a "$TMP/fresh" "$TMP/fresh-critical"
printf '%s\n' 'stunnel-5.80-x86_64-1.txz' > "$TMP/fresh-critical/critical.candidates.txt"
assert_failure 'a new critical userspace candidate should block payload inspection' validate_nested_candidates "$TMP/fresh-critical"

SLACKPKG_PKGLIST=$TMP/pkglist
python3 - "$TMP/expected.txt" "$SLACKPKG_PKGLIST" <<'PY'
import pathlib, sys
out=[]
for filename in pathlib.Path(sys.argv[1]).read_text().splitlines():
    stem=filename[:-4]
    name, version, arch, build=stem.rsplit('-',3)
    out.append(f'slackware64 {name} {version} {arch} {build} {filename}\n')
pathlib.Path(sys.argv[2]).write_text(''.join(out), encoding='utf-8')
PY
assert_success 'all 68 exact repository records should resolve' resolve_repository_records "$TMP/expected.txt" "$TMP/repository.tsv"
assert_equal 68 "$(wc -l < "$TMP/repository.tsv")" 'the repository map should contain 68 rows'
cp "$SLACKPKG_PKGLIST" "$TMP/pkglist-duplicate"
head -n 1 "$SLACKPKG_PKGLIST" >> "$TMP/pkglist-duplicate"
SLACKPKG_PKGLIST=$TMP/pkglist-duplicate
assert_failure 'duplicate repository identities should fail closed' resolve_repository_records "$TMP/expected.txt" "$TMP/duplicate.tsv"
SLACKPKG_PKGLIST=$TMP/pkglist

PACKAGE_CACHE_ROOT=$TMP/cache
mkdir -p "$PACKAGE_CACHE_ROOT/slackware64/x"
python3 - "$TMP/expected.txt" "$PACKAGE_CACHE_ROOT/slackware64/x" <<'PY'
import io, json, pathlib, tarfile, sys
names=pathlib.Path(sys.argv[1]).read_text().splitlines(); root=pathlib.Path(sys.argv[2])
for index, filename in enumerate(names):
    path=root/filename
    with tarfile.open(path, 'w:xz') as tar:
        def add(name, data=b'x', mode=0o644, kind='file', link=''):
            info=tarfile.TarInfo(name); info.mode=mode
            if kind=='file': info.size=len(data); tar.addfile(info, io.BytesIO(data))
            elif kind=='dir': info.type=tarfile.DIRTYPE; tar.addfile(info)
            elif kind=='symlink': info.type=tarfile.SYMTYPE; info.linkname=link; tar.addfile(info)
        if filename == 'breeze-grub-6.7.4-x86_64-1.txz':
            add('usr/share/grub/themes/breeze/theme.txt', b'theme')
        elif filename == 'stunnel-5.80-x86_64-1.txz':
            add('etc/stunnel/stunnel.conf.new', b'config')
            add('etc/rc.d/rc.stunnel.new', b'#!/bin/sh\n', 0o755)
        elif filename == 'SDL3-3.4.14-x86_64-1.txz':
            add('usr/lib64/libSDL3.so.0', b'\x7fELFfixture')
        else:
            add(f'usr/share/review/{index}.txt', b'payload')
        if index < 3:
            add('install/doinst.sh', b'#!/bin/sh\ntrue\n', 0o755)
PY
assert_success 'the exact 68 cached archives should resolve into a manifest' resolve_cached_manifest "$TMP/expected.txt" "$TMP/cache.tsv"
assert_equal 68 "$(wc -l < "$TMP/cache.tsv")" 'the cache manifest should contain 68 rows'
OUTPUT_DIR=$TMP/output
mkdir -p "$OUTPUT_DIR"
values=$(inspect_payload_archives "$TMP/cache.tsv" "$OUTPUT_DIR")
assert_equal 68 "$(printf '%s\n' "$values" | sed -n '1p')" 'all 68 package payloads should be inspected'
assert_equal 3 "$(printf '%s\n' "$values" | sed -n '2p')" 'three fixture maintainer scripts should be captured'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '4p')" 'the service fixture should expose one service-adjacent path'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '5p')" 'the fixture should identify one ELF payload'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '6p')" 'the GRUB theme should be the only boot-adjacent payload path'
assert_success 'all captured maintainer scripts should be syntax-valid' validate_doinst_syntax "$OUTPUT_DIR/doinst"
assert_equal true "$(json_value "$OUTPUT_DIR/package-payload-summary.json" 'str(d["package_payloads_inspected"]).lower()')" 'the payload summary should record completed archive inspection'
assert_equal true "$(json_value "$OUTPUT_DIR/package-payload-summary.json" 'str(d["payload_path_review_complete"]).lower()')" 'the payload path review should be complete'
assert_equal false "$(json_value "$OUTPUT_DIR/package-payload-summary.json" 'str(d["maintainer_scripts_review_complete"]).lower()')" 'maintainer-script review should remain pending'
assert_equal false "$(json_value "$OUTPUT_DIR/package-payload-summary.json" 'str(d["userspace_apply_review_complete"]).lower()')" 'userspace apply review should remain incomplete'
assert_equal current-userspace-maintainer-script-review-preflight "$(json_value "$OUTPUT_DIR/package-payload-summary.json" 'd["next_stage"]')" 'the next stage should review maintainer scripts'
assert_contains 'breeze-grub-6.7.4-x86_64-1.txz' "$OUTPUT_DIR/payload-inventory.tsv" 'the inventory should retain the GRUB theme identity'
assert_contains 'etc/rc.d/rc.stunnel.new' "$OUTPUT_DIR/payload-inventory.tsv" 'the inventory should retain service-adjacent paths'

make_bad_archive() {
    local source=$1 destination=$2 mode=$3
    python3 - "$source" "$destination" "$mode" <<'PY'
import io, tarfile, sys
src,dst,mode=sys.argv[1:]
with tarfile.open(dst,'w:xz') as tar:
    def add(name,data=b'x',perm=0o644,kind='file',link=''):
        info=tarfile.TarInfo(name); info.mode=perm
        if kind=='file': info.size=len(data); tar.addfile(info,io.BytesIO(data))
        elif kind=='symlink': info.type=tarfile.SYMTYPE; info.linkname=link; tar.addfile(info)
    if mode=='boot': add('boot/vmlinuz-bad')
    elif mode=='grub': add('usr/share/grub/themes/unreviewed/theme.txt')
    elif mode=='escape': add('usr/lib64/link',kind='symlink',link='../../../etc/passwd')
    elif mode=='setuid': add('usr/bin/bad',perm=0o4755)
    elif mode=='missing-theme': add('usr/share/doc/breeze-grub/readme')
PY
}

first=$(head -n 1 "$TMP/cache.tsv")
first_name=${first%%$'\t'*}
first_path=$(printf '%s' "$first" | cut -f2)
for mode in boot grub escape setuid; do
    bad_dir=$TMP/bad-$mode; cp -a "$PACKAGE_CACHE_ROOT" "$bad_dir"
    bad_path=$(find "$bad_dir" -type f -name "$first_name")
    make_bad_archive "$first_path" "$bad_path" "$mode"
    python3 - "$TMP/cache.tsv" "$bad_dir" "$TMP/bad-$mode.tsv" <<'PY'
import hashlib,pathlib,sys
source=pathlib.Path(sys.argv[1]).read_text().splitlines(); root=pathlib.Path(sys.argv[2]); out=[]
for row in source:
    filename=row.split('\t')[0]; path=next(root.rglob(filename)); data=path.read_bytes()
    out.append(f'{filename}\t{path}\t{hashlib.sha256(data).hexdigest()}\t{len(data)}\n')
pathlib.Path(sys.argv[3]).write_text(''.join(out))
PY
    assert_failure "a $mode payload should fail closed" inspect_payload_archives "$TMP/bad-$mode.tsv" "$TMP/out-$mode"
done

breeze=breeze-grub-6.7.4-x86_64-1.txz
bad_dir=$TMP/bad-theme; cp -a "$PACKAGE_CACHE_ROOT" "$bad_dir"
make_bad_archive "$(find "$PACKAGE_CACHE_ROOT" -type f -name "$breeze")" "$(find "$bad_dir" -type f -name "$breeze")" missing-theme
python3 - "$TMP/cache.tsv" "$bad_dir" "$TMP/bad-theme.tsv" <<'PY'
import hashlib,pathlib,sys
source=pathlib.Path(sys.argv[1]).read_text().splitlines(); root=pathlib.Path(sys.argv[2]); out=[]
for row in source:
    filename=row.split('\t')[0]; path=next(root.rglob(filename)); data=path.read_bytes()
    out.append(f'{filename}\t{path}\t{hashlib.sha256(data).hexdigest()}\t{len(data)}\n')
pathlib.Path(sys.argv[3]).write_text(''.join(out))
PY
assert_failure 'a breeze-grub archive without the reviewed theme prefix should fail closed' inspect_payload_archives "$TMP/bad-theme.tsv" "$TMP/out-theme"

EXPECTED_PACKAGE_COUNT=68
INSPECTED_PACKAGE_COUNT=68
DOINST_SCRIPT_COUNT=3
CONFIG_PATH_COUNT=2
SERVICE_PATH_COUNT=1
ELF_FILE_COUNT=1
BOOT_THEME_PATH_COUNT=1
PAYLOAD_PATH_REVIEW_COMPLETE=true
NEXT_STAGE=current-userspace-maintainer-script-review-preflight
PASS_COUNT=16
FAILURE_COUNT=0
TARGET=slackware-current
write_summary "$TMP/summary.txt"
assert_contains 'package_payloads_inspected=true' "$TMP/summary.txt" 'the summary should expose completed payload inspection'
assert_contains 'maintainer_scripts_review_complete=false' "$TMP/summary.txt" 'the summary should preserve pending script review'
assert_contains 'userspace_apply_review_complete=false' "$TMP/summary.txt" 'the summary should deny completed userspace review'
assert_contains 'next_stage=current-userspace-maintainer-script-review-preflight' "$TMP/summary.txt" 'the summary should route to maintainer-script review'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should deny readiness'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should deny authorization'

assert_success 'the payload-review script should have valid Bash syntax' bash -n "$SCRIPT"
assert_success 'the payload-review script should be executable' test -x "$SCRIPT"
assert_not_contains '--execute-apply' "$SCRIPT" 'the payload-review script must never expose execute-apply'
assert_not_contains 'upgradepkg' "$SCRIPT" 'the payload-review script must not install package archives'
assert_not_contains 'installpkg' "$SCRIPT" 'the payload-review script must not install new package archives'
assert_not_contains 'removepkg' "$SCRIPT" 'the payload-review script must not remove packages'
assert_not_contains 'dkms build' "$SCRIPT" 'the payload-review script must not build DKMS modules'
assert_not_contains 'grub-mkconfig -o' "$SCRIPT" 'the payload-review script must not replace GRUB configuration'
assert_not_contains 'update-grub' "$SCRIPT" 'the payload-review script must not invoke update-grub'
assert_not_contains 'eval ' "$SCRIPT" 'the payload-review script must not evaluate generated shell code'
assert_contains 'package_payloads_inspected=$PAYLOAD_PATH_REVIEW_COMPLETE' "$SCRIPT" 'the script should publish the payload inspection state'
assert_contains 'maintainer_scripts_review_complete=false' "$SCRIPT" 'the script should preserve the maintainer-script boundary'
assert_contains 'apply_ready=false' "$SCRIPT" 'the script should preserve readiness denial'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the script should preserve authorization denial'

printf 'Slackware-current userspace payload review harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
