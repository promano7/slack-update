#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.md"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.tsv"
step200_policy="$acc/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review-policy.json"
step200_record="$acc/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv"
step194_policy="$acc/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json"
step194_record="$acc/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv"
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
    "step-201 helper|$helper" \
    "step-201 probe|$probe" \
    "step-201 document|$doc" \
    "step-201 policy|$policy" \
    "step-201 record|$record" \
    "accepted step-200 policy|$step200_policy" \
    "accepted step-200 record|$step200_record" \
    "historical step-194 policy|$step194_policy" \
    "historical step-194 record|$step194_record" \
    "CHANGELOG|$changelog"; do
    require_regular "${item%%|*} is a regular file" "${item#*|}"
done

if [[ ! -e $builder ]]; then pass 'local-source builder remains unimplemented'; else fail 'local-source builder remains unimplemented'; fi

if [[ $(sha256sum -- "$step200_policy" | awk '{print $1}') == '801fb952679b8e32847b027c52a05c73b1af33b981e52925d8df0bf8dc38b945' ]]; then pass 'accepted step-200 policy hash is frozen'; else fail 'accepted step-200 policy hash is frozen'; fi
if [[ $(sha256sum -- "$step200_record" | awk '{print $1}') == '55e78ed7aafc384f48b6e3ed7952f6b8389aa92afdecf171f70550b0c0ac63ca' ]]; then pass 'accepted step-200 record hash is frozen'; else fail 'accepted step-200 record hash is frozen'; fi
if [[ $(sha256sum -- "$step194_policy" | awk '{print $1}') == '0db70e4cbeba69a607a372181745ef936bcc693cfe11eb8aebf2c3f764c29621' ]]; then pass 'historical step-194 policy hash is frozen'; else fail 'historical step-194 policy hash is frozen'; fi
if [[ $(sha256sum -- "$step194_record" | awk '{print $1}') == 'd2bbc87628a78d79077ecf51732a63dcbec55fc136b3d47ae2702c96867b09c6' ]]; then pass 'historical step-194 record hash is frozen'; else fail 'historical step-194 record hash is frozen'; fi

expect_tsv $'accepted_resume_boundary_step\t200' 'record binds accepted step 200'
expect_tsv $'historical_target_baseline_step\t194' 'record identifies step 194 only as historical baseline'
expect_tsv $'prior_target_binding_reusable\tno' 'prior target binding remains expired'
expect_tsv $'historical_baseline_purpose\texpected-pre-staging-state-only' 'historical binding is used only as expected state'
expect_tsv $'previous_boot_id_match_required\tno' 'old boot ID is not required'
expect_tsv $'selected_family\tkernel-package-edge' 'kernel-package-edge remains selected'
expect_tsv $'family_closed\tno' 'kernel-package-edge remains open'
expect_tsv $'artifact_byte_binding_state\taccepted-byte-binding-frozen' 'artifact byte binding remains frozen'
expect_tsv $'evidence_root_must_remain_unchanged\tyes' 'external evidence root remains immutable'
expect_tsv $'frozen_predecessor_artifact\tkernel-headers-6.18.44-x86-1.txz' 'predecessor artifact remains frozen'
expect_tsv $'frozen_target_artifact\tkernel-headers-6.18.45-x86-1.txz' 'target artifact remains frozen'
expect_tsv $'fresh_target_revalidation_state\tread-only-observation-authorized' 'fresh read-only revalidation is authorized'
expect_tsv $'probe_execution\troot-via-sudo' 'probe execution method is frozen'
expect_tsv $'expected_hostname_fqdn\tvbox-slackcurrent.vbox-slackcurrent.org' 'expected target FQDN is frozen'
expect_tsv $'expected_uname_release\t6.18.45' 'expected running kernel is frozen'
expect_tsv $'expected_header_package_record\tkernel-headers-6.18.45-x86-1' 'expected header record is frozen'
expect_tsv $'expected_kernel_generic_record\tkernel-generic-6.18.45-x86_64-1' 'expected kernel-generic record is frozen'
expect_tsv $'expected_kernel_huge_status\tabsent' 'kernel-huge expected absence is frozen'
expect_tsv $'expected_kernel_modules_status\tabsent' 'kernel-modules expected absence is frozen'
expect_tsv $'fresh_boot_id_required\tyes' 'fresh boot ID observation is required'
expect_tsv $'target_repository_required\tno' 'target repository is not required'
expect_tsv $'repository_refresh_allowed\tno' 'repository refresh remains forbidden'
expect_tsv $'network_access_allowed\tno' 'target network access remains forbidden'
expect_tsv $'package_mutation_allowed\tno' 'package mutation remains forbidden'
expect_tsv $'boot_mutation_allowed\tno' 'boot mutation remains forbidden'
expect_tsv $'reboot_allowed\tno' 'reboot remains forbidden'
expect_tsv $'live_candidate_set_bound\tno' 'no live candidate set is bound'
expect_tsv $'runtime_target_revalidation_observation_authorized\tyes' 'only fresh target observation is opened'
expect_tsv $'fresh_target_revalidation_freeze_authorized_after_successful_observation\tyes' 'successful observation may route to freeze'
expect_tsv $'target_artifact_copy_authorized\tno' 'target artifact copy remains forbidden'
expect_tsv $'local_source_build_authorized\tno' 'local-source build remains forbidden'
expect_tsv $'runtime_scenario_execution_authorized\tno' 'runtime scenario execution remains forbidden'
expect_tsv $'package_action_authorized\tno' 'package action remains forbidden'
expect_tsv $'boot_action_authorized\tno' 'boot action remains forbidden'
expect_tsv $'phase_2_start_authorized\tno' 'Phase 2 remains forbidden'
expect_tsv $'machine_action_required\tyes' 'step 201 requires the read-only VM observation'
expect_tsv $'machine_action_type\tread-only-fresh-target-revalidation-observation' 'machine action is explicitly read-only revalidation'
expect_tsv $'pause_safe\tno' 'step 201 remains inside the active chain'
expect_tsv $'next_stage\tphase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze' 'record routes only to fresh-target revalidation freeze'

TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
if "$helper" --output-dir "$TMP" >/dev/null \
   && cmp -s -- "$policy" "$TMP/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review-policy.json" \
   && cmp -s -- "$record" "$TMP/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.tsv"; then
    pass 'step-201 helper reproduces policy and record deterministically'
else
    fail 'step-201 helper deterministic reproduction failed'
fi

if python3 - "$policy" "$step200_policy" "$step194_policy" "$probe" <<'PY'
import hashlib
import json
import sys
from pathlib import Path
p = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
p200 = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
p194 = json.loads(Path(sys.argv[3]).read_text(encoding='utf-8'))
probe_path = Path(sys.argv[4])
probe_sha = hashlib.sha256(probe_path.read_bytes()).hexdigest()
assert p200['runtime_revalidation']['prior_target_binding_reusable'] is False
assert p194['runtime_target_binding']['state'] == 'frozen'
assert p['review_only'] is True
assert p['accepted_resume_boundary']['step'] == 200
assert p['accepted_resume_boundary']['prior_target_binding_reusable'] is False
assert p['historical_target_baseline']['step'] == 194
assert p['historical_target_baseline']['binding_reusable'] is False
assert p['historical_target_baseline']['previous_boot_id_is_not_reused'] is True
assert p['selected_family']['family'] == 'kernel-package-edge'
assert p['artifact_byte_binding']['state'] == 'accepted-byte-binding-frozen'
assert p['artifact_byte_binding']['evidence_root_must_remain_unchanged'] is True
r = p['fresh_target_revalidation']
assert r['state'] == 'read-only-observation-authorized'
assert r['probe_sha256'] == probe_sha
assert r['expected_hostname_fqdn'] == 'vbox-slackcurrent.vbox-slackcurrent.org'
assert r['expected_uname_machine'] == 'x86_64'
assert r['expected_uname_release'] == '6.18.45'
assert r['expected_slackware_version'] == 'Slackware 15.0+'
assert r['expected_package_database_manifest_sha256'] == '3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
assert r['expected_header_package_record'] == 'kernel-headers-6.18.45-x86-1'
assert r['expected_kernel_generic_record'] == 'kernel-generic-6.18.45-x86_64-1'
assert r['expected_kernel_huge_status'] == 'absent'
assert r['expected_kernel_modules_status'] == 'absent'
assert r['fresh_boot_id_required'] is True
assert r['previous_boot_id_match_required'] is False
assert r['previous_boot_id_must_not_be_used_as_binding'] is True
assert r['target_repository_required'] is False
assert r['repository_refresh_allowed'] is False
assert r['network_access_allowed'] is False
assert r['package_mutation_allowed'] is False
assert r['boot_mutation_allowed'] is False
assert r['persistent_system_configuration_change_allowed'] is False
assert r['reboot_allowed'] is False
assert r['live_candidate_set_bound'] is False
assert p['local_source_state']['builder_implementation_state'] == 'not-implemented'
assert p['local_source_state']['local_source_tree_built'] is False
assert p['authorization']['runtime_target_revalidation_observation_authorized'] is True
assert p['authorization']['fresh_target_revalidation_freeze_authorized_after_successful_observation'] is True
for key, value in p['authorization'].items():
    if key in {'runtime_target_revalidation_observation_authorized', 'fresh_target_revalidation_freeze_authorized_after_successful_observation'}:
        assert value is True
    else:
        assert value is False
