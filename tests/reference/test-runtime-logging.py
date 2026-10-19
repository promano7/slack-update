#!/usr/bin/env python3
"""Characterize private runtime setup, log routing and finite log rotation."""
from pathlib import Path
import itertools
import os
import re
import shlex
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('WORKDIR', 'LOGDIR', 'DATE', 'LOG', 'RUNTIME_TMPDIR', 'BROKEN',
          'QUEUE_CORE', 'QUEUE_EXTRA', 'SBO_OPTION_RECORDS', 'SBO_GENERATED_QUEUE_DIR',
          'BEFORE_PKGS', 'AFTER_PKGS', 'PENDING_NEW_CONFIG_FILES', 'QUEUE_FINAL',
          'BROKEN_NEW', 'STILL_BROKEN', 'BROKEN_ERRORS', 'ELF_LIBRARY_CACHE',
          'ABI_CANDIDATES', 'CSB_DIR')
COMMON = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/trace"; builtin printf '\n' >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$*" >&2; exit 97; }
main() { forbidden main; }
cleanup() { forbidden cleanup; }
slackpkg() { forbidden slackpkg; }
sbopkg() { forbidden sbopkg; }
mkinitrd() { forbidden mkinitrd; }
grub-mkconfig() { forbidden grub; }
curl() { forbidden curl; }
git() { forbidden git; }
'''
SETUP = r'''
initialize_runtime_state() {
    record state
    [[ $FAULT != state ]] || return 43
    RUNTIME_TMPDIR=
}
mkdir() {
    record mkdir "$@"
    [[ $FAULT != mkdir ]] || return 43
    builtin command mkdir "$@"
}
date() {
    record date "$@"
    [[ $FAULT != date ]] || return 43
    builtin printf '2030-02-03-040506\n'
}
mktemp() {
    local count=0
    [[ ! -f "$TEST_ROOT/count" ]] || read -r count < "$TEST_ROOT/count"
    count=$((count + 1))
    builtin printf '%s\n' "$count" > "$TEST_ROOT/count"
    record mktemp "$@"
    [[ $FAULT != "temp$count" ]] || return 43
    if [[ $# == 0 ]]; then
        : > "$TEST_ROOT/temp-$count"
        builtin printf '%s\n' "$TEST_ROOT/temp-$count"
    elif [[ $# == 2 && $1 == -d && $2 == /tmp/slack-update-dry-run.XXXXXX ]]; then
        builtin command mkdir -- "$TEST_ROOT/private-dry"
        builtin printf '%s\n' "$TEST_ROOT/private-dry"
    else
        forbidden mktemp-vector
    fi
}
'''


def quote(value):
    return shlex.quote(str(value))


def execute(root, body):
    env = dict(os.environ, LC_ALL='C')
    proc = subprocess.Popen(['bash', '-c', COMMON + body, 'runtime-test',
                             str(REFERENCE), str(root)], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, env=env)
    out, err = proc.communicate(timeout=15)
    assert proc.returncode == 0, (proc.returncode, out, err)
    return proc.pid, out, err


def trace(root):
    path = root / 'trace'
    return [tuple(part.decode() for part in row.split(b'\0')[:-1])
            for row in path.read_bytes().split(b'\n') if row] if path.exists() else []


def setup_case(root, dry, fault, existing):
    work, log = root / 'configured-work', root / 'logs'
    if existing:
        work.mkdir()
        log.mkdir()
        (work / 'keep').write_bytes(b'old work\n')
        (log / 'keep').write_bytes(b'old log\n')
    expected = {name: 'seed-' + name for name in FIELDS}
    body = SETUP + '\n' + '\n'.join(name + '=' + quote(value) for name, value in expected.items())
    body += '\nWORKDIR_CONFIG=' + quote(work) + '\nLOGDIR_CONFIG=' + quote(log)
    body += '\nCSB_DIR_CONFIG=' + quote(root / 'csb') + '\nFAULT=' + quote(fault)
    body += '\n' + ('initialize_dry_run_runtime' if dry else 'initialize_runtime')
    body += '\nstatus=$?\nbuiltin printf "%s\\0" "$status"' + ''.join(' "$' + name + '"' for name in FIELDS) + '\n'
    pid, out, err = execute(root, body)
    calls = [('state',)]
    expected_err = b''
    status = 0
    if fault == 'state':
        status = 1
    else:
        expected['RUNTIME_TMPDIR'] = ''
        expected['LOGDIR'] = str(log)
        if not dry:
            expected['WORKDIR'] = str(work)
        calls.append(('mkdir', '-p', str(log)) if dry else ('mkdir', '-p', str(work), str(log)))
        if fault == 'mkdir':
            status = 1
            expected_err = ('Error: cannot create the dry-run log directory: ' + str(log) if dry else
                            'Error: cannot create runtime directories: ' + str(work) + ', ' + str(log)).encode() + b'\n'
        else:
            calls.append(('date', '+%F-%H%M%S'))
            expected['DATE'] = '' if fault == 'date' else '2030-02-03-040506'
            if fault == 'date':
                status = 1
                expected_err = ('Error: cannot create the ' + ('dry-run' if dry else 'runtime') + ' timestamp\n').encode()
            else:
                expected['LOG'] = str(log / 'run-2030-02-03-040506.log')
                if dry:
                    calls.append(('mktemp', '-d', '/tmp/slack-update-dry-run.XXXXXX'))
                    if fault == 'temp1':
                        status = 1
                        expected_err = b'Error: cannot create the private dry-run workspace\n'
                    else:
                        work = root / 'private-dry'
                        expected.update(WORKDIR=str(work), RUNTIME_TMPDIR=str(work))
                if not status:
                    leaves = dict(BROKEN='broken.txt', QUEUE_CORE='queue-core.sqf',
                                  QUEUE_EXTRA='queue-extra.sqf', SBO_OPTION_RECORDS='sbo-options.normalized',
                                  BEFORE_PKGS='packages.before', AFTER_PKGS='packages.after',
                                  PENDING_NEW_CONFIG_FILES='slackware-new-config-files.txt')
                    expected.update({name: str(work / leaf) for name, leaf in leaves.items()})
                    expected['SBO_GENERATED_QUEUE_DIR'] = str(work / ('sbo-generated-queues' if dry else
                                                                   '.sbo-generated-2030-02-03-040506-' + str(pid)))
                    if dry:
                        expected.update({name: str(work / leaf) for name, leaf in dict(
                            QUEUE_FINAL='queue-final.sqf', BROKEN_NEW='broken-new.txt',
                            STILL_BROKEN='still-broken.txt', BROKEN_ERRORS='broken-errors.txt',
                            ELF_LIBRARY_CACHE='elf-library-cache.txt', ABI_CANDIDATES='abi-rebuild-candidates.txt').items()})
                    else:
                        messages = ('final queue', 'broken-object scan', 'broken-object verification',
                                    'broken-object diagnostics', 'ELF library-cache')
                        for number, name in enumerate(('QUEUE_FINAL', 'BROKEN_NEW', 'STILL_BROKEN',
                                                       'BROKEN_ERRORS', 'ELF_LIBRARY_CACHE'), 1):
                            calls.append(('mktemp',))
                            expected[name] = '' if fault == 'temp' + str(number) else str(root / ('temp-' + str(number)))
                            if fault == 'temp' + str(number):
                                status = 1
                                expected_err = ('Error: cannot create the ' + messages[number - 1] + ' temporary file\n').encode()
                                break
                    if not status:
                        expected['CSB_DIR'] = str(root / 'csb')
    assert out == b'\0'.join([str(status).encode()] + [expected[name].encode() for name in FIELDS]) + b'\0', (dry, fault, out, expected)
    assert err == expected_err, (dry, fault, err, expected_err)
    assert trace(root) == calls, (trace(root), calls)
    files = {str(p.relative_to(root)): p.read_bytes() for p in root.rglob('*') if p.is_file() and p.name not in ('trace', 'count')}
    expected_files = {'configured-work/keep': b'old work\n', 'logs/keep': b'old log\n'} if existing else {}
    if dry and status == 0:
        expected_files.update({'private-dry/' + leaf: b'' for leaf in
                               ('broken.txt', 'queue-core.sqf', 'queue-extra.sqf', 'sbo-options.normalized',
                                'broken-errors.txt', 'elf-library-cache.txt')})
    elif not dry:
        count = len([call for call in calls if call[0] == 'mktemp'])
        expected_files.update({'temp-' + str(n): b'' for n in range(1, count + 1) if fault != 'temp' + str(n)})
    assert files == expected_files, (files, expected_files)
    assert log.exists() == (existing or fault not in ('state', 'mkdir'))
    assert (root / 'configured-work').exists() == (existing or not dry and fault not in ('state', 'mkdir'))


def logging_case(root, json_mode, events, prefix, payload, missing=''):
    logfile = root / 'run.log'
    if prefix:
        logfile.write_bytes(prefix)
    body = '\nLOG=' + quote(logfile) + '\nJSON_OUTPUT=' + str(json_mode) + '\nEVENTS_OUTPUT=' + str(events)
    body += '\nMISSING=' + quote(missing) + r'''
command() {
    if [[ $# == 2 && $1 == -v ]]; then
        record discover "$2"
        [[ $2 != "$MISSING" ]] || return 1
        builtin command -v "$2"
    else
        forbidden command-vector
    fi
}
exec 4>&1
exec 3> "$TEST_ROOT/descriptor3"
configure_logging
status=$?
if [[ $status == 0 ]]; then logger_pid=$!; fi
'''
    if not missing:
        body += '\nbuiltin printf %s ' + quote(payload.decode()) + '\nbuiltin printf "err\\n" >&2\nbuiltin printf "MACHINE\\n" >&3\n'
        body += 'exec 1>&- 2>&-\nwait "$logger_pid"\n'
    body += '\nbuiltin printf "STATUS=%s\\n" "$status" >&4\n'
    _, out, err = execute(root, body)
    discovery = [('discover', 'sed')] + ([] if missing == 'sed' else [('discover', 'tee')])
    assert trace(root) == discovery, trace(root)
    if missing:
        assert out == b'STATUS=1\n' and err == ('Error: required logging command is unavailable: ' + missing + '\n').encode(), (out, err)
        assert logfile.exists() == bool(prefix), logfile
        assert (logfile.read_bytes() if logfile.exists() else b'') == prefix
        assert (root / 'descriptor3').read_bytes() == b''
    else:
        # Authored expected bytes: sed removes supported ANSI and the first CR per line;
        # UTF-8 and unsupported ANSI remain. Both console and log receive the filter.
        expected = {b'plain\n': b'plain\n', b'\x1b[31mred\x1b[0m\r\n': b'red\n',
                    '✓\rX\rY\x1b[2A\n'.encode(): '✓X\rY\x1b[2A\n'.encode()}[payload] + b'err\n'
        structured = json_mode == 1 or events == 1
        # fd4 status and fd3 machine output are emitted by the same shell in order.
        assert out == (b'MACHINE\nSTATUS=0\n' if structured else expected + b'STATUS=0\n'), (out, expected)
        assert err == (expected if structured else b''), err
        assert logfile.read_bytes() == prefix + expected
        assert (root / 'descriptor3').read_bytes() == (b'' if structured else b'MACHINE\n')


def logging_failure_case(root, json_mode, events, profile, prefix=b''):
    """Exercise existing open/descriptor guards with real private failures."""
    logfile = root / 'run.log'
    if profile == 'directory':
        logfile.mkdir()
    elif profile == 'link-directory':
        target = root / 'log-target'
        target.mkdir()
        logfile.symlink_to(target)
    elif profile == 'missing-parent':
        logfile = root / 'missing/run.log'
    elif profile == 'closed-stdout':
        if prefix:
            logfile.write_bytes(prefix)
    else:
        raise AssertionError('unexpected failure profile')

    def snapshot():
        return {str(path.relative_to(root)): ('link', os.readlink(path)) if path.is_symlink()
                else ('dir',) if path.is_dir() else ('file', path.read_bytes())
                for path in root.rglob('*') if path.name != 'trace'}

    expected = snapshot()
    expected['descriptor3'] = ('file', b'FD3\n')
    if profile == 'closed-stdout':
        expected['run.log'] = ('file', prefix)
    body = '\nLOG=' + quote(logfile) + '\nJSON_OUTPUT=' + str(json_mode) + '\nEVENTS_OUTPUT=' + str(events)
    body += r'''
command() {
    [[ $# == 2 && $1 == -v && ( $2 == sed || $2 == tee ) ]] || forbidden command-vector
    record discover "$2"
    builtin command -v "$2"
}
exec 4>&1
exec 3> "$TEST_ROOT/descriptor3"
'''
    if profile == 'closed-stdout':
        assert json_mode == 1 or events == 1
        body += 'exec 1>&-\n'
    body += r'''
configure_logging
status=$?
if [[ $status == 0 ]]; then
    logger_pid=${!:-}
    exec 1>&- 2>&-
    if [[ -n $logger_pid ]]; then wait "$logger_pid"; fi
fi
builtin printf 'FD3\n' >&3
builtin printf 'STATUS=%s\n' "$status" >&4
'''
    _, out, err = execute(root, body)
    assert out == b'STATUS=1\n', (profile, out)
    if profile == 'closed-stdout':
        shell_error = '1: Bad file descriptor\n'
        message = 'Error: cannot reserve the machine-readable output descriptor\n'
    else:
        shell_error = str(logfile) + (': No such file or directory\n' if profile == 'missing-parent' else ': Is a directory\n')
        message = 'Error: cannot open the runtime log for writing: ' + str(logfile) + '\n'
    pattern = re.escape(str(REFERENCE)) + r': line [1-9][0-9]*: ' + re.escape(shell_error + message)
    assert re.fullmatch(pattern, err.decode()), (profile, err, pattern)
    assert trace(root) == [('discover', 'sed'), ('discover', 'tee')], trace(root)
    assert snapshot() == expected, (profile, snapshot(), expected)


def rotation_case(root, days, fault):
    log = root / 'logs'
    (log / 'nested').mkdir(parents=True)
    protected = root / 'protected'
    protected.write_bytes(b'protected\n')
    now = time.time()
    for leaf, age in [('run-old.log', days + 2.25), ('run-edge.log', days + .25),
                      ('run-young.log', 0), ('other.log', days + 2.25), ('nested/run-deep.log', days + 2.25)]:
        path = log / leaf
        path.write_bytes(leaf.encode())
        os.utime(path, (now - age * 86400,) * 2)
    directory = log / 'run-empty.log'
    directory.mkdir()
    os.utime(directory, (now - (days + 2.25) * 86400,) * 2)
    link = log / 'run-link.log'
    link.symlink_to(protected)
    os.utime(link, (now - (days + 2.25) * 86400,) * 2, follow_symlinks=False)
    before = sorted(str(p.relative_to(log)) for p in log.rglob('*'))
    body = '\nLOGDIR=' + quote(log) + '\nLOG_RETENTION_DAYS=' + str(days) + '\nFAULT=' + str(fault) + r'''
find() {
    record find "$@"
    [[ $FAULT == 0 ]] || return 43
    builtin command find "$@"
}
rotate_logs
builtin printf '%s\n' "$?"
'''
    _, out, err = execute(root, body)
    assert out == b'0\n' and err == b'', (out, err)
    assert trace(root) == [('find', str(log), '-name', 'run-*.log', '-mtime', '+' + str(days), '-delete')]
    after = sorted(str(p.relative_to(log)) for p in log.rglob('*'))
    assert after == (before if fault else ['nested', 'other.log', 'run-edge.log', 'run-young.log']), after
    assert protected.read_bytes() == b'protected\n'


def main():
    counts = [0, 0, 0]
    with tempfile.TemporaryDirectory(prefix='slack-update-runtime-test-') as temporary:
        root = Path(temporary)
        for dry in (False, True):
            faults = ('none', 'state', 'mkdir', 'date', 'temp1') + (() if dry else ('temp2', 'temp3', 'temp4', 'temp5'))
            for fault, existing in itertools.product(faults, (False, True)):
                case = root / ('setup-' + str(counts[0])); case.mkdir()
                setup_case(case, dry, fault, existing); counts[0] += 1
        for json_mode, events, prefix, payload in itertools.product((0, 1), (0, 1), (b'', b'old\n'),
                (b'plain\n', b'\x1b[31mred\x1b[0m\r\n', '✓\rX\rY\x1b[2A\n'.encode())):
            case = root / ('logging-' + str(counts[1])); case.mkdir()
            logging_case(case, json_mode, events, prefix, payload); counts[1] += 1
        for missing in ('sed', 'tee'):
            for prefix in (b'', b'old\n'):
                case = root / ('logging-' + str(counts[1])); case.mkdir()
                logging_case(case, 0, 0, prefix, b'plain\n', missing); counts[1] += 1
        for json_mode, events, profile in itertools.product((0, 1), (0, 1), ('directory', 'link-directory', 'missing-parent')):
            case = root / ('logging-' + str(counts[1])); case.mkdir()
            logging_failure_case(case, json_mode, events, profile); counts[1] += 1
        for (json_mode, events), prefix in itertools.product(((1, 0), (0, 1), (1, 1)), (b'', b'old\n')):
            case = root / ('logging-' + str(counts[1])); case.mkdir()
            logging_failure_case(case, json_mode, events, 'closed-stdout', prefix); counts[1] += 1
        for days, fault in itertools.product((0, 1, 30), (0, 43)):
            case = root / ('rotation-' + str(counts[2])); case.mkdir()
            rotation_case(case, days, fault); counts[2] += 1
    print('Runtime/logging tests: %d setup entries, %d logging entries, %d rotation entries, 0 failures' % tuple(counts))


if __name__ == '__main__':
    main()
