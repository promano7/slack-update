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
import subprocess
import sys
import tempfile
import time

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review'
prefix = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
review_path = root / 'tools/reference' / (base + '.py')
review = runpy.run_path(str(review_path))
passes = 0


def check(label, condition):
    global passes
    if not condition:
        raise AssertionError(label)
    passes += 1
    print('PASS: ' + label, flush=True)


def rejects(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, TypeError, OSError):
        return True
    return False


def load(tail):
    return json.loads((fixture / (base + '-' + tail + '.json')).read_bytes())


def execute(command):
    # Progress stays on stderr, outside exact ordered acceptance labels. Child
    # stdout is kept intact and compared only after successful completion.
    with tempfile.TemporaryFile(mode='w+b') as out, tempfile.TemporaryFile(mode='w+b') as err:
        child = subprocess.Popen([str(x) for x in command], stdout=out, stderr=err)
        started = time.monotonic()
        while True:
            try:
                code = child.wait(timeout=30)
                break
            except subprocess.TimeoutExpired:
                print('Repository-only recursive suite still running (' + str(int(time.monotonic()-started)) + 's).', file=sys.stderr, flush=True)
        out.seek(0); err.seek(0)
        stdout, stderr = out.read().decode('utf-8'), err.read().decode('utf-8')
    if code:
        sys.stderr.write(stdout[-5000:] + stderr[-5000:])
    return code, stdout, stderr


history=review['verify'](root)
policy=load('policy');freeze=load('freeze');gaps=load('native-gap-register');conditions=load('pause-conditions')
receipt=load('step347-user-acceptance');confirmation=load('checkpoint-confirmation')
check('all1710 accepted347 source bytes preserved',len(history)==1710)
check('complete185 original347 receipt and exact commit scope accepted',review['validate_return'](confirmation,receipt,policy))
check('reportedfed2808 first push clean matching HEAD origin accepted',confirmation['commit_prefix']=='fed2808' and confirmation['user_worktree_clean'] and confirmation['user_head_matches_origin'])
check('all81 source-bound offline inputs frozen',review['validate_freeze'](freeze,history,policy))
check('full unchanged native gap proof case macro microstep register',review['validate_gap_register'](gaps,history))
check('all nine original pause conditions retained',review['validate_conditions'](conditions,freeze))
for row in freeze['frozen_artifact_registry339_347']:
    check('frozen accepted repository artifact '+str(row['step'])+'/'+row['path'],hashlib.sha256(history[row['path']]).hexdigest()==row['sha256'] and row['scope']=='repository-artifact-not-native-implementation')
for key,value in [('frozen_artifact_registry339_347',freeze['frozen_artifact_registry339_347'][:-1]),('freeze_version','native-implementation-freeze'),('scope','global-host-closure'),('next_authorized_stage','349'),('actual_host_state','absent'),('actual_live_bindings',{'boot':'historical'})]:
    bad=copy.deepcopy(freeze);bad[key]=value
    check('scope input host or future work cannot escape freeze '+key,rejects(review['validate_freeze'],bad,history,policy))
bad=copy.deepcopy(freeze);bad['frozen_artifact_registry339_347'][0]['sha256']='0'*64
check('changed accepted source cannot be frozen',rejects(review['validate_freeze'],bad,history,policy))
for key in ('strong_safe_pause','user_step348_checkpoint_confirmed','actual_operational_implementation_frozen','actual_native_refinement_complete','actual_dynamic_graph_complete','actual_independent_oracle_selected','operational_conformance','operational_readiness','runtime_authority','new_runtime_work_authorized','historical_binding_or_authority_reuse_allowed','machine_action_required','controller_action_required','new_batch_machine_cleanup_required','new_batch_controller_cleanup_required','later_current_refresh_invalidates_repository_only_pause','phase1_matrix_complete','kernel_package_edge_complete','phase2_open'):
    bad=copy.deepcopy(freeze);bad[key]=True
    check('repository freeze cannot promote native or pending fact '+key,rejects(review['validate_freeze'],bad,history,policy))
for key in ('native_cases_run','native_proofs_added'):
    for value in (1,True):
        bad=copy.deepcopy(freeze);bad[key]=value
        check('no native evidence or bool int promotion '+key+'/'+repr(value),rejects(review['validate_freeze'],bad,history,policy))
for key in ('stop_after_complete348_acceptance','future_work_requires_new_user_request','current348_user_acceptance_pending'):
    bad=copy.deepcopy(freeze);bad[key]=False
    check('batch stop and current receipt cannot be bypassed '+key,rejects(review['validate_freeze'],bad,history,policy))
for row in gaps['native_gap_rows']:
    check('native gap remains pending after artifact freeze '+row['inherited_gap']['id'],row['actual_independent_evidence'] is None and row['actual_native_event_relation'] is None and not row['native_status_promoted'])
for key in ('native_gap_rows','qualified_proofs','native_case_templates','macro_cut_obligations','owned_stage7_microsteps'):
    bad=copy.deepcopy(gaps);bad[key]=bad[key][:-1]
    check('missing full native obligation blocks freeze '+key,rejects(review['validate_gap_register'],bad,history))
