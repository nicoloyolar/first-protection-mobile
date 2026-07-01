# Plan De Trabajo Para Integracion Hardware

Este plan ordena el trabajo para integrar el dispositivo STM al sistema First Protection sin bloquear el avance de la app y el panel web.

## Objetivo

Construir un sistema donde el dispositivo fisico instalado en el vehiculo reporte telemetria, reciba comandos y ejecute actuadores de disuasion/control: humo, sirena y corta corriente.

## Fase 0: Definicion Tecnica

Estado esperado: decisiones claras antes de firmware real.

- Definir placa STM exacta y perifericos.
- Definir modem o conectividad.
- Definir modulo GPS.
- Definir actuadores y circuitos: humo, sirena, relay/corte.
- Definir alimentacion principal y respaldo.
- Definir boton fisico y tipo de pulsaciones.
- Definir riesgos legales/operativos del corta corriente.
- Definir si se usara HTTPS, MQTT o ambos.

Entregables:

- Diagrama electrico preliminar.
- Lista de componentes.
- Estados del firmware.
- Contrato API versionado.

### Estado Actual (2026-07-01)

- GPS definido: modulo GY-GPSV3-NEO (chip u-blox NEO), UART.
- Pantalla local definida: OLED 1.3" 128x64 blanco/azul. Usar interfaz I2C (4 pines) en vez de SPI (7 pines) para ahorrar GPIO, dado que ya se ocupan pines en UART (GPS) y salidas digitales (actuadores).
- Modem/conectividad: sin definir. No hay modulo SIM/celular todavia. Este es el bloqueo principal de esta fase: sin conectividad resuelta no se puede avanzar a Fase 3, donde "levantar conectividad" es el primer paso del firmware MVP.

## Fase 1: Backend De Integracion

Estado esperado: backend listo antes de tener hardware final.

- Crear endpoint de telemetria.
- Crear endpoint de eventos.
- Crear cola de comandos pendientes.
- Crear endpoint de ACK de comandos.
- Validar firma por dispositivo.
- Registrar eventos en Firebase.
- Mantener campos de compatibilidad para app actual.

Entregables:

- API funcional en entorno dev.
- Colecciones/rutas Firebase creadas.
- Tests basicos de payloads validos e invalidos.
- Script o cliente mock para simular STM.

## Fase 2: Simulador De Dispositivo

Estado esperado: probar app, panel y backend sin hardware.

- Crear simulador CLI o script que envie telemetria.
- Simular movimiento GPS.
- Simular boton fisico.
- Simular actuadores y ACK.
- Simular offline/reintentos.
- Simular robo/portonazo.

Escenarios minimos:

- Vehiculo estacionado sin movimiento.
- Vehiculo se mueve sin usuario cerca.
- Usuario activa protocolo desde app.
- Admin activa humo/sirena/corte desde panel.
- Boton fisico activa alerta.
- Dispositivo pierde conexion.

## Fase 3: Firmware MVP

Estado esperado: firmware puede hablar con backend.

- Levantar conectividad.
- Leer GPS.
- Enviar heartbeat.
- Enviar telemetria.
- Consultar comandos.
- Ejecutar salidas digitales simuladas.
- Enviar ACK.
- Guardar cola local simple si no hay red.

Entregables:

- Firmware `0.1.0`.
- Logs de comunicacion.
- Prueba con dispositivo en banco.

## Fase 4: Hardware En Banco

Estado esperado: actuadores reales controlados en ambiente seguro.

- Probar relay/corte con carga segura.
- Probar sirena.
- Probar humo con restricciones de seguridad.
- Probar boton fisico.
- Probar alimentacion y bateria respaldo.
- Probar perdida y recuperacion de red.
- Probar perdida y recuperacion GPS.

Entregables:

- Matriz de pruebas.
- Registro de fallas.
- Ajustes de firmware/hardware.

## Fase 5: Integracion Vehicular Controlada

Estado esperado: prueba en vehiculo propio o controlado.

- Instalacion con tecnico.
- Validar ubicacion real del vehiculo.
- Validar comandos desde app.
- Validar comandos desde panel.
- Validar boton fisico.
- Validar modo estacionado.
- Validar distancia usuario-vehiculo.
- Validar protocolo de emergencia.

Entregables:

- Demo end-to-end.
- Checklist de instalacion.
- Procedimiento de emergencia.

## Fase 6: MVP Operativo

Estado esperado: sistema listo para pilotos.

- Usuarios internos First Protection.
- Clientes demo.
- Flota demo.
- Panel con estados de conexion.
- Eventos historicos.
- Alertas visibles.
- Notificaciones push.
- Reglas Firebase endurecidas.
- Restricciones de API keys.

## Trabajo En App Movil

- Mostrar ubicacion del vehiculo desde STM.
- Mostrar ubicacion del usuario solo como referencia de cercania.
- Agregar modo estacionado/armado.
- Agregar estado de conexion del dispositivo.
- Agregar confirmaciones y estados pendientes para comandos.
- Mostrar si el comando fue ejecutado, fallido o expirado.
- Agregar notificaciones push.

## Trabajo En Panel Web

- Mostrar dispositivos online/offline.
- Mostrar ultima telemetria y `lastSeenAt`.
- Mostrar comandos pendientes y su estado.
- Mostrar eventos criticos.
- Filtrar por organizacion/flota.
- Agregar vista de diagnostico para soporte tecnico.
- Agregar bloqueo operacional para comandos peligrosos.

## Trabajo En Seguridad

- Validar identidad del dispositivo.
- Separar permisos de usuario, admin y dispositivo.
- Evitar que clientes escriban telemetria vehicular.
- Auditar todos los comandos.
- Rotar secretos de dispositivo.
- Registrar instalacion y desinstalacion.

## Riesgos A Resolver

- Activacion accidental de corta corriente.
- Perdida de conectividad durante emergencia.
- GPS impreciso en estacionamientos/subterraneos.
- Latencia de comandos.
- Manipulacion fisica del dispositivo.
- Uso indebido de credenciales admin.

## Criterio De MVP Hardware

El MVP fisico esta listo cuando:

- El STM envia ubicacion real del vehiculo.
- App y panel muestran esa ubicacion.
- App y panel solicitan comandos.
- STM ejecuta y confirma comandos.
- Boton fisico genera evento critico.
- El sistema distingue ubicacion del usuario y ubicacion del vehiculo.
- Los eventos quedan auditados.
- Hay flujo offline/reintento minimo.
