#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review'
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.tsv"
v3="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
v4="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
changelog="$repo_root/CHANGELOG.md"
passes=0
failures=0

good() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
bad() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check() { local msg=$1; shift; if "$@"; then good "$msg"; else bad "$msg"; fi; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
expect_hash() { [[ $(sha "$1") == "$2" ]]; }

for spec in \
  "step-264 helper|$helper" \
  "step-264 document|$doc" \
  "step-264 policy|$policy" \
  "step-264 record|$record" \
  "accepted step-263 helper|$prev_helper" \
  "accepted step-263 document|$prev_doc" \
  "accepted step-263 harness|$prev_harness" \
  "accepted step-263 policy|$prev_policy" \
  "accepted step-263 record|$prev_record" \
  "accepted v3 builder|$v3" \
  "frozen v4 builder|$v4" \
  "CHANGELOG|$changelog"; do
    label=${spec%%|*}; path=${spec#*|}
    check "$label exists as regular file" regular "$path"
done

check 'accepted step-263 helper SHA-256 matches' expect_hash "$prev_helper" '546cc2c6bcb50ea64dfcde09d9facdd997dc6f1c615e04c07d944596d2557445'
check 'accepted step-263 document SHA-256 matches' expect_hash "$prev_doc" 'df86e5f3e7002dd6fbffd53951d15242c917ad0514c5122e38597b7f7dd9c72b'
check 'accepted step-263 harness SHA-256 matches' expect_hash "$prev_harness" '09e8242d0ec4a457cce3df528e73a92419d4c6f663d2127d4ff25521a1cfc5b2'
check 'accepted step-263 policy SHA-256 matches' expect_hash "$prev_policy" '2d43ad83fbdd51dfcadcb9dc0b2f61403ab4ab883c18108c02b0e2595efe1dc7'
check 'accepted step-263 record SHA-256 matches' expect_hash "$prev_record" '42289765f73553f2d8ffac31c1d04dbe3208045c5e2e8a3375260b227e0eee28'
check 'accepted v3 builder SHA-256 remains frozen' expect_hash "$v3" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
check 'v4 builder SHA-256 is frozen' expect_hash "$v4" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
check 'step-264 helper SHA-256 matches policy-bound identity' expect_hash "$helper" 'a2a95740b9d1837a6d0ef7ad5510199868b5ae07087ef692c55375f46af0beb7'

check 'v4 builder passes bash syntax validation' bash -n "$v4"
check 'step-264 helper passes bash syntax validation' bash -n "$helper"
check 'step-264 harness passes bash syntax validation' bash -n "${BASH_SOURCE[0]}"
check 'step-264 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
check 'step-264 helper rejects unknown option' bash -c '! "$1" --unknown >/dev/null 2>&1' _ "$helper"
check 'v4 builder still exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$v4"

prev_out=$(mktemp)
out_dir=$(mktemp -d)
trap 'rm -f -- "$prev_out"; rm -rf -- "$out_dir"' EXIT HUP INT TERM
if "$prev_harness" >"$prev_out" 2>&1 && grep -Fxq 'Result: PASS (77 passes, 0 failures)' "$prev_out"; then
    good 'complete accepted step-263 repository acceptance reruns PASS'
else
    cat "$prev_out" >&2
    bad 'complete accepted step-263 repository acceptance reruns PASS'
fi

if "$helper" --output-dir "$out_dir" >/dev/null; then good 'step-264 helper executes successfully'; else bad 'step-264 helper executes successfully'; fi
check 'helper reproduces frozen policy exactly' cmp -s "$out_dir/${base}-policy.json" "$policy"
check 'helper reproduces frozen record exactly' cmp -s "$out_dir/${base}.tsv" "$record"

check 'policy semantic assertions pass' python3 - "$policy" <<'PYCHK'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==264 and p['review_status']=='PASS'
assert p['frozen_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert p['frozen_v4_builder']['state']=='implementation-frozen-not-executed'
assert p['frozen_v4_builder']['production_execution_performed'] is False
assert p['implementation_freeze']['reviewed_builder_identity_frozen'] is True
assert p['implementation_freeze']['v3_baseline_identity_reproved'] is True
assert p['implementation_freeze']['tagged_writer_forbidden'] is True
assert len(p['implementation_freeze']['synthetic_gate_set_frozen'])==6
assert p['fresh_revalidation_gate']['target_machine_read_only_revalidation_required'] is True
assert p['fresh_revalidation_gate']['must_prove_v4_output_paths_absent'] is True
assert p['fresh_revalidation_gate']['must_not_execute_v4_builder'] is True
assert p['authorization']['fresh_target_and_v4_output_absence_revalidation_authorized'] is True
assert p['authorization']['local_source_v4_builder_execution_authorized'] is False
assert p['authorization']['local_source_v4_build_authorized'] is False
assert p['authorization']['slackpkg_mutation_authorized'] is False
assert p['authorization']['network_access_authorized'] is False
assert p['machine_action_required'] is True
assert p['machine_action_class']=='read-only-target-and-output-absence-revalidation'
assert p['strong_safe_pause'] is False
assert p['next_stage'].endswith('local-source-v4-fresh-target-and-output-absence-revalidation')
PYCHK

check 'TSV freezes v4 builder SHA-256' grep -Fxq $'frozen_v4_builder_sha256\t38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' "$record"
check 'TSV records implementation frozen not executed' grep -Fxq $'builder_implementation_state\timplementation-frozen-not-executed' "$record"
check 'TSV keeps v4 builder execution closed' grep -Fxq $'v4_builder_execution_authorized\tno' "$record"
check 'TSV keeps v4 build closed' grep -Fxq $'v4_build_authorized\tno' "$record"
check 'TSV opens read-only fresh revalidation' grep -Fxq $'fresh_target_and_v4_output_absence_revalidation_authorized\tyes' "$record"
check 'TSV names machine action class' grep -Fxq $'machine_action_class\tread-only-target-and-output-absence-revalidation' "$record"
check 'TSV names next stage' grep -Fxq $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation' "$record"

check 'document records exact frozen v4 builder SHA-256' grep -Fq '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' "$doc"
check 'document records implementation-frozen-not-executed state' grep -Fq 'implementation-frozen-not-executed' "$doc"
check 'document requires step-263 77-pass acceptance rerun' grep -Fq 'Result: PASS (77 passes, 0 failures)' "$doc"
check 'document opens only read-only target-machine revalidation next' grep -Fq 'fresh read-only target-machine revalidation' "$doc"
check 'document keeps production builder execution closed' grep -Fq 'No production `local-source-v4` builder execution is performed' "$doc"
check 'CHANGELOG records step 264' grep -Fq 'Phase 1 step 264' "$changelog"

for f in "$helper" "$doc" "$policy" "$record"; do
    name=${f##*/}
    check "$name contains no trailing whitespace" bash -c '! grep -nE "[[:blank:]]+$" "$1" >/dev/null' _ "$f"
done
check 'step-264 helper contains no executable network package boot reboot or shutdown command' bash -c '! grep -nE "^[[:space:]]*(curl|wget|slackpkg|installpkg|upgradepkg|removepkg|reboot|shutdown|poweroff)([[:space:]]|$)" "$1" >/dev/null' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
