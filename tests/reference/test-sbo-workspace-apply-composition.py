#!/usr/bin/env python3
"""Compose real workspace/sync/readiness/apply/result paths with supplied leaves."""
import importlib.util
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
REFERENCE=ROOT/'tools/reference/slack-update-reference.sh'
spec=importlib.util.spec_from_file_location('workspace_count_fixture',Path(__file__).with_name('test-sbo-workspace-count.py'))
fixture=importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
PREFIX=fixture.PREFIX+r'''
for name in synchronize_sbo_repository build_sbo_target_queues_after_synchronization; do
    definition=$(declare -f "$name")
    eval "${definition/$name/real_$name}"
done
unset name definition
synchronize_sbo_repository() {
    record main sync
    local result=0
    real_synchronize_sbo_repository || result=$?
    record main sync-return "$result"
    return "$result"
}
build_sbo_target_queues_after_synchronization() {
    record main gate
    local result=0
    real_build_sbo_target_queues_after_synchronization || result=$?
    record main gate-return "$result"
    return "$result"
}
date() { [[ $# == 2 && $1 == -u && $2 == '+%Y-%m-%dT%H:%M:%SZ' ]] || forbidden clock-vector;builtin printf '2000-01-01T00:00:00Z\n'; }
sbopkg() { [[ $# == 1 && $1 == -r ]] || forbidden sync-vector;record main sbopkg "$@";return "$SYNC_CODE"; }
capture_package_snapshot_before() { PACKAGE_SNAPSHOT_BEFORE_VALID=1;PACKAGE_SNAPSHOT_BEFORE_COUNT=3; }
capture_package_snapshot_after() { PACKAGE_SNAPSHOT_AFTER_VALID=1;PACKAGE_SNAPSHOT_AFTER_COUNT=4; }
probe_boot_module() { BOOT_MODULE_STATE=disabled;return 0; }
prepare_geninitrd_grub_policy_override() { GENINITRD_POLICY_OVERRIDE_STATUS=supplied-prepared;return 0; }
restore_geninitrd_grub_policy_override() { GENINITRD_POLICY_OVERRIDE_STATUS=supplied-restored;return 0; }
update_slackware_system() {
    SLACKPKG_UPDATE_STATUS=0;SLACKPKG_INSTALL_NEW_STATUS=0;SLACKPKG_UPGRADE_ALL_STATUS=0
    PENDING_NEW_CONFIG_FILES_VALID=1;PENDING_NEW_CONFIG_FILES_COUNT=0
}
probe_optional_modules() {
    FLATPAK_MODULE_RUN=0;ELF_MODULE_RUN=0;CINNAMON_MODULE_RUN=0;SBO_MODULE_RUN=$SBO_RUN
    FLATPAK_MODULE_STATE=disabled;ELF_MODULE_STATE=disabled;CINNAMON_MODULE_STATE=disabled
    FLATPAK_MODULE_REASON=supplied-off;ELF_MODULE_REASON=supplied-off;CINNAMON_MODULE_REASON=supplied-off
    SBO_MODULE_STATE=disabled;SBO_MODULE_REASON=supplied-off
    [[ $SBO_RUN == 0 ]] || SBO_MODULE_STATE=available
    return 0
}
print_optional_module_activation() { :; }
detect_abi_changes() { :; }
detect_kernel_changes() { :; }
build_sbo_core_queue() {
    record main core
    : > "$QUEUE_CORE";: > "$SBO_OPTION_RECORDS";SBO_OPTION_RECORD_COUNT=0;TOTAL_CORE=0
    if [[ $PROFILE == full ]];then builtin printf 'core-a\ncore-b\n' > "$QUEUE_CORE";TOTAL_CORE=2;fi
}
add_abi_rebuild_targets() { record main abi;: > "$QUEUE_EXTRA";TOTAL_EXTRA=0; }
build_and_apply_sbo_queue() {
    record main process
    builtin command cat -- "$QUEUE_CORE" > "$QUEUE_FINAL"
    TOTAL=$TOTAL_CORE;TOTAL_EN_COLA=$TOTAL_CORE;SBO_BUILD_STATUS=0
}
emit_module_started_event() { :; }
emit_action_started_event() { :; }
emit_action_completed_event() { if [[ $1 == sbo ]];then record main action "$@";fi;return 0; }
emit_module_completed_event() { if [[ $1 == sbo ]];then record main module "$@";fi;return 0; }
run_boot_preparation_module() { record main boot-callback;return 0; }
print_summary() { record main summary "$slackware_state" "$flatpak_state" "$sbo_state" "$elf_state" "$cinnamon_state" "$action_exit";return 0; }
'''
GUARDS=tuple(n for n in fixture.GUARDS if n not in ('run_apply_workflow','build_sbo_core_queue','build_and_apply_sbo_queue'))+(
    'capture_validated_package_snapshot','stage_geninitrd_grub_policy_override','update_flatpak','rebuild_cinnamon',
    'verify_broken_elf_objects_after_rebuild','mkinitrd','grub-mkconfig')
