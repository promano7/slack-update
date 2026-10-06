#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only failure refinement mapping and gap review; no shell sourcing or runtime dispatch.\n' "${0##*/}"
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
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1584 manifest')
    exact(len(bindings),1584,'accepted1584 count')
    history={}
    for rel,digest in bindings.items():
        raw=safe_file(root,rel)
        if rel=='CHANGELOG.md':
            prefix=CHANGELOG_PREFIX.encode()
            exact(raw[:len(prefix)].hex(),prefix.hex(),'334 CHANGELOG prefix')
            exact(len(raw),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            raw=raw[len(prefix):]
        exact(sha(raw),digest,'accepted artifact drift '+rel);history[rel]=raw
    return history
def validate_confirmation(c,r):
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed333 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original333 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),1400,'complete1400 return')
    exact(lines.count('Result: PASS (1400 passes, 0 failures)'),1,'1400 summary')
    return True
def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step333-exact333-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=1400 or lines.count('Result: PASS (1400 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact1400 predecessor acceptance failed')
        return result.stdout
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = '7b782eb2383534e54f9f73fb2ff0d2338fd5f7df344c8a54e4f48b82427515dd'
CHANGELOG_PREFIX = '## Phase 1 step334 — failure refinement mapping and gaps — 2026-10-06\n\n- Confirmed step333 at prefix f648885 from complete ordered 1400 PASS identical to prepared/installed, successful first push, clean tree and matching HEAD/origin. Original return and external confirmation retained; full object ID unknown. Prepared step333 flags and prior history unchanged. Step328 remains the last confirmed strong pause.\n- Preserve all 1584 accepted files except additive CHANGELOG; nine new repository artifacts. Rerun exact 1400 predecessor and full nested history. Select successor-inert-failure-refinement-obligations-v1 as data only: 31 inherited macro events cross-index 25 distinct candidate phases via 32 links; readonly preflight and irreversible forward-stop remain two explicit candidate boundaries without standalone legacy events. No split/merge implies native equivalence.\n- Record 81 before/within/after macro-cut obligations for all 27 candidate boundaries, nine exact source322 owned stage7 microstep obligations, all 23 inherited hazards/eight forbidden actions and 16 native component/refinement gap requirements. Preserve exact source326 2938 finite declared families, raw statuses, budget/horizon and model contract; no syscall/crash/concurrency completeness, native injection site or writer-lifetime proof selected.\n- Unknown owned binding retains artifacts/no replay and may leave separately reviewable independently known-safe original target verification; unknown target/control forbids all restore/verification eligibility despite optimistic flags. Publication uncertainty stays pending with no target refresh/grant/restoration/republication. Raw status alone never proves no additional effect; private raw status retained, full native status/effect vector still required.\n- Separate inert review gates require known forward stop/original live recovery rights/original phase/identity/safe boot/baseline/earlier-target outcome, continuous guard/known-child quiescence/original finite live fence/deadline/durable pre-spent budget. Backed restoration needs verified original backups; independently unchanged verification needs no target writes or never-created backups. No automatic recovery, replay, guard reacquire, rebind, renewal or native authority from private eligibility.\n- All eight step320–327 source views, 30 domains/95 macro relations/27 phases/26 interfaces/35 types, 13 historical stages/nine windows/seven capabilities/ten cross obligations/46 unproven proofs/52 independent cases unrun remain exact. No native entry/graph/refinement/component/fault schedule/ABI/writer/storage/time/oracle selected or proven. Host unobserved, never absent/globally closed; no machine/controller cleanup. Step335 oracle scaffolding follows complete step334 return; step338 scoped conditional candidate pause remains target, runtime/production/Phase2 closed and Phase1/kernel incomplete.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review.md': 'bf2b37bc78a23cdfe17f4ea894cdfe408e3d310dbb2990ee485dd07f73b3e191', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-policy.json': 'f61a129b879fa9078d861ae0366393f2fe72ea781799d45f65e99b4c3d7fc449', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-refinement.json': '7fd2c6b0c35f5a6ef86504debac0b9e2dd2cae358496bfee60889209abe4f87c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-private-dispositions.json': '73c8b739a47054a7715bf3573c2cf4380e1603930d4f75342866d4ff69a7e0a4', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-checkpoint-confirmation.json': '9d5ab661b885a62745bf54f37db3a27b84ae468d9d1a442537c4fb7a6cc43458', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-step333-user-acceptance.json': '9940770389d70bc4bfa212294f2095fdd7192b2f6333c62c6ad402db079fa143', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-native-gap-register.tsv': '33e3e5dc8d5d1ce0b93a833a577ada9524a22018510b6c907a5667c5a8c6ee98'}
CONFIRMATION_SHA256 = '9d5ab661b885a62745bf54f37db3a27b84ae468d9d1a442537c4fb7a6cc43458'
RECEIPT_SHA256 = '4497dbf1eea47471afffadc7eaab30f0b700f4eb94f45c0639f50772b1353a3f'
RECEIPT_SIZE = 108239
MANIFEST_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-manifest.json'
LEGACY_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-complete-finite-failure-model-and-independent-conformance-plan-review-design.json'
# Inert fault refinement obligations, not a native fault model or recovery engine.
LEGACY_PHASES={
 'service-own-failure-barrier':['service-barrier-authentication'],
 'authenticate-original-context':['service-barrier-authentication'],
 'consume-original-grant':['service-original-durable-claim'],
 'spend-launch-slot':['service-durable-launch-spend'],
 'launch-one-worker':['service-single-worker-spawn'],
 'stage0-offline-bootstrap':['worker0-bounded-auth-read'],
 'stage0-close-unreviewed-capabilities':['worker0-close-bootstrap'],
 'stage1-arm-traps':['worker1-arm-traps'],
 'outer-guard-and-fresh-original':['interstage1-2-guard-freshoriginal'],
 'stage2-owned-work':['worker2-owned-workspace'],
 'stage3-verify-original-backups':['worker3-original-backups'],
 'stage4-exact-predecessor':['worker4-exact-predecessor'],
 'stage5-local-isolation':['worker5-local-isolation'],
 'stage6-refresh-bind-raw-pin':['worker6-refresh-pin-once'],
 'stage7-owned-binding':['worker7-validate-pinned-candidate','worker7-owned-durable-commit'],
 'reference-reviewed-owned-preparation':['worker8-whole-successor-apply'],
 'nested-update-same-raw-pin':['worker8-whole-successor-apply'],
 'nested-install-new-empty':['worker8-whole-successor-apply'],
 'nested-upgrade-one-target':['worker8-whole-successor-apply'],
 'reference-reviewed-owned-final-snapshots':['worker8-whole-successor-apply'],
 'drain-owned-children':['drain-known-owned-children'],
 'restore-original-if-changed':['worker9-original-restoration'],
 'verify-original':['worker10-original-verification'],
 'close-target-evidence':['worker11-close-target-evidence'],
 'release-target-control':['release-target-control'],
 'publication-controls-bound':['worker12-publication-controls'],
 'write-record-no-replace':['worker12-publication-record'],
 'record-durability-confirmed':['worker12-publication-record'],
 'write-last-receipt-no-replace':['worker12-last-receipt'],
 'last-receipt-durability-confirmed':['worker12-last-receipt'],
 'handoff-complete':['worker12-durable-handoff'],
}
NATIVE_REFINEMENT_REQUIREMENTS=[
 'Select full actual successor entry and every transitive writer/helper/effect; map native events to all declared phases without omitting reference preparation/nested calls/final snapshots.',
 'Bind actual issuer/principal/key/epoch/authentication and malformed/lost handoff observations independently; private context tags are not credentials.',
 'Prove concurrent/restart durable linearizable original claim and lost-ACK quarantine; never reset consumed/uncertain state.',
 'Prove one durable launch pre-spend, exact single spawn and bounded all-owned-child supervision; unknown spend/spawn cannot be retried.',
 'Prove bounded canonical offline memory/FD close and whole namespace/process containment on all paths; no worker broker/RPC/service capability.',
 'Bind trusted time and separate original live forward/recovery/publication fences continuously, with in-flight effects and revocation uncertainty observed.',
 'Prove native writer/object/alias/lifetime exclusion continuously from fresh original capture through known release; no guard reacquire on loss.',
 'Prove fresh original memory baseline after traps/guard before owned2, exact backups3/approved deltas and immutable original raw pkglist pin through consumers/restoration audit.',
 'Refine every owned intent/staging/bytes/metadata/data/no-replace/directory-durability/exit-evidence cut and child drain; unknown owned binding is distinct from unknown target.',
 'Bind real versioned backend/full selectors/raw full status vectors/sticky latch and independently observed intended/no-op/unexpected effects, not generic exit0 or three emulator calls.',
 'Prove checked-to-used source/archive/interpreter/helper/pkgtools/install-hook closure and prohibit boot/GenInitrd/optional/unresolved effects across the complete graph.',
 'Refine irreversible forward stop, retained original finite deadline and durable pre-spent budget, known original identity/phase/guard/children/outcomes, backed restoration or independently unchanged verification.',
 'Independently capture full original invariant verification/known-child closure/target evidence before release; no later target refresh/rebind/write/new grant.',
 'Refine separate captured-data publication controls/no-replace record/final receipt storage durability, trusted origin and handoff; no pair atomicity/selfreceipt/uncertain republish.',
 'Construct independent syscall/storage/crash/signal/restart/concurrency refinement including every actual micro-event, denied/in-flight effect and helper lifetime; 31 macro events/2938 declared families are not universal schedules.',
 'Bind separate native two-platform implementation/versions/boot/source/attempt/fresh test authority and independent raw oracle/positive-negative controls; all52 cases still unrun.',
]
FAULT_GATES=['forward_stopped','original_recovery_rights_live','phase_within_original_expectation','same_original_attempt','same_safe_boot_identity','original_baseline_known','earlier_target_outcome_known',
             'continuous_guard_valid','known_children_quiescent','original_recovery_fence_live','finite_original_deadline_valid',
             'original_budget_durably_prespent','verified_original_backups','independently_unchanged_target']

def build_failure_refinement(history,manifest,legacy):
    boundaries=[r['declared_boundary'] for r in manifest['phases']]
    phases={r['id']:r for r in boundaries};legacy_rows=[]
    for window in ['forward','recovery','publication']:
        for event in legacy['model_domains'][window]:
            legacy_rows.append(dict(legacy_event=event,legacy_window=window,candidate_phase_ids=LEGACY_PHASES[event],
                                    relation='declarative-split-or-merge-cross-index-not-equivalence-proof',
                                    status='native-refinement-required-not-proven',actual_native_events=None,actual_evidence=None))
    mapped={p for r in legacy_rows for p in r['candidate_phase_ids']}
    cuts=[]
    for phase in boundaries:
        for location in ['before-declared-operation','within-declared-operation','after-declared-operation']:
            cuts.append(dict(id=phase['id']+'/'+location,phase_id=phase['id'],caller_actor=phase['actor'],rights_window=phase['rights_window'],
                             location=location,scope='macro-cut-obligation-not-selected-native-injection-site',
                             required_future_proofs=sorted({p for c in manifest['components'] if phase['id'] in c['phase_ids'] for p in c['required_future_proofs']}),
                             actual_instruction_or_syscall=None,actual_writer_lifetimes=None,actual_fault_schedule=None,
                             actual_independent_oracle=None,status='required-not-refined',runtime_authorized=False))
    return dict(schema=1,step=334,scope='repository-failure-refinement-mapping-and-gap-review-only',
                selected_candidate_version='successor-inert-failure-refinement-obligations-v1',
                manifest_binding=dict(path=MANIFEST_PATH,sha256=sha(history[MANIFEST_PATH])),
                legacy_model_binding=dict(path=LEGACY_PATH,sha256=sha(history[LEGACY_PATH])),
                legacy_model_domains=legacy['model_domains'],legacy_model_coverage=legacy['model_coverage'],legacy_model_contract=legacy['model_contract'],
                legacy_to_candidate=legacy_rows,
                unmatched_explicit_legacy_boundaries=[dict(phase_id=p,status='explicit-candidate-boundary-not-standalone-legacy-event',
                                                         obligation='Preserve accepted331 boundary; add actual native refinement. No synthetic old event or waived side condition.',actual_evidence=None) for p in phases if p not in mapped],
                candidate_boundary_cuts=cuts,
                stage7_owned_microstep_obligations=[dict(position=i,source_step=step,status='required-not-native-refined',actual_instruction_or_syscall=None,
                                                        actual_durability_evidence=None,no_unknown_replay=True) for i,step in enumerate(manifest['exact_phase_contract']['stage7_owned_commit_sequence'])],
                hazard_register=[dict(id=h,status='native-applicability-and-inflight-lifetime-review-required',actual_injection_site=None,actual_evidence=None) for h in legacy['model_domains']['hazards']],
                forbidden_actions=legacy['model_domains']['forbidden'],
                native_gap_register=[dict(inherited_gap=g,refinement_requirement=NATIVE_REFINEMENT_REQUIREMENTS[i],
                                          status='required-not-selected-refined-or-proven',actual_model_or_component=None,
                                          actual_native_event_relation=None,actual_independent_evidence=None) for i,g in enumerate(manifest['actual_selection_gaps'])],
                qualified_proof_register=manifest['qualified_proof_register'],independent_platform_cases=manifest['independent_platform_cases'],
                exact_phase_contract=manifest['exact_phase_contract'],
                fault_disposition_contract=dict(conditions=FAULT_GATES,unknown_owned_vs_target='Unknown owned-only outcome retains artifacts/no replay but may leave separately reviewable known-safe original target verification. Unknown target outcome blocks every restore/verification eligibility even if optimistic flags supplied.',
                                                publication='Publication uncertainty retains pending record/receipt/origin; no target refresh, grant, restoration or uncertainty replay.',
                                                known_failure='Raw failure or exit0 with failed selectors never alone proves no additional effect. Original raw fixture status retained, real full vector/oracle still required.',
                                                recovery='Separate inert review eligibility only after forward stop; all original identity/baseline/earlier-target/guard/child/fence/deadline/durable-pre-spend conditions known. Backed restore requires verified original backups; independently unchanged branch avoids target writes and never-created backups. Never automatic recovery or a new grant.'),
                actual_native_refinement_complete=False,actual_fault_schedules_selected=False,actual_native_graph_complete=False,
                actual_operational_conformance=False,operational_readiness=False,runtime_authority=False,
                actual_live_bindings=None,actual_host_state='unobserved-not-claimed-absent',actual_global_host_closure_asserted=False,
                machine_action_required=False,controller_action_required=False,historical_v2_or_reference_main_sourced_run=False,
                user_step334_checkpoint_confirmed=False,strong_safe_pause=False,last_confirmed_strong_safe_pause_step=328,
                next_stage='335-independent-oracle-scaffolding-after-complete334-return')

