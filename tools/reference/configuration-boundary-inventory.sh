#!/bin/bash
# Inventory hardcoded configuration candidates in the reference engine.
# This tool is intentionally read-only: it emits a deterministic report to stdout.

set -eu

usage() {
    cat <<'USAGE'
Usage: configuration-boundary-inventory.sh [--source PATH]

Inventory hardcoded configuration candidates in the Slack-Update reference engine.
The report is deterministic for a given source file and is written to stdout only.
USAGE
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
SOURCE="$REPO_ROOT/tools/reference/slack-update-reference.sh"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --source)
            [ "$#" -ge 2 ] || { echo "ERROR: --source requires a path" >&2; exit 2; }
            SOURCE=$2
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            exit 2
            ;;
    esac
done

[ -f "$SOURCE" ] || { echo "ERROR: source is not a regular file: $SOURCE" >&2; exit 1; }
[ ! -L "$SOURCE" ] || { echo "ERROR: source must not be a symlink: $SOURCE" >&2; exit 1; }

SOURCE_SHA256=$(sha256sum "$SOURCE" | awk '{print $1}')

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-boundary-review\n'
printf 'source\t%s\n' "$SOURCE"
printf 'source_sha256\t%s\n' "$SOURCE_SHA256"
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_file_created\tfalse\n'
printf 'module_mode_migration_deferred\ttrue\n'
printf '%s\n' '---'
printf 'kind\tline\ttext\n'

# Candidate 1: top-level-looking uppercase assignments. These are review candidates,
# not automatic user-facing configuration keys.
awk '
{
    line=$0
    if (line ~ /^[[:space:]]*[A-Z][A-Z0-9_]*[[:space:]]*=/) {
        gsub(/\t/, " ", line)
        printf "assignment\t%d\t%s\n", NR, line
    }
}
' "$SOURCE"

# Candidate 2: literal system paths. Keep the complete source line so later review
# can distinguish policy paths from safety invariants and transient workspace paths.
awk '
{
    line=$0
    if (line ~ /\/(etc|var|boot|usr|run|tmp)\//) {
        gsub(/\t/, " ", line)
        printf "absolute-path\t%d\t%s\n", NR, line
    }
}
' "$SOURCE"

# Candidate 3: external commands whose names may represent policy or environment
# assumptions. Command discovery is evidence only; it does not imply configurability.
awk '
BEGIN {
    pattern="(^|[[:space:];|&()])(slackpkg|installpkg|upgradepkg|removepkg|grub-mkconfig|grub-install|eliloconfig|mkinitrd|depmod|modprobe|lilo|elilo)([[:space:];|&()<>]|$)"
}
{
    line=$0
    if (line ~ pattern) {
        gsub(/\t/, " ", line)
        printf "external-command\t%d\t%s\n", NR, line
    }
}
' "$SOURCE"
