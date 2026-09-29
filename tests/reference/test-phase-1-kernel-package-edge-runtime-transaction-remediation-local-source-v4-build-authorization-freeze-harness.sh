#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.sh"; executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh"; doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.tsv"; builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.sh"; prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.md"; prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.tsv"
passes=0; failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file() { [[ -f $1 && ! -L $1 ]] && pass "$2 exists as regular file" || fail "$2 exists as regular file"; }
check_hash() { local got; got=$(sha256sum -- "$1" | awk '{print $1}'); [[ $got == "$2" ]] && pass "$3 SHA-256 matches" || fail "$3 SHA-256 matches ($got)"; }
check_file "$helper" 'step-267 helper'; check_file "$executor" 'step-267 executor'; check_file "$doc" 'step-267 document'; check_file "$policy" 'step-267 policy'; check_file "$record" 'step-267 record'
check_hash "$prev_helper" '6b16ee9a7e904b173849486ba4119842e1fcc73ae41508286b039c8016a58171' 'accepted step-266 helper'; check_hash "$prev_doc" '3ce7f916d39efe4b3e80ac8648015f74bab61dda43f4c78d0ec72ff757311535' 'accepted step-266 document'; check_hash "$prev_harness" 'ca0c690ce437428c4a0f803f9e2c94b03a19e40e141318a6c0ef7341eac06f9a' 'accepted step-266 harness'; check_hash "$prev_policy" 'fd6ce003f5b46451a94319b3949d7354396934b937068dd0b1a871c942f197a3' 'accepted step-266 policy'; check_hash "$prev_record" 'd0bf5b8e88aaf8dab683ccff439d356071a222b184f85050509e54393b674a87' 'accepted step-266 record'
check_hash "$builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen v4 builder'
check_hash "$executor" 'f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985' 'frozen single-use executor'; check_hash "$helper" '19e18b03a3ede501479dd6feda45f9abba9ee5b4ac78a51a2f04f185de47e709' 'step-267 helper'; check_hash "$doc" '52403327b577b910c13c47ce1a36631b92c70e6085ef59cf44847719d6cb6044' 'step-267 document'; check_hash "$policy" '8dd97f9e4593c6ecb2081f342c9f0a0af308650eac58abf375c92880a2e1f405' 'step-267 policy'; check_hash "$record" '5cb4fa2687c238cf88d15539b337da771da06555d2eaba8ea889302132f7c2f1' 'step-267 record'
bash -n "$executor" && pass 'step-267 executor passes bash syntax validation' || fail 'step-267 executor passes bash syntax validation'
bash -n "$helper" && pass 'step-267 helper passes bash syntax validation' || fail 'step-267 helper passes bash syntax validation'
bash -n "${BASH_SOURCE[0]}" && pass 'step-267 harness passes bash syntax validation' || fail 'step-267 harness passes bash syntax validation'
"$executor" --help >/dev/null && pass 'step-267 executor exposes non-mutating help' || fail 'step-267 executor exposes non-mutating help'
"$helper" --help >/dev/null && pass 'step-267 helper exposes non-mutating help' || fail 'step-267 helper exposes non-mutating help'
if "$executor" --unknown >/dev/null 2>&1; then fail 'step-267 executor rejects unknown option'; else pass 'step-267 executor rejects unknown option'; fi
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-267 helper rejects unknown option'; else pass 'step-267 helper rejects unknown option'; fi
work=$(mktemp -d); trap 'rm -rf -- "$work"' EXIT
"$helper" --output-dir "$work" >/dev/null && pass 'step-267 helper executes successfully' || fail 'step-267 helper executes successfully'
cmp -s "$work/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$work/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
python3 - "$policy" "$record" <<'PYCHECK'
import json,pathlib,sys
p=json.load(open(sys.argv[1],encoding='utf-8')); r={}
for line in pathlib.Path(sys.argv[2]).read_text(encoding='utf-8').splitlines():
    if line: k,v=line.split('	',1); r[k]=v
