#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REMOVAL="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-authorized-removal.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-policy.json"
ACCEPTED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-20260815-accepted.json"
STEP109_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1.sh"
STEP109_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-policy.json"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*"; }
sha_file() { sha256sum -- "$1" | awk '{print $1}'; }

EXPECTED_REMOVAL_SHA=82be2bd09936b1c3043858eb275e2ba20da776f50de4522a642b7132122c9c7d
EXPECTED_POLICY_SHA=b30a648cf62323787dd2923d80d44fa2bde9a351b3fad78cec9fa2c450f47ab3
EXPECTED_ACCEPTED_SHA=3426de39e4d3eb21eca6529d3b91f4dee9d87b42914002c08b7afa5544cc9222
EXPECTED_STEP109_SCRIPT_SHA=009824cdf74feb180f9e570239d0dc7a147fbd388158e46862101f4667df4317
EXPECTED_STEP109_POLICY_SHA=7f202b438fa011a50fc5196e7130e52ec1b0a2f81462e40acef101cc362cf502
EXPECTED_REMOVAL_SCOPE=06214a3fdc5a04e9221829e775587ea280bd5bc06587d1fd0ee300bf3a430626
EXPECTED_REMOVAL_TARGET=a18c56ff099c424cea5e16b3ec559debd8e54d7fec4968c6c0154dd2216831a8
EXPECTED_DIRECTORY_MANIFEST=eabe41e119b8a9233b0d19f4e6c57e3b6510bc59fb070ce3854a72fa99878d56

for spec in \
    "$REMOVAL|authorized removal" \
    "$POLICY|removal policy" \
    "$ACCEPTED|accepted step-109 record" \
    "$STEP109_SCRIPT|step-109 release-review script" \
    "$STEP109_POLICY|step-109 release-review policy"; do
    path=${spec%%|*}; label=${spec#*|}
    if [[ -f $path && ! -L $path ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha_file "$REMOVAL") == "$EXPECTED_REMOVAL_SHA" ]] && pass "authorized removal has the exact prepared SHA-256" || fail "authorized removal SHA-256 mismatch"
[[ $(sha_file "$POLICY") == "$EXPECTED_POLICY_SHA" ]] && pass "removal policy has the exact prepared SHA-256" || fail "removal policy SHA-256 mismatch"
[[ $(sha_file "$ACCEPTED") == "$EXPECTED_ACCEPTED_SHA" ]] && pass "accepted step-109 record has the exact reviewed SHA-256" || fail "accepted step-109 SHA-256 mismatch"
[[ $(sha_file "$STEP109_SCRIPT") == "$EXPECTED_STEP109_SCRIPT_SHA" ]] && pass "step-109 release-review script remains byte-identical" || fail "step-109 script SHA-256 mismatch"
[[ $(sha_file "$STEP109_POLICY") == "$EXPECTED_STEP109_POLICY_SHA" ]] && pass "step-109 release-review policy remains byte-identical" || fail "step-109 policy SHA-256 mismatch"

bash -n "$REMOVAL" >/dev/null 2>&1 && pass "authorized removal is shell-syntax valid" || fail "authorized removal has shell syntax errors"
"$REMOVAL" --help >/dev/null 2>&1 && pass "authorized removal exposes a non-mutating help boundary" || fail "authorized removal help boundary failed"
if "$REMOVAL" --definitely-unknown >/dev/null 2>&1; then fail "unknown options do not fail closed"; else pass "unknown options fail closed"; fi

