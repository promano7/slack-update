#!/usr/bin/env python3
"""Check private ELF scan/recheck workflows with supplied cache and dependency readers."""
from pathlib import Path
from collections import Counter
import itertools
import os
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'tools/reference/slack-update-reference.sh'
FIELDS = ('ELF_SCAN_STATUS','ELF_VERIFICATION_STATUS','BROKEN_COUNT','ELF_LIBRARY_CACHE_RECORD_COUNT')
PREFIX = r'''
source "$1"
TEST_ROOT=$2
record() { builtin printf '%s\0' "$@" >> "$TEST_ROOT/trace"; builtin printf '\n' >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
refresh_static_elf_library_cache() {
    [[ $# == 1 && $1 == "$ELF_LIBRARY_CACHE" ]] || forbidden cache-vector
    record refresh "$@"
    ELF_LIBRARY_CACHE_RECORD_COUNT=0
    if [[ $FAULT == cache ]]; then builtin printf 'supplied cache error\n' >> "$BROKEN_ERRORS"; return 43; fi
    builtin printf 'supplied cache\n' > "$1"
    ELF_LIBRARY_CACHE_RECORD_COUNT=1
}
static_elf_object_has_missing_dependency() {
    [[ $# == 2 && $1 == "$TEST_ROOT/scan/"* && $2 == "$ELF_LIBRARY_CACHE" ]] || forbidden dependency-vector
    record dependency "$@"
    case "$1" in
        */healthy) return 1 ;;
        */broken|*/broken2|*/'space name') return 0 ;;
        */error) return 2 ;;
        */other) return 23 ;;
        *) forbidden unexpected-object ;;
    esac
}
find() {
    [[ $# == 9 && $1 == "$TEST_ROOT/scan" && $9 == -print0 ]] || forbidden find-vector
    record find "$@"
    [[ $FAULT != find ]] || return 43
    builtin command find "$@"
    local status=$?
    [[ $FAULT != find-partial ]] || return 43
    return "$status"
}
sort() {
    [[ $# == 1 && $1 == -u ]] || forbidden sort-vector
    if [[ $FAULT == sort ]]; then
        local line=
        while IFS= read -r line || [[ -n $line ]]; do :; done
        return 43
    fi
    builtin command sort "$@"
    local status=$?
    if [[ $FAULT == clear-directory || $FAULT == clear-link-directory ]]; then
        [[ $status == 0 && $BROKEN == "$TEST_ROOT/broken" \
            && -f $BROKEN && ! -L $BROKEN && ! -s $STILL_BROKEN ]] || forbidden clear-fixture
        record block-clear "$FAULT"
        builtin command mv -- "$BROKEN" "$TEST_ROOT/saved-broken" || forbidden clear-move
        if [[ $FAULT == clear-directory ]]; then
            builtin command mkdir -- "$BROKEN" || forbidden clear-directory
        else
            builtin command mkdir -- "$TEST_ROOT/clear-target" || forbidden clear-target
            builtin command ln -s -- "$TEST_ROOT/clear-target" "$BROKEN" || forbidden clear-link
        fi
    fi
    [[ $FAULT != sort-partial ]] || return 43
    return "$status"
}
cp() {
    [[ $# == 4 && $1 == -f && $2 == -- && $3 == "$TEST_ROOT/"* && $4 == "$BROKEN" ]] || forbidden cp-vector
    record cp "$@"
    [[ $FAULT != cp ]] || return 43
    if [[ $FAULT == cp-partial ]]; then
        builtin printf 'supplied partial copy\n' > "$BROKEN"
        return 43
    fi
    builtin command cp "$@"
}
wc() {
    [[ $# == 1 && $1 == -l ]] || forbidden wc-vector
    record wc "$@"
    [[ $FAULT != wc ]] || return 43
    if [[ $FAULT == wc-partial ]]; then
        builtin printf '42\n'
        return 43
    fi
    builtin command wc "$@"
}
'''
FORBIDDEN = ('main','initialize_execution_environment','initialize_runtime','load_configuration','run_apply_workflow',
             'run_check_workflow','run_dry_run_workflow','extract_static_elf_identity','extract_static_elf_needed_libraries',
             'readelf','ldd','ldconfig','slackpkg','sbopkg','sqg','flatpak','git','curl','wget','mktemp','mv','rm',
             'regenerate_initrd','update_grub_configuration','map_broken_objects_to_sbo_packages')
