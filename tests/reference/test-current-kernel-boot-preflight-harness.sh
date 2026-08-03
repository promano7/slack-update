#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-boot-preflight.sh"
ACCEPTED_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-accepted.json"

# Source functions without running the real-system scenario.
# shellcheck source=../acceptance/reference/test-current-kernel-boot-preflight.sh
source "$ACCEPTANCE_SCRIPT"

TEST_COUNT=0
TEST_FAILURE_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() { TEST_COUNT=$((TEST_COUNT + 1)); TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
DIGEST=d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1

assert_contains 'never installs packages, runs mkinitrd' "$ACCEPTANCE_SCRIPT" 'usage should state the non-destructive boundary'
assert_contains 'apply-ready=false, apply-authorized=false' "$ACCEPTANCE_SCRIPT" 'the result must deny apply'
assert_contains 'monolithic kernel-generic' "$ACCEPTANCE_SCRIPT" 'the current package model should be explicit'
assert_contains '/home/$owner' "$ACCEPTANCE_SCRIPT" 'evidence must be copied directly to the user home'
assert_contains 'sha256sum -c' "$ACCEPTANCE_SCRIPT" 'the destination verification command should be printed'
assert_contains '(cd "$parent" && sha256sum "${archive##*/}")' "$ACCEPTANCE_SCRIPT" 'sidecars should contain only the archive basename'
assert_contains 'hashlib.sha256()' "$ACCEPTANCE_SCRIPT" 'package immutability should cover package-record contents'
assert_contains 'the package database and boot state were captured before inspection' "$ACCEPTANCE_SCRIPT" 'the initial state must be captured before inspection'
assert_contains 'a complete capture pair is unavailable' "$ACCEPTANCE_SCRIPT" 'missing captures must block unchanged-state assertions'
assert_not_contains 'slackpkg upgrade-all' "$ACCEPTANCE_SCRIPT" 'preflight must not upgrade packages'
assert_not_contains 'mkinitrd -F' "$ACCEPTANCE_SCRIPT" 'preflight must not regenerate initrd'
assert_not_contains 'grub-mkconfig -o' "$ACCEPTANCE_SCRIPT" 'preflight must not regenerate GRUB'
assert_not_contains 'upgradepkg ' "$ACCEPTANCE_SCRIPT" 'preflight must not invoke upgradepkg'
assert_not_contains 'installpkg ' "$ACCEPTANCE_SCRIPT" 'preflight must not invoke installpkg'
assert_not_contains 'removepkg ' "$ACCEPTANCE_SCRIPT" 'preflight must not invoke removepkg'

TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_success 'valid current preflight arguments should parse' parse_arguments --target slackware-current --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel 6.18.41
assert_equal slackware-current "$TARGET" 'target should be preserved'
assert_equal 6.18.41 "$TARGET_KERNEL" 'target kernel should be preserved'
assert_equal "$DIGEST" "$CONFIRM_CANDIDATES_SHA256" 'candidate digest should be preserved'

TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'Slackware 15.0 should be rejected' parse_arguments --target slackware-15.0 --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel 6.18.41
TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'short candidate digests should be rejected' parse_arguments --target slackware-current --confirm-candidates-sha256 deadbeef --confirm-target-kernel 6.18.41
TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'unsafe target kernel versions should be rejected' parse_arguments --target slackware-current --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel ../6.18.41
TARGET= TARGET_KERNEL= CONFIRM_CANDIDATES_SHA256= ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE OUTPUT_DIR=
assert_failure 'relative output paths should be rejected' parse_arguments --target slackware-current --confirm-candidates-sha256 "$DIGEST" --confirm-target-kernel 6.18.41 --output-dir relative

assert_success 'the accepted fixture should match the reviewed identity' validate_accepted_preflight
assert_equal 6.18.40 "$(package_record_version kernel-generic-6.18.40-x86_64-1)" 'kernel package version should be parsed'
assert_success 'safe kernel versions should pass' is_safe_kernel_version 6.18.41
assert_failure 'kernel versions with whitespace should fail' is_safe_kernel_version '6.18.41 bad'
assert_failure 'kernel versions with slash should fail' is_safe_kernel_version '6.18/41'
assert_success 'the reviewed fixture should be valid JSON' python3 -m json.tool "$ACCEPTED_FIXTURE"

cp "$ACCEPTED_FIXTURE" "$TMP/fixture.json"
python3 - "$TMP/fixture.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['apply_authorized']=True
open(p,'w').write(json.dumps(d))
PY
ACCEPTED_PREFLIGHT="$TMP/fixture.json"
assert_failure 'an apply-authorized fixture should be rejected' validate_accepted_preflight
ACCEPTED_PREFLIGHT=$ACCEPTED_FIXTURE

CONF="$TMP/mkinitrd.conf"
cat > "$CONF" <<'EOF_CONF'
KERNEL_VERSION="6.18.40"
ROOTDEV='/dev/sda2'
OUTPUT_IMAGE=/boot/initrd.gz
EOF_CONF
assert_equal 6.18.40 "$(read_scalar_assignment "$CONF" KERNEL_VERSION)" 'quoted KERNEL_VERSION should parse'
assert_equal /dev/sda2 "$(read_scalar_assignment "$CONF" ROOTDEV)" 'single-quoted ROOTDEV should parse'
assert_equal /boot/initrd.gz "$(read_scalar_assignment "$CONF" OUTPUT_IMAGE)" 'plain output path should parse'
printf 'KERNEL_VERSION=one\nKERNEL_VERSION=two\n' > "$CONF"
assert_failure 'duplicate mkinitrd assignments should fail' read_scalar_assignment "$CONF" KERNEL_VERSION

bash -n "$ACCEPTANCE_SCRIPT" && pass || fail 'acceptance script should pass bash -n'

printf 'Slackware-current kernel boot preflight harness: %d checks, %d failures\n' "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
