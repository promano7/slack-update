#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'
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

for item in "$helper" "$doc" "$policy" "$record"; do assert "step-224 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-223 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-223 helper hash is frozen' hash_is "$prev_helper" '31dd91d1319fcd8c0a56a8580ae0665f2844dc02a5a3da39c80fb438681f20ae'
assert 'accepted step-223 document hash is frozen' hash_is "$prev_doc" '4b75ab3018df982f4115d397824d65fffb33fd5cd38f08800de8d6158885a63c'
assert 'accepted step-223 harness hash is frozen' hash_is "$prev_harness" '3b8c7760cdd82f3f8995e1190f8e69c80959aefc32ab1162f542d16c7c8ae388'
assert 'accepted step-223 policy hash is frozen' hash_is "$prev_policy" '7f8d68bce758482b9e96b42e9465d5574d37a0d6c0527508dfe66d44d18a75a3'
assert 'accepted step-223 record hash is frozen' hash_is "$prev_record" '6394ab2be2e303d2e26851065034fc199840a4d701ba87d6b21eb891adc8fac5'
assert 'step-224 helper hash matches generated policy' hash_is "$helper" '8d81a78fc92b35601976d83133e28a0509ab8b7940dca03ad0b0061ef4db8c30'
assert 'step-224 frozen policy hash matches overlay' hash_is "$policy" '5bb886adbbaa6e48649dd094b19e9f9d47e0d00e42af41a9bfef8c6bf8510dbe'
assert 'step-224 frozen record hash matches overlay' hash_is "$record" 'b740a6963432a0e744099a4facad2b627f39d5e5321ac1a784e5d0082efac1a9'
assert 'step-224 helper passes bash syntax validation' bash -n "$helper"
assert 'step-224 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-224 helper rejects unknown option' bash -c '! "$1" --bad-option >/dev/null 2>&1' _ "$helper"

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
assert 'step-224 helper executes successfully' "$helper" --output-dir "$tmp"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/${base}.tsv"

assert 'step-224 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['step']==224 and p['review_status']=='PASS'
assert p['frozen_runtime_identity']['boot_id']=='cd975bdc-a133-47d1-9e92-e9b51bef9d99'
assert p['frozen_runtime_identity']['must_be_revalidated_before_any_future_machine_action'] is True
assert p['preservation_contract']['local_source_v1_must_be_preserved_unchanged'] is True
assert p['preservation_contract']['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
d=p['local_source_v2_design']
assert d['state']=='design-reviewed-not-implemented'
assert d['root'].endswith('/local-source-v2')
assert d['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert d['exact_package_archive_count']==1
assert d['CHECKSUMS_md5_asc']['required'] is True
assert d['CHECKSUMS_md5_asc']['cryptographic_authenticity_claim'] is False
assert d['CHECKSUMS_md5_asc']['future_refresh_requires_CHECKGPG_off'] is True
assert d['priority_tree_contract']['effective_x86_64_priority_trees']==['patches','slackware64','extra','pasture','testing']
assert d['priority_tree_contract']['PACKAGES_TXT_required_for_every_priority_tree'] is True
assert d['priority_tree_contract']['target_stanza_tree']=='slackware64'
assert d['priority_tree_contract']['global_pkglist_row_count_is_not_an_acceptance_guard'] is True
r=p['future_refresh_acceptance_contract']
assert r['not_authorized_by_step_224'] is True
assert r['workdir_strategy']=='transaction-owned-new-empty-workdir'
assert r['pre_refresh_pkglist_must_be_absent'] is True
assert r['workdir_must_not_reuse_var_lib_slackpkg_pkglist'] is True
assert r['refresh_exit_status_must_be_zero'] is True
assert r['stdout_stderr_must_not_contain_error_downloading_from_local_source'] is True
assert r['candidate_guard_scope']=='target-specific-not-global-pkglist-row-count'
assert r['target_candidate_row_count']==1
assert r['predecessor_installed_required_at_binding_time'] is True
assert r['target_source_binding_to_frozen_sha256_and_v2_tree_manifest_required'] is True
assert r['candidate_binding_and_consumption_same_transaction_required'] is True
assert r['evidence_encoding']=='real-tab-tsv'
a=p['authorization']
assert a['repository_only_local_source_v2_design_freeze_authorized'] is True
for k in ('local_source_v2_builder_implementation_authorized','local_source_v2_build_authorized','target_observation_authorized','runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized'):
    assert a[k] is False,k
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze'
PYSEM

for key in step review_status frozen_boot_id local_source_v2_design_state local_source_v2_root CHECKSUMS_md5_asc_required priority_trees refresh_workdir_strategy candidate_guard_scope repository_only_local_source_v2_design_freeze_authorized local_source_v2_build_authorized runtime_rerun_authorized package_action_authorized machine_action_required pause_safe next_stage; do
  assert "record contains $key" record_has "$key"
done
assert 'record binds step 224' record_is step 224
assert 'record requires compatibility asc' record_is CHECKSUMS_md5_asc_required yes
assert 'record freezes all priority trees' record_is priority_trees patches,slackware64,extra,pasture,testing
assert 'record retires global pkglist count' record_is global_pkglist_row_count_guard_retired yes
assert 'record requires fresh transaction workdir' record_is refresh_workdir_strategy transaction-owned-new-empty-workdir
assert 'record keeps builder implementation closed' record_is local_source_v2_builder_implementation_authorized no
assert 'record keeps v2 build closed' record_is local_source_v2_build_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record requires no machine action' record_is machine_action_required no
assert 'record names design freeze next' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze
assert 'document preserves v1 as immutable history' grep -Fq '`local-source-v1`, its external manifest' "$doc"
assert 'document states asc is compatibility only' grep -Fq 'compatibility artifact only' "$doc"
assert 'document freezes priority tree set' grep -Fq '`patches`, `slackware64`, `extra`, `pasture`, and `testing`' "$doc"
assert 'document requires transaction-owned empty workdir' grep -Fq 'transaction-owned empty Slackpkg workdir' "$doc"
assert 'document keeps global row guard retired' grep -Fq 'global `pkglist` row-count requirement remains retired' "$doc"
assert 'CHANGELOG records step 224' grep -Fq '## Phase 1 step 224 kernel-package-edge runtime-transaction remediation local-source-v2 design review' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
