# Plan De Trabajo First Protection

Documento vivo para ordenar el trabajo pendiente en todos los frentes (app móvil, panel web, backend/seguridad y hardware). Base para la conversación con el cliente. Se actualiza a medida que se sume documentación adicional o cambien prioridades.

Última actualización: 2026-08-12 (Pista A y B completas salvo lo pausado; en Pista C se decidió Cloud Functions y se verificó contra el emulador — encontrando y corrigiendo 2 bugs reales que nunca se habían probado —, pero el deploy real quedó bloqueado por el plan de facturación del proyecto — ver Pista C ítem 2 — y sigue pendiente la decisión de política de corte de corriente).

## Cómo Leer Este Documento

- Cada frente tiene una lista de brechas (`falta`) verificadas contra el código actual, no solo contra la documentación.
- Prioridad: 🔴 alta (bloquea demo/producción o es riesgo de seguridad), 🟠 media (mejora funcional esperada por el cliente), 🟡 baja (pulido/optimización).
- "Evidencia" indica dónde se verificó el estado (archivo o doc).

## Fuentes Revisadas

**En el repositorio** (código y docs versionados):

- Código en `lib/`, `functions/`, `scripts/`, `test/`.
- `README.md`, `apuntes.txt`, `docs/device-api-contract.md`, `docs/hardware-roadmap.md`, `docs/integration-checklist.md`, `docs/physical-device-integration.md`, historial de commits (`git log`).

**Documentos externos aportados por el cliente/usuario** (PDF, fechados 27 de mayo de 2026, no versionados en este repo):

1. *Contrato API dispositivo First Protection* — v1, integración STM32/SIM7600/nube.
2. *Manual interno de uso y pruebas First Protection* — v1.0, guía de QA y demo.
3. *Estado del proyecto First Protection* — informe ejecutivo de cierre MVP.
4. *GY-NEO-M8N GPS MODULE* — datasheet del módulo GPS.
5. *Guía de desarrollo y entornos First Protection* — v1.0.
6. *Arquitectura técnica del sistema First Protection* — v1.0.

---

## ⚠️ Hallazgo Crítico: Documentación vs. Código Real

Los 6 documentos aportados (fechados **27-may-2026**) describen un estado del proyecto más avanzado y prolijo que lo que existe hoy en el repositorio (verificado el 11-ago-2026, con el último commit real del 01-jul-2026). Esto hay que resolverlo **antes** de repetirle estas afirmaciones al cliente como si fueran el estado actual.

| Lo que dicen los documentos de mayo | Lo que hay realmente en el repo (verificado en código) |
|---|---|
| "Flujo de comandos: **Cerrado para MVP** — la app crea comandos pendientes y espera ACK para estado real." | `admin_dashboard_web.dart` y `client_home_screen.dart` siguen escribiendo el actuador **directo** vía `actualizarComandoDispositivo`. No está cerrado. |
| "Reglas Firebase: **Base versionada** (archivo incluido); falta prueba formal en emulador." | No existe `database.rules.json` en el repo, y `firebase.json` no referencia ningún archivo de reglas. No hay reglas versionadas todavía. |
| Referencian `docs/development-guide.md`, `docs/internal-user-manual.md`, `docs/project-decisions-and-risks.md`, `docs/delivery-log.md` como documentación disponible. | Ninguno de esos 4 archivos existe en `docs/`. Solo existen los 5 archivos ya listados en "Fuentes Revisadas". |
| Arquitectura de hardware da por **elegido** el módem SIM7600 (LTE/4G), con nota "por confirmar modelo exacto y bandas". | `docs/hardware-roadmap.md` e `docs/integration-checklist.md` (commit **01-jul-2026**, más reciente que los PDF) dicen explícitamente: *"no hay módulo SIM/celular todavía"* y marcan esto como el bloqueo crítico de la Fase 3. |
| Coinciden ✅: script `functions/package.json` con script `test:smoke`, y `scripts/stm_simulator.py` con escenarios `parked/drive/carjacking/offline` — esto sí existe tal cual en el repo. | Confirmado en código. |

**Lectura más probable:** los documentos de mayo parecen redactados como cierre/entrega de una etapa (o por otra persona/rol) sin que el código correspondiente se haya terminado de mergear, o esos archivos y ese avance quedaron en otro lugar (otra máquina, otra rama, otro repo) y nunca llegaron a este repositorio. En particular, la contradicción sobre el **SIM7600** es la más importante: mayo dice "ya elegimos módem", julio dice "no hay módem definido". Esto necesita una respuesta directa de la persona a cargo de hardware antes de la reunión — no se puede asumir ninguna de las dos versiones.

**Recomendación para la reunión con el cliente:**
- No presentar "flujo de comandos cerrado" ni "reglas Firebase versionadas" como completado — decir que está en curso (ya está en este plan).
- Preguntar si existen los 4 documentos referenciados (`development-guide`, `internal-user-manual`, `project-decisions-and-risks`, `delivery-log`) en algún otro lugar — tienen contenido valioso (guía de entornos, plan de pruebas) que conviene recuperar en vez de rehacer.

