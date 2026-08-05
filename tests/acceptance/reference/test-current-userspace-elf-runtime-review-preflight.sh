#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_CONFIGURATION_REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-configuration-service-review-preflight.sh"
DEFAULT_CONFIGURATION_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-configuration-service-review-20260805-accepted.json"
DEFAULT_REVIEW_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-elf-runtime-review-policy.json"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-userspace-elf-runtime-review-preflight

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
CONFIGURATION_REVIEW_SCRIPT=$DEFAULT_CONFIGURATION_REVIEW_SCRIPT
CONFIGURATION_RECORD=$DEFAULT_CONFIGURATION_RECORD
REVIEW_POLICY=$DEFAULT_REVIEW_POLICY
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
EXPECTED_ELF_FILE_COUNT=0
EXPECTED_ELF_PACKAGE_COUNT=0
ELF_FILE_COUNT=0
ELF_PACKAGE_COUNT=0
DYNAMIC_OBJECT_COUNT=0
EXECUTABLE_OBJECT_COUNT=0
RELOCATABLE_OBJECT_COUNT=0
OTHER_OBJECT_COUNT=0
INTERPRETER_COUNT=0
NEEDED_EDGE_COUNT=0
UNIQUE_NEEDED_COUNT=0
TRANSACTION_SONAME_COUNT=0
HOST_RESOLVED_EDGE_COUNT=0
TRANSACTION_RESOLVED_EDGE_COUNT=0
UNRESOLVED_EDGE_COUNT=0
UNSAFE_RUNTIME_OBJECT_COUNT=0
ELF_RUNTIME_REVIEW_COMPLETE=false
NEXT_STAGE=manual-review-required

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Review the exact 722 ELF objects from the accepted Slackware-current
userspace transaction without installing packages or executing payload.
The preflight reruns the configuration/service review, verifies all exact
package identities and per-package ELF counts, and uses readelf plus the
read-only ldconfig cache to classify architecture, loader metadata, runtime
paths, hardening properties, and DT_NEEDED resolution.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --configuration-review-script PATH
      --configuration-record PATH
      --review-policy PATH
      --output-dir PATH
  -h, --help
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }

is_sha256() {
    [ "${#1}" -eq 64 ] || return 1
    case "$1" in *[!0-9A-Fa-f]*) return 1 ;; esac
}

is_safe_kernel_version() {
    case "$1" in ''|.|..|*/*|*[[:space:]]*|*[!A-Za-z0-9._+-]*) return 1 ;; *) return 0 ;; esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-candidates-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CANDIDATES_SHA256=$2; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --configuration-review-script) [ "$#" -ge 2 ] || return 1; CONFIGURATION_REVIEW_SCRIPT=$2; shift 2 ;;
            --configuration-record) [ "$#" -ge 2 ] || return 1; CONFIGURATION_RECORD=$2; shift 2 ;;
            --review-policy) [ "$#" -ge 2 ] || return 1; REVIEW_POLICY=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    local path
    for path in "$CONFIGURATION_REVIEW_SCRIPT" "$CONFIGURATION_RECORD" "$REVIEW_POLICY" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

capture_package_database() {
    local output=$1 root=/var/lib/pkgtools/packages item
    [ -d "$root" ] && [ ! -L "$root" ] || return 1
    : > "$output" || return 1
    while IFS= read -r -d '' item; do
        [ ! -L "$item" ] || return 1
        printf '%s\t%s\n' "${item##*/}" "$(sha256sum -- "$item" | awk '{print $1}')" >> "$output" || return 1
    done < <(find "$root" -maxdepth 1 -type f -print0 | LC_ALL=C sort -z)
    [ -s "$output" ]
}

capture_path_state() {
    local path=$1
    if [ -L "$path" ]; then
        printf 'symlink|%s|%s' "$(readlink -- "$path" 2>/dev/null || true)" "$(readlink -e -- "$path" 2>/dev/null || true)"
    elif [ -f "$path" ]; then
        printf 'regular|%s|%s' "$(stat -c '%a:%u:%g:%s:%Y' -- "$path")" "$(sha256sum -- "$path" | awk '{print $1}')"
    elif [ -d "$path" ]; then
        printf 'directory|%s|' "$(stat -c '%a:%u:%g:%Y' -- "$path")"
    else
        printf 'missing||'
    fi
}

