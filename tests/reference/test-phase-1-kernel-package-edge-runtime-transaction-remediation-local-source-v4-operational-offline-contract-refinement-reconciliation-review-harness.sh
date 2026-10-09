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
import runpy
import subprocess
import sys
import tempfile
import time

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review'
prefix = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
review_path = root / 'tools/reference' / (base + '.py')
review = runpy.run_path(str(review_path))
passes = 0


def check(label, condition):
    global passes
    if not condition:
        raise AssertionError(label)
    passes += 1
    print('PASS: ' + label, flush=True)


def rejects(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, TypeError, OSError):
        return True
    return False


def load(tail):
    return json.loads((fixture / (base + '-' + tail + '.json')).read_bytes())


def execute(command):
    # Progress stays on stderr, outside exact ordered acceptance labels. Child
    # stdout is kept intact and compared only after successful completion.
    with tempfile.TemporaryFile(mode='w+b') as out, tempfile.TemporaryFile(mode='w+b') as err:
        child = subprocess.Popen([str(x) for x in command], stdout=out, stderr=err)
        started = time.monotonic()
        while True:
            try:
                code = child.wait(timeout=30)
                break
            except subprocess.TimeoutExpired:
                print('Repository-only recursive suite still running (' + str(int(time.monotonic()-started)) + 's).', file=sys.stderr, flush=True)
        out.seek(0); err.seek(0)
        stdout, stderr = out.read().decode('utf-8'), err.read().decode('utf-8')
    if code:
        sys.stderr.write(stdout[-5000:] + stderr[-5000:])
    return code, stdout, stderr


history = review['verify'](root)
policy = load('policy')
reconciliation = load('reconciliation')
mapping = load('rule-map')
gaps = load('native-gap-register')
receipt = load('step346-user-acceptance')
confirmation = load('checkpoint-confirmation')
check('all1701 accepted346 source bytes preserved', len(history) == 1701)
check('full original Markdown receipt bound without rewriting', review['validate_return'](confirmation, receipt, policy))
check('all616 literal Markdown labels exactly ordered', review['extract_markdown_labels'](receipt['text']) == policy['accepted_ordered346_labels'])
check('reported038c896 push clean matching HEAD origin accepted', confirmation['commit_prefix'] == '038c896' and confirmation['user_head_matches_origin'] and confirmation['user_worktree_clean'])
check('full contract reconciliation accepted', review['validate_reconciliation'](reconciliation, history))
check('every model definition and conditional guard source indexed', review['validate_rule_map'](mapping, reconciliation, history))
check('full native gap event and finite coverage register accepted', review['validate_gap_register'](gaps, reconciliation, mapping, history))
retained = reconciliation['retained_full_normative_rows']
counts = {'effect_domain_reconciliation':30, 'all95_macro_design_relations':95,
 'all27_phase_boundaries':27, 'all26_nominal_interfaces':26, 'all35_nominal_types':35,
 'qualified_proof_reconciliation':46, 'authority_window_reconciliation':9,
 'seven_capability_reconciliation':7, 'ten_cross_obligation_reconciliation':10,
 'macro_cut_obligations':81, 'owned_stage7_microsteps':9,
 'native_case_templates':52, 'native_gap_register':16}
for key, count in counts.items():
    check('full original retained register ' + key, len(retained[key]) == count)
    bad = copy.deepcopy(reconciliation)
    bad['retained_full_normative_rows'][key] = bad['retained_full_normative_rows'][key][:-1]
    check('missing full original row blocks reconciliation ' + key, rejects(review['validate_reconciliation'], bad, history))
for step, original in retained['exact_contract_views'].items():
    check('full normative source view retained ' + step, original is not None and len(original) > 0)
    bad = copy.deepcopy(reconciliation)
    bad['retained_full_normative_rows']['exact_contract_views'][step] = {}
    check('digest cannot replace full normative contract ' + step, rejects(review['validate_reconciliation'], bad, history))
