#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-candidate-chain-refresh-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-candidate-chain-refresh-preflight.sh
source "$SCRIPT"

HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0
pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() { [ "$1" = "$2" ] && pass || fail "$3 (expected '$1', got '$2')"; }
assert_contains() { grep -Fq -- "$1" "$2" && pass || fail "$3"; }
assert_not_contains() { grep -Fq -- "$1" "$2" && fail "$3" || pass; }
json_value() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2], {"d":d}))' "$1" "$2"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BASELINE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260804-accepted.json"
RUNNING_KERNEL=6.18.40

make_fresh() {
    local dir=$1 mode=$2
    mkdir -p "$dir"
    python3 - "$BASELINE" "$dir" "$mode" <<'PY'
import hashlib,json,pathlib,sys
base_path, out_dir, mode=sys.argv[1:]
d=json.load(open(base_path, encoding='utf-8'))
install=list(d['candidates']['install_new'])
upgrade=list(d['candidates']['upgrade_all'])
critical=[]
if mode == 'changed-kernel':
    upgrade=[x for x in upgrade if not x.startswith(('kernel-generic-','kernel-headers-','kernel-source-'))]
    upgrade += ['kernel-generic-6.18.43-x86_64-1.txz','kernel-headers-6.18.43-x86-1.txz','kernel-source-6.18.43-noarch-1.txz']
elif mode == 'incomplete-kernel':
    upgrade=[x for x in upgrade if not x.startswith(('kernel-generic-','kernel-headers-','kernel-source-'))]
    upgrade += ['kernel-generic-6.18.43-x86_64-1.txz','kernel-source-6.18.43-noarch-1.txz']
elif mode == 'ambiguous-kernel':
    upgrade += ['kernel-generic-6.18.43-x86_64-1.txz','kernel-headers-6.18.43-x86-1.txz','kernel-source-6.18.43-noarch-1.txz']
elif mode == 'userspace':
    upgrade += ['example-userspace-1.0-x86_64-1.txz']
elif mode == 'userspace-replacement':
    old=next(x for x in upgrade if x.startswith('nano-'))
    upgrade.remove(old)
    upgrade += ['nano-9.3-x86_64-1.txz']
elif mode == 'critical':
    upgrade += ['example-critical-1.0-x86_64-1.txz']
    critical=['example-critical-1.0-x86_64-1.txz']
elif mode == 'none':
    install=[]; upgrade=[]
elif mode == 'malformed':
    upgrade += ['../unsafe.txz']
install=sorted(set(install)); upgrade=sorted(set(upgrade)); allc=sorted(set(install+upgrade)); critical=sorted(set(critical))
out=pathlib.Path(out_dir)
for name,values in [
    ('install-new.candidates.txt',install),
    ('upgrade-all.candidates.txt',upgrade),
    ('all.candidates.txt',allc),
    ('critical.candidates.txt',critical),
]:
    (out/name).write_text(''.join(f'{x}\n' for x in values), encoding='utf-8')
digest=hashlib.sha256(''.join(f'{x}\n' for x in allc).encode()).hexdigest()
(out/'summary.txt').write_text('\n'.join([
 'scenario=normal-update','mode=preflight','target=slackware-current','result=PASS','failures=0',
 f'install_new_candidates={len(install)}',f'upgrade_candidates={len(upgrade)}',f'total_candidates={len(allc)}',
 f'candidate_set_sha256={digest}','kernel_candidates=2',f'critical_candidates={len(critical)}','']))
PY
}

assert_success 'the acceptance script should have valid Bash syntax' bash -n "$SCRIPT"
assert_contains 'only the non-installing --preflight mode' "$SCRIPT" 'the help should describe the non-installing wrapper'
assert_contains 'slackware-current-preflight-20260804-accepted.json' "$SCRIPT" 'the default baseline should be the accepted 69-candidate record'
assert_contains 'bash "$NORMAL_UPDATE_SCRIPT" --target slackware-current --preflight' "$SCRIPT" 'the wrapper should invoke only the normal-update preflight'
assert_not_contains '--execute-apply' <(grep -E '^[[:space:]]*bash "\$NORMAL_UPDATE_SCRIPT"' "$SCRIPT") 'the embedded invocation must never request apply'
assert_contains 'normal_update_apply_executed=false' "$SCRIPT" 'the summary should deny normal-update apply execution'
assert_contains 'package_transaction_executed=false' "$SCRIPT" 'the summary should deny package execution'
assert_contains 'initrd_generation_executed=false' "$SCRIPT" 'the summary should deny initrd generation'
assert_contains 'grub_update_executed=false' "$SCRIPT" 'the summary should deny GRUB updates'
assert_contains 'apply_ready=false' "$SCRIPT" 'apply readiness must remain false'
assert_contains 'apply_authorized=false' "$SCRIPT" 'apply authorization must remain false'
assert_contains 'sha256sum -c' "$SCRIPT" 'portable verification should be printed'
assert_contains '/home/$owner' "$SCRIPT" 'evidence should copy directly to the user home'

