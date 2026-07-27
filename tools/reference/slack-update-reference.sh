#!/bin/bash
#
# slack-update-reference.sh — Actualizacion desatendida de Slackware-current + SBo + Flatpak + Cinnamon
#
# Instalacion:
#   cp slack-update-reference.sh /usr/local/sbin/slack-update
#   chmod 700 /usr/local/sbin/slack-update
#
# Uso manual:   slack-update
# Uso en cron:  0 3 * * 0 /usr/local/sbin/slack-update

set -uo pipefail
IFS=$'\n\t'

# Runtime setup functions

require_root() {
    [ "$(id -u)" -eq 0 ] || { echo "Este script requiere root"; exit 1; }
}

acquire_instance_lock() {
    LOCKFILE=/var/run/slack-update.lock

    exec 9>"$LOCKFILE"

    # Asegurar lock estable (evita carreras con rm externo)
    if ! flock -n 9; then
        echo "Otra instancia de slack-update ya esta ejecutandose"
        exit 1
    fi
}

initialize_runtime() {
    WORKDIR=/var/lib/slack-update
    LOGDIR=/var/log/slack-update

    mkdir -p "$WORKDIR" "$LOGDIR"

    DATE=$(date +%F-%H%M%S)
    LOG="$LOGDIR/run-$DATE.log"

    BROKEN="$WORKDIR/broken.txt"
    QUEUE_CORE="$WORKDIR/queue-core.sqf"
    QUEUE_EXTRA="$WORKDIR/queue-extra.sqf"

    BEFORE_PKGS="$WORKDIR/packages.before"
    AFTER_PKGS="$WORKDIR/packages.after"

    # Tempfiles — se crean aqui para que el trap los cubra desde el inicio
    QUEUE_FINAL=$(mktemp)
    BROKEN_NEW=$(mktemp)
    STILL_BROKEN=$(mktemp)
    BROKEN_ERRORS=$(mktemp)

    KERNEL_TRIGGER=0
    INITRD_UPDATE=0
    GRUB_UPDATE=0
    ABI_TRIGGER=0
    CINNAMON_TRIGGER=0   # 0=none, 1=needed, 2=ok, 3=fail
    CINNAMON_OK=0
    INITRD_OK=0
    GRUB_OK=0
    TOTAL_EN_COLA=0
    TOTAL_CORE=0
    TOTAL_EXTRA=0
    CSB_DIR="$WORKDIR/csb"
}

cleanup() {
        rm -f "$QUEUE_FINAL" "$BROKEN_NEW" "$STILL_BROKEN" "$BROKEN_ERRORS" 2>/dev/null || true
        flock -u 9 2>/dev/null || true
}

rotate_logs() {
    # Rotacion de logs — conservar solo los ultimos 30 dias.
    # FIX #10: La rotacion se ejecuta ANTES de abrir el log de esta ejecucion,
    # por lo que nunca puede borrar el fichero run-$DATE.log actual.
    find "$LOGDIR" -name 'run-*.log' -mtime +30 -delete 2>/dev/null || true
}

configure_logging() {
    # Redirigir log filtrando codigos ANSI
    # FIX #10: Se eliminan emojis del log para evitar problemas de encoding en cron.
    # La salida de consola (si se ejecuta interactivamente) los mostrara igualmente
    # porque el tee escribe a stdout antes del filtro de ANSI.
    exec > >(sed 's/\x1b\[[0-9;]*[mGKHJ]//g; s/\r//' | tee -a "$LOG") 2>&1
}

print_start_banner() {
    echo "================================================"
    echo "START: $(date)"
    echo "================================================"
}

# Update workflow functions

capture_package_snapshot_before() {
    # ---------------------------
    # SNAPSHOT BEFORE
    # ---------------------------

    rm -f "$BEFORE_PKGS" "$AFTER_PKGS"

    find /var/log/packages -maxdepth 1 -type f -printf '%f\n' \
        | sort > "$BEFORE_PKGS" || true
}

update_slackware_system() {
    # ---------------------------
    # [1] UPDATE SYSTEM
    # ---------------------------

    echo "[1] Slackware update"

    slackpkg -batch=on -default_answer=y update      || true
    slackpkg -batch=on -default_answer=y install-new || true
    slackpkg -batch=on -default_answer=y upgrade-all || true
}

