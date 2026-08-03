#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
PLANNER=$REPOSITORY_ROOT/tools/reference/kernel-cleanup-plan-reference.sh
FIXTURE_DIR=$REPOSITORY_ROOT/tests/fixtures/reference/kernel-cleanup
ELILO_FIXTURE=$FIXTURE_DIR/slackware-15.0-elilo-dual-kernel-design.json
GRUB_DUAL_FIXTURE=$FIXTURE_DIR/slackware-15.0-grub-dual-kernel-design.json
GRUB_SINGLE_FIXTURE=$FIXTURE_DIR/slackware-15.0-grub-single-kernel-observed.json

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
    if part.isdigit():
        value = value[int(part)]
    else:
        value = value[part]
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

mutate_fixture() {
    local source=$1 destination=$2 expression=$3
    python3 - "$source" "$destination" "$expression" <<'PYTHON_EOF'
import json
import sys
source, destination, expression = sys.argv[1:]
data = json.load(open(source, encoding="utf-8"))
exec(expression, {"data": data})
with open(destination, "w", encoding="utf-8") as stream:
    json.dump(data, stream, sort_keys=True, indent=2)
    stream.write("\n")
PYTHON_EOF
}

run_plan() {
    local fixture=$1 output=$2
    "$PLANNER" --input "$fixture" --output "$output"
}

assert_contains 'non-destructive cleanup plan' "$PLANNER" \
    'planner usage should describe the non-destructive boundary'
assert_contains 'cleanup_authorized' "$PLANNER" \
    'planner should preserve a separate cleanup authorization field'
assert_contains 'requires_separate_apply_stage' "$PLANNER" \
    'planner should require a separate apply stage'
assert_not_contains 'removepkg ' "$PLANNER" \
    'planner source must not invoke package removal'
assert_not_contains 'upgradepkg ' "$PLANNER" \
    'planner source must not invoke package upgrades'
assert_not_contains 'installpkg ' "$PLANNER" \
    'planner source must not invoke package installation'
assert_not_contains 'grub-mkconfig -o' "$PLANNER" \
    'planner source must not execute GRUB generation'
assert_not_contains 'eliloconfig' "$PLANNER" \
    'planner source must not execute ELILO configuration'
assert_not_contains 'rm -' "$PLANNER" \
    'planner source must not execute file removal'
assert_success 'planner should pass Bash syntax validation' bash -n "$PLANNER"
assert_success 'test harness should pass Bash syntax validation' bash -n "$0"

# The accepted ELILO retention baseline produces a complete but blocked plan.
ELILO_PLAN=$TMP/elilo-plan.json
assert_success 'ELILO design fixture should produce a plan' run_plan "$ELILO_FIXTURE" "$ELILO_PLAN"
assert_equal 1 "$(json_get "$ELILO_PLAN" schema)" 'ELILO plan should use schema 1'
assert_equal kernel-cleanup-plan "$(json_get "$ELILO_PLAN" scenario)" 'ELILO plan should expose the cleanup scenario'
assert_equal elilo "$(json_get "$ELILO_PLAN" boot_loader)" 'ELILO plan should preserve the backend'
assert_equal true "$(json_get "$ELILO_PLAN" applicable)" 'ELILO plan should be applicable with a rollback kernel'
assert_equal designed-blocked "$(json_get "$ELILO_PLAN" status)" 'ELILO plan should remain blocked'
assert_equal false "$(json_get "$ELILO_PLAN" cleanup_eligible)" 'ELILO baseline should remain retention-ineligible'
assert_equal false "$(json_get "$ELILO_PLAN" cleanup_authorized)" 'ELILO plan should remain unauthorized'
assert_equal false "$(json_get "$ELILO_PLAN" apply_permitted)" 'ELILO plan must never permit apply'
assert_equal true "$(json_get "$ELILO_PLAN" requires_separate_apply_stage)" 'ELILO plan should require a separate apply stage'
assert_equal 5.15.209 "$(json_get "$ELILO_PLAN" running_kernel)" 'ELILO plan should preserve the running kernel'
assert_equal 5.15.19 "$(json_get "$ELILO_PLAN" rollback_kernel)" 'ELILO plan should preserve the rollback version'
assert_equal /boot/efi/EFI/Slackware/elilo.conf "$(json_get "$ELILO_PLAN" boot_transaction.config)"     'ELILO plan should expose its exact configuration path'
assert_equal '["/boot/efi/EFI/Slackware/initrd.gz","/boot/efi/EFI/Slackware/vmlinuz"]'     "$(json_get "$ELILO_PLAN" boot_transaction.rollback_artifacts)"     'ELILO plan should expose only the two legacy EFI rollback files'
assert_equal 3 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["active_packages"]))' "$ELILO_PLAN")" 'ELILO plan should contain three active packages'
assert_equal 3 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["rollback_packages"]))' "$ELILO_PLAN")" 'ELILO plan should contain three rollback packages'
assert_equal 3 "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["active_archives"]))' "$ELILO_PLAN")" 'ELILO plan should cover three active archives'
assert_contains 'retention-eligibility-not-accepted' "$ELILO_PLAN" \
    'ELILO baseline should be blocked by retention eligibility'
