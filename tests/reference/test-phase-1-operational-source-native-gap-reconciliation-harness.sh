#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import hashlib
import json
import re
import runpy
import sys

root=Path(sys.argv[1]);name='phase-1-operational-source-native-gap-reconciliation';prior='phase-1-operational-native-implementation-prerequisites'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(name+'.py');m=runpy.run_path(str(tool));passes=0
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError,OSError):return True
    return False
def load(tail):return json.loads((fixture/(name+'-'+tail+'.json')).read_bytes())
policy=load('policy');confirmed=load('confirmed365');receipt=load('step365-user-acceptance');stored=load('reconciliation')
check('all1859 accepted365 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1859)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted365 bytes exact with additive CHANGELOG only',len(history)==1859)
check('external confirmed365 bytes exact',sha((fixture/(name+'-confirmed365.json')).read_bytes())==policy['expected_confirmation_sha256'])
check('complete365 receipt and report-based confirmation validate',m['validate_acceptance'](receipt,confirmed))
text=receipt['text'];raw=text.encode();message=policy['accepted_commit_message'];head='bede6fa (HEAD -> main, origin/main, origin/HEAD) '+message
check('all140 exact ordered365 labels and zero-failure summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered365_labels'] and text.count('Result: PASS (140 passes, 0 failures)')==1)
check('reported365 exact eight-file commit and seven created paths',text.count('[main bede6fa] '+message)==1 and text.count('8 files changed, 2762 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step365_created_paths'])
check('reported365 push clean status and matching heads',text.count('f8db9d6..bede6fa  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'))
check('receipt SHA size and original-capture limitation retained',sha(raw)==policy['accepted_receipt_sha256']==receipt['sha256'] and len(raw)==policy['accepted_receipt_size_bytes']==receipt['size_bytes'] and receipt['capture_basis']=='complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture' and receipt['normalization']=='none')
check('accepted365 is not a new pause or invented full commit',confirmed['commit_prefix']=='bede6fa' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
for field,value in [('strong_safe_pause',True),('commit_full','bede6fa'+'0'*33),('runtime_authority',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('native_cases_run',1),('native_proofs_added',1),('user_worktree_clean',False),('user_head_matches_origin',False),('phase1_matrix_complete',True),('kernel_package_edge_complete',True),('production_entry_closed',False),('phase2_open',True)]:
    bad=copy.deepcopy(confirmed);bad[field]=value;check('reject changed365 confirmation '+field,rejected(m['validate_acceptance'],receipt,bad))
for label,edit in [('truncated receipt',lambda x:x[:-1]),('same-length edited receipt',lambda x:x.replace('bede6fa','bede6fb',1)),('injected status output',lambda x:x.replace(head,' M README.md\n'+head,1))]:
    bad=copy.deepcopy(receipt);bad['text']=edit(text);check('reject '+label,rejected(m['validate_acceptance'],bad,confirmed))
bad=copy.deepcopy(receipt);bad['capture_basis']='original-terminal-byte-capture';check('reject invented original terminal capture',rejected(m['validate_acceptance'],bad,confirmed))
check('exact four review roots closed with historical generated role',m['SOURCE_BINDINGS']==policy['source_roots'] and all(not x['execution_authorized'] and x['actual_native_binding'] is None for x in m['SOURCE_BINDINGS']) and 'not-a-second-independent-worker' in m['SOURCE_BINDINGS'][3]['role'])
inputs={k:json.loads(history[path]) for k,path in policy['input_paths'].items()}
inputs['confirmations']={str(step):json.loads(history[path]) for step,path in policy['checkpoint_confirmation_paths'].items()};inputs['confirmations']['365']=confirmed
sources={x['path']:history[x['path']] for x in policy['source_roots']};readme=history['README.md']
for key,data in inputs.items():
    check('full frozen '+key+' canonical binding exact',m['canonical'](data)==policy['input_canonical_sha256'][key]==m['INPUT_HASHES'][key] and (key=='confirmations' or sha(history[policy['input_paths'][key]])==policy['input_file_sha256'][key]))
actual=m['reconcile'](sources,inputs,readme)
check('complete source native reconciliation reproduced',m['validate_reconciliation'](stored,sources,inputs,readme) and sha((fixture/(name+'-reconciliation.json')).read_bytes())==policy['expected_reconciliation_sha256'])
g=inputs['native_gap'];norm=g['full_normative_rows'];gaps=g['full_original_native_gap_rows348'];pr=inputs['prerequisites'];effects=inputs['effects'];deps=inputs['dependency'];rows=actual['gap_reconciliation_rows']
check('all16 complete original gap rows retained in canonical order',[x['id'] for x in rows]==policy['inherited_gap_ids'] and [x['full_original_gap_row348'] for x in rows]==gaps==actual['full_original_native_gap_rows348'] and len(rows)==16)
check('every prerequisite row linked by complete canonical SHA',all(x['prerequisite365_canonical_sha256']==m['canonical'](p) and x['implementation_requirements365']==p['implementation_review_required'] and x['platform_readiness365']==p['platform_readiness'] for x,p in zip(rows,pr['prerequisite_rows'])))
check('all source hazard and dependency family navigation retained exactly',all(x['source_hazard_ids364']==[h['id'] for h in effects['lifetime_hazards'] if x['id'] in h['original_native_gap_ids']] and x['dependency_family_ids363']==[f['id'] for f in deps['dependency_families'] if x['id'] in f['original_native_gap_ids']] for x in rows))
check('source navigation is non-exhaustive and discharges no native gap',all(x['source_links_are_non_exhaustive'] and not x['source_links_discharge_native_gap'] and not x['no_selected_source_link_means_absent'] and x['native_status']=='required-not-selected-refined-or-proven' and x['actual_native_evidence'] is None for x in rows))
check('issuer claim and revocation gaps retained even without source links',all(any(x['id']==key and not x['source_hazard_ids364'] and not x['source_links_discharge_native_gap'] for x in rows) for key in ['issuer-authentication-key-provenance','linearizable-durable-claim-and-quarantine','native-time-revocation-fence']))
proofs=norm['qualified_proof_reconciliation'];cases=norm['native_case_templates'];groups=g['full_original_evidence_group_rows335']
check('all46 full unproven proof rows retained',actual['full_qualified_proof_rows347']==proofs and len(proofs)==46 and all(p['status']=='required-not-proven' and p['actual_evidence'] is None and not p['private_PASS_is_native_proof'] for p in proofs))
check('all52 full unrun separate platform case rows retained',actual['full_native_case_rows347']==cases and len(cases)==52 and len({(c['platform'],c['case_id']) for c in cases})==52 and all(c['status']=='required-not-run' and c['actual_result'] is None and c['actual_fresh_test_authority'] is None for c in cases))
check('all12 full independent raw groups still uncaptured',actual['full_independent_raw_groups335']==groups and len(groups)==12 and all(x['status']=='required-native-evidence-not-captured' and x['actual_raw_capture'] is None for x in groups))
proof_edges={(p['qualified_id'],c['platform'],c['case_id']) for p in proofs for c in p['required_native_case_tuples']};case_edges={(p,c['platform'],c['case_id']) for c in cases for p in c['required_qualified_proofs']}
relations=actual['ordered_proof_case_relations'];actual_edges=[(x['qualified_proof_id'],x['platform'],x['case_id']) for x in relations]
check('all1072 proof case edges independently match both native directions',proof_edges==case_edges==set(actual_edges) and len(relations)==len(set(actual_edges))==policy['expected_proof_case_relations']==1072)
check('proof case relation ordering preserves original proof then original tuple order',actual_edges==[(p['qualified_id'],c['platform'],c['case_id']) for p in proofs for c in p['required_native_case_tuples']])
check('native relation labels remain unproven and unrun',all(x['proof_status']=='required-not-proven' and x['case_status']=='required-not-run' and not x['native_proof'] for x in relations))
check('all case evidence group references point to exact original groups',all(set(c['evidence_group_ids'])=={x['id'] for x in groups} for c in cases))
check('all8 original full contracts remain bound',actual['original_contract_bindings320_327']==norm['exact_contract_bindings'] and set(actual['original_contract_bindings320_327'])=={str(s) for s in range(320,328)} and actual['full_contracts_canonical_sha256']==m['canonical'](g['full_original_contracts320_327']))
check('all16 complete normative sections bound without count substitution',set(actual['full_normative_sections'])==set(norm) and len(norm)==16 and all(actual['full_normative_sections'][k]['canonical_sha256']==m['canonical'](v) and actual['full_normative_sections'][k]['representation']=='whole-section-bound-not-count-substitute' and actual['full_normative_sections'][k]['row_count']==(len(v) if isinstance(v,list) else None) for k,v in norm.items()))
expected_prefixes=['aedcbc3','9a9cd12','633b524','aff8592','c69533f','f8db9d6','bede6fa'];checkpoints=actual['accepted_checkpoints359_365']
check('all7 accepted checkpoint reports exact without invented full commits',[x['step'] for x in checkpoints]==list(range(359,366)) and [x['reported_commit_prefix'] for x in checkpoints]==expected_prefixes and all(x['commit_full'] is None and x['reported_clean_matching_heads'] and not x['new_strong_safe_pause'] and not x['runtime_authority'] and x['confirmation_canonical_sha256']==m['canonical'](inputs['confirmations'][str(x['step'])]) for x in checkpoints))
ledger=actual['source_review_ledger'];check('full five source review stages retained as repository progress',[x['stage'] for x in ledger]==list(range(361,366)) and all(not x['native_proof'] and x['full_input_canonical_sha256']==m['INPUT_HASHES'][x['full_input']] for x in ledger))
check('inventory context and dependency metrics keep exact source scope',ledger[0]['source_records']==15106 and ledger[1]['whole_spans']==17 and ledger[1]['selected_sites']==65 and ledger[2]['written_candidates']==51 and ledger[2]['literal_occurrences']==958 and ledger[2]['dependency_families']==12 and ledger[2]['missing_platform_inputs']==126)
check('effect and prerequisite records stay distinct missing native requirements',ledger[3]['effect_domains']==21 and ledger[3]['lifetime_hazards']==16 and ledger[3]['missing_platform_relations']==32 and ledger[3]['retained_lexical_channel_indices']==4660 and ledger[4]['prerequisite_rows']==16 and ledger[4]['missing_platform_readiness_slots']==32 and ledger[4]['supplemental_platform_slots']==2 and ledger[4]['pending_review_deliverables']==8)
check('supplemental cksum retained without historical register rewrite',actual['supplemental_external_inputs365']==pr['supplemental_external_inputs'] and len(actual['supplemental_external_inputs365'])==1 and actual['supplemental_external_inputs365'][0]['name_candidate']=='cksum' and not actual['supplemental_external_inputs365'][0]['historical_register363_modified'] and 'cksum' not in [x['name_candidate'] for x in deps['command_candidates']])
targets=actual['readme367_review_targets'];expected_lines=[10,636,1387,1399,1402,1430,1434,1909,2749]
check('nine exact README review targets retain historical and current distinctions',[x['anchor']['line_number'] for x in targets]==expected_lines and len(targets)==policy['expected_readme_targets']==9)
geometry=True
for target in targets:
    loc=target['anchor'];lines=readme.split(b'\n');content=lines[loc['line_number']-1]+b'\n';offset=sum(len(line)+1 for line in lines[:loc['line_number']-1]);geometry=geometry and loc['path']=='README.md' and sha(readme)==loc['source_sha256'] and sha(content)==loc['raw_line_sha256'] and loc['line_start_byte']==offset and loc['line_length_bytes']==len(content) and loc['full_line_text']==content.decode()
check('README target full-line geometry independently verified',geometry)
check('README untouched and no target checkbox or authority promoted',readme==(root/'README.md').read_bytes() and all(not x['readme_edited'] and not x['checkbox_promoted'] and not x['runtime_authority'] for x in targets) and not actual['coverage']['readme_reconciled'] and not actual['coverage']['README_is_operational_review_root'])
check('reference v1 schema and C gate reviews remain explicit',any(x['id']=='v1-schema-pending' and 'pending' in x['required367_review'] for x in targets) and any(x['id']=='reference-freeze-gates' and 'blocked' in x['required367_review'] for x in targets))
check('remaining finite roadmap exactly367 README then368 conditional pause',actual['remaining_roadmap']==inputs['plan']['roadmap'][8:] and [x['step'] for x in actual['remaining_roadmap']]==[367,368] and not any(x['runtime_authorized'] for x in actual['remaining_roadmap']))
for label,mutate in [
('omitted gap row',lambda x:x['gap_reconciliation_rows'].pop()),('reordered gap rows',lambda x:x['gap_reconciliation_rows'].reverse()),('native gap closed',lambda x:x['gap_reconciliation_rows'][0].__setitem__('native_status','closed')),('source link gap discharged',lambda x:x['gap_reconciliation_rows'][0].__setitem__('source_links_discharge_native_gap',True)),('empty source link treated absent',lambda x:x['gap_reconciliation_rows'][1].__setitem__('no_selected_source_link_means_absent',True)),('changed prerequisite binding',lambda x:x['gap_reconciliation_rows'][0].__setitem__('prerequisite365_canonical_sha256','0'*64)),('dropped implementation obligation',lambda x:x['gap_reconciliation_rows'][0]['implementation_requirements365'].pop()),('invented native evidence',lambda x:x['gap_reconciliation_rows'][0].__setitem__('actual_native_evidence',{})),('deleted hazard link',lambda x:x['gap_reconciliation_rows'][0]['source_hazard_ids364'].pop()),('deleted native proof',lambda x:x['full_qualified_proof_rows347'].pop()),('deleted native case',lambda x:x['full_native_case_rows347'].pop()),('deleted raw group',lambda x:x['full_independent_raw_groups335'].pop()),('omitted proof case relation',lambda x:x['ordered_proof_case_relations'].pop()),('reordered proof case relations',lambda x:x['ordered_proof_case_relations'].reverse()),('false native proof relation',lambda x:x['ordered_proof_case_relations'][0].__setitem__('native_proof',True)),('changed case platform',lambda x:x['ordered_proof_case_relations'][0].__setitem__('platform','shared-platform')),('deleted original contract',lambda x:x['original_contract_bindings320_327'].pop('320')),('deleted normative section',lambda x:x['full_normative_sections'].pop('owned_stage7_microsteps')),('changed full normative SHA',lambda x:x['full_normative_sections']['native_case_templates'].__setitem__('canonical_sha256','0'*64)),('invented accepted full commit',lambda x:x['accepted_checkpoints359_365'][0].__setitem__('commit_full','aedcbc3'+'0'*33)),('checkpoint promoted to pause',lambda x:x['accepted_checkpoints359_365'][0].__setitem__('new_strong_safe_pause',True)),('source progress native proof',lambda x:x['source_review_ledger'][0].__setitem__('native_proof',True)),('cksum dropped',lambda x:x['supplemental_external_inputs365'].clear()),('readme target omitted',lambda x:x['readme367_review_targets'].pop()),('readme byte anchor changed',lambda x:x['readme367_review_targets'][0]['anchor'].__setitem__('line_start_byte',1)),('premature README checkbox',lambda x:x['readme367_review_targets'][0].__setitem__('checkbox_promoted',True)),('missing final roadmap stage',lambda x:x['remaining_roadmap'].pop()),('invented native runner',lambda x:x.__setitem__('runner',{}))]:
    bad=copy.deepcopy(stored);mutate(bad);check('reject '+label,rejected(m['validate_reconciliation'],bad,sources,inputs,readme))
for field in ['source_links_exhaustive','full_native_graph_resolved','native_case_executed','native_proof_added','actual_component_selected','readme_reconciled','current_step_is_strong_pause','source_review_closes_phase1_matrix','source_review_selects_native_successor','source_missing_means_absent','historical_authority_reused','README_is_operational_review_root']:
    bad=copy.deepcopy(stored);bad['coverage'][field]=True;check('reject false reconciliation coverage '+field,rejected(m['validate_reconciliation'],bad,sources,inputs,readme))
for field,value in [('native_graph_complete',True),('execution_authorized',True),('runtime_authority',True),('actual_successor_selected',True),('actual_live_bindings',{}),('actual_host_state','absent'),('actual_global_host_closure',True),('native_cases_run',1),('readme_reconciliation_step',None),('strong_safe_pause',True)]:
    bad=copy.deepcopy(stored);bad['boundaries'][field]=value;check('reject false boundary '+field,rejected(m['validate_reconciliation'],bad,sources,inputs,readme))
for key in inputs:
    bad=copy.deepcopy(inputs)
    if key=='confirmations':bad[key]['365']['strong_safe_pause']=True
    else:bad[key]['invented_native_authority']=True
    check('reject changed frozen '+key,rejected(m['reconcile'],sources,bad,readme))
bad=dict(inputs);bad.pop('prerequisites');check('reject incomplete frozen input set',rejected(m['reconcile'],sources,bad,readme))
bad=dict(inputs);bad['extra']={};check('reject extra frozen input set',rejected(m['reconcile'],sources,bad,readme))
first=policy['source_roots'][0]['path'];bad=dict(sources);bad[first]=b'X'+bad[first][1:];check('reject source byte drift',rejected(m['reconcile'],bad,inputs,readme))
bad=dict(sources);bad['README.md']=readme;check('reject README as extra operational root',rejected(m['reconcile'],bad,inputs,readme))
check('reject README drift before reconciliation target selection',rejected(m['reconcile'],sources,inputs,b'X'+readme[1:]))
views=m['source_lines'](sources);check('reject bool and out of range source anchor integers',all(rejected(m['anchor'],views,i,1) for i in [True,-1,4]) and all(rejected(m['anchor'],views,0,line) for line in [True,0,6638]))
mutated=m['reconcile'](sources,inputs,readme);mutated['boundaries']['runtime_authority']=True;mutated['review_sources'][0]['execution_authorized']=True;mutated['full_original_native_gap_rows348'][0]['status']='waived';mutated['full_native_case_rows347'][0]['status']='passed';mutated['original_contract_bindings320_327'].clear();mutated['frozen_inputs']['effects']='changed'
check('returned report detached from constants and full normative caller data',not m['BOUNDARIES']['runtime_authority'] and not m['SOURCE_BINDINGS'][0]['execution_authorized'] and gaps[0]['status']=='required-not-selected-refined-or-proven' and len(norm['exact_contract_bindings'])==8 and m['reconcile'](sources,inputs,readme)==stored)
ast_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(ast_tree) if isinstance(node,ast.Import) for alias in node.names}
check('pure reconciliation validator imports only hashlib json and re',imports=={'hashlib','json','re'})
check('validator has no filesystem lookup execution decode or spawn entry',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in {'open','exec','eval','compile','__import__'}) or (isinstance(node.func,ast.Attribute) and node.func.attr in {'system','popen','run','which','b64decode','execv','spawnv','read_bytes','read_text','stat','resolve'})) for node in ast.walk(ast_tree)))
old_coverage=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-readonly-source-inventory-control-coverage.json'])
check('historical361 modeled socket limitation preserved',not old_coverage['native_proof'] and any('socket-type-stat-metadata-modeled' in x.get('method','') for x in old_coverage['controls']))
check('original scoped pause358 retained and366 never claims host closure',actual['boundaries']['last_confirmed_strong_safe_pause_step']==358 and not actual['boundaries']['strong_safe_pause'] and actual['boundaries']['actual_host_state']=='unobserved-not-claimed-absent' and actual['boundaries']['actual_live_bindings'] is None and not actual['boundaries']['actual_global_host_closure'])
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
