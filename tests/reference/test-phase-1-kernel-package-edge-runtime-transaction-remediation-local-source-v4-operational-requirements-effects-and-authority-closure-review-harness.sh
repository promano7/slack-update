#!/bin/bash
set -euo pipefail
export LC_ALL=C
[[ $# -eq 0 ]] || { printf 'ERROR: harness takes no arguments\n' >&2; exit 2; }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
import ast
import copy
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-effects-and-authority-closure-review'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
tool = root / 'tools/reference' / (base + '.sh')
passes = 0


def check(label, condition):
    global passes
    if not condition:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label, flush=True)


def rejected(function, *args):
    try:
        function(*args)
    except (ValueError, KeyError, TypeError, OSError):
        return True
    return False


def run(argv):
    return subprocess.run([str(x) for x in argv], capture_output=True, text=True)


check('exact317 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '011d6625b43e32cb3c4fe7f07b3dd0261b9fb50931f6ec53e5d9716a905a092d')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step317_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step316-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1429 accepted bytes and original CHANGELOG suffix',len(history)==1429)
check('confirmed316 full1203 first-push return and clean HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('cross dependency effects and authority requirements accepted',ns['validate_review'](review,facts,prior))
check('typed closed317 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared316 wording retained with external confirmation',prior['user_step316_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('all actual owner/path/publication bindings absent',all(value is None for value in review['operational_cross_bindings'].values()))
check('seven prior reviews and no remaining separate capability reviews',len(review['previously_reviewed_requirements'])==7 and review['other_deferred_capabilities']==[])
check('all seven reviews still operationally incomplete',review['proof_state']['operational_capability_complete'] is False and policy['operational_readiness'] is False)
check('mandatory private coverage preserved',review['candidate_sha256_bindings']==prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests']==prior['frozen_private_scope']['mandatory_tests'])
check('frozen owned root0700 publication0600 and promano/users retained',facts['path_design']['owned_root_mode']=='0700' and facts['path_design']['publication_mode']=='0600' and facts['path_design']['publication_owner']=='promano:users')
check('all actual path values remain symbolic/unbound',facts['path_design']['transaction_root'] is None and facts['path_design']['scope']=='symbolic-proposal-only-actual-paths-require-later-grant')
check('pair not atomic and external receipt last preserved',facts['publication_design']['archive_sidecar_pair_atomicity_claim'] is False and facts['publication_design']['receipt_committed_last'] is True)
check('partial publication and unsafe restore keep distinct obligations',facts['publication_design']['incomplete_archive_sidecar_or_receipt_keeps_pending_controller_obligations'] is True and facts['cleanup_design']['unsafe_restore_or_boot_drift_keeps_pending_machine_obligations'] is True)
check('child quiescence before restore preserved',facts['child_supervision_design']['child_quiescence_required_before_restore'] is True)
check('314 claim/traps gap remains operational blocker','314-durable-claim-traps-gap-retained' in review['blockers'])
for rel,digest in ns['OWN_HASHES'].items():
    check('exact bound317 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

def mutate(value, path, replacement):
    changed = copy.deepcopy(value)
    slot = changed
    for key in path[:-1]:
        slot = slot[key]
    slot[path[-1]] = replacement
    return changed


def bad_policy(label, path, value):
    check('rejects ' + label, rejected(ns['validate_policy'], mutate(policy,path,value), confirmation, receipt, prior, review))


for key,value in policy.items():
    if type(value) is bool or value is None:
        bad_policy('premature316 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
for key in ['schema','step','new_repository_artifact_count','prepared_repository_file_count']:
    bad_policy('wrong numeric or bool type ' + key,[key],True)
for key in policy['authorization']:
    bad_policy('opened inherited authority ' + key,['authorization',key],True)
for key,value in policy['fresh_boundary'].items():
    bad_policy('invented operational slot ' + key,['fresh_boundary',key],'stale-binding' if value is None else not value)
for key,value in policy['repository_stage_permission'].items():
    if type(value) is bool:
        bad_policy('widened or incomplete stage permission ' + key,['repository_stage_permission',key],not value)
for path,value in [(['accepted_checkpoint','commit_full'],'f'*40),(['accepted_checkpoint','sha256_bindings'],{}),(['accepted_checkpoint','sha256_bindings','CHANGELOG.md'],'0'*64),(['review_sha256'],'0'*64),(['other_deferred_capabilities'],['unreviewed-capability']),(['previously_reviewed_requirements'],[]),(['frozen_private_scope','mandatory_tests'],[]),(['next_stage'],'wrong-stage')]:
    bad_policy('changed policy identity or coverage ' + '.'.join(path),path,value)
extra = dict(policy, live_use_authorized=True)
check('unknown live authority field rejected', rejected(ns['validate_policy'],extra,confirmation,receipt,prior,review))
for key,value in confirmation.items():
    if type(value) is bool or value is None:
        check('rejects confirmation evidence invention ' + key,rejected(ns['validate_confirmation'],mutate(confirmation,[key],not value if type(value) is bool else 'invented'),receipt))
check('wrong confirmed commit prefix rejected',rejected(ns['validate_confirmation'],mutate(confirmation,['commit_prefix'],'fffffff'),receipt))
for key,value in dict(text=receipt['text'][:-1],original_display_sha256='0'*64,original_display_size_bytes=True,encoding='unknown').items():
    check('original316 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened owner/publication requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_cross_bindings']:
    check('rejects invented live publication binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_cross_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['seven_review_bindings'],[]),(['cross_dependency_map'],[]),(['effects_authority_closure'],[]),(['blockers'],[]),(['other_deferred_capabilities'],['eighth']),(['capability'],'invented'),(['prohibited_current_effects'],[])]:
    check('cross review scope drift rejects '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
check('all seven review bytes and closed policies bound',ns['validate_bundle'](history,review))
for i,row in enumerate(review['seven_review_bindings']):
    for key,new in [('review_sha256','0'*64),('policy_sha256','0'*64),('step',True),('capability','invented')]:
        check('separate dependency identity drift rejected '+str(row['step'])+' '+key,rejected(ns['validate_bundle'],history,mutate(review,['seven_review_bindings',i,key],new)))
    check('separate requirement review remains operationally incomplete '+str(row['step']),row['requirements_status']=='reviewed-not-operationally-complete' and row['operational_conformance'] is False)
record=(fixture/(base+'.tsv')).read_bytes();roles=(fixture/(base+'-cross-dependency-matrix.tsv')).read_bytes();matrix=(fixture/(base+'-effects-authority-closure.tsv')).read_bytes()
check('strict cross dependency effects authority TSV accepted',ns['validate_tables'](record,roles,matrix))
for values,label in [((record+b'step\t317\n',roles,matrix),'duplicate record'),((record.replace(b'actual_receipt_committed\tno',b'actual_receipt_committed\tyes'),roles,matrix),'premature receipt'),((record,roles.replace(b'unresolved-integration-design',b'operationally-resolved'),matrix),'invented integration'),((record,roles,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost authority domain')]:
    check('cross TSV drift rejected '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('same slices changed full reference rejects',rejected(ns['validate_review'],review,changed,prior))
for path,value in [(['stages',0,'effect'],'filesystem-write'),(['path_design','transaction_root'],'invented'),(['publication_design','archive_sidecar_pair_atomicity_claim'],True),(['publication_design','receipt_committed_last'],False),(['cleanup_design','unsafe_restore_or_boot_drift_keeps_pending_machine_obligations'],False)]:
    check('frozen cross fact drift rejected '+'.'.join(str(p) for p in path),rejected(ns['validate_review'],review,mutate(facts,path,value),prior))
basecase=dict(scope='finite-hypothetical-closure-not-operational-proof',origin='synthetic-private-fixture',machine_obligations='closed',controller_obligations='closed',children='drained',restoration='verified',receipt='complete-success',original_status=0,cleanup_status=0,rights='terminal')
result=ns['classify_private_result'](basecase)
check('synthetic known complete success classified only in model',result['model_success'] and not result['actual_dispatch_authorized'] and not result['actual_safe_pause_authorized'])
# Exhaust independent machine/controller/child/restore/receipt/right combinations.
# Expected closure is checked by explicit conjunctions, with failure evidence separate.
import itertools
for machine,controller,child,restore,receiptstate,rights in itertools.product(['unknown','pending','closed'],['unknown','pending','closed'],['unknown','live','drained'],['unknown','unsafe','verified'],['absent','partial','complete-failure','complete-success'],['active','terminal']):
    value=dict(basecase,machine_obligations=machine,controller_obligations=controller,children=child,restoration=restore,receipt=receiptstate,rights=rights,original_status=20 if receiptstate=='complete-failure' else 0)
    result=ns['classify_private_result'](value)
    mc=machine=='closed' and child=='drained' and restore=='verified'
    cc=controller=='closed' and receiptstate in ['complete-failure','complete-success']
    tr=mc and cc and rights=='terminal'
    label='/'.join([machine,controller,child,restore,receiptstate,rights])
    check('finite obligation result '+label,result['model_machine_closed']==mc and result['model_controller_closed']==cc and result['model_terminal_rights_closed']==tr and result['model_success']==(tr and receiptstate=='complete-success') and result['model_complete_failure']==(tr and receiptstate=='complete-failure') and all(result[k] is False for k in ['actual_dispatch_authorized','actual_grant_consumed','actual_operational_conformance','actual_obligations_closed','actual_safe_pause_authorized']))
for key in ['original_status','cleanup_status']:
    for status in [None,True,-1,256,'0']:
        changed=dict(basecase,**{key:status})
        if status is None:
            r=ns['classify_private_result'](changed)
            check('unknown '+key+' cannot complete closure',not r['model_controller_closed'] and not r['model_success'] and not r['model_terminal_rights_closed'])
        else:check('typed invalid '+key+' rejects '+repr(status),rejected(ns['classify_private_result'],changed))
for key,value in dict(scope='actual-runtime',origin='live-host',machine_obligations=[],controller_obligations=False,children='killed',restoration='forced',receipt='visible-but-sync-unknown',rights='renewed').items():
    check('unreviewed closure state rejects '+key,rejected(ns['classify_private_result'],dict(basecase,**{key:value})))
check('extra grant or actual safe pause field rejects',rejected(ns['classify_private_result'],dict(basecase,actual_safe_pause=True)))
for receiptstate,orig,cleanup in [('complete-failure',0,0),('complete-success',20,0),('complete-success',0,20)]:
    r=ns['classify_private_result'](dict(basecase,receipt=receiptstate,original_status=orig,cleanup_status=cleanup))
    check('inconsistent success failure classification stays pending '+str((receiptstate,orig,cleanup)),r['model_result']=='pending-or-inconsistent' and not r['model_terminal_rights_closed'])
check('all current actual obligations effects and bindings remain null',all(v is None for v in review['operational_cross_bindings'].values()))

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step317-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real317 review entry reruns full unchanged1203 predecessor acceptance', result.returncode == 0 and 'exact_step316_acceptance\tPASS (1203 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full1203 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 1203 and old_log.splitlines()[-1] == 'Result: PASS (1203 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step316-user-acceptance.json', '.tsv', '-cross-dependency-matrix.tsv', '-effects-authority-closure.tsv']]
    for name in names:
        check('exact published317 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
    check('published review does not confer selector or next-stage authority', 'actual_selector_equivalence_proven\tno' in result.stdout and 'next_stage_authorized\tno' in result.stdout)
    check('occupied output directory rejected without overwrite', run(['bash', tool, '--output-dir', out]).returncode != 0)
    for i, name in enumerate(names + [base + '-predecessor-test.log']):
        blocked = area / ('blocked-' + str(i))
        blocked.mkdir()
        (blocked / name).write_bytes(b'keep\n')
        check('occupied output rejects before publication ' + name, run(['bash', tool, '--output-dir', blocked]).returncode != 0 and list(blocked.iterdir()) == [blocked / name] and (blocked / name).read_bytes() == b'keep\n')
    missing = area / 'missing'
    check('missing output rejected without creation', run(['bash', tool, '--output-dir', missing]).returncode != 0 and not missing.exists())
    linked = area / 'linked'
    linked.symlink_to(out, target_is_directory=True)
    check('output symlink rejected', run(['bash', tool, '--output-dir', linked]).returncode != 0)
    copied = area / 'slack-update'
    shutil.copytree(root, copied)
    copied_tool = copied / 'tools/reference' / (base + '.sh')
    empty = area / 'empty'
    empty.mkdir()
    mutations = list(ns['OWN_HASHES']) + ['tools/reference/slack-update-reference.sh',
        'tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json',
        next(iter(policy['frozen_private_scope']['candidate_sha256_bindings'])), 'CHANGELOG.md']
    for rel in mutations:
        path = copied / rel
        content = path.read_bytes()
        path.write_bytes(content + b'\n')
        check('changed planning/reference/history input rejects before publication ' + path.name, run(['bash', copied_tool, '--output-dir', empty]).returncode != 0 and not list(empty.iterdir()))
        path.write_bytes(content)
    for rel in ['tools/reference/slack-update-reference.sh', 'docs/reference/' + base + '.md']:
        path = copied / rel
        content = path.read_bytes()
        saved = area / ('saved-' + str(len(list(area.iterdir()))))
        saved.write_bytes(content)
        path.unlink()
        path.symlink_to(saved)
        check('same-content source/reference symlink rejected ' + path.name, run(['bash', copied_tool, '--output-dir', empty]).returncode != 0 and not list(empty.iterdir()))
        path.unlink()
        path.write_bytes(content)
check('all1429 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
