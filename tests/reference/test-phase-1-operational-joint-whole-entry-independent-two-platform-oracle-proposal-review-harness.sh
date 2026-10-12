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
step = 'phase-1-operational-joint-whole-entry-independent-two-platform-oracle-proposal-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe supplied repository path ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, proposal, sources, policy = [load(s) for s in ['entry405', 'baseline', 'review', 'sources', 'policy']]
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
check('whole authored406 entry baseline review sources independently bound', module['validate_fixtures']({'entry405': entry, 'baseline': baseline, 'review': proposal, 'sources': sources}, policy))
check('complete actual405 supplied receipt81PASS exact commit push clean heads', module['validate_entry'](entry, policy))
check('all91 whole inputs and32 roots retained;inert roots never executed', module['validate_sources'](inputs, source_blobs, sources, policy))
check('whole original entry source and independent full two-platform oracle requirements retained', module['validate_review_shape'](proposal, inputs, sources, policy))
check('all2170 accepted405 historical paths unchanged except exact prefixes', module['validate_repository']({p: safe(p) for p in baseline}, baseline, policy))
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
    ('original whole entry clause shortened',lambda c:c['whole_normative_sections']['original325']['graph_contract'].pop('entry')),
    ('one source surface omitted',lambda c:c['all8_source_surface_reconciliations'].pop()),
    ('source consumed protection removed',lambda c:c['joint_proposed_statements'].update(checked_to_consumed_source='Check SHA once.')),
    ('nested argv scope shortened',lambda c:c['whole_normative_sections']['original325']['nested_argv_contract'].pop()),
    ('raw status distinction shortened',lambda c:c['whole_normative_sections']['original325']['selector_contract'].pop('statuses')),
    ('one qualified proof omitted',lambda c:c['whole_normative_sections']['design375']['full_original_qualified_proofs347'].pop()),
    ('one proof statement shortened',lambda c:c['whole_normative_sections']['design375']['full_original_qualified_proofs347'][0]['inherited_proof']['source_proof'].update(evidence='short')),
    ('one full native case omitted',lambda c:c['whole_normative_sections']['design375']['full_original_native_cases347'].pop()),
    ('one raw group omitted',lambda c:c['whole_normative_sections']['design375']['full_original_raw_groups335'].pop()),
    ('one ordered relation omitted',lambda c:c['whole_normative_sections']['design375']['full_ordered_required_proof_case_relations'].pop()),
    ('one native case joint row omitted',lambda c:c['all52_original_case_joint_reconciliations'].pop()),
    ('case source pointer rebound',lambda c:c['all52_original_case_joint_reconciliations'][0].update(json_pointer='/case_evidence_review/1')),
    ('case platform borrowed',lambda c:c['all52_original_case_joint_reconciliations'][0].update(platform='Slackware-current')),
    ('case original evidence group omitted',lambda c:c['whole_normative_sections']['design375']['case_evidence_review'][0]['all_original_evidence_group_ids'].pop()),
    ('one comparison requirement omitted',lambda c:c['whole_normative_sections']['design375']['comparison_requirement_review'].pop()),
    ('one native cut dimension omitted',lambda c:c['whole_normative_sections']['design376']['native_cut_resolution_dimensions'].pop()),
    ('one observation family omitted',lambda c:c['whole_normative_sections']['design376']['native_observation_family_review'].pop()),
    ('whole expectation contract truncated',lambda c:c['whole_normative_sections']['independent_expectation351'].pop('review_requirements')),
    ('one oracle role omitted',lambda c:c['all6_oracle_role_reconciliations'].pop()),
    ('one effective fault control omitted',lambda c:c['all6_fault_control_reconciliations'].pop()),
    ('verifier forbidden to author expectations',lambda c:c.update(verifier_may_author_independent_expectations=False)),
    ('whole entry replaced by three calls',lambda c:c.update(whole_entry_replaced_by_three_calls=True)),
    ('lexical census or hash proves consumed graph',lambda c:c.update(lexical_census_or_hash_proves_consumed_graph=True)),
    ('subject self expectation allowed',lambda c:c.update(subject_self_expectation_allowed=True)),
    ('shared selector cleanup logic is sole oracle',lambda c:c.update(shared_selector_cleanup_logic_is_sole_oracle=True)),
    ('four distinct people required',lambda c:c.update(four_distinct_people_required=True)),
    ('role or hash proves independence',lambda c:c.update(role_or_hash_proves_independence=True)),
    ('requested fault is effective cut',lambda c:c.update(requested_fault_is_effective_cut=True)),
    ('macro cuts are actual native sites',lambda c:c.update(macro_cuts_are_actual_native_sites=True)),
    ('macro schedules are exhaustive',lambda c:c.update(macro_schedules_are_exhaustive=True)),
    ('nominal types are actual ABI',lambda c:c.update(nominal_types_are_actual_ABI=True)),
    ('unknown means empty or no effect',lambda c:c.update(unknown_means_empty_or_no_effect=True)),
    ('pending erases known mismatch',lambda c:c.update(pending_erases_known_mismatch=True)),
    ('sort dedup or sample vectors allowed',lambda c:c.update(sort_dedup_or_sample_vectors_allowed=True)),
    ('cross platform evidence transfer allowed',lambda c:c.update(cross_platform_evidence_transfer_allowed=True)),
    ('observer injector effects exempt',lambda c:c.update(observer_injector_effects_exempt=True)),
    ('private351 literals are native expectations',lambda c:c.update(private351_literals_are_native_expectations=True)),
    ('matching paper vectors are native conformance',lambda c:c.update(matching_paper_vectors_are_native_conformance=True)),
    ('actual backend invented',lambda c:c.update(actual_backend_or_selector={})),
    ('actual full native expectations invented',lambda c:c.update(actual_full_raw_expected_or_observed_artifacts={})),
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
check('reject truncated actual405 transcript', rejects(module['validate_entry'], altered_entry, policy))
altered_inputs = dict(inputs)
altered_inputs['original324'] += b' '
check('reject original source byte drift', rejects(module['validate_sources'], altered_inputs, source_blobs, sources, policy))
altered_policy = copy.deepcopy(policy)
altered_policy['expected_statements']['independent_expectations_and_capture'] = 'Subject is sole oracle.'
check('reject coordinated authored policy substitution', rejects(module['validate_policy'], altered_policy))
check('review output retains inactive draft and closed native rights', module['review'](entry, proposal, inputs, source_blobs, sources, policy) == policy['expected_review_result'])
tree = ast.parse(safe('tools/reference/' + step + '.py'))
imports = {a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n, ast.Import) for a in n.names}
check('pure reviewer imports only hashlib json re', imports == {'hashlib','json','re'} and not any(isinstance(n, ast.ImportFrom) for n in ast.walk(tree)))
for rel in ['docs/reference/' + step + '.md', 'tests/reference/test-' + step + '-harness.sh']:
    check('exact delivered artifact ' + rel, module['sha'](safe(rel)) == policy['artifact_sha256'][rel])
