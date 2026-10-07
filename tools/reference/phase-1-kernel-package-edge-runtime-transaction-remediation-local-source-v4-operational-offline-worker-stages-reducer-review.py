#!/usr/bin/env python3
"""Review immutable repository-only admission model artifacts and prior return."""
from pathlib import Path
import ast
import hashlib
import json
import sys
BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review.md': '98c6d774c8be81e480ca517bf365155cfeb9464a72e3e3bde52e859214b4ea6a', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review-checkpoint-confirmation.json': 'bce826adfc031ca9f051612dc3ff5e69f83fc08f826446b33c0794d03ac479f8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review-contract.json': '2d124e45a9fd200e1f47099ee9fc48d847c3b7ce24eb98477b7fae24cf736c99', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review-phase-map.json': '0903fb323dd6e31749135d7fb460de604eff1e694775c160a74ef103145e3e87', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review-policy.json': '7e1b9f32c99a03d46c63defb199b9bba30cdb3a10a64fde48f2d780d6a4e258b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review-step342-user-acceptance.json': 'd9f610d61e67935eee842d0e19d5c35d541574aa1a820370118409becb704625', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer.py': '2678499696ddc9293998dbcd5916aab29c028b045569ade416b38752629836a8'}
ADDITION_SHA='d15c45307097bd59d122bd25a098c0c8648dbf36164e5010aaf56f831da835f8'


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
 exact(confirmation['step'],342,'accepted342');exact(confirmation['commit_prefix'],'914eb3b','reported accepted prefix');exact(confirmation['commit_full'],None,'full ID unknown')
 exact(confirmation['acceptance_result'],'PASS (599 passes, 0 failures)','complete599 summary')
 exact(confirmation['ordered_output_normalization'],'none','no return normalization')
 for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','push_first_attempt_succeeded'):exact(confirmation[k],True,'complete accepted342 '+k)
 for k in ('strong_safe_pause','runtime_authority','phase2_open'):exact(confirmation[k],False,'no native/new pause')
 for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native cases/proofs')
 exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'confirmed pause unchanged');exact(confirmation['actual_live_bindings'],None,'no live bindings');exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
 exact([x for x in lines if x.startswith('PASS: ')],policy['accepted_ordered342_labels'],'complete exact599 ordered labels')
 exact(sum(x.startswith('PASS: ') for x in lines),599,'all599');exact(lines.count('Result: PASS (599 passes, 0 failures)'),1,'single summary')
 exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],policy['accepted_step342_paths'],'exact9 new paths')
 exact(lines.count(' 10 files changed, 3049 insertions(+)'),1,'reported exact scope')
 message='Phase 1 step 342: model bounded bootstrap traps and fresh original guard'
 exact(lines.count('914eb3b (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching HEAD-origin')
 if '1e350de..914eb3b  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
 return True

def validate_mapping(mapping,contract,history):
 for field in ('core340_binding','admission341_binding','bootstrap342_binding','map340_binding','interfaces332_binding','inventory330_binding'):
  b=mapping[field];exact(sha(history[b['path']]),b['sha256'],'exact unchanged frozen dependency')
 m=json.loads(history[mapping['map340_binding']['path']]);i=json.loads(history[mapping['interfaces332_binding']['path']]);v=json.loads(history[mapping['inventory330_binding']['path']]);original=i['inherited_phase_contract']
 phases=['worker2-owned-workspace','worker3-original-backups','worker4-exact-predecessor','worker5-local-isolation','worker6-refresh-pin-once','worker7-validate-pinned-candidate','worker7-owned-durable-commit','worker8-whole-successor-apply']
 exact(mapping['phase_rows'],{k:m['phases'][k] for k in phases},'eight exact source phases');exact(mapping['phase_view_types'],{k:m['phase_view_types'][k] for k in phases},'all allowed original interface types');exact(contract['phase_order'],phases,'same source ordering')
 common=['consumed-original-context','continuous-guard-view','live-original-fence-view','dependency-closure-view','source-closure-view']
 expected={phases[0]:common+['original-baseline-view','owned-path-set-view'],phases[1]:common+['original-baseline-view','owned-path-set-view','original-backups-view'],phases[2]:common+['original-backups-view','exact-predecessor-view','complete-effect-graph-view','package-effect-result-view'],phases[3]:common+['original-backups-view','exact-predecessor-view','isolated-config-view'],phases[4]:common+['original-backups-view','exact-predecessor-view','isolated-config-view','complete-effect-graph-view','raw-pkglist-pin-view','full-selector-vector-view'],phases[5]:common+['raw-pkglist-pin-view','candidate-binding-view'],phases[6]:common+['raw-pkglist-pin-view','candidate-binding-view'],phases[7]:m['phase_view_types'][phases[7]]}
 exact(mapping['required_positive_views'],expected,'all phase view obligations; whole16 types')
 for phase,views in expected.items():
  if not set(views).issubset(m['phase_view_types'][phase]):raise ValueError('outside frozen type contract')
 exact(len(expected[phases[7]]),16,'whole boundary not three-call substitute')
 for k in ('stage7_microsteps',):exact(mapping[k],original['stage7_owned_commit_sequence'],'nine original microsteps');exact(contract[k],mapping[k],'same microsteps')
 exact(mapping['source322_contract'],original['selected_source_views']['322'],'full original owned durability contract')
 exact(mapping['source325_contract'],original['selected_source_views']['325'],'full graph selector and whole contract')
 exact(mapping['original_designed_domains'],[n['id'] for n in v['candidate_nodes']],'all30 exact domains')
 exact(mapping['original_macro_relations'],[[n['source'],n['target']] for n in v['candidate_edges']],'all95 exact designed relations')
 exact(len(mapping['original_designed_domains']),30,'original domain count');exact(len(mapping['original_macro_relations']),95,'original relation count')
 exact(mapping['whole_private_observations'],['nested-update','nested-install-new','nested-upgrade-all','whole-entry-complete'],'private observations within source phase');exact(contract['whole_private_observations'],mapping['whole_private_observations'],'whole completion distinct')
 exact(contract['dependencies'],{'core340':mapping['core340_binding'],'admission341':mapping['admission341_binding'],'bootstrap342':mapping['bootstrap342_binding']},'unchanged source dependencies')
 exact(contract['dependency_aliases'],['slack_update_offline_core340','slack_update_offline_bootstrap342'],'fixed private aliases')
 for k in ('native_authority','native_evidence'):exact(mapping[k],False,'no native promotion');exact(contract[k],False,'no native promotion')
 for k in ('operational_readiness','strong_safe_pause','actual_successor_entry_selected','actual_dynamic_graph_complete','actual_native_authority_supplied'):exact(contract[k],False,'actual work unresolved')
 for k in ('native_cases_run','native_proofs_added'):exact(contract[k],0,'no native proof/case')
 for k,v in [('required_native_proofs_pending',46),('native_cases_pending',52),('native_gaps_pending',16)]:exact(contract[k],v,'native obligations unwaived')
 exact(contract['no_native_effects'],True,'pure model only')
 return True

def verify(root):
 root=Path(root).absolute()
 if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
 for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current343 source SHA')
 load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes());policy=load('-policy.json');history={}
 for relative,digest in policy['baseline_sha256_bindings'].items():
  raw=safe_file(root,relative).read_bytes()
  if relative=='CHANGELOG.md':
   size=policy['accepted_changelog_size']
   if len(raw)<=size:raise ValueError('missing additive343 changelog')
   exact(sha(raw[:-size]),ADDITION_SHA,'exact343 addition');raw=raw[-size:]
  exact(sha(raw),digest,'accepted342 bytes '+relative);history[relative]=raw
 exact(len(history),1665,'all accepted source files')
 validate_return(load('-checkpoint-confirmation.json'),load('-step342-user-acceptance.json'),policy)
 validate_mapping(load('-phase-map.json'),load('-contract.json'),history)
 ast.parse(safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer.py').read_text())
 return history

def main(argv):
 if argv==['--help']:print('Repository-only pure bootstrap guard model review: --check REPOSITORY');return 0
 if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
 try:verify(argv[1])
 except (ValueError,KeyError,TypeError,OSError) as error:print('ERROR: '+str(error),file=sys.stderr);return 1
 print('step343_pure_worker_stages_review_status\tPASS');print('runtime_authority\tno');print('native_cases_run\t0');print('native_proofs_added\t0');return 0
if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
