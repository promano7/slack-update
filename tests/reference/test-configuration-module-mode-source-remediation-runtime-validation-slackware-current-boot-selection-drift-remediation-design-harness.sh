#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.sh"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.md"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
step141_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-policy.json"
step141_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-harness.sh"
step141_r1_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-revision-1-harness.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { if [[ -f "$1" && ! -L "$1" ]]; then pass "$2 is a regular file"; else fail "$2 is not a regular file"; fi; }
check_hash() { local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); if [[ "$actual" == "$2" ]]; then pass "$3 has the exact reviewed SHA-256"; else fail "$3 SHA-256 changed"; fi; }

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$step141_policy" "step-141 manual-review policy"
check_regular "$step141_harness" "corrected step-141 harness"
check_regular "$step141_r1_harness" "step-141 revision-1 harness"
check_regular "$helper" "step-142 design helper"
check_regular "$design" "step-142 design record"
check_regular "$policy" "step-142 design policy"
check_regular "$doc" "step-142 design document"

check_hash "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
check_hash "$step141_policy" b5bf2d88f0f6b0e0b8627f6f1bfa1f37bd8349359d6964be84d6ca3f6068c730 "step-141 manual-review policy"
check_hash "$step141_harness" 21c620597e01e673688f85ef4b116219ca9a611254f423135ffa8983c4d6c1d3 "corrected step-141 harness"
check_hash "$step141_r1_harness" f3f696ef0d62a993f6ec2bcfb34a807afa01751517360c14419a1087119cc04e "step-141 revision-1 harness"
check_hash "$helper" 1f65652d0175b10965e085b68f665203c54c9f981315f91a16dde422653d8293 "step-142 design helper"
check_hash "$design" 565b3d30749dd3d1b75c29d36a37425c60005d9fb109ae1248f5aa6398fd1825 "step-142 design record"
check_hash "$policy" cac091fd160d4ae47f36d8e1d9da21cca753e416139a7959c9ee6b5e2233a139 "step-142 design policy"
check_hash "$doc" 130d3db195d621362b21f05a9009b8bfd853906c3cc402406a6aef58a1d728ca "step-142 design document"

if bash -n "$helper"; then pass "step-142 design helper is shell-syntax valid"; else fail "step-142 design helper has invalid shell syntax"; fi
if bash -n "${BASH_SOURCE[0]}"; then pass "step-142 design harness is shell-syntax valid"; else fail "step-142 design harness has invalid shell syntax"; fi
if "$helper" --help >/dev/null; then pass "step-142 helper exposes a non-mutating help boundary"; else fail "step-142 helper help boundary failed"; fi
if "$helper" --invalid >/dev/null 2>&1; then fail "step-142 helper accepted an unknown option"; else pass "step-142 helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "step-142 design policy is valid JSON"; else fail "step-142 design policy is invalid JSON"; fi

output=$("$helper" 2>&1) || { fail "step-142 design helper did not complete successfully"; output=''; }
for pair in     $'failure_classification\tfrozen-boot-selection-mismatch'     $'recovery_strategy\tinteractive-grub-menu-selection'     $'persistent_boot_selection_mutation_required\tfalse'     $'reboot_required_by_design\ttrue'     $'post_reboot_characterization_required\ttrue'     $'runtime_probe_permitted_during_recovery\tfalse'     $'step139_authorization_reusable\tfalse'     $'machine_execution_authorized\tfalse'     $'reboot_authorized\tfalse'     $'boot_mutation_authorized\tfalse'     $'slackware_current_rerun_authorized\tfalse'     $'slackware_15_execution_released\tfalse'     $'repository_refresh_required\tfalse'     $'pause_safe\ttrue'; do
    if grep -Fxq -- "$pair" <<<"$output"; then pass "design output records ${pair%%$'\t'*}"; else fail "design output is missing ${pair%%$'\t'*}"; fi
done

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s '[:space:]' ' ')
if grep -Fq 'manually select exactly:' <<<"$normalized_doc" && grep -Fq 'Slackware-current slack-update direct generic (no initrd)' <<<"$normalized_doc"; then pass "design document requires manual selection of the exact frozen GRUB entry"; else fail "design document does not bind the exact manual GRUB selection"; fi
if grep -Fq 'linux /boot/vmlinuz-generic root=/dev/sda2 ro' <<<"$normalized_doc"; then pass "design document preserves the exact frozen linux command"; else fail "design document does not preserve the frozen linux command"; fi
if grep -Fq 'No persistent boot-selection mutation is part of the design' <<<"$normalized_doc"; then pass "design document forbids persistent boot-selection mutation"; else fail "design document does not forbid persistent boot-selection mutation"; fi
if grep -Fq 'must not invoke the remediated runtime probe' <<<"$normalized_doc"; then pass "design document separates boot recovery from runtime probing"; else fail "design document does not separate boot recovery from runtime probing"; fi
if grep -Fq 'consumed step-139 authorization must never be reused' <<<"$normalized_doc"; then pass "design document keeps the consumed authorization non-reusable"; else fail "design document permits ambiguity about the consumed authorization"; fi
if grep -Fq 'pause_safe=true' <<<"$normalized_doc"; then pass "design document records a publication-independent safe pause"; else fail "design document does not record the safe-pause boundary"; fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail "step-142 helper contains a machine, boot, or package mutation command"; else pass "step-142 helper contains no machine, boot, or package mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then fail "step-142 helper contains a network client command"; else pass "step-142 helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
