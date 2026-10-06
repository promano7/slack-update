#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only source-bound candidate graph inventory; no shell sourcing or runtime dispatch.\n' "${0##*/}"
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

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-candidate-refinement-resume-planning-boundary-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = '27eab6a506b3f77f4d4ad66d34b1f038f1e61f5e04fa9af58cf59c4e2b147acb'
CHANGELOG_PREFIX = '## Phase 1 step330 — source-bound successor candidate graph inventory — 2026-10-06\n\n- Confirmed329 at010194d prefix, complete ordered271 PASS identical to prepared/installed output, first push successful, clean tree and matching HEAD/origin. Preserve the complete original user return and external confirmation without rewriting prepared329. Full commit ID unknown; no independent host/GitHub observation.328 remains the last confirmed strong pause.\n- Preserve1548 accepted repository artifacts except additive CHANGELOG; nine additions. Rerun full exact271 predecessor with1320 and all nested historical coverage unchanged. Source-bound inventory covers30 designed domains/every95 macro relation, nine authority windows, seven capabilities/ten obligations/all46 qualified future proofs and52 required-not-run platform cases.\n- Bind six immutable source roles including full reference text, historical private emulator/tests/wrapper and frozenv2 body/executor. Recompute166 reference header segments/prelude/tail and Python syntax spans without sourcing or running inspected source. Bound line-level lexical ambiguity candidates include comments/strings and cannot prove effects, call resolution, exclusion or completeness.\n- Cross-index every node to exact frozen contracts and applicable historical source spans, rights/proofs/capabilities/obligations/platform case IDs. Historical private emulator and its three-call run_guarded_reference are never a selected whole successor or real backend/selector; own reference lock is never actual all-writer exclusion. Unimplemented service/fence/FD/owner/source/backend/helper/recovery/publication/oracle roles remain null and all nodes dispatch-blocked.\n- Preserve forbidden GenInitrd/optional/boot/unknown domains. Sixteen explicit actual selection/proof gaps include complete dynamic graph, native protocol/clock/revocation/writer/lifetime/durability and independent two-platform evidence. Original raw-status/sticky-failure/same-attempt/finite-recovery/captured-publication contracts remain mandatory; static inventory and private PASS never establish operational implementation freeze or conformance.\n- Current effects are repository/private validation only; no runtime/preflight/refresh/namespace/target/restore/operational publication/source execution or live authority. Host remains unobserved, never absent; no new batch machine/controller cleanup.330 user application/commit/push pending;331 inert successor phase-map follows complete330 return.338 conditional scoped repository candidate pause; production/Phase2 closed, Phase1/kernel incomplete.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review.md': '0d81e4a96e3cb48d4ab142697a8c4a389a2ecd92aa6cf844fc108f46e8489ab8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-policy.json': 'b631f7ee575ea93e45fc6912ed1f206d0f1e9b1f3daa201e148d0b075f79f711', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-inventory.json': '2e34c85968e85e9be6fe4c0f9e3a140a6d626d94e6b848c84d1e016d71a83f80', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-checkpoint-confirmation.json': 'b60eac7dc15836fe54e2d6f739f05066eb039c52c7cb4f8e80f2c9b12bd11808', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-step329-user-acceptance.json': 'a21c5d22914f63801bfb18273c944284501ab815b75baf8fa9455d14673204f4', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-candidate-nodes.tsv': '6d750ee93fc6f60b3a4fc4340f237d68a12aa916e44ecc1bf4951b149c8a0e02', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-source-bound-candidate-graph-inventory-review-candidate-edges.tsv': '870fddfbb149e96590effabba90ba530e954cca954c61908ccc1c3ba52136ee7'}
CONFIRMATION_SHA256 = 'b60eac7dc15836fe54e2d6f739f05066eb039c52c7cb4f8e80f2c9b12bd11808'
RECEIPT_SHA256 = '2431c688359f8f96dafd4ba8b4494808a5a43cee7be841edce75893deb219151'
RECEIPT_SIZE = 20503

REFERENCE='tools/reference/slack-update-reference.sh'
PRIVATE='tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate-private.py'
PRIVATE_TEST='tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-private.py'
PRIVATE_ENTRY=PRIVATE.replace('-private.py','.sh')
FROZEN_BODY='tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh'
FROZEN_EXECUTOR=FROZEN_BODY.replace('-body.sh','.sh')
SOURCE_ROLES={REFERENCE:'immutable-reference-text-not-selected-successor-entry',
              PRIVATE:'historical-private-emulator-not-native-operational-implementation',
              PRIVATE_TEST:'historical-private-tests-not-independent-platform-oracle',
              PRIVATE_ENTRY:'historical-private-wrapper-not-operational-entry',
              FROZEN_BODY:'historical-runtime-body-read-only-never-run',
              FROZEN_EXECUTOR:'historical-frozen-executor-read-only-never-run'}
