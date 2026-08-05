#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-geninitrd-command-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-geninitrd-command-preflight.sh
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
assert_contains 'command-output mode only' "$SCRIPT" 'the help should state the non-executing generator mode'
assert_contains 'timeout 30 "$GENERATOR_SCRIPT" -k "$RUNNING_KERNEL"' "$SCRIPT" 'the generator should run only for the installed kernel'
assert_not_contains ' --run' <(grep -E '^[[:space:]]*timeout ' "$SCRIPT") 'the generator invocation must not use --run'
assert_not_contains 'eval ' "$SCRIPT" 'the generated command must never be evaluated'
assert_not_contains 'bash -c "$PROJECTED_COMMAND"' "$SCRIPT" 'the projected command must never be passed to a shell'
assert_not_contains 'b588e9e74258baaf2d5e05a1731981cb679f5665d50a3a91d9f02219c4a8024a' "$SCRIPT" 'the preflight must not retain the stale 6.18.41 package digest'
assert_not_contains 'e9e7a1c5c71c945ee99595868aa8fee8a644b56601ece0c3e5696d643fe84878' "$SCRIPT" 'the preflight must not duplicate the accepted 6.18.42 package digest in code'
assert_contains 'REVIEWED_PACKAGE_SHA256' "$SCRIPT" 'the cache check should use the package identity loaded from accepted evidence'
if grep -Eq '^[[:space:]]*(mkinitrd|geninitrd|update-grub|grub-mkconfig|installpkg|upgradepkg|removepkg|slackpkg)[[:space:]]' "$SCRIPT"; then
    fail 'the preflight must not invoke package, initrd, or GRUB mutation commands'
else
    pass
fi
assert_contains 'generated_command_executed=false' "$SCRIPT" 'the evidence must state that the generated command was not executed'
assert_contains 'mkinitrd_executed=false' "$SCRIPT" 'the summary must deny mkinitrd execution'
assert_contains 'geninitrd_executed=false' "$SCRIPT" 'the summary must deny geninitrd execution'
assert_contains 'update_grub_executed=false' "$SCRIPT" 'the summary must deny GRUB updates'
assert_contains 'APPLY_READY=false' "$SCRIPT" 'apply readiness must remain false'
assert_contains 'APPLY_AUTHORIZED=false' "$SCRIPT" 'apply authorization must remain false'
assert_contains 'sha256sum -c' "$SCRIPT" 'portable evidence verification should be printed'
assert_contains '/home/$owner/' "$SCRIPT" 'evidence should be copied directly to the user home directory'
assert_contains 'slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json' "$SCRIPT" 'the corrected DKMS record must be the default'
assert_contains 'geninitrd-managed-versioned-initrd' "$SCRIPT" 'the corrected versioned-initrd baseline must be required'
assert_contains 'versioned-to-versioned-initrd' "$SCRIPT" 'the command projection must preserve the versioned-to-versioned transition'
assert_contains 'validate_live_geninitrd_baseline' "$SCRIPT" 'the live GenInitrd baseline must be revalidated before projection'
assert_contains '/boot/initrd-generic.img' "$SCRIPT" 'the named initrd must be part of the sensitive-state boundary'
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
DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
assert_success 'the accepted records should match the exact generator transaction' validate_accepted_records
assert_equal kernel-generic-6.18.42-x86_64-1.txz "$REVIEWED_PACKAGE_FILENAME" 'accepted evidence should provide the reviewed package filename'
assert_equal e9e7a1c5c71c945ee99595868aa8fee8a644b56601ece0c3e5696d643fe84878 "$REVIEWED_PACKAGE_SHA256" 'accepted evidence should provide the reviewed package SHA-256'

cp "$CHAIN_PREFLIGHT" "$TMP/chain-mismatch.json"
python3 - "$TMP/chain-mismatch.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['nested_boot_archive_sha256']='0'*64; open(p,'w').write(json.dumps(d))
PY
CHAIN_PREFLIGHT="$TMP/chain-mismatch.json"
assert_failure 'a restarted chain detached from the accepted boot evidence should fail closed' validate_accepted_records
CHAIN_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json"

