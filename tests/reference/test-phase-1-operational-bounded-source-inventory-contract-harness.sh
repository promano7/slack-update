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

root=Path(sys.argv[1])
name='phase-1-operational-bounded-source-inventory-contract'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
module=runpy.run_path(str(root/'tools/reference'/(name+'.py')))
passes=0
def check(label,value):
    global passes
    if not value:
        raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError):return True
    return False
def load(tail):return json.loads((fixture/(name+'-'+tail+'.json')).read_bytes())
policy=load('policy');contract=load('contract');confirmed=load('confirmed359');receipt=load('step359-user-acceptance')
check('all1816 accepted359 source bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1816)
history={}
for rel,digest in policy['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):
        raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if hashlib.sha256(raw).hexdigest()!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted359 bytes preserved with additive CHANGELOG only',len(history)==1816)
check('carried confirmed359 representation exact',hashlib.sha256((fixture/(name+'-confirmed359.json')).read_bytes()).hexdigest()==policy['expected_confirmation_sha256'])
check('complete pasted359 message and report-based acceptance',module['validate_return'](confirmed,receipt,policy))
check('full bounded lexical design contract exact',module['validate_contract'](contract,policy))
check('full contract file SHA exact',hashlib.sha256((fixture/(name+'-contract.json')).read_bytes()).hexdigest()==policy['expected_contract_sha256'])
sources={row['path']:history[row['path']] for row in policy['source_roots']}
check('four exact review sources fit byte and line bounds',module['validate_bundle'](policy['source_roots'],sources,policy['source_roots'],contract['limits']))
check('README remains exact for reconciliation367',hashlib.sha256((root/'README.md').read_bytes()).hexdigest()==policy['readme_at_entry_sha256'])
check('future reader implementation and eighteen controls remain pending361',contract['state']=='design-only-reader-and-inventory-implementation-pending361' and len(contract['required_controls361'])==18)
gaps=json.loads(history[contract['retained_requirements'][0]])
check('all16 inherited gap identities retained',[r['inherited_gap']['id'] for r in gaps['full_original_native_gap_rows348']]==policy['inherited_gap_ids'])
check('all16 native gap evidence and components stay null',all(r['status']=='required-not-selected-refined-or-proven' and not r['native_status_promoted'] and all(r[k] is None for k in ['actual_model_or_component','actual_native_event_relation','actual_independent_evidence']) for r in gaps['full_original_native_gap_rows348']))
norm=gaps['full_normative_rows']
check('all46 original native proofs remain unproven',len(norm['qualified_proof_reconciliation'])==46 and all(r['status']=='required-not-proven' for r in norm['qualified_proof_reconciliation']))
check('all52 two-platform native cases remain unrun',len(norm['native_case_templates'])==52 and all(r['status']=='required-not-run' for r in norm['native_case_templates']))
check('all12 original raw native evidence groups remain uncaptured',len(gaps['full_original_evidence_group_rows335'])==12 and all(r['status']=='required-native-evidence-not-captured' for r in gaps['full_original_evidence_group_rows335']))
tree=ast.parse((root/'tools/reference'/(name+'.py')).read_text())
imports={node.names[0].name for node in ast.walk(tree) if isinstance(node,ast.Import)}
check('current data validator imports only hashlib json and re',imports=={'hashlib','json','re'})
check('data validator has no source execution import eval or process entry',not any(isinstance(node,ast.Call) and isinstance(node.func,ast.Name) and node.func.id in {'exec','eval','compile','__import__','open'} for node in ast.walk(tree)))
for key,value in [('strong_safe_pause',True),('commit_full','invented'),('runtime_authority',True),('user_worktree_clean',False),('user_head_matches_origin',False),('actual_global_host_closure',True)]:
    changed=copy.deepcopy(confirmed);changed[key]=value
    check('reject changed359 confirmation '+key,rejected(module['validate_return'],changed,receipt,policy))
changed=copy.deepcopy(receipt);changed['text']=receipt['text'][:-12]
check('reject incomplete359 pasted message',rejected(module['validate_return'],confirmed,changed,policy))
changed=copy.deepcopy(receipt);changed['capture_basis']='original-terminal-byte-capture'
check('reject invented original terminal capture',rejected(module['validate_return'],confirmed,changed,policy))
for label,mutate in [
 ('reader falsely implemented',lambda c:c.update(state='reader-implemented')),
 ('native graph falsely complete',lambda c:c['report_boundaries'].update(native_graph_complete=True)),
 ('runtime authority',lambda c:c['report_boundaries'].update(runtime_authority=True)),
 ('missing native unknown category',lambda c:c['required_unresolved_relation_categories'].pop()),
 ('record budget increased',lambda c:c['limits'].update(max_total_hint_records=40001)),
 ('bool used as integer source bound',lambda c:c['limits'].update(max_sources=True)),
 ('source execute rule removed',lambda c:c['input_rules'].pop()),
 ('lexical uncertainty rule removed',lambda c:c['lexical_semantics'].pop()),
 ('README obligation lost',lambda c:c.update(readme_reconciliation_step=None)),
 ('future control omitted',lambda c:c['required_controls361'].pop())]:
    changed=copy.deepcopy(contract);mutate(changed)
    check('reject contract '+label,rejected(module['validate_contract'],changed,policy))
for path in ['', '/etc/passwd', '../outside.sh', 'tools/../outside.sh', 'tools//bad.sh', './tools/a.sh', 'tools/a\\b.sh', 'tools/a\n.sh', 'tools/é.sh', 'a'*241]:
    check('reject unsafe source path '+repr(path),rejected(module['validate_path'],path))
check('safe explicit relative ASCII source path accepted',module['validate_path']('tools/reference/example.sh'))
limits=contract['limits']
for label,raw in [('invalid UTF8',b'\xff'),('NUL',b'x\0y'),('empty source',b'')]:
    check('reject '+label,rejected(module['validate_source_bytes'],raw,limits))
for label,field,cap,raw in [('single source bytes','max_source_bytes',3,b'abcd'),('line bytes including terminator','max_line_bytes_including_terminator',3,b'abc\n'),('source lines','max_lines_per_source',1,b'a\nb\n')]:
    lowered=dict(limits);lowered[field]=cap
    check('hard fail '+label,rejected(module['validate_source_bytes'],raw,lowered))
for label,field,cap in [('total bytes','max_total_source_bytes',1),('total lines','max_total_lines',1),('source count','max_sources',3)]:
    lowered=dict(limits);lowered[field]=cap
    check('hard fail '+label,rejected(module['validate_bundle'],policy['source_roots'],sources,policy['source_roots'],lowered))
changed=copy.deepcopy(policy['source_roots']);changed[0]['execution_authorized']=True
check('historical executable cannot become runnable root',rejected(module['validate_bundle'],changed,sources,policy['source_roots'],limits))
changed_sources=dict(sources);changed_sources[next(iter(sources))]+=b'\n'
check('observed source byte drift rejects bundle',rejected(module['validate_bundle'],policy['source_roots'],changed_sources,policy['source_roots'],limits))
def anchor(path,raw,line_number,kind='command-name-hint'):
    lines=module['physical_lines'](raw);line=lines[line_number-1]
    text,short=module['snippet_prefix'](line,limits['max_snippet_utf8_bytes'])
    return {'path':path,'source_sha256':module['sha'](raw),'line_number':line_number,
            'line_start_byte':sum(map(len,lines[:line_number-1])),'line_length_bytes':len(line),
            'raw_line_sha256':module['sha'](line),'snippet':text,'snippet_truncated':short,
            'kind':kind,'semantic_status':module['SEMANTIC_STATUS']}
path=policy['source_roots'][0]['path'];example=anchor(path,sources[path],3)
check('exact real source byte anchor accepted as lexical only',module['validate_anchor'](example,sources,contract))
synthetic={'tools/reference/anchor-example.sh':'# é\r\nline\r\nlast'.encode()}
row=anchor(next(iter(synthetic)),next(iter(synthetic.values())),2)
check('CRLF and nonASCII preserve physical line byte offsets',row['line_start_byte']==6 and row['line_length_bytes']==6 and module['validate_anchor'](row,synthetic,contract))
check('final line without newline preserves exact length',module['physical_lines'](b'a\nb')==[b'a\n',b'b'])
long={'tools/reference/long-example.sh':b'a'*511+'é'.encode()+b'\n'}
longrow=anchor(next(iter(long)),next(iter(long.values())),1)
check('snippet truncation respects UTF8 codepoint boundary',len(longrow['snippet'].encode())==511 and longrow['snippet_truncated'] and module['validate_anchor'](longrow,long,contract))
for key,value in [('line_number',0),('line_number',True),('line_start_byte',1),('line_length_bytes',0),('raw_line_sha256','0'*64),('source_sha256','0'*64),('snippet','changed'),('semantic_status','confirmed-native-call'),('kind','resolved-native-command')]:
    changed=copy.deepcopy(example);changed[key]=value
    check('reject false anchor '+key+' '+str(value),rejected(module['validate_anchor'],changed,sources,contract))
changed=copy.deepcopy(longrow);changed['snippet_truncated']=False
check('short snippet cannot claim full line',rejected(module['validate_anchor'],changed,long,contract))
report={'schema':1,'scope':module['SCOPE'],'review_sources':policy['source_roots'],'hint_records':[],
        'unresolved_relations':list(module['REQUIRED_UNRESOLVED']),
        'coverage':{'kind':'bounded-textual-hints-only','shell_parsed':False,'runtime_relations_verified':False,'absence_of_effects_proven':False},
        'boundaries':module['REPORT_BOUNDARIES']}
check('zero hints design still retains every required native unknown',module['validate_report_design'](report,sources,policy['source_roots'],contract))
for field in ['native_graph_complete','execution_authorized','runtime_authority','operational_conformance']:
    changed=copy.deepcopy(report);changed['boundaries'][field]=True
    check('reject report '+field,rejected(module['validate_report_design'],changed,sources,policy['source_roots'],contract))
changed=copy.deepcopy(report);changed['unresolved_relations']=[]
check('empty hints cannot erase unresolved native relations',rejected(module['validate_report_design'],changed,sources,policy['source_roots'],contract))
changed=copy.deepcopy(report);changed['coverage']['absence_of_effects_proven']=True
check('lexical hints cannot prove no effects',rejected(module['validate_report_design'],changed,sources,policy['source_roots'],contract))
changed=copy.deepcopy(report);changed['hint_records']=[example,example]
check('repeated lexical hints remain distinct ordered records',module['validate_report_design'](changed,sources,policy['source_roots'],contract))
limited=copy.deepcopy(contract);limited['limits']['max_hint_records_per_source']=1
check('per-source record budget hard fails rather than truncates',rejected(module['validate_report_design'],changed,sources,policy['source_roots'],limited))
limited=copy.deepcopy(contract);limited['limits']['max_total_hint_records']=1
check('total record budget hard fails rather than truncates',rejected(module['validate_report_design'],changed,sources,policy['source_roots'],limited))
changed=copy.deepcopy(report);changed['hint_records']=[anchor(path,sources[path],4),example]
check('out-of-order byte anchors rejected',rejected(module['validate_report_design'],changed,sources,policy['source_roots'],contract))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
