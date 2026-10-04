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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause'
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


check('exact318 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == 'c8fd3ce66351fd2007fd61963358d097e8887dd8a1212b6bbbe074f7314c9b9f')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step318_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-freeze.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step317-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']])
check('exact1439 accepted bytes and original CHANGELOG suffix',len(history)==1439)
check('confirmed317 full1007 first-push return and clean HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('requirements freeze and conditional pause accepted',ns['validate_review'](review,facts,prior))
check('typed closed318 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared317 wording retained with external confirmation',prior['user_step317_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
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
    check('exact bound318 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

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
        bad_policy('premature317 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
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
    check('original317 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened owner/publication requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_cross_bindings']:
    check('rejects invented live publication binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_cross_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
check('frozen requirements and current qualification remain conditional',policy['requirements_frozen'] is True and policy['strong_pause_qualification_complete'] is True and policy['strong_safe_pause'] is False and policy['user_step318_checkpoint_confirmed'] is False)
check('all future stage rights closed with no numeric next step',policy['repository_stage_permission']['next_review_step'] is None and policy['all_future_stage_and_operational_rights_closed'] is True)
check('complete318 return required no reserve or auto resume',review['pause_qualification']['full318_user_checkpoint_required'] is True and review['pause_qualification']['reserve319_320_authorized'] is False and review['pause_qualification']['new_resume_requires_explicit_user_plan'] is True)
check('all seven freeze and batch checkpoint bytes accepted',ns['validate_bundle'](history,review))
for i,row in enumerate(review['seven_review_bindings']):
    for key,new in [('review_sha256','0'*64),('policy_sha256','0'*64),('step',True),('capability','invented')]:
        check('separate frozen dependency drift rejects '+str(row['step'])+' '+key,rejected(ns['validate_bundle'],history,mutate(review,['seven_review_bindings',i,key],new)))
for i,row in enumerate(review['accepted_batch_inventory']):
    for key,new in [('policy_sha256','0'*64),('commit_prefix','invented'),('acceptance_result','PASS (0 passes, 0 failures)'),('step',True)]:
        check('batch checkpoint drift rejects '+str(row['step'])+' '+key,rejected(ns['validate_bundle'],history,mutate(review,['accepted_batch_inventory',i,key],new)))
    if row['confirmation_path'] is not None:
        check('bound batch confirmation digest rejects '+str(row['step']),rejected(ns['validate_bundle'],history,mutate(review,['accepted_batch_inventory',i,'confirmation_sha256'],'0'*64)))
for key in ['seven_review_bindings','requirements','cross_dependency_map','proof_obligations','blockers']:
    check('frozen exact cross reviewed bytes reject '+key,rejected(ns['validate_bundle'],history,mutate(review,['frozen_requirements_specification',key],[])))
for path,value in [(['historical_strong_pause_anchor','sha256'],'0'*64),(['accepted_batch_inventory'],[]),(['seven_review_bindings'],[]),(['pause_qualification','strong_pause_confirmed_now'],True),(['pause_qualification','current_actual_host_obligations'],[]),(['frozen_requirements_specification','operational_design_bytes_changed'],True),(['remaining_operational_blockers'],[]),(['blockers'],[])]:
    check('freeze closure overclaim drift rejects '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
for key,value in review['pause_qualification'].items():
    if type(value) is bool or value is None:
        check('pause qualification overclaim or loss rejects '+key,rejected(ns['validate_review'],mutate(review,['pause_qualification',key],not value if type(value) is bool else 'fabricated'),facts,prior))
record=(fixture/(base+'.tsv')).read_bytes();roles=(fixture/(base+'-requirements-freeze-map.tsv')).read_bytes();matrix=(fixture/(base+'-pause-conditions.tsv')).read_bytes()
check('strict freeze map and pause condition TSV accepted',ns['validate_tables'](record,roles,matrix))
for values,label in [((record+b'step\t318\n',roles,matrix),'duplicate record'),((record.replace(b'strong_safe_pause\tno',b'strong_safe_pause\tyes'),roles,matrix),'premature pause'),((record,roles.replace(b'operational-incomplete',b'operational-complete'),matrix),'invented capability completion'),((record,roles,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost pause condition')]:
    check('freeze TSV drift rejected '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']])
check('immutable whole reference drift still rejects',rejected(ns['validate_review'],review,changed,prior))
basecase=dict(origin='synthetic-private-fixture',scope='repository-requirements-batch-only-not-host-conformance',checkpoint={key:True for key in ['applied','complete_acceptance','commit_pushed','worktree_clean','HEAD_matches_origin']},conditions=dict(policy['strong_pause_completion_conditions']),batch_machine_obligations='none-introduced-by-batch',batch_controller_obligations='none-introduced-by-batch',batch_effects='repository-and-private-validation-only',current_actual_host_obligations='unobserved',future_runtime_rights='closed',future_repository_rights='closed',current_live_bindings='unbound')
r=ns['evaluate_private_pause_gate'](basecase)
check('model complete repository gate does not confirm actual pause or host',r['model_repository_pause_eligible'] and not r['actual_strong_safe_pause_confirmed'] and not r['actual_host_obligations_closed'])
import itertools
keys=list(basecase['checkpoint'])
for flags in itertools.product([False,True],repeat=len(keys)):
    value=mutate(basecase,['checkpoint'],dict(zip(keys,flags)));r=ns['evaluate_private_pause_gate'](value)
    check('all checkpoint parts jointly required '+str(flags),r['model_repository_pause_eligible']==all(flags) and not r['actual_user318_checkpoint_confirmed'])
for key in basecase['conditions']:
    r=ns['evaluate_private_pause_gate'](mutate(basecase,['conditions',key],False))
    check('pause gate denies missing required condition '+key,not r['model_repository_pause_eligible'])
    for bad in [None,1,'yes']:
        check('pause condition typed bool required '+key+' '+repr(bad),rejected(ns['evaluate_private_pause_gate'],mutate(basecase,['conditions',key],bad)))
for machine,controller,effects,runtime,repo,bindings in itertools.product(['none-introduced-by-batch','pending','unknown'],['none-introduced-by-batch','pending','unknown'],['repository-and-private-validation-only','runtime-or-partial-publication','unknown'],['closed','open'],['closed','open'],['unbound','bound']):
    value=dict(basecase,batch_machine_obligations=machine,batch_controller_obligations=controller,batch_effects=effects,future_runtime_rights=runtime,future_repository_rights=repo,current_live_bindings=bindings)
    r=ns['evaluate_private_pause_gate'](value);eligible=machine==controller=='none-introduced-by-batch' and effects=='repository-and-private-validation-only' and runtime==repo=='closed' and bindings=='unbound'
    check('scoped effects obligations rights gate '+ '/'.join([machine,controller,effects,runtime,repo,bindings]),r['model_repository_pause_eligible']==eligible and all(r[k] is False for k in ['actual_user318_checkpoint_confirmed','actual_strong_safe_pause_confirmed','actual_dispatch_authorized','actual_grant_consumed','actual_operational_conformance','actual_host_obligations_closed']))
for key,value in dict(origin='actual-host',scope='live-operational-pause',current_actual_host_obligations='closed',batch_machine_obligations=[],future_runtime_rights=True,batch_effects='preflight-only',current_live_bindings=None).items():
    check('unreviewed actual pause or bad type rejects '+key,rejected(ns['evaluate_private_pause_gate'],dict(basecase,**{key:value})))
for key in keys:
    check('checkpoint type bool required '+key,rejected(ns['evaluate_private_pause_gate'],mutate(basecase,['checkpoint',key],1)))
check('missing checkpoint key rejects',rejected(ns['evaluate_private_pause_gate'],mutate(basecase,['checkpoint'],{})))
check('extra actual grant or pause field rejects',rejected(ns['evaluate_private_pause_gate'],dict(basecase,actual_strong_safe_pause=True)))
check('actual host obligations and runtime bindings still null',all(v is None for v in review['operational_cross_bindings'].values()))

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step318-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real318 review entry reruns full unchanged1007 predecessor acceptance', result.returncode == 0 and 'exact_step317_acceptance\tPASS (1007 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full1007 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 1007 and old_log.splitlines()[-1] == 'Result: PASS (1007 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-freeze.json', '-checkpoint-confirmation.json', '-step317-user-acceptance.json', '.tsv', '-requirements-freeze-map.tsv', '-pause-conditions.tsv']]
    for name in names:
        check('exact published318 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
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
check('all1439 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
