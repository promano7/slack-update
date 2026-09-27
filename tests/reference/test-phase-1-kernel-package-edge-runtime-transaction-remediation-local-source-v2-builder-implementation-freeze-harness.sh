#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'; prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
helper="$repo_root/tools/reference/${base}.sh"; doc="$repo_root/docs/reference/${base}.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev_helper="$repo_root/tools/reference/${prev}.sh"; prev_doc="$repo_root/docs/reference/${prev}.md"; prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
record_has() { awk -F '\t' -v k="$1" '$1==k {found=1} END {exit !found}' "$record"; }
for item in "$builder" "$helper" "$doc" "$policy" "$record"; do assert "step-227 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-226 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'reviewed v2 builder SHA-256 remains frozen' hash_is "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'accepted step-226 helper hash is frozen' hash_is "$prev_helper" 'fc8ffed9c7fa9eb69a59b03b4d47bad3dfda4182cea20409f3dec0517f7f9d12'
assert 'accepted step-226 document hash is frozen' hash_is "$prev_doc" 'f69b4c905d2b328f48f4c6f722015aa94794e095f4f1ed6cd1d16cee012fc806'
assert 'accepted step-226 harness hash is frozen' hash_is "$prev_harness" '7ff6d776b683a5ddc7bc74a581e602f3479704bf37b78afb8ee3de8b4b9b3f8f'
assert 'accepted step-226 policy hash is frozen' hash_is "$prev_policy" '950fa9b91c59fc0562011ff716ca0108bb7ff78d5140cf96c4c9547806cd5826'
assert 'accepted step-226 record hash is frozen' hash_is "$prev_record" '4da734369f4e4311f027d613732d0c8eaf2d873d74ec804272873c5ba265b412'
assert 'step-227 helper hash matches frozen policy' hash_is "$helper" '0882eb6636170e7ffde474f0d3c11f90dbf8b2431a29b9fe062bafcac2dee425'
assert 'step-227 policy hash matches overlay' hash_is "$policy" '79fcbc19be0de464ba41e02fbd4b7f4a66b15b34e41648df7a6763bb706149ad'
assert 'step-227 record hash matches overlay' hash_is "$record" 'c4fb4fce881ac6cf5254dd67399233a64361caf81b14638aa2d506d0edd073d4'
assert 'frozen v2 builder passes bash syntax validation' bash -n "$builder"
assert 'step-227 helper passes bash syntax validation' bash -n "$helper"
assert 'step-227 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-227 helper rejects unknown option' bash -c '! "$1" --bad-option >/dev/null 2>&1' _ "$helper"
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
assert 'step-227 helper executes successfully' "$helper" --output-dir "$tmp"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/${base}.tsv"
assert 'step-227 policy semantic assertions pass' python3 - "$prev_policy" "$policy" <<'PYSEM'
import copy,json,sys
p226=json.load(open(sys.argv[1],encoding='utf-8')); p=json.load(open(sys.argv[2],encoding='utf-8'))
assert p['step']==227 and p['review_status']=='PASS'
assert p['accepted_step_226']['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert p['frozen_runtime_identity']==p226['frozen_runtime_identity']
assert p['preservation_contract']==p226['preservation_contract']
expected_impl=copy.deepcopy(p226['builder_implementation']); expected_impl['state']='implemented-frozen-not-executed'; assert p['builder_implementation']==expected_impl
expected_design=copy.deepcopy(p226['local_source_v2_design']); expected_design['state']='design-frozen-implementation-frozen-not-built'; assert p['local_source_v2_design']==expected_design
r=copy.deepcopy(p226['future_refresh_acceptance_contract']); r.pop('not_authorized_by_step_226',None); r['not_authorized_by_step_227']=True; assert p['future_refresh_acceptance_contract']==r
assert p['implementation_freeze_contract']['fresh_target_revalidation_required_before_builder_transport_or_execution'] is True
a=p['authorization']; assert a['repository_only_prebuild_fresh_target_revalidation_review_authorized'] is True
for k in ('target_observation_authorized','probe_transport_copy_authorized','local_source_v2_builder_transport_authorized','local_source_v2_builder_execution_authorized','local_source_v2_build_authorized','runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized','evidence_cleanup_authorized','phase_2_start_authorized'): assert a[k] is False,k
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review'
PYSEM
for key in step review_status builder_implementation_state builder_sha256 local_source_v2_design_state priority_trees CHECKSUMS_md5_asc_required refresh_workdir_strategy candidate_guard_scope repository_only_prebuild_fresh_target_revalidation_review_authorized target_observation_authorized local_source_v2_builder_execution_authorized local_source_v2_build_authorized runtime_rerun_authorized package_action_authorized machine_action_required pause_safe next_stage; do assert "record contains $key" record_has "$key"; done
assert 'record freezes step 227' record_is step 227
assert 'record freezes builder implementation' record_is builder_implementation_state implemented-frozen-not-executed
assert 'record freezes exact builder SHA-256' record_is builder_sha256 '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'record freezes v2 as not built' record_is local_source_v2_design_state design-frozen-implementation-frozen-not-built
assert 'record opens only prebuild revalidation review' record_is repository_only_prebuild_fresh_target_revalidation_review_authorized yes
assert 'record keeps target observation closed' record_is target_observation_authorized no
assert 'record keeps builder execution closed' record_is local_source_v2_builder_execution_authorized no
assert 'record keeps v2 build closed' record_is local_source_v2_build_authorized no
assert 'record requires no machine action' record_is machine_action_required no
assert 'record names prebuild revalidation review next' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review
assert 'document records exact frozen builder SHA' grep -Fq '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' "$doc"
assert 'document requires fresh target revalidation before builder use' grep -Fq 'must be freshly revalidated again' "$doc"
assert 'document keeps observation closed' grep -Fq 'observation itself remains closed' "$doc"
assert 'CHANGELOG records step 227' grep -Fq '## Phase 1 step 227 kernel-package-edge runtime-transaction remediation local-source-v2 builder implementation freeze' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