for key in ('runtime_authority','actual_operational_implementation_frozen','operational_conformance','operational_readiness','phase1_matrix_complete','kernel_package_edge_complete','phase2_open','strong_safe_pause','repository_reconciliation_is_native_refinement'):
    bad = copy.deepcopy(reconciliation); bad[key] = True
    check('private review cannot promote native fact ' + key, rejects(review['validate_reconciliation'], bad, history))
for key in ('native_cases_run','native_proofs_added'):
    for value in (True, 1):
        bad = copy.deepcopy(reconciliation); bad[key] = value
        check('no native evidence or bool int coercion ' + key + '/' + repr(value), rejects(review['validate_reconciliation'], bad, history))
for key, value in [('actual_host_state','absent'),('actual_live_bindings',{'boot':'historical'}),('repository_source_conflicts_found',['unresolved-conflict']),('current347_user_acceptance_pending',False)]:
    bad = copy.deepcopy(reconciliation); bad[key] = value
    check('conflict host or historical binding remains blocker ' + key, rejects(review['validate_reconciliation'], bad, history))
for row in mapping['phase_rows']:
    phase = row['id']
    check('exact typed source phase positive views retained ' + phase, row['native_proof'] is False and row['actual_native_event_mapping'] is None and bool(row['native_gap_ids']))
    check('source phase full proofs cases macro cuts associated ' + phase, bool(row['inherited_links']['qualified_proof_ids']) and bool(row['inherited_links']['native_case_tuples']) and len(row['inherited_links']['macro_cut_ids']) == 3)
for family in mapping['modules']:
    check('all source definitions guards and unresolved events retained ' + family, any(x['family'] == family for x in mapping['rule_rows']) and any(x['family'] == family for x in gaps['unresolved_event_rows']))
bad = copy.deepcopy(mapping); bad['rule_rows'] = bad['rule_rows'][:-1]
check('missing conditional rule blocks source reconciliation', rejects(review['validate_rule_map'], bad, reconciliation, history))
bad = copy.deepcopy(mapping); bad['rule_rows'][0]['source_span_sha256'] = '0'*64
check('changed rule span cannot pass source index', rejects(review['validate_rule_map'], bad, reconciliation, history))
bad = copy.deepcopy(mapping); bad['phase_rows'][0]['positive_view_contracts'] = {}
check('missing positive view contract blocks phase reconciliation', rejects(review['validate_rule_map'], bad, reconciliation, history))
bad = copy.deepcopy(mapping); bad['rule_rows'][0]['inherited_links']['native_case_tuples'] = [['platform','case_id']]
check('native case field names cannot replace actual platform case associations', rejects(review['validate_rule_map'], bad, reconciliation, history))
bad = copy.deepcopy(mapping); bad['phase_rows'][0]['native_proof'] = True
check('phase mapping never native proof', rejects(review['validate_rule_map'], bad, reconciliation, history))
check('both native platforms retain exactly26 unrun templates', all(sum(x['platform'] == platform for x in retained['native_case_templates']) == 26 for platform in ('Slackware-15.0','Slackware-current')))
for index, row in enumerate(gaps['native_gap_rows']):
    gap_id = row['inherited_gap']['id']
    check('native obligation remains unresolved ' + gap_id, row['native_status_promoted'] is False and row['actual_independent_evidence'] is None and row['actual_native_event_relation'] is None)
    bad = copy.deepcopy(gaps); bad['native_gap_rows'][index]['native_status_promoted'] = True
    check('model progress cannot promote native gap ' + gap_id, rejects(review['validate_gap_register'], bad, reconciliation, mapping, history))
