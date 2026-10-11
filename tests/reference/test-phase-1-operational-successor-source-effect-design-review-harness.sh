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
import runpy
import sys

root=Path(sys.argv[1]);name='phase-1-operational-successor-source-effect-design-review'
f=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(name+'.py')
m=runpy.run_path(str(tool));passes=0
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((f/(name+'-'+tail+'.json')).read_bytes())
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError):return True
    return False
p=load('policy');design=load('design');c=load('confirmed369');r=load('step369-user-acceptance')
check('authored370 policy independently frozen',m['validate_policy'](p))
check('all1889 accepted369 baseline files bound',len(p['baseline_sha256'])==p['accepted_source_count']==1889)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted path: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted369 drift: '+rel)
    history[rel]=raw
check('all accepted369 bytes exact with additive CHANGELOG only',len(history)==1889)
check('full pasted369 message and report-based confirmation validate',m['validate_acceptance'](c,r,p))
check('all89 exact ordered predecessor PASS labels retained',len(p['accepted369_contract']['expected_ordered369_labels'])==89)
check('reported369 is accepted not a new pause or invented fullID',c['commit_prefix']=='3a99d10' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368)
check('pasted-message transcription and storage-newline limitation explicit','transcribed-UTF8-with-final-storage-newline' in r['capture_basis'] and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for key,path in p['input_paths'].items():
    check('full input byte and canonical binding '+key,sha(history[path])==p['input_file_sha256'][key] and m['canonical'](inputs[key])==p['input_canonical_sha256'][key])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('full frozen inputs and exact four historical source roles',m['validate_inputs'](inputs,sources,readme,p))
check('complete proposed successor design validates',m['validate_design'](design,inputs,sources,p))
check('nine responsibilities unselected and not bound processes',len(design['roles'])==9 and all(x['actual_component'] is None and x['actual_implementation_bytes'] is None and not x['execution_authorized'] for x in design['roles']))
check('eight draft interfaces grant no channel capability or event proof',len(design['interfaces'])==8 and all(x['actual_channel_or_descriptor'] is None and not x['current_capability_granted'] and not x['native_order_or_reachability_proven'] for x in design['interfaces']))
check('ten full-graph admission rules all remain unsatisfied natively',len(design['graph_admission_rules'])==10 and all(x['native_satisfied'] is False for x in design['graph_admission_rules']))
check('seven ordering questions do not redefine original stages',len(design['proposed_order_requirements'])==7 and not design['design_milestones_redefine_original_stages'] and all(x['actual_native_event_relation'] is None for x in design['proposed_order_requirements']))
check('all21 selected effect domains retain whole original binding',len(design['source_effect_treatments'])==21 and [x['id'] for x in design['source_effect_treatments']]==[x['id'] for x in inputs['effects']['effect_domains']])
for row,original in zip(design['source_effect_treatments'],inputs['effects']['effect_domains']):
    valid=m['canonical'](original)==row['full_original_domain_canonical_sha256'] and row['full_original_source_anchors']==original['source_anchors']
    for item in row['full_original_source_anchors']:
        a=item['anchor'];raw=sources[a['path']];lines=raw.splitlines(keepends=True);line=a['line_number'];start=a['line_start_byte'];length=a['line_length_bytes']
        valid=valid and type(line) is int and type(start) is int and type(length) is int and raw[start:start+length]==lines[line-1]==a['full_line_text'].encode() and start==sum(map(len,lines[:line-1])) and sha(lines[line-1])==a['raw_line_sha256'] and sha(raw)==a['source_sha256']
    check('independent whole source-anchor geometry '+row['id'],valid)
check('all12 original dependency families and24 separate unbound platform records',len(design['dependency_family_requirements'])==12 and sum(len(x['platform_inputs']) for x in design['dependency_family_requirements'])==24 and all(x['actual_version'] is None and x['actual_object_bytes'] is None and not x['native_proof'] for f in design['dependency_family_requirements'] for x in f['platform_inputs']))
check('supplementalcksum exact without changing original363 register',design['supplemental_cksum']['full_original_supplemental_inputs']==freeze['supplemental_external_inputs365'] and not design['supplemental_cksum']['changes_accepted363_register'] and design['supplemental_cksum']['native_binding'] is None)
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:
    check('complete original normative scope '+key,len(freeze[key])==count)
check('three primary assignments do not waive all16 native gaps',len(design['primary_gap_ids'])==3 and design['all_full_original_requirements_normative'] and not design['native_graph_complete'])
check('README377 conditionalpause378 no automatic379 unchanged',design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'] and sha(readme)==p['readme_at_entry_sha256'])
for field,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('native_cases_run',1),('native_proofs_added',1),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False)]:
    bad=copy.deepcopy(c);bad[field]=value;check('reject invented369 '+field,rejected(m['validate_acceptance'],bad,r,p))
