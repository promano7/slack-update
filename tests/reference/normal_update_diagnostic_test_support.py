"""Test-only private filesystem bridge. Never installed, never a production mode."""
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

HELPERS = Path(__file__).resolve().parents[1]/'acceptance/reference'
sys.path.insert(0,str(HELPERS))
import normal_update_metadata as m
import normal_update_boot as b
from normal_update_protocol import validate_probe_files

FIXTURES = Path(__file__).resolve().parents[1]/'fixtures/reference/acceptance/normal-update/diagnostic'
FPR = 'EC5649DA401E22ABFA6736EF6A4463C040102233'
NAME = 'kernel-headers-7.2.15-x86-1.txz'


def prepare(root,scenario):
    fs=root/'fs';fs.mkdir(parents=True)
    tools={}
    for logical in ['/usr/sbin/slackpkg','/usr/libexec/slackpkg/pkglist.awk','/usr/libexec/slackpkg/functions.d/dialog-functions.sh']:
        p=fs/logical.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True)
        p.write_bytes((FIXTURES/'metadata/pkglist.awk').read_bytes() if logical.endswith('pkglist.awk') else b'fixture-only; not executable backend\n')
        p.chmod(0o755);tools[logical]=m.digest(p)
    conf=fs/'etc/slackpkg';conf.mkdir(parents=True)
    (fs/'etc/slackware-version').write_text('Slackware 15.0+\n')
    (conf/'slackpkg.conf').write_text('WORKDIR=/var/lib/slackpkg\n')
    (conf/'mirrors').write_text('https://fixture.invalid/tree/\n');(conf/'blacklist').write_text('')
    remote=root/'remote';remote.mkdir()
    for name in ['CHECKSUMS.md5','FILELIST.TXT']:
        with gzip.open(FIXTURES/'metadata'/(name+'.gz'),'rb') as stream:data=stream.read(64*1024*1024+1)
        assert len(data)<=64*1024*1024
        (remote/name).write_bytes(data)
    shutil.copyfile(FIXTURES/'metadata/CHECKSUMS.md5.asc',remote/'CHECKSUMS.md5.asc')
    work=fs/'var/lib/slackpkg';work.mkdir(parents=True)
    for p in remote.iterdir():shutil.copyfile(p,work/p.name)
    filtered=b''.join(line+b'\n' for line in (work/'CHECKSUMS.md5').read_bytes().splitlines() if __import__('re').search(rb'\.t[blxg]z$',line))
    data=subprocess.run(['awk','-f',str(fs/'usr/libexec/slackpkg/pkglist.awk')],input=filtered,capture_output=True,check=True).stdout
    (work/'pkglist').write_bytes(data)
    if scenario=='catalog-stale':(work/'pkglist').write_bytes(b'stale index\n')
    (work/'LASTUPDATE').write_text('1793573177\n')
    pkgs=fs/'var/log/packages';pkgs.mkdir(parents=True);(pkgs/'fixture-1.0-x86_64-1').write_text('fixture package record\n')
    for name,data in [('boot/grub/grub.cfg',b'menu'),('boot/grub/grubenv',b'env'),('boot/initrd-6.18.45.img',b'initrd'),('boot/vmlinuz-6.18.45',b'kernel'),('boot/efi/EFI/Slackware/grubx64.efi',b'efi')]:
        p=fs/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    (fs/'boot/initrd-generic.img').symlink_to('initrd-6.18.45.img')
    mounts={'/':{'source':'fixture-root','fstype':'ext4'},'/boot/efi':{'source':'fixture-efi','fstype':'vfat'}}
    profile={'slackpkg-15.0.10-count-v1':dict(backend_sha256=tools,executable_extensions=['dialog-functions.sh'],pkglist_awk='/usr/libexec/slackpkg/pkglist.awk',workdir='/var/lib/slackpkg')}
    m.write_json(root/'profiles.json',profile)
    key=(FIXTURES/'metadata/slackware.gpg').resolve()
    policy=dict(schema=1,target='slackware-current',hostname='fixture-host',boot_id='fixture-boot',backend_profile='slackpkg-15.0.10-count-v1',backend_sha256=tools,
                configuration_sha256={'/etc/slackpkg/'+p.name:m.digest(p) for p in conf.iterdir()},mirror='https://fixture.invalid/tree/',public_keyring=str(key),public_keyring_sha256=m.digest(key),
                primary_fingerprint=FPR,boot_profile='current-grub',required_mounts=mounts,extra_boot_files=[])
    m.write_json(root/'policy.json',policy)
    (root/'scenario').write_text(scenario)


