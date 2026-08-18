#!/bin/bash
# Static harness for the Phase 1 configuration-boundary inventory.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
INVENTORY="$REPO_ROOT/tools/reference/configuration-boundary-inventory.sh"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-boundary-review-policy.json"
REVIEW_DOC="$REPO_ROOT/docs/reference/configuration-boundary-review.md"
ACCEPTED116="$REPO_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
REFERENCE_ENGINE="$REPO_ROOT/tools/reference/slack-update-reference.sh"

PASSES=0
FAILURES=0

pass() { echo "PASS: $*"; PASSES=$((PASSES + 1)); }
fail() { echo "FAIL: $*"; FAILURES=$((FAILURES + 1)); }

check_regular() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then pass "$2 is a regular non-symlink file"; else fail "$2 is a regular non-symlink file"; fi
}

check_regular "$INVENTORY" "configuration inventory"
check_regular "$POLICY" "configuration-boundary policy"
check_regular "$REVIEW_DOC" "configuration-boundary review document"
check_regular "$ACCEPTED116" "accepted step-116 record"
check_regular "$REFERENCE_ENGINE" "reference engine"

if bash -n "$INVENTORY"; then pass "configuration inventory is shell-syntax valid"; else fail "configuration inventory is shell-syntax valid"; fi

if "$INVENTORY" --help >/dev/null 2>&1; then pass "configuration inventory exposes a help boundary"; else fail "configuration inventory exposes a help boundary"; fi
if "$INVENTORY" --definitely-invalid >/dev/null 2>&1; then fail "unknown inventory options fail closed"; else pass "unknown inventory options fail closed"; fi

python3 - "$POLICY" "$ACCEPTED116" "$INVENTORY" "$REVIEW_DOC" <<'PY'
import hashlib, json, pathlib, sys
policy_path, accepted_path, inventory_path, doc_path = map(pathlib.Path, sys.argv[1:])
policy = json.loads(policy_path.read_text())
accepted = json.loads(accepted_path.read_text())

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def emit(ok, text):
    print(("PYPASS: " if ok else "PYFAIL: ") + text)

emit(policy.get("schema") == 1, "policy schema")
emit(policy.get("scenario") == "phase-1-configuration-boundary-review", "policy scenario")
emit(policy.get("reviewed") is True, "configuration boundary is reviewed")
emit(policy.get("accepted_step_116_record_sha256") == sha(accepted_path), "policy binds the exact accepted step-116 record")
emit(policy.get("accepted_step_116_archive_sha256") == accepted.get("archive_sha256"), "policy binds the accepted step-116 evidence archive")
emit(accepted.get("cleanup_scenario_closed") is True and accepted.get("future_work_requires_fresh_boundary") is True, "step 116 requires this fresh review boundary")
emit(accepted.get("next_stage") == "phase-1-resume-planning", "step 116 resumes only at phase-1 planning")
emit(policy.get("inventory_script_sha256") == sha(inventory_path), "policy binds the exact inventory script")
emit(policy.get("review_document_sha256") == sha(doc_path), "policy binds the exact review document")
emit(policy.get("inventory_source") == "tools/reference/slack-update-reference.sh", "inventory source is the production reference engine")
emit(policy.get("runtime_behavior_change") is False, "step 117 does not change runtime behavior")
emit(policy.get("configuration_file_created") is False, "step 117 creates no runtime configuration file")
emit(policy.get("migration_authorized") is False, "step 117 does not authorize migration")
emit(policy.get("machine_action_required") is False, "step 117 requires no machine action")
emit(policy.get("network_access_allowed") is False, "network access remains denied")
emit(policy.get("package_mutation_allowed") is False, "package mutation remains denied")
emit(policy.get("boot_mutation_allowed") is False, "boot mutation remains denied")
emit(policy.get("module_mutation_allowed") is False, "module mutation remains denied")
emit(policy.get("repository_refresh_allowed") is False, "repository refresh remains denied")
emit(policy.get("module_mode_migration_deferred") is True, "module enabled/disabled/auto migration remains deferred")
emit(policy.get("candidate_classes") == ["assignment", "absolute-path", "external-command"], "inventory candidate classes are exact")
emit(policy.get("required_review_classifications") == ["user-configurable-default", "environment-derived", "internal-constant", "safety-invariant", "deferred-module-mode"], "step-118 classification set is exact")
emit(policy.get("next_stage") == "phase-1-configuration-schema-defaults", "successful review advances only to configuration schema/defaults")
emit(policy.get("pause_safe") is True, "repository-only review remains pause-safe")
PY

