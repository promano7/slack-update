#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-boundary-design.sh"
DOC="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-boundary-design.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design.tsv"
STEP191_HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-contract-freeze.sh"
STEP191_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze-policy.json"
STEP191_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

for spec in \
    "$HELPER|step-192 runtime-boundary helper" \
    "$DOC|step-192 reference document" \
    "$POLICY|step-192 design policy" \
    "$RECORD|step-192 design record" \
    "$STEP191_HELPER|accepted step-191 contract helper" \
    "$STEP191_POLICY|accepted step-191 contract policy" \
    "$STEP191_RECORD|accepted step-191 contract record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done
check_hash "$HELPER" '6d60eab66bf569832f6998193629ec04993e22554b792e1ceae37076241bd7c8' 'step-192 runtime-boundary helper'
check_hash "$DOC" 'e8d66f7b0e8ea2d2a91d47d8c322f64f42c62aa136e0cdaa6737d26b8a3bf0a1' 'step-192 reference document'
check_hash "$POLICY" 'a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a' 'step-192 design policy'
check_hash "$RECORD" 'e244ecf5286a9b9e4f448151c1926469bb5c8b892091ea26e52b61c85c8e1d9e' 'step-192 design record'
check_hash "$STEP191_HELPER" 'd47e283f81738763563cdc27f17a2badf7a44cdb8d11240be4d01c4a3dce3896' 'accepted step-191 contract helper'
check_hash "$STEP191_POLICY" '95f065e015106467e25f81d1cb9c4199967edd51aee821ed70d3001c301a35fc' 'accepted step-191 contract policy'
check_hash "$STEP191_RECORD" 'ab90fa4f61dd5de7db5fe76cebcd72adfe7d25c95d6925aeb1c67bd09db7f28d' 'accepted step-191 contract record'

if bash -n "$HELPER"; then pass 'step-192 runtime-boundary helper is shell-syntax valid'; else fail 'step-192 runtime-boundary helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-192 helper exposes a non-mutating help boundary'; else fail 'step-192 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-192 helper accepts unknown options'; else pass 'step-192 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-192 design policy is valid JSON'; else fail 'step-192 design policy is invalid JSON'; fi

