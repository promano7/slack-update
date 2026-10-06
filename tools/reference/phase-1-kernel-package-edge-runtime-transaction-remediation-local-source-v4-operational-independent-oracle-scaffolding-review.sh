#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only independent oracle scaffolding review; no shell sourcing or runtime dispatch.\n' "${0##*/}"
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
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1593 manifest')
    exact(len(bindings),1593,'accepted1593 count')
    history={}
    for rel,digest in bindings.items():
        raw=safe_file(root,rel)
        if rel=='CHANGELOG.md':
            prefix=CHANGELOG_PREFIX.encode()
            exact(raw[:len(prefix)].hex(),prefix.hex(),'335 CHANGELOG prefix')
            exact(len(raw),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            raw=raw[len(prefix):]
        exact(sha(raw),digest,'accepted artifact drift '+rel);history[rel]=raw
    return history
def validate_confirmation(c,r):
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed334 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original334 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),1242,'complete1242 return')
    exact(lines.count('Result: PASS (1242 passes, 0 failures)'),1,'1242 summary')
    return True
def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step334-exact334-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=1242 or lines.count('Result: PASS (1242 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact1242 predecessor acceptance failed')
        return result.stdout
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = 'e9bcc45fea8f2342e78a70e96836387834f5199e1ab680d8e035216197525edc'
CHANGELOG_PREFIX = '## Phase 1 step335 — independent oracle scaffolding — 2026-10-06\n\n- Confirmed step334 at prefix acd7a08 from complete ordered 1242 PASS identical to prepared/installed, first push successful, clean tree and matching HEAD/origin. Complete original return/external confirmation retained; full object ID unknown. Prepared step334/history, its successful preliminary1236/33 source/evidence and explicit three-condition private review revision remain unchanged. Step328 is the last confirmed strong pause.\n- Preserve all 1593 accepted files except additive CHANGELOG; nine new artifacts. Rerun exact 1242 predecessor and full nested history. Select successor-inert-independent-oracle-scaffold-v1 as data only: 52 distinct native case templates, 26 each15.0/current, all original source326 case subjects/authority/oracle/evidence/status fields unchanged, 12 inherited evidence gates and 12 independent observation groups. Actual observer/verifier/expectation author/comparison implementation and platform/source/boot/attempt/test authority/capture/results remain null/unselected.\n- Record separate subject/collector/verifier provenance and independently reviewed expectation requirements; prohibit shared candidate selector/cleanup logic, selfreported PASS/signature/row or candidate-derived expectation as sole oracle. Complete raw full status/selector/effect/lifetime/time-fence-budget/backup-original/target-release/publication-last-receipt vectors and independent positive/negative fault controls are mandatory future native evidence, not supplied by role labels or private comparisons.\n- Synthetic closed packet checks case/platform tuple and private original context, separate role labels, no candidate-logic reuse, typed ordered expected/observed vectors, all 12 groups and both controls. Claimed subject PASS cannot override mismatch; unknown/missing observation stays null/pending, never empty/no-effect/absence. Ineffective/unknown/missing controls block private declaration completeness. Even complete private match leaves all 52 native cases required-not-run and actual oracle/conformance/closure/test authority false.\n- Preserve all46 native proofs,16 gaps,81 macro-cut/nine owned-stage7 microstep obligations,31 macro-event/2938 finite-family limitations,14 original recovery conditions and all eight320–327 views/30 domains/95 relations/27 phases/26 interfaces/35 types/13 stages/nine windows/seven capabilities/ten obligations. Native storage/syscall/clock/fence/source/backend/selector/child/oracle selection and independence proof remain pending; no cross-platform transfer or actual refinement inferred.\n- No inspected reference main/frozenv2/source execution, runtime/VM/preflight/refresh/namespace/package/target/restore/operational publication/service channel/fault injection or new batch cleanup. Actual host unobserved, never absent/globally closed; live bindings null. Step336 independently authored candidate negative tests follows complete step335 return. Step338 scoped candidate pause remains conditional; runtime/production/Phase2 closed, Phase1/kernel incomplete.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review.md': '6a5a8815a0679eddcbefd32847c8959d7e91c61f40dc90f2e965ce7d69373ca0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-policy.json': '9b0cbc63aae976f5a89ce3cc58eb3abb2b8ce36698c4075e5b26c6a119391096', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-scaffold.json': 'a89ae9237cedbc72d2a4e46edde5a28c1e296569fbe5f928ff3358b1462e5adf', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-private-packets.json': '919c275400ca6cde0247951dcc313d42970bb61cdef39a6b23bc590e75820219', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-checkpoint-confirmation.json': '9ead55fee8ca6c8f43640b7c1dc81586fecc673876057e0f0434e97c2821525f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-step334-user-acceptance.json': 'ad928c11b489dc32ce26b2129d7b9d5500a2eba834a7c9e3af4075c27af7ae27', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-case-proof-map.tsv': '2d7429590370091a6bfd7642d7f7622f81c948069cc7b19aea432a06bfdd33dd'}
CONFIRMATION_SHA256 = '9ead55fee8ca6c8f43640b7c1dc81586fecc673876057e0f0434e97c2821525f'
RECEIPT_SHA256 = 'cfbcc301bfbbee29dc095abb3f05ac12dc2b526514b0a7c51a718ed66f4481e2'
RECEIPT_SIZE = 131953
REFINEMENT_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-refinement.json'
LEGACY_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-complete-finite-failure-model-and-independent-conformance-plan-review-design.json'
# Oracle evidence scaffold and synthetic vector comparison; no native verifier selected.
EVIDENCE_GROUPS=[
 ('subject-source-graph','Actual selected complete implementation/transitive dependency versions and checked-to-used bytes, not a lexical graph or emulator argv.'),
 ('platform-original-authority','Separate exact platform/version/boot/source/epoch/original attempt/test-run and explicit fresh native test authority; no cross-platform or historical binding inference.'),
 ('independent-provenance','Independent collector/verifier and separately reviewed expectation provenance/code; role labels or subject signature/PASS never enough.'),
 ('original-identity-timeline','Independent before/during/after original identities, approved phase deltas and immutable raw pin; no preflight promotion or rebinding.'),
 ('raw-status-selector-vector','Complete raw process streams/status vector/full selectors and intended versus no-op/unexpected effects; generic exit0 never enough.'),
 ('target-owned-effect-vector','Independent full target and owned effects, original baseline/metadata/presence and native denied/in-flight writer/alias surfaces.'),
 ('writer-child-lifetimes','All actual known owned child/helper/interpreter/writer/object/alias lifetimes, signal/crash quiescence and continuous guard before release.'),
 ('time-fence-recovery-budget','Trusted clocks/live split revocation fences/finite original deadline/durable pre-spent budget and original recovery rights; no broker channel or offline revocation proof.'),
 ('original-restoration-verification','Known original target outcome, exact verified backups or independently unchanged verification without never-created backups; full invariants/evidence before release.'),
 ('publication-last-receipt','Captured-data separate publication controls, no-replace record/final receipt file-metadata-directory-storage durability, independent trusted origin/handoff; no selfreceipt/pairatomicity/retry.'),
 ('positive-negative-fault-controls','Independent positive and negative fault controls with actual injection effectiveness and raw consequences, not an asserted fault flag.'),
 ('scoped-closure-or-pending','Complete source-bound effect/proof/rights/lifetime cross-closure or explicit scoped pending obligations; unknown never absence/global closure.'),
]
VECTOR_TYPES=['boolean','integer','tag']
CONTROL_TAGS=['declared-effective','declared-ineffective','declared-unknown','declared-missing']


