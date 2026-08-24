#!/bin/bash
set -u
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.sh"
main_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-harness.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json"
main_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.md"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-revision-1.md"

expected_source_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_helper_sha256=791199d3f3967e87a610aed86bcaf62ef48e1d78f8941e398e0a962261066f97
expected_main_harness_sha256=bc405b5fbbe7c5d9f952a5c6b1b94b120be03ced0f30940e861c0029a98d6727
expected_review_sha256=18de033bdde24bf7c1072314cded46e134cee06aac8434f47f3318e97995d30d
expected_policy_sha256=43c7b538d06e142180aa343bc743ab11c341e71a4ace6ea0909efac1be90f4ac
expected_main_doc_sha256=45045f1cd53b78558b0e703927b1f7ab97d472983061003b2dc5009e5affa98e
expected_doc_sha256=9b5cd6144b214af0df2c3f3bac1d80dbc0d04a404cafc71c4f3501adaca897ed

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }

check_regular "$source_file" "post-remediation reference implementation"
check_regular "$helper" "corrected step-138 regression-review helper"
check_regular "$main_harness" "step-138 regression-review harness"
check_regular "$review" "step-138 regression-review record"
check_regular "$policy" "step-138 regression-review policy"
check_regular "$main_doc" "step-138 regression-review document"
check_regular "$doc" "step-138 revision-1 document"

check_hash "$source_file" "$expected_source_sha256" "post-remediation reference implementation"
check_hash "$helper" "$expected_helper_sha256" "corrected step-138 regression-review helper"
check_hash "$main_harness" "$expected_main_harness_sha256" "step-138 regression-review harness"
check_hash "$review" "$expected_review_sha256" "step-138 regression-review record"
check_hash "$policy" "$expected_policy_sha256" "step-138 regression-review policy"
check_hash "$main_doc" "$expected_main_doc_sha256" "step-138 regression-review document"
check_hash "$doc" "$expected_doc_sha256" "step-138 revision-1 document"

if bash -n "$helper"; then pass "corrected regression-review helper is shell-syntax valid"; else fail "corrected regression-review helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "corrected regression-review helper exposes a non-mutating help boundary"; else fail "corrected regression-review helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "corrected regression-review helper rejects unknown options"; else pass "corrected regression-review helper rejects unknown options"; fi

if python3 - "$helper" <<'PY' >/dev/null 2>&1
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'import os\n' in text
assert 'fixture_env = os.environ.copy()' in text
assert 'fixture_env["LC_ALL"] = "C"' in text
assert 'fixture_env["LANG"] = "C"' in text
assert text.count('env=fixture_env') == 2
assert '"GENERIC_KERNEL_LINK" not in historical.stderr or "unbound variable" not in historical.stderr' in text
PY
then pass "revision forces deterministic C locale for both executable fixtures"; else fail "revision forces deterministic C locale for both executable fixtures"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_review=$(sha256sum -- "$review" | awk '{print $1}')
before_policy=$(sha256sum -- "$policy" | awk '{print $1}')
helper_output=$(mktemp)
main_output=$(mktemp)
trap 'rm -f -- "$helper_output" "$main_output"' EXIT

if "$helper" >"$helper_output"; then pass "corrected step-138 regression helper completes successfully"; else fail "corrected step-138 regression helper completes successfully"; fi
if grep -Fxq $'historical_unset_fixture_detected\ttrue' "$helper_output"; then pass "locale-stable historical fixture detects the reviewed unset variable"; else fail "locale-stable historical fixture detects the reviewed unset variable"; fi
if grep -Fxq $'remediated_probe_fixture_passed\ttrue' "$helper_output"; then pass "remediated probe fixture still passes under set -u"; else fail "remediated probe fixture still passes under set -u"; fi
if grep -Fxq $'generic_link_argument_preserved\ttrue' "$helper_output"; then pass "remediated fixture still preserves the generic-kernel link argument"; else fail "remediated fixture still preserves the generic-kernel link argument"; fi
if grep -Fxq $'machine_execution_authorized\tfalse' "$helper_output"; then pass "corrected regression helper authorizes no machine execution"; else fail "corrected regression helper authorizes no machine execution"; fi
if grep -Fxq $'slackware_current_rerun_authorized\tfalse' "$helper_output"; then pass "Slackware-current rerun remains unauthorized"; else fail "Slackware-current rerun remains unauthorized"; fi

if bash "$main_harness" >"$main_output"; then
    cat "$main_output"
    pass "original step-138 regression-review harness passes with the locale-stable helper"
else
    cat "$main_output"
    fail "original step-138 regression-review harness passes with the locale-stable helper"
fi

if [[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]]; then pass "revision-1 verification does not modify the reference implementation"; else fail "revision-1 verification does not modify the reference implementation"; fi
if [[ $(sha256sum -- "$review" | awk '{print $1}') == "$before_review" ]]; then pass "revision-1 verification does not modify the regression record"; else fail "revision-1 verification does not modify the regression record"; fi
if [[ $(sha256sum -- "$policy" | awk '{print $1}') == "$before_policy" ]]; then pass "revision-1 verification does not modify the regression policy"; else fail "revision-1 verification does not modify the regression policy"; fi

if python3 - "$doc" <<'PY' >/dev/null 2>&1
import re
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
normalized = re.sub(r"\s+", " ", text)
assert "locale-sensitive" in normalized
assert "LC_ALL=C" in normalized
assert "LANG=C" in normalized
assert "No Slackware-current rerun is authorized" in normalized
assert "step-136 source authorization remains consumed and non-reusable" in normalized
PY
then pass "revision-1 document records the locale defect and preserved authorization boundary"; else fail "revision-1 document records the locale defect and preserved authorization boundary"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