capture_package_snapshot_after() {
    # ---------------------------
    # SNAPSHOT AFTER
    # ---------------------------

    find /var/log/packages -maxdepth 1 -type f -printf '%f\n' \
        | sort > "$AFTER_PKGS" || true
}

update_flatpak() {
    # ---------------------------
    # [2] FLATPAK
    # ---------------------------

    echo "[2] Flatpak update"

    if command -v flatpak >/dev/null 2>&1; then
        flatpak update -y --noninteractive || true
    else
        echo "  Flatpak no instalado, omitiendo"
    fi
}

detect_abi_changes() {
    # ---------------------------
    # [3] ABI + CINNAMON DETECTION
    # ---------------------------

    echo "[3] Detectando cambios ABI"

    ABI_PACKAGES=(
        glibc gcc glib2 dbus libffi zlib zstd lz4
        mesa gtk+3 gtk4 cairo cairomm1 pango harfbuzz libdrm libinput gtkmm3 openexr
        ffmpeg gstreamer gst-plugins-base pipewire openssl openssl-solibs gnutls
        curl libpng libjpeg-turbo libtiff alsa-lib libvorbis libopus flac nss nspr
    )

    CINNAMON_ABI=(
        mesa gtk+3 gtk4 cairo pango harfbuzz libdrm libinput ffmpeg openexr gtkmm3 cairomm1
        libX11 libxcb libXext libXrender atk
    )

    CRITICAL_UPDATED=()

    for p in "${ABI_PACKAGES[@]}"; do

        BEFORE=$(grep "^${p}-" "$BEFORE_PKGS" || true)
        AFTER=$(grep  "^${p}-" "$AFTER_PKGS"  || true)

        if [ "$BEFORE" != "$AFTER" ]; then

            echo "  ABI change: $p"
            ABI_TRIGGER=1

            # Paquetes criticos que requieren reinicio para ser efectivos
            case "$p" in
                glibc|dbus|openssl|openssl-solibs)
                    CRITICAL_UPDATED+=("$p")
                    ;;
            esac

            for c in "${CINNAMON_ABI[@]}"; do
                if [ "$c" = "$p" ]; then
                    CINNAMON_TRIGGER=1
                    echo "   -> Cinnamon rebuild required"
                    break
                fi
            done

        fi

    done

    [ "$ABI_TRIGGER"      -eq 0 ] && echo "  Sin cambios ABI relevantes"
    [ "$CINNAMON_TRIGGER" -eq 0 ] && echo "  Sin cambios en pila grafica de Cinnamon"

    if [ "${#CRITICAL_UPDATED[@]}" -gt 0 ]; then
        echo "  [WARN] Paquetes criticos actualizados que requieren reinicio: ${CRITICAL_UPDATED[*]}"
    fi
}

detect_kernel_changes() {
    # ---------------------------
    # [4] KERNEL DETECTION
    # ---------------------------

    echo "[4] Detectando cambios en kernel"

    # FIX #7: Ampliada la lista de paquetes de kernel vigilados.
    # kernel-huge: kernel alternativo presente en algunos sistemas.
    # kernel-headers: su cambio puede requerir recompilacion de modulos externos.
    KERNEL_PACKAGES=(kernel-generic kernel-huge kernel-modules kernel-headers)

    for p in "${KERNEL_PACKAGES[@]}"; do

        BEFORE=$(grep "^${p}-" "$BEFORE_PKGS" || true)
        AFTER=$(grep  "^${p}-" "$AFTER_PKGS"  || true)

        if [ "$BEFORE" != "$AFTER" ]; then
            echo "  Kernel actualizado: $p"
            KERNEL_TRIGGER=1
            # Solo regenerar initrd y grub si cambio el kernel en si, no solo las headers
            case "$p" in
                kernel-generic|kernel-huge|kernel-modules)
                    INITRD_UPDATE=1
                    GRUB_UPDATE=1
                    ;;
                kernel-headers)
                    echo "  [INFO] kernel-headers actualizado: puede requerir recompilacion de modulos externos"
                    ;;
            esac
        fi

    done

    [ "$KERNEL_TRIGGER" -eq 0 ] && echo "  Sin cambios de kernel"
}

