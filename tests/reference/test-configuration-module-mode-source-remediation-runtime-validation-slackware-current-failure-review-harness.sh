#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
current_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() { local path=$1 label=$2; if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi; }
check_hash() { local path=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi; }
check_output() { local key=$1 expected=$2 label=$3 actual; actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output"); if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; fi; }

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$binding_policy" "step-132 target-binding policy"
check_regular "$current_harness" "step-132 Slackware-current harness"
check_regular "$review" "step-134 failure-review record"
check_regular "$policy" "step-134 failure-review policy"
check_regular "$helper" "step-134 failure-review helper"
check_regular "$doc" "step-134 failure-review document"
check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$current_harness" 9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62 "step-132 Slackware-current harness"

if bash -n "$helper"; then pass "failure-review helper is shell-syntax valid"; else fail "failure-review helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "failure-review helper exposes a non-mutating help boundary"; else fail "failure-review helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "failure-review helper rejects unknown options"; else pass "failure-review helper rejects unknown options"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "failure-review policy is valid JSON"; else fail "failure-review policy is valid JSON"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_binding=$(sha256sum -- "$binding_policy" | awk '{print $1}')
before_harness=$(sha256sum -- "$current_harness" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "Slackware-current failure review completed successfully"; else fail "Slackware-current failure review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "failure review did not modify the reference implementation" || fail "failure review did not modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "failure review did not modify the configuration template" || fail "failure review did not modify the configuration template"
[[ $(sha256sum -- "$binding_policy" | awk '{print $1}') == "$before_binding" ]] && pass "failure review did not modify the step-132 binding" || fail "failure review did not modify the step-132 binding"
[[ $(sha256sum -- "$current_harness" | awk '{print $1}') == "$before_harness" ]] && pass "failure review did not modify the consumed current harness" || fail "failure review did not modify the consumed current harness"

check_output schema 1 "failure-review output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review "failure-review output records the expected scenario"
check_output evidence_archive_sha256 78193b32b52094ec164a051f34589e33ca3918eb0a5bc0c0927033ea797840ed "failure review is bound to the authenticated step-133 evidence archive"
check_output evidence_authenticated true "step-133 evidence is authenticated"
check_output target_characterization_accepted true "the target characterization remains accepted"
check_output execution_attempt_consumed true "the current execution attempt is consumed"
check_output runtime_probe_completed false "the runtime probe is recorded as incomplete"
check_output runtime_probe_accepted false "the incomplete runtime probe is not accepted"
check_output system_state_preserved true "package, boot, source, and template state remained preserved"
check_output failure_stage probe_boot_module "the failure remains bound to probe_boot_module"
check_output failure_function probe_direct_generic_boot_layout "the failure remains bound to the direct-generic capability probe"
check_output failure_type unbound-shell-variable "the failure type is frozen as an unbound shell variable"
check_output failure_variable GENERIC_KERNEL_LINK "the exact failing variable is frozen"
check_output failure_classification source-runtime-initialization-defect "the failure is classified as a source runtime-initialization defect"
check_output root_cause_confirmed true "the accepted source landmarks confirm the root cause"
check_output remediation_required true "a narrow source remediation is required"
check_output source_change_authorized false "step 134 grants no source change"
check_output machine_execution_authorized false "step 134 grants no machine execution"
check_output slackware_current_rerun_authorized false "the consumed current execution cannot be rerun under step 132"
check_output slackware_15_execution_released false "Slackware 15.0 remains held"
check_output slackware_15_execution_authorized false "Slackware 15.0 remains unauthorized"
check_output repository_refresh_required false "failure review requires no Slackware repository refresh"
check_output slackware_repository_state_dependency false "failure review is independent of Slackware repository publication state"
check_output machine_action_required false "step 134 requires no machine action"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design "failure review advances only to remediation design"
check_output pause_safe true "the reviewed failure boundary is pause-safe"

if grep -Fq '78193b32b52094ec164a051f34589e33ca3918eb0a5bc0c0927033ea797840ed' "$doc" && grep -Fq 'GENERIC_KERNEL_LINK: unbound variable' "$doc" && grep -Fq 'sixteen pre-probe characterization assertions' "$doc"; then pass "failure-review document binds the diagnosis to the authenticated runtime evidence"; else fail "failure-review document binds the diagnosis to the authenticated runtime evidence"; fi
if grep -Fq 'cannot be reused' "$doc" && grep -Fq 'Slackware 15.0 remains held' "$doc"; then pass "failure-review document preserves the consumed authorization and 15.0 hold"; else fail "failure-review document preserves the consumed authorization and 15.0 hold"; fi
if grep -Fq 'source runtime-initialization defect' "$doc" && grep -Fq 'before the classifier body can execute' "$doc"; then pass "failure-review document records the exact initialization-order defect"; else fail "failure-review document records the exact initialization-order defect"; fi
if grep -Fq 'pause_safe=true' "$doc" && grep -Fq 'independent of later Slackware-current publications' "$doc"; then pass "failure-review document records a publication-independent safe pause"; else fail "failure-review document records a publication-independent safe pause"; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail "failure-review helper contains no package, boot, or shutdown mutation command"; else pass "failure-review helper contains no package, boot, or shutdown mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then fail "failure-review helper contains no network client command"; else pass "failure-review helper contains no network client command"; fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
