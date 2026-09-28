#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd -P)
historical_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
historical_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
historical_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
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
    "$historical_body|historical failed remediation executor body" \
    "$historical_builder|historical failed remediation executor builder" \
    "$historical_executor|historical failed remediation executor payload" \
    "$body|v2 executor body" \
    "$builder|v2 executor builder" \
    "$executor|v2 canonical executor" \
    "$reference|frozen reference script" \
    "$config|frozen effective configuration"; do
    file=${pair%%|*}
    label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail_test "$label is missing or unsafe"; fi
done

[[ $(sha "$historical_body") == 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b' ]] && pass 'historical failed remediation body hash is unchanged' || fail_test 'historical failed remediation body hash drift'
[[ $(sha "$historical_builder") == 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379' ]] && pass 'historical failed remediation builder hash is unchanged' || fail_test 'historical failed remediation builder hash drift'
[[ $(sha "$historical_executor") == '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' ]] && pass 'historical failed remediation executor hash is unchanged' || fail_test 'historical failed remediation executor hash drift'
[[ $(sha "$reference") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'reference script matches frozen SHA-256' || fail_test 'reference script SHA-256 drift'
[[ $(sha "$config") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'effective configuration matches frozen SHA-256' || fail_test 'effective configuration SHA-256 drift'
[[ $(sha "$body") == 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68' ]] && pass 'v2 executor body matches reviewed SHA-256' || fail_test 'v2 executor body SHA-256 drift'
[[ $(sha "$builder") == '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da' ]] && pass 'v2 builder matches reviewed SHA-256' || fail_test 'v2 builder SHA-256 drift'
[[ $(sha "$executor") == 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' ]] && pass 'v2 canonical executor matches reviewed SHA-256' || fail_test 'v2 canonical executor SHA-256 drift'

bash -n "$body" && pass 'v2 body passes bash syntax validation' || fail_test 'v2 body has invalid shell syntax'
bash -n "$builder" && pass 'v2 builder passes bash syntax validation' || fail_test 'v2 builder has invalid shell syntax'
bash -n "$executor" && pass 'v2 executor passes bash syntax validation' || fail_test 'v2 executor has invalid shell syntax'
"$builder" --help >/dev/null 2>&1 && pass 'v2 builder exposes non-mutating help' || fail_test 'v2 builder help failed'
"$executor" --help >/dev/null 2>&1 && pass 'v2 executor exposes non-mutating help' || fail_test 'v2 executor help failed'
if "$builder" --unknown >/dev/null 2>&1; then fail_test 'v2 builder accepts unknown option'; else pass 'v2 builder rejects unknown option'; fi
if "$executor" --unknown >/dev/null 2>&1; then fail_test 'v2 executor accepts unknown option'; else pass 'v2 executor rejects unknown option'; fi
if "$executor" >/dev/null 2>&1; then fail_test 'v2 executor runs without explicit runtime acknowledgement'; else pass 'v2 executor rejects missing runtime acknowledgement'; fi

regen=$(mktemp -d)
trap 'rm -rf -- "$regen"' EXIT
if "$builder" --repo-root "$repo_root" --output "$regen/executor.sh" >/dev/null 2>&1; then pass 'v2 builder generates executor from frozen repository inputs'; else fail_test 'v2 builder generation failed'; fi
if cmp -s "$executor" "$regen/executor.sh"; then pass 'v2 builder reproduces canonical executor byte-for-byte'; else fail_test 'v2 builder output differs from canonical executor'; fi
[[ $(sha "$regen/executor.sh") == 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' ]] && pass 'regenerated v2 executor has reviewed SHA-256' || fail_test 'regenerated v2 executor SHA-256 mismatch'

awk '$0=="__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__"{f=1;next}$0=="__SLACK_UPDATE_REFERENCE_PAYLOAD_END__"{f=0;exit}f' "$executor" | base64 -d > "$regen/reference.sh"
awk '$0=="__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__"{f=1;next}$0=="__SLACK_UPDATE_CONFIG_PAYLOAD_END__"{f=0;exit}f' "$executor" | base64 -d > "$regen/config.conf"
[[ $(sha "$regen/reference.sh") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'v2 executor embeds exact frozen reference bytes' || fail_test 'embedded reference bytes differ'
[[ $(sha "$regen/config.conf") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'v2 executor embeds exact frozen configuration bytes' || fail_test 'embedded configuration bytes differ'

for needle in \
    "readonly EXPECTED_BOOT_ID='047e744d-d2ea-4d9a-8746-7734b58db3b2'" \
    "readonly TARGET_RECORD='kernel-headers-6.18.45-x86-1'" \
    "readonly LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3'" \
    "readonly LOCAL_SOURCE_URI='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3/'" \
    "readonly EXPECTED_TREE_MANIFEST_SHA256='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'" \
    "readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation-v2'" \
    "readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz'"; do
    contains "$executor" "$needle" && pass "v2 executor freezes: ${needle#readonly }" || fail_test "v2 executor missing frozen constant: $needle"
done

for needle in \
    "readonly LOCAL_SOURCE_V2_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'" \
    "readonly EXPECTED_LOCAL_SOURCE_V2_MANIFEST_SHA256='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'" \
    "readonly FAILED_REMEDIATION_EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation'" \
    "readonly FAILED_REMEDIATION_PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz'"; do
    contains "$executor" "$needle" && pass "v2 executor preserves historical input: ${needle#readonly }" || fail_test "v2 executor missing historical preservation constant: $needle"
done

contains "$body" '--execute-runtime-remediation-v2-validation' && pass 'v2 executor uses the frozen explicit runtime acknowledgement' || fail_test 'v2 runtime acknowledgement missing'
not_contains "$body" '--execute-runtime-remediation-validation)' && pass 'v2 body does not accept historical remediation acknowledgement' || fail_test 'historical remediation acknowledgement remains accepted'

for needle in \
    'verify_preserved_inputs' \
    'verify_target_identity' \
    'verify_local_source_tree' \
    'verify_v3_manifest_coverage' \
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
    contains "$body" "$needle" && pass "v2 body implements frozen boundary: $needle" || fail_test "v2 body missing frozen boundary: $needle"
done

contains "$body" "grep -Fxq 'PGP compatibility marker for Slackpkg checkchangelog only.'" && pass 'v3 compatibility PGP marker is required exactly' || fail_test 'exact v3 compatibility PGP marker guard missing'
contains "$body" "! grep -Fq 'BEGIN PGP SIGNATURE'" && pass 'v3 compatibility artifact cannot impersonate OpenPGP signature' || fail_test 'OpenPGP impersonation guard missing'
contains "$body" 'SLACKPKG_WORKDIR="$RUN_DIR/slackpkg-workdir"' && pass 'transaction owns isolated Slackpkg WORKDIR' || fail_test 'isolated Slackpkg WORKDIR missing'
contains "$body" 'SLACKPKG_CACHE="$RUN_DIR/slackpkg-cache"' && pass 'transaction owns isolated Slackpkg TEMP cache' || fail_test 'isolated Slackpkg TEMP cache missing'
contains "$body" '[[ ! -e $pkglist && ! -L $pkglist ]]' && pass 'fresh transaction pkglist must be absent before refresh' || fail_test 'pre-refresh pkglist absence guard missing'
contains "$body" '> "$RUN_DIR/slackpkg-update.stdout" 2> "$RUN_DIR/slackpkg-update.stderr"' && pass 'Slackpkg refresh captures stdout and stderr separately' || fail_test 'Slackpkg stdout/stderr capture missing'
contains "$body" '[[ $rc -eq 0 ]]' && pass 'Slackpkg refresh requires exit status zero' || fail_test 'Slackpkg exit-zero guard missing'
contains "$body" "grep -Fqi 'Error downloading from '" && pass 'human-spaced Slackpkg download error guard is exact' || fail_test 'human-spaced Slackpkg error guard missing'
not_contains "$body" 'error-downloading-from-local-source' && pass 'hyphenated synthetic Slackpkg error literal is forbidden' || fail_test 'hyphenated synthetic Slackpkg error literal remains'
contains "$body" '[[ -f $pkglist && ! -L $pkglist ]]' && pass 'fresh transaction-owned pkglist is required after refresh' || fail_test 'post-refresh pkglist guard missing'
contains "$body" 'candidate_binding_lifetime same-runtime-transaction-only' && pass 'refresh evidence freezes same-transaction candidate-binding lifetime' || fail_test 'same-transaction binding evidence missing'

contains "$body" '[[ $target_count -eq 1 ]]' && pass 'candidate guard requires exactly one target row' || fail_test 'exact target candidate guard missing'
contains "$body" '[[ -f $source_package && ! -L $source_package ]] || continue' && pass 'candidate classification requires backing v3 package bytes' || fail_test 'source-backed candidate classification missing'
contains "$body" '[[ $install_new_count -eq 0 ]]' && pass 'candidate guard rejects install-new source candidates' || fail_test 'install-new guard missing'
contains "$body" '[[ $non_header_upgrade_count -eq 0 ]]' && pass 'candidate guard rejects non-header source upgrades' || fail_test 'non-header upgrade guard missing'
contains "$body" '[[ $configured_boot_upgrade_count -eq 0 ]]' && pass 'candidate guard rejects configured boot-package upgrades' || fail_test 'boot-package guard missing'
not_contains "$body" "line_count=\$(awk 'NF {count++} END {print count+0}'" && pass 'global pkglist row-count guard remains retired' || fail_test 'historical global pkglist row guard returned'

contains "$body" 'rm -rf -- "$SLACKPKG_STATE"' && contains "$body" 'cp -a -- "$BACKUP_ROOT/slackpkg-state" "$SLACKPKG_STATE"' && pass 'rollback restores canonical Slackpkg state from private backup' || fail_test 'Slackpkg state rollback is incomplete'
contains "$body" 'restore_target_header' && contains "$body" 'upgradepkg --install-new "$STAGED_TARGET"' && pass 'rollback can restore frozen target header' || fail_test 'target-header rollback path missing'
contains "$body" 'restore_geninitrd_policy' && pass 'rollback restores GenInitrd policy' || fail_test 'GenInitrd rollback path missing'
contains "$body" 'FAILED_REMEDIATION_EVIDENCE_ROOT' && contains "$body" "grep -Fqi 'Error downloading from '" && pass 'failed remediation evidence and human-spaced failure are preserved' || fail_test 'failed remediation preservation guard missing'
contains "$body" 'EXPECTED_LOCAL_SOURCE_V2_MANIFEST_SHA256' && contains "$body" "! grep -q 'PGP'" && pass 'historical local-source-v2 no-PGP state is preserved' || fail_test 'local-source-v2 preservation guard missing'

for needle in \
    'record_kv "$RUN_DIR/preflight.tsv" preflight_status PASS' \
    'record_kv "$RUN_DIR/candidate-binding.tsv" binding_status PASS' \
    'record_kv "$RUN_DIR/result.tsv" runtime_remediation_v2_validation_status PASS'; do
    contains "$body" "$needle" && pass "v2 evidence path uses real-tab record_kv: $needle" || fail_test "v2 record_kv evidence path missing: $needle"
done
not_contains "$body" 'binding_status\tPASS' && pass 'candidate evidence contains no literal backslash-t separator' || fail_test 'candidate evidence contains literal backslash-t separator'

contains "$body" '[[ ! -e $EVIDENCE_ROOT && ! -L $EVIDENCE_ROOT ]]' && pass 'v2 executor requires a fresh evidence root' || fail_test 'fresh v2 evidence-root preflight missing'
contains "$body" '[[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]]' && pass 'v2 executor refuses to overwrite success evidence' || fail_test 'published v2 evidence overwrite guard missing'
contains "$body" 'external_network_access_performed no' && pass 'published result records no external network access' || fail_test 'network evidence flag missing'
contains "$body" 'reboot_performed no' && pass 'published result records no reboot' || fail_test 'reboot evidence flag missing'

if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$body"; then fail_test 'v2 body contains an external network client command'; else pass 'v2 body contains no external network client command'; fi
if grep -Eq '\b(reboot|shutdown|poweroff)\b' "$body"; then fail_test 'v2 body contains a reboot or shutdown command'; else pass 'v2 body contains no reboot or shutdown command'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg)\b' "$builder"; then fail_test 'v2 builder contains a package-management execution command'; else pass 'v2 builder contains no package-management execution command'; fi
if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$builder"; then fail_test 'v2 builder contains a network client command'; else pass 'v2 builder contains no network client command'; fi

# Synthetic candidate binding: auxiliary pkglist rows without backing v3 bytes are ignored,
# while unexpected source-backed candidates fail closed.
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
if "$regen/candidate-unit.sh" "$regen/unit" >/dev/null 2>&1; then pass 'target-specific candidate guard tolerates auxiliary metadata rows without backing v3 bytes'; else fail_test 'candidate guard incorrectly rejects auxiliary metadata row'; fi
if grep -Fxq $'target_candidate_count\t1' "$regen/unit/candidate-binding.tsv" && grep -Fxq $'install_new_count\t0' "$regen/unit/candidate-binding.tsv"; then pass 'synthetic candidate evidence records one target and zero unexpected candidates'; else fail_test 'synthetic candidate evidence is incorrect'; fi

mkdir -p "$regen/unit-fail/source/slackware64/d" "$regen/unit-fail/source/slackware64/a" "$regen/unit-fail/workdir"
printf 'target\n' > "$regen/unit-fail/source/slackware64/d/kernel-headers-6.18.45-x86-1.txz"
printf 'unexpected\n' > "$regen/unit-fail/source/slackware64/a/unexpected-1.0-x86_64-1.txz"
cat > "$regen/unit-fail/workdir/pkglist" <<'EOF_PKGLIST'
slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz
slackware64 unexpected 1.0 x86_64 1 unexpected-1.0-x86_64-1 ./slackware64/a txz
EOF_PKGLIST
if "$regen/candidate-unit.sh" "$regen/unit-fail" >/dev/null 2>&1; then fail_test 'candidate guard accepts unexpected source-backed install-new candidate'; else pass 'candidate guard rejects unexpected source-backed install-new candidate'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
