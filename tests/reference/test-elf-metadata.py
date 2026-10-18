#!/usr/bin/env python3
"""Check static ELF metadata helpers with private files and supplied readelf bytes."""
from pathlib import Path
import itertools
import os
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
IDENTITIES = (('ELF64','little endian','X86-64'),('ELF32','little endian','80386'),
              ('ELF64','little endian','AArch64'),('ELF64','big endian','X86-64'))


def header(identity):
    return ''.join(f'  {key}: {value}\n' for key,value in zip(('Class','Data','Machine'),identity))


HEADERS = (
    *((f'identity-{i}',header(identity),'\t'.join(identity)+'\n') for i,identity in enumerate(IDENTITIES)),
    ('reordered','Machine: A\nData: D\nClass: C\n','C\tD\tA\n'),
    ('whitespace',' \tClass: \tELF64 \t\n Data: little endian   \nMachine: X86-64\t\n','ELF64\tlittle endian\tX86-64\n'),
    ('last-field-wins','Class: old\n'+header(IDENTITIES[0]),'\t'.join(IDENTITIES[0])+'\n'),
    ('colons','Class: C:discard\nData: D:retained\nMachine: M:retained\n','C\tD:retained\tM:retained\n'),
    ('unterminated',header(IDENTITIES[0]).rstrip('\n'),'\t'.join(IDENTITIES[0])+'\n'),
    ('unknown-values','Class: strange\nData: arbitrary\nMachine: unknown\n','strange\tarbitrary\tunknown\n'),
    ('noise','ignored\n'+header(IDENTITIES[0]),'\t'.join(IDENTITIES[0])+'\n'),
    ('missing-class','Data: D\nMachine: M\n',None),
    ('missing-data','Class: C\nMachine: M\n',None),
    ('missing-machine','Class: C\nData: D\n',None),
    ('blank-field','Class: C\nData: \t\nMachine: M\n',None),
    ('wrong-case','class: C\ndata: D\nmachine: M\n',None),
    ('empty','',None),
)
DYNAMIC = (
    ('empty','',''), ('none','No dynamic section\n',''),
    ('one',' (NEEDED) Shared library: [liba.so]\n','liba.so\n'),
    ('duplicates',' (NEEDED) [libz.so]\n (NEEDED) [liba.so]\n (NEEDED) [libz.so]\n','liba.so\nlibz.so\n'),
    ('ignore-other',' (SONAME) [libx.so]\n',''),
    ('unterminated',' (NEEDED) [liba.so]','liba.so\n'),
    ('empty-name',' (NEEDED) []\n','\n'),
    ('unbracketed',' (NEEDED) no brackets\n',' (NEEDED) no brackets\n'),
    ('last-bracket',' (NEEDED) [first] [last]\n','last\n'),
    ('extra-tail',' (NEEDED) [liba.so] ignored\n','liba.so\n'),
    ('wrong-case',' (needed) [liba.so]\n',''),
)
CACHES = ((),(('liba.so',*IDENTITIES[0],'/unmeasured/path'),),
          (('liba.so',*IDENTITIES[1],'/unmeasured/path'),),
          (('liba.so',*IDENTITIES[2],'/unmeasured/path'),),
          (('liba.so',*IDENTITIES[3],'/unmeasured/path'),),
          tuple(('liba.so',*identity,'/unmeasured/path') for identity in IDENTITIES),
          (('liba.so.prefix',*IDENTITIES[0],'/unmeasured/path'),),
          (('liba.so',*IDENTITIES[0]),),
          (('liba.so',*IDENTITIES[0],'/first'),('liba.so',*IDENTITIES[0],'/second')))
