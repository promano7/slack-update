#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-schema-inventory.sh [--source PATH] [--template PATH]

Read the current reference implementation and configuration template without
modifying either file. Report CONFIG_* bootstrap initializers, their Phase 1
classification, and the real section/key surface exposed by the template.
USAGE
}

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"

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

for file in "$source_file" "$template_file"; do
    if [[ ! -f "$file" || -L "$file" || ! -r "$file" ]]; then
        echo "ERROR: required input is not a readable regular non-symlink file: $file" >&2
        exit 1
    fi
done

source_sha=$(sha256sum -- "$source_file" | awk '{print $1}')
template_sha=$(sha256sum -- "$template_file" | awk '{print $1}')

classify_variable() {
    case "$1" in
        CONFIG_FILE)
            printf '%s' 'configuration-source'
            ;;
        CONFIG_SCHEMA_VERSION)
            printf '%s' 'schema-control'
            ;;
        CONFIG_FLATPAK_MODE|CONFIG_SBO_MODE|CONFIG_ELF_MODE|CONFIG_BOOT_MODE|CONFIG_CINNAMON_MODE)
            printf '%s' 'deferred-module-mode'
            ;;
        CONFIG_*)
            printf '%s' 'existing-config-surface'
            ;;
        *)
            printf '%s' 'not-config'
            ;;
    esac
}

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-schema-defaults-review\n'
printf 'source\t%s\n' "$source_file"
printf 'source_sha256\t%s\n' "$source_sha"
printf 'template\t%s\n' "$template_file"
printf 'template_sha256\t%s\n' "$template_sha"
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_file_created\tfalse\n'
printf 'existing_configuration_surface\ttrue\n'
printf 'module_mode_migration_deferred\ttrue\n'
printf '%s\n' '---'
printf 'kind\tline\tname\tclassification\tbootstrap_initializer\n'

awk '
    /^[[:space:]]*CONFIG_[A-Z0-9_]+=/ {
        line=$0
        sub(/^[[:space:]]*/, "", line)
        name=line
        sub(/=.*/, "", name)
        if (!(name in seen)) {
            value=line
            sub(/^[^=]*=/, "", value)
            seen[name]=1
            printf "%d\t%s\t%s\n", NR, name, value
        }
    }
' "$source_file" | while IFS=$'\t' read -r line name initializer; do
    classification=$(classify_variable "$name")
    printf 'bootstrap\t%s\t%s\t%s\t%s\n' "$line" "$name" "$classification" "$initializer"
done

printf '%s\n' '---'
printf 'kind\tline\tkey\traw_value\n'
awk '
    BEGIN { section="" }
    {
        raw=$0
        trimmed=$0
        sub(/^[[:space:]]+/, "", trimmed)
        sub(/[[:space:]]+$/, "", trimmed)
        if (trimmed == "" || trimmed ~ /^[#;]/) next
        if (trimmed ~ /^\[[^][]+\]$/) {
            section=trimmed
            sub(/^\[/, "", section)
            sub(/\]$/, "", section)
            next
        }
        if (trimmed ~ /^[A-Za-z0-9_.-]+[[:space:]]*=/) {
            key=trimmed
            sub(/[[:space:]]*=.*/, "", key)
            value=trimmed
            sub(/^[^=]*=/, "", value)
            sub(/^[[:space:]]+/, "", value)
            full=(section == "" ? key : section "." key)
            printf "template-key\t%d\t%s\t%s\n", NR, full, value
        }
    }
' "$template_file"
