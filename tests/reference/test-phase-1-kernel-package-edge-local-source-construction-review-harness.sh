#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-review.md"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-review.tsv"
freeze_policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json"
freeze_record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"
design_policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json"
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

check 'step-198 construction-review helper is a regular non-symlink file' regular "$helper"
check 'step-198 reference document is a regular non-symlink file' regular "$doc"
check 'step-198 construction-review policy is a regular non-symlink file' regular "$policy"
check 'step-198 construction-review record is a regular non-symlink file' regular "$record"
check 'accepted step-197 byte-binding policy is a regular non-symlink file' regular "$freeze_policy"
check 'accepted step-197 byte-binding record is a regular non-symlink file' regular "$freeze_record"
check 'accepted step-195 local-source design policy is a regular non-symlink file' regular "$design_policy"

check 'step-198 helper has the exact reviewed SHA-256' hash_is "$helper" 'dbe4a95c37c0c01d3c272a9a39ce2197e90e7256bdfae580885b172c98458cb4'
check 'step-198 reference document has the exact reviewed SHA-256' hash_is "$doc" 'a202d530f155d06f8b763b054b9a4c9eb7b1bc9b4f038d5790e13ca0b55a35a0'
check 'step-198 policy has the exact reviewed SHA-256' hash_is "$policy" 'd9625849f7254480495a6e749b1a07643f2504f169f54a40507fb26e84eddd70'
check 'step-198 record has the exact reviewed SHA-256' hash_is "$record" '57fc3fa28b148850544a8610ebc9572bfed528bf7e5b3b3c7d1b244822aa7ed6'
check 'accepted step-197 policy has the frozen SHA-256' hash_is "$freeze_policy" '79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12'
check 'accepted step-197 record has the frozen SHA-256' hash_is "$freeze_record" 'abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449'
check 'accepted step-195 design policy has the frozen SHA-256' hash_is "$design_policy" 'ce33fc2ead2335c50cd9e47146f8d1d818a49e1cb3169b06fe9a983af60f6015'

check 'step-198 helper is shell-syntax valid' bash -n "$helper"
check 'step-198 helper exposes a non-mutating help boundary' bash -c '"$1" --help >/dev/null' _ "$helper"
check 'step-198 helper rejects unknown options' bash -c '! "$1" --definitely-unknown >/dev/null 2>&1' _ "$helper"
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-198 policy is valid JSON'; else fail 'step-198 policy is valid JSON'; fi

python3 - "$policy" "$record" <<'PY' && pass 'step-198 local-source construction review completed successfully' || fail 'step-198 local-source construction review completed successfully'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['scenario']=='phase-1-kernel-package-edge-local-source-construction-review'
assert p['review_only'] is True
assert p['accepted_byte_binding']['step']==197
assert p['accepted_local_source_design']['step']==195
assert p['construction_review']['state']=='reviewed-awaiting-fresh-construction-boundary'
assert p['next_stage']=='phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause'
assert r['construction_review_state']=='reviewed-awaiting-fresh-construction-boundary'
PY

