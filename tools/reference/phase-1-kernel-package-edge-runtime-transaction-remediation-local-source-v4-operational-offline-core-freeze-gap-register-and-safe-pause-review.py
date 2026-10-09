#!/usr/bin/env python3
"""Verify a repository-only offline freeze; private eligibility is not authority."""
from pathlib import Path
import hashlib
import json
import sys

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review'
PREFIX = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-'
PRIOR = PREFIX + 'offline-contract-refinement-reconciliation-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1/'
SCOPE = 'repository-offline-transition-core-workstream339-348-only'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review.md': '2c6f681ee475cf710170c75e0045bd5b3ddb0a0a909d2a48d647454c988a4f90', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review-checkpoint-confirmation.json': '13f17cd4d5f4b51c2245b316f9f8f4a9c948172b24825aa5dc1b5781e7615227', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review-freeze.json': 'ef26037256b8574cea72f297b88910f53dc51e6632a0440a8361ea8aa65761d0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review-native-gap-register.json': '578188d6ba5b220569c64bb869bd5a0da5bccfe1fe4fa7d98d7ddcc99fd38091', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review-pause-conditions.json': '7c609304f0aa321470f2b103e3530b4a686c9aba6e6e274121df21425161b54c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review-policy.json': '73e990cef5cec08f9bc0f14dd2683ce1145840aff21927d6e095b25aca2726b7', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review-step347-user-acceptance.json': '57fc849d016d14120801d39925d1a38f7ccad54490c4c1c6382148d8289a7ce6'}
ADDITION_SHA = 'd27cb044550a04ac6eafc1dbf3e75cc5ea33c3048bd2fff1c0188c21290166d7'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def exact(value, expected, label):
    if type(value) is not type(expected) or json.dumps(value, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(label)


def safe_file(root, relative):
    if type(relative) is not str or not relative or '\\' in relative or any(x in ('', '.', '..') for x in relative.split('/')):
        raise ValueError('unsafe repository relative path')
    path = root / relative
    if not path.is_file() or path.is_symlink() or path.resolve() != path.absolute() or not path.resolve().is_relative_to(root):
        raise ValueError('unsafe source ' + relative)
    return path


def old(history, suffix):
    return json.loads(history[FIXTURE + PRIOR + '-' + suffix + '.json'])


def validate_return(confirmation, receipt, policy):
    raw = receipt['text'].encode('utf-8')
    lines = receipt['text'].splitlines()
    exact(receipt['encoding'], 'utf8-json-text', 'original user receipt encoding')
    exact(sha(raw), receipt['original_display_sha256'], 'full original receipt SHA')
    exact(len(raw), receipt['original_display_size_bytes'], 'full original receipt size')
    exact(confirmation['evidence_sha256'], sha(raw), 'confirmation full receipt SHA')
    exact(confirmation['evidence_size_bytes'], len(raw), 'confirmation full receipt size')
    exact(confirmation['step'], 347, 'accepted347')
    exact(confirmation['commit_prefix'], 'fed2808', 'reported accepted347 prefix')
    exact(confirmation['commit_full'], None, 'full object ID unknown')
    exact(confirmation['acceptance_result'], 'PASS (185 passes, 0 failures)', 'complete185 result')
    exact(confirmation['ordered_output_normalization'], 'none', 'original report not normalized')
    exact([x for x in lines if x.startswith('PASS: ')], policy['accepted_ordered347_labels'], 'all185 labels in exact accepted order')
    exact(lines.count('Result: PASS (185 passes, 0 failures)'), 1, 'single complete summary')
    exact([x.removeprefix(' create mode 100644 ') for x in lines if x.startswith(' create mode 100644 ')], policy['accepted_step347_paths'], 'exact nine created paths')
    exact(lines.count(' 10 files changed, 289068 insertions(+)'), 1, 'exact reported ten-file scope')
    message = 'Phase 1 step 347: reconcile offline core contracts and native gaps'
    exact(lines.count('[main fed2808] ' + message), 1, 'exact reported commit')
    exact(lines.count('fed2808 (HEAD -> main, origin/main, origin/HEAD) ' + message), 2, 'matching reported HEAD and origin')
    if '038c896..fed2808  main -> main' not in receipt['text'] or 'step347_overlay_application_status\tPASS' not in receipt['text']:
        raise ValueError('successful reported overlay and push required')
    for key in ('complete_ordered_return_matches_prepared_and_installed', 'user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed', 'user_head_matches_origin', 'user_worktree_clean', 'push_first_attempt_succeeded', 'production_entry_closed'):
        exact(confirmation[key], True, 'accepted347 ' + key)
    for key in ('strong_safe_pause', 'runtime_authority', 'phase2_open'):
        exact(confirmation[key], False, 'no promotion ' + key)
    for key in ('actual_native_cases_run', 'actual_native_proofs_added'):
        exact(confirmation[key], 0, 'no native evidence')
    exact(confirmation['push_attempt_count'], 1, 'first successful push')
    exact(confirmation['last_confirmed_strong_safe_pause_step'], 338, 'last confirmed pause338')
    exact(confirmation['actual_host_state'], 'unobserved-not-claimed-absent', 'host unknown')
    exact(confirmation['actual_live_bindings'], None, 'no actual live binding')
    return True


def validate_freeze(value, history, policy):
    previous = old(history, 'reconciliation')
    exact(value['schema'], 1, 'freeze schema')
    exact(value['step'], 348, 'current348')
    exact(value['scope'], SCOPE, 'offline workstream scope')
    exact(value['freeze_version'], 'source-bound-pure-offline-core-artifact-freeze-v1', 'offline artifact freeze only')
    exact(value['offline_repository_artifacts_frozen'], True, 'repository source frozen')
    expected_registry = previous['offline_artifact_registry339_346'] + [
        {'step': 347, 'path': path, 'sha256': sha(history[path]), 'scope': 'repository-artifact-not-native-implementation'}
        for path in policy['accepted_step347_paths']]
    exact(value['frozen_artifact_registry339_347'], expected_registry, 'all81 accepted source inputs in original order')
    exact(len(expected_registry), 81, 'exact81 frozen source inputs')
    for row in expected_registry:
        exact(sha(history[row['path']]), row['sha256'], 'unchanged accepted input')
    for key, suffix in [('exact347_reconciliation_binding','reconciliation'), ('exact347_rule_map_binding','rule-map'), ('exact347_native_gap_binding','native-gap-register')]:
        path = FIXTURE + PRIOR + '-' + suffix + '.json'
        exact(value[key], {'path': path, 'sha256': sha(history[path])}, 'full unchanged347 normative source')
    exact(value['model_modules'], previous['model_modules'], 'all unchanged seven pure modules')
    for bound in value['model_modules'].values():
        exact(sha(history[bound['path']]), bound['sha256'], 'same frozen model bytes')
    exact(value['source_definition_and_guard_count'], len(old(history,'rule-map')['rule_rows']), 'original637 rule index retained')
    exact(value['counts'], previous['counts'], 'all full original register counts')
    exact(value['original_pause_conditions'], previous['original_pause_conditions'], 'all original nine pause conditions')
    closure = value['current348_closure_artifacts']
    exact(closure['count'], 9, 'nine current bookkeeping artifacts')
    exact(closure['paths'], policy['current348_closure_artifacts'], 'complete separately bound348 scope')
    exact(closure['user_acceptance_pending'], True, 'no current receipt invented')
    exact(value['accepted_checkpoint_chain338_347'][:-1], previous['accepted_checkpoint_chain338_346'], 'complete unchanged prior receipt chain')
    current = value['accepted_checkpoint_chain338_347'][-1]
    exact(current['step'], 347, 'latest accepted347 only')
    exact(current['commit_prefix'], 'fed2808', 'latest reported prefix')
    exact(current['acceptance_result'], 'PASS (185 passes, 0 failures)', 'latest accepted tests')
    exact(current['complete_user_return_accepted'], True, 'complete347 accepted')
    for key in ('scoped_pause_candidate', 'current348_user_acceptance_pending', 'stop_after_complete348_acceptance', 'future_work_requires_new_user_request', 'production_entry_closed'):
        exact(value[key], True, 'scoped pending stop boundary ' + key)
    for key in ('strong_safe_pause', 'user_step348_checkpoint_confirmed', 'actual_operational_implementation_frozen', 'actual_native_refinement_complete', 'actual_dynamic_graph_complete', 'actual_independent_oracle_selected', 'operational_conformance', 'operational_readiness', 'runtime_authority', 'new_runtime_work_authorized', 'historical_binding_or_authority_reuse_allowed', 'machine_action_required', 'controller_action_required', 'new_batch_machine_cleanup_required', 'new_batch_controller_cleanup_required', 'later_current_refresh_invalidates_repository_only_pause', 'phase1_matrix_complete', 'kernel_package_edge_complete', 'phase2_open'):
        exact(value[key], False, 'native or future scope remains closed ' + key)
    for key in ('native_cases_run','native_proofs_added'):
        exact(value[key], 0, 'freeze adds no native evidence')
    exact(value['actual_host_state'], 'unobserved-not-claimed-absent', 'host unknown')
    exact(value['actual_live_bindings'], None, 'no live binding')
    exact(value['next_authorized_stage'], None, 'stop after348 no349')
    exact(value['last_confirmed_strong_safe_pause_step'], 338, 'last confirmed338 until receipt')
    return True


def validate_gap_register(value, history):
    previous = old(history,'native-gap-register')
    original = old(history,'reconciliation')['retained_full_normative_rows']
    for key in ('native_gap_rows','qualified_proofs','native_case_templates','clock_boundary','macro_cut_boundary'):
        exact(value[key], previous[key], 'full unchanged native blocker ' + key)
    for key in ('macro_cut_obligations','owned_stage7_microsteps'):
        exact(value[key], original[key], 'full original macro and owned obligations')
    exact(len(value['native_gap_rows']), 16, 'all16 gaps')
    exact(len(value['qualified_proofs']), 46, 'all46 unproven native proofs')
    exact(len(value['native_case_templates']), 52, 'all52 unrun native cases')
    for key in ('native_cases_run','native_proofs_added'):
        exact(value[key], 0, 'no native evidence')
    for key in ('actual_operational_implementation_frozen','actual_native_refinement_complete','operational_conformance','operational_readiness','runtime_authority'):
        exact(value[key], False, 'native resolution still pending')
    exact(value['actual_host_state'], 'unobserved-not-claimed-absent', 'host remains unknown')
    exact(value['actual_live_bindings'], None, 'no actual live binding')
    return True


def validate_conditions(value, freeze):
    exact(value['schema'], 1, 'condition schema')
    exact(value['step'], 348, 'condition step')
    exact(value['scope'], SCOPE, 'condition scope')
    exact([x['id'] for x in value['conditions']], freeze['original_pause_conditions'], 'all nine original conditions in order')
    for i, row in enumerate(value['conditions']):
        exact(row['position'], i, 'condition position')
        exact(row['status'], 'pending-current348-complete-user-return' if i == 0 else 'repository-scope-checked-with-native-blockers-retained', 'current return never historical substitute')
        if type(row['requirement']) is not str or not row['requirement']:
            raise ValueError('full condition requirement missing')
        exact(row['actual_native_evidence'], None, 'no native condition proof')
        exact(row['current348_actual_user_confirmation'], None, 'current348 not confirmed')
    for key in ('actual_strong_safe_pause_confirmed','actual_global_host_closure','runtime_authority','private_eligibility_is_actual_confirmation'):
        exact(value[key], False, 'private condition cannot confirm actual closure')
    exact(value['external_confirmation_rule'], freeze['pause_confirmation_rule'], 'external complete receipt still required')
    return True


def private_pause_eligibility(value, conditions):
    """Pure synthetic eligibility data. Never confirms actual pause or authority."""
    keys = {'schema','step','scope','origin','checks','actual_host_state','actual_live_bindings','runtime_authority'}
    if type(value) is not dict or set(value) != keys:
        raise ValueError('closed private eligibility fields required')
    exact(value['schema'], 1, 'private schema')
    exact(value['step'], 348, 'private348 only')
    exact(value['scope'], SCOPE, 'private repository scope only')
    exact(value['origin'], 'synthetic-private-fixture', 'private fixture not native evidence')
    exact(value['actual_host_state'], 'unobserved-not-claimed-absent', 'host unknown never absent')
    exact(value['actual_live_bindings'], None, 'no binding reuse')
    exact(value['runtime_authority'], False, 'no new authority')
    names = [x['id'] for x in conditions['conditions']]
    checks = value['checks']
    if type(checks) is not dict or set(checks) != set(names) or any(type(x) is not bool for x in checks.values()):
        raise ValueError('all nine exact bool condition reports required')
    pending = [name for name in names if not checks[name]]
    return {'model_scoped_pause_confirmation_eligible':not pending, 'model_pending_conditions':pending,
        'actual_strong_safe_pause_confirmed':False,'actual_global_host_closure':False,
        'actual_target_or_publication_closure':False,'actual_native_implementation_frozen':False,
        'actual_operational_conformance':False,'actual_runtime_authority':False,
        'actual_native_cases_run':0,'actual_native_proofs_added':0}


def verify(root):
    root = Path(root).absolute()
    if not root.is_dir() or root.resolve() != root:
        raise ValueError('safe repository root required')
    for relative, digest in OWN_HASHES.items():
        exact(sha(safe_file(root,relative).read_bytes()), digest, 'current348 exact bookkeeping source')
    load = lambda tail:json.loads(safe_file(root,FIXTURE+BASE+'-'+tail+'.json').read_bytes())
    policy=load('policy');history={}
    for relative,digest in policy['baseline_sha256_bindings'].items():
        raw=safe_file(root,relative).read_bytes()
        if relative=='CHANGELOG.md':
            size=policy['accepted_changelog_size']
            if len(raw)<=size:raise ValueError('missing additive348 changelog')
            exact(sha(raw[:-size]), ADDITION_SHA, 'exact348 additive prefix')
            raw=raw[-size:]
        exact(sha(raw), digest, 'accepted347 bytes '+relative)
        history[relative]=raw
    exact(len(history),1710,'all1710 accepted source files')
    validate_return(load('checkpoint-confirmation'),load('step347-user-acceptance'),policy)
    freeze=load('freeze');validate_freeze(freeze,history,policy)
    validate_gap_register(load('native-gap-register'),history)
    validate_conditions(load('pause-conditions'),freeze)
    return history


def main(argv):
    if argv==['--help']:
        print('Repository-only conditional offline freeze: --check REPOSITORY')
        return 0
    if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
    try:verify(argv[1])
    except (ValueError,KeyError,TypeError,OSError) as error:
        print('ERROR: '+str(error),file=sys.stderr);return 1
    print('step348_offline_core_artifact_freeze_review_status\tPASS')
    print('current348_user_acceptance_pending\tyes')
    print('runtime_authority\tno')
    print('native_cases_run\t0')
    print('native_proofs_added\t0')
    return 0


if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