PREFIX = r'''
source "$1"
TEST_ROOT=$2
BROKEN_ERRORS=$TEST_ROOT/errors
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
readelf() {
    [[ $# == 3 && $2 == -- && $3 == "$TEST_ROOT/object" ]] || forbidden readelf-vector
    builtin printf '%s\0' "$@" "$LC_ALL" >> "$TEST_ROOT/trace"
    case "$1" in
        -h) builtin printf '%s' "$HEADER_BYTES"; builtin printf '%s' "$HEADER_ERRORS" >&2; return "$HEADER_RC" ;;
        -d) builtin printf '%s' "$DYNAMIC_BYTES"; builtin printf '%s' "$DYNAMIC_ERRORS" >&2; return "$DYNAMIC_RC" ;;
        *) forbidden readelf-mode ;;
    esac
}
od() {
    [[ $# == 5 && $1 == -An && $2 == -tx1 && $3 == -N4 && $4 == -- && $5 == "$TEST_ROOT/"* ]] || forbidden od-vector
    [[ $FAULT != od ]] || return 43
    builtin command od "$@"
}
tr() { [[ $FAULT != tr ]] || return 43; builtin command tr "$@"; }
readlink() {
    [[ $# == 3 && $1 == -f && $2 == -- && $3 == "$TEST_ROOT/"* ]] || forbidden readlink-vector
    [[ $FAULT != readlink ]] || return 43
    builtin command readlink "$@"
}
sort() {
    if [[ $FAULT == sort ]]; then
        local discard=
        while IFS= read -r discard || [[ -n $discard ]]; do :; done
        return 43
    fi
    builtin command sort "$@"
}
'''
FORBIDDEN = ('main','initialize_execution_environment','initialize_runtime','load_configuration','run_apply_workflow',
             'run_check_workflow','run_dry_run_workflow','refresh_static_elf_library_cache','detect_broken_elf_objects',
             'verify_broken_elf_objects_after_rebuild','ldd','ldconfig','slackpkg','sbopkg','sqg','flatpak','git','curl',
             'wget','find','mktemp','mv','rm','chmod','regenerate_initrd','update_grub_configuration')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)


def compatible(cache, soname, identity):
    return len(identity)==3 and all(identity) and any(tuple(row[:4])==(soname,*identity) for row in cache)


def inventory(root):
    return {str(p.relative_to(root)):('link',os.readlink(p)) if p.is_symlink() else ('dir',) if p.is_dir()
            else ('file',p.read_bytes()) for p in root.rglob('*')}


def invoke(root, entry, arguments, values, status, stdout='', errors='prior\n', calls=()):
    (root/'errors').write_text('prior\n')
    (root/'cache').write_text(''.join('\t'.join(row)+'\n' for row in values.pop('cache',())))
    before = inventory(root)
    defaults = dict(HEADER_BYTES='',DYNAMIC_BYTES='',HEADER_ERRORS='',DYNAMIC_ERRORS='',HEADER_RC=0,DYNAMIC_RC=0,FAULT='none')
    defaults.update(values)
    assignments = '\n'.join(name+'='+shlex.quote(str(value)) for name,value in defaults.items())
    script = PREFIX+GUARDS+'\n'+assignments+'\nsaved_ifs=$IFS\nouter=kept\n'+entry+' '+shlex.join(map(str,arguments))+'\nraw=$?\n'
    script += '[[ $IFS == "$saved_ifs" && $outer == kept ]] || exit 96\nbuiltin printf "\\0STATUS\\0%s" "$raw"\n'
    result = subprocess.run(['bash','--noprofile','--norc','-c',script,'elf-metadata-test',str(REFERENCE),str(root)],
                            capture_output=True,cwd=root,env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)),timeout=10)
    wanted = stdout.encode()+b'\0STATUS\0'+str(status).encode()
    if (result.returncode,result.stdout,result.stderr)!=(0,wanted,b''):
        raise AssertionError(f'{entry}: expected {(0,wanted,b"")!r}, got {(result.returncode,result.stdout,result.stderr)!r}')
    expected_trace = b''.join(b'\0'.join(x.encode() for x in (mode,'--',str(root/'object'),'C'))+b'\0' for mode in calls)
    actual_trace = (root/'trace').read_bytes() if (root/'trace').exists() else b''
    if actual_trace!=expected_trace:raise AssertionError(f'{entry}: readelf vector/order differs')
    if calls:before['trace']=('file',expected_trace)
    before['errors']=('file',errors.encode())
    if inventory(root)!=before:raise AssertionError(f'{entry}: private inventory differs')


