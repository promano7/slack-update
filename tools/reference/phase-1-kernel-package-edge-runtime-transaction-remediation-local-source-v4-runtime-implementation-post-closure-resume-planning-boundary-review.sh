#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only requirements planning; no operational authority.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYPLAN'
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# Constants and bound input identities are inserted by the delivery builder.
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-closure-and-strong-safe-pause'
BASELINE_DIGEST = '2aac81a14019ce945c752ae28fa12ebd9c4c11080d3effea4ac5d756eac220d0'
RECEIPT_DIGEST = '5c2124bf725dfe1da2de9b39795e406e3abc854e747f47e21eb8c15a33f77aac'
CAPABILITIES = ['real-reference-integration-and-selector-equivalence', 'namespace-command-transport-and-no-fallback', 'absolute-backend-path-and-SHA', 'reviewed-platform-writer-serialization', 'fresh-single-use-grant-source-target-predecessor-and-boot', 'real-source-and-archive-revalidation', 'operational-owner-and-publication-path-bindings']
STAGES = ['phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-effects-and-authority-closure-review', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause']
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review.md': 'ef65abeb2ae69ee2af74fad1cb51d33461fc97c8b86b6155934dc989fa4b826f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review-policy.json': '12b48a734212757a85de790a7af4ec27d3cb802bef358e19baa72314c2132fd6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review-checkpoint-confirmation.json': '40aea0966fc0694e7c2bd949511733dc30c1b54820369cc91dc1dca2957181ee', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review-step308-user-acceptance.json': '3a85c1a391e67513314dd75c17bce8f25e54d68901cd78b91a4dd2c3542999b3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review.tsv': '589d2603bea18a3001b2e7408431931b6c67fc6b4f0a3d9d4febff619043ada1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review-roadmap.tsv': '63cae0246af6018b85ee405855caf1ba6c4774e7c90df2d8529609ac754bb491'}
CHANGELOG_PREFIX = '## Phase 1 step309 — post-private-closure resume planning boundary review — 2026-10-04\n\n- Confirmed308: dd0f21e prefix only, complete324 PASS, application/commit/first successful push and empty short status with matching HEAD/origin by original user return. Confirmation remains external to the accepted descriptors; no independent host/GitHub inspection or invented full commit ID.\n- Preserve1351 accepted artifacts and exact CHANGELOG suffix, closed private candidate/freeze306/review307/closure308 and all source/history/evidence. Add eight repository planning/evidence/test artifacts, prepared snapshot1359; no accepted code or descriptor rewrite.\n- New explicit user resume opens repository planning only. Proposed309–318 block reviews seven operational dependencies separately, then cross-dependency/effects/authority review317 and requirements freeze/conditional strong pause318. Historical309–310 reserve is closed; proposed319–320 reserve is not authorization.\n- Each capability review must identify components, allowed/rejected effects, fresh inputs and dependencies, positive/negative proof, Slackware15/current scope and unresolved blockers. Reviewed requirements never mean implemented capability, operational readiness, conformance or live authorization.\n- Carry exact mandatory PRIVATE coverage and candidate identities without weakening; hashes, private emulation and locks confer no live rights. Production/Phase2 closed, operational SHA/bindings null, old grant/boot/pkglist/candidate validity not reusable, historical v2 never sourced or run.\n- Full324 acceptance reruns in exact accepted1351 historical snapshot without patched files/constants. New plan gates reject stale bindings, widened authority, premature pause, incomplete receipt and missing/reordered/sealed-as-complete dependency reviews. No machine/controller observation, attempt or cleanup.\n- Prepared309 user checkpoint pending. Only separate reference/selector requirements review310 after complete user application/tests/commit/push/clean-tree return; roadmap grants no later stages. New pause_safe/strong_safe_pause false, historical308 valid. Phase1/kernel-package-edge incomplete. Final pause requires closed effects/obligations/rights and confirmation, never numeric step or preflight alone.\n\n'
PLAN_KEYS = ['accepted_checkpoint', 'authorization', 'capability_review_requirements', 'confirmed308_supersedes_prepared_wording_without_editing_history', 'controller_action_required', 'deferred_capabilities', 'fresh_boundary', 'frozen_private_scope', 'historical_reserve309_310_closed_not_inherited', 'historical_step308_pause_remains_valid', 'kernel_package_edge_complete', 'machine_action_required', 'new_block_scope', 'new_plan_basis', 'new_repository_artifact_count', 'next_stage', 'next_stage_authorized', 'next_stage_condition', 'operational_conformance', 'operational_executor_sha256', 'operational_implementation_complete', 'operational_readiness', 'pause_safe', 'phase1_matrix_complete', 'phase2_open', 'prepared_repository_file_count', 'production_entry_closed', 'repository_stage_permission', 'review_only', 'review_status', 'roadmap', 'runtime_attempt_planned', 'scenario', 'schema', 'state', 'step', 'strong_pause_completion_conditions', 'strong_safe_pause', 'user_step309_checkpoint_confirmed']


