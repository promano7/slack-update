#!/usr/bin/env python3
"""Review immutable repository-only admission model artifacts and prior return."""
from pathlib import Path
import ast
import hashlib
import json
import sys
BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review.md': '4e3b946d1dc4fe33fa3e1050b63c514f4c587beb80567663193a984cdf900063', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review-checkpoint-confirmation.json': '7421b95a2a2d30a1a284205bb87f506f5d879d94a1fb8cd31e3580d6b07ef836', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review-contract.json': '2442c48ba4acea258f4c2586c0614d9918c44b2ec0b43d5f6cf9a09ff0fb171b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review-phase-map.json': 'e843e1b9b2d3cca58f2a945c58c929f1b528fd157cd38e30bdf80ee075156f1f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review-policy.json': '890384483d3aaf691d939ed5720b3e0ac8e652760089bb1699a56736da1a607e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review-step345-user-acceptance.json': '69833df9b977a3950ce9e45f6f885e4328f68e854375a1be2c620ab39cdda9d5', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-auditor.py': 'f22c34c50f622812b4b5793bff33094560797af4c45f9bf87257f352af0bee26'}
ADDITION_SHA='fa3831188dcf420d51ecdfbfa44ad4323f75c2e61e3644743868f7fc152ad4aa'


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
 exact(confirmation['step'],345,'accepted345');exact(confirmation['commit_prefix'],'8f6b3cd','reported accepted prefix');exact(confirmation['commit_full'],None,'full ID unknown')
 exact(confirmation['acceptance_result'],'PASS (1041 passes, 0 failures)','complete1041 summary')
 exact(confirmation['ordered_output_normalization'],'none','no return normalization')
 for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','push_first_attempt_succeeded'):exact(confirmation[k],True,'complete accepted345 '+k)
 for k in ('strong_safe_pause','runtime_authority','phase2_open'):exact(confirmation[k],False,'no native/new pause')
 for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native cases/proofs')
 exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'confirmed pause unchanged');exact(confirmation['actual_live_bindings'],None,'no live bindings');exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
 exact([x for x in lines if x.startswith('PASS: ')],policy['accepted_ordered345_labels'],'complete exact1041 ordered labels')
 exact(sum(x.startswith('PASS: ') for x in lines),1041,'all1041');exact(lines.count('Result: PASS (1041 passes, 0 failures)'),1,'single summary')
 exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],policy['accepted_step345_paths'],'exact9 new paths')
 exact(lines.count(' 10 files changed, 3633 insertions(+)'),1,'reported exact scope')
 message='Phase 1 step 345: model target evidence release and captured-data publication'
 exact(lines.count('8f6b3cd (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching HEAD-origin')
 if 'ba4ce74..8f6b3cd  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
 return True

def validate_mapping(mapping,contract,history):
 for b in list(mapping['dependencies'].values())+[mapping['map340_binding'],mapping['interfaces332_binding']]:exact(sha(history[b['path']]),b['sha256'],'unchanged frozen component')
 m=json.loads(history[mapping['map340_binding']['path']]);i=json.loads(history[mapping['interfaces332_binding']['path']]);original=i['inherited_phase_contract']
 exact(mapping['phase_rows'],m['phases'],'all27 original phase rows');exact(mapping['phase_view_types'],m['phase_view_types'],'all35 original types in phase context')
 exact(mapping['source326_model_contract'],original['selected_source_views']['326']['model_contract'],'full original finite fault contract');exact(mapping['source327_crossclosure_contract'],original['selected_source_views']['327']['crossclosure_contract'],'full original crossclosure contract')
 families=['admission','bootstrap','worker','recovery','finalization'];transfers=[['admission','bootstrap'],['bootstrap','worker'],['worker','recovery'],['recovery','finalization']]
 exact(mapping['families'],families,'five exact typed families');exact(contract['family_order'],families,'same family order');exact(mapping['private_transfers'],transfers,'explicit private model boundaries');exact(contract['private_transfers'],transfers,'same boundaries')
 for k,v in [('golden_report_count',43),('golden_total_observations',47),('max_private_operations',128)]:exact(mapping[k],v,'finite declared '+k);exact(contract[k],v,'same bounded '+k)
 exact(mapping['original_phase_count'],27,'no new native phase');exact(mapping['golden_transfer_count'],4,'four private transfers')
 exact(contract['dependencies'],mapping['dependencies'],'all unchanged modules')
 for k in ('native_authority','native_evidence'):exact(mapping[k],False,'no native promotion');exact(contract[k],False,'no native promotion')
 for k in ('operational_readiness','strong_safe_pause','actual_global_host_closure_asserted','actual_concurrency_exhaustive'):exact(contract[k],False,'actual work unresolved')
 for k in ('native_cases_run','native_proofs_added'):exact(contract[k],0,'no native proof/case')
 for k,v in [('required_native_proofs_pending',46),('native_cases_pending',52),('native_gaps_pending',16)]:exact(contract[k],v,'native obligations unwaived')
 exact(contract['no_native_effects'],True,'pure model only')
 return True

def verify(root):
 root=Path(root).absolute()
 if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
 for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current346 source SHA')
 load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes());policy=load('-policy.json');history={}
 for relative,digest in policy['baseline_sha256_bindings'].items():
  raw=safe_file(root,relative).read_bytes()
  if relative=='CHANGELOG.md':
   size=policy['accepted_changelog_size']
   if len(raw)<=size:raise ValueError('missing additive346 changelog')
   exact(sha(raw[:-size]),ADDITION_SHA,'exact346 addition');raw=raw[-size:]
  exact(sha(raw),digest,'accepted345 bytes '+relative);history[relative]=raw
 exact(len(history),1692,'all accepted source files')
 validate_return(load('-checkpoint-confirmation.json'),load('-step345-user-acceptance.json'),policy)
 validate_mapping(load('-phase-map.json'),load('-contract.json'),history)
 ast.parse(safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-auditor.py').read_text())
 return history

def main(argv):
 if argv==['--help']:print('Repository-only pure bootstrap guard model review: --check REPOSITORY');return 0
 if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
 try:verify(argv[1])
 except (ValueError,KeyError,TypeError,OSError) as error:print('ERROR: '+str(error),file=sys.stderr);return 1
 print('step346_pure_whole_sequence_audit_review_status\tPASS');print('runtime_authority\tno');print('native_cases_run\t0');print('native_proofs_added\t0');return 0
if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
