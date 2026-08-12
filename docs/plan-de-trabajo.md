# Plan De Trabajo First Protection

Documento vivo para ordenar el trabajo pendiente en todos los frentes (app móvil, panel web, backend/seguridad y hardware). Base para la conversación con el cliente. Se actualiza a medida que se sume documentación adicional o cambien prioridades.

Última actualización: 2026-08-12 (se cierra la decisión de módem para el prototipo — ver sección de Hallazgo Crítico y Pista D).

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
| 🔴 | No se registra `usuarios/{uid}/liveLocation` ni existe lógica de cercanía usuario-vehículo. | No hay ningún archivo que escriba ubicación del usuario ni compare distancias. | Bloquea toda la lógica de "posible portonazo" descrita en `physical-device-integration.md`. |
| 🟠 | Sin modo estacionado/armado (`systemMode`). | No existe ningún control ni campo consumido para esto en la app. | |
| 🟠 | Sin notificaciones (SMS, correo, llamada a central). | Pendiente explícito en `apuntes.txt`. | Depende de definir proveedor (Twilio/Firebase Cloud Messaging/central telefónica). |
| 🟠 | Sin registro de datos del propietario desde la app móvil (nombre, RUT, email, teléfono, domicilio, contacto de emergencia). | Pendiente en `apuntes.txt`; hoy solo se edita desde el panel web. | Web ya lo tiene, falta paridad en móvil. |
| 🟢 **Resuelto (2026-08-12)** | Historial de eventos visible para el cliente. | Nueva pantalla `HistorialEventosScreen`, accesible desde el ícono de historial en el AppBar del dashboard móvil. Reutiliza `DatabaseService.escucharEventosDispositivo`. | Mismo dato y stream que la pestaña "Eventos" del panel admin; se factorizó el formateo de mensajes en `DeviceEventFormatter` para no duplicar lógica entre app y panel. |
| 🟠 | Sin geocerca (validación de distancia/velocidad). | Pendiente explícito en `apuntes.txt`. | |
| 🟡 | Falta integrar color del vehículo en el flujo móvil (el panel web ya lo tiene). | `apuntes.txt`. | |
| 🟡 | Optimizar el slider de corte de corriente. | `apuntes.txt`; `security_slider.dart` funcional pero pendiente de ajuste UX. | |
| 🐞 | Bug reportado: "comentario random (tiene un foco malo)". | `apuntes.txt`, sin ticket técnico asociado. | Falta reproducir — pedir detalle/captura al reportar el bug. |

## 2. Brechas — Panel Web (Admin)

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🟢 **Resuelto (2026-08-12)** | Mismo fix de comandos directos sin cola/ACK, ya que panel y app comparten `actualizarComandoDispositivo`. | `admin_dashboard_web.dart:_confirmCommand` → `updateDeviceCommand` → método ya corregido. | Un solo cambio en `database_service.dart` resolvió ambos frontends a la vez. |
| 🟢 **Resuelto (2026-08-12)** | Vista de comandos y su estado/ACK. | Pestaña "COMANDOS" en `admin_dashboard_web.dart`, sobre `device_commands/`. | El estado hoy es casi siempre "Pendiente" hasta que se resuelva el punto anterior (actuador directo). |
| 🟢 **Resuelto (2026-08-12)** | Vista de diagnóstico técnico: firmware/hardware version, señal GPS/red, batería de respaldo, último heartbeat. | Nueva pestaña "DIAGNÓSTICO" en `admin_dashboard_web.dart`, junto a CONTROL y DUEÑO. Lee directo del nodo `dispositivos/{id}` que ya escribe `registrarTelemetriaDispositivo`. | Sin trabajo de backend adicional — el dato ya existía, solo faltaba la pantalla. |
| 🟢 **Resuelto (2026-08-12)** | Vista de eventos críticos / auditoría, combinando `eventos/{deviceId}` (comandos remotos) y `device_events/{deviceId}` (heartbeat/tamper/panic/ack, sin contar heartbeat que es ruido rutinario). | Nueva pestaña "EVENTOS" en `admin_dashboard_web.dart`, alimentada por `DatabaseService.escucharEventosDispositivo`. | Sin trabajo de backend adicional — el dato ya existía, solo faltaba exponerlo. |
| 🟠 | Sin filtro por organización/flota en el dashboard (el modelo de datos ya soporta `organizationId`). | `escucharDispositivosAdmin` acepta `organizationId` pero la UI no lo usa. | Relevante si el cliente quiere vender a empresas/flotas más adelante. |
| 🟡 | Sin bloqueo operacional adicional para comandos peligrosos más allá del diálogo de confirmación actual (ya existe confirmación simple). | `admin_dashboard_web.dart:_confirmCommand`. | Evaluar si alcanza o se requiere doble aprobación para corta corriente. |

