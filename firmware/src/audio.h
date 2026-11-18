#ifndef AUDIO_H
#define AUDIO_H

#include <stdint.h>

/*
 * Mensajes de voz con un DFPlayer Mini (MP3 desde microSD, amplificador 3 W).
 * Comparte USART1 con el GPS: el GPS solo transmite hacia la placa (RX, D2) y
 * el DFPlayer solo recibe (TX, D8), ambos a 9600 baudios.
 *   D8 -> RX del DFPlayer (con resistencia de 1 k en serie), 5V, GND,
 *   SPK1/SPK2 -> parlante de 3 W.
 * Archivos en la microSD: /mp3/0001.mp3, /mp3/0002.mp3... (numero = mensaje).
 * Sin respuesta del modulo no se puede detectar si esta conectado, asi que
 * cada mensaje tambien se muestra en la pantalla y en el log.
 *
 * Catalogo propuesto en docs/plan-de-trabajo.md seccion 11 (pendiente de
 * confirmar con el cliente).
 */

typedef enum {
    AUDIO_ARMADO = 1,
    AUDIO_DESARMADO = 2,
    AUDIO_PROTOCOLO_ON = 3,
    AUDIO_PROTOCOLO_OFF = 4,
    AUDIO_MOVIMIENTO_NO_AUTORIZADO = 5,
    AUDIO_CORTE_ON = 6,
    AUDIO_HUMO_ON = 7,
    AUDIO_MESSAGE_COUNT = 7,
} AudioMessage;

#define AUDIO_VOLUME_MAX 30

void audio_init(void);
void audio_tick(uint32_t nowMs);
void audio_play(AudioMessage message);
void audio_set_volume(uint8_t volume);
uint8_t audio_volume(void);

/* Etiqueta corta del mensaje que esta sonando (para la pantalla), o NULL. */
const char *audio_now_playing(uint32_t nowMs);

/* Imprime todos los mensajes ("# AudioCatalogo N: "texto""), para que el
 * puente del PC genere los audios por adelantado. */
void audio_print_catalog(void);

#endif
