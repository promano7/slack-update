# Normal-update diagnóstico, etapa A — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Contener P1 rechazando apply y corregir los cuatro defectos diagnósticos sin ejecutar un caso nativo.

**Architecture:** Bash conserva el flujo, los helpers históricos y el empaquetado. Tres módulos Python3 separan protocolo de candidatos, adquisición/validación del catálogo y manifiesto de boot. Main usa las fronteras nuevas; los helpers antiguos conservados por compatibilidad no acreditan seguridad de un flujo nativo.

**Tech Stack:** Bash, Python3 estándar, herramientas existentes Slackware/GnuPG/awk; sin paquetes o módulos Python nuevos.

Decisión de implementación: escribir helpers compatibles con Python3.9 y3.12 (sin APIs posteriores a3.9, como `hashlib.file_digest`, ni anotaciones PEP604). Probar con intérpretes disponibles sin instalar otros; si solo hay3.12, registrar que3.9 no fue ejecutado, sin afirmar conformidad15.0.

**Spec:** `docs/superpowers/specs/2026-11-02-normal-update-diagnostic-design.md`, copia exacta de `/home/promano/Documentos/ChatGPT/slack-update/runs/harness-design-20261102-204431/DESIGN.md`. Leer también el REVIEW.md de `runs/harness-review-20261102-2033` y AGENTS.md del directorio externo del proyecto.

## Global Constraints

- Base exacta b10552adfe1b5c6fc0f746324d0525f269eb929b, árbol3f9e019ce067e5ccdfec44b784305c22fbd77684. Si cambia, revisar el plan antes de aplicar cambios.
- «No introduce paquetes, dependencias Python nuevas ni C.»
- «En A, --execute-apply sigue siendo reconocible, pero main termina con error antes de refresh, sondas o launcher.» Sin escape por opción o entorno.
- «P1 sigue abierto hasta B.» No modificar el motor de referencia ni habilitar su consumo de manifiestos en A.
- «Si ambas quedan vacías, este escenario histórico de actualización no obtiene PASS»: no cero y `no-candidates`; raw20 no se convierte en aceptación contractual install20/upgrade20.
- «El resultado dirá “catálogo observado validado para estas sondas”, nunca latest global». Igualdad de fechas coherentes es válida; no imponer TTL arbitrario.
- «Mantener las expectativas históricas intactas». No editar evidencias900/910/920 ni registros aceptados para obtener PASS.
- Sin backend real/red/sudo/instalación/initrd/update-grub/reinicio durante implementación y pruebas de A. Tests exclusivamente privados y con dobles.
- G1/G2/G3, migración/realesv1/nativo/plataforma/fase1/kernel/freeze y recuperación siguen abiertos. Sin nueva PAUSA numerada ni permisos heredados.
- Push solo desde Arch. Commits con identidad real configurada; nunca inventarla. Bundle verificado solo si hay commits nuevos.

## Review Focus

1. Señal/timeout mientras un hijo mantiene abiertos los canales: no continuar, conservar primer error y no afirmar captura completa sin cerrar el grupo (tarea2).
2. Cambio del índice, configuración o estado instalado entre sondas: no publicar digest autorizado a partir de fuentes distintas (tareas2/3).
3. Raw20 válido en una acción y candidatos válidos en otra: aceptar la sonda vacía, sin perder la otra ni inventar paquetes desde stderr (tarea3).
4. Catálogo de igual fecha, pero pkglist distinto o firma de clave distinta: distinguir igualdad legítima de inconsistencia (tarea3).
5. Enlaces a otro montaje, initrd versionado y objetos ilegibles: no convertir una captura parcial en prueba de conservación (tarea4).

## Preparación y mapa de archivos

Este plan se prepara fuera del canónico; destino documental previsto al incorporar el cambio: `docs/superpowers/plans/2026-11-02-normal-update-diagnostic-A.md`, con la especificación viajando junto a él. No escribir allí ahora ni modificar este input externo sellado por su hash.

Al ejecutar, usar `superpowers:using-git-worktrees`: detectar primero si ya existe aislamiento. Preferir la herramienta nativa disponible; en su defecto worktree/checkout aislado dentro del directorio autorizado. No alterar el canónico por comodidad ni escribir su metadata fuera del sandbox sin permisos. Verificar los AGENTS aplicables a ese checkout. El plan no autoriza una operación nativa.

