#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import dataclasses
import hashlib
import json
import subprocess
import sys
import tempfile
import types

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review';core_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py';review_path=root/'tools/reference'/(base+'.py');fixture=root/'tests/fixtures/reference/acceptance/phase-1/'
passes=0
def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def rejects(fn,*args,**kwargs):
 try:fn(*args,**kwargs)
 except (ValueError,TypeError,KeyError,AttributeError,dataclasses.FrozenInstanceError):return True
 return False
def change(value,path,new):
 value=copy.deepcopy(value);cursor=value
 for key in path[:-1]:cursor=cursor[key]
 cursor[path[-1]]=new;return value
def run(argv):return subprocess.run([str(x) for x in argv],capture_output=True,text=True)
def load(suffix):return json.loads((fixture/(base+suffix)).read_bytes())
check('exact340 pure core source SHA',hashlib.sha256(core_path.read_bytes()).hexdigest()=='94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5')
check('exact340 reviewer source SHA',hashlib.sha256(review_path.read_bytes()).hexdigest()=='40f2809ad2f73cefa3d57ece5293f456a15c579b408fe28338b4a4e9f2e808c2')
# Register the private module before executing its dataclass definitions, without pycache.
core=types.ModuleType('private340_core');sys.modules[core.__name__]=core
exec(compile(ast.parse(core_path.read_text()),str(core_path),'exec'),core.__dict__)
review={'__name__':'private340_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');spec=load('-schema.json');policy=load('-policy.json')
check('all1638 accepted339 source bytes preserved',len(history)==1638)
check('full339 return including SSH and wrong-directory failures accepted',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step339-user-acceptance.json'),policy))
check('original27 phases35 types26 interfaces85 contexts9 windows bound',review['validate_mapping'](mapping,history))
check('core actor/window/order map exact to source',dict(core.PHASE_ROWS)=={k:(v['actor'],v['window'],v['position']) for k,v in mapping['phases'].items()})
check('core type map exact to source',core.TYPE_NAMES==frozenset(mapping['nominal_types']))
check('core phase views exact to full original interfaces',dict(core.PHASE_VIEWS)=={k:frozenset(v) for k,v in mapping['phase_view_types'].items()})
check('all nine windows retained without invented service/forbidden phase',core.RIGHTS_WINDOWS==tuple(mapping['rights_windows']) and not any(x[1] in ('service','forbidden') for x in core.PHASE_ROWS.values()))
ctx=core.ModelContext('model-attempt-a','model-boot-a');other=core.ModelContext('model-attempt-a','model-boot-b');initial=core.initial_state(ctx)
check('initial state is closed and unobserved with no authority',initial.phase is None and initial.claim=='known-unused' and initial.launch=='unspent' and initial.forward=='closed' and initial.target=='unobserved' and not initial.authority and not initial.native_evidence)
check('all original rights inactive in initial state',len(initial.rights)==9 and all(x.status=='inactive' for x in initial.rights))
check('declared initial wire shape equals actual initial value',core.to_wire(initial)==spec['initial_state'])
for name,fields in spec['record_fields'].items():
 check('declared closed record fields '+name,[x.name for x in dataclasses.fields(getattr(core,name))]==fields)
for symbol in ('','bcfac4fa-4e6e-450a-aa95-bd591a979b4e','/var/tmp/target','../escape','model-A','model-'+('a'*100),True):
 check('native/unsafe context symbol rejected '+repr(symbol),rejects(core.ModelContext,symbol,'model-boot-a'))
for name,allowed in core.STATE_ENUMS.items():
 check('unknown state status rejected '+name,rejects(dataclasses.replace,initial,**{name:'actual-native-PASS'}))
 for value in allowed:
  state=dataclasses.replace(initial,**{name:value})
  check('shape-only symbolic state enumeration '+name+'/'+value,core.decode(core.encode(state))==state)
for key,value in [('phase','GenInitrd'),('traps',1),('pin','/var/lib/pkgtools/packages'),('stage7_completed',True),('stage7_completed',10),('recovery_limit',True),('recovery_limit',-1),('recovery_spent',1),('recovery_spent',True),('rights',list(initial.rights)),('rights',initial.rights[:-1]),('rights',initial.rights[::-1]),('raw_statuses',[]),('first_failure',{}),('authority',True),('authority',0),('native_evidence',True)]:
 check('closed state rejects '+key+' '+repr(value)[:70],rejects(dataclasses.replace,initial,**{key:value}))
spent=dataclasses.replace(initial,recovery_limit=3,recovery_spent=3)
check('finite model budget preserves complete spend',core.decode(core.encode(spent)).recovery_spent==3)
check('budget overspend rejected',rejects(dataclasses.replace,spent,recovery_spent=4))
for phase,row in mapping['phases'].items():
 for outcome in ('known-success','known-failure','unknown','unattempted'):
  e=core.ModelEvent(ctx,phase,row['actor'],row['window'],outcome)
  check('exact source phase/outcome shape '+phase+'/'+outcome,core.decode(core.encode(e))==e)
 check('wrong actor rejected '+phase,rejects(core.ModelEvent,ctx,phase,'invented-actor',row['window'],'known-success'))
 check('wrong window rejected '+phase,rejects(core.ModelEvent,ctx,phase,row['actor'],'forbidden','known-success'))
for name in mapping['nominal_types']:
 view=core.ModelView(name,ctx,'model-value-a')
 phase=next(k for k,v in mapping['phase_view_types'].items() if name in v);row=mapping['phases'][phase]
 event=core.ModelEvent(ctx,phase,row['actor'],row['window'],'known-success',views=(view,))
 check('original nominal type roundtrip '+name,core.decode(core.encode(event))==event)
 for outcome in ('known-failure','unknown','unattempted'):
  check('no success view on '+outcome+'/'+name,rejects(dataclasses.replace,event,outcome=outcome))
 check('cross-boot view rejected '+name,rejects(dataclasses.replace,event,views=(dataclasses.replace(view,context=other),)))
 check('duplicated view type rejected '+name,rejects(dataclasses.replace,event,views=(view,view)))
 check('native view authority rejected '+name,rejects(dataclasses.replace,view,authority=True))
event=core.ModelEvent(ctx,'service-barrier-authentication','service','policy','known-success')
golden=b'{"actor":"service","authority":false,"context":{"attempt":"model-attempt-a","boot":"model-boot-a"},"kind":"event","native_evidence":false,"operation":"phase-report","origin":"synthetic-private-fixture","outcome":"known-success","phase":"service-barrier-authentication","raw_statuses":[],"schema":1,"scope":"offline-transition-core-shape-only","views":[],"window":"policy"}'
check('independently written exact canonical event bytes',core.encode(event)==golden and core.decode(golden)==event)
for operation in spec['owned_stage7_microsteps']:
 e=core.ModelEvent(ctx,'worker7-owned-durable-commit','worker','forward','known-success',operation)
 check('each exact nine owned microstep shape '+operation,core.decode(core.encode(e))==e)
 check('owned microstep denied outside stage7 '+operation,rejects(dataclasses.replace,event,operation=operation))
raw=(core.RawStatus('model-call-a',0),core.RawStatus('model-call-b',17),core.RawStatus('model-call-c',-9),core.RawStatus('model-call-d',None))
state=dataclasses.replace(initial,raw_statuses=raw,first_failure=raw[1])
check('raw full vector retains zero nonzero signed and unknown',tuple(x.code for x in core.decode(core.encode(state)).raw_statuses)==(0,17,-9,None))
check('raw original first failure retained separately',core.decode(core.encode(state)).first_failure==raw[1])
check('zero raw code alone never establishes native success',not dataclasses.replace(initial,first_failure=raw[0]).native_evidence)
check('unknown raw code remains null rather than zero',core.decode(core.encode(state)).raw_statuses[-1].code is None)
for code in (True,1.0,2147483648,-2147483649,'0'):
 check('bad raw status rejected '+repr(code),rejects(core.RawStatus,'model-call-a',code))
check('duplicate raw call labels rejected',rejects(dataclasses.replace,initial,raw_statuses=(raw[0],raw[0])))
check('unattempted event rejects attempted raw vector',rejects(dataclasses.replace,event,outcome='unattempted',raw_statuses=raw))
for value in [initial,event,core.ModelResult(ctx,'accepted-shape','valid-shape',initial),core.ModelResult(ctx,'rejected','rule-rejected'),core.ModelResult(ctx,'pending','unknown-observation',state),core.ModelResult(ctx,'pending','transition-not-implemented')]:
 check('immutable state/event/result roundtrip '+type(value).__name__+'/'+getattr(value,'decision','shape'),core.decode(core.encode(value))==value)
 wire=core.to_wire(value);wire['context']['boot']='model-boot-mutated'
 check('detached JSON cannot mutate immutable input '+type(value).__name__,value.context.boot=='model-boot-a')
 check('record attribute cannot be assigned '+type(value).__name__,rejects(setattr,value,'authority',True))
for decision,reason,successor in [('accepted-shape','valid-shape',None),('accepted-shape','unknown-observation',initial),('rejected','rule-rejected',initial),('pending','valid-shape',initial),('accepted-shape','valid-shape',core.initial_state(other))]:
 check('inconsistent result rejected '+decision+'/'+reason,rejects(core.ModelResult,ctx,decision,reason,successor))
check('context attribute frozen',rejects(setattr,ctx,'boot','model-boot-b'))
check('nested rights report frozen',rejects(setattr,initial.rights[0],'status','reported-live'))
check('phase map immutable',rejects(lambda: core.PHASE_ROWS.__setitem__('new',('worker','forward',99))))
wire=core.to_wire(event)
for path,new in [(['schema'],True),(['schema'],2),(['origin'],'native-observation'),(['scope'],'runtime'),(['authority'],True),(['authority'],0),(['native_evidence'],True),(['context','boot'],'actual-boot-id'),(['actor'],'worker'),(['window'],'forward'),(['phase'],'GenInitrd'),(['views'],{}),(['raw_statuses'],{}),(['kind'],'native-command')]:
 check('wire rejects unsafe field '+str(path)+' '+repr(new),rejects(core.from_wire,change(wire,path,new)))
nested=core.to_wire(core.ModelResult(ctx,'pending','transition-not-implemented'))
check('result successor cannot be event JSON',rejects(core.from_wire,dict(nested,successor=wire)))
check('result successor cannot be nested result JSON',rejects(core.from_wire,dict(nested,successor=nested)))
cyclic=dict(nested);cyclic['successor']=cyclic
check('cyclic direct JSON-shaped result rejected before recursion',rejects(core.from_wire,cyclic))
check('extra operational argv field rejected',rejects(core.from_wire,dict(wire,argv=['upgradepkg','x'])))
check('extra nested original credential rejected',rejects(core.from_wire,change(wire,['context'],dict(wire['context'],credential='real'))))
for raw_input in [b'',b' ',b'null',b'[]',b'true',b'\xff',b'\xef\xbb\xbf'+golden,b' '+golden,golden+b'\n',golden+b'{}',golden.replace(b'"schema":1',b'"schema":1,"schema":1'),golden.replace(b'"attempt":"model-attempt-a"',b'"attempt":"model-attempt-a","attempt":"model-attempt-a"'),golden.replace(b'"schema":1',b'"schema":NaN'),golden.replace(b'model-boot-a',b'model-boot-\\u0061'),b'['*34+b'0'+b']'*34,b'x'*(65536+1)]:
 check('bounded canonical JSON rejection '+repr(raw_input[:45]),rejects(core.decode,raw_input))
check('decoder rejects mutable bytearray',rejects(core.decode,bytearray(golden)))
check('encoder rejects arbitrary operational object',rejects(core.encode,{'argv':['sh']}))
check('shape-valid state is not proof of transition order',dataclasses.replace(initial,guard='continuous',traps=False).traps is False)
for key,new in [('user_worktree_clean',False),('runtime_authority',True),('strong_safe_pause',True),('commit_prefix','fffffff')]:
 check('false predecessor acceptance rejected '+key,rejects(review['validate_return'],change(load('-checkpoint-confirmation.json'),[key],new),load('-step339-user-acceptance.json'),policy))
for key,new in [('phases',{}),('nominal_types',[]),('original_interface_contexts',True),('rights_windows',[]),('phase_view_types',{}),('native_authority',True)]:
 check('mapping cannot waive original '+key,rejects(review['validate_mapping'],change(mapping,[key],new),history))
for argv in [[],['--bogus'],['--check'],['--check','']]:
 check('strict340 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
r=run(['python3','-B',review_path,'--check',root]);check('actual source-bound340 review entry',r.returncode==0 and 'step340_offline_schema_review_status\tPASS' in r.stdout)
with tempfile.TemporaryDirectory(prefix='step340-source-check-') as directory:
 area=Path(directory);snapshot=area/'accepted339';snapshot.mkdir()
 for relative,rawbytes in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(rawbytes)
 r=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot])
 if r.returncode:sys.stderr.write(r.stdout+r.stderr)
 check('unchanged339 verifier reruns on exact accepted snapshot',r.returncode==0 and 'step339_repository_planning_status\tPASS' in r.stdout)
check('all accepted sources unchanged after schema tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
