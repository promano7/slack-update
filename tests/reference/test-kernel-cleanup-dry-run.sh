#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
PLANNER=$REPOSITORY_ROOT/tools/reference/kernel-cleanup-plan-reference.sh
DRY_RUNNER=$REPOSITORY_ROOT/tools/reference/kernel-cleanup-dry-run-reference.sh
FIXTURE_DIR=$REPOSITORY_ROOT/tests/fixtures/reference/kernel-cleanup
ELILO_INELIGIBLE=$FIXTURE_DIR/slackware-15.0-elilo-dual-kernel-design.json
ELILO_MATURE=$FIXTURE_DIR/slackware-15.0-elilo-dual-kernel-mature-synthetic.json
GRUB_MATURE=$FIXTURE_DIR/slackware-15.0-grub-dual-kernel-design.json
GRUB_SINGLE=$FIXTURE_DIR/slackware-15.0-grub-single-kernel-observed.json
POLICY=$FIXTURE_DIR/kernel-cleanup-dry-run-authorization-policy.json

TEST_COUNT=0
TEST_FAILURE_COUNT=0

pass() { TEST_COUNT=$((TEST_COUNT + 1)); }
fail() {
    TEST_COUNT=$((TEST_COUNT + 1))
    TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$1" >&2
}
assert_success() { local message=$1; shift; "$@" >/dev/null 2>&1 && pass || fail "$message"; }
assert_failure() { local message=$1; shift; "$@" >/dev/null 2>&1 && fail "$message" || pass; }
assert_equal() {
    local expected=$1 actual=$2 message=$3
    [ "$expected" = "$actual" ] && pass || fail "$message (expected '$expected', got '$actual')"
}
assert_contains() {
    local pattern=$1 path=$2 message=$3
    grep -Fq -- "$pattern" "$path" && pass || fail "$message"
}
assert_not_contains() {
    local pattern=$1 path=$2 message=$3
    grep -Fq -- "$pattern" "$path" && fail "$message" || pass
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

json_get() {
    python3 - "$1" "$2" <<'PYTHON_EOF'
import json
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
for part in sys.argv[2].split("."):
    value = value[int(part)] if part.isdigit() else value[part]
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("null")
elif isinstance(value, (dict, list)):
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))
else:
    print(value)
PYTHON_EOF
}

mutate_json() {
    local source=$1 destination=$2 expression=$3 rehash=${4:-false}
    python3 - "$source" "$destination" "$expression" "$rehash" <<'PYTHON_EOF'
import hashlib
import json
import sys
source, destination, expression, rehash = sys.argv[1:]
data = json.load(open(source, encoding="utf-8"))
exec(expression, {"data": data})
if rehash == "true" and "plan_sha256" in data:
    del data["plan_sha256"]
    canonical = json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    data["plan_sha256"] = hashlib.sha256(canonical).hexdigest()
with open(destination, "w", encoding="utf-8") as stream:
    json.dump(data, stream, sort_keys=True, indent=2)
    stream.write("\n")
PYTHON_EOF
}

make_plan() {
    "$PLANNER" --input "$1" --output "$2"
}

make_authorization() {
    local plan=$1 output=$2 identifier=$3
    python3 - "$plan" "$output" "$identifier" <<'PYTHON_EOF'
import json
import sys
plan = json.load(open(sys.argv[1], encoding="utf-8"))
authorization = {
    "schema": 1,
    "scenario": "kernel-cleanup-dry-run-authorization",
    "authorization_id": sys.argv[3],
    "scope": "dry-run-only",
    "confirmation": "authorize-kernel-cleanup-dry-run-only",
    "dry_run_authorized": True,
    "apply_authorized": False,
    "plan_sha256": plan["plan_sha256"],
    "target": plan["target"],
    "boot_loader": plan["boot_loader"],
    "active_kernel": plan["active_kernel"],
    "rollback_kernel": plan["rollback_kernel"],
}
with open(sys.argv[2], "w", encoding="utf-8") as stream:
    json.dump(authorization, stream, sort_keys=True, indent=2)
    stream.write("\n")
PYTHON_EOF
}

run_dry() {
    local plan=$1 output=$2 authorization=${3:-} failure=${4:-}
    local args=(--dry-run --plan "$plan" --output "$output")
    [ -z "$authorization" ] || args+=(--authorization "$authorization")
    [ -z "$failure" ] || args+=(--simulate-failure-at "$failure")
    "$DRY_RUNNER" "${args[@]}"
}

assert_contains 'Real cleanup remains a separate, unavailable stage' "$DRY_RUNNER" \
    'usage should state that real apply is unavailable'
