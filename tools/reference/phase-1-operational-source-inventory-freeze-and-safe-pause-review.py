"""Freeze reviewed source and README data; conditional repository pause only."""
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

CONFIRMATION = {'acceptance_result': 'PASS (146 passes, 0 failures)', 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'basis': 'complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture', 'commit_full': None, 'commit_prefix': '06ce1a3', 'exact_commit_scope_files': 9, 'exact_commit_scope_insertions': 2769, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 358, 'native_cases_run': 0, 'native_proofs_added': 0, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'receipt_sha256': 'f8cada5662cf43764ba1122a8c77c21a690d3c00a18f3ad033164f7d41c871c2', 'receipt_size_bytes': 13307, 'runtime_authority': False, 'schema': 1, 'scope': 'repository-source-inventory-and-roadmap-workstream359-368-only', 'step': 367, 'strong_safe_pause': False, 'user_application_completed': True, 'user_commit_and_push_completed': True, 'user_harness_completed': True, 'user_head_matches_origin': True, 'user_worktree_clean': True, 'exact_commit_scope_deletions': 31}
RECEIPT = {'schema': 1, 'step': 367, 'sha256': 'f8cada5662cf43764ba1122a8c77c21a690d3c00a18f3ad033164f7d41c871c2', 'size_bytes': 13307, 'normalization': 'none', 'capture_basis': 'complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture'}
SOURCE_BINDINGS = [{'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/slack-update-reference.sh', 'review_selection_only': True, 'role': 'reference-specification-source-for-review-only', 'sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415', 'size_bytes': 239718}, {'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh', 'review_selection_only': True, 'role': 'historical-worker-body-not-a-selected-native-successor', 'sha256': 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68', 'size_bytes': 42856}, {'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh', 'review_selection_only': True, 'role': 'historical-generator-source-for-review-only', 'sha256': '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da', 'size_bytes': 9487}, {'actual_native_binding': None, 'execution_authorized': False, 'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh', 'review_selection_only': True, 'role': 'historical-generated-artifact-not-a-second-independent-worker', 'sha256': 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d', 'size_bytes': 373181}]
INPUT_HASHES = {'context': '826215551c42d25dd9dfee3ec4a0ee1368b0516e5e771a183d2286ca691eb6bc', 'dependency': '5c7f04e951ddad613b80d888637334ca425d1048db3e0f16d8316d3e322f35f2', 'effects': 'c93f51f5df607e11044f8768e4af2df2e2ea8d49fd16f340d5838f2fb6a1289b', 'inventory': 'd336257b5730c1f454d5c6e731b0ae8e01bcbb6682fb672b630c0be113da0e62', 'native_gap': 'fa137d69e96839812beb47c4716c2e51441a3a1ca8f80070badbde28b3480a59', 'plan': 'a224d849409a76649e865e585c10d7008ff436e244a34abf3419c679996eccb2', 'prerequisites': '8204756e325e6eea4a0e52de0d2f7fbce68218d5e11b021d42baafbcafcb2a8c', 'reconciliation366': 'e0b6268fd4960319e7729ec3653c81d325df10911271c12eb70911d48f66bb56', 'readme367': 'd4b93a1ca9c12d1fbdf4b2869ccf22cc5c39ad83c00a6487535e827ffc7fe693', 'pause358': '1ef0efffebdd88bcb9251cc83df0f93d9f463f975c5c49b9844c9bb13cd2d0e9', 'confirmed358': '02b6bab63eba2a31bd77beb2d0362d1dab1156c9f65f34d7aef704d007c48604', 'controls361': '4927cb8493f5cc6ae4a850d0758da89b6d93ce5dd7e579c1d8de58b80041be7a'}
README_SHA = 'abd8b889d00a6f8324c260d9d0584a364a5e08d6e1ccfd40b76bc01eb66fce49'
SCOPE = 'repository-source-inventory-and-roadmap-workstream359-368-only'

def validate_acceptance(receipt,confirmation):
    exact(confirmation,CONFIRMATION,'confirmation changed')
    exact({k:v for k,v in receipt.items() if k!='text'},RECEIPT,'receipt fields changed')
    raw=receipt['text'].encode('utf-8')
    if sha(raw)!=RECEIPT['sha256'] or len(raw)!=RECEIPT['size_bytes']:raise ValueError('complete user message changed')
    return True

def validate_sources(sources):
    if type(sources) is not dict or set(sources)!={x['path'] for x in SOURCE_BINDINGS}:raise ValueError('exact four source roots required')
    for desc in SOURCE_BINDINGS:
        raw=sources[desc['path']]
        if type(raw) is not bytes or len(raw)!=desc['size_bytes'] or sha(raw)!=desc['sha256']:raise ValueError('source bytes changed')
        if desc['execution_authorized'] or desc['actual_native_binding'] is not None:raise ValueError('source authority changed')
    return True

