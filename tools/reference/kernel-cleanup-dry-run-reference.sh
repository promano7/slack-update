#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

PLAN=
AUTHORIZATION=
OUTPUT=-
DRY_RUN=0
SIMULATE_FAILURE_AT=

print_usage() {
    cat <<'EOF_USAGE'
Usage: kernel-cleanup-dry-run-reference.sh --dry-run --plan FILE
       [--authorization FILE] [--simulate-failure-at ACTION] [--output FILE]

Validate a schema-1 kernel cleanup plan and render a complete execution
simulation. This command never invokes package tools, never edits boot-loader
configuration, never deletes files, and never grants real apply authorization.
A matching dry-run-only authorization is required before destructive stages are
simulated. Real cleanup remains a separate, unavailable stage.
EOF_USAGE
}

error() {
    printf 'error: %s\n' "$*" >&2
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                [ "$DRY_RUN" -eq 0 ] || return 1
                DRY_RUN=1
                shift
                ;;
            --plan)
                [ "$#" -ge 2 ] || return 1
                PLAN=$2
                shift 2
                ;;
            --authorization)
                [ "$#" -ge 2 ] || return 1
                AUTHORIZATION=$2
                shift 2
                ;;
            --simulate-failure-at)
                [ "$#" -ge 2 ] || return 1
                SIMULATE_FAILURE_AT=$2
                shift 2
                ;;
            --output)
                [ "$#" -ge 2 ] || return 1
                OUTPUT=$2
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                error "unknown argument: $1"
                return 1
                ;;
        esac
    done

    [ "$DRY_RUN" -eq 1 ] || return 1
    [ -n "$PLAN" ] || return 1
    [ "$OUTPUT" = - ] || [ -n "$OUTPUT" ] || return 1
}

require_regular_input() {
    local path=$1
    [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ]
}

