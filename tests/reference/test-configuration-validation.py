#!/usr/bin/env python3
"""Validate supplied configuration state without applying settings or workflows."""

from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
# Authored complete, semantically valid state; paths need not exist on the host.
SETTINGS = {
    "core.schema_version": ("CONFIG_SCHEMA_VERSION", "1"),
    "core.work_dir": ("CONFIG_WORK_DIR", "/private/work"),
    "core.log_dir": ("CONFIG_LOG_DIR", "/private/log"),
    "core.lock_file": ("CONFIG_LOCK_FILE", "/private/lock"),
    "core.log_retention_days": ("CONFIG_LOG_RETENTION_DAYS", "30"),
    "core.package_database": ("CONFIG_PACKAGE_DATABASE", "/private/packages"),
    "slackware.install_new": ("CONFIG_SLACKWARE_INSTALL_NEW", "true"),
    "slackware.upgrade_all": ("CONFIG_SLACKWARE_UPGRADE_ALL", "true"),
    "flatpak.mode": ("CONFIG_FLATPAK_MODE", "auto"),
    "sbo.mode": ("CONFIG_SBO_MODE", "auto"),
    "sbo.sbopkg_config": ("CONFIG_SBOPKG_CONFIG", "/private/sbopkg.conf"),
    "sbo.queue_dir_fallback": ("CONFIG_SBO_QUEUE_DIR_FALLBACK", "/private/queues"),
    "sbo.package_tag": ("CONFIG_SBO_PACKAGE_TAG", "_SBo"),
    "sbo.options_file": ("CONFIG_SBO_OPTIONS_FILE", "/private/options.sqf"),
    "elf.mode": ("CONFIG_ELF_MODE", "auto"),
    "elf.scan_paths": ("CONFIG_ELF_SCAN_PATHS", "/private/bin:/private/lib"),
    "packages.abi": ("CONFIG_ABI_PACKAGES", "glibc gcc"),
    "packages.cinnamon_abi": ("CONFIG_CINNAMON_ABI_PACKAGES", "mesa gtk+3"),
    "packages.critical": ("CONFIG_CRITICAL_PACKAGES", "glibc dbus"),
    "packages.kernel": ("CONFIG_KERNEL_PACKAGES", "kernel-generic kernel-headers"),
    "packages.kernel_boot": ("CONFIG_KERNEL_BOOT_PACKAGES", "kernel-generic"),
    "packages.kernel_headers": ("CONFIG_KERNEL_HEADERS_PACKAGES", "kernel-headers"),
    "boot.mode": ("CONFIG_BOOT_MODE", "auto"),
    "boot.mkinitrd_config": ("CONFIG_MKINITRD_CONFIG", "/private/mkinitrd.conf"),
    "boot.initrd_default_output": ("CONFIG_INITRD_DEFAULT_OUTPUT", "/private/initrd.gz"),
    "boot.kernel_package": ("CONFIG_INITRD_KERNEL_PACKAGE", "kernel-generic"),
    "boot.modules_directory": ("CONFIG_KERNEL_MODULES_DIRECTORY", "/private/modules"),
    "boot.grub_directory": ("CONFIG_GRUB_DIRECTORY", "/private/grub"),
    "boot.grub_config": ("CONFIG_GRUB_CONFIG", "/private/grub/grub.cfg"),
    "cinnamon.mode": ("CONFIG_CINNAMON_MODE", "auto"),
    "cinnamon.repository": ("CONFIG_CSB_REPOSITORY", "/private/csb"),
    "cinnamon.remote": ("CONFIG_CSB_REMOTE", "https://example.invalid/csb.git"),
    "cinnamon.branch": ("CONFIG_CSB_BRANCH", "master"),
    "cinnamon.builder": ("CONFIG_CSB_BUILDER", "build-cinnamon.sh"),
}
MODES = ("flatpak.mode", "sbo.mode", "elf.mode", "boot.mode", "cinnamon.mode")
PATHS = (
    "core.work_dir", "core.log_dir", "core.lock_file", "core.package_database",
    "sbo.sbopkg_config", "sbo.queue_dir_fallback", "sbo.options_file",
    "boot.mkinitrd_config", "boot.initrd_default_output", "boot.modules_directory",
    "boot.grub_directory", "boot.grub_config", "cinnamon.repository",
)
PACKAGES = ("packages.abi", "packages.cinnamon_abi", "packages.critical",
            "packages.kernel", "packages.kernel_boot", "packages.kernel_headers")
DRIVER = r'''
source "$1"
shift
initialize_configuration_state
while (( $# )); do
    printf -v "$1" '%s' "$2"
    shift 2
done
ELF_SCAN_PATHS=(stale)
before_ifs=$IFS
apply_configuration() { printf 'unexpected apply\n' >&2; exit 97; }
validate_configuration
status=$?
printf '%s\0' "$IFS"
if (( status == 0 )); then
    printf '%s\0' "${#ELF_SCAN_PATHS[@]}" "${ELF_SCAN_PATHS[@]}"
fi
[[ $IFS == "$before_ifs" ]] || exit 98
exit "$status"
'''


