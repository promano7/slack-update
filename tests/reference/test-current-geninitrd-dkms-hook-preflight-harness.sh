#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-geninitrd-dkms-hook-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-geninitrd-dkms-hook-preflight.sh
source "$SCRIPT"

HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0
pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_success 'the acceptance script should have valid Bash syntax' bash -n "$SCRIPT"
assert_contains 'dkms --version' "$SCRIPT" 'the preflight should capture only the DKMS version'
assert_contains 'dkms status' "$SCRIPT" 'the preflight should capture read-only DKMS status'
if grep -Eq '^[[:space:]]*dkms[[:space:]]+(build|install|autoinstall|remove)([[:space:]]|$)' "$SCRIPT"; then
    fail 'the preflight must not invoke a mutating DKMS action'
else
    pass
fi
if grep -Eq '^[[:space:]]*(installpkg|upgradepkg|removepkg|slackpkg|mkinitrd|geninitrd|update-grub|grub-mkconfig)[[:space:]]' "$SCRIPT"; then
    fail 'the preflight must not invoke package, initrd, or boot mutation commands'
else
    pass
fi
assert_not_contains 'bash "$path"' "$SCRIPT" 'the reviewed hook bodies must never be executed'
assert_not_contains 'sh "$path"' "$SCRIPT" 'the reviewed hook bodies must never be executed with sh'
assert_contains 'APPLY_READY=false' "$SCRIPT" 'apply readiness must remain false'
assert_contains 'APPLY_AUTHORIZED=false' "$SCRIPT" 'apply authorization must remain false'
assert_contains 'sha256sum -c' "$SCRIPT" 'portable evidence verification should be printed'
assert_contains 'custom-review-required' "$SCRIPT" 'hook content should require a later manual review'
assert_contains 'target_build_executed' "$SCRIPT" 'the result must state that no target build was executed'
assert_contains 'slackware-current-kernel-chain-restart-20260805-accepted.json' "$SCRIPT" 'the corrected chain-restart record must be the default'
assert_contains 'geninitrd-managed-versioned-initrd' "$SCRIPT" 'the corrected versioned-initrd baseline must be required'
assert_contains 'versioned-to-versioned-initrd' "$SCRIPT" 'the policy transition must remain versioned to versioned'
assert_not_contains "boot.get('boot_mode') == 'direct-generic-no-initrd'" "$SCRIPT" 'the revoked direct-no-initrd baseline must not be accepted'

is_safe_kernel_version 6.18.42 && pass || fail 'a normal kernel version should be safe'
is_safe_kernel_version '../6.18.42' && fail 'parent traversal should be rejected' || pass
is_safe_kernel_version '6.18.42 bad' && fail 'whitespace should be rejected' || pass
is_sha256 "$(printf 'a%.0s' {1..64})" && pass || fail 'a valid SHA-256 should be accepted'
is_sha256 abc && fail 'a short SHA-256 should be rejected' || pass

TARGET=slackware-current
TARGET_KERNEL=6.18.42
CONFIRM_CANDIDATES_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"
CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"
POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"
assert_success 'the accepted records should match the exact DKMS-hook transaction' validate_accepted_records
cp "$CHAIN_PREFLIGHT" "$TMP/chain-wrong-boot-mode.json"
python3 - "$TMP/chain-wrong-boot-mode.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['nested_boot_mode']='direct-generic-no-initrd'
open(p,'w').write(json.dumps(d))
PY
CHAIN_PREFLIGHT="$TMP/chain-wrong-boot-mode.json"
assert_failure 'a chain record using the revoked direct-no-initrd mode should fail closed' validate_accepted_records
CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"
cp "$NORMAL_PREFLIGHT" "$TMP/normal-missing-source.json"
python3 - "$TMP/normal-missing-source.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['candidates']['upgrade_all']=[x for x in d['candidates']['upgrade_all'] if not x.startswith('kernel-source-')]
open(p,'w').write(json.dumps(d))
PY
NORMAL_PREFLIGHT="$TMP/normal-missing-source.json"
assert_failure 'a transaction without the target kernel source candidate should fail closed' validate_accepted_records
NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
cp "$POLICY_PREFLIGHT" "$TMP/policy-wrong-hook.json"
python3 - "$TMP/policy-wrong-hook.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['executable_hooks'][0]['sha256']='0'*64
open(p,'w').write(json.dumps(d))
PY
POLICY_PREFLIGHT="$TMP/policy-wrong-hook.json"
assert_failure 'a policy record with an unreviewed hook digest should fail closed' validate_accepted_records
POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"
cp "$POLICY_PREFLIGHT" "$TMP/policy-wrong-package-link.json"
python3 - "$TMP/policy-wrong-package-link.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['package_preflight_archive_sha256']='0'*64
open(p,'w').write(json.dumps(d))
PY
POLICY_PREFLIGHT="$TMP/policy-wrong-package-link.json"
assert_failure 'a policy record detached from the accepted exact-package evidence should fail closed' validate_accepted_records
POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"

