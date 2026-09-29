#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review'
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.tsv"
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.sh"
prev_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-probe.sh"
prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.md"
prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.tsv"
v4_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file() { [[ -f $1 && ! -L $1 ]] && pass "$2 exists as regular file" || fail "$2 exists as regular file"; }
check_hash() { local got; got=$(sha256sum -- "$1" | awk '{print $1}'); [[ $got == "$2" ]] && pass "$3 SHA-256 matches" || fail "$3 SHA-256 matches ($got)"; }

check_file "$helper" 'step-266 helper'; check_file "$doc" 'step-266 document'; check_file "$policy" 'step-266 policy'; check_file "$record" 'step-266 record'
check_hash "$prev_helper" 'bf6fdad0eca2444c8be535eaaf8cd8aaeca54a548c10425fbccc363d3af9a52f' 'accepted step-265 helper'
check_hash "$prev_probe" '16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd' 'accepted step-265 probe'
check_hash "$prev_doc" 'b6a5892659c84f64a209edb750bc6c33e7aaf5ba2af5aee16691049a6bf7f3ec' 'accepted step-265 document'
check_hash "$prev_harness" '9e020da7b2a921478d915fb73c4b93bf40f071b16066dd70768da1b0e71d4566' 'accepted step-265 harness'
check_hash "$prev_policy" 'e1f76e643cd3bf2784f5038acdc01961290b724e3574a98d8ae951e59b480daf' 'accepted step-265 policy'
check_hash "$prev_record" '4ccfe17c7a6236d1bc4ad92d64015fd3bcaafd1bca1aceb931c5a417c7eeca55' 'accepted step-265 record'
check_hash "$v4_builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen v4 builder'
check_hash "$helper" '6b16ee9a7e904b173849486ba4119842e1fcc73ae41508286b039c8016a58171' 'step-266 helper'
check_hash "$doc" '3ce7f916d39efe4b3e80ac8648015f74bab61dda43f4c78d0ec72ff757311535' 'step-266 document'
check_hash "$policy" 'fd6ce003f5b46451a94319b3949d7354396934b937068dd0b1a871c942f197a3' 'step-266 policy'
check_hash "$record" 'd0bf5b8e88aaf8dab683ccff439d356071a222b184f85050509e54393b674a87' 'step-266 record'

bash -n "$helper" && pass 'step-266 helper passes bash syntax validation' || fail 'step-266 helper passes bash syntax validation'
bash -n "${BASH_SOURCE[0]}" && pass 'step-266 harness passes bash syntax validation' || fail 'step-266 harness passes bash syntax validation'
"$helper" --help >/dev/null && pass 'step-266 helper exposes non-mutating help' || fail 'step-266 helper exposes non-mutating help'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-266 helper rejects unknown option'; else pass 'step-266 helper rejects unknown option'; fi

work=$(mktemp -d); trap 'rm -rf -- "$work"' EXIT
"$helper" --output-dir "$work" >/dev/null && pass 'step-266 helper executes successfully' || fail 'step-266 helper executes successfully'
cmp -s "$work/${base}-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$work/${base}.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

