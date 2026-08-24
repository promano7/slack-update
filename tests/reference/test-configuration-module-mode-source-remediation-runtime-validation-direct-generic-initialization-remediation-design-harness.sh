#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
step134_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
step134_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; fi; }

check_regular "$source_file" "accepted reference implementation"
check_regular "$template" "configuration template"
check_regular "$step134_review" "step-134 failure-review record"
check_regular "$step134_policy" "step-134 failure-review policy"
check_regular "$design" "step-135 remediation-design record"
check_regular "$policy" "step-135 remediation-design policy"
check_regular "$helper" "step-135 remediation-design helper"
check_regular "$doc" "step-135 remediation-design document"
check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
check_hash "$step134_review" 18380df076d7a264053ffb5aa3bcf85a73cf142feb9adf8adeb64b82b16a3939 "step-134 failure-review record"
check_hash "$step134_policy" 7fd3da927af6223b97f7669defe32530af1aae9028af57da1fb1b4b39464e8c4 "step-134 failure-review policy"

if bash -n "$helper"; then pass "remediation-design helper is shell-syntax valid"; else fail "remediation-design helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "remediation-design helper exposes a non-mutating help boundary"; else fail "remediation-design helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "remediation-design helper rejects unknown options"; else pass "remediation-design helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "remediation-design policy is valid JSON"; else fail "remediation-design policy is valid JSON"; fi

if python3 - "$source_file" "$design" "$policy" <<'PY'
import csv
import json
import re
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    source = handle.read()
with open(sys.argv[2], encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(sys.argv[3], encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
assignment = "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic"
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert source.count(assignment) == 1
assert classifier is not None and assignment in classifier.group("body")
assert probe is not None and '"$GENERIC_KERNEL_LINK"' in probe.group("body")
assert row["edit_strategy"] == policy["designed_remediation"]["edit_strategy"]
assert row["source_change_authorized"] == "false"
assert row["machine_execution_authorized"] == "false"
assert policy["source_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
PY
then pass "design is internally consistent with the accepted pre-remediation source"; else fail "design is internally consistent with the accepted pre-remediation source"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_review=$(sha256sum -- "$step134_review" | awk '{print $1}')
before_step134=$(sha256sum -- "$step134_policy" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "direct-generic initialization remediation design completed successfully"; else fail "direct-generic initialization remediation design completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "design did not modify the reference implementation" || fail "design did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "design did not modify the configuration template" || fail "design did not modify the configuration template"
[[ $(sha256sum -- "$step134_review" | awk '{print $1}') == "$before_review" ]] && pass "design did not modify the accepted step-134 review record" || fail "design did not modify the accepted step-134 review record"
[[ $(sha256sum -- "$step134_policy" | awk '{print $1}') == "$before_step134" ]] && pass "design did not modify the accepted step-134 review policy" || fail "design did not modify the accepted step-134 review policy"

check_output schema 1 "design output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design "design output records the expected scenario"
check_output accepted_source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "design remains bound to the accepted pre-remediation source"
check_output failure_variable GENERIC_KERNEL_LINK "design remains bound to the exact failing variable"
check_output failure_function probe_direct_generic_boot_layout "design remains bound to the exact failing function"
check_output current_assignment_scope classify_direct_generic_boot_layout "design freezes the current late assignment scope"
check_output planned_assignment_scope global-boot-path-initialization-boundary "design freezes the earlier initialization scope"
check_output edit_strategy relocate-existing-assignment-before-first-use "design chooses relocation rather than a semantic rewrite"
check_output assignment_value_change false "the generic-kernel path value is preserved"
check_output function_signature_change false "direct-generic function signatures are preserved"
check_output boot_semantics_change false "boot-layout semantics are preserved"
check_output configuration_template_change false "configuration template remains untouched"
check_output contract_change false "optional-module contract remains untouched"
check_output source_change_authorized false "design does not authorize the source edit"
check_output machine_execution_authorized false "design authorizes no machine execution"
check_output slackware_current_rerun_authorized false "consumed current authorization remains non-reusable"
check_output slackware_15_execution_released false "Slackware 15.0 remains held"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "design is independent of Slackware publication state"
check_output machine_action_required false "design requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review "design advances only to separate source authorization review"
check_output pause_safe true "repository-only design boundary remains pause-safe"

if grep -Fq 'GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot' "$doc" \
    && grep -Fq 'GENERIC_KERNEL_LINK=/boot/vmlinuz-generic' "$doc" \
    && grep -Fq 'relocation-only' "$doc"; then
    pass "design document records the exact relocation boundary"
else
    fail "design document records the exact relocation boundary"
fi
if grep -Fq 'does **not** authorize the source relocation' "$doc" \
    && grep -Fq 'Slackware 15.0 remains held' "$doc"; then
    pass "design document preserves source and machine authorization boundaries"
else
    fail "design document preserves source and machine authorization boundaries"
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
