#!/bin/bash
set -u
set -o pipefail
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review.sh"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization.tsv"
step155_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review-policy.json"
step155_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.tsv"
step155_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.md"
implementation_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-policy.json"
step153_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
consumed_step150="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
successor="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$*"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; if [[ -f "$path" && ! -L "$path" ]]; then actual=$(sha256sum -- "$path" | awk '{print $1}'); else actual=missing; fi; if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; printf '  expected: %s\n  actual:   %s\n' "$expected" "${actual:-<missing>}"; fi; }

for entry in \
    "$helper|step-156 authorization helper" \
    "$doc|step-156 reference document" \
    "$policy|step-156 authorization policy" \
    "$authorization|step-156 authorization record" \
    "$step155_policy|step-155 implementation-review policy" \
    "$step155_record|step-155 implementation-review record" \
    "$step155_doc|step-155 reference document" \
    "$implementation_policy|step-154 implementation policy" \
    "$step153_policy|consumed step-153 authorization policy" \
    "$binding_policy|step-132 target-binding policy" \
    "$accepted_closure|accepted Slackware 15.0 ELILO closure" \
    "$consumed_step150|consumed step-150 execution harness" \
    "$successor|accepted successor execution harness" \
    "$source_file|accepted remediated reference source" \
    "$template|configuration template"; do
    check_regular "${entry%%|*}" "${entry#*|}"
done

check_hash "$helper" 7c42b48e7ed487a439bcaa148ed3dcc136d9efe1d3dca4a41a3d8c5bd3158a2a "step-156 authorization helper"
check_hash "$doc" 3c85259d59689f043fa34a07aded0d3555dabb74f41142711c08d84672465cee "step-156 reference document"
check_hash "$policy" a01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375 "step-156 authorization policy"
check_hash "$authorization" 6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017 "step-156 authorization record"
check_hash "$step155_policy" c8da64247cc5a6020a82876eac2617be6b34901e65241bec100993387c6a1945 "step-155 implementation-review policy"
check_hash "$step155_record" d449e3d46ea3c3c42344df12176d637fe6879533012ad0994809b617bdbc4f65 "step-155 implementation-review record"
check_hash "$step155_doc" 2f8873922f294285706d89f61543dafdbe355ea62080268529c66cc9062173eb "step-155 reference document"
check_hash "$implementation_policy" 38e73937af376b9bf0a5f9378144b4ecb3c963e475707214e05e51df3495a9d7 "step-154 implementation policy"
check_hash "$step153_policy" a4192c8562b59110e60c99bd64be17b1459e1c2c210117a60e97b0609be20a4c "consumed step-153 authorization policy"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"
check_hash "$consumed_step150" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
check_hash "$successor" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "accepted successor execution harness"
check_hash "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference source"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"

if bash -n "$helper"; then pass "step-156 authorization helper is shell-syntax valid"; else fail "step-156 authorization helper is shell-syntax valid"; fi
if bash -n "$successor"; then pass "successor execution harness remains shell-syntax valid"; else fail "successor execution harness remains shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "step-156 helper exposes a non-mutating help boundary"; else fail "step-156 helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "step-156 helper rejects unknown options"; else pass "step-156 helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "step-156 authorization policy is valid JSON"; else fail "step-156 authorization policy is valid JSON"; fi