def validated_inputs(inputs,readme,sources):
    validate_sources(sources)
    if type(readme) is not bytes or sha(readme)!=README_SHA:raise ValueError('accepted reconciled README required')
    if type(inputs) is not dict or set(inputs)!=set(INPUT_HASHES):raise ValueError('exact complete frozen input set required')
    for key,value in inputs.items():
        if canonical(value)!=INPUT_HASHES[key]:raise ValueError('frozen input changed: '+key)
    return True

def pause_conditions(inputs,readme,sources):
    validated_inputs(inputs,readme,sources)
    original=inputs['pause358'];confirmed358=inputs['confirmed358'];plan=inputs['plan']
    ids=[row['id'] for row in original['conditions']]
    if ids!=confirmed358['original_pause_conditions'] or len(ids)!=9:raise ValueError('all original scoped conditions required')
    if plan['conditional_pause_step']!=368 or plan['readme_reconciliation_step']!=367 or plan['boundaries']['scope']!=SCOPE:raise ValueError('finite original batch scope changed')
    rows=[]
    for pos,row in enumerate(original['conditions']):
        rows.append({'id':row['id'],'position':pos,'requirement':row['requirement'],'full_original_condition358':row,'repository_status':'pending-current368-complete-user-return' if pos==0 else 'repository-scope-checked-with-native-blockers-retained','current368_actual_user_confirmation':None,'actual_native_evidence':None})
    report={'schema':1,'step':368,'scope':SCOPE,'conditions':rows,'full_original_conditions358_canonical_sha256':INPUT_HASHES['pause358'],'last_confirmed_strong_safe_pause_step':358,'original_condition_scope358':original['scope'],'private_eligibility_is_actual_confirmation':False,'actual_strong_safe_pause_confirmed':False,'actual_global_host_closure':False,'runtime_authority':False,'current368_user_commit_full':None,'current368_user_commit_prefix':None,'current368_user_worktree_clean':None,'current368_user_head_matches_origin':None,'required_final_commit_message':'Phase 1 step 368: freeze source inventory and conditional safe pause','final_receipt_rule':{'overlay':'step368 installer PASS with exact accepted367 baseline','tests':'complete exact ordered368 PASS labels and zero-failure summary frozen in delivery manifest','commit':'exact message and all nine changed paths with eight exact additions; exact stats and SHA set in delivery manifest','push':'successful06ce1a3-to-reported368 push to main','status':'empty git status followed by two matching reported HEAD/origin lines','bytes':'retain complete uploaded user-message UTF8 bytes without normalization; do not invent independent original terminal capture or full commit ID','confirmation':'external to immutable repository only after all nine scoped conditions and complete final receipt','native':'no proof, case run, live authority, operational readiness or global host closure inferred'},'after_final_acceptance':{'batch_stopped':True,'next_authorized_stage':None,'automatic369':False,'future_work_requires_new_user_request':True,'historical_binding_or_authority_reuse_allowed':False,'later_current_refresh_invalidates_repository_only_pause':False}}
    return json.loads(json.dumps(report,sort_keys=True,ensure_ascii=True))