GUARDS = '\n'.join(f'{name}() {{ forbidden {name}; }}' for name in FORBIDDEN)
SCAN_PROFILES = ('empty','healthy','broken','error','mixed')
VERIFY_PROFILES = ('missing-list','empty','healthy','broken','error','text','dangling','missing-object',
                   'mixed','duplicates','no-newline','blank-lines')


def inventory(root):
    return {str(p.relative_to(root)):('link',os.readlink(p)) if p.is_symlink() else ('dir',) if p.is_dir()
            else ('file',p.read_bytes()) for p in root.rglob('*') if p.name != 'trace'}


def diagnostics(lines):
    return '' if not lines else '  [WARN] Static ELF inspection diagnostics:\n'+''.join('    '+line+'\n' for line in lines)


def scenario(root, kind, profile, fault, old_errors):
    scan = root/'scan'
    if profile != 'missing-root':scan.mkdir()
    paths = {key:str(root/key.lower()) for key in ('BROKEN','BROKEN_NEW','STILL_BROKEN','BROKEN_ERRORS','ELF_LIBRARY_CACHE')}
    for path in paths.values():Path(path).write_text('old\n')
    Path(paths['BROKEN_ERRORS']).write_text(old_errors)
    names = []
    if kind == 'scan':
        names = [] if profile in ('empty','missing-root') else [profile] if profile != 'mixed' else [
            'healthy','broken','error','other','text','link-broken','dangling','nested/broken2','space name']
    elif kind == 'verify':
        names = ['healthy','broken','error','other','text','link-broken','dangling','nested/broken2','space name']
    for name in names:
        p=scan/name;p.parent.mkdir(parents=True,exist_ok=True)
        if name == 'link-broken':p.symlink_to(scan/'broken')
        elif name == 'dangling':p.symlink_to(scan/'missing')
        else:p.write_bytes(b'text\n' if name == 'text' else b'\x7fELFfixture\n')
    lines = []
    if kind == 'verify':
        selected = dict(healthy=['healthy'],broken=['broken'],error=['error'],text=['text'],dangling=['dangling'],
                        **{'missing-object':['missing'],'mixed':['healthy','broken','link-broken','error','text','dangling','missing','other','space name'],
                           'duplicates':['broken','error','error','broken'],'no-newline':['broken'],'blank-lines':['','healthy','','broken','']})
        lines = [str(scan/name) if name else '' for name in selected.get(profile,[])]
        value = '\n'.join(lines)+('\n' if lines and profile != 'no-newline' else '')
        if profile == 'missing-list':Path(paths['BROKEN']).unlink()
        else:Path(paths['BROKEN']).write_text(value)
    if kind == 'report':Path(paths['BROKEN_ERRORS']).write_text(profile)
    expected = inventory(root); state=['9','8','7','6']; output=''; status=0; calls=[]; stderr=b''; stderr_pattern=None
    def file(key,data):expected[Path(paths[key]).name]=('file',data.encode())
    def call(*args):calls.append(tuple(map(str,args)))
    early = kind == 'verify' and profile in ('missing-list','empty')
    if kind == 'report':
        if profile:output='  [WARN] Static ELF inspection diagnostics:\n'+''.join('    '+line for line in profile.splitlines(keepends=True));file('BROKEN_ERRORS','')
    elif early:state[1]='0'
    else:
        state[0 if kind == 'scan' else 1]='0';state[3]='0' if fault == 'cache' else '1'
        file('BROKEN_ERRORS','');file('BROKEN_NEW' if kind == 'scan' else 'STILL_BROKEN','')
        call('refresh',paths['ELF_LIBRARY_CACHE'])
        if kind == 'scan':output='[8] Detecting broken ELF objects without executing inspected files\n'
        else:output='  Verifying rebuilt ELF objects with static inspection...\n'
        if fault == 'cache':
            status=1;state[0 if kind == 'scan' else 1]='1'
            output+='  [ERROR] Cannot build the static ELF library cache\n' if kind == 'scan' else '  [WARN] Cannot refresh the static ELF library cache after the rebuild\n'
            output+=diagnostics(['supplied cache error'])
        else:
            file('ELF_LIBRARY_CACHE','supplied cache\n');broken=[];errors=[]
            if kind == 'scan':
                call('find',scan,'(','-type','f','-o','-type','l',')','-print0')
                selected_names=[] if fault == 'find' else names
                candidates=[(str(scan/name),name) for name in selected_names if name not in ('text','dangling')]
            else:
                candidates=[]
                for path in lines:
                    if not path:continue
                    name=Path(path).name
                    if name in ('text','dangling'):
                        broken.append(path);errors.append('cannot statically re-inspect '+path)
                    elif name != 'missing':candidates.append((path,name))
            for path,name in candidates:
                resolved=str(scan/'broken') if name == 'link-broken' else path
                call('dependency',resolved,paths['ELF_LIBRARY_CACHE'])
                if name in ('broken','link-broken','nested/broken2','broken2','space name'):broken.append(path)
                elif name == 'error':
                    if kind == 'verify':broken.append(path)
                    errors.append(('readelf could not inspect ' if kind == 'scan' else 'readelf could not re-inspect ')+path)
            # Recheck diagnostics follow input order, independently of sorted result output.
            if kind == 'verify':
                errors=[]
                for path in lines:
                    if not path:continue
                    name=Path(path).name
                    if name in ('text','dangling'):errors.append('cannot statically re-inspect '+path)
                    elif name == 'error':errors.append('readelf could not re-inspect '+path)
            value='' if fault == 'sort' else ''.join(path+'\n' for path in sorted(set(broken)))
            file('BROKEN_NEW' if kind == 'scan' else 'STILL_BROKEN',value)
            clear_failed = kind == 'verify' and fault in ('clear-directory','clear-link-directory')
            if clear_failed:
                assert not value
                call('block-clear',fault)
                expected['saved-broken']=expected[Path(paths['BROKEN']).name]
                if fault == 'clear-directory':expected[Path(paths['BROKEN']).name]=('dir',)
                else:
                    expected['clear-target']=('dir',)
                    expected[Path(paths['BROKEN']).name]=('link',str(root/'clear-target'))
                stderr_pattern=re.escape(str(REFERENCE))+r': line [1-9][0-9]*: '+re.escape(paths['BROKEN'])+r': Is a directory\n'
            pipeline_failed = fault in ('sort','sort-partial') or (kind == 'scan' and (fault in ('find','find-partial') or profile == 'missing-root'))
            if pipeline_failed:
                status=1;state[0 if kind == 'scan' else 1]='1'
                output+=('  [ERROR] Cannot enumerate or sort the static ELF scan results\n' if kind == 'scan' else '  [WARN] Cannot sort the static ELF verification results\n')+diagnostics(errors)
                if profile == 'missing-root':stderr=f"find: '{scan}': No such file or directory\n".encode()
            else:output+=diagnostics(errors)
            if kind == 'scan' and not pipeline_failed:
                call('wc','-l')
                if fault in ('wc','wc-partial'):
                    status=1;state[0]='1';output+='  [ERROR] Cannot count the static ELF scan results\n'
                else:
                    call('cp','-f','--',paths['BROKEN_NEW'],paths['BROKEN'])
                    if fault in ('cp','cp-partial'):
                        status=1;state[0]='1';output+='  [ERROR] Cannot publish the static ELF scan results\n'
                        if fault == 'cp-partial':file('BROKEN','supplied partial copy\n')
                    else:
                        file('BROKEN',value);state[2]=str(value.count('\n'));output+='  Broken ELF objects detected: '+state[2]+'\n'
            elif kind == 'verify' and not pipeline_failed and value:
                output+='  [WARN] ELF objects that still have unresolved dependencies:\n'+''.join('    '+line+'\n' for line in value.splitlines())
                call('cp','-f','--',paths['STILL_BROKEN'],paths['BROKEN'])
                if fault in ('cp','cp-partial'):
                    output+='  [WARN] Cannot publish the unresolved ELF verification results\n'
                    if fault == 'cp-partial':file('BROKEN','supplied partial copy\n')
                else:file('BROKEN',value)
                state[1]='1';status=1
            elif kind == 'verify' and not pipeline_failed:
                if clear_failed:
                    state[1]='1';status=1;output+='  [WARN] Cannot clear the resolved ELF object list\n'
                else:output+='  [OK] All previously broken ELF objects passed static verification\n';file('BROKEN','')
    values=paths|dict(FAULT=fault,ELF_SCAN_STATUS=9,ELF_VERIFICATION_STATUS=8,BROKEN_COUNT=7,ELF_LIBRARY_CACHE_RECORD_COUNT=6)
    assignments='\n'.join(key+'='+shlex.quote(str(value)) for key,value in values.items())
    entry={'scan':'detect_broken_elf_objects','verify':'verify_broken_elf_objects_after_rebuild','report':'report_static_elf_scan_errors'}[kind]
    suffix='\nELF_SCAN_PATHS=("$TEST_ROOT/scan")\nsaved_ifs=$IFS\nouter=kept\n'+entry+'\nraw=$?\n'
    suffix+='[[ $IFS == "$saved_ifs" && $outer == kept ]] || exit 96\nbuiltin printf "\\0STATE\\0%s\\0" "$raw"\n'
    suffix+='\n'.join('builtin printf "%s\\0" "${'+name+'}"' for name in FIELDS)+'\n'
    result=subprocess.run(['bash','--noprofile','--norc','-c',PREFIX+GUARDS+'\n'+assignments+suffix,
                           'elf-scan-test',str(REFERENCE),str(root)],capture_output=True,cwd=root,
                          env=dict(os.environ,LC_ALL='C',TMPDIR=str(root)),timeout=10)
    wanted=output.encode()+b'\0STATE\0'+str(status).encode()+b'\0'+b''.join(value.encode()+b'\0' for value in state)
    stderr_matches=bool(re.fullmatch(stderr_pattern,result.stderr.decode())) if stderr_pattern else result.stderr==stderr
    if (result.returncode,result.stdout)!=(0,wanted) or not stderr_matches:
        raise AssertionError(f'{kind}/{profile}/{fault}: expected {(0,wanted,stderr)!r}, got {(result.returncode,result.stdout,result.stderr)!r}')
    raw=(root/'trace').read_bytes() if (root/'trace').exists() else b''
    actual=[tuple(item.decode().split('\0')[:-1]) for item in raw.split(b'\n') if item]
    # Real find order is unspecified; cache-first, command vectors and multiplicity are checked.
    if Counter(actual)!=Counter(calls) or (calls and actual[0]!=calls[0]):raise AssertionError(f'{kind}/{profile}/{fault}: callback vectors differ')
    if kind != 'scan' and actual!=calls:raise AssertionError(f'{kind}/{profile}/{fault}: callback order differs')
    if inventory(root)!=expected:raise AssertionError(f'{kind}/{profile}/{fault}: private inventory differs')


