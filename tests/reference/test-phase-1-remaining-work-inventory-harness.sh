#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-remaining-work-inventory.sh"
DOC="$repo_root/docs/reference/phase-1-remaining-work-inventory.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory.tsv"
STEP162_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review-policy.json"
STEP162_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() {
    local file=$1 label=$2
    if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
}
check_hash() {
    local file=$1 expected=$2 label=$3 actual
    if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi
}

for spec in \
    "$HELPER|step-163 inventory helper" \
    "$DOC|step-163 reference document" \
    "$POLICY|step-163 inventory policy" \
    "$RECORD|step-163 inventory record" \
    "$STEP162_POLICY|accepted step-162 boundary policy" \
    "$STEP162_RECORD|accepted step-162 boundary record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '100419b14c72d7a9e71ce0c3f99603b4e7d6ba6d90deeea46658f5b4deec7d22' 'step-163 inventory helper'
check_hash "$DOC" '9b09dcc2276d3b0e766613469ffa1fc823f32fcfcb7bd275961bb5412e845219' 'step-163 reference document'
check_hash "$POLICY" 'fb9ab7db1adad032b29be14a6100fdc6221eefd8de3360374085e8b3d76e4f03' 'step-163 inventory policy'
check_hash "$RECORD" '8a1160121683117fc247cbf35d2943d35b6b219323e8e58a2fb9baed165f8b01' 'step-163 inventory record'
check_hash "$STEP162_POLICY" '47210ad2f1ce84946452c862be172a7e3b803c29772ecf8aae1e693dce4e3ae9' 'accepted step-162 boundary policy'
check_hash "$STEP162_RECORD" '338ca5c43dd79a02b7362c2a4cd661b4333139351902689c7af4d479a4bdf521' 'accepted step-162 boundary record'

if bash -n "$HELPER"; then pass 'step-163 inventory helper is shell-syntax valid'; else fail 'step-163 inventory helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-163 helper exposes a non-mutating help boundary'; else fail 'step-163 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-163 helper accepts unknown options'; else pass 'step-163 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-163 inventory policy is valid JSON'; else fail 'step-163 inventory policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-163 remaining-work inventory completed successfully'; else fail 'step-163 inventory helper failed'; printf '%s\n' "$output"; fi

header=$(head -n 1 "$RECORD")
if [[ $header == $'workstream\tclassification\tstate\tscope\tmachine_execution_required\trepository_refresh_required\tphase_1_blocking\tdisposition' ]]; then pass 'inventory record has the frozen eight-column schema'; else fail 'inventory record schema mismatch'; fi
rows=$(($(wc -l < "$RECORD") - 1))
if [[ $rows -eq 7 ]]; then pass 'inventory contains exactly seven high-level workstreams'; else fail 'inventory row count is not seven'; fi

expect_record() {
    local pattern=$1 label=$2
    if grep -Eq "$pattern" "$RECORD"; then pass "$label"; else fail "$label"; fi
}
expect_record '^roadmap-state-reconciliation[[:space:]]+planning-hygiene[[:space:]]+pending[[:space:]]+repository-only[[:space:]]+false[[:space:]]+false[[:space:]]+false[[:space:]]' 'roadmap reconciliation is pending repository-only work'
expect_record '^reference-comment-language-audit[[:space:]]+repository-review[[:space:]]+pending[[:space:]]+repository-only[[:space:]]+false[[:space:]]+false[[:space:]]+true[[:space:]]' 'English-comment audit remains a blocking repository review'
expect_record '^configuration-schema-compatibility-roadmap[[:space:]]+accepted-evidence-roadmap-stale[[:space:]]+accepted[[:space:]]+repository-only[[:space:]]+false[[:space:]]+false[[:space:]]+false[[:space:]]' 'configuration compatibility is classified as accepted evidence with stale roadmap state'
expect_record '^normal-update-roadmap-stale-items[[:space:]]+accepted-evidence-roadmap-stale[[:space:]]+accepted[[:space:]]+repository-only[[:space:]]+false[[:space:]]+false[[:space:]]+false[[:space:]]' 'historical normal-update roadmap gaps are classified as stale presentation, not rerun requirements'
expect_record '^acceptance-matrix-remainder[[:space:]]+acceptance-work[[:space:]]+pending[[:space:]]+mixed-design-and-runtime[[:space:]]+true[[:space:]]+conditional[[:space:]]+true[[:space:]]' 'acceptance-matrix remainder stays explicit and requires future machine work'
expect_record '^reference-freeze[[:space:]]+phase-gate[[:space:]]+blocked[[:space:]]+repository-only[[:space:]]+false[[:space:]]+false[[:space:]]+true[[:space:]]' 'reference freeze remains blocked behind acceptance work'
expect_record '^c-port-start[[:space:]]+phase-transition[[:space:]]+blocked[[:space:]]+future-phase[[:space:]]+false[[:space:]]+false[[:space:]]+true[[:space:]]' 'C port remains blocked by the Phase 1 gate'

if python3 - "$POLICY" "$STEP162_POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p162 = json.load(handle)
assert p162['fresh_boundary']['opened'] is True
assert p162['fresh_boundary']['scope'] == 'phase-1-resume-planning'
assert p162['next_stage'] == 'phase-1-remaining-work-inventory'
assert p['review_only'] is True
assert p['accepted_boundary']['step'] == 162
assert p['inventory']['row_count'] == 7
assert p['inventory']['accepted_evidence_roadmap_stale_count'] == 2
assert p['inventory']['pending_repository_only_count'] == 2
assert p['inventory']['pending_acceptance_work_count'] == 1
assert p['inventory']['blocked_gate_count'] == 2
assert p['inventory']['contains_machine_work'] is True
assert p['inventory']['machine_work_authorized'] is False
assert p['inventory']['roadmap_reconciliation_required'] is True
assert p['inventory']['c_port_may_start'] is False
for key in (
    'source_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['next_stage'] == 'phase-1-next-workstream-selection-freeze'
assert p['slackware_current_publication_invalidates_inventory'] is False
assert p['pause_safe'] is False
PY
then pass 'inventory policy preserves the planning-only boundary and classifies remaining work coherently'; else fail 'step-163 inventory semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'unfinished engineering work'* && $normalized_doc == *'roadmap state that has not yet caught up'* && $normalized_doc == *'phase-1-next-workstream-selection-freeze'* ]]; then
    pass 'reference document explains the stale-roadmap versus pending-work distinction'
else
    fail 'step-163 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 163 remaining-work inventory' "$CHANGELOG" && grep -Fq 'phase-1-next-workstream-selection-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 163'; else fail 'CHANGELOG does not record step 163'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-163 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-163 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-163 helper contains a network client command'; else pass 'step-163 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
