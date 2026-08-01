#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-kernel-transaction-apply.sh"

# Source helpers without executing the real-system transaction.
# shellcheck source=../acceptance/reference/test-elilo-kernel-transaction-apply.sh
source "$ACCEPTANCE_SCRIPT"

TEST_COUNT=0
TEST_FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { local expected=$1 actual=$2 message=$3; [ "$expected" = "$actual" ] && pass || fail "$message (expected '$expected', got '$actual')"; }
assert_contains() { local pattern=$1 path=$2 message=$3; grep -Fq -- "$pattern" "$path" && pass || fail "$message"; }
assert_not_contains() { local pattern=$1 path=$2 message=$3; grep -Fq -- "$pattern" "$path" && fail "$message" || pass; }

WORK=$(mktemp -d)
trap 'rm -rf -- "$WORK"' EXIT

TARGET= CONFIRM_HOSTNAME= CONFIRM_CANDIDATE_SHA256= CONFIRM_TARGET_KERNEL= OUTPUT_DIR=
assert_success 'complete apply confirmations should parse' parse_apply_arguments \
    --target slackware-15.0 --execute-apply \
    --confirm-hostname vbox-slack15.vbox-slack15.org \
    --confirm-candidate-sha256 10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db \
    --confirm-target-kernel 5.15.209 --output-dir /tmp/evidence
TARGET= CONFIRM_HOSTNAME= CONFIRM_CANDIDATE_SHA256= CONFIRM_TARGET_KERNEL= OUTPUT_DIR=
assert_failure 'apply must require the explicit execution switch' parse_apply_arguments \
    --target slackware-15.0 --confirm-hostname host \
    --confirm-candidate-sha256 10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db \
    --confirm-target-kernel 5.15.209
TARGET= CONFIRM_HOSTNAME= CONFIRM_CANDIDATE_SHA256= CONFIRM_TARGET_KERNEL= OUTPUT_DIR=
assert_failure 'apply must reject a short candidate digest' parse_apply_arguments \
    --target slackware-15.0 --execute-apply --confirm-hostname host \
    --confirm-candidate-sha256 deadbeef --confirm-target-kernel 5.15.209
TARGET= CONFIRM_HOSTNAME= CONFIRM_CANDIDATE_SHA256= CONFIRM_TARGET_KERNEL= OUTPUT_DIR=
assert_failure 'apply must reject unsafe target versions' parse_apply_arguments \
    --target slackware-15.0 --execute-apply --confirm-hostname host \
    --confirm-candidate-sha256 10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db \
    --confirm-target-kernel '../5.15.209'

cat > "$WORK/blacklist" <<'EOF_BLACKLIST'
# keep
kernel-generic
kernel-huge # deferred
kernel-modules
[0-9]+_SBo
EOF_BLACKLIST
assert_success 'exact kernel deferrals should be removable' write_blacklist_without_deferrals "$WORK/blacklist" "$WORK/blacklist.tx"
assert_contains '# keep' "$WORK/blacklist.tx" 'unrelated blacklist comments should be preserved'
assert_contains '[0-9]+_SBo' "$WORK/blacklist.tx" 'unrelated blacklist patterns should be preserved'
assert_not_contains 'kernel-generic' "$WORK/blacklist.tx" 'kernel-generic should be removed only in the transaction copy'
assert_not_contains 'kernel-huge' "$WORK/blacklist.tx" 'kernel-huge should be removed only in the transaction copy'
assert_not_contains 'kernel-modules' "$WORK/blacklist.tx" 'kernel-modules should be removed only in the transaction copy'
printf 'kernel-generic\nkernel-generic\nkernel-huge\nkernel-modules\n' > "$WORK/blacklist.duplicate"
assert_failure 'duplicate active deferrals should fail closed' write_blacklist_without_deferrals "$WORK/blacklist.duplicate" "$WORK/out"
printf 'kernel-generic\nkernel-huge\n' > "$WORK/blacklist.missing"
assert_failure 'missing active deferrals should fail closed' write_blacklist_without_deferrals "$WORK/blacklist.missing" "$WORK/out"

