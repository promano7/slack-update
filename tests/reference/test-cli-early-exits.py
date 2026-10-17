#!/usr/bin/env python3
"""Check main's help/invalid-input exits with later boundaries prohibited."""

from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
USAGE = b"""Usage: reference-cli-test [--check | --apply | --dry-run] [--json | --events]
       reference-cli-test [--help]

Run the current Slack-Update reference workflow.

Options:
      --check    Check for Slackware repository updates without applying changes
      --apply    Run the existing update workflow and apply changes
      --dry-run  Produce a complete non-modifying execution plan
      --json     Write the final structured result to standard output
      --events   Stream provisional NDJSON progress events to standard output
  -h, --help     Show this help message and exit

Running without an operation preserves the current legacy apply workflow.
With --json or --events, human-readable progress is written to standard error
and the log. The two machine-readable output modes are mutually exclusive.
Configuration is loaded from /etc/slack-update/slack-update.conf. When the
script runs from the source tree, data/config/slack-update.conf is used as a
development fallback. SLACK_UPDATE_CONFIG may select another file for tests.
Optional modules use enabled, disabled, or auto activation modes in that file.
Process exit codes 0 through 8 are stable and documented in README.md.
"""
# This list names replaced functions, not an operating-system sandbox. A future
# newly introduced effect boundary must be reviewed before running this test.
FORBIDDEN = (
    "load_configuration", "require_root", "acquire_instance_lock",
    "install_runtime_traps", "initialize_dry_run_runtime", "initialize_runtime",
    "rotate_logs", "configure_logging", "print_start_banner",
    "emit_operation_started_event", "run_check_workflow", "run_apply_workflow",
    "run_dry_run_workflow", "date", "determine_stable_exit_code",
    "print_stable_exit_code_summary", "print_json_result", "emit_final_events",
)
PREFIX = r'''
source "$1"
TRACE=$2
CHANNEL=$3
channel_mode=$4
shift 4
initialize_execution_environment() {
    printf 'environment\n' >> "$TRACE"
}
forbidden() {
    printf 'forbidden:%s\n' "$1" >> "$TRACE"
    printf 'ERROR: prohibited boundary: %s\n' "$1" >&2
    exit 97
}
if [ "$channel_mode" = open ]; then
    exec 3>"$CHANNEL"
else
    exec 3>&-
fi
'''
# Fixed reviewed function names are used to generate definitions; arguments are
# passed as subprocess argv and never inserted into shell source or evaluated.
DRIVER = PREFIX + "\n".join(
    f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN
) + '\nmain "$@"\n'


def cases():
    result = [(["--help"], 0, b""), (["-h"], 0, b""),
              (["--help", "-h"], 0, b""), (["--help", "--"], 0, b"")]
    for help_option in ("--help", "-h"):
        for operation in ("--check", "--apply", "--dry-run"):
            result.extend([([help_option, operation], 0, b""),
                           ([operation, help_option], 0, b"")])
            for output in ("--json", "--events"):
                result.extend([([help_option, operation, output], 0, b""),
                               ([output, operation, help_option], 0, b"")])
        for output in ("--json", "--events"):
            result.extend([([output, help_option], 0, b""),
                           ([help_option, output], 0, b"")])
    invalid = [
        (["--unknown"], "unknown option: --unknown"),
        (["--help", "--unknown"], "unknown option: --unknown"),
        (["--unknown", "--help"], "unknown option: --unknown"),
        (["--help", "extra"], "unexpected argument: extra"),
        (["extra", "--help"], "unexpected argument: extra"),
        ([""], "unexpected argument: "),
        (["--", "--help"], "unexpected argument: --help"),
        (["--help", "--", "extra"], "unexpected argument: extra"),
        (["--check", "--apply"], "only one operation may be specified"),
        (["--help", "--check", "--check"], "only one operation may be specified"),
        (["--json", "--events"], "--json and --events are mutually exclusive"),
        (["--events", "--json"], "--json and --events are mutually exclusive"),
        (["--help", "--json", "--events"], "--json and --events are mutually exclusive"),
        (["--json", "--unknown"], "unknown option: --unknown"),
        (["--events", "--unknown"], "unknown option: --unknown"),
        (["--dry-run", "unexpected"], "unexpected argument: unexpected"),
        (["--apply", "--unknown"], "unknown option: --unknown"),
        (["--check", "--unknown"], "unknown option: --unknown"),
    ]
    result.extend((arguments, 7, ("Error: " + diagnostic + "\n").encode("utf-8"))
                  for arguments, diagnostic in invalid)
    return result


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-cli-early-") as directory:
        work = Path(directory)
        for mode in ("closed", "open"):
            for arguments, status, diagnostic in cases():
                trace = work / "trace"
                channel = work / "channel"
                trace.unlink(missing_ok=True)
                channel.unlink(missing_ok=True)
                result = subprocess.run(
                    ["bash", "--noprofile", "--norc", "-c", DRIVER,
                     "reference-cli-test", str(REFERENCE), str(trace), str(channel),
                     mode, *arguments], cwd=work, capture_output=True, timeout=10)
                assert result.returncode == status, (mode, arguments, result.returncode, result.stderr)
                assert result.stdout == (USAGE if status == 0 else b""), (mode, arguments, result.stdout)
                assert result.stderr == (b"" if status == 0 else diagnostic + USAGE), (mode, arguments, result.stderr)
                assert trace.is_file(), (mode, arguments, "missing environment call")
                assert trace.read_bytes() == b"environment\n", (mode, arguments, trace.read_bytes())
                if mode == "open":
                    assert channel.read_bytes() == b"", (mode, arguments, channel.read_bytes())
                else:
                    assert not channel.exists(), (mode, arguments)
                count += 1
    return count


def main():
    count = run_cases()
    print(f"CLI early exits: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
