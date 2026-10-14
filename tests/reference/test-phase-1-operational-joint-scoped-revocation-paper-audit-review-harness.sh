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
root=Path(sys.argv[1]);step='phase-1-operational-joint-scoped-revocation-paper-audit-review'
def safe(rel):
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe input '+rel)
    return p.read_bytes()
def load(suffix):return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/'+step+'-'+suffix+'.json'))
entry,baseline,audit,sources,policy=[load(s) for s in ['entry410','baseline','audit','sources','policy']]
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
check('whole authored411 fixtures bound',module['validate_fixtures']({'entry410':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual410 return69PASS exact commit push clean matching heads',module['validate_entry'](entry,inputs,policy))
check('all117 whole inputs and37 roots; native roots inert',module['validate_sources'](inputs,blobs,sources,policy))
check('whole scoped revocation context36 paper cases old findings and two open questions',module['validate_audit'](audit,inputs,sources,policy))
check('all2210 historical410 bodies unchanged except exact additive prefixes',module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={p.decode() for p in raw.split(b'\0') if p}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda a:a.update(schema=True)),
 ('option selected',lambda a:a.update(selected_options=['JCP400-A'])),
 ('migration approved',lambda a:a.update(approved_contract_migration={})),
 ('independent impact acceptance invented',lambda a:a.update(independent_impact_review_accepted=True)),
 ('native authority opened',lambda a:a.update(runtime_authority=True)),
 ('native evidence invented',lambda a:a.update(actual_native_evidence={})),
 ('current pause self-confirmed',lambda a:a.update(current_strong_safe_pause=True)),
 ('unknown host made absent',lambda a:a['boundaries'].update(actual_host_state='absent')),
 ('global closure invented',lambda a:a['boundaries'].update(actual_global_host_closure=True)),
 ('old finding removed',lambda a:a['whole_accepted410_findings'].pop()),
 ('old clarification silently activated',lambda a:a['whole_accepted410_clarifications'][0].update(substitution_authorized=True)),
 ('whole original clause shortened',lambda a:a['whole_current323_fence_forward_recovery_closure']['recovery_contract'].update(validity='short')),
 ('full402 envelope requirement omitted',lambda a:a['whole_operation402_context']['complete_operation_envelope_requirements']['required_before_any_future_admission'].pop()),
 ('one global rule omitted',lambda a:a['whole_nine_global_semantic_rules'].pop('R402')),
 ('paper namespace selected as native policy',lambda a:a['paper_scope_interpretation'].update(actual_issuer_format_selected=True)),
 ('one paper case omitted',lambda a:a['cases'].pop()),
 ('case order changed',lambda a:a['cases'].reverse()),
 ('known failure erased',lambda a:a['cases'][12]['reading'].update(original_forward_failed=False)),
 ('pending state erased',lambda a:a['cases'][12]['reading'].update(pending_obligations_retained=False)),
 ('paper positive made native authority',lambda a:a['cases'][2]['reading'].update(runtime_authority=True)),
 ('request made full drain',lambda a:a['cases'][2]['reading'].update(request_or_return_proves_full_drain=True)),
 ('unknown recast as no-effect',lambda a:a['cases'][3]['reading'].update(unknown_means_no_effect=True)),
 ('new specification question omitted',lambda a:a['new_findings'].pop()),
 ('original publication policy invented',lambda a:a['interpretation_limit'].update(actual_original_publication_policy_selected=True)),
 ('native gate claimed from paper reader',lambda a:a['interpretation_limit'].update(reader_is_native_admission_gate=True)),
 ('full1286 semantic acceptance invented',lambda a:a['interpretation_limit'].update(all1286_member_semantics_independently_accepted=True)),
 ('fresh native grant gate omitted',lambda a:a['remaining_review_and_approval_order'].pop(2)),
 ('next step skips acceptance',lambda a:a.update(next_preparable_step_after_complete411_acceptance=413)),
 ('automatic419 permitted',lambda a:a.update(no_automatic419=False))]
for label,mutate in mutations:
    bad=copy.deepcopy(audit);mutate(bad);check('reject '+label,rejects(module['validate_audit'],bad,inputs,sources,policy))
byid={r['case']['id']:r['case'] for r in audit['cases']}
expected={
 'F02-request-denies-new':'paper-denied-dependent-effect-or-admission',
 'F03-known-pre-request-envelope':'paper-consider-known-pre-request-finite-envelope-only',
 'F04-unknown-request-order':'paper-pending-unproved-dependent-effect',
 'F05-expired-pre-request-envelope':'paper-denied-dependent-effect-or-admission',
 'F09-outside-original-envelope':'paper-denied-dependent-effect-or-admission',
 'R01-forward-only-not-recovery-request':'paper-consider-original-envelope-without-applicable-request',
 'R02-recovery-all-pre-request-envelope':'paper-consider-known-pre-request-finite-envelope-only',
 'R05-backup-unknown':'paper-pending-unproved-dependent-effect',
 'R06-lost-restore-ACK-never-repeat':'paper-denied-dependent-effect-or-admission',
 'E01-target-evidence-is-recovery-scope':'paper-consider-known-pre-request-finite-envelope-only',
 'E02-publication-controls-not-recovery-right':'paper-denied-dependent-effect-or-admission',
 'P01-target-all-not-publication-authority':'paper-consider-original-envelope-without-applicable-request',
 'P02-own-publication-request-pre-admitted':'paper-consider-known-pre-request-finite-envelope-only',
 'P03-own-publication-request-denies-new':'paper-denied-dependent-effect-or-admission',
 'P04-own-publication-controls-unknown':'paper-pending-unproved-dependent-effect',
 'P06-forbidden-post-release-target-read':'paper-denied-dependent-effect-or-admission',
 'P08-unknown-request-namespace':'paper-pending-unproved-dependent-effect'}
for id_,result in expected.items():check('paper boundary '+id_,module['paper_reading'](byid[id_])['candidate_clause_projection']==result)
r=module['paper_reading'](byid['F13-known-failure-plus-unknown-request'])
check('failure mismatch and pending survive together without authority',r['original_forward_failed'] is True and r['original_mismatch'] is True and r['pending_obligations_retained'] and not r['runtime_authority'])
check('unknown request applicability remains null not unrelated false',r['request_applies_in_paper_namespace'] is None)
r=module['paper_reading'](byid['P07-custody-unknown-retains-target-fact'])
check('qualified captured fact survives unknown custody and sticky original failure',r['qualified_captured_fact']=='hypothetically-qualified-original-target-match' and r['original_forward_failed'] is True and r['pending_obligations_retained'])
case=copy.deepcopy(byid['F03-known-pre-request-envelope']);case['facts']['within_original_deadline']=1
check('reject integer as boolean deadline premise',rejects(module['paper_reading'],case))
case=copy.deepcopy(byid['F03-known-pre-request-envelope']);case['original_forward_failed']=None
check('unknown forward status cannot become known no-failure',module['paper_reading'](case)['candidate_clause_projection']=='paper-pending-unproved-dependent-effect')
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual410 receipt',rejects(module['validate_entry'],bad,inputs,policy))
bad=dict(inputs);bad['original323']+=b' '
check('reject original source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_interpretation_limit']['reader_is_native_admission_gate']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('review output has36 paper cases and no actual authority proof or pause',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'));imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};forbidden={'open','exec','eval','input','compile','__import__'}
check('pure supplied-data reader imports only hashlib json re without dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
