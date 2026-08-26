#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
DESIGN="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.tsv"
DESIGN_POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design-policy.json"
DESIGN_HELPER="$REPO_ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.sh"
DESIGN_HARNESS="$REPO_ROOT/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design-harness.sh"
DESIGN_DOC="$REPO_ROOT/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.md"
AUTH="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review.tsv"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review-policy.json"
HELPER="$REPO_ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review.sh"
DOC="$REPO_ROOT/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review.md"

passes=0
failures=0
pass() { passes=$((passes + 1)); printf 'PASS: %s\n' "$*"; }
fail() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$*"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
check_file() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local path=$1 expected=$2 label=$3; if [[ -f "$path" && $(sha "$path") == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

check_file "$DESIGN" "step-142 design record"
check_file "$DESIGN_POLICY" "step-142 design policy"
check_file "$DESIGN_HELPER" "step-142 design helper"
check_file "$DESIGN_HARNESS" "step-142 design harness"
check_file "$DESIGN_DOC" "step-142 design document"
check_file "$AUTH" "step-143 authorization record"
check_file "$POLICY" "step-143 authorization policy"
check_file "$HELPER" "step-143 authorization helper"
check_file "$DOC" "step-143 authorization document"

check_hash "$DESIGN" 565b3d30749dd3d1b75c29d36a37425c60005d9fb109ae1248f5aa6398fd1825 "step-142 design record"
check_hash "$DESIGN_POLICY" cac091fd160d4ae47f36d8e1d9da21cca753e416139a7959c9ee6b5e2233a139 "step-142 design policy"
check_hash "$DESIGN_HELPER" 1f65652d0175b10965e085b68f665203c54c9f981315f91a16dde422653d8293 "step-142 design helper"
check_hash "$DESIGN_HARNESS" 675bf39c9865a7d6575b5793354e73bededd5c1686f1664d458a750318a33b4e "step-142 design harness"
check_hash "$DESIGN_DOC" 130d3db195d621362b21f05a9009b8bfd853906c3cc402406a6aef58a1d728ca "step-142 design document"
check_hash "$AUTH" 0bf88636c5ecea2a7c7fb9375c3112849a654f9f6b4ed0236c778642f76ce3aa "step-143 authorization record"
check_hash "$POLICY" ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c "step-143 authorization policy"
check_hash "$HELPER" f4ac7d283d1cbf0b9e3f46c832fa46b3ff9744c33db03ffe77c81dabaf1d4d5d "step-143 authorization helper"
check_hash "$DOC" 8642b75ae1b7874c32cdae7894f00f088033fb6d3ca5799c22189fd9df553ecc "step-143 authorization document"

if bash -n "$HELPER"; then pass "step-143 authorization helper is shell-syntax valid"; else fail "step-143 authorization helper has invalid shell syntax"; fi
if bash -n "${BASH_SOURCE[0]}"; then pass "step-143 authorization harness is shell-syntax valid"; else fail "step-143 authorization harness has invalid shell syntax"; fi
if "$HELPER" --help >/dev/null; then pass "step-143 helper exposes a non-mutating help boundary"; else fail "step-143 helper help boundary failed"; fi
if "$HELPER" --invalid >/dev/null 2>&1; then fail "step-143 helper accepted an unknown option"; else pass "step-143 helper rejects unknown options"; fi
if python3 -m json.tool "$POLICY" >/dev/null; then pass "step-143 authorization policy is valid JSON"; else fail "step-143 authorization policy is invalid JSON"; fi

before_design=$(sha "$DESIGN")
before_policy=$(sha "$DESIGN_POLICY")
before_helper=$(sha "$DESIGN_HELPER")
before_harness=$(sha "$DESIGN_HARNESS")
before_doc=$(sha "$DESIGN_DOC")
output=$($HELPER 2>&1) || { fail "step-143 authorization review did not complete successfully"; output=''; }
[[ $(sha "$DESIGN") == "$before_design" ]] && pass "authorization review preserves the step-142 design record" || fail "authorization review modified the step-142 design record"
[[ $(sha "$DESIGN_POLICY") == "$before_policy" ]] && pass "authorization review preserves the step-142 design policy" || fail "authorization review modified the step-142 design policy"
[[ $(sha "$DESIGN_HELPER") == "$before_helper" ]] && pass "authorization review preserves the step-142 design helper" || fail "authorization review modified the step-142 design helper"
[[ $(sha "$DESIGN_HARNESS") == "$before_harness" ]] && pass "authorization review preserves the step-142 design harness" || fail "authorization review modified the step-142 design harness"
[[ $(sha "$DESIGN_DOC") == "$before_doc" ]] && pass "authorization review preserves the step-142 design document" || fail "authorization review modified the step-142 design document"

for pair in \
    $'failure_classification\tfrozen-boot-selection-mismatch' \
    $'authorization_consumable\ttrue' \
    $'machine_sequence_limit\t1' \
    $'reboot_limit\t1' \
    $'interactive_boot_selection_authorized\ttrue' \
    $'authorized_menuentry\tSlackware-current slack-update direct generic (no initrd)' \
    $'persistent_boot_selection_mutation_authorized\tfalse' \
    $'boot_configuration_mutation_authorized\tfalse' \
    $'runtime_probe_authorized\tfalse' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'repository_refresh_authorized\tfalse' \
    $'pre_reboot_gate_required\ttrue' \
    $'post_reboot_characterization_required\ttrue' \
    $'step139_authorization_reusable\tfalse' \
    $'machine_action_required\tfalse' \
    $'future_machine_action_authorized\ttrue' \
    $'slackware_repository_state_dependency\tfalse' \
    $'pause_safe\ttrue'; do
    key=${pair%%$'\t'*}
    if grep -Fxq -- "$pair" <<<"$output"; then pass "authorization output records $key"; else fail "authorization output is missing $key"; fi
done

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if grep -Fq 'manually select exactly:' <<<"$normalized_doc" && grep -Fq 'Slackware-current slack-update direct generic (no initrd)' <<<"$normalized_doc"; then pass "authorization document binds the one permitted interactive menu selection"; else fail "authorization document does not bind the interactive selection"; fi
if grep -Fq 'linux /boot/vmlinuz-generic root=/dev/sda2 ro' <<<"$normalized_doc"; then pass "authorization document preserves the exact frozen linux command"; else fail "authorization document does not preserve the frozen linux command"; fi
if grep -Fq 'only boot-selection action authorized' <<<"$normalized_doc" && grep -Fq 'not authorization to mutate boot configuration' <<<"$normalized_doc"; then pass "authorization document distinguishes interactive selection from boot mutation"; else fail "authorization document blurs interactive selection and boot mutation"; fi
if grep -Fq 'Any mismatch must stop before reboot' <<<"$normalized_doc"; then pass "authorization document requires a fail-closed pre-reboot gate"; else fail "authorization document lacks a fail-closed pre-reboot gate"; fi
if grep -Fq 'runtime remediation probe is explicitly forbidden' <<<"$normalized_doc"; then pass "authorization document withholds the runtime probe"; else fail "authorization document does not withhold the runtime probe"; fi
if grep -Fq 'consumed step-139 authorization remains non-reusable' <<<"$normalized_doc"; then pass "authorization document keeps the consumed rerun authorization non-reusable"; else fail "authorization document permits ambiguity about step 139"; fi
if grep -Fq 'Slackware 15.0 remains held and unauthorized' <<<"$normalized_doc"; then pass "authorization document keeps Slackware 15.0 held"; else fail "authorization document does not keep Slackware 15.0 held"; fi
if grep -Fq 'pause_safe=true' <<<"$normalized_doc"; then pass "authorization document records the publication-independent safe pause"; else fail "authorization document lacks the safe-pause boundary"; fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$HELPER"; then fail "step-143 helper contains a machine, boot, package, or shutdown mutation command"; else pass "step-143 helper contains no machine, boot, package, or shutdown mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$HELPER"; then fail "step-143 helper contains a network client command"; else pass "step-143 helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