assert p['step']==267 and p['review_status']=='PASS' and p['review_only'] is False
assert p['single_build_authorization']['state']=='frozen-and-authorized'
assert p['single_build_authorization']['authorization_use_count']==1
assert p['single_build_authorization']['authorization_bound_boot_id']=='d34855ae-e039-4005-a842-1bef51082195'
assert p['single_build_authorization']['builder_and_executor_transport_authorized'] is True
assert p['single_build_authorization']['builder_execution_authorized'] is True
assert p['single_build_authorization']['local_source_v4_build_authorized'] is True
assert p['single_build_authorization']['executor_must_revalidate_full_boundary_immediately_before_build'] is True
assert p['single_build_authorization']['no_second_execution_authorized'] is True
assert p['single_build_authorization']['rerun_after_failure_authorized'] is False
for k in ('slackpkg_refresh_allowed','repository_refresh_allowed','network_access_allowed','package_mutation_allowed','persistent_configuration_change_allowed','boot_mutation_allowed','reboot_allowed','evidence_cleanup_allowed'): assert p['single_build_authorization'][k] is False
assert p['authorization']['local_source_v4_builder_execution_authorized'] is True and p['authorization']['local_source_v4_build_authorized'] is True
assert p['machine_action_required'] is True and p['controller_action_required'] is True
assert p['strong_safe_pause'] is False
assert r['single_build_authorization_state']=='frozen-and-authorized' and r['authorization_use_count']=='1'
assert r['second_execution_authorized']=='no' and r['rerun_after_failure_authorized']=='no'
PYCHECK
[[ $? -eq 0 ]] && pass 'step-267 policy semantic assertions pass' || fail 'step-267 policy semantic assertions pass'
grep -Fq "EXPECTED_BOOT_ID='d34855ae-e039-4005-a842-1bef51082195'" "$executor" && pass 'executor binds exact fresh boot ID' || fail 'executor binds exact fresh boot ID'
grep -Fq "EXPECTED_V4_BUILDER_SHA256='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'" "$executor" && pass 'executor binds exact v4 builder identity' || fail 'executor binds exact v4 builder identity'
grep -Fq 'verify_local_source_v3' "$executor" && pass 'executor revalidates accepted v3 source' || fail 'executor revalidates accepted v3 source'
grep -Fq 'verify_failed_v2_evidence' "$executor" && pass 'executor revalidates preserved v2 evidence' || fail 'executor revalidates preserved v2 evidence'
grep -Fq 'verify_v4_outputs_absent' "$executor" && pass 'executor revalidates v4 output absence' || fail 'executor revalidates v4 output absence'
grep -Fq '"$builder" --build-local-source-v4' "$executor" && pass 'executor invokes only frozen v4 builder acknowledgement' || fail 'executor invokes only frozen v4 builder acknowledgement'
grep -Fq "printf 'authorization_consumed\\tyes\\n'" "$executor" && pass 'executor reports consumed authorization after success' || fail 'executor reports consumed authorization after success'
grep -Fq 'There is no authorized second execution.' "$doc" && pass 'document forbids second execution' || fail 'document forbids second execution'
grep -Fq 'do not rerun it' "$doc" && pass 'document forbids rerun after failure' || fail 'document forbids rerun after failure'
for f in "$helper" "$executor" "$doc" "$policy" "$record"; do if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "${f##*/} contains no trailing whitespace"; else pass "${f##*/} contains no trailing whitespace"; fi; done
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)([[:space:]]|$)|^[[:space:]]*(sudo[[:space:]]+)?git[[:space:]]+(pull|fetch)([[:space:]]|$)' "$executor"; then fail 'executor contains no Slackpkg package network boot reboot or repository-refresh command'; else pass 'executor contains no Slackpkg package network boot reboot or repository-refresh command'; fi
grep -Fq '## Phase 1 step 267' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 267' || fail 'CHANGELOG records step 267'
if (( failures )); then printf 'Result: FAIL (%d passes, %d failures)\n' "$passes" "$failures"; exit 1; fi
printf 'Result: PASS (%d passes, 0 failures)\n' "$passes"