capture_sensitive_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in \
        /boot/vmlinuz-generic "/boot/vmlinuz-$(uname -r)" \
        /boot/initrd-generic.img "/boot/initrd-$(uname -r).img" \
        /boot/initrd.gz /boot/grub/grub.cfg /etc/default/geninitrd \
        /etc/mkinitrd.conf /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia \
        /var/lib/dkms; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

validate_accepted_records() {
    python3 - "$CONFIGURATION_RECORD" "$REVIEW_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import hashlib, json, re, sys
record_path, policy_path, confirmed_digest, confirmed_target = sys.argv[1:]
try:
    record=json.load(open(record_path, encoding='utf-8'))
    policy=json.load(open(policy_path, encoding='utf-8'))
except Exception:
    raise SystemExit(1)

def digest(value): return isinstance(value,str) and re.fullmatch(r'[0-9a-f]{64}',value) is not None
def denied(value): return value.get('apply_ready') is False and value.get('apply_authorized') is False
packages=policy.get('reviewed_packages',[])
manifest=''.join(f"{x.get('package')}\t{x.get('sha256')}\t{x.get('size')}\t{x.get('expected_elf_count')}\n" for x in sorted(packages,key=lambda x:x.get('package',''))).encode()
elf_manifest=''.join(f"{x.get('package')}\t{x.get('expected_elf_count')}\n" for x in sorted(packages,key=lambda x:x.get('package','')) if x.get('expected_elf_count')).encode()
checks=[
 record.get('scenario')=='current-userspace-configuration-service-review-preflight', record.get('target')=='slackware-current',
 record.get('accepted') is True, denied(record), digest(record.get('archive_sha256')), digest(record.get('nested_maintainer_archive_sha256')),
 record.get('candidate_set_sha256')==confirmed_digest, record.get('target_kernel')==confirmed_target,
 record.get('expected_package_count')==record.get('inspected_package_count')==68, record.get('elf_file_count')==722,
 record.get('configuration_path_count')==46, record.get('service_path_count')==44,
 record.get('configuration_service_review_complete') is True, record.get('elf_runtime_review_complete') is False,
 record.get('userspace_apply_review_complete') is False, record.get('package_transaction_executed') is False,
 record.get('configuration_file_executed') is False, record.get('service_file_executed') is False,
 record.get('service_control_executed') is False, record.get('package_database_unchanged') is True,
 record.get('service_sensitive_state_unchanged') is True, record.get('assertions')=={'passes':15,'failures':0},
 record.get('evidence',{}).get('copied_to')=='/home/promano', record.get('evidence',{}).get('destination_verification')=='passed',
 record.get('next_stage')=='current-userspace-elf-runtime-review-preflight',
 policy.get('scenario')=='current-userspace-elf-runtime-review-policy', policy.get('target')=='slackware-current',
 policy.get('reviewed') is True, denied(policy), policy.get('candidate_set_sha256')==confirmed_digest,
 policy.get('target_kernel')==confirmed_target, policy.get('accepted_configuration_service_archive_sha256')==record.get('archive_sha256'),
 policy.get('accepted_nested_maintainer_archive_sha256')==record.get('nested_maintainer_archive_sha256'),
 policy.get('expected_package_count')==len(packages)==68, len({x.get('package') for x in packages})==68,
 all(digest(x.get('sha256')) and isinstance(x.get('size'),int) and x.get('size')>0 and isinstance(x.get('expected_elf_count'),int) and x.get('expected_elf_count')>=0 for x in packages),
 policy.get('expected_elf_package_count')==sum(x.get('expected_elf_count',0)>0 for x in packages)==61,
 policy.get('expected_elf_file_count')==sum(x.get('expected_elf_count',0) for x in packages)==722,
 policy.get('reviewed_package_elf_manifest_sha256')==hashlib.sha256(manifest).hexdigest(),
 policy.get('elf_count_manifest_sha256')==hashlib.sha256(elf_manifest).hexdigest(),
 policy.get('required_identity')=={'class':'ELF64','data':"2's complement, little endian",'machine':'Advanced Micro Devices X86-64'},
 policy.get('allowed_program_interpreters')==['/lib64/ld-linux-x86-64.so.2'],
 policy.get('reject_needed_entries_with_slashes') is True, policy.get('reject_unresolved_dependencies') is True,
 policy.get('reject_text_relocations') is True, policy.get('reject_executable_stack') is True,
 policy.get('reject_writable_executable_load_segments') is True, policy.get('require_nonexecuting_readelf_review') is True,
 policy.get('configuration_service_review_complete') is True, policy.get('elf_runtime_review_complete') is False,
 policy.get('userspace_apply_review_complete') is False, policy.get('next_stage')=='current-userspace-apply-review-preflight',
]
if not all(checks): raise SystemExit(1)
print(policy['expected_elf_file_count'])
print(policy['expected_elf_package_count'])
PY
}

