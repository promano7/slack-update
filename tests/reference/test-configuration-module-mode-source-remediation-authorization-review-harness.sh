#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-authorization-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
decision="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision.tsv"
step125_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision-freeze-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design.tsv"
step126_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-authorization-review.md"

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
check_regular "$step126_policy" "step-126 remediation-design policy"
check_regular "$authorization" "step-127 source authorization"
check_regular "$policy" "step-127 authorization-review policy"
check_regular "$helper" "step-127 authorization-review helper"
check_regular "$doc" "step-127 authorization-review document"

check_hash "$source_file" 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$decision" 9ed9ebe81da18b837a86d4bcc6d5c537aef3061378e0f9b1e7400cedfe422d83 "step-125 frozen remediation decision"
check_hash "$step125_policy" f5243cf0e14af0e2b94b06dbf904a53a122f1b59df807c9ed90bdccc2366ab5d "step-125 decision-freeze policy"
check_hash "$design" 36dcb8e9d4f91e166c00043f6f8930ecf6c985b49413fa44d4762dce4f81df45 "step-126 remediation design"
check_hash "$step126_policy" 982fffd2d145d9c88b89d2b5f929f19f698ffba4b81e15597a00d33637002e58 "step-126 remediation-design policy"
check_hash "$authorization" 8b2443f3b5f1de52a68cd4f8e4286ed88e071ac50ea99ee36c13905c251bfc08 "step-127 source authorization"
check_hash "$policy" f03d11f7d8bb0f6545e6abfea9ac20a8ae21e8ee2fa8b81a0ccbbd23dfecb98c "step-127 authorization-review policy"

if bash -n "$helper"; then pass "authorization-review helper is shell-syntax valid"; else fail "authorization-review helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "authorization-review helper exposes a non-mutating help boundary"; else fail "authorization-review helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "authorization-review policy is valid JSON"; else fail "authorization-review policy is valid JSON"; fi

if python3 - "$authorization" "$policy" <<'PY'
import csv, json, sys
with open(sys.argv[1], encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(sys.argv[2], encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
authorized = policy["authorized_source_change"]
assert row["discrepancy_id"] == authorized["discrepancy_id"]
assert row["function"] == authorized["function"]
assert row["mode"] == authorized["mode"]
assert row["authorization_scope"] == authorized["scope"]
assert row["authorized_edit"] == authorized["authorized_edit"]
assert row["source_change_authorized"] == "true"
assert policy["source_change_authorized"] is True
assert policy["source_change_applied"] is False
assert policy["contract_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
PY
then pass "authorization TSV and policy are internally consistent"; else fail "authorization TSV and policy are internally consistent"; fi

if grep -Fq 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then' "$source_file" \
    && grep -Fq 'BOOT_PREPARATION_LAYOUT=partial' "$source_file" \
    && grep -Fq 'auto mode detected a partial boot preparation path' "$source_file"; then
    pass "pre-edit source still contains the exact branch being authorized for removal"
else
    fail "pre-edit source still contains the exact branch being authorized for removal"
fi
if grep -Fq 'mkinitrd-managed|direct-generic-no-initrd)' "$source_file" \
    && grep -Fq 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd' "$source_file"; then
    pass "pre-edit source retains both validated complete-layout landmarks"
else
    fail "pre-edit source retains both validated complete-layout landmarks"
fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_design=$(sha256sum -- "$design" | awk '{print $1}')
before_step126=$(sha256sum -- "$step126_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "source remediation authorization review completed successfully"; else fail "source remediation authorization review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "authorization review did not modify the reference implementation" || fail "authorization review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "authorization review did not modify the configuration template" || fail "authorization review did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "authorization review did not modify the frozen mode contract" || fail "authorization review did not modify the frozen mode contract"
[[ $(sha256sum -- "$design" | awk '{print $1}') == "$before_design" ]] && pass "authorization review did not modify the step-126 design" || fail "authorization review did not modify the step-126 design"
[[ $(sha256sum -- "$step126_policy" | awk '{print $1}') == "$before_step126" ]] && pass "authorization review did not modify the step-126 policy" || fail "authorization review did not modify the step-126 policy"

check_output schema 1 "authorization output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-authorization-review "authorization output records the expected scenario"
check_output discrepancy_id boot-auto-partial-path-availability "authorization remains bound to the exact discrepancy"
check_output target_function probe_boot_module "authorization remains limited to probe_boot_module"
check_output authorized_mode auto "authorization remains limited to auto mode"
check_output authorization_scope boot-auto-partial-applicability-only "authorization preserves the frozen source scope"
check_output authorized_edit remove-auto-partial-availability-branch "authorization permits only the designed branch removal"
check_output pre_edit_source_sha256 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "authorization is bound to the exact pre-edit source identity"
check_output source_change_applied false "authorization review itself applies no source change"
check_output source_change_authorized true "authorization review grants the narrow source change"
check_output contract_change_authorized false "contract modification remains unauthorized"
check_output configuration_template_change_authorized false "configuration-template modification remains unauthorized"
check_output capability_probe_change_authorized false "capability-probe modification remains unauthorized"
check_output enabled_semantics_change_authorized false "enabled-mode semantic changes remain unauthorized"
check_output disabled_semantics_change_authorized false "disabled-mode semantic changes remain unauthorized"
check_output machine_action_required false "authorization review requires no machine action"
check_output slackware_repository_state_dependency false "authorization review has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-source-remediation-implementation "authorization advances only to source remediation implementation"
check_output pause_safe true "repository-only authorization boundary remains pause-safe"

if grep -Fq 'consumable only' "$doc" && grep -Fq 'SHA-256' "$doc" && grep -Fq 'invalid' "$doc"; then
    pass "authorization document binds consumption to the accepted source identity"
else
    fail "authorization document binds consumption to the accepted source identity"
fi
if grep -Fq 'does not apply' "$doc" && grep -Fq 'source_change_applied=false' "$doc"; then
    pass "authorization document preserves the review-only boundary"
else
    fail "authorization document preserves the review-only boundary"
fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then
    pass "authorization document preserves both mandatory Slackware targets"
else
    fail "authorization document preserves both mandatory Slackware targets"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "authorization-review helper contains no package, boot, or shutdown mutation command"
else
    pass "authorization-review helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "authorization-review helper contains no network client command"
else
    pass "authorization-review helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
