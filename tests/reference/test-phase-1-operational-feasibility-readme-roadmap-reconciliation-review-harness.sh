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

root = Path(sys.argv[1])
step = 'phase-1-operational-feasibility-readme-roadmap-reconciliation-review'
prefix = root / 'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):
    return json.loads((prefix / (step + '-' + suffix + '.json')).read_bytes())
p = load('policy'); c = load('confirmed386'); r = load('step386-user-acceptance')
d = load('dossier'); s = load('sources')
tool = root / 'tools/reference' / (step + '.py')
m = runpy.run_path(str(tool)); passes = 0
def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)
def rejected(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, TypeError):
        return True
    return False
blobs = {}
for rel in p['baseline_sha256']:
    path = root / rel
    if not path.is_file() or path.is_symlink() or path.resolve() != path.absolute():
        raise SystemExit('FAIL: unsafe386 artifact ' + rel)
    blobs[rel] = path.read_bytes()
additions = {rel: blobs[rel][:-p['accepted_document_size_bytes'][rel]] for rel in p['addition_sha256']}
inputs = {key: (root / path).read_bytes() for key, path in p['whole_input_paths'].items()}
f = json.loads(inputs['freeze378'])
sources = {row['path']: (root / row['path']).read_bytes() for row in f['review_sources']}
check('authored387 policy independently frozen', m['validate_policy'](p))
check('whole2017 predecessor preserved with additive README and CHANGELOG', m['validate_baseline'](blobs, additions, p))
check('complete386 supplied Markdown exact516 ordered labels commit push reported clean heads', m['validate_acceptance'](c, r, p))
check('whole37 original and accepted380 through386 inputs plus four inert roots', m['validate_inputs'](inputs, sources, p))
check('whole387 roadmap reconciliation and closed native gates', m['validate_dossier'](d, s, inputs, additions['README.md'], p))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    actual = {x.decode() for x in raw.split(b'\0') if x}
else:
    actual = {str(path.relative_to(root)) for path in root.rglob('*') if path.is_file() and '.git' not in path.relative_to(root).parts}
check('exact eight new Git visible artifacts ignored outputs retained', actual == set(p['baseline_sha256']) | set(p['new_paths']))
for key in inputs:
    bad = dict(inputs); bad[key] += b'\n'
    check('reject whole normative input drift ' + key, rejected(m['validate_inputs'], bad, sources, p))
for path in sources:
    bad = dict(sources); bad[path] += b'\n'
    check('reject inert source drift ' + path, rejected(m['validate_inputs'], inputs, bad, p))
for key, value in [('commit_full', 'invented'), ('strong_safe_pause', True), ('native_cases_run', 1), ('native_proofs_added', 1),
                   ('runtime_authority', True), ('actual_host_state', 'absent'), ('actual_live_bindings', {}),
                   ('actual_global_host_closure', True), ('user_worktree_clean', False), ('user_head_matches_origin', False),
                   ('capture_basis', 'independent-terminal-byte-capture')]:
    bad = copy.deepcopy(c); bad[key] = value
    check('reject386 acceptance promotion ' + key, rejected(m['validate_acceptance'], bad, r, p))
for label, change in [
    ('truncated Markdown receipt', lambda t: t[:-1]),
    ('same size commit edit', lambda t: t.replace('094af08', '094af09', 1)),
    ('dirty final status injected', lambda t: t.replace('main -> main 094af08', 'main -> main  M README.md 094af08', 1)),
    ('PASS order changed', lambda t: t.replace(p['expected_ordered_PASS_labels386'][0], p['expected_ordered_PASS_labels386'][1], 1)),
    ('Markdown receipt normalized', lambda t: t.replace('\\.', '.')),
]:
    bad = copy.deepcopy(r); bad['text'] = change(r['text'])
    check('reject ' + label, rejected(m['validate_acceptance'], c, bad, p))
for key, value in d['boundaries'].items():
    bad = copy.deepcopy(d)
    bad['boundaries'][key] = not value if type(value) is bool else (value + 1 if type(value) is int else {})
    check('reject changed native or project boundary ' + key, rejected(m['validate_dossier'], bad, s, inputs, additions['README.md'], p))
for key, value in d['reconciliation_limits'].items():
    bad = copy.deepcopy(d)
    bad['reconciliation_limits'][key] = not value if type(value) is bool else 'invented'
    check('reject roadmap promotion ' + key, rejected(m['validate_dossier'], bad, s, inputs, additions['README.md'], p))
for index, row in enumerate(d['whole_accepted386_integrated_dossier']['candidates']):
    bad = copy.deepcopy(d)
    bad['whole_accepted386_integrated_dossier']['candidates'][index]['native_blocker_resolved'] = True
    check('reject native resolution of original candidate ' + row['id'], rejected(m['validate_dossier'], bad, s, inputs, additions['README.md'], p))
