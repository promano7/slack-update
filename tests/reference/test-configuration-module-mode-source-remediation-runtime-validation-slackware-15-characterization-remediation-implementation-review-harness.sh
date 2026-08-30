#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.sh"
successor="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
review_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.tsv"
review_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review-policy.json"
review_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.md"
step154_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.tsv"
step154_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-policy.json"
step154_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.md"
step153_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
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
    "$helper|step-155 implementation-review helper" \
    "$successor|step-154 successor execution harness" \
    "$review_record|step-155 implementation-review record" \
    "$review_policy|step-155 implementation-review policy" \
    "$review_doc|step-155 reference document" \
    "$step154_record|step-154 implementation record" \
    "$step154_policy|step-154 implementation policy" \
    "$step154_doc|step-154 reference document" \
    "$step153_policy|consumed step-153 authorization policy" \
    "$step150_harness|consumed step-150 execution harness" \
    "$binding_policy|step-132 target-binding policy" \
    "$accepted_closure|accepted Slackware 15.0 ELILO closure"; do
    check_regular "${entry%%|*}" "${entry#*|}"
done

check_hash "$successor" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "step-154 successor execution harness"
check_hash "$step154_record" caf14634fc170cfd638b6a678d13943748c13ee75bcb501f2b09ffcca0a218d9 "step-154 implementation record"
check_hash "$step154_policy" 38e73937af376b9bf0a5f9378144b4ecb3c963e475707214e05e51df3495a9d7 "step-154 implementation policy"
check_hash "$step154_doc" db36c2fbd3750081eb1b7582ed24c22e1929f28c1f46a6244de3bf52241f3e34 "step-154 reference document"
check_hash "$step153_policy" a4192c8562b59110e60c99bd64be17b1459e1c2c210117a60e97b0609be20a4c "consumed step-153 authorization policy"
check_hash "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

if [[ ! -e "$future_execution_policy" && ! -L "$future_execution_policy" ]]; then pass "future machine-execution authorization policy remains absent"; else fail "future machine-execution authorization policy remains absent"; fi
if bash -n "$helper"; then pass "step-155 review helper is shell-syntax valid"; else fail "step-155 review helper is shell-syntax valid"; fi
if bash -n "$successor"; then pass "reviewed successor harness remains shell-syntax valid"; else fail "reviewed successor harness remains shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "step-155 helper exposes a non-mutating help boundary"; else fail "step-155 helper exposes a non-mutating help boundary"; fi
if "$helper" --unknown-option >/dev/null 2>&1; then fail "step-155 helper rejects unknown options"; else pass "step-155 helper rejects unknown options"; fi
if "$successor" --help >/dev/null; then pass "reviewed successor harness exposes help without machine authorization"; else fail "reviewed successor harness exposes help without machine authorization"; fi
if "$successor" --target slackware-15.0 --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org --confirm-execution-authorization-policy-sha256 0000000000000000000000000000000000000000000000000000000000000000 >/dev/null 2>&1; then
    fail "reviewed successor harness still refuses execution while authorization is absent"
else
    rc=$?
    [[ $rc -eq 3 ]] && pass "reviewed successor harness still refuses execution while authorization is absent" || fail "reviewed successor harness still refuses execution while authorization is absent"
fi
if python3 -m json.tool "$review_policy" >/dev/null; then pass "step-155 implementation-review policy is valid JSON"; else fail "step-155 implementation-review policy is valid JSON"; fi

