#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy
import csv
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause.md': '6b8566ce316c0c424a725556574f60682f11190eb37631b3b770b35356fa8055', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause-policy.json': '1f59e1773194259de7edb6fb1b11ab371047c7f92a2d9669344b9ccdf3beec22', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause.tsv': '869c4eed4424c5c77bc4ada44553c74d250dfc1e868da2a22715449a6333170b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause-result.tsv': 'db2fc3501a701ecd475fa5c824cd512140150770f7a9a456cb210eec6ba1485e', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause.sh': '856c53ce04c8027f5c34d436fc647996fab1eff122e6e277ba0cccc4a9d86717'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
helper = root / 'tools/reference' / (base + '.sh')
policy_path = fixture / (base + '-policy.json')
policy = json.loads(policy_path.read_text())
previous = json.loads((fixture / (prior + '-policy.json')).read_text())
passes = 0

def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)

def run(args):
    return subprocess.run([str(x) for x in args], capture_output=True, text=True)

accepted = policy['accepted_checkpoint']
for rel, digest in (accepted['sha256_bindings'] | own_hashes).items():
    path = root / rel
    check('exact regular artifact: ' + path.name, path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('actual result review identity follows accepted287',policy['schema']==1 and policy['step']==288 and policy['scenario']==base and policy['review_only'] and policy['review_status']=='PASS' and previous['next_stage']==base)
check('confirmedc9170da full155 user checkpoint',accepted['step']==287 and accepted['commit']=='c9170da' and accepted['acceptance_result']=='PASS (155 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete prefix provenance without full object invention',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance']=='complete-user-returned-step287-application-acceptance-commit-push-clean-tree-2026-10-01')
for key in ['design','implementation','implementation_state_scope','current_probe_implementation_state','accepted_freeze_contract','accepted_implementation_freeze_contract','immutable_implementation','accepted_authorization_closure','historical_observation','historical_returned_attempt','future_build_boundary','roadmap','strong_pause_completion_conditions','accepted_observation_authorization','accepted_observation_return_contract','accepted_observation','accepted_build_authorization_review']:
    check('exact historical source/evidence preservation: '+key,policy[key]==previous[key])
check('consumed one-attempt grant and prior controller checkpoint preserved',policy['consumed_single_build_authorization']==previous['single_build_authorization'] and policy['consumed_controller_protocol']==previous['controller_protocol'])
design=policy['design'];implementation=policy['implementation'];grant=policy['consumed_single_build_authorization'];result=policy['accepted_build_result'];artifact=policy['accepted_local_source_v4'];closure=policy['authorization_closure'];runtime=policy['runtime_boundary_after_pause'];safe=policy['safe_pause'];boot=grant['authorization_boot_id']
result_path=root/result['result_path']
with result_path.open(newline='') as handle:
    reader=csv.DictReader(handle,delimiter='\t');fieldnames=reader.fieldnames;rows=list(reader)
check('strict phase-qualified real-tab result header and fields',fieldnames==['phase','field','value'] and all(set(row)==set(fieldnames) and all(row.values()) for row in rows))
check('all27 returned rows preserved without collapsing duplicates',len(rows)==result['field_count']==27 and len({(row['phase'],row['field']) for row in rows})==27 and len({row['field'] for row in rows})<27)
check('three phases ordered with exact lengths',list(dict.fromkeys(row['phase'] for row in rows))==result['phase_order']==['executor-preflight','builder','executor-result'] and [sum(row['phase']==stage for row in rows) for stage in result['phase_order']]==[5,14,8])
values={stage:{row['field']:row['value'] for row in rows if row['phase']==stage} for stage in result['phase_order']}
check('result ordered phase fields and values match complete return',values==result['values_by_phase'] and all([row['field'] for row in rows if row['phase']==stage]==result['ordered_fields_by_phase'][stage] for stage in result['phase_order']))
check('normalized result SHA and exact returned provenance',hashlib.sha256(result_path.read_bytes()).hexdigest()==result['normalized_result_sha256'] and result['provenance']=='complete-user-returned-step287-pair-sha-preflight-builder-executor-and-exit-status-2026-10-01')
check('semantic transcription preserves repeated names without raw identity claim',result['normalization']=='phase-qualified-real-tab-semantic-display-transcription-preserves-repeated-field-names-no-original-stream-byte-identity-claim')
check('pair SHA checks and exact integer exit0 reviewed',result['transported_executor_sha_check_passed'] and result['transported_builder_sha_check_passed'] and result['complete_stdout_stderr_and_exit_status_reviewed'] and not result['stderr_error_text_present_in_return'] and type(result['reported_exit_status']) is int and result['reported_exit_status']==0 and not any(row['field']=='build_attempt_exit_status' for row in rows))
preflight=values['executor-preflight'];built=values['builder'];executed=values['executor-result']
check('all three actual success statuses are PASS',preflight['v4_v2_authorized_build_preflight_status']==built['local_source_v4_build_status']==executed['v4_v2_authorized_build_executor_status']=='PASS')
check('actual fresh UUID, exact builder identity and one start',preflight['authorization_boot_id']==boot=='bcfac4fa-4e6e-450a-aa95-bd591a979b4e' and preflight['authorized_builder_sha256']==grant['builder_sha256'] and preflight['authorization_use_count']=='1' and preflight['authorized_builder_execution_starting']=='yes')
check('actual executor and builder entry reviewed, not preclaimed',result['executor_preflight_passed'] and result['production_executor_invocation_observed'] and result['production_builder_entry_observed'] and result['builder_passed'] and result['executor_passed'] and policy['current_build_execution_state']=='immutable-executor-and-builder-executed-pass-result-reviewed-authority-closed')
check('actual authority consumed with no second execution',executed['authorization_consumed']=='yes' and executed['second_execution_authorized']=='no' and result['authorization_use_count']==1 and result['authority_consumed'] and not result['second_execution_authorized'] and result['successful_exit_does_not_authorize_runtime_or_retry'])
for stage,fields in [('builder',['network_access_performed','package_action_performed','slackpkg_configuration_change_performed','boot_action_performed','reboot_performed']),('executor-result',['slackpkg_refresh_performed','package_action_performed','network_access_performed','boot_action_performed','reboot_performed'])]:
    for key in fields:check('returned no-effect field: '+stage+'/'+key,values[stage][key]=='no')
check('build scope matches newly frozen authority',result['reported_build_scope_and_no_effect_fields_match_frozen_contract'] and built['local_source_v4_root']==grant['permitted_output_paths'][0] and built['tree_manifest']==grant['permitted_output_paths'][1])
check('accepted target/root/manifest match actual result',artifact['state']=='built-accepted-preserve-unchanged' and all(artifact[key]==built[key] for key in ['target_package','target_sha256','tree_manifest','tree_manifest_sha256']) and artifact['root']==built['local_source_v4_root'] and artifact['tree_manifest_sha256_sidecar']==grant['permitted_output_paths'][2])
check('actual manifest identity frozen from successful verified output',artifact['tree_manifest_sha256']=='a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8' and artifact['tree_manifest_identity_provenance']=='actual-user-returned-immutable-builder-output-after-final-tree-and-sidecar-verification')
check('target exact staged SHA and five priority trees',artifact['target_package']=='kernel-headers-6.18.45-x86-1.txz' and artifact['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c' and artifact['priority_trees']==built['priority_trees'].split(',')==['patches','slackware64','extra','pasture','testing'])
check('compatibility marker present and explicitly non-authenticating',built['compatibility_asc_present']==built['compatibility_asc_PGP_marker_present']=='yes' and artifact['compatibility_asc_present'] and artifact['compatibility_asc_PGP_marker_present'] and artifact['compatibility_asc_is_not_openpgp_signature'])
check('all v4 artifacts preserved and verified afresh before use',artifact['tree_and_both_manifest_files_must_be_preserved_unchanged'] and artifact['future_use_requires_actual_tree_manifest_sidecar_and_target_sha_revalidation'])
control=result['control_flow_review']
def function(source,name):
    start=source.index(name+'() {');end=source.index('\n}',start)+2;return source[start:end]+'\n'
builder_source=(root/grant['builder_path']).read_text();executor_source=(root/grant['executor_path']).read_text()
for kind,source in [('builder',builder_source),('executor',executor_source)]:
    for name,digest in control[kind+'_function_sha256'].items():
        check('bound actual success/control function: '+kind+'/'+name,hashlib.sha256(function(source,name).encode()).hexdigest()==digest)
builder_main=function(builder_source,'main');executor_launch=function(executor_source,'launch_verified_builder')
check('actual published tree and sidecar verified before builder PASS',builder_main.index('verify_tree_manifest "$LOCAL_SOURCE_ROOT" "$TREE_MANIFEST" "$TREE_MANIFEST_SHA256" || exit 12')<builder_main.index("printf 'local_source_v4_build_status") and control['final_tree_and_manifest_sidecar_verified_before_builder_pass'])
check('source finalization precedes publication and verify',builder_main.index('finalize_source_tree "$source"')<builder_main.index('mv -- "$source" "$LOCAL_SOURCE_ROOT"')<builder_main.index('verify_tree_manifest "$LOCAL_SOURCE_ROOT"') and control['source_finalized_before_final_publication'])
check('executor PASS only after zero verified Bash builder exit',executor_launch.index('if bash -- "$builder" --build-local-source-v4; then')<executor_launch.index('return "$builder_status"')<executor_launch.index("printf 'v4_v2_authorized_build_executor_status") and control['executor_pass_only_after_zero_builder_exit'])
check('owned cleanup contract preserved and inference explicit','trap cleanup_builder_temp EXIT HUP INT TERM' in builder_main and 'rm -rf -- "$BUILDER_TEMP_ROOT"' in function(builder_source,'cleanup_builder_temp') and control['builder_owned_exit_trap_cleanup_inferred_from_source_and_complete_exit0_return'])
check('no invented independent postbuild observation/stat',not control['temporary_output_absence_independently_observed_after_build'] and not control['post_build_target_or_history_preservation_independently_observed'] and control['claims_are_bound_source_and_return_inferences_not_postbuild_live_probe'] and artifact['final_ownership_and_modes_inferred_from_bound_successful_builder_not_independent_postbuild_stat'])
check('completed contract supports no unresolved transaction conclusion',control['no_unresolved_transaction_or_partial_publication_inferred_from_complete_successful_contract'] and safe['no_unresolved_transaction_or_partial_publication'])
for key in ['step287_executor_invocation_consumes_single_build_authority','all_build_executor_builder_transport_and_execution_authority_revoked','step285_probe_authority_remains_consumed','all_operational_authority_closed','single_grant_not_reusable_after_success','source_and_evidence_preservation_required','no_required_machine_or_controller_action']:
    check('authority closure invariant: '+key,closure[key] is True)
check('no manual retry/chmod/external cleanup allowed',closure['manual_builder_chmod_retry_or_external_cleanup_authorized'] is False)
authorization=policy['authorization']
check('every operational and repository-advance authorization flag closed',all(value is False for value in authorization.values()))
check('prior live binding expired including old boot requirement',runtime['prior_observation_boot_id']==boot and runtime['prior_package_database_manifest_sha256']==previous['accepted_observation']['values']['package_database_manifest_sha256'] and runtime['prior_target_binding_state']=='expired-at-strong-safe-pause' and not runtime['prior_target_binding_reusable_after_pause'] and not runtime['old_vm_boot_continuity_required_after_closure'])
for key in ['future_work_requires_explicit_resume_planning_boundary','fresh_target_revalidation_required_before_any_future_machine_action','accepted_v4_tree_manifest_sidecar_and_staged_target_must_verify_before_use','separate_runtime_source_candidate_and_executor_boundary_review_required','new_explicit_machine_authorization_required','later_publication_may_invalidate_live_state_for_future_work']:
    check('fresh future boundary: '+key,runtime[key] is True)
check('later current publication does not invalidate completed checkpoint',runtime['later_slackware_current_publication_invalidates_completed_checkpoint'] is False and safe['safe_across_later_slackware_current_publication'])
check('no ongoing or independently observed current live state invented',policy['current_boot_id'] is None and not policy['current_target_or_output_preservation_independently_observed'] and policy['current_state_claim_scope']=='completed-SHA-bound-build-return-and-source-control-flow-review-no-continuous-or-independent-postbuild-live-state-claim')
check('strong pause uses completed actual result and closure',safe['state']=='strong-safe-pause-on-user-step288-acceptance' and safe['actual_complete_successful_build_reviewed'] and safe['completion_not_based_on_preflight_alone'] and safe['no_open_operational_authorization'] and safe['completed_artifacts_and_history_preserved'] and safe['old_live_binding_expired_future_machine_work_requires_fresh_evidence'] and safe['user_repository_application_acceptance_commit_push_confirmation_required'])
check('policy strong pause, no required machine/controller action',policy['pause_safe'] is True and policy['strong_safe_pause'] is True and not policy['machine_action_required'] and not policy['controller_action_required'] and all(safe[key]==policy[key] for key in ['pause_safe','strong_safe_pause','machine_action_required','controller_action_required']))
check('family/matrix still open and no automatic next step',not policy['phase_1_acceptance_matrix_complete'] and not policy['kernel_package_edge_complete'] and policy['next_stage_requires_new_explicit_resume'] and policy['next_stage']==next_stage and next_stage.endswith('-post-local-source-v4-build-resume-planning-boundary-review'))
check('repository acceptance reruns no machine path',policy['repository_acceptance_scope']=={'full_accepted155_predecessor_suite_required':True,'returned_result_reviewed_without_machine_rerun':True,'immutable_source_bytes_modified':False,'production_executor_main_entered':False,'production_probe_main_entered':False,'production_builder_entered':False,'host_bound_guards_called':False,'live_target_observation_performed':False,'production_constants_modified':False})
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()]
check('strict unique real-tab result review record',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(dict(record_rows)))
record=dict(record_rows)
check('record exact accepted checkpoint and actual artifact/result identity',record['step']=='288' and record['accepted_checkpoint_step']=='287' and record['accepted_checkpoint_commit']=='c9170da' and record['accepted_checkpoint_acceptance']==accepted['acceptance_result'] and record['reported_build_attempt_exit_status']=='0' and record['returned_result_field_count']=='27' and record['normalized_result_sha256']==result['normalized_result_sha256'] and record['accepted_local_source_v4_tree_manifest_sha256']==artifact['tree_manifest_sha256'])
check('record actual entry, consumed authority and expired binding',all(record[key]=='yes' for key in ['production_executor_invocation_observed','production_builder_entry_observed','build_authority_consumed','all_operational_authority_revoked','old_runtime_binding_expired','future_machine_work_requires_fresh_evidence_and_new_authorization']) and record['current_boot_id']=='not-claimed-after-closure' and record['temporary_output_absence_independently_observed_after_build']=='no')
check('record closed permissions and strong-pause flags consistent',all(record[key]=='no' for key in authorization) and all(record[key]==('yes' if policy[key] else 'no') for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']) and record['next_stage']==next_stage)
source = helper.read_text()
check('helper only invokes accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step288-repository-') as directory:
    tmp = Path(directory); output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full155 authorization suite actually reruns without machine rerun',result.returncode==0 and 'accepted_step287_revalidated\tPASS (155 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-result.tsv']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('publication closes authority and strong pause without machine action', 'build_authority_consumed\tyes' in result.stdout and 'all_operational_authority_revoked\tyes' in result.stdout and 'old_runtime_binding_expired\tyes' in result.stdout and 'machine_action_required\tno' in result.stdout and 'strong_safe_pause\tyes' in result.stdout and 'next_stage_requires_new_explicit_resume\tyes' in result.stdout and ('next_stage\t'+next_stage) in result.stdout)
    before = {path.name: path.read_bytes() for path in output.iterdir()}
    check('duplicate outputs rejected unchanged', run(['bash', '--', helper, '--output-dir', output]).returncode != 0 and {path.name: path.read_bytes() for path in output.iterdir()} == before)
    link = tmp / 'link'; link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('symlink output ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output rejected without creation', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir()
    replica_helper = replica / 'tools/reference' / (base + '.sh')
    for rel in list(accepted['sha256_bindings']) + [key for key in own_hashes if key != f'tools/reference/{base}.sh']:
        target = replica / rel; original = target.read_bytes(); target.write_bytes(original + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed input rejects before freeze publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    target = replica / design['baseline_path']; original = target.read_bytes(); target.unlink(); target.symlink_to(root / design['baseline_path'])
    result = run(['bash', '--', replica_helper, '--output-dir', rejected])
    check('same-content symlink baseline rejected', result.returncode != 0 and not list(rejected.iterdir()))
    target.unlink(); target.write_bytes(original)
    for section, key, value in [
        ('authorization','new_executor_execution_authorized',True),
        ('authorization','new_probe_execution_authorized',True),
        ('runtime_boundary_after_pause','prior_target_binding_reusable_after_pause',True),
        ('accepted_build_result','reported_exit_status',1),
        ('accepted_local_source_v4','tree_manifest_sha256','0'*64),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed freeze or operational permission rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted287 and actual288 strong-pause closure', '## Phase 1 step 288 ' in changelog and 'c9170da' in changelog and artifact['tree_manifest_sha256'] in changelog and 'Accepted the complete actual one-attempt return' in changelog and 'Every authorization flag is false' in changelog and '## Phase 1 step 287 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST