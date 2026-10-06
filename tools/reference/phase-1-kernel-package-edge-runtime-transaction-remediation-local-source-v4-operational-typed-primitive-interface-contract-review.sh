#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only typed primitive interface contracts; no shell sourcing or runtime dispatch.\n' "${0##*/}"
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
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1566 manifest')
    exact(len(bindings),1566,'accepted1566 count')
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
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed331 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original331 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),399,'complete399 return')
    exact(lines.count('Result: PASS (399 passes, 0 failures)'),1,'399 summary')
    return True
def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step331-exact331-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=399 or lines.count('Result: PASS (399 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact399 predecessor acceptance failed')
        return result.stdout
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = '8e72e36f13c01eb87555ab3aaa0be44e1ead1db3f4000a38b9bb881b1816c9e1'
CHANGELOG_PREFIX = '## Phase 1 step332 — typed primitive interface contracts — 2026-10-06\n\n- Confirmed331 at prefix5bbdcaa, complete ordered399 PASS identical to prepared/installed, successful first push, clean tree and matching HEAD/origin. Original return/external confirmation retained; full object ID unknown and historical prepared331 flags unchanged.328 remains the last confirmed strong pause.\n- Preserve1566 accepted artifacts except additive CHANGELOG; nine new source artifacts. Full exact399 predecessor/all nested379/271/1320 coverage rerun. Select successor-inert-typed-interfaces-v1 as data:26 nominal interfaces across27 source-bound phase boundaries, four forbidden/unknown domains with no interface, closed typed inputs/outputs/provider-role/caller-phase-actor/rights-window and uncertainty rules. No actual native component or ABI selected.\n- Inherit the complete unchanged331 phase map,13 historical stages/eight320–327 source views/30 domains/95 design edges/nine windows/seven capabilities/ten obligations/all46 proof links/52 required-not-run independent cases and16 actual gaps. Actor/lifetime/linearity/evidence requirements are explicit; nominal tokens never prove authenticity, irreversible durable consumption, native guard/fence/time or runtime containment.\n- Preserve original barrier-before-claim/pre-spent-single-launch/bounded offline bootstrap/no broker capability; traps then continuous guard/freshoriginal before owned2/backups3; one raw pkglist pin; readonly validation plus source322 nine-step owned stage7 commit; full successor graph/nested argv/selectors/raw statuses/sticky failure latch and blocked boot/GenInitrd/optional/unknown effects.\n- Retain finite same-original recovery/known child drain/guard-fence/deadline/durable pre-spent budget/verified backups or independent unchanged verification without never-created backups. Target full original verification/evidence precedes release; publication captured-data-only/separate controls/last receipt durability-origin-handoff, no pairatomicity/selfreceipt/replay/refresh/new grant.\n- Private exchange checks typed symbolic original context and exact phase/provider/caller rights; failed/unknown/unattempted reports carry no success payload, actual evidence or authority. All private complete results still leave every native obligation pending. No dispatcher/adapter/source execution/syscall/capability minting or automatic recovery.333 candidate manifest validator follows complete332 return;338 conditional scoped candidate pause, runtime/production/Phase2 closed and Phase1/kernel incomplete. Host unobserved, never absent/globallyclosed.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review.md': 'a9c7589096dbd31216f85acd2d1f665092cb4d6b9bd0f778ee4ebf90da69a0e6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-policy.json': '5b7e6e5abef69855086aee762bfda81d64482d3ebe5fc12fa6808d84b9910a57', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-interfaces.json': 'a86782e26e1fa0aeb29e497f49207835223db7bf20866db5885d76a2343f3ce4', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-types.json': 'd3c56602f1fd3cb3395130db07810754fd3a6aee19a99641fbaca15d222a3b5f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-checkpoint-confirmation.json': 'f748310ffc7baeaab34f50bc3be88fbbfc21de811531bf4931a6122b5d3f767f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-step331-user-acceptance.json': '183f6644e5fbe356ce7df5af31da51793a232c8cdafd30b3b04d91e832682dc5', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-interface-proof-map.tsv': '528270121676a7136e42d83cf4dd493c788426df56ade29bcedeba74946ddebd'}
CONFIRMATION_SHA256 = 'f748310ffc7baeaab34f50bc3be88fbbfc21de811531bf4931a6122b5d3f767f'
RECEIPT_SHA256 = '1f8f736f9d4e347fd429aa2f8c46c4ba2f5b4d65b8fbaa8fe0f4a2142a7415f1'
RECEIPT_SIZE = 34015
PHASE_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-phase-map.json'
# Repository-only nominal interface contracts. No native adapters or dispatcher.
INTERFACE_LAYOUT = [
 ('issuer-policy-and-key-provisioning','issuer-policy-provider',['issuer-policy-view'],['authenticated-policy-view'],'Authenticate service-own barrier, issuer/principal/key provenance and exact original scopes before ledger/log effects; authentication is not admission.'),
 ('durable-admission-claim','admission-storage-provider',['authenticated-policy-view'],['consumed-original-context'],'Atomic durable linearizable original unused-to-consumed claim after own barrier; unknown persistence quarantines, never returns unused or permits retry.'),
 ('durable-single-launch-slot','launch-supervisor',['consumed-original-context'],['spent-launch-view'],'Persist one launch spend before one spawn. Unknown spend/spawn remains spent or quarantined; never relaunch or refund.'),
 ('offline-bootstrap-context','offline-handoff-provider',['consumed-original-context','spent-launch-view'],['closed-bootstrap-view'],'Bounded canonical authenticated memory-only handoff; source321 byte/deadline/FD limits exact. Close read FD on every path before childexec; no writer, broker, RPC or service capability.'),
 ('trusted-time-and-revocation-fence','external-native-fence-provider',['consumed-original-context'],['live-original-fence-view'],'Trusted time, original split forward/recovery scopes, continuous external native live fence; worker receives no broker/RPC/service channel. Offline receipt is not live revocation proof.'),
 ('worker-readonly-preflight','readonly-worker',['consumed-original-context','closed-bootstrap-view','source-closure-view'],['early-observation-view'],'Same original consumed context readonly observation, no owned/ledger effects, no promotion to original target baseline.'),
 ('worker-traps-and-child-control','owned-child-supervisor',['consumed-original-context'],['armed-traps-view','known-child-set-view'],'Arm traps before owned effects; bounded supervision of every known owned child including helpers; unknown child identity/quiescence blocks recovery/release.'),
 ('outer-writer-guard-and-original-baseline','native-writer-exclusion-provider',['consumed-original-context','armed-traps-view','live-original-fence-view'],['continuous-guard-view','original-baseline-view'],'Native object/alias/writer-lifetime exclusion and fresh original capture in memory after traps before owned2. Guard continuous through known target release, never reacquired.'),
 ('owned-runtime-and-original-backups','owned-storage-provider',['consumed-original-context','continuous-guard-view','original-baseline-view'],['owned-path-set-view','original-backups-view'],'Individual canonical owned paths after guard; exact original presence/content/metadata backups persisted and verified before predecessor/config/target effects.'),
 ('predecessor-and-local-isolation','controlled-package-worker',['consumed-original-context','continuous-guard-view','original-backups-view','source-closure-view'],['exact-predecessor-view','isolated-config-view','raw-pkglist-pin-view'],'Only original approved predecessor/config deltas. Fresh regular nonempty exit0 pkglist with both-stream guards, one original raw SHA pin; no fallback or rebind.'),
 ('stage7-owned-binding','owned-binding-storage-provider',['consumed-original-context','continuous-guard-view','raw-pkglist-pin-view'],['candidate-binding-view'],'Readonly eight-field pinned validation then all nine source322 intent/stage/write/file-and-directory durable/no-replace/exit-evidence steps. Unknown commit blocks8; binding alone grants no dispatch.'),
 ('whole-reference-entry','successor-entry-provider',['consumed-original-context','continuous-guard-view','candidate-binding-view','complete-effect-graph-view','source-closure-view'],['whole-entry-result-view'],'Complete selected successor transitive effect graph and all nested helpers required; never substitute three emulator argv or run reference main/frozenv2 in this review.'),
 ('reference-lock-runtime-logs','reference-effect-adapter',['consumed-original-context','continuous-guard-view','owned-path-set-view','complete-effect-graph-view'],['contained-runtime-view'],'All reference lock/runtime/log/FD/cleanup writers, aliases and lifetimes contained; every writer accounted, no broad path waiver.'),
 ('reference-snapshots-and-config-scan','reference-effect-adapter',['consumed-original-context','continuous-guard-view','original-baseline-view','complete-effect-graph-view'],['contained-snapshot-view'],'All snapshot/config scans and mutations classified against original baseline; early observations never become replacement baseline.'),
 ('nested-call-adapter','nested-call-provider',['consumed-original-context','candidate-binding-view','raw-pkglist-pin-view','complete-effect-graph-view'],['nested-call-result-view'],'Exact source325 argv, full environment/FD/cwd/namespace/helper/effect context; same consumed original attempt, no nested unused admission.'),
 ('real-backend-and-selector','backend-selector-provider',['consumed-original-context','raw-pkglist-pin-view','complete-effect-graph-view'],['full-selector-vector-view'],'Versioned actual backend, all selector guards/raw exit statuses/full status vector and sticky failure latch. Package name/flags or generic exit0 never prove intended effect.'),
 ('package-tools-and-install-hooks','package-effect-provider',['consumed-original-context','continuous-guard-view','source-closure-view','complete-effect-graph-view'],['package-effect-result-view'],'All pkgtools/install hooks/post-actions and helpers match approved deltas/full graph. Boot/GenInitrd/optional/unknown effects remain blocked even if flags suppress them.'),
 ('source-and-archive-consumption','checked-content-provider',['consumed-original-context'],['source-closure-view'],'Bind every consumed source/archive/package byte and extraction/type/path/metadata policy through actual use; hash check alone not checked-to-used equivalence.'),
 ('interpreter-helper-dependency-consumption','dependency-closure-provider',['source-closure-view'],['dependency-closure-view'],'All service/bootstrap/worker/recovery/publication interpreters and helper/transitive dependencies, writers and lifetimes source-bound; lexical inventory is not complete dynamic graph.'),
 ('owned-child-quiescence','owned-child-supervisor',['consumed-original-context','known-child-set-view','continuous-guard-view','live-original-fence-view'],['quiescent-child-view'],'Forward irreversibly stopped; known owned child drain with retained original finite recovery rights/fence/deadline/budget before restoration and release. Unknown child never guessed absent.'),
 ('same-attempt-original-restoration','original-recovery-provider',['consumed-original-context','continuous-guard-view','original-baseline-view','quiescent-child-view','recovery-budget-view'],['original-restoration-result-view'],'Only original finite rights/identity/safe boot/phase/known outcomes/continuous guard-fence/durable pre-spent budget. Verified original backups required for restore; independent unchanged verification avoids writes and never-created backups. Unknown action never replayed.'),
 ('target-evidence-closure','original-verification-provider',['consumed-original-context','continuous-guard-view','original-baseline-view','quiescent-child-view'],['original-verification-view','closed-target-evidence-view'],'Full original invariants and source324 unchanged raw audit pin, preserve original failure. Capture closed target evidence before release; no later pkglist consumer after restoration.'),
 ('target-control-release','target-release-supervisor',['continuous-guard-view','quiescent-child-view','original-verification-view','closed-target-evidence-view'],['target-release-view'],'Release only after known original verification/evidence/owned child closure; no target writes/refresh/read-to-rebind/reacquire/new grant after release.'),
 ('publication-controls','publication-control-provider',['closed-target-evidence-view','target-release-view'],['publication-control-view'],'Independent owner/recipient/ancestry/alias/content and live original publication rights through last receipt durability/origin/handoff. Captured closed data only, no target access or new target grant.'),
 ('publication-record','publication-storage-provider',['closed-target-evidence-view','target-release-view','publication-control-view'],['publication-record-view'],'Individual no-replace publication file/content/metadata/directory/storage durability; no pair atomicity, selfreceipt or retry uncertain publication.'),
 ('publication-last-receipt','independent-receipt-provider',['publication-control-view','publication-record-view'],['last-receipt-origin-view'],'Separate trusted final receipt/origin/durability and recipient handoff before publication rights close; no selfreceipt, republish uncertainty or target refresh/write/grant.'),
]