cp "$BOOT_PREFLIGHT" "$TMP/boot-revoked-mode.json"
python3 - "$TMP/boot-revoked-mode.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['boot_mode']='direct-generic-no-initrd'; open(p,'w').write(json.dumps(d))
PY
BOOT_PREFLIGHT="$TMP/boot-revoked-mode.json"
assert_failure 'the revoked direct-no-initrd boot baseline should fail closed' validate_accepted_records
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-boot-preflight-20260805-accepted.json"

cp "$POLICY_PREFLIGHT" "$TMP/policy-transition.json"
python3 - "$TMP/policy-transition.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['policy']['transition_mode']='direct-to-generated-initrd'; open(p,'w').write(json.dumps(d))
PY
POLICY_PREFLIGHT="$TMP/policy-transition.json"
assert_failure 'a policy using the revoked direct transition should fail closed' validate_accepted_records
POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json"

cp "$PACKAGE_PREFLIGHT" "$TMP/package-invalid-digest.json"
python3 - "$TMP/package-invalid-digest.json" <<'PYFIXTURE'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d['package']['sha256'] = 'not-a-sha256'
open(p, 'w').write(json.dumps(d))
PYFIXTURE
PACKAGE_PREFLIGHT="$TMP/package-invalid-digest.json"
assert_failure 'an invalid package digest in accepted evidence should fail closed' validate_accepted_records
assert_equal '' "$REVIEWED_PACKAGE_SHA256" 'failed accepted-record validation should clear any previously loaded package identity'
PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json"

cp "$DKMS_PREFLIGHT" "$TMP/dkms-status.json"
python3 - "$TMP/dkms-status.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['dkms']['status_row_count']=1; d['dkms']['status_rows']=['nvidia/1, 6.18.40, installed']; open(p,'w').write(json.dumps(d))
PY
DKMS_PREFLIGHT="$TMP/dkms-status.json"
assert_failure 'a registered DKMS module should invalidate the accepted no-op hook boundary' validate_accepted_records
DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
cp "$DKMS_PREFLIGHT" "$TMP/dkms-action.json"
python3 - "$TMP/dkms-action.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['hooks'][0]['predicted_action']='dkms-install'; open(p,'w').write(json.dumps(d))
PY
DKMS_PREFLIGHT="$TMP/dkms-action.json"
assert_failure 'a hook that could install a module should fail the no-op boundary' validate_accepted_records
DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"
cp "$DKMS_PREFLIGHT" "$TMP/dkms-initrd.json"
python3 - "$TMP/dkms-initrd.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['current_versioned_initrd_sha256']='0'*64; open(p,'w').write(json.dumps(d))
PY
DKMS_PREFLIGHT="$TMP/dkms-initrd.json"
assert_failure 'a DKMS boundary detached from the corrected versioned initrd should fail closed' validate_accepted_records
DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json"

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
import hashlib,json,pathlib,sys
source,root,output=sys.argv[1:]; d=json.load(open(source)); r=pathlib.Path(root)
def sha(name): return hashlib.sha256((r/name).read_bytes()).hexdigest()
d['generic_kernel_sha256']=sha('boot/vmlinuz-6.18.40')
d['versioned_initrd_sha256']=sha('boot/initrd-6.18.40.img')
d['versioned_initrd_size']=(r/'boot/initrd-6.18.40.img').stat().st_size
d['active_grub_sha256']=sha('boot/grub/grub.cfg')
open(output,'w').write(json.dumps(d))
PY
OLD_PATH=$PATH
PATH="$TMP/bin:$PATH"
assert_success 'a coherent synthetic GenInitrd-managed baseline should validate before command projection' validate_live_geninitrd_baseline "$LIVE_RECORD" "$LIVE_ROOT" "$TMP/live.txt"
assert_contains 'transition_mode=versioned-to-versioned-initrd' "$TMP/live.txt" 'the live evidence should preserve the corrected transition mode'
cp "$LIVE_RECORD" "$TMP/live-wrong-initrd.json"
python3 - "$TMP/live-wrong-initrd.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['versioned_initrd_sha256']='0'*64; open(p,'w').write(json.dumps(d))
PY
assert_failure 'a changed live versioned initrd should fail closed before command projection' validate_live_geninitrd_baseline "$TMP/live-wrong-initrd.json" "$LIVE_ROOT" "$TMP/live-wrong.txt"
printf 'AUTOGENERATE_INITRD=true\nGENINITRD_NAMED_SYMLINK=false\nGENINITRD_INITRD_GZ_SYMLINK=false\n' > "$LIVE_ROOT/etc/default/geninitrd"
assert_failure 'a disabled named-initrd policy should fail closed before command projection' validate_live_geninitrd_baseline "$LIVE_RECORD" "$LIVE_ROOT" "$TMP/live-policy.txt"
PATH=$OLD_PATH

