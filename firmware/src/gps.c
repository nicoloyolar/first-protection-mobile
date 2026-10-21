#include "gps.h"

#include <stdlib.h>
#include <string.h>

#include "stm32f4xx_hal.h"

#define GPS_BAUD 9600
#define RX_BUFFER_SIZE 512
#define NMEA_MAX 96
#define MAX_FIELDS 20
#define FIX_TIMEOUT_MS 3000  /* sin RMC valido en este tiempo = se perdio el fix */
#define DATA_TIMEOUT_MS 3000 /* sin bytes en este tiempo = modulo desconectado */
#define KNOTS_TO_KMH 1.852f

static UART_HandleTypeDef huart1;

/* Buffer circular llenado por la interrupcion de recepcion. */
static volatile uint8_t rxBuffer[RX_BUFFER_SIZE];
static volatile uint16_t rxHead;
static uint16_t rxTail;

static char sentence[NMEA_MAX];
static size_t sentenceLen;

static GpsData data;
static bool anyByte;
static uint32_t lastByteMs;
static uint32_t lastValidRmcMs;

void gps_init(void)
{
    GPIO_InitTypeDef gpio = {0};

    __HAL_RCC_USART1_CLK_ENABLE();
    __HAL_RCC_GPIOA_CLK_ENABLE();

    gpio.Pin = GPIO_PIN_9 | GPIO_PIN_10;
    gpio.Mode = GPIO_MODE_AF_PP;
    gpio.Pull = GPIO_PULLUP;
    gpio.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    gpio.Alternate = GPIO_AF7_USART1;
    HAL_GPIO_Init(GPIOA, &gpio);

    huart1.Instance = USART1;
    huart1.Init.BaudRate = GPS_BAUD;
    huart1.Init.WordLength = UART_WORDLENGTH_8B;
    huart1.Init.StopBits = UART_STOPBITS_1;
    huart1.Init.Parity = UART_PARITY_NONE;
    huart1.Init.Mode = UART_MODE_TX_RX;
    huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
    huart1.Init.OverSampling = UART_OVERSAMPLING_16;
    if (HAL_UART_Init(&huart1) != HAL_OK) {
        return;
    }

    __HAL_UART_ENABLE_IT(&huart1, UART_IT_RXNE);
    HAL_NVIC_SetPriority(USART1_IRQn, 2, 0);
    HAL_NVIC_EnableIRQ(USART1_IRQn);
}

void USART1_IRQHandler(void)
{
    /* Leer SR y luego DR limpia RXNE y tambien un eventual overrun. */
    uint32_t sr = USART1->SR;
    if (sr & (USART_SR_RXNE | USART_SR_ORE)) {
        uint8_t byte = (uint8_t)USART1->DR;
        uint16_t next = (uint16_t)((rxHead + 1) % RX_BUFFER_SIZE);
        if (next != rxTail) {
            rxBuffer[rxHead] = byte;
            rxHead = next;
        }
    }
}

/* ---- Parser NMEA ---- */

static int hexValue(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}

/* XOR de todo lo que hay entre '$' y '*' debe coincidir con los 2 digitos hex finales. */
static bool checksumOk(const char *s)
{
    const char *star = strchr(s, '*');
    if (!star || strlen(star) < 3) {
        return false;
    }
    uint8_t sum = 0;
    for (const char *p = s + 1; p < star; p++) {
        sum ^= (uint8_t)*p;
    }
    int hi = hexValue(star[1]);
    int lo = hexValue(star[2]);
    return hi >= 0 && lo >= 0 && sum == (uint8_t)((hi << 4) | lo);
}

/* Separa por comas conservando los campos vacios (NMEA los usa mucho). */
static int splitFields(char *s, char **fields, int max)
{
    int n = 0;
    fields[n++] = s;
    for (char *p = s; *p && n < max; p++) {
        if (*p == ',') {
            *p = '\0';
            fields[n++] = p + 1;
        }
    }
    return n;
}

