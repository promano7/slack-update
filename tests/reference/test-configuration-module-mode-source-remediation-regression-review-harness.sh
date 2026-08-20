#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-regression-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step123_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"
step123_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review-policy.json"
step128_implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation.tsv"
step128_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation-policy.json"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-regression-review.md"

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
check_regular "$step123_review" "step-123 conformance review"
check_regular "$step123_policy" "step-123 conformance policy"
check_regular "$step128_implementation" "step-128 implementation record"
check_regular "$step128_policy" "step-128 implementation policy"
check_regular "$review" "step-129 regression review"
check_regular "$policy" "step-129 regression-review policy"
check_regular "$helper" "step-129 regression-review helper"
check_regular "$doc" "step-129 regression-review document"

check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "post-remediation reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$step123_review" 8d642b84b9e23c7c88a5af259ec4ff75bc68d57e60f7b87d1baaa7664f40e9e1 "step-123 conformance review"
check_hash "$step123_policy" 823fee83b57d701f3e4fe6021d778f1217ad58c82dc4356c405b6ebb04420753 "step-123 conformance policy"
check_hash "$step128_implementation" 368ea87d0a71a96f9dc8a6a08a4afcdfe9e10191ed0a3b3a827e98b049333725 "step-128 implementation record"
check_hash "$step128_policy" e91c542c7918a0bdbab68fa2650583410416ebe49d5ee481f957af4793dafb18 "step-128 implementation policy"

if bash -n "$source_file"; then pass "post-remediation reference implementation is shell-syntax valid"; else fail "post-remediation reference implementation is shell-syntax valid"; fi
if bash -n "$helper"; then pass "regression-review helper is shell-syntax valid"; else fail "regression-review helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "regression-review helper exposes a non-mutating help boundary"; else fail "regression-review helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "regression-review policy is valid JSON"; else fail "regression-review policy is valid JSON"; fi

if python3 - "$contract" "$step123_review" "$step128_implementation" "$step128_policy" "$review" "$policy" <<'PY'
import csv
import json
import sys

contract_path, old_path, implementation_path, step128_policy_path, review_path, policy_path = sys.argv[1:]
with open(contract_path, encoding="utf-8", newline="") as handle:
    contract = list(csv.DictReader(handle, delimiter="\t"))
with open(old_path, encoding="utf-8", newline="") as handle:
    old = list(csv.DictReader(handle, delimiter="\t"))
with open(implementation_path, encoding="utf-8", newline="") as handle:
    implementation = list(csv.DictReader(handle, delimiter="\t"))
with open(step128_policy_path, encoding="utf-8") as handle:
    step128 = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    review = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(contract) == len(old) == len(review) == 15
assert [(r["module"], r["mode"]) for r in contract] == [(r["module"], r["mode"]) for r in old]
assert [(r["module"], r["mode"]) for r in contract] == [(r["module"], r["mode"]) for r in review]
assert sum(r["status"] == "conformant" for r in old) == 14
old_discrepancies = [r for r in old if r["status"] == "discrepancy"]
assert len(old_discrepancies) == 1
assert old_discrepancies[0]["module"] == "boot" and old_discrepancies[0]["mode"] == "auto"
assert old_discrepancies[0]["discrepancy_id"] == "boot-auto-partial-path-availability"
assert all(r["status"] == "conformant" for r in review)
assert sum(r["evidence_basis"] == "step123-conformance-plus-step128-exact-delta" for r in review) == 14
resolved = [r for r in review if r["resolved_discrepancy_id"] != "-"]
assert len(resolved) == 1
assert resolved[0]["module"] == "boot" and resolved[0]["mode"] == "auto"
assert resolved[0]["resolved_discrepancy_id"] == "boot-auto-partial-path-availability"
assert resolved[0]["evidence_basis"] == "step128-behavioral-regression"
assert len(implementation) == 1
assert implementation[0]["post_edit_source_sha256"] == policy["source_sha256"]
assert step128["post_edit_source_sha256"] == policy["source_sha256"]
assert implementation[0]["source_change_applied"] == "true"
assert implementation[0]["authorization_consumed"] == "true"
assert implementation[0]["further_source_change_authorized"] == "false"
assert policy["contract_rows_reviewed"] == 15
assert policy["inherited_conforming_rows"] == 14
assert policy["remediated_rows_revalidated"] == 1
assert policy["conforming_rows"] == 15
assert policy["discrepancy_rows"] == 0
assert policy["all_rows_conform"] is True
assert policy["behavioral_regression_cases"] == 7
assert policy["further_source_change_authorized"] is False
assert policy["runtime_behavior_change_in_step129"] is False
assert policy["machine_action_required"] is False
assert policy["runtime_machine_validation_still_required"] is True
assert policy["pause_safe"] is True
PY
then pass "contract, historical review, implementation, and regression review are internally consistent"; else fail "contract, historical review, implementation, and regression review are internally consistent"; fi

