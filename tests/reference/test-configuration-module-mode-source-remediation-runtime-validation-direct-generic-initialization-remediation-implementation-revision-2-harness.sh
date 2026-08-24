#!/bin/bash
set -u
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.sh"
r1_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-revision-1-harness.sh"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-policy.json"
r1_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-revision-1.md"
r2_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-revision-2.md"

expected_post_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_pre_sha256=c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
expected_helper_sha256=f7b4ab152ab7944ea9e8922a8895ce40bbf362ab8e997c3c75e79d9cdf77d2be
expected_r1_harness_sha256=7e4fa76a04f60ad3906763c8b4fde71b0997e14eec51b9668e464d1c71f10418
expected_implementation_sha256=685eb5cc28e6d04d96d672a4d51b5856b7ae9fff932949f3baa6f10aab2276d9
expected_policy_sha256=daa03522c27e48f295f6d403636627e5d94f1e4a631f671c955d96f9a0c2e1de
expected_r1_doc_sha256=dffd02deb53032a06ead9578f0bddd30f257134a3b857c882635353ff2291243

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }

check_regular "$source_file" "post-edit reference implementation"
check_regular "$helper" "corrected step-137 implementation helper"
check_regular "$r1_harness" "corrected revision-1 harness"
check_regular "$implementation" "step-137 implementation record"
check_regular "$policy" "step-137 implementation policy"
check_regular "$r1_doc" "step-137 revision-1 document"
check_regular "$r2_doc" "step-137 revision-2 document"

check_hash "$source_file" "$expected_post_sha256" "post-edit reference implementation"
check_hash "$helper" "$expected_helper_sha256" "corrected step-137 implementation helper"
check_hash "$r1_harness" "$expected_r1_harness_sha256" "corrected revision-1 harness"
check_hash "$implementation" "$expected_implementation_sha256" "step-137 implementation record"
check_hash "$policy" "$expected_policy_sha256" "step-137 implementation policy"
check_hash "$r1_doc" "$expected_r1_doc_sha256" "step-137 revision-1 document"

if bash -n "$r1_harness"; then pass "corrected revision-1 harness is shell-syntax valid"; else fail "corrected revision-1 harness is shell-syntax valid"; fi

if python3 - "$r1_harness" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
assert 'normalized = " ".join(handle.read().split())' in text
assert 'verification code, not to the authorized source relocation' in text
assert "grep -Fq 'verification code, not to the'" not in text
PY
then pass "revision-1 document assertion is whitespace-normalized rather than line-oriented"; else fail "revision-1 document assertion is whitespace-normalized rather than line-oriented"; fi

if python3 - "$r1_doc" "$expected_pre_sha256" <<'PY'
import sys
normalized = " ".join(open(sys.argv[1], encoding="utf-8").read().split())
assert "verification code, not to the authorized source relocation" in normalized
assert "classifier-local" in normalized
assert sys.argv[2] in normalized
assert "No Slackware-current rerun is authorized" in normalized
PY
then pass "revision-1 document satisfies the corrected semantic assertion"; else fail "revision-1 document satisfies the corrected semantic assertion"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_helper=$(sha256sum -- "$helper" | awk '{print $1}')
before_record=$(sha256sum -- "$implementation" | awk '{print $1}')
before_policy=$(sha256sum -- "$policy" | awk '{print $1}')
r1_output=$(mktemp)
trap 'rm -f -- "$r1_output"' EXIT

if bash "$r1_harness" >"$r1_output"; then
    cat "$r1_output"
    pass "corrected revision-1 harness passes completely"
else
    cat "$r1_output"
    fail "corrected revision-1 harness passes completely"
fi

if [[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]]; then pass "revision-2 verification does not modify the reference implementation"; else fail "revision-2 verification does not modify the reference implementation"; fi
if [[ $(sha256sum -- "$helper" | awk '{print $1}') == "$before_helper" ]]; then pass "revision-2 verification does not modify the corrected helper"; else fail "revision-2 verification does not modify the corrected helper"; fi
if [[ $(sha256sum -- "$implementation" | awk '{print $1}') == "$before_record" ]]; then pass "revision-2 verification does not modify the implementation record"; else fail "revision-2 verification does not modify the implementation record"; fi
if [[ $(sha256sum -- "$policy" | awk '{print $1}') == "$before_policy" ]]; then pass "revision-2 verification does not modify the implementation policy"; else fail "revision-2 verification does not modify the implementation policy"; fi

if python3 - "$r2_doc" "$expected_post_sha256" "$expected_pre_sha256" <<'PY'
import sys
normalized = " ".join(open(sys.argv[1], encoding="utf-8").read().split())
assert "line-oriented assertion failed" in normalized
assert "normalizes Markdown whitespace" in normalized
assert sys.argv[2] in normalized
assert sys.argv[3] in normalized
assert "authorization remains consumed and non-reusable" in normalized
assert "authorizes no source change and no machine execution" in normalized
PY
then pass "revision-2 document records the assertion defect and preserved authorization boundary"; else fail "revision-2 document records the assertion defect and preserved authorization boundary"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
