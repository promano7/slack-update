#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.md"
policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review-policy.json"
record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.tsv"
design_policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json"
design_record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.tsv"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check() { local msg=$1; shift; if "$@"; then pass "$msg"; else fail "$msg"; fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
contains() { grep -Fq -- "$2" "$1"; }
not_contains() { ! grep -Fq -- "$2" "$1"; }

check 'step-196 binding-review helper is a regular non-symlink file' regular "$helper"
check 'step-196 controller acquisition probe is a regular non-symlink file' regular "$probe"
check 'step-196 reference document is a regular non-symlink file' regular "$doc"
check 'step-196 binding-review policy is a regular non-symlink file' regular "$policy"
check 'step-196 binding-review record is a regular non-symlink file' regular "$record"
check 'accepted step-195 design policy is a regular non-symlink file' regular "$design_policy"
check 'accepted step-195 design record is a regular non-symlink file' regular "$design_record"

check 'step-196 binding-review helper has the exact reviewed SHA-256' hash_is "$helper" '512c2bb9146a740ba05a2b839b406550d3d0f11e9e9e59ed53c8486c62f38301'
check 'step-196 acquisition probe has the exact reviewed SHA-256' hash_is "$probe" '943af8b0995368b34c3fc79efaac09cbbdebebc1ea5929a4c566ccfd2ef1e586'
check 'step-196 reference document has the exact reviewed SHA-256' hash_is "$doc" '61c04e143521d1f8d53344f2cedf8c14f62d72ce5b98ae561e2486cdbdcd8886'
check 'step-196 binding-review policy has the exact reviewed SHA-256' hash_is "$policy" 'ba6fe4afb14cc5c7793c2ac610660706648eb2bbf5a8b95ea31199efe18cb03b'
check 'step-196 binding-review record has the exact reviewed SHA-256' hash_is "$record" '27c86a17e6f98984cb2101749d3fba21b14be697dca7382f9016ef90ef83df2a'
check 'accepted step-195 design policy has the frozen SHA-256' hash_is "$design_policy" 'ce33fc2ead2335c50cd9e47146f8d1d818a49e1cb3169b06fe9a983af60f6015'
check 'accepted step-195 design record has the frozen SHA-256' hash_is "$design_record" 'aa37378cc4e3af31fc37a0a111b9ab0e39f3bf784e011168f962e165927a01a5'

check 'step-196 binding-review helper is shell-syntax valid' bash -n "$helper"
check 'step-196 acquisition probe is shell-syntax valid' bash -n "$probe"
check 'step-196 helper exposes a non-mutating help boundary' bash -c '"$1" --help >/dev/null' _ "$helper"
check 'step-196 probe exposes a non-mutating help boundary' bash -c '"$1" --help >/dev/null' _ "$probe"
check 'step-196 helper rejects unknown options' bash -c '! "$1" --definitely-unknown >/dev/null 2>&1' _ "$helper"
check 'step-196 probe rejects unknown options' bash -c '! "$1" --definitely-unknown >/dev/null 2>&1' _ "$probe"
check 'step-196 probe requires an explicit output directory' bash -c '! "$1" --acquire-binding-evidence >/dev/null 2>&1' _ "$probe"

if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass 'step-196 binding-review policy is valid JSON'; else fail 'step-196 binding-review policy is valid JSON'; fi

python3 - "$policy" "$record" <<'PY' && pass 'step-196 package-pair/local-source binding review completed successfully' || fail 'step-196 package-pair/local-source binding review completed successfully'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['scenario']=='phase-1-kernel-package-edge-package-pair-and-local-source-binding-review'
assert p['accepted_binding_design']['step']==195
assert p['artifact_binding_review']['state']=='frozen-awaiting-controller-acquisition-evidence'
assert p['next_stage']=='phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze'
assert r['artifact_binding_review_state']=='frozen-awaiting-controller-acquisition-evidence'
PY

python3 - "$policy" <<'PY' && pass 'review preserves the exact predecessor/target artifact origins' || fail 'review preserves the exact predecessor/target artifact origins'
import json,sys
p=json.load(open(sys.argv[1])); o=p['artifact_binding_review']['artifact_origins']
assert o['predecessor_package_url'].endswith('/kernel-headers-6.18.44-x86-1.txz')
assert o['predecessor_signature_url'].endswith('/kernel-headers-6.18.44-x86-1.txz.asc')
assert o['target_package_url'].endswith('/kernel-headers-6.18.45-x86-1.txz')
assert o['target_signature_url'].endswith('/kernel-headers-6.18.45-x86-1.txz.asc')
assert all(v.startswith('https://slackware.uk/cumulative/') for v in o.values())
PY

