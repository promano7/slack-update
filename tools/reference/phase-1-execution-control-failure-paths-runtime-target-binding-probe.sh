#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly FROZEN_REFERENCE_SCRIPT_SHA256='086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
readonly FROZEN_EFFECTIVE_CONFIG_SHA256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh [--expected-fqdn NAME] [--help]

Perform the step-181-r1 standalone read-only target-binding observation. The
probe reads machine identity and capability state and reports the source and
configuration SHA-256 identities frozen into this file by the controller-side
overlay. No slack-update repository is required on the target VM. The only
capability action is an ephemeral `unshare --net -- true` check. The probe does
not refresh repositories, contact external networks, modify packages, change
boot state, restart the system, or alter persistent configuration.
USAGE
}

expected_fqdn='vbox-slackcurrent.vbox-slackcurrent.org'
while (($#)); do
    case "$1" in
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
[[ $FROZEN_REFERENCE_SCRIPT_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: embedded reference-script SHA-256 is invalid\n' >&2; exit 4; }
[[ $FROZEN_EFFECTIVE_CONFIG_SHA256 =~ ^[0-9a-f]{64}$ ]] || { printf 'ERROR: embedded effective-config SHA-256 is invalid\n' >&2; exit 4; }

hostname_short=$(hostname)
hostname_fqdn=$(hostname -f)
[[ $hostname_fqdn == "$expected_fqdn" ]] || {
    printf 'ERROR: FQDN mismatch\nexpected: %s\nactual:   %s\n' "$expected_fqdn" "$hostname_fqdn" >&2
    exit 5
}
uname_release=$(uname -r)
slackware_version=$(cat /etc/slackware-version)
boot_id=$(cat /proc/sys/kernel/random/boot_id)
probe_sha=$(sha256sum -- "${BASH_SOURCE[0]}" | awk '{print $1}')

missing=()
for cmd in bash python3 sha256sum tar flock unshare kill ps crontab; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
    printf 'ERROR: required command(s) missing: %s\n' "${missing[*]}" >&2
    exit 6
fi
if ! ps -eo comm= | awk '$1 == "crond" { found=1 } END { exit(found ? 0 : 1) }'; then
    printf 'ERROR: crond is not running\n' >&2
    exit 7
fi
crontab_rc=0
crontab -l >/dev/null 2>&1 || crontab_rc=$?
if [[ $crontab_rc -ne 0 && $crontab_rc -ne 1 ]]; then
    printf 'ERROR: root crontab read-only check returned %d\n' "$crontab_rc" >&2
    exit 8
fi
if ! unshare --net -- true; then
    printf 'ERROR: ephemeral network namespace capability check failed\n' >&2
    exit 9
fi

printf 'binding_status\tPASS\n'
printf 'hostname\t%s\n' "$hostname_short"
printf 'hostname-fqdn\t%s\n' "$hostname_fqdn"
printf 'uname-release\t%s\n' "$uname_release"
printf 'slackware-version\t%s\n' "$slackware_version"
printf 'boot-id\t%s\n' "$boot_id"
printf 'reference-script-sha256\t%s\n' "$FROZEN_REFERENCE_SCRIPT_SHA256"
printf 'effective-config-sha256\t%s\n' "$FROZEN_EFFECTIVE_CONFIG_SHA256"
printf 'source-identity-origin\tcontroller-repo-frozen-at-step-181-r1\n'
printf 'target-repository-required\tno\n'
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
