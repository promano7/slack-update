#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-post-package-boot-recovery-verification.sh"
REAL_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-policy.json"
DIAGNOSTIC="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-normal-update-authorized-apply-20260805-post-package-boot-diagnostic.json"

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
BASE_ROOT="$TMP/base-root"
BIN="$TMP/bin"
POLICY="$TMP/policy.json"
OUTPUT_ROOT="$TMP/evidence"
mkdir -p "$BIN" "$OUTPUT_ROOT"
cat > "$BIN/grub-script-check" <<'EOF_STUB'
#!/bin/bash
case "${GRUB_CHECK_FAIL:-0}" in 1) exit 1 ;; esac
[ -f "$1" ] && grep -q '^menuentry ' "$1"
EOF_STUB
chmod 755 "$BIN/grub-script-check"

create_base_root() {
    local root=$1
    rm -rf "$root"
    mkdir -p \
        "$root/etc/default" \
        "$root/etc" \
        "$root/boot/grub" \
        "$root/lib/modules/6.18.42/kernel" \
        "$root/lib/modules/6.18.40/kernel" \
        "$root/usr/sbin" \
        "$root/usr/share/mkinitrd" \
        "$root/var/lib/pkgtools/setup" \
        "$root/var/lib/pkgtools/packages"
    printf 'Slackware 15.0+\n' > "$root/etc/slackware-version"
    printf 'kernel-6.18.42\n' > "$root/boot/vmlinuz-6.18.42"
    printf 'initrd-6.18.42\n' > "$root/boot/initrd-6.18.42.img"
    chmod 644 "$root/boot/vmlinuz-6.18.42" "$root/boot/initrd-6.18.42.img"
    ln -s vmlinuz-6.18.42 "$root/boot/vmlinuz-generic"
    ln -s initrd-6.18.42.img "$root/boot/initrd-generic.img"
    printf 'target module\n' > "$root/lib/modules/6.18.42/kernel/test.ko"
    printf 'running module\n' > "$root/lib/modules/6.18.40/kernel/test.ko"
    printf 'AUTOGENERATE_INITRD=true\nAUTO_UPDATE_GRUB=true\n' > "$root/etc/default/geninitrd"
    printf '#!/bin/bash\nexit 0\n' > "$root/usr/sbin/geninitrd"
    printf '#!/bin/bash\necho mkinitrd\n' > "$root/usr/share/mkinitrd/mkinitrd_command_generator.sh"
    printf '#!/bin/bash\nexit 0\n' > "$root/var/lib/pkgtools/setup/setup.01.mkinitrd"
    chmod 755 "$root/usr/sbin/geninitrd" "$root/usr/share/mkinitrd/mkinitrd_command_generator.sh" "$root/var/lib/pkgtools/setup/setup.01.mkinitrd"
    cat > "$root/boot/grub/grub.cfg" <<'EOF_GRUB'
menuentry 'Slackware generic' {
  linux /boot/vmlinuz-generic root=/dev/sda2 ro
  initrd /boot/initrd-generic.img
}
EOF_GRUB
    chmod 600 "$root/boot/grub/grub.cfg"
    printf 'boot/vmlinuz-6.18.42\nboot/vmlinuz-generic\nlib/modules/6.18.42/\n' > "$root/var/lib/pkgtools/packages/kernel-generic-6.18.42-x86_64-1"
    printf 'usr/include/linux/\n' > "$root/var/lib/pkgtools/packages/kernel-headers-6.18.42-x86-1"
    printf 'usr/src/linux-6.18.42/\n' > "$root/var/lib/pkgtools/packages/kernel-source-6.18.42-noarch-1"
    printf 'usr/sbin/grub-mkconfig\n' > "$root/var/lib/pkgtools/packages/grub-2.14-x86_64-3"
    printf 'boot/grub/themes/breeze/\n' > "$root/var/lib/pkgtools/packages/breeze-grub-6.7.4-x86_64-1"
    printf 'usr/bin/dummy\n' > "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1"
}