assert_contains 'apply_authorized' "$DRY_RUNNER" \
    'dry-run results should preserve explicit apply denial'
assert_not_contains 'subprocess.' "$DRY_RUNNER" \
    'dry-run source must not launch Python subprocesses'
assert_not_contains 'os.system' "$DRY_RUNNER" \
    'dry-run source must not invoke a shell through Python'
assert_not_contains 'shell=True' "$DRY_RUNNER" \
    'dry-run source must not enable shell execution'
assert_not_contains 'eval ' "$DRY_RUNNER" \
    'dry-run source must not use eval'
assert_success 'dry-run executor should pass Bash syntax validation' bash -n "$DRY_RUNNER"
assert_success 'dry-run harness should pass Bash syntax validation' bash -n "$0"
assert_success 'authorization policy fixture should be valid JSON' python3 -m json.tool "$POLICY"
assert_equal dry-run-only "$(json_get "$POLICY" scope)" 'policy should be limited to dry-run'
assert_equal false "$(json_get "$POLICY" apply_authorized)" 'policy must deny apply'

ELILO_BLOCKED_PLAN=$TMP/elilo-blocked-plan.json
ELILO_MATURE_PLAN=$TMP/elilo-mature-plan.json
GRUB_MATURE_PLAN=$TMP/grub-mature-plan.json
GRUB_SINGLE_PLAN=$TMP/grub-single-plan.json
assert_success 'ineligible ELILO fixture should produce a plan' make_plan "$ELILO_INELIGIBLE" "$ELILO_BLOCKED_PLAN"
assert_success 'mature synthetic ELILO fixture should produce a plan' make_plan "$ELILO_MATURE" "$ELILO_MATURE_PLAN"
assert_success 'mature GRUB fixture should produce a plan' make_plan "$GRUB_MATURE" "$GRUB_MATURE_PLAN"
assert_success 'single-kernel GRUB fixture should produce a plan' make_plan "$GRUB_SINGLE" "$GRUB_SINGLE_PLAN"
assert_equal '/boot/efi/EFI/Slackware/elilo.conf' "$(json_get "$ELILO_MATURE_PLAN" boot_transaction.config)" \
    'ELILO plan should expose the exact configuration path'
assert_equal '["/boot/efi/EFI/Slackware/initrd.gz","/boot/efi/EFI/Slackware/vmlinuz"]' \
    "$(json_get "$ELILO_MATURE_PLAN" boot_transaction.rollback_artifacts)" \
    'ELILO plan should expose only the two legacy EFI rollback files'
assert_equal '/boot/grub/grub.cfg' "$(json_get "$GRUB_MATURE_PLAN" boot_transaction.config)" \
    'GRUB plan should expose the exact configuration path'
assert_equal '[]' "$(json_get "$GRUB_MATURE_PLAN" boot_transaction.rollback_artifacts)" \
    'GRUB plan should not claim unowned rollback artifacts'

ELILO_BLOCKED_RESULT=$TMP/elilo-blocked-result.json
assert_success 'ineligible ELILO plan should produce a blocked dry-run result' run_dry "$ELILO_BLOCKED_PLAN" "$ELILO_BLOCKED_RESULT"
assert_equal blocked "$(json_get "$ELILO_BLOCKED_RESULT" status)" 'ineligible ELILO dry-run should be blocked'
assert_equal false "$(json_get "$ELILO_BLOCKED_RESULT" simulation_complete)" 'blocked dry-run should not simulate stages'
assert_equal false "$(json_get "$ELILO_BLOCKED_RESULT" dry_run_authorized)" 'blocked dry-run should remain unauthorized'
assert_equal false "$(json_get "$ELILO_BLOCKED_RESULT" apply_authorized)" 'blocked dry-run must deny apply'
assert_equal '[]' "$(json_get "$ELILO_BLOCKED_RESULT" steps)" 'blocked dry-run should contain no steps'
assert_contains 'retention-eligibility-not-accepted' "$ELILO_BLOCKED_RESULT" \
    'blocked dry-run should retain the eligibility reason'
assert_contains 'dry-run-authorization-missing' "$ELILO_BLOCKED_RESULT" \
    'blocked dry-run should report missing simulation authorization'

GRUB_BLOCKED_RESULT=$TMP/grub-blocked-result.json
assert_success 'eligible GRUB plan without authorization should remain blocked' run_dry "$GRUB_MATURE_PLAN" "$GRUB_BLOCKED_RESULT"
assert_equal blocked "$(json_get "$GRUB_BLOCKED_RESULT" status)" 'eligible unauthenticated dry-run should be blocked'
assert_not_contains 'retention-eligibility-not-accepted' "$GRUB_BLOCKED_RESULT" \
    'eligible plan should not report an eligibility blocker'