def build_oracle_scaffold(history,refinement,legacy):
    groups=[dict(id=i,required_native_observation=description,actual_collector=None,actual_verifier=None,
                 actual_expected_vector=None,actual_raw_capture=None,actual_capture_sha256=None,
                 status='required-native-evidence-not-captured') for i,description in EVIDENCE_GROUPS]
    cases=[]
    for row in legacy['conformance_plan']:
        cases.append(dict(platform=row['platform'],case_id=row['case_id'],inherited_case=row,
                          required_source_evidence_gates=legacy['conformance_evidence_gates'],
                          required_qualified_proofs=[p['qualified_id'] for p in refinement['qualified_proof_register'] if row['case_id'] in p['conformance_case_ids']],
                          evidence_group_ids=[i for i,_ in EVIDENCE_GROUPS],
                          actual_subject_implementation=None,actual_subject_complete_graph=None,
                          actual_independent_collector=None,actual_independent_verifier=None,
                          actual_expectation_author=None,actual_comparison_algorithm=None,
                          actual_platform_version=None,actual_boot_id=None,actual_original_attempt=None,
                          actual_test_run_id=None,actual_fresh_test_authority=None,
                          actual_expected_vector_artifacts=None,actual_raw_capture_artifacts=None,
                          actual_positive_fault_control=None,actual_negative_fault_control=None,
                          actual_result=None,status='required-not-run'))
    return dict(schema=1,step=335,scope='repository-independent-oracle-scaffolding-only',
                selected_candidate_version='successor-inert-independent-oracle-scaffold-v1',
                refinement_binding=dict(path=REFINEMENT_PATH,sha256=sha(history[REFINEMENT_PATH])),
                legacy_plan_binding=dict(path=LEGACY_PATH,sha256=sha(history[LEGACY_PATH])),
                inherited_independent_conformance_contract=legacy['independent_conformance_contract'],
                inherited_source_evidence_gates=legacy['conformance_evidence_gates'],
                evidence_groups=groups,cases=cases,qualified_proof_register=refinement['qualified_proof_register'],
                inherited_native_gap_register=refinement['native_gap_register'],
                inherited_phase_contract=refinement['exact_phase_contract'],
                inherited_macro_cut_obligations=refinement['candidate_boundary_cuts'],
                inherited_owned_stage7_microsteps=refinement['stage7_owned_microstep_obligations'],
                independence_contract=dict(subject_collector_verifier='Separate subject, independent collector and verifier sources/provenance required; synthetic distinct role labels do not prove native independence.',
                                           expectation_author='Separately reviewed expectation cannot derive from candidate or be authored as candidate selfreport; verifier may author independent expectations.',
                                           forbidden_reuse='No candidate selector/cleanup/implementation logic reused as sole verifier/oracle, no emitted PASS/signature/row accepted as raw effect proof.',
                                           fault_controls='Independent positive and negative effectiveness/raw consequences required. Missing/unknown/ineffective control blocks private declaration completeness and actual native conformance remains pending.',
                                           uncertainty='Missing/unknown observation is null and pending, never empty/no-effect/absent. Declared mismatch remains visible even with other pending groups.',
                                           platforms='52 separate cases,26 each15.0/current. No transfer of platform token/version/boot/source/authority/result from either platform.',
                                           boundary='Synthetic envelope/type/vector comparison only. No actual raw capture, authenticator, observer, native comparator, source selection, test runner or fault injector.'),
                actual_independent_oracle_selected=False,actual_native_capture_present=False,
                actual_native_cases_run=0,actual_operational_conformance=False,operational_readiness=False,
                runtime_authority=False,actual_fresh_test_authority_granted=False,
                actual_live_bindings=None,actual_host_state='unobserved-not-claimed-absent',actual_global_host_closure_asserted=False,
                machine_action_required=False,controller_action_required=False,historical_v2_or_reference_main_sourced_run=False,
                user_step335_checkpoint_confirmed=False,strong_safe_pause=False,last_confirmed_strong_safe_pause_step=328,
                next_stage='336-independently-authored-candidate-negative-tests-after-complete335-return')

