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

root=Path(sys.argv[1]);name='phase-1-operational-effect-lifetime-review';prior='phase-1-operational-external-dependency-register'
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
policy=load('policy');confirmed=load('confirmed363');receipt=load('step363-user-acceptance');stored=load('review')
check('all1845 accepted363 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1845)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted363 bytes exact with additive CHANGELOG only',len(history)==1845)
check('external confirmed363 bytes exact',sha((fixture/(name+'-confirmed363.json')).read_bytes())==policy['expected_confirmation_sha256'])
check('complete363 receipt and report-based confirmation validate',m['validate_acceptance'](receipt,confirmed))
text=receipt['text'];raw=text.encode();message=policy['accepted_commit_message'];head='c69533f (HEAD -> main, origin/main, origin/HEAD) '+message
check('all119 exact ordered363 labels and zero-failure summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered363_labels'] and text.count('Result: PASS (119 passes, 0 failures)')==1)
check('reported363 exact eight-file commit and seven created paths',text.count('[main c69533f] '+message)==1 and text.count('8 files changed, 3456 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step363_created_paths'])
check('reported363 push clean status and matching heads',text.count('aff8592..c69533f  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'))
check('receipt SHA size and original-capture limitation retained',sha(raw)==policy['accepted_receipt_sha256']==receipt['sha256'] and len(raw)==policy['accepted_receipt_size_bytes']==receipt['size_bytes'] and receipt['capture_basis']=='complete-user-message-text-transcribed-as-UTF8-with-final-storage-newline;not-original-terminal-byte-capture')
check('accepted363 is not a new pause or invented full commit',confirmed['commit_prefix']=='c69533f' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
for field,value in [('strong_safe_pause',True),('commit_full','c69533f'+'0'*33),('runtime_authority',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('native_cases_run',1),('native_proofs_added',1),('user_worktree_clean',False),('user_head_matches_origin',False),('phase1_matrix_complete',True),('kernel_package_edge_complete',True),('production_entry_closed',False),('phase2_open',True)]:
    bad=copy.deepcopy(confirmed);bad[field]=value;check('reject changed363 confirmation '+field,rejected(m['validate_acceptance'],receipt,bad))
for label,edit in [('truncated receipt',lambda x:x[:-1]),('same-length edited receipt',lambda x:x.replace('c69533f','c695340',1)),('injected status output',lambda x:x.replace(head,' M README.md\n'+head,1))]:
    bad=copy.deepcopy(receipt);bad['text']=edit(text);check('reject '+label,rejected(m['validate_acceptance'],bad,confirmed))
bad=copy.deepcopy(receipt);bad['capture_basis']='original-terminal-byte-capture';check('reject invented original terminal capture',rejected(m['validate_acceptance'],bad,confirmed))
check('exact four review roots remain closed and historical roles distinct',m['SOURCE_BINDINGS']==policy['source_roots'] and all(not x['execution_authorized'] and x['actual_native_binding'] is None for x in m['SOURCE_BINDINGS']) and 'not-a-second-independent-worker' in m['SOURCE_BINDINGS'][3]['role'])
inventory=json.loads(history[policy['inventory_path']]);context=json.loads(history[policy['context_path']]);dependencies=json.loads(history[policy['dependency_path']]);gap_data=json.loads(history[policy['native_gap_path']]);gap_rows=gap_data['full_original_native_gap_rows348'];sources={x['path']:history[x['path']] for x in policy['source_roots']}
for key,data in [('inventory',inventory),('context',context),('dependencies',dependencies),('gap_rows',gap_rows)]:
    check('complete frozen '+key+' canonical binding exact',m['canonical'](data)==m['INPUT_HASHES'][key])
actual=m['effect_lifetime_review'](sources,inventory,context,dependencies,gap_rows)
check('complete effect lifetime review reproduced',m['validate_review'](stored,sources,inventory,context,dependencies,gap_rows) and sha((fixture/(name+'-review.json')).read_bytes())==policy['expected_review_sha256'])
domain_ids=['execution-environment','instance-lock-descriptor','runtime-directories-and-temporaries','dry-run-state-files','log-rotation-and-process-pipelines','package-snapshot-files','mirror-transport-probe','package-backend-effects','GenInitrd-policy-override-and-restore','private-SBo-workspace','optional-repositories-and-builders','static-ELF-observation-and-diagnostics','boot-output-generation-and-replacement','reference-cleanup-and-release','worker-preparation-before-traps','worker-backup-and-restoration','worker-config-and-native-child-launch','worker-final-snapshots-and-flags','worker-publication-and-self-receipt','generator-output-lifetime','reference-events-and-FD-output']
hazard_ids=['lock-path-object-and-release','inherited-FD-and-pipeline-descendants','package-database-canonical-and-compatibility-aliases','checked-source-archive-interpreter-consumption','generator-check-to-reopen-window','temporary-name-and-owned-cleanup-aliases','dry-run-and-check-effect-scope','policy-fingerprint-copy-replace-restore-window','GRUB-fingerprint-and-replacement-window','backup-owned-binding-and-target-binding-distinct','worker-first-write-before-trap-registration','signal-cleanup-and-sticky-failure','backend-hooks-and-rollback-descendants','final-snapshots-flags-and-known-release','publication-later-target-reads-and-backup-deletion','archive-checksum-pair-and-self-receipt']
check('all21 selected effect domains ordered and distinct',[x['id'] for x in actual['effect_domains']]==domain_ids and len(set(domain_ids))==21)
check('all16 selected lifetime hazards ordered and distinct',[x['id'] for x in actual['lifetime_hazards']]==hazard_ids and len(set(hazard_ids))==16)
domains={x['id']:x for x in actual['effect_domains']};hazards={x['id']:x for x in actual['lifetime_hazards']}
geometry=True
for row in actual['effect_domains']+actual['lifetime_hazards']:
    for site in row['source_anchors']:
        loc=site['anchor'];raw=sources[loc['path']];pieces=raw.split(b'\n');full=pieces[loc['line_number']-1]+b'\n';offset=sum(len(x)+1 for x in pieces[:loc['line_number']-1])
        geometry=geometry and sha(raw)==loc['source_sha256'] and sha(full)==loc['raw_line_sha256'] and offset==loc['line_start_byte'] and len(full)==loc['line_length_bytes'] and full.decode()==loc['full_line_text'] and site['token'] in full.decode() and site['status']=='reviewed-source-text-not-native-event'
check('every selected full line independently matches source byte geometry',geometry)
check('all domain objects and writers remain unbound',all(x['actual_writer_set'] is None and x['actual_object_bindings'] is None and x['native_effects_observed'] is None and not x['absence_of_effects_proven'] for x in domains.values()))
check('textual anchor ordering never claims native event ordering',all(x['actual_native_event_relation'] is None and not x['source_anchor_order_is_native_event_order'] and not x['native_gap_discharged'] for x in hazards.values()))
slots=[s for x in hazards.values() for s in x['platform_relations']]
check('all32 separate platform lifetime relations retained',len(slots)==32 and len({x['id'] for x in slots})==32 and all([s['platform'] for s in x['platform_relations']]==['Slackware-15.0','Slackware-current'] for x in hazards.values()))
nullable=['actual_writer_set','actual_object_set','alias_equivalence','checked_to_consumed_identity','continuous_exclusion_interval','native_fence','guard_loss_handling','known_child_closure','owned_backup_binding','target_binding','durable_release_relation','independent_raw_evidence']
check('every native lifetime binding and observation remains null',all(s['status']=='required-native-lifetime-relation-not-bound' and not s['native_proof'] and all(s[k] is None for k in nullable) for s in slots))
channels=actual['retained_lexical_channels'];counts={'pipeline-redirection-hint':1155,'dynamic-command-hint':2833,'trap-process-hint':145,'source-eval-exec-hint':114,'command-substitution-hint':387,'here-document-hint':26}
check('all4660 selected lexical channel indices exact and ordered',set(channels)==set(counts) and all(channels[k]==[i for i,x in enumerate(inventory['hint_records']) if x['kind']==k] and len(channels[k])==count for k,count in counts.items()) and sum(map(len,channels.values()))==4660)
check('all15106 hints and126 dependency input slots retained without discharge',len(inventory['hint_records'])==15106 and len([s for x in dependencies['command_candidates']+dependencies['dependency_families'] for s in x['platform_inputs']])==126 and all(not s['native_proof'] for x in dependencies['command_candidates']+dependencies['dependency_families'] for s in x['platform_inputs']) and actual['coverage']['all15106_inventory_records_retained'] and actual['coverage']['all126_dependency_platform_slots_still_unbound'])
def contains(row,line,token):return any(s['anchor']['line_number']==line and token in s['anchor']['full_line_text'] for s in row['source_anchors'])
check('instance FD lock has separate open acquire unlock close sites',all(contains(domains['instance-lock-descriptor'],line,token) for line,token in [(2127,'exec 9'),(2133,'flock'),(2144,'flock'),(2148,'exec 9')]))
check('logging pipelines inherited FD and cleanup remain unresolved',contains(hazards['inherited-FD-and-pipeline-descendants'],2499,'exec 3') and contains(hazards['inherited-FD-and-pipeline-descendants'],2503,'tee'))
check('canonical and compatibility package database aliases stay distinct',contains(hazards['package-database-canonical-and-compatibility-aliases'],7,'/var/log/packages') and contains(hazards['package-database-canonical-and-compatibility-aliases'],8,'/var/lib/pkgtools/packages'))
check('checked archive source and later interpreter consumption separately anchored',contains(hazards['checked-source-archive-interpreter-consumption'],674,'sha256sum') and contains(hazards['checked-source-archive-interpreter-consumption'],562,'bash') and contains(hazards['checked-source-archive-interpreter-consumption'],709,'upgradepkg'))
check('generator frozen hash precedes later text reads without native fence',contains(hazards['generator-check-to-reopen-window'],105,'check_sha') and contains(hazards['generator-check-to-reopen-window'],166,'cat --') and contains(hazards['generator-check-to-reopen-window'],167,'base64'))
check('temporary cleanup and owned path flags do not bind object aliases',contains(hazards['temporary-name-and-owned-cleanup-aliases'],2419,'rm -rf') and any('open-FD' in x for x in hazards['temporary-name-and-owned-cleanup-aliases']['unproven_relations']))
check('dry-run local writes transport and log deletion remain visible',all(contains(hazards['dry-run-and-check-effect-scope'],line,token) for line,token in [(2366,'mktemp -d'),(2398,': >'),(2475,'-delete'),(2567,'wget')]))
check('policy stat hash copy replace and restore remain separate operations',all(contains(hazards['policy-fingerprint-copy-replace-restore-window'],line,token) for line,token in [(3115,'stat'),(3116,'sha256sum'),(3255,'cp --preserve'),(3303,'mv -fT'),(3381,'mv -fT')]))
check('cksum newly selected outside frozen51 candidates stays unresolved',contains(hazards['GRUB-fingerprint-and-replacement-window'],4958,'cksum') and 'cksum' not in [x['name_candidate'] for x in dependencies['command_candidates']] and any('outside-frozen51' in x for x in hazards['GRUB-fingerprint-and-replacement-window']['unproven_relations']))
check('owned backup binding distinct from target binding on both platforms',all(s['owned_backup_binding'] is None and s['target_binding'] is None for s in hazards['backup-owned-binding-and-target-binding-distinct']['platform_relations']) and any('distinct' in x for x in hazards['backup-owned-binding-and-target-binding-distinct']['unproven_relations']))
check('worker source preparation writes precede source trap and mutation flag',all(contains(hazards['worker-first-write-before-trap-registration'],line,token) for line,token in [(664,'install -d'),(670,'extract_payload'),(676,'derive_runtime_config'),(702,'backup_mutable_state'),(703,'trap'),(708,'MUTATION_STARTED=1')]))
check('cleanup failure trap handling and child drain require native proof',contains(hazards['signal-cleanup-and-sticky-failure'],390,'trap -') and contains(hazards['signal-cleanup-and-sticky-failure'],393,'restore_transaction_state') and any('child-drain' in x for x in hazards['signal-cleanup-and-sticky-failure']['unproven_relations']))
check('rollback backend launch and postinst flags discharge no hooks',contains(hazards['backend-hooks-and-rollback-descendants'],346,'upgradepkg') and contains(hazards['backend-hooks-and-rollback-descendants'],3437,'-postinst=off') and not hazards['backend-hooks-and-rollback-descendants']['native_gap_discharged'])
check('final snapshot flags never prove known-child target closure',contains(hazards['final-snapshots-flags-and-known-release'],727,'RESTORATION_COMPLETE=1') and contains(hazards['final-snapshots-flags-and-known-release'],728,'MUTATION_STARTED=0') and not actual['coverage']['target_closure_before_release_proven'])
check('publication retains later target reads and earlier backup deletion sites',all(contains(hazards['publication-later-target-reads-and-backup-deletion'],line,token) for line,token in [(590,'rm -rf'),(595,'package_database_manifest_hash'),(596,'boot_id'),(727,'RESTORATION_COMPLETE=1'),(729,'publish_evidence')]) and not actual['coverage']['captured_data_only_publication_proven'])
check('separate archive checksum and worker self PASS are not independent receipt',all(contains(hazards['archive-checksum-pair-and-self-receipt'],line,token) for line,token in [(605,'mv -f'),(607,'PUBLISHED_SHA256'),(611,'validation_status'),(5578,'provisional')]))
check('every original native gap row and unknown category retained',actual['full_original_native_gap_rows348']==gap_rows and len(gap_rows)==16 and actual['unresolved_relations']==m['UNRESOLVED'])
for label,mutate in [
('omitted domain',lambda x:x['effect_domains'].pop()),('reordered domains',lambda x:x['effect_domains'].reverse()),('changed object expression',lambda x:x['effect_domains'][0]['object_expressions'].append('/invented')),
('invented writer set',lambda x:x['effect_domains'][0].__setitem__('actual_writer_set',[])),('invented observed effect',lambda x:x['effect_domains'][0].__setitem__('native_effects_observed',[])),('false absence of effects',lambda x:x['effect_domains'][0].__setitem__('absence_of_effects_proven',True)),
('omitted hazard',lambda x:x['lifetime_hazards'].pop()),('reordered hazard anchors',lambda x:x['lifetime_hazards'][0]['source_anchors'].reverse()),('changed full line SHA',lambda x:x['effect_domains'][0]['source_anchors'][0]['anchor'].__setitem__('raw_line_sha256','0'*64)),('changed byte offset',lambda x:x['effect_domains'][0]['source_anchors'][0]['anchor'].__setitem__('line_start_byte',1)),
('false runtime event order',lambda x:x['lifetime_hazards'][0].__setitem__('source_anchor_order_is_native_event_order',True)),('false native event relation',lambda x:x['lifetime_hazards'][0].__setitem__('actual_native_event_relation',{})),('native gap discharged',lambda x:x['lifetime_hazards'][0].__setitem__('native_gap_discharged',True)),('omitted original gap',lambda x:x['full_original_native_gap_rows348'].pop()),
('missing second platform',lambda x:x['lifetime_hazards'][0]['platform_relations'].pop()),('shared platform identity',lambda x:x['lifetime_hazards'][0]['platform_relations'][1].__setitem__('id',x['lifetime_hazards'][0]['platform_relations'][0]['id'])),('omitted lexical index',lambda x:x['retained_lexical_channels']['dynamic-command-hint'].pop()),('duplicated lexical index',lambda x:x['retained_lexical_channels']['trap-process-hint'].append(0)),('unknown review field',lambda x:x.__setitem__('native_success',True))]:
    bad=copy.deepcopy(stored);mutate(bad);check('reject '+label,rejected(m['validate_review'],bad,sources,inventory,context,dependencies,gap_rows))
for field in nullable+['native_proof','status']:
    bad=copy.deepcopy(stored);bad['lifetime_hazards'][0]['platform_relations'][0][field]=True if field=='native_proof' else 'invented-native-binding';check('reject invented platform relation '+field,rejected(m['validate_review'],bad,sources,inventory,context,dependencies,gap_rows))
for field in ['shell_parsed','effect_or_alias_graph_complete','native_continuous_exclusion_proven','native_child_drain_proven','native_rollback_durability_proven','target_closure_before_release_proven','captured_data_only_publication_proven','source_flags_are_native_receipts','no_effects_inferred_from_operation_name','reported_scoped_pause_is_global_host_closure']:
    bad=copy.deepcopy(stored);bad['coverage'][field]=True;check('reject false coverage '+field,rejected(m['validate_review'],bad,sources,inventory,context,dependencies,gap_rows))
for field,value in [('native_graph_complete',True),('execution_authorized',True),('runtime_authority',True),('actual_successor_selected',True),('actual_live_bindings',{}),('actual_host_state','absent'),('actual_global_host_closure',True),('native_cases_run',1),('readme_reconciliation_step',None),('strong_safe_pause',True)]:
    bad=copy.deepcopy(stored);bad['boundaries'][field]=value;check('reject false boundary '+field,rejected(m['validate_review'],bad,sources,inventory,context,dependencies,gap_rows))
inputs=[inventory,context,dependencies,gap_rows]
for index,key in enumerate(['inventory','context','dependencies','gap_rows']):
    values=copy.deepcopy(inputs)
    if isinstance(values[index],dict):values[index]['invented_native_authority']=True
    else:values[index].pop()
    check('reject changed complete frozen '+key,rejected(m['effect_lifetime_review'],sources,*values))
first=policy['source_roots'][0]['path'];bad=dict(sources);bad[first]=b'X'+bad[first][1:];check('reject source byte drift before review',rejected(m['effect_lifetime_review'],bad,*inputs))
bad=dict(sources);bad['../unapproved.sh']=b'exit 0\n';check('reject extra traversing source root',rejected(m['effect_lifetime_review'],bad,*inputs))
views=m['source_lines'](sources);check('reject bool and out of range source anchor integers',all(rejected(m['anchor'],views,i,1) for i in [True,-1,4]) and all(rejected(m['anchor'],views,0,line) for line in [True,0,6638]))
mutated=m['effect_lifetime_review'](sources,*inputs);mutated['boundaries']['runtime_authority']=True;mutated['review_sources'][0]['execution_authorized']=True;mutated['full_original_native_gap_rows348'][0]['status']='waived';mutated['frozen_inputs']['inventory']='changed'
check('returned mutation cannot change frozen boundaries inputs or caller gaps',not m['BOUNDARIES']['runtime_authority'] and not m['SOURCE_BINDINGS'][0]['execution_authorized'] and gap_rows[0]['status']=='required-not-selected-refined-or-proven' and m['effect_lifetime_review'](sources,*inputs)==stored)
ast_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(ast_tree) if isinstance(node,ast.Import) for alias in node.names}
check('pure reviewer imports only hashlib json and re',imports=={'hashlib','json','re'})
check('pure reviewer has no filesystem resolution execution decode or spawn entry',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in {'open','exec','eval','compile','__import__'}) or (isinstance(node.func,ast.Attribute) and node.func.attr in {'system','popen','run','which','b64decode','execv','spawnv','read_bytes','read_text','stat','resolve'})) for node in ast.walk(ast_tree)))
check('README remains exact pending367',sha((root/'README.md').read_bytes())==policy['readme_at_entry_sha256'])
old_coverage=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-readonly-source-inventory-control-coverage.json'])
check('historical361 modeled socket limitation preserved',not old_coverage['native_proof'] and any('socket-type-stat-metadata-modeled' in x.get('method','') for x in old_coverage['controls']))
norm=gap_data['full_normative_rows']
check('all16 native gaps still unselected and unproven',all(x['status']=='required-not-selected-refined-or-proven' and not x['native_status_promoted'] and x['actual_model_or_component'] is None and x['actual_independent_evidence'] is None for x in gap_rows))
check('46 native proofs and52 cases still unproven and unrun',len(norm['qualified_proof_reconciliation'])==46 and all(x['status']=='required-not-proven' for x in norm['qualified_proof_reconciliation']) and len(norm['native_case_templates'])==52 and all(x['status']=='required-not-run' for x in norm['native_case_templates']))
check('12 independent raw native groups remain uncaptured',len(gap_data['full_original_evidence_group_rows335'])==12 and all(x['status']=='required-native-evidence-not-captured' for x in gap_data['full_original_evidence_group_rows335']))
plan=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-source-inventory-resume-planning-review-plan.json'])
check('finite359-368 roadmap and final README obligation retained',[x['step'] for x in plan['roadmap']]==list(range(359,369)) and plan['readme_reconciliation_step']==367 and plan['conditional_pause_step']==368)
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
