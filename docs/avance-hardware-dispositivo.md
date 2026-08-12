# Avance Del Dispositivo Físico — First Protection

Informe de avance orientado al cliente, enfocado en la construcción del dispositivo instalado en el vehículo (no en el software). Refleja el estado real de cada componente según la documentación técnica y de arquitectura disponible a la fecha.

Fecha: 2026-08-12.

## Resumen

El dispositivo físico ("STM") es el equipo que se instala en el vehículo y que reporta ubicación, estado y ejecuta las acciones de seguridad (humo, sirena, corte de corriente). El diseño del prototipo ya está definido a nivel de arquitectura: qué componente cumple cada función y cómo se comunican entre sí. De los 10 componentes que forman el dispositivo, **4 están confirmados y con especificación técnica en mano** (incluyendo el módem, recién cerrado), y el resto está identificado pero pendiente de diseño de circuito o de compra.

**Nota de alcance:** esta etapa del proyecto es un prototipo/MVP para validar el sistema completo funcionando ("dar la vuelta" con un vehículo de prueba), no un producto para fabricar en volumen. Las decisiones de componentes priorizan velocidad y costo para esta etapa; donde aplica, se deja anotado el camino de upgrade para una versión más robusta más adelante.

## Estado Por Componente

| Componente | Función en el dispositivo | Estado | Detalle |
|---|---|---|---|
| **Controlador (familia STM32)** | Cerebro del dispositivo: lee sensores, decide y controla los actuadores. | 🟢 Familia definida | Se eligió la familia de microcontrolador STM32. Falta cerrar la placa/modelo exacto y su distribución de pines (paso siguiente, no bloqueante). |
| **Módulo GPS/GNSS (NEO-M8N)** | Ubicación real del vehículo — la fuente oficial de posición, no el teléfono del usuario. | 🟢 Confirmado | Módulo u-blox NEO-M8N (variante GY-GPSV3-NEO), comunicación UART. Ficha técnica ya en mano: precisión de 2 metros, primer posicionamiento en 1 segundo (arranque en caliente) o 26 segundos (arranque en frío), hasta 500 m/s de velocidad máxima. Componente listo para integrarse. |
| **Pantalla de diagnóstico (OLED)** | Pantalla local para revisar el estado del dispositivo durante instalación o soporte técnico — no reemplaza ninguna función de seguridad. | 🟢 Confirmado | OLED 1.3" 128x64, interfaz I2C (elegida sobre SPI para ahorrar pines, ya que GPS y actuadores también los usan). |
| **Módem celular (A7670C/A7670SA para el prototipo)** | Comunicación del dispositivo con la nube — sin esto, el dispositivo no puede reportar ubicación ni recibir comandos fuera de una red WiFi conocida. | 🟢 Confirmado para esta etapa | Se eligió un módem LTE de menor costo para esta etapa de prototipo, en vez del SIM7600 evaluado inicialmente. Mismo fabricante y compatible a nivel de firmware, así que no se pierde el trabajo de diseño ya hecho. El SIM7600 (más rápido y algo más caro) queda anotado como opción para una versión más robusta más adelante, no descartado. Falta confirmar la compatibilidad de bandas exacta con el operador local — mismo paso que hubiera aplicado igual con cualquier módem elegido. |
| **Plan de datos / SIM celular** | Conectividad móvil para que el módem transmita. | 🟠 Pendiente | Con el módem ya definido, se puede avanzar a elegir plan/operador. |
| **Fuente DC-DC automotriz** | Convierte la alimentación de 12V del vehículo a los 5V/3.3V que necesita la electrónica del dispositivo. | 🟠 Pendiente de diseño | Componente identificado como requerido; falta validar el circuito con protecciones (fusible, ruido eléctrico del vehículo, picos de tensión). |
| **Antenas (LTE y GNSS)** | Recepción de señal celular y satelital. | 🟠 Pendiente de diseño | Tipo de antena y conector exacto dependen de la placa final. |
| **Relés/MOSFETs de potencia (sirena, humo, corte de corriente)** | Circuito que permite que el controlador active físicamente cada sistema de seguridad. | 🟠 Pendiente de diseño | Los 3 actuadores están identificados; falta definir el circuito de potencia aislado para cada uno. |
| **Botón físico oculto** | Activación manual de una alerta o protocolo de emergencia desde dentro del vehículo. | 🟠 Pendiente de diseño | El comportamiento ya está definido a nivel funcional (pulsación corta = alerta, pulsación larga = protocolo activo); falta el circuito físico. |
| **Lectura de voltaje/ignición** | Diagnóstico eléctrico: saber si el vehículo está encendido y el estado de la batería. | 🟡 Pendiente de diseño | Requiere un circuito de lectura (divisor de voltaje protegido) todavía no definido. |

**Leyenda:** 🟢 confirmado y listo para integrar · 🟡 en la etapa final de definición · 🟠 identificado, pendiente de diseño de circuito o compra.

## Por Qué El Módem Celular Era El Componente Clave

De los 10 componentes, el módem celular era el único que **condicionaba el inicio de la siguiente etapa** (programar el firmware que hace hablar al dispositivo con la nube). Con la elección del A7670 para esta etapa, ese bloqueo queda resuelto y se puede avanzar de forma continua con el resto de la construcción.

## Camino Ya Recorrido

- Arquitectura completa del sistema definida: qué hace el dispositivo, qué hace la nube y qué hace cada aplicación.
- Contrato técnico de comunicación ya escrito y probado: se definió exactamente qué información envía el dispositivo (ubicación, batería, señal, estado de los actuadores) y cómo recibe y confirma órdenes. Este contrato ya se validó con un simulador de software, así que cuando el dispositivo físico esté listo, conectarlo es un paso de integración, no de diseño desde cero.
- 4 de 10 componentes confirmados con ficha técnica en mano (controlador, GPS, pantalla de diagnóstico y módem celular).

## Próximo Hito

Confirmar la variante de bandas del módem A7670 contra el operador local del piloto y comenzar la programación del firmware del dispositivo — primera vez que el prototipo hablará con la nube real.

---
*Este informe complementa el plan de trabajo interno (`docs/plan-de-trabajo.md`), que cubre además el avance de software.*
