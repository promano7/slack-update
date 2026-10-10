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
import os
import re
import runpy
import stat
import subprocess
import sys
import tempfile

root=Path(sys.argv[1]);name='phase-1-operational-readonly-source-inventory';prior='phase-1-operational-bounded-source-inventory-contract'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(name+'.py')
m=runpy.run_path(str(tool));passes=0;passed=[]
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;passed.append(label);print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError,OSError):return True
    return False
def load(tail):return json.loads((fixture/(name+'-'+tail+'.json')).read_bytes())
policy=load('policy');confirmed=load('confirmed360');receipt=load('step360-user-acceptance')
contract=json.loads((fixture/(prior+'-contract.json')).read_bytes())
contract_policy=json.loads((fixture/(prior+'-policy.json')).read_bytes())
check('all1823 accepted360 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1823)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    if hashlib.sha256(raw).hexdigest()!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted360 bytes exact with additive CHANGELOG only',len(history)==1823)
check('carried external confirmed360 bytes exact',hashlib.sha256((fixture/(name+'-confirmed360.json')).read_bytes()).hexdigest()==policy['expected_confirmation_sha256'])
text=receipt['text'];raw=text.encode()
check('complete360 message representation and capture limitation retained',hashlib.sha256(raw).hexdigest()==receipt['sha256']==policy['accepted_receipt_sha256'] and len(raw)==receipt['size_bytes']==policy['accepted_receipt_size_bytes'] and receipt['capture_basis']=='complete-user-message-text-transcribed-as-UTF8-with-final-storage-newline;not-original-terminal-byte-capture')
check('all81 exact ordered360 PASS labels and summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered360_labels'] and text.count('Result: PASS (81 passes, 0 failures)')==1)
message=policy['accepted_commit_message'];head='9a9cd12 (HEAD -> main, origin/main, origin/HEAD) '+message
check('exact reported360 commit stats and seven created paths',text.count('[main 9a9cd12] '+message)==1 and text.count('8 files changed, 2628 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step360_created_paths'])
check('reported360 push clean status and matching heads',text.count('aedcbc3..9a9cd12  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n') and confirmed['user_worktree_clean'] and confirmed['user_head_matches_origin'])
check('360 accepted without inventing full ID or new pause',confirmed['commit_prefix']=='9a9cd12' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
check('frozen360 contract validates unchanged',m['validate_contract'](contract,contract_policy))
old_source=(root/'tools/reference'/(prior+'.py')).read_text();expected_prefix=old_source[:old_source.index('\ndef validate_return(')].replace('"""Validate the bounded inventory data contract; no filesystem reader or scanner."""','"""Inspect bound repository source bytes without executing their contents."""')
check('frozen360 data rules copied statically and exactly',tool.read_text().split('\n# Exact frozen360')[0]==expected_prefix)
check('explicit metadata bindings match accepted360 source files',m['METADATA_BINDINGS']==policy['metadata_bindings'] and all(hashlib.sha256(history[row['path']]).hexdigest()==row['sha256'] for row in m['METADATA_BINDINGS']))
actual=m['inventory_report'](str(root),policy['source_roots'],contract)
stored=load('inventory')
check('complete current inventory equals stored full source anchors',actual==stored and hashlib.sha256((fixture/(name+'-inventory.json')).read_bytes()).hexdigest()==policy['expected_inventory_sha256'])
check('all15106 lexical records retained with distinct source roles',len(actual['hint_records'])==policy['expected_inventory_record_count']==15106 and {row['path']:sum(x['path']==row['path'] for x in actual['hint_records']) for row in policy['source_roots']}==policy['expected_inventory_counts_by_source'])
check('every actual record remains a lexical unresolved candidate',all(row['semantic_status']==m['SEMANTIC_STATUS'] for row in actual['hint_records']))
check('all required native unknowns and closed report boundaries retained',actual['unresolved_relations']==list(m['REQUIRED_UNRESOLVED']) and actual['boundaries']==m['REPORT_BOUNDARIES'])
check('README unchanged pending367',hashlib.sha256((root/'README.md').read_bytes()).hexdigest()==policy['readme_at_entry_sha256'])
source_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(source_tree) if isinstance(node,ast.Import) for alias in node.names}
check('reader imports no process network dynamic-module or shell library',imports=={'hashlib','json','re','argparse','os','stat','sys'})
forbidden_names={'exec','eval','compile','__import__'};forbidden_attrs={'system','popen','execv','execve','execl','spawnv','spawnve','fork'}
check('reader has no inspected-code evaluation or process-spawn call',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in forbidden_names) or (isinstance(node.func,ast.Attribute) and node.func.attr in forbidden_attrs)) for node in ast.walk(source_tree)))
limits=contract['limits']
def descriptor(path,raw,role='isolated-private-test-source-not-native-binding'):
    return {'path':path,'sha256':m['sha'](raw),'size_bytes':len(raw),'role':role,'review_selection_only':True,'execution_authorized':False,'actual_native_binding':None}
