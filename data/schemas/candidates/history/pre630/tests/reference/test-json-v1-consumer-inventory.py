#!/usr/bin/env python3
"""Check a bounded source inventory and characterize existing offline consumers."""

import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
INVENTORY = ROOT / 'data/schemas/candidates/consumer-inventory.json'


def discover(root):
    found = set()
    for directory in ('tools', 'tests'):
        for path in (root / directory).rglob('*'):
            if path.suffix not in ('.py', '.sh') or not path.is_file():
                continue
            if path.is_symlink():
                raise ValueError('source symlink requires separate review')
            raw = path.read_bytes()
            if b'schema_version' in raw or b'schema_status' in raw:
                found.add(path.relative_to(root).as_posix())
    return found


def validate_inventory(root, inventory):
    entries = inventory['metadata_references']
    paths = [row['path'] for row in entries]
    if len(set(paths)) != len(paths) or set(paths) != discover(root):
        raise ValueError('metadata reference set drift; review new and removed sources')
    for row in entries + inventory['additional_dependencies']:
        path = root / row['path']
        if hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
            raise ValueError('source inventory drift: ' + row['path'])


def python_validator(path, function):
    # Extract only the existing Python heredoc; never source an acceptance script.
    text = path.read_text()
    body = text.split(function + '() {\n', 1)[1].split('\n}\n', 1)[0]
    assert body.count("<<'PYTHON_EOF'\n") == 1
    return body.split("<<'PYTHON_EOF'\n", 1)[1].split('\nPYTHON_EOF', 1)[0]


def consumer_checks():
    no_updates = python_validator(ROOT / 'tests/acceptance/reference/test-no-updates.sh', 'validate_json_result')
    normal = python_validator(ROOT / 'tests/acceptance/reference/test-normal-update.sh', 'validate_apply_json')
    count = 0
    with tempfile.TemporaryDirectory(prefix='slack-update-consumer-review-') as directory:
        path = Path(directory) / 'supplied.json'
        for operation in ('check', 'apply'):
            fixture = json.loads((ROOT / 'tests/fixtures/reference/acceptance/no-updates' /
                                  (operation + '-result.json')).read_text())
            for version in (0, 1):
                value = copy.deepcopy(fixture)
                if version:
                    value.update(schema_version=1, schema_status='stable')
                path.write_text(json.dumps(value))
                result = subprocess.run([sys.executable, '-c', no_updates, operation,
                                         str(path), value['config_path']], capture_output=True,
                                        timeout=15, check=False)
                assert result.returncode == (1 if version else 0), result
                assert result.stdout == b''
                assert result.stderr == (b'unexpected schema_version\n' if version else b'')
                count += 1
        # This fixture is authored from the original harness's valid non-boot case.
        # It is deliberately a consumer subset, not a complete candidate result.
        value = dict(schema_version=0, operation='apply', success=True, partial=False,
                     boot_safe=True, exit_code=0, reboot='none', config_path='/supplied/config', errors=[],
                     modules=dict(slackware=dict(state='success', update_exit_code=0,
                         install_new_exit_code=0, upgrade_all_exit_code=0, postinstall_policy='defer',
                         postinstall_processing_enabled=False, pending_new_config_files_valid=True,
                         pending_new_config_files_count=0, pending_new_config_files=[],
                         snapshot_before_valid=True, snapshot_after_valid=True,
                         secondary_modules_blocked=False, kernel_changes=True, critical_packages=[]),
                         flatpak=dict(mode='disabled'), sbo=dict(mode='disabled'),
                         elf=dict(mode='disabled'), cinnamon=dict(mode='disabled'),
                         boot=dict(mode='auto', state='not-required', initrd_required=False,
                                   initrd_state='not-required', grub_required=False, grub_state='not-required')))
        for version in (0, 1):
            value['schema_version'] = version
            path.write_text(json.dumps(value))
            result = subprocess.run([sys.executable, '-c', normal, str(path), value['config_path'], '0'],
                                    capture_output=True, timeout=15, check=False)
            assert result.returncode == (1 if version else 0), result
            assert result.stdout == b''
            assert result.stderr == (b'unexpected schema_version\n' if version else b'')
            count += 1
    return count


def main():
    inventory = json.loads(INVENTORY.read_text())
    validate_inventory(ROOT, inventory)
    controls = 0
    for change in ('missing', 'hash', 'duplicate'):
        damaged = copy.deepcopy(inventory)
        if change == 'missing':
            damaged['metadata_references'].pop()
        elif change == 'hash':
            damaged['metadata_references'][0]['sha256'] = '0' * 64
        else:
            damaged['metadata_references'].append(copy.deepcopy(damaged['metadata_references'][0]))
        try:
            validate_inventory(ROOT, damaged)
        except ValueError:
            controls += 1
        else:
            raise AssertionError('inventory negative control accepted')
    consumers = consumer_checks()
    print(f'JSON consumer inventory: {len(inventory["metadata_references"])} metadata source references, '
          f'{controls} inventory rejection controls, {consumers} extracted offline consumer checks; '
          'current v0 accepted / prospective v1 refused; no acceptance workflow')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