/* NMEA expresa la coordenada como (d)ddmm.mmmmm mas hemisferio N/S/E/W. */
static bool parseCoordinate(const char *value, const char *hemisphere, double *out)
{
    if (!*value || !*hemisphere) {
        return false;
    }
    double raw = atof(value);
    int degrees = (int)(raw / 100);
    double minutes = raw - degrees * 100;
    double result = degrees + minutes / 60.0;
    if (*hemisphere == 'S' || *hemisphere == 'W') {
        result = -result;
    }
    *out = result;
    return true;
}

/* $xxRMC,hora,estado,lat,N/S,lng,E/W,velocidad(nudos),rumbo,fecha,... */
static void parseRmc(char **f, int n, uint32_t nowMs)
{
    double lat, lng;
    if (n < 9 || f[2][0] != 'A') {
        return; /* estado V = sin posicion valida */
    }
    if (!parseCoordinate(f[3], f[4], &lat) || !parseCoordinate(f[5], f[6], &lng)) {
        return;
    }
    data.lat = lat;
    data.lng = lng;
    data.speedKmh = f[7][0] ? (float)atof(f[7]) * KNOTS_TO_KMH : 0.0f;
    if (f[8][0]) {
        data.courseDeg = (float)atof(f[8]);
    }
    data.hasEverFix = true;
    lastValidRmcMs = nowMs;
}

/* $xxGGA,hora,lat,N/S,lng,E/W,calidad,satelites,HDOP,altitud,... */
static void parseGga(char **f, int n)
{
    if (n < 9) {
        return;
    }
    data.satellites = (uint8_t)atoi(f[7]);
    if (f[8][0]) {
        data.hdop = (float)atof(f[8]);
    }
}

static void handleSentence(const char *s, uint32_t nowMs)
{
    char copy[NMEA_MAX];
    char *fields[MAX_FIELDS];

    if (s[0] != '$' || !checksumOk(s)) {
        return;
    }
    /* Copia sin '$' ni "*hh" para poder cortarla en campos. */
    size_t len = (size_t)(strchr(s, '*') - (s + 1));
    if (len >= sizeof copy) {
        return;
    }
    memcpy(copy, s + 1, len);
    copy[len] = '\0';

    int n = splitFields(copy, fields, MAX_FIELDS);
    if (strlen(fields[0]) != 5) {
        return;
    }
    const char *type = fields[0] + 2; /* salta el talker: GP, GN, GL... */
    if (strcmp(type, "RMC") == 0) {
        parseRmc(fields, n, nowMs);
    } else if (strcmp(type, "GGA") == 0) {
        parseGga(fields, n);
    }
}

/* ---- API publica ---- */

void gps_tick(uint32_t nowMs)
{
    while (rxTail != rxHead) {
        char c = (char)rxBuffer[rxTail];
        rxTail = (uint16_t)((rxTail + 1) % RX_BUFFER_SIZE);
        anyByte = true;
        lastByteMs = nowMs;

        if (c == '$') {
            sentenceLen = 0; /* una frase nueva descarta cualquier resto incompleto */
        }
        if (c == '\r' || c == '\n') {
            if (sentenceLen > 0) {
                sentence[sentenceLen] = '\0';
                handleSentence(sentence, nowMs);
                sentenceLen = 0;
            }
            continue;
        }
        if (sentenceLen < NMEA_MAX - 1) {
            sentence[sentenceLen++] = c;
        } else {
            sentenceLen = 0; /* demasiado larga: no es NMEA valido */
        }
    }

    data.receiving = anyByte && nowMs - lastByteMs < DATA_TIMEOUT_MS;
    data.fix = data.hasEverFix && nowMs - lastValidRmcMs < FIX_TIMEOUT_MS;
}

const GpsData *gps_data(void)
{
    return &data;
}

void gps_feed_sentence(const char *s)
{
    handleSentence(s, HAL_GetTick());
}