output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-192 kernel-package-edge runtime-boundary design completed successfully'; else fail 'step-192 runtime-boundary helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_contract_step\t191' 'design starts from accepted step 191'
expect_line $'selected_family\tkernel-package-edge' 'design preserves kernel-package-edge family'
expect_line $'scenario_count\t1' 'design preserves the single selected scenario'
expect_line $'runtime_boundary_design_state\tfrozen' 'runtime-boundary design is frozen'
expect_line $'target_class\tslackware-current-runtime-validation-vm' 'target class is Slackware-current validation VM'
expect_line $'target_binding_deferred\tyes' 'exact machine binding remains deferred'
expect_line $'package_pair_binding_deferred\tyes' 'exact predecessor/target package pair remains deferred'
expect_line $'local_source_binding_deferred\tyes' 'exact immutable local source remains deferred'
expect_line $'live_candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'transition_strategy\tcontrolled-predecessor-stage-then-reference-upgrade-against-immutable-local-slackpkg-source' 'controlled predecessor-stage/reference-upgrade strategy is frozen'
expect_line $'source_strategy\timmutable-local-slackpkg-compatible-source' 'runtime source is immutable and slackpkg-compatible'
expect_line $'network_access_during_runtime_allowed\tno' 'runtime is designed to be network-independent'
expect_line $'official_package_artifacts_required\tyes' 'genuine Slackware package artifacts are required'
expect_line $'staging_mutation_scope\tselected-configured-kernel-header-package-only' 'staging mutation is restricted to the selected header package'
expect_line $'tested_transition_performed_by_reference_apply\tyes' 'tested transition must be performed by reference apply'
expect_line $'reference_apply_path\ttools/reference/slack-update-reference.sh' 'reference implementation path is frozen'
expect_line $'reference_apply_mode\t--apply' 'reference apply mode is frozen'
expect_line $'candidate_guard\tafter-local-source-refresh-exactly-one-upgrade-candidate-and-it-is-the-selected-kernel-header-package' 'candidate guard requires the exact header-only candidate set'
expect_line $'install_new_candidate_count_required\t0' 'install-new candidate count must be zero'
expect_line $'non_header_upgrade_candidate_count_required\t0' 'non-header upgrade candidate count must be zero'
expect_line $'kernel_boot_upgrade_candidate_count_required\t0' 'kernel boot-package candidate count must be zero'
expect_line $'candidate_guard_failure_action\tabort-before-reference-apply-and-restore-pre-test-state' 'candidate-guard failure stops before reference apply'
expect_line $'boot_mutation_allowed\tno' 'boot mutation is forbidden'
expect_line $'boot_configuration_mutation_allowed\tno' 'boot configuration mutation is forbidden'
expect_line $'reboot_allowed\tno' 'reboot is forbidden'
expect_line $'unrelated_package_mutation_allowed\tno' 'unrelated package mutation is forbidden'
expect_line $'configuration_restore_rule\tbyte-for-byte' 'temporary slackpkg configuration must be restored byte-for-byte'
expect_line $'planned_acceptance_executor_path\ttests/acceptance/reference/test-kernel-package-edge.sh' 'planned acceptance executor path is frozen'
expect_line $'planned_execution_acknowledgement\t--execute-runtime-validation' 'future runtime acknowledgement is explicit'
expect_line $'runtime_evidence_root\t/var/tmp/slack-update-acceptance/kernel-package-edge' 'runtime evidence root is frozen'
expect_line $'published_archive_path\t/home/promano/slack-update-phase-1-kernel-package-edge-evidence.tar.gz' 'private evidence archive path is frozen'
expect_line $'rollback_rule\trestore-target-header-and-original-slackpkg-configuration-preserve-evidence-stop' 'rollback rule restores target header and slackpkg configuration'
expect_line $'acceptance_matrix_complete\tno' 'acceptance matrix remains incomplete'
expect_line $'target_binding_review_authorized_for_next_stage\tyes' 'only the next target-binding review is authorized'
expect_line $'package_pair_binding_authorized\tno' 'package pair binding is not yet authorized'
expect_line $'local_source_binding_authorized\tno' 'local source binding is not yet authorized'
expect_line $'runtime_executor_implementation_authorized\tno' 'runtime executor implementation is not authorized'
expect_line $'runtime_execution_authorized\tno' 'runtime execution is not authorized'
expect_line $'repository_refresh_authorized\tno' 'repository refresh is not authorized'
expect_line $'network_refresh_authorized\tno' 'network refresh is not authorized'
expect_line $'machine_execution_authorized\tno' 'machine execution is not authorized'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'reboot_authorized\tno' 'reboot is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 192 requires no machine action'
expect_line $'slackware_current_publication_invalidates_design\tno' 'later Slackware-current publication does not invalidate the unbound design'
expect_line $'next_stage\tphase-1-kernel-package-edge-runtime-target-binding-review' 'next stage is target-binding review'
expect_line $'pause_safe\tno' 'step 192 remains inside the active chain'