python_checks=$(python3 - "$review_policy" "$step154_policy" "$review_record" <<'PY'
import csv, json, sys
review_path, step154_path, record_path = sys.argv[1:]
with open(review_path, encoding='utf-8') as f: r=json.load(f)
with open(step154_path, encoding='utf-8') as f: s=json.load(f)
with open(record_path, encoding='utf-8', newline='') as f: rows=list(csv.DictReader(f, delimiter='\t'))
checks=[]
def add(name, cond): checks.append((name, bool(cond)))
add('review policy records schema 1', r['schema']==1)
add('review policy records expected scenario', r['scenario'].endswith('characterization-remediation-implementation-review'))
add('review verdict is accepted', r['review_verdict']=='accepted')
add('review binds exact successor SHA-256', r['reviewed_implementation']['successor_harness_sha256']=='6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7')
add('review freezes core identity scope', r['reviewed_implementation']['identity_gate_scope']=='accepted-elilo-core-identity-only')
add('review keeps mkinitrd out of pre-probe identity', r['reviewed_implementation']['mkinitrd_regular_file_pre_probe_requirement'] is False)
add('review keeps GRUB absence out of pre-probe identity', r['reviewed_implementation']['grub_absence_pre_probe_requirement'] is False)
add('review requires live runtime capability bits', r['reviewed_implementation']['runtime_capability_bits_from_probe'] is True)
add('review rejects historical exact capability vector', r['reviewed_implementation']['historical_exact_capability_vector_required'] is False)
add('review preserves semantic fail-closed acceptance', r['reviewed_implementation']['runtime_acceptance_scope']=='auto-fail-closed-incomplete-layout-semantics')
add('review locks accepted implementation', r['reviewed_implementation']['implementation_locked'] is True)
add('step-153 repository authorization remains consumed', r['authorization_state']['step153_repository_authorization_consumed'] is True)
add('step-149 machine authorization remains non-reusable', r['authorization_state']['step149_machine_authorization_reusable'] is False)
add('future execution policy remains absent in policy', r['authorization_state']['future_execution_authorization_policy_exists'] is False)
add('no further harness change remains authorized', r['authorization_state']['further_execution_harness_change_authorized'] is False)
add('machine execution remains unauthorized in policy', r['machine_execution_authorized'] is False)
add('Slackware 15 rerun remains unauthorized in policy', r['slackware_15_rerun_authorized'] is False)
add('source change remains absent', r['source_change_applied'] is False)
add('configuration-template change remains absent', r['configuration_template_change_applied'] is False)
add('contract change remains absent', r['contract_change_applied'] is False)
add('target-binding change remains absent', r['target_binding_change_applied'] is False)
add('repository refresh remains unnecessary', r['repository_refresh_required'] is False)
add('review is publication-state independent', r['slackware_repository_state_dependency'] is False)
add('review requires no machine action', r['machine_action_required'] is False)
add('future work requires a fresh boundary', r['future_work_requires_fresh_boundary'] is True)
add('review records safe pause', r['pause_safe'] is True)
add('review next stage is fresh rerun authorization review', r['next_stage'].endswith('characterization-remediated-rerun-authorization-review'))
add('step-154 implementation already consumed step-153 authorization', s['implementation']['step153_repository_authorization_consumed'] is True)
add('step-154 implementation left future authorization absent', s['execution_hold']['future_execution_authorization_policy_exists'] is False)
add('step-154 implementation left machine execution unauthorized', s['machine_execution_authorized'] is False)
add('review record contains exactly one row', len(rows)==1)
if rows:
    row=rows[0]
    add('review record accepts implementation', row['implementation_verdict']=='accepted')
    add('review record marks reviewed safe pause', row['status']=='reviewed-safe-pause')
    add('review record keeps machine execution unauthorized', row['machine_execution_authorized']=='false')
    add('review record keeps rerun unauthorized', row['slackware_15_rerun_authorized']=='false')
for name, ok in checks:
    print(('PASS' if ok else 'FAIL')+'\t'+name)
PY
)
while IFS=$'\t' read -r result label; do
    [[ "$result" == PASS ]] && pass "$label" || fail "$label"
done <<< "$python_checks"