def validate_failure_refinement(value,history,manifest,legacy):
    exact(value,build_failure_refinement(history,manifest,legacy),'exact failure refinement source cuts gaps proof dispositions')
    exact(len(value['legacy_to_candidate']),31,'31 legacy macro events')
    exact(len(value['candidate_boundary_cuts']),81,'27 candidate boundaries three obligation cuts each')
    exact(len(value['stage7_owned_microstep_obligations']),9,'all nine source322 microstep obligations')
    exact([r['phase_id'] for r in value['unmatched_explicit_legacy_boundaries']],['worker0-readonly-preflight','stop-forward-irreversibly'],'two explicit unmatched legacy boundaries retained')
    phase_ids={r['declared_boundary']['id'] for r in manifest['phases']}
    if any(p not in phase_ids for r in value['legacy_to_candidate'] for p in r['candidate_phase_ids']):raise ValueError('unknown candidate phase')
    return True

def private_fault_record(phase,scope='owned-only',outcome='unknown'):
    return dict(origin='synthetic-private-fixture',scope='inert-fault-disposition-only',phase_id=phase['id'],caller_actor=phase['actor'],rights_window=phase['rights_window'],
                effect_scope=scope,outcome=outcome,raw_fixture_status=0 if outcome=='known-complete' else -1,
                conditions={k:True for k in FAULT_GATES})

