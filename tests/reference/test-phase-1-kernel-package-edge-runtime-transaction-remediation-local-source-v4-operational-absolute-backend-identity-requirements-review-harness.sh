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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review'
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


check('exact311 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == 'b6234a380fe3d8a8b37dfa8df8aba45b275acfa3c8d84777ecf14ec02a0d69da')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step312_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step311-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1379 accepted bytes and original CHANGELOG suffix',len(history)==1379)
check('confirmed311 full366 original return first push clean matching HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('separate absolute backend identity requirements accepted',ns['validate_review'](review,facts,prior))
check('typed closed312 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared311 wording retained with external confirmation',prior['user_step311_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('frozen absolute backend path SHA binding remains null',facts['adapter_design']['real_backend_absolute_path_and_sha256'] is None)
check('exact frozen three nested argv preserved',len(facts['adapter_design']['allowed_argv'])==3)
check('all actual operational identity slots absent',all(value is None for value in review['operational_identity_bindings'].values()))
check('two earlier requirement reviews and four further reviews preserved',len(review['previously_reviewed_requirements'])==2 and len(review['other_deferred_capabilities'])==4 and review['prior_review_sha256']==prior['review_sha256'])
check('mandatory private coverage and candidate SHAs preserved',review['candidate_sha256_bindings']==prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests']==prior['frozen_private_scope']['mandatory_tests'])
for rel,digest in ns['OWN_HASHES'].items():
    check('exact bound312 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

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
    check('original311 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened absolute backend identity requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_identity_bindings']:
    check('rejects invented live namespace binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_identity_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['other_deferred_capabilities'],[]),(['prohibited_current_effects'],[]),(['blockers'],[]),(['prior_review_sha256'],'0'*64),(['backend_role_map'],[]),(['private_fixture_specification','dispatch_authority'],True),(['immutable_design_facts','adapter_design','real_backend_absolute_path_and_sha256'],'invented')]:
    check('rejects identity review scope drift '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
record=(fixture/(base+'.tsv')).read_bytes()
roles=(fixture/(base+'-backend-role-map.tsv')).read_bytes()
matrix=(fixture/(base+'-identity-proof-matrix.tsv')).read_bytes()
check('strict identity record roles and proof TSV accepted',ns['validate_tables'](record,roles,matrix))
for values,label in [((record+b'step\t312\n',roles,matrix),'duplicate record'),((record.replace(b'execution_race_closed\tno',b'execution_race_closed\tyes'),roles,matrix),'premature race closure'),((record,roles.replace(b'required-not-bound',b'live-bound'),matrix),'invented backend binding'),((record,roles,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost identity obligation')]:
    check('rejects TSV '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('same slices with changed full reference SHA rejected',rejected(ns['validate_review'],review,changed,prior))
freeze=json.loads(history[review['freeze_path']]);freeze['frozen_implementation_specification']['adapter_design']['no_recursive_PATH_resolution_or_network_fallback']=False
changed=ns['extract_facts'](raw,json.dumps(freeze).encode())
check('weakened immutable adapter resolution rejected',rejected(ns['validate_review'],review,changed,prior))

for path in ['slackpkg','relative/backend','/a/../backend','/a/./backend','//a/backend','/a//backend','/a/backend/','/a/backend x','/a/backend\n','/a/backend\x00','/a\\backend',None,True,0]:
    check('lexical private path rejects '+repr(path),rejected(ns['lexical_canonical_absolute'],path))
check('canonical absolute lexical path accepted without filesystem lookup',ns['lexical_canonical_absolute']('/__private__/backend')=='/__private__/backend')
expected=dict(private_fixture_accepted=True,dispatch_authorized=False,actual_backend_identity_proven=False,dependency_closure_proven=False,execution_race_closed=False,operational_conformance=False,production_entry_closed=True)


def model(platform):
    records=copy.deepcopy(review['private_fixture_specification']['platform_records'][platform])
    return dict(origin='synthetic-private-fixture',scope='finite-synthetic-identity-graph-no-live-proof',platform=platform,records=records,dispatch_records=copy.deepcopy(records),resolution=dict(adapter_to_backend='direct-reviewed-absolute-object',PATH_search=False,shell_fallback=False,rehash_and_rebind=False),environment=dict(PATH='<owned-adapters>:<reviewed-system-path>',LC_ALL='C',SLACK_UPDATE_CONFIG='<derived-config>'),argv=['-batch=on','-default_answer=y','update'],stability=dict(retained_checked_object=True,content_write_exclusion=True,ancestry_mount_and_dependency_stability=True,same_transaction_recheck=True,failure_latch_clear=True))


for platform in ['Slackware-15.0','Slackware-current']:
    private=model(platform)
    check('complete known toy graph accepted without dispatch '+platform,ns['admit_private_fixture'](private)==expected)
    for argv in facts['adapter_design']['allowed_argv']:
        check('private exact nested argv admitted '+platform+' '+argv[-1],ns['admit_private_fixture'](mutate(private,['argv'],argv))==expected)
    for role,record in private['records'].items():
        changed=copy.deepcopy(private);changed['records'].pop(role)
        check('missing bound role rejected '+platform+' '+role,rejected(ns['admit_private_fixture'],changed))
        changed=copy.deepcopy(private);changed['dispatch_records'].pop(role)
        check('missing dispatch identity rejected '+platform+' '+role,rejected(ns['admit_private_fixture'],changed))
        check('dispatch object replaced after checksum rejected '+platform+' '+role,rejected(ns['admit_private_fixture'],mutate(private,['dispatch_records',role,'object'],'replaced-object')))
        check('same opened object modified at dispatch rejected '+platform+' '+role,rejected(ns['admit_private_fixture'],mutate(private,['dispatch_records',role,'content'],record['content']+'changed')))
        changed=copy.deepcopy(private);changed['records'][role]['content']+='changed';changed['records'][role]['sha256']=hashlib.sha256(changed['records'][role]['content'].encode()).hexdigest();changed['dispatch_records']=copy.deepcopy(changed['records'])
        check('changed bytes cannot self-rehash into approval '+platform+' '+role,rejected(ns['admit_private_fixture'],changed))
        for key,value in dict(regular=False,owner='unreviewed',mode='group-writable',ancestry='symlink-ancestor',privileges='unreviewed-capability',version='unreviewed-version').items():
            check('unbound private metadata rejected '+platform+' '+role+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['records',role,key],value)))
    for alternate in ['slackpkg','/a/../slackpkg','/a//slackpkg','//a/slackpkg','/a/slackpkg\n','/proc/self/fd/999','/unreviewed/slackpkg']:
        check('private alternate backend path rejected '+platform+' '+repr(alternate),rejected(ns['admit_private_fixture'],mutate(private,['records','slackpkg','path'],alternate)))
    for digest in ['',None,'0'*63,'g'*64,private['records']['slackpkg']['sha256'].upper(),'0'*64]:
        check('malformed or wrong SHA rejected '+platform+' '+repr(digest),rejected(ns['admit_private_fixture'],mutate(private,['records','slackpkg','sha256'],digest)))
    for key in ['path','object']:
        check('adapter backend alias recursion rejected '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['records','slackpkg',key],private['records']['adapter'][key])))
    for key,value in dict(interpreter_role='env',dependencies=['unbound-helper'],format='directory').items():
        check('unreviewed interpreter dependency or type rejected '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['records','slackpkg',key],value)))
    other='Slackware-current' if platform=='Slackware-15.0' else 'Slackware-15.0'
    check('other platform toy identity substituted rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['records','slackpkg'],model(other)['records']['slackpkg'])))
    for key,value in private['resolution'].items():
        check('lookup fallback or rebind rejected '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['resolution',key],not value if type(value) is bool else 'PATH-slackpkg')))
    for key in private['stability']:
        check('missing content object or writer stability rejected '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['stability',key],False)))
    for key in ['BASH_ENV','ENV','LD_PRELOAD','LD_LIBRARY_PATH','BASH_FUNC_slackpkg%%']:
        env=dict(private['environment']);env[key]='injected'
        check('private interpreter loader environment injection rejected '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['environment'],env)))
