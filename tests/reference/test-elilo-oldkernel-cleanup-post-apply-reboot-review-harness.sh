#!/usr/bin/env bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
REVIEW="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-post-apply-reboot-review.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-post-apply-reboot-review-policy.json"
ACCEPTED="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-20260815-accepted.json"

EXPECTED_REVIEW_SHA256=cb6bd676f6094866d5b2d85b524190e611c25823899d17769f12548a3204bd47
EXPECTED_POLICY_SHA256=47997a3050ee35be70e608a93fa144d09fac316e6f928ad0968ba92c8ac6d96a
EXPECTED_ACCEPTED_SHA256=429042886380d1ee119221a3cff0927258a328684b99fd039f80233a138d0b1c
EXPECTED_SCOPE_SHA256=2de44097cbfdd6cfba2751f01470b4f48c2a3f740d7722669f2d4ca30cd0dfa7

PASSES=0
FAILURES=0

pass() {
    PASSES=$((PASSES + 1))
    printf 'PASS: %s\n' "$*"
}

fail() {
    FAILURES=$((FAILURES + 1))
    printf 'FAIL: %s\n' "$*"
}

check() {
    local message=$1
    shift
    if "$@"; then
        pass "$message"
    else
        fail "$message"
    fi
}

sha() {
    sha256sum -- "$1" | awk '{print $1}'
}

check "post-apply reboot review is a regular non-symlink file" test -f "$REVIEW"
check "post-apply reboot policy is a regular non-symlink file" test -f "$POLICY"
check "accepted step-105 record is a regular non-symlink file" test -f "$ACCEPTED"
if [[ -L $REVIEW ]]; then fail "review script is not a symlink"; else pass "review script is not a symlink"; fi
if [[ -L $POLICY ]]; then fail "review policy is not a symlink"; else pass "review policy is not a symlink"; fi
if [[ -L $ACCEPTED ]]; then fail "accepted record is not a symlink"; else pass "accepted record is not a symlink"; fi

if [[ -f $REVIEW && $(sha "$REVIEW") == "$EXPECTED_REVIEW_SHA256" ]]; then pass "review script has the exact prepared SHA-256"; else fail "review script has the exact prepared SHA-256"; fi
if [[ -f $POLICY && $(sha "$POLICY") == "$EXPECTED_POLICY_SHA256" ]]; then pass "review policy has the exact prepared SHA-256"; else fail "review policy has the exact prepared SHA-256"; fi
if [[ -f $ACCEPTED && $(sha "$ACCEPTED") == "$EXPECTED_ACCEPTED_SHA256" ]]; then pass "accepted step-105 record has the exact reviewed SHA-256"; else fail "accepted step-105 record has the exact reviewed SHA-256"; fi

if bash -n "$REVIEW"; then pass "review script is shell-syntax valid"; else fail "review script is shell-syntax valid"; fi
if bash "$REVIEW" --help >/dev/null 2>&1; then pass "review script exposes a non-mutating help boundary"; else fail "review script exposes a non-mutating help boundary"; fi
if bash "$REVIEW" --unknown-option >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

if python3 - "$POLICY" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema'] == 1
assert p['scenario'] == 'elilo-oldkernel-cleanup-post-apply-reboot-review'
assert p['reviewed'] is True
assert p['reboot_review_authorized'] is True
assert p['reboot_execution_authorized'] is False
assert p['package_mutation_authorized'] is False
assert p['boot_mutation_authorized'] is False
assert p['recovery_backup_removal_authorized'] is False
assert p['repository_refresh_authorized'] is False
assert p['network_access_authorized'] is False
PY
then pass "policy is review-only and denies reboot execution and system mutation"; else fail "policy is review-only and denies reboot execution and system mutation"; fi

