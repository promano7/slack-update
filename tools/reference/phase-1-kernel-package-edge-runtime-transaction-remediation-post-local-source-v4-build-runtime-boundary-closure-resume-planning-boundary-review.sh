#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only resume planning; no machine authority.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYPLAN'
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile

def validate_resume_plan(plan, closed, frozen):
    def exact(actual, expected, label):
        if json.dumps(actual, sort_keys=True, separators=(',', ':')) != json.dumps(expected, sort_keys=True, separators=(',', ':')):
            raise ValueError(label)
    for key, value in dict(schema=1, step=299, scenario='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review', review_status='PASS', review_only=True,
                           state='resume-plan-prepared-user-checkpoint-pending',
                           confirmed_step298_supersedes_prepared_wording_without_editing_history=True,
                           accepted_step298_pause_remains_valid_as_historical_checkpoint=True).items():
        exact(plan.get(key), value, 'plan status ' + key)
    accepted = plan['accepted_checkpoint']
    expected_checkpoint = dict(step=298, commit_prefix='acc26e3', commit_full=None,
                               commit_identity_scope='user-returned-seven-character-prefix-full-object-id-not-supplied',
                               acceptance_result='PASS (304 passes, 0 failures)', user_application_completed=True,
                               user_commit_and_push_completed=True, user_worktree_clean=True, strong_safe_pause=True,
                               repository_file_count=1274,
                               provenance='complete-user-return-not-independent-user-host-or-GitHub-inspection',
                               changelog_verification='exact-step298-bytes-are-the-suffix-of-current-changelog')
    for key, value in expected_checkpoint.items():
        exact(accepted.get(key), value, 'checkpoint ' + key)
    if not isinstance(accepted['sha256_bindings'], dict) or len(accepted['sha256_bindings']) != 1274:
        raise ValueError('incomplete accepted manifest')
    if type(accepted['changelog_size_bytes']) is not int or accepted['changelog_size_bytes'] <= 0:
        raise ValueError('invalid historical CHANGELOG size')
    exact(plan['accepted_authority_and_effect_closure'], closed, 'changed historical closure')
    exact(plan['accepted_runtime_boundary'], frozen, 'changed frozen source/candidate/executor boundary')
    if not closed['all_authority_closed'] or not closed['all_operational_authority_closed'] or any(closed['authorization'].values()):
        raise ValueError('predecessor authority not closed')
    if closed['effects']['unresolved_transaction'] or closed['effects']['unreviewed_partial_publication']:
        raise ValueError('unreviewed historical obligations')
    expected_fresh = dict(scope='repository-only-v4-runtime-executor-preparation', old_live_binding_state='expired-at-step298',
        current_boot_id=None, current_boot_continuity_asserted=False, current_target_or_source_preservation_observed=False,
        current_predecessor_availability_observed=False, current_pkglist_sha256=None, current_candidate_count=None,
        current_candidate_binding_created=False, v4_runtime_pkglist_generation_observed=False,
        no_operational_authority_inherited=True, future_executor_state_at_resume='absent-not-implemented-no-hash',
        future_executor_path=frozen['executor']['future_executor_path'], future_executor_sha256=None,
        phase1_matrix_complete=False, kernel_package_edge_complete=False, phase2_open=False)
    exact(plan['fresh_boundary'], expected_fresh, 'invented live binding, executor or project acceptance')
    expected_authority = dict.fromkeys(closed['authorization'], False)
    expected_authority['repository_only_transaction_contract_review_authorized'] = True
    exact(plan['authorization'], expected_authority, 'inherited, extra or prematurely opened authority')
    exact(plan['authorization_scope'], 'only-next-repository-transaction-contract-review-after-user-step299-checkpoint', 'authority checkpoint gate')
    road = plan['roadmap']
    for key, value in dict(preferred_step_count=10, maximum_planned_step_count=12,
        supersedes_closed_step289_roadmap_optional299_300=True, roadmap_grants_machine_authority=False,
        roadmap_grants_later_repository_stages=False, runtime_attempt_planned=False,
        fresh_live_observation_planned=False, pause_by_numeric_step_guaranteed=False,
        incomplete_output_is_not_success_or_pause=True, reviewed_effect_free_rejection_can_close_earlier=True,
        repair_overlays_require_separate_review_and_user_checkpoint=True, scope_change_requires_new_repository_plan=True).items():
        exact(road.get(key), value, 'roadmap ' + key)
    stem = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime'
    expected_stages = ['phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review'] + [stem + '-' + s for s in [
        'transaction-contract-review', 'transaction-contract-freeze', 'executor-design-review', 'executor-design-freeze',
        'executor-implementation-review', 'executor-failure-coverage-review', 'executor-implementation-freeze',
        'implementation-effect-and-authority-closure-review', 'implementation-closure-and-strong-safe-pause']]
    scopes = ['resume-planning', 'contract-review', 'contract-freeze', 'design-review', 'design-freeze',
              'implementation-review', 'failure-coverage-review', 'implementation-freeze', 'closure-review', 'conditional-closure']
    if len(road['preferred_steps']) != 10:
        raise ValueError('missing preferred stages')
    for offset, row in enumerate(road['preferred_steps']):
        for key, value in dict(step=299 + offset, stage=expected_stages[offset], scope=scopes[offset],
            machine_authority=False, requires_previous_user_checkpoint=(offset != 0), conditional_pause_candidate=(offset == 9)).items():
            exact(row.get(key), value, 'preferred stage ' + str(offset) + ' ' + key)
        if not isinstance(row.get('objective'), str) or not row['objective'].strip():
            raise ValueError('missing stage objective')
    exact(road['optional_failure_steps'], [
        dict(step=309, stage=stem + '-repository-failure-characterization-review', scope='repository-only-failure-review', machine_authority=False),
        dict(step=310, stage=stem + '-repository-failure-closure-and-strong-safe-pause', scope='conditional-reviewed-failure-closure', machine_authority=False)
    ], 'optional stages are not bounded repository failure closure')
    topics = plan['required_design_topics']
    exact(sorted(topics), sorted(['preserved_input_identity', 'fresh_operational_gate', 'isolated_transaction',
        'local_only_refresh', 'fresh_pkglist', 'exact_candidate_binding', 'bounded_package_mutation', 'restoration',
        'publication', 'synthetic_failure_coverage', 'closed_entry', 'historical_acceptance']), 'missing design topic')
    if any(not isinstance(value, str) or not value.strip() for value in topics.values()):
        raise ValueError('empty design topic')
    for key, phrases in dict(fresh_pkglist=['Absent before refresh', 'regular non-symlink nonempty', 'both streams', 'Error downloading from', 'exit0'],
        exact_candidate_binding=['one safe eight-field target row', 'duplicate', 'traversal', 'inside that transaction before apply'],
        restoration=['baseline', 'boot invariants', 'failure status', 'restoration failures'],
        publication=['success only after restoration invariants', 'never on partial failure'],
        closed_entry=['does not authorize', 'missing future grant fails before mutation'],
        historical_acceptance=['exact accepted predecessor files', 'no edits', 'actual repository files']).items():
        if any(phrase not in topics[key] for phrase in phrases):
            raise ValueError('weakened design boundary ' + key)
    preservation = ['accepted_repository_history', 'v4_source_manifest_sidecar_target', 'v3_source_and_failed_v2_evidence',
        'staged_target_and_predecessor_history', 'immutable_builders_probes_historical_executors',
        'step294_semantic_provenance_limits', 'controller_capture_without_cleanup',
        'source_untagged_checksums_and_non_authenticating_marker', 'same_transaction_candidate_and_restoration_contracts']
    exact(plan['preservation'], dict.fromkeys(preservation, True), 'preservation requirement')
    completion = ['complete_repository_acceptance_reviewed', 'code_and_failure_evidence_bound',
        'all_effects_and_obligations_reviewed', 'no_unresolved_transaction_or_partial_publication',
        'no_required_machine_or_controller_cleanup', 'all_stage_and_operational_rights_consumed_or_revoked',
        'old_and_future_unused_live_bindings_expired', 'user_application_acceptance_commit_push_clean_tree_confirmed',
        'completed_checkpoint_independent_of_later_current_publication', 'not_based_on_preflight_alone']
    exact(plan['strong_pause_completion_conditions'], dict.fromkeys(completion, True), 'incomplete strong-pause gate')
    exact(plan['repository_acceptance_scope'], dict(full_accepted304_suite_required=True,
        predecessor_suite_uses_exact_bound_historical_snapshot=True, production_main_entered=False,
        production_executor_sourced_or_run=False, live_observation_performed=False,
        new_executor_implemented_by_step299=False, historical_artifacts_or_constants_patched=False), 'acceptance overclaim')
    for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause', 'user_step299_checkpoint_confirmed']:
        exact(plan[key], False, 'premature state ' + key)
    exact(plan['next_stage'], expected_stages[1], 'wrong next gate')
    return True

