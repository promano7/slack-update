#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-reference-comment-language-audit-execution.sh [--output-dir DIR] [--help]

Execute the read-only Phase 1 comment-language audit against
 tools/reference/slack-update-reference.sh. The audit inventories syntactic
shell comments, classifies comment prose, binds the result to the exact target
SHA-256, and writes deterministic TSV/JSON evidence. It never edits the target.
USAGE
}

output_dir=
while (($#)); do
    case "$1" in
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

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
target="$repo_root/tools/reference/slack-update-reference.sh"
contract_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze-policy.json"
contract_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze.tsv"

check_hash() {
    local file=$1 expected=$2 actual
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$contract_policy" '3df64c07bf2169f78add075ff0febaf04f3c418d8f1cbdb7435ebe9498209d4d'
check_hash "$contract_record" '74c5cbda7c4fd609844352747af29f4ffe24e84dd9ef934cb6671dcb25523743'
[[ -f $target && ! -L $target ]] || { printf 'ERROR: audit target missing or unsafe\n' >&2; exit 5; }

if [[ -z $output_dir ]]; then
    output_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 6; }

record="$output_dir/phase-1-reference-comment-language-audit-execution.tsv"
policy="$output_dir/phase-1-reference-comment-language-audit-execution-policy.json"
helper_path="$repo_root/tools/reference/phase-1-reference-comment-language-audit-execution.sh"

target_sha=$(sha256sum -- "$target" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$target" "$record" <<'PY_AUDIT'
import hashlib
import re
import sys
from pathlib import Path

target = Path(sys.argv[1])
record = Path(sys.argv[2])
lines = target.read_text(encoding='utf-8').splitlines()

strong_spanish = re.compile(
    r'(?i)\b(?:resumen|rotacion|redirigir|filtrando|codigos|eliminan|emojis|salida|consola|'
    r'ejecuta|interactivamente|mostrara|escribe|acumular|hacer|contaminar|datos|ejecuciones|'
    r'anteriores|disparo|bloque|anclar|cubrir|rutas|manifiestos|algunos|omiten|sustituido|'
    r'pasar|todos|paquetes|puede|superar|cola|grande|usar|forma|recomendada|listas|eliminados|'
    r'evitar|problemas|entornos|sustituyen|marcadores|texto|plano|conservar|ultimos|dias|'
    r'nunca|borrar|fichero|unico|robusto|actualizacion|recompilacion|librerias|reinicio|'
    r'cambios|sistema|modulos|configuracion|archivos|pendientes|revision|lectura|temporal)\b'
)
spanish_function = re.compile(r'(?i)\b(?:el|la|los|las|de|del|al|en|y|que|para|por|con|sin|se|si|no|un|una|unos|unas)\b')
accented = re.compile(r'[áéíóúüñÁÉÍÓÚÜÑ]')
technical = re.compile(r'(?i)^(?:shellcheck|spdx|pragma|nolint|noqa|type:\s*ignore)\b')
separator = re.compile(r'^[\s#=\-_*~.\[\]0-9:]+$')

pending_heredocs = []
records = []

def heredoc_delims(code):
    out=[]
    for m in re.finditer(r'<<-?\s*([\'\"]?)([A-Za-z_][A-Za-z0-9_]*)\1', code):
        out.append(m.group(2))
    return out

def comment_index(line):
    single = False
    double = False
    escaped = False
    for i, ch in enumerate(line):
        if escaped:
            escaped = False
            continue
        if ch == '\\' and not single:
            escaped = True
            continue
        if ch == "'" and not double:
            single = not single
            continue
        if ch == '"' and not single:
            double = not double
            continue
        if ch == '#' and not single and not double:
            if i == 0 or line[i-1].isspace() or line[i-1] in ';|&()<>':
                return i
    return None

for lineno, line in enumerate(lines, 1):
    if pending_heredocs:
        delim = pending_heredocs[0]
        if line.strip() == delim:
            pending_heredocs.pop(0)
        continue
    idx = comment_index(line)
    code = line if idx is None else line[:idx]
    pending_heredocs.extend(heredoc_delims(code))
    if idx is None:
        continue
    if lineno == 1 and line.startswith('#!'):
        continue
    text = line[idx+1:].strip()
    if technical.search(text):
        classification='technical-directive'; reason='machine-directive'
    elif not text or separator.fullmatch(text):
        classification='code-fragment'; reason='separator-or-empty'
    elif not re.search(r'[a-záéíóúüñ]', text):
        classification='code-fragment'; reason='non-prose-heading-or-code'
    else:
        function_hits = spanish_function.findall(text)
        if accented.search(text) or strong_spanish.search(text) or len(function_hits) >= 3:
            classification='language-defect'; reason='spanish-lexical-evidence'
        else:
            classification='english-prose'; reason='no-spanish-lexical-evidence'
    normalized = text.replace('\t', '    ')
    digest = hashlib.sha256(text.encode('utf-8')).hexdigest()
    records.append((lineno, classification, reason, digest, normalized))

with record.open('w', encoding='utf-8', newline='') as h:
    h.write('line_number\tclassification\treason\tcomment_sha256\tcomment_text\n')
    for row in records:
        h.write('\t'.join(map(str,row))+'\n')
PY_AUDIT

python3 - "$record" "$policy" "$target_sha" "$helper_sha" <<'PY_POLICY'
import csv, json, sys
from pathlib import Path
record=Path(sys.argv[1])
policy=Path(sys.argv[2])
target_sha=sys.argv[3]
helper_sha=sys.argv[4]
counts={k:0 for k in ('english-prose','technical-directive','code-fragment','language-defect')}
with record.open(encoding='utf-8', newline='') as h:
    rows=list(csv.DictReader(h, delimiter='\t'))
for row in rows:
    counts[row['classification']]+=1
defects=counts['language-defect']
data={
  'schema':1,
  'scenario':'phase-1-reference-comment-language-audit-execution',
  'review_only':True,
  'accepted_contract':{
    'step':165,
    'policy_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze-policy.json',
    'policy_sha256':'3df64c07bf2169f78add075ff0febaf04f3c418d8f1cbdb7435ebe9498209d4d',
    'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze.tsv',
    'record_sha256':'74c5cbda7c4fd609844352747af29f4ffe24e84dd9ef934cb6671dcb25523743'
  },
  'audit':{
    'target_path':'tools/reference/slack-update-reference.sh',
    'target_sha256':target_sha,
    'inventory_complete':True,
    'total_comments':len(rows),
    'english_prose':counts['english-prose'],
    'technical_directive':counts['technical-directive'],
    'code_fragment':counts['code-fragment'],
    'language_defects':defects,
    'conformance_pass':defects == 0,
    'source_modified':False
  },
  'authorization':{
    'source_change_authorized':False,
    'repository_refresh_authorized':False,
    'network_refresh_authorized':False,
    'machine_execution_authorized':False,
    'package_action_authorized':False,
    'boot_action_authorized':False,
    'phase_2_start_authorized':False,
    'future_work_requires_explicit_authorization':True
  },
  'helper_path':'tools/reference/phase-1-reference-comment-language-audit-execution.sh',
  'helper_sha256':helper_sha,
  'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution.tsv',
  'next_stage':'phase-1-reference-comment-language-audit-closure-review' if defects == 0 else 'phase-1-reference-comment-language-remediation-design',
  'slackware_current_publication_invalidates_audit':False,
  'pause_safe':False
}
policy.write_text(json.dumps(data, indent=2, sort_keys=False)+'\n', encoding='utf-8')
PY_POLICY

printf 'Audit target SHA-256: %s\n' "$target_sha"
python3 - "$policy" <<'PY_SUMMARY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
a=p['audit']
print(f"Syntactic comments inventoried: {a['total_comments']}")
print(f"Language defects: {a['language_defects']}")
print(f"Conformance pass: {str(a['conformance_pass']).lower()}")
print(f"Next stage: {p['next_stage']}")
PY_SUMMARY
