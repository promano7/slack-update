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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review'
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


check('exact planning tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '24b9477b9ebeaf375780d9cc82a4fede2143419df212dd877c3a8776f68d3326')
source = tool.read_text().split("<<'PYPLAN'\n", 1)[1].rsplit('\nPYPLAN', 1)[0]
namespace = {'__name__': 'step309_private_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), namespace)
plan = json.loads((fixture / (base + '-policy.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step308-user-acceptance.json')).read_text())
history = namespace['verify_history'](root, plan['accepted_checkpoint'], namespace['CHANGELOG_PREFIX'].encode())
prior = namespace['PRIOR']
closure = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + prior + '-policy.json'])
frozen = json.loads(history[plan['frozen_private_scope']['freeze_path']])
validate = namespace['validate_plan']
check('exact1351 historical files and CHANGELOG suffix preserved', len(history) == 1351)
check('complete original324 acceptance commit push and clean-tree confirmation', namespace['validate_confirmation'](confirmation, receipt))
check('prepared309 resume and seven separate reviews accepted', validate(plan, confirmation, receipt, closure, frozen))
check('immutable prepared308 pending wording superseded externally', closure['accepted_closure_complete'] is False and confirmation['accepted_closure_complete'] is True)
check('frozen eleven sections and thirteen stages remain bound', len(frozen['frozen_implementation_specification']) == 11 and len(frozen['frozen_stage_order']) == 13)
check('all current repository and operational authorization remains closed', all(value is False for value in plan['authorization'].values()))
for rel, digest in namespace['OWN_HASHES'].items():
    check('exact bound planning input: ' + rel.rsplit('/', 1)[-1], hashlib.sha256((root / rel).read_bytes()).hexdigest() == digest)


def bad_plan(label, path, value):
    changed = copy.deepcopy(plan)
    slot = changed
    for key in path[:-1]:
        slot = slot[key]
    slot[path[-1]] = value
    check('rejects ' + label, rejected(validate, changed, confirmation, receipt, closure, frozen))


for key, value in dict(step=310, schema=True, user_step309_checkpoint_confirmed=True,
    pause_safe=True, strong_safe_pause=True, machine_action_required=True,
    controller_action_required=True, runtime_attempt_planned=True,
    phase1_matrix_complete=True, kernel_package_edge_complete=True,
    phase2_open=True, production_entry_closed=False, operational_implementation_complete=True,
    operational_readiness=True, operational_conformance=True,
    operational_executor_sha256='0' * 64, historical_step308_pause_remains_valid=False,
    confirmed308_supersedes_prepared_wording_without_editing_history=False,
    historical_reserve309_310_closed_not_inherited=False, next_stage_authorized=True,
    next_stage='wrong-stage', next_stage_condition='no-checkpoint-required',
    new_repository_artifact_count=7, prepared_repository_file_count=1358).items():
    bad_plan('changed boundary ' + key, [key], value)
extra = copy.deepcopy(plan)
extra['machine_authorized'] = True
check('unknown plan authority key', rejected(validate, extra, confirmation, receipt, closure, frozen))
for key in plan['authorization']:
    bad_plan('opened old authorization ' + key, ['authorization', key], True)
for key, value in plan['fresh_boundary'].items():
    replacement = 'stale-historical-binding' if value is None else not value
    bad_plan('stale or invented live slot ' + key, ['fresh_boundary', key], replacement)
for key, value in plan['repository_stage_permission'].items():
    if isinstance(value, bool):
        bad_plan('weakened checkpoint gate ' + key, ['repository_stage_permission', key], not value)
bad_plan('inherited historical reserve scope', ['repository_stage_permission', 'current_scope'], 'historical-reserve309-310')
for key in ['commit_prefix', 'commit_full', 'acceptance_result', 'repository_file_count', 'provenance']:
    bad_plan('invented accepted checkpoint ' + key, ['accepted_checkpoint', key], 'invented')
bad_plan('boolean CHANGELOG length', ['accepted_checkpoint', 'changelog_size_bytes'], True)
bad_plan('incomplete predecessor manifest', ['accepted_checkpoint', 'sha256_bindings'], {})
bad_plan('different accepted file identity', ['accepted_checkpoint', 'sha256_bindings', 'CHANGELOG.md'], '0' * 64)
bad_plan('missing capability', ['deferred_capabilities'], plan['deferred_capabilities'][:-1])
bad_plan('reordered capabilities', ['deferred_capabilities'], list(reversed(plan['deferred_capabilities'])))
for capability in plan['deferred_capabilities']:
    bad_plan('missing separate review ' + capability, ['capability_review_requirements', capability, 'required_outputs'], [])
    bad_plan('premature capability complete ' + capability, ['capability_review_requirements', capability, 'operational_capability_complete'], True)
    bad_plan('live-use grant from review ' + capability, ['capability_review_requirements', capability, 'live_use_authorized'], True)