if grep -Fq 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then' "$source_file" \
    || grep -Fq 'BOOT_PREPARATION_LAYOUT=partial' "$source_file" \
    || grep -Fq 'auto mode detected a partial boot preparation path' "$source_file"; then
    fail "historical auto-partial availability branch remains absent"
else
    pass "historical auto-partial availability branch remains absent"
fi
if grep -Fq 'mkinitrd-managed|direct-generic-no-initrd)' "$source_file" \
    && grep -Fq 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd' "$source_file"; then
    pass "both validated complete-layout landmarks remain present"
else
    fail "both validated complete-layout landmarks remain present"
fi
if grep -Fq 'BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"' "$source_file"; then
    pass "fail-closed auto fallback remains present"
else
    fail "fail-closed auto fallback remains present"
fi

run_probe_case() {
    local case_name=$1
    bash -s -- "$source_file" "$case_name" <<'BASH'
set -euo pipefail
source_file=$1
case_name=$2
source "$source_file"

tmp=$(mktemp -d)
rm_cmd=$(command -v rm)
cleanup_probe_fixture() { "$rm_cmd" -rf -- "$tmp"; }
trap cleanup_probe_fixture EXIT
mkdir -p "$tmp/bin" "$tmp/grub"
: > "$tmp/mkinitrd.conf"

make_command() {
    local name=$1
    printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/$name"
    chmod 0755 "$tmp/bin/$name"
}

BOOT_MODE=auto
MKINITRD_CONFIG="$tmp/missing-mkinitrd.conf"
GRUB_DIRECTORY="$tmp/missing-grub"
BOOT_DIRECT_GENERIC_REASON=

probe_direct_generic_boot_layout() {
    BOOT_DIRECT_GENERIC_AVAILABLE=0
    BOOT_DIRECT_GENERIC_REASON="direct generic fixture rejected"
    return 1
}

case "$case_name" in
    auto-mkinitrd-managed)
        make_command mkinitrd
        make_command grub-mkconfig
        make_command grub-script-check
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        GRUB_DIRECTORY="$tmp/grub"
        ;;
    auto-direct-generic)
        make_command grub-mkconfig
        make_command grub-script-check
        GRUB_DIRECTORY="$tmp/grub"
        probe_direct_generic_boot_layout() {
            BOOT_DIRECT_GENERIC_AVAILABLE=1
            BOOT_DIRECT_GENERIC_REASON=
            return 0
        }
        ;;
    auto-initrd-only)
        make_command mkinitrd
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        ;;
    auto-grub-only-invalid-direct)
        make_command grub-mkconfig
        make_command grub-script-check
        GRUB_DIRECTORY="$tmp/grub"
        ;;
    auto-none)
        ;;
    enabled-initrd-only)
        BOOT_MODE=enabled
        make_command mkinitrd
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        ;;
    disabled-any-layout)
        BOOT_MODE=disabled
        make_command mkinitrd
        make_command grub-mkconfig
        make_command grub-script-check
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        GRUB_DIRECTORY="$tmp/grub"
        ;;
    *)
        printf 'unknown case: %s\n' "$case_name" >&2
        exit 2
        ;;
esac

PATH="$tmp/bin"
probe_boot_module
printf '%s|%s|%s|%s|%s|%s\n' \
    "$BOOT_MODULE_STATE" "$BOOT_MODULE_RUN" "$BOOT_PREPARATION_LAYOUT" \
    "$BOOT_MODULE_REASON" "$BOOT_INITRD_AVAILABLE" "$BOOT_GRUB_AVAILABLE"
BASH
}

