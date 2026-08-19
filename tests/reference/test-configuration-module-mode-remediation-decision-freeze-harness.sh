#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-remediation-decision-freeze.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"
step123_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review-policy.json"
step124_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-discrepancy-classification-policy.json"
decision="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision-freeze-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-remediation-decision-freeze.md"

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
check_regular "$step124_policy" "step-124 classification policy"
check_regular "$decision" "step-125 frozen remediation decision"
check_regular "$policy" "step-125 decision-freeze policy"
check_regular "$helper" "step-125 decision-freeze helper"
check_regular "$doc" "step-125 decision-freeze document"

check_hash "$source_file" 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$review" 8d642b84b9e23c7c88a5af259ec4ff75bc68d57e60f7b87d1baaa7664f40e9e1 "step-123 conformance review"
check_hash "$step123_policy" 823fee83b57d701f3e4fe6021d778f1217ad58c82dc4356c405b6ebb04420753 "step-123 conformance policy"
check_hash "$step124_policy" a5c75793771c60b1717614ceea1e8832f29eb4b25f94865204cd3c8208b37258 "step-124 classification policy"

if bash -n "$helper"; then pass "decision-freeze helper is shell-syntax valid"; else fail "decision-freeze helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "decision-freeze helper exposes a non-mutating help boundary"; else fail "decision-freeze helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "decision-freeze policy is valid JSON"; else fail "decision-freeze policy is valid JSON"; fi

if python3 - "$decision" "$policy" <<'PY'
import csv, json, sys
with open(sys.argv[1], encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(sys.argv[2], encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
frozen = policy["frozen_decision"]
assert row["discrepancy_id"] == frozen["discrepancy_id"]
assert row["resolution_direction"] == frozen["resolution_direction"]
assert row["future_source_scope"] == frozen["future_source_scope"]
assert row["target_behavior"] == frozen["target_behavior"]
assert row["source_change_authorized"] == "false"
assert row["contract_change_authorized"] == "false"
PY
then pass "decision TSV and freeze policy are internally consistent"; else fail "decision TSV and freeze policy are internally consistent"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_review=$(sha256sum -- "$review" | awk '{print $1}')
before_step123=$(sha256sum -- "$step123_policy" | awk '{print $1}')
before_step124=$(sha256sum -- "$step124_policy" | awk '{print $1}')
before_decision=$(sha256sum -- "$decision" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "remediation decision freeze completed successfully"; else fail "remediation decision freeze completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "freeze did not modify the reference implementation" || fail "freeze did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "freeze did not modify the configuration template" || fail "freeze did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "freeze did not modify the frozen mode contract" || fail "freeze did not modify the frozen mode contract"
[[ $(sha256sum -- "$review" | awk '{print $1}') == "$before_review" ]] && pass "freeze did not modify the accepted step-123 review" || fail "freeze did not modify the accepted step-123 review"
[[ $(sha256sum -- "$step123_policy" | awk '{print $1}') == "$before_step123" ]] && pass "freeze did not modify the accepted step-123 policy" || fail "freeze did not modify the accepted step-123 policy"
[[ $(sha256sum -- "$step124_policy" | awk '{print $1}') == "$before_step124" ]] && pass "freeze did not modify the accepted step-124 policy" || fail "freeze did not modify the accepted step-124 policy"
[[ $(sha256sum -- "$decision" | awk '{print $1}') == "$before_decision" ]] && pass "freeze did not modify its decision input" || fail "freeze did not modify its decision input"

check_output schema 1 "freeze output records schema 1"
check_output scenario phase-1-configuration-module-mode-remediation-decision-freeze "freeze output records the expected scenario"
check_output discrepancy_id boot-auto-partial-path-availability "freeze keeps the exact classified discrepancy"
check_output discrepancy_module boot "freeze remains scoped to boot"
check_output discrepancy_mode auto "freeze remains scoped to auto mode"
check_output discrepancy_classification implementation-conformance-gap "freeze preserves the implementation-gap classification"
check_output safety_domain boot-preparation "freeze preserves the boot-preparation safety domain"
check_output resolution_direction preserve-contract-tighten-source "freeze preserves the remediation direction"
check_output contract_preservation required "freeze requires preservation of the contract"
check_output source_remediation_required true "freeze records that source remediation is required"
check_output future_source_scope boot-auto-partial-applicability-only "freeze limits the future source scope"
check_output target_behavior auto-not-runnable-unless-validated-supported-preparation-path "freeze records the target behavior"
check_output decision_frozen true "remediation decision is explicitly frozen"
check_output runtime_behavior_change false "freeze itself changes no runtime behavior"
check_output configuration_template_change false "freeze changes no configuration template"
check_output source_change_authorized false "freeze does not yet authorize source modification"
check_output contract_change_authorized false "freeze does not authorize contract modification"
check_output machine_action_required false "freeze requires no machine action"
check_output slackware_repository_state_dependency false "freeze has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-source-remediation-design "freeze advances only to source remediation design"
check_output pause_safe true "repository-only decision freeze remains pause-safe"

if grep -Fq 'preserve-contract-tighten-source' "$doc" && grep -Fq 'boot-auto-partial-applicability-only' "$doc"; then
    pass "decision-freeze document records the frozen direction and scope"
else
    fail "decision-freeze document records the frozen direction and scope"
fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then
    pass "decision-freeze document preserves both mandatory Slackware targets"
else
    fail "decision-freeze document preserves both mandatory Slackware targets"
fi
if grep -Fq 'phase-1-configuration-module-mode-source-remediation-design' "$doc"; then
    pass "decision-freeze document limits continuation to source remediation design"
else
    fail "decision-freeze document limits continuation to source remediation design"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "decision-freeze helper contains no package, boot, or shutdown mutation command"
else
    pass "decision-freeze helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "decision-freeze helper contains no network client command"
else
    pass "decision-freeze helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