validate_nested_configuration_review() {
    local directory=$1
    [ -f "$directory/summary.txt" ] || return 1
    [ -f "$directory/configuration-service-summary.json" ] || return 1
    [ -f "$directory/nested/maintainer-review/nested/payload-review/package-payload-summary.json" ] || return 1
    [ -f "$directory/nested/maintainer-review/nested/payload-review/payload-inventory.tsv" ] || return 1
    [ -f "$directory/nested/maintainer-review/nested/payload-review/cached-packages.tsv" ] || return 1
    python3 - "$directory" "$CONFIGURATION_RECORD" "$REVIEW_POLICY" <<'PY'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1]); record=json.load(open(sys.argv[2])); policy=json.load(open(sys.argv[3]))
summary={}
for raw in (root/'summary.txt').read_text().splitlines():
    if '=' in raw:
        k,v=raw.split('=',1); summary[k]=v
config=json.load(open(root/'configuration-service-summary.json'))
payload=json.load(open(root/'nested/maintainer-review/nested/payload-review/package-payload-summary.json'))
expected={x['package']:(x['sha256'],x['size'],x['expected_elf_count']) for x in policy['reviewed_packages']}
observed={x['filename']:(x['sha256'],x['size'],x['elf']) for x in payload['packages']}
checks=[
 summary.get('scenario')=='current-userspace-configuration-service-review-preflight', summary.get('result')=='PASS',
 summary.get('candidate_set_sha256')==record.get('candidate_set_sha256'), summary.get('target_kernel')==record.get('target_kernel'),
 int(summary.get('configuration_path_count','-1'))==46, int(summary.get('service_path_count','-1'))==44,
 summary.get('configuration_service_review_complete')=='true', summary.get('elf_runtime_review_complete')=='false',
 summary.get('package_transaction_executed')=='false', summary.get('service_control_executed')=='false',
 summary.get('next_stage')=='current-userspace-elf-runtime-review-preflight', int(summary.get('passes','-1'))==15,
 int(summary.get('failures','-1'))==0, config.get('configuration_service_review_complete') is True,
 config.get('elf_runtime_review_complete') is False, config.get('configuration_files_executed') is False,
 config.get('service_files_executed') is False, config.get('service_control_executed') is False,
 payload.get('package_count')==68, payload.get('totals',{}).get('elf')==722,
 payload.get('payload_path_review_complete') is True, expected==observed,
]
if not all(checks): raise SystemExit(1)
PY
}

create_and_verify_nested_archive() {
    local nested_root=$1 directory=$2 archive sidecar
    archive=$nested_root/configuration-service-review.tar.gz
    sidecar=$archive.sha256
    tar -C "$nested_root" -czf "$archive" "$(basename -- "$directory")" || return 1
    (cd "$nested_root" && sha256sum -- "${archive##*/}" > "${sidecar##*/}") || return 1
    (cd "$nested_root" && sha256sum -c "${sidecar##*/}" >/dev/null) || return 1
}

analyze_elf_runtime() {
    local payload_dir=$1 inventory=$2 summary=$3 host_cache=$4 work_dir=$5
    python3 - "$payload_dir" "$REVIEW_POLICY" "$inventory" "$summary" "$host_cache" "$work_dir" <<'PY'
import collections, hashlib, json, os, pathlib, posixpath, re, subprocess, sys, tarfile
payload_dir=pathlib.Path(sys.argv[1]); policy=json.load(open(sys.argv[2],encoding='utf-8'))
inventory_path=pathlib.Path(sys.argv[3]); summary_path=pathlib.Path(sys.argv[4]); host_cache_path=pathlib.Path(sys.argv[5]); work_dir=pathlib.Path(sys.argv[6])
work_dir.mkdir(parents=True,exist_ok=True)
packages={x['package']:x for x in policy['reviewed_packages']}
cache={}
for raw in (payload_dir/'cached-packages.tsv').read_text(encoding='utf-8').splitlines():
    fields=raw.split('\t')
    if len(fields)!=4: raise SystemExit('malformed cached package manifest')
    name,path,digest,size=fields; cache[name]=(pathlib.Path(path),digest,int(size))
if set(cache)!=set(packages): raise SystemExit('cached package set changed')
for name,item in packages.items():
    path,digest,size=cache[name]
    if path.name!=name or not path.is_file() or path.is_symlink(): raise SystemExit(f'unsafe cached package path: {name}')
    if digest!=item['sha256'] or size!=item['size'] or path.stat().st_size!=size: raise SystemExit(f'cached package identity changed: {name}')
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''): h.update(block)
    if h.hexdigest()!=digest: raise SystemExit(f'cached package digest changed: {name}')

