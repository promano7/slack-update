#!/usr/bin/env python3
"""Behavioral regressions. Only private child processes/files, no native backend."""
import importlib
import copy
import gzip
import hashlib
import os
import subprocess
from unittest import mock
import json
from pathlib import Path
import sys
import tempfile
import unittest

HELPERS = Path(__file__).resolve().parents[1] / 'acceptance/reference'
sys.path.insert(0, str(HELPERS))

class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue((HELPERS/'normal_update_metadata.py').exists(), 'missing captured runner')
        self.m = importlib.import_module('normal_update_metadata')
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_channels_and_raw20(self):
        r = self.m.run_captured([sys.executable, '-c', 'import sys;print("out");print("err",file=sys.stderr);sys.exit(20)'], self.root/'probe', 3)
        self.assertEqual(20, r['raw_status'])
        self.assertIsNone(r['error'])
        self.assertEqual(b'out\n', (self.root/'probe.stdout').read_bytes())
        self.assertEqual(b'err\n', (self.root/'probe.stderr').read_bytes())
        self.assertTrue(r['capture_complete'])

    def test_timeout_closes_own_group(self):
        r = self.m.run_captured([sys.executable, '-c', 'import time;time.sleep(30)'], self.root/'timeout', .05)
        self.assertEqual('timeout', r['error'])
        self.assertEqual([], r['live_after_close'])
        self.assertTrue(r['capture_complete'])

    def test_orphan_writer_prevents_success(self):
        code = 'import subprocess,sys;subprocess.Popen([sys.executable,"-c","import time;time.sleep(30)"])'
        r = self.m.run_captured([sys.executable, '-c', code], self.root/'orphan', 3)
        self.assertEqual(0, r['raw_status'])
        self.assertEqual('lingering-descendants', r['error'])
        self.assertEqual([], r['live_after_close'])

    def test_failed_command_preserves_raw_status(self):
        r = self.m.run_captured([sys.executable, '-c', 'raise SystemExit(42)'], self.root/'bad', 3)
        self.assertEqual(42, r['raw_status'])
        self.assertEqual('42\n', (self.root/'bad.exit').read_text())


FIXTURES = Path(__file__).resolve().parents[1]/'fixtures/reference/acceptance/normal-update/diagnostic'
FPR = 'EC5649DA401E22ABFA6736EF6A4463C040102233'
NAME = 'kernel-headers-6.18.45-x86-1.txz'

def candidate_catalog(names=(NAME,)):
    return {'profile':'slackpkg-15.0.10-count-v1','packages':{n:[{'name':n.rsplit('-',3)[0], 'repository':'slackware64','path':'./slackware64/a','arch':n.rsplit('-',2)[1]}] for n in names}}

def listing(names=(NAME,), action='upgrade-all'):
    search = 'NEW packages to install' if action == 'install-new' else 'packages to upgrade'
    verb = 'install' if action == 'install-new' else 'upgrade'
    return ('Looking for '+search+'. Please wait... DONE\n\n'+'\n'.join(names)+'\n\nTotal package(s): '+str(len(names))+'\n\nDo you wish to '+verb+' selected packages (Y/n)? n\n\n').encode()

def empty_listing(action):
    verb = 'install' if action == 'install-new' else 'upgrade'
    other = 'upgrade|reinstall' if verb == 'install' else 'install|reinstall'
    pre = 'Looking for NEW packages to install. Please wait... DONE\n\n' if verb == 'install' else 'Checking local integrity... DONE\nLooking for packages to upgrade. Please wait... DONE\n\n'
    return (pre+'No packages match the pattern for '+verb+'. Try:\n\n\t/usr/sbin/slackpkg '+other+' \n\n').encode()

