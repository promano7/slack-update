#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-boundary.sh"
machine="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery.sh"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution.tsv"
auth_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution.md"
changelog="$repo_root/CHANGELOG.md"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS: %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL: %s\n' "$*"; }
require_file() { [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is missing or unsafe"; }
require_hash() { local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ $actual == $2 ]] && pass "$3 SHA-256 is frozen" || fail "$3 SHA-256 mismatch: $actual"; }

for spec in \
    "$helper|step-144 boundary helper" \
    "$machine|step-144 machine harness" \
    "$policy|step-144 execution policy" \
    "$record|step-144 execution record" \
    "$auth_policy|step-143 authorization policy" \
    "$doc|step-144 reference document" \
    "$changelog|CHANGELOG"; do
    IFS='|' read -r path label <<< "$spec"
    require_file "$path" "$label"
done

if [[ $fail_count -ne 0 ]]; then
    printf 'Result: FAIL (%d passes, %d failures)\n' "$pass_count" "$fail_count"
    exit 1
fi

require_hash "$auth_policy" ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c "step-143 authorization policy"
require_hash "$policy" 4d056fcf9287ffbbdf83ec8b9fc5bb709b781989f59a719639aab77f58c93e6f "step-144 execution policy"
require_hash "$machine" 300335ef07df2f091e9b0d8f849f8c65fcece5a134880301d684c36bb10bf12f "step-144 machine harness"
require_hash "$helper" 66106b3e931de34024765e0cd93a6a52499937aa7f2def5a599c06abc38c6fa6 "step-144 boundary helper"

bash -n "$helper" && pass "the boundary helper has valid Bash syntax" || fail "the boundary helper has invalid Bash syntax"
bash -n "$machine" && pass "the machine harness has valid Bash syntax" || fail "the machine harness has invalid Bash syntax"
python3 -m json.tool "$policy" >/dev/null && pass "the execution policy is valid JSON" || fail "the execution policy is invalid JSON"

output=$(bash "$helper" 2>&1) || {
    printf '%s\n' "$output"
    fail "the boundary helper did not execute successfully"
    output=""
}
for expected in \
    $'step143_authorization_policy_sha256\tef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c' \
    $'execution_policy_sha256\t4d056fcf9287ffbbdf83ec8b9fc5bb709b781989f59a719639aab77f58c93e6f' \
    $'execution_harness_sha256\t300335ef07df2f091e9b0d8f849f8c65fcece5a134880301d684c36bb10bf12f' \
    $'pre_reboot_gate_required\ttrue' \
    $'machine_harness_performs_reboot\tfalse' \
    $'authorized_reboot_command\tsudo /sbin/reboot' \
    $'reboot_limit\t1' \
    $'interactive_boot_selection_limit\t1' \
    $'authorized_menuentry\tSlackware-current slack-update direct generic (no initrd)' \
    $'runtime_probe_authorized\tfalse' \
    $'repository_refresh_authorized\tfalse' \
    $'package_mutation_authorized\tfalse' \
    $'boot_configuration_mutation_authorized\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'pause_safe_while_recovery_armed\tfalse'; do
    grep -Fx -- "$expected" <<< "$output" >/dev/null \
        && pass "helper reports: $expected" \
        || fail "helper is missing: $expected"
done

python3 - "$policy" "$record" "$machine" <<'PY'
import csv
import json
import re
import sys

policy_path, record_path, machine_path = sys.argv[1:]
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
with open(record_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(machine_path, encoding="utf-8") as handle:
    machine = handle.read()

assert policy["step143_authorization_policy_sha256"] == "ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c"
assert policy["authorization_id"] == "slackware-current-interactive-frozen-boot-selection-recovery"
assert policy["target"]["hostname_fqdn"] == "vbox-slackcurrent.vbox-slackcurrent.org"
assert policy["target"]["accepted_kernel"] == "6.18.45"
assert policy["target"]["boot_image"] == "/boot/vmlinuz-generic"
assert policy["target"]["generic_kernel_target"] == "/boot/vmlinuz-6.18.45"
assert policy["target"]["mounted_root_device"] == "/dev/sda2"
assert policy["target"]["post_reboot_root_token"] == "/dev/sda2"
assert policy["target"]["dedicated_linux_command"] == "linux /boot/vmlinuz-generic root=/dev/sda2 ro"
assert policy["target"]["grub_cfg_sha256"] == "f9864ba5d8bbe78689b3b1e3ff337049e48026c1cd3f4289b3d4297af3a40593"
assert policy["target"]["custom_grub_script_sha256"] == "766bc1d8fabee076d521c641e19eeb03353733657031975a87131e72dd31bec1"
assert policy["pre_reboot_gate"]["reboot_performed_by_harness"] is False
assert policy["manual_reboot_boundary"]["reboot_limit"] == 1
assert policy["manual_reboot_boundary"]["interactive_boot_selection_limit"] == 1
assert policy["post_reboot_characterization"]["authorization_consumed_when_reboot_proven"] is True
assert policy["runtime_probe_permitted"] is False
assert policy["repository_refresh_permitted"] is False
assert policy["package_mutation_permitted"] is False
assert policy["boot_configuration_mutation_permitted"] is False
assert policy["slackware_15_execution_permitted"] is False
assert len(rows) == 1
assert rows[0]["reboot_limit"] == "1"
assert rows[0]["interactive_selection_limit"] == "1"
assert rows[0]["harness_reboots"] == "false"
assert rows[0]["runtime_probe_authorized"] == "false"

# The harness may print the authorized reboot command, but it must never execute
# reboot, shutdown, or GRUB mutation commands itself.
for line in machine.splitlines():
    stripped = line.strip()
    assert re.match(r"^(?:sudo\s+)?(?:/sbin/)?reboot(?:\s|$)", stripped) is None
    assert re.match(r"^(?:sudo\s+)?(?:/sbin/)?shutdown(?:\s|$)", stripped) is None
    assert re.match(r"^(?:sudo\s+)?(?:/usr/sbin/)?grub-(?:mkconfig|reboot|set-default|editenv)(?:\s|$)", stripped) is None

assert "probe_boot_module" not in machine
assert "slackpkg update" not in machine
assert "slackpkg install-new" not in machine
assert "slackpkg upgrade-all" not in machine
assert "--stage pre-reboot" in machine
assert "--stage post-reboot" in machine
assert "--confirm-single-authorized-reboot" in machine
assert "--confirm-interactive-menuentry" in machine
assert "AUTHORIZATION_CONSUMED_BY_REBOOT=true" in machine
PY
if [[ $? -eq 0 ]]; then
    pass "the frozen execution policy and machine harness preserve the single-use non-mutating recovery contract"
else
    fail "the execution policy or machine harness violates the reviewed recovery contract"
fi

for text in \
    'pre-reboot' \
    'post-reboot' \
    'Slackware-current slack-update direct generic (no initrd)' \
    'sudo /sbin/reboot' \
    'runtime probe remains unauthorized' \
    'Slackware 15.0 remains unauthorized'; do
    grep -F -- "$text" "$doc" >/dev/null \
        && pass "the reference document records: $text" \
        || fail "the reference document is missing: $text"
done

grep -F '<!-- step-144-slackware-current-boot-selection-recovery-execution:start -->' "$changelog" >/dev/null \
    && pass "CHANGELOG records the step-144 execution boundary" \
    || fail "CHANGELOG does not record the step-144 execution boundary"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail_count -eq 0 ]] && printf PASS || printf FAIL)" "$pass_count" "$fail_count"
[[ $fail_count -eq 0 ]]