python3 - "$policy" "$record" <<'PYCHECK'
import json,pathlib,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
r={}
for line in pathlib.Path(sys.argv[2]).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); r[k]=v
assert p['step']==266 and p['review_status']=='PASS'
o=p['consumed_revalidation_observation']
assert o['v4_fresh_target_and_output_absence_revalidation_status']=='PASS'
assert o['fresh_boot_id']=='d34855ae-e039-4005-a842-1bef51082195'
assert o['prior_runtime_binding_reused']=='no'
assert o['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert o['staged_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert o['local_source_v3_tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert o['failed_v2_pkglist_sha256']=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
for k in ('local_source_v4_root_absent','local_source_v4_tree_manifest_absent','local_source_v4_tree_manifest_sidecar_absent','local_source_v4_temporary_build_roots_absent','failed_v2_evidence_preserved','boot_artifacts_match_failed_v2_preflight','slackpkg_state_matches_failed_v2_preflight','geninitrd_policy_matches_failed_v2_preflight'):
    assert o[k]=='yes'
for k in ('builder_execution_performed','local_source_v4_build_performed','slackpkg_refresh_performed','package_action_performed','network_access_performed','boot_action_performed','reboot_performed','persistent_configuration_change_performed','evidence_cleanup_performed'):
    assert o[k]=='no'
assert p['fresh_target_binding']['fresh_boot_id']==o['fresh_boot_id']
assert p['fresh_target_binding']['prior_runtime_binding_reused'] is False
assert p['frozen_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
a=p['reviewed_single_build_authorization']
assert a['state']=='reviewed-not-authorized' and a['authorization_use_count']==1
assert a['authorization_bound_boot_id']=='d34855ae-e039-4005-a842-1bef51082195'
assert a['same_boot_required_at_execution'] is True
assert a['builder_sha256']==p['frozen_v4_builder']['sha256']
assert a['acknowledgement']=='--build-local-source-v4'
assert a['final_outputs_must_still_be_absent_immediately_before_execution'] is True
assert a['temporary_build_roots_must_still_be_absent_immediately_before_execution'] is True
assert a['accepted_local_source_v3_must_remain_immutable'] is True
assert a['failed_v2_evidence_must_remain_immutable'] is True
assert a['no_second_execution_authorized'] is True
for k in ('slackpkg_refresh_allowed','repository_refresh_allowed','network_access_allowed','package_mutation_allowed','persistent_configuration_change_allowed','boot_mutation_allowed','reboot_allowed','evidence_cleanup_allowed'):
    assert a[k] is False
assert p['authorization']['build_authorization_freeze_review_authorized'] is True
assert p['authorization']['local_source_v4_builder_transport_authorized'] is False
assert p['authorization']['local_source_v4_builder_execution_authorized'] is False
assert p['authorization']['local_source_v4_build_authorized'] is False
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze'
assert r['single_build_authorization_state']=='reviewed-not-authorized'
assert r['authorization_bound_boot_id']=='d34855ae-e039-4005-a842-1bef51082195'
assert r['v4_builder_execution_authorized']=='no' and r['v4_build_authorized']=='no'
PYCHECK
[[ $? -eq 0 ]] && pass 'step-266 policy semantic assertions pass' || fail 'step-266 policy semantic assertions pass'

grep -Fq 'd34855ae-e039-4005-a842-1bef51082195' "$doc" && pass 'document freezes fresh boot ID' || fail 'document freezes fresh boot ID'
grep -Fq 'reviewed, but it is **not yet granted**' "$doc" && pass 'document distinguishes review from authorization grant' || fail 'document distinguishes review from authorization grant'
grep -Fq 'exactly one' "$doc" && pass 'document bounds future build to one execution' || fail 'document bounds future build to one execution'
grep -Fq -- '--build-local-source-v4' "$doc" && pass 'document binds future builder acknowledgement' || fail 'document binds future builder acknowledgement'
grep -Fq 'builder transport: closed' "$doc" && pass 'document keeps builder transport closed' || fail 'document keeps builder transport closed'
grep -Fq 'builder execution: closed' "$doc" && pass 'document keeps builder execution closed' || fail 'document keeps builder execution closed'

grep -Fq 'reviewed-not-authorized' "$record" && pass 'TSV records reviewed-not-authorized state' || fail 'TSV records reviewed-not-authorized state'
grep -Fq $'machine_action_required\tno' "$record" && pass 'TSV requires no machine action' || fail 'TSV requires no machine action'

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "${f##*/} contains no trailing whitespace"; else pass "${f##*/} contains no trailing whitespace"; fi
done
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)([[:space:]]|$)|^[[:space:]]*(sudo[[:space:]]+)?git[[:space:]]+(pull|fetch)([[:space:]]|$)' "$helper"; then
    fail 'step-266 helper contains no executable network package boot reboot or shutdown command'
else
    pass 'step-266 helper contains no executable network package boot reboot or shutdown command'
fi
grep -Fq '## Phase 1 step 266' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 266' || fail 'CHANGELOG records step 266'

if (( failures )); then printf 'Result: FAIL (%d passes, %d failures)\n' "$passes" "$failures"; exit 1; fi
printf 'Result: PASS (%d passes, 0 failures)\n' "$passes"
