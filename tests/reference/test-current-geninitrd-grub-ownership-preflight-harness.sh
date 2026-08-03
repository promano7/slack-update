#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh
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
assert_contains 'temporary-atomic-policy-override' "$SCRIPT" 'the selected ownership strategy should be explicit'
assert_contains 'active-config-assignment-overwrites-environment-before-shell-defaulting' "$SCRIPT" 'environment-only suppression should be rejected explicitly'
assert_contains 'AUTO_UPDATE_GRUB=false' "$SCRIPT" 'the evidence-local policy should disable only automatic GRUB updates'
assert_contains 'active_policy_changed=false' "$SCRIPT" 'the summary must deny active policy mutation'
assert_contains 'package_transaction_executed=false' "$SCRIPT" 'the summary must deny package execution'
assert_contains 'mkinitrd_executed=false' "$SCRIPT" 'the summary must deny mkinitrd execution'
assert_contains 'geninitrd_executed=false' "$SCRIPT" 'the summary must deny geninitrd execution'
assert_contains 'update_grub_executed=false' "$SCRIPT" 'the summary must deny update-grub execution'
assert_contains 'grub_mkconfig_executed=false' "$SCRIPT" 'the summary must deny grub-mkconfig execution'
assert_contains 'commands_executed=0' "$SCRIPT" 'the summary must record zero executed commands'
assert_contains 'mutations_performed=0' "$SCRIPT" 'the summary must record zero mutations'
assert_contains 'APPLY_READY=false' "$SCRIPT" 'apply readiness must remain false'
assert_contains 'APPLY_AUTHORIZED=false' "$SCRIPT" 'apply authorization must remain false'
assert_not_contains 'eval ' "$SCRIPT" 'the preflight must not evaluate generated shell text'
if grep -E '^[[:space:]]*(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|geninitrd|update-grub|grub-mkconfig)[[:space:]]' "$SCRIPT" | grep -vq '='; then
    fail 'the preflight must not invoke package, initrd, or GRUB mutation commands'
else
    pass
fi
assert_contains 'sha256sum -c' "$SCRIPT" 'portable evidence verification should be printed'
assert_contains '/home/$owner/' "$SCRIPT" 'evidence should be copied directly to the user home directory'

is_safe_kernel_version 6.18.41 && pass || fail 'a normal kernel version should be safe'
is_safe_kernel_version '../6.18.41' && fail 'parent traversal should be rejected' || pass
is_safe_kernel_version '6.18.41 bad' && fail 'whitespace should be rejected' || pass
is_sha256 "$(printf 'a%.0s' {1..64})" && pass || fail 'a valid SHA-256 should be accepted'
is_sha256 abc && fail 'a short SHA-256 should be rejected' || pass

TARGET=slackware-current
TARGET_KERNEL=6.18.41
CONFIRM_CANDIDATES_SHA256=d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1
NORMAL_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-accepted.json"
BOOT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-accepted.json"
PACKAGE_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260803-accepted.json"
POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260803-accepted.json"
DKMS_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260803-accepted.json"
COMMAND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260803-accepted.json"
assert_success 'all accepted records should match the exact reviewed transaction' validate_accepted_records

cp "$COMMAND_PREFLIGHT" "$TMP/command-ready.json"
python3 - "$TMP/command-ready.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['apply_ready']=True; open(p,'w').write(json.dumps(d))
PY
COMMAND_PREFLIGHT="$TMP/command-ready.json"
assert_failure 'an apply-ready command record should fail the immutable preflight boundary' validate_accepted_records
COMMAND_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260803-accepted.json"

cp "$POLICY_PREFLIGHT" "$TMP/policy-grub.json"
python3 - "$TMP/policy-grub.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['policy']['auto_update_grub']=False; open(p,'w').write(json.dumps(d))
PY
POLICY_PREFLIGHT="$TMP/policy-grub.json"
assert_failure 'a policy record without automatic GRUB update should not match this ownership conflict' validate_accepted_records
POLICY_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260803-accepted.json"

