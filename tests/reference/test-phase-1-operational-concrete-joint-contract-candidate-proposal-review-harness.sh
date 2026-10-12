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
step = 'phase-1-operational-concrete-joint-contract-candidate-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, candidate, sources, policy = [load(s) for s in ['entry399', 'baseline', 'candidate', 'sources', 'policy']]
module = runpy.run_path(str(root / 'tools/reference' / (step + '.py')))
passes = 0
def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)
def rejects(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, IndexError, TypeError):
        return True
    return False
inputs = {k: safe(v['path']) for k, v in sources['inputs'].items()}
roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
source_blobs = {r['path']: (safe(r['path'])[len(policy['prefixes']['README.md'].encode()):] if r['path'] == 'README.md' else safe(r['path'])) for r in roots}
check('whole authored400 entry baseline candidate sources independently bound', module['validate_fixtures']({'entry399': entry, 'baseline': baseline, 'candidate': candidate, 'sources': sources}, policy))
check('complete actual399 supplied receipt43PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all73 whole inputs and26 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('all nine source options exact current clauses and original396 impact bindings', module['validate_candidate_shape'](candidate, inputs, sources, policy))
check('all2122 accepted399 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    inventory = {p.decode() for p in raw.split(b'\0') if p}
else:
    inventory = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG scope', inventory == set(baseline) | set(policy['new_paths']))
def shape(c):
    return module['validate_candidate_shape'](c, inputs, sources, policy)
mutations = [
    ('boolean schema', lambda c: c.update(schema=True)),
    ('candidate selected by user', lambda c: c.update(user_selected=True)),
    ('selected options invented', lambda c: c.update(selected_options=['test'])),
    ('joint specification approved', lambda c: c.update(approved_joint_specification={})),
    ('contract migration approved', lambda c: c.update(approved_contract_migration={})),
    ('semantic replacements complete', lambda c: c.update(semantic_migration_complete=True)),
    ('impact independently accepted', lambda c: c.update(independent_impact_review_accepted=True)),
    ('native compatibility proved', lambda c: c.update(joint_native_compatibility_proven=True)),
    ('native protocol complete', lambda c: c.update(concrete_protocol_completeness_claimed=True)),
    ('native authority opened', lambda c: c.update(runtime_authority=True)),
    ('native case invented', lambda c: c.update(native_cases_run=1)),
    ('native graph invented', lambda c: c.update(actual_joint_native_graph={})),
    ('whole original contract inactive', lambda c: c.update(whole_original_requirements_remain_normative=False)),
    ('original option silently dropped', lambda c: c['draft_option_references'].pop()),
    ('option source index rebound', lambda c: c['draft_option_references'][0].update(source_option_index=0)),
    ('option approved via reference', lambda c: c['draft_option_references'][0].update(approved_migration={})),
    ('impact row binding substituted', lambda c: c['draft_option_references'][0].update(whole_396_impact_review_canonical_sha256='0'*64)),
    ('exact amendment wording shortened', lambda c: c['exact_adopted_inactive_option_wording'][0]['proposed_clause_text'].clear()),
    ('guarantee loss hidden', lambda c: c['complete_source_guarantee_loss_register'][0]['guarantees_lost_or_changed'].pop()),
    ('empty retention loss list removed', lambda c: c['complete_source_guarantee_loss_register'].pop(2)),
    ('trusted privileged workload exemption', lambda c: c['new_joint_wording'][0].update(text='All root writers trusted.')),
    ('worker control channel silently borrowed', lambda c: c['new_joint_wording'][1].update(text='Worker may call the service.')),
    ('clock or right renewed', lambda c: c['new_joint_wording'][2].update(text='Renew the deadline on guardian restart.')),
    ('unknown backup authorizes restore', lambda c: c['new_joint_wording'][3].update(text='Restore when backup state unknown.')),
    ('terminal observer exemption', lambda c: c['new_joint_wording'][4].update(text='Ignore observer effects.')),
    ('three-call whole-entry replacement', lambda c: c['new_joint_wording'][5].update(text='Only three backend calls required.')),
    ('same-brief joint wording missing', lambda c: c['new_joint_wording'].pop(2)),
    ('whole original decision shortened', lambda c: c['eight_pending_decisions'][0]['whole_original_decision']['whole_original_conflict'].update(unresolved_requirement='short')),
    ('finite recovery decision loses storage family', lambda c: c['eight_pending_decisions'][5]['draft_option_ids'].pop()),
    ('original conflict declared resolved', lambda c: c['eight_pending_decisions'][0].update(original_conflict_resolved=True)),
    ('joint dimension omitted', lambda c: c['nine_unresolved_joint_reviews'].pop()),
    ('joint unknown declared safe', lambda c: c['nine_unresolved_joint_reviews'][0].update(actual_joint_resolution='safe')),
    ('specific unresolved question hidden', lambda c: c['nine_unresolved_joint_reviews'][0].update(candidate_specific_question='resolved')),
    ('role labels promoted to independence', lambda c: c.update(role_labels_are_independence_or_native_graph_proof=True)),
    ('role selected as actual mechanism', lambda c: c['proposed_roles'][0].update(implementation_selected=True)),
    ('15.0 support invented', lambda c: c['platform_rows'][0].update(support=True)),
    ('current platform evidence borrowed', lambda c: c['platform_rows'][1].update(native_evidence={})),
    ('retention comparator selected', lambda c: c['retention_comparator'].update(selected=True)),
    ('deferral opens native effects', lambda c: c['deferral_comparator'].update(runtime_authority=True)),
    ('retention family omitted', lambda c: c['retention_comparator']['option_references'].pop()),
    ('migration coverage reduced', lambda c: c['migration_coverage'].update(original_members=1)),
    ('migration table made approval', lambda c: c['migration_coverage'].update(map_coverage_is_semantic_approval=True)),
    ('known incompatibility erased', lambda c: c['known_draft_incompatibilities'].pop()),
    ('new pause declared', lambda c: c['boundaries'].update(strong_safe_pause=True)),
    ('automatic409 allowed', lambda c: c.update(no_automatic409=False)),
    ('advance past401 without accepted400', lambda c: c.update(next_preparable_step_after_complete400_acceptance=402))]
for label, mutate in mutations:
    altered = copy.deepcopy(candidate)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual399 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_joint_wording'][1]['text'] = 'Worker may call the service.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, candidate, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
