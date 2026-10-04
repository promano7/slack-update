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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review'
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


check('exact311 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '5771bfecb2d1a93e330cc9c99d37b68baf12f715f10bc5873e027fc51d0ee95a')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step313_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step312-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1389 accepted bytes and original CHANGELOG suffix',len(history)==1389)
check('confirmed312 full590 first-push return and clean HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('separate writer serialization requirements accepted',ns['validate_review'](review,facts,prior))
check('typed closed313 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared312 wording retained with external confirmation',prior['user_step312_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('actual platform writer lock bindings remain unresolved',facts['writer_preflight_design']['backend_paths_hashes_and_platform_lock_bindings'] is None)
check('bound reference uses own FD9 flock and explicit unlock',b'flock -n 9' in raw and b'flock -u 9' in raw)
check('all actual writer protocol and resource bindings absent',all(value is None for value in review['operational_writer_bindings'].values()))
check('three prior requirement reviews and three remaining reviews preserved',len(review['previously_reviewed_requirements'])==3 and len(review['other_deferred_capabilities'])==3 and review['prior_review_sha256']==prior['review_sha256'])
check('mandatory private coverage and candidate SHAs preserved',review['candidate_sha256_bindings']==prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests']==prior['frozen_private_scope']['mandatory_tests'])
for rel,digest in ns['OWN_HASHES'].items():
    check('exact bound313 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

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
        bad_policy('premature312 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
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
    check('original312 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened writer serialization requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_writer_bindings']:
    check('rejects invented live writer binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_writer_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['other_deferred_capabilities'],[]),(['prohibited_current_effects'],[]),(['blockers'],[]),(['prior_review_sha256'],'0'*64),(['writer_resource_map'],[]),(['private_fixture_specification','guard','all_entrypoints_controlled'],False),(['immutable_design_facts','writer_preflight_design','backend_paths_hashes_and_platform_lock_bindings'],'invented')]:
    check('rejects writer review scope drift '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
record=(fixture/(base+'.tsv')).read_bytes();resources=(fixture/(base+'-writer-resource-map.tsv')).read_bytes();matrix=(fixture/(base+'-serialization-proof-matrix.tsv')).read_bytes()
check('strict writer record resource and proof TSV accepted',ns['validate_tables'](record,resources,matrix))
for values,label in [((record+b'step\t313\n',resources,matrix),'duplicate record'),((record.replace(b'platform_writer_exclusion_proven\tno',b'platform_writer_exclusion_proven\tyes'),resources,matrix),'premature exclusion'),((record,resources.replace(b'required-not-live-bound',b'actual-proven'),matrix),'invented resource binding'),((record,resources,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost serialization obligation')]:
    check('rejects TSV '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('same lock slices with changed full reference SHA rejected',rejected(ns['validate_review'],review,changed,prior))
changed=ns['extract_facts'](raw.replace(b'flock -n 9',b'flock -n 8'),history[review['freeze_path']])
check('reference instance FD protocol drift rejected',rejected(ns['validate_review'],review,changed,prior))


def model(platform):
    p=review['private_fixture_specification']
    events=[dict(action='acquire',subject='outer-owner'),dict(action='capture',subject='baseline')]
    events += [dict(action='deny-writer',subject=writer) for writer in p['blocked_writers']]
    events += [dict(action='dispatch',subject=stage) for stage in p['dispatch_stages']]
    events += [dict(action=a,subject=b) for a,b in [('wait-drain','all-owned-children'),('restore-verify','full-baseline'),('close-target-evidence','captured-restored-state'),('release','outer-owner'),('publish-last-receipt','external-captured-data-only')]]
    return dict(origin='synthetic-private-fixture',scope='finite-known-writers-and-events-not-platform-exclusion-proof',platform=platform,domain_bindings=copy.deepcopy(p['domain_bindings']),writers=copy.deepcopy(p['writers']),guard=copy.deepcopy(p['guard']),events=events)


expected=dict(private_fixture_accepted=True,dispatch_authorized=False,platform_writer_exclusion_proven=False,actual_lock_protocol_proven=False,operational_conformance=False,production_entry_closed=True)
for platform in ['Slackware-15.0','Slackware-current']:
    private=model(platform)
    check('finite private full-window schedule accepted without dispatch '+platform,ns['admit_private_fixture'](private)==expected)
    for domain in private['domain_bindings']:
        missing=dict(private['domain_bindings']);missing.pop(domain)
        check('missing guarded resource rejects '+platform+' '+domain,rejected(ns['admit_private_fixture'],mutate(private,['domain_bindings'],missing)))
        check('unbound resource alias rejects '+platform+' '+domain,rejected(ns['admit_private_fixture'],mutate(private,['domain_bindings',domain],'different-resource-object')))
    for writer in private['writers']:
        missing=dict(private['writers']);missing.pop(writer)
        check('incomplete writer admission inventory rejects '+platform+' '+writer,rejected(ns['admit_private_fixture'],mutate(private,['writers'],missing)))
        check('nonparticipating uncontrolled writer rejects '+platform+' '+writer,rejected(ns['admit_private_fixture'],mutate(private,['writers',writer],'uncontrolled-nonparticipant')))
    writers=dict(private['writers'],unknown_writer='running-now')
    check('unknown newly admitted writer rejects '+platform,rejected(ns['admit_private_fixture'],mutate(private,['writers'],writers)))
    for key,value in private['guard'].items():
        check('unproven or changed guard control rejects '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['guard',key],not value if type(value) is bool else 'unreviewed')))
    for index,event in enumerate(private['events']):
        events=copy.deepcopy(private['events']);events.pop(index)
        check('missing required effect-order event rejects '+platform+' '+event['action']+':'+event['subject'],rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    events=copy.deepcopy(private['events']);events[0],events[1]=events[1],events[0]
    check('baseline capture before exclusion rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    for stage in review['private_fixture_specification']['dispatch_stages']:
        events=copy.deepcopy(private['events']);index=next(i for i,e in enumerate(events) if e==dict(action='dispatch',subject=stage));events.insert(index,dict(action='release',subject='outer-owner'))
        check('release between guarded stages rejected '+platform+' '+stage,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    for event in [dict(action='guard-lost',subject='outer-owner'),dict(action='force-unlock',subject='foreign-holder'),dict(action='unlink-recreate',subject='guard-object'),dict(action='owner-died-child-writing',subject='owned-child'),dict(action='admit-writer',subject='scheduled_refresh')]:
        events=copy.deepcopy(private['events']);events.insert(4,event)
        check('loss bypass or owner failure event rejected '+platform+' '+event['action'],rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    for action in ['restore-verify','release','publish-last-receipt']:
        events=copy.deepcopy(private['events']);index=next(i for i,e in enumerate(events) if e['action']==action);event=events.pop(index);events.insert(3,event)
        check('premature restoration release or receipt rejected '+platform+' '+action,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    events=copy.deepcopy(private['events']);events.insert(-1,dict(action='dispatch',subject='upgrade-all'))
    check('target mutation after guard release rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    events=copy.deepcopy(private['events']);events.append(dict(action='dispatch',subject='upgrade-all'))
    check('target mutation after last receipt rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    events=copy.deepcopy(private['events']);index=next(i for i,e in enumerate(events) if e==dict(action='dispatch',subject='nested-update'));events[index],events[index+1]=events[index+1],events[index]
    check('nested dispatch stage order rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    events=copy.deepcopy(private['events']);events.append(dict(action='publish-last-receipt',subject='external-captured-data-only'))
    check('duplicate external last receipt rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
    events=copy.deepcopy(private['events']);events[0]['subject']='reference-FD9'
    check('reference instance guard cannot stand in for outer owner '+platform,rejected(ns['admit_private_fixture'],mutate(private,['events'],events)))
for key,value in dict(origin='live-lock-observation',scope='actual-platform-exclusion',platform='unreviewed',writers={},domain_bindings={},events=[]).items():
    check('private provenance or completeness rejected '+key,rejected(ns['admit_private_fixture'],mutate(model('Slackware-current'),[key],value)))
check('unknown fixture operational authority rejected',rejected(ns['admit_private_fixture'],dict(model('Slackware-current'),dispatch_authorized=True)))
check('toy schedule cannot populate actual writer or lock bindings',all(value is None for value in review['operational_writer_bindings'].values()) and ns['admit_private_fixture'](model('Slackware-current'))['platform_writer_exclusion_proven'] is False)

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step313-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real313 review entry reruns full unchanged590 predecessor acceptance', result.returncode == 0 and 'exact_step312_acceptance\tPASS (590 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full590 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 590 and old_log.splitlines()[-1] == 'Result: PASS (590 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step312-user-acceptance.json', '.tsv', '-writer-resource-map.tsv', '-serialization-proof-matrix.tsv']]
    for name in names:
        check('exact published311 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
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
check('all1389 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