def freeze(sources,inputs,readme):
    validated_inputs(inputs,readme,sources)
    g=inputs['native_gap'];rec=inputs['reconciliation366'];doc=inputs['readme367'];plan=inputs['plan'];norm=g['full_normative_rows'];pr=inputs['prerequisites']
    if doc['readme_after_sha256']!=README_SHA or not doc['boundaries']['readme_reconciled'] or doc['phase1_matrix_complete'] or doc['current_step_strong_safe_pause']:raise ValueError('README acceptance boundary inconsistent')
    if doc['full_native_gap_rows348']!=g['full_original_native_gap_rows348'] or rec['full_original_native_gap_rows348']!=g['full_original_native_gap_rows348']:raise ValueError('full native gap linkage inconsistent')
    if [row['step'] for row in plan['roadmap']]!=list(range(359,369)) or any(row['runtime_authorized'] for row in plan['roadmap']):raise ValueError('exact ten-step no-runtime roadmap required')
    if canonical(g)!=doc['full_native_contract_input_canonical_sha256'] or canonical(rec)!=doc['full_source_reconciliation366_canonical_sha256']:raise ValueError('whole native/source input linkage changed')
    checkpoints=rec['accepted_checkpoints359_365']+[{'step':366,'reported_commit_prefix':doc['accepted_checkpoint366']['commit_prefix'],'commit_full':None,'acceptance_result':doc['accepted_checkpoint366']['acceptance_result'],'confirmation_canonical_sha256':canonical(doc['accepted_checkpoint366']),'reported_clean_matching_heads':True,'new_strong_safe_pause':False,'runtime_authority':False},{'step':367,'reported_commit_prefix':CONFIRMATION['commit_prefix'],'commit_full':None,'acceptance_result':CONFIRMATION['acceptance_result'],'confirmation_canonical_sha256':canonical(CONFIRMATION),'reported_clean_matching_heads':True,'new_strong_safe_pause':False,'runtime_authority':False}]
    if [x['step'] for x in checkpoints]!=list(range(359,368)):raise ValueError('complete accepted359-367 checkpoint chain required')
    proofs=norm['qualified_proof_reconciliation'];cases=norm['native_case_templates'];groups=g['full_original_evidence_group_rows335'];relations=rec['ordered_proof_case_relations']
    left={(p['qualified_id'],c['platform'],c['case_id']) for p in proofs for c in p['required_native_case_tuples']};right={(p,c['platform'],c['case_id']) for c in cases for p in c['required_qualified_proofs']}
    observed={(x['qualified_proof_id'],x['platform'],x['case_id']) for x in relations}
    if left!=right or observed!=left or len(relations)!=len(left):raise ValueError('complete unique bidirectional native obligation relations required')
    native_closed={'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'native_graph_complete':False,'actual_native_refinement_complete':False,'actual_successor_selected':False,'native_components_selected':False,'native_proofs_added':0,'native_cases_run':0,'operational_readiness':False,'operational_conformance':False,'runtime_authority':False,'execution_authorized':False,'machine_action_required':False,'controller_action_required':False,'phase1_matrix_complete':False,'kernel_package_edge_complete':False,'reference_v1_frozen':False,'version1_schema_frozen':False,'C_port_open':False,'phase2_open':False,'production_entry_closed':True,'strong_safe_pause':False}
    report={'schema':1,'step':368,'scope':SCOPE,'state':'prepared-final-user-overlay-tests-commit-push-receipt-pending','review_sources':SOURCE_BINDINGS,'frozen_inputs':INPUT_HASHES,'accepted_checkpoint_chain359_367':checkpoints,'last_confirmed_strong_safe_pause_step':358,'full_roadmap359_368':plan['roadmap'],'batch_length':10,'repository_review_eligible_for_conditional_pause':True,'final_pause_requires_complete_user_receipt':True,'actual_strong_safe_pause_confirmed':False,'source_review_ledger366':rec['source_review_ledger'],'full_gap_reconciliation_rows366':rec['gap_reconciliation_rows'],'full_original_contracts320_327':g['full_original_contracts320_327'],'full_normative_rows347':norm,'full_original_native_gap_rows348':g['full_original_native_gap_rows348'],'full_qualified_proof_rows347':proofs,'full_native_case_rows347':cases,'full_independent_raw_groups335':groups,'full_independence_contract335':g['full_original_independence_contract335'],'ordered_required_proof_case_relations':relations,'supplemental_external_inputs365':pr['supplemental_external_inputs'],'full_normative_section_sha256':{k:canonical(v) for k,v in norm.items()},'full_contracts_sha256':canonical(g['full_original_contracts320_327']),'historical361_control_coverage':inputs['controls361'],'readme':{'path':'README.md','sha256':README_SHA,'size_bytes':len(readme),'accepted_at_step':367,'accepted_reported_commit_prefix':'06ce1a3','complete_reconciliation_record_sha256':INPUT_HASHES['readme367'],'patch_operations':doc['patch_operations'],'full_support_source_hashes':doc['full_support_source_hashes'],'residual_inventory188_exact_text':doc['residual_inventory188_exact_text'],'remaining_real_system_families':5,'remaining_real_system_scenarios':20,'documentation_input_not_operational_review_root':True,'historical_diagnostics_relabelled_accepted':False,'historical_authority_reused':False},'pause_conditions_canonical_sha256':canonical(pause_conditions(inputs,readme,sources)),'boundaries':native_closed,'after_final_acceptance':{'batch_stopped':True,'next_authorized_stage':None,'automatic369':False,'future_work_requires_new_user_request':True,'historical_binding_or_authority_reuse_allowed':False,'later_current_refresh_invalidates_repository_only_pause':False}}
    return json.loads(json.dumps(report,sort_keys=True,ensure_ascii=True))

def validate_freeze(value,sources,inputs,readme):return exact(value,freeze(sources,inputs,readme),'freeze drift or false closure')
def validate_pause_conditions(value,inputs,readme,sources):return exact(value,pause_conditions(inputs,readme,sources),'pause condition drift or premature confirmation')
