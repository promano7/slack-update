#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.sh [--help]

Validate and report the repository-only step-138 regression review for the
GENERIC_KERNEL_LINK direct-generic initialization remediation. This command
performs no source, configuration, package, boot, repository, or machine
mutation.
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
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.tsv"
implementation_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation-policy.json"
implementation_helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json"

expected_source_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_implementation_sha256=685eb5cc28e6d04d96d672a4d51b5856b7ae9fff932949f3baa6f10aab2276d9
expected_implementation_policy_sha256=daa03522c27e48f295f6d403636627e5d94f1e4a631f671c955d96f9a0c2e1de
expected_implementation_helper_sha256=f7b4ab152ab7944ea9e8922a8895ce40bbf362ab8e997c3c75e79d9cdf77d2be

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
    "$source_file|post-remediation reference implementation" \
    "$template|configuration template" \
    "$contract|optional-module contract" \
    "$implementation|step-137 implementation record" \
    "$implementation_policy|step-137 implementation policy" \
    "$implementation_helper|corrected step-137 implementation helper" \
    "$review|step-138 regression-review record" \
    "$policy|step-138 regression-review policy"; do
    require_regular_file "${entry%%|*}" "${entry#*|}"
done

require_sha256 "$source_file" "$expected_source_sha256" "post-remediation reference implementation"
require_sha256 "$template" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "optional-module contract"
require_sha256 "$implementation" "$expected_implementation_sha256" "step-137 implementation record"
require_sha256 "$implementation_policy" "$expected_implementation_policy_sha256" "step-137 implementation policy"
require_sha256 "$implementation_helper" "$expected_implementation_helper_sha256" "corrected step-137 implementation helper"

bash -n "$source_file"
"$implementation_helper" >/dev/null

python3 - "$source_file" <<'PY'
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

source_path = Path(sys.argv[1])
text = source_path.read_text(encoding="utf-8")
assignment = "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic\n"
anchor = "GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot\n"

if text.count(assignment) != 1:
    raise SystemExit("expected exactly one GENERIC_KERNEL_LINK assignment")
if text.count(anchor + assignment) != 1:
    raise SystemExit("GENERIC_KERNEL_LINK does not immediately follow the frozen initialization anchor")
probe_match = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", text, re.S)
classifier_match = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", text, re.S)
if probe_match is None or classifier_match is None:
    raise SystemExit("direct-generic functions are missing")
if text.index(assignment) >= probe_match.start():
    raise SystemExit("GENERIC_KERNEL_LINK initialization does not precede probe definition")
if "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic" in classifier_match.group("body"):
    raise SystemExit("classifier still contains the late GENERIC_KERNEL_LINK assignment")
probe = probe_match.group(0)
if '"$GENERIC_KERNEL_LINK"' not in probe:
    raise SystemExit("probe no longer expands the reviewed GENERIC_KERNEL_LINK argument")

fixture_prefix = r'''#!/bin/bash
set -euo pipefail
GENERIC_KERNEL_LINK=/boot/vmlinuz-generic
PACKAGE_DATABASE=/fixture/packages
BOOT_CMDLINE_FILE=/fixture/cmdline
GRUB_CONFIG=/fixture/grub.cfg
MKINITRD_CONFIG=/fixture/mkinitrd.conf
INITRD_DEFAULT_OUTPUT=/fixture/initrd.gz
KERNEL_MODULES_DIRECTORY=/fixture/modules
RUNNING_KERNEL=6.18.45
CAPTURED_GENERIC_LINK=
classify_direct_generic_boot_layout() {
    CAPTURED_GENERIC_LINK=$4
    [[ "$CAPTURED_GENERIC_LINK" == /boot/vmlinuz-generic ]]
    return 0
}
grub-script-check() { return 0; }
'''
fixture_suffix = r'''
probe_direct_generic_boot_layout
[[ "$BOOT_DIRECT_GENERIC_AVAILABLE" -eq 1 ]]
[[ "$CAPTURED_GENERIC_LINK" == /boot/vmlinuz-generic ]]
printf '%s\n' "$CAPTURED_GENERIC_LINK"
'''

