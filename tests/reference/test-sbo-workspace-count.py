#!/usr/bin/env python3
"""Check private workspace count failures before copy and sync readiness."""
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
REFERENCE=ROOT/'tools/reference/slack-update-reference.sh'
FAULTS=('none','find-quiet','find-partial','wc-1','wc-43','wc-127','wc-partial','wc-zero','wc-stderr','enumerate')
FIELDS=('SBOPKG_SYNC_STATUS','SQG_SYNC_STATUS','SBO_QUEUE_GENERATION_READY','SBO_QUEUE_SOURCE_DIR',
        'SBO_PERSONAL_QUEUE_FILE_COUNT','SBO_PERSONAL_QUEUE_SYMLINK_COUNT','SBO_TARGET_SELECTION_ERROR',
        'SBO_GENERATED_QUEUE_OWNED_PATH','SBO_GENERATED_QUEUE_OWNED_CANONICAL','SBO_PRIVATE_SBOPKG_CONFIG')
PREFIX=r'''
source "$1"
TEST_ROOT=$2
record() { local name=$1;shift;builtin printf '%s\0' "$@" >> "$TEST_ROOT/$name.events";builtin printf '\n' >> "$TEST_ROOT/$name.events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2;exit 97; }
definition=$(declare -f prepare_private_sbo_queue_workspace)
eval "${definition/prepare_private_sbo_queue_workspace/real_prepare_private_sbo_queue_workspace}"
unset definition
prepare_private_sbo_queue_workspace() {
    record main workspace "$@"
    local status=0
    real_prepare_private_sbo_queue_workspace "$@" || status=$?
    record main workspace-return "$status"
    return "$status"
}
command() {
    [[ $# == 2 && $1 == -v && ( $2 == sbopkg || $2 == sqg ) ]] || forbidden discovery-vector
    record main discover "$2"
    return 0
}
find() {
    [[ $1 == "$PERSONAL" && $2 == -type && $4 == -name && $5 == '*.sqf' ]] || forbidden find-path
    if [[ $# == 6 && $3 == f && $6 == -print0 ]];then
        record regular-find "$@"
        if [[ $FAULT == enumerate ]];then builtin printf '%s\0' "$PERSONAL/top.sqf";return 43;fi
    elif [[ $# == 7 && $3 == l && $6 == -printf && $7 == . ]];then
        record link-find "$@"
        if [[ $FAULT == find-quiet ]];then return 43;fi
        if [[ $FAULT == find-partial ]];then builtin printf .;return 43;fi
    else forbidden find-vector;fi
    builtin command find "$@"
}
wc() {
    [[ $# == 1 && $1 == -c ]] || forbidden count-vector
    record count "$@"
    case "$FAULT" in
        wc-1) return 1 ;;
        wc-43) return 43 ;;
        wc-127) return 127 ;;
        wc-partial) builtin printf '42\n';return 43 ;;
        wc-zero) builtin printf '0\n';return 43 ;;
        wc-stderr) builtin printf 'supplied audit count failure\n' >&2;return 43 ;;
    esac
    builtin command wc "$@"
}
rm() {
    if [[ $# == 3 && $1 == -rf && $2 == -- && $3 == "$WORKSPACE" ]];then
        record removal owned-workspace "$@"
        [[ $CLEANUP != owned-fail ]] || return 43
    elif [[ $# == 2 && $1 == -f && $2 == "$TEST_ROOT/"tmp.* ]];then
        record removal listing -f
        [[ $CLEANUP != listing-fail ]] || return 43
    else forbidden remove-vector;fi
    builtin command rm "$@"
}
readlink() {
    [[ $# == 3 && $1 == -m && $2 == -- && ( $3 == "$PERSONAL" || $3 == "$WORKSPACE" ) ]] || forbidden canonical-vector
    if [[ $3 == "$WORKSPACE" && -d $WORKSPACE ]]; then
        record canonical "$@"
        case "$CLEANUP" in
            canonical-fail) return 43 ;;
            mismatch) builtin printf '%s\n' "$TEST_ROOT/other-workspace";return 0 ;;
        esac
    fi
    builtin command readlink "$@"
}
install() { record copy install "$@";builtin command install "$@"; }
cat() { record copy cat "$@";builtin command cat "$@"; }
sbopkg() { [[ $# == 1 && $1 == -r ]] || forbidden sync-vector;record main sbopkg "$@";return 0; }
sqg() { [[ $# == 1 && $1 == -a && $QUEUEDIR == "$WORKSPACE" && $SBOPKG_CONF == "$TEST_ROOT/private.conf" ]] || forbidden sqg-vector;record main sqg "$@";return 0; }
resolve_sbo_personal_queue_directory() { record main resolve;SBO_PERSONAL_QUEUE_DIR=$PERSONAL; }
prepare_private_sqg_configuration() {
    [[ $# == 2 && $1 == "$TEST_ROOT/original.conf" && $2 == "$WORKSPACE" ]] || forbidden config-vector
    record main config "$@"
    SBO_PRIVATE_SBOPKG_CONFIG=$TEST_ROOT/private.conf
}
'''
GUARDS=('main','initialize_execution_environment','initialize_runtime','load_configuration','configure_logging',
        'run_apply_workflow','run_check_workflow','run_dry_run_workflow','slackpkg','flatpak','git','curl','wget',
        'readelf','ldconfig','regenerate_initrd','update_grub_configuration','build_sbo_core_queue',
        'build_and_apply_sbo_queue','detect_broken_elf_objects','map_broken_objects_to_sbo_packages')


