#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.sh"
successor="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.md"
step153_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
step153_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization.tsv"
step153_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review.md"
step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
future_execution_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$*"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; printf '  expected: %s\n  actual:   %s\n' "$expected" "${actual:-<missing>}"; fi; }

for entry in \
    "$helper|step-154 implementation helper" \
    "$successor|step-154 successor execution harness" \
    "$record|step-154 implementation record" \
    "$policy|step-154 implementation policy" \
    "$doc|step-154 reference document" \
    "$step153_policy|step-153 authorization policy" \
    "$step153_record|step-153 authorization record" \
    "$step153_doc|step-153 reference document" \
    "$step150_harness|consumed step-150 execution harness" \
    "$binding_policy|step-132 target-binding policy" \
    "$accepted_closure|accepted Slackware 15.0 ELILO closure"; do
    check_regular "${entry%%|*}" "${entry#*|}"
done

check_hash "$step153_policy" a4192c8562b59110e60c99bd64be17b1459e1c2c210117a60e97b0609be20a4c "step-153 authorization policy"
check_hash "$step153_record" b91241cb0ea5432d0f88a8824d2a6261b189b6440a6d4f176dca806f68d58ba8 "step-153 authorization record"
check_hash "$step153_doc" 9b4029a3e49b7d1f37fca086c2879edcee88e114174891c8ec14db515bfc7c38 "step-153 reference document"
check_hash "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"
check_hash "$successor" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "step-154 successor execution harness"
check_hash "$record" caf14634fc170cfd638b6a678d13943748c13ee75bcb501f2b09ffcca0a218d9 "step-154 implementation record"
check_hash "$policy" 38e73937af376b9bf0a5f9378144b4ecb3c963e475707214e05e51df3495a9d7 "step-154 implementation policy"
check_hash "$doc" db36c2fbd3750081eb1b7582ed24c22e1929f28c1f46a6244de3bf52241f3e34 "step-154 reference document"

if [[ ! -e "$future_execution_policy" && ! -L "$future_execution_policy" ]]; then pass "future machine-execution authorization policy is absent"; else fail "future machine-execution authorization policy is absent"; fi
if bash -n "$helper"; then pass "step-154 implementation helper is shell-syntax valid"; else fail "step-154 implementation helper is shell-syntax valid"; fi
if bash -n "$successor"; then pass "successor execution harness is shell-syntax valid"; else fail "successor execution harness is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "step-154 helper exposes a non-mutating help boundary"; else fail "step-154 helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "step-154 helper rejects unknown options"; else pass "step-154 helper rejects unknown options"; fi
if "$successor" --help >/dev/null; then pass "successor harness exposes help without machine authorization"; else fail "successor harness exposes help without machine authorization"; fi
if "$successor" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-execution-authorization-policy-sha256 0000000000000000000000000000000000000000000000000000000000000000 >/dev/null 2>&1; then
    fail "successor harness refuses execution while future authorization is absent"
else
    rc=$?
    [[ $rc -eq 3 ]] && pass "successor harness refuses execution while future authorization is absent" || fail "successor harness refuses execution while future authorization is absent"
fi
if python3 -m json.tool "$policy" >/dev/null; then pass "step-154 implementation policy is valid JSON"; else fail "step-154 implementation policy is valid JSON"; fi

core_gate=$(python3 - "$successor" <<'PY'
import pathlib, sys
text=pathlib.Path(sys.argv[1]).read_text()
print(text.split('# BEGIN CORE IDENTITY GATE',1)[1].split('# END CORE IDENTITY GATE',1)[0])
PY
)
if [[ "$core_gate" == *'EXPECTED_HOSTNAME_FQDN'* && "$core_gate" == *'Slackware 15.0'* && "$core_gate" == *'/sys/firmware/efi'* && "$core_gate" == *'EXPECTED_KERNEL'* && "$core_gate" == *'EXPECTED_BOOT_IMAGE_SUFFIX'* && "$core_gate" == *'EXPECTED_ELILO_SHA256'* ]]; then
    pass "successor core-identity gate contains every frozen ELILO identity predicate"
