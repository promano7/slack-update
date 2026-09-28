#!/bin/bash
set -u
set -o pipefail
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.tsv"
changelog="$repo_root/CHANGELOG.md"
step251_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review-policy.json"
step251_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.tsv"

pass=0
fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }

for spec in "$helper|step-252 helper" "$probe|step-252 probe" "$doc|step-252 document" "$policy|step-252 policy" "$record|step-252 record" "$changelog|CHANGELOG" "$step251_policy|accepted step-251 policy" "$step251_record|accepted step-251 record"; do
    file=${spec%%|*}; label=${spec#*|}
    [[ -f $file && ! -L $file ]] && ok "$label exists as regular file" || bad "$label exists as regular file"
done

for script in "$helper" "$probe"; do
    bash -n "$script" >/dev/null 2>&1 && ok "$(basename "$script") passes bash syntax validation" || bad "$(basename "$script") passes bash syntax validation"
done

"$helper" --help >/dev/null 2>&1 && ok 'step-252 helper exposes non-mutating help' || bad 'step-252 helper exposes non-mutating help'
"$probe" --help >/dev/null 2>&1 && ok 'step-252 probe exposes non-mutating help' || bad 'step-252 probe exposes non-mutating help'
if "$helper" --definitely-invalid >/dev/null 2>&1; then bad 'step-252 helper rejects unknown option'; else ok 'step-252 helper rejects unknown option'; fi
if "$probe" --definitely-invalid >/dev/null 2>&1; then bad 'step-252 probe rejects unknown option'; else ok 'step-252 probe rejects unknown option'; fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
if "$helper" --output-dir "$scratch" >/dev/null; then
    ok 'step-252 helper executes successfully'
else
    bad 'step-252 helper executes successfully'
fi
cmp -s "$scratch/$(basename "$policy")" "$policy" && ok 'helper reproduces frozen policy exactly' || bad 'helper reproduces frozen policy exactly'
cmp -s "$scratch/$(basename "$record")" "$record" && ok 'helper reproduces frozen record exactly' || bad 'helper reproduces frozen record exactly'

python3 - "$policy" "$step251_policy" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
p251=json.load(open(sys.argv[2], encoding='utf-8'))
assert p['schema']==1
assert p['step']==252 and p['review_status']=='PASS'
assert p['accepted_step_251']['fresh_boundary_preserved'] is True
assert p['accepted_step_251']['accepted_v3_manifest_binding_preserved'] is True
assert p['accepted_step_251']['prior_machine_authority_reused'] is False
assert p['accepted_local_source_v3']['tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert p['accepted_local_source_v3']['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert p['accepted_local_source_v3']['compatibility_PGP_marker']=='PGP compatibility marker for Slackpkg checkchangelog only.'
assert p['accepted_local_source_v3']['openpgp_signature_block_forbidden'] is True
assert p['probe']['read_only'] is True and p['probe']['authorization_use_count']==1
assert p['executor_v2_boundary']['human_spaced_error_prefix']=='Error downloading from '
assert p['executor_v2_boundary']['human_spaced_error_prefix_record_encoding']=='hex:4572726f7220646f776e6c6f6164696e672066726f6d20'
assert p['authorization']['target_observation_authorized'] is True
assert p['authorization']['probe_transport_copy_authorized'] is True
assert p['authorization']['probe_execution_authorized'] is True
for key in ['runtime_executor_v2_implementation_authorized','runtime_executor_v2_transport_authorized','runtime_candidate_binding_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','persistent_configuration_change_authorized','phase_2_start_authorized']:
    assert p['authorization'][key] is False, key
assert p['machine_action_required'] is True
assert p['controller_action_required'] is True
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze'
assert p251['runtime_executor_v2_boundary']['accepted_v3_manifest_identity_bound'] is True
PY
[[ $? -eq 0 ]] && ok 'step-252 policy semantic assertions pass' || bad 'step-252 policy semantic assertions pass'

for spec in \
 'step|252' \
 'review_status|PASS' \
 'accepted_step_251|yes' \
 'fresh_boundary_preserved|yes' \
 'accepted_v3_manifest_binding_preserved|yes' \
 'prior_machine_authority_reused|no' \
 'probe_transport_copy_authorized|yes' \
 'target_observation_authorized|yes' \
 'probe_execution_authorized|yes' \
 'probe_execution_use_count|1' \
 'fresh_boot_id_must_be_observed|yes' \
 'historical_boot_id_reusable|no' \
 'local_source_v3_tree_manifest_sha256|8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' \
 'local_source_v3_tree_manifest_sidecar_must_verify|yes' \
 'local_source_v3_manifest_exact_coverage_required|yes' \
 'local_source_v3_compatibility_PGP_marker_must_verify|yes' \
 'human_spaced_error_prefix_hex|4572726f7220646f776e6c6f6164696e672066726f6d20' \
 'hyphenated_error_literal_guard_forbidden|yes' \
 'candidate_set_bound|no' \
 'runtime_executor_v2_implementation_authorized|no' \
 'runtime_executor_v2_transport_authorized|no' \
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
 'next_stage|phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze'; do
    key=${spec%%|*}; value=${spec#*|}
    grep -Fxq "$key"$'\t'"$value" "$record" && ok "record freezes: $key" || bad "record freezes: $key"
done

grep -Fq 'exactly one bounded read-only observation' "$doc" && ok 'reference document opens one bounded read-only observation' || bad 'reference document opens one bounded read-only observation'
grep -Fq 'manifest must cover exactly the accepted regular-file set' "$doc" && ok 'reference document requires exact v3 manifest coverage' || bad 'reference document requires exact v3 manifest coverage'
grep -Fq 'does not itself bind a candidate set or authorize executor-v2 implementation' "$doc" && ok 'reference document keeps executor and candidate authority closed' || bad 'reference document keeps executor and candidate authority closed'
grep -Fq '4572726f7220646f776e6c6f6164696e672066726f6d20' "$doc" && ok 'reference document records whitespace-safe error-prefix encoding' || bad 'reference document records whitespace-safe error-prefix encoding'
grep -Fq '## Phase 1 step 252 kernel-package-edge runtime-transaction remediation post-local-source-v3 build revalidation review' "$changelog" && ok 'CHANGELOG records step 252' || bad 'CHANGELOG records step 252'
grep -Fq "printf 'post_v3_build_revalidation_status\\tPASS\\n'" "$probe" && ok 'probe emits real-tab PASS evidence' || bad 'probe emits real-tab PASS evidence'
grep -Fq 'verify_v3_manifest_coverage' "$probe" && ok 'probe checks exact v3 manifest coverage' || bad 'probe checks exact v3 manifest coverage'
grep -Fq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$probe" && ok 'probe checks exact v3 PGP compatibility marker' || bad 'probe checks exact v3 PGP compatibility marker'
grep -Fq 'BEGIN PGP SIGNATURE' "$probe" && ok 'probe rejects OpenPGP signature impersonation' || bad 'probe rejects OpenPGP signature impersonation'

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
    for x in bad: print(*x, sep=':')
    raise SystemExit(1)
PY
then ok 'step-252 helper and probe contain no executable package/network/boot command'; else bad 'step-252 helper and probe contain no executable package/network/boot command'; fi

if python3 - "$helper" "$probe" "$doc" "$policy" "$record" <<'PY'
import sys
from pathlib import Path
bad=[]
for name in sys.argv[1:]:
    for i,line in enumerate(Path(name).read_text(encoding='utf-8').splitlines(),1):
        if line.rstrip(' \t') != line:
            bad.append((name,i))
if bad:
    print(bad)
    raise SystemExit(1)
PY
then ok 'new step-252 artifacts contain no trailing whitespace'; else bad 'new step-252 artifacts contain no trailing whitespace'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && printf PASS || printf FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
