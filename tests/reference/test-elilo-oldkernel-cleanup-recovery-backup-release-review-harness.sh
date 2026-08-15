#!/usr/bin/env bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REVIEW="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-recovery-backup-release-review.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-recovery-backup-release-review-policy.json"
ACCEPTED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-reboot-verification-20260815-accepted.json"
EXPECTED_REVIEW_SHA=f9d9f69ce33f0ac88ad514dd0955ff578a0ee552fbd0ce34b518fc0f48b5961e
EXPECTED_POLICY_SHA=107799edcc26434e331634375301b1a39520fa6b1d479d445f7a106646b7260e
EXPECTED_ACCEPTED_SHA=28b1d780e35ad2c0fa7cda2deaf372475b6967145f74b572f5b2eb8307dfcce0
EXPECTED_SCOPE=7db595eea0276ee21bcc15be5c05d338b6d121a1b94d565d55943a6ed1ed1049
EXPECTED_REMOVAL_TARGET=fb4798006e393ce84856c7afed4484aaaa2990952dcc9928f0787c56fb57874d

PASS=0
FAIL=0
pass(){ PASS=$((PASS+1)); printf 'PASS: %s\n' "$*"; }
fail(){ FAIL=$((FAIL+1)); printf 'FAIL: %s\n' "$*"; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
check_file(){ local f=$1 label=$2; [[ -f $f && ! -L $f ]] && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"; }

check_file "$REVIEW" "recovery-backup release review"
check_file "$POLICY" "release-review policy"
check_file "$ACCEPTED" "accepted step-107 record"
[[ $(sha "$REVIEW") == "$EXPECTED_REVIEW_SHA" ]] && pass "release-review script has the exact prepared SHA-256" || fail "release-review script hash drifted"
[[ $(sha "$POLICY") == "$EXPECTED_POLICY_SHA" ]] && pass "release-review policy has the exact prepared SHA-256" || fail "release-review policy hash drifted"
[[ $(sha "$ACCEPTED") == "$EXPECTED_ACCEPTED_SHA" ]] && pass "accepted step-107 record has the exact reviewed SHA-256" || fail "accepted step-107 record hash drifted"
bash -n "$REVIEW" && pass "release-review script is shell-syntax valid" || fail "release-review script has shell syntax errors"
"$REVIEW" --help >/dev/null 2>&1 && pass "release review exposes a non-mutating help boundary" || fail "release-review help failed"
if "$REVIEW" --unknown-option >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

while IFS=$'\t' read -r mark label; do [[ $mark == PASSPY ]] && pass "$label" || fail "$label"; done < <(python3 - "$POLICY" "$ACCEPTED" <<'PY'
import json,sys
p=json.load(open(sys.argv[1])); a=json.load(open(sys.argv[2]))
checks=[
(p['schema']==1 and p['scenario']=='elilo-oldkernel-cleanup-recovery-backup-release-review','policy schema and scenario'),
(p['reviewed'] is True and p['release_review_authorized'] is True,'release-review gate'),
(all(p[k] is False for k in ['package_mutation_authorized','boot_mutation_authorized','recovery_backup_mutation_authorized','removal_execution_authorized','repository_refresh_authorized','network_access_authorized','reboot_authorized']),'all mutation, removal execution, refresh, network, and reboot actions remain denied'),
(a['accepted'] is True and a['post_reboot_verified'] is True and a['recovery_backup_release_ready'] is True,'accepted step-107 post-reboot boundary'),
(a['recovery_backup_retained'] is True and a['recovery_backup_removal_authorized'] is False,'step-107 record keeps the backup retained and removal unauthorized'),
(a['archive_sha256']==p['accepted_post_reboot_archive_sha256'],'accepted post-reboot archive binding'),
(a['current_boot_id']==p['accepted_boot_id'],'accepted successful boot identity binding'),
(a['post_package_snapshot_sha256']==p['post_package_snapshot_sha256'],'package snapshot binding'),
(a['active_module_object_manifest_sha256']==p['active_module_object_manifest_sha256'],'active module manifest binding'),
(a['rollback_module_objects_manifest_sha256']==p['rollback_module_objects_manifest_sha256'],'rollback module absence binding'),
(a['boot_state_sha256']==p['boot_state_sha256'] and a['elilo_conf_sha256']==p['elilo_conf_sha256'],'boot and ELILO binding'),
(a['recovery_manifest_sha256']==p['recovery_manifest_sha256'],'recovery manifest binding'),
(a['recovery_archives']['boot.tar']==p['recovery_archives']['boot_tar'] and a['recovery_archives']['modules.tar']==p['recovery_archives']['modules_tar'] and a['recovery_archives']['pkgtools.tar']==p['recovery_archives']['pkgtools_tar'],'all three recovery archive hashes are bound'),
(p['expected_directory_members']==['boot.tar','modules.tar','pkgtools.tar'],'exact recovery-directory member set'),
(p['removal_target_sha256']=='fb4798006e393ce84856c7afed4484aaaa2990952dcc9928f0787c56fb57874d','exact future removal target binding'),
(p['successful_result']['recovery_backup_removal_authorized'] is True and p['successful_result']['removal_executed'] is False,'successful review authorizes only a later removal boundary'),
(p['successful_result']['next_stage']=='elilo-oldkernel-cleanup-recovery-backup-authorized-removal','successful review advances only to separately gated removal')]
for ok,label in checks: print(('PASSPY' if ok else 'FAILPY')+'\t'+label)
PY
)

grep -Fq 'CURRENT_BOOT_ID == "$EXPECTED_BOOT_ID"' "$REVIEW" && pass "release review requires the same boot that passed step 107" || fail "same-boot binding is missing"
grep -Fq 'recovery-directory-members.before.txt' "$REVIEW" && pass "release review captures exact recovery-directory membership" || fail "recovery-directory membership capture is missing"
grep -Fq "EXPECTED_MEMBERS=\$'boot.tar\\tf\\nmodules.tar\\tf\\npkgtools.tar\\tf'" "$REVIEW" && pass "release review requires exactly three regular recovery archives" || fail "exact regular-file member requirement is missing"
grep -Fq 'REMOVAL_TARGET_SHA256=' "$REVIEW" && pass "release review derives a deterministic future removal target" || fail "future removal-target derivation is missing"
grep -Fq 'recovery_backup_removal_authorized=$RECOVERY_BACKUP_REMOVAL_AUTHORIZED' "$REVIEW" && pass "release review records removal authorization without executing removal" || fail "removal-authorization result is missing"
grep -Fq 'removal_executed=false' "$REVIEW" && pass "release review explicitly records that removal was not executed" || fail "non-execution result is missing"
grep -Fq 'cmp -s -- "$WORKDIR/recovery-directory-members.before.txt" "$WORKDIR/recovery-directory-members.after.txt"' "$REVIEW" && pass "release review proves recovery-directory membership stayed unchanged" || fail "recovery-directory immutability proof is missing"

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$REVIEW"; then fail "release-review source contains a reboot or shutdown execution command"; else pass "release-review source contains no reboot or shutdown execution command"; fi
if grep -Eq '(^|[[:space:];])(removepkg|upgradepkg|installpkg|slackpkg|eliloconfig)([[:space:];]|$)' "$REVIEW"; then fail "release-review source contains package or ELILO mutation commands"; else pass "release-review source contains no package-manager or ELILO mutation command"; fi
if grep -Eq '^[[:space:]]*(rm|rmdir|unlink)([[:space:]]|$)' "$REVIEW"; then fail "release-review source contains a recovery removal execution command"; else pass "release-review source contains no recovery removal execution command"; fi
if grep -Eq '(^|[[:space:];])(curl|wget|ftp|rsync|scp)([[:space:];]|$)' "$REVIEW"; then fail "release-review source contains a network client command"; else pass "release-review source contains no network client command"; fi

calc=$(printf '%s\n' \
  'scenario=elilo-oldkernel-cleanup-recovery-backup-release-review' \
  'accepted_post_reboot_archive_sha256=71b23d0175203eb6dc3ea5d8a93353c5eb68bb2bf49d83f7ae92f9a141fa4a1c' \
  "accepted_post_reboot_record_sha256=$EXPECTED_ACCEPTED_SHA" \
  "release_review_policy_sha256=$EXPECTED_POLICY_SHA" \
  "release_review_script_sha256=$EXPECTED_REVIEW_SHA" \
  'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
  'active_kernel=5.15.209' \
  'rollback_kernel=5.15.19' \
  'accepted_boot_id=626f1a3a-606a-4dd3-8ff2-64d78032cadf' \
  'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' | sha256sum | awk '{print $1}')
[[ $calc == "$EXPECTED_SCOPE" ]] && pass "calculated release confirmation scope matches the prepared immutable boundary" || fail "release confirmation scope mismatch"

removal_target=$(printf '%s\n' \
  'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' \
  'boot.tar=ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85' \
  'modules.tar=ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781' \
  'pkgtools.tar=50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f' \
  'directory_members=boot.tar,modules.tar,pkgtools.tar' | sha256sum | awk '{print $1}')
[[ $removal_target == "$EXPECTED_REMOVAL_TARGET" ]] && pass "calculated future removal target matches the reviewed exact directory contents" || fail "future removal-target hash mismatch"

grep -Fq '/home/promano/' "$REVIEW" && grep -Fq 'promano -g users' "$REVIEW" && pass "release review prints direct /home/promano evidence-copy commands with required ownership" || fail "evidence-copy contract is incomplete"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL -eq 0 ]] && printf PASS || printf FAIL)" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
