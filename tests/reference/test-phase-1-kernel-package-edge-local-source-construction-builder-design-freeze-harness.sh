#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze.md"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-review.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
pass=0; fail=0
ok(){ printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad(){ printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file(){ [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }
check_line(){ grep -Fqx "$2" "$record" && ok "$1" || bad "$1"; }
check_file 'step-204 policy is a regular file' "$policy"
check_file 'step-204 record is a regular file' "$record"
check_file 'step-204 helper is a regular file' "$helper"
check_file 'step-204 document is a regular file' "$doc"
check_file 'accepted step-203 policy is a regular file' "$prior_policy"
check_file 'accepted step-203 record is a regular file' "$prior_record"
check_file 'accepted step-203 helper is a regular file' "$prior_helper"
[[ ! -e $builder ]] && ok 'local-source builder remains unimplemented' || bad 'local-source builder remains unimplemented'
[[ $(sha256sum "$prior_policy"|awk '{print $1}') == 44f924e526d8b9bcdbed70054630d15801538f0bf9a965a7513f8a1b27060568 ]] && ok 'accepted step-203 policy hash is frozen' || bad 'accepted step-203 policy hash is frozen'
[[ $(sha256sum "$prior_record"|awk '{print $1}') == c0b97882d36fe5f24f5a2ad95bece3f9ec9e7850de2dc346f7e384f3d31944ed ]] && ok 'accepted step-203 record hash is frozen' || bad 'accepted step-203 record hash is frozen'
[[ $(sha256sum "$prior_helper"|awk '{print $1}') == 0474e11e9ce36955c52750258560e1affe2fe12242217ad82ec14424312c1944 ]] && ok 'accepted step-203 helper hash is frozen' || bad 'accepted step-203 helper hash is frozen'
bash -n "$helper" && ok 'step-204 helper passes shell syntax validation' || bad 'step-204 helper passes shell syntax validation'
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/${record##*/}" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PYASSERT204' && ok 'policy freezes step-203 builder design without operational authority' || bad 'policy freezes step-203 builder design without operational authority'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8')); b=p['builder_design']; a=p['authorization']
assert b['state']=='frozen' and b['builder_implementation_state']=='not-implemented'
assert b['accepted_builder_input_artifact_count']==1 and b['accepted_builder_input_artifact']=='kernel-headers-6.18.45-x86-1.txz'
assert b['predecessor_is_builder_input'] is False and b['exact_package_candidate_count']==1
assert b['required_top_level_metadata']==['ChangeLog.txt','FILELIST.TXT','PACKAGES.TXT','CHECKSUMS.md5']
assert b['metadata_contract']['packages_txt_exact_stanza_count']==1
assert b['deterministic_generation']['source_tree_promoted_only_after_validation']
assert not b['deterministic_generation']['existing_final_tree_overwrite_allowed']
assert b['finalization_contract']['manifest_is_outside_source_tree'] and b['finalization_contract']['final_tree_directory_mode']=='0555' and b['finalization_contract']['final_tree_regular_file_mode']=='0444'
assert b['failure_contract']['fail_closed'] and b['failure_contract']['must_not_modify_package_database'] and b['failure_contract']['must_not_modify_slackpkg_configuration'] and b['failure_contract']['must_not_modify_boot_state'] and b['failure_contract']['must_not_reboot']
assert a['builder_implementation_review_authorized_for_next_stage']
for k,v in a.items():
    if k!='builder_implementation_review_authorized_for_next_stage': assert v is False
assert p['machine_action_required'] is False and p['pause_safe'] is False
PYASSERT204
check_line 'record freezes builder design' $'builder_design_state\tfrozen'
check_line 'record keeps builder unimplemented' $'builder_implementation_state\tnot-implemented'
check_line 'record preserves single builder input' $'accepted_builder_input_artifact_count\t1'
check_line 'record excludes predecessor from builder input' $'predecessor_is_builder_input\tno'
check_line 'record preserves single package candidate' $'exact_package_candidate_count\t1'
check_line 'record freezes metadata set' $'required_top_level_metadata\tChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5'
check_line 'record freezes tree manifest path' $'tree_manifest_path\t/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
check_line 'record freezes final directory mode' $'final_tree_directory_mode\t0555'
check_line 'record freezes final regular-file mode' $'final_tree_regular_file_mode\t0444'
check_line 'record forbids runtime network access' $'runtime_network_access_allowed\tno'
check_line 'record forbids package database mutation' $'builder_may_modify_package_database\tno'
check_line 'record forbids slackpkg configuration mutation' $'builder_may_modify_slackpkg_configuration\tno'
check_line 'record authorizes only implementation review next' $'builder_implementation_review_authorized_for_next_stage\tyes'
check_line 'record does not authorize builder implementation execution' $'builder_implementation_authorized\tno'
check_line 'record does not authorize artifact copy' $'target_artifact_copy_authorized\tno'
check_line 'record does not authorize local-source build' $'local_source_build_authorized\tno'
check_line 'record requires no machine action' $'machine_action_required\tno'
check_line 'record routes to builder implementation review' $'next_stage\tphase-1-kernel-package-edge-local-source-construction-builder-implementation-review'
if grep -Fq 'only next authority is repository-only' "$doc" && grep -Fq 'builder remains' "$doc" && grep -Fq 'not implemented' "$doc"; then ok 'reference document records freeze and implementation-review boundary'; else bad 'reference document records freeze and implementation-review boundary'; fi
if grep -Fq 'Phase 1 step 204 kernel-package-edge local-source construction builder design freeze' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 204'; else bad 'CHANGELOG records step 204'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-204 helper contains no executable network/package/boot/reboot command'; else ok 'step-204 helper contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
