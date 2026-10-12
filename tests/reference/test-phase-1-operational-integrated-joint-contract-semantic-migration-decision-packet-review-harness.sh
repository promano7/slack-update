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
step = 'phase-1-operational-integrated-joint-contract-semantic-migration-decision-packet-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry406', 'baseline', 'review', 'sources', 'policy']]
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
check('whole authored407 entry baseline review sources independently bound', module['validate_fixtures']({'entry406': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual406 supplied receipt102PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all94 whole inputs and33 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('complete inactive joint scope guarantee loss and whole-member acceptance criteria retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2178 accepted406 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    inventory = {p.decode() for p in raw.split(b'\0') if p}
else:
    inventory = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG scope', inventory == set(baseline) | set(policy['new_paths']))
def shape(c):
    return module['validate_review_shape'](c, inputs, sources, policy)
mutations = [
    ('boolean schema',lambda c:c.update(schema=True)),
    ('user selection invented',lambda c:c.update(selected_options=['test'])),
    ('migration approval invented',lambda c:c.update(approved_contract_migration={})),
    ('joint specification approval invented',lambda c:c.update(approved_joint_specification={})),
    ('runtime opened',lambda c:c.update(runtime_authority=True)),
    ('native case invented',lambda c:c.update(native_cases_run=1)),
    ('original norms waived',lambda c:c.update(whole_original_requirements_remain_normative=False)),
    ('whole option wording shortened',lambda c:c['whole400_four_initial_amendment_wordings'][0]['proposed_clause_text'].pop('trusted_host_assumption')),
    ('source guarantee loss hidden',lambda c:c['complete_guarantee_loss_and_incompatibility_register']['whole400_all9_source_guarantee_loss_register'].pop()),
    ('recovery continuation additional loss hidden',lambda c:c['complete_guarantee_loss_and_incompatibility_register']['whole402_additional_forward_recovery_publication_losses'].pop(1)),
    ('one exact replacement omitted',lambda c:c['exact14_inactive_clause_replacements'].pop()),
    ('recovery replacement changed',lambda c:c['exact14_inactive_clause_replacements'][7].update(complete_proposed_value='Unchanged original recovery.')),
    ('whole current replacement clause truncated',lambda c:c['exact14_inactive_clause_replacements'][0].update(whole_current_value='short')),
    ('terminal assumption hidden',lambda c:c['complete4_additional_trust_and_terminal_assumptions'].pop('terminal_acceptance_cut')),
    ('patch view approved',lambda c:c['whole8_current_and_inactive_patch_contract_views'][3].update(approved_or_activated=True)),
    ('old unpatched fence reused',lambda c:c['whole8_current_and_inactive_patch_contract_views'][3]['inactive_exact_clause_patch_view']['fence_contract'].update(rule='old')),
    ('whole decision original truncated',lambda c:c['all8_whole_decision_proposals'][0]['whole_original397_decision']['whole_original_conflict'].update(unresolved_requirement='short')),
    ('author option promoted to user selection',lambda c:c['all8_whole_decision_proposals'][0].update(explicit_user_selection=['declared-operation-admission-cuts'])),
    ('native grant inferred from packet',lambda c:c['all8_whole_decision_proposals'][0].update(fresh_native_test_grant={})),
    ('one whole joint dimension omitted',lambda c:c['all9_whole_joint_dimension_answers'].pop()),
    ('specific joint answer shortened',lambda c:c['all9_whole_joint_dimension_answers'][5].update(complete_inactive_candidate_joint_answer='Producer proves final receipt.')),
    ('one original pair omitted',lambda c:c['whole_original397_all325_pair_questions'].pop()),
    ('candidate same-brief pair omitted',lambda c:c['all36_author_candidate_pair_questions'].pop()),
    ('global rule source or oracle shortened',lambda c:c['semantic_register']['rules']['S406'].update(guarantee='Use three calls.')),
    ('host excluded tamper detection invented',lambda c:c['semantic_register']['rules']['T401'].update(negative='Hidden trusted tampering always detected.')),
    ('recovery every-effect guarantee silently reused',lambda c:c['semantic_register']['rules']['R402'].update(guarantee='Every old recovery guarantee unchanged.')),
    ('clock deadline renewed',lambda c:c['semantic_register']['rules']['C403'].update(negative='Renew clock on loss.')),
    ('old stage12 conformance silently reused',lambda c:c['semantic_register']['rules']['E405'].update(guarantee='Producer subset equals original stage12.')),
    ('one specific proof criterion omitted',lambda c:c['semantic_register']['proofs'].pop('323/external-live-revocation-fence')),
    ('one case-specific criterion omitted',lambda c:c['semantic_register']['cases'].pop('record-last-receipt')),
    ('test grant before safe review',lambda c:c['semantic_register'].update(entry_before_effects='Run native faults to learn safety.')),
    ('one whole category omitted',lambda c:c['all15_category1286_whole_member_acceptance_matrix'].pop()),
    ('one complete source member omitted',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][6]['members'].pop()),
    ('whole original proof shortened',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][3]['members'][0]['whole_original_member']['inherited_proof']['source_proof'].update(evidence='short')),
    ('whole member source pointer rebound',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][3]['members'][0].update(source_json_pointer='/full_qualified_proof_rows347/1')),
    ('proof-specific expectation removed',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][3]['members'][0]['complete_candidate_acceptance_criterion'].update(complete_specific_candidate_evidence='generic')),
    ('full negative expectation removed',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][3]['members'][0]['complete_candidate_acceptance_criterion']['local_complete_guarantee_positive_negative_expectations'][0].pop('negative')),
    ('local focus waives dependency rules',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][6]['members'][0]['complete_candidate_acceptance_criterion'].update(local_focus_does_not_waive_other_global_rules=False)),
    ('ordered relation case moved to other platform',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][6]['members'][0]['whole_original_member'].update(platform='Slackware-current')),
    ('ordered relation exact case evidence omitted',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][6]['members'][0]['complete_candidate_acceptance_criterion'].update(complete_specific_candidate_evidence='Proof alone sufficient.')),
    ('native test entry gate shortened',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][8]['members'][0]['complete_candidate_acceptance_criterion'].update(complete_specific_candidate_evidence='PASS supplies native grant.')),
    ('readiness still demands original stage equivalence',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][9]['members'][2]['complete_candidate_acceptance_criterion'].update(complete_specific_candidate_evidence='All old guarantees unchanged.')),
    ('historical family silently closed',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][10]['members'][0].update(actual_native_status_promoted=True)),
    ('member independently accepted by author',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][0]['members'][0]['complete_candidate_acceptance_criterion'].update(independently_accepted=True)),
    ('member current norm silently inactive',lambda c:c['all15_category1286_whole_member_acceptance_matrix'][0]['members'][0].update(current_original_normative=False)),
    ('independent impact accepted by packet',lambda c:c.update(independent_impact_review_accepted=True)),
    ('semantic migration independently complete',lambda c:c.update(semantic_migration_complete=True)),
    ('actual native graph invented',lambda c:c.update(actual_joint_native_graph={})),
    ('unknown host made absent',lambda c:c.update(actual_host_state='absent')),
    ('global host closure invented',lambda c:c.update(actual_global_host_closure=True)),
    ('new pause claimed',lambda c:c.update(current_strong_safe_pause=True)),
    ('automatic409 opened',lambda c:c.update(no_automatic409=False))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual406 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['semantic_definitions']['rules']['S406']['guarantee'] = 'Subject is sole oracle.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