assert_contains 'dry-run-authorization-missing' "$GRUB_BLOCKED_RESULT" \
    'eligible plan should require dry-run authorization'

GRUB_SINGLE_RESULT=$TMP/grub-single-result.json
assert_success 'single-kernel GRUB plan should produce a no-op result' run_dry "$GRUB_SINGLE_PLAN" "$GRUB_SINGLE_RESULT"
assert_equal not-applicable "$(json_get "$GRUB_SINGLE_RESULT" status)" 'single-kernel dry-run should be inapplicable'
assert_equal true "$(json_get "$GRUB_SINGLE_RESULT" simulation_complete)" 'single-kernel no-op should complete'
assert_equal '[]' "$(json_get "$GRUB_SINGLE_RESULT" steps)" 'single-kernel no-op should contain no steps'
assert_equal '[]' "$(json_get "$GRUB_SINGLE_RESULT" mutations_performed)" 'single-kernel no-op should perform no mutations'

ELILO_AUTH=$TMP/elilo-auth.json
GRUB_AUTH=$TMP/grub-auth.json
make_authorization "$ELILO_MATURE_PLAN" "$ELILO_AUTH" elilo-dry-run-fixture-001
make_authorization "$GRUB_MATURE_PLAN" "$GRUB_AUTH" grub-dry-run-fixture-001
ELILO_RESULT=$TMP/elilo-result.json
GRUB_RESULT=$TMP/grub-result.json
assert_success 'authorized mature ELILO plan should complete its simulation' run_dry "$ELILO_MATURE_PLAN" "$ELILO_RESULT" "$ELILO_AUTH"
assert_success 'authorized mature GRUB plan should complete its simulation' run_dry "$GRUB_MATURE_PLAN" "$GRUB_RESULT" "$GRUB_AUTH"
assert_equal simulation-complete "$(json_get "$ELILO_RESULT" status)" 'ELILO simulation should complete'
assert_equal simulation-complete "$(json_get "$GRUB_RESULT" status)" 'GRUB simulation should complete'
assert_equal true "$(json_get "$ELILO_RESULT" dry_run_authorized)" 'ELILO simulation should record dry-run authorization'
assert_equal false "$(json_get "$ELILO_RESULT" apply_authorized)" 'ELILO simulation must deny apply'
assert_equal false "$(json_get "$GRUB_RESULT" apply_authorized)" 'GRUB simulation must deny apply'
assert_equal 14 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["steps"]))' "$ELILO_RESULT")" \
    'ELILO simulation should contain fourteen ordered steps'
assert_equal 14 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["steps"]))' "$GRUB_RESULT")" \
    'GRUB simulation should contain fourteen ordered steps'
assert_equal '[]' "$(json_get "$ELILO_RESULT" commands_executed)" 'ELILO simulation should execute no commands'
assert_equal '[]' "$(json_get "$ELILO_RESULT" mutations_performed)" 'ELILO simulation should perform no mutations'
assert_equal '[]' "$(json_get "$GRUB_RESULT" commands_executed)" 'GRUB simulation should execute no commands'
assert_equal '[]' "$(json_get "$GRUB_RESULT" mutations_performed)" 'GRUB simulation should perform no mutations'
assert_contains '"/sbin/removepkg"' "$ELILO_RESULT" 'ELILO simulation should show exact proposed package removals as data'
assert_contains '"/sbin/upgradepkg"' "$ELILO_RESULT" 'ELILO simulation should show active-package repair as data'
assert_contains '"/boot/efi/EFI/Slackware/initrd.gz"' "$ELILO_RESULT" 'ELILO simulation should show delayed legacy initrd deletion'
assert_contains '"/boot/efi/EFI/Slackware/vmlinuz"' "$ELILO_RESULT" 'ELILO simulation should show delayed legacy kernel deletion'
assert_contains '"/usr/sbin/grub-mkconfig"' "$GRUB_RESULT" 'GRUB simulation should show staged generation as data'
assert_contains '"/usr/bin/grub-script-check"' "$GRUB_RESULT" 'GRUB simulation should show staged validation as data'
assert_contains '"/bin/mv"' "$GRUB_RESULT" 'GRUB simulation should show atomic replacement as data'
assert_not_contains '"/bin/rm"' "$GRUB_RESULT" 'GRUB simulation should not invent unowned rollback file deletion'
assert_equal 64 "$(json_get "$ELILO_RESULT" result_sha256 | wc -c | awk '{print $1-1}')" \
    'ELILO result should expose a 64-character identity'