### Actualización 2026-08-12 — Contradicción Del SIM7600 Resuelta

Se tomó una decisión explícita en dos etapas en vez de forzar una sola respuesta a "¿sigue vigente el SIM7600 o no?":

- **Prototipo actual:** módem **SIMCom A7670C/A7670SA** (LTE Cat-1). Mismo fabricante y set de comandos AT que el SIM7600, así que el firmware que se escriba ahora no se pierde si más adelante se sube a Cat-4. Costo muy inferior (USD 10-25 importado vs. ~CLP 90.490 del SIM7600 con stock en Chile) — coherente con que esta etapa es un prototipo/MVP, no producción en volumen.
- **Version profesional/producción futura:** el SIM7600 queda como upgrade evaluado y no descartado, para cuando el proyecto pase de "dar la vuelta" con un vehículo de prueba a un producto más robusto.
- Se descarta explícitamente cualquier módulo 2G (tipo SIM800L): Entel ya completó su apagón de 2G (2024) y Movistar/Claro tienen confirmado el cierre de 2G y 3G en Chile para 2025-2026 — comprar un módulo 2G hoy sería comprar algo que puede quedar sin red durante el piloto.
- Detalle completo en `docs/hardware-roadmap.md` (sección "Decisión De Modem"), `docs/integration-checklist.md` y `docs/avance-hardware-dispositivo.md`.
- Sigue pendiente (no bloqueante): confirmar la variante de bandas exacta del A7670 contra el operador que se use en el piloto.

---