def validate_oracle_scaffold(value,history,refinement,legacy):
    exact(value,build_oracle_scaffold(history,refinement,legacy),'exact oracle scaffold native case/proof/provenance obligations')
    exact(len(value['cases']),52,'52 native cases unrun');exact(len(value['evidence_groups']),12,'12 independent evidence groups')
    exact(len({(r['platform'],r['case_id']) for r in value['cases']}),52,'distinct two-platform case tuples')
    exact([sum(r['platform']==p for r in value['cases']) for p in ['Slackware-15.0','Slackware-current']],[26,26],'separate26 cases each platform')
    return True


def validate_vector(value):
    if type(value) is not list or not 1<=len(value)<=64:raise ValueError('bounded nonempty private vector; unknown/missing uses null')
    ids=[]
    for row in value:
        exact(sorted(row),['item_id','value','value_type'],'closed typed vector item')
        ident=row['item_id']
        if type(ident) is not str or not 1<=len(ident)<=64 or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_' for c in ident):raise ValueError('bounded symbolic vector item ID')
        ids.append(ident);kind=row['value_type'];v=row['value']
        if kind=='boolean':
            if type(v) is not bool:raise ValueError('boolean vector type')
        elif kind=='integer':
            if type(v) is not int or not -(2**63)<=v<2**63:raise ValueError('integer vector type no bool coercion')
        elif kind=='tag':
            if type(v) is not str or not 1<=len(v)<=64 or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_' for c in v):raise ValueError('bounded private tag not path/FD/content')
        else:raise ValueError('closed nominal vector types')
    if len(set(ids))!=len(ids):raise ValueError('duplicate vector item ID')
    return True


