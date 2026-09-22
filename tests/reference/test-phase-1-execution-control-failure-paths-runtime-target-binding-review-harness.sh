#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
HELPER="$REPO_ROOT/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.sh"
PROBE="$REPO_ROOT/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh"
DOC="$REPO_ROOT/docs/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.md"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json"
RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv"
STEP180_POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design-policy.json"
STEP180_RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv"
REFERENCE_SCRIPT="$REPO_ROOT/tools/reference/slack-update-reference.sh"
EFFECTIVE_CONFIG="$REPO_ROOT/data/config/slack-update.conf"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
for spec in \
    "$HELPER|step-181-r1 target-binding review helper" \
    "$PROBE|step-181-r1 standalone target-binding probe" \
    "$DOC|step-181-r1 reference document" \
    "$POLICY|step-181-r1 target-binding review policy" \
    "$RECORD|step-181-r1 target-binding review record" \
    "$STEP180_POLICY|accepted step-180 boundary-design policy" \
    "$STEP180_RECORD|accepted step-180 boundary-design record" \
    "$REFERENCE_SCRIPT|controller reference script" \
    "$EFFECTIVE_CONFIG|controller effective config"
do check_regular "${spec%%|*}" "${spec#*|}"; done

check_hash() { local file=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }
check_hash "$STEP180_POLICY" '63a1605b36cddbc12fb3e0b3b68a349435f2230348bf3be76c71cd04e1c84cf1' 'accepted step-180 boundary-design policy'
check_hash "$STEP180_RECORD" '0d4c3f5015da8f32bdb431d1246b5f670ace8cece2ccfc8331a69f73d87fcab1' 'accepted step-180 boundary-design record'

if bash -n "$HELPER"; then pass 'step-181-r1 target-binding review helper is shell-syntax valid'; else fail 'step-181-r1 helper has invalid shell syntax'; fi
if bash -n "$PROBE"; then pass 'step-181-r1 standalone probe is shell-syntax valid'; else fail 'step-181-r1 probe has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-181-r1 helper exposes a non-mutating help boundary'; else fail 'step-181-r1 helper help boundary failed'; fi
if "$PROBE" --help >/dev/null 2>&1; then pass 'step-181-r1 probe exposes a non-mutating help boundary'; else fail 'step-181-r1 probe help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-181-r1 helper accepts unknown options'; else pass 'step-181-r1 helper rejects unknown options'; fi
if "$PROBE" --unknown >/dev/null 2>&1; then fail 'step-181-r1 probe accepts unknown options'; else pass 'step-181-r1 probe rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-181-r1 target-binding review policy is valid JSON'; else fail 'step-181-r1 target-binding review policy is invalid JSON'; fi

reference_sha=$(sha256sum -- "$REFERENCE_SCRIPT" | awk '{print $1}')
config_sha=$(sha256sum -- "$EFFECTIVE_CONFIG" | awk '{print $1}')
probe_sha=$(sha256sum -- "$PROBE" | awk '{print $1}')
helper_sha=$(sha256sum -- "$HELPER" | awk '{print $1}')
probe_reference_sha=$(sed -n "s/^readonly FROZEN_REFERENCE_SCRIPT_SHA256='\([0-9a-f]\{64\}\)'$/\1/p" "$PROBE")
probe_config_sha=$(sed -n "s/^readonly FROZEN_EFFECTIVE_CONFIG_SHA256='\([0-9a-f]\{64\}\)'$/\1/p" "$PROBE")
if [[ $probe_reference_sha == "$reference_sha" ]]; then pass 'standalone probe embeds the controller reference-script SHA-256'; else fail 'standalone probe reference-script SHA-256 mismatch'; fi
if [[ $probe_config_sha == "$config_sha" ]]; then pass 'standalone probe embeds the controller effective-config SHA-256'; else fail 'standalone probe effective-config SHA-256 mismatch'; fi

