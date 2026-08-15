#!/usr/bin/env bash
set -u
set -o pipefail

export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REVIEW="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-removal-boot-rebind-review.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-removal-boot-rebind-review-policy.json"
FAILED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-20260815-failed-reviewed.json"
ACCEPTED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-revision-1-20260815-accepted.json"
STEP110_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-authorized-removal.sh"
STEP110_POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-authorized-removal-policy.json"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*"; }
sha_file() { sha256sum -- "$1" | awk '{print $1}'; }

EXPECTED_REVIEW_SHA=5bb8a9ad2f51911233d05d329476a54726323d9397d5d673124851176769fa38
EXPECTED_POLICY_SHA=3e2568307dba4ff8e58c597c8852b938e3a749eef7eb301431cdf68c29a219db
EXPECTED_FAILED_SHA=28a456406c19fcdb268abafb4c530851300d9ae8240b597f3cafc692faec4bfd
EXPECTED_ACCEPTED_SHA=3426de39e4d3eb21eca6529d3b91f4dee9d87b42914002c08b7afa5544cc9222
EXPECTED_STEP110_SCRIPT_SHA=82be2bd09936b1c3043858eb275e2ba20da776f50de4522a642b7132122c9c7d
EXPECTED_STEP110_POLICY_SHA=b30a648cf62323787dd2923d80d44fa2bde9a351b3fad78cec9fa2c450f47ab3
EXPECTED_FAILED_ARCHIVE=8cc762579a8e32f23c197d26bc260fcc375d8152645f56f69e5bbe2eff26c00f
EXPECTED_ACCEPTED_ARCHIVE=7c18beea914406dfe0354169b683839c14a03479e3a29dc869d1c2119facb624
EXPECTED_REBIND_SCOPE=fd9abf6be217a1ca08f7f3d8aa27f41dca3c4e95b31e66d4ab12ff27f4ec8976
EXPECTED_REMOVAL_TARGET=a18c56ff099c424cea5e16b3ec559debd8e54d7fec4968c6c0154dd2216831a8
EXPECTED_DIRECTORY_MANIFEST=eabe41e119b8a9233b0d19f4e6c57e3b6510bc59fb070ce3854a72fa99878d56

for spec in \
    "$REVIEW|boot-rebind review" \
    "$POLICY|boot-rebind policy" \
    "$FAILED|reviewed failed step-110 record" \
    "$ACCEPTED|accepted step-109 record" \
    "$STEP110_SCRIPT|failed step-110 removal script" \
    "$STEP110_POLICY|failed step-110 removal policy"; do
    path=${spec%%|*}; label=${spec#*|}
    if [[ -f $path && ! -L $path ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha_file "$REVIEW") == "$EXPECTED_REVIEW_SHA" ]] && pass "boot-rebind review has the exact prepared SHA-256" || fail "boot-rebind review SHA-256 mismatch"
[[ $(sha_file "$POLICY") == "$EXPECTED_POLICY_SHA" ]] && pass "boot-rebind policy has the exact prepared SHA-256" || fail "boot-rebind policy SHA-256 mismatch"
[[ $(sha_file "$FAILED") == "$EXPECTED_FAILED_SHA" ]] && pass "reviewed failed step-110 record has the exact diagnostic SHA-256" || fail "reviewed failed step-110 record SHA-256 mismatch"
[[ $(sha_file "$ACCEPTED") == "$EXPECTED_ACCEPTED_SHA" ]] && pass "accepted step-109 record remains byte-identical" || fail "accepted step-109 record SHA-256 mismatch"
[[ $(sha_file "$STEP110_SCRIPT") == "$EXPECTED_STEP110_SCRIPT_SHA" ]] && pass "failed step-110 removal script remains byte-identical" || fail "failed step-110 script SHA-256 mismatch"
[[ $(sha_file "$STEP110_POLICY") == "$EXPECTED_STEP110_POLICY_SHA" ]] && pass "failed step-110 removal policy remains byte-identical" || fail "failed step-110 policy SHA-256 mismatch"

bash -n "$REVIEW" >/dev/null 2>&1 && pass "boot-rebind review is shell-syntax valid" || fail "boot-rebind review has shell syntax errors"
"$REVIEW" --help >/dev/null 2>&1 && pass "boot-rebind review exposes a non-mutating help boundary" || fail "boot-rebind review help boundary failed"
if "$REVIEW" --definitely-unknown >/dev/null 2>&1; then fail "unknown options do not fail closed"; else pass "unknown options fail closed"; fi