for offset, row in enumerate(plan['roadmap']['preferred_steps']):
    bad_plan('machine authority at stage ' + str(row['step']), ['roadmap', 'preferred_steps', offset, 'machine_authority'], True)
    bad_plan('capability readiness at stage ' + str(row['step']), ['roadmap', 'preferred_steps', offset, 'operational_readiness_granted'], True)
    bad_plan('reordered stage identity ' + str(row['step']), ['roadmap', 'preferred_steps', offset, 'step'], 999)
bad_plan('missing preferred step', ['roadmap', 'preferred_steps'], plan['roadmap']['preferred_steps'][:-1])
for key in ['roadmap_grants_later_repository_stages', 'roadmap_grants_machine_authority',
            'runtime_attempt_planned', 'fresh_live_observation_planned', 'pause_by_numeric_step_guaranteed']:
    bad_plan('roadmap overclaim ' + key, ['roadmap', key], True)
for offset in range(2):
    bad_plan('authorized optional reserve ' + str(319 + offset), ['roadmap', 'optional_failure_steps', offset, 'authorized_now'], True)
for key in plan['strong_pause_completion_conditions']:
    bad_plan('missing pause condition ' + key, ['strong_pause_completion_conditions', key], False)
bad_plan('weakened mandatory private tests', ['frozen_private_scope', 'mandatory_tests'], [])
bad_plan('candidate hash substituted for operational identity', ['frozen_private_scope', 'candidate_sha256_bindings'], {})
for key in ['mandatory_coverage_cannot_be_skipped_or_weakened', 'private_coverage_is_not_operational_conformance',
            'immutable_reference_and_candidate_preserved', 'historical_v2_never_sourced_or_run']:
    bad_plan('weakened private scope ' + key, ['frozen_private_scope', key], False)
for key in ['strong_safe_pause', 'accepted_closure_complete', 'user_application_completed',
    'user_harness_completed', 'user_commit_and_push_completed', 'user_worktree_clean',
    'user_head_matches_origin', 'production_entry_closed',
    'all_current_stage_and_operational_authority_closed', 'future_unused_live_bindings_closed',
    'repository_prepared_flags_remain_immutable_historical', 'prepared308_confirmation_gate_satisfied']:
    changed = copy.deepcopy(confirmation)
    changed[key] = False
    check('rejects incomplete308 confirmation ' + key, rejected(namespace['validate_confirmation'], changed, receipt))
for key, value in dict(commit_full='f' * 40, commit_prefix='otherid', historical_live_bindings_reusable=True,
    reserve309_310_authorized=True, current_boot_id='old-boot', operational_readiness=True,
    operational_conformance=True, current_pkglist_sha256='old-sha', phase2_open=True).items():
    changed = copy.deepcopy(confirmation)
    changed[key] = value
    check('rejects invented308 binding or permission ' + key, rejected(namespace['validate_confirmation'], changed, receipt))
for key, value in dict(text=receipt['text'][:-1], original_display_sha256='0' * 64,
    original_display_size_bytes=True, encoding='unknown').items():
    changed = copy.deepcopy(receipt)
    changed[key] = value
    check('rejects changed original receipt ' + key, rejected(namespace['validate_confirmation'], confirmation, changed))
