"""Bounded diagnostic command capture. No arbitrary-command CLI."""
import argparse
import hashlib
import re
import socket
import stat
import urllib.request
import urllib.parse
import json
import os
from pathlib import Path
import signal
import subprocess
import time

from normal_update_protocol import DiagnosticError, read_json


def write_json(path, data):
    path = Path(path)
    with path.open('x', encoding='utf-8') as stream:
        json.dump(data, stream, sort_keys=True, indent=2)
        stream.write('\n')


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def group_members(pgid):
    result = []
    for p in Path('/proc').glob('[0-9]*/stat'):
        try:
            fields = p.read_text().rsplit(') ', 1)[1].split()
            if int(fields[2]) == pgid and fields[0] != 'Z':
                result.append(int(p.parent.name))
        except (FileNotFoundError, ProcessLookupError):
            pass
    return sorted(result)


def run_captured(argv: list, prefix: Path, timeout: float) -> dict:
    prefix = Path(prefix)
    paths = {ch: Path(str(prefix) + '.' + ch) for ch in ('stdout', 'stderr', 'exit', 'capture.json')}
    if any(p.exists() or p.is_symlink() for p in paths.values()):
        raise DiagnosticError('capture-output-exists')
    caught = []
    previous = {}
    def interrupted(signum, _frame):
        caught.append(signum)
    for sig in (signal.SIGINT, signal.SIGTERM):
        previous[sig] = signal.signal(sig, interrupted)
    record = dict(argv=argv, error=None, raw_status=None, capture_complete=False,
                  live_after_close=[], pid=None)
    process = None
    try:
        with paths['stdout'].open('xb') as out, paths['stderr'].open('xb') as err:
            try:
                env = dict(os.environ, LC_ALL='C', LANG='C', TERM='dumb')
                process = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=out,
                                           stderr=err, env=env, start_new_session=True)
                record['pid'] = process.pid
                deadline = time.monotonic() + timeout
                while process.poll() is None:
                    if caught:
                        record['error'] = 'signal-' + signal.Signals(caught[0]).name
                        break
                    if time.monotonic() >= deadline:
                        record['error'] = 'timeout'
                        break
                    time.sleep(.01)
                members = group_members(process.pid)
                if members and not record['error']:
                    record['error'] = 'lingering-descendants'
                if members:
                    for sig, seconds in ((signal.SIGTERM, 5), (signal.SIGKILL, 5)):
                        try:
                            os.killpg(process.pid, sig)
                        except ProcessLookupError:
                            pass
                        until = time.monotonic() + seconds
                        while group_members(process.pid) and time.monotonic() < until:
                            process.poll()
                            time.sleep(.01)
                        if not group_members(process.pid):
                            break
                if process.poll() is None:
                    process.wait(timeout=1)
                record['raw_status'] = process.returncode if process.returncode >= 0 else 128 - process.returncode
                record['live_after_close'] = group_members(process.pid)
                record['capture_complete'] = not record['live_after_close']
                if not record['capture_complete']:
                    record['error'] = record['error'] or 'unresolved-process-group'
            except OSError as exc:
                record['error'] = 'command-start-failed'
                record['exception'] = str(exc)
    finally:
        for sig, handler in previous.items():
            signal.signal(sig, handler)
    paths['exit'].write_text(str(record['raw_status'] if record['raw_status'] is not None else 'not-run') + '\n')
    if record['capture_complete']:
        for ch in ('stdout', 'stderr'):
            record[ch] = dict(bytes=paths[ch].stat().st_size, sha256=digest(paths[ch]))
    write_json(paths['capture.json'], record)
    return record


SYSTEM_ROOT = Path('/')
PROFILES = Path(__file__).with_name('normal-update-profiles.json')
POLICY_FIELDS = {'schema', 'target', 'hostname', 'boot_id', 'backend_profile', 'backend_sha256',
                 'configuration_sha256', 'mirror', 'public_keyring', 'public_keyring_sha256',
                 'primary_fingerprint', 'boot_profile', 'required_mounts', 'extra_boot_files'}


