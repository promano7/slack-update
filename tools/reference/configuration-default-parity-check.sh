#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-default-parity-check.sh [--source PATH] [--template PATH] [--contract PATH]

Compare the reviewed CONFIG_* bootstrap surface with the configuration template
and the frozen Phase 1 default-parity contract. This command is read-only.
USAGE
}

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
contract_file="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-contract.tsv"
inventory="$repo_root/tools/reference/configuration-schema-inventory.sh"

while (($#)); do
    case "$1" in
        --source)
            (($# >= 2)) || { echo "ERROR: --source requires a path" >&2; exit 2; }
            source_file=$2
            shift 2
            ;;
        --template)
            (($# >= 2)) || { echo "ERROR: --template requires a path" >&2; exit 2; }
            template_file=$2
            shift 2
            ;;
        --contract)
            (($# >= 2)) || { echo "ERROR: --contract requires a path" >&2; exit 2; }
            contract_file=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            exit 2
            ;;
    esac
done

for file in "$source_file" "$template_file" "$contract_file" "$inventory"; do
    if [[ ! -f "$file" || -L "$file" || ! -r "$file" ]]; then
        echo "ERROR: required input is not a readable regular non-symlink file: $file" >&2
        exit 1
    fi
done

inventory_out=$(mktemp)
trap 'rm -f -- "$inventory_out"' EXIT
"$inventory" --source "$source_file" --template "$template_file" >"$inventory_out"

contract_rows=$(awk -F '\t' 'NR>1 && NF>=5 {n++} END {print n+0}' "$contract_file")
[[ "$contract_rows" -eq 34 ]] || { echo "ERROR: parity contract must contain exactly 34 rows" >&2; exit 1; }

contract_variables=$(awk -F '\t' 'NR>1 {print $1}' "$contract_file" | LC_ALL=C sort)
contract_keys=$(awk -F '\t' 'NR>1 {print $2}' "$contract_file" | LC_ALL=C sort)
[[ $(printf '%s\n' "$contract_variables" | uniq | wc -l) -eq 34 ]] || { echo "ERROR: parity contract contains duplicate variables" >&2; exit 1; }
[[ $(printf '%s\n' "$contract_keys" | uniq | wc -l) -eq 34 ]] || { echo "ERROR: parity contract contains duplicate keys" >&2; exit 1; }

observed_template_keys=$(awk -F '\t' '$1=="template-key" {print $3}' "$inventory_out" | LC_ALL=C sort)
if [[ "$contract_keys" != "$observed_template_keys" ]]; then
    echo "ERROR: configuration template keys differ from the frozen parity contract" >&2
    exit 1
fi

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-default-parity-freeze\n'
printf 'source_sha256\t%s\n' "$(sha256sum -- "$source_file" | awk '{print $1}')"
printf 'template_sha256\t%s\n' "$(sha256sum -- "$template_file" | awk '{print $1}')"
printf 'contract_sha256\t%s\n' "$(sha256sum -- "$contract_file" | awk '{print $1}')"
printf 'runtime_behavior_change\tfalse\n'
printf 'default_parity_frozen\ttrue\n'
printf 'module_mode_migration_deferred\ttrue\n'
printf '%s\n' '---'
printf 'kind\tvariable\tkey\tclassification\tbootstrap_initializer\ttemplate_value\n'

parity_rows=0
deferred_rows=0
bootstrap_overlap_rows=0

while IFS=$'\t' read -r variable key classification expected_bootstrap expected_template; do
    [[ "$variable" == "variable" ]] && continue

    observed_bootstrap=$(awk -F '\t' -v n="$variable" '$1=="bootstrap" && $3==n {print $5; found=1; exit} END {if (!found) exit 1}' "$inventory_out") || {
        echo "ERROR: CONFIG_* variable missing from reviewed bootstrap surface: $variable" >&2
        exit 1
    }
    observed_classification=$(awk -F '\t' -v n="$variable" '$1=="bootstrap" && $3==n {print $4; found=1; exit} END {if (!found) exit 1}' "$inventory_out") || exit 1
    observed_template=$(awk -F '\t' -v k="$key" '$1=="template-key" && $3==k {print $4; found=1; exit} END {if (!found) exit 1}' "$inventory_out") || {
        echo "ERROR: template key missing from reviewed configuration template: $key" >&2
        exit 1
    }

    normalized_bootstrap=$observed_bootstrap
    [[ -n "$normalized_bootstrap" ]] || normalized_bootstrap='<empty>'

    [[ "$observed_classification" == "$classification" ]] || {
        echo "ERROR: classification drift for $variable" >&2
        exit 1
    }
    [[ "$normalized_bootstrap" == "$expected_bootstrap" ]] || {
        echo "ERROR: bootstrap initializer drift for $variable" >&2
        exit 1
    }
    [[ "$observed_template" == "$expected_template" ]] || {
        echo "ERROR: template default drift for $key" >&2
        exit 1
    }

    if [[ "$expected_bootstrap" != '<empty>' ]]; then
        bootstrap_overlap_rows=$((bootstrap_overlap_rows + 1))
        [[ "$expected_bootstrap" == "$expected_template" ]] || {
            echo "ERROR: duplicated bootstrap/template default is inconsistent for $variable" >&2
            exit 1
        }
    fi

    if [[ "$classification" == 'deferred-module-mode' ]]; then
        deferred_rows=$((deferred_rows + 1))
    fi

    parity_rows=$((parity_rows + 1))
    printf 'parity\t%s\t%s\t%s\t%s\t%s\n' \
        "$variable" "$key" "$classification" "$expected_bootstrap" "$expected_template"
done < "$contract_file"

[[ "$parity_rows" -eq 34 ]] || { echo "ERROR: parity validation did not cover 34 rows" >&2; exit 1; }
[[ "$deferred_rows" -eq 5 ]] || { echo "ERROR: parity contract must keep exactly five module modes deferred" >&2; exit 1; }
[[ "$bootstrap_overlap_rows" -eq 8 ]] || { echo "ERROR: expected exactly eight bootstrap/template default overlaps" >&2; exit 1; }

printf '%s\n' '---'
printf 'parity_rows\t%d\n' "$parity_rows"
printf 'deferred_module_mode_rows\t%d\n' "$deferred_rows"
printf 'bootstrap_template_overlap_rows\t%d\n' "$bootstrap_overlap_rows"
printf 'configuration_source_variable\tCONFIG_FILE\n'
printf 'configuration_source_is_not_template_key\ttrue\n'
printf 'parity_status\taccepted\n'
