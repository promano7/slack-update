#!/usr/bin/env python3
"""Review immutable repository-only admission model artifacts and prior return."""
from pathlib import Path
import ast
import hashlib
import json
import sys
BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review.md': '6054ceaaac9db97395003971073fb9d68cb3295496871681bf12da5374b2d23a', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review-checkpoint-confirmation.json': '2f6ee6000b9c564953b4c7ee53540a7d6ac64440d704f4871e82699f735cd535', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review-contract.json': '93bb2da25e58f6b38108fddb18ab56000a06edd349a85b349e68657ef6cc2f82', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review-phase-map.json': 'a8d67032186f2f8df13b065659e7af637c93ddbefb3019307169375d610fdd58', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review-policy.json': '99d7ba0c7eba8719aa4d4851a47e184237a23779ddb7c030a24f7d93c947ac41', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review-step340-user-acceptance.json': 'e769e8b46c541bf61ad90bf07aff4e061e5d45b954413def096c2dbda5a4062a', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer.py': '1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed'}
ADDITION_SHA='b54e1cd6cd8128a1953144b45b1eb2b5fdfcb50cd0aa28ae0b667d791433718c'


def sha(x):return hashlib.sha256(x).hexdigest()
def exact(value,expected,label):
 if type(value) is not type(expected) or value!=expected:raise ValueError(label)
def safe_file(root,relative):
 if type(relative) is not str or not relative or '\\' in relative or any(p in ('','.','..') for p in relative.split('/')):raise ValueError('unsafe repository path')
 p=root/relative
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute():raise ValueError('unsafe source '+relative)
 return p

def validate_return(confirmation,receipt,policy):
 raw=receipt['text'].encode();lines=receipt['text'].splitlines()
 exact(receipt['encoding'],'utf8-json-text','full original encoding')
 exact(len(raw),receipt['original_display_size_bytes'],'full original size');exact(sha(raw),receipt['original_display_sha256'],'full original SHA')
 exact(sha(raw),confirmation['evidence_sha256'],'confirmation bound original');exact(len(raw),confirmation['evidence_size_bytes'],'confirmation full original')
 exact(confirmation['step'],340,'accepted340');exact(confirmation['commit_prefix'],'1804cc1','reported accepted prefix');exact(confirmation['commit_full'],None,'full ID unknown')
 exact(confirmation['acceptance_result'],'PASS (624 passes, 0 failures)','complete624 summary')
 exact(confirmation['ordered_output_normalization'],'none','no return normalization')
 for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','push_first_attempt_succeeded'):exact(confirmation[k],True,'complete accepted340 '+k)
 for k in ('strong_safe_pause','runtime_authority','phase2_open'):exact(confirmation[k],False,'no native/new pause')
 for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native cases/proofs')
 exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'confirmed pause unchanged');exact(confirmation['actual_live_bindings'],None,'no live bindings');exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
 exact([x for x in lines if x.startswith('PASS: ')],policy['accepted_ordered340_labels'],'complete exact624 ordered labels')
 exact(sum(x.startswith('PASS: ') for x in lines),624,'all624');exact(lines.count('Result: PASS (624 passes, 0 failures)'),1,'single summary')
 exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],policy['accepted_step340_paths'],'exact9 new paths')
 exact(lines.count(' 10 files changed, 3402 insertions(+)'),1,'reported exact scope')
 message='Phase 1 step 340: define immutable offline state event and result schemas'
 exact(lines.count('1804cc1 (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching HEAD-origin')
 if '83b8441..1804cc1  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
 return True

def validate_mapping(mapping,contract,history):
 for field in ('core340_binding','map340_binding'):
  binding=mapping[field];exact(sha(history[binding['path']]),binding['sha256'],'bound unchanged340 dependency')
 m=json.loads(history[mapping['map340_binding']['path']]);phases=['service-barrier-authentication','service-original-durable-claim','service-durable-launch-spend','service-single-worker-spawn']
 exact(mapping['phase_rows'],{k:m['phases'][k] for k in phases},'all four exact original service phases')
 exact(mapping['phase_view_types'],{k:m['phase_view_types'][k] for k in phases},'source-bound allowed view types')
 exact(contract['phase_order'],phases,'source service order')
 expected={phases[0]:['authenticated-policy-view'],phases[1]:['authenticated-policy-view','consumed-original-context'],phases[2]:['consumed-original-context','spent-launch-view'],phases[3]:['consumed-original-context','spent-launch-view']}
 for phase,v in expected.items():v.extend(['dependency-closure-view','source-closure-view']);v.extend(['issuer-policy-view'] if phase==phases[0] else [])
 exact(mapping['required_positive_views'],expected,'all policy/consumed/spent bindings')
 for k,v in expected.items():
  if not set(v).issubset(m['phase_view_types'][k]):raise ValueError('required type not in frozen phase contract')
 exact(contract['core340_binding'],mapping['core340_binding'],'same immutable core version')
 exact(contract['dependency_alias'],'slack_update_offline_core340','private pinned dependency alias')
 for k in ('native_authority','native_evidence'):exact(mapping[k],False,'mapping no native promotion');exact(contract[k],False,'contract no native promotion')
 for k in ('worker_stage0_authorized','operational_readiness','strong_safe_pause'):exact(contract[k],False,'incomplete later/native work')
 for k in ('native_cases_run','native_proofs_added'):exact(contract[k],0,'private data not native proof')
 for k,v in [('required_native_proofs_pending',46),('native_cases_pending',52),('native_gaps_pending',16)]:exact(contract[k],v,'unwaived native obligations')
 exact(contract['no_native_effects'],True,'pure scope');exact(contract['no_request_match_or_preflight_gate_before_claim'],True,'burn before worker preflight')
 return True

def verify(root):
 root=Path(root).absolute()
 if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
 for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current341 source SHA')
 load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes());policy=load('-policy.json');history={}
 for relative,digest in policy['baseline_sha256_bindings'].items():
  raw=safe_file(root,relative).read_bytes()
  if relative=='CHANGELOG.md':
   size=policy['accepted_changelog_size']
   if len(raw)<=size:raise ValueError('missing additive341 changelog')
   exact(sha(raw[:-size]),ADDITION_SHA,'exact341 addition');raw=raw[-size:]
  exact(sha(raw),digest,'accepted340 bytes '+relative);history[relative]=raw
 exact(len(history),1647,'all accepted source files')
 validate_return(load('-checkpoint-confirmation.json'),load('-step340-user-acceptance.json'),policy)
 validate_mapping(load('-phase-map.json'),load('-contract.json'),history)
 ast.parse(safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer.py').read_text())
 return history

def main(argv):
 if argv==['--help']:print('Repository-only pure admission model review: --check REPOSITORY');return 0
 if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
 try:verify(argv[1])
 except (ValueError,KeyError,TypeError,OSError) as error:print('ERROR: '+str(error),file=sys.stderr);return 1
 print('step341_pure_admission_launch_review_status\tPASS');print('runtime_authority\tno');print('native_cases_run\t0');print('native_proofs_added\t0');return 0
if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
