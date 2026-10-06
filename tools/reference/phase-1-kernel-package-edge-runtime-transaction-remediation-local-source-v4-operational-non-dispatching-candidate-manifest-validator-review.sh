#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only non-dispatching candidate manifest validator; no shell sourcing or runtime dispatch.\n' "${0##*/}"
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
    exact(sha(encoded(bindings)),BASELINE_SHA256,'accepted1575 manifest')
    exact(len(bindings),1575,'accepted1575 count')
    history={}
    for rel,digest in bindings.items():
        raw=safe_file(root,rel)
        if rel=='CHANGELOG.md':
            prefix=CHANGELOG_PREFIX.encode()
            exact(raw[:len(prefix)].hex(),prefix.hex(),'333 CHANGELOG prefix')
            exact(len(raw),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            raw=raw[len(prefix):]
        exact(sha(raw),digest,'accepted artifact drift '+rel);history[rel]=raw
    return history
def validate_confirmation(c,r):
    exact(sha(encoded(c)),CONFIRMATION_SHA256,'external confirmed332 receipt')
    exact(sorted(r),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt schema')
    exact(r['encoding'],'utf8-json-text','receipt encoding')
    exact(sha(r['text'].encode()),RECEIPT_SHA256,'complete original332 return')
    exact(r['original_display_sha256'],RECEIPT_SHA256,'receipt SHA metadata')
    exact(len(r['text'].encode()),RECEIPT_SIZE,'receipt size')
    exact(r['original_display_size_bytes'],RECEIPT_SIZE,'receipt size metadata')
    lines=r['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines),1429,'complete1429 return')
    exact(lines.count('Result: PASS (1429 passes, 0 failures)'),1,'1429 summary')
    return True
def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step332-exact332-') as directory:
        snapshot=Path(directory)/'slack-update'
        for rel,content in history.items():
            p=snapshot/safe_relative(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
        result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines=result.stdout.decode().splitlines()
        if result.returncode or sum(x.startswith('PASS: ') for x in lines)!=1429 or lines.count('Result: PASS (1429 passes, 0 failures)')!=1:
            sys.stderr.buffer.write(result.stdout+result.stderr);raise ValueError('full exact1429 predecessor acceptance failed')
        return result.stdout
BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_SHA256 = '1c98c497cd1a362fb6dccf6a68b7e2fd88b12ea82bc2025f6f35e9eca7154df4'
CHANGELOG_PREFIX = '## Phase 1 step333 — non-dispatching candidate manifest validator — 2026-10-06\n\n- Confirmed step332 at prefix 0e9646f from complete ordered 1429 PASS matching prepared and installed output, successful first push, clean tree and matching HEAD/origin. Complete original return and external confirmation retained; full object ID unknown. Prepared step332 flags/history and corrected generator setup failure remain unchanged. Step328 is the last confirmed strong pause.\n- Preserve all 1575 accepted artifacts except additive CHANGELOG; nine new repository files. Rerun exact 1429 predecessor acceptance and all nested historical coverage. Select successor-inert-candidate-manifest-v1 as data only: 30 component domains, 95 inherited macro design relations, 27 ordered phase boundaries, 26 nominal interfaces, 35 type references, 85 phase/interface declarations and 13 inherited data path/SHA bindings. No native entry or dispatcher selected.\n- Closed bounded UTF8 JSON parser rejects duplicate keys, floats/nonfinite constants, malformed bytes, scalar roots and excessive bytes/depth/nodes/strings/integers. Manifest validator resolves component/phase/interface/type/qualified-proof/source-digest references and caller actor/original rights contexts, then requires exact inherited source obligations. All macro relations remain designed, unproven and without dispatch authority.\n- Preserve all eight step320–327 source views, 13 historical stages, nine authority windows, seven capabilities, ten cross obligations, 46 required-not-proven qualified proofs, 52 independent required-not-run cases and 16 actual selection/refinement gaps. Four forbidden/unknown domains have no interface. Actual component paths/SHA/writers/dependencies/lifetimes/evidence/live bindings remain null; no proof waiver or runtime freeze/readiness inference from declaration validity.\n- Original barrier/irreversible claim/pre-spent single launch/bounded offline bootstrap/no broker capability, traps/continuous guard/fresh original/backups, one raw pkglist pin, explicit nine-step owned stage7 commit, full effect/nested argv/selector/raw-status/sticky latch, finite original recovery/child drain and separate target-release/publication/last-receipt rules remain exact. Nominal phase uses do not imply runtime call ordering, authenticated linear handles or native fault/conformance proof.\n- No inspected source, reference main or frozenv2 sourced/run; no runtime/preflight/refresh/namespace/package/target/restore/operational publication/service channel or new batch cleanup. Host unobserved, never absent/globally closed. Step333 user acceptance pending; step334 failure-refinement mapping follows complete return. Step338 conditional scoped candidate pause remains target; production/Phase2 closed, Phase1/kernel incomplete.\n\n'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review.md': '706c32ed7ec0837974a86b9e2272143e3abd97c564018e1d98af1e9cb21777c2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-policy.json': 'e09231f55ff366b178f26197782f147c5f1e21b3a517e724d1b9b37e06731825', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-manifest.json': '5c1d5b951acc8aef08c80051e74814cf64f94cccc1a585def6d2355be978aa71', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-validation-report.json': '3893123409d05ceaffff1a8c8657684f5a4b1b979d56d8b37416e5bbebe51bd9', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-checkpoint-confirmation.json': '5c6f5efb1512fa6b5c01dc8e3c619456d41ae38e86b90aad799ef03d856a6114', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-step332-user-acceptance.json': '0056688b4b54f1c74c27cda8cf4578225e32803f46d3294fdc5755e2dec7d3e1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-non-dispatching-candidate-manifest-validator-review-artifact-bindings.tsv': '9ef6d3742bfb253e909c3fb1060235f7ce463bd1ff95ab163b25e4a857c41af9'}
CONFIRMATION_SHA256 = '5c6f5efb1512fa6b5c01dc8e3c619456d41ae38e86b90aad799ef03d856a6114'
RECEIPT_SHA256 = 'd2979f07eacf54671291def913abb62e8ea20761e6a21e8afed93baa51886c41'
RECEIPT_SIZE = 146649
CATALOG_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-interfaces.json'
TYPES_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-typed-primitive-interface-contract-review-types.json'
# Closed inert manifest parsing and source-reference validation, never dispatch.
MANIFEST_LIMIT_BYTES=1048576
MANIFEST_LIMIT_NODES=50000
MANIFEST_LIMIT_DEPTH=32

def parse_candidate_manifest(raw):
    if type(raw) is not bytes or not 1<=len(raw)<=MANIFEST_LIMIT_BYTES:raise ValueError('bounded bytes required')
    def object_pairs(pairs):
        result={}
        for key,value in pairs:
            if key in result:raise ValueError('duplicate JSON object key')
            result[key]=value
        return result
    def no_number(value):raise ValueError('floats and nonfinite constants forbidden')
    try:value=json.loads(raw.decode('utf-8'),object_pairs_hook=object_pairs,parse_float=no_number,parse_constant=no_number)
    except (UnicodeError,json.JSONDecodeError,RecursionError) as exc:raise ValueError('invalid bounded UTF8 JSON') from exc
    nodes=0
    def walk(v,depth):
        nonlocal nodes
        nodes+=1
        if nodes>MANIFEST_LIMIT_NODES or depth>MANIFEST_LIMIT_DEPTH:raise ValueError('bounded JSON shape exceeded')
        if type(v) is dict:
            for k,x in v.items():walk(k,depth+1);walk(x,depth+1)
        elif type(v) is list:
            for x in v:walk(x,depth+1)
        elif type(v) is str:
            if len(v)>65536:raise ValueError('JSON string too large')
        elif type(v) is int:
            if not -(2**63)<=v<2**63:raise ValueError('JSON integer out of bounds')
        elif type(v) not in (bool,type(None)):raise ValueError('unsupported JSON scalar')
    walk(value,0)
    if type(value) is not dict:raise ValueError('manifest must be a JSON object')
    return value

def build_candidate_manifest(history,catalog,inventory,retained):
    phase=catalog['inherited_phase_contract'];interfaces={r['id']:r for r in catalog['interfaces']}
    paths=[CATALOG_PATH,TYPES_PATH,catalog['phase_map_binding']['path'],phase['inherited_inventory_binding']['path'],inventory['inherited_obligations_binding']['path']]
    # Frozen binding register is keyed by source step, with path/hash inside values.
    paths+=[v['path'] for v in phase['preserved_integration_contract_bindings'].values()]
    bindings=[dict(path=p,sha256=sha(history[p]),kind='inherited-readonly-data-not-native-component') for p in paths]
    components=[]
    for n in inventory['candidate_nodes']:
        interface=interfaces.get(n['id'])
        components.append(dict(id=n['id'],classification=n['classification'],designed_node=n['designed_node'],
                               historical_source_anchors=n['historical_source_anchors'],
                               interface_binding=dict(id=interface['id'],version=interface['version'],canonical_sha256=sha(encoded(interface))) if interface else None,
                               phase_ids=next(r['phase_ids'] for r in phase['node_phase_map'] if r['id']==n['id']),
                               required_future_proofs=n['required_future_proofs'],
                               actual_implementation_path=None,actual_implementation_sha256=None,actual_writers=None,
                               actual_dependencies=None,actual_lifetimes=None,actual_evidence=None,
                               dispatch_blocked=True,operational_proven=False))
    phases=[]
    for r in phase['entry_trace']:
        uses=[dict(interface_id=i['id'],version=i['version'],provider_role=i['provider_role'],
                   caller_actor=p['caller_actor'],rights_window=p['rights_window'],
                   input_types=i['input_types'],success_output_types=i['success_output_types'],dispatch_authorized=False)
              for i in catalog['interfaces'] for p in i['allowed_phase_contexts'] if p['id']==r['id']]
        phases.append(dict(declared_boundary=r,nominal_interface_uses=uses,
                           scope='declaration-cross-index-not-runtime-call-order-or-proof',actual_dispatcher=None))
    return dict(schema=1,step=333,scope='repository-non-dispatching-candidate-manifest-only',
                selected_candidate_version='successor-inert-candidate-manifest-v1',artifact_bindings=bindings,
                components=components,macro_design_relations=inventory['candidate_edges'],phases=phases,
                type_bindings=[dict(name=t['name'],canonical_sha256=sha(encoded(t)),actual_native_ABI=None) for t in catalog['type_definitions']],
                exact_phase_contract=phase,qualified_proof_register=retained['future_proof_register'],
                authority_windows=retained['authority_windows'],seven_requirements_bindings=retained['seven_requirements_bindings'],
                preserved_cross_obligations=retained['preserved_cross_obligations'],
                independent_platform_cases=inventory['inherited_platform_cases'],actual_selection_gaps=inventory['all_actual_selection_gaps'],
                actual_entry_path=None,actual_dispatcher=None,actual_live_bindings=None,
                actual_dynamic_graph_complete=False,actual_native_primitives_selected=False,
                actual_implementation_frozen=False,operational_conformance=False,operational_readiness=False,
                runtime_authority=False,actual_host_state='unobserved-not-claimed-absent',actual_global_host_closure_asserted=False,
                historical_v2_or_reference_main_sourced_run=False,machine_action_required=False,controller_action_required=False,
                user_step333_checkpoint_confirmed=False,strong_safe_pause=False,last_confirmed_strong_safe_pause_step=328,
                next_stage='334-failure-refinement-mapping-and-gaps-after-complete333-return')

def validate_candidate_manifest(value,history,catalog,inventory,retained):
    if type(value) is not dict or type(value.get('schema')) is not int or type(value.get('step')) is not int:raise ValueError('closed manifest schema integer types')
    # Establish cross-reference consistency independently of source equality checks.
    def unique(rows,key,label):
        if type(rows) is not list or any(type(r) is not dict for r in rows):raise ValueError(label+' rows')
        ids=[r[key] for r in rows]
        if any(type(x) is not str for x in ids) or len(set(ids))!=len(ids):raise ValueError(label+' duplicate or invalid ID')
        return set(ids)
    components=value['components'];component_ids=unique(components,'id','components')
    interfaces={r['id']:r for r in catalog['interfaces']};types=unique(catalog['type_definitions'],'name','types')
    phases=value['phases'];phase_ids=unique([r['declared_boundary'] for r in phases],'id','phases')
    proof_ids=unique(value['qualified_proof_register'],'qualified_id','proofs')
    for binding in value['artifact_bindings']:
        rel=binding['path'];safe_relative(rel)
        if rel not in history:raise ValueError('manifest binding outside accepted source')
        exact(binding['sha256'],sha(history[rel]),'bound artifact byte drift')
    for n in components:
        if type(n['dispatch_blocked']) is not bool or not n['dispatch_blocked']:raise ValueError('component dispatch forbidden')
        if not set(n['phase_ids'])<=phase_ids or not set(n['required_future_proofs'])<=proof_ids:raise ValueError('unresolved phase or qualified proof reference')
        b=n['interface_binding']
        if b is not None:
            if b['id']!=n['id'] or b['id'] not in interfaces:raise ValueError('unresolved or crossed interface reference')
            exact(b['canonical_sha256'],sha(encoded(interfaces[b['id']])),'interface contract digest')
        elif n['id'] in interfaces:raise ValueError('required nominal interface omitted')
    for edge in value['macro_design_relations']:
        if edge['source'] not in component_ids or edge['target'] not in component_ids:raise ValueError('unknown macro relation endpoint')
        exact(edge['actual_edge_proven'],False,'macro design edge never actual proof');exact(edge['dispatch_authorized'],False,'macro design edge never dispatch')
    for row in phases:
        boundary=row['declared_boundary']
        for use in row['nominal_interface_uses']:
            i=interfaces.get(use['interface_id'])
            if i is None:raise ValueError('unknown or forbidden phase interface')
            context=dict(id=boundary['id'],caller_actor=use['caller_actor'],rights_window=use['rights_window'])
            if context not in i['allowed_phase_contexts']:raise ValueError('phase actor rights crossing')
            if not set(use['input_types']+use['success_output_types'])<=types:raise ValueError('unresolved nominal type reference')
            exact(use['dispatch_authorized'],False,'inert declaration no call authority')
    exact(value,build_candidate_manifest(history,catalog,inventory,retained),'exact source-bound manifest no waiver or extra field')
    return dict(candidate_declaration_valid=True,native_selection_or_evidence_complete=False,
                component_domains=len(components),macro_design_relations=len(value['macro_design_relations']),
                phase_boundaries=len(phases),nominal_interfaces=len(interfaces),nominal_types=len(types),
                required_not_proven_proofs=len(proof_ids),required_not_run_cases=len(value['independent_platform_cases']),
                unresolved_native_gap_categories=len(value['actual_selection_gaps']),
                actual_dispatch_authorized=False,actual_operational_implementation_frozen=False,
                actual_operational_conformance=False,actual_operational_readiness=False,
                actual_host_closure=False,actual_target_or_publication_closure=False)


def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed333 artifact '+rel)
    load=lambda suffix:json.loads(safe_file(root,FIXTURE+'/'+BASE+suffix))
    policy=load('-policy.json');history=verify_history(root,policy);catalog=json.loads(history[CATALOG_PATH])
    phase=catalog['inherited_phase_contract'];inventory=json.loads(history[phase['inherited_inventory_binding']['path']])
    retained=json.loads(history[inventory['inherited_obligations_binding']['path']])
    manifest=parse_candidate_manifest(safe_file(root,FIXTURE+'/'+BASE+'-manifest.json'))
    report=validate_candidate_manifest(manifest,history,catalog,inventory,retained)
    exact(report,load('-validation-report.json'),'declaration report never native completion')
    validate_confirmation(load('-checkpoint-confirmation.json'),load('-step332-user-acceptance.json'))
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    suffixes=['-policy.json','-manifest.json','-validation-report.json','-checkpoint-confirmation.json','-step332-user-acceptance.json','-artifact-bindings.tsv']
    payloads={BASE+s:safe_file(root,FIXTURE+'/'+BASE+s) for s in suffixes};logname=BASE+'-predecessor-test.log'
    if any((out/n).exists() or (out/n).is_symlink() for n in list(payloads)+[logname]):raise ValueError('occupied private output; no overwrite')
    payloads[logname]=run_historical(history)
    exact({r:sha(c) for r,c in verify_history(root,policy).items()},{r:sha(c) for r,c in history.items()},'history changed during private validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'333 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step332_acceptance\tPASS (1429 passes, 0 failures)')
    print('step333_non_dispatching_candidate_manifest_status\tPASS')
    print('component_domains_macro_relations_phases_interfaces_types\t30/95/27/26/35')
    print('actual_native_dispatch_or_proof_authorized\tno')
    print('required_proofs_and_independent_cases\t46-unproven/52-unrun')
    print('last_confirmed_strong_safe_pause_step\t328')
    print('strong_safe_pause\tno-user333-acceptance-pending')
    print('operational_readiness\tno')

if __name__=='__main__':
    try:main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError,SyntaxError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)

PYREVIEW