while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done < <(python3 - "$POLICY" "$ACCEPTED" <<'PY'
import hashlib, json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
a=json.load(open(sys.argv[2], encoding='utf-8'))
expected_members=[
    'archive.sha256','boot.before.sha256','boot.tar','modules-active-objects.before.sha256',
    'modules-active-stable.before.sha256','modules-active.before.sha256','modules-rollback.before.sha256',
    'modules.tar','packages.before.txt','pkgtools.tar'
]
expected_hashes={
    'archive.sha256':'9e8e360dd455f64508cb28223ad17af3f8e983dca24de5af937971d2a6b70013',
    'boot.before.sha256':'95bbc279c56b63d088bc25a54abda0dcdf0e70fa920fc32b22260bfafe9fdec5',
    'boot.tar':'ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85',
    'modules-active-objects.before.sha256':'4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425',
    'modules-active-stable.before.sha256':'c01a1b554d3d2589ea880a15ff2d6d3a987e5bf743a45c9e47e74c92c5c3db76',
    'modules-active.before.sha256':'a284a504efad1e6bcd200ab6dd453cafad557b575f4231a25bb12f06bcd23695',
    'modules-rollback.before.sha256':'49fb193b78b668eaf5dba1788c1e18861e6c77f083e9e50c5edc2a57965eed26',
    'modules.tar':'ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781',
    'packages.before.txt':'b295eaa1abde0f961d21227d51988cead0a7794a298a5a980b19fb312d7b897a',
    'pkgtools.tar':'50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f'
}
checks=[
    (p['schema']==1 and p['scenario']=='elilo-oldkernel-cleanup-recovery-backup-authorized-removal','policy schema and removal scenario'),
    (p['reviewed'] is True and p['removal_execution_authorized'] is True and p['recovery_backup_mutation_authorized'] is True,'destructive removal gate is explicitly authorized'),
    (all(p[k] is False for k in ['package_mutation_authorized','boot_mutation_authorized','module_mutation_authorized','repository_refresh_authorized','network_access_authorized','reboot_authorized']),'all non-recovery system mutation, refresh, network, and reboot actions remain denied'),
    (p['recursive_removal_authorized'] is False and p['glob_removal_authorized'] is False and p['parent_removal_authorized'] is False,'recursive, glob, and parent removal remain denied'),
    (a['accepted'] is True and a['release_review_passed'] is True,'step-109 release review is explicitly accepted'),
    (a['recovery_backup_retained'] is True and a['recovery_backup_removal_authorized'] is True and a['removal_executed'] is False,'step-109 authorized removal without executing it'),
    (a['archive_sha256']=='7c18beea914406dfe0354169b683839c14a03479e3a29dc869d1c2119facb624','accepted step-109 archive binding'),
    (p['accepted_release_record_sha256']=='3426de39e4d3eb21eca6529d3b91f4dee9d87b42914002c08b7afa5544cc9222','policy binds the exact accepted step-109 record'),
    (p['accepted_release_archive_sha256']==a['archive_sha256'],'policy and accepted record bind the same step-109 archive'),
    (p['accepted_release_review_script_sha256']==a['release_review_script_sha256']=='009824cdf74feb180f9e570239d0dc7a147fbd388158e46862101f4667df4317','step-109 review code binding'),
    (p['accepted_release_review_policy_sha256']==a['release_review_policy_sha256']=='7f202b438fa011a50fc5196e7130e52ec1b0a2f81462e40acef101cc362cf502','step-109 policy binding'),
    (p['hostname_fqdn']==a['hostname_fqdn']=='vbox-slack15.vbox-slack15.org','host binding'),
    (p['active_kernel']==a['active_kernel']=='5.15.209' and p['rollback_kernel']==a['rollback_kernel']=='5.15.19','kernel binding'),
    (p['accepted_boot_id']==a['accepted_boot_id']=='626f1a3a-606a-4dd3-8ff2-64d78032cadf','accepted boot identity binding'),
    (p['recovery_backup_path']==a['recovery_backup_path']=='/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z','exact recovery path binding'),
    (p['post_package_snapshot_sha256']==a['post_package_snapshot_sha256'],'package baseline binding'),
    (p['active_module_object_manifest_sha256']==a['active_module_object_manifest_sha256'],'active module baseline binding'),
    (p['rollback_module_objects_manifest_sha256']==a['rollback_module_objects_manifest_sha256'],'rollback absence baseline binding'),
    (p['boot_state_sha256']==a['boot_state_sha256'] and p['elilo_conf_sha256']==a['elilo_conf_sha256'],'boot and ELILO baseline binding'),
    (p['recovery_manifest_sha256']==a['recovery_manifest_sha256'],'recovery payload manifest binding'),
    (p['expected_directory_members']==a['expected_directory_members']==expected_members,'exact ten-file recovery member set'),
    (p['recovery_member_hashes']==a['recovery_member_hashes']==expected_hashes,'every recovery file hash is bound'),
    (p['recovery_directory_manifest_sha256']==a['recovery_directory_manifest_sha256']=='eabe41e119b8a9233b0d19f4e6c57e3b6510bc59fb070ce3854a72fa99878d56','complete recovery-directory manifest binding'),
    (p['removal_target_sha256']==a['removal_target_sha256']=='a18c56ff099c424cea5e16b3ec559debd8e54d7fec4968c6c0154dd2216831a8','exact destructive target binding'),
    (p['successful_result']['removal_executed'] is True and p['successful_result']['recovery_backup_removed'] is True and p['successful_result']['recovery_backup_retained'] is False,'successful result requires complete backup removal'),
    (p['successful_result']['system_state_preserved'] is True and p['successful_result']['pause_safe'] is True,'successful result requires unchanged system state and safe pause'),
    (p['successful_result']['next_stage']=='elilo-oldkernel-cleanup-recovery-backup-post-removal-verification','successful result advances only to post-removal verification')
]
for ok,label in checks:
    print(('PASS' if ok else 'FAIL')+'\t'+label)
PY
)