root = Path(sys.argv[1])
out = Path(sys.argv[2]).absolute()
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review.md': 'c52d8dacffb8f9b4475a96deb6b0a0fc601b2200fb5493413f18f8da60455e8d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-checkpoint-confirmation.json': '96bfae4a558456dc53a7eb7b313e5b20a03e9ee693c4a1e1f609ccc5b182cdeb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-policy.json': 'c90cada68176cea957390da133be2342f6155f1b62dfd3331e6fc8e54a2fdfdf', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-roadmap.tsv': '6de179130cc63ea418d6c134fca26bb53f5bc1252a119976223c10be51a8fb67', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-step298-user-acceptance.json': '96e3a850cfd24be65eedabae09933dd3c79dd8edb97d585862467a121418c804', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review.tsv': '697616cf7af36d0b57b240e197e3f2f727c833e26f37ce834ed222c778e8346d'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
def fail(message):
    raise SystemExit('ERROR: ' + message)
def safe_regular(path):
    return path.is_file() and not path.is_symlink() and path.resolve() == path.absolute()
if not out.is_dir() or out.resolve() != out:
    fail('output directory must exist without symlink ancestors')
for rel, digest in own_hashes.items():
    path = root / rel
    if not safe_regular(path) or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        fail('changed or unsafe plan input: ' + rel)