class ProtocolTests(unittest.TestCase):
    def setUp(self):
        self.p = importlib.import_module('normal_update_protocol')
        self.assertTrue(hasattr(self.p, 'parse_probe'), 'strict parser missing')
    def test_x86_filename_survives(self):
        self.assertEqual([NAME], self.p.parse_probe('upgrade-all', listing(), 0, candidate_catalog()))
    def test_historical_real_counter_layout(self):
        data=(FIXTURES/'install-new-900.stdout').read_bytes()
        names=['bdf2psf-1.249-noarch-1.txz','blake3-1.8.7-x86_64-1.txz','btop-1.4.8-x86_64-1.txz','cpufetch-1.07-x86_64-1.txz','f3-10.0-x86_64-1.txz','fonts-uw-ttyp0-2.1-noarch-2.txz','fwupd-2.1.9-x86_64-1.txz','fwupd-efi-1.9-x86_64-1.txz','highway-1.4.0-x86_64-2.txz','kexec-tools-2.0.32-x86_64-5.txz','kio-snapshot-1.1.0-x86_64-1.txz','kmscon-10.1.0-x86_64-1.txz','kweather-26.08.2-x86_64-1.txz','libgit2-1.9.7-x86_64-1.txz','libjxl-0.12.0-x86_64-4.txz','libtatsu-1.0.5-x86_64-1.txz','libtsm-4.8.0-x86_64-1.txz','libvips-8.18.7-x86_64-1.txz','pdfio-1.6.6-x86_64-1.txz','spleen-2.2.0-noarch-1.txz','xf86-video-cirrus-1.6.0-x86_64-1.txz']
        self.assertEqual(names,self.p.parse_probe('install-new',data,0,candidate_catalog(names)))
    def test_raw20_is_empty_not_diagnostic_package(self):
        for action in ['install-new','upgrade-all']:
            self.assertEqual([], self.p.parse_probe(action,empty_listing(action),20,candidate_catalog()))
    def test_bad_protocols_fail_closed(self):
        data=listing()
        bad=[(data,20),(data.replace(b'Total package(s): 1',b'Total package(s): 2'),0),
             (listing((NAME,NAME)),0),(data.split(b'Do you wish')[0],0),
             (data+data,0),(data.replace(b'? n',b'? y'),0),
             (data.replace(b'wish to upgrade',b'wish to install'),0),
             (NAME.encode()+b'\n'+data,0),(b'No packages selected\n',0),
             (b'\xff'+data,0),(empty_listing('install-new'),20)]
        for output,raw in bad:
            with self.subTest(output=output[:70], raw=raw):
                with self.assertRaises(self.p.DiagnosticError):
                    self.p.parse_probe('upgrade-all',output,raw,candidate_catalog())
    def test_membership_and_ambiguity(self):
        for catalog in [candidate_catalog(()),{'profile':'slackpkg-15.0.10-count-v1','packages':{NAME:[{},{}]}}]:
            with self.assertRaises(self.p.DiagnosticError):
                self.p.parse_probe('upgrade-all',listing(),0,catalog)
    def test_capture_error_and_stderr_never_enter_list(self):
        self.assertTrue(hasattr(self.p,'validate_probe_files'),'capture-bound parser missing')
        with tempfile.TemporaryDirectory() as tmp:
            prefix=Path(tmp)/'probe'
            Path(str(prefix)+'.stdout').write_bytes(empty_listing('install-new'))
            Path(str(prefix)+'.stderr').write_text('/fixture/ghost-1.0-x86_64-1.txz\n')
            Path(str(prefix)+'.exit').write_text('20\n')
            channels={k:{'sha256':hashlib.sha256(Path(str(prefix)+'.'+k).read_bytes()).hexdigest(),'bytes':Path(str(prefix)+'.'+k).stat().st_size} for k in ['stdout','stderr']}
            rec=dict(raw_status=20,error=None,capture_complete=True,**channels)
            Path(str(prefix)+'.capture.json').write_text(json.dumps(rec))
            self.assertEqual([],self.p.validate_probe_files('install-new',prefix,candidate_catalog()))
            rec['error']='timeout';Path(str(prefix)+'.capture.json').write_text(json.dumps(rec))
            with self.assertRaises(self.p.DiagnosticError):self.p.validate_probe_files('install-new',prefix,candidate_catalog())

