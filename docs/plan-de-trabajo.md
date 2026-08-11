# Plan De Trabajo First Protection

Documento vivo para ordenar el trabajo pendiente en todos los frentes (app móvil, panel web, backend/seguridad y hardware). Base para la conversación con el cliente. Se actualiza a medida que se sume documentación adicional o cambien prioridades.

Última actualización: 2026-08-11 (incorpora 6 documentos adicionales aportados por el usuario, todos fechados 27-may-2026).

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
- Preguntar puntualmente: *¿el SIM7600 sigue siendo la decisión vigente, o se descartó entre mayo y julio?* Esa respuesta cambia si el bloqueo de hardware sigue "sin definir" o solo falta "confirmar modelo y probar".
- Preguntar si existen los 4 documentos referenciados (`development-guide`, `internal-user-manual`, `project-decisions-and-risks`, `delivery-log`) en algún otro lugar — tienen contenido valioso (guía de entornos, plan de pruebas) que conviene recuperar en vez de rehacer.

---

## 1. Brechas — App Móvil (Cliente)

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🔴 | Los comandos (humo, sirena, corta corriente) modifican el actuador **de inmediato** desde la app; no esperan confirmación (ACK) del dispositivo físico. | `database_service.dart:actualizarComandoDispositivo` escribe en `dispositivos/{id}/{campo}` en el mismo paso que crea el comando. | Es el mismo hueco que marca el checklist como "siguiente hito recomendado". Hoy funciona porque no hay hardware real; se vuelve riesgo en cuanto exista un STM. |
| 🔴 | No se muestra el estado del comando (pendiente / recibido / ejecutado / fallido / expirado). | No hay UI que lea `device_commands/{deviceId}`; el modelo `DeviceCommand` existe pero no se consume en `client_home_screen.dart`. | Requiere resolver el punto anterior primero. |
| 🔴 | No se registra `usuarios/{uid}/liveLocation` ni existe lógica de cercanía usuario-vehículo. | No hay ningún archivo que escriba ubicación del usuario ni compare distancias. | Bloquea toda la lógica de "posible portonazo" descrita en `physical-device-integration.md`. |
| 🟠 | Sin modo estacionado/armado (`systemMode`). | No existe ningún control ni campo consumido para esto en la app. | |
| 🟠 | Sin notificaciones (SMS, correo, llamada a central). | Pendiente explícito en `apuntes.txt`. | Depende de definir proveedor (Twilio/Firebase Cloud Messaging/central telefónica). |
| 🟠 | Sin registro de datos del propietario desde la app móvil (nombre, RUT, email, teléfono, domicilio, contacto de emergencia). | Pendiente en `apuntes.txt`; hoy solo se edita desde el panel web. | Web ya lo tiene, falta paridad en móvil. |
| 🟠 | Sin historial de eventos visible para el cliente. | No hay pantalla que lea `eventos/{deviceId}` ni `device_events/{deviceId}`. | |
| 🟠 | Sin geocerca (validación de distancia/velocidad). | Pendiente explícito en `apuntes.txt`. | |
| 🟡 | Falta integrar color del vehículo en el flujo móvil (el panel web ya lo tiene). | `apuntes.txt`. | |
| 🟡 | Optimizar el slider de corte de corriente. | `apuntes.txt`; `security_slider.dart` funcional pero pendiente de ajuste UX. | |
| 🐞 | Bug reportado: "comentario random (tiene un foco malo)". | `apuntes.txt`, sin ticket técnico asociado. | Falta reproducir — pedir detalle/captura al reportar el bug. |

