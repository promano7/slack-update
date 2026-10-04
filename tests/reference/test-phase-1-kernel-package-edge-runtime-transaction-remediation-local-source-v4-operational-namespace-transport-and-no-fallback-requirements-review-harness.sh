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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review'
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


check('exact311 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == '879829026bb35db6c8e9f5c72b05580488e92e0689eb8aeccfe8b58050125686')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step311_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step310-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1369 accepted bytes and original CHANGELOG suffix', len(history) == 1369)
check('confirmed310 full286 original return first push and clean matching HEAD origin', ns['validate_confirmation'](confirmation, receipt))
check('separate namespace transport requirements accepted', ns['validate_review'](review, facts, prior))
check('typed closed311 policy accepted', ns['validate_policy'](policy, confirmation, receipt, prior, review))
check('immutable prepared310 wording retained with external confirmation', prior['user_step310_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('two frozen network namespace templates preserved', facts['command_templates']['refresh'][:3] == ['unshare','-n','--'] and facts['command_templates']['apply'][:3] == ['unshare','-n','--'])
check('predecessor restore network coverage explicitly unproven', all(row['group'] is None and 'separate-containment' in row['gap'] for row in review['command_scope'][2:]))
check('private mandatory coverage and five further separate reviews preserved', review['candidate_sha256_bindings'] == prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests'] == prior['frozen_private_scope']['mandatory_tests'] and len(review['other_deferred_capabilities']) == 5)
check('all actual namespace bindings absent', all(value is None for value in review['namespace_bindings'].values()))
check('reference actual selector requirements retain bound310 identity', review['prior_review_sha256'] == prior['review_sha256'] and policy['actual_selector_equivalence_proven'] is False)
for rel, digest in ns['OWN_HASHES'].items():
    check('exact bound311 input ' + Path(rel).name, hashlib.sha256((root / rel).read_bytes()).hexdigest() == digest)


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
        bad_policy('premature311 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
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
    check('original310 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened namespace transport requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['namespace_bindings']:
    check('rejects invented live namespace binding ' + key,rejected(ns['validate_review'],mutate(review,['namespace_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['transport_requirements','exact_mirror_uri'],'https://example.invalid/'),(['transport_requirements','lexical_fixture_is_not_backend_or_realpath_proof'],False),(['other_deferred_capabilities'],[]),(['prohibited_current_effects'],[]),(['blockers'],[]),(['prior_review_sha256'],'0'*64),(['immutable_design_facts','command_templates','apply'],['unshare','-n','--fork'])]:
    check('rejects review scope or identity drift ' + '.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
record = (fixture / (base + '.tsv')).read_bytes()
scope = (fixture / (base + '-namespace-scope.tsv')).read_bytes()
matrix = (fixture / (base + '-transport-proof-matrix.tsv')).read_bytes()
check('strict record namespace scope and proof TSV accepted',ns['validate_tables'](record,scope,matrix))
for values,label in [((record+b'step\t311\n',scope,matrix),'duplicate record'),((record.replace(b'real_transport_proven\tno',b'real_transport_proven\tyes'),scope,matrix),'premature real transport'),((record,scope.replace(b'upgradepkg',b'unshare upgradepkg'),matrix),'invented predecessor wrapper'),((record,scope,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost future proof')]:
    check('rejects TSV ' + label,rejected(ns['validate_tables'],*values))
changed = ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('unchanged slices with different full reference SHA rejected',rejected(ns['validate_review'],review,changed,prior))
freeze = json.loads(history[review['freeze_path']])
freeze['frozen_implementation_specification']['command_templates']['apply'].insert(2,'--fork')
changed = ns['extract_facts'](raw,json.dumps(freeze).encode())
check('frozen launcher option mutation rejected',rejected(ns['validate_review'],review,changed,prior))

# Pure fixture data: never call unshare, setns, nsenter or a real backend.
private = dict(origin='synthetic-private-fixture',scope='refresh-and-apply-only-not-predecessor-or-restore',host='synthetic-host',groups={},descendants={},environment=review['transport_requirements']['exact_environment_allowlist'],uri=review['transport_requirements']['exact_mirror_uri'],streams=dict(download_error=False,nested_update_exit=0,pkglist_regular_fresh=True,pkglist_unchanged=True,later_call_after_latched_failure=False))
for name,roles in dict(refresh=['refresh-backend'],apply=['reference','nested-update','install-new','upgrade-all','package-script']).items():
    identity='synthetic-'+name
    private['groups'][name]=dict(available=True,identity=identity,launch_exit=0,descriptors=['owned-stdin','owned-stdout-pipe','owned-stderr-pipe'],resources='reviewed-no-external-connectivity',reentry=False,supervision='owned-wait-drain-before-restore')
    private['descendants'][name]={role:identity for role in roles}
expected = dict(private_fixture_accepted=True,dispatch_authorized=False,operational_namespace_proven=False,real_transport_proven=False,operational_conformance=False,production_entry_closed=True)
check('two independent groups with inherited private members accepted without dispatch',ns['admit_private_fixture'](private)==expected)
# An inode label may be reused after a namespace lifetime ends. Group admission is scoped;
# equal labels alone are not a fresh-handle proof or a reason to require one shared group.
equal = copy.deepcopy(private)
equal['groups']['apply']['identity']=equal['groups']['refresh']['identity']
equal['descendants']['apply']={role:equal['groups']['apply']['identity'] for role in equal['descendants']['apply']}
check('group-scoped labels do not assume global namespace inode uniqueness',ns['admit_private_fixture'](equal)==expected)
for group in ['refresh','apply']:
    for key,value in dict(available=False,identity=private['host'],launch_exit=1,descriptors=['host-socket'],resources='external-route',reentry=True,supervision='restore-before-wait').items():
        check('private admission rejects ' + group + ' ' + key,rejected(ns['admit_private_fixture'],mutate(private,['groups',group,key],value)))
    for role in private['descendants'][group]:
        check('private child escape rejected ' + group + ' ' + role,rejected(ns['admit_private_fixture'],mutate(private,['descendants',group,role],'synthetic-host')))
    members=dict(private['descendants'][group]);members.pop(next(iter(members)))
    check('missing child membership rejected ' + group,rejected(ns['admit_private_fixture'],mutate(private,['descendants',group],members)))
for fd in ['host-network-socket','host-netns-handle','host-UNIX-broker','unknown-extra-FD']:
    check('private unknown retained descriptor rejects ' + fd,rejected(ns['admit_private_fixture'],mutate(private,['groups','apply','descriptors'],private['groups']['apply']['descriptors']+[fd])))
for std in ['stdin','stdout','stderr']:
    descriptors=list(private['groups']['apply']['descriptors']);descriptors[['stdin','stdout','stderr'].index(std)]='host-socket-'+std
    check('host socket on ' + std + ' rejected',rejected(ns['admit_private_fixture'],mutate(private,['groups','apply','descriptors'],descriptors)))
for key in ['http_proxy','HTTPS_PROXY','ALL_PROXY','BASH_ENV','ENV','LD_PRELOAD','BASH_FUNC_slackpkg%%']:
    env=dict(private['environment']);env[key]='injected'
    check('private environment injection rejected ' + key,rejected(ns['admit_private_fixture'],mutate(private,['environment'],env)))
for key in private['environment']:
    check('unreviewed environment binding rejected ' + key,rejected(ns['admit_private_fixture'],mutate(private,['environment',key],'unreviewed')))
uri=private['uri']
for alternate in ['https://example.invalid/','ftp://example.invalid/','file://localhost'+uri[7:],'file://host'+uri[7:],uri+'?query',uri+'#fragment',uri.replace('local-source-v4','%6cocal-source-v4'),uri+'../',uri+'\\escape',uri+' ',uri+'\n'+uri,uri.rstrip('/'),'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4/',None]:
    check('exact local URI private gate rejects ' + repr(alternate),rejected(ns['admit_private_fixture'],mutate(private,['uri'],alternate)))
for key,value in private['streams'].items():
    check('nested refresh or failure latch rejects ' + key,rejected(ns['admit_private_fixture'],mutate(private,['streams',key],not value if type(value) is bool else 37)))
for path in [['groups','apply','launch_exit'],['groups','apply','available'],['streams','nested_update_exit'],['streams','pkglist_unchanged']]:
    current=private
    for key in path:current=current[key]
    check('strict admission rejects bool int confusion ' + '.'.join(path),rejected(ns['admit_private_fixture'],mutate(private,path,0 if type(current) is bool else False)))
for key,value in dict(origin='live-host-observation',scope='whole-transaction',host='',descendants={},groups={}).items():
    check('fixture scope completeness rejected ' + key,rejected(ns['admit_private_fixture'],mutate(private,[key],value)))
check('unknown private authority field rejected',rejected(ns['admit_private_fixture'],dict(private,dispatch_authorized=True)))
check('accepted synthetic labels never populate live review slots',all(value is None for value in review['namespace_bindings'].values()) and ns['admit_private_fixture'](private)['dispatch_authorized'] is False)

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step311-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real311 review entry reruns full unchanged286 predecessor acceptance', result.returncode == 0 and 'exact_step310_acceptance\tPASS (286 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full286 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 286 and old_log.splitlines()[-1] == 'Result: PASS (286 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step310-user-acceptance.json', '.tsv', '-namespace-scope.tsv', '-transport-proof-matrix.tsv']]
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
check('all1369 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
