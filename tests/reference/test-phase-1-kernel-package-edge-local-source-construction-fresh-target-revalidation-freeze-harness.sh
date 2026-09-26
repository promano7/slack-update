#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.md"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-r2-probe.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
pass=0; fail=0
ok(){ printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad(){ printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file(){ [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }
check_file 'step-202 policy is a regular file' "$policy"
check_file 'step-202 record is a regular file' "$record"
check_file 'step-202 helper is a regular file' "$helper"
check_file 'step-202 document is a regular file' "$doc"
check_file 'accepted step-201-r2 policy is a regular file' "$prior_policy"
check_file 'accepted step-201-r2 record is a regular file' "$prior_record"
check_file 'accepted step-201-r2 probe is a regular file' "$probe"
[[ ! -e $builder ]] && ok 'local-source builder remains unimplemented' || bad 'local-source builder remains unimplemented'
[[ $(sha256sum "$prior_policy"|awk '{print $1}') == 0d0ce818ea6155e9ed75436baeb16b6a2a993574aa5648cd8dbf5de80dda97fa ]] && ok 'accepted step-201-r2 policy hash is frozen' || bad 'accepted step-201-r2 policy hash is frozen'
[[ $(sha256sum "$prior_record"|awk '{print $1}') == d48edf0060acf59be5401f7ab95ffd6da1b2aa509319108533e4b5fe58f28324 ]] && ok 'accepted step-201-r2 record hash is frozen' || bad 'accepted step-201-r2 record hash is frozen'
[[ $(sha256sum "$probe"|awk '{print $1}') == 93d705080e6698841d613eeb90a2baeca80d000a14af7405f0e219d8d608f3ae ]] && ok 'accepted corrected probe hash is frozen' || bad 'accepted corrected probe hash is frozen'
bash -n "$helper" && ok 'step-202 helper passes shell syntax validation' || bad 'step-202 helper passes shell syntax validation'
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/${record##*/}" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PY' && ok 'policy freezes exact post-pause target evidence and no operational authority' || bad 'policy freezes exact post-pause target evidence and no operational authority'
import json,sys
p=json.load(open(sys.argv[1]))
a=p['accepted_revalidation_evidence']; b=p['fresh_target_binding']; z=p['authorization']
assert a['status']=='PASS'
assert a['boot_id']=='d767c4ed-b21f-4c6f-9a1e-db7948c285cf'
assert a['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert a['characterized_drift_record']=='pCloudDrive-2.3.0-x86_64-1_SBo'
assert a['header_package_record']=='kernel-headers-6.18.45-x86-1'
assert a['kernel_generic_record']=='kernel-generic-6.18.45-x86_64-1'
assert a['kernel_huge_absent'] and a['kernel_modules_absent']
assert b['state']=='frozen' and b['binding_is_post_pause'] and not b['historical_step_194_binding_reused']
assert not b['fresh_candidate_set_bound'] and b['builder_implementation_state']=='not-implemented'
assert z['repository_only_builder_design_review_authorized']
for k,v in z.items():
    if k!='repository_only_builder_design_review_authorized': assert v is False
assert p['machine_action_required'] is False and p['pause_safe'] is False
PY
grep -Fq $'revalidation_status\tPASS' "$record" && ok 'record accepts successful revalidation' || bad 'record accepts successful revalidation'
grep -Fq $'fresh_target_binding\tfrozen' "$record" && ok 'record freezes fresh target binding' || bad 'record freezes fresh target binding'
grep -Fq $'historical_step_194_binding_reused\tno' "$record" && ok 'record forbids historical binding reuse' || bad 'record forbids historical binding reuse'
grep -Fq $'fresh_candidate_set_bound\tno' "$record" && ok 'record binds no fresh candidate set' || bad 'record binds no fresh candidate set'
grep -Fq $'target_artifact_copy_authorized\tno' "$record" && ok 'target copy remains forbidden' || bad 'target copy remains forbidden'
grep -Fq $'local_source_build_authorized\tno' "$record" && ok 'local-source build remains forbidden' || bad 'local-source build remains forbidden'
grep -Fq $'repository_only_builder_design_review_authorized\tyes' "$record" && ok 'only repository builder design review is opened' || bad 'only repository builder design review is opened'
grep -Fq $'machine_action_required\tno' "$record" && ok 'step 202 requires no machine action' || bad 'step 202 requires no machine action'
grep -Fq $'next_stage\tphase-1-kernel-package-edge-local-source-construction-builder-design-review' "$record" && ok 'record routes to builder design review' || bad 'record routes to builder design review'
grep -Fq 'pCloudDrive-2.3.0-x86_64-1_SBo' "$doc" && grep -Fq 'historical step-194 runtime binding is not reused' "$doc" && ok 'document records characterized drift and new binding semantics' || bad 'document records characterized drift and new binding semantics'
grep -Fq 'Phase 1 step 202 kernel-package-edge fresh target revalidation freeze' "$repo_root/CHANGELOG.md" && ok 'CHANGELOG records step 202' || bad 'CHANGELOG records step 202'
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]' "$helper"; then bad 'helper contains no executable network/package/boot/reboot command'; else ok 'helper contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
