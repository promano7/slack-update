#!/bin/bash
set -euo pipefail
export LC_ALL=C
[[ $# -eq 0 ]] || { printf 'ERROR: harness takes no arguments\n' >&2; exit 2; }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast
import copy
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
tool = root / 'tools/reference' / (base + '.sh')
passes = 0


def check(label, condition):
    global passes
    if not condition:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label, flush=True)


def rejected(function, *args):
    try:
        function(*args)
    except (ValueError, KeyError, TypeError, OSError):
        return True
    return False


def run(argv):
    return subprocess.run([str(x) for x in argv], capture_output=True, text=True)


check('exact310 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '89691e986e7a7548d3f29b9df592d0454f9da2923af41803b1dc49cc928b2f14')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step310_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step309-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_reference_facts'](raw)
functions = ns['extract_functions'](raw, ns['FUNCTION_NAMES'])
check('exact1359 accepted bytes and original CHANGELOG suffix', len(history) == 1359)
check('confirmed309 full280 original receipt includes SSH failure and successful retry', ns['validate_confirmation'](confirmation, receipt))
check('separate reference selector requirements accepted', ns['validate_review'](review, facts, prior))
check('typed closed310 policy accepted', ns['validate_policy'](policy, confirmation, receipt, prior, review))
check('immutable pending309 wording retained with external confirmation', prior['user_step309_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('eighteen exact static function slices bound', len(facts['function_slices']) == 18)
check('actual selector provenance and selected vectors remain unavailable', all(value is None for key, value in review['selector_equivalence_requirements'].items() if key.startswith('actual_')))
check('private candidate mandatory coverage and all six other capabilities preserved', review['candidate_sha256_bindings'] == prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests'] == prior['frozen_private_scope']['mandatory_tests'] and len(review['other_deferred_capabilities']) == 6)
for rel, digest in ns['OWN_HASHES'].items():
    check('exact bound310 input ' + Path(rel).name, hashlib.sha256((root / rel).read_bytes()).hexdigest() == digest)


def bad_policy(label, path, value):
    changed = copy.deepcopy(policy)
    slot = changed
    for key in path[:-1]:
        slot = slot[key]
    slot[path[-1]] = value
    check('rejects ' + label, rejected(ns['validate_policy'], changed, confirmation, receipt, prior, review))


for key, value in dict(step=311, schema=True, user_step310_checkpoint_confirmed=True,
    pause_safe=True, strong_safe_pause=True, machine_action_required=True,
    controller_action_required=True, runtime_attempt_planned=True, phase1_matrix_complete=True,
    kernel_package_edge_complete=True, phase2_open=True, production_entry_closed=False,
    operational_readiness=True, operational_implementation_complete=True, operational_conformance=True,
    operational_executor_sha256='0' * 64, actual_reference_main_entered=True,
    actual_slackpkg_selector_executed=True, operational_capability_complete=True,
    actual_selector_equivalence_proven=True, historical_v2_sourced_or_run=True,
    confirmed309_supersedes_immutable_prepared_wording=False,
    next_stage_authorized=True, next_stage='wrong-stage', new_repository_artifact_count=9,
    prepared_repository_file_count=1368).items():
    bad_policy('premature310 boundary ' + key, [key], value)
for key in policy['authorization']:
    bad_policy('opened inherited authorization ' + key, ['authorization', key], True)
for key, value in policy['fresh_boundary'].items():
    bad_policy('invented operational slot ' + key, ['fresh_boundary', key], 'stale-binding' if value is None else not value)
for key in ['other_capabilities_reviewed_by310', 'next_review_authorized_now', 'later_stages_granted_by_roadmap']:
    bad_policy('widened current review permission ' + key, ['repository_stage_permission', key], True)
bad_policy('missing user310 checkpoint gate', ['repository_stage_permission', 'requires_complete_user310_checkpoint'], False)
bad_policy('changed accepted309 manifest', ['accepted_checkpoint', 'sha256_bindings', 'CHANGELOG.md'], '0' * 64)
bad_policy('incomplete accepted309 manifest', ['accepted_checkpoint', 'sha256_bindings'], {})
bad_policy('invented full309 commit', ['accepted_checkpoint', 'commit_full'], 'f' * 40)
bad_policy('unbound review SHA', ['review_sha256'], '0' * 64)
bad_policy('merged six remaining reviews', ['other_deferred_capabilities'], [])
bad_policy('weakened frozen mandatory tests', ['frozen_private_scope', 'mandatory_tests'], [])
for key, value in policy['private_probe_scope'].items():
    bad_policy('private source slice overclaim ' + key, ['private_probe_scope', key], not value)
extra = copy.deepcopy(policy)
extra['live_use_authorized'] = True
check('unknown live authority key rejected', rejected(ns['validate_policy'], extra, confirmation, receipt, prior, review))
for key in ['user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed',
    'user_worktree_clean', 'user_head_matches_origin', 'explicit_push_retry_succeeded',
    'initial_push_failed_at_ssh_transport', 'confirmation_external_to_immutable_repository']:
    changed = copy.deepcopy(confirmation)
    changed[key] = False
    check('rejects incomplete309 confirmation ' + key, rejected(ns['validate_confirmation'], changed, receipt))
for key, value in dict(commit_prefix='wrongid', commit_full='f' * 40, push_first_attempt_succeeded=True,
    push_retry_required=True, runtime_retry_performed=True, operational_authority_inherited=True,
    live_target_observed=True, user_step309_strong_pause_claimed=True).items():
    changed = copy.deepcopy(confirmation)
    changed[key] = value
    check('rejects invented309 proof or retry ' + key, rejected(ns['validate_confirmation'], changed, receipt))
for key, value in dict(text=receipt['text'][:-1], original_display_sha256='0' * 64,
    original_display_size_bytes=True, encoding='unknown').items():
    changed = copy.deepcopy(receipt)
    changed[key] = value
    check('rejects original309 receipt drift ' + key, rejected(ns['validate_confirmation'], confirmation, changed))


def bad_review(label, path, value):
    changed = copy.deepcopy(review)
    slot = changed
    for key in path[:-1]:
        slot = slot[key]
    slot[path[-1]] = value
    check('rejects weakened review ' + label, rejected(ns['validate_review'], changed, facts, prior))


for key in ['actual_selector_equivalence_proven', 'actual_slackpkg_selector_executed',
    'operational_capability_complete', 'operational_readiness', 'operational_conformance', 'real_reference_main_entered']:
    bad_review('operational proof ' + key, ['proof_state', key], True)
for key in ['persistent_failure_latch_before_backend_dispatch', 'later_mutating_calls_rejected_after_any_latched_failure',
    'raw_nested_status_never_normalized', 'backend_resolution_absolute_canonical_SHA_no_PATH_recursion',
    'unknown_argv_or_missing_binding_rejects_before_backend', 'before_each_nested_call_require_fresh_grant_boot_source_target_predecessor_and_pkglist',
    'nested_update_exit0_and_both_stream_error_guard_and_unchanged_regular_pkglist_SHA', 'candidate_drift_must_stop_not_rebind']:
    bad_review('adapter guard ' + key, ['adapter_requirements', key], False)
bad_review('upgrade20 accepted under one-target contract', ['adapter_requirements', 'upgrade_all_status_policy'], 'raw20-means-success')
bad_review('empty install-new20 always forbidden by emulator', ['adapter_requirements', 'install_new_status_policy'], 'raw0-only-no-backend-review')
for key in ['exact_complete_vectors_not_counts_only', 'pkglist_single_row_is_not_actual_selector_proof',
    'reference_dry_run_or_json_is_not_backend_selector_enumeration', 'oracle_inputs_and_actual_selector_inputs_must_be_identical',
    'compatibility_evidence_separate_per_bound_backend']:
    bad_review('selector proof condition ' + key, ['selector_equivalence_requirements', key], False)
bad_review('backend selector inferred from private candidate', ['selector_equivalence_requirements', 'actual_backend_selector_sha256'], '0' * 64)
bad_review('authority to capture real selector', ['selector_equivalence_requirements', 'permission_to_collect_or_execute_backend_selector'], True)
for offset, row in enumerate(review['selector_proof_obligations']):
    bad_review('missing proof evidence ' + row['id'], ['selector_proof_obligations', offset, 'required_evidence'], '')
    bad_review('future proof declared completed ' + row['id'], ['selector_proof_obligations', offset, 'status'], 'live-conformance-PASS')
bad_review('missing whole-reference effect blocker', ['blockers'], [])
bad_review('whole-reference source allowed', ['prohibited_current_effects'], [])
bad_review('six pending capabilities lost', ['other_deferred_capabilities'], [])
record = (fixture / (base + '.tsv')).read_bytes()
call_map = (fixture / (base + '-call-map.tsv')).read_bytes()
matrix = (fixture / (base + '-selector-proof-matrix.tsv')).read_bytes()
ns['validate_tables'](record, call_map, matrix, review, policy)
check('strict reviewed record call-map and proof-matrix TSV accepted', True)
check('TSV duplicate key rejected', rejected(ns['validate_tables'], record + b'step\t310\n', call_map, matrix, review, policy))
check('TSV premature selector conformance rejected', rejected(ns['validate_tables'], record.replace(b'actual_selector_equivalence_proven\tno', b'actual_selector_equivalence_proven\tyes'), call_map, matrix, review, policy))
check('wrong actual caller argv mapping rejected', rejected(ns['validate_tables'], record, call_map.replace(b'upgrade-all', b'clean-system'), matrix, review, policy))
check('lost selector proof obligation rejected', rejected(ns['validate_tables'], record, call_map, b'\n'.join(matrix.splitlines()[:-1]) + b'\n', review, policy))
for mutated in [raw.replace(b'slackpkg -batch=on -default_answer=y update', b'slackpkg -batch=on -default_answer=n update'),
    raw.replace(b'install-new:20', b'install-new:21'), raw.replace(b'update_slackware_system() {', b'other_update_function() {')]:
    check('changed bound reference command/classifier/function rejected', rejected(ns['extract_reference_facts'], mutated))
changed_facts = ns['extract_reference_facts'](raw + b'\n')
check('same function slices with different full reference SHA rejected', rejected(ns['validate_review'], review, changed_facts, prior))

# Only two reviewed slices are executable here. Neither can enter main or a real backend.
bash = '/bin/bash'
private_env = {'LC_ALL': 'C', 'PATH': '/__step310_no_external_commands__'}
helper = functions['slackpkg_apply_action_failed']['content']
for action in ['update', 'install-new', 'upgrade-all']:
    for status in [-1, 0, 1, 20, 37]:
        script = helper + '\nslackpkg_apply_action_failed "$1" "$2"\n'
        result = subprocess.run([bash, '--noprofile', '--norc', '-c', script, '--', action, str(status)], env=private_env, capture_output=True, text=True)
        accepted_status = status == -1 or status == 0 or (action != 'update' and status == 20)
        check('exact pure reference status predicate ' + action + ':' + str(status), result.returncode == (1 if accepted_status else 0) and result.stdout == '' and result.stderr == '')
check('reference unattempted-1 classification cannot prove mutation success', review['findings'][3]['id'] == 'raw-status20' and review['adapter_requirements']['upgrade_all_status_policy'].startswith('raw0-and-verified-exact-target-effect'))


def probe_update(update_status, install_status, upgrade_status, install_enabled=True, upgrade_enabled=True, latch=False, define_backend=True):
    stub = '''
PRIVATE_LATCH=0
slackpkg() {
    if [ "$PRIVATE_LATCH" -ne 0 ]; then
        printf 'PRIVATE_REJECTED:%s\\n' "$*"
        return "$PRIVATE_LATCH"
    fi
    printf 'PRIVATE_CALL:%s\\n' "$*"
    case "${!#}" in
        update) result=$UPDATE_RESULT ;;
        install-new) result=$INSTALL_RESULT ;;
        upgrade-all) result=$UPGRADE_RESULT ;;
        *) return 97 ;;
    esac
    if [ "$LATCH_ENABLED" = true ] && [ "$result" -ne 0 ]; then
        PRIVATE_LATCH=$result
    fi
    return "$result"
}
''' if define_backend else ''
    capture_stub = '''
capture_pending_new_config_files() {
    PENDING_NEW_CONFIG_FILES_COUNT=0
    return 0
}
'''
    values = '\n'.join(['UPDATE_RESULT=' + str(update_status), 'INSTALL_RESULT=' + str(install_status),
        'UPGRADE_RESULT=' + str(upgrade_status), 'SLACKWARE_INSTALL_NEW=' + str(install_enabled).lower(),
        'SLACKWARE_UPGRADE_ALL=' + str(upgrade_enabled).lower(), 'LATCH_ENABLED=' + str(latch).lower(),
        'SLACKPKG_UPDATE_STATUS=-1', 'SLACKPKG_INSTALL_NEW_STATUS=-1', 'SLACKPKG_UPGRADE_ALL_STATUS=-1'])
    script = values + '\n' + stub + capture_stub + functions['update_slackware_system']['content']
    script += '\nupdate_slackware_system\nprintf "PRIVATE_STATUS:%s:%s:%s\\n" "$SLACKPKG_UPDATE_STATUS" "$SLACKPKG_INSTALL_NEW_STATUS" "$SLACKPKG_UPGRADE_ALL_STATUS"\n'
    return subprocess.run([bash, '--noprofile', '--norc', '-c', script], env=private_env, capture_output=True, text=True)


expected_calls = ['PRIVATE_CALL:' + ' '.join(row['argv']) for row in facts['nested_commands']]
for statuses in [(0, 0, 0), (37, 0, 0), (0, 73, 0), (0, 20, 20)]:
    result = probe_update(*statuses)
    calls = [line for line in result.stdout.splitlines() if line.startswith('PRIVATE_CALL:')]
    check('exact update slice three calls under injected raw statuses ' + repr(statuses), result.returncode == 0 and calls == expected_calls and 'PRIVATE_STATUS:' + ':'.join(map(str, statuses)) in result.stdout and result.stderr == '')
result = probe_update(37, 0, 0, latch=True)
check('file-free latch injection denies later backend dispatch despite caller continuation', sum(line.startswith('PRIVATE_CALL:') for line in result.stdout.splitlines()) == 1 and sum(line.startswith('PRIVATE_REJECTED:') for line in result.stdout.splitlines()) == 2 and 'PRIVATE_STATUS:37:37:37' in result.stdout)
result = probe_update(0, 0, 0, install_enabled=False)
check('disabled install-new slice changes actual call vector and preserves unattempted-1', [line for line in result.stdout.splitlines() if line.startswith('PRIVATE_CALL:')] == [expected_calls[0], expected_calls[2]] and 'PRIVATE_STATUS:0:-1:0' in result.stdout)
result = probe_update(0, 0, 0, upgrade_enabled=False)
check('disabled upgrade cannot establish required single target effect', [line for line in result.stdout.splitlines() if line.startswith('PRIVATE_CALL:')] == expected_calls[:2] and 'PRIVATE_STATUS:0:0:-1' in result.stdout)
result = probe_update(0, 0, 0, define_backend=False)
check('missing injected backend cannot fall back to host command', 'PRIVATE_CALL:' not in result.stdout and 'PRIVATE_STATUS:127:127:127' in result.stdout and result.stderr.count('slackpkg: command not found') == 3)
check('private exact slices leave actual selector and main proofs false', policy['actual_reference_main_entered'] is False and policy['actual_slackpkg_selector_executed'] is False and policy['actual_selector_equivalence_proven'] is False)
for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step310-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real310 review entry reruns full unchanged280 predecessor acceptance', result.returncode == 0 and 'exact_step309_acceptance\tPASS (280 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full280 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 280 and old_log.splitlines()[-1] == 'Result: PASS (280 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step309-user-acceptance.json', '.tsv', '-call-map.tsv', '-selector-proof-matrix.tsv']]
    for name in names:
        check('exact published310 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
    check('published review does not confer selector or next-stage authority', 'actual_selector_equivalence_proven\tno' in result.stdout and 'next_stage_authorized\tno' in result.stdout)
    check('occupied output directory rejected without overwrite', run(['bash', tool, '--output-dir', out]).returncode != 0)
    for i, name in enumerate(names + [base + '-predecessor-test.log']):
        blocked = area / ('blocked-' + str(i))
        blocked.mkdir()
        (blocked / name).write_bytes(b'keep\n')
        check('occupied output rejects before publication ' + name, run(['bash', tool, '--output-dir', blocked]).returncode != 0 and list(blocked.iterdir()) == [blocked / name] and (blocked / name).read_bytes() == b'keep\n')
    missing = area / 'missing'
    check('missing output rejected without creation', run(['bash', tool, '--output-dir', missing]).returncode != 0 and not missing.exists())
    linked = area / 'linked'
    linked.symlink_to(out, target_is_directory=True)
    check('output symlink rejected', run(['bash', tool, '--output-dir', linked]).returncode != 0)
    copied = area / 'slack-update'
    shutil.copytree(root, copied)
    copied_tool = copied / 'tools/reference' / (base + '.sh')
    empty = area / 'empty'
    empty.mkdir()
    mutations = list(ns['OWN_HASHES']) + ['tools/reference/slack-update-reference.sh',
        'tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json',
        next(iter(policy['frozen_private_scope']['candidate_sha256_bindings'])), 'CHANGELOG.md']
    for rel in mutations:
        path = copied / rel
        content = path.read_bytes()
        path.write_bytes(content + b'\n')
        check('changed planning/reference/history input rejects before publication ' + path.name, run(['bash', copied_tool, '--output-dir', empty]).returncode != 0 and not list(empty.iterdir()))
        path.write_bytes(content)
    for rel in ['tools/reference/slack-update-reference.sh', 'docs/reference/' + base + '.md']:
        path = copied / rel
        content = path.read_bytes()
        saved = area / ('saved-' + str(len(list(area.iterdir()))))
        saved.write_bytes(content)
        path.unlink()
        path.symlink_to(saved)
        check('same-content source/reference symlink rejected ' + path.name, run(['bash', copied_tool, '--output-dir', empty]).returncode != 0 and not list(empty.iterdir()))
        path.unlink()
        path.write_bytes(content)
check('all1359 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