mkdir -p "$WORK/cache/patches/packages/linux-5.15.209"
cat > "$WORK/selected.tsv" <<'EOF_SELECTED'
patches	kernel-generic	5.15.209	x86_64	1	kernel-generic-5.15.209-x86_64-1	./patches/packages/linux-5.15.209	1
patches	kernel-huge	5.15.209	x86_64	1	kernel-huge-5.15.209-x86_64-1	./patches/packages/linux-5.15.209	2
patches	kernel-modules	5.15.209	x86_64	1	kernel-modules-5.15.209-x86_64-1	./patches/packages/linux-5.15.209	3
EOF_SELECTED
for name in generic huge modules; do : > "$WORK/cache/patches/packages/linux-5.15.209/kernel-$name-5.15.209-x86_64-1.txz"; done
assert_success 'the exact cached kernel packages should resolve' resolve_downloaded_kernel_packages "$WORK/selected.tsv" "$WORK/cache" "$WORK/downloads"
assert_equal 3 "$(wc -l < "$WORK/downloads")" 'three downloaded package paths should be emitted'
assert_contains 'kernel-generic-5.15.209-x86_64-1.txz' "$WORK/downloads" 'the generic package should be selected exactly'
assert_contains 'kernel-huge-5.15.209-x86_64-1.txz' "$WORK/downloads" 'the huge package should be selected exactly'
assert_contains 'kernel-modules-5.15.209-x86_64-1.txz' "$WORK/downloads" 'the modules package should be selected exactly'
rm "$WORK/cache/patches/packages/linux-5.15.209/kernel-modules-5.15.209-x86_64-1.txz"
assert_failure 'an incomplete download set should fail closed' resolve_downloaded_kernel_packages "$WORK/selected.tsv" "$WORK/cache" "$WORK/downloads.bad"
: > "$WORK/cache/patches/packages/linux-5.15.209/kernel-modules-5.15.209-x86_64-1.txz"
: > "$WORK/cache/patches/packages/linux-5.15.209/kernel-modules-5.15.209-x86_64-1.tgz"
assert_failure 'ambiguous cached package extensions should fail closed' resolve_downloaded_kernel_packages "$WORK/selected.tsv" "$WORK/cache" "$WORK/downloads.bad"
rm "$WORK/cache/patches/packages/linux-5.15.209/kernel-modules-5.15.209-x86_64-1.tgz"

mkdir -p "$WORK/pkgdb"
for name in kernel-generic kernel-huge kernel-modules; do
    : > "$WORK/pkgdb/$name-5.15.19-x86_64-1"
    : > "$WORK/pkgdb/$name-5.15.209-x86_64-1"
done
assert_success 'old and new kernel packages should coexist exactly' validate_installed_target_kernel "$WORK/pkgdb" 5.15.19 5.15.209 "$WORK/installed.tsv"
assert_equal 6 "$(wc -l < "$WORK/installed.tsv")" 'six package records should prove rollback coexistence'
: > "$WORK/pkgdb/kernel-generic-5.15.208-x86_64-1"
assert_failure 'a third generic kernel package version should fail closed' validate_installed_target_kernel "$WORK/pkgdb" 5.15.19 5.15.209 "$WORK/installed.bad"
rm "$WORK/pkgdb/kernel-generic-5.15.208-x86_64-1"
rm "$WORK/pkgdb/kernel-huge-5.15.19-x86_64-1"
assert_failure 'a missing working kernel package should fail closed' validate_installed_target_kernel "$WORK/pkgdb" 5.15.19 5.15.209 "$WORK/installed.bad"

