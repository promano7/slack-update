#!/bin/bash
set -u
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.sh"
main_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-harness.sh"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-revision-1.md"

expected_post_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_pre_sha256=c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
expected_helper_sha256=f7b4ab152ab7944ea9e8922a8895ce40bbf362ab8e997c3c75e79d9cdf77d2be
expected_main_harness_sha256=6c2e74561e80215bda2a66b828b60198064d700338168bbbab15d31500f2ee59
expected_implementation_sha256=685eb5cc28e6d04d96d672a4d51b5856b7ae9fff932949f3baa6f10aab2276d9
expected_policy_sha256=daa03522c27e48f295f6d403636627e5d94f1e4a631f671c955d96f9a0c2e1de

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }

check_regular "$source_file" "post-edit reference implementation"
check_regular "$helper" "corrected step-137 implementation helper"
check_regular "$main_harness" "step-137 implementation harness"
check_regular "$implementation" "step-137 implementation record"
check_regular "$policy" "step-137 implementation policy"
check_regular "$doc" "step-137 revision-1 document"

check_hash "$source_file" "$expected_post_sha256" "post-edit reference implementation"
check_hash "$helper" "$expected_helper_sha256" "corrected step-137 implementation helper"
check_hash "$main_harness" "$expected_main_harness_sha256" "step-137 implementation harness"
check_hash "$implementation" "$expected_implementation_sha256" "step-137 implementation record"
check_hash "$policy" "$expected_policy_sha256" "step-137 implementation policy"

if bash -n "$helper"; then pass "corrected implementation helper is shell-syntax valid"; else fail "corrected implementation helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "corrected implementation helper exposes a non-mutating help boundary"; else fail "corrected implementation helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "corrected implementation helper rejects unknown options"; else pass "corrected implementation helper rejects unknown options"; fi

if python3 - "$source_file" <<'PY'
import re
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    source = handle.read()
state = "    BOOT_DIRECT_GENERIC_BOOT_IMAGE=\n"
assert source.count(state) >= 2
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert classifier is not None
assert classifier.group("body").count(state) == 1
assert "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic" not in classifier.group("body")
PY
then pass "revision identifies the reconstruction landmark only inside the classifier"; else fail "revision identifies the reconstruction landmark only inside the classifier"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
helper_output=$(mktemp)
main_output=$(mktemp)
trap 'rm -f -- "$helper_output" "$main_output"' EXIT

if "$helper" >"$helper_output"; then pass "corrected exact-delta helper completes successfully"; else fail "corrected exact-delta helper completes successfully"; fi
if awk -F '\t' -v v="$expected_pre_sha256" '$1 == "pre_edit_source_sha256" && $2 == v {found=1} END {exit !found}' "$helper_output"; then pass "corrected helper remains bound to the authorized pre-edit identity"; else fail "corrected helper remains bound to the authorized pre-edit identity"; fi
if awk -F '\t' -v v="$expected_post_sha256" '$1 == "post_edit_source_sha256" && $2 == v {found=1} END {exit !found}' "$helper_output"; then pass "corrected helper remains bound to the accepted post-edit identity"; else fail "corrected helper remains bound to the accepted post-edit identity"; fi
if awk -F '\t' '$1 == "exact_delta_reconstruction" && $2 == "true" {found=1} END {exit !found}' "$helper_output"; then pass "corrected helper proves the exact source delta"; else fail "corrected helper proves the exact source delta"; fi
if awk -F '\t' '$1 == "machine_execution_authorized" && $2 == "false" {found=1} END {exit !found}' "$helper_output"; then pass "corrected helper authorizes no machine execution"; else fail "corrected helper authorizes no machine execution"; fi
if awk -F '\t' '$1 == "further_source_change_authorized" && $2 == "false" {found=1} END {exit !found}' "$helper_output"; then pass "corrected helper preserves the consumed source-authorization boundary"; else fail "corrected helper preserves the consumed source-authorization boundary"; fi

if bash "$main_harness" >"$main_output"; then
    cat "$main_output"
    pass "original step-137 implementation harness passes with the corrected helper"
else
    cat "$main_output"
    fail "original step-137 implementation harness passes with the corrected helper"
fi

if [[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]]; then pass "revision-1 verification does not modify the reference implementation"; else fail "revision-1 verification does not modify the reference implementation"; fi
if python3 - "$doc" "$expected_pre_sha256" <<'PYDOC'
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    normalized = " ".join(handle.read().split())

expected_pre_sha256 = sys.argv[2]
assert "verification code, not to the authorized source relocation" in normalized
assert "classifier-local" in normalized
assert expected_pre_sha256 in normalized
assert "No Slackware-current rerun is authorized" in normalized
PYDOC
then
    pass "revision-1 document records the verification defect and preserved authorization boundary"
else
    fail "revision-1 document records the verification defect and preserved authorization boundary"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
