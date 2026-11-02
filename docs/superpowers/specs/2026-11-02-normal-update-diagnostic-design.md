# Propuesta de correcciones del harness diagnóstico

2 de noviembre de 2026, Europe/Madrid. Estado: **borrador para revisión del usuario**.
El usuario pidió preparar el diseño de las cinco correcciones y después eligió
explícitamente «Por etapas, con apply bloqueado hasta resolver P1». El enfoque
está elegido; este documento completo sigue pendiente de revisión y aprobación.
No es un plan de ejecución ni autorización de un caso nativo.

## Objetivo y base

Evitar que el harness atribuya a sus resultados candidatos, validación del catálogo
o conservación del arranque que sus capturas no demuestran. Impedir que su camino
apply alcance una selección distinta de la revisada. Base canónica exacta:
`b10552adfe1b5c6fc0f746324d0525f269eb929b`, árbol
`3f9e019ce067e5ccdfec44b784305c22fbd77684`.

Autoridad del diagnóstico: `../harness-review-20261102-2033/REVIEW.md`.
PAUSA920 mantiene su alcance inerte; no se crea PAUSA921 ni se cierra fase1.
Las cinco etiquetas siguientes corresponden a aquel informe, sin renumerar los
13 hallazgos/16 gaps históricos. Productor0/provisional y realesv1=0 continúan.

Se comprobó nuevamente la fuente2732/48, modos e índice limpios; suite específica
118/118; ZIP900/910/920 con SHA256 y sus verificadores. Las cuatro reproducciones
aisladas conservan sus resultados anteriores, incluido el PASS espurio raw20-stderr.
Son resultados del código anterior, no pruebas de una corrección.

## Enfoques considerados y alcance propuesto

1. **Por etapas, elegido por el usuario.** A: desactivar el acceso apply de este harness y
   reparar diagnóstico/evidencias con regresiones offline. B: diseño separado del
   enlace selección/consumo, antes de permitir apply otra vez. Reduce el cambio
   inmediato al harness y deja visible que P1 está contenido, todavía sin resolver.
2. **Transacción completa conjunta.** Cambiar también el motor de referencia para
   preparar y consumir paquetes exactos. Puede resolver P1 definitivamente, pero
   requiere tratar orden, autoactualización del backend, scripts, recuperación y
   locks en una frontera nueva de mayor alcance.

No sirve repetir el digest justo antes del launcher: la referencia aún hace
update/install-new/upgrade-all después de esa comprobación.

La etapa A propone conservar Bash y los helpers Python3 que ya utiliza el harness.
No introduce paquetes, dependencias Python nuevas ni C. El diseño se conserva aquí
como documento externo de trabajo para mantener intacto el canónico; su eventual
incorporación se hará con el cambio revisado y su política documental.

## Estado observable y terminación

El flujo propuesto es: argumentos/entorno → captura inicial → refresh → validación
del catálogo → sonda install-new y validación → sonda upgrade-all y validación →
clasificación → capturas finales/comparaciones → evidencia. Cada transición exige
que la anterior haya terminado correctamente.

El primer fallo impide cualquier sonda posterior, clasificación sobre resultados
parciales y apply. Se permiten únicamente capturas finales de lectura, cierre de
recursos propios y publicación de evidencia. Un fallo de captura o empaquetado
también devuelve no cero, conserva el directorio y no borra el error inicial.
Las salidas de subprocess, sus estados raw y los errores de finalización se
registran separados. SIGINT/SIGTERM tampoco permiten avanzar al siguiente paso.

El resumen conserva los campos históricos para sus significados actuales y añade
`terminal_stage`, `failure_reason`, estado de cada etapa (`not-run`, `passed`,
`failed`), identidad del perfil y los alcances de validación. Los contadores de
etapas no ejecutadas son desconocidos, no cero; un digest parcial no se publica
como conjunto revisado. En un fallo tras una sonda válida se retiene su lista como
evidencia parcial, claramente marcada y sin clasificación autorizable.

## P1: impedir apply sin enlace selección/consumo