# Convert Python result markers into harness counters.
PYOUT=$(python3 - "$POLICY" "$ACCEPTED116" "$INVENTORY" "$REVIEW_DOC" <<'PY'
import hashlib, json, pathlib, sys
policy_path, accepted_path, inventory_path, doc_path = map(pathlib.Path, sys.argv[1:])
policy = json.loads(policy_path.read_text()); accepted = json.loads(accepted_path.read_text())
sha=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
checks=[
policy.get("schema")==1,
policy.get("scenario")=="phase-1-configuration-boundary-review",
policy.get("reviewed") is True,
policy.get("accepted_step_116_record_sha256")==sha(accepted_path),
policy.get("accepted_step_116_archive_sha256")==accepted.get("archive_sha256"),
accepted.get("cleanup_scenario_closed") is True and accepted.get("future_work_requires_fresh_boundary") is True,
accepted.get("next_stage")=="phase-1-resume-planning",
policy.get("inventory_script_sha256")==sha(inventory_path),
policy.get("review_document_sha256")==sha(doc_path),
policy.get("inventory_source")=="tools/reference/slack-update-reference.sh",
policy.get("runtime_behavior_change") is False,
policy.get("configuration_file_created") is False,
policy.get("migration_authorized") is False,
policy.get("machine_action_required") is False,
policy.get("network_access_allowed") is False,
policy.get("package_mutation_allowed") is False,
policy.get("boot_mutation_allowed") is False,
policy.get("module_mutation_allowed") is False,
policy.get("repository_refresh_allowed") is False,
policy.get("module_mode_migration_deferred") is True,
policy.get("candidate_classes")==["assignment","absolute-path","external-command"],
policy.get("required_review_classifications")==["user-configurable-default","environment-derived","internal-constant","safety-invariant","deferred-module-mode"],
policy.get("next_stage")=="phase-1-configuration-schema-defaults",
policy.get("pause_safe") is True,
]
print(sum(checks), len(checks)-sum(checks))
PY
)
PY_PASS=${PYOUT%% *}
PY_FAIL=${PYOUT##* }
PASSES=$((PASSES + PY_PASS))
FAILURES=$((FAILURES + PY_FAIL))

# The inventory itself must be deterministic and detect each candidate class.
TMP_SOURCE=$(mktemp)
trap 'rm -f "$TMP_SOURCE"' EXIT HUP INT TERM
cat > "$TMP_SOURCE" <<'EOF_FIXTURE'
DEFAULT_MODE="safe"
PKG_DB="/var/lib/pkgtools/packages"
run_update() {
    slackpkg upgrade-all
}
EOF_FIXTURE
OUT1=$("$INVENTORY" --source "$TMP_SOURCE")
OUT2=$("$INVENTORY" --source "$TMP_SOURCE")
if [ "$OUT1" = "$OUT2" ]; then pass "inventory output is deterministic for identical source"; else fail "inventory output is deterministic for identical source"; fi
if printf '%s\n' "$OUT1" | grep -q '^assignment'; then pass "inventory detects assignment candidates"; else fail "inventory detects assignment candidates"; fi
if printf '%s\n' "$OUT1" | grep -q '^absolute-path'; then pass "inventory detects absolute-path candidates"; else fail "inventory detects absolute-path candidates"; fi
if printf '%s\n' "$OUT1" | grep -q '^external-command'; then pass "inventory detects external-command candidates"; else fail "inventory detects external-command candidates"; fi
if printf '%s\n' "$OUT1" | grep -q $'^runtime_behavior_change\tfalse$'; then pass "inventory explicitly records no runtime behavior change"; else fail "inventory explicitly records no runtime behavior change"; fi
if printf '%s\n' "$OUT1" | grep -q $'^configuration_file_created\tfalse$'; then pass "inventory explicitly records no configuration file creation"; else fail "inventory explicitly records no configuration file creation"; fi
if printf '%s\n' "$OUT1" | grep -q $'^module_mode_migration_deferred\ttrue$'; then pass "inventory explicitly defers module mode migration"; else fail "inventory explicitly defers module mode migration"; fi

# Source-level deny-list: inventory is read-only with respect to the system and repository.
if grep -Eq '(^|[;&|[:space:]])(slackpkg|installpkg|upgradepkg|removepkg)[[:space:]]' "$INVENTORY"; then fail "inventory source contains no package mutation command"; else pass "inventory source contains no package mutation command"; fi
if grep -Eq '(^|[;&|[:space:]])(reboot|shutdown|poweroff|halt)[[:space:]]' "$INVENTORY"; then fail "inventory source contains no reboot or shutdown command"; else pass "inventory source contains no reboot or shutdown command"; fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|git[[:space:]]+(fetch|pull|clone))[[:space:]]' "$INVENTORY"; then fail "inventory source contains no network client command"; else pass "inventory source contains no network client command"; fi
if grep -Eq '(^|[;&|[:space:]])(rm|mv|cp|install)[[:space:]]' "$INVENTORY"; then fail "inventory source contains no filesystem mutation command"; else pass "inventory source contains no filesystem mutation command"; fi

printf 'Result: %s passes, %s failures\n' "$PASSES" "$FAILURES"
[ "$FAILURES" -eq 0 ]