## 1. Brechas — App Móvil (Cliente)

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🟢 **Resuelto (2026-08-12)** | Los comandos ya no modifican el actuador de inmediato: pasan por `device_commands/` y esperan ACK. | `database_service.dart:actualizarComandoDispositivo` ya no escribe `dispositivos/{id}/{campo}`; `functions/index.js:ackCommand` es el único que lo hace, y solo cuando `status: executed`. | Era el hito de sincronización del Sprint 2. El simulador STM sigue siendo quien responde el ACK mientras no exista hardware real. |
| 🟢 **Resuelto (2026-08-12)** | Estado del comando (pendiente / recibido / ejecutado / fallido / expirado) visible en la UI. | `client_home_screen.dart` (badge en slider y botones de humo/sirena) y `admin_dashboard_web.dart` (pestaña "COMANDOS"), ambos sobre `DatabaseService.escucharComandosDispositivo`. | Hoy va a mostrar casi siempre "Pendiente" porque el punto anterior (actuador directo) sigue sin resolverse — es exactamente lo que esta vista deja visible, en vez de ocultarlo. |
| 🟢 **Resuelto (2026-08-12)** | Se registra `usuarios/{uid}/liveLocation` y existe una heurística básica de cercanía usuario-vehículo. | `LiveLocationService` (geolocator) + `VehiculoController.iniciarSeguimientoUsuario`/`_evaluarCercania`; `DatabaseService.actualizarUbicacionUsuario` y `registrarAlertaProximidad`. UI en `client_home_screen.dart` (marcador de usuario, chip de distancia, banner de alerta). | Heurística cliente: si el vehículo está a ≥80 m y con velocidad ≥8 km/h, se crea un evento `posibleAlejamientoVehiculo` en `eventos/{deviceId}` (el cliente ya tiene permiso de escritura ahí). **No** cambia `systemMode` ni activa protocolo automáticamente — eso sigue pendiente de una decisión server-side (ver Pista C y "Modos Del Sistema" en `physical-device-integration.md`). Requiere el permiso de ubicación del teléfono; si se niega, la UI lo indica pero no bloquea el resto de la app. |
| 🟢 **Resuelto (2026-08-12), parcial** | Modo estacionado/armado (`systemMode`: `normal`/`armed`). Switch en la app, guarda la posición del vehículo al armar (`armedAt`) y alerta si se mueve más de 100 m estando armado (`vehicleMovedWhileArmed`). | `VehiculoController.alternarModoArmado`/`_evaluarModoArmado`, `DatabaseService.actualizarModoArmado`/`registrarAlertaModoArmado`, control en `client_home_screen.dart`. | Solo implementa 2 de los 8 estados que sugiere `physical-device-integration.md` (`normal`/`armed`) — `proximityWatch`, `suspiciousMovement`, `carjackingSuspected`, `theftConfirmed`, `service`, `offline` quedan para más adelante si se necesitan. No permite armar si el vehículo reporta velocidad > 5 km/h (evita armar "por error" en marcha). |
| 🟠 | Sin notificaciones (SMS, correo, llamada a central). | Pendiente explícito en `apuntes.txt`. | Depende de definir proveedor (Twilio/Firebase Cloud Messaging/central telefónica). |
| 🟢 **Resuelto (2026-08-12)** | Registro de datos del propietario desde la app móvil (nombre, RUT, email, teléfono, domicilio, contacto de emergencia). | Nueva pantalla `DatosPropietarioScreen`, accesible desde el ícono junto al historial en el AppBar. `DatabaseService.obtenerDatosPropietario`/`actualizarDatosPropietario`. | Mismo esquema de datos que ya usaba el panel web (campos planos en `dispositivos/{idDispositivo}`, no en `usuarios/{uid}` — se mantuvo así por consistencia, aunque signifique que si un dueño tiene 2 vehículos edita sus propios datos 2 veces). Se eliminó `usuario_propietario_model.dart`: era código muerto con una forma de datos que no coincidía con la real (sugería `usuarios/{uid}` y `misVehiculos`). No incluye marca/modelo/color/patente ni campos operativos (fecha instalación, mantenimiento, estado suscripción) — esos siguen siendo edición exclusiva del panel admin. |
| 🟢 **Resuelto (2026-08-12)** | Historial de eventos visible para el cliente. | Nueva pantalla `HistorialEventosScreen`, accesible desde el ícono de historial en el AppBar del dashboard móvil. Reutiliza `DatabaseService.escucharEventosDispositivo`. | Mismo dato y stream que la pestaña "Eventos" del panel admin; se factorizó el formateo de mensajes en `DeviceEventFormatter` para no duplicar lógica entre app y panel. |
| 🟢 **Resuelto (2026-08-12)** | Geocerca: zona fija (centro + radio) configurable por el usuario, independiente del modo armado y de la ubicación del teléfono. Alerta si el vehículo sale de la zona en cualquier momento. | Nueva pantalla `GeocercaScreen` (acceso desde el drawer), `EstadoDispositivo.geofence*`, `DatabaseService.actualizarGeocerca`/`obtenerGeocerca`/`registrarAlertaGeocerca`, `VehiculoController._evaluarGeocerca`. | Se decidió explícitamente con el usuario que esto fuera distinto de la heurística de modo armado (que solo compara contra el punto donde se armó) — la geocerca usa un centro fijo definido a mano y queda activa siempre, no solo mientras el sistema está armado. Radio configurable 200 m–20 km vía slider; sin `.validate` de forma en las reglas más allá de tipos/rango de `radiusMeters` (> 0). |
| 🟢 **Resuelto (2026-08-12)** | Color del vehículo integrado en el flujo móvil. | `vincular_vehiculo_screen.dart` (selector de color al vincular), `VehicleData.colorFor`, punto de color visible en la lista de vehículos del drawer. | Se fija una sola vez al vincular (igual que marca/modelo/patente hoy) — no hay pantalla en la app para cambiarlo después, solo el panel admin puede editarlo. Se guarda en `vehicles_meta/{id}.color` y `dispositivos/{id}.color` para que ambas superficies (app y panel) lo vean. |
| 🟢 **Resuelto (2026-08-12)** | Slider de corte de corriente optimizado. | `security_slider.dart` reescrito: gesto controlado en vez de `Slider` de Material. | Se encontró y corrigió un problema real, no solo estético: el `Slider` original movía el valor al punto exacto donde se tocaba el track, así que un tap accidental cerca del borde derecho podía superar el umbral (90%) y disparar el corte de corriente **sin arrastre real**. Ahora el gesto solo responde si empieza sobre el thumb. De paso se agregó una barra de progreso (antes no había ninguna señal visual de cuánto faltaba) y una animación de regreso más suave al soltar antes del umbral. |
| 🟢 **Resuelto (2026-08-12)** | ~~Bug~~ Feature: "comentario random (tiene un foco malo)" — en realidad era una nota sobre poder anotar señas particulares del vehículo (rayones, foco quemado, etc.) para identificarlo en caso de robo, no un bug. | Nueva sección "SEÑAS PARTICULARES" en `DatosPropietarioScreen`. `DatabaseService.obtenerDatosPropietario`/`actualizarDatosPropietario` ahora incluyen `comentario`. | El campo `comentario` ya existía en `dispositivos/{id}` — el panel admin lo tenía (`device_inventory_screen.dart`), pero el cliente no podía editarlo desde su celular. Aclarado directamente con el usuario que el ítem original de `apuntes.txt` no era un bug reproducible. |

