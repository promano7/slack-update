#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast
import copy
import json
import runpy
import subprocess
import sys

root = Path(sys.argv[1]); step = 'phase-1-operational-feasibility-decision-freeze-and-safe-pause-review'
prefix = root / 'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):
    return json.loads((prefix / (step + '-' + suffix + '.json')).read_bytes())
p = load('policy'); c = load('confirmed387'); r = load('step387-user-acceptance')
f = load('freeze'); pause = load('pause-conditions'); s = load('sources')
tool = root / 'tools/reference' / (step + '.py'); m = runpy.run_path(str(tool)); passes = 0
def check(label, value):
    global passes
    if not value: raise SystemExit('FAIL: ' + label)
    passes += 1; print('PASS: ' + label)
def rejected(fn, *args):
    try: fn(*args)
    except (ValueError, KeyError, TypeError): return True
    return False
blobs = {}
for rel in p['baseline_sha256']:
    path = root / rel
    if not path.is_file() or path.is_symlink() or path.resolve() != path.absolute():
        raise SystemExit('FAIL: unsafe387 artifact ' + rel)
    blobs[rel] = path.read_bytes()
addition = blobs['CHANGELOG.md'][:-p['accepted_changelog_size_bytes']]
inputs = {key: (root / path).read_bytes() for key, path in p['whole_input_paths'].items()}
prior = json.loads(inputs['freeze378'])
sources = {row['path']: (root / row['path']).read_bytes() for row in prior['review_sources']}
reviewers = {path: (root / path).read_bytes() for path in p['batch_reviewer_sha256']}
readme = blobs['README.md']
check('authored388 policy independently frozen', m['validate_policy'](p))
check('whole2025 accepted387 bytes exact except additive CHANGELOG', m['validate_baseline'](blobs, addition, p))
check('complete387 visible transcript exact211 labels commit push reported clean matching heads', m['validate_acceptance'](c, r, p))
check('whole40 normative inputs four inert roots nine reviewers and README bound', m['validate_inputs'](inputs, sources, reviewers, readme, p))
check('whole decision freeze and nine full original conditions validate without current confirmation', m['validate_freeze'](f, pause, s, inputs, p))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    actual = {x.decode() for x in raw.split(b'\0') if x}
else:
    actual = {str(path.relative_to(root)) for path in root.rglob('*') if path.is_file() and '.git' not in path.relative_to(root).parts}
check('exact nine new Git visible artifacts ignored local outputs retained', actual == set(p['baseline_sha256']) | set(p['new_paths']))
for key in inputs:
    bad = dict(inputs); bad[key] += b'\n'
    check('reject whole normative input drift ' + key, rejected(m['validate_inputs'], bad, sources, reviewers, readme, p))
for path in sources:
    bad = dict(sources); bad[path] += b'\n'
    check('reject inert source drift ' + path, rejected(m['validate_inputs'], inputs, bad, reviewers, readme, p))
for path in reviewers:
    bad = dict(reviewers); bad[path] += b'\n'
    check('reject accepted batch reviewer drift ' + path, rejected(m['validate_inputs'], inputs, sources, bad, readme, p))
check('reject accepted README drift', rejected(m['validate_inputs'], inputs, sources, reviewers, readme + b'\n', p))
for key, value in [('commit_full', 'invented'), ('strong_safe_pause', True), ('native_cases_run', 1), ('native_proofs_added', 1),
                   ('runtime_authority', True), ('actual_host_state', 'absent'), ('actual_live_bindings', {}),
                   ('actual_global_host_closure', True), ('user_worktree_clean', False), ('user_head_matches_origin', False),
                   ('capture_basis', 'independent-terminal-byte-capture')]:
    bad = copy.deepcopy(c); bad[key] = value
    check('reject387 acceptance promotion ' + key, rejected(m['validate_acceptance'], bad, r, p))
for label, change in [
    ('truncated transcript', lambda t: t[:-1]),
    ('same size commit edit', lambda t: t.replace('086aab2', '086aab3', 1)),
    ('dirty final status injected', lambda t: t.replace('\n086aab2 (HEAD', '\n M README.md\n086aab2 (HEAD', 1)),
    ('ordered PASS changed', lambda t: t.replace(p['expected_ordered_PASS_labels387'][0], p['expected_ordered_PASS_labels387'][1], 1)),
]:
    bad = copy.deepcopy(r); bad['text'] = change(r['text'])
    check('reject ' + label, rejected(m['validate_acceptance'], c, bad, p))
for key, value in f['boundaries'].items():
    bad = copy.deepcopy(f)
    bad['boundaries'][key] = not value if type(value) is bool else (value + 1 if type(value) is int else {})
    check('reject changed native or project boundary ' + key, rejected(m['validate_freeze'], bad, pause, s, inputs, p))
for index, row in enumerate(pause['conditions']):
    for key, value in [('requirement', 'abbreviated'), ('full_prepared_condition378', {'id': row['id']}),
                       ('current388_actual_user_confirmation', True), ('actual_native_evidence', 'proven'),
                       ('actual_global_host_closure', True), ('repository_review_basis', 'all host artifacts absent')]:
        bad = copy.deepcopy(pause); bad['conditions'][index][key] = value
        check('reject full pause condition mutation ' + str(index) + ' ' + key, rejected(m['validate_freeze'], f, bad, s, inputs, p))
