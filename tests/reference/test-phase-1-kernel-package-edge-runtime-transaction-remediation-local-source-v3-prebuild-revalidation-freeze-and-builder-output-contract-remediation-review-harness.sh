#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-revalidation-freeze-and-builder-output-contract-remediation-review'
helper="$repo_root/tools/reference/${base}.sh"; doc="$repo_root/docs/reference/${base}.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"; new_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'; prev_helper="$repo_root/tools/reference/${prev}.sh"; prev_probe="$repo_root/tools/reference/${prev}-probe.sh"; prev_doc="$repo_root/docs/reference/${prev}.md"; prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
for item in "$helper" "$doc" "$policy" "$record" "$old_builder" "$new_builder"; do assert "step-248 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_probe" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-247 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-247 helper hash is frozen' hash_is "$prev_helper" '82f00abac2aafb0b79ca74e7d210bd96899cb91a93e6e735b1e3d3171de91941'
assert 'accepted step-247 probe hash is frozen' hash_is "$prev_probe" '7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949'
assert 'accepted step-247 document hash is frozen' hash_is "$prev_doc" 'afd62ddaf9bbae7554a133997bd2b6ea0101ffdb2cfedf2bdcac98341251459e'
assert 'accepted step-247 harness hash is frozen' hash_is "$prev_harness" '1543be40544074240e1080bab037555d0389d05380694f5c77eccf8622c1f746'
assert 'accepted step-247 policy hash is frozen' hash_is "$prev_policy" '08973f578b54e330e7c2219fe92d99192cf01379f2667627850515396f7f2fd9'
assert 'accepted step-247 record hash is frozen' hash_is "$prev_record" '2535d7488cab5268a73e779e8fd6c4a110a8c0797ab87616bf0778321f4fb759'
assert 'historical v3 builder hash remains frozen' hash_is "$old_builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'corrected v3 builder r1 hash is frozen for review' hash_is "$new_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'old v3 builder passes bash syntax validation' bash -n "$old_builder"
assert 'corrected v3 builder r1 passes bash syntax validation' bash -n "$new_builder"
assert 'step-248 helper passes bash syntax validation' bash -n "$helper"
assert 'corrected v3 builder exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$new_builder"
assert 'corrected v3 builder rejects missing acknowledgement' bash -c '! "$1" >/dev/null 2>&1' _ "$new_builder"
assert 'step-248 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-248 helper rejects unknown option' bash -c '! "$1" --bad >/dev/null 2>&1' _ "$helper"
repro=$(mktemp -d); testroot=$(mktemp -d); trap 'rm -rf -- "$repro" "$testroot"' EXIT
assert 'step-248 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/${base}.tsv"
assert 'step-248 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==248 and p['review_status']=='PASS' and p['review_only'] is True
obs=p['prebuild_v3_observation']; rem=p['builder_output_contract_remediation']; a=p['authorization']
assert obs['state']=='consumed-and-frozen' and obs['prebuild_v3_revalidation_status']=='PASS'
assert obs['fresh_boot_id']=='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'
assert obs['local_source_v3_final_outputs_absent'] and obs['local_source_v3_temporary_build_roots_absent']
assert rem['defect_state']=='confirmed-before-build-authorization'
assert rem['historical_builder_execution_count']==0
assert rem['historical_builder_sha256']=='56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert rem['corrected_builder_sha256']=='80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert rem['allowed_change_count']==2 and rem['build_semantics_unchanged'] is True
assert a['repository_corrected_builder_freeze_and_build_authorization_review_authorized'] is True
for k,v in a.items():
    if k!='repository_corrected_builder_freeze_and_build_authorization_review_authorized': assert v is False,k
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review'
PYSEM
assert 'corrected builder changes only the two stale output labels' python3 - "$old_builder" "$new_builder" <<'PYDIFF'
import pathlib,sys
old=pathlib.Path(sys.argv[1]).read_text(); new=pathlib.Path(sys.argv[2]).read_text()
assert old.count('local_source_v2_build_status')==1 and old.count('local_source_v2_root')==1
expected=old.replace('local_source_v2_build_status','local_source_v3_build_status').replace('local_source_v2_root','local_source_v3_root')
assert new==expected
assert 'local_source_v2_build_status' not in new and 'local_source_v2_root' not in new
assert new.count('local_source_v3_build_status')==1 and new.count('local_source_v3_root')==1
PYDIFF
fixture="$testroot/fixture"; mkdir -p "$fixture/pkgroot/install" "$fixture/pkgroot/usr/include/linux"
cat > "$fixture/pkgroot/install/slack-desc" <<'SLACKDESC'
kernel-headers: kernel-headers (Linux kernel include files)
kernel-headers:
kernel-headers: Synthetic step-248 builder-equivalence package.
SLACKDESC
printf '#define SYNTHETIC_STEP248 1\n' > "$fixture/pkgroot/usr/include/linux/step248.h"
fixture_pkg="$fixture/kernel-headers-6.18.45-x86-1.txz"; ( cd "$fixture/pkgroot" && tar -cJf "$fixture_pkg" . ); fixture_sha=$(sha "$fixture_pkg")
SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$old_builder"
source_old="$testroot/source-old"; scratch_old="$testroot/scratch-old"; manifest_old="$testroot/old.tree.sha256"; side_old="$testroot/old.tree.sha256.sha256"
assert 'historical builder seam renders v3 source' render_source_tree "$fixture_pkg" "$source_old" "$scratch_old" "$fixture_sha"
assert 'historical builder seam validates v3 source' validate_source_tree "$source_old" "$fixture_sha"
write_tree_manifest "$source_old" "$manifest_old" "$side_old"
SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1 source "$new_builder"
source_new="$testroot/source-new"; scratch_new="$testroot/scratch-new"; manifest_new="$testroot/new.tree.sha256"; side_new="$testroot/new.tree.sha256.sha256"
assert 'corrected builder seam renders v3 source' render_source_tree "$fixture_pkg" "$source_new" "$scratch_new" "$fixture_sha"
assert 'corrected builder seam validates v3 source' validate_source_tree "$source_new" "$fixture_sha"
write_tree_manifest "$source_new" "$manifest_new" "$side_new"
assert 'historical and corrected builders render byte-identical v3 trees' cmp -s "$manifest_old" "$manifest_new"
assert 'corrected compatibility asc retains exact PGP marker' grep -Fxq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$source_new/CHECKSUMS.md5.asc"
assert 'corrected compatibility asc still forbids signature impersonation' bash -c '! grep -Fq "BEGIN PGP SIGNATURE" "$1/CHECKSUMS.md5.asc"' _ "$source_new"
assert 'record consumes step-247 observation' record_is prebuild_v3_observation_state consumed-and-frozen
assert 'record freezes fresh boot ID' record_is fresh_boot_id fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9
assert 'record preserves historical builder hash' record_is historical_v3_builder_sha256 56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582
assert 'record freezes corrected builder hash' record_is corrected_v3_builder_r1_sha256 80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30
assert 'record keeps corrected builder transport closed' record_is local_source_v3_builder_transport_authorized no
assert 'record keeps v3 build closed' record_is local_source_v3_build_authorized no
assert 'record routes to corrected builder freeze authorization review' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review
assert 'reference document records stale v2 status label' grep -Fq 'local_source_v2_build_status' "$doc"
assert 'reference document records corrected v3 status label' grep -Fq 'local_source_v3_build_status' "$doc"
assert 'reference document preserves old builder as never executed' grep -Fq 'never been executed on the target' "$doc"
assert 'step-248 files have no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4" "$5"' _ "$helper" "$doc" "$policy" "$record" "$new_builder"
assert 'CHANGELOG records step 248' grep -Fq '## Phase 1 step 248 ' "$repo_root/CHANGELOG.md"
assert 'step-248 helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$helper"
assert 'corrected builder contains no package or network client command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|curl|wget|git)[[:space:]]" "$1"' _ "$new_builder"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