while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done < <(python3 - "$POLICY" "$FAILED" "$ACCEPTED" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
f=json.load(open(sys.argv[2], encoding='utf-8'))
a=json.load(open(sys.argv[3], encoding='utf-8'))
expected_members=[
    'archive.sha256','boot.before.sha256','boot.tar','modules-active-objects.before.sha256',
    'modules-active-stable.before.sha256','modules-active.before.sha256','modules-rollback.before.sha256',
    'modules.tar','packages.before.txt','pkgtools.tar'
]
checks=[
    (p['schema']==1 and p['scenario']=='elilo-oldkernel-cleanup-recovery-backup-removal-boot-rebind-review','policy schema and boot-rebind scenario'),
    (p['reviewed'] is True and p['review_only'] is True and p['boot_rebind_review_authorized'] is True,'boot-rebind review gate is explicitly authorized'),
    (p['removal_execution_authorized'] is False and p['recovery_backup_mutation_authorized'] is False,'recovery removal and mutation remain disabled in step 111'),
    (all(p[k] is False for k in ['package_mutation_authorized','boot_mutation_authorized','module_mutation_authorized','repository_refresh_authorized','network_access_authorized','reboot_authorized']),'all system mutation, refresh, network, and reboot actions remain denied'),
    (p['transient_boot_id_equality_required'] is False and p['stable_boot_identity_required'] is True,'transient boot-id equality is replaced by stable boot identity'),
    (a['accepted'] is True and a['release_review_passed'] is True and a['recovery_backup_removal_authorized'] is True,'accepted step-109 removal authorization remains valid as the persistent baseline'),
    (a['archive_sha256']=='7c18beea914406dfe0354169b683839c14a03479e3a29dc869d1c2119facb624','accepted step-109 archive binding'),
    (f['diagnostic_accepted'] is True and f['archive_sha256']=='8cc762579a8e32f23c197d26bc260fcc375d8152645f56f69e5bbe2eff26c00f','failed step-110 diagnostic archive binding'),
    (f['removal_started'] is False and f['removed_file_count']==0 and f['removal_executed'] is False,'failed step 110 never entered the destructive boundary'),
    (f['recovery_backup_removed'] is False and f['recovery_backup_retained'] is True,'failed step 110 retained the complete recovery backup'),
    (f['system_state_preserved'] is True,'failed step 110 preserved system state'),
    (f['diagnosis']['observed_boot_id_differs_from_step109'] is True,'diagnostic records the transient boot-id mismatch'),
    (f['diagnosis']['persistent_package_baseline_matches'] is True,'diagnostic preserves the package baseline'),
    (f['diagnosis']['persistent_active_module_baseline_matches'] is True,'diagnostic preserves the active-module baseline'),
    (f['diagnosis']['persistent_rollback_absence_baseline_matches'] is True,'diagnostic preserves rollback-module absence'),
    (f['diagnosis']['persistent_boot_state_baseline_matches'] is True and f['diagnosis']['persistent_elilo_baseline_matches'] is True,'diagnostic preserves boot and ELILO baselines'),
    (f['diagnosis']['recovery_directory_manifest_matches'] is True and f['diagnosis']['recovery_payload_manifest_matches'] is True,'diagnostic preserves the exact recovery snapshot'),
    (f['diagnosis']['destructive_boundary_entered'] is False and f['diagnosis']['partial_removal_occurred'] is False,'diagnostic explicitly rules out partial removal'),
    (p['accepted_release_record_sha256']=='3426de39e4d3eb21eca6529d3b91f4dee9d87b42914002c08b7afa5544cc9222','policy binds the exact accepted step-109 record'),
    (p['accepted_release_archive_sha256']==a['archive_sha256'],'policy and accepted record bind the same step-109 archive'),
    (p['failed_step110_record_sha256']=='28a456406c19fcdb268abafb4c530851300d9ae8240b597f3cafc692faec4bfd','policy binds the exact reviewed failed step-110 record'),
    (p['failed_step110_archive_sha256']==f['archive_sha256'],'policy and diagnostic bind the same failed step-110 archive'),
    (p['failed_step110_script_sha256']=='82be2bd09936b1c3043858eb275e2ba20da776f50de4522a642b7132122c9c7d','policy binds the exact failed step-110 code'),
    (p['failed_step110_policy_sha256']=='b30a648cf62323787dd2923d80d44fa2bde9a351b3fad78cec9fa2c450f47ab3','policy binds the exact failed step-110 policy'),
    (p['hostname_fqdn']==a['hostname_fqdn']==f['hostname_fqdn']=='vbox-slack15.vbox-slack15.org','host binding'),
    (p['active_kernel']==a['active_kernel']==f['active_kernel']=='5.15.209' and p['rollback_kernel']==a['rollback_kernel']==f['rollback_kernel']=='5.15.19','kernel binding'),
    (p['previous_accepted_boot_id']==a['accepted_boot_id']==f['previously_accepted_boot_id'],'previous accepted boot-id is retained only as diagnostic history'),
    (p['failed_step110_observed_boot_id']==f['observed_boot_id']=='a67cdf84-8ae2-4b3d-96e9-7c4cfc7bd8a3','failed boot-id observation binding'),
    (p['required_boot_image_suffix']=='\\EFI\\Slackware\\vmlinuz-generic-5.15.209','stable versioned BOOT_IMAGE suffix binding'),
    (p['recovery_backup_path']==a['recovery_backup_path']==f['recovery_backup_path'],'exact recovery path binding'),
    (p['post_package_snapshot_sha256']==a['post_package_snapshot_sha256']==f['evidence_members']['packages_before_sha256'],'package baseline binding'),
    (p['active_module_object_manifest_sha256']==a['active_module_object_manifest_sha256']==f['evidence_members']['modules_active_before_sha256'],'active module baseline binding'),
    (p['rollback_module_objects_manifest_sha256']==a['rollback_module_objects_manifest_sha256']==f['evidence_members']['modules_rollback_before_sha256'],'rollback absence baseline binding'),
    (p['boot_state_sha256']==a['boot_state_sha256']==f['evidence_members']['boot_state_before_sha256'],'boot-state baseline binding'),
    (p['elilo_conf_sha256']==a['elilo_conf_sha256']==f['evidence_members']['elilo_before_sha256'],'ELILO baseline binding'),
    (p['recovery_manifest_sha256']==a['recovery_manifest_sha256']==f['evidence_members']['recovery_payload_manifest_sha256'],'recovery payload manifest binding'),
    (p['recovery_directory_manifest_sha256']==a['recovery_directory_manifest_sha256']==f['evidence_members']['recovery_directory_manifest_sha256'],'complete recovery-directory manifest binding'),
    (p['removal_target_sha256']==a['removal_target_sha256']==f['removal_target_sha256'],'exact future destructive target binding'),
    (p['expected_directory_members']==a['expected_directory_members']==expected_members,'exact ten-file recovery member set'),
    (p['successful_result']['rebind_review_passed'] is True and p['successful_result']['stable_boot_identity_verified'] is True,'successful review requires stable boot identity verification'),
    (p['successful_result']['transient_boot_id_equality_required'] is False,'successful review explicitly releases transient boot-id equality'),
    (p['successful_result']['recovery_backup_retained'] is True and p['successful_result']['recovery_backup_removal_reauthorized'] is True and p['successful_result']['removal_executed'] is False,'successful review reauthorizes but never executes removal'),
    (p['successful_result']['pause_safe'] is True and p['successful_result']['next_stage']=='elilo-oldkernel-cleanup-recovery-backup-authorized-removal-revision-1','successful review establishes a safe pause and advances only to revised removal')
]
for ok,label in checks:
    print(('PASS' if ok else 'FAIL')+'\t'+label)
PY
)

