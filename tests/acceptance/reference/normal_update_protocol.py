"""Candidate protocol for the explicitly pinned slackpkg count-list profile."""
import argparse
import hashlib
import json
from pathlib import Path
import re

class DiagnosticError(Exception):
    def __init__(self, reason: str):
        self.reason = reason
        super().__init__(reason)


def read_json(path):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise DiagnosticError('duplicate-json-key')
            result[key] = value
        return result
    try:
        return json.loads(Path(path).read_text(encoding='utf-8'), object_pairs_hook=pairs,
                          parse_constant=lambda _: (_ for _ in ()).throw(DiagnosticError('invalid-json-number')))
    except (OSError, ValueError, UnicodeError) as exc:
        raise DiagnosticError('invalid-json-input') from exc


FILENAME = re.compile(r'(?P<name>[A-Za-z0-9][A-Za-z0-9+._-]*)-(?P<version>[^\s/-]+)-(?P<arch>x86_64|x86|noarch|fw|i[3-6]86|aarch64|arm[^\s/-]*)-(?P<build>[^\s/]+)\.(?P<extension>txz|tgz|tbz|tlz)')


def parse_probe(action: str, stdout: bytes, raw: int, catalog: dict) -> list:
    if action not in ('install-new', 'upgrade-all') or raw not in (0, 20):
        raise DiagnosticError('invalid-probe-status-or-action')
    if catalog.get('profile') != 'slackpkg-15.0.10-count-v1':
        raise DiagnosticError('unsupported-probe-profile')
    try:
        lines = [line.strip() for line in stdout.decode('utf-8', errors='strict').splitlines()]
    except UnicodeError as exc:
        raise DiagnosticError('invalid-probe-encoding') from exc
    lines = [line for line in lines if line]
    if lines and lines[0] == 'Checking local integrity... DONE':
        lines.pop(0)
    verb = 'install' if action == 'install-new' else 'upgrade'
    search = 'NEW packages to install' if action == 'install-new' else 'packages to upgrade'
    heading = 'Looking for ' + search + '. Please wait... DONE'
    if not lines or lines.pop(0) != heading:
        raise DiagnosticError('invalid-probe-heading')
    if raw == 20:
        other = 'upgrade|reinstall' if action == 'install-new' else 'install|reinstall'
        expected = ['No packages match the pattern for ' + verb + '. Try:', '/usr/sbin/slackpkg ' + other]
        if lines != expected:
            raise DiagnosticError('incoherent-empty-probe')
        return []
    prompt = 'Do you wish to ' + verb + ' selected packages (Y/n)? n'
    if not lines or lines[-1] != prompt:
        raise DiagnosticError('missing-negative-probe-prompt')
    lines.pop()
    if not lines or not re.fullmatch(r'Total package\(s\): [1-9][0-9]*', lines[-1]):
        raise DiagnosticError('missing-probe-counter')
    count = int(lines.pop().split(': ')[1])
    if count != len(lines) or len(set(lines)) != len(lines):
        raise DiagnosticError('probe-count-or-duplicate')
    packages = catalog.get('packages', {})
    for name in lines:
        match = FILENAME.fullmatch(name)
        if not match:
            raise DiagnosticError('invalid-candidate-row')
        records = packages.get(name, [])
        if len(records) != 1:
            raise DiagnosticError('candidate-missing-or-ambiguous')
        record = records[0]
        if record.get('name') != match['name'] or record.get('arch') != match['arch']:
            raise DiagnosticError('candidate-index-incoherent')
    return sorted(lines, key=lambda value: value.encode('utf-8'))


def validate_probe_files(action: str, prefix: Path, catalog: dict) -> list:
    prefix = str(prefix)
    capture = read_json(prefix + '.capture.json')
    try:
        raw = int(Path(prefix + '.exit').read_text().strip())
        if capture.get('error') is not None or capture.get('capture_complete') is not True or capture.get('raw_status') != raw:
            raise DiagnosticError('probe-capture-incomplete')
        channels = {}
        for ch in ('stdout', 'stderr'):
            data = Path(prefix + '.' + ch).read_bytes()
            expected = capture.get(ch, {})
            if expected.get('bytes') != len(data) or expected.get('sha256') != hashlib.sha256(data).hexdigest():
                raise DiagnosticError('probe-channel-drift')
            channels[ch] = data
        return parse_probe(action, channels['stdout'], raw, catalog)
    except (OSError, ValueError) as exc:
        raise DiagnosticError('invalid-probe-capture') from exc


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--action', required=True, choices=('install-new', 'upgrade-all'))
    parser.add_argument('--prefix', required=True)
    parser.add_argument('--catalog', required=True)
    parser.add_argument('--output-prefix', required=True)
    args = parser.parse_args()
    result = {'valid': False}
    status = 1
    try:
        names = validate_probe_files(args.action, Path(args.prefix), read_json(args.catalog))
        # No list is written until all rows/channels have passed.
        with Path(args.output_prefix + '.candidates.txt').open('x') as stream:
            stream.write(''.join(name + '\n' for name in names))
        result = {'valid': True, 'count': len(names), 'diagnostic_only': True}
        status = 0
    except (DiagnosticError, OSError) as exc:
        result['reason'] = str(exc)
    with Path(args.output_prefix + '.validation.json').open('x') as stream:
        json.dump(result, stream, sort_keys=True)
        stream.write('\n')
    return status

if __name__ == '__main__':
    raise SystemExit(main())
