#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"

passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
record_has() { awk -F '\t' -v k="$1" '$1==k {found=1} END {exit !found}' "$record"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for item in "$builder" "$helper" "$doc" "$policy" "$record"; do assert "step-226 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-225 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-225 helper hash is frozen' hash_is "$prev_helper" 'e7c3c682b0078f4db070328cecf26e2df89f40caa12e8bea68e2f5aacedcf2e4'
assert 'accepted step-225 document hash is frozen' hash_is "$prev_doc" 'f2e2f343b83b03a963c10fe094a39bdad2623d447807cc88c2021effebb42808'
assert 'accepted step-225 harness hash is frozen' hash_is "$prev_harness" '6ac7be3dc98936c43585e6e0ffec158597035abbd88d166052f5d25a3cf76f59'
assert 'accepted step-225 policy hash is frozen' hash_is "$prev_policy" '6f439cc4803cefb8d1c8d62a3e9ccc07a4dae9523c4e16592d4527e01696ab64'
assert 'accepted step-225 record hash is frozen' hash_is "$prev_record" 'd43544d6dbe41e5c17372921b93fd200afddaea7dcbf147c89814c625c5e5811'
assert 'reviewed v2 builder SHA-256 is frozen' hash_is "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'step-226 helper hash matches frozen policy' hash_is "$helper" 'fc8ffed9c7fa9eb69a59b03b4d47bad3dfda4182cea20409f3dec0517f7f9d12'
assert 'step-226 frozen policy hash matches overlay' hash_is "$policy" '950fa9b91c59fc0562011ff716ca0108bb7ff78d5140cf96c4c9547806cd5826'
assert 'step-226 frozen record hash matches overlay' hash_is "$record" '4da734369f4e4311f027d613732d0c8eaf2d873d74ec804272873c5ba265b412'
assert 'v2 builder passes bash syntax validation' bash -n "$builder"
assert 'step-226 helper passes bash syntax validation' bash -n "$helper"
assert 'v2 builder exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$builder"
assert 'v2 builder rejects missing acknowledgement' bash -c '! "$1" >/dev/null 2>&1' _ "$builder"
assert 'v2 builder rejects unknown acknowledgement' bash -c '! "$1" --unknown >/dev/null 2>&1' _ "$builder"
assert 'step-226 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-226 helper rejects unknown option' bash -c '! "$1" --bad-option >/dev/null 2>&1' _ "$helper"

repro=$(mktemp -d); testroot=$(mktemp -d); trap 'rm -rf -- "$repro" "$testroot"' EXIT
assert 'step-226 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/${base}.tsv"

assert 'step-226 policy semantic assertions pass' python3 - "$prev_policy" "$policy" <<'PYSEM'
import json,sys
p225=json.load(open(sys.argv[1],encoding='utf-8')); p=json.load(open(sys.argv[2],encoding='utf-8'))
assert p['schema']==1 and p['step']==226 and p['review_status']=='PASS' and p['review_only'] is True
assert p['accepted_step_225']['policy_sha256']=='6f439cc4803cefb8d1c8d62a3e9ccc07a4dae9523c4e16592d4527e01696ab64'
assert p['frozen_runtime_identity']==p225['frozen_runtime_identity']
assert p['preservation_contract']==p225['preservation_contract']
assert p['local_source_v2_design']==p225['local_source_v2_design']
b=p['builder_implementation']; d=p['local_source_v2_design']; a=p['authorization']
assert b['state']=='implemented-reviewed-awaiting-freeze'
assert b['builder_path']=='tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh' and b['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert b['execution_acknowledgement']=='--build-local-source-v2'
assert b['repository_test_seam']=='SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1'
assert b['production_paths_overridable'] is False and b['local_source_v2_root']==d['root']
assert b['priority_trees']==['patches','slackware64','extra','pasture','testing']
assert b['compatibility_asc_required'] is True and b['compatibility_asc_is_not_authenticity_evidence'] is True
assert b['failure_contract']['must_preserve_local_source_v1'] and b['failure_contract']['must_preserve_failed_runtime_evidence']
assert b['failure_contract']['must_not_access_network'] and b['failure_contract']['must_not_modify_package_database']
assert a['repository_only_local_source_v2_builder_implementation_freeze_authorized'] is True
for k in ('local_source_v2_builder_execution_authorized','local_source_v2_build_authorized','target_observation_authorized','runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized','evidence_cleanup_authorized','phase_2_start_authorized'):
    assert a[k] is False,k
assert p['future_refresh_acceptance_contract']['workdir_strategy']=='transaction-owned-new-empty-workdir'
assert p['future_refresh_acceptance_contract']['candidate_guard_scope']=='target-specific-not-global-pkglist-row-count'
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'
PYSEM

# Exercise pure builder functions through the repository-only library seam.
fixture="$testroot/fixture"
mkdir -p "$fixture/pkgroot/install" "$fixture/pkgroot/usr/include/linux"
cat > "$fixture/pkgroot/install/slack-desc" <<'SLACKDESC'
# HOW TO EDIT THIS FILE:
kernel-headers: kernel-headers (Linux kernel include files)
kernel-headers:
kernel-headers: Synthetic v2 repository harness package.
SLACKDESC
printf '#define SYNTHETIC_V2_KERNEL_HEADER 1\n' > "$fixture/pkgroot/usr/include/linux/synthetic-v2.h"
fixture_pkg="$fixture/kernel-headers-6.18.45-x86-1.txz"
( cd "$fixture/pkgroot" && tar -cJf "$fixture_pkg" . )
fixture_sha=$(sha "$fixture_pkg")
SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1 source "$builder"

assert 'library seam accepts valid regular input and SHA' validate_input_file "$fixture_pkg" 'kernel-headers-6.18.45-x86-1.txz' "$fixture_sha"
assert 'library seam rejects wrong input SHA' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1 source "$1"; ! validate_input_file "$2" kernel-headers-6.18.45-x86-1.txz 0000000000000000000000000000000000000000000000000000000000000000 >/dev/null 2>&1' _ "$builder" "$fixture_pkg"
ln -s "$fixture_pkg" "$fixture/kernel-headers-symlink.txz"
assert 'library seam rejects symlink input' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1 source "$1"; ! validate_input_file "$2" kernel-headers-symlink.txz "$3" >/dev/null 2>&1' _ "$builder" "$fixture/kernel-headers-symlink.txz" "$fixture_sha"

source1="$testroot/source1"; scratch1="$testroot/scratch1"
source2="$testroot/source2"; scratch2="$testroot/scratch2"
assert 'library seam renders v2 source from valid fixture' render_source_tree "$fixture_pkg" "$source1" "$scratch1" "$fixture_sha"
assert 'library seam validates exact v2 source contract' validate_source_tree "$source1" "$fixture_sha"
assert 'second render succeeds for determinism comparison' render_source_tree "$fixture_pkg" "$source2" "$scratch2" "$fixture_sha"
assert 'second render validates exact v2 source contract' validate_source_tree "$source2" "$fixture_sha"

manifest1="$testroot/source1.tree.sha256"; side1="$testroot/source1.tree.sha256.sha256"
manifest2="$testroot/source2.tree.sha256"; side2="$testroot/source2.tree.sha256.sha256"
write_tree_manifest "$source1" "$manifest1" "$side1"; write_tree_manifest "$source2" "$manifest2" "$side2"
assert 'library seam writes and verifies v2 external tree manifest' verify_tree_manifest "$source1" "$manifest1" "$side1"
assert 'deterministic renders have identical tree manifests' cmp -s "$manifest1" "$manifest2"
assert 'rendered v2 exposes exactly one package archive' bash -c '[[ $(find "$1" -type f -name "*.txz" | wc -l) -eq 1 ]]' _ "$source1"
assert 'rendered v2 excludes predecessor archive' bash -c '[[ ! -e "$1/slackware64/d/kernel-headers-6.18.44-x86-1.txz" ]]' _ "$source1"
assert 'top-level PACKAGES.TXT has exactly one target stanza' bash -c '[[ $(grep -c "^PACKAGE NAME:  " "$1/PACKAGES.TXT") -eq 1 ]]' _ "$source1"
assert 'slackware64 PACKAGES.TXT has exactly one target stanza' bash -c '[[ $(grep -c "^PACKAGE NAME:  " "$1/slackware64/PACKAGES.TXT") -eq 1 ]]' _ "$source1"
for tree in patches extra pasture testing; do assert "$tree PACKAGES.TXT has zero package stanzas" bash -c '[[ $(grep -c "^PACKAGE NAME:  " "$1/$2/PACKAGES.TXT" || true) -eq 0 ]]' _ "$source1" "$tree"; done
assert 'top-level and slackware64 target indexes are identical' cmp -s "$source1/PACKAGES.TXT" "$source1/slackware64/PACKAGES.TXT"
assert 'PACKAGES.TXT description comes from fixture slack-desc' grep -Fq 'Synthetic v2 repository harness package.' "$source1/PACKAGES.TXT"
assert 'compatibility asc is present' regular "$source1/CHECKSUMS.md5.asc"
assert 'compatibility asc makes no authenticity claim' grep -Fq 'No cryptographic authenticity claim is made by this file.' "$source1/CHECKSUMS.md5.asc"
assert 'compatibility asc does not impersonate PGP signature' bash -c '! grep -Fq "BEGIN PGP SIGNATURE" "$1/CHECKSUMS.md5.asc"' _ "$source1"
assert 'FILELIST enumerates target package' grep -Fxq './slackware64/d/kernel-headers-6.18.45-x86-1.txz' "$source1/FILELIST.TXT"
assert 'FILELIST enumerates compatibility asc' grep -Fxq './CHECKSUMS.md5.asc' "$source1/FILELIST.TXT"
assert 'FILELIST row count matches regular-file count' bash -c '[[ $(wc -l < "$1/FILELIST.TXT") -eq $(find "$1" -type f | wc -l) ]]' _ "$source1"
assert 'CHECKSUMS.md5 excludes itself' bash -c '! grep -Fq "MD5 (./CHECKSUMS.md5)" "$1/CHECKSUMS.md5"' _ "$source1"
assert 'CHECKSUMS.md5 excludes compatibility asc' bash -c '! grep -Fq "MD5 (./CHECKSUMS.md5.asc)" "$1/CHECKSUMS.md5"' _ "$source1"
assert 'CHECKSUMS.md5 binds target package' bash -c 'm=$(md5sum "$1/slackware64/d/kernel-headers-6.18.45-x86-1.txz"|awk "{print \$1}"); grep -Fxq "MD5 (./slackware64/d/kernel-headers-6.18.45-x86-1.txz) = $m" "$1/CHECKSUMS.md5"' _ "$source1"

unused_source="$testroot/not-yet-created"; unused_manifest="$testroot/not-yet-created.tree.sha256"; unused_side="$testroot/not-yet-created.tree.sha256.sha256"
assert 'output preflight accepts absent v2 destinations' preflight_output_paths "$unused_source" "$unused_manifest" "$unused_side"
mkdir "$unused_source"; printf 'sentinel\n' > "$unused_source/sentinel"
assert 'output preflight rejects pre-existing final v2 source' bash -c 'SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1 source "$1"; ! preflight_output_paths "$2" "$3" "$4" >/dev/null 2>&1' _ "$builder" "$unused_source" "$unused_manifest" "$unused_side"
assert 'pre-existing final v2 source remains untouched on rejection' bash -c '[[ $(cat "$1/sentinel") == sentinel ]]' _ "$unused_source"

for key in step review_status builder_implementation_state builder_path builder_sha256 execution_acknowledgement repository_test_seam production_paths_overridable local_source_v2_root priority_trees CHECKSUMS_md5_asc_required refresh_workdir_strategy candidate_guard_scope repository_only_local_source_v2_builder_implementation_freeze_authorized local_source_v2_builder_execution_authorized local_source_v2_build_authorized target_observation_authorized runtime_rerun_authorized package_action_authorized machine_action_required pause_safe next_stage; do assert "record contains $key" record_has "$key"; done
assert 'record freezes step 226' record_is step 226
assert 'record marks builder implementation reviewed awaiting freeze' record_is builder_implementation_state implemented-reviewed-awaiting-freeze
assert 'record freezes builder SHA' record_is builder_sha256 '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'record freezes repository-only test seam' record_is repository_test_seam 'SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1'
assert 'record forbids production path override' record_is production_paths_overridable no
assert 'record preserves all priority trees' record_is priority_trees patches,slackware64,extra,pasture,testing
assert 'record preserves compatibility asc requirement' record_is CHECKSUMS_md5_asc_required yes
assert 'record authorizes only implementation freeze next' record_is repository_only_local_source_v2_builder_implementation_freeze_authorized yes
assert 'record keeps builder execution closed' record_is local_source_v2_builder_execution_authorized no
assert 'record keeps v2 build closed' record_is local_source_v2_build_authorized no
assert 'record keeps target observation closed' record_is target_observation_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record requires no machine action' record_is machine_action_required no
assert 'record routes to implementation freeze' record_is next_stage phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze
assert 'document records reviewed builder SHA' grep -Fq '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' "$doc"
assert 'document records repository-only implementation boundary' grep -Fq 'without executing its production path' "$doc"
assert 'CHANGELOG records step 226' grep -Fq '## Phase 1 step 226 kernel-package-edge runtime-transaction remediation local-source-v2 builder implementation review' "$repo_root/CHANGELOG.md"
assert 'builder contains no package/boot/reboot mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$builder"
assert 'builder contains no network client command' bash -c '! grep -Eq "^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh)[[:space:]]" "$1"' _ "$builder"
assert 'step-226 helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
