#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-conformance-review.sh [--help]

Review the unchanged reference implementation against the 15-row optional-module
mode contract frozen in step 122. This command is repository-local and read-only.
It reports conformance discrepancies but does not modify source, configuration,
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
template_file="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step122_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract-freeze-policy.json"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"

expected_source_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_step122_policy_sha256=b65d1860d408fec5ff87b509efb87cd95b90c229adaf0203f70db685fdbc847f
expected_review_sha256=8d642b84b9e23c7c88a5af259ec4ff75bc68d57e60f7b87d1baaa7664f40e9e1

require_regular_file() {
    local path=$1
    local label=$2
    if [[ ! -f "$path" || -L "$path" ]]; then
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    fi
}

require_sha256() {
    local path=$1
    local expected=$2
    local label=$3
    local actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

require_literal() {
    local literal=$1
    if ! grep -Fq -- "$literal" "$source_file"; then
        printf 'error: required source conformance landmark is missing: %s\n' "$literal" >&2
        exit 1
    fi
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template_file" "configuration template"
require_regular_file "$contract" "step-122 frozen mode contract"
require_regular_file "$step122_policy" "step-122 freeze policy"
require_regular_file "$review" "step-123 conformance review"
require_sha256 "$source_file" "$expected_source_sha256" "reference implementation"
require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "step-122 frozen mode contract"
require_sha256 "$step122_policy" "$expected_step122_policy_sha256" "step-122 freeze policy"
require_sha256 "$review" "$expected_review_sha256" "step-123 conformance review"

# Generic mode contract landmarks in the accepted source.
require_literal 'validate_module_mode_configuration() {'
require_literal 'enabled|disabled|auto) ;;'
require_literal 'CONFIG_FLATPAK_MODE=auto'
require_literal 'CONFIG_SBO_MODE=auto'
require_literal 'CONFIG_ELF_MODE=auto'
require_literal 'CONFIG_BOOT_MODE=auto'
require_literal 'CONFIG_CINNAMON_MODE=auto'
require_literal 'FLATPAK_MODULE_REASON="disabled by configuration"'
require_literal 'SBO_MODULE_REASON="disabled by configuration"'
require_literal 'ELF_MODULE_REASON="disabled by configuration"'
require_literal 'BOOT_MODULE_REASON="disabled by configuration"'
require_literal 'CINNAMON_MODULE_REASON="disabled by configuration"'
require_literal 'RESULT_ERRORS+=("Flatpak module is enabled but unavailable: $FLATPAK_MODULE_REASON")'
require_literal 'RESULT_ERRORS+=("SBo module is enabled but unavailable: $SBO_MODULE_REASON")'
require_literal 'RESULT_ERRORS+=("ELF module is enabled but unavailable: $ELF_MODULE_REASON")'
require_literal 'RESULT_ERRORS+=("Boot module is enabled but unavailable: $BOOT_MODULE_REASON")'
require_literal 'RESULT_ERRORS+=("Cinnamon module is enabled but unavailable: $CINNAMON_MODULE_REASON")'
require_literal 'if [ "$CINNAMON_TRIGGER" -eq 1 ]; then'

# Boot enabled requires one of the two validated complete layouts.
require_literal 'mkinitrd-managed|direct-generic-no-initrd)'
# The accepted source also has an auto-only partial-layout branch. That branch is
# deliberately recorded as the single conformance discrepancy instead of being
# silently normalized or changed by this review.
require_literal 'BOOT_PREPARATION_LAYOUT=partial'
require_literal 'auto mode detected a partial boot preparation path'

python3 - "$contract" "$step122_policy" "$review" <<'PY'
import csv
import json
import sys

contract_path, policy_path, review_path = sys.argv[1:]
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-contract-freeze"
assert policy["mode_contract_frozen"] is True
assert policy["contract_row_count"] == 15
assert policy["next_stage"] == "phase-1-configuration-module-mode-conformance-review"

with open(contract_path, encoding="utf-8", newline="") as handle:
    contract = list(csv.DictReader(handle, delimiter="\t"))
with open(review_path, encoding="utf-8", newline="") as handle:
    review = list(csv.DictReader(handle, delimiter="\t"))

assert len(contract) == 15
assert len(review) == 15
contract_keys = {(row["module"], row["mode"]) for row in contract}
review_keys = {(row["module"], row["mode"]) for row in review}
assert contract_keys == review_keys
assert sum(row["status"] == "conformant" for row in review) == 14
assert sum(row["status"] == "discrepancy" for row in review) == 1
mismatches = [row for row in review if row["status"] == "discrepancy"]
assert mismatches == [{
    "module": "boot",
    "mode": "auto",
    "status": "discrepancy",
    "observed_behavior": "partial-preparation-layout-may-be-marked-available-and-runnable",
    "discrepancy_id": "boot-auto-partial-path-availability",
}]
boot_auto = next(row for row in contract if row["module"] == "boot" and row["mode"] == "auto")
assert boot_auto["applicability_policy"] == "validated-supported-preparation-path-only"
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-conformance-review\n'
printf 'source_sha256\t%s\n' "$expected_source_sha256"
printf 'template_sha256\t%s\n' "$expected_template_sha256"
printf 'contract_sha256\t%s\n' "$expected_contract_sha256"
printf 'step122_policy_sha256\t%s\n' "$expected_step122_policy_sha256"
printf 'review_sha256\t%s\n' "$expected_review_sha256"
printf 'supported_targets\tslackware-15.0,slackware-current\n'
printf 'contract_rows_reviewed\t15\n'
printf 'conforming_rows\t14\n'
printf 'discrepancy_rows\t1\n'
printf 'all_rows_conform\tfalse\n'
printf 'discrepancy_id\tboot-auto-partial-path-availability\n'
printf 'discrepancy_module\tboot\n'
printf 'discrepancy_mode\tauto\n'
printf 'discrepancy_classification\tpending\n'
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_template_change\tfalse\n'
printf 'source_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-conformance-discrepancy-classification\n'
printf 'pause_safe\ttrue\n'
