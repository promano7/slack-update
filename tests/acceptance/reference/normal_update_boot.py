"""Finite boot manifest; no boot configuration evaluation or generation."""
import argparse
import json
import os
from pathlib import Path
import posixpath
import stat
import subprocess
from typing import Optional

from normal_update_protocol import DiagnosticError
from normal_update_metadata import file_record, load_policy, require, write_json

GRUB_ROOTS = ['/boot', '/etc/default/grub', '/etc/default/grub.d', '/etc/grub.d',
              '/etc/default/geninitrd', '/etc/mkinitrd.conf']
ELILO_ROOTS = ['/boot', '/etc/elilo.conf']


def read_mounts():
    process = subprocess.run(['findmnt','-J','-o','TARGET,SOURCE,FSTYPE'], stdin=subprocess.DEVNULL,
                             capture_output=True, timeout=30, check=True)
    mounts = {}
    def visit(item):
        require(item['target'] not in mounts, 'ambiguous-mount-target')
        mounts[item['target']] = {'source':item['source'], 'fstype':item['fstype']}
        for child in item.get('children', []):
            visit(child)
    for item in json.loads(process.stdout)['filesystems']:
        visit(item)
    return mounts


def capture_boot(policy: dict, fs_root: Path = Path('/'), mounts: Optional[dict] = None) -> dict:
    fs_root = Path(fs_root)
    profile = policy['boot_profile']
    require((policy['target'],profile) in [('slackware-current','current-grub'),('slackware-15.0','slackware15-elilo')], 'unsupported-boot-layout')
    roots = list(GRUB_ROOTS if profile == 'current-grub' else ELILO_ROOTS)
    extras = policy['extra_boot_files']
    roots += extras
    def physical(logical):return fs_root/logical.lstrip('/')
    def covered(logical):return any(logical == root or logical.startswith(root.rstrip('/')+'/') for root in roots)
    try:
        require(physical('/boot').is_dir() and not physical('/boot').is_symlink(), 'missing-boot-root')
        require(all(physical(path).is_file() for path in extras), 'extra-boot-path-must-be-file')
        mounts = read_mounts() if mounts is None else mounts
        required = policy['required_mounts']
        require('/' in required, 'missing-root-mount-policy')
        for dest,record in required.items():
            require(mounts.get(dest) == record, 'required-boot-mount-mismatch')
        # Include containing mounts of roots/files, not just descendants walked.
        observed = {dest:rec for dest,rec in mounts.items() if covered(dest) or
                    any(root == dest or root.startswith(dest.rstrip('/')+'/') for root in roots)}
        require(all(dest in required for dest in observed), 'undeclared-boot-mount')
        entries = {}
        def resolve_link(logical):
            chain = []
            seen = set()
            current = logical
            for _ in range(64):
                require(current not in seen, 'cyclic-boot-link');seen.add(current)
                parts = Path(current).parts[1:]
                found = False
                for index in range(len(parts)):
                    probe = '/'+'/'.join(parts[:index+1])
                    info = physical(probe).lstat()
                    if stat.S_ISLNK(info.st_mode):
                        require(covered(probe), 'undeclared-external-boot-link')
                        target = os.readlink(physical(probe))
                        chain.append(dict(path=probe,target=target,mode=stat.S_IMODE(info.st_mode),uid=info.st_uid,gid=info.st_gid))
                        base = target if target.startswith('/') else posixpath.join(posixpath.dirname(probe),target)
                        current = posixpath.normpath(posixpath.join(base,*parts[index+1:]))
                        require(covered(current), 'undeclared-external-boot-target')
                        found = True
                        break
                if not found:
                    require(physical(current).is_file() and not physical(current).is_symlink(), 'unsupported-directory-boot-link')
                    return current, chain
            raise DiagnosticError('boot-link-depth-exceeded')
        def visit(logical):
            if logical in entries:return
            path = physical(logical)
            try:
                info = path.lstat()
            except FileNotFoundError:
                require(logical not in extras, 'missing-declared-boot-file')
                entries[logical] = {'type':'missing'}
                return
            common = {'mode':stat.S_IMODE(info.st_mode),'uid':info.st_uid,'gid':info.st_gid}
            if stat.S_ISLNK(info.st_mode):
                final,chain = resolve_link(logical)
                value = dict(common,type='symlink',target=os.readlink(path),resolved=final,chain=chain,content=file_record(physical(final)))
                after = path.lstat()
                require((info.st_dev,info.st_ino,info.st_mtime_ns,info.st_ctime_ns) == (after.st_dev,after.st_ino,after.st_mtime_ns,after.st_ctime_ns)
                        and value['target'] == os.readlink(path), 'boot-link-drift')
                entries[logical] = value
                visit(final)
            elif stat.S_ISREG(info.st_mode):
                entries[logical] = file_record(path)
            elif stat.S_ISDIR(info.st_mode):
                entries[logical] = dict(common,type='directory')
                names = sorted(p.name for p in path.iterdir())
                for name in names:visit(logical.rstrip('/')+'/'+name)
                require(names == sorted(p.name for p in path.iterdir()), 'boot-membership-drift')
            else:
                raise DiagnosticError('unsupported-boot-object')
        for root in roots:visit(root)
        # Keep the legacy absence explicit in the extended manifest.
        if '/boot/initrd.gz' not in entries:visit('/boot/initrd.gz')
        if profile == 'current-grub':
            require(entries.get('/boot/grub/grub.cfg',{}).get('type') in ('regular','symlink'), 'unsupported-boot-layout')
        else:
            # Require an actual ELILO config, not merely a declared profile name.
            configs = [name for name,rec in entries.items() if name.endswith('/elilo.conf') and rec['type'] in ('regular','symlink')]
            require(configs, 'unsupported-boot-layout')
        return {'schema':1,'profile':profile,'required_mounts':required,'observed_mounts':observed,'entries':entries,'errors':[],
                'scope':'declared boot manifest only; no active menu, recovery or whole-host proof'}
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError, KeyError, TypeError) as exc:
        raise DiagnosticError('boot-capture-incomplete') from exc


def compare_boot(before: dict, after: dict) -> bool:
    return before.get('schema') == after.get('schema') == 1 and before.get('errors') == after.get('errors') == [] and before == after


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--policy',required=True)
    parser.add_argument('--output',required=True)
    args = parser.parse_args()
    try:
        result = capture_boot(load_policy(Path(args.policy)))
        write_json(args.output,result)
        return 0
    except (DiagnosticError,OSError,subprocess.SubprocessError) as exc:
        print(json.dumps({'valid':False,'reason':str(exc)}),file=__import__('sys').stderr)
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