ROOT="$TMP/root"
mkdir -p "$ROOT/etc/default" "$ROOT/usr/sbin" "$ROOT/var/lib/pkgtools/setup" "$TMP/out"
CONFIG="$ROOT/etc/default/geninitrd"
GENINITRD="$ROOT/usr/sbin/geninitrd"
SETUP="$ROOT/var/lib/pkgtools/setup/setup.01.mkinitrd"
cat > "$CONFIG" <<'EOF_CONFIG'
# Reviewed policy
KERNEL=/boot/vmlinuz-generic
GENERATOR=mkinitrd
AUTOGENERATE_INITRD=true
AUTO_UPDATE_GRUB=true
EOF_CONFIG
cat > "$GENINITRD" <<'EOF_GENINITRD'
#!/bin/bash
cd "$(dirname "$0")/../.."
if [ -r etc/default/geninitrd ]; then
  . etc/default/geninitrd
fi
chroot . /var/lib/pkgtools/setup/setup.01.mkinitrd
EOF_GENINITRD
cat > "$SETUP" <<'EOF_SETUP'
#!/bin/bash
if [ -r etc/default/geninitrd ]; then
  . etc/default/geninitrd
fi
AUTO_UPDATE_GRUB=${AUTO_UPDATE_GRUB:-true}
printf '%s\n' 'initrd-${KERNEL_VERSION}.img' >/dev/null
if [ "$AUTO_UPDATE_GRUB" = "true" ]; then
  chroot . /usr/sbin/update-grub
fi
EOF_SETUP
chmod 0644 "$CONFIG"
chmod 0755 "$GENINITRD" "$SETUP"
assert_success 'a reviewed config and control flow should produce a safe ownership plan' analyze_grub_ownership "$CONFIG" "$GENINITRD" "$SETUP" "$TMP/out/staged" "$TMP/out/analysis.json" 6.18.41
assert_contains 'AUTO_UPDATE_GRUB=false' "$TMP/out/staged" 'the staged copy should disable automatic GRUB update'
assert_not_contains 'AUTO_UPDATE_GRUB=true' "$TMP/out/staged" 'the staged copy should not retain the active true assignment'
assert_contains 'AUTO_UPDATE_GRUB=true' "$CONFIG" 'the active fixture must remain unchanged'
assert_equal temporary-atomic-policy-override "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["strategy"])' "$TMP/out/analysis.json")" 'the strategy should use a temporary atomic policy override'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["environment_override_safe"]).lower())' "$TMP/out/analysis.json")" 'environment-only override should be unsafe'
assert_equal 12 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["transaction_steps"]))' "$TMP/out/analysis.json")" 'the plan should contain twelve ordered steps'
assert_equal 5 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["recovery_boundaries"]))' "$TMP/out/analysis.json")" 'the plan should contain five recovery boundaries'
assert_equal 0 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["commands_executed"]))' "$TMP/out/analysis.json")" 'the plan should record no executed commands'
assert_equal 0 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["mutations_performed"]))' "$TMP/out/analysis.json")" 'the plan should record no mutations'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_ready"]).lower())' "$TMP/out/analysis.json")" 'the plan must remain not ready'
assert_equal false "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_authorized"]).lower())' "$TMP/out/analysis.json")" 'the plan must remain unauthorized'
assert_equal true "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["requires_final_candidate_revalidation"]).lower())' "$TMP/out/analysis.json")" 'final candidate revalidation must remain required'

