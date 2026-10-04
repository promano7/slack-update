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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review'
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


check('exact315 requirements tool SHA', hashlib.sha256(tool.read_bytes()).hexdigest() == 'ddb4de03fe02e3261d20c6a1cca825a4accd54633a582224f8c03345c968e6ab')
source = tool.read_text().split("<<'PYREVIEW'\n", 1)[1].rsplit('\nPYREVIEW', 1)[0]
ns = {'__name__': 'step315_test_seams'}
exec(compile(ast.parse(source), str(tool), 'exec'), ns)
policy = json.loads((fixture / (base + '-policy.json')).read_text())
review = json.loads((fixture / (base + '-review.json')).read_text())
confirmation = json.loads((fixture / (base + '-checkpoint-confirmation.json')).read_text())
receipt = json.loads((fixture / (base + '-step314-user-acceptance.json')).read_text())
history = ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode())
prior = json.loads(history['tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json'])
raw = history['tools/reference/slack-update-reference.sh']
facts = ns['extract_facts'](raw, history[review['freeze_path']],history[review['source_boundary_path']],history[review['builder_path']])
check('exact1409 accepted bytes and original CHANGELOG suffix',len(history)==1409)
check('confirmed314 full1173 first-push return and clean HEAD origin',ns['validate_confirmation'](confirmation,receipt))
check('separate source and archive requirements accepted',ns['validate_review'](review,facts,prior))
check('typed closed315 policy accepted',ns['validate_policy'](policy,confirmation,receipt,prior,review))
check('immutable prepared314 wording retained with external confirmation',prior['user_step314_checkpoint_confirmed'] is False and confirmation['user_application_completed'] is True)
check('all actual source/archive/pkglist bindings absent',all(value is None for value in review['operational_source_bindings'].values()))
check('five prior reviews and one remaining preserved',len(review['previously_reviewed_requirements'])==5 and len(review['other_deferred_capabilities'])==1)
check('mandatory private coverage preserved',review['candidate_sha256_bindings']==prior['frozen_private_scope']['candidate_sha256_bindings'] and review['mandatory_private_tests']==prior['frozen_private_scope']['mandatory_tests'])
check('historical source17 entries6 dirs11 files retained',facts['historical_source']['non_root_entry_count']==17 and len(facts['historical_source']['directories'])==6 and len(facts['historical_source']['regular_files'])==11)
check('historical observation explicitly point-in-time transcription',facts['historical_source']['observation_is_point_in_time_not_current_or_continuous'] is True and facts['historical_source']['observation_provenance']=='semantic-transcription-of-user-returned-terminal-display')
check('untagged9 compatibility checksum contract retained',facts['historical_source']['checksum_expected_row_count']==9 and facts['historical_source']['tagged_md5_records_forbidden'] is True and facts['historical_source']['compatibility_asc_non_authenticating'] is True)
check('exact eight-field candidate not generation proof',len(facts['historical_candidate']['expected_target_fields'])==8 and facts['historical_candidate']['observed_v4_pkglist_generation_success'] is False)
check('314 durable claim/traps gap remains separate','314-durable-claim-traps-gap-retained' in review['blockers'] and prior['review_only'] is True)
check('five builder slices static-only bound',len(facts['builder_function_slices'])==5 and facts['builder_sha256']==facts['historical_source']['accepted_builder_sha256'])
for rel,digest in ns['OWN_HASHES'].items():
    check('exact bound315 input '+Path(rel).name,hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest)

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
        bad_policy('premature314 boundary ' + key, [key], not value if type(value) is bool else 'stale-binding')
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
    check('original314 receipt drift rejected ' + key,rejected(ns['validate_confirmation'],confirmation,mutate(receipt,[key],value)))
for key in review['proof_state']:
    check('rejects proof overclaim or loss ' + key,rejected(ns['validate_review'],mutate(review,['proof_state',key],not review['proof_state'][key]),facts,prior))
for key in review['requirements']:
    check('rejects weakened source archive requirement ' + key,rejected(ns['validate_review'],mutate(review,['requirements',key],False),facts,prior))
