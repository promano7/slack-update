#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only proof effect rights and gap reconciliation review; no shell sourcing or runtime dispatch.\n' "${0##*/}"
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
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1611 manifest')
    exact(len(bindings),1611,'accepted1611 count')
    history={}
    for rel,digest in bindings.items():
        raw=safe_file(root,rel)
        if rel=='CHANGELOG.md':
            prefix=CHANGELOG_PREFIX.encode()
            exact(raw[:len(prefix)].hex(),prefix.hex(),'337 CHANGELOG prefix')
            exact(len(raw),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            raw=raw[len(prefix):]
        exact(sha(raw),digest,'accepted artifact drift '+rel);history[rel]=raw
    return history
def validate_confirmation(c,r):
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed336 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original336 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),1247,'complete1247 return')
    exact(lines.count('Result: PASS (1247 passes, 0 failures)'),1,'1247 summary')
    return True
def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step336-exact336-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=1247 or lines.count('Result: PASS (1247 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact1247 predecessor acceptance failed')
        return result.stdout
import copy
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independently-authored-candidate-negative-tests-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = '94c6cc82f793b31abf3860c594f54087dbb3fa98ea221a72a564ba49fdfcaf65'
CHANGELOG_PREFIX = '## Phase 1 step337 — proof/effect/rights/gap reconciliation — 2026-10-06\n\n- Confirmed336 at2ed8836 from complete ordered1247 PASS, successful first push, clean status and matching HEAD/origin. Original return retained; full object ID unknown. User applied the exact verified367149-byte compact overlay SHA4bb5cbb2031aebad323a76fe4c591ddad2b84b13061bc476aacacfd020c948fc after the original full ZIP became truncated. Transport failure/repair evidence retained separately; no repository revision, source/test change, reapplication or historical flag rewrite. Last confirmed strong pause328.\n- Preserve all1611 accepted files except additive CHANGELOG; nine new artifacts. Rerun exact1247 predecessor and full nested history. Select successor-inert-proof-effect-rights-gap-reconciliation-v1 as data only. Check exact329-336 sources/eight320-327 views and bindings, all46 proof registers/52 full native templates,30 domains/every95 macro relation/27 phases/26 interfaces/35 types/85 contexts, nine original rights windows/seven capabilities/ten cross obligations/16 native gaps/81 cuts/nine owned microsteps. Bind all72 repository artifacts329-336, not native components.\n- Reconcile every qualified proof to retained domains, candidate phases/nominal interfaces and separate native case tuples. Seven capabilities/ten obligations have explicit manual design-related domain/proof cross-indexes, never proof or exhaustive native refinement. Service-own and forbidden windows retain source obligations without inventing standalone331 phases. No original authority/budget/deadline/fence/issuer/scope, component/native writer/effect or independent oracle evidence selected.\n- Reconcile1166 private assertions/92 positive controls/812 expected rejections/354 expected declarative responses with complete336 return. Private PASS adds zero native proofs and runs zero native cases. Every native unknown remains a blocker, never absence/no-effect/global closure. All46 proofs required-not-proven/52 cases required-not-run (26 each15.0/current), seven capabilities/ten obligations/nine windows still native incomplete.\n- Preserve all nine original329 conditional pause requirements. Synthetic boundary requires exact repository329-338 scope, no authority/live binding, unobserved host and exact bool conditions; false condition stays pending. Private review eligibility never confirms pause, actual implementation freeze/conformance/target/publication/global closure or new grant.338 artifact freeze/gap register requires complete337 return and later complete338 acceptance; no proof weakening to fit batch.\n- No runtime/VM/preflight/refresh/namespace/package/target/restore/operational publication/service channel or new batch machine/controller cleanup. Reference main/frozenv2 never sourced/run. Actual host unobserved, live bindings null, later-current refresh must not reuse stale bindings. Production/Phase2 closed; Phase1/kernel incomplete.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review.md': '3b0109c8044a2311427f5395a6d166a22ec9f68a08a80bc04f696c60712d2e79', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review-policy.json': '756ce59901103202df5abeb9f386411031f06087b53db3a42eed8c2358f8228a', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review-reconciliation.json': '127a2109c49a74bc7c36f6ed644cc60dfeeee4d8beba11398fa81253551055c5', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review-private-boundaries.json': '3c6fe692acf722be1b531ef4768b105ea2ed40b4eadfcc4ad9e5a79494a42966', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review-checkpoint-confirmation.json': '0060bd66231ac3659ddd05e8c58e8603f04fb2f008904e26d1c1cdcc560061d6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review-step336-user-acceptance.json': '99dbd7b6312aaa02d801887506a93e12a0daf222b217b2f1a954c10c892f5306', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-proof-effect-rights-and-gap-reconciliation-review-proof-effect-rights-map.tsv': 'eb2d39221ff091d49bd18df971cb4d119c937fe3727619efdd09a12e5238edf8'}
CONFIRMATION_SHA256 = '0060bd66231ac3659ddd05e8c58e8603f04fb2f008904e26d1c1cdcc560061d6'
RECEIPT_SHA256 = '1ba0bc4585f8fbb89e4b9b1a6db8d9439caebd921bfb07c7cd7ba95e45a45bd9'
RECEIPT_SIZE = 158303
WORKSTREAM_BASES = {'329': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-candidate-refinement-resume-planning-boundary-review', '330': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review', '331': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review', '332': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review', '333': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review', '334': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review', '335': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review', '336': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independently-authored-candidate-negative-tests-review'}
SOURCE_PATHS = {'retained': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-candidate-refinement-resume-planning-boundary-review-retained-obligations.json', 'plan': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-candidate-refinement-resume-planning-boundary-review-plan.json', 'inventory': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-inventory.json', 'phase': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-inert-successor-entry-and-phase-map-review-phase-map.json', 'catalog': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-interfaces.json', 'manifest': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-manifest.json', 'fault': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-failure-refinement-mapping-and-gap-review-refinement.json', 'oracle': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independent-oracle-scaffolding-review-scaffold.json', 'negative': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independently-authored-candidate-negative-tests-review-review.json', 'suite': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-independently-authored-candidate-negative-tests-review-negative-cases.json'}
# Exact declarative cross-index. No native component or authority selection.
CAPABILITY_DOMAINS={
 'real-reference-integration-and-selector-equivalence':['whole-reference-entry','nested-call-adapter','real-backend-and-selector','package-tools-and-install-hooks'],
 'namespace-command-transport-and-no-fallback':['offline-bootstrap-context','worker-traps-and-child-control','whole-reference-entry','nested-call-adapter','interpreter-helper-dependency-consumption'],
 'absolute-backend-path-and-SHA':['real-backend-and-selector','nested-call-adapter','source-and-archive-consumption'],
 'reviewed-platform-writer-serialization':['outer-writer-guard-and-original-baseline','reference-lock-runtime-logs','reference-snapshots-and-config-scan','owned-child-quiescence','source-and-archive-consumption'],
 'fresh-single-use-grant-source-target-predecessor-and-boot':['issuer-policy-and-key-provisioning','durable-admission-claim','durable-single-launch-slot','trusted-time-and-revocation-fence','predecessor-and-local-isolation','same-attempt-original-restoration'],
 'real-source-and-archive-revalidation':['source-and-archive-consumption','interpreter-helper-dependency-consumption','package-tools-and-install-hooks','predecessor-and-local-isolation'],
 'operational-owner-and-publication-path-bindings':['target-evidence-closure','target-control-release','publication-controls','publication-record','publication-last-receipt'],
}
OBLIGATION_DOMAINS={
 'claim-traps-containment':['issuer-policy-and-key-provisioning','durable-admission-claim','offline-bootstrap-context','worker-traps-and-child-control'],
 'guarded-baseline':['outer-writer-guard-and-original-baseline','owned-runtime-and-original-backups','predecessor-and-local-isolation'],
 'binding-effect-classification':['stage7-owned-binding','worker-traps-and-child-control','outer-writer-guard-and-original-baseline'],
 'whole-effect-graph':['whole-reference-entry','nested-call-adapter','real-backend-and-selector','reference-lock-runtime-logs','reference-snapshots-and-config-scan','reference-GenInitrd-mutation','reference-optional-module-mutation','reference-boot-mutation','unresolved-dynamic-helpers-and-dependencies'],
 'retained-bytes-and-writers':['source-and-archive-consumption','interpreter-helper-dependency-consumption','outer-writer-guard-and-original-baseline'],
 'same-attempt-phase-deltas':['predecessor-and-local-isolation','same-attempt-original-restoration','source-and-archive-consumption','target-evidence-closure'],
 'pkglist-selector-status':['predecessor-and-local-isolation','real-backend-and-selector','nested-call-adapter'],
 'target-publication-controls':['owned-child-quiescence','target-evidence-closure','target-control-release','publication-controls'],
 'last-receipt-durability':['publication-record','publication-last-receipt'],
 'failure-recovery-rights':['trusted-time-and-revocation-fence','owned-child-quiescence','same-attempt-original-restoration','outer-writer-guard-and-original-baseline'],
}