cp "$CONFIG" "$TMP/duplicate.conf"
printf '%s\n' 'AUTO_UPDATE_GRUB=true' >> "$TMP/duplicate.conf"
assert_failure 'duplicate active AUTO_UPDATE_GRUB assignments should fail closed' analyze_grub_ownership "$TMP/duplicate.conf" "$GENINITRD" "$SETUP" "$TMP/out/dup-staged" "$TMP/out/dup.json" 6.18.41
cp "$CONFIG" "$TMP/false.conf"
sed -i 's/AUTO_UPDATE_GRUB=true/AUTO_UPDATE_GRUB=false/' "$TMP/false.conf"
assert_failure 'an already-disabled policy should not match the observed ownership conflict' analyze_grub_ownership "$TMP/false.conf" "$GENINITRD" "$SETUP" "$TMP/out/false-staged" "$TMP/out/false.json" 6.18.41
cp "$CONFIG" "$TMP/unsafe.conf"
printf '%s\n' 'POST_INSTALL_SCRIPT=$(id)' >> "$TMP/unsafe.conf"
assert_failure 'command substitution in active policy should fail closed' analyze_grub_ownership "$TMP/unsafe.conf" "$GENINITRD" "$SETUP" "$TMP/out/unsafe-staged" "$TMP/out/unsafe.json" 6.18.41
ln -s "$CONFIG" "$TMP/link.conf"
assert_failure 'a symlinked policy should fail closed' analyze_grub_ownership "$TMP/link.conf" "$GENINITRD" "$SETUP" "$TMP/out/link-staged" "$TMP/out/link.json" 6.18.41
chmod 0664 "$CONFIG"
assert_failure 'a group-writable active policy should fail closed' analyze_grub_ownership "$CONFIG" "$GENINITRD" "$SETUP" "$TMP/out/mode-staged" "$TMP/out/mode.json" 6.18.41
chmod 0644 "$CONFIG"
cp "$SETUP" "$TMP/setup-wrong-order"
cat > "$TMP/setup-wrong-order" <<'EOF_WRONG'
#!/bin/bash
AUTO_UPDATE_GRUB=${AUTO_UPDATE_GRUB:-true}
. etc/default/geninitrd
printf '%s\n' 'initrd-${KERNEL_VERSION}.img' >/dev/null
if [ "$AUTO_UPDATE_GRUB" = "true" ]; then /usr/sbin/update-grub; fi
EOF_WRONG
chmod 0755 "$TMP/setup-wrong-order"
assert_failure 'policy sourcing after shell defaulting should fail closed' analyze_grub_ownership "$CONFIG" "$GENINITRD" "$TMP/setup-wrong-order" "$TMP/out/order-staged" "$TMP/out/order.json" 6.18.41
cp "$SETUP" "$TMP/setup-no-guard"
sed -i '/if \[ "\$AUTO_UPDATE_GRUB" = "true" \]/d' "$TMP/setup-no-guard"
chmod 0755 "$TMP/setup-no-guard"
assert_failure 'an unguarded update-grub call should fail closed' analyze_grub_ownership "$CONFIG" "$GENINITRD" "$TMP/setup-no-guard" "$TMP/out/guard-staged" "$TMP/out/guard.json" 6.18.41
printf '#!/bin/bash\nif then\n' > "$TMP/bad-geninitrd"
chmod 0755 "$TMP/bad-geninitrd"
assert_failure 'a syntax-invalid geninitrd script should fail closed' analyze_grub_ownership "$CONFIG" "$TMP/bad-geninitrd" "$SETUP" "$TMP/out/syntax-staged" "$TMP/out/syntax.json" 6.18.41

(
    PASS_COUNT=11
    FAILURE_COUNT=0
    TARGET=slackware-current
    RUNNING_KERNEL=6.18.40
    TARGET_KERNEL=6.18.41
    CONFIRM_CANDIDATES_SHA256=d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1
    STRATEGY=temporary-atomic-policy-override
    ENVIRONMENT_OVERRIDE_SAFE=false
    write_summary "$TMP/summary.txt"
)
assert_contains 'active_policy_changed=false' "$TMP/summary.txt" 'the summary should deny policy mutation'
assert_contains 'commands_executed=0' "$TMP/summary.txt" 'the summary should record zero executed commands'
assert_contains 'mutations_performed=0' "$TMP/summary.txt" 'the summary should record zero mutations'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should keep apply readiness false'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should keep apply authorization false'
assert_contains 'passes=11' "$TMP/summary.txt" 'the summary should preserve the pass count'

printf 'Slackware-current GenInitrd GRUB ownership preflight harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
