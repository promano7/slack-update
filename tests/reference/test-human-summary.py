#!/usr/bin/env python3
"""Check exact human summaries from supplied state and real private text files."""

from pathlib import Path
import itertools
import os
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
MODULES = ("FLATPAK", "SBO", "ELF", "CINNAMON", "BOOT")
LABELS = ("Flatpak", "SBo", "ELF", "Cinnamon", "Boot")
PENDING = {"zero": b"ignored list\n", "lines": b"/private/a space.new\n/private/back\\slash.new\n",
           "tail": b"/private/a.new\n\n/private/last.new", "invalid": b"ignored invalid\n", "invalid-empty": b""}
BROKEN = {"empty": b"", "lines": b"/private/one\n/private/two with space\n",
          "tail": b"/private/tail", "link": b"/private/linked\n"}
BASE = dict(kind="apply", snapshot=3, pending="zero", blocked=0, abi=0, cinnamon=0,
            boot="none", critical=0, queues=0, broken="empty", clock=0, modules=0, check=0)
BOOT = ("none", "other-trigger", "initrd-skip", "initrd-ok", "initrd-fail", "initrd-error",
        "direct-ok", "direct-error", "direct-quiet", "other-layout", "grub-skip", "grub-blocked",
        "grub-ok", "grub-fail", "grub-error", "both-failed")
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
date() { [[ $# == 0 ]] || forbidden date-arguments; trace date; printf '%s\n' "$FIXED_DATE"; return "$CLOCK_RETURN"; }
wc() { [[ $# == 1 && $1 == -l ]] || forbidden count-arguments; trace wc "$@"; builtin command wc "$@"; }
sed() {
    [[ $# == 2 && $1 == 's/^/      /' && $2 == "$BROKEN" ]] || forbidden sed-arguments
    trace sed "$@"; builtin command sed "$@"
}
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "probe_optional_modules", "probe_boot_module",
             "capture_validated_package_snapshot", "capture_pending_new_config_files", "update_slackware_system", "update_flatpak",
             "rebuild_cinnamon_if_needed", "regenerate_initrd", "update_grub_configuration", "emit_event", "print_json_result",
             "slackpkg", "flatpak", "sbopkg", "sqg", "git", "curl", "wget", "mkinitrd", "geninitrd", "grub-mkconfig", "find", "rm", "mv", "mktemp")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def cases():
    for snapshot, pending, blocked in itertools.product(range(8), PENDING, (0, 1)):
        yield BASE | dict(snapshot=snapshot, pending=pending, blocked=blocked)
    for abi, cinnamon, boot in itertools.product((0, 1, 7), (0, 1, 2, 3, 7), BOOT):
        yield BASE | dict(abi=abi, cinnamon=cinnamon, boot=boot)
    for queues, broken, critical in itertools.product(range(5), BROKEN, range(3)):
        yield BASE | dict(queues=queues, broken=broken, critical=critical, pending="tail", modules=1)
    for blocked, clock, modules in itertools.product((0, 1), (0, 41), (0, 1)):
        yield BASE | dict(blocked=blocked, clock=clock, modules=modules, boot="both-failed", broken="lines")
    for status, clock in itertools.product((0, 100, 1, 20, 42, 127, 255, -1), (0, 41)):
        yield BASE | dict(kind="check", check=status, clock=clock)


def state(case, work):
    before, after, error = case["snapshot"] & 1, (case["snapshot"] >> 1) & 1, case["snapshot"] >> 2
    values = dict(PACKAGE_SNAPSHOT_BEFORE_VALID=before, PACKAGE_SNAPSHOT_AFTER_VALID=after,
                  PACKAGE_SNAPSHOT_BEFORE_COUNT=17, PACKAGE_SNAPSHOT_AFTER_COUNT=23,
                  PACKAGE_SNAPSHOT_BEFORE_ERROR="before failure" if error else "",
                  PACKAGE_SNAPSHOT_AFTER_ERROR="after failure" if error else "",
                  PENDING_NEW_CONFIG_FILES_VALID=int(not case["pending"].startswith("invalid")),
                  PENDING_NEW_CONFIG_FILES_COUNT=3 if case["pending"] == "tail" else 2 if case["pending"] == "lines" else 0,
                  PENDING_NEW_CONFIG_FILES_ERROR="scan failure" if case["pending"] == "invalid" else "",
                  PENDING_NEW_CONFIG_FILES=str(work / "pending list"), SECONDARY_MODULES_BLOCKED=case["blocked"],
                  SECONDARY_MODULES_BLOCK_REASON="supplied snapshot failure", ABI_TRIGGER=case["abi"], CINNAMON_TRIGGER=case["cinnamon"],
                  KERNEL_TRIGGER=0 if case["boot"] == "none" else 7 if case["boot"] == "other-trigger" else 1,
                  INITRD_REQUIRED=0, INITRD_UPDATE=1, INITRD_OK=0, INITRD_VALIDATION_ERROR="",
                  BOOT_PREPARATION_LAYOUT="other", DIRECT_GENERIC_VALIDATION_STATUS=1, DIRECT_GENERIC_VALIDATION_ERROR="",
                  DIRECT_GENERIC_INSTALLED_KERNEL_VERSION="6.private", GRUB_REQUIRED=0, GRUB_UPDATE=1, GRUB_BLOCKED_BY_INITRD=0,
                  GRUB_BLOCK_REASON="supplied initrd failure", GRUB_OK=0, GRUB_VALIDATION_ERROR="",
                  TOTAL_CORE=4, SBO_OPTION_RECORD_COUNT=2, TOTAL_EXTRA=3, TOTAL_EN_COLA=6, SBO_PERSONAL_QUEUE_DIR="",
                  SBO_PERSONAL_QUEUE_FILE_COUNT=2, SBO_PERSONAL_QUEUE_SYMLINK_COUNT=1, SBO_QUEUE_GENERATION_READY=0,
                  SBO_GENERATED_QUEUE_DIR="", ELF_LIBRARY_CACHE_RECORD_COUNT=11, BROKEN=str(work / "broken list"),
                  CONFIG_FILE="/private/config with space", LOG="/private/log with space", FIXED_DATE="fixed private clock", CLOCK_RETURN=case["clock"],
                  CHECK_STATUS=case["check"])
    boot = case["boot"]
    if boot.startswith("initrd-") or boot == "both-failed":
        values.update(INITRD_REQUIRED=1, INITRD_UPDATE=int(boot != "initrd-skip"), INITRD_OK=int(boot == "initrd-ok"),
                      INITRD_VALIDATION_ERROR="initrd validation failure" if boot in ("initrd-error", "both-failed") else "")
    if boot.startswith("direct-"):
        values.update(BOOT_PREPARATION_LAYOUT="direct-generic-no-initrd", DIRECT_GENERIC_VALIDATION_STATUS=int(boot != "direct-ok"),
                      DIRECT_GENERIC_VALIDATION_ERROR="direct validation failure" if boot == "direct-error" else "")
    if boot.startswith("grub-") or boot == "both-failed":
        # Conflicting supplied flags exercise documented display precedence, not reachable workflow claims.
        values.update(GRUB_REQUIRED=1, GRUB_UPDATE=int(boot != "grub-skip"), GRUB_OK=int(boot in ("grub-ok", "grub-skip", "grub-blocked")),
                      GRUB_BLOCKED_BY_INITRD=int(boot in ("grub-skip", "grub-blocked", "both-failed")),
                      GRUB_VALIDATION_ERROR="transaction failure" if boot == "grub-error" else "")
    for module in MODULES:
        values[module + "_MODE"] = "enabled" if case["modules"] else "auto"
        values[module + "_MODULE_STATE"] = "supplied-state" if case["modules"] else "available"
    if case["queues"] in (1, 2, 3): values["SBO_PERSONAL_QUEUE_DIR"] = "/private/personal queues"
    if case["queues"] in (2, 3): values["SBO_GENERATED_QUEUE_DIR"] = "/private/generated queues"
    if case["queues"] == 3: values["SBO_QUEUE_GENERATION_READY"] = 1
    if case["queues"] == 4:
        for name in ("SBO_PERSONAL_QUEUE_DIR", "SBO_QUEUE_GENERATION_READY", "SBO_GENERATED_QUEUE_DIR", "ELF_LIBRARY_CACHE_RECORD_COUNT", "GRUB_VALIDATION_ERROR"):
            del values[name]
    return values


def expected(case, work):
    """Authored output oracle; no source-derived golden text or renderer invocation."""
    if case["kind"] == "check":
        message = "[OK] No Slackware repository updates were reported." if case["check"] == 0 else "[UPDATES] Slackware repository updates are available." if case["check"] == 100 else "[ERROR] The Slackware update check did not complete successfully."
        return ("\n==============================\nCHECK SUMMARY\n==============================\n\n" + message +
                "\n\n[INFO] No packages or optional components were modified.\n[CONFIG] Configuration: /private/config with space\n[LOG] Full log: /private/log with space\n[END] Finished: fixed private clock\n").encode()
    lines = ["", "==============================", "RESUMEN", "==============================", "", "[PKG] Estado de actualizacion del sistema:", ""]
    before, after, error = case["snapshot"] & 1, (case["snapshot"] >> 1) & 1, case["snapshot"] >> 2
    lines += ["- Instantanea previa: valida (17 paquetes)" if before else "- [ERROR] Instantanea previa: no valida" + (" (before failure)" if error else "")]
    lines += ["- Instantanea posterior: valida (23 paquetes)" if after else "- [ERROR] Instantanea posterior: no valida" + (" (after failure)" if error else "") if before else "- Instantanea posterior: no capturada"]
    lines += ["", "- Politica de configuracion post-instalacion: conservar archivos actuales", "  -> El procesamiento interactivo de slackpkg esta desactivado durante install-new y upgrade-all."]
    if case["pending"].startswith("invalid"):
        lines += ["  -> [WARN] No se pudo enumerar los archivos .new pendientes" + (": scan failure" if case["pending"] == "invalid" else "")]
    else:
        lines += ["  -> Archivos .new pendientes de revision manual: " + str({"zero": 0, "lines": 2, "tail": 3}[case["pending"]])]
        if case["pending"] == "lines": lines += ["    * /private/a space.new", "    * /private/back\\slash.new"]
        if case["pending"] == "tail": lines += ["    * /private/a.new", "    * ", "    * /private/last.new"]
    lines += [""]
    if case["blocked"]:
        lines += ["- [ERROR] Modulos secundarios bloqueados: supplied snapshot failure", "  -> Flatpak, analisis de paquetes, SBo, ELF, Cinnamon y boot no se iniciaron.", ""]
    else:
        lines += ["- Cambios ABI detectados: " + str(case["abi"])]
        lines += ["  -> Se detectaron actualizaciones en librerias criticas del sistema.", "  -> Los paquetes SBo afectados han sido anadidos a la cola de recompilacion."] if case["abi"] == 1 else ["  -> No se detectaron cambios en librerias ABI relevantes."]
        cinnamon = {0: "Cinnamon no requirio recompilacion.", 2: "Cinnamon fue reconstruido correctamente.", 3: "Cinnamon requeria reconstruccion pero fallo."}.get(case["cinnamon"], "Cinnamon fue marcado pero no ejecutado correctamente.")
        boot = case["boot"]
        lines += ["", "- Recompilacion de Cinnamon: " + str(case["cinnamon"]), "  -> " + cinnamon, "", "- Cambios de kernel: " + str(0 if boot == "none" else 7 if boot == "other-trigger" else 1)]
        if boot in ("none", "other-trigger"):
            lines += ["  -> No hubo cambios en el kernel."]
        else:
            lines += ["  -> Se detecto actualizacion del kernel."]
            if boot.startswith("initrd-") or boot == "both-failed":
                message = "initrd omitido por el modo del modulo boot (" + ("enabled" if case["modules"] else "auto") + ")." if boot == "initrd-skip" else "initrd regenerado correctamente." if boot == "initrd-ok" else "initrd requeria regeneracion pero fallo."
                lines += ["  -> " + message]
                if boot in ("initrd-error", "both-failed"): lines += ["  -> Validacion: initrd validation failure"]
            if boot.startswith("direct-"):
                lines += ["  -> Direct generic boot does not require initrd."]
                if boot == "direct-ok": lines += ["  -> Direct kernel and modules validated: 6.private."]
                if boot == "direct-error": lines += ["  -> Direct validation: direct validation failure"]
            if boot.startswith("grub-") or boot == "both-failed":
                message = "GRUB omitido por el modo del modulo boot (auto)." if boot == "grub-skip" else "GRUB bloqueado para proteger el arranque: supplied initrd failure" if boot in ("grub-blocked", "both-failed") else "GRUB generado en temporal, validado e instalado atomicamente." if boot == "grub-ok" else "GRUB requeria actualizacion pero fallo."
                lines += ["  -> " + message]
                if boot == "grub-error": lines += ["  -> Transaccion GRUB: transaction failure"]
            lines += ["  -> Reinicia el sistema para aplicar el nuevo kernel."]
        if case["critical"]:
            lines += ["", "- [WARN] Paquetes criticos actualizados que requieren reinicio:", "    * kernel-private"]
            if case["critical"] == 2: lines += ["    * glibc private", "    * kernel-private"]
            lines += ["  -> Se recomienda reiniciar el sistema para que los cambios sean efectivos."]
        lines += ["", "[PKG] Estado de colas SBo:", "", "- Cola principal (repositorios SBo):  4 paquetes", "- Opciones SBo preservadas:            2 registros", "- Cola extra (ABI + binarios rotos):  3 paquetes", "- Total en cola (enviados a sbopkg):  6 paquetes"]
        if case["queues"] in (1, 2, 3): lines += ["- Directorio de colas personales:     /private/personal queues (solo lectura)", "- Colas personales copiadas:          2", "- Enlaces de cola ignorados:          1"]
        if case["queues"] == 3: lines += ["- Workspace privado de sqg:           /private/generated queues (validado)"]
        if case["queues"] == 2: lines += ["- Workspace privado de sqg:           no validado"]
        lines += ["", "[SYS] Diagnostico del sistema:", "", "- Resolucion ELF por arquitectura: clase + datos + maquina", "- Registros ELF compatibles en cache: " + ("0" if case["queues"] == 4 else "11")]
        if case["broken"] == "empty":
            lines += ["- [OK] No se detectaron binarios con librerias rotas (o todos fueron reparados)."]
        else:
            lines += ["- [WARN] Binarios con librerias rotas tras recompilacion: " + str(BROKEN[case["broken"]].count(b"\n")), "  -> Estos binarios siguen rotos y requieren atencion manual:"]
            # sed preserves an unterminated final record; the following echo supplies its newline.
            lines += ["      " + line for line in BROKEN[case["broken"]].decode().splitlines()]
        if case["broken"] != "tail": lines += [""]
    lines += ["[MODULES] Modos y estado de activacion:", ""]
    lines += ["- " + label + ": mode=" + ("enabled, state=supplied-state" if case["modules"] else "auto, state=available") for label in LABELS]
    lines += ["", "[CONFIG] Configuracion: /private/config with space", "[LOG] Log completo: /private/log with space", "[FIN] Finalizacion: fixed private clock"]
    return ("\n".join(lines) + "\n").encode()


def run_case(work, case):
    (work / "pending list").write_bytes(PENDING[case["pending"]])
    if case["broken"] == "link":
        (work / "broken target").write_bytes(BROKEN["link"]); (work / "broken list").symlink_to(work / "broken target")
    else: (work / "broken list").write_bytes(BROKEN[case["broken"]])
    trace = work / "trace"; trace.write_bytes(b"")
    inventory = lambda: {p.name: ("link", str(p.readlink())) if p.is_symlink() else ("file", p.read_bytes()) for p in work.iterdir() if p != trace}
    before = inventory()
    values = state(case, work)
    reset = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in values.items())
    optional = ("SBO_PERSONAL_QUEUE_DIR", "SBO_QUEUE_GENERATION_READY", "SBO_GENERATED_QUEUE_DIR", "ELF_LIBRARY_CACHE_RECORD_COUNT", "GRUB_VALIDATION_ERROR")
    reset += "\n" + "\n".join("unset " + name for name in optional if name not in values)
    critical = () if case["critical"] == 0 else ("kernel-private",) if case["critical"] == 1 else ("kernel-private", "glibc private", "kernel-private")
    reset += "\nCRITICAL_UPDATED=(" + " ".join(map(shlex.quote, critical)) + ")"
    # Selected input globals/array/IFS must survive; loop temporaries pkg/pending_config are not covered.
    snapshot = 'printf \'%s\\0\' ' + " ".join('"${' + key + '-__UNSET__}"' for key in sorted(set(values) | set(optional))) + ' "${CRITICAL_UPDATED[@]}" "$IFS"'
    function = "print_check_summary" if case["kind"] == "check" else "print_summary"
    driver = PREFIX + GUARDS + "\nIFS='|: '\nfor repetition in 1 2; do\n" + reset + "\n" + function + '\nraw=$?\nprintf \'RESULT\\0%s\\0\' "$raw"\n' + snapshot + "\ndone\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "human-summary-test", str(REFERENCE), str(trace)], capture_output=True, timeout=10, env=dict(os.environ, LC_ALL="C"))
    saved = b"".join(str(values.get(key, "__UNSET__")).encode() + b"\0" for key in sorted(set(values) | set(optional)))
    saved += b"".join(value.encode() + b"\0" for value in critical) + b"|: \0"
    packet = expected(case, work) + b"RESULT\0" + b"0\0" + saved
    assert result.returncode == 0, (case, "driver", result.returncode, result.stderr)
    assert result.stdout == packet * 2, (case, "stdout", result.stdout, packet * 2)
    assert result.stderr == b"", (case, "stderr", result.stderr)
    rows = []
    if case["kind"] == "apply" and not case["blocked"] and case["broken"] != "empty": rows += [("wc", "-l"), ("sed", "s/^/      /", str(work / "broken list"))]
    rows += [("date",)]
    encoded = b"".join(b"".join(value.encode() + b"\0" for value in row) + b"\n" for row in rows)
    assert trace.read_bytes() == encoded * 2, (case, "trace", trace.read_bytes(), encoded * 2)
    assert inventory() == before, (case, "private inventory")


def main():
    counts = dict(apply=0, check=0)
    with tempfile.TemporaryDirectory(prefix="slack-update human summary ") as temporary:
        for number, case in enumerate(cases()):
            work = Path(temporary) / str(number); work.mkdir(); run_case(work, case); counts[case["kind"]] += 1
    print(f"Human summaries: {counts['apply']} apply scenarios, {counts['check']} check scenarios, {sum(counts.values()) * 2} entries, 0 failures")


if __name__ == "__main__":
    main()
