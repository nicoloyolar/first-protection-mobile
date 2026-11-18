#ifndef GPS_H
#define GPS_H

#include <stdbool.h>
#include <stdint.h>

/*
 * GPS u-blox NEO-M8N (GY-GPSV3-NEO) por USART1 a 9600 baudios, NMEA:
 *   TX del GPS -> D2 (PA10), RX del GPS -> D8 (PA9, opcional).
 * Lee RMC (posicion, velocidad, rumbo), GGA (satelites, HDOP) y GSV
 * (satelites en vista, para saber si la antena ve el cielo antes del fix), con
 * talker GP o GN (el M8N usa GN al combinar GPS + GLONASS/Galileo).
 */

typedef struct {
    bool receiving;  /* llegan bytes del modulo (cableado OK) */
    bool fix;        /* posicion valida reciente */
    bool hasEverFix; /* hubo fix alguna vez desde el arranque: lat/lng es la ultima conocida */
    double lat;      /* posicion publicada: retenida en reposo (ver gps.c) */
    double lng;
    float heldOffsetM; /* distancia entre la ultima posicion cruda y la publicada (diagnostico) */
    float speedKmh;
    float courseDeg;
    uint8_t satellites;       /* usados en el fix (GGA); 0 hasta tener fix */
    uint8_t satellitesInView; /* visibles en el cielo (GSV), sumando constelaciones */
    float hdop;
} GpsData;

void gps_init(void);
void gps_tick(uint32_t nowMs);
const GpsData *gps_data(void);

/* Inyecta una frase NMEA completa ("$GNRMC,...*hh"), para probar sin el modulo. */
void gps_feed_sentence(const char *sentence);

/* Transmite por USART1 TX (D8). El GPS no la usa (solo recibimos sus frases),
 * asi que la comparte el DFPlayer, que tambien trabaja a 9600 (ver audio.h). */
void gps_usart_transmit(const uint8_t *data, uint16_t len);

#endif
