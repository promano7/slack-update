#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-conformance-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step122_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract-freeze-policy.json"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-conformance-review.md"

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
check_regular "$step122_policy" "step-122 freeze policy"
check_regular "$review" "step-123 conformance review"
check_regular "$policy" "step-123 conformance policy"
check_regular "$helper" "step-123 conformance helper"
check_regular "$doc" "step-123 conformance document"

check_hash "$source_file" 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$step122_policy" b65d1860d408fec5ff87b509efb87cd95b90c229adaf0203f70db685fdbc847f "step-122 freeze policy"

if bash -n "$helper"; then pass "conformance helper is shell-syntax valid"; else fail "conformance helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "conformance helper exposes a non-mutating help boundary"; else fail "conformance helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "conformance policy is valid JSON"; else fail "conformance policy is valid JSON"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_step122=$(sha256sum -- "$step122_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "module-mode conformance review completed successfully"; else fail "module-mode conformance review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "review did not modify the reference implementation" || fail "review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "review did not modify the configuration template" || fail "review did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "review did not modify the frozen mode contract" || fail "review did not modify the frozen mode contract"
[[ $(sha256sum -- "$step122_policy" | awk '{print $1}') == "$before_step122" ]] && pass "review did not modify the accepted step-122 policy" || fail "review did not modify the accepted step-122 policy"

check_output schema 1 "review output records schema 1"
check_output scenario phase-1-configuration-module-mode-conformance-review "review output records the expected scenario"
check_output contract_rows_reviewed 15 "review covers all 15 frozen contract rows"
check_output conforming_rows 14 "review records fourteen conforming rows"
check_output discrepancy_rows 1 "review records exactly one discrepancy"
check_output all_rows_conform false "review does not falsely claim full conformance"
check_output discrepancy_id boot-auto-partial-path-availability "review names the boot auto discrepancy"
check_output discrepancy_module boot "discrepancy is scoped to boot"
check_output discrepancy_mode auto "discrepancy is scoped to auto mode"
check_output discrepancy_classification pending "discrepancy classification remains pending"
check_output runtime_behavior_change false "review records zero runtime behavior change"
check_output configuration_template_change false "review records zero configuration-template change"
check_output source_change_authorized false "review authorizes no source change"
check_output contract_change_authorized false "review authorizes no contract change"
check_output machine_action_required false "review requires no machine action"
check_output slackware_repository_state_dependency false "review has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-conformance-discrepancy-classification "review advances only to discrepancy classification"
check_output pause_safe true "repository-only conformance review remains pause-safe"

python3 - "$review" "$policy" <<'PY' && pass "policy and 15-row conformance table are internally consistent" || fail "policy and 15-row conformance table are internally consistent"
import csv, json, sys
review_path, policy_path = sys.argv[1:]
rows = list(csv.DictReader(open(review_path, encoding="utf-8"), delimiter="\t"))
policy = json.load(open(policy_path, encoding="utf-8"))
assert len(rows) == policy["contract_rows_reviewed"] == 15
assert sum(r["status"] == "conformant" for r in rows) == policy["conforming_rows"] == 14
assert sum(r["status"] == "discrepancy" for r in rows) == policy["discrepancy_rows"] == 1
assert policy["all_rows_conform"] is False
assert policy["runtime_behavior_change"] is False
assert policy["machine_action_required"] is False
assert policy["pause_safe"] is True
assert policy["discrepancies"][0]["id"] == "boot-auto-partial-path-availability"
PY

if grep -Eq '(^|[^[:alnum:]_])(curl|wget|ftp|rsync|scp|ssh)([^[:alnum:]_]|$)' "$helper"; then fail "conformance helper contains no network client command"; else pass "conformance helper contains no network client command"; fi
mutation_command_regex='(slackpkg|upgradepkg|installpkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig)'
if grep -Eq "^[[:space:]]*((if|while|until|then|do)[[:space:]]+)?((sudo|command)[[:space:]]+)?${mutation_command_regex}([[:space:]]|$)" "$helper" \
    || grep -Eq "(^|[;&|()])[[:space:]]*((sudo|command)[[:space:]]+)?${mutation_command_regex}([[:space:]]|$)" "$helper"; then
    fail "conformance helper contains no package or boot mutation command"
else
    pass "conformance helper contains no package or boot mutation command"
fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$helper"; then fail "conformance helper contains no reboot or shutdown command"; else pass "conformance helper contains no reboot or shutdown command"; fi
if grep -Eq '(^|[;&|[:space:]])(rm|mv|cp|install|ln|sed[[:space:]]+-i|truncate|dd)([[:space:]]|$)' "$helper"; then fail "conformance helper contains no repository file-mutation command"; else pass "conformance helper contains no repository file-mutation command"; fi

if grep -Fq 'Fourteen' "$doc" && grep -Fq 'boot-auto-partial-path-availability' "$doc"; then pass "review document records the 14-plus-1 conformance result"; else fail "review document records the 14-plus-1 conformance result"; fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then pass "review document preserves both mandatory Slackware targets"; else fail "review document preserves both mandatory Slackware targets"; fi
if grep -Fq 'phase-1-configuration-module-mode-conformance-discrepancy-classification' "$doc"; then pass "review document limits continuation to discrepancy classification"; else fail "review document limits continuation to discrepancy classification"; fi

if (( failures == 0 )); then
    printf 'Result: %d passes, 0 failures\n' "$passes"
    exit 0
fi
printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
exit 1
