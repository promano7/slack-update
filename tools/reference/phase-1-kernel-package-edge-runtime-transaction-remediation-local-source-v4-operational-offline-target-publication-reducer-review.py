#!/usr/bin/env python3
"""Review immutable repository-only admission model artifacts and prior return."""
from pathlib import Path
import ast
import hashlib
import json
import sys
BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review.md': '91bb44cd5fa69c0e036216ea7ae3f6cacbf84526bb032863f3ac1f51ed1a9d24', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review-checkpoint-confirmation.json': '4fbd601b64e06a68a247c669ee890d856a8e65afd7ab9be095265e71a594b9b2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review-contract.json': 'b0e0d275de57208fe7b4c189158cce90fdb5fdf842f72f6c1e7a4a3123cb5a73', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review-phase-map.json': '5a6b31667e0b0a72a6e7fe0df91bb20e2fe714944c905f53bde0b783325e7f52', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review-policy.json': 'a4fec1fe48da0f8ca639d611a62a851cee64a2784713b99632737f329b35edeb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review-step344-user-acceptance.json': '945b8917d763ea0bb94f49a724cb28cac5ecb1e7783966b19b888f9e17041e91', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer.py': '22fc51ade0c3a213b004b5b90a79fa7f9c5b2c2125748afbcf61b84aac369954'}
ADDITION_SHA='dcd3023801c2993c31fa44330cbf1f4e7c8fc5bdc58f4baabc4ac12656ba70fa'


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
 exact(confirmation['step'],344,'accepted344');exact(confirmation['commit_prefix'],'ba4ce74','reported accepted prefix');exact(confirmation['commit_full'],None,'full ID unknown')
 exact(confirmation['acceptance_result'],'PASS (881 passes, 0 failures)','complete881 summary')
 exact(confirmation['ordered_output_normalization'],'none','no return normalization')
 for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','push_first_attempt_succeeded'):exact(confirmation[k],True,'complete accepted344 '+k)
 for k in ('strong_safe_pause','runtime_authority','phase2_open'):exact(confirmation[k],False,'no native/new pause')
 for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native cases/proofs')
 exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'confirmed pause unchanged');exact(confirmation['actual_live_bindings'],None,'no live bindings');exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
 exact([x for x in lines if x.startswith('PASS: ')],policy['accepted_ordered344_labels'],'complete exact881 ordered labels')
 exact(sum(x.startswith('PASS: ') for x in lines),881,'all881');exact(lines.count('Result: PASS (881 passes, 0 failures)'),1,'single summary')
 exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],policy['accepted_step344_paths'],'exact9 new paths')
 exact(lines.count(' 10 files changed, 3903 insertions(+)'),1,'reported exact scope')
 message='Phase 1 step 344: model irreversible stop and finite original recovery'
 exact(lines.count('ba4ce74 (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching HEAD-origin')
 if 'b3a8db8..ba4ce74  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
 return True

def validate_mapping(mapping,contract,history):
 for field in ('core340_binding','recovery344_binding','map340_binding','interfaces332_binding'):
  b=mapping[field];exact(sha(history[b['path']]),b['sha256'],'unchanged frozen dependency')
 m=json.loads(history[mapping['map340_binding']['path']]);i=json.loads(history[mapping['interfaces332_binding']['path']]);original=i['inherited_phase_contract']
 phases=['worker11-close-target-evidence','release-target-control','worker12-publication-controls','worker12-publication-record','worker12-last-receipt','worker12-durable-handoff']
 exact(mapping['phase_rows'],{k:m['phases'][k] for k in phases},'six exact original closure/publication phases');exact(mapping['phase_view_types'],{k:m['phase_view_types'][k] for k in phases},'all original phase types');exact(contract['phase_order'],phases,'same original ordering')
 effect={p:m['phase_view_types'][p] for p in phases};budget={p:[v for v in effect[p] if v not in ('closed-target-evidence-view','target-release-view')] for p in phases[:2]};budget[phases[1]].append('closed-target-evidence-view')
 exact(mapping['budget_positive_views'],budget,'existing original budget before capture/release');exact(mapping['effect_positive_views'],effect,'all original effect input/output types')
 exact(mapping['source323_closure_contract'],original['selected_source_views']['323']['closure_contract'],'full original controller pending closure contract')
 exact(mapping['source327_crossclosure_contract'],original['selected_source_views']['327']['crossclosure_contract'],'full frozen crossclosure contract')
 for k in ('publication_contract','publication_branch_rule','retained_recovery_contract'):exact(mapping[k],original[k],'full original '+k)
 exact(contract['dependencies'],{'core340':mapping['core340_binding'],'recovery344':mapping['recovery344_binding']},'pinned dependencies');exact(contract['dependency_aliases'],['slack_update_offline_core340','slack_update_offline_recovery344'],'fixed aliases')
 for k in ('native_authority','native_evidence'):exact(mapping[k],False,'no native promotion');exact(contract[k],False,'no native promotion')
 for k in ('operational_readiness','strong_safe_pause','actual_publication_authority_supplied','actual_global_host_closure_asserted','actual_pair_atomicity_claimed'):exact(contract[k],False,'actual work unresolved')
 for k in ('native_cases_run','native_proofs_added'):exact(contract[k],0,'no native proof/case')
 for k,v in [('required_native_proofs_pending',46),('native_cases_pending',52),('native_gaps_pending',16)]:exact(contract[k],v,'native obligations unwaived')
 exact(contract['no_native_effects'],True,'pure model only')
 return True

def verify(root):
 root=Path(root).absolute()
 if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
 for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current345 source SHA')
 load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes());policy=load('-policy.json');history={}
 for relative,digest in policy['baseline_sha256_bindings'].items():
  raw=safe_file(root,relative).read_bytes()
  if relative=='CHANGELOG.md':
   size=policy['accepted_changelog_size']
   if len(raw)<=size:raise ValueError('missing additive345 changelog')
   exact(sha(raw[:-size]),ADDITION_SHA,'exact345 addition');raw=raw[-size:]
  exact(sha(raw),digest,'accepted344 bytes '+relative);history[relative]=raw
 exact(len(history),1683,'all accepted source files')
 validate_return(load('-checkpoint-confirmation.json'),load('-step344-user-acceptance.json'),policy)
 validate_mapping(load('-phase-map.json'),load('-contract.json'),history)
 ast.parse(safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer.py').read_text())
 return history

def main(argv):
 if argv==['--help']:print('Repository-only pure bootstrap guard model review: --check REPOSITORY');return 0
 if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
 try:verify(argv[1])
 except (ValueError,KeyError,TypeError,OSError) as error:print('ERROR: '+str(error),file=sys.stderr);return 1
 print('step345_pure_target_publication_review_status\tPASS');print('runtime_authority\tno');print('native_cases_run\t0');print('native_proofs_added\t0');return 0
if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
