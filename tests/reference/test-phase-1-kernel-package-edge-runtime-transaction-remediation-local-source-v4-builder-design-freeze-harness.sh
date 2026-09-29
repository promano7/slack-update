#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze'
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file() { [[ -f $1 && ! -L $1 ]] && pass "$2 exists as regular file" || fail "$2 exists as regular file"; }
check_hash() { local got; got=$(sha256sum -- "$1" | awk '{print $1}'); [[ $got == "$2" ]] && pass "$3" || fail "$3 (got $got)"; }

check_file "$helper" 'step-262 helper'
check_file "$doc" 'step-262 document'
check_file "$policy" 'step-262 policy'
check_file "$record" 'step-262 record'
check_file "$prev_helper" 'accepted step-261 helper'
check_file "$prev_doc" 'accepted step-261 document'
check_file "$prev_harness" 'accepted step-261 harness'
check_file "$prev_policy" 'accepted step-261 policy'
check_file "$prev_record" 'accepted step-261 record'
check_file "$v3_builder" 'accepted v3 builder'
check_file "$changelog" 'CHANGELOG'

check_hash "$prev_helper" '6768757c0eb8524a7b5e75ff71281f1614f2d3a04103825d3f662c5a44c50393' 'accepted step-261 helper SHA-256 matches'
check_hash "$prev_doc" 'd90684734c2de428d84ae0bf01c34c62c78ba234cb59598cb47ceeb910516da7' 'accepted step-261 document SHA-256 matches'
check_hash "$prev_harness" '161a00c3552bcc2cec52446a239490140df80989885ce53984c4211355b57874' 'accepted step-261 harness SHA-256 matches'
check_hash "$prev_policy" 'db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef' 'accepted step-261 policy SHA-256 matches'
check_hash "$prev_record" 'b733228aeca5be7055cb84dff306744fb41f49f13c7cc8c1d57bed7401c94981' 'accepted step-261 record SHA-256 matches'
check_hash "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' 'accepted v3 builder SHA-256 remains frozen'
check_hash "$helper" 'a8e6e5980edcf9550bc4ab7999b4452899b45e0e29c4e62039b9045916573b2f' 'step-262 helper SHA-256 matches'
check_hash "$doc" '29da67295aba1d65de381901031048691940ac8729b57846c51d20c318ac04e5' 'step-262 document SHA-256 matches'
check_hash "$policy" '9359949c6dfd9ac7476b1b4f3053dbd2859022feab6d90e7baafcafb5a07b425' 'step-262 policy SHA-256 matches'
check_hash "$record" 'fff8563425ff16f64935e94d99d6e8709554941aac55bc7e40917a04fb39d6e3' 'step-262 record SHA-256 matches'

bash -n "$helper" && pass 'step-262 helper passes bash syntax validation' || fail 'step-262 helper passes bash syntax validation'
bash -n "${BASH_SOURCE[0]}" && pass 'step-262 harness passes bash syntax validation' || fail 'step-262 harness passes bash syntax validation'
"$helper" --help >/dev/null && pass 'step-262 helper exposes non-mutating help' || fail 'step-262 helper exposes non-mutating help'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-262 helper rejects unknown option'; else pass 'step-262 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp"; then pass 'step-262 helper executes successfully'; else fail 'step-262 helper executes successfully'; fi
cmp -s "$tmp/${base}-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/${base}.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

