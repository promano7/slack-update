#!/bin/bash
set -u
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-design.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
decision="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision.tsv"
step125_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision-freeze-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-design.md"

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
check_regular "$decision" "step-125 frozen remediation decision"
check_regular "$step125_policy" "step-125 decision-freeze policy"
check_regular "$design" "step-126 remediation design"
check_regular "$policy" "step-126 remediation-design policy"
check_regular "$helper" "step-126 remediation-design helper"
check_regular "$doc" "step-126 remediation-design document"

check_hash "$source_file" 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$decision" 9ed9ebe81da18b837a86d4bcc6d5c537aef3061378e0f9b1e7400cedfe422d83 "step-125 frozen remediation decision"
check_hash "$step125_policy" f5243cf0e14af0e2b94b06dbf904a53a122f1b59df807c9ed90bdccc2366ab5d "step-125 decision-freeze policy"

if bash -n "$helper"; then pass "remediation-design helper is shell-syntax valid"; else fail "remediation-design helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "remediation-design helper exposes a non-mutating help boundary"; else fail "remediation-design helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "remediation-design policy is valid JSON"; else fail "remediation-design policy is valid JSON"; fi

if python3 - "$design" "$policy" <<'PY'
import csv, json, sys
with open(sys.argv[1], encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(sys.argv[2], encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
r = policy["designed_remediation"]
assert row["discrepancy_id"] == r["discrepancy_id"]
assert row["function"] == r["function"]
assert row["mode"] == r["mode"]
assert row["edit_strategy"] == r["edit_strategy"]
assert row["partial_auto_state"] == "unavailable"
assert row["partial_auto_run"] == "0"
assert row["source_change_authorized"] == "false"
assert policy["source_change_authorized"] is False
assert policy["contract_change_authorized"] is False
PY
then pass "design TSV and policy are internally consistent"; else fail "design TSV and policy are internally consistent"; fi

if grep -Fq 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then' "$source_file" \
    && grep -Fq 'BOOT_PREPARATION_LAYOUT=partial' "$source_file" \
    && grep -Fq 'auto mode detected a partial boot preparation path' "$source_file"; then
    pass "accepted source still contains the exact historical partial auto branch"
else
    fail "accepted source still contains the exact historical partial auto branch"
fi
if grep -Fq 'mkinitrd-managed|direct-generic-no-initrd)' "$source_file" \
    && grep -Fq 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd' "$source_file"; then
    pass "accepted source retains both validated complete-layout landmarks"
else
    fail "accepted source retains both validated complete-layout landmarks"
fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_decision=$(sha256sum -- "$decision" | awk '{print $1}')
before_step125=$(sha256sum -- "$step125_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "source remediation design completed successfully"; else fail "source remediation design completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "design did not modify the reference implementation" || fail "design did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "design did not modify the configuration template" || fail "design did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "design did not modify the frozen mode contract" || fail "design did not modify the frozen mode contract"
[[ $(sha256sum -- "$decision" | awk '{print $1}') == "$before_decision" ]] && pass "design did not modify the step-125 frozen decision" || fail "design did not modify the step-125 frozen decision"
[[ $(sha256sum -- "$step125_policy" | awk '{print $1}') == "$before_step125" ]] && pass "design did not modify the step-125 freeze policy" || fail "design did not modify the step-125 freeze policy"

check_output schema 1 "design output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-design "design output records the expected scenario"
check_output discrepancy_id boot-auto-partial-path-availability "design remains bound to the exact discrepancy"
check_output target_function probe_boot_module "design limits the future source edit to probe_boot_module"
check_output remediation_scope boot-auto-partial-applicability-only "design preserves the frozen source scope"
check_output edit_strategy remove-auto-partial-availability-branch "design chooses the minimal partial-branch removal strategy"
check_output partial_auto_target unavailable-non-runnable "design makes incomplete auto layouts non-runnable"
check_output preserve_complete_layouts true "design preserves validated complete layouts"
check_output preserve_enabled_semantics true "design preserves enabled-mode strict semantics"
check_output preserve_disabled_semantics true "design preserves disabled-mode bypass semantics"
check_output runtime_behavior_change false "design step itself changes no runtime behavior"
check_output configuration_template_change false "design changes no configuration template"
check_output source_change_authorized false "design does not authorize source modification"
check_output contract_change_authorized false "design does not authorize contract modification"
check_output machine_action_required false "design requires no machine action"
check_output slackware_repository_state_dependency false "design has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-source-remediation-authorization-review "design advances only to remediation authorization review"
check_output pause_safe true "repository-only design boundary remains pause-safe"

if grep -Fq 'remove' "$doc" && grep -Fq 'partial' "$doc" && grep -Fq 'fail-closed fallback' "$doc"; then
    pass "design document explains the minimal branch-removal strategy"
else
    fail "design document explains the minimal branch-removal strategy"
fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then
    pass "design document preserves both mandatory Slackware targets"
else
    fail "design document preserves both mandatory Slackware targets"
fi
if grep -Fq 'source edit' "$doc" && grep -Fq 'does not authorize' "$doc"; then
    pass "design document preserves the source authorization boundary"
else
    fail "design document preserves the source authorization boundary"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "remediation-design helper contains no package, boot, or shutdown mutation command"
else
    pass "remediation-design helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "remediation-design helper contains no network client command"
else
    pass "remediation-design helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
