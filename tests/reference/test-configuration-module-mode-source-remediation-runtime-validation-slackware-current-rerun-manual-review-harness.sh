#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
rerun_authorization_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review-policy.json"
rerun_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { [[ -f "$1" && ! -L "$1" ]] && pass "$2 is a regular file" || fail "$2 is a regular file"; }
check_hash() { local actual; actual=$(sha256sum -- "$1" 2>/dev/null | awk '{print $1}'); [[ "$actual" == "$2" ]] && pass "$3" || fail "$3"; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); [[ "$actual" == "$expected" ]] && pass "$label" || fail "$label"; }

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$binding_policy" "step-132 target-binding policy"
check_regular "$rerun_authorization_policy" "step-139 rerun-authorization policy"
check_regular "$rerun_harness" "step-140 rerun harness"
check_regular "$review" "step-141 manual-review record"
check_regular "$policy" "step-141 manual-review policy"
check_regular "$helper" "step-141 manual-review helper"
check_regular "$doc" "step-141 manual-review document"

check_hash "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference implementation is unchanged"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template is unchanged"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target binding is unchanged"
check_hash "$rerun_authorization_policy" 5d0dc91852d8efe5ff203be68468ca5db4cfb6c718e1f4430caf4bf75550a6ba "step-139 rerun authorization is unchanged"
check_hash "$rerun_harness" 0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120 "step-140 rerun harness is unchanged"

bash -n "$helper" && pass "manual-review helper is shell-syntax valid" || fail "manual-review helper is shell-syntax valid"
bash -n "$0" && pass "manual-review harness is shell-syntax valid" || fail "manual-review harness is shell-syntax valid"
"$helper" --help >/dev/null && pass "manual-review helper exposes a non-mutating help boundary" || fail "manual-review helper exposes a non-mutating help boundary"
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "manual-review helper rejects unknown options"; else pass "manual-review helper rejects unknown options"; fi
python3 -m json.tool "$policy" >/dev/null && pass "manual-review policy is valid JSON" || fail "manual-review policy is valid JSON"

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_authorization=$(sha256sum -- "$rerun_authorization_policy" | awk '{print $1}')
before_rerun=$(sha256sum -- "$rerun_harness" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
"$helper" >"$output" && pass "Slackware-current rerun manual review completed successfully" || fail "Slackware-current rerun manual review completed successfully"

[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "manual review did not modify the reference implementation" || fail "manual review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "manual review did not modify the configuration template" || fail "manual review did not modify the configuration template"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "manual review did not modify the step-132 binding" || fail "manual review did not modify the step-132 binding"
[[ $(sha256sum -- "$rerun_authorization_policy" | awk '{print $1}') == "$before_authorization" ]] && pass "manual review did not modify the step-139 authorization" || fail "manual review did not modify the step-139 authorization"
[[ $(sha256sum -- "$rerun_harness" | awk '{print $1}') == "$before_rerun" ]] && pass "manual review did not modify the step-140 rerun harness" || fail "manual review did not modify the step-140 rerun harness"

check_output schema 1 "manual-review output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review "manual-review output records the expected scenario"
check_output evidence_archive_sha256 def71e947186de4e3df4f4af4cddc55f0b41397076e17fbc1b97f13129e58eb8 "manual review is bound to the authenticated step-140 evidence"
check_output evidence_authenticated true "step-140 evidence is authenticated"
check_output target_characterization_accepted false "target characterization remains rejected"
check_output underlying_root_device_matches true "the mounted root still resolves to the frozen partition"
check_output frozen_boot_selection_matches false "the exact frozen boot selection does not match"
check_output runtime_probe_completed false "the runtime probe was not entered"
check_output runtime_probe_accepted false "no runtime verdict is accepted"
check_output system_state_preserved true "package, boot, source, and template state remained preserved"
check_output failure_stage pre-probe-target-characterization "the stop occurred during pre-probe characterization"
check_output failure_classification frozen-boot-selection-mismatch "the failure is classified as a frozen boot-selection mismatch"
check_output source_runtime_initialization_remediation_exercised false "the repaired source path was not exercised"
check_output rerun_attempt_consumed true "the single step-139 rerun attempt is treated as consumed"
check_output rerun_under_step139_authorization_permitted false "the step-139 authorization cannot be reused"
check_output boot_selection_remediation_required true "boot-selection remediation requires a separate design"
check_output source_change_required false "the evidence does not require another source change"
check_output source_change_authorized false "step 141 grants no source change"
check_output machine_execution_authorized false "step 141 grants no machine execution"
check_output reboot_authorized false "step 141 grants no reboot"
check_output boot_mutation_authorized false "step 141 grants no boot mutation"
check_output slackware_current_rerun_authorized false "no replacement Slackware-current rerun is authorized"
check_output slackware_15_execution_released false "Slackware 15.0 remains held"
check_output slackware_15_execution_authorized false "Slackware 15.0 remains unauthorized"
check_output repository_refresh_required false "manual review requires no Slackware repository refresh"
check_output slackware_repository_state_dependency false "manual review is independent of Slackware-current publication state"
check_output machine_action_required false "step 141 requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design "manual review advances only to boot-selection remediation design"
check_output pause_safe true "the reviewed failure boundary is pause-safe"

if grep -Fq 'def71e947186de4e3df4f4af4cddc55f0b41397076e17fbc1b97f13129e58eb8' "$doc" \
    && grep -Fq 'root=UUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863' "$doc" \
    && grep -Fq 'root=/dev/sda2' "$doc"; then
    pass "manual-review document binds the diagnosis to the authenticated root-token mismatch"
else
    fail "manual-review document binds the diagnosis to the authenticated root-token mismatch"
fi
if python3 - "$doc" <<'PYDOC'
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    normalized = " ".join(handle.read().split())

assert "runtime probe was never invoked" in normalized
assert "neither exercised nor rejected" in normalized
PYDOC
then
    pass "manual-review document does not misclassify the unexercised source remediation"
else
    fail "manual-review document does not misclassify the unexercised source remediation"
fi
if grep -Fq 'must not be used again' "$doc" \
    && grep -Fq 'Slackware 15.0 remains held' "$doc"; then
    pass "manual-review document preserves the fail-closed authorization boundary"
else
    fail "manual-review document preserves the fail-closed authorization boundary"
fi
if grep -Fq 'pause_safe=true' "$doc" \
    && grep -Fq 'independent of later Slackware-current publications' "$doc"; then
    pass "manual-review document records a publication-independent safe pause"
else
    fail "manual-review document records a publication-independent safe pause"
fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|grub-reboot|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "manual-review helper contains no package, boot, reboot, or shutdown mutation command"
else
    pass "manual-review helper contains no package, boot, reboot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "manual-review helper contains no network client command"
else
    pass "manual-review helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