else
    fail "successor core-identity gate contains every frozen ELILO identity predicate"
fi
if [[ "$core_gate" != *'/etc/mkinitrd.conf'* ]]; then pass "mkinitrd configuration is absent from the core-identity gate"; else fail "mkinitrd configuration is absent from the core-identity gate"; fi
if [[ "$core_gate" != *'/boot/grub'* ]]; then pass "GRUB path state is absent from the core-identity gate"; else fail "GRUB path state is absent from the core-identity gate"; fi
if grep -Fq "printf 'mkinitrd_config_sha256=%s" "$successor"; then pass "mkinitrd state remains captured as runtime evidence"; else fail "mkinitrd state remains captured as runtime evidence"; fi
if grep -Fq "printf 'grub_directory_kind='" "$successor"; then pass "GRUB path state remains captured as runtime evidence"; else fail "GRUB path state remains captured as runtime evidence"; fi
if grep -Fq "printf 'boot_initrd_available=%s" "$successor" && grep -Fq "printf 'boot_grub_available=%s" "$successor"; then pass "live capability bits are captured from the runtime probe"; else fail "live capability bits are captured from the runtime probe"; fi

runtime_acceptance=$(python3 - "$successor" <<'PY'
import pathlib, sys
text=pathlib.Path(sys.argv[1]).read_text()
print(text.split('# BEGIN RUNTIME ACCEPTANCE',1)[1].split('# END RUNTIME ACCEPTANCE',1)[0])
PY
)
if [[ "$runtime_acceptance" != *'BOOT_INITRD_AVAILABLE'* && "$runtime_acceptance" != *'BOOT_GRUB_AVAILABLE'* ]]; then pass "runtime acceptance does not require the historical exact capability vector"; else fail "runtime acceptance does not require the historical exact capability vector"; fi
for token in 'BOOT_MODE == auto' 'BOOT_MODULE_STATE == unavailable' 'BOOT_MODULE_RUN -eq 0' 'BOOT_PREPARATION_LAYOUT == unknown' 'BOOT_DIRECT_GENERIC_AVAILABLE -eq 0' 'no supported initrd or GRUB preparation path was detected'; do
    if [[ "$runtime_acceptance" == *"$token"* ]]; then pass "runtime acceptance preserves semantic predicate: $token"; else fail "runtime acceptance preserves semantic predicate: $token"; fi
done
if grep -Fq 'capture_packages "$EVIDENCE_DIR/packages.before.txt"' "$successor" && grep -Fq 'capture_packages "$EVIDENCE_DIR/packages.after.txt"' "$successor"; then pass "successor preserves pre/post package evidence"; else fail "successor preserves pre/post package evidence"; fi
if grep -Fq 'slackpkg-metadata.before.txt' "$successor" && grep -Fq 'slackpkg-metadata.after.txt' "$successor"; then pass "successor preserves pre/post Slackpkg metadata evidence"; else fail "successor preserves pre/post Slackpkg metadata evidence"; fi
if grep -Fq 'boot-state.before.txt' "$successor" && grep -Fq 'boot-state.after.txt' "$successor"; then pass "successor preserves pre/post boot-state evidence"; else fail "successor preserves pre/post boot-state evidence"; fi
if grep -Fq 'source.before.sha256' "$successor" && grep -Fq 'source.after.sha256' "$successor" && grep -Fq 'template.before.sha256' "$successor" && grep -Fq 'template.after.sha256' "$successor"; then pass "successor preserves pre/post source and template identity evidence"; else fail "successor preserves pre/post source and template identity evidence"; fi