if python3 - "$POLICY" "$probe_sha" "$helper_sha" "$reference_sha" "$config_sha" <<'INNERPY'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
probe_sha, helper_sha, reference_sha, config_sha=sys.argv[2:]
assert p['revision']=='r1-standalone-probe'
assert p['review_only'] is True and p['accepted_runtime_boundary_design']['step']==180
b=p['target_binding_review']
assert b['state']=='runtime-observation-required'
assert b['expected_hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['binding_probe_sha256']==probe_sha
assert b['target_repository_required'] is False
assert b['source_identity_origin']=='controller-repo-frozen-into-standalone-probe'
assert b['reference_script_sha256']==reference_sha
assert b['effective_config_sha256']==config_sha
assert b['repository_refresh_allowed'] is False and b['successful_external_network_access_required'] is False
assert b['package_mutation_allowed'] is False and b['boot_mutation_allowed'] is False and b['reboot_allowed'] is False
assert b['persistent_system_configuration_change_allowed'] is False
assert 'unshare-network-namespace' in b['required_capability_observations'] and 'running-crond' in b['required_capability_observations']
a=p['authorization']
assert a['runtime_target_observation_authorized'] is True and a['target_binding_freeze_authorized_after_successful_observation'] is True
for key in ('runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert a[key] is False
assert p['helper_sha256']==helper_sha
assert p['machine_action_required'] is True and p['machine_action_type']=='read-only-target-binding-observation'
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-target-binding-freeze' and p['pause_safe'] is False
INNERPY
then pass 'step-181-r1 policy freezes a repository-independent read-only observation gate'; else fail 'step-181-r1 policy semantic assertions failed'; fi

if grep -Fqx $'target_repository_required\tno' "$RECORD"; then pass 'step-181-r1 record no longer requires a target repository'; else fail 'step-181-r1 record still requires a target repository'; fi
if grep -Fqx $'source_identity_origin\tcontroller-repo-frozen-into-standalone-probe' "$RECORD"; then pass 'step-181-r1 record freezes controller-side source identity origin'; else fail 'step-181-r1 record source identity origin is wrong'; fi
if grep -Fqx $'reference_script_sha256\t'"$reference_sha" "$RECORD"; then pass 'step-181-r1 record freezes reference-script SHA-256'; else fail 'step-181-r1 record reference-script SHA-256 mismatch'; fi
if grep -Fqx $'effective_config_sha256\t'"$config_sha" "$RECORD"; then pass 'step-181-r1 record freezes effective-config SHA-256'; else fail 'step-181-r1 record effective-config SHA-256 mismatch'; fi
if grep -Fqx $'binding_probe_sha256\t'"$probe_sha" "$RECORD"; then pass 'step-181-r1 record freezes standalone probe SHA-256'; else fail 'step-181-r1 record probe SHA-256 mismatch'; fi

regen_dir=$(mktemp -d)
trap 'rm -rf -- "$regen_dir"' EXIT
if "$HELPER" --output-dir "$regen_dir" >/dev/null 2>&1; then pass 'step-181-r1 helper regenerates revised policy and record'; else fail 'step-181-r1 helper regeneration failed'; fi
if cmp -s "$POLICY" "$regen_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json"; then pass 'step-181-r1 helper reproduces the frozen revised policy exactly'; else fail 'step-181-r1 regenerated policy differs'; fi
if cmp -s "$RECORD" "$regen_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv"; then pass 'step-181-r1 helper reproduces the frozen revised record exactly'; else fail 'step-181-r1 regenerated record differs'; fi

if grep -Fq -- '--repo-root' "$PROBE"; then fail 'step-181-r1 standalone probe still exposes --repo-root'; else pass 'step-181-r1 standalone probe has no target-repository option'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$PROBE"; then fail 'step-181-r1 probe contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-181-r1 probe contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$PROBE"; then fail 'step-181-r1 probe contains a network client command'; else pass 'step-181-r1 probe contains no network client command'; fi
if grep -Eq '\b(crontab[[:space:]]+(-e|-r)|crontab[[:space:]]+[^-])\b' "$PROBE"; then fail 'step-181-r1 probe contains a mutating crontab operation'; else pass 'step-181-r1 probe only reads crontab state'; fi
if grep -Fq 'unshare --net -- true' "$PROBE"; then pass 'step-181-r1 probe network-namespace check is bounded to true'; else fail 'step-181-r1 probe network-namespace capability check is not frozen'; fi
if grep -Fq 'Phase 1 step 181-r1 standalone target-binding probe remediation' "$CHANGELOG"; then pass 'CHANGELOG records step 181-r1'; else fail 'CHANGELOG does not record step 181-r1'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'does not need to host the repository'* && $normalized_doc == *'unshare --net'* && $normalized_doc == *'target-repository-required'* && $normalized_doc == *'runtime-target-binding-freeze'* ]]; then pass 'reference document records standalone probe remediation and next binding-freeze gate'; else fail 'step-181-r1 reference document is incomplete'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