assert_contains 'cleanup-authorization-not-granted' "$ELILO_PLAN" \
    'ELILO baseline should be blocked by authorization'
assert_contains 'remove_exact_rollback_package_records' "$ELILO_PLAN" \
    'ELILO plan should remove only exact rollback package records'
assert_contains 'reinstall_exact_active_package_set' "$ELILO_PLAN" \
    'ELILO plan should repair shared paths by reinstalling active packages'
assert_contains 'stage_elilo_config_without_oldkernel' "$ELILO_PLAN" \
    'ELILO backend should stage oldkernel removal'
assert_contains 'atomically_activate_elilo_config' "$ELILO_PLAN" \
    'ELILO backend should activate its staged configuration atomically'
assert_contains 'prove_oldkernel_is_no_longer_referenced' "$ELILO_PLAN" \
    'ELILO backend should prove oldkernel is unreferenced before deletion'
assert_contains 'delete_only_unreferenced_rollback_artifacts' "$ELILO_PLAN" \
    'ELILO plan should delay rollback artifact deletion'
assert_contains 'preserve kernel headers source and firmware packages' "$ELILO_PLAN" \
    'ELILO plan should preserve non-boot kernel packages'
assert_equal 64 "$(json_get "$ELILO_PLAN" plan_sha256 | wc -c | awk '{print $1-1}')" \
    'ELILO plan should expose a 64-character SHA-256 identity'

# A mature synthetic GRUB inventory uses regeneration and atomic replacement.
GRUB_DUAL_PLAN=$TMP/grub-dual-plan.json
assert_success 'dual-kernel GRUB fixture should produce a plan' run_plan "$GRUB_DUAL_FIXTURE" "$GRUB_DUAL_PLAN"
assert_equal grub "$(json_get "$GRUB_DUAL_PLAN" boot_loader)" 'GRUB plan should preserve the backend'
assert_equal true "$(json_get "$GRUB_DUAL_PLAN" applicable)" 'GRUB plan should be applicable with a rollback kernel'
assert_equal true "$(json_get "$GRUB_DUAL_PLAN" cleanup_eligible)" 'mature GRUB fixture should preserve eligibility'
assert_equal false "$(json_get "$GRUB_DUAL_PLAN" cleanup_authorized)" 'mature GRUB fixture should remain unauthorized'
assert_equal false "$(json_get "$GRUB_DUAL_PLAN" apply_permitted)" 'mature eligibility alone must not permit apply'
assert_equal /boot/grub/grub.cfg "$(json_get "$GRUB_DUAL_PLAN" boot_transaction.config)"     'GRUB plan should expose its exact configuration path'
assert_equal huge "$(json_get "$GRUB_DUAL_PLAN" boot_transaction.default_flavor)"     'GRUB plan should preserve the observed default flavor'
assert_equal '[]' "$(json_get "$GRUB_DUAL_PLAN" boot_transaction.rollback_artifacts)"     'GRUB plan should not invent unowned rollback artifacts'
assert_not_contains 'retention-eligibility-not-accepted' "$GRUB_DUAL_PLAN" \
    'mature GRUB plan should not retain the eligibility blocker'
assert_contains 'cleanup-authorization-not-granted' "$GRUB_DUAL_PLAN" \
    'mature GRUB plan should retain the authorization blocker'
