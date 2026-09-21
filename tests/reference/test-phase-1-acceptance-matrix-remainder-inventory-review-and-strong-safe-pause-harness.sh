#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.sh"
doc="$repo_root/docs/reference/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.md"
policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause-policy.json"
record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv"
step175_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-policy.json"
step175_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory.tsv"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check_regular() { [[ -f $1 && ! -L $1 ]] && pass "$2" || fail "$2"; }
check_hash() {
    local file=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$file" 2>/dev/null | awk '{print $1}' || true)
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}

check_regular "$helper" 'step-176 review helper is a regular non-symlink file'
check_regular "$doc" 'step-176 reference document is a regular non-symlink file'
check_regular "$policy" 'step-176 review policy is a regular non-symlink file'
check_regular "$record" 'step-176 review record is a regular non-symlink file'
check_regular "$step175_policy" 'accepted step-175 inventory policy is a regular non-symlink file'
check_regular "$step175_record" 'accepted step-175 inventory record is a regular non-symlink file'

check_hash "$helper" 'ce9d2058788e7743d62d63114a6531b9238cbc142cb3d6994fd4c4ae6264bc7b' 'step-176 review helper has the exact reviewed SHA-256'
check_hash "$doc" '809350e1ca24598011bff7a319f0e5064fb9d7cb4eef7c08ed6694b23fac6fe4' 'step-176 reference document has the exact reviewed SHA-256'
check_hash "$policy" '86eaf01a35bfee7bae0450d669b06a3d1aa3f6f7e8d47776a09f036d62ff6ea6' 'step-176 review policy has the exact reviewed SHA-256'
check_hash "$record" 'eff7de99e6a31e47cd09fff61aa26d600f34f09cffedce5cabafb0736be6c389' 'step-176 review record has the exact reviewed SHA-256'
check_hash "$step175_policy" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe' 'accepted step-175 inventory policy has the exact reviewed SHA-256'
check_hash "$step175_record" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff' 'accepted step-175 inventory record has the exact reviewed SHA-256'

if bash -n -- "$helper"; then pass 'step-176 review helper is shell-syntax valid'; else fail 'step-176 review helper is shell-syntax valid'; fi
if bash -- "$helper" --help >/dev/null; then pass 'step-176 helper exposes a non-mutating help boundary'; else fail 'step-176 helper exposes a non-mutating help boundary'; fi
if bash -- "$helper" --definitely-unknown >/dev/null 2>&1; then fail 'step-176 helper rejects unknown options'; else pass 'step-176 helper rejects unknown options'; fi
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-176 review policy is valid JSON'; else fail 'step-176 review policy is valid JSON'; fi

# Reproduce the review evidence independently and compare byte-for-byte.
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if bash -- "$helper" --output-dir "$tmp" >/dev/null; then
    pass 'step-176 inventory review reproduces successfully'
else
    fail 'step-176 inventory review reproduces successfully'
fi
if cmp -s -- "$tmp/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause-policy.json" "$policy"; then
    pass 'accepted step-176 review policy is deterministically reproducible'
else
    fail 'accepted step-176 review policy is deterministically reproducible'
fi
if cmp -s -- "$tmp/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv" "$record"; then
    pass 'accepted step-176 review record is deterministically reproducible'
else
    fail 'accepted step-176 review record is deterministically reproducible'
fi

if python3 - "$policy" "$record" "$step175_policy" "$step175_record" <<'PY'
import csv
import hashlib
import json
import sys
from pathlib import Path

policy_path, record_path, p175_path, r175_path = map(Path, sys.argv[1:])
p = json.loads(policy_path.read_text(encoding='utf-8'))
p175 = json.loads(p175_path.read_text(encoding='utf-8'))
with record_path.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.reader(handle, delimiter='\t'))

