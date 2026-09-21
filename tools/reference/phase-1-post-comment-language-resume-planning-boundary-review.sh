#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-post-comment-language-resume-planning-boundary-review.sh [--help]

Read-only Phase 1 resume-planning boundary review after the accepted step-169
comment-language closure. The helper verifies the exact step-169 strong-safe-
pause evidence and emits a fresh repository-only planning boundary. It grants
no source, network, repository, machine, package, boot, or Phase 2 authority.
USAGE
}

if (($#)); then
    if [[ $# -eq 1 && $1 == --help ]]; then
        usage
        exit 0
    fi
    printf 'ERROR: unknown option: %s\n' "$1" >&2
    exit 2
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
checkpoint_policy="$acceptance_dir/phase-1-reference-comment-language-remediation-closure-review-policy.json"
checkpoint_record="$acceptance_dir/phase-1-reference-comment-language-remediation-closure-review.tsv"
record="$acceptance_dir/phase-1-post-comment-language-resume-planning-boundary-review.tsv"

check_hash() {
    local file=$1 expected=$2 actual
    [[ -f $file && ! -L $file ]] || {
        printf 'ERROR: required regular file is missing or unsafe: %s\n' "$file" >&2
        exit 3
    }
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$checkpoint_policy" 'd0cc3e26dd663e5f1117a327a088084b6c734a6ced608191f1ce174b5be4e11c'
check_hash "$checkpoint_record" 'c0cc272c7270945d289068d024ff7a14abe275c03292b310e058a829b0528f44'

python3 - "$checkpoint_policy" "$checkpoint_record" <<'PY'
import csv
import json
import sys
from pathlib import Path

policy_path = Path(sys.argv[1])
record_path = Path(sys.argv[2])
policy = json.loads(policy_path.read_text(encoding='utf-8'))
with record_path.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.reader(handle, delimiter='\t'))
values = {key: value for key, value in rows[1:]}

assert policy['schema'] == 1
assert policy['scenario'] == 'phase-1-reference-comment-language-remediation-closure-review'
assert policy['review_only'] is True
assert policy['closure']['source_after_sha256'] == '086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
assert policy['closure']['fresh_reaudit']['language_defects'] == 0
assert policy['closure']['fresh_reaudit']['conformance_pass'] is True
assert policy['closure']['workstream_closed'] is True
assert policy['closure']['source_remediation_closed'] is True
assert policy['safe_pause']['pause_safe'] is True
assert policy['safe_pause']['strong_safe_pause'] is True
assert policy['safe_pause']['machine_action_required'] is False
assert policy['safe_pause']['slackware_current_publication_invalidates_closure'] is False
assert policy['authorization']['future_work_requires_fresh_boundary'] is True
for key in (
    'source_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert policy['authorization'][key] is False
assert policy['next_stage'] == 'phase-1-resume-planning-after-comment-language-closure'
assert rows[0] == ['check', 'value']
assert values['workstream_closed'] == 'yes'
assert values['reaudit_language_defects'] == '0'
assert values['strong_safe_pause'] == 'yes'
assert values['machine_action_required'] == 'no'
assert values['future_work_requires_fresh_boundary'] == 'yes'
assert values['next_stage'] == 'phase-1-resume-planning-after-comment-language-closure'
PY

[[ -f $record && ! -L $record ]] || {
    printf 'ERROR: step-170 boundary record is missing or unsafe\n' >&2
    exit 5
}
cat -- "$record"
