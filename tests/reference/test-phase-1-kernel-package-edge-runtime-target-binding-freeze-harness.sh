#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass(){ printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-target-binding-freeze.md"
POLICY="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json"
RECORD="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv"
REVIEW_HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-review.sh"
REVIEW_PROBE="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh"
REVIEW_DOC="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-target-binding-review.md"
REVIEW_POLICY="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-review-policy.json"
REVIEW_RECORD="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-review.tsv"
REVIEW_HARNESS="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-target-binding-review-harness.sh"
CHANGELOG="$repo_root/CHANGELOG.md"

regular(){ [[ -f $1 && ! -L $1 ]]; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }

for spec in \
  "$HELPER|step-194 target-binding freeze helper" \
  "$DOC|step-194 reference document" \
  "$POLICY|step-194 target-binding policy" \
  "$RECORD|step-194 target-binding record" \
  "$REVIEW_HELPER|accepted step-193-r2 review helper" \
  "$REVIEW_PROBE|accepted step-193-r2 standalone probe" \
  "$REVIEW_DOC|accepted step-193-r2 reference document" \
  "$REVIEW_POLICY|accepted step-193-r2 review policy" \
  "$REVIEW_RECORD|accepted step-193-r2 review record" \
  "$REVIEW_HARNESS|accepted step-193-r2 review harness"; do
    file=${spec%%|*}; label=${spec#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$HELPER") == '4d6eeac51205934663f7669242c0124f7a5cd4d99b994b6b4d1315e07ccb719f' ]] && pass 'step-194 helper has the exact reviewed SHA-256' || fail 'step-194 helper SHA-256 mismatch'
[[ $(sha "$DOC") == '75c06799591893868f743ef7c0834975ecac9d867f32f56add836fcec40dc106' ]] && pass 'step-194 reference document has the exact reviewed SHA-256' || fail 'step-194 reference document SHA-256 mismatch'
[[ $(sha "$POLICY") == '0db70e4cbeba69a607a372181745ef936bcc693cfe11eb8aebf2c3f764c29621' ]] && pass 'step-194 policy has the exact reviewed SHA-256' || fail 'step-194 policy SHA-256 mismatch'
[[ $(sha "$RECORD") == 'd2bbc87628a78d79077ecf51732a63dcbec55fc136b3d47ae2702c96867b09c6' ]] && pass 'step-194 record has the exact reviewed SHA-256' || fail 'step-194 record SHA-256 mismatch'
[[ $(sha "$REVIEW_HELPER") == '15788b1c8f973fc9bdffaa6c582b313632025a1d98f691f3f89211019b8a99a2' ]] && pass 'accepted step-193-r2 review helper has the exact reviewed SHA-256' || fail 'accepted step-193-r2 review helper SHA-256 mismatch'
[[ $(sha "$REVIEW_PROBE") == 'bda22255aaa1db2dad4f8a28ed89719ddc89dbb03989fa3facd0a19c6d65ac6f' ]] && pass 'accepted step-193-r2 probe has the exact reviewed SHA-256' || fail 'accepted step-193-r2 probe SHA-256 mismatch'
[[ $(sha "$REVIEW_DOC") == '07f2a27c64d7edd3e9854b4dadc5606e4ced0f61d258bc1bb8450915e8aaf1df' ]] && pass 'accepted step-193-r2 reference document has the exact reviewed SHA-256' || fail 'accepted step-193-r2 reference document SHA-256 mismatch'
[[ $(sha "$REVIEW_POLICY") == '834276083c8e4d50c2c5510e10c21c512bb10ee85a88b70baeebf7a494d5f7a1' ]] && pass 'accepted step-193-r2 review policy has the exact reviewed SHA-256' || fail 'accepted step-193-r2 review policy SHA-256 mismatch'
[[ $(sha "$REVIEW_RECORD") == '6fc9cc61a4ac84eff07f2cf273aabda043f13115b53f35fdfa670c7a64815160' ]] && pass 'accepted step-193-r2 review record has the exact reviewed SHA-256' || fail 'accepted step-193-r2 review record SHA-256 mismatch'
[[ $(sha "$REVIEW_HARNESS") == '310b2c7d9150a826fcddeb66871f9beced73785801c7b972ac7bbdfa13267bc8' ]] && pass 'accepted step-193-r2 review harness has the exact reviewed SHA-256' || fail 'accepted step-193-r2 review harness SHA-256 mismatch'

bash -n "$HELPER" && pass 'step-194 helper is shell-syntax valid' || fail 'step-194 helper has invalid shell syntax'
"$HELPER" --help >/dev/null 2>&1 && pass 'step-194 helper exposes a non-mutating help boundary' || fail 'step-194 helper help failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-194 helper accepts an unknown option'; else pass 'step-194 helper rejects unknown options'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-194 target-binding freeze policy is valid JSON' || fail 'step-194 policy is invalid JSON'

if python3 - "$POLICY" <<'INNERPY'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-runtime-target-binding-freeze'
assert p['review_only'] is True
r=p['accepted_target_binding_review']
assert r['step']==193 and r['revision']=='r2-boot-package-observation'
assert r['policy_sha256']=='834276083c8e4d50c2c5510e10c21c512bb10ee85a88b70baeebf7a494d5f7a1'
assert r['record_sha256']=='6fc9cc61a4ac84eff07f2cf273aabda043f13115b53f35fdfa670c7a64815160'
assert r['probe_sha256']=='bda22255aaa1db2dad4f8a28ed89719ddc89dbb03989fa3facd0a19c6d65ac6f'
b=p['runtime_target_binding']
assert b['state']=='frozen' and b['observation_status']=='PASS'
assert b['target_class']=='slackware-current-runtime-validation-vm'
assert b['target_hostname']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['uname_release']=='6.18.45' and b['uname_machine']=='x86_64'
assert b['slackware_version']=='Slackware 15.0+'
assert b['boot_id']=='5e79b100-55a8-415d-a6ea-1cb8c568c2eb'
assert b['reference_script_sha256']=='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
assert b['effective_config_sha256']=='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert b['configured_kernel_headers']==['kernel-headers']
assert b['configured_kernel_boot']==['kernel-generic','kernel-huge','kernel-modules']
assert b['package_database']=='/var/log/packages'
assert b['package_database_canonical']=='/var/lib/pkgtools/packages'
assert b['package_database_resolved']=='/var/lib/pkgtools/packages'
assert b['package_database_manifest_sha256']=='3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
assert b['header_package_record_count']==1
assert b['header_package_record']=='kernel-headers-6.18.45-x86-1'
assert b['boot_package_records_unambiguous'] is True
assert b['installed_boot_package_count']==1
obs={x['name']:x for x in b['boot_package_observations']}
assert obs['kernel-generic']=={'name':'kernel-generic','record_count':1,'status':'installed','record':'kernel-generic-6.18.45-x86_64-1'}
assert obs['kernel-huge']=={'name':'kernel-huge','record_count':0,'status':'absent','record':None}
assert obs['kernel-modules']=={'name':'kernel-modules','record_count':0,'status':'absent','record':None}
assert b['slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
assert b['slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
assert b['probe_sha256']=='bda22255aaa1db2dad4f8a28ed89719ddc89dbb03989fa3facd0a19c6d65ac6f'
assert b['source_identity_origin']=='controller-repo-frozen-at-step-193'
assert b['target_repository_required'] is False
for key in ('repository_refresh_performed','network_access_performed','package_action_performed','boot_action_performed','persistent_configuration_change_performed','reboot_performed'):
    assert b[key] is False
v=b['validity_requirements']
for key in ('same_hostname_fqdn_required','same_boot_id_required_before_staging','same_running_kernel_required_before_staging','same_uname_machine_required','same_reference_script_sha256_required','same_effective_config_sha256_required','same_package_database_layout_required','same_package_database_manifest_sha256_required_before_staging','same_header_package_record_required_before_staging','same_boot_package_observations_required_before_staging','same_slackpkg_conf_sha256_required_before_source_binding','same_slackpkg_mirrors_sha256_required_before_source_binding','same_probe_sha256_required_for_binding_reproduction','target_reboot_invalidates_binding','running_kernel_change_invalidates_binding','package_database_drift_invalidates_pre_staging_binding','slackpkg_configuration_drift_invalidates_source_binding','controller_reference_or_config_change_invalidates_binding'):
    assert v[key] is True
assert v['later_slackware_current_publication_invalidates_binding'] is False
assert v['binding_drift_action']=='stop-before-package-staging-and-return-to-target-binding-review'
a=p['authorization']
assert a['package_pair_and_local_source_binding_design_authorized_for_next_stage'] is True
for key in ('package_pair_binding_authorized','local_source_binding_authorized','runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'):
    assert a[key] is False
assert p['machine_action_required'] is False
assert p['slackware_current_publication_invalidates_binding'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-package-pair-and-local-source-binding-design'
assert p['pause_safe'] is False
INNERPY
then pass 'step-194 target binding freeze completed successfully'; else fail 'step-194 target-binding semantic assertions failed'; fi

for line in \
  $'runtime_target_binding_state\tfrozen' \
  $'observation_status\tPASS' \
  $'hostname_fqdn\tvbox-slackcurrent.vbox-slackcurrent.org' \
  $'uname_release\t6.18.45' \
  $'boot_id\t5e79b100-55a8-415d-a6ea-1cb8c568c2eb' \
  $'package_database_manifest_sha256\t3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910' \
  $'header_package_record\tkernel-headers-6.18.45-x86-1' \
  $'boot_package_record_status_kernel-generic\tinstalled' \
  $'boot_package_record_status_kernel-huge\tabsent' \
  $'boot_package_record_status_kernel-modules\tabsent' \
  $'slackpkg_conf_sha256\tf1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' \
  $'slackpkg_mirrors_sha256\t71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12' \
  $'package_action_authorized\tno' \
  $'next_stage\tphase-1-kernel-package-edge-package-pair-and-local-source-binding-design'; do
    grep -Fqx "$line" "$RECORD" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"
done

regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
if "$HELPER" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-194 helper regenerates policy and record'; else fail 'step-194 helper regeneration failed'; fi
cmp -s "$POLICY" "$regen/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json" && pass 'step-194 helper reproduces the frozen policy exactly' || fail 'step-194 regenerated policy differs'
cmp -s "$RECORD" "$regen/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv" && pass 'step-194 helper reproduces the frozen record exactly' || fail 'step-194 regenerated record differs'

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-194 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-194 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$HELPER"; then fail 'step-194 helper contains a network client command'; else pass 'step-194 helper contains no network client command'; fi
if grep -Fq 'Phase 1 step 194 kernel-package-edge runtime target-binding freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 194'; else fail 'CHANGELOG does not record step 194'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'5e79b100-55a8-415d-a6ea-1cb8c568c2eb'* && $normalized_doc == *'kernel-headers-6.18.45-x86-1'* && $normalized_doc == *'3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'* && $normalized_doc == *'package-pair-and-local-source-binding-design'* ]]; then pass 'reference document records exact target/package binding, invalidation boundary, and next stage'; else fail 'step-194 reference document is incomplete'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