LIVE_ROOT=$TMP/live-root
mkdir -p "$LIVE_ROOT/boot/grub" "$LIVE_ROOT/etc/default" "$TMP/bin"
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/grub-script-check"
chmod 0755 "$TMP/bin/grub-script-check"
printf 'kernel\n' > "$LIVE_ROOT/boot/vmlinuz-6.18.40"
ln -s vmlinuz-6.18.40 "$LIVE_ROOT/boot/vmlinuz-generic"
printf 'initrd\n' > "$LIVE_ROOT/boot/initrd-6.18.40.img"
ln -s initrd-6.18.40.img "$LIVE_ROOT/boot/initrd-generic.img"
cat > "$LIVE_ROOT/etc/default/geninitrd" <<'EOF_POLICY'
AUTOGENERATE_INITRD=true
GENINITRD_NAMED_SYMLINK=true
GENINITRD_INITRD_GZ_SYMLINK=false
EOF_POLICY
cat > "$LIVE_ROOT/boot/grub/grub.cfg" <<'EOF_GRUB'
menuentry 'Slackware' {
  linux /boot/vmlinuz-generic root=/dev/sda2 ro
  initrd /boot/initrd-generic.img
}
EOF_GRUB
LIVE_RECORD=$TMP/live-record.json
python3 - "$BOOT_PREFLIGHT" "$LIVE_ROOT" "$LIVE_RECORD" <<'PY'
import hashlib, json, pathlib, sys
source, root, output = sys.argv[1:]
d=json.load(open(source))
r=pathlib.Path(root)
def sha(name): return hashlib.sha256((r/name).read_bytes()).hexdigest()
d['generic_kernel_sha256']=sha('boot/vmlinuz-6.18.40')
d['versioned_initrd_sha256']=sha('boot/initrd-6.18.40.img')
d['versioned_initrd_size']=(r/'boot/initrd-6.18.40.img').stat().st_size
d['active_grub_sha256']=sha('boot/grub/grub.cfg')
open(output,'w').write(json.dumps(d))
PY
OLD_PATH=$PATH
PATH="$TMP/bin:$PATH"
assert_success 'a coherent synthetic GenInitrd-managed baseline should validate' validate_live_geninitrd_baseline "$LIVE_RECORD" "$LIVE_ROOT" "$TMP/live.txt"
cp "$LIVE_RECORD" "$TMP/live-wrong-initrd.json"
python3 - "$TMP/live-wrong-initrd.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['versioned_initrd_sha256']='0'*64; open(p,'w').write(json.dumps(d))
PY
assert_failure 'a changed versioned initrd should fail closed' validate_live_geninitrd_baseline "$TMP/live-wrong-initrd.json" "$LIVE_ROOT" "$TMP/live-wrong.txt"
printf 'AUTOGENERATE_INITRD=true\nGENINITRD_NAMED_SYMLINK=false\nGENINITRD_INITRD_GZ_SYMLINK=false\n' > "$LIVE_ROOT/etc/default/geninitrd"
assert_failure 'a disabled named-initrd policy should fail closed' validate_live_geninitrd_baseline "$LIVE_RECORD" "$LIVE_ROOT" "$TMP/live-policy.txt"
printf 'AUTOGENERATE_INITRD=true\nGENINITRD_NAMED_SYMLINK=true\nGENINITRD_INITRD_GZ_SYMLINK=false\n' > "$LIVE_ROOT/etc/default/geninitrd"
PATH=$OLD_PATH

PRE=$TMP/pre
POST=$TMP/post
mkdir -p "$PRE" "$POST"
cat > "$PRE/dkms-bcachefs" <<'EOF_HOOK1'
#!/bin/bash
set -e
KERNEL_VERSION=${KERNEL_VERSION:-$(uname -r)}
/usr/sbin/dkms status
printf '%s\n' "$KERNEL_VERSION" >/dev/null
EOF_HOOK1
cat > "$PRE/dkms-nvidia" <<'EOF_HOOK2'
#!/bin/sh
set -eu
/usr/sbin/dkms status
EOF_HOOK2
chmod 0755 "$PRE/dkms-bcachefs" "$PRE/dkms-nvidia"
POLICY=$TMP/synthetic-policy.json
python3 - "$PRE" "$POLICY" <<'PY'
import hashlib,json,pathlib,sys
pre=pathlib.Path(sys.argv[1]); out=sys.argv[2]
h=[]
for name in ('dkms-bcachefs','dkms-nvidia'):
 p=pre/name
 h.append({'kind':'pre','path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'dkms':True})
json.dump({'executable_hooks':h},open(out,'w'))
PY
HOOK_OUT=$TMP/hook-out
assert_success 'two reviewed safe executable hooks should be captured' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$HOOK_OUT"
assert_equal 2 "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hook_count"])' "$HOOK_OUT/analysis.json")" 'the hook analysis should report two hooks'
assert_equal custom-review-required "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["review_status"])' "$HOOK_OUT/analysis.json")" 'the hook analysis should remain pending manual review'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_ready"]).lower())' "$HOOK_OUT/analysis.json")" 'the hook analysis must not become apply-ready'
assert_equal 600 "$(stat -c '%a' "$HOOK_OUT/dkms-bcachefs")" 'copied hook evidence should be owner-only'
assert_contains '/usr/sbin/dkms' "$HOOK_OUT/analysis.json" 'the static command surface should include the DKMS path'
assert_contains 'command-substitution' "$HOOK_OUT/analysis.json" 'shell features should be inventoried without evaluation'
assert_contains '"executed": false' "$HOOK_OUT/analysis.json" 'the analysis must record that hooks were not executed'

