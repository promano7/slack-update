#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-reference-comment-language-remediation-closure-review.sh [--output-dir DIR] [--help]

Review and close the Phase 1 reference comment-language remediation workstream.
The review verifies the accepted step-168 transformation by reverse reconstruction,
runs a fresh zero-defect language audit, and emits deterministic closure evidence.
It never edits the reference source and grants no operational authorization.
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
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step168_policy="$acceptance_dir/phase-1-reference-comment-language-remediation-implementation-policy.json"
step168_record="$acceptance_dir/phase-1-reference-comment-language-remediation-implementation.tsv"
audit_helper="$repo_root/tools/reference/phase-1-reference-comment-language-audit-execution.sh"
target="$repo_root/tools/reference/slack-update-reference.sh"
helper_path="$repo_root/tools/reference/phase-1-reference-comment-language-remediation-closure-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

for required in "$step168_policy" "$step168_record" "$audit_helper" "$target" "$helper_path"; do
    require_regular "$required"
done

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 4; }

policy="$output_dir/phase-1-reference-comment-language-remediation-closure-review-policy.json"
record="$output_dir/phase-1-reference-comment-language-remediation-closure-review.tsv"

step168_policy_sha=$(sha256sum -- "$step168_policy" | awk '{print $1}')
step168_record_sha=$(sha256sum -- "$step168_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
target_sha=$(sha256sum -- "$target" | awk '{print $1}')

readarray -t implementation_values < <(python3 - "$step168_policy" <<'PY_POLICY_READ'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p.get('schema') == 1
assert p.get('scenario') == 'phase-1-reference-comment-language-remediation-implementation'
i=p['implementation']
r=p['reaudit']
a=p['authorization']
assert i['target_path'] == 'tools/reference/slack-update-reference.sh'
assert i['authorized_translations'] == 17
assert i['changed_lines'] == 17
assert i['line_count_preserved'] is True
assert i['code_prefix_preserved'] is True
assert i['nonauthorized_change_detected'] is False
assert i['reverse_reconstruction_matches_source_before'] is True
assert i['bash_n_pass'] is True
assert i['source_modified'] is True
assert r['inventory_complete'] is True
assert r['language_defects'] == 0
assert r['conformance_pass'] is True
assert a['source_change_authorized'] is False
assert a['repository_refresh_authorized'] is False
assert a['network_refresh_authorized'] is False
assert a['machine_execution_authorized'] is False
assert a['package_action_authorized'] is False
assert a['boot_action_authorized'] is False
assert a['phase_2_start_authorized'] is False
assert p['next_stage'] == 'phase-1-reference-comment-language-remediation-closure-review'
assert p['pause_safe'] is False
print(i['source_before_sha256'])
print(i['source_after_sha256'])
print(i['authorized_translations'])
PY_POLICY_READ
)
source_before_sha=${implementation_values[0]}
source_after_sha=${implementation_values[1]}
authorized_translations=${implementation_values[2]}

[[ $target_sha == "$source_after_sha" ]] || {
    printf 'ERROR: current reference source does not match accepted step 168\nexpected: %s\nactual:   %s\n' "$source_after_sha" "$target_sha" >&2
    exit 5
}

bash -n -- "$target"

reverse_sha=$(python3 - "$target" "$step168_record" <<'PY_REVERSE'
import csv, hashlib, re, sys
from pathlib import Path

target=Path(sys.argv[1])
record=Path(sys.argv[2])
lines=target.read_text(encoding='utf-8').splitlines(keepends=True)

def comment_index(line):
    single=False; double=False; escaped=False
    for i,ch in enumerate(line):
        if escaped:
            escaped=False; continue
        if ch == '\\' and not single:
            escaped=True; continue
        if ch == "'" and not double:
            single=not single; continue
        if ch == '"' and not single:
            double=not double; continue
        if ch == '#' and not single and not double:
            if i == 0 or line[i-1].isspace() or line[i-1] in ';|&()<>':
                return i
    return None

with record.open(encoding='utf-8', newline='') as h:
    rows=list(csv.DictReader(h, delimiter='\t'))
if len(rows) != 17:
    raise SystemExit('accepted step-168 record must contain exactly 17 translations')
if [r['defect_id'] for r in rows] != [f'D{i:03d}' for i in range(1,18)]:
    raise SystemExit('accepted step-168 defect IDs are not the frozen D001..D017 sequence')
for row in rows:
    if row['code_prefix_preserved'] != 'yes' or row['line_count_preserved'] != 'yes':
        raise SystemExit('accepted translation row violates preservation flags')
    n=int(row['line_number'])
    if n < 1 or n > len(lines):
        raise SystemExit(f'line number out of range: {n}')
    line=lines[n-1]
    ending='\n' if line.endswith('\n') else ''
    body=line[:-1] if ending else line
    idx=comment_index(body)
    if idx is None:
        raise SystemExit(f'no syntactic comment at accepted line {n}')
    payload_start=idx+1
    while payload_start < len(body) and body[payload_start] in ' \t':
        payload_start += 1
    current=body[payload_start:]
    if current != row['after_text']:
        raise SystemExit(f'current comment payload mismatch at line {n}')
    if hashlib.sha256(current.encode()).hexdigest() != row['after_sha256']:
        raise SystemExit(f'current comment SHA mismatch at line {n}')
    if hashlib.sha256(row['before_text'].encode()).hexdigest() != row['before_sha256']:
        raise SystemExit(f'accepted before-comment SHA mismatch at line {n}')
    lines[n-1]=body[:payload_start] + row['before_text'] + ending
blob=''.join(lines).encode('utf-8')
print(hashlib.sha256(blob).hexdigest())
PY_REVERSE
)
[[ $reverse_sha == "$source_before_sha" ]] || {
    printf 'ERROR: reverse reconstruction does not match accepted pre-remediation source\nexpected: %s\nactual:   %s\n' "$source_before_sha" "$reverse_sha" >&2
    exit 6
}

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
bash -- "$audit_helper" --output-dir "$tmp" >/dev/null
reaudit_policy="$tmp/phase-1-reference-comment-language-audit-execution-policy.json"
reaudit_record="$tmp/phase-1-reference-comment-language-audit-execution.tsv"
require_regular "$reaudit_policy"
require_regular "$reaudit_record"
reaudit_policy_sha=$(sha256sum -- "$reaudit_policy" | awk '{print $1}')
reaudit_record_sha=$(sha256sum -- "$reaudit_record" | awk '{print $1}')

readarray -t audit_values < <(python3 - "$reaudit_policy" "$target_sha" <<'PY_AUDIT_READ'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
a=p['audit']
assert a['target_sha256'] == sys.argv[2]
assert a['inventory_complete'] is True
assert a['language_defects'] == 0
assert a['conformance_pass'] is True
assert a['source_modified'] is False
print(a['total_comments'])
print(a['english_prose'])
print(a['technical_directive'])
print(a['code_fragment'])
print(a['language_defects'])
PY_AUDIT_READ
)
reaudit_total=${audit_values[0]}
reaudit_english=${audit_values[1]}
reaudit_technical=${audit_values[2]}
reaudit_code=${audit_values[3]}
reaudit_defects=${audit_values[4]}

python3 - "$record" "$step168_policy_sha" "$step168_record_sha" "$source_before_sha" "$target_sha" "$authorized_translations" "$reaudit_total" "$reaudit_english" "$reaudit_technical" "$reaudit_code" "$reaudit_defects" <<'PY_RECORD'
import sys
(record, p168, r168, before, after, translations, total, english, technical, code, defects) = sys.argv[1:]
rows=[
 ('check','value'),
 ('accepted_step_168_policy_sha256',p168),
 ('accepted_step_168_record_sha256',r168),
 ('source_before_sha256',before),
 ('source_after_sha256',after),
 ('authorized_translations',translations),
 ('reverse_reconstruction_matches_source_before','yes'),
 ('bash_n_pass','yes'),
 ('reaudit_total_comments',total),
 ('reaudit_english_prose',english),
 ('reaudit_technical_directive',technical),
 ('reaudit_code_fragment',code),
 ('reaudit_language_defects',defects),
 ('reaudit_conformance_pass','yes'),
 ('workstream_closed','yes'),
 ('pause_safe','yes'),
 ('strong_safe_pause','yes'),
 ('machine_action_required','no'),
 ('future_work_requires_fresh_boundary','yes'),
 ('next_stage','phase-1-resume-planning-after-comment-language-closure'),
]
with open(record,'w',encoding='utf-8',newline='') as h:
    for row in rows:
        h.write('\t'.join(row)+'\n')
PY_RECORD

python3 - "$policy" "$step168_policy_sha" "$step168_record_sha" "$source_before_sha" "$target_sha" "$authorized_translations" "$reverse_sha" "$reaudit_total" "$reaudit_english" "$reaudit_technical" "$reaudit_code" "$reaudit_defects" "$reaudit_policy_sha" "$reaudit_record_sha" "$helper_sha" <<'PY_POLICY'
import json, sys
(policy, p168, r168, before, after, translations, reverse, total, english, technical,
 code, defects, reaudit_policy_sha, reaudit_record_sha, helper_sha) = sys.argv[1:]
data={
  'schema':1,
  'scenario':'phase-1-reference-comment-language-remediation-closure-review',
  'review_only':True,
  'accepted_implementation':{
    'step':168,
    'policy_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation-policy.json',
    'policy_sha256':p168,
    'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-implementation.tsv',
    'record_sha256':r168,
  },
  'closure':{
    'target_path':'tools/reference/slack-update-reference.sh',
    'source_before_sha256':before,
    'source_after_sha256':after,
    'authorized_translations':int(translations),
    'reverse_reconstruction_sha256':reverse,
    'reverse_reconstruction_matches_source_before':reverse == before,
    'bash_n_pass':True,
    'fresh_reaudit':{
      'inventory_complete':True,
      'total_comments':int(total),
      'english_prose':int(english),
      'technical_directive':int(technical),
      'code_fragment':int(code),
      'language_defects':int(defects),
      'conformance_pass':int(defects) == 0,
      'ephemeral_policy_sha256':reaudit_policy_sha,
      'ephemeral_record_sha256':reaudit_record_sha,
    },
    'workstream_closed':True,
    'source_remediation_closed':True,
  },
  'remaining_phase_1_work':{
    'roadmap_reconciliation':'pending-repository-only-nonblocking',
    'acceptance_matrix_remainder':'pending-future-machine-work',
    'reference_freeze':'blocked-behind-remaining-acceptance-work',
    'c_port':'blocked-by-phase-1-gate',
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
    'future_work_requires_fresh_boundary':True,
  },
  'safe_pause':{
    'pause_safe':True,
    'strong_safe_pause':True,
    'machine_action_required':False,
    'slackware_current_publication_invalidates_closure':False,
  },
  'helper_path':'tools/reference/phase-1-reference-comment-language-remediation-closure-review.sh',
  'helper_sha256':helper_sha,
  'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-closure-review.tsv',
  'next_stage':'phase-1-resume-planning-after-comment-language-closure',
}
open(policy,'w',encoding='utf-8').write(json.dumps(data, indent=2, sort_keys=False)+'\n')
PY_POLICY

printf 'Accepted step-168 policy SHA-256: %s\n' "$step168_policy_sha"
printf 'Accepted step-168 record SHA-256: %s\n' "$step168_record_sha"
printf 'Closed source SHA-256: %s\n' "$target_sha"
printf 'Authorized translations verified: %s\n' "$authorized_translations"
printf 'Fresh language defects: %s\n' "$reaudit_defects"
printf 'Workstream closed: true\n'
printf 'Strong safe pause: true\n'
printf 'Machine action required: false\n'
printf 'Future work requires fresh boundary: true\n'
printf 'Next stage: phase-1-resume-planning-after-comment-language-closure\n'
