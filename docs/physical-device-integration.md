# Integracion Con Dispositivo Fisico STM

Este documento define como debe integrarse el dispositivo fisico instalado en el vehiculo con First Protection. La meta es que el firmware STM, el backend, la app movil y el panel web trabajen con el mismo contrato tecnico.

## Principio Central

El sistema maneja dos ubicaciones diferentes:

- Ubicacion del vehiculo: la envia el dispositivo STM/GPS instalado en el automovil.
- Ubicacion del usuario: la envia el telefono movil del usuario, cuando la app tiene permiso.

La ubicacion oficial del vehiculo siempre debe venir del dispositivo fisico. La app movil no debe sobrescribirla, salvo en modo demo o simulacion claramente marcado.

```text
Dispositivo STM = fuente del vehiculo
Telefono movil = fuente del usuario
Servidor/Firebase = arbitro, auditor y sincronizador
Panel web = operacion y soporte
App movil = control autorizado y visualizacion
```

## Responsabilidades Del STM

El dispositivo fisico debe:

- Enviar telemetria periodica del vehiculo.
- Reportar eventos criticos: movimiento, ignicion, boton fisico, manipulacion, baja bateria, perdida de GPS.
- Consultar o recibir comandos pendientes.
- Ejecutar actuadores fisicos: humo, sirena y corta corriente.
- Confirmar ejecucion, rechazo o falla de cada comando.
- Mantener un modo local de emergencia si pierde conexion.

## Actuadores Fisicos

Los actuadores se ejecutan en el vehiculo, no en la app:

- `humo`: sistema de disuasion por humo.
- `sirena`: alerta sonora.
- `cortaCorriente`: bloqueo o corte controlado del circuito definido por hardware.

La app movil y el panel web solo solicitan comandos. El STM es quien confirma que el actuador se activo o desactivo.

## Entradas Fisicas Esperadas

Entradas minimas recomendadas:

- Boton fisico oculto bajo el volante.
- Ignicion o ACC.
- Sensor de movimiento o acelerometro.
- Alimentacion principal del vehiculo.
- Bateria interna de respaldo.
- GPS.
- Senal de modem o conectividad.
- Tamper o desconexion de antena/modulo, si aplica.

## Flujo De Telemetria

```text
STM toma datos
  -> envia heartbeat/telemetria
  -> backend valida identidad y estructura
  -> backend actualiza dispositivos/{deviceId}
  -> app y panel reciben cambios en tiempo real
  -> si hay regla de riesgo, se crea evento/alerta
```

## Flujo De Comandos

```text
Usuario o admin solicita comando
  -> backend crea comando pendiente
  -> STM consulta o recibe comando
  -> STM valida estado local
  -> STM ejecuta actuador
  -> STM reporta resultado
  -> backend actualiza estado y registra evento
  -> app/panel muestran confirmacion
```

## Boton Fisico Bajo El Volante

El boton fisico puede usarse para activar un protocolo local rapido.

Comportamiento recomendado:

1. Pulsacion corta: marcar evento `panicButtonPressed`.
2. Pulsacion larga: activar `protocoloActivo`.
3. Doble pulsacion: cancelar protocolo, si el negocio lo permite.

El firmware debe enviar el evento al backend y, si corresponde, activar sirena/humo/corta corriente segun reglas locales.

## Modos Del Sistema

Estados sugeridos para `dispositivos/{deviceId}/systemMode`:

- `normal`: monitoreo sin alerta.
- `armed`: vehiculo protegido/estacionado.
- `proximityWatch`: monitoreo de cercania usuario-vehiculo.
- `suspiciousMovement`: movimiento no esperado.
- `carjackingSuspected`: posible portonazo o robo en curso.
- `theftConfirmed`: robo confirmado por usuario/admin/dispositivo.
- `service`: mantencion o instalacion.
- `offline`: sin conexion reciente.

## Cercania Usuario-Vehiculo

El sistema debe comparar:

- `dispositivos/{deviceId}/location`: ubicacion del vehiculo.
- `usuarios/{uid}/liveLocation`: ubicacion del usuario.

Reglas iniciales:

- Si el vehiculo esta estacionado y se mueve mas de `armedRadiusMeters`, generar alerta.
- Si el vehiculo se aleja del telefono a velocidad sostenida, generar `carjackingSuspected`.
- Si el usuario activa protocolo, pasar a `theftConfirmed`.
- Si el STM reporta boton fisico, crear evento de alta prioridad.

Parametros sugeridos:

- `armedRadiusMeters`: 80 a 150 metros.
- `proximityRadiusMeters`: 30 a 60 metros.
- `carjackingDistanceMeters`: 80 metros.
- `carjackingSpeedKmh`: 8 km/h o mas.
- `heartbeatTimeoutSeconds`: 60 a 180 segundos.

Estos valores deben quedar configurables por organizacion o tipo de cliente.

## Seguridad Minima

El STM no debe escribir directamente como usuario final. Recomendacion:

- Cada dispositivo tiene `deviceId`.
- Cada dispositivo tiene `deviceSecret` o certificado.
- El backend valida firma/HMAC o token del dispositivo.
- El backend escribe en Firebase.
- Las apps nunca escriben telemetria del vehiculo.

Para el MVP se puede partir con HTTPS + HMAC por dispositivo. Para produccion, evaluar certificados por dispositivo o un gateway IoT.

## Reintentos Y Offline

El firmware debe manejar:

- Cola local de eventos si no hay red.
- Reintento exponencial.
- Confirmacion de recepcion del backend.
- Numeros de secuencia para evitar eventos duplicados.
- Ultimo comando procesado para evitar reejecuciones peligrosas.

## Componentes Confirmados (2026-07-01)

- GPS: modulo GY-GPSV3-NEO (chip u-blox NEO), UART.
- Pantalla local de estado/debug: OLED 1.3" 128x64 blanco/azul, SPI o I2C. Se recomienda I2C de 4 pines para no competir por GPIO con GPS y actuadores. No reemplaza ninguna entrada fisica listada arriba; es solo para diagnostico en banco.

## Pendientes De Decision

- Red disponible para el STM: LTE, NB-IoT, WiFi, LoRa u otra. **Sin definir. Aun no hay modulo SIM/celular** — bloqueo principal antes de iniciar Fase 3 (Firmware MVP) del roadmap, ya que WiFi y LoRa no son viables para un vehiculo en movimiento fuera de una red conocida.
- Protocolo principal: HTTPS pull, HTTPS push, MQTT o WebSocket.
- Quien decide reglas automaticas: firmware, backend o mixto.
- Politica exacta del corta corriente por seguridad electrica/legal.
- Si humo/sirena pueden activarse automaticamente o solo por confirmacion humana.