En A, `--execute-apply` sigue siendo reconocible, pero main termina con error antes
de refresh, sondas o launcher. Es un rechazo de capacidad disponible, incluso con
hostname, digest y opciones kernel/críticos correctos. No existe opción/env de
escape. El helper de launcher puede conservarse para caracterización histórica,
pero no queda accesible desde main en modo apply. Se actualizarán ayuda y guía
para describir esta suspensión. No se altera el motor de referencia en A ni se
afirma que su invocación directa haya quedado protegida por este cambio.

La prueba decisiva usa main y dobles que fallan si se llama a update, una sonda o
la referencia. Debe devolver no cero y explicar el bloqueo. La existencia de este
rechazo contiene el riesgo por esta entrada; **P1 sigue abierto** hasta B.

B necesita una propuesta propia antes de implementación. Como requisitos mínimos:

- Un manifiesto revisable que ligue host/boot/caso, estado instalado, configuración,
  blacklist/prioridades, hashes del harness/motor/backend, catálogo validado y
  acciones ordenadas install-new/upgrade-all con identidades y bytes de paquetes.
- Preparar/verificar los archivos antes de la primera mutación, con ubicación
  privada e identidad estable; el digest de nombres histórico no basta para
  vincular repositorio, acción, bytes u orden.
- Que el ejecutor consuma ese manifiesto y esos bytes sin otro update ni una
  selección abierta. Comprobar pertenencia a un índice no demuestra que el backend
  haya seleccionado todo lo necesario. Diseñar explícitamente la selección tras
  install-new, ya que puede cambiar el estado que usa upgrade-all.
- Definir exclusión efectiva y revalidación del estado de entrada hasta consumo;
  un lock privado del harness no bloquea slackpkg externo. Tratar la autoactualización
  de slackpkg y los efectos de doinst como transiciones explícitas, no como pasos
  silenciosos. Ningún refresh o reintento automático después de mutación.
- Revisión de recuperación real y boot del caso; detectar drift antes de instalar,
  distinguir fallo sin mutación de transacción parcial y conservar evidencia.

Este documento no elige todavía un mecanismo implementable para B ni autoriza
reabrir apply tras terminar A. No se promete atomicidad/rollback de los paquetes.

## P2: candidatos con procedencia y coherencia

Cada sonda retiene stdout, stderr y estado raw en archivos separados. Un log
combinado, si se mantiene para lectura, nunca es entrada del parser. No se eliminan
mensajes stderr; tampoco se convierten automáticamente en candidatos o en fallo
por su mera presencia. Se valida el protocolo conocido y sus errores explícitos.

El parser de uso nativo se selecciona por identidad de backend/configuración,
sin detección permisiva de cualquier formato que contenga un .txz. Para el backend
local15.0.10 examinado: bloque entre el encabezamiento de búsqueda esperado y
`Total package(s): N`, filas completas con nombres, cierre con prompt de la acción
correcta y respuesta negativa. N debe coincidir con las filas; duplicados,
filas inválidas, bloques múltiples/truncados o nombres fuera del bloque son errores
de protocolo si intentan suplir el listado. No se aplica una regex a todo stdout.

Las fixtures antiguas con tabla `[ Repository ] [ Package ]` se conservan exactas;
pueden seguir sirviendo al helper histórico y sus118 controles. Nuevas fixtures
derivadas de las capturas900 cubrirán el perfil real con contador, sin presentarlas
como ejecución actual. Un perfil futuro16 requiere su propia lectura y pruebas;
no se hereda automáticamente la validación del backend15.

Coherencia mínima: raw0 requiere listado no vacío completo y rechazo de instalación;
raw20 requiere la forma explícita de ausencia de candidatos de la acción y lista
vacía; cualquier otro raw falla. raw20 con filas o raw0 con salida incompleta falla.
La ausencia válida de una acción permite sondear la otra. Si ambas quedan vacías,
este escenario histórico de actualización no obtiene PASS: termina no cero con
razón `no-candidates`, sin fabricar un candidato. Esto no cambia los criterios
contractuales originales install20/upgrade20.

Cada fila aceptada debe resolver a un registro único del catálogo validado, con
repositorio/ruta/arquitectura coherentes; conflictos de identidad se rechazan.
Se conserva el digest histórico de la unión ordenada de nombres para comparación
documental. No se presenta ese digest como permiso suficiente de instalación.

## P2: cortar tras refresh o sonda fallidos

