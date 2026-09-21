#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-inventory.sh"
DOC="$repo_root/docs/reference/phase-1-acceptance-matrix-remainder-inventory.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory.tsv"
STEP174_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-review-policy.json"
STEP174_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-review.tsv"
STEP163_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory-policy.json"
STEP163_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"
check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }
for spec in "$HELPER|step-175 inventory helper" "$DOC|step-175 reference document" "$POLICY|step-175 inventory policy" "$RECORD|step-175 inventory record" "$STEP174_POLICY|accepted step-174 review policy" "$STEP174_RECORD|accepted step-174 review record" "$STEP163_POLICY|accepted step-163 inventory policy" "$STEP163_RECORD|accepted step-163 inventory record"; do check_regular "${spec%%|*}" "${spec#*|}"; done
check_hash "$HELPER" '52d1bc395003a70a874ab6a40161c7927e03758b3bd0032a2018f348580d818f' 'step-175 inventory helper'
check_hash "$DOC" '97d24ee5109fc8d9582c833891b2b218cae53ed2aead812e2a0e1c8fd11fe07a' 'step-175 reference document'
check_hash "$POLICY" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe' 'step-175 inventory policy'
check_hash "$RECORD" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff' 'step-175 inventory record'
check_hash "$STEP174_POLICY" '63da904c6c3b97acba8d648c0f586780ff460885755d5fa31371b055e853e119' 'accepted step-174 review policy'
check_hash "$STEP174_RECORD" 'ab250e343bf2c1968f6a6c27021b50d2aaf598a2fb791b6f0c10ecfbd81a3861' 'accepted step-174 review record'
check_hash "$STEP163_POLICY" 'fb9ab7db1adad032b29be14a6100fdc6221eefd8de3360374085e8b3d76e4f03' 'accepted step-163 inventory policy'
check_hash "$STEP163_RECORD" '8a1160121683117fc247cbf35d2943d35b6b219323e8e58a2fb9baed165f8b01' 'accepted step-163 inventory record'
if bash -n "$HELPER"; then pass 'step-175 inventory helper is shell-syntax valid'; else fail 'step-175 inventory helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-175 helper exposes a non-mutating help boundary'; else fail 'step-175 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-175 helper accepts unknown options'; else pass 'step-175 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-175 inventory policy is valid JSON'; else fail 'step-175 inventory policy is invalid JSON'; fi
output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-175 acceptance-matrix remainder inventory completed successfully'; else fail 'step-175 inventory helper failed'; printf '%s\n' "$output"; fi
expect_row() { local prefix=$1 label=$2; if grep -Fq "$prefix" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_row $'kernel-package-edge\t1\t' 'kernel-package edge family contains one scenario'
expect_row $'boot-safety-failure-paths\t7\t' 'boot-safety failure family contains seven scenarios'
expect_row $'sbo-elf-optional-runtime\t6\t' 'SBo/ELF family contains six scenarios'
expect_row $'cinnamon-optional-runtime\t3\t' 'Cinnamon family contains three scenarios'
expect_row $'flatpak-optional-runtime\t3\t' 'Flatpak family contains three scenarios'
expect_row $'execution-control-failure-paths\t4\t' 'execution-control family contains four scenarios'
if python3 - "$POLICY" "$RECORD" "$STEP174_POLICY" "$STEP163_POLICY" <<'PYCHECK'
import csv, json, sys
from pathlib import Path
p = json.load(open(sys.argv[1], encoding='utf-8'))
with open(sys.argv[2], encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
p174 = json.load(open(sys.argv[3], encoding='utf-8'))
p163 = json.load(open(sys.argv[4], encoding='utf-8'))
assert p['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert p['review_only'] is True
assert p['accepted_roadmap_review']['step'] == 174
assert p['accepted_prior_inventory']['step'] == 163
assert p174['review']['roadmap_reconciliation_closed'] is True
assert p174['review']['acceptance_matrix_complete'] is False
assert p163['inventory']['pending_acceptance_work_count'] == 1
assert p163['inventory']['machine_work_authorized'] is False
inv = p['inventory']
assert inv['family_count'] == 6 and inv['scenario_count'] == 24
assert inv['classification'] == 'pending-real-system-acceptance-remainder'
assert inv['contains_machine_work'] is True
assert inv['machine_work_authorized'] is False
assert inv['candidate_set_bound'] is False
assert inv['repository_refresh_required_now'] is False
assert inv['roadmap_reconciliation_closed'] is True
assert inv['accepted_core_scenarios_must_not_be_replayed'] is True
assert len(inv['accepted_core_coverage']) == 5
expected_counts = {
    'kernel-package-edge': 1,
    'boot-safety-failure-paths': 7,
    'sbo-elf-optional-runtime': 6,
    'cinnamon-optional-runtime': 3,
    'flatpak-optional-runtime': 3,
    'execution-control-failure-paths': 4,
}
assert {row['family']: int(row['scenario_count']) for row in rows} == expected_counts
assert sum(expected_counts.values()) == 24
assert all(row['runtime_boundary_required'] == 'true' for row in rows)
assert all(row['repository_refresh_requirement'] == 'conditional' for row in rows)
assert p['gates']['acceptance_matrix_complete'] is False
assert p['gates']['reference_freeze_status'] == 'blocked-behind-remaining-acceptance-work'
assert p['gates']['c_port_status'] == 'blocked-by-phase-1-gate'
for key in ('source_change_authorized','documentation_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['authorization']['future_work_requires_fresh_boundary'] is True
assert p['safe_pause']['pause_safe'] is False
assert p['safe_pause']['strong_safe_pause'] is False
assert p['safe_pause']['machine_action_required'] is False
assert p['safe_pause']['slackware_current_publication_invalidates_inventory'] is False
assert p['next_stage'] == 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause'
PYCHECK
then pass 'inventory policy freezes 24 scenarios in six families and preserves all Phase 1 gates'; else fail 'step-175 inventory semantic assertions failed'; fi
if grep -Fq 'Phase 1 step 175 acceptance-matrix remainder inventory' "$CHANGELOG" && grep -Fq 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause' "$CHANGELOG"; then pass 'CHANGELOG records step 175'; else fail 'CHANGELOG does not record step 175'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-175 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-175 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-175 helper contains a network client command'; else pass 'step-175 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