assert p['machine_action_required'] is True
assert p['machine_action_type'] == 'read-only-fresh-target-revalidation-observation'
assert p['pause_safe'] is False
assert p['next_stage'] == 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze'
PY
then pass 'step-201 policy freezes a fresh fail-closed read-only revalidation gate'; else fail 'step-201 policy semantic assertions failed'; fi

if bash -n "$probe"; then pass 'fresh-target probe passes shell syntax validation'; else fail 'fresh-target probe shell syntax validation failed'; fi

probe_sha=$(sha256sum -- "$probe" | awk '{print $1}')
if grep -Fxq -- $'revalidation_probe_sha256\t'"$probe_sha" "$record"; then pass 'record binds the exact fresh-target probe SHA-256'; else fail 'record probe SHA-256 binding mismatch'; fi

if grep -Fqx "readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'" "$probe" \
   && grep -Fqx "readonly EXPECTED_UNAME_RELEASE='6.18.45'" "$probe" \
   && grep -Fqx "readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'" "$probe"; then
    pass 'probe embeds the exact resumed target identity and header baseline'
else
    fail 'probe target/header baseline is incomplete'
fi

if grep -Fqx "readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'" "$probe" \
   && grep -Fqx "readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'" "$probe" \
   && grep -Fqx "readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'" "$probe"; then
    pass 'probe embeds the frozen package-database and slackpkg fingerprints'
else
    fail 'probe package/configuration fingerprint baseline is incomplete'
fi

if grep -Fq $'prior_target_binding_reused\\tno' "$probe" \
   && grep -Fq $'fresh_boot_id_observed\\tyes' "$probe" \
   && ! grep -Fq '5e79b100-55a8-415d-a6ea-1cb8c568c2eb' "$probe"; then
    pass 'probe records a fresh boot identity without embedding the expired boot ID'
else
    fail 'probe accidentally reuses the expired boot identity'
fi

if grep -Fq 'package database manifest drift' "$probe" \
   && grep -Fq 'kernel-headers record drift' "$probe" \
   && grep -Fq 'kernel-generic record drift' "$probe" \
   && grep -Fq 'slackpkg.conf fingerprint drift' "$probe"; then
    pass 'probe fails closed on pre-staging package/configuration drift'
else
    fail 'probe drift guards are incomplete'
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$probe"; then
    fail 'fresh-target probe executes a package, boot, reboot, or shutdown mutation command'
else
    pass 'fresh-target probe executes no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh|ping)([[:space:]]|$)' "$probe"; then
    fail 'fresh-target probe executes a network client command'
else
    pass 'fresh-target probe executes no network client command'
fi
if grep -Eq '^[[:space:]]*(cp|mv|rm|install|touch|mkdir|chmod|chown)([[:space:]]|$)' "$probe"; then
    fail 'fresh-target probe executes a persistent filesystem mutation command'
else
    pass 'fresh-target probe executes no persistent filesystem mutation command'
fi

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'step-194 runtime target binding remains expired and is not reusable'* \
   && $normalized_doc == *'does not require the old step-194 boot ID'* \
   && $normalized_doc == *'kernel-headers-6.18.45-x86-1'* \
   && $normalized_doc == *'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze'* ]]; then
    pass 'reference document records expired binding, fresh boot semantics, exact baseline, and next stage'
else
    fail 'step-201 reference document is incomplete'
fi

if grep -Fq '## Phase 1 step 201 kernel-package-edge fresh target revalidation review' "$changelog" \
   && grep -Fq 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze' "$changelog"; then
    pass 'CHANGELOG records step 201'
else
    fail 'CHANGELOG does not record step 201'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $failures -eq 0 ]] && printf PASS || printf FAIL )" "$passes" "$failures"
(( failures == 0 ))
