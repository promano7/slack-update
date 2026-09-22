#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh [--repo-root DIR|auto] [--expected-fqdn NAME] [--help]

Perform the step-181 read-only target-binding observation. The probe reads
machine identity and capability state, hashes the existing reference script
and effective configuration, and performs only an ephemeral `unshare --net`
capability check that runs `true`. It does not refresh repositories, contact
external networks, modify packages, change boot state, restart the system, or alter configuration.
USAGE
}

repo_root=auto
expected_fqdn='vbox-slackcurrent.vbox-slackcurrent.org'
while (($#)); do
    case "$1" in
        --repo-root)
            [[ $# -ge 2 ]] || { printf 'ERROR: --repo-root requires a value\n' >&2; exit 2; }
            repo_root=$2
            shift 2
            ;;
        --expected-fqdn)
            [[ $# -ge 2 ]] || { printf 'ERROR: --expected-fqdn requires a value\n' >&2; exit 2; }
            expected_fqdn=$2
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'ERROR: run this read-only probe through sudo/root\n' >&2; exit 3; }

if [[ $repo_root == auto ]]; then
    found=()
    for candidate in /home/promano/GitHub/slack-update /home/promano/Descargas/slack-update-main; do
        if [[ -f $candidate/tools/reference/slack-update-reference.sh && -f $candidate/data/config/slack-update.conf ]]; then
            found+=("$candidate")
        fi
    done
    if ((${#found[@]} != 1)); then
        printf 'ERROR: auto repo discovery found %d valid candidates; pass --repo-root explicitly\n' "${#found[@]}" >&2
        if ((${#found[@]})); then printf 'candidate\t%s\n' "${found[@]}" >&2; else printf 'candidate\tnone\n' >&2; fi
        exit 4
    fi
    repo_root=${found[0]}
fi
repo_root=$(CDPATH= cd -- "$repo_root" && pwd -P)

reference_script="$repo_root/tools/reference/slack-update-reference.sh"
effective_config="$repo_root/data/config/slack-update.conf"
[[ -f $reference_script && ! -L $reference_script ]] || { printf 'ERROR: reference script missing or unsafe: %s\n' "$reference_script" >&2; exit 5; }
[[ -f $effective_config && ! -L $effective_config ]] || { printf 'ERROR: effective config missing or unsafe: %s\n' "$effective_config" >&2; exit 5; }

hostname_short=$(hostname)
hostname_fqdn=$(hostname -f)
[[ $hostname_fqdn == "$expected_fqdn" ]] || {
    printf 'ERROR: FQDN mismatch\nexpected: %s\nactual:   %s\n' "$expected_fqdn" "$hostname_fqdn" >&2
    exit 6
}
uname_release=$(uname -r)
slackware_version=$(cat /etc/slackware-version)
boot_id=$(cat /proc/sys/kernel/random/boot_id)
reference_sha=$(sha256sum -- "$reference_script" | awk '{print $1}')
config_sha=$(sha256sum -- "$effective_config" | awk '{print $1}')
probe_sha=$(sha256sum -- "${BASH_SOURCE[0]}" | awk '{print $1}')

missing=()
for cmd in bash python3 sha256sum tar flock unshare kill ps crontab; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
    printf 'ERROR: required command(s) missing: %s\n' "${missing[*]}" >&2
    exit 7
fi
if ! ps -eo comm= | awk '$1 == "crond" { found=1 } END { exit(found ? 0 : 1) }'; then
    printf 'ERROR: crond is not running\n' >&2
    exit 8
fi
crontab_rc=0
crontab -l >/dev/null 2>&1 || crontab_rc=$?
if [[ $crontab_rc -ne 0 && $crontab_rc -ne 1 ]]; then
    printf 'ERROR: root crontab read-only check returned %d\n' "$crontab_rc" >&2
    exit 9
fi
if ! unshare --net -- true; then
    printf 'ERROR: ephemeral network namespace capability check failed\n' >&2
    exit 10
fi

printf 'binding_status\tPASS\n'
printf 'hostname\t%s\n' "$hostname_short"
printf 'hostname-fqdn\t%s\n' "$hostname_fqdn"
printf 'uname-release\t%s\n' "$uname_release"
printf 'slackware-version\t%s\n' "$slackware_version"
printf 'boot-id\t%s\n' "$boot_id"
printf 'repo-root\t%s\n' "$repo_root"
printf 'reference-script-sha256\t%s\n' "$reference_sha"
printf 'effective-config-sha256\t%s\n' "$config_sha"
printf 'probe-sha256\t%s\n' "$probe_sha"
printf 'capability-bash\tPASS\n'
printf 'capability-python3\tPASS\n'
printf 'capability-sha256sum\tPASS\n'
printf 'capability-tar\tPASS\n'
printf 'capability-flock\tPASS\n'
printf 'capability-unshare-network-namespace\tPASS\n'
printf 'capability-kill\tPASS\n'
printf 'capability-ps\tPASS\n'
printf 'capability-crontab\tPASS\n'
printf 'capability-running-crond\tPASS\n'
printf 'root-crontab-read-only-check\tPASS\n'
printf 'repository-refresh-performed\tno\n'
printf 'external-network-access-performed\tno\n'
printf 'package-mutation-performed\tno\n'
printf 'boot-mutation-performed\tno\n'
printf 'system-restart-performed\tno\n'
printf 'persistent-configuration-change-performed\tno\n'