grep -Fq 'RUNNING_KERNEL == "$EXPECTED_ACTIVE_KERNEL"' "$REVIEW" && pass "runtime review requires the exact active kernel" || fail "exact running-kernel check is missing"
grep -Fq 'BOOT_IMAGE == *"$EXPECTED_BOOT_IMAGE_SUFFIX"' "$REVIEW" && pass "runtime review requires the exact versioned ELILO BOOT_IMAGE suffix" || fail "stable BOOT_IMAGE check is missing"
grep -Fq 'CURRENT_BOOT_ID =~ ^[0-9a-f]' "$REVIEW" && pass "current boot ID is validated as an evidence identifier" || fail "current boot-ID syntax validation is missing"
if grep -Fq 'CURRENT_BOOT_ID == "$' "$REVIEW"; then fail "review still requires equality to a transient boot ID"; else pass "review does not require equality to any transient boot ID"; fi
grep -Fq 'proc-cmdline.txt' "$REVIEW" && grep -Fq 'boot-image.txt' "$REVIEW" && pass "runtime boot identity is captured as evidence" || fail "runtime boot-identity evidence capture is incomplete"
grep -Fq 'capture_all_state before' "$REVIEW" && grep -Fq 'capture_all_state after' "$REVIEW" && pass "persistent state is captured before and after review" || fail "before/after state capture is incomplete"
grep -Fq 'EXPECTED_MEMBERS' "$REVIEW" && pass "review requires the exact ten-file recovery member set" || fail "exact recovery member-set check is missing"
grep -Fq 'recovery-directory-manifest' "$REVIEW" && pass "review hashes the complete recovery directory" || fail "complete recovery-directory hashing is missing"
grep -Fq 'RECOVERY_BACKUP_REMOVAL_REAUTHORIZED=true' "$REVIEW" && pass "successful review records removal reauthorization" || fail "removal reauthorization result is missing"
grep -Fq 'removal_executed=false' "$REVIEW" && pass "review explicitly records that removal was not executed" || fail "non-execution result is missing"
grep -Fq 'PAUSE_SAFE=true' "$REVIEW" && pass "successful review establishes a safe pause" || fail "safe-pause result is missing"