def reconciliation_sources(history):
    return {k:json.loads(history[p]) for k,p in SOURCE_PATHS.items()}

def reconcile_source_inputs(history,s):
    retained=s['retained'];inventory=s['inventory'];phase=s['phase'];catalog=s['catalog'];manifest=s['manifest'];fault=s['fault'];oracle=s['oracle'];negative=s['negative'];suite=s['suite']
    for rows,count,label in [(retained['effect_domains'],30,'domains'),(retained['designed_edges'],95,'macro relations'),(phase['entry_trace'],27,'phases'),(catalog['interfaces'],26,'interfaces'),(catalog['type_definitions'],35,'types'),(retained['authority_windows'],9,'rights windows'),(retained['seven_requirements_bindings'],7,'capabilities'),(retained['preserved_cross_obligations'],10,'cross obligations'),(fault['native_gap_register'],16,'native gaps'),(fault['candidate_boundary_cuts'],81,'macro cuts'),(fault['stage7_owned_microstep_obligations'],9,'owned microsteps'),(oracle['cases'],52,'native cases'),(s['plan']['pause_conditions'],9,'original pause conditions')]:exact(len(rows),count,'all original '+label)
    exact(sum(len(i['allowed_phase_contexts']) for i in catalog['interfaces']),85,'all85 nominal interface phase contexts')
    exact(len(retained['future_proof_register']),46,'46 original qualified proofs')
    for proof in retained['future_proof_register']:
        exact(proof['operational_proven'],False,'native proof not promoted');exact(proof['actual_evidence'],None,'native proof evidence absent not supplied');exact(proof['source_proof']['status'],'required-not-proven','original proof remains pending')
    for row in oracle['cases']:
        exact(row['status'],'required-not-run','native case still unrun');exact(row['actual_result'],None,'no native result')
    for value in [manifest['qualified_proof_register'],fault['qualified_proof_register'],oracle['qualified_proof_register'],negative['qualified_proof_register']]:exact(value,retained['future_proof_register'],'all qualified proof registers equal')
    exact(phase['selected_source_views'],retained['frozen_contract_views'],'eight original frozen contract views')
    exact(phase['preserved_integration_contract_bindings'],retained['successor_contract_bindings'],'eight frozen source bindings')
    exact(sorted(retained['successor_contract_bindings']),[str(i) for i in range(320,328)],'all320-327 contracts')
    for binding in retained['successor_contract_bindings'].values():exact(sha(history[binding['path']]),binding['sha256'],'frozen contract source bytes')
    for cap in retained['seven_requirements_bindings']:
        for role in ['policy','review']:exact(sha(history[cap[role+'_path']]),cap[role+'_sha256'],'capability source bytes')
        exact(cap['operational_conformance'],False,'capability remains native incomplete')
    exact([c['capability'] for c in retained['seven_requirements_bindings']],list(CAPABILITY_DOMAINS),'all seven manual capability cross-index keys')
    exact([c['id'] for c in retained['preserved_cross_obligations']],list(OBLIGATION_DOMAINS),'all ten manual obligation keys')
    exact(manifest['authority_windows'],retained['authority_windows'],'all nine original rights windows')
    exact(manifest['seven_requirements_bindings'],retained['seven_requirements_bindings'],'all seven capability bindings')
    exact(manifest['preserved_cross_obligations'],retained['preserved_cross_obligations'],'all ten cross obligations')
    exact([n['id'] for n in manifest['components']],retained['effect_domains'],'all30 declared effect domains')
    exact([[e['source'],e['target']] for e in manifest['macro_design_relations']],retained['designed_edges'],'every95 declared macro relation')
    exact(manifest['macro_design_relations'],inventory['candidate_edges'],'inventory and manifest edges unchanged')
    for value in [catalog['inherited_phase_contract'],manifest['exact_phase_contract'],fault['exact_phase_contract'],oracle['inherited_phase_contract']]:exact(value,phase,'exact phase contract in every successor view')
    exact(oracle['inherited_native_gap_register'],fault['native_gap_register'],'all16 native refinement gaps')
    exact(negative['native_gap_register'],fault['native_gap_register'],'negative tests cannot close native gaps')
    exact(negative['macro_cut_obligations'],fault['candidate_boundary_cuts'],'all81 cut obligations')
    exact(negative['owned_stage7_microsteps'],fault['stage7_owned_microstep_obligations'],'all9 owned microsteps')
    exact([r['inherited_case'] for r in oracle['cases']],retained['independent_conformance_plan'],'all52 original full native case contracts')
    exact(negative['native_case_templates'],oracle['cases'],'native case templates unchanged by private tests')
    projection=[dict(platform=r['platform'],case_id=r['case_id'],status=r['status'],result=r['actual_result']) for r in oracle['cases']]
    for value in [manifest['independent_platform_cases'],inventory['inherited_platform_cases'],phase['inherited_platform_cases']]:exact(value,projection,'all52 separately pending two-platform cases')
    exact(len(suite['cases']),1166,'all1166 private contract assertions')
    exact(negative['private_case_count'],1166,'private case count retained')
    exact(sum(c['baseline_positive_control'] for c in suite['cases']),92,'all92 positive controls')
    exact(sum(c['expectation']['kind']=='reject' for c in suite['cases']),812,'812 rejected declarations expected')
    exact(sum(c['expectation']['kind']=='return' for c in suite['cases']),354,'354 private declaration responses expected')
    for row in manifest['components']:
        exact(row['dispatch_blocked'],True,'every component dispatch blocked');exact(row['operational_proven'],False,'no actual component proof')
        for key in ['actual_implementation_path','actual_implementation_sha256','actual_writers','actual_dependencies','actual_lifetimes','actual_evidence']:exact(row[key],None,'no native component binding')
    for row in retained['authority_windows']:
        exact(row['actual_authority_valid'],False,'no original window native authority');exact(row['operational_disposition'],'required-not-proven','rights proof pending')
        for key in ['actual_budget','actual_deadline','actual_fence','actual_issuer','actual_scope']:exact(row[key],None,'no live original window binding')
    return True

