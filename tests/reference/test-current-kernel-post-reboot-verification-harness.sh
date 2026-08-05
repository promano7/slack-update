#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-reboot-verification.sh"
REAL_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-reboot-verification-policy.json"
REAL_REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-apply-reboot-review.sh"

TEST_COUNT=0
FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BIN="$TMP/bin"
mkdir -p "$BIN"

cat > "$BIN/grub-script-check" <<'EOF_STUB'
#!/bin/bash
case "${GRUB_CHECK_FAIL:-0}" in 1) exit 1 ;; esac
[ -f "$1" ] && grep -q '^menuentry ' "$1"
EOF_STUB

cat > "$BIN/grub-editenv" <<'EOF_STUB'
#!/bin/bash
[ "$#" -eq 2 ] && [ "$2" = list ] || exit 1
[ -f "$1" ] || exit 1
grep -E '^(next_entry|saved_entry)=' "$1" || true
EOF_STUB
chmod 755 "$BIN/grub-script-check" "$BIN/grub-editenv"

sha() { sha256sum -- "$1" | awk '{print $1}'; }

create_root() {
    local root=$1
    rm -rf "$root"
    mkdir -p \
        "$root/proc/sys/kernel/random" \
        "$root/etc/default" \
        "$root/boot/grub" \
        "$root/lib/modules/6.18.42/kernel" \
        "$root/lib/modules/6.18.40/kernel" \
        "$root/usr/sbin" \
        "$root/usr/share/mkinitrd" \
        "$root/var/lib/pkgtools/setup" \
        "$root/var/lib/pkgtools/packages"
    printf 'Slackware 15.0+\n' > "$root/etc/slackware-version"
    printf 'BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro\n' > "$root/proc/cmdline"
    printf '6.18.42\n' > "$root/proc/sys/kernel/osrelease"
    printf '12345678-1234-4abc-8def-1234567890ab\n' > "$root/proc/sys/kernel/random/boot_id"
    chmod 444 "$root/proc/cmdline" "$root/proc/sys/kernel/osrelease" "$root/proc/sys/kernel/random/boot_id"
    printf 'kernel-6.18.42\n' > "$root/boot/vmlinuz-6.18.42"
    printf 'initrd-6.18.42\n' > "$root/boot/initrd-6.18.42.img"
    chmod 644 "$root/boot/vmlinuz-6.18.42" "$root/boot/initrd-6.18.42.img"
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    printf 'target module\n' > "$root/lib/modules/6.18.42/kernel/test.ko"
    printf 'old module\n' > "$root/lib/modules/6.18.40/kernel/test.ko"
    printf 'AUTOGENERATE_INITRD=true\nAUTO_UPDATE_GRUB=true\n' > "$root/etc/default/geninitrd"
    printf '#!/bin/bash\nexit 0\n' > "$root/usr/sbin/geninitrd"
    printf '#!/bin/bash\necho mkinitrd\n' > "$root/usr/share/mkinitrd/mkinitrd_command_generator.sh"
    printf '#!/bin/bash\nexit 0\n' > "$root/var/lib/pkgtools/setup/setup.01.mkinitrd"
    chmod 755 "$root/usr/sbin/geninitrd" "$root/usr/share/mkinitrd/mkinitrd_command_generator.sh" "$root/var/lib/pkgtools/setup/setup.01.mkinitrd"
    cat > "$root/boot/grub/grub.cfg" <<'EOF_GRUB'
set default="0"
menuentry 'Slackware generic' --id slackware-generic {
  linux /boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro
  initrd /boot/initrd-generic.img
}
menuentry 'Diagnostic shell' --id diagnostic-shell {
  linux /boot/vmlinuz-diagnostic root=/dev/sda2 ro
}
EOF_GRUB
    : > "$root/boot/grub/grubenv"
    chmod 600 "$root/boot/grub/grub.cfg"
    chmod 644 "$root/boot/grub/grubenv"
    printf 'boot/vmlinuz-6.18.42\nboot/vmlinuz-generic\nlib/modules/6.18.42/\n' > "$root/var/lib/pkgtools/packages/kernel-generic-6.18.42-x86_64-1"
    printf 'usr/include/linux/\n' > "$root/var/lib/pkgtools/packages/kernel-headers-6.18.42-x86-1"
    printf 'usr/src/linux-6.18.42/\n' > "$root/var/lib/pkgtools/packages/kernel-source-6.18.42-noarch-1"
    printf 'usr/sbin/grub-mkconfig\n' > "$root/var/lib/pkgtools/packages/grub-2.14-x86_64-3"
    printf 'boot/grub/themes/breeze/\n' > "$root/var/lib/pkgtools/packages/breeze-grub-6.7.4-x86_64-1"
    printf 'usr/bin/dummy\n' > "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1"
}

