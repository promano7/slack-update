#!/usr/bin/env python3
"""Check real SBo coordinators with supplied commands/collectors and private lists."""
from pathlib import Path
import itertools
import os
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('SBOPKG_SYNC_STATUS','SQG_SYNC_STATUS','SBO_QUEUE_GENERATION_READY','SBO_QUEUE_SOURCE_DIR',
          'SBO_PERSONAL_QUEUE_DIR','SBO_PERSONAL_QUEUE_FILE_COUNT','SBO_PERSONAL_QUEUE_SYMLINK_COUNT',
          'TOTAL_CORE','SBO_OPTION_RECORD_COUNT','TOTAL_EXTRA','SBO_BUILD_STATUS','TOTAL','TOTAL_EN_COLA',
          'SBO_TARGET_SELECTION_ERROR','SBOPKG_CONF','QUEUEDIR')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/trace"; builtin printf '\n' >> "$TEST_ROOT/trace"; }
command() {
    [[ $1 == -v && $# == 2 ]] || forbidden command
    record discover "$2"
    case "$2" in
        sbopkg) [[ $HAS_SBOPKG == 1 ]] ;;
        sqg) [[ $HAS_SQG == 1 ]] ;;
        *) forbidden discovery ;;
    esac
}
rm() {
    [[ $1 == -f && $# == 4 && $2 == "$QUEUE_CORE" && $3 == "$QUEUE_EXTRA" && $4 == "$SBO_OPTION_RECORDS" ]] || forbidden rm
    record rm "$@"
    builtin command rm "$@"
}
wc() { [[ $# == 1 && $1 == -l ]] || forbidden wc; record wc "$@"; builtin command wc "$@"; }
touch() { [[ $# == 1 && $1 == "$QUEUE_EXTRA" ]] || forbidden touch; record touch "$@"; builtin command touch "$@"; }
sbopkg() { record sbopkg "$@"; return "$SBOPKG_RC"; }
sqg() { record sqg "$@" "$SBOPKG_CONF" "$QUEUEDIR"; return "$SQG_RC"; }
resolve_sbo_personal_queue_directory() {
    record resolve
    if [[ $RESOLVE_RC != 0 ]]; then SBO_TARGET_SELECTION_ERROR=supplied-resolve-error; return "$RESOLVE_RC"; fi
    SBO_PERSONAL_QUEUE_DIR=$TEST_ROOT/personal
}
prepare_private_sbo_queue_workspace() {
    record workspace "$@"
    if [[ $WORKSPACE_RC != 0 ]]; then SBO_TARGET_SELECTION_ERROR=supplied-workspace-error; return "$WORKSPACE_RC"; fi
    SBO_QUEUE_SOURCE_DIR=$SBO_GENERATED_QUEUE_DIR
    SBO_PERSONAL_QUEUE_FILE_COUNT=3
    SBO_PERSONAL_QUEUE_SYMLINK_COUNT=$SYMLINKS
}
prepare_private_sqg_configuration() {
    record config "$@"
    if [[ $CONFIG_RC != 0 ]]; then SBO_TARGET_SELECTION_ERROR=supplied-config-error; return "$CONFIG_RC"; fi
    SBO_PRIVATE_SBOPKG_CONFIG=$TEST_ROOT/private.conf
}
collect_ordered_sbo_targets_from_queue_directory() {
    record ordered "$@"
    if [[ $CORE_RC != 0 ]]; then SBO_TARGET_SELECTION_ERROR=supplied-core-error; return "$CORE_RC"; fi
    builtin printf '%s' "$CORE_BYTES" > "$2"
}
collect_sbo_option_records_from_sources() {
    record options "$@"
    if [[ $OPTIONS_RC != 0 ]]; then SBO_TARGET_SELECTION_ERROR=supplied-options-error; return "$OPTIONS_RC"; fi
    builtin printf 'z\tV=yes\n' > "$3"
    SBO_OPTION_RECORD_COUNT=1
}
collect_installed_sbo_targets() {
    record installed "$@"
    if [[ $INSTALLED_RC != 0 ]]; then SBO_TARGET_SELECTION_ERROR=supplied-installed-error; return "$INSTALLED_RC"; fi
    builtin printf 'a\nz\n' > "$1"
}
merge_ordered_sbo_queue_with_target_sets() {
    record merge "$@"
    if [[ $MERGE_RC != 0 ]]; then return "$MERGE_RC"; fi
    builtin printf '%s' "$FINAL_BYTES" > "$1"
}
verify_broken_elf_objects_after_rebuild() { record verify; return "$VERIFY_RC"; }
'''
FORBIDDEN = ('main','initialize_execution_environment','initialize_runtime','load_configuration',
             'run_apply_workflow','run_check_workflow','run_dry_run_workflow','slackpkg','flatpak',
             'git','curl','wget','find','sort','mktemp','mv','regenerate_initrd','update_grub_configuration',
             'detect_broken_elf_objects','map_broken_objects_to_sbo_packages','emit_event')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)


def initial(root):
    state = dict(zip(FIELDS, ('17','18','9',str(root/'old-source'),str(root/'personal'),'8','7',
                             '6','5','4','3','11','12','old-error','outer-conf','outer-queue')))
    return state


def profiles():
    for sbopkg, sqg in ((0,0),(0,1),(1,0)):
        for seed in (0,1):
            yield 'sync', dict(HAS_SBOPKG=sbopkg,HAS_SQG=sqg,seed=seed)
    for stage, rc, seed in itertools.product(('resolve','workspace','config'),(0,20),(0,1)):
        yield 'sync', dict(stage=stage,SBOPKG_RC=rc,seed=seed)
    for rc, sqg, links, seed in itertools.product((0,7,20),(0,9,20),(0,2),(0,1)):
        yield 'sync', dict(SBOPKG_RC=rc,SQG_RC=sqg,SYMLINKS=links,seed=seed)
    for flags, outcome in itertools.product(itertools.product((0,1),repeat=4), ('core-fail','options-fail','empty','full')):
        personal, source, resolve, present = flags
        yield 'core', dict(personal=personal,source=source,RESOLVE_RC=resolve,present=present,outcome=outcome)
    for trigger, failure, existing, seed in itertools.product((0,1,2),(0,1),(0,1),(0,1)):
        yield 'abi', dict(ABI_TRIGGER=trigger,INSTALLED_RC=failure,existing=existing,seed=seed)
    for ready, error, core, abi in itertools.product((None,0,1,2),('', 'preset-error'),(0,1,23),(0,1,19)):
        yield 'gate', dict(ready=ready,error=error,GATE_CORE_RC=core,GATE_ABI_RC=abi)
    for merge, empty, broken, rc, verify, unset in itertools.product((0,1),(0,1),(0,1),(0,7,20),(0,19),(0,1)):
        yield 'final', dict(MERGE_RC=merge,empty=empty,broken=broken,SBOPKG_RC=rc,VERIFY_RC=verify,unset=unset)


def inventory(root):
    return {str(p.relative_to(root)): ('directory',) if p.is_dir() else ('file',p.read_bytes())
            for p in root.rglob('*') if p.name != 'trace'}


def scenario(root, kind, profile):
    paths = {name:str(root/name.lower()) for name in ('QUEUE_CORE','QUEUE_EXTRA','SBO_OPTION_RECORDS','QUEUE_FINAL',
             'BROKEN','STILL_BROKEN','SBO_OPTIONS_FILE','SBOPKG_CONFIG','LOG')}
    for path in paths.values(): Path(path).write_text('preserved\n')
    values = dict(HAS_SBOPKG=1,HAS_SQG=1,SBOPKG_RC=0,SQG_RC=0,RESOLVE_RC=0,WORKSPACE_RC=0,
                  CONFIG_RC=0,SYMLINKS=0,CORE_RC=0,OPTIONS_RC=0,INSTALLED_RC=0,MERGE_RC=0,VERIFY_RC=0,
                  CORE_BYTES='z\na\n',FINAL_BYTES='z\na\n',ABI_TRIGGER=0)
    values.update({k:v for k,v in profile.items() if k.isupper()})
    state = initial(root)
    if profile.get('seed') == 0:
        state.update(SBOPKG_SYNC_STATUS='-1',SQG_SYNC_STATUS='-1',SBO_QUEUE_GENERATION_READY='0',TOTAL_EXTRA='0')
    values.update(paths); values['SBO_GENERATED_QUEUE_DIR']=str(root/'generated')
    if kind=='core':
        state['SBO_PERSONAL_QUEUE_DIR']=str(root/'personal') if profile['personal'] else ''
        state['SBO_QUEUE_SOURCE_DIR']=str(root/'supplied') if profile['source'] else ''
        selected=root/('supplied' if profile['source'] else 'personal')
        if profile['present']: selected.mkdir()
        values['CORE_RC']=7 if profile['outcome']=='core-fail' else 0
        values['OPTIONS_RC']=19 if profile['outcome']=='options-fail' else 0
        values['CORE_BYTES']='' if profile['outcome']=='empty' else 'z\na\n'
    if kind=='abi' and not profile['existing']:Path(paths['QUEUE_EXTRA']).unlink()
    if kind=='gate':
        state['SBO_QUEUE_GENERATION_READY']=str(profile['ready']) if profile['ready'] is not None else '<unset>'
        state['SBO_TARGET_SELECTION_ERROR']=profile['error']
    if kind=='final':
        Path(paths['BROKEN']).write_text('broken-object\n' if profile['broken'] else '')
        values['FINAL_BYTES']='' if profile['empty'] else 'z\na\n'
    expected_files=inventory(root); expected=dict(state); trace=[]; output=''; status=0
    def call(*args):trace.append(tuple(map(str,args)))
    if kind=='sync':
        output='[5] Sync SBo\n';call('discover','sbopkg')
        if not values['HAS_SBOPKG']:output+='  sbopkg no instalado, omitiendo\n'
        else:
            call('discover','sqg')
            if not values['HAS_SQG']:output+='  sqg no encontrado -- omitiendo sync SBo\n'
            else:
                call('sbopkg','-r');expected.update(SBOPKG_SYNC_STATUS=str(values['SBOPKG_RC']),SQG_SYNC_STATUS='0',SBO_QUEUE_GENERATION_READY='0',SBO_QUEUE_SOURCE_DIR='')
                stage=profile.get('stage')
                values.update(RESOLVE_RC=int(stage=='resolve'),WORKSPACE_RC=int(stage=='workspace'),CONFIG_RC=int(stage=='config'))
                call('resolve')
                if stage=='resolve':expected['SBO_TARGET_SELECTION_ERROR']='supplied-resolve-error'
                else:
                    expected['SBO_PERSONAL_QUEUE_DIR']=str(root/'personal');call('workspace',root/'personal',root/'generated')
                    if stage=='workspace':expected['SBO_TARGET_SELECTION_ERROR']='supplied-workspace-error'
                    else:
                        expected.update(SBO_QUEUE_SOURCE_DIR=str(root/'generated'),SBO_PERSONAL_QUEUE_FILE_COUNT='3',SBO_PERSONAL_QUEUE_SYMLINK_COUNT=str(values['SYMLINKS']))
                        call('config',paths['SBOPKG_CONFIG'],root/'generated')
                        if stage=='config':expected['SBO_TARGET_SELECTION_ERROR']='supplied-config-error'
                        else:
                            output+=f'  Personal queue directory preserved read-only: {root}/personal\n'
                            output+=f'  Private sqg workspace: {root}/generated\n  Personal queue files copied: 3\n'
                            if values['SYMLINKS']:output+=f"  [WARN] Personal queue symlinks ignored: {values['SYMLINKS']}\n"
                            call('sqg','-a',root/'private.conf',root/'generated')
                            if values['SQG_RC']:
                                expected.update(SQG_SYNC_STATUS=str(values['SQG_RC']),SBO_TARGET_SELECTION_ERROR=f"sqg queue generation failed in the private workspace with exit code {values['SQG_RC']}")
                            else:expected['SBO_QUEUE_GENERATION_READY']='1'
                if stage:
                    expected['SQG_SYNC_STATUS']='1';output+='  [ERROR] '+expected['SBO_TARGET_SELECTION_ERROR']+'\n'
    elif kind=='core':
        output='[6] Generando colas SBo\n'
        if not profile['personal']:
            call('resolve')
            if profile['RESOLVE_RC']:
                expected['SBO_TARGET_SELECTION_ERROR']='supplied-resolve-error';status=1;output+='  [ERROR] supplied-resolve-error\n'
            else:expected['SBO_PERSONAL_QUEUE_DIR']=str(root/'personal')
        if status==0:
            if not profile['source']:expected['SBO_QUEUE_SOURCE_DIR']=expected['SBO_PERSONAL_QUEUE_DIR']
            call('rm','-f',paths['QUEUE_CORE'],paths['QUEUE_EXTRA'],paths['SBO_OPTION_RECORDS'])
            for name in ('QUEUE_CORE','QUEUE_EXTRA','SBO_OPTION_RECORDS'):expected_files.pop(Path(paths[name]).name,None)
            if not profile['present']:output+='  [WARN] SBo queue source directory not found: '+expected['SBO_QUEUE_SOURCE_DIR']+'\n'
            call('ordered',expected['SBO_QUEUE_SOURCE_DIR'],paths['QUEUE_CORE'])
            if values['CORE_RC']:
                expected['SBO_TARGET_SELECTION_ERROR']='supplied-core-error';status=1;output+='  [ERROR] supplied-core-error\n'
            else:
                expected_files[Path(paths['QUEUE_CORE']).name]=('file',values['CORE_BYTES'].encode());call('options',expected['SBO_QUEUE_SOURCE_DIR'],paths['SBO_OPTIONS_FILE'],paths['SBO_OPTION_RECORDS'])
                if values['OPTIONS_RC']:
                    expected['SBO_TARGET_SELECTION_ERROR']='supplied-options-error';status=1;output+='  [ERROR] supplied-options-error\n'
                else:
                    expected_files[Path(paths['SBO_OPTION_RECORDS']).name]=('file',b'z\tV=yes\n');expected.update(SBO_OPTION_RECORD_COUNT='1',TOTAL_CORE='0' if profile['outcome']=='empty' else '2')
                    call('wc','-l');output+=f"  Cola principal: {expected['TOTAL_CORE']} paquetes\n  Opciones de compilacion preservadas: 1\n"
    elif kind=='abi':
        if profile['ABI_TRIGGER']==1:
            output='[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra\n';call('installed',paths['QUEUE_EXTRA'])
            if values['INSTALLED_RC']:
                status=1;expected['SBO_TARGET_SELECTION_ERROR']='supplied-installed-error';output+='  [ERROR] supplied-installed-error\n'
            else:
                expected_files[Path(paths['QUEUE_EXTRA']).name]=('file',b'a\nz\n');expected['TOTAL_EXTRA']='2';call('wc','-l');output+='  Cola ABI extra: 2 paquetes\n'
        else:
            call('touch',paths['QUEUE_EXTRA']);expected_files.setdefault(Path(paths['QUEUE_EXTRA']).name,('file',b''))
    elif kind=='gate':
        if profile['ready']!=1:
            status=1
            if not profile['error']:expected['SBO_TARGET_SELECTION_ERROR']='private SBo queue generation did not complete successfully'
        else:
            call('core');status=values['GATE_CORE_RC']
            if status==0:call('abi');status=values['GATE_ABI_RC']
    else:
        output='[10] Aplicando cola SBo\n';call('merge',paths['QUEUE_FINAL'],paths['QUEUE_CORE'],'/dev/null' if profile['unset'] else paths['SBO_OPTION_RECORDS'],paths['QUEUE_EXTRA'])
        if values['MERGE_RC']:
            status=1;expected.update(SBO_BUILD_STATUS='1',SBO_TARGET_SELECTION_ERROR='cannot build the final dependency-ordered SBo queue');output+='  [ERROR] cannot build the final dependency-ordered SBo queue\n'
        else:
            expected_files[Path(paths['QUEUE_FINAL']).name]=('file',values['FINAL_BYTES'].encode());count='0' if profile['empty'] else '2';expected.update(TOTAL=count,TOTAL_EN_COLA=count)
            call('wc','-l');output+=f'  Total paquetes en cola: {count}\n'
            if profile['empty']:output+='  Cola vacia, nada que hacer\n'
            else:
                call('sbopkg','-b','-B',paths['QUEUE_FINAL']);expected['SBO_BUILD_STATUS']=str(values['SBOPKG_RC'])
                output+=f"  [WARN] sbopkg termino con errores -- revisar log: {paths['LOG']}\n" if values['SBOPKG_RC'] else '  [OK] Cola SBo procesada\n'
                if profile['broken']:call('verify')
    assignments='\n'.join(name+'='+shlex.quote(str(value)) for name,value in (values|state).items());extra=''
    if kind=='gate':
        extra+='\nbuild_sbo_core_queue() { record core; return "$GATE_CORE_RC"; }\nadd_abi_rebuild_targets() { record abi; return "$GATE_ABI_RC"; }\n'
        if profile['ready'] is None:extra+='unset SBO_QUEUE_GENERATION_READY\n'
    if kind=='final' and profile['unset']:extra+='\nunset SBO_OPTION_RECORDS\n'
    entry={'sync':'synchronize_sbo_repository','core':'build_sbo_core_queue','abi':'add_abi_rebuild_targets','gate':'build_sbo_target_queues_after_synchronization','final':'build_and_apply_sbo_queue'}[kind]
    suffix='\ncaller_ifs=$IFS\noutside=kept\n'+entry+'\nraw=$?\n[[ $IFS == "$caller_ifs" && $outside == kept ]] || exit 96\n'
    suffix+='builtin printf "\\0STATE\\0%s\\0" "$raw"\n'
    suffix+='\n'.join('builtin printf "%s\\0" "${'+name+'-<unset>}"' for name in FIELDS)+'\n'
    result=subprocess.run(['bash','--noprofile','--norc','-c',PREFIX+GUARDS+'\n'+assignments+extra+suffix,'sbo-workflow-test',str(REFERENCE),str(root)],capture_output=True,cwd=root,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)),timeout=10)
    wanted=output.encode()+b'\0STATE\0'+str(status).encode()+b'\0'+b''.join(expected[name].encode()+b'\0' for name in FIELDS)
    if (result.returncode,result.stdout,result.stderr)!=(0,wanted,b''):
        raise AssertionError(f'{kind}/{profile}: expected {(0,wanted,b"")!r}, got {(result.returncode,result.stdout,result.stderr)!r}')
    actual_trace=(root/'trace').read_bytes() if (root/'trace').exists() else b''
    wanted_trace=b''.join(b'\0'.join(value.encode() for value in event)+b'\0\n' for event in trace)
    if actual_trace!=wanted_trace:raise AssertionError(f'{kind}/{profile}: trace {actual_trace!r} != {wanted_trace!r}')
    if inventory(root)!=expected_files:raise AssertionError(f'{kind}/{profile}: private files differ')


def run():
    counts=dict.fromkeys(('sync','core','abi','gate','final'),0)
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-workflow-') as tmp:
        for index,(kind,profile) in enumerate(profiles()):
            root=Path(tmp)/str(index);root.mkdir();scenario(root,kind,profile);counts[kind]+=1
    print('SBo workflow tests: '+', '.join(f'{value} {kind} entries' for kind,value in counts.items())+', 0 failures')


if __name__=='__main__':run()
