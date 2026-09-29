#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review'
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"

passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }

for item in "$helper" "$doc" "$policy" "$record"; do assert "step-261 ${item##*/} exists as regular file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record" "$v3_builder"; do assert "accepted input ${item##*/} exists as regular file" regular "$item"; done
assert 'accepted step-260 helper SHA-256 matches' hash_is "$prev_helper" '7c8e4adf631352887d142a984d7433df3550741ad74671071ca875134275c09c'
assert 'accepted step-260 document SHA-256 matches' hash_is "$prev_doc" '336ef9f38fe3d7a4319b769a7ed375169a161d6c2f4302b913bacd12be980fe4'
assert 'accepted step-260 harness SHA-256 matches' hash_is "$prev_harness" 'd0fa4a58c3848bd26a512ef9a560120a7c8f30e9482a27c0c6837ed3a29cc58d'
assert 'accepted step-260 policy SHA-256 matches' hash_is "$prev_policy" '72012226ec638b0cf9da0ab0514b391a88223958cb2c5567ad4aeca356ec9872'
assert 'accepted step-260 record SHA-256 matches' hash_is "$prev_record" '266acba4c83d9a346e032433221776e14d67e7dde5bba49a5bb0da62b95aa780'
assert 'accepted v3 builder SHA-256 remains frozen' hash_is "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'step-261 helper SHA-256 matches' hash_is "$helper" '6768757c0eb8524a7b5e75ff71281f1614f2d3a04103825d3f662c5a44c50393'
assert 'step-261 document SHA-256 matches' hash_is "$doc" 'd90684734c2de428d84ae0bf01c34c62c78ba234cb59598cb47ceeb910516da7'
assert 'step-261 policy SHA-256 matches' hash_is "$policy" 'db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef'
assert 'step-261 record SHA-256 matches' hash_is "$record" 'b733228aeca5be7055cb84dff306744fb41f49f13c7cc8c1d57bed7401c94981'
assert 'step-261 helper passes bash syntax validation' bash -n "$helper"
assert 'step-261 harness passes bash syntax validation' bash -n "${BASH_SOURCE[0]}"
assert 'step-261 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-261 helper rejects unknown option' bash -c '! "$1" --bad-option >/dev/null 2>&1' _ "$helper"

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
assert 'step-261 helper executes successfully' "$helper" --output-dir "$tmp"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/${base}.tsv"

assert 'step-261 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['step']==261 and p['review_status']=='PASS' and p['review_only'] is True
assert p['accepted_v3_builder']['sha256']=='80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert p['accepted_v3_builder']['must_remain_unchanged'] is True
assert p['frozen_inputs']['functional_remediation_scope']=='CHECKSUMS.md5 record representation only'
d=p['builder_design']
assert d['state']=='design-reviewed-not-implemented'
assert d['production_builder_path'].endswith('local-source-v4-build.sh')
assert d['production_switch']=='--build-local-source-v4'
assert d['library_only_seam']=='SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY'
assert d['output_identity']['local_source_root'].endswith('/local-source-v4')
w=d['checksum_writer_design']
assert w['writer_command']=='md5sum -- "$rel"'
assert w['tagged_writer_forbidden'] is True
assert w['excluded_paths']==['./CHECKSUMS.md5','./CHECKSUMS.md5.asc']
v=d['checksum_validator_design']
for k in ('missing_binding_rejected','duplicate_binding_rejected','malformed_binding_rejected','extra_binding_rejected_by_count_plus_exact_per_file_proof','binary_marker_binding_not_accepted'):
    assert v[k] is True,k
u=d['unchanged_code_and_behavior_contract']
assert u['priority_tree_set']==['patches','slackware64','extra','pasture','testing']
for k in ('input_validation_and_target_sha256_binding','output_path_absence_preflight','exactly_one_target_package_archive','predecessor_absent','compatibility_asc_semantics','deterministic_mtime_normalization','external_sha256_tree_manifest_and_sidecar','post_publish_manifest_verification','local_only_no_network','no_package_slackpkg_boot_reboot_or_persistent_config_action'):
    assert u[k] is True,k
r=d['implementation_review_requirements']
for k in ('exact_v3_baseline_hash_must_still_match','diff_must_be_limited_to_authorized_identity_and_checksum_changes','synthetic_tree_tests_must_prove_valid_untagged_bindings_pass','synthetic_tree_tests_must_prove_tagged_binding_fails','synthetic_tree_tests_must_prove_missing_binding_fails','synthetic_tree_tests_must_prove_duplicate_binding_fails','synthetic_tree_tests_must_prove_malformed_or_extra_binding_fails','production_execution_forbidden_during_implementation_review'):
    assert r[k] is True,k
a=p['authorization']
assert a['repository_only_v4_builder_design_freeze_authorized'] is True
for k,vv in a.items():
    if k!='repository_only_v4_builder_design_freeze_authorized': assert vv is False,k
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze'
PYSEM

assert 'record binds step 261' record_is step 261
assert 'record marks design reviewed but not implemented' record_is builder_design_state design-reviewed-not-implemented
assert 'record freezes narrow remediation scope' record_is functional_remediation_scope CHECKSUMS.md5-record-representation-only
assert 'record selects untagged writer' record_is checksum_writer md5sum-untagged-path-final
assert 'record forbids tagged checksums' record_is tagged_checksum_records_authorized no
assert 'record requires exact binding validation' record_is validator_requires_exact_one_binding_per_eligible_file yes
assert 'record keeps target identity frozen' record_is target_package_identity_change_authorized no
assert 'record keeps v3 immutable' record_is v3_builder_mutation_authorized no
assert 'record keeps v4 implementation closed' record_is v4_builder_implementation_authorized no
assert 'record keeps v4 build closed' record_is v4_build_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record requires no machine action' record_is machine_action_required no
assert 'record names design freeze next' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze
assert 'document names exact untagged line shape' grep -Fq '<32-lowercase-hex-md5>  ./relative/path' "$doc"
assert 'document forbids tagged records' grep -Fq 'GNU tagged records of the form `MD5 (...) = ...` are forbidden.' "$doc"
assert 'document preserves priority trees' grep -Fq '`patches`, `slackware64`, `extra`, `pasture`, and `testing`' "$doc"
assert 'document requires synthetic negative tests' grep -Fq 'tagged, missing, duplicate, malformed, or extra bindings fail' "$doc"
assert 'CHANGELOG records step 261' grep -Fq '## Phase 1 step 261 kernel-package-edge runtime-transaction remediation local-source-v4 builder design review' "$repo_root/CHANGELOG.md"
assert 'helper contains no executable network package boot reboot or shutdown command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

for f in "$helper" "$doc" "$policy" "$record"; do assert "${f##*/} contains no trailing whitespace" bash -c '! grep -nE "[[:blank:]]+$" "$1" >/dev/null' _ "$f"; done
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
