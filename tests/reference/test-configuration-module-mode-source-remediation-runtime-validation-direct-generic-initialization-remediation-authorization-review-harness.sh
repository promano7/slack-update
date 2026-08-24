#!/bin/bash
set -u
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
step134_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
step134_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; fi; }

check_regular "$source_file" "accepted pre-edit reference implementation"
check_regular "$template" "configuration template"
check_regular "$step134_review" "step-134 failure-review record"
check_regular "$step134_policy" "step-134 failure-review policy"
check_regular "$design" "step-135 remediation-design record"
check_regular "$design_policy" "step-135 remediation-design policy"
check_regular "$authorization" "step-136 source-authorization record"
check_regular "$policy" "step-136 authorization-review policy"
check_regular "$helper" "step-136 authorization-review helper"
check_regular "$doc" "step-136 authorization-review document"

check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted pre-edit reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
check_hash "$step134_review" 18380df076d7a264053ffb5aa3bcf85a73cf142feb9adf8adeb64b82b16a3939 "step-134 failure-review record"
check_hash "$step134_policy" 7fd3da927af6223b97f7669defe32530af1aae9028af57da1fb1b4b39464e8c4 "step-134 failure-review policy"
check_hash "$design" 92f32e694de60beefea4066a33bd12bdc55ad787e7d24da65ee8fa5f30c62ee2 "step-135 remediation-design record"
check_hash "$design_policy" ea809c4c9e7c1fa46d812d7a778969c9b6b441821a306553e4f6bfff167c2c7b "step-135 remediation-design policy"

if bash -n "$helper"; then pass "authorization-review helper is shell-syntax valid"; else fail "authorization-review helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "authorization-review helper exposes a non-mutating help boundary"; else fail "authorization-review helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "authorization-review helper rejects unknown options"; else pass "authorization-review helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "authorization-review policy is valid JSON"; else fail "authorization-review policy is valid JSON"; fi