## 2. Brechas — Panel Web (Admin)

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🟢 **Resuelto (2026-08-12)** | Mismo fix de comandos directos sin cola/ACK, ya que panel y app comparten `actualizarComandoDispositivo`. | `admin_dashboard_web.dart:_confirmCommand` → `updateDeviceCommand` → método ya corregido. | Un solo cambio en `database_service.dart` resolvió ambos frontends a la vez. |
| 🟢 **Resuelto (2026-08-12)** | Vista de comandos y su estado/ACK. | Pestaña "COMANDOS" en `admin_dashboard_web.dart`, sobre `device_commands/`. | El estado hoy es casi siempre "Pendiente" hasta que se resuelva el punto anterior (actuador directo). |
| 🟢 **Resuelto (2026-08-12)** | Vista de diagnóstico técnico: firmware/hardware version, señal GPS/red, batería de respaldo, último heartbeat. | Nueva pestaña "DIAGNÓSTICO" en `admin_dashboard_web.dart`, junto a CONTROL y DUEÑO. Lee directo del nodo `dispositivos/{id}` que ya escribe `registrarTelemetriaDispositivo`. | Sin trabajo de backend adicional — el dato ya existía, solo faltaba la pantalla. |
| 🟢 **Resuelto (2026-08-12)** | Vista de eventos críticos / auditoría, combinando `eventos/{deviceId}` (comandos remotos) y `device_events/{deviceId}` (heartbeat/tamper/panic/ack, sin contar heartbeat que es ruido rutinario). | Nueva pestaña "EVENTOS" en `admin_dashboard_web.dart`, alimentada por `DatabaseService.escucharEventosDispositivo`. | Sin trabajo de backend adicional — el dato ya existía, solo faltaba exponerlo. |
| 🟢 **Resuelto (2026-08-12)** | Filtro por organización/flota en el dashboard. | `AdminDeviceViewData.organizationId`/`matchesOrganization`, `AdminDashboardController.organizations`/`setOrganizationFilter`, chips nuevos en `admin_dashboard_web.dart`. | La UI del filtro solo se muestra si hay 2+ organizaciones distintas en la flota — con una sola (el caso de hoy) no aporta nada y se mantiene oculta. Empieza a funcionar solo el día que haya una segunda organización real. |
| 🟢 **Resuelto (2026-08-12)** | Doble confirmación para el comando más peligroso: activar corta corriente. | `admin_dashboard_web.dart:_confirmarCorteCorrienteReforzado`. | Se evaluó (según lo que pedía esta brecha) y se decidió reforzar solo **activar** corta corriente — desactivarlo (restaurar el motor) es la acción de recuperación, no necesita fricción extra. El admin debe escribir la patente de la unidad para habilitar el botón, y si el último dato de velocidad conocido es > 0 se muestra una advertencia de que el vehículo podría estar en movimiento. Humo y protocolo/sirena siguen con la confirmación simple de antes. Esto no decide la política de negocio de cuándo se permite cortar corriente en movimiento — eso sigue abierto (ver nota en Pista C). |

