#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only integration design planning; no runtime authority.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYREVIEW'
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review.md': 'cdea9b1e55f04936604379e3a11b24e435fef8c10978c407b4117d17b7135327', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review-policy.json': '5b4fa83c9acfb8b5b54a6f1315ef0cdf637a29de37d3da0d8c5c86ee7b4dab0d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review-plan.json': '8c4f17759effab4b37d8e2418f4b7da89da519ccda8e08865b0990acc155e5ec', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review-checkpoint-confirmation.json': 'c83cbeb935a062516ff27fd55ed0d4e170c445ccb295d1976261089b2ad9d15b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review-step318-user-acceptance.json': '3f882e0827fd721bb5a20cb9493818cc22a6ef095efa5ee43e8a1dde317caf0e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review-roadmap.tsv': '754869ac6c27234445b5c494c41d3b138cc7bdecd939db48a8b2840066fa1d93', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-integration-design-resume-planning-boundary-review-integration-obligations.tsv': 'eb17fd55e7d17627e6202ff22d6303e6d7a933c6de13e22f784f601f88d6331f'}
CHANGELOG_PREFIX = '## Phase 1 step319 — post-requirements integration design resume planning — 2026-10-04\n\n- Resume by new explicit user request from confirmed318 strong pause: e31977c prefix, full717 PASS, successful first push, clean tree and matching HEAD/origin logs. Full object ID unknown; original user return is not independent host/GitHub inspection. External confirmation preserves immutable prepared318 flags and all prior failures/history.\n- Preserve all1449 accepted artifacts except an additive CHANGELOG prefix. Nine new repository artifacts bind the accepted receipt, confirmation, exact baseline, seven frozen requirements and ten cross-dependency proof obligations. Complete717 predecessor suite is rerun on exact accepted bytes; independent earlier counts/mandatory coverage remain unchanged.\n- Plan ten repository integration-design stages319–328. Select admission/durable consumption, isolated FD handoff, explicit successor stage7 owned binding classification and expiry/revocation recovery design in separate future reviews. Integrate guarded baseline, original phase deltas, complete reference/effect graph and publication controls, then private failure model, cross closure and conditional design freeze/pause.\n- This is a new route, not use of ungranted historical319–320 reserves.329–330 optional remediation remains ungranted; roadmap grants no later-stage or runtime authority. Only current319 overlay/tests/exact commit/user push/return allowed. Stage320 preparation follows complete319 acceptance; each later stage requires its predecessor return.\n- No protocol, recovery policy, operational successor implementation or conformance selected here. Frozen operational source/specification and all seven requirements unchanged. Proof obligations still required-not-proven; current live bindings and actual host obligations remain null/unobserved, never claimed absent. Historical v2 never sourced/run and consumed/unused historical grants remain closed.\n- Target328 strong pause is conditional on complete user acceptance and scoped effects/obligations/rights closure, with no required batch machine/controller cleanup or operational attempt/publication.319 is not a new strong pause;318 remains the confirmed anchor. Pause must be independent of later-current refresh/publication. Unresolved design incompatibility blocks freeze and requires an explicit revised plan rather than weakened coverage.\n- Production/Phase2 closed; Phase1/kernel edge incomplete. Compatibility scope stays Slackware15.0/current without live proof. No machine/controller operation or cleanup introduced by this repository-only stage; operational implementation/conformance and fresh authority remain separate later work.\n\n'
BASELINE_JSON_SHA256 = '4c46e0fca24c8d0194283ea29375a17c08a15db7fba353f873252b4ce7acd9f6'
CONFIRMATION_SHA256 = 'c83cbeb935a062516ff27fd55ed0d4e170c445ccb295d1976261089b2ad9d15b'
RECEIPT_SHA256 = 'd81fd03e1b1d5e94e3c8dfdd9337f6ef9c2a6a25cea4ef57334769d2e394a636'
PLAN_SCHEMA = ['actual_host_obligations_claimed_absent', 'actual_host_obligations_observed', 'compatibility_claim', 'compatibility_scope', 'current_live_bindings', 'current_stage_rights', 'decision_boundaries', 'frozen_operational_design_rewritten', 'historical_reserve319_320_reused', 'historical_v2_sourced_or_run', 'integration_obligations', 'kernel_package_edge_complete', 'last_confirmed_strong_safe_pause_step', 'later_stage_rights', 'operational_conformance', 'operational_implementation_complete', 'operational_readiness', 'optional_step_range', 'optional_steps_authorized', 'pause_conditions', 'pause_scope', 'phase1_matrix_complete', 'phase2_open', 'preferred_step_range', 'production_entry_closed', 'remaining_operational_blockers', 'roadmap_grants_later_stages', 'route', 'runtime_attempt_planned', 'runtime_rights', 'schema', 'scope', 'scope_selection', 'seven_requirements_bindings', 'step', 'stop_rule', 'strong_safe_pause', 'successor_integration_design_selected', 'successor_rule', 'user_step319_checkpoint_confirmed']
ROUTE_STAGES = ['resume-planning-boundary-review', 'admission-and-durable-consumption-design-review', 'admission-handoff-and-namespace-fd-design-review', 'stage7-owned-binding-effect-design-review', 'expiry-revocation-and-bounded-recovery-design-review', 'guarded-baseline-and-phase-delta-integration-design-review', 'reference-effects-and-publication-integration-design-review', 'integration-failure-model-and-conformance-plan-review', 'integration-design-effects-obligations-and-rights-closure-review', 'integration-design-freeze-and-conditional-strong-safe-pause']
OBLIGATION_STEPS = {'claim-traps-containment': [320, 321, 324, 326], 'guarded-baseline': [324, 326], 'binding-effect-classification': [322, 324, 326], 'whole-effect-graph': [321, 325, 326], 'retained-bytes-and-writers': [324, 325, 326], 'same-attempt-phase-deltas': [320, 323, 324, 326], 'pkglist-selector-status': [325, 326], 'target-publication-controls': [323, 325, 326], 'last-receipt-durability': [325, 326], 'failure-recovery-rights': [323, 326]}
TABLE_HASHES = ['754869ac6c27234445b5c494c41d3b138cc7bdecd939db48a8b2840066fa1d93', 'eb17fd55e7d17627e6202ff22d6303e6d7a933c6de13e22f784f601f88d6331f']