Rutas siguientes relativas a la raíz del checkout aislado, que se registrará con ruta absoluta en la evidencia:

| Archivo | Responsabilidad |
| --- | --- |
| `tests/acceptance/reference/test-normal-update.sh` | Rechazo apply, flujo secuencial, estados/resumen, capturas y cierre |
| `tests/acceptance/reference/normal_update_protocol.py` (nuevo) | Parser puro, coherencia raw/listado y resolución contra pkglist |
| `tests/acceptance/reference/normal_update_metadata.py` (nuevo) | Política/perfil, capturas de comandos acotadas, catálogo validado y snapshot de selección |
| `tests/acceptance/reference/normal_update_boot.py` (nuevo) | Manifiesto de rutas/montajes y comparación determinista |
| `tests/acceptance/reference/normal-update-profiles.json` (nuevo) | Identidades del único backend observado, no autorización de ejecución |
| `tests/reference/test-normal-update-diagnostic-flow.sh` (nuevo) | Regresiones de main, con cada frontera externa sustituida |
| `tests/reference/test_normal_update_diagnostic.py` (nuevo) | Unitarios y composición de protocolo/catálogo/boot/runner privados |
| `tests/fixtures/reference/acceptance/normal-update/diagnostic/` (nuevo) | Capturas/protocolos, perfiles de prueba, material público firmado y procedencia |
| `tests/acceptance/reference/README.md` | Describir preflight nuevo, política necesaria y suspensión de apply |

No modificar `tools/reference/slack-update-reference.sh`, configuración productiva ni la suite118 existente. Mantener API/comportamiento de `extract_slackpkg_candidates`, `run_metadata_refresh`, `run_candidate_probe`, launcher y validadores históricos para sus callers de pruebas; main pasa a wrappers nuevos y sus tests deben envenenar los viejos para demostrar que no los usa. Esto no los convierte en nuevas entradas aprobadas de operación. Preservar los textos que la suite118 comprueba cuando siguen siendo ciertos; por ejemplo, la afirmación de boot se delimita añadiendo `within the declared boot manifest`, sin promesa sobre el host completo.

## Contratos compartidos que fija este plan

**Estados y errores.** Bash: `FIRST_FAILURE_REASON`, `TERMINAL_STAGE`, `FINALIZATION_ERRORS`; estados por etapa `not-run|passed|failed`. Conteos desconocidos y digest incompleto se escriben `not-calculated`; cero solo significa una lista vacía validada. Exit2 para argumentos/capacidad/entorno previos al caso; exit1 para fallo diagnóstico o cierre; exit0 solo preflight completo con al menos un candidato. Los estados raw permanecen en `*.exit`. No cambiar la tabla estable0–8 del motor de referencia.

**Política del caso (dato nuevo, no grant).** Añadir `--diagnostic-policy PATH` al parser; validarla en main antes de cualquier backend. Parsear argumentos preflight sin ella puede seguir funcionando para compatibilidad, pero main debe rechazar su ausencia. JSON estricto schema1, sin claves duplicadas/desconocidas, con: `target`, `hostname`, `boot_id`, `backend_profile`, `backend_sha256` (mapa de archivos), `configuration_sha256` (mapa), `mirror` HTTPS, `public_keyring` absoluto, `public_keyring_sha256`, `primary_fingerprint`, `boot_profile`, `required_mounts` (mapa destino→source/fstype) y `extra_boot_files` (lista absoluta). Ninguna credencial, URL con userinfo, comandos shell, wildcard de rutas o código se admite en ella. Copia exacta y hash en evidencia.

Perfil inicial `slackpkg-15.0.10-count-v1`: registrar hashes de `/usr/sbin/slackpkg` y los siete archivos regulares observados bajo `/usr/libexec/slackpkg`, conjunto exacto de extensiones ejecutables y algoritmo de pkglist. Obtener esos bytes de los inputs900/920 retenidos, contrastarlos con el host por lectura y registrar procedencia antes del commit; no inventar hashes ni seleccionar perfil solo por VERSION. No admitir16 por similitud de nombres. Los perfiles de prueba se inyectan en funciones importadas/dobles; no crear `--test-mode` ni bypass por env en la CLI nativa.