## 3. Brechas — Backend / API / Seguridad

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🟢 **Resuelto (2026-08-12)** | Reglas de Realtime Database publicadas: autenticación obligatoria, separación cliente/interno por rol, el cliente no puede tocar el actuador ni falsificar su propio ACK. | `database.rules.json` (raíz), referenciado desde `firebase.json`. Detalle y limitaciones conocidas en `docs/database-rules.md`. | **Acción manual pendiente antes de desplegar**: sembrar el primer usuario con `role: admin` a mano (Console o Admin SDK) — sin eso, nadie puede entrar al panel después del deploy. Verificado de forma manual (no automatizada) contra el emulador de RTDB el 2026-08-12: lectura sin autenticación devuelve "Permission denied", como corresponde. |
| 🟢 **Resuelto (2026-08-12)** | Decisión tomada: Cloud Functions (2ª gen), no servicio propio. Preparado y verificado contra el emulador — falta solo el `firebase deploy` real. | `.firebaserc` (nuevo, proyecto `first-protection`), `functions/index.js:onRequestV2`, dependencias reales instaladas (`npm install`). | Se eligió Cloud Functions porque el código ya estaba escrito pensando en eso (`exports.deviceApi`) y el proyecto ya está 100% en Firebase (Auth + RTDB) — es el camino de menor fricción para un prototipo de bajo volumen. `minInstances: 0` (sin costo fijo, acepta cold start ocasional). |
| 🟢 **Resuelto (2026-08-12)** | 2 bugs reales encontrados y corregidos al verificar contra el emulador de Functions (nunca se había probado así antes de hoy). | `functions/index.js`. | **(1)** `exports.deviceApi` se asignaba **antes** de `module.exports = {...}`, que reemplaza el objeto de exports entero — la Cloud Function nunca se registraba, en ninguna versión anterior de este archivo. **(2)** `parseJsonBody` releía el stream del request con `req.on('data'/'end')`, pero bajo el Functions Framework el body ya viene leído (`req.rawBody`) — reintentar leerlo rompía la conexión (`ECONNRESET`) en cualquier POST real. Ninguno de los 22 tests automatizados detectaba esto porque corren contra `handleApiRequest` directo, sin pasar por el wrapper real de Cloud Functions — quedó anotado como brecha de cobertura. |
| 🟢 **Resuelto (2026-08-12)** | Bug adicional: `saveTelemetry` escribía `undefined` en `device_events/.../metadata` cuando la telemetría no traía `power` o `location.speedKmh` (ambos opcionales en el contrato) — el Admin SDK real rechaza cualquier `undefined` y la escritura fallaba con 500. `memoryStore` nunca lo detectaba porque no valida forma de datos como Firebase real. | `functions/index.js:buildHeartbeatMetadata`, con test dedicado. | Se encontró recién al probar contra la RTDB real (por accidente, ver nota abajo) y se confirmó el fix contra el emulador de RTDB. |
| 🟢 **Resuelto (2026-08-12)** | Tests automatizados de la API de dispositivo (telemetría/comandos/ACK). | `functions/test/device-api.test.js` (Node `--test`, 16 casos), corre contra el servidor real vía `npm test` en `functions/`. Cubre firma HMAC válida/inválida/expirada, rangos de lat/lng/velocidad/voltaje, ciclo comando pendiente→recibido→ACK, comando expirado, y `DEVICE_API_SKIP_SIGNATURE`. | De paso se cerraron 2 brechas que el propio contrato marcaba como pendientes: "ignorar sequence repetidos" (antes no existía) y validar rango de `speedKmh`/`vehicleVoltage` (antes solo se validaba lat/lng). Sigue sin existir un chequeo de `deviceId` desconocido (hoy cualquier `deviceId` nuevo se crea implícitamente en el primer POST) — ver `docs/device-api-contract.md`. |
| 🟠 | API keys de Google Maps sin restringir por dominio/paquete/SHA-1/APIs permitidas. | `README.md` pendientes. | Tarea de configuración (no de código), rápida de resolver. |
| 🟢 **Resuelto (2026-08-12), parcial** | Rate limiting en creación de comandos: máximo 5 comandos por dispositivo cada 10 segundos, devuelve 429 si se supera. | `functions/index.js:commandRateLimited`, cubierto en `functions/test/device-api.test.js`. | **No** cubre rotación de `deviceSecret` (sigue pendiente, ver nota abajo) ni rate limit de telemetría/eventos — el foco fue la superficie más sensible (comandos de actuador). |
| 🟢 **Resuelto (2026-08-12)** | Validación server-side de comandos peligrosos: `type`/`target` deben ser enums conocidos, y `setActuator` exige `target` de tipo actuador con `value` booleano. | `functions/index.js:validateCommandPayload`, cubierto en `functions/test/device-api.test.js`. | Antes cualquier payload llegaba a `device_commands/` sin validar forma — la única barrera era la UI. Esto **no** decide política de negocio (ej. bloquear corta corriente en movimiento sigue abierto, es decisión de negocio/legal, ver Pista A nota y `physical-device-integration.md`). |
| 🟠 | Rotación de `deviceSecret` sin implementar. Hoy además no hay secreto por dispositivo: todos comparten un único `DEVICE_SIM_SECRET` vía variable de entorno. | `functions/index.js:DEFAULT_DEVICE_SECRET`. | Requiere primero un flujo de aprovisionamiento de dispositivo (generar y guardar un secreto por `deviceId`) que hoy no existe — no es solo agregar rotación, es una brecha más grande que la nota original sugería. |
| 🟠 | `DEVICE_API_SKIP_SIGNATURE` existe como variable para saltar la firma HMAC — riesgo si queda activa fuera de desarrollo. | `Guía de desarrollo y entornos` (PDF), sección "Variables y secretos". | Confirmar que nunca esté activa en staging/producción; no se verificó en este repo si hay un chequeo automático que lo bloquee. |
| 🟠 | Falta probar los endpoints con el hardware real (SIM7600) y validar el payload armado desde STM32 + NEO-M8N. | *Contrato API dispositivo* (PDF), sección "Pendientes de cierre". | Depende de que exista hardware — mientras tanto se puede seguir validando contra el simulador. |
| 🟡 | Sin proceso formal para crear usuarios admin y asignar roles. | `README.md` pendientes. | |
| 🟡 | Falta definir la política operacional exacta de cuándo se puede activar corta corriente/humo/sirena (¿solo confirmación humana? ¿reglas automáticas?). | `docs/physical-device-integration.md` y *Contrato API dispositivo* (PDF) coinciden en dejarlo abierto. | Es una decisión de negocio/legal, no solo técnica — conviene resolverla con el cliente. |
| 🟡 | Los 22 tests automatizados de la API prueban `handleApiRequest` directo, nunca el wrapper real de Cloud Functions (`exports.deviceApi`). | `functions/test/device-api.test.js`. | Por eso los 2 bugs de arriba no los detectaban. Sería valioso un test de humo contra `firebase emulators:start --only functions` (lo que se hizo manualmente hoy) automatizado en CI, no solo manual. |

### ⚠️ Incidente Menor (2026-08-12): Escritura Accidental En Producción Durante Pruebas

Al verificar el wrapper de Cloud Functions contra el emulador (`firebase emulators:start --only functions`, **sin** `database`), una llamada de prueba escribió un comando real en `device_commands/GPS-EMUTEST2` de la base de datos de **producción** — el emulador de Functions por sí solo no aísla las llamadas a servicios no emulados; usa las credenciales reales (ADC) y avisa de esto en su propio log. Se detectó, se limpió (`firebase database:remove`) y se repitió la prueba con `--only functions,database` juntos (que sí redirige automáticamente vía `FIREBASE_DATABASE_EMULATOR_HOST`), confirmando que las reglas de `database.rules.json` también funcionan correctamente contra el emulador de RTDB (lectura sin auth devuelve "Permission denied", como debe ser). Lección para la próxima vez: nunca levantar el emulador de `functions` solo si el código puede tocar la base de datos — siempre junto con `database`.