ELILO_RESULT_2=$TMP/elilo-result-2.json
assert_success 'repeated ELILO simulation should succeed' run_dry "$ELILO_MATURE_PLAN" "$ELILO_RESULT_2" "$ELILO_AUTH"
assert_success 'repeated ELILO simulation should be byte-identical' cmp -s "$ELILO_RESULT" "$ELILO_RESULT_2"
STDOUT_RESULT=$TMP/stdout-result.json
assert_success 'stdout simulation should succeed' bash -c '"$1" --dry-run --plan "$2" --authorization "$3" > "$4"' _ "$DRY_RUNNER" "$GRUB_MATURE_PLAN" "$GRUB_AUTH" "$STDOUT_RESULT"
assert_success 'stdout and file simulation should be byte-identical' cmp -s "$GRUB_RESULT" "$STDOUT_RESULT"

FAIL_EARLY=$TMP/fail-early.json
FAIL_REINSTALL=$TMP/fail-reinstall.json
FAIL_ACTIVATE=$TMP/fail-activate.json
FAIL_DELETE=$TMP/fail-delete.json
assert_success 'early failure injection should render safely' run_dry "$ELILO_MATURE_PLAN" "$FAIL_EARLY" "$ELILO_AUTH" revalidate_inventory_and_running_kernel
assert_success 'package repair failure injection should render safely' run_dry "$ELILO_MATURE_PLAN" "$FAIL_REINSTALL" "$ELILO_AUTH" reinstall_exact_active_package_set
assert_success 'ELILO activation failure injection should render safely' run_dry "$ELILO_MATURE_PLAN" "$FAIL_ACTIVATE" "$ELILO_AUTH" atomically_activate_elilo_config
assert_success 'artifact deletion failure injection should render safely' run_dry "$ELILO_MATURE_PLAN" "$FAIL_DELETE" "$ELILO_AUTH" delete_only_unreferenced_rollback_artifacts
assert_equal simulated-failure "$(json_get "$FAIL_EARLY" status)" 'failure injection should be explicit'
assert_contains 'discard_private_dry_run_workspace' "$FAIL_EARLY" 'early failure should require only workspace discard'
assert_contains 'reinstall_exact_active_package_set_from_verified_archives' "$FAIL_REINSTALL" 'post-removal failure should require active repair'
assert_not_contains 'atomically_restore_archived_boot_loader_configuration' "$FAIL_REINSTALL" 'pre-activation failure should preserve the active boot config'
assert_contains 'atomically_restore_archived_boot_loader_configuration' "$FAIL_ACTIVATE" 'activation failure should define atomic boot-config restoration'
assert_contains 'restore_archived_rollback_artifacts' "$FAIL_DELETE" 'post-deletion failure should define rollback artifact restoration'
assert_contains '"outcome": "not-reached"' "$FAIL_ACTIVATE" 'failure injection should stop later simulated stages'
assert_equal '[]' "$(json_get "$FAIL_DELETE" commands_executed)" 'failure simulation should still execute no commands'
assert_equal '[]' "$(json_get "$FAIL_DELETE" mutations_performed)" 'failure simulation should still perform no mutations'

assert_failure 'missing --dry-run should fail' "$DRY_RUNNER" --plan "$ELILO_MATURE_PLAN"
assert_failure 'unknown --apply option should fail' "$DRY_RUNNER" --apply --plan "$ELILO_MATURE_PLAN"
assert_failure 'missing plan option should fail' "$DRY_RUNNER" --dry-run
assert_failure 'missing plan value should fail' "$DRY_RUNNER" --dry-run --plan
assert_failure 'relative output should fail' "$DRY_RUNNER" --dry-run --plan "$ELILO_MATURE_PLAN" --output relative.json
EXISTING=$TMP/existing.json
printf '{}\n' > "$EXISTING"
assert_failure 'existing output should fail' "$DRY_RUNNER" --dry-run --plan "$ELILO_MATURE_PLAN" --output "$EXISTING"
PLAN_LINK=$TMP/plan-link.json
ln -s "$ELILO_MATURE_PLAN" "$PLAN_LINK"
assert_failure 'plan symlinks should fail' "$DRY_RUNNER" --dry-run --plan "$PLAN_LINK"
AUTH_LINK=$TMP/auth-link.json
ln -s "$ELILO_AUTH" "$AUTH_LINK"
assert_failure 'authorization symlinks should fail' "$DRY_RUNNER" --dry-run --plan "$ELILO_MATURE_PLAN" --authorization "$AUTH_LINK"
assert_failure 'failure injection without authorization should fail' "$DRY_RUNNER" --dry-run --plan "$ELILO_MATURE_PLAN" --simulate-failure-at reinstall_exact_active_package_set
assert_failure 'unknown failure action should fail' "$DRY_RUNNER" --dry-run --plan "$ELILO_MATURE_PLAN" --authorization "$ELILO_AUTH" --simulate-failure-at unknown_action
assert_failure 'authorization must not target an ineligible plan' "$DRY_RUNNER" --dry-run --plan "$ELILO_BLOCKED_PLAN" --authorization "$ELILO_AUTH"
assert_failure 'authorization must not target a non-applicable plan' "$DRY_RUNNER" --dry-run --plan "$GRUB_SINGLE_PLAN" --authorization "$GRUB_AUTH"

