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
step = 'phase-1-operational-joint-writer-source-trust-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry400', 'baseline', 'review', 'sources', 'policy']]
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
check('whole authored401 entry baseline review sources independently bound', module['validate_fixtures']({'entry400': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual400 supplied receipt59PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all76 whole inputs and27 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('full original writer source trust clauses and lifetime requirements retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2130 accepted400 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    inventory = {p.decode() for p in raw.split(b'\0') if p}
else:
    inventory = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG scope', inventory == set(baseline) | set(policy['new_paths']))
def shape(c):
    return module['validate_review_shape'](c, inputs, sources, policy)
mutations = [
    ('boolean schema', lambda c: c.update(schema=True)),
    ('user selection invented', lambda c: c.update(selected_options=['test'])),
    ('contract approval invented', lambda c: c.update(approved_contract_migration={})),
    ('native authority opened', lambda c: c.update(runtime_authority=True)),
    ('native case invented', lambda c: c.update(native_cases_run=1)),
    ('original contract waived', lambda c: c.update(whole_original_requirements_remain_normative=False)),
    ('whole guard clause shortened', lambda c: c['whole_original_guard_contract'].pop('coverage')),
    ('shared trust losses hidden', lambda c: c['complete400_writer_clock_guarantee_losses'][0]['guarantees_lost_or_changed'].pop()),
    ('administrator workload exempted', lambda c: c.update(ordinary_privileged_workload_exempt=True)),
    ('observer injector exempted', lambda c: c.update(observer_or_injector_exempt=True)),
    ('UID or role label proves trust', lambda c: c.update(infrastructure_role_name_or_uid_proves_trust=True)),
    ('excluded guarantee activated', lambda c: c.update(deliberate_trusted_infrastructure_exclusion_is_active=True)),
    ('hidden infrastructure tampering detection claimed', lambda c: c.update(hidden_infrastructure_tampering_detection_proven=True)),
    ('unknown actor trusted', lambda c: c['proposed_trusted_infrastructure_roles'][0].update(selected_as_trusted=True)),
    ('source consumed identity invented', lambda c: c.update(actual_source_objects={})),
    ('actual native control invented', lambda c: c.update(actual_enforcement_policy={})),
    ('deadline guard renewed', lambda c: c.update(guard_reacquisition_or_deadline_renewal_allowed=True)),
    ('ordinary faults exempted', lambda c: c['joint_proposed_statements'].update(trust_assumption='Ignore ordinary infrastructure faults.')),
    ('source aliases omitted', lambda c: c['joint_proposed_statements'].update(source_consumption='Hashes suffice.')),
    ('first write before traps permitted', lambda c: c['joint_proposed_statements'].update(guard_lifetime='Traps may follow writes.')),
    ('one domain omitted', lambda c: c['seven_original_domain_reviews'].pop()),
    ('foreign class question omitted', lambda c: c['all_domain_writer_class_questions'].pop()),
    ('lifetime hazard omitted', lambda c: c['whole_lifetime_hazard_reviews'].pop()),
    ('lifetime whole row pointer shifted', lambda c: c['whole_lifetime_hazard_reviews'][0]['whole_original_reference'].update(json_pointer='/lifetime_hazards/1')),
    ('lifetime native gap resolved', lambda c: c['whole_lifetime_hazard_reviews'][0].update(native_gap_resolved=True)),
    ('source effect domain omitted', lambda c: c['whole_effect_domain_reviews'].pop()),
    ('source review treated exhaustive', lambda c: c.update(original_source_lifetime_review_is_exhaustive_native_inventory=True)),
    ('other platform native support borrowed', lambda c: c['whole_original_platform_writer_domains'][7].update(continuously_excluded=True)),
    ('paper case becomes native observation', lambda c: c['authored_hypothetical_classification_cases'][0].update(actual_native_observation={})),
    ('semantic migration complete claimed', lambda c: c.update(exact_semantic_migration_complete=True)),
    ('remaining joint blocker hidden', lambda c: c['remaining_joint_reviews'].pop()),
    ('new pause claimed', lambda c: c['boundaries'].update(strong_safe_pause=True)),
    ('automatic409 opened', lambda c: c.update(no_automatic409=False))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual400 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_statements']['actor_and_action_scope'] = 'All UID0 trusted.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
for case in proposal['authored_hypothetical_classification_cases']:
    result = module['classify_hypothetical'](case, policy)
    check('hypothetical actor/action witness ' + case['id'], result == {'inactive_proposal_disposition':case['expected_inactive_proposal_disposition'], 'hypothetical_trust_condition_status':case['expected_hypothetical_trust_condition_status'], 'known_mismatch_cannot_be_erased_by_proposed_exclusion':True, 'original_all_writer_requirement_unchanged':True, 'actual_actor_or_support':None, 'runtime_authority':False, 'native_proof':False})
bad_case = copy.deepcopy(proposal['authored_hypothetical_classification_cases'][0])
bad_case['enumerated_for_assumption'] = 1
check('reject integer membership masquerading as trusted bool', rejects(module['classify_hypothetical'],bad_case,policy))
bad_case['enumerated_for_assumption'] = True
bad_case['hypothetical_only'] = False
check('reject proposed classifier used as actual policy', rejects(module['classify_hypothetical'],bad_case,policy))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
