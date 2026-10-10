"""Reconcile source and native-gap data; no native selection or authority."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(value):return sha(json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(actual,expected,label):
    if canonical(actual)!=canonical(expected):raise ValueError(label)
    return True

def integer(value,minimum,maximum,label):
    if type(value) is not int or not minimum<=value<=maximum:raise ValueError(label)
    return value

SOURCE_BINDINGS = [{'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/slack-update-reference.sh', 'review_selection_only': True, 'role': 'reference-specification-source-for-review-only', 'sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415', 'size_bytes': 239718}, {'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh', 'review_selection_only': True, 'role': 'historical-worker-body-not-a-selected-native-successor', 'sha256': 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68', 'size_bytes': 42856}, {'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh', 'review_selection_only': True, 'role': 'historical-generator-source-for-review-only', 'sha256': '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da', 'size_bytes': 9487}, {'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh', 'review_selection_only': True, 'role': 'historical-generated-artifact-not-a-second-independent-worker', 'sha256': 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d', 'size_bytes': 373181}]
INPUT_HASHES = {'context': '826215551c42d25dd9dfee3ec4a0ee1368b0516e5e771a183d2286ca691eb6bc', 'dependency': '5c7f04e951ddad613b80d888637334ca425d1048db3e0f16d8316d3e322f35f2', 'effects': 'c93f51f5df607e11044f8768e4af2df2e2ea8d49fd16f340d5838f2fb6a1289b', 'inventory': 'd336257b5730c1f454d5c6e731b0ae8e01bcbb6682fb672b630c0be113da0e62', 'native_gap': 'fa137d69e96839812beb47c4716c2e51441a3a1ca8f80070badbde28b3480a59', 'prerequisites': '8204756e325e6eea4a0e52de0d2f7fbce68218d5e11b021d42baafbcafcb2a8c', 'plan': 'a224d849409a76649e865e585c10d7008ff436e244a34abf3419c679996eccb2', 'confirmations': 'f28359d164e1869464e3527f4f3a5b3c3967791e841f5a5e14784f6915ff5f35'}
CONFIRMATION = {'acceptance_result': 'PASS (140 passes, 0 failures)', 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'basis': 'complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture', 'commit_full': None, 'commit_prefix': 'bede6fa', 'exact_commit_scope_files': 8, 'exact_commit_scope_insertions': 2762, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 358, 'native_cases_run': 0, 'native_proofs_added': 0, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'receipt_sha256': '781ec7dac2c60590886afb983f4f13fb74a209aeee1ecd07d5b35cee18fd37c8', 'receipt_size_bytes': 10690, 'runtime_authority': False, 'schema': 1, 'scope': 'repository-source-inventory-and-roadmap-workstream359-368-only', 'step': 365, 'strong_safe_pause': False, 'user_application_completed': True, 'user_commit_and_push_completed': True, 'user_harness_completed': True, 'user_head_matches_origin': True, 'user_worktree_clean': True}
RECEIPT = {'schema': 1, 'step': 365, 'sha256': '781ec7dac2c60590886afb983f4f13fb74a209aeee1ecd07d5b35cee18fd37c8', 'size_bytes': 10690, 'normalization': 'none', 'capture_basis': 'complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture'}
README_SHA = '6cfc1556fd6ef50089be4f3b5472c268dd01a8330b6262e46b51994712a7cfad'
README_TARGETS = [('current-project-status', 10, '## Project status', 'Summarize accepted repository checkpoints and remaining Phase1/reference-v1/C blockers without claiming complete platform validation.'), ('comment-language-checklist', 636, '- [ ] Ensure every comment added to the script is written in English.', 'Audit accepted comment-language remediation closure before changing this historical checkbox.'), ('normal-update-history', 1387, '  - [ ] Repeat the corrected Slackware-current preflight before any apply authorization.', 'Reconcile later accepted transactions with stale preflight history; retain the kernel-package-edge blocker and consume no fresh authority.'), ('ELILO-mature-retention-history', 1399, '  - [ ] Repeat the retention preflight no earlier than 2026-08-08 19:51 CEST and review mature eligibility evidence.', 'Reconcile accepted116 cleanup closure with stale scheduled retention task; do not reopen consumed machine authority.'), ('ELILO-cleanup-apply-history', 1402, '  - [ ] Implement and explicitly authorize the separate cleanup apply only after mature eligibility evidence is accepted.', 'Reconcile later accepted cleanup implementation and closure with this historical unchecked task.'), ('reference-freeze-gates', 1430, '### Reference freeze', 'Keep reference-v1 and C completion gates blocked and distinguish provisional structured output from a frozen v1 schema.'), ('v1-schema-pending', 1434, '- [ ] Define the version 1 JSON result schema.', 'Preserve explicit pending version1 schema obligation; repository source review is not schema acceptance.'), ('immediate-next-steps', 1909, '## Immediate next steps', 'Separate the current finite367/368 repository work from historical machine checklist; retain fresh-boundary requirements for later native work.'), ('last-numbered-checkpoint120', 2749, '<!-- step-120-configuration-compatibility-checkpoint:start -->', 'Preserve numbered history and distinguish checkpoint120 from later reconciliation173 and current367 work.')]
BOUNDARIES = {'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_successor_selected': False, 'conditional_pause_step': 368, 'execution_authorized': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 358, 'native_cases_run': 0, 'native_gap_count': 16, 'native_graph_complete': False, 'native_proofs_added': 0, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'readme_reconciliation_step': 367, 'runtime_authority': False, 'strong_safe_pause': False}

def source_lines(sources):
    if type(sources) is not dict or set(sources)!={row['path'] for row in SOURCE_BINDINGS}:raise ValueError('exact sources required')
    result={}
    for binding in SOURCE_BINDINGS:
        raw=sources[binding['path']]
        if type(raw) is not bytes or len(raw)!=binding['size_bytes'] or sha(raw)!=binding['sha256']:raise ValueError('source byte binding changed')
        raw.decode('utf-8','strict')
        if b'\0' in raw:raise ValueError('NUL source')
        lines=raw.split(b'\n');lines=[line+b'\n' for line in lines[:-1]]+([lines[-1]] if lines[-1] else [])
        offsets=[];offset=0
        for line in lines:offsets.append(offset);offset+=len(line)
        result[binding['path']]=(raw,lines,offsets,binding)
    return result

def anchor(views,index,line):
    integer(index,0,len(SOURCE_BINDINGS)-1,"source index")
    path=SOURCE_BINDINGS[index]['path'];raw,lines,offsets,binding=views[path]
    integer(line,1,len(lines),'line outside source');content=lines[line-1]
    return {'path':path,'source_sha256':binding['sha256'],'line_number':line,'line_start_byte':offsets[line-1],'line_length_bytes':len(content),'raw_line_sha256':sha(content),'full_line_text':content.decode('utf-8'),'source_role':binding['role']}

def validate_acceptance(receipt,confirmation):
    exact(confirmation,CONFIRMATION,'confirmation changed')
    exact({k:v for k,v in receipt.items() if k!='text'},RECEIPT,'receipt fields changed')
    raw=receipt['text'].encode('utf-8')
    if sha(raw)!=RECEIPT['sha256'] or len(raw)!=RECEIPT['size_bytes']:raise ValueError('complete user message changed')
    return True

def readme_anchors(raw):
    if type(raw) is not bytes or sha(raw)!=README_SHA:raise ValueError('exact unchanged README required')
    pieces=raw.split(b'\n');lines=[p+b'\n' for p in pieces[:-1]]+([pieces[-1]] if pieces[-1] else [])
    offsets=[];at=0
    for line in lines:offsets.append(at);at+=len(line)
    result=[]
    for key,line,literal,need in README_TARGETS:
        content=lines[line-1]
        if content.decode('utf-8').rstrip('\n')!=literal:raise ValueError('README target literal changed')
        result.append({'id':key,'anchor':{'path':'README.md','source_sha256':README_SHA,'line_number':line,'line_start_byte':offsets[line-1],'line_length_bytes':len(content),'raw_line_sha256':sha(content),'full_line_text':content.decode('utf-8')},'required367_review':need,'readme_edited':False,'checkbox_promoted':False,'runtime_authority':False})
    return result

def reconcile(sources,inputs,readme):
    source_lines(sources)
    if type(inputs) is not dict or set(inputs)!=set(INPUT_HASHES):raise ValueError('exact complete input set required')
    for key,value in inputs.items():
        if canonical(value)!=INPUT_HASHES[key]:raise ValueError('frozen input changed: '+key)
    g=inputs['native_gap'];norm=g['full_normative_rows'];gaps=g['full_original_native_gap_rows348'];pr=inputs['prerequisites'];effects=inputs['effects'];deps=inputs['dependency']
    if pr['full_original_native_gap_rows348']!=gaps or effects['full_original_native_gap_rows348']!=gaps or deps['full_original_native_gap_rows348']!=gaps:raise ValueError('full original gap relation inconsistent')
    by_pr={x['id']:x for x in pr['prerequisite_rows']}
    rows=[]
    for gap in gaps:
        key=gap['inherited_gap']['id'];p=by_pr[key];hazards=[h for h in effects['lifetime_hazards'] if key in h['original_native_gap_ids']];families=[f for f in deps['dependency_families'] if key in f['original_native_gap_ids']]
        if p['full_original_gap_row348']!=gap or p['source_findings364']!=hazards:raise ValueError('prerequisite original/source linkage inconsistent')
        rows.append({'id':key,'full_original_gap_row348':gap,'prerequisite365_canonical_sha256':canonical(p),'source_hazard_ids364':[h['id'] for h in hazards],'dependency_family_ids363':[f['id'] for f in families],'implementation_requirements365':p['implementation_review_required'],'platform_readiness365':p['platform_readiness'],'source_links_are_non_exhaustive':True,'source_links_discharge_native_gap':False,'no_selected_source_link_means_absent':False,'native_status':'required-not-selected-refined-or-proven','actual_native_evidence':None})
    proofs=norm['qualified_proof_reconciliation'];cases=norm['native_case_templates'];raw_groups=g['full_original_evidence_group_rows335'];case_map={(x['platform'],x['case_id']):x for x in cases};proof_ids={x['qualified_id'] for x in proofs};group_ids={x['id'] for x in raw_groups}
    if len(case_map)!=len(cases) or len(proof_ids)!=len(proofs):raise ValueError('duplicate original proof/case identity')
    from_proof={(p['qualified_id'],c['platform'],c['case_id']) for p in proofs for c in p['required_native_case_tuples']};from_case={(p,c['platform'],c['case_id']) for c in cases for p in c['required_qualified_proofs']}
    if from_proof!=from_case or any((platform,cid) not in case_map or pid not in proof_ids for pid,platform,cid in from_proof):raise ValueError('proof/case relation inconsistent')
    if any(not set(c['evidence_group_ids'])<=group_ids for c in cases):raise ValueError('unknown evidence group in native case')
    relations=[{'qualified_proof_id':p['qualified_id'],'platform':c['platform'],'case_id':c['case_id'],'proof_status':p['status'],'case_status':case_map[(c['platform'],c['case_id'])]['status'],'native_proof':False} for p in proofs for c in p['required_native_case_tuples']]
    checkpoints=[]
    for step in range(359,366):
        c=inputs['confirmations'][str(step)]
        if c['step']!=step or c['strong_safe_pause'] or c['runtime_authority'] or not c['user_worktree_clean'] or not c['user_head_matches_origin']:raise ValueError('checkpoint acceptance boundary inconsistent')
        checkpoints.append({'step':step,'reported_commit_prefix':c['commit_prefix'],'commit_full':None,'acceptance_result':c['acceptance_result'],'confirmation_canonical_sha256':canonical(c),'reported_clean_matching_heads':True,'new_strong_safe_pause':False,'runtime_authority':False})
    names=[x['name_candidate'] for x in deps['command_candidates']];supp=pr['supplemental_external_inputs']
    if len(supp)!=1 or supp[0]['name_candidate']!='cksum' or 'cksum' in names or supp[0]['historical_register363_modified']:raise ValueError('supplemental frozen-register relation changed')
    ledger=[{'stage':361,'full_input':'inventory','full_input_canonical_sha256':INPUT_HASHES['inventory'],'source_records':len(inputs['inventory']['hint_records']),'native_proof':False}, {'stage':362,'full_input':'context','full_input_canonical_sha256':INPUT_HASHES['context'],'whole_spans':len(inputs['context']['selected_spans']),'selected_sites':len(inputs['context']['selected_sites']),'native_proof':False}, {'stage':363,'full_input':'dependency','full_input_canonical_sha256':INPUT_HASHES['dependency'],'written_candidates':len(names),'literal_occurrences':len(deps['literal_occurrences']),'dependency_families':len(deps['dependency_families']),'missing_platform_inputs':126,'native_proof':False}, {'stage':364,'full_input':'effects','full_input_canonical_sha256':INPUT_HASHES['effects'],'effect_domains':len(effects['effect_domains']),'lifetime_hazards':len(effects['lifetime_hazards']),'missing_platform_relations':32,'retained_lexical_channel_indices':4660,'native_proof':False}, {'stage':365,'full_input':'prerequisites','full_input_canonical_sha256':INPUT_HASHES['prerequisites'],'prerequisite_rows':len(pr['prerequisite_rows']),'missing_platform_readiness_slots':32,'supplemental_platform_slots':2,'pending_review_deliverables':8,'native_proof':False}]
    report={'schema':1,'step':366,'scope':pr['scope'],'review_sources':SOURCE_BINDINGS,'frozen_inputs':INPUT_HASHES,'accepted_checkpoints359_365':checkpoints,'source_review_ledger':ledger,'gap_reconciliation_rows':rows,'full_original_native_gap_rows348':gaps,'full_qualified_proof_rows347':proofs,'full_native_case_rows347':cases,'full_independent_raw_groups335':raw_groups,'ordered_proof_case_relations':relations,'original_contract_bindings320_327':norm['exact_contract_bindings'],'full_contracts_canonical_sha256':canonical(g['full_original_contracts320_327']),'full_normative_sections':{k:{'canonical_sha256':canonical(v),'representation':'whole-section-bound-not-count-substitute','kind':'list' if isinstance(v,list) else 'object','row_count':len(v) if isinstance(v,list) else None} for k,v in norm.items()},'supplemental_external_inputs365':supp,'readme367_review_targets':readme_anchors(readme),'remaining_roadmap':inputs['plan']['roadmap'][8:],'boundaries':BOUNDARIES,'coverage':{'whole_inputs_retained':True,'all16_native_gaps_retained':True,'proof_case_relation_bidirectional':True,'source_links_exhaustive':False,'full_native_graph_resolved':False,'native_case_executed':False,'native_proof_added':False,'actual_component_selected':False,'readme_reconciled':False,'current_step_is_strong_pause':False,'source_review_closes_phase1_matrix':False,'source_review_selects_native_successor':False,'source_missing_means_absent':False,'historical_authority_reused':False,'README_is_operational_review_root':False}}
    return json.loads(json.dumps(report,sort_keys=True,ensure_ascii=True))

def validate_reconciliation(report,sources,inputs,readme):
    return exact(report,reconcile(sources,inputs,readme),'reconciliation changed or native closure promoted')
