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
step = 'phase-1-operational-joint-contract-proposal-freeze-and-safe-pause-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry407', 'baseline', 'freeze', 'sources', 'policy']]
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
check('whole authored408 entry baseline review sources independently bound', module['validate_fixtures']({'entry407': entry, 'baseline': baseline, 'freeze': proposal, 'sources': sources}, policy))
check('complete actual407 supplied receipt88PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all106 whole inputs and34 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('whole inactive manuscript receipts and all nine original conditional pause requirements retained', module['validate_review_shape'](proposal, entry, inputs, sources, policy))
check('all2186 accepted407 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
if (root / '.git').exists():
    raw = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], capture_output=True, check=True).stdout
    inventory = {p.decode() for p in raw.split(b'\0') if p}
else:
    inventory = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG scope', inventory == set(baseline) | set(policy['new_paths']))
def shape(c):
    return module['validate_review_shape'](c, entry, inputs, sources, policy)
mutations = [
    ('boolean schema',lambda c:c.update(schema=True)),
    ('user option selected by freeze',lambda c:c.update(selected_options=['test'])),
    ('migration approved by freeze',lambda c:c.update(approved_contract_migration={})),
    ('specification approved by freeze',lambda c:c.update(approved_joint_specification={})),
    ('runtime authority opened',lambda c:c.update(runtime_authority=True)),
    ('native case invented',lambda c:c.update(native_cases_run=1)),
    ('current original norms waived',lambda c:c.update(whole_original_requirements_remain_normative=False)),
    ('conditional eligibility self-confirms pause',lambda c:c.update(actual_strong_safe_pause_confirmed=True)),
    ('private PASS made actual confirmation',lambda c:c.update(private_eligibility_is_actual_confirmation=True)),
    ('all nine externally confirmed before final return',lambda c:c.update(all_nine_current408_conditions_externally_confirmed=True)),
    ('current408 user receipt invented',lambda c:c.update(current408_actual_final_user_receipt={})),
    ('current408 commit invented',lambda c:c.update(current408_user_commit_prefix='invented')),
    ('current408 clean tree invented',lambda c:c.update(current408_user_worktree_clean=True)),
    ('current408 matching heads invented',lambda c:c.update(current408_user_head_matches_origin=True)),
    ('historical confirmation expanded to new scope',lambda c:c['whole_historical398_external_entry']['confirmation'].update(scope='repository-joint-contract-proposal399-408-only')),
    ('historical whole external condition truncated',lambda c:c['whole_historical398_external_entry']['external_conditions']['conditions'][0]['whole_prepared398_condition'].pop('full_original_prepared_condition388')),
    ('one whole current pause condition omitted',lambda c:c['conditions'].pop()),
    ('whole nested original pause condition truncated',lambda c:c['conditions'][0]['whole_original_prepared398_condition'].pop('full_original_prepared_condition388')),
    ('current pause scope widened',lambda c:c['conditions'][0].update(current_scope='global-host-closure')),
    ('current wrapper confirmation invented',lambda c:c['conditions'][0].update(current408_actual_user_confirmation={})),
    ('unknown native evidence invented in condition',lambda c:c['conditions'][3].update(actual_native_evidence={})),
    ('unknown host made absent',lambda c:c.update(actual_host_state='absent')),
    ('global host closure invented',lambda c:c.update(actual_global_host_closure=True)),
    ('machine action required from freeze',lambda c:c.update(machine_action_required=True)),
    ('controller cleanup claimed by freeze',lambda c:c.update(controller_action_required=True)),
    ('old live binding reused',lambda c:c.update(historical_binding_or_authority_reuse_allowed=True)),
    ('later current refresh invalidates repo pause',lambda c:c.update(later_current_refresh_invalidates_repository_only_pause=True)),
    ('future unused rights reopened',lambda c:c.update(next_authorized_stage_after408=409)),
    ('automatic409 allowed',lambda c:c.update(no_automatic409=False)),
    ('external all-nine requirement removed',lambda c:c['after_final_acceptance'].update(all_nine_whole_original_conditions_required=False)),
    ('final actual receipt not required',lambda c:c['after_final_acceptance'].update(final_actual_receipt_required=False)),
    ('STOP after final acceptance removed',lambda c:c['after_final_acceptance'].update(stop_after_final_acceptance=False)),
    ('new request requirement removed',lambda c:c['after_final_acceptance'].update(future_batch_requires_new_user_request=False)),
    ('whole input freeze shortened',lambda c:c['frozen_inputs'].pop('packet407')),
    ('inert native source removed',lambda c:c['frozen_source_roots'].pop(0)),
    ('one accepted checkpoint omitted',lambda c:c['accepted_checkpoint_chain399_407'].pop(0)),
    ('accepted checkpoint reordered',lambda c:c['accepted_checkpoint_chain399_407'].reverse()),
    ('whole prior supplied receipt truncated',lambda c:c['accepted_checkpoint_chain399_407'][0]['whole_actual_entry']['receipt'].update(text='short')),
    ('full prior Git ID invented',lambda c:c['accepted_checkpoint_chain399_407'][0].update(full_Git_ID_known=True)),
    ('intermediate receipt made new strong pause',lambda c:c['accepted_checkpoint_chain399_407'][0].update(repository_checkpoint_is_new_strong_pause=True)),
    ('whole semantic packet truncated',lambda c:c['whole_accepted407_packet']['all15_category1286_whole_member_acceptance_matrix'][6]['members'].pop()),
    ('source guarantee loss omitted',lambda c:c['whole_accepted407_packet']['complete_guarantee_loss_and_incompatibility_register']['whole402_additional_forward_recovery_publication_losses'].pop(1)),
    ('exact inactive amendment shortened',lambda c:c['whole_accepted407_packet']['exact14_inactive_clause_replacements'].pop()),
    ('whole decision obligation shortened',lambda c:c['whole_accepted407_packet']['all8_whole_decision_proposals'][0]['whole_original397_decision']['whole_original_conflict'].update(unresolved_requirement='short')),
    ('old stage12 equivalence invented',lambda c:c['whole_accepted407_packet'].update(old_stage12_claimed_equivalent_to_producer_subset=True)),
    ('native support invented',lambda c:c['whole_accepted407_packet'].update(actual_two_platform_run_bindings={})),
    ('independent impact promoted by freeze',lambda c:c.update(independent_impact_review_accepted=True)),
    ('native semantic migration complete claimed',lambda c:c.update(semantic_migration_complete=True)),
    ('finite roadmap shortened',lambda c:c['whole_399_roadmap'].pop()),
    ('last confirmed pause made current',lambda c:c.update(last_confirmed_strong_safe_pause_step=408))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual407 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_conditions'][0]['repository_status'] = 'confirmed-now'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
check('ALL9 complete supplied399-407 receipts bind actual checkpoint acceptance',module['validate_checkpoint_chain'](proposal['accepted_checkpoint_chain399_407'],entry,inputs,sources,policy))
for row in proposal['accepted_checkpoint_chain399_407']:
    check('whole accepted checkpoint receipt step'+str(row['step']),row['whole_actual_entry']['confirmation']['step']==row['step'] and row['repository_checkpoint_is_new_strong_pause'] is False)
for condition in proposal['conditions']:
    check('WHOLE conditional pause requirement '+condition['id'],condition['whole_original_prepared398_condition']['id']==condition['id'] and condition['current408_actual_user_confirmation'] is None and condition['actual_global_host_closure'] is False and condition['actual_native_evidence'] is None)
# Inspect all in-scope candidate sources without executing them.
for number in range(399,408):
    path=policy['scope_reviewer_paths'][str(number)];tree=ast.parse(safe(path))
    names={a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
    forbidden={'open','exec','eval','__import__','input'}
    calls={n.func.id for n in ast.walk(tree) if isinstance(n,ast.Call) and isinstance(n.func,ast.Name)}
    check('in-scope pure data reviewer'+str(number)+' byte-bound never dispatched',names=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)) and not forbidden.intersection(calls) and all(isinstance(n,(ast.Import,ast.FunctionDef,ast.Assign,ast.Expr)) for n in tree.body))
check('WHOLE407 full1286 criteria and1072 ordered relations frozen',module['validate_whole_packet407'](proposal['whole_accepted407_packet'],inputs,sources))
check('original398 external pause remains historical scope only',proposal['whole_historical398_external_entry']['confirmation']['strong_safe_pause'] is True and proposal['whole_historical398_external_entry']['confirmation']['scope']=='repository-contract-decision-proposals389-398-only' and proposal['actual_strong_safe_pause_confirmed'] is False)
check('final receipt and external all-nine confirmation still required',proposal['after_final_acceptance']['external_confirmation_only'] is True and proposal['after_final_acceptance']['all_nine_whole_original_conditions_required'] is True and proposal['after_final_acceptance']['final_actual_receipt_required'] is True)
check('after confirmed408 STOP and new request required',proposal['after_final_acceptance']['stop_after_final_acceptance'] is True and proposal['after_final_acceptance']['future_batch_requires_new_user_request'] is True and proposal['next_authorized_stage_after408'] is None and proposal['no_automatic409'] is True)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