before_step153=$(sha256sum -- "$step153_policy" | awk '{print $1}')
before_step150=$(sha256sum -- "$step150_harness" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_closure=$(sha256sum -- "$accepted_closure" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "step-154 characterization remediation implementation validation completed successfully"; else fail "step-154 characterization remediation implementation validation completed successfully"; fi
[[ $(sha256sum -- "$step153_policy" | awk '{print $1}') == "$before_step153" ]] && pass "implementation helper preserves the consumed step-153 authorization" || fail "implementation helper preserves the consumed step-153 authorization"
[[ $(sha256sum -- "$step150_harness" | awk '{print $1}') == "$before_step150" ]] && pass "implementation helper preserves the consumed step-150 harness" || fail "implementation helper preserves the consumed step-150 harness"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "implementation helper preserves the historical target binding" || fail "implementation helper preserves the historical target binding"
[[ $(sha256sum -- "$accepted_closure" | awk '{print $1}') == "$before_closure" ]] && pass "implementation helper preserves the accepted ELILO closure" || fail "implementation helper preserves the accepted ELILO closure"

check_output schema 1 "implementation output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation "implementation output records the expected scenario"
check_output implementation_id slackware-15-characterization-remediation "implementation remains bound to the accepted remediation design"
check_output authorized_change create-new-successor-harness "implementation consumes only the authorized harness creation"
check_output successor_harness_path tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh "implementation uses the frozen successor path"
check_output successor_harness_sha256 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "implementation freezes the successor harness SHA-256"
check_output step153_authorization_consumed true "step-153 repository authorization is consumed"
check_output step150_harness_immutable true "consumed step-150 harness remains immutable"
check_output identity_gate_scope accepted-elilo-core-identity-only "implementation limits pre-probe gating to core identity"
check_output mkinitrd_pre_probe_gate false "mkinitrd presence is not a pre-probe identity gate"
check_output grub_pre_probe_gate false "GRUB absence is not a pre-probe identity gate"
check_output mkinitrd_observation_preserved true "mkinitrd observation remains evidence"
check_output grub_path_observation_preserved true "GRUB path observation remains evidence"
check_output runtime_capability_bits_predeclared false "runtime capability bits are not predeclared"
check_output runtime_acceptance_scope auto-fail-closed-incomplete-layout-semantics "implementation preserves semantic fail-closed acceptance"
check_output future_execution_policy_required true "successor execution requires a separate future authorization policy"
check_output future_execution_policy_exists false "step 154 creates no machine-execution authorization policy"
check_output execution_harness_change_applied true "authorized successor harness creation is applied"
check_output further_execution_harness_change_authorized false "no further execution-harness modification remains authorized"
check_output source_change_applied false "source remains unchanged"
check_output configuration_template_change_applied false "configuration template remains unchanged"
check_output contract_change_applied false "optional-module contract remains unchanged"
check_output target_binding_change_applied false "historical target binding remains unchanged"
check_output machine_execution_authorized false "machine execution remains unauthorized"
check_output slackware_15_rerun_authorized false "Slackware 15.0 rerun remains unauthorized"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "implementation is independent of Slackware publication state"
check_output machine_action_required false "implementation requires no machine action"
check_output future_work_requires_fresh_boundary true "future machine work requires a fresh boundary"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review "implementation advances only to repository review"
check_output pause_safe true "repository-only implementation remains pause-safe"

if grep -Fq 'does **not** create the future machine-execution' "$doc" && grep -Fq 'refuses execution unless the future' "$doc"; then pass "implementation document explains the execution hold"; else fail "implementation document explains the execution hold"; fi
if grep -Fq 'no longer identity gates' "$doc" && grep -Fq 'not compared with the historical step-132 exact vector' "$doc"; then pass "implementation document records corrected characterization semantics"; else fail "implementation document records corrected characterization semantics"; fi
if grep -Fq 'Step 153' "$doc" && grep -Fq 'single-use repository authorization' "$doc" && grep -Fq 'step-149 machine authorization remains consumed' "$doc"; then pass "implementation document closes consumed authorization boundaries"; else fail "implementation document closes consumed authorization boundaries"; fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail "implementation helper contains no package, boot, or shutdown mutation command"; else pass "implementation helper contains no package, boot, or shutdown mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)' "$helper"; then fail "implementation helper contains no network client command"; else pass "implementation helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