def private_oracle_packet(case):
    platform=case['platform'];token={'Slackware-15.0':'fixture-platform15-A','Slackware-current':'fixture-platformcurrent-A'}[platform]
    groups={}
    for ident,_ in EVIDENCE_GROUPS:
        v=[dict(item_id='fixture-item-A',value_type='integer',value=1)]
        groups[ident]=dict(expected_vector=v,observed_vector=[dict(r) for r in v],status='declared-known')
    return dict(origin='synthetic-private-fixture',scope='oracle-envelope-contract-only',
                case_ref=dict(platform=platform,case_id=case['case_id']),
                context=dict(platform_token=token,case_token='fixture-case-'+case['case_id'],attempt_token='fixture-original-attempt-A',boot_token='fixture-original-boot-A',
                             source_graph_token='fixture-source-graph-A',test_authority='private-schema-test-only-no-native-grant'),
                identities=dict(subject='fixture-subject-A',collector='fixture-collector-B',verifier='fixture-verifier-C',expectation_author='fixture-verifier-C'),
                reuse=dict(candidate_logic_used_as_verifier=False,subject_report_is_sole_oracle=False,expectation_derived_from_subject=False),
                subject_claimed_status='PASS',groups=groups,
                fault_controls=dict(positive='declared-effective',negative='declared-effective'),
                actual_native_bindings=None,actual_authority=False)


