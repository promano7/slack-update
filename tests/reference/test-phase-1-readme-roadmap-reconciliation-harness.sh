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
import re
import runpy
import sys

root=Path(sys.argv[1]);name='phase-1-readme-roadmap-reconciliation';prior='phase-1-operational-source-native-gap-reconciliation'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(name+'.py');m=runpy.run_path(str(tool));passes=0
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError,OSError):return True
    return False
def load(tail):return json.loads((fixture/(name+'-'+tail+'.json')).read_bytes())
policy=load('policy');confirmed=load('confirmed366');receipt=load('step366-user-acceptance');stored=load('reconciliation')
check('all1866 accepted366 bindings retained',len(policy['baseline_sha256'])==policy['accepted_source_count']==1866)
history={}
for rel,digest in policy['baseline_sha256'].items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size_bytes']:]
    elif rel=='README.md':raw=stored['accepted_readme_preimage_text'].encode('utf-8')
    if sha(raw)!=digest:raise ValueError('accepted source drift: '+rel)
    history[rel]=raw
check('all accepted366 bytes exact except bounded README and additive CHANGELOG',len(history)==1866)
check('external confirmed366 bytes exact',sha((fixture/(name+'-confirmed366.json')).read_bytes())==policy['expected_confirmation_sha256'])
check('complete366 receipt and report-based confirmation validate',m['validate_acceptance'](receipt,confirmed))
text=receipt['text'];raw=text.encode();message=policy['accepted_commit_message'];head='8963dca (HEAD -> main, origin/main, origin/HEAD) '+message
check('all129 exact ordered366 labels and zero-failure summary',[s for s in text.splitlines() if s.startswith('PASS: ')]==policy['expected_ordered366_labels'] and text.count('Result: PASS (129 passes, 0 failures)')==1)
check('reported366 exact eight-file commit and seven created paths',text.count('[main 8963dca] '+message)==1 and text.count('8 files changed, 3784 insertions(+)')==1 and re.findall(r'^ create mode 100644 (.+)$',text,re.M)==policy['accepted_step366_created_paths'])
check('reported366 push clean status and matching heads',text.count('bede6fa..8963dca  main -> main')==1 and text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'))
check('receipt SHA size and original-capture limitation retained',sha(raw)==policy['accepted_receipt_sha256']==receipt['sha256'] and len(raw)==policy['accepted_receipt_size_bytes']==receipt['size_bytes'] and receipt['capture_basis']=='complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture' and receipt['normalization']=='none')
check('accepted366 is not a new pause or invented full commit',confirmed['commit_prefix']=='8963dca' and confirmed['commit_full'] is None and not confirmed['strong_safe_pause'] and confirmed['last_confirmed_strong_safe_pause_step']==358)
for field,value in [('strong_safe_pause',True),('commit_full','8963dca'+'0'*33),('runtime_authority',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('native_cases_run',1),('native_proofs_added',1),('user_worktree_clean',False),('user_head_matches_origin',False),('phase1_matrix_complete',True),('kernel_package_edge_complete',True),('production_entry_closed',False),('phase2_open',True)]:
    bad=copy.deepcopy(confirmed);bad[field]=value;check('reject changed366 confirmation '+field,rejected(m['validate_acceptance'],receipt,bad))
for label,edit in [('truncated receipt',lambda x:x[:-1]),('same-length edited receipt',lambda x:x.replace('8963dca','8963dcb',1)),('injected status output',lambda x:x.replace(head,' M README.md\n'+head,1))]:
    bad=copy.deepcopy(receipt);bad['text']=edit(text);check('reject '+label,rejected(m['validate_acceptance'],bad,confirmed))
bad=copy.deepcopy(receipt);bad['capture_basis']='original-terminal-byte-capture';check('reject invented original terminal capture',rejected(m['validate_acceptance'],bad,confirmed))
before=stored['accepted_readme_preimage_text'].encode('utf-8');after=(root/'README.md').read_bytes();support={path:history[path] for path in policy['support_sha256']}
check('complete accepted README preimage exact',sha(before)==policy['readme_before_sha256']==policy['baseline_sha256']['README.md']==m['README_BEFORE_SHA'])
check('complete reconciled README result exact',sha(after)==policy['readme_after_sha256']==m['README_AFTER_SHA'] and after==m['reconciled_readme'](before,support))
check('full stored reconciliation reproduced',m['validate_record'](stored,before,after,support) and sha((fixture/(name+'-reconciliation.json')).read_bytes())==policy['expected_reconciliation_sha256'])
check('all20 supporting source byte bindings exact',len(support)==20 and policy['support_sha256']==m['SUPPORT_HASHES'] and all(sha(raw)==policy['support_sha256'][path] for path,raw in support.items()))
check('all27 finite README patch operations retained exactly',len(m['PATCHES'])==policy['expected_patch_operations']==27 and stored['patch_operations']==m['PATCHES'] and all(p['occurrences']==1 and all(path in support for path in p['supporting_paths']) for p in m['PATCHES']))
# Apply the written exact operations independently without the reviewer's helper.
independent=before.decode('utf-8')
for p in stored['patch_operations']:
    check('exact README patch preimage '+p['id'],independent.count(p['old'])==p['occurrences'])
    independent=independent.replace(p['old'],p['new'])
check('independent ordered patch reproduction equals full README',independent.encode()==after)
text_after=after.decode();prefix='tests/fixtures/reference/acceptance/';phase=prefix+'phase-1/'
def tsv(path):return dict(line.split('\t',1) for line in support[path].decode().splitlines()[1:] if line)
comments=tsv(phase+'phase-1-reference-comment-language-remediation-closure-review.tsv');modes=tsv(phase+'configuration-module-mode-workstream-closure-checkpoint.tsv');execution=tsv(phase+'phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv')
check('comment-language historical closure supports exact checkbox',comments['workstream_closed']=='yes' and comments['reaudit_language_defects']=='0' and comments['reaudit_conformance_pass']=='yes' and '- [x] Close the English-comment remediation (step 169)' in text_after)
check('module modes closure preserves mandatory-target accepted historical scope',modes['module_mode_workstream_closed']=='true' and modes['mandatory_targets_accepted']=='true' and modes['conforming_rows']=='15' and modes['pending_module_mode_action']=='false' and 'including runtime validation on both mandatory targets' in text_after)
check('execution control closure supports all4 historical matrix entries',execution['network_failure']=='PASS' and execution['simultaneous_execution']=='PASS' and execution['signal_SIGINT']=='PASS:130' and execution['signal_SIGTERM']=='PASS:143' and execution['signal_SIGHUP']=='PASS:129' and execution['cron_without_interactive_terminal']=='PASS' and execution['acceptance_matrix_complete']=='no')
check('execution accepted VM scope never promoted to all52 native cases','Step 188 closed its four execution-control scenarios\nin the recorded Slackware-current VM runtime scope' in text_after and 'this does not prove the later\n52 two-platform operational cases' in text_after)
payload=json.loads(support[prefix+'normal-update/slackware-current-userspace-payload-review-20260805-accepted.json']);scripts=json.loads(support[prefix+'normal-update/slackware-current-userspace-maintainer-script-review-20260805-accepted.json']);config=json.loads(support[prefix+'normal-update/slackware-current-userspace-configuration-service-review-20260805-accepted.json'])
check('68 payload and37 script closure fields actually accepted',payload['accepted'] and payload['inspected_package_count']==68 and payload['doinst_script_count']==37 and scripts['accepted'] and scripts['maintainer_scripts_review_complete'] and config['accepted'] and config['configuration_service_review_complete'])
ready=json.loads(support[prefix+'normal-update/slackware-current-kernel-transaction-readiness-20260805-accepted.json']);reboot=json.loads(support[prefix+'normal-update/slackware-current-kernel-post-reboot-verification-20260805-accepted.json'])
check('historical readiness and reboot evidence support completed chain',ready['accepted'] and ready['apply_ready'] and ready['candidate_count']==137 and reboot['accepted'] and reboot['package_transaction_completed'] and reboot['reboot_verified'] and not reboot['mandatory_work_remaining'])
retention=json.loads(support[prefix+'kernel-boot/slackware-15.0-elilo-oldkernel-retention-preflight-20260811-accepted.json']);elilo=json.loads(support[prefix+'kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json'])
check('mature ELILO eligibility and consumed cleanup closure support updates',retention['cleanup_eligible'] and retention['status']=='accepted-mature-retention' and elilo['accepted'] and elilo['cleanup_scenario_closed'] and elilo['historical_authorizations_consumed'] and not elilo['pending_destructive_action'] and not elilo['machine_action_required'])
old=json.loads(support[prefix+'normal-update/slackware-current-apply-reviewed.json'])
check('original ten-package diagnostic never relabelled accepted',old['accepted'] is False and old['reference_revalidation_required'] is True and not stored['historical_diagnostics_relabelled_accepted'] and 'original\nten-package `.new` record remains diagnostic' in text_after and all(p['disposition']=='superseded-historical-follow-up' for p in m['PATCHES'] if p['id'].startswith('new-policy-')))
residual=support[policy['residual_inventory_path']].decode();residual_rows=[line.split('\t') for line in residual.splitlines()[1:] if line]
check('exact5-family20-scenario residual inventory carried',stored['residual_inventory188_exact_text']==residual and len(residual_rows)==5 and [int(x[1]) for x in residual_rows]==[1,7,6,3,3] and sum(int(x[1]) for x in residual_rows)==20)
matrix=text_after.split('### Real-system acceptance matrix\n',1)[1].split('### Reference freeze\n',1)[0];pending=[line for line in matrix.splitlines() if line.startswith('- [ ] ')]
check('exact20 remaining top-level matrix scenarios stay unchecked',len(pending)==20 and any('Kernel headers update without a kernel image update' in x for x in pending) and sum('GRUB' in x for x in pending)>=3)
check('reference v1 schema and C completion gates unchanged',before.decode().split('### Reference freeze\n',1)[1].split('## Phase 2',1)[0]==text_after.split('### Reference freeze\n',1)[1].split('## Phase 2',1)[0] and '- [ ] Define the version 1 JSON result schema.' in text_after and '- [ ] Mark the script behavior as `reference-v1`.' in text_after and '- [ ] First C milestone started' in text_after)
check('Phase2 architecture checklist preserved byte-for-byte',before.decode().split('## Phase 2',1)[1].split('## Immediate next steps',1)[0]==text_after.split('## Phase 2',1)[1].split('## Immediate next steps',1)[0])
start='<!-- step-120-configuration-compatibility-checkpoint:start -->';end='<!-- step-120-configuration-compatibility-checkpoint:end -->'
check('exact historical checkpoint120 body retained with later161 supersession',before.decode().split(start)[1].split(end)[0]==text_after.split(start)[1].split(end)[0] and 'then-deferred module-mode migration was subsequently closed at step 161' in text_after and 'previous substantive reconciliation was **173**' in text_after)
check('accepted rollback92 and ELILO116 summaries remain exact',before.decode().split('## Accepted Slackware-current rollback closure',1)[1].split('## Goals',1)[0]==text_after.split('## Accepted Slackware-current rollback closure',1)[1].split('## Goals',1)[0])
check('misleading current ELILO continuations relabelled historical','## Current ELILO oldkernel cleanup continuation' not in text_after and all('## Historical ELILO oldkernel cleanup continuation — step '+str(s) in text_after for s in [102,103]))
check('check and dry-run local effects are explicit without source changes','local state/log writes remain source-described effects' in text_after and 'Their names do not prove an\nabsence of effects' in text_after and stored['change_class']=='README-documentation-only-no-runtime-source-change')
for match in re.finditer(r'\]\(([^)]+)\)',text_after.split('<!-- step-367-readme-roadmap-reconciliation:start -->')[1].split('<!-- step-367-readme-roadmap-reconciliation:end -->')[0]):
    rel=match.group(1);check('new README relative link resolves '+rel,(root/rel).is_file() and rel in history)
gap=json.loads(support[policy['native_gap_path']]);check('full16 native gap rows exact and unselected',stored['full_native_gap_rows348']==gap['full_original_native_gap_rows348'] and len(stored['full_native_gap_rows348'])==16 and all(x['status']=='required-not-selected-refined-or-proven' for x in stored['full_native_gap_rows348']))
check('full46 proof52 case12 raw rows preserved without promotion',stored['full_qualified_proof_rows347']==gap['full_normative_rows']['qualified_proof_reconciliation'] and stored['full_native_case_rows347']==gap['full_normative_rows']['native_case_templates'] and stored['full_independent_raw_groups335']==gap['full_original_evidence_group_rows335'] and all(x['status']=='required-not-run' for x in stored['full_native_case_rows347']))
check('whole native contract and source reconciliation input hashes exact',m['canonical'](gap)==stored['full_native_contract_input_canonical_sha256']==policy['native_gap_canonical_sha256'] and m['canonical'](json.loads(support[policy['reconciliation366_path']]))==stored['full_source_reconciliation366_canonical_sha256']==policy['reconciliation366_canonical_sha256'])
check('README368 conditional next step never a premature pause',stored['next_step']==368 and not stored['automatic369'] and not stored['current_step_strong_safe_pause'] and 'last confirmed scoped pause is **358**' in text_after and 'no automatic\n369' in text_after)
for label,mutate in [('omitted patch',lambda x:x['patch_operations'].pop()),('changed patch disposition',lambda x:x['patch_operations'][0].__setitem__('disposition','native-closure')),('changed README SHA',lambda x:x.__setitem__('readme_after_sha256','0'*64)),('edited preimage',lambda x:x.__setitem__('accepted_readme_preimage_text',x['accepted_readme_preimage_text']+'x')),('deleted native gap',lambda x:x['full_native_gap_rows348'].pop()),('deleted native proof',lambda x:x['full_qualified_proof_rows347'].pop()),('deleted native case',lambda x:x['full_native_case_rows347'].pop()),('deleted raw group',lambda x:x['full_independent_raw_groups335'].pop()),('residual inventory shortened',lambda x:x.__setitem__('residual_inventory188_exact_text','summary')),('new runtime source change',lambda x:x.__setitem__('change_class','runtime-source-change')),('historical diagnostic promoted',lambda x:x.__setitem__('historical_diagnostics_relabelled_accepted',True)),('native runner invented',lambda x:x.__setitem__('runner',{}))]:
    bad=copy.deepcopy(stored);mutate(bad);check('reject '+label,rejected(m['validate_record'],bad,before,after,support))
for field in ['phase1_matrix_complete','reference_v1_frozen','version1_schema_frozen','C_port_open','phase2_open','production_open','current_step_strong_safe_pause','automatic369','historical_authority_reused','source_review_is_native_proof']:
    bad=copy.deepcopy(stored);bad[field]=True;check('reject false documentation completion '+field,rejected(m['validate_record'],bad,before,after,support))
for field,value in [('native_graph_complete',True),('execution_authorized',True),('runtime_authority',True),('actual_successor_selected',True),('actual_live_bindings',{}),('actual_host_state','absent'),('actual_global_host_closure',True),('native_cases_run',1),('readme_reconciled',False),('strong_safe_pause',True)]:
    bad=copy.deepcopy(stored);bad['boundaries'][field]=value;check('reject false boundary '+field,rejected(m['validate_record'],bad,before,after,support))
for path in support:
    bad=dict(support);bad[path]=bad[path]+b'X';check('reject supporting source drift '+path,rejected(m['reconciled_readme'],before,bad))
bad=dict(support);bad.pop(next(iter(bad)));check('reject missing supporting source',rejected(m['reconciled_readme'],before,bad))
bad=dict(support);bad['../outside']=b'x';check('reject unapproved extra support path',rejected(m['reconciled_readme'],before,bad))
check('reject accepted README preimage drift',rejected(m['reconciled_readme'],before+b'X',support))
check('reject reconciled README result drift',rejected(m['reconciliation_record'],before,after+b'X',support))
mutated=m['reconciliation_record'](before,after,support);mutated['boundaries']['runtime_authority']=True;mutated['patch_operations'][0]['supporting_paths'].clear();mutated['full_native_case_rows347'][0]['status']='passed';mutated['full_support_source_hashes'].clear()
check('returned record detached from module constants and normative source data',not m['BOUNDARIES']['runtime_authority'] and len(m['PATCHES'][0]['supporting_paths'])==6 and len(m['SUPPORT_HASHES'])==20 and m['reconciliation_record'](before,after,support)==stored)
ast_tree=ast.parse(tool.read_text());imports={alias.name for node in ast.walk(ast_tree) if isinstance(node,ast.Import) for alias in node.names}
check('pure documentation validator imports only hashlib json and re',imports=={'hashlib','json','re'})
check('validator has no filesystem lookup execution decode or spawn entry',not any(isinstance(node,ast.Call) and ((isinstance(node.func,ast.Name) and node.func.id in {'open','exec','eval','compile','__import__'}) or (isinstance(node.func,ast.Attribute) and node.func.attr in {'system','popen','run','which','b64decode','execv','spawnv','read_bytes','read_text','stat','resolve'})) for node in ast.walk(ast_tree)))
old_coverage=json.loads(history['tests/fixtures/reference/acceptance/phase-1/phase-1-operational-readonly-source-inventory-control-coverage.json'])
check('historical361 modeled socket limitation preserved',not old_coverage['native_proof'] and any('socket-type-stat-metadata-modeled' in x.get('method','') for x in old_coverage['controls']))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
