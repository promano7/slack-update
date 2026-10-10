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

root=Path(sys.argv[1]);name='phase-1-operational-external-dependency-register';prior='phase-1-operational-entrypoint-callsite-review'
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
policy=load('policy');confirmed=load('confirmed362');receipt=load('step362-user-acceptance');stored=load('register')
check('all1838 accepted362 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1838)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted362 bytes exact with additive CHANGELOG only',len(history)==1838)
check('external confirmed362 bytes exact',sha((fixture/(name+'-confirmed362.json')).read_bytes())==policy['expected_confirmation_sha256'])
check('complete362 receipt and report-based confirmation validate',m['validate_acceptance'](receipt,confirmed))
text=receipt['text'];raw=text.encode();message=policy['accepted_commit_message'];head='aff8592 (HEAD -> main, origin/main, origin/HEAD) '+message
check('all87 exact ordered362 labels and zero-failure summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered362_labels'] and text.count('Result: PASS (87 passes, 0 failures)')==1)
check('reported362 exact eight-file commit and seven created paths',text.count('[main aff8592] '+message)==1 and text.count('8 files changed, 23359 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step362_created_paths'])
check('reported362 push clean status and matching heads',text.count('633b524..aff8592  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'))
check('receipt SHA size and original-capture limitation retained',sha(raw)==policy['accepted_receipt_sha256']==receipt['sha256'] and len(raw)==policy['accepted_receipt_size_bytes']==receipt['size_bytes'] and receipt['capture_basis']=='complete-user-message-text-transcribed-as-UTF8-with-final-storage-newline;not-original-terminal-byte-capture')
check('accepted362 is not a new pause or invented full commit',confirmed['commit_prefix']=='aff8592' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
for field,value in [('strong_safe_pause',True),('commit_full','aff8592'+'0'*33),('runtime_authority',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('native_cases_run',1),('native_proofs_added',1),('user_worktree_clean',False),('user_head_matches_origin',False),('phase1_matrix_complete',True),('kernel_package_edge_complete',True),('production_entry_closed',False),('phase2_open',True)]:
    bad=copy.deepcopy(confirmed);bad[field]=value;check('reject changed362 confirmation '+field,rejected(m['validate_acceptance'],receipt,bad))
for label,edit in [('truncated receipt',lambda x:x[:-1]),('same-length edited receipt',lambda x:x.replace('aff8592','aff8593',1)),('injected status output',lambda x:x.replace(head,' M README.md\n'+head,1))]:
    bad=copy.deepcopy(receipt);bad['text']=edit(text);check('reject '+label,rejected(m['validate_acceptance'],bad,confirmed))
bad=copy.deepcopy(receipt);bad['capture_basis']='original-terminal-byte-capture';check('reject invented original terminal capture',rejected(m['validate_acceptance'],bad,confirmed))
check('exact four review source descriptors remain closed',m['SOURCE_BINDINGS']==policy['source_roots'] and all(not row['execution_authorized'] and row['actual_native_binding'] is None for row in m['SOURCE_BINDINGS']))
inventory=json.loads(history[policy['inventory_path']]);review=json.loads(history[policy['review_path']]);gap_data=json.loads(history[policy['native_gap_path']]);gap_rows=gap_data['full_original_native_gap_rows348'];sources={row['path']:history[row['path']] for row in policy['source_roots']}
check('full15106 inventory exact binding preserved',sha(history[policy['inventory_path']])==policy['inventory_sha256'] and m['canonical'](inventory)==policy['inventory_canonical_sha256']==m['INVENTORY_SHA'] and len(inventory['hint_records'])==15106)
check('full362 entry-callsite context review exact binding preserved',sha(history[policy['review_path']])==policy['review_sha256'] and m['canonical'](review)==policy['review_canonical_sha256']==m['REVIEW_SHA'] and len(review['selected_sites'])==65)
check('full original16 native gap rows canonical binding exact',m['canonical'](gap_rows)==policy['native_gap_rows_canonical_sha256']==m['GAP_ROWS_SHA'])
actual=m['dependency_register'](sources,inventory,review,gap_rows)
check('complete external dependency register reproduced',m['validate_register'](stored,sources,inventory,review,gap_rows) and sha((fixture/(name+'-register.json')).read_bytes())==policy['expected_register_sha256'])
expected_names='awk base64 bash cat chown chmod cmp cp date dirname env find flock flatpak git grep grub-mkconfig grub-script-check head hostname id install ldconfig md5sum mkdir mkinitrd mktemp mv od python3 readelf readlink rm sbopkg sed sha256sum slackpkg sort sqg stat tail tar tee touch tr uname uniq unshare upgradepkg wc wget'.split()
check('all51 written name candidates retained in exact order',[row['name_candidate'] for row in actual['command_candidates']]==expected_names and len(expected_names)==policy['named_candidate_count']==51)
expected_families=['shell-resolution-and-startup','slackpkg-backend-and-full-selector','pkgtools-archives-and-install-hooks','core-utilities-parsers-and-compression','foreign-python-validator-runtime','optional-repository-and-build-tools','boot-generators-and-policy-hooks','elf-loader-and-library-inputs','configuration-mirrors-and-source-metadata','process-namespace-FD-and-platform','storage-recovery-and-publication','generated-payload-and-runtime-consumption']
check('all12 source-anchored dependency families retained',[row['id'] for row in actual['dependency_families']]==expected_families and len(expected_families)==policy['dependency_family_count']==12)
occ=actual['literal_occurrences'];check('all958 literal name-line records ordered and unproven',len(occ)==policy['expected_occurrence_count']==958 and [row['id'] for row in occ]==list(range(958)) and all(row['actual_callee_binding'] is None and row['native_dependency_proven'] is False and row['status']=='lexical-name-occurrence-not-command-resolution' for row in occ))
index_map={row['path']:i for i,row in enumerate(policy['source_roots'])};name_map={name:i for i,name in enumerate(expected_names)}
check('source line then candidate-name occurrence order exact',[(index_map[row['anchor']['path']],row['anchor']['line_number'],name_map[row['name_candidate']]) for row in occ]==sorted((index_map[row['anchor']['path']],row['anchor']['line_number'],name_map[row['name_candidate']]) for row in occ))
all_ids=[i for row in actual['command_candidates'] for i in row['occurrence_ids']]
check('named rows partition every occurrence without omission or duplicates',sorted(all_ids)==list(range(958)) and len(set(all_ids))==958 and all(occ[i]['name_candidate']==row['name_candidate'] for row in actual['command_candidates'] for i in row['occurrence_ids']))
geometry=True;multimatch=False;nonascii=False
for row in occ:
    loc=row['anchor'];data=sources[loc['path']];lines=data.split(b'\n');full=lines[loc['line_number']-1]+b'\n';start=sum(len(line)+1 for line in lines[:loc['line_number']-1])
    geometry=geometry and sha(full)==loc['raw_line_sha256'] and start==loc['line_start_byte'] and len(full)==loc['line_length_bytes'] and full.decode()==loc['full_line_text'] and sha(data)==loc['source_sha256']
    for begin,end in row['literal_match_byte_ranges']:
        geometry=geometry and full[begin:end]==row['name_candidate'].encode() and 0<=begin<end<=len(full)
    multimatch=multimatch or len(row['literal_match_byte_ranges'])>1;nonascii=nonascii or any(c>=128 for c in full)
check('every occurrence line and match range independently matches full bytes',geometry and multimatch)
# Isolated in-memory helper bytes; not an accepted repository source binding.
private_views={row['path']:(b'',[],[],dict(row,sha256=sha(b''),role='private-helper-test-not-native-or-accepted-source')) for row in policy['source_roots']}
private_raw='# é bash bash\n'.encode();private_binding=dict(policy['source_roots'][0],sha256=sha(private_raw),role='private-helper-test-not-native-or-accepted-source')
private_views[first_path:=policy['source_roots'][0]['path']]=(private_raw,[private_raw],[0],private_binding)
private_occ=m['occurrence_records'](private_views,['bash'],{'selected_sites':[]})
check('isolated helper preserves UTF8 match bytes and repeated names',len(private_occ)==1 and private_occ[0]['literal_match_byte_ranges']==[[5,9],[10,14]] and private_occ[0]['anchor']['raw_line_sha256']==sha(private_raw) and private_occ[0]['anchor']['line_length_bytes']==15)
context_lines={(row['anchor']['path'],row['anchor']['line_number']):row for row in review['selected_sites']}
check('all362 selected contexts preserved without command resolution',all(row['selected362_contexts']==[{'site_id':site['id'],'context_review':site['context_review']} for site in review['selected_sites'] if site['anchor']['path']==row['anchor']['path'] and site['anchor']['line_number']==row['anchor']['line_number']] for row in occ))
plan_rows=[row for row in occ if row['name_candidate']=='slackpkg' and row['anchor']['path'].endswith('/slack-update-reference.sh') and row['anchor']['line_number'] in [2823,2825,2830,5879]]
check('printed and JSON slackpkg plan contexts retained as strings',len(plan_rows)==4 and [row['selected362_contexts'][0]['context_review'] for row in plan_rows]==['printed-plan-string-text']*3+['JSON-plan-string-text'])
commands={row['name_candidate']:row for row in actual['command_candidates']};families={row['id']:row for row in actual['dependency_families']}
check('actual source sites distinguish backend pkgtools and dynamic builder requirements',any(x['token']=='slackpkg' for x in families['slackpkg-backend-and-full-selector']['source_anchors']) and any(x['token']=='upgradepkg' for x in families['pkgtools-archives-and-install-hooks']['source_anchors']) and any(x['token']=='$CSB_BUILDER' for x in families['optional-repository-and-build-tools']['source_anchors']))
check('postinst-off source text never discharges install-hook closure',sum(x['token']=='-postinst=off' for x in families['slackpkg-backend-and-full-selector']['source_anchors'])==2 and not actual['coverage']['postinst_off_discharges_hook_closure'] and 'archive-member-and-install-hook-source-bytes' in families['pkgtools-archives-and-install-hooks']['required_inputs'])
check('foreign Python inputs and shell-loader-library closure stay missing',any(x['token']=='import json,sys' for x in families['foreign-python-validator-runtime']['source_anchors']) and 'installed-interpreter-and-stdlib-search-path-closure' in families['foreign-python-validator-runtime']['required_inputs'] and 'actual-executable-interpreter-loader-and-library-byte-closure' in families['elf-loader-and-library-inputs']['required_inputs'])
check('config and mirror requirements do not add a review root',any(x['token']=='data/config/slack-update.conf' for x in families['configuration-mirrors-and-source-metadata']['source_anchors']) and len(actual['review_sources'])==4 and all(not x['path'].endswith('.conf') for x in actual['review_sources']))
check('namespace FD platform storage and publication inputs stay separate',all(k in families for k in ['process-namespace-FD-and-platform','storage-recovery-and-publication']) and 'actual-filesystem-mount-device-durability-and-writer-alias-closure' in families['storage-recovery-and-publication']['required_inputs'])
rows=actual['command_candidates']+actual['dependency_families'];slots=[slot for row in rows for slot in row['platform_inputs']]
check('all126 separate two-platform missing-input slots retained',len(slots)==126 and len({slot['id'] for slot in slots})==126 and all([slot['platform'] for slot in row['platform_inputs']]==['Slackware-15.0','Slackware-current'] for row in rows))
nullable=['availability','resolved_path','version','architecture','package_record','sha256','size_bytes','owner_mode','interpreter_loader_library_graph','effective_config_and_hook_bytes','checked_to_consumed_identity','fresh_attempt_identity','independent_raw_observation']
check('every platform availability version identity and observation remains null',all(slot['status']=='required-native-input-not-bound' and slot['native_proof'] is False and all(slot[k] is None for k in nullable) for slot in slots))
check('common native requirements include full transitive consumption and raw origin',all(row['required_inputs']==m['COMMON_REQUIREMENTS'] and not row['exhaustive'] for row in actual['command_candidates']) and 'checked-to-consumed-object-identity-alias-and-lifetime-closure' in m['COMMON_REQUIREMENTS'] and 'independent-same-attempt-raw-observation-and-origin' in m['COMMON_REQUIREMENTS'])
gap_ids=[row['inherited_gap']['id'] for row in gap_rows]
check('all full original gap rows retained and family links discharge none',actual['full_original_native_gap_rows348']==gap_rows and gap_ids==policy['inherited_gap_ids'] and all(not row['gap_discharged'] and all(k in gap_ids for k in row['original_native_gap_ids']) for row in actual['dependency_families']))
check('native input gaps never inferred absent from lexical inventory',not actual['coverage']['candidate_register_is_exhaustive'] and not actual['coverage']['native_resolution_performed'] and not actual['coverage']['installed_versions_bound'] and not actual['coverage']['missing_input_means_absent'] and actual['coverage']['remaining_runtime_dependencies_status']=='required-not-enumerated-or-bound')
check('generated copies and historical constants never become current bindings',not actual['coverage']['historical_constants_are_current_bindings'] and not actual['coverage']['decoded_payloads_reviewed'] and any(x['token']=='$REFERENCE_FILE' for x in families['generated-payload-and-runtime-consumption']['source_anchors']) and actual['review_sources'][3]['role']=='historical-generated-artifact-not-a-second-independent-worker')
check('all original unknown categories and15106 hints remain retained',actual['unresolved_relations']==m['UNRESOLVED'] and actual['coverage']['all15106_inventory_records_retained'] and actual['frozen_inputs']['inventory_canonical_sha256']==m['INVENTORY_SHA'])
for label,mutate in [
('omitted candidate',lambda x:x['command_candidates'].pop()),('extra candidate',lambda x:x['command_candidates'].append(copy.deepcopy(x['command_candidates'][0]))),('reordered candidates',lambda x:x['command_candidates'].reverse()),('missing literal occurrence',lambda x:x['literal_occurrences'].pop()),('reordered literal occurrences',lambda x:x['literal_occurrences'].reverse()),('rebound line SHA',lambda x:x['literal_occurrences'][0]['anchor'].__setitem__('raw_line_sha256','0'*64)),('wrong literal match byte range',lambda x:x['literal_occurrences'][0]['literal_match_byte_ranges'][0].__setitem__(0,0)),('false native command resolution',lambda x:x['literal_occurrences'][0].__setitem__('actual_callee_binding',{})),('false observed native dependency',lambda x:x['literal_occurrences'][0].__setitem__('native_dependency_proven',True)),('omitted known printed plan context',lambda x:next(row for row in x['literal_occurrences'] if row['selected362_contexts'])['selected362_contexts'].clear()),('missing dependency family',lambda x:x['dependency_families'].pop()),('omitted hook closure requirement',lambda x:x['dependency_families'][2]['required_inputs'].pop()),('missing normative native gap',lambda x:x['full_original_native_gap_rows348'].pop()),('family gap falsely discharged',lambda x:x['dependency_families'][0].__setitem__('gap_discharged',True)),('shared platform ID',lambda x:x['command_candidates'][0]['platform_inputs'][1].__setitem__('id',x['command_candidates'][0]['platform_inputs'][0]['id'])),('missing second platform input',lambda x:x['dependency_families'][0]['platform_inputs'].pop()),('unknown dependency field',lambda x:x.__setitem__('native_success',True))]:
    bad=copy.deepcopy(stored);mutate(bad);check('reject '+label,rejected(m['validate_register'],bad,sources,inventory,review,gap_rows))
for field,value in [('availability',False),('resolved_path','/usr/bin/awk'),('version','invented'),('architecture','x86_64'),('package_record','historical-record'),('sha256','0'*64),('size_bytes',True),('owner_mode','root:root:0755'),('interpreter_loader_library_graph',[]),('effective_config_and_hook_bytes',[]),('checked_to_consumed_identity',{}),('fresh_attempt_identity','old-boot-id'),('independent_raw_observation',{}),('native_proof',True),('status','native-bound')]:
    bad=copy.deepcopy(stored);bad['command_candidates'][0]['platform_inputs'][0][field]=value;check('reject invented platform input '+field,rejected(m['validate_register'],bad,sources,inventory,review,gap_rows))
for field,value in [('candidate_register_is_exhaustive',True),('shell_parsed',True),('native_resolution_performed',True),('installed_versions_bound',True),('missing_input_means_absent',True),('postinst_off_discharges_hook_closure',True),('historical_constants_are_current_bindings',True),('decoded_payloads_reviewed',True),('platform_inputs_independently_observed',True)]:
    bad=copy.deepcopy(stored);bad['coverage'][field]=value;check('reject false register coverage '+field,rejected(m['validate_register'],bad,sources,inventory,review,gap_rows))
for field,value in [('native_graph_complete',True),('execution_authorized',True),('runtime_authority',True),('actual_successor_selected',True),('actual_live_bindings',{}),('actual_host_state','absent'),('actual_global_host_closure',True),('native_cases_run',1),('readme_reconciliation_step',None),('strong_safe_pause',True)]:
    bad=copy.deepcopy(stored);bad['boundaries'][field]=value;check('reject false register boundary '+field,rejected(m['validate_register'],bad,sources,inventory,review,gap_rows))
bad=copy.deepcopy(inventory);bad['hint_records'].pop();check('reject truncated original inventory',rejected(m['dependency_register'],sources,bad,review,gap_rows))
bad=copy.deepcopy(review);bad['selected_sites'][0]['reachability_proven']=True;check('reject changed original context review',rejected(m['dependency_register'],sources,inventory,bad,gap_rows))
bad=copy.deepcopy(gap_rows);bad[0]['actual_model_or_component']={};check('reject changed original native gap component',rejected(m['dependency_register'],sources,inventory,review,bad))
first=policy['source_roots'][0]['path'];bad=dict(sources);bad[first]=b'X'+bad[first][1:];check('reject source byte drift before candidate matching',rejected(m['dependency_register'],bad,inventory,review,gap_rows))
bad=dict(sources);bad['../unapproved.sh']=b'exit 0\n';check('reject unapproved extra source path',rejected(m['dependency_register'],bad,inventory,review,gap_rows))
views=m['source_lines'](sources);check('reject invalid source indices and bool line numbers',all(rejected(m['anchor'],views,i,1) for i in [True,-1,4]) and all(rejected(m['anchor'],views,0,line) for line in [True,0,6638]))
globals_data=m['dependency_register'].__globals__;budget=globals_data['MAX_OCCURRENCES'];globals_data['MAX_OCCURRENCES']=1
try:budget_refused=rejected(m['dependency_register'],sources,inventory,review,gap_rows)
finally:globals_data['MAX_OCCURRENCES']=budget
check('hard fail occurrence budget without successful truncated register',budget_refused and budget==4096)
mutated=m['dependency_register'](sources,inventory,review,gap_rows);mutated['boundaries']['runtime_authority']=True;mutated['review_sources'][0]['execution_authorized']=True;mutated['command_candidates'][0]['required_inputs'].clear();mutated['full_original_native_gap_rows348'][0]['status']='waived'
check('mutating returned report cannot alter frozen expectations or caller gaps',m['BOUNDARIES']['runtime_authority'] is False and m['SOURCE_BINDINGS'][0]['execution_authorized'] is False and len(m['COMMON_REQUIREMENTS'])==8 and gap_rows[0]['status']=='required-not-selected-refined-or-proven' and m['dependency_register'](sources,inventory,review,gap_rows)==stored)
ast_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(ast_tree) if isinstance(node,ast.Import) for alias in node.names}
check('pure register tool imports only hashlib json and re',imports=={'hashlib','json','re'})
check('pure register tool has no filesystem resolution execution decode or spawn entry',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in {'open','exec','eval','compile','__import__'}) or (isinstance(node.func,ast.Attribute) and node.func.attr in {'system','popen','run','which','b64decode','execv','spawnv','read_bytes','read_text','stat','resolve'})) for node in ast.walk(ast_tree)))
check('README remains exact pending367',sha((root/'README.md').read_bytes())==policy['readme_at_entry_sha256'])
old_coverage=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-readonly-source-inventory-control-coverage.json'])
check('historical361 modeled socket limitation preserved',old_coverage['native_proof'] is False and any('socket-type-stat-metadata-modeled' in row.get('method','') for row in old_coverage['controls']))
norm=gap_data['full_normative_rows']
check('all16 native gaps still unselected and unproven',all(row['status']=='required-not-selected-refined-or-proven' and not row['native_status_promoted'] and row['actual_model_or_component'] is None and row['actual_independent_evidence'] is None for row in gap_rows))
check('46 native proofs and52 cases still unproven and unrun',len(norm['qualified_proof_reconciliation'])==46 and all(row['status']=='required-not-proven' for row in norm['qualified_proof_reconciliation']) and len(norm['native_case_templates'])==52 and all(row['status']=='required-not-run' for row in norm['native_case_templates']))
check('12 independent raw native groups remain uncaptured',len(gap_data['full_original_evidence_group_rows335'])==12 and all(row['status']=='required-native-evidence-not-captured' for row in gap_data['full_original_evidence_group_rows335']))
plan=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-source-inventory-resume-planning-review-plan.json'])
check('finite359-368 roadmap and final README obligation retained',[row['step'] for row in plan['roadmap']]==list(range(359,369)) and plan['readme_reconciliation_step']==367 and plan['conditional_pause_step']==368)
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