python3 - "$policy" <<'PY' && pass 'review freezes the Slackware signing-key identity' || fail 'review freezes the Slackware signing-key identity'
import json,sys
k=json.load(open(sys.argv[1]))['artifact_binding_review']['signing_key']
assert k['url']=='https://mirrors.slackware.com/slackware/slackware-current/GPG-KEY'
assert k['expected_primary_fingerprint']=='EC5649DA401E22ABFA6736EF6A4463C040102233'
assert k['expected_long_key_id']=='6A4463C040102233'
assert k['expected_uid']=='Slackware Linux Project <security@slackware.com>'
PY

python3 - "$policy" <<'PY' && pass 'review records the pair as consecutive in the cumulative archive' || fail 'review records the pair as consecutive in the cumulative archive'
import json,sys
h=json.load(open(sys.argv[1]))['artifact_binding_review']['pair_history_review']
assert h['predecessor_record']=='kernel-headers-6.18.44-x86-1'
assert h['target_record']=='kernel-headers-6.18.45-x86-1'
assert h['predecessor_archive_timestamp']=='2026-08-10 03:40'
assert h['target_archive_timestamp']=='2026-08-20 05:19'
assert h['consecutive_in_cumulative_archive'] is True
PY

python3 - "$policy" <<'PY' && pass 'review defers byte binding to the next freeze gate' || fail 'review defers byte binding to the next freeze gate'
import json,sys
p=json.load(open(sys.argv[1]))['artifact_binding_review']
assert p['package_and_signature_sha256_binding_deferred_to_next_freeze'] is True
need=set(p['required_probe_evidence'])
for key in ['predecessor_package_sha256','target_package_sha256','predecessor_signature_sha256','target_signature_sha256','binding_evidence_sha256','acquired_files_manifest_sha256']:
    assert key in need
PY

python3 - "$policy" <<'PY' && pass 'controller acquisition is narrowly authorized while target actions remain forbidden' || fail 'controller acquisition is narrowly authorized while target actions remain forbidden'
import json,sys
a=json.load(open(sys.argv[1]))['authorization']
assert a['controller_artifact_acquisition_authorized'] is True
assert a['controller_network_access_authorized_only_for_frozen_probe_urls'] is True
for k in ['target_vm_network_access_authorized','target_vm_action_authorized','target_artifact_copy_authorized','package_pair_binding_authorized','local_source_binding_authorized','local_source_build_authorized','runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized']:
    assert a[k] is False
PY

check 'step 196 requires controller action but no target-machine action' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["controller_action_required"] is True and p["machine_action_required"] is False' "$policy"
check 'step 196 is not a strong safe pause' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["pause_safe"] is False' "$policy"
check 'next stage is package-pair/local-source binding freeze' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["next_stage"]=="phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze"' "$policy"