`configuration_sha256` inventaría los archivos efectivos bajo `/etc/slackpkg` sin seguir directorios simbólicos; validar conjunto y hashes, no solo cuatro nombres elegidos. El perfil inicial acepta únicamente archivos regulares/directorios de configuración; un enlace no previsto requiere revisión de perfil y se rechaza antes de backend. No sourcear esa configuración para descubrir valores. Perfil examinado exige WORKDIR `/var/lib/slackpkg`, un mirror activo coincidente y extensiones exactas. Una configuración distinta necesita revisión de perfil; rechazar antes de llamar al backend. La clave del caso permanece una fijación explícita, no procedencia G1 autenticada.

**Funciones Python.** Los tres módulos tienen `DiagnosticError(reason: str)` importado de `normal_update_protocol.py`; sus resultados son dict JSON serializables, sin mensajes de éxito en stdout al importarse. CLI devuelve0 válido,1 inválido con JSON de error y canales retenidos. Escribir resultados en archivo nuevo o reemplazo atómico propio; nunca publicar listas parcialmente escritas.

**Fronteras Bash nuevas**, llamadas con argumentos entre comillas:

- `validate_diagnostic_policy POLICY OUT_JSON`: lectura/identidad y snapshot inicial del caso.
- `run_diagnostic_command ACTION PREFIX`: ACTION solo `update|install-new|upgrade-all`; canales `PREFIX.stdout`, `.stderr`, `.exit`, `.capture.json`; retornar raw real, también20. Usa `DIAGNOSTIC_POLICY` fijada por el parser; la CLI Python recibe esa ruta y vuelve a validar identidad/perfil antes de iniciar el backend. No basta una variable que diga validated=true.
- `validate_diagnostic_catalog POLICY BEFORE_JSON OUT_DIR`: adquirir/validar y escribir `catalog.json` y snapshot canónico `selection.json`.
- `validate_diagnostic_probe ACTION PREFIX CATALOG OUT_PREFIX`: lista `.candidates.txt` y `.validation.json` solo tras validación completa.
- `capture_selection_state POLICY OUTPUT`: inventario de configuración/backend, metadata consumida y paquete instalado; comparación exacta contra baseline posterior a refresh antes/después de cada sonda.
- `capture_diagnostic_boot POLICY OUTPUT`: manifiesto nuevo, sin cambiar el helper antiguo si lo necesitan callers históricos.
- `finish_diagnostic STAGE REASON`: idempotente; único cierre tras iniciar evidencia. Mantener `finish_with_evidence` histórico para tests aislados; main usa el cierre nuevo.

No invocar helpers Python mediante `eval`; CLI finita con argumentos explícitos para estas operaciones. No crear un dispatcher que acepte comandos arbitrarios desde la política.

### Task 1: Rechazo temprano de apply

**Files:** modificar harness principal; crear test de flujo y `diagnostic/README.md` con procedencia/límites de fixtures. Consumo: `parse_arguments` existente. Produce: rechazo incondicional del modo apply en main.

- [ ] **1. Escribir regresión `apply-blocked-before-backend`.** Sourcear harness en un subshell, sustituir root/host/capturas por datos privados y todos los wrappers/launcher por sentinelas que registran llamada y devuelven97. Invocar main con hostname/digest válidos y todas las opciones permisivas.

  Assert: `rc == 2`, stderr contiene `apply-disabled-until-selection-consumption-binding`, traza backend vacía y launcher no alcanzado. Añadir variante sin privilegios para verificar que tampoco toca backend ni hace refresh.