RUNNING_KERNEL=6.18.40
TARGET_KERNEL=6.18.42
EXPECTED_INITRD=/boot/initrd-6.18.42.img

cat > "$TMP/good.out" <<'EOF_GOOD'
# mkinitrd command generated for the running system:
mkinitrd -c -k 6.18.40 -f ext4 -r /dev/sda2 -m virtio:ext4 -u -o /boot/initrd.gz
EOF_GOOD
assert_success 'one inert generated mkinitrd command should parse safely' parse_generator_output "$TMP/good.out" "$TMP/good.json"
assert_equal 6.18.42 "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); v=d["projected_command_vector"]; print(v[v.index("-k")+1])' "$TMP/good.json")" 'the projected command should use the target kernel'
assert_equal /boot/initrd-6.18.42.img "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); v=d["projected_command_vector"]; print(v[v.index("-o")+1])' "$TMP/good.json")" 'the projected command should use the versioned target initrd'
assert_equal 2 "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["module_count"])' "$TMP/good.json")" 'the module list should be inventoried'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["generated_command_executed"]).lower())' "$TMP/good.json")" 'the analysis must record that the command was not executed'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_ready"]).lower())' "$TMP/good.json")" 'the projection must not become apply-ready'

cat > "$TMP/no-output.out" <<'EOF_NOOUTPUT'
mkinitrd -c -k 6.18.40 -f ext4 -r /dev/sda2 -m ext4
EOF_NOOUTPUT
assert_success 'a safe command without an output flag should receive the reviewed target output' parse_generator_output "$TMP/no-output.out" "$TMP/no-output.json"
assert_equal /boot/initrd-6.18.42.img "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); v=d["projected_command_vector"]; print(v[v.index("-o")+1])' "$TMP/no-output.json")" 'the missing output should be appended safely'

printf 'mkinitrd -c -k 6.18.39 -o /boot/initrd.gz\n' > "$TMP/wrong-kernel.out"
assert_failure 'a command for a different current kernel should fail closed' parse_generator_output "$TMP/wrong-kernel.out" "$TMP/wrong-kernel.json"
printf 'mkinitrd -k 6.18.40 -o /boot/initrd.gz\n' > "$TMP/no-create.out"
assert_failure 'a command without the clean-create flag should fail closed' parse_generator_output "$TMP/no-create.out" "$TMP/no-create.json"
printf 'mkinitrd -c -k 6.18.40 -o ../../tmp/initrd\n' > "$TMP/unsafe-output.out"
assert_failure 'an output outside boot should fail closed' parse_generator_output "$TMP/unsafe-output.out" "$TMP/unsafe-output.json"
printf 'mkinitrd -c -k 6.18.40 -m "ext4:bad/module" -o /boot/initrd.gz\n' > "$TMP/unsafe-module.out"
assert_failure 'an unsafe module name should fail closed' parse_generator_output "$TMP/unsafe-module.out" "$TMP/unsafe-module.json"
printf 'mkinitrd -c -k 6.18.40 -o /boot/initrd.gz; touch /tmp/pwn\n' > "$TMP/operator.out"
assert_failure 'a shell operator in generated output should fail closed' parse_generator_output "$TMP/operator.out" "$TMP/operator.json"
printf 'mkinitrd -c -k 6.18.40 -o /boot/initrd.gz\nmkinitrd -c -k 6.18.40 -o /boot/other.img\n' > "$TMP/multiple.out"
assert_failure 'multiple generated mkinitrd commands should fail closed' parse_generator_output "$TMP/multiple.out" "$TMP/multiple.json"
printf 'echo no-command\n' > "$TMP/missing.out"
assert_failure 'missing generated mkinitrd output should fail closed' parse_generator_output "$TMP/missing.out" "$TMP/missing.json"
printf 'mkinitrd -c -k 6.18.40 -o /boot/initrd.gz $(id)\n' > "$TMP/substitution.out"
assert_failure 'command substitution should fail closed' parse_generator_output "$TMP/substitution.out" "$TMP/substitution.json"
printf 'mkinitrd -c -k 6.18.40 -m ext4:virtio \\\n  -o /boot/initrd.gz\n' > "$TMP/continued.out"
assert_success 'a backslash-continued inert command should parse safely' parse_generator_output "$TMP/continued.out" "$TMP/continued.json"