check 'probe embeds the exact Slackware project signing-key fingerprint' contains "$probe" "expected_fpr='EC5649DA401E22ABFA6736EF6A4463C040102233'"
check 'probe embeds the exact Slackware signing-key long ID' contains "$probe" "expected_keyid='6A4463C040102233'"
check 'probe embeds the exact Slackware signing-key UID' contains "$probe" "expected_uid='Slackware Linux Project <security@slackware.com>'"
check 'probe obtains the key only from the frozen Slackware mirror URL' contains "$probe" "key_url='https://mirrors.slackware.com/slackware/slackware-current/GPG-KEY'"
check 'probe obtains artifacts only from the frozen cumulative archive base' contains "$probe" "archive_base='https://slackware.uk/cumulative/slackware64-current/slackware64/d'"
check 'probe freezes the expected predecessor package filename' contains "$probe" "pre_pkg='kernel-headers-6.18.44-x86-1.txz'"
check 'probe freezes the expected target package filename' contains "$probe" "tgt_pkg='kernel-headers-6.18.45-x86-1.txz'"
check 'probe requires HTTPS-only curl transport' contains "$probe" "--proto '=https' --tlsv1.2"
check 'probe disables automatic GPG key retrieval' contains "$probe" '--no-auto-key-retrieve'
check 'probe requires exact VALIDSIG fingerprint evidence' contains "$probe" '[GNUPG:] VALIDSIG $expected_fpr '
check 'probe rejects execution as root' contains "$probe" '(( EUID != 0 ))'
check 'probe requires a new output path' contains "$probe" '[[ ! -e $output_dir ]]'
check 'probe writes binding-evidence.tsv' contains "$probe" 'binding-evidence.tsv'
check 'probe writes acquired-files.sha256' contains "$probe" 'acquired-files.sha256'
check 'probe records both package SHA-256 values' bash -c 'grep -Fq predecessor_package_sha256 "$1" && grep -Fq target_package_sha256 "$1"' _ "$probe"
check 'probe records both signature SHA-256 values' bash -c 'grep -Fq predecessor_signature_sha256 "$1" && grep -Fq target_signature_sha256 "$1"' _ "$probe"
check 'probe records both signature validation results' bash -c 'grep -Fq predecessor_signature_valid "$1" && grep -Fq target_signature_valid "$1"' _ "$probe"
check 'probe records that target-VM network access was not performed' contains "$probe" 'target_vm_network_access_performed'
check 'probe records that target-VM action was not performed' contains "$probe" 'target_vm_action_performed'
check 'probe records that no package action was performed' contains "$probe" 'package_action_performed'
check 'probe records that no boot action was performed' contains "$probe" 'boot_action_performed'
check 'probe records that no reboot was performed' contains "$probe" 'reboot_performed'
check 'probe explicitly tells the operator to preserve the evidence root' contains "$probe" 'preserve_evidence_root_for_next_gate'
check 'probe contains no sudo invocation' not_contains "$probe" 'sudo '
check 'probe contains no ssh invocation' not_contains "$probe" 'ssh '
check 'probe contains no scp invocation' not_contains "$probe" 'scp '
check 'probe contains no slackpkg invocation' not_contains "$probe" 'slackpkg '
check 'probe contains no upgradepkg invocation' not_contains "$probe" 'upgradepkg '
check 'probe contains no installpkg invocation' not_contains "$probe" 'installpkg '
check 'probe contains no removepkg invocation' not_contains "$probe" 'removepkg '
check 'probe contains no bootloader mutation command' bash -c '! grep -Eq '"'"'(^|[[:space:]])(grub-install|grub-mkconfig|eliloconfig|lilo)([[:space:]]|$)'"'"' "$1"' _ "$probe"
check 'probe contains no reboot or shutdown command' bash -c '! grep -Eq '"'"'(^|[[:space:]])(reboot|shutdown|poweroff)([[:space:]]|$)'"'"' "$1"' _ "$probe"
check 'binding-review helper contains no network client command' bash -c '! grep -Eq '"'"'(^|[[:space:]])(curl|wget|ftp|rsync)([[:space:]]|$)'"'"' "$1"' _ "$helper"
check 'binding-review helper contains no package or boot mutation command' bash -c '! grep -Eq '"'"'(^|[[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|reboot|shutdown)([[:space:]]|$)'"'"' "$1"' _ "$helper"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
if bash "$helper" --output-dir "$TMP" >/dev/null && cmp -s "$policy" "$TMP/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review-policy.json" && cmp -s "$record" "$TMP/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.tsv"; then
    pass 'step-196 helper reproduces policy and record deterministically'
else
    fail 'step-196 helper reproduces policy and record deterministically'
fi

check 'reference document records exact archive origins' contains "$doc" 'slackware.uk/cumulative/slackware64-current/slackware64/d/kernel-headers-6.18.44-x86-1.txz'
check 'reference document records full signing-key fingerprint' contains "$doc" 'EC5649DA401E22ABFA6736EF6A4463C040102233'
check 'reference document records unprivileged controller-only acquisition' contains "$doc" 'without root privileges'
check 'reference document records target VM remains untouched and offline' contains "$doc" 'target VM remains untouched and offline'
check 'reference document records next binding-freeze stage' contains "$doc" 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze'
check 'CHANGELOG records step 196' contains "$changelog" '## Phase 1 step 196 kernel-package-edge package-pair and local-source binding review'

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
