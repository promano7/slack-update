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
step = 'phase-1-operational-contract-decision-resume-planning-review'
prefix = root / 'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):
    return json.loads((prefix / (step + '-' + suffix + '.json')).read_bytes())

entry, baseline, plan, sources, policy = [load(s) for s in ['entry388', 'baseline', 'plan', 'sources', 'policy']]
tool = root / 'tools/reference' / (step + '.py')
m = runpy.run_path(str(tool))
passes = 0
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

def safe_bytes(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise SystemExit('FAIL: unsafe repository artifact ' + rel)
    return p.read_bytes()

inputs = {key: safe_bytes(row['path']) for key, row in sources['inputs'].items()}
roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
source_blobs = {row['path']: safe_bytes(row['path']) for row in roots}
blobs = {path: safe_bytes(path) for path in baseline}
addition = blobs['CHANGELOG.md'][:-policy['accepted_changelog_size_bytes']]
check('authored389 policy independently frozen', m['validate_policy'](policy))
check('whole accepted entry baseline plan and source fixtures exact', m['validate_fixtures'](entry, baseline, plan, sources, policy))
check('complete unchanged388 return and all nine WHOLE original confirmed conditions', m['validate_entry'](entry, inputs, policy))
check('all42 normative inputs four inert ten reviewer and README roots unchanged', m['validate_inputs'](inputs, source_blobs, sources, policy))
check('all2034 accepted388 repository bytes exact except additive CHANGELOG', m['validate_baseline'](blobs, baseline, addition, policy))
check('finite389-398 proposal plan retains all eight conflicts and closed native boundaries', m['validate_plan_shape'](plan, inputs, sources))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    actual = {x.decode() for x in raw.split(b'\0') if x}
else:
    actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight new Git-visible artifacts and no unrelated commit scope', actual == set(baseline) | set(policy['new_paths']))

# Exercise semantic rules directly, independently of whole-fixture equality.
mutations = [
    ('boolean schema', lambda p: p.update(schema=True)),
    ('shortened original conflict', lambda p: p['whole_original_conflicts'][0].pop('unresolved_requirement')),
    ('original conflict resolved', lambda p: p['whole_original_conflicts'][0].update(native_blocker_resolved=True)),
    ('original contract waiver', lambda p: p.update(whole_original_requirements_remain_normative=False)),
    ('candidate verdict promotion', lambda p: p['current_bounded_verdict_counts'].update(unresolved=0)),
    ('truncated roadmap', lambda p: p['roadmap'].pop()),
    ('reordered roadmap', lambda p: p['roadmap'].reverse()),
    ('successor before acceptance', lambda p: p['roadmap'][1].update(acceptance_predecessor_required=388)),
    ('native authority in roadmap', lambda p: p['roadmap'][1].update(native_authority=True)),
    ('foreign primary conflict', lambda p: p['roadmap'][1]['primary_conflict_ids'].append('foreign')),
    ('duplicate primary conflict', lambda p: p['roadmap'][1]['primary_conflict_ids'].append(p['roadmap'][1]['primary_conflict_ids'][0])),
    ('missing writer brief coverage', lambda p: p['roadmap'][1].update(primary_conflict_ids=[])),
    ('integration omits one original conflict', lambda p: p['roadmap'][8]['primary_conflict_ids'].pop()),
    ('empty concrete product', lambda p: p['roadmap'][1].update(required_result='')),
    ('source scope reduction', lambda p: p['whole_input_references'].pop('design377')),
    ('false resolved user decision', lambda p: p['unresolved_user_decisions'].pop()),
    ('invented current decision packet', lambda p: p.update(actual_decision_packet={})),
    ('author-selected option', lambda p: p.update(selected_options={'choice': 'amendment'})),
    ('implied approved migration', lambda p: p.update(approved_contract_migration={})),
    ('invented native evidence', lambda p: p.update(native_evidence={})),
    ('invented full commit', lambda p: p.update(full_commit_id='d31ba23' + '0' * 33)),
    ('retention option omitted', lambda p: p['proposal_rules']['allowed_dispositions'].remove('retain-original')),
    ('deferral option omitted', lambda p: p['proposal_rules']['allowed_dispositions'].remove('defer')),
    ('platform borrowed', lambda p: p['proposal_rules'].update(platforms=['Slackware-current'])),
    ('unknown platform promoted', lambda p: p['proposal_rules'].update(unknown_platform_support_value=True)),
    ('final close moved earlier', lambda p: p['pause_policy'].update(conditional_close_step=390)),
    ('original pause condition omitted', lambda p: p['pause_policy']['original_condition_ids'].pop()),
    ('automatic399 authorized', lambda p: p['pause_policy'].update(after_confirmed398_next_authorized_stage=399)),
]
for label, mutate in mutations:
    bad = copy.deepcopy(plan)
    mutate(bad)
    check('semantic rejection: ' + label, rejected(m['validate_plan_shape'], bad, inputs, sources))
for key in plan['boundaries']:
    bad = copy.deepcopy(plan)
    v = bad['boundaries'][key]
    bad['boundaries'][key] = not v if type(v) is bool else (v + 1 if type(v) is int else {})
    check('semantic rejection of boundary ' + key, rejected(m['validate_plan_shape'], bad, inputs, sources))
for key in ['contract_amendment_authorized', 'component_selection_authorized', 'native_test_or_runtime_authorized']:
    bad = copy.deepcopy(plan); bad['authorization_basis'][key] = True
    check('semantic rejection of implied permission ' + key, rejected(m['validate_plan_shape'], bad, inputs, sources))
for key, value in plan['proposal_rules'].items():
    if type(value) is bool:
        bad = copy.deepcopy(plan); bad['proposal_rules'][key] = not value
        check('semantic rejection of changed proposal rule ' + key, rejected(m['validate_plan_shape'], bad, inputs, sources))
for key, value in plan['pause_policy'].items():
    if type(value) is bool:
        bad = copy.deepcopy(plan); bad['pause_policy'][key] = not value
        check('semantic rejection of changed pause requirement ' + key, rejected(m['validate_plan_shape'], bad, inputs, sources))
for key in inputs:
    bad = dict(inputs); bad[key] += b'\n'
    check('reject original input drift ' + key, rejected(m['validate_inputs'], bad, source_blobs, sources, policy))
for row in roots:
    bad = dict(source_blobs); bad[row['path']] += b'\n'
    check('reject source root drift ' + row['path'], rejected(m['validate_inputs'], inputs, bad, sources, policy))
for suffix, value in [('entry388', entry), ('baseline', baseline), ('plan', plan), ('sources', sources)]:
    bad = copy.deepcopy(value); bad['invented'] = True
    args = [entry, baseline, plan, sources, policy]
    args[['entry388', 'baseline', 'plan', 'sources'].index(suffix)] = bad
    check('reject whole fixture substitution ' + suffix, rejected(m['validate_fixtures'], *args))
bad = copy.deepcopy(entry)
bad['confirmed_pause']['confirmed_conditions'][0]['full_prepared_condition388'] = {'id': 'summary'}
check('reject original full pause reduced to summary', rejected(m['validate_entry'], bad, inputs, policy))
bad = copy.deepcopy(entry); bad['receipt']['text'] = bad['receipt']['text'][:-1]
check('reject truncated predecessor return', rejected(m['validate_entry'], bad, inputs, policy))
bad = copy.deepcopy(entry); bad['confirmation']['commit_full'] = 'invented'
check('reject full Git identity invented from prefix', rejected(m['validate_entry'], bad, inputs, policy))
bad = dict(blobs); bad['CHANGELOG.md'] += b'\n'
check('reject historical CHANGELOG rewrite', rejected(m['validate_baseline'], bad, baseline, addition, policy))
bad = dict(blobs); bad['README.md'] += b'\n'
check('reject historical README rewrite', rejected(m['validate_baseline'], bad, baseline, addition, policy))
bad = dict(blobs); bad.pop('README.md')
check('reject missing predecessor repository artifact', rejected(m['validate_baseline'], bad, baseline, addition, policy))
bad = copy.deepcopy(policy); bad['accepted_head_prefix'] = 'invented'
check('reject reanchored authored policy', rejected(m['validate_policy'], bad))
report = m['review'](entry, baseline, plan, sources, inputs, source_blobs, policy)
check('report keeps proposed changes inactive and last confirmed pause388', report['last_confirmed_repository_pause'] == 388 and report['strong_safe_pause'] is False and report['approved_contract_migration'] is None)
check('report waits for actual389 acceptance before390 and stops after398', report['after_complete_current_user_acceptance_next_preparable_step'] == 390 and report['next_authorized_stage_after398'] is None)
report['plan']['whole_original_conflicts'].clear()
check('detached report cannot modify original obligations', len(plan['whole_original_conflicts']) == 8)
for path in [row['path'] for row in sources['reviewer_roots']] + ['tools/reference/' + step + '.py']:
    tree = ast.parse(safe_bytes(path))
    imports = {alias.name.split('.')[0] for node in ast.walk(tree) if isinstance(node, ast.Import) for alias in node.names}
    forbidden = {'open', 'exec', 'eval', 'compile', '__import__', 'getattr', 'globals', 'locals', 'input', 'breakpoint'}
    calls = {node.func.id for node in ast.walk(tree) if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)}
    check('pure supplied-data reviewer no native dispatch ' + path,
          imports <= {'hashlib', 'json', 're'} and not any(isinstance(node, ast.ImportFrom) for node in ast.walk(tree)) and not (calls & forbidden))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
