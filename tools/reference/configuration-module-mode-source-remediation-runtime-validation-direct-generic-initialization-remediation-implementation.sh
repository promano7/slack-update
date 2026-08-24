#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.sh [--help]

Validate and report the repository-only step-137 implementation of the
GENERIC_KERNEL_LINK direct-generic initialization remediation. The authorized
source relocation must already have been applied by the step-137 overlay. This
command performs validation only and does not modify source, configuration,
packages, boot state, repositories, or machines.
USAGE
}

if (( $# > 1 )); then
    printf 'error: unexpected arguments\n' >&2
    exit 2
fi
if (( $# == 1 )); then
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) printf 'error: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step134_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
step134_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization.tsv"
authorization_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review-policy.json"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-policy.json"

expected_pre_sha256=c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_step134_review_sha256=18380df076d7a264053ffb5aa3bcf85a73cf142feb9adf8adeb64b82b16a3939
expected_step134_policy_sha256=7fd3da927af6223b97f7669defe32530af1aae9028af57da1fb1b4b39464e8c4
expected_design_sha256=92f32e694de60beefea4066a33bd12bdc55ad787e7d24da65ee8fa5f30c62ee2
expected_design_policy_sha256=ea809c4c9e7c1fa46d812d7a778969c9b6b441821a306553e4f6bfff167c2c7b
expected_authorization_sha256=ff601285a6b81e8a7b6a005bdd451f08e499cb3590b61c2ed15647c001b1ebb5
expected_authorization_policy_sha256=c9edf1e77034e469dcfd074e0e8b82e27e3e839503929c9fa1bbf184bb8a13ea

require_regular_file() {
    local path=$1 label=$2
    [[ -f "$path" && ! -L "$path" ]] || {
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    }
}
require_sha256() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ "$actual" == "$expected" ]] || {
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    }
}

for entry in \
    "$source_file|post-edit reference implementation" \
    "$template|configuration template" \
    "$contract|optional-module contract" \
    "$step134_review|step-134 failure-review record" \
    "$step134_policy|step-134 failure-review policy" \
    "$design|step-135 remediation design" \
    "$design_policy|step-135 remediation-design policy" \
    "$authorization|step-136 source authorization" \
    "$authorization_policy|step-136 authorization-review policy" \
    "$implementation|step-137 implementation record" \
    "$policy|step-137 implementation policy"; do
    require_regular_file "${entry%%|*}" "${entry#*|}"
done

require_sha256 "$template" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "optional-module contract"
require_sha256 "$step134_review" "$expected_step134_review_sha256" "step-134 failure-review record"
require_sha256 "$step134_policy" "$expected_step134_policy_sha256" "step-134 failure-review policy"
require_sha256 "$design" "$expected_design_sha256" "step-135 remediation design"
require_sha256 "$design_policy" "$expected_design_policy_sha256" "step-135 remediation-design policy"
require_sha256 "$authorization" "$expected_authorization_sha256" "step-136 source authorization"
require_sha256 "$authorization_policy" "$expected_authorization_policy_sha256" "step-136 authorization-review policy"

post_sha256=$(awk -F '\t' 'NR == 2 {print $7}' "$implementation")
case "$post_sha256" in
    ''|__POST_EDIT_SOURCE_SHA256__|*[!0-9a-f]*)
        printf 'error: invalid recorded post-edit source SHA-256\n' >&2
        exit 1
        ;;
