#!/bin/bash
set -u
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step134_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
step134_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization.tsv"
authorization_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review-policy.json"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; fi; }

check_regular "$source_file" "post-edit reference implementation"
check_regular "$template" "configuration template"
check_regular "$contract" "optional-module contract"
check_regular "$step134_review" "step-134 failure-review record"
check_regular "$step134_policy" "step-134 failure-review policy"
check_regular "$design" "step-135 remediation-design record"
check_regular "$design_policy" "step-135 remediation-design policy"
check_regular "$authorization" "step-136 source-authorization record"
check_regular "$authorization_policy" "step-136 authorization-review policy"
check_regular "$implementation" "step-137 implementation record"
check_regular "$policy" "step-137 implementation policy"
check_regular "$helper" "step-137 implementation helper"
check_regular "$doc" "step-137 implementation document"

check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "optional-module contract"
check_hash "$step134_review" 18380df076d7a264053ffb5aa3bcf85a73cf142feb9adf8adeb64b82b16a3939 "step-134 failure-review record"
check_hash "$step134_policy" 7fd3da927af6223b97f7669defe32530af1aae9028af57da1fb1b4b39464e8c4 "step-134 failure-review policy"
check_hash "$design" 92f32e694de60beefea4066a33bd12bdc55ad787e7d24da65ee8fa5f30c62ee2 "step-135 remediation-design record"
check_hash "$design_policy" ea809c4c9e7c1fa46d812d7a778969c9b6b441821a306553e4f6bfff167c2c7b "step-135 remediation-design policy"
check_hash "$authorization" ff601285a6b81e8a7b6a005bdd451f08e499cb3590b61c2ed15647c001b1ebb5 "step-136 source-authorization record"
check_hash "$authorization_policy" c9edf1e77034e469dcfd074e0e8b82e27e3e839503929c9fa1bbf184bb8a13ea "step-136 authorization-review policy"

if bash -n "$source_file"; then pass "post-edit reference implementation is shell-syntax valid"; else fail "post-edit reference implementation is shell-syntax valid"; fi
if bash -n "$helper"; then pass "implementation helper is shell-syntax valid"; else fail "implementation helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "implementation helper exposes a non-mutating help boundary"; else fail "implementation helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "implementation helper rejects unknown options"; else pass "implementation helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "implementation policy is valid JSON"; else fail "implementation policy is valid JSON"; fi

post_sha256=$(awk -F '\t' 'NR == 2 {print $7}' "$implementation")
if [[ "$post_sha256" =~ ^[0-9a-f]{64}$ ]]; then pass "implementation record contains a valid post-edit SHA-256"; else fail "implementation record contains a valid post-edit SHA-256"; fi
if [[ $(sha256sum -- "$source_file" 2>/dev/null | awk '{print $1}') == "$post_sha256" ]]; then pass "post-edit reference implementation matches the recorded SHA-256"; else fail "post-edit reference implementation matches the recorded SHA-256"; fi
if [[ "$post_sha256" != c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c ]]; then pass "post-edit reference implementation differs from the authorized pre-edit identity"; else fail "post-edit reference implementation differs from the authorized pre-edit identity"; fi

if python3 - "$implementation" "$policy" "$authorization" "$authorization_policy" <<'PY'
import csv
import json
import sys
implementation_path, policy_path, authorization_path, authorization_policy_path = sys.argv[1:]
with open(implementation_path, encoding="utf-8", newline="") as handle:
    implementation_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
with open(authorization_path, encoding="utf-8", newline="") as handle:
    authorization_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(authorization_policy_path, encoding="utf-8") as handle:
    authorization_policy = json.load(handle)