write_recovery_policy() {
    local root=$1 policy=$2
    python3 - "$root" "$policy" <<'PY'
import hashlib, json, pathlib, sys
root=pathlib.Path(sys.argv[1]); out=pathlib.Path(sys.argv[2]); pkg=root/'var/lib/pkgtools/packages'
def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def size(p): return pathlib.Path(p).stat().st_size
names=sorted(p.name for p in pkg.iterdir() if p.is_file() and not p.is_symlink())
snapshot=''.join(f'{sha(pkg/n)}  {n}\n' for n in names).encode()
name_snapshot=''.join(n+'\n' for n in names).encode()
required=[]
for name in ['kernel-generic-6.18.42-x86_64-1','kernel-headers-6.18.42-x86-1','kernel-source-6.18.42-noarch-1','grub-2.14-x86_64-3','breeze-grub-6.7.4-x86_64-1']:
    required.append({'name':name,'record_sha256':sha(pkg/name)})
d={
 'scenario':'current-post-package-boot-recovery-verification','target':'slackware-current','reviewed':True,
 'target_kernel':'6.18.42','installed_package_count':len(names),
 'installed_package_database_snapshot_sha256':hashlib.sha256(snapshot).hexdigest(),
 'installed_package_name_snapshot_sha256':hashlib.sha256(name_snapshot).hexdigest(),
 'required_package_records':required,
 'forbidden_package_records':['kernel-generic-6.18.40-x86_64-1','kernel-headers-6.18.40-x86-1','kernel-source-6.18.40-noarch-1'],
 'target_artifacts':{
   'kernel_sha256':sha(root/'boot/vmlinuz-6.18.42'),'kernel_size':size(root/'boot/vmlinuz-6.18.42'),
   'initrd_sha256':sha(root/'boot/initrd-6.18.42.img'),'initrd_size':size(root/'boot/initrd-6.18.42.img')},
 'geninitrd':{
   'policy_sha256':sha(root/'etc/default/geninitrd'),'policy_size':size(root/'etc/default/geninitrd'),
   'geninitrd_sha256':sha(root/'usr/sbin/geninitrd'),'geninitrd_size':size(root/'usr/sbin/geninitrd'),
   'generator_sha256':sha(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),'generator_size':size(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),
   'setup_sha256':sha(root/'var/lib/pkgtools/setup/setup.01.mkinitrd'),'setup_size':size(root/'var/lib/pkgtools/setup/setup.01.mkinitrd')},
 'active_grub':{'sha256':sha(root/'boot/grub/grub.cfg'),'size':size(root/'boot/grub/grub.cfg')},
}
out.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

write_review_policy() {
    local policy=$1
    cat > "$policy" <<'EOF_POLICY'
{
  "post_reboot_stage": "current-kernel-post-reboot-verification",
  "reboot_execution_allowed": false,
  "reviewed": true,
  "scenario": "current-kernel-post-apply-reboot-review",
  "target": "slackware-current",
  "target_kernel": "6.18.42"
}
EOF_POLICY
}

write_review_record() {
    local review_policy=$1 record=$2
    python3 - "$review_policy" "$REAL_REVIEW_SCRIPT" "$record" <<'PY'
import hashlib, json, pathlib, sys
policy, script, out=map(pathlib.Path,sys.argv[1:])
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
d={
 'scenario':'current-kernel-post-apply-reboot-review','target':'slackware-current','accepted':True,
 'archive_sha256':'e'*64,'hostname_short':'pcold-slack','hostname_fqdn':'pcold-slack.pcold-slack.org',
 'running_kernel':'6.18.40','target_kernel':'6.18.42','package_transaction_completed':True,
 'package_database_unchanged':True,'boot_sensitive_state_unchanged':True,'target_artifacts_verified':True,
 'geninitrd_controls_verified':True,'current_boot_image':'/boot/vmlinuz-generic',
 'required_kernel':'/boot/vmlinuz-generic','required_initrd':'/boot/initrd-generic.img',
 'next_entry_present':False,'pause_safe':True,'reboot_ready':True,'reboot_authorized':True,
 'reboot_executed':False,'next_stage':'manual-reboot-to-reviewed-target',
 'review_policy_sha256':sha(policy),'review_script_sha256':sha(script),
}
out.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

write_verification_policy() {
    local recovery=$1 review_policy=$2 record=$3 policy=$4
    python3 - "$recovery" "$review_policy" "$REAL_REVIEW_SCRIPT" "$record" "$SCRIPT" "$policy" <<'PY'
import hashlib, json, pathlib, sys
recovery, review_policy, review_script, record, verify_script, out=map(pathlib.Path,sys.argv[1:])
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
root_uuid='ba7632d7-7469-483e-830d-59c88d985866'
archive='e'*64
scope=(
 'operation=current-kernel-post-reboot-verification\n'
 'target=slackware-current\n'
 'hostname_short=pcold-slack\n'
 'hostname_fqdn=pcold-slack.pcold-slack.org\n'
 'target_kernel=6.18.42\n'
 f'root_uuid={root_uuid}\n'
 f'reboot_review_archive_sha256={archive}\n'
 f'reboot_review_record_sha256={sha(record)}\n'
 f'reboot_review_policy_sha256={sha(review_policy)}\n'
 f'reboot_review_script_sha256={sha(review_script)}\n'
 f'recovery_policy_sha256={sha(recovery)}\n'
 f'post_reboot_verification_script_sha256={sha(verify_script)}\n'
).encode()
d={
 'scenario':'current-kernel-post-reboot-verification','target':'slackware-current','reviewed':True,
 'required_hostname_short':'pcold-slack','required_hostname_fqdn':'pcold-slack.pcold-slack.org',
 'previous_running_kernel':'6.18.40','target_kernel':'6.18.42','expected_architecture':'x86_64',
 'required_boot_image':'/boot/vmlinuz-generic','required_initrd':'/boot/initrd-generic.img','required_root_uuid':root_uuid,
 'accepted_reboot_review_archive_sha256':archive,'accepted_reboot_review_record_sha256':sha(record),
 'reboot_review_policy_sha256':sha(review_policy),'reboot_review_script_sha256':sha(review_script),
 'recovery_policy_sha256':sha(recovery),'post_reboot_verification_script_sha256':sha(verify_script),
 'verification_scope_sha256':hashlib.sha256(scope).hexdigest(),
 'repository_refresh_allowed':False,'package_mutation_allowed':False,'initrd_mutation_allowed':False,
 'grub_mutation_allowed':False,'reboot_execution_allowed':False,'expected_pause_safe':True,
 'expected_reboot_verified':True,'expected_update_closed':True,
 'next_stage':'optional-rollback-reconstruction-review',
}
out.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

create_case() {
    local name=$1 root recovery review_policy record verify_policy
    root="$TMP/$name-root"
    recovery="$TMP/$name-recovery.json"
    review_policy="$TMP/$name-review-policy.json"
    record="$TMP/$name-record.json"
    verify_policy="$TMP/$name-verify-policy.json"
    create_root "$root"
    write_recovery_policy "$root" "$recovery"
    write_review_policy "$review_policy"
    write_review_record "$review_policy" "$record"
    write_verification_policy "$recovery" "$review_policy" "$record" "$verify_policy"
    printf '%s\n%s\n%s\n%s\n%s\n' "$root" "$recovery" "$review_policy" "$record" "$verify_policy"
}

run_script() {
    local root=$1 recovery=$2 review_policy=$3 record=$4 verify_policy=$5 output=$6 running=${7:-6.18.42} arch=${8:-x86_64} uuid=${9:-ba7632d7-7469-483e-830d-59c88d985866}
    local scope
    scope=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["verification_scope_sha256"])' "$verify_policy")
    env \
      SLACK_UPDATE_TEST_MODE=1 \
      SLACK_UPDATE_TEST_ROOT="$root" \
      SLACK_UPDATE_TEST_PATH="$BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
      SLACK_UPDATE_TEST_HOSTNAME_SHORT=pcold-slack \
      SLACK_UPDATE_TEST_HOSTNAME_FQDN=pcold-slack.pcold-slack.org \
      SLACK_UPDATE_TEST_RUNNING_KERNEL="$running" \
      SLACK_UPDATE_TEST_ARCHITECTURE="$arch" \
      SLACK_UPDATE_TEST_ROOT_UUID="$uuid" \
      SLACK_UPDATE_TEST_ROOT_SOURCE=/dev/test-root \
      POST_REBOOT_REBOOT_RECORD="$record" \
      POST_REBOOT_REVIEW_POLICY="$review_policy" \
      POST_REBOOT_REVIEW_SCRIPT="$REAL_REVIEW_SCRIPT" \
      POST_REBOOT_RECOVERY_POLICY="$recovery" \
      POST_REBOOT_VERIFICATION_POLICY="$verify_policy" \
      bash "$SCRIPT" \
        --target slackware-current \
        --confirm-hostname pcold-slack \
        --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
        --confirm-reboot-review-evidence-sha256 "$(printf e%.0s {1..64})" \
        --confirm-target-kernel 6.18.42 \
        --confirm-verification-sha256 "$scope" \
        --output-dir "$output"
}

assert_success 'the post-reboot verification script should have valid shell syntax' bash -n "$SCRIPT"
assert_success 'the real post-reboot policy should be valid JSON' python3 -m json.tool "$REAL_POLICY"
assert_success 'the real policy should bind the exact post-reboot verification script' python3 -c 'import hashlib,json,sys; d=json.load(open(sys.argv[1])); raise SystemExit(0 if d["post_reboot_verification_script_sha256"] == hashlib.sha256(open(sys.argv[2],"rb").read()).hexdigest() else 1)' "$REAL_POLICY" "$SCRIPT"
assert_contains '"repository_refresh_allowed": false' "$REAL_POLICY" 'the post-reboot policy must forbid repository refresh'
assert_contains '"expected_update_closed": true' "$REAL_POLICY" 'the policy must close the update only after success'
assert_contains 'validate_live_boot_identity' "$SCRIPT" 'the live boot identity must be verified'
assert_contains 'validate_active_modules' "$SCRIPT" 'the active module tree must be verified'
assert_contains 'validate_effective_grub_selection' "$SCRIPT" 'the effective GRUB selection must remain verified'
assert_contains 'UPDATE_CLOSED=true' "$SCRIPT" 'a successful summary must close the update'
assert_not_contains 'slackpkg update' "$SCRIPT" 'the post-reboot verifier must not refresh Slackware metadata'
assert_not_contains 'grub-mkconfig' "$SCRIPT" 'the post-reboot verifier must not regenerate GRUB'
assert_not_contains 'upgradepkg ' "$SCRIPT" 'the post-reboot verifier must not install packages'
assert_not_contains 'removepkg ' "$SCRIPT" 'the post-reboot verifier must not remove packages'
assert_not_contains 'mkinitrd ' "$SCRIPT" 'the post-reboot verifier must not generate an initrd'
assert_not_contains 'shutdown -r' "$SCRIPT" 'the post-reboot verifier must not invoke shutdown'
assert_not_contains 'systemctl reboot' "$SCRIPT" 'the post-reboot verifier must not invoke systemd reboot'
assert_failure 'missing required arguments should be rejected' bash "$SCRIPT" --target slackware-current
assert_failure 'an unsafe target kernel token should be rejected' bash "$SCRIPT" --target slackware-current --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org --confirm-reboot-review-evidence-sha256 "$(printf e%.0s {1..64})" --confirm-target-kernel '../bad' --confirm-verification-sha256 "$(printf a%.0s {1..64})"

mapfile -t BASE < <(create_case baseline)
ROOT=${BASE[0]}; RECOVERY=${BASE[1]}; REVIEW_POLICY=${BASE[2]}; RECORD=${BASE[3]}; VERIFY_POLICY=${BASE[4]}; OUT="$TMP/baseline-output"
BEFORE=$(find "$ROOT" \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
assert_success 'the exact synthetic post-reboot state should close the update' run_script "$ROOT" "$RECOVERY" "$REVIEW_POLICY" "$RECORD" "$VERIFY_POLICY" "$OUT"
AFTER=$(find "$ROOT" \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
assert_equal "$BEFORE" "$AFTER" 'the verifier must not modify the synthetic system root'
assert_contains 'result=PASS' "$OUT/summary.txt" 'the baseline summary should pass'
assert_contains 'passes=14' "$OUT/summary.txt" 'the baseline should report all fourteen assertions'
assert_contains 'failures=0' "$OUT/summary.txt" 'the baseline should have zero failures'
assert_contains 'running_kernel=6.18.42' "$OUT/summary.txt" 'the target kernel should be active'
assert_contains 'boot_image=/boot/vmlinuz-generic' "$OUT/summary.txt" 'the generic boot path should be recorded'
assert_contains 'rollback_state=degraded-modules-only' "$OUT/summary.txt" 'rollback should become modules-only after reboot'
assert_contains 'pause_safe=true' "$OUT/summary.txt" 'the accepted safe pause should remain true'
assert_contains 'reboot_verified=true' "$OUT/summary.txt" 'the reboot should be verified'
assert_contains 'update_closed=true' "$OUT/summary.txt" 'the update should close'
assert_contains 'next_stage=optional-rollback-reconstruction-review' "$OUT/summary.txt" 'only optional rollback work should remain'
assert_success 'the structured post-reboot analysis should be valid JSON' python3 -m json.tool "$OUT/post-reboot-analysis.json"
assert_success 'the structured boot identity should be valid JSON' python3 -m json.tool "$OUT/boot-identity.json"
assert_success 'the structured GRUB selection should be valid JSON' python3 -m json.tool "$OUT/grub-selection.json"
assert_success 'the package snapshots should remain identical' cmp "$OUT/packages.before.txt" "$OUT/packages.after.txt"
assert_success 'the sensitive snapshots should remain identical' cmp "$OUT/sensitive.before.txt" "$OUT/sensitive.after.txt"
assert_success 'the verified GRUB copy should match the synthetic active file' cmp "$ROOT/boot/grub/grub.cfg" "$OUT/grub.cfg.verified"

negative_case() {
    local name=$1 mutation=$2 running=${3:-6.18.42} arch=${4:-x86_64} uuid=${5:-ba7632d7-7469-483e-830d-59c88d985866}
    local root recovery review_policy record verify_policy output
    root="$TMP/$name-root"
    recovery="$TMP/$name-recovery.json"
    review_policy="$TMP/$name-review-policy.json"
    record="$TMP/$name-record.json"
    verify_policy="$TMP/$name-verify-policy.json"
    output="$TMP/$name-output"
    cp -a "$ROOT" "$root"
    cp "$RECOVERY" "$recovery"
    cp "$REVIEW_POLICY" "$review_policy"
    cp "$RECORD" "$record"
    cp "$VERIFY_POLICY" "$verify_policy"
    eval "$mutation"
    assert_failure "$name should fail closed" run_script "$root" "$recovery" "$review_policy" "$record" "$verify_policy" "$output" "$running" "$arch" "$uuid"
    [ -f "$output/summary.txt" ] && assert_contains 'update_closed=false' "$output/summary.txt" "$name must not close the update"
}

negative_case wrong-running-kernel ':' 6.18.40
negative_case wrong-architecture ':' 6.18.42 aarch64
negative_case wrong-root-uuid ':' 6.18.42 x86_64 deadbeef-dead-beef-dead-beefdeadbeef
negative_case osrelease-mismatch 'printf "6.18.40\n" > "$root/proc/sys/kernel/osrelease"'
negative_case boot-image-mismatch 'printf "BOOT_IMAGE=/boot/vmlinuz-6.18.42 root=UUID=ba7632d7-7469-483e-830d-59c88d985866 ro\n" > "$root/proc/cmdline"'
negative_case root-argument-mismatch 'printf "BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=deadbeef-dead-beef-dead-beefdeadbeef ro\n" > "$root/proc/cmdline"'
negative_case writable-root 'printf "BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=ba7632d7-7469-483e-830d-59c88d985866 rw\n" > "$root/proc/cmdline"'
negative_case zero-boot-id 'printf "00000000-0000-0000-0000-000000000000\n" > "$root/proc/sys/kernel/random/boot_id"'
negative_case malformed-boot-id 'printf "not-a-boot-id\n" > "$root/proc/sys/kernel/random/boot_id"'
negative_case package-drift 'printf "changed\n" >> "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1"'
negative_case missing-kernel-record 'rm "$root/var/lib/pkgtools/packages/kernel-generic-6.18.42-x86_64-1"'
negative_case kernel-image-drift 'printf "changed\n" >> "$root/boot/vmlinuz-6.18.42"'
negative_case initrd-drift 'printf "changed\n" >> "$root/boot/initrd-6.18.42.img"'
negative_case generic-kernel-link-drift 'rm "$root/boot/vmlinuz-generic"; ln -s vmlinuz-6.18.40 "$root/boot/vmlinuz-generic"'
negative_case missing-target-modules 'rm -rf "$root/lib/modules/6.18.42"'
negative_case geninitrd-drift 'printf "changed\n" >> "$root/etc/default/geninitrd"'
negative_case grub-next-entry 'printf "next_entry=diagnostic-shell\n" > "$root/boot/grub/grubenv"'
negative_case grub-selection-drift 'sed -i "s/set default=\"0\"/set default=\"1\"/" "$root/boot/grub/grub.cfg"'
negative_case old-kernel-image-present 'printf "old kernel\n" > "$root/boot/vmlinuz-6.18.40"'
negative_case old-modules-missing 'rm -rf "$root/lib/modules/6.18.40"'
negative_case changed-record 'python3 -c "import json; p=\"$record\"; d=json.load(open(p)); d[\"reboot_authorized\"]=False; open(p,\"w\").write(json.dumps(d)+\"\\n\")"'

HASH_ROOT="$TMP/wrong-scope-root"
HASH_RECOVERY="$TMP/wrong-scope-recovery.json"
HASH_REVIEW="$TMP/wrong-scope-review-policy.json"
HASH_RECORD="$TMP/wrong-scope-record.json"
HASH_POLICY="$TMP/wrong-scope-verify-policy.json"
HASH_OUT="$TMP/wrong-scope-output"
cp -a "$ROOT" "$HASH_ROOT"
cp "$RECOVERY" "$HASH_RECOVERY"
cp "$REVIEW_POLICY" "$HASH_REVIEW"
cp "$RECORD" "$HASH_RECORD"
cp "$VERIFY_POLICY" "$HASH_POLICY"
assert_failure 'an incorrect explicit verification scope should fail closed' env \
  SLACK_UPDATE_TEST_MODE=1 SLACK_UPDATE_TEST_ROOT="$HASH_ROOT" SLACK_UPDATE_TEST_PATH="$BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  SLACK_UPDATE_TEST_HOSTNAME_SHORT=pcold-slack SLACK_UPDATE_TEST_HOSTNAME_FQDN=pcold-slack.pcold-slack.org \
  SLACK_UPDATE_TEST_RUNNING_KERNEL=6.18.42 SLACK_UPDATE_TEST_ARCHITECTURE=x86_64 \
  SLACK_UPDATE_TEST_ROOT_UUID=ba7632d7-7469-483e-830d-59c88d985866 SLACK_UPDATE_TEST_ROOT_SOURCE=/dev/test-root \
  POST_REBOOT_REBOOT_RECORD="$HASH_RECORD" POST_REBOOT_REVIEW_POLICY="$HASH_REVIEW" POST_REBOOT_REVIEW_SCRIPT="$REAL_REVIEW_SCRIPT" \
  POST_REBOOT_RECOVERY_POLICY="$HASH_RECOVERY" POST_REBOOT_VERIFICATION_POLICY="$HASH_POLICY" \
  bash "$SCRIPT" --target slackware-current --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
  --confirm-reboot-review-evidence-sha256 "$(printf e%.0s {1..64})" --confirm-target-kernel 6.18.42 \
  --confirm-verification-sha256 "$(printf f%.0s {1..64})" --output-dir "$HASH_OUT"

printf 'Post-reboot verification harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