class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.m=importlib.import_module('normal_update_metadata')
        self.assertTrue(hasattr(self.m,'validate_catalog'),'catalog validator missing')
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.work=self.root/'var/lib/slackpkg';self.work.mkdir(parents=True)
        self.meta=FIXTURES/'metadata'
        for name in ['CHECKSUMS.md5','FILELIST.TXT']:
            data=gzip.decompress((self.meta/(name+'.gz')).read_bytes())
            self.assertLess(len(data),64*1024*1024)
            (self.work/name).write_bytes(data)
        (self.work/'CHECKSUMS.md5.asc').write_bytes((self.meta/'CHECKSUMS.md5.asc').read_bytes())
        self.awk=self.root/'pkglist.awk';self.awk.write_bytes((self.meta/'pkglist.awk').read_bytes())
        filtered=b''.join(line+b'\n' for line in (self.work/'CHECKSUMS.md5').read_bytes().splitlines() if __import__('re').search(rb'\.t[blxg]z$',line))
        data=subprocess.run(['awk','-f',str(self.awk)],input=filtered,capture_output=True,check=True).stdout
        self.pkglist=b'\n'.join(line[1:] if line.startswith(b'M') else line for line in data.split(b'\n'))
        (self.work/'pkglist').write_bytes(self.pkglist)
        (self.work/'LASTUPDATE').write_text('1793573177\n')
        self.policy={'backend_profile':'slackpkg-15.0.10-count-v1','primary_fingerprint':FPR,
                     'public_keyring':str(self.meta/'slackware.gpg'),'public_keyring_sha256':hashlib.sha256((self.meta/'slackware.gpg').read_bytes()).hexdigest(),
                     'mirror':'https://fixture.invalid/slackware64-current/','_workdir':str(self.work),'_pkglist_awk':str(self.awk)}
        self.protected={'backend':{},'configuration':{},'packages':{},'package_database_resolved':'fixture','workdir':{}}
        self.before={'lastupdate_before':1793573177,'selection':copy.deepcopy(self.protected)}
        def acquire(url,out):
            name=url.rsplit('/',1)[-1];data=(self.work/name).read_bytes();Path(out).write_bytes(data)
            return dict(bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),effective_url=url)
        self.patch=mock.patch.object(self.m,'fetch_https',side_effect=acquire);self.patch.start();self.addCleanup(self.patch.stop)
        self.snap=mock.patch.object(self.m,'capture_selection',return_value=self.protected);self.snap.start();self.addCleanup(self.snap.stop)
        self.count=0
    def validate(self):
        self.count+=1;dest=self.root/('validation-'+str(self.count));dest.mkdir()
        return self.m.validate_catalog(self.policy,self.before,dest)
    def test_coherent_equal_date_is_valid(self):
        result=self.validate()
        self.assertEqual(1793573177,result['filelist_timestamp'])
        self.assertTrue(result['packages'])
        self.assertFalse(result['latest_global_claimed'])
    def test_changed_index_and_date_fail(self):
        mutations=[('pkglist',b'old index\n'),('LASTUPDATE',b'1793573178\n'),('LASTUPDATE',b'not-a-date\n')]
        for name,data in mutations:
            path=self.work/name;old=path.read_bytes();path.write_bytes(data)
            with self.subTest(name=name):
                with self.assertRaises(self.m.DiagnosticError):self.validate()
            path.write_bytes(old)
        self.before['lastupdate_before']=1793573178
        with self.assertRaises(self.m.DiagnosticError):self.validate()
    def test_checksum_mismatch_and_wrong_key_fail(self):
        old=(self.work/'FILELIST.TXT').read_bytes();(self.work/'FILELIST.TXT').write_bytes(old+b'altered\n')
        with self.assertRaises(self.m.DiagnosticError):self.validate()
        (self.work/'FILELIST.TXT').write_bytes(old)
        self.policy['primary_fingerprint']='0'*40
        with self.assertRaises(self.m.DiagnosticError):self.validate()
    def test_package_or_config_drift_after_update_blocks_validation(self):
        for domain in ['backend','configuration','packages','package_database_resolved']:
            original=copy.deepcopy(self.protected[domain])
            self.protected[domain]={'changed':True}
            with self.subTest(domain=domain):
                with self.assertRaises(self.m.DiagnosticError):self.validate()
            self.protected[domain]=original

    def test_corrupt_signature_fails(self):
        p=self.work/'CHECKSUMS.md5.asc';p.write_bytes(p.read_bytes().replace(b'A',b'B'))
        with self.assertRaises(self.m.DiagnosticError):self.validate()