- [ ] **2. Ejecutar rojo:** `bash tests/reference/test-normal-update-diagnostic-flow.sh apply-blocked-before-backend`. Debe fallar porque la base intenta avanzar, no por un fixture ausente. El driver nuevo acepta selección de caso; sin argumento corre todos.
- [ ] **3. Implementar gate** inmediatamente después de `parse_arguments` y antes del root gate, comandos, output root y capturas. Mantener reconocimiento de opciones para devolver explicación de capacidad suspendida. Actualizar ayuda en esta misma tarea.
- [ ] **4. Verificar verde** con el caso anterior y `bash tests/reference/test-normal-update-acceptance-harness.sh`:118 controles/0 fallos, sin tocar sus expectativas. Capturar diff de referencia vacío.
- [ ] **5. Commit** solo archivos de esta tarea con identidad real: `fix: block normal-update apply until candidate consumption is bound`. Si no hay identidad configurada (no se encontró en la comprobación inicial), conservar diff revisable y resolver identidad con el usuario antes del commit; no inventarla ni trasladar credenciales.

### Task 2: Estados secuenciales, captura y cierre ante errores

**Files:** harness; módulos metadata y protocolo nuevos y test Python; ampliar test de flujo. Crear en protocolo únicamente `DiagnosticError(reason: str)` en esta tarea; su implementación guarda `reason` y hereda de Exception. Consume gate1. Produce wrappers `run_diagnostic_command`, `finish_diagnostic` y estados definidos arriba; validación catálogo/sondas conectada en tareas3/4 antes de declarar A completo.

- [ ] **1. Escribir casos rojos de main** `refresh30-stops`, `install42-stops`, `upgrade42-no-digest`, `capture-failure`, `archive-failure`, `signal-stops`. Dobles validadores con resultados privados permiten probar el control sin atribuir validación real. Assert trazas respectivamente `[update]`, `[update, install-new]`, `[update, install-new, upgrade-all]`; `result=FAIL`, primer error intacto, digest `not-calculated`, ninguna referencia apply. Una sonda válida previa se conserva marcada parcial.
- [ ] **2. Ejecutar rojo:** `bash tests/reference/test-normal-update-diagnostic-flow.sh`. Además crear `RunnerTests` en el test Python: hijo privado que deja descendiente escribiendo, termina padre temprano, timeout y SIGTERM; comprobar que no se hashean canales aún abiertos y no se avanza.
- [ ] **3. Implementar `run_captured(argv: list[str], prefix: Path, timeout: float) -> dict` interno** en metadata, sin exponer argv genérico por CLI. Subprocess con stdin DEVNULL, canales separados y sesión/grupo propio; plazos600s update,180s sondas,60s herramientas auxiliares; timeout/señal→TERM, esperar5s, KILL si precisa y esperar otros5s. Registrar grupo sin resolver/canales incompletos como fallo, no prometer limpieza global. Tests usan plazos breves inyectados por función, nunca por opción nativa.

  El runner instala handlers INT/TERM que terminan su grupo backend antes de salir; main solicita la terminación del runner activo y espera su cierre. El grupo del backend se controla explícitamente, pues una sesión hija no queda resuelta matando solo al runner. Las pruebas inspeccionan descendientes propios, incluidos los que sobreviven al padre. No registrar captura completa si queda alguno.

  `run_diagnostic_command` usa ruta backend validada `/usr/sbin/slackpkg`, LC_ALL=C/LANG=C/TERM=dumb y flags `-dialog=off -batch=on -default_answer=n -postinst=off`, con la acción al final. Esto no llama al helper histórico que responde y. El retorno0 de update aún necesita tarea3; n puede evitar descarga cuando no cambió ChangeLog y la validación posterior decidirá coherencia. Capturar raw20 sin normalizarlo.
- [ ] **4. Implementar flujo y cierre**: retornar a finalización tras primer error; traps INT/TERM cierran grupo propio activo, marcan fallo y no reentran al handler. Tras iniciar evidencia, intentar capturas finales y TAR/sidecar aunque falle una comparación. Fallo TAR conserva directorio/resumen y no anuncia archivo publicado; errores secundarios en `FINALIZATION_ERRORS`. Si falla captura inicial, no llamar backend. Main no debe usar los helpers legacy de refresh/parser/launcher. Hasta completar tareas3/4, los wrappers de validación/captura aún no implementados devuelven `diagnostic-validation-not-ready` antes de todo backend; únicamente los dobles de tests avanzan. No introducir un PASS provisional. Cualquier fallo invalida el campo revisable `candidate_set_sha256` a `not-calculated`; si interesa retener un digest observado completo, usar campo separado `observed_candidate_set_sha256` con alcance no autorizable.
- [ ] **5. Verificar verde:** driver Bash completo hasta esta tarea y `python3 -B tests/reference/test_normal_update_diagnostic.py RunnerTests -v`. Añadir control de cierre satisfactorio verificando sidecar desde el directorio padre y contenido del TAR privado.
- [ ] **6. Commit** `fix: stop diagnostic flow at the first failed stage`, con el mismo control de identidad. Ningún estado intermedio de esta tarea se presenta como preflight nativo validado.