if python3 - "$POLICY" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['expected_script_sha256'] == 'cb6bd676f6094866d5b2d85b524190e611c25823899d17769f12548a3204bd47'
assert p['accepted_apply_record_sha256'] == '429042886380d1ee119221a3cff0927258a328684b99fd039f80233a138d0b1c'
assert p['accepted_apply_archive_sha256'] == 'd3f68ec2a2947c75fddadbdae57246db7b535c926fc83952ef2d9960aa8ac0fa'
assert p['production_executor_sha256'] == '7b42e2df3f99eaa7a92bbb2b91bcc97aa63d5cb0f755b935788409533ada937c'
assert p['production_policy_sha256'] == '98cfb6ead03debb184884da422d9050050f97060991c56cbf5806574e9ab919f'
PY
then pass "policy binds the exact step-105 evidence, accepted record, production executor, and production policy"; else fail "policy binds the exact step-105 evidence, accepted record, production executor, and production policy"; fi

if python3 - "$POLICY" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['hostname_fqdn'] == 'vbox-slack15.vbox-slack15.org'
assert p['active_kernel'] == '5.15.209'
assert p['rollback_kernel'] == '5.15.19'
assert p['recovery_backup_path'] == '/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z'
assert p['post_package_snapshot_sha256'] == 'ab69ead76bd994fd5198fa0351b9ecc66a6b2af986965751750e54aaa69e054f'
assert p['active_module_object_manifest_sha256'] == '4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425'
PY
then pass "policy binds the exact host, kernels, recovery path, package snapshot, and active module objects"; else fail "policy binds the exact host, kernels, recovery path, package snapshot, and active module objects"; fi

if python3 - "$ACCEPTED" <<'PY'
import json, sys
r=json.load(open(sys.argv[1], encoding='utf-8'))
assert r['accepted'] is True
assert r['apply_executed'] is True
assert r['apply_committed'] is True
assert r['recovery_attempted'] is False
assert r['recovery_restored'] is False
assert r['recovery_backup_retained'] is True
assert r['pause_safe'] is True
assert r['reboot_required'] is True
assert r['reboot_authorized'] is False
assert r['reboot_executed'] is False
assert r['next_stage'] == 'elilo-oldkernel-cleanup-post-apply-reboot-review'
PY
then pass "accepted record preserves the committed step-105 result and keeps reboot separately unauthorized"; else fail "accepted record preserves the committed step-105 result and keeps reboot separately unauthorized"; fi

if python3 - "$ACCEPTED" <<'PY'
import json, sys
r=json.load(open(sys.argv[1], encoding='utf-8'))
assert r['archive_sha256'] == 'd3f68ec2a2947c75fddadbdae57246db7b535c926fc83952ef2d9960aa8ac0fa'
assert r['post_package_snapshot_sha256'] == 'ab69ead76bd994fd5198fa0351b9ecc66a6b2af986965751750e54aaa69e054f'
assert r['active_module_object_manifest_sha256'] == '4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425'
assert r['recovery_archives']['boot.tar'] == 'ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85'
assert r['recovery_archives']['modules.tar'] == 'ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781'
assert r['recovery_archives']['pkgtools.tar'] == '50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f'
PY
then pass "accepted record binds the exact post-cleanup package, modules, and recovery evidence"; else fail "accepted record binds the exact post-cleanup package, modules, and recovery evidence"; fi

if python3 - "$ACCEPTED" <<'PY'
import json, sys
r=json.load(open(sys.argv[1], encoding='utf-8'))
expected={
'/boot/vmlinuz-generic-5.15.209':'7a001bd59a0a86567e18798bfa4951dc5ef916004d92daed9a1e532eff04a2a9',
'/boot/initrd-generic-5.15.209.gz':'777c8d971342b15c9d5ece42d26e869b8d804ac37a17044113aae18aa51124df',
'/boot/efi/EFI/Slackware/vmlinuz-generic-5.15.209':'7a001bd59a0a86567e18798bfa4951dc5ef916004d92daed9a1e532eff04a2a9',
'/boot/efi/EFI/Slackware/initrd-generic-5.15.209.gz':'777c8d971342b15c9d5ece42d26e869b8d804ac37a17044113aae18aa51124df'}
assert r['active_boot_artifacts'] == expected
PY
then pass "accepted record binds all four active 5.15.209 boot artifacts"; else fail "accepted record binds all four active 5.15.209 boot artifacts"; fi