grep -Fq -- '--execute-authorized-removal' "$REMOVAL" && pass "destructive execution requires an explicit command-line gate" || fail "explicit destructive execution gate is missing"
grep -Fq 'if [[ $FAIL_COUNT -eq 0 ]]; then' "$REMOVAL" && pass "removal starts only after a clean pre-removal boundary" || fail "clean pre-removal gate is missing"
grep -Fq 'CURRENT_BOOT_ID == "$EXPECTED_BOOT_ID"' "$REMOVAL" && pass "removal requires the exact boot accepted by step 109" || fail "accepted boot identity check is missing"
grep -Fq 'ACTUAL_MEMBERS == "$EXPECTED_MEMBERS"' "$REMOVAL" && pass "removal requires the exact ten-file member set immediately before mutation" || fail "exact member-set check is missing"
grep -Fq 'recovery-directory-manifest.before.sha256' "$REMOVAL" && pass "removal validates the complete recovery-directory hash manifest" || fail "complete recovery manifest validation is missing"
grep -Fq 'unlink -- "$path"' "$REMOVAL" && pass "each reviewed recovery file is removed with unlink" || fail "exact-file unlink execution is missing"
grep -Fq 'expected_member_sha256=$(json_map_value "$POLICY" recovery_member_hashes "$name")' "$REMOVAL" && pass "each file hash is revalidated immediately before unlink" || fail "per-file last-moment hash validation is missing"
grep -Fq 'rmdir -- "$EXPECTED_RECOVERY_BACKUP_PATH"' "$REMOVAL" && pass "only the now-empty exact recovery directory is removed with rmdir" || fail "exact directory rmdir is missing"
grep -Fq 'REMOVED_COUNT -eq ${#MEMBERS[@]}' "$REMOVAL" && pass "directory removal requires all ten exact unlinks to complete" || fail "complete unlink-count gate is missing"
grep -Fq 'capture_system_state before' "$REMOVAL" && grep -Fq 'capture_system_state after' "$REMOVAL" && pass "system state is captured before and after destructive removal" || fail "before/after system-state capture is incomplete"
grep -Fq 'SYSTEM_STATE_PRESERVED=true' "$REMOVAL" && pass "successful removal explicitly proves system-state preservation" || fail "system-state preservation result is missing"
grep -Fq 'recovery-path.after.txt' "$REMOVAL" && pass "post-removal evidence records recovery-path absence" || fail "post-removal recovery-path evidence is missing"
grep -Fq 'PAUSE_SAFE=true' "$REMOVAL" && pass "successful complete removal establishes a safe pause" || fail "safe-pause result is missing"

if grep -Eq '(^|[[:space:];])rm[[:space:]]' "$REMOVAL"; then fail "removal source contains rm"; else pass "removal source contains no rm command"; fi
if grep -Fq 'rm -rf' "$REMOVAL" || grep -Fq 'rm -r' "$REMOVAL"; then fail "removal source contains recursive rm"; else pass "removal source contains no recursive rm"; fi
if grep -Eq 'unlink[^\n]*\*|rmdir[^\n]*\*' "$REMOVAL"; then fail "removal source uses a glob in destructive commands"; else pass "destructive commands contain no glob"; fi
if grep -Eq '(^|[[:space:];])(removepkg|upgradepkg|installpkg|slackpkg|eliloconfig)([[:space:];]|$)' "$REMOVAL"; then fail "removal source contains package or ELILO mutation commands"; else pass "removal source contains no package-manager or ELILO mutation command"; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$REMOVAL"; then fail "removal source contains reboot or shutdown execution"; else pass "removal source contains no reboot or shutdown execution"; fi
if grep -Eq '(^|[[:space:];])(curl|wget|ftp|rsync|scp)([[:space:];]|$)' "$REMOVAL"; then fail "removal source contains a network client"; else pass "removal source contains no network client command"; fi

calc=$(printf '%s\n' \
    'scenario=elilo-oldkernel-cleanup-recovery-backup-authorized-removal' \
    'accepted_release_archive_sha256=7c18beea914406dfe0354169b683839c14a03479e3a29dc869d1c2119facb624' \
    "accepted_release_record_sha256=$EXPECTED_ACCEPTED_SHA" \
    "accepted_release_review_script_sha256=$EXPECTED_STEP109_SCRIPT_SHA" \
    "accepted_release_review_policy_sha256=$EXPECTED_STEP109_POLICY_SHA" \
    "removal_policy_sha256=$EXPECTED_POLICY_SHA" \
    "removal_script_sha256=$EXPECTED_REMOVAL_SHA" \
    'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
    'active_kernel=5.15.209' \
    'rollback_kernel=5.15.19' \
    'accepted_boot_id=626f1a3a-606a-4dd3-8ff2-64d78032cadf' \
    'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' \
    "recovery_directory_manifest_sha256=$EXPECTED_DIRECTORY_MANIFEST" \
    "removal_target_sha256=$EXPECTED_REMOVAL_TARGET" | sha256sum | awk '{print $1}')
[[ $calc == "$EXPECTED_REMOVAL_SCOPE" ]] && pass "calculated destructive confirmation scope matches the prepared immutable boundary" || fail "destructive confirmation scope mismatch"

grep -Fq '/home/promano/' "$REMOVAL" && grep -Fq 'promano -g users' "$REMOVAL" && pass "removal prints direct /home/promano evidence-copy commands with required ownership" || fail "evidence-copy contract is incomplete"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL -eq 0 ]] && printf PASS || printf FAIL)" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
