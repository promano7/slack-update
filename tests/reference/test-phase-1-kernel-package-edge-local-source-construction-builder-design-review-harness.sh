#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-review.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-review.md"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
pass=0; fail=0
ok(){ printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad(){ printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file(){ [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }
check_line(){ grep -Fqx "$2" "$record" && ok "$1" || bad "$1"; }
check_file 'step-203 policy is a regular file' "$policy"
check_file 'step-203 record is a regular file' "$record"
check_file 'step-203 helper is a regular file' "$helper"
check_file 'step-203 document is a regular file' "$doc"
check_file 'accepted step-202 policy is a regular file' "$prior_policy"
check_file 'accepted step-202 record is a regular file' "$prior_record"
check_file 'accepted step-202 helper is a regular file' "$prior_helper"
[[ ! -e $builder ]] && ok 'local-source builder remains unimplemented' || bad 'local-source builder remains unimplemented'
[[ $(sha256sum "$prior_policy"|awk '{print $1}') == 196f29cc2bc171e8ce12f4ba6648dcceeb36a5ba49ca29956edba1f6c35521b0 ]] && ok 'accepted step-202 policy hash is frozen' || bad 'accepted step-202 policy hash is frozen'
[[ $(sha256sum "$prior_record"|awk '{print $1}') == 611bb1de56fb14c04340333b02c2290640f325ba11daf68e944d13c252432e45 ]] && ok 'accepted step-202 record hash is frozen' || bad 'accepted step-202 record hash is frozen'
[[ $(sha256sum "$prior_helper"|awk '{print $1}') == 5e6968c0af540fe993d229f7c86f906e6e2bcb2bbe82557603d24b01975e7a59 ]] && ok 'accepted step-202 helper hash is frozen' || bad 'accepted step-202 helper hash is frozen'
bash -n "$helper" && ok 'step-203 helper passes shell syntax validation' || bad 'step-203 helper passes shell syntax validation'
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/${record##*/}" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PYASSERT203' && ok 'policy freezes deterministic fail-closed single-candidate builder design' || bad 'policy freezes deterministic fail-closed single-candidate builder design'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8')); b=p['builder_design']; m=b['metadata_contract']; d=b['deterministic_generation']; i=b['input_guards']; f=b['finalization_contract']; x=b['failure_contract']; a=p['authorization']
assert b['state']=='reviewed-awaiting-design-freeze' and b['builder_implementation_state']=='not-implemented'
assert b['accepted_builder_input_artifact_count']==1 and b['accepted_builder_input_artifact']=='kernel-headers-6.18.45-x86-1.txz' and b['predecessor_is_builder_input'] is False
assert b['exact_package_candidate_count']==1 and b['target_relative_path']=='slackware64/d/kernel-headers-6.18.45-x86-1.txz'
assert b['required_top_level_metadata']==['ChangeLog.txt','FILELIST.TXT','PACKAGES.TXT','CHECKSUMS.md5']
assert m['packages_txt_exact_stanza_count']==1 and m['packages_txt_package_location']=='./slackware64/d' and m['checksums_md5_must_bind_target_package'] and m['filelist_txt_must_not_expose_second_package_archive']
assert not d['wall_clock_time_embedded'] and not d['hostname_embedded'] and not d['boot_id_embedded'] and d['sorted_manifest_paths'] and d['source_tree_promoted_only_after_validation'] and not d['existing_final_tree_overwrite_allowed']
assert i['target_input_sha256_must_match_frozen_binding'] and not i['target_input_symlink_allowed'] and not i['builder_may_access_network']
assert f['manifest_is_outside_source_tree'] and f['manifest_sha256_required'] and f['final_tree_directory_mode']=='0555' and f['final_tree_regular_file_mode']=='0444'
assert x['fail_closed'] and x['must_preserve_staging_inputs'] and x['must_not_modify_package_database'] and x['must_not_modify_slackpkg_configuration'] and x['must_not_modify_boot_state'] and x['must_not_reboot']
assert a['builder_design_freeze_authorized_for_next_stage']
for k,v in a.items():
    if k!='builder_design_freeze_authorized_for_next_stage': assert v is False
assert p['machine_action_required'] is False and p['pause_safe'] is False
PYASSERT203
check_line 'record preserves frozen target binding' $'fresh_target_binding_state\tfrozen'
check_line 'record keeps builder unimplemented' $'builder_implementation_state\tnot-implemented'
check_line 'record allows exactly one builder input artifact' $'accepted_builder_input_artifact_count\t1'
check_line 'record excludes predecessor from builder input' $'predecessor_is_builder_input\tno'
check_line 'record allows exactly one package candidate' $'exact_package_candidate_count\t1'
check_line 'record freezes target package relative path' $'target_relative_path\tslackware64/d/kernel-headers-6.18.45-x86-1.txz'
check_line 'record freezes required metadata set' $'required_top_level_metadata\tChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5'
check_line 'record freezes external tree manifest path' $'tree_manifest_path\t/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
check_line 'record freezes final directory mode' $'final_tree_directory_mode\t0555'
check_line 'record freezes final regular-file mode' $'final_tree_regular_file_mode\t0444'
check_line 'record forbids runtime network access' $'runtime_network_access_allowed\tno'
check_line 'record forbids final-tree overwrite' $'existing_final_tree_overwrite_allowed\tno'
check_line 'record forbids package database mutation by builder' $'builder_may_modify_package_database\tno'
check_line 'record forbids slackpkg configuration mutation by builder' $'builder_may_modify_slackpkg_configuration\tno'
check_line 'record authorizes only design freeze next' $'builder_design_freeze_authorized_for_next_stage\tyes'
check_line 'record does not authorize implementation' $'builder_implementation_authorized\tno'
check_line 'record does not authorize target artifact copy' $'target_artifact_copy_authorized\tno'
check_line 'record does not authorize local-source build' $'local_source_build_authorized\tno'
check_line 'record requires no machine action' $'machine_action_required\tno'
check_line 'record routes to builder design freeze' $'next_stage\tphase-1-kernel-package-edge-local-source-construction-builder-design-freeze'
if grep -Fq 'install/slack-desc' "$doc" && grep -Fq 'Exactly one package archive' "$doc" && grep -Fq 'local-source.tree.sha256' "$doc" && grep -Fq 'phase-1-kernel-package-edge-local-source-construction-builder-design-freeze' "$doc"; then ok 'reference document records metadata, single-candidate, manifest, and next-stage contract'; else bad 'reference document records metadata, single-candidate, manifest, and next-stage contract'; fi
if grep -Fq 'Phase 1 step 203 kernel-package-edge local-source construction builder design review' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 203'; else bad 'CHANGELOG records step 203'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-203 helper contains no executable network/package/boot/reboot command'; else ok 'step-203 helper contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