cat > "$WORK/generator.log" <<'EOF_GENERATOR'
mkinitrd -c -k 5.15.209 -f ext4 -r /dev/sda2 -m jbd2:mbcache:crc32c_intel:crc32c_generic:ext4 -u -o /boot/initrd.gz
EOF_GENERATOR
assert_success 'the reviewed mkinitrd command should parse without eval' build_mkinitrd_argv "$WORK/generator.log" 5.15.209 /boot/initrd-generic-5.15.209.gz "$WORK/argv.nul"
python3 - "$WORK/argv.nul" <<'PYTHON_EOF'
import pathlib, sys
items = pathlib.Path(sys.argv[1]).read_bytes().split(b"\0")
items = [item.decode() for item in items if item]
assert items[0] == "mkinitrd"
assert items[items.index("-k") + 1] == "5.15.209"
assert items[items.index("-o") + 1] == "/boot/initrd-generic-5.15.209.gz"
assert "/boot/initrd.gz" not in items
PYTHON_EOF
[ "$?" -eq 0 ] && pass || fail 'the parsed argv should replace only the initrd output path'
sed 's/5.15.209/5.15.208/' "$WORK/generator.log" > "$WORK/generator.wrong"
assert_failure 'a generator command for another kernel should fail closed' build_mkinitrd_argv "$WORK/generator.wrong" 5.15.209 /boot/new.gz "$WORK/argv.bad"
printf '%s\n%s\n' "$(cat "$WORK/generator.log")" "$(cat "$WORK/generator.log")" > "$WORK/generator.multiple"
assert_failure 'multiple mkinitrd commands should fail closed' build_mkinitrd_argv "$WORK/generator.multiple" 5.15.209 /boot/new.gz "$WORK/argv.bad"
sed 's/ -u / --evil /' "$WORK/generator.log" > "$WORK/generator.unsafe"
assert_failure 'unsupported mkinitrd options should fail closed' build_mkinitrd_argv "$WORK/generator.unsafe" 5.15.209 /boot/new.gz "$WORK/argv.bad"

cat > "$WORK/elilo.conf" <<'EOF_ELILO'
chooser=simple
delay=1
timeout=1
#
image=vmlinuz
        label=vmlinuz
        initrd=initrd.gz
        read-only
        append="root=/dev/sda2 vga=normal ro"
EOF_ELILO
assert_success 'a two-entry ELILO transaction config should be generated' write_transaction_elilo_config "$WORK/elilo.conf" "$WORK/elilo.planned" vmlinuz-generic-5.15.209 initrd-generic-5.15.209.gz
assert_success 'the generated ELILO transaction config should validate' validate_transaction_elilo_config "$WORK/elilo.planned" vmlinuz-generic-5.15.209 initrd-generic-5.15.209.gz
assert_contains 'default=vmlinuz' "$WORK/elilo.planned" 'the new versioned entry should be the explicit ELILO default'
assert_contains 'image=vmlinuz-generic-5.15.209' "$WORK/elilo.planned" 'the first ELILO entry should select the new generic kernel'
assert_contains 'initrd=initrd-generic-5.15.209.gz' "$WORK/elilo.planned" 'the first ELILO entry should select the new initrd'
assert_contains 'label=oldkernel' "$WORK/elilo.planned" 'the old working kernel should remain selectable'
assert_contains 'image=vmlinuz' "$WORK/elilo.planned" 'the rollback entry should retain the old EFI kernel'
assert_contains 'initrd=initrd.gz' "$WORK/elilo.planned" 'the rollback entry should retain the old EFI initrd'
sed '/label=/d' "$WORK/elilo.conf" > "$WORK/elilo.no-label"
assert_failure 'an ELILO stanza without one label should fail closed' write_transaction_elilo_config "$WORK/elilo.no-label" "$WORK/elilo.bad" new initrd-new
printf '\nimage=extra\n label=extra\n initrd=extra.gz\n' >> "$WORK/elilo.conf"
assert_failure 'multiple existing ELILO stanzas should fail closed' write_transaction_elilo_config "$WORK/elilo.conf" "$WORK/elilo.bad" new initrd-new