INVALID=$TMP/invalid.json
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["active_kernel"] = "5.15.999"'
assert_failure 'plan content hash mismatch should fail' run_dry "$INVALID" "$TMP/hash-mismatch.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["apply_permitted"] = True' true
assert_failure 'plans that permit apply should fail' run_dry "$INVALID" "$TMP/apply-permitted.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["cleanup_authorized"] = True' true
assert_failure 'plans that authorize cleanup should fail' run_dry "$INVALID" "$TMP/cleanup-authorized.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["requires_separate_apply_stage"] = False' true
assert_failure 'plans without a separate apply stage should fail' run_dry "$INVALID" "$TMP/separate-stage.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["actions"].reverse()' true
assert_failure 'reordered action sequences should fail' run_dry "$INVALID" "$TMP/reordered.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["boot_transaction"]["config"] = "relative"' true
assert_failure 'unsafe boot configuration paths should fail' run_dry "$INVALID" "$TMP/boot-path.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["boot_transaction"]["rollback_artifacts"].append(data["boot_transaction"]["rollback_artifacts"][0])' true
assert_failure 'duplicate rollback artifacts should fail' run_dry "$INVALID" "$TMP/artifact-duplicate.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["active_packages"].pop()' true
assert_failure 'incomplete active package sets should fail' run_dry "$INVALID" "$TMP/active-set.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["active_packages"][0] += ";unsafe"' true
assert_failure 'unsafe active package records should fail' run_dry "$INVALID" "$TMP/active-record.json" "$ELILO_AUTH"
mutate_json "$ELILO_MATURE_PLAN" "$INVALID" 'data["active_archives"][0]["path"] = "/var/cache/../tmp/kernel.txz"' true
assert_failure 'non-canonical archive paths should fail' run_dry "$INVALID" "$TMP/archive-path.json" "$ELILO_AUTH"

INVALID_AUTH=$TMP/invalid-auth.json
mutate_json "$ELILO_AUTH" "$INVALID_AUTH" 'data["apply_authorized"] = True'
assert_failure 'dry-run authorization must deny apply' run_dry "$ELILO_MATURE_PLAN" "$TMP/auth-apply.json" "$INVALID_AUTH"
mutate_json "$ELILO_AUTH" "$INVALID_AUTH" 'data["scope"] = "apply"'
assert_failure 'dry-run authorization scope must be exact' run_dry "$ELILO_MATURE_PLAN" "$TMP/auth-scope.json" "$INVALID_AUTH"
mutate_json "$ELILO_AUTH" "$INVALID_AUTH" 'data["confirmation"] = "yes"'
assert_failure 'dry-run authorization confirmation must be exact' run_dry "$ELILO_MATURE_PLAN" "$TMP/auth-confirmation.json" "$INVALID_AUTH"
mutate_json "$ELILO_AUTH" "$INVALID_AUTH" 'data["plan_sha256"] = "0" * 64'
assert_failure 'dry-run authorization must match the exact plan' run_dry "$ELILO_MATURE_PLAN" "$TMP/auth-plan.json" "$INVALID_AUTH"
mutate_json "$ELILO_AUTH" "$INVALID_AUTH" 'data["rollback_kernel"] = "5.15.18"'
assert_failure 'dry-run authorization must match the rollback kernel' run_dry "$ELILO_MATURE_PLAN" "$TMP/auth-kernel.json" "$INVALID_AUTH"
mutate_json "$ELILO_AUTH" "$INVALID_AUTH" 'data["authorization_id"] = "../unsafe"'
assert_failure 'dry-run authorization IDs must be safe' run_dry "$ELILO_MATURE_PLAN" "$TMP/auth-id.json" "$INVALID_AUTH"

printf 'Kernel cleanup dry-run harness: %d checks, %d failures\n' "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