write_policy() {
    local root=$1 policy=$2
    python3 - "$root" "$policy" <<'PY'
import hashlib, json, os, pathlib, sys
root=pathlib.Path(sys.argv[1]); out=pathlib.Path(sys.argv[2]); pkg=root/'var/lib/pkgtools/packages'
def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def size(p): return pathlib.Path(p).stat().st_size
names=sorted(p.name for p in pkg.iterdir() if p.is_file() and not p.is_symlink())
snapshot=''.join(f'{sha(pkg/n)}  {n}\n' for n in names).encode()
name_snapshot=''.join(n+'\n' for n in names).encode()
records=[]
for n in ['kernel-generic-6.18.42-x86_64-1','kernel-headers-6.18.42-x86-1','kernel-source-6.18.42-noarch-1','grub-2.14-x86_64-3','breeze-grub-6.7.4-x86_64-1']:
    records.append({'name':n,'record_sha256':sha(pkg/n)})
d={
 'scenario':'current-post-package-boot-recovery-verification','target':'slackware-current','reviewed':True,
 'accepted_failed_apply_archive_sha256':'a'*64,'accepted_nested_apply_archive_sha256':'b'*64,
 'candidate_set_sha256':'c'*64,'required_hostname_short':'pcold-slack','required_hostname_fqdn':'pcold-slack.pcold-slack.org',
 'running_kernel':'6.18.40','target_kernel':'6.18.42','package_transaction_executed':True,'package_transaction_completed':True,
 'install_new_exit_code':0,'upgrade_all_exit_code':0,'installed_package_count':len(names),
 'installed_package_database_snapshot_sha256':hashlib.sha256(snapshot).hexdigest(),
 'installed_package_name_snapshot_sha256':hashlib.sha256(name_snapshot).hexdigest(),
 'required_package_records':records,
 'forbidden_package_records':['kernel-generic-6.18.40-x86_64-1','kernel-headers-6.18.40-x86-1','kernel-source-6.18.40-noarch-1'],
 'target_artifacts':{'kernel_sha256':sha(root/'boot/vmlinuz-6.18.42'),'kernel_size':size(root/'boot/vmlinuz-6.18.42'),'initrd_sha256':sha(root/'boot/initrd-6.18.42.img'),'initrd_size':size(root/'boot/initrd-6.18.42.img')},
 'geninitrd':{
   'policy_sha256':sha(root/'etc/default/geninitrd'),'policy_size':size(root/'etc/default/geninitrd'),
   'geninitrd_sha256':sha(root/'usr/sbin/geninitrd'),'geninitrd_size':size(root/'usr/sbin/geninitrd'),
   'generator_sha256':sha(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),'generator_size':size(root/'usr/share/mkinitrd/mkinitrd_command_generator.sh'),
   'setup_sha256':sha(root/'var/lib/pkgtools/setup/setup.01.mkinitrd'),'setup_size':size(root/'var/lib/pkgtools/setup/setup.01.mkinitrd')},
 'active_grub':{'sha256':sha(root/'boot/grub/grub.cfg'),'size':size(root/'boot/grub/grub.cfg')},
 'rollback':{'state':'degraded-running-session-and-modules-only'},
 'active_grub_mutation_required':False,'package_mutation_allowed':False,'initrd_mutation_allowed':False,'grub_mutation_allowed':False,
 'expected_pause_safe':True,'reboot_ready_after_verification':True,'reboot_authorized':False,'next_stage':'current-kernel-post-apply-reboot-review'
}
out.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

run_script() {
    local root=$1 policy=$2 output=$3
    env \
        SLACK_UPDATE_TEST_MODE=1 \
        SLACK_UPDATE_TEST_ROOT="$root" \
        SLACK_UPDATE_TEST_PATH="$BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        SLACK_UPDATE_TEST_HOSTNAME_SHORT=pcold-slack \
        SLACK_UPDATE_TEST_HOSTNAME_FQDN=pcold-slack.pcold-slack.org \
        SLACK_UPDATE_TEST_RUNNING_KERNEL=6.18.40 \
        RECOVERY_POLICY_PATH="$policy" \
        RECOVERY_OUTPUT_ROOT="$OUTPUT_ROOT" \
        bash "$SCRIPT" \
            --target slackware-current \
            --confirm-hostname pcold-slack \
            --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
            --confirm-post-apply-evidence-sha256 "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["accepted_failed_apply_archive_sha256"])' "$policy")" \
            --confirm-target-kernel 6.18.42 \
            --output-dir "$output"
}

create_case() {
    local name=$1 root policy
    root="$TMP/$name-root"
    policy="$TMP/$name-policy.json"
    create_base_root "$root"
    write_policy "$root" "$policy"
    printf '%s\n%s\n' "$root" "$policy"
}

assert_success 'the recovery verification script should have valid shell syntax' bash -n "$SCRIPT"
assert_success 'the reviewed recovery policy should be valid JSON' python3 -m json.tool "$REAL_POLICY"
assert_success 'the rejected post-package diagnostic should be valid JSON' python3 -m json.tool "$DIAGNOSTIC"
assert_contains '"accepted": false' "$DIAGNOSTIC" 'the step-78 result must remain rejected'
assert_contains '"completed": true' "$DIAGNOSTIC" 'the diagnostic should preserve the completed package transaction'
assert_contains '"kernel_image_6_18_40_present": false' "$DIAGNOSTIC" 'the missing old kernel image must be recorded'
assert_contains '"active_grub_mutation_required": false' "$REAL_POLICY" 'the recovery must not require GRUB mutation'
assert_contains '"expected_pause_safe": true' "$REAL_POLICY" 'the policy should permit a safe pause only after exact verification'
assert_contains 'grub-script-check' "$SCRIPT" 'the active GRUB configuration must be syntax checked'
assert_contains 'validate_grub_kernel_initrd_pair' "$SCRIPT" 'the same-menuentry pair must be validated'
assert_contains 'active_grub_mutated=false' "$SCRIPT" 'the summary must expose zero GRUB mutation'
assert_contains '"reboot_authorized": false' "$REAL_POLICY" 'the verification must not authorize reboot'
assert_not_contains 'slackpkg update' "$SCRIPT" 'post-package recovery must not refresh the repository'
assert_not_contains 'grub-mkconfig' "$SCRIPT" 'post-package recovery must not regenerate GRUB'
assert_not_contains 'upgradepkg' "$SCRIPT" 'post-package recovery must not install packages'
assert_failure 'missing required arguments should be rejected' bash "$SCRIPT" --target slackware-current
assert_failure 'an unsafe target kernel token should be rejected' bash "$SCRIPT" --target slackware-current --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org --confirm-post-apply-evidence-sha256 "$(printf a%.0s {1..64})" --confirm-target-kernel '../bad'

mapfile -t BASE < <(create_case baseline)
BASE_CASE_ROOT=${BASE[0]}; BASE_POLICY=${BASE[1]}; BASE_OUT="$TMP/baseline-output"
BEFORE_HASH=$(find "$BASE_CASE_ROOT" -type f -o -type l | LC_ALL=C sort | xargs -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
assert_success 'the exact synthetic post-package state should verify successfully' run_script "$BASE_CASE_ROOT" "$BASE_POLICY" "$BASE_OUT"
AFTER_HASH=$(find "$BASE_CASE_ROOT" -type f -o -type l | LC_ALL=C sort | xargs -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
assert_equal "$BEFORE_HASH" "$AFTER_HASH" 'the verification must not modify the synthetic system root'
assert_contains 'result=PASS' "$BASE_OUT/summary.txt" 'the baseline summary should pass'
assert_contains 'pause_safe=true' "$BASE_OUT/summary.txt" 'the baseline should declare a safe pause'
assert_contains 'reboot_ready=true' "$BASE_OUT/summary.txt" 'the target boot pair should be reboot-ready'
assert_contains 'reboot_authorized=false' "$BASE_OUT/summary.txt" 'the verification should retain separate reboot authorization'
assert_contains 'rollback_state=degraded-running-session-and-modules-only' "$BASE_OUT/summary.txt" 'the degraded rollback state should be explicit'
assert_contains 'active_grub_mutated=false' "$BASE_OUT/summary.txt" 'GRUB must remain unchanged'
assert_success 'the recovery analysis should be valid JSON' python3 -m json.tool "$BASE_OUT/recovery-analysis.json"
assert_contains '"pause_safe": true' "$BASE_OUT/recovery-analysis.json" 'structured evidence should report pause safety'
assert_contains '"target_boot_pair_verified": true' "$BASE_OUT/recovery-analysis.json" 'structured evidence should report the verified target pair'
assert_success 'the copied GRUB evidence should equal the active configuration' cmp "$BASE_CASE_ROOT/boot/grub/grub.cfg" "$BASE_OUT/grub.cfg.verified"
assert_success 'the package snapshots should remain identical' cmp "$BASE_OUT/packages.before.txt" "$BASE_OUT/packages.after.txt"
assert_success 'the sensitive snapshots should remain identical' cmp "$BASE_OUT/sensitive.before.txt" "$BASE_OUT/sensitive.after.txt"

negative_case() {
    local name=$1 mutation=$2 root policy output
    mapfile -t CASE < <(create_case "$name")
    root=${CASE[0]}; policy=${CASE[1]}; output="$TMP/$name-output"
    eval "$mutation"
    assert_failure "$name should fail closed" run_script "$root" "$policy" "$output"
    [ -f "$output/summary.txt" ] && assert_contains 'pause_safe=false' "$output/summary.txt" "$name must not claim a safe pause"
}

negative_case kernel-hash 'printf tampered >> "$root/boot/vmlinuz-6.18.42"'
negative_case initrd-hash 'printf tampered >> "$root/boot/initrd-6.18.42.img"'
negative_case kernel-link 'rm "$root/boot/vmlinuz-generic"; ln -s vmlinuz-6.18.41 "$root/boot/vmlinuz-generic"'
negative_case initrd-link 'rm "$root/boot/initrd-generic.img"; ln -s initrd-6.18.41.img "$root/boot/initrd-generic.img"'
negative_case package-drift 'printf changed >> "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1"'
negative_case grub-hash 'printf "# changed\n" >> "$root/boot/grub/grub.cfg"'
negative_case grub-pair 'sed -i "/initrd /d" "$root/boot/grub/grub.cfg"; write_policy "$root" "$policy"'

mapfile -t GRUB_FAIL < <(create_case grub-check-fail)
GRUB_FAIL_ROOT=${GRUB_FAIL[0]}; GRUB_FAIL_POLICY=${GRUB_FAIL[1]}; GRUB_FAIL_OUT="$TMP/grub-check-fail-output"
GRUB_CHECK_FAIL=1 assert_failure 'a syntax-check failure should block pause safety' run_script "$GRUB_FAIL_ROOT" "$GRUB_FAIL_POLICY" "$GRUB_FAIL_OUT"

printf 'Current post-package boot recovery verification harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