check('separate private clock boundary retained', 'admission/forward' in gaps['clock_boundary'] and 'durable global once' in gaps['clock_boundary'])
check('all original source macro cuts are not native syscall coverage', 'not syscall/crash/concurrency coverage' in gaps['macro_cut_boundary'])
for transform in ('lost-label','duplicate-label','reverse-labels','lost-push','changed-created-path'):
    bad = copy.deepcopy(receipt)
    if transform == 'lost-label':
        bad['text'] = bad['text'].replace(policy['accepted_ordered346_labels'][0] + ' ', '', 1)
    elif transform == 'duplicate-label':
        bad['text'] = bad['text'].replace(policy['accepted_ordered346_labels'][0], policy['accepted_ordered346_labels'][0] + ' ' + policy['accepted_ordered346_labels'][0], 1)
    elif transform == 'reverse-labels':
        first, second = policy['accepted_ordered346_labels'][:2]
        bad['text'] = bad['text'].replace(first + ' ' + second, second + ' ' + first, 1)
    elif transform == 'lost-push':
        bad['text'] = bad['text'].replace('8f6b3cd..038c896  main -> main', 'push-unknown', 1)
    else:
        bad['text'] = bad['text'].replace(' create mode 100644 docs/', ' create mode 100644 altered/', 1)
    raw = bad['text'].encode(); bad['original_display_sha256'] = hashlib.sha256(raw).hexdigest(); bad['original_display_size_bytes'] = len(raw)
    confirm = copy.deepcopy(confirmation); confirm['evidence_sha256'] = bad['original_display_sha256']; confirm['evidence_size_bytes'] = len(raw)
    check('complete original return boundary rejects ' + transform, rejects(review['validate_return'], confirm, bad, policy))
for argv in ([],['--bogus'],['--check'],['--check','']):
    check('strict347 reviewer CLI ' + repr(argv), review['main'](argv) == 2)
code, stdout, stderr = execute(['python3','-B',review_path,'--check',root])
check('current source-bound347 CLI review passes', code == 0 and 'step347_offline_contract_reconciliation_status\tPASS' in stdout)
check('last confirmed pause remains338 and current347 pending', reconciliation['last_confirmed_strong_safe_pause_step'] == 338 and not reconciliation['strong_safe_pause'] and reconciliation['current347_user_acceptance_pending'])

with tempfile.TemporaryDirectory(prefix='step347-full-source-') as directory:
    accepted346 = Path(directory) / 'accepted346'; accepted346.mkdir()
    for relative, raw in history.items():
        p = accepted346 / relative; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(raw)
    code, stdout, stderr = execute(['python3','-B',accepted346 / policy['predecessor_verifier'],'--check',accepted346])
    check('unchanged346 reviewer accepts exact1701 historical bytes', code == 0)
    print('Running unchanged346 recursive pure suites.', file=sys.stderr, flush=True)
    code, stdout, stderr = execute(['bash',accepted346 / policy['predecessor_harness']])
    check('unchanged346 full616 recursive model suite passes', code == 0 and stdout.splitlines().count('Result: PASS (616 passes, 0 failures)') == 1)
    check('all616 predecessor labels exactly match original accepted order', [x for x in stdout.splitlines() if x.startswith('PASS: ')] == policy['accepted_ordered346_labels'])
    old_policy = review['historical_json'](history, 'offline-transition-core-resume-planning-review-policy')
    accepted338 = Path(directory) / 'accepted338'; accepted338.mkdir()
    for relative, digest in old_policy['baseline_sha256_bindings'].items():
        raw = history[relative]
        if relative == 'CHANGELOG.md': raw = raw[-old_policy['accepted_changelog_size']:]
        if hashlib.sha256(raw).hexdigest() != digest: raise AssertionError('exact historical338 source SHA')
        p = accepted338 / relative; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(raw)
    check('full1629-file338 source restored exactly without historical edits', len(old_policy['baseline_sha256_bindings']) == 1629)
    print('Running full unchanged338 recursive historical suite; this may take several minutes.', file=sys.stderr, flush=True)
    code, stdout, stderr = execute(['bash',accepted338 / policy['historical_full_harness']])
    check('full unchanged338 recursive364 suite passes', code == 0 and stdout.splitlines().count(policy['historical_full_result']) == 1)
    check('all364 historical labels match complete accepted338 return', [x for x in stdout.splitlines() if x.startswith('PASS: ')] == policy['full338_ordered_labels'])

check('all accepted bytes retained after full reconciliation suites', review['verify'](root) == history)
print('Result: PASS (' + str(passes) + ' passes, 0 failures)', flush=True)
PYTEST
