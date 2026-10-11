#!/usr/bin/env python3
"""Review supplied whole stage12/external receipt causality decisions only; no native operations."""
import hashlib
import json
import re
POLICY_SHA='5a84bee31be704f1c50b4f294cdc896f0408e3e7e565b7af0526729560f23275'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or canonical(value)!=canonical(expected):raise ValueError(label)
    return True
def validate_policy(p):return exact(canonical(p),POLICY_SHA,'authored384policy substitution')
def validate_acceptance(c,r,p):
    validate_policy(p);exact(canonical(c),p['confirmation_canonical_sha256'],'complete383confirmation')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete uploaded383receipt')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'unchanged383uploadedbytes');exact(len(raw),c['receipt_size_bytes'],'383size')
    text=r['text'];exact([s for s in text.splitlines() if s.startswith('PASS: ')],p['expected_ordered_PASS_labels383'],'all239ordered383labels')
    for marker in ['Result: PASS (239 passes, 0 failures)','step383_overlay_application_status\tPASS','step383_commit_scope_verification_status\tPASS',
                   '9 files changed, 4597 insertions(+)','[main 45f463f] '+c['exact_commit_message'],'6c65757..45f463f  main -> main']:
        exact(text.count(marker),1,'exact single383marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),p['expected_created_paths383'],'exact383creates')
    head='45f463f (HEAD -> main, origin/main, origin/HEAD) '+c['exact_commit_message']
    exact(text.split('6c65757..45f463f  main -> main',1)[1].strip().splitlines(),[head,head,'promano@pc-arch ~/Descargas $'],'reportedcleanmatchingheads')
    return True
def validate_baseline(blobs,addition,p):
    validate_policy(p);exact(sorted(blobs),sorted(p['baseline_sha256']),'all1993predecessorpaths')
    exact(sha(addition),p['changelog_addition_sha256'],'exact384prefix')
    for rel,digest in p['baseline_sha256'].items():
        raw=blobs[rel]
        if rel=='CHANGELOG.md':
            if not raw.startswith(addition):raise ValueError('additive384prefix')
            raw=raw[len(addition):]
        exact(sha(raw),digest,'whole accepted383bytes '+rel)
    return True
def validate_inputs(inputs,sources,readme,p):
    validate_policy(p);exact(sorted(inputs),sorted(p['whole_input_paths']),'whole original input set')
    for key,raw in inputs.items():
        exact(sha(raw),p['whole_input_sha256'][key],'wholebyte '+key)
        exact(canonical(json.loads(raw)),p['whole_input_canonical_sha256'][key],'wholecanonical '+key)
    f=json.loads(inputs['freeze378']);exact(sorted(sources),sorted(r['path'] for r in f['review_sources']),'four inert roots')
    for row in f['review_sources']:exact(sha(sources[row['path']]),row['sha256'],'inertsource '+row['path'])
    exact(sha(readme),p['baseline_sha256']['README.md'],'exact README')
    return True
def has_cycle(edges):
    # Supplied paper dependencies only; no native event or clock observation.
    if type(edges) is not list:raise ValueError('edge list')
    graph={}
    for edge in edges:
        if type(edge) is not list or len(edge)!=2 or any(type(v) is not str or not v for v in edge):raise ValueError('edge schema')
        graph.setdefault(edge[0],[]).append(edge[1]);graph.setdefault(edge[1],[])
    colors={}
    def visit(node):
        if colors.get(node)==1:return True
        if colors.get(node)==2:return False
        colors[node]=1
        if any(visit(n) for n in graph[node]):return True
        colors[node]=2;return False
    return any(visit(n) for n in graph)
def validate_dossier(d,s,inputs,p):
    validate_policy(p);exact(canonical(d),p['dossier_canonical_sha256'],'whole stage12 external receipt causality dossier')
    exact(canonical(s),p['sources_canonical_sha256'],'primary register')
    f=json.loads(inputs['freeze378']);plan=json.loads(inputs['plan379'])
    exact(d['boundaries'],p['boundaries'],'closed native gates')
    for number,keys in p['original_contract_keys'].items():
        original=f['full_original_contracts320_327'][number]['document']
        for key in keys:exact(d['original'+number+'_'+key],original[key],'whole'+number+' '+key)
    original316=json.loads(inputs['publication_requirements316'])
    exact(d['original316_whole_stage12'],next(r for r in original316['immutable_design_facts']['stages'] if r['index']==12),'whole original stage12')
    for number in ['374','375']:
        original=json.loads(inputs['design'+number])
        for key in p['original'+number+'_review_keys']:exact(d['original'+number+'_'+key],original[key],'whole'+number+' '+key)
    exact(d['original377_whole_stage12_conflict'],f['full_accepted377_unresolved_conflict_review'][6],'whole377 stage12 conflict')
    for row in d['conditional_dependency_questions']:
        exact(has_cycle(row['edges']),row['expected_cycle'],'conditional dependency cycle '+row['id'])
        exact(row['actual_native_graph'],None,'actual graph unselected')
        exact(row['original_stage12_reconciled'],False,'whole stage12 not proven')
    exact([c['id'] for c in d['candidates']],p['candidate_ids'],'eight candidate identities')
    exact([r['id'] for r in d['adversarial_schedules']],p['schedule_ids'],'fourteen conditional schedules')
    exact(plan['pause_policy']['original_condition_ids'],p['original_pause_condition_ids'],'nine original conditions')
    return True
def review(d,s,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_inputs(inputs,sources,readme,p);validate_dossier(d,s,inputs,p)
    return json.loads(json.dumps({'step':384,'state':'repository-review-valid-user-acceptance-pending','dossier':d,
         'native_entry_blocked':True,'strong_safe_pause':False,'whole_input_bindings':p['whole_input_sha256'],
         'accepted_predecessor_commit_prefix':'45f463f','full_commit_id_known':False}))