def system_path(logical):
    return SYSTEM_ROOT / str(logical).lstrip('/')


def host_identity():
    return socket.gethostname(), Path('/proc/sys/kernel/random/boot_id').read_text().strip()


def require(value, reason):
    if not value:
        raise DiagnosticError(reason)


def https_url(url):
    try:
        parsed = urllib.parse.urlsplit(url)
        require(parsed.scheme == 'https' and parsed.hostname and not parsed.username and not parsed.password and not parsed.fragment,
                'invalid-https-mirror')
        return url
    except ValueError as exc:
        raise DiagnosticError('invalid-https-mirror') from exc


def file_record(path):
    path = Path(path)
    before = path.stat()
    require(stat.S_ISREG(before.st_mode), 'unsupported-file-type')
    value = {'type': 'regular', 'mode': stat.S_IMODE(before.st_mode), 'uid': before.st_uid,
             'gid': before.st_gid, 'bytes': before.st_size, 'sha256': digest(path)}
    after = path.stat()
    require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns) ==
            (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns), 'file-changed-during-capture')
    return value


def snapshot_tree(root, allow_internal_links=False):
    root = Path(root)
    require(root.is_dir() and not root.is_symlink(), 'invalid-snapshot-root')
    entries = {}
    def visit(path):
        info = path.lstat()
        name = '.' if path == root else path.relative_to(root).as_posix()
        base = {'mode': stat.S_IMODE(info.st_mode), 'uid': info.st_uid, 'gid': info.st_gid}
        if stat.S_ISLNK(info.st_mode):
            require(allow_internal_links, 'unexpected-snapshot-link')
            try:
                target = path.resolve(strict=True)
            except (OSError, RuntimeError) as exc:
                raise DiagnosticError('invalid-snapshot-link') from exc
            require(os.path.commonpath([str(target), str(root.resolve())]) == str(root.resolve()), 'external-snapshot-link')
            entries[name] = dict(base, type='symlink', target=os.readlink(path), resolved=str(target), content=file_record(target))
        elif stat.S_ISREG(info.st_mode):
            entries[name] = file_record(path)
        elif stat.S_ISDIR(info.st_mode):
            entries[name] = dict(base, type='directory')
            before = sorted(p.name for p in path.iterdir())
            for child in before:
                visit(path/child)
            require(before == sorted(p.name for p in path.iterdir()), 'snapshot-membership-drift')
        else:
            raise DiagnosticError('unsupported-snapshot-object')
    visit(root)
    return entries


def logical_file_hashes(root, logical):
    entries = snapshot_tree(root)
    return {logical.rstrip('/')+'/'+name: rec['sha256'] for name, rec in entries.items() if rec['type'] == 'regular'}