parsed=module['prepare_parsed'](inputs)
semantics=module['derive_semantics'](parsed,policy['semantic_definitions'])
for category in proposal['all15_category1286_whole_member_acceptance_matrix']:
    source=next(c for c in parsed['oracle_brief396']['impact_categories'] if c['id']==category['category_id'])
    check('complete whole member criteria category '+category['category_id'],category['ordered_member_ids']==source['ordered_member_ids'] and len(category['members'])==len(source['ordered_member_ids']))
check('ALL1286 whole ordered original members preserved',sum(len(c['members']) for c in proposal['all15_category1286_whole_member_acceptance_matrix'])==1286)
changes=module['derive_changes'](parsed)
check('ALL14 exact source-bound whole current and proposed clause values',changes==proposal['exact14_inactive_clause_replacements'])
proofs=proposal['semantic_register']['proofs'];cases=proposal['semantic_register']['cases']
check('all46 proof-specific and26 case-type criteria retained',len(proofs)==46 and len(cases)==26 and all(s['complete_specific_candidate_evidence'] for s in list(proofs.values())+list(cases.values())))
relations=proposal['all15_category1286_whole_member_acceptance_matrix'][6]['members']
check('all1072 relations include exact proof AND own-platform case meaning',len(relations)==1072 and all('\nAND this exact case on '+r['whole_original_member']['platform']+':' in r['complete_candidate_acceptance_criterion']['complete_specific_candidate_evidence'] for r in relations))
check('recovery revocation changed expectation retained alongside original branch',any(r['json_pointer']=='/recovery_contract/revocation' for r in changes) and 'explicitly weakens original recovery' in proposal['semantic_register']['rules']['R402']['guarantee'])
check('hidden infrastructure and clock tampering never claimed detected', 'not promised detectable' in proposal['semantic_register']['rules']['T401']['negative'] and 'not guaranteed detected' in proposal['semantic_register']['rules']['C403']['guarantee'])
check('native entry safe review precedes separate fresh explicit grant','THEN separate fresh explicit bounded' in proposal['semantic_register']['entry_before_effects'] and 'BEFORE effects' in proposal['semantic_register']['entry_before_effects'])
check('eight actual user decisions and native grants unanswered',all(r['explicit_user_selection'] is None and r['explicit_migration_approval'] is None and r['fresh_native_test_grant'] is None and r['runtime_authority'] is False for r in proposal['all8_whole_decision_proposals']))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
