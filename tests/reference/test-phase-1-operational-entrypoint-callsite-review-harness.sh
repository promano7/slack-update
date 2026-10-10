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

root=Path(sys.argv[1]);name='phase-1-operational-entrypoint-callsite-review';prior='phase-1-operational-readonly-source-inventory'
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
policy=load('policy');confirmed=load('confirmed361');receipt=load('step361-user-acceptance');stored=load('review')
check('all1831 accepted361 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1831)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted361 bytes exact with additive CHANGELOG only',len(history)==1831)
check('external confirmed361 bytes exact',sha((fixture/(name+'-confirmed361.json')).read_bytes())==policy['expected_confirmation_sha256'])
check('complete361 receipt and report-based confirmation validate',m['validate_acceptance'](receipt,confirmed))
text=receipt['text'];raw=text.encode();message=policy['accepted_commit_message'];head='633b524 (HEAD -> main, origin/main, origin/HEAD) '+message
check('all51 exact ordered361 labels and zero-failure summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered361_labels'] and text.count('Result: PASS (51 passes, 0 failures)')==1)
check('reported361 exact nine-file commit and eight created paths',text.count('[main 633b524] '+message)==1 and text.count('9 files changed, 18044 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step361_created_paths'])
check('reported361 push clean status and matching heads',text.count('9a9cd12..633b524  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'))
check('receipt SHA size and original-capture limitation retained',sha(raw)==policy['accepted_receipt_sha256']==receipt['sha256'] and len(raw)==policy['accepted_receipt_size_bytes']==receipt['size_bytes'] and receipt['capture_basis']=='complete-user-message-text-transcribed-as-UTF8-with-final-storage-newline;not-original-terminal-byte-capture')
check('accepted361 is not a new pause or invented full commit',confirmed['commit_prefix']=='633b524' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
for field,value in [('strong_safe_pause',True),('commit_full','633b524'+'0'*33),('runtime_authority',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('native_cases_run',1),('native_proofs_added',1),('user_worktree_clean',False),('user_head_matches_origin',False),('phase1_matrix_complete',True),('kernel_package_edge_complete',True),('production_entry_closed',False),('phase2_open',True)]:
    bad=copy.deepcopy(confirmed);bad[field]=value;check('reject changed361 confirmation '+field,rejected(m['validate_acceptance'],receipt,bad))
for label,edit in [('truncated receipt',lambda x:x[:-1]),('same-length edited receipt',lambda x:x.replace('633b524','633b525',1)),('injected status output',lambda x:x.replace(head,' M README.md\n'+head,1))]:
    bad=copy.deepcopy(receipt);bad['text']=edit(text);check('reject '+label,rejected(m['validate_acceptance'],bad,confirmed))
bad=copy.deepcopy(receipt);bad['capture_basis']='original-terminal-byte-capture';check('reject invented original terminal capture',rejected(m['validate_acceptance'],bad,confirmed))
check('exact source descriptors remain review-only',m['SOURCE_BINDINGS']==policy['source_roots'] and all(not r['execution_authorized'] and r['actual_native_binding'] is None for r in m['SOURCE_BINDINGS']))
inventory=json.loads(history[policy['inventory_path']]);sources={row['path']:history[row['path']] for row in policy['source_roots']}
check('frozen full15106 inventory binding exact',sha(history[policy['inventory_path']])==policy['inventory_sha256'] and m['canonical'](inventory)==policy['inventory_canonical_sha256']==m['INVENTORY_SHA'] and len(inventory['hint_records'])==15106)
actual=m['review_report'](sources,inventory)
check('complete stored entry-callsite review reproduced',m['validate_review'](stored,sources,inventory) and sha((fixture/(name+'-review.json')).read_bytes())==policy['expected_review_sha256'])
check('17 whole source spans and65 full-line sites retained',len(actual['selected_spans'])==policy['selected_span_count']==17 and len(actual['selected_sites'])==policy['selected_site_count']==65)
partition=actual['complete_lexical_partition'];indices=[i for bucket in partition.values() for i in bucket]
check('nine disjoint kind lists retain every15106 record once',len(partition)==9 and len(indices)==len(set(indices))==15106 and sorted(indices)==list(range(15106)) and all(bucket==sorted(bucket) for bucket in partition.values()))
check('all250 definition-like anchors preserved without function resolution',len(actual['definition_like_register'])==250 and [d['inventory_index'] for d in actual['definition_like_register']]==partition['function-definition-hint'] and all(d['anchor']==inventory['hint_records'][d['inventory_index']] and d['status']=='definition-like-text-not-resolved-runtime-function' for d in actual['definition_like_register']))
sites={site['id']:site for site in actual['selected_sites']}
check('reference guard entry and three dispatch branches exact',sites['reference-guard']['anchor']['full_line_text']=='if [ "${BASH_SOURCE[0]}" = "$0" ]; then\n' and sites['reference-entry']['anchor']['full_line_text']=='    main "$@"\n' and [sites[k]['target_text'] for k in ['reference-check-dispatch','reference-apply-dispatch','reference-dry-run-dispatch']]==['run_check_workflow','run_apply_workflow','run_dry_run_workflow'])
check('reference default apply retained as argument text',sites['reference-default-operation']['anchor']['full_line_text']=='    OPERATION=apply\n')
check('worker and generated unconditional entry copies distinct',sites['worker-entry']['anchor']['full_line_text']==sites['generated-worker-entry']['anchor']['full_line_text']=='main "$@"\n' and sites['worker-entry']['anchor']['source_role']!=sites['generated-worker-entry']['anchor']['source_role'])
check('printed and JSON plans distinct from package command sites',all(sites[k]['context_review']=='printed-plan-string-text' for k in ['reference-printed-update-plan','reference-printed-install-plan','reference-printed-upgrade-plan']) and sites['reference-JSON-update-plan']['context_review']=='JSON-plan-string-text' and all(sites[k]['context_review']=='external-command-text' for k in ['reference-package-update','reference-package-install-new','reference-package-upgrade-all']))
check('dry-run probe and output redirection remain visible',sites['reference-dry-run-probe']['target_text']=='check_slackware_updates' and sites['reference-dry-run-output-file']['anchor']['full_line_text']=='        : > "$QUEUE_CORE"\n' and not actual['coverage']['no_hint_means_no_effects'])
check('dynamic command probes retain unresolved names',sites['reference-variable-command-probe']['target_text']=='$logging_command' and sites['worker-variable-command-probe']['target_text']=='$command_name')
check('deferred trap handlers and logging pipeline remain unresolved',sum(s['context_review']=='trap-handler-text' for s in sites.values())==9 and sum(s['context_review']=='process-substitution-pipeline-text' for s in sites.values())==2)
check('foreign Python here documents and dynamic interpreter source visible',sites['worker-python-delta-input']['context_review']==sites['worker-python-result-input']['context_review']=='foreign-interpreter-here-document-text' and '$REFERENCE_FILE' in sites['worker-reference-launch']['anchor']['full_line_text'])
check('generator quoted and expanding here documents differentiated',sites['generator-header-start']['anchor']['full_line_text']=="cat > \"$tmp\" <<'HEADER'\n" and sites['generator-constant-block']['anchor']['full_line_text']=='cat >> "$tmp" <<EOF_CONSTANTS\n')
check('generator syntax and output commands only inspected as text',sites['generator-syntax-command']['anchor']['full_line_text']=='bash -n "$tmp"\n' and sites['generator-output-replace']['anchor']['full_line_text']=='mv -f -- "$tmp" "$output"\n')
copy_relation=actual['copy_relationship'];body=sources[policy['source_roots'][1]['path']];generated=sources[policy['source_roots'][3]['path']]
check('exact historical body copy at byte4039 line48 verified without decode',generated[4039:4039+42856]==body and generated.count(body)==1 and generated[:4039].count(b'\n')+1==48 and copy_relation['length_bytes']==42856 and copy_relation['sha256']==sha(body))
check('generated copy never claims independent worker or current authority',not copy_relation['independent_worker'] and not copy_relation['embedded_reference_decoded'] and not copy_relation['embedded_config_decoded'] and not copy_relation['runtime_consumption_identity_proven'] and not copy_relation['historical_constants_current_authority'])
check('every selected line and whole span has independent exact byte anchor',all((lambda data,loc: sha(data.splitlines(keepends=True)[loc['line_number']-1])==loc['raw_line_sha256'] and sum(map(len,data.splitlines(keepends=True)[:loc['line_number']-1]))==loc['line_start_byte'] and len(data.splitlines(keepends=True)[loc['line_number']-1])==loc['line_length_bytes'])(sources[s['anchor']['path']],s['anchor']) for s in sites.values()) and all(sha(sources[s['anchor']['path']][s['anchor']['start_byte']:s['anchor']['start_byte']+s['anchor']['length_bytes']])==s['anchor']['span_sha256'] for s in actual['selected_spans']))
check('candidate definition references remain textual and same-source',all(all(inventory['hint_records'][i]['path']==s['anchor']['path'] and inventory['hint_records'][i]['kind']=='function-definition-hint' for i in s['candidate_same_source_definition_indices']) and s['relation_status']=='source-text-context-reviewed-runtime-edge-unresolved' and s['actual_callee_binding'] is None and not s['reachability_proven'] and not s['native_effects_proven'] for s in sites.values()))
check('all original unresolved categories and non-exhaustive coverage retained',actual['unresolved_relations']==m['UNRESOLVED'] and not actual['coverage']['shell_parsed'] and not actual['coverage']['complete_call_graph_claimed'] and actual['coverage']['selected_sites_are_not_exhaustive'] and actual['coverage']['all_inventory_records_retained_as_unresolved'])
for label,mutate in [
 ('omitted selected entry',lambda x:x['selected_sites'].pop(0)),('changed line byte offset',lambda x:x['selected_sites'][0]['anchor'].__setitem__('line_start_byte',0)),('changed full line SHA',lambda x:x['selected_sites'][0]['anchor'].__setitem__('raw_line_sha256','0'*64)),('reordered selected sites',lambda x:x['selected_sites'].reverse()),('false resolved callee',lambda x:x['selected_sites'][0].__setitem__('actual_callee_binding',{})),('false reachable edge',lambda x:x['selected_sites'][0].__setitem__('reachability_proven',True)),('printed plan promoted to external call',lambda x:x['selected_sites'][20].__setitem__('context_review','external-command-text')),('deleted lexical record index',lambda x:x['complete_lexical_partition']['command-name-hint'].pop()),('duplicated lexical index',lambda x:x['complete_lexical_partition']['command-name-hint'].append(0)),('deleted uncertain definition',lambda x:x['definition_like_register'].pop()),('false whole span hash',lambda x:x['selected_spans'][0]['anchor'].__setitem__('span_sha256','0'*64)),('body copy as independent worker',lambda x:x['copy_relationship'].__setitem__('independent_worker',True)),('payload falsely decoded',lambda x:x['copy_relationship'].__setitem__('embedded_reference_decoded',True)),('historical authority reuse',lambda x:x['copy_relationship'].__setitem__('historical_constants_current_authority',True)),('missing unresolved relation',lambda x:x['unresolved_relations'].pop()),('full shell graph claimed',lambda x:x['coverage'].__setitem__('shell_parsed',True)),('exhaustive site selection claimed',lambda x:x['coverage'].__setitem__('selected_sites_are_not_exhaustive',False)),('unknown review field',lambda x:x.__setitem__('native_success',True))]:
    bad=copy.deepcopy(stored);mutate(bad);check('reject '+label,rejected(m['validate_review'],bad,sources,inventory))
for field,value in [('native_graph_complete',True),('execution_authorized',True),('runtime_authority',True),('actual_successor_selected',True),('actual_host_state','absent'),('actual_live_bindings',{}),('actual_global_host_closure',True),('native_cases_run',True),('readme_reconciliation_step',None),('strong_safe_pause',True)]:
    bad=copy.deepcopy(stored);bad['boundaries'][field]=value;check('reject false review boundary '+field,rejected(m['validate_review'],bad,sources,inventory))
bad=copy.deepcopy(inventory);bad['hint_records'].pop();check('reject truncated full inventory',rejected(m['review_report'],sources,bad))
bad=dict(sources);first=policy['source_roots'][0]['path'];bad[first]=b'X'+bad[first][1:];check('reject same-length source drift before review',rejected(m['review_report'],bad,inventory))
bad=dict(sources);bad['../unapproved.sh']=b'exit 0\n';check('reject extra or traversing source input',rejected(m['review_report'],bad,inventory))
views=m['source_lines'](sources)
check('reject bool zero and out-of-range anchor lines',all(rejected(m['anchor'],views,0,line) for line in [True,0,6638]) and rejected(m['span_anchor'],views,0,10,9))
ast_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(ast_tree) if isinstance(node,ast.Import) for alias in node.names}
check('pure reviewer imports only hashlib json and re',imports=={'hashlib','json','re'})
check('pure reviewer has no read execution import decode or spawn entry',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in {'open','exec','eval','compile','__import__'}) or (isinstance(node.func,ast.Attribute) and node.func.attr in {'system','popen','run','b64decode','execv','spawnv','read_bytes','read_text'})) for node in ast.walk(ast_tree)))
check('README remains exact pending367',sha((root/'README.md').read_bytes())==policy['readme_at_entry_sha256'])
coverage=json.loads(history['tests/fixtures/reference/acceptance/phase-1/'+prior+'-control-coverage.json'])
check('historical361 modeled socket limitation remains exact',coverage['native_proof'] is False and any('socket-type-stat-metadata-modeled' in row.get('method','') for row in coverage['controls']))
plan=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-source-inventory-resume-planning-review-plan.json']);gaps=json.loads(history[plan['requirements_retained_by_exact_binding'][0]]);norm=gaps['full_normative_rows']
check('all16 full native gaps unselected and unproven',[row['inherited_gap']['id'] for row in gaps['full_original_native_gap_rows348']]==policy['inherited_gap_ids'] and all(row['status']=='required-not-selected-refined-or-proven' and not row['native_status_promoted'] for row in gaps['full_original_native_gap_rows348']))
check('46 original proofs and52 native cases still unproven and unrun',len(norm['qualified_proof_reconciliation'])==46 and all(row['status']=='required-not-proven' for row in norm['qualified_proof_reconciliation']) and len(norm['native_case_templates'])==52 and all(row['status']=='required-not-run' for row in norm['native_case_templates']))
check('all12 independent raw native groups remain uncaptured',len(gaps['full_original_evidence_group_rows335'])==12 and all(row['status']=='required-native-evidence-not-captured' for row in gaps['full_original_evidence_group_rows335']))
check('finite roadmap and final README obligation retained',[row['step'] for row in plan['roadmap']]==list(range(359,369)) and plan['readme_reconciliation_step']==367 and plan['conditional_pause_step']==368)
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
