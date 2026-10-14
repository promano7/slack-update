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
root=Path(sys.argv[1]);step='phase-1-operational-joint-trust-clock-guardian-drain-audit-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,audit,sources,policy=[load(s) for s in ['entry411','baseline','audit','sources','policy']]
module=runpy.run_path(str(root/'tools/reference'/(step+'.py')));passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label)
def rejects(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,IndexError,TypeError):return True
    return False
inputs={k:safe(v['path']) for k,v in sources['inputs'].items()}
rows=sources['inert_roots']+sources['reviewer_roots']+[sources['readme']]
blobs={r['path']:(safe(r['path'])[len(policy['prefixes']['README.md'].encode()):] if r['path']=='README.md' else safe(r['path'])) for r in rows}
check('whole authored412 fixtures bound',module['validate_fixtures']({'entry411':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual411 return64PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all121 whole inputs and38 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('whole trust clock guardian drain context34 paper challenges and open questions',module['validate_audit'](audit,inputs,sources,policy))
check('all2218 historical411 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={p.decode() for p in raw.split(b'\0') if p}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda a:a.update(schema=True)),
 ('option selected',lambda a:a.update(selected_options=['JCP400-A'])),
 ('migration approved',lambda a:a.update(approved_contract_migration={})),
 ('same-author audit made independent acceptance',lambda a:a.update(independent_impact_review_accepted=True)),
 ('native authority opened',lambda a:a.update(runtime_authority=True)),
 ('current pause self-confirmed',lambda a:a.update(current_strong_safe_pause=True)),
 ('unknown host made absent',lambda a:a['boundaries'].update(actual_host_state='absent')),
 ('global closure invented',lambda a:a['boundaries'].update(actual_global_host_closure=True)),
 ('native case invented',lambda a:a['boundaries'].update(native_cases_run=1)),
 ('whole source reference removed',lambda a:a['whole_input_references'].pop('trust401')),
 ('whole trust writer question removed',lambda a:a['whole_trust401_context']['all_domain_writer_class_questions'].pop()),
 ('whole source lifetime row removed',lambda a:a['whole_trust401_context']['whole_lifetime_hazard_reviews'].pop()),
 ('one full drain facet omitted',lambda a:a['whole_loss403_context']['seven_full_drain_requirements'].pop()),
 ('one loss role omitted',lambda a:a['whole_loss403_context']['proposed_loss_roles'].pop()),
 ('old410 finding omitted',lambda a:a['whole_accepted410_findings'].pop()),
 ('old411 question omitted',lambda a:a['whole_accepted411_findings'].pop()),
 ('clock clarification activated',lambda a:a['whole_accepted410_clarifications'][0].update(substitution_authorized=True)),
 ('one global rule waived',lambda a:a['whole_nine_global_semantic_rules'].pop('G403')),
 ('one paper challenge omitted',lambda a:a['paper_case_reviews'].pop()),
 ('past fact made current invariance',lambda a:a['paper_case_reviews'][16]['premise_projection'].update(past_facts_establish_current_invariance=True)),
 ('known drain renews expired rights',lambda a:a['paper_case_reviews'][19]['premise_projection'].update(known_drain_renews_rights=True)),
 ('role survival made full drain',lambda a:a['paper_case_reviews'][11]['premise_projection'].update(role_survival_establishes_full_drain=True)),
 ('role label made independence',lambda a:a['paper_case_reviews'][31]['premise_projection'].update(role_labels_establish_independence=True)),
 ('original failure erased',lambda a:a['paper_case_reviews'][30]['premise_projection'].update(original_forward_failed=False)),
 ('pending obligations erased',lambda a:a['paper_case_reviews'][30]['premise_projection'].update(pending_obligations_retained=False)),
 ('new question omitted',lambda a:a['new_findings'].pop()),
 ('paper premises made native proof',lambda a:a['interpretation_limit'].update(all_true_premises_prove_native_drain=True)),
 ('fresh explicit grant gate removed',lambda a:a['remaining_review_and_approval_order'].pop(2)),
 ('next step skips actual acceptance',lambda a:a.update(next_preparable_step_after_complete412_acceptance=414)),
 ('automatic419 permitted',lambda a:a.update(no_automatic419=False))]
for label,mutate in mutations:
    bad=copy.deepcopy(audit);mutate(bad);check('reject '+label,rejects(module['validate_audit'],bad,inputs,sources,policy))
byid={r['case']['id']:r['case'] for r in audit['paper_case_reviews']}
positive=byid['C01-original-fixed-mapping']
for key in module['FACET_IDS']:
    case=copy.deepcopy(positive);case['drain_facets'][key]=None
    result=module['premise_vector'](case)
    check('every original drain facet remains required '+key,result['drain_premises']['unknown_premises']==[key] and not result['drain_premises']['all_supplied_premises_true'] and result['pending_obligations_retained'] and not result['runtime_authority'])
for key in module['RIGHT_IDS']:
    case=copy.deepcopy(positive);case['current_right_constraints'][key]=False
    result=module['premise_vector'](case)
    check('failed original right cannot be supplied by known drain '+key,result['current_right_premises']['false_premises']==[key] and result['drain_premises']['all_supplied_premises_true'] and not result['known_drain_renews_rights'] and not result['runtime_authority'])
for key in module['ROLE_IDS']:
    case=copy.deepcopy(positive);case['reported_role_survival'][key]=False
    result=module['premise_vector'](case)
    check('loss role does not mint replacement control '+key,result['reported_role_survival'][key] is False and not result['role_survival_establishes_full_drain'] and not result['role_labels_establish_independence'] and not result['runtime_authority'])
r=module['premise_vector'](byid['X01-failure-mismatch-pending'])
check('original failure mismatch past fact and pending preserved together',r['original_forward_failed'] is True and r['original_mismatch'] is True and r['qualified_past_fact']=='hypothetical-qualified-original-mismatch' and r['pending_obligations_retained'])
r=module['premise_vector'](byid['C02-expiry-after-known-drain'])
check('known past drain survives expiry without renewed rights',r['qualified_past_fact']=='hypothetical-qualified-complete-drain-at-original-cut' and r['current_right_premises']['false_premises']==['within-original-deadline'] and not r['known_drain_renews_rights'])
r=module['premise_vector'](byid['C04-resume-gate-async-pending'])
check('resume gate leaves async storage and elapsed accounting unknown','all-inflight-storage-effects-drained' in r['drain_premises']['unknown_premises'] and 'clock-and-suspend-elapsed-accounting-known' in r['current_right_premises']['unknown_premises'] and r['pending_obligations_retained'])
case=copy.deepcopy(positive);case['drain_facets'][module['FACET_IDS'][0]]=1
check('reject integer as boolean membership premise',rejects(module['premise_vector'],case))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual411 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['trust401']+=b' '
check('reject whole trust source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['all_true_premises_prove_native_drain']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('prepared result has34 paper challenges no native rights or current pause',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure reader imports only hashlib json re without native dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