if grep -Fq -- '--confirm-apply-evidence-sha256' "$REVIEW" \
    && grep -Fq -- '--confirm-recovery-backup-path' "$REVIEW" \
    && grep -Fq -- '--confirm-review-scope-sha256' "$REVIEW"; then
    pass "review requires explicit evidence, recovery-backup, and calculated-scope confirmations"
else
    fail "review requires explicit evidence, recovery-backup, and calculated-scope confirmations"
fi

if grep -Fq 'post_package_snapshot_sha256' "$REVIEW" && grep -Fq 'packages.before.txt' "$REVIEW"; then
    pass "review validates the exact accepted post-cleanup package snapshot"
else
    fail "review validates the exact accepted post-cleanup package snapshot"
fi

if grep -Fq 'modules-active-objects.before.sha256' "$REVIEW" \
    && grep -Fq '4edc368213108a4d359d6ebe51ddd52e80669b6b78695fc7b64a5c89c4be2425' "$POLICY"; then
    pass "review validates the complete active kernel-module object manifest"
else
    fail "review validates the complete active kernel-module object manifest"
fi

if grep -Fq 'modules-rollback-objects.before.txt' "$REVIEW" \
    && grep -Fq -- "-name '*.ko.*'" "$REVIEW"; then
    pass "review rejects any remaining rollback kernel-module object without requiring the depmod directory to vanish"
else
    fail "review rejects any remaining rollback kernel-module object without requiring the depmod directory to vanish"
fi

if grep -Fq 'oldkernel' "$REVIEW" \
    && grep -Fq 'vmlinuz-generic-' "$REVIEW" \
    && grep -Fq 'initrd-generic-' "$REVIEW" \
    && grep -Fq 'clean_value(labels[0]) != clean_value(defaults[0])' "$REVIEW"; then
    pass "ELILO review requires one active versioned pair, no oldkernel reference, and a matching default label"
else
    fail "ELILO review requires one active versioned pair, no oldkernel reference, and a matching default label"
fi

if grep -Fq '/boot/efi/EFI/Slackware/vmlinuz' "$REVIEW" \
    && grep -Fq '/boot/efi/EFI/Slackware/initrd.gz' "$REVIEW" \
    && grep -Fq '/boot/vmlinuz-generic-5.15.19' "$REVIEW"; then
    pass "review checks the exact rollback boot-artifact absence boundary"
else
    fail "review checks the exact rollback boot-artifact absence boundary"
fi

if grep -Fq 'vboxguest.ko' "$REVIEW" \
    && grep -Fq 'vboxsf.ko' "$REVIEW" \
    && grep -Fq 'vboxvideo.ko' "$REVIEW"; then
    pass "review explicitly checks all three authorized VirtualBox rollback survivors remain absent"
else
    fail "review explicitly checks all three authorized VirtualBox rollback survivors remain absent"
fi

if grep -Fq 'ede0c895d7c9abc6b6c72ce9550b04d835d4a7a3cf843ca858c3ac64357beb85 boot.tar' "$REVIEW" \
    && grep -Fq 'ffc38a087235183bf846012812e71392c0e927c7bd80532c8330d0e85626e781 modules.tar' "$REVIEW" \
    && grep -Fq '50a0d5ac17ca56a634b7e81a47282eae263d6f6239799efee05207ae8c02e31f pkgtools.tar' "$REVIEW"; then
    pass "review verifies all three retained recovery archives by exact hash"
else
    fail "review verifies all three retained recovery archives by exact hash"
fi

if grep -Fq 'cmp -s -- "$WORKDIR/packages.before.txt" "$WORKDIR/packages.after.txt"' "$REVIEW" \
    && grep -Fq 'cmp -s -- "$WORKDIR/boot-state.before.txt" "$WORKDIR/boot-state.after.txt"' "$REVIEW" \
    && grep -Fq 'cmp -s -- "$WORKDIR/elilo.conf.before" "$WORKDIR/elilo.conf.after"' "$REVIEW"; then
    pass "review proves package, boot, and ELILO state remain unchanged during execution"