def package_name(filename):
    stem=filename
    for suffix in ('.txz','.tgz','.tbz','.tlz'):
        if stem.endswith(suffix): stem=stem[:-len(suffix)]
    parts=stem.rsplit('-',3)
    return parts[0] if len(parts)==4 else stem

replaced_names={package_name(name) for name in packages}
replaced_paths=set(); package_root=pathlib.Path('/var/lib/pkgtools/packages')
if package_root.is_dir() and not package_root.is_symlink():
    for record in package_root.iterdir():
        if not record.is_file() or record.is_symlink() or package_name(record.name) not in replaced_names: continue
        in_files=False
        for raw in record.read_text(encoding='utf-8',errors='replace').splitlines():
            if raw=='FILE LIST:': in_files=True; continue
            if not in_files or not raw or raw.startswith(('#','PACKAGE ')): continue
            value=raw.removeprefix('./').rstrip('/')
            if value and not value.startswith('/'): replaced_paths.add(value)

ld=subprocess.run(['ldconfig','-p'],stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,encoding='utf-8',errors='replace')
if ld.returncode!=0: raise SystemExit('ldconfig cache could not be read')
host=collections.defaultdict(set); host_rows=[]
for raw in ld.stdout.splitlines():
    m=re.match(r'\s*(\S+)\s+\(([^)]*)\)\s+=>\s+(\S+)\s*$',raw)
    if not m: continue
    soname,caps,path=m.groups()
    if 'x86-64' not in caps: continue
    if not path.startswith('/') or path.startswith(('/tmp/','/var/tmp/','/dev/shm/','/run/user/')): continue
    shadowed=path.lstrip('/') in replaced_paths or os.path.realpath(path).lstrip('/') in replaced_paths
    host_rows.append((soname,caps,path,'shadowed-by-transaction' if shadowed else 'available'))
    if not shadowed: host[soname].add(path)
host_cache_path.write_text('soname\tcapabilities\tpath\tstatus\n'+''.join(f'{a}\t{b}\t{c}\t{d}\n' for a,b,c,d in sorted(host_rows)),encoding='utf-8')
if not host and not replaced_paths: raise SystemExit('no compatible host libraries were parsed')

required=policy['required_identity']; allowed_interpreters=set(policy['allowed_program_interpreters'])
default_dirs=set(policy['default_runtime_directories']); allowed_roots=tuple(policy['allowed_runtime_path_roots']); forbidden_roots=tuple(policy['forbidden_runtime_path_roots'])

def run_readelf(args,path):
    cp=subprocess.run(['readelf','-W',*args,'--',str(path)],stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,encoding='utf-8',errors='replace')
    if cp.returncode!=0: raise SystemExit(f'readelf failed: {cp.stderr.strip()}')
    return cp.stdout

def parse_header(text):
    values={}
    for key in ('Class','Data','Machine','Type'):
        m=re.search(r'^\s*'+re.escape(key)+r':\s+(.+?)\s*$',text,re.M)
        if not m: raise SystemExit(f'missing ELF header field: {key}')
        values[key.lower()]=m.group(1).split(' (')[0] if key=='Type' else m.group(1)
    return values

def parse_dynamic(text):
    result={'needed':[],'soname':'','rpath':'','runpath':'','textrel':False}
    for raw in text.splitlines():
        if '(TEXTREL)' in raw: result['textrel']=True
        m=re.search(r'\((NEEDED|SONAME|RPATH|RUNPATH)\).*\[(.*?)\]',raw)
        if not m: continue
        tag,value=m.groups()
        if tag=='NEEDED': result['needed'].append(value)
        else: result[tag.lower()]=value
    result['needed']=sorted(set(result['needed']))
    return result

def parse_program(text):
    interpreter=''; executable_stack=False; wx_load=False
    m=re.search(r'Requesting program interpreter:\s*([^\]]+)\]',text)
    if m: interpreter=m.group(1).strip()
    for raw in text.splitlines():
        line=raw.strip()
        if line.startswith('GNU_STACK'):
            tokens=line.split()
            flags=''.join(x for x in tokens if re.fullmatch(r'[RWE]+',x))
            if 'E' in flags: executable_stack=True
        if line.startswith('LOAD'):
            tokens=line.split()
            flags=''.join(x for x in tokens if re.fullmatch(r'[RWE]+',x))
            if 'W' in flags and 'E' in flags: wx_load=True
    return interpreter,executable_stack,wx_load

