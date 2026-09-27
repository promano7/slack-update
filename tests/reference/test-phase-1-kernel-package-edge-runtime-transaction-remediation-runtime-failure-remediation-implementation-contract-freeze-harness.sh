#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.sh"; doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"; builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review.sh"; prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review.md"; prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review.tsv"
v2_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"; failed_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"; failed_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"; failed_exec="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for item in "$helper" "$doc" "$policy" "$record" "$builder"; do assert "step-246 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-245 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-245 helper hash is frozen' hash_is "$prev_helper" 'cfb13ed97cf819fa942dbcc7437e34d2b94fd54400b35c1b9901bdd000460515'
assert 'accepted step-245 document hash is frozen' hash_is "$prev_doc" 'b99b485cff14f5bad74e8c18780824902d024ba83ad9e2b3582abb28c33d3994'
assert 'accepted step-245 harness hash is frozen' hash_is "$prev_harness" 'f4942f581d7ea74d746ab00decf953c62b28cd128daaf5b66485185ae9baba19'
assert 'accepted step-245 policy hash is frozen' hash_is "$prev_policy" 'd95c7374cbd9944f6d9de7c6b04ced88b92fd262c0f4a2d3f5eb94097d02b83c'
assert 'accepted step-245 record hash is frozen' hash_is "$prev_record" '385e2f5cf95b98ddcd844eb0b6470cd04f4cb57d5429e3ec7ef87f3b00e8d33c'
assert 'accepted v3 builder hash is frozen' hash_is "$builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'historical v2 builder remains frozen' hash_is "$v2_builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'historical failed executor body remains frozen' hash_is "$failed_body" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
assert 'historical failed executor builder remains frozen' hash_is "$failed_builder" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
assert 'historical failed executor remains frozen' hash_is "$failed_exec" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
assert 'step-246 helper hash is frozen' hash_is "$helper" '8fd3a7268c7fa2ea5b55a2dc1d154b7340ac673458513105b617aa78bccb597c'
assert 'step-246 document hash is frozen' hash_is "$doc" '8673e5fb07a728ed8e65b9253d2e33d031f6a0dd9051d950b696fd421a1630f5'
assert 'step-246 policy hash is frozen' hash_is "$policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0'
assert 'step-246 record hash is frozen' hash_is "$record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071'
assert 'v3 builder passes bash syntax validation' bash -n "$builder"
assert 'step-246 helper passes bash syntax validation' bash -n "$helper"
assert 'v3 builder exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$builder"
assert 'v3 builder rejects missing acknowledgement' bash -c '! "$1" >/dev/null 2>&1' _ "$builder"
assert 'step-246 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-246 helper rejects unknown option' bash -c '! "$1" --bad >/dev/null 2>&1' _ "$helper"

repro=$(mktemp -d); testroot=$(mktemp -d); trap 'rm -rf -- "$repro" "$testroot"' EXIT
assert 'step-246 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"
assert 'step-246 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==246 and p['freeze_status']=='PASS' and p['review_only'] is True
b=p['local_source_v3_builder_implementation']; e=p['future_executor_v2_contract']; a=p['authorization']; f=p['implementation_contract_freeze']
assert b['state']=='implemented-frozen-not-executed'
assert b['builder_sha256']=='56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582' and b['execution_acknowledgement']=='--build-local-source-v3'
assert b['compatibility_asc']['required_marker_text']=='PGP compatibility marker for Slackpkg checkchangelog only.'
assert b['compatibility_asc']['BEGIN_PGP_SIGNATURE_forbidden'] is True
assert e['state']=='reviewed-frozen-not-implemented' and e['implementation_must_wait_for_accepted_v3_manifest_identity'] is True
r=e['refresh_success_contract']; assert r['human_spaced_error_prefix']=='Error downloading from ' and r['hyphenated_literal_guard_forbidden'] is True
assert f['accepted_step_245_builder_bytes_are_immutable'] and f['fresh_prebuild_target_revalidation_required_before_builder_transport_or_execution']
assert f['future_executor_v2_must_bind_accepted_v3_manifest_identity']
assert a['repository_prebuild_fresh_target_revalidation_review_authorized'] is True
for k,v in a.items():
    if k!='repository_prebuild_fresh_target_revalidation_review_authorized': assert v is False,k
assert p['machine_action_required'] is False and p['pause_safe'] is False and p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'
PYSEM

