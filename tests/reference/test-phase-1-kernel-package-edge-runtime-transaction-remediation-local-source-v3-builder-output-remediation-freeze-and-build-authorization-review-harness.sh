#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review'
helper="$repo_root/tools/reference/${base}.sh"; doc="$repo_root/docs/reference/${base}.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-revalidation-freeze-and-builder-output-contract-remediation-review'; prev_helper="$repo_root/tools/reference/${prev}.sh"; prev_doc="$repo_root/docs/reference/${prev}.md"; prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"; new_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
for item in "$helper" "$doc" "$policy" "$record" "$old_builder" "$new_builder"; do assert "step-249 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-248 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-248 helper hash is frozen' hash_is "$prev_helper" '5230b8d9f9d5fb06d6da72adc7f8b997f79a0faf81c3f7c5db8767144416bc00'
assert 'accepted step-248 document hash is frozen' hash_is "$prev_doc" '2283eed2db70e77c70383505532435449aec6acc27306d06a5f1bf458f13aa10'
assert 'accepted step-248 harness hash is frozen' hash_is "$prev_harness" '07cf31c476ce02d0360b067a0e0f03cddb776663a00bcb3e01b315170984a946'
assert 'accepted step-248 policy hash is frozen' hash_is "$prev_policy" '6b93336f6f35702e604fcad956f5c05570572d4d296c5a7d95369226abd40300'
assert 'accepted step-248 record hash is frozen' hash_is "$prev_record" 'b3523649344b28dc14583939750e9ba03488fd81ee3dbf225fa819cc4512de67'
assert 'historical v3 builder remains frozen' hash_is "$old_builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'corrected builder r1 hash is frozen for authorization' hash_is "$new_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'corrected builder r1 passes bash syntax validation' bash -n "$new_builder"
assert 'step-249 helper passes bash syntax validation' bash -n "$helper"
assert 'corrected builder exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$new_builder"
assert 'corrected builder rejects missing acknowledgement' bash -c '! "$1" >/dev/null 2>&1' _ "$new_builder"
assert 'step-249 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-249 helper rejects unknown option' bash -c '! "$1" --bad >/dev/null 2>&1' _ "$helper"
repro=$(mktemp -d); testroot=$(mktemp -d); trap 'rm -rf -- "$repro" "$testroot"' EXIT
assert 'step-249 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/${base}.tsv"
assert 'step-249 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==249 and p['review_status']=='PASS'
a=p['authorization']; s=p['single_build_authorization']; f=p['builder_output_remediation_freeze']; o=p['consumed_prebuild_v3_observation']
assert o['prebuild_v3_revalidation_status']=='PASS' and o['probe_authority_consumed'] is True
assert o['fresh_boot_id']=='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'
assert f['historical_builder_execution_count']==0
assert f['corrected_builder_sha256']=='80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert f['corrected_builder_state']=='implemented-frozen-authorized-for-single-build'
assert s['state']=='authorized-not-executed' and s['authorization_use_count']==1
assert s['authority_consumed_on_builder_start'] is True and s['no_second_execution_authorized'] is True
assert s['same_boot_required_at_execution'] is True
assert a['local_source_v3_builder_transport_authorized'] is True
assert a['local_source_v3_builder_execution_authorized'] is True
assert a['local_source_v3_build_authorized'] is True
assert a['local_source_v3_build_result_review_authorized_after_successful_build'] is True
for k,v in a.items():
    if k not in ('local_source_v3_builder_transport_authorized','local_source_v3_builder_execution_authorized','local_source_v3_build_authorized','local_source_v3_build_result_review_authorized_after_successful_build'):
        assert v is False,(k,v)