GENERATOR_SCRIPT="$TMP/generator.sh"
SETUP_SCRIPT="$TMP/setup.sh"
cat > "$GENERATOR_SCRIPT" <<'EOF_GENERATOR'
#!/bin/bash
printf '%s\n' 'mkinitrd -c -k test -o /boot/initrd.gz'
EOF_GENERATOR
cat > "$SETUP_SCRIPT" <<'EOF_SETUP'
#!/bin/bash
# KERNEL_DOINST
# mkinitrd_command_generator.sh
printf '%s\n' 'initrd-${KERNEL_VERSION}.img' >/dev/null
EOF_SETUP
chmod 0755 "$GENERATOR_SCRIPT" "$SETUP_SCRIPT"
assert_success 'safe root-owned generator and setup fixtures should validate' validate_generator_scripts "$TMP/scripts.txt"
assert_contains 'generator_sha256=' "$TMP/scripts.txt" 'script digests should be captured'
chmod 0775 "$GENERATOR_SCRIPT"
assert_failure 'a group-writable generator should fail closed' validate_generator_scripts "$TMP/scripts-bad-mode.txt"
chmod 0755 "$GENERATOR_SCRIPT"
printf '#!/bin/bash\nif then\n' > "$GENERATOR_SCRIPT"
chmod 0755 "$GENERATOR_SCRIPT"
assert_failure 'a syntax-invalid generator should fail closed' validate_generator_scripts "$TMP/scripts-bad-syntax.txt"

(
    PASS_COUNT=12
    FAILURE_COUNT=0
    TARGET=slackware-current
    RUNNING_KERNEL=6.18.40
    TARGET_KERNEL=6.18.42
    CONFIRM_CANDIDATES_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
    EXPECTED_INITRD=/boot/initrd-6.18.42.img
    GENERATOR_SHA256=abc
    COMMAND_STATUS=projected-safe
    write_summary "$TMP/summary.txt"
)
assert_contains 'generator_run_mode=command-output-only' "$TMP/summary.txt" 'the summary should preserve the safe invocation mode'
assert_contains 'generated_command_executed=false' "$TMP/summary.txt" 'the summary should deny command execution'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should keep apply readiness false'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should keep apply authorization false'
assert_contains 'boot_mode=geninitrd-managed-versioned-initrd' "$TMP/summary.txt" 'the summary should preserve the corrected boot mode'
assert_contains 'transition_mode=versioned-to-versioned-initrd' "$TMP/summary.txt" 'the summary should preserve the corrected transition mode'
assert_contains 'current_versioned_initrd=/boot/initrd-6.18.40.img' "$TMP/summary.txt" 'the summary should preserve the current versioned initrd'
assert_contains 'passes=12' "$TMP/summary.txt" 'the summary should preserve the pass count'

printf 'Slackware-current GenInitrd command preflight harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