FIELDS=('STABLE_EXIT_CODE','RESULT_SUCCESS','RESULT_PARTIAL','RESULT_BOOT_SAFE','RESULT_REBOOT',
        'SBOPKG_SYNC_STATUS','SQG_SYNC_STATUS','SBO_QUEUE_GENERATION_READY','SBO_TARGET_SELECTION_STATUS',
        'SBO_BUILD_STATUS','SBO_PERSONAL_QUEUE_FILE_COUNT','SBO_PERSONAL_QUEUE_SYMLINK_COUNT',
        'TOTAL_CORE','SBO_OPTION_RECORD_COUNT','TOTAL_EXTRA','TOTAL','TOTAL_EN_COLA',
        'SBO_TARGET_SELECTION_ERROR','SBO_QUEUE_SOURCE_DIR','SBO_GENERATED_QUEUE_OWNED_PATH',
        'SBO_GENERATED_QUEUE_OWNED_CANONICAL','SBO_PRIVATE_SBOPKG_CONFIG')


def scenario(root,profile,fault,sbo,sync_code,cleanup='none'):
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
    active_count=bool(sbo and profile!='missing' and fault!='enumerate')
    count_failed=early and fault!='enumerate'
    error=(('cannot count personal SBo queue symlinks: ' if count_failed else 'cannot enumerate personal SBo queue files: ')+str(personal)) if early else ''
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
        if profile=='full' and not early:
            expected['workspace/nested']=('dir',0o700)
            expected['workspace/top.sqf']=('file',b'alpha\n',0o600)
            expected['workspace/nested/private.sqf']=('file',b'beta\n',0o600)
    owned=str(workspace) if sbo and (not early or retained) else ''
    fields=[2 if errors else 0,0 if errors else 1,1 if errors else 0,1,'none',
            sync_code if sbo else -1,1 if early else 0 if sbo else -1,1 if sbo and not early else 0,
            1 if early else 0 if sbo else -1,0 if sbo and not early else -1,
            2 if sbo and not early and profile=='full' else 0 if sbo else 8,
            2 if sbo and not early and profile=='full' else 0 if sbo else 7,
            total,0,0,total,total,error,str(workspace) if sbo and not early else '' if sbo else str(root/'old-source'),
            owned,owned,str(root/'private.conf') if sbo and not early else 'old-conf']
    values=dict(PERSONAL=str(personal),WORKSPACE=str(workspace),FAULT=fault,CLEANUP=cleanup,PROFILE=profile,
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
    p=subprocess.run(['bash','--noprofile','--norc','-c',shell,'workspace-apply-composition',str(REFERENCE),str(root)],cwd=root,capture_output=True,timeout=15,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)))
    wanted=output.encode()+b'\0STATE\0'+b''.join(str(v).encode()+b'\0' for v in [0,*fields])+b'ERRORS\0'+b''.join(e.encode()+b'\0' for e in (errors or ['']))+b'WARNINGS\0\0'
    stderr=b'supplied audit count failure\n' if sbo and profile!='missing' and fault=='wc-stderr' else b''
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
    if sbo and not early and profile=='full':
        for relative in ('nested/private.sqf','top.sqf'):copy += [('install','-m','0600','/dev/null',str(workspace/relative)),('cat','--',str(personal/relative))]
    assert logs['copy']==fixture.encode(copy)
    listings=list(root.glob('tmp.*'));assert len(listings)==(1 if early and cleanup=='listing-fail' else 0)
    if listings:expected[listings[0].name]=('file',(str(personal/'nested/private.sqf')+'\0'+str(personal/'top.sqf')+'\0').encode() if profile=='full' else b'',0o600)
    assert fixture.inventory(root)==expected,(profile,fault,sbo,sync_code,cleanup,'inventory differs')
    assert all(fixture.inventory(root)[n]==v for n,v in before.items() if n not in ('core','extra','options','final','broken'))


def main():
    cases=list(itertools.product(('missing','empty','full'),fixture.FAULTS,(0,1),(0,43)))
    cases += [(*v,cleanup) for v in itertools.product(('empty','full'),('wc-partial',),(1,),(0,43))
              for cleanup in ('listing-fail','owned-fail','canonical-fail','mismatch')]
    with tempfile.TemporaryDirectory(prefix='slack-update-workspace-apply-') as tmp:
        for i,case in enumerate(cases):
            root=Path(tmp)/str(i);root.mkdir();scenario(root,*case)
    assert len(cases)==136
    print('SBo workspace apply composition: 136 scenarios, 0 failures')


if __name__=='__main__':main()
