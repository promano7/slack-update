#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.sh"; probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-probe.sh"; doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.tsv"
pass=0; failn=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; failn=$((failn+1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
sha() { sha256sum -- "$1"|awk '{print $1}'; }
check 'step-268 helper exists' '[[ -f "$helper" && ! -L "$helper" ]]'
check 'step-268 probe exists' '[[ -f "$probe" && ! -L "$probe" ]]'
check 'step-268 document exists' '[[ -f "$doc" && ! -L "$doc" ]]'
check 'step-268 policy exists' '[[ -f "$policy" && ! -L "$policy" ]]'
check 'step-268 record exists' '[[ -f "$record" && ! -L "$record" ]]'
check 'accepted step-267 helper SHA-256 matches' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.sh") == 19e18b03a3ede501479dd6feda45f9abba9ee5b4ac78a51a2f04f185de47e709 ]]'
check 'accepted step-267 executor SHA-256 matches' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh") == f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985 ]]'
check 'frozen v4 builder SHA-256 matches' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh") == 38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7 ]]'
check 'step-268 probe SHA-256 matches' '[[ $(sha "$probe") == 5bebb4e56e3d39d2346a004fe7b5055a208b02ce5673f65d023bb66c44d9ea63 ]]'
check 'step-268 helper SHA-256 matches' '[[ $(sha "$helper") == da49e1e5688dfc95291fa13a2078d12e7d8ba54220bd9a7d3854964440a764d9 ]]'
check 'step-268 document SHA-256 matches' '[[ $(sha "$doc") == d836c961acb5b1ac77e7e09e565b0442c82d1c838f6a1719c684bef9b2d9c3b0 ]]'
check 'step-268 policy SHA-256 matches' '[[ $(sha "$policy") == 78e9f5701fce6a2f876bfe4d245faddb42db10119869d3e5d13837eb76e96f19 ]]'
check 'step-268 record SHA-256 matches' '[[ $(sha "$record") == f36666492820f274802c03ff57784c844213d72616bc808b90b3abf9bdfd7be1 ]]'
check 'helper syntax valid' 'bash -n "$helper"'
check 'probe syntax valid' 'bash -n "$probe"'
check 'harness syntax valid' 'bash -n "${BASH_SOURCE[0]}"'
check 'helper exposes help' '"$helper" --help >/dev/null'
check 'probe exposes help' '"$probe" --help >/dev/null'
check 'helper rejects unknown option' '! "$helper" --bogus >/dev/null 2>&1'
check 'probe rejects unknown option' '! "$probe" --bogus >/dev/null 2>&1'
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
check 'helper executes successfully' '"$helper" --output-dir "$tmp" >/dev/null'
check 'helper reproduces frozen policy' 'cmp -s "$policy" "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-policy.json"'
check 'helper reproduces frozen record' 'cmp -s "$record" "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.tsv"'
check 'policy semantic assertions pass' "python3 - '$policy' <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1]))
assert p['step']==268 and p['review_status']=='PASS' and p['strong_safe_pause'] is False
assert p['observed_failure']['preflight_status']=='PASS'
assert p['observed_failure']['failure_class']=='permission-denied-on-direct-script-exec'
assert p['authorization_after_failure']['state']=='failed-at-launch-invalidated'
assert p['authorization_after_failure']['rerun_authorized'] is False
assert p['remediation_boundary']['selected']=='invoke-frozen-builder-through-bash'
assert p['remediation_boundary']['implementation_authorized'] is False
PYSEM"
check 'document records Permission denied launch failure' "grep -Fq 'Permission denied' '$doc'"
check 'document forbids rerun' "grep -Fq 'second executor invocation' '$doc'"
check 'document selects bash invocation remediation' "grep -Fq 'invoke the exact SHA-bound builder through' '$doc'"
check 'probe requires v4 output absence' "grep -Fq 'verify_v4_absent' '$probe'"
check 'probe reports builder mode' "grep -Fq 'transported_builder_mode' '$probe'"
check 'probe does not execute builder' "! grep -Eq '(^|[;&|[:space:]])(\./|/[^ ]*/)?phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build\.sh([[:space:]]|$)' '$probe'"
check 'probe contains no executable mutation/network/boot commands' "! grep -Ev '^[[:space:]]*#' '$probe' | grep -Eq '(^|[;&|[:space:]])(slackpkg|installpkg|upgradepkg|removepkg|wget|curl|reboot|shutdown|poweroff)([[:space:]]|$)'"
for f in "$helper" "$probe" "$doc" "$policy" "$record"; do check "$(basename "$f") contains no trailing whitespace" "! grep -nE '[[:blank:]]+$' '$f' >/dev/null"; done
check 'CHANGELOG records step 268' "grep -Fq '## Phase 1 step 268 — local-source-v4 authorized-build launch failure review' '$repo_root/CHANGELOG.md'"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failn -eq 0 ]] && printf PASS || printf FAIL)" "$pass" "$failn"
[[ $failn -eq 0 ]]
