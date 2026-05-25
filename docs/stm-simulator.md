# Simulador STM

El simulador STM permite probar el contrato de integracion antes de tener el dispositivo fisico terminado. Esta escrito en Python y no requiere paquetes externos.

## Por Que Python

Se eligio Python para el simulador porque:

- No depende de Flutter ni de Dart.
- Es facil de ejecutar en PCs de desarrollo, notebooks de laboratorio o equipos de firmware.
- Usa solo librerias estandar.
- Permite simular HTTP, firmas HMAC, telemetria, eventos y ACK de comandos.

Los modelos Dart igualmente existen para que la app y el panel entiendan el mismo contrato.

## Ejecutar En Modo Dry Run

El modo `--dry-run` imprime los requests sin enviarlos.

```bash
python scripts/stm_simulator.py --dry-run
```

Escenario de vehiculo estacionado:

```bash
python scripts/stm_simulator.py --scenario parked --dry-run
```

Escenario de vehiculo en movimiento:

```bash
python scripts/stm_simulator.py --scenario drive --dry-run
```

Escenario de posible portonazo:

```bash
python scripts/stm_simulator.py --scenario carjacking --dry-run
```

Escenario de conectividad intermitente:

```bash
python scripts/stm_simulator.py --scenario offline --dry-run
```

## Ejecutar Contra Una API Local

Cuando exista backend local:

```bash
python scripts/stm_simulator.py ^
  --base-url http://localhost:5001 ^
  --device-id GPS-SIM001 ^
  --secret dev-secret ^
  --scenario drive
```

En PowerShell tambien puedes usar una sola linea:

```bash
python scripts/stm_simulator.py --base-url http://localhost:5001 --device-id GPS-SIM001 --secret dev-secret --scenario drive
```

## Escenarios Soportados

- `parked`: vehiculo quieto, ignicion apagada.
- `drive`: vehiculo en movimiento normal.
- `carjacking`: vehiculo se mueve rapido y simula boton fisico en la tercera iteracion.
- `offline`: alterna conectividad para probar tolerancia a fallos.

## Endpoints Que Usa

```text
POST /api/v1/devices/{deviceId}/telemetry
POST /api/v1/devices/{deviceId}/events
GET  /api/v1/devices/{deviceId}/commands/next
POST /api/v1/devices/{deviceId}/commands/{commandId}/ack
```

## Firma De Requests

Cada request incluye:

```text
X-Device-Id
X-Device-Timestamp
X-Device-Signature
```

`X-Device-Signature` se calcula como:

```text
hmac_sha256(json_body + timestamp, deviceSecret)
```

## Siguiente Paso

Implementar una API local o Cloud Functions que responda a estos endpoints. Mientras eso no exista, usar `--dry-run` para validar payloads y escenarios.