if python3 - "$authorization" "$policy" <<'PY'
import csv
import json
import sys
with open(sys.argv[1], encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(sys.argv[2], encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
authorized = policy["authorized_source_change"]
assert row["design_id"] == authorized["design_id"]
assert row["authorization_scope"] == authorized["scope"]
assert row["authorized_edit"] == authorized["authorized_edit"]
assert row["assignment"] == authorized["assignment"]
assert row["remove_from_function"] == authorized["remove_from_function"]
assert row["insert_after_exact_anchor"] == authorized["insert_after_exact_anchor"]
assert row["source_change_authorized"] == "true"
assert row["machine_execution_authorized"] == "false"
assert policy["source_change_authorized"] is True
assert policy["source_change_applied"] is False
assert policy["machine_execution_authorized"] is False
PY
then pass "authorization TSV and policy are internally consistent"; else fail "authorization TSV and policy are internally consistent"; fi

if python3 - "$source_file" <<'PY'
import re
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    source = handle.read()
assignment = "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic"
anchor = "GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot"
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert source.count(assignment) == 1
assert source.count(anchor) == 1
assert classifier is not None and assignment in classifier.group("body")
assert probe is not None and '"$GENERIC_KERNEL_LINK"' in probe.group("body")
assert "classify_direct_generic_boot_layout" in probe.group("body")
assert source.index(anchor) < source.index("classify_direct_generic_boot_layout() {")
PY
then pass "pre-edit source still has the exact step-135 initialization defect shape"; else fail "pre-edit source still has the exact step-135 initialization defect shape"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_review=$(sha256sum -- "$step134_review" | awk '{print $1}')
before_step134=$(sha256sum -- "$step134_policy" | awk '{print $1}')
before_design=$(sha256sum -- "$design" | awk '{print $1}')
before_design_policy=$(sha256sum -- "$design_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "direct-generic initialization remediation authorization review completed successfully"; else fail "direct-generic initialization remediation authorization review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "authorization review did not modify the reference implementation" || fail "authorization review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "authorization review did not modify the configuration template" || fail "authorization review did not modify the configuration template"
[[ $(sha256sum -- "$step134_review" | awk '{print $1}') == "$before_review" ]] && pass "authorization review did not modify the accepted step-134 review record" || fail "authorization review did not modify the accepted step-134 review record"
[[ $(sha256sum -- "$step134_policy" | awk '{print $1}') == "$before_step134" ]] && pass "authorization review did not modify the accepted step-134 review policy" || fail "authorization review did not modify the accepted step-134 review policy"
[[ $(sha256sum -- "$design" | awk '{print $1}') == "$before_design" ]] && pass "authorization review did not modify the step-135 design" || fail "authorization review did not modify the step-135 design"
[[ $(sha256sum -- "$design_policy" | awk '{print $1}') == "$before_design_policy" ]] && pass "authorization review did not modify the step-135 design policy" || fail "authorization review did not modify the step-135 design policy"

check_output schema 1 "authorization output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review "authorization output records the expected scenario"
check_output accepted_source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "authorization is bound to the exact pre-edit source identity"
check_output step135_design_sha256 92f32e694de60beefea4066a33bd12bdc55ad787e7d24da65ee8fa5f30c62ee2 "authorization is bound to the exact step-135 design"
check_output step135_design_policy_sha256 ea809c4c9e7c1fa46d812d7a778969c9b6b441821a306553e4f6bfff167c2c7b "authorization is bound to the exact step-135 design policy"
check_output design_id direct-generic-initialization-remediation "authorization remains bound to the direct-generic initialization remediation"
check_output failure_variable GENERIC_KERNEL_LINK "authorization remains bound to the failing variable"
check_output authorization_scope direct-generic-generic-kernel-link-initialization-only "authorization preserves the frozen source scope"
check_output authorized_edit relocate-existing-assignment-before-first-use "authorization permits only the designed assignment relocation"
check_output assignment GENERIC_KERNEL_LINK=/boot/vmlinuz-generic "authorization preserves the exact assignment"
check_output remove_from_function classify_direct_generic_boot_layout "authorization permits removal only from the classifier"
check_output insert_after_exact_anchor GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot "authorization freezes the exact insertion anchor"
check_output preserve_assignment_count 1 "authorization preserves exactly one assignment"
check_output preserve_assignment_value true "authorization preserves the generic-kernel path value"
check_output preserve_variable_mutability true "authorization preserves variable mutability"
check_output function_signature_change_authorized false "function-signature changes remain unauthorized"
check_output boot_semantics_change_authorized false "boot semantic changes remain unauthorized"
check_output configuration_template_change_authorized false "configuration-template modification remains unauthorized"
check_output contract_change_authorized false "contract modification remains unauthorized"
check_output source_change_applied false "authorization review itself applies no source change"
check_output source_change_authorized true "authorization review grants the narrow source relocation"
check_output machine_execution_authorized false "authorization grants no machine execution"
check_output slackware_current_rerun_authorized false "consumed Slackware-current authorization remains non-reusable"
check_output slackware_15_execution_released false "Slackware 15.0 remains held"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "authorization is independent of Slackware publication state"
check_output machine_action_required false "authorization requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation "authorization advances only to repository-local implementation"
check_output pause_safe true "repository-only authorization boundary remains pause-safe"

if grep -Fq 'consumable only' "$doc" && grep -Fq 'Any pre-edit source SHA-256 mismatch makes this authorization invalid' "$doc" && grep -Fq 'single-use' "$doc"; then
    pass "authorization document binds single-use consumption to the accepted source identity"
else
    fail "authorization document binds single-use consumption to the accepted source identity"
fi
if grep -Fq 'does not apply the relocation' "$doc" && grep -Fq 'source_change_applied=false' "$doc"; then
    pass "authorization document preserves the review-only boundary"
else
    fail "authorization document preserves the review-only boundary"
fi
if grep -Fq 'Slackware 15.0 remains held' "$doc" && grep -Fq 'No Slackware-current rerun is authorized' "$doc"; then
    pass "authorization document preserves both machine hold boundaries"
else
    fail "authorization document preserves both machine hold boundaries"
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