fixture_env = os.environ.copy()
fixture_env["LC_ALL"] = "C"
fixture_env["LANG"] = "C"

with tempfile.TemporaryDirectory() as td:
    good = Path(td) / "good.sh"
    good.write_text(fixture_prefix + probe + fixture_suffix, encoding="utf-8")
    good.chmod(0o700)
    result = subprocess.run([str(good)], text=True, capture_output=True, env=fixture_env)
    if result.returncode != 0:
        raise SystemExit("remediated set -u probe fixture failed: " + result.stderr.strip())
    if result.stdout.strip() != "/boot/vmlinuz-generic":
        raise SystemExit("remediated probe fixture passed an unexpected generic link")

    bad_text = fixture_prefix.replace("GENERIC_KERNEL_LINK=/boot/vmlinuz-generic\n", "", 1) + probe + fixture_suffix
    bad = Path(td) / "historical.sh"
    bad.write_text(bad_text, encoding="utf-8")
    bad.chmod(0o700)
    historical = subprocess.run([str(bad)], text=True, capture_output=True, env=fixture_env)
    if historical.returncode == 0:
        raise SystemExit("historical unset-variable fixture unexpectedly passed")
    if "GENERIC_KERNEL_LINK" not in historical.stderr or "unbound variable" not in historical.stderr:
        raise SystemExit("historical fixture did not fail at the reviewed unset variable")
PY

python3 - "$implementation" "$implementation_policy" "$review" "$policy" <<'PY'
import csv
import json
import sys

implementation_path, implementation_policy_path, review_path, policy_path = sys.argv[1:]
with open(implementation_path, encoding="utf-8", newline="") as handle:
    implementation = list(csv.DictReader(handle, delimiter="\t"))
with open(implementation_policy_path, encoding="utf-8") as handle:
    implementation_policy = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    review = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(implementation) == 1
assert len(review) == 1
impl = implementation[0]
row = review[0]
assert impl["post_edit_source_sha256"] == row["source_sha256"] == policy["source_sha256"]
assert impl["source_change_applied"] == "true"
assert impl["authorization_consumed"] == "true"
assert impl["further_source_change_authorized"] == "false"
assert implementation_policy["post_edit_source_sha256"] == policy["source_sha256"]
assert implementation_policy["authorization_consumed"] is True
assert row["schema"] == "1"
assert row["scenario"] == policy["scenario"]
for key in (
    "exact_delta_revalidated", "source_shell_syntax", "historical_unset_fixture_detected",
    "remediated_probe_fixture_passed", "generic_link_argument_preserved",
    "configuration_template_unchanged", "optional_module_contract_unchanged",
    "authorization_consumed", "pause_safe"):
    assert row[key] == "true"
for key in (
    "further_source_change_authorized", "machine_execution_authorized",
    "slackware_current_rerun_authorized", "slackware_15_execution_released",
    "repository_refresh_required", "machine_action_required"):
    assert row[key] == "false"
assert policy["regression_boundary"]["historical_unset_fixture_must_fail"] is True
assert policy["regression_boundary"]["remediated_probe_fixture_must_pass_under_set_u"] is True
assert policy["source_change_applied"] is True
assert policy["authorization_consumed"] is True
assert policy["further_source_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
assert policy["runtime_machine_validation_still_required"] is True
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["pause_safe"] is True
PY

cat <<'EOF'
schema	1
scenario	phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review
source_sha256	aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
exact_delta_revalidated	true
source_shell_syntax	true
historical_unset_fixture_detected	true
remediated_probe_fixture_passed	true
generic_link_argument_preserved	true
configuration_template_unchanged	true
optional_module_contract_unchanged	true
authorization_consumed	true
further_source_change_authorized	false
machine_execution_authorized	false
slackware_current_rerun_authorized	false
slackware_15_execution_released	false
runtime_machine_validation_still_required	true
repository_refresh_required	false
slackware_repository_state_dependency	false
machine_action_required	false
next_stage	phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review
pause_safe	true
EOF