python3 - "$policy" "$record" <<'PYTEST'
import json, pathlib, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
r={}
for line in pathlib.Path(sys.argv[2]).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); r[k]=v
checks=[
 ('policy identifies step 262', p['step']==262 and p['scenario'].endswith('local-source-v4-builder-design-freeze')),
 ('review status is PASS', p['review_status']=='PASS'),
 ('step-261 input is accepted', p['accepted_step_261']['policy_sha256']=='db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef'),
 ('v3 builder identity remains frozen', p['accepted_v3_builder']['sha256']=='80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' and p['accepted_v3_builder']['must_remain_unchanged'] is True),
 ('builder design is frozen not implemented', p['builder_design']['state']=='design-frozen-not-implemented'),
 ('functional scope remains checksum representation only', p['frozen_inputs']['functional_remediation_scope']=='CHECKSUMS.md5 record representation only'),
 ('writer remains ordinary untagged md5sum', p['builder_design']['checksum_writer_design']['writer_command']=='md5sum -- "$rel"'),
 ('tagged records remain forbidden', p['builder_design']['checksum_writer_design']['tagged_writer_forbidden'] is True),
 ('path remains terminal field', p['builder_design']['checksum_writer_design']['path_is_final_whitespace_delimited_field'] is True),
 ('exact binding validator remains mandatory', p['builder_design']['checksum_validator_design']['missing_binding_rejected'] is True and p['builder_design']['checksum_validator_design']['duplicate_binding_rejected'] is True and p['builder_design']['checksum_validator_design']['malformed_binding_rejected'] is True),
 ('accepted design semantics are immutable', p['design_freeze_contract']['accepted_step_261_design_semantics_must_not_change'] is True),
 ('implementation must be mechanical v3 derivative', p['design_freeze_contract']['implementation_must_be_mechanical_v3_r1_derivative'] is True),
 ('implementation diff is restricted', p['design_freeze_contract']['implementation_diff_must_be_limited_to_frozen_identity_and_checksum_changes'] is True),
 ('synthetic negative tests are mandatory', p['design_freeze_contract']['synthetic_negative_tests_are_mandatory'] is True),
 ('implementation review may not execute builder', p['design_freeze_contract']['implementation_review_may_create_repository_artifacts_but_may_not_execute_builder'] is True),
 ('implementation review is repository only', p['implementation_review_boundary']['repository_only'] is True and p['implementation_review_boundary']['production_execution_forbidden'] is True),
 ('valid untagged synthetic test required', p['implementation_review_boundary']['must_prove_valid_untagged_bindings_pass'] is True),
 ('tagged synthetic failure required', p['implementation_review_boundary']['must_prove_tagged_bindings_fail'] is True),
 ('missing synthetic failure required', p['implementation_review_boundary']['must_prove_missing_bindings_fail'] is True),
 ('duplicate synthetic failure required', p['implementation_review_boundary']['must_prove_duplicate_bindings_fail'] is True),
 ('malformed binary-marker synthetic failure required', p['implementation_review_boundary']['must_prove_malformed_or_binary_marker_bindings_fail'] is True),
 ('extra synthetic failure required', p['implementation_review_boundary']['must_prove_extra_bindings_fail'] is True),
 ('only implementation review is opened', p['authorization']['repository_only_v4_builder_implementation_review_authorized'] is True),
 ('v4 builder execution remains closed', p['authorization']['local_source_v4_builder_execution_authorized'] is False),
 ('v4 build remains closed', p['authorization']['local_source_v4_build_authorized'] is False),
 ('target observation remains closed', p['authorization']['target_observation_authorized'] is False),
 ('runtime rerun remains closed', p['authorization']['runtime_execution_or_rerun_authorized'] is False),
 ('package and Slackpkg mutation remain closed', p['authorization']['package_action_authorized'] is False and p['authorization']['slackpkg_mutation_authorized'] is False),
 ('network boot reboot remain closed', p['authorization']['network_access_authorized'] is False and p['authorization']['boot_action_authorized'] is False and p['authorization']['reboot_authorized'] is False),
 ('no machine action is required', p['machine_action_required'] is False and p['controller_action_required'] is False),
 ('step 262 is not a strong safe pause', p['pause_safe'] is False and p['strong_safe_pause'] is False),
 ('next stage is v4 builder implementation review', p['next_stage'].endswith('local-source-v4-builder-implementation-review')),
 ('TSV freezes design state', r['builder_design_state']=='design-frozen-not-implemented'),
 ('TSV opens repository implementation review', r['repository_only_v4_builder_implementation_review_authorized']=='yes'),
 ('TSV keeps builder execution closed', r['v4_builder_execution_authorized']=='no'),
 ('TSV keeps v4 build closed', r['v4_build_authorized']=='no'),
 ('TSV requires no machine action', r['machine_action_required']=='no' and r['controller_action_required']=='no'),
]
for label,ok in checks:
    print(('PASS: ' if ok else 'FAIL: ')+label)
    if not ok: raise SystemExit(1)
PYTEST
py_status=$?
if [[ $py_status -eq 0 ]]; then passes=$((passes+37)); else failures=$((failures+1)); fi

grep -Fq 'design-frozen-not-implemented' "$doc" && pass 'step-262 document records frozen design state' || fail 'step-262 document records frozen design state'
grep -Fq 'mechanical derivative' "$doc" && pass 'step-262 document constrains implementation derivation' || fail 'step-262 document constrains implementation derivation'
grep -Fq 'tagged, missing, duplicate, malformed/binary-marker, and extra bindings fail' "$doc" && pass 'step-262 document requires synthetic negative cases' || fail 'step-262 document requires synthetic negative cases'
grep -Fq '## Phase 1 step 262 kernel-package-edge runtime-transaction remediation local-source-v4 builder design freeze' "$changelog" && pass 'CHANGELOG records step 262' || fail 'CHANGELOG records step 262'

for f in "$helper" "$doc" "$policy" "$record"; do
    name=${f##*/}
    if grep -n '[[:blank:]]$' "$f" >/dev/null; then fail "$name contains no trailing whitespace"; else pass "$name contains no trailing whitespace"; fi
done

if grep -E '(^|[;|&][[:space:]]*)(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)([[:space:]]|$)|(^|[[:space:]])(curl|wget)[[:space:]]' "$helper" >/dev/null; then
    fail 'step-262 helper contains no executable network package boot reboot or shutdown command'
else
    pass 'step-262 helper contains no executable network package boot reboot or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
