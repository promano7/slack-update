#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.md"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv"
step198_policy="$acc/phase-1-kernel-package-edge-local-source-construction-review-policy.json"
step198_record="$acc/phase-1-kernel-package-edge-local-source-construction-review.tsv"
step197_policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json"
step197_record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check() { local msg=$1; shift; if "$@"; then pass "$msg"; else fail "$msg"; fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
contains() { grep -Fq -- "$2" "$1"; }

check 'step-199 strong-safe-pause helper is a regular non-symlink file' regular "$helper"
check 'step-199 reference document is a regular non-symlink file' regular "$doc"
check 'step-199 strong-safe-pause policy is a regular non-symlink file' regular "$policy"
check 'step-199 strong-safe-pause record is a regular non-symlink file' regular "$record"
check 'accepted step-198 policy is a regular non-symlink file' regular "$step198_policy"
check 'accepted step-198 record is a regular non-symlink file' regular "$step198_record"
check 'accepted step-197 policy is a regular non-symlink file' regular "$step197_policy"
check 'accepted step-197 record is a regular non-symlink file' regular "$step197_record"

check 'step-199 helper has the exact reviewed SHA-256' hash_is "$helper" '5222077154b05776d2de824a9fdcfc0694266f13f56a14553d70ce771d37563f'
check 'step-199 reference document has the exact reviewed SHA-256' hash_is "$doc" 'f3d31c4f057e33290ef3b6548b3a04bf4cb7406330ebebe013148a81a917d7b6'
check 'step-199 policy has the exact reviewed SHA-256' hash_is "$policy" '6577709a7fc3b822a9e7e6bcf4f94c973d0a12d829b3a65efc7da4a5038d6a43'
check 'step-199 record has the exact reviewed SHA-256' hash_is "$record" '4bd523d8f5958f6227ef6ee48f208e8253a06a2c7f9d9a1b6664286286fda8a1'
check 'accepted step-198 policy has the frozen SHA-256' hash_is "$step198_policy" 'd9625849f7254480495a6e749b1a07643f2504f169f54a40507fb26e84eddd70'
check 'accepted step-198 record has the frozen SHA-256' hash_is "$step198_record" '57fc3fa28b148850544a8610ebc9572bfed528bf7e5b3b3c7d1b244822aa7ed6'
check 'accepted step-197 policy has the frozen SHA-256' hash_is "$step197_policy" '79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12'
check 'accepted step-197 record has the frozen SHA-256' hash_is "$step197_record" 'abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449'

check 'step-199 helper is shell-syntax valid' bash -n "$helper"
check 'step-199 helper exposes a non-mutating help boundary' bash -c '"$1" --help >/dev/null' _ "$helper"
check 'step-199 helper rejects unknown options' bash -c '! "$1" --definitely-unknown >/dev/null 2>&1' _ "$helper"
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-199 policy is valid JSON'; else fail 'step-199 policy is valid JSON'; fi

python3 - "$policy" "$record" <<'PY' && pass 'step-199 strong safe pause review completed successfully' || fail 'step-199 strong safe pause review completed successfully'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['scenario']=='phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause'
assert p['pause_safe'] is True
assert p['safe_pause']['strong_safe_pause'] is True
assert p['safe_pause']['no_open_operational_authorization'] is True
assert p['selected_family']['family']=='kernel-package-edge'
assert p['selected_family']['family_closed'] is False
assert p['continuation']['next_stage']=='phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review'
assert r['pause_safe']=='yes'
assert r['strong_safe_pause']=='yes'
PY

check 'kernel-package-edge remains the selected family' contains "$record" $'selected_family\tkernel-package-edge'
check 'kernel-package-edge family remains open' contains "$record" $'family_closed\tno'
check 'artifact byte binding remains frozen' contains "$record" $'artifact_byte_binding_state\taccepted-byte-binding-frozen'
check 'evidence root remains preserved' contains "$record" $'evidence_root\t/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts'
check 'evidence root must remain unchanged' contains "$record" $'evidence_root_must_remain_unchanged\tyes'
check 'frozen target package SHA-256 is preserved' contains "$record" $'target_package_sha256\tc7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
check 'frozen predecessor package SHA-256 is preserved' contains "$record" $'predecessor_package_sha256\t3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
check 'artifact binding survives later publication' contains "$record" $'artifact_binding_survives_later_publication\tyes'
check 'builder remains deliberately unimplemented' bash -c '[[ ! -e $1 ]]' _ "$builder"
check 'local source remains unbuilt' contains "$record" $'local_source_tree_built\tno'
check 'local-source tree manifest remains unbound' contains "$record" $'local_source_tree_manifest_bound\tno'
check 'prior runtime target binding is not reusable after pause' contains "$record" $'prior_target_binding_reusable_after_pause\tno'
check 'fresh target revalidation is required before machine action' contains "$record" $'fresh_target_revalidation_required_before_any_machine_action\tyes'
check 'fresh candidate set is required before runtime' contains "$record" $'fresh_candidate_set_required_before_runtime\tyes'
check 'source changes are not authorized' contains "$record" $'source_change_authorized\tno'
check 'documentation changes are not authorized' contains "$record" $'documentation_change_authorized\tno'
check 'controller artifact acquisition is closed' contains "$record" $'controller_artifact_acquisition_authorized\tno'
check 'controller network is closed' contains "$record" $'controller_network_access_authorized\tno'
check 'repository refresh is closed' contains "$record" $'repository_refresh_authorized\tno'
check 'network refresh is closed' contains "$record" $'network_refresh_authorized\tno'
check 'target-machine action is closed' contains "$record" $'target_vm_action_authorized\tno'
check 'target-machine network is closed' contains "$record" $'target_vm_network_access_authorized\tno'
check 'target artifact copy is closed' contains "$record" $'target_artifact_copy_authorized\tno'
check 'local-source build is closed' contains "$record" $'local_source_build_authorized\tno'
check 'runtime executor implementation is closed' contains "$record" $'runtime_executor_implementation_authorized\tno'
check 'runtime scenario execution is closed' contains "$record" $'runtime_scenario_execution_authorized\tno'
check 'package action is closed' contains "$record" $'package_action_authorized\tno'
check 'boot action is closed' contains "$record" $'boot_action_authorized\tno'
check 'reboot is closed' contains "$record" $'reboot_authorized\tno'
check 'Phase 2 remains closed' contains "$record" $'phase_2_start_authorized\tno'
check 'step 199 requires no machine action' contains "$record" $'machine_action_required\tno'
check 'step 199 requires no controller action' contains "$record" $'controller_action_required\tno'
check 'no operational authorization remains open' contains "$record" $'no_open_operational_authorization\tyes'
check 'later Slackware-current publication does not invalidate checkpoint' contains "$record" $'later_slackware_current_publication_invalidates_checkpoint\tno'
check 'future work requires a fresh boundary' contains "$record" $'future_work_requires_fresh_boundary\tyes'
check 'acceptance matrix remains incomplete' contains "$record" $'acceptance_matrix_complete\tno'
check 'next stage is fresh local-source construction resume planning' contains "$record" $'next_stage\tphase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review'

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
if bash "$helper" --output-dir "$TMP" >/dev/null && cmp -s "$policy" "$TMP/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause-policy.json" && cmp -s "$record" "$TMP/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv"; then
    pass 'step-199 helper reproduces policy and record deterministically'
else
    fail 'step-199 helper reproduces policy and record deterministically'
fi

check 'reference document records strong safe pause' contains "$doc" 'A successful step 199 is a strong safe pause.'
check 'reference document records preserved artifact binding' contains "$doc" 'byte binding remains accepted and reusable across later Slackware-current publications'
check 'reference document records runtime binding expiry' contains "$doc" 'not reusable after this pause'
check 'reference document records fresh target revalidation' contains "$doc" 'fresh planning boundary and revalidate the Slackware-current VM'
check 'reference document records next continuation stage' contains "$doc" 'phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review'
check 'CHANGELOG records step 199' contains "$changelog" '## Phase 1 step 199 kernel-package-edge local-source construction review and strong safe pause'

if ! grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(curl|wget|ftp|rsync|ssh|scp|slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    pass 'step-199 helper contains no executable network, package, boot, reboot, or shutdown command'
else
    fail 'step-199 helper contains no executable network, package, boot, reboot, or shutdown command'
fi

printf 'Result: PASS (%d passes, %d failures)\n' "$passes" "$failures"
(( failures == 0 ))