def resolve_runtime_paths(value,object_path):
    if not value: return []
    origin=posixpath.dirname('/'+object_path.lstrip('/')); result=[]
    for component in value.split(':'):
        if not component: raise SystemExit(f'empty runtime path in {object_path}')
        component=component.replace('${ORIGIN}',origin).replace('$ORIGIN',origin)
        if '$' in component or not component.startswith('/'): raise SystemExit(f'unsafe runtime path in {object_path}: {component}')
        normalized=posixpath.normpath(component)
        if normalized=='.' or normalized.startswith(forbidden_roots): raise SystemExit(f'forbidden runtime path in {object_path}: {normalized}')
        if not any(normalized==root or normalized.startswith(root+'/') for root in allowed_roots): raise SystemExit(f'out-of-scope runtime path in {object_path}: {normalized}')
        result.append(normalized)
    return sorted(set(result))

objects=[]; observed_counts=collections.Counter(); temp=work_dir/'current.elf'
for package in sorted(packages):
    archive_path=cache[package][0]
    with tarfile.open(archive_path,mode='r|*') as archive:
        for member in archive:
            if not member.isfile(): continue
            stream=archive.extractfile(member)
            if stream is None: raise SystemExit(f'unreadable archive member: {package}:{member.name}')
            prefix=stream.read(4)
            if prefix!=b'\x7fELF': stream.close(); continue
            with temp.open('wb') as out:
                out.write(prefix)
                for block in iter(lambda:stream.read(1024*1024),b''): out.write(block)
            stream.close(); os.chmod(temp,0o600)
            name=posixpath.normpath(member.name.removeprefix('./'))
            header=parse_header(run_readelf(['-h'],temp))
            if header['class']!=required['class'] or header['data']!=required['data'] or header['machine']!=required['machine']:
                raise SystemExit(f'unreviewed ELF identity: {package}:{name}:{header}')
            dynamic=parse_dynamic(run_readelf(['-d'],temp))
            program=run_readelf(['-l'],temp)
            interpreter,exec_stack,wx_load=parse_program(program)
            if interpreter and interpreter not in allowed_interpreters: raise SystemExit(f'unsafe interpreter: {package}:{name}:{interpreter}')
            if dynamic['textrel']: raise SystemExit(f'TEXTREL object: {package}:{name}')
            if exec_stack: raise SystemExit(f'executable stack: {package}:{name}')
            if wx_load: raise SystemExit(f'writable executable LOAD segment: {package}:{name}')
            if any('/' in needed for needed in dynamic['needed']): raise SystemExit(f'DT_NEEDED contains slash: {package}:{name}')
            rdirs=resolve_runtime_paths(dynamic['rpath'],name)+resolve_runtime_paths(dynamic['runpath'],name)
            digest=hashlib.sha256(temp.read_bytes()).hexdigest()
            objects.append({'package':package,'path':name,'size':member.size,'sha256':digest,**header,**dynamic,'interpreter':interpreter,'runtime_dirs':sorted(set(rdirs)),'exec_stack':exec_stack,'wx_load':wx_load})
            observed_counts[package]+=1
            temp.unlink()
if temp.exists(): temp.unlink()
if sum(observed_counts.values())!=policy['expected_elf_file_count']: raise SystemExit('ELF total changed')
for package,item in packages.items():
    if observed_counts[package]!=item['expected_elf_count']: raise SystemExit(f'ELF count changed: {package}')

providers=collections.defaultdict(list)
for obj in objects:
    directory=posixpath.dirname('/'+obj['path'].lstrip('/'))
    aliases=[]
    if obj['soname']: aliases.append(obj['soname'])
    basename=posixpath.basename(obj['path'])
    if '.so' in basename: aliases.append(basename)
    for alias in set(aliases): providers[alias].append(directory)
transaction_sonames=set(providers); unresolved=[]; host_edges=0; transaction_edges=0; needed_names=set()
for obj in objects:
    search_dirs=default_dirs|set(obj['runtime_dirs'])
    for needed in obj['needed']:
        needed_names.add(needed)
        candidate_dirs=set(providers.get(needed,[]))
        if candidate_dirs & search_dirs:
            transaction_edges+=1; continue
        if needed in host:
            host_edges+=1; continue
        unresolved.append((obj['package'],obj['path'],needed,','.join(sorted(search_dirs))))
