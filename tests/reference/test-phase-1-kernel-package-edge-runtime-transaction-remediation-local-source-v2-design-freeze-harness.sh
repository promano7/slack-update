#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze'
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"

passes=0
failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
record_has() { awk -F '\t' -v k="$1" '$1==k {found=1} END {exit !found}' "$record"; }

for item in "$helper" "$doc" "$policy" "$record"; do assert "step-225 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-224 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-224 helper hash is frozen' hash_is "$prev_helper" '8d81a78fc92b35601976d83133e28a0509ab8b7940dca03ad0b0061ef4db8c30'
assert 'accepted step-224 document hash is frozen' hash_is "$prev_doc" '206b56d8fec4e9310bb16e6de41612e42a3385aaca75026098b5cb355dbd6431'
assert 'accepted step-224 harness hash is frozen' hash_is "$prev_harness" 'a56eb3a73b3897e4f70252cd4a89b492c93dc95d464688593ae7d27f86308158'
assert 'accepted step-224 policy hash is frozen' hash_is "$prev_policy" '5bb886adbbaa6e48649dd094b19e9f9d47e0d00e42af41a9bfef8c6bf8510dbe'
assert 'accepted step-224 record hash is frozen' hash_is "$prev_record" 'b740a6963432a0e744099a4facad2b627f39d5e5321ac1a784e5d0082efac1a9'
assert 'step-225 helper hash matches frozen policy' hash_is "$helper" 'e7c3c682b0078f4db070328cecf26e2df89f40caa12e8bea68e2f5aacedcf2e4'
assert 'step-225 frozen policy hash matches overlay' hash_is "$policy" '6f439cc4803cefb8d1c8d62a3e9ccc07a4dae9523c4e16592d4527e01696ab64'
assert 'step-225 frozen record hash matches overlay' hash_is "$record" 'd43544d6dbe41e5c17372921b93fd200afddaea7dcbf147c89814c625c5e5811'
assert 'step-225 helper passes bash syntax validation' bash -n "$helper"
assert 'step-225 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-225 helper rejects unknown option' bash -c '! "$1" --bad-option >/dev/null 2>&1' _ "$helper"

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
assert 'step-225 helper executes successfully' "$helper" --output-dir "$tmp"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/${base}.tsv"

assert 'step-225 policy semantic assertions pass' python3 - "$prev_policy" "$policy" <<'PYSEM'
import copy,json,sys
p224=json.load(open(sys.argv[1],encoding='utf-8'))
p=json.load(open(sys.argv[2],encoding='utf-8'))
assert p['schema']==1 and p['step']==225 and p['review_status']=='PASS'
assert p['accepted_step_224']['policy_sha256']=='5bb886adbbaa6e48649dd094b19e9f9d47e0d00e42af41a9bfef8c6bf8510dbe'
assert p['frozen_runtime_identity']==p224['frozen_runtime_identity']
assert p['preservation_contract']==p224['preservation_contract']
expected=copy.deepcopy(p224['local_source_v2_design']); expected['state']='design-frozen-not-implemented'
assert p['local_source_v2_design']==expected
r=copy.deepcopy(p224['future_refresh_acceptance_contract']); r.pop('not_authorized_by_step_224',None); r['not_authorized_by_step_225']=True
assert p['future_refresh_acceptance_contract']==r
assert p['local_source_v2_design']['CHECKSUMS_md5_asc']['required'] is True
assert p['local_source_v2_design']['priority_tree_contract']['effective_x86_64_priority_trees']==['patches','slackware64','extra','pasture','testing']
assert p['future_refresh_acceptance_contract']['workdir_strategy']=='transaction-owned-new-empty-workdir'
assert p['future_refresh_acceptance_contract']['candidate_guard_scope']=='target-specific-not-global-pkglist-row-count'
a=p['authorization']
assert a['repository_only_local_source_v2_builder_implementation_review_authorized'] is True
for k in ('local_source_v2_builder_implementation_authorized','local_source_v2_builder_execution_authorized','local_source_v2_build_authorized','target_observation_authorized','runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized','evidence_cleanup_authorized','phase_2_start_authorized'):
    assert a[k] is False,k
assert p['design_freeze_contract']['accepted_step_224_design_semantics_must_not_change'] is True
assert p['implementation_boundary']['builder_implementation_review_is_repository_only'] is True
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['future_work_requires_explicit_authorization'] is True
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'
PYSEM

for key in step review_status frozen_boot_id local_source_v2_design_state local_source_v2_root CHECKSUMS_md5_asc_required priority_trees refresh_workdir_strategy candidate_guard_scope repository_only_local_source_v2_builder_implementation_review_authorized local_source_v2_builder_execution_authorized local_source_v2_build_authorized runtime_rerun_authorized package_action_authorized machine_action_required pause_safe next_stage; do
  assert "record contains $key" record_has "$key"
done
assert 'record freezes step 225' record_is step 225
assert 'record freezes v2 design' record_is local_source_v2_design_state design-frozen-not-implemented
assert 'record preserves compatibility asc requirement' record_is CHECKSUMS_md5_asc_required yes
assert 'record preserves all priority trees' record_is priority_trees patches,slackware64,extra,pasture,testing
assert 'record preserves fresh transaction workdir' record_is refresh_workdir_strategy transaction-owned-new-empty-workdir
assert 'record preserves target-specific candidate guard' record_is candidate_guard_scope target-specific-not-global-pkglist-row-count
assert 'record opens only repository builder implementation review' record_is repository_only_local_source_v2_builder_implementation_review_authorized yes
assert 'record keeps builder execution closed' record_is local_source_v2_builder_execution_authorized no
assert 'record keeps v2 build closed' record_is local_source_v2_build_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record requires no machine action' record_is machine_action_required no
assert 'record names implementation review next' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review
assert 'document states exact design semantics are frozen' grep -Fq 'freezes that design without changing its semantics' "$doc"
assert 'document preserves v1 and failed evidence' grep -Fq 'preserved failed-runtime evidence, staged target, and v1 tree remain unchanged' "$doc"
assert 'document preserves priority tree contract' grep -Fq '`patches`, `slackware64`, `extra`, `pasture`, and `testing`' "$doc"
assert 'document preserves empty transaction workdir contract' grep -Fq 'transaction-owned new empty Slackpkg workdir' "$doc"
assert 'document opens repository-only implementation review' grep -Fq 'only new authority is repository-only' "$doc"
assert 'CHANGELOG records step 225' grep -Fq '## Phase 1 step 225 kernel-package-edge runtime-transaction remediation local-source-v2 design freeze' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
