#!/usr/bin/env python3
"""Check configuration text parsing with private files, without applying it."""

from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
# Authored public-key to parser-state mapping; never extracted from the subject.
KEYS = {
    "core.schema_version": "CONFIG_SCHEMA_VERSION",
    "core.work_dir": "CONFIG_WORK_DIR",
    "core.log_dir": "CONFIG_LOG_DIR",
    "core.lock_file": "CONFIG_LOCK_FILE",
    "core.log_retention_days": "CONFIG_LOG_RETENTION_DAYS",
    "core.package_database": "CONFIG_PACKAGE_DATABASE",
    "slackware.install_new": "CONFIG_SLACKWARE_INSTALL_NEW",
    "slackware.upgrade_all": "CONFIG_SLACKWARE_UPGRADE_ALL",
    "flatpak.mode": "CONFIG_FLATPAK_MODE",
    "sbo.mode": "CONFIG_SBO_MODE",
    "sbo.sbopkg_config": "CONFIG_SBOPKG_CONFIG",
    "sbo.queue_dir_fallback": "CONFIG_SBO_QUEUE_DIR_FALLBACK",
    "sbo.package_tag": "CONFIG_SBO_PACKAGE_TAG",
    "sbo.options_file": "CONFIG_SBO_OPTIONS_FILE",
    "elf.mode": "CONFIG_ELF_MODE",
    "elf.scan_paths": "CONFIG_ELF_SCAN_PATHS",
    "packages.abi": "CONFIG_ABI_PACKAGES",
    "packages.cinnamon_abi": "CONFIG_CINNAMON_ABI_PACKAGES",
    "packages.critical": "CONFIG_CRITICAL_PACKAGES",
    "packages.kernel": "CONFIG_KERNEL_PACKAGES",
    "packages.kernel_boot": "CONFIG_KERNEL_BOOT_PACKAGES",
    "packages.kernel_headers": "CONFIG_KERNEL_HEADERS_PACKAGES",
    "boot.mode": "CONFIG_BOOT_MODE",
    "boot.mkinitrd_config": "CONFIG_MKINITRD_CONFIG",
    "boot.initrd_default_output": "CONFIG_INITRD_DEFAULT_OUTPUT",
    "boot.kernel_package": "CONFIG_INITRD_KERNEL_PACKAGE",
    "boot.modules_directory": "CONFIG_KERNEL_MODULES_DIRECTORY",
    "boot.grub_directory": "CONFIG_GRUB_DIRECTORY",
    "boot.grub_config": "CONFIG_GRUB_CONFIG",
    "cinnamon.mode": "CONFIG_CINNAMON_MODE",
    "cinnamon.repository": "CONFIG_CSB_REPOSITORY",
    "cinnamon.remote": "CONFIG_CSB_REMOTE",
    "cinnamon.branch": "CONFIG_CSB_BRANCH",
    "cinnamon.builder": "CONFIG_CSB_BUILDER",
}
DEFAULTS = {key: "" for key in KEYS}
DEFAULTS.update({key: "auto" for key in (
    "flatpak.mode", "sbo.mode", "elf.mode", "boot.mode", "cinnamon.mode")})
DEFAULTS.update({"sbo.options_file": "/etc/slack-update/sbo-options.sqf",
                 "boot.kernel_package": "kernel-generic",
                 "boot.modules_directory": "/lib/modules"})
DRIVER = r'''
source "$1"
CONFIG_FILE=$2
shift 2
for name in "$@"; do
    printf -v "$name" stale
done
SEEN_CONFIG_KEYS=stale
initialize_configuration_state
parse_configuration_file
status=$?
for name in "$@"; do
    printf '%s\0' "${!name}"
done
printf '%s\0' "$SEEN_CONFIG_KEYS"
exit "$status"
'''


def framed(values):
    return b"".join(value.encode("utf-8") + b"\0" for value in values)