def build_interface_catalog(history,phase):
    rows=[];nodes={r['id']:r for r in phase['node_phase_map']};phases={r['id']:r for r in phase['entry_trace']}
    for identifier,provider,inputs,outputs,requirement in INTERFACE_LAYOUT:
        node=nodes[identifier]
        rows.append(dict(id=identifier,version=1,provider_role=provider,
                         input_types=inputs,success_output_types=outputs,
                         allowed_phase_contexts=[dict(id=p,caller_actor=phases[p]['actor'],rights_window=phases[p]['rights_window']) for p in node['phase_ids']],
                         retained_requirement=requirement,required_future_proofs=node['required_future_proofs'],
                         completion_type='nominal-private-result-not-native-evidence',
                         linearity='original-context-and-finite-rights-never-cloned-renewed-or-reissued; type-shape-does-not-prove-linearity',
                         lifetime='all-actual-writers-objects-aliases-dependencies-through-source-bound-phase-lifetime-required-not-proven',
                         uncertain_outcome_rule='no-success-outputs-no-automatic-retry-restore-relaunch-rebind-or-closure; retain-original-pending-obligations',
                         actual_component_path=None,actual_component_sha256=None,actual_writers=None,actual_dependencies=None,
                         actual_lifetime=None,actual_durability_or_fence_evidence=None,actual_conformance_evidence=None,
                         dispatch_blocked=True))
    type_names=sorted({t for row in rows for t in row['input_types']+row['success_output_types']})
    types=[dict(name=t,kind='nominal-private-symbolic-view',native_abi=None,real_value=None,
                authority=False,proof_status='required-not-proven',
                representation='closed fields: type,scope,attempt,boot,symbol,authority; private original fixture context only') for t in type_names]
    return dict(schema=1,step=332,scope='repository-typed-primitive-interface-contracts-only',
                selected_candidate_version='successor-inert-typed-interfaces-v1',interfaces=rows,type_definitions=types,
                phase_map_binding=dict(path=PHASE_PATH,sha256=sha(history[PHASE_PATH])),
                inherited_phase_contract=phase,
                blocked_domains=[dict(id=n['id'],interface=None,dispatch_blocked=True,required_future_proofs=n['required_future_proofs']) for n in phase['node_phase_map'] if n['forbidden_or_unknown']],
                all_actual_selection_gaps=phase['all_actual_selection_gaps'],inherited_counts=phase['inherited_counts'],
                inherited_platform_cases=phase['inherited_platform_cases'],
                scope_limit='No request queue, adapter, syscall, native ABI, source loading, dispatcher, capability issuance or actual effect observation. Nominal shape is not runtime authenticity, continuous enforcement, durable/linear storage, full graph, fault refinement or conformance.',
                actual_native_primitives_selected=False,actual_native_interface_abi_selected=False,
                actual_graph_complete=False,actual_implementation_frozen=False,operational_conformance=False,
                operational_readiness=False,runtime_authority=False,actual_host_state='unobserved-not-claimed-absent',
                actual_live_bindings=None,machine_action_required=False,controller_action_required=False,
                historical_v2_or_reference_main_sourced_run=False,strong_safe_pause=False,
                user_step332_checkpoint_confirmed=False,last_confirmed_strong_safe_pause_step=328,
                next_stage='333-non-dispatching-candidate-manifest-validator-after-complete332-return')

