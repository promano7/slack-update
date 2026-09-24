#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.md"
policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"
review_policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review-policy.json"
review_record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check() { local msg=$1; shift; if "$@"; then pass "$msg"; else fail "$msg"; fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
contains() { grep -Fq -- "$2" "$1"; }

check 'step-197 binding-freeze helper is a regular non-symlink file' regular "$helper"
check 'step-197 reference document is a regular non-symlink file' regular "$doc"
check 'step-197 binding-freeze policy is a regular non-symlink file' regular "$policy"
check 'step-197 binding-freeze record is a regular non-symlink file' regular "$record"
check 'accepted step-196 binding-review policy is a regular non-symlink file' regular "$review_policy"
check 'accepted step-196 binding-review record is a regular non-symlink file' regular "$review_record"
check 'accepted step-196 controller probe is a regular non-symlink file' regular "$probe"

check 'step-197 helper has the exact reviewed SHA-256' hash_is "$helper" 'f9bacedb9c65576a9b7eb32ac53e4465088f5ef8700976ed8a5b6cb31d2f7ebb'
check 'step-197 reference document has the exact reviewed SHA-256' hash_is "$doc" 'da1f6549f30ed7628e0e27c7abaf23fbabb6e2273d97c226f4be4455e83ac9fe'
check 'step-197 policy has the exact reviewed SHA-256' hash_is "$policy" '79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12'
check 'step-197 record has the exact reviewed SHA-256' hash_is "$record" 'abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449'
check 'accepted step-196 policy has the frozen SHA-256' hash_is "$review_policy" 'ba6fe4afb14cc5c7793c2ac610660706648eb2bbf5a8b95ea31199efe18cb03b'
check 'accepted step-196 record has the frozen SHA-256' hash_is "$review_record" '27c86a17e6f98984cb2101749d3fba21b14be697dca7382f9016ef90ef83df2a'
check 'accepted step-196 acquisition probe has the frozen SHA-256' hash_is "$probe" '943af8b0995368b34c3fc79efaac09cbbdebebc1ea5929a4c566ccfd2ef1e586'

check 'step-197 helper is shell-syntax valid' bash -n "$helper"
check 'step-197 helper exposes a non-mutating help boundary' bash -c '"$1" --help >/dev/null' _ "$helper"
check 'step-197 helper rejects unknown options' bash -c '! "$1" --definitely-unknown >/dev/null 2>&1' _ "$helper"
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-197 policy is valid JSON'; else fail 'step-197 policy is valid JSON'; fi

python3 - "$policy" "$record" <<'PY' && pass 'step-197 byte binding freeze completed successfully' || fail 'step-197 byte binding freeze completed successfully'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['scenario']=='phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze'
assert p['artifact_byte_binding']['state']=='accepted-byte-binding-frozen'
assert p['artifact_byte_binding']['observation_status']=='PASS'
assert p['accepted_binding_review']['step']==196
assert p['next_stage']=='phase-1-kernel-package-edge-local-source-construction-review'
assert r['artifact_byte_binding_state']=='accepted-byte-binding-frozen'
assert r['observation_status']=='PASS'
PY

python3 - "$policy" <<'PY' && pass 'binding freeze records the exact evidence-root identities' || fail 'binding freeze records the exact evidence-root identities'
import json,sys
b=json.load(open(sys.argv[1]))['artifact_byte_binding']
assert b['evidence_root']=='/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts'
assert b['evidence_root_must_be_preserved_unchanged'] is True
assert b['binding_evidence_sha256']=='dd3037a58a3a2455d5c4e960ac027bed3dc644a193c22e9ec806a43d91b2ae63'
assert b['acquired_files_manifest_sha256']=='1292ade434fd52b90f4230955610d5a0ca70fb0c586a6a6488ecf912621cf86f'
PY

python3 - "$policy" <<'PY' && pass 'binding freeze records the exact Slackware signing-key evidence' || fail 'binding freeze records the exact Slackware signing-key evidence'
import json,sys
k=json.load(open(sys.argv[1]))['artifact_byte_binding']['signing_key']
assert k['fingerprint']=='EC5649DA401E22ABFA6736EF6A4463C040102233'
assert k['file_sha256']=='82af92f3a9abdae815534912e7c438f1bad50b8516bb8d75fe9e08444f727daf'
PY

python3 - "$policy" <<'PY' && pass 'predecessor package and signature bytes are frozen exactly' || fail 'predecessor package and signature bytes are frozen exactly'
import json,sys
x=json.load(open(sys.argv[1]))['artifact_byte_binding']['package_pair']
assert x['predecessor_record']=='kernel-headers-6.18.44-x86-1'
assert x['predecessor_package_sha256']=='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
assert x['predecessor_signature_sha256']=='e818c8b1c665aabc8724e8a301de5a711eb949bbf2dfd92dba8ce5ced7bdcf21'
assert x['predecessor_signature_valid'] is True
PY

python3 - "$policy" <<'PY' && pass 'target package and signature bytes are frozen exactly' || fail 'target package and signature bytes are frozen exactly'
import json,sys
x=json.load(open(sys.argv[1]))['artifact_byte_binding']['package_pair']
assert x['target_record']=='kernel-headers-6.18.45-x86-1'
assert x['target_package_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert x['target_signature_sha256']=='66787e515d7d4420daab5aac412cd8ac5921a1dff037147b8216e1017ac1c801'
assert x['target_signature_valid'] is True
PY

python3 - "$policy" <<'PY' && pass 'accepted acquisition side effects are all negative' || fail 'accepted acquisition side effects are all negative'
import json,sys
s=json.load(open(sys.argv[1]))['artifact_byte_binding']['accepted_observation_side_effects']
assert all(v is False for v in s.values())
PY

python3 - "$policy" <<'PY' && pass 'step 196 network authorization is revoked after byte binding' || fail 'step 196 network authorization is revoked after byte binding'
import json,sys
a=json.load(open(sys.argv[1]))['authorization']
assert a['controller_artifact_acquisition_authorized'] is False
assert a['controller_network_access_authorized'] is False
assert json.load(open(sys.argv[1]))['artifact_byte_binding']['controller_redownload_requires_new_explicit_authorization'] is True
PY

python3 - "$policy" <<'PY' && pass 'target and runtime mutations remain forbidden' || fail 'target and runtime mutations remain forbidden'
import json,sys
a=json.load(open(sys.argv[1]))['authorization']
for k in ['target_vm_network_access_authorized','target_vm_action_authorized','target_artifact_copy_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','local_source_build_authorized','runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','phase_2_start_authorized']:
    assert a[k] is False
PY

check 'only the local-source construction review is authorized next' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["authorization"]["local_source_construction_review_authorized_for_next_stage"] is True and p["next_stage"]=="phase-1-kernel-package-edge-local-source-construction-review"' "$policy"
check 'step 197 requires no controller or machine action' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["controller_action_required"] is False and p["machine_action_required"] is False' "$policy"
check 'later publication does not invalidate frozen bytes' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["artifact_byte_binding"]["later_archive_or_slackware_current_publication_invalidates_byte_binding"] is False' "$policy"
check 'step 197 remains inside the active chain' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["pause_safe"] is False' "$policy"

for value in 'dd3037a58a3a2455d5c4e960ac027bed3dc644a193c22e9ec806a43d91b2ae63' '1292ade434fd52b90f4230955610d5a0ca70fb0c586a6a6488ecf912621cf86f' '82af92f3a9abdae815534912e7c438f1bad50b8516bb8d75fe9e08444f727daf' '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d' 'e818c8b1c665aabc8724e8a301de5a711eb949bbf2dfd92dba8ce5ced7bdcf21' 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c' '66787e515d7d4420daab5aac412cd8ac5921a1dff037147b8216e1017ac1c801'; do
    check "record contains frozen SHA-256 $value" contains "$record" "$value"
done

check 'record closes controller acquisition authorization' contains "$record" $'controller_artifact_acquisition_authorized\tno'
check 'record closes controller network authorization' contains "$record" $'controller_network_access_authorized\tno'
check 'record preserves the next stage' contains "$record" $'next_stage\tphase-1-kernel-package-edge-local-source-construction-review'

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
if bash "$helper" --output-dir "$TMP" >/dev/null && cmp -s "$policy" "$TMP/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json" && cmp -s "$record" "$TMP/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"; then
    pass 'step-197 helper reproduces policy and record deterministically'
else
    fail 'step-197 helper reproduces policy and record deterministically'
fi

check 'reference document records the preserved evidence root' contains "$doc" '/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts'
check 'reference document records both frozen package hashes' bash -c 'grep -Fq 3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d "$1" && grep -Fq c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c "$1"' _ "$doc"
check 'reference document records controller network closure' contains "$doc" 'closes the temporary controller acquisition authorization'
check 'reference document records next local-source construction review' contains "$doc" 'phase-1-kernel-package-edge-local-source-construction-review'
check 'CHANGELOG records step 197' contains "$changelog" '## Phase 1 step 197 kernel-package-edge package-pair and local-source binding freeze'
check 'step-197 helper contains no network client command' bash -c '! grep -Eq '"'"'(^|[[:space:]])(curl|wget|ftp|rsync)([[:space:]]|$)'"'"' "$1"' _ "$helper"
check 'step-197 helper contains no executable package, boot, reboot, or shutdown mutation line' bash -c '! grep -Eq '"'"'^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|eliloconfig|lilo|reboot|shutdown|poweroff)([[:space:]]|$)'"'"' "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
