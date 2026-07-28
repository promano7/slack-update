#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "$TEST_DIR/../.." && pwd)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
DEFAULT_CONFIG="$REPOSITORY_ROOT/data/config/slack-update.conf"
EXPECTED_PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

TEST_COUNT=0
FAILURE_COUNT=0

pass() {
    TEST_COUNT=$((TEST_COUNT + 1))
}

fail() {
    local message=$1

    TEST_COUNT=$((TEST_COUNT + 1))
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$message" >&2
}

assert_equal() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" = "$expected" ]; then
        pass
    else
        fail "$message (expected '$expected', got '$actual')"
    fi
}

assert_file_contains() {
    local pattern=$1
    local path=$2
    local message=$3

    if grep -Fq -- "$pattern" "$path"; then
        pass
    else
        fail "$message"
    fi
}

assert_file_not_contains() {
    local pattern=$1
    local path=$2
    local message=$3

    if grep -Fq -- "$pattern" "$path"; then
        fail "$message"
    else
        pass
    fi
}

assert_file_exists() {
    local path=$1
    local message=$2

    if [ -e "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

assert_mode() {
    local expected=$1
    local path=$2
    local message=$3
    local actual

    actual=$(stat -c '%a' -- "$path" 2>/dev/null) || actual=missing
    assert_equal "$expected" "$actual" "$message"
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

# Source-level contract: normalize the environment before any CLI or config work.
main_start=$(grep -n '^main() {' "$REFERENCE_SCRIPT" | cut -d: -f1)
main_end=$(grep -n '^if \[ "${BASH_SOURCE\[0\]}" = "\$0" \]; then' "$REFERENCE_SCRIPT" | cut -d: -f1)
main_source=$(sed -n "${main_start},${main_end}p" "$REFERENCE_SCRIPT")
init_line=$(printf '%s\n' "$main_source" | grep -n '^[[:space:]]*initialize_execution_environment$' | cut -d: -f1)
parse_line=$(printf '%s\n' "$main_source" | grep -n '^[[:space:]]*parse_arguments ' | cut -d: -f1)
load_line=$(printf '%s\n' "$main_source" | grep -n '^[[:space:]]*load_configuration ' | cut -d: -f1)

if grep -Fq 'initialize_execution_environment() {' "$REFERENCE_SCRIPT"; then
    pass
else
    fail 'the reference script should define an execution-environment initializer'
fi
if [ -n "$init_line" ] && [ -n "$parse_line" ] && [ "$init_line" -lt "$parse_line" ]; then
    pass
else
    fail 'the execution environment should be normalized before argument parsing'
fi
if [ -n "$init_line" ] && [ -n "$load_line" ] && [ "$init_line" -lt "$load_line" ]; then
    pass
else
    fail 'the execution environment should be normalized before configuration loading'
fi
assert_file_contains "readonly SLACK_UPDATE_SYSTEM_PATH=$EXPECTED_PATH" "$REFERENCE_SCRIPT" \
    'the deterministic command path should include all Slackware administrative directories'
assert_file_contains 'HOME=/root' "$REFERENCE_SCRIPT" \
    'cron execution should use the root home directory'
assert_file_contains 'TMPDIR=/tmp' "$REFERENCE_SCRIPT" \
    'temporary files should use the system temporary directory'
assert_file_contains 'LC_ALL=C' "$REFERENCE_SCRIPT" \
    'cron execution should use a deterministic locale'
assert_file_contains 'TERM=dumb' "$REFERENCE_SCRIPT" \
    'cron execution should advertise a non-interactive terminal type'
assert_file_contains 'GIT_TERMINAL_PROMPT=0' "$REFERENCE_SCRIPT" \
    'unattended Git operations should reject terminal prompts'
assert_file_contains 'GIT_ASKPASS=/bin/false' "$REFERENCE_SCRIPT" \
    'unattended Git operations should reject graphical credential prompts'
assert_file_contains 'SSH_ASKPASS=/bin/false' "$REFERENCE_SCRIPT" \
    'unattended SSH helpers should reject graphical credential prompts'
assert_file_contains 'unset CDPATH DISPLAY WAYLAND_DISPLAY XAUTHORITY' "$REFERENCE_SCRIPT" \
    'cron execution should discard inherited directory and graphical-session variables'
assert_file_contains 'unset DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR' "$REFERENCE_SCRIPT" \
    'cron execution should not depend on a desktop session bus'
assert_file_contains 'umask 077' "$REFERENCE_SCRIPT" \
    'runtime files should use a deterministic owner-only umask'

for interactive_pattern in 'read -p' 'read -s' 'stty ' '/dev/tty'; do
    if grep -Fq -- "$interactive_pattern" "$REFERENCE_SCRIPT"; then
        fail "the reference script should not require an interactive primitive: $interactive_pattern"
    else
        pass
    fi
done

# Exercise the environment initializer in a fully empty and deliberately hostile environment.
ENV_HARNESS="$TEST_TMP/environment-harness.sh"
cat > "$ENV_HARNESS" <<'HARNESS_EOF'
#!/bin/bash

REFERENCE_SCRIPT=$1
OUTPUT=$2

# shellcheck source=/dev/null
source "$REFERENCE_SCRIPT"
initialize_execution_environment

{
    printf 'PATH=%s\n' "$PATH"
    printf 'HOME=%s\n' "$HOME"
    printf 'USER=%s\n' "$USER"
    printf 'LOGNAME=%s\n' "$LOGNAME"
    printf 'SHELL=%s\n' "$SHELL"
    printf 'TMPDIR=%s\n' "$TMPDIR"
    printf 'LANG=%s\n' "$LANG"
    printf 'LC_ALL=%s\n' "$LC_ALL"
    printf 'TERM=%s\n' "$TERM"
    printf 'GIT_TERMINAL_PROMPT=%s\n' "$GIT_TERMINAL_PROMPT"
    printf 'GIT_ASKPASS=%s\n' "$GIT_ASKPASS"
    printf 'SSH_ASKPASS=%s\n' "$SSH_ASKPASS"
    printf 'CDPATH=%s\n' "${CDPATH-unset}"
    printf 'DISPLAY=%s\n' "${DISPLAY-unset}"
    printf 'WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY-unset}"
    printf 'XAUTHORITY=%s\n' "${XAUTHORITY-unset}"
    printf 'DBUS_SESSION_BUS_ADDRESS=%s\n' "${DBUS_SESSION_BUS_ADDRESS-unset}"
    printf 'XDG_RUNTIME_DIR=%s\n' "${XDG_RUNTIME_DIR-unset}"
    printf 'UMASK=%s\n' "$(umask)"
    printf 'FIND=%s\n' "$(command -v find)"
    printf 'FLOCK=%s\n' "$(command -v flock)"
} > "$OUTPUT"
HARNESS_EOF
chmod 0755 "$ENV_HARNESS"

ENV_OUTPUT="$TEST_TMP/environment.out"
/usr/bin/env -i \
    PATH=/hostile/bin \
    HOME=/tmp/hostile-home \
    USER=hostile-user \
    LOGNAME=hostile-logname \
    SHELL=/bin/false \
    TMPDIR=/tmp/hostile-tmp \
    LANG=C.UTF-8 \
    LC_ALL=POSIX \
    TERM=xterm-256color \
    GIT_TERMINAL_PROMPT=1 \
    GIT_ASKPASS=/tmp/hostile-askpass \
    SSH_ASKPASS=/tmp/hostile-ssh-askpass \
    CDPATH=/tmp \
    DISPLAY=:99 \
    WAYLAND_DISPLAY=wayland-99 \
    XAUTHORITY=/tmp/authority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/bus \
    XDG_RUNTIME_DIR=/tmp/runtime \
    /bin/bash "$ENV_HARNESS" "$REFERENCE_SCRIPT" "$ENV_OUTPUT"
env_status=$?
assert_equal 0 "$env_status" 'the environment initializer should run under env -i'
assert_file_contains "PATH=$EXPECTED_PATH" "$ENV_OUTPUT" \
    'the inherited PATH should be replaced rather than extended'
assert_file_contains 'HOME=/root' "$ENV_OUTPUT" 'HOME should be normalized for root cron'
assert_file_contains 'USER=root' "$ENV_OUTPUT" 'USER should be normalized for root cron'
assert_file_contains 'LOGNAME=root' "$ENV_OUTPUT" 'LOGNAME should be normalized for root cron'
assert_file_contains 'SHELL=/bin/bash' "$ENV_OUTPUT" 'SHELL should identify the required interpreter'
assert_file_contains 'TMPDIR=/tmp' "$ENV_OUTPUT" 'TMPDIR should be normalized'
assert_file_contains 'LANG=C' "$ENV_OUTPUT" 'LANG should be deterministic'
assert_file_contains 'LC_ALL=C' "$ENV_OUTPUT" 'LC_ALL should be deterministic'
assert_file_contains 'TERM=dumb' "$ENV_OUTPUT" 'TERM should be non-interactive'
assert_file_contains 'GIT_TERMINAL_PROMPT=0' "$ENV_OUTPUT" \
    'Git terminal prompting should be disabled'
assert_file_contains 'GIT_ASKPASS=/bin/false' "$ENV_OUTPUT" \
    'Git askpass prompting should be disabled'
assert_file_contains 'SSH_ASKPASS=/bin/false' "$ENV_OUTPUT" \
    'SSH askpass prompting should be disabled'
assert_file_contains 'CDPATH=unset' "$ENV_OUTPUT" 'CDPATH should be removed'
assert_file_contains 'DISPLAY=unset' "$ENV_OUTPUT" 'DISPLAY should be removed'
assert_file_contains 'WAYLAND_DISPLAY=unset' "$ENV_OUTPUT" 'WAYLAND_DISPLAY should be removed'
assert_file_contains 'XAUTHORITY=unset' "$ENV_OUTPUT" 'XAUTHORITY should be removed'
assert_file_contains 'DBUS_SESSION_BUS_ADDRESS=unset' "$ENV_OUTPUT" \
    'the desktop session bus should be removed'
assert_file_contains 'XDG_RUNTIME_DIR=unset' "$ENV_OUTPUT" \
    'the desktop runtime directory should be removed'
assert_file_contains 'UMASK=0077' "$ENV_OUTPUT" 'the runtime umask should be owner-only'
assert_file_contains 'FIND=' "$ENV_OUTPUT" 'standard userland commands should remain discoverable'
assert_file_not_contains 'FIND=missing' "$ENV_OUTPUT" 'find should resolve through the deterministic path'
assert_file_contains 'FLOCK=' "$ENV_OUTPUT" 'administrative support commands should remain discoverable'
assert_file_not_contains 'FLOCK=missing' "$ENV_OUTPUT" 'flock should resolve through the deterministic path'
find_command=$(sed -n 's/^FIND=//p' "$ENV_OUTPUT")
flock_command=$(sed -n 's/^FLOCK=//p' "$ENV_OUTPUT")
case "$find_command" in
    /*) pass ;;
    *) fail 'find should resolve to an absolute command path' ;;
esac
case "$flock_command" in
    /*) pass ;;
    *) fail 'flock should resolve to an absolute command path' ;;
esac

# --help must work directly with no cron-provided HOME, locale, shell, or usable PATH.
HELP_OUTPUT="$TEST_TMP/help.out"
HELP_ERROR="$TEST_TMP/help.err"
timeout 5 /usr/bin/env -i PATH=/missing "$REFERENCE_SCRIPT" --help \
    </dev/null > "$HELP_OUTPUT" 2> "$HELP_ERROR"
help_status=$?
assert_equal 0 "$help_status" 'direct --help execution should work under env -i'
assert_file_contains 'Usage:' "$HELP_OUTPUT" 'minimal-environment help should reach standard output'
assert_equal 0 "$(wc -c < "$HELP_ERROR")" 'minimal-environment help should not emit diagnostics'

make_case_config() {
    local case_dir=$1
    local config=$2

    mkdir -p "$case_dir/packages" "$case_dir/sbo-queues" "$case_dir/grub" "$case_dir/csb"
    sed \
        -e "s#^work_dir=.*#work_dir=$case_dir/work#" \
        -e "s#^log_dir=.*#log_dir=$case_dir/log#" \
        -e "s#^lock_file=.*#lock_file=$case_dir/slack-update.lock#" \
        -e "s#^package_database=.*#package_database=$case_dir/packages#" \
        -e 's#^mode=auto#mode=disabled#g' \
        -e "s#^sbopkg_config=.*#sbopkg_config=$case_dir/sbopkg.conf#" \
        -e "s#^queue_dir_fallback=.*#queue_dir_fallback=$case_dir/sbo-queues#" \
        -e "s#^options_file=.*#options_file=$case_dir/sbo-options.sqf#" \
        -e "s#^mkinitrd_config=.*#mkinitrd_config=$case_dir/mkinitrd.conf#" \
        -e "s#^initrd_default_output=.*#initrd_default_output=$case_dir/initrd.gz#" \
        -e "s#^modules_directory=.*#modules_directory=$case_dir/modules#" \
        -e "s#^grub_directory=.*#grub_directory=$case_dir/grub#" \
        -e "s#^grub_config=.*#grub_config=$case_dir/grub/grub.cfg#" \
        -e "s#^repository=.*#repository=$case_dir/csb#" \
        "$DEFAULT_CONFIG" > "$config"
}

CRON_HARNESS="$TEST_TMP/cron-harness.sh"
cat > "$CRON_HARNESS" <<'HARNESS_EOF'
#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

REFERENCE_SCRIPT=$1
CASE_DIR=$2
SLACK_UPDATE_CONFIG=$3
shift 3
export SLACK_UPDATE_CONFIG

# shellcheck source=/dev/null
source "$REFERENCE_SCRIPT"

require_root() {
    return 0
}

slackpkg() {
    {
        printf 'PATH=%s\n' "$PATH"
        printf 'HOME=%s\n' "$HOME"
        printf 'USER=%s\n' "$USER"
        printf 'LOGNAME=%s\n' "$LOGNAME"
        printf 'SHELL=%s\n' "$SHELL"
        printf 'TMPDIR=%s\n' "$TMPDIR"
        printf 'LANG=%s\n' "$LANG"
        printf 'LC_ALL=%s\n' "$LC_ALL"
        printf 'TERM=%s\n' "$TERM"
        printf 'GIT_TERMINAL_PROMPT=%s\n' "$GIT_TERMINAL_PROMPT"
        printf 'GIT_ASKPASS=%s\n' "$GIT_ASKPASS"
        printf 'SSH_ASKPASS=%s\n' "$SSH_ASKPASS"
        printf 'STDIN_TTY=%s\n' "$([ -t 0 ] && printf yes || printf no)"
        printf 'STDOUT_TTY=%s\n' "$([ -t 1 ] && printf yes || printf no)"
        printf 'STDERR_TTY=%s\n' "$([ -t 2 ] && printf yes || printf no)"
        printf 'ARGS='
        printf '%s ' "$@"
        printf '\n'
        printf 'UMASK=%s\n' "$(umask)"
    } > "$CASE_DIR/slackpkg.environment"
    return 100
}

main "$@"
HARNESS_EOF
chmod 0755 "$CRON_HARNESS"

run_cron_case() {
    local name=$1
    shift
    local case_dir="$TEST_TMP/$name"
    local config="$case_dir/slack-update.conf"
    local status

    mkdir -p "$case_dir"
    make_case_config "$case_dir" "$config"

    timeout 10 /usr/bin/env -i \
        PATH=/missing \
        HOME=/tmp/hostile-home \
        LANG=es_ES.UTF-8 \
        TERM=xterm \
        DISPLAY=:99 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/fake-bus \
        /bin/bash "$CRON_HARNESS" "$REFERENCE_SCRIPT" "$case_dir" "$config" "$@" \
        </dev/null > "$case_dir/stdout" 2> "$case_dir/stderr"
    status=$?
    printf '%s' "$status"
}

human_status=$(run_cron_case human --check)
assert_equal 0 "$human_status" 'a detached human-readable cron check should succeed'
assert_file_contains 'Slackware repository updates are available' "$TEST_TMP/human/stdout" \
    'the cron check should complete its human-readable summary'
assert_file_exists "$TEST_TMP/human/slackpkg.environment" \
    'the cron check should invoke slackpkg'
assert_file_contains 'ARGS=-batch=on -default_answer=n check-updates ' \
    "$TEST_TMP/human/slackpkg.environment" \
    'the cron check should use non-interactive slackpkg arguments'
assert_file_contains "PATH=$EXPECTED_PATH" "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should expose the deterministic PATH to commands'
assert_file_contains 'HOME=/root' "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should expose the root home directory'
assert_file_contains 'LANG=C' "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should expose the deterministic language'
assert_file_contains 'LC_ALL=C' "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should expose the deterministic locale'
assert_file_contains 'TERM=dumb' "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should expose a non-interactive terminal type'
assert_file_contains 'GIT_TERMINAL_PROMPT=0' "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should disable Git terminal prompts'
assert_file_contains 'STDIN_TTY=no' "$TEST_TMP/human/slackpkg.environment" \
    'the cron workflow should not require a terminal on stdin'
assert_file_contains 'STDOUT_TTY=no' "$TEST_TMP/human/slackpkg.environment" \
    'the cron workflow should not require a terminal on stdout'
assert_file_contains 'STDERR_TTY=no' "$TEST_TMP/human/slackpkg.environment" \
    'the cron workflow should not require a terminal on stderr'
assert_file_contains 'UMASK=0077' "$TEST_TMP/human/slackpkg.environment" \
    'the complete workflow should retain the owner-only umask'
assert_mode 700 "$TEST_TMP/human/work" 'the cron work directory should be owner-only'
assert_mode 700 "$TEST_TMP/human/log" 'the cron log directory should be owner-only'
assert_mode 600 "$TEST_TMP/human/slack-update.lock" 'the cron lock file should be owner-only'
human_log=$(find "$TEST_TMP/human/log" -maxdepth 1 -type f -name 'run-*.log' -print -quit)
assert_file_exists "$human_log" 'the cron workflow should create a persistent log'
assert_mode 600 "$human_log" 'the cron log should be owner-only'
assert_file_contains 'CHECK SUMMARY' "$human_log" 'the cron log should contain the completed summary'

json_status=$(run_cron_case json --check --json)
assert_equal 0 "$json_status" 'a detached JSON cron check should succeed'
assert_file_contains '"exit_code": 0' "$TEST_TMP/json/stdout" \
    'JSON cron output should expose the successful process code'
assert_file_contains '"success": true' "$TEST_TMP/json/stdout" \
    'JSON cron output should expose a successful result'
assert_file_not_contains 'CHECK SUMMARY' "$TEST_TMP/json/stdout" \
    'JSON stdout should remain free of human-readable progress'
assert_file_contains 'CHECK SUMMARY' "$TEST_TMP/json/stderr" \
    'JSON mode should route human-readable progress to stderr'
assert_equal 1 "$(grep -c '^{[[:space:]]*$' "$TEST_TMP/json/stdout")" \
    'JSON mode should emit one final structured object'

events_status=$(run_cron_case events --check --events)
assert_equal 0 "$events_status" 'a detached NDJSON cron check should succeed'
assert_file_contains '"type":"operation_started"' "$TEST_TMP/events/stdout" \
    'event mode should begin with an operation-started record'
assert_file_contains '"type":"operation_completed"' "$TEST_TMP/events/stdout" \
    'event mode should finish with an operation-completed record'
assert_file_contains '"exit_code":0' "$TEST_TMP/events/stdout" \
    'the final event should expose the successful process code'
assert_file_not_contains 'CHECK SUMMARY' "$TEST_TMP/events/stdout" \
    'event stdout should remain free of human-readable progress'
assert_file_contains 'CHECK SUMMARY' "$TEST_TMP/events/stderr" \
    'event mode should route human-readable progress to stderr'

if [ "$FAILURE_COUNT" -ne 0 ]; then
    printf 'FAILED: %d of %d cron-environment checks failed\n' \
        "$FAILURE_COUNT" "$TEST_COUNT" >&2
    exit 1
fi

printf 'PASS: %d cron-environment checks\n' "$TEST_COUNT"
