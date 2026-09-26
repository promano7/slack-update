#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.sh"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-executor-design-review-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.md"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-candidate-set-binding-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.tsv"
reference="$repo_root/tools/reference/slack-update-reference.sh"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }

for f in "$helper" "$policy" "$record" "$doc" "$prior_helper" "$prior_policy" "$prior_record" "$reference"; do
    assert "$(basename "$f") is a regular file" test -f "$f"
    assert "$(basename "$f") is not a symlink" test ! -L "$f"
done

assert_hash() {
    local label=$1 file=$2 expected=$3 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}
assert_hash 'accepted step-214 helper hash is frozen' "$prior_helper" '6bbc9e32e52163025a8947e0a8cb172c8a710ab91dc8420c9a940b9186a325e2'
assert_hash 'accepted step-214 policy hash is frozen' "$prior_policy" 'c5fcead64abd1c2d4136c754da6bcca56e2ec5ed16ba1e7193d55c8dceff21aa'
assert_hash 'accepted step-214 record hash is frozen' "$prior_record" 'fd76bd3d83f50e71210bc7b38f2604eb119432ec716af64f0b8608c440228007'
assert_hash 'frozen reference script hash is preserved' "$reference" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
assert 'step-215 helper passes bash syntax validation' bash -n "$helper"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-215 helper executes successfully'; else fail 'step-215 helper executes successfully'; fi
assert 'generated step-215 policy matches frozen fixture' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'generated step-215 record matches frozen fixture' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS executor design review' grep -Fqx $'executor_design_review_status\tPASS' "$tmp/helper.out"
assert 'helper reports reviewed design state' grep -Fqx $'executor_design_state\treviewed' "$tmp/helper.out"
assert 'helper preserves same-transaction candidate lifetime' grep -Fqx $'candidate_binding_lifetime\tsame-runtime-transaction-only' "$tmp/helper.out"
assert 'helper forbids runtime external network' grep -Fqx $'runtime_external_network_access_allowed\tno' "$tmp/helper.out"
assert 'helper keeps runtime execution unauthorized' grep -Fqx $'runtime_scenario_execution_authorized\tno' "$tmp/helper.out"

python3 - "$policy" "$record" <<'PY' >"$tmp/semantic.out"
import csv
import json
import sys

p = json.load(open(sys.argv[1], encoding='utf-8'))
with open(sys.argv[2], encoding='utf-8', newline='') as handle:
    r = dict(csv.reader(handle, delimiter='\t'))

