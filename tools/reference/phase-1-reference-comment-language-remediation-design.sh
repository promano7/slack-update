#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-reference-comment-language-remediation-design.sh [--output-dir DIR] [--help]

Freeze the repository-only remediation design for comment-language defects
accepted by step 166. The design authorizes only one-for-one translation of
the exact defective shell-comment payloads. It never edits the source itself.
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
step166_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution-policy.json"
step166_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution.tsv"
target="$repo_root/tools/reference/slack-update-reference.sh"
helper_path="$repo_root/tools/reference/phase-1-reference-comment-language-remediation-design.sh"

for file in "$step166_policy" "$step166_record" "$target" "$helper_path"; do
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
done

if [[ -z $output_dir ]]; then
    output_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 4; }

record="$output_dir/phase-1-reference-comment-language-remediation-design.tsv"
policy="$output_dir/phase-1-reference-comment-language-remediation-design-policy.json"
step166_policy_sha=$(sha256sum -- "$step166_policy" | awk '{print $1}')
step166_record_sha=$(sha256sum -- "$step166_record" | awk '{print $1}')
target_sha=$(sha256sum -- "$target" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step166_policy" "$step166_record" "$target_sha" "$record" <<'PY_RECORD'
import csv, json, sys
from pathlib import Path
p=json.load(open(sys.argv[1],encoding='utf-8'))
record_in=Path(sys.argv[2])
target_sha=sys.argv[3]
out=Path(sys.argv[4])
a=p['audit']
assert p['scenario']=='phase-1-reference-comment-language-audit-execution'
assert p['next_stage']=='phase-1-reference-comment-language-remediation-design'
assert p['review_only'] is True
assert a['target_path']=='tools/reference/slack-update-reference.sh'
assert a['target_sha256']==target_sha
assert a['inventory_complete'] is True
assert a['conformance_pass'] is False
assert a['language_defects'] > 0
with record_in.open(encoding='utf-8',newline='') as h:
    rows=list(csv.DictReader(h,delimiter='\t'))
defects=[r for r in rows if r['classification']=='language-defect']
assert len(defects)==a['language_defects']
with out.open('w',encoding='utf-8',newline='') as h:
    h.write('defect_id\tline_number\tcomment_sha256\tcomment_text\tauthorized_change\tpreserve_code_prefix\tpreserve_line_count\tdisposition\n')
    for idx,r in enumerate(defects,1):
        text=r['comment_text'].replace('\t','    ')
        h.write(f"D{idx:03d}\t{r['line_number']}\t{r['comment_sha256']}\t{text}\ttranslate-comment-payload-to-English\tyes\tyes\tauthorized-for-step-168\n")
PY_RECORD

python3 - "$step166_policy" "$step166_record" "$record" "$policy" "$step166_policy_sha" "$step166_record_sha" "$target_sha" "$helper_sha" <<'PY_POLICY'
import csv, json, sys
from pathlib import Path
step166=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h:
    audit_rows=list(csv.DictReader(h,delimiter='\t'))
with open(sys.argv[3],encoding='utf-8',newline='') as h:
    design_rows=list(csv.DictReader(h,delimiter='\t'))
policy_path=Path(sys.argv[4])
step166_policy_sha,step166_record_sha,target_sha,helper_sha=sys.argv[5:9]
defects=[r for r in audit_rows if r['classification']=='language-defect']
assert len(defects)==len(design_rows)==step166['audit']['language_defects']
assert [r['line_number'] for r in defects]==[r['line_number'] for r in design_rows]
assert [r['comment_sha256'] for r in defects]==[r['comment_sha256'] for r in design_rows]
data={
  'schema':1,
  'scenario':'phase-1-reference-comment-language-remediation-design',
  'review_only':True,
  'accepted_audit':{
    'step':166,
    'policy_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution-policy.json',
    'policy_sha256':step166_policy_sha,
    'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-execution.tsv',
    'record_sha256':step166_record_sha,
    'target_path':'tools/reference/slack-update-reference.sh',
    'target_sha256':target_sha,
    'language_defects':len(defects)
  },
  'remediation_design':{
    'authorized_rows':len(defects),
    'translation_requirement':'English natural-language comment prose',
    'change_unit':'syntactic shell-comment payload only',
    'preserve_code_prefix_through_hash':True,
    'preserve_line_count':True,
    'preserve_nondefect_comments':True,
    'runtime_strings_out_of_scope':True,
    'heredoc_payload_out_of_scope':True,
    'technical_directives_out_of_scope':True,
    'code_changes_forbidden':True,
    'implementation_must_run_bash_n':True,
    'implementation_must_rerun_language_audit':True,
    'implementation_zero_defect_gate':True
  },
  'authorization':{
    'source_change_authorized':True,
    'source_change_scope':'only defect rows frozen by this design record',
    'repository_refresh_authorized':False,
    'network_refresh_authorized':False,
    'machine_execution_authorized':False,
    'package_action_authorized':False,
    'boot_action_authorized':False,
    'phase_2_start_authorized':False,
    'future_work_requires_explicit_authorization':True
  },
  'helper_path':'tools/reference/phase-1-reference-comment-language-remediation-design.sh',
  'helper_sha256':helper_sha,
  'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-remediation-design.tsv',
  'next_stage':'phase-1-reference-comment-language-remediation-implementation',
  'slackware_current_publication_invalidates_design':False,
  'pause_safe':False
}
policy_path.write_text(json.dumps(data,indent=2,sort_keys=False)+'\n',encoding='utf-8')
PY_POLICY

printf 'Accepted step-166 policy SHA-256: %s\n' "$step166_policy_sha"
printf 'Accepted step-166 record SHA-256: %s\n' "$step166_record_sha"
printf 'Authorized target SHA-256: %s\n' "$target_sha"
python3 - "$policy" <<'PY_SUMMARY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
print(f"Authorized comment translations: {p['remediation_design']['authorized_rows']}")
print(f"Source change authorized: {str(p['authorization']['source_change_authorized']).lower()}")
print(f"Next stage: {p['next_stage']}")
PY_SUMMARY
printf '%s\n' '--- Authorized defect inventory ---'
awk -F '\t' 'NR==1{next}{printf "%s line=%s sha256=%s text=%s\n",$1,$2,$3,$4}' "$record"
