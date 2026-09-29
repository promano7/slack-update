#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.tsv"
v3_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
v2_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert() { local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }

assert 'step-259 helper exists as regular file' regular "$helper"
assert 'step-259 document exists as regular file' regular "$doc"
assert 'step-259 policy exists as regular file' regular "$policy"
assert 'step-259 record exists as regular file' regular "$record"
assert 'accepted step-258 helper exists as regular file' regular "$prior_helper"
assert 'accepted step-258 document exists as regular file' regular "$prior_doc"
assert 'accepted step-258 harness exists as regular file' regular "$prior_harness"
assert 'accepted step-258 policy exists as regular file' regular "$prior_policy"
assert 'accepted step-258 record exists as regular file' regular "$prior_record"
assert 'accepted v3 builder exists as regular file' regular "$v3_builder"
assert 'executor-v2 body exists as regular file' regular "$v2_body"
assert 'CHANGELOG exists as regular file' regular "$changelog"

assert 'accepted step-258 helper SHA-256 matches' sha_is "$prior_helper" 'f112bc1131db22a21d5561a15fd05cb2c9094389e9b27512861df4b3c53396a2'
assert 'accepted step-258 document SHA-256 matches' sha_is "$prior_doc" 'eafe9afb4da73466181bff7e00e58c8416ec9db24c0089cdc1c46d2a113654b1'
assert 'accepted step-258 harness SHA-256 matches' sha_is "$prior_harness" 'f2b597c5ffdcd34376a70ab50470316b349aa97e2432119266e36d2df103f323'
assert 'accepted step-258 policy SHA-256 matches' sha_is "$prior_policy" '0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc'
assert 'accepted step-258 record SHA-256 matches' sha_is "$prior_record" '20023a8057f7eea1260c22caa8b8dc52e9025f1cc2ff79af94962ca7d4c95bc5'
assert 'accepted v3 builder SHA-256 remains frozen' sha_is "$v3_builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'executor-v2 body SHA-256 remains frozen' sha_is "$v2_body" 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'
assert 'step-259 helper SHA-256 matches' sha_is "$helper" '5fd8be4fcfae7ef061c3c038000ffccec54a85377717175f98befaadf6985ffc'
assert 'step-259 document SHA-256 matches' sha_is "$doc" 'd6de802c3ff0425bbb0a9dd0e83ea1f264f0a529a97c1051d41b9d3e2e2bb6a6'
assert 'step-259 policy SHA-256 matches' sha_is "$policy" '0d93cd3f3ea7ca79995fb1eea2d71d96159dea33a6308144311f63580ad51395'
assert 'step-259 record SHA-256 matches' sha_is "$record" '8fd908b7fedbc61ea5ded315fd11afa9946fe7a2214a86d78971ee408433a3e1'

assert 'step-259 helper passes bash syntax validation' bash -n "$helper"
assert 'step-259 harness passes bash syntax validation' bash -n "${BASH_SOURCE[0]}"
assert 'step-259 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail 'step-259 helper rejects unknown option'; else pass 'step-259 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp/generated" > "$tmp/helper.out" 2> "$tmp/helper.err"; then pass 'step-259 helper executes successfully'; else cat "$tmp/helper.err" >&2; fail 'step-259 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/generated/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/generated/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.tsv"
assert 'helper reports PASS root-cause review' grep -Fqx $'root_cause_review_status\tPASS' "$tmp/helper.out"
assert 'helper freezes root cause' grep -Fqx $'root_cause_status\tFROZEN' "$tmp/helper.out"
assert 'helper identifies tagged checksum incompatibility' grep -Fqx $'root_cause_class\tslackpkg-incompatible-tagged-checksums-md5-package-line-format' "$tmp/helper.out"
assert 'helper explains observed empty pkglist exactly' grep -Fqx $'observed_empty_pkglist_explained_exactly\tyes' "$tmp/helper.out"
assert 'helper selects local-source-v4 remediation' grep -Fqx $'remediation_source_revision\tlocal-source-v4' "$tmp/helper.out"
assert 'helper keeps runtime rerun closed' grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/helper.out"