if python3 - "$POLICY" "$STEP191_POLICY" <<'PY_ASSERT'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8')); c=json.load(open(sys.argv[2],encoding='utf-8'))
assert c['contract']['family']=='kernel-package-edge' and c['contract']['scenario_count']==1
assert p['review_only'] is True and p['accepted_contract']['step']==191
r=p['runtime_boundary_design']; t=r['transition']; e=r['evidence']
assert r['state']=='frozen' and r['target_class']=='slackware-current-runtime-validation-vm'
assert r['target_binding_deferred'] is True and r['package_pair_binding_deferred'] is True and r['local_source_binding_deferred'] is True
assert r['live_candidate_set_bound'] is False and r['live_runtime_chain_open'] is False
assert t['strategy']=='controlled-predecessor-stage-then-reference-upgrade-against-immutable-local-slackpkg-source'
assert t['official_package_artifacts_required'] is True and t['exact_package_pair_binding_deferred'] is True
assert t['package_pair_must_share_slackware_package_name'] is True and t['predecessor_must_differ_from_target'] is True
assert t['boot_packages_must_already_match_target_source_before-staging'] is True
assert t['staging_package_mutation_must_touch_only_selected_header_package'] is True
assert t['tested_transition_must_be_performed_by_reference_apply'] is True
assert t['reference_apply_path']=='tools/reference/slack-update-reference.sh' and t['reference_apply_mode']=='--apply'
assert t['source_strategy']=='immutable-local-slackpkg-compatible-source'
assert t['source_must_be_network-independent_during-runtime'] is True and t['source_metadata_and_target_package_must_be_hash-bound'] is True
assert t['install_new_candidate_count_required']==0 and t['non_header_upgrade_candidate_count_required']==0 and t['kernel_boot_upgrade_candidate_count_required']==0
assert len(e['pre_baseline'])==7 and len(e['bound_source'])==4 and len(e['staged_precondition'])==5 and len(e['reference_transition'])==8 and len(e['final_state'])==7
assert r['configuration_restore_rule']=='all-temporary-slackpkg-configuration-changes-must-be-restored-byte-for-byte'
assert r['boot_mutation_allowed'] is False and r['boot_configuration_mutation_allowed'] is False and r['reboot_allowed'] is False
assert r['network_access_during_runtime_allowed'] is False and r['unrelated_package_mutation_allowed'] is False
assert r['setup_header_package_mutation_may_be_authorized_later'] is True and r['reference_header_package_mutation_may_be_authorized_later'] is True
a=p['authorization']
assert a['target_binding_review_authorized_for_next_stage'] is True
for key in ('package_pair_binding_authorized','local_source_binding_authorized','runtime_executor_implementation_authorized','runtime_execution_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'):
    assert a[key] is False
assert p['machine_action_required'] is False and p['slackware_current_publication_invalidates_design'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-target-binding-review' and p['pause_safe'] is False
PY_ASSERT
then pass 'design policy freezes a reproducible header-only transition with candidate guard and rollback'; else fail 'step-192 design semantic assertions failed'; fi

repro_dir=$(mktemp -d)
if "$HELPER" --output-dir "$repro_dir" >/dev/null 2>&1 && cmp -s "$POLICY" "$repro_dir/$(basename "$POLICY")" && cmp -s "$RECORD" "$repro_dir/$(basename "$RECORD")"; then
    pass 'step-192 evidence reproduces deterministically in an isolated output directory'
else
    fail 'step-192 evidence does not reproduce deterministically'
fi
rm -rf -- "$repro_dir"

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'immutable local'* && $normalized_doc == *'exact candidate set contains one upgrade only'* && $normalized_doc == *'slack-update-reference.sh --apply'* && $normalized_doc == *'phase-1-kernel-package-edge-runtime-target-binding-review'* ]]; then pass 'reference document records immutable source, candidate guard, reference transition, and next stage'; else fail 'step-192 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 192 kernel-package-edge runtime-boundary design' "$CHANGELOG" && grep -Fq 'phase-1-kernel-package-edge-runtime-target-binding-review' "$CHANGELOG"; then pass 'CHANGELOG records step 192'; else fail 'CHANGELOG does not record step 192'; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$HELPER"; then fail 'step-192 helper executes a package, boot, reboot, or shutdown mutation command'; else pass 'step-192 helper executes no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '^[[:space:]]*(curl|wget|rsync|scp|ssh)([[:space:]]|$)' "$HELPER"; then fail 'step-192 helper executes a network client command'; else pass 'step-192 helper executes no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
