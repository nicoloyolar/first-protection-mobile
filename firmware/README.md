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
| | RX | sin conectar | D8 queda para el DFPlayer |
| | VCC / GND | 5V o 3V3 / GND | Según la etiqueta del módulo |
| LCD GM12864-03A (ST7567) | CS | D10 | SPI por software |
| | RST | D11 | |
| | A0 | D12 | |
| | SCK | D15 | |
| | SDA | D14 | |
| | GND / VDD | GND / 3V3 | |
| | BA / BK | opcional | Retroiluminación: BK a GND, BA a 3V3 **con resistencia de 100–220 Ω** |
| DFPlayer Mini (mensajes de voz) | RX | D8 | **Con resistencia de 1 kΩ en serie.** Comparte USART1 con el GPS: el GPS usa solo RX (D2) y el DFPlayer solo TX (D8), los dos a 9600 |
| | VCC / GND | 5V / GND | |
| | SPK1 / SPK2 | parlante 3 W (4–8 Ω) | Los audios van en la microSD como `/mp3/0001.mp3`, `/mp3/0002.mp3`… (ver `src/audio.h`) |

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

En la consola, `ayuda` lista los comandos manuales: `humo on`, `corte off`, `armar`, `estado`, `contraste 0-63`, `girar`, `espejo`, `audio 1-7`, `volumen 0-30`, `nmea <frase>`, etc. La pantalla del banco se ve bien con los valores de fábrica (contraste 20, sin girar).

## Conectar con el sistema real

```powershell
$env:FP_DEVICE_SECRET = (firebase functions:secrets:access DEVICE_SIM_SECRET --project first-protection | Out-String).Trim()
python ..\scripts\stm_serial_bridge.py --base-url https://us-central1-first-protection.cloudfunctions.net/deviceApi
```

La placa aparece como `GPS-NUCLEO01`. Requiere `pyserial`. Mientras el puente corre, ocupa el puerto serie, y el monitor de PlatformIO no puede abrirlo.

**Mensajes de voz sin DFPlayer:** en Windows, el puente hace de DFPlayer y reproduce cada mensaje por el parlante del PC (`scripts/pc_audio.py`). Al arrancar, le pide a la placa su catálogo (`audio catalogo`) y genera los audios por adelantado. Usa la voz latinoamericana **es-US-Chirp3-HD-Kore** de Google Cloud Text-to-Speech, con las credenciales ADC de gcloud y el proyecto `first-protection`; la voz final la define el cliente.
- `firmware/audio/0001.wav`, `0002.wav`… son los que suenan en el PC.
- `firmware/audio/mp3/0001.mp3`, `0002.mp3`… están **listos para copiar a la microSD** del DFPlayer (carpeta `mp3`).

Los audios se regeneran solos si cambia el texto en `src/audio.c` o la voz. Otra voz: `--voice es-US-Chirp3-HD-Charon`. Voz de Windows sin internet: `--voice windows`. Sin audio: `--no-pc-audio`.

## Qué es real y qué está simulado

- **Real:** contrato de mensajes, cola de comandos con ACK, reglas locales de seguridad (no cortar corriente ni armar en movimiento), GPS y pantalla.
- **Simulado:**
  - actuadores (LEDs en vez de relés);
  - ignición (un cable en vez de la señal ACC);
  - voltaje (valor fijo);
  - conectividad (puente USB en vez del módem).
- **Sin fix de GPS:** se usa la ignición como aproximación de "en movimiento", y la ubicación es la última conocida, o una de prueba si nunca hubo fix.