assert len(implementation_rows) == len(authorization_rows) == 1
row = implementation_rows[0]
auth = authorization_rows[0]
assert row["design_id"] == auth["design_id"]
assert row["function"] == auth["function"]
assert row["variable"] == auth["variable"]
assert row["authorization_scope"] == auth["authorization_scope"]
assert row["authorized_edit"] == auth["authorized_edit"]
assert row["assignment"] == auth["assignment"]
assert row["remove_from_function"] == auth["remove_from_function"]
assert row["insert_after_exact_anchor"] == auth["insert_after_exact_anchor"]
assert row["pre_edit_source_sha256"] == authorization_policy["accepted_source_sha256"]
assert row["post_edit_source_sha256"] == policy["post_edit_source_sha256"]
assert row["source_change_applied"] == "true"
assert row["authorization_consumed"] == "true"
assert row["further_source_change_authorized"] == "false"
assert row["machine_execution_authorized"] == "false"
assert policy["accepted_step136_scenario"] == authorization_policy["scenario"]
assert policy["source_change_applied"] is True
assert policy["authorization_consumed"] is True
assert policy["further_source_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
PY
then pass "implementation records consume exactly the step-136 authorization"; else fail "implementation records consume exactly the step-136 authorization"; fi

if python3 - "$source_file" <<'PY'
import re
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    source = handle.read()
assignment = "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic"
anchor = "GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot"
assert source.count(assignment) == 1
assert source.count(anchor) == 1
assert anchor + "\n" + assignment in source
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert classifier is not None and probe is not None
assert assignment not in classifier.group("body")
assert "local generic_link=$4" in classifier.group("body")
assert '"$GENERIC_KERNEL_LINK"' in probe.group("body")
assert "classify_direct_generic_boot_layout" in probe.group("body")
assert source.index(anchor) < source.index("classify_direct_generic_boot_layout() {") < source.index("probe_direct_generic_boot_layout() {")
PY
then pass "post-edit source has the exact authorized initialization shape"; else fail "post-edit source has the exact authorized initialization shape"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_review=$(sha256sum -- "$step134_review" | awk '{print $1}')
before_design=$(sha256sum -- "$design" | awk '{print $1}')
before_authorization=$(sha256sum -- "$authorization" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "direct-generic initialization remediation implementation completed successfully"; else fail "direct-generic initialization remediation implementation completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "implementation helper did not further modify the reference implementation" || fail "implementation helper did not further modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "implementation did not modify the configuration template" || fail "implementation did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "implementation did not modify the optional-module contract" || fail "implementation did not modify the optional-module contract"
[[ $(sha256sum -- "$step134_review" | awk '{print $1}') == "$before_review" ]] && pass "implementation preserved the accepted step-134 failure review" || fail "implementation preserved the accepted step-134 failure review"
[[ $(sha256sum -- "$design" | awk '{print $1}') == "$before_design" ]] && pass "implementation preserved the accepted step-135 design" || fail "implementation preserved the accepted step-135 design"
[[ $(sha256sum -- "$authorization" | awk '{print $1}') == "$before_authorization" ]] && pass "implementation preserved the consumed step-136 authorization record" || fail "implementation preserved the consumed step-136 authorization record"

check_output schema 1 "implementation output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation "implementation output records the expected scenario"
check_output design_id direct-generic-initialization-remediation "implementation remains bound to the accepted design"
check_output failure_variable GENERIC_KERNEL_LINK "implementation remains bound to the failing variable"
check_output authorization_scope direct-generic-generic-kernel-link-initialization-only "implementation preserves the authorized source scope"
check_output authorized_edit relocate-existing-assignment-before-first-use "implementation applies only the authorized relocation"
check_output pre_edit_source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "implementation remains bound to the authorized pre-edit source identity"
check_output post_edit_source_sha256 "$post_sha256" "implementation reports the recorded post-edit source identity"
check_output assignment GENERIC_KERNEL_LINK=/boot/vmlinuz-generic "implementation preserves the exact assignment"
check_output remove_from_function classify_direct_generic_boot_layout "implementation removes the assignment only from the classifier"
check_output insert_after_exact_anchor GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot "implementation inserts only after the frozen anchor"
check_output assignment_count 1 "implementation preserves exactly one assignment"
check_output assignment_value_preserved true "implementation preserves the assignment value"
check_output variable_mutability_preserved true "implementation preserves variable mutability"
check_output function_signature_change false "implementation changes no function signature"
check_output boot_semantics_change false "implementation changes no boot-layout semantics"
check_output configuration_template_change false "implementation changes no configuration-template bytes"
check_output contract_change false "implementation changes no optional-module contract"
check_output exact_delta_reconstruction true "implementation proves the exact source delta by reconstruction"
check_output source_change_applied true "implementation records that the source change was applied"
check_output authorization_consumed true "implementation consumes the single-use authorization"
check_output further_source_change_authorized false "implementation authorizes no further source edit"
check_output machine_execution_authorized false "implementation authorizes no machine execution"
check_output slackware_current_rerun_authorized false "Slackware-current rerun remains unauthorized"
check_output slackware_15_execution_released false "Slackware 15.0 remains held"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "implementation is independent of Slackware publication state"
check_output machine_action_required false "implementation requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review "implementation advances only to repository-local regression review"
check_output pause_safe true "repository-only implementation boundary remains pause-safe"

if grep -Fq 'reconstructs the authorized pre-edit image' "$doc" && grep -Fq 'only source delta' "$doc" && grep -Fq 'c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c' "$doc"; then
    pass "implementation document records the exact-delta proof"
else
    fail "implementation document records the exact-delta proof"
fi
if grep -Fq 'authorization_consumed=true' "$doc" && grep -Fq 'further_source_change_authorized=false' "$doc"; then
    pass "implementation document closes the consumed source authorization"
else
    fail "implementation document closes the consumed source authorization"
fi
if grep -Fq 'No Slackware-current rerun is authorized' "$doc" && grep -Fq 'Slackware 15.0 remains held' "$doc"; then
    pass "implementation document preserves both machine hold boundaries"
else
    fail "implementation document preserves both machine hold boundaries"
fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "implementation helper contains no package, boot, or shutdown mutation command"
else
    pass "implementation helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "implementation helper contains no network client command"
else
    pass "implementation helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