Aplicar el flujo anterior a fallos raw, fallo de validación del catálogo, parser,
clasificación y captura. El caso refresh30 debe dejar traza de **solo update**;
install-new42 debe impedir upgrade-all; upgrade-all42 no debe producir digest
válido ni entrar a apply. Se conserva el estado raw original sin normalizarlo a0.
La finalización se prueba mediante main, no solo el helper que devuelve el error.

## P2: catálogo validado, sin deducir frescura de rc0

El retorno0 del refresh significa únicamente que ese proceso terminó con0.
Antes de sondas, un validador explícito debe ligar el catálogo consumido con una
observación del espejo configurado y comprobar:

- Identidad de mirror/configuración y backend; evidencia de adquisición con canales,
  estados y hashes. Archivos CHECKSUMS y firma completos y verificación criptográfica
  válida con la clave fijada por el caso; no basta buscar `VALIDSIG` sin contrastar
  fingerprint. El uso de la clave no demuestra procedencia independiente G1.
- FILELIST adquirido cuyo checksum coincide con el catálogo firmado; fecha parseable,
  igual al LASTUPDATE efectivo y no inferior a la fecha anterior. Igualdad de fecha
  es admisible con catálogo coherente; no se exige cambio artificial ni se impone
  un plazo de caducidad sin fundamento contractual. Ausencia/corrupción del estado
  previo no permite inventar una fecha base: rechazar con razón específica.
- CHECKSUMS/firma efectivos de slackpkg coincidentes con los bytes validados;
  regeneración de pkglist desde esos CHECKSUMS usando la transformación exacta del
  backend examinado y comparación completa. Capturar además ChangeLog y las demás
  entradas efectivas de selección (incluidos configuración, blacklist y prioridades).
  Registrar sus hashes, sin afirmar que todos esos textos están firmados por esta
  verificación si no existe tal vínculo.
- Los archivos de selección y el estado instalado permanecen iguales durante ambas
  sondas. Si hay drift, se conserva evidencia y se termina; no se reintenta para
  obtener PASS. Comparaciones entre extremos no prueban ausencia de cambios y retorno
  intermedios, ni resuelven por sí solas la exclusión exigida para B.

El mecanismo de validación seguirá las relaciones comprobadas en RUN-OPERATIONS900,
pero con fallos explícitos y pruebas propias; su transformación compartida no será
un oráculo independiente. Un rc0 con pkglist antiguo, firma inválida, checksum
discordante, fecha regresiva o evidencia insuficiente impide la primera sonda.
El resultado dirá «catálogo observado validado para estas sondas», nunca latest
global ni «se descargaron metadatos nuevos» cuando los bytes puedan ser iguales.
No se ejecuta este protocolo vivo durante la preparación del diseño o sus tests.

## P2: delimitar y ampliar la observación de boot

Sustituir la promesa genérica de initrd/GRUB intactos por «manifiesto de boot
declarado, sin cambios entre capturas». El perfil GRUB de esta VM inventaría de
forma recursiva `/boot`, incluyendo su montaje EFI, y las configuraciones
`/etc/default/grub`, `/etc/default/grub.d`, `/etc/grub.d`,
`/etc/default/geninitrd` y `/etc/mkinitrd.conf`, con presencias/ausencias explícitas.
Incluye así initrd versionado/genérico, kernel, microcode, grub.cfg y grubenv;
no se fija6.18.45 como versión futura. Mantener el perfil15.0/ELILO separado.

Enumerar sin seguir directorios simbólicos; registrar cada enlace literal y
destino, cada archivo regular con SHA256/tamaño/modo/uid/gid, y los montajes
esperados. Reenumerar al final para detectar altas/bajas y retargeting. Todo destino
necesario fuera del dominio debe quedar declarado y capturado explícitamente o
provocar cobertura incompleta. Enlaces rotos, ciclos, objetos no soportados,
errores de lectura y montajes desaparecidos impiden un PASS de conservación.

Conservar hostname, boot_id, uname y cmdline como contexto. No ejecutar/sourcing
de grub.cfg, hooks o configuración para descubrir rutas. Un perfil no reconocido
falla con evidencia; no se improvisa un intérprete GRUB. La igualdad del manifiesto
no demuestra cuál menú se seleccionará, un arranque exitoso, recuperación, igualdad
global del host ni ausencia de cambios transitorios. No incluye atimes.

