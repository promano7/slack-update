#!/usr/bin/env python3
"""Review supplied draft design data and frozen source bytes, without native action."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(value):return sha(json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or (value!=expected if isinstance(value,(set,bytes)) else canonical(value)!=canonical(expected)):
        raise ValueError(label)
    return True

POLICY_SHA='7efd3230956344a455ee36ab985126131ecd4ededed29b6e29f2dba17acb520d'
DESIGN_SHA='e02d1237325cbfbb3821f9c824830caff78f07a960bb1133b9ea2b5b1babc04a'
BOUNDARIES={'C_port_open': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_native_refinement_complete': False, 'actual_successor_selected': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'design_is_complete_native_graph': False, 'design_is_actual_source_implementation': False, 'design_is_actual_native_refinement': False}

def validate_policy(policy):
    exact(canonical(policy),POLICY_SHA,'frozen policy changed')
    return True

def validate_acceptance(confirmation,receipt,policy):
    validate_policy(policy)
    exact(canonical(confirmation),policy['confirmation_canonical_sha256'],'complete accepted369 confirmation')
    exact(canonical(receipt),policy['receipt_canonical_sha256'],'complete pasted369 representation')
    raw=receipt['text'].encode('utf-8')
    exact(sha(raw),confirmation['receipt_sha256'],'receipt SHA')
    exact(len(raw),confirmation['receipt_size_bytes'],'receipt length')
    text=receipt['text'];contract=policy['accepted369_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered369_labels'],'all89 ordered labels')
    for key in ['expected_zero_failure_summary','expected_overlay_status','expected_commit_scope_status','synthetic_expected_commit_stats']:
        if text.count(contract[key])!=1:raise ValueError('single reported369 marker: '+key)
    if text.count('[main 3a99d10] '+contract['expected_commit_message'])!=1 or text.count('030acb8..3a99d10  main -> main')!=1:
        raise ValueError('reported exact commit or successful push')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'exact eight additions')
    head='3a99d10 (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
    if text.count(head)!=2 or not text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $\n'):
        raise ValueError('complete reported clean matching-head ending')
    return True

def validate_inputs(inputs,sources,readme,policy):
    validate_policy(policy)
    exact(set(inputs),set(policy['input_paths']),'complete frozen input set')
    for k,v in inputs.items():exact(canonical(v),policy['input_canonical_sha256'][k],'whole frozen input '+k)
    exact(set(sources),{r['path'] for r in policy['source_roots']},'four historical review roots')
    for r in policy['source_roots']:
        raw=sources[r['path']]
        if type(raw) is not bytes or sha(raw)!=r['sha256'] or len(raw)!=r['size_bytes']:raise ValueError('source drift')
    if type(readme) is not bytes or sha(readme)!=policy['readme_at_entry_sha256']:raise ValueError('premature README edit')
    return True

def validate_anchor(anchor,sources):
    raw=sources[anchor['path']]
    if sha(raw)!=anchor['source_sha256']:raise ValueError('anchor source SHA')
    line=anchor['line_number'];start=anchor['line_start_byte'];length=anchor['line_length_bytes']
    if any(type(v) is not int for v in (line,start,length)) or line<1 or start<0 or length<1 or start+length>len(raw):raise ValueError('anchor geometry type or bounds')
    lines=raw.splitlines(keepends=True)
    if line>len(lines) or sum(len(x) for x in lines[:line-1])!=start or len(lines[line-1])!=length:raise ValueError('anchor actual line geometry')
    exact(raw[start:start+length],anchor['full_line_text'].encode('utf-8'),'full line literal')
    exact(sha(raw[start:start+length]),anchor['raw_line_sha256'],'full line SHA')
    return True

def validate_design(design,inputs,sources,policy):
    validate_policy(policy)
    exact(set(inputs),set(policy['input_paths']),'complete frozen design inputs')
    for k,v in inputs.items():exact(canonical(v),policy['input_canonical_sha256'][k],'whole design input '+k)
    exact(canonical(design),DESIGN_SHA,'complete authored draft design')
    exact(design['boundaries'],BOUNDARIES,'closed draft/native boundaries')
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][1]['primary_gap_ids'],'three primary gap review assignments')
    roles={r['id'] for r in design['roles']}
    if len(roles)!=len(design['roles']):raise ValueError('duplicate role')
    for row in design['interfaces']:
        if row['from_role'] not in roles or row['to_role'] not in roles:raise ValueError('unknown interface role')
    original=inputs['effects']['effect_domains']
    exact([r['id'] for r in design['source_effect_treatments']],[r['id'] for r in original],'all21 original selected effect domains')
    for row,source in zip(design['source_effect_treatments'],original):
        exact(row['full_original_domain_canonical_sha256'],canonical(source),'full original domain binding')
        exact(row['full_original_source_anchors'],source['source_anchors'],'all selected full anchors')
        if row['proposed_role'] not in roles:raise ValueError('unknown effect owner role')
        for item in row['full_original_source_anchors']:validate_anchor(item['anchor'],sources)
    exact([r['id'] for r in design['dependency_family_requirements']],[r['id'] for r in inputs['dependency']['dependency_families']],'all12 original dependency families')
    for row,source in zip(design['dependency_family_requirements'],inputs['dependency']['dependency_families']):
        exact(row['full_original_family_canonical_sha256'],canonical(source),'full original dependency family')
        exact([r['platform'] for r in row['platform_inputs']],['Slackware-15.0','Slackware-current'],'separate platform records')
    exact(design['supplemental_cksum']['full_original_supplemental_inputs'],inputs['freeze']['supplemental_external_inputs365'],'whole original cksum supplement')
    return True

def review(design,confirmation,receipt,inputs,sources,readme,policy):
    validate_acceptance(confirmation,receipt,policy)
    validate_inputs(inputs,sources,readme,policy)
    validate_design(design,inputs,sources,policy)
    return json.loads(json.dumps({'schema':1,'step':370,'scope':design['scope'],
        'state':'draft-reference-design-prepared-user-acceptance-pending',
        'boundaries':BOUNDARIES,'design':design,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_original_contracts320_327':inputs['freeze']['full_original_contracts320_327'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'native_components_selected':False,'native_cases_run':0,'native_proofs_added':0,
        'runtime_authority':False,'actual_current_strong_safe_pause_confirmed':False}))