class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.m=importlib.import_module('normal_update_metadata')
        self.assertTrue(hasattr(self.m,'load_policy'),'policy validator missing')
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        (self.root/'etc').mkdir()
        (self.root/'etc/slackware-version').write_text('Slackware 15.0+\n')
        paths=['/usr/sbin/slackpkg','/usr/libexec/slackpkg/pkglist.awk','/usr/libexec/slackpkg/functions.d/dialog-functions.sh']
        tools={}
        for name in paths:
            p=self.root/name.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_text('fixture\n');p.chmod(0o755);tools[name]=hashlib.sha256(p.read_bytes()).hexdigest()
        conf=self.root/'etc/slackpkg';conf.mkdir(parents=True)
        (conf/'slackpkg.conf').write_text('WORKDIR=/var/lib/slackpkg\n')
        (conf/'mirrors').write_text('https://fixture.invalid/tree/\n');(conf/'blacklist').write_text('')
        work=self.root/'var/lib/slackpkg';work.mkdir(parents=True);(work/'LASTUPDATE').write_text('1793573177\n')
        self.key=FIXTURES/'metadata/slackware.gpg'
        self.policy={'schema':1,'target':'slackware-current','hostname':'fixture-host','boot_id':'fixture-boot','backend_profile':'slackpkg-15.0.10-count-v1',
         'backend_sha256':tools,'configuration_sha256':{'/etc/slackpkg/'+p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in conf.iterdir()},'mirror':'https://fixture.invalid/tree/',
         'public_keyring':str(self.key),'public_keyring_sha256':hashlib.sha256(self.key.read_bytes()).hexdigest(),'primary_fingerprint':FPR,'boot_profile':'current-grub',
         'required_mounts':{'/':{'source':'fixture-root','fstype':'ext4'},'/boot/efi':{'source':'fixture-efi','fstype':'vfat'}},'extra_boot_files':[]}
        self.profile=self.root/'profiles.json';self.profile.write_text(json.dumps({'slackpkg-15.0.10-count-v1':dict(backend_sha256=tools,executable_extensions=['dialog-functions.sh'],pkglist_awk='/usr/libexec/slackpkg/pkglist.awk',workdir='/var/lib/slackpkg')}))
        self.path=self.root/'policy.json'
        for patch in [mock.patch.object(self.m,'SYSTEM_ROOT',self.root),mock.patch.object(self.m,'host_identity',return_value=('fixture-host','fixture-boot'))]:
            patch.start();self.addCleanup(patch.stop)
    def load(self):
        self.path.write_text(json.dumps(self.policy));return self.m.load_policy(self.path,self.profile)
    def test_exact_policy_is_valid(self):
        self.assertEqual('slackpkg-15.0.10-count-v1',self.load()['backend_profile'])
    def test_wrong_binding_and_unsupported_profile(self):
        for key,value in [('hostname','other'),('boot_id','other'),('backend_profile','slackpkg16'),('mirror','https://user:secret@fixture.invalid/tree/'),('unknown','x')]:
            original=copy.deepcopy(self.policy);self.policy[key]=value
            with self.subTest(key=key):
                with self.assertRaises(self.m.DiagnosticError):self.load()
            self.policy=original
    def test_policy_target_must_match_effective_host(self):
        self.policy['target']='slackware-15.0'
        self.policy['boot_profile']='slackware15-elilo'
        with self.assertRaises(self.m.DiagnosticError):self.load()

    def test_tools_configuration_and_extra_extensions_drift(self):
        for logical in ['/usr/sbin/slackpkg','/etc/slackpkg/blacklist']:
            p=self.root/logical.lstrip('/');old=p.read_bytes();p.write_bytes(b'changed')
            with self.assertRaises(self.m.DiagnosticError):self.load()
            p.write_bytes(old)
        extra=self.root/'usr/libexec/slackpkg/functions.d/unknown.sh';extra.write_text('bad');extra.chmod(0o755)
        with self.assertRaises(self.m.DiagnosticError):self.load()
    def test_duplicate_json_and_missing_file(self):
        self.path.write_text('{"schema":1,"schema":1}')
        with self.assertRaises(self.m.DiagnosticError):self.m.load_policy(self.path,self.profile)
        self.path.unlink()
        with self.assertRaises(self.m.DiagnosticError):self.m.load_policy(self.path,self.profile)

