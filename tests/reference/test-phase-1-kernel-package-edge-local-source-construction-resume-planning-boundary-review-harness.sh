#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.md"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv"
step199_policy="$acc/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause-policy.json"
step199_record="$acc/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv"
changelog="$repo_root/CHANGELOG.md"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

require_regular() {
    local label=$1 path=$2
    if [[ -f $path && ! -L $path ]]; then pass "$label"; else fail "$label"; fi
}

expect_tsv() {
    local expected=$1 label=$2
    if grep -Fxq -- "$expected" "$record"; then pass "$label"; else fail "$label"; fi
}

for item in \
    "step-200 helper|$helper" \
    "step-200 document|$doc" \
    "step-200 policy|$policy" \
    "step-200 record|$record" \
    "accepted step-199 policy|$step199_policy" \
    "accepted step-199 record|$step199_record" \
    "CHANGELOG|$changelog"; do
    require_regular "${item%%|*} is a regular file" "${item#*|}"
done

if [[ ! -e $builder ]]; then pass 'local-source builder remains unimplemented'; else fail 'local-source builder remains unimplemented'; fi

if [[ $(sha256sum -- "$step199_policy" | awk '{print $1}') == '6577709a7fc3b822a9e7e6bcf4f94c973d0a12d829b3a65efc7da4a5038d6a43' ]]; then pass 'accepted step-199 policy hash is frozen'; else fail 'accepted step-199 policy hash is frozen'; fi
if [[ $(sha256sum -- "$step199_record" | awk '{print $1}') == '4bd523d8f5958f6227ef6ee48f208e8253a06a2c7f9d9a1b6664286286fda8a1' ]]; then pass 'accepted step-199 record hash is frozen'; else fail 'accepted step-199 record hash is frozen'; fi

expect_tsv $'accepted_checkpoint_step\t199' 'record binds step 199 as accepted checkpoint'
expect_tsv $'accepted_checkpoint_strong_safe_pause\tyes' 'record preserves the strong safe pause origin'
expect_tsv $'fresh_boundary\tyes' 'record opens a fresh boundary'
expect_tsv $'boundary_scope\tphase-1-kernel-package-edge-local-source-construction-resume-planning' 'record freezes the resume-planning scope'
expect_tsv $'selected_family\tkernel-package-edge' 'kernel-package-edge remains selected'
expect_tsv $'family_closed\tno' 'kernel-package-edge remains open'
expect_tsv $'artifact_byte_binding_state\taccepted-byte-binding-frozen' 'artifact byte binding remains frozen'
expect_tsv $'evidence_root_must_remain_unchanged\tyes' 'external evidence root must remain unchanged'
expect_tsv $'artifact_binding_survives_later_publication\tyes' 'artifact binding survives later publication'
expect_tsv $'controller_reacquisition_authorized\tno' 'artifact reacquisition is not authorized'
expect_tsv $'builder_implementation_state\tnot-implemented' 'local-source builder remains deferred'
expect_tsv $'local_source_tree_built\tno' 'local-source tree remains unbuilt'
expect_tsv $'prior_target_binding_reusable\tno' 'pre-pause target binding remains expired'
expect_tsv $'fresh_target_revalidation_required_before_machine_action\tyes' 'fresh target revalidation remains mandatory'
expect_tsv $'fresh_candidate_set_required_before_runtime\tyes' 'fresh runtime candidate set remains mandatory'
expect_tsv $'target_observation_authorized_now\tno' 'step 200 does not authorize target observation'
expect_tsv $'target_vm_action_authorized\tno' 'step 200 does not authorize target action'
expect_tsv $'target_vm_network_access_authorized\tno' 'step 200 does not authorize target network access'
expect_tsv $'target_artifact_copy_authorized\tno' 'step 200 does not authorize target artifact copy'
expect_tsv $'local_source_build_authorized\tno' 'step 200 does not authorize local-source build'
expect_tsv $'runtime_scenario_execution_authorized\tno' 'step 200 does not authorize runtime execution'
expect_tsv $'package_action_authorized\tno' 'step 200 does not authorize package action'
expect_tsv $'boot_action_authorized\tno' 'step 200 does not authorize boot action'
expect_tsv $'reboot_authorized\tno' 'step 200 does not authorize reboot'
expect_tsv $'phase_2_start_authorized\tno' 'step 200 does not authorize Phase 2'
expect_tsv $'machine_action_required\tno' 'step 200 requires no machine action'
expect_tsv $'pause_safe\tno' 'step 200 opens an active planning chain'
expect_tsv $'next_stage\tphase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review' 'record routes only to fresh target revalidation review'

TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
if "$helper" --output-dir "$TMP" >/dev/null \
   && cmp -s -- "$policy" "$TMP/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review-policy.json" \
   && cmp -s -- "$record" "$TMP/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv"; then
    pass 'step-200 helper reproduces policy and record deterministically'
else
    fail 'step-200 helper reproduces policy and record deterministically'
fi

if python3 - "$policy" "$step199_policy" <<'PY'
import json
import sys
from pathlib import Path
p = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
p199 = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
assert p199['safe_pause']['strong_safe_pause'] is True
assert p['review_only'] is True
assert p['accepted_checkpoint']['step'] == 199
assert p['accepted_checkpoint']['strong_safe_pause'] is True
assert p['fresh_boundary']['opened'] is True
assert p['fresh_boundary']['scope'] == 'phase-1-kernel-package-edge-local-source-construction-resume-planning'
assert p['fresh_boundary']['selected_family_preserved'] is True
assert p['fresh_boundary']['live_runtime_chain_open'] is False
assert p['fresh_boundary']['runtime_candidate_set_bound'] is False
assert p['selected_family']['family'] == 'kernel-package-edge'
assert p['selected_family']['family_closed'] is False
assert p['artifact_byte_binding']['state'] == 'accepted-byte-binding-frozen'
assert p['artifact_byte_binding']['evidence_root_must_remain_unchanged'] is True
assert p['artifact_byte_binding']['survives_later_publication'] is True
assert p['artifact_byte_binding']['controller_reacquisition_authorized'] is False
assert p['local_source_state']['builder_implementation_state'] == 'not-implemented'
assert p['local_source_state']['local_source_tree_built'] is False
assert p['local_source_state']['local_source_tree_manifest_bound'] is False
assert p['runtime_revalidation']['prior_target_binding_reusable'] is False
assert p['runtime_revalidation']['fresh_target_revalidation_required_before_machine_action'] is True
assert p['runtime_revalidation']['fresh_candidate_set_required_before_runtime'] is True
assert p['runtime_revalidation']['target_observation_authorized_now'] is False
for key, value in p['authorization'].items():
    if key == 'future_work_requires_explicit_authorization':
        assert value is True
    else:
        assert value is False
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['next_stage'] == 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review'
PY
then pass 'step-200 policy preserves safe-pause state while opening no operational authority'; else fail 'step-200 semantic assertions failed'; fi

if grep -Fq 'The pre-pause target binding remains expired and must not be reused.' "$doc" \
   && grep -Fq 'tools/reference/phase-1-kernel-package-edge-local-source-build.sh' "$doc" \
   && grep -Fq 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review' "$doc"; then
    pass 'reference document records expired runtime binding, deferred builder, and next stage'
else
    fail 'step-200 reference document is incomplete'
fi

if grep -Fq '## Phase 1 step 200 kernel-package-edge local-source construction resume-planning boundary review' "$changelog" \
   && grep -Fq 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review' "$changelog"; then
    pass 'CHANGELOG records step 200'
else
    fail 'CHANGELOG does not record step 200'
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(curl|wget|ftp|rsync|ssh|scp|slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail 'step-200 helper contains an operational command'
else
    pass 'step-200 helper contains no executable network, package, boot, reboot, or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $failures -eq 0 ]] && printf PASS || printf FAIL )" "$passes" "$failures"
(( failures == 0 ))
