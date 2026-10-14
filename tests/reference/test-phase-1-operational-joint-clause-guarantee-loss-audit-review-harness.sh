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
step = 'phase-1-operational-joint-clause-guarantee-loss-audit-review'
def safe(rel):
    p = root / rel
    if not p.is_file() or p.is_symlink() or p.resolve() != p.absolute() or not p.resolve().is_relative_to(root):
        raise ValueError('unsafe repository input ' + rel)
    return p.read_bytes()
def load(suffix):
    return json.loads(safe('tests/fixtures/reference/acceptance/phase-1/' + step + '-' + suffix + '.json'))
entry, baseline, audit, sources, policy = [load(s) for s in ['entry409','baseline','audit','sources','policy']]
module = runpy.run_path(str(root/'tools/reference'/(step+'.py')))
passes = 0
def check(label, value):
    global passes
    if not value:raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)
def rejects(fn, *args):
    try:fn(*args)
    except (ValueError, KeyError, IndexError, TypeError):return True
    return False
inputs = {k:safe(v['path']) for k,v in sources['inputs'].items()}
rows = sources['inert_roots']+sources['reviewer_roots']+[sources['readme']]
blobs = {r['path']:(safe(r['path'])[len(policy['prefixes']['README.md'].encode()):] if r['path']=='README.md' else safe(r['path'])) for r in rows}
check('whole authored410 fixtures bound', module['validate_fixtures']({'entry409':entry,'baseline':baseline,'audit':audit,'sources':sources},policy))
check('complete actual409 return61PASS exact commit push clean matching heads', module['validate_entry'](entry,inputs,policy))
check('all113 whole inputs and36 roots retained; native roots inert', module['validate_sources'](inputs,blobs,sources,policy))
check('all14 whole clauses four assumptions complete losses eight views and seven findings', module['validate_audit'](audit,inputs,sources,policy))
check('eight whole patch views derived from exact declared replacements only', module['validate_patch_views'](audit['whole_eight_current_and_inactive_patch_views'],[r['whole_frozen_replacement'] for r in audit['clause_reviews']],inputs))
check('all2202 historical409 paths unchanged except exact additive prefixes', module['validate_repository']({p:safe(p) for p in baseline},baseline,policy))
if (root/'.git').exists():
    raw = subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout
    actual = {p.decode() for p in raw.split(b'\0') if p}
else:
    actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus README and CHANGELOG', actual==set(baseline)|set(policy['new_paths']))
