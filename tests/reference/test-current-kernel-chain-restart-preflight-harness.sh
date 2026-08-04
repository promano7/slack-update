#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-kernel-chain-restart-preflight.sh"
REFRESH="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-candidate-chain-refresh-20260804-accepted.json"
PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0

pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); }
fail() {
    HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1))
    HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" >&2
}
assert_success() { local label=$1; shift; "$@" && pass || fail "$label"; }
assert_failure() { local label=$1; shift; "$@" && fail "$label" || pass; }
assert_contains() {
    local needle=$1 file=$2 label=$3
    grep -Fq -- "$needle" "$file" && pass || fail "$label"
}
assert_not_contains() {
    local needle=$1 file=$2 label=$3
    grep -Fq -- "$needle" "$file" && fail "$label" || pass
}
assert_equal() {
    local expected=$1 actual=$2 label=$3
    [ "$expected" = "$actual" ] && pass || fail "$label (expected=$expected actual=$actual)"
}
json_value() {
    python3 - "$1" "$2" <<'PY'
import json,sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
print(eval(sys.argv[2], {'__builtins__': {}}, {'d': data, 'len': len}))
PY
}

# shellcheck source=/dev/null
source "$SCRIPT"

assert_contains 'invokes only the non-destructive kernel boot' "$SCRIPT" 'help should describe the non-destructive restart'
assert_contains '--accepted-preflight "$ACCEPTED_PREFLIGHT"' "$SCRIPT" 'the nested boot preflight should receive the reviewed record explicitly'
assert_contains '--output-dir "$nested_dir"' "$SCRIPT" 'nested evidence should stay inside the outer evidence tree'
assert_not_contains '--execute-apply' "$SCRIPT" 'the wrapper source must not contain an apply request'
assert_contains 'package_transaction_executed=false' "$SCRIPT" 'the outer summary should deny package execution'
assert_contains 'initrd_generation_executed=false' "$SCRIPT" 'the outer summary should deny initrd generation'
assert_contains 'grub_update_executed=false' "$SCRIPT" 'the outer summary should deny GRUB updates'
assert_contains 'apply_ready=false' "$SCRIPT" 'the outer summary should keep readiness false'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the outer summary should keep authorization false'
assert_contains 'sha256sum -c' "$SCRIPT" 'portable nested and copied evidence verification should be required'
assert_contains '/home/$owner' "$SCRIPT" 'evidence should copy directly to the user home'

TARGET=slackware-current
ACCEPTED_REFRESH=$REFRESH
ACCEPTED_PREFLIGHT=$PREFLIGHT
assert_success 'the accepted fresh chain should load safely' load_reviewed_chain
assert_equal 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 "$CANDIDATE_SET_SHA256" 'the accepted candidate digest should be loaded'
assert_equal 6.18.42 "$TARGET_KERNEL" 'the accepted target kernel should be loaded'
assert_equal 6.18.40 "$RUNNING_KERNEL" 'the reviewed running kernel should be loaded'
assert_equal 69 "$(json_value "$PREFLIGHT" 'd["candidates"]["total"]')" 'the new accepted set should contain 69 candidates'
assert_equal 1 "$(json_value "$PREFLIGHT" 'len(d["candidates"]["install_new"])')" 'one install-new candidate should be preserved'
assert_equal 68 "$(json_value "$PREFLIGHT" 'len(d["candidates"]["upgrade_all"])')" '68 upgrade candidates should be preserved'
assert_equal changed-kernel-set "$(json_value "$REFRESH" 'd["chain_status"]')" 'the accepted refresh should preserve the changed-kernel status'
assert_equal repeat-current-kernel-evidence-chain "$(json_value "$REFRESH" 'd["next_stage"]')" 'the accepted refresh should require a chain restart'
assert_equal False "$(json_value "$REFRESH" 'd["prior_candidate_bound_chain_reusable"]')" 'the 6.18.41 chain should remain non-reusable'

cp "$REFRESH" "$TMP/refresh-authorized.json"
python3 - "$TMP/refresh-authorized.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['apply_authorized']=True; open(p,'w').write(json.dumps(d))
PY
ACCEPTED_REFRESH="$TMP/refresh-authorized.json"
assert_failure 'an authorized refresh record should be rejected' load_reviewed_chain

cp "$REFRESH" "$TMP/refresh-target.json"
python3 - "$TMP/refresh-target.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['target_kernel']='6.18.99'; open(p,'w').write(json.dumps(d))
PY
ACCEPTED_REFRESH="$TMP/refresh-target.json"
assert_failure 'a refresh target that differs from the normal preflight should fail' load_reviewed_chain

cp "$PREFLIGHT" "$TMP/preflight-digest.json"
python3 - "$TMP/preflight-digest.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['candidates']['candidate_set_sha256']='0'*64; open(p,'w').write(json.dumps(d))
PY
ACCEPTED_REFRESH=$REFRESH
ACCEPTED_PREFLIGHT="$TMP/preflight-digest.json"
assert_failure 'a candidate digest that does not describe the exact list should fail' load_reviewed_chain

