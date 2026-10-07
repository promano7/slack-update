#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1]); base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review'; fixture = root / 'tests/fixtures/reference/acceptance/phase-1/'
tool = root / 'tools/reference' / (base + '.py')
passes = 0
def check(label, condition):
    global passes
    if not condition:
        print('FAIL: ' + label)
        raise SystemExit(1)
    passes += 1; print('PASS: ' + label, flush=True)
def reject(fn, *args):
    try: fn(*args)
    except (ValueError, TypeError, KeyError, OSError): return True
    return False
def change(value, path, replacement):
    value = copy.deepcopy(value); cursor = value
    for key in path[:-1]: cursor = cursor[key]
    cursor[path[-1]] = replacement; return value
def run(argv):
    return subprocess.run([str(x) for x in argv], capture_output=True, text=True)
check('exact339 verifier SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '3c4b3acab3b0bb1a33863e2abdd927d7ebb2ba8af332e05bb580c96cb3127589')
# Execute the actual verifier definitions in memory; importing creates no pycache.
ns = {'__name__': 'private339_definitions'}
exec(compile(ast.parse(tool.read_text()), str(tool), 'exec'), ns)
load = lambda suffix: json.loads((fixture / (base + suffix)).read_bytes())
policy = load('-policy.json'); plan = load('-plan.json'); retained = load('-retained-obligations.json')
confirmation = load('-checkpoint-confirmation.json'); receipt = load('-step338-user-acceptance.json')
history = ns['verify'](root)
check('all1629 accepted source files with additive changelog preserved', len(history) == 1629)
check('complete externally confirmed338 acceptance retained', ns['validate_checkpoint'](confirmation, receipt))
conditions = ns['validate_retained'](retained, history)
check('ten-stage pure offline route with every pause condition', ns['validate_plan'](plan, conditions))
for key in ns['FALSE_FIELDS']:
    check('rejects invented authority or completion ' + key, reject(ns['validate_plan'], change(plan, [key], True), conditions))
for key in ns['TRUE_FIELDS']:
    check('rejects missing required boundary ' + key, reject(ns['validate_plan'], change(plan, [key], False), conditions))
for key, value in [('step', True), ('schema', True), ('actual_host_state', 'absent'), ('actual_live_bindings', {'boot': 'old'}), ('preferred_step_range', [339, 350]), ('conditional_pause_step', 347), ('native_cases_run', 1), ('native_proofs_added', 1), ('core_execution_scope', 'dispatch-native'), ('compatibility_claim', 'native-PASS'), ('pause_conditions', conditions[:-1]), ('route', [])]:
    check('rejects unsafe plan ' + key, reject(ns['validate_plan'], change(plan, [key], value), conditions))
check('rejects extra native grant field', reject(ns['validate_plan'], dict(plan, grant='old'), conditions))
for i, row in enumerate(plan['route']):
    for key, value in [('entry_requires_confirmed_step', 338 if i else 337), ('runtime_authorized', True), ('deliverable', ''), ('step', True), ('status', 'native-authorized')]:
        check('route' + str(row['step']) + ' rejects ' + key, reject(ns['validate_plan'], change(plan, ['route', i, key], value), conditions))
for name, index in retained['registers'].items():
    check('cannot omit full register ' + name, reject(ns['validate_retained'], change(retained, ['registers', name, 'rows'], index['rows'][:-1]), history))
    check('cannot change original obligation ' + name, reject(ns['validate_retained'], change(retained, ['registers', name, 'rows', 0, 'canonical_row_sha256'], '0'*64), history))
    check('rejects bool obligation position ' + name, reject(ns['validate_retained'], change(retained, ['registers', name, 'rows', 0, 'position'], False), history))
for key, value in [('text', receipt['text'][:-1]), ('original_display_size_bytes', True), ('original_display_sha256', '0'*64)]:
    check('rejects incomplete receipt ' + key, reject(ns['validate_checkpoint'], confirmation, change(receipt, [key], value)))
for key, value in [('step', True), ('commit_prefix', 'fffffff'), ('user_worktree_clean', False), ('user_head_matches_origin', False), ('runtime_authority', True), ('strong_safe_pause', False)]:
    check('rejects invented checkpoint ' + key, reject(ns['validate_checkpoint'], change(confirmation, [key], value), receipt))
for rel in ['/absolute', '../escape', 'a//b', 'a/./b', 'a/../b', 'a\\b', '']:
    check('rejects unsafe path ' + repr(rel), reject(ns['safe_path'], root, rel))
for args in [[], ['--bogus'], ['--check'], ['--check', ''], ['--check', root, 'extra']]:
    check('strict CLI ' + repr(args), run(['python3', '-B', tool, *args]).returncode == 2)
result = run(['python3', '-B', tool, '--check', root])
if result.returncode: sys.stderr.write(result.stdout + result.stderr)
check('actual339 entry validates repository plan', result.returncode == 0 and 'step339_repository_planning_status\tPASS' in result.stdout)
check('entry emits no runtime authority or native result', 'runtime_authority\tno' in result.stdout and 'native_cases_run\t0' in result.stdout)
with tempfile.TemporaryDirectory(prefix='step339-history-') as directory:
    area = Path(directory); snapshot = area / 'accepted338'; snapshot.mkdir()
    for rel, raw in history.items():
        p = snapshot / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(raw)
    check('historical prepared338 pending flags not rewritten', json.loads((snapshot / 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-scoped-candidate-artifact-freeze-gap-register-and-safe-pause-review-policy.json').read_bytes())['strong_safe_pause'] is False)
    # All inspected source remains inert; only the exact private predecessor harness executes.
    result = run(['bash', snapshot / policy['predecessor_harness']])
    log = result.stdout.splitlines()
    if result.returncode: sys.stderr.write(result.stdout + result.stderr)
    check('full exact364 predecessor and nested historical tests pass', result.returncode == 0 and log and log[-1] == policy['predecessor_acceptance'])
    expected = [x for x in receipt['text'].splitlines() if x.startswith('PASS: ')]
    check('complete ordered364 predecessor equals original user receipt', [x for x in log if x.startswith('PASS: ')] == expected and len(expected) == 364)
    # Output and negative source checks operate on a separate private candidate snapshot.
    candidate = area / 'candidate'; shutil.copytree(root, candidate)
    for rel in list(ns['OWN_HASHES']) + ['tools/reference/slack-update-reference.sh', 'CHANGELOG.md']:
        p = candidate / rel; old = p.read_bytes(); p.write_bytes(old + b'\n')
        # Appended changelog bytes cannot match its original source suffix.
        check('changed source rejects ' + p.name, reject(ns['verify'], candidate))
        p.write_bytes(old)
    p = candidate / 'tools/reference/slack-update-reference.sh'; saved = area / 'saved'; saved.write_bytes(p.read_bytes()); p.unlink(); p.symlink_to(saved)
    check('same-byte operational source symlink rejected', reject(ns['verify'], candidate))
check('accepted history unchanged after all tests', ns['verify'](root) == history)
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