printf old > "$WORK/destination"
printf new > "$WORK/source"
chmod 0640 "$WORK/destination"
assert_success 'atomic replacement should preserve destination metadata' atomic_replace_preserving_metadata "$WORK/source" "$WORK/destination"
assert_equal new "$(cat "$WORK/destination")" 'atomic replacement should install the requested bytes'
assert_equal 640 "$(stat -c '%a' "$WORK/destination")" 'atomic replacement should preserve the destination mode'

mkdir -p "$WORK/efi"
printf kernel > "$WORK/kernel"
assert_success 'verified EFI copies should commit atomically' stage_verified_copy "$WORK/kernel" "$WORK/efi/.stage" "$WORK/efi/kernel-new" 0755
assert_equal kernel "$(cat "$WORK/efi/kernel-new")" 'the committed EFI copy should match the source bytes'
assert_equal 755 "$(stat -c '%a' "$WORK/efi/kernel-new")" 'the committed EFI copy should use the requested mode'
assert_failure 'an existing EFI target should block replacement' stage_verified_copy "$WORK/kernel" "$WORK/efi/.stage2" "$WORK/efi/kernel-new" 0755

MOCK_LOG="$WORK/slackpkg.args"
OUTPUT_DIR="$WORK/commands"
mkdir -p "$OUTPUT_DIR"
slackpkg() { printf '%s ' "$@" >> "$MOCK_LOG"; printf '\n' >> "$MOCK_LOG"; return 0; }
assert_success 'kernel package download should use three exact slackpkg download calls' run_kernel_package_download "$WORK/download.log"
assert_equal 3 "$(wc -l < "$MOCK_LOG")" 'exactly three Slackpkg download calls should be issued'
assert_contains 'download kernel-generic ' "$MOCK_LOG" 'kernel-generic should be requested as one exact package name'
assert_contains 'download kernel-huge ' "$MOCK_LOG" 'kernel-huge should be requested as one exact package name'
assert_contains 'download kernel-modules ' "$MOCK_LOG" 'kernel-modules should be requested as one exact package name'
assert_not_contains '^kernel-(generic|huge|modules)$' "$MOCK_LOG" 'the unsupported extended-regex alternation must not be passed to Slackpkg'
assert_not_contains 'upgrade' "$MOCK_LOG" 'the kernel download path must never use slackpkg upgrade'
assert_equal 3 "$(wc -l < "$OUTPUT_DIR/slackpkg-download-status.tsv")" 'each exact download should have an evidence status record'
: > "$MOCK_LOG"
SLACKPKG_MOCK_CALL=0
slackpkg() {
    SLACKPKG_MOCK_CALL=$((SLACKPKG_MOCK_CALL + 1))
    printf '%s ' "$@" >> "$MOCK_LOG"
    printf '\n' >> "$MOCK_LOG"
    [ "$SLACKPKG_MOCK_CALL" -ne 2 ]
}
assert_failure 'a failed exact package download should stop the sequence' run_kernel_package_download "$WORK/download.fail.log"
assert_equal 2 "$(wc -l < "$MOCK_LOG")" 'downloads after the first failure must not be attempted'
assert_equal 1 "$(awk -F '\t' '$1 == "kernel-huge" { print $2 }' "$OUTPUT_DIR/slackpkg-download-status.tsv")" 'the failing exact package should preserve its raw status'
unset -f slackpkg
INSTALL_LOG="$WORK/installpkg.args"
installpkg() { printf '%s\n' "$*" > "$INSTALL_LOG"; return 0; }
printf '%s\n' /cache/generic.txz /cache/huge.txz /cache/modules.txz > "$WORK/package-list"
assert_success 'installpkg should receive the complete downloaded package set' install_downloaded_kernel_packages "$WORK/package-list" "$WORK/install.log"
assert_contains '/cache/generic.txz' "$INSTALL_LOG" 'installpkg should receive the generic package'
assert_contains '/cache/huge.txz' "$INSTALL_LOG" 'installpkg should receive the huge package'
assert_contains '/cache/modules.txz' "$INSTALL_LOG" 'installpkg should receive the modules package'
unset -f installpkg