ANCHORS={
 'issuer-policy-and-key-provisioning':([],[]),
 'durable-admission-claim':([],[]),
 'durable-single-launch-slot':([],[]),
 'offline-bootstrap-context':([],[]),
 'trusted-time-and-revocation-fence':([],[]),
 'worker-readonly-preflight':([],['Transaction.verify_inputs','Transaction.verify_immediate_preflight']),
 'worker-traps-and-child-control':(['install_runtime_traps'],['Transaction.arm_cleanup_traps','Transaction.on_signal','Transaction.on_exit']),
 'outer-writer-guard-and-original-baseline':([],['Transaction.capture_and_verify_baseline','Transaction.mutation_guard']),
 'owned-runtime-and-original-backups':(['initialize_runtime'],['Transaction.create_owned_workspace','Transaction.capture_and_verify_baseline']),
 'predecessor-and-local-isolation':([],['Transaction.stage_exact_predecessor','Transaction.configure_local_isolation','Transaction.refresh_and_validate_pkglist']),
 'stage7-owned-binding':([],['Transaction.bind_exact_candidate']),
 'whole-reference-entry':(['main','run_apply_workflow','update_slackware_system'],['Transaction.run_guarded_reference']),
 'reference-lock-runtime-logs':(['acquire_instance_lock','initialize_runtime','install_runtime_traps','rotate_logs','configure_logging'],[]),
 'reference-snapshots-and-config-scan':(['capture_package_snapshot_before','capture_package_snapshot_after','capture_pending_new_config_files','load_configuration'],[]),
 'reference-GenInitrd-mutation':(['prepare_geninitrd_grub_policy_override','restore_geninitrd_grub_policy_override'],[]),
 'reference-optional-module-mutation':([],[]),
 'reference-boot-mutation':(['probe_boot_module','run_boot_preparation_module'],[]),
 'nested-call-adapter':(['update_slackware_system','slackpkg_apply_action_failed'],['Transaction.guarded_slackpkg']),
 'real-backend-and-selector':(['update_slackware_system'],['PrivateBackend.slackpkg']),
 'package-tools-and-install-hooks':(['update_slackware_system'],['PrivateBackend.package']),
 'source-and-archive-consumption':([],['Transaction.verify_inputs']),
 'interpreter-helper-dependency-consumption':([],[]),
 'owned-child-quiescence':([],['Transaction.quiesce_children','Transaction.drain_owned','Transaction.spawn_owned']),
 'same-attempt-original-restoration':([],['Transaction.cleanup','Transaction.restore_baseline','Transaction.restore_file']),
 'target-evidence-closure':([],['Transaction.verify_restoration','Transaction.finalize_stage_evidence']),
 'target-control-release':([],[]),
 'publication-controls':([],['Transaction.publish_evidence_and_receipt']),
 'publication-record':(['print_json_result'],['Transaction.write_evidence','Transaction.flush_records']),
 'publication-last-receipt':([],['Transaction.commit_receipt']),
 'unresolved-dynamic-helpers-and-dependencies':([],[]),
}
GAPS=['actual-successor-entry-and-transitive-graph','issuer-authentication-key-provenance',
      'linearizable-durable-claim-and-quarantine','durable-launch-spend-and-supervision',
      'offline-bootstrap-and-FD-namespace-containment','native-time-revocation-fence',
      'native-writer-object-alias-and-lifetime-exclusion','fresh-original-baseline-and-approved-deltas',
      'owned-backup-binding-and-child-recovery-primitives','versioned-real-backend-and-full-selector',
      'package-hooks-source-archive-and-helper-consumption','bounded-clock-budget-and-same-attempt-recovery',
      'target-closure-before-release','independent-publication-last-receipt-durability-and-origin',
      'syscall-crash-concurrency-model-refinement','independent-two-platform-oracle-and-fault-observations']

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
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1548 manifest')
    exact(len(bindings),1548,'accepted1548 count')
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

def reference_segments(raw):
    lines=raw.decode().splitlines(keepends=True)
    starts=[(i,m.group(1)) for i,line in enumerate(lines) if (m:=re.fullmatch(r'([A-Za-z_][A-Za-z_0-9]*)\(\) \{\n',line))]
    entries=[i for i,line in enumerate(lines) if line.startswith('if [ "${BASH_SOURCE[0]}" = "$0" ]; then')]
    if not starts or len(entries)!=1 or entries[0]<=starts[-1][0]:raise ValueError('unsupported reference header/tail layout')
    rows=[]
    for index,(begin,name) in enumerate(starts):
        end=starts[index+1][0] if index+1<len(starts) else entries[0]
        rows.append(dict(name=name,start_line=begin+1,end_line=end,sha256=sha(''.join(lines[begin:end]).encode())))
    if len({r['name'] for r in rows})!=len(rows):raise ValueError('duplicate column-zero header')
    return dict(reference_sha256=sha(raw),line_count=len(lines),function_count=len(rows),functions=rows,
                prelude_sha256=sha(''.join(lines[:starts[0][0]]).encode()),
                entry_tail_sha256=sha(''.join(lines[entries[0]:]).encode()),
                method='exact-column-zero-segments-not-Bash-AST-or-call-graph',actual_transitive_graph_complete=False)

