#!/usr/bin/env python3
"""Check ABI/kernel change detection using private snapshots and the real boot policy."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
ABI_NAMES = ("openssl", "gtk+3", "glibc")
KERNEL_NAMES = ("kernel-generic", "kernel-modules", "kernel-headers", "kernel-firmware", "kernel-source")


def records(*names):
    return "".join(name + "-1.0-x86_64-1\n" for name in names)


# name, before bytes (None means missing), after bytes, authored changed-name list, configured names
ABI_PROFILES = (
    ("same", records(*ABI_NAMES), records(*ABI_NAMES), (), ABI_NAMES),
    ("openssl-version", records("openssl"), "openssl-2.0-x86_64-1\n", ("openssl",), ABI_NAMES),
    ("graphics", records("gtk+3"), "gtk+3-2.0-x86_64-1\n", ("gtk+3",), ABI_NAMES),
    ("critical", records("glibc"), "glibc-2.0-x86_64-1\n", ("glibc",), ABI_NAMES),
    ("all", "", records(*ABI_NAMES), ABI_NAMES, ABI_NAMES),
    ("new", "", records("openssl"), ("openssl",), ABI_NAMES),
    ("removed", records("openssl"), "", ("openssl",), ABI_NAMES),
    ("prefix", records("openssl"), records("openssl", "openssl-solibs", "gtk+30"), (), ABI_NAMES),
    ("normalized", "/private/path/openssl-1.0-x86_64-1.txz\n", records("openssl"), (), ABI_NAMES),
    ("build", records("openssl"), "openssl-1.0-x86_64-2\n", ("openssl",), ABI_NAMES),
    ("arch", records("openssl"), "openssl-1.0-i586-1\n", ("openssl",), ABI_NAMES),
    ("no-newline", records("gtk+3"), "gtk+3-2.0-x86_64-1", ("gtk+3",), ABI_NAMES),
    ("same-no-newline", records("gtk+3"), "gtk+3-1.0-x86_64-1", (), ABI_NAMES),
    ("invalid", records("openssl"), records("openssl") + "bad\npackage name-1.0-x86_64-1\n", (), ABI_NAMES),
    ("order", "openssl-1.0-x86_64-1\nopenssl-2.0-x86_64-1\n", "openssl-2.0-x86_64-1\nopenssl-1.0-x86_64-1\n", ("openssl",), ABI_NAMES),
    ("duplicate-record", records("openssl"), records("openssl", "openssl"), ("openssl",), ABI_NAMES),
    ("duplicate-list", "", records("openssl"), ("openssl", "openssl"), ("openssl", "openssl")),
    ("empty-list", "", records("openssl"), (), ()),
    ("missing-before", None, records("openssl"), ("openssl",), ABI_NAMES),
    ("missing-after", records("openssl"), None, ("openssl",), ABI_NAMES),
    ("missing-both", None, None, (), ABI_NAMES),
)
KERNEL_PROFILES = (
    ("same", records(*KERNEL_NAMES), records(*KERNEL_NAMES), (), KERNEL_NAMES),
    *((name, records(name), name + "-2.0-x86_64-1\n", (name,), KERNEL_NAMES) for name in KERNEL_NAMES),
    ("all", "", records(*KERNEL_NAMES), KERNEL_NAMES, KERNEL_NAMES),
    ("new", "", records("kernel-generic"), ("kernel-generic",), KERNEL_NAMES),
    ("removed", records("kernel-modules"), "", ("kernel-modules",), KERNEL_NAMES),
    ("prefix", records("kernel-headers"), records("kernel-headers", "kernel-headers-extra"), (), KERNEL_NAMES),
    ("normalized", "/private/path/kernel-headers-1.0-x86_64-1.tgz\n", records("kernel-headers"), (), KERNEL_NAMES),
    ("invalid", "bad\n", "package name-1.0-x86_64-1\n", (), KERNEL_NAMES),
    ("order", "kernel-headers-1.0-x86_64-1\nkernel-headers-2.0-x86_64-1\n", "kernel-headers-2.0-x86_64-1\nkernel-headers-1.0-x86_64-1\n", ("kernel-headers",), KERNEL_NAMES),
    ("duplicate-list", "", records("kernel-headers"), ("kernel-headers", "kernel-headers"), ("kernel-headers", "kernel-headers")),
    ("empty-list", "", records("kernel-generic"), (), ()),
    ("missing-before", None, records("kernel-generic"), ("kernel-generic",), KERNEL_NAMES),
    ("missing-after", records("kernel-headers"), None, ("kernel-headers",), KERNEL_NAMES),
    ("missing-both", None, None, (), KERNEL_NAMES),
)
PREFIX = r'''
source "$1"
BEFORE_PKGS=$2
AFTER_PKGS=$3
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
function [ {
    case "${1-}" in
        -f) [[ $2 == "$BEFORE_PKGS" || $2 == "$AFTER_PKGS" ]] || forbidden snapshot-path ;;
        -d|-r|-s|-x|-L) forbidden unexpected-path-predicate ;;
    esac
    builtin [ "$@"
}
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "run_boot_preparation_module",
             "capture_validated_package_snapshot", "validate_package_snapshot", "probe_optional_modules", "probe_boot_module",
             "regenerate_initrd", "update_grub_configuration", "emit_event", "slackpkg", "flatpak", "sbopkg", "sqg",
             "mkinitrd", "geninitrd", "grub-mkconfig", "git", "curl", "wget", "find", "sort", "rm", "mv", "mktemp")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = ("ABI_TRIGGER", "CINNAMON_TRIGGER", "KERNEL_TRIGGER", "INITRD_UPDATE", "GRUB_UPDATE", "INITRD_REQUIRED", "GRUB_REQUIRED",
          "CINNAMON_MODULE_RUN", "CINNAMON_MODE", "CINNAMON_MODULE_STATE", "BOOT_MODE", "BOOT_PREPARATION_LAYOUT",
          "BOOT_INITRD_AVAILABLE", "BOOT_GRUB_AVAILABLE", "INITRD_OK", "GRUB_OK", "SLACKWARE_PACKAGE_NAME")


def cases():
    for profile, mode, run, abi, cinnamon in itertools.product(ABI_PROFILES, ("auto", "enabled", "disabled"), (0, 1), (0, 1), (0, 2, 3)):
        yield "abi", profile, dict(CINNAMON_MODE=mode, CINNAMON_MODULE_RUN=run, ABI_TRIGGER=abi, CINNAMON_TRIGGER=cinnamon)
    for profile, mode, layout, available, requested, seed in itertools.product(
            KERNEL_PROFILES, ("auto", "enabled", "disabled"), ("mkinitrd-managed", "direct-generic-no-initrd"),
            itertools.product((0, 1), repeat=2), itertools.product((0, 1), repeat=2), (0, 1)):
        yield "kernel", profile, dict(BOOT_MODE=mode, BOOT_PREPARATION_LAYOUT=layout, BOOT_INITRD_AVAILABLE=available[0],
                                     BOOT_GRUB_AVAILABLE=available[1], INITRD_UPDATE=requested[0], GRUB_UPDATE=requested[1], KERNEL_TRIGGER=seed)


def initial(override):
    return dict(ABI_TRIGGER=0, CINNAMON_TRIGGER=0, KERNEL_TRIGGER=0, INITRD_UPDATE=0, GRUB_UPDATE=0, INITRD_REQUIRED=9, GRUB_REQUIRED=9,
                CINNAMON_MODULE_RUN=0, CINNAMON_MODE="auto", CINNAMON_MODULE_STATE="supplied-state", BOOT_MODE="auto",
                BOOT_PREPARATION_LAYOUT="mkinitrd-managed", BOOT_INITRD_AVAILABLE=1, BOOT_GRUB_AVAILABLE=1,
                INITRD_OK=7, GRUB_OK=8, SLACKWARE_PACKAGE_NAME="outer-parser-name") | override


def expected(kind, profile, override):
    values = initial(override)
    changed = profile[3]
    critical = []
    lines = []
    if kind == "abi":
        lines.append("[3] Detectando cambios ABI")
        if changed:
            values["ABI_TRIGGER"] = 1
        for name in changed:
            lines.append("  ABI change: " + name)
            if name in ("openssl", "glibc"):
                critical.append(name)
            if name in ("openssl", "gtk+3"):
                if values["CINNAMON_MODULE_RUN"]:
                    values["CINNAMON_TRIGGER"] = 1
                    lines.append("   -> Cinnamon rebuild required")
                else:
                    lines.append("   -> Cinnamon trigger ignored: mode=" + values["CINNAMON_MODE"] + ", state=supplied-state")
        if not values["ABI_TRIGGER"]:
            lines.append("  Sin cambios ABI relevantes")
        if not values["CINNAMON_TRIGGER"]:
            lines.append("  Sin cambios en pila grafica de Cinnamon")
        if critical:
            lines.append("  [WARN] Paquetes criticos actualizados que requieren reinicio: " + "|".join(critical))
    else:
        critical = ["stale-critical"]
        lines.append("[4] Detectando cambios en kernel")
        if changed:
            values["KERNEL_TRIGGER"] = 1
        for name in changed:
            lines.append("  Kernel actualizado: " + name)
            if name == "kernel-headers":
                lines.append("  [INFO] kernel-headers actualizado: puede requerir recompilacion de modulos externos")
        image_changed = any(name in ("kernel-generic", "kernel-modules") for name in changed)
        requests = (1, 1) if image_changed else (values["INITRD_UPDATE"], values["GRUB_UPDATE"])
        direct = values["BOOT_PREPARATION_LAYOUT"] == "direct-generic-no-initrd"
        required = (0 if direct else requests[0], requests[1])
        # Authored policy truth table: required flags survive disabled/auto filtering.
        selected = {
            "disabled": (0, 0),
            "enabled": required,
            "auto": (required[0] * values["BOOT_INITRD_AVAILABLE"], required[1] * values["BOOT_GRUB_AVAILABLE"]),
        }[values["BOOT_MODE"]]
        values.update(INITRD_REQUIRED=required[0], GRUB_REQUIRED=required[1], INITRD_UPDATE=selected[0], GRUB_UPDATE=selected[1])
        if not values["KERNEL_TRIGGER"]:
            lines.append("  Sin cambios de kernel")
        elif values["BOOT_MODE"] == "disabled":
            lines.append("  [INFO] Boot preparation disabled by configuration")
        elif values["BOOT_MODE"] == "auto":
            if required[0] and not selected[0]:
                lines.append("  [INFO] initrd preparation not applicable in auto mode")
            if required[1] and not selected[1]:
                lines.append("  [INFO] GRUB preparation not applicable in auto mode")
    return values, critical, ("\n".join(lines) + "\n").encode()


def run_case(work, kind, profile, override):
    before, after = work / "before snapshot", work / "after snapshot"
    for path, text in ((before, profile[1]), (after, profile[2])):
        path.unlink(missing_ok=True)
        if text is not None:
            path.write_text(text)
    values = initial(override)
    reset = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in values.items())
    arrays = dict(ABI_PACKAGES=profile[4] if kind == "abi" else ABI_NAMES, CRITICAL_PACKAGES=("openssl", "glibc"),
                  CINNAMON_ABI=("openssl", "gtk+3"), KERNEL_PACKAGES=profile[4] if kind == "kernel" else KERNEL_NAMES,
                  KERNEL_BOOT_PACKAGES=("kernel-generic", "kernel-modules"), KERNEL_HEADERS_PACKAGES=("kernel-headers",))
    array_reset = "\n".join(name + "=(" + " ".join(shlex.quote(value) for value in content) + ")" for name, content in arrays.items())
    function = "detect_abi_changes" if kind == "abi" else "detect_kernel_changes"
    output = 'printf \'RESULT\\0%s\\0\' "$status"; printf \'%s\\0\' ' + " ".join(f'"${{{name}}}"' for name in FIELDS) + ' "$IFS" "${#CRITICAL_UPDATED[@]}"\n'
    output += 'printf \'%s\\0\' "${CRITICAL_UPDATED[@]}"\n'
    for name in arrays:
        output += f'printf \'%s\\0\' "${{{name}[@]}}"\n'
    script = PREFIX + GUARDS + "\nIFS='|: '\nfor repetition in 1 2; do\n" + reset + "\n" + array_reset + "\nCRITICAL_UPDATED=(stale-critical)\n" + function + '\nstatus=$?\n' + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "package-change-test", str(REFERENCE), str(before), str(after)],
                            capture_output=True, timeout=10)
    expected_values, critical, text = expected(kind, profile, override)
    packet = text + b"RESULT\0" + b"0\0" + b"".join(str(field).encode() + b"\0" for field in (*[expected_values[name] for name in FIELDS], "|: ", len(critical)))
    packet += b"".join(name.encode() + b"\0" for name in critical) if critical else b"\0"
    for content in arrays.values():
        packet += b"".join(name.encode() + b"\0" for name in content) if content else b"\0"
    identity = kind, profile[0], override
    assert result.returncode == 0, (identity, "driver", result.returncode, result.stderr)
    assert result.stderr == b"", (identity, "stderr", result.stderr)
    assert result.stdout == packet * 2, (identity, "stdout", result.stdout, packet * 2)
    assert sorted(path.name for path in work.iterdir()) == sorted(path.name for path, text in ((before, profile[1]), (after, profile[2])) if text is not None), (identity, "inventory")
    for path, text in ((before, profile[1]), (after, profile[2])):
        if text is not None:
            assert path.read_bytes() == text.encode(), (identity, "snapshot changed")


def main():
    counts = dict(abi=0, kernel=0)
    with tempfile.TemporaryDirectory(prefix="slack-update package changes ") as temporary:
        for kind, profile, override in cases():
            run_case(Path(temporary), kind, profile, override)
            counts[kind] += 1
    total = sum(counts.values())
    print(f"Package change detection: {counts['abi']} ABI scenarios, {counts['kernel']} kernel scenarios, {total * 2} detector entries, 0 failures")


if __name__ == "__main__":
    main()
