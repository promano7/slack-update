#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-implementation.sh"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design.tsv"
step126_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization.tsv"
step127_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization-review-policy.json"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-implementation.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check_regular() {
    local path=$1 label=$2
    if [[ -f "$path" && ! -L "$path" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi
}
check_hash() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi
}
check_output() {
    local key=$1 expected=$2 label=$3 actual
    actual=$(awk -F '\t' -v k="$key" '$1 == k {print $2; exit}' "$output")
    if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label"; fi
}

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$contract" "step-122 frozen mode contract"
check_regular "$design" "step-126 remediation design"
check_regular "$step126_policy" "step-126 remediation-design policy"
check_regular "$authorization" "step-127 source authorization"
check_regular "$step127_policy" "step-127 authorization-review policy"
check_regular "$implementation" "step-128 implementation record"
check_regular "$policy" "step-128 implementation policy"
check_regular "$helper" "step-128 implementation helper"
check_regular "$doc" "step-128 implementation document"

check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "step-122 frozen mode contract"
check_hash "$design" 36dcb8e9d4f91e166c00043f6f8930ecf6c985b49413fa44d4762dce4f81df45 "step-126 remediation design"
check_hash "$step126_policy" 982fffd2d145d9c88b89d2b5f929f19f698ffba4b81e15597a00d33637002e58 "step-126 remediation-design policy"
check_hash "$authorization" 8b2443f3b5f1de52a68cd4f8e4286ed88e071ac50ea99ee36c13905c251bfc08 "step-127 source authorization"
check_hash "$step127_policy" f03d11f7d8bb0f6545e6abfea9ac20a8ae21e8ee2fa8b81a0ccbbd23dfecb98c "step-127 authorization-review policy"

