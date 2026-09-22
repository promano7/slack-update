#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly EXPECTED_REFERENCE_SHA256='086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
readonly EXPECTED_CONFIG_SHA256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_KERNEL='6.18.45'
readonly EXPECTED_BOOT_ID='cb85100b-9993-4876-ab32-b2457ed0ac6d'
readonly RUNTIME_ACK='--execute-runtime-validation'
readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/execution-control-failure-paths'
readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz'
readonly PUBLISHED_SHA256='/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz.sha256'

usage() {
    cat <<'EOF'
Usage: phase-1-execution-control-failure-paths-runtime-executor-build.sh \\
       --repo-root REPO_ROOT --output OUTPUT

Build the reviewed standalone runtime validation executor from the exact frozen
reference script and effective configuration. This command does not contact the
network and does not perform runtime validation.
EOF
}

repo_root=
output=
while (($#)); do
    case "$1" in
        --repo-root)
            [[ $# -ge 2 ]] || { printf 'ERROR: --repo-root requires a value\n' >&2; exit 2; }
            repo_root=$2
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output requires a value\n' >&2; exit 2; }
            output=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

[[ -n $repo_root && -n $output ]] || { usage >&2; exit 2; }
repo_root=$(CDPATH= cd -- "$repo_root" && pwd -P)
reference="$repo_root/tools/reference/slack-update-reference.sh"
config="$repo_root/data/config/slack-update.conf"
for path in "$reference" "$config"; do
    [[ -f $path && ! -L $path ]] || { printf 'ERROR: required frozen input is missing or unsafe: %s\n' "$path" >&2; exit 3; }
done
reference_sha=$(sha256sum -- "$reference" | awk '{print $1}')
config_sha=$(sha256sum -- "$config" | awk '{print $1}')
[[ $reference_sha == "$EXPECTED_REFERENCE_SHA256" ]] || {
    printf 'ERROR: reference script SHA-256 drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_REFERENCE_SHA256" "$reference_sha" >&2
    exit 4
}
[[ $config_sha == "$EXPECTED_CONFIG_SHA256" ]] || {
    printf 'ERROR: effective configuration SHA-256 drift\nexpected: %s\nactual:   %s\n' "$EXPECTED_CONFIG_SHA256" "$config_sha" >&2
    exit 5
}

output_dir=$(dirname -- "$output")
mkdir -p -- "$output_dir"
tmp=$(mktemp "$output_dir/.runtime-executor.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

cat > "$tmp" <<EOF
#!/bin/bash
set -euo pipefail
IFS=\$'\\n\\t'

readonly EXPECTED_FQDN='$EXPECTED_FQDN'
readonly EXPECTED_KERNEL='$EXPECTED_KERNEL'
readonly EXPECTED_BOOT_ID='$EXPECTED_BOOT_ID'
readonly EMBEDDED_REFERENCE_SHA256='$EXPECTED_REFERENCE_SHA256'
readonly EMBEDDED_CONFIG_SHA256='$EXPECTED_CONFIG_SHA256'
readonly RUNTIME_ACK='$RUNTIME_ACK'
readonly EVIDENCE_ROOT='$EVIDENCE_ROOT'
readonly PUBLISHED_ARCHIVE='$PUBLISHED_ARCHIVE'
readonly PUBLISHED_SHA256='$PUBLISHED_SHA256'
EOF

cat >> "$tmp" <<'EXECUTOR_BODY'
readonly PUBLISHED_OWNER='promano:users'
readonly PUBLISHED_MODE='0600'
readonly CRON_WAIT_SECONDS=90
SELF=$(readlink -f -- "${BASH_SOURCE[0]}")
ACTIVE_CHILD=
CRON_MODIFIED=0
CRON_WAS_PRESENT=0
CRON_BACKUP=
RUN_DIR=
DERIVED_CONFIG=
REFERENCE_FILE=
INTERNAL_TOKEN_FILE=
LOCKFILE_RUNTIME=

usage() {
    cat <<'EOF'
Usage: phase-1-execution-control-failure-paths-runtime-executor.sh --execute-runtime-validation
       phase-1-execution-control-failure-paths-runtime-executor.sh --help

Run the bounded Phase 1 execution-control failure-path acceptance validation.
The runtime acknowledgement is mandatory. The executor revalidates the frozen
VM binding before any scenario and does not require a Git repository on target.
EOF
}

extract_payload() {
    local kind=$1 destination=$2 begin end
    case "$kind" in
        reference)
            begin='__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__'
            end='__SLACK_UPDATE_REFERENCE_PAYLOAD_END__'
            ;;
        config)
            begin='__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__'
            end='__SLACK_UPDATE_CONFIG_PAYLOAD_END__'
            ;;
        *) return 2 ;;
    esac
    awk -v begin="$begin" -v end="$end" '
        $0 == begin { inside=1; next }
        $0 == end { inside=0; exit }
        inside { print }
    ' "$SELF" | base64 -d > "$destination"
}

internal_authorized() {
    [[ -n ${SLACK_UPDATE_RUN_DIR:-} && -n ${SLACK_UPDATE_INTERNAL_TOKEN:-} ]]
    [[ -f ${SLACK_UPDATE_RUN_DIR}/internal.token && ! -L ${SLACK_UPDATE_RUN_DIR}/internal.token ]]
    local expected
    expected=$(cat -- "${SLACK_UPDATE_RUN_DIR}/internal.token")
    [[ $SLACK_UPDATE_INTERNAL_TOKEN == "$expected" ]]
}

prepare_reference_driver() {
    local run_dir=$1
    export SLACK_UPDATE_CONFIG="$run_dir/derived.conf"
    # shellcheck disable=SC1090
    source "$run_dir/slack-update-reference.sh"
    initialize_execution_environment
    INSTANCE_LOCK_HELD=0
    load_configuration
    require_root
}

internal_safe_driver() {
    local ready=$1 fifo=$2
    internal_authorized || { printf 'ERROR: internal driver authorization failed\n' >&2; return 97; }
    prepare_reference_driver "$SLACK_UPDATE_RUN_DIR"
    acquire_instance_lock
    install_runtime_traps
    printf 'ready\n' > "$ready"
    IFS= read -r _ < "$fifo" || true
    trap - EXIT HUP INT TERM
    release_instance_lock
}

internal_lock_probe() {
    internal_authorized || return 97
    prepare_reference_driver "$SLACK_UPDATE_RUN_DIR"
    local rc=0
    acquire_instance_lock || rc=$?
    if [[ $rc -eq 0 ]]; then release_instance_lock; fi
    return "$rc"
}

internal_cron_driver() {
    local result_file=$1
    internal_authorized || return 97
    prepare_reference_driver "$SLACK_UPDATE_RUN_DIR"
    acquire_instance_lock
    install_runtime_traps
    {
        if [[ -t 0 || -t 1 || -t 2 ]]; then
            printf 'tty_state\tpresent\n'
        else
            printf 'tty_state\tabsent\n'
        fi
        printf 'driver_state\tcompleted\n'
    } > "$result_file"
    trap - EXIT HUP INT TERM
    release_instance_lock
}

case "${1:-}" in
    --internal-safe-driver)
        [[ $# -eq 3 ]] || exit 96
        internal_safe_driver "$2" "$3"
        exit $?
        ;;
    --internal-lock-probe)
        [[ $# -eq 1 ]] || exit 96
        internal_lock_probe
        exit $?
        ;;
    --internal-cron-driver)
        [[ $# -eq 2 ]] || exit 96
        internal_cron_driver "$2"
        exit $?
        ;;
    -h|--help)
        usage
        exit 0
        ;;
esac

if [[ $# -ne 1 || $1 != "$RUNTIME_ACK" ]]; then
    usage >&2
    exit 2
fi
if [[ $(id -u) -ne 0 ]]; then
    printf 'ERROR: runtime validation must run as root\n' >&2
    exit 8
fi

for command_name in bash python3 sha256sum tar flock unshare kill ps crontab timeout base64 awk sed find sort grep install cp cmp chown chmod mkfifo hostname uname cat date sleep env readlink mktemp rm dirname basename; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'ERROR: required runtime capability is unavailable: %s\n' "$command_name" >&2
        exit 20
    }
done
if ! ps -eo comm= | awk '{$1=$1};1' | grep -Fxq crond; then
    printf 'ERROR: crond is not running\n' >&2
    exit 21
fi

actual_fqdn=$(hostname -f)
actual_kernel=$(uname -r)
actual_boot_id=$(cat /proc/sys/kernel/random/boot_id)
[[ $actual_fqdn == "$EXPECTED_FQDN" ]] || { printf 'ERROR: FQDN drift: %s\n' "$actual_fqdn" >&2; exit 22; }
[[ $actual_kernel == "$EXPECTED_KERNEL" ]] || { printf 'ERROR: kernel drift: %s\n' "$actual_kernel" >&2; exit 23; }
[[ $actual_boot_id == "$EXPECTED_BOOT_ID" ]] || { printf 'ERROR: boot-id drift: %s\n' "$actual_boot_id" >&2; exit 24; }

rm -rf -- "$EVIDENCE_ROOT"
install -d -m 0700 -- "$EVIDENCE_ROOT"
RUN_DIR="$EVIDENCE_ROOT/run"
install -d -m 0700 -- "$RUN_DIR" "$RUN_DIR/pre" "$RUN_DIR/post" "$RUN_DIR/scenarios" "$RUN_DIR/work" "$RUN_DIR/log"
REFERENCE_FILE="$RUN_DIR/slack-update-reference.sh"
DERIVED_CONFIG="$RUN_DIR/derived.conf"
INTERNAL_TOKEN_FILE="$RUN_DIR/internal.token"
LOCKFILE_RUNTIME="$RUN_DIR/slack-update.lock"

extract_payload reference "$REFERENCE_FILE"
extract_payload config "$RUN_DIR/frozen.conf"
chmod 0700 "$REFERENCE_FILE"
chmod 0600 "$RUN_DIR/frozen.conf"
[[ $(sha256sum -- "$REFERENCE_FILE" | awk '{print $1}') == "$EMBEDDED_REFERENCE_SHA256" ]] || {
    printf 'ERROR: embedded reference payload identity mismatch\n' >&2
    exit 25
}
[[ $(sha256sum -- "$RUN_DIR/frozen.conf" | awk '{print $1}') == "$EMBEDDED_CONFIG_SHA256" ]] || {
    printf 'ERROR: embedded configuration payload identity mismatch\n' >&2
    exit 26
}

python3 - "$RUN_DIR/frozen.conf" "$DERIVED_CONFIG" "$RUN_DIR/work" "$RUN_DIR/log" "$LOCKFILE_RUNTIME" <<'PY'
import re, sys
source, output, work, log, lock = sys.argv[1:]
replacements = {"work_dir": work, "log_dir": log, "lock_file": lock}
counts = {key: 0 for key in replacements}
section = None
out = []
with open(source, encoding="utf-8") as handle:
    for raw in handle:
        stripped = raw.strip()
        match = re.fullmatch(r"\[([A-Za-z0-9_]+)\]", stripped)
        if match:
            section = match.group(1)
            out.append(raw)
            continue
        key_match = re.match(r"^(\s*)([a-z0-9_]+)(\s*=\s*)(.*?)(\r?\n)?$", raw)
        if section == "core" and key_match and key_match.group(2) in replacements:
            key = key_match.group(2)
            newline = key_match.group(5) or "\n"
            out.append(f"{key_match.group(1)}{key}{key_match.group(3)}{replacements[key]}{newline}")
            counts[key] += 1
        else:
            out.append(raw)
if counts != {"work_dir": 1, "log_dir": 1, "lock_file": 1}:
    raise SystemExit(f"unexpected core override counts: {counts}")
with open(output, "w", encoding="utf-8", newline="") as handle:
    handle.writelines(out)
PY
chmod 0600 "$DERIVED_CONFIG"
derived_sha=$(sha256sum -- "$DERIVED_CONFIG" | awk '{print $1}')
printf '%s' "$(printf '%s:%s:%s:%s' "$EXPECTED_BOOT_ID" "$$" "$(date +%s%N)" "$derived_sha" | sha256sum | awk '{print $1}')" > "$INTERNAL_TOKEN_FILE"
chmod 0600 "$INTERNAL_TOKEN_FILE"
internal_token=$(cat -- "$INTERNAL_TOKEN_FILE")

cat > "$RUN_DIR/binding.tsv" <<EOF
check\tvalue
hostname_fqdn\t$actual_fqdn
uname_release\t$actual_kernel
boot_id\t$actual_boot_id
reference_script_sha256\t$EMBEDDED_REFERENCE_SHA256
effective_config_sha256\t$EMBEDDED_CONFIG_SHA256
derived_config_sha256\t$derived_sha
EOF

capture_tree_manifest() {
    local tree=$1 output=$2
    python3 - "$tree" > "$output" <<'PY'
import hashlib, os, stat, sys
root = sys.argv[1]
if not os.path.exists(root):
    print("MISSING\t.")
    raise SystemExit(0)
for current, dirs, files in os.walk(root, topdown=True, followlinks=False):
    dirs.sort(); files.sort()
    names = sorted(dirs + files)
    for name in names:
        path = os.path.join(current, name)
        rel = os.path.relpath(path, root)
        try:
            st = os.lstat(path)
        except FileNotFoundError:
            print(f"VANISHED\t{rel}")
            continue
        mode = stat.S_IFMT(st.st_mode)
        if stat.S_ISLNK(mode):
            print(f"L\t{rel}\t{os.readlink(path)}")
        elif stat.S_ISREG(mode):
            h = hashlib.sha256()
            with open(path, "rb") as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                    h.update(chunk)
            print(f"F\t{rel}\t{h.hexdigest()}\t{st.st_size}")
        elif stat.S_ISDIR(mode):
            print(f"D\t{rel}")
        else:
            print(f"O\t{rel}\t{oct(mode)}")
PY
}

capture_root_crontab() {
    local state_file=$1 content_file=$2 error_file=$3 rc
    : > "$content_file"
    : > "$error_file"
    set +e
    crontab -l > "$content_file" 2> "$error_file"
    rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
        printf 'present\n' > "$state_file"
        return 0
    fi
    if [[ $rc -eq 1 ]]; then
        : > "$content_file"
        printf 'absent\n' > "$state_file"
        return 0
    fi
    printf 'ERROR: cannot read root crontab (exit %d)\n' "$rc" >&2
    return "$rc"
}

capture_system_fingerprints() {
    local destination=$1
    install -d -m 0700 -- "$destination"
    capture_tree_manifest /var/lib/pkgtools/packages "$destination/package-database.manifest"
    capture_tree_manifest /var/lib/slackpkg "$destination/slackpkg-state.manifest"
    capture_tree_manifest /etc/slackpkg "$destination/slackpkg-config.manifest"
    capture_tree_manifest /boot "$destination/boot.manifest"
    uname -r > "$destination/kernel.txt"
    cat /proc/cmdline > "$destination/proc-cmdline.txt"
    capture_root_crontab "$destination/root-crontab.state" "$destination/root-crontab.txt" "$destination/root-crontab.stderr"
}

lock_is_free() {
    local rc=0
    exec 8>"$LOCKFILE_RUNTIME"
    flock -n 8 || rc=$?
    if [[ $rc -eq 0 ]]; then flock -u 8 || true; fi
    exec 8>&-
    return "$rc"
}

wait_for_file() {
    local path=$1 max_seconds=$2 elapsed=0
    while [[ ! -f $path ]]; do
        (( elapsed >= max_seconds * 10 )) && return 1
        sleep 0.1
        elapsed=$((elapsed + 1))
    done
}

restore_crontab() {
    [[ $CRON_MODIFIED -eq 1 ]] || return 0
    if [[ $CRON_WAS_PRESENT -eq 1 ]]; then
        crontab "$CRON_BACKUP" >/dev/null 2>&1 || return 1
    else
        crontab -r >/dev/null 2>&1 || true
    fi
    CRON_MODIFIED=0
}

runtime_cleanup() {
    local rc=$?
    if [[ -n ${ACTIVE_CHILD:-} ]] && kill -0 "$ACTIVE_CHILD" 2>/dev/null; then
        kill -TERM "$ACTIVE_CHILD" 2>/dev/null || true
        sleep 1
        kill -KILL "$ACTIVE_CHILD" 2>/dev/null || true
        wait "$ACTIVE_CHILD" 2>/dev/null || true
    fi
    ACTIVE_CHILD=
    restore_crontab || true
    return "$rc"
}
trap runtime_cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

capture_system_fingerprints "$RUN_DIR/pre"
cp -- "$SELF" "$RUN_DIR/runtime-executor.sh"
chmod 0700 "$RUN_DIR/runtime-executor.sh"

printf 'running\n' > "$RUN_DIR/status"

# Scenario 1: a full reference --check must fail inside an isolated network namespace.
network_dir="$RUN_DIR/scenarios/network-failure"
install -d -m 0700 -- "$network_dir"
set +e
timeout 60s unshare --net -- env SLACK_UPDATE_CONFIG="$DERIVED_CONFIG" /bin/bash "$REFERENCE_FILE" --check >"$network_dir/stdout" 2>"$network_dir/stderr"
network_rc=$?
set -e
printf '%d\n' "$network_rc" > "$network_dir/exit-code"
if [[ $network_rc -eq 0 || $network_rc -eq 124 ]]; then
    printf 'ERROR: network-failure scenario did not fail deterministically (exit %d)\n' "$network_rc" >&2
    printf 'failed-network\n' > "$RUN_DIR/status"
    exit 31
fi
lock_is_free || { printf 'ERROR: lock remained held after network scenario\n' >&2; exit 32; }
printf 'PASS\n' > "$network_dir/result"

# Scenario 2: a second real reference lock acquisition must return EXIT_ALREADY_RUNNING=6.
sim_dir="$RUN_DIR/scenarios/simultaneous-execution"
install -d -m 0700 -- "$sim_dir"
sim_fifo="$sim_dir/hold.fifo"
sim_ready="$sim_dir/ready"
mkfifo -m 0600 "$sim_fifo"
SLACK_UPDATE_RUN_DIR="$RUN_DIR" SLACK_UPDATE_INTERNAL_TOKEN="$internal_token" \
    /bin/bash "$RUN_DIR/runtime-executor.sh" --internal-safe-driver "$sim_ready" "$sim_fifo" >"$sim_dir/first.stdout" 2>"$sim_dir/first.stderr" &
ACTIVE_CHILD=$!
wait_for_file "$sim_ready" 10 || { printf 'ERROR: first lock holder did not become ready\n' >&2; exit 33; }
set +e
SLACK_UPDATE_RUN_DIR="$RUN_DIR" SLACK_UPDATE_INTERNAL_TOKEN="$internal_token" \
    /bin/bash "$RUN_DIR/runtime-executor.sh" --internal-lock-probe >"$sim_dir/second.stdout" 2>"$sim_dir/second.stderr"
second_rc=$?
set -e
printf '%d\n' "$second_rc" > "$sim_dir/second-exit-code"
[[ $second_rc -eq 6 ]] || { printf 'ERROR: second lock attempt returned %d instead of 6\n' "$second_rc" >&2; exit 34; }
printf 'release\n' > "$sim_fifo"
if wait "$ACTIVE_CHILD"; then first_rc=0; else first_rc=$?; fi
ACTIVE_CHILD=
printf '%d\n' "$first_rc" > "$sim_dir/first-exit-code"
[[ $first_rc -eq 0 ]] || { printf 'ERROR: first lock holder exited %d\n' "$first_rc" >&2; exit 35; }
lock_is_free || { printf 'ERROR: lock remained held after simultaneous-execution scenario\n' >&2; exit 36; }
printf 'PASS\n' > "$sim_dir/result"

# Scenario 3: deliver each required signal to a signalable safe reference driver.
sig_dir="$RUN_DIR/scenarios/signals"
install -d -m 0700 -- "$sig_dir"
for item in INT:130 TERM:143 HUP:129; do
    signal_name=${item%%:*}
    expected_rc=${item##*:}
    one_dir="$sig_dir/$signal_name"
    install -d -m 0700 -- "$one_dir"
    fifo="$one_dir/hold.fifo"
    ready="$one_dir/ready"
    mkfifo -m 0600 "$fifo"
    SLACK_UPDATE_RUN_DIR="$RUN_DIR" SLACK_UPDATE_INTERNAL_TOKEN="$internal_token" \
    python3 - "$RUN_DIR/runtime-executor.sh" "$ready" "$fifo" >"$one_dir/stdout" 2>"$one_dir/stderr" <<'PY' &
import os, signal, sys
script, ready, fifo = sys.argv[1:]
for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(sig, signal.SIG_DFL)
os.execve('/bin/bash', ['/bin/bash', script, '--internal-safe-driver', ready, fifo], os.environ)
PY
    ACTIVE_CHILD=$!
    wait_for_file "$ready" 10 || { printf 'ERROR: %s driver did not become ready\n' "$signal_name" >&2; exit 37; }
    kill -s "$signal_name" "$ACTIVE_CHILD"
    if wait "$ACTIVE_CHILD"; then signal_rc=0; else signal_rc=$?; fi
    ACTIVE_CHILD=
    printf '%d\n' "$signal_rc" > "$one_dir/exit-code"
    [[ $signal_rc -eq $expected_rc ]] || { printf 'ERROR: %s returned %d instead of %d\n' "$signal_name" "$signal_rc" "$expected_rc" >&2; exit 38; }
    lock_is_free || { printf 'ERROR: lock remained held after %s\n' "$signal_name" >&2; exit 39; }
    printf 'PASS\n' > "$one_dir/result"
done
printf 'PASS\n' > "$sig_dir/result"

# Scenario 4: run the safe driver once through the already-running real root cron.
cron_dir="$RUN_DIR/scenarios/cron"
install -d -m 0700 -- "$cron_dir"
CRON_BACKUP="$cron_dir/root-crontab.before"
cron_state="$cron_dir/root-crontab.before.state"
cron_err="$cron_dir/root-crontab.before.stderr"
capture_root_crontab "$cron_state" "$CRON_BACKUP" "$cron_err"
if [[ $(cat "$cron_state") == present ]]; then CRON_WAS_PRESENT=1; else CRON_WAS_PRESENT=0; fi
cron_install="$cron_dir/root-crontab.with-test"
if [[ $CRON_WAS_PRESENT -eq 1 ]]; then cat "$CRON_BACKUP" > "$cron_install"; else : > "$cron_install"; fi
printf '\n# slack-update-phase-1-execution-control-failure-paths\n' >> "$cron_install"
printf '* * * * * SLACK_UPDATE_RUN_DIR=%q SLACK_UPDATE_INTERNAL_TOKEN=%q /bin/bash %q --internal-cron-driver %q >>%q 2>&1\n' \
    "$RUN_DIR" "$internal_token" "$RUN_DIR/runtime-executor.sh" "$cron_dir/driver-result.tsv" "$cron_dir/cron.log" >> "$cron_install"
crontab "$cron_install"
CRON_MODIFIED=1
elapsed=0
while [[ ! -f $cron_dir/driver-result.tsv && $elapsed -lt $CRON_WAIT_SECONDS ]]; do
    sleep 2
    elapsed=$((elapsed + 2))
done
[[ -f $cron_dir/driver-result.tsv ]] || { printf 'ERROR: real cron driver did not complete within %d seconds\n' "$CRON_WAIT_SECONDS" >&2; exit 40; }
grep -Fqx $'tty_state\tabsent' "$cron_dir/driver-result.tsv" || { printf 'ERROR: cron driver observed an interactive terminal\n' >&2; exit 41; }
grep -Fqx $'driver_state\tcompleted' "$cron_dir/driver-result.tsv" || { printf 'ERROR: cron driver did not report completion\n' >&2; exit 42; }
restore_crontab || { printf 'ERROR: root crontab restoration failed\n' >&2; exit 43; }
capture_root_crontab "$cron_dir/root-crontab.after.state" "$cron_dir/root-crontab.after" "$cron_dir/root-crontab.after.stderr"
cmp -s "$cron_state" "$cron_dir/root-crontab.after.state" || { printf 'ERROR: root crontab presence state changed\n' >&2; exit 44; }
cmp -s "$CRON_BACKUP" "$cron_dir/root-crontab.after" || { printf 'ERROR: root crontab content was not restored exactly\n' >&2; exit 45; }
lock_is_free || { printf 'ERROR: lock remained held after cron scenario\n' >&2; exit 46; }
printf 'PASS\n' > "$cron_dir/result"

capture_system_fingerprints "$RUN_DIR/post"
for file in package-database.manifest slackpkg-state.manifest slackpkg-config.manifest boot.manifest kernel.txt proc-cmdline.txt root-crontab.state root-crontab.txt; do
    cmp -s "$RUN_DIR/pre/$file" "$RUN_DIR/post/$file" || {
        printf 'ERROR: protected fingerprint changed: %s\n' "$file" >&2
        exit 47
    }
done
lock_is_free || { printf 'ERROR: final reference lock is not clean\n' >&2; exit 48; }
[[ $CRON_MODIFIED -eq 0 ]] || { printf 'ERROR: final cron restoration gate is not clean\n' >&2; exit 49; }

cat > "$RUN_DIR/result.tsv" <<EOF
check\tvalue
family\texecution-control-failure-paths
network_failure\tPASS
simultaneous_execution\tPASS
signal_SIGINT\tPASS
signal_SIGTERM\tPASS
signal_SIGHUP\tPASS
cron_without_interactive_terminal\tPASS
package_database_unchanged\tyes
slackpkg_state_unchanged\tyes
boot_artifacts_unchanged\tyes
root_crontab_restored_exactly\tyes
lock_clean\tyes
runtime_binding_preserved\tyes
EOF
printf 'PASS\n' > "$RUN_DIR/status"

rm -f -- "$PUBLISHED_ARCHIVE" "$PUBLISHED_SHA256"
tar -czf "$PUBLISHED_ARCHIVE" -C "$(dirname -- "$EVIDENCE_ROOT")" "$(basename -- "$EVIDENCE_ROOT")"
sha256sum -- "$PUBLISHED_ARCHIVE" > "$PUBLISHED_SHA256"
chown "$PUBLISHED_OWNER" "$PUBLISHED_ARCHIVE" "$PUBLISHED_SHA256"
chmod "$PUBLISHED_MODE" "$PUBLISHED_ARCHIVE" "$PUBLISHED_SHA256"

printf 'runtime_validation_status\tPASS\n'
printf 'evidence_archive\t%s\n' "$PUBLISHED_ARCHIVE"
printf 'evidence_sha256_file\t%s\n' "$PUBLISHED_SHA256"
printf 'evidence_archive_sha256\t%s\n' "$(sha256sum -- "$PUBLISHED_ARCHIVE" | awk '{print $1}')"
printf 'boot_id\t%s\n' "$actual_boot_id"
printf 'derived_config_sha256\t%s\n' "$derived_sha"
exit 0

__SLACK_UPDATE_REFERENCE_PAYLOAD_BEGIN__
EXECUTOR_BODY
base64 -w 76 -- "$reference" >> "$tmp"
cat >> "$tmp" <<'EXECUTOR_MIDDLE'
__SLACK_UPDATE_REFERENCE_PAYLOAD_END__
__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__
EXECUTOR_MIDDLE
base64 -w 76 -- "$config" >> "$tmp"
cat >> "$tmp" <<'EXECUTOR_END'
__SLACK_UPDATE_CONFIG_PAYLOAD_END__
EXECUTOR_END
chmod 0755 "$tmp"
mv -f -- "$tmp" "$output"
trap - EXIT
printf 'Built standalone runtime executor: %s\n' "$output"
printf 'Reference script SHA-256: %s\n' "$reference_sha"
printf 'Effective config SHA-256: %s\n' "$config_sha"
printf 'Runtime executor SHA-256: %s\n' "$(sha256sum -- "$output" | awk '{print $1}')"