def load_policy(path: Path, profiles_path: Path = PROFILES) -> dict:
    try:
        policy = read_json(path)
        require(isinstance(policy, dict) and set(policy) == POLICY_FIELDS and type(policy['schema']) is int and policy['schema'] == 1,
                'invalid-policy-schema')
        require(policy['target'] in ('slackware-current', 'slackware-15.0'), 'invalid-policy-target')
        version = system_path('/etc/slackware-version').read_text().strip()
        host_target = 'slackware-15.0' if version == 'Slackware 15.0' else (
            'slackware-current' if version.startswith('Slackware ') and (version.endswith('+') or version.startswith('Slackware current')) else None)
        require(policy['target'] == host_target, 'policy-target-host-mismatch')
        require((policy['hostname'], policy['boot_id']) == host_identity(), 'policy-host-or-boot-mismatch')
        require(policy['boot_profile'] == {'slackware-current':'current-grub','slackware-15.0':'slackware15-elilo'}[policy['target']],
                'unsupported-boot-profile')
        profiles = read_json(profiles_path)
        require(policy['backend_profile'] in profiles, 'unsupported-backend-profile')
        profile = profiles[policy['backend_profile']]
        expected = profile['backend_sha256']
        require(policy['backend_sha256'] == expected, 'backend-policy-profile-mismatch')
        actual = {'/usr/sbin/slackpkg': digest(system_path('/usr/sbin/slackpkg'))}
        for p in system_path('/usr/libexec/slackpkg').rglob('*'):
            require(not p.is_symlink(), 'backend-link-not-supported')
            if p.is_file():
                actual['/'+p.relative_to(SYSTEM_ROOT).as_posix()] = digest(p)
        require(actual == expected, 'backend-identity-drift')
        extensions = sorted(p.name for p in system_path('/usr/libexec/slackpkg/functions.d').iterdir() if os.access(p, os.X_OK) and p.is_file())
        require(extensions == sorted(profile['executable_extensions']), 'backend-extension-drift')
        configuration = logical_file_hashes(system_path('/etc/slackpkg'), '/etc/slackpkg')
        require(configuration == policy['configuration_sha256'], 'configuration-identity-drift')
        config = system_path('/etc/slackpkg/slackpkg.conf').read_text()
        workdirs = re.findall(r'^WORKDIR=([^\n]+)$', config, re.M)
        require(workdirs == [profile['workdir']], 'unsupported-slackpkg-workdir')
        mirrors = [line.strip() for line in system_path('/etc/slackpkg/mirrors').read_text().splitlines()
                   if line.strip() and not line.lstrip().startswith('#')]
        https_url(policy['mirror'])
        require(mirrors == [policy['mirror']], 'mirror-policy-mismatch')
        keyring = Path(policy['public_keyring'])
        require(keyring.is_absolute() and not keyring.is_symlink() and digest(keyring) == policy['public_keyring_sha256'], 'public-keyring-drift')
        require(re.fullmatch('[A-F0-9]{40}', policy['primary_fingerprint']), 'invalid-fingerprint')
        mounts = policy['required_mounts']
        require(isinstance(mounts, dict) and '/' in mounts and mounts, 'missing-required-mounts')
        for dest, record in mounts.items():
            require(isinstance(dest, str) and dest.startswith('/') and '..' not in Path(dest).parts and isinstance(record, dict) and
                    set(record) == {'source','fstype'} and all(isinstance(v,str) and v for v in record.values()), 'invalid-mount-policy')
        require(isinstance(policy['extra_boot_files'], list) and all(isinstance(v,str) and v.startswith('/') and '..' not in Path(v).parts for v in policy['extra_boot_files']), 'invalid-extra-boot-files')
        policy = dict(policy)
        policy['_workdir'] = str(system_path(profile['workdir']))
        policy['_pkglist_awk'] = str(system_path(profile['pkglist_awk']))
        policy['_input_sha256'] = digest(path)
        policy['_lastupdate_before'] = read_lastupdate(Path(policy['_workdir'])/'LASTUPDATE')
        return policy
    except (KeyError, TypeError, OSError, ValueError, RuntimeError) as exc:
        raise DiagnosticError('invalid-policy-input') from exc


def read_lastupdate(path):
    data = Path(path).read_text().strip()
    require(bool(re.fullmatch('[0-9]+', data)), 'invalid-lastupdate')
    return int(data)


def capture_selection(policy: dict) -> dict:
    files = {logical: file_record(system_path(logical)) for logical in policy['backend_sha256']}
    package_path = system_path('/var/log/packages').resolve(strict=True)
    return {'backend': files, 'configuration': snapshot_tree(system_path('/etc/slackpkg')),
            'workdir': snapshot_tree(Path(policy['_workdir']), allow_internal_links=True),
            'package_database_resolved': str(package_path), 'packages': snapshot_tree(package_path)}


