#include "audio.h"

#include <stdbool.h>
#include <stdio.h>

#include "gps.h"
#include "stm32f4xx_hal.h"

#define POWER_UP_DELAY_MS 2000 /* el DFPlayer tarda ~1.5 s en leer la microSD */
#define DISPLAY_LABEL_MS 3000
#define DEFAULT_VOLUME 20

/* Comandos del protocolo serial del DFPlayer Mini. */
#define CMD_SET_VOLUME 0x06
#define CMD_PLAY_MP3_FOLDER 0x12 /* reproduce /mp3/NNNN.mp3 */

typedef struct {
    const char *label; /* para la pantalla (sin tildes: la fuente es ASCII), max 13 caracteres */
    const char *text;  /* texto del mensaje en UTF-8; el puente del PC lo usa para generar la voz */
} MessageInfo;

static const MessageInfo messages[AUDIO_MESSAGE_COUNT + 1] = {
    [AUDIO_ARMADO] = {"Armado", "Sistema de seguridad armado."},
    [AUDIO_DESARMADO] = {"Desarmado", "Sistema de seguridad desarmado."},
    [AUDIO_PROTOCOLO_ON] = {"Protocolo ON",
                            "Atención: este vehículo está bajo protocolo de seguridad First Protection. "
                            "Su ubicación está siendo informada."},
    [AUDIO_PROTOCOLO_OFF] = {"Protocolo OFF", "Protocolo de seguridad desactivado."},
    [AUDIO_MOVIMIENTO_NO_AUTORIZADO] = {"Mov. no autor.",
                                        "Vehículo en movimiento no autorizado. Detenga el vehículo."},
    [AUDIO_CORTE_ON] = {"Corte ON", "Corte de energía activado."},
    [AUDIO_HUMO_ON] = {"Humo ON", "Atención: sistema de humo disuasivo activado."},
};

static uint8_t volume = DEFAULT_VOLUME;
static bool volumeSent;
static AudioMessage pending; /* 0 = nada; si llegan varios antes de poder enviar, gana el ultimo */
static AudioMessage lastPlayed;
static uint32_t lastPlayedMs;

static void sendCommand(uint8_t command, uint16_t param)
{
    uint8_t frame[10] = {0x7E, 0xFF, 0x06, command, 0x00, (uint8_t)(param >> 8), (uint8_t)param, 0, 0, 0xEF};
    uint16_t sum = 0;
    for (int i = 1; i <= 6; i++) {
        sum += frame[i];
    }
    uint16_t checksum = (uint16_t)(0 - sum);
    frame[7] = (uint8_t)(checksum >> 8);
    frame[8] = (uint8_t)checksum;
    gps_usart_transmit(frame, sizeof frame);
}

void audio_init(void)
{
    /* USART1 ya la inicializa gps_init(); aqui no hay nada que configurar. */
}

void audio_tick(uint32_t nowMs)
{
    if (!pending || nowMs < POWER_UP_DELAY_MS) {
        return;
    }
    if (!volumeSent) {
        sendCommand(CMD_SET_VOLUME, volume);
        volumeSent = true;
        HAL_Delay(30); /* el modulo necesita un respiro entre comandos */
    }
    sendCommand(CMD_PLAY_MP3_FOLDER, (uint16_t)pending);
    pending = 0;
}

void audio_play(AudioMessage message)
{
    if (message < 1 || message > AUDIO_MESSAGE_COUNT) {
        return;
    }
    printf("# Audio %u: \"%s\"\r\n", (unsigned)message, messages[message].text);
    pending = message;
    lastPlayed = message;
    lastPlayedMs = HAL_GetTick();
}

void audio_set_volume(uint8_t value)
{
    volume = value > AUDIO_VOLUME_MAX ? AUDIO_VOLUME_MAX : value;
    if (HAL_GetTick() >= POWER_UP_DELAY_MS) {
        sendCommand(CMD_SET_VOLUME, volume);
        volumeSent = true;
    } else {
        volumeSent = false;
    }
}

uint8_t audio_volume(void)
{
    return volume;
}

void audio_print_catalog(void)
{
    for (int i = 1; i <= AUDIO_MESSAGE_COUNT; i++) {
        printf("# AudioCatalogo %d: \"%s\"\r\n", i, messages[i].text);
    }
}

const char *audio_now_playing(uint32_t nowMs)
{
    if (!lastPlayed || nowMs - lastPlayedMs >= DISPLAY_LABEL_MS) {
        return NULL;
    }
    return messages[lastPlayed].label;
}
