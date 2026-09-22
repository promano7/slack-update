#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd -P)
BUILDER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh"
EXECUTOR="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation.tsv"
AUTH_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review-policy.json"
AUTH_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.tsv"
REFERENCE="$repo_root/tools/reference/slack-update-reference.sh"
CONFIG="$repo_root/data/config/slack-update.conf"
CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0; FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular(){ [[ -f $1 && ! -L $1 ]]; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
for pair in "$BUILDER|step-185 runtime-executor builder" "$EXECUTOR|step-185 generated runtime executor" "$DOC|step-185 implementation document" "$POLICY|step-185 implementation policy" "$RECORD|step-185 implementation record" "$AUTH_POLICY|accepted step-184 authorization policy" "$AUTH_RECORD|accepted step-184 authorization record" "$REFERENCE|frozen reference script" "$CONFIG|frozen effective config"; do
    file=${pair%%|*}; label=${pair#*|}; if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done
[[ $(sha "$AUTH_POLICY") == '16ca30b51e7f2875f45587611b7d7b4bbfdaa490a1f36b1adb96d12f34df67a3' ]] && pass 'accepted step-184 authorization policy has the exact reviewed SHA-256' || fail 'step-184 authorization policy SHA-256 mismatch'
[[ $(sha "$AUTH_RECORD") == '2c366f62c26f1af7e62d574037da584365c2e17aa7e74bc489d4952b5767c762' ]] && pass 'accepted step-184 authorization record has the exact reviewed SHA-256' || fail 'step-184 authorization record SHA-256 mismatch'
[[ $(sha "$REFERENCE") == '086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea' ]] && pass 'reference script still matches the frozen SHA-256' || fail 'reference script drifted from the frozen identity'
[[ $(sha "$CONFIG") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'effective config still matches the frozen SHA-256' || fail 'effective config drifted from the frozen identity'
bash -n "$BUILDER" && pass 'step-185 builder is shell-syntax valid' || fail 'step-185 builder has invalid shell syntax'
bash -n "$EXECUTOR" && pass 'step-185 generated executor is shell-syntax valid' || fail 'step-185 generated executor has invalid shell syntax'
"$BUILDER" --help >/dev/null 2>&1 && pass 'step-185 builder exposes a non-mutating help boundary' || fail 'step-185 builder help failed'
"$EXECUTOR" --help >/dev/null 2>&1 && pass 'step-185 executor exposes a non-mutating help boundary' || fail 'step-185 executor help failed'
if "$BUILDER" --unknown >/dev/null 2>&1; then fail 'step-185 builder accepts an unknown option'; else pass 'step-185 builder rejects unknown options'; fi
if "$EXECUTOR" >/dev/null 2>&1; then fail 'step-185 executor runs without explicit acknowledgement'; else pass 'step-185 executor rejects missing runtime acknowledgement'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-185 implementation policy is valid JSON' || fail 'step-185 policy is invalid JSON'
if python3 - "$POLICY" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8')); impl=p['implementation']; auth=p['authorization']
assert p['schema']==1 and p['scenario']=='phase-1-execution-control-failure-paths-runtime-executor-implementation' and p['review_only'] is False
assert p['accepted_implementation_authorization']['step']==184
assert impl['state']=='implemented-awaiting-review' and impl['family']=='execution-control-failure-paths' and impl['scenario_count']==4
assert impl['payload_form']=='single-self-contained-shell-script' and impl['target_requires_repository'] is False and impl['runtime_acknowledgement']=='--execute-runtime-validation'
assert impl['reference_script_sha256']=='086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
assert impl['effective_config_sha256']=='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert impl['frozen_binding']['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'
assert impl['signal_exit_codes']=={'SIGINT':130,'SIGTERM':143,'SIGHUP':129} and impl['simultaneous_second_exit_code']==6 and impl['cron_maximum_wait_seconds']==90
assert impl['copy_to_target_authorized'] is False and impl['runtime_execution_authorized'] is False
assert auth['runtime_executor_implementation_review_authorized_for_next_stage'] is True
for k in ('copy_executor_to_runtime_target_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert auth[k] is False
assert p['machine_action_required'] is False and p['pause_safe'] is False
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization'
PY
then pass 'step-185 implementation policy matches the accepted authorization boundary'; else fail 'step-185 semantic policy assertions failed'; fi
for row in $'runtime_executor_implementation_state\timplemented-awaiting-review' $'payload_form\tsingle-self-contained-shell-script' $'target_requires_repository\tno' $'runtime_acknowledgement\t--execute-runtime-validation' $'boot_id\tcb85100b-9993-4876-ab32-b2457ed0ac6d' $'copy_executor_to_runtime_target_authorized\tno' $'runtime_scenario_execution_authorized\tno' $'machine_action_required\tno' $'pause_safe\tno'; do grep -Fqx "$row" "$RECORD" && pass "implementation record freezes: ${row%%$'\t'*}" || fail "implementation record missing: $row"; done
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
if "$BUILDER" --repo-root "$repo_root" --output "$tmp/executor.sh" >/dev/null 2>&1; then pass 'builder regenerates the standalone executor from the frozen inputs'; else fail 'builder failed to regenerate the standalone executor'; fi
cmp -s "$EXECUTOR" "$tmp/executor.sh" && pass 'committed executor is exactly reproducible from the builder' || fail 'committed executor differs from builder output'
extract_between(){ local begin=$1 end=$2 source=$3 dest=$4; awk -v b="$begin" -v e="$end" '$0==b{on=1;next}$0==e{exit}on{print}' "$source" | base64 -d > "$dest"; }
extract_between '__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__' '__SLACK_UPDATE_REFERENCE_PAYLOAD_END__' "$EXECUTOR" "$tmp/reference.sh"
extract_between '__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__' '__SLACK_UPDATE_CONFIG_PAYLOAD_END__' "$EXECUTOR" "$tmp/config.conf"
[[ $(sha "$tmp/reference.sh") == '086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea' ]] && pass 'executor embeds the exact frozen reference script' || fail 'embedded reference script identity mismatch'
[[ $(sha "$tmp/config.conf") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'executor embeds the exact frozen effective config' || fail 'embedded effective config identity mismatch'
for needle in "EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'" "EXPECTED_KERNEL='6.18.45'" "EXPECTED_BOOT_ID='cb85100b-9993-4876-ab32-b2457ed0ac6d'" "RUNTIME_ACK='--execute-runtime-validation'" 'unshare --net --' '--internal-lock-probe' 'INT:130 TERM:143 HUP:129' 'CRON_WAIT_SECONDS=90' 'root_crontab_restored_exactly'; do grep -Fq -- "$needle" "$EXECUTOR" && pass "executor contains reviewed contract element: $needle" || fail "executor missing reviewed contract element: $needle"; done
if grep -Eq '\b(upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$BUILDER"; then fail 'builder contains an unauthorized package, boot, reboot, or shutdown mutation command'; else pass 'builder contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$BUILDER"; then fail 'builder contains a network client command'; else pass 'builder contains no network client command'; fi
fixture="$tmp/drift-repo"; mkdir -p "$fixture/tools/reference" "$fixture/data/config"; cp -- "$REFERENCE" "$fixture/tools/reference/slack-update-reference.sh"; cp -- "$CONFIG" "$fixture/data/config/slack-update.conf"; printf '\n# drift\n' >> "$fixture/data/config/slack-update.conf"
if "$BUILDER" --repo-root "$fixture" --output "$tmp/should-not-exist.sh" >/dev/null 2>&1; then fail 'builder accepts a drifted effective config'; else pass 'builder fails closed on effective-config identity drift'; fi
if grep -Fq 'Phase 1 step 185 execution-control runtime-executor implementation' "$CHANGELOG"; then pass 'CHANGELOG records step 185'; else fail 'CHANGELOG does not record step 185'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' '); if [[ $normalized_doc == *'generated standalone runtime executor'* && $normalized_doc == *'--execute-runtime-validation'* && $normalized_doc == *'Step 186 must review the implementation'* ]]; then pass 'implementation document records payload, acknowledgement, and deferred runtime authority'; else fail 'step-185 implementation document is incomplete'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