prepare_output() {
    local parent

    [ "$OUTPUT" != - ] || return 0
    case "$OUTPUT" in
        /*) ;;
        *) error "--output must be an absolute path or '-'"; return 1 ;;
    esac
    [ ! -e "$OUTPUT" ] && [ ! -L "$OUTPUT" ] || {
        error "output path already exists"
        return 1
    }
    parent=${OUTPUT%/*}
    [ -d "$parent" ] && [ ! -L "$parent" ] && [ -w "$parent" ] || {
        error "output parent is not a writable regular directory"
        return 1
    }
}

render_dry_run() {
    python3 - "$PLAN" "$AUTHORIZATION" "$SIMULATE_FAILURE_AT" "$OUTPUT" <<'PYTHON_EOF'
import hashlib
import json
import pathlib
import re
import sys

plan_path = pathlib.Path(sys.argv[1])
authorization_arg = sys.argv[2]
failure_action = sys.argv[3]
output_arg = sys.argv[4]
plan = json.loads(plan_path.read_text(encoding="utf-8"))

SAFE_ID = re.compile(r"^[0-9A-Za-z][0-9A-Za-z._-]{0,127}$")
SAFE_SHA256 = re.compile(r"^[0-9a-f]{64}$")
SAFE_VERSION = re.compile(r"^[0-9A-Za-z._+]+$")
SAFE_PACKAGE = re.compile(
    r"^(?P<name>kernel-(?:generic|huge|modules))-(?P<version>[0-9A-Za-z._+]+)-x86_64-(?P<build>[0-9]+)$"
)
EXPECTED_PACKAGE_NAMES = ("kernel-generic", "kernel-huge", "kernel-modules")
COMMON_ACTIONS = [
    "revalidate_inventory_and_running_kernel",
    "verify_exact_active_package_archives",
    "archive_package_and_boot_state",
    "remove_exact_rollback_package_records",
    "reinstall_exact_active_package_set",
    "verify_active_package_records_and_module_tree",
]
FINAL_ACTIONS = [
    "verify_active_boot_chain",
    "delete_only_unreferenced_rollback_artifacts",
    "capture_and_compare_final_state",
    "publish_private_evidence_and_portable_sha256",
]
BACKEND_ACTIONS = {
    "elilo": [
        "stage_elilo_config_without_oldkernel",
        "validate_active_elilo_entry_and_staged_config",
        "atomically_activate_elilo_config",
        "prove_oldkernel_is_no_longer_referenced",
    ],
    "grub": [
        "generate_grub_config_to_same_directory_temporary_file",
        "validate_staged_grub_config",
        "verify_active_entries_and_absent_rollback_entries",
        "atomically_replace_grub_config",
    ],
}
CONFIRMATION = "authorize-kernel-cleanup-dry-run-only"


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def require_string(value, message):
    require(isinstance(value, str) and value != "", message)
    return value


def require_absolute_path(value, message):
    value = require_string(value, message)
    require(value.startswith("/") and "\x00" not in value, message)
    require(not any(ord(character) < 32 for character in value), message)
    normalized = pathlib.PurePosixPath(value)
    require(str(normalized) == value and ".." not in normalized.parts, message)
    return value


def verify_plan_hash(document):
    supplied = require_string(document.get("plan_sha256"), "cleanup plan SHA-256 is missing")
    require(SAFE_SHA256.fullmatch(supplied) is not None, "cleanup plan SHA-256 is unsafe")
    unhashed = dict(document)
    del unhashed["plan_sha256"]
    canonical = json.dumps(unhashed, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    calculated = hashlib.sha256(canonical).hexdigest()
    require(calculated == supplied, "cleanup plan SHA-256 does not match its content")
    return supplied


def validate_package_set(records, version, field):
    require(isinstance(records, list) and len(records) == 3, f"{field} must contain three records")
    require(len(set(records)) == 3, f"{field} contains duplicate records")
    names = []
    for record in records:
        require(isinstance(record, str), f"{field} contains an unsafe record")
        match = SAFE_PACKAGE.fullmatch(record)
        require(match is not None, f"{field} contains an unsafe record")
        names.append(match.group("name"))
        require(match.group("version") == version, f"{field} does not match its kernel version")
    require(tuple(sorted(names)) == tuple(sorted(EXPECTED_PACKAGE_NAMES)), f"{field} must contain the exact boot-kernel package names")
    return sorted(records)


def validate_archives(archives, active_records):
    require(isinstance(archives, list) and len(archives) == 3, "active archives must contain three entries")
    normalized = []
    seen = set()
    for archive in archives:
        require(isinstance(archive, dict), "active archive entry is invalid")
        record = require_string(archive.get("record"), "active archive record is missing")
        require(record in active_records and record not in seen, "active archive coverage is invalid")
        seen.add(record)
        path = require_absolute_path(archive.get("path"), "active archive path is unsafe")
        sha256 = require_string(archive.get("sha256"), "active archive SHA-256 is missing")
        require(SAFE_SHA256.fullmatch(sha256) is not None, "active archive SHA-256 is unsafe")
        normalized.append({"record": record, "path": path, "sha256": sha256})
    require(seen == set(active_records), "active archives do not cover the active package set")
    return sorted(normalized, key=lambda item: item["record"])


def validate_boot_transaction(document, boot_loader, rollback_kernel):
    transaction = document.get("boot_transaction")
    require(isinstance(transaction, dict), "boot transaction metadata is missing")
    config = require_absolute_path(transaction.get("config"), "boot-loader configuration path is unsafe")
    artifacts = transaction.get("rollback_artifacts")
    require(isinstance(artifacts, list), "rollback artifact inventory is invalid")
    normalized_artifacts = []
    for artifact in artifacts:
        normalized_artifacts.append(require_absolute_path(artifact, "rollback artifact path is unsafe"))
    require(len(normalized_artifacts) == len(set(normalized_artifacts)), "rollback artifact inventory contains duplicates")
    if boot_loader == "elilo":
        active_entry = transaction.get("active_entry")
        rollback_entry = transaction.get("rollback_entry")
        require(isinstance(active_entry, dict) and isinstance(rollback_entry, dict), "ELILO transaction entries are incomplete")
        require(active_entry.get("label") == "vmlinuz", "ELILO active label is unsafe")
        require(rollback_entry.get("label") == "oldkernel", "ELILO rollback label is unsafe")
        require(rollback_entry.get("kernel") == "vmlinuz" and rollback_entry.get("initrd") == "initrd.gz", "ELILO rollback artifacts are unsafe")
        require(len(normalized_artifacts) == 2, "ELILO rollback artifact inventory must contain two files")
    else:
        require(transaction.get("default_flavor") in {"generic", "huge"}, "GRUB default flavor is unsafe")
        require(transaction.get("active_entries_present") is True, "GRUB active entries are missing")
        if rollback_kernel is not None:
            require(transaction.get("rollback_entries_present") is True, "GRUB rollback entries are missing")
        require(normalized_artifacts == [], "GRUB must not schedule unowned rollback artifacts")
    return {**transaction, "config": config, "rollback_artifacts": sorted(normalized_artifacts)}


def validate_authorization(path, plan_sha256, document):
    authorization = json.loads(path.read_text(encoding="utf-8"))
    require(authorization.get("schema") == 1, "unsupported dry-run authorization schema")
    require(authorization.get("scenario") == "kernel-cleanup-dry-run-authorization", "unsupported dry-run authorization scenario")
    identifier = require_string(authorization.get("authorization_id"), "dry-run authorization ID is missing")
    require(SAFE_ID.fullmatch(identifier) is not None, "dry-run authorization ID is unsafe")
    require(authorization.get("scope") == "dry-run-only", "dry-run authorization scope is unsafe")
    require(authorization.get("confirmation") == CONFIRMATION, "dry-run authorization confirmation is invalid")
    require(authorization.get("dry_run_authorized") is True, "dry-run authorization is not granted")
    require(authorization.get("apply_authorized") is False, "dry-run authorization must not grant apply")
    require(authorization.get("plan_sha256") == plan_sha256, "dry-run authorization targets a different plan")
    require(authorization.get("target") == document.get("target"), "dry-run authorization target does not match")
    require(authorization.get("boot_loader") == document.get("boot_loader"), "dry-run authorization boot loader does not match")
    require(authorization.get("active_kernel") == document.get("active_kernel"), "dry-run authorization active kernel does not match")
    require(authorization.get("rollback_kernel") == document.get("rollback_kernel"), "dry-run authorization rollback kernel does not match")
    return identifier


def proposed_commands(action, document, archives, transaction, evidence_root):
    active_kernel = document["active_kernel"]
    rollback_kernel = document.get("rollback_kernel")
    config = transaction["config"]
    config_path = pathlib.PurePosixPath(config)
    if action == "revalidate_inventory_and_running_kernel":
        return [["internal:revalidate-inventory", document["plan_sha256"], active_kernel, rollback_kernel or "none"]]
    if action == "verify_exact_active_package_archives":
        return [["/usr/bin/sha256sum", "--check", f"{evidence_root}/active-packages.sha256"]]
    if action == "archive_package_and_boot_state":
        return [["internal:capture-package-and-boot-state", evidence_root]]
    if action == "remove_exact_rollback_package_records":
        return [["/sbin/removepkg", record] for record in document["rollback_packages"]]
    if action == "reinstall_exact_active_package_set":
        return [["/sbin/upgradepkg", "--reinstall", archive["path"]] for archive in archives]
    if action == "verify_active_package_records_and_module_tree":
        return [["internal:verify-active-packages-and-modules", active_kernel]]
    if action == "stage_elilo_config_without_oldkernel":
        staged = str(config_path.parent / ".elilo.conf.slack-update.dry-run")
        return [["internal:render-elilo-config-without-oldkernel", config, staged]]
    if action == "validate_active_elilo_entry_and_staged_config":
        return [["internal:validate-staged-elilo-config", str(config_path.parent / ".elilo.conf.slack-update.dry-run"), active_kernel]]
    if action == "atomically_activate_elilo_config":
        return [["/bin/mv", "--", str(config_path.parent / ".elilo.conf.slack-update.dry-run"), config]]
    if action == "prove_oldkernel_is_no_longer_referenced":
        return [["internal:prove-elilo-oldkernel-unreferenced", config]]
    if action == "generate_grub_config_to_same_directory_temporary_file":
        staged = str(config_path.parent / ".grub.cfg.slack-update.dry-run")
        return [["/usr/sbin/grub-mkconfig", "-o", staged]]
    if action == "validate_staged_grub_config":
        return [["/usr/bin/grub-script-check", str(config_path.parent / ".grub.cfg.slack-update.dry-run")]]
    if action == "verify_active_entries_and_absent_rollback_entries":
        return [["internal:verify-grub-kernel-entries", str(config_path.parent / ".grub.cfg.slack-update.dry-run"), active_kernel, rollback_kernel]]
    if action == "atomically_replace_grub_config":
        return [["/bin/mv", "--", str(config_path.parent / ".grub.cfg.slack-update.dry-run"), config]]
    if action == "verify_active_boot_chain":
        return [["internal:verify-active-boot-chain", document["boot_loader"], active_kernel]]
    if action == "delete_only_unreferenced_rollback_artifacts":
        return [["/bin/rm", "--", artifact] for artifact in transaction["rollback_artifacts"]]
    if action == "capture_and_compare_final_state":
        return [["internal:capture-and-compare-final-state", evidence_root]]
    if action == "publish_private_evidence_and_portable_sha256":
        return [["internal:publish-private-evidence", evidence_root, "/home/promano"]]
    raise SystemExit(f"unsupported cleanup action: {action}")


def recovery_actions(actions, failed_action, boot_loader):
    if not failed_action:
        return []
    index = actions.index(failed_action)
    removal_index = actions.index("remove_exact_rollback_package_records")
    activation_action = "atomically_activate_elilo_config" if boot_loader == "elilo" else "atomically_replace_grub_config"
    activation_index = actions.index(activation_action)
    deletion_index = actions.index("delete_only_unreferenced_rollback_artifacts")
    if index < removal_index:
        return ["discard_private_dry_run_workspace"]
    recovery = [
        "reinstall_exact_active_package_set_from_verified_archives",
        "restore_archived_package_and_boot_state",
        "revalidate_active_package_records_and_module_tree",
    ]
    if index >= activation_index:
        recovery.extend([
            "atomically_restore_archived_boot_loader_configuration",
            "revalidate_active_boot_chain",
        ])
    if index >= deletion_index:
        recovery.extend([
            "restore_archived_rollback_artifacts",
            "revalidate_rollback_boot_entry_before_retry",
        ])
    return recovery


require(plan.get("schema") == 1, "unsupported cleanup plan schema")
require(plan.get("scenario") == "kernel-cleanup-plan", "unsupported cleanup plan scenario")
plan_sha256 = verify_plan_hash(plan)
require(plan.get("target") in {"slackware-15.0", "slackware-current"}, "unsupported cleanup target")
boot_loader = plan.get("boot_loader")
require(boot_loader in BACKEND_ACTIONS, "unsupported cleanup boot loader")
active_kernel = require_string(plan.get("active_kernel"), "active kernel is missing")
require(SAFE_VERSION.fullmatch(active_kernel) is not None, "active kernel is unsafe")
require(plan.get("running_kernel") == active_kernel, "running kernel does not match active kernel")
rollback_kernel = plan.get("rollback_kernel")
if rollback_kernel is not None:
    require(isinstance(rollback_kernel, str) and SAFE_VERSION.fullmatch(rollback_kernel), "rollback kernel is unsafe")
    require(rollback_kernel != active_kernel, "rollback and active kernels are identical")
require(plan.get("cleanup_authorized") is False, "cleanup plan unexpectedly grants authorization")
require(plan.get("apply_permitted") is False, "cleanup plan unexpectedly permits apply")
require(plan.get("requires_separate_apply_stage") is True, "cleanup plan does not require a separate apply stage")
require(isinstance(plan.get("cleanup_eligible"), bool), "cleanup eligibility is invalid")
transaction = validate_boot_transaction(plan, boot_loader, rollback_kernel)

applicable = plan.get("applicable") is True
if not applicable:
    require(plan.get("status") == "not-applicable", "non-applicable plan status is invalid")
    require(rollback_kernel is None, "non-applicable plan contains a rollback kernel")
    require(plan.get("actions") == [], "non-applicable plan contains actions")
    require(authorization_arg == "", "authorization must not target a non-applicable plan")
    require(failure_action == "", "failure injection requires an applicable plan")
    result = {
        "schema": 1,
        "scenario": "kernel-cleanup-dry-run",
        "mode": "dry-run",
        "status": "not-applicable",
        "plan_sha256": plan_sha256,
        "target": plan["target"],
        "boot_loader": boot_loader,
        "active_kernel": active_kernel,
        "rollback_kernel": None,
        "dry_run_authorized": False,
        "apply_authorized": False,
        "simulation_complete": True,
        "steps": [],
        "recovery_actions": [],
        "commands_executed": [],
        "mutations_performed": [],
        "blocked_reasons": ["no-rollback-kernel-present"],
        "safety_invariants": [
            "no package command was invoked",
            "no boot-loader configuration was modified",
            "no file was deleted",
            "real cleanup apply remains unavailable",
        ],
    }
else:
    require(plan.get("status") == "designed-blocked", "applicable plan status is invalid")
    require(rollback_kernel is not None, "applicable plan has no rollback kernel")
    active_records = validate_package_set(plan.get("active_packages"), active_kernel, "active packages")
    rollback_records = validate_package_set(plan.get("rollback_packages"), rollback_kernel, "rollback packages")
    active_archives = validate_archives(plan.get("active_archives"), active_records)
    expected_actions = COMMON_ACTIONS + BACKEND_ACTIONS[boot_loader] + FINAL_ACTIONS
    require(plan.get("actions") == expected_actions, "cleanup action sequence is invalid")
    blocked_reasons = plan.get("blocked_reasons")
    require(isinstance(blocked_reasons, list), "cleanup blocked reasons are invalid")
    require("cleanup-authorization-not-granted" in blocked_reasons, "cleanup plan lost the authorization blocker")
    if plan["cleanup_eligible"]:
        require("retention-eligibility-not-accepted" not in blocked_reasons, "eligible plan retains the eligibility blocker")
    else:
        require("retention-eligibility-not-accepted" in blocked_reasons, "ineligible plan lost the eligibility blocker")

    authorization_id = None
    if authorization_arg:
        require(plan["cleanup_eligible"] is True, "dry-run authorization cannot target an ineligible plan")
        authorization_id = validate_authorization(pathlib.Path(authorization_arg), plan_sha256, plan)
    if failure_action:
        require(authorization_id is not None, "failure injection requires dry-run authorization")
        require(failure_action in expected_actions, "failure injection action is not in the plan")

    if authorization_id is None:
        result = {
            "schema": 1,
            "scenario": "kernel-cleanup-dry-run",
            "mode": "dry-run",
            "status": "blocked",
            "plan_sha256": plan_sha256,
            "target": plan["target"],
            "boot_loader": boot_loader,
            "active_kernel": active_kernel,
            "rollback_kernel": rollback_kernel,
            "dry_run_authorized": False,
            "apply_authorized": False,
            "simulation_complete": False,
            "steps": [],
            "recovery_actions": [],
            "commands_executed": [],
            "mutations_performed": [],
            "blocked_reasons": (["retention-eligibility-not-accepted"] if not plan["cleanup_eligible"] else []) + ["dry-run-authorization-missing"],
            "safety_invariants": [
                "do not simulate destructive stages without a matching dry-run-only authorization",
                "no package command was invoked",
                "no boot-loader configuration was modified",
                "no file was deleted",
                "real cleanup apply remains unavailable",
            ],
        }
    else:
        evidence_root = f"/var/tmp/slack-update-acceptance/kernel-cleanup-dry-run/{authorization_id}"
        steps = []
        failure_seen = False
        for sequence, action in enumerate(expected_actions, start=1):
            if failure_seen:
                outcome = "not-reached"
            elif action == failure_action:
                outcome = "simulated-failure"
                failure_seen = True
            else:
                outcome = "would-complete"
            steps.append({
                "sequence": sequence,
                "action": action,
                "outcome": outcome,
                "would_execute": proposed_commands(action, plan, active_archives, transaction, evidence_root),
                "executed": False,
                "mutation_performed": False,
            })
        recovery = recovery_actions(expected_actions, failure_action, boot_loader)
        result = {
            "schema": 1,
            "scenario": "kernel-cleanup-dry-run",
            "mode": "dry-run",
            "status": "simulated-failure" if failure_action else "simulation-complete",
            "plan_sha256": plan_sha256,
            "authorization_id": authorization_id,
            "target": plan["target"],
            "boot_loader": boot_loader,
            "active_kernel": active_kernel,
            "rollback_kernel": rollback_kernel,
            "dry_run_authorized": True,
            "apply_authorized": False,
            "simulation_complete": True,
            "failure_injected_at": failure_action or None,
            "private_evidence_root": evidence_root,
            "active_packages": active_records,
            "rollback_packages": rollback_records,
            "active_archives": active_archives,
            "boot_transaction": transaction,
            "steps": steps,
            "recovery_actions": recovery,
            "commands_executed": [],
            "mutations_performed": [],
            "blocked_reasons": ["real-apply-stage-unavailable"],
            "safety_invariants": [
                "all command vectors are data and were not executed",
                "no package command was invoked",
                "no boot-loader configuration was modified",
                "no file was deleted",
                "no evidence directory was created",
                "apply authorization remains false",
                "real cleanup apply remains unavailable",
            ],
        }

canonical_without_hash = json.dumps(result, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
result["result_sha256"] = hashlib.sha256(canonical_without_hash).hexdigest()
rendered = json.dumps(result, sort_keys=True, indent=2, ensure_ascii=True) + "\n"
if output_arg == "-":
    sys.stdout.write(rendered)
else:
    output_path = pathlib.Path(output_arg)
    with output_path.open("x", encoding="utf-8") as stream:
        stream.write(rendered)
PYTHON_EOF
}

main() {
    parse_arguments "$@" || {
        print_usage >&2
        exit 2
    }
    require_regular_input "$PLAN" || {
        error "plan must be a readable regular file and not a symlink"
        exit 3
    }
    if [ -n "$AUTHORIZATION" ]; then
        require_regular_input "$AUTHORIZATION" || {
            error "authorization must be a readable regular file and not a symlink"
            exit 3
        }
    fi
    prepare_output || exit 4
    render_dry_run
}

main "$@"
