#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
name='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review'
passes=0
failures=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
regular() { local p=$1 label=$2; if [[ -f $p && ! -L $p ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
hash_eq() { local p=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$p" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label hash is frozen"; else fail "$label hash drift: $actual"; fi; }
contains() { local p=$1 needle=$2 label=$3; if grep -Fq -- "$needle" "$p"; then pass "$label"; else fail "$label"; fi; }

helper="$repo_root/tools/reference/$name.sh"
doc="$repo_root/docs/reference/$name.md"
policy="$acc/$name-policy.json"
record="$acc/$name.tsv"
prior_helper="$repo_root/tools/reference/$prior.sh"
prior_probe="$repo_root/tools/reference/$prior-probe.sh"
prior_doc="$repo_root/docs/reference/$prior.md"
prior_harness="$repo_root/tests/reference/test-$prior-harness.sh"
prior_policy="$acc/$prior-policy.json"
prior_record="$acc/$prior.tsv"
changelog="$repo_root/CHANGELOG.md"

regular "$helper" "$name.sh"
regular "$doc" "$name.md"
regular "$policy" "$name-policy.json"
regular "$record" "$name.tsv"
regular "$prior_helper" "accepted step-241 helper"
regular "$prior_probe" "accepted step-241 probe"
regular "$prior_doc" "accepted step-241 document"
regular "$prior_harness" "accepted step-241 harness"
regular "$prior_policy" "accepted step-241 policy"
regular "$prior_record" "accepted step-241 record"
regular "$changelog" "CHANGELOG.md"

hash_eq "$prior_helper" 'df6bf05be7cdca8bb6bbbb38d1a20e1edf1ee5bd4a0f37ca270a6fea0077bb72' 'accepted step-241 helper'
hash_eq "$prior_probe" 'bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a' 'accepted step-241 probe'
hash_eq "$prior_doc" 'c55980b0ba549e8649e2c8cc218d470e7d526feca030f43787a15bdc72fc9a03' 'accepted step-241 document'
hash_eq "$prior_harness" 'a2c1c56db5690b2e524199f1ba0e7f120a33f81f120354a8cc5b61d7aabd4185' 'accepted step-241 harness'
hash_eq "$prior_policy" '8eaf56961ff91db699b6de1b066a71736f8abf23c462142d4c4929e4e124c778' 'accepted step-241 policy'
hash_eq "$prior_record" '537d87de8c81f3677ddfc49d922dd94efd6d04551ddfb9d5c306e0729f506985' 'accepted step-241 record'
hash_eq "$helper" '042b3b925f0de7d583ded59240b54b0f66e5f116c51236ce44b3417f57a6a210' 'step-242 helper'
hash_eq "$doc" '0f3c9b256d02201c46b7ea81d95d3deeab6423d635da2e9447afc64d378fee59' 'step-242 document'

if bash -n "$helper"; then pass 'step-242 helper passes bash syntax validation'; else fail 'step-242 helper bash syntax validation'; fi
if "$helper" --help >/tmp/step242-help.$$ 2>&1; then pass 'step-242 helper exposes non-mutating help'; else fail 'step-242 helper help'; fi
if "$helper" --unknown >/tmp/step242-unknown.$$ 2>&1; then fail 'step-242 helper rejects unknown option'; else pass 'step-242 helper rejects unknown option'; fi
rm -f /tmp/step242-help.$$ /tmp/step242-unknown.$$

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp"; then pass 'step-242 helper executes successfully'; else fail 'step-242 helper execution'; fi
if cmp -s "$tmp/$name-policy.json" "$policy"; then pass 'helper reproduces frozen policy exactly'; else fail 'helper policy reproduction'; fi
if cmp -s "$tmp/$name.tsv" "$record"; then pass 'helper reproduces frozen record exactly'; else fail 'helper record reproduction'; fi

if python3 - "$policy" <<'PYASSERT'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==242 and p['freeze_status']=='PASS'
assert p['probe_protocol']['observed_invocation_count']==2
assert p['probe_protocol']['first_invocation_result']=='ABORTED_PRECONDITION_MISSING_PRESERVED_EXECUTOR'
assert p['probe_protocol']['first_invocation_mutation_performed'] is False
assert p['probe_protocol']['successful_characterization_observation_count']==1
assert p['probe_protocol']['successful_observation_result']=='PASS'
assert p['probe_protocol']['observation_authority_state']=='consumed-and-closed'
assert p['rollback_baseline']['status']=='PASS'
assert p['rollback_baseline']['current_header_record']=='kernel-headers-6.18.45-x86-1'
assert p['rollback_baseline']['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert p['rollback_baseline']['boot_artifacts_unchanged'] is True
assert p['failure_characterization']['state']=='frozen-confirmed'
assert p['failure_characterization']['mechanism']=='compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch'
assert p['failure_characterization']['slackpkg_update_exit_code']==0
assert p['failure_characterization']['transaction_pkglist_present'] is False
assert p['failure_characterization']['compatibility_asc_contains_PGP'] is False
assert p['failure_characterization']['installed_slackpkg_requires_PGP_marker'] is True
assert p['failure_characterization']['executor_error_signal_guard_form']=='hyphenated-literal'
assert p['design_constraints_for_next_stage']['preserve_local_source_v2_unchanged'] is True
assert p['design_constraints_for_next_stage']['must_match_actual_human_spaced_download_error_signal'] is True
assert p['authorization']['repository_failure_remediation_design_review_authorized'] is True
for key in ['probe_transport_copy_authorized','failure_characterization_observation_authorized','runtime_executor_transport_authorized','runtime_scenario_execution_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized']:
    assert p['authorization'][key] is False, key
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review'
PYASSERT
then pass 'step-242 policy semantic assertions pass'; else fail 'step-242 policy semantic assertions'; fi

for kv in   $'step\t242'   $'freeze_status\tPASS'   $'probe_invocation_count_observed\t2'   $'successful_characterization_status\tPASS'   $'failure_characterization_observation_authority_state\tconsumed-and-closed'   $'rollback_baseline_status\tPASS'   $'failure_mechanism_state\tfrozen-confirmed'   $'runtime_rerun_authorized\tno'   $'repository_failure_remediation_design_review_authorized\tyes'   $'machine_action_required\tno'   $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review'
do
  if grep -Fxq -- "$kv" "$record"; then pass "record freezes: ${kv%%$'\t'*}"; else fail "record missing: $kv"; fi
done

contains "$doc" 'Two probe invocations were observed.' 'reference document records probe invocation irregularity'
contains "$doc" 'The mechanism is frozen as' 'reference document freezes characterization mechanism'
contains "$doc" 'no further probe execution is authorized.' 'reference document closes probe authority'
contains "$doc" 'Neither accepted `local-source-v2` nor the failed remediated executor generation may be changed in place.' 'reference document preserves historical inputs'
contains "$doc" 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review' 'reference document names next stage'

if grep -nE '[[:blank:]]+$' "$doc" "$helper" "$policy" "$record" >/tmp/step242-ws.$$; then cat /tmp/step242-ws.$$; fail 'step-242 files have no trailing whitespace'; else pass 'step-242 files have no trailing whitespace'; fi
rm -f /tmp/step242-ws.$$
contains "$changelog" '## Phase 1 step 242 kernel-package-edge runtime-transaction remediation runtime failure characterization freeze' 'CHANGELOG records step 242'

if grep -nE '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff|mount|umount)([[:space:]]|$)' "$helper" >/tmp/step242-cmd.$$; then cat /tmp/step242-cmd.$$; fail 'step-242 helper contains no executable machine mutation command'; else pass 'step-242 helper contains no executable machine mutation command'; fi
rm -f /tmp/step242-cmd.$$

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