def validate_interface_catalog(value,history,phase):
    exact(value,build_interface_catalog(history,phase),'exact typed catalog source/proof/lifetime/blocker closure')
    exact(len(value['interfaces']),26,'26 nominal interfaces')
    exact(len(value['blocked_domains']),4,'four forbidden/unknown domains have no interface')
    exact(sorted({r['id'] for r in value['interfaces']}|{r['id'] for r in value['blocked_domains']}),sorted(r['id'] for r in phase['node_phase_map']),'all30 domains retained')
    return True

def symbolic_value(type_name):
    return dict(type=type_name,scope='private-symbolic-review',attempt='original-attempt-A',boot='original-boot-A',symbol='fixture-value-A',authority=False)

def validate_symbolic_value(value,type_name):
    exact(sorted(value),['attempt','authority','boot','scope','symbol','type'],'closed nominal value fields')
    exact(value['type'],type_name,'nominal type mismatch')
    exact(value['scope'],'private-symbolic-review','native handle cannot masquerade as private view')
    exact(value['attempt'],'original-attempt-A','same original attempt no rebind')
    exact(value['boot'],'original-boot-A','same original boot no rebind')
    exact(value['authority'],False,'no value conveys authority')
    symbol=value['symbol']
    if type(symbol) is not str or not 1<=len(symbol)<=64 or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_' for c in symbol):raise ValueError('bounded private symbol, never path/content/FD')
    return True