if unresolved:
    (work_dir/'unresolved.tsv').write_text('package\tpath\tneeded\tsearch_dirs\n'+''.join('\t'.join(row)+'\n' for row in unresolved),encoding='utf-8')
    raise SystemExit(f'{len(unresolved)} unresolved runtime dependencies')

types=collections.Counter(obj['type'] for obj in objects)
rows=['package\tpath\tsize\tsha256\ttype\tclass\tdata\tmachine\tinterpreter\tsoname\tneeded_count\tneeded\trpath\trunpath\truntime_dirs\n']
for obj in sorted(objects,key=lambda x:(x['package'],x['path'])):
    clean=lambda value:str(value).replace('\t',' ').replace('\n',' ')
    rows.append('\t'.join(clean(x) for x in (obj['package'],obj['path'],obj['size'],obj['sha256'],obj['type'],obj['class'],obj['data'],obj['machine'],obj['interpreter'],obj['soname'],len(obj['needed']),','.join(obj['needed']),obj['rpath'],obj['runpath'],','.join(obj['runtime_dirs'])))+'\n')
inventory_path.write_text(''.join(rows),encoding='utf-8')
summary={
 'scenario':'current-userspace-elf-runtime-review-preflight','elf_file_count':len(objects),'elf_package_count':sum(v>0 for v in observed_counts.values()),
 'dynamic_object_count':types.get('DYN',0),'executable_object_count':types.get('EXEC',0),'relocatable_object_count':types.get('REL',0),
 'other_object_count':len(objects)-types.get('DYN',0)-types.get('EXEC',0)-types.get('REL',0),
 'interpreter_count':sum(bool(x['interpreter']) for x in objects),'needed_edge_count':sum(len(x['needed']) for x in objects),
 'unique_needed_count':len(needed_names),'transaction_soname_count':len(transaction_sonames),
 'host_resolved_edge_count':host_edges,'transaction_resolved_edge_count':transaction_edges,'unresolved_edge_count':0,
 'unsafe_runtime_object_count':0,'text_relocation_count':0,'executable_stack_count':0,'writable_executable_load_segment_count':0,
 'exact_package_hashes_verified':True,'exact_per_package_elf_counts_verified':True,'required_elf_identity_verified':True,
 'readelf_only_payload_inspection':True,'payload_objects_executed':False,'dynamic_loader_tracing_executed':False,
 'configuration_service_review_complete':True,'elf_runtime_review_complete':True,'userspace_apply_review_complete':False,
 'next_stage':'current-userspace-apply-review-preflight','apply_ready':False,'apply_authorized':False,
}
summary_path.write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n',encoding='utf-8')
for value in (len(objects),sum(v>0 for v in observed_counts.values()),types.get('DYN',0),types.get('EXEC',0),types.get('REL',0),summary['other_object_count'],summary['interpreter_count'],summary['needed_edge_count'],summary['unique_needed_count'],summary['transaction_soname_count'],host_edges,transaction_edges,0,0): print(value)
PY
}