## 2. Brechas — Panel Web (Admin)

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🔴 | Mismo problema de comandos directos sin cola/ACK que en móvil. | `admin_dashboard_web.dart:_confirmCommand` → `updateDeviceCommand` → mismo método directo. | Se resuelve junto con el punto de app móvil: es un cambio de backend + ambos frontends a la vez. |
| 🔴 | No hay vista de comandos pendientes ni su estado/ACK. | No existe pantalla que lea `device_commands/`. | |
| 🔴 | No hay vista de diagnóstico técnico: firmware/hardware version, señal GPS/red, batería de respaldo, último heartbeat (`lastSeenAt`). | Modelos (`DeviceTelemetry`, `DeviceEvent`) ya existen en `lib/core/models`, pero no hay pantalla que los consuma. | El dato ya se guarda (`registrarTelemetriaDispositivo`); falta solo UI. |
| 🟠 | No hay vista de eventos críticos / auditoría, aunque el modelo de datos ya audita todo en `eventos/{deviceId}` y `device_events/{deviceId}`. | `database_service.dart` escribe eventos correctamente; no hay pantalla que los liste. | Ganancia rápida: el dato ya existe, solo falta exponerlo. |
| 🟠 | Sin filtro por organización/flota en el dashboard (el modelo de datos ya soporta `organizationId`). | `escucharDispositivosAdmin` acepta `organizationId` pero la UI no lo usa. | Relevante si el cliente quiere vender a empresas/flotas más adelante. |
| 🟡 | Sin bloqueo operacional adicional para comandos peligrosos más allá del diálogo de confirmación actual (ya existe confirmación simple). | `admin_dashboard_web.dart:_confirmCommand`. | Evaluar si alcanza o se requiere doble aprobación para corta corriente. |

## 3. Brechas — Backend / API / Seguridad

| Prioridad | Brecha | Evidencia | Nota |
|---|---|---|---|
| 🔴 | Reglas de Realtime Database sin publicar en modo estricto (hoy expuesto a modo abierto/dev). | `README.md` "Pendientes antes de producción"; no hay archivo `database.rules.json` con reglas por rol/organización revisado en el repo. | Riesgo de seguridad más urgente antes de cualquier demo pública. |
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
| 🔴 **BLOQUEANTE (a confirmar)** | Módulo SIM/celular: los docs de julio dicen "sin definir todavía"; los PDF de mayo ya dan por elegido el **SIM7600** (con modelo/bandas exactas por confirmar). Contradicción sin resolver — ver hallazgo crítico arriba. | `docs/hardware-roadmap.md`/`integration-checklist.md` (jul-2026) vs. *Estado del proyecto* / *Arquitectura técnica* (PDF, may-2026). | **Antes de la reunión, preguntar directamente al equipo de hardware cuál de las dos versiones está vigente.** Si el SIM7600 sigue en pie, el bloqueo es más liviano ("confirmar modelo y probar") que si volvió a "sin definir". |
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

### Hito de sincronización (cruza Móvil + Web + Backend)

Este es el cambio más importante del próximo ciclo porque hoy la app y el panel alteran el actuador directamente, lo cual es incompatible con tener un dispositivo físico real:

1. Backend: terminar el modelo `device_commands` (ya existe parcialmente) para que **todo comando pase por cola pendiente → ACK**, sin tocar el campo del actuador hasta que el dispositivo confirme.
2. Panel web: agregar vista de comando pendiente/estado y dejar de escribir el actuador directo.
3. App móvil: mismo cambio + mostrar estado visual (pendiente/ejecutado/fallido/expirado) en el slider y botones de humo/sirena.
4. Backend: mientras no exista hardware real, mantener el simulador (`scripts/stm_simulator.py`) como el que responde el ACK, para no romper las demos.

### Pista A — App Móvil

1. 🔴 Migrar comandos de escritura directa a modelo pendiente/ACK (ver hito de sincronización).
2. 🔴 Mostrar estado de comando en UI.
3. 🔴 Registrar `liveLocation` del usuario + lógica básica de cercanía usuario-vehículo.
4. 🟠 Modo estacionado/armado.
5. 🟠 Formulario de datos del propietario (nombre, RUT, email, teléfono, domicilio, contacto de emergencia).
6. 🟠 Historial de eventos para el cliente.
7. 🟠 Notificaciones (definir proveedor primero: push / SMS / correo / llamada).
8. 🟠 Geocerca.
9. 🟡 Color de vehículo, optimización de slider, fix bug "foco malo".

