#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.tsv"
implementation_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-policy.json"
implementation_helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.sh"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { [[ -f "$1" && ! -L "$1" ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_sha() { local actual; actual=$(sha256sum -- "$1" 2>/dev/null | awk '{print $1}'); [[ "$actual" == "$2" ]] && pass "$3 has the exact reviewed SHA-256" || fail "$3 has the exact reviewed SHA-256"; }
check_output() { local k=$1 v=$2 label=$3; grep -Fxq -- "$k"$'\t'"$v" "$output" && pass "$label" || fail "$label"; }

for entry in \
    "$source_file|post-remediation reference implementation" \
    "$template|configuration template" \
    "$contract|optional-module contract" \
    "$implementation|step-137 implementation record" \
    "$implementation_policy|step-137 implementation policy" \
    "$implementation_helper|corrected step-137 implementation helper" \
    "$review|step-138 regression-review record" \
    "$policy|step-138 regression-review policy" \
    "$helper|step-138 regression-review helper" \
    "$doc|step-138 regression-review document"; do
    check_regular "${entry%%|*}" "${entry#*|}"
done

check_sha "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "post-remediation reference implementation"
check_sha "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_sha "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "optional-module contract"
check_sha "$implementation" 685eb5cc28e6d04d96d672a4d51b5856b7ae9fff932949f3baa6f10aab2276d9 "step-137 implementation record"
check_sha "$implementation_policy" daa03522c27e48f295f6d403636627e5d94f1e4a631f671c955d96f9a0c2e1de "step-137 implementation policy"
check_sha "$implementation_helper" f7b4ab152ab7944ea9e8922a8895ce40bbf362ab8e997c3c75e79d9cdf77d2be "corrected step-137 implementation helper"

bash -n "$source_file" && pass "post-remediation reference implementation is shell-syntax valid" || fail "post-remediation reference implementation is shell-syntax valid"
bash -n "$helper" && pass "regression-review helper is shell-syntax valid" || fail "regression-review helper is shell-syntax valid"
"$helper" --help >/dev/null 2>&1 && pass "regression-review helper exposes a non-mutating help boundary" || fail "regression-review helper exposes a non-mutating help boundary"
if "$helper" --not-an-option >/dev/null 2>&1; then fail "regression-review helper rejects unknown options"; else pass "regression-review helper rejects unknown options"; fi
python3 -m json.tool "$policy" >/dev/null 2>&1 && pass "regression-review policy is valid JSON" || fail "regression-review policy is valid JSON"

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
before_impl=$(sha256sum -- "$implementation" | awk '{print $1}')
before_impl_policy=$(sha256sum -- "$implementation_policy" | awk '{print $1}')
before_impl_helper=$(sha256sum -- "$implementation_helper" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "direct-generic initialization remediation regression review completed successfully"; else fail "direct-generic initialization remediation regression review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "regression review did not modify the reference implementation" || fail "regression review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "regression review did not modify the configuration template" || fail "regression review did not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "regression review did not modify the optional-module contract" || fail "regression review did not modify the optional-module contract"
[[ $(sha256sum -- "$implementation" | awk '{print $1}') == "$before_impl" ]] && pass "regression review did not modify the step-137 implementation record" || fail "regression review did not modify the step-137 implementation record"
[[ $(sha256sum -- "$implementation_policy" | awk '{print $1}') == "$before_impl_policy" ]] && pass "regression review did not modify the step-137 implementation policy" || fail "regression review did not modify the step-137 implementation policy"
[[ $(sha256sum -- "$implementation_helper" | awk '{print $1}') == "$before_impl_helper" ]] && pass "regression review did not modify the corrected step-137 helper" || fail "regression review did not modify the corrected step-137 helper"

check_output schema 1 "regression output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review "regression output records the expected scenario"
check_output source_sha256 aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "regression review remains bound to the accepted post-remediation source"
check_output exact_delta_revalidated true "regression review revalidates the exact source delta"
check_output source_shell_syntax true "regression review records source shell syntax validity"
check_output historical_unset_fixture_detected true "regression detects the historical unset-variable defect"
check_output remediated_probe_fixture_passed true "remediated probe fixture passes under set -u"
check_output generic_link_argument_preserved true "probe passes the generic-kernel link argument unchanged"
check_output configuration_template_unchanged true "configuration template remains unchanged"
check_output optional_module_contract_unchanged true "optional-module contract remains unchanged"
check_output authorization_consumed true "source authorization remains consumed"
check_output further_source_change_authorized false "no further source edit is authorized"
check_output machine_execution_authorized false "regression review grants no machine execution"
check_output slackware_current_rerun_authorized false "Slackware-current rerun remains unauthorized"
check_output slackware_15_execution_released false "Slackware 15.0 remains held"
check_output runtime_machine_validation_still_required true "runtime machine validation remains pending"
check_output repository_refresh_required false "no Slackware repository refresh is required"
check_output slackware_repository_state_dependency false "regression review is independent of Slackware publication state"
check_output machine_action_required false "regression review requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review "regression review advances only to rerun authorization review"
check_output pause_safe true "repository-only regression boundary remains pause-safe"

if python3 - "$review" "$policy" <<'PY' >/dev/null 2>&1
import csv, json, sys
with open(sys.argv[1], encoding='utf-8', newline='') as h: rows=list(csv.DictReader(h, delimiter='\t'))
with open(sys.argv[2], encoding='utf-8') as h: p=json.load(h)
assert len(rows)==1 and rows[0]['scenario']==p['scenario']
assert rows[0]['source_sha256']==p['source_sha256']
assert p['regression_boundary']['historical_unset_fixture_must_fail'] is True
assert p['regression_boundary']['remediated_probe_fixture_must_pass_under_set_u'] is True
assert p['machine_execution_authorized'] is False
assert p['pause_safe'] is True
PY
then pass "regression TSV and policy are internally consistent"; else fail "regression TSV and policy are internally consistent"; fi

if grep -Fq 'GENERIC_KERNEL_LINK: unbound variable' "$doc" && grep -Fq 'set -u' "$doc" && grep -Fq '/boot/vmlinuz-generic' "$doc"; then pass "regression document records the executable historical and remediated fixtures"; else fail "regression document records the executable historical and remediated fixtures"; fi
if grep -Fq 'further_source_change_authorized=false' "$doc" && grep -Fq 'No Slackware-current rerun is authorized' "$doc" && grep -Fq 'Slackware 15.0 remains' "$doc"; then pass "regression document preserves source and machine authorization boundaries"; else fail "regression document preserves source and machine authorization boundaries"; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail "regression-review helper contains no package, boot, or shutdown mutation command"; else pass "regression-review helper contains no package, boot, or shutdown mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(fetch|pull|clone)|rsync)([[:space:]]|$)' "$helper"; then fail "regression-review helper contains no network client command"; else pass "regression-review helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