before_successor=$(sha256sum -- "$successor" | awk '{print $1}')
before_step154=$(sha256sum -- "$step154_policy" | awk '{print $1}')
before_step150=$(sha256sum -- "$step150_harness" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_closure=$(sha256sum -- "$accepted_closure" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "step-155 implementation review completed successfully"; else fail "step-155 implementation review completed successfully"; fi
[[ $(sha256sum -- "$successor" | awk '{print $1}') == "$before_successor" ]] && pass "review helper preserves the accepted successor harness" || fail "review helper preserves the accepted successor harness"
[[ $(sha256sum -- "$step154_policy" | awk '{print $1}') == "$before_step154" ]] && pass "review helper preserves the step-154 implementation policy" || fail "review helper preserves the step-154 implementation policy"
[[ $(sha256sum -- "$step150_harness" | awk '{print $1}') == "$before_step150" ]] && pass "review helper preserves the consumed step-150 harness" || fail "review helper preserves the consumed step-150 harness"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "review helper preserves the historical target binding" || fail "review helper preserves the historical target binding"
[[ $(sha256sum -- "$accepted_closure" | awk '{print $1}') == "$before_closure" ]] && pass "review helper preserves the accepted ELILO closure" || fail "review helper preserves the accepted ELILO closure"

check_output schema 1 "review output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review "review output records the expected scenario"
check_output review_id slackware-15-characterization-remediation-implementation "review output remains bound to the implementation"
check_output implementation_verdict accepted "review accepts the step-154 implementation"
check_output successor_harness_sha256 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "review freezes the exact successor harness"
check_output identity_gate_scope accepted-elilo-core-identity-only "review freezes the corrected identity gate"
check_output mkinitrd_pre_probe_gate false "review keeps mkinitrd presence out of the identity gate"
check_output grub_pre_probe_gate false "review keeps GRUB absence out of the identity gate"
check_output runtime_capability_bits_from_probe true "review requires live runtime capability observations"
check_output historical_exact_capability_vector_required false "review rejects the historical exact capability vector"
check_output runtime_acceptance_scope auto-fail-closed-incomplete-layout-semantics "review freezes semantic fail-closed acceptance"
check_output step153_authorization_consumed true "review records step-153 repository authorization consumed"
check_output step149_authorization_reusable false "review records step-149 machine authorization non-reusable"
check_output future_execution_policy_exists false "review leaves future execution authorization absent"
check_output further_execution_harness_change_authorized false "review authorizes no further harness change"
check_output source_change_applied false "review applies no source change"
check_output configuration_template_change_applied false "review applies no configuration-template change"
check_output contract_change_applied false "review applies no contract change"
check_output target_binding_change_applied false "review applies no target-binding change"
check_output machine_execution_authorized false "review authorizes no machine execution"
check_output slackware_15_rerun_authorized false "review authorizes no Slackware 15 rerun"
check_output repository_refresh_required false "review requires no repository refresh"
check_output slackware_repository_state_dependency false "review is independent of Slackware publication state"
check_output machine_action_required false "review requires no machine action"
check_output future_work_requires_fresh_boundary true "review requires a fresh future boundary"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review "review advances only to a fresh authorization review"
check_output pause_safe true "implementation-review checkpoint is pause-safe"

for phrase in \
    'The implementation is accepted.' \
    'No future machine-execution authorization policy exists at this checkpoint.' \
    'The old step-149 machine authorization cannot be reused.' \
    'requires no machine action' \
    'strong safe pause' \
    'pause_safe=true'; do
    if grep -Fq "$phrase" "$review_doc"; then pass "review document records: $phrase"; else fail "review document records: $phrase"; fi
done

if grep -Eq '(^|[[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|mkinitrd|grub-install|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$helper"; then fail "review helper contains no package, boot, or shutdown mutation command"; else pass "review helper contains no package, boot, or shutdown mutation command"; fi
if grep -Eq '(^|[[:space:]])(curl|wget|ftp|rsync)([[:space:]]|$)' "$helper"; then fail "review helper contains no network client command"; else pass "review helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