def evaluate_private_oracle_packet(value,scaffold):
    exact(sorted(value),['actual_authority','actual_native_bindings','case_ref','context','fault_controls','groups','identities','origin','reuse','scope','subject_claimed_status'],'closed synthetic evidence packet')
    exact(value['origin'],'synthetic-private-fixture','private origin');exact(value['scope'],'oracle-envelope-contract-only','private scope')
    exact(value['actual_native_bindings'],None,'synthetic evidence no native binding');exact(value['actual_authority'],False,'synthetic evidence no grant')
    ref=value['case_ref'];exact(sorted(ref),['case_id','platform'],'closed case tuple')
    cases=[r for r in scaffold['cases'] if r['platform']==ref['platform'] and r['case_id']==ref['case_id']]
    if len(cases)!=1:raise ValueError('unknown wildcard duplicate or cross-platform native case')
    context=dict(platform_token={'Slackware-15.0':'fixture-platform15-A','Slackware-current':'fixture-platformcurrent-A'}[ref['platform']],case_token='fixture-case-'+ref['case_id'],
                 attempt_token='fixture-original-attempt-A',boot_token='fixture-original-boot-A',source_graph_token='fixture-source-graph-A',test_authority='private-schema-test-only-no-native-grant')
    exact(value['context'],context,'private platform original context no transplant or actual test authority')
    ids=value['identities'];exact(sorted(ids),['collector','expectation_author','subject','verifier'],'four logical provenance roles')
    for label in ids.values():
        if type(label) is not str or not label.startswith('fixture-') or not 1<=len(label)<=64 or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_' for c in label):raise ValueError('bounded private role label')
    if len({ids[k] for k in ['subject','collector','verifier']})!=3 or ids['expectation_author']==ids['subject']:raise ValueError('subject cannot be collector/verifier/expectation author')
    exact(value['reuse'],dict(candidate_logic_used_as_verifier=False,subject_report_is_sole_oracle=False,expectation_derived_from_subject=False),'no selfreport or shared candidate logic oracle')
    if value['subject_claimed_status'] not in ['PASS','FAIL','unknown']:raise ValueError('subject claim tag')
    groups=value['groups'];exact(sorted(groups),sorted(i for i,_ in EVIDENCE_GROUPS),'all independent evidence groups required')
    pending=[];mismatch=[]
    for ident,_ in EVIDENCE_GROUPS:
        group=groups[ident];exact(sorted(group),['expected_vector','observed_vector','status'],'closed evidence group')
        validate_vector(group['expected_vector']);status=group['status']
        if status=='declared-known':
            validate_vector(group['observed_vector'])
            if encoded(group['expected_vector'])!=encoded(group['observed_vector']):mismatch.append(ident)
        elif status in ['declared-unknown','declared-missing']:
            exact(group['observed_vector'],None,'unknown/missing never empty no-effect or absence');pending.append(ident)
        else:raise ValueError('closed observation status')
    controls=value['fault_controls'];exact(sorted(controls),['negative','positive'],'both independent fault controls required')
    if any(type(s) is not str or s not in CONTROL_TAGS for s in controls.values()):raise ValueError('closed fault control tag')
    ineffective=[k for k,s in controls.items() if s=='declared-ineffective'];unready=[k for k,s in controls.items() if s in ['declared-unknown','declared-missing']]
    complete=not pending and not mismatch and not ineffective and not unready
    return dict(model_synthetic_schema_valid=True,model_declared_evidence_complete=complete,
                model_mismatch_groups=mismatch,model_pending_groups=pending,
                model_ineffective_fault_controls=ineffective,model_pending_fault_controls=unready,
                model_subject_claim_used_for_acceptance=False,
                actual_platform_case_status='required-not-run',actual_independent_oracle_selected=False,
                actual_raw_native_capture_present=False,actual_native_test_authority_granted=False,
                actual_native_conformance=False,actual_target_or_publication_closure=False,
                actual_global_host_closure=False)


def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed335 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    policy=load('-policy.json');history=verify_history(root,policy);refinement=json.loads(history[REFINEMENT_PATH]);legacy=json.loads(history[LEGACY_PATH])
    scaffold=load('-scaffold.json');validate_oracle_scaffold(scaffold,history,refinement,legacy)
    for example in load('-private-packets.json')['examples']:
        exact(example['actual_evidence'],None,'private packet not native evidence')
        exact(example['result'],evaluate_private_oracle_packet(example['input'],scaffold),'private oracle packet no native conformance')
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step334-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-scaffold.json','-private-packets.json','-checkpoint-confirmation.json','-step334-user-acceptance.json','-case-proof-map.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,policy).items()},{r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'335 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step334_acceptance\tPASS (1242 passes, 0 failures)')
    print('step335_independent_oracle_scaffolding_status\tPASS')
    print('native_case_templates_and_evidence_groups\t52/12')
    print('actual_independent_oracle_or_test_authority_selected\tno')
    print('actual_native_cases_run\t0')
    print('required_proofs_and_independent_cases\t46-unproven/52-unrun')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user335-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)

PYREVIEW
