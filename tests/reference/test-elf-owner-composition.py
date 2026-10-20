#!/usr/bin/env python3
"""Compose real apply/owner/builder/result helpers with private files and supplied operations."""
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
PROFILES = ('owned', 'unowned', 'empty')
FAULTS = ('none', 'scan', 'lookup', 'order', 'count', 'count-partial', 'publish', 'publish-partial')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
event() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/events"; builtin printf '\n' >> "$TEST_ROOT/events"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
date() { [[ $# == 2 && $1 == -u && $2 == '+%Y-%m-%dT%H:%M:%SZ' ]] || forbidden clock-vector; builtin printf '2000-01-01T00:00:00Z\n'; }
eval "$(declare -f map_broken_objects_to_sbo_packages | sed '1s/map_broken_objects_to_sbo_packages/real_map_broken_objects_to_sbo_packages/')"
map_broken_objects_to_sbo_packages() {
    event map
    local status=0
    OWNER_ACTIVE=1
    real_map_broken_objects_to_sbo_packages || status=$?
    OWNER_ACTIVE=0
    return "$status"
}
capture_package_snapshot_before() { PACKAGE_SNAPSHOT_BEFORE_VALID=1; PACKAGE_SNAPSHOT_BEFORE_COUNT=3; }
probe_boot_module() { BOOT_MODULE_STATE=disabled; return 0; }
prepare_geninitrd_grub_policy_override() { GENINITRD_POLICY_OVERRIDE_STATUS=supplied-prepared; return 0; }
restore_geninitrd_grub_policy_override() { GENINITRD_POLICY_OVERRIDE_STATUS=supplied-restored; return 0; }
capture_package_snapshot_after() { PACKAGE_SNAPSHOT_AFTER_VALID=1; PACKAGE_SNAPSHOT_AFTER_COUNT=4; }
update_slackware_system() {
    SLACKPKG_UPDATE_STATUS=0; SLACKPKG_INSTALL_NEW_STATUS=0; SLACKPKG_UPGRADE_ALL_STATUS=0
    PENDING_NEW_CONFIG_FILES_VALID=1; PENDING_NEW_CONFIG_FILES_COUNT=0
}
probe_optional_modules() {
    FLATPAK_MODULE_RUN=0; CINNAMON_MODULE_RUN=0
    FLATPAK_MODULE_STATE=disabled; CINNAMON_MODULE_STATE=disabled
    FLATPAK_MODULE_REASON=supplied-off; CINNAMON_MODULE_REASON=supplied-off
    SBO_MODULE_RUN=$SBO_RUN; ELF_MODULE_RUN=$ELF_RUN
    SBO_MODULE_STATE=disabled; ELF_MODULE_STATE=disabled
    SBO_MODULE_REASON=supplied-off; ELF_MODULE_REASON=supplied-off
    [[ $SBO_RUN == 0 ]] || SBO_MODULE_STATE=available
    [[ $ELF_RUN == 0 ]] || ELF_MODULE_STATE=available
    return 0
}
print_optional_module_activation() { :; }
detect_abi_changes() { :; }
detect_kernel_changes() { :; }
synchronize_sbo_repository() { SBOPKG_SYNC_STATUS=0; SQG_SYNC_STATUS=0; }
build_sbo_target_queues_after_synchronization() {
    event queues
    builtin printf 'core-b\ncore-a\n' > "$QUEUE_CORE"
    builtin printf 'zeta\nabi\n' > "$QUEUE_EXTRA"
    : > "$SBO_OPTION_RECORDS"
    TOTAL_CORE=2; TOTAL_EXTRA=2; SBO_OPTION_RECORD_COUNT=0; SBO_TARGET_SELECTION_ERROR=
}
detect_broken_elf_objects() {
    event scan
    : > "$BROKEN"
    if [[ $PROFILE != empty ]]; then builtin printf '%s' "$OBJECT_PATH" > "$BROKEN"; fi
    ELF_SCAN_STATUS=0
    if [[ $FAULT == scan ]]; then ELF_SCAN_STATUS=43; return 43; fi
    return 0
}
grep() {
    [[ $# == 7 && $1 == -rlFx && $2 == -e && $4 == -e && $6 == -- \
        && $3 == "$OBJECT_PATH" && $7 == "$PACKAGE_DATABASE/" ]] || forbidden grep-vector
    if [[ $OWNER_ACTIVE == 1 && $FAULT == lookup ]]; then return 43; fi
    builtin command grep "$@"
}
sort() {
    if [[ $OWNER_ACTIVE == 1 && $FAULT == order ]]; then
        local line
        while IFS= read -r line || [[ -n $line ]]; do :; done
        return 43
    fi
    builtin command sort "$@"
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden count-vector
    if [[ $OWNER_ACTIVE == 1 && ( $FAULT == count || $FAULT == count-partial ) ]]; then
        if [[ $FAULT == count-partial ]]; then builtin printf '42\n'; fi
        return 43
    fi
    builtin command wc "$@"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$TEST_ROOT/"* && $4 == "$TEST_ROOT/"* ]] || forbidden move-vector
    if [[ $OWNER_ACTIVE == 1 && $3 == "$QUEUE_EXTRA.merged" && $4 == "$QUEUE_EXTRA" \
        && ( $FAULT == publish || $FAULT == publish-partial ) ]]; then
        if [[ $FAULT == publish-partial ]]; then builtin printf 'supplied-partial\n' > "$QUEUE_EXTRA"; fi
        return 43
    fi
    builtin command mv "$@"
}
sbopkg() {
    [[ $# == 3 && $1 == -b && $2 == -B && $3 == "$QUEUE_FINAL" ]] || forbidden builder-vector
    event builder "$@"
    return "$BUILD_CODE"
}
verify_broken_elf_objects_after_rebuild() {
    event recheck
    : > "$BROKEN"; ELF_VERIFICATION_STATUS=0
}
emit_module_started_event() { :; }
emit_action_started_event() { :; }
emit_action_completed_event() {
    if [[ $1 == elf || ( $1 == sbo && $2 == process_queue ) ]]; then event action "$@"; fi
    return 0
}
emit_module_completed_event() {
    if [[ $1 == elf || $1 == sbo ]]; then event module "$@"; fi
    return 0
}
run_boot_preparation_module() { event boot-callback; return 0; }
print_summary() {
    event summary "$slackware_state" "$flatpak_state" "$sbo_state" "$elf_state" "$cinnamon_state" "$action_exit"
    return 0
}
'''
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'configure_logging',
          'load_configuration', 'run_check_workflow', 'run_dry_run_workflow', 'update_flatpak',
          'rebuild_cinnamon', 'capture_validated_package_snapshot', 'stage_geninitrd_grub_policy_override',
          'readelf', 'ldd', 'ldconfig', 'slackpkg', 'sqg', 'flatpak', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration', 'mkinitrd', 'grub-mkconfig')
FIELDS = ('STABLE_EXIT_CODE', 'RESULT_SUCCESS', 'RESULT_PARTIAL', 'RESULT_BOOT_SAFE', 'RESULT_REBOOT',
          'SBO_TARGET_SELECTION_STATUS', 'SBO_TARGET_SELECTION_ERROR', 'SBO_BUILD_STATUS', 'TOTAL_EXTRA',
          'TOTAL_EN_COLA', 'ELF_SCAN_STATUS', 'ELF_VERIFICATION_STATUS')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('dir',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*') if p.name != 'events'}


def encode(rows):
    return b''.join(b''.join(str(value).encode() + b'\0' for value in row) + b'\n' for row in rows)


def scenario(root, profile, fault, sbo, elf, build):
    (root / 'objects').mkdir(); (root / 'packages').mkdir()
    obj = root / 'objects/lib[7]+.so'; obj.write_text('private text object; no ELF execution\n')
    (root / 'packages/owner-1.0-x86_64-1_SBo').write_text(str(obj) + ('-suffix' if profile == 'unowned' else '') + '\n')
    (root / 'packages/decoy-1.0-x86_64-1_SBo').write_text(str(obj) + '-tail\n')
    (root / 'packages/native-1.0-x86_64-1').write_text(str(obj) + '\n')
    for name, data in {'core': 'stale-core\n', 'extra': 'stale-extra\n', 'options': '',
                       'broken': 'stale-broken\n', 'final': 'old-final\n'}.items():
        (root / name).write_text(data)
    expected = inventory(root); rows = []; output = ''
    def file(name, value): expected[name] = ('file', value.encode())
    if sbo:
        rows.append(('queues',)); file('core', 'core-b\ncore-a\n'); file('extra', 'zeta\nabi\n')
    else:
        file('core', ''); file('extra', '')
    file('options', '')
    error = ''; selection = 0 if sbo else -1; extra_count = 2 if sbo else 0
    broken = str(obj) if elf and profile != 'empty' else ''
    file('broken', broken)
    scan_failed = bool(elf and fault == 'scan')
    mapping_failed = bool(elf and not scan_failed and profile != 'empty' and fault != 'none')
    if elf:
        rows.append(('scan',))
        if not scan_failed:
            rows.append(('map',)); output += '[9] Mapeando binarios rotos a paquetes SBo\n'
            if profile == 'empty': output += '  Sin binarios rotos, nada que anadir\n'
            elif mapping_failed:
                error = ('cannot collect broken-object SBo owners' if fault in ('lookup', 'order') else
                         'cannot count merged broken-object SBo targets' if fault in ('count', 'count-partial') else
                         'cannot publish broken-object SBo targets')
                output += '  [ERROR] ' + error + '\n'
                if fault == 'publish-partial': file('extra', 'supplied-partial\n')
            else:
                targets = (['abi', 'zeta'] if sbo else []) + (['owner'] if profile == 'owned' else [])
                targets = sorted(targets); extra_count = len(targets)
                file('extra', ''.join(target + '\n' for target in targets))
                output += '  Cola extra tras rotos: ' + str(extra_count) + ' paquetes\n'
    failed = scan_failed or mapping_failed
    if failed: selection = 1
    elf_state = 'disabled' if not elf else 'failed' if failed else 'warning' if broken else 'success'
    rows.append(('action', 'elf', 'scan_dependencies', elf_state,
                 'ELF dependency scan was not applicable: supplied-off' if not elf else
                 'Static ELF inspection or ownership mapping failed' if failed else 'ELF dependency scan completed',
                 1 if failed else 0))
    rows.append(('module', 'elf', elf_state, 'ELF dependency module completed', 0))
    builder = bool(sbo and not failed); recheck = bool(builder and broken)
    total = 0; build_status = -1
    sbo_state = 'failed' if failed else 'success' if sbo else 'disabled'
    if builder:
        extras = sorted((['abi', 'zeta'] if sbo else []) + (['owner'] if elf and profile == 'owned' else []))
        final = ['core-b', 'core-a'] + extras; total = len(final)
        file('final', ''.join(name + '\n' for name in final))
        rows.append(('builder', '-b', '-B', str(root / 'final')))
        build_status = build
        output += '[10] Aplicando cola SBo\n  Total paquetes en cola: ' + str(total) + '\n'
        output += ('  [OK] Cola SBo procesada\n' if not build else
                   '  [WARN] sbopkg termino con errores -- revisar log: ' + str(root / 'run.log') + '\n')
        if recheck:
            rows.append(('recheck',)); broken = ''; file('broken', '')
        if build: sbo_state = 'failed'
    raw_sbo = build if builder else 1 if failed else 0
    rows.append(('action', 'sbo', 'process_queue', sbo_state,
                 'Final SBo queue processing completed' if builder else
                 'SBo queue processing was blocked because target selection failed' if sbo else
                 'SBo queue processing was not applicable: supplied-off', raw_sbo if sbo else 0))
    rows.append(('module', 'sbo', sbo_state, 'SBo update module completed', raw_sbo))
    rows += [('boot-callback',), ('summary', 'success', 'disabled', sbo_state, elf_state, 'disabled', 0)]
    errors = []
    if failed: errors.append('SBo target selection failed: ' + (error or 'unknown selection failure'))
    if builder and build: errors.append('sbopkg queue processing failed with exit code ' + str(build))
    if elf and broken: errors.append('ELF dependency verification still reports broken objects')
    fields = [2 if errors else 0, 0 if errors else 1, 1 if errors else 0, 1, 'none', selection, error,
              build_status, extra_count, total, 43 if scan_failed else 0 if elf else -1, 0 if recheck else -1]
    settings = dict(PROFILE=profile, FAULT=fault, SBO_RUN=str(sbo), ELF_RUN=str(elf), BUILD_CODE=str(build),
                    OBJECT_PATH=str(obj), OWNER_ACTIVE='0', PACKAGE_DATABASE=str(root / 'packages'), SBO_PACKAGE_TAG='_SBo',
                    QUEUE_CORE=str(root / 'core'), QUEUE_EXTRA=str(root / 'extra'), QUEUE_FINAL=str(root / 'final'),
                    SBO_OPTION_RECORDS=str(root / 'options'), BROKEN=str(root / 'broken'), LOG=str(root / 'run.log'),
                    OPERATION='apply', FLATPAK_MODE='disabled', SBO_MODE='auto', ELF_MODE='auto',
                    CINNAMON_MODE='disabled', BOOT_MODE='disabled', SBO_QUEUE_DIR_FALLBACK='supplied-fallback')
    shell = PREFIX + '\n' + '\n'.join(name + '() { forbidden ' + name + '; }' for name in GUARDS) + '\n'
    shell += 'initialize_runtime_state || exit 96\n'
    shell += '\n'.join(key + '=' + shlex.quote(value) for key, value in settings.items()) + '\n'
    shell += r'''
IFS='|: '
action_exit=77; sbo_state=outer-sbo; elf_state=outer-elf
raw=0
run_apply_workflow || raw=$?
determine_stable_exit_code "$raw"
builtin printf '\0STATE\0%s\0' "$raw"
'''
    shell += '\n'.join('builtin printf "%s\\0" "${' + name + '}"' for name in FIELDS) + '\n'
    shell += r'''
builtin printf '%s\0' "$IFS" "$action_exit" "$sbo_state" "$elf_state"
builtin printf 'ERRORS\0'; builtin printf '%s\0' "${RESULT_ERRORS[@]}"
builtin printf 'WARNINGS\0'; builtin printf '%s\0' "${RESULT_WARNINGS[@]}"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'owner-composition', str(REFERENCE), str(root)],
                            cwd=root, capture_output=True, timeout=15,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + b''.join(str(value).encode() + b'\0' for value in
             [0, *fields, '|: ', 77, 'outer-sbo', 'outer-elf'])
    wanted += b'ERRORS\0' + b''.join(value.encode() + b'\0' for value in (errors or [''])) + b'WARNINGS\0\0'
    trace = (root / 'events').read_bytes() if (root / 'events').exists() else b''
    if result.returncode or result.stderr or result.stdout != wanted or trace != encode(rows) or inventory(root) != expected:
        raise AssertionError(dict(profile=profile, fault=fault, sbo=sbo, elf=elf, build=build,
                                  returncode=result.returncode, stdout=result.stdout, expected_stdout=wanted,
                                  stderr=result.stderr, trace=trace, expected_trace=encode(rows),
                                  inventory_matches=inventory(root) == expected))


def main():
    failures = []; count = 0
    for profile in PROFILES:
        for fault in FAULTS:
            for sbo in (0, 1):
                for elf in (0, 1):
                    for build in (0, 43):
                        count += 1
                        with tempfile.TemporaryDirectory(prefix='owner-composition-test-') as temporary:
                            try: scenario(Path(temporary), profile, fault, sbo, elf, build)
                            except AssertionError as error: failures.append((count, str(error)))
    if failures:
        for number, error in failures: print(f'FAIL owner composition {number}: {error}', file=sys.stderr)
        raise SystemExit(f'ELF owner composition: {count - len(failures)} pass, {len(failures)} fail')
    print(f'ELF owner composition: {count} scenarios PASS')


if __name__ == '__main__': main()
