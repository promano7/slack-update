#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-post-apply-reboot-review.sh"
REAL_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-post-apply-reboot-review-policy.json"
REAL_CHECKPOINT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-20260805-accepted.json"
REAL_RECOVERY_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-policy.json"
REAL_RECOVERY_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-post-package-boot-recovery-verification.sh"

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
OUTPUT_ROOT="$TMP/evidence"
mkdir -p "$BIN" "$OUTPUT_ROOT"

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

create_base_root() {
    local root=$1
    rm -rf "$root"
    mkdir -p \
        "$root/proc" \
        "$root/etc/default" \
        "$root/boot/grub" \
        "$root/lib/modules/6.18.42/kernel" \
        "$root/lib/modules/6.18.40/kernel" \
        "$root/usr/sbin" \
        "$root/usr/share/mkinitrd" \
        "$root/var/lib/pkgtools/setup" \
        "$root/var/lib/pkgtools/packages"
    printf 'Slackware 15.0+\n' > "$root/etc/slackware-version"
    printf 'BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=test ro\n' > "$root/proc/cmdline"
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
set default="0"
menuentry 'Slackware generic' --id slackware-generic {
  linux /boot/vmlinuz-generic root=/dev/sda2 ro
  initrd /boot/initrd-generic.img
}
menuentry 'Diagnostic shell' --id diagnostic-shell {
  linux /boot/vmlinuz-diagnostic root=/dev/sda2 ro
}
EOF_GRUB
    : > "$root/boot/grub/grubenv"
    chmod 600 "$root/boot/grub/grub.cfg" "$root/boot/grub/grubenv"
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
records=[]
for n in ['kernel-generic-6.18.42-x86_64-1','kernel-headers-6.18.42-x86-1','kernel-source-6.18.42-noarch-1','grub-2.14-x86_64-3','breeze-grub-6.7.4-x86_64-1']:
    records.append({'name':n,'record_sha256':sha(pkg/n)})
d={
 'scenario':'current-post-package-boot-recovery-verification','target':'slackware-current','reviewed':True,
 'required_hostname_short':'pcold-slack','required_hostname_fqdn':'pcold-slack.pcold-slack.org',
 'running_kernel':'6.18.40','target_kernel':'6.18.42','expected_pause_safe':True,'reboot_authorized':False,
 'installed_package_count':len(names),
 'installed_package_database_snapshot_sha256':hashlib.sha256(snapshot).hexdigest(),
 'installed_package_name_snapshot_sha256':hashlib.sha256(name_snapshot).hexdigest(),
 'required_package_records':records,
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

write_checkpoint() {
    local recovery_policy=$1 checkpoint=$2
    python3 - "$recovery_policy" "$REAL_RECOVERY_SCRIPT" "$checkpoint" <<'PY'
import hashlib, json, pathlib, sys
recovery_policy, recovery_script, out = map(pathlib.Path, sys.argv[1:])
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
d={
 'scenario':'current-post-package-boot-recovery-verification','target':'slackware-current','accepted':True,
 'archive_sha256':'a'*64,'package_transaction_completed':True,'target_boot_pair_verified':True,
 'active_grub_mutated':False,'running_kernel':'6.18.40','target_kernel':'6.18.42',
 'rollback_state':'degraded-running-session-and-modules-only','pause_safe':True,'reboot_ready':True,
 'reboot_authorized':False,'next_stage':'current-kernel-post-apply-reboot-review',
 'policy_sha256':sha(recovery_policy),'verification_script_sha256':sha(recovery_script),
}
out.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

write_review_policy() {
    local recovery_policy=$1 checkpoint=$2 review_policy=$3
    python3 - "$checkpoint" "$recovery_policy" "$REAL_RECOVERY_SCRIPT" "$SCRIPT" "$review_policy" <<'PY'
import hashlib, json, pathlib, sys
checkpoint, recovery_policy, recovery_script, review_script, out = map(pathlib.Path, sys.argv[1:])
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checkpoint_sha=sha(checkpoint); recovery_policy_sha=sha(recovery_policy); recovery_script_sha=sha(recovery_script); review_script_sha=sha(review_script)
safe_pause='a'*64
scope=(
 'operation=current-kernel-post-apply-reboot-review\n'
 'target=slackware-current\n'
 'hostname_short=pcold-slack\n'
 'hostname_fqdn=pcold-slack.pcold-slack.org\n'
 'running_kernel=6.18.40\n'
 'target_kernel=6.18.42\n'
 f'safe_pause_archive_sha256={safe_pause}\n'
 'rollback_state=degraded-running-session-and-modules-only\n'
 f'checkpoint_record_sha256={checkpoint_sha}\n'
 f'recovery_policy_sha256={recovery_policy_sha}\n'
 f'recovery_verification_script_sha256={recovery_script_sha}\n'
 f'reboot_review_script_sha256={review_script_sha}\n'
).encode()
d={
 'scenario':'current-kernel-post-apply-reboot-review','target':'slackware-current','reviewed':True,'authorization_reviewed':True,
 'required_hostname_short':'pcold-slack','required_hostname_fqdn':'pcold-slack.pcold-slack.org',
 'required_running_kernel':'6.18.40','target_kernel':'6.18.42','accepted_safe_pause_archive_sha256':safe_pause,
 'accepted_checkpoint_record_sha256':checkpoint_sha,'recovery_policy_sha256':recovery_policy_sha,
 'recovery_verification_script_sha256':recovery_script_sha,'reboot_review_script_sha256':review_script_sha,
 'authorization_scope_sha256':hashlib.sha256(scope).hexdigest(),
 'rollback_state':'degraded-running-session-and-modules-only','required_current_boot_image':'/boot/vmlinuz-generic',
 'required_next_kernel':'/boot/vmlinuz-generic','required_next_initrd':'/boot/initrd-generic.img','forbid_grub_next_entry':True,
 'repository_refresh_allowed':False,'package_mutation_allowed':False,'initrd_mutation_allowed':False,
 'grub_mutation_allowed':False,'reboot_execution_allowed':False,'reboot_authorized_only_after_exact_review':True,
 'next_stage':'manual-reboot-to-reviewed-target','post_reboot_stage':'current-kernel-post-reboot-verification',
}
out.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

create_case() {
    local name=$1 root recovery_policy checkpoint review_policy
    root="$TMP/$name-root"
    recovery_policy="$TMP/$name-recovery-policy.json"
    checkpoint="$TMP/$name-checkpoint.json"
    review_policy="$TMP/$name-review-policy.json"
    create_base_root "$root"
    write_recovery_policy "$root" "$recovery_policy"
    write_checkpoint "$recovery_policy" "$checkpoint"
    write_review_policy "$recovery_policy" "$checkpoint" "$review_policy"
    printf '%s\n%s\n%s\n%s\n' "$root" "$recovery_policy" "$checkpoint" "$review_policy"
}

refresh_case_policies() {
    local root=$1 recovery_policy=$2 checkpoint=$3 review_policy=$4
    write_recovery_policy "$root" "$recovery_policy"
    write_checkpoint "$recovery_policy" "$checkpoint"
    write_review_policy "$recovery_policy" "$checkpoint" "$review_policy"
}

run_script() {
    local root=$1 recovery_policy=$2 checkpoint=$3 review_policy=$4 output=$5 authorization
    authorization=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["authorization_scope_sha256"])' "$review_policy")
    env \
        SLACK_UPDATE_TEST_MODE=1 \
        SLACK_UPDATE_TEST_ROOT="$root" \
        SLACK_UPDATE_TEST_PATH="$BIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        SLACK_UPDATE_TEST_HOSTNAME_SHORT=pcold-slack \
        SLACK_UPDATE_TEST_HOSTNAME_FQDN=pcold-slack.pcold-slack.org \
        SLACK_UPDATE_TEST_RUNNING_KERNEL=6.18.40 \
        REBOOT_REVIEW_CHECKPOINT_RECORD="$checkpoint" \
        REBOOT_REVIEW_RECOVERY_POLICY="$recovery_policy" \
        REBOOT_REVIEW_RECOVERY_SCRIPT="$REAL_RECOVERY_SCRIPT" \
        REBOOT_REVIEW_POLICY="$review_policy" \
        REBOOT_REVIEW_OUTPUT_ROOT="$OUTPUT_ROOT" \
        bash "$SCRIPT" \
            --target slackware-current \
            --authorize-reboot-review \
            --acknowledge-degraded-rollback \
            --confirm-hostname pcold-slack \
            --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
            --confirm-running-kernel 6.18.40 \
            --confirm-safe-pause-evidence-sha256 "$(printf a%.0s {1..64})" \
            --confirm-target-kernel 6.18.42 \
            --confirm-authorization-sha256 "$authorization" \
            --output-dir "$output"
}

assert_success 'the reboot review script should have valid shell syntax' bash -n "$SCRIPT"
assert_success 'the real reboot review policy should be valid JSON' python3 -m json.tool "$REAL_POLICY"
assert_success 'the accepted safe-pause checkpoint should be valid JSON' python3 -m json.tool "$REAL_CHECKPOINT"
assert_success 'the recovery policy should be valid JSON' python3 -m json.tool "$REAL_RECOVERY_POLICY"
assert_contains '"repository_refresh_allowed": false' "$REAL_POLICY" 'the review policy must forbid repository refresh'
assert_contains '"reboot_execution_allowed": false' "$REAL_POLICY" 'the review must not execute the reboot'
assert_contains '"forbid_grub_next_entry": true' "$REAL_POLICY" 'a one-time GRUB selection must be forbidden'
assert_contains 'validate_effective_grub_selection' "$SCRIPT" 'the effective GRUB default must be reviewed'
assert_contains 'required_current_boot_image' "$SCRIPT" 'the current generic boot path must be bound'
assert_contains 'reboot_executed=false' "$SCRIPT" 'the result must state that reboot was not executed'
assert_not_contains 'slackpkg update' "$SCRIPT" 'the reboot review must not refresh Slackware metadata'
assert_not_contains 'grub-mkconfig' "$SCRIPT" 'the reboot review must not regenerate GRUB'
assert_not_contains 'upgradepkg ' "$SCRIPT" 'the reboot review must not install packages'
assert_not_contains 'shutdown -r' "$SCRIPT" 'the reboot review must not invoke shutdown'
assert_not_contains 'systemctl reboot' "$SCRIPT" 'the reboot review must not invoke systemd reboot'
assert_failure 'missing required arguments should be rejected' bash "$SCRIPT" --target slackware-current
assert_failure 'authorization without rollback acknowledgement should be rejected' bash "$SCRIPT" --target slackware-current --authorize-reboot-review
assert_failure 'an unsafe target token should be rejected' bash "$SCRIPT" --target slackware-current --authorize-reboot-review --acknowledge-degraded-rollback --confirm-hostname pcold-slack --confirm-hostname-fqdn pcold-slack.pcold-slack.org --confirm-running-kernel 6.18.40 --confirm-safe-pause-evidence-sha256 "$(printf a%.0s {1..64})" --confirm-target-kernel '../bad' --confirm-authorization-sha256 "$(printf b%.0s {1..64})"

mapfile -t BASE < <(create_case baseline)
BASE_ROOT=${BASE[0]}; BASE_RECOVERY=${BASE[1]}; BASE_CHECKPOINT=${BASE[2]}; BASE_REVIEW=${BASE[3]}; BASE_OUT="$TMP/baseline-output"
BEFORE_HASH=$(find "$BASE_ROOT" \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
assert_success 'the exact synthetic safe-pause state should authorize the manual reboot' run_script "$BASE_ROOT" "$BASE_RECOVERY" "$BASE_CHECKPOINT" "$BASE_REVIEW" "$BASE_OUT"
AFTER_HASH=$(find "$BASE_ROOT" \( -type f -o -type l \) -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}')
assert_equal "$BEFORE_HASH" "$AFTER_HASH" 'the reboot review must not modify the synthetic system root'
assert_contains 'result=PASS' "$BASE_OUT/summary.txt" 'the baseline summary should pass'
assert_contains 'pause_safe=true' "$BASE_OUT/summary.txt" 'the accepted safe pause should remain valid'
assert_contains 'reboot_ready=true' "$BASE_OUT/summary.txt" 'the exact boot pair should be reboot-ready'
assert_contains 'reboot_authorized=true' "$BASE_OUT/summary.txt" 'the explicit review should authorize one manual reboot'
assert_contains 'reboot_executed=false' "$BASE_OUT/summary.txt" 'the review must not execute the reboot'
assert_contains 'boot_selection=effective-default-generic-kernel-initrd-pair' "$BASE_OUT/summary.txt" 'the effective GRUB selection should be explicit'
assert_contains 'next_stage=manual-reboot-to-reviewed-target' "$BASE_OUT/summary.txt" 'the next stage should be the manual reboot'
assert_success 'the structured reboot review should be valid JSON' python3 -m json.tool "$BASE_OUT/reboot-review-analysis.json"
assert_contains '"repository_metadata_refreshed": false' "$BASE_OUT/reboot-review-analysis.json" 'structured evidence must record no metadata refresh'
assert_contains '"host_mutated": false' "$BASE_OUT/reboot-review-analysis.json" 'structured evidence must record zero host mutation'
assert_success 'the copied GRUB file should equal the active synthetic configuration' cmp "$BASE_ROOT/boot/grub/grub.cfg" "$BASE_OUT/grub.cfg.verified"
assert_success 'the observed GRUB file should remain available for failed-review diagnostics' cmp "$BASE_ROOT/boot/grub/grub.cfg" "$BASE_OUT/grub.cfg.observed"
assert_success 'the package snapshots should remain identical' cmp "$BASE_OUT/packages.before.txt" "$BASE_OUT/packages.after.txt"
assert_success 'the sensitive snapshots should remain identical' cmp "$BASE_OUT/sensitive.before.txt" "$BASE_OUT/sensitive.after.txt"
assert_success 'the GRUB selection evidence should be valid JSON' python3 -m json.tool "$BASE_OUT/grub-selection.json"

mapfile -t SAVED_CASE < <(create_case saved-entry)
SAVED_ROOT=${SAVED_CASE[0]}; SAVED_RECOVERY=${SAVED_CASE[1]}; SAVED_CHECKPOINT=${SAVED_CASE[2]}; SAVED_REVIEW=${SAVED_CASE[3]}; SAVED_OUT="$TMP/saved-entry-output"
cat > "$SAVED_ROOT/boot/grub/grub.cfg" <<'EOF_GRUB_SAVED'
set default="${saved_entry}"
menuentry 'Slackware generic' $menuentry_id_option 'slackware-generic' {
  linux /boot/vmlinuz-generic root=/dev/sda2 ro
  initrd /boot/initrd-generic.img
}
menuentry 'Diagnostic shell' $menuentry_id_option 'diagnostic-shell' {
  linux /boot/vmlinuz-diagnostic root=/dev/sda2 ro
}
EOF_GRUB_SAVED
printf 'saved_entry=slackware-generic
' > "$SAVED_ROOT/boot/grub/grubenv"
refresh_case_policies "$SAVED_ROOT" "$SAVED_RECOVERY" "$SAVED_CHECKPOINT" "$SAVED_REVIEW"
assert_success 'a saved GRUB entry ID should resolve to the reviewed generic pair' run_script "$SAVED_ROOT" "$SAVED_RECOVERY" "$SAVED_CHECKPOINT" "$SAVED_REVIEW" "$SAVED_OUT"
assert_contains '"selected_entry_id": "slackware-generic"' "$SAVED_OUT/grub-selection.json" 'the saved-entry evidence should record the resolved GRUB ID'

mapfile -t SUBMENU_CASE < <(create_case submenu-entry)
SUBMENU_ROOT=${SUBMENU_CASE[0]}; SUBMENU_RECOVERY=${SUBMENU_CASE[1]}; SUBMENU_CHECKPOINT=${SUBMENU_CASE[2]}; SUBMENU_REVIEW=${SUBMENU_CASE[3]}; SUBMENU_OUT="$TMP/submenu-entry-output"
cat > "$SUBMENU_ROOT/boot/grub/grub.cfg" <<'EOF_GRUB_SUBMENU'
set default="1>0"
menuentry 'Diagnostic shell' --id diagnostic-shell {
  linux /boot/vmlinuz-diagnostic root=/dev/sda2 ro
}
submenu 'Advanced Slackware options' --id slackware-advanced {
  menuentry 'Slackware generic' --id slackware-generic {
    linux /boot/vmlinuz-generic root=/dev/sda2 ro
    initrd /boot/initrd-generic.img
  }
}
EOF_GRUB_SUBMENU
refresh_case_policies "$SUBMENU_ROOT" "$SUBMENU_RECOVERY" "$SUBMENU_CHECKPOINT" "$SUBMENU_REVIEW"
assert_success 'a numeric submenu selector should resolve to the reviewed generic pair' run_script "$SUBMENU_ROOT" "$SUBMENU_RECOVERY" "$SUBMENU_CHECKPOINT" "$SUBMENU_REVIEW" "$SUBMENU_OUT"
assert_contains '"selector": "1>0"' "$SUBMENU_OUT/grub-selection.json" 'the submenu evidence should record the complete selector path'

negative_case() {
    local name=$1 mutation=$2 refresh=${3:-no} root recovery checkpoint review output
    mapfile -t CASE < <(create_case "$name")
    root=${CASE[0]}; recovery=${CASE[1]}; checkpoint=${CASE[2]}; review=${CASE[3]}; output="$TMP/$name-output"
    eval "$mutation"
    if [ "$refresh" = yes ]; then
        refresh_case_policies "$root" "$recovery" "$checkpoint" "$review"
    fi
    assert_failure "$name should fail closed" run_script "$root" "$recovery" "$checkpoint" "$review" "$output"
    [ -f "$output/summary.txt" ] && assert_contains 'reboot_authorized=false' "$output/summary.txt" "$name must not authorize reboot"
}

negative_case kernel-hash 'printf tampered >> "$root/boot/vmlinuz-6.18.42"'
negative_case initrd-link 'rm "$root/boot/initrd-generic.img"; ln -s initrd-6.18.41.img "$root/boot/initrd-generic.img"'
negative_case package-drift 'printf changed >> "$root/var/lib/pkgtools/packages/dummy-1.0-x86_64-1"'
negative_case geninitrd-drift 'printf changed >> "$root/etc/default/geninitrd"'
negative_case grub-hash 'printf "# changed\n" >> "$root/boot/grub/grub.cfg"'
negative_case old-kernel-image-returned 'printf old > "$root/boot/vmlinuz-6.18.40"'
negative_case cmdline-not-generic 'printf "BOOT_IMAGE=/boot/vmlinuz-6.18.40 root=UUID=test ro\n" > "$root/proc/cmdline"'
negative_case grub-next-entry 'printf "next_entry=diagnostic-shell\n" > "$root/boot/grub/grubenv"'
negative_case wrong-effective-default 'sed -i "s/set default=\"0\"/set default=\"1\"/" "$root/boot/grub/grub.cfg"' yes
negative_case missing-saved-entry 'sed -i "s/set default=\"0\"/set default=\"\${saved_entry}\"/" "$root/boot/grub/grub.cfg"; printf "saved_entry=missing-entry\n" > "$root/boot/grub/grubenv"' yes
negative_case unsupported-default-expression 'sed -i "s/set default=\"0\"/set default=\"\${unsupported_selector}\"/" "$root/boot/grub/grub.cfg"' yes

mapfile -t CMDLINE_CASE < <(create_case cmdline-pause-safe)
CMDLINE_ROOT=${CMDLINE_CASE[0]}; CMDLINE_RECOVERY=${CMDLINE_CASE[1]}; CMDLINE_CHECKPOINT=${CMDLINE_CASE[2]}; CMDLINE_REVIEW=${CMDLINE_CASE[3]}; CMDLINE_OUT="$TMP/cmdline-pause-safe-output"
printf 'BOOT_IMAGE=/boot/vmlinuz-6.18.40 root=UUID=test ro\n' > "$CMDLINE_ROOT/proc/cmdline"
assert_failure 'a changed boot image should block reboot authorization' run_script "$CMDLINE_ROOT" "$CMDLINE_RECOVERY" "$CMDLINE_CHECKPOINT" "$CMDLINE_REVIEW" "$CMDLINE_OUT"
assert_contains 'pause_safe=true' "$CMDLINE_OUT/summary.txt" 'a reboot-only failure should preserve the installed safe-pause checkpoint'
assert_contains 'reboot_ready=false' "$CMDLINE_OUT/summary.txt" 'a reboot-only failure should clear readiness'
assert_contains 'next_stage=current-kernel-post-apply-reboot-review-correction' "$CMDLINE_OUT/summary.txt" 'a reboot-only failure should request review correction'

mapfile -t SCOPE_CASE < <(create_case authorization-scope)
SCOPE_ROOT=${SCOPE_CASE[0]}; SCOPE_RECOVERY=${SCOPE_CASE[1]}; SCOPE_CHECKPOINT=${SCOPE_CASE[2]}; SCOPE_REVIEW=${SCOPE_CASE[3]}; SCOPE_OUT="$TMP/authorization-scope-output"
python3 - "$SCOPE_REVIEW" <<'PY'
import json, pathlib, sys
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text()); d['authorization_scope_sha256']='f'*64; p.write_text(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
assert_failure 'a changed authorization scope should fail closed' run_script "$SCOPE_ROOT" "$SCOPE_RECOVERY" "$SCOPE_CHECKPOINT" "$SCOPE_REVIEW" "$SCOPE_OUT"
assert_contains 'reboot_authorized=false' "$SCOPE_OUT/summary.txt" 'a changed authorization scope must not authorize reboot'

mapfile -t GRUB_FAIL < <(create_case grub-check-fail)
GRUB_FAIL_ROOT=${GRUB_FAIL[0]}; GRUB_FAIL_RECOVERY=${GRUB_FAIL[1]}; GRUB_FAIL_CHECKPOINT=${GRUB_FAIL[2]}; GRUB_FAIL_REVIEW=${GRUB_FAIL[3]}; GRUB_FAIL_OUT="$TMP/grub-check-fail-output"
GRUB_CHECK_FAIL=1 assert_failure 'a GRUB syntax-check failure should block reboot authorization' run_script "$GRUB_FAIL_ROOT" "$GRUB_FAIL_RECOVERY" "$GRUB_FAIL_CHECKPOINT" "$GRUB_FAIL_REVIEW" "$GRUB_FAIL_OUT"

printf 'Current kernel post-apply reboot review harness: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
