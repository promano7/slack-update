#!/bin/bash
set -euo pipefail
IFS=$'
	'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze-harness.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh"
changelog="$repo_root/CHANGELOG.md"
PASS_COUNT=0; FAIL_COUNT=0
pass(){ printf 'PASS: %s
' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s
' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha(){ sha256sum -- "$1"|awk '{print $1}'; }
for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$executor" "$acceptance_harness" "$changelog"; do [[ -f $f && ! -L $f ]] && pass "$(basename "$f") is a regular non-symlink file" || fail "unsafe or missing file: $f"; done
[[ $(sha "$prior_helper") == 'd24b7d2b62a39878935bdc5a1983a368351937e63aa93ae79b8520039480a0a4' ]] && pass 'accepted step-238 helper hash is frozen' || fail 'accepted step-238 helper hash drift'
[[ $(sha "$prior_doc") == '96bdc5a543c608deba6e49f9287cf973cabd743ff361268b1cd66aa77c78b80b' ]] && pass 'accepted step-238 document hash is frozen' || fail 'accepted step-238 document hash drift'
[[ $(sha "$prior_harness") == '135da2a0ab0443164961182b9afff3a7c48fceea0a491620623a7c0f0d00340d' ]] && pass 'accepted step-238 harness hash is frozen' || fail 'accepted step-238 harness hash drift'
[[ $(sha "$prior_policy") == '8648917cc2ed5188a73d3d2f53d799d11680da224cf98135a28262b7def23e9d' ]] && pass 'accepted step-238 policy hash is frozen' || fail 'accepted step-238 policy hash drift'
[[ $(sha "$prior_record") == 'e3194088051d95db4df7a6f806a0003db814086a4f66c835ea4fcc7bfe09c902' ]] && pass 'accepted step-238 record hash is frozen' || fail 'accepted step-238 record hash drift'
[[ $(sha "$executor") == '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' ]] && pass 'frozen remediated executor hash remains exact' || fail 'frozen executor hash drift'
[[ $(sha "$acceptance_harness") == '9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652' ]] && pass 'repository acceptance harness remains exact' || fail 'repository acceptance harness drift'
[[ $(sha "$helper") == 'c40913a7b59accd6a76ccb5435e4d12a85c828cc9bbbbcc991bf2949a8a8755c' ]] && pass 'step-239 helper hash is frozen' || fail 'step-239 helper hash drift'
[[ $(sha "$doc") == '7d27c65fe87e81e7a808f01add3cfcf04a0e04451692808da84348390007732f' ]] && pass 'step-239 document hash is frozen' || fail 'step-239 document hash drift'
[[ $(sha "$policy") == '9bf93ea719de95e8413b36913bd347744cbcb0cd2431182e55ce87b3d9a338df' ]] && pass 'step-239 policy hash is frozen' || fail 'step-239 policy hash drift'
[[ $(sha "$record") == '8884fdd1d74f7bbe7b358e4630a60090bad3b417d9c45802ee1acbe1abad9cd8' ]] && pass 'step-239 record hash is frozen' || fail 'step-239 record hash drift'
bash -n "$helper" && pass 'step-239 helper passes bash syntax validation' || fail 'step-239 helper syntax invalid'
"$helper" --help >/dev/null 2>&1 && pass 'step-239 helper exposes non-mutating help' || fail 'step-239 helper help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-239 helper accepts unknown option'; else pass 'step-239 helper rejects unknown option'; fi
regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
if "$helper" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-239 helper executes successfully'; else fail 'step-239 helper execution failed'; fi
cmp -s "$policy" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-policy.json" && pass 'helper reproduces frozen policy exactly' || fail 'regenerated policy differs'
cmp -s "$record" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.tsv" && pass 'helper reproduces frozen record exactly' || fail 'regenerated record differs'
python3 -m json.tool "$policy" >/dev/null && pass 'step-239 policy is valid JSON' || fail 'step-239 policy invalid JSON'
if python3 - "$policy" <<'PYASSERT'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['step']==239 and p['review_status']=='PASS'
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review'
a=p['accepted_step_238']; assert a['freeze_status']=='PASS' and a['no_machine_authority_inherited'] is True
c=p['reviewed_runtime_authorization_contract']
assert c['state']=='reviewed-awaiting-single-use-authorization-freeze'
assert c['execution_target']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert c['required_running_kernel']=='6.18.45'
assert c['required_boot_id']=='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'
assert c['executor']['sha256']=='9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
assert c['executor']['rebuild_before_transport_authorized'] is False
assert c['predecessor']['sha256']=='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
assert c['predecessor']['redownload_authorized'] is False
assert c['staged_target']['sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert c['local_source_v2']['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert c['historical_failed_evidence']['must_remain_present'] is True
assert c['new_evidence']['runtime_root_must_be_absent_before_start'] is True
assert c['exact_execution_command']=='sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh --execute-runtime-remediation-validation'
assert c['transaction_lifetime']=='single-execution-authority-consumed-on-runtime-start'
assert c['candidate_binding_lifetime']=='same-runtime-transaction-only'
assert c['preflight_must_complete_before_first_mutation'] is True
for key in ['boot-id-drift','local-source-v2-tree-drift','preexisting-remediation-evidence-root']:
    assert key in c['authorization_invalidated_by']
b=c['bounded_mutation']; assert b['package_mutation_scope']=='kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only'
assert b['external_network_access_authorized'] is False and b['boot_action_authorized'] is False and b['reboot_authorized'] is False
f=c['required_final_state']; assert f['header_record']=='kernel-headers-6.18.45-x86-1' and f['reboot_performed'] is False
auth=p['authorization']; assert auth['repository_only_runtime_authorization_freeze_authorized'] is True
for k,v in auth.items():
    if k!='repository_only_runtime_authorization_freeze_authorized': assert v is False
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze'
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
PYASSERT
then pass 'step-239 runtime-authorization review semantic assertions pass'; else fail 'step-239 semantic assertions failed'; fi
for line in  $'step	239'  $'review_status	PASS'  $'runtime_authorization_contract_state	reviewed-awaiting-single-use-authorization-freeze'  $'required_boot_id	fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'  $'canonical_executor_sha256	9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'  $'predecessor_sha256	3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'  $'repository_only_runtime_authorization_freeze_authorized	yes'  $'runtime_executor_transport_authorized	no'  $'runtime_scenario_execution_authorized	no'  $'machine_action_required	no'  $'next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze'; do grep -Fqx "$line" "$record" && pass "record freezes: ${line%%$'	'*}" || fail "record missing frozen row: $line"; done
norm=$(tr '
' ' ' < "$doc"|tr -s '[:space:]' ' ')
[[ $norm == *'9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'* ]] && pass 'reference document records executor identity' || fail 'document omits executor hash'
[[ $norm == *'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'* ]] && pass 'reference document records fresh boot identity' || fail 'document omits boot ID'
[[ $norm == *'same-runtime-transaction-only'* ]] && pass 'reference document preserves same-transaction candidate lifetime' || fail 'document omits candidate lifetime'
[[ $norm == *'grants no machine authority'* ]] && pass 'reference document keeps current machine authority closed' || fail 'document boundary unclear'
[[ $norm == *'runtime-executor-runtime-authorization-freeze'* ]] && pass 'reference document names next stage' || fail 'document next stage mismatch'
for f in "$helper" "$doc"; do if grep -n '[[:blank:]]$' "$f" >/dev/null; then fail "$(basename "$f") has trailing whitespace"; else pass "$(basename "$f") has no trailing whitespace"; fi; done
grep -Fq 'Phase 1 step 239 kernel-package-edge runtime-transaction remediation runtime authorization review' "$changelog" && pass 'CHANGELOG records step 239' || fail 'CHANGELOG does not record step 239'
if grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail 'step-239 helper contains mutation command'; else pass 'step-239 helper contains no executable package/boot mutation command'; fi
if grep -Eq '(curl|wget|ftp|rsync|scp|ssh|ping)' "$helper"; then fail 'step-239 helper contains network client command'; else pass 'step-239 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)
' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
