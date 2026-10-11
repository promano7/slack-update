#!/usr/bin/env python3
"""Review supplied supervisor/clock/drain decisions only; no native operations."""
import hashlib
import json
import re
POLICY_SHA='face68b9ba4a57a9b095e81b7bcbea592db234592daba74ec9bac1fbe570e42c'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or canonical(value)!=canonical(expected):raise ValueError(label)
    return True
def validate_policy(p):return exact(canonical(p),POLICY_SHA,'authored382policy substitution')
def validate_acceptance(c,r,p):
    validate_policy(p);exact(canonical(c),p['confirmation_canonical_sha256'],'complete381confirmation')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete uploaded381receipt')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'unchanged381uploadedbytes');exact(len(raw),c['receipt_size_bytes'],'381size')
    text=r['text'];exact([s for s in text.splitlines() if s.startswith('PASS: ')],p['expected_ordered_PASS_labels381'],'all184ordered381labels')
    for marker in ['Result: PASS (184 passes, 0 failures)','step381_overlay_application_status\tPASS','step381_commit_scope_verification_status\tPASS',
                   '9 files changed, 3519 insertions(+)','[main 0f099fe] '+c['exact_commit_message'],'7820d1a..0f099fe  main -> main']:
        exact(text.count(marker),1,'exact single381marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),p['expected_created_paths381'],'exact381creates')
    head='0f099fe (HEAD -> main, origin/main, origin/HEAD) '+c['exact_commit_message']
    exact(text.split('7820d1a..0f099fe  main -> main',1)[1].strip().splitlines(),[head,head,'promano@pc-arch ~/Descargas $'],'reportedcleanmatchingheads')
    return True
def validate_baseline(blobs,addition,p):
    validate_policy(p);exact(sorted(blobs),sorted(p['baseline_sha256']),'all1977predecessorpaths')
    exact(sha(addition),p['changelog_addition_sha256'],'exact382prefix')
    for rel,digest in p['baseline_sha256'].items():
        raw=blobs[rel]
        if rel=='CHANGELOG.md':
            if not raw.startswith(addition):raise ValueError('additive382prefix')
            raw=raw[len(addition):]
        exact(sha(raw),digest,'whole accepted381bytes '+rel)
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
def validate_dossier(d,s,inputs,p):
    validate_policy(p);exact(canonical(d),p['dossier_canonical_sha256'],'whole supervisor clock drain dossier')
    exact(canonical(s),p['sources_canonical_sha256'],'primary register')
    f=json.loads(inputs['freeze378']);plan=json.loads(inputs['plan379'])
    exact(d['boundaries'],p['boundaries'],'closed native gates')
    for number,keys in [('323',['clock_contract','fence_contract','forward_contract','recovery_contract','closure_contract']),('324',['guard_contract']),('326',['model_contract','independent_conformance_contract'])]:
        original=f['full_original_contracts320_327'][number]['document']
        for key in keys:exact(d['original'+number+'_'+key],original[key],'whole'+number+' '+key)
    exact(d['original377_supervisor_conflict'],f['full_accepted377_unresolved_conflict_review'][2],'whole377 supervisor conflict')
    exact(d['original377_finite_time_conflict'],f['full_accepted377_unresolved_conflict_review'][5],'whole377 clock conflict')
    exact(d['original372_supervision_and_time_blockers'],[r for r in f['inherited372_feasibility_blockers'] if r['family_id'] in ['whole-descendant-supervision','trusted-finite-time']],'whole372 supervision and time blockers')
    exact([c['id'] for c in d['candidates']],p['candidate_ids'],'eight candidate identities')
    exact([r['id'] for r in d['adversarial_schedules']],p['schedule_ids'],'fourteen conditional schedules')
    exact(plan['pause_policy']['original_condition_ids'],p['original_pause_condition_ids'],'nine original conditions')
    return True
def review(d,s,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_inputs(inputs,sources,readme,p);validate_dossier(d,s,inputs,p)
    return json.loads(json.dumps({'step':382,'state':'repository-review-valid-user-acceptance-pending','dossier':d,
         'native_entry_blocked':True,'strong_safe_pause':False,'whole_input_bindings':p['whole_input_sha256'],
         'accepted_predecessor_commit_prefix':'0f099fe','full_commit_id_known':False}))