def python_definitions(raw):
    text=raw.decode();lines=text.splitlines(keepends=True);tree=ast.parse(text)
    rows=[]
    def visit(nodes,prefix=''):
        for node in nodes:
            if isinstance(node,(ast.FunctionDef,ast.AsyncFunctionDef,ast.ClassDef)):
                name=prefix+node.name
                rows.append(dict(name=name,kind=type(node).__name__,start_line=node.lineno,end_line=node.end_lineno,
                                 sha256=sha(''.join(lines[node.lineno-1:node.end_lineno]).encode()),
                                 evidence='syntax-span-only-no-call-resolution-or-execution'))
                visit(node.body,name+'.')
    visit(tree.body)
    if len({r['name'] for r in rows})!=len(rows):raise ValueError('ambiguous Python definition name')
    return rows

def lexical_ambiguities(raw):
    patterns={'command-substitution':r'\$\(|`','variable-expansion':r'\$[A-Za-z_{]',
              'source-eval-or-exec-token':r'\b(?:source|eval|exec)\b',
              'process-or-file-API-token':r'\b(?:subprocess|Popen|open|os|shutil)\b',
              'redirection-or-pipe-token':r'[<>|]'}
    rows=[]
    for number,line in enumerate(raw.decode().splitlines(keepends=True),1):
        tags=[tag for tag,pattern in patterns.items() if re.search(pattern,line)]
        if tags:rows.append(dict(line=number,tags=tags,line_sha256=sha(line.encode()),
                                interpretation='lexical-hit-including-comments-strings-not-confirmed-effect-or-complete-hazard-list'))
    return rows

def build_inventory(history,retained,graph,cross):
    reference=reference_segments(history[REFERENCE]);definitions=python_definitions(history[PRIVATE])
    byref={r['name']:r for r in reference['functions']};bypy={r['name']:r for r in definitions}
    old=graph['reference_census']
    for key in ['reference_sha256','line_count','function_count','prelude_sha256','entry_tail_sha256']:
        exact(reference[key],old[key],'original325 reference '+key)
    for fresh,original in zip(reference['functions'],old['functions']):
        exact(fresh,{k:original[k] for k in fresh},'original325 exact function span')
    exact(len(reference['functions']),len(old['functions']),'all original166 spans')
    crossrows={r['effect_node']:r for r in cross['crossclosure_matrix']}
    nodes=[]
    for original in graph['catalogue_nodes']:
        node=original['id'];refnames,pynames=ANCHORS[node]
        if node=='reference-optional-module-mutation':
            refnames=[r['name'] for r in old['functions'] if r['classification']=='optional-module-potential-effects-not-excluded-by-flags-alone']
        bindings=crossrows[node]['source_design_bindings']
        anchors=[dict(anchor_kind='frozen-contract-source',path=v['path'],sha256=v['sha256'],contract_step=int(k)) for k,v in bindings.items()]
        for name in refnames:anchors.append(dict(anchor_kind='historical-reference-segment-not-successor-selection',path=REFERENCE,**byref[name]))
        for name in pynames:anchors.append(dict(anchor_kind='historical-private-emulator-segment-not-native-proof',path=PRIVATE,**bypy[name]))
        nodes.append(dict(id=node,designed_node=original,historical_source_anchors=anchors,
                          rights_window=crossrows[node]['rights_window'],
                          required_future_proofs=crossrows[node]['future_proofs']+[r['qualified_id'] for r in retained['future_proof_register'] if r['source_step']==327 and r['qualified_id'] not in crossrows[node]['future_proofs']],
                          required_capabilities=crossrows[node]['capabilities'],
                          required_cross_obligations=crossrows[node]['cross_obligations'],
                          required_conformance_case_ids=crossrows[node]['conformance_case_ids'],
                          dispatch_blocked=True,
                          classification='forbidden-or-unknown-domain' if original['rights_scope']=='forbidden' else 'contract-bound-candidate-actual-component-unselected',
                          actual_implementation_path=None,actual_implementation_sha256=None,
                          actual_writers=None,actual_dependencies=None,actual_lifetimes=None,
                          actual_evidence=None,operational_proven=False))
    sources=[dict(path=p,sha256=sha(history[p]),size_bytes=len(history[p]),role=role,
                  selected_actual_implementation=False) for p,role in SOURCE_ROLES.items()]
    edges=[dict(source=a,target=b,kind='inherited-macro-design-relation-not-runtime-call-edge',
                actual_edge_proven=False,actual_binding=None,dispatch_authorized=False)
           for a,b in graph['catalogue_edges']]
    return dict(schema=1,step=330,scope='repository-source-bound-candidate-inventory-only',
                source_roles=sources,reference_segments=reference,private_python_definitions=definitions,
                lexical_ambiguity_candidates={p:lexical_ambiguities(history[p]) for p in [REFERENCE,PRIVATE,PRIVATE_ENTRY,FROZEN_BODY]},
                candidate_nodes=nodes,candidate_edges=edges,
                inherited_counts=retained['crossclosure_counts'],
                inherited_platform_cases=[dict(platform=r['platform'],case_id=r['case_id'],status=r['status'],result=r['result']) for r in retained['independent_conformance_plan']],
                inherited_obligations_binding=dict(path=FIXTURE+'/'+PRIOR+'-retained-obligations.json',sha256=sha(history[FIXTURE+'/'+PRIOR+'-retained-obligations.json'])),
                all_actual_selection_gaps=[dict(id=x,status='required-not-selected-or-proven',actual_binding=None,actual_evidence=None) for x in GAPS],
                actual_dynamic_graph_complete=False,actual_successor_entry_selected=False,
                actual_operational_implementation_frozen=False,operational_conformance=False,
                operational_readiness=False,runtime_authority=False,
                historical_v2_or_reference_main_sourced_run=False,
                actual_host_state='unobserved-not-claimed-absent',actual_live_bindings=None,
                machine_action_required=False,controller_action_required=False,
                user_step330_checkpoint_confirmed=False,strong_safe_pause=False,
                last_confirmed_strong_safe_pause_step=328,
                next_stage='331-inert-successor-phase-map-after-complete330-return',
                stop_rule='Any missing/unclassified actual dependency or effect blocks real dispatch; static source binding cannot satisfy operational closure or waive original proofs.')