def build_reconciliation(history):
    s=reconciliation_sources(history);reconcile_source_inputs(history,s)
    retained=s['retained'];manifest=s['manifest'];phase=s['phase'];catalog=s['catalog'];oracle=s['oracle'];negative=s['negative'];fault=s['fault']
    components={r['id']:r for r in manifest['components']};interfaces={r['id']:r for r in catalog['interfaces']};proofs=retained['future_proof_register']
    def proof_union(domains):
        if any(d not in components for d in domains):raise ValueError('unknown manual domain link')
        return sorted({p for d in domains for p in components[d]['required_future_proofs']})
    proof_rows=[]
    for proof in proofs:
        ident=proof['qualified_id'];domains=[r['id'] for r in manifest['components'] if ident in r['required_future_proofs']]
        if not domains:raise ValueError('qualified proof has no retained domain cross-index')
        proof_rows.append(dict(qualified_id=ident,inherited_proof=proof,domain_ids=domains,
                               candidate_phase_ids=sorted({p for d in domains for p in components[d]['phase_ids']}),
                               nominal_interface_ids=[d for d in domains if d in interfaces],
                               required_native_case_tuples=[dict(platform=c['platform'],case_id=c['case_id']) for c in oracle['cases'] if ident in c['required_qualified_proofs']],
                               status='required-not-proven',actual_evidence=None,private_PASS_is_native_proof=False))
    domain_rows=[dict(id=row['id'],accepted_component_sha256=sha(encoded(row)),classification=row['classification'],
                      phase_ids=row['phase_ids'],nominal_interface_id=row['id'] if row['id'] in interfaces else None,
                      required_qualified_proofs=row['required_future_proofs'],dispatch_blocked=True,
                      actual_component=None,actual_effect_evidence=None,status='declarative-cross-index-reviewed-native-unselected') for row in manifest['components']]
    rights_rows=[dict(window=row['window'],inherited_window=row,phase_ids=[p['id'] for p in phase['entry_trace'] if p['rights_window']==row['window']],
                     no_standalone_candidate_phase=row['window'] in ['service','forbidden'],
                     standalone_note='Source service-own controls or forbidden boundary retained without inventing a new331 phase.' if row['window'] in ['service','forbidden'] else 'Exact331 phase rights tags only, never native credential or enforcement proof.',
                     actual_grant=None,actual_binding=None,status='required-not-proven') for row in retained['authority_windows']]
    def related(row,key,mapping):
        ids=mapping[row[key]]
        return dict(id=row[key],inherited_obligation=row,design_related_domain_ids=ids,design_related_qualified_proofs=proof_union(ids),
                    relationship='manual-design-cross-index-not-proof-or-exhaustive-native-refinement',
                    actual_evidence=None,operational_conformance=False,status='required-not-proven')
    registry=[]
    for step,base in WORKSTREAM_BASES.items():
        paths=sorted(p for p in history if p=='docs/reference/'+base+'.md' or p=='tools/reference/'+base+'.sh' or p=='tests/reference/test-'+base+'-harness.sh' or p.startswith(FIXTURE+'/'+base+'-'))
        exact(len(paths),9,'all nine repository artifacts for workstream step'+step)
        registry.extend(dict(step=int(step),path=p,sha256=sha(history[p]),scope='repository-artifact-not-native-implementation') for p in paths)
    return dict(schema=1,step=337,scope='repository-proof-effect-rights-gap-reconciliation-only',
                selected_candidate_version='successor-inert-proof-effect-rights-gap-reconciliation-v1',repository_reconciliation_complete=True,
                source_bindings=[dict(role=k,path=p,sha256=sha(history[p])) for k,p in SOURCE_PATHS.items()],repository_artifact_registry329_336=registry,
                exact_contract_bindings=retained['successor_contract_bindings'],exact_contract_views=retained['frozen_contract_views'],
                qualified_proof_reconciliation=proof_rows,effect_domain_reconciliation=domain_rows,
                all95_macro_design_relations=manifest['macro_design_relations'],all27_phase_boundaries=phase['entry_trace'],
                all26_nominal_interfaces=catalog['interfaces'],all35_nominal_types=catalog['type_definitions'],
                authority_window_reconciliation=rights_rows,
                seven_capability_reconciliation=[related(r,'capability',CAPABILITY_DOMAINS) for r in retained['seven_requirements_bindings']],
                ten_cross_obligation_reconciliation=[related(r,'id',OBLIGATION_DOMAINS) for r in retained['preserved_cross_obligations']],
                all16_native_gaps=fault['native_gap_register'],all52_native_case_templates=oracle['cases'],
                all81_macro_cut_obligations=fault['candidate_boundary_cuts'],all9_owned_microsteps=fault['stage7_owned_microstep_obligations'],
                exact_bootstrap_and_original_phase_contract=phase,
                private_negative_test_reconciliation=dict(source_path=SOURCE_PATHS['negative'],source_sha256=sha(history[SOURCE_PATHS['negative']]),private_cases=1166,positive_controls=92,expected_rejections=812,expected_declarative_returns=354,scope='complete336-return-and-full-predecessor-tests-not-native-evidence',native_proofs_added=0,native_cases_run=0),
                repository_source_conflicts_found=[],native_unknowns_are_retained_blockers_not_absence=True,
                original329_pause_conditions=s['plan']['pause_conditions'],conditional_next_stage='338-scoped-repository-candidate-artifact-freeze-and-gap-register-after-complete337-return',
                freeze_boundary='Repository candidate artifacts/gaps only. Actual implementation/component/native graph/refinement/oracle/two-platform conformance/readiness remain unselected or unproven. Complete338 user acceptance required before a new scoped strong pause confirmation.',
                actual_native_cases_run=0,actual_proofs_added=0,actual_dynamic_graph_complete=False,actual_native_refinement_complete=False,
                actual_independent_oracle_selected=False,actual_operational_implementation_frozen=False,actual_operational_conformance=False,operational_readiness=False,runtime_authority=False,
                actual_live_bindings=None,actual_host_state='unobserved-not-claimed-absent',actual_global_host_closure_asserted=False,
                historical_v2_or_reference_main_sourced_run=False,machine_action_required=False,controller_action_required=False,
                user_step337_checkpoint_confirmed=False,strong_safe_pause=False,last_confirmed_strong_safe_pause_step=328,
                production_entry_closed=True,phase2_open=False,phase1_matrix_complete=False,kernel_package_edge_complete=False)