plan = json.loads((fixture / (base + '-policy.json')).read_text())
accepted = plan['accepted_checkpoint']
bindings = accepted['sha256_bindings']
historical_bytes = {}
for rel, digest in bindings.items():
    path = root / rel
    if Path(rel).is_absolute() or '..' in Path(rel).parts or not safe_regular(path) or not path.resolve().is_relative_to(root):
        fail('unsafe accepted path: ' + rel)
    content = path.read_bytes()
    if rel == 'CHANGELOG.md':
        content = content[-accepted['changelog_size_bytes']:]
    if hashlib.sha256(content).hexdigest() != digest:
        fail('accepted checkpoint SHA-256 mismatch: ' + rel)
    historical_bytes[rel] = content
closed = json.loads(historical_bytes['tests/fixtures/reference/acceptance/phase-1/' + prior + '-closure.json'])
frozen = json.loads(historical_bytes[closed['preservation']['frozen_boundary_path']])
try:
    validate_resume_plan(plan, closed, frozen)
except (ValueError, KeyError, TypeError) as error:
    fail('resume plan rejected: ' + str(error))
confirmation = json.loads((root / accepted['confirmation_path']).read_text())
receipt = json.loads((root / accepted['evidence_path']).read_text())
original_display = receipt['text'].encode('utf-8')
if receipt['encoding'] != 'utf8-json-text' or hashlib.sha256(original_display).hexdigest() != receipt['original_display_sha256'] or receipt['original_display_sha256'] != accepted['evidence_sha256'] or len(original_display) != receipt['original_display_size_bytes']:
    fail('accepted user display bytes changed')
if confirmation['commit_prefix'] != 'acc26e3' or confirmation['step'] != 298 or not confirmation['prepared_contract_confirmation_gate_satisfied'] or not confirmation['user_harness_completed'] or not confirmation['user_commit_and_push_completed'] or not confirmation['user_worktree_clean'] or not confirmation['strong_safe_pause'] or confirmation['evidence_sha256'] != accepted['evidence_sha256']:
    fail('accepted user checkpoint confirmation incomplete')
publish = [base + suffix for suffix in ['-policy.json', '.tsv', '-roadmap.tsv', '-checkpoint-confirmation.json', '-step298-user-acceptance.json']]
for name in publish:
    if (out / name).exists() or (out / name).is_symlink():
        fail('planning output already exists: ' + name)
# Historical acceptance uses exact bytes, never patched constants or production entry.
with tempfile.TemporaryDirectory(prefix='step299-accepted298-') as directory:
    snapshot = Path(directory) / 'slack-update'
    for rel, content in historical_bytes.items():
        path = snapshot / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
    absent = snapshot / frozen['executor']['future_executor_path']
    if absent.exists() or absent.is_symlink():
        fail('historical snapshot contains a future executor')
    result = subprocess.run(['bash', str(snapshot / 'tests/reference' / ('test-' + prior + '-harness.sh'))], capture_output=True, text=True)
    if result.returncode != 0 or 'Result: PASS (304 passes, 0 failures)' not in result.stdout.splitlines():
        sys.stderr.write(result.stdout + result.stderr)
        fail('full304 historical acceptance failed')
created = []
try:
    for name in publish:
        with (out / name).open('xb') as handle:
            created.append(out / name)
            handle.write((fixture / name).read_bytes())
except BaseException:
    for path in reversed(created):
        path.unlink()
    raise
for key, value in dict(step_299_resume_planning_status='PASS', accepted_step298_revalidated='PASS (304 passes, 0 failures)',
    accepted_step298_strong_pause_confirmed='yes', historical_snapshot_bytes_exact='yes',
    live_target_observation_performed='no', runtime_attempt_authorized='no', new_executor_implemented='no',
    machine_action_required='no', controller_action_required='no', pause_safe='no', strong_safe_pause='no',
    next_stage=plan['next_stage']).items():
    print(key + '\t' + value)
PYPLAN