## Identidad, pruebas y archivos previstos

A modifica `tests/acceptance/reference/test-normal-update.sh` y su guía
`tests/acceptance/reference/README.md`. Añade pruebas actuales separadas de
caracterizaciones congeladas, preferentemente
`tests/reference/test-normal-update-diagnostic-flow.sh` y fixtures nuevas bajo
`tests/fixtures/reference/acceptance/normal-update/diagnostic/`. Los validadores
pueden extraerse a un helper Python3 vecino del harness si facilita su prueba;
esa división es decisión del implementador, sin dependencia nueva ni dispatcher.
La identidad SHA256 del harness y de todo helper efectivo se guarda en host.txt,
junto a referencia, configuración, backend y perfil. No se presupone existencia
de esas interfaces/archivos nuevos antes de implementarlos.

Orden propuesto para A: rechazo apply; corte y finalización; catálogo/parser
coherentes; manifiesto boot e identidad; documentación y revisión del conjunto.
Todo se ejecutará en checkout aislado cuando se autorice implementar. Regresiones
primero rojas por el motivo observado y después verdes con la corrección mínima.

Matriz mínima para convertir en pruebas automatizadas, sin sudo/red/backend real:

| Frontera | Fallo exigido | Control positivo |
| --- | --- | --- |
| apply | main rechaza antes de toda llamada aun con confirmaciones válidas | preflight alcanza únicamente dobles |
| refresh | raw30 y rc0 con catálogo incoherente dejan cero sondas | catálogo firmado/coherente con fecha igual o superior |
| sondas | fallo primera impide segunda; fallo segunda impide digest | ambas listas válidas y raw20 vacío + otra no vacía |
| parser | stderr ghost, texto fuera de bloque, raw20 con filas, duplicados, truncamiento, contador/acción incorrectos | listado real900 con contador, x86 y x86_64; fixture histórica exacta en su helper |
| catálogo | firma/clave/checksum/fecha/pkglist/configuración divergentes | identidad y coherencia completas; sin claim latest |
| boot | initrd versionado cambia; enlace redirigido; alta/baja; ilegible; EFI ausente | dos manifiestos completos iguales; layout separado15.0 |
| cierre | fallo captura/TAR o señal conserva primer error y no continúa | evidencia nueva con resumen y sidecar verificables |

Los tests de main sustituyen todas las fronteras externas y las capturas por
fixtures privadas; un ejecutable backend prohibido deja constancia si se alcanza.
Probar también que la evidencia retenida no contiene credenciales. Mantener las
expectativas históricas intactas; si un test congelado solo es válido en b10552a,
se ejecuta allí y se añade el contrato corregido por separado, sin relajar su oráculo.
Los118 actuales no son por sí solos la aceptación del flujo reparado;143/102 no
se repiten por inercia. El plan posterior fijará los comandos y checks requeridos.

## Límites y siguiente decisión

Esta sesión solo prepara diseño y evidencia offline externa. Sin correcciones,
commit, push o bundle. El sandbox no recuperó la credencial del llavero; no se
usó sudo ni se necesita para el diseño. La captura root910 sigue siendo histórica.
No se consultó Git remoto ni mirror nuevo; las versiones7.2.14/7.2.15 no son
candidatos operativos verificados en esta sesión.

Recuperación real, G1/G2/G3, migración, nativo/plataforma/fase1/kernel/freeze y las
reservas920 siguen pendientes. El clon ofrecido no está acreditado. Un caso
instalador futuro debe comprobar copia y retorno efectivos y volver a revisar sus
candidatos y permisos. En esta VM, si actualiza kernel: **sudo update-grub después
de actualizar y antes de reiniciar**, retorno y configuración correctos con los
artefactos pertinentes; resolver fallos antes del reinicio.

Push exclusivamente desde Arch. Si una implementación autorizada crea commits,
preparar bundle verificado con referencias/prerrequisitos; no fabricar bundle ahora.
La aprobación de este diseño permite preparar el plan de A; no supone aprobación
de B ni de una ejecución nativa. El siguiente documento será el plan con tareas,
interfaces y pruebas, después de la revisión de este diseño.