def fetch_https(url: str, output: Path) -> dict:
    https_url(url)
    class HTTPSRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            https_url(newurl)
            return super().redirect_request(req, fp, code, msg, headers, newurl)
    record = {'requested_url': url, 'transport':'python-urllib', 'error':None}
    output = Path(output)
    count = 0
    started = time.monotonic()
    try:
        opener = urllib.request.build_opener(HTTPSRedirect())
        with opener.open(url, timeout=10) as response, output.open('xb') as stream:
            record['effective_url'] = https_url(response.geturl())
            record['headers'] = dict(response.headers.items())
            while True:
                require(time.monotonic()-started <= 60, 'fetch-deadline')
                chunk = response.read(65536)
                if not chunk:
                    break
                count += len(chunk)
                require(count <= 64*1024*1024, 'fetch-size-limit')
                stream.write(chunk)
        record.update(bytes=count, sha256=digest(output))
        return record
    except Exception as exc:
        record.update(error=str(exc), bytes=count)
        raise DiagnosticError('catalog-acquisition-failed') from exc
    finally:
        write_json(Path(str(output)+'.fetch.json'), record)


def checked_command(argv, prefix):
    record = run_captured(argv, prefix, 60)
    require(record['error'] is None and record['capture_complete'] and record['raw_status'] == 0, 'catalog-command-failed')
    return Path(str(prefix)+'.stdout').read_bytes()


def validate_catalog(policy: dict, before: dict, evidence: Path) -> dict:
    evidence = Path(evidence)
    work = Path(policy['_workdir'])
    initial = capture_selection(policy)
    protected = before.get('selection', {})
    for domain in ('backend', 'configuration', 'packages', 'package_database_resolved'):
        require(domain in protected and domain in initial and protected[domain] == initial[domain],
                'protected-state-changed-during-refresh')
    acquisitions = []
    total = 0
    for name in ('CHECKSUMS.md5', 'CHECKSUMS.md5.asc', 'FILELIST.TXT'):
        record = fetch_https(policy['mirror'].rstrip('/')+'/'+name, evidence/name)
        acquisitions.append(record)
        total += record['bytes']
        require(total <= 128*1024*1024, 'acquisition-total-limit')
    key = Path(policy['public_keyring'])
    require(digest(key) == policy['public_keyring_sha256'], 'public-keyring-drift')
    home = evidence/'gnupg';home.mkdir(mode=0o700)
    status = checked_command(['gpgv','--homedir',str(home),'--keyring',str(key), '--status-fd','1',
                              str(evidence/'CHECKSUMS.md5.asc'),str(evidence/'CHECKSUMS.md5')], evidence/'signature').decode('ascii', errors='strict')
    valid = [line.split() for line in status.splitlines() if line.startswith('[GNUPG:] VALIDSIG ')]
    bad = ('BADSIG','ERRSIG','REVKEYSIG','EXPKEYSIG','EXPSIG','KEYEXPIRED','SIGEXPIRED')
    require(len(valid) == 1 and valid[0][-1] == policy['primary_fingerprint'] and
            not any('[GNUPG:] '+code+' ' in status for code in bad), 'signature-fingerprint-or-state')
    sums_data = (evidence/'CHECKSUMS.md5').read_bytes()
    require(sums_data == (work/'CHECKSUMS.md5').read_bytes() and
            (evidence/'CHECKSUMS.md5.asc').read_bytes() == (work/'CHECKSUMS.md5.asc').read_bytes(), 'effective-catalog-mismatch')
    sums = {}
    for line in sums_data.decode('utf-8').splitlines():
        fields = line.split()
        if len(fields) == 2 and re.fullmatch('[0-9a-fA-F]{32}',fields[0]):
            name = fields[1].removeprefix('./')
            require(name not in sums, 'duplicate-catalog-checksum')
            sums[name] = fields[0].lower()
    filelist = (evidence/'FILELIST.TXT').read_bytes()
    require(hashlib.md5(filelist).hexdigest() == sums.get('FILELIST.TXT'), 'filelist-checksum-mismatch')
    require(filelist.splitlines(), 'missing-filelist-date')
    date = checked_command(['date','-d',filelist.splitlines()[0].decode('ascii'),'+%s'], evidence/'filelist-date')
    require(re.fullmatch(rb'[0-9]+\n',date), 'invalid-filelist-date')
    timestamp = int(date)
    last = read_lastupdate(work/'LASTUPDATE')
    require(type(before.get('lastupdate_before')) is int and timestamp == last and last >= before['lastupdate_before'], 'catalog-date-incoherent-or-regressed')
    filtered = evidence/'signed-package-lines.txt'
    filtered.write_bytes(b''.join(line+b'\n' for line in sums_data.splitlines() if re.search(rb'\.t[blxg]z$',line)))
    awk = checked_command(['awk','-f',policy['_pkglist_awk'],str(filtered)], evidence/'pkglist-awk')
    rebuilt = b'\n'.join(line[1:] if line.startswith(b'M') else line for line in awk.split(b'\n'))
    (evidence/'regenerated.pkglist').write_bytes(rebuilt)
    require(rebuilt == (work/'pkglist').read_bytes(), 'effective-pkglist-incoherent')
    packages = {}
    for line in rebuilt.decode('utf-8',errors='strict').splitlines():
        f = line.split()
        require(len(f) == 8, 'invalid-pkglist-record')
        repository,name,version,arch,build,stem,path,extension = f
        filename = stem+'.'+extension
        packages.setdefault(filename,[]).append(dict(repository=repository,name=name,version=version,arch=arch,build=build,path=path,extension=extension))
    final = capture_selection(policy)
    require(initial == final, 'selection-drift-during-validation')
    result = dict(schema=1, profile=policy['backend_profile'], primary_fingerprint=policy['primary_fingerprint'],
                  filelist_timestamp=timestamp,lastupdate_before=before['lastupdate_before'],lastupdate_after=last,
                  latest_global_claimed=False,key_provenance_independently_authenticated=False,
                  packages=packages,acquisitions=acquisitions,selection=final)
    write_json(evidence/'catalog.json',result)
    return result