### Task 3: Política, catálogo observado y protocolo de candidatos

**Files:** ampliar protocolo creado en2; crear perfilesJSON y fixtures; ampliar metadata, harness, tests Python/flujo. Consumo: wrappers/runner2 y su DiagnosticError. Produce todas las validaciones de catálogo y sondas, snapshots y digest completo.

**Interfaces Python concretas:**

`load_policy(path: Path, profiles_path: Path) -> dict`; `capture_selection(policy: dict) -> dict`; `fetch_https(url: str, output: Path) -> dict`; `validate_catalog(policy: dict, before: dict, evidence: Path) -> dict`; `parse_probe(action: str, stdout: bytes, raw: int, catalog: dict) -> list[str]`.

`catalog` schema1 incluye `profile`, `primary_fingerprint`, `filelist_timestamp`, `lastupdate_before`, `lastupdate_after`, hashes de metadata/configuración/backend y `packages`: mapa filename→lista de registros `{repository,path,name,version,arch,build,extension}`. La lista permite detectar ambigüedades, no colapsarlas al cargar. stdout/stderr no entran en ese catálogo. El wrapper parser valida también captura completa/estado raw en `.capture.json`; no da por buenos bytes cuyo runner falló.

- [ ] **1. Escribir `PolicyTests`, `CatalogTests`, `ProtocolTests` rojos** con estas aserciones concretas:

  | Casos | Aserción |
  | --- | --- |
  | Política ausente, duplicada, perfil16 desconocido, hash/toolset/config o hostname/boot distintos | falla antes de backend y de red |
  | Update0 + pkglist antiguo; fingerprint distinto; firma inválida; FILELIST checksum discordante; LASTUPDATE inválido/regresivo | `DiagnosticError`, ninguna sonda |
  | Firma/catálogo coherentes con fecha igual o superior | catálogo válido; no texto latest o descarga nueva garantizada |
  | Índice/configuración/paquetes cambian antes o después de una sonda | no lanzar la siguiente; no digest final |
  | Listado900 con contador, arquitecturas x86/x86_64 y prompt de acción correcto | nombres completos exactos, orden canónico LC_ALL=C |
  | Ghost en stderr y raw20 con ausencia explícita stdout | lista vacía; ghost nunca en digest |
  | Fila solo fuera de bloque, duplicado, contador erróneo, truncamiento, bloques múltiples, prompt/acción incorrectos, raw20 con filas | parser falla |
  | Nombre que no existe o resuelve a más de un registro | parser falla; no escoger primer registro |
  | Install vacío20 + upgrade válido0 | unión exacta de upgrade; escenario puede PASS |
  | Ambos vacíos20 | sondeos válidos pero escenario FAIL/no-candidates |

  Assertions representativas: `assert parse_probe('install-new', empty_install, 20, catalog) == []`; `with self.assertRaises(DiagnosticError): parse_probe('upgrade-all', wrong_count, 0, catalog)`. No probar raw20 como criterio contractual nuevo.