python_checks=$(python3 - "$step155_policy" "$policy" "$authorization" <<'PY'
import csv
import json
import sys
with open(sys.argv[1], encoding='utf-8') as handle:
    step155 = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    policy = json.load(handle)
with open(sys.argv[3], encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
checks = []
def add(label, value): checks.append((label, bool(value)))
add('step-155 review is accepted', step155['review_verdict'] == 'accepted')
add('step-155 locks the successor implementation', step155['reviewed_implementation']['implementation_locked'] is True)
add('step-155 releases only to a fresh authorization review', step155['next_stage'] == policy['scenario'])
add('step-149 authorization remains non-reusable', policy['prior_authorization_state']['step149_machine_authorization_reusable'] is False)
add('step-153 repository authorization remains consumed', policy['prior_authorization_state']['step153_repository_authorization_consumed'] is True)
add('authorization freezes successor harness SHA-256', policy['execution']['execution_harness_sha256'] == '6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7')
add('authorization preserves core identity gate', policy['execution']['identity_gate_scope'] == 'accepted-elilo-core-identity-only')
add('runtime capability bits come from live probe', policy['execution']['runtime_capability_bits_from_probe'] is True)
add('historical exact capability vector is not required', policy['execution']['historical_exact_capability_vector_required'] is False)
add('runtime acceptance preserves fail-closed semantics', policy['execution']['runtime_acceptance_scope'] == 'auto-fail-closed-incomplete-layout-semantics')
add('authorization target is Slackware 15.0', policy['target']['target'] == 'slackware-15.0')
add('authorization freezes expected FQDN', policy['target']['hostname_fqdn'] == 'vbox-slack15.vbox-slack15.org')
add('authorization freezes accepted kernel', policy['target']['running_kernel'] == '5.15.209')
add('authorization requires one execution', policy['authorization']['machine_execution_limit'] == 1)
add('authorization is consumable', policy['authorization']['authorization_consumable'] is True)
add('machine execution is authorized', policy['authorization']['execution_authorized'] is True)
add('reboot remains forbidden', policy['authorization']['reboot_limit'] == 0)
for key in ('repository_refresh_authorized', 'package_mutation_authorized', 'boot_mutation_authorized', 'source_change_authorized', 'configuration_template_change_authorized', 'contract_change_authorized', 'target_binding_change_authorized', 'execution_harness_change_authorized', 'retry_authorized'):
    add(key.replace('_', ' ') + ' is false', policy['authorization'][key] is False)
add('authorization is publication-state independent', policy['slackware_repository_state_dependency'] is False)
add('authorization review requires no machine action', policy['machine_action_required'] is False)
add('authorization checkpoint is pause-safe', policy['pause_safe'] is True)
add('authorization advances to single execution', policy['next_stage'].endswith('characterization-remediated-rerun-execution'))
add('authorization record contains exactly one row', len(rows) == 1)
if rows:
    row = rows[0]
    add('authorization record is unconsumed', row['status'] == 'authorized-unconsumed')
    add('authorization record has no retry', row['retry_authorized'] == 'false')
for label, ok in checks:
    print(('PASS' if ok else 'FAIL') + '\t' + label)
PY
)
while IFS=$'\t' read -r result label; do
    [[ "$result" == PASS ]] && pass "$label" || fail "$label"
done <<< "$python_checks"

before_successor=$(sha256sum -- "$successor" | awk '{print $1}')
before_step155=$(sha256sum -- "$step155_policy" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_closure=$(sha256sum -- "$accepted_closure" | awk '{print $1}')
before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "step-156 characterization-remediated rerun authorization review completed successfully"; else fail "step-156 characterization-remediated rerun authorization review completed successfully"; fi
[[ $(sha256sum -- "$successor" | awk '{print $1}') == "$before_successor" ]] && pass "authorization review preserves the successor harness" || fail "authorization review preserves the successor harness"
[[ $(sha256sum -- "$step155_policy" | awk '{print $1}') == "$before_step155" ]] && pass "authorization review preserves the step-155 review policy" || fail "authorization review preserves the step-155 review policy"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "authorization review preserves the historical target binding" || fail "authorization review preserves the historical target binding"
[[ $(sha256sum -- "$accepted_closure" | awk '{print $1}') == "$before_closure" ]] && pass "authorization review preserves the accepted ELILO closure" || fail "authorization review preserves the accepted ELILO closure"
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "authorization review preserves the accepted source" || fail "authorization review preserves the accepted source"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "authorization review preserves the configuration template" || fail "authorization review preserves the configuration template"

check_output schema 1 "authorization output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review "authorization output records the expected scenario"
check_output authorization_id runtime-slackware-15-characterization-remediated-rerun "authorization output records the fresh authorization id"
check_output step155_review_policy_sha256 c8da64247cc5a6020a82876eac2617be6b34901e65241bec100993387c6a1945 "authorization is bound to the accepted step-155 review policy"
check_output source_sha256 aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "authorization freezes the accepted source"
check_output template_sha256 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "authorization freezes the configuration template"
check_output target_binding_policy_sha256 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "authorization freezes the historical target binding"
check_output accepted_elilo_closure_record_sha256 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "authorization freezes the accepted ELILO closure"
check_output consumed_step150_harness_sha256 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "authorization preserves the consumed step-150 harness identity"
check_output execution_harness_sha256 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "authorization freezes the successor execution harness"
check_output authorization_record_sha256 6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017 "authorization freezes its record"
check_output authorization_policy_sha256 a01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375 "authorization exposes the policy SHA-256 required by execution"
check_output identity_gate_scope accepted-elilo-core-identity-only "authorization preserves the corrected identity gate"
check_output runtime_capability_bits_from_probe true "authorization requires live capability observations"
check_output historical_exact_capability_vector_required false "authorization rejects the historical exact capability vector"
check_output runtime_acceptance_scope auto-fail-closed-incomplete-layout-semantics "authorization freezes semantic fail-closed acceptance"
check_output step149_authorization_reusable false "consumed step-149 authorization remains non-reusable"
check_output step153_authorization_consumed true "step-153 repository authorization remains consumed"
check_output machine_execution_authorized true "authorization grants exactly the pending machine execution"
check_output authorization_consumable true "authorization is consumable"
check_output machine_execution_limit 1 "authorization permits one machine execution"
check_output reboots_allowed 0 "authorization permits zero reboots"
check_output repository_refresh_allowed false "authorization permits no repository refresh"
check_output package_mutation_allowed false "authorization permits no package mutation"
check_output boot_mutation_allowed false "authorization permits no boot mutation"
check_output source_change_authorized false "authorization permits no source change"
check_output configuration_template_change_authorized false "authorization permits no configuration-template change"
check_output contract_change_authorized false "authorization permits no contract change"
check_output target_binding_change_authorized false "authorization permits no target-binding change"
check_output execution_harness_change_authorized false "authorization permits no harness change"
check_output retry_authorized false "authorization permits no retry"
check_output machine_action_required false "authorization review itself requires no machine action"
check_output slackware_repository_state_dependency false "authorization is independent of later Slackware publications"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-execution "authorization advances to the single execution"
check_output pause_safe true "authorization checkpoint is pause-safe"

for phrase in \
    'single-use and consumable by one invocation' \
    'permits zero reboots' \
    'historical exact capability vector is not an acceptance requirement' \
    'consumed step-149 machine authorization remains non-reusable' \
    'pause_safe=true'; do
    if python3 - "$doc" "$phrase" <<'PY_DOC'
import sys
text = ' '.join(open(sys.argv[1], encoding='utf-8').read().split())
phrase = ' '.join(sys.argv[2].split())
raise SystemExit(0 if phrase in text else 1)
PY_DOC
    then pass "authorization document records: $phrase"; else fail "authorization document records: $phrase"; fi
done

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|grub-reboot|grub-set-default|grub-editenv|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail "authorization helper contains no package, boot, or shutdown mutation command"; else pass "authorization helper contains no package, boot, or shutdown mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)' "$helper"; then fail "authorization helper contains no network client command"; else pass "authorization helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
