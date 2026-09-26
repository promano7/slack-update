#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-r2-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.md"
step201r1_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review-policy.json"
step201r1_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.tsv"
characterization_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-probe.sh"
passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }

for f in "$policy" "$record" "$helper" "$probe" "$doc" "$step201r1_policy" "$step201r1_record" "$characterization_probe"; do
    [[ -f $f && ! -L $f ]] && pass "${f#$repo_root/} is a regular file" || fail "${f#$repo_root/} missing or unsafe"
done

bash -n "$helper" && pass 'step-201-r2 helper passes shell syntax validation' || fail 'step-201-r2 helper shell syntax'
bash -n "$probe" && pass 'step-201-r2 probe passes shell syntax validation' || fail 'step-201-r2 probe shell syntax'

[[ $(sha256sum "$step201r1_policy" | awk '{print $1}') == 698b7127fd2922046a2a9a633fd9371291962b0b535563b766ba835cfcdd162d ]] && pass 'accepted step-201-r1 policy hash is frozen' || fail 'accepted step-201-r1 policy hash drift'
[[ $(sha256sum "$step201r1_record" | awk '{print $1}') == edac5ba6521c71f05605aacf8b32ae144d4d1a9846d249f14821af05e3b3a5d9 ]] && pass 'accepted step-201-r1 record hash is frozen' || fail 'accepted step-201-r1 record hash drift'
[[ $(sha256sum "$characterization_probe" | awk '{print $1}') == 523decebbbda74069ebdd97e3ed8c3465514eee65f3ce673c4d845eb8d9098f2 ]] && pass 'accepted characterization probe hash is frozen' || fail 'accepted characterization probe hash drift'

python3 - "$policy" <<'PY' && pass 'policy accepts only characterized out-of-scenario drift and corrected read-only rerun' || fail 'policy contract mismatch'
import json,sys
p=json.load(open(sys.argv[1]))
assert p['scenario'].endswith('package-database-drift-characterization-review')
assert p['revision']=='r2-drift-isolation-and-revalidation-rerun'
e=p['characterization_evidence']
assert e['status']=='PASS'
assert e['boot_id']=='d767c4ed-b21f-4c6f-9a1e-db7948c285cf'
assert e['baseline_package_database_manifest_sha256']=='3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
assert e['characterized_package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert e['recent_installed_record_count']==1
assert e['recent_installed_records']==['pCloudDrive-2.3.0-x86_64-1_SBo']
assert e['recent_removed_record_count']==0
assert e['header_package_record_baseline_match'] is True
assert e['kernel_generic_record_baseline_match'] is True
assert e['kernel_huge_absent'] is True
assert e['kernel_modules_absent'] is True
assert e['slackpkg_conf_baseline_match'] is True
assert e['slackpkg_mirrors_baseline_match'] is True
assert p['review_decision']['drift_class']=='out-of-scenario-third-party-package-record'
assert p['review_decision']['scenario_critical_state_unchanged'] is True
assert p['review_decision']['direct_target_binding_freeze_authorized'] is False
assert p['review_decision']['additional_drift_fails_closed'] is True
assert p['authorization']['corrected_fresh_target_revalidation_rerun_authorized'] is True
assert p['authorization']['fresh_target_revalidation_freeze_authorized_after_pass'] is True
for k,v in p['authorization'].items():
    if k not in {'corrected_fresh_target_revalidation_rerun_authorized','fresh_target_revalidation_freeze_authorized_after_pass'}:
        assert v is False
assert p['machine_action_required'] is True
assert p['pause_safe'] is False
PY

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
bash "$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && cmp -s "$record" "$tmp/${record##*/}" && pass 'step-201-r2 helper reproduces policy and record deterministically' || fail 'step-201-r2 helper output is not deterministic'

probe_sha=$(sha256sum "$probe" | awk '{print $1}')
grep -Fqx $'corrected_revalidation_probe_sha256\t'"$probe_sha" "$record" && pass 'record binds exact corrected revalidation probe SHA-256' || fail 'record corrected probe SHA-256 mismatch'
grep -Fq "readonly EXPECTED_BOOT_ID='d767c4ed-b21f-4c6f-9a1e-db7948c285cf'" "$probe" && pass 'probe binds characterized boot ID' || fail 'probe boot-ID binding missing'
grep -Fq "readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'" "$probe" && pass 'probe binds characterized package manifest' || fail 'probe package-manifest binding missing'
grep -Fq "readonly EXPECTED_CHARACTERIZED_RECORD='pCloudDrive-2.3.0-x86_64-1_SBo'" "$probe" && pass 'probe binds exact characterized third-party record' || fail 'probe third-party record binding missing'
grep -Fq 'recent_installed_count -eq 1' "$probe" && grep -Fq 'recent_removed_count -eq 0' "$probe" && pass 'probe rejects additional post-baseline package drift' || fail 'probe post-baseline drift guard missing'
grep -Fq "readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'" "$probe" && pass 'probe preserves exact kernel-headers record' || fail 'probe kernel-headers binding missing'
grep -Fq "readonly EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'" "$probe" && pass 'probe preserves exact kernel-generic record' || fail 'probe kernel-generic binding missing'
grep -Fq "readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'" "$probe" && pass 'probe preserves slackpkg.conf fingerprint' || fail 'probe slackpkg.conf binding missing'
grep -Fq "readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'" "$probe" && pass 'probe preserves slackpkg mirrors fingerprint' || fail 'probe slackpkg mirrors binding missing'
grep -Fq "readonly FROZEN_PREDECESSOR_SHA256='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'" "$probe" && grep -Fq "readonly FROZEN_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'" "$probe" && pass 'probe preserves frozen predecessor/target artifact bytes' || fail 'probe artifact binding drift'
grep -Fq $'fresh_target_revalidation_freeze_authorized_after_pass\tyes' "$record" && pass 'successful rerun routes only to fresh target freeze' || fail 'fresh target freeze route missing'
grep -Fq $'target_artifact_copy_authorized\tno' "$record" && grep -Fq $'local_source_build_authorized\tno' "$record" && pass 'target copy and local-source build remain forbidden' || fail 'target copy/local-source authorization widened'
grep -Fq $'package_action_authorized\tno' "$record" && grep -Fq $'boot_action_authorized\tno' "$record" && grep -Fq $'reboot_authorized\tno' "$record" && pass 'package, boot, and reboot actions remain forbidden' || fail 'machine mutation authorization widened'

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)([[:space:]]|$)' "$probe"; then
    fail 'probe contains executable mutation or network command'
else
    pass 'probe contains no executable network/package/boot/reboot command'
fi

if grep -Eq '(^|[;&|])[[:space:]]*(cp|mv|rm|mkdir|touch|chmod|chown|ln|tee|sed[[:space:]]+-i)([[:space:]]|$)' "$probe"; then
    fail 'probe contains persistent filesystem mutation command'
else
    pass 'probe contains no persistent filesystem mutation command'
fi

grep -Fq 'pCloudDrive-2.3.0-x86_64-1_SBo' "$doc" && pass 'reference document records isolated pCloudDrive drift' || fail 'reference document missing isolated drift record'
grep -Fq 'does not directly freeze a new runtime target binding' "$doc" && pass 'reference document preserves review-before-freeze boundary' || fail 'reference document freeze boundary unclear'
grep -Fq 'Phase 1 step 201-r2' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 201-r2' || fail 'CHANGELOG missing step 201-r2'

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
