#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.tsv"
step231_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.sh"
step231_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.md"
step231_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review-harness.sh"
step231_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review-policy.json"
step231_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.tsv"
changelog="$repo_root/CHANGELOG.md"

pass=0
fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
assert_regular() { local f=$1 m=$2; [[ -f $f && ! -L $f ]] && ok "$m" || bad "$m"; }
assert_hash() { local f=$1 e=$2 m=$3 a; a=$(sha256sum -- "$f" | awk '{print $1}'); [[ $a == "$e" ]] && ok "$m" || { bad "$m"; printf '  expected %s\n  actual   %s\n' "$e" "$a"; }; }
assert_grep() { local pat=$1 f=$2 m=$3; grep -Fq -- "$pat" "$f" && ok "$m" || bad "$m"; }

for item in \
 "$helper|step-232 helper is a regular non-symlink file" \
 "$probe|step-232 probe is a regular non-symlink file" \
 "$doc|step-232 reference document is a regular non-symlink file" \
 "$policy|step-232 policy is a regular non-symlink file" \
 "$record|step-232 record is a regular non-symlink file" \
 "$step231_helper|accepted step-231 helper is a regular non-symlink file" \
 "$step231_doc|accepted step-231 document is a regular non-symlink file" \
 "$step231_harness|accepted step-231 harness is a regular non-symlink file" \
 "$step231_policy|accepted step-231 policy is a regular non-symlink file" \
 "$step231_record|accepted step-231 record is a regular non-symlink file" \
 "$changelog|CHANGELOG is a regular non-symlink file"; do
    IFS='|' read -r f m <<< "$item"
    assert_regular "$f" "$m"
done

assert_hash "$step231_helper" '82a5fd1a4d0e8407484e406b5e337761967a5f8ea97e1a85ddde69d544516f4b' 'accepted step-231 helper hash is frozen'
assert_hash "$step231_doc" 'c7173fadb533dafa895056733e175f096fdf100b79832d9803551d2b3ee01fb4' 'accepted step-231 document hash is frozen'
assert_hash "$step231_harness" 'eceb685682ceaa37323acb471bea59edc741badaba785a99978512f8e0ecdecf' 'accepted step-231 harness hash is frozen'
assert_hash "$step231_policy" 'cbdf94615bd349cc5196297dec52338638fcc5aa3f1200ae674e7fc2fc04ec0d' 'accepted step-231 policy hash is frozen'
assert_hash "$step231_record" 'cd0175b12d697d51eef5e7916438f1d3ec72db891375d47588cff445d9d65e76' 'accepted step-231 record hash is frozen'

bash -n "$helper" && ok 'step-232 helper passes bash syntax validation' || bad 'step-232 helper passes bash syntax validation'
bash -n "$probe" && ok 'step-232 probe passes bash syntax validation' || bad 'step-232 probe passes bash syntax validation'
"$helper" --help >/dev/null && ok 'step-232 helper exposes non-mutating help' || bad 'step-232 helper exposes non-mutating help'
"$probe" --help >/dev/null && ok 'step-232 probe exposes non-mutating help' || bad 'step-232 probe exposes non-mutating help'
if "$helper" --definitely-unknown >/dev/null 2>&1; then bad 'step-232 helper rejects unknown option'; else ok 'step-232 helper rejects unknown option'; fi
if "$probe" --definitely-unknown >/dev/null 2>&1; then bad 'step-232 probe rejects unknown option'; else ok 'step-232 probe rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp"; then ok 'step-232 helper executes successfully'; else bad 'step-232 helper executes successfully'; fi
cmp -s "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-policy.json" "$policy" && ok 'helper reproduces frozen policy exactly' || bad 'helper reproduces frozen policy exactly'
cmp -s "$tmp/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.tsv" "$record" && ok 'helper reproduces frozen record exactly' || bad 'helper reproduces frozen record exactly'

if python3 - "$policy" "$record" "$probe" <<'PY'
import csv, hashlib, json, sys
from pathlib import Path
p=Path(sys.argv[1]); r=Path(sys.argv[2]); probe=Path(sys.argv[3])
d=json.loads(p.read_text())
with r.open(newline='', encoding='utf-8') as h:
    rows=dict(csv.reader(h, delimiter='\t'))
