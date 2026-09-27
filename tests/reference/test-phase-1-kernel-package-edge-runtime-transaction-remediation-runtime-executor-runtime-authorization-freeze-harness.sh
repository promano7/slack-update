#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-harness.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
changelog="$repo_root/CHANGELOG.md"
PASS_COUNT=0; FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha(){ sha256sum -- "$1"|awk '{print $1}'; }
for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$executor" "$changelog"; do [[ -f $f && ! -L $f ]] && pass "$(basename "$f") is a regular non-symlink file" || fail "unsafe or missing file: $f"; done
[[ $(sha "$prior_helper") == 'c40913a7b59accd6a76ccb5435e4d12a85c828cc9bbbbcc991bf2949a8a8755c' ]] && pass 'accepted step-239 helper hash is frozen' || fail 'accepted step-239 helper hash drift'
[[ $(sha "$prior_doc") == '7d27c65fe87e81e7a808f01add3cfcf04a0e04451692808da84348390007732f' ]] && pass 'accepted step-239 document hash is frozen' || fail 'accepted step-239 document hash drift'
[[ $(sha "$prior_harness") == '104ca01a3c9c582950d9f8c24700c105dbdaf01e8120963edc608bdacbf79af5' ]] && pass 'accepted step-239 harness hash is frozen' || fail 'accepted step-239 harness hash drift'
[[ $(sha "$prior_policy") == '9bf93ea719de95e8413b36913bd347744cbcb0cd2431182e55ce87b3d9a338df' ]] && pass 'accepted step-239 policy hash is frozen' || fail 'accepted step-239 policy hash drift'
[[ $(sha "$prior_record") == '8884fdd1d74f7bbe7b358e4630a60090bad3b417d9c45802ee1acbe1abad9cd8' ]] && pass 'accepted step-239 record hash is frozen' || fail 'accepted step-239 record hash drift'
[[ $(sha "$executor") == '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' ]] && pass 'frozen remediated executor hash remains exact' || fail 'executor hash drift'
[[ $(sha "$helper") == '5b2a707ffb1686eb41260956c5bd2423dbc25508e46b93796da703c3cbef3389' ]] && pass 'step-240 helper hash is frozen' || fail 'step-240 helper hash drift'
[[ $(sha "$doc") == 'e701fb391391aacb06d9b4d2b90e6db4d671f2b2129c89172c0307928c228c40' ]] && pass 'step-240 document hash is frozen' || fail 'step-240 document hash drift'
[[ $(sha "$policy") == 'dd80b32a42e278f4f9ed8cc80c1aace1159e501d0154dcf2c8f828cafa7d5ce1' ]] && pass 'step-240 policy hash is frozen' || fail 'step-240 policy hash drift'
[[ $(sha "$record") == '31e438ab895a31e4c952c9dc8af87c9a1280edd967c29504ee0c5bbdea6735d1' ]] && pass 'step-240 record hash is frozen' || fail 'step-240 record hash drift'
bash -n "$helper" && pass 'step-240 helper passes bash syntax validation' || fail 'step-240 helper syntax invalid'
"$helper" --help >/dev/null 2>&1 && pass 'step-240 helper exposes non-mutating help' || fail 'step-240 helper help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-240 helper accepts unknown option'; else pass 'step-240 helper rejects unknown option'; fi
regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
"$helper" --output-dir "$regen" >/dev/null 2>&1 && pass 'step-240 helper executes successfully' || fail 'step-240 helper execution failed'
cmp -s "$policy" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-policy.json" && pass 'helper reproduces frozen policy exactly' || fail 'regenerated policy differs'
cmp -s "$record" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.tsv" && pass 'helper reproduces frozen record exactly' || fail 'regenerated record differs'
python3 -m json.tool "$policy" >/dev/null && pass 'step-240 policy is valid JSON' || fail 'step-240 policy invalid JSON'
if python3 - "$policy" <<'PYASSERT'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==240 and p['freeze_status']=='PASS'
assert p['single_use_runtime_authority_state']=='authorized-awaiting-runtime-start' and p['authorization_use_count']==1
assert p['accepted_step_239']['review_status']=='PASS'
a=p['authorization']
for k in ['runtime_executor_transport_authorized','predecessor_package_transport_authorized','predecessor_package_staging_authorized','temporary_slackpkg_configuration_authorized','local_source_metadata_refresh_authorized','runtime_candidate_binding_authorized','reference_apply_authorized','runtime_scenario_execution_authorized','runtime_rerun_authorized','package_action_authorized','repository_refresh_authorized']: assert a[k] is True
for k in ['runtime_executor_build_authorized','predecessor_package_redownload_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized']: assert a[k] is False
s=p['single_use_constraints']; assert s['authority_consumed_on_runtime_start'] is True and s['second_execution_forbidden'] is True and s['preflight_failure_consumes_authority'] is True
assert s['exact_execution_command']=='sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh --execute-runtime-remediation-validation'
t=p['transport']; assert t['executor_sha256']=='9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' and t['predecessor_sha256']=='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
assert p['machine_action_required'] is True and p['controller_action_required'] is True
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-review'
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
PYASSERT
then pass 'step-240 single-use runtime authorization semantic assertions pass'; else fail 'step-240 semantic assertions failed'; fi
for line in $'step\t240' $'freeze_status\tPASS' $'single_use_runtime_authority_state\tauthorized-awaiting-runtime-start' $'authorization_use_count\t1' $'runtime_executor_transport_authorized\tyes' $'predecessor_package_transport_authorized\tyes' $'runtime_scenario_execution_authorized\tyes' $'network_access_authorized\tno' $'reboot_authorized\tno' $'authority_consumed_on_runtime_start\tyes' $'second_execution_forbidden\tyes' $'machine_action_required\tyes' $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-review'; do grep -Fqx "$line" "$record" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"; done
norm=$(tr '\n' ' ' < "$doc"|tr -s '[:space:]' ' ')
[[ $norm == *'one bounded runtime-remediation authority'* ]] && pass 'reference document opens one bounded runtime authority' || fail 'document authority scope unclear'
[[ $norm == *'authority is consumed when that executor starts'* ]] && pass 'reference document freezes consumption point' || fail 'document omits authority consumption'
[[ $norm == *'A second execution is forbidden'* ]] && pass 'reference document forbids second execution' || fail 'document omits second-run prohibition'
[[ $norm == *'External network access, boot changes, reboot'* ]] && pass 'reference document preserves external mutation prohibitions' || fail 'document mutation boundary unclear'
[[ $norm == *'runtime-result-review'* ]] && pass 'reference document names result review' || fail 'document next stage mismatch'
for f in "$helper" "$doc"; do if grep -n '[[:blank:]]$' "$f" >/dev/null; then fail "$(basename "$f") has trailing whitespace"; else pass "$(basename "$f") has no trailing whitespace"; fi; done
grep -Fq 'Phase 1 step 240 kernel-package-edge runtime-transaction remediation runtime authorization freeze' "$changelog" && pass 'CHANGELOG records step 240' || fail 'CHANGELOG does not record step 240'
if grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail 'step-240 helper contains executable machine mutation command'; else pass 'step-240 helper itself contains no executable machine mutation command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
