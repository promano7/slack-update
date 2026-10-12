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
step = 'phase-1-operational-joint-baseline-storage-finite-rights-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry403', 'baseline', 'review', 'sources', 'policy']]
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
check('whole authored404 entry baseline review sources independently bound', module['validate_fixtures']({'entry403': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual403 supplied receipt73PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all85 whole inputs and30 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('full original original baseline storage clauses and once-only rights requirements retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2154 accepted403 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
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
    ('selection invented',lambda c:c.update(selected_options=['test'])),
    ('approved migration invented',lambda c:c.update(approved_contract_migration={})),
    ('runtime opened',lambda c:c.update(runtime_authority=True)),
    ('native case invented',lambda c:c.update(native_cases_run=1)),
    ('normative original waived',lambda c:c.update(whole_original_requirements_remain_normative=False)),
    ('service barrier removed',lambda c:c['whole_original320_claim_and_launch'].pop('service_traps')),
    ('durable claim replaced with refund',lambda c:c['joint_proposed_statements'].update(service_claim_launch='Refund on lost ACK.')),
    ('one owned microstep omitted',lambda c:c['all9_owned_microstep_reconciliations'].pop()),
    ('one original microstep cut omitted',lambda c:c['all9_owned_microstep_reconciliations'][0]['whole_original_microstep_review']['declared_review_cut_questions'].pop()),
    ('one recovery branch omitted',lambda c:c['all18_original_recovery_branch_reconciliations'].pop()),
    ('whole branch condition shortened',lambda c:c['all18_original_recovery_branch_reconciliations'][0]['whole_original_branch'].update(required_independent_condition='short')),
    ('recoveryrevocation change hidden',lambda c:c['all18_original_recovery_branch_reconciliations'][3].update(candidate_specific_reconciliation='Original equivalence.')),
    ('backup absence proves unchanged',lambda c:c.update(missing_backup_proves_unchanged=True)),
    ('unknown owned means absenttarget',lambda c:c.update(unknown_owned_implies_target_absent=True)),
    ('ACK flush treateddurable',lambda c:c.update(ACK_hash_or_file_flush_is_durability_proof=True)),
    ('raw pkglist rebound',lambda c:c.update(logical_pkglist_equivalence_rebinds_raw_bytes=True)),
    ('unknown restore repeated',lambda c:c.update(unknown_action_can_repeat=True)),
    ('unknown spend refunded',lambda c:c.update(unknown_spend_can_refund=True)),
    ('unrelated unknown erases qualified facts',lambda c:c.update(captured_target_fact_erased_by_unrelated_unknown=True)),
    ('restore erases original failure',lambda c:c.update(restore_success_erases_original_failure=True)),
    ('native selector invented',lambda c:c.update(is_executable_recovery_selector=True)),
    ('baseline capturedactual',lambda c:c.update(actual_original_baseline={})),
    ('backup boundactual',lambda c:c.update(actual_protected_backups={})),
    ('ledger selectedactual',lambda c:c.update(actual_rights_ledger_or_action_spends={})),
    ('one phase vector omitted',lambda c:c['whole_original16_phase_observation_rows'].pop()),
    ('other platform support borrowed',lambda c:c['whole_original_platform_storage_readiness'][0].update(runtime_authority=True)),
    ('paper native observation invented',lambda c:c['authored_hypothetical_cases'][0].update(actual_native_evidence={})),
    ('joint question omitted',lambda c:c['remaining_joint_reviews'].pop()),
    ('semantic migration complete',lambda c:c.update(semantic_migration_complete=True)),
    ('new pause claimed',lambda c:c['boundaries'].update(strong_safe_pause=True)),
    ('automatic409 opened',lambda c:c.update(no_automatic409=False))]
for label, mutate in mutations:
    altered = copy.deepcopy(proposal)
    mutate(altered)
    check('reject ' + label + ' by semantic review', rejects(shape, altered))
altered_entry = copy.deepcopy(entry)
altered_entry['receipt']['text'] = altered_entry['receipt']['text'][:-1]
check('reject truncated actual403 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_statements']['once_only_recovery'] = 'Repeat uncertain restore.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
for case in proposal['authored_hypothetical_cases']:
    result=module['hypothetical_case'](case,policy)
    check('paper storage rights witness '+case['id'],result['new_operation_review_question']==case['expected_question'] and result['runtime_authority'] is False and result['native_proof'] is False and result['actual_native_fact_or_action'] is None and result['actual_closed'] is False)
case=proposal['authored_hypothetical_cases'][23];result=module['hypothetical_case'](case,policy)
check('qualified captured target fact retained with owned controller unknown',result['qualified_captured_target_fact']=='known-original' and result['owned_outcome_preserved']=='unknown' and result['controller_outcome_preserved']=='unknown')
case=proposal['authored_hypothetical_cases'][8];result=module['hypothetical_case'](case,policy)
check('unknown restore ACK never repeated even with qualified original target fact',result['new_operation_review_question']=='paper-deny-repeat-uncertain-restore' and result['qualified_captured_target_fact']=='known-original')
case=proposal['authored_hypothetical_cases'][21];result=module['hypothetical_case'](case,policy)
check('known mismatch and original failure survive claimed restore completion',result['known_mismatch_preserved'] is True and result['original_failure_preserved'] is True)
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['original_spent']=True
check('reject boolean original spend masquerading as integer',rejects(module['hypothetical_case'],case,policy))
case['original_spent']=1;case['hypothetical_only']=False
check('reject paper helper used as actual recovery selector',rejects(module['hypothetical_case'],case,policy))
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