def exact(actual, expected, label):
    if json.dumps(actual, sort_keys=True, default=lambda b: ["bytes", b.hex()]) != json.dumps(expected, sort_keys=True, default=lambda b: ["bytes", b.hex()]):
        raise ValueError(label)

def sha(content):
    return hashlib.sha256(content).hexdigest()

def safe_relative(rel):
    if type(rel) is not str or not rel or '\\' in rel or rel.startswith('/') or any(x in ('', '.', '..') for x in rel.split('/')):
        raise ValueError('unsafe relative path')
    return Path(rel)

def safe_file(root, rel):
    p = root / safe_relative(rel)
    if not p.is_file() or p.is_symlink() or p.absolute() != p.resolve() or not p.resolve().is_relative_to(root.resolve()):
        raise ValueError('unsafe file ' + rel)
    return p.read_bytes()

def validate_confirmation(c, receipt):
    exact(sha((json.dumps(c, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()), CONFIRMATION_SHA256, 'external318 confirmation')
    exact(sorted(receipt), ['encoding','original_display_sha256','original_display_size_bytes','text'], 'receipt fields')
    exact(receipt['encoding'], 'utf8-json-text', 'receipt encoding')
    raw = receipt['text'].encode()
    exact(sha(raw), RECEIPT_SHA256, 'receipt318 original digest')
    exact(len(raw), 71179, 'receipt318 original size')
    exact(receipt['original_display_sha256'], RECEIPT_SHA256, 'receipt digest metadata')
    exact(receipt['original_display_size_bytes'], 71179, 'receipt size metadata')
    lines = receipt['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),717,'complete ordered717 return')
    exact(lines.count('Result: PASS (717 passes, 0 failures)'),1,'full717 summary')
    log = 'e31977c (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 318: freeze operational requirements and qualify strong safe pause'
    exact(lines.count(log),2,'matching returned HEAD/origin logs')
    if '[main e31977c]' not in receipt['text'] or '4741bc1..e31977c  main -> main' not in receipt['text']:
        raise ValueError('missing318 commit/push')
    return True

def verify_history(root, policy):
    binding = policy['baseline_sha256_bindings']
    serialized = (json.dumps(binding, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
    exact(sha(serialized),BASELINE_JSON_SHA256,'exact accepted1449 manifest')
    exact(len(binding),1449,'accepted1449 file count')
    history = {}
    for rel,digest in binding.items():
        content = safe_file(root,rel)
        if rel == 'CHANGELOG.md':
            prefix = CHANGELOG_PREFIX.encode()
            exact(len(content),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            exact(content[:len(prefix)],prefix,'new CHANGELOG prefix')
            content = content[len(prefix):]
        exact(sha(content),digest,'accepted artifact drift '+rel)
        history[rel] = content
    return history

def validate_plan(plan, frozen):
    exact(sorted(plan),PLAN_SCHEMA,'strict planning schema')
    exact(plan['schema'],1,'schema'); exact(plan['step'],319,'step')
    for key in ['schema','step','last_confirmed_strong_safe_pause_step']:
        if type(plan[key]) is not int: raise ValueError('integer field '+key)
    for key,value in dict(scope='repository-only-successor-integration-design-planning',
        preferred_step_range=[319,328],optional_step_range=[329,330],
        optional_steps_authorized=False,roadmap_grants_later_stages=False,
        historical_reserve319_320_reused=False,
        scope_selection='new-user-request-after-confirmed318-not-consumption-of-old-reserves',
        runtime_attempt_planned=False,production_entry_closed=True,phase2_open=False,
        phase1_matrix_complete=False,kernel_package_edge_complete=False,
        historical_v2_sourced_or_run=False,frozen_operational_design_rewritten=False,
        successor_integration_design_selected=False,operational_implementation_complete=False,
        operational_conformance=False,operational_readiness=False,
        current_live_bindings=None,actual_host_obligations_observed=None,
        actual_host_obligations_claimed_absent=False,last_confirmed_strong_safe_pause_step=318,
        strong_safe_pause=False,user_step319_checkpoint_confirmed=False,
        current_stage_rights=['repository-overlay','repository-tests','exact-commit','user-push-and-return'],
        runtime_rights='closed',later_stage_rights='closed-pending-predecessor-acceptance',
        pause_scope='repository-integration-design-workstream319-328-only',
        decision_boundaries=dict(durable_admission='unselected-unimplemented',
            admission_fd_handoff='unselected-unimplemented',
            stage7_successor_effect_classification='unselected-frozen-history-preserved',
            expiry_revocation_recovery_policy='unselected-unimplemented'),
        compatibility_scope=['Slackware-15.0','Slackware-current'],
        compatibility_claim='requirements-and-future-proof-targets-only-no-live-validation').items():
        exact(plan[key],value,'planning boundary '+key)
    for key in ['stop_rule','successor_rule']:
        if type(plan[key]) is not str or not plan[key].strip(): raise ValueError('missing design rule')
    expected_conditions = ['complete-user-overlay-test-commit-successful-push-clean-tree-and-matching-HEAD-origin-return', 'all-batch-design-effects-obligations-and-rights-reviewed-and-closed', 'no-batch-runtime-or-partial-operational-publication', 'no-required-batch-machine-or-controller-cleanup', 'all-future-stage-runtime-and-unused-live-rights-closed', 'unknown-actual-host-obligations-remain-unobserved-not-claimed-absent', 'pause-independent-of-later-Slackware-current-refresh-or-publication']
    exact(plan['pause_conditions'],expected_conditions,'complete scoped pause conditions')
    exact(len(plan['route']),10,'ten-stage route')
    for index,row in enumerate(plan['route']):
        step = 319+index
        exact(sorted(row),['conditional_pause_candidate','deliverable','entry_requires_confirmed_step','runtime_authorized','scope','stage','status','step'],'route schema')
        if type(row['step']) is not int or type(row['entry_requires_confirmed_step']) is not int:
            raise ValueError('route step types')
        exact(row['step'],step,'route order'); exact(row['stage'],ROUTE_STAGES[index],'route stage')
        exact(row['entry_requires_confirmed_step'],step-1,'no skipped predecessor')
        exact(row['scope'],'repository-design-only','route scope')
        exact(row['runtime_authorized'],False,'closed machine authority')
        exact(row['conditional_pause_candidate'],step==328,'pause target')
        exact(row['status'],'prepared-not-user-accepted' if step==319 else 'planned-not-authorized','route rights')
        if type(row['deliverable']) is not str or not row['deliverable'].strip(): raise ValueError('route deliverable absent')
    exact(plan['seven_requirements_bindings'],frozen['seven_review_bindings'],'seven exact frozen reviews')
    exact(plan['remaining_operational_blockers'],frozen['remaining_operational_blockers'],'remaining operational blockers')
    obligations = plan['integration_obligations']
    exact(len(obligations),len(frozen['proof_obligations']),'all ten proof obligations')
    for row,old in zip(obligations,frozen['proof_obligations']):
        exact(row,dict(id=old['id'],required_evidence=old['required_evidence'],negative_case=old['negative_case'],
            status='required-not-proven',design_review_steps=OBLIGATION_STEPS[old['id']],operational_proof_complete=False),'preserved proof obligation '+old['id'])
    return True

def validate_tables(roadmap, obligations):
    exact(sha(roadmap),TABLE_HASHES[0],'exact typed roadmap')
    exact(sha(obligations),TABLE_HASHES[1],'exact obligation coverage table')
    return True

def evaluate_private_stage_gate(value):
    exact(sorted(value),['checkpoint','origin','requested_step','returned_step','scope'],'gate fields')
    exact(value['origin'],'synthetic-private-fixture','private origin')
    exact(value['scope'],'repository-stage-preparation-only','private gate scope')
    for key in ['requested_step','returned_step']:
        if type(value[key]) is not int: raise ValueError('typed stage')
    step = value['requested_step']
    if step not in range(320,329): raise ValueError('stage outside preferred future route')
    checkpoint = value['checkpoint']
    keys = ['applied','complete_acceptance','commit_pushed','worktree_clean','HEAD_matches_origin']
    exact(sorted(checkpoint),sorted(keys),'complete checkpoint schema')
    if any(type(x) is not bool for x in checkpoint.values()): raise ValueError('typed checkpoint fields')
    return dict(model_repository_preparation_eligible=value['returned_step']==step-1 and all(checkpoint.values()),
        actual_dispatch_authorized=False,actual_grant_issued=False,actual_grant_consumed=False,
        actual_operational_conformance=False,actual_host_obligations_closed=False,
        actual_strong_safe_pause_confirmed=False)

def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step319-exact318-') as directory:
        snapshot = Path(directory)/'slack-update'
        for rel,content in history.items():
            p = snapshot/safe_relative(rel); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(content)
        result = subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines = result.stdout.decode().splitlines()
        if result.returncode or lines.count('Result: PASS (717 passes, 0 failures)')!=1 or sum(x.startswith('PASS: ') for x in lines)!=717:
            sys.stderr.buffer.write(result.stdout+result.stderr)
            raise ValueError('full exact717 predecessor acceptance failed')
        return result.stdout

def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve(): raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items(): exact(sha(safe_file(root,rel)),digest,'changed319 input '+rel)
    fixture = root/FIXTURE
    load = lambda suffix: json.loads((fixture/(BASE+suffix)).read_bytes())
    policy,plan = load('-policy.json'),load('-plan.json')
    history = verify_history(root,policy)
    frozen = json.loads(history[FIXTURE+'/'+PRIOR+'-freeze.json'])
    validate_plan(plan,frozen)
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step318-user-acceptance.json'))
    validate_tables(*[(fixture/(BASE+s)).read_bytes() for s in ['-roadmap.tsv','-integration-obligations.tsv']])
    payloads = {BASE+s:(fixture/(BASE+s)).read_bytes() for s in ['-policy.json', '-plan.json', '-checkpoint-confirmation.json', '-step318-user-acceptance.json', '-roadmap.tsv', '-integration-obligations.tsv']}
    log_name = BASE+'-predecessor-test.log'
    if not out.is_dir() or out.absolute()!=out.resolve(): raise ValueError('output must exist without symlink ancestors')
    if any((out/name).exists() or (out/name).is_symlink() for name in list(payloads)+[log_name]):
        raise ValueError('occupied output; no overwrite')
    payloads[log_name] = run_historical(history)
    exact(verify_history(root,policy),history,'history changed during validation')
    for rel,digest in OWN_HASHES.items(): exact(sha(safe_file(root,rel)),digest,'319 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:
                created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created): p.unlink()
        raise
    print('exact_step318_acceptance\tPASS (717 passes, 0 failures)')
    print('step319_resume_planning_status\tPASS')
    print('preferred_step_range\t319-328')
    print('actual_dispatch_authorized\tno')
    print('operational_readiness\tno')
    print('strong_safe_pause\tno')
    print('last_confirmed_strong_safe_pause_step\t318')
    print('next_stage_authorized\tno')

if __name__ == '__main__':
    try: main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)
PYREVIEW
