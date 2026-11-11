# Firmware Del Dispositivo STM

Firmware del dispositivo First Protection sobre la placa de desarrollo **NUCLEO-F401RE** (STM32F401RE), en banco de pruebas. Implementa el contrato de `docs/device-api-contract.md`: telemetría, eventos, comandos y ACK.

Mientras no esté el módem A7670, la placa se comunica por USB con `scripts/stm_serial_bridge.py`. El puente cumple el rol del módem: firma con HMAC y reenvía a la `deviceApi` real. El protocolo serial está descrito en `src/device.h`.

## Conexiones

Placa con el USB hacia arriba. Los nombres de cada pin están impresos en la Nucleo.

| Componente | Pin del componente | Pin Nucleo | Nota |
|---|---|---|---|
| LED corte de corriente | + (con resistencia 220–330 Ω a GND) | D3 | Fijo |
| LED sirena | + | D4 | Parpadeo rápido |
| LED humo | + | D5 | Fijo |
| LED protocolo de emergencia | + | D6 | Fijo |
| LED sistema armado | + | D7 | Fijo |
| LED de vida | — | LD2 (en la placa) | Parpadeo 1 Hz |
| Botón oculto | — | B1 (botón azul de la placa) | Corto = alerta, 2 s = protocolo |
| Ignición/ACC (simulada) | cable a GND | D9 | Cable conectado = llave en contacto |
| GPS NEO-M8N | TX | D2 | USART1, 9600 baudios |
| | RX (opcional) | D8 | |
| | VCC / GND | 5V o 3V3 / GND | Según la etiqueta del módulo |
| LCD GM12864-03A (ST7567) | CS | D10 | SPI por software |
| | RST | D11 | |
| | A0 | D12 | |
| | SCK | D15 | |
| | SDA | D14 | |
| | GND / VDD | GND / 3V3 | |
| | BA / BK | opcional | Retroiluminación: BK a GND, BA a 3V3 **con resistencia de 100–220 Ω** |

Pines reservados:
- **D13**: no usar, es el LED LD2 de la placa.
- **USART6** (PA11/PA12, conector morpho): módem A7670.
- **A0–A5**: lectura de voltaje del vehículo (ADC).

## Compilar, grabar y monitorear

Requiere PlatformIO (`pip install platformio`). Desde esta carpeta:

```
python -m platformio run -t upload      # compila y graba (copia el .bin a la unidad del ST-Link)
python -m platformio device monitor     # consola serial a 115200
```

En la consola, `ayuda` lista los comandos manuales: `humo on`, `corte off`, `armar`, `estado`, `contraste 0-63`, `girar`, `espejo`, `nmea <frase>`, etc. La pantalla del banco se ve bien con los valores de fábrica (contraste 20, sin girar).

## Conectar con el sistema real

```powershell
$env:FP_DEVICE_SECRET = (firebase functions:secrets:access DEVICE_SIM_SECRET --project first-protection | Out-String).Trim()
python ..\scripts\stm_serial_bridge.py --base-url https://us-central1-first-protection.cloudfunctions.net/deviceApi
```

La placa aparece como `GPS-NUCLEO01`. Requiere `pyserial`. Mientras el puente corre, ocupa el puerto serie, y el monitor de PlatformIO no puede abrirlo.

## Qué es real y qué está simulado

- **Real:** contrato de mensajes, cola de comandos con ACK, reglas locales de seguridad (no cortar corriente ni armar en movimiento), GPS y pantalla.
- **Simulado:**
  - actuadores (LEDs en vez de relés);
  - ignición (un cable en vez de la señal ACC);
  - voltaje (valor fijo);
  - conectividad (puente USB en vez del módem).
- **Sin fix de GPS:** se usa la ignición como aproximación de "en movimiento", y la ubicación es la última conocida, o una de prueba si nunca hubo fix.
