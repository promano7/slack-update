#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy
import hashlib
import json
import runpy
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review.md': '034c055e9e6e0a3ca4212054420ae041c209f43eae6881a1650a83f8a028e797', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-checkpoint-confirmation.json': '27eca1f98f206e5db936b199f5dd40997fd008ffcbc65329e03c6f666bdb5aa2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-freeze.json': '842857a0e9e86496dd65507604555fe1e9faf342f1f803a7a805332b3009e9ad', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-native-gap-register.json': 'bc08559d8b3e1af94247753f94012759c5bcf7b875d244fd9bc4328ba2f88305', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-pause-conditions.json': 'c84c3a8816f6d2d2f3206da7c06f5d96fb04cb60fe9cade039b55c7c8cb36d5d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-policy.json': '35330a681670487b4a3691fb92bcf3410e4433798b5be6da73ba0f21c99e2f0b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-step357-user-acceptance.json': '9b18b890c8cf904e65f0ef26df3d44037eb2e3c8d2b6c17ddac357d7e09a80bf', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review.py': '03796d4052ddd40fd4241a890d45cb364f8b466828bb36b0a749f719080fda06'}
addition_sha = '16f0d6bf15f6d273425539cbb8e2f6ba56ecb1475739bc9daffe2051f1bebf3e'
passes = 0
def check(label, condition):
    global passes
    if not condition:
        raise AssertionError(label)
    passes += 1
    print('PASS: ' + label, flush=True)
def load(tail):
    return json.loads((fixture / (base + '-' + tail + '.json')).read_bytes())
def rejected(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, TypeError):
        return True
    return False
