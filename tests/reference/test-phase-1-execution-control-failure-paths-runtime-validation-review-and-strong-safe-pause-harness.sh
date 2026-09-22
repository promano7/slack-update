#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.sh"
doc="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv"
remaining="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv"
step175_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-policy.json"
step175_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory.tsv"
r187_policy="$acceptance_dir/phase-1-execution-control-failure-paths-network-failure-remediation-policy.json"
r187_record="$acceptance_dir/phase-1-execution-control-failure-paths-network-failure-remediation.tsv"
r187_harness="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-network-failure-remediation-harness.sh"
r187_doc="$repo_root/docs/reference/phase-1-execution-control-failure-paths-network-failure-remediation.md"
step186_harness="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization-harness.sh"
reference_script="$repo_root/tools/reference/slack-update-reference.sh"
executor="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-execution-control-failure-paths.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check_regular() { [[ -f $1 && ! -L $1 ]] && pass "$2" || fail "$2"; }
check_hash() { local file=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$file" 2>/dev/null | awk '{print $1}' || true); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }

check_regular "$helper" 'step-188 review helper is a regular non-symlink file'
check_regular "$doc" 'step-188 reference document is a regular non-symlink file'
check_regular "$policy" 'step-188 strong-safe-pause policy is a regular non-symlink file'
check_regular "$record" 'step-188 closure record is a regular non-symlink file'
check_regular "$remaining" 'step-188 residual inventory is a regular non-symlink file'
check_regular "$r187_policy" 'accepted step-187-r3 remediation policy is a regular non-symlink file'
check_regular "$r187_record" 'accepted step-187-r3 remediation record is a regular non-symlink file'
check_regular "$step175_policy" 'accepted step-175 inventory policy is a regular non-symlink file'
check_regular "$step175_record" 'accepted step-175 inventory record is a regular non-symlink file'

check_hash "$helper" '296617f1e499a74151b68c96d08fb90273a0acbd30b566dcced6cc1a9f504fae' 'step-188 review helper has the exact reviewed SHA-256'
check_hash "$doc" 'a27c459e33061fbbe9171f19c32df1a4ffbdcfd8df4c841be983b0a95c42fa4f' 'step-188 reference document has the exact reviewed SHA-256'
check_hash "$policy" 'b7a78b9dfbb6eeb3c802820a2566deae96f43c5dace3a22a8e88ab513f623d63' 'step-188 policy has the exact reviewed SHA-256'
check_hash "$record" '427e07e26cfc9449c0df3e0bd20cc97dfcc681825e1a073d0d83ea9fd49969fb' 'step-188 record has the exact reviewed SHA-256'
check_hash "$remaining" '8aa3f1dbe177ec336025f4b3983e22b07205d8bf72fb214442704764131094e9' 'step-188 residual inventory has the exact reviewed SHA-256'
check_hash "$step175_policy" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe' 'accepted step-175 inventory policy has the exact reviewed SHA-256'
check_hash "$step175_record" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff' 'accepted step-175 inventory record has the exact reviewed SHA-256'
check_hash "$r187_policy" 'b4f09cafce7b2e6f4fc45b451f010b7ff683be259fab8a3872b3a7c3e3bdb569' 'accepted step-187-r3 remediation policy has the exact reviewed SHA-256'
check_hash "$r187_record" 'efc3f04b821f40b388935870c458b34ca7407aef66af91328e7953ad086caa16' 'accepted step-187-r3 remediation record has the exact reviewed SHA-256'
check_hash "$r187_harness" 'fbd6ca7ce54eb7e5bbf8c3c2ad2c7c5f2a8a8a2ea2666aa088a99f1cf3da460c' 'accepted step-187 remediation harness has the exact reviewed SHA-256'
check_hash "$r187_doc" '4fc23c5eb11268c1b41a3ec2ebb9061d37a4ec7dcdaef1bfc140f35454e0fba5' 'accepted step-187-r3 remediation document has the exact reviewed SHA-256'
check_hash "$step186_harness" '6ff46b710f58769a20a8261ed7d085828516608f135a76223d19bc64a83abc19' 'supersession-aware step-186 harness has the exact reviewed SHA-256'
check_hash "$reference_script" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' 'accepted remediated reference script has the exact reviewed SHA-256'
check_hash "$executor" '262ce8667437ed9de94682ec31773094409e286cd721d4a351963cd59b59fecc' 'accepted runtime executor has the exact reviewed SHA-256'
check_hash "$acceptance_harness" '0ce04751466f0c31cd55f96f8e3d79e41153655c65b14bf54ee42aa80b18268f' 'accepted execution-control acceptance harness has the exact reviewed SHA-256'

if bash -n -- "$helper"; then pass 'step-188 review helper is shell-syntax valid'; else fail 'step-188 review helper is shell-syntax valid'; fi
if bash -- "$helper" --help >/dev/null; then pass 'step-188 helper exposes a non-mutating help boundary'; else fail 'step-188 helper exposes a non-mutating help boundary'; fi
if bash -- "$helper" --definitely-unknown >/dev/null 2>&1; then fail 'step-188 helper rejects unknown options'; else pass 'step-188 helper rejects unknown options'; fi
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-188 policy is valid JSON'; else fail 'step-188 policy is valid JSON'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if bash -- "$helper" --output-dir "$tmp" >/dev/null; then pass 'step-188 closure evidence reproduces successfully'; else fail 'step-188 closure evidence reproduces successfully'; fi
if cmp -s -- "$tmp/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause-policy.json" "$policy"; then pass 'step-188 policy is deterministically reproducible'; else fail 'step-188 policy is deterministically reproducible'; fi
if cmp -s -- "$tmp/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv" "$record"; then pass 'step-188 record is deterministically reproducible'; else fail 'step-188 record is deterministically reproducible'; fi
if cmp -s -- "$tmp/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv" "$remaining"; then pass 'step-188 residual inventory is deterministically reproducible'; else fail 'step-188 residual inventory is deterministically reproducible'; fi

if python3 - "$policy" "$record" "$remaining" "$r187_policy" "$step175_record" <<'PYASSERT'
import csv,json,sys
from pathlib import Path
p_path,r_path,rem_path,p187_path,r175_path=map(Path,sys.argv[1:])
p=json.loads(p_path.read_text())
p187=json.loads(p187_path.read_text())
with r_path.open(newline='',encoding='utf-8') as h: rows=list(csv.reader(h,delimiter='\t'))
values=dict(rows[1:])
with rem_path.open(newline='',encoding='utf-8') as h: rem=list(csv.DictReader(h,delimiter='\t'))
with r175_path.open(newline='',encoding='utf-8') as h: old=list(csv.DictReader(h,delimiter='\t'))
assert p['scenario']=='phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause'
assert p['accepted_runtime_validation']['rerun_status']=='PASS'
assert p['accepted_runtime_validation']['evidence_archive_sha256']=='da2f111515e9b7ddc322ca4403cfa543b5710c1c05b94c6fa7dca2a5c336290d'
assert p['accepted_runtime_validation']['scenario_results']['network_failure']=={'fail_closed': True, 'reference_exit_code': 1, 'status': 'PASS'}
assert p['accepted_runtime_validation']['scenario_results']['simultaneous_execution']['second_exit_code']==6
assert p['accepted_runtime_validation']['scenario_results']['signal_SIGINT']['exit_code']==130
assert p['accepted_runtime_validation']['scenario_results']['signal_SIGTERM']['exit_code']==143
assert p['accepted_runtime_validation']['scenario_results']['signal_SIGHUP']['exit_code']==129
assert p['accepted_runtime_validation']['scenario_results']['cron_without_interactive_terminal']['tty_state']=='absent'
assert all(p['accepted_runtime_validation']['safety_results'].values())
assert p['closed_family']['family']=='execution-control-failure-paths'
assert p['closed_family']['scenario_count']==4
assert p['closed_family']['closure_status']=='accepted'
assert p['remaining_inventory']['family_count']==5
assert p['remaining_inventory']['scenario_count']==20
assert len(rem)==5 and sum(int(x['scenario_count']) for x in rem)==20
assert 'execution-control-failure-paths' not in {x['family'] for x in rem}
assert {x['family'] for x in rem} == {x['family'] for x in old} - {'execution-control-failure-paths'}
assert p187['authorization']['runtime_scenario_execution_authorized'] is True
assert p['authorization']['runtime_scenario_execution_authorized'] is False
for key in ('source_change_authorized','documentation_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['authorization']['future_work_requires_fresh_boundary'] is True
assert p['safe_pause']['pause_safe'] is True
assert p['safe_pause']['strong_safe_pause'] is True
assert p['safe_pause']['machine_action_required'] is False
assert p['safe_pause']['no_open_operational_authorization'] is True
assert p['safe_pause']['slackware_current_publication_invalidates_checkpoint'] is False
assert p['continuation']['no_runtime_family_preselected'] is True
assert p['gates']['acceptance_matrix_complete'] is False
assert p['next_stage']=='phase-1-acceptance-matrix-remainder-resume-planning'
assert values['closed_family']=='execution-control-failure-paths'
assert values['runtime_validation_status']=='PASS'
assert values['remaining_inventory_family_count']=='5'
assert values['remaining_inventory_scenario_count']=='20'
assert values['family_selected_for_execution']=='no'
assert values['live_runtime_chain_open']=='no'
assert values['runtime_scenario_execution_authorized']=='no'
assert values['pause_safe']=='yes' and values['strong_safe_pause']=='yes'
assert values['next_stage']=='phase-1-acceptance-matrix-remainder-resume-planning'
PYASSERT
then pass 'step-188 semantics close execution-control, revoke runtime authority, and preserve the remaining Phase 1 gates'; else fail 'step-188 semantic assertions failed'; fi

if grep -Fq '## Phase 1 step 188 execution-control runtime validation review and strong safe pause' "$changelog"; then pass 'CHANGELOG records step 188'; else fail 'CHANGELOG records step 188'; fi
if grep -Fq 'A successful step 188 is a strong safe pause.' "$doc" && grep -Fq 'five families / 20 scenarios' "$doc" && grep -Fq 'no runtime family preselected' "$doc"; then pass 'reference document records closure, residual inventory, and strong safe pause'; else fail 'reference document misses closure or strong-safe-pause assertions'; fi

if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([;&|[:space:]]|$)' "$helper"; then fail 'step-188 helper contains forbidden package/boot mutation command'; else pass 'step-188 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|git[[:space:]]+(fetch|pull|clone)|rsync[[:space:]].*::|scp|ssh)([;&|[:space:]]|$)' "$helper"; then fail 'step-188 helper contains forbidden network client command'; else pass 'step-188 helper contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
