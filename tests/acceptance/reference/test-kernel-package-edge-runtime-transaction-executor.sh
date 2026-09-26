#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd -P)
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
reference="$repo_root/tools/reference/slack-update-reference.sh"
config="$repo_root/data/config/slack-update.conf"

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for pair in \
    "$builder|builder" \
    "$body|executor body" \
    "$executor|canonical executor" \
    "$reference|frozen reference script" \
    "$config|frozen effective configuration"; do
    file=${pair%%|*}
    label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$reference") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'reference script matches frozen SHA-256' || fail 'reference script SHA-256 drift'
[[ $(sha "$config") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'effective configuration matches frozen SHA-256' || fail 'effective configuration SHA-256 drift'
[[ $(sha "$body") == '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581' ]] && pass 'executor body matches reviewed SHA-256' || fail 'executor body SHA-256 drift'
[[ $(sha "$builder") == '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea' ]] && pass 'builder matches reviewed SHA-256' || fail 'builder SHA-256 drift'
[[ $(sha "$executor") == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' ]] && pass 'canonical executor matches reviewed SHA-256' || fail 'canonical executor SHA-256 drift'

bash -n "$builder" && pass 'builder passes bash syntax validation' || fail 'builder has invalid shell syntax'
bash -n "$body" && pass 'executor body passes bash syntax validation' || fail 'executor body has invalid shell syntax'
bash -n "$executor" && pass 'canonical executor passes bash syntax validation' || fail 'canonical executor has invalid shell syntax'
"$builder" --help >/dev/null 2>&1 && pass 'builder exposes non-mutating help' || fail 'builder help failed'
"$executor" --help >/dev/null 2>&1 && pass 'executor exposes non-mutating help' || fail 'executor help failed'
if "$builder" --unknown >/dev/null 2>&1; then fail 'builder accepts unknown option'; else pass 'builder rejects unknown option'; fi
if "$executor" --unknown >/dev/null 2>&1; then fail 'executor accepts unknown option'; else pass 'executor rejects unknown option'; fi
if "$executor" >/dev/null 2>&1; then fail 'executor runs without explicit runtime acknowledgement'; else pass 'executor rejects missing runtime acknowledgement'; fi

regen=$(mktemp -d)
trap 'rm -rf -- "$regen"' EXIT
if "$builder" --repo-root "$repo_root" --output "$regen/executor.sh" >/dev/null 2>&1; then pass 'builder generates an executor from frozen repository inputs'; else fail 'builder generation failed'; fi
if cmp -s "$executor" "$regen/executor.sh"; then pass 'builder reproduces canonical executor byte-for-byte'; else fail 'builder output differs from canonical executor'; fi
[[ $(sha "$regen/executor.sh") == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' ]] && pass 'regenerated executor has reviewed SHA-256' || fail 'regenerated executor SHA-256 mismatch'

awk '$0=="__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__"{f=1;next}$0=="__SLACK_UPDATE_REFERENCE_PAYLOAD_END__"{f=0;exit}f' "$executor" | base64 -d > "$regen/reference.sh"
awk '$0=="__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__"{f=1;next}$0=="__SLACK_UPDATE_CONFIG_PAYLOAD_END__"{f=0;exit}f' "$executor" | base64 -d > "$regen/config.conf"
[[ $(sha "$regen/reference.sh") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'executor embeds exact frozen reference bytes' || fail 'embedded reference bytes differ'
[[ $(sha "$regen/config.conf") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'executor embeds exact frozen configuration bytes' || fail 'embedded configuration bytes differ'

for needle in \
    "readonly EXPECTED_BOOT_ID='91901677-1dc3-4a39-a4b1-3f87e6875234'" \
    "readonly PREDECESSOR_RECORD='kernel-headers-6.18.44-x86-1'" \
    "readonly TARGET_RECORD='kernel-headers-6.18.45-x86-1'" \
    "readonly LOCAL_SOURCE_URI='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source/'" \
    "readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'"; do
    grep -Fq "$needle" "$executor" && pass "executor freezes: ${needle#readonly }" || fail "executor missing frozen constant: $needle"
done

for needle in \
    'verify_target_identity' \
    'backup_mutable_state' \
    'trap cleanup_on_exit EXIT' \
    'upgradepkg "$PREDECESSOR_TRANSPORT"' \
    'verify_header_only_staging_delta' \
    'configure_temporary_slackpkg' \
    'unshare -n -- slackpkg -batch=on -default_answer=y update' \
    'bind_candidate_set' \
    'same-runtime-transaction-only' \
    'unshare -n -- env SLACK_UPDATE_CONFIG="$DERIVED_CONFIG" bash "$REFERENCE_FILE" --apply --json' \
    'restore_transaction_state' \
    'verify_final_invariants' \
    'publish_evidence'; do
    grep -Fq "$needle" "$body" && pass "executor body implements reviewed boundary: $needle" || fail "executor body missing reviewed boundary: $needle"
done

for needle in \
    'flatpak" && /^mode=/ { print "mode=disabled"' \
    'sbo" && /^mode=/ { print "mode=disabled"' \
    'elf" && /^mode=/ { print "mode=disabled"' \
    'cinnamon" && /^mode=/ { print "mode=disabled"'; do
    grep -Fq "$needle" "$body" && pass 'derived configuration disables an unrelated secondary module' || fail "derived configuration override missing: $needle"
done

grep -Fq 'section == "core" && /^work_dir=/' "$body" && pass 'derived configuration redirects work directory' || fail 'derived work directory override missing'
grep -Fq 'section == "core" && /^log_dir=/' "$body" && pass 'derived configuration redirects log directory' || fail 'derived log directory override missing'
grep -Fq 'section == "core" && /^lock_file=/' "$body" && pass 'derived configuration redirects lock file' || fail 'derived lock-file override missing'
if grep -Fq 'section == "boot" && /^mode=/' "$body"; then fail 'executor body rewrites boot.mode'; else pass 'derived configuration leaves boot.mode unchanged'; fi
if grep -Fq 'section == "slackware" && /' "$body"; then fail 'executor body rewrites Slackware update policy'; else pass 'derived configuration leaves Slackware update policy unchanged'; fi

for needle in \
    'upgrade_count\t1' \
    'install_new_count\t0' \
    'non_header_upgrade_count\t0' \
    'configured_boot_upgrade_count\t0'; do
    grep -Fq "$needle" "$body" && pass "candidate evidence freezes $needle" || fail "candidate evidence missing $needle"
done

grep -Fq "grep -Fq 'puede requerir recompilacion de modulos externos'" "$body" && pass 'reference result requires external-module warning observation' || fail 'external-module warning guard missing'
grep -Fq "assert p['modules']['slackware']['kernel_changes'] is True" "$body" && pass 'reference JSON requires kernel trigger' || fail 'kernel-trigger JSON guard missing'
grep -Fq "assert boot['grub_command_attempted'] is False" "$body" && pass 'reference JSON forbids GRUB command execution' || fail 'GRUB command guard missing'
grep -Fq "assert boot['grub_config_replaced'] is False" "$body" && pass 'reference JSON forbids GRUB replacement' || fail 'GRUB replacement guard missing'

grep -Fq 'rm -rf -- "$SLACKPKG_STATE"' "$body" && grep -Fq 'cp -a -- "$BACKUP_ROOT/slackpkg-state" "$SLACKPKG_STATE"' "$body" && pass 'rollback restores Slackpkg state from private backup' || fail 'Slackpkg state rollback is incomplete'
grep -Fq 'restore_target_header' "$body" && grep -Fq 'upgradepkg --install-new "$STAGED_TARGET"' "$body" && pass 'rollback can restore frozen target header' || fail 'target-header rollback path missing'
grep -Fq 'GENINITRD_FINGERPRINT_BEFORE' "$body" && grep -Fq 'restore_geninitrd_policy' "$body" && pass 'rollback protects GenInitrd policy fingerprint' || fail 'GenInitrd rollback path missing'

grep -Fq '[[ ! -e $EVIDENCE_ROOT && ! -L $EVIDENCE_ROOT ]]' "$body" && pass 'executor requires a fresh evidence root' || fail 'fresh evidence-root preflight missing'
grep -Fq '[[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]]' "$body" && pass 'executor refuses to overwrite prior published evidence' || fail 'published-evidence overwrite guard missing'
grep -Fq 'external_network_access_performed no' "$body" && pass 'published result records no external network access' || fail 'network evidence flag missing'
grep -Fq 'reboot_performed no' "$body" && pass 'published result records no reboot' || fail 'reboot evidence flag missing'

if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$body"; then fail 'executor body contains an external network client command'; else pass 'executor body contains no external network client command'; fi
if grep -Eq '\b(reboot|shutdown|poweroff)\b' "$body"; then fail 'executor body contains a reboot or shutdown command'; else pass 'executor body contains no reboot or shutdown command'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg)\b' "$builder"; then fail 'controller builder contains a package-management execution command'; else pass 'controller builder contains no package-management execution command'; fi
if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$builder"; then fail 'controller builder contains a network client command'; else pass 'controller builder contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
