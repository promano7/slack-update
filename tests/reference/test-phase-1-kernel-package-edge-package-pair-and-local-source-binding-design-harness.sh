#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
A="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1"
HELPER="$REPO_ROOT/tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.sh"
DOC="$REPO_ROOT/docs/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.md"
POLICY="$A/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json"
RECORD="$A/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.tsv"
STEP194_HELPER="$REPO_ROOT/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-freeze.sh"
STEP194_DOC="$REPO_ROOT/docs/reference/phase-1-kernel-package-edge-runtime-target-binding-freeze.md"
STEP194_POLICY="$A/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json"
STEP194_RECORD="$A/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv"
STEP192_POLICY="$A/phase-1-kernel-package-edge-runtime-boundary-design-policy.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
PASS_COUNT=0
FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
regular(){ [[ -f $1 && ! -L $1 ]]; }
expect_line(){ local line=$1 label=$2; grep -Fqx "$line" "$RECORD" && pass "$label" || fail "$label"; }

for item in \
  "$HELPER|step-195 binding-design helper" \
  "$DOC|step-195 reference document" \
  "$POLICY|step-195 binding-design policy" \
  "$RECORD|step-195 binding-design record" \
  "$STEP194_HELPER|accepted step-194 helper" \
  "$STEP194_DOC|accepted step-194 reference document" \
  "$STEP194_POLICY|accepted step-194 policy" \
  "$STEP194_RECORD|accepted step-194 record" \
  "$STEP192_POLICY|accepted step-192 runtime-boundary policy"; do
    file=${item%%|*}; label=${item#*|}
    regular "$file" && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"
done

[[ $(sha "$HELPER") == '9dff053b5f8c4beeb78e3c827b241f7dafc9604a397b3caeda64a2348151f8b7' ]] && pass 'step-195 helper has the exact reviewed SHA-256' || fail 'step-195 helper SHA-256 mismatch'
[[ $(sha "$DOC") == '9cf7a2eeae89d7189931b700df58e096c3cb97de102c3bc16ce40ae677e7154d' ]] && pass 'step-195 reference document has the exact reviewed SHA-256' || fail 'step-195 reference document SHA-256 mismatch'
[[ $(sha "$POLICY") == 'ce33fc2ead2335c50cd9e47146f8d1d818a49e1cb3169b06fe9a983af60f6015' ]] && pass 'step-195 policy has the exact reviewed SHA-256' || fail 'step-195 policy SHA-256 mismatch'
[[ $(sha "$RECORD") == 'aa37378cc4e3af31fc37a0a111b9ab0e39f3bf784e011168f962e165927a01a5' ]] && pass 'step-195 record has the exact reviewed SHA-256' || fail 'step-195 record SHA-256 mismatch'
[[ $(sha "$STEP194_HELPER") == '4d6eeac51205934663f7669242c0124f7a5cd4d99b994b6b4d1315e07ccb719f' ]] && pass 'accepted step-194 helper has the exact reviewed SHA-256' || fail 'accepted step-194 helper SHA-256 mismatch'
[[ $(sha "$STEP194_DOC") == '75c06799591893868f743ef7c0834975ecac9d867f32f56add836fcec40dc106' ]] && pass 'accepted step-194 reference document has the exact reviewed SHA-256' || fail 'accepted step-194 reference document SHA-256 mismatch'
[[ $(sha "$STEP194_POLICY") == '0db70e4cbeba69a607a372181745ef936bcc693cfe11eb8aebf2c3f764c29621' ]] && pass 'accepted step-194 policy has the exact reviewed SHA-256' || fail 'accepted step-194 policy SHA-256 mismatch'
[[ $(sha "$STEP194_RECORD") == 'd2bbc87628a78d79077ecf51732a63dcbec55fc136b3d47ae2702c96867b09c6' ]] && pass 'accepted step-194 record has the exact reviewed SHA-256' || fail 'accepted step-194 record SHA-256 mismatch'
[[ $(sha "$STEP192_POLICY") == 'a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a' ]] && pass 'accepted step-192 runtime-boundary policy has the exact reviewed SHA-256' || fail 'accepted step-192 runtime-boundary policy SHA-256 mismatch'

bash -n "$HELPER" && pass 'step-195 helper is shell-syntax valid' || fail 'step-195 helper has invalid shell syntax'
"$HELPER" --help >/dev/null 2>&1 && pass 'step-195 helper exposes a non-mutating help boundary' || fail 'step-195 helper help failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-195 helper accepts an unknown option'; else pass 'step-195 helper rejects unknown options'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-195 binding-design policy is valid JSON' || fail 'step-195 binding-design policy is invalid JSON'

if python3 - "$POLICY" "$STEP194_POLICY" "$STEP192_POLICY" <<'PY_ASSERT'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
t=json.load(open(sys.argv[2],encoding='utf-8'))
r=json.load(open(sys.argv[3],encoding='utf-8'))
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-package-pair-and-local-source-binding-design'
assert p['review_only'] is True
assert p['accepted_target_binding']['step']==194
assert p['accepted_target_binding']['policy_sha256']=='0db70e4cbeba69a607a372181745ef936bcc693cfe11eb8aebf2c3f764c29621'
assert p['accepted_target_binding']['record_sha256']=='d2bbc87628a78d79077ecf51732a63dcbec55fc136b3d47ae2702c96867b09c6'
assert p['accepted_target_binding']['target_hostname']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert p['accepted_target_binding']['boot_id']=='5e79b100-55a8-415d-a6ea-1cb8c568c2eb'
assert p['accepted_target_binding']['header_package_record']=='kernel-headers-6.18.45-x86-1'
assert p['accepted_runtime_boundary_design']['step']==192
assert p['accepted_runtime_boundary_design']['policy_sha256']=='a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a'
assert p['accepted_runtime_boundary_design']['source_strategy']=='immutable-local-slackpkg-compatible-source'
assert t['runtime_target_binding']['state']=='frozen'
assert t['runtime_target_binding']['header_package_record']=='kernel-headers-6.18.45-x86-1'
assert r['runtime_boundary_design']['transition']['source_strategy']=='immutable-local-slackpkg-compatible-source'

d=p['binding_design']; pair=d['package_pair']; acq=d['artifact_acquisition']; src=d['local_source']; v=d['validity']
assert d['state']=='frozen'
assert pair['state']=='design-frozen-artifacts-unbound'
assert pair['package_name']=='kernel-headers'
assert pair['target_installed_record']=='kernel-headers-6.18.45-x86-1'
assert pair['target_artifact_filename_expected']=='kernel-headers-6.18.45-x86-1.txz'
assert pair['target_signature_filename_expected']=='kernel-headers-6.18.45-x86-1.txz.asc'
assert pair['predecessor_candidate_record']=='kernel-headers-6.18.44-x86-1'
assert pair['predecessor_artifact_filename_expected']=='kernel-headers-6.18.44-x86-1.txz'
assert pair['predecessor_signature_filename_expected']=='kernel-headers-6.18.44-x86-1.txz.asc'
assert pair['predecessor_selection_rule']=='immediate-prior-kernel-headers-release-before-bound-target-in-cumulative-slackware-current-history'
for key in ('same_package_name_required','same_package_arch_required','same_package_build_required','predecessor_must_compare_older_than_target','target_must_match_frozen_installed_record','artifact_sha256_binding_deferred','signature_sha256_binding_deferred','exact_download_origin_binding_deferred','trusted_signing_key_binding_deferred','detached_signature_verification_required_before_source_build','artifact_sha256_verification_required_before_source_build'):
    assert pair[key] is True
assert acq['state']=='not-authorized'
assert acq['controller_only_when_later_authorized'] is True
assert acq['target_vm_network_access_forbidden'] is True
assert acq['predecessor_and_target_package_bytes_required'] is True
assert acq['predecessor_and_target_detached_signatures_required'] is True
assert acq['exact_origin_and_hashes_must_be_frozen_before_target_copy'] is True
assert acq['no_target_copy_authorized_by_this_step'] is True
assert src['state']=='design-frozen-source-bytes-unbound'
assert src['strategy']=='deterministically-generated-minimal-file-mirror-from-bound-target-artifact'
assert src['planned_builder_path']=='tools/reference/phase-1-kernel-package-edge-local-source-build.sh'
assert src['runtime_root']=='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
assert src['runtime_mirror_uri']=='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
assert src['target_package_relative_path']=='slackware64/d/kernel-headers-6.18.45-x86-1.txz'
assert src['required_metadata_files']==['ChangeLog.txt','FILELIST.TXT','PACKAGES.TXT','CHECKSUMS.md5']
for key in ('target_package_only_exposed','artifact_authenticity_must_be_verified_before_source_build','runtime_must_not_depend_on_generated_metadata_for_artifact_authenticity','temporary_generated_metadata_signature_check_may_be_disabled_only_inside_bound_runtime_configuration','source_tree_manifest_sha256_binding_deferred','source_file_sha256_set_binding_deferred','source_tree_must_be_read_only_after_build','source_tree_must_be_hash_verified_before_and_after_reference_apply'):
    assert src[key] is True
assert src['generated_metadata_is_upstream_signed'] is False
assert src['runtime_network_access_allowed'] is False
assert src['target_vm_artifact_download_allowed'] is False
assert d['candidate_guard_preserved']=='after-local-source-refresh-exactly-one-upgrade-candidate-and-it-is-the-selected-kernel-header-package'
assert d['install_new_candidate_count_required']==0
assert d['non_header_upgrade_candidate_count_required']==0
assert d['kernel_boot_upgrade_candidate_count_required']==0
assert d['reference_apply_path']=='tools/reference/slack-update-reference.sh'
assert d['reference_apply_mode']=='--apply'
assert d['tested_transition_must_be_performed_by_reference_apply'] is True
assert d['boot_mutation_allowed'] is False and d['boot_configuration_mutation_allowed'] is False
assert d['reboot_allowed'] is False and d['unrelated_package_mutation_allowed'] is False
assert d['live_candidate_set_bound'] is False and d['live_runtime_chain_open'] is False
assert v['target_binding_from_step_194_must_remain_valid_before_any_target_copy'] is True
assert v['target_reboot_or_package_drift_requires_return_to_target_binding_review'] is True
assert v['controller_reference_or_effective_configuration_drift_requires_return_to_target_binding_review'] is True
assert v['later_slackware_current_publication_invalidates_this_design'] is False
assert v['later_publication_must_not_replace_the_bound_6_18_45_target_identity'] is True
assert v['artifact_binding_failure_action']=='stop-before-target-copy-or-package-staging'
a=p['authorization']
assert a['package_pair_and_local_source_binding_review_authorized_for_next_stage'] is True
for key in ('controller_artifact_acquisition_authorized','target_artifact_copy_authorized','package_pair_binding_authorized','local_source_binding_authorized','runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'):
    assert a[key] is False
assert p['machine_action_required'] is False
assert p['slackware_current_publication_invalidates_design'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-package-pair-and-local-source-binding-review'
assert p['pause_safe'] is False
PY_ASSERT
then pass 'step-195 package-pair and local-source binding design completed successfully'; else fail 'step-195 binding-design semantic assertions failed'; fi

expect_line $'binding_design_state\tfrozen' 'binding design is frozen'
expect_line $'selected_package_name\tkernel-headers' 'selected package remains kernel-headers'
expect_line $'target_installed_record\tkernel-headers-6.18.45-x86-1' 'target installed record remains bound to 6.18.45'
expect_line $'target_artifact_filename_expected\tkernel-headers-6.18.45-x86-1.txz' 'expected target artifact filename is frozen'
expect_line $'predecessor_candidate_record\tkernel-headers-6.18.44-x86-1' 'immediate predecessor candidate is frozen'
expect_line $'predecessor_artifact_filename_expected\tkernel-headers-6.18.44-x86-1.txz' 'expected predecessor artifact filename is frozen'
expect_line $'artifact_sha256_binding_deferred\tyes' 'artifact SHA-256 binding remains deferred'
expect_line $'signature_sha256_binding_deferred\tyes' 'signature SHA-256 binding remains deferred'
expect_line $'exact_download_origin_binding_deferred\tyes' 'download-origin binding remains deferred'
expect_line $'detached_signature_verification_required_before_source_build\tyes' 'detached signatures must be verified before source build'
expect_line $'local_source_strategy\tdeterministically-generated-minimal-file-mirror-from-bound-target-artifact' 'minimal deterministic file mirror strategy is frozen'
expect_line $'local_source_builder_path\ttools/reference/phase-1-kernel-package-edge-local-source-build.sh' 'planned local-source builder path is frozen'
expect_line $'local_source_runtime_root\t/var/tmp/slack-update-acceptance/kernel-package-edge/local-source' 'local-source runtime root is frozen'
expect_line $'local_source_mirror_uri\tfile:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source' 'local file mirror URI is frozen'
expect_line $'local_source_target_package_relative_path\tslackware64/d/kernel-headers-6.18.45-x86-1.txz' 'target package relative source path is frozen'
expect_line $'local_source_required_metadata_files\tChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5' 'required local-source metadata set is frozen'
expect_line $'local_source_target_package_only_exposed\tyes' 'local source exposes only the bound target package'
expect_line $'local_source_tree_manifest_binding_deferred\tyes' 'source-tree manifest binding remains deferred'
expect_line $'runtime_network_access_allowed\tno' 'runtime network access remains forbidden'
expect_line $'target_vm_artifact_download_allowed\tno' 'target VM artifact download remains forbidden'
expect_line $'candidate_guard\tafter-local-source-refresh-exactly-one-upgrade-candidate-and-it-is-the-selected-kernel-header-package' 'header-only candidate guard is preserved'
expect_line $'install_new_candidate_count_required\t0' 'install-new candidate count remains zero'
expect_line $'non_header_upgrade_candidate_count_required\t0' 'non-header upgrade candidate count remains zero'
expect_line $'kernel_boot_upgrade_candidate_count_required\t0' 'kernel boot-package candidate count remains zero'
expect_line $'live_candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'controller_artifact_acquisition_authorized\tno' 'controller artifact acquisition is not authorized'
expect_line $'target_artifact_copy_authorized\tno' 'target artifact copy is not authorized'
expect_line $'package_pair_binding_authorized\tno' 'package-pair binding is not authorized'
expect_line $'local_source_binding_authorized\tno' 'local-source binding is not authorized'
expect_line $'runtime_executor_implementation_authorized\tno' 'runtime executor implementation is not authorized'
expect_line $'runtime_scenario_execution_authorized\tno' 'runtime scenario execution is not authorized'
expect_line $'machine_execution_authorized\tno' 'machine execution is not authorized'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'reboot_authorized\tno' 'reboot is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 195 requires no machine action'
expect_line $'slackware_current_publication_invalidates_design\tno' 'later Slackware-current publication does not invalidate the design'
expect_line $'next_stage\tphase-1-kernel-package-edge-package-pair-and-local-source-binding-review' 'next stage is package-pair and local-source binding review'
expect_line $'pause_safe\tno' 'step 195 remains inside the active chain'

repro_dir=$(mktemp -d)
if "$HELPER" --output-dir "$repro_dir" >/dev/null 2>&1 && cmp -s "$POLICY" "$repro_dir/$(basename "$POLICY")" && cmp -s "$RECORD" "$repro_dir/$(basename "$RECORD")"; then
    pass 'step-195 evidence reproduces deterministically in an isolated output directory'
else
    fail 'step-195 evidence does not reproduce deterministically'
fi
rm -rf -- "$repro_dir"

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'kernel-headers-6.18.44-x86-1.txz'* && $normalized_doc == *'kernel-headers-6.18.45-x86-1.txz'* && $normalized_doc == *'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source'* && $normalized_doc == *'phase-1-kernel-package-edge-package-pair-and-local-source-binding-review'* ]]; then pass 'reference document records package pair, offline local source, and next stage'; else fail 'step-195 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 195 kernel-package-edge package-pair and local-source binding design' "$CHANGELOG" && grep -Fq 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-review' "$CHANGELOG"; then pass 'CHANGELOG records step 195'; else fail 'CHANGELOG does not record step 195'; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$HELPER"; then fail 'step-195 helper executes a package, boot, reboot, or shutdown mutation command'; else pass 'step-195 helper executes no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '^[[:space:]]*(curl|wget|rsync|scp|ssh|ping)([[:space:]]|$)' "$HELPER"; then fail 'step-195 helper executes a network client command'; else pass 'step-195 helper executes no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
