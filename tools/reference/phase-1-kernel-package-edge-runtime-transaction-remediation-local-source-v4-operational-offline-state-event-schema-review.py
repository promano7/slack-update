#!/usr/bin/env python3
"""Source-bound repository schema review. No native observations or dispatch."""
from pathlib import Path
import ast
import hashlib
import json
import re
import sys

BASE='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review'
FIXTURE='tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES={'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py': '94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5', 'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review.md': '472e81bdc553be5efe9c8b027fa4d6dcabb8da1c9c259d63804d18ecd4b7e58c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review-phase-map.json': '23d306b87e275ed590007da464112e7412a702c904c29e32f46f40bf8a337f03', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review-checkpoint-confirmation.json': 'f7856c2e0fcebce5134fe5e3a896f215ba53e8396be5b6a23b15d67602aaf5d0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review-step339-user-acceptance.json': '674b604eaee229f51c2077d4ebbf9c7140ebd0a4699c23eba5a07853103e94df', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review-policy.json': 'fbde8612306beeae95cbd57691359bcbe4d176de869fda8afd993e16969153c3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-state-event-schema-review-schema.json': '3c22e90b44c98736c1fbb49b254ebb965d7d81f667ed13bdba6f3f72ff3fc928'}
ADDITION_SHA='efa22dbb17b6868ce6dd9478068875dee41bd0d440a497adaa7b593202a59b8f'
ACCEPTED_339_PATHS=['docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review.md', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-checkpoint-confirmation.json', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-plan.json', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-policy.json', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-retained-obligations.json', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-roadmap.tsv', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-step338-user-acceptance.json', 'tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-harness.sh', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review.py']


def sha(value):return hashlib.sha256(value).hexdigest()
def exact(value,expected,label):
    if type(value) is not type(expected) or value!=expected:raise ValueError(label)
def safe_file(root,relative):
    if type(relative) is not str or not relative or '\\' in relative or any(p in ('','.','..') for p in relative.split('/')):
        raise ValueError('unsafe repository path')
    p=root/relative
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute():raise ValueError('unsafe source: '+relative)
    return p

def normalize_label(value):
    if value.startswith("PASS: strict CLI ['--check', PosixPath("):
        if not re.fullmatch(r"PASS: strict CLI \['--check', PosixPath\('[^'\n]+'\), 'extra'\]",value):raise ValueError('ambiguous root label')
        return "PASS: strict CLI ['--check', PosixPath('<checked-repository-root>'), 'extra']"
    return value

def validate_return(confirmation,receipt,policy):
    raw=receipt['text'].encode('utf-8');lines=receipt['text'].splitlines()
    exact(receipt['encoding'],'utf8-json-text','full original return encoding')
    exact(len(raw),receipt['original_display_size_bytes'],'full original return size')
    exact(sha(raw),receipt['original_display_sha256'],'full original return SHA')
    exact(sha(raw),confirmation['evidence_sha256'],'confirmation binds original return')
    exact(len(raw),confirmation['evidence_size_bytes'],'confirmation full return size')
    exact(confirmation['step'],339,'accepted339');exact(confirmation['commit_prefix'],'83b8441','reported prefix')
    exact(confirmation['commit_full'],None,'full ID unknown')
    exact(confirmation['acceptance_result'],'PASS (162 passes, 0 failures)','complete339 summary')
    for k in ('complete_ordered_return_matches_prepared_and_installed','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean'):
        exact(confirmation[k],True,'complete returned acceptance '+k)
    for k in ('strong_safe_pause','runtime_authority','phase2_open'):
        exact(confirmation[k],False,'no new native authority or pause')
    exact(confirmation['last_confirmed_strong_safe_pause_step'],338,'last confirmed pause')
    exact(confirmation['actual_live_bindings'],None,'no live bindings')
    exact(confirmation['actual_host_state'],'unobserved-not-claimed-absent','host unobserved')
    for k in ('actual_native_cases_run','actual_native_proofs_added'):exact(confirmation[k],0,'no native proof promotion')
    labels=[x for x in lines if x.startswith('PASS: ')]
    exact(len(labels),162,'all complete ordered labels')
    exact(sum(normalize_label(x)!=x for x in labels),1,'only checked-root path label normalized')
    exact(list(map(normalize_label,labels)),policy['accepted_ordered339_labels'],'all exact ordered339 labels')
    exact(lines.count('Result: PASS (162 passes, 0 failures)'),1,'single complete acceptance summary')
    exact([x[len(' create mode 100644 '):] for x in lines if x.startswith(' create mode 100644 ')],ACCEPTED_339_PATHS,'all nine returned new paths')
    exact(lines.count(' 10 files changed, 4567 insertions(+)'),1,'exact reported commit scope')
    message='Phase 1 step 339: plan pure offline transition core from confirmed pause'
    exact(lines.count('83b8441 (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching reported HEAD-origin')
    if '0bdf964..83b8441  main -> main' not in receipt['text']:raise ValueError('successful reported push missing')
    exact(confirmation['push_attempt_count'],2,'both real repository attempts retained')
    exact(confirmation['successful_push_attempts'],1,'one successful observed push')
    exact(confirmation['first_push_failed_ssh_disconnect'],True,'first failure preserved')
    exact(confirmation['out_of_repository_retry_failed_preserved'],True,'nonrepository retry preserved')
    if 'Received disconnect from' not in receipt['text'] or 'fatal: no es un repositorio git' not in receipt['text']:raise ValueError('failure history omitted')
    return True

def validate_mapping(mapping,history):
    binding=mapping['freeze_binding'];original=history[binding['path']]
    exact(sha(original),binding['sha256'],'full original338 frozen contract')
    freeze=json.loads(original)
    expected={x['id']:{'actor':x['actor'],'window':x['rights_window'],'position':x['position']} for x in freeze['all27_phase_boundaries']}
    exact(mapping['phases'],expected,'all27 exact phases actors/windows/order')
    exact(mapping['nominal_types'],[x['name'] for x in freeze['all35_nominal_types']],'all35 original names')
    exact(mapping['rights_windows'],[x['window'] for x in freeze['authority_window_reconciliation']],'all nine original windows')
    views={k:set() for k in expected};contexts=0
    for x in freeze['all26_nominal_interfaces']:
        for phase in x['allowed_phase_contexts']:
            views[phase['id']].update(x['input_types']+x['success_output_types']);contexts+=1
    exact(contexts,85,'all original interface contexts')
    exact(mapping['original_interface_contexts'],85,'context count')
    exact(mapping['phase_view_types'],{k:sorted(v) for k,v in views.items()},'complete source-bound phase view types')
    exact(mapping['original_interface_bindings'],[{'id':x['id'],'canonical_row_sha256':sha(json.dumps(x,sort_keys=True,separators=(',',':')).encode())} for x in freeze['all26_nominal_interfaces']],'full26 original interface rows')
    exact(mapping['no_standalone_phase_windows'],['service','forbidden'],'no invented phase')
    for k in ('native_authority','native_evidence'):exact(mapping[k],False,'symbolic map never native proof')
    return True

def verify(root):
    root=Path(root).absolute()
    if not root.is_dir() or root.resolve()!=root:raise ValueError('safe repository root required')
    for relative,digest in OWN_HASHES.items():exact(sha(safe_file(root,relative).read_bytes()),digest,'current340 source SHA')
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+BASE+suffix).read_bytes())
    policy=load('-policy.json');history={}
    for relative,digest in policy['baseline_sha256_bindings'].items():
        raw=safe_file(root,relative).read_bytes()
        if relative=='CHANGELOG.md':
            size=policy['accepted_changelog_size']
            if len(raw)<=size:raise ValueError('missing340 additive changelog')
            exact(sha(raw[:-size]),ADDITION_SHA,'exact340 changelog addition');raw=raw[-size:]
        exact(sha(raw),digest,'exact accepted339 bytes '+relative);history[relative]=raw
    exact(len(history),1638,'all accepted339 sources')
    validate_return(load('-checkpoint-confirmation.json'),load('-step339-user-acceptance.json'),policy)
    validate_mapping(load('-phase-map.json'),history)
    spec=load('-schema.json')
    for k in ('input_resource_limits_are_native_conformance','dataclass_immutability_is_authentication_or_security','constructors_check_transition_semantics','reducers_implemented','operational_entry_selected','native_authority','native_evidence'):exact(spec[k],False,'shape-only boundary '+k)
    exact(spec['step'],340,'current schema step');exact(spec['wire_schema'],1,'private wire version')
    # Parse only. Actual new pure record/codec behavior is executed by the harness.
    core=safe_file(root,'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py')
    ast.parse(core.read_text())
    return history

def main(argv):
    if argv==['--help']:
        print('Repository-only immutable model schema check: --check REPOSITORY');return 0
    if len(argv)!=2 or argv[0]!='--check' or not argv[1]:return 2
    try:verify(argv[1])
    except (ValueError,KeyError,TypeError,OSError) as error:
        print('ERROR: '+str(error),file=sys.stderr);return 1
    print('step340_offline_schema_review_status\tPASS')
    print('last_confirmed_strong_safe_pause_step\t338')
    print('native_cases_run\t0');print('native_proofs_added\t0');print('runtime_authority\tno')
    return 0

if __name__=='__main__':raise SystemExit(main(sys.argv[1:]))