def run():
    counts = dict.fromkeys(('magic/path','header','dynamic','cache','dependency'),0)
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-metadata-') as tmp:
        parent=Path(tmp);index=0
        def fresh():
            nonlocal index
            index+=1;root=parent/str(index);root.mkdir();return root
        for profile,entry,fault in itertools.product(('elf','empty','text','short','directory','missing','link','dangling','chain','loop','option-name','script'),
                ('elf_file_has_static_magic','resolve_static_elf_object_path'),('none','od','tr','readlink')):
            root=fresh();obj=root/'object';target=root/'target';resolved=obj
            data={'elf':b'\x7fELFpayload','empty':b'','text':b'text','short':b'\x7fEL','option-name':b'\x7fELF','script':b'#!/bin/sh\nexit 0\n'}
            if profile in data:obj.write_bytes(data[profile]);obj.chmod(0o755)
            elif profile=='directory':obj.mkdir()
            elif profile=='link':target.write_bytes(b'\x7fELF');obj.symlink_to(target);resolved=target
            elif profile=='dangling':obj.symlink_to(target)
            elif profile=='chain':
                target.write_bytes(b'\x7fELF');(root/'middle').symlink_to(target);obj.symlink_to(root/'middle');resolved=target
            elif profile=='loop':obj.symlink_to(obj)
            if profile=='option-name':
                option=root/'-option';obj.rename(option);obj=option;resolved=option
            good=profile in ('elf','link','chain','option-name') and fault not in ('od','tr')
            if entry=='resolve_static_elf_object_path' and fault=='readlink':good=False
            invoke(root,entry,[obj],dict(FAULT=fault),0 if good else 1,str(resolved)+'\n' if good and entry.startswith('resolve') else '')
            counts['magic/path']+=1
        for profile,rc,warning in itertools.product(HEADERS,(0,7),('', 'supplied header diagnostic\n')):
            _,data,parsed=profile;root=fresh()
            invoke(root,'extract_static_elf_identity',[root/'object'],dict(HEADER_BYTES=data,HEADER_RC=rc,HEADER_ERRORS=warning),
                   1 if parsed is None else rc,parsed or '',errors='prior\n'+warning,calls=('-h',));counts['header']+=1
        for profile,rc,fault in itertools.product(DYNAMIC,(0,7),('none','sort')):
            _,data,parsed=profile;root=fresh()
            invoke(root,'extract_static_elf_needed_libraries',[root/'object'],dict(DYNAMIC_BYTES=data,DYNAMIC_RC=rc,DYNAMIC_ERRORS='supplied dynamic diagnostic\n',FAULT=fault),
                   43 if fault=='sort' else rc,'' if fault=='sort' else parsed,errors='prior\nsupplied dynamic diagnostic\n',calls=('-d',));counts['dynamic']+=1
        queries=(*IDENTITIES,('ELF32','little endian','X86-64'),(),('ELF64','broken'))
        for cache,soname,identity in itertools.product(CACHES,('liba.so','liba','missing.so'),queries):
            root=fresh();good=compatible(cache,soname,identity)
            invoke(root,'static_elf_cache_has_compatible_library',[root/'cache',soname,'\t'.join(identity)],dict(cache=cache),0 if good else 1);counts['cache']+=1
        needed_profiles=((),('liba.so',),('missing.so',),('liba.so','liba.so'),('liba.so','missing.so'),('liba',),('',))
        for identity,needed,cache,h_rc,d_rc in itertools.product((*IDENTITIES,None),needed_profiles,(CACHES[0],CACHES[1],CACHES[3],CACHES[5]),(0,7),(0,7)):
            root=fresh();h_data=header(identity) if identity else 'Class: ELF64\n'
            dynamic=''.join(' (NEEDED) ['+name+']\n' for name in needed)
            calls=('-h',) if h_rc or identity is None else ('-h','-d')
            status=2 if h_rc or identity is None or d_rc else (1 if all(compatible(cache,name,identity) for name in needed if name) else 0)
            invoke(root,'static_elf_object_has_missing_dependency',[root/'object',root/'cache'],dict(cache=cache,HEADER_BYTES=h_data,DYNAMIC_BYTES=dynamic,
                HEADER_RC=h_rc,DYNAMIC_RC=d_rc,HEADER_ERRORS='h\n',DYNAMIC_ERRORS='d\n'),status,
                errors='prior\nh\n'+('d\n' if len(calls)==2 else ''),calls=calls);counts['dependency']+=1
    print('ELF metadata tests: '+', '.join(f'{value} {kind} entries' for kind,value in counts.items())+', 0 failures')


if __name__=='__main__':run()