assert p['machine_action_required'] is True and p['controller_action_required'] is True
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause'
PYSEM
assert 'corrected builder still differs only by two evidence labels' python3 - "$old_builder" "$new_builder" <<'PYDIFF'
import pathlib,sys
old=pathlib.Path(sys.argv[1]).read_text(); new=pathlib.Path(sys.argv[2]).read_text()
expected=old.replace('local_source_v2_build_status','local_source_v3_build_status').replace('local_source_v2_root','local_source_v3_root')
assert new==expected
PYDIFF
fixture="$testroot/fixture"; mkdir -p "$fixture/pkgroot/install" "$fixture/pkgroot/usr/include/linux"
cat > "$fixture/pkgroot/install/slack-desc" <<'SLACKDESC'
kernel-headers: kernel-headers (Linux kernel include files)
kernel-headers:
kernel-headers: Synthetic step-249 freeze fixture.
SLACKDESC
printf '#define SYNTHETIC_STEP249 1\n' > "$fixture/pkgroot/usr/include/linux/step249.h"
fixture_pkg="$fixture/kernel-headers-6.18.45-x86-1.txz"; ( cd "$fixture/pkgroot" && tar -cJf "$fixture_pkg" . ); fixture_sha=$(sha "$fixture_pkg")
SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$new_builder"
source_one="$testroot/source-one"; scratch_one="$testroot/scratch-one"; manifest_one="$testroot/one.tree.sha256"; side_one="$testroot/one.tree.sha256.sha256"
source_two="$testroot/source-two"; scratch_two="$testroot/scratch-two"; manifest_two="$testroot/two.tree.sha256"; side_two="$testroot/two.tree.sha256.sha256"
assert 'freeze seam renders corrected v3 source' render_source_tree "$fixture_pkg" "$source_one" "$scratch_one" "$fixture_sha"
assert 'freeze seam validates corrected v3 source' validate_source_tree "$source_one" "$fixture_sha"
write_tree_manifest "$source_one" "$manifest_one" "$side_one"
assert 'freeze seam renders corrected v3 source a second time' render_source_tree "$fixture_pkg" "$source_two" "$scratch_two" "$fixture_sha"
assert 'freeze seam validates second corrected v3 source' validate_source_tree "$source_two" "$fixture_sha"
write_tree_manifest "$source_two" "$manifest_two" "$side_two"
assert 'corrected builder remains deterministic at authorization freeze' cmp -s "$manifest_one" "$manifest_two"
assert 'corrected v3 compatibility asc retains exact PGP marker' grep -Fxq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$source_one/CHECKSUMS.md5.asc"
assert 'corrected v3 compatibility asc does not impersonate signature block' bash -c '! grep -Fq "BEGIN PGP SIGNATURE" "$1/CHECKSUMS.md5.asc"' _ "$source_one"
assert 'record consumes fresh v3 observation' record_is prebuild_v3_observation_state consumed-and-frozen-for-single-v3-build-authorization
assert 'record freezes corrected builder r1' record_is corrected_v3_builder_r1_sha256 '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'record opens builder transport' record_is local_source_v3_builder_transport_authorized yes
assert 'record opens builder execution' record_is local_source_v3_builder_execution_authorized yes
assert 'record opens one v3 build' record_is local_source_v3_build_authorized yes
assert 'record consumes authority on builder start' record_is authority_consumed_on_builder_start yes
assert 'record forbids second builder execution' record_is second_builder_execution_forbidden yes
assert 'record keeps executor-v2 implementation closed' record_is runtime_executor_v2_implementation_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record routes to step-250 strong-safe-pause review' record_is next_stage 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause'
assert 'reference document freezes exact corrected builder SHA' grep -Fq '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' "$doc"
assert 'reference document requires single-use builder execution' grep -Fq 'Exactly one copy/transport' "$doc"
assert 'reference document freezes v3 PASS output label' grep -Fq 'local_source_v3_build_status=PASS' "$doc"
assert 'reference document keeps executor v2 closed' grep -Fq 'reviewed-frozen-not-implemented' "$doc"
assert 'step-249 files have no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4"' _ "$helper" "$doc" "$policy" "$record"
assert 'CHANGELOG records step 249' grep -Fq '## Phase 1 step 249 ' "$repo_root/CHANGELOG.md"
assert 'step-249 helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$helper"
assert 'corrected builder contains no package or network client command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|curl|wget|git)[[:space:]]" "$1"' _ "$new_builder"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
