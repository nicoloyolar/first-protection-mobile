# Checklist De Integracion First Protection

Este checklist mantiene el estado del MVP, backend y futuro dispositivo STM. Actualizarlo cada vez que se complete una pieza relevante.

## Estado General

- [x] App Flutter cliente/admin existente.
- [x] Login admin con Firebase Auth y roles.
- [x] Modelo base para usuarios internos, clientes, familias y empresas.
- [x] Documentacion tecnica de integracion STM.
- [x] Contrato API inicial para dispositivo fisico.
- [x] Simulador STM en Python.
- [x] API local/Cloud Function inicial compatible con el simulador.
- [ ] Backend desplegado en Firebase Functions.
- [x] Reglas Realtime Database definitivas (`database.rules.json`, 2026-08-12) — falta sembrar el primer admin antes de desplegar, ver `docs/database-rules.md`.
- [ ] Vista admin de diagnostico tecnico.
- [ ] Notificaciones push.
- [ ] Integracion con hardware STM real.

## Backend/API De Dispositivo

- [x] `POST /api/v1/devices/{deviceId}/telemetry`
- [x] `POST /api/v1/devices/{deviceId}/events`
- [x] `GET /api/v1/devices/{deviceId}/commands/next`
- [x] `POST /api/v1/devices/{deviceId}/commands/{commandId}/ack`
- [x] Endpoint dev para crear comando: `POST /api/v1/devices/{deviceId}/commands`
- [x] Firma HMAC inicial para requests del dispositivo.
- [x] Modo local con memoria para desarrollo.
- [x] Escritura Firebase cuando corre como Cloud Function.
- [x] Tests automatizados de API (2026-08-12, `functions/test/device-api.test.js`).
- [x] Validacion avanzada de comandos peligrosos (2026-08-12, forma/enum server-side; la politica de negocio de cuando permitir corta corriente sigue abierta).
- [x] Rate limiting por dispositivo (2026-08-12, solo creacion de comandos; telemetria/eventos sin limitar todavia).
- [ ] Rotacion de secretos por dispositivo (bloqueado: no existe aun un secreto por `deviceId`, solo uno global via env var).

## Simulador STM

- [x] Simular telemetria GPS.
- [x] Simular vehiculo estacionado.
- [x] Simular vehiculo en movimiento.
- [x] Simular posible portonazo.
- [x] Simular conectividad intermitente.
- [x] Simular boton fisico bajo el volante.
- [x] Consultar comandos pendientes.
- [x] Enviar ACK de comandos.
- [ ] Simular falla de actuador.
- [ ] Simular perdida de GPS.
- [ ] Simular bateria baja.
- [ ] Simular manipulacion/tamper.

## App Movil

- [x] Ubicacion del telefono no sobrescribe ubicacion del vehiculo.
- [x] Modelos Dart para comandos, eventos y telemetria.
- [x] Mostrar estado de comando: pendiente, recibido, ejecutado, fallido, expirado (2026-08-12, en app y panel).
- [ ] Registrar ubicacion del usuario en `usuarios/{uid}/liveLocation`.
- [ ] Modo estacionado/armado.
- [ ] Logica de cercania usuario-vehiculo.
- [ ] Alerta de alejamiento o posible portonazo.
- [x] Historial de eventos para el cliente (pantalla "Historial", 2026-08-12).

## Panel Admin

- [x] Acceso protegido por rol.
- [x] Dashboard de dispositivos.
- [x] Confirmacion para comandos criticos.
- [x] Vista de instalacion/diagnostico tecnico (pestaña "Diagnóstico" en el panel, 2026-08-12).
- [x] Mostrar ultimo heartbeat.
- [x] Mostrar firmware/hardware version.
- [x] Mostrar senal GPS/red, voltaje y bateria.
- [x] Vista de eventos criticos / auditoria (pestaña "Eventos" en el panel, 2026-08-12).
- [x] Crear comandos pendientes sin modificar actuador inmediatamente (hito de sincronizacion resuelto 2026-08-12).
- [x] Mostrar comandos pendientes y su estado (pestaña "Comandos", 2026-08-12) — ahora si refleja la realidad: "Pendiente" hasta que el simulador/dispositivo confirma via ACK.

## Firmware STM Futuro

