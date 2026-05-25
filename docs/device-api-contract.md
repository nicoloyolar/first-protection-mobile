# Contrato API Para Dispositivo STM

Este contrato es la propuesta inicial para preparar la integracion entre el dispositivo fisico y First Protection. Puede implementarse como Cloud Functions, API REST propia o un gateway IoT.

## Version

- Version del contrato: `v1`
- Formato: JSON sobre HTTPS
- Alternativa futura: MQTT con los mismos payloads

## Identidad Del Dispositivo

Cada dispositivo debe tener:

- `deviceId`: identificador publico, por ejemplo `GPS-ABC123`.
- `deviceSecret`: secreto privado instalado en firmware o memoria segura.
- `firmwareVersion`: version del firmware.
- `hardwareVersion`: version de placa.

Headers recomendados:

```http
X-Device-Id: GPS-ABC123
X-Device-Timestamp: 1710000000
X-Device-Signature: hmac_sha256(body + timestamp, deviceSecret)
```

El backend debe rechazar requests sin firma valida, timestamps muy antiguos o `deviceId` desconocidos.

## Endpoints Propuestos

### POST /api/v1/devices/{deviceId}/telemetry

El STM envia estado y mediciones del vehiculo.

Request:

```json
{
  "sequence": 1024,
  "timestamp": 1710000000,
  "location": {
    "lat": -36.82699,
    "lng": -73.04977,
    "accuracyMeters": 8.5,
    "speedKmh": 31.4,
    "heading": 182.0,
    "gpsFix": true,
    "satellites": 9
  },
  "power": {
    "vehicleVoltage": 12.4,
    "backupBatteryPercent": 86,
    "externalPower": true
  },
  "signals": {
    "ignition": true,
    "movement": true,
    "panicButton": false,
    "tamper": false
  },
  "actuators": {
    "humo": false,
    "sirena": false,
    "cortaCorriente": false
  },
  "network": {
    "rssi": -71,
    "operator": "carrier",
    "online": true
  },
  "firmwareVersion": "0.1.0",
  "hardwareVersion": "rev-a"
}
```

Response:

```json
{
  "ok": true,
  "serverTime": 1710000001,
  "pendingCommands": 1
}
```

### GET /api/v1/devices/{deviceId}/commands/next

El STM consulta el siguiente comando pendiente.

Response sin comandos:

```json
{
  "ok": true,
  "command": null
}
```

Response con comando:

```json
{
  "ok": true,
  "command": {
    "commandId": "cmd_01HT",
    "type": "setActuator",
    "target": "humo",
    "value": true,
    "requestedBy": "uid-admin",
    "requestedByRole": "admin",
    "createdAt": 1710000000,
    "expiresAt": 1710000060
  }
}
```

### POST /api/v1/devices/{deviceId}/commands/{commandId}/ack

El STM confirma que recibio, ejecuto, rechazo o fallo el comando.

Request:

```json
{
  "status": "executed",
  "executedAt": 1710000005,
  "result": {
    "target": "humo",
    "value": true,
    "actuatorState": true
  },
  "errorCode": null,
  "message": "Humo activado correctamente"
}
```

Estados permitidos:

- `received`: el dispositivo recibio el comando.
- `executed`: el comando fue ejecutado.
- `rejected`: el dispositivo rechazo el comando por seguridad o estado local.
- `failed`: el comando fallo por hardware, energia o tiempo.
- `expired`: el comando expiro antes de ejecutarse.

### POST /api/v1/devices/{deviceId}/events

El STM envia eventos discretos.

Request:

```json
{
  "sequence": 1025,
  "timestamp": 1710000020,
  "type": "panicButtonPressed",
  "severity": "critical",
  "location": {
    "lat": -36.82699,
    "lng": -73.04977
  },
  "metadata": {
    "pressDurationMs": 2200
  }
}
```

Tipos iniciales:

- `panicButtonPressed`
- `ignitionOn`
- `ignitionOff`
- `movementDetected`
- `vehicleMovedWhileArmed`
- `tamperDetected`
- `gpsLost`
- `gpsRecovered`
- `powerDisconnected`
- `powerRestored`
- `actuatorStateChanged`
- `heartbeat`

## Modelo De Comandos

Comandos iniciales:

```json
{
  "type": "setActuator",
  "target": "humo",
  "value": true
}
```

Targets:

- `humo`
- `sirena`
- `cortaCorriente`
- `protocoloActivo`

Comandos futuros:

- `setSystemMode`
- `requestTelemetryNow`
- `restartDevice`
- `updateConfig`
- `firmwareUpdate`

## Esquema Firebase Sugerido

```text
dispositivos/{deviceId}
  id
  organizationId
  idVehiculo
  idPropietario
  alias
  patente
  systemMode
  connectionState
  lastSeenAt
  location
    lat
    lng
    accuracyMeters
    speedKmh
    heading
  power
    vehicleVoltage
    backupBatteryPercent
    externalPower
  signals
    ignition
    movement
    panicButton
    tamper
  actuators
    humo
    sirena
    cortaCorriente
  firmwareVersion
  hardwareVersion

device_commands/{deviceId}/{commandId}
  type
  target
  value
  status
  requestedBy
  requestedByRole
  createdAt
  expiresAt
  receivedAt
  executedAt
  errorCode

device_events/{deviceId}/{eventId}
  type
  severity
  timestamp
  location
  metadata
```

## Compatibilidad Con La App Actual

La app actual usa campos planos como:

- `latitud`
- `longitud`
- `velocidad`
- `voltaje`
- `humo`
- `protocoloActivo`
- `cortaCorriente`

Durante la transicion se puede mantener escritura duplicada:

```text
location.lat -> latitud
location.lng -> longitud
location.speedKmh -> velocidad
power.vehicleVoltage -> voltaje
actuators.humo -> humo
actuators.cortaCorriente -> cortaCorriente
```

Cuando app y panel ya consuman el esquema nuevo, los campos planos pueden quedar como compatibilidad temporal.

## Validaciones Minimas Del Backend

- Rechazar `deviceId` desconocido.
- Rechazar firma invalida.
- Rechazar comandos expirados.
- No aceptar timestamps muy antiguos.
- Ignorar `sequence` repetidos.
- Validar rangos de latitud, longitud, voltaje y velocidad.
- Registrar todos los comandos y eventos criticos.

## MQTT Futuro

Si se usa MQTT, los topicos equivalentes pueden ser:

```text
fp/devices/{deviceId}/telemetry
fp/devices/{deviceId}/events
fp/devices/{deviceId}/commands
fp/devices/{deviceId}/commands/{commandId}/ack
```

La estructura JSON debe mantenerse igual para no duplicar logica de backend.