d = p['runtime_transaction_executor_design']
f = p['frozen_inputs']
a = p['authorization']
checks = {
    'policy identifies step-215 scenario': p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-design-review',
    'step-214 same-transaction contract is consumed': p['accepted_step_214']['same_transaction_candidate_contract_consumed'] is True,
    'design is repository-only reviewed state': p['review_only'] is True and d['state'] == 'reviewed',
    'target does not require repository': d['target_requires_repository'] is False,
    'standalone payload keeps predecessor transport separate': d['payload_form'] == 'single-self-contained-shell-script-plus-separately-transported-frozen-predecessor-package',
    'runtime acknowledgement is explicit': d['runtime_acknowledgement'] == '--execute-runtime-validation',
    'fresh boot ID is preserved': f['boot_id'] == '91901677-1dc3-4a39-a4b1-3f87e6875234' and r['fresh_boot_id'] == f['boot_id'],
    'reference script identity is frozen': f['reference_script_sha256'] == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
    'effective configuration identity is frozen': f['effective_config_sha256'] == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'predecessor identity is frozen': f['predecessor_record'] == 'kernel-headers-6.18.44-x86-1' and f['predecessor_sha256'] == '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
    'target identity is frozen': f['target_record'] == 'kernel-headers-6.18.45-x86-1' and f['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'local source manifest is frozen': f['local_source_tree_manifest_sha256'] == '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'preflight fails before mutation on drift': d['pre_execution_gate']['drift_action'] == 'abort-before-any-package-or-slackpkg-mutation-and-return-to-revalidation-review',
    'preflight requires absent fresh evidence root': d['pre_execution_gate']['runtime_evidence_root_must_be_absent'] is True,
    'derived config disables unrelated modules': all(d['runtime_config_derivation']['allowed_overrides'][k] == 'disabled' for k in ['flatpak.mode','sbo.mode','elf.mode','cinnamon.mode']),
    'derived config preserves boot auto': d['runtime_config_derivation']['boot.mode_must_remain'] == 'auto',
    'derived config preserves Slackware actions': d['runtime_config_derivation']['slackware.install_new_must_remain'] is True and d['runtime_config_derivation']['slackware.upgrade_all_must_remain'] is True,
    'network namespace blocks external access': d['network_boundary']['external_network_access_allowed'] is False and d['network_boundary']['candidate_refresh_and_reference_apply_run_in_network_namespace'] is True,
    'local file source remains usable': d['network_boundary']['local_file_source_remains_accessible'] is True,
    'Slackpkg config and state are backed up': d['slackpkg_transaction']['backup_before_mutation_required'] is True and d['slackpkg_transaction']['state_root'] == '/var/lib/slackpkg',
    'temporary mirror is exact local source': d['slackpkg_transaction']['temporary_mirror_exact_value'] == 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source/',
    'generated metadata GPG relaxation is bounded': d['slackpkg_transaction']['temporary_checkgpg_value'] == 'off' and d['slackpkg_transaction']['generated_metadata_authenticity_is_not_trusted'] is True,
    'package authenticity stays detached-signature bound': d['slackpkg_transaction']['package_authenticity_source'] == 'frozen-step-197-detached-signature-byte-binding',
    'Slackpkg configuration restore is byte-for-byte': d['slackpkg_transaction']['configuration_restore_byte_for_byte_required'] is True,
    'Slackpkg state restore is byte-for-byte': d['slackpkg_transaction']['state_restore_byte_for_byte_required'] is True,
    'staging changes only selected header': d['package_transition']['staging_may_change_only_selected_header_package'] is True,
    'staging preserves running kernel and boot state': d['package_transition']['running_kernel_must_not_change'] is True and d['package_transition']['boot_artifacts_must_not_change'] is True and d['package_transition']['configured_boot_package_records_must_not_change'] is True,
    'candidate binding stays same transaction': d['candidate_guard']['binding_lifetime'] == 'same-runtime-transaction-only' and d['candidate_guard']['must_be_consumed_without_pause'] is True,
    'candidate guard requires one header upgrade': d['candidate_guard']['expected_upgrade_count'] == 1 and d['candidate_guard']['expected_upgrade_package'] == 'kernel-headers',
    'candidate guard excludes install-new and unrelated upgrades': d['candidate_guard']['expected_install_new_count'] == 0 and d['candidate_guard']['expected_non_header_upgrade_count'] == 0 and d['candidate_guard']['expected_configured_boot_upgrade_count'] == 0,
    'reference apply uses frozen script and structured output': d['reference_apply']['sha256'] == f['reference_script_sha256'] and d['reference_apply']['mode'] == '--apply' and d['reference_apply']['structured_output'] == '--json',
    'reference apply expects kernel header edge': d['reference_apply']['expected_kernel_trigger'] == 1 and d['reference_apply']['expected_initrd_update'] == 0 and d['reference_apply']['expected_grub_update'] == 0,
    'external-module warning is required': d['reference_apply']['external_module_warning_required'] is True,
    'boot preparation is forbidden': d['reference_apply']['boot_preparation_action_forbidden'] is True,
    'rollback trap precedes first mutation': d['rollback_and_cleanup']['cleanup_trap_installed_before_first_mutation'] is True,
    'failure restores target header': d['rollback_and_cleanup']['on_any_failure_restore_target_header_from_staged_target'] is True,
    'failure cannot leave predecessor installed': d['rollback_and_cleanup']['predecessor_may_not_be_left_installed_as_terminal_state'] is True,
    'rollback restores Slackpkg and GenInitrd state': d['rollback_and_cleanup']['restore_slackpkg_configuration_byte_for_byte'] and d['rollback_and_cleanup']['restore_slackpkg_state_byte_for_byte'] and d['rollback_and_cleanup']['restore_geninitrd_policy_to_original_fingerprint'],
    'final header returns to target': d['final_invariants']['header_record'] == 'kernel-headers-6.18.45-x86-1',
    'final package database returns to frozen manifest': d['final_invariants']['package_database_manifest_sha256'] == '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'final boot identity is unchanged': d['final_invariants']['running_kernel'] == '6.18.45' and d['final_invariants']['boot_id'] == '91901677-1dc3-4a39-a4b1-3f87e6875234',
    'final local source and target bytes remain unchanged': d['final_invariants']['local_source_tree_unchanged'] and d['final_invariants']['staged_target_unchanged'],
    'evidence contract includes candidate and reference outputs': 'exact-candidate-binding' in d['evidence_contract'] and 'reference-stdout-stderr-json-and-exit-status' in d['evidence_contract'],
    'only implementation review is opened': a['repository_only_runtime_transaction_executor_implementation_review_authorized'] is True,
    'executor build and transport remain unauthorized': a['runtime_executor_build_authorized'] is False and a['runtime_executor_transport_authorized'] is False,
    'predecessor transport and staging remain unauthorized': a['predecessor_package_transport_authorized'] is False and a['predecessor_package_staging_authorized'] is False,
    'Slackpkg mutation remains unauthorized': a['temporary_slackpkg_configuration_authorized'] is False and a['local_source_metadata_refresh_authorized'] is False,
    'candidate and reference execution remain unauthorized': a['runtime_candidate_binding_authorized'] is False and a['reference_apply_authorized'] is False and a['runtime_scenario_execution_authorized'] is False,
    'package network boot reboot remain unauthorized': a['package_action_authorized'] is False and a['network_access_authorized'] is False and a['boot_action_authorized'] is False and a['reboot_authorized'] is False,
    'no machine or controller action is required': p['machine_action_required'] is False and p['controller_action_required'] is False,
    'step is not a safe pause': p['pause_safe'] is False and p['strong_safe_pause'] is False,
    'next stage is implementation review': p['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review',
}
for label, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + '\t' + label)
PY
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s ' ')
[[ $normalized_doc == *'network namespace with no external interfaces'* ]] && pass 'reference document records network isolation' || fail 'reference document records network isolation'
[[ $normalized_doc == *'disabling the Flatpak, SBo, ELF, and Cinnamon modules'* ]] && pass 'reference document records secondary module isolation' || fail 'reference document records secondary module isolation'
[[ $normalized_doc == *'Leaving the 6.18.44 predecessor installed is never an acceptable terminal state'* ]] && pass 'reference document records mandatory rollback' || fail 'reference document records mandatory rollback'
assert 'CHANGELOG records step 215' grep -Fq '## Phase 1 step 215 kernel-package-edge runtime transaction executor design review' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable package/network/boot/reboot command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|unshare)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