mkdir "$PRE/unexpected"
assert_failure 'an unsupported directory inside the hook directory should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-directory"
rmdir "$PRE/unexpected"
printf '#!/bin/sh\ntrue\n' > "$PRE/extra"
chmod 0755 "$PRE/extra"
assert_failure 'an unexpected executable hook should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-extra"
rm "$PRE/extra"
chmod 0775 "$PRE/dkms-bcachefs"
assert_failure 'a group-writable reviewed hook should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-mode"
chmod 0755 "$PRE/dkms-bcachefs"
ln -s dkms-bcachefs "$PRE/link-hook"
assert_failure 'a symlink in the hook directory should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-link"
rm "$PRE/link-hook"
printf '\n# changed\n' >> "$PRE/dkms-bcachefs"
assert_failure 'a hook digest change should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-digest"
sed -i '$d' "$PRE/dkms-bcachefs"
printf '#!/bin/bash\nif then\n' > "$PRE/dkms-bcachefs"
chmod 0755 "$PRE/dkms-bcachefs"
python3 - "$PRE" "$POLICY" <<'PY'
import hashlib,json,pathlib,sys
pre=pathlib.Path(sys.argv[1]); p=sys.argv[2]
d=json.load(open(p))
for item in d['executable_hooks']:
 if item['path'].endswith('dkms-bcachefs'):
  item['sha256']=hashlib.sha256((pre/'dkms-bcachefs').read_bytes()).hexdigest()
open(p,'w').write(json.dumps(d))
PY
assert_failure 'a syntax-invalid reviewed hook should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-syntax"
printf '#!/bin/bash\r\ntrue\r\n' > "$PRE/dkms-bcachefs"
chmod 0755 "$PRE/dkms-bcachefs"
python3 - "$PRE" "$POLICY" <<'PY'
import hashlib,json,pathlib,sys
pre=pathlib.Path(sys.argv[1]); p=sys.argv[2]
d=json.load(open(p))
for item in d['executable_hooks']:
 if item['path'].endswith('dkms-bcachefs'):
  item['sha256']=hashlib.sha256((pre/'dkms-bcachefs').read_bytes()).hexdigest()
open(p,'w').write(json.dumps(d))
PY
assert_failure 'a reviewed hook with CRLF content should fail closed' analyze_reviewed_hooks "$POLICY" "$PRE" "$POST" "$TMP/out-crlf"

TREE=$TMP/tree
mkdir -p "$TREE/a"
printf 'x\n' > "$TREE/a/file"
ln -s ../outside "$TREE/a/link"
assert_success 'a normal tree inventory should be captured without following links' capture_tree_inventory "$TREE" 3 "$TMP/tree.txt"
assert_contains 'a/file|regular|' "$TMP/tree.txt" 'regular files should be inventoried'
assert_contains 'a/link|symlink|' "$TMP/tree.txt" 'symlinks should be recorded without following them'
assert_contains '../outside' "$TMP/tree.txt" 'the symlink target should be preserved for review'
assert_success 'a missing optional tree should be represented safely' capture_tree_inventory "$TMP/missing" 2 "$TMP/missing.txt"
assert_contains '|missing' "$TMP/missing.txt" 'a missing tree should be explicit'
ln -s "$TREE" "$TMP/tree-link"
assert_failure 'a symlinked inventory root should fail closed' capture_tree_inventory "$TMP/tree-link" 2 "$TMP/tree-link.txt"

printf 'data\n' > "$TMP/file"
assert_contains 'regular|' <(capture_path_state "$TMP/file") 'regular path state should be captured'
ln -s file "$TMP/file-link"
assert_contains 'symlink|file|' <(capture_path_state "$TMP/file-link") 'symlink path state should be captured'
assert_contains 'missing||' <(capture_path_state "$TMP/not-there") 'missing path state should be captured'

(
    PASS_COUNT=12
    FAILURE_COUNT=0
    TARGET=slackware-current
    RUNNING_KERNEL=6.18.40
    TARGET_KERNEL=6.18.42
    HOOK_COUNT=2
    DKMS_STATUS_ROWS=3
    REVIEW_STATUS=custom-review-required
    write_summary "$TMP/summary.txt"
)
assert_contains 'hooks_executed=false' "$TMP/summary.txt" 'the summary should state that no hook ran'
assert_contains 'dkms_build_executed=false' "$TMP/summary.txt" 'the summary should state that no DKMS build ran'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should keep apply readiness false'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should keep apply authorization false'
assert_contains 'passes=12' "$TMP/summary.txt" 'the summary should preserve the pass count'

printf 'Slackware-current DKMS hook preflight harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