bad=copy.deepcopy(gaps);bad['native_gap_rows'][0]['actual_independent_evidence']='model-pass'
check('model trace cannot become native gap evidence',rejects(review['validate_gap_register'],bad,history))
check('exact26 unrun native templates per platform retained',all(sum(row['platform']==platform for row in gaps['native_case_templates'])==26 for platform in ('Slackware-15.0','Slackware-current')))
check('full original finite clocks cuts and owned microsteps remain blockers','admission/forward' in gaps['clock_boundary'] and len(gaps['macro_cut_obligations'])==81 and len(gaps['owned_stage7_microsteps'])==9)
names=freeze['original_pause_conditions']
private={'schema':1,'step':348,'scope':freeze['scope'],'origin':'synthetic-private-fixture',
 'checks':{name:True for name in names},'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'runtime_authority':False}
result=review['private_pause_eligibility'](private,conditions)
check('all nine private checks only model eligibility',result['model_scoped_pause_confirmation_eligible'] and result['model_pending_conditions']==[])
for key in ('actual_strong_safe_pause_confirmed','actual_global_host_closure','actual_target_or_publication_closure','actual_native_implementation_frozen','actual_operational_conformance','actual_runtime_authority'):
    check('synthetic eligible receipt cannot confirm actual fact '+key,result[key] is False)
for i,name in enumerate(names):
    bad=copy.deepcopy(private);bad['checks'][name]=False
    result=review['private_pause_eligibility'](bad,conditions)
    check('each original condition independently blocks private eligibility '+name,not result['model_scoped_pause_confirmation_eligible'] and result['model_pending_conditions']==[name] and not result['actual_strong_safe_pause_confirmed'])
    wrong=copy.deepcopy(conditions);wrong['conditions'][i]['current348_actual_user_confirmation']=True
    check('historical or synthetic confirmation cannot fill current348 receipt '+name,rejects(review['validate_conditions'],wrong,freeze))
bad=copy.deepcopy(private);bad['checks']={name:False for name in names};result=review['private_pause_eligibility'](bad,conditions)
check('all pending conditions retained in original order',result['model_pending_conditions']==names and not result['model_scoped_pause_confirmation_eligible'])
for key,value in [('schema',True),('step',347),('scope','repository-other-workstream'),('scope','global-host-closure'),('origin','actual-native-receipt'),('actual_host_state','absent'),('actual_live_bindings',{'grant':'old'}),('runtime_authority',True)]:
    bad=copy.deepcopy(private);bad[key]=value
    check('foreign scope host evidence or authority private claim rejected '+key+'/'+repr(value),rejects(review['private_pause_eligibility'],bad,conditions))
for value in (1,0,'yes',None):
    bad=copy.deepcopy(private);bad['checks'][names[0]]=value
    check('exact boolean condition reports required '+repr(value),rejects(review['private_pause_eligibility'],bad,conditions))
for action in ('extra-grant','missing-check','extra-check'):
    bad=copy.deepcopy(private)
    if action=='extra-grant':bad['new_grant']='model-new-grant'
    elif action=='missing-check':del bad['checks'][names[0]]
    else:bad['checks']['new-authority']=True
    check('closed private pause handoff rejects '+action,rejects(review['private_pause_eligibility'],bad,conditions))
for mutation in ('lost-label','reverse-labels','lost-push','wrong-head','changed-created-path'):
    bad=copy.deepcopy(receipt)
    if mutation=='lost-label':bad['text']=bad['text'].replace(policy['accepted_ordered347_labels'][0]+'\n','',1)
    elif mutation=='reverse-labels':
        first,second=policy['accepted_ordered347_labels'][:2];bad['text']=bad['text'].replace(first+'\n'+second,second+'\n'+first,1)
    elif mutation=='lost-push':bad['text']=bad['text'].replace('038c896..fed2808  main -> main','push-unknown',1)
    elif mutation=='wrong-head':bad['text']=bad['text'].replace('fed2808 (HEAD -> main, origin/main, origin/HEAD)','0000000 (HEAD -> main, origin/main, origin/HEAD)',1)
    else:bad['text']=bad['text'].replace(' create mode 100644 docs/',' create mode 100644 altered/',1)
    raw=bad['text'].encode();bad['original_display_sha256']=hashlib.sha256(raw).hexdigest();bad['original_display_size_bytes']=len(raw)
    confirm=copy.deepcopy(confirmation);confirm['evidence_sha256']=bad['original_display_sha256'];confirm['evidence_size_bytes']=len(raw)
    check('complete user acceptance boundary rejects '+mutation,rejects(review['validate_return'],confirm,bad,policy))
for argv in ([],['--bogus'],['--check'],['--check','']):check('strict348 reviewer CLI '+repr(argv),review['main'](argv)==2)
code,stdout,stderr=execute(['python3','-B',review_path,'--check',root])
check('source-bound348 freeze review passes',code==0 and 'step348_offline_core_artifact_freeze_review_status\tPASS' in stdout)
check('prepared348 keeps last pause338 and no next batch authorization',freeze['last_confirmed_strong_safe_pause_step']==338 and freeze['current348_user_acceptance_pending'] and freeze['next_authorized_stage'] is None and not freeze['strong_safe_pause'])
with tempfile.TemporaryDirectory(prefix='step348-accepted347-') as directory:
    snapshot=Path(directory)/'accepted347';snapshot.mkdir()
    for relative,raw in history.items():
        p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
    code,stdout,stderr=execute(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot])
    check('unchanged347 reviewer accepts full exact1710 historical source',code==0)
    print('Running full unchanged347185 and recursive346/340–345/338 suites; progress every30s.',file=sys.stderr,flush=True)
    code,stdout,stderr=execute(['bash',snapshot/policy['predecessor_harness']])
    check('full unchanged347185 recursive suites pass',code==0 and stdout.splitlines().count(policy['predecessor_result'])==1)
    check('all185 prior labels exactly match complete accepted347 return',[x for x in stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered347_labels'])
check('all1710 accepted bytes intact after freeze tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)',flush=True)
PYTEST