class CatalogSignatureIntegrationTests(CatalogTests):
    """The positive and negative tests above execute real gpgv on public920 bytes."""


class BootTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue((HELPERS/'normal_update_boot.py').exists(),'boot manifest missing')
        self.b=importlib.import_module('normal_update_boot')
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        for name,data in [('boot/initrd-6.18.45.img',b'initrd'),('boot/vmlinuz-6.18.45',b'kernel'),('boot/intel-ucode.img',b'ucode'),('boot/grub/grub.cfg',b'menu'),('boot/grub/grubenv',b'env'),('boot/efi/EFI/Slackware/grubx64.efi',b'efi')]:
            p=self.root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        (self.root/'boot/initrd-generic.img').symlink_to('initrd-6.18.45.img')
        self.mounts={'/':{'source':'fixture-root','fstype':'ext4'},'/boot/efi':{'source':'fixture-efi','fstype':'vfat'}}
        self.policy={'target':'slackware-current','boot_profile':'current-grub','required_mounts':copy.deepcopy(self.mounts),'extra_boot_files':[]}
    def capture(self):return self.b.capture_boot(self.policy,self.root,self.mounts)
    def test_complete_equal_snapshots(self):
        a=self.capture();b=self.capture()
        self.assertTrue(self.b.compare_boot(a,b))
        self.assertEqual('missing',a['entries']['/boot/initrd.gz']['type'])
        self.assertEqual('symlink',a['entries']['/boot/initrd-generic.img']['type'])
    def test_versioned_initrd_change_and_membership(self):
        baseline=self.capture()
        for name,data in [('boot/initrd-6.18.45.img',b'changed'),('boot/added',b'new')]:
            p=self.root/name;old=p.read_bytes() if p.exists() else None;p.write_bytes(data)
            self.assertFalse(self.b.compare_boot(baseline,self.capture()))
            if old is None:p.unlink()
            else:p.write_bytes(old)
        (self.root/'boot/vmlinuz-6.18.45').unlink()
        self.assertFalse(self.b.compare_boot(baseline,self.capture()))
    def test_retarget_link(self):
        baseline=self.capture();(self.root/'boot/other.img').write_bytes(b'other')
        p=self.root/'boot/initrd-generic.img';p.unlink();p.symlink_to('other.img')
        self.assertFalse(self.b.compare_boot(baseline,self.capture()))
    def test_efi_mount_missing_or_replaced(self):
        for value in [None,{'source':'wrong','fstype':'vfat'}]:
            if value is None:self.mounts.pop('/boot/efi',None)
            else:self.mounts['/boot/efi']=value
            with self.assertRaises(self.b.DiagnosticError):self.capture()
    def test_broken_cyclic_external_and_directory_links(self):
        p=self.root/'boot/bad'
        outside=self.root/'outside';outside.write_bytes(b'external')
        for target in ['absent','bad','/outside','grub']:
            p.symlink_to(target)
            with self.subTest(target=target):
                with self.assertRaises(self.b.DiagnosticError):self.capture()
            p.unlink()
    def test_extra_boot_files_cannot_expand_to_directory(self):
        p=self.root/'outside-dir';p.mkdir();(p/'private').write_text('must not traverse')
        self.policy['extra_boot_files']=['/outside-dir']
        with self.assertRaises(self.b.DiagnosticError):self.capture()

    def test_external_file_mount_ancestor_must_be_bound(self):
        target=self.root/'external-mount/initrd.img';target.parent.mkdir();target.write_bytes(b'external initrd')
        (self.root/'boot/external.img').symlink_to('/external-mount/initrd.img')
        self.policy['extra_boot_files']=['/external-mount/initrd.img']
        self.mounts['/external-mount']={'source':'device-one','fstype':'ext4'}
        with self.assertRaises(self.b.DiagnosticError):self.capture()
        self.policy['required_mounts']['/external-mount']=copy.deepcopy(self.mounts['/external-mount'])
        baseline=self.capture()
        self.assertIn('/external-mount',baseline['observed_mounts'])
        self.mounts['/external-mount']['source']='replacement-device'
        with self.assertRaises(self.b.DiagnosticError):self.capture()
        self.mounts.pop('/external-mount')
        with self.assertRaises(self.b.DiagnosticError):self.capture()

    def test_declared_external_file_is_captured(self):
        (self.root/'outside').write_bytes(b'external')
        (self.root/'boot/extra.img').symlink_to('/outside')
        self.policy['extra_boot_files']=['/outside']
        data=self.capture()
        self.assertEqual(hashlib.sha256(b'external').hexdigest(),data['entries']['/outside']['sha256'])
    def test_special_and_unreadable_objects_fail(self):
        p=self.root/'boot/fifo';os.mkfifo(p)
        with self.assertRaises(self.b.DiagnosticError):self.capture()
        p.unlink()
        with mock.patch.object(self.b,'file_record',side_effect=PermissionError('fixture')):
            with self.assertRaises(self.b.DiagnosticError):self.capture()
    def test_elilo_is_a_separate_profile(self):
        self.policy['target']='slackware-15.0';self.policy['boot_profile']='slackware15-elilo'
        with self.assertRaises(self.b.DiagnosticError):self.capture()
        p=self.root/'boot/efi/EFI/Slackware/elilo.conf';p.write_text('image=vmlinuz\n')
        data=self.capture()
        self.assertEqual('slackware15-elilo',data['profile'])
        self.assertNotIn('/etc/default/grub',data['entries'])