- [ ] **2. Ejecutar rojo:** `python3 -B tests/reference/test_normal_update_diagnostic.py PolicyTests CatalogTests ProtocolTests -v`; driver main con validadores reales sobre fixtures, adquisición y runner sustituidos. Que fallen las aserciones nuevas, no un acceso al host.
- [ ] **3. Preparar fixtures trazables** copiando únicamente capturas públicas900 por acción, preservando vacíos/prompts/contador. No cambiar las fixtures antiguas de tabla. Para integración criptográfica offline, añadir `metadata/CHECKSUMS.md5.gz`, `FILELIST.TXT.gz`, `CHECKSUMS.md5.asc`, `slackware.gpg` desde920, con tamaños/hashes de origen y aviso de clave pública/procedencia no independiente. Descomprimir solo en memoria/temporales propios con límite64MiB por archivo; no extraer TAR a rutas vivas. Conservar la transformación `pkglist.awk` observada como fixture de texto hasheada y ejecutarla solo con fixture propia. No exportar keyrings del usuario/root ni usar una clave privada.
- [ ] **4. Implementar política y catálogo**: verificar identidad antes del refresh y otra vez después; snapshot LASTUPDATE inicial requerido. Adquisición propia de CHECKSUMS, firma y FILELIST del mirror fijado: solo HTTPS en cada redirección, URL sin userinfo, máximo64MiB por archivo/128MiB por adquisición, timeout de lectura10s y plazo total60s; salida a archivos propios nuevos. Nada de flags o shell procedentes de configuración. Retener origen/URL efectiva/tamaño/hashes/errores.

  GPGV en homedir privado, `--keyring` absoluto de bytes fijados y status-fd dedicado; requerir proceso0 y VALIDSIG con fingerprint primario del caso, rechazar claves/firma adicionales no esperadas y estados negativos. Sin keyserver, ownertrust, autoinicio de agentes o reutilización del homedir del usuario. Comparar CHECKSUMS y firma adquiridos con los efectivos; FILELIST→MD5 firmado; fecha con `date -d` de argv fijo y locale C, igual al LASTUPDATE posterior y no regresiva. Regenerar todo pkglist mediante awk exacto del perfil y la transformación observada `sed -e 's/^M//g'`, reteniendo bytes/canales; comparar íntegramente. Transformación compartida ≠ oráculo independiente.

  Snapshot de selección incluye backend/configuración, todos los archivos regulares del WORKDIR efectivo más enlaces declarados, presencia/ausencia y estado instalado `/var/log/packages` resuelto. Rechazar objetos/links inesperados. Después del refresh se fija la baseline de sondas; compararla antes/después de cada una. No restaurar metadata automáticamente ni reintentar cuando difiera.
- [ ] **5. Implementar parser estricto** con decodificación UTF-8 estricta del perfilC, gramática de filename Slackware compatible con x86, sin regex sobre el texto entero. Bloque empieza con búsqueda de la acción, filas de nombre completo y contador único `Total package(s): N`, termina con prompt install/upgrade y n. Se permite preámbulo de integridad conocido y espacios vacíos; cualquier formato no reconocido dentro del protocolo falla. Raw20 exige el literal real15 `No packages match the pattern for install. Try:` o `...upgrade. Try:` y cierre conocido sin filas, con su ayuda de comando; no usar el literal sintético `install-new` como protocolo nativo. La fixture de revisión sintética se transforma explícitamente en caso adversarial, no se declara soporte de ese dialecto.

  Comparar número de filas con N antes de deduplicar; resolver cada filename de forma única en catálogo. Canonizar nombres con el mismo orden byte/C para conservar el digest histórico. `validate_diagnostic_probe` nunca lee stderr como lista. Main clasifica/digiere solo después de validar ambas sondas y estado de selección.
- [ ] **6. Verificar verde** los tres grupos y todos los casos Bash anteriores. Añadir `CatalogSignatureIntegrationTests`: gpgv real con material público920 privado, control de firma manipulada y pin incorrecto; adquisición sin red. Si falta gpgv, la prueba requerida falla con razón explícita, no SKIP silencioso. Run: `python3 -B tests/reference/test_normal_update_diagnostic.py CatalogSignatureIntegrationTests -v`.
- [ ] **7. Commit** `fix: validate diagnostic catalogs and candidate provenance`, incluyendo fixtures y procedencia; revisar que no contiene secretos ni keyrings privados.

### Task 4: Manifiesto de boot e identidad del código

**Files:** crear boot; ampliar harness/tests. Consume política3 y cierre2. Produce `capture_diagnostic_boot` y hashes de todos los módulos efectivos.