esac
[[ ${#post_sha256} -eq 64 ]] || { printf 'error: invalid recorded post-edit source SHA-256 length\n' >&2; exit 1; }
require_sha256 "$source_file" "$post_sha256" "post-edit reference implementation"

python3 - "$source_file" "$expected_pre_sha256" <<'PY'
import hashlib
import re
import sys

path, expected_pre = sys.argv[1:]
with open(path, "rb") as handle:
    current = handle.read()

anchor = b"GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot\n"
global_assignment = b"GENERIC_KERNEL_LINK=/boot/vmlinuz-generic\n"
classifier_state = b"    BOOT_DIRECT_GENERIC_BOOT_IMAGE=\n"
classifier_assignment = b"    GENERIC_KERNEL_LINK=/boot/vmlinuz-generic\n"

if current.count(anchor) != 1:
    raise SystemExit("post-edit source does not contain exactly one initialization anchor")
if current.count(global_assignment) != 1:
    raise SystemExit("post-edit source does not contain exactly one global GENERIC_KERNEL_LINK assignment")
if current.count(anchor + global_assignment) != 1:
    raise SystemExit("global GENERIC_KERNEL_LINK assignment does not immediately follow the authorized anchor")
if current.count(classifier_assignment) != 0:
    raise SystemExit("classifier still assigns GENERIC_KERNEL_LINK")

text = current.decode("utf-8")
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", text, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", text, re.S)
if classifier is None or probe is None:
    raise SystemExit("direct-generic functions are missing")
if "local generic_link=$4" not in classifier.group("body"):
    raise SystemExit("classifier generic-link argument changed")
if classifier.group("body").count("    BOOT_DIRECT_GENERIC_BOOT_IMAGE=\n") != 1:
    raise SystemExit("classifier-local reconstruction landmark is not unique")
if '"$GENERIC_KERNEL_LINK"' not in probe.group("body"):
    raise SystemExit("probe no longer expands GENERIC_KERNEL_LINK at the reviewed call")
if "classify_direct_generic_boot_layout" not in probe.group("body"):
    raise SystemExit("probe no longer calls the reviewed classifier")
if text.index("GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot") >= text.index("probe_direct_generic_boot_layout() {"):
    raise SystemExit("global initialization no longer precedes probe use")

reconstructed = current.replace(anchor + global_assignment, anchor, 1)
classifier_bytes = re.search(rb"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", reconstructed, re.S)
if classifier_bytes is None:
    raise SystemExit("classifier is missing from reconstructed image")
classifier_body = classifier_bytes.group("body")
if classifier_body.count(classifier_state) != 1:
    raise SystemExit("classifier-local reconstruction landmark is not unique in reconstructed image")
relative_state_offset = classifier_body.index(classifier_state)
insertion_offset = classifier_bytes.start("body") + relative_state_offset + len(classifier_state)
reconstructed = reconstructed[:insertion_offset] + classifier_assignment + reconstructed[insertion_offset:]
actual_pre = hashlib.sha256(reconstructed).hexdigest()
if actual_pre != expected_pre:
    raise SystemExit(f"reconstructed pre-edit SHA-256 mismatch: expected {expected_pre}, got {actual_pre}")
PY

python3 - "$implementation" "$policy" "$post_sha256" <<'PY'
import csv
import json
import sys

implementation_path, policy_path, post_sha256 = sys.argv[1:]
with open(implementation_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
assert row["pre_edit_source_sha256"] == policy["pre_edit_source_sha256"]
assert row["post_edit_source_sha256"] == post_sha256 == policy["post_edit_source_sha256"]
assert row["source_change_applied"] == "true"
assert row["authorization_consumed"] == "true"
assert row["further_source_change_authorized"] == "false"
assert row["machine_execution_authorized"] == "false"
assert policy["source_change_applied"] is True
assert policy["authorization_consumed"] is True
assert policy["further_source_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation\n'
printf 'design_id\tdirect-generic-initialization-remediation\n'
printf 'failure_variable\tGENERIC_KERNEL_LINK\n'
printf 'authorization_scope\tdirect-generic-generic-kernel-link-initialization-only\n'
printf 'authorized_edit\trelocate-existing-assignment-before-first-use\n'
printf 'pre_edit_source_sha256\t%s\n' "$expected_pre_sha256"
printf 'post_edit_source_sha256\t%s\n' "$post_sha256"
printf 'assignment\tGENERIC_KERNEL_LINK=/boot/vmlinuz-generic\n'
printf 'remove_from_function\tclassify_direct_generic_boot_layout\n'
printf 'insert_after_exact_anchor\tGENINITRD_VERSIONED_INITRD_DIRECTORY=/boot\n'
printf 'assignment_count\t1\n'
printf 'assignment_value_preserved\ttrue\n'
printf 'variable_mutability_preserved\ttrue\n'
printf 'function_signature_change\tfalse\n'
printf 'boot_semantics_change\tfalse\n'
printf 'configuration_template_change\tfalse\n'
printf 'contract_change\tfalse\n'
printf 'exact_delta_reconstruction\ttrue\n'
printf 'source_change_applied\ttrue\n'
printf 'authorization_consumed\ttrue\n'
printf 'further_source_change_authorized\tfalse\n'
printf 'machine_execution_authorized\tfalse\n'
printf 'slackware_current_rerun_authorized\tfalse\n'
printf 'slackware_15_execution_released\tfalse\n'
printf 'repository_refresh_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review\n'
printf 'pause_safe\ttrue\n'
