#!/usr/bin/env python3
"""Check private boot configuration readers and supplied-validator GRUB checks."""
from pathlib import Path
import itertools
import os
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/trace"; builtin printf '\n' >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$*" >&2; exit 97; }
'''
GUARDS = '\n'.join(name + '() { forbidden ' + name + '; }' for name in (
    'main', 'initialize_execution_environment', 'initialize_runtime', 'cleanup',
    'run_apply_workflow', 'regenerate_initrd', 'update_grub_configuration',
    'install_validated_grub_config', 'mkinitrd', 'geninitrd', 'grub-mkconfig',
    'slackpkg', 'sbopkg', 'curl', 'wget', 'git', 'uname', 'eval'))


def q(value):
    return shlex.quote(str(value))


def run(root, bindings, operation, fields):
    body = PREFIX + GUARDS + '\nIFS="|: "\n'
    body += '\n'.join(name + '=' + q(value) for name, value in bindings.items())
    body += '\n' + operation + '\nstatus=$?\n'
    body += 'builtin printf "%s\\0" "$status" ' + ' '.join('"${' + name + '}"' for name in fields) + ' "$IFS"\n'
    result = subprocess.run(['bash', '--noprofile', '--norc', '-c', body, 'boot-validation-test',
                             str(REFERENCE), str(root)], capture_output=True, timeout=10,
                            env=dict(os.environ, LC_ALL='C'))
    assert result.returncode == 0 and result.stderr == b'', (result.returncode, result.stdout, result.stderr)
    return result.stdout


def packet(*values):
    return b''.join(str(value).encode() + b'\0' for value in (*values, '|: '))


def scalar_cases(root):
    cases = [
        ('missing', '', 2, '', 'mkinitrd configuration is not a regular file: {path}'),
        ('directory', '', 2, '', 'mkinitrd configuration is not a regular file: {path}'),
        ('regular', '', 1, '', '{name} assignment is missing from: {path}'),
        ('regular', '# {name}=ignored\nOTHER=x\n', 1, '', '{name} assignment is missing from: {path}'),
        ('regular', '{name}=6.1\n', 0, '6.1', ''),
        ('regular', ' export {name} = "6.1" # note\r\n', 0, '6.1', ''),
        ('regular', "{name}='/dev/root'", 0, '/dev/root', ''),
        ('symlink', '{name}=UUID=abc-123\n', 0, 'UUID=abc-123', ''),
        ('regular', '{name}=a_b+.,:/=@%-\n', 0, 'a_b+.,:/=@%-', ''),
        ('regular', '{name}=abc# comment\n', 0, 'abc', ''),
        ('regular', '{name}=\n', 2, '', 'empty {name} assignment in: {path}'),
        ('regular', '{name}=""\n', 2, '', 'unsafe {name} assignment in: {path}'),
        ('regular', '{name}="abc\n', 2, '', 'unterminated {name} assignment in: {path}'),
        ('regular', '{name}=ab"c\n', 2, '', 'invalid quoting in {name} assignment: {path}'),
        ('regular', '{name}="a b"\n', 2, '', 'unsafe {name} assignment in: {path}'),
        ('regular', '{name}="abc#def"\n', 2, '', 'unterminated {name} assignment in: {path}'),
        ('regular', '{name}=first\n{name}=second\n', 2, 'first', 'duplicate {name} assignment in: {path}'),
        ('regular', '{name}=first\nexport {name}=second\n', 2, 'first', 'duplicate {name} assignment in: {path}'),
        ('regular', 'export{name}=ignored\n{name}_OTHER=no\n', 1, '', '{name} assignment is missing from: {path}'),
        ('regular', '{name}="$(touch {marker})"\n', 2, '', 'unsafe {name} assignment in: {path}'),
        ('regular', '{name}=`touch {marker}`\n', 2, '', 'unsafe {name} assignment in: {path}'),
        ('regular', '{name}="abc"tail\n', 2, '', 'unterminated {name} assignment in: {path}'),
    ]
    count = 0
    for name, case in itertools.product(('KERNEL_VERSION', 'ROOTDEV'), cases):
        kind, text, status, value, error = case
        work = root / ('scalar-' + str(count)); work.mkdir()
        path = work / 'config'; marker = work / 'must-not-execute'
        substitutions = dict(name=name, path=str(path), marker=str(marker))
        if kind == 'directory':
            path.mkdir()
        elif kind != 'missing':
            target = work / 'target' if kind == 'symlink' else path
            target.write_text(text.format(**substitutions))
            if kind == 'symlink':
                path.symlink_to(target)
        before = sorted(p.name for p in work.iterdir())
        result = run(work, dict(MKINITRD_ASSIGNMENT_VALUE='stale', MKINITRD_ASSIGNMENT_ERROR='stale'),
                     'read_mkinitrd_scalar_assignment ' + q(path) + ' ' + q(name),
                     ('MKINITRD_ASSIGNMENT_VALUE', 'MKINITRD_ASSIGNMENT_ERROR'))
        assert result == packet(status, value, error.format(**substitutions)), (name, case, result)
        assert sorted(p.name for p in work.iterdir()) == before and not marker.exists()
        count += 1
    return count


def version_cases(root):
    values = [('6.1', 0), ('6.1-rc1+local', 0), ('_', 0), ('-', 0), ('a', 0),
              ('...', 0), ('1..2', 0), ('6_1', 0), ('', 1), ('.', 1), ('..', 1),
              ('a/b', 1), ('a b', 1), ('a\tb', 1), ('a\nb', 1), ('a:b', 1),
              ('$(true)', 1), ('a;true', 1), ('é', 1), ('*', 1)]
    for value, status in values:
        assert run(root, {}, 'is_safe_kernel_version ' + q(value), ()) == packet(status), value
    return len(values)


def snapshot_cases(root):
    record = 'kernel-generic-6.1-x86_64-1'
    cases = [
        ('missing', '', 1, '', 0, 'installed package snapshot is unavailable: {path}'),
        ('directory', '', 1, '', 0, 'installed package snapshot is unavailable: {path}'),
        ('regular', '', 1, '', 0, 'installed kernel package was not found in the post-update snapshot: kernel-generic'),
        ('regular', 'bad\nbash-5.2-x86_64-1\n', 1, '', 0, 'installed kernel package was not found in the post-update snapshot: kernel-generic'),
        ('regular', record, 0, '6.1', 1, 'outer-error'),
        ('regular', record + '\n' + record + '\n', 0, '6.1', 2, 'outer-error'),
        ('regular', record + '\nkernel-generic-6.1-i586-2\n', 0, '6.1', 2, 'outer-error'),
        ('regular', 'cache/' + record + '.txz\n', 0, '6.1', 1, 'outer-error'),
        ('regular', record + '\nkernel-generic-6.2-x86_64-1\n', 1, '', 2, 'installed kernel package has multiple versions in the post-update snapshot: kernel-generic'),
        ('regular', 'kernel-generic-.-x86_64-1\n', 1, '', 0, 'installed kernel package has an unsafe version: kernel-generic-.-x86_64-1'),
        ('regular', record + '\nkernel-generic-..-x86_64-1\n', 1, '', 1, 'installed kernel package has an unsafe version: kernel-generic-..-x86_64-1'),
        ('symlink', record + '\n', 0, '6.1', 1, 'outer-error'),
    ]
    for number, (kind, text, status, version, count, error) in enumerate(cases):
        work = root / ('snapshot-' + str(number)); work.mkdir(); path = work / 'snapshot'
        if kind == 'directory':
            path.mkdir()
        elif kind != 'missing':
            target = work / 'target' if kind == 'symlink' else path
            target.write_text(text)
            if kind == 'symlink': path.symlink_to(target)
        result = run(work, dict(INITRD_VALIDATION_ERROR='outer-error', INITRD_INSTALLED_KERNEL_VERSION='stale',
                               INITRD_INSTALLED_KERNEL_RECORD_COUNT=99),
                     'resolve_installed_initrd_kernel_version ' + q(path) + ' kernel-generic',
                     ('INITRD_INSTALLED_KERNEL_VERSION', 'INITRD_INSTALLED_KERNEL_RECORD_COUNT', 'INITRD_VALIDATION_ERROR'))
        assert result == packet(status, version, count, error.format(path=path)), (number, result)
    return len(cases)


def output_cases(root):
    cases = [
        ('OUTPUT_IMAGE=/primary\nOUTPUT=/legacy\n', '/default', 0, '/primary', 'outer-error'),
        ('OUTPUT=/legacy\n', '/default', 0, '/legacy', 'outer-error'),
        ('# absent\n', '/default', 0, '/default', 'outer-error'),
        ('', 'relative-default', 1, 'relative-default', 'resolved initrd output path is not absolute: relative-default'),
        ('OUTPUT_IMAGE=relative\nOUTPUT=/legacy\n', '/default', 1, 'relative', 'resolved initrd output path is not absolute: relative'),
        ('OUTPUT_IMAGE=\nOUTPUT=/legacy\n', '/default', 1, '', 'empty OUTPUT_IMAGE assignment in: {path}'),
        ('OUTPUT_IMAGE=/one\nOUTPUT_IMAGE=/two\n', '/default', 1, '', 'duplicate OUTPUT_IMAGE assignment in: {path}'),
        ('OUTPUT="unterminated\n', '/default', 1, '', 'unterminated OUTPUT assignment in: {path}'),
        ('OUTPUT_IMAGE=/../opaque\n', '/default', 0, '/../opaque', 'outer-error'),
        (None, '/default', 1, '', 'mkinitrd configuration is not a regular file: {path}'),
    ]
    for number, (text, default, status, value, error) in enumerate(cases):
        work = root / ('output-' + str(number)); work.mkdir(); path = work / 'config'
        if text is not None: path.write_text(text)
        result = run(work, dict(MKINITRD_CONFIG=path, INITRD_DEFAULT_OUTPUT=default,
                               INITRD_OUTPUT_PATH='stale', INITRD_VALIDATION_ERROR='outer-error'),
                     'resolve_configured_initrd_output_path', ('INITRD_OUTPUT_PATH', 'INITRD_VALIDATION_ERROR'))
        assert result == packet(status, value, error.format(path=path)), (number, result)
    return len(cases)


def grub_cases(root):
    valid = 'linux /vmlinuz-6.1 root=/dev/root\ninitrd /initrd-6.1.img\n'
    bodies = [
        (valid, True),
        ('linuxefi /boot/vmlinuz-generic\ninitrdefi /microcode /boot/initrd-link.img\n', True),
        ('linux /vmlinuz-6.1\n# no initrd\n', False),
        ('linux /wrong\ninitrd /initrd-6.1.img\n', False),
        ('# linux /vmlinuz-6.1\n# initrd /initrd-6.1.img\n', False),
        ('menuentry a {\n linux /vmlinuz-6.1\n}\nmenuentry b {\n initrd /initrd-6.1.img\n}\n', True),
    ]
    cases = [(text, 'regular', 'direct-generic-no-initrd', 'generated-initrd', '6.1', '/elsewhere/initrd-6.1.img', validator)
             for text, _ in bodies for validator in (0, 23, 126, -1)]
    cases += [(valid, kind, 'direct-generic-no-initrd', 'generated-initrd', '6.1', '/x/initrd-6.1.img', 0)
              for kind in ('missing', 'directory', 'symlink', 'empty')]
    cases += [(text, 'regular', layout, state, version, initrd, 0) for text, layout, state, version, initrd in (
        ('opaque\n', 'unknown', 'unknown', 'unsafe/version', '/wrong'),
        ('linux /vmlinuz-generic\n', 'direct-generic-no-initrd', 'unknown', '6.1', ''),
        (valid, 'direct-generic-no-initrd', 'generated-initrd', 'unsafe/version', '/x/initrd-6.1.img'),
        (valid, 'direct-generic-no-initrd', 'generated-initrd', '6.1', '/x/wrong.img'),
        ('linux /vmlinuz-generic\n', 'direct-generic-no-initrd', 'unknown', 'unsafe/version', ''),
        (valid, 'direct-generic-no-initrd', 'generated-initrd', '', '/x/initrd-6.1.img'),
    )]
    for number, (text, kind, layout, state, version, initrd, validator) in enumerate(cases):
        work = root / ('grub-' + str(number)); work.mkdir(); path = work / 'candidate'
        target = work / 'target' if kind == 'symlink' else path
        if kind == 'directory': path.mkdir()
        elif kind != 'missing':
            target.write_text('' if kind == 'empty' else text); target.chmod(0o640)
            if kind == 'symlink': path.symlink_to(target)
        operation = r'''