def inventory(root):
    result={}
    for p in root.rglob('*'):
        if p.name.endswith('.events'):continue
        mode=p.lstat().st_mode&0o777
        result[p.relative_to(root).as_posix()]=('link',os.readlink(p),mode) if p.is_symlink() else ('dir',mode) if p.is_dir() else ('file',p.read_bytes(),mode)
    return result


def encode(rows):return b''.join(b''.join(str(v).encode()+b'\0' for v in row)+b'\n' for row in rows)


def scenario(reference,root,profile,fault,entry,cleanup="none"):
    personal=root/'personal';workspace=root/'workspace'
    (root/'sentinel').write_text('untouched\n')
    if profile!='missing':personal.mkdir()
    if profile=='full':
        (personal/'nested').mkdir();(personal/'top.sqf').write_text('alpha\n')
        (personal/'nested/private.sqf').write_text('beta\n');(personal/'note.txt').write_text('preserved\n')
        (personal/'link.sqf').symlink_to('../sentinel');(personal/'nested/link.sqf').symlink_to('../../sentinel')
    before=inventory(root);expected=before.copy()
    early=profile!='missing' and fault!='none'
    count_failed=early and fault!='enumerate'
    retained=early and cleanup in ('owned-fail','canonical-fail','mismatch')
    count={'find-quiet':'0','find-partial':'1','wc-partial':'42','wc-zero':'0'}.get(fault,'' if fault.startswith('wc-') else '2' if profile=='full' else '0')
    if profile=='missing' or early:count='0'
    copied=2 if profile=='full' and not early else 0
    error=('cannot count personal SBo queue symlinks: ' if count_failed else 'cannot enumerate personal SBo queue files: ')+str(personal) if early else ''
    state=['0' if entry=='sync' else '17','1' if early and entry=='sync' else '0' if entry=='sync' else '18',
           '0' if early and entry=='sync' else '1' if entry=='sync' else '9',
           '' if early and entry=='sync' else str(root/'old-source') if early else str(workspace),
           str(copied),count,error,str(workspace) if retained and cleanup!='mismatch' or not early else '',str(workspace) if retained and cleanup!='mismatch' or not early else '',
           str(root/'private.conf') if entry=='sync' and not early else 'old-conf']
    raw=1 if early and entry=='direct' else 0
    main=[]
    if entry=='sync':main += [('discover','sbopkg'),('discover','sqg'),('sbopkg','-r'),('resolve',)]
    main += [('workspace',str(personal),str(workspace)),('workspace-return',1 if early else 0)]
    output=''
    if not early or retained:
        expected['workspace']=('dir',0o700)
        if profile=='full' and not early:
            expected['workspace/nested']=('dir',0o700)
            expected['workspace/top.sqf']=('file',b'alpha\n',0o600)
            expected['workspace/nested/private.sqf']=('file',b'beta\n',0o600)
    if entry=='sync':
        output='[5] Sync SBo\n'
        if early:output+='  [ERROR] '+error+'\n'
        else:
            main += [('config',str(root/'original.conf'),str(workspace)),('sqg','-a')]
            output+=f'  Personal queue directory preserved read-only: {personal}\n  Private sqg workspace: {workspace}\n  Personal queue files copied: {copied}\n'
            if count and int(count)>0:output+='  [WARN] Personal queue symlinks ignored: '+count+'\n'
    values=dict(PERSONAL=str(personal),WORKSPACE=str(workspace),FAULT=fault,CLEANUP=cleanup,symlink_count='outer-count-sentinel',SBOPKG_SYNC_STATUS=17,SQG_SYNC_STATUS=18,
        SBO_QUEUE_GENERATION_READY=9,SBO_QUEUE_SOURCE_DIR=str(root/'old-source'),SBO_PERSONAL_QUEUE_FILE_COUNT=8,
        SBO_PERSONAL_QUEUE_SYMLINK_COUNT=7,SBO_TARGET_SELECTION_ERROR='old-error',SBO_GENERATED_QUEUE_OWNED_PATH='',
        SBO_GENERATED_QUEUE_OWNED_CANONICAL='',SBO_PRIVATE_SBOPKG_CONFIG='old-conf',SBO_GENERATED_QUEUE_DIR=str(workspace),
        SBOPKG_CONFIG=str(root/'original.conf'),SBOPKG_CONF='outer-conf',QUEUEDIR='outer-queue')
    script=PREFIX+'\n'+'\n'.join(n+'() { forbidden '+n+'; }' for n in GUARDS)+'\n'
    script+='\n'.join(n+'='+shlex.quote(str(v)) for n,v in values.items())+"\nIFS='|: '\nsaved_ifs=$IFS\n"
    script+=('synchronize_sbo_repository' if entry=='sync' else 'prepare_private_sbo_queue_workspace "$PERSONAL" "$WORKSPACE"')+'\nraw=$?\n'
    script+='[[ $symlink_count == outer-count-sentinel && $IFS == "$saved_ifs" && $SBOPKG_CONF == outer-conf && $QUEUEDIR == outer-queue ]] || exit 96\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script+='\n'.join('builtin printf "%s\\0" "${'+n+'}"' for n in FIELDS)
    result=subprocess.run(['bash','--noprofile','--norc','-c',script,'workspace512-audit',str(reference),str(root)],
        capture_output=True,cwd=root,timeout=10,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)))
    wanted=output.encode()+b'\0STATE\0'+str(raw).encode()+b'\0'+b''.join(v.encode()+b'\0' for v in state)
    stderr=b'supplied audit count failure\n' if profile!='missing' and fault=='wc-stderr' else b''
    stderr_ok=result.stderr==stderr
    assert result.returncode==0 and result.stdout==wanted and stderr_ok,(profile,fault,entry,result.returncode,result.stdout,wanted,result.stderr)
    logs={name:(root/(name+'.events')).read_bytes() if (root/(name+'.events')).exists() else b'' for name in ('main','regular-find','link-find','count','removal','canonical','copy')}
    assert logs['main']==encode(main),(profile,fault,entry,logs['main'],main)
    assert logs['regular-find']==(encode([(str(personal),'-type','f','-name','*.sqf','-print0')]) if profile!='missing' else b'')
    expected_links=encode([(str(personal),'-type','l','-name','*.sqf','-printf','.')]) if profile!='missing' and fault!='enumerate' else b''
    assert logs['link-find']==expected_links
    assert logs['count']==(encode([('-c',)]) if expected_links else b'')
    if early:
        assert logs['removal']==encode([('listing','-f')]+([] if cleanup in ('canonical-fail','mismatch') else [('owned-workspace','-rf','--',str(workspace))]))
    elif profile!='missing':assert logs['removal']==encode([('listing','-f')])
    else:assert logs['removal']==b''
    assert logs['canonical']==(encode([('-m','--',str(workspace))]) if early else b'')
    copy=[]
    if profile=='full' and not early:
        for relative in ('nested/private.sqf','top.sqf'):
            copy += [('install','-m','0600','/dev/null',str(workspace/relative)),('cat','--',str(personal/relative))]
    assert logs['copy']==encode(copy),(profile,fault,entry,cleanup,'copy entered before valid count')
    listings=list(root.glob('tmp.*'))
    assert len(listings)==(1 if early and cleanup=='listing-fail' else 0)
    if listings:
        listing_bytes=(str(personal/'nested/private.sqf')+'\0'+str(personal/'top.sqf')+'\0').encode() if profile=='full' else b''
        expected[listings[0].name]=('file',listing_bytes,0o600)
    assert inventory(root)==expected,(profile,fault,entry,'private inventory/modes/link bytes differ')
    assert all(inventory(root)[name]==row for name,row in before.items()),'selected personal/sentinel inputs changed'
    return dict(profile=profile,fault=fault,entry=entry,raw=raw,reported_symlinks=count,copied_regular_files=copied,
                count_failure_rejected=count_failed,cleanup=cleanup,retained_workspace=retained,
                upstream_enumeration_failure=profile!='missing' and fault=='enumerate',sqg_entered=entry=='sync' and not early,
                private_inventory_and_selected_modes_match=True,personal_inputs_unchanged=True)


def main():
    rows=[]
    cases=list(itertools.product(('missing','empty','full'),FAULTS,('direct','sync')))
    cleanup_cases=[(*case,cleanup) for case in itertools.product(('empty','full'),('wc-partial',),('direct','sync'))
                   for cleanup in ('listing-fail','owned-fail','canonical-fail','mismatch')]
    with tempfile.TemporaryDirectory(prefix='slack-update-workspace-count-') as tmp:
        for i,case in enumerate(cases+cleanup_cases):
            root=Path(tmp).resolve()/str(i);root.mkdir();rows.append(scenario(REFERENCE,root,*case))
    assert len(rows)==76 and sum(r['count_failure_rejected'] for r in rows)==48
    print('SBo workspace count tests: 76 scenarios, 0 failures')


if __name__=='__main__':main()
