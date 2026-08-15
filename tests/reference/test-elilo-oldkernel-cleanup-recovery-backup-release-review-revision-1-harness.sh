#!/usr/bin/env bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REVIEW="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-policy.json"
ACCEPTED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-reboot-verification-20260815-accepted.json"
FAILED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-20260815-failed-reviewed.json"

EXPECTED_REVIEW_SHA=009824cdf74feb180f9e570239d0dc7a147fbd388158e46862101f4667df4317
EXPECTED_POLICY_SHA=7f202b438fa011a50fc5196e7130e52ec1b0a2f81462e40acef101cc362cf502
EXPECTED_ACCEPTED_SHA=28b1d780e35ad2c0fa7cda2deaf372475b6967145f74b572f5b2eb8307dfcce0
EXPECTED_FAILED_SHA=c5d2d9fb44a0110ce0e26eb17e049e2c4e6cc16887eb3528f360c20a8148ab8d
EXPECTED_SCOPE=8927500b71fcd776b579b24cc1dcc4f1f863e22af6166ea16d1bfc3e89b2c4bd
EXPECTED_REMOVAL_TARGET=a18c56ff099c424cea5e16b3ec559debd8e54d7fec4968c6c0154dd2216831a8
EXPECTED_DIRECTORY_MANIFEST=eabe41e119b8a9233b0d19f4e6c57e3b6510bc59fb070ce3854a72fa99878d56

