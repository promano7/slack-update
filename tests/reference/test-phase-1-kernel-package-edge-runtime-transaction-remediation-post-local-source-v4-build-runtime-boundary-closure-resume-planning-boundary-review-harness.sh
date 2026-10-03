#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import csv
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
root = Path(sys.argv[1]); base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review'; prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause'
own = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review.md': 'c52d8dacffb8f9b4475a96deb6b0a0fc601b2200fb5493413f18f8da60455e8d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-checkpoint-confirmation.json': '96bfae4a558456dc53a7eb7b313e5b20a03e9ee693c4a1e1f609ccc5b182cdeb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-policy.json': 'c90cada68176cea957390da133be2342f6155f1b62dfd3331e6fc8e54a2fdfdf', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-roadmap.tsv': '6de179130cc63ea418d6c134fca26bb53f5bc1252a119976223c10be51a8fb67', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review-step298-user-acceptance.json': '96e3a850cfd24be65eedabae09933dd3c79dd8edb97d585862467a121418c804', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review.tsv': '697616cf7af36d0b57b240e197e3f2f727c833e26f37ce834ed222c778e8346d', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review.sh': '71058e1854bb3da5d41d384f3f147e0f234b101649629f61d00d82e0911c379b'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
plan = json.loads((fixture / (base + '-policy.json')).read_text())
accepted = plan['accepted_checkpoint']
closed = json.loads((fixture / (prior + '-closure.json')).read_text())
frozen = json.loads((root / closed['preservation']['frozen_boundary_path']).read_text())
helper = root / 'tools/reference' / (base + '.sh')
passes = 0
def check(label, value):
    global passes
    if not value: raise SystemExit('FAIL: ' + label)
    passes += 1; print('PASS: ' + label)
def run(argv):
    return subprocess.run([str(x) for x in argv], capture_output=True, text=True)
def bound_history():
    for rel, digest in accepted['sha256_bindings'].items():
        p = root / rel
        if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute(): return False
        data = p.read_bytes()
        if rel == 'CHANGELOG.md': data = data[-accepted['changelog_size_bytes']:]
        if hashlib.sha256(data).hexdigest() != digest: return False
    return len(accepted['sha256_bindings']) == 1274
check('all1274 safe exact historical artifacts and CHANGELOG suffix', bound_history())
for rel, digest in own.items():
    p = root / rel
    check('exact new input: ' + p.name, p.is_file() and not p.is_symlink() and p.resolve() == p.absolute() and hashlib.sha256(p.read_bytes()).hexdigest() == digest)
for p in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + p.name, run(['bash', '-n', p]).returncode == 0)
source = helper.read_text(); code = source.split("<<'PYPLAN'\n", 1)[1].rsplit('\nPYPLAN', 1)[0]
nodes = [n for n in ast.parse(code).body if isinstance(n, ast.FunctionDef) and n.name == 'validate_resume_plan']
check('one exact pure gate extracted without top-level execution', len(nodes) == 1)
scope = {'json': json}
exec(compile(ast.fix_missing_locations(ast.Module(body=nodes, type_ignores=[])), '<resume-gate>', 'exec'), scope)
gate = scope['validate_resume_plan']
check('pure gate accepts complete reviewed plan', gate(plan, closed, frozen) is True)
receipt_fixture = json.loads((root / accepted['evidence_path']).read_text())
receipt = receipt_fixture['text'].encode('utf-8')
confirmation = json.loads((root / accepted['confirmation_path']).read_text())
check('complete user receipt hash bound', hashlib.sha256(receipt).hexdigest() == accepted['evidence_sha256'] == confirmation['evidence_sha256'])
check('user full304 commit push and status evidence retained', all(x in receipt for x in [b'Result: PASS (304 passes, 0 failures)', b'[main acc26e3]', b'195d8dd..acc26e3  main -> main', b'git status --short']))
check('confirmed298 supersedes prepared wording without historical edits', all(confirmation[k] is True for k in ['prepared_contract_confirmation_gate_satisfied', 'user_harness_completed', 'user_application_completed', 'user_commit_and_push_completed', 'user_worktree_clean', 'strong_safe_pause']) and confirmation['repository_bytes_changed_for_confirmation'] is False)
check('prefix only no invented full ID or current boot', accepted['commit_full'] is None and confirmation['commit_full'] is None and confirmation['current_boot_id'] is None)
check('exact future resume stage from closed298', closed['resume']['next_repository_stage'] == base)
executor = root / frozen['executor']['future_executor_path']
check('executor absent at299', not executor.exists() and not executor.is_symlink())
def rejected(bad):
    try: gate(bad, closed, frozen)
    except (ValueError, KeyError, TypeError): return True
    return False