cp "$PREFLIGHT" "$TMP/preflight-source.json"
python3 - "$TMP/preflight-source.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['candidates']['upgrade_all'].remove('kernel-source-6.18.42-noarch-1.txz'); d['candidates']['total']-=1; open(p,'w').write(json.dumps(d))
PY
ACCEPTED_PREFLIGHT="$TMP/preflight-source.json"
assert_failure 'a missing kernel-source companion should fail closed' load_reviewed_chain

cp "$PREFLIGHT" "$TMP/preflight-overlap.json"
python3 - "$TMP/preflight-overlap.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['candidates']['upgrade_all'].append(d['candidates']['install_new'][0]); d['candidates']['total']+=1; open(p,'w').write(json.dumps(d))
PY
ACCEPTED_PREFLIGHT="$TMP/preflight-overlap.json"
assert_failure 'a candidate present in both operations should fail closed' load_reviewed_chain

cp "$PREFLIGHT" "$TMP/preflight-unsafe.json"
python3 - "$TMP/preflight-unsafe.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['candidates']['upgrade_all'][0]='../bad.txz'; open(p,'w').write(json.dumps(d))
PY
ACCEPTED_PREFLIGHT="$TMP/preflight-unsafe.json"
assert_failure 'an unsafe package filename should fail closed' load_reviewed_chain

ACCEPTED_PREFLIGHT=$PREFLIGHT
assert_success 'the accepted chain should reload after negative cases' load_reviewed_chain

cat > "$TMP/summary.txt" <<EOF_SUMMARY
scenario=current-kernel-boot-preflight
target=slackware-current
result=PASS
passes=20
failures=0
running_kernel=6.18.40
installed_kernel=6.18.40
target_kernel=6.18.42
candidate_set_sha256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
package_layout=monolithic-generic
boot_mode=direct-generic-no-initrd
apply_ready=false
apply_authorized=false
EOF_SUMMARY
assert_success 'a matching nested boot summary should validate' validate_nested_summary "$TMP/summary.txt"

sed 's/target_kernel=6.18.42/target_kernel=6.18.41/' "$TMP/summary.txt" > "$TMP/summary-old-target.txt"
assert_failure 'a stale nested target should be rejected' validate_nested_summary "$TMP/summary-old-target.txt"
sed 's/result=PASS/result=FAIL/' "$TMP/summary.txt" > "$TMP/summary-fail.txt"
assert_failure 'a failed nested result should be rejected' validate_nested_summary "$TMP/summary-fail.txt"
sed 's/apply_authorized=false/apply_authorized=true/' "$TMP/summary.txt" > "$TMP/summary-authorized.txt"
assert_failure 'an authorized nested result should be rejected' validate_nested_summary "$TMP/summary-authorized.txt"
sed 's/boot_mode=direct-generic-no-initrd/boot_mode=unsafe/' "$TMP/summary.txt" > "$TMP/summary-mode.txt"
assert_failure 'an unknown boot mode should be rejected' validate_nested_summary "$TMP/summary-mode.txt"

mkdir -p "$TMP/nested"
printf 'nested evidence\n' > "$TMP/nested/slackware-current-current-kernel-boot-preflight-20260804T000000Z.tar.gz"
(cd "$TMP/nested" && sha256sum slackware-current-current-kernel-boot-preflight-20260804T000000Z.tar.gz > slackware-current-current-kernel-boot-preflight-20260804T000000Z.tar.gz.sha256)
assert_success 'one portable nested archive should verify' verify_nested_archive "$TMP/nested"
printf 'tamper\n' >> "$TMP/nested/slackware-current-current-kernel-boot-preflight-20260804T000000Z.tar.gz"
assert_failure 'a tampered nested archive should fail verification' verify_nested_archive "$TMP/nested"
rm -f "$TMP/nested"/*
assert_failure 'missing nested evidence should fail verification' verify_nested_archive "$TMP/nested"

PASS_COUNT=6
FAILURE_COUNT=0
TARGET=slackware-current
RUNNING_KERNEL=6.18.40
TARGET_KERNEL=6.18.42
CANDIDATE_SET_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
write_summary "$TMP/outer-summary.txt"
assert_contains 'scenario=current-kernel-chain-restart-preflight' "$TMP/outer-summary.txt" 'outer summary should name the restart scenario'
assert_contains 'next_stage=current-kernel-package-preflight' "$TMP/outer-summary.txt" 'outer summary should select the package preflight next'
assert_contains 'normal_update_apply_executed=false' "$TMP/outer-summary.txt" 'outer summary should deny normal-update apply'
assert_contains 'package_transaction_executed=false' "$TMP/outer-summary.txt" 'outer summary should deny package changes'
assert_contains 'apply_ready=false' "$TMP/outer-summary.txt" 'outer summary should remain not ready'
assert_contains 'apply_authorized=false' "$TMP/outer-summary.txt" 'outer summary should remain unauthorized'
assert_contains 'passes=6' "$TMP/outer-summary.txt" 'outer summary should preserve the pass count'

printf 'Slackware-current kernel chain restart harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
