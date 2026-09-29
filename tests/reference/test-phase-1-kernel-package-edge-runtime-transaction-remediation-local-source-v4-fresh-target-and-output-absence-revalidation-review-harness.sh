#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review'
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.tsv"
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.sh"
prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.md"
prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze.tsv"
v4_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
step258_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"
passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file() { [[ -f $1 && ! -L $1 ]] && pass "$2 exists as regular file" || fail "$2 exists as regular file"; }
check_hash() { local got; got=$(sha256sum -- "$1" | awk '{print $1}'); [[ $got == "$2" ]] && pass "$3 SHA-256 matches" || fail "$3 SHA-256 matches ($got)"; }

check_file "$helper" 'step-265 helper'; check_file "$probe" 'step-265 probe'; check_file "$doc" 'step-265 document'; check_file "$policy" 'step-265 policy'; check_file "$record" 'step-265 record'
check_hash "$prev_helper" 'a2a95740b9d1837a6d0ef7ad5510199868b5ae07087ef692c55375f46af0beb7' 'accepted step-264 helper'
check_hash "$prev_doc" 'f0d706b90a1941d5987614ae75254a03d176a2701dd39f16b610b0ece3a28234' 'accepted step-264 document'
check_hash "$prev_harness" '5957d5a459d5d94231c8d7c18983d8a2ec31da6fbe87778ed4571697e48bc532' 'accepted step-264 harness'
check_hash "$prev_policy" 'c9f087b26eda42baef877438ec2b47dc7b257fc3e0562a10ca4bab2eeec4584d' 'accepted step-264 policy'
check_hash "$prev_record" 'b0f6075b9c048ef85dd7c7cc24fb283b6a9d618625b7b27eb3cc8c57426737d1' 'accepted step-264 record'
check_hash "$v4_builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen v4 builder'
check_hash "$step258_policy" '0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc' 'accepted failed-v2 checkpoint'
check_hash "$probe" '16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd' 'step-265 probe'
check_hash "$helper" 'bf6fdad0eca2444c8be535eaaf8cd8aaeca54a548c10425fbccc363d3af9a52f' 'step-265 helper'
check_hash "$doc" 'b6a5892659c84f64a209edb750bc6c33e7aaf5ba2af5aee16691049a6bf7f3ec' 'step-265 document'
check_hash "$policy" 'e1f76e643cd3bf2784f5038acdc01961290b724e3574a98d8ae951e59b480daf' 'step-265 policy'
check_hash "$record" '4ccfe17c7a6236d1bc4ad92d64015fd3bcaafd1bca1aceb931c5a417c7eeca55' 'step-265 record'

bash -n "$helper" && pass 'step-265 helper passes bash syntax validation' || fail 'step-265 helper passes bash syntax validation'
bash -n "$probe" && pass 'step-265 probe passes bash syntax validation' || fail 'step-265 probe passes bash syntax validation'
bash -n "${BASH_SOURCE[0]}" && pass 'step-265 harness passes bash syntax validation' || fail 'step-265 harness passes bash syntax validation'
"$helper" --help >/dev/null && pass 'step-265 helper exposes non-mutating help' || fail 'step-265 helper exposes non-mutating help'
"$probe" --help >/dev/null && pass 'step-265 probe exposes non-mutating help' || fail 'step-265 probe exposes non-mutating help'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-265 helper rejects unknown option'; else pass 'step-265 helper rejects unknown option'; fi
if "$probe" --unknown >/dev/null 2>&1; then fail 'step-265 probe rejects unknown option'; else pass 'step-265 probe rejects unknown option'; fi

work=$(mktemp -d); trap 'rm -rf -- "$work"' EXIT
"$helper" --output-dir "$work" >/dev/null && pass 'step-265 helper executes successfully' || fail 'step-265 helper executes successfully'
cmp -s "$work/${base}-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$work/${base}.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