write_summary() {
    cat > "$1" <<EOF_SUMMARY
scenario=current-userspace-elf-runtime-review-preflight
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
target=$TARGET
candidate_set_sha256=$CONFIRM_CANDIDATES_SHA256
target_kernel=$CONFIRM_TARGET_KERNEL
expected_elf_file_count=$EXPECTED_ELF_FILE_COUNT
elf_file_count=$ELF_FILE_COUNT
expected_elf_package_count=$EXPECTED_ELF_PACKAGE_COUNT
elf_package_count=$ELF_PACKAGE_COUNT
dynamic_object_count=$DYNAMIC_OBJECT_COUNT
executable_object_count=$EXECUTABLE_OBJECT_COUNT
relocatable_object_count=$RELOCATABLE_OBJECT_COUNT
other_object_count=$OTHER_OBJECT_COUNT
interpreter_count=$INTERPRETER_COUNT
needed_edge_count=$NEEDED_EDGE_COUNT
unique_needed_count=$UNIQUE_NEEDED_COUNT
transaction_soname_count=$TRANSACTION_SONAME_COUNT
host_resolved_edge_count=$HOST_RESOLVED_EDGE_COUNT
transaction_resolved_edge_count=$TRANSACTION_RESOLVED_EDGE_COUNT
unresolved_edge_count=$UNRESOLVED_EDGE_COUNT
unsafe_runtime_object_count=$UNSAFE_RUNTIME_OBJECT_COUNT
package_payloads_inspected=true
payload_path_review_complete=true
maintainer_scripts_review_complete=true
configuration_service_review_complete=true
elf_runtime_review_complete=$ELF_RUNTIME_REVIEW_COMPLETE
userspace_apply_review_complete=false
package_transaction_executed=false
maintainer_script_executed=false
configuration_file_executed=false
service_file_executed=false
service_control_executed=false
elf_payload_executed=false
dynamic_loader_tracing_executed=false
mkinitrd_executed=false
geninitrd_executed=false
dkms_action_executed=false
grub_update_executed=false
next_stage=$NEXT_STAGE
apply_ready=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-userspace-elf-runtime-review-preflight-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive"
    (cd "$(dirname -- "$archive")" && sha256sum -- "$(basename -- "$archive")" > "$(basename -- "$sidecar")") || return 1
    chmod 0600 -- "$sidecar"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    if id "$owner" >/dev/null 2>&1; then
        group=$(id -gn "$owner")
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
            "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
        printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${sidecar##*/}"
    fi
}

main() {
    local timestamp nested_root nested_dir nested_exit=0 values work_dir
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this acceptance preflight must run as root'; return 2; }
    for tool in bash python3 sha256sum find sort tar stat readelf ldconfig; do
        command -v "$tool" >/dev/null 2>&1 || { error "required command is missing: $tool"; return 2; }
    done
    bash -n "$CONFIGURATION_REVIEW_SCRIPT" || { error 'configuration/service review script has invalid syntax'; return 2; }
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    mkdir -p "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if values=$(validate_accepted_records); then
        EXPECTED_ELF_FILE_COUNT=$(printf '%s\n' "$values" | sed -n '1p')
        EXPECTED_ELF_PACKAGE_COUNT=$(printf '%s\n' "$values" | sed -n '2p')
        record_pass 'the accepted configuration/service review and ELF policy bind the exact 722-object inspection'
    else
        record_failure 'the accepted configuration/service record or ELF policy is unsafe or inconsistent'
    fi
    [ "$CONFIRM_CANDIDATES_SHA256" = 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 ] \
        && [ "$CONFIRM_TARGET_KERNEL" = 6.18.42 ] \
        && record_pass 'the explicit candidate digest and target kernel match the reviewed ELF runtime boundary' \
        || record_failure 'the explicit candidate digest or target kernel does not match the reviewed ELF runtime boundary'
    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and runtime-sensitive state were captured before static ELF review'
    else
        record_failure 'the initial package or runtime-sensitive state could not be captured safely'
    fi

    nested_root=$OUTPUT_DIR/nested
    nested_dir=$nested_root/configuration-service-review
    mkdir -p "$nested_root"
    printf 'Running a fresh non-installing configuration/service review before ELF classification...\n'
    bash "$CONFIGURATION_REVIEW_SCRIPT" --target slackware-current \
        --confirm-candidates-sha256 "$CONFIRM_CANDIDATES_SHA256" \
        --confirm-target-kernel "$CONFIRM_TARGET_KERNEL" \
        --output-dir "$nested_dir" \
        > "$OUTPUT_DIR/configuration-review.stdout.log" 2> "$OUTPUT_DIR/configuration-review.stderr.log" || nested_exit=$?
    printf '%s\n' "$nested_exit" > "$OUTPUT_DIR/configuration-review.exit"
    cat "$OUTPUT_DIR/configuration-review.stdout.log"
    [ -s "$OUTPUT_DIR/configuration-review.stderr.log" ] && cat "$OUTPUT_DIR/configuration-review.stderr.log" >&2 || true
    [ "$nested_exit" -eq 0 ] \
        && record_pass 'the embedded configuration/service review completed without installing or executing payload' \
        || record_failure "the embedded configuration/service review failed with exit code $nested_exit"
    [ "$nested_exit" -eq 0 ] && validate_nested_configuration_review "$nested_dir" \
        && record_pass 'the fresh nested evidence still contains the exact 68 packages and 722 ELF objects' \
        || record_failure 'the nested configuration/service evidence changed before ELF review'
    create_and_verify_nested_archive "$nested_root" "$nested_dir" \
        && record_pass 'the nested configuration/service archive and portable sidecar verify inside the ELF evidence' \
        || record_failure 'the nested configuration/service archive or portable sidecar is invalid'

    work_dir=$OUTPUT_DIR/.elf-work
    if values=$(analyze_elf_runtime \
        "$nested_dir/nested/maintainer-review/nested/payload-review" \
        "$OUTPUT_DIR/elf-runtime-inventory.tsv" "$OUTPUT_DIR/elf-runtime-summary.json" \
        "$OUTPUT_DIR/host-library-cache.tsv" "$work_dir"); then
        ELF_FILE_COUNT=$(printf '%s\n' "$values" | sed -n '1p')
        ELF_PACKAGE_COUNT=$(printf '%s\n' "$values" | sed -n '2p')
        DYNAMIC_OBJECT_COUNT=$(printf '%s\n' "$values" | sed -n '3p')
        EXECUTABLE_OBJECT_COUNT=$(printf '%s\n' "$values" | sed -n '4p')
        RELOCATABLE_OBJECT_COUNT=$(printf '%s\n' "$values" | sed -n '5p')
        OTHER_OBJECT_COUNT=$(printf '%s\n' "$values" | sed -n '6p')
        INTERPRETER_COUNT=$(printf '%s\n' "$values" | sed -n '7p')
        NEEDED_EDGE_COUNT=$(printf '%s\n' "$values" | sed -n '8p')
        UNIQUE_NEEDED_COUNT=$(printf '%s\n' "$values" | sed -n '9p')
        TRANSACTION_SONAME_COUNT=$(printf '%s\n' "$values" | sed -n '10p')
        HOST_RESOLVED_EDGE_COUNT=$(printf '%s\n' "$values" | sed -n '11p')
        TRANSACTION_RESOLVED_EDGE_COUNT=$(printf '%s\n' "$values" | sed -n '12p')
        UNRESOLVED_EDGE_COUNT=$(printf '%s\n' "$values" | sed -n '13p')
        UNSAFE_RUNTIME_OBJECT_COUNT=$(printf '%s\n' "$values" | sed -n '14p')
        record_pass 'all 68 cached archives retain their exact identities and per-package ELF counts'
        record_pass 'all 722 ELF objects retain the reviewed x86-64 little-endian identity'
        record_pass 'all interpreters and runtime search paths remain confined to reviewed system roots'
        record_pass 'no TEXTREL, executable stack, or writable-executable LOAD segment was found'
        record_pass 'every DT_NEEDED edge resolves through the read-only host cache or reviewed transaction libraries'
    else
        record_failure 'one or more ELF objects contain unsafe metadata or unresolved runtime dependencies'
    fi
    rm -rf -- "$work_dir"

    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$ELF_FILE_COUNT" -eq "$EXPECTED_ELF_FILE_COUNT" ] \
            && [ "$ELF_PACKAGE_COUNT" -eq "$EXPECTED_ELF_PACKAGE_COUNT" ] \
            && [ "$UNRESOLVED_EDGE_COUNT" -eq 0 ] && [ "$UNSAFE_RUNTIME_OBJECT_COUNT" -eq 0 ]; then
        ELF_RUNTIME_REVIEW_COMPLETE=true
        NEXT_STAGE=current-userspace-apply-review-preflight
        record_pass 'the ELF runtime review is complete while userspace apply review remains pending'
    else
        ELF_RUNTIME_REVIEW_COMPLETE=false
        NEXT_STAGE=manual-review-required
        record_failure 'the ELF runtime boundary could not be completed safely'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and runtime-sensitive state were captured after static ELF review' \
        || record_failure 'the final package or runtime-sensitive state could not be captured safely'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && record_pass 'the installed package database remained unchanged during ELF review' \
        || record_failure 'the installed package database changed during ELF review'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged during ELF review' \
        || record_failure 'the runtime-sensitive system state changed during review'

    [ "$FAILURE_COUNT" -eq 0 ] || { ELF_RUNTIME_REVIEW_COMPLETE=false; NEXT_STAGE=manual-review-required; }
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current ELF runtime review result: candidates=%s, elf=%s, packages=%s, dynamic=%s, executable=%s, relocatable=%s, needed=%s, unresolved=%s, unsafe=%s, elf-runtime-review-complete=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' \
        "$CONFIRM_CANDIDATES_SHA256" "$ELF_FILE_COUNT" "$ELF_PACKAGE_COUNT" "$DYNAMIC_OBJECT_COUNT" \
        "$EXECUTABLE_OBJECT_COUNT" "$RELOCATABLE_OBJECT_COUNT" "$NEEDED_EDGE_COUNT" "$UNRESOLVED_EDGE_COUNT" \
        "$UNSAFE_RUNTIME_OBJECT_COUNT" "$ELF_RUNTIME_REVIEW_COMPLETE" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