is_sha256 "$(printf 'a%.0s' {1..64})" && pass || fail 'a valid SHA-256 should be accepted'
is_sha256 abc && fail 'a short SHA-256 should be rejected' || pass
is_safe_kernel_version 6.18.42 && pass || fail 'a normal kernel version should be safe'
is_safe_kernel_version '../6.18.42' && fail 'kernel traversal should be rejected' || pass
is_safe_kernel_version '6.18.42 bad' && fail 'kernel whitespace should be rejected' || pass

BASELINE_PREFLIGHT=$BASELINE
assert_success 'the accepted candidate baseline should validate' validate_baseline_record
cp "$BASELINE" "$TMP/baseline-authorized.json"
python3 - "$TMP/baseline-authorized.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['apply_authorized']=True; open(p,'w').write(json.dumps(d))
PY
BASELINE_PREFLIGHT="$TMP/baseline-authorized.json"
assert_failure 'an authorized baseline should be rejected' validate_baseline_record
cp "$BASELINE" "$TMP/baseline-digest.json"
python3 - "$TMP/baseline-digest.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['candidates']['candidate_set_sha256']='0'*64; open(p,'w').write(json.dumps(d))
PY
BASELINE_PREFLIGHT="$TMP/baseline-digest.json"
assert_failure 'a baseline whose digest does not describe its candidates should fail during comparison' analyze_refresh "$BASELINE_PREFLIGHT" "$TMP/missing" "$TMP/out.json"
BASELINE_PREFLIGHT=$BASELINE

make_fresh "$TMP/unchanged" unchanged
assert_success 'the unchanged reviewed set should analyze safely' analyze_refresh "$BASELINE" "$TMP/unchanged" "$TMP/unchanged.json"
assert_equal unchanged-reviewed-kernel-set "$(json_value "$TMP/unchanged.json" 'd["chain_status"]')" 'the unchanged set should preserve its reviewed kernel classification'
assert_equal false "$(json_value "$TMP/unchanged.json" 'str(d["candidate_set_changed"]).lower()')" 'the unchanged set should report no digest change'
assert_equal true "$(json_value "$TMP/unchanged.json" 'str(d["prior_candidate_bound_chain_reusable"]).lower()')" 'the exact candidate-bound chain should remain reusable'
assert_equal 6.18.42 "$(json_value "$TMP/unchanged.json" 'd["target_kernel"]')" 'the reviewed target kernel should be retained'
assert_equal true "$(json_value "$TMP/unchanged.json" 'str(d["kernel_companion_set_complete"]).lower()')" 'the generic, headers, and source set should be complete'
assert_equal current-transaction-readiness-dry-run "$(json_value "$TMP/unchanged.json" 'd["next_stage"]')" 'the unchanged chain should advance only to readiness dry-run'
assert_equal false "$(json_value "$TMP/unchanged.json" 'str(d["apply_ready"]).lower()')" 'an unchanged refresh must not become apply-ready'
assert_equal false "$(json_value "$TMP/unchanged.json" 'str(d["apply_authorized"]).lower()')" 'an unchanged refresh must not authorize apply'

make_fresh "$TMP/changed" changed-kernel
assert_success 'a changed complete kernel set should analyze safely' analyze_refresh "$BASELINE" "$TMP/changed" "$TMP/changed.json"
assert_equal changed-kernel-set "$(json_value "$TMP/changed.json" 'd["chain_status"]')" 'a new target kernel should stale the reviewed chain'
assert_equal true "$(json_value "$TMP/changed.json" 'str(d["candidate_set_changed"]).lower()')" 'the changed set should report a digest change'
assert_equal false "$(json_value "$TMP/changed.json" 'str(d["prior_candidate_bound_chain_reusable"]).lower()')" 'the old candidate-bound chain must not be reusable'
assert_equal 6.18.43 "$(json_value "$TMP/changed.json" 'd["target_kernel"]')" 'the new target kernel should be extracted'
assert_equal repeat-current-kernel-evidence-chain "$(json_value "$TMP/changed.json" 'd["next_stage"]')" 'a changed kernel set should repeat the evidence chain'
assert_equal 3 "$(json_value "$TMP/changed.json" 'len(d["added_candidates"])')" 'three new target kernel companions should be added'
assert_equal 3 "$(json_value "$TMP/changed.json" 'len(d["removed_candidates"])')" 'three old target kernel companions should be removed'

