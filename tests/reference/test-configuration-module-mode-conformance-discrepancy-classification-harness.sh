#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-conformance-discrepancy-classification.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"
step123_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review-policy.json"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-discrepancy-classification-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-conformance-discrepancy-classification.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() {
    local path=$1 label=$2
    if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi
}
check_hash() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi
}
check_output() {
    local key=$1 expected=$2 label=$3 actual
    actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output")
    if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; fi
}

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$contract" "step-122 frozen mode contract"
check_regular "$review" "step-123 conformance review"
check_regular "$step123_policy" "step-123 conformance policy"
check_regular "$policy" "step-124 classification policy"
check_regular "$helper" "step-124 classification helper"
check_regular "$doc" "step-124 classification document"

check_hash "$source_file" 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$review" 8d642b84b9e23c7c88a5af259ec4ff75bc68d57e60f7b87d1baaa7664f40e9e1 "step-123 conformance review"
check_hash "$step123_policy" 823fee83b57d701f3e4fe6021d778f1217ad58c82dc4356c405b6ebb04420753 "step-123 conformance policy"

if bash -n "$helper"; then pass "classification helper is shell-syntax valid"; else fail "classification helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "classification helper exposes a non-mutating help boundary"; else fail "classification helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "classification policy is valid JSON"; else fail "classification policy is valid JSON"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_review=$(sha256sum -- "$review" | awk '{print $1}')
before_step123=$(sha256sum -- "$step123_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "conformance discrepancy classification completed successfully"; else fail "conformance discrepancy classification completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "classification did not modify the reference implementation" || fail "classification did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "classification did not modify the configuration template" || fail "classification did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "classification did not modify the frozen mode contract" || fail "classification did not modify the frozen mode contract"
[[ $(sha256sum -- "$review" | awk '{print $1}') == "$before_review" ]] && pass "classification did not modify the accepted step-123 review" || fail "classification did not modify the accepted step-123 review"
[[ $(sha256sum -- "$step123_policy" | awk '{print $1}') == "$before_step123" ]] && pass "classification did not modify the accepted step-123 policy" || fail "classification did not modify the accepted step-123 policy"

check_output schema 1 "classification output records schema 1"
check_output scenario phase-1-configuration-module-mode-conformance-discrepancy-classification "classification output records the expected scenario"
check_output discrepancy_id boot-auto-partial-path-availability "classification keeps the exact step-123 discrepancy"
check_output discrepancy_module boot "classification remains scoped to boot"
check_output discrepancy_mode auto "classification remains scoped to auto mode"
check_output discrepancy_classification implementation-conformance-gap "discrepancy is classified as an implementation conformance gap"
check_output safety_domain boot-preparation "classification records the boot-preparation safety domain"
check_output resolution_direction preserve-contract-tighten-source "classification preserves the contract and points remediation at the source"
check_output contract_change_recommended false "classification does not recommend relaxing the frozen contract"
check_output source_change_recommended true "classification recommends a future source remediation"
check_output runtime_behavior_change false "classification itself changes no runtime behavior"
check_output configuration_template_change false "classification changes no configuration template"
check_output source_change_authorized false "classification does not yet authorize source modification"
check_output contract_change_authorized false "classification does not authorize contract modification"
check_output machine_action_required false "classification requires no machine action"
check_output slackware_repository_state_dependency false "classification has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-remediation-decision-freeze "classification advances only to remediation decision freeze"
check_output pause_safe true "repository-only classification remains pause-safe"

if grep -Fq 'implementation-conformance-gap' "$doc" && grep -Fq 'preserve-contract-tighten-source' "$doc"; then
    pass "classification document records the selected classification and resolution direction"
else
    fail "classification document records the selected classification and resolution direction"
fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then
    pass "classification document preserves both mandatory Slackware targets"
else
    fail "classification document preserves both mandatory Slackware targets"
fi
if grep -Fq 'phase-1-configuration-module-mode-remediation-decision-freeze' "$doc"; then
    pass "classification document limits continuation to remediation decision freeze"
else
    fail "classification document limits continuation to remediation decision freeze"
fi

# Detect executable mutation commands, not quoted source-landmark text.
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "classification helper contains no package, boot, or shutdown mutation command"
else
    pass "classification helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "classification helper contains no network client command"
else
    pass "classification helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