mutations = [(['schema'], True), (['step'], 299.0), (['review_only'], 1),
    (['accepted_checkpoint', 'commit_full'], 'acc26e3' + '0' * 33),
    (['accepted_checkpoint', 'user_worktree_clean'], False), (['accepted_checkpoint', 'repository_file_count'], 1274.0),
    (['accepted_checkpoint', 'changelog_size_bytes'], True),
    (['accepted_authority_and_effect_closure', 'effects', 'unresolved_transaction'], True),
    (['accepted_runtime_boundary', 'source', 'manifest_sha256'], '0' * 64),
    (['accepted_runtime_boundary', 'candidate', 'exact_target_candidate_count'], 2),
    (['fresh_boundary', 'current_boot_id'], closed['observation']['boot_id']),
    (['fresh_boundary', 'current_pkglist_sha256'], '0' * 64),
    (['fresh_boundary', 'future_executor_sha256'], '0' * 64),
    (['authorization', 'repository_only_transaction_contract_review_authorized'], 1),
    (['authorization', 'repository_only_executor_implementation_authorized'], True),
    (['authorization_scope'], 'unconditional-next-stage'),
    (['roadmap', 'preferred_step_count'], True), (['roadmap', 'maximum_planned_step_count'], 13),
    (['roadmap', 'preferred_steps', 5, 'machine_authority'], True),
    (['roadmap', 'preferred_steps', 5, 'requires_previous_user_checkpoint'], False),
    (['roadmap', 'preferred_steps', 6, 'scope'], 'runtime'),
    (['roadmap', 'preferred_steps', 0, 'conditional_pause_candidate'], True),
    (['roadmap', 'optional_failure_steps', 0, 'step'], 299),
    (['roadmap', 'optional_failure_steps', 1, 'machine_authority'], True),
    (['next_stage'], 'runtime-now')]
for section, keys in {
    'fresh_boundary': ['current_boot_continuity_asserted', 'current_target_or_source_preservation_observed', 'current_predecessor_availability_observed', 'current_candidate_binding_created', 'v4_runtime_pkglist_generation_observed', 'phase1_matrix_complete', 'phase2_open'],
    'authorization': ['runtime_executor_rerun_authorized', 'new_executor_transport_authorized', 'new_executor_execution_authorized'],
    'roadmap': ['roadmap_grants_machine_authority', 'roadmap_grants_later_repository_stages', 'runtime_attempt_planned', 'fresh_live_observation_planned', 'pause_by_numeric_step_guaranteed'],
    'repository_acceptance_scope': ['production_executor_sourced_or_run', 'historical_artifacts_or_constants_patched']}.items():
    mutations += [([section, key], True) for key in keys]
