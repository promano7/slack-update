#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
FIXTURES="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot"
EXECUTOR="$REPOSITORY_ROOT/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh"
POLICY="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-policy.json"
ACCEPTED_AUTH="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-20260811-accepted.json"
ACCEPTED_PLAN="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json"
ACCEPTED_REVISION="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-review-20260811-accepted.json"
ACCEPTED_SURVIVOR="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-rollback-module-survivor-authorization-review-20260814-accepted.json"
ACCEPTED_THIRD="$FIXTURES/slackware-15.0-elilo-oldkernel-cleanup-third-attempt-authorization-review-20260814-accepted.json"

EXPECTED_EXECUTOR_SHA256=7b42e2df3f99eaa7a92bbb2b91bcc97aa63d5cb0f755b935788409533ada937c
EXPECTED_POLICY_SHA256=98cfb6ead03debb184884da422d9050050f97060991c56cbf5806574e9ab919f
EXPECTED_THIRD_RECORD_SHA256=1500829b085a0f10b2768671fec2d33d67d3f8fa355cc374f297dbf27bed3619
EXPECTED_AUTH_RECORD_SHA256=4289573e994c900fcec0e4a039dac75141bebabfc4ee9289adb08d5b4ce0d40d
EXPECTED_PLAN_RECORD_SHA256=2154bb568b48ed313837858dc2bc3e8406e25c7a6b354282c8ba9d348f2cef09
EXPECTED_REVISION_RECORD_SHA256=7f927e0238ad95b5240a41430ae6e9ab76e825869b7929fe996721e51c14e1c4
EXPECTED_SURVIVOR_RECORD_SHA256=59e1d20f96b52667555b616f6aca63db6fbf9286657d7c94ee7cad8f38ab5af6
EXPECTED_AUTH_ARCHIVE_SHA256=9ed0b6f4c989e4ea5d1742fc47d2ae5c31979e64fc3dffcc1aa7e5ed15934553
EXPECTED_REVISION_ARCHIVE_SHA256=4ed50105ad880742638c91426cdc3d9e9a8dcd04425f5fe74709e9ae708024e7
EXPECTED_SURVIVOR_ARCHIVE_SHA256=405327481b0c7459aab7ddab5b1a2f325fffb6ac2312ed1b4a18afc36d32fe6a
EXPECTED_THIRD_ARCHIVE_SHA256=c9b208042303ed775ed4750b36e4665ed683db7e12a2f33e0544236a30cecdee
EXPECTED_CONTRACT_SHA256=e5b587aacb911a05428706a09c3d7a85dc35a9802e46ccf8131cb3569dd6806f
EXPECTED_SCOPE_SHA256=f9a1beb3973633e4f9af8b2571628f0b24d14338e915e11afc94ac6ef9849e37

passes=0
failures=0

pass() {
    passes=$((passes + 1))
    printf 'PASS: %s\n' "$1"
}