## 4. Brechas — Hardware / Firmware (referencia, no depende de este repo)

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🟢 **Resuelto (2026-08-12)** | Módulo SIM/celular definido para el prototipo: **A7670C/A7670SA** (LTE Cat-1), con el SIM7600 (Cat-4) reservado como upgrade para una versión más profesional/productiva futura. | `docs/hardware-roadmap.md` sección "Decisión De Modem" (12-ago-2026). | Pendiente no bloqueante: confirmar bandas exactas del A7670 contra el operador del piloto. |
| 🟠 | Controlador principal STM32 — dado como definido en los PDF de mayo, no mencionado como decisión pendiente en los docs de julio (consistente, sin conflicto). | *Arquitectura técnica*, *Estado del proyecto* (PDF). | |
| 🟢 | GPS/GNSS: módulo NEO-M8N (familia u-blox NEO-M8N/GY-GPSV3-NEO) — coincide entre repo y PDF, con datasheet completo ya en mano (UART 9600–460800 baud, 3.3–6V, precisión ~2m). | `docs/hardware-roadmap.md` + datasheet *GY-NEO-M8N GPS MODULE* (PDF). | Sin conflicto — este componente está resuelto y documentado a nivel de specs. |
| 🟠 | Circuitos de sirena, humo y corta corriente sin definir (relés/MOSFETs optoaislados marcados como "requerido" pero sin circuito). | `docs/hardware-roadmap.md` Fase 0; *Estado del proyecto* (PDF) sección "Esquema de hardware definido para prototipo". | |
| 🟠 | Fuente DC-DC automotriz (12V → 5V/3.3V) sin validar con protecciones de ruido, fusible y transientes. | *Estado del proyecto* (PDF), "Pendientes de validación hardware". | No mencionado en los docs de julio — información nueva que suma al roadmap. |
| 🟠 | Antenas LTE y GNSS sin definir conector/tipo exacto según placa final. | *Estado del proyecto* / *Arquitectura técnica* (PDF). | |
| 🟠 | Pinout del STM32 sin definir: UART GNSS, UART/USB módem, GPIO actuadores, ADC voltaje/ignición. | *Arquitectura técnica* (PDF), "Pendientes técnicos". | Bloquea el diseño de la placa final aunque los componentes ya estén elegidos. |
| 🟠 | Botón físico y tipo de pulsaciones sin definir a nivel de hardware (el comportamiento lógico ya está especificado en `physical-device-integration.md`). | | |
| 🟡 | Lectura de voltaje/ignición (diagnóstico eléctrico) sin circuito ADC/divisor definido. | *Estado del proyecto* (PDF). | |
| 🟡 | Pantalla de diagnóstico OLED ya definida (✅). | `docs/hardware-roadmap.md` Fase 0. | Único ítem de esta fase ya resuelto sin ambigüedad entre fuentes. |

---

## 5. Plan De Trabajo Por Frentes

Se organiza en **4 pistas paralelas** (para "atacar todos los frentes" a la vez) más un hito de sincronización que las cruza. Dentro de cada pista, el orden importa (de arriba hacia abajo); entre pistas, pueden avanzar simultáneamente con distintas personas/tiempos.

### Hito de sincronización (cruza Móvil + Web + Backend) — ✅ Resuelto 2026-08-12

Era el cambio más importante porque hasta el 11-ago la app y el panel alteraban el actuador directamente, lo cual es incompatible con tener un dispositivo físico real:

1. ✅ Backend: `device_commands` ahora es el único camino — **todo comando pasa por cola pendiente → ACK**, sin tocar el campo del actuador hasta que el dispositivo confirme (`functions/index.js:ackCommand`).
2. ✅ Panel web: vista de comando pendiente/estado (pestaña "COMANDOS", Sprint 1) y ya no escribe el actuador directo.
3. ✅ App móvil: mismo cambio + estado visual (pendiente/ejecutado/fallido/expirado) en el slider y botones de humo/sirena (Sprint 1).
4. ✅ El simulador (`scripts/stm_simulator.py`) sigue respondiendo el ACK; el backend ahora usa ese ACK para actualizar el actuador real, en vez de que la app lo adivine.

Efecto práctico: al presionar un botón, el estado va a mostrar "Pendiente" hasta que el simulador (corriendo con `npm run serve:device-api` + `python scripts/stm_simulator.py`) haga el siguiente poll y confirme — recién ahí el botón/slider refleja el cambio real. Esto es esperado y correcto; antes era instantáneo pero falso.

### Pista A — App Móvil