expect_probe_case() {
    local case_name=$1 expected=$2 label=$3 actual
    if actual=$(run_probe_case "$case_name") && [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label"
        printf '  expected: %s\n  actual:   %s\n' "$expected" "${actual:-<command failed>}"
    fi
}

expect_probe_case auto-mkinitrd-managed \
    'available|1|mkinitrd-managed||1|1' \
    "auto mode preserves the complete mkinitrd-managed layout"
expect_probe_case auto-direct-generic \
    'available|1|direct-generic-no-initrd||0|1' \
    "auto mode preserves the validated direct-generic-no-initrd layout"
expect_probe_case auto-initrd-only \
    'unavailable|0|unknown|no supported initrd or GRUB preparation path was detected|1|0' \
    "auto mode rejects an initrd-only partial capability set"
expect_probe_case auto-grub-only-invalid-direct \
    'unavailable|0|unknown|no supported initrd or GRUB preparation path was detected|0|1' \
    "auto mode rejects GRUB-only capability without validated direct-generic boot"
expect_probe_case auto-none \
    'unavailable|0|unknown|no supported initrd or GRUB preparation path was detected|0|0' \
    "auto mode remains unavailable when no preparation capability exists"
expect_probe_case enabled-initrd-only \
    'unavailable|0|unknown|GRUB preparation requirements are missing|1|0' \
    "enabled mode preserves strict incomplete-layout semantics"
expect_probe_case disabled-any-layout \
    'disabled|0|unknown|disabled by configuration|0|0' \
    "disabled mode preserves its early non-runnable bypass"

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_step128_implementation=$(sha256sum -- "$step128_implementation" | awk '{print $1}')
before_step128_policy=$(sha256sum -- "$step128_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "source remediation regression review completed successfully"; else fail "source remediation regression review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "regression review did not modify the reference implementation" || fail "regression review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "regression review did not modify the configuration template" || fail "regression review did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "regression review did not modify the frozen mode contract" || fail "regression review did not modify the frozen mode contract"
[[ $(sha256sum -- "$step128_implementation" | awk '{print $1}') == "$before_step128_implementation" ]] && pass "regression review did not modify the step-128 implementation record" || fail "regression review did not modify the step-128 implementation record"
[[ $(sha256sum -- "$step128_policy" | awk '{print $1}') == "$before_step128_policy" ]] && pass "regression review did not modify the step-128 implementation policy" || fail "regression review did not modify the step-128 implementation policy"

check_output schema 1 "regression output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-regression-review "regression output records the expected scenario"
check_output contract_rows_reviewed 15 "regression review covers all 15 frozen contract rows"
check_output inherited_conforming_rows 14 "regression review preserves fourteen previously conforming rows"
check_output remediated_rows_revalidated 1 "regression review revalidates exactly one remediated row"
check_output conforming_rows 15 "regression review records fifteen conforming rows"
check_output discrepancy_rows 0 "regression review records zero remaining discrepancies"
check_output all_rows_conform true "regression review records complete mode-contract conformance"
check_output resolved_discrepancy_id boot-auto-partial-path-availability "regression review resolves the exact historical discrepancy"
check_output behavioral_regression_cases 7 "regression review records all seven behavioral cases"
check_output source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "regression review remains bound to the accepted post-remediation source"
check_output source_change_applied true "regression review preserves the applied source-change state"
check_output authorization_consumed true "regression review preserves the consumed authorization state"
check_output further_source_change_authorized false "no further source change is authorized"
check_output contract_change_authorized false "contract modification remains unauthorized"
check_output configuration_template_change_authorized false "configuration-template modification remains unauthorized"
check_output runtime_behavior_change_reviewed true "regression review explicitly reviews the runtime behavior change"
check_output runtime_behavior_change_in_step129 false "step 129 introduces no new runtime behavior change"
check_output machine_action_required false "regression review requires no machine action"
check_output runtime_machine_validation_still_required true "target runtime validation remains explicitly pending"
check_output slackware_repository_state_dependency false "regression review has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-planning "regression review advances only to runtime-validation planning"
check_output pause_safe true "repository-only regression boundary remains pause-safe"

if grep -Fq '15/15' "$doc" && grep -Fq 'zero open' "$doc" && grep -Fq 'boot-auto-partial-path-availability' "$doc"; then
    pass "regression document records complete repository-level conformance"
else
    fail "regression document records complete repository-level conformance"
fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then
    pass "regression document preserves both mandatory Slackware targets"
else
    fail "regression document preserves both mandatory Slackware targets"
fi
if grep -Fq 'runtime-validation-planning' "$doc" && grep -Fq 'VM' "$doc"; then
    pass "regression document defers machine work to explicit runtime-validation planning"
else
    fail "regression document defers machine work to explicit runtime-validation planning"
fi
if grep -Fq 'further_source_change_authorized=false' "$doc"; then
    pass "regression document preserves the closed source authorization boundary"
else
    fail "regression document preserves the closed source authorization boundary"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "regression-review helper contains no package, boot, or shutdown mutation command"
else
    pass "regression-review helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)' "$helper"; then
    fail "regression-review helper contains no network client command"
else
    pass "regression-review helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