**Interfaces:** `capture_boot(policy: dict, fs_root: Path = Path('/'), mounts: Optional[dict] = None) -> dict`; `compare_boot(before: dict, after: dict) -> bool`. Optional procede de typing. `fs_root`/montajes inyectables solo para tests importados, no opción que redirija silenciosamente una CLI nativa. JSON schema1 determinista con `profile`, `required_mounts`, `entries` (ruta lógica→tipo/metadatos/hash/target) y errores explícitos; contexto temporal/boot se guarda separado para no introducir un diff por fecha de captura.

- [ ] **1. Escribir `BootTests` rojos:** árbol privado con initrd.gz ausente, kernel/initrd versionados, links genéricos, microcode, grub.cfg/grubenv y montaje EFI simulado. Aserciones: snapshots iguales→true; cambiar solo `initrd-6.18.45.img`, cambiar target, crear/borrar objeto o quitar montaje→false/error. Lazo/rotura/link a fuera sin declaración/FIFO/lectura fallida→error, sin PASS parcial. Mock de PermissionError a nivel de lector para que el test sea válido también si el executor tuviera privilegios.
- [ ] **2. Ejecutar rojo:** `python3 -B tests/reference/test_normal_update_diagnostic.py BootTests -v` y caso Bash `boot-incomplete-stops-before-refresh`.
- [ ] **3. Implementar el manifiesto** de `/boot` recursivo, cruzando EFI solo si concuerda con `required_mounts`; no seguir directorios simbólicos. Incluir todas las configuraciones de GRUB/GenInitrd/mkinitrd del diseño, con ausencia explícita. Archivo regular: tipo, modo, uid/gid, tamaño y SHA256; enlace: lstat, texto literal, resolución acotada con detección de ciclos y destino final capturado. Un destino exterior necesita estar en `extra_boot_files` explícitos. Registrar directorios para detectar altas/bajas; rechazar tipos especiales, montajes inesperados y cambios durante lectura detectados con stat antes/después. No afirmar ausencia de races no detectables por estas comparaciones.

  `boot_profile=current-grub` permite este dominio solo con targetcurrent. `slackware15-elilo` es perfil separado: `/boot` y `/etc/elilo.conf`, sin mezclar GRUB ni afirmar layout nativo15 validado; exigir que su política declare los montajes/rutas de cargador efectivos y que estén presentes/capturados. Si no pueden identificarse mediante la política y datos leídos, fallar `unsupported-boot-layout`; los fixtures no habilitan por sí mismos ejecución en15.0. No sourcear configuración, interpretar grub.cfg ni ejecutar generadores.
- [ ] **4. Integrar identidad y alcance:** `host.txt` incluye SHA256 de harness, los tres módulos, profilesJSON, referencia, template, política y backend, contexto host/boot/kernel/cmdline. La aserción de igualdad se limita al manifiesto y a los bytes/metadatos declarados. Un fallo de lectura inicial impide refresh; uno final impide PASS/digest revisado. No se prueba arranque, elección del menú ni recuperación.
- [ ] **5. Verificar verde** BootTests, driver Bash completo y suite118 inalterada. Comprobar que hashes registrados corresponden a los bytes ejecutados y que ningún fixture contiene valores de sudo.
- [ ] **6. Commit** `fix: scope diagnostic boot preservation to complete manifests`.

### Task 5: Guía actual, composición y entrega

**Files:** guía de aceptación, procedencia fixtures y documentos de este cambio. Consumo: tareas1–4. Produce diff revisado y entrega de A, sin reapertura apply.