1. ✅ ~~Migrar comandos de escritura directa a modelo pendiente/ACK~~ — resuelto 2026-08-12 (ver hito de sincronización).
2. ✅ ~~Mostrar estado de comando en UI~~ — resuelto 2026-08-12.
3. ✅ ~~Registrar `liveLocation` del usuario + lógica básica de cercanía usuario-vehículo~~ — resuelto 2026-08-12.
4. ✅ ~~Modo estacionado/armado~~ — resuelto 2026-08-12, parcial (solo `normal`/`armed`, ver brecha arriba).
5. ✅ ~~Formulario de datos del propietario (nombre, RUT, email, teléfono, domicilio, contacto de emergencia)~~ — resuelto 2026-08-12.
6. ✅ ~~Historial de eventos para el cliente~~ — resuelto 2026-08-12.
7. 🟠 Notificaciones (definir proveedor primero: push / SMS / correo / llamada). **Pausado a pedido del cliente — es config/decisión, se retoma junto con la restricción de API keys de Maps (Pista C ítem 4).**
8. ✅ ~~Geocerca~~ — resuelto 2026-08-12.
9. ✅ ~~Color de vehículo~~, ✅ ~~optimización de slider~~ y ✅ ~~"señas particulares" del vehículo~~ (era un feature, no un bug) — resueltos 2026-08-12.

### Pista B — Panel Web

1. ✅ ~~Migrar comandos al modelo pendiente/ACK~~ — resuelto 2026-08-12 (ver hito de sincronización).
2. ✅ ~~Vista de comandos pendientes y su estado~~ — resuelto 2026-08-12.
3. ✅ ~~Vista de diagnóstico técnico (firmware/hardware version, señal, batería, `lastSeenAt`)~~ — resuelto 2026-08-12.
4. ✅ ~~Vista de eventos críticos / auditoría~~ — resuelto 2026-08-12.
5. ✅ ~~Filtro por organización/flota~~ — resuelto 2026-08-12 (oculto hasta que exista una 2ª organización real).
6. ✅ ~~Reforzar confirmación de comandos peligrosos~~ — resuelto 2026-08-12 (doble confirmación al activar corta corriente).

### Pista C — Backend / Seguridad

