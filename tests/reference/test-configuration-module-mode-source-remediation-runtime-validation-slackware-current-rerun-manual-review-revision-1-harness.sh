#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
main_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-harness.sh"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-policy.json"
manual_review_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.md"
r1_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-revision-1.md"

expected_main_harness_sha256=21c620597e01e673688f85ef4b116219ca9a611254f423135ffa8983c4d6c1d3
expected_helper_sha256=a90f8443b13efb997dd9026e275dfa5ef3f72340b5ca2991e4f8434b604dcd75
expected_review_sha256=31646232d70ccf97c441636e7b8a7cc5b69817b0aea430cbe1df3b9432c2b978
expected_policy_sha256=b5bf2d88f0f6b0e0b8627f6f1bfa1f37bd8349359d6964be84d6ca3f6068c730
expected_manual_review_doc_sha256=b5d8cd7ef6034dd5b571a849eaf5dd820c9c2ca389bbf830b91c89a20ab1dae5
expected_r1_doc_sha256=a4dc30bad31f86f03069c01d22aa34288457f004b4c9aa1c10f300dd11cafafe

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { [[ -f "$1" && ! -L "$1" ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_hash() { local actual; actual=$(sha256sum -- "$1" 2>/dev/null | awk '{print $1}'); [[ "$actual" == "$2" ]] && pass "$3 has the exact reviewed SHA-256" || fail "$3 has the exact reviewed SHA-256"; }

check_regular "$main_harness" "corrected step-141 manual-review harness"
check_regular "$helper" "step-141 manual-review helper"
check_regular "$review" "step-141 manual-review record"
check_regular "$policy" "step-141 manual-review policy"
check_regular "$manual_review_doc" "step-141 manual-review document"
check_regular "$r1_doc" "step-141 revision-1 document"

check_hash "$main_harness" "$expected_main_harness_sha256" "corrected step-141 manual-review harness"
check_hash "$helper" "$expected_helper_sha256" "step-141 manual-review helper"
check_hash "$review" "$expected_review_sha256" "step-141 manual-review record"
check_hash "$policy" "$expected_policy_sha256" "step-141 manual-review policy"
check_hash "$manual_review_doc" "$expected_manual_review_doc_sha256" "step-141 manual-review document"
check_hash "$r1_doc" "$expected_r1_doc_sha256" "step-141 revision-1 document"

if bash -n "$main_harness"; then pass "corrected step-141 harness is shell-syntax valid"; else fail "corrected step-141 harness is shell-syntax valid"; fi
if bash -n "$0"; then pass "revision-1 harness is shell-syntax valid"; else fail "revision-1 harness is shell-syntax valid"; fi

if python3 - "$main_harness" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
assert 'normalized = " ".join(handle.read().split())' in text
assert 'assert "runtime probe was never invoked" in normalized' in text
assert 'assert "neither exercised nor rejected" in normalized' in text
assert "grep -Fq 'runtime probe was never invoked'" not in text
PY
then
    pass "step-141 prose assertion is whitespace-normalized rather than line-oriented"
else
    fail "step-141 prose assertion is whitespace-normalized rather than line-oriented"
fi

if python3 - "$manual_review_doc" <<'PY'
import sys
normalized = " ".join(open(sys.argv[1], encoding="utf-8").read().split())
assert "runtime probe was never invoked" in normalized
assert "neither exercised nor rejected" in normalized
assert "frozen-boot-selection-mismatch" in normalized
assert "must not be used again" in normalized
assert "Slackware 15.0 remains held" in normalized
PY
then
    pass "unchanged step-141 document satisfies the corrected semantic assertion"
else
    fail "unchanged step-141 document satisfies the corrected semantic assertion"
fi

before_helper=$(sha256sum -- "$helper" | awk '{print $1}')
before_review=$(sha256sum -- "$review" | awk '{print $1}')
before_policy=$(sha256sum -- "$policy" | awk '{print $1}')
before_doc=$(sha256sum -- "$manual_review_doc" | awk '{print $1}')
main_output=$(mktemp)
trap 'rm -f -- "$main_output"' EXIT

if bash "$main_harness" >"$main_output"; then
    cat "$main_output"
    pass "corrected step-141 manual-review harness passes completely"
else
    cat "$main_output"
    fail "corrected step-141 manual-review harness passes completely"
fi

[[ $(sha256sum -- "$helper" | awk '{print $1}') == "$before_helper" ]] && pass "revision-1 verification does not modify the manual-review helper" || fail "revision-1 verification does not modify the manual-review helper"
[[ $(sha256sum -- "$review" | awk '{print $1}') == "$before_review" ]] && pass "revision-1 verification does not modify the manual-review record" || fail "revision-1 verification does not modify the manual-review record"
[[ $(sha256sum -- "$policy" | awk '{print $1}') == "$before_policy" ]] && pass "revision-1 verification does not modify the manual-review policy" || fail "revision-1 verification does not modify the manual-review policy"
[[ $(sha256sum -- "$manual_review_doc" | awk '{print $1}') == "$before_doc" ]] && pass "revision-1 verification does not modify the manual-review document" || fail "revision-1 verification does not modify the manual-review document"

if python3 - "$r1_doc" <<'PY'
import sys
normalized = " ".join(open(sys.argv[1], encoding="utf-8").read().split())
assert "59 passes and one failure" in normalized
assert "line-oriented `grep -F`" in normalized
assert "normalizes Markdown whitespace" in normalized
assert "def71e947186de4e3df4f4af4cddc55f0b41397076e17fbc1b97f13129e58eb8" in normalized
assert "authorizes no source change" in normalized
assert "no machine execution" in normalized
assert "pause_safe=true" in normalized
assert "boot-selection-drift-remediation-design" in normalized
PY
then
    pass "revision-1 document records the assertion defect and preserved authorization boundary"
else
    fail "revision-1 document records the assertion defect and preserved authorization boundary"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