synchronize_sbo_repository() {
    # ---------------------------
    # [5] SBo SYNC
    # ---------------------------

    echo "[5] Sync SBo"

    if command -v sbopkg >/dev/null 2>&1; then
        if command -v sqg >/dev/null 2>&1; then
            sbopkg -r || true
            sqg -a    || true
        else
            echo "  sqg no encontrado -- omitiendo sync SBo"
        fi
    else
        echo "  sbopkg no instalado, omitiendo"
    fi
}

build_sbo_core_queue() {
    # ---------------------------
    # [6] BUILD QUEUES
    # ---------------------------

    echo "[6] Generando colas SBo"

    # FIX #6: Parseo mas robusto de sbopkg.conf — cubre valores con comillas dobles,
    # comillas simples o sin comillas.
    SBODIR=$(grep -E '^QUEUEDIR=' /etc/sbopkg/sbopkg.conf 2>/dev/null \
        | head -1 | cut -d= -f2- | tr -d \"\' | xargs 2>/dev/null || true)
    if [ -z "$SBODIR" ]; then
        SBODIR=/var/lib/sbopkg/queues
        echo "  [WARN] No se pudo leer QUEUEDIR de sbopkg.conf — usando valor por defecto: $SBODIR"
    fi

    rm -f "$QUEUE_CORE" "$QUEUE_EXTRA"

    if [ -d "$SBODIR" ]; then
        find "$SBODIR" -name '*.sqf' -exec cat {} + 2>/dev/null \
            | awk '{print $1}' | sort -u > "$QUEUE_CORE"
        TOTAL_CORE=$(wc -l < "$QUEUE_CORE")
        echo "  Cola principal: $TOTAL_CORE paquetes"
    else
        echo "  [WARN] Directorio de queues no encontrado: $SBODIR"
        touch "$QUEUE_CORE"
    fi
}

add_abi_rebuild_targets() {
    # ---------------------------
    # [7] ABI FORCES SBo REBUILD
    # ---------------------------

    if [ "$ABI_TRIGGER" -eq 1 ]; then

        echo "[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra"

        find /var/log/packages -maxdepth 1 -name '*_SBo' \
            -printf '%f\n' 2>/dev/null \
            | rev | cut -d- -f4- | rev \
            | sort -u > "$QUEUE_EXTRA" || true

        TOTAL_EXTRA=$(wc -l < "$QUEUE_EXTRA")
        echo "  Cola ABI extra: $TOTAL_EXTRA paquetes"

    else
        touch "$QUEUE_EXTRA"
    fi
}

detect_broken_elf_objects() {
    # ---------------------------
    # [8] BROKEN LIBS DETECTION
    # ---------------------------

    echo "[8] Detectando binarios rotos"

    # FIX #2: El subshell del pipe hacia 'while | sort' perdía la salida del log.
    # Se redirige la salida de errores del bucle explícitamente al log mediante
    # un fichero temporal de errores, y se procesa después del bucle.
    find /usr/bin /usr/sbin /usr/libexec /opt \( -type f -o -type l \) -print0 |
    while IFS= read -r -d '' f; do
        # FIX #5: Sustituido 'file | ldd' por 'readelf -d' para deteccion segura.
        # ldd puede ejecutar el binario (riesgo con binarios de terceros) y genera
        # falsos positivos con binarios PIE o con RPATH $ORIGIN. readelf -d es
        # estrictamente estatico. Se comprueba cada libreria NEEDED contra la cache
        # de ldconfig; si no aparece, el binario se marca como roto.
        _real=$(readlink -f "$f" 2>/dev/null || echo "$f")
        _needed=$(readelf -d "$_real" 2>>"$BROKEN_ERRORS" \
            | awk '/\(NEEDED\)/{match($0,/\[([^]]+)\]/,a); print a[1]}') || continue
        [ -z "$_needed" ] && continue
        while IFS= read -r _lib; do
            [ -z "$_lib" ] && continue
            /sbin/ldconfig -p 2>/dev/null | grep -qF "$_lib" || { echo "$f"; break; }
        done <<< "$_needed"
    done | sort -u > "$BROKEN_NEW"

    # Volcar los errores del bucle al log principal
    if [ -s "$BROKEN_ERRORS" ]; then
        echo "  [WARN] Errores durante deteccion de binarios rotos:"
        sed 's/^/    /' "$BROKEN_ERRORS"
        > "$BROKEN_ERRORS"
    fi

    # broken.txt refleja el estado actual — no acumulado
    cp "$BROKEN_NEW" "$BROKEN"

    BROKEN_COUNT=$(wc -l < "$BROKEN" 2>/dev/null || echo 0)
    echo "  Binarios rotos detectados: $BROKEN_COUNT"
}

map_broken_objects_to_sbo_packages() {
    # ---------------------------
    # [9] MAP BROKEN TO SBo PKGS
    # ---------------------------

    echo "[9] Mapeando binarios rotos a paquetes SBo"

    if [ -s "$BROKEN" ]; then
        # FIX #3: Acumular en temporal y hacer merge para no contaminar QUEUE_EXTRA
        # con datos de ejecuciones anteriores cuando ABI no disparo (bloque [7]).
        _BROKEN_PKGS=$(mktemp)
        while read -r bin; do
            [ -e "$bin" ] || continue
            # FIX #4: Anclar con grep -P para cubrir rutas con y sin barra inicial
            # en los manifiestos de /var/log/packages (algunos omiten el '/' inicial).
            grep -rlP "^/?${bin#/}$" /var/log/packages/ 2>/dev/null \
                | sed 's|.*/||' \
                | grep '_SBo' \
                | rev | cut -d- -f4- | rev
        done < "$BROKEN" | sort -u > "$_BROKEN_PKGS"

        # Merge: contenido previo de QUEUE_EXTRA (si lo hay) + rotos nuevos, deduplicado
        sort -u "$QUEUE_EXTRA" "$_BROKEN_PKGS" -o "$QUEUE_EXTRA" 2>/dev/null || true
        rm -f "$_BROKEN_PKGS"

        TOTAL_EXTRA=$(wc -l < "$QUEUE_EXTRA")
        echo "  Cola extra tras rotos: $TOTAL_EXTRA paquetes"
    else
        echo "  Sin binarios rotos, nada que anadir"
    fi
}

build_and_apply_sbo_queue() {
    # ---------------------------
    # [10] BUILD FINAL QUEUE + APPLY
    # ---------------------------

    echo "[10] Aplicando cola SBo"

    cat "$QUEUE_CORE" "$QUEUE_EXTRA" 2>/dev/null | sort -u > "$QUEUE_FINAL"

    TOTAL=$(wc -l < "$QUEUE_FINAL")
    TOTAL_EN_COLA=$TOTAL
    echo "  Total paquetes en cola: $TOTAL"

    if [ "$TOTAL" -gt 0 ]; then
        # FIX #5: Sustituido 'sbopkg -b -i "string largo"' por 'sbopkg -b -B fichero'.
        # Pasar todos los paquetes como un unico string con -i puede superar ARG_MAX
        # cuando la cola es grande. Usar -B con el fichero .sqf es mas robusto y es
        # la forma recomendada por sbopkg para listas de paquetes.
        sbopkg -b -B "$QUEUE_FINAL" \
            && echo "  [OK] Cola SBo procesada" \
            || echo "  [WARN] sbopkg termino con errores -- revisar log: $LOG"

        # Verificar si los binarios que estaban rotos antes de sbopkg siguen rotos
        if [ -s "$BROKEN" ]; then
            echo "  Verificando si los binarios rotos fueron reparados..."
            > "$STILL_BROKEN"
            while read -r bin; do
                [ -e "$bin" ] || continue
                ldd "$bin" 2>/dev/null | grep -q "not found" && echo "$bin"
            done < "$BROKEN" | sort > "$STILL_BROKEN"

            if [ -s "$STILL_BROKEN" ]; then
                echo "  [WARN] Binarios que siguen rotos tras la recompilacion:"
                sed 's/^/    /' "$STILL_BROKEN"
                cp "$STILL_BROKEN" "$BROKEN"
            else
                echo "  [OK] Todos los binarios rotos fueron reparados"
                > "$BROKEN"
            fi
        fi
    else
        echo "  Cola vacia, nada que hacer"
    fi
}

rebuild_cinnamon() {
    # ---------------------------
    # [11] CINNAMON BUILD
    # ---------------------------

    if [ "$CINNAMON_TRIGGER" -eq 1 ]; then

        echo "[11] Rebuild Cinnamon"

        if [ -d "$CSB_DIR/.git" ]; then

            echo "  Actualizando repositorio CSB"

            git -C "$CSB_DIR" fetch origin 2>&1 \
                && git -C "$CSB_DIR" reset --hard origin/master 2>&1 \
                && echo "  [OK] Repositorio CSB actualizado" \
                || echo "  [WARN] No se pudo actualizar CSB -- continuando con copia local"

        else

            echo "  Clonando repositorio CSB"

            git clone -b master https://github.com/CinnamonSlackBuilds/csb.git "$CSB_DIR" \
                && echo "  [OK] Repositorio CSB clonado" \
                || echo "  [ERROR] git clone de CSB fallo -- Cinnamon NO sera reconstruido"
        fi

        CINNAMON_OK=0

        if [ -x "$CSB_DIR/build-cinnamon.sh" ]; then

            (
                cd "$CSB_DIR" || exit 1
                ./build-cinnamon.sh
            )
            RET=$?

            if [ "$RET" -eq 0 ]; then
                CINNAMON_OK=1
                CINNAMON_TRIGGER=2
                echo "  [OK] Cinnamon reconstruido correctamente"
            else
                CINNAMON_TRIGGER=3
                echo "  [ERROR] Fallo en Cinnamon -- revisar log"
            fi

        else
            CINNAMON_TRIGGER=3
            echo "  [ERROR] build-cinnamon.sh no existe o no es ejecutable"
        fi

    fi
}

regenerate_initrd() {
    # ---------------------------
    # [12] INITRD
    # ---------------------------

    if [ "$INITRD_UPDATE" -eq 1 ]; then

        echo "[12] Regenerando initrd"

        if command -v mkinitrd >/dev/null 2>&1; then
            if [ -f /etc/mkinitrd.conf ]; then
                if grep -q '^ROOTDEV=' /etc/mkinitrd.conf 2>/dev/null; then
                    mkinitrd -F \
                        && {
                            # FIX #8: Verificar que el initrd existe y no esta vacio
                            _initrd=$(grep -E '^OUTPUT=' /etc/mkinitrd.conf 2>/dev/null \
                                | cut -d= -f2- | tr -d \"\' | xargs 2>/dev/null)
                            _initrd=${_initrd:-/boot/initrd.gz}
                            if [ -s "$_initrd" ]; then
                                INITRD_OK=1
                                echo "  [OK] initrd regenerado ($_initrd)"
                            else
                                echo "  [ERROR] mkinitrd termino sin errores pero $_initrd esta vacio o no existe"
                            fi
                        } \
                        || echo "  [ERROR] mkinitrd -F fallo"
                else
                    echo "  [ERROR] /etc/mkinitrd.conf existe pero no contiene ROOTDEV -- initrd NO regenerado"
                    echo "          Revisa /etc/mkinitrd.conf antes de continuar"
                fi
            else
                echo "  [ERROR] /etc/mkinitrd.conf no existe -- initrd NO regenerado"
            fi
        else
            echo "  [ERROR] mkinitrd no encontrado"
        fi

    fi
}

update_grub_configuration() {
    # ---------------------------
    # [13] GRUB
    # ---------------------------

    if [ "$GRUB_UPDATE" -eq 1 ]; then

        echo "[13] Actualizando GRUB"

        if command -v grub-mkconfig >/dev/null 2>&1 && [ -d /boot/grub ]; then
            grub-mkconfig -o /boot/grub/grub.cfg \
                && {
                    GRUB_OK=1
                    echo "  [OK] GRUB actualizado"
                } \
                || echo "  [ERROR] grub-mkconfig fallo"

        else
            echo "  [ERROR] GRUB no encontrado o /boot/grub no existe"
        fi

    fi
}

print_summary() {
    # ---------------------------
    # RESUMEN
    # FIX #10: Eliminados emojis para evitar problemas de encoding en entornos
    # cron sin locale UTF-8. Se sustituyen por marcadores de texto plano.
    # ---------------------------

    echo
    echo "=============================="
    echo "RESUMEN"
    echo "=============================="
    echo

    echo "[PKG] Estado de actualizacion del sistema:"
    echo

    echo "- Cambios ABI detectados: $ABI_TRIGGER"
    if [ "$ABI_TRIGGER" -eq 1 ]; then
        echo "  -> Se detectaron actualizaciones en librerias criticas del sistema."
        echo "  -> Los paquetes SBo afectados han sido anadidos a la cola de recompilacion."
    else
        echo "  -> No se detectaron cambios en librerias ABI relevantes."
    fi

    echo

    echo "- Recompilacion de Cinnamon: $CINNAMON_TRIGGER"

    if [ "$CINNAMON_TRIGGER" -ne 0 ]; then

        if [ "$CINNAMON_TRIGGER" -eq 2 ]; then
            echo "  -> Cinnamon fue reconstruido correctamente."
        elif [ "$CINNAMON_TRIGGER" -eq 3 ]; then
            echo "  -> Cinnamon requeria reconstruccion pero fallo."
        else
            echo "  -> Cinnamon fue marcado pero no ejecutado correctamente."
        fi

    else
        echo "  -> Cinnamon no requirio recompilacion."
    fi

    echo

    echo "- Cambios de kernel: $KERNEL_TRIGGER"

    if [ "$KERNEL_TRIGGER" -eq 1 ]; then

        echo "  -> Se detecto actualizacion del kernel."

        if [ "$INITRD_UPDATE" -eq 1 ]; then
            if [ "$INITRD_OK" -eq 1 ]; then
                echo "  -> initrd regenerado correctamente."
            else
                echo "  -> initrd requeria regeneracion pero fallo."
            fi
        fi

        if [ "$GRUB_UPDATE" -eq 1 ]; then
            if [ "$GRUB_OK" -eq 1 ]; then
                echo "  -> GRUB actualizado correctamente."
            else
                echo "  -> GRUB requeria actualizacion pero fallo."
            fi
        fi

        echo "  -> Reinicia el sistema para aplicar el nuevo kernel."

    else
        echo "  -> No hubo cambios en el kernel."
    fi

    if [ "${#CRITICAL_UPDATED[@]}" -gt 0 ]; then
        echo
        echo "- [WARN] Paquetes criticos actualizados que requieren reinicio:"
        for pkg in "${CRITICAL_UPDATED[@]}"; do
            echo "    * $pkg"
        done
        echo "  -> Se recomienda reiniciar el sistema para que los cambios sean efectivos."
    fi

    echo

    echo "[PKG] Estado de colas SBo:"
    echo

    echo "- Cola principal (repositorios SBo):  $TOTAL_CORE paquetes"
    echo "- Cola extra (ABI + binarios rotos):  $TOTAL_EXTRA paquetes"
    echo "- Total en cola (enviados a sbopkg):  $TOTAL_EN_COLA paquetes"

    echo

    echo "[SYS] Diagnostico del sistema:"
    echo

    if [ -s "$BROKEN" ]; then
        echo "- [WARN] Binarios con librerias rotas tras recompilacion: $(wc -l < "$BROKEN")"
        echo "  -> Estos binarios siguen rotos y requieren atencion manual:"
        sed 's/^/      /' "$BROKEN"
    else
        echo "- [OK] No se detectaron binarios con librerias rotas (o todos fueron reparados)."
    fi

    echo

    echo "[LOG] Log completo: $LOG"
    echo "[FIN] Finalizacion: $(date)"
}

# Entry point

main() {
    require_root
    acquire_instance_lock
    initialize_runtime
    trap cleanup EXIT INT TERM HUP
    rotate_logs
    configure_logging
    print_start_banner
    capture_package_snapshot_before
    update_slackware_system
    capture_package_snapshot_after
    update_flatpak
    detect_abi_changes
    detect_kernel_changes
    synchronize_sbo_repository
    build_sbo_core_queue
    add_abi_rebuild_targets
    detect_broken_elf_objects
    map_broken_objects_to_sbo_packages
    build_and_apply_sbo_queue
    rebuild_cinnamon
    regenerate_initrd
    update_grub_configuration
    print_summary
}

main "$@"
