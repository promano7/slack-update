#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
APPLY_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-normal-update-authorized-apply.sh"

# Source reviewed helpers without running the real transaction.
# shellcheck source=../acceptance/reference/test-current-normal-update-authorized-apply.sh
source "$APPLY_SCRIPT"

TEST_COUNT=0
TEST_FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local m=$1; shift; if "$@" >/dev/null 2>&1; then pass; else fail "$m"; fi; }
assert_failure() { local m=$1; shift; if "$@" >/dev/null 2>&1; then fail "$m"; else pass; fi; }
assert_contains() { local p=$1 f=$2 m=$3; grep -Fq -- "$p" "$f" && pass || fail "$m"; }
assert_not_contains() { local p=$1 f=$2 m=$3; grep -Fq -- "$p" "$f" && fail "$m" || pass; }
assert_equal() { local e=$1 a=$2 m=$3; [ "$e" = "$a" ] && pass || fail "$m (expected $e, got $a)"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_contains '--execute-authorized-apply' "$APPLY_SCRIPT" 'the wrapper should require an explicit execution option'
assert_contains '--confirm-authorization-sha256' "$APPLY_SCRIPT" 'the wrapper should require the exact authorization scope digest'
assert_contains '--confirm-hostname-fqdn' "$APPLY_SCRIPT" 'the wrapper should require an explicit reviewed FQDN'
assert_contains '--confirm-hostname "$HOSTNAME_FQDN"' "$APPLY_SCRIPT" 'the child normal-update apply should receive the verified FQDN'
assert_contains '--confirm-readiness-sha256' "$APPLY_SCRIPT" 'the wrapper should bind the accepted readiness archive'
assert_contains 'Running final candidate revalidation' "$APPLY_SCRIPT" 'the wrapper should announce final revalidation immediately before apply'
assert_contains '--execute-apply' "$APPLY_SCRIPT" 'the wrapper should invoke the existing real apply acceptance mode'
assert_contains '--allow-kernel-update' "$APPLY_SCRIPT" 'the wrapper should explicitly allow the reviewed kernel transaction'
assert_not_contains '--allow-critical-update' "$APPLY_SCRIPT" 'the zero-critical transaction should not authorize critical updates'
assert_contains 'pause_safe=true' "$APPLY_SCRIPT" 'only a complete transaction should expose pause safety'
assert_contains 'reviewed-package-transaction-complete-and-boot-artifacts-validated' "$APPLY_SCRIPT" 'pause safety should have a precise reason'
assert_contains 'manual-recovery-review-required' "$APPLY_SCRIPT" 'partial or failed apply should route to manual recovery'
assert_contains '/boot/vmlinuz-6.18.40' "$APPLY_SCRIPT" 'the wrapper should preserve the old kernel rollback artifact'
assert_contains '/boot/initrd-6.18.40.img' "$APPLY_SCRIPT" 'the wrapper should preserve the old initrd rollback artifact'
assert_contains 'sha256sum /etc/default/geninitrd' "$APPLY_SCRIPT" 'the restored GenInitrd policy should be verified by digest'
assert_contains 'nested normal-update apply archive' "$APPLY_SCRIPT" 'the child evidence should be verified inside the parent evidence'
assert_contains 'BOOT_CMDLINE_FILE=/proc/cmdline' "$NORMAL_UPDATE_SCRIPT" 'the real acceptance boundary should initialize the live boot command-line source before invoking the accepted engine'
assert_contains 'reference_engine_sha256={reference_digest}' "$APPLY_SCRIPT" 'the authorization scope should bind the exact reference engine digest'
assert_contains 'normal_update_acceptance_sha256={normal_digest}' "$APPLY_SCRIPT" 'the authorization scope should bind the exact normal-update acceptance digest'
assert_contains 'authorized_apply_wrapper_sha256={authorized_apply_digest}' "$APPLY_SCRIPT" 'the authorization scope should bind the exact authorized-apply wrapper digest'
assert_contains 'Copy evidence command:' "$APPLY_SCRIPT" 'the wrapper should print direct /home evidence copy commands'
assert_contains 'Verify evidence command:' "$APPLY_SCRIPT" 'the wrapper should print destination-side verification'

reset_args() {
    TARGET= OUTPUT_DIR= CONFIRM_HOSTNAME= CONFIRM_HOSTNAME_FQDN= CONFIRM_CANDIDATES_SHA256= CONFIRM_TARGET_KERNEL=
    CONFIRM_READINESS_SHA256= CONFIRM_AUTHORIZATION_SHA256= EXECUTE_AUTHORIZED_APPLY=0
}
reset_args
assert_failure 'missing explicit execution should fail argument parsing' parse_arguments \
    --target slackware-current --confirm-hostname pcold-slack \
    --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42 \
    --confirm-readiness-sha256 d49af0c2f95f6ceaaa6f4073a5567b914f53ee9605724f78fea4a30afc463783 \
    --confirm-authorization-sha256 539ba5135c0e38c62627f230cae374753f9a8e34c049790547629d74bb076cce
reset_args
assert_failure 'a malformed candidate digest should fail parsing' parse_arguments \
    --target slackware-current --execute-authorized-apply --confirm-hostname pcold-slack \
    --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
    --confirm-candidates-sha256 invalid --confirm-target-kernel 6.18.42 \
    --confirm-readiness-sha256 d49af0c2f95f6ceaaa6f4073a5567b914f53ee9605724f78fea4a30afc463783 \
    --confirm-authorization-sha256 539ba5135c0e38c62627f230cae374753f9a8e34c049790547629d74bb076cce
reset_args
assert_failure 'a relative evidence path should fail parsing' parse_arguments \
    --target slackware-current --execute-authorized-apply --confirm-hostname pcold-slack \
    --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42 \
    --confirm-readiness-sha256 d49af0c2f95f6ceaaa6f4073a5567b914f53ee9605724f78fea4a30afc463783 \
    --confirm-authorization-sha256 539ba5135c0e38c62627f230cae374753f9a8e34c049790547629d74bb076cce \
    --output-dir relative
reset_args
assert_success 'the exact reviewed authorization arguments should parse' parse_arguments \
    --target slackware-current --execute-authorized-apply --confirm-hostname pcold-slack \
    --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42 \
    --confirm-readiness-sha256 d49af0c2f95f6ceaaa6f4073a5567b914f53ee9605724f78fea4a30afc463783 \
    --confirm-authorization-sha256 539ba5135c0e38c62627f230cae374753f9a8e34c049790547629d74bb076cce \
    --output-dir "$TMP/out"
assert_equal slackware-current "$TARGET" 'the target should be preserved'
assert_equal pcold-slack "$CONFIRM_HOSTNAME" 'the short hostname should be preserved'
assert_equal pcold-slack.pcold-slack.org "$CONFIRM_HOSTNAME_FQDN" 'the FQDN should be preserved'
assert_equal 6.18.42 "$CONFIRM_TARGET_KERNEL" 'the target kernel should be preserved'
assert_equal 1 "$EXECUTE_AUTHORIZED_APPLY" 'the explicit execution count should be one'
assert_equal "$TMP/out" "$OUTPUT_DIR" 'the absolute output directory should be preserved'

assert_success 'the exact accepted readiness and policy should validate' validate_reviewed_authorization

mutate_json() {
    local source=$1 output=$2 code=$3
    python3 - "$source" "$output" "$code" <<'PY'
import json,sys
source,output,code=sys.argv[1:]
d=json.load(open(source,encoding='utf-8'))
exec(code,{}, {'d':d})
json.dump(d,open(output,'w',encoding='utf-8'),indent=2,sort_keys=True)
PY
}

original_readiness=$READINESS_RECORD
mutate_json "$original_readiness" "$TMP/readiness-hash.json" "d['archive_sha256']='0'*64"
READINESS_RECORD="$TMP/readiness-hash.json"
assert_failure 'a changed readiness archive digest should fail authorization' validate_reviewed_authorization
READINESS_RECORD=$original_readiness
mutate_json "$original_readiness" "$TMP/readiness-candidate.json" "d['candidate_set_sha256']='0'*64"
READINESS_RECORD="$TMP/readiness-candidate.json"
assert_failure 'a changed readiness candidate digest should fail authorization' validate_reviewed_authorization
READINESS_RECORD=$original_readiness
mutate_json "$original_readiness" "$TMP/readiness-ready.json" "d['apply_ready']=False"
READINESS_RECORD="$TMP/readiness-ready.json"
assert_failure 'a non-ready record should fail authorization' validate_reviewed_authorization
READINESS_RECORD=$original_readiness
mutate_json "$original_readiness" "$TMP/readiness-pause.json" "d['pause_safe']=True"
READINESS_RECORD="$TMP/readiness-pause.json"
assert_failure 'a readiness record falsely marked pause-safe should fail authorization' validate_reviewed_authorization
READINESS_RECORD=$original_readiness
mutate_json "$original_readiness" "$TMP/readiness-stage.json" "d['next_stage']='current-kernel-post-apply-verification'"
READINESS_RECORD="$TMP/readiness-stage.json"
assert_failure 'an unexpected readiness next stage should fail authorization' validate_reviewed_authorization
READINESS_RECORD=$original_readiness

original_policy=$AUTHORIZATION_POLICY
for item in \
    "hostname-short:d['required_hostname_short']='other-host'" \
    "hostname-fqdn:d['required_hostname_fqdn']='other.example'" \
    "scope:d['authorization_scope_sha256']='0'*64" \
    "engine:d['reference_engine_sha256']='0'*64" \
    "acceptance:d['normal_update_acceptance_sha256']='0'*64" \
    "wrapper:d['authorized_apply_wrapper_sha256']='0'*64" \
    "critical:d['critical_update_authorized']=True" \
    "postinstall:d['postinstall_processing_enabled']=True" \
    "exit:d['expected_exit_code']=0" \
    "pause:d['pause_safe_after_successful_apply']=False" \
    "scope-code:d['authorization_scope_binds_code_hashes']=False"; do
    name=${item%%:*}; code=${item#*:}
    mutate_json "$original_policy" "$TMP/policy-$name.json" "$code"
    AUTHORIZATION_POLICY="$TMP/policy-$name.json"
    assert_failure "a changed $name policy field should fail authorization" validate_reviewed_authorization
done
AUTHORIZATION_POLICY=$original_policy


HOSTNAME_SHORT=pcold-slack
HOSTNAME_FQDN=pcold-slack.pcold-slack.org
assert_success 'the exact short hostname and FQDN should validate as one host identity' validate_live_host_identity
HOSTNAME_SHORT=other-host
assert_failure 'a changed short hostname should fail host identity validation' validate_live_host_identity
HOSTNAME_SHORT=pcold-slack
HOSTNAME_FQDN=other.example
assert_failure 'a changed FQDN should fail host identity validation' validate_live_host_identity
HOSTNAME_FQDN=pcold-slack.pcold-slack.org
if declare -f validate_live_pre_state | grep -Fq 'HOSTNAME_'; then
    fail 'boot-state validation should not duplicate host identity validation'
else
    pass
fi

CHILD="$TMP/child"
mkdir -p "$CHILD"
cat > "$CHILD/summary.txt" <<'EOF_SUMMARY'
scenario=normal-update
mode=apply
target=slackware-current
result=PASS
passes=11
failures=0
install_new_candidates=1
upgrade_candidates=136
total_candidates=137
candidate_set_sha256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
kernel_candidates=2
critical_candidates=0
metadata_update_exit_code=0
apply_exit_code=5
EOF_SUMMARY
python3 - "$CHILD/apply.json" <<'PY'
import json,sys
boot={
 'mode':'auto','state':'success','initrd_required':True,'initrd_state':'success',
 'grub_required':True,'grub_state':'success','geninitrd_policy_override_required':True,
 'geninitrd_policy_override_applied':True,'geninitrd_policy_override_restored':True,
 'geninitrd_policy_override_active':False,'geninitrd_policy_override_status':'restored',
 'geninitrd_post_state':'generated-initrd','geninitrd_post_kernel_version':'6.18.42',
 'geninitrd_post_kernel_path':'/boot/vmlinuz-6.18.42','geninitrd_post_modules_path':'/lib/modules/6.18.42',
 'geninitrd_post_initrd_path':'/boot/initrd-6.18.42.img','geninitrd_post_named_link':'/boot/initrd-generic.img',
 'grub_command_attempted':True,'grub_config_replaced':True,'grub_blocked_by_initrd':False}
slack={'state':'success','update_exit_code':0,'install_new_exit_code':0,'upgrade_all_exit_code':0,
 'postinstall_policy':'defer','postinstall_processing_enabled':False,'pending_new_config_files_valid':True,
 'snapshot_before_valid':True,'snapshot_after_valid':True,'secondary_modules_blocked':False,'kernel_changes':True}
data={'operation':'apply','success':True,'partial':False,'boot_safe':True,'exit_code':5,'reboot':'required',
 'errors':[],'modules':{'slackware':slack,'boot':boot}}
json.dump(data,open(sys.argv[1],'w'),indent=2,sort_keys=True)
PY
assert_success 'an exact synthetic successful child apply should validate' validate_child_apply "$CHILD"

mutate_apply() {
    local name=$1 code=$2
    cp "$CHILD/apply.json" "$TMP/apply-$name.json"
    python3 - "$TMP/apply-$name.json" "$code" <<'PY'
import json,sys
p,code=sys.argv[1:]
d=json.load(open(p))
exec(code,{}, {'d':d})
json.dump(d,open(p,'w'),indent=2,sort_keys=True)
PY
    mv "$CHILD/apply.json" "$TMP/apply-good.json"
    cp "$TMP/apply-$name.json" "$CHILD/apply.json"
    assert_failure "a changed child $name field should fail closed" validate_child_apply "$CHILD"
    mv "$TMP/apply-good.json" "$CHILD/apply.json"
}

mutate_apply success "d['success']=False"
mutate_apply partial "d['partial']=True"
mutate_apply boot-safe "d['boot_safe']=False"
mutate_apply exit "d['exit_code']=0"
mutate_apply reboot "d['reboot']='none'"
mutate_apply errors "d['errors']=['failure']"
mutate_apply package-state "d['modules']['slackware']['state']='failed'"
mutate_apply postinstall "d['modules']['slackware']['postinstall_policy']='interactive'"
mutate_apply postinstall-enabled "d['modules']['slackware']['postinstall_processing_enabled']=True"
mutate_apply snapshot "d['modules']['slackware']['snapshot_after_valid']=False"
mutate_apply secondary "d['modules']['slackware']['secondary_modules_blocked']=True"
mutate_apply kernel-trigger "d['modules']['slackware']['kernel_changes']=False"
mutate_apply boot-mode "d['modules']['boot']['mode']='disabled'"
mutate_apply boot-state "d['modules']['boot']['state']='failed'"
mutate_apply initrd "d['modules']['boot']['initrd_state']='failed'"
mutate_apply grub "d['modules']['boot']['grub_state']='failed'"
mutate_apply policy-restored "d['modules']['boot']['geninitrd_policy_override_restored']=False"
mutate_apply policy-active "d['modules']['boot']['geninitrd_policy_override_active']=True"
mutate_apply post-state "d['modules']['boot']['geninitrd_post_state']='invalid'"
mutate_apply target-kernel "d['modules']['boot']['geninitrd_post_kernel_version']='6.18.43'"
mutate_apply target-initrd "d['modules']['boot']['geninitrd_post_initrd_path']='/boot/initrd-6.18.43.img'"
mutate_apply grub-replace "d['modules']['boot']['grub_config_replaced']=False"

cp "$CHILD/summary.txt" "$TMP/summary-good.txt"
sed -i 's/total_candidates=137/total_candidates=138/' "$CHILD/summary.txt"
assert_failure 'a changed child candidate count should fail closed' validate_child_apply "$CHILD"
cp "$TMP/summary-good.txt" "$CHILD/summary.txt"
sed -i 's/candidate_set_sha256=.*/candidate_set_sha256=0000000000000000000000000000000000000000000000000000000000000000/' "$CHILD/summary.txt"
assert_failure 'a changed child candidate digest should fail closed' validate_child_apply "$CHILD"
cp "$TMP/summary-good.txt" "$CHILD/summary.txt"

mkdir -p "$TMP/archive-dir/payload"
printf 'fixture\n' > "$TMP/archive-dir/payload/file"
tar -C "$TMP/archive-dir" -czf "$TMP/archive-dir/payload.tar.gz" payload
(cd "$TMP/archive-dir" && sha256sum payload.tar.gz > payload.tar.gz.sha256)
assert_success 'a portable nested archive should verify' verify_nested_archive "$TMP/archive-dir/payload.tar.gz"
printf 'tamper\n' >> "$TMP/archive-dir/payload.tar.gz"
assert_failure 'a changed nested archive should fail verification' verify_nested_archive "$TMP/archive-dir/payload.tar.gz"

OUTPUT_DIR="$TMP/evidence"
mkdir -p "$OUTPUT_DIR"
TARGET=slackware-current
HOSTNAME_SHORT=pcold-slack
HOSTNAME_FQDN=pcold-slack.pcold-slack.org
RUNNING_KERNEL_BEFORE=6.18.40
RUNNING_KERNEL_AFTER=6.18.40
TRANSACTION_STATUS=applied-and-boot-prepared
CHILD_STATUS=0
PAUSE_SAFE=true
PAUSE_SAFETY_REASON=reviewed-package-transaction-complete-and-boot-artifacts-validated
APPLY_READY=true
APPLY_AUTHORIZED=true
NEXT_STAGE=current-kernel-post-apply-verification
PASS_COUNT=16
FAILURE_COUNT=0
write_analysis
write_summary
assert_equal true "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["pause_safe"]).lower())' "$OUTPUT_DIR/authorization-analysis.json")" 'analysis should record safe pause after success'
assert_equal true "$(python3 -c 'import json,sys; print(str(json.load(open(sys.argv[1]))["apply_authorized"]).lower())' "$OUTPUT_DIR/authorization-analysis.json")" 'analysis should record explicit authorization'
assert_equal pcold-slack "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hostname_short"])' "$OUTPUT_DIR/authorization-analysis.json")" 'analysis should record the verified short hostname'
assert_equal pcold-slack.pcold-slack.org "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hostname_fqdn"])' "$OUTPUT_DIR/authorization-analysis.json")" 'analysis should record the verified FQDN'
assert_contains 'transaction_status=applied-and-boot-prepared' "$OUTPUT_DIR/summary.txt" 'summary should expose completed transaction status'
assert_contains 'pause_safe=true' "$OUTPUT_DIR/summary.txt" 'summary should expose pause safety'
assert_contains 'next_stage=current-kernel-post-apply-verification' "$OUTPUT_DIR/summary.txt" 'summary should route to post-apply verification'

printf 'Slackware-current normal-update authorized apply harness: %s checks, %s failures\n' "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