post_sha=$(awk -F '\t' 'NR == 2 {print $7}' "$implementation")
if [[ "$post_sha" =~ ^[0-9a-f]{64}$ ]]; then pass "implementation record contains a concrete post-edit source SHA-256"; else fail "implementation record contains a concrete post-edit source SHA-256"; fi
if [[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$post_sha" ]]; then pass "reference implementation matches the recorded post-edit SHA-256"; else fail "reference implementation matches the recorded post-edit SHA-256"; fi

if bash -n "$source_file"; then pass "post-edit reference implementation is shell-syntax valid"; else fail "post-edit reference implementation is shell-syntax valid"; fi
if bash -n "$helper"; then pass "implementation helper is shell-syntax valid"; else fail "implementation helper is shell-syntax valid"; fi
if "$helper" --help >/dev/null; then pass "implementation helper exposes a non-mutating help boundary"; else fail "implementation helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null; then pass "implementation policy is valid JSON"; else fail "implementation policy is valid JSON"; fi

if python3 - "$implementation" "$policy" "$source_file" <<'PY'
import csv
import hashlib
import json
import sys

implementation_path, policy_path, source_path = sys.argv[1:]
with open(implementation_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
with open(source_path, "rb") as handle:
    actual_post = hashlib.sha256(handle.read()).hexdigest()
assert len(rows) == 1
row = rows[0]
applied = policy["applied_source_change"]
assert row["discrepancy_id"] == applied["discrepancy_id"]
assert row["function"] == applied["function"]
assert row["mode"] == applied["mode"]
assert row["authorization_scope"] == applied["scope"]
assert row["authorized_edit"] == applied["authorized_edit"]
assert row["pre_edit_source_sha256"] == policy["pre_edit_source_sha256"]
assert row["post_edit_source_sha256"] == policy["post_edit_source_sha256"] == actual_post
assert row["source_change_applied"] == "true"
assert row["authorization_consumed"] == "true"
assert row["further_source_change_authorized"] == "false"
assert policy["source_change_applied"] is True
assert policy["authorization_consumed"] is True
assert policy["further_source_change_authorized"] is False
assert policy["runtime_behavior_change"] is True
assert policy["contract_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
PY
then pass "implementation TSV, policy, and source identity are internally consistent"; else fail "implementation TSV, policy, and source identity are internally consistent"; fi

if python3 - "$source_file" <<'PY'
import hashlib
import sys

path = sys.argv[1]
expected = "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6"
with open(path, "rb") as handle:
    current = handle.read()
post_fragment = b'''    elif [ "$BOOT_PREPARATION_LAYOUT" = mkinitrd-managed ] \\\n        || [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ]; then\n        BOOT_MODULE_STATE=available\n        BOOT_MODULE_RUN=1\n    else\n        BOOT_MODULE_STATE=unavailable\n        BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"\n    fi\n'''
removed = b'''    elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then\n        BOOT_MODULE_STATE=available\n        BOOT_MODULE_RUN=1\n        BOOT_PREPARATION_LAYOUT=partial\n        if [ -n "$BOOT_DIRECT_GENERIC_REASON" ]; then\n            BOOT_MODULE_REASON="auto mode detected a partial boot preparation path: $BOOT_DIRECT_GENERIC_REASON"\n        else\n            BOOT_MODULE_REASON="auto mode detected a partial boot preparation path"\n        fi\n'''
pre_fragment = post_fragment.replace(b"    else\n", removed + b"    else\n", 1)
assert current.count(post_fragment) == 1
reconstructed = current.replace(post_fragment, pre_fragment, 1)
assert hashlib.sha256(reconstructed).hexdigest() == expected
PY
then pass "post-edit source reconstructs exactly to the authorized pre-edit SHA-256"; else fail "post-edit source reconstructs exactly to the authorized pre-edit SHA-256"; fi

if grep -Fq 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then' "$source_file" \
    || grep -Fq 'BOOT_PREPARATION_LAYOUT=partial' "$source_file" \
    || grep -Fq 'auto mode detected a partial boot preparation path' "$source_file"; then
    fail "authorized auto-partial branch is completely removed"
else
    pass "authorized auto-partial branch is completely removed"
fi
if grep -Fq 'mkinitrd-managed|direct-generic-no-initrd)' "$source_file" \
    && grep -Fq 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd' "$source_file"; then
    pass "both validated complete-layout landmarks remain present"
else
    fail "both validated complete-layout landmarks remain present"
fi
if grep -Fq 'BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"' "$source_file"; then
    pass "existing fail-closed auto fallback remains present"
else
    fail "existing fail-closed auto fallback remains present"
fi

run_probe_case() {
    local case_name=$1
    bash -s -- "$source_file" "$case_name" <<'BASH'
set -euo pipefail
source_file=$1
case_name=$2
# Sourcing the reference implementation is safe because its main entry point is guarded.
source "$source_file"

tmp=$(mktemp -d)
rm_cmd=$(command -v rm)
cleanup_probe_fixture() { "$rm_cmd" -rf -- "$tmp"; }
trap cleanup_probe_fixture EXIT
mkdir -p "$tmp/bin" "$tmp/grub"
: > "$tmp/mkinitrd.conf"

make_command() {
    local name=$1
    printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/$name"
    chmod 0755 "$tmp/bin/$name"
}

BOOT_MODE=auto
MKINITRD_CONFIG="$tmp/missing-mkinitrd.conf"
GRUB_DIRECTORY="$tmp/missing-grub"
BOOT_DIRECT_GENERIC_REASON=

probe_direct_generic_boot_layout() {
    BOOT_DIRECT_GENERIC_AVAILABLE=0
    BOOT_DIRECT_GENERIC_REASON="direct generic fixture rejected"
    return 1
}

case "$case_name" in
    auto-mkinitrd-managed)
        make_command mkinitrd
        make_command grub-mkconfig
        make_command grub-script-check
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        GRUB_DIRECTORY="$tmp/grub"
        ;;
    auto-direct-generic)
        make_command grub-mkconfig
        make_command grub-script-check
        GRUB_DIRECTORY="$tmp/grub"
        probe_direct_generic_boot_layout() {
            BOOT_DIRECT_GENERIC_AVAILABLE=1
            BOOT_DIRECT_GENERIC_REASON=
            return 0
        }
        ;;
    auto-initrd-only)
        make_command mkinitrd
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        ;;
    auto-grub-only-invalid-direct)
        make_command grub-mkconfig
        make_command grub-script-check
        GRUB_DIRECTORY="$tmp/grub"
        ;;
    auto-none)
        ;;
    enabled-initrd-only)
        BOOT_MODE=enabled
        make_command mkinitrd
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        ;;
    disabled-any-layout)
        BOOT_MODE=disabled
        make_command mkinitrd
        make_command grub-mkconfig
        make_command grub-script-check
        MKINITRD_CONFIG="$tmp/mkinitrd.conf"
        GRUB_DIRECTORY="$tmp/grub"
        ;;
    *)
        printf 'unknown case: %s\n' "$case_name" >&2
        exit 2
        ;;
esac

PATH="$tmp/bin"
probe_boot_module
printf '%s|%s|%s|%s|%s|%s\n' \
    "$BOOT_MODULE_STATE" "$BOOT_MODULE_RUN" "$BOOT_PREPARATION_LAYOUT" \
    "$BOOT_MODULE_REASON" "$BOOT_INITRD_AVAILABLE" "$BOOT_GRUB_AVAILABLE"
BASH
}