fixture="$testroot/fixture"; mkdir -p "$fixture/pkgroot/install" "$fixture/pkgroot/usr/include/linux"
cat > "$fixture/pkgroot/install/slack-desc" <<'SLACKDESC'
kernel-headers: kernel-headers (Linux kernel include files)
kernel-headers:
kernel-headers: Synthetic step-246 freeze package.
SLACKDESC
printf '#define SYNTHETIC_STEP246 1\n' > "$fixture/pkgroot/usr/include/linux/step246.h"
fixture_pkg="$fixture/kernel-headers-6.18.45-x86-1.txz"; ( cd "$fixture/pkgroot" && tar -cJf "$fixture_pkg" . ); fixture_sha=$(sha "$fixture_pkg")
SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$builder"
source1="$testroot/source1"; scratch1="$testroot/scratch1"; source2="$testroot/source2"; scratch2="$testroot/scratch2"
assert 'freeze seam renders v3 source' render_source_tree "$fixture_pkg" "$source1" "$scratch1" "$fixture_sha"
assert 'freeze seam validates exact v3 source contract' validate_source_tree "$source1" "$fixture_sha"
assert 'freeze seam second render succeeds' render_source_tree "$fixture_pkg" "$source2" "$scratch2" "$fixture_sha"
assert 'freeze seam second render validates' validate_source_tree "$source2" "$fixture_sha"
manifest1="$testroot/source1.tree.sha256"; side1="$testroot/source1.tree.sha256.sha256"; manifest2="$testroot/source2.tree.sha256"; side2="$testroot/source2.tree.sha256.sha256"
write_tree_manifest "$source1" "$manifest1" "$side1"; write_tree_manifest "$source2" "$manifest2" "$side2"
assert 'freeze seam verifies external tree manifest' verify_tree_manifest "$source1" "$manifest1" "$side1"
assert 'frozen builder remains deterministic' cmp -s "$manifest1" "$manifest2"
assert 'frozen v3 exposes exactly one package archive' bash -c '[[ $(find "$1" -type f -name "*.txz" | wc -l) -eq 1 ]]' _ "$source1"
assert 'frozen v3 excludes predecessor archive' bash -c '[[ ! -e "$1/slackware64/d/kernel-headers-6.18.44-x86-1.txz" ]]' _ "$source1"
assert 'frozen compatibility asc contains exact PGP marker' grep -Fxq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$source1/CHECKSUMS.md5.asc"
assert 'frozen compatibility asc makes no authenticity claim' grep -Fq 'No cryptographic authenticity claim is made by this file.' "$source1/CHECKSUMS.md5.asc"
assert 'frozen compatibility asc does not impersonate signature block' bash -c '! grep -Fq "BEGIN PGP SIGNATURE" "$1/CHECKSUMS.md5.asc"' _ "$source1"
unused="$testroot/preexisting"; manifest="$testroot/preexisting.tree.sha256"; side="$testroot/preexisting.tree.sha256.sha256"; mkdir "$unused"; printf 'sentinel\n' > "$unused/sentinel"
assert 'frozen builder rejects pre-existing final v3 source' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$1"; ! preflight_output_paths "$2" "$3" "$4" >/dev/null 2>&1' _ "$builder" "$unused" "$manifest" "$side"
assert 'pre-existing v3 source remains untouched after rejection' bash -c '[[ $(cat "$1/sentinel") == sentinel ]]' _ "$unused"
assert 'future executor-v2 remains absent at freeze' bash -c '[[ ! -e "$1/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh" && ! -e "$1/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh" && ! -e "$1/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh" ]]' _ "$repo_root"
assert 'record freezes builder implementation state' record_is local_source_v3_builder_implementation_state implemented-frozen-not-executed
assert 'record freezes builder SHA' record_is local_source_v3_builder_sha256 '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'record freezes future executor state' record_is future_executor_v2_state reviewed-frozen-not-implemented
assert 'record requires fresh target revalidation' record_is fresh_prebuild_target_revalidation_required_before_builder_execution yes
assert 'record keeps target observation closed' record_is target_observation_authorized no
assert 'record keeps v3 build closed' record_is local_source_v3_build_authorized no
assert 'record routes to prebuild revalidation review' record_is next_stage 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'
assert 'reference document records exact builder SHA' grep -Fq '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582' "$doc"
assert 'reference document records exact PGP marker' grep -Fq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$doc"
assert 'reference document keeps executor unimplemented' grep -Fq 'remains **not implemented**' "$doc"
assert 'step-246 files have no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4"' _ "$helper" "$doc" "$policy" "$record"
assert 'CHANGELOG records step 246' grep -Fq '## Phase 1 step 246 ' "$repo_root/CHANGELOG.md"
assert 'step-246 helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$helper"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
