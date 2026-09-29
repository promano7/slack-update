#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-characterization-freeze-and-strong-safe-pause'
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
pass=0
failn=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; failn=$((failn+1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
check 'step-269 helper exists as regular file' '[[ -f "$helper" && ! -L "$helper" ]]'
check 'step-269 document exists as regular file' '[[ -f "$doc" && ! -L "$doc" ]]'
check 'step-269 policy exists as regular file' '[[ -f "$policy" && ! -L "$policy" ]]'
check 'step-269 record exists as regular file' '[[ -f "$record" && ! -L "$record" ]]'
check 'accepted step-268 helper SHA-256 matches' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.sh") == da49e1e5688dfc95291fa13a2078d12e7d8ba54220bd9a7d3854964440a764d9 ]]'
check 'accepted step-268 probe SHA-256 matches' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-probe.sh") == 5bebb4e56e3d39d2346a004fe7b5055a208b02ce5673f65d023bb66c44d9ea63 ]]'
check 'accepted step-268 document SHA-256 matches' '[[ $(sha "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.md") == d836c961acb5b1ac77e7e09e565b0442c82d1c838f6a1719c684bef9b2d9c3b0 ]]'
check 'accepted step-268 harness SHA-256 matches' '[[ $(sha "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-harness.sh") == 91375e62de5bbd1d9c2559125b5b560857c68ab4337556ada1b51839a693b773 ]]'
check 'accepted step-268 policy SHA-256 matches' '[[ $(sha "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review-policy.json") == 78e9f5701fce6a2f876bfe4d245faddb42db10119869d3e5d13837eb76e96f19 ]]'
check 'accepted step-268 record SHA-256 matches' '[[ $(sha "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-failure-review.tsv") == f36666492820f274802c03ff57784c844213d72616bc808b90b3abf9bdfd7be1 ]]'
check 'frozen v4 builder SHA-256 remains unchanged' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh") == 38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7 ]]'
check 'failed step-267 executor SHA-256 remains unchanged' '[[ $(sha "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh") == f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985 ]]'
check 'step-269 helper SHA-256 matches' '[[ $(sha "$helper") == 9dd7fa6bc61a5ea5f68ff26da857140ecfb31cedc6203876e8db719c720586b1 ]]'
check 'step-269 document SHA-256 matches' '[[ $(sha "$doc") == ec594d3f941da828fa7bd4bcd598c275e67ba0cd3f48b9f5b014382f5ed147fd ]]'
check 'step-269 policy SHA-256 matches' '[[ $(sha "$policy") == 2323a05d34c9377a4bd2d96253f17b8fbdae6ce7b6fe17505a97f1ef5c68eb82 ]]'
check 'step-269 record SHA-256 matches' '[[ $(sha "$record") == f0df24341e034dddad4c7efaf3628b8ed4e17b78fa847325cfbd967aebcef95a ]]'
check 'step-269 helper passes bash syntax validation' 'bash -n "$helper"'
check 'step-269 harness passes bash syntax validation' 'bash -n "${BASH_SOURCE[0]}"'
check 'step-269 helper exposes non-mutating help' '"$helper" --help >/dev/null'
check 'step-269 helper rejects unknown option' '! "$helper" --bogus >/dev/null 2>&1'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
check 'step-269 helper executes successfully' '"$helper" --output-dir "$tmp" >/dev/null'
check 'helper reproduces frozen policy exactly' 'cmp -s "$policy" "$tmp/${base}-policy.json"'
check 'helper reproduces frozen record exactly' 'cmp -s "$record" "$tmp/${base}.tsv"'
check 'step-269 policy semantic assertions pass' "python3 - '$policy' <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['step']==269
assert p['review_status']=='PASS'
assert p['strong_safe_pause'] is True
assert p['safe_pause']['pause_safe'] is True
assert p['safe_pause']['strong_safe_pause'] is True
assert p['safe_pause']['no_open_operational_authorization'] is True
assert p['safe_pause']['machine_action_required'] is False
assert p['safe_pause']['controller_action_required'] is False
assert p['failure_characterization']['frozen'] is True
assert p['failure_characterization']['stage']=='direct-builder-launch-before-builder-entry'
assert p['failure_characterization']['class']=='permission-denied-on-direct-script-exec'
assert p['failure_characterization']['builder_transport_mode']=='0644'
assert p['failure_characterization']['builder_transport_executable_bit_visible'] is False
assert p['failure_characterization']['builder_execution_completed'] is False
assert p['failure_characterization']['local_source_v4_build_performed'] is False
assert p['failure_characterization']['authorization_reuse_authorized'] is False
assert p['verified_post_failure_state']['local_source_v4_root_absent'] is True
assert p['verified_post_failure_state']['local_source_v4_tree_manifest_absent'] is True
assert p['verified_post_failure_state']['local_source_v4_tree_manifest_sidecar_absent'] is True
assert p['verified_post_failure_state']['local_source_v4_temporary_build_roots_absent'] is True
assert p['verified_post_failure_state']['local_source_v3_tree_verified'] is True
assert p['verified_post_failure_state']['failed_v2_evidence_preserved'] is True
assert p['verified_post_failure_state']['boot_slackpkg_geninitrd_state_preserved'] is True
assert p['remediation_boundary']['candidate']=='invoke-frozen-builder-through-bash-after-new-review-and-authorization'
assert p['remediation_boundary']['implementation_authorized'] is False
assert p['remediation_boundary']['new_build_authorization_authorized'] is False
assert p['authorization']['repository_only_launch_remediation_review_authorized'] is True
for key,val in p['authorization'].items():
    if key!='repository_only_launch_remediation_review_authorized':
        assert val is False, (key,val)
PYSEM"
check 'TSV records step 269' "grep -Fq $'step\t269' '$record'"
check 'TSV records PASS review' "grep -Fq $'review_status\tPASS' '$record'"
check 'TSV freezes direct-launch failure stage' "grep -Fq $'failure_stage\tdirect-builder-launch-before-builder-entry' '$record'"
check 'TSV freezes permission-denied failure class' "grep -Fq $'failure_class\tpermission-denied-on-direct-script-exec' '$record'"
check 'TSV records builder mode 0644' "grep -Fq $'transported_builder_mode\t0644' '$record'"
check 'TSV records no builder completion' "grep -Fq $'builder_execution_completed\tno' '$record'"
check 'TSV records no v4 build' "grep -Fq $'local_source_v4_build_performed\tno' '$record'"
check 'TSV records all v4 final outputs absent' "grep -Fq $'local_source_v4_root_absent\tyes' '$record' && grep -Fq $'local_source_v4_tree_manifest_absent\tyes' '$record' && grep -Fq $'local_source_v4_tree_manifest_sidecar_absent\tyes' '$record'"
check 'TSV records temporary build roots absent' "grep -Fq $'local_source_v4_temporary_build_roots_absent\tyes' '$record'"
check 'TSV records v3 preserved' "grep -Fq $'local_source_v3_tree_verified\tyes' '$record'"
check 'TSV records failed-v2 evidence preserved' "grep -Fq $'failed_v2_evidence_preserved\tyes' '$record'"
check 'TSV records boot Slackpkg GenInitrd preserved' "grep -Fq $'boot_slackpkg_geninitrd_state_preserved\tyes' '$record'"
check 'TSV forbids authorization reuse' "grep -Fq $'authorization_reuse_authorized\tno' '$record'"
check 'TSV forbids step-267 executor rerun' "grep -Fq $'step267_executor_rerun_authorized\tno' '$record'"
check 'TSV forbids builder execution' "grep -Fq $'builder_execution_authorized\tno' '$record'"
check 'TSV forbids chmod remediation' "grep -Fq $'chmod_remediation_authorized\tno' '$record'"
check 'TSV requires no machine action' "grep -Fq $'machine_action_required\tno' '$record'"
check 'TSV requires no controller action' "grep -Fq $'controller_action_required\tno' '$record'"
check 'TSV marks pause safe' "grep -Fq $'pause_safe\tyes' '$record'"
check 'TSV marks strong safe pause' "grep -Fq $'strong_safe_pause\tyes' '$record'"
check 'TSV names repository-only next stage' "grep -Fq $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review' '$record'"
check 'document records mode 0644' "grep -Fq '0644' '$doc'"
check 'document records failure before builder entry' "grep -Fq 'before builder entry' '$doc'"
check 'document records no partial v4 state' "grep -Fq 'No partial local-source-v4 tree' '$doc'"
check 'document forbids second executor invocation' "grep -Fq 'second executor invocation is forbidden' '$doc'"
check 'document keeps bash remediation unimplemented' "grep -Fq 'neither implements that remediation nor grants a new build authorization' '$doc'"
check 'document establishes strong safe pause' "grep -Fq 'strong_safe_pause=true' '$doc'"
check 'document requires fresh revalidation before future machine action' "grep -Fq 'fresh revalidation and a new explicit authorization' '$doc'"
check 'helper grants no machine authority' "grep -Fq 'grants no machine or build authority' '$helper'"
check 'helper reports strong safe pause' "grep -Fq 'strong_safe_pause' '$helper'"
check 'helper contains no executable network package boot reboot or shutdown command' "! grep -Ev '^[[:space:]]*#' '$helper' | grep -Eq '(^|[;&|[:space:]])(slackpkg|installpkg|upgradepkg|removepkg|wget|curl|reboot|shutdown|poweroff)([[:space:]]|$)'"
for f in "$helper" "$doc" "$policy" "$record"; do check "$(basename "$f") contains no trailing whitespace" "! grep -nE '[[:blank:]]+$' '$f' >/dev/null"; done
check 'CHANGELOG records step 269' "grep -Fq '## Phase 1 step 269 — local-source-v4 build-launch failure characterization freeze and strong safe pause' '$repo_root/CHANGELOG.md'"
check 'CHANGELOG records next repository-only stage' "grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-review' '$repo_root/CHANGELOG.md'"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failn -eq 0 ]] && printf PASS || printf FAIL)" "$pass" "$failn"
[[ $failn -eq 0 ]]
