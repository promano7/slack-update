#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.sh"
step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
step151_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.tsv"
step151_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review-policy.json"
step151_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.md"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; printf '  expected: %s\n  actual:   %s\n' "$expected" "${actual:-<missing>}"; fi; }

for entry in \
    "$helper|step-152 design helper" \
    "$step150_harness|consumed step-150 execution harness" \
    "$step151_review|step-151 failure-review record" \
    "$step151_policy|step-151 failure-review policy" \
    "$step151_doc|step-151 reference document" \
    "$binding_policy|step-132 target-binding policy" \
    "$accepted_closure|accepted Slackware 15.0 ELILO closure" \
    "$design|step-152 remediation design" \
    "$policy|step-152 remediation-design policy" \
    "$doc|step-152 reference document"; do
    check_regular "${entry%%|*}" "${entry#*|}"
done

check_hash "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
check_hash "$step151_review" 5b3a30a73ba3596d2b6db4acef4b1198d541674824211d1c61d0f42c62e0b7d1 "step-151 failure-review record"
check_hash "$step151_policy" d46131b85ba1857412890e0738487dc1c0df8a6406646d8f93758e6fc41c9791 "step-151 failure-review policy"
check_hash "$step151_doc" 3f64d924825a2a5f52e5a62a79f8053f0d7ecc1ef61db436df52887e32d9eb86 "step-151 reference document"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

before_step150=$(sha256sum -- "$step150_harness" | awk '{print $1}')
before_step151_policy=$(sha256sum -- "$step151_policy" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_closure=$(sha256sum -- "$accepted_closure" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "step-152 characterization remediation design completed successfully"; else fail "step-152 characterization remediation design completed successfully"; fi
[[ $(sha256sum -- "$step150_harness" | awk '{print $1}') == "$before_step150" ]] && pass "design review did not modify the consumed step-150 harness" || fail "design review did not modify the consumed step-150 harness"
[[ $(sha256sum -- "$step151_policy" | awk '{print $1}') == "$before_step151_policy" ]] && pass "design review did not modify the accepted step-151 policy" || fail "design review did not modify the accepted step-151 policy"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "design review did not modify the historical target binding" || fail "design review did not modify the historical target binding"
[[ $(sha256sum -- "$accepted_closure" | awk '{print $1}') == "$before_closure" ]] && pass "design review did not modify the accepted ELILO closure" || fail "design review did not modify the accepted ELILO closure"

check_output schema 1 "design output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design "design output records the expected scenario"
check_output failure_classification unfrozen-target-characterization-assumption-mismatch "design remains bound to the accepted failure classification"
check_output identity_gate_scope accepted-elilo-core-identity-only "future pre-probe gate is limited to accepted ELILO core identity"
check_output mkinitrd_future_pre_probe_gate false "mkinitrd presence is removed from the future identity gate"
check_output grub_path_future_pre_probe_gate false "GRUB directory absence is removed from the future identity gate"
check_output mkinitrd_observation_preserved true "mkinitrd state remains evidence"
check_output grub_path_observation_preserved true "GRUB path state remains evidence"
check_output runtime_capability_bits_predeclared false "runtime capability bits are not predeclared from historical characterization"
check_output runtime_acceptance_scope auto-fail-closed-incomplete-layout-semantics "future acceptance tests semantic fail-closed behavior"
check_output step150_harness_immutable true "consumed step-150 harness remains immutable"
check_output step149_authorization_reusable false "consumed step-149 authorization remains non-reusable"
check_output historical_target_binding_mutation false "historical target binding remains immutable"
check_output source_change_authorized false "design authorizes no source change"
check_output configuration_template_change_authorized false "design authorizes no configuration-template change"
check_output contract_change_authorized false "design authorizes no contract change"
check_output execution_harness_change_authorized false "design does not yet authorize harness implementation"
check_output machine_execution_authorized false "design authorizes no machine execution"
check_output slackware_15_rerun_authorized false "design authorizes no Slackware 15.0 rerun"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "design is independent of Slackware publication state"
check_output machine_action_required false "design requires no machine action"
check_output future_work_requires_fresh_boundary true "future work still requires a fresh authorization boundary"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review "design advances only to separate authorization review"
check_output pause_safe true "repository-only design boundary remains pause-safe"

if grep -Fq 'Two-layer characterization boundary' "$doc" \
    && grep -Fq '/etc/mkinitrd.conf' "$doc" \
    && grep -Fq '/boot/grub' "$doc" \
    && grep -Fq 'runtime capability observations' "$doc"; then
    pass "design document separates frozen identity from runtime capability observations"
else
    fail "design document separates frozen identity from runtime capability observations"
fi
if grep -Fq 'BOOT_INITRD_AVAILABLE=1' "$doc" \
    && grep -Fq 'BOOT_GRUB_AVAILABLE=0' "$doc" \
    && grep -Fq 'rather than forced to the historical' "$doc"; then
    pass "design document rejects reuse of the historical exact capability vector"
else
    fail "design document rejects reuse of the historical exact capability vector"
fi
if grep -Fq 'does not rewrite the step-132 target-binding policy' "$doc" \
    && grep -Fq 'step-149 single-use authorization remains consumed' "$doc"; then
    pass "design document preserves historical records and consumed authorization"
else
    fail "design document preserves historical records and consumed authorization"
fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "design helper contains no package, boot, or shutdown mutation command"
else
    pass "design helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "design helper contains no network client command"
else
    pass "design helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