assert_contains 'generate_grub_config_to_same_directory_temporary_file' "$GRUB_DUAL_PLAN" \
    'GRUB backend should generate to a same-directory temporary file'
assert_contains 'validate_staged_grub_config' "$GRUB_DUAL_PLAN" \
    'GRUB backend should validate staged syntax'
assert_contains 'verify_active_entries_and_absent_rollback_entries' "$GRUB_DUAL_PLAN" \
    'GRUB backend should verify active and removed rollback entries'
assert_contains 'atomically_replace_grub_config' "$GRUB_DUAL_PLAN" \
    'GRUB backend should replace the active configuration atomically'
assert_contains 'never hand-edit the active GRUB configuration' "$GRUB_DUAL_PLAN" \
    'GRUB plan should forbid hand editing'
assert_contains 'never write grub-mkconfig output directly to the active path' "$GRUB_DUAL_PLAN" \
    'GRUB plan should preserve staged generation'
assert_contains 'kernel-firmware-20250912_f0f4634-noarch-1' "$GRUB_DUAL_PLAN" \
    'GRUB plan should preserve firmware packages'
assert_contains 'kernel-headers-5.15.209-x86-1' "$GRUB_DUAL_PLAN" \
    'GRUB plan should preserve kernel headers'
assert_contains 'kernel-source-5.15.209-noarch-1' "$GRUB_DUAL_PLAN" \
    'GRUB plan should preserve kernel source'

# The observed development VM has no rollback and must remain untouched.
GRUB_SINGLE_PLAN=$TMP/grub-single-plan.json
assert_success 'single-kernel GRUB fixture should produce a not-applicable result' run_plan "$GRUB_SINGLE_FIXTURE" "$GRUB_SINGLE_PLAN"
assert_equal grub "$(json_get "$GRUB_SINGLE_PLAN" boot_loader)" 'single-kernel result should preserve GRUB'
assert_equal false "$(json_get "$GRUB_SINGLE_PLAN" applicable)" 'single-kernel result should be inapplicable'
assert_equal not-applicable "$(json_get "$GRUB_SINGLE_PLAN" status)" 'single-kernel result should use a stable status'
assert_equal null "$(json_get "$GRUB_SINGLE_PLAN" rollback_kernel)" 'single-kernel result should expose no rollback'
assert_equal '[]' "$(json_get "$GRUB_SINGLE_PLAN" actions)" 'single-kernel result should schedule no actions'
assert_contains 'no-rollback-kernel-present' "$GRUB_SINGLE_PLAN" \
    'single-kernel result should explain why cleanup is inapplicable'
assert_contains 'leave the active package set unchanged' "$GRUB_SINGLE_PLAN" \
    'single-kernel result should preserve active packages'
assert_contains 'leave boot-loader configuration unchanged' "$GRUB_SINGLE_PLAN" \
    'single-kernel result should preserve GRUB'
assert_equal false "$(json_get "$GRUB_SINGLE_PLAN" apply_permitted)" 'single-kernel result should not permit apply'
assert_equal false "$(json_get "$GRUB_SINGLE_PLAN" boot_transaction.rollback_entries_present)"     'single-kernel result should preserve the absence of rollback entries'

# Output is deterministic across repeated runs and stdout/file modes.
ELILO_PLAN_2=$TMP/elilo-plan-2.json
assert_success 'repeated ELILO planning should succeed' run_plan "$ELILO_FIXTURE" "$ELILO_PLAN_2"
assert_success 'repeated ELILO planning should be byte-identical' cmp -s "$ELILO_PLAN" "$ELILO_PLAN_2"
STDOUT_PLAN=$TMP/stdout-plan.json
assert_success 'stdout planning should succeed' bash -c '"$1" --input "$2" > "$3"' _ "$PLANNER" "$GRUB_SINGLE_FIXTURE" "$STDOUT_PLAN"
assert_success 'stdout and file planning should be byte-identical' cmp -s "$GRUB_SINGLE_PLAN" "$STDOUT_PLAN"

