#!/usr/bin/env python3
"""Check literal ELF-owner selection against authored private package manifests."""

import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
PROFILES = (
    ('plain', 'plain-suffix'),
    ('libfoo.so.1', 'libfooxsox1'),
    ('libfoo+plus.so', 'libfooplus.so'),
    ('bracket[7].so', 'bracket7.so'),
    ('paren(7).so', 'paren7.so'),
    ('brace{7}.so', 'braceeeeeee.so'),
    ('star*.so', 'starr.so'),
    ('question?.so', 'questio.so'),
    ('caret^.so', 'caret.so'),
    ('dollar$.so', 'dollar.so'),
    ('pipe|.so', 'pipe.so'),
    ('back\\slash.so', 'back lash.so'),
    ('space name.so', 'spaceXname.so'),
    ('tab\tname.so', 'tabXname.so'),
    ('trailing-tab\t', 'trailing-tab'),
    (' leading-space ', 'leading-space'),
    ('-option.so', '-optionXso'),
    ('ñandú.so', 'ñandúXso'),
)
GUARDS = ('main', 'initialize_execution_environment', 'initialize_runtime', 'load_configuration',
          'run_apply_workflow', 'run_check_workflow', 'run_dry_run_workflow',
          'detect_broken_elf_objects', 'verify_broken_elf_objects_after_rebuild',
          'refresh_static_elf_library_cache', 'readelf', 'ldd', 'ldconfig',
          'slackpkg', 'sbopkg', 'sqg', 'flatpak', 'git', 'curl', 'wget',
          'regenerate_initrd', 'update_grub_configuration')


def inventory(root):
    return {p.relative_to(root).as_posix(): ('link', os.readlink(p)) if p.is_symlink()
            else ('directory',) if p.is_dir() else ('file', p.read_bytes())
            for p in root.rglob('*')}


def scenario(root, leaf, decoy_leaf, slash, terminated, kind='owned', tag='_SBo', linked=False):
    objects = root / 'objects'
    database = root / 'packages'
    objects.mkdir()
    database.mkdir()
    object_path = objects / leaf
    if kind != 'missing-object':
        object_path.write_bytes(b'private object; no ELF reader is invoked\n')
    path = str(object_path)
    body_path = path if slash == 'absolute' else path[1:]
    decoy_path = str(objects / decoy_leaf)
    if slash == 'relative':
        decoy_path = decoy_path[1:]
    def manifest(name, lines):
        (database / name).write_text('PACKAGE DESCRIPTION:\nFILE LIST:\n' + '\n'.join(lines) + '\n')
    owner_lines = [body_path] if kind not in ('unowned', 'substring-only') else [body_path + '-suffix']
    manifest('owner-1.0-x86_64-1' + tag, owner_lines)
    # A second version of the same owner must not duplicate the target.
    manifest('owner-2.0-x86_64-2' + tag, owner_lines)
    manifest('decoy-1.0-x86_64-1' + tag, [decoy_path, body_path + '-suffix', 'prefix-' + body_path])
    manifest('native-1.0-x86_64-1', [body_path])
    manifest('wrong-1.0-x86_64-1' + tag + '_debug', [body_path])
    manifest('malformed', [body_path])
    broken = root / 'broken'
    if kind != 'missing-list':
        lines = [] if kind == 'empty-list' else [path]
        if kind == 'duplicates':
            lines = ['', path, path, '', path]
        broken.write_text('\n'.join(lines) + ('\n' if lines and terminated else ''))
    queue = root / 'queue-extra'
    queue.write_text('zeta\nabi\nzeta\n')
    package_database = database
    if linked:
        package_database = root / 'packages-link'
        package_database.symlink_to(database, target_is_directory=True)
    expected = inventory(root)
    active = kind not in ('empty-list', 'missing-list')
    targets = ['abi', 'owner', 'zeta'] if kind in ('owned', 'duplicates') else ['abi', 'zeta']
    if active:
        expected['queue-extra'] = ('file', ''.join(target + '\n' for target in targets).encode())
    output = '[9] Mapeando binarios rotos a paquetes SBo\n'
    output += ('  Cola extra tras rotos: ' + str(len(targets)) + ' paquetes\n' if active
               else '  Sin binarios rotos, nada que anadir\n')
    total = str(len(targets)) if active else '9'
    assignments = dict(BROKEN=str(broken), QUEUE_EXTRA=str(queue), PACKAGE_DATABASE=str(package_database),
                       SBO_PACKAGE_TAG=tag, SBO_TARGET_SELECTION_ERROR='', TOTAL_EXTRA='9',
                       ELF_SCAN_STATUS='8', ELF_VERIFICATION_STATUS='7')
    shell = 'source "$1"\n'
    shell += '\n'.join(name + '() { builtin printf "prohibited boundary: %s\\n" ' + shlex.quote(name)
                       + ' >&2; exit 97; }' for name in GUARDS) + '\n'
    shell += '\n'.join(key + '=' + shlex.quote(value) for key, value in assignments.items()) + '\n'
    shell += r'''
outer=preserved
saved_ifs=$IFS
map_broken_objects_to_sbo_packages
raw=$?
[[ $IFS == "$saved_ifs" && $outer == preserved ]] || exit 96
builtin printf '\0STATE\0%s\0%s\0%s\0%s\0%s\0' \
    "$raw" "$TOTAL_EXTRA" "$SBO_TARGET_SELECTION_ERROR" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS"
'''
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', shell, 'owner-test', str(REFERENCE)],
                            cwd=root, capture_output=True, timeout=15,
                            env=dict(os.environ, LC_ALL='C', TMPDIR=str(root)))
    wanted = output.encode() + b'\0STATE\0' + b'0\0' + total.encode() + b'\0\0' + b'8\0' + b'7\0'
    if result.returncode != 0 or result.stdout != wanted or result.stderr or inventory(root) != expected:
        raise AssertionError(dict(kind=kind, leaf=leaf, slash=slash, terminated=terminated, linked=linked,
                                  returncode=result.returncode, stdout=result.stdout, expected_stdout=wanted,
                                  stderr=result.stderr, inventory_matches=inventory(root) == expected))


def main():
    cases = [(leaf, decoy, slash, terminated, 'owned', '_SBo', False)
             for leaf, decoy in PROFILES for slash in ('absolute', 'relative') for terminated in (True, False)]
    cases += [('plain', 'plain-suffix', slash, terminated, kind, '_SBo', False)
              for slash in ('absolute', 'relative') for terminated in (True, False)
              for kind in ('unowned', 'missing-object', 'duplicates')]
    cases += [('plain', 'plain-suffix', 'absolute', True, kind, '_SBo', False)
              for kind in ('empty-list', 'missing-list', 'substring-only')]
    cases += [('bracket[7].so', 'bracket7.so', slash, terminated, 'owned', '_custom', True)
              for slash in ('absolute', 'relative') for terminated in (True, False)]
    failures = []
    for number, case in enumerate(cases, 1):
        with tempfile.TemporaryDirectory(prefix='elf-owner-test-') as temporary:
            try:
                scenario(Path(temporary), *case)
            except AssertionError as error:
                failures.append((number, str(error)))
    if failures:
        for number, error in failures:
            print(f'FAIL owner case {number}: {error}', file=sys.stderr)
        raise SystemExit(f'ELF owner mapping: {len(cases) - len(failures)} pass, {len(failures)} fail')
    print(f'ELF owner mapping: {len(cases)} scenarios PASS')


if __name__ == '__main__':
    main()