def private_exchange(interface,phase_index=0,status='known-complete'):
    p=interface['allowed_phase_contexts'][phase_index]
    request=dict(schema=1,origin='synthetic-private-fixture',scope='nominal-interface-shape-only',interface=interface['id'],version=1,
                 phase=p['id'],caller_actor=p['caller_actor'],rights_window=p['rights_window'],provider_role=interface['provider_role'],
                 inputs={t:symbolic_value(t) for t in interface['input_types']})
    report=dict(schema=1,origin='synthetic-private-fixture',interface=interface['id'],status=status,
                outputs={t:symbolic_value(t) for t in interface['success_output_types']} if status=='known-complete' else {},
                actual_evidence=None,actual_authority=False)
    return request,report

def validate_private_exchange(request,report,catalog):
    if type(request) is not dict or type(report) is not dict:raise ValueError('private request/report must be objects')
    if type(request.get('inputs')) is not dict or type(report.get('outputs')) is not dict:raise ValueError('private input/output slots must be objects')
    exact(sorted(request),['caller_actor','inputs','interface','origin','phase','provider_role','rights_window','schema','scope','version'],'closed private request')
    exact(request['schema'],1,'request schema');exact(request['version'],1,'request interface version')
    exact(request['origin'],'synthetic-private-fixture','request origin');exact(request['scope'],'nominal-interface-shape-only','request scope')
    match=[r for r in catalog['interfaces'] if r['id']==request['interface']]
    if len(match)!=1:raise ValueError('unknown or forbidden interface')
    row=match[0];exact(request['provider_role'],row['provider_role'],'provider role cannot cross capabilities')
    context=dict(id=request['phase'],caller_actor=request['caller_actor'],rights_window=request['rights_window'])
    if context not in row['allowed_phase_contexts']:raise ValueError('caller phase actor and original rights window mismatch')
    exact(sorted(request['inputs']),sorted(row['input_types']),'all typed inputs exactly once')
    for name,value in request['inputs'].items():validate_symbolic_value(value,name)
    exact(sorted(report),['actual_authority','actual_evidence','interface','origin','outputs','schema','status'],'closed private report')
    exact(report['schema'],1,'report schema');exact(report['origin'],'synthetic-private-fixture','report origin')
    exact(report['interface'],row['id'],'request report matching interface')
    exact(report['actual_evidence'],None,'private report is not native evidence');exact(report['actual_authority'],False,'private report conveys no grant')
    if report['status'] not in ['known-complete','known-failed','unknown','not-attempted']:raise ValueError('closed outcome tag')
    complete=report['status']=='known-complete'
    exact(sorted(report['outputs']),sorted(row['success_output_types']) if complete else [],'no success payload after failed unknown or unattempted operation')
    for name,value in report['outputs'].items():validate_symbolic_value(value,name)
    return dict(model_shape_valid=True,model_nominal_outputs_present=complete,
                model_pending_native_obligations=True,model_original_uncertainty_retained=not complete,
                model_retry_or_automatic_recovery=False,
                actual_dispatch_authorized=False,actual_linear_consumption_proven=False,
                actual_continuous_fence_proven=False,actual_native_durability_proven=False,
                actual_effect_or_graph_conformance=False,actual_target_or_publication_closure=False)


def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed332 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    policy=load('-policy.json');history=verify_history(root,policy);phase=json.loads(history[PHASE_PATH])
    catalog=load('-interfaces.json');validate_interface_catalog(catalog,history,phase)
    expected_types=dict(schema=1,step=332,scope='nominal-private-type-definitions-not-native-ABI',types=catalog['type_definitions'],outcome_tags=['known-complete','known-failed','unknown','not-attempted'],actual_abi=None,actual_authority=False,actual_evidence=None)
    exact(load('-types.json'),expected_types,'type registry exact')
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step331-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-interfaces.json','-types.json','-checkpoint-confirmation.json','-step331-user-acceptance.json','-interface-proof-map.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,policy).items()},{r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'332 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step331_acceptance\tPASS (399 passes, 0 failures)')
    print('step332_typed_primitive_interface_contract_status\tPASS')
    print('nominal_interfaces_and_blocked_domains\t26/4')
    print('actual_native_ABI_or_dispatch_authorized\tno')
    print('actual_native_proof_or_closure\tno')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user332-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)

PYREVIEW
