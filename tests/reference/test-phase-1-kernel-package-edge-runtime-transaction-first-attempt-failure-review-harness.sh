#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.tsv"
step217_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.sh"
step217_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.md"
step217_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-harness.sh"
step217_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json"
step217_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_regular() { local p=$1 n=$2; [[ -f $p && ! -L $p ]] && pass "$n is a regular non-symlink file" || fail "$n is a regular non-symlink file"; }
check_sha() { local p=$1 expected=$2 n=$3 actual; actual=$(sha256sum -- "$p" | awk '{print $1}'); [[ $actual == $expected ]] && pass "$n hash is frozen" || fail "$n hash is frozen"; }

for spec in   "$helper|step-218 review helper"   "$probe|step-218 failure probe"   "$doc|step-218 reference document"   "$policy|step-218 policy"   "$record|step-218 record"   "$step217_helper|accepted step-217 helper"   "$step217_doc|accepted step-217 document"   "$step217_harness|accepted step-217 harness"   "$step217_policy|accepted step-217 policy"   "$step217_record|accepted step-217 record"   "$executor|authorized step-217 executor"; do
    p=${spec%%|*}; n=${spec#*|}; check_regular "$p" "$n"
done

check_sha "$step217_helper" '737b47787883ebf99f5d306602b8ad1e0d3da5fcf105475e80eece878281768f' 'accepted step-217 helper'
check_sha "$step217_doc" '81809719126afb5e8aca5b63a20b6e8ea2e9c27146bd5febdd56da06f747f6fa' 'accepted step-217 document'
check_sha "$step217_harness" '6b1fa1baad11a67aa6453db2806a636ccc77877e69f6863c4aafc676d22b4b97' 'accepted step-217 harness'
check_sha "$step217_policy" 'ac49b4b12a9478351761f948d66cca7afaa225a18a2e1e4a7834ed84bfd8bdec' 'accepted step-217 policy'
check_sha "$step217_record" 'ca3371e8667c4bb56937740210901ac13f2decac1d29cfb5758b3d294bb9745a' 'accepted step-217 record'
check_sha "$executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' 'authorized step-217 executor'
check_sha "$probe" '0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d' 'step-218 failure probe'
check_sha "$helper" '423993452485a6247969d8f64c174cc06e9002aaeb57ceed02133acd0b3f20af' 'step-218 helper'
check_sha "$doc" '104521f9a9ec24c79e7769129a5bf8967646f65e738c774c7f4d91fe173763d6' 'step-218 document'
check_sha "$policy" 'b60151eb7065a9300e931c8918f00553d8b34924fbbcd6d27def95787886389d' 'step-218 policy'
check_sha "$record" '07141eefbc338fe7b41bae866c26ce7b7c4eba0a0aec7d4ead0b48d85ac66627' 'step-218 record'

bash -n "$helper" && pass 'step-218 helper passes bash syntax validation' || fail 'step-218 helper passes bash syntax validation'
bash -n "$probe" && pass 'step-218 probe passes bash syntax validation' || fail 'step-218 probe passes bash syntax validation'

if "$probe" --help >/dev/null 2>&1; then
    fail 'step-218 probe rejects non-authorized option'
else
    pass 'step-218 probe rejects non-authorized option'
fi

out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
if "$helper" "$out" >"$out/helper.stdout"; then pass 'step-218 helper executes successfully'; else fail 'step-218 helper executes successfully'; fi
cmp -s "$out/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$out/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
grep -Fxq $'review_status\tPASS' "$out/helper.stdout" && pass 'helper reports PASS review status' || fail 'helper reports PASS review status'
grep -Fxq $'runtime_rerun_authorized\tno' "$out/helper.stdout" && pass 'helper keeps runtime rerun unauthorized' || fail 'helper keeps runtime rerun unauthorized'

python3 - "$policy" <<'PY' && pass 'step-218 policy semantic assertions pass' || fail 'step-218 policy semantic assertions pass'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review'
assert p['step']==218
assert p['review_status']=='PASS'
assert p['observed_runtime_result']=='FAIL'
assert p['failure_class']=='candidate-binding-guard-assumption'
assert p['mutation_had_started'] is True
assert p['cleanup_verification_required'] is True
assert p['failure_probe_sha256']=='0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d'
assert p['failure_probe_acknowledgement']=='--observe-failure-cleanup'
assert p['review_revision']=='218-r1'
assert p['preflight_encoding_compatibility']=='literal-backslash-t-or-real-tab'
assert p['machine_action_required'] is True
assert p['machine_action_type']=='read-only-failure-characterization'
for k in ('runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized'):
    assert p[k] is False
assert p['published_success_evidence_expected'] is False
assert p['failed_evidence_root_must_be_preserved'] is True
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-characterization-freeze'
PY

for pair in   'step|218'   'review_status|PASS'   'observed_runtime_result|FAIL'   'failure_class|candidate-binding-guard-assumption'   'cleanup_verification_required|yes'   'runtime_rerun_authorized|no'   'package_action_authorized|no'   'slackpkg_mutation_authorized|no'   'network_access_authorized|no'   'boot_action_authorized|no'   'reboot_authorized|no'   'failed_evidence_root_must_be_preserved|yes'   'review_revision|218-r1'   'preflight_encoding_compatibility|literal-backslash-t-or-real-tab'   'pause_safe|no'; do
    key=${pair%%|*}; value=${pair#*|}; grep -Fxq "$key"$'\t'"$value" "$record" && pass "record freezes: $key" || fail "record freezes: $key"
done

grep -Fq 'rollback trap must be verified' "$doc" && pass 'reference document requires cleanup verification' || fail 'reference document requires cleanup verification'
grep -Fq 'CHECKSUMS.md5.asc' "$doc" && pass 'reference document records missing Slackpkg signature metadata check' || fail 'reference document records missing Slackpkg signature metadata check'
grep -Fq 'No rerun' "$doc" && pass 'reference document keeps runtime rerun closed' || fail 'reference document keeps runtime rerun closed'
grep -Fq 'literal `\t` separators' "$doc" && pass 'reference document records first-probe parser mismatch' || fail 'reference document records first-probe parser mismatch'
grep -Fq '## Phase 1 step 218 kernel-package-edge runtime transaction first-attempt failure review' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 218' || fail 'CHANGELOG records step 218'
grep -Fq '## Phase 1 step 218-r1 kernel-package-edge failure-probe preflight-format remediation' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 218-r1' || fail 'CHANGELOG records step 218-r1'

if grep -Eq '^[[:space:]]*(upgradepkg|installpkg|removepkg|slackpkg|reboot|shutdown|poweroff)[[:space:]]' "$probe"; then
    fail 'step-218 probe contains no executable package/boot command'
else
    pass 'step-218 probe contains no executable package/boot command'
fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|ftp|rsync|scp|ssh)[[:space:]]' "$probe"; then
    fail 'step-218 probe contains no network client command'
else
    pass 'step-218 probe contains no network client command'
fi
if grep -Eq '(^|[;&|[:space:]])(rm|mv|cp|install|mkdir|touch|chmod|chown)[[:space:]]' "$probe"; then
    fail 'step-218 probe contains no filesystem mutation command'
else
    pass 'step-218 probe contains no filesystem mutation command'
fi

grep -Fq "readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'" "$probe" && pass 'probe binds failed evidence root' || fail 'probe binds failed evidence root'
grep -Fq "EXPECTED_PREDECESSOR_RECORD='kernel-headers-6.18.44-x86-1'" "$probe" && pass 'probe binds predecessor rollback identity' || fail 'probe binds predecessor rollback identity'
grep -Fq "EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'" "$probe" && pass 'probe binds restored target identity' || fail 'probe binds restored target identity'
grep -Fq "cleanup_triggered" "$probe" && pass 'probe requires cleanup evidence' || fail 'probe requires cleanup evidence'
grep -Fq "slackpkg_state_fingerprint" "$probe" && pass 'probe compares restored Slackpkg state fingerprint' || fail 'probe compares restored Slackpkg state fingerprint'
grep -Fq "boot_fingerprint" "$probe" && pass 'probe compares /boot fingerprint' || fail 'probe compares /boot fingerprint'
grep -Fq "geninitrd_policy_fingerprint" "$probe" && pass 'probe compares GenInitrd fingerprint' || fail 'probe compares GenInitrd fingerprint'
grep -Fq 'CHECKSUMS.md5.asc' "$probe" && pass 'probe checks local-source signature metadata absence' || fail 'probe checks local-source signature metadata absence'
grep -Fq "runtime_rerun_authorized\tno" "$probe" && pass 'probe reports rerun remains unauthorized' || fail 'probe reports rerun remains unauthorized'
grep -Fq 'if [[ $line == "$key\\t"* ]]' "$probe" && pass 'probe accepts literal backslash-t preflight encoding' || fail 'probe accepts literal backslash-t preflight encoding'

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