def establish_baseline(policy: dict, catalog_path: Path, output: Path):
    catalog = read_json(catalog_path)
    require(catalog.get('schema') == 1 and catalog.get('profile') == policy['backend_profile'] and
            isinstance(catalog.get('selection'), dict), 'invalid-validated-catalog')
    validated = catalog['selection']
    require(validated == capture_selection(policy), 'selection-drift-after-catalog')
    # Never bless a newly captured state as a replacement for the validated one.
    write_json(output, validated)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--operation',choices=('policy','catalog','selection','baseline'))
    group.add_argument('--backend-action',choices=('update','install-new','upgrade-all'))
    parser.add_argument('--policy',required=True)
    parser.add_argument('--output')
    parser.add_argument('--catalog')
    parser.add_argument('--before')
    parser.add_argument('--evidence')
    parser.add_argument('--prefix')
    args = parser.parse_args()
    try:
        policy = load_policy(Path(args.policy))
        if args.backend_action:
            require(args.prefix, 'missing-prefix')
            argv = ['/usr/sbin/slackpkg','-dialog=off','-batch=on','-default_answer=n','-postinst=off',args.backend_action]
            record = run_captured(argv,Path(args.prefix),600 if args.backend_action == 'update' else 180)
            return record['raw_status'] if record['error'] is None and record['capture_complete'] else 1
        if args.operation == 'policy':
            require(args.output,'missing-policy-output')
            Path(str(args.output)+'.input.json').write_bytes(Path(args.policy).read_bytes())
            write_json(args.output,dict(policy_input_sha256=policy['_input_sha256'],lastupdate_before=policy['_lastupdate_before'],selection=capture_selection(policy)))
        elif args.operation == 'baseline':
            require(args.catalog and args.output,'missing-baseline-input')
            establish_baseline(policy,Path(args.catalog),Path(args.output))
        elif args.operation == 'selection':
            require(args.output,'missing-selection-output')
            write_json(args.output,capture_selection(policy))
        else:
            require(args.before and args.evidence,'missing-catalog-input')
            validate_catalog(policy,read_json(args.before),Path(args.evidence))
        return 0
    except (DiagnosticError, OSError, ValueError, TypeError) as exc:
        print(json.dumps({'valid':False,'reason':str(exc)}),file=__import__('sys').stderr)
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
