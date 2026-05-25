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
- [ ] Reglas Realtime Database definitivas.
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
- [ ] Tests automatizados de API.
- [ ] Validacion avanzada de comandos peligrosos.
- [ ] Rate limiting por dispositivo.
- [ ] Rotacion de secretos por dispositivo.

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
- [ ] Mostrar estado de comando: pendiente, recibido, ejecutado, fallido, expirado.
- [ ] Registrar ubicacion del usuario en `usuarios/{uid}/liveLocation`.
- [ ] Modo estacionado/armado.
- [ ] Logica de cercania usuario-vehiculo.
- [ ] Alerta de alejamiento o posible portonazo.
- [ ] Historial de eventos para el cliente.

## Panel Admin

- [x] Acceso protegido por rol.
- [x] Dashboard de dispositivos.
- [x] Confirmacion para comandos criticos.
- [ ] Crear comandos pendientes sin modificar actuador inmediatamente.
- [ ] Mostrar comandos pendientes y ACK.
- [ ] Mostrar ultimo heartbeat.
- [ ] Mostrar firmware/hardware version.
- [ ] Mostrar senal GPS/red, voltaje y bateria.
- [ ] Vista de eventos criticos.
- [ ] Vista de instalacion/diagnostico tecnico.

## Firmware STM Futuro

- [ ] Definir placa STM final.
- [ ] Definir modem/conectividad.
- [ ] Definir modulo GPS.
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

Conectar panel admin y app movil al modelo `device_commands` para que los botones no alteren actuadores directamente, sino que creen comandos pendientes y esperen ACK del dispositivo.