fail() {
    failures=$((failures + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

check_regular() {
    local path=$1 label=$2
    if [[ -f $path && ! -L $path ]]; then
        pass "$label is a regular non-symlink file"
    else
        fail "$label is missing, non-regular, or a symlink"
    fi
}

check_sha() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}') || actual=
    if [[ $actual == "$expected" ]]; then
        pass "$label has the exact reviewed SHA-256"
    else
        fail "$label SHA-256 drifted (expected $expected, got ${actual:-unavailable})"
    fi
}

for item in \
    "$EXECUTOR|executor" \
    "$POLICY|production policy" \
    "$ACCEPTED_AUTH|accepted step-94 record" \
    "$ACCEPTED_PLAN|accepted step-93 record" \
    "$ACCEPTED_REVISION|accepted step-97 record" \
    "$ACCEPTED_SURVIVOR|accepted step-102 record" \
    "$ACCEPTED_THIRD|accepted step-104 record"; do
    IFS='|' read -r path label <<<"$item"
    check_regular "$path" "$label"
done

if (( failures == 0 )); then
    check_sha "$EXECUTOR" "$EXPECTED_EXECUTOR_SHA256" "executor"
    check_sha "$POLICY" "$EXPECTED_POLICY_SHA256" "production policy"
    check_sha "$ACCEPTED_AUTH" "$EXPECTED_AUTH_RECORD_SHA256" "accepted step-94 record"
    check_sha "$ACCEPTED_PLAN" "$EXPECTED_PLAN_RECORD_SHA256" "accepted step-93 record"
    check_sha "$ACCEPTED_REVISION" "$EXPECTED_REVISION_RECORD_SHA256" "accepted step-97 record"
    check_sha "$ACCEPTED_SURVIVOR" "$EXPECTED_SURVIVOR_RECORD_SHA256" "accepted step-102 record"
    check_sha "$ACCEPTED_THIRD" "$EXPECTED_THIRD_RECORD_SHA256" "accepted step-104 record"
fi

if (( failures == 0 )); then
    if python3 - \
        "$POLICY" "$EXECUTOR" "$ACCEPTED_AUTH" "$ACCEPTED_PLAN" "$ACCEPTED_REVISION" "$ACCEPTED_SURVIVOR" "$ACCEPTED_THIRD" \
        "$EXPECTED_AUTH_ARCHIVE_SHA256" "$EXPECTED_REVISION_ARCHIVE_SHA256" "$EXPECTED_SURVIVOR_ARCHIVE_SHA256" "$EXPECTED_THIRD_ARCHIVE_SHA256" \
        "$EXPECTED_CONTRACT_SHA256" "$EXPECTED_SCOPE_SHA256" <<'PY'
import hashlib
import json
import pathlib
import sys

(
    policy_path,
    executor_path,
    auth_path,
    plan_path,
    revision_path,
    survivor_path,
    third_path,
    auth_archive,
    revision_archive,
    survivor_archive,
    third_archive,
    contract,
    expected_scope,
) = sys.argv[1:]


def load(path):
    return json.loads(pathlib.Path(path).read_text(encoding="utf-8"))


def sha(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()


policy = load(policy_path)
auth = load(auth_path)
plan = load(plan_path)
revision = load(revision_path)
survivor = load(survivor_path)
third = load(third_path)

checks = {
    "policy schema and scenario": (
        policy.get("schema") == 3
        and policy.get("scenario") == "elilo-oldkernel-cleanup-authorized-apply-revision-2-prepared"
        and policy.get("reviewed") is True
    ),
    "production execution gate": (
        policy.get("execution_authorized") is True
        and policy.get("third_attempt_authorized") is True
        and policy.get("cleanup_authorized") is True
        and policy.get("apply_authorized") is True
    ),
    "immutable executor binding": policy.get("expected_script_sha256") == sha(executor_path),
    "accepted-record bindings": (
        policy.get("accepted_authorization_record_sha256") == sha(auth_path)
        and policy.get("accepted_source_plan_record_sha256") == sha(plan_path)
        and policy.get("accepted_revision_record_sha256") == sha(revision_path)
        and policy.get("accepted_survivor_authorization_record_sha256") == sha(survivor_path)
        and policy.get("accepted_third_attempt_authorization_record_sha256") == sha(third_path)
    ),
    "accepted-archive bindings": (
        policy.get("accepted_authorization_archive_sha256") == auth_archive
        and policy.get("accepted_revision_archive_sha256") == revision_archive
        and policy.get("accepted_survivor_authorization_archive_sha256") == survivor_archive
        and policy.get("accepted_third_attempt_authorization_archive_sha256") == third_archive
    ),
    "canonical contract binding": policy.get("apply_contract_sha256") == contract,
    "host and kernel binding": (
        policy.get("hostname_fqdn") == "vbox-slack15.vbox-slack15.org"
        and policy.get("active_kernel") == "5.15.209"
        and policy.get("rollback_kernel") == "5.15.19"
    ),
    "destructive-scope restrictions": (
        policy.get("network_access_authorized") is False
        and policy.get("repository_refresh_authorized") is False
        and policy.get("reboot_execution_authorized") is False
        and policy.get("recursive_module_tree_removal_authorized") is False
        and policy.get("active_counterpart_removal_authorized") is False
        and policy.get("exact_survivor_unlink_required") is True
        and policy.get("exact_cached_active_archives_required") is True
        and policy.get("recovery_snapshot_required_before_mutation") is True
        and policy.get("post_apply_reboot_review_required") is True
    ),
    "step-104 accepted result": (
        third.get("accepted") is True
        and third.get("archive_sha256") == third_archive
        and third.get("third_attempt_authorized") is True
        and third.get("cleanup_authorized") is True
        and third.get("apply_authorized") is True
        and third.get("execution_authorized") is False
        and third.get("apply_executed") is False
        and third.get("pause_safe") is True
    ),
    "step-104 immutable executor reference": third.get("revised_apply_script_sha256") == sha(executor_path),
    "step-104 survivor authorization binding": (
        third.get("survivor_deletion_authorization_archive_sha256") == survivor_archive
        and third.get("survivor_deletion_authorization_record_sha256") == sha(survivor_path)
        and third.get("recursive_module_tree_removal_authorized") is False
        and third.get("active_counterpart_removal_authorized") is False
    ),
}

scope = (
    "operation=elilo-oldkernel-cleanup-authorized-apply-revision-2-prepared\n"
    "target=slackware-15.0\n"
    "hostname_fqdn=vbox-slack15.vbox-slack15.org\n"
    f"authorization_evidence_sha256={auth_archive}\n"
    f"revision_evidence_sha256={revision_archive}\n"
    f"survivor_authorization_evidence_sha256={survivor_archive}\n"
    f"third_attempt_authorization_evidence_sha256={third_archive}\n"
    "active_kernel=5.15.209\n"
    "rollback_kernel=5.15.19\n"
    f"apply_contract_sha256={contract}\n"
    f"accepted_authorization_record_sha256={sha(auth_path)}\n"
    f"accepted_revision_record_sha256={sha(revision_path)}\n"
    f"accepted_survivor_authorization_record_sha256={sha(survivor_path)}\n"
    f"accepted_third_attempt_authorization_record_sha256={sha(third_path)}\n"
    f"authorized_apply_script_sha256={sha(executor_path)}\n"
).encode("utf-8")
calculated_scope = hashlib.sha256(scope).hexdigest()
checks["confirmation scope"] = (
    calculated_scope == expected_scope
    and policy.get("confirmation_scope_sha256") == expected_scope
)

for label, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + label)
if not all(checks.values()):
    raise SystemExit(1)
PY
    then
        passes=$((passes + 12))
    else
        failures=$((failures + 1))
    fi
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
(( failures == 0 ))