- [ ] **1. Añadir regresión de composición** `end-to-end-private`: main real con perfiles/catálogo/parser/boot reales sobre árboles privados; solo adquisición, ejecución backend y lecturas del host sustituidas. Fixture control mínimo de ambas listas válidas y caso ghost/raw20. Assert control0/PASS con nombres/digest exactos, ghost no candidato, ambos vacíos1/no-candidates y ausencia de apply. Una sentinel en PATH para slackpkg/sudo/update-grub/mkinitrd/reboot real marca fallo si se alcanza; sustituir también fronteras que emplean rutas absolutas. No basta envenenar PATH.
- [ ] **2. Ejecutar rojo antes del último ajuste de composición**, si el test revela un fallo real. Si ya pasa, conservarlo como control de integración y documentar que no es prueba roja de una corrección pendiente. No inventar un fallo ni presentar un test verde inicial como TDD de un defecto.
- [ ] **3. Actualizar guía** normal-update con bloqueo apply, `--diagnostic-policy`, perfil15 observado, validación limitada del catálogo, layout desconocido que falla y artefactos emitidos. No proporcionar un comando operativo listo para ejecutar sin caso/recovery. Conservar registros históricos aceptados, distinguirlos del nuevo comportamiento. Añadir ejemplo JSON explícitamente no operativo, con campos pendientes y que main rechace; no rellenar permisos/host/boot con datos viejos. Documentar helpers legacy y alcance de compatibilidad. Incorporar plan/spec como documentos previstos, manteniendo procedencia exacta de inputs externos.
- [ ] **4. Ejecutar validación final apropiada**, tras leer completos los tests adicionales antes de ejecutarlos para confirmar aislamiento:

  ```bash
  bash -n tests/acceptance/reference/test-normal-update.sh
  bash -n tests/reference/test-normal-update-diagnostic-flow.sh
  python3 -B tests/reference/test_normal_update_diagnostic.py -v
  bash tests/reference/test-normal-update-diagnostic-flow.sh
  bash tests/reference/test-normal-update-acceptance-harness.sh
  bash tests/reference/test-slackpkg-postinstall-policy.sh
  bash tests/reference/test-error-exit-codes.sh
  bash tests/reference/test-current-normal-update-authorized-apply-harness.sh
  git diff --check
  ```

  Todos rc0; suite existente118/0; los nuevos reportan su conteo real, sin preinventarlo. Son selecciones por CONTRIBUTING18/19 y control adyacente de estados/launcher, no aceptación nativa. No ejecutar143/102 globales por inercia. Si algún histórico depende legítimamente de bytes antiguos, conservarlo y su fuente emparejada; documentar el conflicto y resolver el alcance antes de declarar A completo, sin parchear fixtures/oráculos para maquillar PASS.
- [ ] **5. Revisar el diff completo** mediante `superpowers:requesting-code-review` y verificar antes de afirmar completado. Mantener intactos motor/configuración canónicos, evidencias selladas y suite118; nuevos casos deben verificar que main no invoca helpers legacy. Registrar fuente final, rangos y límites de revisión; IA no es G1.
- [ ] **6. Commit documental/final** `docs: describe diagnostic-only normal-update boundaries`. Verificar identidad, diff staged, status, historial y archivos incluidos; no añadir todo runs/ ni evidencia ajena al cambio.
- [ ] **7. Entrega para Arch**, únicamente con commits nuevos: `git bundle create` de la rama aislada con base b10552adfe1b5c6fc0f746324d0525f269eb929b como prerrequisito, `git bundle verify`, `list-heads`, SHA256 y prueba de importación en clon temporal propio con la base presente. Documentar referencia y rango exactos obtenidos, no inventados. Instrucciones Arch: verificar checksum/bundle en repo con base; comprobar remoto/estado/divergencias antes de fetch/integrar; nunca force-push implícito. No push desde esta VM.

## Criterio de cierre de A y traspaso

A termina solo con rechazo apply probado desde main; cuatro defectos diagnósticos cubiertos por pruebas del flujo y validadores; compatibilidad histórica exacta; evidencia/diff/revisión y entrega de commits reales resueltos. P1 figura **contenido por esta entrada, no resuelto**. Sin declaraciones sobre seguridad de invocar directamente el motor o helpers legacy.

Método recomendado: implementación directa en este chat (`superpowers:executing-plans`) porque las tareas comparten el estado de main y las interfaces de validación; revisión adicional al terminar. El usuario aún no eligió método ni revisó este plan. Antes de implementar, presentarlo y obtener esa revisión conforme al skill writing-plans. El trabajo actual se limita a este plan.

Futuro caso instalador: copia real identificada y retorno comprobado, candidatos actuales y revisión nueva; si actualiza kernel en esta VM, sudo update-grub verificado después de actualizar y antes de reiniciar. Ninguna tarea anterior ejecuta esas operaciones.

Implementation note: the user approved direct execution with “Ok comienza.” The pre-execution approval/status paragraphs above describe the original plan handoff, not a new native grant. The input design is retained verbatim as a historical specification. Current behavior and limits are in the acceptance guide.
