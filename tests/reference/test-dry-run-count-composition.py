#!/usr/bin/env python3
"""Compose real planning/count/coordinator/result helpers with private SBo inputs."""
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
REFERENCE=ROOT/'tools/reference/slack-update-reference.sh'
FAULTS=('none','options-quiet','options-partial','core-quiet','core-partial',
        'candidates-quiet','candidates-partial','objects-quiet','objects-partial',
        'targets-quiet','targets-partial','core+objects','candidates+targets')
FIELDS=('STABLE_EXIT_CODE','RESULT_SUCCESS','RESULT_PARTIAL','RESULT_BOOT_SAFE','RESULT_REBOOT',
        'CHECK_STATUS','SBO_TARGET_SELECTION_STATUS','SBO_TARGET_SELECTION_ERROR','TOTAL_CORE',
        'SBO_OPTION_RECORD_COUNT','PLAN_ABI_SBO_COUNT','PLAN_BROKEN_COUNT','PLAN_BROKEN_SBO_COUNT',
        'ELF_SCAN_STATUS','BROKEN_COUNT','TOTAL_EXTRA','action_exit','sbo_state')
WARNING='Exact Slackware package changes remain unresolved until package metadata is refreshed during apply'
PREFIX=r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
date() { [[ $# == 2 && $1 == -u && $2 == '+%Y-%m-%dT%H:%M:%SZ' ]] || forbidden clock-vector; builtin printf '2000-01-01T00:00:00Z\n'; }
for name in inspect_current_sbo_queues collect_sbo_option_records_from_sources collect_installed_sbo_candidates inspect_current_elf_state; do
    definition=$(declare -f "$name");eval "${definition/$name/real_$name}"
done
unset name definition
inspect_current_sbo_queues() {
    record queues
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=core
    real_inspect_current_sbo_queues || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
collect_sbo_option_records_from_sources() {
    [[ $# == 3 && $1 == "$TEST_ROOT/queues" && $2 == "$SBO_OPTIONS_FILE" && $3 == "$SBO_OPTION_RECORDS" ]] || forbidden options-vector
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=options
    real_collect_sbo_option_records_from_sources "$@" || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
collect_installed_sbo_candidates() {
    record candidates
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=candidates
    real_collect_installed_sbo_candidates || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
inspect_current_elf_state() {
    record elf
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=elf
    real_inspect_current_elf_state || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
resolve_sbo_personal_queue_directory() {
    [[ $# == 0 ]] || forbidden resolve-vector
    record resolve
    SBO_PERSONAL_QUEUE_DIR=$TEST_ROOT/queues
    SBODIR=$TEST_ROOT/queues
}
wc() {
    [[ $# == 1 && $1 == -l && $COUNT_STAGE != none ]] || forbidden count-vector
    local stage=$COUNT_STAGE index
    if [[ $stage == elf ]]; then
        IFS= read -r index < "$TEST_ROOT/elf-count-index" || forbidden index-read
        index=$((index+1));[[ $index -le 2 ]] || forbidden extra-elf-count
        builtin printf '%s\n' "$index" > "$TEST_ROOT/elf-count-index"
        if [[ $index == 1 ]]; then stage=objects;else stage=targets;fi
    fi
    record count "$stage" "$@"
    if [[ $FAULT == "$stage-quiet" || $FAULT == "$stage-partial" \
        || ( $FAULT == core+objects && ( $stage == core || $stage == objects ) ) \
        || ( $FAULT == candidates+targets && ( $stage == candidates || $stage == targets ) ) ]]; then
        [[ $FAULT != *-partial ]] || builtin printf '42\n'
        return 43
    fi
    builtin command wc "$@"
}
check_slackware_updates() {
    record check
    CHECK_STATUS=$CHECK_CODE
    CHECK_ERROR=
    [[ $CHECK_CODE == 69 ]] || return 0
    CHECK_ERROR='supplied check failure'
    return 69
}
inspect_dry_run_environment() { record environment;PLAN_READELF_AVAILABLE=1; }
probe_optional_modules() {
    record probe
    SBO_MODULE_RUN=$SBO_RUN;ELF_MODULE_RUN=$ELF_RUN
    SBO_MODULE_STATE=disabled;ELF_MODULE_STATE=disabled
    [[ $SBO_RUN == 0 ]] || SBO_MODULE_STATE=available
    [[ $ELF_RUN == 0 ]] || ELF_MODULE_STATE=available
    SBO_MODULE_REASON=supplied-off;ELF_MODULE_REASON=supplied-off
}
print_optional_module_activation() { record activation; }
detect_broken_elf_objects() { record scan;builtin printf '%s' "$OBJECT_BYTES" > "$BROKEN";ELF_SCAN_STATUS=0;BROKEN_COUNT=$OBJECT_COUNT; }
map_broken_objects_to_sbo_packages() { record map;builtin printf '%s' "$TARGET_BYTES" > "$QUEUE_EXTRA";TOTAL_EXTRA=$TARGET_COUNT; }
print_dry_run_plan() { record plan "$TOTAL_CORE" "$SBO_OPTION_RECORD_COUNT" "$PLAN_ABI_SBO_COUNT" "$PLAN_BROKEN_COUNT" "$PLAN_BROKEN_SBO_COUNT"; }
emit_module_started_event() { record module-started "$@"; }
emit_action_started_event() { record action-started "$@"; }
emit_action_completed_event() { record action-completed "$@"; }
emit_module_completed_event() { record module-completed "$@"; }
'''
GUARDS=('main','initialize_execution_environment','initialize_runtime','initialize_dry_run_runtime',
        'configure_logging','load_configuration','run_apply_workflow','run_check_workflow','slackpkg',
        'sbopkg','sqg','flatpak','readelf','ldd','ldconfig','git','curl','wget','regenerate_initrd',
        'update_grub_configuration','mkinitrd','grub-mkconfig','synchronize_sbo_repository',
        'build_and_apply_sbo_queue','verify_broken_elf_objects_after_rebuild','print_json_result','emit_final_events')


def inventory(root):
    return {p.relative_to(root).as_posix():('dir',) if p.is_dir() else ('file',p.read_bytes())
            for p in root.rglob('*') if p.name!='events'}


def encode(rows):
    return b''.join(b''.join(str(v).encode()+b'\0' for v in row)+b'\n' for row in rows)


def scenario(root,profile,fault,sbo,elf,check):
    (root/'queues').mkdir();(root/'packages').mkdir()
    (root/'queues/private.sqf').write_text('# empty\n' if profile=='empty' else 'core-b\ncore-a | V=yes\n')
    (root/'packages/native-1.0-x86_64-1').write_text('private manifest\n')
    if profile=='full':
        for name in ('core-a-1.0-x86_64-1_SBo','extra-1.0-x86_64-1_SBo'):
            (root/'packages'/name).write_text('private manifest\n')
    for name in ('core','extra','options','candidates','broken'):(root/name).write_text('old-'+name+'\n')
    (root/'overrides').write_text('');(root/'elf-count-index').write_text('0\n')
    expected=inventory(root)
    core='' if profile=='empty' else 'core-b\ncore-a\n'
    options='' if profile=='empty' else 'core-a\tV=yes\n'
    candidates='' if profile=='empty' else 'core-a\nextra\n'
    objects='' if profile=='empty' else str(root/'supplied-object')+'\n'
    targets='' if profile=='empty' else 'core-a\n'
    active=set(fault.split('+')) if '+' in fault else {fault.split('-')[0]}
    sbo_failure=next((name for name in ('options','core','candidates') if sbo and name in active),'')
    elf_failure=next((name for name in ('objects','targets') if elf and name in active),'')
    selection=-1;error='';core_n=6;option_n=5;abi_n=4;objects_n=6;targets_n=4
    scan=-1;broken_n=8;extra_n=7;elf_index=0
    raw=69 if check==69 else 0
    check_state='failed' if check==69 else 'success'
    rows=[('module-started','slackware','Slackware planning probe started'),
          ('action-started','slackware','check_updates','Checking Slackware repository updates'),('check',),
          ('action-completed','slackware','check_updates',check_state,'Slackware repository probe completed',check),
          ('module-completed','slackware',check_state,'Slackware planning probe completed',check),
          ('module-started','core','Local environment inspection started'),
          ('action-started','core','inspect_environment','Inspecting optional tools and boot configuration'),
          ('environment',),('probe',),('activation',),
          ('action-completed','core','inspect_environment','success','Optional tools, module modes, and boot configuration inspected',0),
          ('module-completed','core','success','Local environment inspection completed',0),
          ('module-started','sbo','SBo planning inspection started')]
    output=''
    def file(name,value):expected[name]=('file',value.encode())
    if sbo:
        selection=0
        rows += [('action-started','sbo','inspect_queues','Inspecting current SBo queues'),('queues',),('resolve',),('count','options','-l')]
        output+='[PLAN] Inspecting current SBo queues\n'
        if sbo_failure!='options':rows.append(('count','core','-l'))
        if sbo_failure not in ('options','core'):
            output+=f'  Current local queue targets: {core.count(chr(10))}\n  Preserved build-option records: {options.count(chr(10))}\n'
            rows += [('candidates',),('count','candidates','-l')]
        if sbo_failure:
            selection=raw=1
            error={'options':'cannot count normalized SBo option map','core':'cannot count the current local SBo queue',
                   'candidates':'cannot count installed SBo candidates for dry-run'}[sbo_failure]
            output+='  [ERROR] '+error+'\n'
            core_n=option_n=abi_n=0
            for name in ('core','options','candidates'):file(name,'')
            rows.append(('action-completed','sbo','inspect_queues','failed','SBo target selection failed: '+error,1))
        else:
            core_n=core.count('\n');option_n=options.count('\n');abi_n=candidates.count('\n')
            file('core',core);file('options',options);file('candidates',candidates)
            rows.append(('action-completed','sbo','inspect_queues','success','Current SBo queues and ABI candidates inspected',0))
        sbo_state='failed' if sbo_failure else 'success'
    else:
        core_n=option_n=abi_n=targets_n=0
        for name in ('core','extra','options','candidates'):file(name,'')
        sbo_state='disabled'
        rows.append(('action-completed','sbo','inspect_queues','disabled','SBo queue inspection was not applicable: supplied-off',0))
    rows += [('module-completed','sbo',sbo_state,'SBo planning inspection completed',0),
             ('module-started','elf','ELF dependency inspection started')]
    if elf:
        rows += [('action-started','elf','scan_dependencies','Scanning current ELF dependencies'),('elf',),('scan',),('map',),('count','objects','-l')]
        output+='[PLAN] Inspecting current ELF dependency state\n'
        file('broken',objects);file('extra',targets)
        scan=0;broken_n=objects.count('\n');extra_n=targets.count('\n');elf_index=1
        if elf_failure!='objects':rows.append(('count','targets','-l'));elf_index=2
        if elf_failure:
            raw=1;elf_state='failed'
            output+='  [ERROR] '+('Cannot count the current broken ELF objects for dry-run' if elf_failure=='objects' else 'Cannot count the current broken-ELF SBo targets for dry-run')+'\n'
            rows.append(('action-completed','elf','scan_dependencies','failed','Static ELF dependency inspection failed',1))
        else:
            objects_n=objects.count('\n');targets_n=targets.count('\n');elf_state='warning' if objects_n else 'success'
            rows.append(('action-completed','elf','scan_dependencies',elf_state,'Current ELF dependency inspection completed',0))
    else:
        file('broken','');objects_n=0;elf_state='disabled'
        rows.append(('action-completed','elf','scan_dependencies','disabled','ELF dependency inspection was not applicable: supplied-off',0))
    rows += [('module-completed','elf',elf_state,'ELF dependency inspection completed',0),
             ('action-started','core','render_plan','Rendering dry-run plan'),
             ('plan',core_n,option_n,abi_n,objects_n,targets_n),
             ('action-completed','core','render_plan','success','Dry-run plan rendered',0)]
    file('elf-count-index',str(elf_index)+'\n')
    errors=(['supplied check failure'] if check==69 else [])+(['SBo target selection failed: '+error] if sbo_failure else [])
    stable=1 if raw or errors else 0
    fields=[stable,1-stable,0,1,'none',check,selection,error,core_n,option_n,abi_n,objects_n,targets_n,scan,broken_n,extra_n,77 if sbo else 0,'outer-sbo']
    values=dict(FAULT=fault,SBO_RUN=sbo,ELF_RUN=elf,CHECK_CODE=check,COUNT_STAGE='none',OPERATION='dry-run',
        TOTAL_CORE=6,SBO_OPTION_RECORD_COUNT=5,PLAN_ABI_SBO_COUNT=4,PLAN_BROKEN_COUNT=6,PLAN_BROKEN_SBO_COUNT=4,
        BROKEN_COUNT=8,TOTAL_EXTRA=7,PACKAGE_DATABASE=str(root/'packages'),SBO_PACKAGE_TAG='_SBo',
        QUEUE_CORE=str(root/'core'),QUEUE_EXTRA=str(root/'extra'),SBO_OPTION_RECORDS=str(root/'options'),
        SBO_OPTIONS_FILE=str(root/'overrides'),ABI_CANDIDATES=str(root/'candidates'),BROKEN=str(root/'broken'),
        SBO_QUEUE_DIR_FALLBACK=str(root/'queues'),LOG=str(root/'run.log'),
        FLATPAK_MODE='disabled',SBO_MODE='auto',ELF_MODE='auto',CINNAMON_MODE='disabled',BOOT_MODE='disabled',
        OBJECT_BYTES=objects,TARGET_BYTES=targets,OBJECT_COUNT=objects.count('\n'),TARGET_COUNT=targets.count('\n'))
    script=PREFIX+'\n'+'\n'.join(name+'() { forbidden '+name+'; }' for name in GUARDS)+'\ninitialize_runtime_state || exit 96\n'
    script+='\n'.join(name+'='+shlex.quote(str(value)) for name,value in values.items())+'\n'
    script+="IFS='|: '\nsaved_ifs=$IFS\naction_exit=77;sbo_state=outer-sbo\nraw=0\nrun_dry_run_workflow || raw=$?\ndetermine_stable_exit_code \"$raw\"\n"
    script+='[[ $COUNT_STAGE == none && $IFS == "$saved_ifs" ]] || exit 95\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    script+='\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)+'\n'
    script+='builtin printf "ERRORS\\0";builtin printf "%s\\0" "${RESULT_ERRORS[@]}"\nbuiltin printf "WARNINGS\\0";builtin printf "%s\\0" "${RESULT_WARNINGS[@]}"\n'
    result=subprocess.run(['bash','--noprofile','--norc','-c',script,'dry-count-composition-test',str(REFERENCE),str(root)],
        cwd=root,capture_output=True,timeout=15,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)))
    wanted=output.encode()+b'\0STATE\0'+b''.join(str(v).encode()+b'\0' for v in [raw,*fields])
    wanted+=b'ERRORS\0'+b''.join(v.encode()+b'\0' for v in (errors or ['']))+b'WARNINGS\0'+WARNING.encode()+b'\0'
    trace=(root/'events').read_bytes()
    if result.returncode or result.stderr or result.stdout!=wanted or trace!=encode(rows) or inventory(root)!=expected:
        raise AssertionError(dict(case=(profile,fault,sbo,elf,check),returncode=result.returncode,stdout=result.stdout,
            expected_stdout=wanted,stderr=result.stderr,trace=trace,expected_trace=encode(rows),inventory_matches=inventory(root)==expected))


def run():
    count=0
    with tempfile.TemporaryDirectory(prefix='slack-update-dry-count-composition-') as tmp:
        for values in itertools.product(('empty','full'),FAULTS,(0,1),(0,1),(0,100,69)):
            root=Path(tmp)/str(count);root.mkdir();scenario(root,*values);count+=1
    print(f'Dry-run count composition: {count} scenarios, 0 failures')


if __name__=='__main__':run()
