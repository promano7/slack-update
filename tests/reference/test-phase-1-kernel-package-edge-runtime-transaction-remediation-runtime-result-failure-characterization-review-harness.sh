#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-harness.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.tsv"
changelog="$repo_root/CHANGELOG.md"
PASS_COUNT=0; FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha(){ sha256sum -- "$1"|awk '{print $1}'; }
for f in "$helper" "$probe" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$changelog"; do [[ -f $f && ! -L $f ]] && pass "$(basename "$f") is a regular non-symlink file" || fail "unsafe or missing file: $f"; done
[[ $(sha "$prior_helper") == '5b2a707ffb1686eb41260956c5bd2423dbc25508e46b93796da703c3cbef3389' ]] && pass 'accepted step-240 helper hash is frozen' || fail 'accepted step-240 helper hash drift'
[[ $(sha "$prior_doc") == 'e701fb391391aacb06d9b4d2b90e6db4d671f2b2129c89172c0307928c228c40' ]] && pass 'accepted step-240 document hash is frozen' || fail 'accepted step-240 document hash drift'
[[ $(sha "$prior_harness") == 'aef384a497e66dba050107f6fd27c7ca1b6d1fa39c4a1a81c65d92f69fcf43e8' ]] && pass 'accepted step-240 harness hash is frozen' || fail 'accepted step-240 harness hash drift'
[[ $(sha "$prior_policy") == 'dd80b32a42e278f4f9ed8cc80c1aace1159e501d0154dcf2c8f828cafa7d5ce1' ]] && pass 'accepted step-240 policy hash is frozen' || fail 'accepted step-240 policy hash drift'
[[ $(sha "$prior_record") == '31e438ab895a31e4c952c9dc8af87c9a1280edd967c29504ee0c5bbdea6735d1' ]] && pass 'accepted step-240 record hash is frozen' || fail 'accepted step-240 record hash drift'
[[ $(sha "$helper") == 'df6bf05be7cdca8bb6bbbb38d1a20e1edf1ee5bd4a0f37ca270a6fea0077bb72' ]] && pass 'step-241 helper hash is frozen' || fail 'step-241 helper hash drift'
[[ $(sha "$probe") == 'bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a' ]] && pass 'step-241 probe hash is frozen' || fail 'step-241 probe hash drift'
[[ $(sha "$doc") == 'c55980b0ba549e8649e2c8cc218d470e7d526feca030f43787a15bdc72fc9a03' ]] && pass 'step-241 document hash is frozen' || fail 'step-241 document hash drift'
[[ $(sha "$policy") == '8eaf56961ff91db699b6de1b066a71736f8abf23c462142d4c4929e4e124c778' ]] && pass 'step-241 policy hash is frozen' || fail 'step-241 policy hash drift'
[[ $(sha "$record") == '537d87de8c81f3677ddfc49d922dd94efd6d04551ddfb9d5c306e0729f506985' ]] && pass 'step-241 record hash is frozen' || fail 'step-241 record hash drift'
bash -n "$helper" && pass 'step-241 helper passes bash syntax validation' || fail 'step-241 helper syntax invalid'
bash -n "$probe" && pass 'step-241 probe passes bash syntax validation' || fail 'step-241 probe syntax invalid'
"$helper" --help >/dev/null 2>&1 && pass 'step-241 helper exposes non-mutating help' || fail 'step-241 helper help failed'
"$probe" --help >/dev/null 2>&1 && pass 'step-241 probe exposes non-mutating help' || fail 'step-241 probe help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-241 helper accepts unknown option'; else pass 'step-241 helper rejects unknown option'; fi
if "$probe" --unknown >/dev/null 2>&1; then fail 'step-241 probe accepts unknown option'; else pass 'step-241 probe rejects unknown option'; fi
regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
"$helper" --output-dir "$regen" >/dev/null 2>&1 && pass 'step-241 helper executes successfully' || fail 'step-241 helper execution failed'
cmp -s "$policy" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-policy.json" && pass 'helper reproduces frozen policy exactly' || fail 'regenerated policy differs'
cmp -s "$record" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.tsv" && pass 'helper reproduces frozen record exactly' || fail 'regenerated record differs'
python3 -m json.tool "$policy" >/dev/null && pass 'step-241 policy is valid JSON' || fail 'step-241 policy invalid JSON'
if python3 - "$policy" <<'PYASSERT'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==241 and p['review_status']=='PASS'
assert p['observed_runtime_result']=='FAIL'
assert p['observed_runtime_error']=='fresh transaction-owned Slackpkg pkglist is missing or unsafe'
assert p['single_use_runtime_authority_state']=='consumed-by-failed-runtime-start'
assert p['authorization_use_count']==1 and p['second_execution_forbidden'] is True
h=p['failure_hypothesis']; assert h['state']=='pending-read-only-runtime-confirmation'; assert h['expected_refresh_exit_code']==0; assert h['expected_transaction_pkglist_present'] is False
assert h['hypothesis']=='compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch'
a=p['authorization']; assert a['probe_transport_copy_authorized'] is True and a['failure_characterization_observation_authorized'] is True
for k in ['runtime_executor_transport_authorized','runtime_scenario_execution_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized']: assert a[k] is False
assert p['machine_action_required'] is True and p['controller_action_required'] is True
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze'
PYASSERT
then pass 'step-241 failure-characterization review semantic assertions pass'; else fail 'step-241 semantic assertions failed'; fi
for row in $'step\t241' $'observed_runtime_result\tFAIL' $'single_use_runtime_authority_state\tconsumed-by-failed-runtime-start' $'second_execution_forbidden\tyes' $'failure_hypothesis_state\tpending-read-only-runtime-confirmation' $'probe_transport_copy_authorized\tyes' $'failure_characterization_observation_authorized\tyes' $'runtime_rerun_authorized\tno' $'package_action_authorized\tno' $'slackpkg_mutation_authorized\tno' $'reboot_authorized\tno' $'evidence_cleanup_authorized\tno'; do grep -Fqx "$row" "$record" && pass "record freezes: ${row%%$'\t'*}" || fail "record missing row: $row"; done
norm=$(tr '\n' ' ' < "$doc"|tr -s '[:space:]' ' ')
[[ $norm == *'A second execution is forbidden'* ]] && pass 'reference document forbids second executor run' || fail 'document omits second-run prohibition'
[[ $norm == *'CHECKSUMS.md5.asc'*'contains no `PGP` marker'* ]] && pass 'reference document records compatibility asc hypothesis' || fail 'document omits asc hypothesis'
[[ $norm == *'Error downloading from <SOURCE>.'* ]] && pass 'reference document records human-form Slackpkg error' || fail 'document omits Slackpkg error form'
[[ $norm == *'read-only observation'* ]] && pass 'reference document opens only read-only observation' || fail 'document observation scope unclear'
for f in "$helper" "$probe" "$doc"; do if grep -n '[[:blank:]]$' "$f" >/dev/null; then fail "$(basename "$f") has trailing whitespace"; else pass "$(basename "$f") has no trailing whitespace"; fi; done
grep -Fq 'Phase 1 step 241 kernel-package-edge runtime-transaction remediation runtime result failure characterization review' "$changelog" && pass 'CHANGELOG records step 241' || fail 'CHANGELOG does not record step 241'
if grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)([[:space:]]|$)' "$probe"; then fail 'step-241 probe contains executable mutation command'; else pass 'step-241 probe contains no executable package/boot mutation command'; fi
if grep -Eq '(^|[[:space:]])(curl|wget|ftp|rsync)([[:space:]]|$)' "$probe"; then fail 'step-241 probe contains network client command'; else pass 'step-241 probe contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
