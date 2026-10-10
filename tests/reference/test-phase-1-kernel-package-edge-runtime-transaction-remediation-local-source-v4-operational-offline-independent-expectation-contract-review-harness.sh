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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bounded-evidence-schema-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-literal-expectations.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review.md': '652b40a47dac079df746966db530a7d5d9a73b9f9bfcaa31e9eb8b56236c0e99', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review-checkpoint-confirmation.json': 'caced619b52ae1dce3309f9959020b23302f8d2518c1dd4d5d3619f73eb36ebd', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review-policy.json': 'b7f37e8aaa37a2cdb8a285f3598caaf8aeb513cb394165f54028155e697b42cb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review-expectation-contract.json': '7784d5d3a5d9d0d8188a9c06bb3e142deb6008d210c583394c7335331677994c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review-literal-expectations.json': '93164535b2e1a0f667b7c91940a8579b65388d10d9b8f9674e7356b339610ebf', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review-retained-obligations.json': '0e663562eae7c34c0c275d13bc4b848871dd34a8924305388aec26436ea06d73', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review-step350-user-acceptance.json': '6eea690a5566ce8ff246b441d69b71a2e3f5201b8335165413f9848e713fc8fe', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-literal-expectations.py': '866dcca8c9047d2e76829e6650f76f6a22042efb6ccb1d27bb9918e8683916c9'}
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
    if not (type(relative)is str and relative and not relative.startswith('/') and '\\' not in relative and all(p not in ('','.','..')for p in relative.split('/'))):raise ValueError('unsafe source path')
    p=root/relative
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe source file')
    return p
for rel,digest in OWN_HASHES.items():check('exact current351 input '+Path(rel).name,sha(path(rel).read_bytes())==digest)
policy=load('policy');contract=load('expectation-contract');retained=load('retained-obligations');literals=load('literal-expectations');receipt=load('step350-user-acceptance');confirmation=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    raw=path(rel).read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted350 source drift: '+rel)
    history[rel]=raw