assert_not_contains 'eval ' "$ACCEPTANCE_SCRIPT" 'the apply script must never evaluate generated shell text'
assert_contains 'local -a package_names=(kernel-generic kernel-huge kernel-modules)' "$ACCEPTANCE_SCRIPT" 'the apply script should enumerate only the three reviewed kernel names'
assert_contains 'download "$package_name"' "$ACCEPTANCE_SCRIPT" 'the apply script should download each reviewed kernel name separately'
assert_not_contains "download '^kernel-(generic|huge|modules)$'" "$ACCEPTANCE_SCRIPT" 'the apply script must not use unsupported extended-regex alternation'
assert_contains 'installpkg "${packages[@]}"' "$ACCEPTANCE_SCRIPT" 'the apply script should preserve the working kernel with installpkg'
assert_not_contains 'slackpkg -dialog=off -batch=on -default_answer=y -postinst=off' "$ACCEPTANCE_SCRIPT" 'the apply script must not upgrade kernel packages through slackpkg'
assert_not_contains 'eliloconfig' "$ACCEPTANCE_SCRIPT" 'the existing EFI boot entry should not be rewritten by eliloconfig'
assert_not_contains 'efibootmgr' "$ACCEPTANCE_SCRIPT" 'the firmware boot variables should remain untouched'
assert_contains 'mv -fT -- "$STAGED_ELILO_CONFIG" "$ELILO_CONFIG"' "$ACCEPTANCE_SCRIPT" 'ELILO activation should use a same-filesystem atomic replacement'
assert_contains "trap 'handle_transaction_signal TERM' TERM" "$ACCEPTANCE_SCRIPT" 'termination signals should have explicit cleanup handlers'
assert_contains 'label=oldkernel' "$WORK/elilo.planned" 'the transaction must keep an explicit old-kernel boot entry'

FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-transaction-preflight-accepted.json"
assert_success 'the accepted transaction preflight record should be valid JSON' python3 -m json.tool "$FIXTURE"
assert_contains '"archive_sha256": "d951cd9eb24b54b1b8c20262ac12c59b00a042c7426c883dd4af246076d482bb"' "$FIXTURE" 'the accepted record should preserve the evidence digest'
assert_contains '"candidate_set_sha256": "10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db"' "$FIXTURE" 'the accepted record should preserve the candidate digest'
assert_contains '"target_kernel": "5.15.209"' "$FIXTURE" 'the accepted record should preserve the target kernel'
assert_contains '"passes": 27' "$FIXTURE" 'the accepted record should preserve all real-system passes'
assert_contains '"failures": 0' "$FIXTURE" 'the accepted record should preserve the zero-failure result'
assert_contains '"apply_authorized": false' "$FIXTURE" 'the preflight record itself must not claim apply authorization'

DIAGNOSTIC_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-transaction-apply-download-diagnostic.json"
assert_success 'the reviewed download diagnostic should be valid JSON' python3 -m json.tool "$DIAGNOSTIC_FIXTURE"
assert_contains '"archive_sha256": "e3a854a2ed5479e9906ff3dd72592bf39439e55e20d1cc992a42eadf05f14996"' "$DIAGNOSTIC_FIXTURE" 'the diagnostic should preserve the evidence digest'
assert_contains '"slackpkg_exit": 20' "$DIAGNOSTIC_FIXTURE" 'the diagnostic should preserve the raw Slackpkg no-match status'
assert_contains '"packages_installed": false' "$DIAGNOSTIC_FIXTURE" 'the diagnostic should prove no packages were installed'
assert_contains '"blacklist_restored_byte_for_byte": true' "$DIAGNOSTIC_FIXTURE" 'the diagnostic should preserve the blacklist restoration boundary'
assert_contains '"retry_authorized": false' "$DIAGNOSTIC_FIXTURE" 'the failed run must not authorize an unreviewed retry'

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'the apply script should pass bash -n'

printf 'ELILO kernel transaction apply harness: %d checks, %d failures\n' "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