for label,edit in [('truncated predecessor message',lambda x:x[:-1]),('same-length predecessor edit',lambda x:x.replace('3a99d10','3a99d11',1)),('injected dirty status',lambda x:x.replace('3a99d10 (HEAD',' M README.md\n3a99d10 (HEAD',1))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='original-independent-terminal-bytes';check('reject invented independent capture',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed complete frozen input '+key,rejected(m['validate_inputs'],bad,sources,readme,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject review source drift',rejected(m['validate_inputs'],inputs,bad,readme,p))
bad=dict(sources);bad['extra.sh']=b'claimed';check('reject extra operational review root',rejected(m['validate_inputs'],inputs,bad,readme,p))
check('reject premature README edit',rejected(m['validate_inputs'],inputs,sources,readme+b'\n',p))
for label,mutate in [('missing role',lambda x:x['roles'].pop()),('worker broker channel',lambda x:x['interfaces'][1].update(proposed_interface='online worker broker/RPC')),('actual component selection',lambda x:x['roles'][0].update(actual_component='service')),('actual interface descriptor',lambda x:x['interfaces'][0].update(actual_channel_or_descriptor=9)),('actual native event proof',lambda x:x['interfaces'][0].update(native_order_or_reachability_proven=True)),('current capability grant',lambda x:x['interfaces'][0].update(current_capability_granted=True)),('unreachable optional branch claimed proven',lambda x:x['source_effect_treatments'][10].update(native_exclusion_proven=True)),('missing effect domain',lambda x:x['source_effect_treatments'].pop()),('missing dependency family',lambda x:x['dependency_family_requirements'].pop()),('collapsed platform records',lambda x:x['dependency_family_requirements'][0]['platform_inputs'].pop()),('fake native backend bytes',lambda x:x['dependency_family_requirements'][1]['platform_inputs'][0].update(actual_object_bytes='claimed')),('source anchors abbreviated',lambda x:x['source_effect_treatments'][0]['full_original_source_anchors'].pop()),('first preparation writes omitted',lambda x:x['source_effect_treatments'][14].update(design_requirement='workspace first')),('late target reads allowed',lambda x:x['source_effect_treatments'][18].update(design_requirement='reopen target during publication')),('generic exit0 made sufficient',lambda x:x['source_effect_treatments'][7].update(design_requirement='exit0 means complete')),('historical generator made successor',lambda x:x['source_effect_treatments'][19].update(design_requirement='replay historical generator')),('cksum register rewritten',lambda x:x['supplemental_cksum'].update(changes_accepted363_register=True)),('complete graph claimed',lambda x:x.update(native_graph_complete=True)),('operational source implementation claimed',lambda x:x.update(operational_implementation_written=True)),('original stage rewrite',lambda x:x.update(design_milestones_redefine_original_stages=True)),('draft graph claimed actual shell graph',lambda x:x.update(design_graph_is_actual_shell_call_graph=True)),('normative scope waived',lambda x:x.update(all_full_original_requirements_normative=False)),('native proof added',lambda x:x.update(native_proofs_added=1)),('native case run',lambda x:x.update(native_cases_run=1)),('premature final pause',lambda x:x.update(conditional_pause_step=370)),('bool schema',lambda x:x.update(schema=True))]:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,sources,p))
for key,value in [('runtime_authority',True),('machine_action_required',True),('controller_action_required',True),('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('actual_host_state','absent'),('actual_global_host_closure',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True)]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject boundary promotion '+key,rejected(m['validate_design'],bad,inputs,sources,p))
anchor=next(item['anchor'] for row in design['source_effect_treatments'] for item in row['full_original_source_anchors'])
check('standalone anchor validates actual full source geometry',m['validate_anchor'](anchor,sources))
for key,value in [('line_number',True),('line_number',-1),('line_start_byte',True),('line_start_byte',-1),('line_length_bytes',0),('line_length_bytes',True),('line_start_byte',len(sources[anchor['path']])),('raw_line_sha256','0'*64),('source_sha256','0'*64),('full_line_text','invented\n')]:
    bad=copy.deepcopy(anchor);bad[key]=value;check('reject invalid anchor '+key+' '+str(value)[:20],rejected(m['validate_anchor'],bad,sources))
bad=copy.deepcopy(p);bad['input_canonical_sha256']['freeze']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report carries full original contracts and normative gaps',out['full_original_contracts320_327']==freeze['full_original_contracts320_327'] and out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'])
out['design']['roles'][0]['actual_component']='claimed';out['full_original_native_gap_rows348'].pop();out['boundaries']['runtime_authority']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('returned data detached from caller and frozen report expectations',again['design']['roles'][0]['actual_component'] is None and len(again['full_original_native_gap_rows348'])==16 and not again['boundaries']['runtime_authority'] and design['roles'][0]['actual_component'] is None)
check('historical361 limitations retained as whole immutable input',m['canonical'](inputs['controls361'])==p['input_canonical_sha256']['controls361'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem source execution decode network or spawn entry',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
