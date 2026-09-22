#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
REFERENCE="$repo_root/tools/reference/slack-update-reference.sh"
CONFIG="$repo_root/data/config/slack-update.conf"
BUILDER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh"
EXECUTOR="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"
ACCEPTANCE="$repo_root/tests/acceptance/reference/test-execution-control-failure-paths.sh"
AUTH_HARNESS="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization-harness.sh"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-network-failure-remediation-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-network-failure-remediation.tsv"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-network-failure-remediation.md"
CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0; FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
regular(){ [[ -f $1 && ! -L $1 ]]; }
for pair in "$REFERENCE|remediated reference script" "$CONFIG|effective config" "$BUILDER|remediated runtime-executor builder" "$EXECUTOR|remediated runtime executor" "$ACCEPTANCE|updated acceptance harness" "$AUTH_HARNESS|updated runtime-authorization harness" "$POLICY|step-187-r2 remediation policy" "$RECORD|step-187-r2 remediation record" "$DOC|step-187-r2 remediation document"; do
    file=${pair%%|*}; label=${pair#*|}
    regular "$file" && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"
done
bash -n "$REFERENCE" && pass 'remediated reference script is shell-syntax valid' || fail 'remediated reference script has invalid shell syntax'
bash -n "$BUILDER" && pass 'remediated builder is shell-syntax valid' || fail 'remediated builder has invalid shell syntax'
bash -n "$EXECUTOR" && pass 'remediated executor is shell-syntax valid' || fail 'remediated executor has invalid shell syntax'
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-187-r2 remediation policy is valid JSON' || fail 'step-187-r2 remediation policy is invalid JSON'
python3 - "$POLICY" "$RECORD" "$REFERENCE" "$BUILDER" "$EXECUTOR" "$ACCEPTANCE" <<'PY'
import csv, hashlib, json, pathlib, sys
policy_path, record_path, reference, builder, executor, acceptance = sys.argv[1:]
policy=json.load(open(policy_path,encoding='utf-8'))
record=dict(csv.reader(open(record_path,encoding='utf-8'),delimiter='\t'))
def sha(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()
checks=[
 ('runtime failure is recorded', policy['accepted_runtime_failure']['status']=='failed-network' and policy['accepted_runtime_failure']['reference_exit_code']==0),
 ('failure is classified fail-open', policy['accepted_runtime_failure']['classification']=='reference-check-fail-open-on-unreachable-mirror'),
 ('reference identity is current', policy['remediation']['reference_script_sha256']==sha(reference)),
 ('builder identity is current', policy['remediation']['builder_sha256']==sha(builder)),
 ('executor identity is current', policy['remediation']['executor_sha256']==sha(executor)),
 ('acceptance identity is current', policy['remediation']['acceptance_harness_sha256']==sha(acceptance)),
 ('same FQDN remains bound', policy['runtime_binding']['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'),
 ('same kernel remains bound', policy['runtime_binding']['uname_release']=='6.18.45'),
 ('same boot-id remains bound', policy['runtime_binding']['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'),
 ('copy of remediated executor is authorized', policy['authorization']['copy_executor_to_runtime_target_authorized'] is True),
 ('runtime rerun is authorized', policy['authorization']['runtime_scenario_execution_authorized'] is True),
 ('repository refresh remains forbidden', policy['authorization']['repository_refresh_authorized'] is False),
 ('package action remains forbidden', policy['authorization']['package_action_authorized'] is False),
 ('boot action remains forbidden', policy['authorization']['boot_action_authorized'] is False),
 ('reboot remains forbidden', policy['authorization']['reboot_authorized'] is False),
 ('next stage is runtime rerun', policy['next_stage']=='phase-1-execution-control-failure-paths-runtime-validation-rerun'),
 ('record freezes new executor identity', record['executor_sha256']==sha(executor)),
 ('record keeps pause unsafe', record['pause_safe']=='no')]
for label, ok in checks:
    print(('PASS' if ok else 'FAIL')+': '+label)
if not all(ok for _,ok in checks): raise SystemExit(1)
PY
rc=$?; if [[ $rc -eq 0 ]]; then PASS_COUNT=$((PASS_COUNT+18)); else FAIL_COUNT=$((FAIL_COUNT+1)); fi
for needle in 'SLACKPKG_MIRRORS_FILE=/etc/slackpkg/mirrors' 'probe_slackpkg_mirror_changelog() {' 'wget --spider --quiet' 'CHECK_STATUS=69' 'configured Slackware mirror ChangeLog is unreachable'; do
    grep -Fq -- "$needle" "$REFERENCE" && pass "reference contains fail-closed element: $needle" || fail "reference misses fail-closed element: $needle"
done
# Source the reference as a library. Its guarded entry point must not execute.
# Mock shell functions are then used to exercise the exact remediated functions.
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/local-mirror"
printf 'fixture\n' > "$tmp/local-mirror/ChangeLog.txt"
printf 'https://mirror.invalid/slackware64-current/\n' > "$tmp/mirrors"
if REFERENCE="$REFERENCE" MIRRORS="$tmp/mirrors" bash <<'BASH'
set -uo pipefail
source "$REFERENCE"
SLACKPKG_MIRRORS_FILE=$MIRRORS
SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS=1
SLACKPKG_CALLED=0
slackpkg(){ SLACKPKG_CALLED=1; return 0; }
wget(){ return 4; }
set +e
check_slackware_updates >/tmp/step187-r2-network.out 2>&1
rc=$?
set -e
[[ $rc -ne 0 && ${CHECK_STATUS:-0} -eq 69 && $SLACKPKG_CALLED -eq 0 ]]
[[ ${CHECK_ERROR:-} == *unreachable* ]]
BASH
then pass 'unreachable mirror fails closed before slackpkg can return false success'; else fail 'unreachable mirror regression simulation failed'; fi
if REFERENCE="$REFERENCE" MIRRORS="$tmp/mirrors" bash <<'BASH'
set -uo pipefail
source "$REFERENCE"
SLACKPKG_MIRRORS_FILE=$MIRRORS
SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS=1
SLACKPKG_CALLED=0
slackpkg(){ SLACKPKG_CALLED=1; return 0; }
wget(){ return 0; }
check_slackware_updates >/dev/null
[[ ${CHECK_STATUS:-99} -eq 0 && $SLACKPKG_CALLED -eq 1 && -z ${CHECK_ERROR:-} ]]
BASH
then pass 'reachable mirror preserves normal no-update success'; else fail 'reachable no-update simulation failed'; fi
if REFERENCE="$REFERENCE" MIRRORS="$tmp/mirrors" bash <<'BASH'
set -uo pipefail
source "$REFERENCE"
SLACKPKG_MIRRORS_FILE=$MIRRORS
SLACKPKG_MIRROR_PROBE_TIMEOUT_SECONDS=1
slackpkg(){ return 100; }
wget(){ return 0; }
check_slackware_updates >/dev/null
[[ ${CHECK_STATUS:-0} -eq 100 ]]
BASH
then pass 'reachable mirror preserves update-available status 100'; else fail 'reachable update simulation failed'; fi
printf '%s\n' "$tmp/local-mirror" > "$tmp/local-mirrors"
if REFERENCE="$REFERENCE" MIRRORS="$tmp/local-mirrors" bash <<'BASH'
set -uo pipefail
source "$REFERENCE"
SLACKPKG_MIRRORS_FILE=$MIRRORS
slackpkg(){ return 0; }
wget(){ return 99; }
check_slackware_updates >/dev/null
[[ ${CHECK_STATUS:-99} -eq 0 ]]
BASH
then pass 'local mirror probe does not require network'; else fail 'local mirror probe failed'; fi
printf 'https://one.invalid/\nhttps://two.invalid/\n' > "$tmp/multiple-mirrors"
if REFERENCE="$REFERENCE" MIRRORS="$tmp/multiple-mirrors" bash <<'BASH'
set -uo pipefail
source "$REFERENCE"
SLACKPKG_MIRRORS_FILE=$MIRRORS
SLACKPKG_CALLED=0
slackpkg(){ SLACKPKG_CALLED=1; return 0; }
wget(){ return 0; }
set +e
check_slackware_updates >/dev/null
rc=$?
set -e
[[ $rc -ne 0 && ${CHECK_STATUS:-0} -eq 69 && $SLACKPKG_CALLED -eq 0 ]]
BASH
then pass 'ambiguous multiple-mirror configuration fails closed'; else fail 'multiple-mirror fail-closed simulation failed'; fi
expected_reference=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["remediation"]["reference_script_sha256"])' "$POLICY")
expected_executor=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["remediation"]["executor_sha256"])' "$POLICY")
grep -Fq "EXPECTED_REFERENCE_SHA256='$expected_reference'" "$BUILDER" && pass 'builder freezes remediated reference identity' || fail 'builder does not freeze remediated reference identity'
[[ $(sha "$EXECUTOR") == "$expected_executor" ]] && pass 'committed executor matches remediation authorization identity' || fail 'executor identity differs from remediation policy'
regen="$tmp/executor.sh"
if "$BUILDER" --repo-root "$repo_root" --output "$regen" >/dev/null 2>&1 && cmp -s "$regen" "$EXECUTOR"; then pass 'remediated executor is exactly reproducible'; else fail 'remediated executor is not reproducible'; fi
if bash "$ACCEPTANCE" >/dev/null; then pass 'step-185 acceptance harness remains green after superseding remediation'; else fail 'step-185 acceptance harness regressed after remediation'; fi
if bash "$AUTH_HARNESS" >/dev/null; then pass 'step-186 authorization harness remains green after superseding remediation'; else fail 'step-186 authorization harness regressed after remediation'; fi
if grep -Fq '## Phase 1 step 187-r2 network-failure fail-closed remediation and runtime reauthorization' "$CHANGELOG"; then pass 'CHANGELOG records step 187-r2'; else fail 'CHANGELOG does not record step 187-r2'; fi
if grep -Fq 'slackpkg check-updates returned exit code 0 while the target network namespace had no usable network' "$DOC"; then pass 'remediation document records the observed runtime failure'; else fail 'remediation document misses observed runtime failure'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && echo PASS || echo FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