make_fresh "$TMP/incomplete" incomplete-kernel
assert_success 'an incomplete kernel set should be represented safely' analyze_refresh "$BASELINE" "$TMP/incomplete" "$TMP/incomplete.json"
assert_equal incomplete-kernel-companion-set "$(json_value "$TMP/incomplete.json" 'd["chain_status"]')" 'missing headers should fail the companion boundary'
assert_equal false "$(json_value "$TMP/incomplete.json" 'str(d["kernel_companion_set_complete"]).lower()')" 'the incomplete set should be marked incomplete'
assert_equal manual-review-required "$(json_value "$TMP/incomplete.json" 'd["next_stage"]')" 'an incomplete set should require manual review'

make_fresh "$TMP/ambiguous" ambiguous-kernel
assert_success 'multiple generic targets should be represented safely' analyze_refresh "$BASELINE" "$TMP/ambiguous" "$TMP/ambiguous.json"
assert_equal ambiguous-kernel-target "$(json_value "$TMP/ambiguous.json" 'd["chain_status"]')" 'multiple generic targets should be ambiguous'
assert_equal manual-review-required "$(json_value "$TMP/ambiguous.json" 'd["next_stage"]')" 'an ambiguous target should require manual review'

make_fresh "$TMP/userspace" userspace
assert_success 'a same-kernel userspace expansion should analyze safely' analyze_refresh "$BASELINE" "$TMP/userspace" "$TMP/userspace.json"
assert_equal changed-userspace-set "$(json_value "$TMP/userspace.json" 'd["chain_status"]')" 'a same-kernel userspace refresh should use the userspace branch'
assert_equal review-fresh-userspace-candidates "$(json_value "$TMP/userspace.json" 'd["next_stage"]')" 'a fresh userspace set should require candidate review'
assert_equal 6.18.42 "$(json_value "$TMP/userspace.json" 'd["target_kernel"]')" 'the unchanged target kernel should remain explicit'
assert_equal false "$(json_value "$TMP/userspace.json" 'str(d["kernel_transaction_changed"]).lower()')" 'the exact kernel transaction should remain unchanged'
assert_equal true "$(json_value "$TMP/userspace.json" 'str(d["userspace_only_candidate_change"]).lower()')" 'the change should be identified as userspace-only'
assert_equal true "$(json_value "$TMP/userspace.json" 'str(d["strict_candidate_superset"]).lower()')" 'an addition-only userspace refresh should be a strict superset'
assert_equal true "$(json_value "$TMP/userspace.json" 'str(d["kernel_evidence_rebind_possible_after_userspace_review"]).lower()')" 'kernel evidence should be eligible for explicit rebind after userspace review'
assert_equal false "$(json_value "$TMP/userspace.json" 'str(d["prior_candidate_bound_chain_reusable"]).lower()')" 'the old candidate-bound chain must not be directly reusable'
assert_equal 1 "$(json_value "$TMP/userspace.json" 'd["added_candidate_count"]')" 'one userspace package should be added'
assert_equal 0 "$(json_value "$TMP/userspace.json" 'd["removed_candidate_count"]')" 'no reviewed package should be removed'

make_fresh "$TMP/userspace-replacement" userspace-replacement
assert_success 'a same-kernel userspace replacement should analyze safely' analyze_refresh "$BASELINE" "$TMP/userspace-replacement" "$TMP/userspace-replacement.json"
assert_equal changed-userspace-set "$(json_value "$TMP/userspace-replacement.json" 'd["chain_status"]')" 'a userspace version replacement should remain a userspace change'
assert_equal false "$(json_value "$TMP/userspace-replacement.json" 'str(d["strict_candidate_superset"]).lower()')" 'a userspace replacement should not be a strict superset'
assert_equal false "$(json_value "$TMP/userspace-replacement.json" 'str(d["kernel_transaction_changed"]).lower()')" 'a userspace replacement should not stale the kernel target itself'