record = (fixture / (base + '.tsv')).read_bytes()
roadmap = (fixture / (base + '-roadmap.tsv')).read_bytes()
namespace['validate_record'](record, plan)
namespace['validate_roadmap'](roadmap, plan)
check('strict real-tab record accepted', True)
check('record rejects duplicate key', rejected(namespace['validate_record'], record + b'step\t309\n', plan))
check('record rejects literal escaped tabs', rejected(namespace['validate_record'], record.replace(b'\t', b'\\t'), plan))
check('record rejects premature strong pause', rejected(namespace['validate_record'], record.replace(b'strong_safe_pause\tno', b'strong_safe_pause\tyes'), plan))
check('roadmap TSV rejects changed stage', rejected(namespace['validate_roadmap'], roadmap.replace(b'310\t', b'999\t'), plan))
for path in ['/tmp/escape', '../escape', 'a/../b', 'a//b', 'a/./b', 'a\\b', '']:
    check('unsafe relative path rejected ' + repr(path), rejected(namespace['safe_relative'], path))
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)
for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict planning CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('planning help describes repository-only scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)

with tempfile.TemporaryDirectory(prefix='step309-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real planning entry full unchanged324 predecessor acceptance', result.returncode == 0 and 'exact_step308_predecessor_acceptance\tPASS (324 passes, 0 failures)' in result.stdout)
    historical_log = (out / (base + '-predecessor-test.log')).read_text()
    check('preserved complete historical324 PASS sequence', sum(line.startswith('PASS: ') for line in historical_log.splitlines()) == 324 and historical_log.splitlines()[-1] == 'Result: PASS (324 passes, 0 failures)')
    check('planning entry carries no operational or new-pause grant', 'next_stage_authorized_now\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout)
    names = [base + suffix for suffix in ['-policy.json', '-checkpoint-confirmation.json', '-step308-user-acceptance.json', '.tsv', '-roadmap.tsv']]
    for name in names:
        check('exact published repository planning input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
    check('occupied planning directory rejected without overwrite', run(['bash', tool, '--output-dir', out]).returncode != 0)
    for name in names + [base + '-predecessor-test.log']:
        blocked = area / ('blocked-' + str(names.index(name)) if name in names else 'blocked-log')
        blocked.mkdir()
        (blocked / name).write_bytes(b'keep existing output\n')
        result = run(['bash', tool, '--output-dir', blocked])
        check('occupied output rejects before publication ' + name, result.returncode != 0 and list(blocked.iterdir()) == [blocked / name] and (blocked / name).read_bytes() == b'keep existing output\n')
    missing = area / 'missing-output'
    check('missing output directory rejected without creation', run(['bash', tool, '--output-dir', missing]).returncode != 0 and not missing.exists())
    linked = area / 'linked-output'
    linked.symlink_to(out, target_is_directory=True)
    check('output symlink rejected', run(['bash', tool, '--output-dir', linked]).returncode != 0)
    copied = area / 'slack-update'
    shutil.copytree(root, copied)
    copied_tool = copied / 'tools/reference' / (base + '.sh')
    clean_output = area / 'clean-output'
    clean_output.mkdir()
    mutation_paths = list(namespace['OWN_HASHES']) + [
        next(iter(frozen['candidate_sha256_bindings'])),
        plan['frozen_private_scope']['freeze_path'], 'CHANGELOG.md']
    for rel in mutation_paths:
        path = copied / rel
        original = path.read_bytes()
        path.write_bytes(original + b'\n')
        result = run(['bash', copied_tool, '--output-dir', clean_output])
        check('changed accepted/planning input rejects before publication ' + Path(rel).name, result.returncode != 0 and not list(clean_output.iterdir()))
        path.write_bytes(original)
    for rel in [plan['frozen_private_scope']['freeze_path'], 'docs/reference/' + base + '.md']:
        path = copied / rel
        original = path.read_bytes()
        saved = area / ('symlink-saved-' + str(len(list(area.iterdir()))))
        saved.write_bytes(original)
        path.unlink()
        path.symlink_to(saved)
        result = run(['bash', copied_tool, '--output-dir', clean_output])
        check('same-content symlink rejected ' + path.name, result.returncode != 0 and not list(clean_output.iterdir()))
        path.unlink()
        path.write_bytes(original)
    tiny = area / 'publication-unit'
    tiny.mkdir()
    check('publication seam rejects escaping output name', rejected(namespace['publish_outputs'], tiny, {'../escape': b'x'}) and not list(tiny.iterdir()))
    namespace['publish_outputs'](tiny, {'first': b'one', 'second': b'two'})
    check('exclusive publication creates only reviewed outputs', (tiny / 'first').read_bytes() == b'one' and (tiny / 'second').read_bytes() == b'two')
    check('publication does not overwrite existing file', rejected(namespace['publish_outputs'], tiny, {'first': b'overwrite'}) and (tiny / 'first').read_bytes() == b'one')

check('all accepted history still preserved after tests', namespace['verify_history'](root, plan['accepted_checkpoint'], namespace['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(namespace['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    content = (root / rel).read_text()
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in content.splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