python3 - "$policy" "$record" > "$tmp/semantic.out" <<'PY'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as f:
    r=dict(csv.reader(f,delimiter='\t'))
root=p['root_cause']; src=p['local_source_v3_checksum_behavior']; rem=p['remediation_direction']; auth=p['authorization']; contract=p['slackpkg_package_list_contract']
checks={
'policy identifies step-259 scenario': p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review' and p['step']==259,
'review status is PASS': p['review_status']=='PASS' and r['review_status']=='PASS',
'step-258 strong safe pause is the accepted input': p['accepted_step_258']['strong_safe_pause_consumed_for_repository_review_only'] is True,
'v3 builder identity is frozen': p['frozen_inputs']['local_source_v3_builder_sha256']=='80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30',
'failed pkglist identity is frozen': p['frozen_inputs']['failed_v2_pkglist_sha256']=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
'Slackpkg package-list source is CHECKSUMS.md5': contract['package_list_source']=='CHECKSUMS.md5',
'terminal package-extension filtering is frozen': contract['package_line_terminal_extension_filter']==r'\.t[blxg]z$',
'pkglist parser consumes final field as path': contract['pkglist_parser_path_field']=='last whitespace-delimited field',
'v3 writer uses GNU tagged MD5': src['writer']=='md5sum --tag -- "$rel"' and src['format']=='GNU tagged MD5',
'tagged package line does not end in extension': src['line_ends_with_package_extension'] is False and r['v3_package_line_ends_with_extension']=='no',
'tagged package line final field is not path': src['last_field_is_package_path'] is False and src['last_field_is_digest'] is True,
'tagged package line does not pass Slackpkg filter': src['passes_slackpkg_package_line_filter'] is False and r['v3_package_line_passes_slackpkg_filter']=='no',
'root cause is frozen': root['status']=='FROZEN' and r['root_cause_status']=='FROZEN',
'root cause class is exact': root['class']=='slackpkg-incompatible-tagged-checksums-md5-package-line-format',
'observed empty pkglist is explained exactly': root['observed_empty_pkglist_explained_exactly'] is True and r['observed_empty_pkglist_explained_exactly']=='yes',
'candidate matching is not causal': root['row_matching_logic_is_not_causal'] is True and r['row_matching_logic_causal']=='no',
'FILELIST is not package-row source': root['filelist_txt_is_not_the_package_row_source'] is True,
'PACKAGES is not package-row source': root['packages_txt_is_not_the_package_row_source'] is True,
'v3 remains immutable evidence': rem['accepted_local_source_v3_is_immutable_evidence'] is True and rem['accepted_v3_builder_bytes_must_not_be_modified_in_place'] is True,
'failed v2 evidence remains immutable': rem['failed_executor_v2_evidence_must_be_preserved_unchanged'] is True,
'executor-v2 rerun remains forbidden': rem['executor_v2_must_not_be_rerun'] is True and r['runtime_rerun_authorized']=='no',
'local-source-v4 is required': rem['new_local_source_revision_required']=='local-source-v4' and r['remediation_source_revision']=='local-source-v4',
'corrected checksum uses path-final untagged format': rem['required_checksum_format']=='GNU untagged md5sum output with package path as final field',
'corrected package line ends in extension': rem['corrected_line_ends_with_package_extension'] is True and r['corrected_package_line_ends_with_extension']=='yes',
'corrected final field is package path': rem['corrected_last_field_is_package_path'] is True and r['corrected_package_line_last_field_is_path']=='yes',
'corrected line passes Slackpkg filter': rem['corrected_line_passes_slackpkg_package_line_filter'] is True and r['corrected_package_line_passes_slackpkg_filter']=='yes',
'package authenticity remains external to compatibility metadata': rem['package_authenticity_remains_bound_by_frozen_sha256_and_external_tree_manifest'] is True and rem['compatibility_asc_remains_non-cryptographic'] is True,
'only next repository review is open': auth['repository_only_root_cause_freeze_and_v4_boundary_review_authorized'] is True and auth['repository_only_root_cause_review_authorized'] is False,
'target observation remains closed': auth['target_observation_authorized'] is False and auth['probe_transport_copy_authorized'] is False,
'v4 implementation and build remain closed': auth['local_source_v4_builder_implementation_authorized'] is False and auth['local_source_v4_build_authorized'] is False,
'runtime executor build and transport remain closed': auth['runtime_executor_build_authorized'] is False and auth['runtime_executor_transport_authorized'] is False,
'package and Slackpkg mutation remain closed': auth['package_action_authorized'] is False and auth['slackpkg_mutation_authorized'] is False,
'candidate binding and reference apply remain closed': auth['runtime_candidate_binding_authorized'] is False and auth['reference_apply_authorized'] is False,
'external network remains closed': auth['network_access_authorized'] is False,
'boot and reboot remain closed': auth['boot_action_authorized'] is False and auth['reboot_authorized'] is False,
'evidence cleanup and Phase 2 remain closed': auth['evidence_cleanup_authorized'] is False and auth['phase_2_start_authorized'] is False,
'no machine action is required': p['machine_action_required'] is False and r['machine_action_required']=='no',
'no controller action is required': p['controller_action_required'] is False and r['controller_action_required']=='no',
'next stage is v4 boundary review': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review',
}
for label,ok in checks.items(): print(('PASS' if ok else 'FAIL')+'\t'+label)
PY
while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