assert p['schema'] == 1
assert p['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause'
assert p['review_only'] is True
assert p['accepted_inventory']['step'] == 175
assert p['accepted_inventory']['policy_sha256'] == hashlib.sha256(p175_path.read_bytes()).hexdigest()
assert p['accepted_inventory']['record_sha256'] == hashlib.sha256(r175_path.read_bytes()).hexdigest()
assert p175['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert p175['inventory']['family_count'] == 6
assert p175['inventory']['scenario_count'] == 24
assert p175['safe_pause']['strong_safe_pause'] is False
assert p175['next_stage'] == 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause'
review = p['review']
assert review['inventory_family_count'] == 6
assert review['inventory_scenario_count'] == 24
assert review['inventory_consistent'] is True
assert review['roadmap_reconciliation_closed'] is True
assert review['accepted_core_scenarios_must_not_be_replayed'] is True
assert review['accepted_core_coverage_count'] == 5
assert review['remaining_work_requires_fresh_scenario_boundary'] is True
assert review['candidate_set_bound'] is False
assert review['family_selected_for_execution'] is False
assert review['live_runtime_chain_open'] is False
assert review['acceptance_matrix_complete'] is False
assert review['reference_freeze_status'] == 'blocked-behind-remaining-acceptance-work'
assert review['c_port_status'] == 'blocked-by-phase-1-gate'
for key in (
    'source_change_authorized',
    'documentation_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['authorization']['future_work_requires_fresh_boundary'] is True
safe = p['safe_pause']
assert safe['pause_safe'] is True
assert safe['strong_safe_pause'] is True
assert safe['machine_action_required'] is False
assert safe['no_open_operational_authorization'] is True
assert safe['slackware_current_publication_invalidates_checkpoint'] is False
assert safe['accepted_inventory_remains_valid_across_publication'] is True
cont = p['continuation']
assert cont['next_family_selection_required'] is True
assert cont['selection_must_occur_after_fresh_boundary'] is True
assert cont['repository_refresh_must_be_justified_by_selected_scenario'] is True
assert cont['no_runtime_family_preselected'] is True
assert p['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
assert rows[0] == ['check', 'value']
values = dict(rows[1:])
assert len(values) == 25
assert values['accepted_inventory_step'] == '175'
assert values['inventory_family_count'] == '6'
assert values['inventory_scenario_count'] == '24'
assert values['family_selected_for_execution'] == 'no'
assert values['live_runtime_chain_open'] == 'no'
assert values['acceptance_matrix_complete'] == 'no'
assert values['pause_safe'] == 'yes'
assert values['strong_safe_pause'] == 'yes'
assert values['machine_action_required'] == 'no'
assert values['no_open_operational_authorization'] == 'yes'
assert values['future_work_requires_fresh_boundary'] == 'yes'
assert values['no_runtime_family_preselected'] == 'yes'
assert values['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
PY
then
    pass 'step-176 review binds the accepted inventory, preserves all gates, and establishes a strong safe pause'
else
    fail 'step-176 review semantic assertions failed'
fi

if grep -Fq '## Phase 1 step 176 acceptance-matrix remainder inventory review and strong safe pause' "$changelog"; then
    pass 'CHANGELOG records step 176'
else
    fail 'CHANGELOG records step 176'
fi
if grep -Fq 'A successful step 176 is a strong safe pause.' "$doc" && grep -Fq 'no runtime family preselected' "$doc"; then
    pass 'reference document records the strong safe pause and unselected runtime remainder'
else
    fail 'reference document does not record the expected strong-safe-pause boundary'
fi

if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([;&|[:space:]]|$)' "$helper"; then
    fail 'step-176 helper contains no package, boot, reboot, or shutdown mutation command'
else
    pass 'step-176 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|git[[:space:]]+(fetch|pull|clone)|rsync[[:space:]].*::|scp|ssh)([;&|[:space:]]|$)' "$helper"; then
    fail 'step-176 helper contains no network client command'
else
    pass 'step-176 helper contains no network client command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
