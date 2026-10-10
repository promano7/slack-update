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

root=Path(sys.argv[1]);name='phase-1-operational-native-implementation-prerequisites';prior='phase-1-operational-effect-lifetime-review'
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
policy=load('policy');confirmed=load('confirmed364');receipt=load('step364-user-acceptance');stored=load('prerequisites')
check('all1852 accepted364 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1852)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted364 bytes exact with additive CHANGELOG only',len(history)==1852)
check('external confirmed364 bytes exact',sha((fixture/(name+'-confirmed364.json')).read_bytes())==policy['expected_confirmation_sha256'])
check('complete364 receipt and report-based confirmation validate',m['validate_acceptance'](receipt,confirmed))
text=receipt['text'];raw=text.encode();message=policy['accepted_commit_message'];head='f8db9d6 (HEAD -> main, origin/main, origin/HEAD) '+message
check('all127 exact ordered364 labels and zero-failure summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered364_labels'] and text.count('Result: PASS (127 passes, 0 failures)')==1)
check('reported364 exact eight-file commit and seven created paths',text.count('[main f8db9d6] '+message)==1 and text.count('8 files changed, 2515 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step364_created_paths'])
check('reported364 push clean status and matching heads',text.count('c69533f..f8db9d6  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'))
check('receipt SHA size and original-capture limitation retained',sha(raw)==policy['accepted_receipt_sha256']==receipt['sha256'] and len(raw)==policy['accepted_receipt_size_bytes']==receipt['size_bytes'] and receipt['capture_basis']=='complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture' and receipt['normalization']=='none')
check('accepted364 is not a new pause or invented full commit',confirmed['commit_prefix']=='f8db9d6' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
for field,value in [('strong_safe_pause',True),('commit_full','f8db9d6'+'0'*33),('runtime_authority',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('native_cases_run',1),('native_proofs_added',1),('user_worktree_clean',False),('user_head_matches_origin',False),('phase1_matrix_complete',True),('kernel_package_edge_complete',True),('production_entry_closed',False),('phase2_open',True)]:
    bad=copy.deepcopy(confirmed);bad[field]=value;check('reject changed364 confirmation '+field,rejected(m['validate_acceptance'],receipt,bad))
for label,edit in [('truncated receipt',lambda x:x[:-1]),('same-length edited receipt',lambda x:x.replace('f8db9d6','f8db9d7',1)),('injected status output',lambda x:x.replace(head,' M README.md\n'+head,1))]:
    bad=copy.deepcopy(receipt);bad['text']=edit(text);check('reject '+label,rejected(m['validate_acceptance'],bad,confirmed))
bad=copy.deepcopy(receipt);bad['capture_basis']='original-terminal-byte-capture';check('reject invented original terminal capture',rejected(m['validate_acceptance'],bad,confirmed))
check('exact four review roots retain closed distinct historical roles',m['SOURCE_BINDINGS']==policy['source_roots'] and all(not x['execution_authorized'] and x['actual_native_binding'] is None for x in m['SOURCE_BINDINGS']) and 'not-a-second-independent-worker' in m['SOURCE_BINDINGS'][3]['role'])
inputs={k:json.loads(history[path]) for k,path in policy['input_paths'].items()};sources={x['path']:history[x['path']] for x in policy['source_roots']}
for key,data in inputs.items():
    check('full frozen '+key+' file and canonical SHA exact',sha(history[policy['input_paths'][key]])==policy['input_file_sha256'][key] and m['canonical'](data)==policy['input_canonical_sha256'][key]==m['INPUT_HASHES'][key])
actual=m['prerequisites'](sources,inputs)
check('complete native prerequisites reproduced',m['validate_prerequisites'](stored,sources,inputs) and sha((fixture/(name+'-prerequisites.json')).read_bytes())==policy['expected_prerequisites_sha256'])
expected_ids=['actual-successor-entry-and-transitive-graph','issuer-authentication-key-provenance','linearizable-durable-claim-and-quarantine','durable-launch-spend-and-supervision','offline-bootstrap-and-FD-namespace-containment','native-time-revocation-fence','native-writer-object-alias-and-lifetime-exclusion','fresh-original-baseline-and-approved-deltas','owned-backup-binding-and-child-recovery-primitives','versioned-real-backend-and-full-selector','package-hooks-source-archive-and-helper-consumption','bounded-clock-budget-and-same-attempt-recovery','target-closure-before-release','independent-publication-last-receipt-durability-and-origin','syscall-crash-concurrency-model-refinement','independent-two-platform-oracle-and-fault-observations']
rows=actual['prerequisite_rows'];gap_data=inputs['native_gap'];gaps=gap_data['full_original_native_gap_rows348'];effects=inputs['effects'];deps=inputs['dependency']
check('all16 normative gap IDs exact and ordered',[x['id'] for x in rows]==expected_ids==policy['inherited_gap_ids'] and len(set(expected_ids))==16)
check('each full original gap row and requirement preserved',[x['full_original_gap_row348'] for x in rows]==gaps and all(x['original_refinement_requirement']==g['refinement_requirement'] for x,g in zip(rows,gaps)))
check('all source lifetime findings linked by exact original gap identity',all(x['source_findings364']==[h for h in effects['lifetime_hazards'] if x['id'] in h['original_native_gap_ids']] for x in rows))
check('no selected source relation never means native gap absent',all(x['source_relation_status']=='no-selected-source-refinement-of-this-native-gap-not-absence' for x in rows if not x['source_findings364']) and all(not x['gap_discharged'] and x['actual_selected_component'] is None and x['actual_native_event_refinement'] is None for x in rows))
check('all16 rows have concrete implementation and future evidence questions',all(len(x['implementation_review_required'])==3 and len(x['future_native_fault_evidence_questions'])==1 and x['status']=='implementation-and-independent-native-evidence-required' for x in rows))
evidence_ids={x['id'] for x in gap_data['full_original_evidence_group_rows335']}
check('evidence navigation links valid and explicitly non-exhaustive',all(set(x['related_evidence_group_ids_non_exhaustive'])<=evidence_ids and len(x['related_evidence_group_ids_non_exhaustive'])>=3 for x in rows) and not actual['coverage']['fault_questions_are_complete_native_schedules'])
slots=[s for x in rows for s in x['platform_readiness']]
check('all32 distinct two-platform gap readiness slots retained',len(slots)==32 and len({s['id'] for s in slots})==32 and all([s['platform'] for s in x['platform_readiness']]==['Slackware-15.0','Slackware-current'] for x in rows))
nullable=['actual_implementation','actual_component_bytes','actual_primitive','actual_platform_version','actual_boot_id','actual_original_attempt','actual_fresh_test_authority','actual_independent_collector','actual_independent_verifier','actual_expected_vector','actual_raw_capture','actual_native_result']
check('all native implementation authority identity and evidence fields remain null',all(all(s[k] is None for k in nullable) and not s['native_proof'] and not s['execution_authorized'] and s['status']=='blocked-native-design-binding-and-evidence-required' for s in slots))
expected_deliverables=['successor-source-and-effect-design','issuer-admission-and-launch-design','native-platform-primitives-design','baseline-owned-recovery-design','closure-and-publication-design','independent-evidence-and-oracle-design','native-refinement-and-case-design','future-explicit-authorization-review']
check('all8 future review deliverables remain pending without artifacts or grants',[x['id'] for x in actual['future_review_deliverables']]==expected_deliverables and all(x['state']=='pending-review-no-native-authorization' and x['actual_artifact'] is None and not x['grants_authority'] for x in actual['future_review_deliverables']))
supp=actual['supplemental_external_inputs'];s=supp[0];site=s['source_sites364'][0];loc=site['anchor'];raw=sources[loc['path']];pieces=raw.split(b'\n');full=pieces[4957]+b'\n';offset=sum(len(x)+1 for x in pieces[:4957])
check('supplemental cksum keeps independently exact4958 byte anchor',len(supp)==1 and s['name_candidate']=='cksum' and loc['line_number']==4958 and full.decode()==loc['full_line_text'] and sha(full)==loc['raw_line_sha256'] and offset==loc['line_start_byte'] and len(full)==loc['line_length_bytes'] and sha(raw)==loc['source_sha256'] and site['token']=='cksum')
check('supplemental cksum does not rewrite frozen51-name register','cksum' not in [x['name_candidate'] for x in deps['command_candidates']] and len(deps['command_candidates'])==51 and not s['historical_register363_modified'] and not s['native_resolution_performed'])
check('both supplemental external input slots stay unbound',len(s['platform_readiness'])==2 and [x['platform'] for x in s['platform_readiness']]==['Slackware-15.0','Slackware-current'] and all(all(x[k] is None for k in nullable) and not x['native_proof'] and not x['execution_authorized'] for x in s['platform_readiness']))
check('full46 qualified proof rows retained exactly',actual['full_qualified_proof_rows347']==gap_data['full_normative_rows']['qualified_proof_reconciliation'] and len(actual['full_qualified_proof_rows347'])==46 and all(x['status']=='required-not-proven' for x in actual['full_qualified_proof_rows347']))
check('full52 native case rows retained exactly',actual['full_native_case_rows347']==gap_data['full_normative_rows']['native_case_templates'] and len(actual['full_native_case_rows347'])==52 and all(x['status']=='required-not-run' for x in actual['full_native_case_rows347']))
check('full12 raw observation groups retained uncaptured',actual['full_independent_raw_groups335']==gap_data['full_original_evidence_group_rows335'] and len(actual['full_independent_raw_groups335'])==12 and all(x['status']=='required-native-evidence-not-captured' for x in actual['full_independent_raw_groups335']))
by_id={x['id']:x for x in rows}
def has(key,token):return any(token in text for text in by_id[key]['implementation_review_required'])
for label,key,token in [
('successor preparation and nested graph retained',expected_ids[0],'preparation'),('private tags never credentials',expected_ids[1],'not credentials'),('lost ACK quarantine irreversible',expected_ids[2],'quarantine'),('single launch pre-spend before spawn',expected_ids[3],'pre-spend'),('worker broker capability excluded',expected_ids[4],'broker'),('split live original fences required',expected_ids[5],'forward, recovery and publication'),('writer exclusion continuous through release',expected_ids[6],'through known release'),('fresh baseline before owned workspace',expected_ids[7],'before owned workspace'),('unknown owned versus target bindings separate',expected_ids[8],'unknown target binding'),('full raw backend vectors and sticky failure',expected_ids[9],'sticky failure'),('source hook consumption includes cksum',expected_ids[10],'cksum'),('finite same attempt recovery retains original deadline',expected_ids[11],'original deadline'),('target closure resolves late publication reads',expected_ids[12],'publication target reads'),('independent publication rejects uncertain republish',expected_ids[13],'uncertain republish'),('macro counts never universal native schedules',expected_ids[14],'not universal schedules'),('separate native test authority for every platform',expected_ids[15],'each platform and case')]:
    check(label,has(key,token))
for label,mutate in [
('omitted prerequisite row',lambda x:x['prerequisite_rows'].pop()),('reordered prerequisite rows',lambda x:x['prerequisite_rows'].reverse()),('shortened normative requirement',lambda x:x['prerequisite_rows'][0].__setitem__('original_refinement_requirement','summary only')),('changed original gap row',lambda x:x['prerequisite_rows'][0]['full_original_gap_row348'].__setitem__('status','closed')),
('omitted implementation requirement',lambda x:x['prerequisite_rows'][0]['implementation_review_required'].pop()),('omitted independent evidence question',lambda x:x['prerequisite_rows'][0]['future_native_fault_evidence_questions'].clear()),('omitted selected source finding',lambda x:x['prerequisite_rows'][0]['source_findings364'].pop()),('missing native gap treated absent',lambda x:x['prerequisite_rows'][1].__setitem__('source_relation_status','absent')),
('native component selected',lambda x:x['prerequisite_rows'][0].__setitem__('actual_selected_component',{})),('native refinement invented',lambda x:x['prerequisite_rows'][0].__setitem__('actual_native_event_refinement',{})),('native gap discharged',lambda x:x['prerequisite_rows'][0].__setitem__('gap_discharged',True)),('shared platform identity',lambda x:x['prerequisite_rows'][0]['platform_readiness'][1].__setitem__('id',x['prerequisite_rows'][0]['platform_readiness'][0]['id'])),('missing second platform',lambda x:x['prerequisite_rows'][0]['platform_readiness'].pop()),('evidence group invented',lambda x:x['prerequisite_rows'][0]['related_evidence_group_ids_non_exhaustive'].append('invented')),
('future deliverable omitted',lambda x:x['future_review_deliverables'].pop()),('future artifact invented',lambda x:x['future_review_deliverables'][0].__setitem__('actual_artifact','invented')),('future deliverable grants authority',lambda x:x['future_review_deliverables'][0].__setitem__('grants_authority',True)),('cksum dropped',lambda x:x['supplemental_external_inputs'].clear()),('cksum native resolution invented',lambda x:x['supplemental_external_inputs'][0].__setitem__('native_resolution_performed',True)),('historical register rewrite',lambda x:x['supplemental_external_inputs'][0].__setitem__('historical_register363_modified',True)),('qualified proof omitted',lambda x:x['full_qualified_proof_rows347'].pop()),('native case omitted',lambda x:x['full_native_case_rows347'].pop()),('raw evidence group omitted',lambda x:x['full_independent_raw_groups335'].pop()),('unknown native runner field',lambda x:x.__setitem__('runner',{}))]:
    bad=copy.deepcopy(stored);mutate(bad);check('reject '+label,rejected(m['validate_prerequisites'],bad,sources,inputs))
for field in nullable+['native_proof','execution_authorized','status']:
    bad=copy.deepcopy(stored);bad['prerequisite_rows'][0]['platform_readiness'][0][field]=True if field in ['native_proof','execution_authorized'] else 'invented';check('reject invented native readiness '+field,rejected(m['validate_prerequisites'],bad,sources,inputs))
for field,value in [('fault_questions_are_complete_native_schedules',True),('prerequisite_table_is_native_implementation',True),('prerequisite_table_grants_test_authority',True),('native_components_selected',True),('native_cases_run',1),('native_proofs_added',1),('historical_constants_are_current_bindings',True),('missing_evidence_means_absent',True),('offline_PASS_proves_operational_conformance',True),('next_review_step',367)]:
    bad=copy.deepcopy(stored);bad['coverage'][field]=value;check('reject false prerequisites coverage '+field,rejected(m['validate_prerequisites'],bad,sources,inputs))
for field,value in [('native_graph_complete',True),('execution_authorized',True),('runtime_authority',True),('actual_successor_selected',True),('actual_live_bindings',{}),('actual_host_state','absent'),('actual_global_host_closure',True),('native_cases_run',1),('readme_reconciliation_step',None),('strong_safe_pause',True)]:
    bad=copy.deepcopy(stored);bad['boundaries'][field]=value;check('reject false boundary '+field,rejected(m['validate_prerequisites'],bad,sources,inputs))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented_native_authority']=True;check('reject changed full frozen '+key,rejected(m['prerequisites'],sources,bad))
bad=dict(inputs);bad.pop('effects');check('reject incomplete frozen input set',rejected(m['prerequisites'],sources,bad))
bad=dict(inputs);bad['extra']={};check('reject extra frozen input set',rejected(m['prerequisites'],sources,bad))
first=policy['source_roots'][0]['path'];bad=dict(sources);bad[first]=b'X'+bad[first][1:];check('reject source byte drift',rejected(m['prerequisites'],bad,inputs))
bad=dict(sources);bad['../unapproved.sh']=b'exit 0\n';check('reject traversing extra source',rejected(m['prerequisites'],bad,inputs))
views=m['source_lines'](sources);check('reject bool and out of range source anchor integers',all(rejected(m['anchor'],views,i,1) for i in [True,-1,4]) and all(rejected(m['anchor'],views,0,line) for line in [True,0,6638]))
mutated=m['prerequisites'](sources,inputs);mutated['boundaries']['runtime_authority']=True;mutated['review_sources'][0]['execution_authorized']=True;mutated['full_original_native_gap_rows348'][0]['status']='waived';mutated['prerequisite_rows'][0]['implementation_review_required'].clear();mutated['frozen_inputs']['effects']='changed';mutated['full_native_case_rows347'][0]['status']='passed'
check('returned report detached from module constants and every caller input',not m['BOUNDARIES']['runtime_authority'] and not m['SOURCE_BINDINGS'][0]['execution_authorized'] and len(m['SPECS'][0][1])==3 and gaps[0]['status']=='required-not-selected-refined-or-proven' and m['prerequisites'](sources,inputs)==stored)
ast_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(ast_tree) if isinstance(node,ast.Import) for alias in node.names}
check('pure prerequisites validator imports only hashlib json and re',imports=={'hashlib','json','re'})
check('validator has no filesystem lookup execution decode or spawn entry',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in {'open','exec','eval','compile','__import__'}) or (isinstance(node.func,ast.Attribute) and node.func.attr in {'system','popen','run','which','b64decode','execv','spawnv','read_bytes','read_text','stat','resolve'})) for node in ast.walk(ast_tree)))
check('README remains exact pending367',sha((root/'README.md').read_bytes())==policy['readme_at_entry_sha256'])
old_coverage=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-readonly-source-inventory-control-coverage.json'])
check('historical361 modeled socket limitation preserved',not old_coverage['native_proof'] and any('socket-type-stat-metadata-modeled' in x.get('method','') for x in old_coverage['controls']))
check('all16 native gaps remain unselected and unproven',all(x['status']=='required-not-selected-refined-or-proven' and not x['native_status_promoted'] and x['actual_model_or_component'] is None and x['actual_independent_evidence'] is None for x in gaps))
plan=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-source-inventory-resume-planning-review-plan.json'])
check('finite359-368 roadmap and final README obligation retained',[x['step'] for x in plan['roadmap']]==list(range(359,369)) and plan['readme_reconciliation_step']==367 and plan['conditional_pause_step']==368)
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