python3 - "$policy" "$record" <<'PYCHECK'
import json, pathlib, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
r={}
for line in pathlib.Path(sys.argv[2]).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); r[k]=v
assert p['step']==265 and p['review_status']=='PASS'
assert p['frozen_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert p['frozen_v4_builder']['state']=='implementation-frozen-not-executed'
assert p['revalidation_probe']['sha256']=='16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd'
assert p['revalidation_probe']['prior_runtime_binding_reusable'] is False
assert p['revalidation_probe']['accepted_local_source_v3_tree_verification_required'] is True
assert p['revalidation_probe']['failed_v2_evidence_preservation_required'] is True
assert p['revalidation_probe']['failed_v2_pkglist_must_remain_zero_bytes'] is True
assert p['revalidation_probe']['local_source_v4_root_must_be_absent'] is True
assert p['revalidation_probe']['local_source_v4_manifest_must_be_absent'] is True
assert p['revalidation_probe']['local_source_v4_manifest_sidecar_must_be_absent'] is True
assert p['revalidation_probe']['local_source_v4_temp_roots_must_be_absent'] is True
assert p['authorization']['target_observation_authorized'] is True
assert p['authorization']['probe_transport_copy_authorized'] is True
assert p['authorization']['local_source_v4_builder_execution_authorized'] is False
assert p['authorization']['local_source_v4_build_authorized'] is False
assert p['authorization']['slackpkg_refresh_authorized'] is False
assert p['authorization']['package_action_authorized'] is False
assert p['authorization']['network_access_authorized'] is False
assert p['authorization']['boot_action_authorized'] is False
assert p['machine_action_class']=='read-only-v4-prebuild-target-and-output-absence-revalidation'
assert p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review'
assert r['revalidation_state']=='read-only-observation-authorized'
assert r['v4_builder_execution_authorized']=='no' and r['v4_build_authorized']=='no'
assert r['local_source_v4_outputs_must_be_absent']=='yes'
PYCHECK
[[ $? -eq 0 ]] && pass 'step-265 policy semantic assertions pass' || fail 'step-265 policy semantic assertions pass'

grep -Fq 'readonly LOCAL_SOURCE_V4_ROOT="$ACCEPTANCE_ROOT/local-source-v4"' "$probe" && pass 'probe binds distinct local-source-v4 root' || fail 'probe binds distinct local-source-v4 root'
grep -Fq 'verify_local_source_v3' "$probe" && pass 'probe verifies accepted local-source-v3' || fail 'probe verifies accepted local-source-v3'
grep -Fq 'verify_failed_v2_evidence' "$probe" && pass 'probe verifies failed-v2 evidence preservation' || fail 'probe verifies failed-v2 evidence preservation'
grep -Fq 'verify_v4_outputs_absent' "$probe" && pass 'probe requires v4 output absence' || fail 'probe requires v4 output absence'
grep -Fq "EXPECTED_EMPTY_SHA256='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'" "$probe" && pass 'probe binds empty failed-v2 pkglist identity' || fail 'probe binds empty failed-v2 pkglist identity'
grep -Fq "EXPECTED_V4_BUILDER_SHA256='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'" "$probe" && pass 'probe reports frozen v4 builder identity' || fail 'probe reports frozen v4 builder identity'

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rm|cp|mv|install|mkdir|touch|chmod|chown)([[:space:]]|$)|^[[:space:]]*(sudo[[:space:]]+)?git[[:space:]]+(pull|fetch)([[:space:]]|$)' "$probe"; then
    fail 'step-265 probe contains no executable mutation network package boot or reboot command'
else
    pass 'step-265 probe contains no executable mutation network package boot or reboot command'
fi
for f in "$helper" "$probe" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "${f##*/} contains no trailing whitespace"; else pass "${f##*/} contains no trailing whitespace"; fi
done

grep -Fq '## Phase 1 step 265' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 265' || fail 'CHANGELOG records step 265'
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