for section, flag in [('cross_conflict_review', 'native_blocker_resolved'), ('full_blocker_review', 'native_gap_closed')]:
    for index, row in enumerate(d['whole_accepted386_integrated_dossier'][section]):
        bad = copy.deepcopy(d)
        bad['whole_accepted386_integrated_dossier'][section][index][flag] = True
        check('reject original blocker promotion ' + section + ' ' + str(index), rejected(m['validate_dossier'], bad, s, inputs, additions['README.md'], p))
for label, change in [
    ('whole stage12 shortened', lambda x: x['whole_accepted386_integrated_dossier']['original316_whole_stage12'].update(operation='subset')),
    ('future test prerequisites shortened', lambda x: x['whole_accepted386_integrated_dossier']['whole377_future_test_entry_prerequisites'].pop()),
    ('operational prerequisites shortened', lambda x: x['whole_accepted386_integrated_dossier']['whole377_future_operational_readiness_prerequisites'].pop()),
    ('counts rewritten', lambda x: x['bounded_candidate_verdict_counts'].update(unresolved=0)),
    ('historical matrix shortened', lambda x: x['historical_pending_families'].pop()),
    ('native cases closed', lambda x: x['pending_native_scope'].update(native_cases_unrun=0)),
    ('pause claimed at387', lambda x: x.update(current_step_strong_safe_pause=True)),
    ('automatic389 opened', lambda x: x.update(automatic389=True)),
    ('pause condition omitted', lambda x: x['whole_original_condition_ids'].pop()),
    ('original final receipt waived', lambda x: x['whole379_pause_policy'].update(final_receipt_required=False)),
    ('original roadmap grant changed', lambda x: x['whole379_step387_roadmap_entry'].update(runtime_authorized=True)),
    ('boolean schema', lambda x: x.update(schema=True)),
]:
    bad = copy.deepcopy(d); change(bad)
    check('reject ' + label, rejected(m['validate_dossier'], bad, s, inputs, additions['README.md'], p))
for rel in ['README.md', 'CHANGELOG.md']:
    bad = dict(blobs); bad[rel] += b'\n'
    check('reject historical suffix drift ' + rel, rejected(m['validate_baseline'], bad, additions, p))
    bad_add = dict(additions); bad_add[rel] += b'\n'
    check('reject authored prefix drift ' + rel, rejected(m['validate_baseline'], blobs, bad_add, p))
for label, old, new in [
    ('current pause misrepresented', b'No new pause', b'New pause'),
    ('native test grant invented', b'separate fresh explicit bounded native-test grant', b'automatic native-test grant'),
    ('candidate readiness invented', b'zero established compatible-unproven', b'45 proven compatible'),
    ('current host absence invented', b'unobserved, not', b'absent, not'),
    ('52 case scope replaced', b'52 native cases unrun', b'52 native cases passed'),
]:
    assert old in additions['README.md'], label
    bad = additions['README.md'].replace(old, new, 1)
    check('reject README ' + label, rejected(m['validate_dossier'], d, s, inputs, bad, p))
bad = copy.deepcopy(p); bad['baseline_sha256']['README.md'] = '0' * 64
check('reject reanchored policy', rejected(m['validate_policy'], bad))
bad_s = copy.deepcopy(s); bad_s[0]['retrieval'] = 'independent native evidence'
check('reject supplied register promoted to native evidence', rejected(m['validate_dossier'], d, bad_s, inputs, additions['README.md'], p))
report = m['review'](d, s, c, r, inputs, sources, additions['README.md'], p)
check('report retains complete386 dossier and37 input bindings', report['dossier']['whole_accepted386_integrated_dossier'] == d['whole_accepted386_integrated_dossier'] and report['whole_input_bindings'] == p['whole_input_sha256'])
check('report leaves native entry and pause closed', report['native_entry_blocked'] and not report['strong_safe_pause'] and not report['automatic389'])
report['dossier']['current_step_strong_safe_pause'] = True
check('detached report cannot promote caller or later review', not d['current_step_strong_safe_pause'] and not m['review'](d, s, c, r, inputs, sources, additions['README.md'], p)['dossier']['current_step_strong_safe_pause'])
tree = ast.parse(tool.read_text())
imports = {a.name for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib', 'json', 're'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
forbidden = {'open', 'exec', 'eval', 'compile', '__import__', 'system', 'popen', 'run', 'read_bytes', 'read_text', 'decode', 'socket', 'urlopen'}
check('reviewer has no filesystem clock network spawn service or native dispatch', not any(isinstance(n, ast.Call) and ((isinstance(n.func, ast.Name) and n.func.id in forbidden) or (isinstance(n.func, ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
