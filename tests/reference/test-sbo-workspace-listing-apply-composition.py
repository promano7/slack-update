#!/usr/bin/env python3
"""Compose final workspace-listing failure through real private apply/result gates."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
REFERENCE=ROOT/'tools/reference/slack-update-reference.sh'
def load(name,filename):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(filename))
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
workflow=load('count_apply_scaffolding','test-sbo-workspace-apply-composition.py')
listing=load('listing_removal_faults','test-sbo-workspace-listing-removal.py')
fixture=workflow.fixture
PREFIX=workflow.PREFIX+listing.REMOVAL
GUARDS=workflow.GUARDS
FIELDS=workflow.FIELDS


def scenario(reference,root,profile,fault,sbo,sync_code,cleanup='none'):
    personal=root/'personal';workspace=root/'workspace'
    (root/'sentinel').write_text('untouched\n')
    if profile!='missing':personal.mkdir()
    if profile=='full':
        (personal/'nested').mkdir();(personal/'top.sqf').write_text('alpha\n')
        (personal/'nested/private.sqf').write_text('beta\n');(personal/'note.txt').write_text('preserved\n')
        (personal/'link.sqf').symlink_to('../sentinel');(personal/'nested/link.sqf').symlink_to('../../sentinel')
    for name in ('core','extra','options','final','broken'):(root/name).write_text('old-'+name+'\n')
    before=fixture.inventory(root);expected=before.copy()
    early=bool(sbo and profile!='missing' and fault!='none')
    retained=early and cleanup in ('owned-fail','canonical-fail','mismatch')
    active_count=bool(sbo and profile!='missing')
    error='cannot remove personal SBo queue listing' if early else ''
    state='disabled' if not sbo else 'failed' if early or sync_code else 'success'
    rows=[];output='';errors=[]
    def file(name,value):expected[name]=('file',value.encode(),before[name][2])
    if sbo:
        rows += [('sync',),('discover','sbopkg'),('discover','sqg'),('sbopkg','-r'),('resolve',),
                 ('workspace',str(personal),str(workspace)),('workspace-return',1 if early else 0)]
        output='[5] Sync SBo\n'
        if early:output+='  [ERROR] '+error+'\n'
        else:
            rows += [('config',str(root/'original.conf'),str(workspace)),('sqg','-a')]
            output+=f'  Personal queue directory preserved read-only: {personal}\n  Private sqg workspace: {workspace}\n  Personal queue files copied: {2 if profile=="full" else 0}\n'
            if profile=='full':output+='  [WARN] Personal queue symlinks ignored: 2\n'
        rows += [('sync-return',0),('action','sbo','synchronize','failed' if early or sync_code else 'success','SBo repository synchronization completed',sync_code if sync_code else 1 if early else 0),('gate',)]
        if not early:rows += [('core',),('abi',)]
        rows.append(('gate-return',1 if early else 0))
        rows.append(('action','sbo','build_queues','failed' if early else 'success','SBo target selection failed: '+error if early else 'Deterministic SBo target sets built',1 if early else 0))
        if sync_code:errors.append('sbopkg repository synchronization failed with exit code '+str(sync_code))
        if early:errors += ['sqg queue generation failed with exit code 1','SBo target selection failed: '+error]
    else:
        rows += [('action','sbo','synchronize','disabled','SBo repository synchronization was not applicable: supplied-off',0),
                 ('action','sbo','build_queues','disabled','SBo queue generation was not applicable: supplied-off',0)]
    for name in ('core','extra','options','broken'):file(name,'')
    total=2 if sbo and not early and profile=='full' else 0
    if sbo and not early:
        file('core','core-a\ncore-b\n' if profile=='full' else '');file('final','core-a\ncore-b\n' if profile=='full' else '')
        rows += [('process',),('action','sbo','process_queue',state,'Final SBo queue processing completed',0)]
    elif sbo:rows.append(('action','sbo','process_queue','failed','SBo queue processing was blocked because target selection failed',1))
    else:rows.append(('action','sbo','process_queue','disabled','SBo queue processing was not applicable: supplied-off',0))
    rows += [('module','sbo',state,'SBo update module completed',1 if early else 0),('boot-callback',),('summary','success','disabled',state,'disabled','disabled',0)]
    if sbo and (not early or retained):
        expected['workspace']=('dir',0o700)
        if profile=='full':
            expected['workspace/nested']=('dir',0o700)
            expected['workspace/top.sqf']=('file',b'alpha\n',0o600)
            expected['workspace/nested/private.sqf']=('file',b'beta\n',0o600)
    owned=str(workspace) if sbo and (not early or retained) else ''
    fields=[2 if errors else 0,0 if errors else 1,1 if errors else 0,1,'none',
            sync_code if sbo else -1,1 if early else 0 if sbo else -1,1 if sbo and not early else 0,
            1 if early else 0 if sbo else -1,0 if sbo and not early else -1,
            2 if sbo and profile=='full' else 0 if sbo else 8,
            2 if sbo and profile=='full' else 0 if sbo else 7,
            total,0,0,total,total,error,str(workspace) if sbo and not early else '' if sbo else str(root/'old-source'),
            owned,owned,str(root/'private.conf') if sbo and not early else 'old-conf']
    values=dict(PERSONAL=str(personal),WORKSPACE=str(workspace),FAULT='none',FINAL_FAULT=fault,CLEANUP=cleanup,PROFILE=profile,
        SBO_RUN=sbo,SYNC_CODE=sync_code,symlink_count='outer-count-sentinel',SBO_PERSONAL_QUEUE_FILE_COUNT=8,
        SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,SBO_QUEUE_SOURCE_DIR=str(root/'old-source'),SBO_PRIVATE_SBOPKG_CONFIG='old-conf',
        SBO_GENERATED_QUEUE_DIR=str(workspace),SBOPKG_CONFIG=str(root/'original.conf'),SBOPKG_CONF='outer-conf',QUEUEDIR='outer-queue',
        QUEUE_CORE=str(root/'core'),QUEUE_EXTRA=str(root/'extra'),QUEUE_FINAL=str(root/'final'),SBO_OPTION_RECORDS=str(root/'options'),
        SBO_OPTIONS_FILE=str(root/'overrides'),BROKEN=str(root/'broken'),TOTAL=0,TOTAL_CORE=6,SBO_OPTION_RECORD_COUNT=5,TOTAL_EXTRA=4,
        OPERATION='apply',FLATPAK_MODE='disabled',SBO_MODE='auto',ELF_MODE='disabled',CINNAMON_MODE='disabled',BOOT_MODE='disabled',SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell=PREFIX+'\n'+'\n'.join(n+'() { forbidden '+n+'; }' for n in GUARDS)+'\ninitialize_runtime_state || exit 96\n'
    shell+='\n'.join(n+'='+shlex.quote(str(v)) for n,v in values.items())+"\nIFS='|: '\naction_exit=77;sbo_state=outer-sbo\nraw=0\nrun_apply_workflow || raw=$?\ndetermine_stable_exit_code \"$raw\"\n"
    shell+='[[ $symlink_count == outer-count-sentinel && $IFS == "|: " && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue && $action_exit == 77 && $sbo_state == outer-sbo ]] || exit 95\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell+='\n'.join('builtin printf "%s\\0" "${'+n+'}"' for n in FIELDS)+r'''
builtin printf 'ERRORS\0';builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0';builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
'''
    p=subprocess.run(['bash','--noprofile','--norc','-c',shell,'workspace-apply-composition',str(reference),str(root)],cwd=root,capture_output=True,timeout=15,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)))
    wanted=output.encode()+b'\0STATE\0'+b''.join(str(v).encode()+b'\0' for v in [0,*fields])+b'ERRORS\0'+b''.join(e.encode()+b'\0' for e in (errors or ['']))+b'WARNINGS\0\0'
    stderr=b'supplied final listing removal failure\n' if sbo and profile!='missing' and fault=='stderr-127' else b''
    assert p.returncode==0 and p.stdout==wanted and p.stderr==stderr,(profile,fault,sbo,sync_code,cleanup,p.returncode,p.stdout,wanted,p.stderr)
    logs={n:(root/(n+'.events')).read_bytes() if (root/(n+'.events')).exists() else b'' for n in ('main','regular-find','link-find','count','removal','canonical','copy')}
    assert logs['main']==fixture.encode(rows),(profile,fault,sbo,sync_code,cleanup,logs['main'],fixture.encode(rows))
    assert logs['regular-find']==(fixture.encode([(str(personal),'-type','f','-name','*.sqf','-print0')]) if sbo and profile!='missing' else b'')
    assert logs['link-find']==(fixture.encode([(str(personal),'-type','l','-name','*.sqf','-printf','.')]) if active_count else b'')
    assert logs['count']==(fixture.encode([('-c',)]) if active_count else b'')
    removal=([('listing','-f')]+([] if cleanup in ('canonical-fail','mismatch') else [('owned-workspace','-rf','--',str(workspace))])) if early else [('listing','-f')] if sbo and profile!='missing' else []
    assert logs['removal']==fixture.encode(removal)
    assert logs['canonical']==(fixture.encode([('-m','--',str(workspace))]) if early else b'')
    copy=[]
    if sbo and profile=='full':
        for relative in ('nested/private.sqf','top.sqf'):copy += [('install','-m','0600','/dev/null',str(workspace/relative)),('cat','--',str(personal/relative))]
    assert logs['copy']==fixture.encode(copy)
    listings=list(root.glob('tmp.*'));assert len(listings)==int(early and fault!='removed-43')
    if listings:expected[listings[0].name]=('file',(str(personal/'nested/private.sqf')+'\0'+str(personal/'top.sqf')+'\0').encode() if profile=='full' else b'',0o600)
    assert fixture.inventory(root)==expected,(profile,fault,sbo,sync_code,cleanup,'inventory differs')
    assert all(fixture.inventory(root)[n]==v for n,v in before.items() if n not in ('core','extra','options','final','broken'))

    return dict(profile=profile,fault=fault,sbo=sbo,sync_code=sync_code,cleanup=cleanup,
        listing_failure_rejected=early,workspace_retained=retained,
        listing_retained=bool(early and fault!='removed-43'),raw_status=0,stable_status=2 if errors else 0,
        prior_sync_policy_reaches_supplied_build=bool(sbo and sync_code and not early))

def cases():
    selected=list(itertools.product(('missing','empty','full'),listing.FAULTS,(0,1),(0,43)))
    selected += [(*case,cleanup) for case in itertools.product(('empty','full'),
        ('quiet-43','removed-43'),(1,),(0,43)) for cleanup in ('owned-fail','canonical-fail','mismatch')]
    return selected


def main():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='slack-update-listing-apply-') as temporary:
        for number,case in enumerate(cases()):
            root=Path(temporary).resolve()/str(number);root.mkdir()
            rows.append(scenario(REFERENCE,root,*case))
    assert len(rows)==84 and sum(r['listing_failure_rejected'] for r in rows)==40
    assert sum(r['workspace_retained'] for r in rows)==24 and sum(r['listing_retained'] for r in rows)==24
    print('SBo workspace final listing apply composition: 84 scenarios, 0 failures')


if __name__=='__main__':main()
