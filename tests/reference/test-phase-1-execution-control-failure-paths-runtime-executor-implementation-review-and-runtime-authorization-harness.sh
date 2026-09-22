#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)

HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.tsv"
P185="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-policy.json"
R185="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation.tsv"
BUILDER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh"
EXECUTOR="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"
ACCEPTANCE="$repo_root/tests/acceptance/reference/test-execution-control-failure-paths.sh"
IDOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation.md"
REMEDIATION_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-network-failure-remediation-policy.json"
REMEDIATION_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-network-failure-remediation.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"

PASS_COUNT=0
FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular(){ [[ -f $1 && ! -L $1 ]]; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }

for pair in \
  "$HELPER|historical step-186 review helper" \
  "$DOC|historical step-186 reference document" \
  "$POLICY|historical step-186 runtime-authorization policy" \
  "$RECORD|historical step-186 runtime-authorization record" \
  "$P185|historical step-185 implementation policy" \
  "$R185|historical step-185 implementation record" \
  "$BUILDER|current remediated builder" \
  "$EXECUTOR|current remediated executor" \
  "$ACCEPTANCE|current remediated acceptance harness" \
  "$IDOC|historical step-185 implementation document" \
  "$REMEDIATION_POLICY|current superseding remediation policy" \
  "$REMEDIATION_RECORD|current superseding remediation record"; do
    f=${pair%%|*}
    label=${pair#*|}
    regular "$f" && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"
done

[[ $(sha "$HELPER") == '17413c6e3af5307c1fea327abd612dd74094cfcb8ca96c7f84b88d1c2c7b233b' ]] && pass 'historical step-186 helper remains byte-identical' || fail 'historical step-186 helper identity drift'
[[ $(sha "$DOC") == 'ffa16401ecd46605a2b3e02187c7e79f75c0871595c501c0b03de64e2dea8302' ]] && pass 'historical step-186 document remains byte-identical' || fail 'historical step-186 document identity drift'
[[ $(sha "$POLICY") == '339000bc665469a5e7338e364f6543bbc355622d9f2aaf14d05bcb4b47d22e57' ]] && pass 'historical step-186 policy remains byte-identical' || fail 'historical step-186 policy identity drift'
[[ $(sha "$RECORD") == '25aadad98181e6eb92056defe740415bf23bb8ccd464b973e0fe5719d087c638' ]] && pass 'historical step-186 record remains byte-identical' || fail 'historical step-186 record identity drift'
[[ $(sha "$P185") == '3cdb3277df0e4bafa4f8f258b65feb66f2b4fe1e9b19b59f560f6c37d1fbe914' ]] && pass 'historical step-185 policy remains byte-identical' || fail 'historical step-185 policy identity drift'
[[ $(sha "$R185") == 'f717cb0ca29ee8592ab362e04c735640a07f4648860ac07e2579e3123a5d6757' ]] && pass 'historical step-185 record remains byte-identical' || fail 'historical step-185 record identity drift'
[[ $(sha "$IDOC") == '9065f59af0590afeb874499a300c21a70c4400cfd0e85c94f7947e1d7d6bb430' ]] && pass 'historical step-185 document remains byte-identical' || fail 'historical step-185 document identity drift'

bash -n "$HELPER" && pass 'historical step-186 helper is still shell-syntax valid' || fail 'historical step-186 helper shell syntax invalid'
"$HELPER" --help >/dev/null && pass 'historical step-186 helper still exposes non-mutating help' || fail 'historical step-186 helper help failed'
if "$HELPER" --definitely-unknown >/dev/null 2>&1; then
    fail 'historical step-186 helper accepted unknown option'
else
    pass 'historical step-186 helper still rejects unknown options'
fi

python3 -m json.tool "$POLICY" >/dev/null && pass 'historical step-186 policy remains valid JSON' || fail 'historical step-186 policy invalid JSON'
python3 -m json.tool "$REMEDIATION_POLICY" >/dev/null && pass 'superseding remediation policy is valid JSON' || fail 'superseding remediation policy invalid JSON'

python3 - "$POLICY" "$RECORD" "$REMEDIATION_POLICY" "$REMEDIATION_RECORD" "$BUILDER" "$EXECUTOR" "$ACCEPTANCE" "$0" <<'PYCHK'
import csv, hashlib, json, pathlib, sys
p186=json.load(open(sys.argv[1],encoding='utf-8'))
r186=dict(csv.reader(open(sys.argv[2],encoding='utf-8'),delimiter='\t'))
pr=json.load(open(sys.argv[3],encoding='utf-8'))
rr=dict(csv.reader(open(sys.argv[4],encoding='utf-8'),delimiter='\t'))
builder,executor,acceptance,harness=sys.argv[5:]
def sha(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()
checks=[
    ('historical step 186 still records accepted step 185',p186['accepted_implementation']['step']==185),
    ('historical step 186 still freezes original builder',p186['accepted_implementation']['builder_sha256']=='69846171f89a1ec0e6be3856680b6c3e8f7b6121819a9bae1d46ba69400c7578'),
    ('historical step 186 still freezes original executor',p186['accepted_implementation']['executor_sha256']=='13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326'),
    ('historical step 186 still authorizes its exact payload',p186['authorization']['runtime_scenario_execution_authorized'] is True and r186['runtime_scenario_execution_authorized']=='yes'),
    ('remediation records the accepted runtime failure',pr['accepted_runtime_failure']['status']=='failed-network' and pr['accepted_runtime_failure']['reference_exit_code']==0),
    ('remediation classification remains fail-open defect',pr['accepted_runtime_failure']['classification']=='reference-check-fail-open-on-unreachable-mirror'),
    ('remediation revision is supersession-aware',pr['remediation'].get('review_revision')=='187-r3'),
    ('current builder identity is authorized by remediation',pr['remediation']['builder_sha256']==sha(builder)),
    ('current executor identity is authorized by remediation',pr['remediation']['executor_sha256']==sha(executor)),
    ('current acceptance identity is authorized by remediation',pr['remediation']['acceptance_harness_sha256']==sha(acceptance)),
    ('current step-186 harness identity is recorded by remediation',pr['remediation']['step_186_harness_sha256']==sha(harness)),
    ('historical helper replay is explicitly unnecessary',pr['supersession']['historical_step_186_helper_replay_required'] is False),
    ('historical executor is explicitly superseded',pr['supersession']['historical_executor_sha256']=='13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326' and pr['supersession']['superseding_executor_sha256']==sha(executor)),
    ('runtime target FQDN remains frozen',pr['runtime_binding']['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'),
    ('runtime kernel remains frozen',pr['runtime_binding']['uname_release']=='6.18.45'),
    ('runtime boot-id remains frozen',pr['runtime_binding']['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'),
    ('copying current executor remains authorized',pr['authorization']['copy_executor_to_runtime_target_authorized'] is True),
    ('runtime rerun remains authorized',pr['authorization']['runtime_scenario_execution_authorized'] is True),
    ('repository refresh remains forbidden',pr['authorization']['repository_refresh_authorized'] is False),
    ('network refresh remains forbidden',pr['authorization']['network_refresh_authorized'] is False),
    ('package actions remain forbidden',pr['authorization']['package_action_authorized'] is False),
    ('boot actions remain forbidden',pr['authorization']['boot_action_authorized'] is False),
    ('reboot remains forbidden',pr['authorization']['reboot_authorized'] is False),
    ('target reboot still invalidates authorization',pr['runtime_binding']['target_reboot_invalidates_authorization'] is True),
    ('next stage remains runtime rerun',pr['next_stage']=='phase-1-execution-control-failure-paths-runtime-validation-rerun'),
    ('remediation record freezes current executor',rr['executor_sha256']==sha(executor)),
    ('remediation record identifies supersession-aware review',rr['supersession_review_revision']=='187-r3'),
    ('remediation record keeps pause unsafe',rr['pause_safe']=='no'),
]
for label,ok in checks:
    print(('PASS' if ok else 'FAIL')+': '+label)
if not all(ok for _,ok in checks):
    raise SystemExit(1)
PYCHK
rc=$?
if [[ $rc -eq 0 ]]; then
    PASS_COUNT=$((PASS_COUNT+28))
else
    FAIL_COUNT=$((FAIL_COUNT+1))
fi

if grep -Eq '(^|[;&|()[:space:]])(slackpkg[[:space:]]+(update|upgrade|install|remove)|grub-install|grub-mkconfig|eliloconfig|mkinitrd|reboot|shutdown|poweroff)([;&|()[:space:]]|$)' "$HELPER"; then
    fail 'historical step-186 helper contains forbidden package/boot mutation command'
else
    pass 'historical step-186 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '(^|[^[:alnum:]_])(curl|wget|ftp|rsync)([^[:alnum:]_]|$)' "$HELPER"; then
    fail 'historical step-186 helper contains a network client command'
else
    pass 'historical step-186 helper contains no network client command'
fi

grep -Fq '## Phase 1 step 186 execution-control runtime-executor implementation review and runtime authorization' "$CHANGELOG" && pass 'CHANGELOG preserves step 186 history' || fail 'CHANGELOG lost step 186 history'
grep -Fq '## Phase 1 step 187-r3 supersession-aware runtime authorization review fix' "$CHANGELOG" && pass 'CHANGELOG records step 187-r3' || fail 'CHANGELOG does not record step 187-r3'

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
