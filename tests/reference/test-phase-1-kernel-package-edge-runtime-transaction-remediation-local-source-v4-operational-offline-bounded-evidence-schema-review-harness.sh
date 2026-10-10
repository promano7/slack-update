#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
from dataclasses import FrozenInstanceError, replace
from types import SimpleNamespace
import ast
import copy
import hashlib
import json
import runpy
import subprocess
import sys
import tempfile

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-envelope.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review.md': '088ad52e774153f21f7c677536da6962bc1eb9779ec0113a530ca80bdb7efb01', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review-checkpoint-confirmation.json': 'eb2d008e13fa45dea3ff650b38c1277a774c0d03556b3da01194c6a982339c92', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review-policy.json': '7d9642615ca0a844ebae10294740d9f37abe719076b24ac0ada781218a8865a6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review-schema-contract.json': 'f010a5d224c9124bda20e8edbe7a77750aaa34861d00c82e31bedc9d09d4ded2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review-evidence-map.json': '65d7a433dd81eeaf9e2ef3825c36d9d5c6a1be5a1ed2d359dd3077a6e6dd35cd', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review-retained-obligations.json': '71aa07220e8d91a1710787419274249a17e297a8ec6298201f098b6900b59a83', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review-step349-user-acceptance.json': '0a6280600037179248d1243bde880d084c715b49489e47f4e5349bc911847df1', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-envelope.py': 'b4e3535d5007cfd9145b5aa0d67dc3815049336ac2408859c1ae1793ef943140'}
passes=0
def check(label,condition):
    global passes
    if not condition:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def sha(raw):return hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((fixture/(base+'-'+tail+'.json')).read_bytes())
def fails(fn,*args):
    try:fn(*args)
    except ValueError:return True
    return False
def path(relative):
    require=type(relative)is str and relative and not relative.startswith('/') and '\\' not in relative and all(p not in ('','.','..') for p in relative.split('/'))
    if not require:raise ValueError('unsafe bound source path')
    p=root/relative
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute():raise ValueError('unsafe source file')
    return p
for rel,digest in OWN_HASHES.items():check('exact current350 input '+Path(rel).name,sha(path(rel).read_bytes())==digest)
policy=load('policy');contract=load('schema-contract');retained=load('retained-obligations');evidence_map=load('evidence-map');receipt=load('step349-user-acceptance');confirmation=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    raw=path(rel).read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted349 source drift: '+rel)
    history[rel]=raw