1. ✅ ~~Redactar y publicar reglas de Realtime Database por rol~~ — resuelto 2026-08-12 (sin filtro por organización todavía, ver `docs/database-rules.md`). Pendiente operativo: sembrar el primer admin antes de desplegar.
2. 🟠 Decidido 2026-08-12: Cloud Functions. Código listo y verificado contra el emulador (con 2 bugs reales corregidos, ver brecha arriba). **`firebase deploy --only functions` intentado y bloqueado**: el proyecto `first-protection` está en plan Spark (gratuito) y Cloud Functions exige plan Blaze (pago por uso, con cuota gratuita generosa) — hay que vincular una cuenta de facturación en [console.cloud.google.com/billing/linkedaccount?project=first-protection](https://console.cloud.google.com/billing/linkedaccount?project=first-protection) antes de poder desplegar. No es una razón para reconsiderar la decisión — cualquier alternativa real en la nube pide lo mismo. Una vez vinculada la cuenta, el deploy es un solo comando.
3. ✅ ~~Tests automatizados de la API de dispositivo (payloads válidos/inválidos, firma HMAC, expiración)~~ — resuelto 2026-08-12.
4. 🟠 Restringir API keys de Google Maps. **Pausado a pedido del cliente — retomar más adelante.**
5. ✅ ~~Rate limiting por dispositivo (creación de comandos)~~ — resuelto 2026-08-12. 🟠 Rotación de secretos por dispositivo sigue pendiente (requiere aprovisionamiento por `deviceId` primero, ver brecha arriba).
6. ✅ ~~Validación server-side de comandos peligrosos~~ — resuelto 2026-08-12.
7. 🟡 Proceso formal de alta de usuarios admin/roles.

### Pista D — Hardware / Firmware (seguimiento, ejecución fuera de este repo)

0. ✅ ~~Aclarar la contradicción SIM7600 vs. "sin módem definido"~~ — resuelto 2026-08-12 (ver Actualización en Hallazgo Crítico arriba).
1. 🟠 Confirmar bandas exactas del módem A7670 (prototipo) contra el operador del piloto. Ya no bloquea el inicio de Fase 3, pero sí que el prototipo conecte en la práctica.
2. 🟠 Definir pinout del STM32 (UART GNSS, UART/USB módem, GPIO actuadores, ADC voltaje/ignición).
3. 🟠 Definir circuitos de sirena, humo y corta corriente (relés/MOSFETs optoaislados).
4. 🟠 Definir botón físico y pulsaciones a nivel de hardware.
5. 🟠 Validar fuente DC-DC automotriz (ruido, fusible, transientes) y tipo de antenas LTE/GNSS.
6. Luego: Fase 3 (Firmware MVP) → Fase 4 (banco de pruebas) → Fase 5 (vehículo controlado) → Fase 6 (MVP operativo), según `docs/hardware-roadmap.md`.

---

## 6. Mensaje Sugerido Para El Cliente

- Software (app + panel + backend) tiene un plan concreto y puede avanzar en paralelo en 3 pistas ya en marcha.
- El bloqueo de hardware que frenaba la Fase 3 (elegir el módem celular) ya se resolvió: se eligió un módem económico (A7670, LTE Cat-1) para esta etapa de prototipo, dejando un módem más rápido (SIM7600) anotado como upgrade para una versión más profesional más adelante. Esto es coherente con el alcance actual del proyecto: un prototipo/MVP para validar el sistema completo, no un producto para fabricar en volumen.
- Antes de cualquier demo con datos reales o usuarios externos, queda 1 tarea de seguridad no negociable: restricción de API keys de Google Maps. (Las otras dos — reglas de Realtime Database y dejar de escribir actuadores directo desde la UI — ya se resolvieron el 2026-08-12. Ojo: las reglas requieren sembrar un usuario admin manualmente antes de desplegarlas, ver `docs/database-rules.md`.)
- Existen documentos previos (mayo 2026) que hablan de un flujo de comandos "cerrado" y reglas Firebase "versionadas" que no coinciden con el código actual — vale la pena preguntar si ese trabajo se hizo en otro lugar y se perdió, antes de asumir que hay que rehacerlo desde cero.

## 7. Plan De Pruebas (QA) — Base Para Demo

Tomado del *Manual interno de uso y pruebas* (PDF, may-2026). Sigue siendo válido como checklist aunque el flujo de comandos todavía no esté cerrado — de hecho, sirve para detectar justamente ese tipo de brechas.

**Roles de prueba:**

| Rol | Debe poder | No debe poder |
|---|---|---|
| Cliente | Iniciar sesión, ver sus vehículos, revisar mapa/telemetría, solicitar comandos permitidos. | Acceder al panel admin, ver vehículos de otros clientes, modificar inventario global. |
| Admin | Acceder al command center, gestionar inventario, buscar dispositivos, solicitar comandos, revisar estados. | Omitir auditoría de comandos o ejecutar acciones sin registro. |
| Operador/Técnico | Monitorear flota, revisar diagnóstico, apoyar pruebas y operaciones autorizadas. | Cambiar permisos globales o saltar validaciones de seguridad. |

**Datos ficticios recomendados:** organización `first-protection`, cliente demo, admin demo, dispositivo `GPS-SIM001`, patente `TEST-01`. **Regla de privacidad:** nunca usar RUT, teléfono, dirección o datos personales reales en pruebas o evidencias compartidas — esto aplica también a cualquier captura que se muestre en la reunión con el cliente.

**Casos mínimos de prueba:**

| ID | Caso | Resultado esperado |
|---|---|---|
| TC-01 | Login cliente | Cliente accede solo a su experiencia móvil. |
| TC-02 | Login admin | Admin accede al command center. |
| TC-03 | Bloqueo cliente en admin | Cliente no autorizado vuelve al login admin con error. |
| TC-04 | Telemetría simulada | App/panel muestran datos del dispositivo simulado. |
| TC-05 | Comando humo | Se crea comando y queda auditado. |
| TC-06 | Corta corriente | Requiere acción explícita y muestra estado del comando. |
| TC-07 | Inventario | Alta/edición se refleja en tabla y datos del panel. |
| TC-08 | Evento crítico | Escenario `carjacking` registra evento y alerta. |

**Criterios para aprobar una demo:** login cliente y admin funcionan; cliente no accede al panel admin; admin ve dispositivos e inventario; cliente ve su vehículo; se puede crear al menos un comando y queda auditado; **el estado del comando se muestra en la UI** (hoy no se cumple — ver brechas de sección 1 y 2); no se usan datos personales reales.

Pendiente: este plan de pruebas no está formalizado en el repo (`test/` solo tiene `models_test.dart`). Vale la pena convertirlo en un checklist repetible (manual o automatizado) antes de la próxima demo.

## 8. Para Retomar La Próxima Sesión

- **Acción inmediata pendiente**: vincular cuenta de facturación (plan Blaze) en el proyecto Firebase `first-protection` para poder correr `firebase deploy --only functions`. Sin esto, el deploy de Cloud Functions queda bloqueado — ver Pista C ítem 2. El código ya está listo y verificado, no falta nada de código para esto.
- Decisiones del usuario aún abiertas: política de corte de corriente automático (Pista C), proveedor de notificaciones (Pista A, pausado), restringir API keys de Maps (Pista C, pausado).
- Ver sección "⚠️ Incidente Menor" arriba antes de volver a levantar el emulador de Functions — siempre junto con `database`, nunca solo.

## 9. Pendiente De Este Documento

- ~~Resolver la contradicción sobre el SIM7600 con el equipo de hardware~~ — resuelto 2026-08-12.
- Confirmar bandas exactas del módem A7670 elegido contra el operador del piloto.
- Confirmar si existen en algún lado los 4 documentos referenciados por los PDF (`development-guide`, `internal-user-manual`, `project-decisions-and-risks`, `delivery-log`) y si hay código asociado al "flujo de comandos cerrado" que no llegó a este repo.
- Falta incorporar más documentación adicional si el cliente/equipo aporta más.
- Falta estimar tiempos/esfuerzo por tarea una vez se prioricen con el cliente.
- Falta definir dueño responsable por tarea/pista.
