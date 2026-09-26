#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review-policy.json"; record="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review.tsv"; helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review.sh"; stager="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"; doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review.md"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze.sh"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze-harness.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze.md"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
pass=0; fail=0
ok(){ printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }; bad(){ printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file(){ [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }; check_line(){ grep -Fqx "$2" "$record" && ok "$1" || bad "$1"; }
for spec in "step-207 policy:$policy" "step-207 record:$record" "step-207 helper:$helper" "step-207 stager:$stager" "step-207 document:$doc" "accepted step-206 policy:$prior_policy" "accepted step-206 record:$prior_record" "frozen builder:$builder"; do check_file "${spec%%:*} is a regular file" "${spec#*:}"; done
[[ $(sha256sum "$prior_policy"|awk '{print $1}') == 89ae426cb6f7a57163fde8c182078549ed94d239956108eb1803806e3030f3ac ]] && ok 'accepted step-206 policy hash is frozen' || bad 'accepted step-206 policy hash is frozen'
[[ $(sha256sum "$prior_record"|awk '{print $1}') == 9324e7df13b645a6445be0dd3b1f1010381a14eccfaa352cb2c610cfa3a4f005 ]] && ok 'accepted step-206 record hash is frozen' || bad 'accepted step-206 record hash is frozen'
[[ $(sha256sum "$prior_helper"|awk '{print $1}') == 93cd675d96e377a96c17d405fc75695fbaa12342bbf1cfc21a7f3e336e121572 ]] && ok 'accepted step-206 helper hash is frozen' || bad 'accepted step-206 helper hash is frozen'
[[ $(sha256sum "$prior_harness"|awk '{print $1}') == b76315a4a1b53f26702cbdf2d01a805d86efdfb5e7e97a03fda943cf70badcf5 ]] && ok 'accepted step-206 harness hash is frozen' || bad 'accepted step-206 harness hash is frozen'
[[ $(sha256sum "$prior_doc"|awk '{print $1}') == ffbf3fc7f062ce31106074a9eaf9c6bd96a9b43ba4fbfe9de1dd7fc2fca9a312 ]] && ok 'accepted step-206 document hash is frozen' || bad 'accepted step-206 document hash is frozen'
[[ $(sha256sum "$builder"|awk '{print $1}') == 59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92 ]] && ok 'builder SHA remains frozen' || bad 'builder SHA remains frozen'
[[ $(sha256sum "$stager"|awk '{print $1}') == a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb ]] && ok 'reviewed stager SHA-256 is frozen' || bad 'reviewed stager SHA-256 is frozen'
bash -n "$stager" && ok 'stager passes shell syntax validation' || bad 'stager passes shell syntax validation'
bash -n "$helper" && ok 'step-207 helper passes shell syntax validation' || bad 'step-207 helper passes shell syntax validation'
if bash "$prior_harness" >/dev/null 2>&1; then ok 'accepted step-206 freeze still passes'; else bad 'accepted step-206 freeze still passes'; fi
if "$stager" >/dev/null 2>&1; then bad 'stager rejects missing acknowledgement'; else ok 'stager rejects missing acknowledgement'; fi
if "$stager" --unknown >/dev/null 2>&1; then bad 'stager rejects unknown acknowledgement'; else ok 'stager rejects unknown acknowledgement'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/${record##*/}" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
# Exercise library-only validation on ordinary files without touching production paths.
fixture="$tmp/kernel-headers-6.18.45-x86-1.txz"; printf 'synthetic-target-artifact\n' > "$fixture"; fixture_sha=$(sha256sum "$fixture"|awk '{print $1}')
if SLACK_UPDATE_TARGET_ARTIFACT_STAGER_LIBRARY_ONLY=1 bash -c 'source "$1"; validate_transport_artifact "$2" "$3" "$4"' _ "$stager" "$fixture" "kernel-headers-6.18.45-x86-1.txz" "$fixture_sha"; then ok 'library seam accepts matching regular transport artifact'; else bad 'library seam accepts matching regular transport artifact'; fi
if SLACK_UPDATE_TARGET_ARTIFACT_STAGER_LIBRARY_ONLY=1 bash -c 'source "$1"; validate_transport_artifact "$2" "$3" deadbeef' _ "$stager" "$fixture" "kernel-headers-6.18.45-x86-1.txz" >/dev/null 2>&1; then bad 'library seam rejects wrong transport SHA'; else ok 'library seam rejects wrong transport SHA'; fi
ln -s "$fixture" "$tmp/link-kernel-headers-6.18.45-x86-1.txz"
if SLACK_UPDATE_TARGET_ARTIFACT_STAGER_LIBRARY_ONLY=1 bash -c 'source "$1"; validate_transport_artifact "$2" "$3" "$4"' _ "$stager" "$tmp/link-kernel-headers-6.18.45-x86-1.txz" "link-kernel-headers-6.18.45-x86-1.txz" "$fixture_sha" >/dev/null 2>&1; then bad 'library seam rejects symlink transport artifact'; else ok 'library seam rejects symlink transport artifact'; fi
python3 - "$policy" <<'PY207' && ok 'policy freezes fail-closed staging review with no machine authority' || bad 'policy freezes fail-closed staging review with no machine authority'
import json,sys
p=json.load(open(sys.argv[1])); s=p['target_artifact_staging']; a=p['authorization']
assert s['state']=='reviewed-awaiting-authorization'
assert s['stager_sha256']=='a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb' and p['stager_sha256']=='a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
assert s['transport_source']=='/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz'
assert s['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert s['preflight']['acceptance_root_must_not_preexist'] and s['preflight']['transport_source_symlink_allowed'] is False
assert s['atomicity']['promote_only_after_staged_artifact_validation'] and s['atomicity']['unexpected_existing_acceptance_root_overwrite_allowed'] is False
assert s['staged_target_owner']=='root:root' and s['staged_target_mode']=='0444'
assert s['runtime_binding']['boot_id']=='d767c4ed-b21f-4c6f-9a1e-db7948c285cf' and s['runtime_binding']['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert a['target_artifact_staging_authorization_review_authorized_for_next_stage'] is True
for k,v in a.items():
    if k!='target_artifact_staging_authorization_review_authorized_for_next_stage': assert v is False
assert p['machine_action_required'] is False and p['pause_safe'] is False
PY207
check_line 'record marks staging reviewed awaiting authorization' $'target_artifact_staging_state\treviewed-awaiting-authorization'
check_line 'record freezes stager SHA' $'stager_sha256\ta57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
check_line 'record freezes transport source' $'transport_source\t/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz'
check_line 'record freezes target SHA' $'target_sha256\tc7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
check_line 'record requires absent acceptance root' $'acceptance_root_must_not_preexist\tyes'
check_line 'record preserves transport source' $'transport_source_preserved\tyes'
check_line 'record forbids stager execution' $'stager_execution_authorized\tno'
check_line 'record forbids target artifact copy' $'target_artifact_copy_authorized\tno'
check_line 'record forbids builder execution' $'builder_execution_authorized\tno'
check_line 'record forbids local-source build' $'local_source_build_authorized\tno'
check_line 'record requires no machine action' $'machine_action_required\tno'
check_line 'record routes only to staging authorization review' $'next_stage\tphase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review'
if grep -Fq 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb' "$doc" && grep -Fq 'does **not** authorize copying or staging' "$doc"; then ok 'reference document records staging review boundary'; else bad 'reference document records staging review boundary'; fi
if grep -Fq 'Phase 1 step 207 kernel-package-edge target-artifact staging review' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 207'; else bad 'CHANGELOG records step 207'; fi
# Stager must not contain network/package/boot mutation clients.
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$stager"; then bad 'stager contains no executable network/package/boot/reboot command'; else ok 'stager contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