mutations += [([key], True) for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause', 'user_step299_checkpoint_confirmed']]
mutations += [(['required_design_topics', k], 'Boundary removed.') for k in ['fresh_pkglist', 'exact_candidate_binding', 'restoration', 'publication', 'closed_entry', 'historical_acceptance']]
mutations += [(['preservation', 'v4_source_manifest_sidecar_target'], False), (['strong_pause_completion_conditions', 'not_based_on_preflight_alone'], False)]
for keys, value in mutations:
    bad = copy.deepcopy(plan); node = bad
    for key in keys[:-1]: node = node[key]
    node[keys[-1]] = value
    check('pure gate rejects ' + '.'.join(str(k) for k in keys), rejected(bad))
for section in ['preservation', 'strong_pause_completion_conditions', 'required_design_topics', 'authorization']:
    bad = copy.deepcopy(plan); bad[section].pop(next(iter(bad[section])))
    check('missing requirement rejected: ' + section, rejected(bad))
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict unique real-tab record', all(len(r) == 2 and all(r) for r in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record matches authority and state', all(record[k] == ('yes' if v else 'no') for k, v in plan['authorization'].items()) and record['next_stage'] == plan['next_stage'] and record['accepted_checkpoint_commit'] == 'acc26e3')
with (fixture / (base + '-roadmap.tsv')).open(newline='') as handle: roadmap = list(csv.DictReader(handle, delimiter='\t'))
check('roadmap TSV exactly matches reviewed JSON gates', roadmap == [{k: 'yes' if v is True else 'no' if v is False else str(v) for k, v in r.items()} for r in plan['roadmap']['preferred_steps']])
for args in [[], ['--help'], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict CLI ' + repr(args), run(['bash', helper, *args]).returncode == (0 if args == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step299-tests-') as directory:
    tmp = Path(directory); out = tmp / 'plan with spaces'; out.mkdir()
    call = run(['bash', helper, '--output-dir', out])
    check('full304 historical acceptance actually reruns before publication', call.returncode == 0 and 'accepted_step298_revalidated\tPASS (304 passes, 0 failures)' in call.stdout)
    for suffix in ['-policy.json', '.tsv', '-roadmap.tsv', '-checkpoint-confirmation.json', '-step298-user-acceptance.json']:
        check('exact bounded publication ' + suffix, (out / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper reports no runtime or new pause', 'runtime_attempt_authorized\tno' in call.stdout and 'strong_safe_pause\tno' in call.stdout)
    before = {p.name: p.read_bytes() for p in out.iterdir()}
    check('existing output rejected without overwrite', run(['bash', helper, '--output-dir', out]).returncode != 0 and before == {p.name: p.read_bytes() for p in out.iterdir()})
    link = tmp / 'output-link'; link.symlink_to(out, target_is_directory=True)
    check('symlink output rejected', run(['bash', helper, '--output-dir', link]).returncode != 0)
    nested = out / 'nested'; nested.mkdir()
    check('symlink ancestor rejected', run(['bash', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output directory rejected', run(['bash', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected_out = tmp / 'rejected'; rejected_out.mkdir(); rh = replica / helper.relative_to(root)
    targets = ['CHANGELOG.md', frozen['executor']['historical_executor_path'], closed['preservation']['frozen_boundary_path'],
               'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh']
    targets += [rel for rel in own if rel != helper.relative_to(root).as_posix()]
    for rel in targets:
        p = replica / rel; old = p.read_bytes(); p.write_bytes(old + b'\n')
        check('changed bound input rejected: ' + p.name, run(['bash', rh, '--output-dir', rejected_out]).returncode != 0 and not list(rejected_out.iterdir()))
        p.write_bytes(old)
    p = replica / frozen['executor']['historical_executor_path']; old = p.read_bytes(); p.unlink(); p.symlink_to(root / p.relative_to(replica))
    check('same-content historical symlink rejected', run(['bash', rh, '--output-dir', rejected_out]).returncode != 0 and not list(rejected_out.iterdir()))
    p.unlink(); p.write_bytes(old)
    future = replica / frozen['executor']['future_executor_path']; future.write_text('THIS FIXTURE MUST NEVER EXECUTE\n')
    isolated = tmp / 'isolated'; isolated.mkdir()
    call = run(['bash', rh, '--output-dir', isolated])
    check('exact historical acceptance survives later artifact outside snapshot', call.returncode == 0 and 'accepted_step298_revalidated\tPASS (304 passes, 0 failures)' in call.stdout and future.read_text() == 'THIS FIXTURE MUST NEVER EXECUTE\n')
check('accepted actual bytes and absent executor preserved after tests', bound_history() and not executor.exists())
for rel in list(own) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG confirms298 and prepares299 without premature pause', '## Phase 1 step 299 ' in changelog and 'acc26e3' in changelog and 'Step298 remains a valid historical strong pause' in changelog and 'pause_safe=false' in changelog and '## Phase 1 step 298 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