chmod() { record chmod "$@"; builtin command chmod "$@"; }
command() {
    [[ $# == 2 && $1 == -v && $2 == grub-script-check ]] || forbidden discovery-vector
    record discover "$2"
    [[ $VALIDATOR != -1 ]]
}
grub-script-check() { record validate "$@"; return "$VALIDATOR"; }
validate_generated_grub_config
'''
        result = run(work, dict(GRUB_TEMP_CONFIG=path, GRUB_VALIDATION_STATUS=99, GRUB_VALIDATION_ERROR='stale',
                               BOOT_PREPARATION_LAYOUT=layout, GENINITRD_POST_STATE=state, GENINITRD_POST_KERNEL_VERSION=version,
                               DIRECT_GENERIC_INSTALLED_KERNEL_VERSION='6.1' if not version else 'wrong-fallback', GENINITRD_POST_INITRD_PATH=initrd,
                               GENINITRD_NAMED_INITRD_GRUB_PATH='/boot/initrd-link.img', VALIDATOR=validator),
                     operation, ('GRUB_VALIDATION_STATUS', 'GRUB_VALIDATION_ERROR'))
        status, error = 1, 'generated GRUB configuration is not a readable regular file'
        calls = []
        if kind == 'empty': error = 'generated GRUB configuration is empty'
        elif kind == 'regular':
            calls = [('chmod', '0600', '--', str(path)), ('discover', 'grub-script-check')]
            if validator == -1: error = 'grub-script-check is unavailable'
            else:
                calls.append(('validate', str(path)))
                if validator:
                    status, error = validator, 'grub-script-check rejected the generated configuration'
                else:
                    accepted = layout != 'direct-generic-no-initrd' or (
                        (version or '6.1') == '6.1' and (text == 'linux /vmlinuz-generic\n' or
                        (initrd.endswith('/initrd-6.1.img') and dict(bodies)[text])))
                    status = 0 if accepted else 1
                    error = '' if accepted else 'generated GRUB configuration does not reference the validated direct-generic kernel and required generated initrd'
        assert result == packet(status, status, error), (number, result, status, error)
        expected_trace = b''.join(b''.join(str(v).encode() + b'\0' for v in row) + b'\n' for row in calls)
        assert (work / 'trace').read_bytes() == expected_trace if calls else not (work / 'trace').exists()
        if kind in ('regular', 'empty', 'symlink'):
            assert target.read_text() == ('' if kind == 'empty' else text)
            assert target.stat().st_mode & 0o777 == (0o600 if kind == 'regular' else 0o640)
    return len(cases)


def main():
    with tempfile.TemporaryDirectory(prefix='slack-update-boot-validation-') as temporary:
        root = Path(temporary)
        counts = (version_cases(root), scalar_cases(root), snapshot_cases(root), output_cases(root), grub_cases(root))
    print('Boot artifact validation tests: %d version entries, %d scalar entries, %d snapshot entries, %d output entries, %d GRUB entries, 0 failures' % counts)


if __name__ == '__main__':
    main()
