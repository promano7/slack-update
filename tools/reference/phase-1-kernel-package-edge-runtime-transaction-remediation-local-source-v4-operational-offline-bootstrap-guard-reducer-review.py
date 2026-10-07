#!/usr/bin/env python3
"""Review immutable repository-only admission model artifacts and prior return."""
from pathlib import Path
import ast
import hashlib
import json
import sys
BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review.md': 'dbf8e4f00e3f2aaf4c42bf6dd3adda98aeb9e0f10a73617a717c7acee929c3ad', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review-checkpoint-confirmation.json': '136c76b93b8fc646d862c37154b286fa1cb5735626e0e9e63baf53c849f73239', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review-contract.json': 'dc50f4e3490ce354392812fc4a1d551b3cf62ee6e8f997447f937023c2255912', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review-phase-map.json': '06dc9224f6870055108f68e22f458f472de0da7fd771dc369876b4b3cb377487', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review-policy.json': '4e7598ae812a568105563b71b9e6c6633a137d9fcbdb90d4664db4c331a60509', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review-step341-user-acceptance.json': '8678e3e2a8a6f7e0669085deaee5df09fd670f7aa5a8f30e3cb80b97dfc0e543', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer.py': '201636350a88c7562cad5cf04f71d5c582b7ea547c2e98b1f7a3751756b32e89'}
ADDITION_SHA='da5f0c3cbedc41db4adddb0d811cc842f4695c986d9f0953a3a72542d0785360'


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
 exact(confirmation['step'],341,'accepted341');exact(confirmation['commit_prefix'],'1e350de','reported accepted prefix');exact(confirmation['commit_full'],None,'full ID unknown')
 exact(confirmation['acceptance_result'],'PASS (462 passes, 0 failures)','complete462 summary')
 exact(confirmation['ordered_output_normalization'],'none','no return normalization')
 for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','push_first_attempt_succeeded'):exact(confirmation[k],True,'complete accepted341 '+k)
 for k in ('strong_safe_pause','runtime_authority','phase2_open'):exact(confirmation[k],False,'no native/new pause')
 for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native cases/proofs')
 exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'confirmed pause unchanged');exact(confirmation['actual_live_bindings'],None,'no live bindings');exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
 exact([x for x in lines if x.startswith('PASS: ')],policy['accepted_ordered341_labels'],'complete exact462 ordered labels')
 exact(sum(x.startswith('PASS: ') for x in lines),462,'all462');exact(lines.count('Result: PASS (462 passes, 0 failures)'),1,'single summary')
 exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],policy['accepted_step341_paths'],'exact9 new paths')
 exact(lines.count(' 10 files changed, 3041 insertions(+)'),1,'reported exact scope')
 message='Phase 1 step 341: implement pure admission and single launch reducer'
 exact(lines.count('1e350de (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching HEAD-origin')
 if '1804cc1..1e350de  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
 return True

def validate_mapping(mapping,contract,history):
 for field in ('core340_binding','admission341_binding','map340_binding','interfaces332_binding'):
  binding=mapping[field];exact(sha(history[binding['path']]),binding['sha256'],'bound unchanged source dependency')
 m=json.loads(history[mapping['map340_binding']['path']]);i=json.loads(history[mapping['interfaces332_binding']['path']]);source=i['inherited_phase_contract']['selected_source_views']['321']
 phases=['worker0-bounded-auth-read','worker0-close-bootstrap','worker0-readonly-preflight','worker1-arm-traps','interstage1-2-guard-freshoriginal']
 exact(mapping['phase_rows'],{k:m['phases'][k] for k in phases},'all five exact source phases')
 exact(mapping['phase_view_types'],{k:m['phase_view_types'][k] for k in phases},'source-bound allowed nominal types')
 exact(contract['phase_order'],phases,'source order')
 common=['consumed-original-context','dependency-closure-view','source-closure-view']
 expected={phases[0]:common+['spent-launch-view','closed-bootstrap-view'],phases[1]:common+['spent-launch-view','closed-bootstrap-view'],phases[2]:common+['closed-bootstrap-view','early-observation-view'],phases[3]:common+['armed-traps-view','known-child-set-view','live-original-fence-view'],phases[4]:common+['armed-traps-view','live-original-fence-view','continuous-guard-view','original-baseline-view']}
 exact(mapping['required_positive_views'],expected,'full positive source-bound view contract')
 for phase,views in expected.items():
  if not set(views).issubset(m['phase_view_types'][phase]):raise ValueError('unknown nominal type')
 limits={k:source['bootstrap'][k] for k in ('maximum_raw_bytes','deadline_seconds','symbolic_read_fd')}
 exact(mapping['source321_contract'],source,'all original321 handoff and containment constraints retained')
 exact(mapping['bootstrap_limits'],limits,'source321 exact limits');exact(contract['bootstrap_limits'],limits,'same bounds')
 exact(limits,{'maximum_raw_bytes':65536,'deadline_seconds':10,'symbolic_read_fd':3},'fixed original bootstrap bounds')
 exact(contract['dependencies'],{'core340':mapping['core340_binding'],'admission341':mapping['admission341_binding']},'same immutable source versions')
 exact(contract['dependency_aliases'],['slack_update_offline_core340','slack_update_offline_admission341'],'private pinned aliases')
 for k in ('native_authority','native_evidence'):exact(mapping[k],False,'no native promotion');exact(contract[k],False,'no native promotion')
 for k in ('worker_owned_stage2_authorized','operational_readiness','strong_safe_pause'):exact(contract[k],False,'later/native work incomplete')
 for k in ('native_cases_run','native_proofs_added'):exact(contract[k],0,'no native execution or proof')
 for k,v in [('required_native_proofs_pending',46),('native_cases_pending',52),('native_gaps_pending',16)]:exact(contract[k],v,'unwaived native obligations')
 exact(contract['no_native_effects'],True,'pure scope')
 return True

def verify(root):
 root=Path(root).absolute()
 if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
 for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current342 source SHA')
 load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes());policy=load('-policy.json');history={}
 for relative,digest in policy['baseline_sha256_bindings'].items():
  raw=safe_file(root,relative).read_bytes()
  if relative=='CHANGELOG.md':
   size=policy['accepted_changelog_size']
   if len(raw)<=size:raise ValueError('missing additive342 changelog')
   exact(sha(raw[:-size]),ADDITION_SHA,'exact342 addition');raw=raw[-size:]
  exact(sha(raw),digest,'accepted341 bytes '+relative);history[relative]=raw
 exact(len(history),1656,'all accepted source files')
 validate_return(load('-checkpoint-confirmation.json'),load('-step341-user-acceptance.json'),policy)
 validate_mapping(load('-phase-map.json'),load('-contract.json'),history)
 ast.parse(safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer.py').read_text())
 return history

def main(argv):
 if argv==['--help']:print('Repository-only pure bootstrap guard model review: --check REPOSITORY');return 0
 if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
 try:verify(argv[1])
 except (ValueError,KeyError,TypeError,OSError) as error:print('ERROR: '+str(error),file=sys.stderr);return 1
 print('step342_pure_bootstrap_guard_review_status\tPASS');print('runtime_authority\tno');print('native_cases_run\t0');print('native_proofs_added\t0');return 0
if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
