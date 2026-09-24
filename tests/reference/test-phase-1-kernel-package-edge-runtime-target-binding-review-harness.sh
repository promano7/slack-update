#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-review.sh"
PROBE="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh"
DOC="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-target-binding-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-review.tsv"
STEP192_HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-boundary-design.sh"
STEP192_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design-policy.json"
STEP192_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design.tsv"
REFERENCE_SCRIPT="$repo_root/tools/reference/slack-update-reference.sh"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

for spec in \
    "$HELPER|step-193 target-binding review helper" \
    "$PROBE|step-193 standalone target-binding probe" \
    "$DOC|step-193 reference document" \
    "$POLICY|step-193 target-binding policy" \
    "$RECORD|step-193 target-binding record" \
    "$STEP192_HELPER|accepted step-192 runtime-boundary helper" \
    "$STEP192_POLICY|accepted step-192 runtime-boundary policy" \
    "$STEP192_RECORD|accepted step-192 runtime-boundary record" \
    "$REFERENCE_SCRIPT|accepted reference implementation"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" 'c8ecaa14ca28e0c7be9f528cbd5ff5d05313a05b3bdc458dd434aa3d8a32a68b' 'step-193 target-binding review helper'
check_hash "$PROBE" 'da2540ccf76749d625721529c660f57861720f3f0e70814ae6fd9865123ea5b6' 'step-193 standalone target-binding probe'
check_hash "$DOC" '4dde1dc1ff861adf065eaf1f4820cdb1ab814dd5c1b9e75b5fbd1ae4902867a2' 'step-193 reference document'
check_hash "$POLICY" 'f840f642934d51ed4e2fc1501ee006fc97d409733b8b5eaaa6c1d7ce70bcf57c' 'step-193 target-binding policy'
check_hash "$RECORD" '492f084e99b92990af0af5ca1738a2025423bf6318b7a5e9e3502bd26f6373fa' 'step-193 target-binding record'
check_hash "$STEP192_HELPER" '6d60eab66bf569832f6998193629ec04993e22554b792e1ceae37076241bd7c8' 'accepted step-192 runtime-boundary helper'
check_hash "$STEP192_POLICY" 'a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a' 'accepted step-192 runtime-boundary policy'
check_hash "$STEP192_RECORD" 'e244ecf5286a9b9e4f448151c1926469bb5c8b892091ea26e52b61c85c8e1d9e' 'accepted step-192 runtime-boundary record'
check_hash "$REFERENCE_SCRIPT" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' 'accepted reference implementation'

if bash -n "$HELPER"; then pass 'step-193 target-binding review helper is shell-syntax valid'; else fail 'step-193 target-binding review helper has invalid shell syntax'; fi
if bash -n "$PROBE"; then pass 'step-193 standalone probe is shell-syntax valid'; else fail 'step-193 standalone probe has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-193 helper exposes a non-mutating help boundary'; else fail 'step-193 helper help boundary failed'; fi
if "$PROBE" --help >/dev/null 2>&1; then pass 'step-193 probe exposes a non-mutating help boundary'; else fail 'step-193 probe help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-193 helper accepts unknown options'; else pass 'step-193 helper rejects unknown options'; fi
if "$PROBE" --unknown >/dev/null 2>&1; then fail 'step-193 probe accepts unknown options'; else pass 'step-193 probe rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-193 target-binding policy is valid JSON'; else fail 'step-193 target-binding policy is invalid JSON'; fi