check 'accepted evidence root is preserved' python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["construction_review"]; assert x["evidence_root"]=="/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts" and x["evidence_root_must_remain_unchanged"] is True' "$policy"
check 'only the bound 6.18.45 target artifact may be exposed' python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["construction_review"]; assert x["target_artifact"]=="kernel-headers-6.18.45-x86-1.txz" and x["target_package_sha256"]=="c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c" and x["predecessor_artifact_must_not_be_exposed_by_local_source"] is True' "$policy"
check 'local-source runtime root is preserved' contains "$record" $'runtime_root\t/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
check 'local-source file mirror URI is preserved' contains "$record" $'runtime_mirror_uri\tfile:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
check 'target relative path is preserved' contains "$record" $'target_relative_path\tslackware64/d/kernel-headers-6.18.45-x86-1.txz'
check 'required metadata set is preserved' contains "$record" $'required_metadata_files\tChangeLog.txt FILELIST.TXT PACKAGES.TXT CHECKSUMS.md5'
check 'planned builder path is preserved' contains "$record" $'planned_builder_path\ttools/reference/phase-1-kernel-package-edge-local-source-build.sh'
check 'builder remains deliberately unimplemented' bash -c '[[ ! -e $1 ]]' _ "$builder"
check 'builder execution remains unauthorized' contains "$record" $'local_source_build_authorized\tno'
check 'target copy remains unauthorized' contains "$record" $'target_artifact_copy_authorized\tno'
check 'local source has not been built' contains "$record" $'local_source_tree_built\tno'
check 'local source tree manifest is not yet bound' contains "$record" $'local_source_tree_manifest_bound\tno'
check 'future local source must be read-only' contains "$record" $'tree_must_be_read_only_before_runtime\tyes'
check 'future source tree must verify before and after apply' contains "$record" $'tree_must_verify_unchanged_before_and_after_reference_apply\tyes'
check 'runtime network remains forbidden' contains "$record" $'runtime_network_access_forbidden\tyes'
check 'fresh target revalidation is required before machine action' contains "$record" $'fresh_target_revalidation_required_before_any_machine_action\tyes'
check 'fresh explicit authorization is required before copy or build' contains "$record" $'fresh_explicit_authorization_required_before_target_copy_or_build\tyes'
check 'controller network remains closed' contains "$record" $'controller_network_access_authorized\tno'
check 'target-machine action remains closed' contains "$record" $'target_vm_action_authorized\tno'
check 'runtime scenario execution remains closed' contains "$record" $'runtime_scenario_execution_authorized\tno'
check 'package action remains closed' contains "$record" $'package_action_authorized\tno'
check 'boot action remains closed' contains "$record" $'boot_action_authorized\tno'
check 'reboot remains closed' contains "$record" $'reboot_authorized\tno'
check 'Phase 2 remains closed' contains "$record" $'phase_2_start_authorized\tno'
check 'step 198 requires no machine action' contains "$record" $'machine_action_required\tno'
check 'step 198 requires no controller action' contains "$record" $'controller_action_required\tno'
check 'later Slackware-current publication does not invalidate the review' contains "$record" $'later_slackware_current_publication_invalidates_review\tno'
check 'strong safe pause is ready for the next review' contains "$record" $'strong_safe_pause_ready_for_review\tyes'
check 'step 198 itself is not yet the pause' contains "$record" $'pause_safe\tno'
check 'next stage is the strong-safe-pause review' contains "$record" $'next_stage\tphase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause'

check 'header-only candidate guard is preserved' python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["construction_review"]; assert x["candidate_guard_preserved"]=="after-local-source-refresh-exactly-one-upgrade-candidate-and-it-is-the-selected-kernel-header-package"' "$policy"
check 'reference apply transition is preserved' python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["construction_review"]; assert x["reference_transition_preserved"]=="tools/reference/slack-update-reference.sh --apply"' "$policy"
check 'boot mutation remains forbidden by the review' python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["construction_review"]; assert x["boot_mutation_forbidden"] is True' "$policy"
check 'reboot remains forbidden by the review' python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["construction_review"]; assert x["reboot_forbidden"] is True' "$policy"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
if bash "$helper" --output-dir "$TMP" >/dev/null && cmp -s "$policy" "$TMP/phase-1-kernel-package-edge-local-source-construction-review-policy.json" && cmp -s "$record" "$TMP/phase-1-kernel-package-edge-local-source-construction-review.tsv"; then
    pass 'step-198 helper reproduces policy and record deterministically'
else
    fail 'step-198 helper reproduces policy and record deterministically'
fi

check 'reference document records preserved evidence root' contains "$doc" '/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts'
check 'reference document records frozen target package hash' contains "$doc" 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
check 'reference document records builder remains unimplemented' contains "$doc" 'does not implement or execute that builder'
check 'reference document records fresh target revalidation' contains "$doc" 'freshly revalidated'
check 'reference document records next strong safe pause review' contains "$doc" 'phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause'
check 'CHANGELOG records step 198' contains "$changelog" '## Phase 1 step 198 kernel-package-edge local-source construction review'

if ! grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(curl|wget|ftp|rsync|ssh|scp|slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    pass 'step-198 helper contains no executable network, package, boot, reboot, or shutdown command'
else
    fail 'step-198 helper contains no executable network, package, boot, reboot, or shutdown command'
fi

printf 'Result: PASS (%d passes, %d failures)\n' "$passes" "$failures"
(( failures == 0 ))
