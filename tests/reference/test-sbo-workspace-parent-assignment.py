#!/usr/bin/env python3
"""Check failed private SBo parent assignment before its mkdir/install/cat compound."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
REFERENCE=ROOT/'tools/reference/slack-update-reference.sh'
spec=importlib.util.spec_from_file_location('workspace_count_support',Path(__file__).with_name('test-sbo-workspace-count.py'))
fixture=importlib.util.module_from_spec(spec);spec.loader.exec_module(fixture)
FAULTS=('none','parent-1','parent-43','parent-127','parent-stderr','quiet-43')

PARENT=r'''
dirname() {
    [[ $# == 2 && $1 == -- ]] || forbidden dirname-vector
    local ordinal
    case "$2" in
        "$WORKSPACE/nested/private.sqf") ordinal=1 ;;
        "$WORKSPACE/top.sqf") ordinal=2 ;;
        *) forbidden dirname-path ;;
    esac
    record parent dirname "$@"
    if [[ $ordinal == "$PARENT_AT" ]]; then
        case "$PARENT_FAULT" in
            quiet-43) return 43 ;;
            parent-1) builtin command dirname "$@" || return; return 1 ;;
            parent-43) builtin command dirname "$@" || return; return 43 ;;
            parent-127) builtin command dirname "$@" || return; return 127 ;;
            parent-stderr)
                builtin command dirname "$@" || return
                builtin printf 'supplied dirname failure with valid output\n' >&2
                return 43 ;;
        esac
    fi
    builtin command dirname "$@"
}
mkdir() {
    if [[ $# == 4 && $1 == -m && $2 == 0700 && $3 == -- && $4 == "$WORKSPACE" ]]; then
        :
    elif [[ $# == 5 && $1 == -p && $2 == -m && $3 == 0700 && $4 == -- &&
            ( $5 == "$WORKSPACE" || $5 == "$WORKSPACE/nested" || -z $5 ) ]]; then
        :
    else forbidden mkdir-vector; fi
    record parent mkdir "$@"
    if [[ $# == 5 && -z $5 ]]; then
        builtin printf 'supplied empty parent rejection\n' >&2
        return 43
    fi
    builtin command mkdir "$@"
}
'''


def scenario(reference,root,profile,fault,ordinal,entry,cleanup='none'):
    personal=root/'personal';workspace=root/'workspace'
    (root/'sentinel').write_bytes(b'untouched\n')
    if profile!='missing':personal.mkdir()
    if profile=='full':
        (personal/'nested').mkdir();(personal/'top.sqf').write_bytes(b'alpha\n')
        (personal/'nested/private.sqf').write_bytes(b'beta\n');(personal/'note.txt').write_bytes(b'preserved\n')
        (personal/'link.sqf').symlink_to('../sentinel');(personal/'nested/link.sqf').symlink_to('../../sentinel')
    before=fixture.inventory(root);expected=before.copy()
    failed=profile=='full' and fault!='none'
    retained=failed and cleanup in ('owned-fail','canonical-fail','mismatch')
    copied=ordinal-1 if failed else 2 if profile=='full' else 0
    links=2 if profile=='full' else 0
    failing_relative='nested/private.sqf' if ordinal==1 else 'top.sqf'
    error='cannot derive private SBo queue parent directory: '+str(workspace/failing_relative) if failed else ''
    raw=1 if failed and entry=='direct' else 0
    source=str(root/'old-source') if failed and entry=='direct' else '' if failed else str(workspace)
    owned=str(workspace) if not failed or retained else ''
    state=['0' if entry=='sync' else '17',
        '1' if entry=='sync' and failed else '0' if entry=='sync' else '18',
        '0' if entry=='sync' and failed else '1' if entry=='sync' else '9',
        source,str(copied),str(links),error,owned,owned,
        str(root/'private.conf') if entry=='sync' and not failed else 'old-conf']
    values=dict(PERSONAL=personal,WORKSPACE=workspace,FAULT='none',CLEANUP=cleanup,PARENT_FAULT=fault,PARENT_AT=ordinal,
        symlink_count='outer-count-sentinel',destination_parent='outer-parent-sentinel',SBOPKG_SYNC_STATUS=17,
        SQG_SYNC_STATUS=18,SBO_QUEUE_GENERATION_READY=9,SBO_QUEUE_SOURCE_DIR=root/'old-source',
        SBO_PERSONAL_QUEUE_FILE_COUNT=8,SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,SBO_TARGET_SELECTION_ERROR='old-error',
        SBO_GENERATED_QUEUE_OWNED_PATH='',SBO_GENERATED_QUEUE_OWNED_CANONICAL='',SBO_PRIVATE_SBOPKG_CONFIG='old-conf',
        SBO_GENERATED_QUEUE_DIR=workspace,SBOPKG_CONFIG=root/'original.conf',SBOPKG_CONF='outer-conf',QUEUEDIR='outer-queue')
    shell=fixture.PREFIX+PARENT+'\n'+'\n'.join(n+'() { forbidden '+n+'; }' for n in fixture.GUARDS)+'\n'
    shell+='\n'.join(n+'='+shlex.quote(str(v)) for n,v in values.items())+"\nIFS='|: '\nsaved_ifs=$IFS\n"
    shell+=('synchronize_sbo_repository' if entry=='sync' else 'prepare_private_sbo_queue_workspace "$PERSONAL" "$WORKSPACE"')+'\nraw=$?\n'
    shell+='[[ $symlink_count == outer-count-sentinel && $destination_parent == outer-parent-sentinel && $IFS == "$saved_ifs" && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue ]] || exit 96\n'
    shell+='builtin printf "\\0STATE\\0%s\\0" "$raw"\n'+'\n'.join('builtin printf "%s\\0" "${'+n+'}"' for n in fixture.FIELDS)
    result=subprocess.run(['bash','--noprofile','--norc','-c',shell,'workspace-parent-assignment',str(reference),str(root)],
        capture_output=True,cwd=root,timeout=10,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)))
    main=[('discover','sbopkg'),('discover','sqg'),('sbopkg','-r'),('resolve',)] if entry=='sync' else []
    main += [('workspace',str(personal),str(workspace)),('workspace-return',1 if failed else 0)]
    output=''
    if entry=='sync':
        output='[5] Sync SBo\n'
        if failed:output+='  [ERROR] '+error+'\n'
        else:
            main += [('config',str(root/'original.conf'),str(workspace)),('sqg','-a')]
            output+=f'  Personal queue directory preserved read-only: {personal}\n  Private sqg workspace: {workspace}\n  Personal queue files copied: {copied}\n'
            if links:output+=f'  [WARN] Personal queue symlinks ignored: {links}\n'
    stderr=b'supplied dirname failure with valid output\n' if profile=='full' and fault=='parent-stderr' else b''
    wanted=output.encode()+b'\0STATE\0'+str(raw).encode()+b'\0'+b''.join(v.encode()+b'\0' for v in state)
    assert (result.returncode,result.stdout,result.stderr)==(0,wanted,stderr),(profile,fault,ordinal,entry,result.returncode,result.stdout,wanted,result.stderr)
    names=('main','regular-find','link-find','count','removal','canonical','copy','parent')
    logs={n:(root/(n+'.events')).read_bytes() if (root/(n+'.events')).exists() else b'' for n in names}
    assert logs['main']==fixture.encode(main)
    existing=profile!='missing'
    assert logs['regular-find']==(fixture.encode([(str(personal),'-type','f','-name','*.sqf','-print0')]) if existing else b'')
    assert logs['link-find']==(fixture.encode([(str(personal),'-type','l','-name','*.sqf','-printf','.')]) if existing else b'')
    assert logs['count']==(fixture.encode([('-c',)]) if existing else b'')
    removal=[('listing','-f')] if existing else []
    if failed and cleanup not in ('canonical-fail','mismatch'):removal.append(('owned-workspace','-rf','--',str(workspace)))
    assert logs['removal']==fixture.encode(removal)
    assert logs['canonical']==(fixture.encode([('-m','--',str(workspace))]) if failed else b'')
    parent=[('mkdir','-m','0700','--',str(workspace))];copies=[]
    if profile=='full':
        for number,relative in enumerate(('nested/private.sqf','top.sqf'),1):
            parent.append(('dirname','--',str(workspace/relative)))
            if failed and number==ordinal:break
            parent.append(('mkdir','-p','-m','0700','--',str((workspace/relative).parent)))
            copies += [('install','-m','0600','/dev/null',str(workspace/relative)),('cat','--',str(personal/relative))]
    assert logs['parent']==fixture.encode(parent),(profile,fault,ordinal,entry,'parent command vectors')
    assert logs['copy']==fixture.encode(copies)
    if not failed or retained:
        expected['workspace']=('dir',0o700)
        if profile=='full' and copied:
            expected['workspace/nested']=('dir',0o700)
            expected['workspace/nested/private.sqf']=('file',b'beta\n',0o600)
            if copied==2:expected['workspace/top.sqf']=('file',b'alpha\n',0o600)
    listings=list(root.glob('tmp.*'))
    assert len(listings)==int(failed and cleanup=='listing-fail'),(profile,fault,ordinal,entry,cleanup,'listings')
    if listings:
        expected[listings[0].name]=('file',b''.join((str(personal/relative)+'\0').encode() for relative in ('nested/private.sqf','top.sqf')),0o600)
    actual=fixture.inventory(root);assert actual==expected,(profile,fault,ordinal,entry,'inventory')
    assert all(actual[n]==value for n,value in before.items())
    return dict(profile=profile,fault=fault,parent_ordinal=ordinal,entry=entry,cleanup=cleanup,
        rejected_parent_status=failed,helper_status=1 if failed else 0,raw_status=raw,copied_files=copied,
        symlinks=links,source_published=not failed,sqg_entered=entry=='sync' and not failed,
        listing_retained=bool(failed and cleanup=='listing-fail'),workspace_retained=retained)

def cases():
    selected=list(itertools.product(('missing','empty','full'),FAULTS,(1,2),('direct','sync')))
    selected += [(*case,cleanup) for case in itertools.product(('full',),('parent-43','quiet-43'),(1,2),('direct','sync'))
        for cleanup in ('listing-fail','owned-fail','canonical-fail','mismatch')]
    return selected


def main():
    rows=[]
    with tempfile.TemporaryDirectory(prefix='slack-update-workspace-parent-') as temporary:
        for number,case in enumerate(cases()):
            root=Path(temporary).resolve()/str(number);root.mkdir();rows.append(scenario(REFERENCE,root,*case))
    assert len(rows)==104 and sum(r['rejected_parent_status'] for r in rows)==52
    assert sum(r['listing_retained'] for r in rows)==8 and sum(r['workspace_retained'] for r in rows)==24
    print('SBo workspace parent assignment: 104 scenarios, 0 failures')


if __name__=='__main__':main()
