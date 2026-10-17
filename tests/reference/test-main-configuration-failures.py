#!/usr/bin/env python3
"""Exercise main's real configuration loader with later effects prohibited."""

from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
BASELINE = """[core]
schema_version=1
work_dir=/private/work
log_dir=/private/log
lock_file=/private/lock
log_retention_days=30
package_database=/private/packages
[slackware]
install_new=true
upgrade_all=true
[flatpak]
mode=auto
[sbo]
mode=auto
sbopkg_config=/private/sbopkg.conf
queue_dir_fallback=/private/queues
package_tag=_SBo
options_file=/private/options.sqf
[elf]
mode=auto
scan_paths=/private/bin:/private/lib
[packages]
abi=glibc gcc
cinnamon_abi=mesa gtk+3
critical=glibc dbus
kernel=kernel-generic kernel-headers
kernel_boot=kernel-generic
kernel_headers=kernel-headers
[boot]
mode=auto
mkinitrd_config=/private/mkinitrd.conf
initrd_default_output=/private/initrd.gz
kernel_package=kernel-generic
modules_directory=/private/modules
grub_directory=/private/grub
grub_config=/private/grub/grub.cfg
[cinnamon]
mode=auto
repository=/private/csb
remote=https://example.invalid/csb.git
branch=master
builder=build-cinnamon.sh
"""
FORBIDDEN = (
    "acquire_instance_lock", "install_runtime_traps", "initialize_dry_run_runtime",
    "initialize_runtime", "rotate_logs", "configure_logging", "print_start_banner",
    "emit_operation_started_event", "run_check_workflow", "run_apply_workflow",
    "run_dry_run_workflow", "date", "determine_stable_exit_code",
    "print_stable_exit_code_summary", "print_json_result", "emit_final_events",
)
PREFIX = r'''
source "$1"
SLACK_UPDATE_CONFIG=$2
TRACE=$3
CHANNEL=$4
channel_mode=$5
CONTROL=$6
shift 6
initialize_execution_environment() { printf 'environment\n' >> "$TRACE"; }
forbidden() {
    printf 'forbidden:%s\n' "$1" >> "$TRACE"
    printf 'ERROR: prohibited boundary: %s\n' "$1" >&2
    exit 97
}
apply_configuration() {
    [[ $CONTROL == valid ]] || forbidden apply_configuration
    printf 'application-callback\n' >> "$TRACE"
}
require_root() {
    [[ $CONTROL == valid ]] || forbidden require_root
    printf 'privilege-callback\n' >> "$TRACE"
    return 8
}
if [[ $channel_mode == open ]]; then exec 3>"$CHANNEL"; else exec 3>&-; fi
'''
DRIVER = PREFIX + "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN) + '\nmain "$@"\n'


def cases():
    result = [
        ("missing", "", "configuration file not found: {file}"),
        ("directory", "", "configuration file not found: {file}"),
        ("relative", "", "SLACK_UPDATE_CONFIG must be an absolute path"),
        ("file", "", "missing required configuration key: core.schema_version"),
        ("file", "schema_version=1\n", "{file}:1: key outside a section"),
        ("file", "[unknown]\n", "{file}:1: unknown section: unknown"),
        ("file", "[core]\nunknown=value\n", "{file}:2: unknown configuration key: core.unknown"),
        ("file", "[core]\nschema_version=1\nschema_version=1\n", "{file}:3: duplicate key: core.schema_version"),
        ("file", "not-an-assignment\n", "{file}:1: invalid configuration line"),
    ]
    for old, new, diagnostic in (
        ("schema_version=1", "schema_version=2", "unsupported configuration schema version: 2"),
        ("work_dir=/private/work\n", "", "missing required configuration key: core.work_dir"),
        ("install_new=true", "install_new=yes", "slackware.install_new must be true or false"),
        ("[flatpak]\nmode=auto", "[flatpak]\nmode=invalid", "flatpak.mode must be enabled, disabled, or auto"),
        ("work_dir=/private/work", "work_dir=relative", "path must be an absolute path"),
        ("kernel_package=kernel-generic", "kernel_package=kernel-generic kernel-huge", "boot.kernel_package must contain exactly one package name"),
        ("builder=build-cinnamon.sh", "builder=../build", "cinnamon.builder must be a safe relative path"),
        ("https://example.invalid/csb.git", "http://example.invalid/csb.git", "cinnamon.remote must use an explicit https:// URL"),
        ("scan_paths=/private/bin:/private/lib", "scan_paths=relative", "elf.scan_paths must be an absolute path"),
    ):
        assert BASELINE.count(old) == 1
        result.append(("file", BASELINE.replace(old, new), diagnostic))
    result.append(("valid", BASELINE, ""))
    return result


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-main-config-") as directory:
        work = Path(directory)
        fixture = work / "configuration with spaces.conf"
        missing = work / "absent.conf"
        config_directory = work / "config-directory"
        config_directory.mkdir()
        trace, channel = work / "trace", work / "channel"
        for kind, text, diagnostic in cases():
            fixture.write_text(text)
            override = {"missing": str(missing), "directory": str(config_directory),
                        "relative": "relative.conf"}.get(kind, str(fixture))
            valid = kind == "valid"
            for operation in ([], ["--check"], ["--dry-run"], ["--apply"]):
                for output in ([], ["--json"], ["--events"]):
                    for mode in ("closed", "open"):
                        trace.unlink(missing_ok=True)
                        channel.unlink(missing_ok=True)
                        arguments = [*operation, *output]
                        result = subprocess.run(
                            ["bash", "--noprofile", "--norc", "-c", DRIVER, "main-config-test",
                             str(REFERENCE), override, str(trace), str(channel), mode,
                             "valid" if valid else "invalid", *arguments],
                            cwd=work, capture_output=True, timeout=10)
                        label = (kind, diagnostic, arguments, mode)
                        assert result.returncode == (8 if valid else 7), (label, result.returncode, result.stderr)
                        assert result.stdout == b"", (label, result.stdout)
                        expected_error = b"" if valid else ("Error: " + diagnostic.format(file=override) + "\n").encode()
                        assert result.stderr == expected_error, (label, result.stderr, expected_error)
                        assert trace.is_file(), (label, "missing environment trace")
                        expected_trace = b"environment\n"
                        if valid:
                            expected_trace += b"application-callback\nprivilege-callback\n"
                        assert trace.read_bytes() == expected_trace, (label, trace.read_bytes())
                        if mode == "open":
                            assert channel.read_bytes() == b"", (label, channel.read_bytes())
                        else:
                            assert not channel.exists(), label
                        assert fixture.read_text() == text, "loader changed configuration input"
                        count += 1
    return count


def main():
    count = run_cases()
    print(f"Main configuration boundaries: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