# CLI and path safety failures are closed and do not create outputs.
assert_failure 'missing input option should fail' "$PLANNER"
assert_failure 'unknown option should fail' "$PLANNER" --unknown
assert_failure 'missing input value should fail' "$PLANNER" --input
assert_failure 'relative output path should fail' "$PLANNER" --input "$ELILO_FIXTURE" --output relative.json
EXISTING_OUTPUT=$TMP/existing.json
printf '{}\n' > "$EXISTING_OUTPUT"
assert_failure 'existing output path should be rejected' "$PLANNER" --input "$ELILO_FIXTURE" --output "$EXISTING_OUTPUT"
INPUT_LINK=$TMP/input-link.json
ln -s "$ELILO_FIXTURE" "$INPUT_LINK"
assert_failure 'input symlinks should be rejected' "$PLANNER" --input "$INPUT_LINK"
assert_failure 'missing input files should be rejected' "$PLANNER" --input "$TMP/missing.json"

# Inventory validation rejects unsafe or incomplete package state.
INVALID=$TMP/invalid.json
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["schema"] = 2'
assert_failure 'unsupported schema should fail' run_plan "$INVALID" "$TMP/schema-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["cleanup_authorized"] = True'
assert_failure 'planning input must not authorize cleanup' run_plan "$INVALID" "$TMP/authorized-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["running_kernel"] = "5.15.19"'
assert_failure 'running a rollback kernel should fail' run_plan "$INVALID" "$TMP/running-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["rollback_kernel"] = "../5.15.19"'
assert_failure 'unsafe rollback versions should fail' run_plan "$INVALID" "$TMP/version-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["package_database"]["internal_record_symlinks"] = True'
assert_failure 'package record symlinks should fail' run_plan "$INVALID" "$TMP/symlink-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["packages"]["active"].pop()'
assert_failure 'incomplete active package sets should fail' run_plan "$INVALID" "$TMP/active-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["module_trees"]["rollback"] = False'
assert_failure 'missing rollback module trees should fail' run_plan "$INVALID" "$TMP/rollback-module-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["active_archives"].pop()'
assert_failure 'incomplete active archives should fail' run_plan "$INVALID" "$TMP/archive-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["active_archives"][0]["sha256"] = "bad"'
assert_failure 'unsafe active archive hashes should fail' run_plan "$INVALID" "$TMP/hash-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["active_archives"][0]["path"] = "/var/cache/../tmp/kernel.txz"'
assert_failure 'non-canonical active archive paths should fail' run_plan "$INVALID" "$TMP/archive-path-output.json"

# Backend validation rejects unsafe boot state.
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["boot"]["active_entry"]["kernel"] = "vmlinuz"'
assert_failure 'unversioned active ELILO kernels should fail' run_plan "$INVALID" "$TMP/elilo-kernel-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["boot"]["config"] = "/boot/efi/../elilo.conf"'
assert_failure 'non-canonical ELILO configuration paths should fail' run_plan "$INVALID" "$TMP/elilo-path-output.json"
mutate_fixture "$ELILO_FIXTURE" "$INVALID" 'data["boot"]["rollback_entry"]["label"] = "fallback"'
assert_failure 'unexpected ELILO rollback labels should fail' run_plan "$INVALID" "$TMP/elilo-label-output.json"
mutate_fixture "$GRUB_DUAL_FIXTURE" "$INVALID" 'data["boot"]["generator_available"] = False'
assert_failure 'missing grub-mkconfig should fail' run_plan "$INVALID" "$TMP/grub-generator-output.json"
mutate_fixture "$GRUB_DUAL_FIXTURE" "$INVALID" 'data["boot"]["validator_available"] = False'
assert_failure 'missing grub-script-check should fail' run_plan "$INVALID" "$TMP/grub-validator-output.json"
mutate_fixture "$GRUB_DUAL_FIXTURE" "$INVALID" 'data["boot"]["rollback_entries_present"] = False'
assert_failure 'missing rollback GRUB entries should fail for dual-kernel state' run_plan "$INVALID" "$TMP/grub-rollback-output.json"
mutate_fixture "$GRUB_SINGLE_FIXTURE" "$INVALID" 'data["boot"]["rollback_entries_present"] = True'
assert_failure 'rollback GRUB entries without rollback packages should fail' run_plan "$INVALID" "$TMP/grub-single-rollback-output.json"

printf 'Kernel cleanup plan harness: %d checks, %d failures\n' "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