check('all1737 accepted350 bytes and exact historical CHANGELOG suffix',len(history)==1737)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete20194-byte original350 receipt retained without normalization',len(raw)==20194 and sha(raw)=='5eac1703fc67025fc33825b856f9fee7211a67a46d5e5f6d8bc738f631c72806' and receipt['ordered_output_normalization']=='none' and receipt['original_display_size_bytes']==len(raw) and receipt['original_display_sha256']==sha(raw))
check('complete207 predecessor labels exactly match original receipt',[line for line in lines if line.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (207 passes, 0 failures)')==1)
check('reported922d639 exact tenfiles3211 commit nine paths and successful push',lines.count('[main 922d639] Phase 1 step 350: define bounded immutable evidence schema')==1 and lines.count(' 10 files changed, 3211 insertions(+)')==1 and set(line[len(' create mode 100644 '):] for line in lines if line.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   522666b..922d639  main -> main' in lines)
check('complete clean matching heads with unknown full350 commit',lines[-3:-1]==['922d639 (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 350: define bounded immutable evidence schema']*2 and confirmation['commit_full']is None and confirmation['evidence_sha256']==sha(raw) and all(confirmation[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+list(retained['accepted350_bindings'].values())+[retained['accepted349_plan_binding'],retained['schema_module_binding']]
for binding in bindings:check('source-bound unchanged inherited '+Path(binding['path']).name,sha(history[binding['path']])==binding['sha256'])
check('all eight full original320-327 design contracts bound',set(retained['original_design_bindings'])==set(str(i)for i in range(320,328)))
oracle=json.loads(history[retained['source_bindings']['oracle335']['path']])
check('complete original twelve native evidence group rows retained',retained['original_evidence_group_rows']==oracle['evidence_groups'])
check('full original independence contract unchanged',contract['independence_contract']==oracle['independence_contract'])
for row,original in zip(retained['original_case_row_sha256'],oracle['cases']):
    if row['sha256']!=sha(json.dumps(original,sort_keys=True,separators=(',',':')).encode())or row['status']!='required-not-run':raise ValueError('native case promotion or drift')
check('all52 source-bound native cases still unrun',len(retained['original_case_row_sha256'])==len(oracle['cases'])==52 and all(sum(row['platform']==platform for row in retained['original_case_row_sha256'])==26 for platform in ['Slackware-15.0','Slackware-current']))
oldretained=json.loads(history[retained['accepted350_bindings']['retained-obligations']['path']])
check('all46 proofs52 cases16 gaps and original counts retained',retained['counts']==oldretained['counts'] and [retained['counts'][key]for key in ['native_proofs','native_cases','native_gaps']]==[46,52,16])
check('seven frozen modules and nine original pause conditions unchanged',retained['model_modules']==oldretained['model_modules'] and len(retained['model_modules'])==7 and retained['original_pause_conditions']==oldretained['original_pause_conditions'] and len(retained['original_pause_conditions'])==9)
designs={int(step):json.loads(history[binding['path']])for step,binding in retained['original_design_bindings'].items()}
check('full325 selector contract including install0/20 and mandatory upgrade0 retained',contract['original_selector_contract']==designs[325]['selector_contract'])
check('full323 same-original finite recovery contract retained',contract['original_recovery_contract']==designs[323]['recovery_contract'])
check('full325 separate last-receipt publication contract retained',contract['original_publication_contract']==designs[325]['publication_contract'])

m=SimpleNamespace(**runpy.run_path(str(root/'tools/reference'/module)))
check('original26 case IDs and two platform universes exact',m.CASE_IDS==tuple(dict.fromkeys(row['case_id']for row in oracle['cases'])) and m.PLATFORMS==('Slackware-15.0','Slackware-current'))
check('three vectors56 complete typed slots exactly match contract',[(name,list(rows))for name,rows in m.FIELD_SPECS]==[(vector['vector_id'],[(row['field_id'],row['kind'])for row in vector['fields']])for vector in contract['field_specs']] and sum(len(rows)for _,rows in m.FIELD_SPECS)==56)
check('exact bounded declaration limits',contract['limits']==dict(max_wire_bytes=m.MAX_WIRE_BYTES,max_depth=m.MAX_DEPTH,max_vector_items=m.MAX_VECTOR_ITEMS,max_label_chars=m.MAX_LABEL_CHARS,max_budget=m.MAX_BUDGET,max_time_ns=m.MAX_TIME_NS))
for key,cls in [('expectations',m.Expectations),('identity',m.Identity),('provenance',m.Provenance),('vector',m.ExpectedVector),('field',m.ExpectedField)]:check('closed immutable expectation '+key,list(cls.__dataclass_fields__)==contract['closed_fields'][key])
def wire(value):return(json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False)+'\n').encode('ascii')
def field(data,name):
    return next(row for vector in data['vectors']for row in vector['fields']if row['field_id']==name)
def values(data):return {row['field_id']:row['value']for vector in data['vectors']for row in vector['fields']}
check('literal fixtures declare no reducer or subject derivation and no native selection',literals['derived_from_subject']is False and literals['derived_from_model_reducers']is False and literals['native_expected_vectors_selected']is False and literals['native_cases_run']==literals['native_proofs_added']==0)
check('five separate literal scenarios per platform only',len(literals['fixtures'])==10 and all(sum(row['platform']==platform for row in literals['fixtures'])==5 for platform in m.PLATFORMS))
for row in literals['fixtures']:
    data=row['expectation'];e=m.decode(wire(data));a=m.assess(e)
    check('private literal exact roundtrip '+row['platform']+'/'+row['scenario'],m.encode(e)==wire(data) and e.identity.platform==row['platform'])
    check('private literal retains pending provenance and zero native proof '+row['platform']+'/'+row['scenario'],a.pending_provenance_fields and not a.declaration_complete and not any([a.independence_verified,a.native_oracle_selected,a.comparison_performed,a.native_conformance,a.runtime_authority]) and a.native_cases_run==a.native_proofs_added==0)
    v=values(data)
    if row['scenario'].startswith('empty-install-'):
        check('literal empty install differs from one mandatory target '+row['platform']+'/'+row['scenario'],v['install-new-selector']==[] and v['install-new-raw-status']==(0 if row['scenario']=='empty-install-zero'else 20) and v['install-new-target-effects']==v['install-new-owned-effects']==[] and v['upgrade-all-selector']==['private-target-package'] and v['upgrade-all-raw-status']==0)
    elif row['scenario']=='mandatory-upgrade-twenty':
        check('literal mandatory upgrade20 remains original failure after verified recovery '+row['platform'],v['upgrade-all-raw-status']==v['original-forward-status']==20 and v['original-full-invariants-verified']is True and v['pending-target-obligations']==['pkglist-selector-status'])
    elif row['scenario']=='unknown-recovery':
        check('literal unknown child recovery retains original failure spent budget obligations '+row['platform'],v['owned-children-quiescent']is None and v['original-forward-status']==7 and v['recovery-budget-pre-spent']is True and v['recovery-budget-remaining']==0 and v['pending-target-obligations'] and v['pending-owned-obligations'])
    else:
        check('literal unknown receipt independent of known restored target '+row['platform'],v['original-forward-status']==7 and v['target-control-released']is True and v['receipt-state']=='unknown' and v['handoff-acknowledged']is None and v['pending-publication-obligations']==['last-receipt-durability'])

sample=copy.deepcopy(literals['fixtures'][0]['expectation']);e=m.decode(wire(sample))
field(sample,'install-new-selector')['value']=None;a=m.assess(m.decode(wire(sample)))
check('unknown selector retains pending exact field rather than empty tuple',('selector-effects','install-new-selector')in a.pending_expected_fields and field(sample,'install-new-raw-status')['value']==0)
field(sample,'install-new-selector')['value']=[];a=m.assess(m.decode(wire(sample)))
check('explicit empty selector is known expected data with provenance still pending',('selector-effects','install-new-selector')not in a.pending_expected_fields and a.pending_provenance_fields)
for case in oracle['cases']:
    data=copy.deepcopy(sample);data['identity']['platform']=case['platform'];data['case_id']=case['case_id'];a=m.assess(m.decode(wire(data)))
    check('shape valid expectation never runs native '+case['platform']+'/'+case['case_id'],a.schema_valid and not a.native_conformance and a.native_cases_run==a.native_proofs_added==0 and not a.runtime_authority)

# The direct constructors never materialize data as code or evaluate vector values.
for obj in [e,e.identity,e.provenance,e.vectors[0],e.vectors[0].fields[0]]:
    key=next(iter(obj.__dataclass_fields__))
    try:setattr(obj,key,'modified');frozen=False
    except FrozenInstanceError:frozen=True
    check('ordinary mutation rejected '+type(obj).__name__,frozen)
check('direct mutable expected vector container rejected',fails(m.validate,replace(e,vectors=list(e.vectors))))
check('direct mutable field rows rejected',fails(m.validate,replace(e,vectors=(replace(e.vectors[0],fields=list(e.vectors[0].fields)),)+e.vectors[1:])))
selector_index=next(i for i,row in enumerate(e.vectors[0].fields)if row.field_id=='install-new-selector')
newrows=list(e.vectors[0].fields);newrows[selector_index]=replace(newrows[selector_index],value=[])
check('direct mutable selector vector rejected',fails(m.validate,replace(e,vectors=(replace(e.vectors[0],fields=tuple(newrows)),)+e.vectors[1:])))
check('mapping lookalike cannot bypass immutable declaration',fails(m.validate,sample))

for section in ['expectations','identity','provenance','vector','field']:
    for mutation in ['extra','missing']:
        data=copy.deepcopy(sample);target=data if section=='expectations'else data['identity']if section=='identity'else data['provenance']if section=='provenance'else data['vectors'][0]if section=='vector'else data['vectors'][0]['fields'][0]
        if mutation=='extra':target['independence_verified']=True
        else:target.pop(next(iter(target)))
        check('closed '+section+' rejects '+mutation+' field',fails(m.decode,wire(data)))
mutations=[
    ('bool schema',lambda d:d.update(schema_version=True)),('foreign schema',lambda d:d.update(schema_version=2)),
    ('native origin promotion',lambda d:d.update(origin='native-verified')),('unknown case',lambda d:d.update(case_id='foreign-case')),
    ('foreign platform',lambda d:d['identity'].update(platform='Arch-Linux')),('null platform',lambda d:d['identity'].update(platform=None)),
    ('empty boot identity',lambda d:d['identity'].update(boot_id='')),('trimmed identity',lambda d:d['identity'].update(boot_id=' old')),
    ('nonASCII identity',lambda d:d['identity'].update(boot_id='b\u00f3ot')),('oversized identity',lambda d:d['identity'].update(test_run_id='x'*129)),
    ('subject author',lambda d:d['provenance'].update(author_role='subject')),
    ('subject output derivation',lambda d:d['provenance'].update(derivation='subject-output')),
    ('model reducer derivation',lambda d:d['provenance'].update(derivation='model-reducer')),
    ('same selector derivation',lambda d:d['provenance'].update(derivation='same-selector')),
    ('same cleanup derivation',lambda d:d['provenance'].update(derivation='same-cleanup')),
    ('upper digest',lambda d:d['provenance'].update(review_record_sha256='A'*64)),
    ('bool raw status',lambda d:field(d,'install-new-raw-status').update(value=True)),
    ('status below minus1',lambda d:field(d,'install-new-raw-status').update(value=-2)),
    ('status above255',lambda d:field(d,'upgrade-all-raw-status').update(value=256)),
    ('float raw status',lambda d:field(d,'update-raw-status').update(value=0.0)),
    ('int bool',lambda d:field(d,'forward-stopped').update(value=1)),
    ('negative budget',lambda d:field(d,'recovery-budget-remaining').update(value=-1)),
    ('bool budget',lambda d:field(d,'recovery-budget-remaining').update(value=True)),
    ('budget overflow',lambda d:field(d,'recovery-budget-remaining').update(value=65536)),
    ('time overflow',lambda d:field(d,'recovery-deadline-ns').update(value=9223372036854775808)),
    ('negative time',lambda d:field(d,'recovery-deadline-ns').update(value=-1)),
    ('null vector item',lambda d:field(d,'upgrade-all-selector').update(value=[None])),
    ('nested mutable vector item',lambda d:field(d,'upgrade-all-selector').update(value=[[]])),
    ('vector instead of scalar count',lambda d:field(d,'recovery-budget-remaining').update(value=[])),
    ('scalar instead of vector',lambda d:field(d,'upgrade-all-selector').update(value='private-target-package')),
    ('oversized vector',lambda d:field(d,'upgrade-all-selector').update(value=['p']*129)),
    ('oversized vector label',lambda d:field(d,'upgrade-all-selector').update(value=['p'*129])),
    ('newline vector label',lambda d:field(d,'upgrade-all-selector').update(value=['p\nq'])),
    ('bool status vector item',lambda d:field(d,'full-forward-raw-status-vector').update(value=[True])),
    ('missing vector',lambda d:d['vectors'].pop()),('reordered vectors',lambda d:d['vectors'].reverse()),
    ('duplicate vector',lambda d:d['vectors'].__setitem__(1,copy.deepcopy(d['vectors'][0]))),
    ('missing named slot',lambda d:d['vectors'][0]['fields'].pop()),
    ('reordered named slots',lambda d:d['vectors'][0]['fields'].reverse()),
    ('duplicate named slot',lambda d:d['vectors'][0]['fields'].__setitem__(1,copy.deepcopy(d['vectors'][0]['fields'][0])))]
for name,mutate in mutations:
    data=copy.deepcopy(sample);mutate(data);check('malformed independent declaration rejected '+name,fails(m.decode,wire(data)))
for role in ['collector','verifier','author']:
    data=copy.deepcopy(sample);data['provenance'].update(subject_source_sha256='0'*64);data['provenance'][role+'_source_sha256']='0'*64
    check('known subject SHA reused by '+role+' rejected',fails(m.decode,wire(data)))
    data=copy.deepcopy(sample);data['identity']['subject_source_sha256']='0'*64;data['provenance'][role+'_source_sha256']='0'*64
    check('known identity subject SHA reused by '+role+' rejected without duplicate provenance',fails(m.decode,wire(data)))
data=copy.deepcopy(sample);data['identity']['subject_source_sha256']='0'*64;data['provenance']['subject_source_sha256']='1'*64
check('known identity and declared subject source conflict rejected',fails(m.decode,wire(data)))
data=copy.deepcopy(sample);data['provenance'].update(author_role='verifier',derivation='unknown')
check('verifier may author literal and unknown derivation stays pending','derivation'in m.assess(m.decode(wire(data))).pending_provenance_fields)
data=copy.deepcopy(sample);data['provenance']['author_role']='unattributed'
check('unattributed author stays pending rather than authenticated','author_role'in m.assess(m.decode(wire(data))).pending_provenance_fields)

# Fully populated, deliberately private declarations show that shape completion
# and distinct role digests cannot select or authenticate a native oracle.
complete=copy.deepcopy(sample);complete['origin']='separately-reviewed-unverified'
complete['identity'].update(platform_version='private-version',boot_id='private-boot',source_epoch='private-epoch',original_attempt='private-attempt',test_run_id='private-run',subject_source_sha256='0'*64)
complete['provenance'].update(subject_source_sha256='0'*64,collector_source_sha256='1'*64,verifier_source_sha256='2'*64,author_source_sha256='2'*64,review_record_sha256='3'*64)
for vector in complete['vectors']:
    for row in vector['fields']:
        if row['value']is None:
            kind=next(kind for _,specs in m.FIELD_SPECS for name,kind in specs if name==row['field_id'])
            row['value']=False if kind=='bool'else 0 if kind in ('status','budget','time-ns')else '4'*64 if kind=='digest'else 'private-value'if kind=='label'else []
a=m.assess(m.decode(wire(complete)))
check('complete distinct provenance declaration with verifier author grants no oracle',a.declaration_complete and not any([a.independence_verified,a.native_oracle_selected,a.comparison_performed,a.native_conformance,a.runtime_authority]) and a.native_cases_run==a.native_proofs_added==0)
for name,value in [('install-new-raw-status',-1),('upgrade-all-selector',['second','first','second']),('recovery-budget-remaining',65535),('recovery-deadline-ns',9223372036854775807),('owned-child-identities',['x'*128]*128)]:
    data=copy.deepcopy(sample);field(data,name)['value']=value;decoded=m.decode(wire(data))
    check('exact literal boundary and order preserved '+name,values(m.mapping(decoded))[name]==value)
data=copy.deepcopy(sample);field(data,'original-restoration-state')['value']='private {state} "quoted" \\ token'
check('bounded string escapes never affect depth or execute content',m.encode(m.decode(wire(data)))==wire(data))

encoded=wire(sample)
bad_wire=[('empty',b''),('mutable bytes',bytearray(encoded)),('text',encoded.decode()),('wire overflow',b' '*262145),
          ('depth overflow',b'['*13+b'0'+b']'*13),('nonASCII',b'\xff'),('NaN',encoded.replace(b'"schema_version":1',b'"schema_version":NaN')),
          ('Infinity',encoded.replace(b'"schema_version":1',b'"schema_version":Infinity')),
          ('duplicate field',encoded.replace(b'"schema_version":1',b'"schema_version":1,"schema_version":1')),
          ('duplicate nested field',encoded.replace(b'"platform":"Slackware-15.0"',b'"platform":"Slackware-15.0","platform":"Slackware-15.0"')),
          ('missing final LF',encoded[:-1]),('extra LF',encoded+b'\n'),('truncated',encoded[:60]),('trailing object',encoded+b'{}'),
          ('leading whitespace',b' '+encoded),('pretty JSON',(json.dumps(sample,indent=2)+'\n').encode()),('scalar',b'1\n'),('archive',b'PK\x03\x04not-expectation')]
for name,bad in bad_wire:check('strict bounded expectation wire rejects '+name,fails(m.decode,bad))
check('exact nesting bound accepts valid literal envelope',m.depth_bound(encoded)is None)

tree=ast.parse((root/'tools/reference'/module).read_text())
imports={alias.name for node in ast.walk(tree)if isinstance(node,ast.Import)for alias in node.names}|{node.module for node in ast.walk(tree)if isinstance(node,ast.ImportFrom)}
check('expectation module imports only dataclasses JSON and grammar',imports=={'dataclasses','json','re'})
calls={node.func.id for node in ast.walk(tree)if isinstance(node,ast.Call)and isinstance(node.func,ast.Name)}
check('expectation module has no IO dynamic import reducer generator or comparator',not(calls&{'open','eval','exec','compile','__import__','input'})and 'runpy'not in imports and not hasattr(m,'compare')and not hasattr(m,'derive_expectations'))
for arguments in [[],['--generate'],['--compare'],['--execute'],['--collect']]:
    result=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module)]+arguments,capture_output=True)
    check('import-only expectation module denies command entry '+repr(arguments),result.returncode!=0 and result.stdout==b'' and b'Import-only'in result.stderr)
check('actual expectation author collector verifier and native artifacts remain null',all(contract[key]is None for key in ['actual_expectation_author','actual_expected_vector_artifacts','actual_independent_collector','actual_independent_verifier','actual_live_bindings']) and contract['actual_host_state']=='unobserved-not-claimed-absent')
check('current scope contract only no ingestion comparator native authority',contract['current_expectation_contract_implemented']is True and contract['current_ingestion_implemented']is False and contract['current_comparator_implemented']is False and contract['runtime_authority']is False and contract['native_cases_run']==contract['native_proofs_added']==0)

with tempfile.TemporaryDirectory(prefix='step351-exact-accepted350-')as directory:
    historical=Path(directory)
    for rel,data in history.items():
        p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    predecessor=historical/'tests/reference'/('test-'+oldbase+'-harness.sh')
    result=subprocess.run(['bash',str(predecessor)],capture_output=True,text=True)
    if result.returncode:raise AssertionError('unchanged350 full acceptance failed: '+result.stderr[-3000:])
    check('full unchanged350207 acceptance passes on exact1737 snapshot',result.stdout.splitlines().count('Result: PASS (207 passes, 0 failures)')==1)
    check('all207 unchanged predecessor labels exactly match complete user return',[line for line in result.stdout.splitlines()if line.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared351 retains last confirmed pause348 and next352 receipt gate',contract['last_confirmed_strong_safe_pause_step']==348 and contract['strong_safe_pause']is False and contract['current_user_acceptance_pending']is True and contract['user_step351_checkpoint_confirmed']is False and contract['next_stage_after_complete351_acceptance']==352)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
