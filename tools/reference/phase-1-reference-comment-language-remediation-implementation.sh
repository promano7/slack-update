#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-reference-comment-language-remediation-implementation.sh --apply [--output-dir DIR]
       phase-1-reference-comment-language-remediation-implementation.sh --verify [--output-dir DIR]
       phase-1-reference-comment-language-remediation-implementation.sh --help

Apply or verify the exact step-167 authorized comment translations in
 tools/reference/slack-update-reference.sh. No executable shell code, runtime
string, heredoc payload, non-defect comment, package state, boot state, network
state, or machine state is authorized to change.
USAGE
}

mode=
output_dir=
while (($#)); do
    case "$1" in
        --apply|--verify)
            [[ -z $mode ]] || { printf 'ERROR: exactly one mode is required\n' >&2; exit 2; }
            mode=${1#--}
            shift
            ;;
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done
[[ -n $mode ]] || { printf 'ERROR: --apply or --verify is required\n' >&2; exit 2; }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
target="$repo_root/tools/reference/slack-update-reference.sh"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design-policy.json"
design_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design.tsv"
audit_helper="$repo_root/tools/reference/phase-1-reference-comment-language-audit-execution.sh"
helper_path="$repo_root/tools/reference/phase-1-reference-comment-language-remediation-implementation.sh"

if [[ -z $output_dir ]]; then
    output_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
fi
policy="$output_dir/phase-1-reference-comment-language-remediation-implementation-policy.json"
record="$output_dir/phase-1-reference-comment-language-remediation-implementation.tsv"

for file in "$target" "$design_policy" "$design_record" "$audit_helper" "$helper_path"; do
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
done
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 4; }

python3 - "$mode" "$target" "$design_policy" "$design_record" "$audit_helper" "$helper_path" "$policy" "$record" <<'PY_IMPL'
import csv
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

mode=sys.argv[1]
target=Path(sys.argv[2])
design_policy=Path(sys.argv[3])
design_record=Path(sys.argv[4])
audit_helper=Path(sys.argv[5])
helper_path=Path(sys.argv[6])
policy_path=Path(sys.argv[7])
record_path=Path(sys.argv[8])

translations={
'D001': 'Log rotation — keep only the last 30 days.',
'D002': 'FIX #10: Rotation runs BEFORE opening the log for this execution,',
'D003': 'so it can never delete the current run-$DATE.log file.',
'D004': 'Redirect logging while filtering ANSI codes',
'D005': 'FIX #10: Emoji characters are removed from the log to avoid encoding problems in cron.',
'D006': 'Console output (when run interactively) will still display them',
'D007': 'because tee writes to stdout before the ANSI filter.',
'D008': 'FIX #3: Accumulate in a temporary file and merge to avoid contaminating QUEUE_EXTRA',
'D009': 'with data from previous runs when ABI was not triggered (block [7]).',
'D010': 'FIX #4: Anchor with grep -P to cover paths with and without a leading slash',
'D011': "in /var/log/packages manifests (some omit the initial '/').",
'D012': 'FIX #5: Replaced \'sbopkg -b -i "long string"\' with \'sbopkg -b -B file\'.',
'D013': 'Passing all packages as a single string with -i can exceed ARG_MAX',
'D014': 'when the queue is large. Using -B with the .sqf file is more robust and is',
'D015': 'the form recommended by sbopkg for package lists.',
'D016': 'FIX #10: Emoji characters removed to avoid encoding problems in environments',
'D017': 'where cron has no UTF-8 locale. They are replaced with plain-text markers.',
}
expected_old={
'D001': 'Rotacion de logs — conservar solo los ultimos 30 dias.',
'D002': 'FIX #10: La rotacion se ejecuta ANTES de abrir el log de esta ejecucion,',
'D003': 'por lo que nunca puede borrar el fichero run-$DATE.log actual.',
'D004': 'Redirigir log filtrando codigos ANSI',
'D005': 'FIX #10: Se eliminan emojis del log para evitar problemas de encoding en cron.',
'D006': 'La salida de consola (si se ejecuta interactivamente) los mostrara igualmente',
'D007': 'porque el tee escribe a stdout antes del filtro de ANSI.',
'D008': 'FIX #3: Acumular en temporal y hacer merge para no contaminar QUEUE_EXTRA',
'D009': 'con datos de ejecuciones anteriores cuando ABI no disparo (bloque [7]).',
'D010': 'FIX #4: Anclar con grep -P para cubrir rutas con y sin barra inicial',
'D011': "en los manifiestos de /var/log/packages (algunos omiten el '/' inicial).",
'D012': 'FIX #5: Sustituido \'sbopkg -b -i "string largo"\' por \'sbopkg -b -B fichero\'.',
'D013': 'Pasar todos los paquetes como un unico string con -i puede superar ARG_MAX',
'D014': 'cuando la cola es grande. Usar -B con el fichero .sqf es mas robusto y es',
'D015': 'la forma recomendada por sbopkg para listas de paquetes.',
'D016': 'FIX #10: Eliminados emojis para evitar problemas de encoding en entornos',
'D017': 'cron sin locale UTF-8. Se sustituyen por marcadores de texto plano.',
}

def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def sha_file(path: Path) -> str:
    return sha_bytes(path.read_bytes())

def comment_index(line: str):
    single=False
    double=False
    escaped=False
    for i,ch in enumerate(line):
        if escaped:
            escaped=False
            continue
        if ch == '\\' and not single:
            escaped=True
            continue
        if ch == "'" and not double:
            single=not single
            continue
        if ch == '"' and not single:
            double=not double
            continue
        if ch == '#' and not single and not double:
            if i == 0 or line[i-1].isspace() or line[i-1] in ';|&()<>':
                return i
    return None

def split_comment(line: str):
    idx=comment_index(line)
    if idx is None:
        raise AssertionError('authorized line no longer contains a syntactic shell comment')
    suffix=line[idx+1:]
    leading=suffix[:len(suffix)-len(suffix.lstrip())]
    return idx, line[:idx+1], leading, suffix.strip()

with design_policy.open(encoding='utf-8') as h:
    design=json.load(h)
with design_record.open(encoding='utf-8',newline='') as h:
    rows=list(csv.DictReader(h,delimiter='\t'))

assert design['scenario']=='phase-1-reference-comment-language-remediation-design'
assert design['authorization']['source_change_authorized'] is True
assert design['authorization']['source_change_scope']=='only defect rows frozen by this design record'
assert design['remediation_design']['authorized_rows']==len(rows)==17
assert design['remediation_design']['preserve_line_count'] is True
assert design['remediation_design']['preserve_nondefect_comments'] is True
assert design['remediation_design']['code_changes_forbidden'] is True
assert design['next_stage']=='phase-1-reference-comment-language-remediation-implementation'
assert {r['defect_id'] for r in rows}==set(translations)==set(expected_old)
for r in rows:
    did=r['defect_id']
    assert r['comment_text']==expected_old[did]
    assert r['comment_sha256']==hashlib.sha256(expected_old[did].encode()).hexdigest()
    assert r['authorized_change']=='translate-comment-payload-to-English'
    assert r['preserve_code_prefix']=='yes'
    assert r['preserve_line_count']=='yes'
    assert r['disposition']=='authorized-for-step-168'

before_sha=design['accepted_audit']['target_sha256']
design_policy_sha=sha_file(design_policy)
design_record_sha=sha_file(design_record)
helper_sha=sha_file(helper_path)
audit_helper_sha=sha_file(audit_helper)
original_bytes=target.read_bytes()
original_text=original_bytes.decode('utf-8')
original_lines=original_text.splitlines(keepends=True)

# Transform or verify one authorized line while preserving the code prefix,
# comment delimiter, whitespace after the delimiter, and line terminator.
def transform_line(line: str, old: str, new: str, direction: str):
    ending='\n' if line.endswith('\n') else ''
    body=line[:-1] if ending else line
    if body.endswith('\r'):
        cr='\r'
        core=body[:-1]
    else:
        cr=''
        core=body
    idx,prefix,leading,text=split_comment(core)
    expected=old if direction=='forward' else new
    replacement=new if direction=='forward' else old
    assert text==expected
    assert hashlib.sha256(text.encode()).hexdigest()==hashlib.sha256(expected.encode()).hexdigest()
    return prefix+leading+replacement+cr+ending, prefix, leading

if mode=='apply':
    current_sha=sha_bytes(original_bytes)
    if current_sha != before_sha:
        if policy_path.exists() and record_path.exists():
            try:
                existing=json.loads(policy_path.read_text(encoding='utf-8'))
            except Exception:
                existing={}
            if existing.get('implementation',{}).get('source_after_sha256')==current_sha:
                mode='verify'
            else:
                raise AssertionError(f'target SHA-256 is not the authorized pre-change hash: {current_sha}')

if mode=='apply':
    new_lines=list(original_lines)
    output_rows=[]
    authorized_indexes=set()
    for r in rows:
        did=r['defect_id']
        line_number=int(r['line_number'])
        idx=line_number-1
        assert 0 <= idx < len(new_lines)
        changed,prefix,leading=transform_line(new_lines[idx], expected_old[did], translations[did], 'forward')
        new_lines[idx]=changed
        authorized_indexes.add(idx)
        output_rows.append({
            'defect_id':did,
            'line_number':str(line_number),
            'before_sha256':r['comment_sha256'],
            'after_sha256':hashlib.sha256(translations[did].encode()).hexdigest(),
            'before_text':expected_old[did],
            'after_text':translations[did],
            'code_prefix_preserved':'yes',
            'line_count_preserved':'yes',
        })
    assert len(authorized_indexes)==17
    new_text=''.join(new_lines)
    new_bytes=new_text.encode('utf-8')
    assert len(new_lines)==len(original_lines)
    # Reverse the authorized translations and prove that the exact pre-change
    # byte stream is reconstructed. This excludes any non-authorized change.
    reverse_lines=list(new_lines)
    for r in rows:
        did=r['defect_id']
        idx=int(r['line_number'])-1
        reverse_lines[idx],_,_=transform_line(reverse_lines[idx], expected_old[did], translations[did], 'reverse')
    assert ''.join(reverse_lines).encode('utf-8')==original_bytes
    assert sha_bytes(original_bytes)==before_sha

    with tempfile.TemporaryDirectory() as td:
        candidate=Path(td)/'slack-update-reference.sh'
        candidate.write_bytes(new_bytes)
        candidate.chmod(stat.S_IMODE(target.stat().st_mode))
        subprocess.run(['bash','-n',str(candidate)],check=True)

    old_mode=stat.S_IMODE(target.stat().st_mode)
    backup=target.with_name(target.name+'.step168-rollback')
    if backup.exists():
        raise AssertionError(f'rollback path already exists: {backup}')
    target.rename(backup)
    try:
        target.write_bytes(new_bytes)
        target.chmod(old_mode)
        subprocess.run(['bash','-n',str(target)],check=True)
        with tempfile.TemporaryDirectory() as td:
            subprocess.run([str(audit_helper),'--output-dir',td],check=True,stdout=subprocess.DEVNULL)
            rp=Path(td)/'phase-1-reference-comment-language-audit-execution-policy.json'
            rr=Path(td)/'phase-1-reference-comment-language-audit-execution.tsv'
            reaudit=json.loads(rp.read_text(encoding='utf-8'))
            reaudit_policy_sha=sha_file(rp)
            reaudit_record_sha=sha_file(rr)
        a=reaudit['audit']
        assert a['language_defects']==0
        assert a['conformance_pass'] is True
    except Exception:
        if target.exists(): target.unlink()
        backup.rename(target)
        raise
    else:
        backup.unlink()

    after_sha=sha_file(target)
    record_path.parent.mkdir(parents=True,exist_ok=True)
    with record_path.open('w',encoding='utf-8',newline='') as h:
        fields=['defect_id','line_number','before_sha256','after_sha256','before_text','after_text','code_prefix_preserved','line_count_preserved']
        w=csv.DictWriter(h,fieldnames=fields,delimiter='\t',lineterminator='\n')
        w.writeheader(); w.writerows(output_rows)
    data={
      'schema':1,
      'scenario':'phase-1-reference-comment-language-remediation-implementation',
      'review_only':False,
      'accepted_design':{
        'step':167,
        'policy_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design-policy.json',
        'policy_sha256':design_policy_sha,
        'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design.tsv',
        'record_sha256':design_record_sha,
      },
      'implementation':{
        'target_path':'tools/reference/slack-update-reference.sh',
        'source_before_sha256':before_sha,
        'source_after_sha256':after_sha,
        'authorized_translations':len(rows),
        'changed_lines':len(rows),
        'line_count_preserved':True,
        'code_prefix_preserved':True,
        'nonauthorized_change_detected':False,
        'reverse_reconstruction_matches_source_before':True,
        'bash_n_pass':True,
        'source_modified':True,
      },
      'reaudit':{
        'helper_path':'tools/reference/phase-1-reference-comment-language-audit-execution.sh',
        'helper_sha256':audit_helper_sha,
        'inventory_complete':a['inventory_complete'],
        'total_comments':a['total_comments'],
        'english_prose':a['english_prose'],
        'technical_directive':a['technical_directive'],
        'code_fragment':a['code_fragment'],
        'language_defects':a['language_defects'],
        'conformance_pass':a['conformance_pass'],
        'ephemeral_policy_sha256':reaudit_policy_sha,
        'ephemeral_record_sha256':reaudit_record_sha,
      },
      'authorization':{
        'source_change_authorized':False,
        'repository_refresh_authorized':False,
        'network_refresh_authorized':False,
        'machine_execution_authorized':False,
        'package_action_authorized':False,
        'boot_action_authorized':False,
        'phase_2_start_authorized':False,
        'future_work_requires_explicit_authorization':True,
      },
      'helper_path':'tools/reference/phase-1-reference-comment-language-remediation-implementation.sh',
      'helper_sha256':helper_sha,
      'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation.tsv',
      'next_stage':'phase-1-reference-comment-language-remediation-closure-review',
      'slackware_current_publication_invalidates_implementation':False,
      'pause_safe':False,
    }
    policy_path.write_text(json.dumps(data,indent=2,sort_keys=False)+'\n',encoding='utf-8')

# Verification is intentionally reversible: reconstruct the exact pre-change
# source from the accepted translations and compare its SHA-256 with step 167.
with policy_path.open(encoding='utf-8') as h:
    policy=json.load(h)
with record_path.open(encoding='utf-8',newline='') as h:
    applied=list(csv.DictReader(h,delimiter='\t'))
assert policy['scenario']=='phase-1-reference-comment-language-remediation-implementation'
assert policy['accepted_design']['policy_sha256']==design_policy_sha
assert policy['accepted_design']['record_sha256']==design_record_sha
assert policy['implementation']['source_before_sha256']==before_sha
assert policy['implementation']['source_after_sha256']==sha_file(target)
assert policy['implementation']['authorized_translations']==len(applied)==len(rows)==17
assert policy['implementation']['nonauthorized_change_detected'] is False
assert policy['implementation']['reverse_reconstruction_matches_source_before'] is True
assert policy['implementation']['bash_n_pass'] is True
assert policy['reaudit']['language_defects']==0
assert policy['reaudit']['conformance_pass'] is True
assert policy['next_stage']=='phase-1-reference-comment-language-remediation-closure-review'
assert policy['pause_safe'] is False
subprocess.run(['bash','-n',str(target)],check=True)
current_lines=target.read_text(encoding='utf-8').splitlines(keepends=True)
reverse_lines=list(current_lines)
by_id={r['defect_id']:r for r in applied}
assert set(by_id)==set(translations)
for r in rows:
    did=r['defect_id']
    ar=by_id[did]
    assert ar['before_text']==expected_old[did]
    assert ar['after_text']==translations[did]
    assert ar['before_sha256']==hashlib.sha256(expected_old[did].encode()).hexdigest()
    assert ar['after_sha256']==hashlib.sha256(translations[did].encode()).hexdigest()
    assert ar['code_prefix_preserved']=='yes'
    assert ar['line_count_preserved']=='yes'
    idx=int(r['line_number'])-1
    reverse_lines[idx],_,_=transform_line(reverse_lines[idx], expected_old[did], translations[did], 'reverse')
reconstructed=''.join(reverse_lines).encode('utf-8')
assert sha_bytes(reconstructed)==before_sha
with tempfile.TemporaryDirectory() as td:
    subprocess.run([str(audit_helper),'--output-dir',td],check=True,stdout=subprocess.DEVNULL)
    rp=Path(td)/'phase-1-reference-comment-language-audit-execution-policy.json'
    reaudit=json.loads(rp.read_text(encoding='utf-8'))
    assert reaudit['audit']['target_sha256']==sha_file(target)
    assert reaudit['audit']['language_defects']==0
    assert reaudit['audit']['conformance_pass'] is True

print(f"Source before SHA-256: {before_sha}")
print(f"Source after SHA-256: {sha_file(target)}")
print(f"Authorized translations applied: {len(rows)}")
print('Language defects after remediation: 0')
print('Conformance pass: true')
print('Next stage: phase-1-reference-comment-language-remediation-closure-review')
PY_IMPL