check('all1728 accepted349 bytes and exact historical CHANGELOG suffix',len(history)==1728)
raw=receipt['text'].encode('utf-8');lines=receipt['text'].splitlines()
check('complete17125-byte original349 receipt retained without normalization',len(raw)==17125 and sha(raw)=='b0ca5fe14f44d50244668f533b9d7ed8b54f54c27623940a0158b0b55b8e0d78' and receipt['ordered_output_normalization']=='none' and receipt['original_display_size_bytes']==len(raw) and receipt['original_display_sha256']==sha(raw))
check('complete179 predecessor labels match original receipt in exact order',[l for l in lines if l.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (179 passes, 0 failures)')==1)
check('reported522666b exact tenfiles7267 nine-created-path commit and successful push',lines.count('[main 522666b] Phase 1 step 349: plan offline evidence comparator batch')==1 and lines.count(' 10 files changed, 7267 insertions(+)')==1 and sum(l.startswith(' create mode 100644 ') for l in lines)==9 and '   83ae543..522666b  main -> main' in lines)
check('complete clean matching final HEAD-origin receipt and unknown full commit',lines[-3:-1]==['522666b (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 349: plan offline evidence comparator batch']*2 and confirmation['commit_full']is None and confirmation['evidence_sha256']==sha(raw) and all(confirmation[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
oldplan=json.loads(history[retained['accepted349_plan_binding']['path']]);oldretained=json.loads(history[retained['accepted349_retained_binding']['path']])
check('complete349 retained native source bindings counts and nine pause requirements',retained['counts']==oldplan['counts'] and retained['source_bindings']==oldretained['source_bindings'] and retained['original_pause_conditions']==oldretained['original_pause_conditions'] and len(retained['original_pause_conditions'])==9)
for binding in [retained['accepted349_plan_binding'],retained['accepted349_retained_binding']]+list(retained['source_bindings'].values())+list(retained['model_modules'].values()):
    check('source-bound unchanged inherited input '+Path(binding['path']).name,sha(history[binding['path']])==binding['sha256'])
oracle=json.loads(history[evidence_map['source_oracle_binding']['path']])
check('original335 oracle full bytes bound',sha(history[evidence_map['source_oracle_binding']['path']])==evidence_map['source_oracle_binding']['sha256'])
for rows,originals,kind in [(evidence_map['groups'],oracle['evidence_groups'],'group'),(evidence_map['cases'],oracle['cases'],'case')]:
    check('complete original oracle '+kind+' rows retained',len(rows)==len(originals))
    for i,(row,original)in enumerate(zip(rows,originals)):
        if row['position']!=i or row['canonical_full_row_sha256']!=sha(json.dumps(original,sort_keys=True,separators=(',',':')).encode()):raise ValueError('source-bound oracle index drift')
check('all52 native templates remain unrun and26 each platform',len(evidence_map['cases'])==52 and all(r['status']=='required-not-run' and r['actual_result']is None for r in evidence_map['cases']) and all(sum(r['platform']==p for r in evidence_map['cases'])==26 for p in ['Slackware-15.0','Slackware-current']))
check('all12 native evidence groups uncaptured and full independence contract retained',len(evidence_map['groups'])==12 and all(g['status']=='required-native-evidence-not-captured' for g in evidence_map['groups']) and evidence_map['independence_contract']==oracle['independence_contract'])

m=SimpleNamespace(**runpy.run_path(str(root/'tools/reference'/module)))
check('source original case and group universes exact',m.GROUP_IDS==tuple(g['id']for g in oracle['evidence_groups']) and m.CASE_IDS==tuple(dict.fromkeys(c['case_id']for c in oracle['cases'])))
check('all schema bounds exactly match reviewed contract',contract['limits']==dict(max_wire_bytes=m.MAX_WIRE_BYTES,max_depth=m.MAX_DEPTH,max_artifacts=m.MAX_ARTIFACTS,max_artifact_bytes=m.MAX_ARTIFACT_BYTES,max_total_artifact_bytes=m.MAX_TOTAL_ARTIFACT_BYTES,max_identity_label_chars=128,max_logical_id_chars=64))
for role,cls in [('envelope',m.Envelope),('identity',m.Identity),('artifact',m.Artifact),('group',m.Group)]:check('closed immutable source schema '+role,list(cls.__dataclass_fields__)==contract['closed_fields'][role])

# Independent literal metadata fixture. Expectations are not generated from a
# subject/model reducer or from the codec's mapping output.
literal=dict(schema_version=1,origin='private-fixture',case_id='actual-selector',identity=dict(platform='Slackware-15.0',platform_version=None,boot_id=None,source_epoch=None,original_attempt=None,test_run_id=None,subject_source_sha256=None),artifacts=[],groups=[dict(group_id=g['id'],status='missing',artifact_ids=[])for g in oracle['evidence_groups']])
def wire(value):return(json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False)+'\n').encode('ascii')
encoded=wire(literal);env=m.decode(encoded)
check('independent literal envelope decodes exact identity missing states and canonical bytes',m.encode(env)==encoded and env.identity.platform=='Slackware-15.0' and all(g.status=='missing'and g.artifact_ids==()for g in env.groups))
check('unknown identity stays null rather than historical default',all(getattr(env.identity,k)is None for k in ('platform_version','boot_id','source_epoch','original_attempt','test_run_id','subject_source_sha256')))
for case in oracle['cases']:
    data=copy.deepcopy(literal);data['identity']['platform']=case['platform'];data['case_id']=case['case_id'];decoded=m.decode(wire(data));a=m.assess(decoded)
    check('shape valid private fixture never runs native case '+case['platform']+'/'+case['case_id'],a.schema_valid and not a.native_conformance and a.native_cases_run==0 and a.native_proofs_added==0 and not a.runtime_authority)

def descriptor(i=0,size=3,digest=None):return dict(logical_id='raw-'+str(i),evidence_group=m.GROUP_IDS[i%12],sha256=digest if digest is not None else sha(b'raw'),size_bytes=size,media_type='application/octet-stream',producer_role='unattributed',capture_stage='unspecified')
one=copy.deepcopy(literal);one['artifacts']=[descriptor()];one['groups'][0].update(status='present-unverified',artifact_ids=['raw-0'])
one_env=m.decode(wire(one))
check('declared raw metadata preserved without reading any raw file',one_env.artifacts[0].sha256==sha(b'raw') and one_env.artifacts[0].size_bytes==3 and m.assess(one_env).raw_bytes_verified is False)
for status in ['unknown','present-unverified','conflicting']:
    data=copy.deepcopy(one);data['groups'][0]['status']=status;a=m.assess(m.decode(wire(data)))
    check('partial present and conflicting states remain distinct unverified metadata '+status,m.decode(wire(data)).groups[0].status==status and not a.provenance_verified and not a.native_conformance)
data=copy.deepcopy(literal);data['groups'][0]['status']='unknown'
check('unknown with no bytes remains unknown not missing',m.decode(wire(data)).groups[0].status=='unknown')
full=copy.deepcopy(literal);full['origin']='captured-data-unverified'
for i in range(12):full['artifacts'].append(descriptor(i));full['groups'][i].update(status='present-unverified',artifact_ids=['raw-'+str(i)])
a=m.assess(m.decode(wire(full)))
check('all-present captured data declaration cannot become verified native evidence',a.groups_without_complete_declared_data==() and not any([a.raw_bytes_verified,a.provenance_verified,a.native_conformance,a.runtime_authority,a.comparison_performed]) and a.native_cases_run==a.native_proofs_added==0)
empty=copy.deepcopy(one);empty['artifacts'][0].update(size_bytes=0,sha256=sha(b''))
check('known empty raw bytes representable without no-effect claim',m.decode(wire(empty)).artifacts[0].size_bytes==0 and m.assess(m.decode(wire(empty))).raw_bytes_verified is False)

for target in [env,env.identity,one_env.artifacts[0],one_env.groups[0]]:
    field=next(iter(target.__dataclass_fields__))
    try:setattr(target,field,'mutation');frozen=False
    except FrozenInstanceError:frozen=True
    check('record rejects ordinary mutation '+type(target).__name__,frozen)
check('mutable artifact list rejected by direct constructor',fails(m.validate,replace(env,artifacts=[])))
check('mutable group list rejected by direct constructor',fails(m.validate,replace(env,groups=list(env.groups))))
check('mutable group references rejected by direct constructor',fails(m.validate,replace(one_env,groups=(replace(one_env.groups[0],artifact_ids=['raw-0']),)+one_env.groups[1:])))
check('foreign lookalike mapping is not immutable Envelope',fails(m.validate,literal))

for section in ['envelope','identity','artifact','group']:
    for mutation in ['extra','missing']:
        data=copy.deepcopy(one)
        target=data if section=='envelope'else data['identity']if section=='identity'else data['artifacts'][0]if section=='artifact'else data['groups'][0]
        if mutation=='extra':target['runtime_authority']=True
        else:target.pop(next(iter(target)))
        check('closed JSON '+section+' rejects '+mutation+' fields',fails(m.decode,wire(data)))
mutations=[('bool schema',lambda d:d.update(schema_version=True)),('foreign schema',lambda d:d.update(schema_version=2)),('native origin promotion',lambda d:d.update(origin='authenticated-native')),('native result field',lambda d:d.update(native_case_pass=True)),('unknown case',lambda d:d.update(case_id='other-case')),('one platform cannot transfer to other name',lambda d:d['identity'].update(platform='Arch-Linux')),('null platform',lambda d:d['identity'].update(platform=None)),('empty identity not null',lambda d:d['identity'].update(boot_id='')),('identity leading whitespace',lambda d:d['identity'].update(boot_id=' old')),('identity newline',lambda d:d['identity'].update(boot_id='old\nboot')),('nonASCII identity',lambda d:d['identity'].update(boot_id='b\u00f3ot')),('oversized identity',lambda d:d['identity'].update(test_run_id='x'*129)),('invalid subject hash',lambda d:d['identity'].update(subject_source_sha256='ABC')),('negative size',lambda d:d['artifacts'][0].update(size_bytes=-1)),('bool size',lambda d:d['artifacts'][0].update(size_bytes=True)),('float size',lambda d:d['artifacts'][0].update(size_bytes=3.0)),('null size',lambda d:d['artifacts'][0].update(size_bytes=None)),('artifact per-size overflow',lambda d:d['artifacts'][0].update(size_bytes=67108865)),('upper digest',lambda d:d['artifacts'][0].update(sha256='A'*64)),('empty digest',lambda d:d['artifacts'][0].update(sha256='')),('empty size nonempty digest',lambda d:d['artifacts'][0].update(size_bytes=0)),('path traversal ID',lambda d:d['artifacts'][0].update(logical_id='../raw')),('absolute path ID',lambda d:d['artifacts'][0].update(logical_id='/raw')),('backslash ID',lambda d:d['artifacts'][0].update(logical_id='raw\\file')),('oversized ID',lambda d:d['artifacts'][0].update(logical_id='a'*65)),('unsupported executable media',lambda d:d['artifacts'][0].update(media_type='application/x-executable')),('unsupported producer',lambda d:d['artifacts'][0].update(producer_role='trusted-native-issuer')),('unsupported stage',lambda d:d['artifacts'][0].update(capture_stage='after-current-rebind')),('native group status',lambda d:d['groups'][0].update(status='verified')),('missing data with bytes',lambda d:d['groups'][0].update(status='missing')),('dangling reference',lambda d:d['groups'][0].update(artifact_ids=['foreign'])),('duplicate reference',lambda d:d['groups'][0].update(artifact_ids=['raw-0','raw-0'])),('nested mutable reference',lambda d:d['groups'][0].update(artifact_ids=[[]])),('unreferenced artifact',lambda d:d['groups'][0].update(status='unknown',artifact_ids=[])),('foreign group assignment',lambda d:d['artifacts'][0].update(evidence_group=m.GROUP_IDS[1])),('missing group',lambda d:d['groups'].pop()),('reordered groups',lambda d:d['groups'].reverse()),('duplicate group',lambda d:d['groups'].__setitem__(1,copy.deepcopy(d['groups'][0]))),('duplicate artifact ID',lambda d:d['artifacts'].append(copy.deepcopy(d['artifacts'][0])))]
for name,modify in mutations:
    data=copy.deepcopy(one);modify(data);check('malformed declaration rejected '+name,fails(m.decode,wire(data)))
for status in ['present-unverified','conflicting']:
    data=copy.deepcopy(literal);data['groups'][0]['status']=status;check('declared raw state requires actual descriptor reference '+status,fails(m.decode,wire(data)))
for producer in ['subject','collector','verifier','expectation-author','unattributed']:
    data=copy.deepcopy(one);data['artifacts'][0]['producer_role']=producer;a=m.assess(m.decode(wire(data)));check('declared role never authenticates producer '+producer,not a.provenance_verified and not a.runtime_authority)
for stage in ['before','during','after','output','unspecified']:
    data=copy.deepcopy(one);data['artifacts'][0]['capture_stage']=stage;check('declared capture stage is not trusted native time '+stage,not m.assess(m.decode(wire(data))).native_conformance)
for media in ['application/octet-stream','text/plain','application/json']:
    data=copy.deepcopy(one);data['artifacts'][0]['media_type']=media;check('data media metadata never invokes an interpreter '+media,not m.assess(m.decode(wire(data))).comparison_performed)

maximum=copy.deepcopy(literal)
for i in range(128):maximum['artifacts'].append(descriptor(i,0,sha(b'')));maximum['groups'][i%12].update(status='present-unverified');maximum['groups'][i%12]['artifact_ids'].append('raw-'+str(i))
check('exact128 artifact limit supported',len(m.decode(wire(maximum)).artifacts)==128)
maximum['artifacts'].append(descriptor(128,0,sha(b'')));maximum['groups'][128%12]['artifact_ids'].append('raw-128')
check('129 artifacts rejected',fails(m.decode,wire(maximum)))
maxbytes=copy.deepcopy(one);maxbytes['artifacts'][0]['size_bytes']=67108864
check('exact64MiB declared artifact bound supported without allocation',m.decode(wire(maxbytes)).artifacts[0].size_bytes==67108864)
maxbytes['artifacts'].append(descriptor(1,67108864));maxbytes['groups'][1].update(status='present-unverified',artifact_ids=['raw-1'])
check('exact128MiB declared total bound supported without raw IO',m.assess(m.decode(wire(maxbytes))).declared_artifact_bytes==134217728)
maxbytes['artifacts'].append(descriptor(2,1));maxbytes['groups'][2].update(status='present-unverified',artifact_ids=['raw-2'])
check('total declared byte overflow rejected',fails(m.decode,wire(maxbytes)))
identity=copy.deepcopy(literal);identity['identity'].update(platform_version='x'*128,boot_id='old-boot',source_epoch='old-epoch',original_attempt='old-attempt',test_run_id='old-run',subject_source_sha256='0'*64)
check('bounded captured identity declaration never becomes fresh authority',m.decode(wire(identity)).identity.platform_version=='x'*128 and not m.assess(m.decode(wire(identity))).runtime_authority)

for name,bad in [('empty',b''),('mutable bytes',bytearray(encoded)),('text instead of bytes',encoded.decode()),('wire byte overflow',b' '*262145),('nested depth overflow',b'['*13+b'0'+b']'*13),('nonASCII bytes',b'\xff'),('NaN',b'NaN\n'),('Infinity',b'Infinity\n'),('archive input',b'PK\x03\x04\x00'),('duplicate field',encoded.replace(b'"schema_version":1',b'"schema_version":1,"schema_version":1')),('duplicate nested field',encoded.replace(b'"platform":"Slackware-15.0"',b'"platform":"Slackware-15.0","platform":"Slackware-current"')),('truncated canonical JSON',encoded[:-2]),('missing final LF',encoded[:-1]),('extra final LF',encoded+b'\n'),('trailing object',encoded+b'{}'),('leading whitespace',b' '+encoded),('pretty noncanonical JSON',json.dumps(literal,indent=2).encode()+b'\n'),('JSON scalar',b'1\n')]:check('bounded canonical decoder rejects '+name,fails(m.decode,bad))
quoted=copy.deepcopy(identity);quoted['identity']['platform_version']='braces [{}] quote " backslash \\'
check('depth scan respects braces and escaped characters in strings',m.encode(m.decode(wire(quoted)))==wire(quoted))
check('exact depth bound accepts valid shallow metadata',m.MAX_DEPTH==12 and m.decode(encoded)==env)
assessment=m.assess(env)
check('all absent raw data stays pending declaration only',len(assessment.groups_without_complete_declared_data)==12 and not assessment.raw_bytes_verified and not assessment.native_conformance)
tree=ast.parse((root/'tools/reference'/module).read_text())
imports={n.module if isinstance(n,ast.ImportFrom)else a.name for n in ast.walk(tree)if isinstance(n,(ast.Import,ast.ImportFrom))for a in(n.names if isinstance(n,ast.Import)else[None])}
check('schema imports only data serialization hashing and grammar libraries',imports=={'dataclasses','hashlib','json','re'})
check('schema has no filesystem process network or dynamic evaluation calls',not any(isinstance(n,ast.Call)and isinstance(n.func,ast.Name)and n.func.id in {'open','eval','exec','compile','__import__'}for n in ast.walk(tree)))
for args in [[],['--execute'],['--collect'],['--check','/etc/slackpkg']]:
    result=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module),*args],capture_output=True,text=True);check('import-only module rejects command entry '+repr(args),result.returncode!=0 and not result.stdout and 'Import-only' in result.stderr)
check('schema contract selects only codec not ingestion expectations or comparator',contract['current_schema_implemented']is True and all(contract[k]is False for k in ['current_comparator_implemented','current_ingestion_implemented','current_expectation_contract_implemented','actual_native_collector_selected','actual_independent_oracle_selected','actual_native_refinement_complete','actual_operational_implementation_frozen','actual_dynamic_graph_complete','operational_conformance','operational_readiness','runtime_authority','strong_safe_pause','user_step350_checkpoint_confirmed','phase2_open','phase1_matrix_complete','kernel_package_edge_complete','historical_bindings_reusable']))
check('host remains unobserved and binding unknown with no native case proof',contract['actual_host_state']=='unobserved-not-claimed-absent' and contract['actual_live_bindings']is None and contract['native_cases_run']==contract['native_proofs_added']==0)
with tempfile.TemporaryDirectory(prefix='step350-exact349-')as directory:
    historical=Path(directory)
    for rel,raw in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
    result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
    if result.returncode:sys.stderr.write(result.stdout[-3000:]+result.stderr[-3000:])
    check('full unchanged349179 acceptance passes on exact1728 original snapshot',result.returncode==0 and result.stdout.splitlines()[-1]=='Result: PASS (179 passes, 0 failures)')
    check('all179 unchanged predecessor labels exactly match complete user return',[l for l in result.stdout.splitlines()if l.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared350 retains last confirmed pause348 and next351 receipt gate',contract['last_confirmed_strong_safe_pause_step']==348 and contract['next_stage_after_complete350_acceptance']==351 and contract['current_user_acceptance_pending']is True)
print('Result: PASS ('+str(passes)+' passes, 0 failures)',flush=True)
PYTEST
