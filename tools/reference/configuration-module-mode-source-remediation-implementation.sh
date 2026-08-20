#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-implementation.sh [--help]

Validate and report the repository-only step-128 source remediation state.
The authorized source change must already have been applied by the step-128
overlay. This command performs validation only and does not modify source,
configuration, packages, boot state, repositories, or machines.
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
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization.tsv"
step127_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization-review-policy.json"
implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation-policy.json"

expected_pre_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_authorization_sha256=8b2443f3b5f1de52a68cd4f8e4286ed88e071ac50ea99ee36c13905c251bfc08
expected_step127_policy_sha256=f03d11f7d8bb0f6545e6abfea9ac20a8ae21e8ee2fa8b81a0ccbbd23dfecb98c

require_regular_file() {
    local path=$1 label=$2
    if [[ ! -f "$path" || -L "$path" ]]; then
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    fi
}

require_sha256() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

for entry in \
    "$source_file|reference implementation" \
    "$template_file|configuration template" \
    "$contract|step-122 frozen mode contract" \
    "$authorization|step-127 source authorization" \
    "$step127_policy|step-127 authorization-review policy" \
    "$implementation|step-128 implementation record" \
    "$policy|step-128 implementation policy"; do
    require_regular_file "${entry%%|*}" "${entry#*|}"
done

require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "step-122 frozen mode contract"
require_sha256 "$authorization" "$expected_authorization_sha256" "step-127 source authorization"
require_sha256 "$step127_policy" "$expected_step127_policy_sha256" "step-127 authorization-review policy"

post_sha256=$(awk -F '\t' 'NR == 2 {print $7}' "$implementation")
case "$post_sha256" in
    ''|__POST_EDIT_SOURCE_SHA256__|*[!0-9a-f]*)
        printf 'error: invalid recorded post-edit source SHA-256\n' >&2
        exit 1
        ;;
esac
[[ ${#post_sha256} -eq 64 ]] || { printf 'error: invalid recorded post-edit source SHA-256 length\n' >&2; exit 1; }
require_sha256 "$source_file" "$post_sha256" "post-edit reference implementation"

if grep -Fq 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then' "$source_file" \
    || grep -Fq 'BOOT_PREPARATION_LAYOUT=partial' "$source_file" \
    || grep -Fq 'auto mode detected a partial boot preparation path' "$source_file"; then
    printf 'error: removed auto-partial branch is still present\n' >&2
    exit 1
fi

grep -Fq 'mkinitrd-managed|direct-generic-no-initrd)' "$source_file" || { printf 'error: complete-layout case landmark is missing\n' >&2; exit 1; }
grep -Fq 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd' "$source_file" || { printf 'error: direct-generic layout landmark is missing\n' >&2; exit 1; }
grep -Fq 'BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"' "$source_file" || { printf 'error: fail-closed fallback landmark is missing\n' >&2; exit 1; }

python3 - "$source_file" "$expected_pre_sha256" <<'PY'
import hashlib
import sys

path, expected = sys.argv[1:]
with open(path, "rb") as handle:
    current = handle.read()

post_fragment = b'''    elif [ "$BOOT_PREPARATION_LAYOUT" = mkinitrd-managed ] \\\n        || [ "$BOOT_PREPARATION_LAYOUT" = direct-generic-no-initrd ]; then\n        BOOT_MODULE_STATE=available\n        BOOT_MODULE_RUN=1\n    else\n        BOOT_MODULE_STATE=unavailable\n        BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"\n    fi\n'''
removed = b'''    elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then\n        BOOT_MODULE_STATE=available\n        BOOT_MODULE_RUN=1\n        BOOT_PREPARATION_LAYOUT=partial\n        if [ -n "$BOOT_DIRECT_GENERIC_REASON" ]; then\n            BOOT_MODULE_REASON="auto mode detected a partial boot preparation path: $BOOT_DIRECT_GENERIC_REASON"\n        else\n            BOOT_MODULE_REASON="auto mode detected a partial boot preparation path"\n        fi\n'''
pre_fragment = post_fragment.replace(b"    else\n", removed + b"    else\n", 1)
if current.count(post_fragment) != 1:
    raise SystemExit("post-edit source does not contain the single expected remediation landmark")
reconstructed = current.replace(post_fragment, pre_fragment, 1)
actual = hashlib.sha256(reconstructed).hexdigest()
if actual != expected:
    raise SystemExit(f"reconstructed pre-edit SHA-256 mismatch: expected {expected}, got {actual}")
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-implementation\n'
printf 'discrepancy_id\tboot-auto-partial-path-availability\n'
printf 'target_function\tprobe_boot_module\n'
printf 'authorized_mode\tauto\n'
printf 'authorization_scope\tboot-auto-partial-applicability-only\n'
printf 'authorized_edit\tremove-auto-partial-availability-branch\n'
printf 'pre_edit_source_sha256\t%s\n' "$expected_pre_sha256"
printf 'post_edit_source_sha256\t%s\n' "$post_sha256"
printf 'source_change_applied\ttrue\n'
printf 'authorization_consumed\ttrue\n'
printf 'further_source_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'configuration_template_change_authorized\tfalse\n'
printf 'capability_probe_change_authorized\tfalse\n'
printf 'enabled_semantics_change_authorized\tfalse\n'
printf 'disabled_semantics_change_authorized\tfalse\n'
printf 'runtime_behavior_change\ttrue\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-regression-review\n'
printf 'pause_safe\ttrue\n'