mutations = [
    ('boolean schema',lambda a:a.update(schema=True)),
    ('step411 substituted',lambda a:a.update(step=411)),
    ('option selected by audit',lambda a:a.update(selected_options=['JCP400-A'])),
    ('joint specification approved',lambda a:a.update(approved_joint_specification={})),
    ('migration approved',lambda a:a.update(approved_contract_migration={})),
    ('native graph invented',lambda a:a.update(actual_joint_native_graph={})),
    ('actual evidence invented',lambda a:a.update(actual_native_evidence={})),
    ('same-author audit made independent acceptance',lambda a:a.update(independent_impact_review_accepted=True)),
    ('whole migration completed',lambda a:a.update(semantic_migration_complete=True)),
    ('native case invented',lambda a:a['boundaries'].update(native_cases_run=1)),
    ('unknown host made absent',lambda a:a['boundaries'].update(actual_host_state='absent')),
    ('global closure invented',lambda a:a['boundaries'].update(actual_global_host_closure=True)),
    ('original norms waived',lambda a:a.update(whole_original_requirements_remain_normative=False)),
    ('whole current clause shortened',lambda a:a['clause_reviews'][0]['whole_frozen_replacement'].update(whole_current_value='short')),
    ('candidate clause weakened',lambda a:a['clause_reviews'][7]['whole_frozen_replacement'].update(complete_proposed_value='restore may repeat')),
    ('one exact amendment omitted',lambda a:a['clause_reviews'].pop()),
    ('local review waives other global rules',lambda a:a['clause_reviews'][5].update(all_nine_global_rules_apply=False)),
    ('paper challenge made native observation',lambda a:a['clause_reviews'][2].update(native_observation={})),
    ('recovery loss hidden in annotation',lambda a:a['clause_reviews'][7]['complete_annotation'].update(candidate_reading='unchanged recovery equivalence')),
    ('ordinary root workload exempted',lambda a:a['clause_reviews'][1]['complete_annotation'].update(candidate_reading='root helpers are trusted and exempt')),
    ('uncertain admission treated no-effect',lambda a:a['clause_reviews'][3]['complete_annotation'].update(candidate_reading='unknown means no effect')),
    ('safe cut label made proven drain',lambda a:a['clause_reviews'][6]['complete_annotation'].update(candidate_reading='backend exit proves drain')),
    ('one companion assumption omitted',lambda a:a['companion_assumption_reviews'].pop()),
    ('hidden clock tamper detection promised',lambda a:a['companion_assumption_reviews'][1].update(whole_assumption='hidden rollback always detected')),
    ('additional recovery loss omitted',lambda a:a['whole_complete_guarantee_loss_register']['whole402_additional_forward_recovery_publication_losses'].pop(1)),
    ('stage membership loss omitted',lambda a:a['whole_complete_guarantee_loss_register']['whole405_394_stage_terminal_changed_guarantees'].pop()),
    ('one global rule omitted',lambda a:a['whole_nine_global_semantic_rules'].pop('R402')),
    ('whole stage12 shortened',lambda a:a['whole_stage12_comparison']['complete_proposed_value'].update(operation='producer is complete publication')),
    ('current contract view omitted',lambda a:a['whole_eight_current_and_inactive_patch_views'].pop()),
    ('unamended current proof text altered',lambda a:a['whole_eight_current_and_inactive_patch_views'][0]['whole_current_document'].update(schema=999)),
    ('patch view declared native protocol',lambda a:a['whole_eight_current_and_inactive_patch_views'][3].update(patch_view_is_complete_native_protocol=True)),
    ('one authored finding removed',lambda a:a['findings'].pop()),
    ('finding current wording shortened',lambda a:a['findings'][0]['whole_clause_source_bindings'][0].update(whole_current_value='short')),
    ('finding status silently resolved',lambda a:a['findings'][3].update(independent_impact_acceptance=True)),
    ('native proof invented from paper finding',lambda a:a['findings'][5].update(native_proof=True)),
    ('clock clarification silently substituted',lambda a:a['proposed_clarifications'][0].update(substitution_authorized=True)),
    ('publication clarification made native grant',lambda a:a['proposed_clarifications'][1].update(native_authority=True)),
    ('clarification hides original wording',lambda a:a['proposed_clarifications'][0].pop('whole_original_frozen_replacement')),
    ('all findings resolved invented',lambda a:a.update(all_semantic_findings_resolved=True)),
    ('full1286 semantic acceptance inferred',lambda a:a['comparison_limit'].update(all1286_member_semantics_independently_accepted=True)),
    ('native effect before fresh explicit grant',lambda a:a['remaining_review_and_approval_order'].pop(2)),
    ('next step skips acceptance',lambda a:a.update(next_preparable_step_after_complete410_acceptance=412)),
    ('current pause self-confirmed',lambda a:a.update(current_strong_safe_pause=True)),
    ('automatic419 permitted',lambda a:a.update(no_automatic419=False)),
]
for label, mutate in mutations:
    altered=copy.deepcopy(audit);mutate(altered)
    check('reject '+label,rejects(module['validate_audit'],altered,inputs,sources,policy))
for index,view in enumerate(audit['whole_eight_current_and_inactive_patch_views']):
    single=copy.deepcopy(audit['whole_eight_current_and_inactive_patch_views'])
    single[index]['inactive_exact_clause_patch_view']['schema']=999
    check('reject undeclared patch in original'+str(320+index),rejects(module['validate_patch_views'],single,[r['whole_frozen_replacement'] for r in audit['clause_reviews']],inputs))
for label,mutate in [
    ('truncated actual409 receipt',lambda e:e['receipt'].update(text=e['receipt']['text'][:-1])),
    ('full user Git ID invented',lambda e:e['confirmation'].update(commit_full='0'*40)),
    ('intermediate409 made strong pause',lambda e:e['confirmation'].update(new_strong_safe_pause_confirmed=True)),
    ('historical whole408 entry rebound',lambda e:e['whole_confirmed408_entry_reference'].update(sha256='0'*64)),
]:
    altered=copy.deepcopy(entry);mutate(altered)
    check('reject '+label,rejects(module['validate_entry'],altered,inputs,policy))
bad=dict(inputs);bad['original323']+=b' '
check('reject original source byte drift',rejects(module['validate_sources'],bad,blobs,sources,policy))
bad=copy.deepcopy(policy);bad['expected_clarifications'][0]['substitution_authorized']=True
check('reject coordinated authored policy substitution',rejects(module['validate_policy'],bad))
check('review output preserves seven findings two inactive drafts and closed authority',module['review'](entry,audit,inputs,blobs,sources,policy)==policy['expected_review_result'])
tree=ast.parse(safe('tools/reference/'+step+'.py'))
imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
forbidden={'open','exec','eval','input','compile','__import__'}
check('reviewer imports only supplied-data libraries with no dynamic dispatch',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) or (isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in forbidden) for n in ast.walk(tree)))
for path,digest in policy['artifact_sha256'].items():check('exact authored artifact '+path,module['sha'](safe(path))==digest)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
