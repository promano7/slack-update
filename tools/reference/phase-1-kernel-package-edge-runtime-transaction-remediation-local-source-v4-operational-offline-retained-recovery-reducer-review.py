#!/usr/bin/env python3
"""Review immutable repository-only admission model artifacts and prior return."""
from pathlib import Path
import ast
import hashlib
import json
import sys
BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review.md': '21b982ae461346cc07f8802caac0d00c8d259e60685fa9cb1fb48069cccc2ec2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review-checkpoint-confirmation.json': '34955a8fa6958fc7344315e1730d377700b76640ec918c2f7db9084c36fbeffa', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review-contract.json': 'd942ff25f77dde7d48204a251cb83ccc24a6ac9795d93203d2b78c8bc595266d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review-phase-map.json': 'abf9bcbcd8571fb13d2cca8cb35950c63be5a098bf94017fced65a31f9fdd11a', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review-policy.json': 'db08c1a455aa300fe29d672ffabf6afa5ed351e63b5a3a0224516c5fe63852da', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review-step343-user-acceptance.json': '762648cd2882150534a513f5174fd53f8f7f553cf20c9c450a972052b4b3ca6e', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer.py': '8fa9dd38fd7affba5612f093667a118407fb8d8c96531943278b07180904af0a'}
ADDITION_SHA='b79e4829ca7cb913d781c57ce554e00bd8314ab36393b7b92e2f55ef3463236d'


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
 exact(confirmation['step'],343,'accepted343');exact(confirmation['commit_prefix'],'b3a8db8','reported accepted prefix');exact(confirmation['commit_full'],None,'full ID unknown')
 exact(confirmation['acceptance_result'],'PASS (1255 passes, 0 failures)','complete1255 summary')
 exact(confirmation['ordered_output_normalization'],'none','no return normalization')
 for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','push_first_attempt_succeeded'):exact(confirmation[k],True,'complete accepted343 '+k)
 for k in ('strong_safe_pause','runtime_authority','phase2_open'):exact(confirmation[k],False,'no native/new pause')
 for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native cases/proofs')
 exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'confirmed pause unchanged');exact(confirmation['actual_live_bindings'],None,'no live bindings');exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
 exact([x for x in lines if x.startswith('PASS: ')],policy['accepted_ordered343_labels'],'complete exact1255 ordered labels')
 exact(sum(x.startswith('PASS: ') for x in lines),1255,'all1255');exact(lines.count('Result: PASS (1255 passes, 0 failures)'),1,'single summary')
 exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],policy['accepted_step343_paths'],'exact9 new paths')
 exact(lines.count(' 10 files changed, 3988 insertions(+)'),1,'reported exact scope')
 message='Phase 1 step 343: model owned worker pin durable binding and whole successor'
 exact(lines.count('b3a8db8 (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching HEAD-origin')
 if '914eb3b..b3a8db8  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
 return True

def validate_mapping(mapping,contract,history):
 for field in ('core340_binding','worker343_binding','map340_binding','interfaces332_binding'):
  b=mapping[field];exact(sha(history[b['path']]),b['sha256'],'unchanged frozen dependency')
 m=json.loads(history[mapping['map340_binding']['path']]);i=json.loads(history[mapping['interfaces332_binding']['path']]);original=i['inherited_phase_contract']
 phases=['stop-forward-irreversibly','drain-known-owned-children','worker9-original-restoration','worker10-original-verification']
 exact(mapping['phase_rows'],{k:m['phases'][k] for k in phases},'four exact original recovery phases');exact(mapping['phase_view_types'],{k:m['phase_view_types'][k] for k in phases},'all original phase types');exact(contract['phase_order'],phases,'same original ordering')
 stop=['consumed-original-context','dependency-closure-view','live-original-fence-view','source-closure-view']
 common=['consumed-original-context','continuous-guard-view','live-original-fence-view','dependency-closure-view','source-closure-view']
 budget={phases[0]:stop,phases[1]:common+['armed-traps-view','known-child-set-view'],phases[2]:common+['original-baseline-view','quiescent-child-view','complete-effect-graph-view','recovery-budget-view'],phases[3]:common+['original-baseline-view','quiescent-child-view']}
 effect={phases[0]:stop,phases[1]:budget[phases[1]]+['quiescent-child-view'],phases[2]:budget[phases[2]]+['original-restoration-result-view','package-effect-result-view'],phases[3]:budget[phases[3]]+['original-verification-view']}
 exact(mapping['budget_positive_views'],budget,'spend input views separately from effect outputs');exact(mapping['effect_positive_views'],effect,'known effect result required')
 for phase,views in effect.items():
  if not set(views).issubset(m['phase_view_types'][phase]):raise ValueError('outside frozen type contract')
 exact(mapping['source323_contract'],original['selected_source_views']['323'],'full same-original finite recovery contract')
 exact(mapping['source326_recovery_contract'],original['selected_source_views']['326']['model_contract'],'full frozen finite macro model contract')
 for k in ('guarded_recovery_contract','original_baseline_rule'):exact(mapping[k],original[k],'full original '+k)
 exact(mapping['budget_fixture_domain'],list(range(9)),'private0..8 budget unchanged')
 exact(contract['dependencies'],{'core340':mapping['core340_binding'],'worker343':mapping['worker343_binding']},'pinned model dependencies')
 exact(contract['dependency_aliases'],['slack_update_offline_core340','slack_update_offline_worker343'],'fixed private aliases')
 for k in ('native_authority','native_evidence'):exact(mapping[k],False,'no native promotion');exact(contract[k],False,'no native promotion')
 for k in ('operational_readiness','strong_safe_pause','actual_recovery_authority_supplied','actual_global_host_closure_asserted'):exact(contract[k],False,'actual work unresolved')
 for k in ('native_cases_run','native_proofs_added'):exact(contract[k],0,'no native proof/case')
 for k,v in [('required_native_proofs_pending',46),('native_cases_pending',52),('native_gaps_pending',16)]:exact(contract[k],v,'native obligations unwaived')
 exact(contract['no_native_effects'],True,'pure model only')
 return True

def verify(root):
 root=Path(root).absolute()
 if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
 for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current344 source SHA')
 load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes());policy=load('-policy.json');history={}
 for relative,digest in policy['baseline_sha256_bindings'].items():
  raw=safe_file(root,relative).read_bytes()
  if relative=='CHANGELOG.md':
   size=policy['accepted_changelog_size']
   if len(raw)<=size:raise ValueError('missing additive344 changelog')
   exact(sha(raw[:-size]),ADDITION_SHA,'exact344 addition');raw=raw[-size:]
  exact(sha(raw),digest,'accepted343 bytes '+relative);history[relative]=raw
 exact(len(history),1674,'all accepted source files')
 validate_return(load('-checkpoint-confirmation.json'),load('-step343-user-acceptance.json'),policy)
 validate_mapping(load('-phase-map.json'),load('-contract.json'),history)
 ast.parse(safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer.py').read_text())
 return history

def main(argv):
 if argv==['--help']:print('Repository-only pure bootstrap guard model review: --check REPOSITORY');return 0
 if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
 try:verify(argv[1])
 except (ValueError,KeyError,TypeError,OSError) as error:print('ERROR: '+str(error),file=sys.stderr);return 1
 print('step344_pure_retained_recovery_review_status\tPASS');print('runtime_authority\tno');print('native_cases_run\t0');print('native_proofs_added\t0');return 0
if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