def exact(actual, expected, label):
    if isinstance(actual, set) and isinstance(expected, set):
        actual, expected = sorted(actual), sorted(expected)
    if json.dumps(actual, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(label)


def sha(content):
    return hashlib.sha256(content).hexdigest()


def safe_relative(rel):
    if not isinstance(rel, str) or not rel or '\\' in rel:
        raise ValueError('unsafe relative path')
    path = Path(rel)
    if path.is_absolute() or any(part in ('', '.', '..') for part in rel.split('/')):
        raise ValueError('unsafe relative path')
    return path


def safe_regular(path, root):
    return (path.is_file() and not path.is_symlink()
            and path.absolute() == path.resolve()
            and path.resolve().is_relative_to(root.resolve()))


def validate_confirmation(confirmation, receipt):
    required = dict(schema=1, step=308, state='confirmed-step308-strong-safe-pause',
        commit_prefix='dd0f21e', commit_full=None,
        acceptance_result='PASS (324 passes, 0 failures)',
        confirmed_repository_file_count=1351, accepted_closure_complete=True,
        user_application_completed=True, user_harness_completed=True,
        user_commit_and_push_completed=True, user_worktree_clean=True,
        user_head_matches_origin=True, push_first_attempt_succeeded=True,
        push_retry_required=False, strong_safe_pause=True, pause_safe=True,
        all_current_stage_and_operational_authority_closed=True,
        historical_live_bindings_reusable=False, future_unused_live_bindings_closed=True,
        completed_pause_independent_of_later_current_publication=True,
        not_based_on_preflight_alone=True, production_entry_closed=True,
        operational_readiness=False, operational_conformance=False,
        operational_executor_sha256=None, current_boot_id=None,
        current_pkglist_sha256=None, current_candidate_count=None,
        machine_action_required=False, controller_action_required=False,
        runtime_attempt_planned=False, phase1_matrix_complete=False,
        kernel_package_edge_complete=False, phase2_open=False,
        confirmation_external_to_repository=True,
        repository_bytes_modified_for_confirmation=False,
        repository_prepared_flags_remain_immutable_historical=True,
        prepared308_confirmation_gate_satisfied=True,
        next_stage_authorized=False, reserve309_310_authorized=False,
        reserve309_310_used=False, evidence_sha256=RECEIPT_DIGEST,
        evidence_size_bytes=31192,
        commit_identity_scope='user-returned-seven-character-prefix-full-object-id-not-supplied',
        user_checkpoint_confirmation_scope='complete-user-return324-overlay-current-harness-commit-successful-push-empty-short-status-not-independent-host-or-GitHub-inspection')
    for key, value in required.items():
        exact(confirmation.get(key), value, 'checkpoint confirmation ' + key)
    exact(receipt.get('encoding'), 'utf8-json-text', 'receipt encoding')
    text = receipt.get('text')
    if not isinstance(text, str):
        raise ValueError('receipt text')
    content = text.encode('utf-8')
    exact(len(content), 31192, 'receipt size')
    exact(sha(content), RECEIPT_DIGEST, 'receipt original SHA')
    exact(receipt.get('original_display_sha256'), RECEIPT_DIGEST, 'receipt metadata SHA')
    exact(receipt.get('original_display_size_bytes'), 31192, 'receipt metadata size')
    lines = text.splitlines()
    exact(sum(line.startswith('PASS: ') for line in lines), 324, 'complete original PASS sequence')
    if lines.count('Result: PASS (324 passes, 0 failures)') != 1:
        raise ValueError('original acceptance summary')
    if '[main dd0f21e]' not in text or '1019ff6..dd0f21e  main -> main' not in text:
        raise ValueError('original commit and successful push')
    if 'dd0f21e (HEAD -> main, origin/main, origin/HEAD)' not in text:
        raise ValueError('original matching HEAD and origin')
    return True


def validate_plan(plan, confirmation, receipt, closure, frozen):
    validate_confirmation(confirmation, receipt)
    exact(sorted(plan), PLAN_KEYS, 'unknown or missing plan fields')
    for key, value in dict(schema=1, step=309, scenario=BASE,
        review_status='PASS', review_only=True,
        state='resume-plan-prepared-user-checkpoint-pending',
        user_step309_checkpoint_confirmed=False, pause_safe=False,
        strong_safe_pause=False, machine_action_required=False,
        controller_action_required=False, runtime_attempt_planned=False,
        phase1_matrix_complete=False, kernel_package_edge_complete=False,
        phase2_open=False, production_entry_closed=True,
        operational_implementation_complete=False, operational_readiness=False,
        operational_conformance=False, operational_executor_sha256=None,
        historical_step308_pause_remains_valid=True,
        confirmed308_supersedes_prepared_wording_without_editing_history=True,
        historical_reserve309_310_closed_not_inherited=True,
        new_block_scope='repository-requirements-and-integration-design-only',
        new_plan_basis='explicit-user-resume-after-confirmed308-and-accepted309-318-proposal',
        next_stage=STAGES[1], next_stage_authorized=False,
        next_stage_condition='complete-user309-application-harness-commit-push-clean-tree-return',
        new_repository_artifact_count=8, prepared_repository_file_count=1359).items():
        exact(plan.get(key), value, 'resume boundary ' + key)
    accepted = plan['accepted_checkpoint']
    exact(set(accepted), {'step', 'commit_prefix', 'commit_full', 'repository_file_count',
        'acceptance_result', 'changelog_size_bytes', 'sha256_bindings',
        'confirmation_path', 'receipt_path', 'provenance'}, 'checkpoint fields')
    for key, value in dict(step=308, commit_prefix='dd0f21e', commit_full=None,
        repository_file_count=1351, acceptance_result='PASS (324 passes, 0 failures)',
        confirmation_path=FIXTURE + '/' + BASE + '-checkpoint-confirmation.json',
        receipt_path=FIXTURE + '/' + BASE + '-step308-user-acceptance.json',
        provenance='complete-user-return-not-independent-user-host-or-GitHub-inspection').items():
        exact(accepted.get(key), value, 'accepted checkpoint ' + key)
    bindings = accepted['sha256_bindings']
    if not isinstance(bindings, dict) or len(bindings) != 1351:
        raise ValueError('incomplete accepted manifest')
    exact(sha(json.dumps(bindings, sort_keys=True).encode()), BASELINE_DIGEST, 'accepted manifest identity')
    if type(accepted['changelog_size_bytes']) is not int or accepted['changelog_size_bytes'] <= 0:
        raise ValueError('historical CHANGELOG size')
    exact(closure['step'], 308, 'immutable prepared closure step')
    exact(closure['accepted_closure_complete'], False, 'preserved prepared closure wording')
    exact(closure['strong_safe_pause'], False, 'preserved prepared pause wording')
    exact(closure['production_entry_closed'], True, 'prepared production boundary')
    if any(closure['authorization'].values()):
        raise ValueError('historical authority reopened')
    exact(plan['authorization'], closure['authorization'], 'all existing authorization remains closed')
    exact(plan['repository_stage_permission'], dict(current_scope='prepare-review309-only',
        next_review_step=310, next_review_stage=STAGES[1],
        prepared_next_review_gate=True, next_review_authorized_now=False,
        requires_complete_user309_checkpoint=True,
        later_stages_granted_by_roadmap=False,
        optional_failure_steps_authorized_now=False), 'repository checkpoint gate')
    exact(plan['fresh_boundary'], dict(current_boot_id=None, current_pkglist_sha256=None,
        current_candidate_count=None, new_grant_id=None, current_predecessor_availability=None,
        operational_source_manifest_sha256=None, operational_target_sha256=None,
        operational_reference_sha256=None, operational_backend_path=None,
        operational_backend_sha256=None, platform_writer_lock_binding=None,
        namespace_binding=None, transaction_root=None, operational_owner=None,
        publication_paths=None, current_target_or_source_observed=False,
        historical_live_bindings_reusable=False, no_operational_authority_inherited=True),
        'invented operational binding')
    exact(plan['deferred_capabilities'], CAPABILITIES, 'seven separate capabilities')
    exact(plan['frozen_private_scope'], dict(
        freeze_path=FIXTURE + '/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze-freeze.json',
        candidate_sha256_bindings=frozen['candidate_sha256_bindings'],
        mandatory_tests=frozen['mandatory_tests'],
        mandatory_coverage_cannot_be_skipped_or_weakened=True,
        private_coverage_is_not_operational_conformance=True,
        immutable_reference_and_candidate_preserved=True,
        historical_v2_never_sourced_or_run=True), 'weakened private coverage or candidate identity')
    road = plan['roadmap']
    exact(set(road), {'preferred_step_count', 'maximum_planned_step_count', 'preferred_steps',
        'optional_failure_steps', 'scope', 'roadmap_grants_later_repository_stages',
        'roadmap_grants_machine_authority', 'runtime_attempt_planned',
        'fresh_live_observation_planned', 'pause_by_numeric_step_guaranteed',
        'repair_requires_separate_checkpoint', 'scope_change_requires_new_plan'}, 'roadmap fields')
    for key, value in dict(preferred_step_count=10, maximum_planned_step_count=12,
        scope='seven-separate-requirements-reviews-not-operational-capability-completion',
        roadmap_grants_later_repository_stages=False, roadmap_grants_machine_authority=False,
        runtime_attempt_planned=False, fresh_live_observation_planned=False,
        pause_by_numeric_step_guaranteed=False, repair_requires_separate_checkpoint=True,
        scope_change_requires_new_plan=True).items():
        exact(road.get(key), value, 'roadmap boundary ' + key)
    if not isinstance(road['preferred_steps'], list) or len(road['preferred_steps']) != 10:
        raise ValueError('ten preferred stages required')
    for offset, row in enumerate(road['preferred_steps']):
        exact(set(row), {'step', 'stage', 'scope', 'objective', 'capability',
            'requires_previous_user_checkpoint', 'machine_authority',
            'conditional_pause_candidate', 'operational_readiness_granted'}, 'stage fields')
        capability = CAPABILITIES[offset - 1] if 1 <= offset <= 7 else None
        scope = ('resume-planning' if offset == 0 else 'separate-capability-requirements-review'
                 if offset <= 7 else 'cross-dependency-effects-and-authority-closure-review'
                 if offset == 8 else 'requirements-freeze-and-conditional-strong-pause')
        for key, value in dict(step=309 + offset, stage=STAGES[offset], capability=capability,
            scope=scope, requires_previous_user_checkpoint=offset != 0,
            machine_authority=False, conditional_pause_candidate=offset == 9,
            operational_readiness_granted=False).items():
            exact(row.get(key), value, 'stage ' + str(offset) + ' ' + key)
        if not isinstance(row.get('objective'), str) or not row['objective'].strip():
            raise ValueError('stage objective')
    exact(road['optional_failure_steps'], [dict(step=319, scope='repository-only-failure-characterization',
        machine_authority=False, authorized_now=False), dict(step=320,
        scope='reviewed-repository-failure-closure-and-conditional-pause',
        machine_authority=False, authorized_now=False)], 'reserve is not authority')
    reviews = plan['capability_review_requirements']
    exact(set(reviews), set(CAPABILITIES), 'separate review requirements')
    common = ['bound-component-identities', 'allowed-effects-and-rejected-effects',
        'fresh-input-and-cross-dependency-gates', 'positive-and-negative-evidence',
        'slackware15-and-current-compatibility-scope', 'remaining-blockers-and-proof-limits',
        'separate-implementation-conformance-and-live-authorization-required']
    for cap in CAPABILITIES:
        exact(reviews[cap]['required_outputs'], common, 'capability outputs ' + cap)
        exact(reviews[cap]['operational_capability_complete'], False, 'capability overclaim ' + cap)
        exact(reviews[cap]['live_use_authorized'], False, 'capability authority ' + cap)
    exact(plan['strong_pause_completion_conditions'], dict(
        complete_repository_acceptance_reviewed=True,
        seven_requirements_reviews_bound_without_operational_completion_claim=True,
        all_effects_and_obligations_reviewed=True,
        no_unresolved_real_transaction_or_partial_publication=True,
        no_required_delivery_machine_or_controller_cleanup=True,
        all_repository_stage_and_operational_rights_closed=True,
        historical_and_future_unused_live_bindings_closed=True,
        user_application_tests_commit_push_clean_tree_confirmed=True,
        completed_pause_independent_of_later_current_publication=True,
        not_based_on_preflight_alone=True), 'incomplete final pause gate')
    return True


def verify_history(root, accepted, changelog_prefix):
    history = {}
    for rel, digest in accepted['sha256_bindings'].items():
        path = root / safe_relative(rel)
        if not safe_regular(path, root):
            raise ValueError('missing or unsafe accepted artifact: ' + rel)
        content = path.read_bytes()
        if rel == 'CHANGELOG.md':
            size = accepted['changelog_size_bytes']
            if len(content) != size + len(changelog_prefix):
                raise ValueError('unexpected CHANGELOG prefix or suffix length')
            if content[:len(changelog_prefix)] != changelog_prefix:
                raise ValueError('changed step309 CHANGELOG prefix')
            content = content[len(changelog_prefix):]
        if sha(content) != digest:
            raise ValueError('accepted SHA mismatch: ' + rel)
        history[rel] = content
    return history


def validate_record(content, plan):
    lines = content.decode('utf-8').splitlines()
    if not lines or any(line.count('\t') != 1 for line in lines):
        raise ValueError('record must contain real two-column TSV')
    rows = [line.split('\t') for line in lines]
    if len({row[0] for row in rows}) != len(rows):
        raise ValueError('duplicate record keys')
    exact(dict(rows), dict(step='309', resume_planning_status='PASS',
        accepted_checkpoint_commit='dd0f21e', accepted_checkpoint_acceptance='PASS (324 passes, 0 failures)',
        accepted_step308_strong_pause_confirmed='yes', user_step309_checkpoint_confirmed='no',
        production_entry_closed='yes', operational_readiness='no', operational_conformance='no',
        operational_executor_sha256='null', runtime_attempt_authorized='no',
        machine_action_required='no', controller_action_required='no', pause_safe='no',
        strong_safe_pause='no', next_stage_authorized='no', next_stage=plan['next_stage']), 'resume record')


def validate_roadmap(content, plan):
    rows = content.decode('utf-8').splitlines()
    expected = ['step\tstage\tscope\tcapability\tmachine_authority\tconditional_pause_candidate']
    for row in plan['roadmap']['preferred_steps']:
        expected.append('\t'.join([str(row['step']), row['stage'], row['scope'],
            row['capability'] or '-', 'no', 'yes' if row['conditional_pause_candidate'] else 'no']))
    exact(rows, expected, 'roadmap TSV diverges from reviewed route')


def publish_outputs(out, payloads):
    if not out.is_dir() or out.absolute() != out.resolve():
        raise ValueError('output directory must exist without symlink ancestors')
    for name in payloads:
        safe_relative(name)
        if (out / name).exists() or (out / name).is_symlink():
            raise ValueError('occupied planning output: ' + name)
    created = []
    try:
        for name, content in payloads.items():
            with (out / name).open('xb') as handle:
                created.append(out / name)
                handle.write(content)
    except BaseException:
        for path in reversed(created):
            path.unlink()
        raise


def run_predecessor(history):
    # Execute the unchanged historical acceptance in an exact isolated snapshot.
    with tempfile.TemporaryDirectory(prefix='step309-exact308-') as directory:
        snapshot = Path(directory) / 'slack-update'
        for rel, content in history.items():
            target = snapshot / safe_relative(rel)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
        result = subprocess.run(['bash', str(snapshot / 'tests/reference' / ('test-' + PRIOR + '-harness.sh'))],
                                capture_output=True, text=True)
        if result.returncode or result.stdout.splitlines().count('Result: PASS (324 passes, 0 failures)') != 1:
            sys.stderr.write(result.stdout + result.stderr)
            raise ValueError('exact full324 predecessor acceptance failed')
        return result.stdout.encode('utf-8')


def main(root, out):
    if not root.is_dir() or root.absolute() != root.resolve():
        raise ValueError('unsafe repository root')
    for rel, digest in OWN_HASHES.items():
        path = root / safe_relative(rel)
        if not safe_regular(path, root) or sha(path.read_bytes()) != digest:
            raise ValueError('changed or unsafe step309 input: ' + rel)
    fixture = root / FIXTURE
    plan = json.loads((fixture / (BASE + '-policy.json')).read_text())
    confirmation = json.loads((fixture / (BASE + '-checkpoint-confirmation.json')).read_text())
    receipt = json.loads((fixture / (BASE + '-step308-user-acceptance.json')).read_text())
    history = verify_history(root, plan['accepted_checkpoint'], CHANGELOG_PREFIX.encode())
    closure = json.loads(history[FIXTURE + '/' + PRIOR + '-policy.json'])
    frozen = json.loads(history[plan['frozen_private_scope']['freeze_path']])
    validate_plan(plan, confirmation, receipt, closure, frozen)
    validate_record((fixture / (BASE + '.tsv')).read_bytes(), plan)
    validate_roadmap((fixture / (BASE + '-roadmap.tsv')).read_bytes(), plan)
    names = [BASE + suffix for suffix in ['-policy.json', '-checkpoint-confirmation.json',
        '-step308-user-acceptance.json', '.tsv', '-roadmap.tsv']]
    payloads = {name: (fixture / name).read_bytes() for name in names}
    # Reject all occupied outputs before historical tests or any publication.
    if not out.is_dir() or out.absolute() != out.resolve():
        raise ValueError('unsafe planning output directory')
    if any((out / name).exists() or (out / name).is_symlink() for name in names + [BASE + '-predecessor-test.log']):
        raise ValueError('planning outputs must be absent')
    payloads[BASE + '-predecessor-test.log'] = run_predecessor(history)
    # Detect source changes while the historical acceptance was running.
    verify_history(root, plan['accepted_checkpoint'], CHANGELOG_PREFIX.encode())
    for rel, digest in OWN_HASHES.items():
        path = root / rel
        if not safe_regular(path, root) or sha(path.read_bytes()) != digest:
            raise ValueError('step309 input changed during historical acceptance: ' + rel)
    publish_outputs(out, payloads)
    print('step309_resume_planning_status\tPASS')
    print('exact_step308_predecessor_acceptance\tPASS (324 passes, 0 failures)')
    print('historical_step308_pause_confirmed\tyes')
    print('user_step309_checkpoint_pending\tyes')
    print('all_operational_authority_closed\tyes')
    print('next_stage_authorized_now\tno')
    print('machine_action_required\tno')
    print('controller_action_required\tno')
    print('pause_safe\tno')
    print('strong_safe_pause\tno')
    print('next_stage\t' + plan['next_stage'])


if __name__ == '__main__':
    try:
        main(Path(sys.argv[1]), Path(sys.argv[2]).absolute())
    except (ValueError, KeyError, TypeError, OSError, json.JSONDecodeError) as error:
        raise SystemExit('ERROR: ' + str(error))
PYPLAN