class MainIntegrationTests(unittest.TestCase):
    def test_real_main_private_components(self):
        support=Path(__file__).with_name('normal_update_diagnostic_test_support.py').resolve()
        harness=HELPERS/'test-normal-update.sh'
        shell=r'''
source "$1"
case_root=$2
support=$3
id() { if [ "${1:-}" = -u ]; then printf '0\n'; else command id "$@"; fi; }
hostname() { printf 'fixture-host\n'; }
forbidden() { printf 'FORBIDDEN\n' >> "$case_root/forbidden"; return 97; }
slackpkg() { forbidden; }
run_metadata_refresh() { forbidden; }
run_candidate_probe() { forbidden; }
extract_slackpkg_candidates() { forbidden; }
run_reference_apply() { forbidden; }
bridge() { python3 -B "$support" "$case_root" "$@"; }
validate_diagnostic_policy() { bridge policy "$@"; }
validate_diagnostic_catalog() { bridge catalog "$@"; }
validate_diagnostic_probe() { bridge probe "$@"; }
establish_diagnostic_baseline() { bridge baseline "$@"; }
capture_selection_state() { bridge selection "$@"; }
capture_package_database() { bridge packages "$@"; }
capture_diagnostic_boot() { bridge boot "$@"; }
run_diagnostic_command() { bridge command "$@"; }
capture_host_metadata() { printf 'fixture_context=true\n' > "$1"; }
publish_evidence_archive() { :; }
print_evidence_copy_command() { :; }
print_evidence_verification_command() { :; }
unset SUDO_UID SUDO_GID SUDO_USER
main --target slackware-current --preflight --diagnostic-policy "$case_root/policy.json" --output-dir "$case_root/evidence"
'''
        for scenario,rc,total,trace in [
            ('control',0,'1',['update','install-new','upgrade-all']),
            ('ghost-and-upgrade',0,'1',['update','install-new','upgrade-all']),
            ('ghost',1,'0',['update','install-new','upgrade-all']),
            ('both-empty',1,'0',['update','install-new','upgrade-all']),
            ('catalog-stale',1,'not-calculated',['update']),
            ('post-catalog-drift',1,'not-calculated',['update']),
            ('index-drift',1,'not-calculated',['update','install-new'])]:
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as tmp:
                root=Path(tmp)
                subprocess.run([sys.executable,'-B',str(support),str(root),'prepare',scenario],check=True,capture_output=True)
                proc=subprocess.run(['bash','-c',shell,'private-main',str(harness),str(root),str(support)],capture_output=True,text=True,timeout=30)
                self.assertEqual(rc,proc.returncode,proc.stdout+proc.stderr)
                summary=dict(line.split('=',1) for line in (root/'evidence/summary.txt').read_text().splitlines())
                self.assertEqual(total,summary['total_candidates'])
                self.assertEqual(trace,(root/'trace').read_text().splitlines())
                self.assertFalse((root/'forbidden').exists())
                if rc==0:
                    expected=hashlib.sha256(b'kernel-headers-7.2.15-x86-1.txz\n').hexdigest()
                    self.assertEqual(expected,summary['candidate_set_sha256'])
                    self.assertNotIn('ghost',(root/'evidence/all.candidates.txt').read_text())
                else:self.assertEqual('not-calculated',summary['candidate_set_sha256'])
                # A real archive/portable sidecar from the real finalizer.
                result=subprocess.run(['sha256sum','-c','evidence.tar.gz.sha256'],cwd=root,capture_output=True)
                self.assertEqual(0,result.returncode,result.stderr)