def validate_inventory(value,history,retained,graph,cross):
    expected=build_inventory(history,retained,graph,cross)
    exact(value,expected,'strict source-bound candidate inventory and preserved blockers')
    exact(len(value['candidate_nodes']),30,'all30 domains');exact(len(value['candidate_edges']),95,'all95 designed relations')
    exact(len(retained['future_proof_register']),46,'all46 future proofs retained')
    exact(len(retained['independent_conformance_plan']),52,'all52 future cases retained')
    return True

def inventory_repository_status(value):
    # This pure summary consumes no grant and deliberately has no operational entry.
    keys=['origin','known_macro_node','actual_implementation_selected','actual_dependencies_closed','actual_native_proofs_complete','both_platforms_independently_proven']
    exact(sorted(value),sorted(keys),'summary schema')
    exact(value['origin'],'synthetic-private-fixture','private origin')
    if any(type(value[k]) is not bool for k in keys if k!='origin'):raise ValueError('bool summary fields required')
    return dict(repository_inventory_row_eligible=value['known_macro_node'],
                actual_runtime_dispatch_authorized=False,actual_grant_issued=False,
                actual_graph_proven=False,actual_operational_conformance=False)

def validate_confirmation(c,r):
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed329 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original329 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),271,'complete271 return')
    exact(lines.count('Result: PASS (271 passes, 0 failures)'),1,'271 summary')
    return True

def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step330-exact329-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=271 or lines.count('Result: PASS (271 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact271 predecessor acceptance failed')
        return result.stdout

def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed330 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    history=verify_history(root,load('-policy.json'))
    retained=json.loads(history[FIXTURE+'/'+PRIOR+'-retained-obligations.json'])
    graph=json.loads(history[retained['successor_contract_bindings']['325']['path']])
    cross=json.loads(history[retained['successor_contract_bindings']['327']['path']])
    validate_inventory(load('-inventory.json'),history,retained,graph,cross)
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step329-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-inventory.json','-checkpoint-confirmation.json','-step329-user-acceptance.json','-candidate-nodes.tsv','-candidate-edges.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,load('-policy.json')).items()},
          {r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'330 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step329_acceptance\tPASS (271 passes, 0 failures)')
    print('step330_source_bound_candidate_graph_inventory_status\tPASS')
    print('candidate_domains_and_macro_relations\t30/95')
    print('actual_dynamic_graph_complete\tno')
    print('actual_dispatch_or_publication_authorized\tno')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user330-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)
PYREVIEW