def perform(root,operation,args):
    m.SYSTEM_ROOT=root/'fs'
    m.host_identity=lambda:('fixture-host','fixture-boot')
    policy=m.load_policy(root/'policy.json',root/'profiles.json')
    scenario=(root/'scenario').read_text()
    if operation=='policy':
        m.write_json(args[1],dict(lastupdate_before=policy['_lastupdate_before'],selection=m.capture_selection(policy)))
    elif operation=='baseline':m.establish_baseline(policy,Path(args[1]),Path(args[2]))
    elif operation=='selection':m.write_json(args[1],m.capture_selection(policy))
    elif operation=='packages':m.write_json(args[1],m.snapshot_tree(root/'fs/var/log/packages'))
    elif operation=='boot':m.write_json(args[1],b.capture_boot(policy,root/'fs',policy['required_mounts']))
    elif operation=='catalog':
        def fetch(url,dst):
            shutil.copyfile(root/'remote'/url.rsplit('/',1)[-1],dst)
            return dict(bytes=Path(dst).stat().st_size,sha256=m.digest(dst),effective_url=url)
        m.fetch_https=fetch
        m.validate_catalog(policy,json.loads(Path(args[1]).read_text()),Path(args[2]))
        if scenario=='post-catalog-drift':(root/'fs/var/lib/slackpkg/pkglist').write_text('changed AFTER catalog validation\n')
    elif operation=='probe':
        names=validate_probe_files(args[0],Path(args[1]),json.loads(Path(args[2]).read_text()))
        Path(args[3]+'.candidates.txt').write_text(''.join(n+'\n' for n in names))
    elif operation=='command':
        action,prefix=args
        with (root/'trace').open('a') as stream:stream.write(action+'\n')
        raw=0;out=b'fixture refresh\n';err=b''
        if action!='update':
            empty=action=='install-new' or scenario in ['both-empty','ghost']
            verb='install' if action=='install-new' else 'upgrade'
            search='NEW packages to install' if action=='install-new' else 'packages to upgrade'
            out=('Looking for '+search+'. Please wait... DONE\n\n').encode()
            if empty:
                raw=20;other='upgrade|reinstall' if verb=='install' else 'install|reinstall'
                out+=('No packages match the pattern for '+verb+'. Try:\n\n\t/usr/sbin/slackpkg '+other+' \n\n').encode()
            else:out+=(NAME+'\n\nTotal package(s): 1\n\nDo you wish to '+verb+' selected packages (Y/n)? n\n\n').encode()
            if scenario in ['ghost','ghost-and-upgrade']:err=b'/fixture/ghost-1.0-x86_64-1.txz\n'
            if scenario=='index-drift' and action=='install-new':(root/'fs/var/lib/slackpkg/pkglist').write_text('changed after probe\n')
        Path(prefix+'.stdout').write_bytes(out);Path(prefix+'.stderr').write_bytes(err);Path(prefix+'.exit').write_text(str(raw)+'\n')
        channels={ch:dict(bytes=len(data),sha256=hashlib.sha256(data).hexdigest()) for ch,data in [('stdout',out),('stderr',err)]}
        m.write_json(prefix+'.capture.json',dict(raw_status=raw,error=None,capture_complete=True,**channels))
        return raw
    else:raise ValueError('unknown test-only operation')
    return 0

if __name__=='__main__':
    root=Path(sys.argv[1]);operation=sys.argv[2]
    if operation=='prepare':prepare(root,sys.argv[3]);raise SystemExit(0)
    raise SystemExit(perform(root,operation,sys.argv[3:]))