# Independent synthetic checksum-format reproduction.
mkdir -p "$tmp/source/slackware64/d"
target='./slackware64/d/kernel-headers-6.18.45-x86-1.txz'
printf 'synthetic-step-259-package\n' > "$tmp/source/${target#./}"
(cd "$tmp/source" && md5sum --tag -- "$target") > "$tmp/tagged"
(cd "$tmp/source" && md5sum -- "$target") > "$tmp/untagged"
if grep -Eq '\.t[blxg]z$' "$tmp/tagged"; then fail 'tagged checksum is excluded by Slackpkg terminal-extension filter'; else pass 'tagged checksum is excluded by Slackpkg terminal-extension filter'; fi
assert 'tagged checksum final field is not package path' bash -c '[[ $(awk "{print \$NF}" "$1") != "$2" ]]' _ "$tmp/tagged" "$target"
assert 'untagged checksum passes Slackpkg terminal-extension filter' grep -Eq '\.t[blxg]z$' "$tmp/untagged"
assert 'untagged checksum final field is package path' bash -c '[[ $(awk "{print \$NF}" "$1") == "$2" ]]' _ "$tmp/untagged" "$target"

assert 'v3 builder contains the causal tagged checksum writer' grep -Fq 'md5sum --tag -- "$rel"' "$v3_builder"
assert 'v3 builder validates tagged checksum records' grep -Fq 'grep -Fxq "MD5 ($rel) = $md5"' "$v3_builder"
assert 'step-259 document records frozen root-cause class' grep -Fq 'slackpkg-incompatible-tagged-checksums-md5-package-line-format' "$doc"
assert 'step-259 document records empty pkglist SHA' grep -Fq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' "$doc"
assert 'step-259 document requires local-source-v4' grep -Fq 'local-source-v4' "$doc"
assert 'step-259 document forbids executor-v2 rerun' grep -Fq 'executor-v2 must not be rerun' "$doc"
assert 'CHANGELOG records step 259' grep -Fqx '## Phase 1 step 259 kernel-package-edge runtime-transaction remediation empty-pkglist root-cause review — 2026-09-29' "$changelog"

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") contains no trailing whitespace"; else pass "$(basename "$f") contains no trailing whitespace"; fi
done

if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then fail 'step-259 helper contains no executable network package boot reboot or shutdown command'; else pass 'step-259 helper contains no executable network package boot reboot or shutdown command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
