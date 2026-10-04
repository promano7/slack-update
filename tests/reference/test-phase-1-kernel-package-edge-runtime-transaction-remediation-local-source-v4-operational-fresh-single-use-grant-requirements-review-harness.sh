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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review'
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


check('exact314 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '4278e61d06e196da4cf46b193a29dc05a2680b44b11e0a357b20d79c7b4f7a72')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step314_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step313-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1399 accepted bytes and original CHANGELOG suffix',len(history)==1399)
check('confirmed313 full479 first-push return and clean HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('separate fresh single-use grant requirements accepted',ns['validate_review'](review,facts,prior))
check('typed closed314 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared313 wording retained with external confirmation',prior['user_step313_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('all actual grant/source/target/boot bindings absent',all(value is None for value in review['operational_grant_bindings'].values()))
check('four prior reviews and two remaining preserved',len(review['previously_reviewed_requirements'])==4 and len(review['other_deferred_capabilities'])==2)
check('mandatory private coverage preserved',review['candidate_sha256_bindings']==prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests']==prior['frozen_private_scope']['mandatory_tests'])
stages=facts['stages']
check('thirteen immutable stages bound',len(stages)==13 and [s['index'] for s in stages]==list(range(13)))
check('stage0 read-only invocation consumption preserved',stages[0]['effect']=='read-only' and 'consume grant on invocation' in stages[0]['operation'])
check('stage1 traps before filesystem lock/log preserved','no filesystem lock or logging before this barrier' in stages[1]['operation'])
check('unsafe restore/boot drift retains pending obligations',facts['cleanup_design']['unsafe_restore_or_boot_drift_keeps_pending_machine_obligations'] is True)
check('claim protocol gap explicitly unbound',review['operational_grant_bindings']['actual_traps_compatible_consumption_integration'] is None and 'read-only-preflight-versus-persistent-claim-integration-unresolved' in review['blockers'])
for rel,digest in ns['OWN_HASHES'].items():
    check('exact bound314 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

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
        bad_policy('premature313 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
for key in ['schema','step','new_repository_artifact_count','prepared_repository_file_count']:
    bad_policy('wrong numeric or bool type ' + key,[key],True)
for key in policy['authorization']:
    bad_policy('opened inherited authority ' + key,['authorization',key],True)
for key,value in policy['fresh_boundary'].items():
    bad_policy('invented operational slot ' + key,['fresh_boundary',key],'stale-binding' if value is None else not value)
for key,value in policy['repository_stage_permission'].items():
    if type(value) is bool:
        bad_policy('widened or incomplete stage permission ' + key,['repository_stage_permission',key],not value)
for path,value in [(['accepted_checkpoint','commit_full'],'f'*40),(['accepted_checkpoint','sha256_bindings'],{}),(['accepted_checkpoint','sha256_bindings','CHANGELOG.md'],'0'*64),(['review_sha256'],'0'*64),(['other_deferred_capabilities'],[]),(['previously_reviewed_requirements'],[]),(['frozen_private_scope','mandatory_tests'],[]),(['next_stage'],'wrong-stage')]:
    bad_policy('changed policy identity or coverage ' + '.'.join(path),path,value)
extra = dict(policy, live_use_authorized=True)
check('unknown live authority field rejected', rejected(ns['validate_policy'],extra,confirmation,receipt,prior,review))
for key,value in confirmation.items():
    if type(value) is bool or value is None:
        check('rejects confirmation evidence invention ' + key,rejected(ns['validate_confirmation'],mutate(confirmation,[key],not value if type(value) is bool else 'invented'),receipt))
check('wrong confirmed commit prefix rejected',rejected(ns['validate_confirmation'],mutate(confirmation,['commit_prefix'],'fffffff'),receipt))
for key,value in dict(text=receipt['text'][:-1],original_display_sha256='0'*64,original_display_size_bytes=True,encoding='unknown').items():
    check('original313 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened grant freshness requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_grant_bindings']:
    check('rejects invented live grant binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_grant_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['other_deferred_capabilities'],[]),(['prohibited_current_effects'],[]),(['blockers'],[]),(['prior_review_sha256'],'0'*64),(['grant_action_matrix'],[]),(['private_fixture_specification','binding','boot'],'invented')]:
    check('review scope drift rejected '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
record=(fixture/(base+'.tsv')).read_bytes();actions=(fixture/(base+'-grant-action-matrix.tsv')).read_bytes();matrix=(fixture/(base+'-fresh-binding-proof-matrix.tsv')).read_bytes()
check('strict grant record action and proof TSV accepted',ns['validate_tables'](record,actions,matrix))
for values,label in [((record+b'step\t314\n',actions,matrix),'duplicate record'),((record.replace(b'actual_grant_consumed\tno',b'actual_grant_consumed\tyes'),actions,matrix),'premature consumption'),((record,actions.replace(b'required-not-operationally-implemented',b'actual-proven'),matrix),'invented action proof'),((record,actions,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost obligation')]:
    check('TSV drift rejected '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('same static slices with changed full reference SHA rejected',rejected(ns['validate_review'],review,changed,prior))
for path,value in [(['stages',0,'effect'],'owned-files'),(['stages',1,'operation'],'write ledger before traps'),(['cleanup_design','unsafe_restore_or_boot_drift_keeps_pending_machine_obligations'],False)]:
    check('frozen stage or cleanup fact drift rejected '+'.'.join(str(x) for x in path),rejected(ns['validate_review'],review,mutate(facts,path,value),prior))

def model(platform, route='success'):
    p=review['private_fixture_specification']
    actions=['claim','stage:0']
    if route=='failed-preflight':
        actions+=['fail-preflight','close-no-effects']
    else:
        actions+=['stage:1','acquire-exclusion','fresh-under-guard','stage:2','stage:3','stage:4','stage:5']
        if route=='boot-drift-pending': actions+=['boot-drift','preserve-pending']
        elif route=='uncatchable-loss-pending': actions+=['uncatchable-loss','preserve-pending']
        else:
            actions+=['stage:6','stage:7','stage:8','nested-update']
            actions+=['fail-forward'] if route=='failed-nested-update-safe-restore' else ['install-new','upgrade-all']
            actions+=['wait-drain','stage:9','stage:10','stage:11','release-exclusion','stage:12']
    events=[];held=False;phase='baseline'
    for i,action in enumerate(actions):
        events.append(dict(action=action,attempt=p['grant']['attempt'],grant_id=p['grant']['id'],binding=copy.deepcopy(p['binding']),observation=i,phase=phase,guard=held))
        if action=='acquire-exclusion':held=True
        elif action=='stage:4':phase='predecessor'
        elif action=='upgrade-all':phase='target'
        elif action=='stage:9':phase='restored'
        elif action=='release-exclusion':held=False
    return dict(origin='synthetic-private-fixture',scope='finite-memory-claims-not-issuer-or-ledger-proof',platform=platform,route=route,grant=copy.deepcopy(p['grant']),ledger=dict(state='unused',owner=None),events=events)

for platform in ['Slackware-15.0','Slackware-current']:
    for route in review['private_fixture_specification']['routes']:
        private=model(platform,route);answer=ns['admit_private_fixture'](private)
        check('private claim route accepted '+platform+' '+route,answer['private_fixture_accepted'] is True)
        check('private route never confers real authority '+platform+' '+route,all(answer[k] is False for k in ['dispatch_authorized','actual_grant_consumed','actual_atomic_durable_claim_proven','operational_conformance']) and answer['production_entry_closed'] is True)
        pending=route in ['boot-drift-pending','uncatchable-loss-pending']
        check('route obligations are explicit '+platform+' '+route,answer['model_pending_obligations'] is pending and answer['model_all_effects_closed'] is (not pending))
        check('route original failure preserved '+platform+' '+route,answer['model_original_failure_preserved'] is (route!='success'))
        check('consumed route never becomes unused '+platform+' '+route,answer['model_claim_state'].startswith('consumed-') and answer['model_forward_rights_closed'] is True)
        for index,event in enumerate(private['events']):
            omitted=copy.deepcopy(private['events']);omitted.pop(index)
            check('missing claim/freshness/action rejects '+platform+' '+route+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events'],omitted)))
            check('stale observation rejects '+platform+' '+route+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events',index,'observation'],index-1)))
    private=model(platform)
    for index,event in enumerate(private['events']):
        for key in ['attempt','grant_id','phase']:
            check('changed owned scope or phase rejects '+platform+' '+event['action']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['events',index,key],'foreign')))
        check('lost guard or early lock rejects '+platform+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events',index,'guard'],not event['guard'])))
        check('boolean freshness counter rejected '+platform+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events',index,'observation'],True)))
    # Change each required binding independently at every nested call and restore.
    for action in ['stage:2','stage:4','stage:5','stage:6','stage:8','nested-update','install-new','upgrade-all','stage:9']:
        index=next(i for i,e in enumerate(private['events']) if e['action']==action)
        for name in private['events'][index]['binding']:
            check('fresh binding drift rejects '+platform+' '+action+' '+name,rejected(ns['admit_private_fixture'],mutate(private,['events',index,'binding',name],'stale-or-foreign')))
    for route,extra in [('failed-preflight','stage:1'),('failed-nested-update-safe-restore','install-new'),('boot-drift-pending','stage:9'),('uncatchable-loss-pending','stage:12')]:
        bad=model(platform,route);events=copy.deepcopy(bad['events']);event=copy.deepcopy(events[-1]);event['action']=extra;events.insert(-1,event)
        check('forward/restore/false closure after failure rejected '+platform+' '+route,rejected(ns['admit_private_fixture'],mutate(bad,['events'],events)))
    for wrong in ['unused','consumed-closed','consumed-pending']:
        check('grant object cannot substitute claim lifecycle '+platform+' '+wrong,rejected(ns['admit_private_fixture'],mutate(private,['grant','state'],wrong)) if wrong!='unused' else ns['admit_private_fixture'](private)['actual_grant_consumed'] is False)
    for key in private['grant']:
        check('changed issuer grant scope rejects '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['grant',key],'foreign-or-expired')))
    for state in ['consumed-active','consumed-closed','unknown']:
        check('replay/unknown model ledger rejected '+platform+' '+state,rejected(ns['admit_private_fixture'],mutate(private,['ledger','state'],state)))
    ledger=dict(state='unused',owner=None);grant=private['grant']
    check('serial model first exclusive claim succeeds '+platform,ns['claim_private'](ledger,grant,grant['attempt']))
    check('serial model claim consumed immediately '+platform,ledger==dict(state='consumed-active',owner=grant['attempt']))
    check('serial same-owner replay fails '+platform,rejected(ns['claim_private'],ledger,grant,grant['attempt']))
    check('serial competing owner cannot claim '+platform,rejected(ns['claim_private'],ledger,grant,'synthetic-competing-owner'))
    check('failed preflight consumed output does not permit new invocation '+platform,ns['admit_private_fixture'](model(platform,'failed-preflight'))['model_claim_state']=='consumed-closed' and rejected(ns['claim_private'],ledger,grant,grant['attempt']))
    check('safe restoration retained after latched forward failure '+platform,ns['admit_private_fixture'](model(platform,'failed-nested-update-safe-restore'))['model_safe_restore_verified'] is True)
    check('wrong boot never claims restoration closed '+platform,ns['admit_private_fixture'](model(platform,'boot-drift-pending'))['model_safe_restore_verified'] is False)
    check('uncatchable loss retains unknown outcome '+platform,ns['admit_private_fixture'](model(platform,'uncatchable-loss-pending'))['model_claim_state']=='consumed-outcome-unknown-pending')
for key,value in dict(origin='live-grant',scope='actual-authority',platform='unreviewed',route='resume',events=[]).items():
    check('private provenance/scope rejected '+key,rejected(ns['admit_private_fixture'],mutate(model('Slackware-current'),[key],value)))
check('extra dispatch authority field rejected',rejected(ns['admit_private_fixture'],dict(model('Slackware-current'),dispatch_authorized=True)))
check('no synthetic claim promoted to operational binding',all(x is None for x in review['operational_grant_bindings'].values()))

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step314-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real314 review entry reruns full unchanged479 predecessor acceptance', result.returncode == 0 and 'exact_step313_acceptance\tPASS (479 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full479 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 479 and old_log.splitlines()[-1] == 'Result: PASS (479 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step313-user-acceptance.json', '.tsv', '-grant-action-matrix.tsv', '-fresh-binding-proof-matrix.tsv']]
    for name in names:
        check('exact published314 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
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
check('all1399 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