if grep -Eq '(^|[[:space:];])(unlink|rmdir|rm)([[:space:];]|$)' "$REVIEW"; then fail "boot-rebind review source contains recovery removal execution"; else pass "boot-rebind review source contains no recovery removal execution"; fi
if grep -Eq '(^|[[:space:];])(removepkg|upgradepkg|installpkg|slackpkg|eliloconfig)([[:space:];]|$)' "$REVIEW"; then fail "boot-rebind review source contains package or ELILO mutation commands"; else pass "boot-rebind review source contains no package-manager or ELILO mutation command"; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$REVIEW"; then fail "boot-rebind review source contains reboot or shutdown execution"; else pass "boot-rebind review source contains no reboot or shutdown execution"; fi
if grep -Eq '(^|[[:space:];])(curl|wget|ftp|rsync|scp)([[:space:];]|$)' "$REVIEW"; then fail "boot-rebind review source contains a network client"; else pass "boot-rebind review source contains no network client command"; fi

calc=$(printf '%s\n' \
    'scenario=elilo-oldkernel-cleanup-recovery-backup-removal-boot-rebind-review' \
    "accepted_release_archive_sha256=$EXPECTED_ACCEPTED_ARCHIVE" \
    "accepted_release_record_sha256=$EXPECTED_ACCEPTED_SHA" \
    "failed_step110_archive_sha256=$EXPECTED_FAILED_ARCHIVE" \
    "failed_step110_record_sha256=$EXPECTED_FAILED_SHA" \
    "failed_step110_script_sha256=$EXPECTED_STEP110_SCRIPT_SHA" \
    "failed_step110_policy_sha256=$EXPECTED_STEP110_POLICY_SHA" \
    "rebind_policy_sha256=$EXPECTED_POLICY_SHA" \
    "rebind_script_sha256=$EXPECTED_REVIEW_SHA" \
    'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
    'active_kernel=5.15.209' \
    'rollback_kernel=5.15.19' \
    'required_boot_image_suffix=\EFI\Slackware\vmlinuz-generic-5.15.209' \
    'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' \
    "removal_target_sha256=$EXPECTED_REMOVAL_TARGET" | sha256sum | awk '{print $1}')
[[ $calc == "$EXPECTED_REBIND_SCOPE" ]] && pass "calculated boot-rebind confirmation scope matches the prepared immutable boundary" || fail "boot-rebind confirmation scope mismatch"

grep -Fq '/home/promano/' "$REVIEW" && grep -Fq 'promano -g users' "$REVIEW" && pass "review prints direct /home/promano evidence-copy commands with required ownership" || fail "evidence-copy contract is incomplete"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL -eq 0 ]] && printf PASS || printf FAIL)" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
