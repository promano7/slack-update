#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

INPUT=
OUTPUT=-

print_usage() {
    cat <<'EOF_USAGE'
Usage: kernel-cleanup-plan-reference.sh --input FILE [--output FILE]

Validate a schema-1 kernel cleanup inventory and emit a deterministic,
non-destructive cleanup plan. This command never installs or removes packages,
never edits boot-loader configuration, and never deletes files. Every generated
plan remains blocked until a separate apply stage receives explicit cleanup
authorization.
EOF_USAGE
}

error() {
    printf 'error: %s\n' "$*" >&2
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --input)
                [ "$#" -ge 2 ] || return 1
                INPUT=$2
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

    [ -n "$INPUT" ] || return 1
    [ "$OUTPUT" = - ] || [ -n "$OUTPUT" ] || return 1
}

require_safe_input() {
    [ -f "$INPUT" ] && [ ! -L "$INPUT" ] && [ -r "$INPUT" ]
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

emit_plan() {
    python3 - "$INPUT" "$OUTPUT" <<'PYTHON_EOF'
import hashlib
import json
import pathlib
import re
import sys

input_path = pathlib.Path(sys.argv[1])
output_arg = sys.argv[2]
data = json.loads(input_path.read_text(encoding="utf-8"))

SAFE_VERSION = re.compile(r"^[0-9A-Za-z._+]+$")
SAFE_PACKAGE = re.compile(
    r"^(?P<name>kernel-(?:generic|huge|modules))-(?P<version>[0-9A-Za-z._+]+)-x86_64-(?P<build>[0-9]+)$"
)
SAFE_OTHER_PACKAGE = re.compile(r"^[0-9A-Za-z][0-9A-Za-z+._-]*$")
SAFE_SHA256 = re.compile(r"^[0-9a-f]{64}$")
EXPECTED_PACKAGE_NAMES = ("kernel-generic", "kernel-huge", "kernel-modules")


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


def validate_version(value, field):
    require(isinstance(value, str) and SAFE_VERSION.fullmatch(value), f"unsafe {field}")
    return value


def parse_package_records(records, version, field):
    require(isinstance(records, list), f"{field} must be an array")
    parsed = []
    names = []
    for record in records:
        require(isinstance(record, str), f"{field} contains a non-string record")
        match = SAFE_PACKAGE.fullmatch(record)
        require(match is not None, f"{field} contains an unsafe package record")
        require(match.group("version") == version, f"{field} version does not match the kernel")
        parsed.append(record)
        names.append(match.group("name"))
    require(tuple(sorted(names)) == tuple(sorted(EXPECTED_PACKAGE_NAMES)), f"{field} must contain exactly the three boot-kernel package names")
    require(len(set(records)) == 3, f"{field} contains duplicate records")
    return sorted(parsed)


def validate_archives(archives, active_records):
    require(isinstance(archives, list), "active package archives must be an array")
    normalized = []
    seen = set()
    for archive in archives:
        require(isinstance(archive, dict), "active package archive must be an object")
        record = require_string(archive.get("record"), "active package archive record is missing")
        require(record in active_records, "active package archive does not match an active record")
        require(record not in seen, "active package archive is duplicated")
        seen.add(record)
        path = require_absolute_path(archive.get("path"), "active package archive path is unsafe")
        sha256 = require_string(archive.get("sha256"), "active package archive SHA-256 is missing")
        require(SAFE_SHA256.fullmatch(sha256) is not None, "active package archive SHA-256 is unsafe")
        require(archive.get("available") is True, "active package archive is not available")
        normalized.append({"record": record, "path": path, "sha256": sha256})
    require(seen == set(active_records), "active package archives do not cover the exact active package set")
    return sorted(normalized, key=lambda item: item["record"])


require(data.get("schema") == 1, "unsupported cleanup inventory schema")
require(data.get("target") in {"slackware-15.0", "slackware-current"}, "unsupported cleanup target")
require(isinstance(data.get("cleanup_eligible"), bool), "cleanup eligibility must be boolean")
require(data.get("cleanup_authorized") is False, "cleanup inventory must remain unauthorized")
boot_loader = data.get("boot_loader")
require(boot_loader in {"elilo", "grub"}, "unsupported boot loader")
require(data.get("firmware") in {"uefi", "bios"}, "unsupported firmware mode")

running_kernel = validate_version(data.get("running_kernel"), "running kernel")
active_kernel = validate_version(data.get("active_kernel"), "active kernel")
require(running_kernel == active_kernel, "the running kernel is not the active kernel")
rollback_value = data.get("rollback_kernel")
rollback_kernel = None if rollback_value is None else validate_version(rollback_value, "rollback kernel")
require(rollback_kernel != active_kernel, "active and rollback kernels must be distinct")

package_database = data.get("package_database")
require(isinstance(package_database, dict), "package database metadata is missing")
configured_database = require_absolute_path(package_database.get("configured"), "configured package database path is unsafe")
resolved_database = require_absolute_path(package_database.get("resolved"), "resolved package database path is unsafe")
require(package_database.get("resolved_is_directory") is True, "resolved package database is not a directory")
require(package_database.get("internal_record_symlinks") is False, "package database contains record symlinks")

packages = data.get("packages")
require(isinstance(packages, dict), "package inventory is missing")
active_records = parse_package_records(packages.get("active"), active_kernel, "active packages")
other_kernel_packages = packages.get("other_kernel_packages", [])
require(isinstance(other_kernel_packages, list), "other kernel packages are invalid")
require(all(isinstance(value, str) and SAFE_OTHER_PACKAGE.fullmatch(value) for value in other_kernel_packages), "other kernel packages are invalid")
require(len(other_kernel_packages) == len(set(other_kernel_packages)), "other kernel packages contain duplicates")

module_trees = data.get("module_trees")
require(isinstance(module_trees, dict), "module tree inventory is missing")
require(module_trees.get("active") is True, "active module tree is missing")

boot = data.get("boot")
require(isinstance(boot, dict), "boot inventory is missing")

base = {
    "schema": 1,
    "scenario": "kernel-cleanup-plan",
    "target": data["target"],
    "source_inventory": data.get("inventory_id", input_path.name),
    "boot_loader": boot_loader,
    "firmware": data["firmware"],
    "running_kernel": running_kernel,
    "active_kernel": active_kernel,
    "rollback_kernel": rollback_kernel,
    "package_database": {
        "configured": configured_database,
        "resolved": resolved_database,
    },
    "cleanup_eligible": bool(data.get("cleanup_eligible") is True),
    "cleanup_authorized": False,
    "apply_permitted": False,
    "requires_separate_apply_stage": True,
}

if rollback_kernel is None:
    require(packages.get("rollback") in ([], None), "rollback packages exist without a rollback kernel")
    require(module_trees.get("rollback") in (False, None), "rollback module tree exists without a rollback kernel")
    if boot_loader == "grub":
        grub_config = require_absolute_path(boot.get("config"), "GRUB configuration path is unsafe")
        require(boot.get("active_entries_present") is True, "active GRUB entries are missing")
        require(boot.get("rollback_entries_present") is False, "rollback GRUB entries exist without a rollback kernel")
        default_flavor = boot.get("default_flavor")
        require(default_flavor in {"generic", "huge"}, "unsupported GRUB default kernel flavor")
        boot_transaction = {
            "config": grub_config,
            "default_flavor": default_flavor,
            "active_entries_present": True,
            "rollback_entries_present": False,
            "rollback_artifacts": [],
        }
    else:
        raise SystemExit("ELILO cleanup inventory requires a rollback kernel")
    plan = {
        **base,
        "applicable": False,
        "status": "not-applicable",
        "blocked_reasons": ["no-rollback-kernel-present"],
        "active_packages": active_records,
        "rollback_packages": [],
        "active_archives": [],
        "boot_transaction": boot_transaction,
        "actions": [],
        "safety_invariants": [
            "leave the active package set unchanged",
            "leave boot-loader configuration unchanged",
            "do not create a cleanup authorization",
        ],
    }
else:
    rollback_records = parse_package_records(packages.get("rollback"), rollback_kernel, "rollback packages")
    require(module_trees.get("rollback") is True, "rollback module tree is missing")
    active_archives = validate_archives(data.get("active_archives"), active_records)

    blocked_reasons = []
    if data.get("cleanup_eligible") is not True:
        blocked_reasons.append("retention-eligibility-not-accepted")
    blocked_reasons.append("cleanup-authorization-not-granted")

    common_actions = [
        "revalidate_inventory_and_running_kernel",
        "verify_exact_active_package_archives",
        "archive_package_and_boot_state",
        "remove_exact_rollback_package_records",
        "reinstall_exact_active_package_set",
        "verify_active_package_records_and_module_tree",
    ]
    final_actions = [
        "verify_active_boot_chain",
        "delete_only_unreferenced_rollback_artifacts",
        "capture_and_compare_final_state",
        "publish_private_evidence_and_portable_sha256",
    ]

    if boot_loader == "elilo":
        require(data.get("firmware") == "uefi", "ELILO cleanup requires UEFI")
        elilo_config = require_absolute_path(boot.get("config"), "ELILO configuration path is unsafe")
        active_entry = boot.get("active_entry")
        rollback_entry = boot.get("rollback_entry")
        require(isinstance(active_entry, dict) and isinstance(rollback_entry, dict), "ELILO entries are incomplete")
        require(active_entry.get("label") == "vmlinuz", "unexpected active ELILO label")
        require(active_entry.get("kernel") == f"vmlinuz-generic-{active_kernel}", "active ELILO kernel is not versioned")
        require(active_entry.get("initrd") == f"initrd-generic-{active_kernel}.gz", "active ELILO initrd is not versioned")
        require(rollback_entry.get("label") == "oldkernel", "ELILO rollback label is missing")
        require(rollback_entry.get("kernel") == "vmlinuz", "unexpected ELILO rollback kernel")
        require(rollback_entry.get("initrd") == "initrd.gz", "unexpected ELILO rollback initrd")
        elilo_directory = str(pathlib.PurePosixPath(elilo_config).parent)
        boot_transaction = {
            "config": elilo_config,
            "active_entry": {
                "label": active_entry["label"],
                "kernel": active_entry["kernel"],
                "initrd": active_entry["initrd"],
            },
            "rollback_entry": {
                "label": rollback_entry["label"],
                "kernel": rollback_entry["kernel"],
                "initrd": rollback_entry["initrd"],
            },
            "rollback_artifacts": sorted([
                f"{elilo_directory}/{rollback_entry['kernel']}",
                f"{elilo_directory}/{rollback_entry['initrd']}",
            ]),
        }
        backend_actions = [
            "stage_elilo_config_without_oldkernel",
            "validate_active_elilo_entry_and_staged_config",
            "atomically_activate_elilo_config",
            "prove_oldkernel_is_no_longer_referenced",
        ]
        backend_invariants = [
            "never modify the active ELILO configuration in place",
            "retain rollback EFI files until oldkernel removal is atomically active",
            "keep the versioned active kernel and initrd byte-identical across boot and EFI",
        ]
    else:
        grub_config = require_absolute_path(boot.get("config"), "GRUB configuration path is unsafe")
        require(boot.get("generator_available") is True, "grub-mkconfig is unavailable")
        require(boot.get("validator_available") is True, "grub-script-check is unavailable")
        require(boot.get("active_entries_present") is True, "active GRUB entries are missing")
        require(boot.get("rollback_entries_present") is True, "rollback GRUB entries are missing")
        default_flavor = boot.get("default_flavor")
        require(default_flavor in {"generic", "huge"}, "unsupported GRUB default kernel flavor")
        boot_transaction = {
            "config": grub_config,
            "default_flavor": default_flavor,
            "active_entries_present": True,
            "rollback_entries_present": True,
            "rollback_artifacts": [],
        }
        backend_actions = [
            "generate_grub_config_to_same_directory_temporary_file",
            "validate_staged_grub_config",
            "verify_active_entries_and_absent_rollback_entries",
            "atomically_replace_grub_config",
        ]
        backend_invariants = [
            "never hand-edit the active GRUB configuration",
            "never write grub-mkconfig output directly to the active path",
            "preserve the active GRUB configuration on generation validation or replacement failure",
        ]

    plan = {
        **base,
        "applicable": True,
        "status": "designed-blocked",
        "blocked_reasons": blocked_reasons,
        "active_packages": active_records,
        "rollback_packages": rollback_records,
        "active_archives": active_archives,
        "other_kernel_packages_preserved": sorted(other_kernel_packages),
        "boot_transaction": boot_transaction,
        "actions": common_actions + backend_actions + final_actions,
        "safety_invariants": [
            "abort unless the running kernel remains the accepted active kernel",
            "remove only the exact rollback package records",
            "reinstall the exact active package set before boot-loader rollback removal",
            "preserve kernel headers source and firmware packages",
            "delete rollback files only after proving they are unreferenced",
            "keep cleanup authorization separate from planning and eligibility",
        ] + backend_invariants,
    }

canonical_without_hash = json.dumps(plan, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
plan["plan_sha256"] = hashlib.sha256(canonical_without_hash).hexdigest()
rendered = json.dumps(plan, sort_keys=True, indent=2, ensure_ascii=True) + "\n"

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
    require_safe_input || {
        error "input must be a readable regular file and not a symlink"
        exit 3
    }
    prepare_output || exit 4
    emit_plan
}

main "$@"
