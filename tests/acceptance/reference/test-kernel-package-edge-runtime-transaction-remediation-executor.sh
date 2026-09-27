#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd -P)
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
reference="$repo_root/tools/reference/slack-update-reference.sh"
config="$repo_root/data/config/slack-update.conf"

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail_test() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
contains() { grep -Fq -- "$2" "$1"; }
not_contains() { ! grep -Fq -- "$2" "$1"; }

for pair in \
    "$old_body|historical failed executor body" \
    "$old_builder|historical failed executor builder" \
    "$old_executor|historical failed executor payload" \
    "$body|remediated executor body" \
    "$builder|remediated executor builder" \
    "$executor|remediated canonical executor" \
    "$reference|frozen reference script" \
    "$config|frozen effective configuration"; do
    file=${pair%%|*}
    label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail_test "$label is missing or unsafe"; fi
done

[[ $(sha "$old_body") == '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581' ]] && pass 'historical failed executor body hash is unchanged' || fail_test 'historical failed executor body hash drift'
[[ $(sha "$old_builder") == '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea' ]] && pass 'historical failed executor builder hash is unchanged' || fail_test 'historical failed executor builder hash drift'
[[ $(sha "$old_executor") == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' ]] && pass 'historical failed executor payload hash is unchanged' || fail_test 'historical failed executor payload hash drift'
[[ $(sha "$reference") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'reference script matches frozen SHA-256' || fail_test 'reference script SHA-256 drift'
[[ $(sha "$config") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'effective configuration matches frozen SHA-256' || fail_test 'effective configuration SHA-256 drift'
[[ $(sha "$body") == 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b' ]] && pass 'remediated executor body matches reviewed SHA-256' || fail_test 'remediated executor body SHA-256 drift'
[[ $(sha "$builder") == 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379' ]] && pass 'remediated builder matches reviewed SHA-256' || fail_test 'remediated builder SHA-256 drift'
[[ $(sha "$executor") == '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' ]] && pass 'remediated canonical executor matches reviewed SHA-256' || fail_test 'remediated canonical executor SHA-256 drift'

bash -n "$body" && pass 'remediated executor body passes bash syntax validation' || fail_test 'remediated executor body has invalid shell syntax'
bash -n "$builder" && pass 'remediated builder passes bash syntax validation' || fail_test 'remediated builder has invalid shell syntax'
bash -n "$executor" && pass 'remediated canonical executor passes bash syntax validation' || fail_test 'remediated canonical executor has invalid shell syntax'
"$builder" --help >/dev/null 2>&1 && pass 'remediated builder exposes non-mutating help' || fail_test 'remediated builder help failed'
"$executor" --help >/dev/null 2>&1 && pass 'remediated executor exposes non-mutating help' || fail_test 'remediated executor help failed'
if "$builder" --unknown >/dev/null 2>&1; then fail_test 'remediated builder accepts unknown option'; else pass 'remediated builder rejects unknown option'; fi
if "$executor" --unknown >/dev/null 2>&1; then fail_test 'remediated executor accepts unknown option'; else pass 'remediated executor rejects unknown option'; fi
if "$executor" >/dev/null 2>&1; then fail_test 'remediated executor runs without explicit runtime acknowledgement'; else pass 'remediated executor rejects missing runtime acknowledgement'; fi

regen=$(mktemp -d)
trap 'rm -rf -- "$regen"' EXIT
if "$builder" --repo-root "$repo_root" --output "$regen/executor.sh" >/dev/null 2>&1; then pass 'remediated builder generates executor from frozen repository inputs'; else fail_test 'remediated builder generation failed'; fi
if cmp -s "$executor" "$regen/executor.sh"; then pass 'remediated builder reproduces canonical executor byte-for-byte'; else fail_test 'remediated builder output differs from canonical executor'; fi
[[ $(sha "$regen/executor.sh") == '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' ]] && pass 'regenerated remediated executor has reviewed SHA-256' || fail_test 'regenerated remediated executor SHA-256 mismatch'

awk '$0=="__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__"{f=1;next}$0=="__SLACK_UPDATE_REFERENCE_PAYLOAD_END__"{f=0;exit}f' "$executor" | base64 -d > "$regen/reference.sh"
awk '$0=="__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__"{f=1;next}$0=="__SLACK_UPDATE_CONFIG_PAYLOAD_END__"{f=0;exit}f' "$executor" | base64 -d > "$regen/config.conf"
[[ $(sha "$regen/reference.sh") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'remediated executor embeds exact frozen reference bytes' || fail_test 'embedded reference bytes differ'
[[ $(sha "$regen/config.conf") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'remediated executor embeds exact frozen configuration bytes' || fail_test 'embedded configuration bytes differ'

for needle in \
    "readonly EXPECTED_BOOT_ID='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'" \
    "readonly PREDECESSOR_RECORD='kernel-headers-6.18.44-x86-1'" \
    "readonly TARGET_RECORD='kernel-headers-6.18.45-x86-1'" \
    "readonly TARGET_NAME='kernel-headers'" \
    "readonly TARGET_VERSION='6.18.45'" \
    "readonly TARGET_ARCH='x86'" \
    "readonly TARGET_BUILD='1'" \
    "readonly TARGET_LOCATION='./slackware64/d'" \
    "readonly TARGET_PRIORITY_TREE='slackware64'" \
    "readonly LOCAL_SOURCE_URI='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/'" \
    "readonly EXPECTED_TREE_MANIFEST_SHA256='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'" \
    "readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation'" \
    "readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz'"; do
    contains "$executor" "$needle" && pass "remediated executor freezes: ${needle#readonly }" || fail_test "remediated executor missing frozen constant: $needle"
done

for needle in \
    "readonly LOCAL_SOURCE_V1_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'" \
    "readonly EXPECTED_LOCAL_SOURCE_V1_MANIFEST_SHA256='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'" \
    "readonly FAILED_EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'" \
    "readonly FAILED_PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz'"; do
    contains "$executor" "$needle" && pass "remediated executor preserves historical input: ${needle#readonly }" || fail_test "remediated executor missing historical preservation constant: $needle"
done

contains "$body" '--execute-runtime-remediation-validation' && pass 'remediated executor uses new explicit runtime acknowledgement' || fail_test 'remediated runtime acknowledgement missing'
not_contains "$body" 'Usage: phase-1-kernel-package-edge-runtime-transaction-executor.sh --execute-runtime-validation' && pass 'remediated body does not reuse historical acknowledgement' || fail_test 'historical acknowledgement leaked into remediated body'

for needle in \
    'verify_preserved_inputs' \
    'verify_target_identity' \
    'verify_local_source_tree' \
    'verify_v2_manifest_coverage' \
    'backup_mutable_state' \
    'trap cleanup_on_exit EXIT' \
    'upgradepkg "$PREDECESSOR_TRANSPORT"' \
    'verify_header_only_staging_delta' \
    'configure_temporary_slackpkg' \
    'run_local_metadata_refresh' \
    'bind_candidate_set' \
    'unshare -n -- env SLACK_UPDATE_CONFIG="$DERIVED_CONFIG" bash "$REFERENCE_FILE" --apply --json' \
    'restore_transaction_state' \
    'verify_final_invariants' \
    'publish_evidence'; do
    contains "$body" "$needle" && pass "remediated body implements reviewed boundary: $needle" || fail_test "remediated body missing reviewed boundary: $needle"
done

contains "$body" 'SLACKPKG_WORKDIR="$RUN_DIR/slackpkg-workdir"' && pass 'transaction owns isolated Slackpkg WORKDIR' || fail_test 'isolated Slackpkg WORKDIR missing'
contains "$body" 'SLACKPKG_CACHE="$RUN_DIR/slackpkg-cache"' && pass 'transaction owns isolated Slackpkg TEMP cache' || fail_test 'isolated Slackpkg TEMP cache missing'
contains "$body" 'print "WORKDIR=" workdir' && pass 'temporary slackpkg.conf rewrites WORKDIR' || fail_test 'WORKDIR rewrite missing'
contains "$body" 'print "TEMP=" temp' && pass 'temporary slackpkg.conf rewrites TEMP' || fail_test 'TEMP rewrite missing'
contains "$body" 'print "CHECKGPG=off"' && pass 'temporary slackpkg.conf bounds CHECKGPG compatibility mode' || fail_test 'CHECKGPG compatibility override missing'
contains "$body" '[[ -z $(find "$SLACKPKG_WORKDIR" -mindepth 1 -print -quit) ]]' && pass 'transaction WORKDIR must start empty' || fail_test 'empty transaction WORKDIR guard missing'
contains "$body" '[[ ! -e "$SLACKPKG_WORKDIR/pkglist" && ! -L "$SLACKPKG_WORKDIR/pkglist" ]]' && pass 'transaction pkglist must be absent before refresh' || fail_test 'pre-refresh pkglist absence guard missing'
contains "$body" 'local pkglist="$SLACKPKG_WORKDIR/pkglist"' && pass 'fresh candidate source is transaction-owned pkglist' || fail_test 'candidate source does not use transaction-owned pkglist'
not_contains "$body" 'local pkglist="$SLACKPKG_STATE/pkglist"' && pass 'canonical /var/lib/slackpkg pkglist is non-authoritative' || fail_test 'historical canonical pkglist binding remains active'

contains "$body" 'unshare -n -- slackpkg -batch=on -default_answer=y update' && pass 'metadata refresh runs with external network namespace disabled' || fail_test 'network-isolated metadata refresh missing'
contains "$body" "grep -Fqi 'error-downloading-from-local-source'" && pass 'metadata refresh rejects silent local-source error signal' || fail_test 'local-source error-signal guard missing'
contains "$body" '[[ $rc -eq 0 ]]' && pass 'metadata refresh requires zero exit status' || fail_test 'metadata refresh zero-exit guard missing'
contains "$body" "record_kv \"\$RUN_DIR/slackpkg-refresh.tsv\" refreshed_pkglist_sha256" && pass 'refresh evidence records fresh pkglist SHA-256' || fail_test 'refresh pkglist SHA-256 evidence missing'

contains "$body" 'if [[ $dir == "$TARGET_PRIORITY_TREE" && $name == "$TARGET_NAME" && $version == "$TARGET_VERSION" && $arch == "$TARGET_ARCH" && $release == "$TARGET_BUILD" && $fullname == "$TARGET_RECORD" && $path == "$TARGET_LOCATION" && $ext == txz ]]' && pass 'candidate guard matches exact pkglist fields' || fail_test 'exact target-field candidate guard missing'
contains "$body" 'source_package="$LOCAL_SOURCE_ROOT/${path#./}/$fullname.$ext"' && pass 'candidate classification requires a backing package in frozen v2 source' || fail_test 'candidate classification is not source-backed'
contains "$body" '[[ -f $source_package && ! -L $source_package ]] || continue' && pass 'auxiliary pkglist rows are ignored unless backed by source package bytes' || fail_test 'auxiliary metadata row tolerance missing'
contains "$body" '[[ $target_count -eq 1 ]]' && pass 'candidate guard requires exactly one target row' || fail_test 'exact target count guard missing'
contains "$body" '[[ $install_new_count -eq 0 ]]' && pass 'candidate guard rejects install-new source candidates' || fail_test 'install-new guard missing'
contains "$body" '[[ $non_header_upgrade_count -eq 0 ]]' && pass 'candidate guard rejects non-header source upgrades' || fail_test 'non-header upgrade guard missing'
contains "$body" '[[ $configured_boot_upgrade_count -eq 0 ]]' && pass 'candidate guard rejects configured boot-package source upgrades' || fail_test 'boot-package candidate guard missing'
not_contains "$body" "line_count=\$(awk 'NF {count++} END {print count+0}'" && pass 'global pkglist row-count guard is retired' || fail_test 'historical global pkglist row-count guard remains'
not_contains "$body" 'package rows instead of exactly one' && pass 'historical global-row failure text is absent from remediated body' || fail_test 'historical global-row assumption remains in remediated body'

for needle in \
    'record_kv "$RUN_DIR/preflight.tsv" preflight_status PASS' \
    'record_kv "$RUN_DIR/candidate-binding.tsv" binding_status PASS' \
    'record_kv "$RUN_DIR/result.tsv" runtime_remediation_validation_status PASS'; do
    contains "$body" "$needle" && pass "evidence path uses real-tab record_kv: $needle" || fail_test "record_kv evidence path missing: $needle"
done
not_contains "$body" 'binding_status\tPASS' && pass 'candidate evidence contains no literal backslash-t separator' || fail_test 'candidate evidence still contains literal backslash-t separator'
not_contains "$body" 'preflight_status\tPASS' && pass 'preflight evidence contains no literal backslash-t separator' || fail_test 'preflight evidence still contains literal backslash-t separator'

for needle in \
    'flatpak" && /^mode=/ { print "mode=disabled"' \
    'sbo" && /^mode=/ { print "mode=disabled"' \
    'elf" && /^mode=/ { print "mode=disabled"' \
    'cinnamon" && /^mode=/ { print "mode=disabled"'; do
    contains "$body" "$needle" && pass 'derived configuration disables an unrelated secondary module' || fail_test "derived configuration override missing: $needle"
done
contains "$body" 'section == "core" && /^work_dir=/' && pass 'derived reference configuration redirects work directory' || fail_test 'derived reference work directory override missing'
contains "$body" 'section == "core" && /^log_dir=/' && pass 'derived reference configuration redirects log directory' || fail_test 'derived reference log directory override missing'
contains "$body" 'section == "core" && /^lock_file=/' && pass 'derived reference configuration redirects lock file' || fail_test 'derived reference lock-file override missing'
if contains "$body" 'section == "boot" && /^mode=/'; then fail_test 'remediated body rewrites boot.mode'; else pass 'derived reference configuration leaves boot.mode unchanged'; fi
if contains "$body" 'section == "slackware" && /'; then fail_test 'remediated body rewrites Slackware update policy'; else pass 'derived reference configuration leaves Slackware update policy unchanged'; fi

contains "$body" "grep -Fq 'puede requerir recompilacion de modulos externos'" && pass 'reference result requires external-module warning observation' || fail_test 'external-module warning guard missing'
contains "$body" "assert p['modules']['slackware']['kernel_changes'] is True" && pass 'reference JSON requires kernel trigger' || fail_test 'kernel-trigger JSON guard missing'
contains "$body" "assert boot['grub_command_attempted'] is False" && pass 'reference JSON forbids GRUB command execution' || fail_test 'GRUB command guard missing'
contains "$body" "assert boot['grub_config_replaced'] is False" && pass 'reference JSON forbids GRUB replacement' || fail_test 'GRUB replacement guard missing'

contains "$body" 'rm -rf -- "$SLACKPKG_STATE"' && contains "$body" 'cp -a -- "$BACKUP_ROOT/slackpkg-state" "$SLACKPKG_STATE"' && pass 'rollback restores canonical Slackpkg state from private backup' || fail_test 'Slackpkg state rollback is incomplete'
contains "$body" 'restore_target_header' && contains "$body" 'upgradepkg --install-new "$STAGED_TARGET"' && pass 'rollback can restore frozen target header' || fail_test 'target-header rollback path missing'
contains "$body" 'GENINITRD_FINGERPRINT_BEFORE' && contains "$body" 'restore_geninitrd_policy' && pass 'rollback protects GenInitrd policy fingerprint' || fail_test 'GenInitrd rollback path missing'
contains "$body" 'verify_preserved_inputs' && [[ $(grep -F -c 'verify_preserved_inputs' "$body") -ge 3 ]] && pass 'preserved v1 and failed evidence are checked before and after transaction' || fail_test 'preservation checks do not cover final gate'

contains "$body" '[[ ! -e $EVIDENCE_ROOT && ! -L $EVIDENCE_ROOT ]]' && pass 'remediated executor requires fresh evidence root' || fail_test 'fresh evidence-root preflight missing'
contains "$body" '[[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]]' && pass 'remediated executor refuses to overwrite prior remediation evidence' || fail_test 'published remediation-evidence overwrite guard missing'
contains "$body" 'external_network_access_performed no' && pass 'published result records no external network access' || fail_test 'network evidence flag missing'
contains "$body" 'reboot_performed no' && pass 'published result records no reboot' || fail_test 'reboot evidence flag missing'

if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$body"; then fail_test 'remediated executor body contains an external network client command'; else pass 'remediated executor body contains no external network client command'; fi
if grep -Eq '\b(reboot|shutdown|poweroff)\b' "$body"; then fail_test 'remediated executor body contains a reboot or shutdown command'; else pass 'remediated executor body contains no reboot or shutdown command'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg)\b' "$builder"; then fail_test 'controller builder contains a package-management execution command'; else pass 'controller builder contains no package-management execution command'; fi
if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$builder"; then fail_test 'controller builder contains a network client command'; else pass 'controller builder contains no network client command'; fi

# Synthetic candidate-binding check: auxiliary pkglist rows without backing v2 package bytes must not become candidates.
cat > "$regen/candidate-unit.sh" <<'EOF_UNIT'
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
RUN_DIR=$1
SLACKPKG_WORKDIR="$RUN_DIR/workdir"
LOCAL_SOURCE_ROOT="$RUN_DIR/source"
LOCAL_SOURCE_TARGET="$LOCAL_SOURCE_ROOT/slackware64/d/kernel-headers-6.18.45-x86-1.txz"
TARGET_SHA256=$(sha256sum "$LOCAL_SOURCE_TARGET" | awk '{print $1}')
TARGET_PRIORITY_TREE=slackware64
TARGET_NAME=kernel-headers
TARGET_VERSION=6.18.45
TARGET_ARCH=x86
TARGET_BUILD=1
TARGET_RECORD=kernel-headers-6.18.45-x86-1
TARGET_LOCATION=./slackware64/d
EXPECTED_TREE_MANIFEST_SHA256=test-manifest
PREDECESSOR_RECORD=kernel-headers-6.18.44-x86-1
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
regular_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
package_records() { [[ $1 == kernel-headers ]] && printf '%s\n' "$PREDECESSOR_RECORD" || true; }
verify_local_source_tree() { :; }
record_kv() { printf '%s\t%s\n' "$2" "$3" >> "$1"; }
EOF_UNIT
awk '/^bind_candidate_set\(\)/{f=1} f{print} f && /^}/{exit}' "$body" >> "$regen/candidate-unit.sh"
cat >> "$regen/candidate-unit.sh" <<'EOF_UNIT'
bind_candidate_set
EOF_UNIT
chmod +x "$regen/candidate-unit.sh"
mkdir -p "$regen/unit/source/slackware64/d" "$regen/unit/workdir"
printf 'target\n' > "$regen/unit/source/slackware64/d/kernel-headers-6.18.45-x86-1.txz"
cat > "$regen/unit/workdir/pkglist" <<'EOF_PKGLIST'
slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz
slackware64 auxiliary-metadata 1.0 x86_64 1 auxiliary-metadata-1.0-x86_64-1 ./slackware64/a txz
EOF_PKGLIST
if "$regen/candidate-unit.sh" "$regen/unit" >/dev/null 2>&1; then pass 'target-specific candidate guard tolerates auxiliary pkglist rows without backing v2 package bytes'; else fail_test 'target-specific candidate guard incorrectly rejects auxiliary metadata row'; fi
if grep -Fxq $'target_candidate_count\t1' "$regen/unit/candidate-binding.tsv" && grep -Fxq $'install_new_count\t0' "$regen/unit/candidate-binding.tsv" && grep -Fxq $'non_header_upgrade_count\t0' "$regen/unit/candidate-binding.tsv"; then pass 'synthetic candidate evidence records exactly one target and zero unexpected candidates'; else fail_test 'synthetic candidate evidence does not match frozen counts'; fi

mkdir -p "$regen/unit-fail/source/slackware64/d" "$regen/unit-fail/source/slackware64/a" "$regen/unit-fail/workdir"
printf 'target\n' > "$regen/unit-fail/source/slackware64/d/kernel-headers-6.18.45-x86-1.txz"
printf 'unexpected\n' > "$regen/unit-fail/source/slackware64/a/unexpected-1.0-x86_64-1.txz"
cat > "$regen/unit-fail/workdir/pkglist" <<'EOF_PKGLIST'
slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz
slackware64 unexpected 1.0 x86_64 1 unexpected-1.0-x86_64-1 ./slackware64/a txz
EOF_PKGLIST
if "$regen/candidate-unit.sh" "$regen/unit-fail" >/dev/null 2>&1; then fail_test 'target-specific candidate guard accepts unexpected source-backed install-new candidate'; else pass 'target-specific candidate guard rejects unexpected source-backed install-new candidate'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