def evaluate_private_fault_disposition(value,phase_contract):
    exact(sorted(value),['caller_actor','conditions','effect_scope','origin','outcome','phase_id','raw_fixture_status','rights_window','scope'],'closed private fault record')
    exact(value['origin'],'synthetic-private-fixture','private fault origin');exact(value['scope'],'inert-fault-disposition-only','private scope')
    matches=[r for r in phase_contract['entry_trace'] if r['id']==value['phase_id']]
    if len(matches)!=1:raise ValueError('unknown phase')
    phase=matches[0];exact(value['caller_actor'],phase['actor'],'phase actor');exact(value['rights_window'],phase['rights_window'],'original rights window')
    if value['effect_scope'] not in ['owned-only','target','control','publication']:raise ValueError('unknown effect scope')
    if value['outcome'] not in ['known-complete','known-failed','unknown','not-attempted']:raise ValueError('unknown outcome')
    raw=value['raw_fixture_status']
    if type(raw) is not int or raw not in [-1,0,1,2,20,128,137,143]:raise ValueError('single private raw status type/domain')
    if value['outcome']=='known-complete' and raw!=0:raise ValueError('known-complete fixture requires raw0')
    conditions=value['conditions'];exact(sorted(conditions),sorted(FAULT_GATES),'all separate original recovery gates')
    if any(type(v) is not bool for v in conditions.values()):raise ValueError('typed independent conditions')
    noncomplete=value['outcome']!='known-complete';unknown=value['outcome']=='unknown'
    publication=phase['rights_window']=='publication' or value['effect_scope']=='publication'
    target_unknown=unknown and value['effect_scope'] in ['target','control']
    common=all(conditions[k] for k in FAULT_GATES if k not in ['verified_original_backups','independently_unchanged_target'])
    eligible=noncomplete and common and not publication and not target_unknown
    verification=eligible and conditions['independently_unchanged_target']
    backed_restore=eligible and not conditions['independently_unchanged_target'] and conditions['verified_original_backups']
    return dict(model_forward_stop_required=noncomplete or phase['rights_window'] in ['recovery','publication'],
                model_original_raw_fixture_status=raw,model_raw_status_scope='single-private-status-not-real-full-vector-or-effect-proof',
                model_no_additional_effect_inferred=False,model_unknown_scope_pending=unknown,
                model_retained_owned_artifacts_required=unknown and value['effect_scope']=='owned-only',
                model_separate_original_verification_reviewable=verification,
                model_separate_backed_restoration_reviewable=backed_restore,
                model_never_created_backups_required_for_verification=False,
                model_automatic_recovery=False,model_unknown_action_replay_allowed=False,
                model_publication_pending=publication and noncomplete,
                model_target_refresh_after_release_allowed=False,
                actual_target_restored=False,actual_target_closure=False,actual_publication_closure=False,
                actual_new_grant=False,actual_fault_refinement_proven=False,actual_operational_conformance=False,
                actual_host_closure=False)


def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed334 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    policy=load('-policy.json');history=verify_history(root,policy);manifest=json.loads(history[MANIFEST_PATH]);legacy=json.loads(history[LEGACY_PATH])
    review=load('-refinement.json');validate_failure_refinement(review,history,manifest,legacy)
    dispositions=load('-private-dispositions.json')
    for example in dispositions['examples']:
        exact(example['actual_evidence'],None,'private example not native evidence')
        exact(example['result'],evaluate_private_fault_disposition(example['input'],review['exact_phase_contract']),'private fault disposition no native completion')
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step333-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-refinement.json','-private-dispositions.json','-checkpoint-confirmation.json','-step333-user-acceptance.json','-native-gap-register.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,policy).items()},{r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'334 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step333_acceptance\tPASS (1400 passes, 0 failures)')
    print('step334_failure_refinement_mapping_gap_review_status\tPASS')
    print('legacy_macro_events_candidate_phases_macro_cut_obligations\t31/27/81')
    print('actual_native_refinement_or_recovery_authorized\tno')
    print('required_proofs_and_independent_cases\t46-unproven/52-unrun')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user334-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)

PYREVIEW