for key, value in [('actual_strong_safe_pause_confirmed', True), ('private_eligibility_is_actual_confirmation', True),
                   ('current388_user_commit_prefix', 'invented'), ('current388_user_commit_full', 'invented'),
                   ('current388_user_worktree_clean', True), ('current388_user_head_matches_origin', True),
                   ('actual_host_state', 'absent'), ('actual_live_bindings', {}), ('actual_global_host_closure', True),
                   ('runtime_authority', True), ('final_receipt_rule', 'prepared tests suffice')]:
    bad = copy.deepcopy(pause); bad[key] = value
    check('reject premature pause promotion ' + key, rejected(m['validate_freeze'], f, bad, s, inputs, p))
for key, value in [('actual_strong_safe_pause_confirmed', True), ('private_eligibility_is_actual_confirmation', True),
                   ('current388_actual_final_user_receipt', 'invented'), ('next_authorized_stage_after388', 389),
                   ('no_automatic389', False), ('runtime_authority', True), ('native_cases_run', 1),
                   ('native_proofs_added', 1), ('actual_host_state', 'absent'), ('actual_live_bindings', {}),
                   ('actual_global_host_closure', True), ('machine_action_required', True), ('controller_action_required', True),
                   ('native_readiness_still_blocked', False), ('whole_original_requirements_normative', False),
                   ('contract_relaxation_permitted', True), ('primary_assignments_limit_normative_scope', True),
                   ('final_pause_requires_complete_actual_user_receipt', False), ('final_pause_requires_all_nine_whole_original_conditions', False)]:
    bad = copy.deepcopy(f); bad[key] = value
    check('reject decision freeze promotion ' + key, rejected(m['validate_freeze'], bad, pause, s, inputs, p))
for key, value in f['after_final_acceptance'].items():
    bad = copy.deepcopy(f)
    bad['after_final_acceptance'][key] = not value if type(value) is bool else 'invented'
    check('reject changed after final acceptance boundary ' + key, rejected(m['validate_freeze'], bad, pause, s, inputs, p))
for label, change in [
    ('boolean schema', lambda x: x.update(schema=True)),
    ('whole input omitted', lambda x: x['frozen_inputs']['paths'].pop('accepted386dossier')),
    ('whole accepted387 shortened', lambda x: x.update(whole_accepted387_reconciliation={'step': 387})),
    ('original candidate promoted', lambda x: x['whole_accepted387_reconciliation']['whole_accepted386_integrated_dossier']['candidates'][0].update(native_blocker_resolved=True)),
    ('original stage12 shortened', lambda x: x['whole_accepted387_reconciliation']['whole_accepted386_integrated_dossier']['original316_whole_stage12'].update(operation='subset')),
    ('future test prerequisites shortened', lambda x: x['whole_accepted387_reconciliation']['whole_accepted386_integrated_dossier']['whole377_future_test_entry_prerequisites'].pop()),
    ('whole finite roadmap shortened', lambda x: x['whole379_roadmap'].pop()),
    ('accepted chain omitted', lambda x: x['accepted_checkpoint_chain379_387'].pop()),
    ('original reviewer omitted', lambda x: x['batch_reviewer_roots'].pop()),
]:
    bad = copy.deepcopy(f); change(bad)
    check('reject ' + label, rejected(m['validate_freeze'], bad, pause, s, inputs, p))
bad = copy.deepcopy(pause); bad['conditions'].pop()
check('reject missing whole original condition', rejected(m['validate_freeze'], f, bad, s, inputs, p))
bad = copy.deepcopy(pause); bad['conditions'].reverse()
check('reject reordered whole original conditions', rejected(m['validate_freeze'], f, bad, s, inputs, p))
bad = dict(blobs); bad['CHANGELOG.md'] += b'\n'
check('reject historical CHANGELOG suffix drift', rejected(m['validate_baseline'], bad, addition, p))
bad = copy.deepcopy(p); bad['baseline_sha256']['README.md'] = '0' * 64
check('reject reanchored policy', rejected(m['validate_policy'], bad))
bad = copy.deepcopy(s); bad[0]['retrieval'] = 'native platform evidence'
check('reject supplied source register promoted to native evidence', rejected(m['validate_freeze'], f, pause, bad, inputs, p))
report = m['review'](f, pause, s, c, r, inputs, sources, reviewers, readme, p)
check('report retains40 whole input bindings and every original full condition', report['whole_input_bindings'] == p['whole_input_sha256'] and report['pause']['conditions'] == pause['conditions'])
check('report leaves actual pause pending and stops after388', not report['strong_safe_pause'] and report['native_entry_blocked'] and report['next_authorized_stage_after388'] is None and report['no_automatic389'])
report['pause']['actual_strong_safe_pause_confirmed'] = True
check('detached report cannot supply final confirmation', not pause['actual_strong_safe_pause_confirmed'] and not m['review'](f, pause, s, c, r, inputs, sources, reviewers, readme, p)['pause']['actual_strong_safe_pause_confirmed'])
forbidden = {'open', 'exec', 'eval', 'compile', '__import__', 'system', 'popen', 'run', 'read_bytes', 'read_text', 'decode', 'socket', 'urlopen'}
def pure(path):
    tree = ast.parse(path.read_text())
    imports = {a.name for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
    return imports <= {'hashlib', 'json', 're'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)) and not any(isinstance(n, ast.Call) and ((isinstance(n.func, ast.Name) and n.func.id in forbidden) or (isinstance(n.func, ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree))
for path in reviewers:
    check('accepted batch reviewer has no native dispatch or service channel ' + path, pure(root / path))
check('current388 reviewer has no filesystem clock network spawn service or native dispatch', pure(tool))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
