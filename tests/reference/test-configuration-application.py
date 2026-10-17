#!/usr/bin/env python3
"""Check configuration-to-runtime assignments without dispatching a workflow."""

from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
# Authored mapping; no assignments or expectations are extracted from the subject.
SCALARS = {
    "CONFIG_WORK_DIR": "WORKDIR_CONFIG", "CONFIG_LOG_DIR": "LOGDIR_CONFIG",
    "CONFIG_LOCK_FILE": "LOCKFILE", "CONFIG_LOG_RETENTION_DAYS": "LOG_RETENTION_DAYS",
    "CONFIG_PACKAGE_DATABASE": "PACKAGE_DATABASE",
    "CONFIG_SLACKWARE_INSTALL_NEW": "SLACKWARE_INSTALL_NEW",
    "CONFIG_SLACKWARE_UPGRADE_ALL": "SLACKWARE_UPGRADE_ALL",
    "CONFIG_FLATPAK_MODE": "FLATPAK_MODE", "CONFIG_SBO_MODE": "SBO_MODE",
    "CONFIG_SBOPKG_CONFIG": "SBOPKG_CONFIG",
    "CONFIG_SBO_QUEUE_DIR_FALLBACK": "SBO_QUEUE_DIR_FALLBACK",
    "CONFIG_SBO_PACKAGE_TAG": "SBO_PACKAGE_TAG", "CONFIG_SBO_OPTIONS_FILE": "SBO_OPTIONS_FILE",
    "CONFIG_ELF_MODE": "ELF_MODE", "CONFIG_BOOT_MODE": "BOOT_MODE",
    "CONFIG_MKINITRD_CONFIG": "MKINITRD_CONFIG",
    "CONFIG_INITRD_DEFAULT_OUTPUT": "INITRD_DEFAULT_OUTPUT",
    "CONFIG_INITRD_KERNEL_PACKAGE": "INITRD_KERNEL_PACKAGE",
    "CONFIG_KERNEL_MODULES_DIRECTORY": "KERNEL_MODULES_DIRECTORY",
    "CONFIG_GRUB_DIRECTORY": "GRUB_DIRECTORY", "CONFIG_GRUB_CONFIG": "GRUB_CONFIG",
    "CONFIG_CINNAMON_MODE": "CINNAMON_MODE", "CONFIG_CSB_REPOSITORY": "CSB_DIR_CONFIG",
    "CONFIG_CSB_REMOTE": "CSB_REMOTE", "CONFIG_CSB_BRANCH": "CSB_BRANCH",
    "CONFIG_CSB_BUILDER": "CSB_BUILDER",
}
ARRAYS = {
    "CONFIG_ABI_PACKAGES": "ABI_PACKAGES", "CONFIG_CINNAMON_ABI_PACKAGES": "CINNAMON_ABI",
    "CONFIG_CRITICAL_PACKAGES": "CRITICAL_PACKAGES", "CONFIG_KERNEL_PACKAGES": "KERNEL_PACKAGES",
    "CONFIG_KERNEL_BOOT_PACKAGES": "KERNEL_BOOT_PACKAGES",
    "CONFIG_KERNEL_HEADERS_PACKAGES": "KERNEL_HEADERS_PACKAGES",
}
HEADER = r'''
source "$1"
IFS=$2
batch_count=$3
shift 3
CONFIG_SCHEMA_VERSION=preserved-schema
CONFIG_ELF_SCAN_PATHS=preserved-scan-source
ELF_SCAN_PATHS=(untouched sentinel)
'''
SEED = "\n".join(f"{target}=stale" for target in SCALARS.values())
SEED += "\n" + "\n".join(f"{target}=(stale extra)" for target in ARRAYS.values())
RECORD = '\nrecord() {\n    printf \'%s\\0\' "$IFS"'
RECORD += "".join(f' "${target}"' for target in SCALARS.values())
RECORD += ' "$CONFIG_SCHEMA_VERSION" "$CONFIG_ELF_SCAN_PATHS"\n'
for array in ("ELF_SCAN_PATHS", *ARRAYS.values()):
    RECORD += f'''    printf '%s\\0' "${{#{array}[@]}}"
    for item in "${{{array}[@]}}"; do printf '%s\\0' "$item"; done
'''
RECORD += "}\n"
LOOP = r'''
for (( batch=0; batch<batch_count; batch++ )); do
    pairs=$1
    shift
    for (( pair=0; pair<pairs; pair++ )); do
        printf -v "$1" '%s' "$2"
        shift 2
    done
    apply_configuration
    status=$?
    (( status == 0 )) || exit "$status"
    record
done
'''
DRIVER = HEADER + SEED + RECORD + LOOP