- [ ] Definir placa STM final.
- [x] Definir modem/conectividad para prototipo. (A7670C/A7670SA, LTE Cat-1, 2026-08-12; ver nota abajo)
- [ ] Confirmar variante de bandas del A7670 contra el operador del piloto y validar consumo/DC-DC.
- [ ] Evaluar upgrade a SIM7600 (LTE Cat-4) para version profesional/produccion futura.
- [x] Definir modulo GPS. (GY-GPSV3-NEO, chip u-blox NEO, UART)
- [x] Definir pantalla local de estado/debug. (OLED 1.3" 128x64 blanco/azul, usar I2C de 4 pines en vez de SPI de 7 para ahorrar GPIO)
- [ ] Definir circuito de sirena.
- [ ] Definir circuito de humo.
- [ ] Definir circuito de corta corriente.
- [ ] Definir boton fisico y pulsaciones.
- [ ] Enviar telemetria por API.
- [ ] Consultar comandos pendientes.
- [ ] Ejecutar actuadores.
- [ ] Confirmar ACK.
- [ ] Cola offline y reintentos.

## Pruebas Manuales Actuales

Levantar API local:

```bash
cd functions
npm run serve:device-api
```

Enviar telemetria simulada:

```bash
python scripts/stm_simulator.py --scenario carjacking --iterations 5 --interval 1
```

Crear comando de prueba para el simulador:

```bash
curl -X POST http://localhost:5001/api/v1/devices/GPS-SIM001/commands ^
  -H "Content-Type: application/json" ^
  -d "{\"target\":\"humo\",\"value\":true,\"requestedBy\":\"local-admin\",\"requestedByRole\":\"admin\"}"
```

En PowerShell, si no usas `curl`, puedes usar:

```powershell
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:5001/api/v1/devices/GPS-SIM001/commands" `
  -ContentType "application/json" `
  -Body '{"target":"humo","value":true,"requestedBy":"local-admin","requestedByRole":"admin"}'
```

## Siguiente Hito Recomendado

~~Conectar panel admin y app movil al modelo `device_commands`...~~ — **Resuelto 2026-08-12.** Ver `docs/plan-de-trabajo.md` seccion "Hito de sincronizacion".

~~Avanzar en reglas Realtime Database...~~ — **Resuelto 2026-08-12.** Ver `docs/database-rules.md`. Pendiente operativo antes de desplegar: sembrar el primer usuario admin a mano.

Siguiente hito: registrar `liveLocation` del usuario + logica de cercania usuario-vehiculo (Pista A, punto 3), o restringir las API keys de Google Maps (rapido, es configuracion).

## Notas De Hardware (2026-07-01)

Componentes confirmados por el equipo de hardware:

- GPS: modulo GY-GPSV3-NEO (chip u-blox NEO), comunicacion UART.
- Pantalla de estado/debug: OLED 1.3" 128x64 blanco/azul, SPI o I2C. Se recomienda I2C (4 pines) para liberar GPIO frente a UART del GPS y las salidas de actuadores.

Pendiente critico (resuelto, ver nota 2026-08-12 abajo): no habia modulo SIM/celular definido. Sin esto el STM no puede reportar telemetria ni recibir comandos fuera de una red WiFi conocida, lo que bloqueaba el inicio de la Fase 3 (Firmware MVP) del roadmap, ya que "levantar conectividad" es el primer paso antes de leer GPS o enviar heartbeat. Ver `docs/hardware-roadmap.md` y `docs/physical-device-integration.md`.

## Notas De Hardware (2026-08-12)

Decision de modem para destrabar Fase 3, en dos etapas:

- **Prototipo actual:** SIMCom A7670C/A7670SA (LTE Cat-1). Mismo fabricante y comandos AT que el SIM7600 evaluado antes, asi que el firmware no se rehace al migrar. Costo aproximado USD 10-25 por modulo (importado), muy por debajo del SIM7600 (~CLP 90.490 con stock inmediato en Chile). Suficiente para telemetria/comandos JSON (payloads chicos, no se necesita el ancho de banda de Cat-4).
- **Version profesional/produccion futura:** SIM7600 (LTE Cat-4) queda como upgrade evaluado, no descartado.
- **Se descarta cualquier modulo 2G** (ej. SIM800L): Entel ya completo el apagon de 2G (2024) y Movistar/Claro tienen confirmado el cierre de 2G y 3G para 2025-2026 en Chile. Comprar un modulo 2G hoy es comprar algo que puede quedar sin red durante el piloto.
- Sigue pendiente: confirmar bandas del A7670 contra el operador real del piloto y dimensionar la fuente DC-DC para sus picos de consumo.