### Pista B — Panel Web

1. 🔴 Migrar comandos al modelo pendiente/ACK (ver hito de sincronización).
2. 🔴 Vista de comandos pendientes y su estado.
3. 🔴 Vista de diagnóstico técnico (firmware/hardware version, señal, batería, `lastSeenAt`).
4. 🟠 Vista de eventos críticos / auditoría (el dato ya existe, falta la pantalla).
5. 🟠 Filtro por organización/flota.
6. 🟡 Reforzar confirmación de comandos peligrosos si el cliente lo pide.

### Pista C — Backend / Seguridad

1. 🔴 Redactar y publicar reglas de Realtime Database por rol/organización.
2. 🔴 Decidir y ejecutar: reconstruir `functions/` como Cloud Functions reales o mantener servicio propio desplegado (hoy es solo local).
3. 🔴 Tests automatizados de la API de dispositivo (payloads válidos/inválidos, firma HMAC, expiración).
4. 🟠 Restringir API keys de Google Maps.
5. 🟠 Rate limiting + rotación de secretos por dispositivo.
6. 🟠 Validación server-side de comandos peligrosos.
7. 🟡 Proceso formal de alta de usuarios admin/roles.

### Pista D — Hardware / Firmware (seguimiento, ejecución fuera de este repo)

0. 🔴 **Aclarar primero la contradicción SIM7600 vs. "sin módem definido"** (ver hallazgo crítico) — condiciona todo lo demás de esta pista.
1. 🔴 **Decisión/confirmación con el cliente:** módulo SIM/celular (LTE/NB-IoT) — modelo exacto y bandas si el SIM7600 sigue vigente. Sin esto no arranca Fase 3.
2. 🟠 Definir pinout del STM32 (UART GNSS, UART/USB módem, GPIO actuadores, ADC voltaje/ignición).
3. 🟠 Definir circuitos de sirena, humo y corta corriente (relés/MOSFETs optoaislados).
4. 🟠 Definir botón físico y pulsaciones a nivel de hardware.
5. 🟠 Validar fuente DC-DC automotriz (ruido, fusible, transientes) y tipo de antenas LTE/GNSS.
6. Luego: Fase 3 (Firmware MVP) → Fase 4 (banco de pruebas) → Fase 5 (vehículo controlado) → Fase 6 (MVP operativo), según `docs/hardware-roadmap.md`.

---

## 6. Mensaje Sugerido Para El Cliente

- Software (app + panel + backend) tiene un plan concreto y puede avanzar en paralelo en 3 pistas ya en marcha.
- El verdadero cuello de botella del proyecto completo es una decisión de hardware (módulo SIM/celular) — pero hay documentación contradictoria sobre si ya se eligió (SIM7600) o sigue sin definir. Se necesita esa respuesta esta semana, porque bloquea toda la Fase 3 en adelante.
- Antes de cualquier demo con datos reales o usuarios externos, hay 3 tareas de seguridad no negociables: reglas de Realtime Database, restricción de API keys, y dejar de escribir actuadores directo desde la UI.
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

- Resolver la contradicción sobre el SIM7600 con el equipo de hardware (bloquea decidir la urgencia real de la Pista D).
- Confirmar si existen en algún lado los 4 documentos referenciados por los PDF (`development-guide`, `internal-user-manual`, `project-decisions-and-risks`, `delivery-log`) y si hay código asociado al "flujo de comandos cerrado" que no llegó a este repo.
- Falta incorporar más documentación adicional si el cliente/equipo aporta más.
- Falta estimar tiempos/esfuerzo por tarea una vez se prioricen con el cliente.
- Falta definir dueño responsable por tarea/pista.