class FetchTests(unittest.TestCase):
    def setUp(self):
        self.m=importlib.import_module('normal_update_metadata')
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.path=Path(self.tmp.name)/'download'
    def response(self,size=3,url='https://fixture.invalid/data'):
        class Response:
            headers={'Content-Type':'text/plain'}
            def __init__(self):self.remaining=size
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def geturl(self):return url
            def read(self,amount):
                count=min(amount,self.remaining);self.remaining-=count;return b'x'*count
        return Response()
    def run_fetch(self,response):
        opener=mock.Mock();opener.open.return_value=response
        with mock.patch.object(self.m.urllib.request,'build_opener',return_value=opener):
            return self.m.fetch_https('https://fixture.invalid/data',self.path)
    def test_https_bytes_are_recorded(self):
        data=self.run_fetch(self.response())
        self.assertEqual(b'xxx',self.path.read_bytes())
        self.assertEqual(hashlib.sha256(b'xxx').hexdigest(),data['sha256'])
        self.assertIsNone(json.loads(Path(str(self.path)+'.fetch.json').read_text())['error'])
    def test_downgrade_rejected(self):
        with self.assertRaises(self.m.DiagnosticError):self.run_fetch(self.response(url='http://fixture.invalid/data'))
    def test_chunked_size_bound_without_content_length(self):
        with self.assertRaises(self.m.DiagnosticError):self.run_fetch(self.response(size=64*1024*1024+1))
        self.assertLessEqual(self.path.stat().st_size,64*1024*1024)
    def test_deadline_rejected(self):
        with mock.patch.object(self.m.time,'monotonic',side_effect=[0,61]):
            with self.assertRaises(self.m.DiagnosticError):self.run_fetch(self.response())

if __name__ == '__main__':
    unittest.main()