for argv in [[],['update'],['-batch=on','-default_answer=y','clean-system'],['-batch=on','-default_answer=y','update','extra'],'update',None]:
    check('unknown private argv rejected '+repr(argv),rejected(ns['admit_private_fixture'],mutate(model('Slackware-current'),['argv'],argv)))
for key,value in dict(origin='live-observation',scope='actual-identity-proof',platform='unreviewed',records={},dispatch_records={}).items():
    check('private provenance or graph completeness rejected '+key,rejected(ns['admit_private_fixture'],mutate(model('Slackware-current'),[key],value)))
check('unknown fixture dispatch authority rejected',rejected(ns['admit_private_fixture'],dict(model('Slackware-current'),dispatch_authorized=True)))
check('toy success leaves actual identity and all operational slots absent',all(value is None for value in review['operational_identity_bindings'].values()) and ns['admit_private_fixture'](model('Slackware-current'))['actual_backend_identity_proven'] is False)

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step312-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real312 review entry reruns full unchanged366 predecessor acceptance', result.returncode == 0 and 'exact_step311_acceptance\tPASS (366 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full366 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 366 and old_log.splitlines()[-1] == 'Result: PASS (366 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step311-user-acceptance.json', '.tsv', '-backend-role-map.tsv', '-identity-proof-matrix.tsv']]
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
check('all1379 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