## 3. Brechas — Backend / API / Seguridad

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🟢 **Resuelto (2026-08-12)** | Reglas de Realtime Database publicadas: autenticación obligatoria, separación cliente/interno por rol, el cliente no puede tocar el actuador ni falsificar su propio ACK. | `database.rules.json` (raíz), referenciado desde `firebase.json`. Detalle y limitaciones conocidas en `docs/database-rules.md`. | **Acción manual pendiente antes de desplegar**: sembrar el primer usuario con `role: admin` a mano (Console o Admin SDK) — sin eso, nadie puede entrar al panel después del deploy. Sin probar aún contra el emulador. |
| 🔴 | `functions/` solo tiene `index.js` y `package.json` mínimos, sin desplegar como Cloud Functions reales; sirve hoy como API local para el simulador. | `functions/index.js`, `functions/package.json`; checklist marca "Backend desplegado en Firebase Functions" como pendiente. | Decisión pendiente: reconstruir como Cloud Functions o mantener servicio propio. |
| 🔴 | Sin tests automatizados de la API de dispositivo (telemetría/comandos/ACK). | Solo existe `test/models_test.dart` (modelos Dart), nada de la API HTTP. | |
| 🟠 | API keys de Google Maps sin restringir por dominio/paquete/SHA-1/APIs permitidas. | `README.md` pendientes. | Tarea de configuración (no de código), rápida de resolver. |
| 🟠 | Sin rate limiting por dispositivo ni rotación de secretos (`deviceSecret`). | `docs/integration-checklist.md`; el *Contrato API dispositivo* (PDF) también lo marca en "Pendientes de cierre". | |
| 🟠 | Sin validación avanzada de comandos peligrosos en el backend (hoy la validación vive solo en la UI). | `docs/integration-checklist.md`. | |
| 🟠 | `DEVICE_API_SKIP_SIGNATURE` existe como variable para saltar la firma HMAC — riesgo si queda activa fuera de desarrollo. | `Guía de desarrollo y entornos` (PDF), sección "Variables y secretos". | Confirmar que nunca esté activa en staging/producción; no se verificó en este repo si hay un chequeo automático que lo bloquee. |
| 🟠 | Falta probar los endpoints con el hardware real (SIM7600) y validar el payload armado desde STM32 + NEO-M8N. | *Contrato API dispositivo* (PDF), sección "Pendientes de cierre". | Depende de que exista hardware — mientras tanto se puede seguir validando contra el simulador. |
| 🟡 | Sin proceso formal para crear usuarios admin y asignar roles. | `README.md` pendientes. | |
| 🟡 | Falta definir la política operacional exacta de cuándo se puede activar corta corriente/humo/sirena (¿solo confirmación humana? ¿reglas automáticas?). | `docs/physical-device-integration.md` y *Contrato API dispositivo* (PDF) coinciden en dejarlo abierto. | Es una decisión de negocio/legal, no solo técnica — conviene resolverla con el cliente. |

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
3. 🔴 Registrar `liveLocation` del usuario + lógica básica de cercanía usuario-vehículo.
4. 🟠 Modo estacionado/armado.
5. 🟠 Formulario de datos del propietario (nombre, RUT, email, teléfono, domicilio, contacto de emergencia).
6. ✅ ~~Historial de eventos para el cliente~~ — resuelto 2026-08-12.
7. 🟠 Notificaciones (definir proveedor primero: push / SMS / correo / llamada).
8. 🟠 Geocerca.
9. 🟡 Color de vehículo, optimización de slider, fix bug "foco malo".

### Pista B — Panel Web

1. ✅ ~~Migrar comandos al modelo pendiente/ACK~~ — resuelto 2026-08-12 (ver hito de sincronización).
2. ✅ ~~Vista de comandos pendientes y su estado~~ — resuelto 2026-08-12.
3. ✅ ~~Vista de diagnóstico técnico (firmware/hardware version, señal, batería, `lastSeenAt`)~~ — resuelto 2026-08-12.
4. ✅ ~~Vista de eventos críticos / auditoría~~ — resuelto 2026-08-12.
5. 🟠 Filtro por organización/flota.
6. 🟡 Reforzar confirmación de comandos peligrosos si el cliente lo pide.

### Pista C — Backend / Seguridad

1. ✅ ~~Redactar y publicar reglas de Realtime Database por rol~~ — resuelto 2026-08-12 (sin filtro por organización todavía, ver `docs/database-rules.md`). Pendiente operativo: sembrar el primer admin antes de desplegar.
2. 🔴 Decidir y ejecutar: reconstruir `functions/` como Cloud Functions reales o mantener servicio propio desplegado (hoy es solo local).
3. 🔴 Tests automatizados de la API de dispositivo (payloads válidos/inválidos, firma HMAC, expiración).
4. 🟠 Restringir API keys de Google Maps.
5. 🟠 Rate limiting + rotación de secretos por dispositivo.
6. 🟠 Validación server-side de comandos peligrosos.
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

## 8. Pendiente De Este Documento

- ~~Resolver la contradicción sobre el SIM7600 con el equipo de hardware~~ — resuelto 2026-08-12.
- Confirmar bandas exactas del módem A7670 elegido contra el operador del piloto.
- Confirmar si existen en algún lado los 4 documentos referenciados por los PDF (`development-guide`, `internal-user-manual`, `project-decisions-and-risks`, `delivery-log`) y si hay código asociado al "flujo de comandos cerrado" que no llegó a este repo.
- Falta incorporar más documentación adicional si el cliente/equipo aporta más.
- Falta estimar tiempos/esfuerzo por tarea una vez se prioricen con el cliente.
- Falta definir dueño responsable por tarea/pista.
