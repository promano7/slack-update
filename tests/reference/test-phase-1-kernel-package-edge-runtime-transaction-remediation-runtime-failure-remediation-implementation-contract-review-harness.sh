#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review.tsv"
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.sh"; prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.md"; prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze.tsv"
v2_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"; failed_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"; failed_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"; failed_exec="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
record_has() { awk -F '\t' -v k="$1" '$1==k {found=1} END {exit !found}' "$record"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for item in "$builder" "$helper" "$doc" "$policy" "$record"; do assert "step-245 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-244 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-244 helper hash is frozen' hash_is "$prev_helper" '1385b1cdedb54c3084095f366eecf238a68d305aad9419dab2c42fa7a92fe98d'
assert 'accepted step-244 document hash is frozen' hash_is "$prev_doc" 'e58d9d00fcc0102b5841699c5db99a819660bef9505d772e319bf7e802e6a40c'
assert 'accepted step-244 harness hash is frozen' hash_is "$prev_harness" 'c31e13ddb05e5a3dd86c990fc617203a5a2abbd93b437e642208ff33a195c4fe'
assert 'accepted step-244 policy hash is frozen' hash_is "$prev_policy" '1b4e137ade321f081b16433b2f009a8667e6fc4417dc4fc685e8bfbcf29bc79d'
assert 'accepted step-244 record hash is frozen' hash_is "$prev_record" 'e204082d58b7df1ccaa6cacb712b36b4873c14b6b26bf16c1c6050bd613b0047'
assert 'historical local-source-v2 builder remains frozen' hash_is "$v2_builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'historical failed executor body remains frozen' hash_is "$failed_body" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
assert 'historical failed executor builder remains frozen' hash_is "$failed_builder" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
assert 'historical failed executor remains frozen' hash_is "$failed_exec" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
assert 'reviewed local-source-v3 builder hash is frozen' hash_is "$builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'step-245 helper hash is frozen' hash_is "$helper" 'cfb13ed97cf819fa942dbcc7437e34d2b94fd54400b35c1b9901bdd000460515'
assert 'step-245 document hash is frozen' hash_is "$doc" 'b99b485cff14f5bad74e8c18780824902d024ba83ad9e2b3582abb28c33d3994'
assert 'step-245 policy hash is frozen' hash_is "$policy" 'd95c7374cbd9944f6d9de7c6b04ced88b92fd262c0f4a2d3f5eb94097d02b83c'
assert 'step-245 record hash is frozen' hash_is "$record" '385e2f5cf95b98ddcd844eb0b6470cd04f4cb57d5429e3ec7ef87f3b00e8d33c'
assert 'v3 builder passes bash syntax validation' bash -n "$builder"
assert 'step-245 helper passes bash syntax validation' bash -n "$helper"
assert 'v3 builder exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$builder"
assert 'v3 builder rejects missing acknowledgement' bash -c '! "$1" >/dev/null 2>&1' _ "$builder"
assert 'v3 builder rejects unknown acknowledgement' bash -c '! "$1" --unknown >/dev/null 2>&1' _ "$builder"
assert 'step-245 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-245 helper rejects unknown option' bash -c '! "$1" --bad-option >/dev/null 2>&1' _ "$helper"

repro=$(mktemp -d); testroot=$(mktemp -d); trap 'rm -rf -- "$repro" "$testroot"' EXIT
assert 'step-245 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/${base}.tsv"
assert 'step-245 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['step']==245 and p['review_status']=='PASS' and p['review_only'] is True
b=p['local_source_v3_builder_implementation']; e=p['future_executor_v2_contract']; a=p['authorization']
assert b['state']=='implemented-reviewed-awaiting-freeze'
assert b['execution_acknowledgement']=='--build-local-source-v3'
assert b['repository_test_seam']=='SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1'
assert b['production_paths_overridable'] is False
assert b['root'].endswith('/local-source-v3') and b['exact_package_archive_count']==1
asc=b['compatibility_asc']; assert asc['required_marker_text']=='PGP compatibility marker for Slackpkg checkchangelog only.'
assert asc['literal_PGP_marker_required'] and asc['no_cryptographic_authenticity_claim_required'] and asc['BEGIN_PGP_SIGNATURE_forbidden']
assert e['state']=='reviewed-contract-not-implemented' and e['implementation_must_wait_for_accepted_v3_manifest_identity'] is True
r=e['refresh_success_contract']; assert r['slackpkg_exit_zero_required'] and not r['slackpkg_exit_zero_sufficient']
assert r['human_spaced_error_prefix']=='Error downloading from ' and r['human_spaced_error_must_fail_closed'] and r['hyphenated_literal_guard_forbidden']
assert r['fresh_transaction_owned_pkglist_required'] and r['target_specific_candidate_guard_required'] and r['same_transaction_candidate_binding_required']
assert a['repository_implementation_contract_freeze_authorized'] is True
for k in ('local_source_v3_builder_execution_authorized','local_source_v3_build_authorized','fresh_target_observation_authorized','runtime_executor_v2_implementation_authorized','runtime_executor_transport_authorized','runtime_scenario_execution_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized'):
    assert a[k] is False,k
assert p['machine_action_required'] is False and p['controller_action_required'] is False and p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze'
PYSEM

fixture="$testroot/fixture"; mkdir -p "$fixture/pkgroot/install" "$fixture/pkgroot/usr/include/linux"
cat > "$fixture/pkgroot/install/slack-desc" <<'SLACKDESC'
# HOW TO EDIT THIS FILE:
kernel-headers: kernel-headers (Linux kernel include files)
kernel-headers:
kernel-headers: Synthetic v3 repository harness package.
SLACKDESC
printf '#define SYNTHETIC_V3_KERNEL_HEADER 1\n' > "$fixture/pkgroot/usr/include/linux/synthetic-v3.h"
fixture_pkg="$fixture/kernel-headers-6.18.45-x86-1.txz"
( cd "$fixture/pkgroot" && tar -cJf "$fixture_pkg" . )
fixture_sha=$(sha "$fixture_pkg")
SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$builder"
assert 'library seam accepts valid regular input and SHA' validate_input_file "$fixture_pkg" 'kernel-headers-6.18.45-x86-1.txz' "$fixture_sha"
assert 'library seam rejects wrong input SHA' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$1"; ! validate_input_file "$2" kernel-headers-6.18.45-x86-1.txz 0000000000000000000000000000000000000000000000000000000000000000 >/dev/null 2>&1' _ "$builder" "$fixture_pkg"
ln -s "$fixture_pkg" "$fixture/kernel-headers-symlink.txz"
assert 'library seam rejects symlink input' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$1"; ! validate_input_file "$2" kernel-headers-symlink.txz "$3" >/dev/null 2>&1' _ "$builder" "$fixture/kernel-headers-symlink.txz" "$fixture_sha"
source1="$testroot/source1"; scratch1="$testroot/scratch1"; source2="$testroot/source2"; scratch2="$testroot/scratch2"
assert 'library seam renders v3 source from valid fixture' render_source_tree "$fixture_pkg" "$source1" "$scratch1" "$fixture_sha"
assert 'library seam validates exact v3 source contract' validate_source_tree "$source1" "$fixture_sha"
assert 'second v3 render succeeds for determinism comparison' render_source_tree "$fixture_pkg" "$source2" "$scratch2" "$fixture_sha"
assert 'second v3 render validates exact source contract' validate_source_tree "$source2" "$fixture_sha"
manifest1="$testroot/source1.tree.sha256"; side1="$testroot/source1.tree.sha256.sha256"; manifest2="$testroot/source2.tree.sha256"; side2="$testroot/source2.tree.sha256.sha256"
write_tree_manifest "$source1" "$manifest1" "$side1"; write_tree_manifest "$source2" "$manifest2" "$side2"
assert 'library seam writes and verifies v3 external tree manifest' verify_tree_manifest "$source1" "$manifest1" "$side1"
assert 'deterministic v3 renders have identical tree manifests' cmp -s "$manifest1" "$manifest2"
assert 'rendered v3 exposes exactly one package archive' bash -c '[[ $(find "$1" -type f -name "*.txz" | wc -l) -eq 1 ]]' _ "$source1"
assert 'rendered v3 excludes predecessor archive' bash -c '[[ ! -e "$1/slackware64/d/kernel-headers-6.18.44-x86-1.txz" ]]' _ "$source1"
assert 'top-level PACKAGES.TXT has exactly one target stanza' bash -c '[[ $(grep -c "^PACKAGE NAME:  " "$1/PACKAGES.TXT") -eq 1 ]]' _ "$source1"
assert 'slackware64 PACKAGES.TXT has exactly one target stanza' bash -c '[[ $(grep -c "^PACKAGE NAME:  " "$1/slackware64/PACKAGES.TXT") -eq 1 ]]' _ "$source1"
for tree in patches extra pasture testing; do assert "$tree PACKAGES.TXT has zero package stanzas" bash -c '[[ $(grep -c "^PACKAGE NAME:  " "$1/$2/PACKAGES.TXT" || true) -eq 0 ]]' _ "$source1" "$tree"; done
assert 'top-level and slackware64 target indexes are identical' cmp -s "$source1/PACKAGES.TXT" "$source1/slackware64/PACKAGES.TXT"
assert 'PACKAGES.TXT description comes from fixture slack-desc' grep -Fq 'Synthetic v3 repository harness package.' "$source1/PACKAGES.TXT"
assert 'compatibility asc contains exact Slackpkg PGP marker' grep -Fxq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$source1/CHECKSUMS.md5.asc"
assert 'compatibility asc makes no authenticity claim' grep -Fq 'No cryptographic authenticity claim is made by this file.' "$source1/CHECKSUMS.md5.asc"
assert 'compatibility asc states it is not an OpenPGP signature' grep -Fq 'This file is not an OpenPGP signature and MUST NOT be treated as one.' "$source1/CHECKSUMS.md5.asc"
assert 'compatibility asc does not impersonate PGP signature block' bash -c '! grep -Fq "BEGIN PGP SIGNATURE" "$1/CHECKSUMS.md5.asc"' _ "$source1"
assert 'FILELIST enumerates target package' grep -Fxq './slackware64/d/kernel-headers-6.18.45-x86-1.txz' "$source1/FILELIST.TXT"
assert 'FILELIST enumerates compatibility asc' grep -Fxq './CHECKSUMS.md5.asc' "$source1/FILELIST.TXT"
assert 'FILELIST row count matches regular-file count' bash -c '[[ $(wc -l < "$1/FILELIST.TXT") -eq $(find "$1" -type f | wc -l) ]]' _ "$source1"
assert 'CHECKSUMS.md5 excludes itself' bash -c '! grep -Fq "MD5 (./CHECKSUMS.md5)" "$1/CHECKSUMS.md5"' _ "$source1"
assert 'CHECKSUMS.md5 excludes compatibility asc' bash -c '! grep -Fq "MD5 (./CHECKSUMS.md5.asc)" "$1/CHECKSUMS.md5"' _ "$source1"
unused_source="$testroot/not-yet-created"; unused_manifest="$testroot/not-yet-created.tree.sha256"; unused_side="$testroot/not-yet-created.tree.sha256.sha256"
assert 'output preflight accepts absent v3 destinations' preflight_output_paths "$unused_source" "$unused_manifest" "$unused_side"
mkdir "$unused_source"; printf 'sentinel\n' > "$unused_source/sentinel"
assert 'output preflight rejects pre-existing final v3 source' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$1"; ! preflight_output_paths "$2" "$3" "$4" >/dev/null 2>&1' _ "$builder" "$unused_source" "$unused_manifest" "$unused_side"
assert 'pre-existing final v3 source remains untouched on rejection' bash -c '[[ $(cat "$1/sentinel") == sentinel ]]' _ "$unused_source"
assert 'v3 builder contains no local-source-v2 path' bash -c '! grep -Fq "local-source-v2" "$1"' _ "$builder"
assert 'future executor-v2 files are not implemented yet' bash -c '[[ ! -e "$1/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh" && ! -e "$1/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh" && ! -e "$1/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh" ]]' _ "$repo_root"
for key in step review_status local_source_v3_builder_implementation_state local_source_v3_builder_path local_source_v3_builder_sha256 local_source_v3_execution_acknowledgement compatibility_asc_PGP_marker_required future_executor_v2_state future_executor_v2_manifest_identity_required_before_implementation future_refresh_error_guard future_hyphenated_literal_guard repository_implementation_contract_freeze_authorized local_source_v3_builder_execution_authorized local_source_v3_build_authorized runtime_executor_v2_implementation_authorized runtime_rerun_authorized machine_action_required pause_safe next_stage; do assert "record contains $key" record_has "$key"; done
assert 'record freezes step 245' record_is step 245
assert 'record freezes reviewed v3 builder SHA' record_is local_source_v3_builder_sha256 '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'record freezes exact PGP marker requirement' record_is compatibility_asc_PGP_marker_required yes
assert 'record keeps future executor unimplemented' record_is future_executor_v2_state reviewed-contract-not-implemented
assert 'record requires accepted v3 manifest before executor implementation' record_is future_executor_v2_manifest_identity_required_before_implementation yes
assert 'record forbids old hyphenated guard' record_is future_hyphenated_literal_guard forbidden
assert 'record keeps v3 build closed' record_is local_source_v3_build_authorized no
assert 'record routes only to contract freeze' record_is next_stage 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze'
assert 'document records reviewed v3 builder SHA' grep -Fq '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582' "$doc"
assert 'document records exact compatibility marker' grep -Fq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$doc"
assert 'document records executor implementation deferred until accepted v3 manifest' grep -Fq 'wait until the v3 build result has been accepted' "$doc"
assert 'step-245 files have no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4" "$5"' _ "$builder" "$helper" "$doc" "$policy" "$record"
assert 'CHANGELOG records step 245' grep -Fq '## Phase 1 step 245 ' "$repo_root/CHANGELOG.md"
assert 'v3 builder contains no package/boot/reboot mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$builder"
assert 'v3 builder contains no network client command' bash -c '! grep -Eq "^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh)[[:space:]]" "$1"' _ "$builder"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
