#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
authorization_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review-policy.json"
authorization_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization.tsv"
execution_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.md"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

check_regular() {
    local path=$1 label=$2
    [[ -f "$path" && ! -L "$path" ]] && pass "$label is a regular non-symlink file" || fail "$label is a regular non-symlink file"
}
check_hash() {
    local path=$1 expected=$2 label=$3
    [[ $(sha256sum -- "$path" | awk '{print $1}') == "$expected" ]] && pass "$label SHA-256 is frozen" || fail "$label SHA-256 is frozen"
}
check_output() {
    local key=$1 expected=$2 label=$3
    if awk -F '\t' -v key="$key" -v expected="$expected" '$1 == key && $2 == expected { found=1 } END { exit !found }' "$output"; then
        pass "$label"
    else
        fail "$label"
    fi
}

for item in \
    "$helper:step-151 failure-review helper" \
    "$source_file:accepted remediated reference source" \
    "$template:configuration template" \
    "$authorization_policy:step-149 authorization policy" \
    "$authorization_record:step-149 authorization record" \
    "$execution_harness:step-150 execution harness" \
    "$binding_policy:step-132 target-binding policy" \
    "$accepted_closure:accepted Slackware 15.0 ELILO closure" \
    "$review:step-151 failure-review record" \
    "$policy:step-151 failure-review policy" \
    "$doc:step-151 reference document" \
    "$changelog:CHANGELOG"; do
    check_regular "${item%%:*}" "${item#*:}"
done

check_hash "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference source"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$authorization_policy" d2877fce33c417ff8318fbed3e64a0fe409786f475a1d25ccf97f712a159037f "step-149 authorization policy"
check_hash "$authorization_record" 7058af65141f55d664857ada09d1c29431012f78925c38d4af08d628478d0634 "step-149 authorization record"
check_hash "$execution_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "step-150 execution harness"
check_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
check_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

bash -n "$helper" && pass "the step-151 helper has valid Bash syntax" || fail "the step-151 helper has valid Bash syntax"
python3 -m json.tool "$policy" >/dev/null && pass "the step-151 failure-review policy is valid JSON" || fail "the step-151 failure-review policy is valid JSON"

if "$helper" --help >/dev/null 2>&1; then pass "the step-151 helper exposes a non-mutating help boundary"; else fail "the step-151 helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-invalid >/dev/null 2>&1; then fail "the step-151 helper rejects unknown options"; else pass "the step-151 helper rejects unknown options"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_auth=$(sha256sum -- "$authorization_policy" | awk '{print $1}')
before_harness=$(sha256sum -- "$execution_harness" | awk '{print $1}')
before_closure=$(sha256sum -- "$accepted_closure" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "Slackware 15.0 consumed-execution failure review completed successfully"; else fail "Slackware 15.0 consumed-execution failure review completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "failure review did not modify the accepted source" || fail "failure review did not modify the accepted source"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "failure review did not modify the configuration template" || fail "failure review did not modify the configuration template"
[[ $(sha256sum -- "$authorization_policy" | awk '{print $1}') == "$before_auth" ]] && pass "failure review did not modify the consumed authorization" || fail "failure review did not modify the consumed authorization"
[[ $(sha256sum -- "$execution_harness" | awk '{print $1}') == "$before_harness" ]] && pass "failure review did not modify the consumed execution harness" || fail "failure review did not modify the consumed execution harness"
[[ $(sha256sum -- "$accepted_closure" | awk '{print $1}') == "$before_closure" ]] && pass "failure review did not modify the accepted ELILO closure" || fail "failure review did not modify the accepted ELILO closure"

check_output schema 1 "failure-review output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review "failure-review output records the expected scenario"
check_output evidence_archive_sha256 72d62a7b12f95674eefe31fd6b9698519c717d8a0a4d36a90270e62024e5cb78 "failure review is bound to the authenticated step-150 evidence"
check_output evidence_authenticated true "step-150 evidence is authenticated"
check_output accepted_elilo_core_identity_match true "accepted ELILO core identity remains matched"
check_output execution_attempt_consumed true "the Slackware 15.0 execution attempt is consumed"
check_output runtime_probe_invoked false "the runtime probe is recorded as not invoked"
check_output runtime_probe_accepted false "no runtime verdict is accepted"
check_output system_state_preserved true "package, Slackpkg, boot, source, and template state remained preserved"
check_output mkinitrd_config_observed absent "the missing mkinitrd configuration is frozen as observed evidence"
check_output grub_path_observed directory "the incidental GRUB directory is frozen as observed evidence"
check_output accepted_closure_froze_failed_predicates false "the earlier accepted closure did not freeze either failed predicate"
check_output failure_classification unfrozen-target-characterization-assumption-mismatch "the failure is classified as an unfrozen characterization-assumption mismatch"
check_output boot_regression_confirmed false "the evidence does not establish a boot regression"
check_output source_runtime_defect_confirmed false "the uninvoked runtime probe does not establish a source runtime defect"
check_output harness_characterization_overconstrained true "the consumed harness is classified as overconstrained relative to accepted evidence"
check_output remediation_design_required true "a corrected characterization design is required"
check_output execution_harness_change_authorized false "step 151 grants no harness change"
check_output machine_execution_authorized false "step 151 grants no machine execution"
check_output slackware_15_rerun_authorized false "the consumed execution cannot be rerun under step 149"
check_output repository_refresh_required false "failure review requires no Slackware repository refresh"
check_output slackware_repository_state_dependency false "failure review is independent of Slackware publication state"
check_output machine_action_required false "step 151 requires no machine action"
check_output future_work_requires_fresh_boundary true "future work requires a fresh boundary"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design "failure review advances only to characterization remediation design"
check_output pause_safe true "the reviewed failure boundary is pause-safe"

if grep -Fq '72d62a7b12f95674eefe31fd6b9698519c717d8a0a4d36a90270e62024e5cb78' "$doc" \
    && grep -Fq '/etc/mkinitrd.conf' "$doc" \
    && grep -Fq '/boot/grub' "$doc"; then pass "failure-review document binds the diagnosis to the authenticated step-150 evidence"; else fail "failure-review document binds the diagnosis to the authenticated step-150 evidence"; fi
if grep -Fq 'does not freeze' "$doc" && grep -Fq 'unfrozen-target-characterization-assumption-mismatch' "$doc"; then pass "failure-review document distinguishes unfrozen predicates from proven target regression"; else fail "failure-review document distinguishes unfrozen predicates from proven target regression"; fi
if grep -Fq 'cannot be reused' "$doc" && grep -Fq 'probe was never invoked' "$doc"; then pass "failure-review document preserves the consumed authorization and unexecuted runtime boundary"; else fail "failure-review document preserves the consumed authorization and unexecuted runtime boundary"; fi
if grep -Fq 'pause_safe=true' "$doc" && grep -Fq 'independent of later Slackware publications' "$doc"; then pass "failure-review document records a publication-independent safe pause"; else fail "failure-review document records a publication-independent safe pause"; fi
if grep -Fq 'step-151-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review:start' "$changelog"; then pass "CHANGELOG records the step-151 failure review"; else fail "CHANGELOG records the step-151 failure review"; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail "failure-review helper contains no package, boot, or shutdown mutation command"; else pass "failure-review helper contains no package, boot, or shutdown mutation command"; fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then fail "failure-review helper contains no network client command"; else pass "failure-review helper contains no network client command"; fi

printf 'Result: PASS (%d passes, %d failures)\n' "$passes" "$failures"
(( failures == 0 ))