def successes():
    result = [(b"", {}), (b"\n # comment\n\t; comment\r\n", {})]
    # Each key gets a unique value so cross-assignment cannot pass unnoticed.
    for key in KEYS:
        section, name = key.split(".")
        value = "literal-" + key
        result.append((f"[{section}]\n{name}={value}\n".encode(), {key: value}))
    all_values = {key: "all-" + key for key in KEYS}
    text = "".join(f"[{key.split('.')[0]}]\n{key.split('.')[1]}={value}\n"
                   for key, value in all_values.items())
    result.append((text.encode(), all_values))
    for text, value in (
        ("[core]\nwork_dir=/private/path", "/private/path"),
        ("[ core ]\r\n work_dir \t= \t/private/path \r\n", "/private/path"),
        ("[core]\nwork_dir=\n", ""),
        ("[core]\nwork_dir=a=b=c\n", "a=b=c"),
        ("[core]\nwork_dir=two  words\n", "two  words"),
        ("[core]\nwork_dir='quoted value'\n", "'quoted value'"),
        ('[core]\nwork_dir="quoted value"\n', '"quoted value"'),
        ("[core]\nwork_dir=/path # literal ; suffix\n", "/path # literal ; suffix"),
        ("[core]\nwork_dir=ñandú\\path\n", "ñandú\\path"),
        ("[core]\nwork_dir=$VARIABLE ${OTHER} ~/*.conf\n", "$VARIABLE ${OTHER} ~/*.conf"),
        ("[core]\nwork_dir=$(printf executed > marker)\n", "$(printf executed > marker)"),
        ("[core]\nwork_dir=`printf executed > marker`\n", "`printf executed > marker`"),
        ("[core]\nwork_dir=/path; printf executed > marker\n", "/path; printf executed > marker"),
    ):
        result.append((text.encode("utf-8"), {"core.work_dir": value}))
    result.append((b"[core]\nwork_dir=one\n[sbo]\nmode=disabled\n[core]\nlog_dir=two\n",
                   {"core.work_dir": "one", "sbo.mode": "disabled", "core.log_dir": "two"}))
    return result


def failures():
    return [
        (b"key=value\n", 1, "key outside a section"),
        (b"\n# comment\nkey=value", 3, "key outside a section"),
        (b"[unknown]\n", 1, "unknown section: unknown"),
        (b"[CORE]\n", 1, "unknown section: CORE"),
        (b"[]\n", 1, "unknown section: "),
        (b"[[core]]\n", 1, "unknown section: [core]"),
        (b"[core]\nunknown=value\n", 2, "unknown configuration key: core.unknown"),
        (b"[core]\nmode=auto\n", 2, "unknown configuration key: core.mode"),
        (b"[core]\nWork_dir=x\n", 2, "invalid key: Work_dir"),
        (b"[core]\nwork-dir=x\n", 2, "invalid key: work-dir"),
        (b"[core]\nwork dir=x\n", 2, "invalid key: work dir"),
        (b"[core]\n=x\n", 2, "invalid key: "),
        (b"[core]\nwork_dir=x\nwork_dir=y\n", 3, "duplicate key: core.work_dir"),
        (b"[core]\nwork_dir=\n[core]\nwork_dir=x", 4, "duplicate key: core.work_dir"),
        (b"[core]\nwork_dir=x\n[sbo]\nmode=auto\n[core]\nwork_dir=x\n", 6, "duplicate key: core.work_dir"),
        (b"[core]\r\nwork_dir=x\r\nwork_dir=y\r\n", 3, "duplicate key: core.work_dir"),
        (b"[core\n", 1, "invalid configuration line"),
        (b"[core] # comment\n", 1, "invalid configuration line"),
        (b"[core]\nexport work_dir=x\n", 2, "invalid key: export work_dir"),
        (b"[core]\nnot-an-assignment\n", 2, "invalid configuration line"),
        (b"[core]\nunknown=x\nwork_dir=a\nwork_dir=b\n", 2, "unknown configuration key: core.unknown"),
    ]


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-config-parser-") as directory:
        work = Path(directory)
        fixture = work / "configuration with spaces.conf"
        for raw, assignments in successes():
            fixture.write_bytes(raw)
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c", DRIVER, "config-parser-test",
                 str(REFERENCE), str(fixture), *KEYS.values()],
                cwd=work, capture_output=True, timeout=10)
            wanted = dict(DEFAULTS)
            wanted.update(assignments)
            seen = "|" + "".join(key + "|" for key in assignments)
            assert result.returncode == 0, (raw, result.returncode, result.stderr)
            assert result.stderr == b"", (raw, result.stderr)
            assert result.stdout == framed([*wanted.values(), seen]), (raw, result.stdout, wanted)
            assert fixture.read_bytes() == raw, "parser changed its input"
            assert not (work / "marker").exists(), "literal text was executed"
            count += 1
        for raw, line, diagnostic in failures():
            fixture.write_bytes(raw)
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c", DRIVER, "config-parser-test",
                 str(REFERENCE), str(fixture), *KEYS.values()],
                cwd=work, capture_output=True, timeout=10)
            assert result.returncode == 1, (raw, result.returncode)
            wanted_error = f"Error: {fixture}:{line}: {diagnostic}\n".encode()
            assert result.stderr == wanted_error, (raw, result.stderr, wanted_error)
            fields = result.stdout.split(b"\0")
            assert len(fields) == len(KEYS) + 2 and fields[-1] == b"", (raw, result.stdout)
            assert fixture.read_bytes() == raw, "parser changed its input"
            count += 1
    return count


def main():
    count = run_cases()
    print(f"Configuration parser: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