def put(root,path,raw):
    target=root/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw);return descriptor(path,raw)
def inspect(root,rows,c=contract):return m['inventory_report'](str(root),rows,c)
def read(root,rows,l=limits):return m['read_source_bundle'](str(root),rows,rows,l)
with tempfile.TemporaryDirectory(prefix='slack-update361-controls-') as temporary:
    tmp=Path(temporary);marker=tmp/'sentinel'
    dangerous=("#!/bin/bash\nprintf hacked > "+str(marker)+"\n$(touch "+str(marker)+")\n`touch "+str(marker)+"`\nsource missing\neval 'false'\n").encode()
    row=put(tmp,'dangerous.sh',dangerous);result=inspect(tmp,[row])
    check('control361 dangerous-shell-sentinel-remains-unexecuted',not marker.exists() and bool(result['hint_records']))
    encoded=put(tmp,'encoded.sh',b'# BEGIN_EMBEDDED_PAYLOAD\nYmFzaCAtYyAndG91Y2ggU0VOVElORUwn\n# END_EMBEDDED_PAYLOAD\n')
    report=inspect(tmp,[encoded])
    check('control361 decoded-payload-remains-uninterpreted',not marker.exists() and any(r['kind']=='generated-payload-marker-hint' for r in report['hint_records']) and encoded['sha256']==m['sha']((tmp/'encoded.sh').read_bytes()))
    safe=put(tmp,'safe/source.sh',b'echo reviewed\n')
    (tmp/'final-link.sh').symlink_to(tmp/'safe/source.sh');linked=dict(safe,path='final-link.sh')
    check('control361 final-symlink-refused',rejected(read,tmp,[linked]))
    (tmp/'ancestor-link').symlink_to(tmp/'safe',target_is_directory=True);linked=dict(safe,path='ancestor-link/source.sh')
    check('control361 ancestor-symlink-refused',rejected(read,tmp,[linked]))
    check('repository root symlink refused',rejected(read,tmp/'ancestor-link',[dict(safe,path='source.sh')]))
    bad_paths=['../outside.sh','/etc/passwd','safe/../source.sh','safe//source.sh','safe/source\n.sh','safe\\source.sh']
    check('control361 traversal-absolute-control-paths-refused',all(rejected(read,tmp,[dict(safe,path=p)]) for p in bad_paths))
    (tmp/'directory.sh').mkdir();os.mkfifo(tmp/'fifo.sh')
    check('special-file controls have actual FIFO directory and device metadata',stat.S_ISFIFO((tmp/'fifo.sh').stat().st_mode) and stat.S_ISDIR((tmp/'directory.sh').stat().st_mode) and stat.S_ISCHR(os.stat('/dev/null').st_mode))
    cases=[(tmp,'fifo.sh'),(tmp,'directory.sh'),(Path('/dev'),'null')]
    real_read=m['os'].read;real_stat=m['os'].stat;socket_classifications=0
    def never_read(fd,size):raise AssertionError('special-file content must never be read')
    def socket_metadata(path,*args,**kwargs):
        global socket_classifications
        if path=='socket.sh' and kwargs.get('dir_fd') is not None:
            socket_classifications+=1
            return os.stat_result((stat.S_IFSOCK|0o600,0,0,0,0,0,0,0,0,0))
        return real_stat(path,*args,**kwargs)
    m['os'].read=never_read
    try:
        refused=all(rejected(read,parent,[dict(safe,path=path)]) for parent,path in cases)
        m['os'].stat=socket_metadata
        refused=refused and rejected(read,tmp,[dict(safe,path='socket.sh')]) and socket_classifications==1
    finally:
        m['os'].read=real_read;m['os'].stat=real_stat
    check('control361 FIFO-device-socket-directory-refused-without-blocking',refused)
    invalid=[put(tmp,'bad-utf8.sh',b'\xff\n'),put(tmp,'nul.sh',b'a\0b\n')]
    check('control361 invalid-UTF8-and-NUL-refused',all(rejected(read,tmp,[r]) for r in invalid))
    changed=copy.deepcopy(contract);changed['limits']['max_source_bytes']=safe['size_bytes']-1
    changed_total=copy.deepcopy(contract);changed_total['limits']['max_total_source_bytes']=safe['size_bytes']-1
    check('control361 one-source-and-total-byte-bounds-hard-fail',rejected(inspect,tmp,[safe],changed) and rejected(inspect,tmp,[safe],changed_total))
    lines=put(tmp,'lines.sh',b'echo first\necho second\n')
    small_line=copy.deepcopy(contract);small_line['limits']['max_line_bytes_including_terminator']=2
    small_count=copy.deepcopy(contract);small_count['limits']['max_lines_per_source']=1
    small_total=copy.deepcopy(contract);small_total['limits']['max_total_lines']=1
    check('control361 line-length-and-total-line-bounds-hard-fail',all(rejected(inspect,tmp,[lines],c) for c in [small_line,small_count,small_total]))
    one_record=copy.deepcopy(contract);one_record['limits']['max_hint_records_per_source']=1
    total_record=copy.deepcopy(contract);total_record['limits']['max_total_hint_records']=1
    check('control361 one-source-and-total-record-bounds-hard-fail',rejected(inspect,tmp,[lines],one_record) and rejected(inspect,tmp,[lines],total_record))
    real_read=m['os'].read
    def tampered_read(fd,size):
        content=real_read(fd,size)
        return (b'X'+content[1:]) if content else content
    m['os'].read=tampered_read
    try:sha_refused=rejected(read,tmp,[safe])
    finally:m['os'].read=real_read
    changed_stat=False
    def metadata_change(fd,size):
        global changed_stat
        data=real_read(fd,size)
        if not changed_stat:
            observed=(tmp/'safe/source.sh').stat();os.utime(tmp/'safe/source.sh',ns=(observed.st_atime_ns,observed.st_mtime_ns+1000000000));changed_stat=True
        return data
    m['os'].read=metadata_change
    try:metadata_refused=rejected(read,tmp,[safe])
    finally:m['os'].read=real_read
    row=put(tmp,'safe/source.sh',b'echo reviewed\n')
    def short_read(fd,size):return b''
    m['os'].read=short_read
    try:short_refused=rejected(read,tmp,[row])
    finally:m['os'].read=real_read
    grew=False
    def grow_file(fd,size):
        global grew
        data=real_read(fd,size)
        if not grew:
            with (tmp/'safe/source.sh').open('ab') as handle:handle.write(b'X')
            grew=True
        return data
    m['os'].read=grow_file
    try:growth_refused=rejected(read,tmp,[row])
    finally:m['os'].read=real_read
    row=put(tmp,'safe/source.sh',b'echo reviewed\n')
    check('control361 stat-read-SHA-size-drift-refused',sha_refused and metadata_refused and short_refused and growth_refused)
    rebound=dict(row,sha256='0'*64);other=dict(row,path='unapproved.sh')
    check('control361 duplicate-unapproved-or-rebound-root-refused',rejected(read,tmp,[row,row]) and rejected(m['read_source_bundle'],str(tmp),[other],[row],limits) and rejected(read,tmp,[rebound]))
    anchored=put(tmp,'anchored.sh','# é\r\necho é\r\necho last'.encode());report=inspect(tmp,[anchored])
    row2=next(r for r in report['hint_records'] if r['line_number']==2)
    row3=next(r for r in report['hint_records'] if r['line_number']==3)
    check('control361 LF-CRLF-and-nonASCII-anchors-preserve-bytes',row2['line_start_byte']==6 and row2['line_length_bytes']==9 and row2['raw_line_sha256']==m['sha']('echo é\r\n'.encode()) and row3['line_start_byte']==15 and row3['line_length_bytes']==9)
    contexts=put(tmp,'contexts.sh',b'# eval $(false)\nprintf "exec $dynamic"\ncat <<EOF\nexec hypothetical\nEOF\npython3 <<PY\nsource = "foreign"\nPY\n')
    report=inspect(tmp,[contexts]);matched={r['line_number'] for r in report['hint_records']}
    check('control361 comments-strings-here-doc-foreign-code-remain-lexical-uncertainty',{1,2,3,4,6,7}.issubset(matched) and all(r['semantic_status']==m['SEMANTIC_STATUS'] for r in report['hint_records']))
    blank=put(tmp,'blank.sh',b'\n# 123\n');report=inspect(tmp,[blank])
    check('control361 empty-hints-retain-open-native-relations',not report['hint_records'] and report['unresolved_relations']==list(m['REQUIRED_UNRESOLVED']) and not report['boundaries']['native_graph_complete'])
    body=put(tmp,'worker.sh',b'echo identical\n');copyrow=put(tmp,'generated.sh',b'echo identical\n');copyrow['role']='historical-generated-artifact-not-a-second-independent-worker'
    report=inspect(tmp,[body,copyrow])
    check('control361 generated-copy-not-independent-worker',len(report['review_sources'])==2 and report['review_sources'][1]['role']==copyrow['role'] and not report['boundaries']['native_graph_complete'])
    repeated=put(tmp,'repeated.sh',b'echo again\necho again\n');report=inspect(tmp,[repeated])
    check('control361 ordered-repeated-hints-remain-distinct',[r['line_number'] for r in report['hint_records']]==[1,2] and report['hint_records'][0]['raw_line_sha256']==report['hint_records'][1]['raw_line_sha256'])
    bad=copy.deepcopy(report);bad['boundaries']['native_graph_complete']=True
    bad2=copy.deepcopy(report);bad2['boundaries']['runtime_authority']=True
    observed={repeated['path']:(tmp/repeated['path']).read_bytes()}
    check('control361 false-native-authority-or-completeness-refused',rejected(m['validate_report_design'],bad,observed,[repeated],contract) and rejected(m['validate_report_design'],bad2,observed,[repeated],contract))
    before=len(os.listdir('/proc/self/fd'))
    for _ in range(20):
        read(tmp,[repeated]);rejected(read,tmp,[linked]);rejected(read,tmp,[rebound])
    after=len(os.listdir('/proc/self/fd'))
    check('reader closes descriptors on repeated success and failure paths',before==after)
    sentinel_rebound=dict(repeated,execution_authorized=True)
    check('reader refuses an executable source descriptor',rejected(read,tmp,[sentinel_rebound]))
    too_many=dict(limits,max_sources=1)
    check('source count budget enforced before opening content',rejected(read,tmp,[body,copyrow],too_many))
    too_long=dict(repeated,path='a'*241)
    check('source path byte budget enforced',rejected(read,tmp,[too_long]))
    longline=put(tmp,'longline.sh',b'echo '+b'a'*505+'é'.encode()+b'\n');report=inspect(tmp,[longline])
    check('actual scanner short snippet preserves UTF8 boundary flag',report['hint_records'][0]['snippet_truncated'] and len(report['hint_records'][0]['snippet'].encode())==512)
    literal=put(tmp,'literal.sh',b'f() {\nexec "$cmd" | cat <<EOF\n# base64\ntrap wait EXIT\n')
    report=inspect(tmp,[literal]);expected=[(1,'function-definition-hint'),(1,'command-name-hint'),(2,'source-eval-exec-hint'),(2,'pipeline-redirection-hint'),(2,'here-document-hint'),(2,'command-name-hint'),(2,'dynamic-command-hint'),(3,'generated-payload-marker-hint'),(4,'command-name-hint'),(4,'trap-process-hint')]
    check('separately written literal hint-kind and order vector matches',[(r['line_number'],r['kind']) for r in report['hint_records']]==expected)
    clean_cli=subprocess.run([sys.executable,'-B',str(tool),'--inspect-repository',str(root)],capture_output=True)
    check('successful CLI emits only complete bounded JSON report',clean_cli.returncode==0 and not clean_cli.stderr and json.loads(clean_cli.stdout)==stored)
    fake=tmp/'cli-copy';fake.mkdir();bindings=m['METADATA_BINDINGS']
    for descriptor_row in bindings:
        source=root/descriptor_row['path'];target=fake/descriptor_row['path'];target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(source.read_bytes())
    for row in policy['source_roots']:put(fake,row['path'],history[row['path']])
    failed_path=fake/policy['source_roots'][0]['path'];failed_path.write_bytes(failed_path.read_bytes()+b'\n')
    failed_cli=subprocess.run([sys.executable,'-B',str(tool),'--inspect-repository',str(fake)],capture_output=True)
    check('CLI source failure emits no successful partial report',failed_cli.returncode==1 and not failed_cli.stdout and failed_cli.stderr.startswith(b'ERROR: '))
    corrupt=fake/bindings[0]['path'];corrupt.write_bytes(corrupt.read_bytes()+b'\n')
    failed_cli=subprocess.run([sys.executable,'-B',str(tool),'--inspect-repository',str(fake)],capture_output=True)
    check('CLI rejects changed frozen metadata before source scanning',failed_cli.returncode==1 and not failed_cli.stdout)
