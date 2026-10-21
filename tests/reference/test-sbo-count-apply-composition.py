#!/usr/bin/env python3
"""Compose real apply, queue/count/build helpers and result mapping in private cases."""
import itertools
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FAULTS = ('none', 'options-quiet', 'options-partial', 'core-quiet', 'core-partial',
          'abi-quiet', 'abi-partial', 'final-quiet', 'final-partial',
          'reset-quiet', 'reset-partial', 'reset-removed')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
event() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
date() { [[ $# == 2 && $1 == -u && $2 == '+%Y-%m-%dT%H:%M:%SZ' ]] || forbidden clock-vector; builtin printf '2000-01-01T00:00:00Z\n'; }
for name in collect_sbo_option_records_from_sources build_sbo_core_queue add_abi_rebuild_targets build_and_apply_sbo_queue; do
    definition=$(declare -f "$name")
    eval "${definition/$name/real_$name}"
done
unset name definition
collect_sbo_option_records_from_sources() {
    [[ $# == 3 && $1 == "$TEST_ROOT/queues" && $2 == "$SBO_OPTIONS_FILE" && $3 == "$SBO_OPTION_RECORDS" ]] || forbidden options-vector
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=options
    real_collect_sbo_option_records_from_sources "$@" || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
build_sbo_core_queue() {
    event core
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=core
    real_build_sbo_core_queue || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
add_abi_rebuild_targets() {
    event abi
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=abi
    real_add_abi_rebuild_targets || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
build_and_apply_sbo_queue() {
    event final
    local previous=$COUNT_STAGE result=0
    COUNT_STAGE=final
    real_build_and_apply_sbo_queue || result=$?
    COUNT_STAGE=$previous
    return "$result"
}
reset_snapshot() {
    local path
    for path in "$QUEUE_CORE" "$QUEUE_EXTRA" "$SBO_OPTION_RECORDS"; do
        if [[ -e $path ]]; then event reset-file "$path" present "$(< "$path")"
        else event reset-file "$path" absent; fi
    done
}
rm() {
    if [[ $COUNT_STAGE == core && $# == 4 && $1 == -f && $2 == "$QUEUE_CORE" \
        && $3 == "$QUEUE_EXTRA" && $4 == "$SBO_OPTION_RECORDS" ]]; then
        event reset "$@"
        case "$FAULT" in
            reset-quiet) reset_snapshot; return 43 ;;
            reset-partial)
                builtin command rm -f -- "$QUEUE_CORE" || forbidden reset-partial-remove
                builtin printf 'supplied-reset-output\n'
                reset_snapshot
                return 43 ;;
            reset-removed)
                builtin command rm "$@" || forbidden reset-complete-remove
                reset_snapshot
                return 43 ;;
        esac
    fi
    builtin command rm "$@"
}
wc() {
    [[ $# == 1 && $1 == -l && $COUNT_STAGE != none ]] || forbidden count-vector
    event count "$COUNT_STAGE" "$@"
    if [[ $FAULT == "$COUNT_STAGE-quiet" || $FAULT == "$COUNT_STAGE-partial" ]]; then
        if [[ $FAULT == *-partial ]]; then builtin printf '42\n'; fi
        return 43
    fi
    builtin command wc "$@"
}
capture_package_snapshot_before() { PACKAGE_SNAPSHOT_BEFORE_VALID=1; PACKAGE_SNAPSHOT_BEFORE_COUNT=3; }
capture_package_snapshot_after() { PACKAGE_SNAPSHOT_AFTER_VALID=1; PACKAGE_SNAPSHOT_AFTER_COUNT=4; }
probe_boot_module() { BOOT_MODULE_STATE=disabled; return 0; }
prepare_geninitrd_grub_policy_override() { GENINITRD_POLICY_OVERRIDE_STATUS=supplied-prepared; return 0; }
restore_geninitrd_grub_policy_override() { GENINITRD_POLICY_OVERRIDE_STATUS=supplied-restored; return 0; }
update_slackware_system() {
    SLACKPKG_UPDATE_STATUS=0; SLACKPKG_INSTALL_NEW_STATUS=0; SLACKPKG_UPGRADE_ALL_STATUS=0
    PENDING_NEW_CONFIG_FILES_VALID=1; PENDING_NEW_CONFIG_FILES_COUNT=0
}
probe_optional_modules() {
    FLATPAK_MODULE_RUN=0; ELF_MODULE_RUN=0; CINNAMON_MODULE_RUN=0; SBO_MODULE_RUN=$SBO_RUN
    FLATPAK_MODULE_STATE=disabled; ELF_MODULE_STATE=disabled; CINNAMON_MODULE_STATE=disabled
    FLATPAK_MODULE_REASON=supplied-off; ELF_MODULE_REASON=supplied-off; CINNAMON_MODULE_REASON=supplied-off
    SBO_MODULE_STATE=disabled; SBO_MODULE_REASON=supplied-off
    [[ $SBO_RUN == 0 ]] || SBO_MODULE_STATE=available
    return 0
}
print_optional_module_activation() { :; }
detect_abi_changes() { :; }
detect_kernel_changes() { :; }
synchronize_sbo_repository() {
    event sync
    SBOPKG_SYNC_STATUS=0; SQG_SYNC_STATUS=0; SBO_QUEUE_GENERATION_READY=1
    SBO_QUEUE_SOURCE_DIR=$TEST_ROOT/queues
}
sbopkg() {
    [[ $# == 3 && $1 == -b && $2 == -B && $3 == "$QUEUE_FINAL" ]] || forbidden builder-vector
    event builder "$@"
    return "$BUILD_CODE"
}
emit_module_started_event() { :; }
emit_action_started_event() { :; }
emit_action_completed_event() { if [[ $1 == sbo ]]; then event action "$@"; fi; return 0; }
emit_module_completed_event() { if [[ $1 == sbo ]]; then event module "$@"; fi; return 0; }
run_boot_preparation_module() { event boot-callback; return 0; }
print_summary() { event summary "$slackware_state" "$flatpak_state" "$sbo_state" "$elf_state" "$cinnamon_state" "$action_exit"; return 0; }
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'configure_logging', 'load_configuration',
          'run_check_workflow', 'run_dry_run_workflow', 'capture_validated_package_snapshot',
          'stage_geninitrd_grub_policy_override',
          'update_flatpak', 'rebuild_cinnamon', 'detect_broken_elf_objects', 'map_broken_objects_to_sbo_packages',
          'verify_broken_elf_objects_after_rebuild', 'readelf', 'ldd', 'ldconfig', 'slackpkg', 'sqg', 'flatpak',
          'git', 'curl', 'wget', 'regenerate_initrd', 'update_grub_configuration', 'mkinitrd', 'grub-mkconfig')
FIELDS = ('STABLE_EXIT_CODE', 'RESULT_SUCCESS', 'RESULT_PARTIAL', 'RESULT_BOOT_SAFE', 'RESULT_REBOOT',
          'SBO_TARGET_SELECTION_STATUS', 'SBO_TARGET_SELECTION_ERROR', 'SBO_BUILD_STATUS', 'TOTAL_CORE',
          'SBO_OPTION_RECORD_COUNT', 'TOTAL_EXTRA', 'TOTAL', 'TOTAL_EN_COLA', 'ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def encode(rows):
    return b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in rows)


def scenario(root, profile, fault, abi, sbo, build):
    (root / 'queues').mkdir()
    (root / 'packages').mkdir()
    (root / 'queues/private.sqf').write_text('# empty\n' if profile == 'empty' else 'core-b\ncore-a | V=yes\n')
    (root / 'packages/native-1.0-x86_64-1').write_text('private manifest\n')
    if profile == 'full':
        for name in ('core-a-1.0-x86_64-1_SBo', 'extra-1.0-x86_64-1_SBo'):
            (root / 'packages' / name).write_text('private manifest\n')
    for name in ('core', 'extra', 'options', 'broken', 'final'):
        (root / name).write_text('old-' + name + '\n')
    expected = inventory(root)
    rows = []
    output = ''
    core = '' if profile == 'empty' else 'core-b\ncore-a\n'
    options = '' if profile == 'empty' else 'core-a\tV=yes\n'
    extra = 'core-a\nextra\n' if abi and profile == 'full' else ''
    final = '' if profile == 'empty' else 'core-b\ncore-a | V=yes\n' + ('extra\n' if abi else '')
    stage = fault.split('-')[0]
    failed_stage = stage if sbo and stage != 'none' and (stage != 'abi' or abi) else ''
    selection_failed = failed_stage in ('reset', 'options', 'core', 'abi')
    final_failed = failed_stage == 'final'
    error = {'reset': 'cannot remove previous private SBo queue files', 'options': 'cannot count normalized SBo option map', 'core': 'cannot count the core SBo queue',
             'abi': 'cannot count the ABI SBo target queue', 'final': 'cannot count the final dependency-ordered SBo queue'}.get(failed_stage, '')
    core_count = option_count = total = 0
    extra_count = 4 if sbo and not abi else 0
    build_status = -1
    selection = 0 if sbo else -1

    def file(name, value): expected[name] = ('file', value.encode())

    if sbo:
        rows += [('sync',), ('action', 'sbo', 'synchronize', 'success', 'SBo repository synchronization completed', 0),
                 ('core',), ('reset', '-f', str(root / 'core'), str(root / 'extra'), str(root / 'options'))]
        output += '[6] Generando colas SBo\n'
        if failed_stage == 'reset':
            if fault == 'reset-partial': output += 'supplied-reset-output\n'
            for name in ('core', 'extra', 'options'):
                present = fault == 'reset-quiet' or (fault == 'reset-partial' and name != 'core')
                rows.append(('reset-file', str(root / name), 'present', 'old-' + name) if present else
                            ('reset-file', str(root / name), 'absent'))
        else:
            rows.append(('count', 'options', '-l'))
        if failed_stage not in ('reset', 'options'):
            rows.append(('count', 'core', '-l'))
            if failed_stage != 'core':
                core_count = core.count('\n'); option_count = options.count('\n')
                output += f'  Cola principal: {core_count} paquetes\n  Opciones de compilacion preservadas: {option_count}\n'
                rows.append(('abi',))
                if abi:
                    rows.append(('count', 'abi', '-l'))
                    output += '[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra\n'
                    if failed_stage != 'abi':
                        extra_count = extra.count('\n')
                        output += f'  Cola ABI extra: {extra_count} paquetes\n'
        if selection_failed:
            output += '  [ERROR] ' + error + '\n'
            selection = 1
            core_count = option_count = extra_count = 0
            file('core', ''); file('extra', ''); file('options', '')
            rows.append(('action', 'sbo', 'build_queues', 'failed', 'SBo target selection failed: ' + error, 1))
        else:
            file('core', core); file('extra', extra); file('options', options)
            rows.append(('action', 'sbo', 'build_queues', 'success', 'Deterministic SBo target sets built', 0))
    else:
        file('core', ''); file('extra', ''); file('options', '')
        rows += [('action', 'sbo', 'synchronize', 'disabled', 'SBo repository synchronization was not applicable: supplied-off', 0),
                 ('action', 'sbo', 'build_queues', 'disabled', 'SBo queue generation was not applicable: supplied-off', 0)]
    file('broken', '')
    process_code = 0
    sbo_state = 'disabled' if not sbo else 'failed' if selection_failed else 'success'
    if sbo and not selection_failed:
        rows += [('final',), ('count', 'final', '-l')]
        file('final', final)
        output += '[10] Aplicando cola SBo\n'
        if final_failed:
            build_status = process_code = 1
            sbo_state = 'failed'
            output += '  [ERROR] ' + error + '\n'
        else:
            total = final.count('\n')
            output += f'  Total paquetes en cola: {total}\n'
            if total:
                rows.append(('builder', '-b', '-B', str(root / 'final')))
                build_status = process_code = build
                if build: sbo_state = 'failed'
                output += ('  [OK] Cola SBo procesada\n' if not build else
                           '  [WARN] sbopkg termino con errores -- revisar log: ' + str(root / 'run.log') + '\n')
            else:
                output += '  Cola vacia, nada que hacer\n'
        rows.append(('action', 'sbo', 'process_queue', sbo_state, 'Final SBo queue processing completed', process_code))
    elif sbo:
        process_code = 1
        rows.append(('action', 'sbo', 'process_queue', 'failed', 'SBo queue processing was blocked because target selection failed', 1))
    else:
        rows.append(('action', 'sbo', 'process_queue', 'disabled', 'SBo queue processing was not applicable: supplied-off', 0))
    rows += [('module', 'sbo', sbo_state, 'SBo update module completed', process_code), ('boot-callback',),
             ('summary', 'success', 'disabled', sbo_state, 'disabled', 'disabled', 0)]
    errors = []
    if selection_failed: errors.append('SBo target selection failed: ' + error)
    if build_status > 0: errors.append('sbopkg queue processing failed with exit code ' + str(build_status))
    fields = [2 if errors else 0, 0 if errors else 1, 1 if errors else 0, 1, 'none', selection, error,
              build_status, core_count, option_count, extra_count, total, total, -1, -1]
    settings = dict(FAULT=fault, ABI_TRIGGER=str(abi), SBO_RUN=str(sbo), BUILD_CODE=str(build), COUNT_STAGE='none', TOTAL='0',
        TOTAL_CORE='6', SBO_OPTION_RECORD_COUNT='5', TOTAL_EXTRA='4',
        PACKAGE_DATABASE=str(root / 'packages'), SBO_PACKAGE_TAG='_SBo', SBO_PERSONAL_QUEUE_DIR=str(root / 'queues'),
        QUEUE_CORE=str(root / 'core'), QUEUE_EXTRA=str(root / 'extra'), QUEUE_FINAL=str(root / 'final'),
        SBO_OPTION_RECORDS=str(root / 'options'), SBO_OPTIONS_FILE=str(root / 'overrides'), BROKEN=str(root / 'broken'),
        LOG=str(root / 'run.log'), OPERATION='apply', FLATPAK_MODE='disabled', SBO_MODE='auto', ELF_MODE='disabled',
        CINNAMON_MODE='disabled', BOOT_MODE='disabled', SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += 'initialize_runtime_state || exit 96\n'
    shell += '\n'.join(key + '=' + shlex.quote(value) for key, value in settings.items()) + '\n'
    shell += "IFS='|: '\naction_exit=77; sbo_state=outer-sbo\nraw=0\nrun_apply_workflow || raw=$?\ndetermine_stable_exit_code \"$raw\"\n"
    shell += '[[ $COUNT_STAGE == none ]] || exit 95\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    shell += r'''builtin printf '%s\0' "$IFS" "$action_exit" "$sbo_state"
builtin printf 'ERRORS\0'; builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0'; builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'sbo-count-apply-test', str(REFERENCE), str(root)],
                            cwd=root, capture_output=True, timeout=15, env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in [0, *fields, '|: ', 77, 'outer-sbo'])
    wanted += b'ERRORS\0' + b''.join(value.encode() + b'\0' for value in (errors or [''])) + b'WARNINGS\0\0'
    trace = (root / 'events').read_bytes()
    if result.returncode or result.stderr or result.stdout != wanted or trace != encode(rows) or inventory(root) != expected:
        raise AssertionError(dict(case=(profile, fault, abi, sbo, build), returncode=result.returncode,
            stdout=result.stdout, expected_stdout=wanted, stderr=result.stderr, trace=trace, expected_trace=encode(rows),
            inventory_matches=inventory(root) == expected))


def main():
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-sbo-count-apply-') as tmp:
        for values in itertools.product(('empty', 'full'), FAULTS, (0, 1), (0, 1), (0, 43)):
            root = Path(tmp) / str(count)
            root.mkdir()
            scenario(root, *values)
            count += 1
    print(f'SBo count/reset apply composition: {count} scenarios, 0 failures')


if __name__ == '__main__':
    main()
