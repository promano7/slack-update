#!/usr/bin/env bash
set -u
set -o pipefail
export LC_ALL=C
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
VERIFY="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-post-reboot-verification.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-reboot-verification-policy.json"
ACCEPTED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-apply-reboot-review-20260815-accepted.json"
EXPECTED_VERIFY_SHA=797d1876b07ff8459df937566c2aa40c629396ee161843566d9f063f8eeb870a
EXPECTED_POLICY_SHA=0f8d00197d61d2609aa8e7cf4a5601d4a4282d9ebb4d9de8103d0b897658b7d3
EXPECTED_ACCEPTED_SHA=0cf844a9fe0bd03420bca564b6d44cccfc6994b2d2a394643152f36fb9d4d9d4
EXPECTED_SCOPE=fcbb41a567a7faf64ad7db0a6c61074e63482aa18514efed9b35ea450d5852cf
PASS=0; FAIL=0
pass(){ PASS=$((PASS+1)); printf 'PASS: %s\n' "$*"; }
fail(){ FAIL=$((FAIL+1)); printf 'FAIL: %s\n' "$*"; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
check_file(){ local f=$1 label=$2; [[ -f $f && ! -L $f ]] && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"; }
check_file "$VERIFY" "post-reboot verification"
check_file "$POLICY" "post-reboot policy"
check_file "$ACCEPTED" "accepted step-106 record"
[[ $(sha "$VERIFY") == "$EXPECTED_VERIFY_SHA" ]] && pass "verification script has the exact prepared SHA-256" || fail "verification script hash drifted"
[[ $(sha "$POLICY") == "$EXPECTED_POLICY_SHA" ]] && pass "verification policy has the exact prepared SHA-256" || fail "verification policy hash drifted"
[[ $(sha "$ACCEPTED") == "$EXPECTED_ACCEPTED_SHA" ]] && pass "accepted step-106 record has the exact reviewed SHA-256" || fail "accepted record hash drifted"
bash -n "$VERIFY" && pass "verification script is shell-syntax valid" || fail "verification script has shell syntax errors"
"$VERIFY" --help >/dev/null 2>&1 && pass "verification exposes a non-mutating help boundary" || fail "verification help failed"
if "$VERIFY" --unknown-option >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
while IFS=$'\t' read -r mark label; do [[ $mark == PASSPY ]] && pass "$label" || fail "$label"; done < <(python3 - "$POLICY" "$ACCEPTED" <<'PY'
import json,sys
p=json.load(open(sys.argv[1])); a=json.load(open(sys.argv[2]))
checks=[
(p['schema']==1 and p['scenario']=='elilo-oldkernel-cleanup-post-reboot-verification','policy schema and scenario'),
(p['reviewed'] is True and p['post_reboot_verification_authorized'] is True,'post-reboot verification gate'),
(all(p[k] is False for k in ['package_mutation_authorized','boot_mutation_authorized','recovery_backup_removal_authorized','repository_refresh_authorized','network_access_authorized']),'mutation, backup removal, repository refresh, and network access remain denied'),
(a['accepted'] is True and a['reboot_ready'] is True and a['reboot_authorized'] is True and a['reboot_executed'] is False,'accepted step-106 reboot boundary'),
(a['archive_sha256']==p['accepted_reboot_review_archive_sha256'],'accepted archive binding'),
(a['accepted_at_epoch']==p['accepted_reboot_review_epoch'],'reboot chronology binding'),
(a['post_package_snapshot_sha256']==p['post_package_snapshot_sha256'],'package snapshot binding'),
(a['active_module_object_manifest_sha256']==p['active_module_object_manifest_sha256'],'active module manifest binding'),
(a['boot_state_sha256']==p['boot_state_sha256'] and a['elilo_conf_sha256']==p['elilo_conf_sha256'],'boot and ELILO binding'),
(a['recovery_manifest_sha256']==p['recovery_manifest_sha256'],'recovery manifest binding'),
(p['successful_result']['recovery_backup_release_ready'] is True and p['successful_result']['recovery_backup_removal_authorized'] is False,'successful verification only makes recovery backup eligible for later review')]
for ok,label in checks: print(('PASSPY' if ok else 'FAILPY')+'\t'+label)
PY
)
grep -Fq 'btime' "$VERIFY" && pass "verification proves the current boot started after step 106" || fail "boot chronology check is missing"
grep -Fq 'BOOT_IMAGE=' "$VERIFY" && pass "verification checks the running ELILO boot image" || fail "BOOT_IMAGE check is missing"
grep -Fq 'vmlinuz-generic-' "$VERIFY" && pass "verification requires the active versioned kernel image" || fail "versioned boot-image requirement is missing"
grep -Fq 'modules-active-objects.before.sha256' "$VERIFY" && pass "verification checks the complete active module-object manifest" || fail "active module manifest check is missing"
grep -Fq 'modules-rollback-objects.before.txt' "$VERIFY" && pass "verification checks rollback module-object absence" || fail "rollback module absence check is missing"
grep -Fq 'recovery_backup_removal_authorized=false' "$VERIFY" && pass "verification never authorizes recovery backup removal" || fail "backup-removal denial is missing"
grep -Fq 'recovery_backup_release_ready' "$VERIFY" && pass "verification can only advance to a separate backup release review" || fail "backup release review boundary is missing"
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$VERIFY"; then fail "verification source contains a reboot or shutdown execution command"; else pass "verification source contains no reboot or shutdown execution command"; fi
if grep -Eq '(^|[[:space:];])(removepkg|upgradepkg|installpkg|slackpkg|eliloconfig)([[:space:];]|$)' "$VERIFY"; then fail "verification source contains package or ELILO mutation commands"; else pass "verification source contains no package-manager or ELILO mutation command"; fi
if grep -Eq '(^|[[:space:];])(curl|wget|ftp|rsync|scp)([[:space:];]|$)' "$VERIFY"; then fail "verification source contains a network client command"; else pass "verification source contains no network client command"; fi
calc=$(printf '%s\n'   'scenario=elilo-oldkernel-cleanup-post-reboot-verification'   'accepted_reboot_review_archive_sha256=8c8cbdf911a860ed2b0681a3888812e4d3af59869ac93b3ec337e996ea1fc244'   "accepted_reboot_review_record_sha256=$EXPECTED_ACCEPTED_SHA"   "verification_policy_sha256=$EXPECTED_POLICY_SHA"   "verification_script_sha256=$EXPECTED_VERIFY_SHA"   'hostname_fqdn=vbox-slack15.vbox-slack15.org'   'active_kernel=5.15.209'   'rollback_kernel=5.15.19'   'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' | sha256sum | awk '{print $1}')
[[ $calc == "$EXPECTED_SCOPE" ]] && pass "calculated verification confirmation scope matches the prepared immutable boundary" || fail "verification confirmation scope mismatch"
grep -Fq '/home/promano/' "$VERIFY" && grep -Fq 'promano -g users' "$VERIFY" && pass "verification prints direct /home/promano evidence-copy commands with required ownership" || fail "evidence-copy contract is incomplete"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL -eq 0 ]] && printf PASS || printf FAIL)" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