coverage=load('control-coverage')
check('all18 exact original control families have passed concrete repository controls',[r['id'] for r in coverage['controls']]==contract['required_controls361'] and all(r['test_label'] in passed for r in coverage['controls']) and coverage['native_proof'] is False)
gap_path=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-source-inventory-resume-planning-review-plan.json'])['requirements_retained_by_exact_binding'][0]
gaps=json.loads(history[gap_path]);norm=gaps['full_normative_rows']
check('all16 native gaps stay unresolved despite source inventory',[r['inherited_gap']['id'] for r in gaps['full_original_native_gap_rows348']]==policy['inherited_gap_ids'] and all(r['status']=='required-not-selected-refined-or-proven' and not r['native_status_promoted'] for r in gaps['full_original_native_gap_rows348']))
check('46 native proofs and52 native cases remain unproven and unrun',len(norm['qualified_proof_reconciliation'])==46 and all(r['status']=='required-not-proven' for r in norm['qualified_proof_reconciliation']) and len(norm['native_case_templates'])==52 and all(r['status']=='required-not-run' for r in norm['native_case_templates']))
check('12 independent native evidence groups remain uncaptured',len(gaps['full_original_evidence_group_rows335'])==12 and all(r['status']=='required-native-evidence-not-captured' for r in gaps['full_original_evidence_group_rows335']))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
