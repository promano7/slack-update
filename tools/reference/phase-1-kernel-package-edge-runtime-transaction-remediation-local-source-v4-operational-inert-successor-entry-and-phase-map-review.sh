#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only inert successor entry and phase map; no shell sourcing or runtime dispatch.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYREVIEW'
import ast
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
def encoded(value):return (json.dumps(value,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()
def sha(value):return hashlib.sha256(value).hexdigest()
def exact(actual,expected,label):
    if encoded(actual)!=encoded(expected):raise ValueError(label)
def safe_relative(rel):
    if type(rel) is not str or not rel or '\\' in rel or any(x in ('','.','..') for x in rel.split('/')):raise ValueError('unsafe relative path')
    return Path(rel)
def safe_file(root,rel):
    p=root/safe_relative(rel)
    if not p.is_file() or p.is_symlink() or p.absolute()!=p.resolve() or not p.resolve().is_relative_to(root.resolve()):raise ValueError('missing or unsafe file '+rel)
    return p.read_bytes()
def verify_history(root,policy):
    bindings=policy['baseline_sha256_bindings']
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1557 manifest')
    exact(len(bindings),1557,'accepted1557 count')
    history={}
    for rel,digest in bindings.items():
        raw=safe_file(root,rel)
        if rel=='CHANGELOG.md':
            prefix=CHANGELOG_PREFIX.encode()
            exact(raw[:len(prefix)].hex(),prefix.hex(),'330 CHANGELOG prefix')
            exact(len(raw),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            raw=raw[len(prefix):]
        exact(sha(raw),digest,'accepted artifact drift '+rel);history[rel]=raw
    return history
def validate_confirmation(c,r):
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed330 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original330 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),379,'complete379 return')
    exact(lines.count('Result: PASS (379 passes, 0 failures)'),1,'379 summary')
    return True
def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step330-exact330-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=379 or lines.count('Result: PASS (379 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact379 predecessor acceptance failed')
        return result.stdout
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = '775bda3b835c1031ba0baa98d572e301f0e6f741b19395b0e8158bf085b1b166'
CHANGELOG_PREFIX = '## Phase 1 step331 — inert successor entry and phase map — 2026-10-06\n\n- Confirmed330 at prefixea84ecf, complete ordered379 PASS identical to prepared/installed, first push successful, clean tree and matching HEAD/origin. Complete original user return and external confirmation retained; full object ID unknown. Prepared330 flags/history and its corrected private wrapper failure remain unchanged.328 remains last confirmed strong pause.\n- Preserve1557 accepted artifacts except additive CHANGELOG; nine new repository files. Rerun full exact379 predecessor with271/1320 and all nested history. Select successor-inert-entry-and-phase-map-v1 as data only:27 ordered service/worker/supervisor/publisher boundaries, all13 original worker stages/source statements unchanged, explicit successor stage7 owned commit, all30 domain mappings and46 qualified proof links.\n- Own service barrier/auth before irreversible original claim; durable single launch spend before one spawn; bounded offline workerstage0 auth/read/close/no ledger or owned writes; stage1 traps, then outerguard/freshoriginal in-memory before ownedstage2; stage3 verified same-original backups before predecessor/config/package effects. Preserve source321 bootstrap limits and no worker broker/service capability; original consumed attempt/boot/scopes throughout.\n- Stage7 splits read-only pinned candidate validation from source322 exact nine-step owned no-replace durable commit. Stage8 requires whole selected successor/reference-effect equivalence, full selectors/raw statuses/one original raw pin/sticky failure latch and unknown/forbidden-helper rejection; never substitute three private emulator calls for full main. Actual graph/entry/native implementation unselected/unproven, all domains still dispatch-blocked.\n- Close forward on normal completion or failure/expiry/revocation; retain same-attempt finite recovery only. Drain known owned children before safe original restore/fullverify/target evidence/release. Private restore branch requires exact verified backups and original phase/identity/continuous guard/fence/pre-spent budget; independent known-unchanged path verifies without target write or backups never created. Unknown prefix never automatically restores/replays/relaunches/reacquires/renews or claims closure; original failure preserved.\n- After target release, publication controls/record/last receipt/durable origin/handoff are separate and captured-data-only, no target write/refresh/new grant or republish on uncertainty. Finite private prefix-order and recovery-condition checks are not native effect/signal/crash/syscall refinement or actual conformance. Sixteen actual gaps, eight contracts/seven capabilities/ten obligations/nine windows/46 proofs/52 independent cases remain exact and pending.\n- No inspected source/reference main/frozenv2 run; no runtime/preflight/refresh/namespace/target/restore/operational publication or live authority. Actual host unobserved, never absent/globallyclosed; no new batch machine/controller cleanup.331 application/tests/commit/push pending;332 typed primitive interfaces after full331 return.338 conditional scoped candidate freeze/pause; production/Phase2 closed, Phase1/kernel incomplete.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review.md': 'e21683edfb7092792eb4da10ab2bda1f1aec5f809d6bc6b4c0eff3a4da0fff14', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-policy.json': '952fb149e3b53fc6c626bcea44659101d6a4dbe6b1d9a2eb029c2c2dc9295022', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-phase-map.json': '958654daa8617d95b6a742807e620fbf9f46d6bbbb5070623b19cde185c91098', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-checkpoint-confirmation.json': '6eb33d79ec7b9deddbcfa59ca6896ae1c69f0f30a8c8b673fcf727bd11321345', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-step330-user-acceptance.json': '95b7951ea8b7730e979460ffb9489135b1221fadaec7fe6fc3a9fd130388fb35', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-entry-trace.tsv': '8839e7230d5d2657f0288ee0f5df24dd29bd36fa7ede28e1dc5806ac861deff8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-domain-phase-map.tsv': 'ecf45576ce77ddb4d6896ad53d6ae7211ce6d5a99dafe048759703a5ff6dfcf4'}
CONFIRMATION_SHA256 = '6eb33d79ec7b9deddbcfa59ca6896ae1c69f0f30a8c8b673fcf727bd11321345'
RECEIPT_SHA256 = '87caf8824bfef04ba38b84162e971d8b6d76fbb27ef1623741641cfeb0e0b8ba'
RECEIPT_SIZE = 38115
FROZEN_WORKER = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze-freeze.json'
TRACE_LAYOUT=[
 ('service-barrier-authentication','service','policy',None,'service-own-barrier-auth-before-ledger-log-effects'),
 ('service-original-durable-claim','service','admission',None,'one-original-known-authenticated-unused-to-consumed-active'),
 ('service-durable-launch-spend','service','launch',None,'one-durable-slot-spend-before-single-spawn'),
 ('service-single-worker-spawn','service','launch',None,'one-known-spent-launch-no-retry-on-unknown'),
 ('worker0-bounded-auth-read','worker','bootstrap',0,'bounded-offline-memory-auth-read-no-owned-or-ledger-write'),
 ('worker0-close-bootstrap','worker','bootstrap',0,'read-FD-closed-on-every-path-no-writer-broker-service-capability'),
 ('worker0-readonly-preflight','worker','bootstrap',0,'same-original-consumed-attempt-early-observation-not-original-baseline'),
 ('worker1-arm-traps','worker','forward',1,'cleanup-and-child-supervision-before-lock-log-owned-effects'),
 ('interstage1-2-guard-freshoriginal','supervisor','forward',None,'continuous-native-exclusion-and-fresh-original-memory-capture'),
 ('worker2-owned-workspace','worker','forward',2,'individually-whitelisted-canonical-owned-paths-after-outer-guard'),
 ('worker3-original-backups','worker','forward',3,'persist-and-verify-same-original-bytes-metadata-presence-before-target'),
 ('worker4-exact-predecessor','worker','forward',4,'only-original-approved-target-predecessor-delta'),
 ('worker5-local-isolation','worker','forward',5,'only-original-approved-local-config-delta-no-external-fallback'),
 ('worker6-refresh-pin-once','worker','forward',6,'fresh-regular-nonempty-exit0-both-stream-guards-one-raw-SHA-pin'),
 ('worker7-validate-pinned-candidate','worker','forward',7,'read-only-exact-eight-field-original-context-raw-pin-validation'),
 ('worker7-owned-durable-commit','worker','forward',7,'explicit-successor-owned-intent-staging-no-replace-durability-stage-evidence'),
 ('worker8-whole-successor-apply','worker','forward',8,'complete-selected-successor-equivalence-required-not-three-argv-substitution'),
 ('stop-forward-irreversibly','supervisor','recovery',None,'normal-completion-or-failure-expiry-revocation-closes-forward'),
 ('drain-known-owned-children','supervisor','recovery',None,'bounded-original-retained-rights-known-quiescence-before-restore'),
 ('worker9-original-restoration','worker','recovery',9,'safe-same-original-identity-phase-guard-verified-backups-finite-rights'),
 ('worker10-original-verification','worker','recovery',10,'full-original-invariants-raw-audit-pin-not-rebound-no-further-consumer'),
 ('worker11-close-target-evidence','worker','recovery',11,'closed-captured-target-data-complete-before-target-release'),
 ('release-target-control','supervisor','recovery',None,'known-children-original-verify-target-evidence-before-release-no-target-write-refresh-after'),
 ('worker12-publication-controls','publisher','publication',12,'independent-owner-recipient-ancestry-alias-content-controls-captured-data-only'),
 ('worker12-publication-record','publisher','publication',12,'no-replace-file-metadata-directory-storage-durability-no-pairatomicity'),
 ('worker12-last-receipt','publisher','publication',12,'separate-trusted-origin-last-receipt-no-selfreceipt-no-target-grant'),
 ('worker12-durable-handoff','publisher','publication',12,'known-last-receipt-origin-durability-and-handoff-before-publication-rights-close'),
]
NODE_PHASES={
 'issuer-policy-and-key-provisioning':['service-barrier-authentication'],
 'durable-admission-claim':['service-original-durable-claim'],
 'durable-single-launch-slot':['service-durable-launch-spend','service-single-worker-spawn'],
 'offline-bootstrap-context':['worker0-bounded-auth-read','worker0-close-bootstrap'],
 'trusted-time-and-revocation-fence':[r[0] for r in TRACE_LAYOUT if r[2] in ['forward','recovery']],
 'worker-readonly-preflight':['worker0-readonly-preflight'],
 'worker-traps-and-child-control':['worker1-arm-traps','drain-known-owned-children'],
 'outer-writer-guard-and-original-baseline':['interstage1-2-guard-freshoriginal','release-target-control'],
 'owned-runtime-and-original-backups':['worker2-owned-workspace','worker3-original-backups'],
 'predecessor-and-local-isolation':['worker4-exact-predecessor','worker5-local-isolation','worker6-refresh-pin-once'],
 'stage7-owned-binding':['worker7-validate-pinned-candidate','worker7-owned-durable-commit'],
 'whole-reference-entry':['worker8-whole-successor-apply'],
 'reference-lock-runtime-logs':['worker8-whole-successor-apply'],
 'reference-snapshots-and-config-scan':['worker8-whole-successor-apply'],
 'reference-GenInitrd-mutation':[],
 'reference-optional-module-mutation':[],
 'reference-boot-mutation':[],
 'nested-call-adapter':['worker8-whole-successor-apply'],
 'real-backend-and-selector':['worker6-refresh-pin-once','worker8-whole-successor-apply'],
 'package-tools-and-install-hooks':['worker4-exact-predecessor','worker8-whole-successor-apply','worker9-original-restoration'],
 'source-and-archive-consumption':['worker0-readonly-preflight','worker4-exact-predecessor','worker6-refresh-pin-once','worker8-whole-successor-apply','worker9-original-restoration'],
 'interpreter-helper-dependency-consumption':[r[0] for r in TRACE_LAYOUT],
 'owned-child-quiescence':['drain-known-owned-children'],
 'same-attempt-original-restoration':['worker9-original-restoration'],
 'target-evidence-closure':['worker10-original-verification','worker11-close-target-evidence'],
 'target-control-release':['release-target-control'],
 'publication-controls':['worker12-publication-controls','worker12-durable-handoff'],
 'publication-record':['worker12-publication-record'],
 'publication-last-receipt':['worker12-last-receipt','worker12-durable-handoff'],
 'unresolved-dynamic-helpers-and-dependencies':[],
}
RECOVERY_FLAGS=['same_original_attempt','same_safe_boot_identity','forward_stopped','original_recovery_rights_live',
                'finite_deadline_valid','durable_budget_available','durable_budget_spent_before_action','recovery_fence_continuously_valid','guard_continuously_valid','known_child_quiescence',
                'original_baseline_known','phase_within_original_expectation','earlier_action_outcome_known',
                'verified_original_backups','independently_unchanged_target']

def build_phase_map(history,inventory,retained,frozen_worker):
    views=retained['frozen_contract_views'];rows=[]
    for index,(identifier,actor,rights,legacy,invariant) in enumerate(TRACE_LAYOUT):
        rows.append(dict(position=index,id=identifier,actor=actor,rights_window=rights,
                         historical_worker_stage_index=legacy,selected_inert_invariant=invariant,
                         original_attempt_relation='same-original-consumed-active-context-after-service-claim',
                         actual_implementation=None,actual_evidence=None,runtime_authorized=False))
    source_stages=frozen_worker['frozen_implementation_specification']['stages']
    return dict(schema=1,step=331,scope='repository-inert-successor-entry-and-phase-map-only',
                selected_candidate_version='successor-inert-entry-and-phase-map-v1',entry_trace=rows,
                continuous_controls=dict(original_forward_fence_phase_ids=[r['id'] for r in rows if r['rights_window']=='forward'],
                                         original_recovery_fence_phase_ids=[r['id'] for r in rows if r['rights_window']=='recovery'],
                                         separate_publication_rights_phase_ids=[r['id'] for r in rows if r['rights_window']=='publication'],
                                         native_guard_lifetime='interstage1-2-through-known-target-control-release-continuous-not-reacquired',
                                         interpreter_helper_consumption='all-service-bootstrap-worker-recovery-publication-phases-and-all-writers-lifetimes',
                                         worker_broker_or_service_channel='forbidden-also-for-live-fence-no-offline-receipt-revocation-proof'),
                frozen_worker_stage_order=frozen_worker['frozen_stage_order'],frozen_worker_stages=source_stages,
                frozen_worker_binding=dict(path=FROZEN_WORKER,sha256=sha(history[FROZEN_WORKER])),
                inherited_inventory_binding=dict(path=FIXTURE+'/'+PRIOR+'-inventory.json',sha256=sha(history[FIXTURE+'/'+PRIOR+'-inventory.json'])),
                preserved_integration_contract_bindings=retained['successor_contract_bindings'],
                selected_source_views={k:views[k] for k in ['320','321','322','323','324','325','326','327']},
                node_phase_map=[dict(id=n['id'],phase_ids=NODE_PHASES[n['id']],
                                     forbidden_or_unknown=n['classification']=='forbidden-or-unknown-domain',
                                     dispatch_blocked=True,actual_implementation=None,
                                     required_future_proofs=n['required_future_proofs']) for n in inventory['candidate_nodes']],
                stage7_owned_commit_sequence=views['322']['commit_contract']['sequence'],
                original_baseline_rule=views['324']['baseline_contract'],
                raw_pkglist_rule=views['324']['pkglist_contract'],
                nested_full_effect_rule=views['325']['graph_contract'],
                nested_argv_contract=views['325']['nested_argv_contract'],selector_contract=views['325']['selector_contract'],
                bootstrap_limits=views['321']['bootstrap'],
                retained_recovery_contract=views['323']['recovery_contract'],
                guarded_recovery_contract=views['324']['recovery_contract'],
                recovery_branch_gates=RECOVERY_FLAGS,
                recovery_modes=['restore-original-from-verified-backups','verify-independently-unchanged-without-target-write'],
                recovery_branch_rule='Failure never automatically restores. Only explicitly retained original finite rights with known original identity/phase/guard/children/outcomes permit a separately evaluated inert recovery suffix. Unknown action is never replayed. Verification-only path may omit backups that were never created when target independently unchanged.',
                publication_contract=views['325']['publication_contract'],
                publication_branch_rule='Release after original verification and captured target evidence. Publication has independent captured-data controls through last receipt durability/origin/handoff; no target revalidation/write/refresh or republish after unknown outcome.',
                failure_trace_scope='Finite declaration of ordered complete/failing prefixes only; not fault scheduling/native effects/syscall/crash refinement or real recovery/publication proof.',
                all_actual_selection_gaps=inventory['all_actual_selection_gaps'],
                inherited_counts=inventory['inherited_counts'],inherited_platform_cases=inventory['inherited_platform_cases'],
                actual_successor_entry_selected=False,actual_dynamic_graph_complete=False,
                actual_native_primitives_selected=False,actual_operational_implementation_frozen=False,
                operational_conformance=False,operational_readiness=False,runtime_authority=False,
                actual_live_bindings=None,actual_host_state='unobserved-not-claimed-absent',
                historical_v2_or_reference_main_sourced_run=False,machine_action_required=False,controller_action_required=False,
                user_step331_checkpoint_confirmed=False,strong_safe_pause=False,last_confirmed_strong_safe_pause_step=328,
                next_stage='332-typed-primitive-interfaces-after-complete331-return')

def validate_phase_map(value,history,inventory,retained,frozen_worker):
    exact(value,build_phase_map(history,inventory,retained,frozen_worker),'source-bound inert phase map and all pending native obligations')
    exact(len(value['entry_trace']),27,'27 inert boundaries')
    exact(len(value['node_phase_map']),30,'all30 domains')
    exact(len(value['frozen_worker_stages']),13,'13 frozen worker stages unchanged')
    indices=[r['historical_worker_stage_index'] for r in value['entry_trace'] if r['historical_worker_stage_index'] is not None]
    exact(sorted(set(indices)),list(range(13)),'all historical worker stage indices mapped')
    if indices!=sorted(indices):raise ValueError('worker stages reordered')
    for n in value['node_phase_map']:
        if n['forbidden_or_unknown'] and n['phase_ids']:raise ValueError('forbidden domain added to entry')
    return True

def evaluate_private_trace(value):
    exact(sorted(value),['events','origin','scope'],'private trace schema')
    exact(value['origin'],'synthetic-private-fixture','private origin')
    exact(value['scope'],'inert-order-and-attempt-context-only','private trace scope')
    events=value['events'];exact(len(events),len(TRACE_LAYOUT),'complete ordered declaration required')
    stopped=False;failure=None
    for row,layout in zip(events,TRACE_LAYOUT):
        exact(sorted(row),['actor','attempt','boot','id','outcome','rights_window'],'trace event schema')
        exact(row['id'],layout[0],'event order no replay/skip/insertion')
        exact(row['actor'],layout[1],'event actor no capability crossing')
        exact(row['rights_window'],layout[2],'event rights window no new nested grant')
        exact(row['attempt'],'original-attempt-A','same original consumed attempt')
        exact(row['boot'],'original-boot-A','same safe original boot')
        if row['outcome'] not in ['known-complete','known-failed','unknown','not-attempted']:raise ValueError('unknown outcome tag')
        if stopped and row['outcome']!='not-attempted':raise ValueError('later action after stop/unknown')
        if not stopped and row['outcome']!='known-complete':stopped=True;failure=row['id']
    claim=events[1]['outcome'];slot=events[2]['outcome']
    consumed='known-consumed' if claim=='known-complete' else 'quarantine-not-reusable' if claim in ['unknown','known-failed'] else 'not-observed-no-unused-claim'
    spent='known-spent' if slot=='known-complete' else 'quarantine-no-relaunch' if slot in ['unknown','known-failed'] else 'not-observed-no-reusable-slot-claim'
    return dict(model_declared_sequence_complete=not stopped,model_first_stop_boundary=failure,
                model_original_claim_state=consumed,model_original_launch_slot_state=spent,
                model_automatic_recovery=False,model_pending_prefix_obligations=stopped,
                actual_dispatch_authorized=False,actual_grant_issued=False,actual_grant_reused=False,
                actual_graph_or_native_effects_proven=False,actual_operational_conformance=False,
                actual_host_closure=False)

def evaluate_private_recovery(value):
    exact(sorted(value),['conditions','mode','origin','scope'],'recovery branch schema')
    exact(value['origin'],'synthetic-private-fixture','private recovery origin')
    exact(value['scope'],'retained-original-recovery-contract-only','private recovery scope')
    modes=['restore-original-from-verified-backups','verify-independently-unchanged-without-target-write']
    if value['mode'] not in modes:raise ValueError('unknown recovery mode')
    c=value['conditions'];exact(sorted(c),sorted(RECOVERY_FLAGS),'all recovery branch conditions')
    if any(type(x) is not bool for x in c.values()):raise ValueError('typed recovery flags')
    common=all(c[k] for k in RECOVERY_FLAGS if k not in ['verified_original_backups','independently_unchanged_target'])
    restore=value['mode']==modes[0]
    eligible=common and (c['verified_original_backups'] if restore else c['independently_unchanged_target'])
    return dict(model_retained_recovery_branch_eligible=eligible,
                model_target_restore_required=eligible and restore and not c['independently_unchanged_target'],
                model_verification_only=eligible and (not restore or c['independently_unchanged_target']),
                model_original_failure_preserved=True,
                actual_recovery_authorized=False,actual_new_grant_issued=False,
                actual_target_restored=False,actual_host_closure=False)


def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed331 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    policy=load('-policy.json');history=verify_history(root,policy)
    inventory=json.loads(history[FIXTURE+'/'+PRIOR+'-inventory.json'])
    retained=json.loads(history[inventory['inherited_obligations_binding']['path']])
    validate_phase_map(load('-phase-map.json'),history,inventory,retained,json.loads(history[FROZEN_WORKER]))
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step330-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-phase-map.json','-checkpoint-confirmation.json','-step330-user-acceptance.json','-entry-trace.tsv','-domain-phase-map.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,policy).items()},{r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'331 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step330_acceptance\tPASS (379 passes, 0 failures)')
    print('step331_inert_successor_entry_phase_map_status\tPASS')
    print('inert_boundaries_and_frozen_worker_stages\t27/13')
    print('actual_successor_entry_or_native_effects_proven\tno')
    print('actual_dispatch_or_publication_authorized\tno')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user331-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)

PYREVIEW
