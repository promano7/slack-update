#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.sh"; DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.md"; POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization-policy.json"; RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.tsv"
P185="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-policy.json"; R185="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation.tsv"; BUILDER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh"; EXECUTOR="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"; ACCEPTANCE="$repo_root/tests/acceptance/reference/test-execution-control-failure-paths.sh"; IDOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation.md"; CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0; FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
for pair in "$HELPER|step-186 review helper" "$DOC|step-186 reference document" "$POLICY|step-186 runtime-authorization policy" "$RECORD|step-186 runtime-authorization record" "$P185|accepted step-185 implementation policy" "$R185|accepted step-185 implementation record" "$BUILDER|accepted step-185 builder" "$EXECUTOR|accepted step-185 generated executor" "$ACCEPTANCE|accepted step-185 acceptance harness" "$IDOC|accepted step-185 implementation document"; do
 f=${pair%%|*}; label=${pair#*|}; regular "$f" && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"; done
[[ $(sha "$HELPER") == '17413c6e3af5307c1fea327abd612dd74094cfcb8ca96c7f84b88d1c2c7b233b' ]] && pass 'step-186 helper has the exact reviewed SHA-256' || fail 'step-186 helper SHA-256 mismatch'
[[ $(sha "$DOC") == 'ffa16401ecd46605a2b3e02187c7e79f75c0871595c501c0b03de64e2dea8302' ]] && pass 'step-186 document has the exact reviewed SHA-256' || fail 'step-186 document SHA-256 mismatch'
[[ $(sha "$POLICY") == '339000bc665469a5e7338e364f6543bbc355622d9f2aaf14d05bcb4b47d22e57' ]] && pass 'step-186 policy has the exact reviewed SHA-256' || fail 'step-186 policy SHA-256 mismatch'
[[ $(sha "$RECORD") == '25aadad98181e6eb92056defe740415bf23bb8ccd464b973e0fe5719d087c638' ]] && pass 'step-186 record has the exact reviewed SHA-256' || fail 'step-186 record SHA-256 mismatch'
[[ $(sha "$P185") == '3cdb3277df0e4bafa4f8f258b65feb66f2b4fe1e9b19b59f560f6c37d1fbe914' ]] && pass 'accepted step-185 implementation policy has the exact reviewed SHA-256' || fail 'step-185 policy SHA-256 mismatch'
[[ $(sha "$R185") == 'f717cb0ca29ee8592ab362e04c735640a07f4648860ac07e2579e3123a5d6757' ]] && pass 'accepted step-185 implementation record has the exact reviewed SHA-256' || fail 'step-185 record SHA-256 mismatch'
[[ $(sha "$BUILDER") == '69846171f89a1ec0e6be3856680b6c3e8f7b6121819a9bae1d46ba69400c7578' ]] && pass 'step-185 builder identity is frozen' || fail 'step-185 builder identity drift'
[[ $(sha "$EXECUTOR") == '13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326' ]] && pass 'step-185 executor identity is frozen' || fail 'step-185 executor identity drift'
[[ $(sha "$ACCEPTANCE") == '5414d18212118ddd72c0bc0a701449c416ac3f8dd3b4689ca48ed8da948bfedf' ]] && pass 'step-185 acceptance harness identity is frozen' || fail 'step-185 acceptance harness identity drift'
[[ $(sha "$IDOC") == '9065f59af0590afeb874499a300c21a70c4400cfd0e85c94f7947e1d7d6bb430' ]] && pass 'step-185 implementation document identity is frozen' || fail 'step-185 implementation document identity drift'
bash -n "$HELPER" && pass 'step-186 helper is shell-syntax valid' || fail 'step-186 helper shell syntax invalid'
"$HELPER" --help >/dev/null && pass 'step-186 helper exposes a non-mutating help boundary' || fail 'step-186 helper help failed'
if "$HELPER" --definitely-unknown >/dev/null 2>&1; then fail 'step-186 helper accepted unknown option'; else pass 'step-186 helper rejects unknown options'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-186 runtime-authorization policy is valid JSON' || fail 'step-186 runtime-authorization policy invalid JSON'
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
if "$HELPER" --output-dir "$tmp" >/dev/null; then pass 'step-186 implementation review and runtime authorization completed successfully'; else fail 'step-186 helper execution failed'; fi
cmp -s "$tmp/$(basename "$POLICY")" "$POLICY" && pass 'step-186 helper reproduces the frozen policy exactly' || fail 'step-186 policy reproduction mismatch'
cmp -s "$tmp/$(basename "$RECORD")" "$RECORD" && pass 'step-186 helper reproduces the frozen record exactly' || fail 'step-186 record reproduction mismatch'
python3 - "$POLICY" "$RECORD" <<'PYCHK'
import csv,json,sys
p=json.load(open(sys.argv[1])); r=dict(csv.reader(open(sys.argv[2]),delimiter='\t'))
checks=[
('review accepts step 185',p['accepted_implementation']['step']==185),
('repository acceptance result is frozen',p['accepted_implementation']['repository_acceptance_result']=='PASS (48 passes, 0 failures)'),
('builder SHA-256 is frozen',p['accepted_implementation']['builder_sha256']=='69846171f89a1ec0e6be3856680b6c3e8f7b6121819a9bae1d46ba69400c7578'),
('executor SHA-256 is frozen',p['accepted_implementation']['executor_sha256']=='13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326'),
('runtime target FQDN remains frozen',p['runtime_authorization']['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'),
('runtime kernel remains frozen',p['runtime_authorization']['uname_release']=='6.18.45'),
('runtime boot-id remains frozen',p['runtime_authorization']['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'),
('runtime acknowledgement remains explicit',p['runtime_authorization']['runtime_acknowledgement']=='--execute-runtime-validation'),
('target repository remains unnecessary',p['runtime_authorization']['target_requires_repository'] is False),
('copying exact executor is authorized',p['authorization']['copy_executor_to_runtime_target_authorized'] is True),
('runtime scenario execution is authorized',p['authorization']['runtime_scenario_execution_authorized'] is True),
('target SHA-256 verification is required',p['runtime_authorization']['target_sha256_verification_required_before_execution'] is True),
('executor must revalidate binding',p['runtime_authorization']['binding_must_be_revalidated_by_executor_before_first_scenario'] is True),
('target reboot invalidates authorization',p['runtime_authorization']['target_reboot_invalidates_authorization'] is True),
('repository refresh remains forbidden',p['authorization']['repository_refresh_authorized'] is False),
('network refresh remains forbidden',p['authorization']['network_refresh_authorized'] is False),
('package actions remain forbidden',p['authorization']['package_action_authorized'] is False),
('boot actions remain forbidden',p['authorization']['boot_action_authorized'] is False),
('reboot remains forbidden',p['authorization']['reboot_authorized'] is False),
('temporary cron mutation is tightly scoped',p['scenario_safety_contract']['temporary_root_crontab_change_authorized_only_inside_cron_scenario'] is True),
('exact cron restoration is mandatory',p['scenario_safety_contract']['root_crontab_exact_restoration_required'] is True),
('post-execution review is required',p['runtime_authorization']['post_execution_review_required'] is True),
('next stage is runtime validation',p['next_stage']=='phase-1-execution-control-failure-paths-runtime-validation'),
('step 186 is not a safe pause',p['pause_safe'] is False),
('record freezes runtime authorization',r['runtime_authorization_state']=='authorized-exact-payload-on-exact-binding'),
('record authorizes runtime execution',r['runtime_scenario_execution_authorized']=='yes')]
for label,ok in checks: print(('PASS' if ok else 'FAIL')+': '+label)
if not all(ok for _,ok in checks): raise SystemExit(1)
PYCHK
rc=$?; if [[ $rc -eq 0 ]]; then PASS_COUNT=$((PASS_COUNT+26)); else FAIL_COUNT=$((FAIL_COUNT+1)); fi
if grep -Eq '(^|[;&|()[:space:]])(slackpkg[[:space:]]+(update|upgrade|install|remove)|grub-install|grub-mkconfig|eliloconfig|mkinitrd|reboot|shutdown|poweroff)([;&|()[:space:]]|$)' "$HELPER"; then fail 'step-186 helper contains forbidden package/boot mutation command'; else pass 'step-186 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '(^|[^[:alnum:]_])(curl|wget|ftp|rsync)([^[:alnum:]_]|$)' "$HELPER"; then fail 'step-186 helper contains a network client command'; else pass 'step-186 helper contains no network client command'; fi
grep -Fq '## Phase 1 step 186 execution-control runtime-executor implementation review and runtime authorization' "$CHANGELOG" && pass 'CHANGELOG records step 186' || fail 'CHANGELOG does not record step 186'
grep -Fq '13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326' "$DOC" && pass 'reference document records exact executor identity and runtime boundary' || fail 'reference document misses exact executor identity'
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