def validate_reconciliation(value,history):
    exact(value,build_reconciliation(history),'exact proof-effect-rights-gap reconciliation with no waiver')
    return True

def evaluate_private_pause_boundary(value,review):
    exact(sorted(value),['actual_host_state','conditions','live_binding','origin','scope','test_authority'],'closed private scoped boundary')
    exact(value['origin'],'synthetic-private-fixture','private boundary origin')
    exact(value['scope'],'repository-candidate-refinement-workstream329-338-only','exact scoped boundary no runtime or global pause')
    exact(value['test_authority'],False,'private boundary no authority')
    exact(value['live_binding'],None,'no stale or future live binding')
    exact(value['actual_host_state'],'unobserved-not-claimed-absent','unknown host cannot be absence')
    conditions=value['conditions'];exact(sorted(conditions),sorted(review['original329_pause_conditions']),'all original329 pause conditions retained')
    if any(type(v) is not bool for v in conditions.values()):raise ValueError('typed private pause conditions')
    pending=[k for k in review['original329_pause_conditions'] if not conditions[k]]
    return dict(model_repository_candidate_freeze_reviewable=not pending,model_pending_conditions=pending,
                model_actual_proofs_still_required=46,model_actual_native_cases_still_unrun=52,
                actual_strong_safe_pause_confirmed=False,actual_runtime_authority=False,actual_implementation_freeze=False,
                actual_operational_conformance=False,actual_target_or_publication_closure=False,actual_global_host_closure=False)


def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed337 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    policy=load('-policy.json');history=verify_history(root,policy);review=load('-reconciliation.json');validate_reconciliation(review,history)
    for example in load('-private-boundaries.json')['examples']:
        exact(example['actual_evidence'],None,'private boundary not actual evidence')
        exact(example['result'],evaluate_private_pause_boundary(example['input'],review),'exact private pending boundary')
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step336-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-reconciliation.json','-private-boundaries.json','-checkpoint-confirmation.json','-step336-user-acceptance.json','-proof-effect-rights-map.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,policy).items()},{r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'337 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step336_acceptance\tPASS (1247 passes, 0 failures)')
    print('step337_proof_effect_rights_gap_reconciliation_status\tPASS')
    print('required_native_proofs_cases_gaps\t46/52/16-still-pending')
    print('actual_runtime_authority_or_native_closure\tno')
    print('actual_native_cases_run\t0')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user337-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)

PYREVIEW
