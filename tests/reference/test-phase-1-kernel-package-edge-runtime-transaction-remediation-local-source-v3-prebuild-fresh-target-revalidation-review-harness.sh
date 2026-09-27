#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
name='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze'
helper="$repo_root/tools/reference/${name}.sh"
probe="$repo_root/tools/reference/${name}-probe.sh"
doc="$repo_root/docs/reference/${name}.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${name}-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${name}.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
v2_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
failed_exec="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }

for item in "$helper" "$probe" "$doc" "$policy" "$record"; do assert "step-247 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record" "$builder"; do assert "accepted step-246 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-246 helper hash is frozen' hash_is "$prev_helper" '8fd3a7268c7fa2ea5b55a2dc1d154b7340ac673458513105b617aa78bccb597c'
assert 'accepted step-246 document hash is frozen' hash_is "$prev_doc" '8673e5fb07a728ed8e65b9253d2e33d031f6a0dd9051d950b696fd421a1630f5'
assert 'accepted step-246 harness hash is frozen' hash_is "$prev_harness" 'cbec46f7d355251dd4b3862258274ebef8ff6456088d3b6af9fc295f0f34707d'
assert 'accepted step-246 policy hash is frozen' hash_is "$prev_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0'
assert 'accepted step-246 record hash is frozen' hash_is "$prev_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071'
assert 'frozen local-source-v3 builder hash remains exact' hash_is "$builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'historical local-source-v2 builder remains frozen' hash_is "$v2_builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert 'historical failed executor remains frozen' hash_is "$failed_exec" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
assert 'step-247 helper hash is frozen' hash_is "$helper" '82f00abac2aafb0b79ca74e7d210bd96899cb91a93e6e735b1e3d3171de91941'
assert 'step-247 probe hash is frozen' hash_is "$probe" '7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949'
assert 'step-247 document hash is frozen' hash_is "$doc" 'afd62ddaf9bbae7554a133997bd2b6ea0101ffdb2cfedf2bdcac98341251459e'
assert 'step-247 policy hash is frozen' hash_is "$policy" '08973f578b54e330e7c2219fe92d99192cf01379f2667627850515396f7f2fd9'
assert 'step-247 record hash is frozen' hash_is "$record" '2535d7488cab5268a73e779e8fd6c4a110a8c0797ab87616bf0778321f4fb759'
assert 'step-247 helper passes bash syntax validation' bash -n "$helper"
assert 'step-247 probe passes bash syntax validation' bash -n "$probe"
assert 'step-247 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-247 probe exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$probe"
assert 'step-247 helper rejects unknown option' bash -c '! "$1" --bad >/dev/null 2>&1' _ "$helper"
assert 'step-247 probe rejects unknown option' bash -c '! "$1" --bad >/dev/null 2>&1' _ "$probe"
repro=$(mktemp -d); trap 'rm -rf -- "$repro"' EXIT
assert 'step-247 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/${name}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/${name}.tsv"
assert 'step-247 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==247 and p['review_status']=='PASS' and p['review_only'] is True
assert p['accepted_step_246']['builder_sha256']=='56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
r=p['prebuild_v3_fresh_target_revalidation']; a=p['authorization']
assert r['state']=='read-only-observation-authorized'
assert r['probe_sha256']=='7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949'
assert r['acknowledgement']=='--observe-prebuild-v3-fresh-target-revalidation'
assert r['fresh_boot_id_required'] is True and r['prior_runtime_binding_reusable'] is False
assert r['local_source_v2_tree_verification_required'] is True
assert r['local_source_v2_historical_no_PGP_state_must_be_preserved'] is True
assert r['failed_remediation_human_error_must_remain_preserved'] is True
assert r['local_source_v3_final_outputs_must_be_absent'] is True
assert r['local_source_v3_temporary_build_roots_must_be_absent'] is True
assert r['future_executor_v2_must_remain_unimplemented'] is True
assert a['target_observation_authorized'] is True and a['probe_transport_copy_authorized'] is True
assert a['prebuild_v3_revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation'] is True
for k,v in a.items():
    if k not in {'target_observation_authorized','probe_transport_copy_authorized','prebuild_v3_revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation'}:
        assert v is False,k