probe_sha=hashlib.sha256(probe.read_bytes()).hexdigest()
assert d['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review'
assert d['step']==232 and d['review_status']=='PASS'
assert d['accepted_step_231']['fresh_boundary_preserved'] is True
assert d['accepted_step_231']['prior_machine_authority_reused'] is False
assert d['probe']['sha256']==probe_sha
assert d['probe']['read_only'] is True
assert d['probe']['repository_on_target_required'] is False
assert d['expected_target_baseline']['historical_boot_id_reusable'] is False
assert d['expected_target_baseline']['fresh_boot_id_must_be_observed'] is True
assert d['accepted_local_source_v2']['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert d['accepted_local_source_v2']['manifest_sidecar_must_verify'] is True
assert d['accepted_local_source_v2']['manifest_must_cover_exact_regular_file_set'] is True
assert d['accepted_local_source_v2']['exact_generated_regular_file_count']==11
assert d['accepted_local_source_v2']['unexpected_symlinks_or_other_nodes_allowed'] is False
assert d['accepted_local_source_v2']['priority_tree_contract_must_verify'] is True
assert d['accepted_local_source_v2']['compatibility_asc_must_not_claim_authenticity'] is True
assert d['preservation_contract']['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
assert d['authorization']['target_observation_authorized'] is True
assert d['authorization']['probe_transport_copy_authorized'] is True
assert d['authorization']['probe_execution_use_count']==1
for key in ['repository_refresh_authorized','network_access_authorized','runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized']:
    assert d['authorization'][key] is False, key
assert d['machine_action_required'] is True and d['controller_action_required'] is True
assert d['pause_safe'] is False
assert d['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze'
assert rows['step']=='232' and rows['review_status']=='PASS'
assert rows['probe_sha256']==probe_sha
assert rows['target_observation_authorized']=='yes'
assert rows['runtime_rerun_authorized']=='no'
assert rows['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze'
PY
then ok 'step-232 policy semantic assertions pass'; else bad 'step-232 policy semantic assertions pass'; fi

for spec in \
 'step|232' \
 'review_status|PASS' \
 'fresh_boundary_preserved|yes' \
 'prior_machine_authority_reused|no' \
 'probe_transport_copy_authorized|yes' \
 'target_observation_authorized|yes' \
 'probe_execution_use_count|1' \
 'fresh_boot_id_must_be_observed|yes' \
 'historical_boot_id_reusable|no' \
 'local_source_v2_tree_manifest_sidecar_must_verify|yes' \
 'local_source_v2_manifest_exact_coverage_required|yes' \
 'local_source_v2_priority_tree_contract_must_verify|yes' \
 'local_source_v2_compatibility_asc_must_verify|yes' \
 'candidate_set_bound|no' \
 'runtime_executor_remediation_authorized|no' \
 'runtime_rerun_authorized|no' \
 'package_action_authorized|no' \
 'slackpkg_mutation_authorized|no' \
 'repository_refresh_authorized|no' \
 'network_access_authorized|no' \
 'boot_action_authorized|no' \
 'reboot_authorized|no' \
 'evidence_cleanup_authorized|no' \
 'phase_2_start_authorized|no' \
 'machine_action_required|yes' \
 'controller_action_required|yes' \
 'pause_safe|no' \
 'next_stage|phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze'; do
    key=${spec%%|*}; value=${spec#*|}
    grep -Fxq "$key"$'\t'"$value" "$record" && ok "record freezes: $key" || bad "record freezes: $key"
done

assert_grep 'exactly one bounded read-only observation' "$doc" 'reference document opens only one read-only machine observation'
assert_grep 'manifest covers exactly the accepted regular-file set' "$doc" 'reference document explains exact v2 manifest coverage'
assert_grep 'does not itself bind a candidate set or authorize executor remediation' "$doc" 'reference document keeps candidate and executor authority closed'
assert_grep '## Phase 1 step 232 kernel-package-edge runtime-transaction remediation post-local-source-v2-build revalidation review' "$changelog" 'CHANGELOG records step 232'
assert_grep "printf 'post_v2_build_revalidation_status\\tPASS\\n'" "$probe" 'probe emits real-tab PASS evidence'
assert_grep 'verify_v2_manifest_coverage' "$probe" 'probe checks exact v2 manifest coverage'
assert_grep 'No cryptographic authenticity claim is made by this file.' "$probe" 'probe checks bounded compatibility asc role'
assert_grep 'runtime_executor_remediation_performed\tno' "$probe" 'probe reports no executor remediation'

if python3 - "$helper" "$probe" <<'PY'
import re, sys
from pathlib import Path
bad=[]
pattern=re.compile(r'^\s*(?:sudo\s+)?(?:slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|halt|curl|wget)\b')
for filename in sys.argv[1:]:
    for i,line in enumerate(Path(filename).read_text().splitlines(),1):
        if pattern.search(line):
            bad.append((filename,i,line))
if bad:
    for x in bad:
        print(*x, sep=':')
    raise SystemExit(1)
PY
then ok 'step-232 helper and probe contain no executable package/network/boot command'; else bad 'step-232 helper and probe contain no executable package/network/boot command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && printf PASS || printf FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
