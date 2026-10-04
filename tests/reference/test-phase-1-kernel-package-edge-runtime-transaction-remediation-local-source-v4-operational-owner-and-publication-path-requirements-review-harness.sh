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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review'
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


check('exact316 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '295fc55309ed60d61618d7728a5e2d7128e2311da5301f766ae8c31a83a01683')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step316_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step315-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1419 accepted bytes and original CHANGELOG suffix',len(history)==1419)
check('confirmed315 full1124 first-push return and clean HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('separate owner and publication requirements accepted',ns['validate_review'](review,facts,prior))
check('typed closed316 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared315 wording retained with external confirmation',prior['user_step315_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('all actual owner/path/publication bindings absent',all(value is None for value in review['operational_publication_bindings'].values()))
check('six prior reviews and no remaining separate capability reviews',len(review['previously_reviewed_requirements'])==6 and review['other_deferred_capabilities']==[])
check('all seven reviews still operationally incomplete',review['proof_state']['operational_capability_complete'] is False and policy['operational_readiness'] is False)
check('mandatory private coverage preserved',review['candidate_sha256_bindings']==prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests']==prior['frozen_private_scope']['mandatory_tests'])
check('frozen owned root0700 publication0600 and promano/users retained',facts['path_design']['owned_root_mode']=='0700' and facts['path_design']['publication_mode']=='0600' and facts['path_design']['publication_owner']=='promano:users')
check('all actual path values remain symbolic/unbound',facts['path_design']['transaction_root'] is None and facts['path_design']['scope']=='symbolic-proposal-only-actual-paths-require-later-grant')
check('pair not atomic and external receipt last preserved',facts['publication_design']['archive_sidecar_pair_atomicity_claim'] is False and facts['publication_design']['receipt_committed_last'] is True)
check('partial publication and unsafe restore keep distinct obligations',facts['publication_design']['incomplete_archive_sidecar_or_receipt_keeps_pending_controller_obligations'] is True and facts['cleanup_design']['unsafe_restore_or_boot_drift_keeps_pending_machine_obligations'] is True)
check('child quiescence before restore preserved',facts['child_supervision_design']['child_quiescence_required_before_restore'] is True)
check('314 claim/traps gap remains operational blocker','314-durable-claim-traps-gap-retained' in review['blockers'])
for rel,digest in ns['OWN_HASHES'].items():
    check('exact bound316 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

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
        bad_policy('premature315 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
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
    check('original315 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened owner/publication requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_publication_bindings']:
    check('rejects invented live publication binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_publication_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['other_deferred_capabilities'],['invented-next-capability']),(['prohibited_current_effects'],[]),(['blockers'],[]),(['prior_review_sha256'],'0'*64),(['owner_publication_map'],[]),(['private_fixture_specification','archive_descriptors_not_actual_tar'],False)]:
    check('review scope drift rejected '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
record=(fixture/(base+'.tsv')).read_bytes();roles=(fixture/(base+'-owner-publication-map.tsv')).read_bytes();matrix=(fixture/(base+'-publication-proof-matrix.tsv')).read_bytes()
check('strict owner/publication record map and proof TSV accepted',ns['validate_tables'](record,roles,matrix))
for values,label in [((record+b'step\t316\n',roles,matrix),'duplicate record'),((record.replace(b'actual_receipt_committed\tno',b'actual_receipt_committed\tyes'),roles,matrix),'premature receipt'),((record,roles.replace(b'symbolic-not-operationally-bound',b'actual-proven'),matrix),'invented owner/path binding'),((record,roles,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost obligation')]:
    check('TSV drift rejected '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('same static slices with changed full reference SHA rejected',rejected(ns['validate_review'],review,changed,prior))
for path,value in [(['path_design','transaction_root'],'invented'),(['path_design','publication_mode'],'0644'),(['path_design','publication_owner'],'root:root'),(['publication_design','archive_sidecar_pair_atomicity_claim'],True),(['publication_design','receipt_committed_last'],False),(['publication_design','final_stage_evidence'],'self-containing-archive'),(['cleanup_design','unsafe_restore_or_boot_drift_keeps_pending_machine_obligations'],False)]:
    check('frozen owner/path/publication fact drift rejected '+'.'.join(path),rejected(ns['validate_review'],review,mutate(facts,path,value),prior))

def model(platform,route='complete-success'):
    p=review['private_fixture_specification'];actions=['arm-traps','acquire-target-guard','create-owned-root','wait-drain-children']
    if route=='unsafe-restoration-pending':actions+=['restore-unsafe','preserve-backups','mark-pending-machine']
    else:
        actions+=['restore-verify','close-target-evidence','release-target-guard','acquire-publication-guard']
        actions+=['stage-archive','verify-owner-mode-archive','flush-archive','commit-exclusive-archive','sync-parent-archive']
        if route=='archive-only-partial':actions+=['mark-pending-controller']
        else:
            actions+=['stage-sidecar','verify-owner-mode-sidecar','flush-sidecar','commit-exclusive-sidecar','sync-parent-sidecar']
            if route=='archive-sidecar-partial':actions+=['mark-pending-controller']
            else:
                actions+=['stage-receipt','verify-owner-mode-receipt','flush-receipt','commit-exclusive-receipt']
                actions+=['receipt-sync-uncertain','mark-pending-controller'] if route=='receipt-sync-uncertain' else ['sync-parent-receipt','release-publication-guard','close-terminal-rights']
    events=[];target_guard=publication_guard=owned=False
    for i,action in enumerate(actions):
        events.append(dict(action=action,attempt=p['attempt'],binding=dict(archive_sha256=p['archive_sha256'],sidecar_sha256=p['sidecar_sha256'],publication_owner=copy.deepcopy(p['destinations'][0]['owner'])),ordinal=i,owned_root_recorded=owned,publication_guard=publication_guard,target_guard=target_guard))
        if action=='acquire-target-guard':target_guard=True
        elif action=='create-owned-root':owned=True
        elif action=='release-target-guard':target_guard=False
        elif action=='acquire-publication-guard':publication_guard=True
        elif action=='release-publication-guard':publication_guard=False
    original=20 if route=='complete-contained-failure' else None if route=='unsafe-restoration-pending' else 0
    receipt=None
    if route in ['complete-success','complete-contained-failure','receipt-sync-uncertain']:
        receipt=dict(attempt=p['attempt'],archive_sha256=p['archive_sha256'],sidecar_sha256=p['sidecar_sha256'],intended_outcome='FAIL' if original else 'PASS',original_status=original,cleanup_status=0,stage12_stdout='synthetic complete publication stream\n',stage12_stderr='',stage12_exit=0,terminal_nonreusable=True,archive_pair_atomic=False)
    return dict(origin='synthetic-private-fixture',scope='finite-path-events-not-native-publication-proof',platform=platform,route=route,original_status=original,receipt=receipt,events=events,**{key:copy.deepcopy(p[key]) for key in ['token','owned_root','roles','destinations','controls','archive_members','archive_raw_hex','sidecar_text']})

for platform in ['Slackware-15.0','Slackware-current']:
    for route in review['private_fixture_specification']['routes']:
        private=model(platform,route);answer=ns['admit_private_fixture'](private)
        check('private publication route accepted '+platform+' '+route,answer['private_fixture_accepted'] is True)
        check('private route never confers native proof '+platform+' '+route,all(answer[k] is False for k in ['dispatch_authorized','actual_owner_UID_GID_proven','actual_no_replace_commit_proven','actual_crash_durability_proven','actual_receipt_committed','operational_conformance']) and answer['production_entry_closed'] is True)
        machine=route=='unsafe-restoration-pending';controller=route in ['archive-only-partial','archive-sidecar-partial','receipt-sync-uncertain']
        check('partial machine/controller obligations explicit '+platform+' '+route,answer['model_machine_obligations_pending'] is machine and answer['model_controller_obligations_pending'] is controller and answer['model_result_complete'] is (not machine and not controller))
        check('failure/partial never claims success '+platform+' '+route,answer['model_success_eligible'] is (route=='complete-success'))
        check('unclosed partial rights never claimed closed '+platform+' '+route,answer['model_terminal_rights_closed'] is (not machine and not controller))
        for i,event in enumerate(private['events']):
            omitted=copy.deepcopy(private['events']);omitted.pop(i)
            check('missing safety/publication event rejected '+platform+' '+route+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events'],omitted)))
        if private['receipt'] is None:
            bad=dict(private,receipt=model(platform)['receipt'])
            check('pending case cannot fabricate complete receipt '+platform+' '+route,rejected(ns['admit_private_fixture'],bad))
    private=model(platform)
    for key,value in private['controls'].items():
        check('unreviewed ancestry alias writer or protocol rejects '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['controls',key],not value if type(value) is bool else 'unsupported-native')))
    for role in private['roles']:
        for path in ['/synthetic-preserved-source','/etc/slackpkg/mirrors','../escape',private['owned_root']['path']+'/unreviewed-role']:
            check('owned role overlap/escape rejects '+platform+' '+role+' '+path,rejected(ns['admit_private_fixture'],mutate(private,['roles',role],path)))
    for key,value in dict(path='/synthetic-foreign/root',mode='0777',owner='foreign',object_id='parent-replacement').items():
        check('owned root metadata/object drift rejects '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['owned_root',key],value)))
    for i,leaf in enumerate(private['destinations']):
        for key,value in dict(path='/synthetic-dangling-or-other/leaf',mode='0644',absent_before=False,object_id='foreign-existing-object').items():
            check('destination collision/metadata rejects '+platform+' '+leaf['role']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['destinations',i,key],value)))
        for key,value in dict(name='other',group='other',uid=True,gid=True,namespace='unbound').items():
            check('actual-name/UID/GID mapping invention rejects '+platform+' '+leaf['role']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['destinations',i,'owner',key],value)))
    for token in ['b'*32,'047e744d-d2ea-4d9a-8746-7734b58db3b2','A'*32,'a'*31,'a'*33,'../'+('a'*32)]:
        check('old/foreign/unsafe attempt token rejects '+platform+' '+token,rejected(ns['admit_private_fixture'],mutate(private,['token'],token)))
    for i,event in enumerate(private['events']):
        for key,value in dict(attempt='different-attempt',ordinal=True,target_guard=not event['target_guard'],publication_guard=not event['publication_guard'],owned_root_recorded=not event['owned_root_recorded']).items():
            check('same-owner guard or partial-root proof drift rejects '+platform+' '+event['action']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['events',i,key],value)))
        check('archive digest drift during publication rejects '+platform+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events',i,'binding','archive_sha256'],'0'*64)))
    for action,before in [('create-owned-root','arm-traps'),('release-target-guard','restore-verify'),('commit-exclusive-receipt','commit-exclusive-sidecar'),('release-publication-guard','sync-parent-receipt')]:
        events=copy.deepcopy(private['events']);i=next(i for i,e in enumerate(events) if e['action']==action);event=events.pop(i);j=next(i for i,e in enumerate(events) if e['action']==before);events.insert(j,event)
        check('premature ordered effect rejects '+platform+' '+action,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    for action in ['force-rename-existing','unlink-recreate','retry-publication','target-write-after-release','live-source-reread','delete-preserved-backup']:
        events=copy.deepcopy(private['events']);event=copy.deepcopy(events[-2]);event['action']=action;events.insert(-1,event)
        check('unreviewed fallback/retry/effect rejects '+platform+' '+action,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    for key,value in dict(attempt='prior',archive_sha256='0'*64,sidecar_sha256='0'*64,intended_outcome='FAIL',original_status=True,cleanup_status=None,stage12_stdout=None,stage12_stderr=None,stage12_exit=None,terminal_nonreusable=False,archive_pair_atomic=True).items():
        check('incomplete receipt/result/authority drift rejects '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['receipt',key],value)))
    check('receipt self-hash rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['receipt'],dict(private['receipt'],receipt_self_sha256='0'*64))))
    check('archive self-containing receipt rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['archive_members'],private['archive_members']+['stage12-complete','external-receipt'])))
    check('changed archive bytes rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['archive_raw_hex'],private['archive_raw_hex']+'00')))
    check('sidecar duplicate or wrong filename rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['sidecar_text'],private['sidecar_text']+private['sidecar_text'])))
    failed=model(platform,'complete-contained-failure')
    check('complete failure retains original20 and receipt FAIL '+platform,ns['admit_private_fixture'](failed)['model_original_status']==20 and failed['receipt']['intended_outcome']=='FAIL')
    check('failure receipt cannot relabel PASS '+platform,rejected(ns['admit_private_fixture'],mutate(failed,['receipt','intended_outcome'],'PASS')))
    check('visible receipt with sync uncertainty stays controller-pending '+platform,ns['admit_private_fixture'](model(platform,'receipt-sync-uncertain'))['model_controller_obligations_pending'] is True)
    check('unsafe restore has null unknown status and machine pending '+platform,ns['admit_private_fixture'](model(platform,'unsafe-restoration-pending'))['model_original_status'] is None)
for key,value in dict(origin='real-publication-proof',scope='native-crash-durability',platform='unreviewed',route='automatic-retry',events=[]).items():
    check('private scope/provenance rejects '+key,rejected(ns['admit_private_fixture'],mutate(model('Slackware-current'),[key],value)))
check('extra real dispatch field rejects',rejected(ns['admit_private_fixture'],dict(model('Slackware-current'),dispatch_authorized=True)))
check('all operational owner/publication slots remain null',all(value is None for value in review['operational_publication_bindings'].values()))

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step316-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real316 review entry reruns full unchanged1124 predecessor acceptance', result.returncode == 0 and 'exact_step315_acceptance\tPASS (1124 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full1124 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 1124 and old_log.splitlines()[-1] == 'Result: PASS (1124 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step315-user-acceptance.json', '.tsv', '-owner-publication-map.tsv', '-publication-proof-matrix.tsv']]
    for name in names:
        check('exact published316 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
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
check('all1419 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