output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-193 kernel-package-edge target-binding review completed successfully'; else fail 'step-193 target-binding review helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_runtime_boundary_design_step\t192' 'target-binding review starts from accepted step 192'
expect_line $'selected_family\tkernel-package-edge' 'target-binding review preserves kernel-package-edge family'
expect_line $'scenario_count\t1' 'target-binding review preserves the single selected scenario'
expect_line $'target_binding_review_state\truntime-observation-required' 'target-binding review requires a live read-only observation'
expect_line $'target_class\tslackware-current-runtime-validation-vm' 'target class remains Slackware-current validation VM'
expect_line $'expected_hostname_fqdn\tvbox-slackcurrent.vbox-slackcurrent.org' 'target FQDN is frozen'
expect_line $'binding_probe_path\ttools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh' 'standalone probe path is frozen'
expect_line $'binding_probe_sha256\tda2540ccf76749d625721529c660f57861720f3f0e70814ae6fd9865123ea5b6' 'standalone probe SHA-256 is frozen'
expect_line $'probe_execution\troot-via-sudo' 'probe privilege boundary is frozen'
expect_line $'target_repository_required\tno' 'target repository is not required'
expect_line $'source_identity_origin\tcontroller-repo-frozen-at-step-193' 'source identity origin is frozen on the controller'
expect_line $'reference_script_sha256\t1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' 'reference implementation identity is frozen'
expect_line $'effective_config_sha256\t4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' 'effective configuration identity is frozen'
expect_line $'configured_kernel_headers\tkernel-headers' 'configured kernel-header set is frozen'
expect_line $'configured_kernel_boot\tkernel-generic kernel-huge kernel-modules' 'configured kernel boot-package set is frozen'
expect_line $'package_database\t/var/log/packages' 'pkgtools compatibility package database path is frozen'
expect_line $'package_database_canonical\t/var/lib/pkgtools/packages' 'pkgtools canonical package database path is frozen'
expect_line $'package_database_resolution_required\tyes' 'pkgtools compatibility path must resolve exactly to the canonical database'
expect_line $'repository_refresh_allowed\tno' 'repository refresh is forbidden during observation'
expect_line $'network_access_allowed\tno' 'network access is forbidden during observation'
expect_line $'package_mutation_allowed\tno' 'package mutation is forbidden during observation'
expect_line $'boot_mutation_allowed\tno' 'boot mutation is forbidden during observation'
expect_line $'persistent_system_configuration_change_allowed\tno' 'persistent configuration mutation is forbidden during observation'
expect_line $'reboot_allowed\tno' 'reboot is forbidden during observation'
expect_line $'package_pair_binding_deferred\tyes' 'predecessor/target package pair remains deferred'
expect_line $'local_source_binding_deferred\tyes' 'immutable local source remains deferred'
expect_line $'live_candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'observation_output_must_be_returned_for_next_gate\tyes' 'complete probe output is required by the next gate'
expect_line $'target_reboot_invalidates_observation\tyes' 'a target reboot invalidates the observation'
expect_line $'slackware_current_publication_invalidates_review\tno' 'later Slackware-current publication does not invalidate this review'
expect_line $'runtime_target_observation_authorized\tyes' 'read-only target observation is authorized'
expect_line $'target_binding_freeze_authorized_after_successful_observation\tyes' 'successful observation authorizes only the binding-freeze gate'
expect_line $'package_pair_binding_authorized\tno' 'package-pair binding is not authorized'
expect_line $'local_source_binding_authorized\tno' 'local-source binding is not authorized'
expect_line $'runtime_executor_implementation_authorized\tno' 'runtime executor implementation is not authorized'
expect_line $'runtime_execution_authorized\tno' 'runtime execution is not authorized'
expect_line $'repository_refresh_authorized\tno' 'repository refresh remains unauthorized'
expect_line $'network_refresh_authorized\tno' 'network refresh remains unauthorized'
expect_line $'package_action_authorized\tno' 'package action remains unauthorized'
expect_line $'boot_action_authorized\tno' 'boot action remains unauthorized'
expect_line $'reboot_authorized\tno' 'reboot remains unauthorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 remains unauthorized'
expect_line $'machine_action_required\tyes' 'step 193 requires the read-only VM observation'
expect_line $'machine_action_type\tread-only-target-binding-observation' 'machine action is explicitly read-only'
expect_line $'pause_safe\tno' 'step 193 remains inside the active chain'
expect_line $'next_stage\tphase-1-kernel-package-edge-runtime-target-binding-freeze' 'next stage is the target-binding freeze'