def scenarios():
    result = [({}, "")]
    for key in ("slackware.install_new", "slackware.upgrade_all"):
        result.append(({key: "false"}, ""))
    for key in MODES:
        for value in ("enabled", "disabled", "auto"):
            result.append(({key: value}, ""))
    for key in PATHS:
        result.append(({key: "/private/path with spaces"}, ""))
    for value in ("0", "365", "00030"):
        result.append(({"core.log_retention_days": value}, ""))
    for key in PACKAGES:
        result.append(({key: "libA gtk+3 gcc-14 gcc_compat zlib.1"}, ""))
    for key, value in (
        ("sbo.package_tag", "_SBo-test+1.0"),
        ("cinnamon.branch", "current/test_1.2-3"),
        ("cinnamon.builder", "sub/build-cinnamon.sh"),
        ("elf.scan_paths", "/private/one:/private/two:/private/three"),
    ):
        result.append(({key: value}, ""))

    # Each required value is independently removed from the otherwise valid state.
    for key in SETTINGS:
        if key not in MODES:
            result.append(({key: ""}, "missing required configuration key: " + key))
    for value in ("0", "2", "01", "unsupported"):
        result.append(({"core.schema_version": value}, "unsupported configuration schema version: " + value))
    for value in ("-1", "+2", "1.5", "3d", " 3"):
        result.append(({"core.log_retention_days": value}, "core.log_retention_days must be a non-negative integer"))
    for key in ("slackware.install_new", "slackware.upgrade_all"):
        for value in ("yes", "True", "1", "false # comment"):
            result.append(({key: value}, key + " must be true or false"))
    for key in MODES:
        for value in ("true", "AUTO", "enabled ", ""):
            result.append(({key: value}, key + " must be enabled, disabled, or auto"))
    for key in PATHS:
        result.append(({key: "relative/path"}, "path must be an absolute path"))
    for key in (*PACKAGES, "boot.kernel_package"):
        for value in ("bad/name", "name$var"):
            result.append(({key: value}, key + " contains an invalid package name: " + value))
    result.append(({"boot.kernel_package": "kernel-generic kernel-huge"},
                   "boot.kernel_package must contain exactly one package name"))
    for value in ("a b", "a/b", "x$"):
        result.append(({"sbo.package_tag": value}, "sbo.package_tag contains unsupported characters"))
    for value in ("-branch", "with space", "branch;cmd"):
        result.append(({"cinnamon.branch": value}, "cinnamon.branch contains unsupported characters"))
    for value in ("/absolute", "..", "../build", "sub/../build", "sub/..", "build;cmd", "build with space", "build$"):
        result.append(({"cinnamon.builder": value}, "cinnamon.builder must be a safe relative path"))
    for value, error in (
        ("http://example.invalid/csb.git", "cinnamon.remote must use an explicit https:// URL"),
        ("git@example.invalid:csb.git", "cinnamon.remote must use an explicit https:// URL"),
        ("-https://example.invalid/csb.git", "cinnamon.remote contains unsupported characters"),
        ("https://example.invalid/two words", "cinnamon.remote contains unsupported characters"),
    ):
        result.append(({"cinnamon.remote": value}, error))
    for value in (":/private/bin", "/private/bin::/private/lib", "relative:/private/lib", "/private/bin:relative"):
        result.append(({"elf.scan_paths": value}, "elf.scan_paths must be an absolute path"))
    result.extend([
        ({"core.schema_version": "", "slackware.install_new": "bad"}, "missing required configuration key: core.schema_version"),
        ({"slackware.install_new": "bad", "core.work_dir": "relative"}, "slackware.install_new must be true or false"),
        ({"boot.kernel_package": "two packages", "elf.scan_paths": "relative"}, "boot.kernel_package must contain exactly one package name"),
    ])
    return result


def run_cases():
    count = 0
    for changes, error in scenarios():
        values = {key: value for key, (_, value) in SETTINGS.items()}
        values.update(changes)
        arguments = []
        for key, value in values.items():
            arguments.extend((SETTINGS[key][0], value))
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", "-c", DRIVER, "config-validation-test",
             str(REFERENCE), *arguments], cwd=ROOT, capture_output=True, timeout=10)
        assert result.returncode == (1 if error else 0), (changes, result.returncode, result.stderr)
        assert result.stderr == (("Error: " + error + "\n").encode() if error else b""), (changes, result.stderr)
        expected = b"\n\t\0"
        if not error:
            paths = values["elf.scan_paths"].split(":")
            expected += str(len(paths)).encode() + b"\0"
            expected += b"".join(path.encode() + b"\0" for path in paths)
        assert result.stdout == expected, (changes, result.stdout, expected)
        count += 1
    return count


def main():
    count = run_cases()
    print(f"Configuration validation: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