else
    fail "review proves package, boot, and ELILO state remain unchanged during execution"
fi

if ! grep -Eq '(^|[;&|][[:space:]]*)(/sbin/)?(reboot|shutdown|poweroff|halt)([[:space:];&|]|$)' "$REVIEW"; then
    pass "review source contains no reboot or shutdown execution command"
else
    fail "review source contains no reboot or shutdown execution command"
fi

if ! grep -Eq '(^|[;&|][[:space:]]*)(slackpkg|removepkg|installpkg|upgradepkg|eliloconfig)([[:space:];&|]|$)' "$REVIEW"; then
    pass "review source contains no package-manager or ELILO mutation command"
else
    fail "review source contains no package-manager or ELILO mutation command"
fi

if ! grep -Eq '(^|[;&|][[:space:]]*)(curl|wget|ftp|rsync|scp|ssh)([[:space:];&|]|$)' "$REVIEW"; then
    pass "review source contains no network client command"
else
    fail "review source contains no network client command"
fi

if grep -Fq 'recovery_backup_removal_authorized' "$POLICY" \
    && grep -Fq 'recovery_backup_required_until_post_reboot_verification' "$POLICY"; then
    pass "recovery backup remains explicitly protected through post-reboot verification"
else
    fail "recovery backup remains explicitly protected through post-reboot verification"
fi

if grep -Fq 'NEXT_STAGE=elilo-oldkernel-cleanup-manual-reboot' "$REVIEW" \
    && grep -Fq 'REBOOT_AUTHORIZED=true' "$REVIEW" \
    && grep -Fq 'reboot_executed=false' "$REVIEW"; then
    pass "successful review authorizes only the later manual reboot and never claims to execute it"
else
    fail "successful review authorizes only the later manual reboot and never claims to execute it"
fi

CALCULATED_SCOPE=$(
    printf '%s\n' \
        'scenario=elilo-oldkernel-cleanup-post-apply-reboot-review' \
        'accepted_apply_archive_sha256=d3f68ec2a2947c75fddadbdae57246db7b535c926fc83952ef2d9960aa8ac0fa' \
        "accepted_apply_record_sha256=$(sha "$ACCEPTED")" \
        "review_policy_sha256=$(sha "$POLICY")" \
        "review_script_sha256=$(sha "$REVIEW")" \
        'hostname_fqdn=vbox-slack15.vbox-slack15.org' \
        'active_kernel=5.15.209' \
        'rollback_kernel=5.15.19' \
        'recovery_backup_path=/var/lib/slack-update/elilo-cleanup-backups/5.15.19-20260815T160020Z' \
        | sha256sum | awk '{print $1}'
)
if [[ $CALCULATED_SCOPE == "$EXPECTED_SCOPE_SHA256" ]]; then
    pass "calculated review confirmation scope matches the prepared immutable boundary"
else
    fail "calculated review confirmation scope matches the prepared immutable boundary"
fi

if grep -Fq "printf '%s  %s\\n' \"\$(sha_file \"\$ARCHIVE\")\" \"\$(basename \"\$ARCHIVE\")\" > \"\$SIDECAR\"" "$REVIEW"; then
    pass "evidence sidecar is portable and records only the archive basename"
else
    fail "evidence sidecar is portable and records only the archive basename"
fi

if grep -Fq '/home/promano/' "$REVIEW" && grep -Fq 'install -o promano -g users -m 0600' "$REVIEW"; then
    pass "review prints direct /home/promano evidence-copy commands with the required ownership"
else
    fail "review prints direct /home/promano evidence-copy commands with the required ownership"
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAILURES -eq 0 ]] && printf PASS || printf FAIL)" "$PASSES" "$FAILURES"
[[ $FAILURES -eq 0 ]]