if python3 - "$POLICY" "$STEP192_POLICY" <<'PY_ASSERT'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8')); d=json.load(open(sys.argv[2],encoding='utf-8'))
assert d['scenario']=='phase-1-kernel-package-edge-runtime-boundary-design'
assert d['runtime_boundary_design']['state']=='frozen'
assert p['review_only'] is True and p['accepted_runtime_boundary_design']['step']==192
b=p['target_binding_review']
assert b['state']=='runtime-observation-required'
assert b['expected_hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['binding_probe_sha256']=='da2540ccf76749d625721529c660f57861720f3f0e70814ae6fd9865123ea5b6'
assert b['target_repository_required'] is False
assert b['reference_script_sha256']=='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
assert b['effective_config_sha256']=='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert b['configured_kernel_headers']==['kernel-headers']
assert b['configured_kernel_boot']==['kernel-generic','kernel-huge','kernel-modules']
assert b['package_database']=='/var/log/packages'
assert b['package_database_canonical']=='/var/lib/pkgtools/packages'
assert b['successful_observation_requires_exact_package_database_resolution'] is True
assert b['successful_observation_requires_exact_fqdn'] is True
assert b['successful_observation_requires_one_header_record'] is True
assert b['successful_observation_requires_complete_boot_records'] is True
assert b['successful_observation_requires_all_capabilities'] is True
assert b['repository_refresh_allowed'] is False and b['network_access_allowed'] is False
assert b['package_mutation_allowed'] is False and b['boot_mutation_allowed'] is False
assert b['persistent_system_configuration_change_allowed'] is False and b['reboot_allowed'] is False
assert b['package_pair_binding_deferred'] is True and b['local_source_binding_deferred'] is True
assert b['live_candidate_set_bound'] is False and b['live_runtime_chain_open'] is False
assert b['target_reboot_invalidates_observation'] is True and b['slackware_current_publication_invalidates_review'] is False
a=p['authorization']
assert a['runtime_target_observation_authorized'] is True
assert a['target_binding_freeze_authorized_after_successful_observation'] is True
for key in ('package_pair_binding_authorized','local_source_binding_authorized','runtime_executor_implementation_authorized','runtime_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'):
    assert a[key] is False
assert p['machine_action_required'] is True and p['machine_action_type']=='read-only-target-binding-observation'
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-target-binding-freeze' and p['pause_safe'] is False
PY_ASSERT
then pass 'step-193 policy freezes a fail-closed read-only target observation gate'; else fail 'step-193 policy semantic assertions failed'; fi

repro_dir=$(mktemp -d)
if "$HELPER" --output-dir "$repro_dir" >/dev/null 2>&1 && cmp -s "$POLICY" "$repro_dir/$(basename "$POLICY")" && cmp -s "$RECORD" "$repro_dir/$(basename "$RECORD")"; then
    pass 'step-193 helper reproduces policy and record deterministically'
else
    fail 'step-193 helper deterministic reproduction failed'
fi
rm -rf -- "$repro_dir"

if grep -Fqx "readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'" "$PROBE"; then pass 'standalone probe embeds the expected target FQDN'; else fail 'standalone probe target FQDN is not frozen'; fi
if grep -Fqx "readonly FROZEN_REFERENCE_SCRIPT_SHA256='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'" "$PROBE"; then pass 'standalone probe embeds the reference implementation SHA-256'; else fail 'standalone probe reference implementation identity mismatch'; fi
if grep -Fqx "readonly FROZEN_EFFECTIVE_CONFIG_SHA256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'" "$PROBE"; then pass 'standalone probe embeds the effective configuration SHA-256'; else fail 'standalone probe effective configuration identity mismatch'; fi
if grep -Fqx "readonly FROZEN_KERNEL_HEADERS='kernel-headers'" "$PROBE" && grep -Fqx "readonly FROZEN_KERNEL_BOOT='kernel-generic kernel-huge kernel-modules'" "$PROBE"; then pass 'standalone probe embeds the frozen header and boot package sets'; else fail 'standalone probe package sets are not frozen'; fi
if grep -Fq 'expected exactly one installed record' "$PROBE" && grep -Fq 'configured kernel boot package records are incomplete or ambiguous' "$PROBE"; then pass 'standalone probe fails closed on ambiguous header or boot package records'; else fail 'standalone probe package-record fail-closed guards are incomplete'; fi
if grep -Fqx "readonly PACKAGE_DATABASE='/var/log/packages'" "$PROBE" && grep -Fqx "readonly PACKAGE_DATABASE_CANONICAL='/var/lib/pkgtools/packages'" "$PROBE"; then pass 'standalone probe freezes compatibility and canonical pkgtools database paths'; else fail 'standalone probe pkgtools database paths are not frozen'; fi
if grep -Fq 'package_database_resolved=$(readlink -f -- "$PACKAGE_DATABASE"' "$PROBE" && grep -Fq '[[ $package_database_resolved == "$PACKAGE_DATABASE_CANONICAL" ]]' "$PROBE"; then pass 'standalone probe fails closed unless the compatibility symlink resolves to the canonical database'; else fail 'standalone probe package-database resolution guard is incomplete'; fi
if grep -Fq 'for candidate in "$PACKAGE_DATABASE_CANONICAL/$package_name-"*' "$PROBE" && grep -Fq 'manifest_hash "$PACKAGE_DATABASE_CANONICAL"' "$PROBE"; then pass 'standalone probe reads package records and manifest from the canonical database'; else fail 'standalone probe does not consistently use the canonical package database'; fi
if grep -Fq $'binding_status\\tPASS' "$PROBE" && grep -Fq $'target_repository_required\\tno' "$PROBE"; then pass 'standalone probe exposes the required PASS and standalone markers'; else fail 'standalone probe output contract markers are incomplete'; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$PROBE"; then fail 'standalone probe executes a package, boot, reboot, or shutdown mutation command'; else pass 'standalone probe executes no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '^[[:space:]]*(curl|wget|rsync|scp|ssh|ping)([[:space:]]|$)' "$PROBE"; then fail 'standalone probe executes a network client command'; else pass 'standalone probe executes no network client command'; fi
if grep -Eq '^[[:space:]]*(cp|mv|rm|install|touch|mkdir|chmod|chown)([[:space:]]|$)' "$PROBE"; then fail 'standalone probe executes a persistent filesystem mutation command'; else pass 'standalone probe executes no persistent filesystem mutation command'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'standalone probe'* && $normalized_doc == *'/var/log/packages'* && $normalized_doc == *'/var/lib/pkgtools/packages'* && $normalized_doc == *'exactly one `kernel-headers` package record'* && $normalized_doc == *'A later Slackware-current publication does not invalidate this review'* && $normalized_doc == *'phase-1-kernel-package-edge-runtime-target-binding-freeze'* ]]; then pass 'reference document records canonical pkgtools layout, fail-closed package state, publication rule, and next stage'; else fail 'step-193 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 193 kernel-package-edge runtime target-binding review' "$CHANGELOG" && grep -Fq 'Phase 1 step 193-r1 kernel-package-edge pkgtools database layout remediation' "$CHANGELOG" && grep -Fq 'phase-1-kernel-package-edge-runtime-target-binding-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 193 and remediation 193-r1'; else fail 'CHANGELOG does not record step 193-r1 remediation'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