for case in proposal['authored_hypothetical_cases']:
    result=module['hypothetical_case'](case,policy)
    check('paper whole raw oracle witness '+case['id'],result['oracle_review_question']==case['expected_question'] and result['runtime_authority'] is False and result['native_proof'] is False and result['native_conformance'] is False and result['actual_native_fact_or_action'] is None and result['actual_closed'] is False)
case=proposal['authored_hypothetical_cases'][5];result=module['hypothetical_case'](case,policy)
check('known raw mismatch retained with separate unknown effect vector',result['paper_qualified_mismatch_preserved'] and result['pending_raw_fields']==['upgrade_effects'] and 'raw_statuses' in result['declared_disagreement_fields'])
case=proposal['authored_hypothetical_cases'][22];result=module['hypothetical_case'](case,policy)
check('previous qualified mismatch survives later capture unknown',result['paper_qualified_mismatch_preserved'] and result['oracle_review_question']=='paper-deny-known-mismatch')
case=proposal['authored_hypothetical_cases'][23];result=module['hypothetical_case'](case,policy)
check('contained original failure remains failure and not native success',result['original_failure_preserved'] and result['native_conformance'] is False)
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['observed']['raw_statuses'][0]=True
check('reject boolean raw status masquerading as integer',rejects(module['hypothetical_case'],case,policy))
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['observed']['raw_stream_hex'][0]='0'
check('reject truncated synthetic raw byte stream',rejects(module['hypothetical_case'],case,policy))
case=copy.deepcopy(proposal['authored_hypothetical_cases'][0]);case['hypothetical_only']=False
check('reject paper comparator promoted to native conformance',rejects(module['hypothetical_case'],case,policy))
case=copy.deepcopy(proposal['authored_hypothetical_cases'][5]);case['independent_raw_capture_known']=False
result=module['hypothetical_case'](case,policy)
check('unqualified declaration disagreement not independent mismatch',result['paper_qualified_mismatch_preserved'] is False and result['declared_disagreement_fields']==['raw_statuses'] and result['oracle_review_question']=='paper-pending-full-raw-data')
case=proposal['authored_hypothetical_cases'][26];result=module['hypothetical_case'](case,policy)
check('unknown original failure stays null and pending not false success',result['original_forward_failure_fact'] is None and 'original_forward_failed' in result['pending_qualification_fields'] and result['oracle_review_question']=='paper-pending-original-outcome-state')
case=proposal['authored_hypothetical_cases'][27];result=module['hypothetical_case'](case,policy)
check('unknown prior mismatch stays null and pending',result['prior_known_mismatch_fact'] is None and 'previous_known_mismatch' in result['pending_qualification_fields'] and result['oracle_review_question']=='paper-pending-original-outcome-state')
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