def baseline():
    scalars = {key: "value-" + target for key, target in SCALARS.items()}
    arrays = {key: [target.lower() + "_one", target.lower() + "_two"] for key, target in ARRAYS.items()}
    values = dict(scalars)
    values.update({key: " ".join(items) for key, items in arrays.items()})
    return values, arrays


def cases():
    values, arrays = baseline()
    result = [(values, arrays)]
    for key in SCALARS:
        updated = dict(values)
        updated[key] = "text with spaces ñ\t'quoted'\\path\n$literal;not-executed"
        result.append((updated, arrays))
    for key in ARRAYS:
        for text, wanted in (
            ("", []), ("single", ["single"]), ("one two three", ["one", "two", "three"]),
            ("  one  two ", ["one", "two"]),
            ("gtk+3 gcc_compat foo-bar zlib.1", ["gtk+3", "gcc_compat", "foo-bar", "zlib.1"]),
            (r"literal\name next", [r"literal\name", "next"]),
            ("left\tright next", ["left\tright", "next"]),
        ):
            updated = dict(values)
            updated[key] = text
            expected = dict(arrays)
            expected[key] = wanted
            result.append((updated, expected))
    empty_scalars = dict(values)
    empty_scalars.update({key: "" for key in SCALARS})
    result.append((empty_scalars, arrays))
    empty_arrays = dict(values)
    empty_arrays.update({key: "" for key in ARRAYS})
    result.append((empty_arrays, {key: [] for key in ARRAYS}))
    return result


def framed(items):
    return b"".join(str(item).encode("utf-8") + b"\0" for item in items)


def check_batches(ifs, batches):
    arguments = []
    expected = b""
    for values, arrays in batches:
        arguments.append(str(len(values)))
        for key, value in values.items():
            arguments.extend((key, value))
        record = [ifs, *(values[key] for key in SCALARS), "preserved-schema", "preserved-scan-source",
                  2, "untouched", "sentinel"]
        for key in ARRAYS:
            record.extend((len(arrays[key]), *arrays[key]))
        expected += framed(record)
    result = subprocess.run(
        ["bash", "--noprofile", "--norc", "-c", DRIVER, "config-application-test",
         str(REFERENCE), ifs, str(len(batches)), *arguments],
        cwd=ROOT, capture_output=True, timeout=10)
    assert result.returncode == 0, (ifs, result.returncode, result.stderr)
    assert result.stderr == b"", result.stderr
    assert result.stdout == expected, (ifs, result.stdout, expected)


def run_cases():
    count = 0
    all_cases = cases()
    for ifs in ("\n\t", " ", "|:", ""):
        for case in all_cases:
            check_batches(ifs, [case])
            count += 1
        # Reapply after changing every scalar and clearing every array. Verify
        # stale runtime elements disappear, then restore the original state.
        values, arrays = baseline()
        replacement = {key: "second-" + key for key in SCALARS}
        replacement.update({key: "" for key in ARRAYS})
        check_batches(ifs, [(values, arrays), (replacement, {key: [] for key in ARRAYS}), (values, arrays)])
        count += 1
    return count


def main():
    count = run_cases()
    print(f"Configuration application: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