expect_probe_case() {
    local case_name=$1 expected=$2 label=$3 actual
    if actual=$(run_probe_case "$case_name") && [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label"
        printf '  expected: %s\n  actual:   %s\n' "$expected" "${actual:-<command failed>}"
    fi
}

expect_probe_case auto-mkinitrd-managed \
    'available|1|mkinitrd-managed||1|1' \
    "auto mode preserves the complete mkinitrd-managed layout"
expect_probe_case auto-direct-generic \
    'available|1|direct-generic-no-initrd||0|1' \
    "auto mode preserves the validated direct-generic-no-initrd layout"
expect_probe_case auto-initrd-only \
    'unavailable|0|unknown|no supported initrd or GRUB preparation path was detected|1|0' \
    "auto mode rejects an initrd-only partial capability set"
expect_probe_case auto-grub-only-invalid-direct \
    'unavailable|0|unknown|no supported initrd or GRUB preparation path was detected|0|1' \
    "auto mode rejects GRUB-only capability without validated direct-generic boot"
expect_probe_case auto-none \
    'unavailable|0|unknown|no supported initrd or GRUB preparation path was detected|0|0' \
    "auto mode remains unavailable when no preparation capability exists"
expect_probe_case enabled-initrd-only \
    'unavailable|0|unknown|GRUB preparation requirements are missing|1|0' \
    "enabled mode preserves strict incomplete-layout semantics"
expect_probe_case disabled-any-layout \
    'disabled|0|unknown|disabled by configuration|0|0' \
    "disabled mode preserves its early non-runnable bypass"

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_contract=$(sha256sum -- "$contract" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$helper" >"$output"; then pass "source remediation implementation validation completed successfully"; else fail "source remediation implementation validation completed successfully"; fi
[[ $(sha256sum -- "$source_file" | awk '{print $1}') == "$before_source" ]] && pass "implementation helper does not further modify the reference implementation" || fail "implementation helper does not further modify the reference implementation"
[[ $(sha256sum -- "$template" | awk '{print $1}') == "$before_template" ]] && pass "implementation helper does not modify the configuration template" || fail "implementation helper does not modify the configuration template"
[[ $(sha256sum -- "$contract" | awk '{print $1}') == "$before_contract" ]] && pass "implementation helper does not modify the frozen mode contract" || fail "implementation helper does not modify the frozen mode contract"

check_output schema 1 "implementation output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-implementation "implementation output records the expected scenario"
check_output discrepancy_id boot-auto-partial-path-availability "implementation remains bound to the exact discrepancy"
check_output target_function probe_boot_module "implementation remains limited to probe_boot_module"
check_output authorized_mode auto "implementation remains limited to auto mode"
check_output authorization_scope boot-auto-partial-applicability-only "implementation preserves the frozen source scope"
check_output authorized_edit remove-auto-partial-availability-branch "implementation consumed only the authorized edit"
check_output pre_edit_source_sha256 0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6 "implementation records the authorized pre-edit source identity"
check_output post_edit_source_sha256 "$post_sha" "implementation reports the recorded post-edit source identity"
check_output source_change_applied true "implementation records the source change as applied"
check_output authorization_consumed true "implementation consumes the step-127 source authorization"
check_output further_source_change_authorized false "no further source change remains authorized"
check_output contract_change_authorized false "contract modification remains unauthorized"
check_output configuration_template_change_authorized false "configuration-template modification remains unauthorized"
check_output capability_probe_change_authorized false "capability-probe modification remains unauthorized"
check_output enabled_semantics_change_authorized false "enabled-mode semantic changes remain unauthorized"
check_output disabled_semantics_change_authorized false "disabled-mode semantic changes remain unauthorized"
check_output runtime_behavior_change true "implementation explicitly records the narrow runtime behavior change"
check_output machine_action_required false "implementation requires no machine action"
check_output slackware_repository_state_dependency false "implementation has no Slackware repository-state dependency"
check_output next_stage phase-1-configuration-module-mode-source-remediation-regression-review "implementation advances only to regression review"
check_output pause_safe true "repository-only implementation boundary remains pause-safe"

if grep -Fq 'reconstructs' "$doc" && grep -Fq 'SHA-256' "$doc" && grep -Fq 'exact' "$doc"; then
    pass "implementation document explains the exact-delta proof"
else
    fail "implementation document explains the exact-delta proof"
fi
if grep -Fq 'authorization_consumed=true' "$doc" && grep -Fq 'further_source_change_authorized=false' "$doc"; then
    pass "implementation document closes the consumed authorization boundary"
else
    fail "implementation document closes the consumed authorization boundary"
fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then
    pass "implementation document preserves both mandatory Slackware targets"
else
    fail "implementation document preserves both mandatory Slackware targets"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "implementation helper contains no package, boot, or shutdown mutation command"
else
    pass "implementation helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync)([[:space:]]|$)' "$helper"; then
    fail "implementation helper contains no network client command"
else
    pass "implementation helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