PASS=0
FAIL=0
pass(){ PASS=$((PASS+1)); printf 'PASS: %s\n' "$*"; }
fail(){ FAIL=$((FAIL+1)); printf 'FAIL: %s\n' "$*"; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
check_file(){ local f=$1 label=$2; [[ -f $f && ! -L $f ]] && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"; }

check_file "$REVIEW" "revision-1 release review"
check_file "$POLICY" "revision-1 policy"
check_file "$ACCEPTED" "accepted step-107 record"
check_file "$FAILED" "reviewed failed step-108 record"
[[ $(sha "$REVIEW") == "$EXPECTED_REVIEW_SHA" ]] && pass "revision review has the exact prepared SHA-256" || fail "revision review hash drifted"
[[ $(sha "$POLICY") == "$EXPECTED_POLICY_SHA" ]] && pass "revision policy has the exact prepared SHA-256" || fail "revision policy hash drifted"
[[ $(sha "$ACCEPTED") == "$EXPECTED_ACCEPTED_SHA" ]] && pass "accepted step-107 record has the exact reviewed SHA-256" || fail "accepted step-107 record hash drifted"
[[ $(sha "$FAILED") == "$EXPECTED_FAILED_SHA" ]] && pass "reviewed failed step-108 record has the exact diagnostic SHA-256" || fail "failed step-108 diagnostic hash drifted"

bash -n "$REVIEW" && pass "revision review is shell-syntax valid" || fail "revision review has shell syntax errors"
"$REVIEW" --help >/dev/null 2>&1 && pass "revision review exposes a non-mutating help boundary" || fail "revision-review help failed"
if "$REVIEW" --unknown-option >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

while IFS=$'\t' read -r mark label; do [[ $mark == PASSPY ]] && pass "$label" || fail "$label"; done < <(python3 - "$POLICY" "$ACCEPTED" "$FAILED" <<'PY'
import hashlib,json,sys
p=json.load(open(sys.argv[1])); a=json.load(open(sys.argv[2])); f=json.load(open(sys.argv[3]))
expected_members=["archive.sha256", "boot.before.sha256", "boot.tar", "modules-active-objects.before.sha256", "modules-active-stable.before.sha256", "modules-active.before.sha256", "modules-rollback.before.sha256", "modules.tar", "packages.before.txt", "pkgtools.tar"]
expected_hashes={"archive.sha256": "9e8e360dd455f64508cb28223ad17af3f8e983dca24de5af937971d2a6b70013", "boot.before.sha256": "95bbc279c56b63d088bc25a54abda0dcdf0e70fa920fc32b22260bfafe9fdec5", "boot.tar": "ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85", "modules-active-objects.before.sha256": "4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425", "modules-active-stable.before.sha256": "c01a1b554d3d2589ea880a15ff2d6d3a987e5bf743a45c9e47e74c92c5c3db76", "modules-active.before.sha256": "a284a504efad1e6bcd200ab6dd453cafad557b575f4231a25bb12f06bcd23695", "modules-rollback.before.sha256": "49fb193b78b668eaf5dba1788c1e18861e6c77f083e9e50c5edc2a57965eed26", "modules.tar": "ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781", "packages.before.txt": "b295eaa1abde0f961d21227d51988cead0a7794a298a5a980b19fb312d7b897a", "pkgtools.tar": "50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f"}
manifest=''.join(f"{expected_hashes[name]}  {name}\n" for name in sorted(expected_hashes))
checks=[
(p['schema']==1 and p['scenario']=='elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1','policy schema and revision scenario'),
(p['reviewed'] is True and p['revision_review_authorized'] is True,'revision-review gate'),
(all(p[k] is False for k in ['package_mutation_authorized','boot_mutation_authorized','recovery_backup_mutation_authorized','removal_execution_authorized','repository_refresh_authorized','network_access_authorized','reboot_authorized']),'all mutation, removal execution, refresh, network, and reboot actions remain denied'),
(a['accepted'] is True and a['post_reboot_verified'] is True and a['recovery_backup_release_ready'] is True,'accepted step-107 post-reboot boundary'),
(a['recovery_backup_retained'] is True and a['recovery_backup_removal_authorized'] is False,'step-107 still protects recovery removal'),
(f['diagnostic_accepted'] is True and f['release_review_passed'] is False,'failed step-108 evidence is accepted only as a diagnostic'),
(f['recovery_backup_removal_authorized'] is False and f['removal_executed'] is False,'failed step 108 did not authorize or execute removal'),
(f['diagnosis']['machine_state_drift'] is False,'diagnostic rules out real machine-state drift'),
(f['diagnosis']['module_manifest_representation_mismatch'] is True,'diagnostic records the module-path representation mismatch'),
(f['diagnosis']['module_object_count']==4652,'diagnostic binds all 4652 active module objects'),
(f['diagnosis']['normalized_module_manifest_sha256']==a['active_module_object_manifest_sha256'],'normalized failed-step-108 module manifest matches step 107'),
(f['diagnosis']['normalized_module_manifest_matches_step107'] is True,'normalized module comparison was accepted'),
(f['diagnosis']['actual_recovery_directory_member_count']==10,'diagnostic records the ten-file recovery snapshot'),
(f['diagnosis']['recovery_directory_members']==expected_members,'diagnostic binds the exact ten recovery member names'),
(f['diagnosis']['recovery_archives_hash_valid'] is True and f['diagnosis']['review_before_after_state_identical'] is True,'failed step 108 retained valid archives and was non-mutating'),
(p['failed_step108_record_sha256']=='c5d2d9fb44a0110ce0e26eb17e049e2c4e6cc16887eb3528f360c20a8148ab8d' and p['failed_step108_archive_sha256']=='d1da16ad0635c1db89eae273c953fd005b65759699e94e4878676f34fa575003','revision policy binds the reviewed failed step-108 evidence'),
(p['accepted_post_reboot_record_sha256']=='28b1d780e35ad2c0fa7cda2deaf372475b6967145f74b572f5b2eb8307dfcce0','revision policy binds accepted step 107'),
(p['expected_directory_members']==expected_members,'policy requires the exact ten-file recovery directory'),
(p['recovery_member_hashes']==expected_hashes,'policy binds every recovery member hash'),
(hashlib.sha256(manifest.encode()).hexdigest()==p['recovery_directory_manifest_sha256']=='eabe41e119b8a9233b0d19f4e6c57e3b6510bc59fb070ce3854a72fa99878d56','complete recovery-directory manifest hash is deterministic'),
(p['active_module_object_manifest_sha256']==a['active_module_object_manifest_sha256'],'revision preserves the accepted step-107 module baseline'),
(p['post_package_snapshot_sha256']==a['post_package_snapshot_sha256'],'revision preserves the accepted package baseline'),
(p['boot_state_sha256']==a['boot_state_sha256'] and p['elilo_conf_sha256']==a['elilo_conf_sha256'],'revision preserves boot and ELILO baselines'),
(p['recovery_manifest_sha256']==a['recovery_manifest_sha256'],'revision preserves the accepted three-archive manifest'),
(p['successful_result']['recovery_backup_removal_authorized'] is True and p['successful_result']['removal_executed'] is False,'a clean revision authorizes only a later removal boundary'),
(p['successful_result']['next_stage']=='elilo-oldkernel-cleanup-recovery-backup-authorized-removal','a clean revision advances only to separately gated removal')]
for ok,label in checks:
    print(('PASSPY' if ok else 'FAILPY')+'\t'+label)
PY
)

grep -Fq "printf '%s  ./%s\\n'" "$REVIEW" && pass "module capture restores the step-107 ./ path representation" || fail "step-107 module representation is not preserved"
grep -Fq "EXPECTED_MEMBERS=\$'archive.sha256\\tf" "$REVIEW" && pass "revision requires the complete ten-file recovery member set" || fail "ten-file member requirement is missing"
grep -Fq 'recovery-directory-manifest.before.sha256' "$REVIEW" && pass "revision hashes the complete recovery directory" || fail "complete recovery-directory hashing is missing"
grep -Fq 'cmp -s -- "$EXPECTED_RECOVERY_BACKUP_PATH/archive.sha256" "$WORKDIR/recovery.before.sha256"' "$REVIEW" && pass "revision validates retained archive.sha256 metadata against the three payloads" || fail "archive metadata consistency check is missing"
grep -Fq 'REMOVAL_TARGET_SHA256=' "$REVIEW" && pass "revision derives a deterministic ten-file removal target" || fail "ten-file removal target derivation is missing"
grep -Fq 'recovery_backup_removal_authorized=$RECOVERY_BACKUP_REMOVAL_AUTHORIZED' "$REVIEW" && pass "revision records removal authorization without execution" || fail "removal authorization result is missing"
grep -Fq 'removal_executed=false' "$REVIEW" && pass "revision explicitly records that removal was not executed" || fail "non-execution result is missing"
grep -Fq 'cmp -s -- "$WORKDIR/recovery-directory-manifest.before.sha256" "$WORKDIR/recovery-directory-manifest.after.sha256"' "$REVIEW" && pass "revision proves complete recovery data stayed unchanged" || fail "complete recovery immutability proof is missing"

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$REVIEW"; then fail "revision source contains a reboot or shutdown command"; else pass "revision source contains no reboot or shutdown command"; fi
if grep -Eq '(^|[[:space:];])(removepkg|upgradepkg|installpkg|slackpkg|eliloconfig)([[:space:];]|$)' "$REVIEW"; then fail "revision source contains package or ELILO mutation commands"; else pass "revision source contains no package-manager or ELILO mutation command"; fi
if grep -Eq '^[[:space:]]*(rm|rmdir|unlink)([[:space:]]|$)' "$REVIEW"; then fail "revision source contains recovery removal execution"; else pass "revision source contains no recovery removal execution"; fi
if grep -Eq '(^|[[:space:];])(curl|wget|ftp|rsync|scp)([[:space:];]|$)' "$REVIEW"; then fail "revision source contains a network client"; else pass "revision source contains no network client command"; fi

calc=$(printf '%s\n' \
  'scenario=elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1' \
  'accepted_post_reboot_archive_sha256=71b23d0175203eb6dc3ea5d8a93353c5eb68bb2bf49d83f7ae92f9a141fa4a1c' \
  "accepted_post_reboot_record_sha256=$EXPECTED_ACCEPTED_SHA" \
  'failed_step108_archive_sha256=d1da16ad0635c1db89eae273c953fd005b65759699e94e4878676f34fa575003' \
  "failed_step108_record_sha256=$EXPECTED_FAILED_SHA" \
  "release_review_policy_sha256=$EXPECTED_POLICY_SHA" \
  "release_review_script_sha256=$EXPECTED_REVIEW_SHA" \
  'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
  'active_kernel=5.15.209' \
  'rollback_kernel=5.15.19' \
  'accepted_boot_id=626f1a3a-606a-4dd3-8ff2-64d78032cadf' \
  'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' | sha256sum | awk '{print $1}')
[[ $calc == "$EXPECTED_SCOPE" ]] && pass "calculated revision confirmation scope matches the prepared boundary" || fail "revision confirmation scope mismatch"

removal_target=$(printf '%s\n' \
  'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' \
  "recovery_directory_manifest_sha256=$EXPECTED_DIRECTORY_MANIFEST" \
  'directory_members=archive.sha256,boot.before.sha256,boot.tar,modules-active-objects.before.sha256,modules-active-stable.before.sha256,modules-active.before.sha256,modules-rollback.before.sha256,modules.tar,packages.before.txt,pkgtools.tar' | sha256sum | awk '{print $1}')
[[ $removal_target == "$EXPECTED_REMOVAL_TARGET" ]] && pass "calculated future removal target matches all ten reviewed files" || fail "ten-file future removal-target hash mismatch"

grep -Fq '/home/promano/' "$REVIEW" && grep -Fq 'promano -g users' "$REVIEW" && pass "revision prints direct /home/promano evidence-copy commands with required ownership" || fail "evidence-copy contract is incomplete"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL -eq 0 ]] && printf PASS || printf FAIL)" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