def run():
    counts=dict.fromkeys(('scan','verify','report'),0)
    with tempfile.TemporaryDirectory(prefix='slack-update-elf-scan-') as tmp:
        parent=Path(tmp).resolve();index=0
        for kind,profiles,faults in [('scan',SCAN_PROFILES,('none','cache','find','find-partial','sort','sort-partial','cp','cp-partial','wc','wc-partial')),
                                      ('verify',VERIFY_PROFILES,('none','cache','sort','sort-partial','cp','cp-partial'))]:
            for profile,fault,old in itertools.product(profiles,faults,('','prior error\n')):
                root=parent/str(index);index+=1;root.mkdir();scenario(root,kind,profile,fault,old);counts[kind]+=1
        for old in ('','prior error\n'):
            root=parent/str(index);index+=1;root.mkdir();scenario(root,'scan','missing-root','none',old);counts['scan']+=1
        for profile,fault,old in itertools.product(('healthy','missing-object'),('clear-directory','clear-link-directory'),('','prior error\n')):
            root=parent/str(index);index+=1;root.mkdir();scenario(root,'verify',profile,fault,old);counts['verify']+=1
        for text in ('','one\n','one\ntwo\n','unterminated'):
            root=parent/str(index);index+=1;root.mkdir();scenario(root,'report',text,'none','');counts['report']+=1
    print('ELF scan workflow tests: '+', '.join(f'{count} {kind} entries' for kind,count in counts.items())+', 0 failures')


if __name__=='__main__':run()