for rel, digest in own_hashes.items():
    path = root / rel
    check('exact current358 input ' + path.name, path.is_file() and not path.is_symlink() and path.resolve() == path.absolute() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
module = runpy.run_path(str(root / 'tools/reference' / (base + '.py')))
policy = load('policy'); freeze = load('freeze'); gaps = load('native-gap-register')
conditions = load('pause-conditions'); receipt = load('step357-user-acceptance'); confirmed = load('checkpoint-confirmation')
history = {}
for rel, digest in policy['baseline_sha256_bindings'].items():
    path = root / rel
    if not path.is_file() or path.is_symlink() or path.resolve() != path.absolute():
        raise ValueError('unsafe accepted source ' + rel)
    raw = path.read_bytes()
    if rel == 'CHANGELOG.md':
        size = policy['accepted_changelog_size']
        check('exact additive358 CHANGELOG prefix', hashlib.sha256(raw[:-size]).hexdigest() == addition_sha)
        raw = raw[-size:]
    if hashlib.sha256(raw).hexdigest() != digest:
        raise ValueError('accepted357 source drift ' + rel)
    history[rel] = raw
check('all1800 accepted357 files remain exact', len(history) == 1800)
prior = module['PRIOR']; prefix = module['FIXTURE'] + prior
ledger = json.loads(history[prefix + '-reconciliation-ledger.json'])
source_map = json.loads(history[prefix + '-full-contract-source-map.json'])
check('complete original Markdown357 return retained and explicitly compared', module['validate_return'](confirmed, receipt, policy))
check('81 accepted349-357 artifacts frozen without native promotion', module['validate_freeze'](freeze, ledger, source_map, policy))
check('entire normative rows original contracts and native gaps retained', module['validate_gaps'](gaps, ledger, source_map))
check('nine scoped conditions retained with final358 receipt pending', module['validate_conditions'](conditions, freeze))
for row in freeze['frozen_artifact_registry349_357']:
    check('frozen accepted comparator source ' + str(row['step']) + '/' + row['path'], hashlib.sha256(history[row['path']]).hexdigest() == row['sha256'])
check('accepted348-357 chain includes complete357 original receipt', [row['step'] for row in freeze['accepted_checkpoint_chain348_357']] == list(range(348, 358)))
for row in freeze['accepted_checkpoint_chain348_357']:
    for kind in ('receipt', 'confirmation'):
        binding = row[kind]
        check('whole checkpoint binding ' + str(row['step']) + '/' + kind, hashlib.sha256((root / binding['path']).read_bytes()).hexdigest() == binding['sha256'])
norm = gaps['full_normative_rows']
for row in norm['qualified_proof_reconciliation']:
    check('native proof remains required-not-proven ' + row['qualified_id'], row['status'] == 'required-not-proven' and row['actual_evidence'] is None and row['private_PASS_is_native_proof'] is False)
for row in norm['native_case_templates']:
    check('native case remains required-not-run ' + row['platform'] + '/' + row['case_id'], row['status'] == 'required-not-run' and all(v is None for k, v in row.items() if k.startswith('actual_')))
for row in gaps['full_original_native_gap_rows348']:
    check('native blocker retained ' + row['inherited_gap']['id'], row['status'] == 'required-not-selected-refined-or-proven' and row['native_status_promoted'] is False)
for row in gaps['full_original_evidence_group_rows335']:
    check('native raw evidence group remains uncaptured ' + row['id'], row['status'] == 'required-native-evidence-not-captured')
fake = {'schema': 1, 'step': 358, 'scope': module['SCOPE'], 'origin': 'synthetic-private-fixture',
        'checks': {row['id']: True for row in conditions['conditions']},
        'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'runtime_authority': False}
eligibility = module['private_pause_eligibility'](fake, conditions)
check('all-true private fixture never confirms actual pause or authority', eligibility['model_scoped_pause_confirmation_eligible'] is True and all(eligibility[key] is False for key in ('actual_strong_safe_pause_confirmed', 'actual_global_host_closure', 'actual_operational_conformance', 'actual_runtime_authority')))
for row in conditions['conditions']:
    mutated = copy.deepcopy(fake); mutated['checks'][row['id']] = False
    result = module['private_pause_eligibility'](mutated, conditions)
    check('false condition cannot close pause ' + row['id'], result['model_scoped_pause_confirmation_eligible'] is False and result['model_pending_conditions'] == [row['id']])
for key, value in [('scope', 'whole-host'), ('runtime_authority', True), ('runtime_authority', 0), ('actual_host_state', 'absent'), ('actual_live_bindings', {'boot': 'historical'}), ('origin', 'user-native-return'), ('step', 357), ('schema', True)]:
    mutated = copy.deepcopy(fake); mutated[key] = value
    check('private promotion rejected ' + key + '/' + repr(value), rejected(module['private_pause_eligibility'], mutated, conditions))
for name, change in [('extra-field', lambda v: v.update(extra=True)), ('missing-condition', lambda v: v['checks'].pop(next(iter(v['checks'])))), ('integer-condition', lambda v: v['checks'].update({next(iter(v['checks'])): 1}))]:
    mutated = copy.deepcopy(fake); change(mutated)
    check('closed private eligibility rejects ' + name, rejected(module['private_pause_eligibility'], mutated, conditions))
for key, value in [('strong_safe_pause', True), ('runtime_authority', True), ('phase2_open', True), ('actual_host_state', 'globally-closed'), ('actual_live_bindings', {'epoch': 'old'}), ('native_cases_run', 1), ('next_authorized_stage', 359), ('historical_binding_or_authority_reuse_allowed', True), ('operational_readiness', True)]:
    mutated = copy.deepcopy(freeze); mutated[key] = value
    check('freeze denies native promotion ' + key, rejected(module['validate_freeze'], mutated, ledger, source_map, policy))
mutated = copy.deepcopy(freeze); mutated['frozen_artifact_registry349_357'].pop()
check('missing accepted comparator artifact rejected', rejected(module['validate_freeze'], mutated, ledger, source_map, policy))
mutated = copy.deepcopy(gaps); mutated['full_normative_rows']['qualified_proof_reconciliation'][0]['status'] = 'proven'
check('native proof waiver rejected', rejected(module['validate_gaps'], mutated, ledger, source_map))
mutated = copy.deepcopy(gaps); mutated['full_original_contracts320_327'].pop('320')
check('whole original contract deletion rejected', rejected(module['validate_gaps'], mutated, ledger, source_map))
for i in range(9):
    mutated = copy.deepcopy(conditions); mutated['conditions'][i]['status'] = 'globally-confirmed'
    check('invented actual condition closure rejected ' + str(i), rejected(module['validate_conditions'], mutated, freeze))
mutated = copy.deepcopy(receipt); mutated['text'] += ' invented status'
check('changed original user return rejected', rejected(module['validate_return'], confirmed, mutated, policy))
for key, value in [('commit_prefix', 'invented'), ('commit_full', '0' * 40), ('user_worktree_clean', False), ('strong_safe_pause', True)]:
    mutated = copy.deepcopy(confirmed); mutated[key] = value
    check('invented accepted357 fact rejected ' + key, rejected(module['validate_return'], mutated, receipt, policy))
with tempfile.TemporaryDirectory(prefix='step358-exact-accepted357-') as directory:
    historical = Path(directory)
    for rel, raw in history.items():
        path = historical / rel; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(raw)
    result = subprocess.run(['bash', str(historical / 'tests/reference' / ('test-' + prior + '-harness.sh'))], capture_output=True, text=True)
    if result.returncode:
        raise AssertionError('unchanged357 failed: ' + result.stderr[-3000:])
    check('full unchanged357931 acceptance on exact1800 snapshot', result.stdout.splitlines().count('Result: PASS (931 passes, 0 failures)') == 1)
    check('all931 unchanged predecessor labels equal original displayed return', [line for line in result.stdout.splitlines() if line.startswith('PASS: ')] == policy['accepted_ordered357_labels'])
check('stop after final358 receipt with no next authorized stage', freeze['next_authorized_stage'] is None and freeze['stop_after_complete358_acceptance'] is True and freeze['future_work_requires_new_user_request'] is True)
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
