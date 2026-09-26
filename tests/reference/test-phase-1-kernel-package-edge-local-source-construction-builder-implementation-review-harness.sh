#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review.tsv"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-design-freeze.sh"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review.md"
pass=0; failc=0
ok(){ printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad(){ printf 'FAIL: %s\n' "$1"; failc=$((failc+1)); }
regular(){ [[ -f $1 && ! -L $1 ]]; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
check_file(){ local label=$1 file=$2; regular "$file" && ok "$label" || bad "$label"; }
check_line(){ local label=$1 needle=$2; grep -Fqx "$needle" "$record" && ok "$label" || bad "$label"; }

check_file 'step-205 policy is a regular file' "$policy"
check_file 'step-205 record is a regular file' "$record"
check_file 'step-205 helper is a regular file' "$helper"
check_file 'step-205 builder is a regular file' "$builder"
check_file 'step-205 document is a regular file' "$doc"
check_file 'accepted step-204 policy is a regular file' "$prior_policy"
check_file 'accepted step-204 record is a regular file' "$prior_record"
check_file 'accepted step-204 helper is a regular file' "$prior_helper"
[[ $(sha "$prior_policy") == '7f1aacd0f039b3bf7e845de8e9782ea10a1ce735eadd0e24ee59df4f2c551cfd' ]] && ok 'accepted step-204 policy hash is frozen' || bad 'accepted step-204 policy hash is frozen'
[[ $(sha "$prior_record") == 'c4865e6a82714a9b2bfca157e9a37f0aff358f0f023d6d7f4d9d85eb987e4ea8' ]] && ok 'accepted step-204 record hash is frozen' || bad 'accepted step-204 record hash is frozen'
[[ $(sha "$prior_helper") == '7bd30fbdd67529bb0aedd64188f1d5edaaf2c53587f84eb564901024102494ae' ]] && ok 'accepted step-204 helper hash is frozen' || bad 'accepted step-204 helper hash is frozen'
[[ $(sha "$builder") == '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' ]] && ok 'builder implementation SHA-256 is frozen' || bad 'builder implementation SHA-256 is frozen'
bash -n "$builder" && ok 'builder passes shell syntax validation' || bad 'builder passes shell syntax validation'
bash -n "$helper" && ok 'step-205 helper passes shell syntax validation' || bad 'step-205 helper passes shell syntax validation'

if "$builder" >/dev/null 2>&1; then bad 'builder rejects missing acknowledgement'; else ok 'builder rejects missing acknowledgement'; fi
if "$builder" --unknown >/dev/null 2>&1; then bad 'builder rejects unknown acknowledgement'; else ok 'builder rejects unknown acknowledgement'; fi

repro=$(mktemp -d)
testroot=$(mktemp -d)
trap 'rm -rf "$repro" "$testroot"' EXIT
"$helper" --output-dir "$repro" >/dev/null
cmp -s "$policy" "$repro/${policy##*/}" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$repro/${record##*/}" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'

python3 - "$policy" <<'PY205' && ok 'policy records reviewed implementation with no execution authority' || bad 'policy records reviewed implementation with no execution authority'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8')); b=p['builder_implementation']; a=p['authorization']
assert p['builder_sha256']=='59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' and b['builder_sha256']=='59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
assert b['state']=='frozen' and b['builder_implementation_state']=='implemented-reviewed-awaiting-freeze'
assert b['accepted_builder_input_artifact_count']==1 and b['accepted_builder_input_artifact']=='kernel-headers-6.18.45-x86-1.txz'
assert b['predecessor_is_builder_input'] is False and b['exact_package_candidate_count']==1
assert b['repository_test_seam']['production_main_bypassed'] is True and b['repository_test_seam']['production_paths_overridable'] is False
assert a['builder_implementation_freeze_authorized_for_next_stage'] is True
for k,v in a.items():
    if k!='builder_implementation_freeze_authorized_for_next_stage': assert v is False
assert p['machine_action_required'] is False and p['review_only'] is True and p['pause_safe'] is False
PY205

# Exercise pure functions through the repository-only library seam.
fixture="$testroot/fixture"
mkdir -p "$fixture/pkgroot/install" "$fixture/pkgroot/usr/include/linux"
cat > "$fixture/pkgroot/install/slack-desc" <<'SLACKDESC'
# HOW TO EDIT THIS FILE:
kernel-headers: kernel-headers (Linux kernel include files)
kernel-headers:
kernel-headers: Synthetic repository harness package.
SLACKDESC
printf '#define SYNTHETIC_KERNEL_HEADER 1\n' > "$fixture/pkgroot/usr/include/linux/synthetic.h"
fixture_pkg="$fixture/kernel-headers-6.18.45-x86-1.txz"
( cd "$fixture/pkgroot" && tar -cJf "$fixture_pkg" . )
fixture_sha=$(sha "$fixture_pkg")
SLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY=1 source "$builder"

validate_input_file "$fixture_pkg" 'kernel-headers-6.18.45-x86-1.txz' "$fixture_sha" && ok 'library seam accepts valid regular input and SHA' || bad 'library seam accepts valid regular input and SHA'
if validate_input_file "$fixture_pkg" 'kernel-headers-6.18.45-x86-1.txz' '0000000000000000000000000000000000000000000000000000000000000000' >/dev/null 2>&1; then bad 'library seam rejects wrong input SHA'; else ok 'library seam rejects wrong input SHA'; fi
ln -s "$fixture_pkg" "$fixture/kernel-headers-symlink.txz"
if validate_input_file "$fixture/kernel-headers-symlink.txz" 'kernel-headers-symlink.txz' "$fixture_sha" >/dev/null 2>&1; then bad 'library seam rejects symlink input'; else ok 'library seam rejects symlink input'; fi

source_tree="$testroot/source"
extract_tree="$testroot/extract"
render_source_tree "$fixture_pkg" "$source_tree" "$extract_tree" "$fixture_sha" && ok 'library seam renders deterministic source from valid fixture' || bad 'library seam renders deterministic source from valid fixture'
validate_source_tree "$source_tree" "$fixture_sha" && ok 'library seam validates exact single-candidate source' || bad 'library seam validates exact single-candidate source'
[[ $(find "$source_tree" -type f -name '*.txz' | wc -l) -eq 1 ]] && ok 'rendered fixture exposes exactly one package archive' || bad 'rendered fixture exposes exactly one package archive'
[[ $(grep -c '^PACKAGE NAME:  ' "$source_tree/PACKAGES.TXT") -eq 1 ]] && ok 'rendered PACKAGES.TXT has exactly one stanza' || bad 'rendered PACKAGES.TXT has exactly one stanza'
grep -Fq 'Synthetic repository harness package.' "$source_tree/PACKAGES.TXT" && ok 'PACKAGES.TXT description comes from install/slack-desc' || bad 'PACKAGES.TXT description comes from install/slack-desc'
grep -Fxq './slackware64/d/kernel-headers-6.18.45-x86-1.txz' "$source_tree/FILELIST.TXT" && ok 'FILELIST.TXT enumerates frozen relative package path' || bad 'FILELIST.TXT enumerates frozen relative package path'

manifest="$testroot/local-source.tree.sha256"
manifest_sha="$testroot/local-source.tree.sha256.sha256"
write_tree_manifest "$source_tree" "$manifest" "$manifest_sha"
verify_tree_manifest "$source_tree" "$manifest" "$manifest_sha" && ok 'library seam writes and verifies sorted external tree manifest' || bad 'library seam writes and verifies sorted external tree manifest'

unused_source="$testroot/not-yet-created"
unused_manifest="$testroot/not-yet-created.sha256"
unused_manifest_sha="$testroot/not-yet-created.sha256.sha256"
preflight_output_paths "$unused_source" "$unused_manifest" "$unused_manifest_sha" && ok 'output preflight accepts absent destinations' || bad 'output preflight accepts absent destinations'
mkdir "$unused_source"; printf 'sentinel\n' > "$unused_source/sentinel"
if preflight_output_paths "$unused_source" "$unused_manifest" "$unused_manifest_sha" >/dev/null 2>&1; then bad 'output preflight rejects pre-existing final source'; else ok 'output preflight rejects pre-existing final source'; fi
[[ $(cat "$unused_source/sentinel") == sentinel ]] && ok 'pre-existing final source remains untouched on rejection' || bad 'pre-existing final source remains untouched on rejection'

check_line 'record freezes implementation SHA' $'builder_sha256	59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_line 'record marks implementation reviewed awaiting freeze' $'builder_implementation_state	implemented-reviewed-awaiting-freeze'
check_line 'record keeps predecessor outside builder input' $'predecessor_is_builder_input	no'
check_line 'record keeps exactly one candidate' $'exact_package_candidate_count	1'
check_line 'record freezes repository-only test seam' $'repository_test_seam	SLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY=1'
check_line 'record forbids production path override' $'production_paths_overridable	no'
check_line 'record authorizes only implementation freeze' $'builder_implementation_freeze_authorized_for_next_stage	yes'
check_line 'record does not authorize builder execution' $'builder_execution_authorized	no'
check_line 'record does not authorize target artifact copy' $'target_artifact_copy_authorized	no'
check_line 'record does not authorize local-source build' $'local_source_build_authorized	no'
check_line 'record requires no machine action' $'machine_action_required	no'
check_line 'record routes to implementation freeze' $'next_stage	phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze'

if grep -Eq '(^|[;&|()[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|eliloconfig|mkinitrd|reboot|shutdown|poweroff)([;&|()[:space:]]|$)' "$builder"; then bad 'builder contains no package/boot/reboot mutation command'; else ok 'builder contains no package/boot/reboot mutation command'; fi
if grep -Eq '(^|[^[:alnum:]_])(curl|wget|ftp|rsync|scp|ssh)([^[:alnum:]_]|$)' "$builder"; then bad 'builder contains no network client command'; else ok 'builder contains no network client command'; fi
if grep -Fq 'Phase 1 step 205 kernel-package-edge local-source construction builder implementation review' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 205'; else bad 'CHANGELOG records step 205'; fi
if grep -Fq 'implemented-reviewed-awaiting-freeze' "$doc" && grep -Fq 'does **not** authorize builder execution' "$doc"; then ok 'reference document records review-only implementation boundary'; else bad 'reference document records review-only implementation boundary'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failc -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$failc"
[[ $failc -eq 0 ]]