for key in review['operational_source_bindings']:
    check('rejects invented live source binding ' + key,rejected(ns['validate_review'],mutate(review,['operational_source_bindings',key],'synthetic-as-live'),facts,prior))
for index,row in enumerate(review['proof_obligations']):
    check('rejects missing future proof ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'required_evidence'],''),facts,prior))
    check('rejects fixture promoted to conformance ' + row['id'],rejected(ns['validate_review'],mutate(review,['proof_obligations',index,'status'],'operational-PASS'),facts,prior))
for path,value in [(['other_deferred_capabilities'],[]),(['prohibited_current_effects'],[]),(['blockers'],[]),(['prior_review_sha256'],'0'*64),(['source_artifact_map'],[]),(['private_fixture_specification','fixture_SHA_never_real_anchor'],False)]:
    check('review scope drift rejected '+'.'.join(path),rejected(ns['validate_review'],mutate(review,path,value),facts,prior))
record=(fixture/(base+'.tsv')).read_bytes();roles=(fixture/(base+'-source-artifact-map.tsv')).read_bytes();matrix=(fixture/(base+'-source-proof-matrix.tsv')).read_bytes()
check('strict source record artifact map and proof TSV accepted',ns['validate_tables'](record,roles,matrix))
for values,label in [((record+b'step\t315\n',roles,matrix),'duplicate record'),((record.replace(b'actual_pkglist_generated\tno',b'actual_pkglist_generated\tyes'),roles,matrix),'premature generation'),((record,roles.replace(b'not-currently-available-or-bound',b'actual-proven'),matrix),'invented availability'),((record,roles,b'\n'.join(matrix.splitlines()[:-1])+b'\n'),'lost obligation')]:
    check('TSV drift rejected '+label,rejected(ns['validate_tables'],*values))
changed=ns['extract_facts'](raw+b'\n',history[review['freeze_path']],history[review['source_boundary_path']],history[review['builder_path']])
check('same static slices with changed full reference SHA rejected',rejected(ns['validate_review'],review,changed,prior))
changed=ns['extract_facts'](raw,history[review['freeze_path']],history[review['source_boundary_path']],history[review['builder_path']]+b'\n')
check('same builder slices with changed full builder SHA rejected',rejected(ns['validate_review'],review,changed,prior))
for path,value in [(['historical_source','manifest_sha256'],'0'*64),(['historical_source','sidecar_sha256'],'0'*64),(['historical_source','target_sha256'],'0'*64),(['historical_source','regular_files'],[]),(['historical_source','observation_is_point_in_time_not_current_or_continuous'],False),(['historical_candidate','expected_target_fields'],[]),(['adapter_design','update_post_checks'],[])]:
    check('frozen source/candidate fact drift rejected '+'.'.join(path),rejected(ns['validate_review'],review,mutate(facts,path,value),prior))

def model(platform, text=None, recreated=True):
    p=review['private_fixture_specification']
    if text is None:text=' '.join(p['target_fields'])+'\n'
    raw=text.encode();digest=hashlib.sha256(raw).hexdigest()
    pkglist=dict(after_non_symlink=True,after_regular=True,attempt=p['attempt'],before_refresh_absent=True,content_hex=raw.hex(),path=p['pkglist_path'],sha256=digest)
    observations=[]
    for i,action in enumerate(p['actions']):
        row=dict(action=action,archive_sha256=[a['approved_sha256'] for a in p['archives']],attempt=p['attempt'],boot=p['boot'],guard_held=True,observation=i,source_manifest_sha256=p['approved_manifest_sha256'],sidecar_sha256=p['approved_sidecar_sha256'],pkglist_content_hex=None,pkglist_sha256=None,pkglist_regular=None,pkglist_object=None,refresh_exit=None,refresh_stdout=None,refresh_stderr=None)
        if i>=2:row.update(pkglist_content_hex=raw.hex(),pkglist_sha256=digest,pkglist_regular=True,pkglist_object='synthetic-recreated-owned-pkglist' if recreated and i>=4 else 'synthetic-initial-owned-pkglist')
        if action in ['initial-refresh','nested-update']:row.update(refresh_exit=0,refresh_stdout='synthetic complete refresh stream\n',refresh_stderr='')
        observations.append(row)
    return dict(origin='synthetic-private-fixture',scope='synthetic-bytes-and-descriptors-not-current-source-proof',platform=platform,inventory=copy.deepcopy(p['inventory']),manifest_text=p['manifest_text'],sidecar_text=p['sidecar_text'],archives=copy.deepcopy(p['archives']),pkglist=pkglist,observations=observations)

expected=dict(private_fixture_accepted=True,dispatch_authorized=False,actual_source_manifest_revalidated=False,actual_archive_read_or_decoded=False,actual_pkglist_generated=False,actual_candidate_bound=False,actual_selector_equivalence_proven=False,operational_conformance=False,production_entry_closed=True)
for platform in ['Slackware-15.0','Slackware-current']:
    private=model(platform)
    check('synthetic full source archive pkglist binding accepted '+platform,ns['admit_private_fixture'](private)==expected)
    check('new owned pkglist object with identical raw SHA accepted '+platform,ns['admit_private_fixture'](model(platform,recreated=True))==expected)
    check('same owned pkglist object with identical raw SHA accepted '+platform,ns['admit_private_fixture'](model(platform,recreated=False))==expected)
    variant='\n'+'\t'.join(review['private_fixture_specification']['target_fields'])+'\n\n'
    check('initial semantically exact whitespace variant binds own raw SHA '+platform,ns['admit_private_fixture'](model(platform,text=variant))==expected)
    check('baseline may share approved read-only target artifact '+platform,private['archives'][0]['object_id']==private['archives'][2]['object_id'] and private['archives'][0]['approved_sha256']==private['archives'][2]['approved_sha256'])
    for i,row in enumerate(private['inventory']):
        missing=copy.deepcopy(private['inventory']);missing.pop(i)
        check('missing inventory entry rejects '+platform+' '+row['path'],rejected(ns['admit_private_fixture'],mutate(private,['inventory'],missing)))
        for key,value in dict(kind='symlink',mode='777',owner='foreign',object_id='replaced-path-object',alias_count=2,path='./../escape').items():
            check('source identity metadata or alias drift rejects '+platform+' '+row['path']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['inventory',i,key],value)))
        if row['kind']=='regular':
            check('source content drift rejects '+platform+' '+row['path'],rejected(ns['admit_private_fixture'],mutate(private,['inventory',i,'content_hex'],row['content_hex']+'00')))
    for suffix in ['\n','0'*64+'  ./unlisted\n','MD5 (file) = value\n']:
        check('manifest surplus or malformed row rejects '+platform+' '+repr(suffix),rejected(ns['admit_private_fixture'],mutate(private,['manifest_text'],private['manifest_text']+suffix)))
    for text in [private['sidecar_text']+private['sidecar_text'],private['sidecar_text'].replace('local-source-v4.tree.sha256','../different'), '0'*64+'  local-source-v4.tree.sha256\n']:
        check('sidecar duplicate target or digest rejects '+platform+' '+repr(text[:24]),rejected(ns['admit_private_fixture'],mutate(private,['sidecar_text'],text)))
    changed=copy.deepcopy(private);i=next(i for i,r in enumerate(changed['inventory']) if r['path']=='./ChangeLog.txt');changed['inventory'][i]['content_hex']+='00'
    files={r['path']:bytes.fromhex(r['content_hex']) for r in changed['inventory'] if r['kind']=='regular'}
    changed['manifest_text']=''.join(hashlib.sha256(files[name]).hexdigest()+'  '+name+'\n' for name in sorted(files));changed['sidecar_text']=hashlib.sha256(changed['manifest_text'].encode()).hexdigest()+'  local-source-v4.tree.sha256\n'
    check('changed source self-rehash manifest and sidecar cannot authorize '+platform,rejected(ns['admit_private_fixture'],changed))
    extra=copy.deepcopy(private['inventory']);extra.append(dict(extra[-1],path='./slackware64/d/kernel-headers-6.18.44-x86-1.txz'))
    check('predecessor inserted in source rejects '+platform,rejected(ns['admit_private_fixture'],mutate(private,['inventory'],extra)))
    extra=copy.deepcopy(private['inventory']);extra.append(dict(extra[-1],path='./boot/unreviewed'))
    check('extra source entry outside manifest rejects '+platform,rejected(ns['admit_private_fixture'],mutate(private,['inventory'],extra)))
    for i,archive in enumerate(private['archives']):
        for key,value in dict(role='target-only-substitution',path='/synthetic-other/archive.txz',object_id='replaced-object',raw_hex=archive['raw_hex']+'00',approved_sha256='0'*64,decoder='actual-unverified-tar',scripts='unreviewed-install-or-restore-script',writer_exclusion='uncontrolled-writer',member_descriptor_scope='real-decoded-proof').items():
            check('archive role identity script or fake decoder rejects '+platform+' '+archive['role']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['archives',i,key],value)))
        for j,member in enumerate(archive['members']):
            for name in ['../escape','/absolute','usr/include/../../escape','usr/include//alias']:
                check('unreviewed normalized member name rejects '+platform+' '+archive['role']+' '+str(j)+' '+name,rejected(ns['admit_private_fixture'],mutate(private,['archives',i,'members',j,'path'],name)))
        members=copy.deepcopy(archive['members']);members.append(copy.deepcopy(members[-1]))
        check('duplicate member descriptor rejects '+platform+' '+archive['role'],rejected(ns['admit_private_fixture'],mutate(private,['archives',i,'members'],members)))
        for link in ['../../../boot','/etc/passwd','asm']:
            check('unreviewed link escape cycle rejects '+platform+' '+archive['role']+' '+link,rejected(ns['admit_private_fixture'],mutate(private,['archives',i,'members',3,'link_target'],link)))
        for kind in ['hardlink','device','fifo','unknown']:
            check('unreviewed member type rejects '+platform+' '+archive['role']+' '+kind,rejected(ns['admit_private_fixture'],mutate(private,['archives',i,'members',2,'kind'],kind)))
    check('non-string source bytes rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['inventory',6,'content_hex'],True)))
    check('non-string pkglist bytes rejected '+platform,rejected(ns['admit_private_fixture'],mutate(private,['pkglist','content_hex'],True)))
    for key,value in dict(after_non_symlink=False,after_regular=False,before_refresh_absent=False,attempt='prior-attempt',path='/synthetic-old-v2/pkglist',sha256='0'*64,content_hex='').items():
        check('pkglist freshness shape or identity rejects '+platform+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['pkglist',key],value)))
    fields=review['private_fixture_specification']['target_fields']
    row=' '.join(fields)+'\n'
    badtexts=[row+row,row+'extra unrelated row\n',row.replace('./slackware64/d','../escape'),row.replace('6.18.45','6.18.44'), ' '.join(fields[:-1])+'\n',row+'\x00', ' \n\t']
    for text in badtexts:
        candidate=model(platform,text=text)
        check('empty duplicate extra malformed or traversal row rejects '+platform+' '+repr(text[:30]),rejected(ns['admit_private_fixture'],candidate))
    for i,observation in enumerate(private['observations']):
        missing=copy.deepcopy(private['observations']);missing.pop(i)
        check('missing repeated action check rejects '+platform+' '+observation['action'],rejected(ns['admit_private_fixture'],mutate(private,['observations'],missing)))
        for key,value in dict(attempt='foreign',boot='drift',guard_held=False,observation=True,source_manifest_sha256='0'*64,sidecar_sha256='0'*64,archive_sha256=['0'*64]*3).items():
            check('per-action source archive attempt binding rejects '+platform+' '+observation['action']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['observations',i,key],value)))
        if i>=2:
            for key,value in dict(pkglist_regular=False,pkglist_object='foreign-inode',pkglist_sha256='0'*64,pkglist_content_hex=(row+'\n').encode().hex()).items():
                check('per-action bound pkglist drift rejects '+platform+' '+observation['action']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['observations',i,key],value)))
        if observation['action'] in ['initial-refresh','nested-update']:
            for key in ['refresh_stdout','refresh_stderr']:
                check('non-string stream rejected '+platform+' '+observation['action']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['observations',i,key],True)))
            for key,text in [('refresh_stdout','ERROR downloading from synthetic-path\n'),('refresh_stderr','Error downloading from synthetic-path\n')]:
                check('zero exit with human-spaced stream error rejects '+platform+' '+observation['action']+' '+key,rejected(ns['admit_private_fixture'],mutate(private,['observations',i,key],text)))
            check('refresh nonzero exit rejects '+platform+' '+observation['action'],rejected(ns['admit_private_fixture'],mutate(private,['observations',i,'refresh_exit'],20)))
            check('boolean exit code rejects '+platform+' '+observation['action'],rejected(ns['admit_private_fixture'],mutate(private,['observations',i,'refresh_exit'],False)))
    changed=copy.deepcopy(private);variant_bytes=(row+'\n').encode();new_sha=hashlib.sha256(variant_bytes).hexdigest()
    for obs in changed['observations'][4:]:obs.update(pkglist_content_hex=variant_bytes.hex(),pkglist_sha256=new_sha)
    check('nested semantically equal bytes self-rebind rejects '+platform,rejected(ns['admit_private_fixture'],changed))
    check('synthetic archive digest never equals historical target anchor '+platform,private['archives'][0]['approved_sha256']!=facts['historical_source']['target_sha256'])