assert p['machine_action_required'] is True and p['controller_action_required'] is True
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
PYSEM
assert 'record freezes step' record_is step 247
assert 'record freezes review status' record_is review_status PASS
assert 'record freezes frozen builder SHA' record_is builder_sha256 '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert 'record opens read-only observation' record_is prebuild_v3_fresh_target_revalidation_state read-only-observation-authorized
assert 'record freezes probe SHA' record_is prebuild_v3_revalidation_probe_sha256 '7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949'
assert 'record requires fresh boot ID' record_is fresh_boot_id_required yes
assert 'record forbids prior runtime binding reuse' record_is prior_runtime_binding_reusable no
assert 'record preserves local-source-v2' record_is local_source_v2_must_be_preserved_unchanged yes
assert 'record requires v3 final outputs absent' record_is local_source_v3_final_outputs_must_be_absent yes
assert 'record requires v3 temporary roots absent' record_is local_source_v3_temporary_build_roots_must_be_absent yes
assert 'record keeps future executor unimplemented' record_is future_executor_v2_state reviewed-frozen-not-implemented
assert 'record authorizes target observation' record_is target_observation_authorized yes
assert 'record authorizes probe transport only' record_is probe_transport_copy_authorized yes
assert 'record keeps v3 builder transport closed' record_is local_source_v3_builder_transport_authorized no
assert 'record keeps v3 builder execution closed' record_is local_source_v3_builder_execution_authorized no
assert 'record keeps v3 build closed' record_is local_source_v3_build_authorized no
assert 'record keeps executor-v2 implementation closed' record_is runtime_executor_v2_implementation_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record keeps package action closed' record_is package_action_authorized no
assert 'record keeps Slackpkg mutation closed' record_is slackpkg_mutation_authorized no
assert 'record keeps network closed' record_is network_access_authorized no
assert 'record keeps reboot closed' record_is reboot_authorized no
assert 'record routes to step-248 gate' record_is next_stage 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
assert 'probe verifies local-source-v2 tree manifest and sidecar' bash -c 'grep -Fq "local-source-v2 manifest sidecar verification failed" "$1" && grep -Fq "local-source-v2 tree verification failed" "$1"' _ "$probe"
assert 'probe preserves historical no-PGP v2 state' grep -Fq 'historical local-source-v2 compatibility asc unexpectedly contains PGP marker' "$probe"
assert 'probe checks failed remediation human error' grep -Fq "Error downloading from " "$probe"
assert 'probe checks failed remediation pkglist absence' grep -Fq 'failed remediation workdir unexpectedly contains pkglist' "$probe"
assert 'probe checks v3 final-output absence' grep -Fq 'prebuild local-source-v3 output already exists' "$probe"
assert 'probe checks v3 temporary-root absence' grep -Fq 'prebuild local-source-v3 temporary build root already exists' "$probe"
assert 'probe does not depend on preserved executor in Downloads' bash -c '! grep -Fq "/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh" "$1"' _ "$probe"
assert 'reference document records standalone Downloads-independent probe' grep -Fq 'does not depend on a preserved executor copy in `~/Descargas`' "$doc"
assert 'reference document freezes v2 manifest identity' grep -Fq 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945' "$doc"
assert 'reference document keeps v3 build closed' grep -Fq 'does not authorize builder transport/execution' "$doc"
assert 'step-247 files have no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4" "$5"' _ "$helper" "$probe" "$doc" "$policy" "$record"
assert 'CHANGELOG records step 247' grep -Fq '## Phase 1 step 247 ' "$repo_root/CHANGELOG.md"
assert 'step-247 helper contains no executable machine mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$helper"
assert 'step-247 probe contains no executable package or boot mutation command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$probe"
assert 'step-247 probe contains no network client command' bash -c '! grep -Eq "^[[:space:]]*(curl|wget|rsync|ftp|lftp|scp)[[:space:]]" "$1"' _ "$probe"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
