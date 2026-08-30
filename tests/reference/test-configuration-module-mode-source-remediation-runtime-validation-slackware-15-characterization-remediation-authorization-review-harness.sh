#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review.sh"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design-policy.json"
design_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.md"
step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
step151_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review-policy.json"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review.md"
successor="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; printf '  expected: %s\n  actual:   %s\n' "$expected" "${actual:-<missing>}"; fi; }

for entry in \
    "$helper|step-153 authorization helper" \
    "$design|step-152 remediation design" \
    "$design_policy|step-152 remediation-design policy" \
    "$design_doc|step-152 reference document" \
    "$step150_harness|consumed step-150 execution harness" \
    "$step151_policy|step-151 failure-review policy" \
    "$binding_policy|step-132 target-binding policy" \
    "$accepted_closure|accepted Slackware 15.0 ELILO closure" \
    "$authorization|step-153 authorization record" \
    "$policy|step-153 authorization-review policy" \
    "$doc|step-153 reference document"; do
    check_regular "${entry%%|*}" "${entry#*|}"
done

check_hash "$design" 0c0d509daa71fefd527e734c305bef18209e0a4ef157f59477d83e94febd0c89 "step-152 remediation design"
check_hash "$design_policy" 910a5842cadebc282163f1527c3ef1c370ecbe9913d9ed29f23b18b448838b06 "step-152 remediation-design policy"
check_hash "$design_doc" 28e82f7367428de987bfec1bcb160bd40d50d5ad72e595f79239960c760a1432 "step-152 reference document"
check_hash "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
check_hash "$step151_policy" d46131b85ba1857412890e0738487dc1c0df8a6406646d8f93758e6fc41c9791 "step-151 failure-review policy"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

if [[ ! -e "$successor" && ! -L "$successor" ]]; then pass "successor execution harness is not implemented yet"; else fail "successor execution harness is not implemented yet"; fi
if bash -n "$helper"; then pass "step-153 authorization helper is shell-syntax valid"; else fail "step-153 authorization helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "step-153 helper exposes a non-mutating help boundary"; else fail "step-153 helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "step-153 helper rejects unknown options"; else pass "step-153 helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "step-153 authorization policy is valid JSON"; else fail "step-153 authorization policy is valid JSON"; fi

before_design=$(sha256sum -- "$design" | awk '{print $1}')
before_design_policy=$(sha256sum -- "$design_policy" | awk '{print $1}')
before_step150=$(sha256sum -- "$step150_harness" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_closure=$(sha256sum -- "$accepted_closure" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "step-153 characterization remediation authorization review completed successfully"; else fail "step-153 characterization remediation authorization review completed successfully"; fi
[[ $(sha256sum -- "$design" | awk '{print $1}') == "$before_design" ]] && pass "authorization review did not modify the step-152 design" || fail "authorization review did not modify the step-152 design"
[[ $(sha256sum -- "$design_policy" | awk '{print $1}') == "$before_design_policy" ]] && pass "authorization review did not modify the step-152 design policy" || fail "authorization review did not modify the step-152 design policy"
[[ $(sha256sum -- "$step150_harness" | awk '{print $1}') == "$before_step150" ]] && pass "authorization review preserved the consumed step-150 harness" || fail "authorization review preserved the consumed step-150 harness"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "authorization review preserved the historical target binding" || fail "authorization review preserved the historical target binding"
[[ $(sha256sum -- "$accepted_closure" | awk '{print $1}') == "$before_closure" ]] && pass "authorization review preserved the accepted ELILO closure" || fail "authorization review preserved the accepted ELILO closure"

check_output schema 1 "authorization output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review "authorization output records the expected scenario"
check_output design_id slackware-15-characterization-remediation "authorization remains bound to the step-152 design"
check_output authorization_scope slackware-15-successor-execution-harness-only "authorization is limited to the successor harness"
check_output authorized_change create-new-successor-harness "authorization permits only creation of a new harness"
check_output successor_harness_path tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh "authorization freezes the successor harness path"
check_output step152_design_sha256 0c0d509daa71fefd527e734c305bef18209e0a4ef157f59477d83e94febd0c89 "authorization is bound to the exact step-152 design"
check_output step150_harness_immutable true "consumed step-150 harness remains immutable"
check_output step149_authorization_reusable false "consumed step-149 authorization remains non-reusable"
check_output identity_gate_scope accepted-elilo-core-identity-only "authorization preserves the frozen core-identity gate"
check_output mkinitrd_pre_probe_gate false "mkinitrd presence is not authorized as an identity gate"
check_output grub_pre_probe_gate false "GRUB absence is not authorized as an identity gate"
check_output mkinitrd_observation_preserved true "mkinitrd state must remain evidence"
check_output grub_path_observation_preserved true "GRUB path state must remain evidence"
check_output runtime_capability_bits_predeclared false "runtime capability bits must come from the live probe"
check_output runtime_acceptance_scope auto-fail-closed-incomplete-layout-semantics "authorization preserves semantic fail-closed acceptance"
check_output execution_harness_change_applied false "authorization review itself applies no harness change"
check_output execution_harness_change_authorized true "authorization grants the narrow successor-harness implementation"
check_output source_change_authorized false "source modification remains unauthorized"
check_output configuration_template_change_authorized false "configuration-template modification remains unauthorized"
check_output contract_change_authorized false "contract modification remains unauthorized"
check_output target_binding_change_authorized false "historical target-binding modification remains unauthorized"
check_output machine_execution_authorized false "machine execution remains unauthorized"
check_output slackware_15_rerun_authorized false "Slackware 15.0 rerun remains unauthorized"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "authorization is independent of Slackware publication state"
check_output machine_action_required false "authorization requires no machine action"
check_output future_work_requires_fresh_boundary true "machine execution still requires a fresh future boundary"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation "authorization advances only to repository implementation"
check_output pause_safe true "repository-only authorization boundary remains pause-safe"

if grep -Fq 'consumable only while the exact step-152 design' "$doc" \
    && grep -Fq 'single-use for the step-154 repository implementation' "$doc"; then
    pass "authorization document binds single-use implementation to step-152 identity"
else
    fail "authorization document binds single-use implementation to step-152 identity"
fi
if grep -Fq 'must not be pre-probe identity requirements' "$doc" \
    && grep -Fq 'historical step-132 exact capability vector must not' "$doc"; then
    pass "authorization document preserves corrected characterization semantics"
else
    fail "authorization document preserves corrected characterization semantics"
fi
if grep -Fq 'does not authorize execution' "$doc" \
    && grep -Fq 'step-149 machine authorization remains consumed' "$doc"; then
    pass "authorization document preserves the machine-execution hold"
else
    fail "authorization document preserves the machine-execution hold"
fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "authorization helper contains no package, boot, or shutdown mutation command"
else
    pass "authorization helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)' "$helper"; then
    fail "authorization helper contains no network client command"
else
    pass "authorization helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