for key,value in dict(origin='actual-source-probe',scope='real-source-continuity',platform='unreviewed',inventory=[],archives=[],observations=[]).items():
    check('private provenance or missing completeness rejects '+key,rejected(ns['admit_private_fixture'],mutate(model('Slackware-current'),[key],value)))
check('extra dispatch authority field rejects',rejected(ns['admit_private_fixture'],dict(model('Slackware-current'),dispatch_authorized=True)))
check('all actual source bindings remain null',all(value is None for value in review['operational_source_bindings'].values()))

for argv in [[], ['--bogus'], ['--output-dir'], ['--output-dir', ''], ['--output-dir', 'x', 'extra']]:
    check('strict review CLI ' + repr(argv), run(['bash', tool, *argv]).returncode == 2)
check('review help states closed repository scope', 'Repository-only' in run(['bash', tool, '--help']).stdout)
for script in [tool, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax ' + script.name, run(['bash', '-n', script]).returncode == 0)

with tempfile.TemporaryDirectory(prefix='step315-harness-') as directory:
    area = Path(directory)
    out = area / 'published'
    out.mkdir()
    result = run(['bash', tool, '--output-dir', out])
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
    check('real315 review entry reruns full unchanged1173 predecessor acceptance', result.returncode == 0 and 'exact_step314_acceptance\tPASS (1173 passes, 0 failures)' in result.stdout)
    old_log = (out / (base + '-predecessor-test.log')).read_text()
    check('exact full1173 predecessor sequence retained', sum(line.startswith('PASS: ') for line in old_log.splitlines()) == 1173 and old_log.splitlines()[-1] == 'Result: PASS (1173 passes, 0 failures)')
    names = [base + suffix for suffix in ['-policy.json', '-review.json', '-checkpoint-confirmation.json', '-step314-user-acceptance.json', '.tsv', '-source-artifact-map.tsv', '-source-proof-matrix.tsv']]
    for name in names:
        check('exact published315 review input ' + name, (out / name).read_bytes() == (fixture / name).read_bytes())
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
        'tests/fixtures/reference/acceptance/phase-1/' + ns['PRIOR'] + '-policy.json', review['source_boundary_path'], review['builder_path'],
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
check('all1409 predecessor artifacts preserved after acceptance', ns['verify_history'](root, policy['accepted_checkpoint'], ns['CHANGELOG_PREFIX'].encode()) == history)
for rel in list(ns['OWN_HASHES']) + ['tools/reference/' + base + '.sh', 'tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
print('Result: PASS (' + str(passes) + ' passes, 0 failures)')
PYTEST