make_fresh "$TMP/critical" critical
assert_success 'a configured critical candidate should be represented safely' analyze_refresh "$BASELINE" "$TMP/critical" "$TMP/critical.json"
assert_equal critical-candidates-present "$(json_value "$TMP/critical.json" 'd["chain_status"]')" 'critical candidates should force manual review'
assert_equal manual-review-required "$(json_value "$TMP/critical.json" 'd["next_stage"]')" 'critical candidates should not advance automatically'
assert_equal 1 "$(json_value "$TMP/critical.json" 'd["critical_candidate_count"]')" 'the critical candidate count should be preserved'

make_fresh "$TMP/none" none
assert_success 'an empty candidate set should analyze safely' analyze_refresh "$BASELINE" "$TMP/none" "$TMP/none.json"
assert_equal no-updates "$(json_value "$TMP/none.json" 'd["chain_status"]')" 'an empty set should select no-updates acceptance'
assert_equal no-updates-acceptance "$(json_value "$TMP/none.json" 'd["next_stage"]')" 'the no-updates stage should be explicit'

make_fresh "$TMP/malformed" malformed
assert_failure 'a traversal candidate filename should fail closed' analyze_refresh "$BASELINE" "$TMP/malformed" "$TMP/malformed.json"
make_fresh "$TMP/unsorted" unchanged
{ tail -n 1 "$TMP/unsorted/all.candidates.txt"; head -n -1 "$TMP/unsorted/all.candidates.txt"; } > "$TMP/unsorted/all.tmp"
mv "$TMP/unsorted/all.tmp" "$TMP/unsorted/all.candidates.txt"
assert_failure 'an unsorted candidate list should fail closed' analyze_refresh "$BASELINE" "$TMP/unsorted" "$TMP/unsorted.json"
make_fresh "$TMP/bad-summary" unchanged
sed -i 's/^candidate_set_sha256=.*/candidate_set_sha256=0000/' "$TMP/bad-summary/summary.txt"
assert_failure 'a summary digest mismatch should fail closed' analyze_refresh "$BASELINE" "$TMP/bad-summary" "$TMP/bad-summary.json"

make_fresh "$TMP/overlap" unchanged
head -n 1 "$TMP/overlap/install-new.candidates.txt" >> "$TMP/overlap/upgrade-all.candidates.txt"
sort -u "$TMP/overlap/upgrade-all.candidates.txt" -o "$TMP/overlap/upgrade-all.candidates.txt"
assert_failure 'a package present in both candidate operations should fail closed' analyze_refresh "$BASELINE" "$TMP/overlap" "$TMP/overlap.json"
make_fresh "$TMP/bad-count" unchanged
sed -i 's/^total_candidates=.*/total_candidates=999/' "$TMP/bad-count/summary.txt"
assert_failure 'summary counts that do not match the candidate files should fail closed' analyze_refresh "$BASELINE" "$TMP/bad-count" "$TMP/bad-count.json"
make_fresh "$TMP/bad-critical" unchanged
printf '%s
' 'not-a-candidate-1.0-x86_64-1.txz' > "$TMP/bad-critical/critical.candidates.txt"
sed -i 's/^critical_candidates=.*/critical_candidates=1/' "$TMP/bad-critical/summary.txt"
assert_failure 'a critical list outside the exact candidate set should fail closed' analyze_refresh "$BASELINE" "$TMP/bad-critical" "$TMP/bad-critical.json"

(
    PASS_COUNT=8
    FAILURE_COUNT=0
    TARGET=slackware-current
    RUNNING_KERNEL=6.18.40
    BASELINE_CANDIDATE_SHA256=918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9
    FRESH_CANDIDATE_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    CHAIN_STATUS=changed-userspace-set
    TARGET_KERNEL=6.18.42
    NEXT_STAGE=review-fresh-userspace-candidates
    write_summary "$TMP/summary-output.txt"
)
assert_contains 'normal_update_apply_executed=false' "$TMP/summary-output.txt" 'the summary should deny embedded apply'
assert_contains 'package_transaction_executed=false' "$TMP/summary-output.txt" 'the summary should deny package execution'
assert_contains 'apply_ready=false' "$TMP/summary-output.txt" 'the summary should keep readiness false'
assert_contains 'apply_authorized=false' "$TMP/summary-output.txt" 'the summary should keep authorization false'
assert_contains 'next_stage=review-fresh-userspace-candidates' "$TMP/summary-output.txt" 'the summary should preserve the next stage'
assert_contains 'passes=8' "$TMP/summary-output.txt" 'the summary should preserve the assertion count'

printf 'Slackware-current candidate chain refresh harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
